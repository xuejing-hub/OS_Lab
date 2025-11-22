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
