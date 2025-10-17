
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	71450513          	addi	a0,a0,1812 # ffffffffc0201760 <etext+0xa>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	71e50513          	addi	a0,a0,1822 # ffffffffc0201780 <etext+0x2a>
ffffffffc020006a:	0de000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	6e858593          	addi	a1,a1,1768 # ffffffffc0201756 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	72a50513          	addi	a0,a0,1834 # ffffffffc02017a0 <etext+0x4a>
ffffffffc020007e:	0ca000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <slub_caches>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	73650513          	addi	a0,a0,1846 # ffffffffc02017c0 <etext+0x6a>
ffffffffc0200092:	0b6000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	16258593          	addi	a1,a1,354 # ffffffffc02061f8 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	74250513          	addi	a0,a0,1858 # ffffffffc02017e0 <etext+0x8a>
ffffffffc02000a6:	0a2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00006797          	auipc	a5,0x6
ffffffffc02000b6:	54578793          	addi	a5,a5,1349 # ffffffffc02065f7 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	73650513          	addi	a0,a0,1846 # ffffffffc0201800 <etext+0xaa>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a895                	j	ffffffffc0200148 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00006517          	auipc	a0,0x6
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0206018 <slub_caches>
ffffffffc02000de:	00006617          	auipc	a2,0x6
ffffffffc02000e2:	11a60613          	addi	a2,a2,282 # ffffffffc02061f8 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	656010ef          	jal	ffffffffc0201744 <memset>
    dtb_init();
ffffffffc02000f2:	136000ef          	jal	ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	128000ef          	jal	ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	23650513          	addi	a0,a0,566 # ffffffffc0202330 <etext+0xbda>
ffffffffc0200102:	07a000ef          	jal	ffffffffc020017c <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	464000ef          	jal	ffffffffc020056e <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	ec06                	sd	ra,24(sp)
ffffffffc0200114:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200116:	10a000ef          	jal	ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc020011a:	65a2                	ld	a1,8(sp)
}
ffffffffc020011c:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc020011e:	419c                	lw	a5,0(a1)
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c19c                	sw	a5,0(a1)
}
ffffffffc0200124:	6105                	addi	sp,sp,32
ffffffffc0200126:	8082                	ret

ffffffffc0200128 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200128:	1101                	addi	sp,sp,-32
ffffffffc020012a:	862a                	mv	a2,a0
ffffffffc020012c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020012e:	00000517          	auipc	a0,0x0
ffffffffc0200132:	fe250513          	addi	a0,a0,-30 # ffffffffc0200110 <cputch>
ffffffffc0200136:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200138:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013a:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013c:	1f8010ef          	jal	ffffffffc0201334 <vprintfmt>
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	4532                	lw	a0,12(sp)
ffffffffc0200144:	6105                	addi	sp,sp,32
ffffffffc0200146:	8082                	ret

ffffffffc0200148 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200148:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014a:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc020014e:	f42e                	sd	a1,40(sp)
ffffffffc0200150:	f832                	sd	a2,48(sp)
ffffffffc0200152:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200154:	862a                	mv	a2,a0
ffffffffc0200156:	004c                	addi	a1,sp,4
ffffffffc0200158:	00000517          	auipc	a0,0x0
ffffffffc020015c:	fb850513          	addi	a0,a0,-72 # ffffffffc0200110 <cputch>
ffffffffc0200160:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e0ba                	sd	a4,64(sp)
ffffffffc0200166:	e4be                	sd	a5,72(sp)
ffffffffc0200168:	e8c2                	sd	a6,80(sp)
ffffffffc020016a:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc020016c:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	1c4010ef          	jal	ffffffffc0201334 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200174:	60e2                	ld	ra,24(sp)
ffffffffc0200176:	4512                	lw	a0,4(sp)
ffffffffc0200178:	6125                	addi	sp,sp,96
ffffffffc020017a:	8082                	ret

ffffffffc020017c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017c:	1101                	addi	sp,sp,-32
ffffffffc020017e:	e822                	sd	s0,16(sp)
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200184:	00054503          	lbu	a0,0(a0)
ffffffffc0200188:	c51d                	beqz	a0,ffffffffc02001b6 <cputs+0x3a>
ffffffffc020018a:	e426                	sd	s1,8(sp)
ffffffffc020018c:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc020018e:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200190:	090000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00044503          	lbu	a0,0(s0)
ffffffffc0200198:	0405                	addi	s0,s0,1
ffffffffc020019a:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020019c:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc020019e:	f96d                	bnez	a0,ffffffffc0200190 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a0:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a2:	0027841b          	addiw	s0,a5,2
ffffffffc02001a6:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001a8:	078000ef          	jal	ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ac:	60e2                	ld	ra,24(sp)
ffffffffc02001ae:	8522                	mv	a0,s0
ffffffffc02001b0:	6442                	ld	s0,16(sp)
ffffffffc02001b2:	6105                	addi	sp,sp,32
ffffffffc02001b4:	8082                	ret
    cons_putc(c);
ffffffffc02001b6:	4529                	li	a0,10
ffffffffc02001b8:	068000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001bc:	4405                	li	s0,1
}
ffffffffc02001be:	60e2                	ld	ra,24(sp)
ffffffffc02001c0:	8522                	mv	a0,s0
ffffffffc02001c2:	6442                	ld	s0,16(sp)
ffffffffc02001c4:	6105                	addi	sp,sp,32
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00006317          	auipc	t1,0x6
ffffffffc02001cc:	fe832303          	lw	t1,-24(t1) # ffffffffc02061b0 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d0:	715d                	addi	sp,sp,-80
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	00030363          	beqz	t1,ffffffffc02001e4 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e4:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001e6:	103c                	addi	a5,sp,40
ffffffffc02001e8:	e822                	sd	s0,16(sp)
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	862e                	mv	a2,a1
ffffffffc02001ee:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f0:	00001517          	auipc	a0,0x1
ffffffffc02001f4:	64050513          	addi	a0,a0,1600 # ffffffffc0201830 <etext+0xda>
    is_panic = 1;
ffffffffc02001f8:	00006697          	auipc	a3,0x6
ffffffffc02001fc:	fae6ac23          	sw	a4,-72(a3) # ffffffffc02061b0 <is_panic>
    va_start(ap, fmt);
ffffffffc0200200:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200202:	f47ff0ef          	jal	ffffffffc0200148 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200206:	65a2                	ld	a1,8(sp)
ffffffffc0200208:	8522                	mv	a0,s0
ffffffffc020020a:	f1fff0ef          	jal	ffffffffc0200128 <vcprintf>
    cprintf("\n");
ffffffffc020020e:	00001517          	auipc	a0,0x1
ffffffffc0200212:	64250513          	addi	a0,a0,1602 # ffffffffc0201850 <etext+0xfa>
ffffffffc0200216:	f33ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc020021a:	6442                	ld	s0,16(sp)
ffffffffc020021c:	b7d9                	j	ffffffffc02001e2 <__panic+0x1a>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	4760106f          	j	ffffffffc020169a <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	62e50513          	addi	a0,a0,1582 # ffffffffc0201858 <etext+0x102>
void dtb_init(void) {
ffffffffc0200232:	f406                	sd	ra,40(sp)
ffffffffc0200234:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200236:	f13ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023a:	00006597          	auipc	a1,0x6
ffffffffc020023e:	dc65b583          	ld	a1,-570(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200242:	00001517          	auipc	a0,0x1
ffffffffc0200246:	62650513          	addi	a0,a0,1574 # ffffffffc0201868 <etext+0x112>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024a:	00006417          	auipc	s0,0x6
ffffffffc020024e:	dbe40413          	addi	s0,s0,-578 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200252:	ef7ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200256:	600c                	ld	a1,0(s0)
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	62050513          	addi	a0,a0,1568 # ffffffffc0201878 <etext+0x122>
ffffffffc0200260:	ee9ff0ef          	jal	ffffffffc0200148 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200264:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	62a50513          	addi	a0,a0,1578 # ffffffffc0201890 <etext+0x13a>
    if (boot_dtb == 0) {
ffffffffc020026e:	10070163          	beqz	a4,ffffffffc0200370 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200272:	57f5                	li	a5,-3
ffffffffc0200274:	07fa                	slli	a5,a5,0x1e
ffffffffc0200276:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200278:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020027a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020027e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed9cf5>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200286:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	8e49                	or	a2,a2,a0
ffffffffc020029a:	0ff7f793          	zext.b	a5,a5
ffffffffc020029e:	8dd1                	or	a1,a1,a2
ffffffffc02002a0:	07a2                	slli	a5,a5,0x8
ffffffffc02002a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002a8:	0cd59863          	bne	a1,a3,ffffffffc0200378 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ac:	4710                	lw	a2,8(a4)
ffffffffc02002ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002da:	01c56533          	or	a0,a0,t3
ffffffffc02002de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02002f2:	8c49                	or	s0,s0,a0
ffffffffc02002f4:	0622                	slli	a2,a2,0x8
ffffffffc02002f6:	8fcd                	or	a5,a5,a1
ffffffffc02002f8:	06a2                	slli	a3,a3,0x8
ffffffffc02002fa:	8c51                	or	s0,s0,a2
ffffffffc02002fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02002fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200300:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200302:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200304:	9381                	srli	a5,a5,0x20
ffffffffc0200306:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200308:	4301                	li	t1,0
        switch (token) {
ffffffffc020030a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200312:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200314:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200316:	0087579b          	srliw	a5,a4,0x8
ffffffffc020031a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020031e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200322:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200326:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032e:	8ed1                	or	a3,a3,a2
ffffffffc0200330:	0ff77713          	zext.b	a4,a4
ffffffffc0200334:	8fd5                	or	a5,a5,a3
ffffffffc0200336:	0722                	slli	a4,a4,0x8
ffffffffc0200338:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020033a:	05178763          	beq	a5,a7,ffffffffc0200388 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200340:	00f8e963          	bltu	a7,a5,ffffffffc0200352 <dtb_init+0x12a>
ffffffffc0200344:	07c78d63          	beq	a5,t3,ffffffffc02003be <dtb_init+0x196>
ffffffffc0200348:	4709                	li	a4,2
ffffffffc020034a:	00e79763          	bne	a5,a4,ffffffffc0200358 <dtb_init+0x130>
ffffffffc020034e:	4301                	li	t1,0
ffffffffc0200350:	b7d1                	j	ffffffffc0200314 <dtb_init+0xec>
ffffffffc0200352:	4711                	li	a4,4
ffffffffc0200354:	fce780e3          	beq	a5,a4,ffffffffc0200314 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200358:	00001517          	auipc	a0,0x1
ffffffffc020035c:	60050513          	addi	a0,a0,1536 # ffffffffc0201958 <etext+0x202>
ffffffffc0200360:	de9ff0ef          	jal	ffffffffc0200148 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200364:	64e2                	ld	s1,24(sp)
ffffffffc0200366:	6942                	ld	s2,16(sp)
ffffffffc0200368:	00001517          	auipc	a0,0x1
ffffffffc020036c:	62850513          	addi	a0,a0,1576 # ffffffffc0201990 <etext+0x23a>
}
ffffffffc0200370:	7402                	ld	s0,32(sp)
ffffffffc0200372:	70a2                	ld	ra,40(sp)
ffffffffc0200374:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200376:	bbc9                	j	ffffffffc0200148 <cprintf>
}
ffffffffc0200378:	7402                	ld	s0,32(sp)
ffffffffc020037a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020037c:	00001517          	auipc	a0,0x1
ffffffffc0200380:	53450513          	addi	a0,a0,1332 # ffffffffc02018b0 <etext+0x15a>
}
ffffffffc0200384:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200386:	b3c9                	j	ffffffffc0200148 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200388:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020038a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020038e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200392:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200396:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a2:	8ed1                	or	a3,a3,a2
ffffffffc02003a4:	0ff77713          	zext.b	a4,a4
ffffffffc02003a8:	8fd5                	or	a5,a5,a3
ffffffffc02003aa:	0722                	slli	a4,a4,0x8
ffffffffc02003ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003ae:	04031463          	bnez	t1,ffffffffc02003f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003b2:	1782                	slli	a5,a5,0x20
ffffffffc02003b4:	9381                	srli	a5,a5,0x20
ffffffffc02003b6:	043d                	addi	s0,s0,15
ffffffffc02003b8:	943e                	add	s0,s0,a5
ffffffffc02003ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003bc:	bfa1                	j	ffffffffc0200314 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003be:	8522                	mv	a0,s0
ffffffffc02003c0:	e01a                	sd	t1,0(sp)
ffffffffc02003c2:	2f2010ef          	jal	ffffffffc02016b4 <strlen>
ffffffffc02003c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003c8:	4619                	li	a2,6
ffffffffc02003ca:	8522                	mv	a0,s0
ffffffffc02003cc:	00001597          	auipc	a1,0x1
ffffffffc02003d0:	50c58593          	addi	a1,a1,1292 # ffffffffc02018d8 <etext+0x182>
ffffffffc02003d4:	348010ef          	jal	ffffffffc020171c <strncmp>
ffffffffc02003d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003da:	0411                	addi	s0,s0,4
ffffffffc02003dc:	0004879b          	sext.w	a5,s1
ffffffffc02003e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003ec:	00ff0837          	lui	a6,0xff0
ffffffffc02003f0:	488d                	li	a7,3
ffffffffc02003f2:	4e05                	li	t3,1
ffffffffc02003f4:	b705                	j	ffffffffc0200314 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003f8:	00001597          	auipc	a1,0x1
ffffffffc02003fc:	4e858593          	addi	a1,a1,1256 # ffffffffc02018e0 <etext+0x18a>
ffffffffc0200400:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200402:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200406:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020040e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200412:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041a:	8ed1                	or	a3,a3,a2
ffffffffc020041c:	0ff77713          	zext.b	a4,a4
ffffffffc0200420:	0722                	slli	a4,a4,0x8
ffffffffc0200422:	8d55                	or	a0,a0,a3
ffffffffc0200424:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200426:	1502                	slli	a0,a0,0x20
ffffffffc0200428:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042a:	954a                	add	a0,a0,s2
ffffffffc020042c:	e01a                	sd	t1,0(sp)
ffffffffc020042e:	2ba010ef          	jal	ffffffffc02016e8 <strcmp>
ffffffffc0200432:	67a2                	ld	a5,8(sp)
ffffffffc0200434:	473d                	li	a4,15
ffffffffc0200436:	6302                	ld	t1,0(sp)
ffffffffc0200438:	00ff0837          	lui	a6,0xff0
ffffffffc020043c:	488d                	li	a7,3
ffffffffc020043e:	4e05                	li	t3,1
ffffffffc0200440:	f6f779e3          	bgeu	a4,a5,ffffffffc02003b2 <dtb_init+0x18a>
ffffffffc0200444:	f53d                	bnez	a0,ffffffffc02003b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200446:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020044a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020044e:	00001517          	auipc	a0,0x1
ffffffffc0200452:	49a50513          	addi	a0,a0,1178 # ffffffffc02018e8 <etext+0x192>
           fdt32_to_cpu(x >> 32);
ffffffffc0200456:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020045e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200462:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200466:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020046e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200472:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200476:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	01037333          	and	t1,t1,a6
ffffffffc0200482:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	01e5e5b3          	or	a1,a1,t5
ffffffffc020048a:	0ff7f793          	zext.b	a5,a5
ffffffffc020048e:	01de6e33          	or	t3,t3,t4
ffffffffc0200492:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200496:	01067633          	and	a2,a2,a6
ffffffffc020049a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020049e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a2:	07a2                	slli	a5,a5,0x8
ffffffffc02004a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b0:	8ddd                	or	a1,a1,a5
ffffffffc02004b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	08a2                	slli	a7,a7,0x8
ffffffffc02004d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02004e4:	01de6833          	or	a6,t3,t4
ffffffffc02004e8:	0ff77713          	zext.b	a4,a4
ffffffffc02004ec:	01166633          	or	a2,a2,a7
ffffffffc02004f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02004f4:	06a2                	slli	a3,a3,0x8
ffffffffc02004f6:	01046433          	or	s0,s0,a6
ffffffffc02004fa:	0722                	slli	a4,a4,0x8
ffffffffc02004fc:	8fd5                	or	a5,a5,a3
ffffffffc02004fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200500:	1582                	slli	a1,a1,0x20
ffffffffc0200502:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200504:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200506:	9201                	srli	a2,a2,0x20
ffffffffc0200508:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050a:	1402                	slli	s0,s0,0x20
ffffffffc020050c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200510:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200512:	c37ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200516:	85a6                	mv	a1,s1
ffffffffc0200518:	00001517          	auipc	a0,0x1
ffffffffc020051c:	3f050513          	addi	a0,a0,1008 # ffffffffc0201908 <etext+0x1b2>
ffffffffc0200520:	c29ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200524:	01445613          	srli	a2,s0,0x14
ffffffffc0200528:	85a2                	mv	a1,s0
ffffffffc020052a:	00001517          	auipc	a0,0x1
ffffffffc020052e:	3f650513          	addi	a0,a0,1014 # ffffffffc0201920 <etext+0x1ca>
ffffffffc0200532:	c17ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200536:	009405b3          	add	a1,s0,s1
ffffffffc020053a:	15fd                	addi	a1,a1,-1
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	40450513          	addi	a0,a0,1028 # ffffffffc0201940 <etext+0x1ea>
ffffffffc0200544:	c05ff0ef          	jal	ffffffffc0200148 <cprintf>
        memory_base = mem_base;
ffffffffc0200548:	00006797          	auipc	a5,0x6
ffffffffc020054c:	c697bc23          	sd	s1,-904(a5) # ffffffffc02061c0 <memory_base>
        memory_size = mem_size;
ffffffffc0200550:	00006797          	auipc	a5,0x6
ffffffffc0200554:	c687b423          	sd	s0,-920(a5) # ffffffffc02061b8 <memory_size>
ffffffffc0200558:	b531                	j	ffffffffc0200364 <dtb_init+0x13c>

ffffffffc020055a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055a:	00006517          	auipc	a0,0x6
ffffffffc020055e:	c6653503          	ld	a0,-922(a0) # ffffffffc02061c0 <memory_base>
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200564:	00006517          	auipc	a0,0x6
ffffffffc0200568:	c5453503          	ld	a0,-940(a0) # ffffffffc02061b8 <memory_size>
ffffffffc020056c:	8082                	ret

ffffffffc020056e <pmm_init>:
static void init_pmm_manager(void) {
    // pmm_manager = &default_pmm_manager;
    extern const struct pmm_manager default_pmm_manager;
    extern const struct pmm_manager best_fit_pmm_manager;
    extern const struct pmm_manager slub_pmm_manager;
    pmm_manager = &slub_pmm_manager;
ffffffffc020056e:	00002797          	auipc	a5,0x2
ffffffffc0200572:	de278793          	addi	a5,a5,-542 # ffffffffc0202350 <slub_pmm_manager>

    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200576:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200578:	7139                	addi	sp,sp,-64
ffffffffc020057a:	fc06                	sd	ra,56(sp)
ffffffffc020057c:	f822                	sd	s0,48(sp)
ffffffffc020057e:	f426                	sd	s1,40(sp)
ffffffffc0200580:	ec4e                	sd	s3,24(sp)
ffffffffc0200582:	f04a                	sd	s2,32(sp)
    pmm_manager = &slub_pmm_manager;
ffffffffc0200584:	00006417          	auipc	s0,0x6
ffffffffc0200588:	c4440413          	addi	s0,s0,-956 # ffffffffc02061c8 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020058c:	00001517          	auipc	a0,0x1
ffffffffc0200590:	41c50513          	addi	a0,a0,1052 # ffffffffc02019a8 <etext+0x252>
    pmm_manager = &slub_pmm_manager;
ffffffffc0200594:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200596:	bb3ff0ef          	jal	ffffffffc0200148 <cprintf>
    pmm_manager->init();
ffffffffc020059a:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020059c:	00006497          	auipc	s1,0x6
ffffffffc02005a0:	c4448493          	addi	s1,s1,-956 # ffffffffc02061e0 <va_pa_offset>
    pmm_manager->init();
ffffffffc02005a4:	679c                	ld	a5,8(a5)
ffffffffc02005a6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02005a8:	57f5                	li	a5,-3
ffffffffc02005aa:	07fa                	slli	a5,a5,0x1e
ffffffffc02005ac:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02005ae:	fadff0ef          	jal	ffffffffc020055a <get_memory_base>
ffffffffc02005b2:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02005b4:	fb1ff0ef          	jal	ffffffffc0200564 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02005b8:	14050b63          	beqz	a0,ffffffffc020070e <pmm_init+0x1a0>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02005bc:	00a98933          	add	s2,s3,a0
ffffffffc02005c0:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc02005c2:	00001517          	auipc	a0,0x1
ffffffffc02005c6:	42e50513          	addi	a0,a0,1070 # ffffffffc02019f0 <etext+0x29a>
ffffffffc02005ca:	b7fff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02005ce:	65a2                	ld	a1,8(sp)
ffffffffc02005d0:	864e                	mv	a2,s3
ffffffffc02005d2:	fff90693          	addi	a3,s2,-1
ffffffffc02005d6:	00001517          	auipc	a0,0x1
ffffffffc02005da:	43250513          	addi	a0,a0,1074 # ffffffffc0201a08 <etext+0x2b2>
ffffffffc02005de:	b6bff0ef          	jal	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc02005e2:	c80007b7          	lui	a5,0xc8000
ffffffffc02005e6:	85ca                	mv	a1,s2
ffffffffc02005e8:	0d27e163          	bltu	a5,s2,ffffffffc02006aa <pmm_init+0x13c>
ffffffffc02005ec:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02005ee:	00007697          	auipc	a3,0x7
ffffffffc02005f2:	c0968693          	addi	a3,a3,-1015 # ffffffffc02071f7 <end+0xfff>
ffffffffc02005f6:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc02005f8:	81b1                	srli	a1,a1,0xc
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02005fa:	fff80837          	lui	a6,0xfff80
    npage = maxpa / PGSIZE;
ffffffffc02005fe:	00006797          	auipc	a5,0x6
ffffffffc0200602:	beb7b523          	sd	a1,-1046(a5) # ffffffffc02061e8 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200606:	00006797          	auipc	a5,0x6
ffffffffc020060a:	bed7b523          	sd	a3,-1046(a5) # ffffffffc02061f0 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020060e:	982e                	add	a6,a6,a1
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200610:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200612:	02080963          	beqz	a6,ffffffffc0200644 <pmm_init+0xd6>
ffffffffc0200616:	00259613          	slli	a2,a1,0x2
ffffffffc020061a:	962e                	add	a2,a2,a1
ffffffffc020061c:	fec007b7          	lui	a5,0xfec00
ffffffffc0200620:	97b6                	add	a5,a5,a3
ffffffffc0200622:	060e                	slli	a2,a2,0x3
ffffffffc0200624:	963e                	add	a2,a2,a5
ffffffffc0200626:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc0200628:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020062a:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9e30>
        SetPageReserved(pages + i);
ffffffffc020062e:	00176713          	ori	a4,a4,1
ffffffffc0200632:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200636:	fec799e3          	bne	a5,a2,ffffffffc0200628 <pmm_init+0xba>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020063a:	00281793          	slli	a5,a6,0x2
ffffffffc020063e:	97c2                	add	a5,a5,a6
ffffffffc0200640:	078e                	slli	a5,a5,0x3
ffffffffc0200642:	96be                	add	a3,a3,a5
ffffffffc0200644:	c02007b7          	lui	a5,0xc0200
ffffffffc0200648:	0af6e763          	bltu	a3,a5,ffffffffc02006f6 <pmm_init+0x188>
ffffffffc020064c:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020064e:	77fd                	lui	a5,0xfffff
ffffffffc0200650:	00f97933          	and	s2,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200654:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0200656:	0526ec63          	bltu	a3,s2,ffffffffc02006ae <pmm_init+0x140>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020065a:	601c                	ld	a5,0(s0)
ffffffffc020065c:	7b9c                	ld	a5,48(a5)
ffffffffc020065e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200660:	00001517          	auipc	a0,0x1
ffffffffc0200664:	43050513          	addi	a0,a0,1072 # ffffffffc0201a90 <etext+0x33a>
ffffffffc0200668:	ae1ff0ef          	jal	ffffffffc0200148 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020066c:	00005597          	auipc	a1,0x5
ffffffffc0200670:	99458593          	addi	a1,a1,-1644 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200674:	00006797          	auipc	a5,0x6
ffffffffc0200678:	b6b7b223          	sd	a1,-1180(a5) # ffffffffc02061d8 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020067c:	c02007b7          	lui	a5,0xc0200
ffffffffc0200680:	0af5e363          	bltu	a1,a5,ffffffffc0200726 <pmm_init+0x1b8>
ffffffffc0200684:	609c                	ld	a5,0(s1)
}
ffffffffc0200686:	7442                	ld	s0,48(sp)
ffffffffc0200688:	70e2                	ld	ra,56(sp)
ffffffffc020068a:	74a2                	ld	s1,40(sp)
ffffffffc020068c:	7902                	ld	s2,32(sp)
ffffffffc020068e:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200690:	40f586b3          	sub	a3,a1,a5
ffffffffc0200694:	00006797          	auipc	a5,0x6
ffffffffc0200698:	b2d7be23          	sd	a3,-1220(a5) # ffffffffc02061d0 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020069c:	00001517          	auipc	a0,0x1
ffffffffc02006a0:	41450513          	addi	a0,a0,1044 # ffffffffc0201ab0 <etext+0x35a>
ffffffffc02006a4:	8636                	mv	a2,a3
}
ffffffffc02006a6:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02006a8:	b445                	j	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc02006aa:	85be                	mv	a1,a5
ffffffffc02006ac:	b781                	j	ffffffffc02005ec <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02006ae:	6705                	lui	a4,0x1
ffffffffc02006b0:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02006b2:	96ba                	add	a3,a3,a4
ffffffffc02006b4:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02006b6:	00c6d793          	srli	a5,a3,0xc
ffffffffc02006ba:	02b7f263          	bgeu	a5,a1,ffffffffc02006de <pmm_init+0x170>
    pmm_manager->init_memmap(base, n);
