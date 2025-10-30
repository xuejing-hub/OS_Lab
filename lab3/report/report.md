## 练习1：完善中断处理 （需要编程）

简要说明实现过程和定时器中断中断处理的流程。

### 实现代码

```c
clock_set_next_event();
ticks++;
if (ticks % TICK_NUM == 0) {
    print_ticks();
    num++;
}
if (num == 10) {
    sbi_shutdown();
}
```

### 实现过程

1. **设置下一次时钟中断 — `clock_set_next_event()`**

   重新设定下次时钟中断触发时间（当前时间 + 固定周期），为当前时间加上100000

   > 若不重新设置，只会触发一次中断。

2. **更新全局 ticks 计数 — `ticks++`**

   `ticks` 是全局计数器，记录时钟中断触发的次数，每触发一次 timer interrupt 则加 1。

3. **每 100 次 ticks 打印一次 — `ticks % TICK_NUM == 0`**

   每 100 次时钟中断，调用一次 `print_ticks()` 打印 tick 信息，`num++` 记录打印次数。

4. **达到 10 次 Tick 输出后关机 — `sbi_shutdown()`**

   当打印 tick 次数达到 10 次后调用 `sbi_shutdown()` 关机，`sbi_shutdown()` 是 RISC-V 的 SBI 调用。


### 定时器中断处理流程

1. **初始化中断向量表**

   `idt_init()` 函数设置 `stvec` 寄存器为内核统一中断入口 `__alltraps`，捕获所有异常与中断。

2. **进入中断入口**

   当定时器触发 S 态中断时，CPU 跳转到 `__alltraps`，`SAVE_ALL` 宏将通用寄存器、`sepc`、`sstatus` 等上下文信息压入内核栈形成`trapframe`，然后执行 `mov a0, sp` 将 `trapframe` 起始地址传入a0，进入 `trap()` 函数。

3. **区分中断与异常**

   `trap()` 函数调用 `trap_dispatch()`，根据 `cause` 寄存器判断事件类型为定时器中断，跳转到 `interrupt_handler()`。

4. **处理 S 态定时器中断 IRQ_S_TIMER**

   在 `interrupt_handler()` 命中 `IRQ_S_TIMER` 分支，执行时钟处理逻辑。

5. **恢复现场并返回执行**

   中断处理结束后返回 `trapentry.S`， 执行 `RESTORE_ALL` 恢复寄存器和 CSR，执行 `sret`指令返回中断前指令继续运行。

---


## 扩展练习 Challenge1：描述与理解中断流程

### 题目：
一、描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？

二、SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？

三、对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

### 回答：

#### 一、描述ucore中处理中断异常的流程（从异常的产生开始）

1. **异常/中断产生**
   - **例子**：
     - 外部中断：时钟中断、外设中断（如键盘、串口）。
     - 内部异常：页错误、非法指令、断点、系统调用等。
   - **RISC-V 硬件自动处理**：
     1. **保存程序计数器**  
        - 当前执行的指令地址（PC）会被自动保存到 `sepc` 寄存器中，以便在处理完成后能从中断/异常处继续执行。
     2. **记录中断/异常原因**  
        - 中断或异常的类型会写入 `scause` 寄存器。  
        - 对于中断，最高位为 1；异常最高位为 0，低位编码具体类型。
     3. **记录出错地址（仅异常）**  
        - 如果发生异常（如页错误或非法指令），相关的出错地址会写入 `stval` 寄存器，提供调试信息。
     4. **跳转到异常入口**  
        - 硬件自动把 PC 设置为 `stvec` 指向的入口地址。  
        - 在 uCore 中，`stvec` 被初始化为汇编入口 `__alltraps`，所有中断和异常都会从这里统一进入内核处理。

2. **进入汇编入口：`__alltraps`**

   在 `trapentry.S` 中：

```S
   __alltraps:
      SAVE_ALL

      move  a0, sp
      jal trap
      # sp should be the same as before "jal trap"
```

**SAVE_ALL**:把 所有通用寄存器（x0~x31） 和部分 CSR（sstatus、sepc、stval、scause 等）保存到当前栈上。形成一个完整的 trapframe，方便后续 C 层处理或上下文恢复。

**move a0, sp**:把当前的栈顶指针（即 trapframe 的地址）放入 a0 寄存器。因为 RISC-V 调用约定规定函数第一个参数用 a0 传递。也就是把 trapframe 的地址传给 C 层函数 trap(struct trapframe *tf)。

**jal trap**:跳转并链接到 C 函数 trap()，执行中断或异常的分发处理。返回时 sp 没有改变，仍指向 trapframe。

3. **C 层 trap() 调度**

当异常或中断进入内核的汇编入口 `__alltraps` 后，汇编会将现场保存到栈上形成 `trapframe`，并把栈顶指针通过 `a0` 传给 C 函数 `trap()`：

```c
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    }
}

/* *
 * trap - handles or dispatches an exception/interrupt. if and when trap()
 * returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
```

tf->cause 为负值 → 表示中断→ 调用 interrupt_handler(tf) 处理

