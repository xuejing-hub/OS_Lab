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