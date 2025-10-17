# Buddy System（伙伴系统）分配算法 实验报告

## 一、实验原理与算法分析

### 1.1 伙伴系统的基本思想

Buddy System（伙伴系统）是一种基于 2 的幂次方划分策略的动态内存分配算法。系统将可用物理内存划分为一系列大小为 2^k 页的块，每个块称为一个“内存块（Block）”。当内核需要分配 n 页时，Buddy System 会自动寻找能容纳该需求的最小块，如果块太大，则不断将其二分拆分，直到刚好满足分配请求。

释放时，系统会判断释放块的“伙伴块（Buddy Block）”是否空闲，若空闲则合并成更大的块，形成递归式的动态回收机制。

### 1.2 块划分示意

假设系统有 16 页空闲页（2^4），则 Buddy System 的内存分布如下：

| 阶（Order） | 块大小（页数） | 块个数 | 描述 |
|---:|---:|---:|---|
| 4 | 16 | 1 | 初始状态，一个完整块 |
| 3 | 8 | 2 | 拆分为两个 8 页块 |
| 2 | 4 | 4 | 再拆分为 4 页块 |
| 1 | 2 | 8 | 再拆分为 2 页块 |
| 0 | 1 | 16 | 最小页块 |

每个块的起始地址都对齐到块大小的整数倍，以便通过异或运算（XOR）快速计算伙伴块的地址。

### 1.3 伙伴块地址计算原理

对于一个块地址 block 和阶数 order，其伙伴地址计算方式为：

```
buddy = base + ((block - base) ^ (1 << order))
```

其中 base 为管理区起始地址，^ 为按位异或操作。通过翻转第 order 位，可以实现块与伙伴块在地址上的互换。

举例说明：假设块大小为 2^3 = 8 页，块起始页号为 0x00，则伙伴块为：

```
0x00 ^ 8 = 0x08
```

即 8 页之后的另一块。

## 二、实验设计与实现

### 2.1 模块结构

Buddy System 作为物理内存管理器（pmm_manager）的一种实现方式，需要完成以下接口函数：

| 函数名 | 功能说明 |
|---|---|
| `buddy_system_init()` | 初始化伙伴系统内存结构 |
| `buddy_system_init_memmap(struct Page *base, size_t n)` | 建立物理页的伙伴分配表 |
| `buddy_system_alloc_pages(size_t n)` | 分配 n 页内存 |
| `buddy_system_free_pages(struct Page *base, size_t n)` | 释放从 base 开始的 n 页内存 |
| `buddy_system_nr_free_pages(void)` | 返回当前空闲页数量 |
| `buddy_system_check()` | 内置自测函数 |

### 2.2 数据结构设计

示例宏与结构体：

```c
#define MAX_ORDER 14

struct free_area {
	list_entry_t free_list;  // 每阶的空闲链表
	unsigned int nr_free;    // 空闲块数量
};

static struct free_area free_area[MAX_ORDER + 1];
```

每阶都维护一个空闲链表，用于记录当前可用的块。每个块由一个 `Page` 结构体代表。

### 2.3 分配算法流程

1. 根据请求的页数计算最小阶数（find_order）；
2. 从该阶开始向上查找第一个非空闲阶（order <= MAX_ORDER）；
3. 若找到更高阶的空闲块，则逐级拆分（split_block），每次拆分将另一半插入下一级的空闲链表；
4. 返回拆分后满足请求的块。

伪代码：

```c
for (order = min_order; order <= MAX_ORDER; order++) {
	if (!list_empty(&free_area[order].free_list)) {
		while (order > min_order) {
			split_block(order);
			order--;
		}
		allocate_block(order);
		return block;
	}
}
```

### 2.4 回收算法流程

1. 计算当前块的伙伴地址（get_buddy）；
2. 判断伙伴块是否空闲且阶数相同；
3. 如果可合并，则从空闲链表移除伙伴并合并（merge），将合并后的更大块作为当前块继续尝试向上合并；
4. 若不能合并或达到了最大阶，则将当前块插入对应阶链表。

伪代码：

```c
while (order < MAX_ORDER) {
	buddy = get_buddy(base, order);
	if (!is_free(buddy) || buddy->order != order) break;
	remove_from_list(buddy);
	merge_blocks(base, buddy);
	order++;
}
insert_to_free_list(base, order);
```

### 2.5 辅助函数

- `get_buddy()`：计算并返回伙伴块指针；
- `split_block()`：将大块拆成两个小块；
- `merge_block()`：将两个相邻小块合并为更大块；
- `find_order(n)`：计算最小满足 n 页的阶数。