tf->cause 为非负值 → 表示异常→ 调用 exception_handler(tf) 处理

当 trap_dispatch() 返回后，控制权回到 trap()，然后返回汇编入口 __alltraps 的调用点。

4. **返回汇编层**

```S
__trapret:
    RESTORE_ALL
    # return from supervisor call
    sret
```

**RESTORE_ALL**:将 SAVE_ALL 时压入栈的寄存器和关键 CSR 依次恢复。（包括：通用寄存器：x1~x31（x0 不需要恢复，因为总是 0）、栈指针 sp、控制状态寄存器 sstatus、异常程序计数器 sepc）

**sret**:将程序计数器恢复到 sepc，继续执行原来的指令；根据 sstatus 中的 SPP 位判断返回的特权级（用户态或内核态）。

#### 一、其中mov a0，sp的目的是什么？

在 `__alltraps` 汇编入口中，有如下代码：

```S
move a0, sp
jal trap
```

sp 此时指向当前内核栈的栈顶，也就是 SAVE_ALL 压栈后形成的 trapframe 结构体的起始地址。

将 sp 的值复制到寄存器 a0，遵循 RISC-V 调用约定：函数的第一个参数通过 a0 传递。

然后调用 C 函数 trap(struct trapframe *tf)，将 trapframe 的地址传入。

**目的：**

- 将 `trapframe` 地址传递给 C 层 `trap()`，以便访问寄存器上下文和 CSR 信息。  

- 提供上下文访问：C 层可以访问通用寄存器 `x0~x31` 以及控制状态寄存器 `sstatus`、`sepc`、`stval`、`scause`。  

- 实现上下文管理：C 层可以根据 `trapframe` 内容分发处理，中断调用 `interrupt_handler()`，异常调用 `exception_handler()`。  

- 确保函数调用安全：汇编保存现场在栈中完成，通过传递栈顶指针，C 层无需了解寄存器偏移，通过结构体访问即可。


#### 二、SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的？

由 trapframe 结构体定义：

```c
struct trapframe {
    struct pushregs gpr; //保存通用寄存器 `x0~x31`
    uintptr_t status; //保存 `sstatus`
    uintptr_t epc; //保存 `sepc`
    uintptr_t badvaddr; //保存 `stval` 
    uintptr_t cause; //保存 `scause`  
};
```
汇编宏 SAVE_ALL 按照 pushregs 内部寄存器顺序压栈，再依次压入 status、epc、badvaddr、cause：

这样 C 语言中的 tf->gpr.ra、tf->status、tf->epc 等可以与栈中对应位置一一对应；

保证 trapframe 能完整反映中断前的 CPU 状态。

#### 三、对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。

- **不一定必须保存全部寄存器**：某些简单中断理论上可以只保存部分寄存器，但这样实现复杂且容易出错。  

- **uCore 采用统一保存策略**：无论中断类型，都完整保存所有寄存器，确保返回后程序状态完全一致，简化内核实现并便于调试与维护。

- **原因分析**：

  1. **中断随时发生**  
     - 中断可能在任意指令执行过程中触发，包括使用临时寄存器的函数。  
     - 如果只保存部分寄存器，返回时可能会破坏被打断程序的执行状态。

  2. **简化内核实现**  
     - 统一保存上下文可以避免针对不同中断类型做特殊处理，降低实现复杂度。  

  3. **调试与维护便利**  
     - 保存完整上下文便于调试，能够查看任意寄存器的值，方便定位问题。

  4. **性能影响可接受**  
     - 保存全部寄存器的开销在中断发生频率有限的情况下是可以接受的。

## 扩增练习 Challenge2：理解上下文切换机制

### 题目：
一、在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？

二、save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

### 回答:
#### 一、在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？

##### 1. `csrw sscratch, sp`

- 功能：将当前内核栈指针（sp）保存到 CSR 寄存器 `sscratch` 中。  
- 目的：  
  - 当发生中断或异常时，CPU 需要切换到一个安全的内核栈来保存寄存器现场。  
  - 保存原栈指针是为了在中断处理完成后能够恢复到原来的栈环境，保证上下文一致性。  
  - 避免递归中断或异常覆盖当前栈指针，确保内核栈的安全性。  

##### 2. `csrrw s0, sscratch, x0`

- 功能：  
  - 从 CSR 寄存器 `sscratch` 读取先前保存的原栈指针值，并存入通用寄存器 `s0`。  
  - 同时将 `sscratch` 清零，为下一次中断或异常做好准备。  
- 目的：  
  - 在中断返回时，可以通过 `s0` 恢复原来的栈指针（sp），确保中断前的执行环境完整恢复。  
  - 实现安全的栈切换机制：中断处理使用独立内核栈，不会破坏被中断程序的栈状态。  
  - 为内核提供稳定可靠的上下文切换基础，使内核中断处理与普通程序执行相互隔离，避免栈冲突或寄存器覆盖问题。  


#### 二、save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

##### 1. 保存的原因

