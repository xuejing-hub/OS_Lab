#include <pmm.h>
#include <list.h>
#include <string.h>
#include <slub_pmm.h>
#include <stdio.h>

// ----------- 第一层：单链表 free_area 管理 -----------
static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

// 将 Page* 转为内核虚拟地址
static inline void *page2kva(struct Page *page) {
    return (void *)((uintptr_t)page2pa(page) + va_pa_offset);
}

// 将内核虚拟地址转换为 Page*
static inline struct Page *kva2page(void *kva) {
    return pa2page((uintptr_t)kva - va_pa_offset);
}

static void slub_2nd_init(void);

static void slub_init(void) {
    list_init(&free_list);
    nr_free = 0;
    slub_2nd_init();
}

static void slub_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page *slub_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}

static void slub_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

static size_t slub_nr_free_pages(void) {
    return nr_free;
}

// ----------- 第二层：SLUB小块分配 -----------
#define SLUB_SIZE_CLASSES 8
static size_t slub_sizes[SLUB_SIZE_CLASSES] = {8,16,32,64,128,256,512,1024};
#define SLUB_MAX_SIZE (slub_sizes[SLUB_SIZE_CLASSES-1])

struct slub_page {
    struct Page *page;
    struct slub_cache *cache;
    void *freelist;
    size_t inuse;
    list_entry_t page_link;
};

struct slub_cache {
    size_t obj_size;
    size_t objs_per_page;
    list_entry_t partial;
    list_entry_t empty;
};

static struct slub_cache slub_caches[SLUB_SIZE_CLASSES];
#define le2slubpage(le, member) to_struct((le), struct slub_page, member)

static void slub_2nd_init(void) {
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++) {
        slub_caches[i].obj_size = slub_sizes[i];
        slub_caches[i].objs_per_page = (PGSIZE - sizeof(struct slub_page)) / slub_caches[i].obj_size;
        list_init(&slub_caches[i].partial);
        list_init(&slub_caches[i].empty);
    }
}

// 计算 size 对应 cache
static int slub_cache_index(size_t size) {
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
        if (size <= slub_sizes[i]) return i;
    return -1;
}

// 从大块分配新页并初始化 slub_page
static struct slub_page *slub_new_page(struct slub_cache *cache) {
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

// SLUB 分配
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
        cprintf("[SLUB] 新建 slub_page: %p, cache obj_size=%u\n", sp, (unsigned)cache->obj_size);
    }

    if (!sp->freelist) return NULL;

    void *obj = sp->freelist;
    sp->freelist = *(void **)obj;
    sp->inuse++;

    list_del(&sp->page_link);
    if (sp->inuse < cache->objs_per_page)
        list_add(&cache->partial, &sp->page_link);

    cprintf("[SLUB] 分配 obj=%p, slub_page=%p, obj_size=%u, inuse=%u/%u\n",
        obj, sp, (unsigned)cache->obj_size, (unsigned)sp->inuse, (unsigned)cache->objs_per_page);

    return obj;
}

// SLUB 释放
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

    cprintf("[SLUB] 释放 obj=%p, slub_page=%p, obj_size=%u, inuse=%u/%u\n",
        obj, sp, (unsigned)cache->obj_size, (unsigned)sp->inuse, (unsigned)cache->objs_per_page);
}

// 通用分配接口
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

// 通用释放接口
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


