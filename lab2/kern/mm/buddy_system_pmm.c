#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <buddy_system_pmm.h>
#include <memlayout.h>

buddy_system_t buddy_system;
#define buddy_array (buddy_system.free_array)
#define max_order (buddy_system.max_order)
#define nr_free (buddy_system.nr_free)

/////////////////////////////////////////////////////////////////buddy核心函数//////////////////////////////////////////////////////////

//初始化伙伴系统
static void buddy_system_init(void) {
    for (int i = 0; i <= MAX_BUDDY_ORDER; i++) {
        list_init(&buddy_array[i]);
    }
    max_order = 0;//当前系统中最大的连续空闲块阶数为 0（即：初始化时没有记录任何可用块）
    nr_free = 0;//当前系统空闲页数量为 0
}

//初始化链表
static void buddy_system_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);//确保传入的页数 n 不为 0。

    // 直接计算最接近 2 的幂，不大于 n
    size_t p_number = 1;
    while ((p_number << 1) <= n) {
        p_number <<= 1;
    }

    // 计算 order
    unsigned int order = 0;
    size_t tmp = p_number;
    while (tmp > 1) {
        tmp >>= 1;
        order++;
    }

    max_order = order;
    nr_free = p_number;

    // 记录管理区基址，供 get_buddy 使用
    buddy_system.base = base;

    for (struct Page* p = base; p < base + p_number; p++) {
        assert(PageReserved(p));//确保该页最初是保留态（内核初始化时所有页都被标记为保留）。
        p->flags = 0;
        p->property = -1;//初始化属性为 -1，说明此页不是块头页。
        set_page_ref(p, 0);
    }

    base->property = max_order;//表示从 base 开始的一段 2^max_order 页是一个完整空闲块
    SetPageProperty(base);
    list_add(&buddy_array[max_order], &base->page_link);
}

//分裂操作
static void buddy_system_split(size_t n) {
    assert(n > 0 && n <= max_order);
    assert(!list_empty(&buddy_array[n]));

    list_entry_t* le = list_next(&buddy_array[n]);
    struct Page* page1 = le2page(le, page_link);//通过宏将链表节点转换为 Page 结构体指针。

    size_t half_size = 1UL << (n - 1);
    struct Page* page2 = page1 + half_size;

    page1->property = page2->property = n - 1;
    SetPageProperty(page1);
    SetPageProperty(page2);//调用 SetPageProperty 设置标志位，表明它们都是块头页。

    list_del(le);
    list_add(&buddy_array[n - 1], &page1->page_link);
    list_add(&page1->page_link, &page2->page_link);
}

//页的分配：分配 requested_pages 页内存，返回分配得到的块的首地址。
static struct Page* buddy_system_alloc_pages(size_t requested_pages) {
    assert(requested_pages > 0);
    if (requested_pages > nr_free) return NULL;

    // 调整为 >= requested_pages 的 2 的幂
    size_t adjusted_pages = 1;
    while (adjusted_pages < requested_pages) adjusted_pages <<= 1;

    unsigned int order = 0;
    size_t tmp = adjusted_pages;
    while (tmp > 1) { tmp >>= 1; order++; }

    struct Page* allocated_page = NULL;

    for (unsigned int current_order = order; current_order <= max_order; current_order++) {
        if (!list_empty(&buddy_array[current_order])) {
            while (current_order > order) {
                buddy_system_split(current_order--);//如果高阶空闲块大于请求阶，需要分裂。
            }
            allocated_page = le2page(list_next(&buddy_array[order]), page_link);//取出链表中第一个块的页头。
            list_del(&allocated_page->page_link);
            ClearPageProperty(allocated_page);//清除块头页的标志，表示它不再是空闲块。
            nr_free -= adjusted_pages;
            break;
        }
    }

    return allocated_page;//返回分配到的 首页指针，供调用者使用。
}

//根据某个内存块的起始地址 block_addr 和块的阶数 order，计算并返回该块的“伙伴块”（buddy block）的地址。
//一个块从偏移量 0bXXXX000 开始；
//它的 buddy 块就是 0bXXXX000 的第 order 位取反后的结果。
struct Page *get_buddy(struct Page *block_addr, unsigned int order) {
    size_t block_size = 1UL << order;
    // 计算 block_addr 相对于 buddy_system.base 的页偏移（以 Page 单位）
    size_t offset = (size_t)(block_addr - buddy_system.base);
    size_t buddy_offset = offset ^ block_size;
    // 边界检查，防止越界访问
    if (buddy_offset >= npage) {
        panic("get_buddy: buddy offset out of range\n");
    }
    return buddy_system.base + buddy_offset;
}


//页的释放：释放的内存块与它的伙伴块都空闲时，就自动合并成更大的块，以避免内存碎片。
static void buddy_system_free_pages(struct Page* base, size_t n) {
    assert(n > 0);
    size_t block_size = 1UL << base->property;
    assert(block_size >= n);  // 调整后的检查

    struct Page* block = base;
    list_add(&buddy_array[block->property], &block->page_link);

    struct Page* buddy;
    while (block->property < max_order) {
        buddy = get_buddy(block, block->property);

        if (!PageProperty(buddy)) break;

        if (block > buddy) {
            struct Page* tmp = block;
            block = buddy;
            buddy = tmp;
        }//合并时，总是让 block 指向 地址较小 的那一块；

        list_del(&block->page_link);
        list_del(&buddy->page_link);

        block->property += 1;
        list_add(&buddy_array[block->property], &block->page_link);
    }

    SetPageProperty(block);
    nr_free += block_size;
}