- 当中断或异常发生时，硬件会自动将相关信息写入 CSR 寄存器：  
  - `stval`：异常相关地址（如访问错误的虚拟地址或指令地址）。  
  - `scause`：中断或异常的原因代码。  

- 保存这些寄存器到栈上，主要是为了 **C 层处理函数可以访问**：  
  - `trap()`、`interrupt_handler()` 和 `exception_handler()` 可以读取这些值，判断中断或异常类型。  
  - 可以用于打印调试信息或执行相应的异常处理逻辑。  
  - 为软件提供从硬件获取中断/异常信息的接口，使内核能够做出正确响应。  

##### 2. 不还原的原因

- 这些 CSR 寄存器属于 **只读或临时状态寄存器**，只在中断/异常发生时有意义：  
  - 它们记录的是当下的事件信息，而不是原程序的状态。  
  - 中断处理完成后，返回原程序继续执行时，这些值不会影响程序逻辑。  

- 恢复它们没有必要，也不会改变软件行为：  
  - 内核只关心恢复寄存器现场（通用寄存器和必要的控制状态寄存器，如 sstatus、sepc）  
  - `stval` 和 `scause` 的作用在 C 层处理完成后就结束，后续中断或异常发生时会被硬件自动覆盖。


## 扩展练习Challenge3：完善异常中断

### 实验目的

本实验旨在完善操作系统的异常处理机制，特别是对非法指令异常（Illegal Instruction）和断点异常（Breakpoint）的处理。通过捕获这两种异常并输出相关信息，加深对RISC-V架构异常处理机制的理解。

### 实验内容

编程完善在触发一条非法指令异常和断点异常，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。

### 实现代码

在`trap.c`的`exception_handler`函数中，我们添加了对两种异常的处理：

#### 1. 非法指令异常处理（CAUSE_ILLEGAL_INSTRUCTION）

```c
case CAUSE_ILLEGAL_INSTRUCTION:
    // 非法指令异常处理
    cprintf("Exception type: Illegal instruction\n");
    cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
    tf->epc += 4; 
    break;
```

#### 2. 断点异常处理（CAUSE_BREAKPOINT）

```c
case CAUSE_BREAKPOINT:
    // 断点异常处理
    cprintf("Exception type: Breakpoint\n");
    cprintf("Breakpoint caught at 0x%08x\n", tf->epc);
    tf->epc += 2; // ebreak指令长度为2字节
    break;
```

### 关键代码

#### 异常类型识别
- 通过`tf->cause`寄存器判断异常类型
- `CAUSE_ILLEGAL_INSTRUCTION`对应非法指令异常
- `CAUSE_BREAKPOINT`对应断点异常

#### 异常信息输出
- 使用`cprintf`输出指令异常类型和异常指令地址
- `tf->epc`寄存器保存了异常发生时程序计数器的值，即异常指令的地址

#### 更新`tf->epc`寄存器
- 更新`tf->epc`寄存器，使其指向下一个地址，以便在异常处理结束后程序能够正常恢复运行。
- 非法指令异常：`tf->epc += 4`（RISC-V标准指令长度为4字节）
- 断点异常：`tf->epc += 2`（ebreak指令长度为2字节）

### 断点异常问题解决

在实验过程中，断点异常处理遇到了一个重要问题：最初错误地使用了`tf->epc += 4`来处理断点异常，导致程序进入死循环。


#### 问题原因分析：
1. **指令长度差异**：在RISC-V架构中，大多数标准指令的长度为4字节，但这里实现的`ebreak`（断点）指令可能是一个特殊的压缩指令，其长度只有2字节。
2. **程序计数器更新错误**：如果使用`tf->epc += 4`，程序计数器会跳过4个字节，这实际上跳过了`ebreak`指令后的正常指令，导致程序执行流混乱。
3. **死循环机制**：错误的PC更新使得异常处理返回后，程序可能再次执行到异常触发点，或者跳转到无效的指令位置，形成无限循环。
4. **指令对齐问题**：RISC-V要求指令必须按2字节或4字节对齐，错误的PC更新可能导致程序计数器指向不对齐的地址，引发新的异常。

#### 解决方案：
将断点异常的PC更新改为`tf->epc += 2`，这样：
- 精确跳过2字节的`ebreak`指令
- 程序能够正确继续执行后续指令
- 避免了死循环问题
- 确保程序计数器保持正确的对齐

修改代码之后经过测试，证明我们的修改没有问题，代码成功运行，输出了预期的结果。


### 实验结果
在`kern_init`函数中添加两条特殊指令来触发异常
```c
asm volatile(".word 0xFFFFFFFF"); // 触发非法指令异常
asm volatile("ebreak");           // 触发断点异常
```

当内核执行到`kern_init`函数中的异常触发指令时，会输出以下信息：

```
Exception type: Illegal instruction
Illegal instruction caught at 0xc020009c
Exception type: Breakpoint
Breakpoint caught at 0xc02000a0
```

这表明系统成功捕获并处理了两种异常：
1. 在地址`0xc020009c`处捕获到非法指令异常
2. 在地址`0xc02000a0`处捕获到断点异常