ffffffffc02006be:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02006c0:	fff80637          	lui	a2,0xfff80
ffffffffc02006c4:	97b2                	add	a5,a5,a2
ffffffffc02006c6:	00279513          	slli	a0,a5,0x2
ffffffffc02006ca:	953e                	add	a0,a0,a5
ffffffffc02006cc:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02006ce:	40d90933          	sub	s2,s2,a3
ffffffffc02006d2:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02006d4:	00c95593          	srli	a1,s2,0xc
ffffffffc02006d8:	9546                	add	a0,a0,a7
ffffffffc02006da:	9782                	jalr	a5
}
ffffffffc02006dc:	bfbd                	j	ffffffffc020065a <pmm_init+0xec>
        panic("pa2page called with invalid pa");
ffffffffc02006de:	00001617          	auipc	a2,0x1
ffffffffc02006e2:	38260613          	addi	a2,a2,898 # ffffffffc0201a60 <etext+0x30a>
ffffffffc02006e6:	06a00593          	li	a1,106
ffffffffc02006ea:	00001517          	auipc	a0,0x1
ffffffffc02006ee:	39650513          	addi	a0,a0,918 # ffffffffc0201a80 <etext+0x32a>
ffffffffc02006f2:	ad7ff0ef          	jal	ffffffffc02001c8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02006f6:	00001617          	auipc	a2,0x1
ffffffffc02006fa:	34260613          	addi	a2,a2,834 # ffffffffc0201a38 <etext+0x2e2>
ffffffffc02006fe:	06500593          	li	a1,101
ffffffffc0200702:	00001517          	auipc	a0,0x1
ffffffffc0200706:	2de50513          	addi	a0,a0,734 # ffffffffc02019e0 <etext+0x28a>
ffffffffc020070a:	abfff0ef          	jal	ffffffffc02001c8 <__panic>
        panic("DTB memory info not available");
ffffffffc020070e:	00001617          	auipc	a2,0x1
ffffffffc0200712:	2b260613          	addi	a2,a2,690 # ffffffffc02019c0 <etext+0x26a>
ffffffffc0200716:	04d00593          	li	a1,77
ffffffffc020071a:	00001517          	auipc	a0,0x1
ffffffffc020071e:	2c650513          	addi	a0,a0,710 # ffffffffc02019e0 <etext+0x28a>
ffffffffc0200722:	aa7ff0ef          	jal	ffffffffc02001c8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200726:	86ae                	mv	a3,a1
ffffffffc0200728:	00001617          	auipc	a2,0x1
ffffffffc020072c:	31060613          	addi	a2,a2,784 # ffffffffc0201a38 <etext+0x2e2>
ffffffffc0200730:	08000593          	li	a1,128
ffffffffc0200734:	00001517          	auipc	a0,0x1
ffffffffc0200738:	2ac50513          	addi	a0,a0,684 # ffffffffc02019e0 <etext+0x28a>
ffffffffc020073c:	a8dff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200740 <slub_nr_free_pages>:
    }
}

static size_t slub_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200740:	00006517          	auipc	a0,0x6
ffffffffc0200744:	a6856503          	lwu	a0,-1432(a0) # ffffffffc02061a8 <free_area+0x10>
ffffffffc0200748:	8082                	ret

ffffffffc020074a <slub_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020074a:	00006797          	auipc	a5,0x6
ffffffffc020074e:	a4e78793          	addi	a5,a5,-1458 # ffffffffc0206198 <free_area>
    nr_free = 0;
ffffffffc0200752:	00006717          	auipc	a4,0x6
ffffffffc0200756:	a4072b23          	sw	zero,-1450(a4) # ffffffffc02061a8 <free_area+0x10>
#define le2slubpage(le, member) to_struct((le), struct slub_page, member)

static void slub_2nd_init(void) {
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++) {
        slub_caches[i].obj_size = slub_sizes[i];
        slub_caches[i].objs_per_page = (PGSIZE - sizeof(struct slub_page)) / slub_caches[i].obj_size;
ffffffffc020075a:	6505                	lui	a0,0x1
ffffffffc020075c:	e79c                	sd	a5,8(a5)
ffffffffc020075e:	e39c                	sd	a5,0(a5)
ffffffffc0200760:	fd050513          	addi	a0,a0,-48 # fd0 <kern_entry-0xffffffffc01ff030>
ffffffffc0200764:	00002717          	auipc	a4,0x2
ffffffffc0200768:	c2c70713          	addi	a4,a4,-980 # ffffffffc0202390 <slub_sizes>
ffffffffc020076c:	00006797          	auipc	a5,0x6
ffffffffc0200770:	8bc78793          	addi	a5,a5,-1860 # ffffffffc0206028 <slub_caches+0x10>
ffffffffc0200774:	00006817          	auipc	a6,0x6
ffffffffc0200778:	a3480813          	addi	a6,a6,-1484 # ffffffffc02061a8 <free_area+0x10>
        slub_caches[i].obj_size = slub_sizes[i];
ffffffffc020077c:	6310                	ld	a2,0(a4)
        list_init(&slub_caches[i].partial);
        list_init(&slub_caches[i].empty);
ffffffffc020077e:	01078693          	addi	a3,a5,16
ffffffffc0200782:	e79c                	sd	a5,8(a5)
        slub_caches[i].objs_per_page = (PGSIZE - sizeof(struct slub_page)) / slub_caches[i].obj_size;
ffffffffc0200784:	02c555b3          	divu	a1,a0,a2
ffffffffc0200788:	e39c                	sd	a5,0(a5)
        slub_caches[i].obj_size = slub_sizes[i];
ffffffffc020078a:	fec7b823          	sd	a2,-16(a5)
ffffffffc020078e:	ef94                	sd	a3,24(a5)
ffffffffc0200790:	eb94                	sd	a3,16(a5)
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++) {
ffffffffc0200792:	03078793          	addi	a5,a5,48
ffffffffc0200796:	0721                	addi	a4,a4,8
        slub_caches[i].objs_per_page = (PGSIZE - sizeof(struct slub_page)) / slub_caches[i].obj_size;
ffffffffc0200798:	fcb7b423          	sd	a1,-56(a5)
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++) {
ffffffffc020079c:	ff0790e3          	bne	a5,a6,ffffffffc020077c <slub_init+0x32>
}
ffffffffc02007a0:	8082                	ret

ffffffffc02007a2 <slub_alloc_pages>:
    assert(n > 0);
