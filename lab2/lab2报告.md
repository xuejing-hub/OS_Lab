
# SLUB 分配算法

## 算法介绍

slub算法主要用于Linux 内核中为高效分配小块内存，其核心思想是将一页内存划分为多个大小相同的小块，通过缓存对象来管理这些小块，每个对象缓存对应一种固定大小的内存对象，对于大块内存，可以直接使用原本的页面分配算法。

### 缓存（Cache）

在 SLUB 中，每一种固定大小的内存对象都有一个对应的 **slub_cache**（对象缓存）

- **目的**：避免每次分配小对象都去操作整页内存，提高效率。
- **结构**：每个 `slub_cache` 管理一个对象类型的内存分配，主要包含 ：
  1. **partial**：部分使用页（还有空闲块的页）。
  2. **full**：已用满的页（没有可用空闲块）。
  3. **free**：空闲页（整个页还没有分配任何对象）。

每个缓存还记录：
- `obj_size`：对象大小。
- `objs_per_page`：每页可分配的对象数量。
- 分配/释放函数指针。

### Slab（页块）

SLUB 的 **slab** 是对页（Page）进一步划分后的管理单元，每个 slab 通常对应 **一页内存**。

每个 slab 维护一个或多个小块，每个小块存放一个对象。

- **空闲块链表**：通过对象头部的指针把空闲对象串起来（单链表）。
- **引用计数**：记录 slab 内已分配对象数量，用于判断 slab 是否已满或空闲。
- **所属缓存**：指向 `slub_cache`，知道该 slab 分配的是哪类对象。

#### 分配策略

1. **先从 partial 链表分配**：优先使用部分使用页，避免浪费新页。
2. **再从 free 链表分配**：如果 partial 没有可用块，就从空闲页分配一页。
3. **full 链表不参与分配**：已满页无法再分配。

#### 释放策略

1. 对象释放后将块加入 slab 的空闲链表。
2. slab 空闲对象计数变为 0 → slab 加入 free 链表。
3. slab 全部被释放 → 可以考虑回收整页（返还底层 Buddy 分配器）。



SLUB 通过 **缓存+slab** 的两层管理机制实现高效分配：

1. 每类对象有一个缓存，缓存里维护不同状态的 slab 链表。
2. 每页 slab 内部分配小对象，单链表管理空闲块。
3. 优先使用部分使用页，减少新页申请，释放时自动回收空闲页。


## 设计实现

### 1.设计思路

采用两层架构的高效内存单元分配，为简化实现，保留页级别的分配策略，使用 First-Fit 策略分配和回收页，用于处理大块内存请求，同时负责页的合并和空闲管理。第二层在第一层的基础上实现小对象分配，每个 slub_cache 管理固定大小的对象，单页 slab 内包含多个对象，每次小对象分配时，优先从 partial 页获取空闲块，必要时从空闲页或新分配页初始化 slab，再返回对象；释放时将对象放回 slab 的 freelist，并更新 slab 状态，实现高效的内存复用和管理。每个 slab 的占据单位为 1 页，其中存放固定数量的对象，对象大小根据缓存类（8、16、32…1024 字节）划分，从而实现不同大小小对象的快速分配和释放。


### 2.结构设计

```c
struct slub_page {
    struct Page *page;        // 物理页指针
    struct slub_cache *cache; // 所属 cache
    void *freelist;           // 当前空闲对象链
    size_t inuse;             // 已使用对象数
    list_entry_t page_link;   // 链表节点
};

struct slub_cache {
    size_t obj_size;           // 对象大小
    size_t objs_per_page;      // 每页对象数量
    list_entry_t partial;      // 部分使用页链表
    list_entry_t empty;        // 空闲页链表
};
```


### 3.初始化 

初始化分两层，先用默认页级别分配器进行页级别的初始化，然后`slub_2nd_init` 函数用于第二层小对象分配的cache数据结构初始化：为每个对象大小类别创建一个 `slub_cache`，记录对象大小和每页 slab 可容纳的对象数量，同时初始化两个链表——`partial` 用于管理部分使用的 slab，`empty` 用于管理空闲 slab。


