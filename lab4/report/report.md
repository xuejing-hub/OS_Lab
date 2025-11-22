# Lab4 实验报告
## 练习1：分配并初始化一个进程控制块

### 设计实现过程

在 `alloc_proc` 函数中，我按照注释要求对 `struct proc_struct` 的所有字段进行了初始化：

```c
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
        proc->state = PROC_UNINIT;  // 进程状态为未初始化
        proc->pid = -1;             // 进程ID初始化为-1（无效）
        proc->runs = 0;             // 运行次数初始化为0
        proc->kstack = 0;           // 内核栈地址初始化为0
        proc->need_resched = 0;     // 不需要调度
        proc->parent = NULL;        // 父进程指针为空
        proc->mm = NULL;            // 内存管理结构为空
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
        proc->tf = NULL;            // 中断帧指针为空
        proc->pgdir = boot_pgdir_pa; // 页目录表基址为启动页表的物理地址
        proc->flags = 0;            // 标志位清零
        memset(proc->name, 0, PROC_NAME_LEN); // 进程名清零
    }
    return proc;
}
```

在实现过程中，有几个关键的设计考虑：

首先，`pgdir` 字段初始化为 `boot_pgdir_pa`，这是因为在底层硬件操作中，页表寄存器需要的是物理地址而非虚拟地址。

其次，`pid` 初始化为 -1 ，这个特殊值明确标识该进程控制块尚未分配有效的进程ID，避免了与有效进程ID的混淆。

状态字段 `state` 设置为 `PROC_UNINIT` 符合进程生命周期的自然规律，新创建的进程确实应该处于未初始化状态，等待后续的完整设置。

对于 `context` 结构体，我们采用全零初始化，这确保了在第一次上下文切换时不会使用到随机的内存值，保证了系统的稳定性。

### 问题回答
首先定位到
`proc_struct`结构的位置（`proc.h`），结构信息如下所示：
```c
struct proc_struct
{
    enum proc_state state;        // Process state
    int pid;                      // Process ID
    int runs;                     // the running times of Proces
    uintptr_t kstack;             // Process kernel stack
    volatile bool need_resched;   // bool value: need to be rescheduled to release CPU?
    struct proc_struct *parent;   // the parent process
    struct mm_struct *mm;         // Process's memory management field
    struct context context;       // Switch here to run process
    struct trapframe *tf;         // Trap frame for current interrupt
    uintptr_t pgdir;              // the base addr of Page Directroy Table(PDT)
    uint32_t flags;               // Process flag
    char name[PROC_NAME_LEN + 1]; // Process name
    list_entry_t list_link;       // Process link list
    list_entry_t hash_link;       // Process hash list
};
```

#### struct context context 的含义和作用

 `struct context` 保存了进程的上下文信息，包括返回地址(ra)、栈指针(sp)和保存的寄存器(s0-s11)。这些是在进程切换时需要保存和恢复的处理器状态。
```c
struct context
{
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};

```

**作用：** 在RISC-V架构中，ra寄存器用于存储函数返回地址，sp是栈指针，而s0-s11是被调用者保存的寄存器。这些寄存器在函数调用过程中需要被保存和恢复。



当操作系统决定切换到另一个进程时，`switch_to` 函数会将当前CPU的状态保存到 `from->context` 中，然后从 `to->context` 恢复目标进程的运行状态，等到再次运行时，能够从完全相同的位置继续执行，用户完全感知不到中间发生的切换。


#### struct trapframe *tf 的含义和作用

 `struct trapframe` 保存了中断或异常发生时的处理器完整状态，包括所有通用寄存器、程序计数器(epc)、状态寄存器等。

**作用：** 
1. **中断处理**：当中断或异常发生时，硬件会自动将当前状态保存到陷阱帧中
2. **进程创建**：在创建新进程时，通过设置陷阱帧来指定进程的初始执行状态
3. **系统调用**：用户态与内核态切换时，通过陷阱帧传递参数和保存状态
4. **信号处理**：在进程接收到信号时，通过修改陷阱帧来改变执行流程

---
## 练习三

### 目标与背景
本练习主要围绕 SLOB（Simple List Of Blocks）内存分配器的实现与调试展开，重点理解 kmalloc/kfree 的大块分配与释放机制，并结合实际编译警告进行代码修正。

### 关键代码与原理
- SLOB 分配器的核心在于 `kern/mm/kmalloc.c`，其中 `slob_alloc` 负责小块分配，大块（页级）分配则通过 `__slob_get_free_pages` 实现。
- 大块释放时，`__slob_free_pages` 需要将内核虚拟地址（KVA）转换为物理页结构体指针，调用 `free_pages` 释放。
- 转换接口 `kva2page` 定义在 `kern/mm/pmm.h`，其参数类型为 `void *`。

### 编译警告分析
在编译过程中，可能出现如下警告：
```
kern/mm/kmalloc.c:92:22: warning: passing argument 1 of 'kva2page' makes pointer from integer without a cast [-Wint-conversion]
  free_pages(kva2page(kva), 1 << order);
```
原因是 `kva` 类型为 `unsigned long`，而 `kva2page` 需要 `void *`，直接传递会导致类型不兼容的警告。