ffffffffc02007a2:	cd41                	beqz	a0,ffffffffc020083a <slub_alloc_pages+0x98>
    if (n > nr_free) {
ffffffffc02007a4:	00006597          	auipc	a1,0x6
ffffffffc02007a8:	a045a583          	lw	a1,-1532(a1) # ffffffffc02061a8 <free_area+0x10>
ffffffffc02007ac:	86aa                	mv	a3,a0
ffffffffc02007ae:	02059793          	slli	a5,a1,0x20
ffffffffc02007b2:	9381                	srli	a5,a5,0x20
ffffffffc02007b4:	00a7ef63          	bltu	a5,a0,ffffffffc02007d2 <slub_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02007b8:	00006617          	auipc	a2,0x6
ffffffffc02007bc:	9e060613          	addi	a2,a2,-1568 # ffffffffc0206198 <free_area>
ffffffffc02007c0:	87b2                	mv	a5,a2
ffffffffc02007c2:	a029                	j	ffffffffc02007cc <slub_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc02007c4:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02007c8:	00d77763          	bgeu	a4,a3,ffffffffc02007d6 <slub_alloc_pages+0x34>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02007cc:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02007ce:	fec79be3          	bne	a5,a2,ffffffffc02007c4 <slub_alloc_pages+0x22>
        return NULL;
ffffffffc02007d2:	4501                	li	a0,0
}
ffffffffc02007d4:	8082                	ret
        if (page->property > n) {
ffffffffc02007d6:	ff87a303          	lw	t1,-8(a5)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02007da:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02007de:	0087b883          	ld	a7,8(a5)
ffffffffc02007e2:	02031713          	slli	a4,t1,0x20
ffffffffc02007e6:	9301                	srli	a4,a4,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02007e8:	01183423          	sd	a7,8(a6)
    next->prev = prev;
ffffffffc02007ec:	0108b023          	sd	a6,0(a7)
        struct Page *p = le2page(le, page_link);
ffffffffc02007f0:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc02007f4:	02e6fb63          	bgeu	a3,a4,ffffffffc020082a <slub_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc02007f8:	00269713          	slli	a4,a3,0x2
ffffffffc02007fc:	9736                	add	a4,a4,a3
ffffffffc02007fe:	070e                	slli	a4,a4,0x3
ffffffffc0200800:	972a                	add	a4,a4,a0
            SetPageProperty(p);
ffffffffc0200802:	00873e03          	ld	t3,8(a4)
            p->property = page->property - n;
ffffffffc0200806:	40d3033b          	subw	t1,t1,a3
ffffffffc020080a:	00672823          	sw	t1,16(a4)
            SetPageProperty(p);
ffffffffc020080e:	002e6313          	ori	t1,t3,2
ffffffffc0200812:	00673423          	sd	t1,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200816:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc020081a:	0068b023          	sd	t1,0(a7)
ffffffffc020081e:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc0200822:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc0200826:	01073c23          	sd	a6,24(a4)
        ClearPageProperty(page);
ffffffffc020082a:	ff07b703          	ld	a4,-16(a5)
        nr_free -= n;
ffffffffc020082e:	9d95                	subw	a1,a1,a3
ffffffffc0200830:	ca0c                	sw	a1,16(a2)
        ClearPageProperty(page);
ffffffffc0200832:	9b75                	andi	a4,a4,-3
ffffffffc0200834:	fee7b823          	sd	a4,-16(a5)
ffffffffc0200838:	8082                	ret
static struct Page *slub_alloc_pages(size_t n) {
ffffffffc020083a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020083c:	00001697          	auipc	a3,0x1
ffffffffc0200840:	2b468693          	addi	a3,a3,692 # ffffffffc0201af0 <etext+0x39a>
ffffffffc0200844:	00001617          	auipc	a2,0x1
ffffffffc0200848:	2b460613          	addi	a2,a2,692 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc020084c:	03b00593          	li	a1,59
ffffffffc0200850:	00001517          	auipc	a0,0x1
ffffffffc0200854:	2c050513          	addi	a0,a0,704 # ffffffffc0201b10 <etext+0x3ba>
static struct Page *slub_alloc_pages(size_t n) {
ffffffffc0200858:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020085a:	96fff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc020085e <slub_free_pages.part.0>:
    for (; p != base + n; p++) {
ffffffffc020085e:	00259713          	slli	a4,a1,0x2
ffffffffc0200862:	972e                	add	a4,a4,a1
ffffffffc0200864:	070e                	slli	a4,a4,0x3
ffffffffc0200866:	00e506b3          	add	a3,a0,a4
ffffffffc020086a:	87aa                	mv	a5,a0
ffffffffc020086c:	cf09                	beqz	a4,ffffffffc0200886 <slub_free_pages.part.0+0x28>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020086e:	6798                	ld	a4,8(a5)
ffffffffc0200870:	8b0d                	andi	a4,a4,3
ffffffffc0200872:	10071c63          	bnez	a4,ffffffffc020098a <slub_free_pages.part.0+0x12c>
        p->flags = 0;
ffffffffc0200876:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020087a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc020087e:	02878793          	addi	a5,a5,40
ffffffffc0200882:	fed796e3          	bne	a5,a3,ffffffffc020086e <slub_free_pages.part.0+0x10>
    SetPageProperty(base);
ffffffffc0200886:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc020088a:	00006717          	auipc	a4,0x6
ffffffffc020088e:	91e72703          	lw	a4,-1762(a4) # ffffffffc02061a8 <free_area+0x10>
ffffffffc0200892:	00006697          	auipc	a3,0x6
ffffffffc0200896:	90668693          	addi	a3,a3,-1786 # ffffffffc0206198 <free_area>
    return list->next == list;
ffffffffc020089a:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc020089c:	0028e613          	ori	a2,a7,2
    base->property = n;
ffffffffc02008a0:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02008a2:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc02008a4:	9f2d                	addw	a4,a4,a1
ffffffffc02008a6:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02008a8:	0cd78663          	beq	a5,a3,ffffffffc0200974 <slub_free_pages.part.0+0x116>
            struct Page* page = le2page(le, page_link);
ffffffffc02008ac:	fe878713          	addi	a4,a5,-24
ffffffffc02008b0:	4801                	li	a6,0
ffffffffc02008b2:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02008b6:	00e56a63          	bltu	a0,a4,ffffffffc02008ca <slub_free_pages.part.0+0x6c>
    return listelm->next;
ffffffffc02008ba:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02008bc:	06d70363          	beq	a4,a3,ffffffffc0200922 <slub_free_pages.part.0+0xc4>
    struct Page *p = base;
ffffffffc02008c0:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02008c2:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02008c6:	fee57ae3          	bgeu	a0,a4,ffffffffc02008ba <slub_free_pages.part.0+0x5c>
ffffffffc02008ca:	00080463          	beqz	a6,ffffffffc02008d2 <slub_free_pages.part.0+0x74>
ffffffffc02008ce:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02008d2:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc02008d6:	e390                	sd	a2,0(a5)
ffffffffc02008d8:	00c83423          	sd	a2,8(a6)
    elm->prev = prev;
ffffffffc02008dc:	01053c23          	sd	a6,24(a0)
    elm->next = next;
ffffffffc02008e0:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc02008e2:	02d80063          	beq	a6,a3,ffffffffc0200902 <slub_free_pages.part.0+0xa4>
        if (p + p->property == base) {
ffffffffc02008e6:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc02008ea:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc02008ee:	020e1613          	slli	a2,t3,0x20
ffffffffc02008f2:	9201                	srli	a2,a2,0x20
ffffffffc02008f4:	00261713          	slli	a4,a2,0x2
ffffffffc02008f8:	9732                	add	a4,a4,a2
ffffffffc02008fa:	070e                	slli	a4,a4,0x3
ffffffffc02008fc:	971a                	add	a4,a4,t1
ffffffffc02008fe:	04e50d63          	beq	a0,a4,ffffffffc0200958 <slub_free_pages.part.0+0xfa>
    if (le != &free_list) {
ffffffffc0200902:	00d78f63          	beq	a5,a3,ffffffffc0200920 <slub_free_pages.part.0+0xc2>
        if (base + base->property == p) {
ffffffffc0200906:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0200908:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc020090c:	02059613          	slli	a2,a1,0x20
ffffffffc0200910:	9201                	srli	a2,a2,0x20
ffffffffc0200912:	00261713          	slli	a4,a2,0x2
ffffffffc0200916:	9732                	add	a4,a4,a2
ffffffffc0200918:	070e                	slli	a4,a4,0x3
ffffffffc020091a:	972a                	add	a4,a4,a0
ffffffffc020091c:	00e68d63          	beq	a3,a4,ffffffffc0200936 <slub_free_pages.part.0+0xd8>
ffffffffc0200920:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200922:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200924:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200926:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200928:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020092a:	8332                	mv	t1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020092c:	04d70b63          	beq	a4,a3,ffffffffc0200982 <slub_free_pages.part.0+0x124>
ffffffffc0200930:	4805                	li	a6,1
    struct Page *p = base;
ffffffffc0200932:	87ba                	mv	a5,a4
ffffffffc0200934:	b779                	j	ffffffffc02008c2 <slub_free_pages.part.0+0x64>
            base->property += p->property;
ffffffffc0200936:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc020093a:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020093e:	0007b803          	ld	a6,0(a5)
ffffffffc0200942:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200944:	9ead                	addw	a3,a3,a1
ffffffffc0200946:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0200948:	9b75                	andi	a4,a4,-3
ffffffffc020094a:	fee7b823          	sd	a4,-16(a5)
    prev->next = next;
ffffffffc020094e:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200952:	01063023          	sd	a6,0(a2)
ffffffffc0200956:	8082                	ret
            p->property += base->property;
ffffffffc0200958:	01c585bb          	addw	a1,a1,t3
ffffffffc020095c:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200960:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200964:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200968:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc020096c:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200970:	851a                	mv	a0,t1
ffffffffc0200972:	bf41                	j	ffffffffc0200902 <slub_free_pages.part.0+0xa4>
        list_add(&free_list, &(base->page_link));
ffffffffc0200974:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200978:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020097a:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020097c:	e398                	sd	a4,0(a5)
ffffffffc020097e:	e798                	sd	a4,8(a5)
    if (le != &free_list) {
ffffffffc0200980:	8082                	ret
    return listelm->prev;
ffffffffc0200982:	883e                	mv	a6,a5
ffffffffc0200984:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200986:	87b6                	mv	a5,a3
ffffffffc0200988:	bfa9                	j	ffffffffc02008e2 <slub_free_pages.part.0+0x84>
static void slub_free_pages(struct Page *base, size_t n) {
ffffffffc020098a:	1141                	addi	sp,sp,-16
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020098c:	00001697          	auipc	a3,0x1
ffffffffc0200990:	19c68693          	addi	a3,a3,412 # ffffffffc0201b28 <etext+0x3d2>
ffffffffc0200994:	00001617          	auipc	a2,0x1
ffffffffc0200998:	16460613          	addi	a2,a2,356 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc020099c:	05b00593          	li	a1,91
ffffffffc02009a0:	00001517          	auipc	a0,0x1
ffffffffc02009a4:	17050513          	addi	a0,a0,368 # ffffffffc0201b10 <etext+0x3ba>
static void slub_free_pages(struct Page *base, size_t n) {
ffffffffc02009a8:	e406                	sd	ra,8(sp)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02009aa:	81fff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc02009ae <slub_free_pages>:
    assert(n > 0);
ffffffffc02009ae:	c191                	beqz	a1,ffffffffc02009b2 <slub_free_pages+0x4>
ffffffffc02009b0:	b57d                	j	ffffffffc020085e <slub_free_pages.part.0>
static void slub_free_pages(struct Page *base, size_t n) {
ffffffffc02009b2:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02009b4:	00001697          	auipc	a3,0x1
ffffffffc02009b8:	13c68693          	addi	a3,a3,316 # ffffffffc0201af0 <etext+0x39a>
ffffffffc02009bc:	00001617          	auipc	a2,0x1
ffffffffc02009c0:	13c60613          	addi	a2,a2,316 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc02009c4:	05800593          	li	a1,88
ffffffffc02009c8:	00001517          	auipc	a0,0x1
ffffffffc02009cc:	14850513          	addi	a0,a0,328 # ffffffffc0201b10 <etext+0x3ba>
static void slub_free_pages(struct Page *base, size_t n) {
ffffffffc02009d0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02009d2:	ff6ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc02009d6 <slub_init_memmap>:
static void slub_init_memmap(struct Page *base, size_t n) {
ffffffffc02009d6:	1141                	addi	sp,sp,-16
ffffffffc02009d8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02009da:	c9e9                	beqz	a1,ffffffffc0200aac <slub_init_memmap+0xd6>
    for (; p != base + n; p++) {
ffffffffc02009dc:	00259713          	slli	a4,a1,0x2
ffffffffc02009e0:	972e                	add	a4,a4,a1
ffffffffc02009e2:	070e                	slli	a4,a4,0x3
ffffffffc02009e4:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02009e8:	87aa                	mv	a5,a0
    for (; p != base + n; p++) {
ffffffffc02009ea:	cf11                	beqz	a4,ffffffffc0200a06 <slub_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc02009ec:	6798                	ld	a4,8(a5)
ffffffffc02009ee:	8b05                	andi	a4,a4,1
ffffffffc02009f0:	cf51                	beqz	a4,ffffffffc0200a8c <slub_init_memmap+0xb6>
        p->flags = p->property = 0;
ffffffffc02009f2:	0007a823          	sw	zero,16(a5)
ffffffffc02009f6:	0007b423          	sd	zero,8(a5)
ffffffffc02009fa:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc02009fe:	02878793          	addi	a5,a5,40
ffffffffc0200a02:	fed795e3          	bne	a5,a3,ffffffffc02009ec <slub_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200a06:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200a08:	00005717          	auipc	a4,0x5
ffffffffc0200a0c:	7a072703          	lw	a4,1952(a4) # ffffffffc02061a8 <free_area+0x10>
ffffffffc0200a10:	00005697          	auipc	a3,0x5
ffffffffc0200a14:	78868693          	addi	a3,a3,1928 # ffffffffc0206198 <free_area>
    return list->next == list;
ffffffffc0200a18:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200a1a:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200a1e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200a20:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200a22:	9f2d                	addw	a4,a4,a1
ffffffffc0200a24:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200a26:	04d78663          	beq	a5,a3,ffffffffc0200a72 <slub_init_memmap+0x9c>
            struct Page* page = le2page(le, page_link);
ffffffffc0200a2a:	fe878713          	addi	a4,a5,-24
ffffffffc0200a2e:	4581                	li	a1,0
ffffffffc0200a30:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200a34:	00e56a63          	bltu	a0,a4,ffffffffc0200a48 <slub_init_memmap+0x72>
    return listelm->next;
ffffffffc0200a38:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200a3a:	02d70263          	beq	a4,a3,ffffffffc0200a5e <slub_init_memmap+0x88>
    struct Page *p = base;
ffffffffc0200a3e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200a40:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200a44:	fee57ae3          	bgeu	a0,a4,ffffffffc0200a38 <slub_init_memmap+0x62>
ffffffffc0200a48:	c199                	beqz	a1,ffffffffc0200a4e <slub_init_memmap+0x78>
ffffffffc0200a4a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200a4e:	6398                	ld	a4,0(a5)
}
ffffffffc0200a50:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200a52:	e390                	sd	a2,0(a5)
ffffffffc0200a54:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0200a56:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0200a58:	f11c                	sd	a5,32(a0)
ffffffffc0200a5a:	0141                	addi	sp,sp,16
ffffffffc0200a5c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200a5e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200a60:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200a62:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200a64:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200a66:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200a68:	00d70e63          	beq	a4,a3,ffffffffc0200a84 <slub_init_memmap+0xae>
ffffffffc0200a6c:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0200a6e:	87ba                	mv	a5,a4
ffffffffc0200a70:	bfc1                	j	ffffffffc0200a40 <slub_init_memmap+0x6a>
}
ffffffffc0200a72:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200a74:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200a78:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200a7a:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200a7c:	e398                	sd	a4,0(a5)
ffffffffc0200a7e:	e798                	sd	a4,8(a5)
}
ffffffffc0200a80:	0141                	addi	sp,sp,16
ffffffffc0200a82:	8082                	ret
ffffffffc0200a84:	60a2                	ld	ra,8(sp)
ffffffffc0200a86:	e290                	sd	a2,0(a3)
ffffffffc0200a88:	0141                	addi	sp,sp,16
ffffffffc0200a8a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200a8c:	00001697          	auipc	a3,0x1
ffffffffc0200a90:	0c468693          	addi	a3,a3,196 # ffffffffc0201b50 <etext+0x3fa>
ffffffffc0200a94:	00001617          	auipc	a2,0x1
ffffffffc0200a98:	06460613          	addi	a2,a2,100 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc0200a9c:	02300593          	li	a1,35
ffffffffc0200aa0:	00001517          	auipc	a0,0x1
ffffffffc0200aa4:	07050513          	addi	a0,a0,112 # ffffffffc0201b10 <etext+0x3ba>
ffffffffc0200aa8:	f20ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200aac:	00001697          	auipc	a3,0x1
ffffffffc0200ab0:	04468693          	addi	a3,a3,68 # ffffffffc0201af0 <etext+0x39a>
ffffffffc0200ab4:	00001617          	auipc	a2,0x1
ffffffffc0200ab8:	04460613          	addi	a2,a2,68 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc0200abc:	02000593          	li	a1,32
ffffffffc0200ac0:	00001517          	auipc	a0,0x1
ffffffffc0200ac4:	05050513          	addi	a0,a0,80 # ffffffffc0201b10 <etext+0x3ba>
ffffffffc0200ac8:	f00ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200acc <slub_malloc>:
        obj, sp, (unsigned)cache->obj_size, (unsigned)sp->inuse, (unsigned)cache->objs_per_page);
}

// 通用分配接口
void *slub_malloc(size_t size) {
    if (size == 0) return NULL;
ffffffffc0200acc:	12050a63          	beqz	a0,ffffffffc0200c00 <slub_malloc+0x134>
void *slub_malloc(size_t size) {
ffffffffc0200ad0:	7139                	addi	sp,sp,-64
ffffffffc0200ad2:	fc06                	sd	ra,56(sp)

    if (size > SLUB_MAX_SIZE) {
ffffffffc0200ad4:	40000713          	li	a4,1024
ffffffffc0200ad8:	00002797          	auipc	a5,0x2
ffffffffc0200adc:	8b878793          	addi	a5,a5,-1864 # ffffffffc0202390 <slub_sizes>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0200ae0:	4681                	li	a3,0
ffffffffc0200ae2:	4621                	li	a2,8
    if (size > SLUB_MAX_SIZE) {
ffffffffc0200ae4:	0aa76963          	bltu	a4,a0,ffffffffc0200b96 <slub_malloc+0xca>
        if (size <= slub_sizes[i]) return i;
ffffffffc0200ae8:	6398                	ld	a4,0(a5)
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0200aea:	07a1                	addi	a5,a5,8
        if (size <= slub_sizes[i]) return i;
ffffffffc0200aec:	00a77a63          	bgeu	a4,a0,ffffffffc0200b00 <slub_malloc+0x34>
    for (int i = 0; i < SLUB_SIZE_CLASSES; i++)
ffffffffc0200af0:	2685                	addiw	a3,a3,1
ffffffffc0200af2:	fec69be3          	bne	a3,a2,ffffffffc0200ae8 <slub_malloc+0x1c>
    }

    int idx = slub_cache_index(size);
    if (idx < 0) return NULL;
    return slub_cache_alloc(&slub_caches[idx]);
}
ffffffffc0200af6:	70e2                	ld	ra,56(sp)
    if (size == 0) return NULL;
ffffffffc0200af8:	4581                	li	a1,0
}
ffffffffc0200afa:	852e                	mv	a0,a1
ffffffffc0200afc:	6121                	addi	sp,sp,64
ffffffffc0200afe:	8082                	ret
    return slub_cache_alloc(&slub_caches[idx]);
ffffffffc0200b00:	00169893          	slli	a7,a3,0x1
ffffffffc0200b04:	00d887b3          	add	a5,a7,a3
ffffffffc0200b08:	0792                	slli	a5,a5,0x4
ffffffffc0200b0a:	00005317          	auipc	t1,0x5
ffffffffc0200b0e:	50e30313          	addi	t1,t1,1294 # ffffffffc0206018 <slub_caches>
ffffffffc0200b12:	00f30eb3          	add	t4,t1,a5
    return list->next == list;
ffffffffc0200b16:	018eb703          	ld	a4,24(t4)
    if (!list_empty(&cache->partial)) {
ffffffffc0200b1a:	01078e13          	addi	t3,a5,16
ffffffffc0200b1e:	9e1a                	add	t3,t3,t1
        sp = le2slubpage(list_next(&cache->partial), page_link);
ffffffffc0200b20:	fe070813          	addi	a6,a4,-32
    if (!list_empty(&cache->partial)) {
ffffffffc0200b24:	0aee0f63          	beq	t3,a4,ffffffffc0200be2 <slub_malloc+0x116>
    if (!sp->freelist) return NULL;
ffffffffc0200b28:	01083583          	ld	a1,16(a6)
ffffffffc0200b2c:	d5e9                	beqz	a1,ffffffffc0200af6 <slub_malloc+0x2a>
    sp->freelist = *(void **)obj;
ffffffffc0200b2e:	6190                	ld	a2,0(a1)
    sp->inuse++;
ffffffffc0200b30:	01883703          	ld	a4,24(a6)
    if (sp->inuse < cache->objs_per_page)
ffffffffc0200b34:	00d887b3          	add	a5,a7,a3
    sp->freelist = *(void **)obj;
ffffffffc0200b38:	00c83823          	sd	a2,16(a6)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b3c:	02083503          	ld	a0,32(a6)
ffffffffc0200b40:	02883603          	ld	a2,40(a6)
    if (sp->inuse < cache->objs_per_page)
ffffffffc0200b44:	0792                	slli	a5,a5,0x4
    sp->inuse++;
ffffffffc0200b46:	0705                	addi	a4,a4,1
    if (sp->inuse < cache->objs_per_page)
ffffffffc0200b48:	979a                	add	a5,a5,t1
ffffffffc0200b4a:	679c                	ld	a5,8(a5)
    sp->inuse++;
ffffffffc0200b4c:	00e83c23          	sd	a4,24(a6)
    prev->next = next;
ffffffffc0200b50:	e510                	sd	a2,8(a0)
    next->prev = prev;
ffffffffc0200b52:	e208                	sd	a0,0(a2)
    if (sp->inuse < cache->objs_per_page)
ffffffffc0200b54:	00f77d63          	bgeu	a4,a5,ffffffffc0200b6e <slub_malloc+0xa2>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b58:	018eb603          	ld	a2,24(t4)
        list_add(&cache->partial, &sp->page_link);
ffffffffc0200b5c:	02080513          	addi	a0,a6,32
    prev->next = next->prev = elm;
ffffffffc0200b60:	e208                	sd	a0,0(a2)
ffffffffc0200b62:	00aebc23          	sd	a0,24(t4)
    elm->next = next;
ffffffffc0200b66:	02c83423          	sd	a2,40(a6)
    elm->prev = prev;
ffffffffc0200b6a:	03c83023          	sd	t3,32(a6)
        obj, sp, (unsigned)cache->obj_size, (unsigned)sp->inuse, (unsigned)cache->objs_per_page);
ffffffffc0200b6e:	98b6                	add	a7,a7,a3
ffffffffc0200b70:	0892                	slli	a7,a7,0x4
ffffffffc0200b72:	989a                	add	a7,a7,t1
    cprintf("[SLUB] 分配 obj=%p, slub_page=%p, obj_size=%u, inuse=%u/%u\n",
ffffffffc0200b74:	0008a683          	lw	a3,0(a7)
ffffffffc0200b78:	2781                	sext.w	a5,a5
ffffffffc0200b7a:	2701                	sext.w	a4,a4
ffffffffc0200b7c:	8642                	mv	a2,a6
ffffffffc0200b7e:	00001517          	auipc	a0,0x1
ffffffffc0200b82:	01250513          	addi	a0,a0,18 # ffffffffc0201b90 <etext+0x43a>
ffffffffc0200b86:	e42e                	sd	a1,8(sp)
ffffffffc0200b88:	dc0ff0ef          	jal	ffffffffc0200148 <cprintf>
    return obj;
ffffffffc0200b8c:	65a2                	ld	a1,8(sp)
}
ffffffffc0200b8e:	70e2                	ld	ra,56(sp)
ffffffffc0200b90:	852e                	mv	a0,a1
ffffffffc0200b92:	6121                	addi	sp,sp,64
ffffffffc0200b94:	8082                	ret
        size_t pages = (size + PGSIZE - 1) / PGSIZE;
ffffffffc0200b96:	6785                	lui	a5,0x1
ffffffffc0200b98:	17fd                	addi	a5,a5,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0200b9a:	953e                	add	a0,a0,a5
        struct Page *pg = slub_alloc_pages(pages);
ffffffffc0200b9c:	8131                	srli	a0,a0,0xc
ffffffffc0200b9e:	c05ff0ef          	jal	ffffffffc02007a2 <slub_alloc_pages>
        if (!pg) return NULL;
ffffffffc0200ba2:	d931                	beqz	a0,ffffffffc0200af6 <slub_malloc+0x2a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ba4:	00005697          	auipc	a3,0x5
ffffffffc0200ba8:	64c6b683          	ld	a3,1612(a3) # ffffffffc02061f0 <pages>
ffffffffc0200bac:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200bb0:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac6ad5>
ffffffffc0200bb4:	02079713          	slli	a4,a5,0x20
ffffffffc0200bb8:	40d505b3          	sub	a1,a0,a3
ffffffffc0200bbc:	973e                	add	a4,a4,a5
ffffffffc0200bbe:	858d                	srai	a1,a1,0x3
ffffffffc0200bc0:	02e585b3          	mul	a1,a1,a4
ffffffffc0200bc4:	00002717          	auipc	a4,0x2
ffffffffc0200bc8:	9d473703          	ld	a4,-1580(a4) # ffffffffc0202598 <nbase>
    return (void *)((uintptr_t)page2pa(page) + va_pa_offset);
ffffffffc0200bcc:	00005797          	auipc	a5,0x5
ffffffffc0200bd0:	6147b783          	ld	a5,1556(a5) # ffffffffc02061e0 <va_pa_offset>
}
ffffffffc0200bd4:	70e2                	ld	ra,56(sp)
ffffffffc0200bd6:	6121                	addi	sp,sp,64
ffffffffc0200bd8:	95ba                	add	a1,a1,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bda:	05b2                	slli	a1,a1,0xc
    return (void *)((uintptr_t)page2pa(page) + va_pa_offset);
ffffffffc0200bdc:	95be                	add	a1,a1,a5
}
ffffffffc0200bde:	852e                	mv	a0,a1
ffffffffc0200be0:	8082                	ret
    return list->next == list;
ffffffffc0200be2:	028eb803          	ld	a6,40(t4)
    } else if (!list_empty(&cache->empty)) {
ffffffffc0200be6:	02078793          	addi	a5,a5,32
ffffffffc0200bea:	979a                	add	a5,a5,t1
ffffffffc0200bec:	00f80d63          	beq	a6,a5,ffffffffc0200c06 <slub_malloc+0x13a>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200bf0:	00083703          	ld	a4,0(a6)
ffffffffc0200bf4:	00883783          	ld	a5,8(a6)
        sp = le2slubpage(list_next(&cache->empty), page_link);
ffffffffc0200bf8:	1801                	addi	a6,a6,-32
    prev->next = next;
ffffffffc0200bfa:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200bfc:	e398                	sd	a4,0(a5)
}
ffffffffc0200bfe:	b72d                	j	ffffffffc0200b28 <slub_malloc+0x5c>
    if (size == 0) return NULL;
ffffffffc0200c00:	4581                	li	a1,0
}
ffffffffc0200c02:	852e                	mv	a0,a1
ffffffffc0200c04:	8082                	ret
    struct Page *page = slub_alloc_pages(1);
ffffffffc0200c06:	4505                	li	a0,1
ffffffffc0200c08:	f046                	sd	a7,32(sp)
ffffffffc0200c0a:	ec72                	sd	t3,24(sp)
ffffffffc0200c0c:	e836                	sd	a3,16(sp)
ffffffffc0200c0e:	e476                	sd	t4,8(sp)
ffffffffc0200c10:	b93ff0ef          	jal	ffffffffc02007a2 <slub_alloc_pages>
    if (!page) return NULL;
ffffffffc0200c14:	ee0501e3          	beqz	a0,ffffffffc0200af6 <slub_malloc+0x2a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c18:	00005817          	auipc	a6,0x5
ffffffffc0200c1c:	5d883803          	ld	a6,1496(a6) # ffffffffc02061f0 <pages>
ffffffffc0200c20:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200c24:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac6ad5>
ffffffffc0200c28:	02079713          	slli	a4,a5,0x20
ffffffffc0200c2c:	41050833          	sub	a6,a0,a6
ffffffffc0200c30:	97ba                	add	a5,a5,a4
ffffffffc0200c32:	40385813          	srai	a6,a6,0x3
ffffffffc0200c36:	02f80833          	mul	a6,a6,a5
ffffffffc0200c3a:	00002717          	auipc	a4,0x2
ffffffffc0200c3e:	95e73703          	ld	a4,-1698(a4) # ffffffffc0202598 <nbase>
    return (void *)((uintptr_t)page2pa(page) + va_pa_offset);
ffffffffc0200c42:	00005797          	auipc	a5,0x5
ffffffffc0200c46:	59e7b783          	ld	a5,1438(a5) # ffffffffc02061e0 <va_pa_offset>
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc0200c4a:	6ea2                	ld	t4,8(sp)
ffffffffc0200c4c:	66c2                	ld	a3,16(sp)
ffffffffc0200c4e:	6e62                	ld	t3,24(sp)
ffffffffc0200c50:	008ebf03          	ld	t5,8(t4)
    uintptr_t aligned = ((uintptr_t)obj + cache->obj_size - 1) & ~(cache->obj_size - 1);
ffffffffc0200c54:	000eb603          	ld	a2,0(t4)
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc0200c58:	7882                	ld	a7,32(sp)
ffffffffc0200c5a:	983a                	add	a6,a6,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0200c5c:	0832                	slli	a6,a6,0xc
    return (void *)((uintptr_t)page2pa(page) + va_pa_offset);
ffffffffc0200c5e:	983e                	add	a6,a6,a5
    list_init(&sp->page_link);
ffffffffc0200c60:	02080793          	addi	a5,a6,32
    sp->page = page;
ffffffffc0200c64:	00a83023          	sd	a0,0(a6)
    sp->cache = cache;
ffffffffc0200c68:	01d83423          	sd	t4,8(a6)
    sp->inuse = 0;
ffffffffc0200c6c:	00083c23          	sd	zero,24(a6)
    elm->prev = elm->next = elm;
ffffffffc0200c70:	02f83423          	sd	a5,40(a6)
ffffffffc0200c74:	02f83023          	sd	a5,32(a6)
    sp->freelist = NULL;
ffffffffc0200c78:	00083823          	sd	zero,16(a6)
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc0200c7c:	020f0463          	beqz	t5,ffffffffc0200ca4 <slub_malloc+0x1d8>
    uintptr_t aligned = ((uintptr_t)obj + cache->obj_size - 1) & ~(cache->obj_size - 1);
ffffffffc0200c80:	00c807b3          	add	a5,a6,a2
ffffffffc0200c84:	40c00733          	neg	a4,a2
ffffffffc0200c88:	02f78793          	addi	a5,a5,47
ffffffffc0200c8c:	8ff9                	and	a5,a5,a4
    obj = (void *)aligned;
ffffffffc0200c8e:	4581                	li	a1,0
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc0200c90:	4701                	li	a4,0
ffffffffc0200c92:	a011                	j	ffffffffc0200c96 <slub_malloc+0x1ca>
ffffffffc0200c94:	97b2                	add	a5,a5,a2
        *(void **)obj = sp->freelist;
ffffffffc0200c96:	e38c                	sd	a1,0(a5)
    for (size_t i = 0; i < cache->objs_per_page; i++) {
ffffffffc0200c98:	0705                	addi	a4,a4,1
ffffffffc0200c9a:	85be                	mv	a1,a5
ffffffffc0200c9c:	feef1ce3          	bne	t5,a4,ffffffffc0200c94 <slub_malloc+0x1c8>
ffffffffc0200ca0:	00f83823          	sd	a5,16(a6)
        cprintf("[SLUB] 新建 slub_page: %p, cache obj_size=%u\n", sp, (unsigned)cache->obj_size);
ffffffffc0200ca4:	85c2                	mv	a1,a6
ffffffffc0200ca6:	2601                	sext.w	a2,a2
ffffffffc0200ca8:	00001517          	auipc	a0,0x1
ffffffffc0200cac:	eb850513          	addi	a0,a0,-328 # ffffffffc0201b60 <etext+0x40a>
ffffffffc0200cb0:	f446                	sd	a7,40(sp)
ffffffffc0200cb2:	f072                	sd	t3,32(sp)
ffffffffc0200cb4:	ec36                	sd	a3,24(sp)
ffffffffc0200cb6:	e876                	sd	t4,16(sp)
ffffffffc0200cb8:	e442                	sd	a6,8(sp)
ffffffffc0200cba:	c8eff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc0200cbe:	6822                	ld	a6,8(sp)
ffffffffc0200cc0:	6ec2                	ld	t4,16(sp)
ffffffffc0200cc2:	66e2                	ld	a3,24(sp)
ffffffffc0200cc4:	7e02                	ld	t3,32(sp)
ffffffffc0200cc6:	78a2                	ld	a7,40(sp)
ffffffffc0200cc8:	00005317          	auipc	t1,0x5
ffffffffc0200ccc:	35030313          	addi	t1,t1,848 # ffffffffc0206018 <slub_caches>
ffffffffc0200cd0:	bda1                	j	ffffffffc0200b28 <slub_malloc+0x5c>

ffffffffc0200cd2 <slub_free>:

// 通用释放接口
void slub_free(void *ptr) {
    if (!ptr) return;
ffffffffc0200cd2:	c941                	beqz	a0,ffffffffc0200d62 <slub_free+0x90>
    uintptr_t page_addr = (uintptr_t)ptr & ~(PGSIZE - 1);
ffffffffc0200cd4:	767d                	lui	a2,0xfffff
ffffffffc0200cd6:	8e69                	and	a2,a2,a0
    struct slub_page *sp = (struct slub_page *)page_addr;
    if (sp->cache)
ffffffffc0200cd8:	6614                	ld	a3,8(a2)
ffffffffc0200cda:	caa1                	beqz	a3,ffffffffc0200d2a <slub_free+0x58>
    *(void **)obj = sp->freelist;
ffffffffc0200cdc:	6a1c                	ld	a5,16(a2)
    sp->inuse--;
ffffffffc0200cde:	6e18                	ld	a4,24(a2)
    *(void **)obj = sp->freelist;
ffffffffc0200ce0:	e11c                	sd	a5,0(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ce2:	720c                	ld	a1,32(a2)
ffffffffc0200ce4:	761c                	ld	a5,40(a2)
    sp->inuse--;
ffffffffc0200ce6:	177d                	addi	a4,a4,-1
    sp->freelist = obj;
ffffffffc0200ce8:	ea08                	sd	a0,16(a2)
    sp->inuse--;
ffffffffc0200cea:	ee18                	sd	a4,24(a2)
    prev->next = next;
ffffffffc0200cec:	e59c                	sd	a5,8(a1)
    next->prev = prev;
ffffffffc0200cee:	e38c                	sd	a1,0(a5)
    if (sp->inuse == 0)
ffffffffc0200cf0:	c70d                	beqz	a4,ffffffffc0200d1a <slub_free+0x48>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200cf2:	6e8c                	ld	a1,24(a3)
        list_add(&cache->partial, &sp->page_link);
ffffffffc0200cf4:	02060793          	addi	a5,a2,32 # fffffffffffff020 <end+0x3fdf8e28>
ffffffffc0200cf8:	01068813          	addi	a6,a3,16
    prev->next = next->prev = elm;
ffffffffc0200cfc:	e19c                	sd	a5,0(a1)
ffffffffc0200cfe:	ee9c                	sd	a5,24(a3)
    cprintf("[SLUB] 释放 obj=%p, slub_page=%p, obj_size=%u, inuse=%u/%u\n",
ffffffffc0200d00:	469c                	lw	a5,8(a3)
ffffffffc0200d02:	4294                	lw	a3,0(a3)
ffffffffc0200d04:	2701                	sext.w	a4,a4
    elm->next = next;
ffffffffc0200d06:	f60c                	sd	a1,40(a2)
    elm->prev = prev;
ffffffffc0200d08:	03063023          	sd	a6,32(a2)
ffffffffc0200d0c:	85aa                	mv	a1,a0
ffffffffc0200d0e:	00001517          	auipc	a0,0x1
ffffffffc0200d12:	ec250513          	addi	a0,a0,-318 # ffffffffc0201bd0 <etext+0x47a>
ffffffffc0200d16:	c32ff06f          	j	ffffffffc0200148 <cprintf>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d1a:	768c                	ld	a1,40(a3)
        list_add(&cache->empty, &sp->page_link);
ffffffffc0200d1c:	02060793          	addi	a5,a2,32
ffffffffc0200d20:	02068813          	addi	a6,a3,32
    prev->next = next->prev = elm;
ffffffffc0200d24:	e19c                	sd	a5,0(a1)
ffffffffc0200d26:	f69c                	sd	a5,40(a3)
}
ffffffffc0200d28:	bfe1                	j	ffffffffc0200d00 <slub_free+0x2e>
    return pa2page((uintptr_t)kva - va_pa_offset);
ffffffffc0200d2a:	00005717          	auipc	a4,0x5
ffffffffc0200d2e:	4b673703          	ld	a4,1206(a4) # ffffffffc02061e0 <va_pa_offset>
    if (PPN(pa) >= npage) {
ffffffffc0200d32:	00005797          	auipc	a5,0x5
ffffffffc0200d36:	4b67b783          	ld	a5,1206(a5) # ffffffffc02061e8 <npage>
ffffffffc0200d3a:	8e19                	sub	a2,a2,a4
ffffffffc0200d3c:	8231                	srli	a2,a2,0xc
ffffffffc0200d3e:	02f67363          	bgeu	a2,a5,ffffffffc0200d64 <slub_free+0x92>
    return &pages[PPN(pa) - nbase];
ffffffffc0200d42:	00002797          	auipc	a5,0x2
ffffffffc0200d46:	8567b783          	ld	a5,-1962(a5) # ffffffffc0202598 <nbase>
ffffffffc0200d4a:	00005517          	auipc	a0,0x5
ffffffffc0200d4e:	4a653503          	ld	a0,1190(a0) # ffffffffc02061f0 <pages>
ffffffffc0200d52:	4585                	li	a1,1
ffffffffc0200d54:	8e1d                	sub	a2,a2,a5
ffffffffc0200d56:	00261793          	slli	a5,a2,0x2
ffffffffc0200d5a:	97b2                	add	a5,a5,a2
ffffffffc0200d5c:	078e                	slli	a5,a5,0x3
ffffffffc0200d5e:	953e                	add	a0,a0,a5
ffffffffc0200d60:	bcfd                	j	ffffffffc020085e <slub_free_pages.part.0>
ffffffffc0200d62:	8082                	ret
void slub_free(void *ptr) {
ffffffffc0200d64:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0200d66:	00001617          	auipc	a2,0x1
ffffffffc0200d6a:	cfa60613          	addi	a2,a2,-774 # ffffffffc0201a60 <etext+0x30a>
ffffffffc0200d6e:	06a00593          	li	a1,106
ffffffffc0200d72:	00001517          	auipc	a0,0x1
ffffffffc0200d76:	d0e50513          	addi	a0,a0,-754 # ffffffffc0201a80 <etext+0x32a>
ffffffffc0200d7a:	e406                	sd	ra,8(sp)
ffffffffc0200d7c:	c4cff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200d80 <slub_check>:





static void slub_check(void) {
ffffffffc0200d80:	712d                	addi	sp,sp,-288
    cprintf("========== [SLUB Allocator Comprehensive Test] ==========\n\n");
ffffffffc0200d82:	00001517          	auipc	a0,0x1
ffffffffc0200d86:	ea650513          	addi	a0,a0,-346 # ffffffffc0201c28 <etext+0x4d2>
static void slub_check(void) {
ffffffffc0200d8a:	ee06                	sd	ra,280(sp)
ffffffffc0200d8c:	ea22                	sd	s0,272(sp)
ffffffffc0200d8e:	f9d2                	sd	s4,240(sp)
ffffffffc0200d90:	e626                	sd	s1,264(sp)
ffffffffc0200d92:	e24a                	sd	s2,256(sp)
ffffffffc0200d94:	fdce                	sd	s3,248(sp)
ffffffffc0200d96:	f5d6                	sd	s5,232(sp)
    cprintf("========== [SLUB Allocator Comprehensive Test] ==========\n\n");
ffffffffc0200d98:	bb0ff0ef          	jal	ffffffffc0200148 <cprintf>

    /* --- 初始状态 --- */
    cprintf("[Init] 当前总空闲页: %d\n", slub_nr_free_pages());
ffffffffc0200d9c:	00005597          	auipc	a1,0x5
ffffffffc0200da0:	40c5e583          	lwu	a1,1036(a1) # ffffffffc02061a8 <free_area+0x10>
ffffffffc0200da4:	00001517          	auipc	a0,0x1
ffffffffc0200da8:	ec450513          	addi	a0,a0,-316 # ffffffffc0201c68 <etext+0x512>
    return nr_free;
ffffffffc0200dac:	00005a17          	auipc	s4,0x5
ffffffffc0200db0:	3eca0a13          	addi	s4,s4,1004 # ffffffffc0206198 <free_area>
    cprintf("[Init] 当前总空闲页: %d\n", slub_nr_free_pages());
ffffffffc0200db4:	b94ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("[Init] 空闲链表分布(property): ");
ffffffffc0200db8:	00001517          	auipc	a0,0x1
ffffffffc0200dbc:	ed050513          	addi	a0,a0,-304 # ffffffffc0201c88 <etext+0x532>
ffffffffc0200dc0:	b88ff0ef          	jal	ffffffffc0200148 <cprintf>
    return listelm->next;
ffffffffc0200dc4:	008a3403          	ld	s0,8(s4)
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dc8:	01440d63          	beq	s0,s4,ffffffffc0200de2 <slub_check+0x62>
        struct Page *p = le2page(le, page_link);
        cprintf("%d ", p->property);
ffffffffc0200dcc:	ff842583          	lw	a1,-8(s0)
ffffffffc0200dd0:	00001517          	auipc	a0,0x1
ffffffffc0200dd4:	f1850513          	addi	a0,a0,-232 # ffffffffc0201ce8 <etext+0x592>
ffffffffc0200dd8:	b70ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc0200ddc:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dde:	ff4417e3          	bne	s0,s4,ffffffffc0200dcc <slub_check+0x4c>
    }
    cprintf("\n\n");
ffffffffc0200de2:	00001517          	auipc	a0,0x1
ffffffffc0200de6:	ece50513          	addi	a0,a0,-306 # ffffffffc0201cb0 <etext+0x55a>
ffffffffc0200dea:	b5eff0ef          	jal	ffffffffc0200148 <cprintf>

    /* --- 边界情况 --- */
    cprintf(">>> [Boundary Check]\n");
ffffffffc0200dee:	00001517          	auipc	a0,0x1
ffffffffc0200df2:	eca50513          	addi	a0,a0,-310 # ffffffffc0201cb8 <etext+0x562>
ffffffffc0200df6:	b52ff0ef          	jal	ffffffffc0200148 <cprintf>
    void *obj = slub_malloc(0);
    assert(obj == NULL);
    cprintf("[OK] malloc(0) -> NULL\n");
ffffffffc0200dfa:	00001517          	auipc	a0,0x1
ffffffffc0200dfe:	ed650513          	addi	a0,a0,-298 # ffffffffc0201cd0 <etext+0x57a>
ffffffffc0200e02:	b46ff0ef          	jal	ffffffffc0200148 <cprintf>

    void *big = slub_malloc(SLUB_MAX_SIZE + 1);
ffffffffc0200e06:	40100513          	li	a0,1025
ffffffffc0200e0a:	cc3ff0ef          	jal	ffffffffc0200acc <slub_malloc>
ffffffffc0200e0e:	842a                	mv	s0,a0
    if (big) {
ffffffffc0200e10:	3c050963          	beqz	a0,ffffffffc02011e2 <slub_check+0x462>
        cprintf("[OK] 大对象分配成功: %p (> SLUB_MAX_SIZE)\n", big);
ffffffffc0200e14:	85aa                	mv	a1,a0
ffffffffc0200e16:	00001517          	auipc	a0,0x1
ffffffffc0200e1a:	eda50513          	addi	a0,a0,-294 # ffffffffc0201cf0 <etext+0x59a>
ffffffffc0200e1e:	b2aff0ef          	jal	ffffffffc0200148 <cprintf>
        slub_free(big);
ffffffffc0200e22:	8522                	mv	a0,s0
ffffffffc0200e24:	eafff0ef          	jal	ffffffffc0200cd2 <slub_free>
        cprintf("[OK] 大对象释放成功\n");
ffffffffc0200e28:	00001517          	auipc	a0,0x1
ffffffffc0200e2c:	f0050513          	addi	a0,a0,-256 # ffffffffc0201d28 <etext+0x5d2>
ffffffffc0200e30:	b18ff0ef          	jal	ffffffffc0200148 <cprintf>
    } else {
        cprintf("[WARN] 大对象分配失败 (无可用内存)\n");
    }
    cprintf("[Boundary Check Completed]\n\n");
ffffffffc0200e34:	00001517          	auipc	a0,0x1
ffffffffc0200e38:	f4450513          	addi	a0,a0,-188 # ffffffffc0201d78 <etext+0x622>
ffffffffc0200e3c:	b0cff0ef          	jal	ffffffffc0200148 <cprintf>

    /* --- 小对象测试 --- */
    cprintf(">>> [Small Object Alloc/Free Test]\n");
ffffffffc0200e40:	00001517          	auipc	a0,0x1
ffffffffc0200e44:	f5850513          	addi	a0,a0,-168 # ffffffffc0201d98 <etext+0x642>
ffffffffc0200e48:	b00ff0ef          	jal	ffffffffc0200148 <cprintf>
    size_t test_sizes[] = {8, 16, 32, 64, 128, 256, 512};
ffffffffc0200e4c:	00001797          	auipc	a5,0x1
ffffffffc0200e50:	58478793          	addi	a5,a5,1412 # ffffffffc02023d0 <slub_sizes+0x40>
ffffffffc0200e54:	0007b803          	ld	a6,0(a5)
ffffffffc0200e58:	6788                	ld	a0,8(a5)
ffffffffc0200e5a:	6b8c                	ld	a1,16(a5)
ffffffffc0200e5c:	6f90                	ld	a2,24(a5)
ffffffffc0200e5e:	7394                	ld	a3,32(a5)
ffffffffc0200e60:	7798                	ld	a4,40(a5)
ffffffffc0200e62:	7b9c                	ld	a5,48(a5)
ffffffffc0200e64:	e442                	sd	a6,8(sp)
ffffffffc0200e66:	e82a                	sd	a0,16(sp)
ffffffffc0200e68:	ec2e                	sd	a1,24(sp)
ffffffffc0200e6a:	f032                	sd	a2,32(sp)
ffffffffc0200e6c:	f436                	sd	a3,40(sp)
ffffffffc0200e6e:	f83a                	sd	a4,48(sp)
ffffffffc0200e70:	fc3e                	sd	a5,56(sp)
    for (int i = 0; i < sizeof(test_sizes)/sizeof(test_sizes[0]); i++) {
ffffffffc0200e72:	00810a93          	addi	s5,sp,8
ffffffffc0200e76:	04010993          	addi	s3,sp,64
        size_t sz = test_sizes[i];
        void *ptr = slub_malloc(sz);
        assert(ptr != NULL);
        memset(ptr, 0xAB, sz);
ffffffffc0200e7a:	0ab00413          	li	s0,171
        size_t sz = test_sizes[i];
ffffffffc0200e7e:	000ab483          	ld	s1,0(s5)
        void *ptr = slub_malloc(sz);
ffffffffc0200e82:	8526                	mv	a0,s1
ffffffffc0200e84:	c49ff0ef          	jal	ffffffffc0200acc <slub_malloc>
ffffffffc0200e88:	892a                	mv	s2,a0
        assert(ptr != NULL);
ffffffffc0200e8a:	3e050263          	beqz	a0,ffffffffc020126e <slub_check+0x4ee>
        memset(ptr, 0xAB, sz);
ffffffffc0200e8e:	8626                	mv	a2,s1
ffffffffc0200e90:	0ab00593          	li	a1,171
ffffffffc0200e94:	0b1000ef          	jal	ffffffffc0201744 <memset>
        cprintf("[ALLOC] %d bytes @ %p\n", sz, ptr);
ffffffffc0200e98:	864a                	mv	a2,s2
ffffffffc0200e9a:	85a6                	mv	a1,s1
ffffffffc0200e9c:	00001517          	auipc	a0,0x1
ffffffffc0200ea0:	f3450513          	addi	a0,a0,-204 # ffffffffc0201dd0 <etext+0x67a>
ffffffffc0200ea4:	aa4ff0ef          	jal	ffffffffc0200148 <cprintf>
        for (size_t j = 0; j < sz; j++) assert(((uint8_t*)ptr)[j] == 0xAB);
ffffffffc0200ea8:	c899                	beqz	s1,ffffffffc0200ebe <slub_check+0x13e>
ffffffffc0200eaa:	87ca                	mv	a5,s2
ffffffffc0200eac:	009906b3          	add	a3,s2,s1
ffffffffc0200eb0:	0007c703          	lbu	a4,0(a5)
ffffffffc0200eb4:	36871d63          	bne	a4,s0,ffffffffc020122e <slub_check+0x4ae>
ffffffffc0200eb8:	0785                	addi	a5,a5,1
ffffffffc0200eba:	fed79be3          	bne	a5,a3,ffffffffc0200eb0 <slub_check+0x130>
        slub_free(ptr);
ffffffffc0200ebe:	854a                	mv	a0,s2
ffffffffc0200ec0:	e13ff0ef          	jal	ffffffffc0200cd2 <slub_free>
        cprintf("[FREE ] %d bytes @ %p\n", sz, ptr);
ffffffffc0200ec4:	864a                	mv	a2,s2
ffffffffc0200ec6:	85a6                	mv	a1,s1
ffffffffc0200ec8:	00001517          	auipc	a0,0x1
ffffffffc0200ecc:	f4050513          	addi	a0,a0,-192 # ffffffffc0201e08 <etext+0x6b2>
    for (int i = 0; i < sizeof(test_sizes)/sizeof(test_sizes[0]); i++) {
ffffffffc0200ed0:	0aa1                	addi	s5,s5,8
        cprintf("[FREE ] %d bytes @ %p\n", sz, ptr);
ffffffffc0200ed2:	a76ff0ef          	jal	ffffffffc0200148 <cprintf>
    for (int i = 0; i < sizeof(test_sizes)/sizeof(test_sizes[0]); i++) {
ffffffffc0200ed6:	fb5994e3          	bne	s3,s5,ffffffffc0200e7e <slub_check+0xfe>
    }
    cprintf("[Small Object Test Passed]\n\n");
ffffffffc0200eda:	00001517          	auipc	a0,0x1
ffffffffc0200ede:	f4650513          	addi	a0,a0,-186 # ffffffffc0201e20 <etext+0x6ca>
ffffffffc0200ee2:	a66ff0ef          	jal	ffffffffc0200148 <cprintf>

    /* --- 小对象复用性测试 --- */
    cprintf(">>> [Reuse Check]\n");
ffffffffc0200ee6:	00001517          	auipc	a0,0x1
ffffffffc0200eea:	f5a50513          	addi	a0,a0,-166 # ffffffffc0201e40 <etext+0x6ea>
ffffffffc0200eee:	a5aff0ef          	jal	ffffffffc0200148 <cprintf>
    void *a1 = slub_malloc(64);
ffffffffc0200ef2:	04000513          	li	a0,64
ffffffffc0200ef6:	bd7ff0ef          	jal	ffffffffc0200acc <slub_malloc>
ffffffffc0200efa:	84aa                	mv	s1,a0
    slub_free(a1);
ffffffffc0200efc:	dd7ff0ef          	jal	ffffffffc0200cd2 <slub_free>
    void *a2 = slub_malloc(64);
ffffffffc0200f00:	04000513          	li	a0,64
ffffffffc0200f04:	bc9ff0ef          	jal	ffffffffc0200acc <slub_malloc>
ffffffffc0200f08:	842a                	mv	s0,a0
    cprintf("[Reuse] First: %p, Second: %p (%s)\n",
ffffffffc0200f0a:	00001697          	auipc	a3,0x1
ffffffffc0200f0e:	d0e68693          	addi	a3,a3,-754 # ffffffffc0201c18 <etext+0x4c2>
ffffffffc0200f12:	2ca48f63          	beq	s1,a0,ffffffffc02011f0 <slub_check+0x470>
ffffffffc0200f16:	85a6                	mv	a1,s1
ffffffffc0200f18:	8622                	mv	a2,s0
ffffffffc0200f1a:	00001517          	auipc	a0,0x1
ffffffffc0200f1e:	f3e50513          	addi	a0,a0,-194 # ffffffffc0201e58 <etext+0x702>
ffffffffc0200f22:	a26ff0ef          	jal	ffffffffc0200148 <cprintf>
            a1, a2, (a1 == a2) ? "Reused" : "New slab");
    slub_free(a2);
ffffffffc0200f26:	8522                	mv	a0,s0
ffffffffc0200f28:	dabff0ef          	jal	ffffffffc0200cd2 <slub_free>
    cprintf("[Reuse Check Completed]\n\n");
ffffffffc0200f2c:	00001517          	auipc	a0,0x1
ffffffffc0200f30:	f5450513          	addi	a0,a0,-172 # ffffffffc0201e80 <etext+0x72a>
ffffffffc0200f34:	a14ff0ef          	jal	ffffffffc0200148 <cprintf>

    /* --- 批量分配释放 --- */
    cprintf(">>> [Bulk Allocation / Free Test]\n");
ffffffffc0200f38:	00001517          	auipc	a0,0x1
ffffffffc0200f3c:	f6850513          	addi	a0,a0,-152 # ffffffffc0201ea0 <etext+0x74a>
ffffffffc0200f40:	a08ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc0200f44:	84ce                	mv	s1,s3
    const int NUM = 20;
    void *objs[NUM];
    for (int i = 0; i < NUM; i++) {
ffffffffc0200f46:	4401                	li	s0,0
ffffffffc0200f48:	4951                	li	s2,20
        objs[i] = slub_malloc(64);
ffffffffc0200f4a:	04000513          	li	a0,64
ffffffffc0200f4e:	b7fff0ef          	jal	ffffffffc0200acc <slub_malloc>
ffffffffc0200f52:	e088                	sd	a0,0(s1)
ffffffffc0200f54:	862a                	mv	a2,a0
        assert(objs[i]);
ffffffffc0200f56:	2e050c63          	beqz	a0,ffffffffc020124e <slub_check+0x4ce>
        cprintf("[ALLOC] objs[%02d] = %p\n", i, objs[i]);
ffffffffc0200f5a:	85a2                	mv	a1,s0
ffffffffc0200f5c:	00001517          	auipc	a0,0x1
ffffffffc0200f60:	f7450513          	addi	a0,a0,-140 # ffffffffc0201ed0 <etext+0x77a>
    for (int i = 0; i < NUM; i++) {
ffffffffc0200f64:	2405                	addiw	s0,s0,1
        cprintf("[ALLOC] objs[%02d] = %p\n", i, objs[i]);
ffffffffc0200f66:	9e2ff0ef          	jal	ffffffffc0200148 <cprintf>
    for (int i = 0; i < NUM; i++) {
ffffffffc0200f6a:	04a1                	addi	s1,s1,8
ffffffffc0200f6c:	fd241fe3          	bne	s0,s2,ffffffffc0200f4a <slub_check+0x1ca>
    }
    cprintf("[INFO ] 全部 %d 个对象分配完成\n", NUM);
ffffffffc0200f70:	85a2                	mv	a1,s0
ffffffffc0200f72:	00001517          	auipc	a0,0x1
ffffffffc0200f76:	f7e50513          	addi	a0,a0,-130 # ffffffffc0201ef0 <etext+0x79a>
ffffffffc0200f7a:	9ceff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc0200f7e:	894e                	mv	s2,s3
    for (int i = 0; i < NUM; i += 2) {
ffffffffc0200f80:	4481                	li	s1,0
        slub_free(objs[i]);
ffffffffc0200f82:	00093a83          	ld	s5,0(s2)
    for (int i = 0; i < NUM; i += 2) {
ffffffffc0200f86:	0941                	addi	s2,s2,16
        slub_free(objs[i]);
ffffffffc0200f88:	8556                	mv	a0,s5
ffffffffc0200f8a:	d49ff0ef          	jal	ffffffffc0200cd2 <slub_free>
        cprintf("[FREE ] objs[%02d] = %p\n", i, objs[i]);
ffffffffc0200f8e:	85a6                	mv	a1,s1
ffffffffc0200f90:	8656                	mv	a2,s5
ffffffffc0200f92:	00001517          	auipc	a0,0x1
ffffffffc0200f96:	f8e50513          	addi	a0,a0,-114 # ffffffffc0201f20 <etext+0x7ca>
    for (int i = 0; i < NUM; i += 2) {
ffffffffc0200f9a:	2489                	addiw	s1,s1,2
        cprintf("[FREE ] objs[%02d] = %p\n", i, objs[i]);
ffffffffc0200f9c:	9acff0ef          	jal	ffffffffc0200148 <cprintf>
    for (int i = 0; i < NUM; i += 2) {
ffffffffc0200fa0:	fe8491e3          	bne	s1,s0,ffffffffc0200f82 <slub_check+0x202>
ffffffffc0200fa4:	05098413          	addi	s0,s3,80
ffffffffc0200fa8:	8922                	mv	s2,s0
    }
    for (int i = NUM / 2; i < NUM; i++) {
ffffffffc0200faa:	44a9                	li	s1,10
ffffffffc0200fac:	4ad1                	li	s5,20
        objs[i] = slub_malloc(64);
ffffffffc0200fae:	04000513          	li	a0,64
ffffffffc0200fb2:	b1bff0ef          	jal	ffffffffc0200acc <slub_malloc>
ffffffffc0200fb6:	00a93023          	sd	a0,0(s2)
ffffffffc0200fba:	862a                	mv	a2,a0
        assert(objs[i]);
ffffffffc0200fbc:	2c050963          	beqz	a0,ffffffffc020128e <slub_check+0x50e>
        cprintf("[REALLOC] objs[%02d] = %p\n", i, objs[i]);
ffffffffc0200fc0:	85a6                	mv	a1,s1
ffffffffc0200fc2:	00001517          	auipc	a0,0x1
ffffffffc0200fc6:	f7e50513          	addi	a0,a0,-130 # ffffffffc0201f40 <etext+0x7ea>
    for (int i = NUM / 2; i < NUM; i++) {
ffffffffc0200fca:	2485                	addiw	s1,s1,1
        cprintf("[REALLOC] objs[%02d] = %p\n", i, objs[i]);
ffffffffc0200fcc:	97cff0ef          	jal	ffffffffc0200148 <cprintf>
    for (int i = NUM / 2; i < NUM; i++) {
ffffffffc0200fd0:	0921                	addi	s2,s2,8
ffffffffc0200fd2:	fd549ee3          	bne	s1,s5,ffffffffc0200fae <slub_check+0x22e>
ffffffffc0200fd6:	00898493          	addi	s1,s3,8
ffffffffc0200fda:	0a898913          	addi	s2,s3,168
    }
    for (int i = 1; i < NUM; i += 2) slub_free(objs[i]);
ffffffffc0200fde:	6088                	ld	a0,0(s1)
ffffffffc0200fe0:	04c1                	addi	s1,s1,16
ffffffffc0200fe2:	cf1ff0ef          	jal	ffffffffc0200cd2 <slub_free>
ffffffffc0200fe6:	ff249ce3          	bne	s1,s2,ffffffffc0200fde <slub_check+0x25e>
ffffffffc0200fea:	0a098993          	addi	s3,s3,160
    for (int i = NUM / 2; i < NUM; i++) slub_free(objs[i]);
ffffffffc0200fee:	6008                	ld	a0,0(s0)
ffffffffc0200ff0:	0421                	addi	s0,s0,8
ffffffffc0200ff2:	ce1ff0ef          	jal	ffffffffc0200cd2 <slub_free>
ffffffffc0200ff6:	ff341ce3          	bne	s0,s3,ffffffffc0200fee <slub_check+0x26e>
    cprintf("[Bulk Test Completed]\n\n");
ffffffffc0200ffa:	00001517          	auipc	a0,0x1
ffffffffc0200ffe:	f6650513          	addi	a0,a0,-154 # ffffffffc0201f60 <etext+0x80a>
ffffffffc0201002:	946ff0ef          	jal	ffffffffc0200148 <cprintf>

    /* --- 大页分配测试 --- */
    cprintf(">>> [Multi-page Allocation Test]\n");
ffffffffc0201006:	00001517          	auipc	a0,0x1
ffffffffc020100a:	f7250513          	addi	a0,a0,-142 # ffffffffc0201f78 <etext+0x822>
ffffffffc020100e:	93aff0ef          	jal	ffffffffc0200148 <cprintf>
    struct Page *p0 = slub_alloc_pages(3);
ffffffffc0201012:	450d                	li	a0,3
ffffffffc0201014:	f8eff0ef          	jal	ffffffffc02007a2 <slub_alloc_pages>
ffffffffc0201018:	892a                	mv	s2,a0
    struct Page *p1 = slub_alloc_pages(5);
ffffffffc020101a:	4515                	li	a0,5
ffffffffc020101c:	f86ff0ef          	jal	ffffffffc02007a2 <slub_alloc_pages>
ffffffffc0201020:	84aa                	mv	s1,a0
    struct Page *p2 = slub_alloc_pages(10);
ffffffffc0201022:	4529                	li	a0,10
ffffffffc0201024:	f7eff0ef          	jal	ffffffffc02007a2 <slub_alloc_pages>
ffffffffc0201028:	842a                	mv	s0,a0
    if (p0) cprintf("p0 = %p (3 pages)\n", p0);
ffffffffc020102a:	00090963          	beqz	s2,ffffffffc020103c <slub_check+0x2bc>
ffffffffc020102e:	85ca                	mv	a1,s2
ffffffffc0201030:	00001517          	auipc	a0,0x1
ffffffffc0201034:	f7050513          	addi	a0,a0,-144 # ffffffffc0201fa0 <etext+0x84a>
ffffffffc0201038:	910ff0ef          	jal	ffffffffc0200148 <cprintf>
    if (p1) cprintf("p1 = %p (5 pages)\n", p1);
ffffffffc020103c:	c881                	beqz	s1,ffffffffc020104c <slub_check+0x2cc>
ffffffffc020103e:	85a6                	mv	a1,s1
ffffffffc0201040:	00001517          	auipc	a0,0x1
ffffffffc0201044:	f7850513          	addi	a0,a0,-136 # ffffffffc0201fb8 <etext+0x862>
ffffffffc0201048:	900ff0ef          	jal	ffffffffc0200148 <cprintf>
    if (p2) cprintf("p2 = %p (10 pages)\n", p2);
ffffffffc020104c:	c801                	beqz	s0,ffffffffc020105c <slub_check+0x2dc>
ffffffffc020104e:	85a2                	mv	a1,s0
ffffffffc0201050:	00001517          	auipc	a0,0x1
ffffffffc0201054:	f8050513          	addi	a0,a0,-128 # ffffffffc0201fd0 <etext+0x87a>
ffffffffc0201058:	8f0ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("当前空闲页数: %d\n", slub_nr_free_pages());
ffffffffc020105c:	00005597          	auipc	a1,0x5
ffffffffc0201060:	14c5e583          	lwu	a1,332(a1) # ffffffffc02061a8 <free_area+0x10>
ffffffffc0201064:	00001517          	auipc	a0,0x1
ffffffffc0201068:	f8450513          	addi	a0,a0,-124 # ffffffffc0201fe8 <etext+0x892>
ffffffffc020106c:	8dcff0ef          	jal	ffffffffc0200148 <cprintf>
    if (p0) slub_free_pages(p0, 3);
ffffffffc0201070:	00090663          	beqz	s2,ffffffffc020107c <slub_check+0x2fc>
    assert(n > 0);
ffffffffc0201074:	854a                	mv	a0,s2
ffffffffc0201076:	458d                	li	a1,3
ffffffffc0201078:	fe6ff0ef          	jal	ffffffffc020085e <slub_free_pages.part.0>
    if (p1) slub_free_pages(p1, 5);
ffffffffc020107c:	c489                	beqz	s1,ffffffffc0201086 <slub_check+0x306>
    assert(n > 0);
ffffffffc020107e:	8526                	mv	a0,s1
ffffffffc0201080:	4595                	li	a1,5
ffffffffc0201082:	fdcff0ef          	jal	ffffffffc020085e <slub_free_pages.part.0>
    if (p2) slub_free_pages(p2, 10);
ffffffffc0201086:	c409                	beqz	s0,ffffffffc0201090 <slub_check+0x310>
    assert(n > 0);
ffffffffc0201088:	8522                	mv	a0,s0
ffffffffc020108a:	45a9                	li	a1,10
ffffffffc020108c:	fd2ff0ef          	jal	ffffffffc020085e <slub_free_pages.part.0>
    cprintf("[Multi-page Test Completed]\n\n");
ffffffffc0201090:	00001517          	auipc	a0,0x1
ffffffffc0201094:	f7050513          	addi	a0,a0,-144 # ffffffffc0202000 <etext+0x8aa>
ffffffffc0201098:	8b0ff0ef          	jal	ffffffffc0200148 <cprintf>

    /* --- 混合测试 --- */
    cprintf(">>> [Mixed Allocation Pattern]\n");
ffffffffc020109c:	00001517          	auipc	a0,0x1
ffffffffc02010a0:	f8450513          	addi	a0,a0,-124 # ffffffffc0202020 <etext+0x8ca>
ffffffffc02010a4:	8a4ff0ef          	jal	ffffffffc0200148 <cprintf>
    void *x1 = slub_malloc(32);
ffffffffc02010a8:	02000513          	li	a0,32
ffffffffc02010ac:	a21ff0ef          	jal	ffffffffc0200acc <slub_malloc>
ffffffffc02010b0:	892a                	mv	s2,a0
    void *x2 = slub_malloc(64);
ffffffffc02010b2:	04000513          	li	a0,64
ffffffffc02010b6:	a17ff0ef          	jal	ffffffffc0200acc <slub_malloc>
ffffffffc02010ba:	842a                	mv	s0,a0
    void *x3 = slub_malloc(128);
ffffffffc02010bc:	08000513          	li	a0,128
ffffffffc02010c0:	a0dff0ef          	jal	ffffffffc0200acc <slub_malloc>
    cprintf("[ALLOC] x1=%p(32), x2=%p(64), x3=%p(128)\n", x1, x2, x3);
ffffffffc02010c4:	86aa                	mv	a3,a0
ffffffffc02010c6:	8622                	mv	a2,s0
ffffffffc02010c8:	85ca                	mv	a1,s2
    void *x3 = slub_malloc(128);
ffffffffc02010ca:	84aa                	mv	s1,a0
    cprintf("[ALLOC] x1=%p(32), x2=%p(64), x3=%p(128)\n", x1, x2, x3);
ffffffffc02010cc:	00001517          	auipc	a0,0x1
ffffffffc02010d0:	f7450513          	addi	a0,a0,-140 # ffffffffc0202040 <etext+0x8ea>
ffffffffc02010d4:	874ff0ef          	jal	ffffffffc0200148 <cprintf>

    slub_free(x2);
ffffffffc02010d8:	8522                	mv	a0,s0
ffffffffc02010da:	bf9ff0ef          	jal	ffffffffc0200cd2 <slub_free>
    cprintf("[FREE ] x2=%p\n", x2);
ffffffffc02010de:	85a2                	mv	a1,s0
ffffffffc02010e0:	00001517          	auipc	a0,0x1
ffffffffc02010e4:	f9050513          	addi	a0,a0,-112 # ffffffffc0202070 <etext+0x91a>
ffffffffc02010e8:	860ff0ef          	jal	ffffffffc0200148 <cprintf>

    void *x4 = slub_malloc(64);
ffffffffc02010ec:	04000513          	li	a0,64
ffffffffc02010f0:	9ddff0ef          	jal	ffffffffc0200acc <slub_malloc>
    cprintf("[REALLOC] x4=%p(64)\n", x4);
ffffffffc02010f4:	85aa                	mv	a1,a0
    void *x4 = slub_malloc(64);
ffffffffc02010f6:	842a                	mv	s0,a0
    cprintf("[REALLOC] x4=%p(64)\n", x4);
ffffffffc02010f8:	00001517          	auipc	a0,0x1
ffffffffc02010fc:	f8850513          	addi	a0,a0,-120 # ffffffffc0202080 <etext+0x92a>
ffffffffc0201100:	848ff0ef          	jal	ffffffffc0200148 <cprintf>

    slub_free(x1);
ffffffffc0201104:	854a                	mv	a0,s2
ffffffffc0201106:	bcdff0ef          	jal	ffffffffc0200cd2 <slub_free>
    slub_free(x3);
ffffffffc020110a:	8526                	mv	a0,s1
ffffffffc020110c:	bc7ff0ef          	jal	ffffffffc0200cd2 <slub_free>
    slub_free(x4);
ffffffffc0201110:	8522                	mv	a0,s0
ffffffffc0201112:	bc1ff0ef          	jal	ffffffffc0200cd2 <slub_free>
    cprintf("[Mixed Test Completed]\n\n");
ffffffffc0201116:	00001517          	auipc	a0,0x1
ffffffffc020111a:	f8250513          	addi	a0,a0,-126 # ffffffffc0202098 <etext+0x942>
ffffffffc020111e:	82aff0ef          	jal	ffffffffc0200148 <cprintf>

    /* --- 大对象/跨页分配测试 --- */
    cprintf(">>> [Large Object Alloc Test]\n");
ffffffffc0201122:	00001517          	auipc	a0,0x1
ffffffffc0201126:	f9650513          	addi	a0,a0,-106 # ffffffffc02020b8 <etext+0x962>
ffffffffc020112a:	81eff0ef          	jal	ffffffffc0200148 <cprintf>
    void *bigobj = slub_malloc(4096);
ffffffffc020112e:	6505                	lui	a0,0x1
ffffffffc0201130:	99dff0ef          	jal	ffffffffc0200acc <slub_malloc>
ffffffffc0201134:	842a                	mv	s0,a0
    if (bigobj) {
ffffffffc0201136:	c171                	beqz	a0,ffffffffc02011fa <slub_check+0x47a>
        cprintf("[ALLOC] 4096-byte big object @ %p\n", bigobj);
ffffffffc0201138:	85aa                	mv	a1,a0
ffffffffc020113a:	00001517          	auipc	a0,0x1
ffffffffc020113e:	f9e50513          	addi	a0,a0,-98 # ffffffffc02020d8 <etext+0x982>
ffffffffc0201142:	806ff0ef          	jal	ffffffffc0200148 <cprintf>
        slub_free(bigobj);
ffffffffc0201146:	8522                	mv	a0,s0
ffffffffc0201148:	b8bff0ef          	jal	ffffffffc0200cd2 <slub_free>
        cprintf("[FREE ] 4096-byte big object @ %p\n", bigobj);
ffffffffc020114c:	85a2                	mv	a1,s0
ffffffffc020114e:	00001517          	auipc	a0,0x1
ffffffffc0201152:	fb250513          	addi	a0,a0,-78 # ffffffffc0202100 <etext+0x9aa>
ffffffffc0201156:	ff3fe0ef          	jal	ffffffffc0200148 <cprintf>
    } else {
        cprintf("[WARN ] big object alloc failed.\n");
    }
    cprintf("[Large Object Test Completed]\n\n");
ffffffffc020115a:	00001517          	auipc	a0,0x1
ffffffffc020115e:	ff650513          	addi	a0,a0,-10 # ffffffffc0202150 <etext+0x9fa>
ffffffffc0201162:	fe7fe0ef          	jal	ffffffffc0200148 <cprintf>

    /* --- 最终一致性检查 --- */
    cprintf(">>> [Final Consistency Check]\n");
ffffffffc0201166:	00001517          	auipc	a0,0x1
ffffffffc020116a:	00a50513          	addi	a0,a0,10 # ffffffffc0202170 <etext+0xa1a>
ffffffffc020116e:	fdbfe0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc0201172:	008a3783          	ld	a5,8(s4)
    int total_free_pages = 0, count = 0;
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201176:	0b478863          	beq	a5,s4,ffffffffc0201226 <slub_check+0x4a6>
    int total_free_pages = 0, count = 0;
ffffffffc020117a:	4581                	li	a1,0
ffffffffc020117c:	4601                	li	a2,0
        struct Page *p = le2page(le, page_link);
        total_free_pages += p->property;
ffffffffc020117e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201182:	679c                	ld	a5,8(a5)
        count++;
ffffffffc0201184:	2585                	addiw	a1,a1,1
        total_free_pages += p->property;
ffffffffc0201186:	9e39                	addw	a2,a2,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201188:	ff479be3          	bne	a5,s4,ffffffffc020117e <slub_check+0x3fe>
    }
    cprintf("空闲块数量: %d, 总空闲页: %d\n", count, total_free_pages);
    cprintf("slub_nr_free_pages() = %d\n", slub_nr_free_pages());
    assert(total_free_pages == slub_nr_free_pages());
ffffffffc020118c:	8432                	mv	s0,a2
    cprintf("空闲块数量: %d, 总空闲页: %d\n", count, total_free_pages);
ffffffffc020118e:	00001517          	auipc	a0,0x1
ffffffffc0201192:	00250513          	addi	a0,a0,2 # ffffffffc0202190 <etext+0xa3a>
ffffffffc0201196:	fb3fe0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("slub_nr_free_pages() = %d\n", slub_nr_free_pages());
ffffffffc020119a:	00005597          	auipc	a1,0x5
ffffffffc020119e:	00e5e583          	lwu	a1,14(a1) # ffffffffc02061a8 <free_area+0x10>
ffffffffc02011a2:	00001517          	auipc	a0,0x1
ffffffffc02011a6:	01650513          	addi	a0,a0,22 # ffffffffc02021b8 <etext+0xa62>
ffffffffc02011aa:	f9ffe0ef          	jal	ffffffffc0200148 <cprintf>
    return nr_free;
ffffffffc02011ae:	00005797          	auipc	a5,0x5
ffffffffc02011b2:	ffa7e783          	lwu	a5,-6(a5) # ffffffffc02061a8 <free_area+0x10>
    assert(total_free_pages == slub_nr_free_pages());
ffffffffc02011b6:	0ef41c63          	bne	s0,a5,ffffffffc02012ae <slub_check+0x52e>
    cprintf("[Consistency Verified]\n\n");
ffffffffc02011ba:	00001517          	auipc	a0,0x1
ffffffffc02011be:	04e50513          	addi	a0,a0,78 # ffffffffc0202208 <etext+0xab2>
ffffffffc02011c2:	f87fe0ef          	jal	ffffffffc0200148 <cprintf>

    cprintf("========== [SLUB Allocator Test Complete] ==========\n");
}
ffffffffc02011c6:	6452                	ld	s0,272(sp)
ffffffffc02011c8:	60f2                	ld	ra,280(sp)
ffffffffc02011ca:	64b2                	ld	s1,264(sp)
ffffffffc02011cc:	6912                	ld	s2,256(sp)
ffffffffc02011ce:	79ee                	ld	s3,248(sp)
ffffffffc02011d0:	7a4e                	ld	s4,240(sp)
ffffffffc02011d2:	7aae                	ld	s5,232(sp)
    cprintf("========== [SLUB Allocator Test Complete] ==========\n");
ffffffffc02011d4:	00001517          	auipc	a0,0x1
ffffffffc02011d8:	05450513          	addi	a0,a0,84 # ffffffffc0202228 <etext+0xad2>
}
ffffffffc02011dc:	6115                	addi	sp,sp,288
    cprintf("========== [SLUB Allocator Test Complete] ==========\n");
ffffffffc02011de:	f6bfe06f          	j	ffffffffc0200148 <cprintf>
        cprintf("[WARN] 大对象分配失败 (无可用内存)\n");
ffffffffc02011e2:	00001517          	auipc	a0,0x1
ffffffffc02011e6:	b6650513          	addi	a0,a0,-1178 # ffffffffc0201d48 <etext+0x5f2>
ffffffffc02011ea:	f5ffe0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc02011ee:	b199                	j	ffffffffc0200e34 <slub_check+0xb4>
    cprintf("[Reuse] First: %p, Second: %p (%s)\n",
ffffffffc02011f0:	00001697          	auipc	a3,0x1
ffffffffc02011f4:	a2068693          	addi	a3,a3,-1504 # ffffffffc0201c10 <etext+0x4ba>
ffffffffc02011f8:	bb39                	j	ffffffffc0200f16 <slub_check+0x196>
        cprintf("[WARN ] big object alloc failed.\n");
ffffffffc02011fa:	00001517          	auipc	a0,0x1
ffffffffc02011fe:	f2e50513          	addi	a0,a0,-210 # ffffffffc0202128 <etext+0x9d2>
ffffffffc0201202:	f47fe0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("[Large Object Test Completed]\n\n");
ffffffffc0201206:	00001517          	auipc	a0,0x1
ffffffffc020120a:	f4a50513          	addi	a0,a0,-182 # ffffffffc0202150 <etext+0x9fa>
ffffffffc020120e:	f3bfe0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf(">>> [Final Consistency Check]\n");
ffffffffc0201212:	00001517          	auipc	a0,0x1
ffffffffc0201216:	f5e50513          	addi	a0,a0,-162 # ffffffffc0202170 <etext+0xa1a>
ffffffffc020121a:	f2ffe0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc020121e:	008a3783          	ld	a5,8(s4)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201222:	f5479ce3          	bne	a5,s4,ffffffffc020117a <slub_check+0x3fa>
ffffffffc0201226:	4401                	li	s0,0
    int total_free_pages = 0, count = 0;
ffffffffc0201228:	4581                	li	a1,0
ffffffffc020122a:	4601                	li	a2,0
ffffffffc020122c:	b78d                	j	ffffffffc020118e <slub_check+0x40e>
        for (size_t j = 0; j < sz; j++) assert(((uint8_t*)ptr)[j] == 0xAB);
ffffffffc020122e:	00001697          	auipc	a3,0x1
ffffffffc0201232:	bba68693          	addi	a3,a3,-1094 # ffffffffc0201de8 <etext+0x692>
ffffffffc0201236:	00001617          	auipc	a2,0x1
ffffffffc020123a:	8c260613          	addi	a2,a2,-1854 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc020123e:	15200593          	li	a1,338
ffffffffc0201242:	00001517          	auipc	a0,0x1
ffffffffc0201246:	8ce50513          	addi	a0,a0,-1842 # ffffffffc0201b10 <etext+0x3ba>
ffffffffc020124a:	f7ffe0ef          	jal	ffffffffc02001c8 <__panic>
        assert(objs[i]);
ffffffffc020124e:	00001697          	auipc	a3,0x1
ffffffffc0201252:	c7a68693          	addi	a3,a3,-902 # ffffffffc0201ec8 <etext+0x772>
ffffffffc0201256:	00001617          	auipc	a2,0x1
ffffffffc020125a:	8a260613          	addi	a2,a2,-1886 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc020125e:	16800593          	li	a1,360
ffffffffc0201262:	00001517          	auipc	a0,0x1
ffffffffc0201266:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0201b10 <etext+0x3ba>
ffffffffc020126a:	f5ffe0ef          	jal	ffffffffc02001c8 <__panic>
        assert(ptr != NULL);
ffffffffc020126e:	00001697          	auipc	a3,0x1
ffffffffc0201272:	b5268693          	addi	a3,a3,-1198 # ffffffffc0201dc0 <etext+0x66a>
ffffffffc0201276:	00001617          	auipc	a2,0x1
ffffffffc020127a:	88260613          	addi	a2,a2,-1918 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc020127e:	14f00593          	li	a1,335
ffffffffc0201282:	00001517          	auipc	a0,0x1
ffffffffc0201286:	88e50513          	addi	a0,a0,-1906 # ffffffffc0201b10 <etext+0x3ba>
ffffffffc020128a:	f3ffe0ef          	jal	ffffffffc02001c8 <__panic>
        assert(objs[i]);
ffffffffc020128e:	00001697          	auipc	a3,0x1
ffffffffc0201292:	c3a68693          	addi	a3,a3,-966 # ffffffffc0201ec8 <etext+0x772>
ffffffffc0201296:	00001617          	auipc	a2,0x1
ffffffffc020129a:	86260613          	addi	a2,a2,-1950 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc020129e:	17200593          	li	a1,370
ffffffffc02012a2:	00001517          	auipc	a0,0x1
ffffffffc02012a6:	86e50513          	addi	a0,a0,-1938 # ffffffffc0201b10 <etext+0x3ba>
ffffffffc02012aa:	f1ffe0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total_free_pages == slub_nr_free_pages());
ffffffffc02012ae:	00001697          	auipc	a3,0x1
ffffffffc02012b2:	f2a68693          	addi	a3,a3,-214 # ffffffffc02021d8 <etext+0xa82>
ffffffffc02012b6:	00001617          	auipc	a2,0x1
ffffffffc02012ba:	84260613          	addi	a2,a2,-1982 # ffffffffc0201af8 <etext+0x3a2>
ffffffffc02012be:	1b000593          	li	a1,432
ffffffffc02012c2:	00001517          	auipc	a0,0x1
ffffffffc02012c6:	84e50513          	addi	a0,a0,-1970 # ffffffffc0201b10 <etext+0x3ba>
ffffffffc02012ca:	efffe0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc02012ce <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012ce:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02012d0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012d4:	f022                	sd	s0,32(sp)
ffffffffc02012d6:	ec26                	sd	s1,24(sp)
ffffffffc02012d8:	e84a                	sd	s2,16(sp)
ffffffffc02012da:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02012dc:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012e0:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02012e2:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02012e6:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012ea:	84aa                	mv	s1,a0
ffffffffc02012ec:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02012ee:	03067d63          	bgeu	a2,a6,ffffffffc0201328 <printnum+0x5a>
ffffffffc02012f2:	e44e                	sd	s3,8(sp)
ffffffffc02012f4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02012f6:	4785                	li	a5,1
ffffffffc02012f8:	00e7d763          	bge	a5,a4,ffffffffc0201306 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02012fc:	85ca                	mv	a1,s2
ffffffffc02012fe:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201300:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201302:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201304:	fc65                	bnez	s0,ffffffffc02012fc <printnum+0x2e>
ffffffffc0201306:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201308:	00001797          	auipc	a5,0x1
ffffffffc020130c:	f7078793          	addi	a5,a5,-144 # ffffffffc0202278 <etext+0xb22>
ffffffffc0201310:	97d2                	add	a5,a5,s4
}
ffffffffc0201312:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201314:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201318:	70a2                	ld	ra,40(sp)
ffffffffc020131a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020131c:	85ca                	mv	a1,s2
ffffffffc020131e:	87a6                	mv	a5,s1
}
ffffffffc0201320:	6942                	ld	s2,16(sp)
ffffffffc0201322:	64e2                	ld	s1,24(sp)
ffffffffc0201324:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201326:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201328:	03065633          	divu	a2,a2,a6
ffffffffc020132c:	8722                	mv	a4,s0
ffffffffc020132e:	fa1ff0ef          	jal	ffffffffc02012ce <printnum>
ffffffffc0201332:	bfd9                	j	ffffffffc0201308 <printnum+0x3a>

ffffffffc0201334 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201334:	7119                	addi	sp,sp,-128
ffffffffc0201336:	f4a6                	sd	s1,104(sp)
ffffffffc0201338:	f0ca                	sd	s2,96(sp)
ffffffffc020133a:	ecce                	sd	s3,88(sp)
ffffffffc020133c:	e8d2                	sd	s4,80(sp)
ffffffffc020133e:	e4d6                	sd	s5,72(sp)
ffffffffc0201340:	e0da                	sd	s6,64(sp)
ffffffffc0201342:	f862                	sd	s8,48(sp)
ffffffffc0201344:	fc86                	sd	ra,120(sp)
ffffffffc0201346:	f8a2                	sd	s0,112(sp)
ffffffffc0201348:	fc5e                	sd	s7,56(sp)
ffffffffc020134a:	f466                	sd	s9,40(sp)
ffffffffc020134c:	f06a                	sd	s10,32(sp)
ffffffffc020134e:	ec6e                	sd	s11,24(sp)
ffffffffc0201350:	84aa                	mv	s1,a0
ffffffffc0201352:	8c32                	mv	s8,a2
ffffffffc0201354:	8a36                	mv	s4,a3
ffffffffc0201356:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201358:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020135c:	05500b13          	li	s6,85
ffffffffc0201360:	00001a97          	auipc	s5,0x1
ffffffffc0201364:	0a8a8a93          	addi	s5,s5,168 # ffffffffc0202408 <slub_sizes+0x78>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201368:	000c4503          	lbu	a0,0(s8)
ffffffffc020136c:	001c0413          	addi	s0,s8,1
ffffffffc0201370:	01350a63          	beq	a0,s3,ffffffffc0201384 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201374:	cd0d                	beqz	a0,ffffffffc02013ae <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201376:	85ca                	mv	a1,s2
ffffffffc0201378:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020137a:	00044503          	lbu	a0,0(s0)
ffffffffc020137e:	0405                	addi	s0,s0,1
ffffffffc0201380:	ff351ae3          	bne	a0,s3,ffffffffc0201374 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0201384:	5cfd                	li	s9,-1
ffffffffc0201386:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0201388:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc020138c:	4b81                	li	s7,0
ffffffffc020138e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201390:	00044683          	lbu	a3,0(s0)
ffffffffc0201394:	00140c13          	addi	s8,s0,1
ffffffffc0201398:	fdd6859b          	addiw	a1,a3,-35
ffffffffc020139c:	0ff5f593          	zext.b	a1,a1
ffffffffc02013a0:	02bb6663          	bltu	s6,a1,ffffffffc02013cc <vprintfmt+0x98>
ffffffffc02013a4:	058a                	slli	a1,a1,0x2
ffffffffc02013a6:	95d6                	add	a1,a1,s5
ffffffffc02013a8:	4198                	lw	a4,0(a1)
ffffffffc02013aa:	9756                	add	a4,a4,s5
ffffffffc02013ac:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02013ae:	70e6                	ld	ra,120(sp)
ffffffffc02013b0:	7446                	ld	s0,112(sp)
ffffffffc02013b2:	74a6                	ld	s1,104(sp)
ffffffffc02013b4:	7906                	ld	s2,96(sp)
ffffffffc02013b6:	69e6                	ld	s3,88(sp)
ffffffffc02013b8:	6a46                	ld	s4,80(sp)
ffffffffc02013ba:	6aa6                	ld	s5,72(sp)
ffffffffc02013bc:	6b06                	ld	s6,64(sp)
ffffffffc02013be:	7be2                	ld	s7,56(sp)
ffffffffc02013c0:	7c42                	ld	s8,48(sp)
ffffffffc02013c2:	7ca2                	ld	s9,40(sp)
ffffffffc02013c4:	7d02                	ld	s10,32(sp)
ffffffffc02013c6:	6de2                	ld	s11,24(sp)
ffffffffc02013c8:	6109                	addi	sp,sp,128
ffffffffc02013ca:	8082                	ret
            putch('%', putdat);
ffffffffc02013cc:	85ca                	mv	a1,s2
ffffffffc02013ce:	02500513          	li	a0,37
ffffffffc02013d2:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02013d4:	fff44783          	lbu	a5,-1(s0)
ffffffffc02013d8:	02500713          	li	a4,37
ffffffffc02013dc:	8c22                	mv	s8,s0
ffffffffc02013de:	f8e785e3          	beq	a5,a4,ffffffffc0201368 <vprintfmt+0x34>
ffffffffc02013e2:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02013e6:	1c7d                	addi	s8,s8,-1
ffffffffc02013e8:	fee79de3          	bne	a5,a4,ffffffffc02013e2 <vprintfmt+0xae>
ffffffffc02013ec:	bfb5                	j	ffffffffc0201368 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02013ee:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02013f2:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02013f4:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02013f8:	fd06071b          	addiw	a4,a2,-48
ffffffffc02013fc:	24e56a63          	bltu	a0,a4,ffffffffc0201650 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0201400:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201402:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0201404:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0201408:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020140c:	0197073b          	addw	a4,a4,s9
ffffffffc0201410:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201414:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201416:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020141a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020141c:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201420:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201424:	feb570e3          	bgeu	a0,a1,ffffffffc0201404 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201428:	f60d54e3          	bgez	s10,ffffffffc0201390 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc020142c:	8d66                	mv	s10,s9
ffffffffc020142e:	5cfd                	li	s9,-1
ffffffffc0201430:	b785                	j	ffffffffc0201390 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201432:	8db6                	mv	s11,a3
ffffffffc0201434:	8462                	mv	s0,s8
ffffffffc0201436:	bfa9                	j	ffffffffc0201390 <vprintfmt+0x5c>
ffffffffc0201438:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc020143a:	4b85                	li	s7,1
            goto reswitch;
ffffffffc020143c:	bf91                	j	ffffffffc0201390 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc020143e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201440:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201444:	00f74463          	blt	a4,a5,ffffffffc020144c <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201448:	1a078763          	beqz	a5,ffffffffc02015f6 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc020144c:	000a3603          	ld	a2,0(s4)
ffffffffc0201450:	46c1                	li	a3,16
ffffffffc0201452:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201454:	000d879b          	sext.w	a5,s11
ffffffffc0201458:	876a                	mv	a4,s10
ffffffffc020145a:	85ca                	mv	a1,s2
ffffffffc020145c:	8526                	mv	a0,s1
ffffffffc020145e:	e71ff0ef          	jal	ffffffffc02012ce <printnum>
            break;
ffffffffc0201462:	b719                	j	ffffffffc0201368 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201464:	000a2503          	lw	a0,0(s4)
ffffffffc0201468:	85ca                	mv	a1,s2
ffffffffc020146a:	0a21                	addi	s4,s4,8
ffffffffc020146c:	9482                	jalr	s1
            break;
ffffffffc020146e:	bded                	j	ffffffffc0201368 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201470:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201472:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201476:	00f74463          	blt	a4,a5,ffffffffc020147e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020147a:	16078963          	beqz	a5,ffffffffc02015ec <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020147e:	000a3603          	ld	a2,0(s4)
ffffffffc0201482:	46a9                	li	a3,10
ffffffffc0201484:	8a2e                	mv	s4,a1
ffffffffc0201486:	b7f9                	j	ffffffffc0201454 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0201488:	85ca                	mv	a1,s2
ffffffffc020148a:	03000513          	li	a0,48
ffffffffc020148e:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201490:	85ca                	mv	a1,s2
ffffffffc0201492:	07800513          	li	a0,120
ffffffffc0201496:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201498:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020149c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020149e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02014a0:	bf55                	j	ffffffffc0201454 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02014a2:	85ca                	mv	a1,s2
ffffffffc02014a4:	02500513          	li	a0,37
ffffffffc02014a8:	9482                	jalr	s1
            break;
ffffffffc02014aa:	bd7d                	j	ffffffffc0201368 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02014ac:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014b0:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02014b2:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02014b4:	bf95                	j	ffffffffc0201428 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc02014b6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02014b8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02014bc:	00f74463          	blt	a4,a5,ffffffffc02014c4 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc02014c0:	12078163          	beqz	a5,ffffffffc02015e2 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc02014c4:	000a3603          	ld	a2,0(s4)
ffffffffc02014c8:	46a1                	li	a3,8
ffffffffc02014ca:	8a2e                	mv	s4,a1
ffffffffc02014cc:	b761                	j	ffffffffc0201454 <vprintfmt+0x120>
            if (width < 0)
ffffffffc02014ce:	876a                	mv	a4,s10
ffffffffc02014d0:	000d5363          	bgez	s10,ffffffffc02014d6 <vprintfmt+0x1a2>
ffffffffc02014d4:	4701                	li	a4,0
ffffffffc02014d6:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014da:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02014dc:	bd55                	j	ffffffffc0201390 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc02014de:	000d841b          	sext.w	s0,s11
ffffffffc02014e2:	fd340793          	addi	a5,s0,-45
ffffffffc02014e6:	00f037b3          	snez	a5,a5
ffffffffc02014ea:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014ee:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc02014f2:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014f4:	008a0793          	addi	a5,s4,8
ffffffffc02014f8:	e43e                	sd	a5,8(sp)
ffffffffc02014fa:	100d8c63          	beqz	s11,ffffffffc0201612 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02014fe:	12071363          	bnez	a4,ffffffffc0201624 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201502:	000dc783          	lbu	a5,0(s11)
ffffffffc0201506:	0007851b          	sext.w	a0,a5
ffffffffc020150a:	c78d                	beqz	a5,ffffffffc0201534 <vprintfmt+0x200>
ffffffffc020150c:	0d85                	addi	s11,s11,1
ffffffffc020150e:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201510:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201514:	000cc563          	bltz	s9,ffffffffc020151e <vprintfmt+0x1ea>
ffffffffc0201518:	3cfd                	addiw	s9,s9,-1
ffffffffc020151a:	008c8d63          	beq	s9,s0,ffffffffc0201534 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020151e:	020b9663          	bnez	s7,ffffffffc020154a <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0201522:	85ca                	mv	a1,s2
ffffffffc0201524:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201526:	000dc783          	lbu	a5,0(s11)
ffffffffc020152a:	0d85                	addi	s11,s11,1
ffffffffc020152c:	3d7d                	addiw	s10,s10,-1
ffffffffc020152e:	0007851b          	sext.w	a0,a5
ffffffffc0201532:	f3ed                	bnez	a5,ffffffffc0201514 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0201534:	01a05963          	blez	s10,ffffffffc0201546 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0201538:	85ca                	mv	a1,s2
ffffffffc020153a:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020153e:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201540:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0201542:	fe0d1be3          	bnez	s10,ffffffffc0201538 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201546:	6a22                	ld	s4,8(sp)
ffffffffc0201548:	b505                	j	ffffffffc0201368 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020154a:	3781                	addiw	a5,a5,-32
ffffffffc020154c:	fcfa7be3          	bgeu	s4,a5,ffffffffc0201522 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201550:	03f00513          	li	a0,63
ffffffffc0201554:	85ca                	mv	a1,s2
ffffffffc0201556:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201558:	000dc783          	lbu	a5,0(s11)
ffffffffc020155c:	0d85                	addi	s11,s11,1
ffffffffc020155e:	3d7d                	addiw	s10,s10,-1
ffffffffc0201560:	0007851b          	sext.w	a0,a5
ffffffffc0201564:	dbe1                	beqz	a5,ffffffffc0201534 <vprintfmt+0x200>
ffffffffc0201566:	fa0cd9e3          	bgez	s9,ffffffffc0201518 <vprintfmt+0x1e4>
ffffffffc020156a:	b7c5                	j	ffffffffc020154a <vprintfmt+0x216>
            if (err < 0) {
ffffffffc020156c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201570:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0201572:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201574:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201578:	8fb9                	xor	a5,a5,a4
ffffffffc020157a:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020157e:	02d64563          	blt	a2,a3,ffffffffc02015a8 <vprintfmt+0x274>
ffffffffc0201582:	00001797          	auipc	a5,0x1
ffffffffc0201586:	fde78793          	addi	a5,a5,-34 # ffffffffc0202560 <error_string>
ffffffffc020158a:	00369713          	slli	a4,a3,0x3
ffffffffc020158e:	97ba                	add	a5,a5,a4
ffffffffc0201590:	639c                	ld	a5,0(a5)
ffffffffc0201592:	cb99                	beqz	a5,ffffffffc02015a8 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201594:	86be                	mv	a3,a5
ffffffffc0201596:	00001617          	auipc	a2,0x1
ffffffffc020159a:	d1260613          	addi	a2,a2,-750 # ffffffffc02022a8 <etext+0xb52>
ffffffffc020159e:	85ca                	mv	a1,s2
ffffffffc02015a0:	8526                	mv	a0,s1
ffffffffc02015a2:	0d8000ef          	jal	ffffffffc020167a <printfmt>
ffffffffc02015a6:	b3c9                	j	ffffffffc0201368 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02015a8:	00001617          	auipc	a2,0x1
ffffffffc02015ac:	cf060613          	addi	a2,a2,-784 # ffffffffc0202298 <etext+0xb42>
ffffffffc02015b0:	85ca                	mv	a1,s2
ffffffffc02015b2:	8526                	mv	a0,s1
ffffffffc02015b4:	0c6000ef          	jal	ffffffffc020167a <printfmt>
ffffffffc02015b8:	bb45                	j	ffffffffc0201368 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02015ba:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02015bc:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02015c0:	00f74363          	blt	a4,a5,ffffffffc02015c6 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc02015c4:	cf81                	beqz	a5,ffffffffc02015dc <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc02015c6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02015ca:	02044b63          	bltz	s0,ffffffffc0201600 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc02015ce:	8622                	mv	a2,s0
ffffffffc02015d0:	8a5e                	mv	s4,s7
ffffffffc02015d2:	46a9                	li	a3,10
ffffffffc02015d4:	b541                	j	ffffffffc0201454 <vprintfmt+0x120>
            lflag ++;
ffffffffc02015d6:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015d8:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc02015da:	bb5d                	j	ffffffffc0201390 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc02015dc:	000a2403          	lw	s0,0(s4)
ffffffffc02015e0:	b7ed                	j	ffffffffc02015ca <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc02015e2:	000a6603          	lwu	a2,0(s4)
ffffffffc02015e6:	46a1                	li	a3,8
ffffffffc02015e8:	8a2e                	mv	s4,a1
ffffffffc02015ea:	b5ad                	j	ffffffffc0201454 <vprintfmt+0x120>
ffffffffc02015ec:	000a6603          	lwu	a2,0(s4)
ffffffffc02015f0:	46a9                	li	a3,10
ffffffffc02015f2:	8a2e                	mv	s4,a1
ffffffffc02015f4:	b585                	j	ffffffffc0201454 <vprintfmt+0x120>
ffffffffc02015f6:	000a6603          	lwu	a2,0(s4)
ffffffffc02015fa:	46c1                	li	a3,16
ffffffffc02015fc:	8a2e                	mv	s4,a1
ffffffffc02015fe:	bd99                	j	ffffffffc0201454 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0201600:	85ca                	mv	a1,s2
ffffffffc0201602:	02d00513          	li	a0,45
ffffffffc0201606:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0201608:	40800633          	neg	a2,s0
ffffffffc020160c:	8a5e                	mv	s4,s7
ffffffffc020160e:	46a9                	li	a3,10
ffffffffc0201610:	b591                	j	ffffffffc0201454 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201612:	e329                	bnez	a4,ffffffffc0201654 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201614:	02800793          	li	a5,40
ffffffffc0201618:	853e                	mv	a0,a5
ffffffffc020161a:	00001d97          	auipc	s11,0x1
ffffffffc020161e:	c77d8d93          	addi	s11,s11,-905 # ffffffffc0202291 <etext+0xb3b>
ffffffffc0201622:	b5f5                	j	ffffffffc020150e <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201624:	85e6                	mv	a1,s9
ffffffffc0201626:	856e                	mv	a0,s11
ffffffffc0201628:	0a4000ef          	jal	ffffffffc02016cc <strnlen>
ffffffffc020162c:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201630:	01a05863          	blez	s10,ffffffffc0201640 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0201634:	85ca                	mv	a1,s2
ffffffffc0201636:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201638:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc020163a:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020163c:	fe0d1ce3          	bnez	s10,ffffffffc0201634 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201640:	000dc783          	lbu	a5,0(s11)
ffffffffc0201644:	0007851b          	sext.w	a0,a5
ffffffffc0201648:	ec0792e3          	bnez	a5,ffffffffc020150c <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020164c:	6a22                	ld	s4,8(sp)
ffffffffc020164e:	bb29                	j	ffffffffc0201368 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201650:	8462                	mv	s0,s8
ffffffffc0201652:	bbd9                	j	ffffffffc0201428 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201654:	85e6                	mv	a1,s9
ffffffffc0201656:	00001517          	auipc	a0,0x1
ffffffffc020165a:	c3a50513          	addi	a0,a0,-966 # ffffffffc0202290 <etext+0xb3a>
ffffffffc020165e:	06e000ef          	jal	ffffffffc02016cc <strnlen>
ffffffffc0201662:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201666:	02800793          	li	a5,40
                p = "(null)";
ffffffffc020166a:	00001d97          	auipc	s11,0x1
ffffffffc020166e:	c26d8d93          	addi	s11,s11,-986 # ffffffffc0202290 <etext+0xb3a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201672:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201674:	fda040e3          	bgtz	s10,ffffffffc0201634 <vprintfmt+0x300>
ffffffffc0201678:	bd51                	j	ffffffffc020150c <vprintfmt+0x1d8>

ffffffffc020167a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020167a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020167c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201680:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201682:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201684:	ec06                	sd	ra,24(sp)
ffffffffc0201686:	f83a                	sd	a4,48(sp)
ffffffffc0201688:	fc3e                	sd	a5,56(sp)
ffffffffc020168a:	e0c2                	sd	a6,64(sp)
ffffffffc020168c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020168e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201690:	ca5ff0ef          	jal	ffffffffc0201334 <vprintfmt>
}
ffffffffc0201694:	60e2                	ld	ra,24(sp)
ffffffffc0201696:	6161                	addi	sp,sp,80
ffffffffc0201698:	8082                	ret

ffffffffc020169a <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020169a:	00005717          	auipc	a4,0x5
ffffffffc020169e:	97673703          	ld	a4,-1674(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02016a2:	4781                	li	a5,0
ffffffffc02016a4:	88ba                	mv	a7,a4
ffffffffc02016a6:	852a                	mv	a0,a0
ffffffffc02016a8:	85be                	mv	a1,a5
ffffffffc02016aa:	863e                	mv	a2,a5
ffffffffc02016ac:	00000073          	ecall
ffffffffc02016b0:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02016b2:	8082                	ret

ffffffffc02016b4 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02016b4:	00054783          	lbu	a5,0(a0)
ffffffffc02016b8:	cb81                	beqz	a5,ffffffffc02016c8 <strlen+0x14>
    size_t cnt = 0;
ffffffffc02016ba:	4781                	li	a5,0
        cnt ++;
ffffffffc02016bc:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02016be:	00f50733          	add	a4,a0,a5
ffffffffc02016c2:	00074703          	lbu	a4,0(a4)
ffffffffc02016c6:	fb7d                	bnez	a4,ffffffffc02016bc <strlen+0x8>
    }
    return cnt;
}
ffffffffc02016c8:	853e                	mv	a0,a5
ffffffffc02016ca:	8082                	ret

ffffffffc02016cc <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02016cc:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016ce:	e589                	bnez	a1,ffffffffc02016d8 <strnlen+0xc>
ffffffffc02016d0:	a811                	j	ffffffffc02016e4 <strnlen+0x18>
        cnt ++;
ffffffffc02016d2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016d4:	00f58863          	beq	a1,a5,ffffffffc02016e4 <strnlen+0x18>
ffffffffc02016d8:	00f50733          	add	a4,a0,a5
ffffffffc02016dc:	00074703          	lbu	a4,0(a4)
ffffffffc02016e0:	fb6d                	bnez	a4,ffffffffc02016d2 <strnlen+0x6>
ffffffffc02016e2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02016e4:	852e                	mv	a0,a1
ffffffffc02016e6:	8082                	ret

ffffffffc02016e8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016e8:	00054783          	lbu	a5,0(a0)
ffffffffc02016ec:	e791                	bnez	a5,ffffffffc02016f8 <strcmp+0x10>
ffffffffc02016ee:	a01d                	j	ffffffffc0201714 <strcmp+0x2c>
ffffffffc02016f0:	00054783          	lbu	a5,0(a0)
ffffffffc02016f4:	cb99                	beqz	a5,ffffffffc020170a <strcmp+0x22>
ffffffffc02016f6:	0585                	addi	a1,a1,1
ffffffffc02016f8:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02016fc:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016fe:	fef709e3          	beq	a4,a5,ffffffffc02016f0 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201702:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201706:	9d19                	subw	a0,a0,a4
ffffffffc0201708:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020170a:	0015c703          	lbu	a4,1(a1)
ffffffffc020170e:	4501                	li	a0,0
}
ffffffffc0201710:	9d19                	subw	a0,a0,a4
ffffffffc0201712:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201714:	0005c703          	lbu	a4,0(a1)
ffffffffc0201718:	4501                	li	a0,0
ffffffffc020171a:	b7f5                	j	ffffffffc0201706 <strcmp+0x1e>

ffffffffc020171c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020171c:	ce01                	beqz	a2,ffffffffc0201734 <strncmp+0x18>
ffffffffc020171e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201722:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201724:	cb91                	beqz	a5,ffffffffc0201738 <strncmp+0x1c>
ffffffffc0201726:	0005c703          	lbu	a4,0(a1)
ffffffffc020172a:	00f71763          	bne	a4,a5,ffffffffc0201738 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc020172e:	0505                	addi	a0,a0,1
ffffffffc0201730:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201732:	f675                	bnez	a2,ffffffffc020171e <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201734:	4501                	li	a0,0
ffffffffc0201736:	8082                	ret
ffffffffc0201738:	00054503          	lbu	a0,0(a0)
ffffffffc020173c:	0005c783          	lbu	a5,0(a1)
ffffffffc0201740:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201742:	8082                	ret

ffffffffc0201744 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201744:	ca01                	beqz	a2,ffffffffc0201754 <memset+0x10>
ffffffffc0201746:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201748:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020174a:	0785                	addi	a5,a5,1
ffffffffc020174c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201750:	fef61de3          	bne	a2,a5,ffffffffc020174a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201754:	8082                	ret