```c
static void slub_2nd_init(void) {
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++) {
        slub_caches[i].obj_size = slub_sizes[i];
        slub_caches[i].objs_per_page = (PGSIZE - sizeof(struct slub_page)) / slub_caches[i].obj_size;
        list_init(&slub_caches[i].partial);
        list_init(&slub_caches[i].empty);
    }
}
```




### 4. 分配内存

#### 4.1 分配新页面
`slub_new_page` 是 SLUB 第二层分配器中为 `slub_cache` 分配新 slab 页并初始化对象链表的函数，用于小对象分配时新建 slab 。

函数首先调用第一层页分配器分配一页物理内存，如果页分配失败则返回 NULL，表示无法创建新的 slab。新分配的页会被转换为 `slub_page` 结构，存储页的元数据，包括：
- `sp->page`：指向该页的 Page 对象
- `sp->cache`：指向所属缓存，保证对象大小一致
- `sp->inuse`：初始化为 0，表示尚未分配对象
- `sp->freelist`：初始化为空，后续用于存放对象空闲链表

在 slab 页头结构体之后的空间被划分为固定大小的对象，循环 `objs_per_page` 次建立 freelist 链表，使每个对象指向下一个空闲对象，便于快速分配和释放。函数返回初始化好的 `slub_page`，供 `slub_cache_alloc` 分配对象使用。

`slub_new_page` 的作用包括：
- 调用页分配器获取新页面
- 在页头存储 slab 元数据
- 将页剩余空间划分为固定大小对象
- 建立 freelist 链表，


```c
tatic struct slub_page *slub_new_page(struct slub_cache *cache) {
    struct Page *page = slub_alloc_pages(1);
    if (!page) return NULL;

    void *page_addr = page2kva(page);
    struct slub_page *sp = (struct slub_page *)page_addr;
    sp->page = page;
    sp->cache = cache;
    sp->inuse = 0;
    list_init(&sp->page_link);

    void *obj = (char *)page_addr + sizeof(struct slub_page);
    uintptr_t aligned = ((uintptr_t)obj + cache->obj_size - 1) & ~(cache->obj_size - 1);
    obj = (void *)aligned;

    sp->freelist = NULL;
    for (size_t i = 0; i < cache->objs_per_page; i++) {
        *(void **)obj = sp->freelist;
        sp->freelist = obj;
        obj = (char *)obj + cache->obj_size;
    }
    return sp;
}
```

#### 4.2 对象分配

##### 分配内存

在分配内存时，需要分三种情况讨论：
1. **部分使用的页面（partial list 非空）**  
   - 如果 `cache->partial` 链表非空，说明存在已分配过部分对象但还有空闲对象的页面。  
   - 从 `partial` 链表中取出该页面 `sp`，准备从其空闲链表 `freelist` 分配对象。  

2. **空页面（empty list 非空）**  
   - 如果 `partial` 链表为空，但 `cache->empty` 链表非空，则说明存在完全未使用的页面。  
   - 从 `empty` 链表中取出该页面 `sp`，同时将其从 `empty` 链表中删除。  
   - 后续会将该页面根据分配情况加入 `partial` 链表。  

3. **没有可用页面（都为空）**  
   - 如果 `partial` 和 `empty` 都为空，则调用 `slub_new_page(cache)` 申请新页面。  
   - 如果分配失败（返回 `NULL`），则直接返回 `NULL`。  

##### 分配对象

1. 从页面 `sp` 的 `freelist` 中取出一个对象 `obj`。  
2. 更新页面的空闲链表：`sp->freelist = *(void **)obj`，将 `freelist` 指向下一个空闲对象。  
3. 更新页面使用计数：`sp->inuse++`，表示该页面已使用的对象数增加。  

---

##### 页面链表