//显示空闲链表
static void show_buddy_array(int left, int right) {
    assert(left >= 0 && left <= max_order && right >= 0 && right <= max_order);
    bool empty = 1;
    cprintf("----- 当前空闲链表数组 -----\n");
    for (int i = left; i <= right; i++) {
        list_entry_t* head = &buddy_array[i];
        list_entry_t* cur = list_next(head);

        if (cur != head) {
            empty = 0;
            cprintf("阶数 %d 的空闲链表:\n", i);
            do {
                struct Page* p = le2page(cur, page_link);
                cprintf("  %lu 页, 地址 %p\n", 1UL << p->property, p);
                cur = list_next(cur);
            } while (cur != head);
        }
    }
    if (empty) cprintf("无空闲块\n");
    cprintf("----- 显示完成 -----\n\n");
}

//空闲页数
static size_t buddy_system_nr_free_pages(void) {
    return nr_free;
}


/////////////////////////////////////////////////////////////////检测函数//////////////////////////////////////////////////////////

static void buddy_system_check_simple(void) {
    cprintf("=== CHECK SIMPLE ALLOC CONDITION ===\n");
    cprintf("总空闲页数: %d\n", nr_free);

    struct Page *p0 = NULL, *p1 = NULL, *p2 = NULL;

    // 分配操作
    p0 = alloc_pages(5);
    cprintf("p0 分配 5页: %p\n", p0);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    p1 = alloc_pages(5);
    cprintf("p1 分配 10 页: %p\n", p1);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    p2 = alloc_pages(5);
    cprintf("p2 分配 10 页: %p\n", p2);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    // 检查分配正确性
    assert(p0 && p1 && p2);
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    cprintf("=== CHECK SIMPLE FREE CONDITION ===\n");

    // 释放操作
    free_pages(p0, 5);
    cprintf("释放 p0, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    free_pages(p1, 5);
    cprintf("释放 p1, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    free_pages(p2, 5);
    cprintf("释放 p2, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);
}



static void buddy_system_check_complex(void) {
    cprintf("=== CHECK COMPLEX ALLOC CONDITION ===\n");
    cprintf("总空闲页数: %d\n", nr_free);

    struct Page *p0 = NULL, *p1 = NULL, *p2 = NULL;

    // 分配操作
    p0 = alloc_pages(5);
    cprintf("p0 分配 10 页: %p\n", p0);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    p1 = alloc_pages(70);
    cprintf("p1 分配 70 页: %p\n", p1);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    p2 = alloc_pages(120);
    cprintf("p2 分配 120 页: %p\n", p2);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    // 检查分配正确性
    assert(p0 && p1 && p2);
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    cprintf("=== CHECK COMPLEX FREE CONDITION ===\n");

    // 释放操作
    free_pages(p0,5);
    cprintf("释放 p0, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    free_pages(p1, 70);
    cprintf("释放 p1, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    free_pages(p2, 120);
    cprintf("释放 p2, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);
}



static void buddy_system_check_minimum(void) {
    struct Page *p3 = alloc_pages(1);
    cprintf("分配 p3 (1 页): %p\n", p3);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    free_pages(p3, 1);
    cprintf("释放 p3 (1 页)\n");
    show_buddy_array(0, MAX_BUDDY_ORDER);
}

static void buddy_system_check_maximum(void) {
    struct Page *p3 = alloc_pages(16384);
    cprintf("分配 p3 (16384 页): %p\n", p3);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    free_pages(p3, 16384);
    cprintf("释放 p3 (16384 页)\n");
    show_buddy_array(0, MAX_BUDDY_ORDER);
}

static void buddy_system_check_interleaved(void) {
    cprintf("=== CHECK INTERLEAVED ALLOC/FREE CONDITION ===\n");
    cprintf("总空闲页数: %d\n", nr_free);

    struct Page *p0 = NULL, *p1 = NULL, *p2 = NULL, *p3 = NULL;

    // 分配操作：不同大小交错
    p0 = alloc_pages(4);      // 小块
    cprintf("p0 分配 4 页: %p\n", p0);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    p1 = alloc_pages(16);     // 中块
    cprintf("p1 分配 16 页: %p\n", p1);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    p2 = alloc_pages(2);      // 小块
    cprintf("p2 分配 2 页: %p\n", p2);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    p3 = alloc_pages(8);      // 中块
    cprintf("p3 分配 8 页: %p\n", p3);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    // 检查分配正确性
    assert(p0 && p1 && p2 && p3);
    assert(p0 != p1 && p0 != p2 && p0 != p3 &&
           p1 != p2 && p1 != p3 &&
           p2 != p3);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 &&
           page_ref(p2) == 0 && page_ref(p3) == 0);

    // 交错释放操作
    free_pages(p2, 2);
    cprintf("释放 p2, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    free_pages(p0, 4);
    cprintf("释放 p0, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    free_pages(p3, 8);
    cprintf("释放 p3, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);

    free_pages(p1, 16);
    cprintf("释放 p1, 总空闲页数: %d\n", nr_free);
    show_buddy_array(0, MAX_BUDDY_ORDER);
}


static void buddy_system_check(void) {
    cprintf("BEGIN TO TEST OUR BUDDY SYSTEM!\n");
    buddy_system_check_simple();
    buddy_system_check_interleaved(); 
    buddy_system_check_minimum();
    buddy_system_check_maximum();
    buddy_system_check_complex();
}

const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_system_check,
};