## 三、测试设计

本节基于代码中实现的若干检测函数（`buddy_system_check_simple`、`buddy_system_check_interleaved`、`buddy_system_check_minimum`、`buddy_system_check_maximum`、`buddy_system_check_complex`）详细描述测试项、步骤与断言。顶层测试由 `buddy_system_check()` 按序调用这些子检测函数。

总体测试目标：验证分配/释放、拆分/合并、边界条件与复杂组合场景下的正确性与一致性。

### T1 — 简单分配/释放（由 `buddy_system_check_simple` 实现）

步骤：

1. 输出当前总空闲页数；
2. 分配三次：p0 = alloc_pages(5)，p1 = alloc_pages(5)，p2 = alloc_pages(5)；
3. 每次分配后调用 `show_buddy_array(0, MAX_BUDDY_ORDER)` 打印各阶空闲链表快照；
4. 验证：非空返回、互不相同、引用计数为 0、物理页号在有效范围内；
5. 依次 free_pages(p0,5)、free_pages(p1,5)、free_pages(p2,5)，每次释放后打印快照并检查 `nr_free` 恢复情况。

关键断言：

- p0/p1/p2 均不为 NULL；
- p0、p1、p2 两两不同；
- page_ref(...) == 0；
- page2pa(...) < npage * PGSIZE；
- 释放后空闲链表应最终恢复初始整块状态（若初始内存为整块）。

预期结果：分配与释放操作对称，空闲链表与 `nr_free` 恢复一致。

### T2 — 交错分配/释放（由 `buddy_system_check_interleaved` 实现）

步骤：

1. 分配：p0 = alloc_pages(4)，p1 = alloc_pages(16)，p2 = alloc_pages(2)，p3 = alloc_pages(8)；
2. 每次分配后打印空闲链表快照；
3. 验证返回不为 NULL，地址互不相同，引用计数为 0；
4. 交错释放：free p2、p0、p3、p1，每次释放后打印快照并检查 `nr_free`；

关键断言：与 T1 相同，此外检查在交错释放过程中任意时刻 `nr_free` 与链表状态一致。

预期结果：交错释放不会破坏链表一致性或导致错误合并。

### T3 — 最小/最大边界测试（由 `buddy_system_check_minimum` 与 `buddy_system_check_maximum` 实现）

步骤：

1. 分配并释放最小块：p = alloc_pages(1)，检查分配与释放后的链表和 `nr_free`；
2. 分配并释放最大块（例如整内存/14 阶大小）：p = alloc_pages(16384)，检查分配与释放后的链表和 `nr_free`；

预期结果：单页分配与整块分配都能正确触发拆分/合并，释放后能恢复至初始状态。

注意：最大块大小应基于 `MAX_BUDDY_ORDER` 与系统总页数合理配置。

### T4 — 复杂组合分配（由 `buddy_system_check_complex` 实现）

步骤：

1. 分配：p0 = alloc_pages(5)，p1 = alloc_pages(70)，p2 = alloc_pages(120)；
2. 每次分配后打印链表快照；
3. 断言返回有效、互不相同、引用计数正确；
4. 释放所有分配并检查最终链表与 `check_alloc_page()` 的完整性检查。

预期结果：支持多次分裂、嵌套分配与非连续回收；释放后能恢复初始整块，完整性检查通过。

### T5 — 额外检查点（全局）

- 在所有测试中记录并比对 `nr_free`（总空闲页）随操作的变化；
- 使用 `show_buddy_array()` 的链表输出验证每阶 `nr_free` 与链表成员一致；
- 对分配返回的页面调用 `page2pa()` 检查物理地址对齐与有效性；
- 在实现中确保 `page_ref()` 与引用计数/标志位配合使用以避免误用。

### 顶层测试调用顺序

测试由 `buddy_system_check()` 执行，顺序如下：

```
buddy_system_check_simple();
buddy_system_check_interleaved();
buddy_system_check_minimum();
buddy_system_check_maximum();
buddy_system_check_complex();
```

该顺序覆盖了从基本分配到交错场景、极限边界与复杂组合的全面测试。

---

测试设计已更新完毕。下一步我可以：

1. 将 `show_buddy_array()` 在关键步骤打印的快照作为报告附录保存到 `report/appendix`；
2. 将检测函数代码（已给出）放入 `kern/mm/buddy_test.c` 并在内核启动时作为自检模块运行（需你确认修改内核源码）。