static void slub_check(void) {
    cprintf("========== [SLUB Allocator Comprehensive Test] ==========\n\n");

    /* --- 初始状态 --- */
    cprintf("[Init] 当前总空闲页: %d\n", slub_nr_free_pages());
    cprintf("[Init] 空闲链表分布(property): ");
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        cprintf("%d ", p->property);
    }
    cprintf("\n\n");

    /* --- 边界情况 --- */
    cprintf(">>> [Boundary Check]\n");
    void *obj = slub_malloc(0);
    assert(obj == NULL);
    cprintf("[OK] malloc(0) -> NULL\n");

    void *big = slub_malloc(SLUB_MAX_SIZE + 1);
    if (big) {
        cprintf("[OK] 大对象分配成功: %p (> SLUB_MAX_SIZE)\n", big);
        slub_free(big);
        cprintf("[OK] 大对象释放成功\n");
    } else {
        cprintf("[WARN] 大对象分配失败 (无可用内存)\n");
    }
    cprintf("[Boundary Check Completed]\n\n");

    /* --- 小对象测试 --- */
    cprintf(">>> [Small Object Alloc/Free Test]\n");
    size_t test_sizes[] = {8, 16, 32, 64, 128, 256, 512};
    for (int i = 0; i < sizeof(test_sizes)/sizeof(test_sizes[0]); i++) {
        size_t sz = test_sizes[i];
        void *ptr = slub_malloc(sz);
        assert(ptr != NULL);
        memset(ptr, 0xAB, sz);
        cprintf("[ALLOC] %d bytes @ %p\n", sz, ptr);
        for (size_t j = 0; j < sz; j++) assert(((uint8_t*)ptr)[j] == 0xAB);
        slub_free(ptr);
        cprintf("[FREE ] %d bytes @ %p\n", sz, ptr);
    }
    cprintf("[Small Object Test Passed]\n\n");

    /* --- 小对象复用性测试 --- */
    cprintf(">>> [Reuse Check]\n");
    void *a1 = slub_malloc(64);
    slub_free(a1);
    void *a2 = slub_malloc(64);
    cprintf("[Reuse] First: %p, Second: %p (%s)\n",
            a1, a2, (a1 == a2) ? "Reused" : "New slab");
    slub_free(a2);
    cprintf("[Reuse Check Completed]\n\n");

    /* --- 批量分配释放 --- */
    cprintf(">>> [Bulk Allocation / Free Test]\n");
    const int NUM = 20;
    void *objs[NUM];
    for (int i = 0; i < NUM; i++) {
        objs[i] = slub_malloc(64);
        assert(objs[i]);
        cprintf("[ALLOC] objs[%02d] = %p\n", i, objs[i]);
    }
    cprintf("[INFO ] 全部 %d 个对象分配完成\n", NUM);
    for (int i = 0; i < NUM; i += 2) {
        slub_free(objs[i]);
        cprintf("[FREE ] objs[%02d] = %p\n", i, objs[i]);
    }
    for (int i = NUM / 2; i < NUM; i++) {
        objs[i] = slub_malloc(64);
        assert(objs[i]);
        cprintf("[REALLOC] objs[%02d] = %p\n", i, objs[i]);
    }
    for (int i = 1; i < NUM; i += 2) slub_free(objs[i]);
    for (int i = NUM / 2; i < NUM; i++) slub_free(objs[i]);
    cprintf("[Bulk Test Completed]\n\n");

    /* --- 大页分配测试 --- */
    cprintf(">>> [Multi-page Allocation Test]\n");
    struct Page *p0 = slub_alloc_pages(3);
    struct Page *p1 = slub_alloc_pages(5);
    struct Page *p2 = slub_alloc_pages(10);
    if (p0) cprintf("p0 = %p (3 pages)\n", p0);
    if (p1) cprintf("p1 = %p (5 pages)\n", p1);
    if (p2) cprintf("p2 = %p (10 pages)\n", p2);
    cprintf("当前空闲页数: %d\n", slub_nr_free_pages());
    if (p0) slub_free_pages(p0, 3);
    if (p1) slub_free_pages(p1, 5);
    if (p2) slub_free_pages(p2, 10);
    cprintf("[Multi-page Test Completed]\n\n");

    /* --- 混合测试 --- */
    cprintf(">>> [Mixed Allocation Pattern]\n");
    void *x1 = slub_malloc(32);
    void *x2 = slub_malloc(64);
    void *x3 = slub_malloc(128);
    cprintf("[ALLOC] x1=%p(32), x2=%p(64), x3=%p(128)\n", x1, x2, x3);

    slub_free(x2);
    cprintf("[FREE ] x2=%p\n", x2);

    void *x4 = slub_malloc(64);
    cprintf("[REALLOC] x4=%p(64)\n", x4);

    slub_free(x1);
    slub_free(x3);
    slub_free(x4);
    cprintf("[Mixed Test Completed]\n\n");

    /* --- 大对象/跨页分配测试 --- */
    cprintf(">>> [Large Object Alloc Test]\n");
    void *bigobj = slub_malloc(4096);
    if (bigobj) {
        cprintf("[ALLOC] 4096-byte big object @ %p\n", bigobj);
        slub_free(bigobj);
        cprintf("[FREE ] 4096-byte big object @ %p\n", bigobj);
    } else {
        cprintf("[WARN ] big object alloc failed.\n");
    }
    cprintf("[Large Object Test Completed]\n\n");

    /* --- 最终一致性检查 --- */
    cprintf(">>> [Final Consistency Check]\n");
    int total_free_pages = 0, count = 0;
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        total_free_pages += p->property;
        count++;
    }
    cprintf("空闲块数量: %d, 总空闲页: %d\n", count, total_free_pages);
    cprintf("slub_nr_free_pages() = %d\n", slub_nr_free_pages());
    assert(total_free_pages == slub_nr_free_pages());
    cprintf("[Consistency Verified]\n\n");

    cprintf("========== [SLUB Allocator Test Complete] ==========\n");
}


const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = slub_init,
    .init_memmap = slub_init_memmap,
    .alloc_pages = slub_alloc_pages,
    .free_pages = slub_free_pages,
    .nr_free_pages = slub_nr_free_pages,
    .check = slub_check,
};



