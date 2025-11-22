
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49a60613          	addi	a2,a2,1178 # ffffffffc020d4ec <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	5dd030ef          	jal	ra,ffffffffc0203e3e <memset>
    dtb_init();
ffffffffc0200066:	514000ef          	jal	ra,ffffffffc020057a <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	49e000ef          	jal	ra,ffffffffc0200508 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e2258593          	addi	a1,a1,-478 # ffffffffc0203e90 <etext+0x4>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e3a50513          	addi	a0,a0,-454 # ffffffffc0203eb0 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	15a000ef          	jal	ra,ffffffffc02001dc <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	0ca020ef          	jal	ra,ffffffffc0202150 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	0ad000ef          	jal	ra,ffffffffc0200936 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	0ab000ef          	jal	ra,ffffffffc0200938 <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	633020ef          	jal	ra,ffffffffc0202ec4 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	56a030ef          	jal	ra,ffffffffc0203600 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	41c000ef          	jal	ra,ffffffffc02004b6 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	08d000ef          	jal	ra,ffffffffc020092a <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7aa030ef          	jal	ra,ffffffffc020384c <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00004517          	auipc	a0,0x4
ffffffffc02000c0:	dfc50513          	addi	a0,a0,-516 # ffffffffc0203eb8 <etext+0x2c>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	00009b97          	auipc	s7,0x9
ffffffffc02000d6:	f5eb8b93          	addi	s7,s7,-162 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	0ee000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	0de000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	0cc000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	00009517          	auipc	a0,0x9
ffffffffc0200132:	f0250513          	addi	a0,a0,-254 # ffffffffc0209030 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	3a8000ef          	jal	ra,ffffffffc020050a <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	093030ef          	jal	ra,ffffffffc0203a1a <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	05d030ef          	jal	ra,ffffffffc0203a1a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a681                	j	ffffffffc020050a <cons_putc>

ffffffffc02001cc <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001cc:	1141                	addi	sp,sp,-16
ffffffffc02001ce:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001d0:	36e000ef          	jal	ra,ffffffffc020053e <cons_getc>
ffffffffc02001d4:	dd75                	beqz	a0,ffffffffc02001d0 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
ffffffffc02001d8:	0141                	addi	sp,sp,16
ffffffffc02001da:	8082                	ret

ffffffffc02001dc <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001dc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001de:	00004517          	auipc	a0,0x4
ffffffffc02001e2:	ce250513          	addi	a0,a0,-798 # ffffffffc0203ec0 <etext+0x34>
{
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e8:	fadff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ec:	00000597          	auipc	a1,0x0
ffffffffc02001f0:	e5e58593          	addi	a1,a1,-418 # ffffffffc020004a <kern_init>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	cec50513          	addi	a0,a0,-788 # ffffffffc0203ee0 <etext+0x54>
ffffffffc02001fc:	f99ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200200:	00004597          	auipc	a1,0x4
ffffffffc0200204:	c8c58593          	addi	a1,a1,-884 # ffffffffc0203e8c <etext>
ffffffffc0200208:	00004517          	auipc	a0,0x4
ffffffffc020020c:	cf850513          	addi	a0,a0,-776 # ffffffffc0203f00 <etext+0x74>
ffffffffc0200210:	f85ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200214:	00009597          	auipc	a1,0x9
ffffffffc0200218:	e1c58593          	addi	a1,a1,-484 # ffffffffc0209030 <buf>
ffffffffc020021c:	00004517          	auipc	a0,0x4
ffffffffc0200220:	d0450513          	addi	a0,a0,-764 # ffffffffc0203f20 <etext+0x94>
ffffffffc0200224:	f71ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200228:	0000d597          	auipc	a1,0xd
ffffffffc020022c:	2c458593          	addi	a1,a1,708 # ffffffffc020d4ec <end>
ffffffffc0200230:	00004517          	auipc	a0,0x4
ffffffffc0200234:	d1050513          	addi	a0,a0,-752 # ffffffffc0203f40 <etext+0xb4>
ffffffffc0200238:	f5dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023c:	0000d597          	auipc	a1,0xd
ffffffffc0200240:	6af58593          	addi	a1,a1,1711 # ffffffffc020d8eb <end+0x3ff>
ffffffffc0200244:	00000797          	auipc	a5,0x0
ffffffffc0200248:	e0678793          	addi	a5,a5,-506 # ffffffffc020004a <kern_init>
ffffffffc020024c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200256:	3ff5f593          	andi	a1,a1,1023
ffffffffc020025a:	95be                	add	a1,a1,a5
ffffffffc020025c:	85a9                	srai	a1,a1,0xa
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	d0250513          	addi	a0,a0,-766 # ffffffffc0203f60 <etext+0xd4>
}
ffffffffc0200266:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200268:	b735                	j	ffffffffc0200194 <cprintf>

ffffffffc020026a <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc020026a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020026c:	00004617          	auipc	a2,0x4
ffffffffc0200270:	d2460613          	addi	a2,a2,-732 # ffffffffc0203f90 <etext+0x104>
ffffffffc0200274:	04900593          	li	a1,73
ffffffffc0200278:	00004517          	auipc	a0,0x4
ffffffffc020027c:	d3050513          	addi	a0,a0,-720 # ffffffffc0203fa8 <etext+0x11c>
{
ffffffffc0200280:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200282:	1d8000ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0200286 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200286:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200288:	00004617          	auipc	a2,0x4
ffffffffc020028c:	d3860613          	addi	a2,a2,-712 # ffffffffc0203fc0 <etext+0x134>
ffffffffc0200290:	00004597          	auipc	a1,0x4
ffffffffc0200294:	d5058593          	addi	a1,a1,-688 # ffffffffc0203fe0 <etext+0x154>
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	d5050513          	addi	a0,a0,-688 # ffffffffc0203fe8 <etext+0x15c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a2:	ef3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002a6:	00004617          	auipc	a2,0x4
ffffffffc02002aa:	d5260613          	addi	a2,a2,-686 # ffffffffc0203ff8 <etext+0x16c>
ffffffffc02002ae:	00004597          	auipc	a1,0x4
ffffffffc02002b2:	d7258593          	addi	a1,a1,-654 # ffffffffc0204020 <etext+0x194>
ffffffffc02002b6:	00004517          	auipc	a0,0x4
ffffffffc02002ba:	d3250513          	addi	a0,a0,-718 # ffffffffc0203fe8 <etext+0x15c>
ffffffffc02002be:	ed7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002c2:	00004617          	auipc	a2,0x4
ffffffffc02002c6:	d6e60613          	addi	a2,a2,-658 # ffffffffc0204030 <etext+0x1a4>
ffffffffc02002ca:	00004597          	auipc	a1,0x4
ffffffffc02002ce:	d8658593          	addi	a1,a1,-634 # ffffffffc0204050 <etext+0x1c4>
ffffffffc02002d2:	00004517          	auipc	a0,0x4
ffffffffc02002d6:	d1650513          	addi	a0,a0,-746 # ffffffffc0203fe8 <etext+0x15c>
ffffffffc02002da:	ebbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e6:	1141                	addi	sp,sp,-16
ffffffffc02002e8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ea:	ef3ff0ef          	jal	ra,ffffffffc02001dc <print_kerninfo>
    return 0;
}
ffffffffc02002ee:	60a2                	ld	ra,8(sp)
ffffffffc02002f0:	4501                	li	a0,0
ffffffffc02002f2:	0141                	addi	sp,sp,16
ffffffffc02002f4:	8082                	ret

ffffffffc02002f6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f6:	1141                	addi	sp,sp,-16
ffffffffc02002f8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002fa:	f71ff0ef          	jal	ra,ffffffffc020026a <print_stackframe>
    return 0;
}
ffffffffc02002fe:	60a2                	ld	ra,8(sp)
ffffffffc0200300:	4501                	li	a0,0
ffffffffc0200302:	0141                	addi	sp,sp,16
ffffffffc0200304:	8082                	ret

ffffffffc0200306 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200306:	7115                	addi	sp,sp,-224
ffffffffc0200308:	ed5e                	sd	s7,152(sp)
ffffffffc020030a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030c:	00004517          	auipc	a0,0x4
ffffffffc0200310:	d5450513          	addi	a0,a0,-684 # ffffffffc0204060 <etext+0x1d4>
kmonitor(struct trapframe *tf) {
ffffffffc0200314:	ed86                	sd	ra,216(sp)
ffffffffc0200316:	e9a2                	sd	s0,208(sp)
ffffffffc0200318:	e5a6                	sd	s1,200(sp)
ffffffffc020031a:	e1ca                	sd	s2,192(sp)
ffffffffc020031c:	fd4e                	sd	s3,184(sp)
ffffffffc020031e:	f952                	sd	s4,176(sp)
ffffffffc0200320:	f556                	sd	s5,168(sp)
ffffffffc0200322:	f15a                	sd	s6,160(sp)
ffffffffc0200324:	e962                	sd	s8,144(sp)
ffffffffc0200326:	e566                	sd	s9,136(sp)
ffffffffc0200328:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032a:	e6bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032e:	00004517          	auipc	a0,0x4
ffffffffc0200332:	d5a50513          	addi	a0,a0,-678 # ffffffffc0204088 <etext+0x1fc>
ffffffffc0200336:	e5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc020033a:	000b8563          	beqz	s7,ffffffffc0200344 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033e:	855e                	mv	a0,s7
ffffffffc0200340:	7e0000ef          	jal	ra,ffffffffc0200b20 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	4581                	li	a1,0
ffffffffc0200348:	4601                	li	a2,0
ffffffffc020034a:	48a1                	li	a7,8
ffffffffc020034c:	00000073          	ecall
ffffffffc0200350:	00004c17          	auipc	s8,0x4
ffffffffc0200354:	da8c0c13          	addi	s8,s8,-600 # ffffffffc02040f8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200358:	00004917          	auipc	s2,0x4
ffffffffc020035c:	d5890913          	addi	s2,s2,-680 # ffffffffc02040b0 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	00004497          	auipc	s1,0x4
ffffffffc0200364:	d5848493          	addi	s1,s1,-680 # ffffffffc02040b8 <etext+0x22c>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020036a:	00004b17          	auipc	s6,0x4
ffffffffc020036e:	d56b0b13          	addi	s6,s6,-682 # ffffffffc02040c0 <etext+0x234>
        argv[argc ++] = buf;
ffffffffc0200372:	00004a17          	auipc	s4,0x4
ffffffffc0200376:	c6ea0a13          	addi	s4,s4,-914 # ffffffffc0203fe0 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020037c:	854a                	mv	a0,s2
ffffffffc020037e:	d29ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc0200382:	842a                	mv	s0,a0
ffffffffc0200384:	dd65                	beqz	a0,ffffffffc020037c <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200386:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020038a:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038c:	e1bd                	bnez	a1,ffffffffc02003f2 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc020038e:	fe0c87e3          	beqz	s9,ffffffffc020037c <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	00004d17          	auipc	s10,0x4
ffffffffc0200398:	d64d0d13          	addi	s10,s10,-668 # ffffffffc02040f8 <commands>
        argv[argc ++] = buf;
ffffffffc020039c:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	4401                	li	s0,0
ffffffffc02003a0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a2:	243030ef          	jal	ra,ffffffffc0203de4 <strcmp>
ffffffffc02003a6:	c919                	beqz	a0,ffffffffc02003bc <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a8:	2405                	addiw	s0,s0,1
ffffffffc02003aa:	0b540063          	beq	s0,s5,ffffffffc020044a <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ae:	000d3503          	ld	a0,0(s10)
ffffffffc02003b2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b6:	22f030ef          	jal	ra,ffffffffc0203de4 <strcmp>
ffffffffc02003ba:	f57d                	bnez	a0,ffffffffc02003a8 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003bc:	00141793          	slli	a5,s0,0x1
ffffffffc02003c0:	97a2                	add	a5,a5,s0
ffffffffc02003c2:	078e                	slli	a5,a5,0x3
ffffffffc02003c4:	97e2                	add	a5,a5,s8
ffffffffc02003c6:	6b9c                	ld	a5,16(a5)
ffffffffc02003c8:	865e                	mv	a2,s7
ffffffffc02003ca:	002c                	addi	a1,sp,8
ffffffffc02003cc:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003d0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003d2:	fa0555e3          	bgez	a0,ffffffffc020037c <kmonitor+0x76>
}
ffffffffc02003d6:	60ee                	ld	ra,216(sp)
ffffffffc02003d8:	644e                	ld	s0,208(sp)
ffffffffc02003da:	64ae                	ld	s1,200(sp)
ffffffffc02003dc:	690e                	ld	s2,192(sp)
ffffffffc02003de:	79ea                	ld	s3,184(sp)
ffffffffc02003e0:	7a4a                	ld	s4,176(sp)
ffffffffc02003e2:	7aaa                	ld	s5,168(sp)
ffffffffc02003e4:	7b0a                	ld	s6,160(sp)
ffffffffc02003e6:	6bea                	ld	s7,152(sp)
ffffffffc02003e8:	6c4a                	ld	s8,144(sp)
ffffffffc02003ea:	6caa                	ld	s9,136(sp)
ffffffffc02003ec:	6d0a                	ld	s10,128(sp)
ffffffffc02003ee:	612d                	addi	sp,sp,224
ffffffffc02003f0:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f2:	8526                	mv	a0,s1
ffffffffc02003f4:	235030ef          	jal	ra,ffffffffc0203e28 <strchr>
ffffffffc02003f8:	c901                	beqz	a0,ffffffffc0200408 <kmonitor+0x102>
ffffffffc02003fa:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003fe:	00040023          	sb	zero,0(s0)
ffffffffc0200402:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200404:	d5c9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200406:	b7f5                	j	ffffffffc02003f2 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200408:	00044783          	lbu	a5,0(s0)
ffffffffc020040c:	d3c9                	beqz	a5,ffffffffc020038e <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020040e:	033c8963          	beq	s9,s3,ffffffffc0200440 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200412:	003c9793          	slli	a5,s9,0x3
ffffffffc0200416:	0118                	addi	a4,sp,128
ffffffffc0200418:	97ba                	add	a5,a5,a4
ffffffffc020041a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200422:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200424:	e591                	bnez	a1,ffffffffc0200430 <kmonitor+0x12a>
ffffffffc0200426:	b7b5                	j	ffffffffc0200392 <kmonitor+0x8c>
ffffffffc0200428:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020042c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020042e:	d1a5                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200430:	8526                	mv	a0,s1
ffffffffc0200432:	1f7030ef          	jal	ra,ffffffffc0203e28 <strchr>
ffffffffc0200436:	d96d                	beqz	a0,ffffffffc0200428 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200438:	00044583          	lbu	a1,0(s0)
ffffffffc020043c:	d9a9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc020043e:	bf55                	j	ffffffffc02003f2 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200440:	45c1                	li	a1,16
ffffffffc0200442:	855a                	mv	a0,s6
ffffffffc0200444:	d51ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200448:	b7e9                	j	ffffffffc0200412 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020044a:	6582                	ld	a1,0(sp)
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	c9450513          	addi	a0,a0,-876 # ffffffffc02040e0 <etext+0x254>
ffffffffc0200454:	d41ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200458:	b715                	j	ffffffffc020037c <kmonitor+0x76>