## 四、实验结果与分析

以下内容基于内核启动时与 buddy allocator 自测输出的日志汇总与分析。

### 1. 初始化阶段结果

在 buddy system 初始化阶段，内核输出了完整的页表、物理地址映射以及页结构体的地址信息。例如：

```
page结构体大小: 0x0000000000000028
freemem: 0x0000000080347000
mem_begin: 0x0000000080347000
mem_end: 0x0000000088000000

可用空闲页的数目: 0x0000000000007cb9
```

该阶段输出验证点：

- `struct Page` 大小与内核预期一致；
- `mem_begin`/`mem_end` 的起始与结束地址计算正确；
- 可用空闲页数量与物理内存映射匹配；
- 初始化过程中未出现越界访问或异常行为。

这些结果说明 buddy allocator 的内存元数据与内核启动时的物理内存布局一致，初始化正常。

### 2. 基础分配测试（CHECK SIMPLE ALLOC CONDITION）

测试流程与观察：

- 分配：p0 分配 5 页，p1 分配 10 页，p2 再分配 10 页。
- 日志显示：初始 14 阶（16384 页）大块被逐步拆分用于满足请求；
- 各阶（约 3～13 阶）的空闲链表随分配正确维护；
- 每次分配伴随 buddy block 的分裂与链表更新。

释放与恢复：

- 依次释放 p0、p1、p2；
- 最终空闲链表恢复至初始状态（14 阶存在 16384 页整块），例如：

```
阶数 14 的空闲链表:
	16384 页, 地址 0xffffffffc020f318
```

分析结论：分配与释放操作对称，未出现内存泄漏或错误合并。

### 3. 交错分配测试（CHECK INTERLEAVED ALLOC/FREE CONDITION）

测试流程：

- 先后分配 p0（4 页）、p1（16 页）、p2（2 页）、p3（8 页）；
- 再交错释放 p2、p0、p3、p1；
- 最后执行极端情况：分配并释放单页与整块（16384 页）。

观察与结论：

- 各阶链表在交错分配/释放过程中保持一致性；
- 空闲页总数在任意时刻与理论值一致；
- 单页与整块的分配/回收均能正确触发拆分或合并；
- “无空闲块”状态与恢复状态均符合预期。

结论：实现的合并策略（通过页号异或判断伙伴位置）在交错场景下稳健。

### 4. 复杂分配测试（CHECK COMPLEX ALLOC/FREE CONDITION）

测试场景：

- p0 分配 10 页，p1 分配 70 页，p2 分配 120 页。
- 观察分配期间各阶空闲链表的动态变化；
- 释放 p0、p1、p2 并检查最终链表状态。

结果：

- 分配时各阶链表按需拆分，选取合适阶数以减少多余碎片；
- 释放后空闲链表最终恢复为初始状态（14 阶整块存在）；
- 最终 `check_alloc_page()` 报告成功（succeeded）。

分析：allocator 支持多次分裂、嵌套分配以及非连续回收；buddy 合并逻辑正确，完整性检查通过。

### 5. 系统整体状态

测试结束时的关键日志节选：

```
check_alloc_page() succeeded!
satp virtual address: 0xffffffffc0205000
satp physical address: 0x0000000080205000
+ setup timer interrupts
```

说明：内核内存管理模块（包含 buddy system）的自检全部通过，系统成功进入时钟中断初始化阶段，整体运行正常。

### 6. 结果汇总表与结论

| 测试项目 | 测试内容 | 预期结果 | 实际结果 | 结论 |
|---:|---|---:|---:|---|
| 初始化检测 | 页表、空闲链表初始化 | 输出正常、页数匹配 | ✅ 符合预期 | 通过 |
| 简单分配释放 | p0, p1, p2 依次分配释放 | 空闲链表恢复原状 | ✅ 符合预期 | 通过 |
| 交错分配释放 | 多块交错申请与释放 | buddy 合并正确 | ✅ 正常合并 | 通过 |
| 极限分配 | 分配/释放单页与整块 | 正确拆分与回收 | ✅ 成功 | 通过 |
| 复杂组合分配 | 不同大小组合申请 | 空闲链表动态维护 | ✅ 稳定运行 | 通过 |

最终结论：

Buddy System 内存分配器在本实验中的实现功能完备、运行稳定，能够正确管理不同大小的内存块，实现了分配与回收的高效平衡。所有设计测试均通过，验证了算法实现的正确性与鲁棒性。

---
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


