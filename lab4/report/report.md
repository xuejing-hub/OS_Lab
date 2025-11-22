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
## 练习3：编写proc_run 函数（需要编码）

### 一、练习目的与背景
本练习聚焦于操作系统内核的进程管理与调度机制，要求深入理解进程的生命周期、内核线程的创建与运行、以及上下文切换的底层实现。通过动手实现关键函数，掌握进程切换的原理和流程，为后续学习多进程、多线程及调度算法打下坚实基础。

操作系统通过进程管理实现多任务并发运行，进程切换是内核调度的核心。上下文切换不仅涉及寄存器、堆栈等硬件状态，还包括地址空间的切换和调度标志的维护。实验以 uCore 内核为基础，要求实现 `proc_run` 等关键函数，体验内核级线程的调度与切换。

### 二、核心原理与代码实现

#### 1. 进程切换原理
进程切换（Context Switch）是操作系统调度的核心环节。其主要任务包括：
- 保存当前进程的运行环境（寄存器、堆栈、程序计数器等）
- 恢复新进程的运行环境
- 切换地址空间（页表）
- 保证切换过程的原子性，防止中断干扰

在 RISC-V 架构下，页表基址通过 SATP 寄存器管理，切换进程时需更新该寄存器。上下文切换通过 `switch_to` 汇编函数实现，完成寄存器等硬件状态的保存与恢复。

#### 2. proc_run 函数详细实现
`proc_run` 用于将指定进程切换到 CPU 上运行，完整代码如下，并附详细注释：

```c
void proc_run(struct proc_struct *proc)
{
   if (proc != current)
   {
      unsigned long flags;
      // 1. 关闭中断，防止切换过程中被打断，保证原子性
      local_intr_save(flags);

      // 2. 保存当前进程指针，便于后续上下文切换
      struct proc_struct *prev = current;

      // 3. 切换当前进程指针，内核调度新进程
      current = proc;

      // 4. 清除新进程的 need_resched 标志，表示不需要再次调度
      //    同时增加运行次数，便于统计调度频率
      proc->need_resched = 0;
      proc->runs++;

      // 5. 切换页表，更新 SATP 寄存器，激活新进程的地址空间
      lsatp(proc->pgdir);

      // 6. 上下文切换，调用底层汇编函数，切换寄存器等硬件状态
      switch_to(&prev->context, &proc->context);

      // 7. 恢复中断，允许外部事件再次响应
      local_intr_restore(flags);
   }
}
```

#### 3. 关键流程图解

```
当前进程（prev）
   |
   |---> 关闭中断
   |---> 保存 prev 指针
   |---> 切换 current 指针
   |---> 清除 need_resched，runs++
   |---> 切换页表（SATP）
   |---> switch_to(prev, proc)
   |---> 恢复中断
新进程（proc）开始运行
```

#### 4. 相关宏与函数说明
- `local_intr_save(flags)` / `local_intr_restore(flags)`：用于关、开中断，防止切换过程中被打断。
- `lsatp(pgdir)`：切换 SATP 寄存器，激活新进程的地址空间。
- `switch_to(&prev->context, &proc->context)`：底层汇编实现的上下文切换。

#### 5. 代码调试与现象
在调试过程中，通过在 `proc_run`、`proc_init` 等关键位置添加打印语句，观察进程切换和线程创建的过程。系统启动后，首先创建 `idleproc`，随后创建 `initproc`，并输出相关信息，验证切换流程正确。

### 三、内核线程创建与运行分析

#### 1. 线程创建流程
在 `proc_init` 函数中，系统首先通过 `alloc_proc` 创建了 `idleproc`（空闲进程），并初始化其各项参数。随后调用 `kernel_thread(init_main, "Hello world!!", 0)` 创建了 `initproc`（初始化进程），并通过 `find_proc` 查找并设置其名称。