### 修复方法
最直接的修复方式是在调用处进行显式类型转换：
```c
static inline void __slob_free_pages(unsigned long kva, int order)
{
    free_pages(kva2page((void *)kva), 1 << order);
}
```
这样可以消除编译器的类型转换警告，保证代码可读性和安全性。

### 代码风格建议
- 若项目中大量使用整数类型保存地址，可考虑将 `kva2page` 接口改为接受 `uintptr_t`，并统一调用方式。
- 当前项目采用显式强制类型转换，兼容性好，改动最小。

### 编译与运行
在 WSL 或 PowerShell 下，使用如下命令编译和运行：
```powershell
make
make qemu
```
如需调试，可使用：
```powershell
make debug
```

### 验证修复
- 编译后无 `-Wint-conversion` 相关警告。
- 运行 QEMU，内核正常启动，无异常。

### 总结
本练习不仅加深了对 SLOB 分配器的理解，也掌握了 C 语言指针与整数类型转换的规范写法。通过修复编译警告，提升了代码的可移植性和健壮性。

## 扩展练习 Challenge：

### 1. 开关中断实现原理

根据 `sync.h` 中的代码，`local_intr_save(intr_flag)` 和 `local_intr_restore(intr_flag)` 的具体实现如下：

#### 代码分析

```c
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);
```

#### 实现原理

**`local_intr_save(intr_flag)` 的工作流程：**
1. 通过 `read_csr(sstatus)` 读取 RISC-V 的 sstatus 控制状态寄存器
2. 检查 `SSTATUS_SIE`位，判断当前是否允许中断
3. 如果中断原本是开启的（`SSTATUS_SIE` 为1），调用 `intr_disable()` 禁用中断，返回 `1` 表示原本中断是开启状态
4. 如果中断原本就是关闭的，返回 `0`
5. 将返回值保存到 `intr_flag` 变量中

**`local_intr_restore(intr_flag)` 的工作流程：**
1. 检查 `intr_flag` 参数
2. 如果 `intr_flag` 为 `1`（表示在 `local_intr_save` 时中断是开启的）：调用 `intr_enable()` 重新开启中断
3. 如果 `intr_flag` 为 `0`，则不进行任何操作（保持中断关闭状态）


#### 作用
这种机制具有几个重要特性：它是幂等的，多次调用不会产生额外副作用；支持嵌套使用，可以在一个临界区内再进入另一个临界区；能够精确记录状态，避免过度开启或关闭中断。

在实际使用中，这对宏保护了诸如进程调度、内存分配等关键操作，确保这些操作不会被中断打断，从而维护系统数据的一致性。


### 2. 分页模式工作原理分析

#### SV32、SV39、SV48的异同

**相同点：**
- 都采用多级页表结构进行地址转换
- 页表项格式基本相同（PPN + 标志位）
- 都支持虚拟地址到物理地址的映射

**不同点：**
这三种模式的主要区别在于地址空间的大小和页表层级结构。SV32使用32位虚拟地址和2级页表，支持4GB地址空间；SV39使用39位地址和3级页表，支持512GB地址空间；SV48则使用48位地址和4级页表，支持256TB地址空间。这种层级化的设计使得操作系统能够根据实际需求选择合适的分页模式。

#### get_pte() 中相似代码段分析

在 `get_pte()` 函数中出现的两段相似代码分别处理不同级别的页表：

```c
// 第一段：处理第一级页目录
pde_t *pdep1 = &pgdir[PDX1(la)];
if (!(*pdep1 & PTE_V)) {
    // 分配页表页并初始化
    // ...
}

// 第二段：处理第二级页目录  
pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
if (!(*pdep0 & PTE_V)) {
    // 分配页表页并初始化
    // ...
}
```

**为什么如此相像：**
这两段代码都执行相同的核心操作：检查页表项有效性 → 如无效则分配新页表 → 初始化页表项。由于RISC-V的多级页表在各级具有相同的结构和处理逻辑，只是索引的计算方式不同，因此代码结构高度相似。

#### 功能拆分的思考

**当前合并写法的优点：**
- 代码简洁，减少函数调用开销
- 逻辑连贯，便于理解整个页表查找和分配过程
- 减少错误处理代码的重复

**拆分的潜在好处：**
1. **模块化**：`lookup_pte()` 只负责查找，`alloc_pte()` 只负责分配
2. **可重用性**：其他函数可能只需要查找而不需要分配
3. **错误处理**：可以更精确地处理不同类型的错误
4. **性能优化**：在已知页表存在的情况下可以避免分配逻辑



关于是否应该将查找和分配功能拆分，这实际上反映了软件工程中的经典权衡。当前的合并实现具有代码紧凑、执行路径短的优点，特别适合性能敏感的核心路径。而拆分的方案则更符合模块化设计原则，提高了代码的可重用性和可测试性。

在教学环境中，拆分可能更有利于我们理解每个步骤的职责；而在生产环境中，当前的合并实现可能更注重性能优化。一个折中的方案是保持当前的实现，但通过清晰的注释和文档来说明每个步骤的功能，这样既保证了性能，又不失代码的可读性。


---