1. 先将页面从原链表中删除：`list_del(&sp->page_link)`，防止重复出现。  
2. 判断页面是否已经满：  
   - 如果 `sp->inuse < cache->objs_per_page`，说明页面还有空闲对象，则将其加入 `partial` 链表。  
   - 如果已经满，则不加入任何链表，等待释放时重新进入链表管理。  


```c
static void *slub_cache_alloc(struct slub_cache *cache) {
    struct slub_page *sp = NULL;

    if (!list_empty(&cache->partial)) {
        sp = le2slubpage(list_next(&cache->partial), page_link);
    } else if (!list_empty(&cache->empty)) {
        sp = le2slubpage(list_next(&cache->empty), page_link);
        list_del(&sp->page_link);
    } else {
        sp = slub_new_page(cache);
        if (!sp) return NULL;
    }

    if (!sp->freelist) return NULL;

    void *obj = sp->freelist;
    sp->freelist = *(void **)obj;
    sp->inuse++;

    list_del(&sp->page_link);
    if (sp->inuse < cache->objs_per_page)
        list_add(&cache->partial, &sp->page_link);


    return obj;
}
```


### 5. 释放内存


`slub_cache_free` 用于将已分配的对象返回到所属 slab 页面，并更新 slab 的链表状态。

通过将对象指针按页对齐得到所在页的地址，从而定位其所属的 `slub_page`，获取 slab 所属的 `slub_cache`，以便更新链表。

将释放的对象插入 slab 的 `freelist` 链表头，`sp->inuse--`更新 slab 中正在使用的对象计数。

将 slab 从原链表中移除，根据使用情况重新加入合适的链表：
  - `inuse == 0` → slab 完全空闲，加入 `empty` 链表  
  - `inuse > 0` → slab 仍有部分对象使用，加入 `partial` 链表  


```c
static void slub_cache_free(void *obj) {
    if (!obj) return;
    uintptr_t page_addr = (uintptr_t)obj & ~(PGSIZE - 1);
    struct slub_page *sp = (struct slub_page *)page_addr;
    struct slub_cache *cache = sp->cache;

    *(void **)obj = sp->freelist;
    sp->freelist = obj;
    sp->inuse--;

    list_del(&sp->page_link);
    if (sp->inuse == 0)
        list_add(&cache->empty, &sp->page_link);
    else
        list_add(&cache->partial, &sp->page_link);
}
```

---

### 6. 通用接口

- `slub_malloc(size)` 会根据请求大小自动选择分配方式：  
  - 小对象 → `slub_cache_alloc`  
  - 大对象 → 页分配  

- `slub_free(ptr)` 会根据对象是否属于 slab 决定释放策略：  
  - slab 对象 → `slub_cache_free`  
  - 大对象 → `slub_free_pages`  

```c
void *slub_malloc(size_t size) {
    if (size == 0) return NULL;

    if (size > SLUB_MAX_SIZE) {
        size_t pages = (size + PGSIZE - 1) / PGSIZE;
        struct Page *pg = slub_alloc_pages(pages);
        if (!pg) return NULL;
        return page2kva(pg);
    }

    int idx = slub_cache_index(size);
    if (idx < 0) return NULL;
    return slub_cache_alloc(&slub_caches[idx]);
}

void slub_free(void *ptr) {
    if (!ptr) return;
    uintptr_t page_addr = (uintptr_t)ptr & ~(PGSIZE - 1);
    struct slub_page *sp = (struct slub_page *)page_addr;
    if (sp->cache)
        slub_cache_free(ptr);
    else {
        struct Page *pg = kva2page((void *)page_addr);
        slub_free_pages(pg, 1);
    }
}
```




### 7. 测试与验证
详细测试样例见代码，主要包括：
* 小对象分配/释放测试（8~512B） → 通过
* 大对象分配 (>SLUB_MAX_SIZE) → 通过
* 对象复用性验证 → 释放后再次分配获得同一地址
* 多页分配与混合分配模式 → 正确管理 `nr_free` 和链表状态
* 最终一致性检查 → 所有空闲页统计与 `nr_free` 一致

---