线程创建流程如下：
1. `alloc_proc` 分配并初始化进程结构体
2. `setup_kstack` 分配内核栈
3. `copy_mm` 复制或共享地址空间
4. `copy_thread` 设置 trapframe 和 context
5. `hash_proc` 加入哈希表
6. `list_add` 加入进程链表
7. `wakeup_proc` 设置为可运行状态

#### 2. 线程运行机制
`idleproc` 作为系统的守护进程，负责调度和空闲等待，始终处于运行或调度状态。`initproc` 作为初始化进程，负责系统初始化和用户进程的创建。两者均为内核线程，运行在内核态，调度由内核控制。

#### 3. 线程数量与结构
本实验实际创建并运行了两个内核线程：
- `idleproc`（pid=0）：系统启动后第一个线程，负责调度和空闲。
- `initproc`（pid=1）：第二个线程，负责初始化和后续用户线程的创建。

线程结构体 `proc_struct` 包含状态、PID、运行次数、内核栈、调度标志、父子关系、地址空间、上下文等信息，便于内核统一管理。

### 四、实验过程、现象与体会

#### 1. 编译与运行过程
在完成 `proc_run` 等函数实现后，使用 `make qemu` 进行编译和仿真运行。系统启动后，首先输出 `alloc_proc() correct!`，随后创建并运行 `initproc`，输出如下信息：

```
alloc_proc() correct!
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
```

通过这些输出，可以清晰观察到内核线程的创建和切换过程，验证了 `proc_run` 的正确性。

#### 2. 功能验证与调试技巧
- 进程切换功能正常，`proc_run` 能够正确完成上下文切换，系统能够在不同内核线程间切换。
- 线程创建流程清晰，`idleproc` 和 `initproc` 均能正常初始化和运行。
- 通过在关键位置添加断点和打印语句，观察变量变化和切换过程，提升调试效率。

#### 3. 代码细节与优化
- 充分利用宏和底层汇编函数，简化代码实现。
- 通过结构体和链表管理进程集合，提升系统扩展性。
- 关注原子性和中断管理，保证切换过程安全可靠。

#### 4. 个人收获与思考
通过本次实验，深入理解了进程切换的底层原理，包括中断管理、页表切换、上下文保存与恢复等关键环节。掌握了内核线程的创建与调度流程，体会到操作系统调度的复杂性和精细性。实验过程中，遇到编译错误和调试难题，通过查阅资料和分析代码逐步解决，提升了问题分析和解决能力。

此外，实验加深了对内核态与用户态、进程与线程、调度与切换等操作系统核心概念的理解，为后续学习多进程调度、同步机制等内容奠定了坚实基础。

### 五、结论与问题回答

本实验通过实现 `proc_run` 等关键函数，系统性地掌握了操作系统内核中的进程管理与上下文切换机制。通过实际编码、调试和现象观察，深入理解了内核线程的创建、调度与切换流程。实验不仅提升了编程能力，更加深了对操作系统原理的理解。

本次实验为后续学习多进程调度、同步机制、资源管理等内容打下了坚实基础。

---

**问题回答：**

1. **本实验创建且运行了几个内核线程？**  
   答：本实验共创建并运行了两个内核线程，分别是 `idleproc`（pid=0）和 `initproc`（pid=1）。`idleproc` 负责系统调度和空闲等待，`initproc` 负责初始化和后续用户线程的创建。

2. **proc_run 的核心实现思路？**  
   答：proc_run 首先判断是否需要切换进程，若需要则关闭中断，保存当前进程指针，切换当前进程指针，清除调度标志并增加运行次数，切换页表以激活新进程地址空间，调用底层汇编函数完成上下文切换，最后恢复中断，确保切换过程的原子性和安全性。

3. **代码编译与运行结果？**  
   答：编译通过，运行后系统能够正确输出进程创建和切换信息，`proc_run` 功能实现符合预期，内核线程能够正常切换和运行。

4. **个人体会与建议？**  
   答：本实验加深了对操作系统进程管理和调度机制的理解，建议在后续学习中进一步关注多进程调度、同步机制、死锁处理等高级内容，并结合实际项目进行深入实践。


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