ffffffffc020045a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020045a:	0000d317          	auipc	t1,0xd
ffffffffc020045e:	00e30313          	addi	t1,t1,14 # ffffffffc020d468 <is_panic>
ffffffffc0200462:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200466:	715d                	addi	sp,sp,-80
ffffffffc0200468:	ec06                	sd	ra,24(sp)
ffffffffc020046a:	e822                	sd	s0,16(sp)
ffffffffc020046c:	f436                	sd	a3,40(sp)
ffffffffc020046e:	f83a                	sd	a4,48(sp)
ffffffffc0200470:	fc3e                	sd	a5,56(sp)
ffffffffc0200472:	e0c2                	sd	a6,64(sp)
ffffffffc0200474:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200476:	020e1a63          	bnez	t3,ffffffffc02004aa <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020047a:	4785                	li	a5,1
ffffffffc020047c:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200480:	8432                	mv	s0,a2
ffffffffc0200482:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200484:	862e                	mv	a2,a1
ffffffffc0200486:	85aa                	mv	a1,a0
ffffffffc0200488:	00004517          	auipc	a0,0x4
ffffffffc020048c:	cb850513          	addi	a0,a0,-840 # ffffffffc0204140 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200490:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200492:	d03ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200496:	65a2                	ld	a1,8(sp)
ffffffffc0200498:	8522                	mv	a0,s0
ffffffffc020049a:	cdbff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020049e:	00005517          	auipc	a0,0x5
ffffffffc02004a2:	d5250513          	addi	a0,a0,-686 # ffffffffc02051f0 <default_pmm_manager+0x530>
ffffffffc02004a6:	cefff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02004aa:	486000ef          	jal	ra,ffffffffc0200930 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ae:	4501                	li	a0,0
ffffffffc02004b0:	e57ff0ef          	jal	ra,ffffffffc0200306 <kmonitor>
    while (1) {
ffffffffc02004b4:	bfed                	j	ffffffffc02004ae <__panic+0x54>

ffffffffc02004b6 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004b6:	67e1                	lui	a5,0x18
ffffffffc02004b8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004bc:	0000d717          	auipc	a4,0xd
ffffffffc02004c0:	faf73e23          	sd	a5,-68(a4) # ffffffffc020d478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004c4:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004c8:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ca:	953e                	add	a0,a0,a5
ffffffffc02004cc:	4601                	li	a2,0
ffffffffc02004ce:	4881                	li	a7,0
ffffffffc02004d0:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004d4:	02000793          	li	a5,32
ffffffffc02004d8:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004dc:	00004517          	auipc	a0,0x4
ffffffffc02004e0:	c8450513          	addi	a0,a0,-892 # ffffffffc0204160 <commands+0x68>
    ticks = 0;
ffffffffc02004e4:	0000d797          	auipc	a5,0xd
ffffffffc02004e8:	f807b623          	sd	zero,-116(a5) # ffffffffc020d470 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004ec:	b165                	j	ffffffffc0200194 <cprintf>

ffffffffc02004ee <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004ee:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004f2:	0000d797          	auipc	a5,0xd
ffffffffc02004f6:	f867b783          	ld	a5,-122(a5) # ffffffffc020d478 <timebase>
ffffffffc02004fa:	953e                	add	a0,a0,a5
ffffffffc02004fc:	4581                	li	a1,0
ffffffffc02004fe:	4601                	li	a2,0
ffffffffc0200500:	4881                	li	a7,0
ffffffffc0200502:	00000073          	ecall
ffffffffc0200506:	8082                	ret

ffffffffc0200508 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200508:	8082                	ret

ffffffffc020050a <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020050a:	100027f3          	csrr	a5,sstatus
ffffffffc020050e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200510:	0ff57513          	andi	a0,a0,255
ffffffffc0200514:	e799                	bnez	a5,ffffffffc0200522 <cons_putc+0x18>
ffffffffc0200516:	4581                	li	a1,0
ffffffffc0200518:	4601                	li	a2,0
ffffffffc020051a:	4885                	li	a7,1
ffffffffc020051c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200520:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200522:	1101                	addi	sp,sp,-32
ffffffffc0200524:	ec06                	sd	ra,24(sp)
ffffffffc0200526:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200528:	408000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020052c:	6522                	ld	a0,8(sp)
ffffffffc020052e:	4581                	li	a1,0
ffffffffc0200530:	4601                	li	a2,0
ffffffffc0200532:	4885                	li	a7,1
ffffffffc0200534:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200538:	60e2                	ld	ra,24(sp)
ffffffffc020053a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020053c:	a6fd                	j	ffffffffc020092a <intr_enable>

ffffffffc020053e <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020053e:	100027f3          	csrr	a5,sstatus
ffffffffc0200542:	8b89                	andi	a5,a5,2
ffffffffc0200544:	eb89                	bnez	a5,ffffffffc0200556 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200546:	4501                	li	a0,0
ffffffffc0200548:	4581                	li	a1,0
ffffffffc020054a:	4601                	li	a2,0
ffffffffc020054c:	4889                	li	a7,2
ffffffffc020054e:	00000073          	ecall
ffffffffc0200552:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200554:	8082                	ret
int cons_getc(void) {
ffffffffc0200556:	1101                	addi	sp,sp,-32
ffffffffc0200558:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020055a:	3d6000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	4581                	li	a1,0
ffffffffc0200562:	4601                	li	a2,0
ffffffffc0200564:	4889                	li	a7,2
ffffffffc0200566:	00000073          	ecall
ffffffffc020056a:	2501                	sext.w	a0,a0
ffffffffc020056c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020056e:	3bc000ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0200572:	60e2                	ld	ra,24(sp)
ffffffffc0200574:	6522                	ld	a0,8(sp)
ffffffffc0200576:	6105                	addi	sp,sp,32
ffffffffc0200578:	8082                	ret

ffffffffc020057a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020057a:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020057c:	00004517          	auipc	a0,0x4
ffffffffc0200580:	c0450513          	addi	a0,a0,-1020 # ffffffffc0204180 <commands+0x88>
void dtb_init(void) {
ffffffffc0200584:	fc86                	sd	ra,120(sp)
ffffffffc0200586:	f8a2                	sd	s0,112(sp)
ffffffffc0200588:	e8d2                	sd	s4,80(sp)
ffffffffc020058a:	f4a6                	sd	s1,104(sp)
ffffffffc020058c:	f0ca                	sd	s2,96(sp)
ffffffffc020058e:	ecce                	sd	s3,88(sp)
ffffffffc0200590:	e4d6                	sd	s5,72(sp)
ffffffffc0200592:	e0da                	sd	s6,64(sp)
ffffffffc0200594:	fc5e                	sd	s7,56(sp)
ffffffffc0200596:	f862                	sd	s8,48(sp)
ffffffffc0200598:	f466                	sd	s9,40(sp)
ffffffffc020059a:	f06a                	sd	s10,32(sp)
ffffffffc020059c:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020059e:	bf7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005a2:	00009597          	auipc	a1,0x9
ffffffffc02005a6:	a5e5b583          	ld	a1,-1442(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02005aa:	00004517          	auipc	a0,0x4
ffffffffc02005ae:	be650513          	addi	a0,a0,-1050 # ffffffffc0204190 <commands+0x98>
ffffffffc02005b2:	be3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005b6:	00009417          	auipc	s0,0x9
ffffffffc02005ba:	a5240413          	addi	s0,s0,-1454 # ffffffffc0209008 <boot_dtb>
ffffffffc02005be:	600c                	ld	a1,0(s0)
ffffffffc02005c0:	00004517          	auipc	a0,0x4
ffffffffc02005c4:	be050513          	addi	a0,a0,-1056 # ffffffffc02041a0 <commands+0xa8>
ffffffffc02005c8:	bcdff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005cc:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005d0:	00004517          	auipc	a0,0x4
ffffffffc02005d4:	be850513          	addi	a0,a0,-1048 # ffffffffc02041b8 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02005d8:	120a0463          	beqz	s4,ffffffffc0200700 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005dc:	57f5                	li	a5,-3
ffffffffc02005de:	07fa                	slli	a5,a5,0x1e
ffffffffc02005e0:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005e4:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ea:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005f0:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f4:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f8:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200600:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200602:	8ec9                	or	a3,a3,a0
ffffffffc0200604:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200608:	1b7d                	addi	s6,s6,-1
ffffffffc020060a:	0167f7b3          	and	a5,a5,s6
ffffffffc020060e:	8dd5                	or	a1,a1,a3
ffffffffc0200610:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200612:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200618:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a01>
ffffffffc020061c:	10f59163          	bne	a1,a5,ffffffffc020071e <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200620:	471c                	lw	a5,8(a4)
ffffffffc0200622:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200624:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020062a:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020062e:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200632:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200636:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020063a:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200642:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200646:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064e:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	01146433          	or	s0,s0,a7
ffffffffc0200654:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200658:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200662:	8c49                	or	s0,s0,a0
ffffffffc0200664:	0166f6b3          	and	a3,a3,s6
ffffffffc0200668:	00ca6a33          	or	s4,s4,a2
ffffffffc020066c:	0167f7b3          	and	a5,a5,s6
ffffffffc0200670:	8c55                	or	s0,s0,a3
ffffffffc0200672:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200676:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200678:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020067a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020067c:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200680:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200682:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200688:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020068a:	00004917          	auipc	s2,0x4
ffffffffc020068e:	b7e90913          	addi	s2,s2,-1154 # ffffffffc0204208 <commands+0x110>
ffffffffc0200692:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200694:	4d91                	li	s11,4
ffffffffc0200696:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200698:	00004497          	auipc	s1,0x4
ffffffffc020069c:	b6848493          	addi	s1,s1,-1176 # ffffffffc0204200 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a0:	000a2703          	lw	a4,0(s4)
ffffffffc02006a4:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a8:	0087569b          	srliw	a3,a4,0x8
ffffffffc02006ac:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0107571b          	srliw	a4,a4,0x10
ffffffffc02006bc:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02006c6:	8fd5                	or	a5,a5,a3
ffffffffc02006c8:	00eb7733          	and	a4,s6,a4
ffffffffc02006cc:	8fd9                	or	a5,a5,a4
ffffffffc02006ce:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02006d0:	09778c63          	beq	a5,s7,ffffffffc0200768 <dtb_init+0x1ee>
ffffffffc02006d4:	00fbea63          	bltu	s7,a5,ffffffffc02006e8 <dtb_init+0x16e>
ffffffffc02006d8:	07a78663          	beq	a5,s10,ffffffffc0200744 <dtb_init+0x1ca>
ffffffffc02006dc:	4709                	li	a4,2
ffffffffc02006de:	00e79763          	bne	a5,a4,ffffffffc02006ec <dtb_init+0x172>
ffffffffc02006e2:	4c81                	li	s9,0
ffffffffc02006e4:	8a56                	mv	s4,s5
ffffffffc02006e6:	bf6d                	j	ffffffffc02006a0 <dtb_init+0x126>
ffffffffc02006e8:	ffb78ee3          	beq	a5,s11,ffffffffc02006e4 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006ec:	00004517          	auipc	a0,0x4
ffffffffc02006f0:	b9450513          	addi	a0,a0,-1132 # ffffffffc0204280 <commands+0x188>
ffffffffc02006f4:	aa1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	bc050513          	addi	a0,a0,-1088 # ffffffffc02042b8 <commands+0x1c0>
}
ffffffffc0200700:	7446                	ld	s0,112(sp)
ffffffffc0200702:	70e6                	ld	ra,120(sp)
ffffffffc0200704:	74a6                	ld	s1,104(sp)
ffffffffc0200706:	7906                	ld	s2,96(sp)
ffffffffc0200708:	69e6                	ld	s3,88(sp)
ffffffffc020070a:	6a46                	ld	s4,80(sp)
ffffffffc020070c:	6aa6                	ld	s5,72(sp)
ffffffffc020070e:	6b06                	ld	s6,64(sp)
ffffffffc0200710:	7be2                	ld	s7,56(sp)
ffffffffc0200712:	7c42                	ld	s8,48(sp)
ffffffffc0200714:	7ca2                	ld	s9,40(sp)
ffffffffc0200716:	7d02                	ld	s10,32(sp)
ffffffffc0200718:	6de2                	ld	s11,24(sp)
ffffffffc020071a:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020071c:	bca5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc020071e:	7446                	ld	s0,112(sp)
ffffffffc0200720:	70e6                	ld	ra,120(sp)
ffffffffc0200722:	74a6                	ld	s1,104(sp)
ffffffffc0200724:	7906                	ld	s2,96(sp)
ffffffffc0200726:	69e6                	ld	s3,88(sp)
ffffffffc0200728:	6a46                	ld	s4,80(sp)
ffffffffc020072a:	6aa6                	ld	s5,72(sp)
ffffffffc020072c:	6b06                	ld	s6,64(sp)
ffffffffc020072e:	7be2                	ld	s7,56(sp)
ffffffffc0200730:	7c42                	ld	s8,48(sp)
ffffffffc0200732:	7ca2                	ld	s9,40(sp)
ffffffffc0200734:	7d02                	ld	s10,32(sp)
ffffffffc0200736:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200738:	00004517          	auipc	a0,0x4
ffffffffc020073c:	aa050513          	addi	a0,a0,-1376 # ffffffffc02041d8 <commands+0xe0>
}
ffffffffc0200740:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200742:	bc89                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc0200744:	8556                	mv	a0,s5
ffffffffc0200746:	656030ef          	jal	ra,ffffffffc0203d9c <strlen>
ffffffffc020074a:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020074c:	4619                	li	a2,6
ffffffffc020074e:	85a6                	mv	a1,s1
ffffffffc0200750:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200752:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200754:	6ae030ef          	jal	ra,ffffffffc0203e02 <strncmp>
ffffffffc0200758:	e111                	bnez	a0,ffffffffc020075c <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020075a:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020075c:	0a91                	addi	s5,s5,4
ffffffffc020075e:	9ad2                	add	s5,s5,s4
ffffffffc0200760:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200764:	8a56                	mv	s4,s5
ffffffffc0200766:	bf2d                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200768:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020076c:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200774:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200778:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200784:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200790:	00eaeab3          	or	s5,s5,a4
ffffffffc0200794:	00fb77b3          	and	a5,s6,a5
ffffffffc0200798:	00faeab3          	or	s5,s5,a5
ffffffffc020079c:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020079e:	000c9c63          	bnez	s9,ffffffffc02007b6 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02007a2:	1a82                	slli	s5,s5,0x20
ffffffffc02007a4:	00368793          	addi	a5,a3,3
ffffffffc02007a8:	020ada93          	srli	s5,s5,0x20
ffffffffc02007ac:	9abe                	add	s5,s5,a5
ffffffffc02007ae:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007b2:	8a56                	mv	s4,s5
ffffffffc02007b4:	b5f5                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007b6:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	85ca                	mv	a1,s2
ffffffffc02007bc:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007be:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c6:	0187971b          	slliw	a4,a5,0x18
ffffffffc02007ca:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02007d2:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d4:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007dc:	8d59                	or	a0,a0,a4
ffffffffc02007de:	00fb77b3          	and	a5,s6,a5
ffffffffc02007e2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007e4:	1502                	slli	a0,a0,0x20
ffffffffc02007e6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007e8:	9522                	add	a0,a0,s0
ffffffffc02007ea:	5fa030ef          	jal	ra,ffffffffc0203de4 <strcmp>
ffffffffc02007ee:	66a2                	ld	a3,8(sp)
ffffffffc02007f0:	f94d                	bnez	a0,ffffffffc02007a2 <dtb_init+0x228>
ffffffffc02007f2:	fb59f8e3          	bgeu	s3,s5,ffffffffc02007a2 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007f6:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007fa:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007fe:	00004517          	auipc	a0,0x4
ffffffffc0200802:	a1250513          	addi	a0,a0,-1518 # ffffffffc0204210 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080a:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020080e:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200812:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200816:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020081a:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020081e:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200822:	0187d693          	srli	a3,a5,0x18
ffffffffc0200826:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020082a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020082e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200836:	010f6f33          	or	t5,t5,a6
ffffffffc020083a:	0187529b          	srliw	t0,a4,0x18
ffffffffc020083e:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0186f6b3          	and	a3,a3,s8
ffffffffc020084e:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200852:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0107581b          	srliw	a6,a4,0x10
ffffffffc020085a:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085e:	8361                	srli	a4,a4,0x18
ffffffffc0200860:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200864:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200868:	01e6e6b3          	or	a3,a3,t5
ffffffffc020086c:	00cb7633          	and	a2,s6,a2
ffffffffc0200870:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200874:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200878:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020087c:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200880:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200884:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200888:	0088989b          	slliw	a7,a7,0x8
ffffffffc020088c:	011b78b3          	and	a7,s6,a7
ffffffffc0200890:	005eeeb3          	or	t4,t4,t0
ffffffffc0200894:	00c6e733          	or	a4,a3,a2
ffffffffc0200898:	006c6c33          	or	s8,s8,t1
ffffffffc020089c:	010b76b3          	and	a3,s6,a6
ffffffffc02008a0:	00bb7b33          	and	s6,s6,a1
ffffffffc02008a4:	01d7e7b3          	or	a5,a5,t4
ffffffffc02008a8:	016c6b33          	or	s6,s8,s6
ffffffffc02008ac:	01146433          	or	s0,s0,a7
ffffffffc02008b0:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02008b2:	1702                	slli	a4,a4,0x20
ffffffffc02008b4:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008b6:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008b8:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008ba:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008bc:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008c0:	0167eb33          	or	s6,a5,s6
ffffffffc02008c4:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008c6:	8cfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008ca:	85a2                	mv	a1,s0
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	96450513          	addi	a0,a0,-1692 # ffffffffc0204230 <commands+0x138>
ffffffffc02008d4:	8c1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008d8:	014b5613          	srli	a2,s6,0x14
ffffffffc02008dc:	85da                	mv	a1,s6
ffffffffc02008de:	00004517          	auipc	a0,0x4
ffffffffc02008e2:	96a50513          	addi	a0,a0,-1686 # ffffffffc0204248 <commands+0x150>
ffffffffc02008e6:	8afff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008ea:	008b05b3          	add	a1,s6,s0
ffffffffc02008ee:	15fd                	addi	a1,a1,-1
ffffffffc02008f0:	00004517          	auipc	a0,0x4
ffffffffc02008f4:	97850513          	addi	a0,a0,-1672 # ffffffffc0204268 <commands+0x170>
ffffffffc02008f8:	89dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02008fc:	00004517          	auipc	a0,0x4
ffffffffc0200900:	9bc50513          	addi	a0,a0,-1604 # ffffffffc02042b8 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200904:	0000d797          	auipc	a5,0xd
ffffffffc0200908:	b687be23          	sd	s0,-1156(a5) # ffffffffc020d480 <memory_base>
        memory_size = mem_size;
ffffffffc020090c:	0000d797          	auipc	a5,0xd
ffffffffc0200910:	b767be23          	sd	s6,-1156(a5) # ffffffffc020d488 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200914:	b3f5                	j	ffffffffc0200700 <dtb_init+0x186>

ffffffffc0200916 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200916:	0000d517          	auipc	a0,0xd
ffffffffc020091a:	b6a53503          	ld	a0,-1174(a0) # ffffffffc020d480 <memory_base>
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200920:	0000d517          	auipc	a0,0xd
ffffffffc0200924:	b6853503          	ld	a0,-1176(a0) # ffffffffc020d488 <memory_size>
ffffffffc0200928:	8082                	ret

ffffffffc020092a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020092a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200936:	8082                	ret

ffffffffc0200938 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200938:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020093c:	00000797          	auipc	a5,0x0
ffffffffc0200940:	3e478793          	addi	a5,a5,996 # ffffffffc0200d20 <__alltraps>
ffffffffc0200944:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200948:	000407b7          	lui	a5,0x40
ffffffffc020094c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200950:	8082                	ret

ffffffffc0200952 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200952:	610c                	ld	a1,0(a0)
{
ffffffffc0200954:	1141                	addi	sp,sp,-16
ffffffffc0200956:	e022                	sd	s0,0(sp)
ffffffffc0200958:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020095a:	00004517          	auipc	a0,0x4
ffffffffc020095e:	97650513          	addi	a0,a0,-1674 # ffffffffc02042d0 <commands+0x1d8>
{
ffffffffc0200962:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200964:	831ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200968:	640c                	ld	a1,8(s0)
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	97e50513          	addi	a0,a0,-1666 # ffffffffc02042e8 <commands+0x1f0>
ffffffffc0200972:	823ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200976:	680c                	ld	a1,16(s0)
ffffffffc0200978:	00004517          	auipc	a0,0x4
ffffffffc020097c:	98850513          	addi	a0,a0,-1656 # ffffffffc0204300 <commands+0x208>
ffffffffc0200980:	815ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200984:	6c0c                	ld	a1,24(s0)
ffffffffc0200986:	00004517          	auipc	a0,0x4
ffffffffc020098a:	99250513          	addi	a0,a0,-1646 # ffffffffc0204318 <commands+0x220>
ffffffffc020098e:	807ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200992:	700c                	ld	a1,32(s0)
ffffffffc0200994:	00004517          	auipc	a0,0x4
ffffffffc0200998:	99c50513          	addi	a0,a0,-1636 # ffffffffc0204330 <commands+0x238>
ffffffffc020099c:	ff8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009a0:	740c                	ld	a1,40(s0)
ffffffffc02009a2:	00004517          	auipc	a0,0x4
ffffffffc02009a6:	9a650513          	addi	a0,a0,-1626 # ffffffffc0204348 <commands+0x250>
ffffffffc02009aa:	feaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009ae:	780c                	ld	a1,48(s0)
ffffffffc02009b0:	00004517          	auipc	a0,0x4
ffffffffc02009b4:	9b050513          	addi	a0,a0,-1616 # ffffffffc0204360 <commands+0x268>
ffffffffc02009b8:	fdcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009bc:	7c0c                	ld	a1,56(s0)
ffffffffc02009be:	00004517          	auipc	a0,0x4
ffffffffc02009c2:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0204378 <commands+0x280>
ffffffffc02009c6:	fceff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009ca:	602c                	ld	a1,64(s0)
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	9c450513          	addi	a0,a0,-1596 # ffffffffc0204390 <commands+0x298>
ffffffffc02009d4:	fc0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009d8:	642c                	ld	a1,72(s0)
ffffffffc02009da:	00004517          	auipc	a0,0x4
ffffffffc02009de:	9ce50513          	addi	a0,a0,-1586 # ffffffffc02043a8 <commands+0x2b0>
ffffffffc02009e2:	fb2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009e6:	682c                	ld	a1,80(s0)
ffffffffc02009e8:	00004517          	auipc	a0,0x4
ffffffffc02009ec:	9d850513          	addi	a0,a0,-1576 # ffffffffc02043c0 <commands+0x2c8>
ffffffffc02009f0:	fa4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009f4:	6c2c                	ld	a1,88(s0)
ffffffffc02009f6:	00004517          	auipc	a0,0x4
ffffffffc02009fa:	9e250513          	addi	a0,a0,-1566 # ffffffffc02043d8 <commands+0x2e0>
ffffffffc02009fe:	f96ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a02:	702c                	ld	a1,96(s0)
ffffffffc0200a04:	00004517          	auipc	a0,0x4
ffffffffc0200a08:	9ec50513          	addi	a0,a0,-1556 # ffffffffc02043f0 <commands+0x2f8>
ffffffffc0200a0c:	f88ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a10:	742c                	ld	a1,104(s0)
ffffffffc0200a12:	00004517          	auipc	a0,0x4
ffffffffc0200a16:	9f650513          	addi	a0,a0,-1546 # ffffffffc0204408 <commands+0x310>
ffffffffc0200a1a:	f7aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a1e:	782c                	ld	a1,112(s0)
ffffffffc0200a20:	00004517          	auipc	a0,0x4
ffffffffc0200a24:	a0050513          	addi	a0,a0,-1536 # ffffffffc0204420 <commands+0x328>
ffffffffc0200a28:	f6cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a2c:	7c2c                	ld	a1,120(s0)
ffffffffc0200a2e:	00004517          	auipc	a0,0x4
ffffffffc0200a32:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0204438 <commands+0x340>
ffffffffc0200a36:	f5eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a3a:	604c                	ld	a1,128(s0)
ffffffffc0200a3c:	00004517          	auipc	a0,0x4
ffffffffc0200a40:	a1450513          	addi	a0,a0,-1516 # ffffffffc0204450 <commands+0x358>
ffffffffc0200a44:	f50ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a48:	644c                	ld	a1,136(s0)
ffffffffc0200a4a:	00004517          	auipc	a0,0x4
ffffffffc0200a4e:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0204468 <commands+0x370>
ffffffffc0200a52:	f42ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a56:	684c                	ld	a1,144(s0)
ffffffffc0200a58:	00004517          	auipc	a0,0x4
ffffffffc0200a5c:	a2850513          	addi	a0,a0,-1496 # ffffffffc0204480 <commands+0x388>
ffffffffc0200a60:	f34ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a64:	6c4c                	ld	a1,152(s0)
ffffffffc0200a66:	00004517          	auipc	a0,0x4
ffffffffc0200a6a:	a3250513          	addi	a0,a0,-1486 # ffffffffc0204498 <commands+0x3a0>
ffffffffc0200a6e:	f26ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a72:	704c                	ld	a1,160(s0)
ffffffffc0200a74:	00004517          	auipc	a0,0x4
ffffffffc0200a78:	a3c50513          	addi	a0,a0,-1476 # ffffffffc02044b0 <commands+0x3b8>
ffffffffc0200a7c:	f18ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a80:	744c                	ld	a1,168(s0)
ffffffffc0200a82:	00004517          	auipc	a0,0x4
ffffffffc0200a86:	a4650513          	addi	a0,a0,-1466 # ffffffffc02044c8 <commands+0x3d0>
ffffffffc0200a8a:	f0aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a8e:	784c                	ld	a1,176(s0)
ffffffffc0200a90:	00004517          	auipc	a0,0x4
ffffffffc0200a94:	a5050513          	addi	a0,a0,-1456 # ffffffffc02044e0 <commands+0x3e8>
ffffffffc0200a98:	efcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a9c:	7c4c                	ld	a1,184(s0)
ffffffffc0200a9e:	00004517          	auipc	a0,0x4
ffffffffc0200aa2:	a5a50513          	addi	a0,a0,-1446 # ffffffffc02044f8 <commands+0x400>
ffffffffc0200aa6:	eeeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aaa:	606c                	ld	a1,192(s0)
ffffffffc0200aac:	00004517          	auipc	a0,0x4
ffffffffc0200ab0:	a6450513          	addi	a0,a0,-1436 # ffffffffc0204510 <commands+0x418>
ffffffffc0200ab4:	ee0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200ab8:	646c                	ld	a1,200(s0)
ffffffffc0200aba:	00004517          	auipc	a0,0x4
ffffffffc0200abe:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0204528 <commands+0x430>
ffffffffc0200ac2:	ed2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200ac6:	686c                	ld	a1,208(s0)
ffffffffc0200ac8:	00004517          	auipc	a0,0x4
ffffffffc0200acc:	a7850513          	addi	a0,a0,-1416 # ffffffffc0204540 <commands+0x448>
ffffffffc0200ad0:	ec4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ad4:	6c6c                	ld	a1,216(s0)
ffffffffc0200ad6:	00004517          	auipc	a0,0x4
ffffffffc0200ada:	a8250513          	addi	a0,a0,-1406 # ffffffffc0204558 <commands+0x460>
ffffffffc0200ade:	eb6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ae2:	706c                	ld	a1,224(s0)
ffffffffc0200ae4:	00004517          	auipc	a0,0x4
ffffffffc0200ae8:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0204570 <commands+0x478>
ffffffffc0200aec:	ea8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200af0:	746c                	ld	a1,232(s0)
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	a9650513          	addi	a0,a0,-1386 # ffffffffc0204588 <commands+0x490>
ffffffffc0200afa:	e9aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200afe:	786c                	ld	a1,240(s0)
ffffffffc0200b00:	00004517          	auipc	a0,0x4
ffffffffc0200b04:	aa050513          	addi	a0,a0,-1376 # ffffffffc02045a0 <commands+0x4a8>
ffffffffc0200b08:	e8cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b0c:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b0e:	6402                	ld	s0,0(sp)
ffffffffc0200b10:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b12:	00004517          	auipc	a0,0x4
ffffffffc0200b16:	aa650513          	addi	a0,a0,-1370 # ffffffffc02045b8 <commands+0x4c0>
}
ffffffffc0200b1a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b1c:	e78ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b20 <print_trapframe>:
{
ffffffffc0200b20:	1141                	addi	sp,sp,-16
ffffffffc0200b22:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b24:	85aa                	mv	a1,a0
{
ffffffffc0200b26:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b28:	00004517          	auipc	a0,0x4
ffffffffc0200b2c:	aa850513          	addi	a0,a0,-1368 # ffffffffc02045d0 <commands+0x4d8>
{
ffffffffc0200b30:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b32:	e62ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b36:	8522                	mv	a0,s0
ffffffffc0200b38:	e1bff0ef          	jal	ra,ffffffffc0200952 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b3c:	10043583          	ld	a1,256(s0)
ffffffffc0200b40:	00004517          	auipc	a0,0x4
ffffffffc0200b44:	aa850513          	addi	a0,a0,-1368 # ffffffffc02045e8 <commands+0x4f0>
ffffffffc0200b48:	e4cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b4c:	10843583          	ld	a1,264(s0)
ffffffffc0200b50:	00004517          	auipc	a0,0x4
ffffffffc0200b54:	ab050513          	addi	a0,a0,-1360 # ffffffffc0204600 <commands+0x508>
ffffffffc0200b58:	e3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b5c:	11043583          	ld	a1,272(s0)
ffffffffc0200b60:	00004517          	auipc	a0,0x4
ffffffffc0200b64:	ab850513          	addi	a0,a0,-1352 # ffffffffc0204618 <commands+0x520>
ffffffffc0200b68:	e2cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b6c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b70:	6402                	ld	s0,0(sp)
ffffffffc0200b72:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b74:	00004517          	auipc	a0,0x4
ffffffffc0200b78:	abc50513          	addi	a0,a0,-1348 # ffffffffc0204630 <commands+0x538>
}
ffffffffc0200b7c:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b82 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b82:	11853783          	ld	a5,280(a0)
ffffffffc0200b86:	472d                	li	a4,11
ffffffffc0200b88:	0786                	slli	a5,a5,0x1
ffffffffc0200b8a:	8385                	srli	a5,a5,0x1
ffffffffc0200b8c:	08f76d63          	bltu	a4,a5,ffffffffc0200c26 <interrupt_handler+0xa4>
ffffffffc0200b90:	00004717          	auipc	a4,0x4
ffffffffc0200b94:	b6870713          	addi	a4,a4,-1176 # ffffffffc02046f8 <commands+0x600>
ffffffffc0200b98:	078a                	slli	a5,a5,0x2
ffffffffc0200b9a:	97ba                	add	a5,a5,a4
ffffffffc0200b9c:	439c                	lw	a5,0(a5)
ffffffffc0200b9e:	97ba                	add	a5,a5,a4
ffffffffc0200ba0:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ba2:	00004517          	auipc	a0,0x4
ffffffffc0200ba6:	b0650513          	addi	a0,a0,-1274 # ffffffffc02046a8 <commands+0x5b0>
ffffffffc0200baa:	deaff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200bae:	00004517          	auipc	a0,0x4
ffffffffc0200bb2:	ada50513          	addi	a0,a0,-1318 # ffffffffc0204688 <commands+0x590>
ffffffffc0200bb6:	ddeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bba:	00004517          	auipc	a0,0x4
ffffffffc0200bbe:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0204648 <commands+0x550>
ffffffffc0200bc2:	dd2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bc6:	00004517          	auipc	a0,0x4
ffffffffc0200bca:	aa250513          	addi	a0,a0,-1374 # ffffffffc0204668 <commands+0x570>
ffffffffc0200bce:	dc6ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200bd2:	1141                	addi	sp,sp,-16
ffffffffc0200bd4:	e022                	sd	s0,0(sp)
ffffffffc0200bd6:	e406                	sd	ra,8(sp)
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event();
ffffffffc0200bd8:	917ff0ef          	jal	ra,ffffffffc02004ee <clock_set_next_event>
        ticks++;
ffffffffc0200bdc:	0000d797          	auipc	a5,0xd
ffffffffc0200be0:	89478793          	addi	a5,a5,-1900 # ffffffffc020d470 <ticks>
ffffffffc0200be4:	6398                	ld	a4,0(a5)
ffffffffc0200be6:	0000d417          	auipc	s0,0xd
ffffffffc0200bea:	8aa40413          	addi	s0,s0,-1878 # ffffffffc020d490 <num>
ffffffffc0200bee:	0705                	addi	a4,a4,1
ffffffffc0200bf0:	e398                	sd	a4,0(a5)
        if (ticks % TICK_NUM == 0) {
ffffffffc0200bf2:	639c                	ld	a5,0(a5)
ffffffffc0200bf4:	06400713          	li	a4,100
ffffffffc0200bf8:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200bfc:	c795                	beqz	a5,ffffffffc0200c28 <interrupt_handler+0xa6>
            print_ticks();
            num++;
        }
        if (num == 10) {
ffffffffc0200bfe:	6018                	ld	a4,0(s0)
ffffffffc0200c00:	47a9                	li	a5,10
ffffffffc0200c02:	00f71863          	bne	a4,a5,ffffffffc0200c12 <interrupt_handler+0x90>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c06:	4501                	li	a0,0
ffffffffc0200c08:	4581                	li	a1,0
ffffffffc0200c0a:	4601                	li	a2,0
ffffffffc0200c0c:	48a1                	li	a7,8
ffffffffc0200c0e:	00000073          	ecall
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c12:	60a2                	ld	ra,8(sp)
ffffffffc0200c14:	6402                	ld	s0,0(sp)
ffffffffc0200c16:	0141                	addi	sp,sp,16
ffffffffc0200c18:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c1a:	00004517          	auipc	a0,0x4
ffffffffc0200c1e:	abe50513          	addi	a0,a0,-1346 # ffffffffc02046d8 <commands+0x5e0>
ffffffffc0200c22:	d72ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c26:	bded                	j	ffffffffc0200b20 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c28:	06400593          	li	a1,100
ffffffffc0200c2c:	00004517          	auipc	a0,0x4
ffffffffc0200c30:	a9c50513          	addi	a0,a0,-1380 # ffffffffc02046c8 <commands+0x5d0>
ffffffffc0200c34:	d60ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            num++;
ffffffffc0200c38:	601c                	ld	a5,0(s0)
ffffffffc0200c3a:	0785                	addi	a5,a5,1
ffffffffc0200c3c:	e01c                	sd	a5,0(s0)
ffffffffc0200c3e:	b7c1                	j	ffffffffc0200bfe <interrupt_handler+0x7c>

ffffffffc0200c40 <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c40:	11853783          	ld	a5,280(a0)
ffffffffc0200c44:	473d                	li	a4,15
ffffffffc0200c46:	0cf76563          	bltu	a4,a5,ffffffffc0200d10 <exception_handler+0xd0>
ffffffffc0200c4a:	00004717          	auipc	a4,0x4
ffffffffc0200c4e:	c7670713          	addi	a4,a4,-906 # ffffffffc02048c0 <commands+0x7c8>
ffffffffc0200c52:	078a                	slli	a5,a5,0x2
ffffffffc0200c54:	97ba                	add	a5,a5,a4
ffffffffc0200c56:	439c                	lw	a5,0(a5)
ffffffffc0200c58:	97ba                	add	a5,a5,a4
ffffffffc0200c5a:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200c5c:	00004517          	auipc	a0,0x4
ffffffffc0200c60:	c4c50513          	addi	a0,a0,-948 # ffffffffc02048a8 <commands+0x7b0>
ffffffffc0200c64:	d30ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200c68:	00004517          	auipc	a0,0x4
ffffffffc0200c6c:	ac050513          	addi	a0,a0,-1344 # ffffffffc0204728 <commands+0x630>
ffffffffc0200c70:	d24ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200c74:	00004517          	auipc	a0,0x4
ffffffffc0200c78:	ad450513          	addi	a0,a0,-1324 # ffffffffc0204748 <commands+0x650>
ffffffffc0200c7c:	d18ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200c80:	00004517          	auipc	a0,0x4
ffffffffc0200c84:	ae850513          	addi	a0,a0,-1304 # ffffffffc0204768 <commands+0x670>
ffffffffc0200c88:	d0cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200c8c:	00004517          	auipc	a0,0x4
ffffffffc0200c90:	af450513          	addi	a0,a0,-1292 # ffffffffc0204780 <commands+0x688>
ffffffffc0200c94:	d00ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200c98:	00004517          	auipc	a0,0x4
ffffffffc0200c9c:	af850513          	addi	a0,a0,-1288 # ffffffffc0204790 <commands+0x698>
ffffffffc0200ca0:	cf4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200ca4:	00004517          	auipc	a0,0x4
ffffffffc0200ca8:	b0c50513          	addi	a0,a0,-1268 # ffffffffc02047b0 <commands+0x6b8>
ffffffffc0200cac:	ce8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200cb0:	00004517          	auipc	a0,0x4
ffffffffc0200cb4:	b1850513          	addi	a0,a0,-1256 # ffffffffc02047c8 <commands+0x6d0>
ffffffffc0200cb8:	cdcff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200cbc:	00004517          	auipc	a0,0x4
ffffffffc0200cc0:	b2450513          	addi	a0,a0,-1244 # ffffffffc02047e0 <commands+0x6e8>
ffffffffc0200cc4:	cd0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200cc8:	00004517          	auipc	a0,0x4
ffffffffc0200ccc:	b3050513          	addi	a0,a0,-1232 # ffffffffc02047f8 <commands+0x700>
ffffffffc0200cd0:	cc4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200cd4:	00004517          	auipc	a0,0x4
ffffffffc0200cd8:	b4450513          	addi	a0,a0,-1212 # ffffffffc0204818 <commands+0x720>
ffffffffc0200cdc:	cb8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200ce0:	00004517          	auipc	a0,0x4
ffffffffc0200ce4:	b5850513          	addi	a0,a0,-1192 # ffffffffc0204838 <commands+0x740>
ffffffffc0200ce8:	cacff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200cec:	00004517          	auipc	a0,0x4
ffffffffc0200cf0:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204858 <commands+0x760>
ffffffffc0200cf4:	ca0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200cf8:	00004517          	auipc	a0,0x4
ffffffffc0200cfc:	b8050513          	addi	a0,a0,-1152 # ffffffffc0204878 <commands+0x780>
ffffffffc0200d00:	c94ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200d04:	00004517          	auipc	a0,0x4
ffffffffc0200d08:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0204890 <commands+0x798>
ffffffffc0200d0c:	c88ff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200d10:	bd01                	j	ffffffffc0200b20 <print_trapframe>

ffffffffc0200d12 <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d12:	11853783          	ld	a5,280(a0)
ffffffffc0200d16:	0007c363          	bltz	a5,ffffffffc0200d1c <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200d1a:	b71d                	j	ffffffffc0200c40 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200d1c:	b59d                	j	ffffffffc0200b82 <interrupt_handler>
	...

ffffffffc0200d20 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200d20:	14011073          	csrw	sscratch,sp
ffffffffc0200d24:	712d                	addi	sp,sp,-288
ffffffffc0200d26:	e406                	sd	ra,8(sp)
ffffffffc0200d28:	ec0e                	sd	gp,24(sp)
ffffffffc0200d2a:	f012                	sd	tp,32(sp)
ffffffffc0200d2c:	f416                	sd	t0,40(sp)
ffffffffc0200d2e:	f81a                	sd	t1,48(sp)
ffffffffc0200d30:	fc1e                	sd	t2,56(sp)
ffffffffc0200d32:	e0a2                	sd	s0,64(sp)
ffffffffc0200d34:	e4a6                	sd	s1,72(sp)
ffffffffc0200d36:	e8aa                	sd	a0,80(sp)
ffffffffc0200d38:	ecae                	sd	a1,88(sp)
ffffffffc0200d3a:	f0b2                	sd	a2,96(sp)
ffffffffc0200d3c:	f4b6                	sd	a3,104(sp)
ffffffffc0200d3e:	f8ba                	sd	a4,112(sp)
ffffffffc0200d40:	fcbe                	sd	a5,120(sp)
ffffffffc0200d42:	e142                	sd	a6,128(sp)
ffffffffc0200d44:	e546                	sd	a7,136(sp)
ffffffffc0200d46:	e94a                	sd	s2,144(sp)
ffffffffc0200d48:	ed4e                	sd	s3,152(sp)
ffffffffc0200d4a:	f152                	sd	s4,160(sp)
ffffffffc0200d4c:	f556                	sd	s5,168(sp)
ffffffffc0200d4e:	f95a                	sd	s6,176(sp)
ffffffffc0200d50:	fd5e                	sd	s7,184(sp)
ffffffffc0200d52:	e1e2                	sd	s8,192(sp)
ffffffffc0200d54:	e5e6                	sd	s9,200(sp)
ffffffffc0200d56:	e9ea                	sd	s10,208(sp)
ffffffffc0200d58:	edee                	sd	s11,216(sp)
ffffffffc0200d5a:	f1f2                	sd	t3,224(sp)
ffffffffc0200d5c:	f5f6                	sd	t4,232(sp)
ffffffffc0200d5e:	f9fa                	sd	t5,240(sp)
ffffffffc0200d60:	fdfe                	sd	t6,248(sp)
ffffffffc0200d62:	14002473          	csrr	s0,sscratch
ffffffffc0200d66:	100024f3          	csrr	s1,sstatus
ffffffffc0200d6a:	14102973          	csrr	s2,sepc
ffffffffc0200d6e:	143029f3          	csrr	s3,stval
ffffffffc0200d72:	14202a73          	csrr	s4,scause
ffffffffc0200d76:	e822                	sd	s0,16(sp)
ffffffffc0200d78:	e226                	sd	s1,256(sp)
ffffffffc0200d7a:	e64a                	sd	s2,264(sp)
ffffffffc0200d7c:	ea4e                	sd	s3,272(sp)
ffffffffc0200d7e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d80:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d82:	f91ff0ef          	jal	ra,ffffffffc0200d12 <trap>

ffffffffc0200d86 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d86:	6492                	ld	s1,256(sp)
ffffffffc0200d88:	6932                	ld	s2,264(sp)
ffffffffc0200d8a:	10049073          	csrw	sstatus,s1
ffffffffc0200d8e:	14191073          	csrw	sepc,s2
ffffffffc0200d92:	60a2                	ld	ra,8(sp)
ffffffffc0200d94:	61e2                	ld	gp,24(sp)
ffffffffc0200d96:	7202                	ld	tp,32(sp)
ffffffffc0200d98:	72a2                	ld	t0,40(sp)
ffffffffc0200d9a:	7342                	ld	t1,48(sp)
ffffffffc0200d9c:	73e2                	ld	t2,56(sp)
ffffffffc0200d9e:	6406                	ld	s0,64(sp)
ffffffffc0200da0:	64a6                	ld	s1,72(sp)
ffffffffc0200da2:	6546                	ld	a0,80(sp)
ffffffffc0200da4:	65e6                	ld	a1,88(sp)
ffffffffc0200da6:	7606                	ld	a2,96(sp)
ffffffffc0200da8:	76a6                	ld	a3,104(sp)
ffffffffc0200daa:	7746                	ld	a4,112(sp)
ffffffffc0200dac:	77e6                	ld	a5,120(sp)
ffffffffc0200dae:	680a                	ld	a6,128(sp)
ffffffffc0200db0:	68aa                	ld	a7,136(sp)
ffffffffc0200db2:	694a                	ld	s2,144(sp)
ffffffffc0200db4:	69ea                	ld	s3,152(sp)
ffffffffc0200db6:	7a0a                	ld	s4,160(sp)
ffffffffc0200db8:	7aaa                	ld	s5,168(sp)
ffffffffc0200dba:	7b4a                	ld	s6,176(sp)
ffffffffc0200dbc:	7bea                	ld	s7,184(sp)
ffffffffc0200dbe:	6c0e                	ld	s8,192(sp)
ffffffffc0200dc0:	6cae                	ld	s9,200(sp)
ffffffffc0200dc2:	6d4e                	ld	s10,208(sp)
ffffffffc0200dc4:	6dee                	ld	s11,216(sp)
ffffffffc0200dc6:	7e0e                	ld	t3,224(sp)
ffffffffc0200dc8:	7eae                	ld	t4,232(sp)
ffffffffc0200dca:	7f4e                	ld	t5,240(sp)
ffffffffc0200dcc:	7fee                	ld	t6,248(sp)
ffffffffc0200dce:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200dd0:	10200073          	sret

ffffffffc0200dd4 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200dd4:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dd6:	bf45                	j	ffffffffc0200d86 <__trapret>
	...

ffffffffc0200dda <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200dda:	00008797          	auipc	a5,0x8
ffffffffc0200dde:	65678793          	addi	a5,a5,1622 # ffffffffc0209430 <free_area>
ffffffffc0200de2:	e79c                	sd	a5,8(a5)
ffffffffc0200de4:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200de6:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200dea:	8082                	ret

ffffffffc0200dec <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200dec:	00008517          	auipc	a0,0x8
ffffffffc0200df0:	65456503          	lwu	a0,1620(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200df4:	8082                	ret

ffffffffc0200df6 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200df6:	715d                	addi	sp,sp,-80
ffffffffc0200df8:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200dfa:	00008417          	auipc	s0,0x8
ffffffffc0200dfe:	63640413          	addi	s0,s0,1590 # ffffffffc0209430 <free_area>
ffffffffc0200e02:	641c                	ld	a5,8(s0)
ffffffffc0200e04:	e486                	sd	ra,72(sp)
ffffffffc0200e06:	fc26                	sd	s1,56(sp)
ffffffffc0200e08:	f84a                	sd	s2,48(sp)
ffffffffc0200e0a:	f44e                	sd	s3,40(sp)
ffffffffc0200e0c:	f052                	sd	s4,32(sp)
ffffffffc0200e0e:	ec56                	sd	s5,24(sp)
ffffffffc0200e10:	e85a                	sd	s6,16(sp)
ffffffffc0200e12:	e45e                	sd	s7,8(sp)
ffffffffc0200e14:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e16:	2a878d63          	beq	a5,s0,ffffffffc02010d0 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200e1a:	4481                	li	s1,0
ffffffffc0200e1c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e1e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e22:	8b09                	andi	a4,a4,2
ffffffffc0200e24:	2a070a63          	beqz	a4,ffffffffc02010d8 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200e28:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e2c:	679c                	ld	a5,8(a5)
ffffffffc0200e2e:	2905                	addiw	s2,s2,1
ffffffffc0200e30:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e32:	fe8796e3          	bne	a5,s0,ffffffffc0200e1e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e36:	89a6                	mv	s3,s1
ffffffffc0200e38:	6d1000ef          	jal	ra,ffffffffc0201d08 <nr_free_pages>
ffffffffc0200e3c:	6f351e63          	bne	a0,s3,ffffffffc0201538 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e40:	4505                	li	a0,1
ffffffffc0200e42:	649000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200e46:	8aaa                	mv	s5,a0
ffffffffc0200e48:	42050863          	beqz	a0,ffffffffc0201278 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e4c:	4505                	li	a0,1
ffffffffc0200e4e:	63d000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200e52:	89aa                	mv	s3,a0
ffffffffc0200e54:	70050263          	beqz	a0,ffffffffc0201558 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e58:	4505                	li	a0,1
ffffffffc0200e5a:	631000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200e5e:	8a2a                	mv	s4,a0
ffffffffc0200e60:	48050c63          	beqz	a0,ffffffffc02012f8 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e64:	293a8a63          	beq	s5,s3,ffffffffc02010f8 <default_check+0x302>
ffffffffc0200e68:	28aa8863          	beq	s5,a0,ffffffffc02010f8 <default_check+0x302>
ffffffffc0200e6c:	28a98663          	beq	s3,a0,ffffffffc02010f8 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e70:	000aa783          	lw	a5,0(s5)
ffffffffc0200e74:	2a079263          	bnez	a5,ffffffffc0201118 <default_check+0x322>
ffffffffc0200e78:	0009a783          	lw	a5,0(s3)
ffffffffc0200e7c:	28079e63          	bnez	a5,ffffffffc0201118 <default_check+0x322>
ffffffffc0200e80:	411c                	lw	a5,0(a0)
ffffffffc0200e82:	28079b63          	bnez	a5,ffffffffc0201118 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200e86:	0000c797          	auipc	a5,0xc
ffffffffc0200e8a:	6327b783          	ld	a5,1586(a5) # ffffffffc020d4b8 <pages>
ffffffffc0200e8e:	40fa8733          	sub	a4,s5,a5
ffffffffc0200e92:	00005617          	auipc	a2,0x5
ffffffffc0200e96:	b4663603          	ld	a2,-1210(a2) # ffffffffc02059d8 <nbase>
ffffffffc0200e9a:	8719                	srai	a4,a4,0x6
ffffffffc0200e9c:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e9e:	0000c697          	auipc	a3,0xc
ffffffffc0200ea2:	6126b683          	ld	a3,1554(a3) # ffffffffc020d4b0 <npage>
ffffffffc0200ea6:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ea8:	0732                	slli	a4,a4,0xc
ffffffffc0200eaa:	28d77763          	bgeu	a4,a3,ffffffffc0201138 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200eae:	40f98733          	sub	a4,s3,a5
ffffffffc0200eb2:	8719                	srai	a4,a4,0x6
ffffffffc0200eb4:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200eb6:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200eb8:	4cd77063          	bgeu	a4,a3,ffffffffc0201378 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200ebc:	40f507b3          	sub	a5,a0,a5
ffffffffc0200ec0:	8799                	srai	a5,a5,0x6
ffffffffc0200ec2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ec4:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ec6:	30d7f963          	bgeu	a5,a3,ffffffffc02011d8 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200eca:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ecc:	00043c03          	ld	s8,0(s0)
ffffffffc0200ed0:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200ed4:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200ed8:	e400                	sd	s0,8(s0)
ffffffffc0200eda:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200edc:	00008797          	auipc	a5,0x8
ffffffffc0200ee0:	5607a223          	sw	zero,1380(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200ee4:	5a7000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200ee8:	2c051863          	bnez	a0,ffffffffc02011b8 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200eec:	4585                	li	a1,1
ffffffffc0200eee:	8556                	mv	a0,s5
ffffffffc0200ef0:	5d9000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    free_page(p1);
ffffffffc0200ef4:	4585                	li	a1,1
ffffffffc0200ef6:	854e                	mv	a0,s3
ffffffffc0200ef8:	5d1000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    free_page(p2);
ffffffffc0200efc:	4585                	li	a1,1
ffffffffc0200efe:	8552                	mv	a0,s4
ffffffffc0200f00:	5c9000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    assert(nr_free == 3);
ffffffffc0200f04:	4818                	lw	a4,16(s0)
ffffffffc0200f06:	478d                	li	a5,3
ffffffffc0200f08:	28f71863          	bne	a4,a5,ffffffffc0201198 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f0c:	4505                	li	a0,1
ffffffffc0200f0e:	57d000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200f12:	89aa                	mv	s3,a0
ffffffffc0200f14:	26050263          	beqz	a0,ffffffffc0201178 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f18:	4505                	li	a0,1
ffffffffc0200f1a:	571000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200f1e:	8aaa                	mv	s5,a0
ffffffffc0200f20:	3a050c63          	beqz	a0,ffffffffc02012d8 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f24:	4505                	li	a0,1
ffffffffc0200f26:	565000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200f2a:	8a2a                	mv	s4,a0
ffffffffc0200f2c:	38050663          	beqz	a0,ffffffffc02012b8 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200f30:	4505                	li	a0,1
ffffffffc0200f32:	559000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200f36:	36051163          	bnez	a0,ffffffffc0201298 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200f3a:	4585                	li	a1,1
ffffffffc0200f3c:	854e                	mv	a0,s3
ffffffffc0200f3e:	58b000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f42:	641c                	ld	a5,8(s0)
ffffffffc0200f44:	20878a63          	beq	a5,s0,ffffffffc0201158 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200f48:	4505                	li	a0,1
ffffffffc0200f4a:	541000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200f4e:	30a99563          	bne	s3,a0,ffffffffc0201258 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200f52:	4505                	li	a0,1
ffffffffc0200f54:	537000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200f58:	2e051063          	bnez	a0,ffffffffc0201238 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200f5c:	481c                	lw	a5,16(s0)
ffffffffc0200f5e:	2a079d63          	bnez	a5,ffffffffc0201218 <default_check+0x422>
    free_page(p);
ffffffffc0200f62:	854e                	mv	a0,s3
ffffffffc0200f64:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f66:	01843023          	sd	s8,0(s0)
ffffffffc0200f6a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f6e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f72:	557000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    free_page(p1);
ffffffffc0200f76:	4585                	li	a1,1
ffffffffc0200f78:	8556                	mv	a0,s5
ffffffffc0200f7a:	54f000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    free_page(p2);
ffffffffc0200f7e:	4585                	li	a1,1
ffffffffc0200f80:	8552                	mv	a0,s4
ffffffffc0200f82:	547000ef          	jal	ra,ffffffffc0201cc8 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f86:	4515                	li	a0,5
ffffffffc0200f88:	503000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200f8c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f8e:	26050563          	beqz	a0,ffffffffc02011f8 <default_check+0x402>
ffffffffc0200f92:	651c                	ld	a5,8(a0)
ffffffffc0200f94:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f96:	8b85                	andi	a5,a5,1
ffffffffc0200f98:	54079063          	bnez	a5,ffffffffc02014d8 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f9c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f9e:	00043b03          	ld	s6,0(s0)
ffffffffc0200fa2:	00843a83          	ld	s5,8(s0)
ffffffffc0200fa6:	e000                	sd	s0,0(s0)
ffffffffc0200fa8:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200faa:	4e1000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200fae:	50051563          	bnez	a0,ffffffffc02014b8 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200fb2:	08098a13          	addi	s4,s3,128
ffffffffc0200fb6:	8552                	mv	a0,s4
ffffffffc0200fb8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200fba:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200fbe:	00008797          	auipc	a5,0x8
ffffffffc0200fc2:	4807a123          	sw	zero,1154(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200fc6:	503000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200fca:	4511                	li	a0,4
ffffffffc0200fcc:	4bf000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200fd0:	4c051463          	bnez	a0,ffffffffc0201498 <default_check+0x6a2>
ffffffffc0200fd4:	0889b783          	ld	a5,136(s3)
ffffffffc0200fd8:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200fda:	8b85                	andi	a5,a5,1
ffffffffc0200fdc:	48078e63          	beqz	a5,ffffffffc0201478 <default_check+0x682>
ffffffffc0200fe0:	0909a703          	lw	a4,144(s3)
ffffffffc0200fe4:	478d                	li	a5,3
ffffffffc0200fe6:	48f71963          	bne	a4,a5,ffffffffc0201478 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200fea:	450d                	li	a0,3
ffffffffc0200fec:	49f000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200ff0:	8c2a                	mv	s8,a0
ffffffffc0200ff2:	46050363          	beqz	a0,ffffffffc0201458 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0200ff6:	4505                	li	a0,1
ffffffffc0200ff8:	493000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0200ffc:	42051e63          	bnez	a0,ffffffffc0201438 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201000:	418a1c63          	bne	s4,s8,ffffffffc0201418 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201004:	4585                	li	a1,1
ffffffffc0201006:	854e                	mv	a0,s3
ffffffffc0201008:	4c1000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    free_pages(p1, 3);
ffffffffc020100c:	458d                	li	a1,3
ffffffffc020100e:	8552                	mv	a0,s4
ffffffffc0201010:	4b9000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
ffffffffc0201014:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201018:	04098c13          	addi	s8,s3,64
ffffffffc020101c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020101e:	8b85                	andi	a5,a5,1
ffffffffc0201020:	3c078c63          	beqz	a5,ffffffffc02013f8 <default_check+0x602>
ffffffffc0201024:	0109a703          	lw	a4,16(s3)
ffffffffc0201028:	4785                	li	a5,1
ffffffffc020102a:	3cf71763          	bne	a4,a5,ffffffffc02013f8 <default_check+0x602>
ffffffffc020102e:	008a3783          	ld	a5,8(s4)
ffffffffc0201032:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201034:	8b85                	andi	a5,a5,1
ffffffffc0201036:	3a078163          	beqz	a5,ffffffffc02013d8 <default_check+0x5e2>
ffffffffc020103a:	010a2703          	lw	a4,16(s4)
ffffffffc020103e:	478d                	li	a5,3
ffffffffc0201040:	38f71c63          	bne	a4,a5,ffffffffc02013d8 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201044:	4505                	li	a0,1
ffffffffc0201046:	445000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc020104a:	36a99763          	bne	s3,a0,ffffffffc02013b8 <default_check+0x5c2>
    free_page(p0);
ffffffffc020104e:	4585                	li	a1,1
ffffffffc0201050:	479000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201054:	4509                	li	a0,2
ffffffffc0201056:	435000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc020105a:	32aa1f63          	bne	s4,a0,ffffffffc0201398 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020105e:	4589                	li	a1,2
ffffffffc0201060:	469000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    free_page(p2);
ffffffffc0201064:	4585                	li	a1,1
ffffffffc0201066:	8562                	mv	a0,s8
ffffffffc0201068:	461000ef          	jal	ra,ffffffffc0201cc8 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020106c:	4515                	li	a0,5
ffffffffc020106e:	41d000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc0201072:	89aa                	mv	s3,a0
ffffffffc0201074:	48050263          	beqz	a0,ffffffffc02014f8 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201078:	4505                	li	a0,1
ffffffffc020107a:	411000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
ffffffffc020107e:	2c051d63          	bnez	a0,ffffffffc0201358 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201082:	481c                	lw	a5,16(s0)
ffffffffc0201084:	2a079a63          	bnez	a5,ffffffffc0201338 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201088:	4595                	li	a1,5
ffffffffc020108a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020108c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201090:	01643023          	sd	s6,0(s0)
ffffffffc0201094:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201098:	431000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
    return listelm->next;
ffffffffc020109c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020109e:	00878963          	beq	a5,s0,ffffffffc02010b0 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02010a2:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010a6:	679c                	ld	a5,8(a5)
ffffffffc02010a8:	397d                	addiw	s2,s2,-1
ffffffffc02010aa:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010ac:	fe879be3          	bne	a5,s0,ffffffffc02010a2 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02010b0:	26091463          	bnez	s2,ffffffffc0201318 <default_check+0x522>
    assert(total == 0);
ffffffffc02010b4:	46049263          	bnez	s1,ffffffffc0201518 <default_check+0x722>
}
ffffffffc02010b8:	60a6                	ld	ra,72(sp)
ffffffffc02010ba:	6406                	ld	s0,64(sp)
ffffffffc02010bc:	74e2                	ld	s1,56(sp)
ffffffffc02010be:	7942                	ld	s2,48(sp)
ffffffffc02010c0:	79a2                	ld	s3,40(sp)
ffffffffc02010c2:	7a02                	ld	s4,32(sp)
ffffffffc02010c4:	6ae2                	ld	s5,24(sp)
ffffffffc02010c6:	6b42                	ld	s6,16(sp)
ffffffffc02010c8:	6ba2                	ld	s7,8(sp)
ffffffffc02010ca:	6c02                	ld	s8,0(sp)
ffffffffc02010cc:	6161                	addi	sp,sp,80
ffffffffc02010ce:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010d0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02010d2:	4481                	li	s1,0
ffffffffc02010d4:	4901                	li	s2,0
ffffffffc02010d6:	b38d                	j	ffffffffc0200e38 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02010d8:	00004697          	auipc	a3,0x4
ffffffffc02010dc:	82868693          	addi	a3,a3,-2008 # ffffffffc0204900 <commands+0x808>
ffffffffc02010e0:	00004617          	auipc	a2,0x4
ffffffffc02010e4:	83060613          	addi	a2,a2,-2000 # ffffffffc0204910 <commands+0x818>
ffffffffc02010e8:	0f000593          	li	a1,240
ffffffffc02010ec:	00004517          	auipc	a0,0x4
ffffffffc02010f0:	83c50513          	addi	a0,a0,-1988 # ffffffffc0204928 <commands+0x830>
ffffffffc02010f4:	b66ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010f8:	00004697          	auipc	a3,0x4
ffffffffc02010fc:	8c868693          	addi	a3,a3,-1848 # ffffffffc02049c0 <commands+0x8c8>
ffffffffc0201100:	00004617          	auipc	a2,0x4
ffffffffc0201104:	81060613          	addi	a2,a2,-2032 # ffffffffc0204910 <commands+0x818>
ffffffffc0201108:	0bd00593          	li	a1,189
ffffffffc020110c:	00004517          	auipc	a0,0x4
ffffffffc0201110:	81c50513          	addi	a0,a0,-2020 # ffffffffc0204928 <commands+0x830>
ffffffffc0201114:	b46ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201118:	00004697          	auipc	a3,0x4
ffffffffc020111c:	8d068693          	addi	a3,a3,-1840 # ffffffffc02049e8 <commands+0x8f0>
ffffffffc0201120:	00003617          	auipc	a2,0x3
ffffffffc0201124:	7f060613          	addi	a2,a2,2032 # ffffffffc0204910 <commands+0x818>
ffffffffc0201128:	0be00593          	li	a1,190
ffffffffc020112c:	00003517          	auipc	a0,0x3
ffffffffc0201130:	7fc50513          	addi	a0,a0,2044 # ffffffffc0204928 <commands+0x830>
ffffffffc0201134:	b26ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201138:	00004697          	auipc	a3,0x4
ffffffffc020113c:	8f068693          	addi	a3,a3,-1808 # ffffffffc0204a28 <commands+0x930>
ffffffffc0201140:	00003617          	auipc	a2,0x3
ffffffffc0201144:	7d060613          	addi	a2,a2,2000 # ffffffffc0204910 <commands+0x818>
ffffffffc0201148:	0c000593          	li	a1,192
ffffffffc020114c:	00003517          	auipc	a0,0x3
ffffffffc0201150:	7dc50513          	addi	a0,a0,2012 # ffffffffc0204928 <commands+0x830>
ffffffffc0201154:	b06ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201158:	00004697          	auipc	a3,0x4
ffffffffc020115c:	95868693          	addi	a3,a3,-1704 # ffffffffc0204ab0 <commands+0x9b8>
ffffffffc0201160:	00003617          	auipc	a2,0x3
ffffffffc0201164:	7b060613          	addi	a2,a2,1968 # ffffffffc0204910 <commands+0x818>
ffffffffc0201168:	0d900593          	li	a1,217
ffffffffc020116c:	00003517          	auipc	a0,0x3
ffffffffc0201170:	7bc50513          	addi	a0,a0,1980 # ffffffffc0204928 <commands+0x830>
ffffffffc0201174:	ae6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201178:	00003697          	auipc	a3,0x3
ffffffffc020117c:	7e868693          	addi	a3,a3,2024 # ffffffffc0204960 <commands+0x868>
ffffffffc0201180:	00003617          	auipc	a2,0x3
ffffffffc0201184:	79060613          	addi	a2,a2,1936 # ffffffffc0204910 <commands+0x818>
ffffffffc0201188:	0d200593          	li	a1,210
ffffffffc020118c:	00003517          	auipc	a0,0x3
ffffffffc0201190:	79c50513          	addi	a0,a0,1948 # ffffffffc0204928 <commands+0x830>
ffffffffc0201194:	ac6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 3);
ffffffffc0201198:	00004697          	auipc	a3,0x4
ffffffffc020119c:	90868693          	addi	a3,a3,-1784 # ffffffffc0204aa0 <commands+0x9a8>
ffffffffc02011a0:	00003617          	auipc	a2,0x3
ffffffffc02011a4:	77060613          	addi	a2,a2,1904 # ffffffffc0204910 <commands+0x818>
ffffffffc02011a8:	0d000593          	li	a1,208
ffffffffc02011ac:	00003517          	auipc	a0,0x3
ffffffffc02011b0:	77c50513          	addi	a0,a0,1916 # ffffffffc0204928 <commands+0x830>
ffffffffc02011b4:	aa6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011b8:	00004697          	auipc	a3,0x4
ffffffffc02011bc:	8d068693          	addi	a3,a3,-1840 # ffffffffc0204a88 <commands+0x990>
ffffffffc02011c0:	00003617          	auipc	a2,0x3
ffffffffc02011c4:	75060613          	addi	a2,a2,1872 # ffffffffc0204910 <commands+0x818>
ffffffffc02011c8:	0cb00593          	li	a1,203
ffffffffc02011cc:	00003517          	auipc	a0,0x3
ffffffffc02011d0:	75c50513          	addi	a0,a0,1884 # ffffffffc0204928 <commands+0x830>
ffffffffc02011d4:	a86ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02011d8:	00004697          	auipc	a3,0x4
ffffffffc02011dc:	89068693          	addi	a3,a3,-1904 # ffffffffc0204a68 <commands+0x970>
ffffffffc02011e0:	00003617          	auipc	a2,0x3
ffffffffc02011e4:	73060613          	addi	a2,a2,1840 # ffffffffc0204910 <commands+0x818>
ffffffffc02011e8:	0c200593          	li	a1,194
ffffffffc02011ec:	00003517          	auipc	a0,0x3
ffffffffc02011f0:	73c50513          	addi	a0,a0,1852 # ffffffffc0204928 <commands+0x830>
ffffffffc02011f4:	a66ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != NULL);
ffffffffc02011f8:	00004697          	auipc	a3,0x4
ffffffffc02011fc:	90068693          	addi	a3,a3,-1792 # ffffffffc0204af8 <commands+0xa00>
ffffffffc0201200:	00003617          	auipc	a2,0x3
ffffffffc0201204:	71060613          	addi	a2,a2,1808 # ffffffffc0204910 <commands+0x818>
ffffffffc0201208:	0f800593          	li	a1,248
ffffffffc020120c:	00003517          	auipc	a0,0x3
ffffffffc0201210:	71c50513          	addi	a0,a0,1820 # ffffffffc0204928 <commands+0x830>
ffffffffc0201214:	a46ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201218:	00004697          	auipc	a3,0x4
ffffffffc020121c:	8d068693          	addi	a3,a3,-1840 # ffffffffc0204ae8 <commands+0x9f0>
ffffffffc0201220:	00003617          	auipc	a2,0x3
ffffffffc0201224:	6f060613          	addi	a2,a2,1776 # ffffffffc0204910 <commands+0x818>
ffffffffc0201228:	0df00593          	li	a1,223
ffffffffc020122c:	00003517          	auipc	a0,0x3
ffffffffc0201230:	6fc50513          	addi	a0,a0,1788 # ffffffffc0204928 <commands+0x830>
ffffffffc0201234:	a26ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201238:	00004697          	auipc	a3,0x4
ffffffffc020123c:	85068693          	addi	a3,a3,-1968 # ffffffffc0204a88 <commands+0x990>
ffffffffc0201240:	00003617          	auipc	a2,0x3
ffffffffc0201244:	6d060613          	addi	a2,a2,1744 # ffffffffc0204910 <commands+0x818>
ffffffffc0201248:	0dd00593          	li	a1,221
ffffffffc020124c:	00003517          	auipc	a0,0x3
ffffffffc0201250:	6dc50513          	addi	a0,a0,1756 # ffffffffc0204928 <commands+0x830>
ffffffffc0201254:	a06ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201258:	00004697          	auipc	a3,0x4
ffffffffc020125c:	87068693          	addi	a3,a3,-1936 # ffffffffc0204ac8 <commands+0x9d0>
ffffffffc0201260:	00003617          	auipc	a2,0x3
ffffffffc0201264:	6b060613          	addi	a2,a2,1712 # ffffffffc0204910 <commands+0x818>
ffffffffc0201268:	0dc00593          	li	a1,220
ffffffffc020126c:	00003517          	auipc	a0,0x3
ffffffffc0201270:	6bc50513          	addi	a0,a0,1724 # ffffffffc0204928 <commands+0x830>
ffffffffc0201274:	9e6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201278:	00003697          	auipc	a3,0x3
ffffffffc020127c:	6e868693          	addi	a3,a3,1768 # ffffffffc0204960 <commands+0x868>
ffffffffc0201280:	00003617          	auipc	a2,0x3
ffffffffc0201284:	69060613          	addi	a2,a2,1680 # ffffffffc0204910 <commands+0x818>
ffffffffc0201288:	0b900593          	li	a1,185
ffffffffc020128c:	00003517          	auipc	a0,0x3
ffffffffc0201290:	69c50513          	addi	a0,a0,1692 # ffffffffc0204928 <commands+0x830>
ffffffffc0201294:	9c6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201298:	00003697          	auipc	a3,0x3
ffffffffc020129c:	7f068693          	addi	a3,a3,2032 # ffffffffc0204a88 <commands+0x990>
ffffffffc02012a0:	00003617          	auipc	a2,0x3
ffffffffc02012a4:	67060613          	addi	a2,a2,1648 # ffffffffc0204910 <commands+0x818>
ffffffffc02012a8:	0d600593          	li	a1,214
ffffffffc02012ac:	00003517          	auipc	a0,0x3
ffffffffc02012b0:	67c50513          	addi	a0,a0,1660 # ffffffffc0204928 <commands+0x830>
ffffffffc02012b4:	9a6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012b8:	00003697          	auipc	a3,0x3
ffffffffc02012bc:	6e868693          	addi	a3,a3,1768 # ffffffffc02049a0 <commands+0x8a8>
ffffffffc02012c0:	00003617          	auipc	a2,0x3
ffffffffc02012c4:	65060613          	addi	a2,a2,1616 # ffffffffc0204910 <commands+0x818>
ffffffffc02012c8:	0d400593          	li	a1,212
ffffffffc02012cc:	00003517          	auipc	a0,0x3
ffffffffc02012d0:	65c50513          	addi	a0,a0,1628 # ffffffffc0204928 <commands+0x830>
ffffffffc02012d4:	986ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012d8:	00003697          	auipc	a3,0x3
ffffffffc02012dc:	6a868693          	addi	a3,a3,1704 # ffffffffc0204980 <commands+0x888>
ffffffffc02012e0:	00003617          	auipc	a2,0x3
ffffffffc02012e4:	63060613          	addi	a2,a2,1584 # ffffffffc0204910 <commands+0x818>
ffffffffc02012e8:	0d300593          	li	a1,211
ffffffffc02012ec:	00003517          	auipc	a0,0x3
ffffffffc02012f0:	63c50513          	addi	a0,a0,1596 # ffffffffc0204928 <commands+0x830>
ffffffffc02012f4:	966ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012f8:	00003697          	auipc	a3,0x3
ffffffffc02012fc:	6a868693          	addi	a3,a3,1704 # ffffffffc02049a0 <commands+0x8a8>
ffffffffc0201300:	00003617          	auipc	a2,0x3
ffffffffc0201304:	61060613          	addi	a2,a2,1552 # ffffffffc0204910 <commands+0x818>
ffffffffc0201308:	0bb00593          	li	a1,187
ffffffffc020130c:	00003517          	auipc	a0,0x3
ffffffffc0201310:	61c50513          	addi	a0,a0,1564 # ffffffffc0204928 <commands+0x830>
ffffffffc0201314:	946ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(count == 0);
ffffffffc0201318:	00004697          	auipc	a3,0x4
ffffffffc020131c:	93068693          	addi	a3,a3,-1744 # ffffffffc0204c48 <commands+0xb50>
ffffffffc0201320:	00003617          	auipc	a2,0x3
ffffffffc0201324:	5f060613          	addi	a2,a2,1520 # ffffffffc0204910 <commands+0x818>
ffffffffc0201328:	12500593          	li	a1,293
ffffffffc020132c:	00003517          	auipc	a0,0x3
ffffffffc0201330:	5fc50513          	addi	a0,a0,1532 # ffffffffc0204928 <commands+0x830>
ffffffffc0201334:	926ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc0201338:	00003697          	auipc	a3,0x3
ffffffffc020133c:	7b068693          	addi	a3,a3,1968 # ffffffffc0204ae8 <commands+0x9f0>
ffffffffc0201340:	00003617          	auipc	a2,0x3
ffffffffc0201344:	5d060613          	addi	a2,a2,1488 # ffffffffc0204910 <commands+0x818>
ffffffffc0201348:	11a00593          	li	a1,282
ffffffffc020134c:	00003517          	auipc	a0,0x3
ffffffffc0201350:	5dc50513          	addi	a0,a0,1500 # ffffffffc0204928 <commands+0x830>
ffffffffc0201354:	906ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201358:	00003697          	auipc	a3,0x3
ffffffffc020135c:	73068693          	addi	a3,a3,1840 # ffffffffc0204a88 <commands+0x990>
ffffffffc0201360:	00003617          	auipc	a2,0x3
ffffffffc0201364:	5b060613          	addi	a2,a2,1456 # ffffffffc0204910 <commands+0x818>
ffffffffc0201368:	11800593          	li	a1,280
ffffffffc020136c:	00003517          	auipc	a0,0x3
ffffffffc0201370:	5bc50513          	addi	a0,a0,1468 # ffffffffc0204928 <commands+0x830>
ffffffffc0201374:	8e6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201378:	00003697          	auipc	a3,0x3
ffffffffc020137c:	6d068693          	addi	a3,a3,1744 # ffffffffc0204a48 <commands+0x950>
ffffffffc0201380:	00003617          	auipc	a2,0x3
ffffffffc0201384:	59060613          	addi	a2,a2,1424 # ffffffffc0204910 <commands+0x818>
ffffffffc0201388:	0c100593          	li	a1,193
ffffffffc020138c:	00003517          	auipc	a0,0x3
ffffffffc0201390:	59c50513          	addi	a0,a0,1436 # ffffffffc0204928 <commands+0x830>
ffffffffc0201394:	8c6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201398:	00004697          	auipc	a3,0x4
ffffffffc020139c:	87068693          	addi	a3,a3,-1936 # ffffffffc0204c08 <commands+0xb10>
ffffffffc02013a0:	00003617          	auipc	a2,0x3
ffffffffc02013a4:	57060613          	addi	a2,a2,1392 # ffffffffc0204910 <commands+0x818>
ffffffffc02013a8:	11200593          	li	a1,274
ffffffffc02013ac:	00003517          	auipc	a0,0x3
ffffffffc02013b0:	57c50513          	addi	a0,a0,1404 # ffffffffc0204928 <commands+0x830>
ffffffffc02013b4:	8a6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02013b8:	00004697          	auipc	a3,0x4
ffffffffc02013bc:	83068693          	addi	a3,a3,-2000 # ffffffffc0204be8 <commands+0xaf0>
ffffffffc02013c0:	00003617          	auipc	a2,0x3
ffffffffc02013c4:	55060613          	addi	a2,a2,1360 # ffffffffc0204910 <commands+0x818>
ffffffffc02013c8:	11000593          	li	a1,272
ffffffffc02013cc:	00003517          	auipc	a0,0x3
ffffffffc02013d0:	55c50513          	addi	a0,a0,1372 # ffffffffc0204928 <commands+0x830>
ffffffffc02013d4:	886ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02013d8:	00003697          	auipc	a3,0x3
ffffffffc02013dc:	7e868693          	addi	a3,a3,2024 # ffffffffc0204bc0 <commands+0xac8>
ffffffffc02013e0:	00003617          	auipc	a2,0x3
ffffffffc02013e4:	53060613          	addi	a2,a2,1328 # ffffffffc0204910 <commands+0x818>
ffffffffc02013e8:	10e00593          	li	a1,270
ffffffffc02013ec:	00003517          	auipc	a0,0x3
ffffffffc02013f0:	53c50513          	addi	a0,a0,1340 # ffffffffc0204928 <commands+0x830>
ffffffffc02013f4:	866ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02013f8:	00003697          	auipc	a3,0x3
ffffffffc02013fc:	7a068693          	addi	a3,a3,1952 # ffffffffc0204b98 <commands+0xaa0>
ffffffffc0201400:	00003617          	auipc	a2,0x3
ffffffffc0201404:	51060613          	addi	a2,a2,1296 # ffffffffc0204910 <commands+0x818>
ffffffffc0201408:	10d00593          	li	a1,269
ffffffffc020140c:	00003517          	auipc	a0,0x3
ffffffffc0201410:	51c50513          	addi	a0,a0,1308 # ffffffffc0204928 <commands+0x830>
ffffffffc0201414:	846ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201418:	00003697          	auipc	a3,0x3
ffffffffc020141c:	77068693          	addi	a3,a3,1904 # ffffffffc0204b88 <commands+0xa90>
ffffffffc0201420:	00003617          	auipc	a2,0x3
ffffffffc0201424:	4f060613          	addi	a2,a2,1264 # ffffffffc0204910 <commands+0x818>
ffffffffc0201428:	10800593          	li	a1,264
ffffffffc020142c:	00003517          	auipc	a0,0x3
ffffffffc0201430:	4fc50513          	addi	a0,a0,1276 # ffffffffc0204928 <commands+0x830>
ffffffffc0201434:	826ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201438:	00003697          	auipc	a3,0x3
ffffffffc020143c:	65068693          	addi	a3,a3,1616 # ffffffffc0204a88 <commands+0x990>
ffffffffc0201440:	00003617          	auipc	a2,0x3
ffffffffc0201444:	4d060613          	addi	a2,a2,1232 # ffffffffc0204910 <commands+0x818>
ffffffffc0201448:	10700593          	li	a1,263
ffffffffc020144c:	00003517          	auipc	a0,0x3
ffffffffc0201450:	4dc50513          	addi	a0,a0,1244 # ffffffffc0204928 <commands+0x830>
ffffffffc0201454:	806ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201458:	00003697          	auipc	a3,0x3
ffffffffc020145c:	71068693          	addi	a3,a3,1808 # ffffffffc0204b68 <commands+0xa70>
ffffffffc0201460:	00003617          	auipc	a2,0x3
ffffffffc0201464:	4b060613          	addi	a2,a2,1200 # ffffffffc0204910 <commands+0x818>
ffffffffc0201468:	10600593          	li	a1,262
ffffffffc020146c:	00003517          	auipc	a0,0x3
ffffffffc0201470:	4bc50513          	addi	a0,a0,1212 # ffffffffc0204928 <commands+0x830>
ffffffffc0201474:	fe7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201478:	00003697          	auipc	a3,0x3
ffffffffc020147c:	6c068693          	addi	a3,a3,1728 # ffffffffc0204b38 <commands+0xa40>
ffffffffc0201480:	00003617          	auipc	a2,0x3
ffffffffc0201484:	49060613          	addi	a2,a2,1168 # ffffffffc0204910 <commands+0x818>
ffffffffc0201488:	10500593          	li	a1,261
ffffffffc020148c:	00003517          	auipc	a0,0x3
ffffffffc0201490:	49c50513          	addi	a0,a0,1180 # ffffffffc0204928 <commands+0x830>
ffffffffc0201494:	fc7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201498:	00003697          	auipc	a3,0x3
ffffffffc020149c:	68868693          	addi	a3,a3,1672 # ffffffffc0204b20 <commands+0xa28>
ffffffffc02014a0:	00003617          	auipc	a2,0x3
ffffffffc02014a4:	47060613          	addi	a2,a2,1136 # ffffffffc0204910 <commands+0x818>
ffffffffc02014a8:	10400593          	li	a1,260
ffffffffc02014ac:	00003517          	auipc	a0,0x3
ffffffffc02014b0:	47c50513          	addi	a0,a0,1148 # ffffffffc0204928 <commands+0x830>
ffffffffc02014b4:	fa7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014b8:	00003697          	auipc	a3,0x3
ffffffffc02014bc:	5d068693          	addi	a3,a3,1488 # ffffffffc0204a88 <commands+0x990>
ffffffffc02014c0:	00003617          	auipc	a2,0x3
ffffffffc02014c4:	45060613          	addi	a2,a2,1104 # ffffffffc0204910 <commands+0x818>
ffffffffc02014c8:	0fe00593          	li	a1,254
ffffffffc02014cc:	00003517          	auipc	a0,0x3
ffffffffc02014d0:	45c50513          	addi	a0,a0,1116 # ffffffffc0204928 <commands+0x830>
ffffffffc02014d4:	f87fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!PageProperty(p0));
ffffffffc02014d8:	00003697          	auipc	a3,0x3
ffffffffc02014dc:	63068693          	addi	a3,a3,1584 # ffffffffc0204b08 <commands+0xa10>
ffffffffc02014e0:	00003617          	auipc	a2,0x3
ffffffffc02014e4:	43060613          	addi	a2,a2,1072 # ffffffffc0204910 <commands+0x818>
ffffffffc02014e8:	0f900593          	li	a1,249
ffffffffc02014ec:	00003517          	auipc	a0,0x3
ffffffffc02014f0:	43c50513          	addi	a0,a0,1084 # ffffffffc0204928 <commands+0x830>
ffffffffc02014f4:	f67fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02014f8:	00003697          	auipc	a3,0x3
ffffffffc02014fc:	73068693          	addi	a3,a3,1840 # ffffffffc0204c28 <commands+0xb30>
ffffffffc0201500:	00003617          	auipc	a2,0x3
ffffffffc0201504:	41060613          	addi	a2,a2,1040 # ffffffffc0204910 <commands+0x818>
ffffffffc0201508:	11700593          	li	a1,279
ffffffffc020150c:	00003517          	auipc	a0,0x3
ffffffffc0201510:	41c50513          	addi	a0,a0,1052 # ffffffffc0204928 <commands+0x830>
ffffffffc0201514:	f47fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == 0);
ffffffffc0201518:	00003697          	auipc	a3,0x3
ffffffffc020151c:	74068693          	addi	a3,a3,1856 # ffffffffc0204c58 <commands+0xb60>
ffffffffc0201520:	00003617          	auipc	a2,0x3
ffffffffc0201524:	3f060613          	addi	a2,a2,1008 # ffffffffc0204910 <commands+0x818>
ffffffffc0201528:	12600593          	li	a1,294
ffffffffc020152c:	00003517          	auipc	a0,0x3
ffffffffc0201530:	3fc50513          	addi	a0,a0,1020 # ffffffffc0204928 <commands+0x830>
ffffffffc0201534:	f27fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == nr_free_pages());
ffffffffc0201538:	00003697          	auipc	a3,0x3
ffffffffc020153c:	40868693          	addi	a3,a3,1032 # ffffffffc0204940 <commands+0x848>
ffffffffc0201540:	00003617          	auipc	a2,0x3
ffffffffc0201544:	3d060613          	addi	a2,a2,976 # ffffffffc0204910 <commands+0x818>
ffffffffc0201548:	0f300593          	li	a1,243
ffffffffc020154c:	00003517          	auipc	a0,0x3
ffffffffc0201550:	3dc50513          	addi	a0,a0,988 # ffffffffc0204928 <commands+0x830>
ffffffffc0201554:	f07fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201558:	00003697          	auipc	a3,0x3
ffffffffc020155c:	42868693          	addi	a3,a3,1064 # ffffffffc0204980 <commands+0x888>
ffffffffc0201560:	00003617          	auipc	a2,0x3
ffffffffc0201564:	3b060613          	addi	a2,a2,944 # ffffffffc0204910 <commands+0x818>
ffffffffc0201568:	0ba00593          	li	a1,186
ffffffffc020156c:	00003517          	auipc	a0,0x3
ffffffffc0201570:	3bc50513          	addi	a0,a0,956 # ffffffffc0204928 <commands+0x830>
ffffffffc0201574:	ee7fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201578 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201578:	1141                	addi	sp,sp,-16
ffffffffc020157a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020157c:	12058f63          	beqz	a1,ffffffffc02016ba <default_free_pages+0x142>
    for (; p != base + n; p ++) {
ffffffffc0201580:	00659693          	slli	a3,a1,0x6
ffffffffc0201584:	96aa                	add	a3,a3,a0
ffffffffc0201586:	87aa                	mv	a5,a0
ffffffffc0201588:	02d50263          	beq	a0,a3,ffffffffc02015ac <default_free_pages+0x34>
ffffffffc020158c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020158e:	8b05                	andi	a4,a4,1
ffffffffc0201590:	10071563          	bnez	a4,ffffffffc020169a <default_free_pages+0x122>
ffffffffc0201594:	6798                	ld	a4,8(a5)
ffffffffc0201596:	8b09                	andi	a4,a4,2
ffffffffc0201598:	10071163          	bnez	a4,ffffffffc020169a <default_free_pages+0x122>
        p->flags = 0;
ffffffffc020159c:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02015a0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015a4:	04078793          	addi	a5,a5,64
ffffffffc02015a8:	fed792e3          	bne	a5,a3,ffffffffc020158c <default_free_pages+0x14>
    base->property = n;
ffffffffc02015ac:	2581                	sext.w	a1,a1
ffffffffc02015ae:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02015b0:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015b4:	4789                	li	a5,2
ffffffffc02015b6:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02015ba:	00008697          	auipc	a3,0x8
ffffffffc02015be:	e7668693          	addi	a3,a3,-394 # ffffffffc0209430 <free_area>
ffffffffc02015c2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02015c4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02015c6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02015ca:	9db9                	addw	a1,a1,a4
ffffffffc02015cc:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02015ce:	08d78f63          	beq	a5,a3,ffffffffc020166c <default_free_pages+0xf4>
            struct Page* page = le2page(le, page_link);
ffffffffc02015d2:	fe878713          	addi	a4,a5,-24
ffffffffc02015d6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02015da:	4581                	li	a1,0
            if (base < page) {
ffffffffc02015dc:	00e56a63          	bltu	a0,a4,ffffffffc02015f0 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02015e0:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02015e2:	04d70a63          	beq	a4,a3,ffffffffc0201636 <default_free_pages+0xbe>
    for (; p != base + n; p ++) {
ffffffffc02015e6:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015e8:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02015ec:	fee57ae3          	bgeu	a0,a4,ffffffffc02015e0 <default_free_pages+0x68>
ffffffffc02015f0:	c199                	beqz	a1,ffffffffc02015f6 <default_free_pages+0x7e>
ffffffffc02015f2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015f6:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02015f8:	e390                	sd	a2,0(a5)
ffffffffc02015fa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015fc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015fe:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201600:	00d70c63          	beq	a4,a3,ffffffffc0201618 <default_free_pages+0xa0>
        if (p + p->property == base) {
ffffffffc0201604:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201608:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc020160c:	02059793          	slli	a5,a1,0x20
ffffffffc0201610:	83e9                	srli	a5,a5,0x1a
ffffffffc0201612:	97b2                	add	a5,a5,a2
ffffffffc0201614:	02f50b63          	beq	a0,a5,ffffffffc020164a <default_free_pages+0xd2>
    return listelm->next;
ffffffffc0201618:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020161a:	00d70b63          	beq	a4,a3,ffffffffc0201630 <default_free_pages+0xb8>
        if (base + base->property == p) {
ffffffffc020161e:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201620:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201624:	02061793          	slli	a5,a2,0x20
ffffffffc0201628:	83e9                	srli	a5,a5,0x1a
ffffffffc020162a:	97aa                	add	a5,a5,a0
ffffffffc020162c:	04f68763          	beq	a3,a5,ffffffffc020167a <default_free_pages+0x102>
}
ffffffffc0201630:	60a2                	ld	ra,8(sp)
ffffffffc0201632:	0141                	addi	sp,sp,16
ffffffffc0201634:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201636:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201638:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020163a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020163c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020163e:	02d70463          	beq	a4,a3,ffffffffc0201666 <default_free_pages+0xee>
    prev->next = next->prev = elm;
ffffffffc0201642:	8832                	mv	a6,a2
ffffffffc0201644:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201646:	87ba                	mv	a5,a4
ffffffffc0201648:	b745                	j	ffffffffc02015e8 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020164a:	491c                	lw	a5,16(a0)
ffffffffc020164c:	9dbd                	addw	a1,a1,a5
ffffffffc020164e:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201652:	57f5                	li	a5,-3
ffffffffc0201654:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201658:	6d0c                	ld	a1,24(a0)
ffffffffc020165a:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc020165c:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020165e:	e59c                	sd	a5,8(a1)
    return listelm->next;
ffffffffc0201660:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201662:	e38c                	sd	a1,0(a5)
ffffffffc0201664:	bf5d                	j	ffffffffc020161a <default_free_pages+0xa2>
ffffffffc0201666:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201668:	873e                	mv	a4,a5
ffffffffc020166a:	bf69                	j	ffffffffc0201604 <default_free_pages+0x8c>
}
ffffffffc020166c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020166e:	e390                	sd	a2,0(a5)
ffffffffc0201670:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201672:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201674:	ed1c                	sd	a5,24(a0)
ffffffffc0201676:	0141                	addi	sp,sp,16
ffffffffc0201678:	8082                	ret
            base->property += p->property;
ffffffffc020167a:	ff872783          	lw	a5,-8(a4)
ffffffffc020167e:	ff070693          	addi	a3,a4,-16
ffffffffc0201682:	9e3d                	addw	a2,a2,a5
ffffffffc0201684:	c910                	sw	a2,16(a0)
ffffffffc0201686:	57f5                	li	a5,-3
ffffffffc0201688:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020168c:	6314                	ld	a3,0(a4)
ffffffffc020168e:	671c                	ld	a5,8(a4)
}
ffffffffc0201690:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201692:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201694:	e394                	sd	a3,0(a5)
ffffffffc0201696:	0141                	addi	sp,sp,16
ffffffffc0201698:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020169a:	00003697          	auipc	a3,0x3
ffffffffc020169e:	5d668693          	addi	a3,a3,1494 # ffffffffc0204c70 <commands+0xb78>
ffffffffc02016a2:	00003617          	auipc	a2,0x3
ffffffffc02016a6:	26e60613          	addi	a2,a2,622 # ffffffffc0204910 <commands+0x818>
ffffffffc02016aa:	08300593          	li	a1,131
ffffffffc02016ae:	00003517          	auipc	a0,0x3
ffffffffc02016b2:	27a50513          	addi	a0,a0,634 # ffffffffc0204928 <commands+0x830>
ffffffffc02016b6:	da5fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc02016ba:	00003697          	auipc	a3,0x3
ffffffffc02016be:	5ae68693          	addi	a3,a3,1454 # ffffffffc0204c68 <commands+0xb70>
ffffffffc02016c2:	00003617          	auipc	a2,0x3
ffffffffc02016c6:	24e60613          	addi	a2,a2,590 # ffffffffc0204910 <commands+0x818>
ffffffffc02016ca:	08000593          	li	a1,128
ffffffffc02016ce:	00003517          	auipc	a0,0x3
ffffffffc02016d2:	25a50513          	addi	a0,a0,602 # ffffffffc0204928 <commands+0x830>
ffffffffc02016d6:	d85fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02016da <default_alloc_pages>:
    assert(n > 0);
ffffffffc02016da:	c941                	beqz	a0,ffffffffc020176a <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc02016dc:	00008597          	auipc	a1,0x8
ffffffffc02016e0:	d5458593          	addi	a1,a1,-684 # ffffffffc0209430 <free_area>
ffffffffc02016e4:	0105a803          	lw	a6,16(a1)
ffffffffc02016e8:	872a                	mv	a4,a0
ffffffffc02016ea:	02081793          	slli	a5,a6,0x20
ffffffffc02016ee:	9381                	srli	a5,a5,0x20
ffffffffc02016f0:	00a7ee63          	bltu	a5,a0,ffffffffc020170c <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02016f4:	87ae                	mv	a5,a1
ffffffffc02016f6:	a801                	j	ffffffffc0201706 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02016f8:	ff87a683          	lw	a3,-8(a5)
ffffffffc02016fc:	02069613          	slli	a2,a3,0x20
ffffffffc0201700:	9201                	srli	a2,a2,0x20
ffffffffc0201702:	00e67763          	bgeu	a2,a4,ffffffffc0201710 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201706:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201708:	feb798e3          	bne	a5,a1,ffffffffc02016f8 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020170c:	4501                	li	a0,0
}
ffffffffc020170e:	8082                	ret
    return listelm->prev;
ffffffffc0201710:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201714:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201718:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020171c:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201720:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201724:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201728:	02c77863          	bgeu	a4,a2,ffffffffc0201758 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020172c:	071a                	slli	a4,a4,0x6
ffffffffc020172e:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201730:	41c686bb          	subw	a3,a3,t3
ffffffffc0201734:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201736:	00870613          	addi	a2,a4,8
ffffffffc020173a:	4689                	li	a3,2
ffffffffc020173c:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201740:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201744:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201748:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020174c:	e290                	sd	a2,0(a3)
ffffffffc020174e:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201752:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201754:	01173c23          	sd	a7,24(a4)
ffffffffc0201758:	41c8083b          	subw	a6,a6,t3
ffffffffc020175c:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201760:	5775                	li	a4,-3
ffffffffc0201762:	17c1                	addi	a5,a5,-16
ffffffffc0201764:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201768:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020176a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020176c:	00003697          	auipc	a3,0x3
ffffffffc0201770:	4fc68693          	addi	a3,a3,1276 # ffffffffc0204c68 <commands+0xb70>
ffffffffc0201774:	00003617          	auipc	a2,0x3
ffffffffc0201778:	19c60613          	addi	a2,a2,412 # ffffffffc0204910 <commands+0x818>
ffffffffc020177c:	06200593          	li	a1,98
ffffffffc0201780:	00003517          	auipc	a0,0x3
ffffffffc0201784:	1a850513          	addi	a0,a0,424 # ffffffffc0204928 <commands+0x830>
default_alloc_pages(size_t n) {
ffffffffc0201788:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020178a:	cd1fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020178e <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020178e:	1141                	addi	sp,sp,-16
ffffffffc0201790:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201792:	c5f1                	beqz	a1,ffffffffc020185e <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0201794:	00659693          	slli	a3,a1,0x6
ffffffffc0201798:	96aa                	add	a3,a3,a0
ffffffffc020179a:	87aa                	mv	a5,a0
ffffffffc020179c:	00d50f63          	beq	a0,a3,ffffffffc02017ba <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02017a0:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02017a2:	8b05                	andi	a4,a4,1
ffffffffc02017a4:	cf49                	beqz	a4,ffffffffc020183e <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02017a6:	0007a823          	sw	zero,16(a5)
ffffffffc02017aa:	0007b423          	sd	zero,8(a5)
ffffffffc02017ae:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02017b2:	04078793          	addi	a5,a5,64
ffffffffc02017b6:	fed795e3          	bne	a5,a3,ffffffffc02017a0 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02017ba:	2581                	sext.w	a1,a1
ffffffffc02017bc:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017be:	4789                	li	a5,2
ffffffffc02017c0:	00850713          	addi	a4,a0,8
ffffffffc02017c4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02017c8:	00008697          	auipc	a3,0x8
ffffffffc02017cc:	c6868693          	addi	a3,a3,-920 # ffffffffc0209430 <free_area>
ffffffffc02017d0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017d2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017d4:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02017d8:	9db9                	addw	a1,a1,a4
ffffffffc02017da:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02017dc:	04d78a63          	beq	a5,a3,ffffffffc0201830 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc02017e0:	fe878713          	addi	a4,a5,-24
ffffffffc02017e4:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02017e8:	4581                	li	a1,0
            if (base < page) {
ffffffffc02017ea:	00e56a63          	bltu	a0,a4,ffffffffc02017fe <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02017ee:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02017f0:	02d70263          	beq	a4,a3,ffffffffc0201814 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc02017f4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02017f6:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02017fa:	fee57ae3          	bgeu	a0,a4,ffffffffc02017ee <default_init_memmap+0x60>
ffffffffc02017fe:	c199                	beqz	a1,ffffffffc0201804 <default_init_memmap+0x76>
ffffffffc0201800:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201804:	6398                	ld	a4,0(a5)
}
ffffffffc0201806:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201808:	e390                	sd	a2,0(a5)
ffffffffc020180a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020180c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020180e:	ed18                	sd	a4,24(a0)
ffffffffc0201810:	0141                	addi	sp,sp,16
ffffffffc0201812:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201814:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201816:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201818:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020181a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020181c:	00d70663          	beq	a4,a3,ffffffffc0201828 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201820:	8832                	mv	a6,a2
ffffffffc0201822:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201824:	87ba                	mv	a5,a4
ffffffffc0201826:	bfc1                	j	ffffffffc02017f6 <default_init_memmap+0x68>
}
ffffffffc0201828:	60a2                	ld	ra,8(sp)
ffffffffc020182a:	e290                	sd	a2,0(a3)
ffffffffc020182c:	0141                	addi	sp,sp,16
ffffffffc020182e:	8082                	ret
ffffffffc0201830:	60a2                	ld	ra,8(sp)
ffffffffc0201832:	e390                	sd	a2,0(a5)
ffffffffc0201834:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201836:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201838:	ed1c                	sd	a5,24(a0)
ffffffffc020183a:	0141                	addi	sp,sp,16
ffffffffc020183c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020183e:	00003697          	auipc	a3,0x3
ffffffffc0201842:	45a68693          	addi	a3,a3,1114 # ffffffffc0204c98 <commands+0xba0>
ffffffffc0201846:	00003617          	auipc	a2,0x3
ffffffffc020184a:	0ca60613          	addi	a2,a2,202 # ffffffffc0204910 <commands+0x818>
ffffffffc020184e:	04900593          	li	a1,73
ffffffffc0201852:	00003517          	auipc	a0,0x3
ffffffffc0201856:	0d650513          	addi	a0,a0,214 # ffffffffc0204928 <commands+0x830>
ffffffffc020185a:	c01fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc020185e:	00003697          	auipc	a3,0x3
ffffffffc0201862:	40a68693          	addi	a3,a3,1034 # ffffffffc0204c68 <commands+0xb70>
ffffffffc0201866:	00003617          	auipc	a2,0x3
ffffffffc020186a:	0aa60613          	addi	a2,a2,170 # ffffffffc0204910 <commands+0x818>
ffffffffc020186e:	04600593          	li	a1,70
ffffffffc0201872:	00003517          	auipc	a0,0x3
ffffffffc0201876:	0b650513          	addi	a0,a0,182 # ffffffffc0204928 <commands+0x830>
ffffffffc020187a:	be1fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020187e <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc020187e:	c94d                	beqz	a0,ffffffffc0201930 <slob_free+0xb2>
{
ffffffffc0201880:	1141                	addi	sp,sp,-16
ffffffffc0201882:	e022                	sd	s0,0(sp)
ffffffffc0201884:	e406                	sd	ra,8(sp)
ffffffffc0201886:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201888:	e9c1                	bnez	a1,ffffffffc0201918 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020188a:	100027f3          	csrr	a5,sstatus
ffffffffc020188e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201890:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201892:	ebd9                	bnez	a5,ffffffffc0201928 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201894:	00007617          	auipc	a2,0x7
ffffffffc0201898:	78c60613          	addi	a2,a2,1932 # ffffffffc0209020 <slobfree>
ffffffffc020189c:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020189e:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018a0:	679c                	ld	a5,8(a5)
ffffffffc02018a2:	02877a63          	bgeu	a4,s0,ffffffffc02018d6 <slob_free+0x58>
ffffffffc02018a6:	00f46463          	bltu	s0,a5,ffffffffc02018ae <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018aa:	fef76ae3          	bltu	a4,a5,ffffffffc020189e <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc02018ae:	400c                	lw	a1,0(s0)
ffffffffc02018b0:	00459693          	slli	a3,a1,0x4
ffffffffc02018b4:	96a2                	add	a3,a3,s0
ffffffffc02018b6:	02d78a63          	beq	a5,a3,ffffffffc02018ea <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02018ba:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc02018bc:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018be:	00469793          	slli	a5,a3,0x4
ffffffffc02018c2:	97ba                	add	a5,a5,a4
ffffffffc02018c4:	02f40e63          	beq	s0,a5,ffffffffc0201900 <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc02018c8:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc02018ca:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc02018cc:	e129                	bnez	a0,ffffffffc020190e <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc02018ce:	60a2                	ld	ra,8(sp)
ffffffffc02018d0:	6402                	ld	s0,0(sp)
ffffffffc02018d2:	0141                	addi	sp,sp,16
ffffffffc02018d4:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018d6:	fcf764e3          	bltu	a4,a5,ffffffffc020189e <slob_free+0x20>
ffffffffc02018da:	fcf472e3          	bgeu	s0,a5,ffffffffc020189e <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc02018de:	400c                	lw	a1,0(s0)
ffffffffc02018e0:	00459693          	slli	a3,a1,0x4
ffffffffc02018e4:	96a2                	add	a3,a3,s0
ffffffffc02018e6:	fcd79ae3          	bne	a5,a3,ffffffffc02018ba <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02018ea:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02018ec:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02018ee:	9db5                	addw	a1,a1,a3
ffffffffc02018f0:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02018f2:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02018f4:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018f6:	00469793          	slli	a5,a3,0x4
ffffffffc02018fa:	97ba                	add	a5,a5,a4
ffffffffc02018fc:	fcf416e3          	bne	s0,a5,ffffffffc02018c8 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201900:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201902:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201904:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201906:	9ebd                	addw	a3,a3,a5
ffffffffc0201908:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc020190a:	e70c                	sd	a1,8(a4)
ffffffffc020190c:	d169                	beqz	a0,ffffffffc02018ce <slob_free+0x50>
}
ffffffffc020190e:	6402                	ld	s0,0(sp)
ffffffffc0201910:	60a2                	ld	ra,8(sp)
ffffffffc0201912:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201914:	816ff06f          	j	ffffffffc020092a <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201918:	25bd                	addiw	a1,a1,15
ffffffffc020191a:	8191                	srli	a1,a1,0x4
ffffffffc020191c:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020191e:	100027f3          	csrr	a5,sstatus
ffffffffc0201922:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201924:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201926:	d7bd                	beqz	a5,ffffffffc0201894 <slob_free+0x16>
        intr_disable();
ffffffffc0201928:	808ff0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc020192c:	4505                	li	a0,1
ffffffffc020192e:	b79d                	j	ffffffffc0201894 <slob_free+0x16>
ffffffffc0201930:	8082                	ret

ffffffffc0201932 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201932:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201934:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201936:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020193a:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc020193c:	34e000ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
	if (!page)
ffffffffc0201940:	c91d                	beqz	a0,ffffffffc0201976 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201942:	0000c697          	auipc	a3,0xc
ffffffffc0201946:	b766b683          	ld	a3,-1162(a3) # ffffffffc020d4b8 <pages>
ffffffffc020194a:	8d15                	sub	a0,a0,a3
ffffffffc020194c:	8519                	srai	a0,a0,0x6
ffffffffc020194e:	00004697          	auipc	a3,0x4
ffffffffc0201952:	08a6b683          	ld	a3,138(a3) # ffffffffc02059d8 <nbase>
ffffffffc0201956:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201958:	00c51793          	slli	a5,a0,0xc
ffffffffc020195c:	83b1                	srli	a5,a5,0xc
ffffffffc020195e:	0000c717          	auipc	a4,0xc
ffffffffc0201962:	b5273703          	ld	a4,-1198(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201966:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201968:	00e7fa63          	bgeu	a5,a4,ffffffffc020197c <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc020196c:	0000c697          	auipc	a3,0xc
ffffffffc0201970:	b5c6b683          	ld	a3,-1188(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201974:	9536                	add	a0,a0,a3
}
ffffffffc0201976:	60a2                	ld	ra,8(sp)
ffffffffc0201978:	0141                	addi	sp,sp,16
ffffffffc020197a:	8082                	ret
ffffffffc020197c:	86aa                	mv	a3,a0
ffffffffc020197e:	00003617          	auipc	a2,0x3
ffffffffc0201982:	37a60613          	addi	a2,a2,890 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0201986:	07100593          	li	a1,113
ffffffffc020198a:	00003517          	auipc	a0,0x3
ffffffffc020198e:	39650513          	addi	a0,a0,918 # ffffffffc0204d20 <default_pmm_manager+0x60>
ffffffffc0201992:	ac9fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201996 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201996:	1101                	addi	sp,sp,-32
ffffffffc0201998:	ec06                	sd	ra,24(sp)
ffffffffc020199a:	e822                	sd	s0,16(sp)
ffffffffc020199c:	e426                	sd	s1,8(sp)
ffffffffc020199e:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02019a0:	01050713          	addi	a4,a0,16
ffffffffc02019a4:	6785                	lui	a5,0x1
ffffffffc02019a6:	0cf77363          	bgeu	a4,a5,ffffffffc0201a6c <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019aa:	00f50493          	addi	s1,a0,15
ffffffffc02019ae:	8091                	srli	s1,s1,0x4
ffffffffc02019b0:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019b2:	10002673          	csrr	a2,sstatus
ffffffffc02019b6:	8a09                	andi	a2,a2,2
ffffffffc02019b8:	e25d                	bnez	a2,ffffffffc0201a5e <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc02019ba:	00007917          	auipc	s2,0x7
ffffffffc02019be:	66690913          	addi	s2,s2,1638 # ffffffffc0209020 <slobfree>
ffffffffc02019c2:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019c6:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc02019c8:	4398                	lw	a4,0(a5)
ffffffffc02019ca:	08975e63          	bge	a4,s1,ffffffffc0201a66 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc02019ce:	00d78b63          	beq	a5,a3,ffffffffc02019e4 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019d2:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02019d4:	4018                	lw	a4,0(s0)
ffffffffc02019d6:	02975a63          	bge	a4,s1,ffffffffc0201a0a <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc02019da:	00093683          	ld	a3,0(s2)
ffffffffc02019de:	87a2                	mv	a5,s0
ffffffffc02019e0:	fed799e3          	bne	a5,a3,ffffffffc02019d2 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc02019e4:	ee31                	bnez	a2,ffffffffc0201a40 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019e6:	4501                	li	a0,0
ffffffffc02019e8:	f4bff0ef          	jal	ra,ffffffffc0201932 <__slob_get_free_pages.constprop.0>
ffffffffc02019ec:	842a                	mv	s0,a0
			if (!cur)
ffffffffc02019ee:	cd05                	beqz	a0,ffffffffc0201a26 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc02019f0:	6585                	lui	a1,0x1
ffffffffc02019f2:	e8dff0ef          	jal	ra,ffffffffc020187e <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019f6:	10002673          	csrr	a2,sstatus
ffffffffc02019fa:	8a09                	andi	a2,a2,2
ffffffffc02019fc:	ee05                	bnez	a2,ffffffffc0201a34 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc02019fe:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201a02:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201a04:	4018                	lw	a4,0(s0)
ffffffffc0201a06:	fc974ae3          	blt	a4,s1,ffffffffc02019da <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201a0a:	04e48763          	beq	s1,a4,ffffffffc0201a58 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a0e:	00449693          	slli	a3,s1,0x4
ffffffffc0201a12:	96a2                	add	a3,a3,s0
ffffffffc0201a14:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a16:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a18:	9f05                	subw	a4,a4,s1
ffffffffc0201a1a:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a1c:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a1e:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201a20:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201a24:	e20d                	bnez	a2,ffffffffc0201a46 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201a26:	60e2                	ld	ra,24(sp)
ffffffffc0201a28:	8522                	mv	a0,s0
ffffffffc0201a2a:	6442                	ld	s0,16(sp)
ffffffffc0201a2c:	64a2                	ld	s1,8(sp)
ffffffffc0201a2e:	6902                	ld	s2,0(sp)
ffffffffc0201a30:	6105                	addi	sp,sp,32
ffffffffc0201a32:	8082                	ret
        intr_disable();
ffffffffc0201a34:	efdfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
			cur = slobfree;
ffffffffc0201a38:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201a3c:	4605                	li	a2,1
ffffffffc0201a3e:	b7d1                	j	ffffffffc0201a02 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201a40:	eebfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201a44:	b74d                	j	ffffffffc02019e6 <slob_alloc.constprop.0+0x50>
ffffffffc0201a46:	ee5fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0201a4a:	60e2                	ld	ra,24(sp)
ffffffffc0201a4c:	8522                	mv	a0,s0
ffffffffc0201a4e:	6442                	ld	s0,16(sp)
ffffffffc0201a50:	64a2                	ld	s1,8(sp)
ffffffffc0201a52:	6902                	ld	s2,0(sp)
ffffffffc0201a54:	6105                	addi	sp,sp,32
ffffffffc0201a56:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a58:	6418                	ld	a4,8(s0)
ffffffffc0201a5a:	e798                	sd	a4,8(a5)
ffffffffc0201a5c:	b7d1                	j	ffffffffc0201a20 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a5e:	ed3fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201a62:	4605                	li	a2,1
ffffffffc0201a64:	bf99                	j	ffffffffc02019ba <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201a66:	843e                	mv	s0,a5
ffffffffc0201a68:	87b6                	mv	a5,a3
ffffffffc0201a6a:	b745                	j	ffffffffc0201a0a <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a6c:	00003697          	auipc	a3,0x3
ffffffffc0201a70:	2c468693          	addi	a3,a3,708 # ffffffffc0204d30 <default_pmm_manager+0x70>
ffffffffc0201a74:	00003617          	auipc	a2,0x3
ffffffffc0201a78:	e9c60613          	addi	a2,a2,-356 # ffffffffc0204910 <commands+0x818>
ffffffffc0201a7c:	06300593          	li	a1,99
ffffffffc0201a80:	00003517          	auipc	a0,0x3
ffffffffc0201a84:	2d050513          	addi	a0,a0,720 # ffffffffc0204d50 <default_pmm_manager+0x90>
ffffffffc0201a88:	9d3fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201a8c <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a8c:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a8e:	00003517          	auipc	a0,0x3
ffffffffc0201a92:	2da50513          	addi	a0,a0,730 # ffffffffc0204d68 <default_pmm_manager+0xa8>
{
ffffffffc0201a96:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a98:	efcfe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a9c:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a9e:	00003517          	auipc	a0,0x3
ffffffffc0201aa2:	2e250513          	addi	a0,a0,738 # ffffffffc0204d80 <default_pmm_manager+0xc0>
}
ffffffffc0201aa6:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201aa8:	eecfe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201aac <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201aac:	1101                	addi	sp,sp,-32
ffffffffc0201aae:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ab0:	6905                	lui	s2,0x1
{
ffffffffc0201ab2:	e822                	sd	s0,16(sp)
ffffffffc0201ab4:	ec06                	sd	ra,24(sp)
ffffffffc0201ab6:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201ab8:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201abc:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201abe:	04a7f963          	bgeu	a5,a0,ffffffffc0201b10 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ac2:	4561                	li	a0,24
ffffffffc0201ac4:	ed3ff0ef          	jal	ra,ffffffffc0201996 <slob_alloc.constprop.0>
ffffffffc0201ac8:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201aca:	c929                	beqz	a0,ffffffffc0201b1c <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201acc:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201ad0:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201ad2:	00f95763          	bge	s2,a5,ffffffffc0201ae0 <kmalloc+0x34>
ffffffffc0201ad6:	6705                	lui	a4,0x1
ffffffffc0201ad8:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201ada:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201adc:	fef74ee3          	blt	a4,a5,ffffffffc0201ad8 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201ae0:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ae2:	e51ff0ef          	jal	ra,ffffffffc0201932 <__slob_get_free_pages.constprop.0>
ffffffffc0201ae6:	e488                	sd	a0,8(s1)
ffffffffc0201ae8:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201aea:	c525                	beqz	a0,ffffffffc0201b52 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201aec:	100027f3          	csrr	a5,sstatus
ffffffffc0201af0:	8b89                	andi	a5,a5,2
ffffffffc0201af2:	ef8d                	bnez	a5,ffffffffc0201b2c <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201af4:	0000c797          	auipc	a5,0xc
ffffffffc0201af8:	9a478793          	addi	a5,a5,-1628 # ffffffffc020d498 <bigblocks>
ffffffffc0201afc:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201afe:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b00:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201b02:	60e2                	ld	ra,24(sp)
ffffffffc0201b04:	8522                	mv	a0,s0
ffffffffc0201b06:	6442                	ld	s0,16(sp)
ffffffffc0201b08:	64a2                	ld	s1,8(sp)
ffffffffc0201b0a:	6902                	ld	s2,0(sp)
ffffffffc0201b0c:	6105                	addi	sp,sp,32
ffffffffc0201b0e:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b10:	0541                	addi	a0,a0,16
ffffffffc0201b12:	e85ff0ef          	jal	ra,ffffffffc0201996 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b16:	01050413          	addi	s0,a0,16
ffffffffc0201b1a:	f565                	bnez	a0,ffffffffc0201b02 <kmalloc+0x56>
ffffffffc0201b1c:	4401                	li	s0,0
}
ffffffffc0201b1e:	60e2                	ld	ra,24(sp)
ffffffffc0201b20:	8522                	mv	a0,s0
ffffffffc0201b22:	6442                	ld	s0,16(sp)
ffffffffc0201b24:	64a2                	ld	s1,8(sp)
ffffffffc0201b26:	6902                	ld	s2,0(sp)
ffffffffc0201b28:	6105                	addi	sp,sp,32
ffffffffc0201b2a:	8082                	ret
        intr_disable();
ffffffffc0201b2c:	e05fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b30:	0000c797          	auipc	a5,0xc
ffffffffc0201b34:	96878793          	addi	a5,a5,-1688 # ffffffffc020d498 <bigblocks>
ffffffffc0201b38:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b3a:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b3c:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201b3e:	dedfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
		return bb->pages;
ffffffffc0201b42:	6480                	ld	s0,8(s1)
}
ffffffffc0201b44:	60e2                	ld	ra,24(sp)
ffffffffc0201b46:	64a2                	ld	s1,8(sp)
ffffffffc0201b48:	8522                	mv	a0,s0
ffffffffc0201b4a:	6442                	ld	s0,16(sp)
ffffffffc0201b4c:	6902                	ld	s2,0(sp)
ffffffffc0201b4e:	6105                	addi	sp,sp,32
ffffffffc0201b50:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b52:	45e1                	li	a1,24
ffffffffc0201b54:	8526                	mv	a0,s1
ffffffffc0201b56:	d29ff0ef          	jal	ra,ffffffffc020187e <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201b5a:	b765                	j	ffffffffc0201b02 <kmalloc+0x56>

ffffffffc0201b5c <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b5c:	c169                	beqz	a0,ffffffffc0201c1e <kfree+0xc2>
{
ffffffffc0201b5e:	1101                	addi	sp,sp,-32
ffffffffc0201b60:	e822                	sd	s0,16(sp)
ffffffffc0201b62:	ec06                	sd	ra,24(sp)
ffffffffc0201b64:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b66:	03451793          	slli	a5,a0,0x34
ffffffffc0201b6a:	842a                	mv	s0,a0
ffffffffc0201b6c:	e3d9                	bnez	a5,ffffffffc0201bf2 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b6e:	100027f3          	csrr	a5,sstatus
ffffffffc0201b72:	8b89                	andi	a5,a5,2
ffffffffc0201b74:	e7d9                	bnez	a5,ffffffffc0201c02 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b76:	0000c797          	auipc	a5,0xc
ffffffffc0201b7a:	9227b783          	ld	a5,-1758(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b7e:	4601                	li	a2,0
ffffffffc0201b80:	cbad                	beqz	a5,ffffffffc0201bf2 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b82:	0000c697          	auipc	a3,0xc
ffffffffc0201b86:	91668693          	addi	a3,a3,-1770 # ffffffffc020d498 <bigblocks>
ffffffffc0201b8a:	a021                	j	ffffffffc0201b92 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b8c:	01048693          	addi	a3,s1,16
ffffffffc0201b90:	c3a5                	beqz	a5,ffffffffc0201bf0 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201b92:	6798                	ld	a4,8(a5)
ffffffffc0201b94:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201b96:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b98:	fe871ae3          	bne	a4,s0,ffffffffc0201b8c <kfree+0x30>
				*last = bb->next;
ffffffffc0201b9c:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201b9e:	ee2d                	bnez	a2,ffffffffc0201c18 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201ba0:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201ba4:	4098                	lw	a4,0(s1)
ffffffffc0201ba6:	08f46963          	bltu	s0,a5,ffffffffc0201c38 <kfree+0xdc>
ffffffffc0201baa:	0000c697          	auipc	a3,0xc
ffffffffc0201bae:	91e6b683          	ld	a3,-1762(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201bb2:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201bb4:	8031                	srli	s0,s0,0xc
ffffffffc0201bb6:	0000c797          	auipc	a5,0xc
ffffffffc0201bba:	8fa7b783          	ld	a5,-1798(a5) # ffffffffc020d4b0 <npage>
ffffffffc0201bbe:	06f47163          	bgeu	s0,a5,ffffffffc0201c20 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201bc2:	00004517          	auipc	a0,0x4
ffffffffc0201bc6:	e1653503          	ld	a0,-490(a0) # ffffffffc02059d8 <nbase>
ffffffffc0201bca:	8c09                	sub	s0,s0,a0
ffffffffc0201bcc:	041a                	slli	s0,s0,0x6
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201bce:	0000c517          	auipc	a0,0xc
ffffffffc0201bd2:	8ea53503          	ld	a0,-1814(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201bd6:	4585                	li	a1,1
ffffffffc0201bd8:	9522                	add	a0,a0,s0
ffffffffc0201bda:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201bde:	0ea000ef          	jal	ra,ffffffffc0201cc8 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201be2:	6442                	ld	s0,16(sp)
ffffffffc0201be4:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201be6:	8526                	mv	a0,s1
}
ffffffffc0201be8:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bea:	45e1                	li	a1,24
}
ffffffffc0201bec:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bee:	b941                	j	ffffffffc020187e <slob_free>
ffffffffc0201bf0:	e20d                	bnez	a2,ffffffffc0201c12 <kfree+0xb6>
ffffffffc0201bf2:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201bf6:	6442                	ld	s0,16(sp)
ffffffffc0201bf8:	60e2                	ld	ra,24(sp)
ffffffffc0201bfa:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bfc:	4581                	li	a1,0
}
ffffffffc0201bfe:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c00:	b9bd                	j	ffffffffc020187e <slob_free>
        intr_disable();
ffffffffc0201c02:	d2ffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201c06:	0000c797          	auipc	a5,0xc
ffffffffc0201c0a:	8927b783          	ld	a5,-1902(a5) # ffffffffc020d498 <bigblocks>
        return 1;
ffffffffc0201c0e:	4605                	li	a2,1
ffffffffc0201c10:	fbad                	bnez	a5,ffffffffc0201b82 <kfree+0x26>
        intr_enable();
ffffffffc0201c12:	d19fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c16:	bff1                	j	ffffffffc0201bf2 <kfree+0x96>
ffffffffc0201c18:	d13fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201c1c:	b751                	j	ffffffffc0201ba0 <kfree+0x44>
ffffffffc0201c1e:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c20:	00003617          	auipc	a2,0x3
ffffffffc0201c24:	1a860613          	addi	a2,a2,424 # ffffffffc0204dc8 <default_pmm_manager+0x108>
ffffffffc0201c28:	06900593          	li	a1,105
ffffffffc0201c2c:	00003517          	auipc	a0,0x3
ffffffffc0201c30:	0f450513          	addi	a0,a0,244 # ffffffffc0204d20 <default_pmm_manager+0x60>
ffffffffc0201c34:	827fe0ef          	jal	ra,ffffffffc020045a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c38:	86a2                	mv	a3,s0
ffffffffc0201c3a:	00003617          	auipc	a2,0x3
ffffffffc0201c3e:	16660613          	addi	a2,a2,358 # ffffffffc0204da0 <default_pmm_manager+0xe0>
ffffffffc0201c42:	07700593          	li	a1,119
ffffffffc0201c46:	00003517          	auipc	a0,0x3
ffffffffc0201c4a:	0da50513          	addi	a0,a0,218 # ffffffffc0204d20 <default_pmm_manager+0x60>
ffffffffc0201c4e:	80dfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c52 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c52:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c54:	00003617          	auipc	a2,0x3
ffffffffc0201c58:	17460613          	addi	a2,a2,372 # ffffffffc0204dc8 <default_pmm_manager+0x108>
ffffffffc0201c5c:	06900593          	li	a1,105
ffffffffc0201c60:	00003517          	auipc	a0,0x3
ffffffffc0201c64:	0c050513          	addi	a0,a0,192 # ffffffffc0204d20 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201c68:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c6a:	ff0fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c6e <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201c6e:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201c70:	00003617          	auipc	a2,0x3
ffffffffc0201c74:	17860613          	addi	a2,a2,376 # ffffffffc0204de8 <default_pmm_manager+0x128>
ffffffffc0201c78:	07f00593          	li	a1,127
ffffffffc0201c7c:	00003517          	auipc	a0,0x3
ffffffffc0201c80:	0a450513          	addi	a0,a0,164 # ffffffffc0204d20 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201c84:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201c86:	fd4fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c8a <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c8a:	100027f3          	csrr	a5,sstatus
ffffffffc0201c8e:	8b89                	andi	a5,a5,2
ffffffffc0201c90:	e799                	bnez	a5,ffffffffc0201c9e <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c92:	0000c797          	auipc	a5,0xc
ffffffffc0201c96:	82e7b783          	ld	a5,-2002(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201c9a:	6f9c                	ld	a5,24(a5)
ffffffffc0201c9c:	8782                	jr	a5
{
ffffffffc0201c9e:	1141                	addi	sp,sp,-16
ffffffffc0201ca0:	e406                	sd	ra,8(sp)
ffffffffc0201ca2:	e022                	sd	s0,0(sp)
ffffffffc0201ca4:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201ca6:	c8bfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201caa:	0000c797          	auipc	a5,0xc
ffffffffc0201cae:	8167b783          	ld	a5,-2026(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cb2:	6f9c                	ld	a5,24(a5)
ffffffffc0201cb4:	8522                	mv	a0,s0
ffffffffc0201cb6:	9782                	jalr	a5
ffffffffc0201cb8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201cba:	c71fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201cbe:	60a2                	ld	ra,8(sp)
ffffffffc0201cc0:	8522                	mv	a0,s0
ffffffffc0201cc2:	6402                	ld	s0,0(sp)
ffffffffc0201cc4:	0141                	addi	sp,sp,16
ffffffffc0201cc6:	8082                	ret

ffffffffc0201cc8 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cc8:	100027f3          	csrr	a5,sstatus
ffffffffc0201ccc:	8b89                	andi	a5,a5,2
ffffffffc0201cce:	e799                	bnez	a5,ffffffffc0201cdc <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201cd0:	0000b797          	auipc	a5,0xb
ffffffffc0201cd4:	7f07b783          	ld	a5,2032(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cd8:	739c                	ld	a5,32(a5)
ffffffffc0201cda:	8782                	jr	a5
{
ffffffffc0201cdc:	1101                	addi	sp,sp,-32
ffffffffc0201cde:	ec06                	sd	ra,24(sp)
ffffffffc0201ce0:	e822                	sd	s0,16(sp)
ffffffffc0201ce2:	e426                	sd	s1,8(sp)
ffffffffc0201ce4:	842a                	mv	s0,a0
ffffffffc0201ce6:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201ce8:	c49fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201cec:	0000b797          	auipc	a5,0xb
ffffffffc0201cf0:	7d47b783          	ld	a5,2004(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cf4:	739c                	ld	a5,32(a5)
ffffffffc0201cf6:	85a6                	mv	a1,s1
ffffffffc0201cf8:	8522                	mv	a0,s0
ffffffffc0201cfa:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201cfc:	6442                	ld	s0,16(sp)
ffffffffc0201cfe:	60e2                	ld	ra,24(sp)
ffffffffc0201d00:	64a2                	ld	s1,8(sp)
ffffffffc0201d02:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201d04:	c27fe06f          	j	ffffffffc020092a <intr_enable>

ffffffffc0201d08 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d08:	100027f3          	csrr	a5,sstatus
ffffffffc0201d0c:	8b89                	andi	a5,a5,2
ffffffffc0201d0e:	e799                	bnez	a5,ffffffffc0201d1c <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d10:	0000b797          	auipc	a5,0xb
ffffffffc0201d14:	7b07b783          	ld	a5,1968(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d18:	779c                	ld	a5,40(a5)
ffffffffc0201d1a:	8782                	jr	a5
{
ffffffffc0201d1c:	1141                	addi	sp,sp,-16
ffffffffc0201d1e:	e406                	sd	ra,8(sp)
ffffffffc0201d20:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201d22:	c0ffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201d26:	0000b797          	auipc	a5,0xb
ffffffffc0201d2a:	79a7b783          	ld	a5,1946(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d2e:	779c                	ld	a5,40(a5)
ffffffffc0201d30:	9782                	jalr	a5
ffffffffc0201d32:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d34:	bf7fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201d38:	60a2                	ld	ra,8(sp)
ffffffffc0201d3a:	8522                	mv	a0,s0
ffffffffc0201d3c:	6402                	ld	s0,0(sp)
ffffffffc0201d3e:	0141                	addi	sp,sp,16
ffffffffc0201d40:	8082                	ret

ffffffffc0201d42 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d42:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d46:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201d4a:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d4c:	078e                	slli	a5,a5,0x3
{
ffffffffc0201d4e:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d50:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201d54:	6094                	ld	a3,0(s1)
{
ffffffffc0201d56:	f04a                	sd	s2,32(sp)
ffffffffc0201d58:	ec4e                	sd	s3,24(sp)
ffffffffc0201d5a:	e852                	sd	s4,16(sp)
ffffffffc0201d5c:	fc06                	sd	ra,56(sp)
ffffffffc0201d5e:	f822                	sd	s0,48(sp)
ffffffffc0201d60:	e456                	sd	s5,8(sp)
ffffffffc0201d62:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d64:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d68:	892e                	mv	s2,a1
ffffffffc0201d6a:	8a32                	mv	s4,a2
ffffffffc0201d6c:	0000b997          	auipc	s3,0xb
ffffffffc0201d70:	74498993          	addi	s3,s3,1860 # ffffffffc020d4b0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d74:	efbd                	bnez	a5,ffffffffc0201df2 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d76:	14060c63          	beqz	a2,ffffffffc0201ece <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d7a:	100027f3          	csrr	a5,sstatus
ffffffffc0201d7e:	8b89                	andi	a5,a5,2
ffffffffc0201d80:	14079963          	bnez	a5,ffffffffc0201ed2 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d84:	0000b797          	auipc	a5,0xb
ffffffffc0201d88:	73c7b783          	ld	a5,1852(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d8c:	6f9c                	ld	a5,24(a5)
ffffffffc0201d8e:	4505                	li	a0,1
ffffffffc0201d90:	9782                	jalr	a5
ffffffffc0201d92:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d94:	12040d63          	beqz	s0,ffffffffc0201ece <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201d98:	0000bb17          	auipc	s6,0xb
ffffffffc0201d9c:	720b0b13          	addi	s6,s6,1824 # ffffffffc020d4b8 <pages>
ffffffffc0201da0:	000b3503          	ld	a0,0(s6)
ffffffffc0201da4:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201da8:	0000b997          	auipc	s3,0xb
ffffffffc0201dac:	70898993          	addi	s3,s3,1800 # ffffffffc020d4b0 <npage>
ffffffffc0201db0:	40a40533          	sub	a0,s0,a0
ffffffffc0201db4:	8519                	srai	a0,a0,0x6
ffffffffc0201db6:	9556                	add	a0,a0,s5
ffffffffc0201db8:	0009b703          	ld	a4,0(s3)
ffffffffc0201dbc:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201dc0:	4685                	li	a3,1
ffffffffc0201dc2:	c014                	sw	a3,0(s0)
ffffffffc0201dc4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201dc6:	0532                	slli	a0,a0,0xc
ffffffffc0201dc8:	16e7f763          	bgeu	a5,a4,ffffffffc0201f36 <get_pte+0x1f4>
ffffffffc0201dcc:	0000b797          	auipc	a5,0xb
ffffffffc0201dd0:	6fc7b783          	ld	a5,1788(a5) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201dd4:	6605                	lui	a2,0x1
ffffffffc0201dd6:	4581                	li	a1,0
ffffffffc0201dd8:	953e                	add	a0,a0,a5
ffffffffc0201dda:	064020ef          	jal	ra,ffffffffc0203e3e <memset>
    return page - pages + nbase;
ffffffffc0201dde:	000b3683          	ld	a3,0(s6)
ffffffffc0201de2:	40d406b3          	sub	a3,s0,a3
ffffffffc0201de6:	8699                	srai	a3,a3,0x6
ffffffffc0201de8:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201dea:	06aa                	slli	a3,a3,0xa
ffffffffc0201dec:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201df0:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201df2:	77fd                	lui	a5,0xfffff
ffffffffc0201df4:	068a                	slli	a3,a3,0x2
ffffffffc0201df6:	0009b703          	ld	a4,0(s3)
ffffffffc0201dfa:	8efd                	and	a3,a3,a5
ffffffffc0201dfc:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e00:	10e7ff63          	bgeu	a5,a4,ffffffffc0201f1e <get_pte+0x1dc>
ffffffffc0201e04:	0000ba97          	auipc	s5,0xb
ffffffffc0201e08:	6c4a8a93          	addi	s5,s5,1732 # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201e0c:	000ab403          	ld	s0,0(s5)
ffffffffc0201e10:	01595793          	srli	a5,s2,0x15
ffffffffc0201e14:	1ff7f793          	andi	a5,a5,511
ffffffffc0201e18:	96a2                	add	a3,a3,s0
ffffffffc0201e1a:	00379413          	slli	s0,a5,0x3
ffffffffc0201e1e:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201e20:	6014                	ld	a3,0(s0)
ffffffffc0201e22:	0016f793          	andi	a5,a3,1
ffffffffc0201e26:	ebad                	bnez	a5,ffffffffc0201e98 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e28:	0a0a0363          	beqz	s4,ffffffffc0201ece <get_pte+0x18c>
ffffffffc0201e2c:	100027f3          	csrr	a5,sstatus
ffffffffc0201e30:	8b89                	andi	a5,a5,2
ffffffffc0201e32:	efcd                	bnez	a5,ffffffffc0201eec <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e34:	0000b797          	auipc	a5,0xb
ffffffffc0201e38:	68c7b783          	ld	a5,1676(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201e3c:	6f9c                	ld	a5,24(a5)
ffffffffc0201e3e:	4505                	li	a0,1
ffffffffc0201e40:	9782                	jalr	a5
ffffffffc0201e42:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201e44:	c4c9                	beqz	s1,ffffffffc0201ece <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e46:	0000bb17          	auipc	s6,0xb
ffffffffc0201e4a:	672b0b13          	addi	s6,s6,1650 # ffffffffc020d4b8 <pages>
ffffffffc0201e4e:	000b3503          	ld	a0,0(s6)
ffffffffc0201e52:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e56:	0009b703          	ld	a4,0(s3)
ffffffffc0201e5a:	40a48533          	sub	a0,s1,a0
ffffffffc0201e5e:	8519                	srai	a0,a0,0x6
ffffffffc0201e60:	9552                	add	a0,a0,s4
ffffffffc0201e62:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e66:	4685                	li	a3,1
ffffffffc0201e68:	c094                	sw	a3,0(s1)
ffffffffc0201e6a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e6c:	0532                	slli	a0,a0,0xc
ffffffffc0201e6e:	0ee7f163          	bgeu	a5,a4,ffffffffc0201f50 <get_pte+0x20e>
ffffffffc0201e72:	000ab783          	ld	a5,0(s5)
ffffffffc0201e76:	6605                	lui	a2,0x1
ffffffffc0201e78:	4581                	li	a1,0
ffffffffc0201e7a:	953e                	add	a0,a0,a5
ffffffffc0201e7c:	7c3010ef          	jal	ra,ffffffffc0203e3e <memset>
    return page - pages + nbase;
ffffffffc0201e80:	000b3683          	ld	a3,0(s6)
ffffffffc0201e84:	40d486b3          	sub	a3,s1,a3
ffffffffc0201e88:	8699                	srai	a3,a3,0x6
ffffffffc0201e8a:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e8c:	06aa                	slli	a3,a3,0xa
ffffffffc0201e8e:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e92:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e94:	0009b703          	ld	a4,0(s3)
ffffffffc0201e98:	068a                	slli	a3,a3,0x2
ffffffffc0201e9a:	757d                	lui	a0,0xfffff
ffffffffc0201e9c:	8ee9                	and	a3,a3,a0
ffffffffc0201e9e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201ea2:	06e7f263          	bgeu	a5,a4,ffffffffc0201f06 <get_pte+0x1c4>
ffffffffc0201ea6:	000ab503          	ld	a0,0(s5)
ffffffffc0201eaa:	00c95913          	srli	s2,s2,0xc
ffffffffc0201eae:	1ff97913          	andi	s2,s2,511
ffffffffc0201eb2:	96aa                	add	a3,a3,a0
ffffffffc0201eb4:	00391513          	slli	a0,s2,0x3
ffffffffc0201eb8:	9536                	add	a0,a0,a3
}
ffffffffc0201eba:	70e2                	ld	ra,56(sp)
ffffffffc0201ebc:	7442                	ld	s0,48(sp)
ffffffffc0201ebe:	74a2                	ld	s1,40(sp)
ffffffffc0201ec0:	7902                	ld	s2,32(sp)
ffffffffc0201ec2:	69e2                	ld	s3,24(sp)
ffffffffc0201ec4:	6a42                	ld	s4,16(sp)
ffffffffc0201ec6:	6aa2                	ld	s5,8(sp)
ffffffffc0201ec8:	6b02                	ld	s6,0(sp)
ffffffffc0201eca:	6121                	addi	sp,sp,64
ffffffffc0201ecc:	8082                	ret
            return NULL;
ffffffffc0201ece:	4501                	li	a0,0
ffffffffc0201ed0:	b7ed                	j	ffffffffc0201eba <get_pte+0x178>
        intr_disable();
ffffffffc0201ed2:	a5ffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ed6:	0000b797          	auipc	a5,0xb
ffffffffc0201eda:	5ea7b783          	ld	a5,1514(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201ede:	6f9c                	ld	a5,24(a5)
ffffffffc0201ee0:	4505                	li	a0,1
ffffffffc0201ee2:	9782                	jalr	a5
ffffffffc0201ee4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ee6:	a45fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201eea:	b56d                	j	ffffffffc0201d94 <get_pte+0x52>
        intr_disable();
ffffffffc0201eec:	a45fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0201ef0:	0000b797          	auipc	a5,0xb
ffffffffc0201ef4:	5d07b783          	ld	a5,1488(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201ef8:	6f9c                	ld	a5,24(a5)
ffffffffc0201efa:	4505                	li	a0,1
ffffffffc0201efc:	9782                	jalr	a5
ffffffffc0201efe:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201f00:	a2bfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201f04:	b781                	j	ffffffffc0201e44 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f06:	00003617          	auipc	a2,0x3
ffffffffc0201f0a:	df260613          	addi	a2,a2,-526 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0201f0e:	0fb00593          	li	a1,251
ffffffffc0201f12:	00003517          	auipc	a0,0x3
ffffffffc0201f16:	efe50513          	addi	a0,a0,-258 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0201f1a:	d40fe0ef          	jal	ra,ffffffffc020045a <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f1e:	00003617          	auipc	a2,0x3
ffffffffc0201f22:	dda60613          	addi	a2,a2,-550 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0201f26:	0ee00593          	li	a1,238
ffffffffc0201f2a:	00003517          	auipc	a0,0x3
ffffffffc0201f2e:	ee650513          	addi	a0,a0,-282 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0201f32:	d28fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f36:	86aa                	mv	a3,a0
ffffffffc0201f38:	00003617          	auipc	a2,0x3
ffffffffc0201f3c:	dc060613          	addi	a2,a2,-576 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0201f40:	0eb00593          	li	a1,235
ffffffffc0201f44:	00003517          	auipc	a0,0x3
ffffffffc0201f48:	ecc50513          	addi	a0,a0,-308 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0201f4c:	d0efe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f50:	86aa                	mv	a3,a0
ffffffffc0201f52:	00003617          	auipc	a2,0x3
ffffffffc0201f56:	da660613          	addi	a2,a2,-602 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0201f5a:	0f800593          	li	a1,248
ffffffffc0201f5e:	00003517          	auipc	a0,0x3
ffffffffc0201f62:	eb250513          	addi	a0,a0,-334 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0201f66:	cf4fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201f6a <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f6a:	1141                	addi	sp,sp,-16
ffffffffc0201f6c:	e022                	sd	s0,0(sp)
ffffffffc0201f6e:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f70:	4601                	li	a2,0
{
ffffffffc0201f72:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f74:	dcfff0ef          	jal	ra,ffffffffc0201d42 <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f78:	c011                	beqz	s0,ffffffffc0201f7c <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f7a:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f7c:	c511                	beqz	a0,ffffffffc0201f88 <get_page+0x1e>
ffffffffc0201f7e:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f80:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f82:	0017f713          	andi	a4,a5,1
ffffffffc0201f86:	e709                	bnez	a4,ffffffffc0201f90 <get_page+0x26>
}
ffffffffc0201f88:	60a2                	ld	ra,8(sp)
ffffffffc0201f8a:	6402                	ld	s0,0(sp)
ffffffffc0201f8c:	0141                	addi	sp,sp,16
ffffffffc0201f8e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f90:	078a                	slli	a5,a5,0x2
ffffffffc0201f92:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f94:	0000b717          	auipc	a4,0xb
ffffffffc0201f98:	51c73703          	ld	a4,1308(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201f9c:	00e7ff63          	bgeu	a5,a4,ffffffffc0201fba <get_page+0x50>
ffffffffc0201fa0:	60a2                	ld	ra,8(sp)
ffffffffc0201fa2:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201fa4:	fff80537          	lui	a0,0xfff80
ffffffffc0201fa8:	97aa                	add	a5,a5,a0
ffffffffc0201faa:	079a                	slli	a5,a5,0x6
ffffffffc0201fac:	0000b517          	auipc	a0,0xb
ffffffffc0201fb0:	50c53503          	ld	a0,1292(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201fb4:	953e                	add	a0,a0,a5
ffffffffc0201fb6:	0141                	addi	sp,sp,16
ffffffffc0201fb8:	8082                	ret
ffffffffc0201fba:	c99ff0ef          	jal	ra,ffffffffc0201c52 <pa2page.part.0>

ffffffffc0201fbe <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201fbe:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fc0:	4601                	li	a2,0
{
ffffffffc0201fc2:	ec26                	sd	s1,24(sp)
ffffffffc0201fc4:	f406                	sd	ra,40(sp)
ffffffffc0201fc6:	f022                	sd	s0,32(sp)
ffffffffc0201fc8:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fca:	d79ff0ef          	jal	ra,ffffffffc0201d42 <get_pte>
    if (ptep != NULL)
ffffffffc0201fce:	c511                	beqz	a0,ffffffffc0201fda <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201fd0:	611c                	ld	a5,0(a0)
ffffffffc0201fd2:	842a                	mv	s0,a0
ffffffffc0201fd4:	0017f713          	andi	a4,a5,1
ffffffffc0201fd8:	e711                	bnez	a4,ffffffffc0201fe4 <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201fda:	70a2                	ld	ra,40(sp)
ffffffffc0201fdc:	7402                	ld	s0,32(sp)
ffffffffc0201fde:	64e2                	ld	s1,24(sp)
ffffffffc0201fe0:	6145                	addi	sp,sp,48
ffffffffc0201fe2:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fe4:	078a                	slli	a5,a5,0x2
ffffffffc0201fe6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fe8:	0000b717          	auipc	a4,0xb
ffffffffc0201fec:	4c873703          	ld	a4,1224(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201ff0:	06e7f363          	bgeu	a5,a4,ffffffffc0202056 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ff4:	fff80537          	lui	a0,0xfff80
ffffffffc0201ff8:	97aa                	add	a5,a5,a0
ffffffffc0201ffa:	079a                	slli	a5,a5,0x6
ffffffffc0201ffc:	0000b517          	auipc	a0,0xb
ffffffffc0202000:	4bc53503          	ld	a0,1212(a0) # ffffffffc020d4b8 <pages>
ffffffffc0202004:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202006:	411c                	lw	a5,0(a0)
ffffffffc0202008:	fff7871b          	addiw	a4,a5,-1
ffffffffc020200c:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020200e:	cb11                	beqz	a4,ffffffffc0202022 <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0202010:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202014:	12048073          	sfence.vma	s1
}
ffffffffc0202018:	70a2                	ld	ra,40(sp)
ffffffffc020201a:	7402                	ld	s0,32(sp)
ffffffffc020201c:	64e2                	ld	s1,24(sp)
ffffffffc020201e:	6145                	addi	sp,sp,48
ffffffffc0202020:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202022:	100027f3          	csrr	a5,sstatus
ffffffffc0202026:	8b89                	andi	a5,a5,2
ffffffffc0202028:	eb89                	bnez	a5,ffffffffc020203a <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc020202a:	0000b797          	auipc	a5,0xb
ffffffffc020202e:	4967b783          	ld	a5,1174(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202032:	739c                	ld	a5,32(a5)
ffffffffc0202034:	4585                	li	a1,1
ffffffffc0202036:	9782                	jalr	a5
    if (flag) {
ffffffffc0202038:	bfe1                	j	ffffffffc0202010 <page_remove+0x52>
        intr_disable();
ffffffffc020203a:	e42a                	sd	a0,8(sp)
ffffffffc020203c:	8f5fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202040:	0000b797          	auipc	a5,0xb
ffffffffc0202044:	4807b783          	ld	a5,1152(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202048:	739c                	ld	a5,32(a5)
ffffffffc020204a:	6522                	ld	a0,8(sp)
ffffffffc020204c:	4585                	li	a1,1
ffffffffc020204e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202050:	8dbfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202054:	bf75                	j	ffffffffc0202010 <page_remove+0x52>
ffffffffc0202056:	bfdff0ef          	jal	ra,ffffffffc0201c52 <pa2page.part.0>

ffffffffc020205a <page_insert>:
{
ffffffffc020205a:	7139                	addi	sp,sp,-64
ffffffffc020205c:	e852                	sd	s4,16(sp)
ffffffffc020205e:	8a32                	mv	s4,a2
ffffffffc0202060:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202062:	4605                	li	a2,1
{
ffffffffc0202064:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202066:	85d2                	mv	a1,s4
{
ffffffffc0202068:	f426                	sd	s1,40(sp)
ffffffffc020206a:	fc06                	sd	ra,56(sp)
ffffffffc020206c:	f04a                	sd	s2,32(sp)
ffffffffc020206e:	ec4e                	sd	s3,24(sp)
ffffffffc0202070:	e456                	sd	s5,8(sp)
ffffffffc0202072:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202074:	ccfff0ef          	jal	ra,ffffffffc0201d42 <get_pte>
    if (ptep == NULL)
ffffffffc0202078:	c961                	beqz	a0,ffffffffc0202148 <page_insert+0xee>
    page->ref += 1;
ffffffffc020207a:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc020207c:	611c                	ld	a5,0(a0)
ffffffffc020207e:	89aa                	mv	s3,a0
ffffffffc0202080:	0016871b          	addiw	a4,a3,1
ffffffffc0202084:	c018                	sw	a4,0(s0)
ffffffffc0202086:	0017f713          	andi	a4,a5,1
ffffffffc020208a:	ef05                	bnez	a4,ffffffffc02020c2 <page_insert+0x68>
    return page - pages + nbase;
ffffffffc020208c:	0000b717          	auipc	a4,0xb
ffffffffc0202090:	42c73703          	ld	a4,1068(a4) # ffffffffc020d4b8 <pages>
ffffffffc0202094:	8c19                	sub	s0,s0,a4
ffffffffc0202096:	000807b7          	lui	a5,0x80
ffffffffc020209a:	8419                	srai	s0,s0,0x6
ffffffffc020209c:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020209e:	042a                	slli	s0,s0,0xa
ffffffffc02020a0:	8cc1                	or	s1,s1,s0
ffffffffc02020a2:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02020a6:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020aa:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02020ae:	4501                	li	a0,0
}
ffffffffc02020b0:	70e2                	ld	ra,56(sp)
ffffffffc02020b2:	7442                	ld	s0,48(sp)
ffffffffc02020b4:	74a2                	ld	s1,40(sp)
ffffffffc02020b6:	7902                	ld	s2,32(sp)
ffffffffc02020b8:	69e2                	ld	s3,24(sp)
ffffffffc02020ba:	6a42                	ld	s4,16(sp)
ffffffffc02020bc:	6aa2                	ld	s5,8(sp)
ffffffffc02020be:	6121                	addi	sp,sp,64
ffffffffc02020c0:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02020c2:	078a                	slli	a5,a5,0x2
ffffffffc02020c4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02020c6:	0000b717          	auipc	a4,0xb
ffffffffc02020ca:	3ea73703          	ld	a4,1002(a4) # ffffffffc020d4b0 <npage>
ffffffffc02020ce:	06e7ff63          	bgeu	a5,a4,ffffffffc020214c <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02020d2:	0000ba97          	auipc	s5,0xb
ffffffffc02020d6:	3e6a8a93          	addi	s5,s5,998 # ffffffffc020d4b8 <pages>
ffffffffc02020da:	000ab703          	ld	a4,0(s5)
ffffffffc02020de:	fff80937          	lui	s2,0xfff80
ffffffffc02020e2:	993e                	add	s2,s2,a5
ffffffffc02020e4:	091a                	slli	s2,s2,0x6
ffffffffc02020e6:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02020e8:	01240c63          	beq	s0,s2,ffffffffc0202100 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02020ec:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b14>
ffffffffc02020f0:	fff7869b          	addiw	a3,a5,-1
ffffffffc02020f4:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02020f8:	c691                	beqz	a3,ffffffffc0202104 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020fa:	120a0073          	sfence.vma	s4
}
ffffffffc02020fe:	bf59                	j	ffffffffc0202094 <page_insert+0x3a>
ffffffffc0202100:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202102:	bf49                	j	ffffffffc0202094 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202104:	100027f3          	csrr	a5,sstatus
ffffffffc0202108:	8b89                	andi	a5,a5,2
ffffffffc020210a:	ef91                	bnez	a5,ffffffffc0202126 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc020210c:	0000b797          	auipc	a5,0xb
ffffffffc0202110:	3b47b783          	ld	a5,948(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202114:	739c                	ld	a5,32(a5)
ffffffffc0202116:	4585                	li	a1,1
ffffffffc0202118:	854a                	mv	a0,s2
ffffffffc020211a:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020211c:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202120:	120a0073          	sfence.vma	s4
ffffffffc0202124:	bf85                	j	ffffffffc0202094 <page_insert+0x3a>
        intr_disable();
ffffffffc0202126:	80bfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020212a:	0000b797          	auipc	a5,0xb
ffffffffc020212e:	3967b783          	ld	a5,918(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202132:	739c                	ld	a5,32(a5)
ffffffffc0202134:	4585                	li	a1,1
ffffffffc0202136:	854a                	mv	a0,s2
ffffffffc0202138:	9782                	jalr	a5
        intr_enable();
ffffffffc020213a:	ff0fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020213e:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202142:	120a0073          	sfence.vma	s4
ffffffffc0202146:	b7b9                	j	ffffffffc0202094 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202148:	5571                	li	a0,-4
ffffffffc020214a:	b79d                	j	ffffffffc02020b0 <page_insert+0x56>
ffffffffc020214c:	b07ff0ef          	jal	ra,ffffffffc0201c52 <pa2page.part.0>

ffffffffc0202150 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202150:	00003797          	auipc	a5,0x3
ffffffffc0202154:	b7078793          	addi	a5,a5,-1168 # ffffffffc0204cc0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202158:	638c                	ld	a1,0(a5)
{
ffffffffc020215a:	7159                	addi	sp,sp,-112
ffffffffc020215c:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020215e:	00003517          	auipc	a0,0x3
ffffffffc0202162:	cc250513          	addi	a0,a0,-830 # ffffffffc0204e20 <default_pmm_manager+0x160>
    pmm_manager = &default_pmm_manager;
ffffffffc0202166:	0000bb17          	auipc	s6,0xb
ffffffffc020216a:	35ab0b13          	addi	s6,s6,858 # ffffffffc020d4c0 <pmm_manager>
{
ffffffffc020216e:	f486                	sd	ra,104(sp)
ffffffffc0202170:	e8ca                	sd	s2,80(sp)
ffffffffc0202172:	e4ce                	sd	s3,72(sp)
ffffffffc0202174:	f0a2                	sd	s0,96(sp)
ffffffffc0202176:	eca6                	sd	s1,88(sp)
ffffffffc0202178:	e0d2                	sd	s4,64(sp)
ffffffffc020217a:	fc56                	sd	s5,56(sp)
ffffffffc020217c:	f45e                	sd	s7,40(sp)
ffffffffc020217e:	f062                	sd	s8,32(sp)
ffffffffc0202180:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202182:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202186:	80efe0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc020218a:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020218e:	0000b997          	auipc	s3,0xb
ffffffffc0202192:	33a98993          	addi	s3,s3,826 # ffffffffc020d4c8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202196:	679c                	ld	a5,8(a5)
ffffffffc0202198:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020219a:	57f5                	li	a5,-3
ffffffffc020219c:	07fa                	slli	a5,a5,0x1e
ffffffffc020219e:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02021a2:	f74fe0ef          	jal	ra,ffffffffc0200916 <get_memory_base>
ffffffffc02021a6:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02021a8:	f78fe0ef          	jal	ra,ffffffffc0200920 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02021ac:	200505e3          	beqz	a0,ffffffffc0202bb6 <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021b0:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02021b2:	00003517          	auipc	a0,0x3
ffffffffc02021b6:	ca650513          	addi	a0,a0,-858 # ffffffffc0204e58 <default_pmm_manager+0x198>
ffffffffc02021ba:	fdbfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02021be:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02021c2:	fff40693          	addi	a3,s0,-1
ffffffffc02021c6:	864a                	mv	a2,s2
ffffffffc02021c8:	85a6                	mv	a1,s1
ffffffffc02021ca:	00003517          	auipc	a0,0x3
ffffffffc02021ce:	ca650513          	addi	a0,a0,-858 # ffffffffc0204e70 <default_pmm_manager+0x1b0>
ffffffffc02021d2:	fc3fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02021d6:	c8000737          	lui	a4,0xc8000
ffffffffc02021da:	87a2                	mv	a5,s0
ffffffffc02021dc:	54876163          	bltu	a4,s0,ffffffffc020271e <pmm_init+0x5ce>
ffffffffc02021e0:	757d                	lui	a0,0xfffff
ffffffffc02021e2:	0000c617          	auipc	a2,0xc
ffffffffc02021e6:	30960613          	addi	a2,a2,777 # ffffffffc020e4eb <end+0xfff>
ffffffffc02021ea:	8e69                	and	a2,a2,a0
ffffffffc02021ec:	0000b497          	auipc	s1,0xb
ffffffffc02021f0:	2c448493          	addi	s1,s1,708 # ffffffffc020d4b0 <npage>
ffffffffc02021f4:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021f8:	0000bb97          	auipc	s7,0xb
ffffffffc02021fc:	2c0b8b93          	addi	s7,s7,704 # ffffffffc020d4b8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202200:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202202:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202206:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020220a:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020220c:	02f50863          	beq	a0,a5,ffffffffc020223c <pmm_init+0xec>
ffffffffc0202210:	4781                	li	a5,0
ffffffffc0202212:	4585                	li	a1,1
ffffffffc0202214:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202218:	00679513          	slli	a0,a5,0x6
ffffffffc020221c:	9532                	add	a0,a0,a2
ffffffffc020221e:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b1c>
ffffffffc0202222:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202226:	6088                	ld	a0,0(s1)
ffffffffc0202228:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc020222a:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020222e:	00d50733          	add	a4,a0,a3
ffffffffc0202232:	fee7e3e3          	bltu	a5,a4,ffffffffc0202218 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202236:	071a                	slli	a4,a4,0x6
ffffffffc0202238:	00e606b3          	add	a3,a2,a4
ffffffffc020223c:	c02007b7          	lui	a5,0xc0200
ffffffffc0202240:	2ef6ece3          	bltu	a3,a5,ffffffffc0202d38 <pmm_init+0xbe8>
ffffffffc0202244:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202248:	77fd                	lui	a5,0xfffff
ffffffffc020224a:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020224c:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc020224e:	5086eb63          	bltu	a3,s0,ffffffffc0202764 <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202252:	00003517          	auipc	a0,0x3
ffffffffc0202256:	c4650513          	addi	a0,a0,-954 # ffffffffc0204e98 <default_pmm_manager+0x1d8>
ffffffffc020225a:	f3bfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc020225e:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202262:	0000b917          	auipc	s2,0xb
ffffffffc0202266:	24690913          	addi	s2,s2,582 # ffffffffc020d4a8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc020226a:	7b9c                	ld	a5,48(a5)
ffffffffc020226c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020226e:	00003517          	auipc	a0,0x3
ffffffffc0202272:	c4250513          	addi	a0,a0,-958 # ffffffffc0204eb0 <default_pmm_manager+0x1f0>
ffffffffc0202276:	f1ffd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020227a:	00006697          	auipc	a3,0x6
ffffffffc020227e:	d8668693          	addi	a3,a3,-634 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202282:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202286:	c02007b7          	lui	a5,0xc0200
ffffffffc020228a:	28f6ebe3          	bltu	a3,a5,ffffffffc0202d20 <pmm_init+0xbd0>
ffffffffc020228e:	0009b783          	ld	a5,0(s3)
ffffffffc0202292:	8e9d                	sub	a3,a3,a5
ffffffffc0202294:	0000b797          	auipc	a5,0xb
ffffffffc0202298:	20d7b623          	sd	a3,524(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020229c:	100027f3          	csrr	a5,sstatus
ffffffffc02022a0:	8b89                	andi	a5,a5,2
ffffffffc02022a2:	4a079763          	bnez	a5,ffffffffc0202750 <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02022a6:	000b3783          	ld	a5,0(s6)
ffffffffc02022aa:	779c                	ld	a5,40(a5)
ffffffffc02022ac:	9782                	jalr	a5
ffffffffc02022ae:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02022b0:	6098                	ld	a4,0(s1)
ffffffffc02022b2:	c80007b7          	lui	a5,0xc8000
ffffffffc02022b6:	83b1                	srli	a5,a5,0xc
ffffffffc02022b8:	66e7e363          	bltu	a5,a4,ffffffffc020291e <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02022bc:	00093503          	ld	a0,0(s2)
ffffffffc02022c0:	62050f63          	beqz	a0,ffffffffc02028fe <pmm_init+0x7ae>
ffffffffc02022c4:	03451793          	slli	a5,a0,0x34
ffffffffc02022c8:	62079b63          	bnez	a5,ffffffffc02028fe <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02022cc:	4601                	li	a2,0
ffffffffc02022ce:	4581                	li	a1,0
ffffffffc02022d0:	c9bff0ef          	jal	ra,ffffffffc0201f6a <get_page>
ffffffffc02022d4:	60051563          	bnez	a0,ffffffffc02028de <pmm_init+0x78e>
ffffffffc02022d8:	100027f3          	csrr	a5,sstatus
ffffffffc02022dc:	8b89                	andi	a5,a5,2
ffffffffc02022de:	44079e63          	bnez	a5,ffffffffc020273a <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02022e2:	000b3783          	ld	a5,0(s6)
ffffffffc02022e6:	4505                	li	a0,1
ffffffffc02022e8:	6f9c                	ld	a5,24(a5)
ffffffffc02022ea:	9782                	jalr	a5
ffffffffc02022ec:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02022ee:	00093503          	ld	a0,0(s2)
ffffffffc02022f2:	4681                	li	a3,0
ffffffffc02022f4:	4601                	li	a2,0
ffffffffc02022f6:	85d2                	mv	a1,s4
ffffffffc02022f8:	d63ff0ef          	jal	ra,ffffffffc020205a <page_insert>
ffffffffc02022fc:	26051ae3          	bnez	a0,ffffffffc0202d70 <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202300:	00093503          	ld	a0,0(s2)
ffffffffc0202304:	4601                	li	a2,0
ffffffffc0202306:	4581                	li	a1,0
ffffffffc0202308:	a3bff0ef          	jal	ra,ffffffffc0201d42 <get_pte>
ffffffffc020230c:	240502e3          	beqz	a0,ffffffffc0202d50 <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc0202310:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202312:	0017f713          	andi	a4,a5,1
ffffffffc0202316:	5a070263          	beqz	a4,ffffffffc02028ba <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc020231a:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020231c:	078a                	slli	a5,a5,0x2
ffffffffc020231e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202320:	58e7fb63          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202324:	000bb683          	ld	a3,0(s7)
ffffffffc0202328:	fff80637          	lui	a2,0xfff80
ffffffffc020232c:	97b2                	add	a5,a5,a2
ffffffffc020232e:	079a                	slli	a5,a5,0x6
ffffffffc0202330:	97b6                	add	a5,a5,a3
ffffffffc0202332:	14fa17e3          	bne	s4,a5,ffffffffc0202c80 <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202336:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc020233a:	4785                	li	a5,1
ffffffffc020233c:	12f692e3          	bne	a3,a5,ffffffffc0202c60 <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202340:	00093503          	ld	a0,0(s2)
ffffffffc0202344:	77fd                	lui	a5,0xfffff
ffffffffc0202346:	6114                	ld	a3,0(a0)
ffffffffc0202348:	068a                	slli	a3,a3,0x2
ffffffffc020234a:	8efd                	and	a3,a3,a5
ffffffffc020234c:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202350:	0ee67ce3          	bgeu	a2,a4,ffffffffc0202c48 <pmm_init+0xaf8>
ffffffffc0202354:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202358:	96e2                	add	a3,a3,s8
ffffffffc020235a:	0006ba83          	ld	s5,0(a3)
ffffffffc020235e:	0a8a                	slli	s5,s5,0x2
ffffffffc0202360:	00fafab3          	and	s5,s5,a5
ffffffffc0202364:	00cad793          	srli	a5,s5,0xc
ffffffffc0202368:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0202c2e <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020236c:	4601                	li	a2,0
ffffffffc020236e:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202370:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202372:	9d1ff0ef          	jal	ra,ffffffffc0201d42 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202376:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202378:	55551363          	bne	a0,s5,ffffffffc02028be <pmm_init+0x76e>
ffffffffc020237c:	100027f3          	csrr	a5,sstatus
ffffffffc0202380:	8b89                	andi	a5,a5,2
ffffffffc0202382:	3a079163          	bnez	a5,ffffffffc0202724 <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202386:	000b3783          	ld	a5,0(s6)
ffffffffc020238a:	4505                	li	a0,1
ffffffffc020238c:	6f9c                	ld	a5,24(a5)
ffffffffc020238e:	9782                	jalr	a5
ffffffffc0202390:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202392:	00093503          	ld	a0,0(s2)
ffffffffc0202396:	46d1                	li	a3,20
ffffffffc0202398:	6605                	lui	a2,0x1
ffffffffc020239a:	85e2                	mv	a1,s8
ffffffffc020239c:	cbfff0ef          	jal	ra,ffffffffc020205a <page_insert>
ffffffffc02023a0:	060517e3          	bnez	a0,ffffffffc0202c0e <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023a4:	00093503          	ld	a0,0(s2)
ffffffffc02023a8:	4601                	li	a2,0
ffffffffc02023aa:	6585                	lui	a1,0x1
ffffffffc02023ac:	997ff0ef          	jal	ra,ffffffffc0201d42 <get_pte>
ffffffffc02023b0:	02050fe3          	beqz	a0,ffffffffc0202bee <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02023b4:	611c                	ld	a5,0(a0)
ffffffffc02023b6:	0107f713          	andi	a4,a5,16
ffffffffc02023ba:	7c070e63          	beqz	a4,ffffffffc0202b96 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02023be:	8b91                	andi	a5,a5,4
ffffffffc02023c0:	7a078b63          	beqz	a5,ffffffffc0202b76 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02023c4:	00093503          	ld	a0,0(s2)
ffffffffc02023c8:	611c                	ld	a5,0(a0)
ffffffffc02023ca:	8bc1                	andi	a5,a5,16
ffffffffc02023cc:	78078563          	beqz	a5,ffffffffc0202b56 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02023d0:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc02023d4:	4785                	li	a5,1
ffffffffc02023d6:	76f71063          	bne	a4,a5,ffffffffc0202b36 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02023da:	4681                	li	a3,0
ffffffffc02023dc:	6605                	lui	a2,0x1
ffffffffc02023de:	85d2                	mv	a1,s4
ffffffffc02023e0:	c7bff0ef          	jal	ra,ffffffffc020205a <page_insert>
ffffffffc02023e4:	72051963          	bnez	a0,ffffffffc0202b16 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02023e8:	000a2703          	lw	a4,0(s4)
ffffffffc02023ec:	4789                	li	a5,2
ffffffffc02023ee:	70f71463          	bne	a4,a5,ffffffffc0202af6 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02023f2:	000c2783          	lw	a5,0(s8)
ffffffffc02023f6:	6e079063          	bnez	a5,ffffffffc0202ad6 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023fa:	00093503          	ld	a0,0(s2)
ffffffffc02023fe:	4601                	li	a2,0
ffffffffc0202400:	6585                	lui	a1,0x1
ffffffffc0202402:	941ff0ef          	jal	ra,ffffffffc0201d42 <get_pte>
ffffffffc0202406:	6a050863          	beqz	a0,ffffffffc0202ab6 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc020240a:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc020240c:	00177793          	andi	a5,a4,1
ffffffffc0202410:	4a078563          	beqz	a5,ffffffffc02028ba <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202414:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202416:	00271793          	slli	a5,a4,0x2
ffffffffc020241a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020241c:	48d7fd63          	bgeu	a5,a3,ffffffffc02028b6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202420:	000bb683          	ld	a3,0(s7)
ffffffffc0202424:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202428:	97d6                	add	a5,a5,s5
ffffffffc020242a:	079a                	slli	a5,a5,0x6
ffffffffc020242c:	97b6                	add	a5,a5,a3
ffffffffc020242e:	66fa1463          	bne	s4,a5,ffffffffc0202a96 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202432:	8b41                	andi	a4,a4,16
ffffffffc0202434:	64071163          	bnez	a4,ffffffffc0202a76 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202438:	00093503          	ld	a0,0(s2)
ffffffffc020243c:	4581                	li	a1,0
ffffffffc020243e:	b81ff0ef          	jal	ra,ffffffffc0201fbe <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202442:	000a2c83          	lw	s9,0(s4)
ffffffffc0202446:	4785                	li	a5,1
ffffffffc0202448:	60fc9763          	bne	s9,a5,ffffffffc0202a56 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc020244c:	000c2783          	lw	a5,0(s8)
ffffffffc0202450:	5e079363          	bnez	a5,ffffffffc0202a36 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202454:	00093503          	ld	a0,0(s2)
ffffffffc0202458:	6585                	lui	a1,0x1
ffffffffc020245a:	b65ff0ef          	jal	ra,ffffffffc0201fbe <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020245e:	000a2783          	lw	a5,0(s4)
ffffffffc0202462:	52079a63          	bnez	a5,ffffffffc0202996 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202466:	000c2783          	lw	a5,0(s8)
ffffffffc020246a:	50079663          	bnez	a5,ffffffffc0202976 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020246e:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202472:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202474:	000a3683          	ld	a3,0(s4)
ffffffffc0202478:	068a                	slli	a3,a3,0x2
ffffffffc020247a:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020247c:	42b6fd63          	bgeu	a3,a1,ffffffffc02028b6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202480:	000bb503          	ld	a0,0(s7)
ffffffffc0202484:	96d6                	add	a3,a3,s5
ffffffffc0202486:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202488:	00d507b3          	add	a5,a0,a3
ffffffffc020248c:	439c                	lw	a5,0(a5)
ffffffffc020248e:	4d979463          	bne	a5,s9,ffffffffc0202956 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202492:	8699                	srai	a3,a3,0x6
ffffffffc0202494:	00080637          	lui	a2,0x80
ffffffffc0202498:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020249a:	00c69713          	slli	a4,a3,0xc
ffffffffc020249e:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02024a0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02024a2:	48b77e63          	bgeu	a4,a1,ffffffffc020293e <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02024a6:	0009b703          	ld	a4,0(s3)
ffffffffc02024aa:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc02024ac:	629c                	ld	a5,0(a3)
ffffffffc02024ae:	078a                	slli	a5,a5,0x2
ffffffffc02024b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024b2:	40b7f263          	bgeu	a5,a1,ffffffffc02028b6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024b6:	8f91                	sub	a5,a5,a2
ffffffffc02024b8:	079a                	slli	a5,a5,0x6
ffffffffc02024ba:	953e                	add	a0,a0,a5
ffffffffc02024bc:	100027f3          	csrr	a5,sstatus
ffffffffc02024c0:	8b89                	andi	a5,a5,2
ffffffffc02024c2:	30079963          	bnez	a5,ffffffffc02027d4 <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc02024c6:	000b3783          	ld	a5,0(s6)
ffffffffc02024ca:	4585                	li	a1,1
ffffffffc02024cc:	739c                	ld	a5,32(a5)
ffffffffc02024ce:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02024d0:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc02024d4:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024d6:	078a                	slli	a5,a5,0x2
ffffffffc02024d8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024da:	3ce7fe63          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02024de:	000bb503          	ld	a0,0(s7)
ffffffffc02024e2:	fff80737          	lui	a4,0xfff80
ffffffffc02024e6:	97ba                	add	a5,a5,a4
ffffffffc02024e8:	079a                	slli	a5,a5,0x6
ffffffffc02024ea:	953e                	add	a0,a0,a5
ffffffffc02024ec:	100027f3          	csrr	a5,sstatus
ffffffffc02024f0:	8b89                	andi	a5,a5,2
ffffffffc02024f2:	2c079563          	bnez	a5,ffffffffc02027bc <pmm_init+0x66c>
ffffffffc02024f6:	000b3783          	ld	a5,0(s6)
ffffffffc02024fa:	4585                	li	a1,1
ffffffffc02024fc:	739c                	ld	a5,32(a5)
ffffffffc02024fe:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202500:	00093783          	ld	a5,0(s2)
ffffffffc0202504:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b14>
    asm volatile("sfence.vma");
ffffffffc0202508:	12000073          	sfence.vma
ffffffffc020250c:	100027f3          	csrr	a5,sstatus
ffffffffc0202510:	8b89                	andi	a5,a5,2
ffffffffc0202512:	28079b63          	bnez	a5,ffffffffc02027a8 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202516:	000b3783          	ld	a5,0(s6)
ffffffffc020251a:	779c                	ld	a5,40(a5)
ffffffffc020251c:	9782                	jalr	a5
ffffffffc020251e:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202520:	4b441b63          	bne	s0,s4,ffffffffc02029d6 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202524:	00003517          	auipc	a0,0x3
ffffffffc0202528:	cb450513          	addi	a0,a0,-844 # ffffffffc02051d8 <default_pmm_manager+0x518>
ffffffffc020252c:	c69fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202530:	100027f3          	csrr	a5,sstatus
ffffffffc0202534:	8b89                	andi	a5,a5,2
ffffffffc0202536:	24079f63          	bnez	a5,ffffffffc0202794 <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc020253a:	000b3783          	ld	a5,0(s6)
ffffffffc020253e:	779c                	ld	a5,40(a5)
ffffffffc0202540:	9782                	jalr	a5
ffffffffc0202542:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202544:	6098                	ld	a4,0(s1)
ffffffffc0202546:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020254a:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020254c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202550:	6a05                	lui	s4,0x1
ffffffffc0202552:	02f47c63          	bgeu	s0,a5,ffffffffc020258a <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202556:	00c45793          	srli	a5,s0,0xc
ffffffffc020255a:	00093503          	ld	a0,0(s2)
ffffffffc020255e:	2ee7ff63          	bgeu	a5,a4,ffffffffc020285c <pmm_init+0x70c>
ffffffffc0202562:	0009b583          	ld	a1,0(s3)
ffffffffc0202566:	4601                	li	a2,0
ffffffffc0202568:	95a2                	add	a1,a1,s0
ffffffffc020256a:	fd8ff0ef          	jal	ra,ffffffffc0201d42 <get_pte>
ffffffffc020256e:	32050463          	beqz	a0,ffffffffc0202896 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202572:	611c                	ld	a5,0(a0)
ffffffffc0202574:	078a                	slli	a5,a5,0x2
ffffffffc0202576:	0157f7b3          	and	a5,a5,s5
ffffffffc020257a:	2e879e63          	bne	a5,s0,ffffffffc0202876 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc020257e:	6098                	ld	a4,0(s1)
ffffffffc0202580:	9452                	add	s0,s0,s4
ffffffffc0202582:	00c71793          	slli	a5,a4,0xc
ffffffffc0202586:	fcf468e3          	bltu	s0,a5,ffffffffc0202556 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc020258a:	00093783          	ld	a5,0(s2)
ffffffffc020258e:	639c                	ld	a5,0(a5)
ffffffffc0202590:	42079363          	bnez	a5,ffffffffc02029b6 <pmm_init+0x866>
ffffffffc0202594:	100027f3          	csrr	a5,sstatus
ffffffffc0202598:	8b89                	andi	a5,a5,2
ffffffffc020259a:	24079963          	bnez	a5,ffffffffc02027ec <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc020259e:	000b3783          	ld	a5,0(s6)
ffffffffc02025a2:	4505                	li	a0,1
ffffffffc02025a4:	6f9c                	ld	a5,24(a5)
ffffffffc02025a6:	9782                	jalr	a5
ffffffffc02025a8:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025aa:	00093503          	ld	a0,0(s2)
ffffffffc02025ae:	4699                	li	a3,6
ffffffffc02025b0:	10000613          	li	a2,256
ffffffffc02025b4:	85d2                	mv	a1,s4
ffffffffc02025b6:	aa5ff0ef          	jal	ra,ffffffffc020205a <page_insert>
ffffffffc02025ba:	44051e63          	bnez	a0,ffffffffc0202a16 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc02025be:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02025c2:	4785                	li	a5,1
ffffffffc02025c4:	42f71963          	bne	a4,a5,ffffffffc02029f6 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02025c8:	00093503          	ld	a0,0(s2)
ffffffffc02025cc:	6405                	lui	s0,0x1
ffffffffc02025ce:	4699                	li	a3,6
ffffffffc02025d0:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02025d4:	85d2                	mv	a1,s4
ffffffffc02025d6:	a85ff0ef          	jal	ra,ffffffffc020205a <page_insert>
ffffffffc02025da:	72051363          	bnez	a0,ffffffffc0202d00 <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc02025de:	000a2703          	lw	a4,0(s4)
ffffffffc02025e2:	4789                	li	a5,2
ffffffffc02025e4:	6ef71e63          	bne	a4,a5,ffffffffc0202ce0 <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025e8:	00003597          	auipc	a1,0x3
ffffffffc02025ec:	d3858593          	addi	a1,a1,-712 # ffffffffc0205320 <default_pmm_manager+0x660>
ffffffffc02025f0:	10000513          	li	a0,256
ffffffffc02025f4:	7de010ef          	jal	ra,ffffffffc0203dd2 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02025f8:	10040593          	addi	a1,s0,256
ffffffffc02025fc:	10000513          	li	a0,256
ffffffffc0202600:	7e4010ef          	jal	ra,ffffffffc0203de4 <strcmp>
ffffffffc0202604:	6a051e63          	bnez	a0,ffffffffc0202cc0 <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202608:	000bb683          	ld	a3,0(s7)
ffffffffc020260c:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202610:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202612:	40da06b3          	sub	a3,s4,a3
ffffffffc0202616:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202618:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc020261a:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc020261c:	8031                	srli	s0,s0,0xc
ffffffffc020261e:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202622:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202624:	30f77d63          	bgeu	a4,a5,ffffffffc020293e <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202628:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020262c:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202630:	96be                	add	a3,a3,a5
ffffffffc0202632:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202636:	766010ef          	jal	ra,ffffffffc0203d9c <strlen>
ffffffffc020263a:	66051363          	bnez	a0,ffffffffc0202ca0 <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc020263e:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202642:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202644:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b14>
ffffffffc0202648:	068a                	slli	a3,a3,0x2
ffffffffc020264a:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc020264c:	26f6f563          	bgeu	a3,a5,ffffffffc02028b6 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202650:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202652:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202654:	2ef47563          	bgeu	s0,a5,ffffffffc020293e <pmm_init+0x7ee>
ffffffffc0202658:	0009b403          	ld	s0,0(s3)
ffffffffc020265c:	9436                	add	s0,s0,a3
ffffffffc020265e:	100027f3          	csrr	a5,sstatus
ffffffffc0202662:	8b89                	andi	a5,a5,2
ffffffffc0202664:	1e079163          	bnez	a5,ffffffffc0202846 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202668:	000b3783          	ld	a5,0(s6)
ffffffffc020266c:	4585                	li	a1,1
ffffffffc020266e:	8552                	mv	a0,s4
ffffffffc0202670:	739c                	ld	a5,32(a5)
ffffffffc0202672:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202674:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202676:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202678:	078a                	slli	a5,a5,0x2
ffffffffc020267a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020267c:	22e7fd63          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202680:	000bb503          	ld	a0,0(s7)
ffffffffc0202684:	fff80737          	lui	a4,0xfff80
ffffffffc0202688:	97ba                	add	a5,a5,a4
ffffffffc020268a:	079a                	slli	a5,a5,0x6
ffffffffc020268c:	953e                	add	a0,a0,a5
ffffffffc020268e:	100027f3          	csrr	a5,sstatus
ffffffffc0202692:	8b89                	andi	a5,a5,2
ffffffffc0202694:	18079d63          	bnez	a5,ffffffffc020282e <pmm_init+0x6de>
ffffffffc0202698:	000b3783          	ld	a5,0(s6)
ffffffffc020269c:	4585                	li	a1,1
ffffffffc020269e:	739c                	ld	a5,32(a5)
ffffffffc02026a0:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02026a2:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc02026a6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02026a8:	078a                	slli	a5,a5,0x2
ffffffffc02026aa:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026ac:	20e7f563          	bgeu	a5,a4,ffffffffc02028b6 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02026b0:	000bb503          	ld	a0,0(s7)
ffffffffc02026b4:	fff80737          	lui	a4,0xfff80
ffffffffc02026b8:	97ba                	add	a5,a5,a4
ffffffffc02026ba:	079a                	slli	a5,a5,0x6
ffffffffc02026bc:	953e                	add	a0,a0,a5
ffffffffc02026be:	100027f3          	csrr	a5,sstatus
ffffffffc02026c2:	8b89                	andi	a5,a5,2
ffffffffc02026c4:	14079963          	bnez	a5,ffffffffc0202816 <pmm_init+0x6c6>
ffffffffc02026c8:	000b3783          	ld	a5,0(s6)
ffffffffc02026cc:	4585                	li	a1,1
ffffffffc02026ce:	739c                	ld	a5,32(a5)
ffffffffc02026d0:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02026d2:	00093783          	ld	a5,0(s2)
ffffffffc02026d6:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc02026da:	12000073          	sfence.vma
ffffffffc02026de:	100027f3          	csrr	a5,sstatus
ffffffffc02026e2:	8b89                	andi	a5,a5,2
ffffffffc02026e4:	10079f63          	bnez	a5,ffffffffc0202802 <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026e8:	000b3783          	ld	a5,0(s6)
ffffffffc02026ec:	779c                	ld	a5,40(a5)
ffffffffc02026ee:	9782                	jalr	a5
ffffffffc02026f0:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02026f2:	4c8c1e63          	bne	s8,s0,ffffffffc0202bce <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02026f6:	00003517          	auipc	a0,0x3
ffffffffc02026fa:	ca250513          	addi	a0,a0,-862 # ffffffffc0205398 <default_pmm_manager+0x6d8>
ffffffffc02026fe:	a97fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202702:	7406                	ld	s0,96(sp)
ffffffffc0202704:	70a6                	ld	ra,104(sp)
ffffffffc0202706:	64e6                	ld	s1,88(sp)
ffffffffc0202708:	6946                	ld	s2,80(sp)
ffffffffc020270a:	69a6                	ld	s3,72(sp)
ffffffffc020270c:	6a06                	ld	s4,64(sp)
ffffffffc020270e:	7ae2                	ld	s5,56(sp)
ffffffffc0202710:	7b42                	ld	s6,48(sp)
ffffffffc0202712:	7ba2                	ld	s7,40(sp)
ffffffffc0202714:	7c02                	ld	s8,32(sp)
ffffffffc0202716:	6ce2                	ld	s9,24(sp)
ffffffffc0202718:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc020271a:	b72ff06f          	j	ffffffffc0201a8c <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc020271e:	c80007b7          	lui	a5,0xc8000
ffffffffc0202722:	bc7d                	j	ffffffffc02021e0 <pmm_init+0x90>
        intr_disable();
ffffffffc0202724:	a0cfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202728:	000b3783          	ld	a5,0(s6)
ffffffffc020272c:	4505                	li	a0,1
ffffffffc020272e:	6f9c                	ld	a5,24(a5)
ffffffffc0202730:	9782                	jalr	a5
ffffffffc0202732:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202734:	9f6fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202738:	b9a9                	j	ffffffffc0202392 <pmm_init+0x242>
        intr_disable();
ffffffffc020273a:	9f6fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020273e:	000b3783          	ld	a5,0(s6)
ffffffffc0202742:	4505                	li	a0,1
ffffffffc0202744:	6f9c                	ld	a5,24(a5)
ffffffffc0202746:	9782                	jalr	a5
ffffffffc0202748:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020274a:	9e0fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020274e:	b645                	j	ffffffffc02022ee <pmm_init+0x19e>
        intr_disable();
ffffffffc0202750:	9e0fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202754:	000b3783          	ld	a5,0(s6)
ffffffffc0202758:	779c                	ld	a5,40(a5)
ffffffffc020275a:	9782                	jalr	a5
ffffffffc020275c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020275e:	9ccfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202762:	b6b9                	j	ffffffffc02022b0 <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202764:	6705                	lui	a4,0x1
ffffffffc0202766:	177d                	addi	a4,a4,-1
ffffffffc0202768:	96ba                	add	a3,a3,a4
ffffffffc020276a:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc020276c:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202770:	14a77363          	bgeu	a4,a0,ffffffffc02028b6 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202774:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202778:	fff80537          	lui	a0,0xfff80
ffffffffc020277c:	972a                	add	a4,a4,a0
ffffffffc020277e:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202780:	8c1d                	sub	s0,s0,a5
ffffffffc0202782:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202786:	00c45593          	srli	a1,s0,0xc
ffffffffc020278a:	9532                	add	a0,a0,a2
ffffffffc020278c:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020278e:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202792:	b4c1                	j	ffffffffc0202252 <pmm_init+0x102>
        intr_disable();
ffffffffc0202794:	99cfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202798:	000b3783          	ld	a5,0(s6)
ffffffffc020279c:	779c                	ld	a5,40(a5)
ffffffffc020279e:	9782                	jalr	a5
ffffffffc02027a0:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02027a2:	988fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027a6:	bb79                	j	ffffffffc0202544 <pmm_init+0x3f4>
        intr_disable();
ffffffffc02027a8:	988fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027ac:	000b3783          	ld	a5,0(s6)
ffffffffc02027b0:	779c                	ld	a5,40(a5)
ffffffffc02027b2:	9782                	jalr	a5
ffffffffc02027b4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027b6:	974fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027ba:	b39d                	j	ffffffffc0202520 <pmm_init+0x3d0>
ffffffffc02027bc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027be:	972fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027c2:	000b3783          	ld	a5,0(s6)
ffffffffc02027c6:	6522                	ld	a0,8(sp)
ffffffffc02027c8:	4585                	li	a1,1
ffffffffc02027ca:	739c                	ld	a5,32(a5)
ffffffffc02027cc:	9782                	jalr	a5
        intr_enable();
ffffffffc02027ce:	95cfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027d2:	b33d                	j	ffffffffc0202500 <pmm_init+0x3b0>
ffffffffc02027d4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027d6:	95afe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027da:	000b3783          	ld	a5,0(s6)
ffffffffc02027de:	6522                	ld	a0,8(sp)
ffffffffc02027e0:	4585                	li	a1,1
ffffffffc02027e2:	739c                	ld	a5,32(a5)
ffffffffc02027e4:	9782                	jalr	a5
        intr_enable();
ffffffffc02027e6:	944fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027ea:	b1dd                	j	ffffffffc02024d0 <pmm_init+0x380>
        intr_disable();
ffffffffc02027ec:	944fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027f0:	000b3783          	ld	a5,0(s6)
ffffffffc02027f4:	4505                	li	a0,1
ffffffffc02027f6:	6f9c                	ld	a5,24(a5)
ffffffffc02027f8:	9782                	jalr	a5
ffffffffc02027fa:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027fc:	92efe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202800:	b36d                	j	ffffffffc02025aa <pmm_init+0x45a>
        intr_disable();
ffffffffc0202802:	92efe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202806:	000b3783          	ld	a5,0(s6)
ffffffffc020280a:	779c                	ld	a5,40(a5)
ffffffffc020280c:	9782                	jalr	a5
ffffffffc020280e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202810:	91afe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202814:	bdf9                	j	ffffffffc02026f2 <pmm_init+0x5a2>
ffffffffc0202816:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202818:	918fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020281c:	000b3783          	ld	a5,0(s6)
ffffffffc0202820:	6522                	ld	a0,8(sp)
ffffffffc0202822:	4585                	li	a1,1
ffffffffc0202824:	739c                	ld	a5,32(a5)
ffffffffc0202826:	9782                	jalr	a5
        intr_enable();
ffffffffc0202828:	902fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020282c:	b55d                	j	ffffffffc02026d2 <pmm_init+0x582>
ffffffffc020282e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202830:	900fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202834:	000b3783          	ld	a5,0(s6)
ffffffffc0202838:	6522                	ld	a0,8(sp)
ffffffffc020283a:	4585                	li	a1,1
ffffffffc020283c:	739c                	ld	a5,32(a5)
ffffffffc020283e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202840:	8eafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202844:	bdb9                	j	ffffffffc02026a2 <pmm_init+0x552>
        intr_disable();
ffffffffc0202846:	8eafe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020284a:	000b3783          	ld	a5,0(s6)
ffffffffc020284e:	4585                	li	a1,1
ffffffffc0202850:	8552                	mv	a0,s4
ffffffffc0202852:	739c                	ld	a5,32(a5)
ffffffffc0202854:	9782                	jalr	a5
        intr_enable();
ffffffffc0202856:	8d4fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020285a:	bd29                	j	ffffffffc0202674 <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020285c:	86a2                	mv	a3,s0
ffffffffc020285e:	00002617          	auipc	a2,0x2
ffffffffc0202862:	49a60613          	addi	a2,a2,1178 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0202866:	1a400593          	li	a1,420
ffffffffc020286a:	00002517          	auipc	a0,0x2
ffffffffc020286e:	5a650513          	addi	a0,a0,1446 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202872:	be9fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202876:	00003697          	auipc	a3,0x3
ffffffffc020287a:	9c268693          	addi	a3,a3,-1598 # ffffffffc0205238 <default_pmm_manager+0x578>
ffffffffc020287e:	00002617          	auipc	a2,0x2
ffffffffc0202882:	09260613          	addi	a2,a2,146 # ffffffffc0204910 <commands+0x818>
ffffffffc0202886:	1a500593          	li	a1,421
ffffffffc020288a:	00002517          	auipc	a0,0x2
ffffffffc020288e:	58650513          	addi	a0,a0,1414 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202892:	bc9fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202896:	00003697          	auipc	a3,0x3
ffffffffc020289a:	96268693          	addi	a3,a3,-1694 # ffffffffc02051f8 <default_pmm_manager+0x538>
ffffffffc020289e:	00002617          	auipc	a2,0x2
ffffffffc02028a2:	07260613          	addi	a2,a2,114 # ffffffffc0204910 <commands+0x818>
ffffffffc02028a6:	1a400593          	li	a1,420
ffffffffc02028aa:	00002517          	auipc	a0,0x2
ffffffffc02028ae:	56650513          	addi	a0,a0,1382 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc02028b2:	ba9fd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc02028b6:	b9cff0ef          	jal	ra,ffffffffc0201c52 <pa2page.part.0>
ffffffffc02028ba:	bb4ff0ef          	jal	ra,ffffffffc0201c6e <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02028be:	00002697          	auipc	a3,0x2
ffffffffc02028c2:	73268693          	addi	a3,a3,1842 # ffffffffc0204ff0 <default_pmm_manager+0x330>
ffffffffc02028c6:	00002617          	auipc	a2,0x2
ffffffffc02028ca:	04a60613          	addi	a2,a2,74 # ffffffffc0204910 <commands+0x818>
ffffffffc02028ce:	17400593          	li	a1,372
ffffffffc02028d2:	00002517          	auipc	a0,0x2
ffffffffc02028d6:	53e50513          	addi	a0,a0,1342 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc02028da:	b81fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028de:	00002697          	auipc	a3,0x2
ffffffffc02028e2:	65268693          	addi	a3,a3,1618 # ffffffffc0204f30 <default_pmm_manager+0x270>
ffffffffc02028e6:	00002617          	auipc	a2,0x2
ffffffffc02028ea:	02a60613          	addi	a2,a2,42 # ffffffffc0204910 <commands+0x818>
ffffffffc02028ee:	16700593          	li	a1,359
ffffffffc02028f2:	00002517          	auipc	a0,0x2
ffffffffc02028f6:	51e50513          	addi	a0,a0,1310 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc02028fa:	b61fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028fe:	00002697          	auipc	a3,0x2
ffffffffc0202902:	5f268693          	addi	a3,a3,1522 # ffffffffc0204ef0 <default_pmm_manager+0x230>
ffffffffc0202906:	00002617          	auipc	a2,0x2
ffffffffc020290a:	00a60613          	addi	a2,a2,10 # ffffffffc0204910 <commands+0x818>
ffffffffc020290e:	16600593          	li	a1,358
ffffffffc0202912:	00002517          	auipc	a0,0x2
ffffffffc0202916:	4fe50513          	addi	a0,a0,1278 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc020291a:	b41fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020291e:	00002697          	auipc	a3,0x2
ffffffffc0202922:	5b268693          	addi	a3,a3,1458 # ffffffffc0204ed0 <default_pmm_manager+0x210>
ffffffffc0202926:	00002617          	auipc	a2,0x2
ffffffffc020292a:	fea60613          	addi	a2,a2,-22 # ffffffffc0204910 <commands+0x818>
ffffffffc020292e:	16500593          	li	a1,357
ffffffffc0202932:	00002517          	auipc	a0,0x2
ffffffffc0202936:	4de50513          	addi	a0,a0,1246 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc020293a:	b21fd0ef          	jal	ra,ffffffffc020045a <__panic>
    return KADDR(page2pa(page));
ffffffffc020293e:	00002617          	auipc	a2,0x2
ffffffffc0202942:	3ba60613          	addi	a2,a2,954 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0202946:	07100593          	li	a1,113
ffffffffc020294a:	00002517          	auipc	a0,0x2
ffffffffc020294e:	3d650513          	addi	a0,a0,982 # ffffffffc0204d20 <default_pmm_manager+0x60>
ffffffffc0202952:	b09fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202956:	00003697          	auipc	a3,0x3
ffffffffc020295a:	82a68693          	addi	a3,a3,-2006 # ffffffffc0205180 <default_pmm_manager+0x4c0>
ffffffffc020295e:	00002617          	auipc	a2,0x2
ffffffffc0202962:	fb260613          	addi	a2,a2,-78 # ffffffffc0204910 <commands+0x818>
ffffffffc0202966:	18d00593          	li	a1,397
ffffffffc020296a:	00002517          	auipc	a0,0x2
ffffffffc020296e:	4a650513          	addi	a0,a0,1190 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202972:	ae9fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202976:	00002697          	auipc	a3,0x2
ffffffffc020297a:	7c268693          	addi	a3,a3,1986 # ffffffffc0205138 <default_pmm_manager+0x478>
ffffffffc020297e:	00002617          	auipc	a2,0x2
ffffffffc0202982:	f9260613          	addi	a2,a2,-110 # ffffffffc0204910 <commands+0x818>
ffffffffc0202986:	18b00593          	li	a1,395
ffffffffc020298a:	00002517          	auipc	a0,0x2
ffffffffc020298e:	48650513          	addi	a0,a0,1158 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202992:	ac9fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202996:	00002697          	auipc	a3,0x2
ffffffffc020299a:	7d268693          	addi	a3,a3,2002 # ffffffffc0205168 <default_pmm_manager+0x4a8>
ffffffffc020299e:	00002617          	auipc	a2,0x2
ffffffffc02029a2:	f7260613          	addi	a2,a2,-142 # ffffffffc0204910 <commands+0x818>
ffffffffc02029a6:	18a00593          	li	a1,394
ffffffffc02029aa:	00002517          	auipc	a0,0x2
ffffffffc02029ae:	46650513          	addi	a0,a0,1126 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc02029b2:	aa9fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc02029b6:	00003697          	auipc	a3,0x3
ffffffffc02029ba:	89a68693          	addi	a3,a3,-1894 # ffffffffc0205250 <default_pmm_manager+0x590>
ffffffffc02029be:	00002617          	auipc	a2,0x2
ffffffffc02029c2:	f5260613          	addi	a2,a2,-174 # ffffffffc0204910 <commands+0x818>
ffffffffc02029c6:	1a800593          	li	a1,424
ffffffffc02029ca:	00002517          	auipc	a0,0x2
ffffffffc02029ce:	44650513          	addi	a0,a0,1094 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc02029d2:	a89fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02029d6:	00002697          	auipc	a3,0x2
ffffffffc02029da:	7da68693          	addi	a3,a3,2010 # ffffffffc02051b0 <default_pmm_manager+0x4f0>
ffffffffc02029de:	00002617          	auipc	a2,0x2
ffffffffc02029e2:	f3260613          	addi	a2,a2,-206 # ffffffffc0204910 <commands+0x818>
ffffffffc02029e6:	19500593          	li	a1,405
ffffffffc02029ea:	00002517          	auipc	a0,0x2
ffffffffc02029ee:	42650513          	addi	a0,a0,1062 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc02029f2:	a69fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 1);
ffffffffc02029f6:	00003697          	auipc	a3,0x3
ffffffffc02029fa:	8b268693          	addi	a3,a3,-1870 # ffffffffc02052a8 <default_pmm_manager+0x5e8>
ffffffffc02029fe:	00002617          	auipc	a2,0x2
ffffffffc0202a02:	f1260613          	addi	a2,a2,-238 # ffffffffc0204910 <commands+0x818>
ffffffffc0202a06:	1ad00593          	li	a1,429
ffffffffc0202a0a:	00002517          	auipc	a0,0x2
ffffffffc0202a0e:	40650513          	addi	a0,a0,1030 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202a12:	a49fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a16:	00003697          	auipc	a3,0x3
ffffffffc0202a1a:	85268693          	addi	a3,a3,-1966 # ffffffffc0205268 <default_pmm_manager+0x5a8>
ffffffffc0202a1e:	00002617          	auipc	a2,0x2
ffffffffc0202a22:	ef260613          	addi	a2,a2,-270 # ffffffffc0204910 <commands+0x818>
ffffffffc0202a26:	1ac00593          	li	a1,428
ffffffffc0202a2a:	00002517          	auipc	a0,0x2
ffffffffc0202a2e:	3e650513          	addi	a0,a0,998 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202a32:	a29fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a36:	00002697          	auipc	a3,0x2
ffffffffc0202a3a:	70268693          	addi	a3,a3,1794 # ffffffffc0205138 <default_pmm_manager+0x478>
ffffffffc0202a3e:	00002617          	auipc	a2,0x2
ffffffffc0202a42:	ed260613          	addi	a2,a2,-302 # ffffffffc0204910 <commands+0x818>
ffffffffc0202a46:	18700593          	li	a1,391
ffffffffc0202a4a:	00002517          	auipc	a0,0x2
ffffffffc0202a4e:	3c650513          	addi	a0,a0,966 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202a52:	a09fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a56:	00002697          	auipc	a3,0x2
ffffffffc0202a5a:	58268693          	addi	a3,a3,1410 # ffffffffc0204fd8 <default_pmm_manager+0x318>
ffffffffc0202a5e:	00002617          	auipc	a2,0x2
ffffffffc0202a62:	eb260613          	addi	a2,a2,-334 # ffffffffc0204910 <commands+0x818>
ffffffffc0202a66:	18600593          	li	a1,390
ffffffffc0202a6a:	00002517          	auipc	a0,0x2
ffffffffc0202a6e:	3a650513          	addi	a0,a0,934 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202a72:	9e9fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a76:	00002697          	auipc	a3,0x2
ffffffffc0202a7a:	6da68693          	addi	a3,a3,1754 # ffffffffc0205150 <default_pmm_manager+0x490>
ffffffffc0202a7e:	00002617          	auipc	a2,0x2
ffffffffc0202a82:	e9260613          	addi	a2,a2,-366 # ffffffffc0204910 <commands+0x818>
ffffffffc0202a86:	18300593          	li	a1,387
ffffffffc0202a8a:	00002517          	auipc	a0,0x2
ffffffffc0202a8e:	38650513          	addi	a0,a0,902 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202a92:	9c9fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a96:	00002697          	auipc	a3,0x2
ffffffffc0202a9a:	52a68693          	addi	a3,a3,1322 # ffffffffc0204fc0 <default_pmm_manager+0x300>
ffffffffc0202a9e:	00002617          	auipc	a2,0x2
ffffffffc0202aa2:	e7260613          	addi	a2,a2,-398 # ffffffffc0204910 <commands+0x818>
ffffffffc0202aa6:	18200593          	li	a1,386
ffffffffc0202aaa:	00002517          	auipc	a0,0x2
ffffffffc0202aae:	36650513          	addi	a0,a0,870 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202ab2:	9a9fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202ab6:	00002697          	auipc	a3,0x2
ffffffffc0202aba:	5aa68693          	addi	a3,a3,1450 # ffffffffc0205060 <default_pmm_manager+0x3a0>
ffffffffc0202abe:	00002617          	auipc	a2,0x2
ffffffffc0202ac2:	e5260613          	addi	a2,a2,-430 # ffffffffc0204910 <commands+0x818>
ffffffffc0202ac6:	18100593          	li	a1,385
ffffffffc0202aca:	00002517          	auipc	a0,0x2
ffffffffc0202ace:	34650513          	addi	a0,a0,838 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202ad2:	989fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202ad6:	00002697          	auipc	a3,0x2
ffffffffc0202ada:	66268693          	addi	a3,a3,1634 # ffffffffc0205138 <default_pmm_manager+0x478>
ffffffffc0202ade:	00002617          	auipc	a2,0x2
ffffffffc0202ae2:	e3260613          	addi	a2,a2,-462 # ffffffffc0204910 <commands+0x818>
ffffffffc0202ae6:	18000593          	li	a1,384
ffffffffc0202aea:	00002517          	auipc	a0,0x2
ffffffffc0202aee:	32650513          	addi	a0,a0,806 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202af2:	969fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202af6:	00002697          	auipc	a3,0x2
ffffffffc0202afa:	62a68693          	addi	a3,a3,1578 # ffffffffc0205120 <default_pmm_manager+0x460>
ffffffffc0202afe:	00002617          	auipc	a2,0x2
ffffffffc0202b02:	e1260613          	addi	a2,a2,-494 # ffffffffc0204910 <commands+0x818>
ffffffffc0202b06:	17f00593          	li	a1,383
ffffffffc0202b0a:	00002517          	auipc	a0,0x2
ffffffffc0202b0e:	30650513          	addi	a0,a0,774 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202b12:	949fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202b16:	00002697          	auipc	a3,0x2
ffffffffc0202b1a:	5da68693          	addi	a3,a3,1498 # ffffffffc02050f0 <default_pmm_manager+0x430>
ffffffffc0202b1e:	00002617          	auipc	a2,0x2
ffffffffc0202b22:	df260613          	addi	a2,a2,-526 # ffffffffc0204910 <commands+0x818>
ffffffffc0202b26:	17e00593          	li	a1,382
ffffffffc0202b2a:	00002517          	auipc	a0,0x2
ffffffffc0202b2e:	2e650513          	addi	a0,a0,742 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202b32:	929fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202b36:	00002697          	auipc	a3,0x2
ffffffffc0202b3a:	5a268693          	addi	a3,a3,1442 # ffffffffc02050d8 <default_pmm_manager+0x418>
ffffffffc0202b3e:	00002617          	auipc	a2,0x2
ffffffffc0202b42:	dd260613          	addi	a2,a2,-558 # ffffffffc0204910 <commands+0x818>
ffffffffc0202b46:	17c00593          	li	a1,380
ffffffffc0202b4a:	00002517          	auipc	a0,0x2
ffffffffc0202b4e:	2c650513          	addi	a0,a0,710 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202b52:	909fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b56:	00002697          	auipc	a3,0x2
ffffffffc0202b5a:	56268693          	addi	a3,a3,1378 # ffffffffc02050b8 <default_pmm_manager+0x3f8>
ffffffffc0202b5e:	00002617          	auipc	a2,0x2
ffffffffc0202b62:	db260613          	addi	a2,a2,-590 # ffffffffc0204910 <commands+0x818>
ffffffffc0202b66:	17b00593          	li	a1,379
ffffffffc0202b6a:	00002517          	auipc	a0,0x2
ffffffffc0202b6e:	2a650513          	addi	a0,a0,678 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202b72:	8e9fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b76:	00002697          	auipc	a3,0x2
ffffffffc0202b7a:	53268693          	addi	a3,a3,1330 # ffffffffc02050a8 <default_pmm_manager+0x3e8>
ffffffffc0202b7e:	00002617          	auipc	a2,0x2
ffffffffc0202b82:	d9260613          	addi	a2,a2,-622 # ffffffffc0204910 <commands+0x818>
ffffffffc0202b86:	17a00593          	li	a1,378
ffffffffc0202b8a:	00002517          	auipc	a0,0x2
ffffffffc0202b8e:	28650513          	addi	a0,a0,646 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202b92:	8c9fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b96:	00002697          	auipc	a3,0x2
ffffffffc0202b9a:	50268693          	addi	a3,a3,1282 # ffffffffc0205098 <default_pmm_manager+0x3d8>
ffffffffc0202b9e:	00002617          	auipc	a2,0x2
ffffffffc0202ba2:	d7260613          	addi	a2,a2,-654 # ffffffffc0204910 <commands+0x818>
ffffffffc0202ba6:	17900593          	li	a1,377
ffffffffc0202baa:	00002517          	auipc	a0,0x2
ffffffffc0202bae:	26650513          	addi	a0,a0,614 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202bb2:	8a9fd0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("DTB memory info not available");
ffffffffc0202bb6:	00002617          	auipc	a2,0x2
ffffffffc0202bba:	28260613          	addi	a2,a2,642 # ffffffffc0204e38 <default_pmm_manager+0x178>
ffffffffc0202bbe:	06400593          	li	a1,100
ffffffffc0202bc2:	00002517          	auipc	a0,0x2
ffffffffc0202bc6:	24e50513          	addi	a0,a0,590 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202bca:	891fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202bce:	00002697          	auipc	a3,0x2
ffffffffc0202bd2:	5e268693          	addi	a3,a3,1506 # ffffffffc02051b0 <default_pmm_manager+0x4f0>
ffffffffc0202bd6:	00002617          	auipc	a2,0x2
ffffffffc0202bda:	d3a60613          	addi	a2,a2,-710 # ffffffffc0204910 <commands+0x818>
ffffffffc0202bde:	1bf00593          	li	a1,447
ffffffffc0202be2:	00002517          	auipc	a0,0x2
ffffffffc0202be6:	22e50513          	addi	a0,a0,558 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202bea:	871fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202bee:	00002697          	auipc	a3,0x2
ffffffffc0202bf2:	47268693          	addi	a3,a3,1138 # ffffffffc0205060 <default_pmm_manager+0x3a0>
ffffffffc0202bf6:	00002617          	auipc	a2,0x2
ffffffffc0202bfa:	d1a60613          	addi	a2,a2,-742 # ffffffffc0204910 <commands+0x818>
ffffffffc0202bfe:	17800593          	li	a1,376
ffffffffc0202c02:	00002517          	auipc	a0,0x2
ffffffffc0202c06:	20e50513          	addi	a0,a0,526 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202c0a:	851fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202c0e:	00002697          	auipc	a3,0x2
ffffffffc0202c12:	41268693          	addi	a3,a3,1042 # ffffffffc0205020 <default_pmm_manager+0x360>
ffffffffc0202c16:	00002617          	auipc	a2,0x2
ffffffffc0202c1a:	cfa60613          	addi	a2,a2,-774 # ffffffffc0204910 <commands+0x818>
ffffffffc0202c1e:	17700593          	li	a1,375
ffffffffc0202c22:	00002517          	auipc	a0,0x2
ffffffffc0202c26:	1ee50513          	addi	a0,a0,494 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202c2a:	831fd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202c2e:	86d6                	mv	a3,s5
ffffffffc0202c30:	00002617          	auipc	a2,0x2
ffffffffc0202c34:	0c860613          	addi	a2,a2,200 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0202c38:	17300593          	li	a1,371
ffffffffc0202c3c:	00002517          	auipc	a0,0x2
ffffffffc0202c40:	1d450513          	addi	a0,a0,468 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202c44:	817fd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c48:	00002617          	auipc	a2,0x2
ffffffffc0202c4c:	0b060613          	addi	a2,a2,176 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0202c50:	17200593          	li	a1,370
ffffffffc0202c54:	00002517          	auipc	a0,0x2
ffffffffc0202c58:	1bc50513          	addi	a0,a0,444 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202c5c:	ffefd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c60:	00002697          	auipc	a3,0x2
ffffffffc0202c64:	37868693          	addi	a3,a3,888 # ffffffffc0204fd8 <default_pmm_manager+0x318>
ffffffffc0202c68:	00002617          	auipc	a2,0x2
ffffffffc0202c6c:	ca860613          	addi	a2,a2,-856 # ffffffffc0204910 <commands+0x818>
ffffffffc0202c70:	17000593          	li	a1,368
ffffffffc0202c74:	00002517          	auipc	a0,0x2
ffffffffc0202c78:	19c50513          	addi	a0,a0,412 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202c7c:	fdefd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c80:	00002697          	auipc	a3,0x2
ffffffffc0202c84:	34068693          	addi	a3,a3,832 # ffffffffc0204fc0 <default_pmm_manager+0x300>
ffffffffc0202c88:	00002617          	auipc	a2,0x2
ffffffffc0202c8c:	c8860613          	addi	a2,a2,-888 # ffffffffc0204910 <commands+0x818>
ffffffffc0202c90:	16f00593          	li	a1,367
ffffffffc0202c94:	00002517          	auipc	a0,0x2
ffffffffc0202c98:	17c50513          	addi	a0,a0,380 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202c9c:	fbefd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ca0:	00002697          	auipc	a3,0x2
ffffffffc0202ca4:	6d068693          	addi	a3,a3,1744 # ffffffffc0205370 <default_pmm_manager+0x6b0>
ffffffffc0202ca8:	00002617          	auipc	a2,0x2
ffffffffc0202cac:	c6860613          	addi	a2,a2,-920 # ffffffffc0204910 <commands+0x818>
ffffffffc0202cb0:	1b600593          	li	a1,438
ffffffffc0202cb4:	00002517          	auipc	a0,0x2
ffffffffc0202cb8:	15c50513          	addi	a0,a0,348 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202cbc:	f9efd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202cc0:	00002697          	auipc	a3,0x2
ffffffffc0202cc4:	67868693          	addi	a3,a3,1656 # ffffffffc0205338 <default_pmm_manager+0x678>
ffffffffc0202cc8:	00002617          	auipc	a2,0x2
ffffffffc0202ccc:	c4860613          	addi	a2,a2,-952 # ffffffffc0204910 <commands+0x818>
ffffffffc0202cd0:	1b300593          	li	a1,435
ffffffffc0202cd4:	00002517          	auipc	a0,0x2
ffffffffc0202cd8:	13c50513          	addi	a0,a0,316 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202cdc:	f7efd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202ce0:	00002697          	auipc	a3,0x2
ffffffffc0202ce4:	62868693          	addi	a3,a3,1576 # ffffffffc0205308 <default_pmm_manager+0x648>
ffffffffc0202ce8:	00002617          	auipc	a2,0x2
ffffffffc0202cec:	c2860613          	addi	a2,a2,-984 # ffffffffc0204910 <commands+0x818>
ffffffffc0202cf0:	1af00593          	li	a1,431
ffffffffc0202cf4:	00002517          	auipc	a0,0x2
ffffffffc0202cf8:	11c50513          	addi	a0,a0,284 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202cfc:	f5efd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202d00:	00002697          	auipc	a3,0x2
ffffffffc0202d04:	5c068693          	addi	a3,a3,1472 # ffffffffc02052c0 <default_pmm_manager+0x600>
ffffffffc0202d08:	00002617          	auipc	a2,0x2
ffffffffc0202d0c:	c0860613          	addi	a2,a2,-1016 # ffffffffc0204910 <commands+0x818>
ffffffffc0202d10:	1ae00593          	li	a1,430
ffffffffc0202d14:	00002517          	auipc	a0,0x2
ffffffffc0202d18:	0fc50513          	addi	a0,a0,252 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202d1c:	f3efd0ef          	jal	ra,ffffffffc020045a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202d20:	00002617          	auipc	a2,0x2
ffffffffc0202d24:	08060613          	addi	a2,a2,128 # ffffffffc0204da0 <default_pmm_manager+0xe0>
ffffffffc0202d28:	0cb00593          	li	a1,203
ffffffffc0202d2c:	00002517          	auipc	a0,0x2
ffffffffc0202d30:	0e450513          	addi	a0,a0,228 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202d34:	f26fd0ef          	jal	ra,ffffffffc020045a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202d38:	00002617          	auipc	a2,0x2
ffffffffc0202d3c:	06860613          	addi	a2,a2,104 # ffffffffc0204da0 <default_pmm_manager+0xe0>
ffffffffc0202d40:	08000593          	li	a1,128
ffffffffc0202d44:	00002517          	auipc	a0,0x2
ffffffffc0202d48:	0cc50513          	addi	a0,a0,204 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202d4c:	f0efd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d50:	00002697          	auipc	a3,0x2
ffffffffc0202d54:	24068693          	addi	a3,a3,576 # ffffffffc0204f90 <default_pmm_manager+0x2d0>
ffffffffc0202d58:	00002617          	auipc	a2,0x2
ffffffffc0202d5c:	bb860613          	addi	a2,a2,-1096 # ffffffffc0204910 <commands+0x818>
ffffffffc0202d60:	16e00593          	li	a1,366
ffffffffc0202d64:	00002517          	auipc	a0,0x2
ffffffffc0202d68:	0ac50513          	addi	a0,a0,172 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202d6c:	eeefd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d70:	00002697          	auipc	a3,0x2
ffffffffc0202d74:	1f068693          	addi	a3,a3,496 # ffffffffc0204f60 <default_pmm_manager+0x2a0>
ffffffffc0202d78:	00002617          	auipc	a2,0x2
ffffffffc0202d7c:	b9860613          	addi	a2,a2,-1128 # ffffffffc0204910 <commands+0x818>
ffffffffc0202d80:	16b00593          	li	a1,363
ffffffffc0202d84:	00002517          	auipc	a0,0x2
ffffffffc0202d88:	08c50513          	addi	a0,a0,140 # ffffffffc0204e10 <default_pmm_manager+0x150>
ffffffffc0202d8c:	ecefd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202d90 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d90:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202d92:	00002697          	auipc	a3,0x2
ffffffffc0202d96:	62668693          	addi	a3,a3,1574 # ffffffffc02053b8 <default_pmm_manager+0x6f8>
ffffffffc0202d9a:	00002617          	auipc	a2,0x2
ffffffffc0202d9e:	b7660613          	addi	a2,a2,-1162 # ffffffffc0204910 <commands+0x818>
ffffffffc0202da2:	08800593          	li	a1,136
ffffffffc0202da6:	00002517          	auipc	a0,0x2
ffffffffc0202daa:	63250513          	addi	a0,a0,1586 # ffffffffc02053d8 <default_pmm_manager+0x718>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202dae:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202db0:	eaafd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202db4 <find_vma>:
{
ffffffffc0202db4:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202db6:	c505                	beqz	a0,ffffffffc0202dde <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202db8:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202dba:	c501                	beqz	a0,ffffffffc0202dc2 <find_vma+0xe>
ffffffffc0202dbc:	651c                	ld	a5,8(a0)
ffffffffc0202dbe:	02f5f263          	bgeu	a1,a5,ffffffffc0202de2 <find_vma+0x2e>
    return listelm->next;
ffffffffc0202dc2:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202dc4:	00f68d63          	beq	a3,a5,ffffffffc0202dde <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202dc8:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2afc>
ffffffffc0202dcc:	00e5e663          	bltu	a1,a4,ffffffffc0202dd8 <find_vma+0x24>
ffffffffc0202dd0:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202dd4:	00e5ec63          	bltu	a1,a4,ffffffffc0202dec <find_vma+0x38>
ffffffffc0202dd8:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202dda:	fef697e3          	bne	a3,a5,ffffffffc0202dc8 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202dde:	4501                	li	a0,0
}
ffffffffc0202de0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202de2:	691c                	ld	a5,16(a0)
ffffffffc0202de4:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202dc2 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202de8:	ea88                	sd	a0,16(a3)
ffffffffc0202dea:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202dec:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202df0:	ea88                	sd	a0,16(a3)
ffffffffc0202df2:	8082                	ret

ffffffffc0202df4 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202df4:	6590                	ld	a2,8(a1)
ffffffffc0202df6:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202dfa:	1141                	addi	sp,sp,-16
ffffffffc0202dfc:	e406                	sd	ra,8(sp)
ffffffffc0202dfe:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e00:	01066763          	bltu	a2,a6,ffffffffc0202e0e <insert_vma_struct+0x1a>
ffffffffc0202e04:	a085                	j	ffffffffc0202e64 <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e06:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202e0a:	04e66863          	bltu	a2,a4,ffffffffc0202e5a <insert_vma_struct+0x66>
ffffffffc0202e0e:	86be                	mv	a3,a5
ffffffffc0202e10:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202e12:	fef51ae3          	bne	a0,a5,ffffffffc0202e06 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202e16:	02a68463          	beq	a3,a0,ffffffffc0202e3e <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202e1a:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e1e:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202e22:	08e8f163          	bgeu	a7,a4,ffffffffc0202ea4 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e26:	04e66f63          	bltu	a2,a4,ffffffffc0202e84 <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202e2a:	00f50a63          	beq	a0,a5,ffffffffc0202e3e <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202e2e:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e32:	05076963          	bltu	a4,a6,ffffffffc0202e84 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202e36:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202e3a:	02c77363          	bgeu	a4,a2,ffffffffc0202e60 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202e3e:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202e40:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202e42:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e46:	e390                	sd	a2,0(a5)
ffffffffc0202e48:	e690                	sd	a2,8(a3)
}
ffffffffc0202e4a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e4c:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e4e:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e50:	0017079b          	addiw	a5,a4,1
ffffffffc0202e54:	d11c                	sw	a5,32(a0)
}
ffffffffc0202e56:	0141                	addi	sp,sp,16
ffffffffc0202e58:	8082                	ret
    if (le_prev != list)
ffffffffc0202e5a:	fca690e3          	bne	a3,a0,ffffffffc0202e1a <insert_vma_struct+0x26>
ffffffffc0202e5e:	bfd1                	j	ffffffffc0202e32 <insert_vma_struct+0x3e>
ffffffffc0202e60:	f31ff0ef          	jal	ra,ffffffffc0202d90 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e64:	00002697          	auipc	a3,0x2
ffffffffc0202e68:	58468693          	addi	a3,a3,1412 # ffffffffc02053e8 <default_pmm_manager+0x728>
ffffffffc0202e6c:	00002617          	auipc	a2,0x2
ffffffffc0202e70:	aa460613          	addi	a2,a2,-1372 # ffffffffc0204910 <commands+0x818>
ffffffffc0202e74:	08e00593          	li	a1,142
ffffffffc0202e78:	00002517          	auipc	a0,0x2
ffffffffc0202e7c:	56050513          	addi	a0,a0,1376 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0202e80:	ddafd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e84:	00002697          	auipc	a3,0x2
ffffffffc0202e88:	5a468693          	addi	a3,a3,1444 # ffffffffc0205428 <default_pmm_manager+0x768>
ffffffffc0202e8c:	00002617          	auipc	a2,0x2
ffffffffc0202e90:	a8460613          	addi	a2,a2,-1404 # ffffffffc0204910 <commands+0x818>
ffffffffc0202e94:	08700593          	li	a1,135
ffffffffc0202e98:	00002517          	auipc	a0,0x2
ffffffffc0202e9c:	54050513          	addi	a0,a0,1344 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0202ea0:	dbafd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202ea4:	00002697          	auipc	a3,0x2
ffffffffc0202ea8:	56468693          	addi	a3,a3,1380 # ffffffffc0205408 <default_pmm_manager+0x748>
ffffffffc0202eac:	00002617          	auipc	a2,0x2
ffffffffc0202eb0:	a6460613          	addi	a2,a2,-1436 # ffffffffc0204910 <commands+0x818>
ffffffffc0202eb4:	08600593          	li	a1,134
ffffffffc0202eb8:	00002517          	auipc	a0,0x2
ffffffffc0202ebc:	52050513          	addi	a0,a0,1312 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0202ec0:	d9afd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202ec4 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202ec4:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ec6:	03000513          	li	a0,48
{
ffffffffc0202eca:	fc06                	sd	ra,56(sp)
ffffffffc0202ecc:	f822                	sd	s0,48(sp)
ffffffffc0202ece:	f426                	sd	s1,40(sp)
ffffffffc0202ed0:	f04a                	sd	s2,32(sp)
ffffffffc0202ed2:	ec4e                	sd	s3,24(sp)
ffffffffc0202ed4:	e852                	sd	s4,16(sp)
ffffffffc0202ed6:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202ed8:	bd5fe0ef          	jal	ra,ffffffffc0201aac <kmalloc>
    if (mm != NULL)
ffffffffc0202edc:	2e050f63          	beqz	a0,ffffffffc02031da <vmm_init+0x316>
ffffffffc0202ee0:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202ee2:	e508                	sd	a0,8(a0)
ffffffffc0202ee4:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202ee6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202eea:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202eee:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202ef2:	02053423          	sd	zero,40(a0)
ffffffffc0202ef6:	03200413          	li	s0,50
ffffffffc0202efa:	a811                	j	ffffffffc0202f0e <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202efc:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202efe:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f00:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202f04:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f06:	8526                	mv	a0,s1
ffffffffc0202f08:	eedff0ef          	jal	ra,ffffffffc0202df4 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202f0c:	c80d                	beqz	s0,ffffffffc0202f3e <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f0e:	03000513          	li	a0,48
ffffffffc0202f12:	b9bfe0ef          	jal	ra,ffffffffc0201aac <kmalloc>
ffffffffc0202f16:	85aa                	mv	a1,a0
ffffffffc0202f18:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f1c:	f165                	bnez	a0,ffffffffc0202efc <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc0202f1e:	00002697          	auipc	a3,0x2
ffffffffc0202f22:	6a268693          	addi	a3,a3,1698 # ffffffffc02055c0 <default_pmm_manager+0x900>
ffffffffc0202f26:	00002617          	auipc	a2,0x2
ffffffffc0202f2a:	9ea60613          	addi	a2,a2,-1558 # ffffffffc0204910 <commands+0x818>
ffffffffc0202f2e:	0da00593          	li	a1,218
ffffffffc0202f32:	00002517          	auipc	a0,0x2
ffffffffc0202f36:	4a650513          	addi	a0,a0,1190 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0202f3a:	d20fd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202f3e:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f42:	1f900913          	li	s2,505
ffffffffc0202f46:	a819                	j	ffffffffc0202f5c <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc0202f48:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f4a:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f4c:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f50:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f52:	8526                	mv	a0,s1
ffffffffc0202f54:	ea1ff0ef          	jal	ra,ffffffffc0202df4 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f58:	03240a63          	beq	s0,s2,ffffffffc0202f8c <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f5c:	03000513          	li	a0,48
ffffffffc0202f60:	b4dfe0ef          	jal	ra,ffffffffc0201aac <kmalloc>
ffffffffc0202f64:	85aa                	mv	a1,a0
ffffffffc0202f66:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f6a:	fd79                	bnez	a0,ffffffffc0202f48 <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc0202f6c:	00002697          	auipc	a3,0x2
ffffffffc0202f70:	65468693          	addi	a3,a3,1620 # ffffffffc02055c0 <default_pmm_manager+0x900>
ffffffffc0202f74:	00002617          	auipc	a2,0x2
ffffffffc0202f78:	99c60613          	addi	a2,a2,-1636 # ffffffffc0204910 <commands+0x818>
ffffffffc0202f7c:	0e100593          	li	a1,225
ffffffffc0202f80:	00002517          	auipc	a0,0x2
ffffffffc0202f84:	45850513          	addi	a0,a0,1112 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0202f88:	cd2fd0ef          	jal	ra,ffffffffc020045a <__panic>
    return listelm->next;
ffffffffc0202f8c:	649c                	ld	a5,8(s1)
ffffffffc0202f8e:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202f90:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f94:	18f48363          	beq	s1,a5,ffffffffc020311a <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f98:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202f9c:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202fa0:	10d61d63          	bne	a2,a3,ffffffffc02030ba <vmm_init+0x1f6>
ffffffffc0202fa4:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202fa8:	10e69963          	bne	a3,a4,ffffffffc02030ba <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202fac:	0715                	addi	a4,a4,5
ffffffffc0202fae:	679c                	ld	a5,8(a5)
ffffffffc0202fb0:	feb712e3          	bne	a4,a1,ffffffffc0202f94 <vmm_init+0xd0>
ffffffffc0202fb4:	4a1d                	li	s4,7
ffffffffc0202fb6:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fb8:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202fbc:	85a2                	mv	a1,s0
ffffffffc0202fbe:	8526                	mv	a0,s1
ffffffffc0202fc0:	df5ff0ef          	jal	ra,ffffffffc0202db4 <find_vma>
ffffffffc0202fc4:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202fc6:	18050a63          	beqz	a0,ffffffffc020315a <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202fca:	00140593          	addi	a1,s0,1
ffffffffc0202fce:	8526                	mv	a0,s1
ffffffffc0202fd0:	de5ff0ef          	jal	ra,ffffffffc0202db4 <find_vma>
ffffffffc0202fd4:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202fd6:	16050263          	beqz	a0,ffffffffc020313a <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202fda:	85d2                	mv	a1,s4
ffffffffc0202fdc:	8526                	mv	a0,s1
ffffffffc0202fde:	dd7ff0ef          	jal	ra,ffffffffc0202db4 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202fe2:	18051c63          	bnez	a0,ffffffffc020317a <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202fe6:	00340593          	addi	a1,s0,3
ffffffffc0202fea:	8526                	mv	a0,s1
ffffffffc0202fec:	dc9ff0ef          	jal	ra,ffffffffc0202db4 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202ff0:	1c051563          	bnez	a0,ffffffffc02031ba <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202ff4:	00440593          	addi	a1,s0,4
ffffffffc0202ff8:	8526                	mv	a0,s1
ffffffffc0202ffa:	dbbff0ef          	jal	ra,ffffffffc0202db4 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202ffe:	18051e63          	bnez	a0,ffffffffc020319a <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203002:	00893783          	ld	a5,8(s2)
ffffffffc0203006:	0c879a63          	bne	a5,s0,ffffffffc02030da <vmm_init+0x216>
ffffffffc020300a:	01093783          	ld	a5,16(s2)
ffffffffc020300e:	0d479663          	bne	a5,s4,ffffffffc02030da <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203012:	0089b783          	ld	a5,8(s3)
ffffffffc0203016:	0e879263          	bne	a5,s0,ffffffffc02030fa <vmm_init+0x236>
ffffffffc020301a:	0109b783          	ld	a5,16(s3)
ffffffffc020301e:	0d479e63          	bne	a5,s4,ffffffffc02030fa <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203022:	0415                	addi	s0,s0,5
ffffffffc0203024:	0a15                	addi	s4,s4,5
ffffffffc0203026:	f9541be3          	bne	s0,s5,ffffffffc0202fbc <vmm_init+0xf8>
ffffffffc020302a:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc020302c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc020302e:	85a2                	mv	a1,s0
ffffffffc0203030:	8526                	mv	a0,s1
ffffffffc0203032:	d83ff0ef          	jal	ra,ffffffffc0202db4 <find_vma>
ffffffffc0203036:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc020303a:	c90d                	beqz	a0,ffffffffc020306c <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc020303c:	6914                	ld	a3,16(a0)
ffffffffc020303e:	6510                	ld	a2,8(a0)
ffffffffc0203040:	00002517          	auipc	a0,0x2
ffffffffc0203044:	50850513          	addi	a0,a0,1288 # ffffffffc0205548 <default_pmm_manager+0x888>
ffffffffc0203048:	94cfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc020304c:	00002697          	auipc	a3,0x2
ffffffffc0203050:	52468693          	addi	a3,a3,1316 # ffffffffc0205570 <default_pmm_manager+0x8b0>
ffffffffc0203054:	00002617          	auipc	a2,0x2
ffffffffc0203058:	8bc60613          	addi	a2,a2,-1860 # ffffffffc0204910 <commands+0x818>
ffffffffc020305c:	10700593          	li	a1,263
ffffffffc0203060:	00002517          	auipc	a0,0x2
ffffffffc0203064:	37850513          	addi	a0,a0,888 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0203068:	bf2fd0ef          	jal	ra,ffffffffc020045a <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc020306c:	147d                	addi	s0,s0,-1
ffffffffc020306e:	fd2410e3          	bne	s0,s2,ffffffffc020302e <vmm_init+0x16a>
ffffffffc0203072:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc0203074:	00a48c63          	beq	s1,a0,ffffffffc020308c <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203078:	6118                	ld	a4,0(a0)
ffffffffc020307a:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020307c:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020307e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203080:	e398                	sd	a4,0(a5)
ffffffffc0203082:	adbfe0ef          	jal	ra,ffffffffc0201b5c <kfree>
    return listelm->next;
ffffffffc0203086:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc0203088:	fea498e3          	bne	s1,a0,ffffffffc0203078 <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc020308c:	8526                	mv	a0,s1
ffffffffc020308e:	acffe0ef          	jal	ra,ffffffffc0201b5c <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203092:	00002517          	auipc	a0,0x2
ffffffffc0203096:	4f650513          	addi	a0,a0,1270 # ffffffffc0205588 <default_pmm_manager+0x8c8>
ffffffffc020309a:	8fafd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc020309e:	7442                	ld	s0,48(sp)
ffffffffc02030a0:	70e2                	ld	ra,56(sp)
ffffffffc02030a2:	74a2                	ld	s1,40(sp)
ffffffffc02030a4:	7902                	ld	s2,32(sp)
ffffffffc02030a6:	69e2                	ld	s3,24(sp)
ffffffffc02030a8:	6a42                	ld	s4,16(sp)
ffffffffc02030aa:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030ac:	00002517          	auipc	a0,0x2
ffffffffc02030b0:	4fc50513          	addi	a0,a0,1276 # ffffffffc02055a8 <default_pmm_manager+0x8e8>
}
ffffffffc02030b4:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02030b6:	8defd06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02030ba:	00002697          	auipc	a3,0x2
ffffffffc02030be:	3a668693          	addi	a3,a3,934 # ffffffffc0205460 <default_pmm_manager+0x7a0>
ffffffffc02030c2:	00002617          	auipc	a2,0x2
ffffffffc02030c6:	84e60613          	addi	a2,a2,-1970 # ffffffffc0204910 <commands+0x818>
ffffffffc02030ca:	0eb00593          	li	a1,235
ffffffffc02030ce:	00002517          	auipc	a0,0x2
ffffffffc02030d2:	30a50513          	addi	a0,a0,778 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc02030d6:	b84fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc02030da:	00002697          	auipc	a3,0x2
ffffffffc02030de:	40e68693          	addi	a3,a3,1038 # ffffffffc02054e8 <default_pmm_manager+0x828>
ffffffffc02030e2:	00002617          	auipc	a2,0x2
ffffffffc02030e6:	82e60613          	addi	a2,a2,-2002 # ffffffffc0204910 <commands+0x818>
ffffffffc02030ea:	0fc00593          	li	a1,252
ffffffffc02030ee:	00002517          	auipc	a0,0x2
ffffffffc02030f2:	2ea50513          	addi	a0,a0,746 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc02030f6:	b64fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02030fa:	00002697          	auipc	a3,0x2
ffffffffc02030fe:	41e68693          	addi	a3,a3,1054 # ffffffffc0205518 <default_pmm_manager+0x858>
ffffffffc0203102:	00002617          	auipc	a2,0x2
ffffffffc0203106:	80e60613          	addi	a2,a2,-2034 # ffffffffc0204910 <commands+0x818>
ffffffffc020310a:	0fd00593          	li	a1,253
ffffffffc020310e:	00002517          	auipc	a0,0x2
ffffffffc0203112:	2ca50513          	addi	a0,a0,714 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0203116:	b44fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020311a:	00002697          	auipc	a3,0x2
ffffffffc020311e:	32e68693          	addi	a3,a3,814 # ffffffffc0205448 <default_pmm_manager+0x788>
ffffffffc0203122:	00001617          	auipc	a2,0x1
ffffffffc0203126:	7ee60613          	addi	a2,a2,2030 # ffffffffc0204910 <commands+0x818>
ffffffffc020312a:	0e900593          	li	a1,233
ffffffffc020312e:	00002517          	auipc	a0,0x2
ffffffffc0203132:	2aa50513          	addi	a0,a0,682 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0203136:	b24fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2 != NULL);
ffffffffc020313a:	00002697          	auipc	a3,0x2
ffffffffc020313e:	36e68693          	addi	a3,a3,878 # ffffffffc02054a8 <default_pmm_manager+0x7e8>
ffffffffc0203142:	00001617          	auipc	a2,0x1
ffffffffc0203146:	7ce60613          	addi	a2,a2,1998 # ffffffffc0204910 <commands+0x818>
ffffffffc020314a:	0f400593          	li	a1,244
ffffffffc020314e:	00002517          	auipc	a0,0x2
ffffffffc0203152:	28a50513          	addi	a0,a0,650 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0203156:	b04fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1 != NULL);
ffffffffc020315a:	00002697          	auipc	a3,0x2
ffffffffc020315e:	33e68693          	addi	a3,a3,830 # ffffffffc0205498 <default_pmm_manager+0x7d8>
ffffffffc0203162:	00001617          	auipc	a2,0x1
ffffffffc0203166:	7ae60613          	addi	a2,a2,1966 # ffffffffc0204910 <commands+0x818>
ffffffffc020316a:	0f200593          	li	a1,242
ffffffffc020316e:	00002517          	auipc	a0,0x2
ffffffffc0203172:	26a50513          	addi	a0,a0,618 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0203176:	ae4fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma3 == NULL);
ffffffffc020317a:	00002697          	auipc	a3,0x2
ffffffffc020317e:	33e68693          	addi	a3,a3,830 # ffffffffc02054b8 <default_pmm_manager+0x7f8>
ffffffffc0203182:	00001617          	auipc	a2,0x1
ffffffffc0203186:	78e60613          	addi	a2,a2,1934 # ffffffffc0204910 <commands+0x818>
ffffffffc020318a:	0f600593          	li	a1,246
ffffffffc020318e:	00002517          	auipc	a0,0x2
ffffffffc0203192:	24a50513          	addi	a0,a0,586 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc0203196:	ac4fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma5 == NULL);
ffffffffc020319a:	00002697          	auipc	a3,0x2
ffffffffc020319e:	33e68693          	addi	a3,a3,830 # ffffffffc02054d8 <default_pmm_manager+0x818>
ffffffffc02031a2:	00001617          	auipc	a2,0x1
ffffffffc02031a6:	76e60613          	addi	a2,a2,1902 # ffffffffc0204910 <commands+0x818>
ffffffffc02031aa:	0fa00593          	li	a1,250
ffffffffc02031ae:	00002517          	auipc	a0,0x2
ffffffffc02031b2:	22a50513          	addi	a0,a0,554 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc02031b6:	aa4fd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma4 == NULL);
ffffffffc02031ba:	00002697          	auipc	a3,0x2
ffffffffc02031be:	30e68693          	addi	a3,a3,782 # ffffffffc02054c8 <default_pmm_manager+0x808>
ffffffffc02031c2:	00001617          	auipc	a2,0x1
ffffffffc02031c6:	74e60613          	addi	a2,a2,1870 # ffffffffc0204910 <commands+0x818>
ffffffffc02031ca:	0f800593          	li	a1,248
ffffffffc02031ce:	00002517          	auipc	a0,0x2
ffffffffc02031d2:	20a50513          	addi	a0,a0,522 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc02031d6:	a84fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(mm != NULL);
ffffffffc02031da:	00002697          	auipc	a3,0x2
ffffffffc02031de:	3f668693          	addi	a3,a3,1014 # ffffffffc02055d0 <default_pmm_manager+0x910>
ffffffffc02031e2:	00001617          	auipc	a2,0x1
ffffffffc02031e6:	72e60613          	addi	a2,a2,1838 # ffffffffc0204910 <commands+0x818>
ffffffffc02031ea:	0d200593          	li	a1,210
ffffffffc02031ee:	00002517          	auipc	a0,0x2
ffffffffc02031f2:	1ea50513          	addi	a0,a0,490 # ffffffffc02053d8 <default_pmm_manager+0x718>
ffffffffc02031f6:	a64fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02031fa <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02031fa:	8526                	mv	a0,s1
	jalr s0
ffffffffc02031fc:	9402                	jalr	s0

	jal do_exit
ffffffffc02031fe:	3e6000ef          	jal	ra,ffffffffc02035e4 <do_exit>

ffffffffc0203202 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203202:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203204:	0e800513          	li	a0,232
{
ffffffffc0203208:	e022                	sd	s0,0(sp)
ffffffffc020320a:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc020320c:	8a1fe0ef          	jal	ra,ffffffffc0201aac <kmalloc>
ffffffffc0203210:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203212:	c521                	beqz	a0,ffffffffc020325a <alloc_proc+0x58>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;  // 进程状态为未初始化
ffffffffc0203214:	57fd                	li	a5,-1
ffffffffc0203216:	1782                	slli	a5,a5,0x20
ffffffffc0203218:	e11c                	sd	a5,0(a0)
        proc->runs = 0;             // 运行次数初始化为0
        proc->kstack = 0;           // 内核栈地址初始化为0
        proc->need_resched = 0;     // 不需要调度
        proc->parent = NULL;        // 父进程指针为空
        proc->mm = NULL;            // 内存管理结构为空
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
ffffffffc020321a:	07000613          	li	a2,112
ffffffffc020321e:	4581                	li	a1,0
        proc->runs = 0;             // 运行次数初始化为0
ffffffffc0203220:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;           // 内核栈地址初始化为0
ffffffffc0203224:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;     // 不需要调度
ffffffffc0203228:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;        // 父进程指针为空
ffffffffc020322c:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;            // 内存管理结构为空
ffffffffc0203230:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 上下文清零
ffffffffc0203234:	03050513          	addi	a0,a0,48
ffffffffc0203238:	407000ef          	jal	ra,ffffffffc0203e3e <memset>
        proc->tf = NULL;            // 中断帧指针为空
        proc->pgdir = boot_pgdir_pa;         // 页目录表基址为启动页表的物理地址
ffffffffc020323c:	0000a797          	auipc	a5,0xa
ffffffffc0203240:	2647b783          	ld	a5,612(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
        proc->tf = NULL;            // 中断帧指针为空
ffffffffc0203244:	0a043023          	sd	zero,160(s0)
        proc->pgdir = boot_pgdir_pa;         // 页目录表基址为启动页表的物理地址
ffffffffc0203248:	f45c                	sd	a5,168(s0)
        proc->flags = 0;            // 标志位清零
ffffffffc020324a:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN); // 进程名清零
ffffffffc020324e:	463d                	li	a2,15
ffffffffc0203250:	4581                	li	a1,0
ffffffffc0203252:	0b440513          	addi	a0,s0,180
ffffffffc0203256:	3e9000ef          	jal	ra,ffffffffc0203e3e <memset>
        
    }
    return proc;
}
ffffffffc020325a:	60a2                	ld	ra,8(sp)
ffffffffc020325c:	8522                	mv	a0,s0
ffffffffc020325e:	6402                	ld	s0,0(sp)
ffffffffc0203260:	0141                	addi	sp,sp,16
ffffffffc0203262:	8082                	ret

ffffffffc0203264 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203264:	0000a797          	auipc	a5,0xa
ffffffffc0203268:	26c7b783          	ld	a5,620(a5) # ffffffffc020d4d0 <current>
ffffffffc020326c:	73c8                	ld	a0,160(a5)
ffffffffc020326e:	b67fd06f          	j	ffffffffc0200dd4 <forkrets>

ffffffffc0203272 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203272:	7179                	addi	sp,sp,-48
ffffffffc0203274:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc0203276:	0000a497          	auipc	s1,0xa
ffffffffc020327a:	1d248493          	addi	s1,s1,466 # ffffffffc020d448 <name.2>
{
ffffffffc020327e:	f022                	sd	s0,32(sp)
ffffffffc0203280:	e84a                	sd	s2,16(sp)
ffffffffc0203282:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203284:	0000a917          	auipc	s2,0xa
ffffffffc0203288:	24c93903          	ld	s2,588(s2) # ffffffffc020d4d0 <current>
    memset(name, 0, sizeof(name));
ffffffffc020328c:	4641                	li	a2,16
ffffffffc020328e:	4581                	li	a1,0
ffffffffc0203290:	8526                	mv	a0,s1
{
ffffffffc0203292:	f406                	sd	ra,40(sp)
ffffffffc0203294:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203296:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc020329a:	3a5000ef          	jal	ra,ffffffffc0203e3e <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc020329e:	0b490593          	addi	a1,s2,180
ffffffffc02032a2:	463d                	li	a2,15
ffffffffc02032a4:	8526                	mv	a0,s1
ffffffffc02032a6:	3ab000ef          	jal	ra,ffffffffc0203e50 <memcpy>
ffffffffc02032aa:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc02032ac:	85ce                	mv	a1,s3
ffffffffc02032ae:	00002517          	auipc	a0,0x2
ffffffffc02032b2:	33250513          	addi	a0,a0,818 # ffffffffc02055e0 <default_pmm_manager+0x920>
ffffffffc02032b6:	edffc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc02032ba:	85a2                	mv	a1,s0
ffffffffc02032bc:	00002517          	auipc	a0,0x2
ffffffffc02032c0:	34c50513          	addi	a0,a0,844 # ffffffffc0205608 <default_pmm_manager+0x948>
ffffffffc02032c4:	ed1fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc02032c8:	00002517          	auipc	a0,0x2
ffffffffc02032cc:	35050513          	addi	a0,a0,848 # ffffffffc0205618 <default_pmm_manager+0x958>
ffffffffc02032d0:	ec5fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02032d4:	70a2                	ld	ra,40(sp)
ffffffffc02032d6:	7402                	ld	s0,32(sp)
ffffffffc02032d8:	64e2                	ld	s1,24(sp)
ffffffffc02032da:	6942                	ld	s2,16(sp)
ffffffffc02032dc:	69a2                	ld	s3,8(sp)
ffffffffc02032de:	4501                	li	a0,0
ffffffffc02032e0:	6145                	addi	sp,sp,48
ffffffffc02032e2:	8082                	ret

ffffffffc02032e4 <proc_run>:
{
ffffffffc02032e4:	7179                	addi	sp,sp,-48
ffffffffc02032e6:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc02032e8:	0000a497          	auipc	s1,0xa
ffffffffc02032ec:	1e848493          	addi	s1,s1,488 # ffffffffc020d4d0 <current>
ffffffffc02032f0:	6098                	ld	a4,0(s1)
{
ffffffffc02032f2:	f406                	sd	ra,40(sp)
ffffffffc02032f4:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02032f6:	02a70d63          	beq	a4,a0,ffffffffc0203330 <proc_run+0x4c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02032fa:	100027f3          	csrr	a5,sstatus
ffffffffc02032fe:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203300:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203302:	e3b1                	bnez	a5,ffffffffc0203346 <proc_run+0x62>
        proc->runs++;
ffffffffc0203304:	4514                	lw	a3,8(a0)
        lsatp(proc->pgdir);
ffffffffc0203306:	755c                	ld	a5,168(a0)
        current = proc;
ffffffffc0203308:	e088                	sd	a0,0(s1)
        proc->runs++;
ffffffffc020330a:	2685                	addiw	a3,a3,1
ffffffffc020330c:	c514                	sw	a3,8(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc020330e:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc0203312:	800006b7          	lui	a3,0x80000
        proc->need_resched = 0;
ffffffffc0203316:	00052c23          	sw	zero,24(a0)
ffffffffc020331a:	8fd5                	or	a5,a5,a3
ffffffffc020331c:	18079073          	csrw	satp,a5
        switch_to(&prev->context, &proc->context);
ffffffffc0203320:	03050593          	addi	a1,a0,48
ffffffffc0203324:	03070513          	addi	a0,a4,48
ffffffffc0203328:	540000ef          	jal	ra,ffffffffc0203868 <switch_to>
    if (flag) {
ffffffffc020332c:	00091763          	bnez	s2,ffffffffc020333a <proc_run+0x56>
}
ffffffffc0203330:	70a2                	ld	ra,40(sp)
ffffffffc0203332:	7482                	ld	s1,32(sp)
ffffffffc0203334:	6962                	ld	s2,24(sp)
ffffffffc0203336:	6145                	addi	sp,sp,48
ffffffffc0203338:	8082                	ret
ffffffffc020333a:	70a2                	ld	ra,40(sp)
ffffffffc020333c:	7482                	ld	s1,32(sp)
ffffffffc020333e:	6962                	ld	s2,24(sp)
ffffffffc0203340:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203342:	de8fd06f          	j	ffffffffc020092a <intr_enable>
ffffffffc0203346:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203348:	de8fd0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        struct proc_struct *prev = current;
ffffffffc020334c:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc020334e:	6522                	ld	a0,8(sp)
ffffffffc0203350:	4905                	li	s2,1
ffffffffc0203352:	bf4d                	j	ffffffffc0203304 <proc_run+0x20>

ffffffffc0203354 <do_fork>:
{
ffffffffc0203354:	7179                	addi	sp,sp,-48
ffffffffc0203356:	e84a                	sd	s2,16(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203358:	0000a917          	auipc	s2,0xa
ffffffffc020335c:	19090913          	addi	s2,s2,400 # ffffffffc020d4e8 <nr_process>
ffffffffc0203360:	00092703          	lw	a4,0(s2)
{
ffffffffc0203364:	f406                	sd	ra,40(sp)
ffffffffc0203366:	f022                	sd	s0,32(sp)
ffffffffc0203368:	ec26                	sd	s1,24(sp)
ffffffffc020336a:	e44e                	sd	s3,8(sp)
ffffffffc020336c:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020336e:	6785                	lui	a5,0x1
ffffffffc0203370:	1cf75f63          	bge	a4,a5,ffffffffc020354e <do_fork+0x1fa>
ffffffffc0203374:	84ae                	mv	s1,a1
ffffffffc0203376:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc0203378:	e8bff0ef          	jal	ra,ffffffffc0203202 <alloc_proc>
ffffffffc020337c:	89aa                	mv	s3,a0
    if (proc == NULL) {
ffffffffc020337e:	1c050d63          	beqz	a0,ffffffffc0203558 <do_fork+0x204>
    if (++last_pid >= MAX_PID)
ffffffffc0203382:	00006897          	auipc	a7,0x6
ffffffffc0203386:	ca688893          	addi	a7,a7,-858 # ffffffffc0209028 <last_pid.1>
ffffffffc020338a:	0008a783          	lw	a5,0(a7)
    proc->parent = current;
ffffffffc020338e:	0000aa17          	auipc	s4,0xa
ffffffffc0203392:	142a0a13          	addi	s4,s4,322 # ffffffffc020d4d0 <current>
ffffffffc0203396:	000a3703          	ld	a4,0(s4)
    if (++last_pid >= MAX_PID)
ffffffffc020339a:	0017881b          	addiw	a6,a5,1
ffffffffc020339e:	0108a023          	sw	a6,0(a7)
    proc->parent = current;
ffffffffc02033a2:	f118                	sd	a4,32(a0)
    if (++last_pid >= MAX_PID)
ffffffffc02033a4:	6789                	lui	a5,0x2
ffffffffc02033a6:	10f85c63          	bge	a6,a5,ffffffffc02034be <do_fork+0x16a>
    if (last_pid >= next_safe)
ffffffffc02033aa:	00006e17          	auipc	t3,0x6
ffffffffc02033ae:	c82e0e13          	addi	t3,t3,-894 # ffffffffc020902c <next_safe.0>
ffffffffc02033b2:	000e2783          	lw	a5,0(t3)
ffffffffc02033b6:	10f85c63          	bge	a6,a5,ffffffffc02034ce <do_fork+0x17a>
    proc->pid = get_pid();
ffffffffc02033ba:	0109a223          	sw	a6,4(s3)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02033be:	4509                	li	a0,2
ffffffffc02033c0:	8cbfe0ef          	jal	ra,ffffffffc0201c8a <alloc_pages>
    if (page != NULL)
ffffffffc02033c4:	18050063          	beqz	a0,ffffffffc0203544 <do_fork+0x1f0>
    return page - pages + nbase;
ffffffffc02033c8:	0000a697          	auipc	a3,0xa
ffffffffc02033cc:	0f06b683          	ld	a3,240(a3) # ffffffffc020d4b8 <pages>
ffffffffc02033d0:	40d506b3          	sub	a3,a0,a3
ffffffffc02033d4:	8699                	srai	a3,a3,0x6
ffffffffc02033d6:	00002517          	auipc	a0,0x2
ffffffffc02033da:	60253503          	ld	a0,1538(a0) # ffffffffc02059d8 <nbase>
ffffffffc02033de:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02033e0:	00c69793          	slli	a5,a3,0xc
ffffffffc02033e4:	83b1                	srli	a5,a5,0xc
ffffffffc02033e6:	0000a717          	auipc	a4,0xa
ffffffffc02033ea:	0ca73703          	ld	a4,202(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02033ee:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033f0:	18e7f663          	bgeu	a5,a4,ffffffffc020357c <do_fork+0x228>
    assert(current->mm == NULL);
ffffffffc02033f4:	000a3783          	ld	a5,0(s4)
ffffffffc02033f8:	0000a717          	auipc	a4,0xa
ffffffffc02033fc:	0d073703          	ld	a4,208(a4) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0203400:	96ba                	add	a3,a3,a4
ffffffffc0203402:	779c                	ld	a5,40(a5)
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0203404:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL);
ffffffffc0203408:	14079a63          	bnez	a5,ffffffffc020355c <do_fork+0x208>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc020340c:	6789                	lui	a5,0x2
ffffffffc020340e:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc0203412:	96be                	add	a3,a3,a5
ffffffffc0203414:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf;
ffffffffc0203418:	87b6                	mv	a5,a3
ffffffffc020341a:	12040813          	addi	a6,s0,288
ffffffffc020341e:	6008                	ld	a0,0(s0)
ffffffffc0203420:	640c                	ld	a1,8(s0)
ffffffffc0203422:	6810                	ld	a2,16(s0)
ffffffffc0203424:	6c18                	ld	a4,24(s0)
ffffffffc0203426:	e388                	sd	a0,0(a5)
ffffffffc0203428:	e78c                	sd	a1,8(a5)
ffffffffc020342a:	eb90                	sd	a2,16(a5)
ffffffffc020342c:	ef98                	sd	a4,24(a5)
ffffffffc020342e:	02040413          	addi	s0,s0,32
ffffffffc0203432:	02078793          	addi	a5,a5,32
ffffffffc0203436:	ff0414e3          	bne	s0,a6,ffffffffc020341e <do_fork+0xca>
    proc->tf->gpr.a0 = 0;
ffffffffc020343a:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020343e:	c4fd                	beqz	s1,ffffffffc020352c <do_fork+0x1d8>
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203440:	0049a503          	lw	a0,4(s3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203444:	00000797          	auipc	a5,0x0
ffffffffc0203448:	e2078793          	addi	a5,a5,-480 # ffffffffc0203264 <forkret>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020344c:	ea84                	sd	s1,16(a3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020344e:	45a9                	li	a1,10
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203450:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203454:	02d9bc23          	sd	a3,56(s3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203458:	540000ef          	jal	ra,ffffffffc0203998 <hash32>
ffffffffc020345c:	02051793          	slli	a5,a0,0x20
ffffffffc0203460:	00006717          	auipc	a4,0x6
ffffffffc0203464:	fe870713          	addi	a4,a4,-24 # ffffffffc0209448 <hash_list>
ffffffffc0203468:	83f1                	srli	a5,a5,0x1c
ffffffffc020346a:	97ba                	add	a5,a5,a4
    __list_add(elm, listelm, listelm->next);
ffffffffc020346c:	6790                	ld	a2,8(a5)
ffffffffc020346e:	0000a697          	auipc	a3,0xa
ffffffffc0203472:	fea68693          	addi	a3,a3,-22 # ffffffffc020d458 <proc_list>
ffffffffc0203476:	0d898713          	addi	a4,s3,216
    prev->next = next->prev = elm;
ffffffffc020347a:	e218                	sd	a4,0(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020347c:	668c                	ld	a1,8(a3)
    prev->next = next->prev = elm;
ffffffffc020347e:	e798                	sd	a4,8(a5)
    nr_process++;
ffffffffc0203480:	00092703          	lw	a4,0(s2)
    elm->next = next;
ffffffffc0203484:	0ec9b023          	sd	a2,224(s3)
    elm->prev = prev;
ffffffffc0203488:	0cf9bc23          	sd	a5,216(s3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020348c:	0c898613          	addi	a2,s3,200
    prev->next = next->prev = elm;
ffffffffc0203490:	e190                	sd	a2,0(a1)
    nr_process++;
ffffffffc0203492:	0017079b          	addiw	a5,a4,1
    wakeup_proc(proc);
ffffffffc0203496:	854e                	mv	a0,s3
    elm->next = next;
ffffffffc0203498:	0cb9b823          	sd	a1,208(s3)
    elm->prev = prev;
ffffffffc020349c:	0cd9b423          	sd	a3,200(s3)
    prev->next = next->prev = elm;
ffffffffc02034a0:	e690                	sd	a2,8(a3)
    nr_process++;
ffffffffc02034a2:	00f92023          	sw	a5,0(s2)
    wakeup_proc(proc);
ffffffffc02034a6:	42c000ef          	jal	ra,ffffffffc02038d2 <wakeup_proc>
    ret = proc->pid;
ffffffffc02034aa:	0049a503          	lw	a0,4(s3)
}
ffffffffc02034ae:	70a2                	ld	ra,40(sp)
ffffffffc02034b0:	7402                	ld	s0,32(sp)
ffffffffc02034b2:	64e2                	ld	s1,24(sp)
ffffffffc02034b4:	6942                	ld	s2,16(sp)
ffffffffc02034b6:	69a2                	ld	s3,8(sp)
ffffffffc02034b8:	6a02                	ld	s4,0(sp)
ffffffffc02034ba:	6145                	addi	sp,sp,48
ffffffffc02034bc:	8082                	ret
        last_pid = 1;
ffffffffc02034be:	4785                	li	a5,1
ffffffffc02034c0:	00f8a023          	sw	a5,0(a7)
        goto inside;
ffffffffc02034c4:	4805                	li	a6,1
ffffffffc02034c6:	00006e17          	auipc	t3,0x6
ffffffffc02034ca:	b66e0e13          	addi	t3,t3,-1178 # ffffffffc020902c <next_safe.0>
    return listelm->next;
ffffffffc02034ce:	0000a617          	auipc	a2,0xa
ffffffffc02034d2:	f8a60613          	addi	a2,a2,-118 # ffffffffc020d458 <proc_list>
ffffffffc02034d6:	00863e83          	ld	t4,8(a2)
        next_safe = MAX_PID;
ffffffffc02034da:	6789                	lui	a5,0x2
ffffffffc02034dc:	00fe2023          	sw	a5,0(t3)
ffffffffc02034e0:	86c2                	mv	a3,a6
ffffffffc02034e2:	4501                	li	a0,0
        while ((le = list_next(le)) != list)
ffffffffc02034e4:	6f09                	lui	t5,0x2
ffffffffc02034e6:	04ce8a63          	beq	t4,a2,ffffffffc020353a <do_fork+0x1e6>
ffffffffc02034ea:	832a                	mv	t1,a0
ffffffffc02034ec:	87f6                	mv	a5,t4
ffffffffc02034ee:	6589                	lui	a1,0x2
ffffffffc02034f0:	a811                	j	ffffffffc0203504 <do_fork+0x1b0>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034f2:	00e6d663          	bge	a3,a4,ffffffffc02034fe <do_fork+0x1aa>
ffffffffc02034f6:	00b75463          	bge	a4,a1,ffffffffc02034fe <do_fork+0x1aa>
ffffffffc02034fa:	85ba                	mv	a1,a4
ffffffffc02034fc:	4305                	li	t1,1
ffffffffc02034fe:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203500:	00c78d63          	beq	a5,a2,ffffffffc020351a <do_fork+0x1c6>
            if (proc->pid == last_pid)
ffffffffc0203504:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0203508:	fed715e3          	bne	a4,a3,ffffffffc02034f2 <do_fork+0x19e>
                if (++last_pid >= next_safe)
ffffffffc020350c:	2685                	addiw	a3,a3,1
ffffffffc020350e:	02b6d163          	bge	a3,a1,ffffffffc0203530 <do_fork+0x1dc>
ffffffffc0203512:	679c                	ld	a5,8(a5)
ffffffffc0203514:	4505                	li	a0,1
        while ((le = list_next(le)) != list)
ffffffffc0203516:	fec797e3          	bne	a5,a2,ffffffffc0203504 <do_fork+0x1b0>
ffffffffc020351a:	c501                	beqz	a0,ffffffffc0203522 <do_fork+0x1ce>
ffffffffc020351c:	00d8a023          	sw	a3,0(a7)
ffffffffc0203520:	8836                	mv	a6,a3
ffffffffc0203522:	e8030ce3          	beqz	t1,ffffffffc02033ba <do_fork+0x66>
ffffffffc0203526:	00be2023          	sw	a1,0(t3)
ffffffffc020352a:	bd41                	j	ffffffffc02033ba <do_fork+0x66>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020352c:	84b6                	mv	s1,a3
ffffffffc020352e:	bf09                	j	ffffffffc0203440 <do_fork+0xec>
                    if (last_pid >= MAX_PID)
ffffffffc0203530:	01e6c363          	blt	a3,t5,ffffffffc0203536 <do_fork+0x1e2>
                        last_pid = 1;
ffffffffc0203534:	4685                	li	a3,1
                    goto repeat;
ffffffffc0203536:	4505                	li	a0,1
ffffffffc0203538:	b77d                	j	ffffffffc02034e6 <do_fork+0x192>
ffffffffc020353a:	cd01                	beqz	a0,ffffffffc0203552 <do_fork+0x1fe>
ffffffffc020353c:	00d8a023          	sw	a3,0(a7)
    return last_pid;
ffffffffc0203540:	8836                	mv	a6,a3
ffffffffc0203542:	bda5                	j	ffffffffc02033ba <do_fork+0x66>
    kfree(proc);
ffffffffc0203544:	854e                	mv	a0,s3
ffffffffc0203546:	e16fe0ef          	jal	ra,ffffffffc0201b5c <kfree>
    ret = -E_NO_MEM;
ffffffffc020354a:	5571                	li	a0,-4
    goto fork_out;
ffffffffc020354c:	b78d                	j	ffffffffc02034ae <do_fork+0x15a>
    int ret = -E_NO_FREE_PROC;
ffffffffc020354e:	556d                	li	a0,-5
ffffffffc0203550:	bfb9                	j	ffffffffc02034ae <do_fork+0x15a>
    return last_pid;
ffffffffc0203552:	0008a803          	lw	a6,0(a7)
ffffffffc0203556:	b595                	j	ffffffffc02033ba <do_fork+0x66>
    ret = -E_NO_MEM;
ffffffffc0203558:	5571                	li	a0,-4
    return ret;
ffffffffc020355a:	bf91                	j	ffffffffc02034ae <do_fork+0x15a>
    assert(current->mm == NULL);
ffffffffc020355c:	00002697          	auipc	a3,0x2
ffffffffc0203560:	0dc68693          	addi	a3,a3,220 # ffffffffc0205638 <default_pmm_manager+0x978>
ffffffffc0203564:	00001617          	auipc	a2,0x1
ffffffffc0203568:	3ac60613          	addi	a2,a2,940 # ffffffffc0204910 <commands+0x818>
ffffffffc020356c:	12d00593          	li	a1,301
ffffffffc0203570:	00002517          	auipc	a0,0x2
ffffffffc0203574:	0e050513          	addi	a0,a0,224 # ffffffffc0205650 <default_pmm_manager+0x990>
ffffffffc0203578:	ee3fc0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc020357c:	00001617          	auipc	a2,0x1
ffffffffc0203580:	77c60613          	addi	a2,a2,1916 # ffffffffc0204cf8 <default_pmm_manager+0x38>
ffffffffc0203584:	07100593          	li	a1,113
ffffffffc0203588:	00001517          	auipc	a0,0x1
ffffffffc020358c:	79850513          	addi	a0,a0,1944 # ffffffffc0204d20 <default_pmm_manager+0x60>
ffffffffc0203590:	ecbfc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203594 <kernel_thread>:
{
ffffffffc0203594:	7129                	addi	sp,sp,-320
ffffffffc0203596:	fa22                	sd	s0,304(sp)
ffffffffc0203598:	f626                	sd	s1,296(sp)
ffffffffc020359a:	f24a                	sd	s2,288(sp)
ffffffffc020359c:	84ae                	mv	s1,a1
ffffffffc020359e:	892a                	mv	s2,a0
ffffffffc02035a0:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035a2:	4581                	li	a1,0
ffffffffc02035a4:	12000613          	li	a2,288
ffffffffc02035a8:	850a                	mv	a0,sp
{
ffffffffc02035aa:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035ac:	093000ef          	jal	ra,ffffffffc0203e3e <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02035b0:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02035b2:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02035b4:	100027f3          	csrr	a5,sstatus
ffffffffc02035b8:	edd7f793          	andi	a5,a5,-291
ffffffffc02035bc:	1207e793          	ori	a5,a5,288
ffffffffc02035c0:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035c2:	860a                	mv	a2,sp
ffffffffc02035c4:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035c8:	00000797          	auipc	a5,0x0
ffffffffc02035cc:	c3278793          	addi	a5,a5,-974 # ffffffffc02031fa <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035d0:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035d2:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035d4:	d81ff0ef          	jal	ra,ffffffffc0203354 <do_fork>
}
ffffffffc02035d8:	70f2                	ld	ra,312(sp)
ffffffffc02035da:	7452                	ld	s0,304(sp)
ffffffffc02035dc:	74b2                	ld	s1,296(sp)
ffffffffc02035de:	7912                	ld	s2,288(sp)
ffffffffc02035e0:	6131                	addi	sp,sp,320
ffffffffc02035e2:	8082                	ret

ffffffffc02035e4 <do_exit>:
{
ffffffffc02035e4:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc02035e6:	00002617          	auipc	a2,0x2
ffffffffc02035ea:	08260613          	addi	a2,a2,130 # ffffffffc0205668 <default_pmm_manager+0x9a8>
ffffffffc02035ee:	18c00593          	li	a1,396
ffffffffc02035f2:	00002517          	auipc	a0,0x2
ffffffffc02035f6:	05e50513          	addi	a0,a0,94 # ffffffffc0205650 <default_pmm_manager+0x990>
{
ffffffffc02035fa:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc02035fc:	e5ffc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203600 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0203600:	7179                	addi	sp,sp,-48
ffffffffc0203602:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0203604:	0000a797          	auipc	a5,0xa
ffffffffc0203608:	e5478793          	addi	a5,a5,-428 # ffffffffc020d458 <proc_list>
ffffffffc020360c:	f406                	sd	ra,40(sp)
ffffffffc020360e:	f022                	sd	s0,32(sp)
ffffffffc0203610:	e84a                	sd	s2,16(sp)
ffffffffc0203612:	e44e                	sd	s3,8(sp)
ffffffffc0203614:	00006497          	auipc	s1,0x6
ffffffffc0203618:	e3448493          	addi	s1,s1,-460 # ffffffffc0209448 <hash_list>
ffffffffc020361c:	e79c                	sd	a5,8(a5)
ffffffffc020361e:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0203620:	0000a717          	auipc	a4,0xa
ffffffffc0203624:	e2870713          	addi	a4,a4,-472 # ffffffffc020d448 <name.2>
ffffffffc0203628:	87a6                	mv	a5,s1
ffffffffc020362a:	e79c                	sd	a5,8(a5)
ffffffffc020362c:	e39c                	sd	a5,0(a5)
ffffffffc020362e:	07c1                	addi	a5,a5,16
ffffffffc0203630:	fef71de3          	bne	a4,a5,ffffffffc020362a <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0203634:	bcfff0ef          	jal	ra,ffffffffc0203202 <alloc_proc>
ffffffffc0203638:	0000a917          	auipc	s2,0xa
ffffffffc020363c:	ea090913          	addi	s2,s2,-352 # ffffffffc020d4d8 <idleproc>
ffffffffc0203640:	00a93023          	sd	a0,0(s2)
ffffffffc0203644:	18050c63          	beqz	a0,ffffffffc02037dc <proc_init+0x1dc>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203648:	07000513          	li	a0,112
ffffffffc020364c:	c60fe0ef          	jal	ra,ffffffffc0201aac <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203650:	07000613          	li	a2,112
ffffffffc0203654:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc0203656:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203658:	7e6000ef          	jal	ra,ffffffffc0203e3e <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc020365c:	00093503          	ld	a0,0(s2)
ffffffffc0203660:	85a2                	mv	a1,s0
ffffffffc0203662:	07000613          	li	a2,112
ffffffffc0203666:	03050513          	addi	a0,a0,48
ffffffffc020366a:	7fe000ef          	jal	ra,ffffffffc0203e68 <memcmp>
ffffffffc020366e:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203670:	453d                	li	a0,15
ffffffffc0203672:	c3afe0ef          	jal	ra,ffffffffc0201aac <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203676:	463d                	li	a2,15
ffffffffc0203678:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc020367a:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020367c:	7c2000ef          	jal	ra,ffffffffc0203e3e <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc0203680:	00093503          	ld	a0,0(s2)
ffffffffc0203684:	463d                	li	a2,15
ffffffffc0203686:	85a2                	mv	a1,s0
ffffffffc0203688:	0b450513          	addi	a0,a0,180
ffffffffc020368c:	7dc000ef          	jal	ra,ffffffffc0203e68 <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203690:	00093783          	ld	a5,0(s2)
ffffffffc0203694:	0000a717          	auipc	a4,0xa
ffffffffc0203698:	e0c73703          	ld	a4,-500(a4) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc020369c:	77d4                	ld	a3,168(a5)
ffffffffc020369e:	0ee68363          	beq	a3,a4,ffffffffc0203784 <proc_init+0x184>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02036a2:	4709                	li	a4,2
ffffffffc02036a4:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036a6:	00003717          	auipc	a4,0x3
ffffffffc02036aa:	95a70713          	addi	a4,a4,-1702 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036ae:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036b2:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02036b4:	4705                	li	a4,1
ffffffffc02036b6:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036b8:	4641                	li	a2,16
ffffffffc02036ba:	4581                	li	a1,0
ffffffffc02036bc:	8522                	mv	a0,s0
ffffffffc02036be:	780000ef          	jal	ra,ffffffffc0203e3e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02036c2:	463d                	li	a2,15
ffffffffc02036c4:	00002597          	auipc	a1,0x2
ffffffffc02036c8:	fec58593          	addi	a1,a1,-20 # ffffffffc02056b0 <default_pmm_manager+0x9f0>
ffffffffc02036cc:	8522                	mv	a0,s0
ffffffffc02036ce:	782000ef          	jal	ra,ffffffffc0203e50 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc02036d2:	0000a717          	auipc	a4,0xa
ffffffffc02036d6:	e1670713          	addi	a4,a4,-490 # ffffffffc020d4e8 <nr_process>
ffffffffc02036da:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc02036dc:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036e0:	4601                	li	a2,0
    nr_process++;
ffffffffc02036e2:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036e4:	00002597          	auipc	a1,0x2
ffffffffc02036e8:	fd458593          	addi	a1,a1,-44 # ffffffffc02056b8 <default_pmm_manager+0x9f8>
ffffffffc02036ec:	00000517          	auipc	a0,0x0
ffffffffc02036f0:	b8650513          	addi	a0,a0,-1146 # ffffffffc0203272 <init_main>
    nr_process++;
ffffffffc02036f4:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc02036f6:	0000a797          	auipc	a5,0xa
ffffffffc02036fa:	dcd7bd23          	sd	a3,-550(a5) # ffffffffc020d4d0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036fe:	e97ff0ef          	jal	ra,ffffffffc0203594 <kernel_thread>
ffffffffc0203702:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203704:	0ea05863          	blez	a0,ffffffffc02037f4 <proc_init+0x1f4>
    if (0 < pid && pid < MAX_PID)
ffffffffc0203708:	6789                	lui	a5,0x2
ffffffffc020370a:	fff5071b          	addiw	a4,a0,-1
ffffffffc020370e:	17f9                	addi	a5,a5,-2
ffffffffc0203710:	2501                	sext.w	a0,a0
ffffffffc0203712:	02e7e263          	bltu	a5,a4,ffffffffc0203736 <proc_init+0x136>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203716:	45a9                	li	a1,10
ffffffffc0203718:	280000ef          	jal	ra,ffffffffc0203998 <hash32>
ffffffffc020371c:	02051693          	slli	a3,a0,0x20
ffffffffc0203720:	82f1                	srli	a3,a3,0x1c
ffffffffc0203722:	96a6                	add	a3,a3,s1
ffffffffc0203724:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0203726:	a029                	j	ffffffffc0203730 <proc_init+0x130>
            if (proc->pid == pid)
ffffffffc0203728:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc020372c:	0a870563          	beq	a4,s0,ffffffffc02037d6 <proc_init+0x1d6>
    return listelm->next;
ffffffffc0203730:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203732:	fef69be3          	bne	a3,a5,ffffffffc0203728 <proc_init+0x128>
    return NULL;
ffffffffc0203736:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203738:	0b478493          	addi	s1,a5,180
ffffffffc020373c:	4641                	li	a2,16
ffffffffc020373e:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203740:	0000a417          	auipc	s0,0xa
ffffffffc0203744:	da040413          	addi	s0,s0,-608 # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203748:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020374a:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020374c:	6f2000ef          	jal	ra,ffffffffc0203e3e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203750:	463d                	li	a2,15
ffffffffc0203752:	00002597          	auipc	a1,0x2
ffffffffc0203756:	f9658593          	addi	a1,a1,-106 # ffffffffc02056e8 <default_pmm_manager+0xa28>
ffffffffc020375a:	8526                	mv	a0,s1
ffffffffc020375c:	6f4000ef          	jal	ra,ffffffffc0203e50 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203760:	00093783          	ld	a5,0(s2)
ffffffffc0203764:	c7e1                	beqz	a5,ffffffffc020382c <proc_init+0x22c>
ffffffffc0203766:	43dc                	lw	a5,4(a5)
ffffffffc0203768:	e3f1                	bnez	a5,ffffffffc020382c <proc_init+0x22c>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020376a:	601c                	ld	a5,0(s0)
ffffffffc020376c:	c3c5                	beqz	a5,ffffffffc020380c <proc_init+0x20c>
ffffffffc020376e:	43d8                	lw	a4,4(a5)
ffffffffc0203770:	4785                	li	a5,1
ffffffffc0203772:	08f71d63          	bne	a4,a5,ffffffffc020380c <proc_init+0x20c>
}
ffffffffc0203776:	70a2                	ld	ra,40(sp)
ffffffffc0203778:	7402                	ld	s0,32(sp)
ffffffffc020377a:	64e2                	ld	s1,24(sp)
ffffffffc020377c:	6942                	ld	s2,16(sp)
ffffffffc020377e:	69a2                	ld	s3,8(sp)
ffffffffc0203780:	6145                	addi	sp,sp,48
ffffffffc0203782:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203784:	73d8                	ld	a4,160(a5)
ffffffffc0203786:	ff11                	bnez	a4,ffffffffc02036a2 <proc_init+0xa2>
ffffffffc0203788:	f0099de3          	bnez	s3,ffffffffc02036a2 <proc_init+0xa2>
ffffffffc020378c:	6394                	ld	a3,0(a5)
ffffffffc020378e:	577d                	li	a4,-1
ffffffffc0203790:	1702                	slli	a4,a4,0x20
ffffffffc0203792:	f0e698e3          	bne	a3,a4,ffffffffc02036a2 <proc_init+0xa2>
ffffffffc0203796:	4798                	lw	a4,8(a5)
ffffffffc0203798:	f00715e3          	bnez	a4,ffffffffc02036a2 <proc_init+0xa2>
ffffffffc020379c:	6b98                	ld	a4,16(a5)
ffffffffc020379e:	f00712e3          	bnez	a4,ffffffffc02036a2 <proc_init+0xa2>
ffffffffc02037a2:	4f98                	lw	a4,24(a5)
ffffffffc02037a4:	2701                	sext.w	a4,a4
ffffffffc02037a6:	ee071ee3          	bnez	a4,ffffffffc02036a2 <proc_init+0xa2>
ffffffffc02037aa:	7398                	ld	a4,32(a5)
ffffffffc02037ac:	ee071be3          	bnez	a4,ffffffffc02036a2 <proc_init+0xa2>
ffffffffc02037b0:	7798                	ld	a4,40(a5)
ffffffffc02037b2:	ee0718e3          	bnez	a4,ffffffffc02036a2 <proc_init+0xa2>
ffffffffc02037b6:	0b07a703          	lw	a4,176(a5)
ffffffffc02037ba:	8d59                	or	a0,a0,a4
ffffffffc02037bc:	0005071b          	sext.w	a4,a0
ffffffffc02037c0:	ee0711e3          	bnez	a4,ffffffffc02036a2 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc02037c4:	00002517          	auipc	a0,0x2
ffffffffc02037c8:	ed450513          	addi	a0,a0,-300 # ffffffffc0205698 <default_pmm_manager+0x9d8>
ffffffffc02037cc:	9c9fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc02037d0:	00093783          	ld	a5,0(s2)
ffffffffc02037d4:	b5f9                	j	ffffffffc02036a2 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02037d6:	f2878793          	addi	a5,a5,-216
ffffffffc02037da:	bfb9                	j	ffffffffc0203738 <proc_init+0x138>
        panic("cannot alloc idleproc.\n");
ffffffffc02037dc:	00002617          	auipc	a2,0x2
ffffffffc02037e0:	ea460613          	addi	a2,a2,-348 # ffffffffc0205680 <default_pmm_manager+0x9c0>
ffffffffc02037e4:	1a700593          	li	a1,423
ffffffffc02037e8:	00002517          	auipc	a0,0x2
ffffffffc02037ec:	e6850513          	addi	a0,a0,-408 # ffffffffc0205650 <default_pmm_manager+0x990>
ffffffffc02037f0:	c6bfc0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("create init_main failed.\n");
ffffffffc02037f4:	00002617          	auipc	a2,0x2
ffffffffc02037f8:	ed460613          	addi	a2,a2,-300 # ffffffffc02056c8 <default_pmm_manager+0xa08>
ffffffffc02037fc:	1c400593          	li	a1,452
ffffffffc0203800:	00002517          	auipc	a0,0x2
ffffffffc0203804:	e5050513          	addi	a0,a0,-432 # ffffffffc0205650 <default_pmm_manager+0x990>
ffffffffc0203808:	c53fc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020380c:	00002697          	auipc	a3,0x2
ffffffffc0203810:	f0c68693          	addi	a3,a3,-244 # ffffffffc0205718 <default_pmm_manager+0xa58>
ffffffffc0203814:	00001617          	auipc	a2,0x1
ffffffffc0203818:	0fc60613          	addi	a2,a2,252 # ffffffffc0204910 <commands+0x818>
ffffffffc020381c:	1cb00593          	li	a1,459
ffffffffc0203820:	00002517          	auipc	a0,0x2
ffffffffc0203824:	e3050513          	addi	a0,a0,-464 # ffffffffc0205650 <default_pmm_manager+0x990>
ffffffffc0203828:	c33fc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020382c:	00002697          	auipc	a3,0x2
ffffffffc0203830:	ec468693          	addi	a3,a3,-316 # ffffffffc02056f0 <default_pmm_manager+0xa30>
ffffffffc0203834:	00001617          	auipc	a2,0x1
ffffffffc0203838:	0dc60613          	addi	a2,a2,220 # ffffffffc0204910 <commands+0x818>
ffffffffc020383c:	1ca00593          	li	a1,458
ffffffffc0203840:	00002517          	auipc	a0,0x2
ffffffffc0203844:	e1050513          	addi	a0,a0,-496 # ffffffffc0205650 <default_pmm_manager+0x990>
ffffffffc0203848:	c13fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020384c <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020384c:	1141                	addi	sp,sp,-16
ffffffffc020384e:	e022                	sd	s0,0(sp)
ffffffffc0203850:	e406                	sd	ra,8(sp)
ffffffffc0203852:	0000a417          	auipc	s0,0xa
ffffffffc0203856:	c7e40413          	addi	s0,s0,-898 # ffffffffc020d4d0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020385a:	6018                	ld	a4,0(s0)
ffffffffc020385c:	4f1c                	lw	a5,24(a4)
ffffffffc020385e:	2781                	sext.w	a5,a5
ffffffffc0203860:	dff5                	beqz	a5,ffffffffc020385c <cpu_idle+0x10>
        {
            schedule();
ffffffffc0203862:	0a2000ef          	jal	ra,ffffffffc0203904 <schedule>
ffffffffc0203866:	bfd5                	j	ffffffffc020385a <cpu_idle+0xe>

ffffffffc0203868 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0203868:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020386c:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0203870:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0203872:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0203874:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0203878:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020387c:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203880:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0203884:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0203888:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020388c:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203890:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0203894:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0203898:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020389c:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02038a0:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02038a4:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02038a6:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02038a8:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02038ac:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02038b0:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02038b4:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02038b8:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02038bc:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02038c0:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02038c4:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02038c8:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02038cc:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02038d0:	8082                	ret

ffffffffc02038d2 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038d2:	411c                	lw	a5,0(a0)
ffffffffc02038d4:	4705                	li	a4,1
ffffffffc02038d6:	37f9                	addiw	a5,a5,-2
ffffffffc02038d8:	00f77563          	bgeu	a4,a5,ffffffffc02038e2 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc02038dc:	4789                	li	a5,2
ffffffffc02038de:	c11c                	sw	a5,0(a0)
ffffffffc02038e0:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038e2:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038e4:	00002697          	auipc	a3,0x2
ffffffffc02038e8:	e5c68693          	addi	a3,a3,-420 # ffffffffc0205740 <default_pmm_manager+0xa80>
ffffffffc02038ec:	00001617          	auipc	a2,0x1
ffffffffc02038f0:	02460613          	addi	a2,a2,36 # ffffffffc0204910 <commands+0x818>
ffffffffc02038f4:	45a5                	li	a1,9
ffffffffc02038f6:	00002517          	auipc	a0,0x2
ffffffffc02038fa:	e8a50513          	addi	a0,a0,-374 # ffffffffc0205780 <default_pmm_manager+0xac0>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038fe:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203900:	b5bfc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203904 <schedule>:
}

void
schedule(void) {
ffffffffc0203904:	1141                	addi	sp,sp,-16
ffffffffc0203906:	e406                	sd	ra,8(sp)
ffffffffc0203908:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020390a:	100027f3          	csrr	a5,sstatus
ffffffffc020390e:	8b89                	andi	a5,a5,2
ffffffffc0203910:	4401                	li	s0,0
ffffffffc0203912:	efbd                	bnez	a5,ffffffffc0203990 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0203914:	0000a897          	auipc	a7,0xa
ffffffffc0203918:	bbc8b883          	ld	a7,-1092(a7) # ffffffffc020d4d0 <current>
ffffffffc020391c:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203920:	0000a517          	auipc	a0,0xa
ffffffffc0203924:	bb853503          	ld	a0,-1096(a0) # ffffffffc020d4d8 <idleproc>
ffffffffc0203928:	04a88e63          	beq	a7,a0,ffffffffc0203984 <schedule+0x80>
ffffffffc020392c:	0c888693          	addi	a3,a7,200
ffffffffc0203930:	0000a617          	auipc	a2,0xa
ffffffffc0203934:	b2860613          	addi	a2,a2,-1240 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc0203938:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020393a:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc020393c:	4809                	li	a6,2
ffffffffc020393e:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203940:	00c78863          	beq	a5,a2,ffffffffc0203950 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203944:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0203948:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc020394c:	03070163          	beq	a4,a6,ffffffffc020396e <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203950:	fef697e3          	bne	a3,a5,ffffffffc020393e <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203954:	ed89                	bnez	a1,ffffffffc020396e <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0203956:	451c                	lw	a5,8(a0)
ffffffffc0203958:	2785                	addiw	a5,a5,1
ffffffffc020395a:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc020395c:	00a88463          	beq	a7,a0,ffffffffc0203964 <schedule+0x60>
            proc_run(next);
ffffffffc0203960:	985ff0ef          	jal	ra,ffffffffc02032e4 <proc_run>
    if (flag) {
ffffffffc0203964:	e819                	bnez	s0,ffffffffc020397a <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0203966:	60a2                	ld	ra,8(sp)
ffffffffc0203968:	6402                	ld	s0,0(sp)
ffffffffc020396a:	0141                	addi	sp,sp,16
ffffffffc020396c:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020396e:	4198                	lw	a4,0(a1)
ffffffffc0203970:	4789                	li	a5,2
ffffffffc0203972:	fef712e3          	bne	a4,a5,ffffffffc0203956 <schedule+0x52>
ffffffffc0203976:	852e                	mv	a0,a1
ffffffffc0203978:	bff9                	j	ffffffffc0203956 <schedule+0x52>
}
ffffffffc020397a:	6402                	ld	s0,0(sp)
ffffffffc020397c:	60a2                	ld	ra,8(sp)
ffffffffc020397e:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0203980:	fabfc06f          	j	ffffffffc020092a <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203984:	0000a617          	auipc	a2,0xa
ffffffffc0203988:	ad460613          	addi	a2,a2,-1324 # ffffffffc020d458 <proc_list>
ffffffffc020398c:	86b2                	mv	a3,a2
ffffffffc020398e:	b76d                	j	ffffffffc0203938 <schedule+0x34>
        intr_disable();
ffffffffc0203990:	fa1fc0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0203994:	4405                	li	s0,1
ffffffffc0203996:	bfbd                	j	ffffffffc0203914 <schedule+0x10>

ffffffffc0203998 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203998:	9e3707b7          	lui	a5,0x9e370
ffffffffc020399c:	2785                	addiw	a5,a5,1
ffffffffc020399e:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02039a2:	02000793          	li	a5,32
ffffffffc02039a6:	9f8d                	subw	a5,a5,a1
}
ffffffffc02039a8:	00f5553b          	srlw	a0,a0,a5
ffffffffc02039ac:	8082                	ret

ffffffffc02039ae <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02039ae:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039b2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02039b4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039b8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02039ba:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039be:	f022                	sd	s0,32(sp)
ffffffffc02039c0:	ec26                	sd	s1,24(sp)
ffffffffc02039c2:	e84a                	sd	s2,16(sp)
ffffffffc02039c4:	f406                	sd	ra,40(sp)
ffffffffc02039c6:	e44e                	sd	s3,8(sp)
ffffffffc02039c8:	84aa                	mv	s1,a0
ffffffffc02039ca:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02039cc:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02039d0:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02039d2:	03067e63          	bgeu	a2,a6,ffffffffc0203a0e <printnum+0x60>
ffffffffc02039d6:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02039d8:	00805763          	blez	s0,ffffffffc02039e6 <printnum+0x38>
ffffffffc02039dc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02039de:	85ca                	mv	a1,s2
ffffffffc02039e0:	854e                	mv	a0,s3
ffffffffc02039e2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02039e4:	fc65                	bnez	s0,ffffffffc02039dc <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039e6:	1a02                	slli	s4,s4,0x20
ffffffffc02039e8:	00002797          	auipc	a5,0x2
ffffffffc02039ec:	db078793          	addi	a5,a5,-592 # ffffffffc0205798 <default_pmm_manager+0xad8>
ffffffffc02039f0:	020a5a13          	srli	s4,s4,0x20
ffffffffc02039f4:	9a3e                	add	s4,s4,a5
}
ffffffffc02039f6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039f8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02039fc:	70a2                	ld	ra,40(sp)
ffffffffc02039fe:	69a2                	ld	s3,8(sp)
ffffffffc0203a00:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a02:	85ca                	mv	a1,s2
ffffffffc0203a04:	87a6                	mv	a5,s1
}
ffffffffc0203a06:	6942                	ld	s2,16(sp)
ffffffffc0203a08:	64e2                	ld	s1,24(sp)
ffffffffc0203a0a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a0c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a0e:	03065633          	divu	a2,a2,a6
ffffffffc0203a12:	8722                	mv	a4,s0
ffffffffc0203a14:	f9bff0ef          	jal	ra,ffffffffc02039ae <printnum>
ffffffffc0203a18:	b7f9                	j	ffffffffc02039e6 <printnum+0x38>

ffffffffc0203a1a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a1a:	7119                	addi	sp,sp,-128
ffffffffc0203a1c:	f4a6                	sd	s1,104(sp)
ffffffffc0203a1e:	f0ca                	sd	s2,96(sp)
ffffffffc0203a20:	ecce                	sd	s3,88(sp)
ffffffffc0203a22:	e8d2                	sd	s4,80(sp)
ffffffffc0203a24:	e4d6                	sd	s5,72(sp)
ffffffffc0203a26:	e0da                	sd	s6,64(sp)
ffffffffc0203a28:	fc5e                	sd	s7,56(sp)
ffffffffc0203a2a:	f06a                	sd	s10,32(sp)
ffffffffc0203a2c:	fc86                	sd	ra,120(sp)
ffffffffc0203a2e:	f8a2                	sd	s0,112(sp)
ffffffffc0203a30:	f862                	sd	s8,48(sp)
ffffffffc0203a32:	f466                	sd	s9,40(sp)
ffffffffc0203a34:	ec6e                	sd	s11,24(sp)
ffffffffc0203a36:	892a                	mv	s2,a0
ffffffffc0203a38:	84ae                	mv	s1,a1
ffffffffc0203a3a:	8d32                	mv	s10,a2
ffffffffc0203a3c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a3e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203a42:	5b7d                	li	s6,-1
ffffffffc0203a44:	00002a97          	auipc	s5,0x2
ffffffffc0203a48:	d80a8a93          	addi	s5,s5,-640 # ffffffffc02057c4 <default_pmm_manager+0xb04>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203a4c:	00002b97          	auipc	s7,0x2
ffffffffc0203a50:	f54b8b93          	addi	s7,s7,-172 # ffffffffc02059a0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a54:	000d4503          	lbu	a0,0(s10)
ffffffffc0203a58:	001d0413          	addi	s0,s10,1
ffffffffc0203a5c:	01350a63          	beq	a0,s3,ffffffffc0203a70 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203a60:	c121                	beqz	a0,ffffffffc0203aa0 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203a62:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a64:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203a66:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a68:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203a6c:	ff351ae3          	bne	a0,s3,ffffffffc0203a60 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a70:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203a74:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203a78:	4c81                	li	s9,0
ffffffffc0203a7a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203a7c:	5c7d                	li	s8,-1
ffffffffc0203a7e:	5dfd                	li	s11,-1
ffffffffc0203a80:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203a84:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a86:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203a8a:	0ff5f593          	andi	a1,a1,255
ffffffffc0203a8e:	00140d13          	addi	s10,s0,1
ffffffffc0203a92:	04b56263          	bltu	a0,a1,ffffffffc0203ad6 <vprintfmt+0xbc>
ffffffffc0203a96:	058a                	slli	a1,a1,0x2
ffffffffc0203a98:	95d6                	add	a1,a1,s5
ffffffffc0203a9a:	4194                	lw	a3,0(a1)
ffffffffc0203a9c:	96d6                	add	a3,a3,s5
ffffffffc0203a9e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203aa0:	70e6                	ld	ra,120(sp)
ffffffffc0203aa2:	7446                	ld	s0,112(sp)
ffffffffc0203aa4:	74a6                	ld	s1,104(sp)
ffffffffc0203aa6:	7906                	ld	s2,96(sp)
ffffffffc0203aa8:	69e6                	ld	s3,88(sp)
ffffffffc0203aaa:	6a46                	ld	s4,80(sp)
ffffffffc0203aac:	6aa6                	ld	s5,72(sp)
ffffffffc0203aae:	6b06                	ld	s6,64(sp)
ffffffffc0203ab0:	7be2                	ld	s7,56(sp)
ffffffffc0203ab2:	7c42                	ld	s8,48(sp)
ffffffffc0203ab4:	7ca2                	ld	s9,40(sp)
ffffffffc0203ab6:	7d02                	ld	s10,32(sp)
ffffffffc0203ab8:	6de2                	ld	s11,24(sp)
ffffffffc0203aba:	6109                	addi	sp,sp,128
ffffffffc0203abc:	8082                	ret
            padc = '0';
ffffffffc0203abe:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203ac0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ac4:	846a                	mv	s0,s10
ffffffffc0203ac6:	00140d13          	addi	s10,s0,1
ffffffffc0203aca:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203ace:	0ff5f593          	andi	a1,a1,255
ffffffffc0203ad2:	fcb572e3          	bgeu	a0,a1,ffffffffc0203a96 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203ad6:	85a6                	mv	a1,s1
ffffffffc0203ad8:	02500513          	li	a0,37
ffffffffc0203adc:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203ade:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203ae2:	8d22                	mv	s10,s0
ffffffffc0203ae4:	f73788e3          	beq	a5,s3,ffffffffc0203a54 <vprintfmt+0x3a>
ffffffffc0203ae8:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203aec:	1d7d                	addi	s10,s10,-1
ffffffffc0203aee:	ff379de3          	bne	a5,s3,ffffffffc0203ae8 <vprintfmt+0xce>
ffffffffc0203af2:	b78d                	j	ffffffffc0203a54 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203af4:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203af8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203afc:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203afe:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203b02:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b06:	02d86463          	bltu	a6,a3,ffffffffc0203b2e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203b0a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b0e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203b12:	0186873b          	addw	a4,a3,s8
ffffffffc0203b16:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203b1a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203b1c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203b20:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203b22:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203b26:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b2a:	fed870e3          	bgeu	a6,a3,ffffffffc0203b0a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203b2e:	f40ddce3          	bgez	s11,ffffffffc0203a86 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203b32:	8de2                	mv	s11,s8
ffffffffc0203b34:	5c7d                	li	s8,-1
ffffffffc0203b36:	bf81                	j	ffffffffc0203a86 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203b38:	fffdc693          	not	a3,s11
ffffffffc0203b3c:	96fd                	srai	a3,a3,0x3f
ffffffffc0203b3e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b42:	00144603          	lbu	a2,1(s0)
ffffffffc0203b46:	2d81                	sext.w	s11,s11
ffffffffc0203b48:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203b4a:	bf35                	j	ffffffffc0203a86 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203b4c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b50:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203b54:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b56:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203b58:	bfd9                	j	ffffffffc0203b2e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203b5a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b5c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b60:	01174463          	blt	a4,a7,ffffffffc0203b68 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203b64:	1a088e63          	beqz	a7,ffffffffc0203d20 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203b68:	000a3603          	ld	a2,0(s4)
ffffffffc0203b6c:	46c1                	li	a3,16
ffffffffc0203b6e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203b70:	2781                	sext.w	a5,a5
ffffffffc0203b72:	876e                	mv	a4,s11
ffffffffc0203b74:	85a6                	mv	a1,s1
ffffffffc0203b76:	854a                	mv	a0,s2
ffffffffc0203b78:	e37ff0ef          	jal	ra,ffffffffc02039ae <printnum>
            break;
ffffffffc0203b7c:	bde1                	j	ffffffffc0203a54 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203b7e:	000a2503          	lw	a0,0(s4)
ffffffffc0203b82:	85a6                	mv	a1,s1
ffffffffc0203b84:	0a21                	addi	s4,s4,8
ffffffffc0203b86:	9902                	jalr	s2
            break;
ffffffffc0203b88:	b5f1                	j	ffffffffc0203a54 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203b8a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b8c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b90:	01174463          	blt	a4,a7,ffffffffc0203b98 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203b94:	18088163          	beqz	a7,ffffffffc0203d16 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203b98:	000a3603          	ld	a2,0(s4)
ffffffffc0203b9c:	46a9                	li	a3,10
ffffffffc0203b9e:	8a2e                	mv	s4,a1
ffffffffc0203ba0:	bfc1                	j	ffffffffc0203b70 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ba2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203ba6:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ba8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203baa:	bdf1                	j	ffffffffc0203a86 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203bac:	85a6                	mv	a1,s1
ffffffffc0203bae:	02500513          	li	a0,37
ffffffffc0203bb2:	9902                	jalr	s2
            break;
ffffffffc0203bb4:	b545                	j	ffffffffc0203a54 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bb6:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203bba:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bbc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203bbe:	b5e1                	j	ffffffffc0203a86 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203bc0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bc2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203bc6:	01174463          	blt	a4,a7,ffffffffc0203bce <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203bca:	14088163          	beqz	a7,ffffffffc0203d0c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203bce:	000a3603          	ld	a2,0(s4)
ffffffffc0203bd2:	46a1                	li	a3,8
ffffffffc0203bd4:	8a2e                	mv	s4,a1
ffffffffc0203bd6:	bf69                	j	ffffffffc0203b70 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203bd8:	03000513          	li	a0,48
ffffffffc0203bdc:	85a6                	mv	a1,s1
ffffffffc0203bde:	e03e                	sd	a5,0(sp)
ffffffffc0203be0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203be2:	85a6                	mv	a1,s1
ffffffffc0203be4:	07800513          	li	a0,120
ffffffffc0203be8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203bea:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203bec:	6782                	ld	a5,0(sp)
ffffffffc0203bee:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203bf0:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203bf4:	bfb5                	j	ffffffffc0203b70 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203bf6:	000a3403          	ld	s0,0(s4)
ffffffffc0203bfa:	008a0713          	addi	a4,s4,8
ffffffffc0203bfe:	e03a                	sd	a4,0(sp)
ffffffffc0203c00:	14040263          	beqz	s0,ffffffffc0203d44 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203c04:	0fb05763          	blez	s11,ffffffffc0203cf2 <vprintfmt+0x2d8>
ffffffffc0203c08:	02d00693          	li	a3,45
ffffffffc0203c0c:	0cd79163          	bne	a5,a3,ffffffffc0203cce <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c10:	00044783          	lbu	a5,0(s0)
ffffffffc0203c14:	0007851b          	sext.w	a0,a5
ffffffffc0203c18:	cf85                	beqz	a5,ffffffffc0203c50 <vprintfmt+0x236>
ffffffffc0203c1a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c1e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c22:	000c4563          	bltz	s8,ffffffffc0203c2c <vprintfmt+0x212>
ffffffffc0203c26:	3c7d                	addiw	s8,s8,-1
ffffffffc0203c28:	036c0263          	beq	s8,s6,ffffffffc0203c4c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203c2c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c2e:	0e0c8e63          	beqz	s9,ffffffffc0203d2a <vprintfmt+0x310>
ffffffffc0203c32:	3781                	addiw	a5,a5,-32
ffffffffc0203c34:	0ef47b63          	bgeu	s0,a5,ffffffffc0203d2a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203c38:	03f00513          	li	a0,63
ffffffffc0203c3c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c3e:	000a4783          	lbu	a5,0(s4)
ffffffffc0203c42:	3dfd                	addiw	s11,s11,-1
ffffffffc0203c44:	0a05                	addi	s4,s4,1
ffffffffc0203c46:	0007851b          	sext.w	a0,a5
ffffffffc0203c4a:	ffe1                	bnez	a5,ffffffffc0203c22 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203c4c:	01b05963          	blez	s11,ffffffffc0203c5e <vprintfmt+0x244>
ffffffffc0203c50:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203c52:	85a6                	mv	a1,s1
ffffffffc0203c54:	02000513          	li	a0,32
ffffffffc0203c58:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203c5a:	fe0d9be3          	bnez	s11,ffffffffc0203c50 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c5e:	6a02                	ld	s4,0(sp)
ffffffffc0203c60:	bbd5                	j	ffffffffc0203a54 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203c62:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c64:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203c68:	01174463          	blt	a4,a7,ffffffffc0203c70 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203c6c:	08088d63          	beqz	a7,ffffffffc0203d06 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203c70:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203c74:	0a044d63          	bltz	s0,ffffffffc0203d2e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203c78:	8622                	mv	a2,s0
ffffffffc0203c7a:	8a66                	mv	s4,s9
ffffffffc0203c7c:	46a9                	li	a3,10
ffffffffc0203c7e:	bdcd                	j	ffffffffc0203b70 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203c80:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c84:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203c86:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203c88:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203c8c:	8fb5                	xor	a5,a5,a3
ffffffffc0203c8e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c92:	02d74163          	blt	a4,a3,ffffffffc0203cb4 <vprintfmt+0x29a>
ffffffffc0203c96:	00369793          	slli	a5,a3,0x3
ffffffffc0203c9a:	97de                	add	a5,a5,s7
ffffffffc0203c9c:	639c                	ld	a5,0(a5)
ffffffffc0203c9e:	cb99                	beqz	a5,ffffffffc0203cb4 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203ca0:	86be                	mv	a3,a5
ffffffffc0203ca2:	00000617          	auipc	a2,0x0
ffffffffc0203ca6:	21660613          	addi	a2,a2,534 # ffffffffc0203eb8 <etext+0x2c>
ffffffffc0203caa:	85a6                	mv	a1,s1
ffffffffc0203cac:	854a                	mv	a0,s2
ffffffffc0203cae:	0ce000ef          	jal	ra,ffffffffc0203d7c <printfmt>
ffffffffc0203cb2:	b34d                	j	ffffffffc0203a54 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203cb4:	00002617          	auipc	a2,0x2
ffffffffc0203cb8:	b0460613          	addi	a2,a2,-1276 # ffffffffc02057b8 <default_pmm_manager+0xaf8>
ffffffffc0203cbc:	85a6                	mv	a1,s1
ffffffffc0203cbe:	854a                	mv	a0,s2
ffffffffc0203cc0:	0bc000ef          	jal	ra,ffffffffc0203d7c <printfmt>
ffffffffc0203cc4:	bb41                	j	ffffffffc0203a54 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203cc6:	00002417          	auipc	s0,0x2
ffffffffc0203cca:	aea40413          	addi	s0,s0,-1302 # ffffffffc02057b0 <default_pmm_manager+0xaf0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cce:	85e2                	mv	a1,s8
ffffffffc0203cd0:	8522                	mv	a0,s0
ffffffffc0203cd2:	e43e                	sd	a5,8(sp)
ffffffffc0203cd4:	0e2000ef          	jal	ra,ffffffffc0203db6 <strnlen>
ffffffffc0203cd8:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203cdc:	01b05b63          	blez	s11,ffffffffc0203cf2 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203ce0:	67a2                	ld	a5,8(sp)
ffffffffc0203ce2:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203ce6:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203ce8:	85a6                	mv	a1,s1
ffffffffc0203cea:	8552                	mv	a0,s4
ffffffffc0203cec:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cee:	fe0d9ce3          	bnez	s11,ffffffffc0203ce6 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cf2:	00044783          	lbu	a5,0(s0)
ffffffffc0203cf6:	00140a13          	addi	s4,s0,1
ffffffffc0203cfa:	0007851b          	sext.w	a0,a5
ffffffffc0203cfe:	d3a5                	beqz	a5,ffffffffc0203c5e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d00:	05e00413          	li	s0,94
ffffffffc0203d04:	bf39                	j	ffffffffc0203c22 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203d06:	000a2403          	lw	s0,0(s4)
ffffffffc0203d0a:	b7ad                	j	ffffffffc0203c74 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203d0c:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d10:	46a1                	li	a3,8
ffffffffc0203d12:	8a2e                	mv	s4,a1
ffffffffc0203d14:	bdb1                	j	ffffffffc0203b70 <vprintfmt+0x156>
ffffffffc0203d16:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d1a:	46a9                	li	a3,10
ffffffffc0203d1c:	8a2e                	mv	s4,a1
ffffffffc0203d1e:	bd89                	j	ffffffffc0203b70 <vprintfmt+0x156>
ffffffffc0203d20:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d24:	46c1                	li	a3,16
ffffffffc0203d26:	8a2e                	mv	s4,a1
ffffffffc0203d28:	b5a1                	j	ffffffffc0203b70 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203d2a:	9902                	jalr	s2
ffffffffc0203d2c:	bf09                	j	ffffffffc0203c3e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203d2e:	85a6                	mv	a1,s1
ffffffffc0203d30:	02d00513          	li	a0,45
ffffffffc0203d34:	e03e                	sd	a5,0(sp)
ffffffffc0203d36:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203d38:	6782                	ld	a5,0(sp)
ffffffffc0203d3a:	8a66                	mv	s4,s9
ffffffffc0203d3c:	40800633          	neg	a2,s0
ffffffffc0203d40:	46a9                	li	a3,10
ffffffffc0203d42:	b53d                	j	ffffffffc0203b70 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203d44:	03b05163          	blez	s11,ffffffffc0203d66 <vprintfmt+0x34c>
ffffffffc0203d48:	02d00693          	li	a3,45
ffffffffc0203d4c:	f6d79de3          	bne	a5,a3,ffffffffc0203cc6 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203d50:	00002417          	auipc	s0,0x2
ffffffffc0203d54:	a6040413          	addi	s0,s0,-1440 # ffffffffc02057b0 <default_pmm_manager+0xaf0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d58:	02800793          	li	a5,40
ffffffffc0203d5c:	02800513          	li	a0,40
ffffffffc0203d60:	00140a13          	addi	s4,s0,1
ffffffffc0203d64:	bd6d                	j	ffffffffc0203c1e <vprintfmt+0x204>
ffffffffc0203d66:	00002a17          	auipc	s4,0x2
ffffffffc0203d6a:	a4ba0a13          	addi	s4,s4,-1461 # ffffffffc02057b1 <default_pmm_manager+0xaf1>
ffffffffc0203d6e:	02800513          	li	a0,40
ffffffffc0203d72:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d76:	05e00413          	li	s0,94
ffffffffc0203d7a:	b565                	j	ffffffffc0203c22 <vprintfmt+0x208>

ffffffffc0203d7c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d7c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203d7e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d82:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d84:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d86:	ec06                	sd	ra,24(sp)
ffffffffc0203d88:	f83a                	sd	a4,48(sp)
ffffffffc0203d8a:	fc3e                	sd	a5,56(sp)
ffffffffc0203d8c:	e0c2                	sd	a6,64(sp)
ffffffffc0203d8e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203d90:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d92:	c89ff0ef          	jal	ra,ffffffffc0203a1a <vprintfmt>
}
ffffffffc0203d96:	60e2                	ld	ra,24(sp)
ffffffffc0203d98:	6161                	addi	sp,sp,80
ffffffffc0203d9a:	8082                	ret

ffffffffc0203d9c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203d9c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203da0:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203da2:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203da4:	cb81                	beqz	a5,ffffffffc0203db4 <strlen+0x18>
        cnt ++;
ffffffffc0203da6:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203da8:	00a707b3          	add	a5,a4,a0
ffffffffc0203dac:	0007c783          	lbu	a5,0(a5)
ffffffffc0203db0:	fbfd                	bnez	a5,ffffffffc0203da6 <strlen+0xa>
ffffffffc0203db2:	8082                	ret
    }
    return cnt;
}
ffffffffc0203db4:	8082                	ret

ffffffffc0203db6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203db6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203db8:	e589                	bnez	a1,ffffffffc0203dc2 <strnlen+0xc>
ffffffffc0203dba:	a811                	j	ffffffffc0203dce <strnlen+0x18>
        cnt ++;
ffffffffc0203dbc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203dbe:	00f58863          	beq	a1,a5,ffffffffc0203dce <strnlen+0x18>
ffffffffc0203dc2:	00f50733          	add	a4,a0,a5
ffffffffc0203dc6:	00074703          	lbu	a4,0(a4)
ffffffffc0203dca:	fb6d                	bnez	a4,ffffffffc0203dbc <strnlen+0x6>
ffffffffc0203dcc:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203dce:	852e                	mv	a0,a1
ffffffffc0203dd0:	8082                	ret

ffffffffc0203dd2 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203dd2:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203dd4:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dd8:	0785                	addi	a5,a5,1
ffffffffc0203dda:	0585                	addi	a1,a1,1
ffffffffc0203ddc:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203de0:	fb75                	bnez	a4,ffffffffc0203dd4 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203de2:	8082                	ret

ffffffffc0203de4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203de4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203de8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203dec:	cb89                	beqz	a5,ffffffffc0203dfe <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203dee:	0505                	addi	a0,a0,1
ffffffffc0203df0:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203df2:	fee789e3          	beq	a5,a4,ffffffffc0203de4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203df6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203dfa:	9d19                	subw	a0,a0,a4
ffffffffc0203dfc:	8082                	ret
ffffffffc0203dfe:	4501                	li	a0,0
ffffffffc0203e00:	bfed                	j	ffffffffc0203dfa <strcmp+0x16>

ffffffffc0203e02 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e02:	c20d                	beqz	a2,ffffffffc0203e24 <strncmp+0x22>
ffffffffc0203e04:	962e                	add	a2,a2,a1
ffffffffc0203e06:	a031                	j	ffffffffc0203e12 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203e08:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e0a:	00e79a63          	bne	a5,a4,ffffffffc0203e1e <strncmp+0x1c>
ffffffffc0203e0e:	00b60b63          	beq	a2,a1,ffffffffc0203e24 <strncmp+0x22>
ffffffffc0203e12:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203e16:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e18:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203e1c:	f7f5                	bnez	a5,ffffffffc0203e08 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e1e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203e22:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e24:	4501                	li	a0,0
ffffffffc0203e26:	8082                	ret

ffffffffc0203e28 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e28:	00054783          	lbu	a5,0(a0)
ffffffffc0203e2c:	c799                	beqz	a5,ffffffffc0203e3a <strchr+0x12>
        if (*s == c) {
ffffffffc0203e2e:	00f58763          	beq	a1,a5,ffffffffc0203e3c <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203e32:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203e36:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e38:	fbfd                	bnez	a5,ffffffffc0203e2e <strchr+0x6>
    }
    return NULL;
ffffffffc0203e3a:	4501                	li	a0,0
}
ffffffffc0203e3c:	8082                	ret

ffffffffc0203e3e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e3e:	ca01                	beqz	a2,ffffffffc0203e4e <memset+0x10>
ffffffffc0203e40:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e42:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e44:	0785                	addi	a5,a5,1
ffffffffc0203e46:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e4a:	fec79de3          	bne	a5,a2,ffffffffc0203e44 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e4e:	8082                	ret

ffffffffc0203e50 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e50:	ca19                	beqz	a2,ffffffffc0203e66 <memcpy+0x16>
ffffffffc0203e52:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e54:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e56:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e5a:	0585                	addi	a1,a1,1
ffffffffc0203e5c:	0785                	addi	a5,a5,1
ffffffffc0203e5e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203e62:	fec59ae3          	bne	a1,a2,ffffffffc0203e56 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203e66:	8082                	ret

ffffffffc0203e68 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203e68:	c205                	beqz	a2,ffffffffc0203e88 <memcmp+0x20>
ffffffffc0203e6a:	962e                	add	a2,a2,a1
ffffffffc0203e6c:	a019                	j	ffffffffc0203e72 <memcmp+0xa>
ffffffffc0203e6e:	00c58d63          	beq	a1,a2,ffffffffc0203e88 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203e72:	00054783          	lbu	a5,0(a0)
ffffffffc0203e76:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203e7a:	0505                	addi	a0,a0,1
ffffffffc0203e7c:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203e7e:	fee788e3          	beq	a5,a4,ffffffffc0203e6e <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e82:	40e7853b          	subw	a0,a5,a4
ffffffffc0203e86:	8082                	ret
    }
    return 0;
ffffffffc0203e88:	4501                	li	a0,0
}
ffffffffc0203e8a:	8082                	ret
