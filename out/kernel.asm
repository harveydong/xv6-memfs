
out/kernel.elf:     file format elf64-x86-64


Disassembly of section .text:

ffffffff80100000 <begin>:
ffffffff80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%rax),%dh
ffffffff80100006:	01 00                	add    %eax,(%rax)
ffffffff80100008:	fe 4f 51             	decb   0x51(%rdi)
ffffffff8010000b:	e4 00                	in     $0x0,%al
ffffffff8010000d:	00 10                	add    %dl,(%rax)
ffffffff8010000f:	00 00                	add    %al,(%rax)
ffffffff80100011:	00 10                	add    %dl,(%rax)
ffffffff80100013:	00 00                	add    %al,(%rax)
ffffffff80100015:	a0 18 00 00 60 19 00 	movabs 0x20001960000018,%al
ffffffff8010001c:	20 00 
ffffffff8010001e:	10 00                	adc    %al,(%rax)

ffffffff80100020 <mboot_entry>:
  .long mboot_entry_addr

mboot_entry:

# zero 4 pages for our bootstrap page tables
  xor %eax, %eax
ffffffff80100020:	31 c0                	xor    %eax,%eax
  mov $0x1000, %edi
ffffffff80100022:	bf 00 10 00 00       	mov    $0x1000,%edi
  mov $0x5000, %ecx
ffffffff80100027:	b9 00 50 00 00       	mov    $0x5000,%ecx
  rep stosb
ffffffff8010002c:	f3 aa                	rep stos %al,%es:(%rdi)

# P4ML[0] -> 0x2000 (PDPT-A)
  mov $(0x2000 | 3), %eax
ffffffff8010002e:	b8 03 20 00 00       	mov    $0x2003,%eax
  mov %eax, 0x1000
ffffffff80100033:	a3 00 10 00 00 b8 03 	movabs %eax,0x3003b800001000
ffffffff8010003a:	30 00 

# P4ML[511] -> 0x3000 (PDPT-B)
  mov $(0x3000 | 3), %eax
ffffffff8010003c:	00 a3 f8 1f 00 00    	add    %ah,0x1ff8(%rbx)
  mov %eax, 0x1FF8

# PDPT-A[0] -> 0x4000 (PD)
  mov $(0x4000 | 3), %eax
ffffffff80100042:	b8 03 40 00 00       	mov    $0x4003,%eax
  mov %eax, 0x2000
ffffffff80100047:	a3 00 20 00 00 b8 03 	movabs %eax,0x4003b800002000
ffffffff8010004e:	40 00 

# PDPT-B[510] -> 0x4000 (PD)
  mov $(0x4000 | 3), %eax
ffffffff80100050:	00 a3 f0 3f 00 00    	add    %ah,0x3ff0(%rbx)
  mov %eax, 0x3FF0

# PD[0..511] -> 0..1022MB
  mov $0x83, %eax
ffffffff80100056:	b8 83 00 00 00       	mov    $0x83,%eax
  mov $0x4000, %ebx
ffffffff8010005b:	bb 00 40 00 00       	mov    $0x4000,%ebx
  mov $512, %ecx
ffffffff80100060:	b9 00 02 00 00       	mov    $0x200,%ecx

ffffffff80100065 <ptbl_loop>:
ptbl_loop:
  mov %eax, (%ebx)
ffffffff80100065:	89 03                	mov    %eax,(%rbx)
  add $0x200000, %eax
ffffffff80100067:	05 00 00 20 00       	add    $0x200000,%eax
  add $0x8, %ebx
ffffffff8010006c:	83 c3 08             	add    $0x8,%ebx
  dec %ecx
ffffffff8010006f:	49 75 f3             	rex.WB jne ffffffff80100065 <ptbl_loop>

# Clear ebx for initial processor boot.
# When secondary processors boot, they'll call through
# entry32mp (from entryother), but with a nonzero ebx.
# We'll reuse these bootstrap pagetables and GDT.
  xor %ebx, %ebx
ffffffff80100072:	31 db                	xor    %ebx,%ebx

ffffffff80100074 <entry32mp>:

.global entry32mp
entry32mp:
# CR3 -> 0x1000 (P4ML)
  mov $0x1000, %eax
ffffffff80100074:	b8 00 10 00 00       	mov    $0x1000,%eax
  mov %eax, %cr3
ffffffff80100079:	0f 22 d8             	mov    %rax,%cr3

  lgdt (gdtr64 - mboot_header + mboot_load_addr)
ffffffff8010007c:	0f 01 15 b0 00 10 00 	lgdt   0x1000b0(%rip)        # ffffffff80200133 <end+0x6a133>

# Enable PAE - CR4.PAE=1
  mov %cr4, %eax
ffffffff80100083:	0f 20 e0             	mov    %cr4,%rax
  bts $5, %eax
ffffffff80100086:	0f ba e8 05          	bts    $0x5,%eax
  mov %eax, %cr4
ffffffff8010008a:	0f 22 e0             	mov    %rax,%cr4

# enable long mode - EFER.LME=1
  mov $0xc0000080, %ecx
ffffffff8010008d:	b9 80 00 00 c0       	mov    $0xc0000080,%ecx
  rdmsr
ffffffff80100092:	0f 32                	rdmsr  
  bts $8, %eax
ffffffff80100094:	0f ba e8 08          	bts    $0x8,%eax
  wrmsr
ffffffff80100098:	0f 30                	wrmsr  

# enable paging
  mov %cr0, %eax
ffffffff8010009a:	0f 20 c0             	mov    %cr0,%rax
  bts $31, %eax
ffffffff8010009d:	0f ba e8 1f          	bts    $0x1f,%eax
  mov %eax, %cr0
ffffffff801000a1:	0f 22 c0             	mov    %rax,%cr0

# shift to 64bit segment
  ljmp $8,$(entry64low - mboot_header + mboot_load_addr)
ffffffff801000a4:	ea                   	(bad)  
ffffffff801000a5:	e0 00                	loopne ffffffff801000a7 <entry32mp+0x33>
ffffffff801000a7:	10 00                	adc    %al,(%rax)
ffffffff801000a9:	08 00                	or     %al,(%rax)
ffffffff801000ab:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

ffffffff801000b0 <gdtr64>:
ffffffff801000b0:	17                   	(bad)  
ffffffff801000b1:	00 c0                	add    %al,%al
ffffffff801000b3:	00 10                	add    %dl,(%rax)
ffffffff801000b5:	00 00                	add    %al,(%rax)
ffffffff801000b7:	00 00                	add    %al,(%rax)
ffffffff801000b9:	00 66 0f             	add    %ah,0xf(%rsi)
ffffffff801000bc:	1f                   	(bad)  
ffffffff801000bd:	44 00 00             	add    %r8b,(%rax)

ffffffff801000c0 <gdt64_begin>:
	...
ffffffff801000cc:	00 98 20 00 00 00    	add    %bl,0x20(%rax)
ffffffff801000d2:	00 00                	add    %al,(%rax)
ffffffff801000d4:	00                   	.byte 0x0
ffffffff801000d5:	90                   	nop
	...

ffffffff801000d8 <gdt64_end>:
ffffffff801000d8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffffffff801000df:	00 

ffffffff801000e0 <entry64low>:
gdt64_end:

.align 16
.code64
entry64low:
  movq $entry64high, %rax
ffffffff801000e0:	48 c7 c0 e9 00 10 80 	mov    $0xffffffff801000e9,%rax
  jmp *%rax
ffffffff801000e7:	ff e0                	jmpq   *%rax

ffffffff801000e9 <_start>:
.global _start
_start:
entry64high:

# ensure data segment registers are sane
  xor %rax, %rax
ffffffff801000e9:	48 31 c0             	xor    %rax,%rax
  mov %ax, %ss
ffffffff801000ec:	8e d0                	mov    %eax,%ss
  mov %ax, %ds
ffffffff801000ee:	8e d8                	mov    %eax,%ds
  mov %ax, %es
ffffffff801000f0:	8e c0                	mov    %eax,%es
  mov %ax, %fs
ffffffff801000f2:	8e e0                	mov    %eax,%fs
  mov %ax, %gs
ffffffff801000f4:	8e e8                	mov    %eax,%gs

# check to see if we're booting a secondary core
  test %ebx, %ebx
ffffffff801000f6:	85 db                	test   %ebx,%ebx
  jnz entry64mp
ffffffff801000f8:	75 11                	jne    ffffffff8010010b <entry64mp>

# setup initial stack
  mov $0xFFFFFFFF80010000, %rax
ffffffff801000fa:	48 c7 c0 00 00 01 80 	mov    $0xffffffff80010000,%rax
  mov %rax, %rsp
ffffffff80100101:	48 89 c4             	mov    %rax,%rsp

# enter main()
  jmp main
ffffffff80100104:	e9 4a 45 00 00       	jmpq   ffffffff80104653 <main>

ffffffff80100109 <__deadloop>:

.global __deadloop
__deadloop:
# we should never return here...
  jmp .
ffffffff80100109:	eb fe                	jmp    ffffffff80100109 <__deadloop>

ffffffff8010010b <entry64mp>:

entry64mp:
# obtain kstack from data block before entryother
  mov $0x7000, %rax
ffffffff8010010b:	48 c7 c0 00 70 00 00 	mov    $0x7000,%rax
  mov -16(%rax), %rsp
ffffffff80100112:	48 8b 60 f0          	mov    -0x10(%rax),%rsp
  jmp mpenter
ffffffff80100116:	e9 f4 45 00 00       	jmpq   ffffffff8010470f <mpenter>

ffffffff8010011b <wrmsr>:

.global wrmsr
wrmsr:
  mov %rdi, %rcx     # arg0 -> msrnum
ffffffff8010011b:	48 89 f9             	mov    %rdi,%rcx
  mov %rsi, %rax     # val.low -> eax
ffffffff8010011e:	48 89 f0             	mov    %rsi,%rax
  shr $32, %rsi
ffffffff80100121:	48 c1 ee 20          	shr    $0x20,%rsi
  mov %rsi, %rdx     # val.high -> edx
ffffffff80100125:	48 89 f2             	mov    %rsi,%rdx
  wrmsr
ffffffff80100128:	0f 30                	wrmsr  
  retq
ffffffff8010012a:	c3                   	retq   

ffffffff8010012b <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
ffffffff8010012b:	55                   	push   %rbp
ffffffff8010012c:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010012f:	48 83 ec 10          	sub    $0x10,%rsp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
ffffffff80100133:	48 c7 c6 08 a5 10 80 	mov    $0xffffffff8010a508,%rsi
ffffffff8010013a:	48 c7 c7 00 a0 18 80 	mov    $0xffffffff8018a000,%rdi
ffffffff80100141:	e8 23 67 00 00       	callq  ffffffff80106869 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
ffffffff80100146:	48 c7 05 d7 df 08 00 	movq   $0xffffffff8018e118,0x8dfd7(%rip)        # ffffffff8018e128 <bcache+0x4128>
ffffffff8010014d:	18 e1 18 80 
  bcache.head.next = &bcache.head;
ffffffff80100151:	48 c7 05 d4 df 08 00 	movq   $0xffffffff8018e118,0x8dfd4(%rip)        # ffffffff8018e130 <bcache+0x4130>
ffffffff80100158:	18 e1 18 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
ffffffff8010015c:	48 c7 45 f8 68 a0 18 	movq   $0xffffffff8018a068,-0x8(%rbp)
ffffffff80100163:	80 
ffffffff80100164:	eb 48                	jmp    ffffffff801001ae <binit+0x83>
    b->next = bcache.head.next;
ffffffff80100166:	48 8b 15 c3 df 08 00 	mov    0x8dfc3(%rip),%rdx        # ffffffff8018e130 <bcache+0x4130>
ffffffff8010016d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100171:	48 89 50 18          	mov    %rdx,0x18(%rax)
    b->prev = &bcache.head;
ffffffff80100175:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100179:	48 c7 40 10 18 e1 18 	movq   $0xffffffff8018e118,0x10(%rax)
ffffffff80100180:	80 
    b->dev = -1;
ffffffff80100181:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100185:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%rax)
    bcache.head.next->prev = b;
ffffffff8010018c:	48 8b 05 9d df 08 00 	mov    0x8df9d(%rip),%rax        # ffffffff8018e130 <bcache+0x4130>
ffffffff80100193:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80100197:	48 89 50 10          	mov    %rdx,0x10(%rax)
    bcache.head.next = b;
ffffffff8010019b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010019f:	48 89 05 8a df 08 00 	mov    %rax,0x8df8a(%rip)        # ffffffff8018e130 <bcache+0x4130>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
ffffffff801001a6:	48 81 45 f8 28 02 00 	addq   $0x228,-0x8(%rbp)
ffffffff801001ad:	00 
ffffffff801001ae:	48 c7 c0 18 e1 18 80 	mov    $0xffffffff8018e118,%rax
ffffffff801001b5:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
ffffffff801001b9:	72 ab                	jb     ffffffff80100166 <binit+0x3b>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
ffffffff801001bb:	90                   	nop
ffffffff801001bc:	c9                   	leaveq 
ffffffff801001bd:	c3                   	retq   

ffffffff801001be <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint blockno)
{
ffffffff801001be:	55                   	push   %rbp
ffffffff801001bf:	48 89 e5             	mov    %rsp,%rbp
ffffffff801001c2:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801001c6:	89 7d ec             	mov    %edi,-0x14(%rbp)
ffffffff801001c9:	89 75 e8             	mov    %esi,-0x18(%rbp)
  struct buf *b;

  acquire(&bcache.lock);
ffffffff801001cc:	48 c7 c7 00 a0 18 80 	mov    $0xffffffff8018a000,%rdi
ffffffff801001d3:	e8 c6 66 00 00       	callq  ffffffff8010689e <acquire>

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
ffffffff801001d8:	48 8b 05 51 df 08 00 	mov    0x8df51(%rip),%rax        # ffffffff8018e130 <bcache+0x4130>
ffffffff801001df:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff801001e3:	eb 6c                	jmp    ffffffff80100251 <bget+0x93>
    if(b->dev == dev && b->blockno == blockno){
ffffffff801001e5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801001e9:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff801001ec:	3b 45 ec             	cmp    -0x14(%rbp),%eax
ffffffff801001ef:	75 54                	jne    ffffffff80100245 <bget+0x87>
ffffffff801001f1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801001f5:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff801001f8:	3b 45 e8             	cmp    -0x18(%rbp),%eax
ffffffff801001fb:	75 48                	jne    ffffffff80100245 <bget+0x87>
      if(!(b->flags & B_BUSY)){
ffffffff801001fd:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100201:	8b 00                	mov    (%rax),%eax
ffffffff80100203:	83 e0 01             	and    $0x1,%eax
ffffffff80100206:	85 c0                	test   %eax,%eax
ffffffff80100208:	75 26                	jne    ffffffff80100230 <bget+0x72>
        b->flags |= B_BUSY;
ffffffff8010020a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010020e:	8b 00                	mov    (%rax),%eax
ffffffff80100210:	83 c8 01             	or     $0x1,%eax
ffffffff80100213:	89 c2                	mov    %eax,%edx
ffffffff80100215:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100219:	89 10                	mov    %edx,(%rax)
        release(&bcache.lock);
ffffffff8010021b:	48 c7 c7 00 a0 18 80 	mov    $0xffffffff8018a000,%rdi
ffffffff80100222:	e8 4e 67 00 00       	callq  ffffffff80106975 <release>
        return b;
ffffffff80100227:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010022b:	e9 a4 00 00 00       	jmpq   ffffffff801002d4 <bget+0x116>
      }
      sleep(b, &bcache.lock);
ffffffff80100230:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100234:	48 c7 c6 00 a0 18 80 	mov    $0xffffffff8018a000,%rsi
ffffffff8010023b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010023e:	e8 de 62 00 00       	callq  ffffffff80106521 <sleep>
      goto loop;
ffffffff80100243:	eb 93                	jmp    ffffffff801001d8 <bget+0x1a>

  acquire(&bcache.lock);

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
ffffffff80100245:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100249:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff8010024d:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80100251:	48 81 7d f8 18 e1 18 	cmpq   $0xffffffff8018e118,-0x8(%rbp)
ffffffff80100258:	80 
ffffffff80100259:	75 8a                	jne    ffffffff801001e5 <bget+0x27>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
ffffffff8010025b:	48 8b 05 c6 de 08 00 	mov    0x8dec6(%rip),%rax        # ffffffff8018e128 <bcache+0x4128>
ffffffff80100262:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80100266:	eb 56                	jmp    ffffffff801002be <bget+0x100>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
ffffffff80100268:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010026c:	8b 00                	mov    (%rax),%eax
ffffffff8010026e:	83 e0 01             	and    $0x1,%eax
ffffffff80100271:	85 c0                	test   %eax,%eax
ffffffff80100273:	75 3d                	jne    ffffffff801002b2 <bget+0xf4>
ffffffff80100275:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100279:	8b 00                	mov    (%rax),%eax
ffffffff8010027b:	83 e0 04             	and    $0x4,%eax
ffffffff8010027e:	85 c0                	test   %eax,%eax
ffffffff80100280:	75 30                	jne    ffffffff801002b2 <bget+0xf4>
      b->dev = dev;
ffffffff80100282:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100286:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80100289:	89 50 04             	mov    %edx,0x4(%rax)
      b->blockno = blockno;
ffffffff8010028c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100290:	8b 55 e8             	mov    -0x18(%rbp),%edx
ffffffff80100293:	89 50 08             	mov    %edx,0x8(%rax)
      b->flags = B_BUSY;
ffffffff80100296:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010029a:	c7 00 01 00 00 00    	movl   $0x1,(%rax)
      release(&bcache.lock);
ffffffff801002a0:	48 c7 c7 00 a0 18 80 	mov    $0xffffffff8018a000,%rdi
ffffffff801002a7:	e8 c9 66 00 00       	callq  ffffffff80106975 <release>
      return b;
ffffffff801002ac:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801002b0:	eb 22                	jmp    ffffffff801002d4 <bget+0x116>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
ffffffff801002b2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801002b6:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff801002ba:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff801002be:	48 81 7d f8 18 e1 18 	cmpq   $0xffffffff8018e118,-0x8(%rbp)
ffffffff801002c5:	80 
ffffffff801002c6:	75 a0                	jne    ffffffff80100268 <bget+0xaa>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
ffffffff801002c8:	48 c7 c7 0f a5 10 80 	mov    $0xffffffff8010a50f,%rdi
ffffffff801002cf:	e8 2b 06 00 00       	callq  ffffffff801008ff <panic>
}
ffffffff801002d4:	c9                   	leaveq 
ffffffff801002d5:	c3                   	retq   

ffffffff801002d6 <bread>:

// Return a B_BUSY buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
ffffffff801002d6:	55                   	push   %rbp
ffffffff801002d7:	48 89 e5             	mov    %rsp,%rbp
ffffffff801002da:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801002de:	89 7d ec             	mov    %edi,-0x14(%rbp)
ffffffff801002e1:	89 75 e8             	mov    %esi,-0x18(%rbp)
  struct buf *b;

  b = bget(dev, blockno);
ffffffff801002e4:	8b 55 e8             	mov    -0x18(%rbp),%edx
ffffffff801002e7:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff801002ea:	89 d6                	mov    %edx,%esi
ffffffff801002ec:	89 c7                	mov    %eax,%edi
ffffffff801002ee:	e8 cb fe ff ff       	callq  ffffffff801001be <bget>
ffffffff801002f3:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if(!(b->flags & B_VALID)) {
ffffffff801002f7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801002fb:	8b 00                	mov    (%rax),%eax
ffffffff801002fd:	83 e0 02             	and    $0x2,%eax
ffffffff80100300:	85 c0                	test   %eax,%eax
ffffffff80100302:	75 0c                	jne    ffffffff80100310 <bread+0x3a>
    iderw(b);
ffffffff80100304:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100308:	48 89 c7             	mov    %rax,%rdi
ffffffff8010030b:	e8 fe a0 00 00       	callq  ffffffff8010a40e <iderw>
  }
  return b;
ffffffff80100310:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80100314:	c9                   	leaveq 
ffffffff80100315:	c3                   	retq   

ffffffff80100316 <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
ffffffff80100316:	55                   	push   %rbp
ffffffff80100317:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010031a:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff8010031e:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  if((b->flags & B_BUSY) == 0)
ffffffff80100322:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100326:	8b 00                	mov    (%rax),%eax
ffffffff80100328:	83 e0 01             	and    $0x1,%eax
ffffffff8010032b:	85 c0                	test   %eax,%eax
ffffffff8010032d:	75 0c                	jne    ffffffff8010033b <bwrite+0x25>
    panic("bwrite");
ffffffff8010032f:	48 c7 c7 20 a5 10 80 	mov    $0xffffffff8010a520,%rdi
ffffffff80100336:	e8 c4 05 00 00       	callq  ffffffff801008ff <panic>
  b->flags |= B_DIRTY;
ffffffff8010033b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010033f:	8b 00                	mov    (%rax),%eax
ffffffff80100341:	83 c8 04             	or     $0x4,%eax
ffffffff80100344:	89 c2                	mov    %eax,%edx
ffffffff80100346:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010034a:	89 10                	mov    %edx,(%rax)
  iderw(b);
ffffffff8010034c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100350:	48 89 c7             	mov    %rax,%rdi
ffffffff80100353:	e8 b6 a0 00 00       	callq  ffffffff8010a40e <iderw>
}
ffffffff80100358:	90                   	nop
ffffffff80100359:	c9                   	leaveq 
ffffffff8010035a:	c3                   	retq   

ffffffff8010035b <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
ffffffff8010035b:	55                   	push   %rbp
ffffffff8010035c:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010035f:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80100363:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  if((b->flags & B_BUSY) == 0)
ffffffff80100367:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010036b:	8b 00                	mov    (%rax),%eax
ffffffff8010036d:	83 e0 01             	and    $0x1,%eax
ffffffff80100370:	85 c0                	test   %eax,%eax
ffffffff80100372:	75 0c                	jne    ffffffff80100380 <brelse+0x25>
    panic("brelse");
ffffffff80100374:	48 c7 c7 27 a5 10 80 	mov    $0xffffffff8010a527,%rdi
ffffffff8010037b:	e8 7f 05 00 00       	callq  ffffffff801008ff <panic>

  acquire(&bcache.lock);
ffffffff80100380:	48 c7 c7 00 a0 18 80 	mov    $0xffffffff8018a000,%rdi
ffffffff80100387:	e8 12 65 00 00       	callq  ffffffff8010689e <acquire>

  b->next->prev = b->prev;
ffffffff8010038c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80100390:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff80100394:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80100398:	48 8b 52 10          	mov    0x10(%rdx),%rdx
ffffffff8010039c:	48 89 50 10          	mov    %rdx,0x10(%rax)
  b->prev->next = b->next;
ffffffff801003a0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801003a4:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff801003a8:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff801003ac:	48 8b 52 18          	mov    0x18(%rdx),%rdx
ffffffff801003b0:	48 89 50 18          	mov    %rdx,0x18(%rax)
  b->next = bcache.head.next;
ffffffff801003b4:	48 8b 15 75 dd 08 00 	mov    0x8dd75(%rip),%rdx        # ffffffff8018e130 <bcache+0x4130>
ffffffff801003bb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801003bf:	48 89 50 18          	mov    %rdx,0x18(%rax)
  b->prev = &bcache.head;
ffffffff801003c3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801003c7:	48 c7 40 10 18 e1 18 	movq   $0xffffffff8018e118,0x10(%rax)
ffffffff801003ce:	80 
  bcache.head.next->prev = b;
ffffffff801003cf:	48 8b 05 5a dd 08 00 	mov    0x8dd5a(%rip),%rax        # ffffffff8018e130 <bcache+0x4130>
ffffffff801003d6:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff801003da:	48 89 50 10          	mov    %rdx,0x10(%rax)
  bcache.head.next = b;
ffffffff801003de:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801003e2:	48 89 05 47 dd 08 00 	mov    %rax,0x8dd47(%rip)        # ffffffff8018e130 <bcache+0x4130>

  b->flags &= ~B_BUSY;
ffffffff801003e9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801003ed:	8b 00                	mov    (%rax),%eax
ffffffff801003ef:	83 e0 fe             	and    $0xfffffffe,%eax
ffffffff801003f2:	89 c2                	mov    %eax,%edx
ffffffff801003f4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801003f8:	89 10                	mov    %edx,(%rax)
  wakeup(b);
ffffffff801003fa:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801003fe:	48 89 c7             	mov    %rax,%rdi
ffffffff80100401:	e8 2e 62 00 00       	callq  ffffffff80106634 <wakeup>

  release(&bcache.lock);
ffffffff80100406:	48 c7 c7 00 a0 18 80 	mov    $0xffffffff8018a000,%rdi
ffffffff8010040d:	e8 63 65 00 00       	callq  ffffffff80106975 <release>
}
ffffffff80100412:	90                   	nop
ffffffff80100413:	c9                   	leaveq 
ffffffff80100414:	c3                   	retq   

ffffffff80100415 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
ffffffff80100415:	55                   	push   %rbp
ffffffff80100416:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100419:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff8010041d:	89 f8                	mov    %edi,%eax
ffffffff8010041f:	66 89 45 ec          	mov    %ax,-0x14(%rbp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
ffffffff80100423:	0f b7 45 ec          	movzwl -0x14(%rbp),%eax
ffffffff80100427:	89 c2                	mov    %eax,%edx
ffffffff80100429:	ec                   	in     (%dx),%al
ffffffff8010042a:	88 45 ff             	mov    %al,-0x1(%rbp)
  return data;
ffffffff8010042d:	0f b6 45 ff          	movzbl -0x1(%rbp),%eax
}
ffffffff80100431:	c9                   	leaveq 
ffffffff80100432:	c3                   	retq   

ffffffff80100433 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
ffffffff80100433:	55                   	push   %rbp
ffffffff80100434:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100437:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff8010043b:	89 fa                	mov    %edi,%edx
ffffffff8010043d:	89 f0                	mov    %esi,%eax
ffffffff8010043f:	66 89 55 fc          	mov    %dx,-0x4(%rbp)
ffffffff80100443:	88 45 f8             	mov    %al,-0x8(%rbp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
ffffffff80100446:	0f b6 45 f8          	movzbl -0x8(%rbp),%eax
ffffffff8010044a:	0f b7 55 fc          	movzwl -0x4(%rbp),%edx
ffffffff8010044e:	ee                   	out    %al,(%dx)
}
ffffffff8010044f:	90                   	nop
ffffffff80100450:	c9                   	leaveq 
ffffffff80100451:	c3                   	retq   

ffffffff80100452 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
ffffffff80100452:	55                   	push   %rbp
ffffffff80100453:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100456:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010045a:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff8010045e:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  volatile ushort pd[5];

  pd[0] = size-1;
ffffffff80100461:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80100464:	83 e8 01             	sub    $0x1,%eax
ffffffff80100467:	66 89 45 f0          	mov    %ax,-0x10(%rbp)
  pd[1] = (uintp)p;
ffffffff8010046b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010046f:	66 89 45 f2          	mov    %ax,-0xe(%rbp)
  pd[2] = (uintp)p >> 16;
ffffffff80100473:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100477:	48 c1 e8 10          	shr    $0x10,%rax
ffffffff8010047b:	66 89 45 f4          	mov    %ax,-0xc(%rbp)
#if X64
  pd[3] = (uintp)p >> 32;
ffffffff8010047f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100483:	48 c1 e8 20          	shr    $0x20,%rax
ffffffff80100487:	66 89 45 f6          	mov    %ax,-0xa(%rbp)
  pd[4] = (uintp)p >> 48;
ffffffff8010048b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010048f:	48 c1 e8 30          	shr    $0x30,%rax
ffffffff80100493:	66 89 45 f8          	mov    %ax,-0x8(%rbp)
#endif
  asm volatile("lidt (%0)" : : "r" (pd));
ffffffff80100497:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff8010049b:	0f 01 18             	lidt   (%rax)
}
ffffffff8010049e:	90                   	nop
ffffffff8010049f:	c9                   	leaveq 
ffffffff801004a0:	c3                   	retq   

ffffffff801004a1 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
ffffffff801004a1:	55                   	push   %rbp
ffffffff801004a2:	48 89 e5             	mov    %rsp,%rbp
  asm volatile("cli");
ffffffff801004a5:	fa                   	cli    
}
ffffffff801004a6:	90                   	nop
ffffffff801004a7:	5d                   	pop    %rbp
ffffffff801004a8:	c3                   	retq   

ffffffff801004a9 <printptr>:
} cons;

static char digits[] = "0123456789abcdef";

static void
printptr(uintp x) {
ffffffff801004a9:	55                   	push   %rbp
ffffffff801004aa:	48 89 e5             	mov    %rsp,%rbp
ffffffff801004ad:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801004b1:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  int i;
  for (i = 0; i < (sizeof(uintp) * 2); i++, x <<= 4)
ffffffff801004b5:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801004bc:	eb 22                	jmp    ffffffff801004e0 <printptr+0x37>
    consputc(digits[x >> (sizeof(uintp) * 8 - 4)]);
ffffffff801004be:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801004c2:	48 c1 e8 3c          	shr    $0x3c,%rax
ffffffff801004c6:	0f b6 80 00 c0 10 80 	movzbl -0x7fef4000(%rax),%eax
ffffffff801004cd:	0f be c0             	movsbl %al,%eax
ffffffff801004d0:	89 c7                	mov    %eax,%edi
ffffffff801004d2:	e8 53 06 00 00       	callq  ffffffff80100b2a <consputc>
static char digits[] = "0123456789abcdef";

static void
printptr(uintp x) {
  int i;
  for (i = 0; i < (sizeof(uintp) * 2); i++, x <<= 4)
ffffffff801004d7:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801004db:	48 c1 65 e8 04       	shlq   $0x4,-0x18(%rbp)
ffffffff801004e0:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801004e3:	83 f8 0f             	cmp    $0xf,%eax
ffffffff801004e6:	76 d6                	jbe    ffffffff801004be <printptr+0x15>
    consputc(digits[x >> (sizeof(uintp) * 8 - 4)]);
}
ffffffff801004e8:	90                   	nop
ffffffff801004e9:	c9                   	leaveq 
ffffffff801004ea:	c3                   	retq   

ffffffff801004eb <printint>:

static void
printint(int xx, int base, int sign)
{
ffffffff801004eb:	55                   	push   %rbp
ffffffff801004ec:	48 89 e5             	mov    %rsp,%rbp
ffffffff801004ef:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff801004f3:	89 7d dc             	mov    %edi,-0x24(%rbp)
ffffffff801004f6:	89 75 d8             	mov    %esi,-0x28(%rbp)
ffffffff801004f9:	89 55 d4             	mov    %edx,-0x2c(%rbp)
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
ffffffff801004fc:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
ffffffff80100500:	74 1c                	je     ffffffff8010051e <printint+0x33>
ffffffff80100502:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100505:	c1 e8 1f             	shr    $0x1f,%eax
ffffffff80100508:	0f b6 c0             	movzbl %al,%eax
ffffffff8010050b:	89 45 d4             	mov    %eax,-0x2c(%rbp)
ffffffff8010050e:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
ffffffff80100512:	74 0a                	je     ffffffff8010051e <printint+0x33>
    x = -xx;
ffffffff80100514:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100517:	f7 d8                	neg    %eax
ffffffff80100519:	89 45 f8             	mov    %eax,-0x8(%rbp)
ffffffff8010051c:	eb 06                	jmp    ffffffff80100524 <printint+0x39>
  else
    x = xx;
ffffffff8010051e:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100521:	89 45 f8             	mov    %eax,-0x8(%rbp)

  i = 0;
ffffffff80100524:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  do{
    buf[i++] = digits[x % base];
ffffffff8010052b:	8b 4d fc             	mov    -0x4(%rbp),%ecx
ffffffff8010052e:	8d 41 01             	lea    0x1(%rcx),%eax
ffffffff80100531:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff80100534:	8b 75 d8             	mov    -0x28(%rbp),%esi
ffffffff80100537:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff8010053a:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff8010053f:	f7 f6                	div    %esi
ffffffff80100541:	89 d0                	mov    %edx,%eax
ffffffff80100543:	89 c0                	mov    %eax,%eax
ffffffff80100545:	0f b6 90 00 c0 10 80 	movzbl -0x7fef4000(%rax),%edx
ffffffff8010054c:	48 63 c1             	movslq %ecx,%rax
ffffffff8010054f:	88 54 05 e0          	mov    %dl,-0x20(%rbp,%rax,1)
  }while((x /= base) != 0);
ffffffff80100553:	8b 7d d8             	mov    -0x28(%rbp),%edi
ffffffff80100556:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80100559:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff8010055e:	f7 f7                	div    %edi
ffffffff80100560:	89 45 f8             	mov    %eax,-0x8(%rbp)
ffffffff80100563:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
ffffffff80100567:	75 c2                	jne    ffffffff8010052b <printint+0x40>

  if(sign)
ffffffff80100569:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
ffffffff8010056d:	74 26                	je     ffffffff80100595 <printint+0xaa>
    buf[i++] = '-';
ffffffff8010056f:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100572:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80100575:	89 55 fc             	mov    %edx,-0x4(%rbp)
ffffffff80100578:	48 98                	cltq   
ffffffff8010057a:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%rbp,%rax,1)

  while(--i >= 0)
ffffffff8010057f:	eb 14                	jmp    ffffffff80100595 <printint+0xaa>
    consputc(buf[i]);
ffffffff80100581:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100584:	48 98                	cltq   
ffffffff80100586:	0f b6 44 05 e0       	movzbl -0x20(%rbp,%rax,1),%eax
ffffffff8010058b:	0f be c0             	movsbl %al,%eax
ffffffff8010058e:	89 c7                	mov    %eax,%edi
ffffffff80100590:	e8 95 05 00 00       	callq  ffffffff80100b2a <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
ffffffff80100595:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
ffffffff80100599:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff8010059d:	79 e2                	jns    ffffffff80100581 <printint+0x96>
    consputc(buf[i]);
}
ffffffff8010059f:	90                   	nop
ffffffff801005a0:	c9                   	leaveq 
ffffffff801005a1:	c3                   	retq   

ffffffff801005a2 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
ffffffff801005a2:	55                   	push   %rbp
ffffffff801005a3:	48 89 e5             	mov    %rsp,%rbp
ffffffff801005a6:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
ffffffff801005ad:	48 89 bd 18 ff ff ff 	mov    %rdi,-0xe8(%rbp)
ffffffff801005b4:	48 89 b5 58 ff ff ff 	mov    %rsi,-0xa8(%rbp)
ffffffff801005bb:	48 89 95 60 ff ff ff 	mov    %rdx,-0xa0(%rbp)
ffffffff801005c2:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
ffffffff801005c9:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
ffffffff801005d0:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
ffffffff801005d7:	84 c0                	test   %al,%al
ffffffff801005d9:	74 20                	je     ffffffff801005fb <cprintf+0x59>
ffffffff801005db:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
ffffffff801005df:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
ffffffff801005e3:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
ffffffff801005e7:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
ffffffff801005eb:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
ffffffff801005ef:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
ffffffff801005f3:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
ffffffff801005f7:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  va_list ap;
  int i, c, locking;
  char *s;

  va_start(ap, fmt);
ffffffff801005fb:	c7 85 20 ff ff ff 08 	movl   $0x8,-0xe0(%rbp)
ffffffff80100602:	00 00 00 
ffffffff80100605:	c7 85 24 ff ff ff 30 	movl   $0x30,-0xdc(%rbp)
ffffffff8010060c:	00 00 00 
ffffffff8010060f:	48 8d 45 10          	lea    0x10(%rbp),%rax
ffffffff80100613:	48 89 85 28 ff ff ff 	mov    %rax,-0xd8(%rbp)
ffffffff8010061a:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
ffffffff80100621:	48 89 85 30 ff ff ff 	mov    %rax,-0xd0(%rbp)

  locking = cons.locking;
ffffffff80100628:	8b 05 7a de 08 00    	mov    0x8de7a(%rip),%eax        # ffffffff8018e4a8 <cons+0x68>
ffffffff8010062e:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%rbp)
  if(locking)
ffffffff80100634:	83 bd 3c ff ff ff 00 	cmpl   $0x0,-0xc4(%rbp)
ffffffff8010063b:	74 0c                	je     ffffffff80100649 <cprintf+0xa7>
    acquire(&cons.lock);
ffffffff8010063d:	48 c7 c7 40 e4 18 80 	mov    $0xffffffff8018e440,%rdi
ffffffff80100644:	e8 55 62 00 00       	callq  ffffffff8010689e <acquire>

  if (fmt == 0)
ffffffff80100649:	48 83 bd 18 ff ff ff 	cmpq   $0x0,-0xe8(%rbp)
ffffffff80100650:	00 
ffffffff80100651:	75 0c                	jne    ffffffff8010065f <cprintf+0xbd>
    panic("null fmt");
ffffffff80100653:	48 c7 c7 2e a5 10 80 	mov    $0xffffffff8010a52e,%rdi
ffffffff8010065a:	e8 a0 02 00 00       	callq  ffffffff801008ff <panic>

  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
ffffffff8010065f:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%rbp)
ffffffff80100666:	00 00 00 
ffffffff80100669:	e9 45 02 00 00       	jmpq   ffffffff801008b3 <cprintf+0x311>
    if(c != '%'){
ffffffff8010066e:	83 bd 38 ff ff ff 25 	cmpl   $0x25,-0xc8(%rbp)
ffffffff80100675:	74 12                	je     ffffffff80100689 <cprintf+0xe7>
      consputc(c);
ffffffff80100677:	8b 85 38 ff ff ff    	mov    -0xc8(%rbp),%eax
ffffffff8010067d:	89 c7                	mov    %eax,%edi
ffffffff8010067f:	e8 a6 04 00 00       	callq  ffffffff80100b2a <consputc>
      continue;
ffffffff80100684:	e9 23 02 00 00       	jmpq   ffffffff801008ac <cprintf+0x30a>
    }
    c = fmt[++i] & 0xff;
ffffffff80100689:	83 85 4c ff ff ff 01 	addl   $0x1,-0xb4(%rbp)
ffffffff80100690:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
ffffffff80100696:	48 63 d0             	movslq %eax,%rdx
ffffffff80100699:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
ffffffff801006a0:	48 01 d0             	add    %rdx,%rax
ffffffff801006a3:	0f b6 00             	movzbl (%rax),%eax
ffffffff801006a6:	0f be c0             	movsbl %al,%eax
ffffffff801006a9:	25 ff 00 00 00       	and    $0xff,%eax
ffffffff801006ae:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%rbp)
    if(c == 0)
ffffffff801006b4:	83 bd 38 ff ff ff 00 	cmpl   $0x0,-0xc8(%rbp)
ffffffff801006bb:	0f 84 25 02 00 00    	je     ffffffff801008e6 <cprintf+0x344>
      break;
    switch(c){
ffffffff801006c1:	8b 85 38 ff ff ff    	mov    -0xc8(%rbp),%eax
ffffffff801006c7:	83 f8 70             	cmp    $0x70,%eax
ffffffff801006ca:	0f 84 db 00 00 00    	je     ffffffff801007ab <cprintf+0x209>
ffffffff801006d0:	83 f8 70             	cmp    $0x70,%eax
ffffffff801006d3:	7f 13                	jg     ffffffff801006e8 <cprintf+0x146>
ffffffff801006d5:	83 f8 25             	cmp    $0x25,%eax
ffffffff801006d8:	0f 84 aa 01 00 00    	je     ffffffff80100888 <cprintf+0x2e6>
ffffffff801006de:	83 f8 64             	cmp    $0x64,%eax
ffffffff801006e1:	74 18                	je     ffffffff801006fb <cprintf+0x159>
ffffffff801006e3:	e9 ac 01 00 00       	jmpq   ffffffff80100894 <cprintf+0x2f2>
ffffffff801006e8:	83 f8 73             	cmp    $0x73,%eax
ffffffff801006eb:	0f 84 0a 01 00 00    	je     ffffffff801007fb <cprintf+0x259>
ffffffff801006f1:	83 f8 78             	cmp    $0x78,%eax
ffffffff801006f4:	74 5d                	je     ffffffff80100753 <cprintf+0x1b1>
ffffffff801006f6:	e9 99 01 00 00       	jmpq   ffffffff80100894 <cprintf+0x2f2>
    case 'd':
      printint(va_arg(ap, int), 10, 1);
ffffffff801006fb:	8b 85 20 ff ff ff    	mov    -0xe0(%rbp),%eax
ffffffff80100701:	83 f8 30             	cmp    $0x30,%eax
ffffffff80100704:	73 23                	jae    ffffffff80100729 <cprintf+0x187>
ffffffff80100706:	48 8b 85 30 ff ff ff 	mov    -0xd0(%rbp),%rax
ffffffff8010070d:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff80100713:	89 d2                	mov    %edx,%edx
ffffffff80100715:	48 01 d0             	add    %rdx,%rax
ffffffff80100718:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff8010071e:	83 c2 08             	add    $0x8,%edx
ffffffff80100721:	89 95 20 ff ff ff    	mov    %edx,-0xe0(%rbp)
ffffffff80100727:	eb 12                	jmp    ffffffff8010073b <cprintf+0x199>
ffffffff80100729:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
ffffffff80100730:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff80100734:	48 89 95 28 ff ff ff 	mov    %rdx,-0xd8(%rbp)
ffffffff8010073b:	8b 00                	mov    (%rax),%eax
ffffffff8010073d:	ba 01 00 00 00       	mov    $0x1,%edx
ffffffff80100742:	be 0a 00 00 00       	mov    $0xa,%esi
ffffffff80100747:	89 c7                	mov    %eax,%edi
ffffffff80100749:	e8 9d fd ff ff       	callq  ffffffff801004eb <printint>
      break;
ffffffff8010074e:	e9 59 01 00 00       	jmpq   ffffffff801008ac <cprintf+0x30a>
    case 'x':
      printint(va_arg(ap, int), 16, 0);
ffffffff80100753:	8b 85 20 ff ff ff    	mov    -0xe0(%rbp),%eax
ffffffff80100759:	83 f8 30             	cmp    $0x30,%eax
ffffffff8010075c:	73 23                	jae    ffffffff80100781 <cprintf+0x1df>
ffffffff8010075e:	48 8b 85 30 ff ff ff 	mov    -0xd0(%rbp),%rax
ffffffff80100765:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff8010076b:	89 d2                	mov    %edx,%edx
ffffffff8010076d:	48 01 d0             	add    %rdx,%rax
ffffffff80100770:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff80100776:	83 c2 08             	add    $0x8,%edx
ffffffff80100779:	89 95 20 ff ff ff    	mov    %edx,-0xe0(%rbp)
ffffffff8010077f:	eb 12                	jmp    ffffffff80100793 <cprintf+0x1f1>
ffffffff80100781:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
ffffffff80100788:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff8010078c:	48 89 95 28 ff ff ff 	mov    %rdx,-0xd8(%rbp)
ffffffff80100793:	8b 00                	mov    (%rax),%eax
ffffffff80100795:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff8010079a:	be 10 00 00 00       	mov    $0x10,%esi
ffffffff8010079f:	89 c7                	mov    %eax,%edi
ffffffff801007a1:	e8 45 fd ff ff       	callq  ffffffff801004eb <printint>
      break;
ffffffff801007a6:	e9 01 01 00 00       	jmpq   ffffffff801008ac <cprintf+0x30a>
    case 'p':
      printptr(va_arg(ap, uintp));
ffffffff801007ab:	8b 85 20 ff ff ff    	mov    -0xe0(%rbp),%eax
ffffffff801007b1:	83 f8 30             	cmp    $0x30,%eax
ffffffff801007b4:	73 23                	jae    ffffffff801007d9 <cprintf+0x237>
ffffffff801007b6:	48 8b 85 30 ff ff ff 	mov    -0xd0(%rbp),%rax
ffffffff801007bd:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff801007c3:	89 d2                	mov    %edx,%edx
ffffffff801007c5:	48 01 d0             	add    %rdx,%rax
ffffffff801007c8:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff801007ce:	83 c2 08             	add    $0x8,%edx
ffffffff801007d1:	89 95 20 ff ff ff    	mov    %edx,-0xe0(%rbp)
ffffffff801007d7:	eb 12                	jmp    ffffffff801007eb <cprintf+0x249>
ffffffff801007d9:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
ffffffff801007e0:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff801007e4:	48 89 95 28 ff ff ff 	mov    %rdx,-0xd8(%rbp)
ffffffff801007eb:	48 8b 00             	mov    (%rax),%rax
ffffffff801007ee:	48 89 c7             	mov    %rax,%rdi
ffffffff801007f1:	e8 b3 fc ff ff       	callq  ffffffff801004a9 <printptr>
      break;
ffffffff801007f6:	e9 b1 00 00 00       	jmpq   ffffffff801008ac <cprintf+0x30a>
    case 's':
      if((s = va_arg(ap, char*)) == 0)
ffffffff801007fb:	8b 85 20 ff ff ff    	mov    -0xe0(%rbp),%eax
ffffffff80100801:	83 f8 30             	cmp    $0x30,%eax
ffffffff80100804:	73 23                	jae    ffffffff80100829 <cprintf+0x287>
ffffffff80100806:	48 8b 85 30 ff ff ff 	mov    -0xd0(%rbp),%rax
ffffffff8010080d:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff80100813:	89 d2                	mov    %edx,%edx
ffffffff80100815:	48 01 d0             	add    %rdx,%rax
ffffffff80100818:	8b 95 20 ff ff ff    	mov    -0xe0(%rbp),%edx
ffffffff8010081e:	83 c2 08             	add    $0x8,%edx
ffffffff80100821:	89 95 20 ff ff ff    	mov    %edx,-0xe0(%rbp)
ffffffff80100827:	eb 12                	jmp    ffffffff8010083b <cprintf+0x299>
ffffffff80100829:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
ffffffff80100830:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff80100834:	48 89 95 28 ff ff ff 	mov    %rdx,-0xd8(%rbp)
ffffffff8010083b:	48 8b 00             	mov    (%rax),%rax
ffffffff8010083e:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
ffffffff80100845:	48 83 bd 40 ff ff ff 	cmpq   $0x0,-0xc0(%rbp)
ffffffff8010084c:	00 
ffffffff8010084d:	75 29                	jne    ffffffff80100878 <cprintf+0x2d6>
        s = "(null)";
ffffffff8010084f:	48 c7 85 40 ff ff ff 	movq   $0xffffffff8010a537,-0xc0(%rbp)
ffffffff80100856:	37 a5 10 80 
      for(; *s; s++)
ffffffff8010085a:	eb 1c                	jmp    ffffffff80100878 <cprintf+0x2d6>
        consputc(*s);
ffffffff8010085c:	48 8b 85 40 ff ff ff 	mov    -0xc0(%rbp),%rax
ffffffff80100863:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100866:	0f be c0             	movsbl %al,%eax
ffffffff80100869:	89 c7                	mov    %eax,%edi
ffffffff8010086b:	e8 ba 02 00 00       	callq  ffffffff80100b2a <consputc>
      printptr(va_arg(ap, uintp));
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
ffffffff80100870:	48 83 85 40 ff ff ff 	addq   $0x1,-0xc0(%rbp)
ffffffff80100877:	01 
ffffffff80100878:	48 8b 85 40 ff ff ff 	mov    -0xc0(%rbp),%rax
ffffffff8010087f:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100882:	84 c0                	test   %al,%al
ffffffff80100884:	75 d6                	jne    ffffffff8010085c <cprintf+0x2ba>
        consputc(*s);
      break;
ffffffff80100886:	eb 24                	jmp    ffffffff801008ac <cprintf+0x30a>
    case '%':
      consputc('%');
ffffffff80100888:	bf 25 00 00 00       	mov    $0x25,%edi
ffffffff8010088d:	e8 98 02 00 00       	callq  ffffffff80100b2a <consputc>
      break;
ffffffff80100892:	eb 18                	jmp    ffffffff801008ac <cprintf+0x30a>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
ffffffff80100894:	bf 25 00 00 00       	mov    $0x25,%edi
ffffffff80100899:	e8 8c 02 00 00       	callq  ffffffff80100b2a <consputc>
      consputc(c);
ffffffff8010089e:	8b 85 38 ff ff ff    	mov    -0xc8(%rbp),%eax
ffffffff801008a4:	89 c7                	mov    %eax,%edi
ffffffff801008a6:	e8 7f 02 00 00       	callq  ffffffff80100b2a <consputc>
      break;
ffffffff801008ab:	90                   	nop
    acquire(&cons.lock);

  if (fmt == 0)
    panic("null fmt");

  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
ffffffff801008ac:	83 85 4c ff ff ff 01 	addl   $0x1,-0xb4(%rbp)
ffffffff801008b3:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
ffffffff801008b9:	48 63 d0             	movslq %eax,%rdx
ffffffff801008bc:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
ffffffff801008c3:	48 01 d0             	add    %rdx,%rax
ffffffff801008c6:	0f b6 00             	movzbl (%rax),%eax
ffffffff801008c9:	0f be c0             	movsbl %al,%eax
ffffffff801008cc:	25 ff 00 00 00       	and    $0xff,%eax
ffffffff801008d1:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%rbp)
ffffffff801008d7:	83 bd 38 ff ff ff 00 	cmpl   $0x0,-0xc8(%rbp)
ffffffff801008de:	0f 85 8a fd ff ff    	jne    ffffffff8010066e <cprintf+0xcc>
ffffffff801008e4:	eb 01                	jmp    ffffffff801008e7 <cprintf+0x345>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
ffffffff801008e6:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
ffffffff801008e7:	83 bd 3c ff ff ff 00 	cmpl   $0x0,-0xc4(%rbp)
ffffffff801008ee:	74 0c                	je     ffffffff801008fc <cprintf+0x35a>
    release(&cons.lock);
ffffffff801008f0:	48 c7 c7 40 e4 18 80 	mov    $0xffffffff8018e440,%rdi
ffffffff801008f7:	e8 79 60 00 00       	callq  ffffffff80106975 <release>
}
ffffffff801008fc:	90                   	nop
ffffffff801008fd:	c9                   	leaveq 
ffffffff801008fe:	c3                   	retq   

ffffffff801008ff <panic>:

void
panic(char *s)
{
ffffffff801008ff:	55                   	push   %rbp
ffffffff80100900:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100903:	48 83 ec 70          	sub    $0x70,%rsp
ffffffff80100907:	48 89 7d 98          	mov    %rdi,-0x68(%rbp)
  int i;
  uintp pcs[10];
  
  cli();
ffffffff8010090b:	e8 91 fb ff ff       	callq  ffffffff801004a1 <cli>
  cons.locking = 0;
ffffffff80100910:	c7 05 8e db 08 00 00 	movl   $0x0,0x8db8e(%rip)        # ffffffff8018e4a8 <cons+0x68>
ffffffff80100917:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
ffffffff8010091a:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80100921:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80100925:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100928:	0f b6 c0             	movzbl %al,%eax
ffffffff8010092b:	89 c6                	mov    %eax,%esi
ffffffff8010092d:	48 c7 c7 3e a5 10 80 	mov    $0xffffffff8010a53e,%rdi
ffffffff80100934:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100939:	e8 64 fc ff ff       	callq  ffffffff801005a2 <cprintf>
  cprintf(s);
ffffffff8010093e:	48 8b 45 98          	mov    -0x68(%rbp),%rax
ffffffff80100942:	48 89 c7             	mov    %rax,%rdi
ffffffff80100945:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010094a:	e8 53 fc ff ff       	callq  ffffffff801005a2 <cprintf>
  cprintf("\n");
ffffffff8010094f:	48 c7 c7 4d a5 10 80 	mov    $0xffffffff8010a54d,%rdi
ffffffff80100956:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010095b:	e8 42 fc ff ff       	callq  ffffffff801005a2 <cprintf>
  getcallerpcs(&s, pcs);
ffffffff80100960:	48 8d 55 a0          	lea    -0x60(%rbp),%rdx
ffffffff80100964:	48 8d 45 98          	lea    -0x68(%rbp),%rax
ffffffff80100968:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010096b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010096e:	e8 5b 60 00 00       	callq  ffffffff801069ce <getcallerpcs>
  for(i=0; i<10; i++)
ffffffff80100973:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff8010097a:	eb 22                	jmp    ffffffff8010099e <panic+0x9f>
    cprintf(" %p", pcs[i]);
ffffffff8010097c:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010097f:	48 98                	cltq   
ffffffff80100981:	48 8b 44 c5 a0       	mov    -0x60(%rbp,%rax,8),%rax
ffffffff80100986:	48 89 c6             	mov    %rax,%rsi
ffffffff80100989:	48 c7 c7 4f a5 10 80 	mov    $0xffffffff8010a54f,%rdi
ffffffff80100990:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100995:	e8 08 fc ff ff       	callq  ffffffff801005a2 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
ffffffff8010099a:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff8010099e:	83 7d fc 09          	cmpl   $0x9,-0x4(%rbp)
ffffffff801009a2:	7e d8                	jle    ffffffff8010097c <panic+0x7d>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
ffffffff801009a4:	c7 05 8a da 08 00 01 	movl   $0x1,0x8da8a(%rip)        # ffffffff8018e438 <panicked>
ffffffff801009ab:	00 00 00 
  for(;;)
    ;
ffffffff801009ae:	eb fe                	jmp    ffffffff801009ae <panic+0xaf>

ffffffff801009b0 <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
ffffffff801009b0:	55                   	push   %rbp
ffffffff801009b1:	48 89 e5             	mov    %rsp,%rbp
ffffffff801009b4:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801009b8:	89 7d ec             	mov    %edi,-0x14(%rbp)
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
ffffffff801009bb:	be 0e 00 00 00       	mov    $0xe,%esi
ffffffff801009c0:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffffffff801009c5:	e8 69 fa ff ff       	callq  ffffffff80100433 <outb>
  pos = inb(CRTPORT+1) << 8;
ffffffff801009ca:	bf d5 03 00 00       	mov    $0x3d5,%edi
ffffffff801009cf:	e8 41 fa ff ff       	callq  ffffffff80100415 <inb>
ffffffff801009d4:	0f b6 c0             	movzbl %al,%eax
ffffffff801009d7:	c1 e0 08             	shl    $0x8,%eax
ffffffff801009da:	89 45 fc             	mov    %eax,-0x4(%rbp)
  outb(CRTPORT, 15);
ffffffff801009dd:	be 0f 00 00 00       	mov    $0xf,%esi
ffffffff801009e2:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffffffff801009e7:	e8 47 fa ff ff       	callq  ffffffff80100433 <outb>
  pos |= inb(CRTPORT+1);
ffffffff801009ec:	bf d5 03 00 00       	mov    $0x3d5,%edi
ffffffff801009f1:	e8 1f fa ff ff       	callq  ffffffff80100415 <inb>
ffffffff801009f6:	0f b6 c0             	movzbl %al,%eax
ffffffff801009f9:	09 45 fc             	or     %eax,-0x4(%rbp)

  if(c == '\n')
ffffffff801009fc:	83 7d ec 0a          	cmpl   $0xa,-0x14(%rbp)
ffffffff80100a00:	75 30                	jne    ffffffff80100a32 <cgaputc+0x82>
    pos += 80 - pos%80;
ffffffff80100a02:	8b 4d fc             	mov    -0x4(%rbp),%ecx
ffffffff80100a05:	ba 67 66 66 66       	mov    $0x66666667,%edx
ffffffff80100a0a:	89 c8                	mov    %ecx,%eax
ffffffff80100a0c:	f7 ea                	imul   %edx
ffffffff80100a0e:	c1 fa 05             	sar    $0x5,%edx
ffffffff80100a11:	89 c8                	mov    %ecx,%eax
ffffffff80100a13:	c1 f8 1f             	sar    $0x1f,%eax
ffffffff80100a16:	29 c2                	sub    %eax,%edx
ffffffff80100a18:	89 d0                	mov    %edx,%eax
ffffffff80100a1a:	c1 e0 02             	shl    $0x2,%eax
ffffffff80100a1d:	01 d0                	add    %edx,%eax
ffffffff80100a1f:	c1 e0 04             	shl    $0x4,%eax
ffffffff80100a22:	29 c1                	sub    %eax,%ecx
ffffffff80100a24:	89 ca                	mov    %ecx,%edx
ffffffff80100a26:	b8 50 00 00 00       	mov    $0x50,%eax
ffffffff80100a2b:	29 d0                	sub    %edx,%eax
ffffffff80100a2d:	01 45 fc             	add    %eax,-0x4(%rbp)
ffffffff80100a30:	eb 39                	jmp    ffffffff80100a6b <cgaputc+0xbb>
  else if(c == BACKSPACE){
ffffffff80100a32:	81 7d ec 00 01 00 00 	cmpl   $0x100,-0x14(%rbp)
ffffffff80100a39:	75 0c                	jne    ffffffff80100a47 <cgaputc+0x97>
    if(pos > 0) --pos;
ffffffff80100a3b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80100a3f:	7e 2a                	jle    ffffffff80100a6b <cgaputc+0xbb>
ffffffff80100a41:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
ffffffff80100a45:	eb 24                	jmp    ffffffff80100a6b <cgaputc+0xbb>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
ffffffff80100a47:	48 8b 0d ca b5 00 00 	mov    0xb5ca(%rip),%rcx        # ffffffff8010c018 <crt>
ffffffff80100a4e:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100a51:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80100a54:	89 55 fc             	mov    %edx,-0x4(%rbp)
ffffffff80100a57:	48 98                	cltq   
ffffffff80100a59:	48 01 c0             	add    %rax,%rax
ffffffff80100a5c:	48 01 c8             	add    %rcx,%rax
ffffffff80100a5f:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80100a62:	0f b6 d2             	movzbl %dl,%edx
ffffffff80100a65:	80 ce 07             	or     $0x7,%dh
ffffffff80100a68:	66 89 10             	mov    %dx,(%rax)
  
  if((pos/80) >= 24){  // Scroll up.
ffffffff80100a6b:	81 7d fc 7f 07 00 00 	cmpl   $0x77f,-0x4(%rbp)
ffffffff80100a72:	7e 56                	jle    ffffffff80100aca <cgaputc+0x11a>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
ffffffff80100a74:	48 8b 05 9d b5 00 00 	mov    0xb59d(%rip),%rax        # ffffffff8010c018 <crt>
ffffffff80100a7b:	48 8d 88 a0 00 00 00 	lea    0xa0(%rax),%rcx
ffffffff80100a82:	48 8b 05 8f b5 00 00 	mov    0xb58f(%rip),%rax        # ffffffff8010c018 <crt>
ffffffff80100a89:	ba 60 0e 00 00       	mov    $0xe60,%edx
ffffffff80100a8e:	48 89 ce             	mov    %rcx,%rsi
ffffffff80100a91:	48 89 c7             	mov    %rax,%rdi
ffffffff80100a94:	e8 63 62 00 00       	callq  ffffffff80106cfc <memmove>
    pos -= 80;
ffffffff80100a99:	83 6d fc 50          	subl   $0x50,-0x4(%rbp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
ffffffff80100a9d:	b8 80 07 00 00       	mov    $0x780,%eax
ffffffff80100aa2:	2b 45 fc             	sub    -0x4(%rbp),%eax
ffffffff80100aa5:	48 98                	cltq   
ffffffff80100aa7:	8d 14 00             	lea    (%rax,%rax,1),%edx
ffffffff80100aaa:	48 8b 05 67 b5 00 00 	mov    0xb567(%rip),%rax        # ffffffff8010c018 <crt>
ffffffff80100ab1:	8b 4d fc             	mov    -0x4(%rbp),%ecx
ffffffff80100ab4:	48 63 c9             	movslq %ecx,%rcx
ffffffff80100ab7:	48 01 c9             	add    %rcx,%rcx
ffffffff80100aba:	48 01 c8             	add    %rcx,%rax
ffffffff80100abd:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80100ac2:	48 89 c7             	mov    %rax,%rdi
ffffffff80100ac5:	e8 43 61 00 00       	callq  ffffffff80106c0d <memset>
  }
  
  outb(CRTPORT, 14);
ffffffff80100aca:	be 0e 00 00 00       	mov    $0xe,%esi
ffffffff80100acf:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffffffff80100ad4:	e8 5a f9 ff ff       	callq  ffffffff80100433 <outb>
  outb(CRTPORT+1, pos>>8);
ffffffff80100ad9:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100adc:	c1 f8 08             	sar    $0x8,%eax
ffffffff80100adf:	0f b6 c0             	movzbl %al,%eax
ffffffff80100ae2:	89 c6                	mov    %eax,%esi
ffffffff80100ae4:	bf d5 03 00 00       	mov    $0x3d5,%edi
ffffffff80100ae9:	e8 45 f9 ff ff       	callq  ffffffff80100433 <outb>
  outb(CRTPORT, 15);
ffffffff80100aee:	be 0f 00 00 00       	mov    $0xf,%esi
ffffffff80100af3:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffffffff80100af8:	e8 36 f9 ff ff       	callq  ffffffff80100433 <outb>
  outb(CRTPORT+1, pos);
ffffffff80100afd:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100b00:	0f b6 c0             	movzbl %al,%eax
ffffffff80100b03:	89 c6                	mov    %eax,%esi
ffffffff80100b05:	bf d5 03 00 00       	mov    $0x3d5,%edi
ffffffff80100b0a:	e8 24 f9 ff ff       	callq  ffffffff80100433 <outb>
  crt[pos] = ' ' | 0x0700;
ffffffff80100b0f:	48 8b 05 02 b5 00 00 	mov    0xb502(%rip),%rax        # ffffffff8010c018 <crt>
ffffffff80100b16:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80100b19:	48 63 d2             	movslq %edx,%rdx
ffffffff80100b1c:	48 01 d2             	add    %rdx,%rdx
ffffffff80100b1f:	48 01 d0             	add    %rdx,%rax
ffffffff80100b22:	66 c7 00 20 07       	movw   $0x720,(%rax)
}
ffffffff80100b27:	90                   	nop
ffffffff80100b28:	c9                   	leaveq 
ffffffff80100b29:	c3                   	retq   

ffffffff80100b2a <consputc>:

void
consputc(int c)
{
ffffffff80100b2a:	55                   	push   %rbp
ffffffff80100b2b:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100b2e:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80100b32:	89 7d fc             	mov    %edi,-0x4(%rbp)
  if(panicked){
ffffffff80100b35:	8b 05 fd d8 08 00    	mov    0x8d8fd(%rip),%eax        # ffffffff8018e438 <panicked>
ffffffff80100b3b:	85 c0                	test   %eax,%eax
ffffffff80100b3d:	74 07                	je     ffffffff80100b46 <consputc+0x1c>
    cli();
ffffffff80100b3f:	e8 5d f9 ff ff       	callq  ffffffff801004a1 <cli>
    for(;;)
      ;
ffffffff80100b44:	eb fe                	jmp    ffffffff80100b44 <consputc+0x1a>
  }

  if(c == BACKSPACE){
ffffffff80100b46:	81 7d fc 00 01 00 00 	cmpl   $0x100,-0x4(%rbp)
ffffffff80100b4d:	75 20                	jne    ffffffff80100b6f <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
ffffffff80100b4f:	bf 08 00 00 00       	mov    $0x8,%edi
ffffffff80100b54:	e8 41 7d 00 00       	callq  ffffffff8010889a <uartputc>
ffffffff80100b59:	bf 20 00 00 00       	mov    $0x20,%edi
ffffffff80100b5e:	e8 37 7d 00 00       	callq  ffffffff8010889a <uartputc>
ffffffff80100b63:	bf 08 00 00 00       	mov    $0x8,%edi
ffffffff80100b68:	e8 2d 7d 00 00       	callq  ffffffff8010889a <uartputc>
ffffffff80100b6d:	eb 0a                	jmp    ffffffff80100b79 <consputc+0x4f>
  } else
    uartputc(c);
ffffffff80100b6f:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100b72:	89 c7                	mov    %eax,%edi
ffffffff80100b74:	e8 21 7d 00 00       	callq  ffffffff8010889a <uartputc>
  cgaputc(c);
ffffffff80100b79:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100b7c:	89 c7                	mov    %eax,%edi
ffffffff80100b7e:	e8 2d fe ff ff       	callq  ffffffff801009b0 <cgaputc>
}
ffffffff80100b83:	90                   	nop
ffffffff80100b84:	c9                   	leaveq 
ffffffff80100b85:	c3                   	retq   

ffffffff80100b86 <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
ffffffff80100b86:	55                   	push   %rbp
ffffffff80100b87:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100b8a:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80100b8e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  int c;

  acquire(&input.lock);
ffffffff80100b92:	48 c7 c7 40 e3 18 80 	mov    $0xffffffff8018e340,%rdi
ffffffff80100b99:	e8 00 5d 00 00       	callq  ffffffff8010689e <acquire>
  while((c = getc()) >= 0){
ffffffff80100b9e:	e9 5f 01 00 00       	jmpq   ffffffff80100d02 <consoleintr+0x17c>
    switch(c){
ffffffff80100ba3:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100ba6:	83 f8 15             	cmp    $0x15,%eax
ffffffff80100ba9:	74 5e                	je     ffffffff80100c09 <consoleintr+0x83>
ffffffff80100bab:	83 f8 15             	cmp    $0x15,%eax
ffffffff80100bae:	7f 13                	jg     ffffffff80100bc3 <consoleintr+0x3d>
ffffffff80100bb0:	83 f8 08             	cmp    $0x8,%eax
ffffffff80100bb3:	0f 84 82 00 00 00    	je     ffffffff80100c3b <consoleintr+0xb5>
ffffffff80100bb9:	83 f8 10             	cmp    $0x10,%eax
ffffffff80100bbc:	74 28                	je     ffffffff80100be6 <consoleintr+0x60>
ffffffff80100bbe:	e9 aa 00 00 00       	jmpq   ffffffff80100c6d <consoleintr+0xe7>
ffffffff80100bc3:	83 f8 1a             	cmp    $0x1a,%eax
ffffffff80100bc6:	74 0a                	je     ffffffff80100bd2 <consoleintr+0x4c>
ffffffff80100bc8:	83 f8 7f             	cmp    $0x7f,%eax
ffffffff80100bcb:	74 6e                	je     ffffffff80100c3b <consoleintr+0xb5>
ffffffff80100bcd:	e9 9b 00 00 00       	jmpq   ffffffff80100c6d <consoleintr+0xe7>
    case C('Z'): // reboot
      lidt(0,0);
ffffffff80100bd2:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80100bd7:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80100bdc:	e8 71 f8 ff ff       	callq  ffffffff80100452 <lidt>
      break;
ffffffff80100be1:	e9 1c 01 00 00       	jmpq   ffffffff80100d02 <consoleintr+0x17c>
    case C('P'):  // Process listing.
      procdump();
ffffffff80100be6:	e8 03 5b 00 00       	callq  ffffffff801066ee <procdump>
      break;
ffffffff80100beb:	e9 12 01 00 00       	jmpq   ffffffff80100d02 <consoleintr+0x17c>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
ffffffff80100bf0:	8b 05 3a d8 08 00    	mov    0x8d83a(%rip),%eax        # ffffffff8018e430 <input+0xf0>
ffffffff80100bf6:	83 e8 01             	sub    $0x1,%eax
ffffffff80100bf9:	89 05 31 d8 08 00    	mov    %eax,0x8d831(%rip)        # ffffffff8018e430 <input+0xf0>
        consputc(BACKSPACE);
ffffffff80100bff:	bf 00 01 00 00       	mov    $0x100,%edi
ffffffff80100c04:	e8 21 ff ff ff       	callq  ffffffff80100b2a <consputc>
      break;
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
ffffffff80100c09:	8b 15 21 d8 08 00    	mov    0x8d821(%rip),%edx        # ffffffff8018e430 <input+0xf0>
ffffffff80100c0f:	8b 05 17 d8 08 00    	mov    0x8d817(%rip),%eax        # ffffffff8018e42c <input+0xec>
ffffffff80100c15:	39 c2                	cmp    %eax,%edx
ffffffff80100c17:	0f 84 e5 00 00 00    	je     ffffffff80100d02 <consoleintr+0x17c>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
ffffffff80100c1d:	8b 05 0d d8 08 00    	mov    0x8d80d(%rip),%eax        # ffffffff8018e430 <input+0xf0>
ffffffff80100c23:	83 e8 01             	sub    $0x1,%eax
ffffffff80100c26:	83 e0 7f             	and    $0x7f,%eax
ffffffff80100c29:	89 c0                	mov    %eax,%eax
ffffffff80100c2b:	0f b6 80 a8 e3 18 80 	movzbl -0x7fe71c58(%rax),%eax
      break;
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
ffffffff80100c32:	3c 0a                	cmp    $0xa,%al
ffffffff80100c34:	75 ba                	jne    ffffffff80100bf0 <consoleintr+0x6a>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
ffffffff80100c36:	e9 c7 00 00 00       	jmpq   ffffffff80100d02 <consoleintr+0x17c>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
ffffffff80100c3b:	8b 15 ef d7 08 00    	mov    0x8d7ef(%rip),%edx        # ffffffff8018e430 <input+0xf0>
ffffffff80100c41:	8b 05 e5 d7 08 00    	mov    0x8d7e5(%rip),%eax        # ffffffff8018e42c <input+0xec>
ffffffff80100c47:	39 c2                	cmp    %eax,%edx
ffffffff80100c49:	0f 84 b3 00 00 00    	je     ffffffff80100d02 <consoleintr+0x17c>
        input.e--;
ffffffff80100c4f:	8b 05 db d7 08 00    	mov    0x8d7db(%rip),%eax        # ffffffff8018e430 <input+0xf0>
ffffffff80100c55:	83 e8 01             	sub    $0x1,%eax
ffffffff80100c58:	89 05 d2 d7 08 00    	mov    %eax,0x8d7d2(%rip)        # ffffffff8018e430 <input+0xf0>
        consputc(BACKSPACE);
ffffffff80100c5e:	bf 00 01 00 00       	mov    $0x100,%edi
ffffffff80100c63:	e8 c2 fe ff ff       	callq  ffffffff80100b2a <consputc>
      }
      break;
ffffffff80100c68:	e9 95 00 00 00       	jmpq   ffffffff80100d02 <consoleintr+0x17c>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
ffffffff80100c6d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80100c71:	0f 84 8a 00 00 00    	je     ffffffff80100d01 <consoleintr+0x17b>
ffffffff80100c77:	8b 15 b3 d7 08 00    	mov    0x8d7b3(%rip),%edx        # ffffffff8018e430 <input+0xf0>
ffffffff80100c7d:	8b 05 a5 d7 08 00    	mov    0x8d7a5(%rip),%eax        # ffffffff8018e428 <input+0xe8>
ffffffff80100c83:	29 c2                	sub    %eax,%edx
ffffffff80100c85:	89 d0                	mov    %edx,%eax
ffffffff80100c87:	83 f8 7f             	cmp    $0x7f,%eax
ffffffff80100c8a:	77 75                	ja     ffffffff80100d01 <consoleintr+0x17b>
        c = (c == '\r') ? '\n' : c;
ffffffff80100c8c:	83 7d fc 0d          	cmpl   $0xd,-0x4(%rbp)
ffffffff80100c90:	74 05                	je     ffffffff80100c97 <consoleintr+0x111>
ffffffff80100c92:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100c95:	eb 05                	jmp    ffffffff80100c9c <consoleintr+0x116>
ffffffff80100c97:	b8 0a 00 00 00       	mov    $0xa,%eax
ffffffff80100c9c:	89 45 fc             	mov    %eax,-0x4(%rbp)
        input.buf[input.e++ % INPUT_BUF] = c;
ffffffff80100c9f:	8b 05 8b d7 08 00    	mov    0x8d78b(%rip),%eax        # ffffffff8018e430 <input+0xf0>
ffffffff80100ca5:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80100ca8:	89 15 82 d7 08 00    	mov    %edx,0x8d782(%rip)        # ffffffff8018e430 <input+0xf0>
ffffffff80100cae:	83 e0 7f             	and    $0x7f,%eax
ffffffff80100cb1:	89 c1                	mov    %eax,%ecx
ffffffff80100cb3:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100cb6:	89 c2                	mov    %eax,%edx
ffffffff80100cb8:	89 c8                	mov    %ecx,%eax
ffffffff80100cba:	88 90 a8 e3 18 80    	mov    %dl,-0x7fe71c58(%rax)
        consputc(c);
ffffffff80100cc0:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100cc3:	89 c7                	mov    %eax,%edi
ffffffff80100cc5:	e8 60 fe ff ff       	callq  ffffffff80100b2a <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
ffffffff80100cca:	83 7d fc 0a          	cmpl   $0xa,-0x4(%rbp)
ffffffff80100cce:	74 19                	je     ffffffff80100ce9 <consoleintr+0x163>
ffffffff80100cd0:	83 7d fc 04          	cmpl   $0x4,-0x4(%rbp)
ffffffff80100cd4:	74 13                	je     ffffffff80100ce9 <consoleintr+0x163>
ffffffff80100cd6:	8b 05 54 d7 08 00    	mov    0x8d754(%rip),%eax        # ffffffff8018e430 <input+0xf0>
ffffffff80100cdc:	8b 15 46 d7 08 00    	mov    0x8d746(%rip),%edx        # ffffffff8018e428 <input+0xe8>
ffffffff80100ce2:	83 ea 80             	sub    $0xffffff80,%edx
ffffffff80100ce5:	39 d0                	cmp    %edx,%eax
ffffffff80100ce7:	75 18                	jne    ffffffff80100d01 <consoleintr+0x17b>
          input.w = input.e;
ffffffff80100ce9:	8b 05 41 d7 08 00    	mov    0x8d741(%rip),%eax        # ffffffff8018e430 <input+0xf0>
ffffffff80100cef:	89 05 37 d7 08 00    	mov    %eax,0x8d737(%rip)        # ffffffff8018e42c <input+0xec>
          wakeup(&input.r);
ffffffff80100cf5:	48 c7 c7 28 e4 18 80 	mov    $0xffffffff8018e428,%rdi
ffffffff80100cfc:	e8 33 59 00 00       	callq  ffffffff80106634 <wakeup>
        }
      }
      break;
ffffffff80100d01:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
ffffffff80100d02:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100d06:	ff d0                	callq  *%rax
ffffffff80100d08:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff80100d0b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80100d0f:	0f 89 8e fe ff ff    	jns    ffffffff80100ba3 <consoleintr+0x1d>
        }
      }
      break;
    }
  }
  release(&input.lock);
ffffffff80100d15:	48 c7 c7 40 e3 18 80 	mov    $0xffffffff8018e340,%rdi
ffffffff80100d1c:	e8 54 5c 00 00       	callq  ffffffff80106975 <release>
}
ffffffff80100d21:	90                   	nop
ffffffff80100d22:	c9                   	leaveq 
ffffffff80100d23:	c3                   	retq   

ffffffff80100d24 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
ffffffff80100d24:	55                   	push   %rbp
ffffffff80100d25:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100d28:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80100d2c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80100d30:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80100d34:	89 55 dc             	mov    %edx,-0x24(%rbp)
  uint target;
  int c;

  iunlock(ip);
ffffffff80100d37:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100d3b:	48 89 c7             	mov    %rax,%rdi
ffffffff80100d3e:	e8 a0 1c 00 00       	callq  ffffffff801029e3 <iunlock>
  target = n;
ffffffff80100d43:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100d46:	89 45 fc             	mov    %eax,-0x4(%rbp)
  acquire(&input.lock);
ffffffff80100d49:	48 c7 c7 40 e3 18 80 	mov    $0xffffffff8018e340,%rdi
ffffffff80100d50:	e8 49 5b 00 00       	callq  ffffffff8010689e <acquire>
  while(n > 0){
ffffffff80100d55:	e9 b2 00 00 00       	jmpq   ffffffff80100e0c <consoleread+0xe8>
    while(input.r == input.w){
      if(proc->killed){
ffffffff80100d5a:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80100d61:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80100d65:	8b 40 40             	mov    0x40(%rax),%eax
ffffffff80100d68:	85 c0                	test   %eax,%eax
ffffffff80100d6a:	74 22                	je     ffffffff80100d8e <consoleread+0x6a>
        release(&input.lock);
ffffffff80100d6c:	48 c7 c7 40 e3 18 80 	mov    $0xffffffff8018e340,%rdi
ffffffff80100d73:	e8 fd 5b 00 00       	callq  ffffffff80106975 <release>
        ilock(ip);
ffffffff80100d78:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100d7c:	48 89 c7             	mov    %rax,%rdi
ffffffff80100d7f:	e8 c0 1a 00 00       	callq  ffffffff80102844 <ilock>
        return -1;
ffffffff80100d84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80100d89:	e9 ac 00 00 00       	jmpq   ffffffff80100e3a <consoleread+0x116>
      }
      sleep(&input.r, &input.lock);
ffffffff80100d8e:	48 c7 c6 40 e3 18 80 	mov    $0xffffffff8018e340,%rsi
ffffffff80100d95:	48 c7 c7 28 e4 18 80 	mov    $0xffffffff8018e428,%rdi
ffffffff80100d9c:	e8 80 57 00 00       	callq  ffffffff80106521 <sleep>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
ffffffff80100da1:	8b 15 81 d6 08 00    	mov    0x8d681(%rip),%edx        # ffffffff8018e428 <input+0xe8>
ffffffff80100da7:	8b 05 7f d6 08 00    	mov    0x8d67f(%rip),%eax        # ffffffff8018e42c <input+0xec>
ffffffff80100dad:	39 c2                	cmp    %eax,%edx
ffffffff80100daf:	74 a9                	je     ffffffff80100d5a <consoleread+0x36>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
ffffffff80100db1:	8b 05 71 d6 08 00    	mov    0x8d671(%rip),%eax        # ffffffff8018e428 <input+0xe8>
ffffffff80100db7:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80100dba:	89 15 68 d6 08 00    	mov    %edx,0x8d668(%rip)        # ffffffff8018e428 <input+0xe8>
ffffffff80100dc0:	83 e0 7f             	and    $0x7f,%eax
ffffffff80100dc3:	89 c0                	mov    %eax,%eax
ffffffff80100dc5:	0f b6 80 a8 e3 18 80 	movzbl -0x7fe71c58(%rax),%eax
ffffffff80100dcc:	0f be c0             	movsbl %al,%eax
ffffffff80100dcf:	89 45 f8             	mov    %eax,-0x8(%rbp)
    if(c == C('D')){  // EOF
ffffffff80100dd2:	83 7d f8 04          	cmpl   $0x4,-0x8(%rbp)
ffffffff80100dd6:	75 19                	jne    ffffffff80100df1 <consoleread+0xcd>
      if(n < target){
ffffffff80100dd8:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100ddb:	3b 45 fc             	cmp    -0x4(%rbp),%eax
ffffffff80100dde:	73 34                	jae    ffffffff80100e14 <consoleread+0xf0>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
ffffffff80100de0:	8b 05 42 d6 08 00    	mov    0x8d642(%rip),%eax        # ffffffff8018e428 <input+0xe8>
ffffffff80100de6:	83 e8 01             	sub    $0x1,%eax
ffffffff80100de9:	89 05 39 d6 08 00    	mov    %eax,0x8d639(%rip)        # ffffffff8018e428 <input+0xe8>
      }
      break;
ffffffff80100def:	eb 23                	jmp    ffffffff80100e14 <consoleread+0xf0>
    }
    *dst++ = c;
ffffffff80100df1:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80100df5:	48 8d 50 01          	lea    0x1(%rax),%rdx
ffffffff80100df9:	48 89 55 e0          	mov    %rdx,-0x20(%rbp)
ffffffff80100dfd:	8b 55 f8             	mov    -0x8(%rbp),%edx
ffffffff80100e00:	88 10                	mov    %dl,(%rax)
    --n;
ffffffff80100e02:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
    if(c == '\n')
ffffffff80100e06:	83 7d f8 0a          	cmpl   $0xa,-0x8(%rbp)
ffffffff80100e0a:	74 0b                	je     ffffffff80100e17 <consoleread+0xf3>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
ffffffff80100e0c:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
ffffffff80100e10:	7f 8f                	jg     ffffffff80100da1 <consoleread+0x7d>
ffffffff80100e12:	eb 04                	jmp    ffffffff80100e18 <consoleread+0xf4>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
ffffffff80100e14:	90                   	nop
ffffffff80100e15:	eb 01                	jmp    ffffffff80100e18 <consoleread+0xf4>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
ffffffff80100e17:	90                   	nop
  }
  release(&input.lock);
ffffffff80100e18:	48 c7 c7 40 e3 18 80 	mov    $0xffffffff8018e340,%rdi
ffffffff80100e1f:	e8 51 5b 00 00       	callq  ffffffff80106975 <release>
  ilock(ip);
ffffffff80100e24:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100e28:	48 89 c7             	mov    %rax,%rdi
ffffffff80100e2b:	e8 14 1a 00 00       	callq  ffffffff80102844 <ilock>

  return target - n;
ffffffff80100e30:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80100e33:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80100e36:	29 c2                	sub    %eax,%edx
ffffffff80100e38:	89 d0                	mov    %edx,%eax
}
ffffffff80100e3a:	c9                   	leaveq 
ffffffff80100e3b:	c3                   	retq   

ffffffff80100e3c <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
ffffffff80100e3c:	55                   	push   %rbp
ffffffff80100e3d:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100e40:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80100e44:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80100e48:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80100e4c:	89 55 dc             	mov    %edx,-0x24(%rbp)
  int i;

  iunlock(ip);
ffffffff80100e4f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100e53:	48 89 c7             	mov    %rax,%rdi
ffffffff80100e56:	e8 88 1b 00 00       	callq  ffffffff801029e3 <iunlock>
  acquire(&cons.lock);
ffffffff80100e5b:	48 c7 c7 40 e4 18 80 	mov    $0xffffffff8018e440,%rdi
ffffffff80100e62:	e8 37 5a 00 00       	callq  ffffffff8010689e <acquire>
  for(i = 0; i < n; i++)
ffffffff80100e67:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80100e6e:	eb 21                	jmp    ffffffff80100e91 <consolewrite+0x55>
    consputc(buf[i] & 0xff);
ffffffff80100e70:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100e73:	48 63 d0             	movslq %eax,%rdx
ffffffff80100e76:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80100e7a:	48 01 d0             	add    %rdx,%rax
ffffffff80100e7d:	0f b6 00             	movzbl (%rax),%eax
ffffffff80100e80:	0f be c0             	movsbl %al,%eax
ffffffff80100e83:	0f b6 c0             	movzbl %al,%eax
ffffffff80100e86:	89 c7                	mov    %eax,%edi
ffffffff80100e88:	e8 9d fc ff ff       	callq  ffffffff80100b2a <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
ffffffff80100e8d:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80100e91:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80100e94:	3b 45 dc             	cmp    -0x24(%rbp),%eax
ffffffff80100e97:	7c d7                	jl     ffffffff80100e70 <consolewrite+0x34>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
ffffffff80100e99:	48 c7 c7 40 e4 18 80 	mov    $0xffffffff8018e440,%rdi
ffffffff80100ea0:	e8 d0 5a 00 00       	callq  ffffffff80106975 <release>
  ilock(ip);
ffffffff80100ea5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80100ea9:	48 89 c7             	mov    %rax,%rdi
ffffffff80100eac:	e8 93 19 00 00       	callq  ffffffff80102844 <ilock>

  return n;
ffffffff80100eb1:	8b 45 dc             	mov    -0x24(%rbp),%eax
}
ffffffff80100eb4:	c9                   	leaveq 
ffffffff80100eb5:	c3                   	retq   

ffffffff80100eb6 <consoleinit>:

void
consoleinit(void)
{
ffffffff80100eb6:	55                   	push   %rbp
ffffffff80100eb7:	48 89 e5             	mov    %rsp,%rbp
  initlock(&cons.lock, "console");
ffffffff80100eba:	48 c7 c6 53 a5 10 80 	mov    $0xffffffff8010a553,%rsi
ffffffff80100ec1:	48 c7 c7 40 e4 18 80 	mov    $0xffffffff8018e440,%rdi
ffffffff80100ec8:	e8 9c 59 00 00       	callq  ffffffff80106869 <initlock>
  initlock(&input.lock, "input");
ffffffff80100ecd:	48 c7 c6 5b a5 10 80 	mov    $0xffffffff8010a55b,%rsi
ffffffff80100ed4:	48 c7 c7 40 e3 18 80 	mov    $0xffffffff8018e340,%rdi
ffffffff80100edb:	e8 89 59 00 00       	callq  ffffffff80106869 <initlock>

  devsw[CONSOLE].write = consolewrite;
ffffffff80100ee0:	48 c7 05 0d d6 08 00 	movq   $0xffffffff80100e3c,0x8d60d(%rip)        # ffffffff8018e4f8 <devsw+0x18>
ffffffff80100ee7:	3c 0e 10 80 
  devsw[CONSOLE].read = consoleread;
ffffffff80100eeb:	48 c7 05 fa d5 08 00 	movq   $0xffffffff80100d24,0x8d5fa(%rip)        # ffffffff8018e4f0 <devsw+0x10>
ffffffff80100ef2:	24 0d 10 80 
  cons.locking = 1;
ffffffff80100ef6:	c7 05 a8 d5 08 00 01 	movl   $0x1,0x8d5a8(%rip)        # ffffffff8018e4a8 <cons+0x68>
ffffffff80100efd:	00 00 00 

  picenable(IRQ_KBD);
ffffffff80100f00:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff80100f05:	e8 91 46 00 00       	callq  ffffffff8010559b <picenable>
  ioapicenable(IRQ_KBD, 0);
ffffffff80100f0a:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80100f0f:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff80100f14:	e8 a9 27 00 00       	callq  ffffffff801036c2 <ioapicenable>
}
ffffffff80100f19:	90                   	nop
ffffffff80100f1a:	5d                   	pop    %rbp
ffffffff80100f1b:	c3                   	retq   

ffffffff80100f1c <cpu_printfeatures>:
// leaf = 7
uint sef_flags;

static void
cpu_printfeatures(void)
{
ffffffff80100f1c:	55                   	push   %rbp
ffffffff80100f1d:	48 89 e5             	mov    %rsp,%rbp
ffffffff80100f20:	48 83 ec 10          	sub    $0x10,%rsp
  uchar vendorStr[13];
  *(uint*)(&vendorStr[0]) = vendor[0];
ffffffff80100f24:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80100f28:	8b 15 8a d5 08 00    	mov    0x8d58a(%rip),%edx        # ffffffff8018e4b8 <vendor>
ffffffff80100f2e:	89 10                	mov    %edx,(%rax)
  *(uint*)(&vendorStr[4]) = vendor[1];
ffffffff80100f30:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80100f34:	48 8d 50 04          	lea    0x4(%rax),%rdx
ffffffff80100f38:	8b 05 7e d5 08 00    	mov    0x8d57e(%rip),%eax        # ffffffff8018e4bc <vendor+0x4>
ffffffff80100f3e:	89 02                	mov    %eax,(%rdx)
  *(uint*)(&vendorStr[8]) = vendor[2];
ffffffff80100f40:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80100f44:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff80100f48:	8b 05 72 d5 08 00    	mov    0x8d572(%rip),%eax        # ffffffff8018e4c0 <vendor+0x8>
ffffffff80100f4e:	89 02                	mov    %eax,(%rdx)
  vendorStr[12] = 0;
ffffffff80100f50:	c6 45 fc 00          	movb   $0x0,-0x4(%rbp)

  cprintf("CPU vendor: %s\n", vendorStr);
ffffffff80100f54:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80100f58:	48 89 c6             	mov    %rax,%rsi
ffffffff80100f5b:	48 c7 c7 68 a5 10 80 	mov    $0xffffffff8010a568,%rdi
ffffffff80100f62:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100f67:	e8 36 f6 ff ff       	callq  ffffffff801005a2 <cprintf>
  cprintf("Max leaf: 0x%x\n", maxleaf);
ffffffff80100f6c:	8b 05 3e d5 08 00    	mov    0x8d53e(%rip),%eax        # ffffffff8018e4b0 <maxleaf>
ffffffff80100f72:	89 c6                	mov    %eax,%esi
ffffffff80100f74:	48 c7 c7 78 a5 10 80 	mov    $0xffffffff8010a578,%rdi
ffffffff80100f7b:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100f80:	e8 1d f6 ff ff       	callq  ffffffff801005a2 <cprintf>
  if (maxleaf >= 1) {
ffffffff80100f85:	8b 05 25 d5 08 00    	mov    0x8d525(%rip),%eax        # ffffffff8018e4b0 <maxleaf>
ffffffff80100f8b:	85 c0                	test   %eax,%eax
ffffffff80100f8d:	0f 84 52 07 00 00    	je     ffffffff801016e5 <cpu_printfeatures+0x7c9>
    cprintf("Features: ");
ffffffff80100f93:	48 c7 c7 88 a5 10 80 	mov    $0xffffffff8010a588,%rdi
ffffffff80100f9a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100f9f:	e8 fe f5 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, FPU);
ffffffff80100fa4:	8b 05 26 d5 08 00    	mov    0x8d526(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff80100faa:	83 e0 01             	and    $0x1,%eax
ffffffff80100fad:	85 c0                	test   %eax,%eax
ffffffff80100faf:	74 11                	je     ffffffff80100fc2 <cpu_printfeatures+0xa6>
ffffffff80100fb1:	48 c7 c7 93 a5 10 80 	mov    $0xffffffff8010a593,%rdi
ffffffff80100fb8:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100fbd:	e8 e0 f5 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, VME);
ffffffff80100fc2:	8b 05 08 d5 08 00    	mov    0x8d508(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff80100fc8:	83 e0 02             	and    $0x2,%eax
ffffffff80100fcb:	85 c0                	test   %eax,%eax
ffffffff80100fcd:	74 11                	je     ffffffff80100fe0 <cpu_printfeatures+0xc4>
ffffffff80100fcf:	48 c7 c7 98 a5 10 80 	mov    $0xffffffff8010a598,%rdi
ffffffff80100fd6:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100fdb:	e8 c2 f5 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, DE);
ffffffff80100fe0:	8b 05 ea d4 08 00    	mov    0x8d4ea(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff80100fe6:	83 e0 04             	and    $0x4,%eax
ffffffff80100fe9:	85 c0                	test   %eax,%eax
ffffffff80100feb:	74 11                	je     ffffffff80100ffe <cpu_printfeatures+0xe2>
ffffffff80100fed:	48 c7 c7 9d a5 10 80 	mov    $0xffffffff8010a59d,%rdi
ffffffff80100ff4:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80100ff9:	e8 a4 f5 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, PSE);
ffffffff80100ffe:	8b 05 cc d4 08 00    	mov    0x8d4cc(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff80101004:	83 e0 08             	and    $0x8,%eax
ffffffff80101007:	85 c0                	test   %eax,%eax
ffffffff80101009:	74 11                	je     ffffffff8010101c <cpu_printfeatures+0x100>
ffffffff8010100b:	48 c7 c7 a1 a5 10 80 	mov    $0xffffffff8010a5a1,%rdi
ffffffff80101012:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101017:	e8 86 f5 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, TSC);
ffffffff8010101c:	8b 05 ae d4 08 00    	mov    0x8d4ae(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff80101022:	83 e0 10             	and    $0x10,%eax
ffffffff80101025:	85 c0                	test   %eax,%eax
ffffffff80101027:	74 11                	je     ffffffff8010103a <cpu_printfeatures+0x11e>
ffffffff80101029:	48 c7 c7 a6 a5 10 80 	mov    $0xffffffff8010a5a6,%rdi
ffffffff80101030:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101035:	e8 68 f5 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, MSR);
ffffffff8010103a:	8b 05 90 d4 08 00    	mov    0x8d490(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff80101040:	83 e0 20             	and    $0x20,%eax
ffffffff80101043:	85 c0                	test   %eax,%eax
ffffffff80101045:	74 11                	je     ffffffff80101058 <cpu_printfeatures+0x13c>
ffffffff80101047:	48 c7 c7 ab a5 10 80 	mov    $0xffffffff8010a5ab,%rdi
ffffffff8010104e:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101053:	e8 4a f5 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, PAE);
ffffffff80101058:	8b 05 72 d4 08 00    	mov    0x8d472(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010105e:	83 e0 40             	and    $0x40,%eax
ffffffff80101061:	85 c0                	test   %eax,%eax
ffffffff80101063:	74 11                	je     ffffffff80101076 <cpu_printfeatures+0x15a>
ffffffff80101065:	48 c7 c7 b0 a5 10 80 	mov    $0xffffffff8010a5b0,%rdi
ffffffff8010106c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101071:	e8 2c f5 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, MCE);
ffffffff80101076:	8b 05 54 d4 08 00    	mov    0x8d454(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010107c:	25 80 00 00 00       	and    $0x80,%eax
ffffffff80101081:	85 c0                	test   %eax,%eax
ffffffff80101083:	74 11                	je     ffffffff80101096 <cpu_printfeatures+0x17a>
ffffffff80101085:	48 c7 c7 b5 a5 10 80 	mov    $0xffffffff8010a5b5,%rdi
ffffffff8010108c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101091:	e8 0c f5 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, CX8);
ffffffff80101096:	8b 05 34 d4 08 00    	mov    0x8d434(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010109c:	25 00 01 00 00       	and    $0x100,%eax
ffffffff801010a1:	85 c0                	test   %eax,%eax
ffffffff801010a3:	74 11                	je     ffffffff801010b6 <cpu_printfeatures+0x19a>
ffffffff801010a5:	48 c7 c7 ba a5 10 80 	mov    $0xffffffff8010a5ba,%rdi
ffffffff801010ac:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801010b1:	e8 ec f4 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, APIC);
ffffffff801010b6:	8b 05 14 d4 08 00    	mov    0x8d414(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff801010bc:	25 00 02 00 00       	and    $0x200,%eax
ffffffff801010c1:	85 c0                	test   %eax,%eax
ffffffff801010c3:	74 11                	je     ffffffff801010d6 <cpu_printfeatures+0x1ba>
ffffffff801010c5:	48 c7 c7 bf a5 10 80 	mov    $0xffffffff8010a5bf,%rdi
ffffffff801010cc:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801010d1:	e8 cc f4 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, SEP);
ffffffff801010d6:	8b 05 f4 d3 08 00    	mov    0x8d3f4(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff801010dc:	25 00 08 00 00       	and    $0x800,%eax
ffffffff801010e1:	85 c0                	test   %eax,%eax
ffffffff801010e3:	74 11                	je     ffffffff801010f6 <cpu_printfeatures+0x1da>
ffffffff801010e5:	48 c7 c7 c5 a5 10 80 	mov    $0xffffffff8010a5c5,%rdi
ffffffff801010ec:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801010f1:	e8 ac f4 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, MTRR);
ffffffff801010f6:	8b 05 d4 d3 08 00    	mov    0x8d3d4(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff801010fc:	25 00 10 00 00       	and    $0x1000,%eax
ffffffff80101101:	85 c0                	test   %eax,%eax
ffffffff80101103:	74 11                	je     ffffffff80101116 <cpu_printfeatures+0x1fa>
ffffffff80101105:	48 c7 c7 ca a5 10 80 	mov    $0xffffffff8010a5ca,%rdi
ffffffff8010110c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101111:	e8 8c f4 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, PGE);
ffffffff80101116:	8b 05 b4 d3 08 00    	mov    0x8d3b4(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010111c:	25 00 20 00 00       	and    $0x2000,%eax
ffffffff80101121:	85 c0                	test   %eax,%eax
ffffffff80101123:	74 11                	je     ffffffff80101136 <cpu_printfeatures+0x21a>
ffffffff80101125:	48 c7 c7 d0 a5 10 80 	mov    $0xffffffff8010a5d0,%rdi
ffffffff8010112c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101131:	e8 6c f4 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, MCA);
ffffffff80101136:	8b 05 94 d3 08 00    	mov    0x8d394(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010113c:	25 00 40 00 00       	and    $0x4000,%eax
ffffffff80101141:	85 c0                	test   %eax,%eax
ffffffff80101143:	74 11                	je     ffffffff80101156 <cpu_printfeatures+0x23a>
ffffffff80101145:	48 c7 c7 d5 a5 10 80 	mov    $0xffffffff8010a5d5,%rdi
ffffffff8010114c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101151:	e8 4c f4 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, CMOV);
ffffffff80101156:	8b 05 74 d3 08 00    	mov    0x8d374(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010115c:	25 00 80 00 00       	and    $0x8000,%eax
ffffffff80101161:	85 c0                	test   %eax,%eax
ffffffff80101163:	74 11                	je     ffffffff80101176 <cpu_printfeatures+0x25a>
ffffffff80101165:	48 c7 c7 da a5 10 80 	mov    $0xffffffff8010a5da,%rdi
ffffffff8010116c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101171:	e8 2c f4 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, PAT);
ffffffff80101176:	8b 05 54 d3 08 00    	mov    0x8d354(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010117c:	25 00 00 01 00       	and    $0x10000,%eax
ffffffff80101181:	85 c0                	test   %eax,%eax
ffffffff80101183:	74 11                	je     ffffffff80101196 <cpu_printfeatures+0x27a>
ffffffff80101185:	48 c7 c7 e0 a5 10 80 	mov    $0xffffffff8010a5e0,%rdi
ffffffff8010118c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101191:	e8 0c f4 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, PSE36);
ffffffff80101196:	8b 05 34 d3 08 00    	mov    0x8d334(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010119c:	25 00 00 02 00       	and    $0x20000,%eax
ffffffff801011a1:	85 c0                	test   %eax,%eax
ffffffff801011a3:	74 11                	je     ffffffff801011b6 <cpu_printfeatures+0x29a>
ffffffff801011a5:	48 c7 c7 e5 a5 10 80 	mov    $0xffffffff8010a5e5,%rdi
ffffffff801011ac:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801011b1:	e8 ec f3 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, PSN);
ffffffff801011b6:	8b 05 14 d3 08 00    	mov    0x8d314(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff801011bc:	25 00 00 04 00       	and    $0x40000,%eax
ffffffff801011c1:	85 c0                	test   %eax,%eax
ffffffff801011c3:	74 11                	je     ffffffff801011d6 <cpu_printfeatures+0x2ba>
ffffffff801011c5:	48 c7 c7 ec a5 10 80 	mov    $0xffffffff8010a5ec,%rdi
ffffffff801011cc:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801011d1:	e8 cc f3 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, CLFSH);
ffffffff801011d6:	8b 05 f4 d2 08 00    	mov    0x8d2f4(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff801011dc:	25 00 00 08 00       	and    $0x80000,%eax
ffffffff801011e1:	85 c0                	test   %eax,%eax
ffffffff801011e3:	74 11                	je     ffffffff801011f6 <cpu_printfeatures+0x2da>
ffffffff801011e5:	48 c7 c7 f1 a5 10 80 	mov    $0xffffffff8010a5f1,%rdi
ffffffff801011ec:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801011f1:	e8 ac f3 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, DS);
ffffffff801011f6:	8b 05 d4 d2 08 00    	mov    0x8d2d4(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff801011fc:	25 00 00 20 00       	and    $0x200000,%eax
ffffffff80101201:	85 c0                	test   %eax,%eax
ffffffff80101203:	74 11                	je     ffffffff80101216 <cpu_printfeatures+0x2fa>
ffffffff80101205:	48 c7 c7 f8 a5 10 80 	mov    $0xffffffff8010a5f8,%rdi
ffffffff8010120c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101211:	e8 8c f3 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, ACPI);
ffffffff80101216:	8b 05 b4 d2 08 00    	mov    0x8d2b4(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010121c:	25 00 00 40 00       	and    $0x400000,%eax
ffffffff80101221:	85 c0                	test   %eax,%eax
ffffffff80101223:	74 11                	je     ffffffff80101236 <cpu_printfeatures+0x31a>
ffffffff80101225:	48 c7 c7 fc a5 10 80 	mov    $0xffffffff8010a5fc,%rdi
ffffffff8010122c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101231:	e8 6c f3 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, MMX);
ffffffff80101236:	8b 05 94 d2 08 00    	mov    0x8d294(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010123c:	25 00 00 80 00       	and    $0x800000,%eax
ffffffff80101241:	85 c0                	test   %eax,%eax
ffffffff80101243:	74 11                	je     ffffffff80101256 <cpu_printfeatures+0x33a>
ffffffff80101245:	48 c7 c7 02 a6 10 80 	mov    $0xffffffff8010a602,%rdi
ffffffff8010124c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101251:	e8 4c f3 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, FXSR);
ffffffff80101256:	8b 05 74 d2 08 00    	mov    0x8d274(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010125c:	25 00 00 00 01       	and    $0x1000000,%eax
ffffffff80101261:	85 c0                	test   %eax,%eax
ffffffff80101263:	74 11                	je     ffffffff80101276 <cpu_printfeatures+0x35a>
ffffffff80101265:	48 c7 c7 07 a6 10 80 	mov    $0xffffffff8010a607,%rdi
ffffffff8010126c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101271:	e8 2c f3 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, SSE);
ffffffff80101276:	8b 05 54 d2 08 00    	mov    0x8d254(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010127c:	25 00 00 00 02       	and    $0x2000000,%eax
ffffffff80101281:	85 c0                	test   %eax,%eax
ffffffff80101283:	74 11                	je     ffffffff80101296 <cpu_printfeatures+0x37a>
ffffffff80101285:	48 c7 c7 0d a6 10 80 	mov    $0xffffffff8010a60d,%rdi
ffffffff8010128c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101291:	e8 0c f3 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, SSE2);
ffffffff80101296:	8b 05 34 d2 08 00    	mov    0x8d234(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010129c:	25 00 00 00 04       	and    $0x4000000,%eax
ffffffff801012a1:	85 c0                	test   %eax,%eax
ffffffff801012a3:	74 11                	je     ffffffff801012b6 <cpu_printfeatures+0x39a>
ffffffff801012a5:	48 c7 c7 12 a6 10 80 	mov    $0xffffffff8010a612,%rdi
ffffffff801012ac:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801012b1:	e8 ec f2 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, SS);
ffffffff801012b6:	8b 05 14 d2 08 00    	mov    0x8d214(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff801012bc:	25 00 00 00 08       	and    $0x8000000,%eax
ffffffff801012c1:	85 c0                	test   %eax,%eax
ffffffff801012c3:	74 11                	je     ffffffff801012d6 <cpu_printfeatures+0x3ba>
ffffffff801012c5:	48 c7 c7 18 a6 10 80 	mov    $0xffffffff8010a618,%rdi
ffffffff801012cc:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801012d1:	e8 cc f2 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, HTT);
ffffffff801012d6:	8b 05 f4 d1 08 00    	mov    0x8d1f4(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff801012dc:	25 00 00 00 10       	and    $0x10000000,%eax
ffffffff801012e1:	85 c0                	test   %eax,%eax
ffffffff801012e3:	74 11                	je     ffffffff801012f6 <cpu_printfeatures+0x3da>
ffffffff801012e5:	48 c7 c7 1c a6 10 80 	mov    $0xffffffff8010a61c,%rdi
ffffffff801012ec:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801012f1:	e8 ac f2 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, TM);
ffffffff801012f6:	8b 05 d4 d1 08 00    	mov    0x8d1d4(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff801012fc:	25 00 00 00 20       	and    $0x20000000,%eax
ffffffff80101301:	85 c0                	test   %eax,%eax
ffffffff80101303:	74 11                	je     ffffffff80101316 <cpu_printfeatures+0x3fa>
ffffffff80101305:	48 c7 c7 21 a6 10 80 	mov    $0xffffffff8010a621,%rdi
ffffffff8010130c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101311:	e8 8c f2 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(features, PBE);
ffffffff80101316:	8b 05 b4 d1 08 00    	mov    0x8d1b4(%rip),%eax        # ffffffff8018e4d0 <features>
ffffffff8010131c:	85 c0                	test   %eax,%eax
ffffffff8010131e:	79 11                	jns    ffffffff80101331 <cpu_printfeatures+0x415>
ffffffff80101320:	48 c7 c7 25 a6 10 80 	mov    $0xffffffff8010a625,%rdi
ffffffff80101327:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010132c:	e8 71 f2 ff ff       	callq  ffffffff801005a2 <cprintf>

    cprintf("\nExt Features: ");
ffffffff80101331:	48 c7 c7 2a a6 10 80 	mov    $0xffffffff8010a62a,%rdi
ffffffff80101338:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010133d:	e8 60 f2 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, SSE3);
ffffffff80101342:	8b 05 84 d1 08 00    	mov    0x8d184(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff80101348:	83 e0 01             	and    $0x1,%eax
ffffffff8010134b:	85 c0                	test   %eax,%eax
ffffffff8010134d:	74 11                	je     ffffffff80101360 <cpu_printfeatures+0x444>
ffffffff8010134f:	48 c7 c7 3a a6 10 80 	mov    $0xffffffff8010a63a,%rdi
ffffffff80101356:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010135b:	e8 42 f2 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, PCLMULQDQ);
ffffffff80101360:	8b 05 66 d1 08 00    	mov    0x8d166(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff80101366:	83 e0 02             	and    $0x2,%eax
ffffffff80101369:	85 c0                	test   %eax,%eax
ffffffff8010136b:	74 11                	je     ffffffff8010137e <cpu_printfeatures+0x462>
ffffffff8010136d:	48 c7 c7 40 a6 10 80 	mov    $0xffffffff8010a640,%rdi
ffffffff80101374:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101379:	e8 24 f2 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, DTES64);
ffffffff8010137e:	8b 05 48 d1 08 00    	mov    0x8d148(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff80101384:	83 e0 04             	and    $0x4,%eax
ffffffff80101387:	85 c0                	test   %eax,%eax
ffffffff80101389:	74 11                	je     ffffffff8010139c <cpu_printfeatures+0x480>
ffffffff8010138b:	48 c7 c7 4b a6 10 80 	mov    $0xffffffff8010a64b,%rdi
ffffffff80101392:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101397:	e8 06 f2 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, MONITOR);
ffffffff8010139c:	8b 05 2a d1 08 00    	mov    0x8d12a(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801013a2:	83 e0 08             	and    $0x8,%eax
ffffffff801013a5:	85 c0                	test   %eax,%eax
ffffffff801013a7:	74 11                	je     ffffffff801013ba <cpu_printfeatures+0x49e>
ffffffff801013a9:	48 c7 c7 53 a6 10 80 	mov    $0xffffffff8010a653,%rdi
ffffffff801013b0:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801013b5:	e8 e8 f1 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, DS_CPL);
ffffffff801013ba:	8b 05 0c d1 08 00    	mov    0x8d10c(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801013c0:	83 e0 10             	and    $0x10,%eax
ffffffff801013c3:	85 c0                	test   %eax,%eax
ffffffff801013c5:	74 11                	je     ffffffff801013d8 <cpu_printfeatures+0x4bc>
ffffffff801013c7:	48 c7 c7 5c a6 10 80 	mov    $0xffffffff8010a65c,%rdi
ffffffff801013ce:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801013d3:	e8 ca f1 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, VMX);
ffffffff801013d8:	8b 05 ee d0 08 00    	mov    0x8d0ee(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801013de:	83 e0 20             	and    $0x20,%eax
ffffffff801013e1:	85 c0                	test   %eax,%eax
ffffffff801013e3:	74 11                	je     ffffffff801013f6 <cpu_printfeatures+0x4da>
ffffffff801013e5:	48 c7 c7 64 a6 10 80 	mov    $0xffffffff8010a664,%rdi
ffffffff801013ec:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801013f1:	e8 ac f1 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, SMX);
ffffffff801013f6:	8b 05 d0 d0 08 00    	mov    0x8d0d0(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801013fc:	83 e0 40             	and    $0x40,%eax
ffffffff801013ff:	85 c0                	test   %eax,%eax
ffffffff80101401:	74 11                	je     ffffffff80101414 <cpu_printfeatures+0x4f8>
ffffffff80101403:	48 c7 c7 69 a6 10 80 	mov    $0xffffffff8010a669,%rdi
ffffffff8010140a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010140f:	e8 8e f1 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, EIST);
ffffffff80101414:	8b 05 b2 d0 08 00    	mov    0x8d0b2(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010141a:	25 80 00 00 00       	and    $0x80,%eax
ffffffff8010141f:	85 c0                	test   %eax,%eax
ffffffff80101421:	74 11                	je     ffffffff80101434 <cpu_printfeatures+0x518>
ffffffff80101423:	48 c7 c7 6e a6 10 80 	mov    $0xffffffff8010a66e,%rdi
ffffffff8010142a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010142f:	e8 6e f1 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, TM2);
ffffffff80101434:	8b 05 92 d0 08 00    	mov    0x8d092(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010143a:	25 00 01 00 00       	and    $0x100,%eax
ffffffff8010143f:	85 c0                	test   %eax,%eax
ffffffff80101441:	74 11                	je     ffffffff80101454 <cpu_printfeatures+0x538>
ffffffff80101443:	48 c7 c7 74 a6 10 80 	mov    $0xffffffff8010a674,%rdi
ffffffff8010144a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010144f:	e8 4e f1 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, SSSE3);
ffffffff80101454:	8b 05 72 d0 08 00    	mov    0x8d072(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010145a:	25 00 02 00 00       	and    $0x200,%eax
ffffffff8010145f:	85 c0                	test   %eax,%eax
ffffffff80101461:	74 11                	je     ffffffff80101474 <cpu_printfeatures+0x558>
ffffffff80101463:	48 c7 c7 79 a6 10 80 	mov    $0xffffffff8010a679,%rdi
ffffffff8010146a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010146f:	e8 2e f1 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, CNXT_ID);
ffffffff80101474:	8b 05 52 d0 08 00    	mov    0x8d052(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010147a:	25 00 04 00 00       	and    $0x400,%eax
ffffffff8010147f:	85 c0                	test   %eax,%eax
ffffffff80101481:	74 11                	je     ffffffff80101494 <cpu_printfeatures+0x578>
ffffffff80101483:	48 c7 c7 80 a6 10 80 	mov    $0xffffffff8010a680,%rdi
ffffffff8010148a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010148f:	e8 0e f1 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, FMA);
ffffffff80101494:	8b 05 32 d0 08 00    	mov    0x8d032(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010149a:	25 00 10 00 00       	and    $0x1000,%eax
ffffffff8010149f:	85 c0                	test   %eax,%eax
ffffffff801014a1:	74 11                	je     ffffffff801014b4 <cpu_printfeatures+0x598>
ffffffff801014a3:	48 c7 c7 89 a6 10 80 	mov    $0xffffffff8010a689,%rdi
ffffffff801014aa:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801014af:	e8 ee f0 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, CMPXCHG16B);
ffffffff801014b4:	8b 05 12 d0 08 00    	mov    0x8d012(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801014ba:	25 00 20 00 00       	and    $0x2000,%eax
ffffffff801014bf:	85 c0                	test   %eax,%eax
ffffffff801014c1:	74 11                	je     ffffffff801014d4 <cpu_printfeatures+0x5b8>
ffffffff801014c3:	48 c7 c7 8e a6 10 80 	mov    $0xffffffff8010a68e,%rdi
ffffffff801014ca:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801014cf:	e8 ce f0 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, xTPR);
ffffffff801014d4:	8b 05 f2 cf 08 00    	mov    0x8cff2(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801014da:	25 00 40 00 00       	and    $0x4000,%eax
ffffffff801014df:	85 c0                	test   %eax,%eax
ffffffff801014e1:	74 11                	je     ffffffff801014f4 <cpu_printfeatures+0x5d8>
ffffffff801014e3:	48 c7 c7 9a a6 10 80 	mov    $0xffffffff8010a69a,%rdi
ffffffff801014ea:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801014ef:	e8 ae f0 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, PDCM);
ffffffff801014f4:	8b 05 d2 cf 08 00    	mov    0x8cfd2(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801014fa:	25 00 80 00 00       	and    $0x8000,%eax
ffffffff801014ff:	85 c0                	test   %eax,%eax
ffffffff80101501:	74 11                	je     ffffffff80101514 <cpu_printfeatures+0x5f8>
ffffffff80101503:	48 c7 c7 a0 a6 10 80 	mov    $0xffffffff8010a6a0,%rdi
ffffffff8010150a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010150f:	e8 8e f0 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, PCID);
ffffffff80101514:	8b 05 b2 cf 08 00    	mov    0x8cfb2(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010151a:	25 00 00 02 00       	and    $0x20000,%eax
ffffffff8010151f:	85 c0                	test   %eax,%eax
ffffffff80101521:	74 11                	je     ffffffff80101534 <cpu_printfeatures+0x618>
ffffffff80101523:	48 c7 c7 a6 a6 10 80 	mov    $0xffffffff8010a6a6,%rdi
ffffffff8010152a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010152f:	e8 6e f0 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, DCA);
ffffffff80101534:	8b 05 92 cf 08 00    	mov    0x8cf92(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010153a:	25 00 00 04 00       	and    $0x40000,%eax
ffffffff8010153f:	85 c0                	test   %eax,%eax
ffffffff80101541:	74 11                	je     ffffffff80101554 <cpu_printfeatures+0x638>
ffffffff80101543:	48 c7 c7 ac a6 10 80 	mov    $0xffffffff8010a6ac,%rdi
ffffffff8010154a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010154f:	e8 4e f0 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, SSE4_1);
ffffffff80101554:	8b 05 72 cf 08 00    	mov    0x8cf72(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010155a:	25 00 00 08 00       	and    $0x80000,%eax
ffffffff8010155f:	85 c0                	test   %eax,%eax
ffffffff80101561:	74 11                	je     ffffffff80101574 <cpu_printfeatures+0x658>
ffffffff80101563:	48 c7 c7 b1 a6 10 80 	mov    $0xffffffff8010a6b1,%rdi
ffffffff8010156a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010156f:	e8 2e f0 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, SSE4_2);
ffffffff80101574:	8b 05 52 cf 08 00    	mov    0x8cf52(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010157a:	25 00 00 10 00       	and    $0x100000,%eax
ffffffff8010157f:	85 c0                	test   %eax,%eax
ffffffff80101581:	74 11                	je     ffffffff80101594 <cpu_printfeatures+0x678>
ffffffff80101583:	48 c7 c7 b9 a6 10 80 	mov    $0xffffffff8010a6b9,%rdi
ffffffff8010158a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010158f:	e8 0e f0 ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, x2APIC);
ffffffff80101594:	8b 05 32 cf 08 00    	mov    0x8cf32(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010159a:	25 00 00 20 00       	and    $0x200000,%eax
ffffffff8010159f:	85 c0                	test   %eax,%eax
ffffffff801015a1:	74 11                	je     ffffffff801015b4 <cpu_printfeatures+0x698>
ffffffff801015a3:	48 c7 c7 c1 a6 10 80 	mov    $0xffffffff8010a6c1,%rdi
ffffffff801015aa:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801015af:	e8 ee ef ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, MOVBE);
ffffffff801015b4:	8b 05 12 cf 08 00    	mov    0x8cf12(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801015ba:	25 00 00 40 00       	and    $0x400000,%eax
ffffffff801015bf:	85 c0                	test   %eax,%eax
ffffffff801015c1:	74 11                	je     ffffffff801015d4 <cpu_printfeatures+0x6b8>
ffffffff801015c3:	48 c7 c7 c9 a6 10 80 	mov    $0xffffffff8010a6c9,%rdi
ffffffff801015ca:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801015cf:	e8 ce ef ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, POPCNT);
ffffffff801015d4:	8b 05 f2 ce 08 00    	mov    0x8cef2(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801015da:	25 00 00 80 00       	and    $0x800000,%eax
ffffffff801015df:	85 c0                	test   %eax,%eax
ffffffff801015e1:	74 11                	je     ffffffff801015f4 <cpu_printfeatures+0x6d8>
ffffffff801015e3:	48 c7 c7 d0 a6 10 80 	mov    $0xffffffff8010a6d0,%rdi
ffffffff801015ea:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801015ef:	e8 ae ef ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, TSCD);
ffffffff801015f4:	8b 05 d2 ce 08 00    	mov    0x8ced2(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801015fa:	25 00 00 00 01       	and    $0x1000000,%eax
ffffffff801015ff:	85 c0                	test   %eax,%eax
ffffffff80101601:	74 11                	je     ffffffff80101614 <cpu_printfeatures+0x6f8>
ffffffff80101603:	48 c7 c7 d8 a6 10 80 	mov    $0xffffffff8010a6d8,%rdi
ffffffff8010160a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010160f:	e8 8e ef ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, AESNI);
ffffffff80101614:	8b 05 b2 ce 08 00    	mov    0x8ceb2(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010161a:	25 00 00 00 02       	and    $0x2000000,%eax
ffffffff8010161f:	85 c0                	test   %eax,%eax
ffffffff80101621:	74 11                	je     ffffffff80101634 <cpu_printfeatures+0x718>
ffffffff80101623:	48 c7 c7 de a6 10 80 	mov    $0xffffffff8010a6de,%rdi
ffffffff8010162a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010162f:	e8 6e ef ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, XSAVE);
ffffffff80101634:	8b 05 92 ce 08 00    	mov    0x8ce92(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010163a:	25 00 00 00 04       	and    $0x4000000,%eax
ffffffff8010163f:	85 c0                	test   %eax,%eax
ffffffff80101641:	74 11                	je     ffffffff80101654 <cpu_printfeatures+0x738>
ffffffff80101643:	48 c7 c7 e5 a6 10 80 	mov    $0xffffffff8010a6e5,%rdi
ffffffff8010164a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010164f:	e8 4e ef ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, OSXSAVE);
ffffffff80101654:	8b 05 72 ce 08 00    	mov    0x8ce72(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010165a:	25 00 00 00 08       	and    $0x8000000,%eax
ffffffff8010165f:	85 c0                	test   %eax,%eax
ffffffff80101661:	74 11                	je     ffffffff80101674 <cpu_printfeatures+0x758>
ffffffff80101663:	48 c7 c7 ec a6 10 80 	mov    $0xffffffff8010a6ec,%rdi
ffffffff8010166a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010166f:	e8 2e ef ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, AVX);
ffffffff80101674:	8b 05 52 ce 08 00    	mov    0x8ce52(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010167a:	25 00 00 00 10       	and    $0x10000000,%eax
ffffffff8010167f:	85 c0                	test   %eax,%eax
ffffffff80101681:	74 11                	je     ffffffff80101694 <cpu_printfeatures+0x778>
ffffffff80101683:	48 c7 c7 f5 a6 10 80 	mov    $0xffffffff8010a6f5,%rdi
ffffffff8010168a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010168f:	e8 0e ef ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, F16C);
ffffffff80101694:	8b 05 32 ce 08 00    	mov    0x8ce32(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff8010169a:	25 00 00 00 20       	and    $0x20000000,%eax
ffffffff8010169f:	85 c0                	test   %eax,%eax
ffffffff801016a1:	74 11                	je     ffffffff801016b4 <cpu_printfeatures+0x798>
ffffffff801016a3:	48 c7 c7 fa a6 10 80 	mov    $0xffffffff8010a6fa,%rdi
ffffffff801016aa:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801016af:	e8 ee ee ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_FEATURE(featuresExt, RDRAND);
ffffffff801016b4:	8b 05 12 ce 08 00    	mov    0x8ce12(%rip),%eax        # ffffffff8018e4cc <featuresExt>
ffffffff801016ba:	25 00 00 00 40       	and    $0x40000000,%eax
ffffffff801016bf:	85 c0                	test   %eax,%eax
ffffffff801016c1:	74 11                	je     ffffffff801016d4 <cpu_printfeatures+0x7b8>
ffffffff801016c3:	48 c7 c7 00 a7 10 80 	mov    $0xffffffff8010a700,%rdi
ffffffff801016ca:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801016cf:	e8 ce ee ff ff       	callq  ffffffff801005a2 <cprintf>
    cprintf("\n");
ffffffff801016d4:	48 c7 c7 08 a7 10 80 	mov    $0xffffffff8010a708,%rdi
ffffffff801016db:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801016e0:	e8 bd ee ff ff       	callq  ffffffff801005a2 <cprintf>
  }

  if (maxleaf >= 7) {
ffffffff801016e5:	8b 05 c5 cd 08 00    	mov    0x8cdc5(%rip),%eax        # ffffffff8018e4b0 <maxleaf>
ffffffff801016eb:	83 f8 06             	cmp    $0x6,%eax
ffffffff801016ee:	0f 86 fc 00 00 00    	jbe    ffffffff801017f0 <cpu_printfeatures+0x8d4>
    cprintf("Structured Extended Features: ");
ffffffff801016f4:	48 c7 c7 10 a7 10 80 	mov    $0xffffffff8010a710,%rdi
ffffffff801016fb:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101700:	e8 9d ee ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_SEFEATURE(sef_flags, FSGSBASE);
ffffffff80101705:	8b 05 c9 cd 08 00    	mov    0x8cdc9(%rip),%eax        # ffffffff8018e4d4 <sef_flags>
ffffffff8010170b:	83 e0 01             	and    $0x1,%eax
ffffffff8010170e:	85 c0                	test   %eax,%eax
ffffffff80101710:	74 11                	je     ffffffff80101723 <cpu_printfeatures+0x807>
ffffffff80101712:	48 c7 c7 2f a7 10 80 	mov    $0xffffffff8010a72f,%rdi
ffffffff80101719:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010171e:	e8 7f ee ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_SEFEATURE(sef_flags, TAM);
ffffffff80101723:	8b 05 ab cd 08 00    	mov    0x8cdab(%rip),%eax        # ffffffff8018e4d4 <sef_flags>
ffffffff80101729:	83 e0 02             	and    $0x2,%eax
ffffffff8010172c:	85 c0                	test   %eax,%eax
ffffffff8010172e:	74 11                	je     ffffffff80101741 <cpu_printfeatures+0x825>
ffffffff80101730:	48 c7 c7 39 a7 10 80 	mov    $0xffffffff8010a739,%rdi
ffffffff80101737:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010173c:	e8 61 ee ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_SEFEATURE(sef_flags, SMEP);
ffffffff80101741:	8b 05 8d cd 08 00    	mov    0x8cd8d(%rip),%eax        # ffffffff8018e4d4 <sef_flags>
ffffffff80101747:	25 80 00 00 00       	and    $0x80,%eax
ffffffff8010174c:	85 c0                	test   %eax,%eax
ffffffff8010174e:	74 11                	je     ffffffff80101761 <cpu_printfeatures+0x845>
ffffffff80101750:	48 c7 c7 3e a7 10 80 	mov    $0xffffffff8010a73e,%rdi
ffffffff80101757:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010175c:	e8 41 ee ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_SEFEATURE(sef_flags, EREP);
ffffffff80101761:	8b 05 6d cd 08 00    	mov    0x8cd6d(%rip),%eax        # ffffffff8018e4d4 <sef_flags>
ffffffff80101767:	25 00 02 00 00       	and    $0x200,%eax
ffffffff8010176c:	85 c0                	test   %eax,%eax
ffffffff8010176e:	74 11                	je     ffffffff80101781 <cpu_printfeatures+0x865>
ffffffff80101770:	48 c7 c7 44 a7 10 80 	mov    $0xffffffff8010a744,%rdi
ffffffff80101777:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010177c:	e8 21 ee ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_SEFEATURE(sef_flags, INVPCID);
ffffffff80101781:	8b 05 4d cd 08 00    	mov    0x8cd4d(%rip),%eax        # ffffffff8018e4d4 <sef_flags>
ffffffff80101787:	25 00 04 00 00       	and    $0x400,%eax
ffffffff8010178c:	85 c0                	test   %eax,%eax
ffffffff8010178e:	74 11                	je     ffffffff801017a1 <cpu_printfeatures+0x885>
ffffffff80101790:	48 c7 c7 4a a7 10 80 	mov    $0xffffffff8010a74a,%rdi
ffffffff80101797:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010179c:	e8 01 ee ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_SEFEATURE(sef_flags, QM);
ffffffff801017a1:	8b 05 2d cd 08 00    	mov    0x8cd2d(%rip),%eax        # ffffffff8018e4d4 <sef_flags>
ffffffff801017a7:	83 e0 01             	and    $0x1,%eax
ffffffff801017aa:	85 c0                	test   %eax,%eax
ffffffff801017ac:	74 11                	je     ffffffff801017bf <cpu_printfeatures+0x8a3>
ffffffff801017ae:	48 c7 c7 53 a7 10 80 	mov    $0xffffffff8010a753,%rdi
ffffffff801017b5:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801017ba:	e8 e3 ed ff ff       	callq  ffffffff801005a2 <cprintf>
    PRINT_SEFEATURE(sef_flags, FPUCS);
ffffffff801017bf:	8b 05 0f cd 08 00    	mov    0x8cd0f(%rip),%eax        # ffffffff8018e4d4 <sef_flags>
ffffffff801017c5:	25 00 20 00 00       	and    $0x2000,%eax
ffffffff801017ca:	85 c0                	test   %eax,%eax
ffffffff801017cc:	74 11                	je     ffffffff801017df <cpu_printfeatures+0x8c3>
ffffffff801017ce:	48 c7 c7 57 a7 10 80 	mov    $0xffffffff8010a757,%rdi
ffffffff801017d5:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801017da:	e8 c3 ed ff ff       	callq  ffffffff801005a2 <cprintf>
    cprintf("\n");
ffffffff801017df:	48 c7 c7 08 a7 10 80 	mov    $0xffffffff8010a708,%rdi
ffffffff801017e6:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801017eb:	e8 b2 ed ff ff       	callq  ffffffff801005a2 <cprintf>
  }
}
ffffffff801017f0:	90                   	nop
ffffffff801017f1:	c9                   	leaveq 
ffffffff801017f2:	c3                   	retq   

ffffffff801017f3 <cpuinfo>:

static void
cpuinfo(void)
{
ffffffff801017f3:	55                   	push   %rbp
ffffffff801017f4:	48 89 e5             	mov    %rsp,%rbp
ffffffff801017f7:	53                   	push   %rbx
ffffffff801017f8:	48 83 ec 10          	sub    $0x10,%rsp
  // check for CPUID support by setting and clearing ID (bit 21) in EFLAGS

  // When EAX=0, the processor returns the highest value (maxleaf) recognized for processor information
  asm("cpuid" : "=a"(maxleaf), "=b"(vendor[0]), "=c"(vendor[2]), "=d"(vendor[1]) : "a" (0) :);
ffffffff801017fc:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101801:	0f a2                	cpuid  
ffffffff80101803:	89 de                	mov    %ebx,%esi
ffffffff80101805:	89 05 a5 cc 08 00    	mov    %eax,0x8cca5(%rip)        # ffffffff8018e4b0 <maxleaf>
ffffffff8010180b:	89 35 a7 cc 08 00    	mov    %esi,0x8cca7(%rip)        # ffffffff8018e4b8 <vendor>
ffffffff80101811:	89 0d a9 cc 08 00    	mov    %ecx,0x8cca9(%rip)        # ffffffff8018e4c0 <vendor+0x8>
ffffffff80101817:	89 15 9f cc 08 00    	mov    %edx,0x8cc9f(%rip)        # ffffffff8018e4bc <vendor+0x4>


  if (maxleaf >= 1) {
ffffffff8010181d:	8b 05 8d cc 08 00    	mov    0x8cc8d(%rip),%eax        # ffffffff8018e4b0 <maxleaf>
ffffffff80101823:	85 c0                	test   %eax,%eax
ffffffff80101825:	74 21                	je     ffffffff80101848 <cpuinfo+0x55>
    // get model, family, stepping info
    asm("cpuid" : "=a"(version), "=b"(processor), "=c"(featuresExt), "=d"(features) : "a" (1) :);
ffffffff80101827:	b8 01 00 00 00       	mov    $0x1,%eax
ffffffff8010182c:	0f a2                	cpuid  
ffffffff8010182e:	89 de                	mov    %ebx,%esi
ffffffff80101830:	89 05 8e cc 08 00    	mov    %eax,0x8cc8e(%rip)        # ffffffff8018e4c4 <version>
ffffffff80101836:	89 35 8c cc 08 00    	mov    %esi,0x8cc8c(%rip)        # ffffffff8018e4c8 <processor>
ffffffff8010183c:	89 0d 8a cc 08 00    	mov    %ecx,0x8cc8a(%rip)        # ffffffff8018e4cc <featuresExt>
ffffffff80101842:	89 15 88 cc 08 00    	mov    %edx,0x8cc88(%rip)        # ffffffff8018e4d0 <features>

  if (maxleaf >= 6) {
    // thermal and power management
  }

  if (maxleaf >= 7) {
ffffffff80101848:	8b 05 62 cc 08 00    	mov    0x8cc62(%rip),%eax        # ffffffff8018e4b0 <maxleaf>
ffffffff8010184e:	83 f8 06             	cmp    $0x6,%eax
ffffffff80101851:	76 19                	jbe    ffffffff8010186c <cpuinfo+0x79>
    // structured extended feature flags (ECX=0)
    uint maxsubleaf;
    asm("cpuid" : "=a"(maxsubleaf), "=b"(sef_flags) : "a" (7), "c" (0) :);
ffffffff80101853:	b8 07 00 00 00       	mov    $0x7,%eax
ffffffff80101858:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff8010185d:	89 d1                	mov    %edx,%ecx
ffffffff8010185f:	0f a2                	cpuid  
ffffffff80101861:	89 da                	mov    %ebx,%edx
ffffffff80101863:	89 45 f4             	mov    %eax,-0xc(%rbp)
ffffffff80101866:	89 15 68 cc 08 00    	mov    %edx,0x8cc68(%rip)        # ffffffff8018e4d4 <sef_flags>
  }

  /* ... and many more ... */
}
ffffffff8010186c:	90                   	nop
ffffffff8010186d:	48 83 c4 10          	add    $0x10,%rsp
ffffffff80101871:	5b                   	pop    %rbx
ffffffff80101872:	5d                   	pop    %rbp
ffffffff80101873:	c3                   	retq   

ffffffff80101874 <cpuid_read>:

static int cpuid_read(struct inode* i, char* buf, int count)
{
ffffffff80101874:	55                   	push   %rbp
ffffffff80101875:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101878:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010187c:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80101880:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
ffffffff80101884:	89 55 ec             	mov    %edx,-0x14(%rbp)
   cpu_printfeatures();
ffffffff80101887:	e8 90 f6 ff ff       	callq  ffffffff80100f1c <cpu_printfeatures>

   return 0;
ffffffff8010188c:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80101891:	c9                   	leaveq 
ffffffff80101892:	c3                   	retq   

ffffffff80101893 <cpuid_write>:

static int cpuid_write(struct inode* i, char* buf, int count)
{
ffffffff80101893:	55                   	push   %rbp
ffffffff80101894:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101897:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010189b:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff8010189f:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
ffffffff801018a3:	89 55 ec             	mov    %edx,-0x14(%rbp)
   cprintf("cpuid_write\n");
ffffffff801018a6:	48 c7 c7 5e a7 10 80 	mov    $0xffffffff8010a75e,%rdi
ffffffff801018ad:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801018b2:	e8 eb ec ff ff       	callq  ffffffff801005a2 <cprintf>
   return 0;
ffffffff801018b7:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff801018bc:	c9                   	leaveq 
ffffffff801018bd:	c3                   	retq   

ffffffff801018be <cpuidinit>:

void
cpuidinit(void)
{
ffffffff801018be:	55                   	push   %rbp
ffffffff801018bf:	48 89 e5             	mov    %rsp,%rbp
  devsw[CPUID].write = cpuid_write;
ffffffff801018c2:	48 c7 05 3b cc 08 00 	movq   $0xffffffff80101893,0x8cc3b(%rip)        # ffffffff8018e508 <devsw+0x28>
ffffffff801018c9:	93 18 10 80 
  devsw[CPUID].read = cpuid_read;
ffffffff801018cd:	48 c7 05 28 cc 08 00 	movq   $0xffffffff80101874,0x8cc28(%rip)        # ffffffff8018e500 <devsw+0x20>
ffffffff801018d4:	74 18 10 80 

  cpuinfo();
ffffffff801018d8:	e8 16 ff ff ff       	callq  ffffffff801017f3 <cpuinfo>
}
ffffffff801018dd:	90                   	nop
ffffffff801018de:	5d                   	pop    %rbp
ffffffff801018df:	c3                   	retq   

ffffffff801018e0 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
ffffffff801018e0:	55                   	push   %rbp
ffffffff801018e1:	48 89 e5             	mov    %rsp,%rbp
ffffffff801018e4:	48 81 ec 00 02 00 00 	sub    $0x200,%rsp
ffffffff801018eb:	48 89 bd 08 fe ff ff 	mov    %rdi,-0x1f8(%rbp)
ffffffff801018f2:	48 89 b5 00 fe ff ff 	mov    %rsi,-0x200(%rbp)
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
ffffffff801018f9:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801018fe:	e8 f7 29 00 00       	callq  ffffffff801042fa <begin_op>
  if((ip = namei(path)) == 0){
ffffffff80101903:	48 8b 85 08 fe ff ff 	mov    -0x1f8(%rbp),%rax
ffffffff8010190a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010190d:	e8 5e 1c 00 00       	callq  ffffffff80103570 <namei>
ffffffff80101912:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
ffffffff80101916:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
ffffffff8010191b:	75 14                	jne    ffffffff80101931 <exec+0x51>
    end_op();
ffffffff8010191d:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101922:	e8 55 2a 00 00       	callq  ffffffff8010437c <end_op>
    return -1;
ffffffff80101927:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010192c:	e9 d6 04 00 00       	jmpq   ffffffff80101e07 <exec+0x527>
  }
  ilock(ip);
ffffffff80101931:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101935:	48 89 c7             	mov    %rax,%rdi
ffffffff80101938:	e8 07 0f 00 00       	callq  ffffffff80102844 <ilock>
  pgdir = 0;
ffffffff8010193d:	48 c7 45 c0 00 00 00 	movq   $0x0,-0x40(%rbp)
ffffffff80101944:	00 

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
ffffffff80101945:	48 8d b5 50 fe ff ff 	lea    -0x1b0(%rbp),%rsi
ffffffff8010194c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101950:	b9 40 00 00 00       	mov    $0x40,%ecx
ffffffff80101955:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff8010195a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010195d:	e8 ed 14 00 00       	callq  ffffffff80102e4f <readi>
ffffffff80101962:	83 f8 3f             	cmp    $0x3f,%eax
ffffffff80101965:	0f 86 48 04 00 00    	jbe    ffffffff80101db3 <exec+0x4d3>
    goto bad;
  if(elf.magic != ELF_MAGIC)
ffffffff8010196b:	8b 85 50 fe ff ff    	mov    -0x1b0(%rbp),%eax
ffffffff80101971:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
ffffffff80101976:	0f 85 3a 04 00 00    	jne    ffffffff80101db6 <exec+0x4d6>
    goto bad;

  if((pgdir = setupkvm()) == 0)
ffffffff8010197c:	e8 f1 86 00 00       	callq  ffffffff8010a072 <setupkvm>
ffffffff80101981:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
ffffffff80101985:	48 83 7d c0 00       	cmpq   $0x0,-0x40(%rbp)
ffffffff8010198a:	0f 84 29 04 00 00    	je     ffffffff80101db9 <exec+0x4d9>
    goto bad;

  // Load program into memory.
  sz = 0;
ffffffff80101990:	48 c7 45 d8 00 00 00 	movq   $0x0,-0x28(%rbp)
ffffffff80101997:	00 
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
ffffffff80101998:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)
ffffffff8010199f:	48 8b 85 70 fe ff ff 	mov    -0x190(%rbp),%rax
ffffffff801019a6:	89 45 e8             	mov    %eax,-0x18(%rbp)
ffffffff801019a9:	e9 c8 00 00 00       	jmpq   ffffffff80101a76 <exec+0x196>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
ffffffff801019ae:	8b 55 e8             	mov    -0x18(%rbp),%edx
ffffffff801019b1:	48 8d b5 10 fe ff ff 	lea    -0x1f0(%rbp),%rsi
ffffffff801019b8:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801019bc:	b9 38 00 00 00       	mov    $0x38,%ecx
ffffffff801019c1:	48 89 c7             	mov    %rax,%rdi
ffffffff801019c4:	e8 86 14 00 00       	callq  ffffffff80102e4f <readi>
ffffffff801019c9:	83 f8 38             	cmp    $0x38,%eax
ffffffff801019cc:	0f 85 ea 03 00 00    	jne    ffffffff80101dbc <exec+0x4dc>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
ffffffff801019d2:	8b 85 10 fe ff ff    	mov    -0x1f0(%rbp),%eax
ffffffff801019d8:	83 f8 01             	cmp    $0x1,%eax
ffffffff801019db:	0f 85 87 00 00 00    	jne    ffffffff80101a68 <exec+0x188>
      continue;
    if(ph.memsz < ph.filesz)
ffffffff801019e1:	48 8b 95 38 fe ff ff 	mov    -0x1c8(%rbp),%rdx
ffffffff801019e8:	48 8b 85 30 fe ff ff 	mov    -0x1d0(%rbp),%rax
ffffffff801019ef:	48 39 c2             	cmp    %rax,%rdx
ffffffff801019f2:	0f 82 c7 03 00 00    	jb     ffffffff80101dbf <exec+0x4df>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
ffffffff801019f8:	48 8b 85 20 fe ff ff 	mov    -0x1e0(%rbp),%rax
ffffffff801019ff:	89 c2                	mov    %eax,%edx
ffffffff80101a01:	48 8b 85 38 fe ff ff 	mov    -0x1c8(%rbp),%rax
ffffffff80101a08:	01 c2                	add    %eax,%edx
ffffffff80101a0a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101a0e:	89 c1                	mov    %eax,%ecx
ffffffff80101a10:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80101a14:	89 ce                	mov    %ecx,%esi
ffffffff80101a16:	48 89 c7             	mov    %rax,%rdi
ffffffff80101a19:	e8 e3 7c 00 00       	callq  ffffffff80109701 <allocuvm>
ffffffff80101a1e:	48 98                	cltq   
ffffffff80101a20:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
ffffffff80101a24:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
ffffffff80101a29:	0f 84 93 03 00 00    	je     ffffffff80101dc2 <exec+0x4e2>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
ffffffff80101a2f:	48 8b 85 30 fe ff ff 	mov    -0x1d0(%rbp),%rax
ffffffff80101a36:	89 c7                	mov    %eax,%edi
ffffffff80101a38:	48 8b 85 18 fe ff ff 	mov    -0x1e8(%rbp),%rax
ffffffff80101a3f:	89 c1                	mov    %eax,%ecx
ffffffff80101a41:	48 8b 85 20 fe ff ff 	mov    -0x1e0(%rbp),%rax
ffffffff80101a48:	48 89 c6             	mov    %rax,%rsi
ffffffff80101a4b:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
ffffffff80101a4f:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80101a53:	41 89 f8             	mov    %edi,%r8d
ffffffff80101a56:	48 89 c7             	mov    %rax,%rdi
ffffffff80101a59:	e8 a8 7b 00 00       	callq  ffffffff80109606 <loaduvm>
ffffffff80101a5e:	85 c0                	test   %eax,%eax
ffffffff80101a60:	0f 88 5f 03 00 00    	js     ffffffff80101dc5 <exec+0x4e5>
ffffffff80101a66:	eb 01                	jmp    ffffffff80101a69 <exec+0x189>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
ffffffff80101a68:	90                   	nop
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
ffffffff80101a69:	83 45 ec 01          	addl   $0x1,-0x14(%rbp)
ffffffff80101a6d:	8b 45 e8             	mov    -0x18(%rbp),%eax
ffffffff80101a70:	83 c0 38             	add    $0x38,%eax
ffffffff80101a73:	89 45 e8             	mov    %eax,-0x18(%rbp)
ffffffff80101a76:	0f b7 85 88 fe ff ff 	movzwl -0x178(%rbp),%eax
ffffffff80101a7d:	0f b7 c0             	movzwl %ax,%eax
ffffffff80101a80:	3b 45 ec             	cmp    -0x14(%rbp),%eax
ffffffff80101a83:	0f 8f 25 ff ff ff    	jg     ffffffff801019ae <exec+0xce>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
ffffffff80101a89:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101a8d:	48 89 c7             	mov    %rax,%rdi
ffffffff80101a90:	e8 a5 10 00 00       	callq  ffffffff80102b3a <iunlockput>
  end_op();
ffffffff80101a95:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101a9a:	e8 dd 28 00 00       	callq  ffffffff8010437c <end_op>
  ip = 0;
ffffffff80101a9f:	48 c7 45 c8 00 00 00 	movq   $0x0,-0x38(%rbp)
ffffffff80101aa6:	00 

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  // The first page is used as a guarded page to limit the stack's memory to one page
  // As the first page isn't used and thus accessing it would cause an exception.
  sz = PGROUNDUP(sz);
ffffffff80101aa7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101aab:	48 05 ff 0f 00 00    	add    $0xfff,%rax
ffffffff80101ab1:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff80101ab7:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
ffffffff80101abb:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101abf:	8d 90 00 20 00 00    	lea    0x2000(%rax),%edx
ffffffff80101ac5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101ac9:	89 c1                	mov    %eax,%ecx
ffffffff80101acb:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80101acf:	89 ce                	mov    %ecx,%esi
ffffffff80101ad1:	48 89 c7             	mov    %rax,%rdi
ffffffff80101ad4:	e8 28 7c 00 00       	callq  ffffffff80109701 <allocuvm>
ffffffff80101ad9:	48 98                	cltq   
ffffffff80101adb:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
ffffffff80101adf:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
ffffffff80101ae4:	0f 84 de 02 00 00    	je     ffffffff80101dc8 <exec+0x4e8>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
ffffffff80101aea:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101aee:	48 2d 00 20 00 00    	sub    $0x2000,%rax
ffffffff80101af4:	48 89 c2             	mov    %rax,%rdx
ffffffff80101af7:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80101afb:	48 89 d6             	mov    %rdx,%rsi
ffffffff80101afe:	48 89 c7             	mov    %rax,%rdi
ffffffff80101b01:	e8 5c 7e 00 00       	callq  ffffffff80109962 <clearpteu>
  sp = sz;
ffffffff80101b06:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80101b0a:	48 89 45 d0          	mov    %rax,-0x30(%rbp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
ffffffff80101b0e:	48 c7 45 e0 00 00 00 	movq   $0x0,-0x20(%rbp)
ffffffff80101b15:	00 
ffffffff80101b16:	e9 b5 00 00 00       	jmpq   ffffffff80101bd0 <exec+0x2f0>
    if(argc >= MAXARG)
ffffffff80101b1b:	48 83 7d e0 1f       	cmpq   $0x1f,-0x20(%rbp)
ffffffff80101b20:	0f 87 a5 02 00 00    	ja     ffffffff80101dcb <exec+0x4eb>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~(sizeof(uintp)-1);
ffffffff80101b26:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101b2a:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80101b31:	00 
ffffffff80101b32:	48 8b 85 00 fe ff ff 	mov    -0x200(%rbp),%rax
ffffffff80101b39:	48 01 d0             	add    %rdx,%rax
ffffffff80101b3c:	48 8b 00             	mov    (%rax),%rax
ffffffff80101b3f:	48 89 c7             	mov    %rax,%rdi
ffffffff80101b42:	e8 c3 53 00 00       	callq  ffffffff80106f0a <strlen>
ffffffff80101b47:	83 c0 01             	add    $0x1,%eax
ffffffff80101b4a:	48 98                	cltq   
ffffffff80101b4c:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff80101b50:	48 29 c2             	sub    %rax,%rdx
ffffffff80101b53:	48 89 d0             	mov    %rdx,%rax
ffffffff80101b56:	48 83 e0 f8          	and    $0xfffffffffffffff8,%rax
ffffffff80101b5a:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
ffffffff80101b5e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101b62:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80101b69:	00 
ffffffff80101b6a:	48 8b 85 00 fe ff ff 	mov    -0x200(%rbp),%rax
ffffffff80101b71:	48 01 d0             	add    %rdx,%rax
ffffffff80101b74:	48 8b 00             	mov    (%rax),%rax
ffffffff80101b77:	48 89 c7             	mov    %rax,%rdi
ffffffff80101b7a:	e8 8b 53 00 00       	callq  ffffffff80106f0a <strlen>
ffffffff80101b7f:	83 c0 01             	add    $0x1,%eax
ffffffff80101b82:	89 c1                	mov    %eax,%ecx
ffffffff80101b84:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101b88:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80101b8f:	00 
ffffffff80101b90:	48 8b 85 00 fe ff ff 	mov    -0x200(%rbp),%rax
ffffffff80101b97:	48 01 d0             	add    %rdx,%rax
ffffffff80101b9a:	48 8b 10             	mov    (%rax),%rdx
ffffffff80101b9d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80101ba1:	89 c6                	mov    %eax,%esi
ffffffff80101ba3:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80101ba7:	48 89 c7             	mov    %rax,%rdi
ffffffff80101baa:	e8 b9 7f 00 00       	callq  ffffffff80109b68 <copyout>
ffffffff80101baf:	85 c0                	test   %eax,%eax
ffffffff80101bb1:	0f 88 17 02 00 00    	js     ffffffff80101dce <exec+0x4ee>
      goto bad;
    ustack[3+argc] = sp;
ffffffff80101bb7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101bbb:	48 8d 50 03          	lea    0x3(%rax),%rdx
ffffffff80101bbf:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80101bc3:	48 89 84 d5 90 fe ff 	mov    %rax,-0x170(%rbp,%rdx,8)
ffffffff80101bca:	ff 
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
ffffffff80101bcb:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
ffffffff80101bd0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101bd4:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80101bdb:	00 
ffffffff80101bdc:	48 8b 85 00 fe ff ff 	mov    -0x200(%rbp),%rax
ffffffff80101be3:	48 01 d0             	add    %rdx,%rax
ffffffff80101be6:	48 8b 00             	mov    (%rax),%rax
ffffffff80101be9:	48 85 c0             	test   %rax,%rax
ffffffff80101bec:	0f 85 29 ff ff ff    	jne    ffffffff80101b1b <exec+0x23b>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~(sizeof(uintp)-1);
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
ffffffff80101bf2:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101bf6:	48 83 c0 03          	add    $0x3,%rax
ffffffff80101bfa:	48 c7 84 c5 90 fe ff 	movq   $0x0,-0x170(%rbp,%rax,8)
ffffffff80101c01:	ff 00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
ffffffff80101c06:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80101c0b:	48 89 85 90 fe ff ff 	mov    %rax,-0x170(%rbp)
  ustack[1] = argc;
ffffffff80101c12:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101c16:	48 89 85 98 fe ff ff 	mov    %rax,-0x168(%rbp)
  ustack[2] = sp - (argc+1)*sizeof(uintp);  // argv pointer
ffffffff80101c1d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101c21:	48 83 c0 01          	add    $0x1,%rax
ffffffff80101c25:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80101c2c:	00 
ffffffff80101c2d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80101c31:	48 29 d0             	sub    %rdx,%rax
ffffffff80101c34:	48 89 85 a0 fe ff ff 	mov    %rax,-0x160(%rbp)

#if X64
  proc->tf->rdi = argc;
ffffffff80101c3b:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80101c42:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80101c46:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80101c4a:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80101c4e:	48 89 50 30          	mov    %rdx,0x30(%rax)
  proc->tf->rsi = sp - (argc+1)*sizeof(uintp);
ffffffff80101c52:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80101c59:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80101c5d:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80101c61:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80101c65:	48 83 c2 01          	add    $0x1,%rdx
ffffffff80101c69:	48 8d 0c d5 00 00 00 	lea    0x0(,%rdx,8),%rcx
ffffffff80101c70:	00 
ffffffff80101c71:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff80101c75:	48 29 ca             	sub    %rcx,%rdx
ffffffff80101c78:	48 89 50 28          	mov    %rdx,0x28(%rax)
#endif

  sp -= (3+argc+1) * sizeof(uintp);
ffffffff80101c7c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101c80:	48 83 c0 04          	add    $0x4,%rax
ffffffff80101c84:	48 c1 e0 03          	shl    $0x3,%rax
ffffffff80101c88:	48 29 45 d0          	sub    %rax,-0x30(%rbp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*sizeof(uintp)) < 0)
ffffffff80101c8c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101c90:	48 83 c0 04          	add    $0x4,%rax
ffffffff80101c94:	8d 0c c5 00 00 00 00 	lea    0x0(,%rax,8),%ecx
ffffffff80101c9b:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80101c9f:	89 c6                	mov    %eax,%esi
ffffffff80101ca1:	48 8d 95 90 fe ff ff 	lea    -0x170(%rbp),%rdx
ffffffff80101ca8:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80101cac:	48 89 c7             	mov    %rax,%rdi
ffffffff80101caf:	e8 b4 7e 00 00       	callq  ffffffff80109b68 <copyout>
ffffffff80101cb4:	85 c0                	test   %eax,%eax
ffffffff80101cb6:	0f 88 15 01 00 00    	js     ffffffff80101dd1 <exec+0x4f1>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
ffffffff80101cbc:	48 8b 85 08 fe ff ff 	mov    -0x1f8(%rbp),%rax
ffffffff80101cc3:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80101cc7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101ccb:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80101ccf:	eb 1c                	jmp    ffffffff80101ced <exec+0x40d>
    if(*s == '/')
ffffffff80101cd1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101cd5:	0f b6 00             	movzbl (%rax),%eax
ffffffff80101cd8:	3c 2f                	cmp    $0x2f,%al
ffffffff80101cda:	75 0c                	jne    ffffffff80101ce8 <exec+0x408>
      last = s+1;
ffffffff80101cdc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101ce0:	48 83 c0 01          	add    $0x1,%rax
ffffffff80101ce4:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  sp -= (3+argc+1) * sizeof(uintp);
  if(copyout(pgdir, sp, ustack, (3+argc+1)*sizeof(uintp)) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
ffffffff80101ce8:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
ffffffff80101ced:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101cf1:	0f b6 00             	movzbl (%rax),%eax
ffffffff80101cf4:	84 c0                	test   %al,%al
ffffffff80101cf6:	75 d9                	jne    ffffffff80101cd1 <exec+0x3f1>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
ffffffff80101cf8:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80101cff:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80101d03:	48 8d 88 d0 00 00 00 	lea    0xd0(%rax),%rcx
ffffffff80101d0a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80101d0e:	ba 10 00 00 00       	mov    $0x10,%edx
ffffffff80101d13:	48 89 c6             	mov    %rax,%rsi
ffffffff80101d16:	48 89 cf             	mov    %rcx,%rdi
ffffffff80101d19:	e8 8a 51 00 00       	callq  ffffffff80106ea8 <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
ffffffff80101d1e:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80101d25:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80101d29:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80101d2d:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
  proc->pgdir = pgdir;
ffffffff80101d31:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80101d38:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80101d3c:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
ffffffff80101d40:	48 89 50 08          	mov    %rdx,0x8(%rax)
  proc->sz = sz;
ffffffff80101d44:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80101d4b:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80101d4f:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff80101d53:	48 89 10             	mov    %rdx,(%rax)
  proc->tf->eip = elf.entry;  // main
ffffffff80101d56:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80101d5d:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80101d61:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80101d65:	48 8b 95 68 fe ff ff 	mov    -0x198(%rbp),%rdx
ffffffff80101d6c:	48 89 90 88 00 00 00 	mov    %rdx,0x88(%rax)
  proc->tf->esp = sp;
ffffffff80101d73:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80101d7a:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80101d7e:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80101d82:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff80101d86:	48 89 90 a0 00 00 00 	mov    %rdx,0xa0(%rax)
  switchuvm(proc);
ffffffff80101d8d:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80101d94:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80101d98:	48 89 c7             	mov    %rax,%rdi
ffffffff80101d9b:	e8 a5 85 00 00       	callq  ffffffff8010a345 <switchuvm>
  freevm(oldpgdir);
ffffffff80101da0:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff80101da4:	48 89 c7             	mov    %rax,%rdi
ffffffff80101da7:	e8 0c 7b 00 00       	callq  ffffffff801098b8 <freevm>
  return 0;
ffffffff80101dac:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101db1:	eb 54                	jmp    ffffffff80101e07 <exec+0x527>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
ffffffff80101db3:	90                   	nop
ffffffff80101db4:	eb 1c                	jmp    ffffffff80101dd2 <exec+0x4f2>
  if(elf.magic != ELF_MAGIC)
    goto bad;
ffffffff80101db6:	90                   	nop
ffffffff80101db7:	eb 19                	jmp    ffffffff80101dd2 <exec+0x4f2>

  if((pgdir = setupkvm()) == 0)
    goto bad;
ffffffff80101db9:	90                   	nop
ffffffff80101dba:	eb 16                	jmp    ffffffff80101dd2 <exec+0x4f2>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
ffffffff80101dbc:	90                   	nop
ffffffff80101dbd:	eb 13                	jmp    ffffffff80101dd2 <exec+0x4f2>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
ffffffff80101dbf:	90                   	nop
ffffffff80101dc0:	eb 10                	jmp    ffffffff80101dd2 <exec+0x4f2>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
ffffffff80101dc2:	90                   	nop
ffffffff80101dc3:	eb 0d                	jmp    ffffffff80101dd2 <exec+0x4f2>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
ffffffff80101dc5:	90                   	nop
ffffffff80101dc6:	eb 0a                	jmp    ffffffff80101dd2 <exec+0x4f2>
  // Make the first inaccessible.  Use the second as the user stack.
  // The first page is used as a guarded page to limit the stack's memory to one page
  // As the first page isn't used and thus accessing it would cause an exception.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
ffffffff80101dc8:	90                   	nop
ffffffff80101dc9:	eb 07                	jmp    ffffffff80101dd2 <exec+0x4f2>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
ffffffff80101dcb:	90                   	nop
ffffffff80101dcc:	eb 04                	jmp    ffffffff80101dd2 <exec+0x4f2>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~(sizeof(uintp)-1);
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
ffffffff80101dce:	90                   	nop
ffffffff80101dcf:	eb 01                	jmp    ffffffff80101dd2 <exec+0x4f2>
  proc->tf->rsi = sp - (argc+1)*sizeof(uintp);
#endif

  sp -= (3+argc+1) * sizeof(uintp);
  if(copyout(pgdir, sp, ustack, (3+argc+1)*sizeof(uintp)) < 0)
    goto bad;
ffffffff80101dd1:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
ffffffff80101dd2:	48 83 7d c0 00       	cmpq   $0x0,-0x40(%rbp)
ffffffff80101dd7:	74 0c                	je     ffffffff80101de5 <exec+0x505>
    freevm(pgdir);
ffffffff80101dd9:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80101ddd:	48 89 c7             	mov    %rax,%rdi
ffffffff80101de0:	e8 d3 7a 00 00       	callq  ffffffff801098b8 <freevm>
  if(ip){
ffffffff80101de5:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
ffffffff80101dea:	74 16                	je     ffffffff80101e02 <exec+0x522>
    iunlockput(ip);
ffffffff80101dec:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101df0:	48 89 c7             	mov    %rax,%rdi
ffffffff80101df3:	e8 42 0d 00 00       	callq  ffffffff80102b3a <iunlockput>
    end_op();
ffffffff80101df8:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101dfd:	e8 7a 25 00 00       	callq  ffffffff8010437c <end_op>
  }
  return -1;
ffffffff80101e02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff80101e07:	c9                   	leaveq 
ffffffff80101e08:	c3                   	retq   

ffffffff80101e09 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
ffffffff80101e09:	55                   	push   %rbp
ffffffff80101e0a:	48 89 e5             	mov    %rsp,%rbp
  initlock(&ftable.lock, "ftable");
ffffffff80101e0d:	48 c7 c6 6b a7 10 80 	mov    $0xffffffff8010a76b,%rsi
ffffffff80101e14:	48 c7 c7 80 e5 18 80 	mov    $0xffffffff8018e580,%rdi
ffffffff80101e1b:	e8 49 4a 00 00       	callq  ffffffff80106869 <initlock>
}
ffffffff80101e20:	90                   	nop
ffffffff80101e21:	5d                   	pop    %rbp
ffffffff80101e22:	c3                   	retq   

ffffffff80101e23 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
ffffffff80101e23:	55                   	push   %rbp
ffffffff80101e24:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101e27:	48 83 ec 10          	sub    $0x10,%rsp
  struct file *f;

  acquire(&ftable.lock);
ffffffff80101e2b:	48 c7 c7 80 e5 18 80 	mov    $0xffffffff8018e580,%rdi
ffffffff80101e32:	e8 67 4a 00 00       	callq  ffffffff8010689e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
ffffffff80101e37:	48 c7 45 f8 e8 e5 18 	movq   $0xffffffff8018e5e8,-0x8(%rbp)
ffffffff80101e3e:	80 
ffffffff80101e3f:	eb 2d                	jmp    ffffffff80101e6e <filealloc+0x4b>
    if(f->ref == 0){
ffffffff80101e41:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101e45:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80101e48:	85 c0                	test   %eax,%eax
ffffffff80101e4a:	75 1d                	jne    ffffffff80101e69 <filealloc+0x46>
      f->ref = 1;
ffffffff80101e4c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101e50:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%rax)
      release(&ftable.lock);
ffffffff80101e57:	48 c7 c7 80 e5 18 80 	mov    $0xffffffff8018e580,%rdi
ffffffff80101e5e:	e8 12 4b 00 00       	callq  ffffffff80106975 <release>
      return f;
ffffffff80101e63:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101e67:	eb 23                	jmp    ffffffff80101e8c <filealloc+0x69>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
ffffffff80101e69:	48 83 45 f8 28       	addq   $0x28,-0x8(%rbp)
ffffffff80101e6e:	48 c7 c0 88 f5 18 80 	mov    $0xffffffff8018f588,%rax
ffffffff80101e75:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
ffffffff80101e79:	72 c6                	jb     ffffffff80101e41 <filealloc+0x1e>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
ffffffff80101e7b:	48 c7 c7 80 e5 18 80 	mov    $0xffffffff8018e580,%rdi
ffffffff80101e82:	e8 ee 4a 00 00       	callq  ffffffff80106975 <release>
  return 0;
ffffffff80101e87:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80101e8c:	c9                   	leaveq 
ffffffff80101e8d:	c3                   	retq   

ffffffff80101e8e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
ffffffff80101e8e:	55                   	push   %rbp
ffffffff80101e8f:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101e92:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80101e96:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  acquire(&ftable.lock);
ffffffff80101e9a:	48 c7 c7 80 e5 18 80 	mov    $0xffffffff8018e580,%rdi
ffffffff80101ea1:	e8 f8 49 00 00       	callq  ffffffff8010689e <acquire>
  if(f->ref < 1)
ffffffff80101ea6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101eaa:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80101ead:	85 c0                	test   %eax,%eax
ffffffff80101eaf:	7f 0c                	jg     ffffffff80101ebd <filedup+0x2f>
    panic("filedup");
ffffffff80101eb1:	48 c7 c7 72 a7 10 80 	mov    $0xffffffff8010a772,%rdi
ffffffff80101eb8:	e8 42 ea ff ff       	callq  ffffffff801008ff <panic>
  f->ref++;
ffffffff80101ebd:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101ec1:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80101ec4:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80101ec7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101ecb:	89 50 04             	mov    %edx,0x4(%rax)
  release(&ftable.lock);
ffffffff80101ece:	48 c7 c7 80 e5 18 80 	mov    $0xffffffff8018e580,%rdi
ffffffff80101ed5:	e8 9b 4a 00 00       	callq  ffffffff80106975 <release>
  return f;
ffffffff80101eda:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80101ede:	c9                   	leaveq 
ffffffff80101edf:	c3                   	retq   

ffffffff80101ee0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
ffffffff80101ee0:	55                   	push   %rbp
ffffffff80101ee1:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101ee4:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff80101ee8:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  struct file ff;

  acquire(&ftable.lock);
ffffffff80101eec:	48 c7 c7 80 e5 18 80 	mov    $0xffffffff8018e580,%rdi
ffffffff80101ef3:	e8 a6 49 00 00       	callq  ffffffff8010689e <acquire>
  if(f->ref < 1)
ffffffff80101ef8:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101efc:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80101eff:	85 c0                	test   %eax,%eax
ffffffff80101f01:	7f 0c                	jg     ffffffff80101f0f <fileclose+0x2f>
    panic("fileclose");
ffffffff80101f03:	48 c7 c7 7a a7 10 80 	mov    $0xffffffff8010a77a,%rdi
ffffffff80101f0a:	e8 f0 e9 ff ff       	callq  ffffffff801008ff <panic>
  if(--f->ref > 0){
ffffffff80101f0f:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101f13:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80101f16:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80101f19:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101f1d:	89 50 04             	mov    %edx,0x4(%rax)
ffffffff80101f20:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101f24:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80101f27:	85 c0                	test   %eax,%eax
ffffffff80101f29:	7e 11                	jle    ffffffff80101f3c <fileclose+0x5c>
    release(&ftable.lock);
ffffffff80101f2b:	48 c7 c7 80 e5 18 80 	mov    $0xffffffff8018e580,%rdi
ffffffff80101f32:	e8 3e 4a 00 00       	callq  ffffffff80106975 <release>
ffffffff80101f37:	e9 93 00 00 00       	jmpq   ffffffff80101fcf <fileclose+0xef>
    return;
  }
  ff = *f;
ffffffff80101f3c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101f40:	48 8b 10             	mov    (%rax),%rdx
ffffffff80101f43:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
ffffffff80101f47:	48 8b 50 08          	mov    0x8(%rax),%rdx
ffffffff80101f4b:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
ffffffff80101f4f:	48 8b 50 10          	mov    0x10(%rax),%rdx
ffffffff80101f53:	48 89 55 e0          	mov    %rdx,-0x20(%rbp)
ffffffff80101f57:	48 8b 50 18          	mov    0x18(%rax),%rdx
ffffffff80101f5b:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
ffffffff80101f5f:	48 8b 40 20          	mov    0x20(%rax),%rax
ffffffff80101f63:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  f->ref = 0;
ffffffff80101f67:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101f6b:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%rax)
  f->type = FD_NONE;
ffffffff80101f72:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80101f76:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  release(&ftable.lock);
ffffffff80101f7c:	48 c7 c7 80 e5 18 80 	mov    $0xffffffff8018e580,%rdi
ffffffff80101f83:	e8 ed 49 00 00       	callq  ffffffff80106975 <release>
  
  if(ff.type == FD_PIPE)
ffffffff80101f88:	8b 45 d0             	mov    -0x30(%rbp),%eax
ffffffff80101f8b:	83 f8 01             	cmp    $0x1,%eax
ffffffff80101f8e:	75 17                	jne    ffffffff80101fa7 <fileclose+0xc7>
    pipeclose(ff.pipe, ff.writable);
ffffffff80101f90:	0f b6 45 d9          	movzbl -0x27(%rbp),%eax
ffffffff80101f94:	0f be d0             	movsbl %al,%edx
ffffffff80101f97:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80101f9b:	89 d6                	mov    %edx,%esi
ffffffff80101f9d:	48 89 c7             	mov    %rax,%rdi
ffffffff80101fa0:	e8 aa 38 00 00       	callq  ffffffff8010584f <pipeclose>
ffffffff80101fa5:	eb 28                	jmp    ffffffff80101fcf <fileclose+0xef>
  else if(ff.type == FD_INODE){
ffffffff80101fa7:	8b 45 d0             	mov    -0x30(%rbp),%eax
ffffffff80101faa:	83 f8 02             	cmp    $0x2,%eax
ffffffff80101fad:	75 20                	jne    ffffffff80101fcf <fileclose+0xef>
    begin_op();
ffffffff80101faf:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101fb4:	e8 41 23 00 00       	callq  ffffffff801042fa <begin_op>
    iput(ff.ip);
ffffffff80101fb9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80101fbd:	48 89 c7             	mov    %rax,%rdi
ffffffff80101fc0:	e8 90 0a 00 00       	callq  ffffffff80102a55 <iput>
    end_op();
ffffffff80101fc5:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80101fca:	e8 ad 23 00 00       	callq  ffffffff8010437c <end_op>
  }
}
ffffffff80101fcf:	c9                   	leaveq 
ffffffff80101fd0:	c3                   	retq   

ffffffff80101fd1 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
ffffffff80101fd1:	55                   	push   %rbp
ffffffff80101fd2:	48 89 e5             	mov    %rsp,%rbp
ffffffff80101fd5:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80101fd9:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80101fdd:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  if(f->type == FD_INODE){
ffffffff80101fe1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101fe5:	8b 00                	mov    (%rax),%eax
ffffffff80101fe7:	83 f8 02             	cmp    $0x2,%eax
ffffffff80101fea:	75 3e                	jne    ffffffff8010202a <filestat+0x59>
    ilock(f->ip);
ffffffff80101fec:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80101ff0:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff80101ff4:	48 89 c7             	mov    %rax,%rdi
ffffffff80101ff7:	e8 48 08 00 00       	callq  ffffffff80102844 <ilock>
    stati(f->ip, st);
ffffffff80101ffc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102000:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff80102004:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff80102008:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010200b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010200e:	e8 b1 0d 00 00       	callq  ffffffff80102dc4 <stati>
    iunlock(f->ip);
ffffffff80102013:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102017:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff8010201b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010201e:	e8 c0 09 00 00       	callq  ffffffff801029e3 <iunlock>
    return 0;
ffffffff80102023:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80102028:	eb 05                	jmp    ffffffff8010202f <filestat+0x5e>
  }
  return -1;
ffffffff8010202a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff8010202f:	c9                   	leaveq 
ffffffff80102030:	c3                   	retq   

ffffffff80102031 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
ffffffff80102031:	55                   	push   %rbp
ffffffff80102032:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102035:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80102039:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff8010203d:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80102041:	89 55 dc             	mov    %edx,-0x24(%rbp)
  int r;

  if(f->readable == 0)
ffffffff80102044:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102048:	0f b6 40 08          	movzbl 0x8(%rax),%eax
ffffffff8010204c:	84 c0                	test   %al,%al
ffffffff8010204e:	75 0a                	jne    ffffffff8010205a <fileread+0x29>
    return -1;
ffffffff80102050:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80102055:	e9 9d 00 00 00       	jmpq   ffffffff801020f7 <fileread+0xc6>
  if(f->type == FD_PIPE)
ffffffff8010205a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010205e:	8b 00                	mov    (%rax),%eax
ffffffff80102060:	83 f8 01             	cmp    $0x1,%eax
ffffffff80102063:	75 1c                	jne    ffffffff80102081 <fileread+0x50>
    return piperead(f->pipe, addr, n);
ffffffff80102065:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102069:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff8010206d:	8b 55 dc             	mov    -0x24(%rbp),%edx
ffffffff80102070:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
ffffffff80102074:	48 89 ce             	mov    %rcx,%rsi
ffffffff80102077:	48 89 c7             	mov    %rax,%rdi
ffffffff8010207a:	e8 89 39 00 00       	callq  ffffffff80105a08 <piperead>
ffffffff8010207f:	eb 76                	jmp    ffffffff801020f7 <fileread+0xc6>
  if(f->type == FD_INODE){
ffffffff80102081:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102085:	8b 00                	mov    (%rax),%eax
ffffffff80102087:	83 f8 02             	cmp    $0x2,%eax
ffffffff8010208a:	75 5f                	jne    ffffffff801020eb <fileread+0xba>
    ilock(f->ip);
ffffffff8010208c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102090:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff80102094:	48 89 c7             	mov    %rax,%rdi
ffffffff80102097:	e8 a8 07 00 00       	callq  ffffffff80102844 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
ffffffff8010209c:	8b 4d dc             	mov    -0x24(%rbp),%ecx
ffffffff8010209f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801020a3:	8b 50 20             	mov    0x20(%rax),%edx
ffffffff801020a6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801020aa:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff801020ae:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
ffffffff801020b2:	48 89 c7             	mov    %rax,%rdi
ffffffff801020b5:	e8 95 0d 00 00       	callq  ffffffff80102e4f <readi>
ffffffff801020ba:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff801020bd:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff801020c1:	7e 13                	jle    ffffffff801020d6 <fileread+0xa5>
      f->off += r;
ffffffff801020c3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801020c7:	8b 50 20             	mov    0x20(%rax),%edx
ffffffff801020ca:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801020cd:	01 c2                	add    %eax,%edx
ffffffff801020cf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801020d3:	89 50 20             	mov    %edx,0x20(%rax)
    iunlock(f->ip);
ffffffff801020d6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801020da:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff801020de:	48 89 c7             	mov    %rax,%rdi
ffffffff801020e1:	e8 fd 08 00 00       	callq  ffffffff801029e3 <iunlock>
    return r;
ffffffff801020e6:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801020e9:	eb 0c                	jmp    ffffffff801020f7 <fileread+0xc6>
  }
  panic("fileread");
ffffffff801020eb:	48 c7 c7 84 a7 10 80 	mov    $0xffffffff8010a784,%rdi
ffffffff801020f2:	e8 08 e8 ff ff       	callq  ffffffff801008ff <panic>
}
ffffffff801020f7:	c9                   	leaveq 
ffffffff801020f8:	c3                   	retq   

ffffffff801020f9 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
ffffffff801020f9:	55                   	push   %rbp
ffffffff801020fa:	48 89 e5             	mov    %rsp,%rbp
ffffffff801020fd:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80102101:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80102105:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80102109:	89 55 dc             	mov    %edx,-0x24(%rbp)
  int r;

  if(f->writable == 0)
ffffffff8010210c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102110:	0f b6 40 09          	movzbl 0x9(%rax),%eax
ffffffff80102114:	84 c0                	test   %al,%al
ffffffff80102116:	75 0a                	jne    ffffffff80102122 <filewrite+0x29>
    return -1;
ffffffff80102118:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010211d:	e9 29 01 00 00       	jmpq   ffffffff8010224b <filewrite+0x152>
  if(f->type == FD_PIPE)
ffffffff80102122:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102126:	8b 00                	mov    (%rax),%eax
ffffffff80102128:	83 f8 01             	cmp    $0x1,%eax
ffffffff8010212b:	75 1f                	jne    ffffffff8010214c <filewrite+0x53>
    return pipewrite(f->pipe, addr, n);
ffffffff8010212d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102131:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff80102135:	8b 55 dc             	mov    -0x24(%rbp),%edx
ffffffff80102138:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
ffffffff8010213c:	48 89 ce             	mov    %rcx,%rsi
ffffffff8010213f:	48 89 c7             	mov    %rax,%rdi
ffffffff80102142:	e8 b0 37 00 00       	callq  ffffffff801058f7 <pipewrite>
ffffffff80102147:	e9 ff 00 00 00       	jmpq   ffffffff8010224b <filewrite+0x152>
  if(f->type == FD_INODE){
ffffffff8010214c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102150:	8b 00                	mov    (%rax),%eax
ffffffff80102152:	83 f8 02             	cmp    $0x2,%eax
ffffffff80102155:	0f 85 e4 00 00 00    	jne    ffffffff8010223f <filewrite+0x146>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
ffffffff8010215b:	c7 45 f4 00 1a 00 00 	movl   $0x1a00,-0xc(%rbp)
    int i = 0;
ffffffff80102162:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
    while(i < n){
ffffffff80102169:	e9 ae 00 00 00       	jmpq   ffffffff8010221c <filewrite+0x123>
      int n1 = n - i;
ffffffff8010216e:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80102171:	2b 45 fc             	sub    -0x4(%rbp),%eax
ffffffff80102174:	89 45 f8             	mov    %eax,-0x8(%rbp)
      if(n1 > max)
ffffffff80102177:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff8010217a:	3b 45 f4             	cmp    -0xc(%rbp),%eax
ffffffff8010217d:	7e 06                	jle    ffffffff80102185 <filewrite+0x8c>
        n1 = max;
ffffffff8010217f:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80102182:	89 45 f8             	mov    %eax,-0x8(%rbp)

      begin_op();
ffffffff80102185:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010218a:	e8 6b 21 00 00       	callq  ffffffff801042fa <begin_op>
      ilock(f->ip);
ffffffff8010218f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102193:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff80102197:	48 89 c7             	mov    %rax,%rdi
ffffffff8010219a:	e8 a5 06 00 00       	callq  ffffffff80102844 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
ffffffff8010219f:	8b 4d f8             	mov    -0x8(%rbp),%ecx
ffffffff801021a2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801021a6:	8b 50 20             	mov    0x20(%rax),%edx
ffffffff801021a9:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801021ac:	48 63 f0             	movslq %eax,%rsi
ffffffff801021af:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801021b3:	48 01 c6             	add    %rax,%rsi
ffffffff801021b6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801021ba:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff801021be:	48 89 c7             	mov    %rax,%rdi
ffffffff801021c1:	e8 09 0e 00 00       	callq  ffffffff80102fcf <writei>
ffffffff801021c6:	89 45 f0             	mov    %eax,-0x10(%rbp)
ffffffff801021c9:	83 7d f0 00          	cmpl   $0x0,-0x10(%rbp)
ffffffff801021cd:	7e 13                	jle    ffffffff801021e2 <filewrite+0xe9>
        f->off += r;
ffffffff801021cf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801021d3:	8b 50 20             	mov    0x20(%rax),%edx
ffffffff801021d6:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff801021d9:	01 c2                	add    %eax,%edx
ffffffff801021db:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801021df:	89 50 20             	mov    %edx,0x20(%rax)
      iunlock(f->ip);
ffffffff801021e2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801021e6:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff801021ea:	48 89 c7             	mov    %rax,%rdi
ffffffff801021ed:	e8 f1 07 00 00       	callq  ffffffff801029e3 <iunlock>
      end_op();
ffffffff801021f2:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801021f7:	e8 80 21 00 00       	callq  ffffffff8010437c <end_op>

      if(r < 0)
ffffffff801021fc:	83 7d f0 00          	cmpl   $0x0,-0x10(%rbp)
ffffffff80102200:	78 28                	js     ffffffff8010222a <filewrite+0x131>
        break;
      if(r != n1)
ffffffff80102202:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff80102205:	3b 45 f8             	cmp    -0x8(%rbp),%eax
ffffffff80102208:	74 0c                	je     ffffffff80102216 <filewrite+0x11d>
        panic("short filewrite");
ffffffff8010220a:	48 c7 c7 8d a7 10 80 	mov    $0xffffffff8010a78d,%rdi
ffffffff80102211:	e8 e9 e6 ff ff       	callq  ffffffff801008ff <panic>
      i += r;
ffffffff80102216:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff80102219:	01 45 fc             	add    %eax,-0x4(%rbp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
ffffffff8010221c:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010221f:	3b 45 dc             	cmp    -0x24(%rbp),%eax
ffffffff80102222:	0f 8c 46 ff ff ff    	jl     ffffffff8010216e <filewrite+0x75>
ffffffff80102228:	eb 01                	jmp    ffffffff8010222b <filewrite+0x132>
        f->off += r;
      iunlock(f->ip);
      end_op();

      if(r < 0)
        break;
ffffffff8010222a:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
ffffffff8010222b:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010222e:	3b 45 dc             	cmp    -0x24(%rbp),%eax
ffffffff80102231:	75 05                	jne    ffffffff80102238 <filewrite+0x13f>
ffffffff80102233:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80102236:	eb 13                	jmp    ffffffff8010224b <filewrite+0x152>
ffffffff80102238:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010223d:	eb 0c                	jmp    ffffffff8010224b <filewrite+0x152>
  }
  panic("filewrite");
ffffffff8010223f:	48 c7 c7 9d a7 10 80 	mov    $0xffffffff8010a79d,%rdi
ffffffff80102246:	e8 b4 e6 ff ff       	callq  ffffffff801008ff <panic>
}
ffffffff8010224b:	c9                   	leaveq 
ffffffff8010224c:	c3                   	retq   

ffffffff8010224d <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
ffffffff8010224d:	55                   	push   %rbp
ffffffff8010224e:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102251:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80102255:	89 7d ec             	mov    %edi,-0x14(%rbp)
ffffffff80102258:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  struct buf *bp;
  
  bp = bread(dev, 1);
ffffffff8010225c:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff8010225f:	be 01 00 00 00       	mov    $0x1,%esi
ffffffff80102264:	89 c7                	mov    %eax,%edi
ffffffff80102266:	e8 6b e0 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff8010226b:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  memmove(sb, bp->data, sizeof(*sb));
ffffffff8010226f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102273:	48 8d 48 28          	lea    0x28(%rax),%rcx
ffffffff80102277:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010227b:	ba 10 00 00 00       	mov    $0x10,%edx
ffffffff80102280:	48 89 ce             	mov    %rcx,%rsi
ffffffff80102283:	48 89 c7             	mov    %rax,%rdi
ffffffff80102286:	e8 71 4a 00 00       	callq  ffffffff80106cfc <memmove>
  brelse(bp);
ffffffff8010228b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010228f:	48 89 c7             	mov    %rax,%rdi
ffffffff80102292:	e8 c4 e0 ff ff       	callq  ffffffff8010035b <brelse>
}
ffffffff80102297:	90                   	nop
ffffffff80102298:	c9                   	leaveq 
ffffffff80102299:	c3                   	retq   

ffffffff8010229a <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
ffffffff8010229a:	55                   	push   %rbp
ffffffff8010229b:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010229e:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801022a2:	89 7d ec             	mov    %edi,-0x14(%rbp)
ffffffff801022a5:	89 75 e8             	mov    %esi,-0x18(%rbp)
  struct buf *bp;
  
  bp = bread(dev, bno);
ffffffff801022a8:	8b 55 e8             	mov    -0x18(%rbp),%edx
ffffffff801022ab:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff801022ae:	89 d6                	mov    %edx,%esi
ffffffff801022b0:	89 c7                	mov    %eax,%edi
ffffffff801022b2:	e8 1f e0 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff801022b7:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  memset(bp->data, 0, BSIZE);
ffffffff801022bb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801022bf:	48 83 c0 28          	add    $0x28,%rax
ffffffff801022c3:	ba 00 02 00 00       	mov    $0x200,%edx
ffffffff801022c8:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801022cd:	48 89 c7             	mov    %rax,%rdi
ffffffff801022d0:	e8 38 49 00 00       	callq  ffffffff80106c0d <memset>
  log_write(bp);
ffffffff801022d5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801022d9:	48 89 c7             	mov    %rax,%rdi
ffffffff801022dc:	e8 36 22 00 00       	callq  ffffffff80104517 <log_write>
  brelse(bp);
ffffffff801022e1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801022e5:	48 89 c7             	mov    %rax,%rdi
ffffffff801022e8:	e8 6e e0 ff ff       	callq  ffffffff8010035b <brelse>
}
ffffffff801022ed:	90                   	nop
ffffffff801022ee:	c9                   	leaveq 
ffffffff801022ef:	c3                   	retq   

ffffffff801022f0 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
ffffffff801022f0:	55                   	push   %rbp
ffffffff801022f1:	48 89 e5             	mov    %rsp,%rbp
ffffffff801022f4:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff801022f8:	89 7d cc             	mov    %edi,-0x34(%rbp)
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
ffffffff801022fb:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
ffffffff80102302:	00 
  readsb(dev, &sb);
ffffffff80102303:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff80102306:	48 8d 55 d0          	lea    -0x30(%rbp),%rdx
ffffffff8010230a:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010230d:	89 c7                	mov    %eax,%edi
ffffffff8010230f:	e8 39 ff ff ff       	callq  ffffffff8010224d <readsb>
  for(b = 0; b < sb.size; b += BPB){
ffffffff80102314:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff8010231b:	e9 15 01 00 00       	jmpq   ffffffff80102435 <balloc+0x145>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
ffffffff80102320:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80102323:	8d 90 ff 0f 00 00    	lea    0xfff(%rax),%edx
ffffffff80102329:	85 c0                	test   %eax,%eax
ffffffff8010232b:	0f 48 c2             	cmovs  %edx,%eax
ffffffff8010232e:	c1 f8 0c             	sar    $0xc,%eax
ffffffff80102331:	89 c2                	mov    %eax,%edx
ffffffff80102333:	8b 45 d8             	mov    -0x28(%rbp),%eax
ffffffff80102336:	c1 e8 03             	shr    $0x3,%eax
ffffffff80102339:	01 d0                	add    %edx,%eax
ffffffff8010233b:	8d 50 03             	lea    0x3(%rax),%edx
ffffffff8010233e:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff80102341:	89 d6                	mov    %edx,%esi
ffffffff80102343:	89 c7                	mov    %eax,%edi
ffffffff80102345:	e8 8c df ff ff       	callq  ffffffff801002d6 <bread>
ffffffff8010234a:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
ffffffff8010234e:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
ffffffff80102355:	e9 aa 00 00 00       	jmpq   ffffffff80102404 <balloc+0x114>
      m = 1 << (bi % 8);
ffffffff8010235a:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff8010235d:	99                   	cltd   
ffffffff8010235e:	c1 ea 1d             	shr    $0x1d,%edx
ffffffff80102361:	01 d0                	add    %edx,%eax
ffffffff80102363:	83 e0 07             	and    $0x7,%eax
ffffffff80102366:	29 d0                	sub    %edx,%eax
ffffffff80102368:	ba 01 00 00 00       	mov    $0x1,%edx
ffffffff8010236d:	89 c1                	mov    %eax,%ecx
ffffffff8010236f:	d3 e2                	shl    %cl,%edx
ffffffff80102371:	89 d0                	mov    %edx,%eax
ffffffff80102373:	89 45 ec             	mov    %eax,-0x14(%rbp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
ffffffff80102376:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80102379:	8d 50 07             	lea    0x7(%rax),%edx
ffffffff8010237c:	85 c0                	test   %eax,%eax
ffffffff8010237e:	0f 48 c2             	cmovs  %edx,%eax
ffffffff80102381:	c1 f8 03             	sar    $0x3,%eax
ffffffff80102384:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff80102388:	48 98                	cltq   
ffffffff8010238a:	0f b6 44 02 28       	movzbl 0x28(%rdx,%rax,1),%eax
ffffffff8010238f:	0f b6 c0             	movzbl %al,%eax
ffffffff80102392:	23 45 ec             	and    -0x14(%rbp),%eax
ffffffff80102395:	85 c0                	test   %eax,%eax
ffffffff80102397:	75 67                	jne    ffffffff80102400 <balloc+0x110>
        bp->data[bi/8] |= m;  // Mark block in use.
ffffffff80102399:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff8010239c:	8d 50 07             	lea    0x7(%rax),%edx
ffffffff8010239f:	85 c0                	test   %eax,%eax
ffffffff801023a1:	0f 48 c2             	cmovs  %edx,%eax
ffffffff801023a4:	c1 f8 03             	sar    $0x3,%eax
ffffffff801023a7:	89 c1                	mov    %eax,%ecx
ffffffff801023a9:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff801023ad:	48 63 c1             	movslq %ecx,%rax
ffffffff801023b0:	0f b6 44 02 28       	movzbl 0x28(%rdx,%rax,1),%eax
ffffffff801023b5:	89 c2                	mov    %eax,%edx
ffffffff801023b7:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff801023ba:	09 d0                	or     %edx,%eax
ffffffff801023bc:	89 c6                	mov    %eax,%esi
ffffffff801023be:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff801023c2:	48 63 c1             	movslq %ecx,%rax
ffffffff801023c5:	40 88 74 02 28       	mov    %sil,0x28(%rdx,%rax,1)
        log_write(bp);
ffffffff801023ca:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801023ce:	48 89 c7             	mov    %rax,%rdi
ffffffff801023d1:	e8 41 21 00 00       	callq  ffffffff80104517 <log_write>
        brelse(bp);
ffffffff801023d6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801023da:	48 89 c7             	mov    %rax,%rdi
ffffffff801023dd:	e8 79 df ff ff       	callq  ffffffff8010035b <brelse>
        bzero(dev, b + bi);
ffffffff801023e2:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801023e5:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff801023e8:	01 c2                	add    %eax,%edx
ffffffff801023ea:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff801023ed:	89 d6                	mov    %edx,%esi
ffffffff801023ef:	89 c7                	mov    %eax,%edi
ffffffff801023f1:	e8 a4 fe ff ff       	callq  ffffffff8010229a <bzero>
        return b + bi;
ffffffff801023f6:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801023f9:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff801023fc:	01 d0                	add    %edx,%eax
ffffffff801023fe:	eb 4f                	jmp    ffffffff8010244f <balloc+0x15f>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
ffffffff80102400:	83 45 f8 01          	addl   $0x1,-0x8(%rbp)
ffffffff80102404:	81 7d f8 ff 0f 00 00 	cmpl   $0xfff,-0x8(%rbp)
ffffffff8010240b:	7f 15                	jg     ffffffff80102422 <balloc+0x132>
ffffffff8010240d:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80102410:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80102413:	01 d0                	add    %edx,%eax
ffffffff80102415:	89 c2                	mov    %eax,%edx
ffffffff80102417:	8b 45 d0             	mov    -0x30(%rbp),%eax
ffffffff8010241a:	39 c2                	cmp    %eax,%edx
ffffffff8010241c:	0f 82 38 ff ff ff    	jb     ffffffff8010235a <balloc+0x6a>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
ffffffff80102422:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102426:	48 89 c7             	mov    %rax,%rdi
ffffffff80102429:	e8 2d df ff ff       	callq  ffffffff8010035b <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
ffffffff8010242e:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%rbp)
ffffffff80102435:	8b 55 d0             	mov    -0x30(%rbp),%edx
ffffffff80102438:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010243b:	39 c2                	cmp    %eax,%edx
ffffffff8010243d:	0f 87 dd fe ff ff    	ja     ffffffff80102320 <balloc+0x30>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
ffffffff80102443:	48 c7 c7 a7 a7 10 80 	mov    $0xffffffff8010a7a7,%rdi
ffffffff8010244a:	e8 b0 e4 ff ff       	callq  ffffffff801008ff <panic>
}
ffffffff8010244f:	c9                   	leaveq 
ffffffff80102450:	c3                   	retq   

ffffffff80102451 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
ffffffff80102451:	55                   	push   %rbp
ffffffff80102452:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102455:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80102459:	89 7d dc             	mov    %edi,-0x24(%rbp)
ffffffff8010245c:	89 75 d8             	mov    %esi,-0x28(%rbp)
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
ffffffff8010245f:	48 8d 55 e0          	lea    -0x20(%rbp),%rdx
ffffffff80102463:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80102466:	48 89 d6             	mov    %rdx,%rsi
ffffffff80102469:	89 c7                	mov    %eax,%edi
ffffffff8010246b:	e8 dd fd ff ff       	callq  ffffffff8010224d <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
ffffffff80102470:	8b 45 d8             	mov    -0x28(%rbp),%eax
ffffffff80102473:	c1 e8 0c             	shr    $0xc,%eax
ffffffff80102476:	89 c2                	mov    %eax,%edx
ffffffff80102478:	8b 45 e8             	mov    -0x18(%rbp),%eax
ffffffff8010247b:	c1 e8 03             	shr    $0x3,%eax
ffffffff8010247e:	01 d0                	add    %edx,%eax
ffffffff80102480:	8d 50 03             	lea    0x3(%rax),%edx
ffffffff80102483:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80102486:	89 d6                	mov    %edx,%esi
ffffffff80102488:	89 c7                	mov    %eax,%edi
ffffffff8010248a:	e8 47 de ff ff       	callq  ffffffff801002d6 <bread>
ffffffff8010248f:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  bi = b % BPB;
ffffffff80102493:	8b 45 d8             	mov    -0x28(%rbp),%eax
ffffffff80102496:	25 ff 0f 00 00       	and    $0xfff,%eax
ffffffff8010249b:	89 45 f4             	mov    %eax,-0xc(%rbp)
  m = 1 << (bi % 8);
ffffffff8010249e:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff801024a1:	99                   	cltd   
ffffffff801024a2:	c1 ea 1d             	shr    $0x1d,%edx
ffffffff801024a5:	01 d0                	add    %edx,%eax
ffffffff801024a7:	83 e0 07             	and    $0x7,%eax
ffffffff801024aa:	29 d0                	sub    %edx,%eax
ffffffff801024ac:	ba 01 00 00 00       	mov    $0x1,%edx
ffffffff801024b1:	89 c1                	mov    %eax,%ecx
ffffffff801024b3:	d3 e2                	shl    %cl,%edx
ffffffff801024b5:	89 d0                	mov    %edx,%eax
ffffffff801024b7:	89 45 f0             	mov    %eax,-0x10(%rbp)
  if((bp->data[bi/8] & m) == 0)
ffffffff801024ba:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff801024bd:	8d 50 07             	lea    0x7(%rax),%edx
ffffffff801024c0:	85 c0                	test   %eax,%eax
ffffffff801024c2:	0f 48 c2             	cmovs  %edx,%eax
ffffffff801024c5:	c1 f8 03             	sar    $0x3,%eax
ffffffff801024c8:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff801024cc:	48 98                	cltq   
ffffffff801024ce:	0f b6 44 02 28       	movzbl 0x28(%rdx,%rax,1),%eax
ffffffff801024d3:	0f b6 c0             	movzbl %al,%eax
ffffffff801024d6:	23 45 f0             	and    -0x10(%rbp),%eax
ffffffff801024d9:	85 c0                	test   %eax,%eax
ffffffff801024db:	75 0c                	jne    ffffffff801024e9 <bfree+0x98>
    panic("freeing free block");
ffffffff801024dd:	48 c7 c7 bd a7 10 80 	mov    $0xffffffff8010a7bd,%rdi
ffffffff801024e4:	e8 16 e4 ff ff       	callq  ffffffff801008ff <panic>
  bp->data[bi/8] &= ~m;
ffffffff801024e9:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff801024ec:	8d 50 07             	lea    0x7(%rax),%edx
ffffffff801024ef:	85 c0                	test   %eax,%eax
ffffffff801024f1:	0f 48 c2             	cmovs  %edx,%eax
ffffffff801024f4:	c1 f8 03             	sar    $0x3,%eax
ffffffff801024f7:	89 c1                	mov    %eax,%ecx
ffffffff801024f9:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff801024fd:	48 63 c1             	movslq %ecx,%rax
ffffffff80102500:	0f b6 44 02 28       	movzbl 0x28(%rdx,%rax,1),%eax
ffffffff80102505:	89 c2                	mov    %eax,%edx
ffffffff80102507:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff8010250a:	f7 d0                	not    %eax
ffffffff8010250c:	21 d0                	and    %edx,%eax
ffffffff8010250e:	89 c6                	mov    %eax,%esi
ffffffff80102510:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80102514:	48 63 c1             	movslq %ecx,%rax
ffffffff80102517:	40 88 74 02 28       	mov    %sil,0x28(%rdx,%rax,1)
  log_write(bp);
ffffffff8010251c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102520:	48 89 c7             	mov    %rax,%rdi
ffffffff80102523:	e8 ef 1f 00 00       	callq  ffffffff80104517 <log_write>
  brelse(bp);
ffffffff80102528:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010252c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010252f:	e8 27 de ff ff       	callq  ffffffff8010035b <brelse>
}
ffffffff80102534:	90                   	nop
ffffffff80102535:	c9                   	leaveq 
ffffffff80102536:	c3                   	retq   

ffffffff80102537 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
ffffffff80102537:	55                   	push   %rbp
ffffffff80102538:	48 89 e5             	mov    %rsp,%rbp
  initlock(&icache.lock, "icache");
ffffffff8010253b:	48 c7 c6 d0 a7 10 80 	mov    $0xffffffff8010a7d0,%rsi
ffffffff80102542:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff80102549:	e8 1b 43 00 00       	callq  ffffffff80106869 <initlock>
}
ffffffff8010254e:	90                   	nop
ffffffff8010254f:	5d                   	pop    %rbp
ffffffff80102550:	c3                   	retq   

ffffffff80102551 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
ffffffff80102551:	55                   	push   %rbp
ffffffff80102552:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102555:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff80102559:	89 7d cc             	mov    %edi,-0x34(%rbp)
ffffffff8010255c:	89 f0                	mov    %esi,%eax
ffffffff8010255e:	66 89 45 c8          	mov    %ax,-0x38(%rbp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
ffffffff80102562:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff80102565:	48 8d 55 d0          	lea    -0x30(%rbp),%rdx
ffffffff80102569:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010256c:	89 c7                	mov    %eax,%edi
ffffffff8010256e:	e8 da fc ff ff       	callq  ffffffff8010224d <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
ffffffff80102573:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)
ffffffff8010257a:	e9 9d 00 00 00       	jmpq   ffffffff8010261c <ialloc+0xcb>
    bp = bread(dev, IBLOCK(inum));
ffffffff8010257f:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80102582:	48 98                	cltq   
ffffffff80102584:	48 c1 e8 03          	shr    $0x3,%rax
ffffffff80102588:	8d 50 02             	lea    0x2(%rax),%edx
ffffffff8010258b:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff8010258e:	89 d6                	mov    %edx,%esi
ffffffff80102590:	89 c7                	mov    %eax,%edi
ffffffff80102592:	e8 3f dd ff ff       	callq  ffffffff801002d6 <bread>
ffffffff80102597:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    dip = (struct dinode*)bp->data + inum%IPB;
ffffffff8010259b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010259f:	48 8d 50 28          	lea    0x28(%rax),%rdx
ffffffff801025a3:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801025a6:	48 98                	cltq   
ffffffff801025a8:	83 e0 07             	and    $0x7,%eax
ffffffff801025ab:	48 c1 e0 06          	shl    $0x6,%rax
ffffffff801025af:	48 01 d0             	add    %rdx,%rax
ffffffff801025b2:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    if(dip->type == 0){  // a free inode
ffffffff801025b6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801025ba:	0f b7 00             	movzwl (%rax),%eax
ffffffff801025bd:	66 85 c0             	test   %ax,%ax
ffffffff801025c0:	75 4a                	jne    ffffffff8010260c <ialloc+0xbb>
      memset(dip, 0, sizeof(*dip));
ffffffff801025c2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801025c6:	ba 40 00 00 00       	mov    $0x40,%edx
ffffffff801025cb:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801025d0:	48 89 c7             	mov    %rax,%rdi
ffffffff801025d3:	e8 35 46 00 00       	callq  ffffffff80106c0d <memset>
      dip->type = type;
ffffffff801025d8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801025dc:	0f b7 55 c8          	movzwl -0x38(%rbp),%edx
ffffffff801025e0:	66 89 10             	mov    %dx,(%rax)
      log_write(bp);   // mark it allocated on the disk
ffffffff801025e3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801025e7:	48 89 c7             	mov    %rax,%rdi
ffffffff801025ea:	e8 28 1f 00 00       	callq  ffffffff80104517 <log_write>
      brelse(bp);
ffffffff801025ef:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801025f3:	48 89 c7             	mov    %rax,%rdi
ffffffff801025f6:	e8 60 dd ff ff       	callq  ffffffff8010035b <brelse>
      return iget(dev, inum);
ffffffff801025fb:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801025fe:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff80102601:	89 d6                	mov    %edx,%esi
ffffffff80102603:	89 c7                	mov    %eax,%edi
ffffffff80102605:	e8 0f 01 00 00       	callq  ffffffff80102719 <iget>
ffffffff8010260a:	eb 2a                	jmp    ffffffff80102636 <ialloc+0xe5>
    }
    brelse(bp);
ffffffff8010260c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102610:	48 89 c7             	mov    %rax,%rdi
ffffffff80102613:	e8 43 dd ff ff       	callq  ffffffff8010035b <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
ffffffff80102618:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff8010261c:	8b 55 d8             	mov    -0x28(%rbp),%edx
ffffffff8010261f:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80102622:	39 c2                	cmp    %eax,%edx
ffffffff80102624:	0f 87 55 ff ff ff    	ja     ffffffff8010257f <ialloc+0x2e>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
ffffffff8010262a:	48 c7 c7 d7 a7 10 80 	mov    $0xffffffff8010a7d7,%rdi
ffffffff80102631:	e8 c9 e2 ff ff       	callq  ffffffff801008ff <panic>
}
ffffffff80102636:	c9                   	leaveq 
ffffffff80102637:	c3                   	retq   

ffffffff80102638 <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
ffffffff80102638:	55                   	push   %rbp
ffffffff80102639:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010263c:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80102640:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
ffffffff80102644:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102648:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff8010264b:	c1 e8 03             	shr    $0x3,%eax
ffffffff8010264e:	8d 50 02             	lea    0x2(%rax),%edx
ffffffff80102651:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102655:	8b 00                	mov    (%rax),%eax
ffffffff80102657:	89 d6                	mov    %edx,%esi
ffffffff80102659:	89 c7                	mov    %eax,%edi
ffffffff8010265b:	e8 76 dc ff ff       	callq  ffffffff801002d6 <bread>
ffffffff80102660:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
ffffffff80102664:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102668:	48 8d 50 28          	lea    0x28(%rax),%rdx
ffffffff8010266c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102670:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80102673:	89 c0                	mov    %eax,%eax
ffffffff80102675:	83 e0 07             	and    $0x7,%eax
ffffffff80102678:	48 c1 e0 06          	shl    $0x6,%rax
ffffffff8010267c:	48 01 d0             	add    %rdx,%rax
ffffffff8010267f:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  dip->type = ip->type;
ffffffff80102683:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102687:	0f b7 50 10          	movzwl 0x10(%rax),%edx
ffffffff8010268b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010268f:	66 89 10             	mov    %dx,(%rax)
  dip->major = ip->major;
ffffffff80102692:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102696:	0f b7 50 12          	movzwl 0x12(%rax),%edx
ffffffff8010269a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010269e:	66 89 50 02          	mov    %dx,0x2(%rax)
  dip->minor = ip->minor;
ffffffff801026a2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801026a6:	0f b7 50 14          	movzwl 0x14(%rax),%edx
ffffffff801026aa:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801026ae:	66 89 50 04          	mov    %dx,0x4(%rax)
  dip->nlink = ip->nlink;
ffffffff801026b2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801026b6:	0f b7 50 16          	movzwl 0x16(%rax),%edx
ffffffff801026ba:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801026be:	66 89 50 06          	mov    %dx,0x6(%rax)
  dip->size = ip->size;
ffffffff801026c2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801026c6:	8b 50 20             	mov    0x20(%rax),%edx
ffffffff801026c9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801026cd:	89 50 10             	mov    %edx,0x10(%rax)
  dip->mode = ip->mode;
ffffffff801026d0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801026d4:	8b 50 1c             	mov    0x1c(%rax),%edx
ffffffff801026d7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801026db:	89 50 0c             	mov    %edx,0xc(%rax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
ffffffff801026de:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801026e2:	48 8d 48 24          	lea    0x24(%rax),%rcx
ffffffff801026e6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801026ea:	48 83 c0 14          	add    $0x14,%rax
ffffffff801026ee:	ba 2c 00 00 00       	mov    $0x2c,%edx
ffffffff801026f3:	48 89 ce             	mov    %rcx,%rsi
ffffffff801026f6:	48 89 c7             	mov    %rax,%rdi
ffffffff801026f9:	e8 fe 45 00 00       	callq  ffffffff80106cfc <memmove>
  log_write(bp);
ffffffff801026fe:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102702:	48 89 c7             	mov    %rax,%rdi
ffffffff80102705:	e8 0d 1e 00 00       	callq  ffffffff80104517 <log_write>
  brelse(bp);
ffffffff8010270a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010270e:	48 89 c7             	mov    %rax,%rdi
ffffffff80102711:	e8 45 dc ff ff       	callq  ffffffff8010035b <brelse>
}
ffffffff80102716:	90                   	nop
ffffffff80102717:	c9                   	leaveq 
ffffffff80102718:	c3                   	retq   

ffffffff80102719 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
ffffffff80102719:	55                   	push   %rbp
ffffffff8010271a:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010271d:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80102721:	89 7d ec             	mov    %edi,-0x14(%rbp)
ffffffff80102724:	89 75 e8             	mov    %esi,-0x18(%rbp)
  struct inode *ip, *empty;

  acquire(&icache.lock);
ffffffff80102727:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff8010272e:	e8 6b 41 00 00       	callq  ffffffff8010689e <acquire>

  // Is the inode already cached?
  empty = 0;
ffffffff80102733:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
ffffffff8010273a:	00 
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
ffffffff8010273b:	48 c7 45 f8 08 f6 18 	movq   $0xffffffff8018f608,-0x8(%rbp)
ffffffff80102742:	80 
ffffffff80102743:	eb 64                	jmp    ffffffff801027a9 <iget+0x90>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
ffffffff80102745:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102749:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff8010274c:	85 c0                	test   %eax,%eax
ffffffff8010274e:	7e 3a                	jle    ffffffff8010278a <iget+0x71>
ffffffff80102750:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102754:	8b 00                	mov    (%rax),%eax
ffffffff80102756:	3b 45 ec             	cmp    -0x14(%rbp),%eax
ffffffff80102759:	75 2f                	jne    ffffffff8010278a <iget+0x71>
ffffffff8010275b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010275f:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80102762:	3b 45 e8             	cmp    -0x18(%rbp),%eax
ffffffff80102765:	75 23                	jne    ffffffff8010278a <iget+0x71>
      ip->ref++;
ffffffff80102767:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010276b:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff8010276e:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80102771:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102775:	89 50 08             	mov    %edx,0x8(%rax)
      release(&icache.lock);
ffffffff80102778:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff8010277f:	e8 f1 41 00 00       	callq  ffffffff80106975 <release>
      return ip;
ffffffff80102784:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102788:	eb 7d                	jmp    ffffffff80102807 <iget+0xee>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
ffffffff8010278a:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff8010278f:	75 13                	jne    ffffffff801027a4 <iget+0x8b>
ffffffff80102791:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102795:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff80102798:	85 c0                	test   %eax,%eax
ffffffff8010279a:	75 08                	jne    ffffffff801027a4 <iget+0x8b>
      empty = ip;
ffffffff8010279c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801027a0:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
ffffffff801027a4:	48 83 45 f8 50       	addq   $0x50,-0x8(%rbp)
ffffffff801027a9:	48 81 7d f8 a8 05 19 	cmpq   $0xffffffff801905a8,-0x8(%rbp)
ffffffff801027b0:	80 
ffffffff801027b1:	72 92                	jb     ffffffff80102745 <iget+0x2c>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
ffffffff801027b3:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff801027b8:	75 0c                	jne    ffffffff801027c6 <iget+0xad>
    panic("iget: no inodes");
ffffffff801027ba:	48 c7 c7 e9 a7 10 80 	mov    $0xffffffff8010a7e9,%rdi
ffffffff801027c1:	e8 39 e1 ff ff       	callq  ffffffff801008ff <panic>

  ip = empty;
ffffffff801027c6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801027ca:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  ip->dev = dev;
ffffffff801027ce:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801027d2:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff801027d5:	89 10                	mov    %edx,(%rax)
  ip->inum = inum;
ffffffff801027d7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801027db:	8b 55 e8             	mov    -0x18(%rbp),%edx
ffffffff801027de:	89 50 04             	mov    %edx,0x4(%rax)
  ip->ref = 1;
ffffffff801027e1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801027e5:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%rax)
  ip->flags = 0;
ffffffff801027ec:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801027f0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%rax)
  release(&icache.lock);
ffffffff801027f7:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff801027fe:	e8 72 41 00 00       	callq  ffffffff80106975 <release>

  return ip;
ffffffff80102803:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80102807:	c9                   	leaveq 
ffffffff80102808:	c3                   	retq   

ffffffff80102809 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
ffffffff80102809:	55                   	push   %rbp
ffffffff8010280a:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010280d:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80102811:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  acquire(&icache.lock);
ffffffff80102815:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff8010281c:	e8 7d 40 00 00       	callq  ffffffff8010689e <acquire>
  ip->ref++;
ffffffff80102821:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102825:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff80102828:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff8010282b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010282f:	89 50 08             	mov    %edx,0x8(%rax)
  release(&icache.lock);
ffffffff80102832:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff80102839:	e8 37 41 00 00       	callq  ffffffff80106975 <release>
  return ip;
ffffffff8010283e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80102842:	c9                   	leaveq 
ffffffff80102843:	c3                   	retq   

ffffffff80102844 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
ffffffff80102844:	55                   	push   %rbp
ffffffff80102845:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102848:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010284c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
ffffffff80102850:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff80102855:	74 0b                	je     ffffffff80102862 <ilock+0x1e>
ffffffff80102857:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010285b:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff8010285e:	85 c0                	test   %eax,%eax
ffffffff80102860:	7f 0c                	jg     ffffffff8010286e <ilock+0x2a>
    panic("ilock");
ffffffff80102862:	48 c7 c7 f9 a7 10 80 	mov    $0xffffffff8010a7f9,%rdi
ffffffff80102869:	e8 91 e0 ff ff       	callq  ffffffff801008ff <panic>

  acquire(&icache.lock);
ffffffff8010286e:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff80102875:	e8 24 40 00 00       	callq  ffffffff8010689e <acquire>
  while(ip->flags & I_BUSY)
ffffffff8010287a:	eb 13                	jmp    ffffffff8010288f <ilock+0x4b>
    sleep(ip, &icache.lock);
ffffffff8010287c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102880:	48 c7 c6 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rsi
ffffffff80102887:	48 89 c7             	mov    %rax,%rdi
ffffffff8010288a:	e8 92 3c 00 00       	callq  ffffffff80106521 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
ffffffff8010288f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102893:	8b 40 0c             	mov    0xc(%rax),%eax
ffffffff80102896:	83 e0 01             	and    $0x1,%eax
ffffffff80102899:	85 c0                	test   %eax,%eax
ffffffff8010289b:	75 df                	jne    ffffffff8010287c <ilock+0x38>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
ffffffff8010289d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801028a1:	8b 40 0c             	mov    0xc(%rax),%eax
ffffffff801028a4:	83 c8 01             	or     $0x1,%eax
ffffffff801028a7:	89 c2                	mov    %eax,%edx
ffffffff801028a9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801028ad:	89 50 0c             	mov    %edx,0xc(%rax)
  release(&icache.lock);
ffffffff801028b0:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff801028b7:	e8 b9 40 00 00       	callq  ffffffff80106975 <release>

  if(!(ip->flags & I_VALID)){
ffffffff801028bc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801028c0:	8b 40 0c             	mov    0xc(%rax),%eax
ffffffff801028c3:	83 e0 02             	and    $0x2,%eax
ffffffff801028c6:	85 c0                	test   %eax,%eax
ffffffff801028c8:	0f 85 12 01 00 00    	jne    ffffffff801029e0 <ilock+0x19c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
ffffffff801028ce:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801028d2:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff801028d5:	c1 e8 03             	shr    $0x3,%eax
ffffffff801028d8:	8d 50 02             	lea    0x2(%rax),%edx
ffffffff801028db:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801028df:	8b 00                	mov    (%rax),%eax
ffffffff801028e1:	89 d6                	mov    %edx,%esi
ffffffff801028e3:	89 c7                	mov    %eax,%edi
ffffffff801028e5:	e8 ec d9 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff801028ea:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
ffffffff801028ee:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801028f2:	48 8d 50 28          	lea    0x28(%rax),%rdx
ffffffff801028f6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801028fa:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff801028fd:	89 c0                	mov    %eax,%eax
ffffffff801028ff:	83 e0 07             	and    $0x7,%eax
ffffffff80102902:	48 c1 e0 06          	shl    $0x6,%rax
ffffffff80102906:	48 01 d0             	add    %rdx,%rax
ffffffff80102909:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    ip->type = dip->type;
ffffffff8010290d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102911:	0f b7 10             	movzwl (%rax),%edx
ffffffff80102914:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102918:	66 89 50 10          	mov    %dx,0x10(%rax)
    ip->major = dip->major;
ffffffff8010291c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102920:	0f b7 50 02          	movzwl 0x2(%rax),%edx
ffffffff80102924:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102928:	66 89 50 12          	mov    %dx,0x12(%rax)
    ip->minor = dip->minor;
ffffffff8010292c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102930:	0f b7 50 04          	movzwl 0x4(%rax),%edx
ffffffff80102934:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102938:	66 89 50 14          	mov    %dx,0x14(%rax)
    ip->nlink = dip->nlink;
ffffffff8010293c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102940:	0f b7 50 06          	movzwl 0x6(%rax),%edx
ffffffff80102944:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102948:	66 89 50 16          	mov    %dx,0x16(%rax)
    ip->size = dip->size;
ffffffff8010294c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102950:	8b 50 10             	mov    0x10(%rax),%edx
ffffffff80102953:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102957:	89 50 20             	mov    %edx,0x20(%rax)
    ip->ownerid = dip->ownerid;
ffffffff8010295a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010295e:	0f b7 50 08          	movzwl 0x8(%rax),%edx
ffffffff80102962:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102966:	66 89 50 18          	mov    %dx,0x18(%rax)
    ip->groupid = dip->groupid;
ffffffff8010296a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010296e:	0f b7 50 0a          	movzwl 0xa(%rax),%edx
ffffffff80102972:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102976:	66 89 50 1a          	mov    %dx,0x1a(%rax)
    ip->mode = dip->mode;
ffffffff8010297a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010297e:	8b 50 0c             	mov    0xc(%rax),%edx
ffffffff80102981:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102985:	89 50 1c             	mov    %edx,0x1c(%rax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
ffffffff80102988:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010298c:	48 8d 48 14          	lea    0x14(%rax),%rcx
ffffffff80102990:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102994:	48 83 c0 24          	add    $0x24,%rax
ffffffff80102998:	ba 2c 00 00 00       	mov    $0x2c,%edx
ffffffff8010299d:	48 89 ce             	mov    %rcx,%rsi
ffffffff801029a0:	48 89 c7             	mov    %rax,%rdi
ffffffff801029a3:	e8 54 43 00 00       	callq  ffffffff80106cfc <memmove>
    brelse(bp);
ffffffff801029a8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801029ac:	48 89 c7             	mov    %rax,%rdi
ffffffff801029af:	e8 a7 d9 ff ff       	callq  ffffffff8010035b <brelse>
    ip->flags |= I_VALID;
ffffffff801029b4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801029b8:	8b 40 0c             	mov    0xc(%rax),%eax
ffffffff801029bb:	83 c8 02             	or     $0x2,%eax
ffffffff801029be:	89 c2                	mov    %eax,%edx
ffffffff801029c0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801029c4:	89 50 0c             	mov    %edx,0xc(%rax)
    if(ip->type == 0)
ffffffff801029c7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801029cb:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff801029cf:	66 85 c0             	test   %ax,%ax
ffffffff801029d2:	75 0c                	jne    ffffffff801029e0 <ilock+0x19c>
      panic("ilock: no type");
ffffffff801029d4:	48 c7 c7 ff a7 10 80 	mov    $0xffffffff8010a7ff,%rdi
ffffffff801029db:	e8 1f df ff ff       	callq  ffffffff801008ff <panic>
  }
}
ffffffff801029e0:	90                   	nop
ffffffff801029e1:	c9                   	leaveq 
ffffffff801029e2:	c3                   	retq   

ffffffff801029e3 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
ffffffff801029e3:	55                   	push   %rbp
ffffffff801029e4:	48 89 e5             	mov    %rsp,%rbp
ffffffff801029e7:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff801029eb:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
ffffffff801029ef:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff801029f4:	74 19                	je     ffffffff80102a0f <iunlock+0x2c>
ffffffff801029f6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801029fa:	8b 40 0c             	mov    0xc(%rax),%eax
ffffffff801029fd:	83 e0 01             	and    $0x1,%eax
ffffffff80102a00:	85 c0                	test   %eax,%eax
ffffffff80102a02:	74 0b                	je     ffffffff80102a0f <iunlock+0x2c>
ffffffff80102a04:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102a08:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff80102a0b:	85 c0                	test   %eax,%eax
ffffffff80102a0d:	7f 0c                	jg     ffffffff80102a1b <iunlock+0x38>
    panic("iunlock");
ffffffff80102a0f:	48 c7 c7 0e a8 10 80 	mov    $0xffffffff8010a80e,%rdi
ffffffff80102a16:	e8 e4 de ff ff       	callq  ffffffff801008ff <panic>

  acquire(&icache.lock);
ffffffff80102a1b:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff80102a22:	e8 77 3e 00 00       	callq  ffffffff8010689e <acquire>
  ip->flags &= ~I_BUSY;
ffffffff80102a27:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102a2b:	8b 40 0c             	mov    0xc(%rax),%eax
ffffffff80102a2e:	83 e0 fe             	and    $0xfffffffe,%eax
ffffffff80102a31:	89 c2                	mov    %eax,%edx
ffffffff80102a33:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102a37:	89 50 0c             	mov    %edx,0xc(%rax)
  wakeup(ip);
ffffffff80102a3a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102a3e:	48 89 c7             	mov    %rax,%rdi
ffffffff80102a41:	e8 ee 3b 00 00       	callq  ffffffff80106634 <wakeup>
  release(&icache.lock);
ffffffff80102a46:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff80102a4d:	e8 23 3f 00 00       	callq  ffffffff80106975 <release>
}
ffffffff80102a52:	90                   	nop
ffffffff80102a53:	c9                   	leaveq 
ffffffff80102a54:	c3                   	retq   

ffffffff80102a55 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
ffffffff80102a55:	55                   	push   %rbp
ffffffff80102a56:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102a59:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80102a5d:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  acquire(&icache.lock);
ffffffff80102a61:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff80102a68:	e8 31 3e 00 00       	callq  ffffffff8010689e <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
ffffffff80102a6d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102a71:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff80102a74:	83 f8 01             	cmp    $0x1,%eax
ffffffff80102a77:	0f 85 9d 00 00 00    	jne    ffffffff80102b1a <iput+0xc5>
ffffffff80102a7d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102a81:	8b 40 0c             	mov    0xc(%rax),%eax
ffffffff80102a84:	83 e0 02             	and    $0x2,%eax
ffffffff80102a87:	85 c0                	test   %eax,%eax
ffffffff80102a89:	0f 84 8b 00 00 00    	je     ffffffff80102b1a <iput+0xc5>
ffffffff80102a8f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102a93:	0f b7 40 16          	movzwl 0x16(%rax),%eax
ffffffff80102a97:	66 85 c0             	test   %ax,%ax
ffffffff80102a9a:	75 7e                	jne    ffffffff80102b1a <iput+0xc5>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
ffffffff80102a9c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102aa0:	8b 40 0c             	mov    0xc(%rax),%eax
ffffffff80102aa3:	83 e0 01             	and    $0x1,%eax
ffffffff80102aa6:	85 c0                	test   %eax,%eax
ffffffff80102aa8:	74 0c                	je     ffffffff80102ab6 <iput+0x61>
      panic("iput busy");
ffffffff80102aaa:	48 c7 c7 16 a8 10 80 	mov    $0xffffffff8010a816,%rdi
ffffffff80102ab1:	e8 49 de ff ff       	callq  ffffffff801008ff <panic>
    ip->flags |= I_BUSY;
ffffffff80102ab6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102aba:	8b 40 0c             	mov    0xc(%rax),%eax
ffffffff80102abd:	83 c8 01             	or     $0x1,%eax
ffffffff80102ac0:	89 c2                	mov    %eax,%edx
ffffffff80102ac2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102ac6:	89 50 0c             	mov    %edx,0xc(%rax)
    release(&icache.lock);
ffffffff80102ac9:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff80102ad0:	e8 a0 3e 00 00       	callq  ffffffff80106975 <release>
    itrunc(ip);
ffffffff80102ad5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102ad9:	48 89 c7             	mov    %rax,%rdi
ffffffff80102adc:	e8 a7 01 00 00       	callq  ffffffff80102c88 <itrunc>
    ip->type = 0;
ffffffff80102ae1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102ae5:	66 c7 40 10 00 00    	movw   $0x0,0x10(%rax)
    iupdate(ip);
ffffffff80102aeb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102aef:	48 89 c7             	mov    %rax,%rdi
ffffffff80102af2:	e8 41 fb ff ff       	callq  ffffffff80102638 <iupdate>
    acquire(&icache.lock);
ffffffff80102af7:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff80102afe:	e8 9b 3d 00 00       	callq  ffffffff8010689e <acquire>
    ip->flags = 0;
ffffffff80102b03:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102b07:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%rax)
    wakeup(ip);
ffffffff80102b0e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102b12:	48 89 c7             	mov    %rax,%rdi
ffffffff80102b15:	e8 1a 3b 00 00       	callq  ffffffff80106634 <wakeup>
  }
  ip->ref--;
ffffffff80102b1a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102b1e:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff80102b21:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80102b24:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102b28:	89 50 08             	mov    %edx,0x8(%rax)
  release(&icache.lock);
ffffffff80102b2b:	48 c7 c7 a0 f5 18 80 	mov    $0xffffffff8018f5a0,%rdi
ffffffff80102b32:	e8 3e 3e 00 00       	callq  ffffffff80106975 <release>
}
ffffffff80102b37:	90                   	nop
ffffffff80102b38:	c9                   	leaveq 
ffffffff80102b39:	c3                   	retq   

ffffffff80102b3a <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
ffffffff80102b3a:	55                   	push   %rbp
ffffffff80102b3b:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102b3e:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80102b42:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  iunlock(ip);
ffffffff80102b46:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102b4a:	48 89 c7             	mov    %rax,%rdi
ffffffff80102b4d:	e8 91 fe ff ff       	callq  ffffffff801029e3 <iunlock>
  iput(ip);
ffffffff80102b52:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102b56:	48 89 c7             	mov    %rax,%rdi
ffffffff80102b59:	e8 f7 fe ff ff       	callq  ffffffff80102a55 <iput>
}
ffffffff80102b5e:	90                   	nop
ffffffff80102b5f:	c9                   	leaveq 
ffffffff80102b60:	c3                   	retq   

ffffffff80102b61 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
ffffffff80102b61:	55                   	push   %rbp
ffffffff80102b62:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102b65:	53                   	push   %rbx
ffffffff80102b66:	48 83 ec 38          	sub    $0x38,%rsp
ffffffff80102b6a:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
ffffffff80102b6e:	89 75 c4             	mov    %esi,-0x3c(%rbp)
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
ffffffff80102b71:	83 7d c4 09          	cmpl   $0x9,-0x3c(%rbp)
ffffffff80102b75:	77 42                	ja     ffffffff80102bb9 <bmap+0x58>
    if((addr = ip->addrs[bn]) == 0)
ffffffff80102b77:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80102b7b:	8b 55 c4             	mov    -0x3c(%rbp),%edx
ffffffff80102b7e:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80102b82:	8b 44 90 04          	mov    0x4(%rax,%rdx,4),%eax
ffffffff80102b86:	89 45 ec             	mov    %eax,-0x14(%rbp)
ffffffff80102b89:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80102b8d:	75 22                	jne    ffffffff80102bb1 <bmap+0x50>
      ip->addrs[bn] = addr = balloc(ip->dev);
ffffffff80102b8f:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80102b93:	8b 00                	mov    (%rax),%eax
ffffffff80102b95:	89 c7                	mov    %eax,%edi
ffffffff80102b97:	e8 54 f7 ff ff       	callq  ffffffff801022f0 <balloc>
ffffffff80102b9c:	89 45 ec             	mov    %eax,-0x14(%rbp)
ffffffff80102b9f:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80102ba3:	8b 55 c4             	mov    -0x3c(%rbp),%edx
ffffffff80102ba6:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
ffffffff80102baa:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80102bad:	89 54 88 04          	mov    %edx,0x4(%rax,%rcx,4)
    return addr;
ffffffff80102bb1:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80102bb4:	e9 c8 00 00 00       	jmpq   ffffffff80102c81 <bmap+0x120>
  }
  bn -= NDIRECT;
ffffffff80102bb9:	83 6d c4 0a          	subl   $0xa,-0x3c(%rbp)

  if(bn < NINDIRECT){
ffffffff80102bbd:	83 7d c4 7f          	cmpl   $0x7f,-0x3c(%rbp)
ffffffff80102bc1:	0f 87 ae 00 00 00    	ja     ffffffff80102c75 <bmap+0x114>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
ffffffff80102bc7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80102bcb:	8b 40 4c             	mov    0x4c(%rax),%eax
ffffffff80102bce:	89 45 ec             	mov    %eax,-0x14(%rbp)
ffffffff80102bd1:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80102bd5:	75 1a                	jne    ffffffff80102bf1 <bmap+0x90>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
ffffffff80102bd7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80102bdb:	8b 00                	mov    (%rax),%eax
ffffffff80102bdd:	89 c7                	mov    %eax,%edi
ffffffff80102bdf:	e8 0c f7 ff ff       	callq  ffffffff801022f0 <balloc>
ffffffff80102be4:	89 45 ec             	mov    %eax,-0x14(%rbp)
ffffffff80102be7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80102beb:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80102bee:	89 50 4c             	mov    %edx,0x4c(%rax)
    bp = bread(ip->dev, addr);
ffffffff80102bf1:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80102bf5:	8b 00                	mov    (%rax),%eax
ffffffff80102bf7:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80102bfa:	89 d6                	mov    %edx,%esi
ffffffff80102bfc:	89 c7                	mov    %eax,%edi
ffffffff80102bfe:	e8 d3 d6 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff80102c03:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
    a = (uint*)bp->data;
ffffffff80102c07:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80102c0b:	48 83 c0 28          	add    $0x28,%rax
ffffffff80102c0f:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
    if((addr = a[bn]) == 0){
ffffffff80102c13:	8b 45 c4             	mov    -0x3c(%rbp),%eax
ffffffff80102c16:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80102c1d:	00 
ffffffff80102c1e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102c22:	48 01 d0             	add    %rdx,%rax
ffffffff80102c25:	8b 00                	mov    (%rax),%eax
ffffffff80102c27:	89 45 ec             	mov    %eax,-0x14(%rbp)
ffffffff80102c2a:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80102c2e:	75 34                	jne    ffffffff80102c64 <bmap+0x103>
      a[bn] = addr = balloc(ip->dev);
ffffffff80102c30:	8b 45 c4             	mov    -0x3c(%rbp),%eax
ffffffff80102c33:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80102c3a:	00 
ffffffff80102c3b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102c3f:	48 8d 1c 02          	lea    (%rdx,%rax,1),%rbx
ffffffff80102c43:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80102c47:	8b 00                	mov    (%rax),%eax
ffffffff80102c49:	89 c7                	mov    %eax,%edi
ffffffff80102c4b:	e8 a0 f6 ff ff       	callq  ffffffff801022f0 <balloc>
ffffffff80102c50:	89 45 ec             	mov    %eax,-0x14(%rbp)
ffffffff80102c53:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80102c56:	89 03                	mov    %eax,(%rbx)
      log_write(bp);
ffffffff80102c58:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80102c5c:	48 89 c7             	mov    %rax,%rdi
ffffffff80102c5f:	e8 b3 18 00 00       	callq  ffffffff80104517 <log_write>
    }
    brelse(bp);
ffffffff80102c64:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80102c68:	48 89 c7             	mov    %rax,%rdi
ffffffff80102c6b:	e8 eb d6 ff ff       	callq  ffffffff8010035b <brelse>
    return addr;
ffffffff80102c70:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80102c73:	eb 0c                	jmp    ffffffff80102c81 <bmap+0x120>
  }

  panic("bmap: out of range");
ffffffff80102c75:	48 c7 c7 20 a8 10 80 	mov    $0xffffffff8010a820,%rdi
ffffffff80102c7c:	e8 7e dc ff ff       	callq  ffffffff801008ff <panic>
}
ffffffff80102c81:	48 83 c4 38          	add    $0x38,%rsp
ffffffff80102c85:	5b                   	pop    %rbx
ffffffff80102c86:	5d                   	pop    %rbp
ffffffff80102c87:	c3                   	retq   

ffffffff80102c88 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
ffffffff80102c88:	55                   	push   %rbp
ffffffff80102c89:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102c8c:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80102c90:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
ffffffff80102c94:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80102c9b:	eb 51                	jmp    ffffffff80102cee <itrunc+0x66>
    if(ip->addrs[i]){
ffffffff80102c9d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102ca1:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80102ca4:	48 63 d2             	movslq %edx,%rdx
ffffffff80102ca7:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80102cab:	8b 44 90 04          	mov    0x4(%rax,%rdx,4),%eax
ffffffff80102caf:	85 c0                	test   %eax,%eax
ffffffff80102cb1:	74 37                	je     ffffffff80102cea <itrunc+0x62>
      bfree(ip->dev, ip->addrs[i]);
ffffffff80102cb3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102cb7:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80102cba:	48 63 d2             	movslq %edx,%rdx
ffffffff80102cbd:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80102cc1:	8b 44 90 04          	mov    0x4(%rax,%rdx,4),%eax
ffffffff80102cc5:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff80102cc9:	8b 12                	mov    (%rdx),%edx
ffffffff80102ccb:	89 c6                	mov    %eax,%esi
ffffffff80102ccd:	89 d7                	mov    %edx,%edi
ffffffff80102ccf:	e8 7d f7 ff ff       	callq  ffffffff80102451 <bfree>
      ip->addrs[i] = 0;
ffffffff80102cd4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102cd8:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80102cdb:	48 63 d2             	movslq %edx,%rdx
ffffffff80102cde:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80102ce2:	c7 44 90 04 00 00 00 	movl   $0x0,0x4(%rax,%rdx,4)
ffffffff80102ce9:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
ffffffff80102cea:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80102cee:	83 7d fc 09          	cmpl   $0x9,-0x4(%rbp)
ffffffff80102cf2:	7e a9                	jle    ffffffff80102c9d <itrunc+0x15>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
ffffffff80102cf4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102cf8:	8b 40 4c             	mov    0x4c(%rax),%eax
ffffffff80102cfb:	85 c0                	test   %eax,%eax
ffffffff80102cfd:	0f 84 a7 00 00 00    	je     ffffffff80102daa <itrunc+0x122>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
ffffffff80102d03:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102d07:	8b 50 4c             	mov    0x4c(%rax),%edx
ffffffff80102d0a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102d0e:	8b 00                	mov    (%rax),%eax
ffffffff80102d10:	89 d6                	mov    %edx,%esi
ffffffff80102d12:	89 c7                	mov    %eax,%edi
ffffffff80102d14:	e8 bd d5 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff80102d19:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    a = (uint*)bp->data;
ffffffff80102d1d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102d21:	48 83 c0 28          	add    $0x28,%rax
ffffffff80102d25:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    for(j = 0; j < NINDIRECT; j++){
ffffffff80102d29:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
ffffffff80102d30:	eb 43                	jmp    ffffffff80102d75 <itrunc+0xed>
      if(a[j])
ffffffff80102d32:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80102d35:	48 98                	cltq   
ffffffff80102d37:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80102d3e:	00 
ffffffff80102d3f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102d43:	48 01 d0             	add    %rdx,%rax
ffffffff80102d46:	8b 00                	mov    (%rax),%eax
ffffffff80102d48:	85 c0                	test   %eax,%eax
ffffffff80102d4a:	74 25                	je     ffffffff80102d71 <itrunc+0xe9>
        bfree(ip->dev, a[j]);
ffffffff80102d4c:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80102d4f:	48 98                	cltq   
ffffffff80102d51:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80102d58:	00 
ffffffff80102d59:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80102d5d:	48 01 d0             	add    %rdx,%rax
ffffffff80102d60:	8b 00                	mov    (%rax),%eax
ffffffff80102d62:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff80102d66:	8b 12                	mov    (%rdx),%edx
ffffffff80102d68:	89 c6                	mov    %eax,%esi
ffffffff80102d6a:	89 d7                	mov    %edx,%edi
ffffffff80102d6c:	e8 e0 f6 ff ff       	callq  ffffffff80102451 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
ffffffff80102d71:	83 45 f8 01          	addl   $0x1,-0x8(%rbp)
ffffffff80102d75:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80102d78:	83 f8 7f             	cmp    $0x7f,%eax
ffffffff80102d7b:	76 b5                	jbe    ffffffff80102d32 <itrunc+0xaa>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
ffffffff80102d7d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102d81:	48 89 c7             	mov    %rax,%rdi
ffffffff80102d84:	e8 d2 d5 ff ff       	callq  ffffffff8010035b <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
ffffffff80102d89:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102d8d:	8b 40 4c             	mov    0x4c(%rax),%eax
ffffffff80102d90:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff80102d94:	8b 12                	mov    (%rdx),%edx
ffffffff80102d96:	89 c6                	mov    %eax,%esi
ffffffff80102d98:	89 d7                	mov    %edx,%edi
ffffffff80102d9a:	e8 b2 f6 ff ff       	callq  ffffffff80102451 <bfree>
    ip->addrs[NDIRECT] = 0;
ffffffff80102d9f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102da3:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%rax)
  }

  ip->size = 0;
ffffffff80102daa:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102dae:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%rax)
  iupdate(ip);
ffffffff80102db5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102db9:	48 89 c7             	mov    %rax,%rdi
ffffffff80102dbc:	e8 77 f8 ff ff       	callq  ffffffff80102638 <iupdate>
}
ffffffff80102dc1:	90                   	nop
ffffffff80102dc2:	c9                   	leaveq 
ffffffff80102dc3:	c3                   	retq   

ffffffff80102dc4 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
ffffffff80102dc4:	55                   	push   %rbp
ffffffff80102dc5:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102dc8:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80102dcc:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80102dd0:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  st->dev = ip->dev;
ffffffff80102dd4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102dd8:	8b 00                	mov    (%rax),%eax
ffffffff80102dda:	89 c2                	mov    %eax,%edx
ffffffff80102ddc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102de0:	89 50 04             	mov    %edx,0x4(%rax)
  st->ino = ip->inum;
ffffffff80102de3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102de7:	8b 50 04             	mov    0x4(%rax),%edx
ffffffff80102dea:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102dee:	89 50 08             	mov    %edx,0x8(%rax)
  st->type = ip->type;
ffffffff80102df1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102df5:	0f b7 50 10          	movzwl 0x10(%rax),%edx
ffffffff80102df9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102dfd:	66 89 10             	mov    %dx,(%rax)
  st->nlink = ip->nlink;
ffffffff80102e00:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102e04:	0f b7 50 16          	movzwl 0x16(%rax),%edx
ffffffff80102e08:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102e0c:	66 89 50 0c          	mov    %dx,0xc(%rax)
  st->size = ip->size;
ffffffff80102e10:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102e14:	8b 50 20             	mov    0x20(%rax),%edx
ffffffff80102e17:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102e1b:	89 50 18             	mov    %edx,0x18(%rax)
  st->ownerid = ip->ownerid;
ffffffff80102e1e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102e22:	0f b7 50 18          	movzwl 0x18(%rax),%edx
ffffffff80102e26:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102e2a:	66 89 50 0e          	mov    %dx,0xe(%rax)
  st->groupid = ip->groupid;
ffffffff80102e2e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102e32:	0f b7 50 1a          	movzwl 0x1a(%rax),%edx
ffffffff80102e36:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102e3a:	66 89 50 10          	mov    %dx,0x10(%rax)
  st->mode = ip->mode;
ffffffff80102e3e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80102e42:	8b 50 1c             	mov    0x1c(%rax),%edx
ffffffff80102e45:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102e49:	89 50 14             	mov    %edx,0x14(%rax)
}
ffffffff80102e4c:	90                   	nop
ffffffff80102e4d:	c9                   	leaveq 
ffffffff80102e4e:	c3                   	retq   

ffffffff80102e4f <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
ffffffff80102e4f:	55                   	push   %rbp
ffffffff80102e50:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102e53:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff80102e57:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff80102e5b:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
ffffffff80102e5f:	89 55 cc             	mov    %edx,-0x34(%rbp)
ffffffff80102e62:	89 4d c8             	mov    %ecx,-0x38(%rbp)
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
ffffffff80102e65:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102e69:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff80102e6d:	66 83 f8 03          	cmp    $0x3,%ax
ffffffff80102e71:	75 6f                	jne    ffffffff80102ee2 <readi+0x93>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
ffffffff80102e73:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102e77:	0f b7 40 12          	movzwl 0x12(%rax),%eax
ffffffff80102e7b:	66 85 c0             	test   %ax,%ax
ffffffff80102e7e:	78 2b                	js     ffffffff80102eab <readi+0x5c>
ffffffff80102e80:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102e84:	0f b7 40 12          	movzwl 0x12(%rax),%eax
ffffffff80102e88:	66 83 f8 09          	cmp    $0x9,%ax
ffffffff80102e8c:	7f 1d                	jg     ffffffff80102eab <readi+0x5c>
ffffffff80102e8e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102e92:	0f b7 40 12          	movzwl 0x12(%rax),%eax
ffffffff80102e96:	98                   	cwtl   
ffffffff80102e97:	48 98                	cltq   
ffffffff80102e99:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80102e9d:	48 05 e0 e4 18 80    	add    $0xffffffff8018e4e0,%rax
ffffffff80102ea3:	48 8b 00             	mov    (%rax),%rax
ffffffff80102ea6:	48 85 c0             	test   %rax,%rax
ffffffff80102ea9:	75 0a                	jne    ffffffff80102eb5 <readi+0x66>
      return -1;
ffffffff80102eab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80102eb0:	e9 18 01 00 00       	jmpq   ffffffff80102fcd <readi+0x17e>
    return devsw[ip->major].read(ip, dst, n);
ffffffff80102eb5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102eb9:	0f b7 40 12          	movzwl 0x12(%rax),%eax
ffffffff80102ebd:	98                   	cwtl   
ffffffff80102ebe:	48 98                	cltq   
ffffffff80102ec0:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80102ec4:	48 05 e0 e4 18 80    	add    $0xffffffff8018e4e0,%rax
ffffffff80102eca:	48 8b 00             	mov    (%rax),%rax
ffffffff80102ecd:	8b 55 c8             	mov    -0x38(%rbp),%edx
ffffffff80102ed0:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
ffffffff80102ed4:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
ffffffff80102ed8:	48 89 cf             	mov    %rcx,%rdi
ffffffff80102edb:	ff d0                	callq  *%rax
ffffffff80102edd:	e9 eb 00 00 00       	jmpq   ffffffff80102fcd <readi+0x17e>
  }

  if(off > ip->size || off + n < off)
ffffffff80102ee2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102ee6:	8b 40 20             	mov    0x20(%rax),%eax
ffffffff80102ee9:	3b 45 cc             	cmp    -0x34(%rbp),%eax
ffffffff80102eec:	72 0d                	jb     ffffffff80102efb <readi+0xac>
ffffffff80102eee:	8b 55 cc             	mov    -0x34(%rbp),%edx
ffffffff80102ef1:	8b 45 c8             	mov    -0x38(%rbp),%eax
ffffffff80102ef4:	01 d0                	add    %edx,%eax
ffffffff80102ef6:	3b 45 cc             	cmp    -0x34(%rbp),%eax
ffffffff80102ef9:	73 0a                	jae    ffffffff80102f05 <readi+0xb6>
    return -1;
ffffffff80102efb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80102f00:	e9 c8 00 00 00       	jmpq   ffffffff80102fcd <readi+0x17e>
  if(off + n > ip->size)
ffffffff80102f05:	8b 55 cc             	mov    -0x34(%rbp),%edx
ffffffff80102f08:	8b 45 c8             	mov    -0x38(%rbp),%eax
ffffffff80102f0b:	01 c2                	add    %eax,%edx
ffffffff80102f0d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102f11:	8b 40 20             	mov    0x20(%rax),%eax
ffffffff80102f14:	39 c2                	cmp    %eax,%edx
ffffffff80102f16:	76 0d                	jbe    ffffffff80102f25 <readi+0xd6>
    n = ip->size - off;
ffffffff80102f18:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102f1c:	8b 40 20             	mov    0x20(%rax),%eax
ffffffff80102f1f:	2b 45 cc             	sub    -0x34(%rbp),%eax
ffffffff80102f22:	89 45 c8             	mov    %eax,-0x38(%rbp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
ffffffff80102f25:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80102f2c:	e9 8d 00 00 00       	jmpq   ffffffff80102fbe <readi+0x16f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
ffffffff80102f31:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff80102f34:	c1 e8 09             	shr    $0x9,%eax
ffffffff80102f37:	89 c2                	mov    %eax,%edx
ffffffff80102f39:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102f3d:	89 d6                	mov    %edx,%esi
ffffffff80102f3f:	48 89 c7             	mov    %rax,%rdi
ffffffff80102f42:	e8 1a fc ff ff       	callq  ffffffff80102b61 <bmap>
ffffffff80102f47:	89 c2                	mov    %eax,%edx
ffffffff80102f49:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102f4d:	8b 00                	mov    (%rax),%eax
ffffffff80102f4f:	89 d6                	mov    %edx,%esi
ffffffff80102f51:	89 c7                	mov    %eax,%edi
ffffffff80102f53:	e8 7e d3 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff80102f58:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    m = min(n - tot, BSIZE - off%BSIZE);
ffffffff80102f5c:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff80102f5f:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff80102f64:	ba 00 02 00 00       	mov    $0x200,%edx
ffffffff80102f69:	29 c2                	sub    %eax,%edx
ffffffff80102f6b:	8b 45 c8             	mov    -0x38(%rbp),%eax
ffffffff80102f6e:	2b 45 fc             	sub    -0x4(%rbp),%eax
ffffffff80102f71:	39 c2                	cmp    %eax,%edx
ffffffff80102f73:	0f 46 c2             	cmovbe %edx,%eax
ffffffff80102f76:	89 45 ec             	mov    %eax,-0x14(%rbp)
    memmove(dst, bp->data + off%BSIZE, m);
ffffffff80102f79:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102f7d:	48 8d 50 28          	lea    0x28(%rax),%rdx
ffffffff80102f81:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff80102f84:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff80102f89:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
ffffffff80102f8d:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80102f90:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80102f94:	48 89 ce             	mov    %rcx,%rsi
ffffffff80102f97:	48 89 c7             	mov    %rax,%rdi
ffffffff80102f9a:	e8 5d 3d 00 00       	callq  ffffffff80106cfc <memmove>
    brelse(bp);
ffffffff80102f9f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80102fa3:	48 89 c7             	mov    %rax,%rdi
ffffffff80102fa6:	e8 b0 d3 ff ff       	callq  ffffffff8010035b <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
ffffffff80102fab:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80102fae:	01 45 fc             	add    %eax,-0x4(%rbp)
ffffffff80102fb1:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80102fb4:	01 45 cc             	add    %eax,-0x34(%rbp)
ffffffff80102fb7:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80102fba:	48 01 45 d0          	add    %rax,-0x30(%rbp)
ffffffff80102fbe:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80102fc1:	3b 45 c8             	cmp    -0x38(%rbp),%eax
ffffffff80102fc4:	0f 82 67 ff ff ff    	jb     ffffffff80102f31 <readi+0xe2>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
ffffffff80102fca:	8b 45 c8             	mov    -0x38(%rbp),%eax
}
ffffffff80102fcd:	c9                   	leaveq 
ffffffff80102fce:	c3                   	retq   

ffffffff80102fcf <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
ffffffff80102fcf:	55                   	push   %rbp
ffffffff80102fd0:	48 89 e5             	mov    %rsp,%rbp
ffffffff80102fd3:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff80102fd7:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff80102fdb:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
ffffffff80102fdf:	89 55 cc             	mov    %edx,-0x34(%rbp)
ffffffff80102fe2:	89 4d c8             	mov    %ecx,-0x38(%rbp)
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
ffffffff80102fe5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102fe9:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff80102fed:	66 83 f8 03          	cmp    $0x3,%ax
ffffffff80102ff1:	75 6f                	jne    ffffffff80103062 <writei+0x93>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
ffffffff80102ff3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80102ff7:	0f b7 40 12          	movzwl 0x12(%rax),%eax
ffffffff80102ffb:	66 85 c0             	test   %ax,%ax
ffffffff80102ffe:	78 2b                	js     ffffffff8010302b <writei+0x5c>
ffffffff80103000:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80103004:	0f b7 40 12          	movzwl 0x12(%rax),%eax
ffffffff80103008:	66 83 f8 09          	cmp    $0x9,%ax
ffffffff8010300c:	7f 1d                	jg     ffffffff8010302b <writei+0x5c>
ffffffff8010300e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80103012:	0f b7 40 12          	movzwl 0x12(%rax),%eax
ffffffff80103016:	98                   	cwtl   
ffffffff80103017:	48 98                	cltq   
ffffffff80103019:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff8010301d:	48 05 e8 e4 18 80    	add    $0xffffffff8018e4e8,%rax
ffffffff80103023:	48 8b 00             	mov    (%rax),%rax
ffffffff80103026:	48 85 c0             	test   %rax,%rax
ffffffff80103029:	75 0a                	jne    ffffffff80103035 <writei+0x66>
      return -1;
ffffffff8010302b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80103030:	e9 45 01 00 00       	jmpq   ffffffff8010317a <writei+0x1ab>
    return devsw[ip->major].write(ip, src, n);
ffffffff80103035:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80103039:	0f b7 40 12          	movzwl 0x12(%rax),%eax
ffffffff8010303d:	98                   	cwtl   
ffffffff8010303e:	48 98                	cltq   
ffffffff80103040:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80103044:	48 05 e8 e4 18 80    	add    $0xffffffff8018e4e8,%rax
ffffffff8010304a:	48 8b 00             	mov    (%rax),%rax
ffffffff8010304d:	8b 55 c8             	mov    -0x38(%rbp),%edx
ffffffff80103050:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
ffffffff80103054:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
ffffffff80103058:	48 89 cf             	mov    %rcx,%rdi
ffffffff8010305b:	ff d0                	callq  *%rax
ffffffff8010305d:	e9 18 01 00 00       	jmpq   ffffffff8010317a <writei+0x1ab>
  }

  if(off > ip->size || off + n < off)
ffffffff80103062:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80103066:	8b 40 20             	mov    0x20(%rax),%eax
ffffffff80103069:	3b 45 cc             	cmp    -0x34(%rbp),%eax
ffffffff8010306c:	72 0d                	jb     ffffffff8010307b <writei+0xac>
ffffffff8010306e:	8b 55 cc             	mov    -0x34(%rbp),%edx
ffffffff80103071:	8b 45 c8             	mov    -0x38(%rbp),%eax
ffffffff80103074:	01 d0                	add    %edx,%eax
ffffffff80103076:	3b 45 cc             	cmp    -0x34(%rbp),%eax
ffffffff80103079:	73 0a                	jae    ffffffff80103085 <writei+0xb6>
    return -1;
ffffffff8010307b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80103080:	e9 f5 00 00 00       	jmpq   ffffffff8010317a <writei+0x1ab>
  if(off + n > MAXFILE*BSIZE)
ffffffff80103085:	8b 55 cc             	mov    -0x34(%rbp),%edx
ffffffff80103088:	8b 45 c8             	mov    -0x38(%rbp),%eax
ffffffff8010308b:	01 d0                	add    %edx,%eax
ffffffff8010308d:	3d 00 14 01 00       	cmp    $0x11400,%eax
ffffffff80103092:	76 0a                	jbe    ffffffff8010309e <writei+0xcf>
    return -1;
ffffffff80103094:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80103099:	e9 dc 00 00 00       	jmpq   ffffffff8010317a <writei+0x1ab>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
ffffffff8010309e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801030a5:	e9 99 00 00 00       	jmpq   ffffffff80103143 <writei+0x174>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
ffffffff801030aa:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff801030ad:	c1 e8 09             	shr    $0x9,%eax
ffffffff801030b0:	89 c2                	mov    %eax,%edx
ffffffff801030b2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801030b6:	89 d6                	mov    %edx,%esi
ffffffff801030b8:	48 89 c7             	mov    %rax,%rdi
ffffffff801030bb:	e8 a1 fa ff ff       	callq  ffffffff80102b61 <bmap>
ffffffff801030c0:	89 c2                	mov    %eax,%edx
ffffffff801030c2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801030c6:	8b 00                	mov    (%rax),%eax
ffffffff801030c8:	89 d6                	mov    %edx,%esi
ffffffff801030ca:	89 c7                	mov    %eax,%edi
ffffffff801030cc:	e8 05 d2 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff801030d1:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    m = min(n - tot, BSIZE - off%BSIZE);
ffffffff801030d5:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff801030d8:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff801030dd:	ba 00 02 00 00       	mov    $0x200,%edx
ffffffff801030e2:	29 c2                	sub    %eax,%edx
ffffffff801030e4:	8b 45 c8             	mov    -0x38(%rbp),%eax
ffffffff801030e7:	2b 45 fc             	sub    -0x4(%rbp),%eax
ffffffff801030ea:	39 c2                	cmp    %eax,%edx
ffffffff801030ec:	0f 46 c2             	cmovbe %edx,%eax
ffffffff801030ef:	89 45 ec             	mov    %eax,-0x14(%rbp)
    memmove(bp->data + off%BSIZE, src, m);
ffffffff801030f2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801030f6:	48 8d 50 28          	lea    0x28(%rax),%rdx
ffffffff801030fa:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff801030fd:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff80103102:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
ffffffff80103106:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80103109:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff8010310d:	48 89 c6             	mov    %rax,%rsi
ffffffff80103110:	48 89 cf             	mov    %rcx,%rdi
ffffffff80103113:	e8 e4 3b 00 00       	callq  ffffffff80106cfc <memmove>
    log_write(bp);
ffffffff80103118:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010311c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010311f:	e8 f3 13 00 00       	callq  ffffffff80104517 <log_write>
    brelse(bp);
ffffffff80103124:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80103128:	48 89 c7             	mov    %rax,%rdi
ffffffff8010312b:	e8 2b d2 ff ff       	callq  ffffffff8010035b <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
ffffffff80103130:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80103133:	01 45 fc             	add    %eax,-0x4(%rbp)
ffffffff80103136:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80103139:	01 45 cc             	add    %eax,-0x34(%rbp)
ffffffff8010313c:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff8010313f:	48 01 45 d0          	add    %rax,-0x30(%rbp)
ffffffff80103143:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103146:	3b 45 c8             	cmp    -0x38(%rbp),%eax
ffffffff80103149:	0f 82 5b ff ff ff    	jb     ffffffff801030aa <writei+0xdb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
ffffffff8010314f:	83 7d c8 00          	cmpl   $0x0,-0x38(%rbp)
ffffffff80103153:	74 22                	je     ffffffff80103177 <writei+0x1a8>
ffffffff80103155:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80103159:	8b 40 20             	mov    0x20(%rax),%eax
ffffffff8010315c:	3b 45 cc             	cmp    -0x34(%rbp),%eax
ffffffff8010315f:	73 16                	jae    ffffffff80103177 <writei+0x1a8>
    ip->size = off;
ffffffff80103161:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80103165:	8b 55 cc             	mov    -0x34(%rbp),%edx
ffffffff80103168:	89 50 20             	mov    %edx,0x20(%rax)
    iupdate(ip);
ffffffff8010316b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010316f:	48 89 c7             	mov    %rax,%rdi
ffffffff80103172:	e8 c1 f4 ff ff       	callq  ffffffff80102638 <iupdate>
  }
  return n;
ffffffff80103177:	8b 45 c8             	mov    -0x38(%rbp),%eax
}
ffffffff8010317a:	c9                   	leaveq 
ffffffff8010317b:	c3                   	retq   

ffffffff8010317c <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
ffffffff8010317c:	55                   	push   %rbp
ffffffff8010317d:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103180:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80103184:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80103188:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  return strncmp(s, t, DIRSIZ);
ffffffff8010318c:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
ffffffff80103190:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103194:	ba 0e 00 00 00       	mov    $0xe,%edx
ffffffff80103199:	48 89 ce             	mov    %rcx,%rsi
ffffffff8010319c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010319f:	e8 26 3c 00 00       	callq  ffffffff80106dca <strncmp>
}
ffffffff801031a4:	c9                   	leaveq 
ffffffff801031a5:	c3                   	retq   

ffffffff801031a6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
ffffffff801031a6:	55                   	push   %rbp
ffffffff801031a7:	48 89 e5             	mov    %rsp,%rbp
ffffffff801031aa:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff801031ae:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff801031b2:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
ffffffff801031b6:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
ffffffff801031ba:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801031be:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff801031c2:	66 83 f8 01          	cmp    $0x1,%ax
ffffffff801031c6:	74 0c                	je     ffffffff801031d4 <dirlookup+0x2e>
    panic("dirlookup not DIR");
ffffffff801031c8:	48 c7 c7 33 a8 10 80 	mov    $0xffffffff8010a833,%rdi
ffffffff801031cf:	e8 2b d7 ff ff       	callq  ffffffff801008ff <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
ffffffff801031d4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801031db:	e9 80 00 00 00       	jmpq   ffffffff80103260 <dirlookup+0xba>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
ffffffff801031e0:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801031e3:	48 8d 75 e0          	lea    -0x20(%rbp),%rsi
ffffffff801031e7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801031eb:	b9 10 00 00 00       	mov    $0x10,%ecx
ffffffff801031f0:	48 89 c7             	mov    %rax,%rdi
ffffffff801031f3:	e8 57 fc ff ff       	callq  ffffffff80102e4f <readi>
ffffffff801031f8:	83 f8 10             	cmp    $0x10,%eax
ffffffff801031fb:	74 0c                	je     ffffffff80103209 <dirlookup+0x63>
      panic("dirlink read");
ffffffff801031fd:	48 c7 c7 45 a8 10 80 	mov    $0xffffffff8010a845,%rdi
ffffffff80103204:	e8 f6 d6 ff ff       	callq  ffffffff801008ff <panic>
    if(de.inum == 0)
ffffffff80103209:	0f b7 45 e0          	movzwl -0x20(%rbp),%eax
ffffffff8010320d:	66 85 c0             	test   %ax,%ax
ffffffff80103210:	74 49                	je     ffffffff8010325b <dirlookup+0xb5>
      continue;
    if(namecmp(name, de.name) == 0){
ffffffff80103212:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
ffffffff80103216:	48 8d 50 02          	lea    0x2(%rax),%rdx
ffffffff8010321a:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff8010321e:	48 89 d6             	mov    %rdx,%rsi
ffffffff80103221:	48 89 c7             	mov    %rax,%rdi
ffffffff80103224:	e8 53 ff ff ff       	callq  ffffffff8010317c <namecmp>
ffffffff80103229:	85 c0                	test   %eax,%eax
ffffffff8010322b:	75 2f                	jne    ffffffff8010325c <dirlookup+0xb6>
      // entry matches path element
      if(poff)
ffffffff8010322d:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
ffffffff80103232:	74 09                	je     ffffffff8010323d <dirlookup+0x97>
        *poff = off;
ffffffff80103234:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80103238:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff8010323b:	89 10                	mov    %edx,(%rax)
      inum = de.inum;
ffffffff8010323d:	0f b7 45 e0          	movzwl -0x20(%rbp),%eax
ffffffff80103241:	0f b7 c0             	movzwl %ax,%eax
ffffffff80103244:	89 45 f8             	mov    %eax,-0x8(%rbp)
      return iget(dp->dev, inum);
ffffffff80103247:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010324b:	8b 00                	mov    (%rax),%eax
ffffffff8010324d:	8b 55 f8             	mov    -0x8(%rbp),%edx
ffffffff80103250:	89 d6                	mov    %edx,%esi
ffffffff80103252:	89 c7                	mov    %eax,%edi
ffffffff80103254:	e8 c0 f4 ff ff       	callq  ffffffff80102719 <iget>
ffffffff80103259:	eb 1a                	jmp    ffffffff80103275 <dirlookup+0xcf>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
ffffffff8010325b:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
ffffffff8010325c:	83 45 fc 10          	addl   $0x10,-0x4(%rbp)
ffffffff80103260:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80103264:	8b 40 20             	mov    0x20(%rax),%eax
ffffffff80103267:	3b 45 fc             	cmp    -0x4(%rbp),%eax
ffffffff8010326a:	0f 87 70 ff ff ff    	ja     ffffffff801031e0 <dirlookup+0x3a>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
ffffffff80103270:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80103275:	c9                   	leaveq 
ffffffff80103276:	c3                   	retq   

ffffffff80103277 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
ffffffff80103277:	55                   	push   %rbp
ffffffff80103278:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010327b:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff8010327f:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff80103283:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
ffffffff80103287:	89 55 cc             	mov    %edx,-0x34(%rbp)
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
ffffffff8010328a:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
ffffffff8010328e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80103292:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff80103297:	48 89 ce             	mov    %rcx,%rsi
ffffffff8010329a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010329d:	e8 04 ff ff ff       	callq  ffffffff801031a6 <dirlookup>
ffffffff801032a2:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff801032a6:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff801032ab:	74 16                	je     ffffffff801032c3 <dirlink+0x4c>
    iput(ip);
ffffffff801032ad:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801032b1:	48 89 c7             	mov    %rax,%rdi
ffffffff801032b4:	e8 9c f7 ff ff       	callq  ffffffff80102a55 <iput>
    return -1;
ffffffff801032b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801032be:	e9 a6 00 00 00       	jmpq   ffffffff80103369 <dirlink+0xf2>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
ffffffff801032c3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801032ca:	eb 3b                	jmp    ffffffff80103307 <dirlink+0x90>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
ffffffff801032cc:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801032cf:	48 8d 75 e0          	lea    -0x20(%rbp),%rsi
ffffffff801032d3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801032d7:	b9 10 00 00 00       	mov    $0x10,%ecx
ffffffff801032dc:	48 89 c7             	mov    %rax,%rdi
ffffffff801032df:	e8 6b fb ff ff       	callq  ffffffff80102e4f <readi>
ffffffff801032e4:	83 f8 10             	cmp    $0x10,%eax
ffffffff801032e7:	74 0c                	je     ffffffff801032f5 <dirlink+0x7e>
      panic("dirlink read");
ffffffff801032e9:	48 c7 c7 45 a8 10 80 	mov    $0xffffffff8010a845,%rdi
ffffffff801032f0:	e8 0a d6 ff ff       	callq  ffffffff801008ff <panic>
    if(de.inum == 0)
ffffffff801032f5:	0f b7 45 e0          	movzwl -0x20(%rbp),%eax
ffffffff801032f9:	66 85 c0             	test   %ax,%ax
ffffffff801032fc:	74 19                	je     ffffffff80103317 <dirlink+0xa0>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
ffffffff801032fe:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103301:	83 c0 10             	add    $0x10,%eax
ffffffff80103304:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff80103307:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010330b:	8b 50 20             	mov    0x20(%rax),%edx
ffffffff8010330e:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103311:	39 c2                	cmp    %eax,%edx
ffffffff80103313:	77 b7                	ja     ffffffff801032cc <dirlink+0x55>
ffffffff80103315:	eb 01                	jmp    ffffffff80103318 <dirlink+0xa1>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
ffffffff80103317:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
ffffffff80103318:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff8010331c:	48 8d 55 e0          	lea    -0x20(%rbp),%rdx
ffffffff80103320:	48 8d 4a 02          	lea    0x2(%rdx),%rcx
ffffffff80103324:	ba 0e 00 00 00       	mov    $0xe,%edx
ffffffff80103329:	48 89 c6             	mov    %rax,%rsi
ffffffff8010332c:	48 89 cf             	mov    %rcx,%rdi
ffffffff8010332f:	e8 03 3b 00 00       	callq  ffffffff80106e37 <strncpy>
  de.inum = inum;
ffffffff80103334:	8b 45 cc             	mov    -0x34(%rbp),%eax
ffffffff80103337:	66 89 45 e0          	mov    %ax,-0x20(%rbp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
ffffffff8010333b:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff8010333e:	48 8d 75 e0          	lea    -0x20(%rbp),%rsi
ffffffff80103342:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80103346:	b9 10 00 00 00       	mov    $0x10,%ecx
ffffffff8010334b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010334e:	e8 7c fc ff ff       	callq  ffffffff80102fcf <writei>
ffffffff80103353:	83 f8 10             	cmp    $0x10,%eax
ffffffff80103356:	74 0c                	je     ffffffff80103364 <dirlink+0xed>
    panic("dirlink");
ffffffff80103358:	48 c7 c7 52 a8 10 80 	mov    $0xffffffff8010a852,%rdi
ffffffff8010335f:	e8 9b d5 ff ff       	callq  ffffffff801008ff <panic>
  
  return 0;
ffffffff80103364:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80103369:	c9                   	leaveq 
ffffffff8010336a:	c3                   	retq   

ffffffff8010336b <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
ffffffff8010336b:	55                   	push   %rbp
ffffffff8010336c:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010336f:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80103373:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80103377:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  char *s;
  int len;

  while(*path == '/')
ffffffff8010337b:	eb 05                	jmp    ffffffff80103382 <skipelem+0x17>
    path++;
ffffffff8010337d:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
ffffffff80103382:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80103386:	0f b6 00             	movzbl (%rax),%eax
ffffffff80103389:	3c 2f                	cmp    $0x2f,%al
ffffffff8010338b:	74 f0                	je     ffffffff8010337d <skipelem+0x12>
    path++;
  if(*path == 0)
ffffffff8010338d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80103391:	0f b6 00             	movzbl (%rax),%eax
ffffffff80103394:	84 c0                	test   %al,%al
ffffffff80103396:	75 0a                	jne    ffffffff801033a2 <skipelem+0x37>
    return 0;
ffffffff80103398:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010339d:	e9 92 00 00 00       	jmpq   ffffffff80103434 <skipelem+0xc9>
  s = path;
ffffffff801033a2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801033a6:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  while(*path != '/' && *path != 0)
ffffffff801033aa:	eb 05                	jmp    ffffffff801033b1 <skipelem+0x46>
    path++;
ffffffff801033ac:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
ffffffff801033b1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801033b5:	0f b6 00             	movzbl (%rax),%eax
ffffffff801033b8:	3c 2f                	cmp    $0x2f,%al
ffffffff801033ba:	74 0b                	je     ffffffff801033c7 <skipelem+0x5c>
ffffffff801033bc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801033c0:	0f b6 00             	movzbl (%rax),%eax
ffffffff801033c3:	84 c0                	test   %al,%al
ffffffff801033c5:	75 e5                	jne    ffffffff801033ac <skipelem+0x41>
    path++;
  len = path - s;
ffffffff801033c7:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff801033cb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801033cf:	48 29 c2             	sub    %rax,%rdx
ffffffff801033d2:	48 89 d0             	mov    %rdx,%rax
ffffffff801033d5:	89 45 f4             	mov    %eax,-0xc(%rbp)
  if(len >= DIRSIZ)
ffffffff801033d8:	83 7d f4 0d          	cmpl   $0xd,-0xc(%rbp)
ffffffff801033dc:	7e 1a                	jle    ffffffff801033f8 <skipelem+0x8d>
    memmove(name, s, DIRSIZ);
ffffffff801033de:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
ffffffff801033e2:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801033e6:	ba 0e 00 00 00       	mov    $0xe,%edx
ffffffff801033eb:	48 89 ce             	mov    %rcx,%rsi
ffffffff801033ee:	48 89 c7             	mov    %rax,%rdi
ffffffff801033f1:	e8 06 39 00 00       	callq  ffffffff80106cfc <memmove>
ffffffff801033f6:	eb 2d                	jmp    ffffffff80103425 <skipelem+0xba>
  else {
    memmove(name, s, len);
ffffffff801033f8:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff801033fb:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
ffffffff801033ff:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80103403:	48 89 ce             	mov    %rcx,%rsi
ffffffff80103406:	48 89 c7             	mov    %rax,%rdi
ffffffff80103409:	e8 ee 38 00 00       	callq  ffffffff80106cfc <memmove>
    name[len] = 0;
ffffffff8010340e:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80103411:	48 63 d0             	movslq %eax,%rdx
ffffffff80103414:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80103418:	48 01 d0             	add    %rdx,%rax
ffffffff8010341b:	c6 00 00             	movb   $0x0,(%rax)
  }
  while(*path == '/')
ffffffff8010341e:	eb 05                	jmp    ffffffff80103425 <skipelem+0xba>
    path++;
ffffffff80103420:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
ffffffff80103425:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80103429:	0f b6 00             	movzbl (%rax),%eax
ffffffff8010342c:	3c 2f                	cmp    $0x2f,%al
ffffffff8010342e:	74 f0                	je     ffffffff80103420 <skipelem+0xb5>
    path++;
  return path;
ffffffff80103430:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
}
ffffffff80103434:	c9                   	leaveq 
ffffffff80103435:	c3                   	retq   

ffffffff80103436 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
ffffffff80103436:	55                   	push   %rbp
ffffffff80103437:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010343a:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff8010343e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80103442:	89 75 e4             	mov    %esi,-0x1c(%rbp)
ffffffff80103445:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  struct inode *ip, *next;

  if(*path == '/')
ffffffff80103449:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010344d:	0f b6 00             	movzbl (%rax),%eax
ffffffff80103450:	3c 2f                	cmp    $0x2f,%al
ffffffff80103452:	75 18                	jne    ffffffff8010346c <namex+0x36>
    ip = iget(ROOTDEV, ROOTINO);
ffffffff80103454:	be 01 00 00 00       	mov    $0x1,%esi
ffffffff80103459:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff8010345e:	e8 b6 f2 ff ff       	callq  ffffffff80102719 <iget>
ffffffff80103463:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80103467:	e9 c3 00 00 00       	jmpq   ffffffff8010352f <namex+0xf9>
  else
    ip = idup(proc->cwd);
ffffffff8010346c:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80103473:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80103477:	48 8b 80 c8 00 00 00 	mov    0xc8(%rax),%rax
ffffffff8010347e:	48 89 c7             	mov    %rax,%rdi
ffffffff80103481:	e8 83 f3 ff ff       	callq  ffffffff80102809 <idup>
ffffffff80103486:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

  while((path = skipelem(path, name)) != 0){
ffffffff8010348a:	e9 a0 00 00 00       	jmpq   ffffffff8010352f <namex+0xf9>
    ilock(ip);
ffffffff8010348f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103493:	48 89 c7             	mov    %rax,%rdi
ffffffff80103496:	e8 a9 f3 ff ff       	callq  ffffffff80102844 <ilock>
    if(ip->type != T_DIR){
ffffffff8010349b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010349f:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff801034a3:	66 83 f8 01          	cmp    $0x1,%ax
ffffffff801034a7:	74 16                	je     ffffffff801034bf <namex+0x89>
      iunlockput(ip);
ffffffff801034a9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801034ad:	48 89 c7             	mov    %rax,%rdi
ffffffff801034b0:	e8 85 f6 ff ff       	callq  ffffffff80102b3a <iunlockput>
      return 0;
ffffffff801034b5:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801034ba:	e9 af 00 00 00       	jmpq   ffffffff8010356e <namex+0x138>
    }
    if(nameiparent && *path == '\0'){
ffffffff801034bf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
ffffffff801034c3:	74 20                	je     ffffffff801034e5 <namex+0xaf>
ffffffff801034c5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801034c9:	0f b6 00             	movzbl (%rax),%eax
ffffffff801034cc:	84 c0                	test   %al,%al
ffffffff801034ce:	75 15                	jne    ffffffff801034e5 <namex+0xaf>
      // Stop one level early.
      iunlock(ip);
ffffffff801034d0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801034d4:	48 89 c7             	mov    %rax,%rdi
ffffffff801034d7:	e8 07 f5 ff ff       	callq  ffffffff801029e3 <iunlock>
      return ip;
ffffffff801034dc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801034e0:	e9 89 00 00 00       	jmpq   ffffffff8010356e <namex+0x138>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
ffffffff801034e5:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
ffffffff801034e9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801034ed:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff801034f2:	48 89 ce             	mov    %rcx,%rsi
ffffffff801034f5:	48 89 c7             	mov    %rax,%rdi
ffffffff801034f8:	e8 a9 fc ff ff       	callq  ffffffff801031a6 <dirlookup>
ffffffff801034fd:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80103501:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80103506:	75 13                	jne    ffffffff8010351b <namex+0xe5>
      iunlockput(ip);
ffffffff80103508:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010350c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010350f:	e8 26 f6 ff ff       	callq  ffffffff80102b3a <iunlockput>
      return 0;
ffffffff80103514:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103519:	eb 53                	jmp    ffffffff8010356e <namex+0x138>
    }
    iunlockput(ip);
ffffffff8010351b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010351f:	48 89 c7             	mov    %rax,%rdi
ffffffff80103522:	e8 13 f6 ff ff       	callq  ffffffff80102b3a <iunlockput>
    ip = next;
ffffffff80103527:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010352b:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
ffffffff8010352f:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff80103533:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80103537:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010353a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010353d:	e8 29 fe ff ff       	callq  ffffffff8010336b <skipelem>
ffffffff80103542:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80103546:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff8010354b:	0f 85 3e ff ff ff    	jne    ffffffff8010348f <namex+0x59>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
ffffffff80103551:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
ffffffff80103555:	74 13                	je     ffffffff8010356a <namex+0x134>
    iput(ip);
ffffffff80103557:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010355b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010355e:	e8 f2 f4 ff ff       	callq  ffffffff80102a55 <iput>
    return 0;
ffffffff80103563:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103568:	eb 04                	jmp    ffffffff8010356e <namex+0x138>
  }
  return ip;
ffffffff8010356a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff8010356e:	c9                   	leaveq 
ffffffff8010356f:	c3                   	retq   

ffffffff80103570 <namei>:

struct inode*
namei(char *path)
{
ffffffff80103570:	55                   	push   %rbp
ffffffff80103571:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103574:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80103578:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  char name[DIRSIZ];
  return namex(path, 0, name);
ffffffff8010357c:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
ffffffff80103580:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80103584:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80103589:	48 89 c7             	mov    %rax,%rdi
ffffffff8010358c:	e8 a5 fe ff ff       	callq  ffffffff80103436 <namex>
}
ffffffff80103591:	c9                   	leaveq 
ffffffff80103592:	c3                   	retq   

ffffffff80103593 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
ffffffff80103593:	55                   	push   %rbp
ffffffff80103594:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103597:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff8010359b:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff8010359f:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  return namex(path, 1, name);
ffffffff801035a3:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff801035a7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801035ab:	be 01 00 00 00       	mov    $0x1,%esi
ffffffff801035b0:	48 89 c7             	mov    %rax,%rdi
ffffffff801035b3:	e8 7e fe ff ff       	callq  ffffffff80103436 <namex>
}
ffffffff801035b8:	c9                   	leaveq 
ffffffff801035b9:	c3                   	retq   

ffffffff801035ba <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
ffffffff801035ba:	55                   	push   %rbp
ffffffff801035bb:	48 89 e5             	mov    %rsp,%rbp
ffffffff801035be:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801035c2:	89 7d fc             	mov    %edi,-0x4(%rbp)
  ioapic->reg = reg;
ffffffff801035c5:	48 8b 05 dc cf 08 00 	mov    0x8cfdc(%rip),%rax        # ffffffff801905a8 <ioapic>
ffffffff801035cc:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801035cf:	89 10                	mov    %edx,(%rax)
  return ioapic->data;
ffffffff801035d1:	48 8b 05 d0 cf 08 00 	mov    0x8cfd0(%rip),%rax        # ffffffff801905a8 <ioapic>
ffffffff801035d8:	8b 40 10             	mov    0x10(%rax),%eax
}
ffffffff801035db:	c9                   	leaveq 
ffffffff801035dc:	c3                   	retq   

ffffffff801035dd <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
ffffffff801035dd:	55                   	push   %rbp
ffffffff801035de:	48 89 e5             	mov    %rsp,%rbp
ffffffff801035e1:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801035e5:	89 7d fc             	mov    %edi,-0x4(%rbp)
ffffffff801035e8:	89 75 f8             	mov    %esi,-0x8(%rbp)
  ioapic->reg = reg;
ffffffff801035eb:	48 8b 05 b6 cf 08 00 	mov    0x8cfb6(%rip),%rax        # ffffffff801905a8 <ioapic>
ffffffff801035f2:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801035f5:	89 10                	mov    %edx,(%rax)
  ioapic->data = data;
ffffffff801035f7:	48 8b 05 aa cf 08 00 	mov    0x8cfaa(%rip),%rax        # ffffffff801905a8 <ioapic>
ffffffff801035fe:	8b 55 f8             	mov    -0x8(%rbp),%edx
ffffffff80103601:	89 50 10             	mov    %edx,0x10(%rax)
}
ffffffff80103604:	90                   	nop
ffffffff80103605:	c9                   	leaveq 
ffffffff80103606:	c3                   	retq   

ffffffff80103607 <ioapicinit>:

void
ioapicinit(void)
{
ffffffff80103607:	55                   	push   %rbp
ffffffff80103608:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010360b:	48 83 ec 10          	sub    $0x10,%rsp
  int i, id, maxintr;

  if(!ismp)
ffffffff8010360f:	8b 05 cb d8 08 00    	mov    0x8d8cb(%rip),%eax        # ffffffff80190ee0 <ismp>
ffffffff80103615:	85 c0                	test   %eax,%eax
ffffffff80103617:	0f 84 a2 00 00 00    	je     ffffffff801036bf <ioapicinit+0xb8>
    return;

  ioapic = (volatile struct ioapic*) IO2V(IOAPIC);
ffffffff8010361d:	48 b8 00 00 c0 40 ff 	movabs $0xffffffff40c00000,%rax
ffffffff80103624:	ff ff ff 
ffffffff80103627:	48 89 05 7a cf 08 00 	mov    %rax,0x8cf7a(%rip)        # ffffffff801905a8 <ioapic>
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
ffffffff8010362e:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff80103633:	e8 82 ff ff ff       	callq  ffffffff801035ba <ioapicread>
ffffffff80103638:	c1 e8 10             	shr    $0x10,%eax
ffffffff8010363b:	25 ff 00 00 00       	and    $0xff,%eax
ffffffff80103640:	89 45 f8             	mov    %eax,-0x8(%rbp)
  id = ioapicread(REG_ID) >> 24;
ffffffff80103643:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80103648:	e8 6d ff ff ff       	callq  ffffffff801035ba <ioapicread>
ffffffff8010364d:	c1 e8 18             	shr    $0x18,%eax
ffffffff80103650:	89 45 f4             	mov    %eax,-0xc(%rbp)
  if(id != ioapicid)
ffffffff80103653:	0f b6 05 8e d8 08 00 	movzbl 0x8d88e(%rip),%eax        # ffffffff80190ee8 <ioapicid>
ffffffff8010365a:	0f b6 c0             	movzbl %al,%eax
ffffffff8010365d:	3b 45 f4             	cmp    -0xc(%rbp),%eax
ffffffff80103660:	74 11                	je     ffffffff80103673 <ioapicinit+0x6c>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
ffffffff80103662:	48 c7 c7 60 a8 10 80 	mov    $0xffffffff8010a860,%rdi
ffffffff80103669:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010366e:	e8 2f cf ff ff       	callq  ffffffff801005a2 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
ffffffff80103673:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff8010367a:	eb 39                	jmp    ffffffff801036b5 <ioapicinit+0xae>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
ffffffff8010367c:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010367f:	83 c0 20             	add    $0x20,%eax
ffffffff80103682:	0d 00 00 01 00       	or     $0x10000,%eax
ffffffff80103687:	89 c2                	mov    %eax,%edx
ffffffff80103689:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010368c:	83 c0 08             	add    $0x8,%eax
ffffffff8010368f:	01 c0                	add    %eax,%eax
ffffffff80103691:	89 d6                	mov    %edx,%esi
ffffffff80103693:	89 c7                	mov    %eax,%edi
ffffffff80103695:	e8 43 ff ff ff       	callq  ffffffff801035dd <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
ffffffff8010369a:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010369d:	83 c0 08             	add    $0x8,%eax
ffffffff801036a0:	01 c0                	add    %eax,%eax
ffffffff801036a2:	83 c0 01             	add    $0x1,%eax
ffffffff801036a5:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801036aa:	89 c7                	mov    %eax,%edi
ffffffff801036ac:	e8 2c ff ff ff       	callq  ffffffff801035dd <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
ffffffff801036b1:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801036b5:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801036b8:	3b 45 f8             	cmp    -0x8(%rbp),%eax
ffffffff801036bb:	7e bf                	jle    ffffffff8010367c <ioapicinit+0x75>
ffffffff801036bd:	eb 01                	jmp    ffffffff801036c0 <ioapicinit+0xb9>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
ffffffff801036bf:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
ffffffff801036c0:	c9                   	leaveq 
ffffffff801036c1:	c3                   	retq   

ffffffff801036c2 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
ffffffff801036c2:	55                   	push   %rbp
ffffffff801036c3:	48 89 e5             	mov    %rsp,%rbp
ffffffff801036c6:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801036ca:	89 7d fc             	mov    %edi,-0x4(%rbp)
ffffffff801036cd:	89 75 f8             	mov    %esi,-0x8(%rbp)
  if(!ismp)
ffffffff801036d0:	8b 05 0a d8 08 00    	mov    0x8d80a(%rip),%eax        # ffffffff80190ee0 <ismp>
ffffffff801036d6:	85 c0                	test   %eax,%eax
ffffffff801036d8:	74 37                	je     ffffffff80103711 <ioapicenable+0x4f>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
ffffffff801036da:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801036dd:	83 c0 20             	add    $0x20,%eax
ffffffff801036e0:	89 c2                	mov    %eax,%edx
ffffffff801036e2:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801036e5:	83 c0 08             	add    $0x8,%eax
ffffffff801036e8:	01 c0                	add    %eax,%eax
ffffffff801036ea:	89 d6                	mov    %edx,%esi
ffffffff801036ec:	89 c7                	mov    %eax,%edi
ffffffff801036ee:	e8 ea fe ff ff       	callq  ffffffff801035dd <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
ffffffff801036f3:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff801036f6:	c1 e0 18             	shl    $0x18,%eax
ffffffff801036f9:	89 c2                	mov    %eax,%edx
ffffffff801036fb:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801036fe:	83 c0 08             	add    $0x8,%eax
ffffffff80103701:	01 c0                	add    %eax,%eax
ffffffff80103703:	83 c0 01             	add    $0x1,%eax
ffffffff80103706:	89 d6                	mov    %edx,%esi
ffffffff80103708:	89 c7                	mov    %eax,%edi
ffffffff8010370a:	e8 ce fe ff ff       	callq  ffffffff801035dd <ioapicwrite>
ffffffff8010370f:	eb 01                	jmp    ffffffff80103712 <ioapicenable+0x50>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
ffffffff80103711:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
ffffffff80103712:	c9                   	leaveq 
ffffffff80103713:	c3                   	retq   

ffffffff80103714 <v2p>:
#endif
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uintp v2p(void *a) { return ((uintp) (a)) - ((uintp)KERNBASE); }
ffffffff80103714:	55                   	push   %rbp
ffffffff80103715:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103718:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff8010371c:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80103720:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80103724:	b8 00 00 00 80       	mov    $0x80000000,%eax
ffffffff80103729:	48 01 d0             	add    %rdx,%rax
ffffffff8010372c:	c9                   	leaveq 
ffffffff8010372d:	c3                   	retq   

ffffffff8010372e <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
ffffffff8010372e:	55                   	push   %rbp
ffffffff8010372f:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103732:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80103736:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff8010373a:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  initlock(&kmem.lock, "kmem");
ffffffff8010373e:	48 c7 c6 92 a8 10 80 	mov    $0xffffffff8010a892,%rsi
ffffffff80103745:	48 c7 c7 c0 05 19 80 	mov    $0xffffffff801905c0,%rdi
ffffffff8010374c:	e8 18 31 00 00       	callq  ffffffff80106869 <initlock>
  kmem.use_lock = 0;
ffffffff80103751:	c7 05 cd ce 08 00 00 	movl   $0x0,0x8cecd(%rip)        # ffffffff80190628 <kmem+0x68>
ffffffff80103758:	00 00 00 
  freerange(vstart, vend);
ffffffff8010375b:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff8010375f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103763:	48 89 d6             	mov    %rdx,%rsi
ffffffff80103766:	48 89 c7             	mov    %rax,%rdi
ffffffff80103769:	e8 33 00 00 00       	callq  ffffffff801037a1 <freerange>
}
ffffffff8010376e:	90                   	nop
ffffffff8010376f:	c9                   	leaveq 
ffffffff80103770:	c3                   	retq   

ffffffff80103771 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
ffffffff80103771:	55                   	push   %rbp
ffffffff80103772:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103775:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80103779:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff8010377d:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  freerange(vstart, vend);
ffffffff80103781:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff80103785:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103789:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010378c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010378f:	e8 0d 00 00 00       	callq  ffffffff801037a1 <freerange>
  kmem.use_lock = 1;
ffffffff80103794:	c7 05 8a ce 08 00 01 	movl   $0x1,0x8ce8a(%rip)        # ffffffff80190628 <kmem+0x68>
ffffffff8010379b:	00 00 00 
}
ffffffff8010379e:	90                   	nop
ffffffff8010379f:	c9                   	leaveq 
ffffffff801037a0:	c3                   	retq   

ffffffff801037a1 <freerange>:

void
freerange(void *vstart, void *vend)
{
ffffffff801037a1:	55                   	push   %rbp
ffffffff801037a2:	48 89 e5             	mov    %rsp,%rbp
ffffffff801037a5:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801037a9:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff801037ad:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  char *p;
  p = (char*)PGROUNDUP((uintp)vstart);
ffffffff801037b1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801037b5:	48 05 ff 0f 00 00    	add    $0xfff,%rax
ffffffff801037bb:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff801037c1:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
ffffffff801037c5:	eb 14                	jmp    ffffffff801037db <freerange+0x3a>
    kfree(p);
ffffffff801037c7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801037cb:	48 89 c7             	mov    %rax,%rdi
ffffffff801037ce:	e8 1b 00 00 00       	callq  ffffffff801037ee <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uintp)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
ffffffff801037d3:	48 81 45 f8 00 10 00 	addq   $0x1000,-0x8(%rbp)
ffffffff801037da:	00 
ffffffff801037db:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801037df:	48 05 00 10 00 00    	add    $0x1000,%rax
ffffffff801037e5:	48 3b 45 e0          	cmp    -0x20(%rbp),%rax
ffffffff801037e9:	76 dc                	jbe    ffffffff801037c7 <freerange+0x26>
    kfree(p);
}
ffffffff801037eb:	90                   	nop
ffffffff801037ec:	c9                   	leaveq 
ffffffff801037ed:	c3                   	retq   

ffffffff801037ee <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
ffffffff801037ee:	55                   	push   %rbp
ffffffff801037ef:	48 89 e5             	mov    %rsp,%rbp
ffffffff801037f2:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801037f6:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  struct run *r;

  if((uintp)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
ffffffff801037fa:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801037fe:	25 ff 0f 00 00       	and    $0xfff,%eax
ffffffff80103803:	48 85 c0             	test   %rax,%rax
ffffffff80103806:	75 1e                	jne    ffffffff80103826 <kfree+0x38>
ffffffff80103808:	48 81 7d e8 00 60 19 	cmpq   $0xffffffff80196000,-0x18(%rbp)
ffffffff8010380f:	80 
ffffffff80103810:	72 14                	jb     ffffffff80103826 <kfree+0x38>
ffffffff80103812:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80103816:	48 89 c7             	mov    %rax,%rdi
ffffffff80103819:	e8 f6 fe ff ff       	callq  ffffffff80103714 <v2p>
ffffffff8010381e:	48 3d ff ff ff 0d    	cmp    $0xdffffff,%rax
ffffffff80103824:	76 0c                	jbe    ffffffff80103832 <kfree+0x44>
    panic("kfree");
ffffffff80103826:	48 c7 c7 97 a8 10 80 	mov    $0xffffffff8010a897,%rdi
ffffffff8010382d:	e8 cd d0 ff ff       	callq  ffffffff801008ff <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
ffffffff80103832:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80103836:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff8010383b:	be 01 00 00 00       	mov    $0x1,%esi
ffffffff80103840:	48 89 c7             	mov    %rax,%rdi
ffffffff80103843:	e8 c5 33 00 00       	callq  ffffffff80106c0d <memset>

  if(kmem.use_lock)
ffffffff80103848:	8b 05 da cd 08 00    	mov    0x8cdda(%rip),%eax        # ffffffff80190628 <kmem+0x68>
ffffffff8010384e:	85 c0                	test   %eax,%eax
ffffffff80103850:	74 0c                	je     ffffffff8010385e <kfree+0x70>
    acquire(&kmem.lock);
ffffffff80103852:	48 c7 c7 c0 05 19 80 	mov    $0xffffffff801905c0,%rdi
ffffffff80103859:	e8 40 30 00 00       	callq  ffffffff8010689e <acquire>
  r = (struct run*)v;
ffffffff8010385e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80103862:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  r->next = kmem.freelist;
ffffffff80103866:	48 8b 15 c3 cd 08 00 	mov    0x8cdc3(%rip),%rdx        # ffffffff80190630 <kmem+0x70>
ffffffff8010386d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103871:	48 89 10             	mov    %rdx,(%rax)
  kmem.freelist = r;
ffffffff80103874:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103878:	48 89 05 b1 cd 08 00 	mov    %rax,0x8cdb1(%rip)        # ffffffff80190630 <kmem+0x70>
  if(kmem.use_lock)
ffffffff8010387f:	8b 05 a3 cd 08 00    	mov    0x8cda3(%rip),%eax        # ffffffff80190628 <kmem+0x68>
ffffffff80103885:	85 c0                	test   %eax,%eax
ffffffff80103887:	74 0c                	je     ffffffff80103895 <kfree+0xa7>
    release(&kmem.lock);
ffffffff80103889:	48 c7 c7 c0 05 19 80 	mov    $0xffffffff801905c0,%rdi
ffffffff80103890:	e8 e0 30 00 00       	callq  ffffffff80106975 <release>
}
ffffffff80103895:	90                   	nop
ffffffff80103896:	c9                   	leaveq 
ffffffff80103897:	c3                   	retq   

ffffffff80103898 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
ffffffff80103898:	55                   	push   %rbp
ffffffff80103899:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010389c:	48 83 ec 10          	sub    $0x10,%rsp
  struct run *r;

  if(kmem.use_lock)
ffffffff801038a0:	8b 05 82 cd 08 00    	mov    0x8cd82(%rip),%eax        # ffffffff80190628 <kmem+0x68>
ffffffff801038a6:	85 c0                	test   %eax,%eax
ffffffff801038a8:	74 0c                	je     ffffffff801038b6 <kalloc+0x1e>
    acquire(&kmem.lock);
ffffffff801038aa:	48 c7 c7 c0 05 19 80 	mov    $0xffffffff801905c0,%rdi
ffffffff801038b1:	e8 e8 2f 00 00       	callq  ffffffff8010689e <acquire>
  r = kmem.freelist;
ffffffff801038b6:	48 8b 05 73 cd 08 00 	mov    0x8cd73(%rip),%rax        # ffffffff80190630 <kmem+0x70>
ffffffff801038bd:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if(r)
ffffffff801038c1:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff801038c6:	74 0e                	je     ffffffff801038d6 <kalloc+0x3e>
    kmem.freelist = r->next;
ffffffff801038c8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801038cc:	48 8b 00             	mov    (%rax),%rax
ffffffff801038cf:	48 89 05 5a cd 08 00 	mov    %rax,0x8cd5a(%rip)        # ffffffff80190630 <kmem+0x70>
  if(kmem.use_lock)
ffffffff801038d6:	8b 05 4c cd 08 00    	mov    0x8cd4c(%rip),%eax        # ffffffff80190628 <kmem+0x68>
ffffffff801038dc:	85 c0                	test   %eax,%eax
ffffffff801038de:	74 0c                	je     ffffffff801038ec <kalloc+0x54>
    release(&kmem.lock);
ffffffff801038e0:	48 c7 c7 c0 05 19 80 	mov    $0xffffffff801905c0,%rdi
ffffffff801038e7:	e8 89 30 00 00       	callq  ffffffff80106975 <release>
  return (char*)r;
ffffffff801038ec:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff801038f0:	c9                   	leaveq 
ffffffff801038f1:	c3                   	retq   

ffffffff801038f2 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
ffffffff801038f2:	55                   	push   %rbp
ffffffff801038f3:	48 89 e5             	mov    %rsp,%rbp
ffffffff801038f6:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff801038fa:	89 f8                	mov    %edi,%eax
ffffffff801038fc:	66 89 45 ec          	mov    %ax,-0x14(%rbp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
ffffffff80103900:	0f b7 45 ec          	movzwl -0x14(%rbp),%eax
ffffffff80103904:	89 c2                	mov    %eax,%edx
ffffffff80103906:	ec                   	in     (%dx),%al
ffffffff80103907:	88 45 ff             	mov    %al,-0x1(%rbp)
  return data;
ffffffff8010390a:	0f b6 45 ff          	movzbl -0x1(%rbp),%eax
}
ffffffff8010390e:	c9                   	leaveq 
ffffffff8010390f:	c3                   	retq   

ffffffff80103910 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
ffffffff80103910:	55                   	push   %rbp
ffffffff80103911:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103914:	48 83 ec 10          	sub    $0x10,%rsp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
ffffffff80103918:	bf 64 00 00 00       	mov    $0x64,%edi
ffffffff8010391d:	e8 d0 ff ff ff       	callq  ffffffff801038f2 <inb>
ffffffff80103922:	0f b6 c0             	movzbl %al,%eax
ffffffff80103925:	89 45 f4             	mov    %eax,-0xc(%rbp)
  if((st & KBS_DIB) == 0)
ffffffff80103928:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff8010392b:	83 e0 01             	and    $0x1,%eax
ffffffff8010392e:	85 c0                	test   %eax,%eax
ffffffff80103930:	75 0a                	jne    ffffffff8010393c <kbdgetc+0x2c>
    return -1;
ffffffff80103932:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80103937:	e9 32 01 00 00       	jmpq   ffffffff80103a6e <kbdgetc+0x15e>
  data = inb(KBDATAP);
ffffffff8010393c:	bf 60 00 00 00       	mov    $0x60,%edi
ffffffff80103941:	e8 ac ff ff ff       	callq  ffffffff801038f2 <inb>
ffffffff80103946:	0f b6 c0             	movzbl %al,%eax
ffffffff80103949:	89 45 fc             	mov    %eax,-0x4(%rbp)

  if(data == 0xE0){
ffffffff8010394c:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%rbp)
ffffffff80103953:	75 19                	jne    ffffffff8010396e <kbdgetc+0x5e>
    shift |= E0ESC;
ffffffff80103955:	8b 05 dd cc 08 00    	mov    0x8ccdd(%rip),%eax        # ffffffff80190638 <shift.1797>
ffffffff8010395b:	83 c8 40             	or     $0x40,%eax
ffffffff8010395e:	89 05 d4 cc 08 00    	mov    %eax,0x8ccd4(%rip)        # ffffffff80190638 <shift.1797>
    return 0;
ffffffff80103964:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103969:	e9 00 01 00 00       	jmpq   ffffffff80103a6e <kbdgetc+0x15e>
  } else if(data & 0x80){
ffffffff8010396e:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103971:	25 80 00 00 00       	and    $0x80,%eax
ffffffff80103976:	85 c0                	test   %eax,%eax
ffffffff80103978:	74 47                	je     ffffffff801039c1 <kbdgetc+0xb1>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
ffffffff8010397a:	8b 05 b8 cc 08 00    	mov    0x8ccb8(%rip),%eax        # ffffffff80190638 <shift.1797>
ffffffff80103980:	83 e0 40             	and    $0x40,%eax
ffffffff80103983:	85 c0                	test   %eax,%eax
ffffffff80103985:	75 08                	jne    ffffffff8010398f <kbdgetc+0x7f>
ffffffff80103987:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010398a:	83 e0 7f             	and    $0x7f,%eax
ffffffff8010398d:	eb 03                	jmp    ffffffff80103992 <kbdgetc+0x82>
ffffffff8010398f:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103992:	89 45 fc             	mov    %eax,-0x4(%rbp)
    shift &= ~(shiftcode[data] | E0ESC);
ffffffff80103995:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103998:	0f b6 80 20 c0 10 80 	movzbl -0x7fef3fe0(%rax),%eax
ffffffff8010399f:	83 c8 40             	or     $0x40,%eax
ffffffff801039a2:	0f b6 c0             	movzbl %al,%eax
ffffffff801039a5:	f7 d0                	not    %eax
ffffffff801039a7:	89 c2                	mov    %eax,%edx
ffffffff801039a9:	8b 05 89 cc 08 00    	mov    0x8cc89(%rip),%eax        # ffffffff80190638 <shift.1797>
ffffffff801039af:	21 d0                	and    %edx,%eax
ffffffff801039b1:	89 05 81 cc 08 00    	mov    %eax,0x8cc81(%rip)        # ffffffff80190638 <shift.1797>
    return 0;
ffffffff801039b7:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801039bc:	e9 ad 00 00 00       	jmpq   ffffffff80103a6e <kbdgetc+0x15e>
  } else if(shift & E0ESC){
ffffffff801039c1:	8b 05 71 cc 08 00    	mov    0x8cc71(%rip),%eax        # ffffffff80190638 <shift.1797>
ffffffff801039c7:	83 e0 40             	and    $0x40,%eax
ffffffff801039ca:	85 c0                	test   %eax,%eax
ffffffff801039cc:	74 16                	je     ffffffff801039e4 <kbdgetc+0xd4>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
ffffffff801039ce:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%rbp)
    shift &= ~E0ESC;
ffffffff801039d5:	8b 05 5d cc 08 00    	mov    0x8cc5d(%rip),%eax        # ffffffff80190638 <shift.1797>
ffffffff801039db:	83 e0 bf             	and    $0xffffffbf,%eax
ffffffff801039de:	89 05 54 cc 08 00    	mov    %eax,0x8cc54(%rip)        # ffffffff80190638 <shift.1797>
  }

  shift |= shiftcode[data];
ffffffff801039e4:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801039e7:	0f b6 80 20 c0 10 80 	movzbl -0x7fef3fe0(%rax),%eax
ffffffff801039ee:	0f b6 d0             	movzbl %al,%edx
ffffffff801039f1:	8b 05 41 cc 08 00    	mov    0x8cc41(%rip),%eax        # ffffffff80190638 <shift.1797>
ffffffff801039f7:	09 d0                	or     %edx,%eax
ffffffff801039f9:	89 05 39 cc 08 00    	mov    %eax,0x8cc39(%rip)        # ffffffff80190638 <shift.1797>
  shift ^= togglecode[data];
ffffffff801039ff:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103a02:	0f b6 80 20 c1 10 80 	movzbl -0x7fef3ee0(%rax),%eax
ffffffff80103a09:	0f b6 d0             	movzbl %al,%edx
ffffffff80103a0c:	8b 05 26 cc 08 00    	mov    0x8cc26(%rip),%eax        # ffffffff80190638 <shift.1797>
ffffffff80103a12:	31 d0                	xor    %edx,%eax
ffffffff80103a14:	89 05 1e cc 08 00    	mov    %eax,0x8cc1e(%rip)        # ffffffff80190638 <shift.1797>
  c = charcode[shift & (CTL | SHIFT)][data];
ffffffff80103a1a:	8b 05 18 cc 08 00    	mov    0x8cc18(%rip),%eax        # ffffffff80190638 <shift.1797>
ffffffff80103a20:	83 e0 03             	and    $0x3,%eax
ffffffff80103a23:	89 c0                	mov    %eax,%eax
ffffffff80103a25:	48 8b 14 c5 20 c5 10 	mov    -0x7fef3ae0(,%rax,8),%rdx
ffffffff80103a2c:	80 
ffffffff80103a2d:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103a30:	48 01 d0             	add    %rdx,%rax
ffffffff80103a33:	0f b6 00             	movzbl (%rax),%eax
ffffffff80103a36:	0f b6 c0             	movzbl %al,%eax
ffffffff80103a39:	89 45 f8             	mov    %eax,-0x8(%rbp)
  if(shift & CAPSLOCK){
ffffffff80103a3c:	8b 05 f6 cb 08 00    	mov    0x8cbf6(%rip),%eax        # ffffffff80190638 <shift.1797>
ffffffff80103a42:	83 e0 08             	and    $0x8,%eax
ffffffff80103a45:	85 c0                	test   %eax,%eax
ffffffff80103a47:	74 22                	je     ffffffff80103a6b <kbdgetc+0x15b>
    if('a' <= c && c <= 'z')
ffffffff80103a49:	83 7d f8 60          	cmpl   $0x60,-0x8(%rbp)
ffffffff80103a4d:	76 0c                	jbe    ffffffff80103a5b <kbdgetc+0x14b>
ffffffff80103a4f:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%rbp)
ffffffff80103a53:	77 06                	ja     ffffffff80103a5b <kbdgetc+0x14b>
      c += 'A' - 'a';
ffffffff80103a55:	83 6d f8 20          	subl   $0x20,-0x8(%rbp)
ffffffff80103a59:	eb 10                	jmp    ffffffff80103a6b <kbdgetc+0x15b>
    else if('A' <= c && c <= 'Z')
ffffffff80103a5b:	83 7d f8 40          	cmpl   $0x40,-0x8(%rbp)
ffffffff80103a5f:	76 0a                	jbe    ffffffff80103a6b <kbdgetc+0x15b>
ffffffff80103a61:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%rbp)
ffffffff80103a65:	77 04                	ja     ffffffff80103a6b <kbdgetc+0x15b>
      c += 'a' - 'A';
ffffffff80103a67:	83 45 f8 20          	addl   $0x20,-0x8(%rbp)
  }
  return c;
ffffffff80103a6b:	8b 45 f8             	mov    -0x8(%rbp),%eax
}
ffffffff80103a6e:	c9                   	leaveq 
ffffffff80103a6f:	c3                   	retq   

ffffffff80103a70 <kbdintr>:

void
kbdintr(void)
{
ffffffff80103a70:	55                   	push   %rbp
ffffffff80103a71:	48 89 e5             	mov    %rsp,%rbp
  consoleintr(kbdgetc);
ffffffff80103a74:	48 c7 c7 10 39 10 80 	mov    $0xffffffff80103910,%rdi
ffffffff80103a7b:	e8 06 d1 ff ff       	callq  ffffffff80100b86 <consoleintr>
}
ffffffff80103a80:	90                   	nop
ffffffff80103a81:	5d                   	pop    %rbp
ffffffff80103a82:	c3                   	retq   

ffffffff80103a83 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
ffffffff80103a83:	55                   	push   %rbp
ffffffff80103a84:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103a87:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff80103a8b:	89 f8                	mov    %edi,%eax
ffffffff80103a8d:	66 89 45 ec          	mov    %ax,-0x14(%rbp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
ffffffff80103a91:	0f b7 45 ec          	movzwl -0x14(%rbp),%eax
ffffffff80103a95:	89 c2                	mov    %eax,%edx
ffffffff80103a97:	ec                   	in     (%dx),%al
ffffffff80103a98:	88 45 ff             	mov    %al,-0x1(%rbp)
  return data;
ffffffff80103a9b:	0f b6 45 ff          	movzbl -0x1(%rbp),%eax
}
ffffffff80103a9f:	c9                   	leaveq 
ffffffff80103aa0:	c3                   	retq   

ffffffff80103aa1 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
ffffffff80103aa1:	55                   	push   %rbp
ffffffff80103aa2:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103aa5:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80103aa9:	89 fa                	mov    %edi,%edx
ffffffff80103aab:	89 f0                	mov    %esi,%eax
ffffffff80103aad:	66 89 55 fc          	mov    %dx,-0x4(%rbp)
ffffffff80103ab1:	88 45 f8             	mov    %al,-0x8(%rbp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
ffffffff80103ab4:	0f b6 45 f8          	movzbl -0x8(%rbp),%eax
ffffffff80103ab8:	0f b7 55 fc          	movzwl -0x4(%rbp),%edx
ffffffff80103abc:	ee                   	out    %al,(%dx)
}
ffffffff80103abd:	90                   	nop
ffffffff80103abe:	c9                   	leaveq 
ffffffff80103abf:	c3                   	retq   

ffffffff80103ac0 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uintp
readeflags(void)
{
ffffffff80103ac0:	55                   	push   %rbp
ffffffff80103ac1:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103ac4:	48 83 ec 10          	sub    $0x10,%rsp
  uintp eflags;
  asm volatile("pushf; pop %0" : "=r" (eflags));
ffffffff80103ac8:	9c                   	pushfq 
ffffffff80103ac9:	58                   	pop    %rax
ffffffff80103aca:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  return eflags;
ffffffff80103ace:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80103ad2:	c9                   	leaveq 
ffffffff80103ad3:	c3                   	retq   

ffffffff80103ad4 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
ffffffff80103ad4:	55                   	push   %rbp
ffffffff80103ad5:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103ad8:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80103adc:	89 7d fc             	mov    %edi,-0x4(%rbp)
ffffffff80103adf:	89 75 f8             	mov    %esi,-0x8(%rbp)
  lapic[index] = value;
ffffffff80103ae2:	48 8b 05 57 cb 08 00 	mov    0x8cb57(%rip),%rax        # ffffffff80190640 <lapic>
ffffffff80103ae9:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80103aec:	48 63 d2             	movslq %edx,%rdx
ffffffff80103aef:	48 c1 e2 02          	shl    $0x2,%rdx
ffffffff80103af3:	48 01 c2             	add    %rax,%rdx
ffffffff80103af6:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80103af9:	89 02                	mov    %eax,(%rdx)
  lapic[ID];  // wait for write to finish, by reading
ffffffff80103afb:	48 8b 05 3e cb 08 00 	mov    0x8cb3e(%rip),%rax        # ffffffff80190640 <lapic>
ffffffff80103b02:	48 83 c0 20          	add    $0x20,%rax
ffffffff80103b06:	8b 00                	mov    (%rax),%eax
}
ffffffff80103b08:	90                   	nop
ffffffff80103b09:	c9                   	leaveq 
ffffffff80103b0a:	c3                   	retq   

ffffffff80103b0b <check_cpuid>:
//PAGEBREAK!

void check_cpuid()
{
ffffffff80103b0b:	55                   	push   %rbp
ffffffff80103b0c:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103b0f:	48 83 ec 10          	sub    $0x10,%rsp
		uint32 edx = 0,ecx = 0;
ffffffff80103b13:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80103b1a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
		__asm__ volatile("cpuid":"=d"(edx),"=c"(ecx):"a"(0x1):"memory","cc");
ffffffff80103b21:	b8 01 00 00 00       	mov    $0x1,%eax
ffffffff80103b26:	0f a2                	cpuid  
ffffffff80103b28:	89 c8                	mov    %ecx,%eax
ffffffff80103b2a:	89 55 fc             	mov    %edx,-0x4(%rbp)
ffffffff80103b2d:	89 45 f8             	mov    %eax,-0x8(%rbp)
		cprintf("check cpuid 0x1\n");
ffffffff80103b30:	48 c7 c7 a0 a8 10 80 	mov    $0xffffffff8010a8a0,%rdi
ffffffff80103b37:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103b3c:	e8 61 ca ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("local apic check,ecx:0x%x,edx:0x%x\n",ecx,edx);
ffffffff80103b41:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80103b44:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80103b47:	89 c6                	mov    %eax,%esi
ffffffff80103b49:	48 c7 c7 b8 a8 10 80 	mov    $0xffffffff8010a8b8,%rdi
ffffffff80103b50:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103b55:	e8 48 ca ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("support APIC:%s\n",(edx&(1<<9))?"YES":"NO");
ffffffff80103b5a:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103b5d:	25 00 02 00 00       	and    $0x200,%eax
ffffffff80103b62:	85 c0                	test   %eax,%eax
ffffffff80103b64:	74 09                	je     ffffffff80103b6f <check_cpuid+0x64>
ffffffff80103b66:	48 c7 c0 dc a8 10 80 	mov    $0xffffffff8010a8dc,%rax
ffffffff80103b6d:	eb 07                	jmp    ffffffff80103b76 <check_cpuid+0x6b>
ffffffff80103b6f:	48 c7 c0 e0 a8 10 80 	mov    $0xffffffff8010a8e0,%rax
ffffffff80103b76:	48 89 c6             	mov    %rax,%rsi
ffffffff80103b79:	48 c7 c7 e3 a8 10 80 	mov    $0xffffffff8010a8e3,%rdi
ffffffff80103b80:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103b85:	e8 18 ca ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("support x2APIC:%s\n",(ecx&(1<<21))?"YES":"NO");
ffffffff80103b8a:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80103b8d:	25 00 00 20 00       	and    $0x200000,%eax
ffffffff80103b92:	85 c0                	test   %eax,%eax
ffffffff80103b94:	74 09                	je     ffffffff80103b9f <check_cpuid+0x94>
ffffffff80103b96:	48 c7 c0 dc a8 10 80 	mov    $0xffffffff8010a8dc,%rax
ffffffff80103b9d:	eb 07                	jmp    ffffffff80103ba6 <check_cpuid+0x9b>
ffffffff80103b9f:	48 c7 c0 e0 a8 10 80 	mov    $0xffffffff8010a8e0,%rax
ffffffff80103ba6:	48 89 c6             	mov    %rax,%rsi
ffffffff80103ba9:	48 c7 c7 f4 a8 10 80 	mov    $0xffffffff8010a8f4,%rdi
ffffffff80103bb0:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103bb5:	e8 e8 c9 ff ff       	callq  ffffffff801005a2 <cprintf>
		
}
ffffffff80103bba:	90                   	nop
ffffffff80103bbb:	c9                   	leaveq 
ffffffff80103bbc:	c3                   	retq   

ffffffff80103bbd <lapicinit>:

void
lapicinit(void)
{
ffffffff80103bbd:	55                   	push   %rbp
ffffffff80103bbe:	48 89 e5             	mov    %rsp,%rbp
  if(!lapic) 
ffffffff80103bc1:	48 8b 05 78 ca 08 00 	mov    0x8ca78(%rip),%rax        # ffffffff80190640 <lapic>
ffffffff80103bc8:	48 85 c0             	test   %rax,%rax
ffffffff80103bcb:	0f 84 0f 01 00 00    	je     ffffffff80103ce0 <lapicinit+0x123>
    return;
	check_cpuid();
ffffffff80103bd1:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103bd6:	e8 30 ff ff ff       	callq  ffffffff80103b0b <check_cpuid>
  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
ffffffff80103bdb:	be 3f 01 00 00       	mov    $0x13f,%esi
ffffffff80103be0:	bf 3c 00 00 00       	mov    $0x3c,%edi
ffffffff80103be5:	e8 ea fe ff ff       	callq  ffffffff80103ad4 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
ffffffff80103bea:	be 0b 00 00 00       	mov    $0xb,%esi
ffffffff80103bef:	bf f8 00 00 00       	mov    $0xf8,%edi
ffffffff80103bf4:	e8 db fe ff ff       	callq  ffffffff80103ad4 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
ffffffff80103bf9:	be 20 00 02 00       	mov    $0x20020,%esi
ffffffff80103bfe:	bf c8 00 00 00       	mov    $0xc8,%edi
ffffffff80103c03:	e8 cc fe ff ff       	callq  ffffffff80103ad4 <lapicw>
  lapicw(TICR, 10000000); 
ffffffff80103c08:	be 80 96 98 00       	mov    $0x989680,%esi
ffffffff80103c0d:	bf e0 00 00 00       	mov    $0xe0,%edi
ffffffff80103c12:	e8 bd fe ff ff       	callq  ffffffff80103ad4 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
ffffffff80103c17:	be 00 00 01 00       	mov    $0x10000,%esi
ffffffff80103c1c:	bf d4 00 00 00       	mov    $0xd4,%edi
ffffffff80103c21:	e8 ae fe ff ff       	callq  ffffffff80103ad4 <lapicw>
  lapicw(LINT1, MASKED);
ffffffff80103c26:	be 00 00 01 00       	mov    $0x10000,%esi
ffffffff80103c2b:	bf d8 00 00 00       	mov    $0xd8,%edi
ffffffff80103c30:	e8 9f fe ff ff       	callq  ffffffff80103ad4 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
ffffffff80103c35:	48 8b 05 04 ca 08 00 	mov    0x8ca04(%rip),%rax        # ffffffff80190640 <lapic>
ffffffff80103c3c:	48 83 c0 30          	add    $0x30,%rax
ffffffff80103c40:	8b 00                	mov    (%rax),%eax
ffffffff80103c42:	c1 e8 10             	shr    $0x10,%eax
ffffffff80103c45:	0f b6 c0             	movzbl %al,%eax
ffffffff80103c48:	83 f8 03             	cmp    $0x3,%eax
ffffffff80103c4b:	76 0f                	jbe    ffffffff80103c5c <lapicinit+0x9f>
    lapicw(PCINT, MASKED);
ffffffff80103c4d:	be 00 00 01 00       	mov    $0x10000,%esi
ffffffff80103c52:	bf d0 00 00 00       	mov    $0xd0,%edi
ffffffff80103c57:	e8 78 fe ff ff       	callq  ffffffff80103ad4 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
ffffffff80103c5c:	be 33 00 00 00       	mov    $0x33,%esi
ffffffff80103c61:	bf dc 00 00 00       	mov    $0xdc,%edi
ffffffff80103c66:	e8 69 fe ff ff       	callq  ffffffff80103ad4 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
ffffffff80103c6b:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80103c70:	bf a0 00 00 00       	mov    $0xa0,%edi
ffffffff80103c75:	e8 5a fe ff ff       	callq  ffffffff80103ad4 <lapicw>
  lapicw(ESR, 0);
ffffffff80103c7a:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80103c7f:	bf a0 00 00 00       	mov    $0xa0,%edi
ffffffff80103c84:	e8 4b fe ff ff       	callq  ffffffff80103ad4 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
ffffffff80103c89:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80103c8e:	bf 2c 00 00 00       	mov    $0x2c,%edi
ffffffff80103c93:	e8 3c fe ff ff       	callq  ffffffff80103ad4 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
ffffffff80103c98:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80103c9d:	bf c4 00 00 00       	mov    $0xc4,%edi
ffffffff80103ca2:	e8 2d fe ff ff       	callq  ffffffff80103ad4 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
ffffffff80103ca7:	be 00 85 08 00       	mov    $0x88500,%esi
ffffffff80103cac:	bf c0 00 00 00       	mov    $0xc0,%edi
ffffffff80103cb1:	e8 1e fe ff ff       	callq  ffffffff80103ad4 <lapicw>
  while(lapic[ICRLO] & DELIVS)
ffffffff80103cb6:	90                   	nop
ffffffff80103cb7:	48 8b 05 82 c9 08 00 	mov    0x8c982(%rip),%rax        # ffffffff80190640 <lapic>
ffffffff80103cbe:	48 05 00 03 00 00    	add    $0x300,%rax
ffffffff80103cc4:	8b 00                	mov    (%rax),%eax
ffffffff80103cc6:	25 00 10 00 00       	and    $0x1000,%eax
ffffffff80103ccb:	85 c0                	test   %eax,%eax
ffffffff80103ccd:	75 e8                	jne    ffffffff80103cb7 <lapicinit+0xfa>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
ffffffff80103ccf:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80103cd4:	bf 20 00 00 00       	mov    $0x20,%edi
ffffffff80103cd9:	e8 f6 fd ff ff       	callq  ffffffff80103ad4 <lapicw>
ffffffff80103cde:	eb 01                	jmp    ffffffff80103ce1 <lapicinit+0x124>

void
lapicinit(void)
{
  if(!lapic) 
    return;
ffffffff80103ce0:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
ffffffff80103ce1:	5d                   	pop    %rbp
ffffffff80103ce2:	c3                   	retq   

ffffffff80103ce3 <cpunum>:
// This is only used during secondary processor startup.
// cpu->id is the fast way to get the cpu number, once the
// processor is fully started.
int
cpunum(void)
{
ffffffff80103ce3:	55                   	push   %rbp
ffffffff80103ce4:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103ce7:	48 83 ec 10          	sub    $0x10,%rsp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
ffffffff80103ceb:	e8 d0 fd ff ff       	callq  ffffffff80103ac0 <readeflags>
ffffffff80103cf0:	25 00 02 00 00       	and    $0x200,%eax
ffffffff80103cf5:	48 85 c0             	test   %rax,%rax
ffffffff80103cf8:	74 2b                	je     ffffffff80103d25 <cpunum+0x42>
    static int n;
    if(n++ == 0)
ffffffff80103cfa:	8b 05 48 c9 08 00    	mov    0x8c948(%rip),%eax        # ffffffff80190648 <n.1926>
ffffffff80103d00:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80103d03:	89 15 3f c9 08 00    	mov    %edx,0x8c93f(%rip)        # ffffffff80190648 <n.1926>
ffffffff80103d09:	85 c0                	test   %eax,%eax
ffffffff80103d0b:	75 18                	jne    ffffffff80103d25 <cpunum+0x42>
      cprintf("cpu called from %x with interrupts enabled\n",
ffffffff80103d0d:	48 8b 45 08          	mov    0x8(%rbp),%rax
ffffffff80103d11:	48 89 c6             	mov    %rax,%rsi
ffffffff80103d14:	48 c7 c7 08 a9 10 80 	mov    $0xffffffff8010a908,%rdi
ffffffff80103d1b:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103d20:	e8 7d c8 ff ff       	callq  ffffffff801005a2 <cprintf>
        __builtin_return_address(0));
  }

  if(!lapic)
ffffffff80103d25:	48 8b 05 14 c9 08 00 	mov    0x8c914(%rip),%rax        # ffffffff80190640 <lapic>
ffffffff80103d2c:	48 85 c0             	test   %rax,%rax
ffffffff80103d2f:	75 07                	jne    ffffffff80103d38 <cpunum+0x55>
    return 0;
ffffffff80103d31:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80103d36:	eb 5c                	jmp    ffffffff80103d94 <cpunum+0xb1>

  id = lapic[ID]>>24;
ffffffff80103d38:	48 8b 05 01 c9 08 00 	mov    0x8c901(%rip),%rax        # ffffffff80190640 <lapic>
ffffffff80103d3f:	48 83 c0 20          	add    $0x20,%rax
ffffffff80103d43:	8b 00                	mov    (%rax),%eax
ffffffff80103d45:	c1 e8 18             	shr    $0x18,%eax
ffffffff80103d48:	89 45 f8             	mov    %eax,-0x8(%rbp)
  for (n = 0; n < ncpu; n++)
ffffffff80103d4b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80103d52:	eb 30                	jmp    ffffffff80103d84 <cpunum+0xa1>
    if (id == cpus[n].apicid)
ffffffff80103d54:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103d57:	48 98                	cltq   
ffffffff80103d59:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80103d5d:	48 89 c2             	mov    %rax,%rdx
ffffffff80103d60:	48 c1 e2 04          	shl    $0x4,%rdx
ffffffff80103d64:	48 29 c2             	sub    %rax,%rdx
ffffffff80103d67:	48 89 d0             	mov    %rdx,%rax
ffffffff80103d6a:	48 05 61 07 19 80    	add    $0xffffffff80190761,%rax
ffffffff80103d70:	0f b6 00             	movzbl (%rax),%eax
ffffffff80103d73:	0f b6 c0             	movzbl %al,%eax
ffffffff80103d76:	3b 45 f8             	cmp    -0x8(%rbp),%eax
ffffffff80103d79:	75 05                	jne    ffffffff80103d80 <cpunum+0x9d>
      return n;
ffffffff80103d7b:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103d7e:	eb 14                	jmp    ffffffff80103d94 <cpunum+0xb1>

  if(!lapic)
    return 0;

  id = lapic[ID]>>24;
  for (n = 0; n < ncpu; n++)
ffffffff80103d80:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80103d84:	8b 05 5a d1 08 00    	mov    0x8d15a(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff80103d8a:	39 45 fc             	cmp    %eax,-0x4(%rbp)
ffffffff80103d8d:	7c c5                	jl     ffffffff80103d54 <cpunum+0x71>
    if (id == cpus[n].apicid)
      return n;

  return 0;
ffffffff80103d8f:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80103d94:	c9                   	leaveq 
ffffffff80103d95:	c3                   	retq   

ffffffff80103d96 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
ffffffff80103d96:	55                   	push   %rbp
ffffffff80103d97:	48 89 e5             	mov    %rsp,%rbp
  if(lapic)
ffffffff80103d9a:	48 8b 05 9f c8 08 00 	mov    0x8c89f(%rip),%rax        # ffffffff80190640 <lapic>
ffffffff80103da1:	48 85 c0             	test   %rax,%rax
ffffffff80103da4:	74 0f                	je     ffffffff80103db5 <lapiceoi+0x1f>
    lapicw(EOI, 0);
ffffffff80103da6:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80103dab:	bf 2c 00 00 00       	mov    $0x2c,%edi
ffffffff80103db0:	e8 1f fd ff ff       	callq  ffffffff80103ad4 <lapicw>
}
ffffffff80103db5:	90                   	nop
ffffffff80103db6:	5d                   	pop    %rbp
ffffffff80103db7:	c3                   	retq   

ffffffff80103db8 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
ffffffff80103db8:	55                   	push   %rbp
ffffffff80103db9:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103dbc:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80103dc0:	89 7d fc             	mov    %edi,-0x4(%rbp)
}
ffffffff80103dc3:	90                   	nop
ffffffff80103dc4:	c9                   	leaveq 
ffffffff80103dc5:	c3                   	retq   

ffffffff80103dc6 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
ffffffff80103dc6:	55                   	push   %rbp
ffffffff80103dc7:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103dca:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff80103dce:	89 f8                	mov    %edi,%eax
ffffffff80103dd0:	89 75 e8             	mov    %esi,-0x18(%rbp)
ffffffff80103dd3:	88 45 ec             	mov    %al,-0x14(%rbp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
ffffffff80103dd6:	be 0f 00 00 00       	mov    $0xf,%esi
ffffffff80103ddb:	bf 70 00 00 00       	mov    $0x70,%edi
ffffffff80103de0:	e8 bc fc ff ff       	callq  ffffffff80103aa1 <outb>
  outb(CMOS_PORT+1, 0x0A);
ffffffff80103de5:	be 0a 00 00 00       	mov    $0xa,%esi
ffffffff80103dea:	bf 71 00 00 00       	mov    $0x71,%edi
ffffffff80103def:	e8 ad fc ff ff       	callq  ffffffff80103aa1 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
ffffffff80103df4:	48 c7 45 f0 67 04 00 	movq   $0xffffffff80000467,-0x10(%rbp)
ffffffff80103dfb:	80 
  wrv[0] = 0;
ffffffff80103dfc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80103e00:	66 c7 00 00 00       	movw   $0x0,(%rax)
  wrv[1] = addr >> 4;
ffffffff80103e05:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80103e09:	48 83 c0 02          	add    $0x2,%rax
ffffffff80103e0d:	8b 55 e8             	mov    -0x18(%rbp),%edx
ffffffff80103e10:	c1 ea 04             	shr    $0x4,%edx
ffffffff80103e13:	66 89 10             	mov    %dx,(%rax)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
ffffffff80103e16:	0f b6 45 ec          	movzbl -0x14(%rbp),%eax
ffffffff80103e1a:	c1 e0 18             	shl    $0x18,%eax
ffffffff80103e1d:	89 c6                	mov    %eax,%esi
ffffffff80103e1f:	bf c4 00 00 00       	mov    $0xc4,%edi
ffffffff80103e24:	e8 ab fc ff ff       	callq  ffffffff80103ad4 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
ffffffff80103e29:	be 00 c5 00 00       	mov    $0xc500,%esi
ffffffff80103e2e:	bf c0 00 00 00       	mov    $0xc0,%edi
ffffffff80103e33:	e8 9c fc ff ff       	callq  ffffffff80103ad4 <lapicw>
  microdelay(200);
ffffffff80103e38:	bf c8 00 00 00       	mov    $0xc8,%edi
ffffffff80103e3d:	e8 76 ff ff ff       	callq  ffffffff80103db8 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
ffffffff80103e42:	be 00 85 00 00       	mov    $0x8500,%esi
ffffffff80103e47:	bf c0 00 00 00       	mov    $0xc0,%edi
ffffffff80103e4c:	e8 83 fc ff ff       	callq  ffffffff80103ad4 <lapicw>
  microdelay(10000);
ffffffff80103e51:	bf 10 27 00 00       	mov    $0x2710,%edi
ffffffff80103e56:	e8 5d ff ff ff       	callq  ffffffff80103db8 <microdelay>
  
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  for(i = 0; i < 2; i++){
ffffffff80103e5b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80103e62:	eb 36                	jmp    ffffffff80103e9a <lapicstartap+0xd4>
    lapicw(ICRHI, apicid<<24);
ffffffff80103e64:	0f b6 45 ec          	movzbl -0x14(%rbp),%eax
ffffffff80103e68:	c1 e0 18             	shl    $0x18,%eax
ffffffff80103e6b:	89 c6                	mov    %eax,%esi
ffffffff80103e6d:	bf c4 00 00 00       	mov    $0xc4,%edi
ffffffff80103e72:	e8 5d fc ff ff       	callq  ffffffff80103ad4 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
ffffffff80103e77:	8b 45 e8             	mov    -0x18(%rbp),%eax
ffffffff80103e7a:	c1 e8 0c             	shr    $0xc,%eax
ffffffff80103e7d:	80 cc 06             	or     $0x6,%ah
ffffffff80103e80:	89 c6                	mov    %eax,%esi
ffffffff80103e82:	bf c0 00 00 00       	mov    $0xc0,%edi
ffffffff80103e87:	e8 48 fc ff ff       	callq  ffffffff80103ad4 <lapicw>
    microdelay(200);
ffffffff80103e8c:	bf c8 00 00 00       	mov    $0xc8,%edi
ffffffff80103e91:	e8 22 ff ff ff       	callq  ffffffff80103db8 <microdelay>
  
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  for(i = 0; i < 2; i++){
ffffffff80103e96:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80103e9a:	83 7d fc 01          	cmpl   $0x1,-0x4(%rbp)
ffffffff80103e9e:	7e c4                	jle    ffffffff80103e64 <lapicstartap+0x9e>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
ffffffff80103ea0:	90                   	nop
ffffffff80103ea1:	c9                   	leaveq 
ffffffff80103ea2:	c3                   	retq   

ffffffff80103ea3 <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
ffffffff80103ea3:	55                   	push   %rbp
ffffffff80103ea4:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103ea7:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80103eab:	89 7d fc             	mov    %edi,-0x4(%rbp)
  outb(CMOS_PORT,  reg);
ffffffff80103eae:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103eb1:	0f b6 c0             	movzbl %al,%eax
ffffffff80103eb4:	89 c6                	mov    %eax,%esi
ffffffff80103eb6:	bf 70 00 00 00       	mov    $0x70,%edi
ffffffff80103ebb:	e8 e1 fb ff ff       	callq  ffffffff80103aa1 <outb>
  microdelay(200);
ffffffff80103ec0:	bf c8 00 00 00       	mov    $0xc8,%edi
ffffffff80103ec5:	e8 ee fe ff ff       	callq  ffffffff80103db8 <microdelay>

  return inb(CMOS_RETURN);
ffffffff80103eca:	bf 71 00 00 00       	mov    $0x71,%edi
ffffffff80103ecf:	e8 af fb ff ff       	callq  ffffffff80103a83 <inb>
ffffffff80103ed4:	0f b6 c0             	movzbl %al,%eax
}
ffffffff80103ed7:	c9                   	leaveq 
ffffffff80103ed8:	c3                   	retq   

ffffffff80103ed9 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
ffffffff80103ed9:	55                   	push   %rbp
ffffffff80103eda:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103edd:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80103ee1:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  r->second = cmos_read(SECS);
ffffffff80103ee5:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80103eea:	e8 b4 ff ff ff       	callq  ffffffff80103ea3 <cmos_read>
ffffffff80103eef:	89 c2                	mov    %eax,%edx
ffffffff80103ef1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103ef5:	89 10                	mov    %edx,(%rax)
  r->minute = cmos_read(MINS);
ffffffff80103ef7:	bf 02 00 00 00       	mov    $0x2,%edi
ffffffff80103efc:	e8 a2 ff ff ff       	callq  ffffffff80103ea3 <cmos_read>
ffffffff80103f01:	89 c2                	mov    %eax,%edx
ffffffff80103f03:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103f07:	89 50 04             	mov    %edx,0x4(%rax)
  r->hour   = cmos_read(HOURS);
ffffffff80103f0a:	bf 04 00 00 00       	mov    $0x4,%edi
ffffffff80103f0f:	e8 8f ff ff ff       	callq  ffffffff80103ea3 <cmos_read>
ffffffff80103f14:	89 c2                	mov    %eax,%edx
ffffffff80103f16:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103f1a:	89 50 08             	mov    %edx,0x8(%rax)
  r->day    = cmos_read(DAY);
ffffffff80103f1d:	bf 07 00 00 00       	mov    $0x7,%edi
ffffffff80103f22:	e8 7c ff ff ff       	callq  ffffffff80103ea3 <cmos_read>
ffffffff80103f27:	89 c2                	mov    %eax,%edx
ffffffff80103f29:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103f2d:	89 50 0c             	mov    %edx,0xc(%rax)
  r->month  = cmos_read(MONTH);
ffffffff80103f30:	bf 08 00 00 00       	mov    $0x8,%edi
ffffffff80103f35:	e8 69 ff ff ff       	callq  ffffffff80103ea3 <cmos_read>
ffffffff80103f3a:	89 c2                	mov    %eax,%edx
ffffffff80103f3c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103f40:	89 50 10             	mov    %edx,0x10(%rax)
  r->year   = cmos_read(YEAR);
ffffffff80103f43:	bf 09 00 00 00       	mov    $0x9,%edi
ffffffff80103f48:	e8 56 ff ff ff       	callq  ffffffff80103ea3 <cmos_read>
ffffffff80103f4d:	89 c2                	mov    %eax,%edx
ffffffff80103f4f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80103f53:	89 50 14             	mov    %edx,0x14(%rax)
}
ffffffff80103f56:	90                   	nop
ffffffff80103f57:	c9                   	leaveq 
ffffffff80103f58:	c3                   	retq   

ffffffff80103f59 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
ffffffff80103f59:	55                   	push   %rbp
ffffffff80103f5a:	48 89 e5             	mov    %rsp,%rbp
ffffffff80103f5d:	48 83 ec 50          	sub    $0x50,%rsp
ffffffff80103f61:	48 89 7d b8          	mov    %rdi,-0x48(%rbp)
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
ffffffff80103f65:	bf 0b 00 00 00       	mov    $0xb,%edi
ffffffff80103f6a:	e8 34 ff ff ff       	callq  ffffffff80103ea3 <cmos_read>
ffffffff80103f6f:	89 45 fc             	mov    %eax,-0x4(%rbp)

  bcd = (sb & (1 << 2)) == 0;
ffffffff80103f72:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80103f75:	83 e0 04             	and    $0x4,%eax
ffffffff80103f78:	85 c0                	test   %eax,%eax
ffffffff80103f7a:	0f 94 c0             	sete   %al
ffffffff80103f7d:	0f b6 c0             	movzbl %al,%eax
ffffffff80103f80:	89 45 f8             	mov    %eax,-0x8(%rbp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
ffffffff80103f83:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
ffffffff80103f87:	48 89 c7             	mov    %rax,%rdi
ffffffff80103f8a:	e8 4a ff ff ff       	callq  ffffffff80103ed9 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
ffffffff80103f8f:	bf 0a 00 00 00       	mov    $0xa,%edi
ffffffff80103f94:	e8 0a ff ff ff       	callq  ffffffff80103ea3 <cmos_read>
ffffffff80103f99:	25 80 00 00 00       	and    $0x80,%eax
ffffffff80103f9e:	85 c0                	test   %eax,%eax
ffffffff80103fa0:	75 2a                	jne    ffffffff80103fcc <cmostime+0x73>
        continue;
    fill_rtcdate(&t2);
ffffffff80103fa2:	48 8d 45 c0          	lea    -0x40(%rbp),%rax
ffffffff80103fa6:	48 89 c7             	mov    %rax,%rdi
ffffffff80103fa9:	e8 2b ff ff ff       	callq  ffffffff80103ed9 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
ffffffff80103fae:	48 8d 4d c0          	lea    -0x40(%rbp),%rcx
ffffffff80103fb2:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
ffffffff80103fb6:	ba 18 00 00 00       	mov    $0x18,%edx
ffffffff80103fbb:	48 89 ce             	mov    %rcx,%rsi
ffffffff80103fbe:	48 89 c7             	mov    %rax,%rdi
ffffffff80103fc1:	e8 c7 2c 00 00       	callq  ffffffff80106c8d <memcmp>
ffffffff80103fc6:	85 c0                	test   %eax,%eax
ffffffff80103fc8:	74 05                	je     ffffffff80103fcf <cmostime+0x76>
ffffffff80103fca:	eb b7                	jmp    ffffffff80103f83 <cmostime+0x2a>

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
ffffffff80103fcc:	90                   	nop
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
ffffffff80103fcd:	eb b4                	jmp    ffffffff80103f83 <cmostime+0x2a>
    fill_rtcdate(&t1);
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
ffffffff80103fcf:	90                   	nop
  }

  // convert
  if (bcd) {
ffffffff80103fd0:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
ffffffff80103fd4:	0f 84 b4 00 00 00    	je     ffffffff8010408e <cmostime+0x135>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
ffffffff80103fda:	8b 45 e0             	mov    -0x20(%rbp),%eax
ffffffff80103fdd:	c1 e8 04             	shr    $0x4,%eax
ffffffff80103fe0:	89 c2                	mov    %eax,%edx
ffffffff80103fe2:	89 d0                	mov    %edx,%eax
ffffffff80103fe4:	c1 e0 02             	shl    $0x2,%eax
ffffffff80103fe7:	01 d0                	add    %edx,%eax
ffffffff80103fe9:	01 c0                	add    %eax,%eax
ffffffff80103feb:	89 c2                	mov    %eax,%edx
ffffffff80103fed:	8b 45 e0             	mov    -0x20(%rbp),%eax
ffffffff80103ff0:	83 e0 0f             	and    $0xf,%eax
ffffffff80103ff3:	01 d0                	add    %edx,%eax
ffffffff80103ff5:	89 45 e0             	mov    %eax,-0x20(%rbp)
    CONV(minute);
ffffffff80103ff8:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80103ffb:	c1 e8 04             	shr    $0x4,%eax
ffffffff80103ffe:	89 c2                	mov    %eax,%edx
ffffffff80104000:	89 d0                	mov    %edx,%eax
ffffffff80104002:	c1 e0 02             	shl    $0x2,%eax
ffffffff80104005:	01 d0                	add    %edx,%eax
ffffffff80104007:	01 c0                	add    %eax,%eax
ffffffff80104009:	89 c2                	mov    %eax,%edx
ffffffff8010400b:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff8010400e:	83 e0 0f             	and    $0xf,%eax
ffffffff80104011:	01 d0                	add    %edx,%eax
ffffffff80104013:	89 45 e4             	mov    %eax,-0x1c(%rbp)
    CONV(hour  );
ffffffff80104016:	8b 45 e8             	mov    -0x18(%rbp),%eax
ffffffff80104019:	c1 e8 04             	shr    $0x4,%eax
ffffffff8010401c:	89 c2                	mov    %eax,%edx
ffffffff8010401e:	89 d0                	mov    %edx,%eax
ffffffff80104020:	c1 e0 02             	shl    $0x2,%eax
ffffffff80104023:	01 d0                	add    %edx,%eax
ffffffff80104025:	01 c0                	add    %eax,%eax
ffffffff80104027:	89 c2                	mov    %eax,%edx
ffffffff80104029:	8b 45 e8             	mov    -0x18(%rbp),%eax
ffffffff8010402c:	83 e0 0f             	and    $0xf,%eax
ffffffff8010402f:	01 d0                	add    %edx,%eax
ffffffff80104031:	89 45 e8             	mov    %eax,-0x18(%rbp)
    CONV(day   );
ffffffff80104034:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80104037:	c1 e8 04             	shr    $0x4,%eax
ffffffff8010403a:	89 c2                	mov    %eax,%edx
ffffffff8010403c:	89 d0                	mov    %edx,%eax
ffffffff8010403e:	c1 e0 02             	shl    $0x2,%eax
ffffffff80104041:	01 d0                	add    %edx,%eax
ffffffff80104043:	01 c0                	add    %eax,%eax
ffffffff80104045:	89 c2                	mov    %eax,%edx
ffffffff80104047:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff8010404a:	83 e0 0f             	and    $0xf,%eax
ffffffff8010404d:	01 d0                	add    %edx,%eax
ffffffff8010404f:	89 45 ec             	mov    %eax,-0x14(%rbp)
    CONV(month );
ffffffff80104052:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff80104055:	c1 e8 04             	shr    $0x4,%eax
ffffffff80104058:	89 c2                	mov    %eax,%edx
ffffffff8010405a:	89 d0                	mov    %edx,%eax
ffffffff8010405c:	c1 e0 02             	shl    $0x2,%eax
ffffffff8010405f:	01 d0                	add    %edx,%eax
ffffffff80104061:	01 c0                	add    %eax,%eax
ffffffff80104063:	89 c2                	mov    %eax,%edx
ffffffff80104065:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff80104068:	83 e0 0f             	and    $0xf,%eax
ffffffff8010406b:	01 d0                	add    %edx,%eax
ffffffff8010406d:	89 45 f0             	mov    %eax,-0x10(%rbp)
    CONV(year  );
ffffffff80104070:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80104073:	c1 e8 04             	shr    $0x4,%eax
ffffffff80104076:	89 c2                	mov    %eax,%edx
ffffffff80104078:	89 d0                	mov    %edx,%eax
ffffffff8010407a:	c1 e0 02             	shl    $0x2,%eax
ffffffff8010407d:	01 d0                	add    %edx,%eax
ffffffff8010407f:	01 c0                	add    %eax,%eax
ffffffff80104081:	89 c2                	mov    %eax,%edx
ffffffff80104083:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80104086:	83 e0 0f             	and    $0xf,%eax
ffffffff80104089:	01 d0                	add    %edx,%eax
ffffffff8010408b:	89 45 f4             	mov    %eax,-0xc(%rbp)
#undef     CONV
  }

  *r = t1;
ffffffff8010408e:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff80104092:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80104096:	48 89 10             	mov    %rdx,(%rax)
ffffffff80104099:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff8010409d:	48 89 50 08          	mov    %rdx,0x8(%rax)
ffffffff801040a1:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff801040a5:	48 89 50 10          	mov    %rdx,0x10(%rax)
  r->year += 2000;
ffffffff801040a9:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff801040ad:	8b 40 14             	mov    0x14(%rax),%eax
ffffffff801040b0:	8d 90 d0 07 00 00    	lea    0x7d0(%rax),%edx
ffffffff801040b6:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff801040ba:	89 50 14             	mov    %edx,0x14(%rax)
}
ffffffff801040bd:	90                   	nop
ffffffff801040be:	c9                   	leaveq 
ffffffff801040bf:	c3                   	retq   

ffffffff801040c0 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(void)
{
ffffffff801040c0:	55                   	push   %rbp
ffffffff801040c1:	48 89 e5             	mov    %rsp,%rbp
ffffffff801040c4:	48 83 ec 10          	sub    $0x10,%rsp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
ffffffff801040c8:	48 c7 c6 34 a9 10 80 	mov    $0xffffffff8010a934,%rsi
ffffffff801040cf:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff801040d6:	e8 8e 27 00 00       	callq  ffffffff80106869 <initlock>
  readsb(ROOTDEV, &sb);
ffffffff801040db:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff801040df:	48 89 c6             	mov    %rax,%rsi
ffffffff801040e2:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff801040e7:	e8 61 e1 ff ff       	callq  ffffffff8010224d <readsb>
  log.start = sb.size - sb.nlog;
ffffffff801040ec:	8b 55 f0             	mov    -0x10(%rbp),%edx
ffffffff801040ef:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801040f2:	29 c2                	sub    %eax,%edx
ffffffff801040f4:	89 d0                	mov    %edx,%eax
ffffffff801040f6:	89 05 cc c5 08 00    	mov    %eax,0x8c5cc(%rip)        # ffffffff801906c8 <log+0x68>
  log.size = sb.nlog;
ffffffff801040fc:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801040ff:	89 05 c7 c5 08 00    	mov    %eax,0x8c5c7(%rip)        # ffffffff801906cc <log+0x6c>
  log.dev = ROOTDEV;
ffffffff80104105:	c7 05 c9 c5 08 00 01 	movl   $0x1,0x8c5c9(%rip)        # ffffffff801906d8 <log+0x78>
ffffffff8010410c:	00 00 00 
  recover_from_log();
ffffffff8010410f:	e8 c6 01 00 00       	callq  ffffffff801042da <recover_from_log>
}
ffffffff80104114:	90                   	nop
ffffffff80104115:	c9                   	leaveq 
ffffffff80104116:	c3                   	retq   

ffffffff80104117 <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
ffffffff80104117:	55                   	push   %rbp
ffffffff80104118:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010411b:	48 83 ec 20          	sub    $0x20,%rsp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
ffffffff8010411f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80104126:	e9 90 00 00 00       	jmpq   ffffffff801041bb <install_trans+0xa4>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
ffffffff8010412b:	8b 15 97 c5 08 00    	mov    0x8c597(%rip),%edx        # ffffffff801906c8 <log+0x68>
ffffffff80104131:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80104134:	01 d0                	add    %edx,%eax
ffffffff80104136:	83 c0 01             	add    $0x1,%eax
ffffffff80104139:	89 c2                	mov    %eax,%edx
ffffffff8010413b:	8b 05 97 c5 08 00    	mov    0x8c597(%rip),%eax        # ffffffff801906d8 <log+0x78>
ffffffff80104141:	89 d6                	mov    %edx,%esi
ffffffff80104143:	89 c7                	mov    %eax,%edi
ffffffff80104145:	e8 8c c1 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff8010414a:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
ffffffff8010414e:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80104151:	48 98                	cltq   
ffffffff80104153:	48 83 c0 1c          	add    $0x1c,%rax
ffffffff80104157:	8b 04 85 70 06 19 80 	mov    -0x7fe6f990(,%rax,4),%eax
ffffffff8010415e:	89 c2                	mov    %eax,%edx
ffffffff80104160:	8b 05 72 c5 08 00    	mov    0x8c572(%rip),%eax        # ffffffff801906d8 <log+0x78>
ffffffff80104166:	89 d6                	mov    %edx,%esi
ffffffff80104168:	89 c7                	mov    %eax,%edi
ffffffff8010416a:	e8 67 c1 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff8010416f:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
ffffffff80104173:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104177:	48 8d 48 28          	lea    0x28(%rax),%rcx
ffffffff8010417b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010417f:	48 83 c0 28          	add    $0x28,%rax
ffffffff80104183:	ba 00 02 00 00       	mov    $0x200,%edx
ffffffff80104188:	48 89 ce             	mov    %rcx,%rsi
ffffffff8010418b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010418e:	e8 69 2b 00 00       	callq  ffffffff80106cfc <memmove>
    bwrite(dbuf);  // write dst to disk
ffffffff80104193:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104197:	48 89 c7             	mov    %rax,%rdi
ffffffff8010419a:	e8 77 c1 ff ff       	callq  ffffffff80100316 <bwrite>
    brelse(lbuf); 
ffffffff8010419f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801041a3:	48 89 c7             	mov    %rax,%rdi
ffffffff801041a6:	e8 b0 c1 ff ff       	callq  ffffffff8010035b <brelse>
    brelse(dbuf);
ffffffff801041ab:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801041af:	48 89 c7             	mov    %rax,%rdi
ffffffff801041b2:	e8 a4 c1 ff ff       	callq  ffffffff8010035b <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
ffffffff801041b7:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801041bb:	8b 05 1b c5 08 00    	mov    0x8c51b(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff801041c1:	3b 45 fc             	cmp    -0x4(%rbp),%eax
ffffffff801041c4:	0f 8f 61 ff ff ff    	jg     ffffffff8010412b <install_trans+0x14>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
ffffffff801041ca:	90                   	nop
ffffffff801041cb:	c9                   	leaveq 
ffffffff801041cc:	c3                   	retq   

ffffffff801041cd <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
ffffffff801041cd:	55                   	push   %rbp
ffffffff801041ce:	48 89 e5             	mov    %rsp,%rbp
ffffffff801041d1:	48 83 ec 20          	sub    $0x20,%rsp
  struct buf *buf = bread(log.dev, log.start);
ffffffff801041d5:	8b 05 ed c4 08 00    	mov    0x8c4ed(%rip),%eax        # ffffffff801906c8 <log+0x68>
ffffffff801041db:	89 c2                	mov    %eax,%edx
ffffffff801041dd:	8b 05 f5 c4 08 00    	mov    0x8c4f5(%rip),%eax        # ffffffff801906d8 <log+0x78>
ffffffff801041e3:	89 d6                	mov    %edx,%esi
ffffffff801041e5:	89 c7                	mov    %eax,%edi
ffffffff801041e7:	e8 ea c0 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff801041ec:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  struct logheader *lh = (struct logheader *) (buf->data);
ffffffff801041f0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801041f4:	48 83 c0 28          	add    $0x28,%rax
ffffffff801041f8:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  int i;
  log.lh.n = lh->n;
ffffffff801041fc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104200:	8b 00                	mov    (%rax),%eax
ffffffff80104202:	89 05 d4 c4 08 00    	mov    %eax,0x8c4d4(%rip)        # ffffffff801906dc <log+0x7c>
  for (i = 0; i < log.lh.n; i++) {
ffffffff80104208:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff8010420f:	eb 23                	jmp    ffffffff80104234 <read_head+0x67>
    log.lh.block[i] = lh->block[i];
ffffffff80104211:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104215:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80104218:	48 63 d2             	movslq %edx,%rdx
ffffffff8010421b:	8b 44 90 04          	mov    0x4(%rax,%rdx,4),%eax
ffffffff8010421f:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80104222:	48 63 d2             	movslq %edx,%rdx
ffffffff80104225:	48 83 c2 1c          	add    $0x1c,%rdx
ffffffff80104229:	89 04 95 70 06 19 80 	mov    %eax,-0x7fe6f990(,%rdx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
ffffffff80104230:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80104234:	8b 05 a2 c4 08 00    	mov    0x8c4a2(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff8010423a:	3b 45 fc             	cmp    -0x4(%rbp),%eax
ffffffff8010423d:	7f d2                	jg     ffffffff80104211 <read_head+0x44>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
ffffffff8010423f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104243:	48 89 c7             	mov    %rax,%rdi
ffffffff80104246:	e8 10 c1 ff ff       	callq  ffffffff8010035b <brelse>
}
ffffffff8010424b:	90                   	nop
ffffffff8010424c:	c9                   	leaveq 
ffffffff8010424d:	c3                   	retq   

ffffffff8010424e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
ffffffff8010424e:	55                   	push   %rbp
ffffffff8010424f:	48 89 e5             	mov    %rsp,%rbp
ffffffff80104252:	48 83 ec 20          	sub    $0x20,%rsp
  struct buf *buf = bread(log.dev, log.start);
ffffffff80104256:	8b 05 6c c4 08 00    	mov    0x8c46c(%rip),%eax        # ffffffff801906c8 <log+0x68>
ffffffff8010425c:	89 c2                	mov    %eax,%edx
ffffffff8010425e:	8b 05 74 c4 08 00    	mov    0x8c474(%rip),%eax        # ffffffff801906d8 <log+0x78>
ffffffff80104264:	89 d6                	mov    %edx,%esi
ffffffff80104266:	89 c7                	mov    %eax,%edi
ffffffff80104268:	e8 69 c0 ff ff       	callq  ffffffff801002d6 <bread>
ffffffff8010426d:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  struct logheader *hb = (struct logheader *) (buf->data);
ffffffff80104271:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104275:	48 83 c0 28          	add    $0x28,%rax
ffffffff80104279:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  int i;
  hb->n = log.lh.n;
ffffffff8010427d:	8b 15 59 c4 08 00    	mov    0x8c459(%rip),%edx        # ffffffff801906dc <log+0x7c>
ffffffff80104283:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104287:	89 10                	mov    %edx,(%rax)
  for (i = 0; i < log.lh.n; i++) {
ffffffff80104289:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80104290:	eb 22                	jmp    ffffffff801042b4 <write_head+0x66>
    hb->block[i] = log.lh.block[i];
ffffffff80104292:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80104295:	48 98                	cltq   
ffffffff80104297:	48 83 c0 1c          	add    $0x1c,%rax
ffffffff8010429b:	8b 0c 85 70 06 19 80 	mov    -0x7fe6f990(,%rax,4),%ecx
ffffffff801042a2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801042a6:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801042a9:	48 63 d2             	movslq %edx,%rdx
ffffffff801042ac:	89 4c 90 04          	mov    %ecx,0x4(%rax,%rdx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
ffffffff801042b0:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801042b4:	8b 05 22 c4 08 00    	mov    0x8c422(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff801042ba:	3b 45 fc             	cmp    -0x4(%rbp),%eax
ffffffff801042bd:	7f d3                	jg     ffffffff80104292 <write_head+0x44>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
ffffffff801042bf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801042c3:	48 89 c7             	mov    %rax,%rdi
ffffffff801042c6:	e8 4b c0 ff ff       	callq  ffffffff80100316 <bwrite>
  brelse(buf);
ffffffff801042cb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801042cf:	48 89 c7             	mov    %rax,%rdi
ffffffff801042d2:	e8 84 c0 ff ff       	callq  ffffffff8010035b <brelse>
}
ffffffff801042d7:	90                   	nop
ffffffff801042d8:	c9                   	leaveq 
ffffffff801042d9:	c3                   	retq   

ffffffff801042da <recover_from_log>:

static void
recover_from_log(void)
{
ffffffff801042da:	55                   	push   %rbp
ffffffff801042db:	48 89 e5             	mov    %rsp,%rbp
  read_head();      
ffffffff801042de:	e8 ea fe ff ff       	callq  ffffffff801041cd <read_head>
  install_trans(); // if committed, copy from log to disk
ffffffff801042e3:	e8 2f fe ff ff       	callq  ffffffff80104117 <install_trans>
  log.lh.n = 0;
ffffffff801042e8:	c7 05 ea c3 08 00 00 	movl   $0x0,0x8c3ea(%rip)        # ffffffff801906dc <log+0x7c>
ffffffff801042ef:	00 00 00 
  write_head(); // clear the log
ffffffff801042f2:	e8 57 ff ff ff       	callq  ffffffff8010424e <write_head>
}
ffffffff801042f7:	90                   	nop
ffffffff801042f8:	5d                   	pop    %rbp
ffffffff801042f9:	c3                   	retq   

ffffffff801042fa <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
ffffffff801042fa:	55                   	push   %rbp
ffffffff801042fb:	48 89 e5             	mov    %rsp,%rbp
  acquire(&log.lock);
ffffffff801042fe:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff80104305:	e8 94 25 00 00       	callq  ffffffff8010689e <acquire>
  while(1){
    if(log.committing){
ffffffff8010430a:	8b 05 c4 c3 08 00    	mov    0x8c3c4(%rip),%eax        # ffffffff801906d4 <log+0x74>
ffffffff80104310:	85 c0                	test   %eax,%eax
ffffffff80104312:	74 15                	je     ffffffff80104329 <begin_op+0x2f>
      sleep(&log, &log.lock);
ffffffff80104314:	48 c7 c6 60 06 19 80 	mov    $0xffffffff80190660,%rsi
ffffffff8010431b:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff80104322:	e8 fa 21 00 00       	callq  ffffffff80106521 <sleep>
ffffffff80104327:	eb e1                	jmp    ffffffff8010430a <begin_op+0x10>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
ffffffff80104329:	8b 0d ad c3 08 00    	mov    0x8c3ad(%rip),%ecx        # ffffffff801906dc <log+0x7c>
ffffffff8010432f:	8b 05 9b c3 08 00    	mov    0x8c39b(%rip),%eax        # ffffffff801906d0 <log+0x70>
ffffffff80104335:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80104338:	89 d0                	mov    %edx,%eax
ffffffff8010433a:	c1 e0 02             	shl    $0x2,%eax
ffffffff8010433d:	01 d0                	add    %edx,%eax
ffffffff8010433f:	01 c0                	add    %eax,%eax
ffffffff80104341:	01 c8                	add    %ecx,%eax
ffffffff80104343:	83 f8 1e             	cmp    $0x1e,%eax
ffffffff80104346:	7e 15                	jle    ffffffff8010435d <begin_op+0x63>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
ffffffff80104348:	48 c7 c6 60 06 19 80 	mov    $0xffffffff80190660,%rsi
ffffffff8010434f:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff80104356:	e8 c6 21 00 00       	callq  ffffffff80106521 <sleep>
ffffffff8010435b:	eb ad                	jmp    ffffffff8010430a <begin_op+0x10>
    } else {
      log.outstanding += 1;
ffffffff8010435d:	8b 05 6d c3 08 00    	mov    0x8c36d(%rip),%eax        # ffffffff801906d0 <log+0x70>
ffffffff80104363:	83 c0 01             	add    $0x1,%eax
ffffffff80104366:	89 05 64 c3 08 00    	mov    %eax,0x8c364(%rip)        # ffffffff801906d0 <log+0x70>
      release(&log.lock);
ffffffff8010436c:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff80104373:	e8 fd 25 00 00       	callq  ffffffff80106975 <release>
      break;
ffffffff80104378:	90                   	nop
    }
  }
}
ffffffff80104379:	90                   	nop
ffffffff8010437a:	5d                   	pop    %rbp
ffffffff8010437b:	c3                   	retq   

ffffffff8010437c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
ffffffff8010437c:	55                   	push   %rbp
ffffffff8010437d:	48 89 e5             	mov    %rsp,%rbp
ffffffff80104380:	48 83 ec 10          	sub    $0x10,%rsp
  int do_commit = 0;
ffffffff80104384:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)

  acquire(&log.lock);
ffffffff8010438b:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff80104392:	e8 07 25 00 00       	callq  ffffffff8010689e <acquire>
  log.outstanding -= 1;
ffffffff80104397:	8b 05 33 c3 08 00    	mov    0x8c333(%rip),%eax        # ffffffff801906d0 <log+0x70>
ffffffff8010439d:	83 e8 01             	sub    $0x1,%eax
ffffffff801043a0:	89 05 2a c3 08 00    	mov    %eax,0x8c32a(%rip)        # ffffffff801906d0 <log+0x70>
  if(log.committing)
ffffffff801043a6:	8b 05 28 c3 08 00    	mov    0x8c328(%rip),%eax        # ffffffff801906d4 <log+0x74>
ffffffff801043ac:	85 c0                	test   %eax,%eax
ffffffff801043ae:	74 0c                	je     ffffffff801043bc <end_op+0x40>
    panic("log.committing");
ffffffff801043b0:	48 c7 c7 38 a9 10 80 	mov    $0xffffffff8010a938,%rdi
ffffffff801043b7:	e8 43 c5 ff ff       	callq  ffffffff801008ff <panic>
  if(log.outstanding == 0){
ffffffff801043bc:	8b 05 0e c3 08 00    	mov    0x8c30e(%rip),%eax        # ffffffff801906d0 <log+0x70>
ffffffff801043c2:	85 c0                	test   %eax,%eax
ffffffff801043c4:	75 13                	jne    ffffffff801043d9 <end_op+0x5d>
    do_commit = 1;
ffffffff801043c6:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)
    log.committing = 1;
ffffffff801043cd:	c7 05 fd c2 08 00 01 	movl   $0x1,0x8c2fd(%rip)        # ffffffff801906d4 <log+0x74>
ffffffff801043d4:	00 00 00 
ffffffff801043d7:	eb 0c                	jmp    ffffffff801043e5 <end_op+0x69>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
ffffffff801043d9:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff801043e0:	e8 4f 22 00 00       	callq  ffffffff80106634 <wakeup>
  }
  release(&log.lock);
ffffffff801043e5:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff801043ec:	e8 84 25 00 00       	callq  ffffffff80106975 <release>

  if(do_commit){
ffffffff801043f1:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff801043f5:	74 38                	je     ffffffff8010442f <end_op+0xb3>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
ffffffff801043f7:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801043fc:	e8 e7 00 00 00       	callq  ffffffff801044e8 <commit>
    acquire(&log.lock);
ffffffff80104401:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff80104408:	e8 91 24 00 00       	callq  ffffffff8010689e <acquire>
    log.committing = 0;
ffffffff8010440d:	c7 05 bd c2 08 00 00 	movl   $0x0,0x8c2bd(%rip)        # ffffffff801906d4 <log+0x74>
ffffffff80104414:	00 00 00 
    wakeup(&log);
ffffffff80104417:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff8010441e:	e8 11 22 00 00       	callq  ffffffff80106634 <wakeup>
    release(&log.lock);
ffffffff80104423:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff8010442a:	e8 46 25 00 00       	callq  ffffffff80106975 <release>
  }
}
ffffffff8010442f:	90                   	nop
ffffffff80104430:	c9                   	leaveq 
ffffffff80104431:	c3                   	retq   

ffffffff80104432 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
ffffffff80104432:	55                   	push   %rbp
ffffffff80104433:	48 89 e5             	mov    %rsp,%rbp
ffffffff80104436:	48 83 ec 20          	sub    $0x20,%rsp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
ffffffff8010443a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80104441:	e9 90 00 00 00       	jmpq   ffffffff801044d6 <write_log+0xa4>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
ffffffff80104446:	8b 15 7c c2 08 00    	mov    0x8c27c(%rip),%edx        # ffffffff801906c8 <log+0x68>
ffffffff8010444c:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010444f:	01 d0                	add    %edx,%eax
ffffffff80104451:	83 c0 01             	add    $0x1,%eax
ffffffff80104454:	89 c2                	mov    %eax,%edx
ffffffff80104456:	8b 05 7c c2 08 00    	mov    0x8c27c(%rip),%eax        # ffffffff801906d8 <log+0x78>
ffffffff8010445c:	89 d6                	mov    %edx,%esi
ffffffff8010445e:	89 c7                	mov    %eax,%edi
ffffffff80104460:	e8 71 be ff ff       	callq  ffffffff801002d6 <bread>
ffffffff80104465:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
ffffffff80104469:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010446c:	48 98                	cltq   
ffffffff8010446e:	48 83 c0 1c          	add    $0x1c,%rax
ffffffff80104472:	8b 04 85 70 06 19 80 	mov    -0x7fe6f990(,%rax,4),%eax
ffffffff80104479:	89 c2                	mov    %eax,%edx
ffffffff8010447b:	8b 05 57 c2 08 00    	mov    0x8c257(%rip),%eax        # ffffffff801906d8 <log+0x78>
ffffffff80104481:	89 d6                	mov    %edx,%esi
ffffffff80104483:	89 c7                	mov    %eax,%edi
ffffffff80104485:	e8 4c be ff ff       	callq  ffffffff801002d6 <bread>
ffffffff8010448a:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    memmove(to->data, from->data, BSIZE);
ffffffff8010448e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104492:	48 8d 48 28          	lea    0x28(%rax),%rcx
ffffffff80104496:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010449a:	48 83 c0 28          	add    $0x28,%rax
ffffffff8010449e:	ba 00 02 00 00       	mov    $0x200,%edx
ffffffff801044a3:	48 89 ce             	mov    %rcx,%rsi
ffffffff801044a6:	48 89 c7             	mov    %rax,%rdi
ffffffff801044a9:	e8 4e 28 00 00       	callq  ffffffff80106cfc <memmove>
    bwrite(to);  // write the log
ffffffff801044ae:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801044b2:	48 89 c7             	mov    %rax,%rdi
ffffffff801044b5:	e8 5c be ff ff       	callq  ffffffff80100316 <bwrite>
    brelse(from); 
ffffffff801044ba:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801044be:	48 89 c7             	mov    %rax,%rdi
ffffffff801044c1:	e8 95 be ff ff       	callq  ffffffff8010035b <brelse>
    brelse(to);
ffffffff801044c6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801044ca:	48 89 c7             	mov    %rax,%rdi
ffffffff801044cd:	e8 89 be ff ff       	callq  ffffffff8010035b <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
ffffffff801044d2:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801044d6:	8b 05 00 c2 08 00    	mov    0x8c200(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff801044dc:	3b 45 fc             	cmp    -0x4(%rbp),%eax
ffffffff801044df:	0f 8f 61 ff ff ff    	jg     ffffffff80104446 <write_log+0x14>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
ffffffff801044e5:	90                   	nop
ffffffff801044e6:	c9                   	leaveq 
ffffffff801044e7:	c3                   	retq   

ffffffff801044e8 <commit>:

static void
commit()
{
ffffffff801044e8:	55                   	push   %rbp
ffffffff801044e9:	48 89 e5             	mov    %rsp,%rbp
  if (log.lh.n > 0) {
ffffffff801044ec:	8b 05 ea c1 08 00    	mov    0x8c1ea(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff801044f2:	85 c0                	test   %eax,%eax
ffffffff801044f4:	7e 1e                	jle    ffffffff80104514 <commit+0x2c>
    write_log();     // Write modified blocks from cache to log
ffffffff801044f6:	e8 37 ff ff ff       	callq  ffffffff80104432 <write_log>
    write_head();    // Write header to disk -- the real commit
ffffffff801044fb:	e8 4e fd ff ff       	callq  ffffffff8010424e <write_head>
    install_trans(); // Now install writes to home locations
ffffffff80104500:	e8 12 fc ff ff       	callq  ffffffff80104117 <install_trans>
    log.lh.n = 0; 
ffffffff80104505:	c7 05 cd c1 08 00 00 	movl   $0x0,0x8c1cd(%rip)        # ffffffff801906dc <log+0x7c>
ffffffff8010450c:	00 00 00 
    write_head();    // Erase the transaction from the log
ffffffff8010450f:	e8 3a fd ff ff       	callq  ffffffff8010424e <write_head>
  }
}
ffffffff80104514:	90                   	nop
ffffffff80104515:	5d                   	pop    %rbp
ffffffff80104516:	c3                   	retq   

ffffffff80104517 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
ffffffff80104517:	55                   	push   %rbp
ffffffff80104518:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010451b:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010451f:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
ffffffff80104523:	8b 05 b3 c1 08 00    	mov    0x8c1b3(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff80104529:	83 f8 1d             	cmp    $0x1d,%eax
ffffffff8010452c:	7f 13                	jg     ffffffff80104541 <log_write+0x2a>
ffffffff8010452e:	8b 05 a8 c1 08 00    	mov    0x8c1a8(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff80104534:	8b 15 92 c1 08 00    	mov    0x8c192(%rip),%edx        # ffffffff801906cc <log+0x6c>
ffffffff8010453a:	83 ea 01             	sub    $0x1,%edx
ffffffff8010453d:	39 d0                	cmp    %edx,%eax
ffffffff8010453f:	7c 0c                	jl     ffffffff8010454d <log_write+0x36>
    panic("too big a transaction");
ffffffff80104541:	48 c7 c7 47 a9 10 80 	mov    $0xffffffff8010a947,%rdi
ffffffff80104548:	e8 b2 c3 ff ff       	callq  ffffffff801008ff <panic>
  if (log.outstanding < 1)
ffffffff8010454d:	8b 05 7d c1 08 00    	mov    0x8c17d(%rip),%eax        # ffffffff801906d0 <log+0x70>
ffffffff80104553:	85 c0                	test   %eax,%eax
ffffffff80104555:	7f 0c                	jg     ffffffff80104563 <log_write+0x4c>
    panic("log_write outside of trans");
ffffffff80104557:	48 c7 c7 5d a9 10 80 	mov    $0xffffffff8010a95d,%rdi
ffffffff8010455e:	e8 9c c3 ff ff       	callq  ffffffff801008ff <panic>

  acquire(&log.lock);
ffffffff80104563:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff8010456a:	e8 2f 23 00 00       	callq  ffffffff8010689e <acquire>
  for (i = 0; i < log.lh.n; i++) {
ffffffff8010456f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80104576:	eb 21                	jmp    ffffffff80104599 <log_write+0x82>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
ffffffff80104578:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010457b:	48 98                	cltq   
ffffffff8010457d:	48 83 c0 1c          	add    $0x1c,%rax
ffffffff80104581:	8b 04 85 70 06 19 80 	mov    -0x7fe6f990(,%rax,4),%eax
ffffffff80104588:	89 c2                	mov    %eax,%edx
ffffffff8010458a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010458e:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff80104591:	39 c2                	cmp    %eax,%edx
ffffffff80104593:	74 11                	je     ffffffff801045a6 <log_write+0x8f>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
ffffffff80104595:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80104599:	8b 05 3d c1 08 00    	mov    0x8c13d(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff8010459f:	3b 45 fc             	cmp    -0x4(%rbp),%eax
ffffffff801045a2:	7f d4                	jg     ffffffff80104578 <log_write+0x61>
ffffffff801045a4:	eb 01                	jmp    ffffffff801045a7 <log_write+0x90>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
ffffffff801045a6:	90                   	nop
  }
  log.lh.block[i] = b->blockno;
ffffffff801045a7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801045ab:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff801045ae:	89 c2                	mov    %eax,%edx
ffffffff801045b0:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801045b3:	48 98                	cltq   
ffffffff801045b5:	48 83 c0 1c          	add    $0x1c,%rax
ffffffff801045b9:	89 14 85 70 06 19 80 	mov    %edx,-0x7fe6f990(,%rax,4)
  if (i == log.lh.n)
ffffffff801045c0:	8b 05 16 c1 08 00    	mov    0x8c116(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff801045c6:	3b 45 fc             	cmp    -0x4(%rbp),%eax
ffffffff801045c9:	75 0f                	jne    ffffffff801045da <log_write+0xc3>
    log.lh.n++;
ffffffff801045cb:	8b 05 0b c1 08 00    	mov    0x8c10b(%rip),%eax        # ffffffff801906dc <log+0x7c>
ffffffff801045d1:	83 c0 01             	add    $0x1,%eax
ffffffff801045d4:	89 05 02 c1 08 00    	mov    %eax,0x8c102(%rip)        # ffffffff801906dc <log+0x7c>
  b->flags |= B_DIRTY; // prevent eviction
ffffffff801045da:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801045de:	8b 00                	mov    (%rax),%eax
ffffffff801045e0:	83 c8 04             	or     $0x4,%eax
ffffffff801045e3:	89 c2                	mov    %eax,%edx
ffffffff801045e5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801045e9:	89 10                	mov    %edx,(%rax)
  release(&log.lock);
ffffffff801045eb:	48 c7 c7 60 06 19 80 	mov    $0xffffffff80190660,%rdi
ffffffff801045f2:	e8 7e 23 00 00       	callq  ffffffff80106975 <release>
}
ffffffff801045f7:	90                   	nop
ffffffff801045f8:	c9                   	leaveq 
ffffffff801045f9:	c3                   	retq   

ffffffff801045fa <v2p>:
ffffffff801045fa:	55                   	push   %rbp
ffffffff801045fb:	48 89 e5             	mov    %rsp,%rbp
ffffffff801045fe:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80104602:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80104606:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff8010460a:	b8 00 00 00 80       	mov    $0x80000000,%eax
ffffffff8010460f:	48 01 d0             	add    %rdx,%rax
ffffffff80104612:	c9                   	leaveq 
ffffffff80104613:	c3                   	retq   

ffffffff80104614 <p2v>:
static inline void *p2v(uintp a) { return (void *) ((a) + ((uintp)KERNBASE)); }
ffffffff80104614:	55                   	push   %rbp
ffffffff80104615:	48 89 e5             	mov    %rsp,%rbp
ffffffff80104618:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff8010461c:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80104620:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104624:	48 05 00 00 00 80    	add    $0xffffffff80000000,%rax
ffffffff8010462a:	c9                   	leaveq 
ffffffff8010462b:	c3                   	retq   

ffffffff8010462c <xchg>:
  asm volatile("hlt");
}

static inline uint
xchg(volatile uint *addr, uintp newval)
{
ffffffff8010462c:	55                   	push   %rbp
ffffffff8010462d:	48 89 e5             	mov    %rsp,%rbp
ffffffff80104630:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80104634:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80104638:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
               "1" ((uint)newval) :
ffffffff8010463c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
xchg(volatile uint *addr, uintp newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
ffffffff80104640:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80104644:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
ffffffff80104648:	f0 87 02             	lock xchg %eax,(%rdx)
ffffffff8010464b:	89 45 fc             	mov    %eax,-0x4(%rbp)
               "+m" (*addr), "=a" (result) :
               "1" ((uint)newval) :
               "cc");
  return result;
ffffffff8010464e:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
ffffffff80104651:	c9                   	leaveq 
ffffffff80104652:	c3                   	retq   

ffffffff80104653 <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
ffffffff80104653:	55                   	push   %rbp
ffffffff80104654:	48 89 e5             	mov    %rsp,%rbp
  uartearlyinit();
ffffffff80104657:	e8 45 41 00 00       	callq  ffffffff801087a1 <uartearlyinit>
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
ffffffff8010465c:	48 c7 c6 00 00 40 80 	mov    $0xffffffff80400000,%rsi
ffffffff80104663:	48 c7 c7 00 60 19 80 	mov    $0xffffffff80196000,%rdi
ffffffff8010466a:	e8 bf f0 ff ff       	callq  ffffffff8010372e <kinit1>
  kvmalloc();      // kernel page table
ffffffff8010466f:	e8 ee 5a 00 00       	callq  ffffffff8010a162 <kvmalloc>
  //if (acpiinit()) // try to use acpi for machine info
    mpinit();      // otherwise use bios MP tables
ffffffff80104674:	e8 49 06 00 00       	callq  ffffffff80104cc2 <mpinit>
  lapicinit();
ffffffff80104679:	e8 3f f5 ff ff       	callq  ffffffff80103bbd <lapicinit>
  seginit();       // set up segments
ffffffff8010467e:	e8 cd 57 00 00       	callq  ffffffff80109e50 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
ffffffff80104683:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff8010468a:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010468e:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104691:	0f b6 c0             	movzbl %al,%eax
ffffffff80104694:	89 c6                	mov    %eax,%esi
ffffffff80104696:	48 c7 c7 78 a9 10 80 	mov    $0xffffffff8010a978,%rdi
ffffffff8010469d:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801046a2:	e8 fb be ff ff       	callq  ffffffff801005a2 <cprintf>
  picinit();       // interrupt controller
ffffffff801046a7:	e8 22 0f 00 00       	callq  ffffffff801055ce <picinit>
  ioapicinit();    // another interrupt controller
ffffffff801046ac:	e8 56 ef ff ff       	callq  ffffffff80103607 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
ffffffff801046b1:	e8 00 c8 ff ff       	callq  ffffffff80100eb6 <consoleinit>
  uartinit();      // serial port
ffffffff801046b6:	e8 9f 41 00 00       	callq  ffffffff8010885a <uartinit>
  pinit();         // process table
ffffffff801046bb:	e8 81 14 00 00       	callq  ffffffff80105b41 <pinit>
  tvinit();        // trap vectors
ffffffff801046c0:	e8 59 56 00 00       	callq  ffffffff80109d1e <tvinit>
  binit();         // buffer cache
ffffffff801046c5:	e8 61 ba ff ff       	callq  ffffffff8010012b <binit>
  fileinit();      // file table
ffffffff801046ca:	e8 3a d7 ff ff       	callq  ffffffff80101e09 <fileinit>
  iinit();         // inode cache
ffffffff801046cf:	e8 63 de ff ff       	callq  ffffffff80102537 <iinit>
  ideinit();       // disk
ffffffff801046d4:	e8 0c 5d 00 00       	callq  ffffffff8010a3e5 <ideinit>
  if(!ismp)
ffffffff801046d9:	8b 05 01 c8 08 00    	mov    0x8c801(%rip),%eax        # ffffffff80190ee0 <ismp>
ffffffff801046df:	85 c0                	test   %eax,%eax
ffffffff801046e1:	75 05                	jne    ffffffff801046e8 <main+0x95>
    timerinit();   // uniprocessor timer
ffffffff801046e3:	e8 f1 3c 00 00       	callq  ffffffff801083d9 <timerinit>
  startothers();   // start other processors
ffffffff801046e8:	e8 8a 00 00 00       	callq  ffffffff80104777 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
ffffffff801046ed:	48 c7 c6 00 00 00 8e 	mov    $0xffffffff8e000000,%rsi
ffffffff801046f4:	48 c7 c7 00 00 40 80 	mov    $0xffffffff80400000,%rdi
ffffffff801046fb:	e8 71 f0 ff ff       	callq  ffffffff80103771 <kinit2>
  userinit();      // first user process
ffffffff80104700:	e8 81 15 00 00       	callq  ffffffff80105c86 <userinit>
  cpuidinit();
ffffffff80104705:	e8 b4 d1 ff ff       	callq  ffffffff801018be <cpuidinit>
  // Finish setting up this processor in mpmain.
  mpmain();
ffffffff8010470a:	e8 18 00 00 00       	callq  ffffffff80104727 <mpmain>

ffffffff8010470f <mpenter>:
}

// Other CPUs jump here from entryother.S.
void
mpenter(void)
{
ffffffff8010470f:	55                   	push   %rbp
ffffffff80104710:	48 89 e5             	mov    %rsp,%rbp
  switchkvm(); 
ffffffff80104713:	e8 0f 5c 00 00       	callq  ffffffff8010a327 <switchkvm>
  seginit();
ffffffff80104718:	e8 33 57 00 00       	callq  ffffffff80109e50 <seginit>
  lapicinit();
ffffffff8010471d:	e8 9b f4 ff ff       	callq  ffffffff80103bbd <lapicinit>
  mpmain();
ffffffff80104722:	e8 00 00 00 00       	callq  ffffffff80104727 <mpmain>

ffffffff80104727 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
ffffffff80104727:	55                   	push   %rbp
ffffffff80104728:	48 89 e5             	mov    %rsp,%rbp
  cprintf("cpu%d: starting\n", cpu->id);
ffffffff8010472b:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80104732:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80104736:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104739:	0f b6 c0             	movzbl %al,%eax
ffffffff8010473c:	89 c6                	mov    %eax,%esi
ffffffff8010473e:	48 c7 c7 8f a9 10 80 	mov    $0xffffffff8010a98f,%rdi
ffffffff80104745:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010474a:	e8 53 be ff ff       	callq  ffffffff801005a2 <cprintf>
  idtinit();       // load idt register
ffffffff8010474f:	e8 d1 55 00 00       	callq  ffffffff80109d25 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
ffffffff80104754:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff8010475b:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010475f:	48 05 d8 00 00 00    	add    $0xd8,%rax
ffffffff80104765:	be 01 00 00 00       	mov    $0x1,%esi
ffffffff8010476a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010476d:	e8 ba fe ff ff       	callq  ffffffff8010462c <xchg>
  scheduler();     // start running processes
ffffffff80104772:	e8 a1 1b 00 00       	callq  ffffffff80106318 <scheduler>

ffffffff80104777 <startothers>:
#endif /* X64 */

// Start the non-boot (AP) processors.
static void
startothers(void)
{
ffffffff80104777:	55                   	push   %rbp
ffffffff80104778:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010477b:	53                   	push   %rbx
ffffffff8010477c:	48 83 ec 28          	sub    $0x28,%rsp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
ffffffff80104780:	bf 00 70 00 00       	mov    $0x7000,%edi
ffffffff80104785:	e8 8a fe ff ff       	callq  ffffffff80104614 <p2v>
ffffffff8010478a:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  memmove(code, _binary_out_entryother_start, (uintp)_binary_out_entryother_size);
ffffffff8010478e:	48 c7 c0 72 00 00 00 	mov    $0x72,%rax
ffffffff80104795:	89 c2                	mov    %eax,%edx
ffffffff80104797:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010479b:	48 c7 c6 b4 ce 10 80 	mov    $0xffffffff8010ceb4,%rsi
ffffffff801047a2:	48 89 c7             	mov    %rax,%rdi
ffffffff801047a5:	e8 52 25 00 00       	callq  ffffffff80106cfc <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
ffffffff801047aa:	48 c7 45 e8 60 07 19 	movq   $0xffffffff80190760,-0x18(%rbp)
ffffffff801047b1:	80 
ffffffff801047b2:	e9 a3 00 00 00       	jmpq   ffffffff8010485a <startothers+0xe3>
    if(c == cpus+cpunum())  // We've started already.
ffffffff801047b7:	e8 27 f5 ff ff       	callq  ffffffff80103ce3 <cpunum>
ffffffff801047bc:	48 98                	cltq   
ffffffff801047be:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff801047c2:	48 89 c2             	mov    %rax,%rdx
ffffffff801047c5:	48 c1 e2 04          	shl    $0x4,%rdx
ffffffff801047c9:	48 29 c2             	sub    %rax,%rdx
ffffffff801047cc:	48 89 d0             	mov    %rdx,%rax
ffffffff801047cf:	48 05 60 07 19 80    	add    $0xffffffff80190760,%rax
ffffffff801047d5:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff801047d9:	74 76                	je     ffffffff80104851 <startothers+0xda>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
ffffffff801047db:	e8 b8 f0 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff801047e0:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
#if X64
    *(uint32*)(code-4) = 0x8000; // just enough stack to get us to entry64mp
ffffffff801047e4:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801047e8:	48 83 e8 04          	sub    $0x4,%rax
ffffffff801047ec:	c7 00 00 80 00 00    	movl   $0x8000,(%rax)
    *(uint32*)(code-8) = v2p(entry32mp);
ffffffff801047f2:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801047f6:	48 8d 58 f8          	lea    -0x8(%rax),%rbx
ffffffff801047fa:	48 c7 c7 74 00 10 80 	mov    $0xffffffff80100074,%rdi
ffffffff80104801:	e8 f4 fd ff ff       	callq  ffffffff801045fa <v2p>
ffffffff80104806:	89 03                	mov    %eax,(%rbx)
    *(uint64*)(code-16) = (uint64) (stack + KSTACKSIZE);
ffffffff80104808:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010480c:	48 83 e8 10          	sub    $0x10,%rax
ffffffff80104810:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
ffffffff80104814:	48 81 c2 00 10 00 00 	add    $0x1000,%rdx
ffffffff8010481b:	48 89 10             	mov    %rdx,(%rax)
    *(void**)(code-4) = stack + KSTACKSIZE;
    *(void**)(code-8) = mpenter;
    *(int**)(code-12) = (void *) v2p(entrypgdir);
#endif

    lapicstartap(c->apicid, v2p(code));
ffffffff8010481e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104822:	48 89 c7             	mov    %rax,%rdi
ffffffff80104825:	e8 d0 fd ff ff       	callq  ffffffff801045fa <v2p>
ffffffff8010482a:	89 c2                	mov    %eax,%edx
ffffffff8010482c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104830:	0f b6 40 01          	movzbl 0x1(%rax),%eax
ffffffff80104834:	0f b6 c0             	movzbl %al,%eax
ffffffff80104837:	89 d6                	mov    %edx,%esi
ffffffff80104839:	89 c7                	mov    %eax,%edi
ffffffff8010483b:	e8 86 f5 ff ff       	callq  ffffffff80103dc6 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
ffffffff80104840:	90                   	nop
ffffffff80104841:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104845:	8b 80 d8 00 00 00    	mov    0xd8(%rax),%eax
ffffffff8010484b:	85 c0                	test   %eax,%eax
ffffffff8010484d:	74 f2                	je     ffffffff80104841 <startothers+0xca>
ffffffff8010484f:	eb 01                	jmp    ffffffff80104852 <startothers+0xdb>
  code = p2v(0x7000);
  memmove(code, _binary_out_entryother_start, (uintp)_binary_out_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
ffffffff80104851:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_out_entryother_start, (uintp)_binary_out_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
ffffffff80104852:	48 81 45 e8 f0 00 00 	addq   $0xf0,-0x18(%rbp)
ffffffff80104859:	00 
ffffffff8010485a:	8b 05 84 c6 08 00    	mov    0x8c684(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff80104860:	48 98                	cltq   
ffffffff80104862:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80104866:	48 89 c2             	mov    %rax,%rdx
ffffffff80104869:	48 c1 e2 04          	shl    $0x4,%rdx
ffffffff8010486d:	48 29 c2             	sub    %rax,%rdx
ffffffff80104870:	48 89 d0             	mov    %rdx,%rax
ffffffff80104873:	48 05 60 07 19 80    	add    $0xffffffff80190760,%rax
ffffffff80104879:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff8010487d:	0f 87 34 ff ff ff    	ja     ffffffff801047b7 <startothers+0x40>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
ffffffff80104883:	90                   	nop
ffffffff80104884:	48 83 c4 28          	add    $0x28,%rsp
ffffffff80104888:	5b                   	pop    %rbx
ffffffff80104889:	5d                   	pop    %rbp
ffffffff8010488a:	c3                   	retq   

ffffffff8010488b <p2v>:
ffffffff8010488b:	55                   	push   %rbp
ffffffff8010488c:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010488f:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80104893:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80104897:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010489b:	48 05 00 00 00 80    	add    $0xffffffff80000000,%rax
ffffffff801048a1:	c9                   	leaveq 
ffffffff801048a2:	c3                   	retq   

ffffffff801048a3 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
ffffffff801048a3:	55                   	push   %rbp
ffffffff801048a4:	48 89 e5             	mov    %rsp,%rbp
ffffffff801048a7:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff801048ab:	89 f8                	mov    %edi,%eax
ffffffff801048ad:	66 89 45 ec          	mov    %ax,-0x14(%rbp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
ffffffff801048b1:	0f b7 45 ec          	movzwl -0x14(%rbp),%eax
ffffffff801048b5:	89 c2                	mov    %eax,%edx
ffffffff801048b7:	ec                   	in     (%dx),%al
ffffffff801048b8:	88 45 ff             	mov    %al,-0x1(%rbp)
  return data;
ffffffff801048bb:	0f b6 45 ff          	movzbl -0x1(%rbp),%eax
}
ffffffff801048bf:	c9                   	leaveq 
ffffffff801048c0:	c3                   	retq   

ffffffff801048c1 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
ffffffff801048c1:	55                   	push   %rbp
ffffffff801048c2:	48 89 e5             	mov    %rsp,%rbp
ffffffff801048c5:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801048c9:	89 fa                	mov    %edi,%edx
ffffffff801048cb:	89 f0                	mov    %esi,%eax
ffffffff801048cd:	66 89 55 fc          	mov    %dx,-0x4(%rbp)
ffffffff801048d1:	88 45 f8             	mov    %al,-0x8(%rbp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
ffffffff801048d4:	0f b6 45 f8          	movzbl -0x8(%rbp),%eax
ffffffff801048d8:	0f b7 55 fc          	movzwl -0x4(%rbp),%edx
ffffffff801048dc:	ee                   	out    %al,(%dx)
}
ffffffff801048dd:	90                   	nop
ffffffff801048de:	c9                   	leaveq 
ffffffff801048df:	c3                   	retq   

ffffffff801048e0 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
ffffffff801048e0:	55                   	push   %rbp
ffffffff801048e1:	48 89 e5             	mov    %rsp,%rbp
  return bcpu-cpus;
ffffffff801048e4:	48 8b 05 05 c6 08 00 	mov    0x8c605(%rip),%rax        # ffffffff80190ef0 <bcpu>
ffffffff801048eb:	48 89 c2             	mov    %rax,%rdx
ffffffff801048ee:	48 c7 c0 60 07 19 80 	mov    $0xffffffff80190760,%rax
ffffffff801048f5:	48 29 c2             	sub    %rax,%rdx
ffffffff801048f8:	48 89 d0             	mov    %rdx,%rax
ffffffff801048fb:	48 c1 f8 04          	sar    $0x4,%rax
ffffffff801048ff:	48 89 c2             	mov    %rax,%rdx
ffffffff80104902:	48 b8 ef ee ee ee ee 	movabs $0xeeeeeeeeeeeeeeef,%rax
ffffffff80104909:	ee ee ee 
ffffffff8010490c:	48 0f af c2          	imul   %rdx,%rax
}
ffffffff80104910:	5d                   	pop    %rbp
ffffffff80104911:	c3                   	retq   

ffffffff80104912 <sum>:

static uchar
sum(uchar *addr, int len)
{
ffffffff80104912:	55                   	push   %rbp
ffffffff80104913:	48 89 e5             	mov    %rsp,%rbp
ffffffff80104916:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010491a:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff8010491e:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  int i, sum;
  
  sum = 0;
ffffffff80104921:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
  for(i=0; i<len; i++)
ffffffff80104928:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff8010492f:	eb 1a                	jmp    ffffffff8010494b <sum+0x39>
    sum += addr[i];
ffffffff80104931:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80104934:	48 63 d0             	movslq %eax,%rdx
ffffffff80104937:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010493b:	48 01 d0             	add    %rdx,%rax
ffffffff8010493e:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104941:	0f b6 c0             	movzbl %al,%eax
ffffffff80104944:	01 45 f8             	add    %eax,-0x8(%rbp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
ffffffff80104947:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff8010494b:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff8010494e:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
ffffffff80104951:	7c de                	jl     ffffffff80104931 <sum+0x1f>
    sum += addr[i];
  return sum;
ffffffff80104953:	8b 45 f8             	mov    -0x8(%rbp),%eax
}
ffffffff80104956:	c9                   	leaveq 
ffffffff80104957:	c3                   	retq   

ffffffff80104958 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
ffffffff80104958:	55                   	push   %rbp
ffffffff80104959:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010495c:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80104960:	89 7d dc             	mov    %edi,-0x24(%rbp)
ffffffff80104963:	89 75 d8             	mov    %esi,-0x28(%rbp)
  uchar *e, *p, *addr;
  struct mp *tmp;

  addr = p2v(a);
ffffffff80104966:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80104969:	48 89 c7             	mov    %rax,%rdi
ffffffff8010496c:	e8 1a ff ff ff       	callq  ffffffff8010488b <p2v>
ffffffff80104971:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  e = addr+len;
ffffffff80104975:	8b 45 d8             	mov    -0x28(%rbp),%eax
ffffffff80104978:	48 63 d0             	movslq %eax,%rdx
ffffffff8010497b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010497f:	48 01 d0             	add    %rdx,%rax
ffffffff80104982:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  for(p = addr; p < e; p += sizeof(struct mp))
ffffffff80104986:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010498a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff8010498e:	e9 30 01 00 00       	jmpq   ffffffff80104ac3 <mpsearch1+0x16b>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0){
ffffffff80104993:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104997:	ba 04 00 00 00       	mov    $0x4,%edx
ffffffff8010499c:	48 c7 c6 a0 a9 10 80 	mov    $0xffffffff8010a9a0,%rsi
ffffffff801049a3:	48 89 c7             	mov    %rax,%rdi
ffffffff801049a6:	e8 e2 22 00 00       	callq  ffffffff80106c8d <memcmp>
ffffffff801049ab:	85 c0                	test   %eax,%eax
ffffffff801049ad:	0f 85 0b 01 00 00    	jne    ffffffff80104abe <mpsearch1+0x166>
ffffffff801049b3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801049b7:	be 10 00 00 00       	mov    $0x10,%esi
ffffffff801049bc:	48 89 c7             	mov    %rax,%rdi
ffffffff801049bf:	e8 4e ff ff ff       	callq  ffffffff80104912 <sum>
ffffffff801049c4:	84 c0                	test   %al,%al
ffffffff801049c6:	0f 85 f2 00 00 00    	jne    ffffffff80104abe <mpsearch1+0x166>
		tmp = (struct mp*)p;
ffffffff801049cc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801049d0:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
		cprintf("mp floating pointer:\n");
ffffffff801049d4:	48 c7 c7 a5 a9 10 80 	mov    $0xffffffff8010a9a5,%rdi
ffffffff801049db:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801049e0:	e8 bd bb ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("mp sig:%x%x%x%x\n",tmp->signature[0],tmp->signature[1],tmp->signature[2],tmp->signature[3]);
ffffffff801049e5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801049e9:	0f b6 40 03          	movzbl 0x3(%rax),%eax
ffffffff801049ed:	0f b6 f0             	movzbl %al,%esi
ffffffff801049f0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801049f4:	0f b6 40 02          	movzbl 0x2(%rax),%eax
ffffffff801049f8:	0f b6 c8             	movzbl %al,%ecx
ffffffff801049fb:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801049ff:	0f b6 40 01          	movzbl 0x1(%rax),%eax
ffffffff80104a03:	0f b6 d0             	movzbl %al,%edx
ffffffff80104a06:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104a0a:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104a0d:	0f b6 c0             	movzbl %al,%eax
ffffffff80104a10:	41 89 f0             	mov    %esi,%r8d
ffffffff80104a13:	89 c6                	mov    %eax,%esi
ffffffff80104a15:	48 c7 c7 bb a9 10 80 	mov    $0xffffffff8010a9bb,%rdi
ffffffff80104a1c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104a21:	e8 7c bb ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("mp phy addr:0x%x\n",tmp->physaddr);
ffffffff80104a26:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104a2a:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80104a2d:	89 c6                	mov    %eax,%esi
ffffffff80104a2f:	48 c7 c7 cc a9 10 80 	mov    $0xffffffff8010a9cc,%rdi
ffffffff80104a36:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104a3b:	e8 62 bb ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("mp length:0x%x\n",tmp->length);
ffffffff80104a40:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104a44:	0f b6 40 08          	movzbl 0x8(%rax),%eax
ffffffff80104a48:	0f b6 c0             	movzbl %al,%eax
ffffffff80104a4b:	89 c6                	mov    %eax,%esi
ffffffff80104a4d:	48 c7 c7 de a9 10 80 	mov    $0xffffffff8010a9de,%rdi
ffffffff80104a54:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104a59:	e8 44 bb ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("mp spec rev:0x%x\n",tmp->specrev);
ffffffff80104a5e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104a62:	0f b6 40 09          	movzbl 0x9(%rax),%eax
ffffffff80104a66:	0f b6 c0             	movzbl %al,%eax
ffffffff80104a69:	89 c6                	mov    %eax,%esi
ffffffff80104a6b:	48 c7 c7 ee a9 10 80 	mov    $0xffffffff8010a9ee,%rdi
ffffffff80104a72:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104a77:	e8 26 bb ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("mp type:0x%x\n",tmp->type);
ffffffff80104a7c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104a80:	0f b6 40 0b          	movzbl 0xb(%rax),%eax
ffffffff80104a84:	0f b6 c0             	movzbl %al,%eax
ffffffff80104a87:	89 c6                	mov    %eax,%esi
ffffffff80104a89:	48 c7 c7 00 aa 10 80 	mov    $0xffffffff8010aa00,%rdi
ffffffff80104a90:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104a95:	e8 08 bb ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("mp imcrp:0x%x\n",tmp->imcrp);
ffffffff80104a9a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104a9e:	0f b6 40 0c          	movzbl 0xc(%rax),%eax
ffffffff80104aa2:	0f b6 c0             	movzbl %al,%eax
ffffffff80104aa5:	89 c6                	mov    %eax,%esi
ffffffff80104aa7:	48 c7 c7 0e aa 10 80 	mov    $0xffffffff8010aa0e,%rdi
ffffffff80104aae:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104ab3:	e8 ea ba ff ff       	callq  ffffffff801005a2 <cprintf>
		
		
      return (struct mp*)p;
ffffffff80104ab8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104abc:	eb 18                	jmp    ffffffff80104ad6 <mpsearch1+0x17e>
  uchar *e, *p, *addr;
  struct mp *tmp;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
ffffffff80104abe:	48 83 45 f8 10       	addq   $0x10,-0x8(%rbp)
ffffffff80104ac3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104ac7:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff80104acb:	0f 82 c2 fe ff ff    	jb     ffffffff80104993 <mpsearch1+0x3b>
		cprintf("mp imcrp:0x%x\n",tmp->imcrp);
		
		
      return (struct mp*)p;
    }
  return 0;
ffffffff80104ad1:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80104ad6:	c9                   	leaveq 
ffffffff80104ad7:	c3                   	retq   

ffffffff80104ad8 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM address space between 0F0000h and 0FFFFFh.
static struct mp*
mpsearch(void)
{
ffffffff80104ad8:	55                   	push   %rbp
ffffffff80104ad9:	48 89 e5             	mov    %rsp,%rbp
ffffffff80104adc:	48 83 ec 20          	sub    $0x20,%rsp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
ffffffff80104ae0:	48 c7 45 f8 00 04 00 	movq   $0xffffffff80000400,-0x8(%rbp)
ffffffff80104ae7:	80 
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
ffffffff80104ae8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104aec:	48 83 c0 0f          	add    $0xf,%rax
ffffffff80104af0:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104af3:	0f b6 c0             	movzbl %al,%eax
ffffffff80104af6:	c1 e0 08             	shl    $0x8,%eax
ffffffff80104af9:	89 c2                	mov    %eax,%edx
ffffffff80104afb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104aff:	48 83 c0 0e          	add    $0xe,%rax
ffffffff80104b03:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104b06:	0f b6 c0             	movzbl %al,%eax
ffffffff80104b09:	09 d0                	or     %edx,%eax
ffffffff80104b0b:	c1 e0 04             	shl    $0x4,%eax
ffffffff80104b0e:	89 45 f4             	mov    %eax,-0xc(%rbp)
ffffffff80104b11:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
ffffffff80104b15:	74 50                	je     ffffffff80104b67 <mpsearch+0x8f>
	  cprintf("ebda addr here\n");
ffffffff80104b17:	48 c7 c7 1d aa 10 80 	mov    $0xffffffff8010aa1d,%rdi
ffffffff80104b1e:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104b23:	e8 7a ba ff ff       	callq  ffffffff801005a2 <cprintf>
    if((mp = mpsearch1(p, 1024))){
ffffffff80104b28:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80104b2b:	be 00 04 00 00       	mov    $0x400,%esi
ffffffff80104b30:	89 c7                	mov    %eax,%edi
ffffffff80104b32:	e8 21 fe ff ff       	callq  ffffffff80104958 <mpsearch1>
ffffffff80104b37:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80104b3b:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff80104b40:	0f 84 9d 00 00 00    	je     ffffffff80104be3 <mpsearch+0x10b>
		cprintf("look for floating pointer from ebda:%p",mp);
ffffffff80104b46:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104b4a:	48 89 c6             	mov    %rax,%rsi
ffffffff80104b4d:	48 c7 c7 30 aa 10 80 	mov    $0xffffffff8010aa30,%rdi
ffffffff80104b54:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104b59:	e8 44 ba ff ff       	callq  ffffffff801005a2 <cprintf>
      return mp;
ffffffff80104b5e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104b62:	e9 9c 00 00 00       	jmpq   ffffffff80104c03 <mpsearch+0x12b>
    }
  } else {
	
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
ffffffff80104b67:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104b6b:	48 83 c0 14          	add    $0x14,%rax
ffffffff80104b6f:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104b72:	0f b6 c0             	movzbl %al,%eax
ffffffff80104b75:	c1 e0 08             	shl    $0x8,%eax
ffffffff80104b78:	89 c2                	mov    %eax,%edx
ffffffff80104b7a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104b7e:	48 83 c0 13          	add    $0x13,%rax
ffffffff80104b82:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104b85:	0f b6 c0             	movzbl %al,%eax
ffffffff80104b88:	09 d0                	or     %edx,%eax
ffffffff80104b8a:	c1 e0 0a             	shl    $0xa,%eax
ffffffff80104b8d:	89 45 f4             	mov    %eax,-0xc(%rbp)
    cprintf("mpserch from system base memory:%p\n",p);
ffffffff80104b90:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80104b93:	89 c6                	mov    %eax,%esi
ffffffff80104b95:	48 c7 c7 58 aa 10 80 	mov    $0xffffffff8010aa58,%rdi
ffffffff80104b9c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104ba1:	e8 fc b9 ff ff       	callq  ffffffff801005a2 <cprintf>
    if((mp = mpsearch1(p-1024, 1024))){
ffffffff80104ba6:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80104ba9:	2d 00 04 00 00       	sub    $0x400,%eax
ffffffff80104bae:	be 00 04 00 00       	mov    $0x400,%esi
ffffffff80104bb3:	89 c7                	mov    %eax,%edi
ffffffff80104bb5:	e8 9e fd ff ff       	callq  ffffffff80104958 <mpsearch1>
ffffffff80104bba:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80104bbe:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff80104bc3:	74 1e                	je     ffffffff80104be3 <mpsearch+0x10b>
		cprintf("look for floating pointer from system base memory:%p",mp);
ffffffff80104bc5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104bc9:	48 89 c6             	mov    %rax,%rsi
ffffffff80104bcc:	48 c7 c7 80 aa 10 80 	mov    $0xffffffff8010aa80,%rdi
ffffffff80104bd3:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104bd8:	e8 c5 b9 ff ff       	callq  ffffffff801005a2 <cprintf>
      return mp;
ffffffff80104bdd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104be1:	eb 20                	jmp    ffffffff80104c03 <mpsearch+0x12b>
    }
  }
  cprintf("mpserch from 0xf0000--0x10000\n");
ffffffff80104be3:	48 c7 c7 b8 aa 10 80 	mov    $0xffffffff8010aab8,%rdi
ffffffff80104bea:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104bef:	e8 ae b9 ff ff       	callq  ffffffff801005a2 <cprintf>
  return mpsearch1(0xF0000, 0x10000);
ffffffff80104bf4:	be 00 00 01 00       	mov    $0x10000,%esi
ffffffff80104bf9:	bf 00 00 0f 00       	mov    $0xf0000,%edi
ffffffff80104bfe:	e8 55 fd ff ff       	callq  ffffffff80104958 <mpsearch1>
}
ffffffff80104c03:	c9                   	leaveq 
ffffffff80104c04:	c3                   	retq   

ffffffff80104c05 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
ffffffff80104c05:	55                   	push   %rbp
ffffffff80104c06:	48 89 e5             	mov    %rsp,%rbp
ffffffff80104c09:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80104c0d:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
ffffffff80104c11:	e8 c2 fe ff ff       	callq  ffffffff80104ad8 <mpsearch>
ffffffff80104c16:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80104c1a:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80104c1f:	74 0b                	je     ffffffff80104c2c <mpconfig+0x27>
ffffffff80104c21:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104c25:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80104c28:	85 c0                	test   %eax,%eax
ffffffff80104c2a:	75 0a                	jne    ffffffff80104c36 <mpconfig+0x31>
    return 0;
ffffffff80104c2c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104c31:	e9 8a 00 00 00       	jmpq   ffffffff80104cc0 <mpconfig+0xbb>
  conf = (struct mpconf*) p2v((uintp) mp->physaddr);
ffffffff80104c36:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104c3a:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80104c3d:	89 c0                	mov    %eax,%eax
ffffffff80104c3f:	48 89 c7             	mov    %rax,%rdi
ffffffff80104c42:	e8 44 fc ff ff       	callq  ffffffff8010488b <p2v>
ffffffff80104c47:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  if(memcmp(conf, "PCMP", 4) != 0)
ffffffff80104c4b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104c4f:	ba 04 00 00 00       	mov    $0x4,%edx
ffffffff80104c54:	48 c7 c6 d7 aa 10 80 	mov    $0xffffffff8010aad7,%rsi
ffffffff80104c5b:	48 89 c7             	mov    %rax,%rdi
ffffffff80104c5e:	e8 2a 20 00 00       	callq  ffffffff80106c8d <memcmp>
ffffffff80104c63:	85 c0                	test   %eax,%eax
ffffffff80104c65:	74 07                	je     ffffffff80104c6e <mpconfig+0x69>
    return 0;
ffffffff80104c67:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104c6c:	eb 52                	jmp    ffffffff80104cc0 <mpconfig+0xbb>
  if(conf->version != 1 && conf->version != 4)
ffffffff80104c6e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104c72:	0f b6 40 06          	movzbl 0x6(%rax),%eax
ffffffff80104c76:	3c 01                	cmp    $0x1,%al
ffffffff80104c78:	74 13                	je     ffffffff80104c8d <mpconfig+0x88>
ffffffff80104c7a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104c7e:	0f b6 40 06          	movzbl 0x6(%rax),%eax
ffffffff80104c82:	3c 04                	cmp    $0x4,%al
ffffffff80104c84:	74 07                	je     ffffffff80104c8d <mpconfig+0x88>
    return 0;
ffffffff80104c86:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104c8b:	eb 33                	jmp    ffffffff80104cc0 <mpconfig+0xbb>
  if(sum((uchar*)conf, conf->length) != 0)
ffffffff80104c8d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104c91:	0f b7 40 04          	movzwl 0x4(%rax),%eax
ffffffff80104c95:	0f b7 d0             	movzwl %ax,%edx
ffffffff80104c98:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104c9c:	89 d6                	mov    %edx,%esi
ffffffff80104c9e:	48 89 c7             	mov    %rax,%rdi
ffffffff80104ca1:	e8 6c fc ff ff       	callq  ffffffff80104912 <sum>
ffffffff80104ca6:	84 c0                	test   %al,%al
ffffffff80104ca8:	74 07                	je     ffffffff80104cb1 <mpconfig+0xac>
    return 0;
ffffffff80104caa:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104caf:	eb 0f                	jmp    ffffffff80104cc0 <mpconfig+0xbb>
  *pmp = mp;
ffffffff80104cb1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80104cb5:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80104cb9:	48 89 10             	mov    %rdx,(%rax)
  return conf;
ffffffff80104cbc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
ffffffff80104cc0:	c9                   	leaveq 
ffffffff80104cc1:	c3                   	retq   

ffffffff80104cc2 <mpinit>:

void
mpinit(void)
{
ffffffff80104cc2:	55                   	push   %rbp
ffffffff80104cc3:	48 89 e5             	mov    %rsp,%rbp
ffffffff80104cc6:	48 83 ec 40          	sub    $0x40,%rsp
  struct mpproc *proc;
  struct mpioapic *ioapic;
  struct mpbus *mpbus;
  struct mpiointr  *iointr;
  
  bcpu = &cpus[0];
ffffffff80104cca:	48 c7 05 1b c2 08 00 	movq   $0xffffffff80190760,0x8c21b(%rip)        # ffffffff80190ef0 <bcpu>
ffffffff80104cd1:	60 07 19 80 
  if((conf = mpconfig(&mp)) == 0)
ffffffff80104cd5:	48 8d 45 c0          	lea    -0x40(%rbp),%rax
ffffffff80104cd9:	48 89 c7             	mov    %rax,%rdi
ffffffff80104cdc:	e8 24 ff ff ff       	callq  ffffffff80104c05 <mpconfig>
ffffffff80104ce1:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80104ce5:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80104cea:	0f 84 52 03 00 00    	je     ffffffff80105042 <mpinit+0x380>
    return;
  ismp = 1;
ffffffff80104cf0:	c7 05 e6 c1 08 00 01 	movl   $0x1,0x8c1e6(%rip)        # ffffffff80190ee0 <ismp>
ffffffff80104cf7:	00 00 00 
  lapic = IO2V((uintp)conf->lapicaddr);
ffffffff80104cfa:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104cfe:	8b 40 24             	mov    0x24(%rax),%eax
ffffffff80104d01:	89 c2                	mov    %eax,%edx
ffffffff80104d03:	48 b8 00 00 00 42 fe 	movabs $0xfffffffe42000000,%rax
ffffffff80104d0a:	ff ff ff 
ffffffff80104d0d:	48 01 d0             	add    %rdx,%rax
ffffffff80104d10:	48 89 05 29 b9 08 00 	mov    %rax,0x8b929(%rip)        # ffffffff80190640 <lapic>
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
ffffffff80104d17:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104d1b:	48 83 c0 2c          	add    $0x2c,%rax
ffffffff80104d1f:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80104d23:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104d27:	0f b7 40 04          	movzwl 0x4(%rax),%eax
ffffffff80104d2b:	0f b7 d0             	movzwl %ax,%edx
ffffffff80104d2e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80104d32:	48 01 d0             	add    %rdx,%rax
ffffffff80104d35:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80104d39:	e9 95 02 00 00       	jmpq   ffffffff80104fd3 <mpinit+0x311>
    switch(*p){
ffffffff80104d3e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104d42:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104d45:	0f b6 c0             	movzbl %al,%eax
ffffffff80104d48:	83 f8 04             	cmp    $0x4,%eax
ffffffff80104d4b:	0f 87 5b 02 00 00    	ja     ffffffff80104fac <mpinit+0x2ea>
ffffffff80104d51:	89 c0                	mov    %eax,%eax
ffffffff80104d53:	48 8b 04 c5 38 ac 10 	mov    -0x7fef53c8(,%rax,8),%rax
ffffffff80104d5a:	80 
ffffffff80104d5b:	ff e0                	jmpq   *%rax
    case MPPROC:
      proc = (struct mpproc*)p;
ffffffff80104d5d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104d61:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
      cprintf("mpinit ncpu=%d apicid=%d,local apic version:0x%x,cpu flags:0x%x,feature:0x%x\n", ncpu, proc->apicid,proc->version,proc->flags,proc->feature);
ffffffff80104d65:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104d69:	8b 78 08             	mov    0x8(%rax),%edi
ffffffff80104d6c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104d70:	0f b6 40 03          	movzbl 0x3(%rax),%eax
ffffffff80104d74:	0f b6 f0             	movzbl %al,%esi
ffffffff80104d77:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104d7b:	0f b6 40 02          	movzbl 0x2(%rax),%eax
ffffffff80104d7f:	0f b6 c8             	movzbl %al,%ecx
ffffffff80104d82:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104d86:	0f b6 40 01          	movzbl 0x1(%rax),%eax
ffffffff80104d8a:	0f b6 d0             	movzbl %al,%edx
ffffffff80104d8d:	8b 05 51 c1 08 00    	mov    0x8c151(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff80104d93:	41 89 f9             	mov    %edi,%r9d
ffffffff80104d96:	41 89 f0             	mov    %esi,%r8d
ffffffff80104d99:	89 c6                	mov    %eax,%esi
ffffffff80104d9b:	48 c7 c7 e0 aa 10 80 	mov    $0xffffffff8010aae0,%rdi
ffffffff80104da2:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104da7:	e8 f6 b7 ff ff       	callq  ffffffff801005a2 <cprintf>
      if(proc->flags & MPBOOT)
ffffffff80104dac:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104db0:	0f b6 40 03          	movzbl 0x3(%rax),%eax
ffffffff80104db4:	0f b6 c0             	movzbl %al,%eax
ffffffff80104db7:	83 e0 02             	and    $0x2,%eax
ffffffff80104dba:	85 c0                	test   %eax,%eax
ffffffff80104dbc:	74 2c                	je     ffffffff80104dea <mpinit+0x128>
        bcpu = &cpus[ncpu];
ffffffff80104dbe:	8b 05 20 c1 08 00    	mov    0x8c120(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff80104dc4:	48 98                	cltq   
ffffffff80104dc6:	48 89 c2             	mov    %rax,%rdx
ffffffff80104dc9:	48 89 d0             	mov    %rdx,%rax
ffffffff80104dcc:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80104dd0:	48 89 c2             	mov    %rax,%rdx
ffffffff80104dd3:	48 89 d0             	mov    %rdx,%rax
ffffffff80104dd6:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80104dda:	48 29 d0             	sub    %rdx,%rax
ffffffff80104ddd:	48 05 60 07 19 80    	add    $0xffffffff80190760,%rax
ffffffff80104de3:	48 89 05 06 c1 08 00 	mov    %rax,0x8c106(%rip)        # ffffffff80190ef0 <bcpu>
      cpus[ncpu].id = ncpu;
ffffffff80104dea:	8b 05 f4 c0 08 00    	mov    0x8c0f4(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff80104df0:	8b 15 ee c0 08 00    	mov    0x8c0ee(%rip),%edx        # ffffffff80190ee4 <ncpu>
ffffffff80104df6:	89 d1                	mov    %edx,%ecx
ffffffff80104df8:	48 98                	cltq   
ffffffff80104dfa:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80104dfe:	48 89 c2             	mov    %rax,%rdx
ffffffff80104e01:	48 c1 e2 04          	shl    $0x4,%rdx
ffffffff80104e05:	48 29 c2             	sub    %rax,%rdx
ffffffff80104e08:	48 89 d0             	mov    %rdx,%rax
ffffffff80104e0b:	48 05 60 07 19 80    	add    $0xffffffff80190760,%rax
ffffffff80104e11:	88 08                	mov    %cl,(%rax)
      cpus[ncpu].apicid = proc->apicid;
ffffffff80104e13:	8b 0d cb c0 08 00    	mov    0x8c0cb(%rip),%ecx        # ffffffff80190ee4 <ncpu>
ffffffff80104e19:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80104e1d:	0f b6 50 01          	movzbl 0x1(%rax),%edx
ffffffff80104e21:	48 63 c1             	movslq %ecx,%rax
ffffffff80104e24:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80104e28:	48 89 c1             	mov    %rax,%rcx
ffffffff80104e2b:	48 c1 e1 04          	shl    $0x4,%rcx
ffffffff80104e2f:	48 29 c1             	sub    %rax,%rcx
ffffffff80104e32:	48 89 c8             	mov    %rcx,%rax
ffffffff80104e35:	48 05 61 07 19 80    	add    $0xffffffff80190761,%rax
ffffffff80104e3b:	88 10                	mov    %dl,(%rax)
      ncpu++;
ffffffff80104e3d:	8b 05 a1 c0 08 00    	mov    0x8c0a1(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff80104e43:	83 c0 01             	add    $0x1,%eax
ffffffff80104e46:	89 05 98 c0 08 00    	mov    %eax,0x8c098(%rip)        # ffffffff80190ee4 <ncpu>
      p += sizeof(struct mpproc);
ffffffff80104e4c:	48 83 45 f8 14       	addq   $0x14,-0x8(%rbp)
      continue;
ffffffff80104e51:	e9 7d 01 00 00       	jmpq   ffffffff80104fd3 <mpinit+0x311>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
ffffffff80104e56:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104e5a:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
      ioapicid = ioapic->apicno;
ffffffff80104e5e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80104e62:	0f b6 40 01          	movzbl 0x1(%rax),%eax
ffffffff80104e66:	88 05 7c c0 08 00    	mov    %al,0x8c07c(%rip)        # ffffffff80190ee8 <ioapicid>
      p += sizeof(struct mpioapic);
ffffffff80104e6c:	48 83 45 f8 08       	addq   $0x8,-0x8(%rbp)
      cprintf("mp config io apic:\n");
ffffffff80104e71:	48 c7 c7 2e ab 10 80 	mov    $0xffffffff8010ab2e,%rdi
ffffffff80104e78:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104e7d:	e8 20 b7 ff ff       	callq  ffffffff801005a2 <cprintf>
      cprintf("ioapic: id:0x%x, version:0x%x,flags:0x%x,mmio:0x%p\n",ioapic->apicno,ioapic->version,ioapic->flags,ioapic->addr);
ffffffff80104e82:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80104e86:	8b 70 04             	mov    0x4(%rax),%esi
ffffffff80104e89:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80104e8d:	0f b6 40 03          	movzbl 0x3(%rax),%eax
ffffffff80104e91:	0f b6 c8             	movzbl %al,%ecx
ffffffff80104e94:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80104e98:	0f b6 40 02          	movzbl 0x2(%rax),%eax
ffffffff80104e9c:	0f b6 d0             	movzbl %al,%edx
ffffffff80104e9f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80104ea3:	0f b6 40 01          	movzbl 0x1(%rax),%eax
ffffffff80104ea7:	0f b6 c0             	movzbl %al,%eax
ffffffff80104eaa:	41 89 f0             	mov    %esi,%r8d
ffffffff80104ead:	89 c6                	mov    %eax,%esi
ffffffff80104eaf:	48 c7 c7 48 ab 10 80 	mov    $0xffffffff8010ab48,%rdi
ffffffff80104eb6:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104ebb:	e8 e2 b6 ff ff       	callq  ffffffff801005a2 <cprintf>
      continue;
ffffffff80104ec0:	e9 0e 01 00 00       	jmpq   ffffffff80104fd3 <mpinit+0x311>
    case MPBUS:
		mpbus = (struct mpbus *)p;
ffffffff80104ec5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104ec9:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
		cprintf("mp config bus:\n");
ffffffff80104ecd:	48 c7 c7 7c ab 10 80 	mov    $0xffffffff8010ab7c,%rdi
ffffffff80104ed4:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104ed9:	e8 c4 b6 ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("bus id:0x%x\n",mpbus->busid);
ffffffff80104ede:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80104ee2:	0f b6 40 01          	movzbl 0x1(%rax),%eax
ffffffff80104ee6:	0f b6 c0             	movzbl %al,%eax
ffffffff80104ee9:	89 c6                	mov    %eax,%esi
ffffffff80104eeb:	48 c7 c7 8c ab 10 80 	mov    $0xffffffff8010ab8c,%rdi
ffffffff80104ef2:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104ef7:	e8 a6 b6 ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("bus type:%s\n",mpbus->bustype);
ffffffff80104efc:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80104f00:	48 83 c0 02          	add    $0x2,%rax
ffffffff80104f04:	48 89 c6             	mov    %rax,%rsi
ffffffff80104f07:	48 c7 c7 99 ab 10 80 	mov    $0xffffffff8010ab99,%rdi
ffffffff80104f0e:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104f13:	e8 8a b6 ff ff       	callq  ffffffff801005a2 <cprintf>
		
		p += sizeof(struct mpbus);
ffffffff80104f18:	48 83 45 f8 08       	addq   $0x8,-0x8(%rbp)
		continue;
ffffffff80104f1d:	e9 b1 00 00 00       	jmpq   ffffffff80104fd3 <mpinit+0x311>
    case MPIOINTR:
		iointr = (struct mpiointr *)p;
ffffffff80104f22:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104f26:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
		p+=8;
ffffffff80104f2a:	48 83 45 f8 08       	addq   $0x8,-0x8(%rbp)
		cprintf("mp io intr:\n");
ffffffff80104f2f:	48 c7 c7 a6 ab 10 80 	mov    $0xffffffff8010aba6,%rdi
ffffffff80104f36:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104f3b:	e8 62 b6 ff ff       	callq  ffffffff801005a2 <cprintf>
		cprintf("intr_type:0x%x,io_intr_flag:0x%x,s_id:0x%x,s_irq:0x%x,d_ioapic_id:0x%x,d_ioapic_intin:0x%x\n",iointr->intr_type,iointr->io_intr_flag,iointr->s_bus_id,iointr->s_bus_irq,iointr->d_io_apic_id,iointr->d_io_apic_intin);
ffffffff80104f40:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80104f44:	0f b6 40 07          	movzbl 0x7(%rax),%eax
ffffffff80104f48:	0f b6 f0             	movzbl %al,%esi
ffffffff80104f4b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80104f4f:	0f b6 40 06          	movzbl 0x6(%rax),%eax
ffffffff80104f53:	44 0f b6 c0          	movzbl %al,%r8d
ffffffff80104f57:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80104f5b:	0f b6 40 05          	movzbl 0x5(%rax),%eax
ffffffff80104f5f:	0f b6 f8             	movzbl %al,%edi
ffffffff80104f62:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80104f66:	0f b6 40 04          	movzbl 0x4(%rax),%eax
ffffffff80104f6a:	0f b6 c8             	movzbl %al,%ecx
ffffffff80104f6d:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80104f71:	0f b7 40 02          	movzwl 0x2(%rax),%eax
ffffffff80104f75:	0f b7 d0             	movzwl %ax,%edx
ffffffff80104f78:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80104f7c:	0f b6 40 01          	movzbl 0x1(%rax),%eax
ffffffff80104f80:	0f b6 c0             	movzbl %al,%eax
ffffffff80104f83:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80104f87:	56                   	push   %rsi
ffffffff80104f88:	45 89 c1             	mov    %r8d,%r9d
ffffffff80104f8b:	41 89 f8             	mov    %edi,%r8d
ffffffff80104f8e:	89 c6                	mov    %eax,%esi
ffffffff80104f90:	48 c7 c7 b8 ab 10 80 	mov    $0xffffffff8010abb8,%rdi
ffffffff80104f97:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104f9c:	e8 01 b6 ff ff       	callq  ffffffff801005a2 <cprintf>
ffffffff80104fa1:	48 83 c4 10          	add    $0x10,%rsp
    case MPLINTR:
     
      p += 8;
ffffffff80104fa5:	48 83 45 f8 08       	addq   $0x8,-0x8(%rbp)
      continue;
ffffffff80104faa:	eb 27                	jmp    ffffffff80104fd3 <mpinit+0x311>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
ffffffff80104fac:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104fb0:	0f b6 00             	movzbl (%rax),%eax
ffffffff80104fb3:	0f b6 c0             	movzbl %al,%eax
ffffffff80104fb6:	89 c6                	mov    %eax,%esi
ffffffff80104fb8:	48 c7 c7 18 ac 10 80 	mov    $0xffffffff8010ac18,%rdi
ffffffff80104fbf:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80104fc4:	e8 d9 b5 ff ff       	callq  ffffffff801005a2 <cprintf>
      ismp = 0;
ffffffff80104fc9:	c7 05 0d bf 08 00 00 	movl   $0x0,0x8bf0d(%rip)        # ffffffff80190ee0 <ismp>
ffffffff80104fd0:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = IO2V((uintp)conf->lapicaddr);
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
ffffffff80104fd3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80104fd7:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff80104fdb:	0f 82 5d fd ff ff    	jb     ffffffff80104d3e <mpinit+0x7c>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
ffffffff80104fe1:	8b 05 f9 be 08 00    	mov    0x8bef9(%rip),%eax        # ffffffff80190ee0 <ismp>
ffffffff80104fe7:	85 c0                	test   %eax,%eax
ffffffff80104fe9:	75 1e                	jne    ffffffff80105009 <mpinit+0x347>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
ffffffff80104feb:	c7 05 ef be 08 00 01 	movl   $0x1,0x8beef(%rip)        # ffffffff80190ee4 <ncpu>
ffffffff80104ff2:	00 00 00 
    lapic = 0;
ffffffff80104ff5:	48 c7 05 40 b6 08 00 	movq   $0x0,0x8b640(%rip)        # ffffffff80190640 <lapic>
ffffffff80104ffc:	00 00 00 00 
    ioapicid = 0;
ffffffff80105000:	c6 05 e1 be 08 00 00 	movb   $0x0,0x8bee1(%rip)        # ffffffff80190ee8 <ioapicid>
    return;
ffffffff80105007:	eb 3a                	jmp    ffffffff80105043 <mpinit+0x381>
  }

  if(mp->imcrp){
ffffffff80105009:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff8010500d:	0f b6 40 0c          	movzbl 0xc(%rax),%eax
ffffffff80105011:	84 c0                	test   %al,%al
ffffffff80105013:	74 2e                	je     ffffffff80105043 <mpinit+0x381>
    // it would run on real hardware.
    outb(0x22, 0x70);   // Select IMCR
ffffffff80105015:	be 70 00 00 00       	mov    $0x70,%esi
ffffffff8010501a:	bf 22 00 00 00       	mov    $0x22,%edi
ffffffff8010501f:	e8 9d f8 ff ff       	callq  ffffffff801048c1 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
ffffffff80105024:	bf 23 00 00 00       	mov    $0x23,%edi
ffffffff80105029:	e8 75 f8 ff ff       	callq  ffffffff801048a3 <inb>
ffffffff8010502e:	83 c8 01             	or     $0x1,%eax
ffffffff80105031:	0f b6 c0             	movzbl %al,%eax
ffffffff80105034:	89 c6                	mov    %eax,%esi
ffffffff80105036:	bf 23 00 00 00       	mov    $0x23,%edi
ffffffff8010503b:	e8 81 f8 ff ff       	callq  ffffffff801048c1 <outb>
ffffffff80105040:	eb 01                	jmp    ffffffff80105043 <mpinit+0x381>
  struct mpbus *mpbus;
  struct mpiointr  *iointr;
  
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
ffffffff80105042:	90                   	nop
  if(mp->imcrp){
    // it would run on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
ffffffff80105043:	c9                   	leaveq 
ffffffff80105044:	c3                   	retq   

ffffffff80105045 <p2v>:
ffffffff80105045:	55                   	push   %rbp
ffffffff80105046:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105049:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff8010504d:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80105051:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105055:	48 05 00 00 00 80    	add    $0xffffffff80000000,%rax
ffffffff8010505b:	c9                   	leaveq 
ffffffff8010505c:	c3                   	retq   

ffffffff8010505d <scan_rdsp>:
extern struct cpu cpus[NCPU];
extern int ismp;
extern int ncpu;
extern uchar ioapicid;

static struct acpi_rdsp *scan_rdsp(uint base, uint len) {
ffffffff8010505d:	55                   	push   %rbp
ffffffff8010505e:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105061:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80105065:	89 7d ec             	mov    %edi,-0x14(%rbp)
ffffffff80105068:	89 75 e8             	mov    %esi,-0x18(%rbp)
  uchar *p;
  for (p = p2v(base); len >= sizeof(struct acpi_rdsp); len -= 4, p += 4) {
ffffffff8010506b:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff8010506e:	48 89 c7             	mov    %rax,%rdi
ffffffff80105071:	e8 cf ff ff ff       	callq  ffffffff80105045 <p2v>
ffffffff80105076:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff8010507a:	eb 62                	jmp    ffffffff801050de <scan_rdsp+0x81>
    if (memcmp(p, SIG_RDSP, 8) == 0) {
ffffffff8010507c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105080:	ba 08 00 00 00       	mov    $0x8,%edx
ffffffff80105085:	48 c7 c6 60 ac 10 80 	mov    $0xffffffff8010ac60,%rsi
ffffffff8010508c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010508f:	e8 f9 1b 00 00       	callq  ffffffff80106c8d <memcmp>
ffffffff80105094:	85 c0                	test   %eax,%eax
ffffffff80105096:	75 3d                	jne    ffffffff801050d5 <scan_rdsp+0x78>
      uint sum, n;
      for (sum = 0, n = 0; n < 20; n++)
ffffffff80105098:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
ffffffff8010509f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%rbp)
ffffffff801050a6:	eb 17                	jmp    ffffffff801050bf <scan_rdsp+0x62>
        sum += p[n];
ffffffff801050a8:	8b 55 f0             	mov    -0x10(%rbp),%edx
ffffffff801050ab:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801050af:	48 01 d0             	add    %rdx,%rax
ffffffff801050b2:	0f b6 00             	movzbl (%rax),%eax
ffffffff801050b5:	0f b6 c0             	movzbl %al,%eax
ffffffff801050b8:	01 45 f4             	add    %eax,-0xc(%rbp)
static struct acpi_rdsp *scan_rdsp(uint base, uint len) {
  uchar *p;
  for (p = p2v(base); len >= sizeof(struct acpi_rdsp); len -= 4, p += 4) {
    if (memcmp(p, SIG_RDSP, 8) == 0) {
      uint sum, n;
      for (sum = 0, n = 0; n < 20; n++)
ffffffff801050bb:	83 45 f0 01          	addl   $0x1,-0x10(%rbp)
ffffffff801050bf:	83 7d f0 13          	cmpl   $0x13,-0x10(%rbp)
ffffffff801050c3:	76 e3                	jbe    ffffffff801050a8 <scan_rdsp+0x4b>
        sum += p[n];
      if ((sum & 0xff) == 0)
ffffffff801050c5:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff801050c8:	0f b6 c0             	movzbl %al,%eax
ffffffff801050cb:	85 c0                	test   %eax,%eax
ffffffff801050cd:	75 06                	jne    ffffffff801050d5 <scan_rdsp+0x78>
        return (struct acpi_rdsp *) p;
ffffffff801050cf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801050d3:	eb 14                	jmp    ffffffff801050e9 <scan_rdsp+0x8c>
extern int ncpu;
extern uchar ioapicid;

static struct acpi_rdsp *scan_rdsp(uint base, uint len) {
  uchar *p;
  for (p = p2v(base); len >= sizeof(struct acpi_rdsp); len -= 4, p += 4) {
ffffffff801050d5:	83 6d e8 04          	subl   $0x4,-0x18(%rbp)
ffffffff801050d9:	48 83 45 f8 04       	addq   $0x4,-0x8(%rbp)
ffffffff801050de:	83 7d e8 23          	cmpl   $0x23,-0x18(%rbp)
ffffffff801050e2:	77 98                	ja     ffffffff8010507c <scan_rdsp+0x1f>
        sum += p[n];
      if ((sum & 0xff) == 0)
        return (struct acpi_rdsp *) p;
    }
  }
  return (struct acpi_rdsp *) 0;  
ffffffff801050e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff801050e9:	c9                   	leaveq 
ffffffff801050ea:	c3                   	retq   

ffffffff801050eb <find_rdsp>:

static struct acpi_rdsp *find_rdsp(void) {
ffffffff801050eb:	55                   	push   %rbp
ffffffff801050ec:	48 89 e5             	mov    %rsp,%rbp
ffffffff801050ef:	48 83 ec 10          	sub    $0x10,%rsp
  struct acpi_rdsp *rdsp;
  uintp pa;
  pa = *((ushort*) P2V(0x40E)) << 4; // EBDA
ffffffff801050f3:	48 c7 c0 0e 04 00 80 	mov    $0xffffffff8000040e,%rax
ffffffff801050fa:	0f b7 00             	movzwl (%rax),%eax
ffffffff801050fd:	0f b7 c0             	movzwl %ax,%eax
ffffffff80105100:	c1 e0 04             	shl    $0x4,%eax
ffffffff80105103:	48 98                	cltq   
ffffffff80105105:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if (pa && (rdsp = scan_rdsp(pa, 1024)))
ffffffff80105109:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff8010510e:	74 21                	je     ffffffff80105131 <find_rdsp+0x46>
ffffffff80105110:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105114:	be 00 04 00 00       	mov    $0x400,%esi
ffffffff80105119:	89 c7                	mov    %eax,%edi
ffffffff8010511b:	e8 3d ff ff ff       	callq  ffffffff8010505d <scan_rdsp>
ffffffff80105120:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80105124:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80105129:	74 06                	je     ffffffff80105131 <find_rdsp+0x46>
    return rdsp;
ffffffff8010512b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010512f:	eb 0f                	jmp    ffffffff80105140 <find_rdsp+0x55>
  return scan_rdsp(0xE0000, 0x20000);
ffffffff80105131:	be 00 00 02 00       	mov    $0x20000,%esi
ffffffff80105136:	bf 00 00 0e 00       	mov    $0xe0000,%edi
ffffffff8010513b:	e8 1d ff ff ff       	callq  ffffffff8010505d <scan_rdsp>
} 
ffffffff80105140:	c9                   	leaveq 
ffffffff80105141:	c3                   	retq   

ffffffff80105142 <acpi_config_smp>:

static int acpi_config_smp(struct acpi_madt *madt) {
ffffffff80105142:	55                   	push   %rbp
ffffffff80105143:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105146:	48 83 ec 50          	sub    $0x50,%rsp
ffffffff8010514a:	48 89 7d b8          	mov    %rdi,-0x48(%rbp)
  uint32 lapic_addr;
  uint nioapic = 0;
ffffffff8010514e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  uchar *p, *e;

  if (!madt)
ffffffff80105155:	48 83 7d b8 00       	cmpq   $0x0,-0x48(%rbp)
ffffffff8010515a:	75 0a                	jne    ffffffff80105166 <acpi_config_smp+0x24>
    return -1;
ffffffff8010515c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80105161:	e9 17 02 00 00       	jmpq   ffffffff8010537d <acpi_config_smp+0x23b>
  if (madt->header.length < sizeof(struct acpi_madt))
ffffffff80105166:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff8010516a:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff8010516d:	83 f8 2b             	cmp    $0x2b,%eax
ffffffff80105170:	77 0a                	ja     ffffffff8010517c <acpi_config_smp+0x3a>
    return -1;
ffffffff80105172:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80105177:	e9 01 02 00 00       	jmpq   ffffffff8010537d <acpi_config_smp+0x23b>

  lapic_addr = madt->lapic_addr_phys;
ffffffff8010517c:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff80105180:	8b 40 24             	mov    0x24(%rax),%eax
ffffffff80105183:	89 45 ec             	mov    %eax,-0x14(%rbp)

  p = madt->table;
ffffffff80105186:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff8010518a:	48 83 c0 2c          	add    $0x2c,%rax
ffffffff8010518e:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  e = p + madt->header.length - sizeof(struct acpi_madt);
ffffffff80105192:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff80105196:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80105199:	89 c0                	mov    %eax,%eax
ffffffff8010519b:	48 8d 50 d4          	lea    -0x2c(%rax),%rdx
ffffffff8010519f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801051a3:	48 01 d0             	add    %rdx,%rax
ffffffff801051a6:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

  while (p < e) {
ffffffff801051aa:	e9 83 01 00 00       	jmpq   ffffffff80105332 <acpi_config_smp+0x1f0>
    uint len;
    if ((e - p) < 2)
ffffffff801051af:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff801051b3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801051b7:	48 29 c2             	sub    %rax,%rdx
ffffffff801051ba:	48 89 d0             	mov    %rdx,%rax
ffffffff801051bd:	48 83 f8 01          	cmp    $0x1,%rax
ffffffff801051c1:	0f 8e 7b 01 00 00    	jle    ffffffff80105342 <acpi_config_smp+0x200>
      break;
    len = p[1];
ffffffff801051c7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801051cb:	48 83 c0 01          	add    $0x1,%rax
ffffffff801051cf:	0f b6 00             	movzbl (%rax),%eax
ffffffff801051d2:	0f b6 c0             	movzbl %al,%eax
ffffffff801051d5:	89 45 dc             	mov    %eax,-0x24(%rbp)
    if ((e - p) < len)
ffffffff801051d8:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff801051dc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801051e0:	48 29 c2             	sub    %rax,%rdx
ffffffff801051e3:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff801051e6:	48 39 c2             	cmp    %rax,%rdx
ffffffff801051e9:	0f 8c 56 01 00 00    	jl     ffffffff80105345 <acpi_config_smp+0x203>
      break;
    switch (p[0]) {
ffffffff801051ef:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801051f3:	0f b6 00             	movzbl (%rax),%eax
ffffffff801051f6:	0f b6 c0             	movzbl %al,%eax
ffffffff801051f9:	85 c0                	test   %eax,%eax
ffffffff801051fb:	74 0e                	je     ffffffff8010520b <acpi_config_smp+0xc9>
ffffffff801051fd:	83 f8 01             	cmp    $0x1,%eax
ffffffff80105200:	0f 84 b1 00 00 00    	je     ffffffff801052b7 <acpi_config_smp+0x175>
ffffffff80105206:	e9 20 01 00 00       	jmpq   ffffffff8010532b <acpi_config_smp+0x1e9>
    case TYPE_LAPIC: {
      struct madt_lapic *lapic = (void*) p;
ffffffff8010520b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010520f:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
      if (len < sizeof(*lapic))
ffffffff80105213:	83 7d dc 07          	cmpl   $0x7,-0x24(%rbp)
ffffffff80105217:	0f 86 07 01 00 00    	jbe    ffffffff80105324 <acpi_config_smp+0x1e2>
        break;
      if (!(lapic->flags & APIC_LAPIC_ENABLED))
ffffffff8010521d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80105221:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff80105224:	83 e0 01             	and    $0x1,%eax
ffffffff80105227:	85 c0                	test   %eax,%eax
ffffffff80105229:	0f 84 f8 00 00 00    	je     ffffffff80105327 <acpi_config_smp+0x1e5>
        break;
      cprintf("acpi: cpu#%d apicid %d\n", ncpu, lapic->apic_id);
ffffffff8010522f:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80105233:	0f b6 40 03          	movzbl 0x3(%rax),%eax
ffffffff80105237:	0f b6 d0             	movzbl %al,%edx
ffffffff8010523a:	8b 05 a4 bc 08 00    	mov    0x8bca4(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff80105240:	89 c6                	mov    %eax,%esi
ffffffff80105242:	48 c7 c7 69 ac 10 80 	mov    $0xffffffff8010ac69,%rdi
ffffffff80105249:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010524e:	e8 4f b3 ff ff       	callq  ffffffff801005a2 <cprintf>
      cpus[ncpu].id = ncpu;
ffffffff80105253:	8b 05 8b bc 08 00    	mov    0x8bc8b(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff80105259:	8b 15 85 bc 08 00    	mov    0x8bc85(%rip),%edx        # ffffffff80190ee4 <ncpu>
ffffffff8010525f:	89 d1                	mov    %edx,%ecx
ffffffff80105261:	48 98                	cltq   
ffffffff80105263:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80105267:	48 89 c2             	mov    %rax,%rdx
ffffffff8010526a:	48 c1 e2 04          	shl    $0x4,%rdx
ffffffff8010526e:	48 29 c2             	sub    %rax,%rdx
ffffffff80105271:	48 89 d0             	mov    %rdx,%rax
ffffffff80105274:	48 05 60 07 19 80    	add    $0xffffffff80190760,%rax
ffffffff8010527a:	88 08                	mov    %cl,(%rax)
      cpus[ncpu].apicid = lapic->apic_id;
ffffffff8010527c:	8b 0d 62 bc 08 00    	mov    0x8bc62(%rip),%ecx        # ffffffff80190ee4 <ncpu>
ffffffff80105282:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80105286:	0f b6 50 03          	movzbl 0x3(%rax),%edx
ffffffff8010528a:	48 63 c1             	movslq %ecx,%rax
ffffffff8010528d:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80105291:	48 89 c1             	mov    %rax,%rcx
ffffffff80105294:	48 c1 e1 04          	shl    $0x4,%rcx
ffffffff80105298:	48 29 c1             	sub    %rax,%rcx
ffffffff8010529b:	48 89 c8             	mov    %rcx,%rax
ffffffff8010529e:	48 05 61 07 19 80    	add    $0xffffffff80190761,%rax
ffffffff801052a4:	88 10                	mov    %dl,(%rax)
      ncpu++;
ffffffff801052a6:	8b 05 38 bc 08 00    	mov    0x8bc38(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff801052ac:	83 c0 01             	add    $0x1,%eax
ffffffff801052af:	89 05 2f bc 08 00    	mov    %eax,0x8bc2f(%rip)        # ffffffff80190ee4 <ncpu>
      break;
ffffffff801052b5:	eb 74                	jmp    ffffffff8010532b <acpi_config_smp+0x1e9>
    }
    case TYPE_IOAPIC: {
      struct madt_ioapic *ioapic = (void*) p;
ffffffff801052b7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801052bb:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
      if (len < sizeof(*ioapic))
ffffffff801052bf:	83 7d dc 0b          	cmpl   $0xb,-0x24(%rbp)
ffffffff801052c3:	76 65                	jbe    ffffffff8010532a <acpi_config_smp+0x1e8>
        break;
      cprintf("acpi: ioapic#%d @%x id=%d base=%d\n",
ffffffff801052c5:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801052c9:	8b 70 08             	mov    0x8(%rax),%esi
        nioapic, ioapic->addr, ioapic->id, ioapic->interrupt_base);
ffffffff801052cc:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801052d0:	0f b6 40 02          	movzbl 0x2(%rax),%eax
    }
    case TYPE_IOAPIC: {
      struct madt_ioapic *ioapic = (void*) p;
      if (len < sizeof(*ioapic))
        break;
      cprintf("acpi: ioapic#%d @%x id=%d base=%d\n",
ffffffff801052d4:	0f b6 c8             	movzbl %al,%ecx
ffffffff801052d7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801052db:	8b 50 04             	mov    0x4(%rax),%edx
ffffffff801052de:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801052e1:	41 89 f0             	mov    %esi,%r8d
ffffffff801052e4:	89 c6                	mov    %eax,%esi
ffffffff801052e6:	48 c7 c7 88 ac 10 80 	mov    $0xffffffff8010ac88,%rdi
ffffffff801052ed:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801052f2:	e8 ab b2 ff ff       	callq  ffffffff801005a2 <cprintf>
        nioapic, ioapic->addr, ioapic->id, ioapic->interrupt_base);
      if (nioapic) {
ffffffff801052f7:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff801052fb:	74 13                	je     ffffffff80105310 <acpi_config_smp+0x1ce>
        cprintf("warning: multiple ioapics are not supported");
ffffffff801052fd:	48 c7 c7 b0 ac 10 80 	mov    $0xffffffff8010acb0,%rdi
ffffffff80105304:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80105309:	e8 94 b2 ff ff       	callq  ffffffff801005a2 <cprintf>
ffffffff8010530e:	eb 0e                	jmp    ffffffff8010531e <acpi_config_smp+0x1dc>
      } else {
        ioapicid = ioapic->id;
ffffffff80105310:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80105314:	0f b6 40 02          	movzbl 0x2(%rax),%eax
ffffffff80105318:	88 05 ca bb 08 00    	mov    %al,0x8bbca(%rip)        # ffffffff80190ee8 <ioapicid>
      }
      nioapic++;
ffffffff8010531e:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
      break;
ffffffff80105322:	eb 07                	jmp    ffffffff8010532b <acpi_config_smp+0x1e9>
      break;
    switch (p[0]) {
    case TYPE_LAPIC: {
      struct madt_lapic *lapic = (void*) p;
      if (len < sizeof(*lapic))
        break;
ffffffff80105324:	90                   	nop
ffffffff80105325:	eb 04                	jmp    ffffffff8010532b <acpi_config_smp+0x1e9>
      if (!(lapic->flags & APIC_LAPIC_ENABLED))
        break;
ffffffff80105327:	90                   	nop
ffffffff80105328:	eb 01                	jmp    ffffffff8010532b <acpi_config_smp+0x1e9>
      break;
    }
    case TYPE_IOAPIC: {
      struct madt_ioapic *ioapic = (void*) p;
      if (len < sizeof(*ioapic))
        break;
ffffffff8010532a:	90                   	nop
      }
      nioapic++;
      break;
    }
    }
    p += len;
ffffffff8010532b:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff8010532e:	48 01 45 f0          	add    %rax,-0x10(%rbp)
  lapic_addr = madt->lapic_addr_phys;

  p = madt->table;
  e = p + madt->header.length - sizeof(struct acpi_madt);

  while (p < e) {
ffffffff80105332:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105336:	48 3b 45 e0          	cmp    -0x20(%rbp),%rax
ffffffff8010533a:	0f 82 6f fe ff ff    	jb     ffffffff801051af <acpi_config_smp+0x6d>
ffffffff80105340:	eb 04                	jmp    ffffffff80105346 <acpi_config_smp+0x204>
    uint len;
    if ((e - p) < 2)
      break;
ffffffff80105342:	90                   	nop
ffffffff80105343:	eb 01                	jmp    ffffffff80105346 <acpi_config_smp+0x204>
    len = p[1];
    if ((e - p) < len)
      break;
ffffffff80105345:	90                   	nop
    }
    }
    p += len;
  }

  if (ncpu) {
ffffffff80105346:	8b 05 98 bb 08 00    	mov    0x8bb98(%rip),%eax        # ffffffff80190ee4 <ncpu>
ffffffff8010534c:	85 c0                	test   %eax,%eax
ffffffff8010534e:	74 28                	je     ffffffff80105378 <acpi_config_smp+0x236>
    ismp = 1;
ffffffff80105350:	c7 05 86 bb 08 00 01 	movl   $0x1,0x8bb86(%rip)        # ffffffff80190ee0 <ismp>
ffffffff80105357:	00 00 00 
    lapic = IO2V(((uintp)lapic_addr));
ffffffff8010535a:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff8010535d:	48 b8 00 00 00 42 fe 	movabs $0xfffffffe42000000,%rax
ffffffff80105364:	ff ff ff 
ffffffff80105367:	48 01 d0             	add    %rdx,%rax
ffffffff8010536a:	48 89 05 cf b2 08 00 	mov    %rax,0x8b2cf(%rip)        # ffffffff80190640 <lapic>
    return 0;
ffffffff80105371:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80105376:	eb 05                	jmp    ffffffff8010537d <acpi_config_smp+0x23b>
  }

  return -1;
ffffffff80105378:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff8010537d:	c9                   	leaveq 
ffffffff8010537e:	c3                   	retq   

ffffffff8010537f <acpiinit>:
#define PHYSLIMIT 0x80000000
#else
#define PHYSLIMIT 0x0E000000
#endif

int acpiinit(void) {
ffffffff8010537f:	55                   	push   %rbp
ffffffff80105380:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105383:	48 83 ec 70          	sub    $0x70,%rsp
  unsigned n, count;
  struct acpi_rdsp *rdsp;
  struct acpi_rsdt *rsdt;
  struct acpi_madt *madt = 0;
ffffffff80105387:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
ffffffff8010538e:	00 

  rdsp = find_rdsp();
ffffffff8010538f:	e8 57 fd ff ff       	callq  ffffffff801050eb <find_rdsp>
ffffffff80105394:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  if (rdsp->rsdt_addr_phys > PHYSLIMIT)
ffffffff80105398:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010539c:	8b 40 10             	mov    0x10(%rax),%eax
ffffffff8010539f:	3d 00 00 00 80       	cmp    $0x80000000,%eax
ffffffff801053a4:	0f 87 6b 01 00 00    	ja     ffffffff80105515 <acpiinit+0x196>
    goto notmapped;
  rsdt = p2v(rdsp->rsdt_addr_phys);
ffffffff801053aa:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801053ae:	8b 40 10             	mov    0x10(%rax),%eax
ffffffff801053b1:	89 c0                	mov    %eax,%eax
ffffffff801053b3:	48 89 c7             	mov    %rax,%rdi
ffffffff801053b6:	e8 8a fc ff ff       	callq  ffffffff80105045 <p2v>
ffffffff801053bb:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  count = (rsdt->header.length - sizeof(*rsdt)) / 4;
ffffffff801053bf:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801053c3:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff801053c6:	89 c0                	mov    %eax,%eax
ffffffff801053c8:	48 83 e8 24          	sub    $0x24,%rax
ffffffff801053cc:	48 c1 e8 02          	shr    $0x2,%rax
ffffffff801053d0:	89 45 dc             	mov    %eax,-0x24(%rbp)
  for (n = 0; n < count; n++) {
ffffffff801053d3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801053da:	e9 1c 01 00 00       	jmpq   ffffffff801054fb <acpiinit+0x17c>
    struct acpi_desc_header *hdr = p2v(rsdt->entry[n]);
ffffffff801053df:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801053e3:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801053e6:	48 83 c2 08          	add    $0x8,%rdx
ffffffff801053ea:	8b 44 90 04          	mov    0x4(%rax,%rdx,4),%eax
ffffffff801053ee:	89 c0                	mov    %eax,%eax
ffffffff801053f0:	48 89 c7             	mov    %rax,%rdi
ffffffff801053f3:	e8 4d fc ff ff       	callq  ffffffff80105045 <p2v>
ffffffff801053f8:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
    if (rsdt->entry[n] > PHYSLIMIT)
ffffffff801053fc:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80105400:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80105403:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80105407:	8b 44 90 04          	mov    0x4(%rax,%rdx,4),%eax
ffffffff8010540b:	3d 00 00 00 80       	cmp    $0x80000000,%eax
ffffffff80105410:	0f 87 02 01 00 00    	ja     ffffffff80105518 <acpiinit+0x199>
      goto notmapped;
//#if DEBUG
#if 1
    uchar sig[5], id[7], tableid[9], creator[5];
    memmove(sig, hdr->signature, 4); sig[4] = 0;
ffffffff80105416:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
ffffffff8010541a:	48 8d 45 c0          	lea    -0x40(%rbp),%rax
ffffffff8010541e:	ba 04 00 00 00       	mov    $0x4,%edx
ffffffff80105423:	48 89 ce             	mov    %rcx,%rsi
ffffffff80105426:	48 89 c7             	mov    %rax,%rdi
ffffffff80105429:	e8 ce 18 00 00       	callq  ffffffff80106cfc <memmove>
ffffffff8010542e:	c6 45 c4 00          	movb   $0x0,-0x3c(%rbp)
    memmove(id, hdr->oem_id, 6); id[6] = 0;
ffffffff80105432:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80105436:	48 8d 48 0a          	lea    0xa(%rax),%rcx
ffffffff8010543a:	48 8d 45 b0          	lea    -0x50(%rbp),%rax
ffffffff8010543e:	ba 06 00 00 00       	mov    $0x6,%edx
ffffffff80105443:	48 89 ce             	mov    %rcx,%rsi
ffffffff80105446:	48 89 c7             	mov    %rax,%rdi
ffffffff80105449:	e8 ae 18 00 00       	callq  ffffffff80106cfc <memmove>
ffffffff8010544e:	c6 45 b6 00          	movb   $0x0,-0x4a(%rbp)
    memmove(tableid, hdr->oem_tableid, 8); tableid[8] = 0;
ffffffff80105452:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80105456:	48 8d 48 10          	lea    0x10(%rax),%rcx
ffffffff8010545a:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
ffffffff8010545e:	ba 08 00 00 00       	mov    $0x8,%edx
ffffffff80105463:	48 89 ce             	mov    %rcx,%rsi
ffffffff80105466:	48 89 c7             	mov    %rax,%rdi
ffffffff80105469:	e8 8e 18 00 00       	callq  ffffffff80106cfc <memmove>
ffffffff8010546e:	c6 45 a8 00          	movb   $0x0,-0x58(%rbp)
    memmove(creator, hdr->creator_id, 4); creator[4] = 0;
ffffffff80105472:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80105476:	48 8d 48 1c          	lea    0x1c(%rax),%rcx
ffffffff8010547a:	48 8d 45 90          	lea    -0x70(%rbp),%rax
ffffffff8010547e:	ba 04 00 00 00       	mov    $0x4,%edx
ffffffff80105483:	48 89 ce             	mov    %rcx,%rsi
ffffffff80105486:	48 89 c7             	mov    %rax,%rdi
ffffffff80105489:	e8 6e 18 00 00       	callq  ffffffff80106cfc <memmove>
ffffffff8010548e:	c6 45 94 00          	movb   $0x0,-0x6c(%rbp)
    cprintf("acpi: %s %s %s %x %s %x\n",
ffffffff80105492:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80105496:	8b 70 20             	mov    0x20(%rax),%esi
ffffffff80105499:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff8010549d:	8b 78 18             	mov    0x18(%rax),%edi
ffffffff801054a0:	4c 8d 45 90          	lea    -0x70(%rbp),%r8
ffffffff801054a4:	48 8d 4d a0          	lea    -0x60(%rbp),%rcx
ffffffff801054a8:	48 8d 55 b0          	lea    -0x50(%rbp),%rdx
ffffffff801054ac:	48 8d 45 c0          	lea    -0x40(%rbp),%rax
ffffffff801054b0:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801054b4:	56                   	push   %rsi
ffffffff801054b5:	4d 89 c1             	mov    %r8,%r9
ffffffff801054b8:	41 89 f8             	mov    %edi,%r8d
ffffffff801054bb:	48 89 c6             	mov    %rax,%rsi
ffffffff801054be:	48 c7 c7 dc ac 10 80 	mov    $0xffffffff8010acdc,%rdi
ffffffff801054c5:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801054ca:	e8 d3 b0 ff ff       	callq  ffffffff801005a2 <cprintf>
ffffffff801054cf:	48 83 c4 10          	add    $0x10,%rsp
      sig, id, tableid, hdr->oem_revision,
      creator, hdr->creator_revision);
#endif
    if (!memcmp(hdr->signature, SIG_MADT, 4))
ffffffff801054d3:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff801054d7:	ba 04 00 00 00       	mov    $0x4,%edx
ffffffff801054dc:	48 c7 c6 f5 ac 10 80 	mov    $0xffffffff8010acf5,%rsi
ffffffff801054e3:	48 89 c7             	mov    %rax,%rdi
ffffffff801054e6:	e8 a2 17 00 00       	callq  ffffffff80106c8d <memcmp>
ffffffff801054eb:	85 c0                	test   %eax,%eax
ffffffff801054ed:	75 08                	jne    ffffffff801054f7 <acpiinit+0x178>
      madt = (void*) hdr;
ffffffff801054ef:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff801054f3:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  rdsp = find_rdsp();
  if (rdsp->rsdt_addr_phys > PHYSLIMIT)
    goto notmapped;
  rsdt = p2v(rdsp->rsdt_addr_phys);
  count = (rsdt->header.length - sizeof(*rsdt)) / 4;
  for (n = 0; n < count; n++) {
ffffffff801054f7:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801054fb:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801054fe:	3b 45 dc             	cmp    -0x24(%rbp),%eax
ffffffff80105501:	0f 82 d8 fe ff ff    	jb     ffffffff801053df <acpiinit+0x60>
#endif
    if (!memcmp(hdr->signature, SIG_MADT, 4))
      madt = (void*) hdr;
  }

  return acpi_config_smp(madt);
ffffffff80105507:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010550b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010550e:	e8 2f fc ff ff       	callq  ffffffff80105142 <acpi_config_smp>
ffffffff80105513:	eb 1f                	jmp    ffffffff80105534 <acpiinit+0x1b5>
  struct acpi_rsdt *rsdt;
  struct acpi_madt *madt = 0;

  rdsp = find_rdsp();
  if (rdsp->rsdt_addr_phys > PHYSLIMIT)
    goto notmapped;
ffffffff80105515:	90                   	nop
ffffffff80105516:	eb 01                	jmp    ffffffff80105519 <acpiinit+0x19a>
  rsdt = p2v(rdsp->rsdt_addr_phys);
  count = (rsdt->header.length - sizeof(*rsdt)) / 4;
  for (n = 0; n < count; n++) {
    struct acpi_desc_header *hdr = p2v(rsdt->entry[n]);
    if (rsdt->entry[n] > PHYSLIMIT)
      goto notmapped;
ffffffff80105518:	90                   	nop
  }

  return acpi_config_smp(madt);

notmapped:
  cprintf("acpi: tables above 0x%x not mapped.\n", PHYSLIMIT);
ffffffff80105519:	be 00 00 00 80       	mov    $0x80000000,%esi
ffffffff8010551e:	48 c7 c7 00 ad 10 80 	mov    $0xffffffff8010ad00,%rdi
ffffffff80105525:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010552a:	e8 73 b0 ff ff       	callq  ffffffff801005a2 <cprintf>
  return -1;
ffffffff8010552f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff80105534:	c9                   	leaveq 
ffffffff80105535:	c3                   	retq   

ffffffff80105536 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
ffffffff80105536:	55                   	push   %rbp
ffffffff80105537:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010553a:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff8010553e:	89 fa                	mov    %edi,%edx
ffffffff80105540:	89 f0                	mov    %esi,%eax
ffffffff80105542:	66 89 55 fc          	mov    %dx,-0x4(%rbp)
ffffffff80105546:	88 45 f8             	mov    %al,-0x8(%rbp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
ffffffff80105549:	0f b6 45 f8          	movzbl -0x8(%rbp),%eax
ffffffff8010554d:	0f b7 55 fc          	movzwl -0x4(%rbp),%edx
ffffffff80105551:	ee                   	out    %al,(%dx)
}
ffffffff80105552:	90                   	nop
ffffffff80105553:	c9                   	leaveq 
ffffffff80105554:	c3                   	retq   

ffffffff80105555 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
ffffffff80105555:	55                   	push   %rbp
ffffffff80105556:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105559:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff8010555d:	89 f8                	mov    %edi,%eax
ffffffff8010555f:	66 89 45 fc          	mov    %ax,-0x4(%rbp)
  irqmask = mask;
ffffffff80105563:	0f b7 45 fc          	movzwl -0x4(%rbp),%eax
ffffffff80105567:	66 89 05 d2 6f 00 00 	mov    %ax,0x6fd2(%rip)        # ffffffff8010c540 <irqmask>
  outb(IO_PIC1+1, mask);
ffffffff8010556e:	0f b7 45 fc          	movzwl -0x4(%rbp),%eax
ffffffff80105572:	0f b6 c0             	movzbl %al,%eax
ffffffff80105575:	89 c6                	mov    %eax,%esi
ffffffff80105577:	bf 21 00 00 00       	mov    $0x21,%edi
ffffffff8010557c:	e8 b5 ff ff ff       	callq  ffffffff80105536 <outb>
  outb(IO_PIC2+1, mask >> 8);
ffffffff80105581:	0f b7 45 fc          	movzwl -0x4(%rbp),%eax
ffffffff80105585:	66 c1 e8 08          	shr    $0x8,%ax
ffffffff80105589:	0f b6 c0             	movzbl %al,%eax
ffffffff8010558c:	89 c6                	mov    %eax,%esi
ffffffff8010558e:	bf a1 00 00 00       	mov    $0xa1,%edi
ffffffff80105593:	e8 9e ff ff ff       	callq  ffffffff80105536 <outb>
}
ffffffff80105598:	90                   	nop
ffffffff80105599:	c9                   	leaveq 
ffffffff8010559a:	c3                   	retq   

ffffffff8010559b <picenable>:

void
picenable(int irq)
{
ffffffff8010559b:	55                   	push   %rbp
ffffffff8010559c:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010559f:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801055a3:	89 7d fc             	mov    %edi,-0x4(%rbp)
  picsetmask(irqmask & ~(1<<irq));
ffffffff801055a6:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801055a9:	ba 01 00 00 00       	mov    $0x1,%edx
ffffffff801055ae:	89 c1                	mov    %eax,%ecx
ffffffff801055b0:	d3 e2                	shl    %cl,%edx
ffffffff801055b2:	89 d0                	mov    %edx,%eax
ffffffff801055b4:	f7 d0                	not    %eax
ffffffff801055b6:	89 c2                	mov    %eax,%edx
ffffffff801055b8:	0f b7 05 81 6f 00 00 	movzwl 0x6f81(%rip),%eax        # ffffffff8010c540 <irqmask>
ffffffff801055bf:	21 d0                	and    %edx,%eax
ffffffff801055c1:	0f b7 c0             	movzwl %ax,%eax
ffffffff801055c4:	89 c7                	mov    %eax,%edi
ffffffff801055c6:	e8 8a ff ff ff       	callq  ffffffff80105555 <picsetmask>
}
ffffffff801055cb:	90                   	nop
ffffffff801055cc:	c9                   	leaveq 
ffffffff801055cd:	c3                   	retq   

ffffffff801055ce <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
ffffffff801055ce:	55                   	push   %rbp
ffffffff801055cf:	48 89 e5             	mov    %rsp,%rbp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
ffffffff801055d2:	be ff 00 00 00       	mov    $0xff,%esi
ffffffff801055d7:	bf 21 00 00 00       	mov    $0x21,%edi
ffffffff801055dc:	e8 55 ff ff ff       	callq  ffffffff80105536 <outb>
  outb(IO_PIC2+1, 0xFF);
ffffffff801055e1:	be ff 00 00 00       	mov    $0xff,%esi
ffffffff801055e6:	bf a1 00 00 00       	mov    $0xa1,%edi
ffffffff801055eb:	e8 46 ff ff ff       	callq  ffffffff80105536 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
ffffffff801055f0:	be 11 00 00 00       	mov    $0x11,%esi
ffffffff801055f5:	bf 20 00 00 00       	mov    $0x20,%edi
ffffffff801055fa:	e8 37 ff ff ff       	callq  ffffffff80105536 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
ffffffff801055ff:	be 20 00 00 00       	mov    $0x20,%esi
ffffffff80105604:	bf 21 00 00 00       	mov    $0x21,%edi
ffffffff80105609:	e8 28 ff ff ff       	callq  ffffffff80105536 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
ffffffff8010560e:	be 04 00 00 00       	mov    $0x4,%esi
ffffffff80105613:	bf 21 00 00 00       	mov    $0x21,%edi
ffffffff80105618:	e8 19 ff ff ff       	callq  ffffffff80105536 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
ffffffff8010561d:	be 03 00 00 00       	mov    $0x3,%esi
ffffffff80105622:	bf 21 00 00 00       	mov    $0x21,%edi
ffffffff80105627:	e8 0a ff ff ff       	callq  ffffffff80105536 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
ffffffff8010562c:	be 11 00 00 00       	mov    $0x11,%esi
ffffffff80105631:	bf a0 00 00 00       	mov    $0xa0,%edi
ffffffff80105636:	e8 fb fe ff ff       	callq  ffffffff80105536 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
ffffffff8010563b:	be 28 00 00 00       	mov    $0x28,%esi
ffffffff80105640:	bf a1 00 00 00       	mov    $0xa1,%edi
ffffffff80105645:	e8 ec fe ff ff       	callq  ffffffff80105536 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
ffffffff8010564a:	be 02 00 00 00       	mov    $0x2,%esi
ffffffff8010564f:	bf a1 00 00 00       	mov    $0xa1,%edi
ffffffff80105654:	e8 dd fe ff ff       	callq  ffffffff80105536 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
ffffffff80105659:	be 03 00 00 00       	mov    $0x3,%esi
ffffffff8010565e:	bf a1 00 00 00       	mov    $0xa1,%edi
ffffffff80105663:	e8 ce fe ff ff       	callq  ffffffff80105536 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
ffffffff80105668:	be 68 00 00 00       	mov    $0x68,%esi
ffffffff8010566d:	bf 20 00 00 00       	mov    $0x20,%edi
ffffffff80105672:	e8 bf fe ff ff       	callq  ffffffff80105536 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
ffffffff80105677:	be 0a 00 00 00       	mov    $0xa,%esi
ffffffff8010567c:	bf 20 00 00 00       	mov    $0x20,%edi
ffffffff80105681:	e8 b0 fe ff ff       	callq  ffffffff80105536 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
ffffffff80105686:	be 68 00 00 00       	mov    $0x68,%esi
ffffffff8010568b:	bf a0 00 00 00       	mov    $0xa0,%edi
ffffffff80105690:	e8 a1 fe ff ff       	callq  ffffffff80105536 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
ffffffff80105695:	be 0a 00 00 00       	mov    $0xa,%esi
ffffffff8010569a:	bf a0 00 00 00       	mov    $0xa0,%edi
ffffffff8010569f:	e8 92 fe ff ff       	callq  ffffffff80105536 <outb>

  if(irqmask != 0xFFFF)
ffffffff801056a4:	0f b7 05 95 6e 00 00 	movzwl 0x6e95(%rip),%eax        # ffffffff8010c540 <irqmask>
ffffffff801056ab:	66 83 f8 ff          	cmp    $0xffff,%ax
ffffffff801056af:	74 11                	je     ffffffff801056c2 <picinit+0xf4>
    picsetmask(irqmask);
ffffffff801056b1:	0f b7 05 88 6e 00 00 	movzwl 0x6e88(%rip),%eax        # ffffffff8010c540 <irqmask>
ffffffff801056b8:	0f b7 c0             	movzwl %ax,%eax
ffffffff801056bb:	89 c7                	mov    %eax,%edi
ffffffff801056bd:	e8 93 fe ff ff       	callq  ffffffff80105555 <picsetmask>
}
ffffffff801056c2:	90                   	nop
ffffffff801056c3:	5d                   	pop    %rbp
ffffffff801056c4:	c3                   	retq   

ffffffff801056c5 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
ffffffff801056c5:	55                   	push   %rbp
ffffffff801056c6:	48 89 e5             	mov    %rsp,%rbp
ffffffff801056c9:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801056cd:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff801056d1:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  struct pipe *p;

  p = 0;
ffffffff801056d5:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
ffffffff801056dc:	00 
  *f0 = *f1 = 0;
ffffffff801056dd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801056e1:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
ffffffff801056e8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801056ec:	48 8b 10             	mov    (%rax),%rdx
ffffffff801056ef:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801056f3:	48 89 10             	mov    %rdx,(%rax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
ffffffff801056f6:	e8 28 c7 ff ff       	callq  ffffffff80101e23 <filealloc>
ffffffff801056fb:	48 89 c2             	mov    %rax,%rdx
ffffffff801056fe:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105702:	48 89 10             	mov    %rdx,(%rax)
ffffffff80105705:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105709:	48 8b 00             	mov    (%rax),%rax
ffffffff8010570c:	48 85 c0             	test   %rax,%rax
ffffffff8010570f:	0f 84 ea 00 00 00    	je     ffffffff801057ff <pipealloc+0x13a>
ffffffff80105715:	e8 09 c7 ff ff       	callq  ffffffff80101e23 <filealloc>
ffffffff8010571a:	48 89 c2             	mov    %rax,%rdx
ffffffff8010571d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80105721:	48 89 10             	mov    %rdx,(%rax)
ffffffff80105724:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80105728:	48 8b 00             	mov    (%rax),%rax
ffffffff8010572b:	48 85 c0             	test   %rax,%rax
ffffffff8010572e:	0f 84 cb 00 00 00    	je     ffffffff801057ff <pipealloc+0x13a>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
ffffffff80105734:	e8 5f e1 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff80105739:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff8010573d:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80105742:	0f 84 b6 00 00 00    	je     ffffffff801057fe <pipealloc+0x139>
    goto bad;
  p->readopen = 1;
ffffffff80105748:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010574c:	c7 80 70 02 00 00 01 	movl   $0x1,0x270(%rax)
ffffffff80105753:	00 00 00 
  p->writeopen = 1;
ffffffff80105756:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010575a:	c7 80 74 02 00 00 01 	movl   $0x1,0x274(%rax)
ffffffff80105761:	00 00 00 
  p->nwrite = 0;
ffffffff80105764:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105768:	c7 80 6c 02 00 00 00 	movl   $0x0,0x26c(%rax)
ffffffff8010576f:	00 00 00 
  p->nread = 0;
ffffffff80105772:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105776:	c7 80 68 02 00 00 00 	movl   $0x0,0x268(%rax)
ffffffff8010577d:	00 00 00 
  initlock(&p->lock, "pipe");
ffffffff80105780:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105784:	48 c7 c6 25 ad 10 80 	mov    $0xffffffff8010ad25,%rsi
ffffffff8010578b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010578e:	e8 d6 10 00 00       	callq  ffffffff80106869 <initlock>
  (*f0)->type = FD_PIPE;
ffffffff80105793:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105797:	48 8b 00             	mov    (%rax),%rax
ffffffff8010579a:	c7 00 01 00 00 00    	movl   $0x1,(%rax)
  (*f0)->readable = 1;
ffffffff801057a0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801057a4:	48 8b 00             	mov    (%rax),%rax
ffffffff801057a7:	c6 40 08 01          	movb   $0x1,0x8(%rax)
  (*f0)->writable = 0;
ffffffff801057ab:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801057af:	48 8b 00             	mov    (%rax),%rax
ffffffff801057b2:	c6 40 09 00          	movb   $0x0,0x9(%rax)
  (*f0)->pipe = p;
ffffffff801057b6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801057ba:	48 8b 00             	mov    (%rax),%rax
ffffffff801057bd:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff801057c1:	48 89 50 10          	mov    %rdx,0x10(%rax)
  (*f1)->type = FD_PIPE;
ffffffff801057c5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801057c9:	48 8b 00             	mov    (%rax),%rax
ffffffff801057cc:	c7 00 01 00 00 00    	movl   $0x1,(%rax)
  (*f1)->readable = 0;
ffffffff801057d2:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801057d6:	48 8b 00             	mov    (%rax),%rax
ffffffff801057d9:	c6 40 08 00          	movb   $0x0,0x8(%rax)
  (*f1)->writable = 1;
ffffffff801057dd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801057e1:	48 8b 00             	mov    (%rax),%rax
ffffffff801057e4:	c6 40 09 01          	movb   $0x1,0x9(%rax)
  (*f1)->pipe = p;
ffffffff801057e8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801057ec:	48 8b 00             	mov    (%rax),%rax
ffffffff801057ef:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff801057f3:	48 89 50 10          	mov    %rdx,0x10(%rax)
  return 0;
ffffffff801057f7:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801057fc:	eb 4f                	jmp    ffffffff8010584d <pipealloc+0x188>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
ffffffff801057fe:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
ffffffff801057ff:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80105804:	74 0c                	je     ffffffff80105812 <pipealloc+0x14d>
    kfree((char*)p);
ffffffff80105806:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010580a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010580d:	e8 dc df ff ff       	callq  ffffffff801037ee <kfree>
  if(*f0)
ffffffff80105812:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105816:	48 8b 00             	mov    (%rax),%rax
ffffffff80105819:	48 85 c0             	test   %rax,%rax
ffffffff8010581c:	74 0f                	je     ffffffff8010582d <pipealloc+0x168>
    fileclose(*f0);
ffffffff8010581e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105822:	48 8b 00             	mov    (%rax),%rax
ffffffff80105825:	48 89 c7             	mov    %rax,%rdi
ffffffff80105828:	e8 b3 c6 ff ff       	callq  ffffffff80101ee0 <fileclose>
  if(*f1)
ffffffff8010582d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80105831:	48 8b 00             	mov    (%rax),%rax
ffffffff80105834:	48 85 c0             	test   %rax,%rax
ffffffff80105837:	74 0f                	je     ffffffff80105848 <pipealloc+0x183>
    fileclose(*f1);
ffffffff80105839:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010583d:	48 8b 00             	mov    (%rax),%rax
ffffffff80105840:	48 89 c7             	mov    %rax,%rdi
ffffffff80105843:	e8 98 c6 ff ff       	callq  ffffffff80101ee0 <fileclose>
  return -1;
ffffffff80105848:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff8010584d:	c9                   	leaveq 
ffffffff8010584e:	c3                   	retq   

ffffffff8010584f <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
ffffffff8010584f:	55                   	push   %rbp
ffffffff80105850:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105853:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80105857:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff8010585b:	89 75 f4             	mov    %esi,-0xc(%rbp)
  acquire(&p->lock);
ffffffff8010585e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105862:	48 89 c7             	mov    %rax,%rdi
ffffffff80105865:	e8 34 10 00 00       	callq  ffffffff8010689e <acquire>
  if(writable){
ffffffff8010586a:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
ffffffff8010586e:	74 22                	je     ffffffff80105892 <pipeclose+0x43>
    p->writeopen = 0;
ffffffff80105870:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105874:	c7 80 74 02 00 00 00 	movl   $0x0,0x274(%rax)
ffffffff8010587b:	00 00 00 
    wakeup(&p->nread);
ffffffff8010587e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105882:	48 05 68 02 00 00    	add    $0x268,%rax
ffffffff80105888:	48 89 c7             	mov    %rax,%rdi
ffffffff8010588b:	e8 a4 0d 00 00       	callq  ffffffff80106634 <wakeup>
ffffffff80105890:	eb 20                	jmp    ffffffff801058b2 <pipeclose+0x63>
  } else {
    p->readopen = 0;
ffffffff80105892:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105896:	c7 80 70 02 00 00 00 	movl   $0x0,0x270(%rax)
ffffffff8010589d:	00 00 00 
    wakeup(&p->nwrite);
ffffffff801058a0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801058a4:	48 05 6c 02 00 00    	add    $0x26c,%rax
ffffffff801058aa:	48 89 c7             	mov    %rax,%rdi
ffffffff801058ad:	e8 82 0d 00 00       	callq  ffffffff80106634 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
ffffffff801058b2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801058b6:	8b 80 70 02 00 00    	mov    0x270(%rax),%eax
ffffffff801058bc:	85 c0                	test   %eax,%eax
ffffffff801058be:	75 28                	jne    ffffffff801058e8 <pipeclose+0x99>
ffffffff801058c0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801058c4:	8b 80 74 02 00 00    	mov    0x274(%rax),%eax
ffffffff801058ca:	85 c0                	test   %eax,%eax
ffffffff801058cc:	75 1a                	jne    ffffffff801058e8 <pipeclose+0x99>
    release(&p->lock);
ffffffff801058ce:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801058d2:	48 89 c7             	mov    %rax,%rdi
ffffffff801058d5:	e8 9b 10 00 00       	callq  ffffffff80106975 <release>
    kfree((char*)p);
ffffffff801058da:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801058de:	48 89 c7             	mov    %rax,%rdi
ffffffff801058e1:	e8 08 df ff ff       	callq  ffffffff801037ee <kfree>
ffffffff801058e6:	eb 0c                	jmp    ffffffff801058f4 <pipeclose+0xa5>
  } else
    release(&p->lock);
ffffffff801058e8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801058ec:	48 89 c7             	mov    %rax,%rdi
ffffffff801058ef:	e8 81 10 00 00       	callq  ffffffff80106975 <release>
}
ffffffff801058f4:	90                   	nop
ffffffff801058f5:	c9                   	leaveq 
ffffffff801058f6:	c3                   	retq   

ffffffff801058f7 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
ffffffff801058f7:	55                   	push   %rbp
ffffffff801058f8:	48 89 e5             	mov    %rsp,%rbp
ffffffff801058fb:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff801058ff:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80105903:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80105907:	89 55 dc             	mov    %edx,-0x24(%rbp)
  int i;

  acquire(&p->lock);
ffffffff8010590a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010590e:	48 89 c7             	mov    %rax,%rdi
ffffffff80105911:	e8 88 0f 00 00       	callq  ffffffff8010689e <acquire>
  for(i = 0; i < n; i++){
ffffffff80105916:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff8010591d:	e9 bb 00 00 00       	jmpq   ffffffff801059dd <pipewrite+0xe6>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
ffffffff80105922:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105926:	8b 80 70 02 00 00    	mov    0x270(%rax),%eax
ffffffff8010592c:	85 c0                	test   %eax,%eax
ffffffff8010592e:	74 12                	je     ffffffff80105942 <pipewrite+0x4b>
ffffffff80105930:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105937:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010593b:	8b 40 40             	mov    0x40(%rax),%eax
ffffffff8010593e:	85 c0                	test   %eax,%eax
ffffffff80105940:	74 16                	je     ffffffff80105958 <pipewrite+0x61>
        release(&p->lock);
ffffffff80105942:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105946:	48 89 c7             	mov    %rax,%rdi
ffffffff80105949:	e8 27 10 00 00       	callq  ffffffff80106975 <release>
        return -1;
ffffffff8010594e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80105953:	e9 ae 00 00 00       	jmpq   ffffffff80105a06 <pipewrite+0x10f>
      }
      wakeup(&p->nread);
ffffffff80105958:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010595c:	48 05 68 02 00 00    	add    $0x268,%rax
ffffffff80105962:	48 89 c7             	mov    %rax,%rdi
ffffffff80105965:	e8 ca 0c 00 00       	callq  ffffffff80106634 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
ffffffff8010596a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010596e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80105972:	48 81 c2 6c 02 00 00 	add    $0x26c,%rdx
ffffffff80105979:	48 89 c6             	mov    %rax,%rsi
ffffffff8010597c:	48 89 d7             	mov    %rdx,%rdi
ffffffff8010597f:	e8 9d 0b 00 00       	callq  ffffffff80106521 <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
ffffffff80105984:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105988:	8b 90 6c 02 00 00    	mov    0x26c(%rax),%edx
ffffffff8010598e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105992:	8b 80 68 02 00 00    	mov    0x268(%rax),%eax
ffffffff80105998:	05 00 02 00 00       	add    $0x200,%eax
ffffffff8010599d:	39 c2                	cmp    %eax,%edx
ffffffff8010599f:	74 81                	je     ffffffff80105922 <pipewrite+0x2b>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
ffffffff801059a1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801059a5:	8b 80 6c 02 00 00    	mov    0x26c(%rax),%eax
ffffffff801059ab:	8d 48 01             	lea    0x1(%rax),%ecx
ffffffff801059ae:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff801059b2:	89 8a 6c 02 00 00    	mov    %ecx,0x26c(%rdx)
ffffffff801059b8:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff801059bd:	89 c1                	mov    %eax,%ecx
ffffffff801059bf:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801059c2:	48 63 d0             	movslq %eax,%rdx
ffffffff801059c5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff801059c9:	48 01 d0             	add    %rdx,%rax
ffffffff801059cc:	0f b6 10             	movzbl (%rax),%edx
ffffffff801059cf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801059d3:	89 c9                	mov    %ecx,%ecx
ffffffff801059d5:	88 54 08 68          	mov    %dl,0x68(%rax,%rcx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
ffffffff801059d9:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801059dd:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801059e0:	3b 45 dc             	cmp    -0x24(%rbp),%eax
ffffffff801059e3:	7c 9f                	jl     ffffffff80105984 <pipewrite+0x8d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
ffffffff801059e5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801059e9:	48 05 68 02 00 00    	add    $0x268,%rax
ffffffff801059ef:	48 89 c7             	mov    %rax,%rdi
ffffffff801059f2:	e8 3d 0c 00 00       	callq  ffffffff80106634 <wakeup>
  release(&p->lock);
ffffffff801059f7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801059fb:	48 89 c7             	mov    %rax,%rdi
ffffffff801059fe:	e8 72 0f 00 00       	callq  ffffffff80106975 <release>
  return n;
ffffffff80105a03:	8b 45 dc             	mov    -0x24(%rbp),%eax
}
ffffffff80105a06:	c9                   	leaveq 
ffffffff80105a07:	c3                   	retq   

ffffffff80105a08 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
ffffffff80105a08:	55                   	push   %rbp
ffffffff80105a09:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105a0c:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80105a10:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80105a14:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80105a18:	89 55 dc             	mov    %edx,-0x24(%rbp)
  int i;

  acquire(&p->lock);
ffffffff80105a1b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105a1f:	48 89 c7             	mov    %rax,%rdi
ffffffff80105a22:	e8 77 0e 00 00       	callq  ffffffff8010689e <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
ffffffff80105a27:	eb 42                	jmp    ffffffff80105a6b <piperead+0x63>
    if(proc->killed){
ffffffff80105a29:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105a30:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105a34:	8b 40 40             	mov    0x40(%rax),%eax
ffffffff80105a37:	85 c0                	test   %eax,%eax
ffffffff80105a39:	74 16                	je     ffffffff80105a51 <piperead+0x49>
      release(&p->lock);
ffffffff80105a3b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105a3f:	48 89 c7             	mov    %rax,%rdi
ffffffff80105a42:	e8 2e 0f 00 00       	callq  ffffffff80106975 <release>
      return -1;
ffffffff80105a47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80105a4c:	e9 ca 00 00 00       	jmpq   ffffffff80105b1b <piperead+0x113>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
ffffffff80105a51:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105a55:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80105a59:	48 81 c2 68 02 00 00 	add    $0x268,%rdx
ffffffff80105a60:	48 89 c6             	mov    %rax,%rsi
ffffffff80105a63:	48 89 d7             	mov    %rdx,%rdi
ffffffff80105a66:	e8 b6 0a 00 00       	callq  ffffffff80106521 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
ffffffff80105a6b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105a6f:	8b 90 68 02 00 00    	mov    0x268(%rax),%edx
ffffffff80105a75:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105a79:	8b 80 6c 02 00 00    	mov    0x26c(%rax),%eax
ffffffff80105a7f:	39 c2                	cmp    %eax,%edx
ffffffff80105a81:	75 0e                	jne    ffffffff80105a91 <piperead+0x89>
ffffffff80105a83:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105a87:	8b 80 74 02 00 00    	mov    0x274(%rax),%eax
ffffffff80105a8d:	85 c0                	test   %eax,%eax
ffffffff80105a8f:	75 98                	jne    ffffffff80105a29 <piperead+0x21>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
ffffffff80105a91:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80105a98:	eb 55                	jmp    ffffffff80105aef <piperead+0xe7>
    if(p->nread == p->nwrite)
ffffffff80105a9a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105a9e:	8b 90 68 02 00 00    	mov    0x268(%rax),%edx
ffffffff80105aa4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105aa8:	8b 80 6c 02 00 00    	mov    0x26c(%rax),%eax
ffffffff80105aae:	39 c2                	cmp    %eax,%edx
ffffffff80105ab0:	74 47                	je     ffffffff80105af9 <piperead+0xf1>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
ffffffff80105ab2:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80105ab5:	48 63 d0             	movslq %eax,%rdx
ffffffff80105ab8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80105abc:	48 8d 34 02          	lea    (%rdx,%rax,1),%rsi
ffffffff80105ac0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105ac4:	8b 80 68 02 00 00    	mov    0x268(%rax),%eax
ffffffff80105aca:	8d 48 01             	lea    0x1(%rax),%ecx
ffffffff80105acd:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80105ad1:	89 8a 68 02 00 00    	mov    %ecx,0x268(%rdx)
ffffffff80105ad7:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff80105adc:	89 c2                	mov    %eax,%edx
ffffffff80105ade:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105ae2:	89 d2                	mov    %edx,%edx
ffffffff80105ae4:	0f b6 44 10 68       	movzbl 0x68(%rax,%rdx,1),%eax
ffffffff80105ae9:	88 06                	mov    %al,(%rsi)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
ffffffff80105aeb:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80105aef:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80105af2:	3b 45 dc             	cmp    -0x24(%rbp),%eax
ffffffff80105af5:	7c a3                	jl     ffffffff80105a9a <piperead+0x92>
ffffffff80105af7:	eb 01                	jmp    ffffffff80105afa <piperead+0xf2>
    if(p->nread == p->nwrite)
      break;
ffffffff80105af9:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
ffffffff80105afa:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105afe:	48 05 6c 02 00 00    	add    $0x26c,%rax
ffffffff80105b04:	48 89 c7             	mov    %rax,%rdi
ffffffff80105b07:	e8 28 0b 00 00       	callq  ffffffff80106634 <wakeup>
  release(&p->lock);
ffffffff80105b0c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80105b10:	48 89 c7             	mov    %rax,%rdi
ffffffff80105b13:	e8 5d 0e 00 00       	callq  ffffffff80106975 <release>
  return i;
ffffffff80105b18:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
ffffffff80105b1b:	c9                   	leaveq 
ffffffff80105b1c:	c3                   	retq   

ffffffff80105b1d <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uintp
readeflags(void)
{
ffffffff80105b1d:	55                   	push   %rbp
ffffffff80105b1e:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105b21:	48 83 ec 10          	sub    $0x10,%rsp
  uintp eflags;
  asm volatile("pushf; pop %0" : "=r" (eflags));
ffffffff80105b25:	9c                   	pushfq 
ffffffff80105b26:	58                   	pop    %rax
ffffffff80105b27:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  return eflags;
ffffffff80105b2b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80105b2f:	c9                   	leaveq 
ffffffff80105b30:	c3                   	retq   

ffffffff80105b31 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
ffffffff80105b31:	55                   	push   %rbp
ffffffff80105b32:	48 89 e5             	mov    %rsp,%rbp
  asm volatile("sti");
ffffffff80105b35:	fb                   	sti    
}
ffffffff80105b36:	90                   	nop
ffffffff80105b37:	5d                   	pop    %rbp
ffffffff80105b38:	c3                   	retq   

ffffffff80105b39 <hlt>:

static inline void
hlt(void)
{
ffffffff80105b39:	55                   	push   %rbp
ffffffff80105b3a:	48 89 e5             	mov    %rsp,%rbp
  asm volatile("hlt");
ffffffff80105b3d:	f4                   	hlt    
}
ffffffff80105b3e:	90                   	nop
ffffffff80105b3f:	5d                   	pop    %rbp
ffffffff80105b40:	c3                   	retq   

ffffffff80105b41 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
ffffffff80105b41:	55                   	push   %rbp
ffffffff80105b42:	48 89 e5             	mov    %rsp,%rbp
  initlock(&ptable.lock, "ptable");
ffffffff80105b45:	48 c7 c6 2a ad 10 80 	mov    $0xffffffff8010ad2a,%rsi
ffffffff80105b4c:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80105b53:	e8 11 0d 00 00       	callq  ffffffff80106869 <initlock>
}
ffffffff80105b58:	90                   	nop
ffffffff80105b59:	5d                   	pop    %rbp
ffffffff80105b5a:	c3                   	retq   

ffffffff80105b5b <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
ffffffff80105b5b:	55                   	push   %rbp
ffffffff80105b5c:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105b5f:	48 83 ec 10          	sub    $0x10,%rsp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
ffffffff80105b63:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80105b6a:	e8 2f 0d 00 00       	callq  ffffffff8010689e <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
ffffffff80105b6f:	48 c7 45 f8 68 0f 19 	movq   $0xffffffff80190f68,-0x8(%rbp)
ffffffff80105b76:	80 
ffffffff80105b77:	eb 13                	jmp    ffffffff80105b8c <allocproc+0x31>
    if(p->state == UNUSED)
ffffffff80105b79:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105b7d:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff80105b80:	85 c0                	test   %eax,%eax
ffffffff80105b82:	74 28                	je     ffffffff80105bac <allocproc+0x51>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
ffffffff80105b84:	48 81 45 f8 e0 00 00 	addq   $0xe0,-0x8(%rbp)
ffffffff80105b8b:	00 
ffffffff80105b8c:	48 81 7d f8 68 47 19 	cmpq   $0xffffffff80194768,-0x8(%rbp)
ffffffff80105b93:	80 
ffffffff80105b94:	72 e3                	jb     ffffffff80105b79 <allocproc+0x1e>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
ffffffff80105b96:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80105b9d:	e8 d3 0d 00 00       	callq  ffffffff80106975 <release>
  return 0;
ffffffff80105ba2:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80105ba7:	e9 d8 00 00 00       	jmpq   ffffffff80105c84 <allocproc+0x129>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
ffffffff80105bac:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
ffffffff80105bad:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105bb1:	c7 40 18 01 00 00 00 	movl   $0x1,0x18(%rax)
  p->pid = nextpid++;
ffffffff80105bb8:	8b 05 a2 69 00 00    	mov    0x69a2(%rip),%eax        # ffffffff8010c560 <nextpid>
ffffffff80105bbe:	8d 50 01             	lea    0x1(%rax),%edx
ffffffff80105bc1:	89 15 99 69 00 00    	mov    %edx,0x6999(%rip)        # ffffffff8010c560 <nextpid>
ffffffff80105bc7:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80105bcb:	89 42 1c             	mov    %eax,0x1c(%rdx)
  release(&ptable.lock);
ffffffff80105bce:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80105bd5:	e8 9b 0d 00 00       	callq  ffffffff80106975 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
ffffffff80105bda:	e8 b9 dc ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff80105bdf:	48 89 c2             	mov    %rax,%rdx
ffffffff80105be2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105be6:	48 89 50 10          	mov    %rdx,0x10(%rax)
ffffffff80105bea:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105bee:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff80105bf2:	48 85 c0             	test   %rax,%rax
ffffffff80105bf5:	75 12                	jne    ffffffff80105c09 <allocproc+0xae>
    p->state = UNUSED;
ffffffff80105bf7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105bfb:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%rax)
    return 0;
ffffffff80105c02:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80105c07:	eb 7b                	jmp    ffffffff80105c84 <allocproc+0x129>
  }
  sp = p->kstack + KSTACKSIZE;
ffffffff80105c09:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105c0d:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff80105c11:	48 05 00 10 00 00    	add    $0x1000,%rax
ffffffff80105c17:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
ffffffff80105c1b:	48 81 6d f0 b0 00 00 	subq   $0xb0,-0x10(%rbp)
ffffffff80105c22:	00 
  p->tf = (struct trapframe*)sp;
ffffffff80105c23:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105c27:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff80105c2b:	48 89 50 28          	mov    %rdx,0x28(%rax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= sizeof(uintp);
ffffffff80105c2f:	48 83 6d f0 08       	subq   $0x8,-0x10(%rbp)
  *(uintp*)sp = (uintp)trapret;
ffffffff80105c34:	48 c7 c2 36 84 10 80 	mov    $0xffffffff80108436,%rdx
ffffffff80105c3b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105c3f:	48 89 10             	mov    %rdx,(%rax)

  sp -= sizeof *p->context;
ffffffff80105c42:	48 83 6d f0 40       	subq   $0x40,-0x10(%rbp)
  p->context = (struct context*)sp;
ffffffff80105c47:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105c4b:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff80105c4f:	48 89 50 30          	mov    %rdx,0x30(%rax)
  memset(p->context, 0, sizeof *p->context);
ffffffff80105c53:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105c57:	48 8b 40 30          	mov    0x30(%rax),%rax
ffffffff80105c5b:	ba 40 00 00 00       	mov    $0x40,%edx
ffffffff80105c60:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80105c65:	48 89 c7             	mov    %rax,%rdi
ffffffff80105c68:	e8 a0 0f 00 00       	callq  ffffffff80106c0d <memset>
  p->context->eip = (uintp)forkret;
ffffffff80105c6d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105c71:	48 8b 40 30          	mov    0x30(%rax),%rax
ffffffff80105c75:	48 c7 c2 f5 64 10 80 	mov    $0xffffffff801064f5,%rdx
ffffffff80105c7c:	48 89 50 38          	mov    %rdx,0x38(%rax)

  return p;
ffffffff80105c80:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80105c84:	c9                   	leaveq 
ffffffff80105c85:	c3                   	retq   

ffffffff80105c86 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
ffffffff80105c86:	55                   	push   %rbp
ffffffff80105c87:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105c8a:	48 83 ec 10          	sub    $0x10,%rsp
  struct proc *p;
  extern char _binary_out_initcode_start[], _binary_out_initcode_size[];
  
  p = allocproc();
ffffffff80105c8e:	e8 c8 fe ff ff       	callq  ffffffff80105b5b <allocproc>
ffffffff80105c93:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  initproc = p;
ffffffff80105c97:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105c9b:	48 89 05 c6 ea 08 00 	mov    %rax,0x8eac6(%rip)        # ffffffff80194768 <initproc>
  if((p->pgdir = setupkvm()) == 0)
ffffffff80105ca2:	e8 cb 43 00 00       	callq  ffffffff8010a072 <setupkvm>
ffffffff80105ca7:	48 89 c2             	mov    %rax,%rdx
ffffffff80105caa:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105cae:	48 89 50 08          	mov    %rdx,0x8(%rax)
ffffffff80105cb2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105cb6:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80105cba:	48 85 c0             	test   %rax,%rax
ffffffff80105cbd:	75 0c                	jne    ffffffff80105ccb <userinit+0x45>
    panic("userinit: out of memory?");
ffffffff80105cbf:	48 c7 c7 31 ad 10 80 	mov    $0xffffffff8010ad31,%rdi
ffffffff80105cc6:	e8 34 ac ff ff       	callq  ffffffff801008ff <panic>
  inituvm(p->pgdir, _binary_out_initcode_start, (uintp)_binary_out_initcode_size);
ffffffff80105ccb:	48 c7 c0 3c 00 00 00 	mov    $0x3c,%rax
ffffffff80105cd2:	89 c2                	mov    %eax,%edx
ffffffff80105cd4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105cd8:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80105cdc:	48 c7 c6 78 ce 10 80 	mov    $0xffffffff8010ce78,%rsi
ffffffff80105ce3:	48 89 c7             	mov    %rax,%rdi
ffffffff80105ce6:	e8 8d 38 00 00       	callq  ffffffff80109578 <inituvm>
  p->sz = PGSIZE;
ffffffff80105ceb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105cef:	48 c7 00 00 10 00 00 	movq   $0x1000,(%rax)
  memset(p->tf, 0, sizeof(*p->tf));
ffffffff80105cf6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105cfa:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80105cfe:	ba b0 00 00 00       	mov    $0xb0,%edx
ffffffff80105d03:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80105d08:	48 89 c7             	mov    %rax,%rdi
ffffffff80105d0b:	e8 fd 0e 00 00       	callq  ffffffff80106c0d <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
ffffffff80105d10:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105d14:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80105d18:	48 c7 80 90 00 00 00 	movq   $0x23,0x90(%rax)
ffffffff80105d1f:	23 00 00 00 
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
ffffffff80105d23:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105d27:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80105d2b:	48 c7 80 a8 00 00 00 	movq   $0x2b,0xa8(%rax)
ffffffff80105d32:	2b 00 00 00 
#ifndef X64
  p->tf->es = p->tf->ds;
  p->tf->ss = p->tf->ds;
#endif
  p->tf->eflags = FL_IF;
ffffffff80105d36:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105d3a:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80105d3e:	48 c7 80 98 00 00 00 	movq   $0x200,0x98(%rax)
ffffffff80105d45:	00 02 00 00 
  p->tf->esp = PGSIZE;
ffffffff80105d49:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105d4d:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80105d51:	48 c7 80 a0 00 00 00 	movq   $0x1000,0xa0(%rax)
ffffffff80105d58:	00 10 00 00 
  p->tf->eip = 0;  // beginning of initcode.S
ffffffff80105d5c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105d60:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80105d64:	48 c7 80 88 00 00 00 	movq   $0x0,0x88(%rax)
ffffffff80105d6b:	00 00 00 00 

  safestrcpy(p->name, "initcode", sizeof(p->name));
ffffffff80105d6f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105d73:	48 05 d0 00 00 00    	add    $0xd0,%rax
ffffffff80105d79:	ba 10 00 00 00       	mov    $0x10,%edx
ffffffff80105d7e:	48 c7 c6 4a ad 10 80 	mov    $0xffffffff8010ad4a,%rsi
ffffffff80105d85:	48 89 c7             	mov    %rax,%rdi
ffffffff80105d88:	e8 1b 11 00 00       	callq  ffffffff80106ea8 <safestrcpy>
  p->cwd = namei("/");
ffffffff80105d8d:	48 c7 c7 53 ad 10 80 	mov    $0xffffffff8010ad53,%rdi
ffffffff80105d94:	e8 d7 d7 ff ff       	callq  ffffffff80103570 <namei>
ffffffff80105d99:	48 89 c2             	mov    %rax,%rdx
ffffffff80105d9c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105da0:	48 89 90 c8 00 00 00 	mov    %rdx,0xc8(%rax)

  p->state = RUNNABLE;
ffffffff80105da7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80105dab:	c7 40 18 03 00 00 00 	movl   $0x3,0x18(%rax)
}
ffffffff80105db2:	90                   	nop
ffffffff80105db3:	c9                   	leaveq 
ffffffff80105db4:	c3                   	retq   

ffffffff80105db5 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
ffffffff80105db5:	55                   	push   %rbp
ffffffff80105db6:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105db9:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80105dbd:	89 7d ec             	mov    %edi,-0x14(%rbp)
  uint sz;
  
  sz = proc->sz;
ffffffff80105dc0:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105dc7:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105dcb:	48 8b 00             	mov    (%rax),%rax
ffffffff80105dce:	89 45 fc             	mov    %eax,-0x4(%rbp)
  if(n > 0){
ffffffff80105dd1:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80105dd5:	7e 34                	jle    ffffffff80105e0b <growproc+0x56>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
ffffffff80105dd7:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80105dda:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80105ddd:	01 c2                	add    %eax,%edx
ffffffff80105ddf:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105de6:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105dea:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80105dee:	8b 4d fc             	mov    -0x4(%rbp),%ecx
ffffffff80105df1:	89 ce                	mov    %ecx,%esi
ffffffff80105df3:	48 89 c7             	mov    %rax,%rdi
ffffffff80105df6:	e8 06 39 00 00       	callq  ffffffff80109701 <allocuvm>
ffffffff80105dfb:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff80105dfe:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80105e02:	75 44                	jne    ffffffff80105e48 <growproc+0x93>
      return -1;
ffffffff80105e04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80105e09:	eb 66                	jmp    ffffffff80105e71 <growproc+0xbc>
  } else if(n < 0){
ffffffff80105e0b:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80105e0f:	79 37                	jns    ffffffff80105e48 <growproc+0x93>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
ffffffff80105e11:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80105e14:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80105e17:	01 d0                	add    %edx,%eax
ffffffff80105e19:	89 c2                	mov    %eax,%edx
ffffffff80105e1b:	8b 4d fc             	mov    -0x4(%rbp),%ecx
ffffffff80105e1e:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105e25:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105e29:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80105e2d:	48 89 ce             	mov    %rcx,%rsi
ffffffff80105e30:	48 89 c7             	mov    %rax,%rdi
ffffffff80105e33:	e8 9d 39 00 00       	callq  ffffffff801097d5 <deallocuvm>
ffffffff80105e38:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff80105e3b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80105e3f:	75 07                	jne    ffffffff80105e48 <growproc+0x93>
      return -1;
ffffffff80105e41:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80105e46:	eb 29                	jmp    ffffffff80105e71 <growproc+0xbc>
  }
  proc->sz = sz;
ffffffff80105e48:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105e4f:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105e53:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80105e56:	48 89 10             	mov    %rdx,(%rax)
  switchuvm(proc);
ffffffff80105e59:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105e60:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105e64:	48 89 c7             	mov    %rax,%rdi
ffffffff80105e67:	e8 d9 44 00 00       	callq  ffffffff8010a345 <switchuvm>
  return 0;
ffffffff80105e6c:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80105e71:	c9                   	leaveq 
ffffffff80105e72:	c3                   	retq   

ffffffff80105e73 <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
ffffffff80105e73:	55                   	push   %rbp
ffffffff80105e74:	48 89 e5             	mov    %rsp,%rbp
ffffffff80105e77:	48 83 ec 20          	sub    $0x20,%rsp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
ffffffff80105e7b:	e8 db fc ff ff       	callq  ffffffff80105b5b <allocproc>
ffffffff80105e80:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80105e84:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80105e89:	75 0a                	jne    ffffffff80105e95 <fork+0x22>
    return -1;
ffffffff80105e8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80105e90:	e9 bf 01 00 00       	jmpq   ffffffff80106054 <fork+0x1e1>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
ffffffff80105e95:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105e9c:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105ea0:	48 8b 00             	mov    (%rax),%rax
ffffffff80105ea3:	89 c2                	mov    %eax,%edx
ffffffff80105ea5:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105eac:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105eb0:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80105eb4:	89 d6                	mov    %edx,%esi
ffffffff80105eb6:	48 89 c7             	mov    %rax,%rdi
ffffffff80105eb9:	e8 fb 3a 00 00       	callq  ffffffff801099b9 <copyuvm>
ffffffff80105ebe:	48 89 c2             	mov    %rax,%rdx
ffffffff80105ec1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105ec5:	48 89 50 08          	mov    %rdx,0x8(%rax)
ffffffff80105ec9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105ecd:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80105ed1:	48 85 c0             	test   %rax,%rax
ffffffff80105ed4:	75 31                	jne    ffffffff80105f07 <fork+0x94>
    kfree(np->kstack);
ffffffff80105ed6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105eda:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff80105ede:	48 89 c7             	mov    %rax,%rdi
ffffffff80105ee1:	e8 08 d9 ff ff       	callq  ffffffff801037ee <kfree>
    np->kstack = 0;
ffffffff80105ee6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105eea:	48 c7 40 10 00 00 00 	movq   $0x0,0x10(%rax)
ffffffff80105ef1:	00 
    np->state = UNUSED;
ffffffff80105ef2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105ef6:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%rax)
    return -1;
ffffffff80105efd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80105f02:	e9 4d 01 00 00       	jmpq   ffffffff80106054 <fork+0x1e1>
  }
  np->sz = proc->sz;
ffffffff80105f07:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105f0e:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105f12:	48 8b 10             	mov    (%rax),%rdx
ffffffff80105f15:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105f19:	48 89 10             	mov    %rdx,(%rax)
  np->parent = proc;
ffffffff80105f1c:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105f23:	64 48 8b 10          	mov    %fs:(%rax),%rdx
ffffffff80105f27:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105f2b:	48 89 50 20          	mov    %rdx,0x20(%rax)
  *np->tf = *proc->tf;
ffffffff80105f2f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105f33:	48 8b 50 28          	mov    0x28(%rax),%rdx
ffffffff80105f37:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105f3e:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105f42:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80105f46:	48 89 c6             	mov    %rax,%rsi
ffffffff80105f49:	b8 16 00 00 00       	mov    $0x16,%eax
ffffffff80105f4e:	48 89 d7             	mov    %rdx,%rdi
ffffffff80105f51:	48 89 c1             	mov    %rax,%rcx
ffffffff80105f54:	f3 48 a5             	rep movsq %ds:(%rsi),%es:(%rdi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
ffffffff80105f57:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105f5b:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80105f5f:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)

  for(i = 0; i < NOFILE; i++)
ffffffff80105f66:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80105f6d:	eb 5b                	jmp    ffffffff80105fca <fork+0x157>
    if(proc->ofile[i])
ffffffff80105f6f:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105f76:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105f7a:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80105f7d:	48 63 d2             	movslq %edx,%rdx
ffffffff80105f80:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80105f84:	48 8b 44 d0 08       	mov    0x8(%rax,%rdx,8),%rax
ffffffff80105f89:	48 85 c0             	test   %rax,%rax
ffffffff80105f8c:	74 38                	je     ffffffff80105fc6 <fork+0x153>
      np->ofile[i] = filedup(proc->ofile[i]);
ffffffff80105f8e:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105f95:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105f99:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80105f9c:	48 63 d2             	movslq %edx,%rdx
ffffffff80105f9f:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80105fa3:	48 8b 44 d0 08       	mov    0x8(%rax,%rdx,8),%rax
ffffffff80105fa8:	48 89 c7             	mov    %rax,%rdi
ffffffff80105fab:	e8 de be ff ff       	callq  ffffffff80101e8e <filedup>
ffffffff80105fb0:	48 89 c1             	mov    %rax,%rcx
ffffffff80105fb3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105fb7:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80105fba:	48 63 d2             	movslq %edx,%rdx
ffffffff80105fbd:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80105fc1:	48 89 4c d0 08       	mov    %rcx,0x8(%rax,%rdx,8)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
ffffffff80105fc6:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80105fca:	83 7d fc 0f          	cmpl   $0xf,-0x4(%rbp)
ffffffff80105fce:	7e 9f                	jle    ffffffff80105f6f <fork+0xfc>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
ffffffff80105fd0:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105fd7:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80105fdb:	48 8b 80 c8 00 00 00 	mov    0xc8(%rax),%rax
ffffffff80105fe2:	48 89 c7             	mov    %rax,%rdi
ffffffff80105fe5:	e8 1f c8 ff ff       	callq  ffffffff80102809 <idup>
ffffffff80105fea:	48 89 c2             	mov    %rax,%rdx
ffffffff80105fed:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80105ff1:	48 89 90 c8 00 00 00 	mov    %rdx,0xc8(%rax)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
ffffffff80105ff8:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80105fff:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106003:	48 8d 88 d0 00 00 00 	lea    0xd0(%rax),%rcx
ffffffff8010600a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010600e:	48 05 d0 00 00 00    	add    $0xd0,%rax
ffffffff80106014:	ba 10 00 00 00       	mov    $0x10,%edx
ffffffff80106019:	48 89 ce             	mov    %rcx,%rsi
ffffffff8010601c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010601f:	e8 84 0e 00 00       	callq  ffffffff80106ea8 <safestrcpy>
 
  pid = np->pid;
ffffffff80106024:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106028:	8b 40 1c             	mov    0x1c(%rax),%eax
ffffffff8010602b:	89 45 ec             	mov    %eax,-0x14(%rbp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
ffffffff8010602e:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80106035:	e8 64 08 00 00       	callq  ffffffff8010689e <acquire>
  np->state = RUNNABLE;
ffffffff8010603a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010603e:	c7 40 18 03 00 00 00 	movl   $0x3,0x18(%rax)
  release(&ptable.lock);
ffffffff80106045:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff8010604c:	e8 24 09 00 00       	callq  ffffffff80106975 <release>
  
  return pid;
ffffffff80106051:	8b 45 ec             	mov    -0x14(%rbp),%eax
}
ffffffff80106054:	c9                   	leaveq 
ffffffff80106055:	c3                   	retq   

ffffffff80106056 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
ffffffff80106056:	55                   	push   %rbp
ffffffff80106057:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010605a:	48 83 ec 10          	sub    $0x10,%rsp
  struct proc *p;
  int fd;

  if(proc == initproc)
ffffffff8010605e:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106065:	64 48 8b 10          	mov    %fs:(%rax),%rdx
ffffffff80106069:	48 8b 05 f8 e6 08 00 	mov    0x8e6f8(%rip),%rax        # ffffffff80194768 <initproc>
ffffffff80106070:	48 39 c2             	cmp    %rax,%rdx
ffffffff80106073:	75 0c                	jne    ffffffff80106081 <exit+0x2b>
    panic("init exiting");
ffffffff80106075:	48 c7 c7 55 ad 10 80 	mov    $0xffffffff8010ad55,%rdi
ffffffff8010607c:	e8 7e a8 ff ff       	callq  ffffffff801008ff <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
ffffffff80106081:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
ffffffff80106088:	eb 63                	jmp    ffffffff801060ed <exit+0x97>
    if(proc->ofile[fd]){
ffffffff8010608a:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106091:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106095:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff80106098:	48 63 d2             	movslq %edx,%rdx
ffffffff8010609b:	48 83 c2 08          	add    $0x8,%rdx
ffffffff8010609f:	48 8b 44 d0 08       	mov    0x8(%rax,%rdx,8),%rax
ffffffff801060a4:	48 85 c0             	test   %rax,%rax
ffffffff801060a7:	74 40                	je     ffffffff801060e9 <exit+0x93>
      fileclose(proc->ofile[fd]);
ffffffff801060a9:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801060b0:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801060b4:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff801060b7:	48 63 d2             	movslq %edx,%rdx
ffffffff801060ba:	48 83 c2 08          	add    $0x8,%rdx
ffffffff801060be:	48 8b 44 d0 08       	mov    0x8(%rax,%rdx,8),%rax
ffffffff801060c3:	48 89 c7             	mov    %rax,%rdi
ffffffff801060c6:	e8 15 be ff ff       	callq  ffffffff80101ee0 <fileclose>
      proc->ofile[fd] = 0;
ffffffff801060cb:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801060d2:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801060d6:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff801060d9:	48 63 d2             	movslq %edx,%rdx
ffffffff801060dc:	48 83 c2 08          	add    $0x8,%rdx
ffffffff801060e0:	48 c7 44 d0 08 00 00 	movq   $0x0,0x8(%rax,%rdx,8)
ffffffff801060e7:	00 00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
ffffffff801060e9:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
ffffffff801060ed:	83 7d f4 0f          	cmpl   $0xf,-0xc(%rbp)
ffffffff801060f1:	7e 97                	jle    ffffffff8010608a <exit+0x34>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
ffffffff801060f3:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801060f8:	e8 fd e1 ff ff       	callq  ffffffff801042fa <begin_op>
  iput(proc->cwd);
ffffffff801060fd:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106104:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106108:	48 8b 80 c8 00 00 00 	mov    0xc8(%rax),%rax
ffffffff8010610f:	48 89 c7             	mov    %rax,%rdi
ffffffff80106112:	e8 3e c9 ff ff       	callq  ffffffff80102a55 <iput>
  end_op();
ffffffff80106117:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010611c:	e8 5b e2 ff ff       	callq  ffffffff8010437c <end_op>
  proc->cwd = 0;
ffffffff80106121:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106128:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010612c:	48 c7 80 c8 00 00 00 	movq   $0x0,0xc8(%rax)
ffffffff80106133:	00 00 00 00 

  acquire(&ptable.lock);
ffffffff80106137:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff8010613e:	e8 5b 07 00 00       	callq  ffffffff8010689e <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
ffffffff80106143:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff8010614a:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010614e:	48 8b 40 20          	mov    0x20(%rax),%rax
ffffffff80106152:	48 89 c7             	mov    %rax,%rdi
ffffffff80106155:	e8 8a 04 00 00       	callq  ffffffff801065e4 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff8010615a:	48 c7 45 f8 68 0f 19 	movq   $0xffffffff80190f68,-0x8(%rbp)
ffffffff80106161:	80 
ffffffff80106162:	eb 4a                	jmp    ffffffff801061ae <exit+0x158>
    if(p->parent == proc){
ffffffff80106164:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106168:	48 8b 50 20          	mov    0x20(%rax),%rdx
ffffffff8010616c:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106173:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106177:	48 39 c2             	cmp    %rax,%rdx
ffffffff8010617a:	75 2a                	jne    ffffffff801061a6 <exit+0x150>
      p->parent = initproc;
ffffffff8010617c:	48 8b 15 e5 e5 08 00 	mov    0x8e5e5(%rip),%rdx        # ffffffff80194768 <initproc>
ffffffff80106183:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106187:	48 89 50 20          	mov    %rdx,0x20(%rax)
      if(p->state == ZOMBIE)
ffffffff8010618b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010618f:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff80106192:	83 f8 05             	cmp    $0x5,%eax
ffffffff80106195:	75 0f                	jne    ffffffff801061a6 <exit+0x150>
        wakeup1(initproc);
ffffffff80106197:	48 8b 05 ca e5 08 00 	mov    0x8e5ca(%rip),%rax        # ffffffff80194768 <initproc>
ffffffff8010619e:	48 89 c7             	mov    %rax,%rdi
ffffffff801061a1:	e8 3e 04 00 00       	callq  ffffffff801065e4 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff801061a6:	48 81 45 f8 e0 00 00 	addq   $0xe0,-0x8(%rbp)
ffffffff801061ad:	00 
ffffffff801061ae:	48 81 7d f8 68 47 19 	cmpq   $0xffffffff80194768,-0x8(%rbp)
ffffffff801061b5:	80 
ffffffff801061b6:	72 ac                	jb     ffffffff80106164 <exit+0x10e>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
ffffffff801061b8:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801061bf:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801061c3:	c7 40 18 05 00 00 00 	movl   $0x5,0x18(%rax)
  sched();
ffffffff801061ca:	e8 1c 02 00 00       	callq  ffffffff801063eb <sched>
  panic("zombie exit");
ffffffff801061cf:	48 c7 c7 62 ad 10 80 	mov    $0xffffffff8010ad62,%rdi
ffffffff801061d6:	e8 24 a7 ff ff       	callq  ffffffff801008ff <panic>

ffffffff801061db <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
ffffffff801061db:	55                   	push   %rbp
ffffffff801061dc:	48 89 e5             	mov    %rsp,%rbp
ffffffff801061df:	48 83 ec 10          	sub    $0x10,%rsp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
ffffffff801061e3:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801061ea:	e8 af 06 00 00       	callq  ffffffff8010689e <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
ffffffff801061ef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff801061f6:	48 c7 45 f8 68 0f 19 	movq   $0xffffffff80190f68,-0x8(%rbp)
ffffffff801061fd:	80 
ffffffff801061fe:	e9 bb 00 00 00       	jmpq   ffffffff801062be <wait+0xe3>
      if(p->parent != proc)
ffffffff80106203:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106207:	48 8b 50 20          	mov    0x20(%rax),%rdx
ffffffff8010620b:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106212:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106216:	48 39 c2             	cmp    %rax,%rdx
ffffffff80106219:	0f 85 96 00 00 00    	jne    ffffffff801062b5 <wait+0xda>
        continue;
      havekids = 1;
ffffffff8010621f:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%rbp)
      if(p->state == ZOMBIE){
ffffffff80106226:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010622a:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff8010622d:	83 f8 05             	cmp    $0x5,%eax
ffffffff80106230:	0f 85 80 00 00 00    	jne    ffffffff801062b6 <wait+0xdb>
        // Found one.
        pid = p->pid;
ffffffff80106236:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010623a:	8b 40 1c             	mov    0x1c(%rax),%eax
ffffffff8010623d:	89 45 f0             	mov    %eax,-0x10(%rbp)
        kfree(p->kstack);
ffffffff80106240:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106244:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff80106248:	48 89 c7             	mov    %rax,%rdi
ffffffff8010624b:	e8 9e d5 ff ff       	callq  ffffffff801037ee <kfree>
        p->kstack = 0;
ffffffff80106250:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106254:	48 c7 40 10 00 00 00 	movq   $0x0,0x10(%rax)
ffffffff8010625b:	00 
        freevm(p->pgdir);
ffffffff8010625c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106260:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80106264:	48 89 c7             	mov    %rax,%rdi
ffffffff80106267:	e8 4c 36 00 00       	callq  ffffffff801098b8 <freevm>
        p->state = UNUSED;
ffffffff8010626c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106270:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%rax)
        p->pid = 0;
ffffffff80106277:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010627b:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%rax)
        p->parent = 0;
ffffffff80106282:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106286:	48 c7 40 20 00 00 00 	movq   $0x0,0x20(%rax)
ffffffff8010628d:	00 
        p->name[0] = 0;
ffffffff8010628e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106292:	c6 80 d0 00 00 00 00 	movb   $0x0,0xd0(%rax)
        p->killed = 0;
ffffffff80106299:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010629d:	c7 40 40 00 00 00 00 	movl   $0x0,0x40(%rax)
        release(&ptable.lock);
ffffffff801062a4:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801062ab:	e8 c5 06 00 00       	callq  ffffffff80106975 <release>
        return pid;
ffffffff801062b0:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff801062b3:	eb 61                	jmp    ffffffff80106316 <wait+0x13b>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
ffffffff801062b5:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff801062b6:	48 81 45 f8 e0 00 00 	addq   $0xe0,-0x8(%rbp)
ffffffff801062bd:	00 
ffffffff801062be:	48 81 7d f8 68 47 19 	cmpq   $0xffffffff80194768,-0x8(%rbp)
ffffffff801062c5:	80 
ffffffff801062c6:	0f 82 37 ff ff ff    	jb     ffffffff80106203 <wait+0x28>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
ffffffff801062cc:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
ffffffff801062d0:	74 12                	je     ffffffff801062e4 <wait+0x109>
ffffffff801062d2:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801062d9:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801062dd:	8b 40 40             	mov    0x40(%rax),%eax
ffffffff801062e0:	85 c0                	test   %eax,%eax
ffffffff801062e2:	74 13                	je     ffffffff801062f7 <wait+0x11c>
      release(&ptable.lock);
ffffffff801062e4:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801062eb:	e8 85 06 00 00       	callq  ffffffff80106975 <release>
      return -1;
ffffffff801062f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801062f5:	eb 1f                	jmp    ffffffff80106316 <wait+0x13b>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
ffffffff801062f7:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801062fe:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106302:	48 c7 c6 00 0f 19 80 	mov    $0xffffffff80190f00,%rsi
ffffffff80106309:	48 89 c7             	mov    %rax,%rdi
ffffffff8010630c:	e8 10 02 00 00       	callq  ffffffff80106521 <sleep>
  }
ffffffff80106311:	e9 d9 fe ff ff       	jmpq   ffffffff801061ef <wait+0x14>
}
ffffffff80106316:	c9                   	leaveq 
ffffffff80106317:	c3                   	retq   

ffffffff80106318 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
ffffffff80106318:	55                   	push   %rbp
ffffffff80106319:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010631c:	48 83 ec 10          	sub    $0x10,%rsp
  struct proc *p = 0;
ffffffff80106320:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
ffffffff80106327:	00 

  for(;;){
    // Enable interrupts on this processor.
    sti();
ffffffff80106328:	e8 04 f8 ff ff       	callq  ffffffff80105b31 <sti>

    // no runnable processes? (did we hit the end of the table last time?)
    // if so, wait for irq before trying again.
    if (p == &ptable.proc[NPROC])
ffffffff8010632d:	48 81 7d f8 68 47 19 	cmpq   $0xffffffff80194768,-0x8(%rbp)
ffffffff80106334:	80 
ffffffff80106335:	75 05                	jne    ffffffff8010633c <scheduler+0x24>
      hlt();
ffffffff80106337:	e8 fd f7 ff ff       	callq  ffffffff80105b39 <hlt>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
ffffffff8010633c:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80106343:	e8 56 05 00 00       	callq  ffffffff8010689e <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff80106348:	48 c7 45 f8 68 0f 19 	movq   $0xffffffff80190f68,-0x8(%rbp)
ffffffff8010634f:	80 
ffffffff80106350:	eb 7a                	jmp    ffffffff801063cc <scheduler+0xb4>
      if(p->state != RUNNABLE)
ffffffff80106352:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106356:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff80106359:	83 f8 03             	cmp    $0x3,%eax
ffffffff8010635c:	75 65                	jne    ffffffff801063c3 <scheduler+0xab>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
ffffffff8010635e:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106365:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80106369:	64 48 89 10          	mov    %rdx,%fs:(%rax)
      switchuvm(p);
ffffffff8010636d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106371:	48 89 c7             	mov    %rax,%rdi
ffffffff80106374:	e8 cc 3f 00 00       	callq  ffffffff8010a345 <switchuvm>
      p->state = RUNNING;
ffffffff80106379:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010637d:	c7 40 18 04 00 00 00 	movl   $0x4,0x18(%rax)
      swtch(&cpu->scheduler, proc->context);
ffffffff80106384:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff8010638b:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010638f:	48 8b 40 30          	mov    0x30(%rax),%rax
ffffffff80106393:	48 c7 c2 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rdx
ffffffff8010639a:	64 48 8b 12          	mov    %fs:(%rdx),%rdx
ffffffff8010639e:	48 83 c2 08          	add    $0x8,%rdx
ffffffff801063a2:	48 89 c6             	mov    %rax,%rsi
ffffffff801063a5:	48 89 d7             	mov    %rdx,%rdi
ffffffff801063a8:	e8 8f 0b 00 00       	callq  ffffffff80106f3c <swtch>
      switchkvm();
ffffffff801063ad:	e8 75 3f 00 00       	callq  ffffffff8010a327 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
ffffffff801063b2:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801063b9:	64 48 c7 00 00 00 00 	movq   $0x0,%fs:(%rax)
ffffffff801063c0:	00 
ffffffff801063c1:	eb 01                	jmp    ffffffff801063c4 <scheduler+0xac>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
ffffffff801063c3:	90                   	nop
    if (p == &ptable.proc[NPROC])
      hlt();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff801063c4:	48 81 45 f8 e0 00 00 	addq   $0xe0,-0x8(%rbp)
ffffffff801063cb:	00 
ffffffff801063cc:	48 81 7d f8 68 47 19 	cmpq   $0xffffffff80194768,-0x8(%rbp)
ffffffff801063d3:	80 
ffffffff801063d4:	0f 82 78 ff ff ff    	jb     ffffffff80106352 <scheduler+0x3a>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
ffffffff801063da:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801063e1:	e8 8f 05 00 00       	callq  ffffffff80106975 <release>

  }
ffffffff801063e6:	e9 3d ff ff ff       	jmpq   ffffffff80106328 <scheduler+0x10>

ffffffff801063eb <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
ffffffff801063eb:	55                   	push   %rbp
ffffffff801063ec:	48 89 e5             	mov    %rsp,%rbp
ffffffff801063ef:	48 83 ec 10          	sub    $0x10,%rsp
  int intena;

  if(!holding(&ptable.lock))
ffffffff801063f3:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801063fa:	e8 95 06 00 00       	callq  ffffffff80106a94 <holding>
ffffffff801063ff:	85 c0                	test   %eax,%eax
ffffffff80106401:	75 0c                	jne    ffffffff8010640f <sched+0x24>
    panic("sched ptable.lock");
ffffffff80106403:	48 c7 c7 6e ad 10 80 	mov    $0xffffffff8010ad6e,%rdi
ffffffff8010640a:	e8 f0 a4 ff ff       	callq  ffffffff801008ff <panic>
  if(cpu->ncli != 1)
ffffffff8010640f:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80106416:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010641a:	8b 80 dc 00 00 00    	mov    0xdc(%rax),%eax
ffffffff80106420:	83 f8 01             	cmp    $0x1,%eax
ffffffff80106423:	74 0c                	je     ffffffff80106431 <sched+0x46>
    panic("sched locks");
ffffffff80106425:	48 c7 c7 80 ad 10 80 	mov    $0xffffffff8010ad80,%rdi
ffffffff8010642c:	e8 ce a4 ff ff       	callq  ffffffff801008ff <panic>
  if(proc->state == RUNNING)
ffffffff80106431:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106438:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010643c:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff8010643f:	83 f8 04             	cmp    $0x4,%eax
ffffffff80106442:	75 0c                	jne    ffffffff80106450 <sched+0x65>
    panic("sched running");
ffffffff80106444:	48 c7 c7 8c ad 10 80 	mov    $0xffffffff8010ad8c,%rdi
ffffffff8010644b:	e8 af a4 ff ff       	callq  ffffffff801008ff <panic>
  if(readeflags()&FL_IF)
ffffffff80106450:	e8 c8 f6 ff ff       	callq  ffffffff80105b1d <readeflags>
ffffffff80106455:	25 00 02 00 00       	and    $0x200,%eax
ffffffff8010645a:	48 85 c0             	test   %rax,%rax
ffffffff8010645d:	74 0c                	je     ffffffff8010646b <sched+0x80>
    panic("sched interruptible");
ffffffff8010645f:	48 c7 c7 9a ad 10 80 	mov    $0xffffffff8010ad9a,%rdi
ffffffff80106466:	e8 94 a4 ff ff       	callq  ffffffff801008ff <panic>
  intena = cpu->intena;
ffffffff8010646b:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80106472:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106476:	8b 80 e0 00 00 00    	mov    0xe0(%rax),%eax
ffffffff8010647c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  swtch(&proc->context, cpu->scheduler);
ffffffff8010647f:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80106486:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010648a:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff8010648e:	48 c7 c2 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rdx
ffffffff80106495:	64 48 8b 12          	mov    %fs:(%rdx),%rdx
ffffffff80106499:	48 83 c2 30          	add    $0x30,%rdx
ffffffff8010649d:	48 89 c6             	mov    %rax,%rsi
ffffffff801064a0:	48 89 d7             	mov    %rdx,%rdi
ffffffff801064a3:	e8 94 0a 00 00       	callq  ffffffff80106f3c <swtch>
  cpu->intena = intena;
ffffffff801064a8:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff801064af:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801064b3:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801064b6:	89 90 e0 00 00 00    	mov    %edx,0xe0(%rax)
}
ffffffff801064bc:	90                   	nop
ffffffff801064bd:	c9                   	leaveq 
ffffffff801064be:	c3                   	retq   

ffffffff801064bf <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
ffffffff801064bf:	55                   	push   %rbp
ffffffff801064c0:	48 89 e5             	mov    %rsp,%rbp
  acquire(&ptable.lock);  //DOC: yieldlock
ffffffff801064c3:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801064ca:	e8 cf 03 00 00       	callq  ffffffff8010689e <acquire>
  proc->state = RUNNABLE;
ffffffff801064cf:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801064d6:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801064da:	c7 40 18 03 00 00 00 	movl   $0x3,0x18(%rax)
  sched();
ffffffff801064e1:	e8 05 ff ff ff       	callq  ffffffff801063eb <sched>
  release(&ptable.lock);
ffffffff801064e6:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801064ed:	e8 83 04 00 00       	callq  ffffffff80106975 <release>
}
ffffffff801064f2:	90                   	nop
ffffffff801064f3:	5d                   	pop    %rbp
ffffffff801064f4:	c3                   	retq   

ffffffff801064f5 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
ffffffff801064f5:	55                   	push   %rbp
ffffffff801064f6:	48 89 e5             	mov    %rsp,%rbp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
ffffffff801064f9:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80106500:	e8 70 04 00 00       	callq  ffffffff80106975 <release>

  if (first) {
ffffffff80106505:	8b 05 59 60 00 00    	mov    0x6059(%rip),%eax        # ffffffff8010c564 <first.1990>
ffffffff8010650b:	85 c0                	test   %eax,%eax
ffffffff8010650d:	74 0f                	je     ffffffff8010651e <forkret+0x29>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
ffffffff8010650f:	c7 05 4b 60 00 00 00 	movl   $0x0,0x604b(%rip)        # ffffffff8010c564 <first.1990>
ffffffff80106516:	00 00 00 
    initlog();
ffffffff80106519:	e8 a2 db ff ff       	callq  ffffffff801040c0 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
ffffffff8010651e:	90                   	nop
ffffffff8010651f:	5d                   	pop    %rbp
ffffffff80106520:	c3                   	retq   

ffffffff80106521 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
ffffffff80106521:	55                   	push   %rbp
ffffffff80106522:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106525:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80106529:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff8010652d:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  if(proc == 0)
ffffffff80106531:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106538:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010653c:	48 85 c0             	test   %rax,%rax
ffffffff8010653f:	75 0c                	jne    ffffffff8010654d <sleep+0x2c>
    panic("sleep");
ffffffff80106541:	48 c7 c7 ae ad 10 80 	mov    $0xffffffff8010adae,%rdi
ffffffff80106548:	e8 b2 a3 ff ff       	callq  ffffffff801008ff <panic>

  if(lk == 0)
ffffffff8010654d:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80106552:	75 0c                	jne    ffffffff80106560 <sleep+0x3f>
    panic("sleep without lk");
ffffffff80106554:	48 c7 c7 b4 ad 10 80 	mov    $0xffffffff8010adb4,%rdi
ffffffff8010655b:	e8 9f a3 ff ff       	callq  ffffffff801008ff <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
ffffffff80106560:	48 81 7d f0 00 0f 19 	cmpq   $0xffffffff80190f00,-0x10(%rbp)
ffffffff80106567:	80 
ffffffff80106568:	74 18                	je     ffffffff80106582 <sleep+0x61>
    acquire(&ptable.lock);  //DOC: sleeplock1
ffffffff8010656a:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80106571:	e8 28 03 00 00       	callq  ffffffff8010689e <acquire>
    release(lk);
ffffffff80106576:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010657a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010657d:	e8 f3 03 00 00       	callq  ffffffff80106975 <release>
  }

  // Go to sleep.
  proc->chan = chan;
ffffffff80106582:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106589:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010658d:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80106591:	48 89 50 38          	mov    %rdx,0x38(%rax)
  proc->state = SLEEPING;
ffffffff80106595:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff8010659c:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801065a0:	c7 40 18 02 00 00 00 	movl   $0x2,0x18(%rax)
  sched();
ffffffff801065a7:	e8 3f fe ff ff       	callq  ffffffff801063eb <sched>

  // Tidy up.
  proc->chan = 0;
ffffffff801065ac:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801065b3:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801065b7:	48 c7 40 38 00 00 00 	movq   $0x0,0x38(%rax)
ffffffff801065be:	00 

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
ffffffff801065bf:	48 81 7d f0 00 0f 19 	cmpq   $0xffffffff80190f00,-0x10(%rbp)
ffffffff801065c6:	80 
ffffffff801065c7:	74 18                	je     ffffffff801065e1 <sleep+0xc0>
    release(&ptable.lock);
ffffffff801065c9:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801065d0:	e8 a0 03 00 00       	callq  ffffffff80106975 <release>
    acquire(lk);
ffffffff801065d5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801065d9:	48 89 c7             	mov    %rax,%rdi
ffffffff801065dc:	e8 bd 02 00 00       	callq  ffffffff8010689e <acquire>
  }
}
ffffffff801065e1:	90                   	nop
ffffffff801065e2:	c9                   	leaveq 
ffffffff801065e3:	c3                   	retq   

ffffffff801065e4 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
ffffffff801065e4:	55                   	push   %rbp
ffffffff801065e5:	48 89 e5             	mov    %rsp,%rbp
ffffffff801065e8:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff801065ec:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
ffffffff801065f0:	48 c7 45 f8 68 0f 19 	movq   $0xffffffff80190f68,-0x8(%rbp)
ffffffff801065f7:	80 
ffffffff801065f8:	eb 2d                	jmp    ffffffff80106627 <wakeup1+0x43>
    if(p->state == SLEEPING && p->chan == chan)
ffffffff801065fa:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801065fe:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff80106601:	83 f8 02             	cmp    $0x2,%eax
ffffffff80106604:	75 19                	jne    ffffffff8010661f <wakeup1+0x3b>
ffffffff80106606:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010660a:	48 8b 40 38          	mov    0x38(%rax),%rax
ffffffff8010660e:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff80106612:	75 0b                	jne    ffffffff8010661f <wakeup1+0x3b>
      p->state = RUNNABLE;
ffffffff80106614:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106618:	c7 40 18 03 00 00 00 	movl   $0x3,0x18(%rax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
ffffffff8010661f:	48 81 45 f8 e0 00 00 	addq   $0xe0,-0x8(%rbp)
ffffffff80106626:	00 
ffffffff80106627:	48 81 7d f8 68 47 19 	cmpq   $0xffffffff80194768,-0x8(%rbp)
ffffffff8010662e:	80 
ffffffff8010662f:	72 c9                	jb     ffffffff801065fa <wakeup1+0x16>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
ffffffff80106631:	90                   	nop
ffffffff80106632:	c9                   	leaveq 
ffffffff80106633:	c3                   	retq   

ffffffff80106634 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
ffffffff80106634:	55                   	push   %rbp
ffffffff80106635:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106638:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff8010663c:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  acquire(&ptable.lock);
ffffffff80106640:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80106647:	e8 52 02 00 00       	callq  ffffffff8010689e <acquire>
  wakeup1(chan);
ffffffff8010664c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106650:	48 89 c7             	mov    %rax,%rdi
ffffffff80106653:	e8 8c ff ff ff       	callq  ffffffff801065e4 <wakeup1>
  release(&ptable.lock);
ffffffff80106658:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff8010665f:	e8 11 03 00 00       	callq  ffffffff80106975 <release>
}
ffffffff80106664:	90                   	nop
ffffffff80106665:	c9                   	leaveq 
ffffffff80106666:	c3                   	retq   

ffffffff80106667 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
ffffffff80106667:	55                   	push   %rbp
ffffffff80106668:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010666b:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010666f:	89 7d ec             	mov    %edi,-0x14(%rbp)
  struct proc *p;

  acquire(&ptable.lock);
ffffffff80106672:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff80106679:	e8 20 02 00 00       	callq  ffffffff8010689e <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff8010667e:	48 c7 45 f8 68 0f 19 	movq   $0xffffffff80190f68,-0x8(%rbp)
ffffffff80106685:	80 
ffffffff80106686:	eb 49                	jmp    ffffffff801066d1 <kill+0x6a>
    if(p->pid == pid){
ffffffff80106688:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010668c:	8b 40 1c             	mov    0x1c(%rax),%eax
ffffffff8010668f:	3b 45 ec             	cmp    -0x14(%rbp),%eax
ffffffff80106692:	75 35                	jne    ffffffff801066c9 <kill+0x62>
      p->killed = 1;
ffffffff80106694:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106698:	c7 40 40 01 00 00 00 	movl   $0x1,0x40(%rax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
ffffffff8010669f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801066a3:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff801066a6:	83 f8 02             	cmp    $0x2,%eax
ffffffff801066a9:	75 0b                	jne    ffffffff801066b6 <kill+0x4f>
        p->state = RUNNABLE;
ffffffff801066ab:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801066af:	c7 40 18 03 00 00 00 	movl   $0x3,0x18(%rax)
      release(&ptable.lock);
ffffffff801066b6:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801066bd:	e8 b3 02 00 00       	callq  ffffffff80106975 <release>
      return 0;
ffffffff801066c2:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801066c7:	eb 23                	jmp    ffffffff801066ec <kill+0x85>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff801066c9:	48 81 45 f8 e0 00 00 	addq   $0xe0,-0x8(%rbp)
ffffffff801066d0:	00 
ffffffff801066d1:	48 81 7d f8 68 47 19 	cmpq   $0xffffffff80194768,-0x8(%rbp)
ffffffff801066d8:	80 
ffffffff801066d9:	72 ad                	jb     ffffffff80106688 <kill+0x21>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
ffffffff801066db:	48 c7 c7 00 0f 19 80 	mov    $0xffffffff80190f00,%rdi
ffffffff801066e2:	e8 8e 02 00 00       	callq  ffffffff80106975 <release>
  return -1;
ffffffff801066e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff801066ec:	c9                   	leaveq 
ffffffff801066ed:	c3                   	retq   

ffffffff801066ee <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
ffffffff801066ee:	55                   	push   %rbp
ffffffff801066ef:	48 89 e5             	mov    %rsp,%rbp
ffffffff801066f2:	48 83 ec 70          	sub    $0x70,%rsp
  int i;
  struct proc *p;
  char *state;
  uintp pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff801066f6:	48 c7 45 f0 68 0f 19 	movq   $0xffffffff80190f68,-0x10(%rbp)
ffffffff801066fd:	80 
ffffffff801066fe:	e9 0a 01 00 00       	jmpq   ffffffff8010680d <procdump+0x11f>
    if(p->state == UNUSED)
ffffffff80106703:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106707:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff8010670a:	85 c0                	test   %eax,%eax
ffffffff8010670c:	0f 84 f2 00 00 00    	je     ffffffff80106804 <procdump+0x116>
      continue;
    if(p->state && p->state < NELEM(states) && states[p->state])
ffffffff80106712:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106716:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff80106719:	85 c0                	test   %eax,%eax
ffffffff8010671b:	74 39                	je     ffffffff80106756 <procdump+0x68>
ffffffff8010671d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106721:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff80106724:	83 f8 05             	cmp    $0x5,%eax
ffffffff80106727:	77 2d                	ja     ffffffff80106756 <procdump+0x68>
ffffffff80106729:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010672d:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff80106730:	89 c0                	mov    %eax,%eax
ffffffff80106732:	48 8b 04 c5 80 c5 10 	mov    -0x7fef3a80(,%rax,8),%rax
ffffffff80106739:	80 
ffffffff8010673a:	48 85 c0             	test   %rax,%rax
ffffffff8010673d:	74 17                	je     ffffffff80106756 <procdump+0x68>
      state = states[p->state];
ffffffff8010673f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106743:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff80106746:	89 c0                	mov    %eax,%eax
ffffffff80106748:	48 8b 04 c5 80 c5 10 	mov    -0x7fef3a80(,%rax,8),%rax
ffffffff8010674f:	80 
ffffffff80106750:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80106754:	eb 08                	jmp    ffffffff8010675e <procdump+0x70>
    else
      state = "???";
ffffffff80106756:	48 c7 45 e8 c5 ad 10 	movq   $0xffffffff8010adc5,-0x18(%rbp)
ffffffff8010675d:	80 
    cprintf("%d %s %s", p->pid, state, p->name);
ffffffff8010675e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106762:	48 8d 88 d0 00 00 00 	lea    0xd0(%rax),%rcx
ffffffff80106769:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010676d:	8b 40 1c             	mov    0x1c(%rax),%eax
ffffffff80106770:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80106774:	89 c6                	mov    %eax,%esi
ffffffff80106776:	48 c7 c7 c9 ad 10 80 	mov    $0xffffffff8010adc9,%rdi
ffffffff8010677d:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80106782:	e8 1b 9e ff ff       	callq  ffffffff801005a2 <cprintf>
    if(p->state == SLEEPING){
ffffffff80106787:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010678b:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff8010678e:	83 f8 02             	cmp    $0x2,%eax
ffffffff80106791:	75 5e                	jne    ffffffff801067f1 <procdump+0x103>
      getstackpcs((uintp*)p->context->ebp, pc);
ffffffff80106793:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106797:	48 8b 40 30          	mov    0x30(%rax),%rax
ffffffff8010679b:	48 8b 40 30          	mov    0x30(%rax),%rax
ffffffff8010679f:	48 89 c2             	mov    %rax,%rdx
ffffffff801067a2:	48 8d 45 90          	lea    -0x70(%rbp),%rax
ffffffff801067a6:	48 89 c6             	mov    %rax,%rsi
ffffffff801067a9:	48 89 d7             	mov    %rdx,%rdi
ffffffff801067ac:	e8 4a 02 00 00       	callq  ffffffff801069fb <getstackpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
ffffffff801067b1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801067b8:	eb 22                	jmp    ffffffff801067dc <procdump+0xee>
        cprintf(" %p", pc[i]);
ffffffff801067ba:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801067bd:	48 98                	cltq   
ffffffff801067bf:	48 8b 44 c5 90       	mov    -0x70(%rbp,%rax,8),%rax
ffffffff801067c4:	48 89 c6             	mov    %rax,%rsi
ffffffff801067c7:	48 c7 c7 d2 ad 10 80 	mov    $0xffffffff8010add2,%rdi
ffffffff801067ce:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801067d3:	e8 ca 9d ff ff       	callq  ffffffff801005a2 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getstackpcs((uintp*)p->context->ebp, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
ffffffff801067d8:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801067dc:	83 7d fc 09          	cmpl   $0x9,-0x4(%rbp)
ffffffff801067e0:	7f 0f                	jg     ffffffff801067f1 <procdump+0x103>
ffffffff801067e2:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801067e5:	48 98                	cltq   
ffffffff801067e7:	48 8b 44 c5 90       	mov    -0x70(%rbp,%rax,8),%rax
ffffffff801067ec:	48 85 c0             	test   %rax,%rax
ffffffff801067ef:	75 c9                	jne    ffffffff801067ba <procdump+0xcc>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
ffffffff801067f1:	48 c7 c7 d6 ad 10 80 	mov    $0xffffffff8010add6,%rdi
ffffffff801067f8:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801067fd:	e8 a0 9d ff ff       	callq  ffffffff801005a2 <cprintf>
ffffffff80106802:	eb 01                	jmp    ffffffff80106805 <procdump+0x117>
  char *state;
  uintp pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
ffffffff80106804:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uintp pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
ffffffff80106805:	48 81 45 f0 e0 00 00 	addq   $0xe0,-0x10(%rbp)
ffffffff8010680c:	00 
ffffffff8010680d:	48 81 7d f0 68 47 19 	cmpq   $0xffffffff80194768,-0x10(%rbp)
ffffffff80106814:	80 
ffffffff80106815:	0f 82 e8 fe ff ff    	jb     ffffffff80106703 <procdump+0x15>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
ffffffff8010681b:	90                   	nop
ffffffff8010681c:	c9                   	leaveq 
ffffffff8010681d:	c3                   	retq   

ffffffff8010681e <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uintp
readeflags(void)
{
ffffffff8010681e:	55                   	push   %rbp
ffffffff8010681f:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106822:	48 83 ec 10          	sub    $0x10,%rsp
  uintp eflags;
  asm volatile("pushf; pop %0" : "=r" (eflags));
ffffffff80106826:	9c                   	pushfq 
ffffffff80106827:	58                   	pop    %rax
ffffffff80106828:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  return eflags;
ffffffff8010682c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80106830:	c9                   	leaveq 
ffffffff80106831:	c3                   	retq   

ffffffff80106832 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
ffffffff80106832:	55                   	push   %rbp
ffffffff80106833:	48 89 e5             	mov    %rsp,%rbp
  asm volatile("cli");
ffffffff80106836:	fa                   	cli    
}
ffffffff80106837:	90                   	nop
ffffffff80106838:	5d                   	pop    %rbp
ffffffff80106839:	c3                   	retq   

ffffffff8010683a <sti>:

static inline void
sti(void)
{
ffffffff8010683a:	55                   	push   %rbp
ffffffff8010683b:	48 89 e5             	mov    %rsp,%rbp
  asm volatile("sti");
ffffffff8010683e:	fb                   	sti    
}
ffffffff8010683f:	90                   	nop
ffffffff80106840:	5d                   	pop    %rbp
ffffffff80106841:	c3                   	retq   

ffffffff80106842 <xchg>:
  asm volatile("hlt");
}

static inline uint
xchg(volatile uint *addr, uintp newval)
{
ffffffff80106842:	55                   	push   %rbp
ffffffff80106843:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106846:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010684a:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff8010684e:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
               "1" ((uint)newval) :
ffffffff80106852:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
xchg(volatile uint *addr, uintp newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
ffffffff80106856:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff8010685a:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
ffffffff8010685e:	f0 87 02             	lock xchg %eax,(%rdx)
ffffffff80106861:	89 45 fc             	mov    %eax,-0x4(%rbp)
               "+m" (*addr), "=a" (result) :
               "1" ((uint)newval) :
               "cc");
  return result;
ffffffff80106864:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
ffffffff80106867:	c9                   	leaveq 
ffffffff80106868:	c3                   	retq   

ffffffff80106869 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
ffffffff80106869:	55                   	push   %rbp
ffffffff8010686a:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010686d:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80106871:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80106875:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  lk->name = name;
ffffffff80106879:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010687d:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff80106881:	48 89 50 08          	mov    %rdx,0x8(%rax)
  lk->locked = 0;
ffffffff80106885:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106889:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  lk->cpu = 0;
ffffffff8010688f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106893:	48 c7 40 10 00 00 00 	movq   $0x0,0x10(%rax)
ffffffff8010689a:	00 
}
ffffffff8010689b:	90                   	nop
ffffffff8010689c:	c9                   	leaveq 
ffffffff8010689d:	c3                   	retq   

ffffffff8010689e <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
ffffffff8010689e:	55                   	push   %rbp
ffffffff8010689f:	48 89 e5             	mov    %rsp,%rbp
ffffffff801068a2:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801068a6:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  pushcli(); // disable interrupts to avoid deadlock.
ffffffff801068aa:	e8 21 02 00 00       	callq  ffffffff80106ad0 <pushcli>
  if(holding(lk)) {
ffffffff801068af:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801068b3:	48 89 c7             	mov    %rax,%rdi
ffffffff801068b6:	e8 d9 01 00 00       	callq  ffffffff80106a94 <holding>
ffffffff801068bb:	85 c0                	test   %eax,%eax
ffffffff801068bd:	74 73                	je     ffffffff80106932 <acquire+0x94>
    int i;
    cprintf("lock '%s':\n", lk->name);
ffffffff801068bf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801068c3:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff801068c7:	48 89 c6             	mov    %rax,%rsi
ffffffff801068ca:	48 c7 c7 02 ae 10 80 	mov    $0xffffffff8010ae02,%rdi
ffffffff801068d1:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801068d6:	e8 c7 9c ff ff       	callq  ffffffff801005a2 <cprintf>
    for (i = 0; i < 10; i++)
ffffffff801068db:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801068e2:	eb 2b                	jmp    ffffffff8010690f <acquire+0x71>
      cprintf(" %p", lk->pcs[i]);
ffffffff801068e4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801068e8:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801068eb:	48 63 d2             	movslq %edx,%rdx
ffffffff801068ee:	48 83 c2 02          	add    $0x2,%rdx
ffffffff801068f2:	48 8b 44 d0 08       	mov    0x8(%rax,%rdx,8),%rax
ffffffff801068f7:	48 89 c6             	mov    %rax,%rsi
ffffffff801068fa:	48 c7 c7 0e ae 10 80 	mov    $0xffffffff8010ae0e,%rdi
ffffffff80106901:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80106906:	e8 97 9c ff ff       	callq  ffffffff801005a2 <cprintf>
{
  pushcli(); // disable interrupts to avoid deadlock.
  if(holding(lk)) {
    int i;
    cprintf("lock '%s':\n", lk->name);
    for (i = 0; i < 10; i++)
ffffffff8010690b:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff8010690f:	83 7d fc 09          	cmpl   $0x9,-0x4(%rbp)
ffffffff80106913:	7e cf                	jle    ffffffff801068e4 <acquire+0x46>
      cprintf(" %p", lk->pcs[i]);
    cprintf("\n");
ffffffff80106915:	48 c7 c7 12 ae 10 80 	mov    $0xffffffff8010ae12,%rdi
ffffffff8010691c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80106921:	e8 7c 9c ff ff       	callq  ffffffff801005a2 <cprintf>
    panic("acquire");
ffffffff80106926:	48 c7 c7 14 ae 10 80 	mov    $0xffffffff8010ae14,%rdi
ffffffff8010692d:	e8 cd 9f ff ff       	callq  ffffffff801008ff <panic>
  }

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
ffffffff80106932:	90                   	nop
ffffffff80106933:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106937:	be 01 00 00 00       	mov    $0x1,%esi
ffffffff8010693c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010693f:	e8 fe fe ff ff       	callq  ffffffff80106842 <xchg>
ffffffff80106944:	85 c0                	test   %eax,%eax
ffffffff80106946:	75 eb                	jne    ffffffff80106933 <acquire+0x95>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
ffffffff80106948:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010694c:	48 c7 c2 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rdx
ffffffff80106953:	64 48 8b 12          	mov    %fs:(%rdx),%rdx
ffffffff80106957:	48 89 50 10          	mov    %rdx,0x10(%rax)
  getcallerpcs(&lk, lk->pcs);
ffffffff8010695b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010695f:	48 8d 50 18          	lea    0x18(%rax),%rdx
ffffffff80106963:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
ffffffff80106967:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010696a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010696d:	e8 5c 00 00 00       	callq  ffffffff801069ce <getcallerpcs>
}
ffffffff80106972:	90                   	nop
ffffffff80106973:	c9                   	leaveq 
ffffffff80106974:	c3                   	retq   

ffffffff80106975 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
ffffffff80106975:	55                   	push   %rbp
ffffffff80106976:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106979:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff8010697d:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  if(!holding(lk))
ffffffff80106981:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106985:	48 89 c7             	mov    %rax,%rdi
ffffffff80106988:	e8 07 01 00 00       	callq  ffffffff80106a94 <holding>
ffffffff8010698d:	85 c0                	test   %eax,%eax
ffffffff8010698f:	75 0c                	jne    ffffffff8010699d <release+0x28>
    panic("release");
ffffffff80106991:	48 c7 c7 1c ae 10 80 	mov    $0xffffffff8010ae1c,%rdi
ffffffff80106998:	e8 62 9f ff ff       	callq  ffffffff801008ff <panic>

  lk->pcs[0] = 0;
ffffffff8010699d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801069a1:	48 c7 40 18 00 00 00 	movq   $0x0,0x18(%rax)
ffffffff801069a8:	00 
  lk->cpu = 0;
ffffffff801069a9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801069ad:	48 c7 40 10 00 00 00 	movq   $0x0,0x10(%rax)
ffffffff801069b4:	00 
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
ffffffff801069b5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801069b9:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801069be:	48 89 c7             	mov    %rax,%rdi
ffffffff801069c1:	e8 7c fe ff ff       	callq  ffffffff80106842 <xchg>

  popcli();
ffffffff801069c6:	e8 55 01 00 00       	callq  ffffffff80106b20 <popcli>
}
ffffffff801069cb:	90                   	nop
ffffffff801069cc:	c9                   	leaveq 
ffffffff801069cd:	c3                   	retq   

ffffffff801069ce <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uintp pcs[])
{
ffffffff801069ce:	55                   	push   %rbp
ffffffff801069cf:	48 89 e5             	mov    %rsp,%rbp
ffffffff801069d2:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801069d6:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff801069da:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  uintp *ebp;
#if X64
  asm volatile("mov %%rbp, %0" : "=r" (ebp));  
ffffffff801069de:	48 89 e8             	mov    %rbp,%rax
ffffffff801069e1:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
#else
  ebp = (uintp*)v - 2;
#endif
  getstackpcs(ebp, pcs);
ffffffff801069e5:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff801069e9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801069ed:	48 89 d6             	mov    %rdx,%rsi
ffffffff801069f0:	48 89 c7             	mov    %rax,%rdi
ffffffff801069f3:	e8 03 00 00 00       	callq  ffffffff801069fb <getstackpcs>
}
ffffffff801069f8:	90                   	nop
ffffffff801069f9:	c9                   	leaveq 
ffffffff801069fa:	c3                   	retq   

ffffffff801069fb <getstackpcs>:

void
getstackpcs(uintp *ebp, uintp pcs[])
{
ffffffff801069fb:	55                   	push   %rbp
ffffffff801069fc:	48 89 e5             	mov    %rsp,%rbp
ffffffff801069ff:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80106a03:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80106a07:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  int i;
  
  for(i = 0; i < 10; i++){
ffffffff80106a0b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80106a12:	eb 50                	jmp    ffffffff80106a64 <getstackpcs+0x69>
    if(ebp == 0 || ebp < (uintp*)KERNBASE || ebp == (uintp*)0xffffffff)
ffffffff80106a14:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff80106a19:	74 70                	je     ffffffff80106a8b <getstackpcs+0x90>
ffffffff80106a1b:	48 b8 ff ff ff 7f ff 	movabs $0xffffffff7fffffff,%rax
ffffffff80106a22:	ff ff ff 
ffffffff80106a25:	48 39 45 e8          	cmp    %rax,-0x18(%rbp)
ffffffff80106a29:	76 60                	jbe    ffffffff80106a8b <getstackpcs+0x90>
ffffffff80106a2b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80106a30:	48 39 45 e8          	cmp    %rax,-0x18(%rbp)
ffffffff80106a34:	74 55                	je     ffffffff80106a8b <getstackpcs+0x90>
      break;
    pcs[i] = ebp[1];     // saved %eip
ffffffff80106a36:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80106a39:	48 98                	cltq   
ffffffff80106a3b:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80106a42:	00 
ffffffff80106a43:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80106a47:	48 01 c2             	add    %rax,%rdx
ffffffff80106a4a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106a4e:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff80106a52:	48 89 02             	mov    %rax,(%rdx)
    ebp = (uintp*)ebp[0]; // saved %ebp
ffffffff80106a55:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106a59:	48 8b 00             	mov    (%rax),%rax
ffffffff80106a5c:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
void
getstackpcs(uintp *ebp, uintp pcs[])
{
  int i;
  
  for(i = 0; i < 10; i++){
ffffffff80106a60:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80106a64:	83 7d fc 09          	cmpl   $0x9,-0x4(%rbp)
ffffffff80106a68:	7e aa                	jle    ffffffff80106a14 <getstackpcs+0x19>
    if(ebp == 0 || ebp < (uintp*)KERNBASE || ebp == (uintp*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uintp*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
ffffffff80106a6a:	eb 1f                	jmp    ffffffff80106a8b <getstackpcs+0x90>
    pcs[i] = 0;
ffffffff80106a6c:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80106a6f:	48 98                	cltq   
ffffffff80106a71:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80106a78:	00 
ffffffff80106a79:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80106a7d:	48 01 d0             	add    %rdx,%rax
ffffffff80106a80:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
    if(ebp == 0 || ebp < (uintp*)KERNBASE || ebp == (uintp*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uintp*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
ffffffff80106a87:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80106a8b:	83 7d fc 09          	cmpl   $0x9,-0x4(%rbp)
ffffffff80106a8f:	7e db                	jle    ffffffff80106a6c <getstackpcs+0x71>
    pcs[i] = 0;
}
ffffffff80106a91:	90                   	nop
ffffffff80106a92:	c9                   	leaveq 
ffffffff80106a93:	c3                   	retq   

ffffffff80106a94 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
ffffffff80106a94:	55                   	push   %rbp
ffffffff80106a95:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106a98:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80106a9c:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  return lock->locked && lock->cpu == cpu;
ffffffff80106aa0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106aa4:	8b 00                	mov    (%rax),%eax
ffffffff80106aa6:	85 c0                	test   %eax,%eax
ffffffff80106aa8:	74 1f                	je     ffffffff80106ac9 <holding+0x35>
ffffffff80106aaa:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106aae:	48 8b 50 10          	mov    0x10(%rax),%rdx
ffffffff80106ab2:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80106ab9:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106abd:	48 39 c2             	cmp    %rax,%rdx
ffffffff80106ac0:	75 07                	jne    ffffffff80106ac9 <holding+0x35>
ffffffff80106ac2:	b8 01 00 00 00       	mov    $0x1,%eax
ffffffff80106ac7:	eb 05                	jmp    ffffffff80106ace <holding+0x3a>
ffffffff80106ac9:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80106ace:	c9                   	leaveq 
ffffffff80106acf:	c3                   	retq   

ffffffff80106ad0 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
ffffffff80106ad0:	55                   	push   %rbp
ffffffff80106ad1:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106ad4:	48 83 ec 10          	sub    $0x10,%rsp
  int eflags;
  
  eflags = readeflags();
ffffffff80106ad8:	e8 41 fd ff ff       	callq  ffffffff8010681e <readeflags>
ffffffff80106add:	89 45 fc             	mov    %eax,-0x4(%rbp)
  cli();
ffffffff80106ae0:	e8 4d fd ff ff       	callq  ffffffff80106832 <cli>
  if(cpu->ncli++ == 0)
ffffffff80106ae5:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80106aec:	64 48 8b 10          	mov    %fs:(%rax),%rdx
ffffffff80106af0:	8b 82 dc 00 00 00    	mov    0xdc(%rdx),%eax
ffffffff80106af6:	8d 48 01             	lea    0x1(%rax),%ecx
ffffffff80106af9:	89 8a dc 00 00 00    	mov    %ecx,0xdc(%rdx)
ffffffff80106aff:	85 c0                	test   %eax,%eax
ffffffff80106b01:	75 1a                	jne    ffffffff80106b1d <pushcli+0x4d>
    cpu->intena = eflags & FL_IF;
ffffffff80106b03:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80106b0a:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106b0e:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80106b11:	81 e2 00 02 00 00    	and    $0x200,%edx
ffffffff80106b17:	89 90 e0 00 00 00    	mov    %edx,0xe0(%rax)
}
ffffffff80106b1d:	90                   	nop
ffffffff80106b1e:	c9                   	leaveq 
ffffffff80106b1f:	c3                   	retq   

ffffffff80106b20 <popcli>:

void
popcli(void)
{
ffffffff80106b20:	55                   	push   %rbp
ffffffff80106b21:	48 89 e5             	mov    %rsp,%rbp
  if(readeflags()&FL_IF)
ffffffff80106b24:	e8 f5 fc ff ff       	callq  ffffffff8010681e <readeflags>
ffffffff80106b29:	25 00 02 00 00       	and    $0x200,%eax
ffffffff80106b2e:	48 85 c0             	test   %rax,%rax
ffffffff80106b31:	74 0c                	je     ffffffff80106b3f <popcli+0x1f>
    panic("popcli - interruptible");
ffffffff80106b33:	48 c7 c7 24 ae 10 80 	mov    $0xffffffff8010ae24,%rdi
ffffffff80106b3a:	e8 c0 9d ff ff       	callq  ffffffff801008ff <panic>
  if(--cpu->ncli < 0)
ffffffff80106b3f:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80106b46:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106b4a:	8b 90 dc 00 00 00    	mov    0xdc(%rax),%edx
ffffffff80106b50:	83 ea 01             	sub    $0x1,%edx
ffffffff80106b53:	89 90 dc 00 00 00    	mov    %edx,0xdc(%rax)
ffffffff80106b59:	8b 80 dc 00 00 00    	mov    0xdc(%rax),%eax
ffffffff80106b5f:	85 c0                	test   %eax,%eax
ffffffff80106b61:	79 0c                	jns    ffffffff80106b6f <popcli+0x4f>
    panic("popcli");
ffffffff80106b63:	48 c7 c7 3b ae 10 80 	mov    $0xffffffff8010ae3b,%rdi
ffffffff80106b6a:	e8 90 9d ff ff       	callq  ffffffff801008ff <panic>
  if(cpu->ncli == 0 && cpu->intena)
ffffffff80106b6f:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80106b76:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106b7a:	8b 80 dc 00 00 00    	mov    0xdc(%rax),%eax
ffffffff80106b80:	85 c0                	test   %eax,%eax
ffffffff80106b82:	75 1a                	jne    ffffffff80106b9e <popcli+0x7e>
ffffffff80106b84:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff80106b8b:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106b8f:	8b 80 e0 00 00 00    	mov    0xe0(%rax),%eax
ffffffff80106b95:	85 c0                	test   %eax,%eax
ffffffff80106b97:	74 05                	je     ffffffff80106b9e <popcli+0x7e>
    sti();
ffffffff80106b99:	e8 9c fc ff ff       	callq  ffffffff8010683a <sti>
}
ffffffff80106b9e:	90                   	nop
ffffffff80106b9f:	5d                   	pop    %rbp
ffffffff80106ba0:	c3                   	retq   

ffffffff80106ba1 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
ffffffff80106ba1:	55                   	push   %rbp
ffffffff80106ba2:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106ba5:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80106ba9:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80106bad:	89 75 f4             	mov    %esi,-0xc(%rbp)
ffffffff80106bb0:	89 55 f0             	mov    %edx,-0x10(%rbp)
  asm volatile("cld; rep stosb" :
ffffffff80106bb3:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
ffffffff80106bb7:	8b 55 f0             	mov    -0x10(%rbp),%edx
ffffffff80106bba:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80106bbd:	48 89 ce             	mov    %rcx,%rsi
ffffffff80106bc0:	48 89 f7             	mov    %rsi,%rdi
ffffffff80106bc3:	89 d1                	mov    %edx,%ecx
ffffffff80106bc5:	fc                   	cld    
ffffffff80106bc6:	f3 aa                	rep stos %al,%es:(%rdi)
ffffffff80106bc8:	89 ca                	mov    %ecx,%edx
ffffffff80106bca:	48 89 fe             	mov    %rdi,%rsi
ffffffff80106bcd:	48 89 75 f8          	mov    %rsi,-0x8(%rbp)
ffffffff80106bd1:	89 55 f0             	mov    %edx,-0x10(%rbp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
ffffffff80106bd4:	90                   	nop
ffffffff80106bd5:	c9                   	leaveq 
ffffffff80106bd6:	c3                   	retq   

ffffffff80106bd7 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
ffffffff80106bd7:	55                   	push   %rbp
ffffffff80106bd8:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106bdb:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80106bdf:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80106be3:	89 75 f4             	mov    %esi,-0xc(%rbp)
ffffffff80106be6:	89 55 f0             	mov    %edx,-0x10(%rbp)
  asm volatile("cld; rep stosl" :
ffffffff80106be9:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
ffffffff80106bed:	8b 55 f0             	mov    -0x10(%rbp),%edx
ffffffff80106bf0:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80106bf3:	48 89 ce             	mov    %rcx,%rsi
ffffffff80106bf6:	48 89 f7             	mov    %rsi,%rdi
ffffffff80106bf9:	89 d1                	mov    %edx,%ecx
ffffffff80106bfb:	fc                   	cld    
ffffffff80106bfc:	f3 ab                	rep stos %eax,%es:(%rdi)
ffffffff80106bfe:	89 ca                	mov    %ecx,%edx
ffffffff80106c00:	48 89 fe             	mov    %rdi,%rsi
ffffffff80106c03:	48 89 75 f8          	mov    %rsi,-0x8(%rbp)
ffffffff80106c07:	89 55 f0             	mov    %edx,-0x10(%rbp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
ffffffff80106c0a:	90                   	nop
ffffffff80106c0b:	c9                   	leaveq 
ffffffff80106c0c:	c3                   	retq   

ffffffff80106c0d <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
ffffffff80106c0d:	55                   	push   %rbp
ffffffff80106c0e:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106c11:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80106c15:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80106c19:	89 75 f4             	mov    %esi,-0xc(%rbp)
ffffffff80106c1c:	89 55 f0             	mov    %edx,-0x10(%rbp)
  if ((uintp)dst%4 == 0 && n%4 == 0){
ffffffff80106c1f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106c23:	83 e0 03             	and    $0x3,%eax
ffffffff80106c26:	48 85 c0             	test   %rax,%rax
ffffffff80106c29:	75 48                	jne    ffffffff80106c73 <memset+0x66>
ffffffff80106c2b:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff80106c2e:	83 e0 03             	and    $0x3,%eax
ffffffff80106c31:	85 c0                	test   %eax,%eax
ffffffff80106c33:	75 3e                	jne    ffffffff80106c73 <memset+0x66>
    c &= 0xFF;
ffffffff80106c35:	81 65 f4 ff 00 00 00 	andl   $0xff,-0xc(%rbp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
ffffffff80106c3c:	8b 45 f0             	mov    -0x10(%rbp),%eax
ffffffff80106c3f:	c1 e8 02             	shr    $0x2,%eax
ffffffff80106c42:	89 c6                	mov    %eax,%esi
ffffffff80106c44:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80106c47:	c1 e0 18             	shl    $0x18,%eax
ffffffff80106c4a:	89 c2                	mov    %eax,%edx
ffffffff80106c4c:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80106c4f:	c1 e0 10             	shl    $0x10,%eax
ffffffff80106c52:	09 c2                	or     %eax,%edx
ffffffff80106c54:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80106c57:	c1 e0 08             	shl    $0x8,%eax
ffffffff80106c5a:	09 d0                	or     %edx,%eax
ffffffff80106c5c:	0b 45 f4             	or     -0xc(%rbp),%eax
ffffffff80106c5f:	89 c1                	mov    %eax,%ecx
ffffffff80106c61:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106c65:	89 f2                	mov    %esi,%edx
ffffffff80106c67:	89 ce                	mov    %ecx,%esi
ffffffff80106c69:	48 89 c7             	mov    %rax,%rdi
ffffffff80106c6c:	e8 66 ff ff ff       	callq  ffffffff80106bd7 <stosl>
ffffffff80106c71:	eb 14                	jmp    ffffffff80106c87 <memset+0x7a>
  } else
    stosb(dst, c, n);
ffffffff80106c73:	8b 55 f0             	mov    -0x10(%rbp),%edx
ffffffff80106c76:	8b 4d f4             	mov    -0xc(%rbp),%ecx
ffffffff80106c79:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106c7d:	89 ce                	mov    %ecx,%esi
ffffffff80106c7f:	48 89 c7             	mov    %rax,%rdi
ffffffff80106c82:	e8 1a ff ff ff       	callq  ffffffff80106ba1 <stosb>
  return dst;
ffffffff80106c87:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80106c8b:	c9                   	leaveq 
ffffffff80106c8c:	c3                   	retq   

ffffffff80106c8d <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
ffffffff80106c8d:	55                   	push   %rbp
ffffffff80106c8e:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106c91:	48 83 ec 28          	sub    $0x28,%rsp
ffffffff80106c95:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80106c99:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80106c9d:	89 55 dc             	mov    %edx,-0x24(%rbp)
  const uchar *s1, *s2;
  
  s1 = v1;
ffffffff80106ca0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106ca4:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  s2 = v2;
ffffffff80106ca8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80106cac:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  while(n-- > 0){
ffffffff80106cb0:	eb 36                	jmp    ffffffff80106ce8 <memcmp+0x5b>
    if(*s1 != *s2)
ffffffff80106cb2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106cb6:	0f b6 10             	movzbl (%rax),%edx
ffffffff80106cb9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106cbd:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106cc0:	38 c2                	cmp    %al,%dl
ffffffff80106cc2:	74 1a                	je     ffffffff80106cde <memcmp+0x51>
      return *s1 - *s2;
ffffffff80106cc4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106cc8:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106ccb:	0f b6 d0             	movzbl %al,%edx
ffffffff80106cce:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106cd2:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106cd5:	0f b6 c0             	movzbl %al,%eax
ffffffff80106cd8:	29 c2                	sub    %eax,%edx
ffffffff80106cda:	89 d0                	mov    %edx,%eax
ffffffff80106cdc:	eb 1c                	jmp    ffffffff80106cfa <memcmp+0x6d>
    s1++, s2++;
ffffffff80106cde:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
ffffffff80106ce3:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
ffffffff80106ce8:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80106ceb:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80106cee:	89 55 dc             	mov    %edx,-0x24(%rbp)
ffffffff80106cf1:	85 c0                	test   %eax,%eax
ffffffff80106cf3:	75 bd                	jne    ffffffff80106cb2 <memcmp+0x25>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
ffffffff80106cf5:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80106cfa:	c9                   	leaveq 
ffffffff80106cfb:	c3                   	retq   

ffffffff80106cfc <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
ffffffff80106cfc:	55                   	push   %rbp
ffffffff80106cfd:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106d00:	48 83 ec 28          	sub    $0x28,%rsp
ffffffff80106d04:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80106d08:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80106d0c:	89 55 dc             	mov    %edx,-0x24(%rbp)
  const char *s;
  char *d;

  s = src;
ffffffff80106d0f:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80106d13:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  d = dst;
ffffffff80106d17:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106d1b:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  if(s < d && s + n > d){
ffffffff80106d1f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106d23:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
ffffffff80106d27:	73 63                	jae    ffffffff80106d8c <memmove+0x90>
ffffffff80106d29:	8b 55 dc             	mov    -0x24(%rbp),%edx
ffffffff80106d2c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106d30:	48 01 d0             	add    %rdx,%rax
ffffffff80106d33:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
ffffffff80106d37:	76 53                	jbe    ffffffff80106d8c <memmove+0x90>
    s += n;
ffffffff80106d39:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80106d3c:	48 01 45 f8          	add    %rax,-0x8(%rbp)
    d += n;
ffffffff80106d40:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80106d43:	48 01 45 f0          	add    %rax,-0x10(%rbp)
    while(n-- > 0)
ffffffff80106d47:	eb 17                	jmp    ffffffff80106d60 <memmove+0x64>
      *--d = *--s;
ffffffff80106d49:	48 83 6d f0 01       	subq   $0x1,-0x10(%rbp)
ffffffff80106d4e:	48 83 6d f8 01       	subq   $0x1,-0x8(%rbp)
ffffffff80106d53:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106d57:	0f b6 10             	movzbl (%rax),%edx
ffffffff80106d5a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106d5e:	88 10                	mov    %dl,(%rax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
ffffffff80106d60:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80106d63:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80106d66:	89 55 dc             	mov    %edx,-0x24(%rbp)
ffffffff80106d69:	85 c0                	test   %eax,%eax
ffffffff80106d6b:	75 dc                	jne    ffffffff80106d49 <memmove+0x4d>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
ffffffff80106d6d:	eb 2a                	jmp    ffffffff80106d99 <memmove+0x9d>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
ffffffff80106d6f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106d73:	48 8d 50 01          	lea    0x1(%rax),%rdx
ffffffff80106d77:	48 89 55 f0          	mov    %rdx,-0x10(%rbp)
ffffffff80106d7b:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80106d7f:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
ffffffff80106d83:	48 89 4d f8          	mov    %rcx,-0x8(%rbp)
ffffffff80106d87:	0f b6 12             	movzbl (%rdx),%edx
ffffffff80106d8a:	88 10                	mov    %dl,(%rax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
ffffffff80106d8c:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80106d8f:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80106d92:	89 55 dc             	mov    %edx,-0x24(%rbp)
ffffffff80106d95:	85 c0                	test   %eax,%eax
ffffffff80106d97:	75 d6                	jne    ffffffff80106d6f <memmove+0x73>
      *d++ = *s++;

  return dst;
ffffffff80106d99:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
}
ffffffff80106d9d:	c9                   	leaveq 
ffffffff80106d9e:	c3                   	retq   

ffffffff80106d9f <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
ffffffff80106d9f:	55                   	push   %rbp
ffffffff80106da0:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106da3:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff80106da7:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80106dab:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
ffffffff80106daf:	89 55 ec             	mov    %edx,-0x14(%rbp)
  return memmove(dst, src, n);
ffffffff80106db2:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff80106db5:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
ffffffff80106db9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106dbd:	48 89 ce             	mov    %rcx,%rsi
ffffffff80106dc0:	48 89 c7             	mov    %rax,%rdi
ffffffff80106dc3:	e8 34 ff ff ff       	callq  ffffffff80106cfc <memmove>
}
ffffffff80106dc8:	c9                   	leaveq 
ffffffff80106dc9:	c3                   	retq   

ffffffff80106dca <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
ffffffff80106dca:	55                   	push   %rbp
ffffffff80106dcb:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106dce:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff80106dd2:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80106dd6:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
ffffffff80106dda:	89 55 ec             	mov    %edx,-0x14(%rbp)
  while(n > 0 && *p && *p == *q)
ffffffff80106ddd:	eb 0e                	jmp    ffffffff80106ded <strncmp+0x23>
    n--, p++, q++;
ffffffff80106ddf:	83 6d ec 01          	subl   $0x1,-0x14(%rbp)
ffffffff80106de3:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
ffffffff80106de8:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
ffffffff80106ded:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80106df1:	74 1d                	je     ffffffff80106e10 <strncmp+0x46>
ffffffff80106df3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106df7:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106dfa:	84 c0                	test   %al,%al
ffffffff80106dfc:	74 12                	je     ffffffff80106e10 <strncmp+0x46>
ffffffff80106dfe:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106e02:	0f b6 10             	movzbl (%rax),%edx
ffffffff80106e05:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106e09:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106e0c:	38 c2                	cmp    %al,%dl
ffffffff80106e0e:	74 cf                	je     ffffffff80106ddf <strncmp+0x15>
    n--, p++, q++;
  if(n == 0)
ffffffff80106e10:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80106e14:	75 07                	jne    ffffffff80106e1d <strncmp+0x53>
    return 0;
ffffffff80106e16:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80106e1b:	eb 18                	jmp    ffffffff80106e35 <strncmp+0x6b>
  return (uchar)*p - (uchar)*q;
ffffffff80106e1d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106e21:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106e24:	0f b6 d0             	movzbl %al,%edx
ffffffff80106e27:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106e2b:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106e2e:	0f b6 c0             	movzbl %al,%eax
ffffffff80106e31:	29 c2                	sub    %eax,%edx
ffffffff80106e33:	89 d0                	mov    %edx,%eax
}
ffffffff80106e35:	c9                   	leaveq 
ffffffff80106e36:	c3                   	retq   

ffffffff80106e37 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
ffffffff80106e37:	55                   	push   %rbp
ffffffff80106e38:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106e3b:	48 83 ec 28          	sub    $0x28,%rsp
ffffffff80106e3f:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80106e43:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80106e47:	89 55 dc             	mov    %edx,-0x24(%rbp)
  char *os;
  
  os = s;
ffffffff80106e4a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106e4e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  while(n-- > 0 && (*s++ = *t++) != 0)
ffffffff80106e52:	90                   	nop
ffffffff80106e53:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80106e56:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80106e59:	89 55 dc             	mov    %edx,-0x24(%rbp)
ffffffff80106e5c:	85 c0                	test   %eax,%eax
ffffffff80106e5e:	7e 35                	jle    ffffffff80106e95 <strncpy+0x5e>
ffffffff80106e60:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106e64:	48 8d 50 01          	lea    0x1(%rax),%rdx
ffffffff80106e68:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
ffffffff80106e6c:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80106e70:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
ffffffff80106e74:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
ffffffff80106e78:	0f b6 12             	movzbl (%rdx),%edx
ffffffff80106e7b:	88 10                	mov    %dl,(%rax)
ffffffff80106e7d:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106e80:	84 c0                	test   %al,%al
ffffffff80106e82:	75 cf                	jne    ffffffff80106e53 <strncpy+0x1c>
    ;
  while(n-- > 0)
ffffffff80106e84:	eb 0f                	jmp    ffffffff80106e95 <strncpy+0x5e>
    *s++ = 0;
ffffffff80106e86:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106e8a:	48 8d 50 01          	lea    0x1(%rax),%rdx
ffffffff80106e8e:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
ffffffff80106e92:	c6 00 00             	movb   $0x0,(%rax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
ffffffff80106e95:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80106e98:	8d 50 ff             	lea    -0x1(%rax),%edx
ffffffff80106e9b:	89 55 dc             	mov    %edx,-0x24(%rbp)
ffffffff80106e9e:	85 c0                	test   %eax,%eax
ffffffff80106ea0:	7f e4                	jg     ffffffff80106e86 <strncpy+0x4f>
    *s++ = 0;
  return os;
ffffffff80106ea2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80106ea6:	c9                   	leaveq 
ffffffff80106ea7:	c3                   	retq   

ffffffff80106ea8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
ffffffff80106ea8:	55                   	push   %rbp
ffffffff80106ea9:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106eac:	48 83 ec 28          	sub    $0x28,%rsp
ffffffff80106eb0:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80106eb4:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80106eb8:	89 55 dc             	mov    %edx,-0x24(%rbp)
  char *os;
  
  os = s;
ffffffff80106ebb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106ebf:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if(n <= 0)
ffffffff80106ec3:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
ffffffff80106ec7:	7f 06                	jg     ffffffff80106ecf <safestrcpy+0x27>
    return os;
ffffffff80106ec9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106ecd:	eb 39                	jmp    ffffffff80106f08 <safestrcpy+0x60>
  while(--n > 0 && (*s++ = *t++) != 0)
ffffffff80106ecf:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
ffffffff80106ed3:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
ffffffff80106ed7:	7e 24                	jle    ffffffff80106efd <safestrcpy+0x55>
ffffffff80106ed9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106edd:	48 8d 50 01          	lea    0x1(%rax),%rdx
ffffffff80106ee1:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
ffffffff80106ee5:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80106ee9:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
ffffffff80106eed:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
ffffffff80106ef1:	0f b6 12             	movzbl (%rdx),%edx
ffffffff80106ef4:	88 10                	mov    %dl,(%rax)
ffffffff80106ef6:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106ef9:	84 c0                	test   %al,%al
ffffffff80106efb:	75 d2                	jne    ffffffff80106ecf <safestrcpy+0x27>
    ;
  *s = 0;
ffffffff80106efd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106f01:	c6 00 00             	movb   $0x0,(%rax)
  return os;
ffffffff80106f04:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80106f08:	c9                   	leaveq 
ffffffff80106f09:	c3                   	retq   

ffffffff80106f0a <strlen>:

int
strlen(const char *s)
{
ffffffff80106f0a:	55                   	push   %rbp
ffffffff80106f0b:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106f0e:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff80106f12:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  int n;

  for(n = 0; s[n]; n++)
ffffffff80106f16:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80106f1d:	eb 04                	jmp    ffffffff80106f23 <strlen+0x19>
ffffffff80106f1f:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80106f23:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80106f26:	48 63 d0             	movslq %eax,%rdx
ffffffff80106f29:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80106f2d:	48 01 d0             	add    %rdx,%rax
ffffffff80106f30:	0f b6 00             	movzbl (%rax),%eax
ffffffff80106f33:	84 c0                	test   %al,%al
ffffffff80106f35:	75 e8                	jne    ffffffff80106f1f <strlen+0x15>
    ;
  return n;
ffffffff80106f37:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
ffffffff80106f3a:	c9                   	leaveq 
ffffffff80106f3b:	c3                   	retq   

ffffffff80106f3c <swtch>:
# and then load register context from new.

.globl swtch
swtch:
  # Save old callee-save registers
  push %rbp
ffffffff80106f3c:	55                   	push   %rbp
  push %rbx
ffffffff80106f3d:	53                   	push   %rbx
  push %r11
ffffffff80106f3e:	41 53                	push   %r11
  push %r12
ffffffff80106f40:	41 54                	push   %r12
  push %r13
ffffffff80106f42:	41 55                	push   %r13
  push %r14
ffffffff80106f44:	41 56                	push   %r14
  push %r15
ffffffff80106f46:	41 57                	push   %r15

  # Switch stacks
  mov %rsp, (%rdi)
ffffffff80106f48:	48 89 27             	mov    %rsp,(%rdi)
  mov %rsi, %rsp
ffffffff80106f4b:	48 89 f4             	mov    %rsi,%rsp

  # Load new callee-save registers
  pop %r15
ffffffff80106f4e:	41 5f                	pop    %r15
  pop %r14
ffffffff80106f50:	41 5e                	pop    %r14
  pop %r13
ffffffff80106f52:	41 5d                	pop    %r13
  pop %r12
ffffffff80106f54:	41 5c                	pop    %r12
  pop %r11
ffffffff80106f56:	41 5b                	pop    %r11
  pop %rbx
ffffffff80106f58:	5b                   	pop    %rbx
  pop %rbp
ffffffff80106f59:	5d                   	pop    %rbp

  ret #??
ffffffff80106f5a:	c3                   	retq   

ffffffff80106f5b <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uintp addr, int *ip)
{
ffffffff80106f5b:	55                   	push   %rbp
ffffffff80106f5c:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106f5f:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80106f63:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80106f67:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  if(addr >= proc->sz || addr+sizeof(int) > proc->sz)
ffffffff80106f6b:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106f72:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106f76:	48 8b 00             	mov    (%rax),%rax
ffffffff80106f79:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
ffffffff80106f7d:	76 1b                	jbe    ffffffff80106f9a <fetchint+0x3f>
ffffffff80106f7f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106f83:	48 8d 50 04          	lea    0x4(%rax),%rdx
ffffffff80106f87:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106f8e:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106f92:	48 8b 00             	mov    (%rax),%rax
ffffffff80106f95:	48 39 c2             	cmp    %rax,%rdx
ffffffff80106f98:	76 07                	jbe    ffffffff80106fa1 <fetchint+0x46>
    return -1;
ffffffff80106f9a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80106f9f:	eb 11                	jmp    ffffffff80106fb2 <fetchint+0x57>
  *ip = *(int*)(addr);
ffffffff80106fa1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106fa5:	8b 10                	mov    (%rax),%edx
ffffffff80106fa7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80106fab:	89 10                	mov    %edx,(%rax)
  return 0;
ffffffff80106fad:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80106fb2:	c9                   	leaveq 
ffffffff80106fb3:	c3                   	retq   

ffffffff80106fb4 <fetchuintp>:

int
fetchuintp(uintp addr, uintp *ip)
{
ffffffff80106fb4:	55                   	push   %rbp
ffffffff80106fb5:	48 89 e5             	mov    %rsp,%rbp
ffffffff80106fb8:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80106fbc:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80106fc0:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  if(addr >= proc->sz || addr+sizeof(uintp) > proc->sz)
ffffffff80106fc4:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106fcb:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106fcf:	48 8b 00             	mov    (%rax),%rax
ffffffff80106fd2:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
ffffffff80106fd6:	76 1b                	jbe    ffffffff80106ff3 <fetchuintp+0x3f>
ffffffff80106fd8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106fdc:	48 8d 50 08          	lea    0x8(%rax),%rdx
ffffffff80106fe0:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80106fe7:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80106feb:	48 8b 00             	mov    (%rax),%rax
ffffffff80106fee:	48 39 c2             	cmp    %rax,%rdx
ffffffff80106ff1:	76 07                	jbe    ffffffff80106ffa <fetchuintp+0x46>
    return -1;
ffffffff80106ff3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80106ff8:	eb 13                	jmp    ffffffff8010700d <fetchuintp+0x59>
  *ip = *(uintp*)(addr);
ffffffff80106ffa:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80106ffe:	48 8b 10             	mov    (%rax),%rdx
ffffffff80107001:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107005:	48 89 10             	mov    %rdx,(%rax)
  return 0;
ffffffff80107008:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff8010700d:	c9                   	leaveq 
ffffffff8010700e:	c3                   	retq   

ffffffff8010700f <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uintp addr, char **pp)
{
ffffffff8010700f:	55                   	push   %rbp
ffffffff80107010:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107013:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80107017:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff8010701b:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  char *s, *ep;

  if(addr >= proc->sz)
ffffffff8010701f:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80107026:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010702a:	48 8b 00             	mov    (%rax),%rax
ffffffff8010702d:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff80107031:	77 07                	ja     ffffffff8010703a <fetchstr+0x2b>
    return -1;
ffffffff80107033:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107038:	eb 5c                	jmp    ffffffff80107096 <fetchstr+0x87>
  *pp = (char*)addr;
ffffffff8010703a:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff8010703e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80107042:	48 89 10             	mov    %rdx,(%rax)
  ep = (char*)proc->sz;
ffffffff80107045:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff8010704c:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80107050:	48 8b 00             	mov    (%rax),%rax
ffffffff80107053:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  for(s = *pp; s < ep; s++)
ffffffff80107057:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010705b:	48 8b 00             	mov    (%rax),%rax
ffffffff8010705e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80107062:	eb 23                	jmp    ffffffff80107087 <fetchstr+0x78>
    if(*s == 0)
ffffffff80107064:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107068:	0f b6 00             	movzbl (%rax),%eax
ffffffff8010706b:	84 c0                	test   %al,%al
ffffffff8010706d:	75 13                	jne    ffffffff80107082 <fetchstr+0x73>
      return s - *pp;
ffffffff8010706f:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80107073:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80107077:	48 8b 00             	mov    (%rax),%rax
ffffffff8010707a:	48 29 c2             	sub    %rax,%rdx
ffffffff8010707d:	48 89 d0             	mov    %rdx,%rax
ffffffff80107080:	eb 14                	jmp    ffffffff80107096 <fetchstr+0x87>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
ffffffff80107082:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
ffffffff80107087:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010708b:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
ffffffff8010708f:	72 d3                	jb     ffffffff80107064 <fetchstr+0x55>
    if(*s == 0)
      return s - *pp;
  return -1;
ffffffff80107091:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff80107096:	c9                   	leaveq 
ffffffff80107097:	c3                   	retq   

ffffffff80107098 <fetcharg>:

#if X64
// arguments passed in registers on x64
static uintp
fetcharg(int n)
{
ffffffff80107098:	55                   	push   %rbp
ffffffff80107099:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010709c:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801070a0:	89 7d fc             	mov    %edi,-0x4(%rbp)
  switch (n) {
ffffffff801070a3:	83 7d fc 05          	cmpl   $0x5,-0x4(%rbp)
ffffffff801070a7:	0f 87 8b 00 00 00    	ja     ffffffff80107138 <fetcharg+0xa0>
ffffffff801070ad:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801070b0:	48 8b 04 c5 48 ae 10 	mov    -0x7fef51b8(,%rax,8),%rax
ffffffff801070b7:	80 
ffffffff801070b8:	ff e0                	jmpq   *%rax
  case 0: return proc->tf->rdi;
ffffffff801070ba:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801070c1:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801070c5:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff801070c9:	48 8b 40 30          	mov    0x30(%rax),%rax
ffffffff801070cd:	eb 6e                	jmp    ffffffff8010713d <fetcharg+0xa5>
  case 1: return proc->tf->rsi;
ffffffff801070cf:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801070d6:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801070da:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff801070de:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff801070e2:	eb 59                	jmp    ffffffff8010713d <fetcharg+0xa5>
  case 2: return proc->tf->rdx;
ffffffff801070e4:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801070eb:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801070ef:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff801070f3:	48 8b 40 18          	mov    0x18(%rax),%rax
ffffffff801070f7:	eb 44                	jmp    ffffffff8010713d <fetcharg+0xa5>
  case 3: return proc->tf->rcx;
ffffffff801070f9:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80107100:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80107104:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80107108:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff8010710c:	eb 2f                	jmp    ffffffff8010713d <fetcharg+0xa5>
  case 4: return proc->tf->r8;
ffffffff8010710e:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80107115:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80107119:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff8010711d:	48 8b 40 38          	mov    0x38(%rax),%rax
ffffffff80107121:	eb 1a                	jmp    ffffffff8010713d <fetcharg+0xa5>
  case 5: return proc->tf->r9;
ffffffff80107123:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff8010712a:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010712e:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff80107132:	48 8b 40 40          	mov    0x40(%rax),%rax
ffffffff80107136:	eb 05                	jmp    ffffffff8010713d <fetcharg+0xa5>
  }
  /* FIXME: should not reach here */
  return 0;
ffffffff80107138:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff8010713d:	c9                   	leaveq 
ffffffff8010713e:	c3                   	retq   

ffffffff8010713f <argint>:

int
argint(int n, int *ip)
{
ffffffff8010713f:	55                   	push   %rbp
ffffffff80107140:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107143:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80107147:	89 7d fc             	mov    %edi,-0x4(%rbp)
ffffffff8010714a:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  *ip = fetcharg(n);
ffffffff8010714e:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80107151:	89 c7                	mov    %eax,%edi
ffffffff80107153:	e8 40 ff ff ff       	callq  ffffffff80107098 <fetcharg>
ffffffff80107158:	89 c2                	mov    %eax,%edx
ffffffff8010715a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010715e:	89 10                	mov    %edx,(%rax)
  return 0;
ffffffff80107160:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80107165:	c9                   	leaveq 
ffffffff80107166:	c3                   	retq   

ffffffff80107167 <arguintp>:

int
arguintp(int n, uintp *ip)
{
ffffffff80107167:	55                   	push   %rbp
ffffffff80107168:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010716b:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff8010716f:	89 7d fc             	mov    %edi,-0x4(%rbp)
ffffffff80107172:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  *ip = fetcharg(n);
ffffffff80107176:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80107179:	89 c7                	mov    %eax,%edi
ffffffff8010717b:	e8 18 ff ff ff       	callq  ffffffff80107098 <fetcharg>
ffffffff80107180:	48 89 c2             	mov    %rax,%rdx
ffffffff80107183:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107187:	48 89 10             	mov    %rdx,(%rax)
  return 0;
ffffffff8010718a:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff8010718f:	c9                   	leaveq 
ffffffff80107190:	c3                   	retq   

ffffffff80107191 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
ffffffff80107191:	55                   	push   %rbp
ffffffff80107192:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107195:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80107199:	89 7d ec             	mov    %edi,-0x14(%rbp)
ffffffff8010719c:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff801071a0:	89 55 e8             	mov    %edx,-0x18(%rbp)
  uintp i;

  if(arguintp(n, &i) < 0)
ffffffff801071a3:	48 8d 55 f8          	lea    -0x8(%rbp),%rdx
ffffffff801071a7:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff801071aa:	48 89 d6             	mov    %rdx,%rsi
ffffffff801071ad:	89 c7                	mov    %eax,%edi
ffffffff801071af:	e8 b3 ff ff ff       	callq  ffffffff80107167 <arguintp>
ffffffff801071b4:	85 c0                	test   %eax,%eax
ffffffff801071b6:	79 07                	jns    ffffffff801071bf <argptr+0x2e>
    return -1;
ffffffff801071b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801071bd:	eb 51                	jmp    ffffffff80107210 <argptr+0x7f>
  if(i >= proc->sz || i+size > proc->sz)
ffffffff801071bf:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801071c6:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801071ca:	48 8b 10             	mov    (%rax),%rdx
ffffffff801071cd:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801071d1:	48 39 c2             	cmp    %rax,%rdx
ffffffff801071d4:	76 20                	jbe    ffffffff801071f6 <argptr+0x65>
ffffffff801071d6:	8b 45 e8             	mov    -0x18(%rbp),%eax
ffffffff801071d9:	48 63 d0             	movslq %eax,%rdx
ffffffff801071dc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801071e0:	48 01 c2             	add    %rax,%rdx
ffffffff801071e3:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801071ea:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801071ee:	48 8b 00             	mov    (%rax),%rax
ffffffff801071f1:	48 39 c2             	cmp    %rax,%rdx
ffffffff801071f4:	76 07                	jbe    ffffffff801071fd <argptr+0x6c>
    return -1;
ffffffff801071f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801071fb:	eb 13                	jmp    ffffffff80107210 <argptr+0x7f>
  *pp = (char*)i;
ffffffff801071fd:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107201:	48 89 c2             	mov    %rax,%rdx
ffffffff80107204:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80107208:	48 89 10             	mov    %rdx,(%rax)
  return 0;
ffffffff8010720b:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80107210:	c9                   	leaveq 
ffffffff80107211:	c3                   	retq   

ffffffff80107212 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
ffffffff80107212:	55                   	push   %rbp
ffffffff80107213:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107216:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010721a:	89 7d ec             	mov    %edi,-0x14(%rbp)
ffffffff8010721d:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  uintp addr;
  if(arguintp(n, &addr) < 0)
ffffffff80107221:	48 8d 55 f8          	lea    -0x8(%rbp),%rdx
ffffffff80107225:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80107228:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010722b:	89 c7                	mov    %eax,%edi
ffffffff8010722d:	e8 35 ff ff ff       	callq  ffffffff80107167 <arguintp>
ffffffff80107232:	85 c0                	test   %eax,%eax
ffffffff80107234:	79 07                	jns    ffffffff8010723d <argstr+0x2b>
    return -1;
ffffffff80107236:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010723b:	eb 13                	jmp    ffffffff80107250 <argstr+0x3e>
  return fetchstr(addr, pp);
ffffffff8010723d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107241:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff80107245:	48 89 d6             	mov    %rdx,%rsi
ffffffff80107248:	48 89 c7             	mov    %rax,%rdi
ffffffff8010724b:	e8 bf fd ff ff       	callq  ffffffff8010700f <fetchstr>
}
ffffffff80107250:	c9                   	leaveq 
ffffffff80107251:	c3                   	retq   

ffffffff80107252 <syscall>:
[SYS_chmod]   = sys_chmod,
};

void
syscall(void)
{
ffffffff80107252:	55                   	push   %rbp
ffffffff80107253:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107256:	53                   	push   %rbx
ffffffff80107257:	48 83 ec 18          	sub    $0x18,%rsp
  int num;

  num = proc->tf->eax;
ffffffff8010725b:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80107262:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80107266:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff8010726a:	48 8b 00             	mov    (%rax),%rax
ffffffff8010726d:	89 45 ec             	mov    %eax,-0x14(%rbp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
ffffffff80107270:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80107274:	7e 3f                	jle    ffffffff801072b5 <syscall+0x63>
ffffffff80107276:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80107279:	83 f8 16             	cmp    $0x16,%eax
ffffffff8010727c:	77 37                	ja     ffffffff801072b5 <syscall+0x63>
ffffffff8010727e:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80107281:	48 98                	cltq   
ffffffff80107283:	48 8b 04 c5 c0 c5 10 	mov    -0x7fef3a40(,%rax,8),%rax
ffffffff8010728a:	80 
ffffffff8010728b:	48 85 c0             	test   %rax,%rax
ffffffff8010728e:	74 25                	je     ffffffff801072b5 <syscall+0x63>
    proc->tf->eax = syscalls[num]();
ffffffff80107290:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80107297:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010729b:	48 8b 58 28          	mov    0x28(%rax),%rbx
ffffffff8010729f:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff801072a2:	48 98                	cltq   
ffffffff801072a4:	48 8b 04 c5 c0 c5 10 	mov    -0x7fef3a40(,%rax,8),%rax
ffffffff801072ab:	80 
ffffffff801072ac:	ff d0                	callq  *%rax
ffffffff801072ae:	48 98                	cltq   
ffffffff801072b0:	48 89 03             	mov    %rax,(%rbx)
ffffffff801072b3:	eb 51                	jmp    ffffffff80107306 <syscall+0xb4>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
ffffffff801072b5:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801072bc:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801072c0:	48 8d b0 d0 00 00 00 	lea    0xd0(%rax),%rsi
ffffffff801072c7:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801072ce:	64 48 8b 00          	mov    %fs:(%rax),%rax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
ffffffff801072d2:	8b 40 1c             	mov    0x1c(%rax),%eax
ffffffff801072d5:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff801072d8:	89 d1                	mov    %edx,%ecx
ffffffff801072da:	48 89 f2             	mov    %rsi,%rdx
ffffffff801072dd:	89 c6                	mov    %eax,%esi
ffffffff801072df:	48 c7 c7 78 ae 10 80 	mov    $0xffffffff8010ae78,%rdi
ffffffff801072e6:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801072eb:	e8 b2 92 ff ff       	callq  ffffffff801005a2 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
ffffffff801072f0:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801072f7:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801072fb:	48 8b 40 28          	mov    0x28(%rax),%rax
ffffffff801072ff:	48 c7 00 ff ff ff ff 	movq   $0xffffffffffffffff,(%rax)
  }
}
ffffffff80107306:	90                   	nop
ffffffff80107307:	48 83 c4 18          	add    $0x18,%rsp
ffffffff8010730b:	5b                   	pop    %rbx
ffffffff8010730c:	5d                   	pop    %rbp
ffffffff8010730d:	c3                   	retq   

ffffffff8010730e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
ffffffff8010730e:	55                   	push   %rbp
ffffffff8010730f:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107312:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80107316:	89 7d ec             	mov    %edi,-0x14(%rbp)
ffffffff80107319:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff8010731d:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
ffffffff80107321:	48 8d 55 f4          	lea    -0xc(%rbp),%rdx
ffffffff80107325:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80107328:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010732b:	89 c7                	mov    %eax,%edi
ffffffff8010732d:	e8 0d fe ff ff       	callq  ffffffff8010713f <argint>
ffffffff80107332:	85 c0                	test   %eax,%eax
ffffffff80107334:	79 07                	jns    ffffffff8010733d <argfd+0x2f>
    return -1;
ffffffff80107336:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010733b:	eb 62                	jmp    ffffffff8010739f <argfd+0x91>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
ffffffff8010733d:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80107340:	85 c0                	test   %eax,%eax
ffffffff80107342:	78 2d                	js     ffffffff80107371 <argfd+0x63>
ffffffff80107344:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80107347:	83 f8 0f             	cmp    $0xf,%eax
ffffffff8010734a:	7f 25                	jg     ffffffff80107371 <argfd+0x63>
ffffffff8010734c:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80107353:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80107357:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff8010735a:	48 63 d2             	movslq %edx,%rdx
ffffffff8010735d:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80107361:	48 8b 44 d0 08       	mov    0x8(%rax,%rdx,8),%rax
ffffffff80107366:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff8010736a:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff8010736f:	75 07                	jne    ffffffff80107378 <argfd+0x6a>
    return -1;
ffffffff80107371:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107376:	eb 27                	jmp    ffffffff8010739f <argfd+0x91>
  if(pfd)
ffffffff80107378:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
ffffffff8010737d:	74 09                	je     ffffffff80107388 <argfd+0x7a>
    *pfd = fd;
ffffffff8010737f:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff80107382:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80107386:	89 10                	mov    %edx,(%rax)
  if(pf)
ffffffff80107388:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
ffffffff8010738d:	74 0b                	je     ffffffff8010739a <argfd+0x8c>
    *pf = f;
ffffffff8010738f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80107393:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80107397:	48 89 10             	mov    %rdx,(%rax)
  return 0;
ffffffff8010739a:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff8010739f:	c9                   	leaveq 
ffffffff801073a0:	c3                   	retq   

ffffffff801073a1 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
ffffffff801073a1:	55                   	push   %rbp
ffffffff801073a2:	48 89 e5             	mov    %rsp,%rbp
ffffffff801073a5:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff801073a9:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
ffffffff801073ad:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801073b4:	eb 46                	jmp    ffffffff801073fc <fdalloc+0x5b>
    if(proc->ofile[fd] == 0){
ffffffff801073b6:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801073bd:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801073c1:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801073c4:	48 63 d2             	movslq %edx,%rdx
ffffffff801073c7:	48 83 c2 08          	add    $0x8,%rdx
ffffffff801073cb:	48 8b 44 d0 08       	mov    0x8(%rax,%rdx,8),%rax
ffffffff801073d0:	48 85 c0             	test   %rax,%rax
ffffffff801073d3:	75 23                	jne    ffffffff801073f8 <fdalloc+0x57>
      proc->ofile[fd] = f;
ffffffff801073d5:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801073dc:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801073e0:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801073e3:	48 63 d2             	movslq %edx,%rdx
ffffffff801073e6:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
ffffffff801073ea:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff801073ee:	48 89 54 c8 08       	mov    %rdx,0x8(%rax,%rcx,8)
      return fd;
ffffffff801073f3:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801073f6:	eb 0f                	jmp    ffffffff80107407 <fdalloc+0x66>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
ffffffff801073f8:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801073fc:	83 7d fc 0f          	cmpl   $0xf,-0x4(%rbp)
ffffffff80107400:	7e b4                	jle    ffffffff801073b6 <fdalloc+0x15>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
ffffffff80107402:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff80107407:	c9                   	leaveq 
ffffffff80107408:	c3                   	retq   

ffffffff80107409 <sys_dup>:

int
sys_dup(void)
{
ffffffff80107409:	55                   	push   %rbp
ffffffff8010740a:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010740d:	48 83 ec 10          	sub    $0x10,%rsp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
ffffffff80107411:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80107415:	48 89 c2             	mov    %rax,%rdx
ffffffff80107418:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff8010741d:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80107422:	e8 e7 fe ff ff       	callq  ffffffff8010730e <argfd>
ffffffff80107427:	85 c0                	test   %eax,%eax
ffffffff80107429:	79 07                	jns    ffffffff80107432 <sys_dup+0x29>
    return -1;
ffffffff8010742b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107430:	eb 2b                	jmp    ffffffff8010745d <sys_dup+0x54>
  if((fd=fdalloc(f)) < 0)
ffffffff80107432:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107436:	48 89 c7             	mov    %rax,%rdi
ffffffff80107439:	e8 63 ff ff ff       	callq  ffffffff801073a1 <fdalloc>
ffffffff8010743e:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff80107441:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80107445:	79 07                	jns    ffffffff8010744e <sys_dup+0x45>
    return -1;
ffffffff80107447:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010744c:	eb 0f                	jmp    ffffffff8010745d <sys_dup+0x54>
  filedup(f);
ffffffff8010744e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107452:	48 89 c7             	mov    %rax,%rdi
ffffffff80107455:	e8 34 aa ff ff       	callq  ffffffff80101e8e <filedup>
  return fd;
ffffffff8010745a:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
ffffffff8010745d:	c9                   	leaveq 
ffffffff8010745e:	c3                   	retq   

ffffffff8010745f <sys_read>:

int
sys_read(void)
{
ffffffff8010745f:	55                   	push   %rbp
ffffffff80107460:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107463:	48 83 ec 20          	sub    $0x20,%rsp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
ffffffff80107467:	48 8d 45 f8          	lea    -0x8(%rbp),%rax
ffffffff8010746b:	48 89 c2             	mov    %rax,%rdx
ffffffff8010746e:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80107473:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80107478:	e8 91 fe ff ff       	callq  ffffffff8010730e <argfd>
ffffffff8010747d:	85 c0                	test   %eax,%eax
ffffffff8010747f:	78 2d                	js     ffffffff801074ae <sys_read+0x4f>
ffffffff80107481:	48 8d 45 f4          	lea    -0xc(%rbp),%rax
ffffffff80107485:	48 89 c6             	mov    %rax,%rsi
ffffffff80107488:	bf 02 00 00 00       	mov    $0x2,%edi
ffffffff8010748d:	e8 ad fc ff ff       	callq  ffffffff8010713f <argint>
ffffffff80107492:	85 c0                	test   %eax,%eax
ffffffff80107494:	78 18                	js     ffffffff801074ae <sys_read+0x4f>
ffffffff80107496:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff80107499:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
ffffffff8010749d:	48 89 c6             	mov    %rax,%rsi
ffffffff801074a0:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff801074a5:	e8 e7 fc ff ff       	callq  ffffffff80107191 <argptr>
ffffffff801074aa:	85 c0                	test   %eax,%eax
ffffffff801074ac:	79 07                	jns    ffffffff801074b5 <sys_read+0x56>
    return -1;
ffffffff801074ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801074b3:	eb 16                	jmp    ffffffff801074cb <sys_read+0x6c>
  return fileread(f, p, n);
ffffffff801074b5:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff801074b8:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
ffffffff801074bc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801074c0:	48 89 ce             	mov    %rcx,%rsi
ffffffff801074c3:	48 89 c7             	mov    %rax,%rdi
ffffffff801074c6:	e8 66 ab ff ff       	callq  ffffffff80102031 <fileread>
}
ffffffff801074cb:	c9                   	leaveq 
ffffffff801074cc:	c3                   	retq   

ffffffff801074cd <sys_write>:

int
sys_write(void)
{
ffffffff801074cd:	55                   	push   %rbp
ffffffff801074ce:	48 89 e5             	mov    %rsp,%rbp
ffffffff801074d1:	48 83 ec 20          	sub    $0x20,%rsp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
ffffffff801074d5:	48 8d 45 f8          	lea    -0x8(%rbp),%rax
ffffffff801074d9:	48 89 c2             	mov    %rax,%rdx
ffffffff801074dc:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801074e1:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff801074e6:	e8 23 fe ff ff       	callq  ffffffff8010730e <argfd>
ffffffff801074eb:	85 c0                	test   %eax,%eax
ffffffff801074ed:	78 2d                	js     ffffffff8010751c <sys_write+0x4f>
ffffffff801074ef:	48 8d 45 f4          	lea    -0xc(%rbp),%rax
ffffffff801074f3:	48 89 c6             	mov    %rax,%rsi
ffffffff801074f6:	bf 02 00 00 00       	mov    $0x2,%edi
ffffffff801074fb:	e8 3f fc ff ff       	callq  ffffffff8010713f <argint>
ffffffff80107500:	85 c0                	test   %eax,%eax
ffffffff80107502:	78 18                	js     ffffffff8010751c <sys_write+0x4f>
ffffffff80107504:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff80107507:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
ffffffff8010750b:	48 89 c6             	mov    %rax,%rsi
ffffffff8010750e:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff80107513:	e8 79 fc ff ff       	callq  ffffffff80107191 <argptr>
ffffffff80107518:	85 c0                	test   %eax,%eax
ffffffff8010751a:	79 07                	jns    ffffffff80107523 <sys_write+0x56>
    return -1;
ffffffff8010751c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107521:	eb 16                	jmp    ffffffff80107539 <sys_write+0x6c>
  return filewrite(f, p, n);
ffffffff80107523:	8b 55 f4             	mov    -0xc(%rbp),%edx
ffffffff80107526:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
ffffffff8010752a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010752e:	48 89 ce             	mov    %rcx,%rsi
ffffffff80107531:	48 89 c7             	mov    %rax,%rdi
ffffffff80107534:	e8 c0 ab ff ff       	callq  ffffffff801020f9 <filewrite>
}
ffffffff80107539:	c9                   	leaveq 
ffffffff8010753a:	c3                   	retq   

ffffffff8010753b <sys_close>:

int
sys_close(void)
{
ffffffff8010753b:	55                   	push   %rbp
ffffffff8010753c:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010753f:	48 83 ec 10          	sub    $0x10,%rsp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
ffffffff80107543:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
ffffffff80107547:	48 8d 45 fc          	lea    -0x4(%rbp),%rax
ffffffff8010754b:	48 89 c6             	mov    %rax,%rsi
ffffffff8010754e:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80107553:	e8 b6 fd ff ff       	callq  ffffffff8010730e <argfd>
ffffffff80107558:	85 c0                	test   %eax,%eax
ffffffff8010755a:	79 07                	jns    ffffffff80107563 <sys_close+0x28>
    return -1;
ffffffff8010755c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107561:	eb 2f                	jmp    ffffffff80107592 <sys_close+0x57>
  proc->ofile[fd] = 0;
ffffffff80107563:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff8010756a:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010756e:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80107571:	48 63 d2             	movslq %edx,%rdx
ffffffff80107574:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80107578:	48 c7 44 d0 08 00 00 	movq   $0x0,0x8(%rax,%rdx,8)
ffffffff8010757f:	00 00 
  fileclose(f);
ffffffff80107581:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107585:	48 89 c7             	mov    %rax,%rdi
ffffffff80107588:	e8 53 a9 ff ff       	callq  ffffffff80101ee0 <fileclose>
  return 0;
ffffffff8010758d:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80107592:	c9                   	leaveq 
ffffffff80107593:	c3                   	retq   

ffffffff80107594 <sys_fstat>:

int
sys_fstat(void)
{
ffffffff80107594:	55                   	push   %rbp
ffffffff80107595:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107598:	48 83 ec 10          	sub    $0x10,%rsp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
ffffffff8010759c:	48 8d 45 f8          	lea    -0x8(%rbp),%rax
ffffffff801075a0:	48 89 c2             	mov    %rax,%rdx
ffffffff801075a3:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801075a8:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff801075ad:	e8 5c fd ff ff       	callq  ffffffff8010730e <argfd>
ffffffff801075b2:	85 c0                	test   %eax,%eax
ffffffff801075b4:	78 1a                	js     ffffffff801075d0 <sys_fstat+0x3c>
ffffffff801075b6:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff801075ba:	ba 1c 00 00 00       	mov    $0x1c,%edx
ffffffff801075bf:	48 89 c6             	mov    %rax,%rsi
ffffffff801075c2:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff801075c7:	e8 c5 fb ff ff       	callq  ffffffff80107191 <argptr>
ffffffff801075cc:	85 c0                	test   %eax,%eax
ffffffff801075ce:	79 07                	jns    ffffffff801075d7 <sys_fstat+0x43>
    return -1;
ffffffff801075d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801075d5:	eb 13                	jmp    ffffffff801075ea <sys_fstat+0x56>
  return filestat(f, st);
ffffffff801075d7:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
ffffffff801075db:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801075df:	48 89 d6             	mov    %rdx,%rsi
ffffffff801075e2:	48 89 c7             	mov    %rax,%rdi
ffffffff801075e5:	e8 e7 a9 ff ff       	callq  ffffffff80101fd1 <filestat>
}
ffffffff801075ea:	c9                   	leaveq 
ffffffff801075eb:	c3                   	retq   

ffffffff801075ec <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
ffffffff801075ec:	55                   	push   %rbp
ffffffff801075ed:	48 89 e5             	mov    %rsp,%rbp
ffffffff801075f0:	48 83 ec 30          	sub    $0x30,%rsp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
ffffffff801075f4:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
ffffffff801075f8:	48 89 c6             	mov    %rax,%rsi
ffffffff801075fb:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80107600:	e8 0d fc ff ff       	callq  ffffffff80107212 <argstr>
ffffffff80107605:	85 c0                	test   %eax,%eax
ffffffff80107607:	78 15                	js     ffffffff8010761e <sys_link+0x32>
ffffffff80107609:	48 8d 45 d8          	lea    -0x28(%rbp),%rax
ffffffff8010760d:	48 89 c6             	mov    %rax,%rsi
ffffffff80107610:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff80107615:	e8 f8 fb ff ff       	callq  ffffffff80107212 <argstr>
ffffffff8010761a:	85 c0                	test   %eax,%eax
ffffffff8010761c:	79 0a                	jns    ffffffff80107628 <sys_link+0x3c>
    return -1;
ffffffff8010761e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107623:	e9 74 01 00 00       	jmpq   ffffffff8010779c <sys_link+0x1b0>

  begin_op();
ffffffff80107628:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010762d:	e8 c8 cc ff ff       	callq  ffffffff801042fa <begin_op>
  if((ip = namei(old)) == 0){
ffffffff80107632:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80107636:	48 89 c7             	mov    %rax,%rdi
ffffffff80107639:	e8 32 bf ff ff       	callq  ffffffff80103570 <namei>
ffffffff8010763e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80107642:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80107647:	75 14                	jne    ffffffff8010765d <sys_link+0x71>
    end_op();
ffffffff80107649:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010764e:	e8 29 cd ff ff       	callq  ffffffff8010437c <end_op>
    return -1;
ffffffff80107653:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107658:	e9 3f 01 00 00       	jmpq   ffffffff8010779c <sys_link+0x1b0>
  }

  ilock(ip);
ffffffff8010765d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107661:	48 89 c7             	mov    %rax,%rdi
ffffffff80107664:	e8 db b1 ff ff       	callq  ffffffff80102844 <ilock>
  if(ip->type == T_DIR){
ffffffff80107669:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010766d:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff80107671:	66 83 f8 01          	cmp    $0x1,%ax
ffffffff80107675:	75 20                	jne    ffffffff80107697 <sys_link+0xab>
    iunlockput(ip);
ffffffff80107677:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010767b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010767e:	e8 b7 b4 ff ff       	callq  ffffffff80102b3a <iunlockput>
    end_op();
ffffffff80107683:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107688:	e8 ef cc ff ff       	callq  ffffffff8010437c <end_op>
    return -1;
ffffffff8010768d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107692:	e9 05 01 00 00       	jmpq   ffffffff8010779c <sys_link+0x1b0>
  }

  ip->nlink++;
ffffffff80107697:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010769b:	0f b7 40 16          	movzwl 0x16(%rax),%eax
ffffffff8010769f:	83 c0 01             	add    $0x1,%eax
ffffffff801076a2:	89 c2                	mov    %eax,%edx
ffffffff801076a4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801076a8:	66 89 50 16          	mov    %dx,0x16(%rax)
  iupdate(ip);
ffffffff801076ac:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801076b0:	48 89 c7             	mov    %rax,%rdi
ffffffff801076b3:	e8 80 af ff ff       	callq  ffffffff80102638 <iupdate>
  iunlock(ip);
ffffffff801076b8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801076bc:	48 89 c7             	mov    %rax,%rdi
ffffffff801076bf:	e8 1f b3 ff ff       	callq  ffffffff801029e3 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
ffffffff801076c4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801076c8:	48 8d 55 e0          	lea    -0x20(%rbp),%rdx
ffffffff801076cc:	48 89 d6             	mov    %rdx,%rsi
ffffffff801076cf:	48 89 c7             	mov    %rax,%rdi
ffffffff801076d2:	e8 bc be ff ff       	callq  ffffffff80103593 <nameiparent>
ffffffff801076d7:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff801076db:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff801076e0:	74 71                	je     ffffffff80107753 <sys_link+0x167>
    goto bad;
  ilock(dp);
ffffffff801076e2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801076e6:	48 89 c7             	mov    %rax,%rdi
ffffffff801076e9:	e8 56 b1 ff ff       	callq  ffffffff80102844 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
ffffffff801076ee:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801076f2:	8b 10                	mov    (%rax),%edx
ffffffff801076f4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801076f8:	8b 00                	mov    (%rax),%eax
ffffffff801076fa:	39 c2                	cmp    %eax,%edx
ffffffff801076fc:	75 1e                	jne    ffffffff8010771c <sys_link+0x130>
ffffffff801076fe:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107702:	8b 50 04             	mov    0x4(%rax),%edx
ffffffff80107705:	48 8d 4d e0          	lea    -0x20(%rbp),%rcx
ffffffff80107709:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010770d:	48 89 ce             	mov    %rcx,%rsi
ffffffff80107710:	48 89 c7             	mov    %rax,%rdi
ffffffff80107713:	e8 5f bb ff ff       	callq  ffffffff80103277 <dirlink>
ffffffff80107718:	85 c0                	test   %eax,%eax
ffffffff8010771a:	79 0e                	jns    ffffffff8010772a <sys_link+0x13e>
    iunlockput(dp);
ffffffff8010771c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107720:	48 89 c7             	mov    %rax,%rdi
ffffffff80107723:	e8 12 b4 ff ff       	callq  ffffffff80102b3a <iunlockput>
    goto bad;
ffffffff80107728:	eb 2a                	jmp    ffffffff80107754 <sys_link+0x168>
  }
  iunlockput(dp);
ffffffff8010772a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010772e:	48 89 c7             	mov    %rax,%rdi
ffffffff80107731:	e8 04 b4 ff ff       	callq  ffffffff80102b3a <iunlockput>
  iput(ip);
ffffffff80107736:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010773a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010773d:	e8 13 b3 ff ff       	callq  ffffffff80102a55 <iput>

  end_op();
ffffffff80107742:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107747:	e8 30 cc ff ff       	callq  ffffffff8010437c <end_op>

  return 0;
ffffffff8010774c:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107751:	eb 49                	jmp    ffffffff8010779c <sys_link+0x1b0>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
ffffffff80107753:	90                   	nop
  end_op();

  return 0;

bad:
  ilock(ip);
ffffffff80107754:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107758:	48 89 c7             	mov    %rax,%rdi
ffffffff8010775b:	e8 e4 b0 ff ff       	callq  ffffffff80102844 <ilock>
  ip->nlink--;
ffffffff80107760:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107764:	0f b7 40 16          	movzwl 0x16(%rax),%eax
ffffffff80107768:	83 e8 01             	sub    $0x1,%eax
ffffffff8010776b:	89 c2                	mov    %eax,%edx
ffffffff8010776d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107771:	66 89 50 16          	mov    %dx,0x16(%rax)
  iupdate(ip);
ffffffff80107775:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107779:	48 89 c7             	mov    %rax,%rdi
ffffffff8010777c:	e8 b7 ae ff ff       	callq  ffffffff80102638 <iupdate>
  iunlockput(ip);
ffffffff80107781:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107785:	48 89 c7             	mov    %rax,%rdi
ffffffff80107788:	e8 ad b3 ff ff       	callq  ffffffff80102b3a <iunlockput>
  end_op();
ffffffff8010778d:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107792:	e8 e5 cb ff ff       	callq  ffffffff8010437c <end_op>
  return -1;
ffffffff80107797:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff8010779c:	c9                   	leaveq 
ffffffff8010779d:	c3                   	retq   

ffffffff8010779e <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
ffffffff8010779e:	55                   	push   %rbp
ffffffff8010779f:	48 89 e5             	mov    %rsp,%rbp
ffffffff801077a2:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff801077a6:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
ffffffff801077aa:	c7 45 fc 20 00 00 00 	movl   $0x20,-0x4(%rbp)
ffffffff801077b1:	eb 42                	jmp    ffffffff801077f5 <isdirempty+0x57>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
ffffffff801077b3:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff801077b6:	48 8d 75 e0          	lea    -0x20(%rbp),%rsi
ffffffff801077ba:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801077be:	b9 10 00 00 00       	mov    $0x10,%ecx
ffffffff801077c3:	48 89 c7             	mov    %rax,%rdi
ffffffff801077c6:	e8 84 b6 ff ff       	callq  ffffffff80102e4f <readi>
ffffffff801077cb:	83 f8 10             	cmp    $0x10,%eax
ffffffff801077ce:	74 0c                	je     ffffffff801077dc <isdirempty+0x3e>
      panic("isdirempty: readi");
ffffffff801077d0:	48 c7 c7 94 ae 10 80 	mov    $0xffffffff8010ae94,%rdi
ffffffff801077d7:	e8 23 91 ff ff       	callq  ffffffff801008ff <panic>
    if(de.inum != 0)
ffffffff801077dc:	0f b7 45 e0          	movzwl -0x20(%rbp),%eax
ffffffff801077e0:	66 85 c0             	test   %ax,%ax
ffffffff801077e3:	74 07                	je     ffffffff801077ec <isdirempty+0x4e>
      return 0;
ffffffff801077e5:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801077ea:	eb 1c                	jmp    ffffffff80107808 <isdirempty+0x6a>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
ffffffff801077ec:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801077ef:	83 c0 10             	add    $0x10,%eax
ffffffff801077f2:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff801077f5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff801077f9:	8b 50 20             	mov    0x20(%rax),%edx
ffffffff801077fc:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801077ff:	39 c2                	cmp    %eax,%edx
ffffffff80107801:	77 b0                	ja     ffffffff801077b3 <isdirempty+0x15>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
ffffffff80107803:	b8 01 00 00 00       	mov    $0x1,%eax
}
ffffffff80107808:	c9                   	leaveq 
ffffffff80107809:	c3                   	retq   

ffffffff8010780a <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
ffffffff8010780a:	55                   	push   %rbp
ffffffff8010780b:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010780e:	48 83 ec 40          	sub    $0x40,%rsp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
ffffffff80107812:	48 8d 45 c8          	lea    -0x38(%rbp),%rax
ffffffff80107816:	48 89 c6             	mov    %rax,%rsi
ffffffff80107819:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff8010781e:	e8 ef f9 ff ff       	callq  ffffffff80107212 <argstr>
ffffffff80107823:	85 c0                	test   %eax,%eax
ffffffff80107825:	79 0a                	jns    ffffffff80107831 <sys_unlink+0x27>
    return -1;
ffffffff80107827:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010782c:	e9 cc 01 00 00       	jmpq   ffffffff801079fd <sys_unlink+0x1f3>

  begin_op();
ffffffff80107831:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107836:	e8 bf ca ff ff       	callq  ffffffff801042fa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
ffffffff8010783b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff8010783f:	48 8d 55 d0          	lea    -0x30(%rbp),%rdx
ffffffff80107843:	48 89 d6             	mov    %rdx,%rsi
ffffffff80107846:	48 89 c7             	mov    %rax,%rdi
ffffffff80107849:	e8 45 bd ff ff       	callq  ffffffff80103593 <nameiparent>
ffffffff8010784e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80107852:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80107857:	75 14                	jne    ffffffff8010786d <sys_unlink+0x63>
    end_op();
ffffffff80107859:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010785e:	e8 19 cb ff ff       	callq  ffffffff8010437c <end_op>
    return -1;
ffffffff80107863:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107868:	e9 90 01 00 00       	jmpq   ffffffff801079fd <sys_unlink+0x1f3>
  }

  ilock(dp);
ffffffff8010786d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107871:	48 89 c7             	mov    %rax,%rdi
ffffffff80107874:	e8 cb af ff ff       	callq  ffffffff80102844 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
ffffffff80107879:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
ffffffff8010787d:	48 c7 c6 a6 ae 10 80 	mov    $0xffffffff8010aea6,%rsi
ffffffff80107884:	48 89 c7             	mov    %rax,%rdi
ffffffff80107887:	e8 f0 b8 ff ff       	callq  ffffffff8010317c <namecmp>
ffffffff8010788c:	85 c0                	test   %eax,%eax
ffffffff8010788e:	0f 84 4e 01 00 00    	je     ffffffff801079e2 <sys_unlink+0x1d8>
ffffffff80107894:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
ffffffff80107898:	48 c7 c6 a8 ae 10 80 	mov    $0xffffffff8010aea8,%rsi
ffffffff8010789f:	48 89 c7             	mov    %rax,%rdi
ffffffff801078a2:	e8 d5 b8 ff ff       	callq  ffffffff8010317c <namecmp>
ffffffff801078a7:	85 c0                	test   %eax,%eax
ffffffff801078a9:	0f 84 33 01 00 00    	je     ffffffff801079e2 <sys_unlink+0x1d8>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
ffffffff801078af:	48 8d 55 c4          	lea    -0x3c(%rbp),%rdx
ffffffff801078b3:	48 8d 4d d0          	lea    -0x30(%rbp),%rcx
ffffffff801078b7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801078bb:	48 89 ce             	mov    %rcx,%rsi
ffffffff801078be:	48 89 c7             	mov    %rax,%rdi
ffffffff801078c1:	e8 e0 b8 ff ff       	callq  ffffffff801031a6 <dirlookup>
ffffffff801078c6:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff801078ca:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff801078cf:	0f 84 0c 01 00 00    	je     ffffffff801079e1 <sys_unlink+0x1d7>
    goto bad;
  ilock(ip);
ffffffff801078d5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801078d9:	48 89 c7             	mov    %rax,%rdi
ffffffff801078dc:	e8 63 af ff ff       	callq  ffffffff80102844 <ilock>

  if(ip->nlink < 1)
ffffffff801078e1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801078e5:	0f b7 40 16          	movzwl 0x16(%rax),%eax
ffffffff801078e9:	66 85 c0             	test   %ax,%ax
ffffffff801078ec:	7f 0c                	jg     ffffffff801078fa <sys_unlink+0xf0>
    panic("unlink: nlink < 1");
ffffffff801078ee:	48 c7 c7 ab ae 10 80 	mov    $0xffffffff8010aeab,%rdi
ffffffff801078f5:	e8 05 90 ff ff       	callq  ffffffff801008ff <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
ffffffff801078fa:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801078fe:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff80107902:	66 83 f8 01          	cmp    $0x1,%ax
ffffffff80107906:	75 21                	jne    ffffffff80107929 <sys_unlink+0x11f>
ffffffff80107908:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010790c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010790f:	e8 8a fe ff ff       	callq  ffffffff8010779e <isdirempty>
ffffffff80107914:	85 c0                	test   %eax,%eax
ffffffff80107916:	75 11                	jne    ffffffff80107929 <sys_unlink+0x11f>
    iunlockput(ip);
ffffffff80107918:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010791c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010791f:	e8 16 b2 ff ff       	callq  ffffffff80102b3a <iunlockput>
    goto bad;
ffffffff80107924:	e9 b9 00 00 00       	jmpq   ffffffff801079e2 <sys_unlink+0x1d8>
  }

  memset(&de, 0, sizeof(de));
ffffffff80107929:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
ffffffff8010792d:	ba 10 00 00 00       	mov    $0x10,%edx
ffffffff80107932:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80107937:	48 89 c7             	mov    %rax,%rdi
ffffffff8010793a:	e8 ce f2 ff ff       	callq  ffffffff80106c0d <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
ffffffff8010793f:	8b 55 c4             	mov    -0x3c(%rbp),%edx
ffffffff80107942:	48 8d 75 e0          	lea    -0x20(%rbp),%rsi
ffffffff80107946:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010794a:	b9 10 00 00 00       	mov    $0x10,%ecx
ffffffff8010794f:	48 89 c7             	mov    %rax,%rdi
ffffffff80107952:	e8 78 b6 ff ff       	callq  ffffffff80102fcf <writei>
ffffffff80107957:	83 f8 10             	cmp    $0x10,%eax
ffffffff8010795a:	74 0c                	je     ffffffff80107968 <sys_unlink+0x15e>
    panic("unlink: writei");
ffffffff8010795c:	48 c7 c7 bd ae 10 80 	mov    $0xffffffff8010aebd,%rdi
ffffffff80107963:	e8 97 8f ff ff       	callq  ffffffff801008ff <panic>
  if(ip->type == T_DIR){
ffffffff80107968:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010796c:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff80107970:	66 83 f8 01          	cmp    $0x1,%ax
ffffffff80107974:	75 21                	jne    ffffffff80107997 <sys_unlink+0x18d>
    dp->nlink--;
ffffffff80107976:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010797a:	0f b7 40 16          	movzwl 0x16(%rax),%eax
ffffffff8010797e:	83 e8 01             	sub    $0x1,%eax
ffffffff80107981:	89 c2                	mov    %eax,%edx
ffffffff80107983:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107987:	66 89 50 16          	mov    %dx,0x16(%rax)
    iupdate(dp);
ffffffff8010798b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010798f:	48 89 c7             	mov    %rax,%rdi
ffffffff80107992:	e8 a1 ac ff ff       	callq  ffffffff80102638 <iupdate>
  }
  iunlockput(dp);
ffffffff80107997:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010799b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010799e:	e8 97 b1 ff ff       	callq  ffffffff80102b3a <iunlockput>

  ip->nlink--;
ffffffff801079a3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801079a7:	0f b7 40 16          	movzwl 0x16(%rax),%eax
ffffffff801079ab:	83 e8 01             	sub    $0x1,%eax
ffffffff801079ae:	89 c2                	mov    %eax,%edx
ffffffff801079b0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801079b4:	66 89 50 16          	mov    %dx,0x16(%rax)
  iupdate(ip);
ffffffff801079b8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801079bc:	48 89 c7             	mov    %rax,%rdi
ffffffff801079bf:	e8 74 ac ff ff       	callq  ffffffff80102638 <iupdate>
  iunlockput(ip);
ffffffff801079c4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801079c8:	48 89 c7             	mov    %rax,%rdi
ffffffff801079cb:	e8 6a b1 ff ff       	callq  ffffffff80102b3a <iunlockput>

  end_op();
ffffffff801079d0:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801079d5:	e8 a2 c9 ff ff       	callq  ffffffff8010437c <end_op>

  return 0;
ffffffff801079da:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801079df:	eb 1c                	jmp    ffffffff801079fd <sys_unlink+0x1f3>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
ffffffff801079e1:	90                   	nop
  end_op();

  return 0;

bad:
  iunlockput(dp);
ffffffff801079e2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801079e6:	48 89 c7             	mov    %rax,%rdi
ffffffff801079e9:	e8 4c b1 ff ff       	callq  ffffffff80102b3a <iunlockput>
  end_op();
ffffffff801079ee:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801079f3:	e8 84 c9 ff ff       	callq  ffffffff8010437c <end_op>
  return -1;
ffffffff801079f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
ffffffff801079fd:	c9                   	leaveq 
ffffffff801079fe:	c3                   	retq   

ffffffff801079ff <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
ffffffff801079ff:	55                   	push   %rbp
ffffffff80107a00:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107a03:	48 83 ec 50          	sub    $0x50,%rsp
ffffffff80107a07:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
ffffffff80107a0b:	89 c8                	mov    %ecx,%eax
ffffffff80107a0d:	66 89 75 c4          	mov    %si,-0x3c(%rbp)
ffffffff80107a11:	66 89 55 c0          	mov    %dx,-0x40(%rbp)
ffffffff80107a15:	66 89 45 bc          	mov    %ax,-0x44(%rbp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
ffffffff80107a19:	48 8d 55 d0          	lea    -0x30(%rbp),%rdx
ffffffff80107a1d:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80107a21:	48 89 d6             	mov    %rdx,%rsi
ffffffff80107a24:	48 89 c7             	mov    %rax,%rdi
ffffffff80107a27:	e8 67 bb ff ff       	callq  ffffffff80103593 <nameiparent>
ffffffff80107a2c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80107a30:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80107a35:	75 0a                	jne    ffffffff80107a41 <create+0x42>
    return 0;
ffffffff80107a37:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107a3c:	e9 88 01 00 00       	jmpq   ffffffff80107bc9 <create+0x1ca>
  ilock(dp);
ffffffff80107a41:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107a45:	48 89 c7             	mov    %rax,%rdi
ffffffff80107a48:	e8 f7 ad ff ff       	callq  ffffffff80102844 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
ffffffff80107a4d:	48 8d 55 ec          	lea    -0x14(%rbp),%rdx
ffffffff80107a51:	48 8d 4d d0          	lea    -0x30(%rbp),%rcx
ffffffff80107a55:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107a59:	48 89 ce             	mov    %rcx,%rsi
ffffffff80107a5c:	48 89 c7             	mov    %rax,%rdi
ffffffff80107a5f:	e8 42 b7 ff ff       	callq  ffffffff801031a6 <dirlookup>
ffffffff80107a64:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80107a68:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80107a6d:	74 4c                	je     ffffffff80107abb <create+0xbc>
    iunlockput(dp);
ffffffff80107a6f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107a73:	48 89 c7             	mov    %rax,%rdi
ffffffff80107a76:	e8 bf b0 ff ff       	callq  ffffffff80102b3a <iunlockput>
    ilock(ip);
ffffffff80107a7b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107a7f:	48 89 c7             	mov    %rax,%rdi
ffffffff80107a82:	e8 bd ad ff ff       	callq  ffffffff80102844 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
ffffffff80107a87:	66 83 7d c4 02       	cmpw   $0x2,-0x3c(%rbp)
ffffffff80107a8c:	75 17                	jne    ffffffff80107aa5 <create+0xa6>
ffffffff80107a8e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107a92:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff80107a96:	66 83 f8 02          	cmp    $0x2,%ax
ffffffff80107a9a:	75 09                	jne    ffffffff80107aa5 <create+0xa6>
      return ip;
ffffffff80107a9c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107aa0:	e9 24 01 00 00       	jmpq   ffffffff80107bc9 <create+0x1ca>
    iunlockput(ip);
ffffffff80107aa5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107aa9:	48 89 c7             	mov    %rax,%rdi
ffffffff80107aac:	e8 89 b0 ff ff       	callq  ffffffff80102b3a <iunlockput>
    return 0;
ffffffff80107ab1:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107ab6:	e9 0e 01 00 00       	jmpq   ffffffff80107bc9 <create+0x1ca>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
ffffffff80107abb:	0f bf 55 c4          	movswl -0x3c(%rbp),%edx
ffffffff80107abf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107ac3:	8b 00                	mov    (%rax),%eax
ffffffff80107ac5:	89 d6                	mov    %edx,%esi
ffffffff80107ac7:	89 c7                	mov    %eax,%edi
ffffffff80107ac9:	e8 83 aa ff ff       	callq  ffffffff80102551 <ialloc>
ffffffff80107ace:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80107ad2:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80107ad7:	75 0c                	jne    ffffffff80107ae5 <create+0xe6>
    panic("create: ialloc");
ffffffff80107ad9:	48 c7 c7 cc ae 10 80 	mov    $0xffffffff8010aecc,%rdi
ffffffff80107ae0:	e8 1a 8e ff ff       	callq  ffffffff801008ff <panic>

  ilock(ip);
ffffffff80107ae5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107ae9:	48 89 c7             	mov    %rax,%rdi
ffffffff80107aec:	e8 53 ad ff ff       	callq  ffffffff80102844 <ilock>
  ip->major = major;
ffffffff80107af1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107af5:	0f b7 55 c0          	movzwl -0x40(%rbp),%edx
ffffffff80107af9:	66 89 50 12          	mov    %dx,0x12(%rax)
  ip->minor = minor;
ffffffff80107afd:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107b01:	0f b7 55 bc          	movzwl -0x44(%rbp),%edx
ffffffff80107b05:	66 89 50 14          	mov    %dx,0x14(%rax)
  ip->nlink = 1;
ffffffff80107b09:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107b0d:	66 c7 40 16 01 00    	movw   $0x1,0x16(%rax)
  iupdate(ip);
ffffffff80107b13:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107b17:	48 89 c7             	mov    %rax,%rdi
ffffffff80107b1a:	e8 19 ab ff ff       	callq  ffffffff80102638 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
ffffffff80107b1f:	66 83 7d c4 01       	cmpw   $0x1,-0x3c(%rbp)
ffffffff80107b24:	75 69                	jne    ffffffff80107b8f <create+0x190>
    dp->nlink++;  // for ".."
ffffffff80107b26:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107b2a:	0f b7 40 16          	movzwl 0x16(%rax),%eax
ffffffff80107b2e:	83 c0 01             	add    $0x1,%eax
ffffffff80107b31:	89 c2                	mov    %eax,%edx
ffffffff80107b33:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107b37:	66 89 50 16          	mov    %dx,0x16(%rax)
    iupdate(dp);
ffffffff80107b3b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107b3f:	48 89 c7             	mov    %rax,%rdi
ffffffff80107b42:	e8 f1 aa ff ff       	callq  ffffffff80102638 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
ffffffff80107b47:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107b4b:	8b 50 04             	mov    0x4(%rax),%edx
ffffffff80107b4e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107b52:	48 c7 c6 a6 ae 10 80 	mov    $0xffffffff8010aea6,%rsi
ffffffff80107b59:	48 89 c7             	mov    %rax,%rdi
ffffffff80107b5c:	e8 16 b7 ff ff       	callq  ffffffff80103277 <dirlink>
ffffffff80107b61:	85 c0                	test   %eax,%eax
ffffffff80107b63:	78 1e                	js     ffffffff80107b83 <create+0x184>
ffffffff80107b65:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107b69:	8b 50 04             	mov    0x4(%rax),%edx
ffffffff80107b6c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107b70:	48 c7 c6 a8 ae 10 80 	mov    $0xffffffff8010aea8,%rsi
ffffffff80107b77:	48 89 c7             	mov    %rax,%rdi
ffffffff80107b7a:	e8 f8 b6 ff ff       	callq  ffffffff80103277 <dirlink>
ffffffff80107b7f:	85 c0                	test   %eax,%eax
ffffffff80107b81:	79 0c                	jns    ffffffff80107b8f <create+0x190>
      panic("create dots");
ffffffff80107b83:	48 c7 c7 db ae 10 80 	mov    $0xffffffff8010aedb,%rdi
ffffffff80107b8a:	e8 70 8d ff ff       	callq  ffffffff801008ff <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
ffffffff80107b8f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107b93:	8b 50 04             	mov    0x4(%rax),%edx
ffffffff80107b96:	48 8d 4d d0          	lea    -0x30(%rbp),%rcx
ffffffff80107b9a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107b9e:	48 89 ce             	mov    %rcx,%rsi
ffffffff80107ba1:	48 89 c7             	mov    %rax,%rdi
ffffffff80107ba4:	e8 ce b6 ff ff       	callq  ffffffff80103277 <dirlink>
ffffffff80107ba9:	85 c0                	test   %eax,%eax
ffffffff80107bab:	79 0c                	jns    ffffffff80107bb9 <create+0x1ba>
    panic("create: dirlink");
ffffffff80107bad:	48 c7 c7 e7 ae 10 80 	mov    $0xffffffff8010aee7,%rdi
ffffffff80107bb4:	e8 46 8d ff ff       	callq  ffffffff801008ff <panic>

  iunlockput(dp);
ffffffff80107bb9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107bbd:	48 89 c7             	mov    %rax,%rdi
ffffffff80107bc0:	e8 75 af ff ff       	callq  ffffffff80102b3a <iunlockput>

  return ip;
ffffffff80107bc5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
ffffffff80107bc9:	c9                   	leaveq 
ffffffff80107bca:	c3                   	retq   

ffffffff80107bcb <sys_open>:

int
sys_open(void)
{
ffffffff80107bcb:	55                   	push   %rbp
ffffffff80107bcc:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107bcf:	48 83 ec 30          	sub    $0x30,%rsp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
ffffffff80107bd3:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
ffffffff80107bd7:	48 89 c6             	mov    %rax,%rsi
ffffffff80107bda:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80107bdf:	e8 2e f6 ff ff       	callq  ffffffff80107212 <argstr>
ffffffff80107be4:	85 c0                	test   %eax,%eax
ffffffff80107be6:	78 15                	js     ffffffff80107bfd <sys_open+0x32>
ffffffff80107be8:	48 8d 45 dc          	lea    -0x24(%rbp),%rax
ffffffff80107bec:	48 89 c6             	mov    %rax,%rsi
ffffffff80107bef:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff80107bf4:	e8 46 f5 ff ff       	callq  ffffffff8010713f <argint>
ffffffff80107bf9:	85 c0                	test   %eax,%eax
ffffffff80107bfb:	79 0a                	jns    ffffffff80107c07 <sys_open+0x3c>
    return -1;
ffffffff80107bfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107c02:	e9 8c 01 00 00       	jmpq   ffffffff80107d93 <sys_open+0x1c8>

  begin_op();
ffffffff80107c07:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107c0c:	e8 e9 c6 ff ff       	callq  ffffffff801042fa <begin_op>

  if(omode & O_CREATE){
ffffffff80107c11:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80107c14:	25 00 02 00 00       	and    $0x200,%eax
ffffffff80107c19:	85 c0                	test   %eax,%eax
ffffffff80107c1b:	74 3e                	je     ffffffff80107c5b <sys_open+0x90>
    ip = create(path, T_FILE, 0, 0);
ffffffff80107c1d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80107c21:	b9 00 00 00 00       	mov    $0x0,%ecx
ffffffff80107c26:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff80107c2b:	be 02 00 00 00       	mov    $0x2,%esi
ffffffff80107c30:	48 89 c7             	mov    %rax,%rdi
ffffffff80107c33:	e8 c7 fd ff ff       	callq  ffffffff801079ff <create>
ffffffff80107c38:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
    if(ip == 0){
ffffffff80107c3c:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80107c41:	0f 85 80 00 00 00    	jne    ffffffff80107cc7 <sys_open+0xfc>
      end_op();
ffffffff80107c47:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107c4c:	e8 2b c7 ff ff       	callq  ffffffff8010437c <end_op>
      return -1;
ffffffff80107c51:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107c56:	e9 38 01 00 00       	jmpq   ffffffff80107d93 <sys_open+0x1c8>
    }
  } else {
    if((ip = namei(path)) == 0){
ffffffff80107c5b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80107c5f:	48 89 c7             	mov    %rax,%rdi
ffffffff80107c62:	e8 09 b9 ff ff       	callq  ffffffff80103570 <namei>
ffffffff80107c67:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80107c6b:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80107c70:	75 14                	jne    ffffffff80107c86 <sys_open+0xbb>
      end_op();
ffffffff80107c72:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107c77:	e8 00 c7 ff ff       	callq  ffffffff8010437c <end_op>
      return -1;
ffffffff80107c7c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107c81:	e9 0d 01 00 00       	jmpq   ffffffff80107d93 <sys_open+0x1c8>
    }
    ilock(ip);
ffffffff80107c86:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107c8a:	48 89 c7             	mov    %rax,%rdi
ffffffff80107c8d:	e8 b2 ab ff ff       	callq  ffffffff80102844 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
ffffffff80107c92:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107c96:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff80107c9a:	66 83 f8 01          	cmp    $0x1,%ax
ffffffff80107c9e:	75 27                	jne    ffffffff80107cc7 <sys_open+0xfc>
ffffffff80107ca0:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80107ca3:	85 c0                	test   %eax,%eax
ffffffff80107ca5:	74 20                	je     ffffffff80107cc7 <sys_open+0xfc>
      iunlockput(ip);
ffffffff80107ca7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107cab:	48 89 c7             	mov    %rax,%rdi
ffffffff80107cae:	e8 87 ae ff ff       	callq  ffffffff80102b3a <iunlockput>
      end_op();
ffffffff80107cb3:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107cb8:	e8 bf c6 ff ff       	callq  ffffffff8010437c <end_op>
      return -1;
ffffffff80107cbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107cc2:	e9 cc 00 00 00       	jmpq   ffffffff80107d93 <sys_open+0x1c8>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
ffffffff80107cc7:	e8 57 a1 ff ff       	callq  ffffffff80101e23 <filealloc>
ffffffff80107ccc:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80107cd0:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80107cd5:	74 15                	je     ffffffff80107cec <sys_open+0x121>
ffffffff80107cd7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107cdb:	48 89 c7             	mov    %rax,%rdi
ffffffff80107cde:	e8 be f6 ff ff       	callq  ffffffff801073a1 <fdalloc>
ffffffff80107ce3:	89 45 ec             	mov    %eax,-0x14(%rbp)
ffffffff80107ce6:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
ffffffff80107cea:	79 30                	jns    ffffffff80107d1c <sys_open+0x151>
    if(f)
ffffffff80107cec:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80107cf1:	74 0c                	je     ffffffff80107cff <sys_open+0x134>
      fileclose(f);
ffffffff80107cf3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107cf7:	48 89 c7             	mov    %rax,%rdi
ffffffff80107cfa:	e8 e1 a1 ff ff       	callq  ffffffff80101ee0 <fileclose>
    iunlockput(ip);
ffffffff80107cff:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107d03:	48 89 c7             	mov    %rax,%rdi
ffffffff80107d06:	e8 2f ae ff ff       	callq  ffffffff80102b3a <iunlockput>
    end_op();
ffffffff80107d0b:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107d10:	e8 67 c6 ff ff       	callq  ffffffff8010437c <end_op>
    return -1;
ffffffff80107d15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107d1a:	eb 77                	jmp    ffffffff80107d93 <sys_open+0x1c8>
  }
  iunlock(ip);
ffffffff80107d1c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107d20:	48 89 c7             	mov    %rax,%rdi
ffffffff80107d23:	e8 bb ac ff ff       	callq  ffffffff801029e3 <iunlock>
  end_op();
ffffffff80107d28:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107d2d:	e8 4a c6 ff ff       	callq  ffffffff8010437c <end_op>

  f->type = FD_INODE;
ffffffff80107d32:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107d36:	c7 00 02 00 00 00    	movl   $0x2,(%rax)
  f->ip = ip;
ffffffff80107d3c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107d40:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80107d44:	48 89 50 18          	mov    %rdx,0x18(%rax)
  f->off = 0;
ffffffff80107d48:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107d4c:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%rax)
  f->readable = !(omode & O_WRONLY);
ffffffff80107d53:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80107d56:	83 e0 01             	and    $0x1,%eax
ffffffff80107d59:	85 c0                	test   %eax,%eax
ffffffff80107d5b:	0f 94 c0             	sete   %al
ffffffff80107d5e:	89 c2                	mov    %eax,%edx
ffffffff80107d60:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107d64:	88 50 08             	mov    %dl,0x8(%rax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
ffffffff80107d67:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80107d6a:	83 e0 01             	and    $0x1,%eax
ffffffff80107d6d:	85 c0                	test   %eax,%eax
ffffffff80107d6f:	75 0a                	jne    ffffffff80107d7b <sys_open+0x1b0>
ffffffff80107d71:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff80107d74:	83 e0 02             	and    $0x2,%eax
ffffffff80107d77:	85 c0                	test   %eax,%eax
ffffffff80107d79:	74 07                	je     ffffffff80107d82 <sys_open+0x1b7>
ffffffff80107d7b:	b8 01 00 00 00       	mov    $0x1,%eax
ffffffff80107d80:	eb 05                	jmp    ffffffff80107d87 <sys_open+0x1bc>
ffffffff80107d82:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107d87:	89 c2                	mov    %eax,%edx
ffffffff80107d89:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107d8d:	88 50 09             	mov    %dl,0x9(%rax)
  return fd;
ffffffff80107d90:	8b 45 ec             	mov    -0x14(%rbp),%eax
}
ffffffff80107d93:	c9                   	leaveq 
ffffffff80107d94:	c3                   	retq   

ffffffff80107d95 <sys_mkdir>:

int
sys_mkdir(void)
{
ffffffff80107d95:	55                   	push   %rbp
ffffffff80107d96:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107d99:	48 83 ec 10          	sub    $0x10,%rsp
  char *path;
  struct inode *ip;

  begin_op();
ffffffff80107d9d:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107da2:	e8 53 c5 ff ff       	callq  ffffffff801042fa <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
ffffffff80107da7:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80107dab:	48 89 c6             	mov    %rax,%rsi
ffffffff80107dae:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80107db3:	e8 5a f4 ff ff       	callq  ffffffff80107212 <argstr>
ffffffff80107db8:	85 c0                	test   %eax,%eax
ffffffff80107dba:	78 26                	js     ffffffff80107de2 <sys_mkdir+0x4d>
ffffffff80107dbc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107dc0:	b9 00 00 00 00       	mov    $0x0,%ecx
ffffffff80107dc5:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff80107dca:	be 01 00 00 00       	mov    $0x1,%esi
ffffffff80107dcf:	48 89 c7             	mov    %rax,%rdi
ffffffff80107dd2:	e8 28 fc ff ff       	callq  ffffffff801079ff <create>
ffffffff80107dd7:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80107ddb:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80107de0:	75 11                	jne    ffffffff80107df3 <sys_mkdir+0x5e>
    end_op();
ffffffff80107de2:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107de7:	e8 90 c5 ff ff       	callq  ffffffff8010437c <end_op>
    return -1;
ffffffff80107dec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107df1:	eb 1b                	jmp    ffffffff80107e0e <sys_mkdir+0x79>
  }
  iunlockput(ip);
ffffffff80107df3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107df7:	48 89 c7             	mov    %rax,%rdi
ffffffff80107dfa:	e8 3b ad ff ff       	callq  ffffffff80102b3a <iunlockput>
  end_op();
ffffffff80107dff:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107e04:	e8 73 c5 ff ff       	callq  ffffffff8010437c <end_op>
  return 0;
ffffffff80107e09:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80107e0e:	c9                   	leaveq 
ffffffff80107e0f:	c3                   	retq   

ffffffff80107e10 <sys_mknod>:

int
sys_mknod(void)
{
ffffffff80107e10:	55                   	push   %rbp
ffffffff80107e11:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107e14:	48 83 ec 20          	sub    $0x20,%rsp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
ffffffff80107e18:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107e1d:	e8 d8 c4 ff ff       	callq  ffffffff801042fa <begin_op>
  if((len=argstr(0, &path)) < 0 ||
ffffffff80107e22:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
ffffffff80107e26:	48 89 c6             	mov    %rax,%rsi
ffffffff80107e29:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80107e2e:	e8 df f3 ff ff       	callq  ffffffff80107212 <argstr>
ffffffff80107e33:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff80107e36:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80107e3a:	78 52                	js     ffffffff80107e8e <sys_mknod+0x7e>
     argint(1, &major) < 0 ||
ffffffff80107e3c:	48 8d 45 e4          	lea    -0x1c(%rbp),%rax
ffffffff80107e40:	48 89 c6             	mov    %rax,%rsi
ffffffff80107e43:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff80107e48:	e8 f2 f2 ff ff       	callq  ffffffff8010713f <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
ffffffff80107e4d:	85 c0                	test   %eax,%eax
ffffffff80107e4f:	78 3d                	js     ffffffff80107e8e <sys_mknod+0x7e>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
ffffffff80107e51:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
ffffffff80107e55:	48 89 c6             	mov    %rax,%rsi
ffffffff80107e58:	bf 02 00 00 00       	mov    $0x2,%edi
ffffffff80107e5d:	e8 dd f2 ff ff       	callq  ffffffff8010713f <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
ffffffff80107e62:	85 c0                	test   %eax,%eax
ffffffff80107e64:	78 28                	js     ffffffff80107e8e <sys_mknod+0x7e>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
ffffffff80107e66:	8b 45 e0             	mov    -0x20(%rbp),%eax
ffffffff80107e69:	0f bf c8             	movswl %ax,%ecx
ffffffff80107e6c:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80107e6f:	0f bf d0             	movswl %ax,%edx
ffffffff80107e72:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
ffffffff80107e76:	be 03 00 00 00       	mov    $0x3,%esi
ffffffff80107e7b:	48 89 c7             	mov    %rax,%rdi
ffffffff80107e7e:	e8 7c fb ff ff       	callq  ffffffff801079ff <create>
ffffffff80107e83:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
ffffffff80107e87:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80107e8c:	75 11                	jne    ffffffff80107e9f <sys_mknod+0x8f>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
ffffffff80107e8e:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107e93:	e8 e4 c4 ff ff       	callq  ffffffff8010437c <end_op>
    return -1;
ffffffff80107e98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107e9d:	eb 1b                	jmp    ffffffff80107eba <sys_mknod+0xaa>
  }
  iunlockput(ip);
ffffffff80107e9f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107ea3:	48 89 c7             	mov    %rax,%rdi
ffffffff80107ea6:	e8 8f ac ff ff       	callq  ffffffff80102b3a <iunlockput>
  end_op();
ffffffff80107eab:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107eb0:	e8 c7 c4 ff ff       	callq  ffffffff8010437c <end_op>
  return 0;
ffffffff80107eb5:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80107eba:	c9                   	leaveq 
ffffffff80107ebb:	c3                   	retq   

ffffffff80107ebc <sys_chdir>:

int
sys_chdir(void)
{
ffffffff80107ebc:	55                   	push   %rbp
ffffffff80107ebd:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107ec0:	48 83 ec 10          	sub    $0x10,%rsp
  char *path;
  struct inode *ip;

  begin_op();
ffffffff80107ec4:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107ec9:	e8 2c c4 ff ff       	callq  ffffffff801042fa <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
ffffffff80107ece:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80107ed2:	48 89 c6             	mov    %rax,%rsi
ffffffff80107ed5:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80107eda:	e8 33 f3 ff ff       	callq  ffffffff80107212 <argstr>
ffffffff80107edf:	85 c0                	test   %eax,%eax
ffffffff80107ee1:	78 17                	js     ffffffff80107efa <sys_chdir+0x3e>
ffffffff80107ee3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80107ee7:	48 89 c7             	mov    %rax,%rdi
ffffffff80107eea:	e8 81 b6 ff ff       	callq  ffffffff80103570 <namei>
ffffffff80107eef:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80107ef3:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80107ef8:	75 14                	jne    ffffffff80107f0e <sys_chdir+0x52>
    end_op();
ffffffff80107efa:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107eff:	e8 78 c4 ff ff       	callq  ffffffff8010437c <end_op>
    return -1;
ffffffff80107f04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107f09:	e9 82 00 00 00       	jmpq   ffffffff80107f90 <sys_chdir+0xd4>
  }
  ilock(ip);
ffffffff80107f0e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107f12:	48 89 c7             	mov    %rax,%rdi
ffffffff80107f15:	e8 2a a9 ff ff       	callq  ffffffff80102844 <ilock>
  if(ip->type != T_DIR){
ffffffff80107f1a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107f1e:	0f b7 40 10          	movzwl 0x10(%rax),%eax
ffffffff80107f22:	66 83 f8 01          	cmp    $0x1,%ax
ffffffff80107f26:	74 1d                	je     ffffffff80107f45 <sys_chdir+0x89>
    iunlockput(ip);
ffffffff80107f28:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107f2c:	48 89 c7             	mov    %rax,%rdi
ffffffff80107f2f:	e8 06 ac ff ff       	callq  ffffffff80102b3a <iunlockput>
    end_op();
ffffffff80107f34:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107f39:	e8 3e c4 ff ff       	callq  ffffffff8010437c <end_op>
    return -1;
ffffffff80107f3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107f43:	eb 4b                	jmp    ffffffff80107f90 <sys_chdir+0xd4>
  }
  iunlock(ip);
ffffffff80107f45:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80107f49:	48 89 c7             	mov    %rax,%rdi
ffffffff80107f4c:	e8 92 aa ff ff       	callq  ffffffff801029e3 <iunlock>
  iput(proc->cwd);
ffffffff80107f51:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80107f58:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80107f5c:	48 8b 80 c8 00 00 00 	mov    0xc8(%rax),%rax
ffffffff80107f63:	48 89 c7             	mov    %rax,%rdi
ffffffff80107f66:	e8 ea aa ff ff       	callq  ffffffff80102a55 <iput>
  end_op();
ffffffff80107f6b:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80107f70:	e8 07 c4 ff ff       	callq  ffffffff8010437c <end_op>
  proc->cwd = ip;
ffffffff80107f75:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80107f7c:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80107f80:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80107f84:	48 89 90 c8 00 00 00 	mov    %rdx,0xc8(%rax)
  return 0;
ffffffff80107f8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80107f90:	c9                   	leaveq 
ffffffff80107f91:	c3                   	retq   

ffffffff80107f92 <sys_exec>:

int
sys_exec(void)
{
ffffffff80107f92:	55                   	push   %rbp
ffffffff80107f93:	48 89 e5             	mov    %rsp,%rbp
ffffffff80107f96:	48 81 ec 20 01 00 00 	sub    $0x120,%rsp
  char *path, *argv[MAXARG];
  int i;
  uintp uargv, uarg;

  if(argstr(0, &path) < 0 || arguintp(1, &uargv) < 0){
ffffffff80107f9d:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80107fa1:	48 89 c6             	mov    %rax,%rsi
ffffffff80107fa4:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80107fa9:	e8 64 f2 ff ff       	callq  ffffffff80107212 <argstr>
ffffffff80107fae:	85 c0                	test   %eax,%eax
ffffffff80107fb0:	78 18                	js     ffffffff80107fca <sys_exec+0x38>
ffffffff80107fb2:	48 8d 85 e8 fe ff ff 	lea    -0x118(%rbp),%rax
ffffffff80107fb9:	48 89 c6             	mov    %rax,%rsi
ffffffff80107fbc:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff80107fc1:	e8 a1 f1 ff ff       	callq  ffffffff80107167 <arguintp>
ffffffff80107fc6:	85 c0                	test   %eax,%eax
ffffffff80107fc8:	79 0a                	jns    ffffffff80107fd4 <sys_exec+0x42>
    return -1;
ffffffff80107fca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80107fcf:	e9 d6 00 00 00       	jmpq   ffffffff801080aa <sys_exec+0x118>
  }
  memset(argv, 0, sizeof(argv));
ffffffff80107fd4:	48 8d 85 f0 fe ff ff 	lea    -0x110(%rbp),%rax
ffffffff80107fdb:	ba 00 01 00 00       	mov    $0x100,%edx
ffffffff80107fe0:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80107fe5:	48 89 c7             	mov    %rax,%rdi
ffffffff80107fe8:	e8 20 ec ff ff       	callq  ffffffff80106c0d <memset>
  for(i=0;; i++){
ffffffff80107fed:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
    if(i >= NELEM(argv))
ffffffff80107ff4:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80107ff7:	83 f8 1f             	cmp    $0x1f,%eax
ffffffff80107ffa:	76 0a                	jbe    ffffffff80108006 <sys_exec+0x74>
      return -1;
ffffffff80107ffc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80108001:	e9 a4 00 00 00       	jmpq   ffffffff801080aa <sys_exec+0x118>
    if(fetchuintp(uargv+sizeof(uintp)*i, &uarg) < 0)
ffffffff80108006:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80108009:	48 98                	cltq   
ffffffff8010800b:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80108012:	00 
ffffffff80108013:	48 8b 85 e8 fe ff ff 	mov    -0x118(%rbp),%rax
ffffffff8010801a:	48 01 c2             	add    %rax,%rdx
ffffffff8010801d:	48 8d 85 e0 fe ff ff 	lea    -0x120(%rbp),%rax
ffffffff80108024:	48 89 c6             	mov    %rax,%rsi
ffffffff80108027:	48 89 d7             	mov    %rdx,%rdi
ffffffff8010802a:	e8 85 ef ff ff       	callq  ffffffff80106fb4 <fetchuintp>
ffffffff8010802f:	85 c0                	test   %eax,%eax
ffffffff80108031:	79 07                	jns    ffffffff8010803a <sys_exec+0xa8>
      return -1;
ffffffff80108033:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80108038:	eb 70                	jmp    ffffffff801080aa <sys_exec+0x118>
    if(uarg == 0){
ffffffff8010803a:	48 8b 85 e0 fe ff ff 	mov    -0x120(%rbp),%rax
ffffffff80108041:	48 85 c0             	test   %rax,%rax
ffffffff80108044:	75 2a                	jne    ffffffff80108070 <sys_exec+0xde>
      argv[i] = 0;
ffffffff80108046:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80108049:	48 98                	cltq   
ffffffff8010804b:	48 c7 84 c5 f0 fe ff 	movq   $0x0,-0x110(%rbp,%rax,8)
ffffffff80108052:	ff 00 00 00 00 
      break;
ffffffff80108057:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
ffffffff80108058:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010805c:	48 8d 95 f0 fe ff ff 	lea    -0x110(%rbp),%rdx
ffffffff80108063:	48 89 d6             	mov    %rdx,%rsi
ffffffff80108066:	48 89 c7             	mov    %rax,%rdi
ffffffff80108069:	e8 72 98 ff ff       	callq  ffffffff801018e0 <exec>
ffffffff8010806e:	eb 3a                	jmp    ffffffff801080aa <sys_exec+0x118>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
ffffffff80108070:	48 8d 85 f0 fe ff ff 	lea    -0x110(%rbp),%rax
ffffffff80108077:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff8010807a:	48 63 d2             	movslq %edx,%rdx
ffffffff8010807d:	48 c1 e2 03          	shl    $0x3,%rdx
ffffffff80108081:	48 01 c2             	add    %rax,%rdx
ffffffff80108084:	48 8b 85 e0 fe ff ff 	mov    -0x120(%rbp),%rax
ffffffff8010808b:	48 89 d6             	mov    %rdx,%rsi
ffffffff8010808e:	48 89 c7             	mov    %rax,%rdi
ffffffff80108091:	e8 79 ef ff ff       	callq  ffffffff8010700f <fetchstr>
ffffffff80108096:	85 c0                	test   %eax,%eax
ffffffff80108098:	79 07                	jns    ffffffff801080a1 <sys_exec+0x10f>
      return -1;
ffffffff8010809a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010809f:	eb 09                	jmp    ffffffff801080aa <sys_exec+0x118>

  if(argstr(0, &path) < 0 || arguintp(1, &uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
ffffffff801080a1:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
ffffffff801080a5:	e9 4a ff ff ff       	jmpq   ffffffff80107ff4 <sys_exec+0x62>
  return exec(path, argv);
}
ffffffff801080aa:	c9                   	leaveq 
ffffffff801080ab:	c3                   	retq   

ffffffff801080ac <sys_pipe>:

int
sys_pipe(void)
{
ffffffff801080ac:	55                   	push   %rbp
ffffffff801080ad:	48 89 e5             	mov    %rsp,%rbp
ffffffff801080b0:	48 83 ec 20          	sub    $0x20,%rsp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
ffffffff801080b4:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff801080b8:	ba 08 00 00 00       	mov    $0x8,%edx
ffffffff801080bd:	48 89 c6             	mov    %rax,%rsi
ffffffff801080c0:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff801080c5:	e8 c7 f0 ff ff       	callq  ffffffff80107191 <argptr>
ffffffff801080ca:	85 c0                	test   %eax,%eax
ffffffff801080cc:	79 0a                	jns    ffffffff801080d8 <sys_pipe+0x2c>
    return -1;
ffffffff801080ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801080d3:	e9 b0 00 00 00       	jmpq   ffffffff80108188 <sys_pipe+0xdc>
  if(pipealloc(&rf, &wf) < 0)
ffffffff801080d8:	48 8d 55 e0          	lea    -0x20(%rbp),%rdx
ffffffff801080dc:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
ffffffff801080e0:	48 89 d6             	mov    %rdx,%rsi
ffffffff801080e3:	48 89 c7             	mov    %rax,%rdi
ffffffff801080e6:	e8 da d5 ff ff       	callq  ffffffff801056c5 <pipealloc>
ffffffff801080eb:	85 c0                	test   %eax,%eax
ffffffff801080ed:	79 0a                	jns    ffffffff801080f9 <sys_pipe+0x4d>
    return -1;
ffffffff801080ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801080f4:	e9 8f 00 00 00       	jmpq   ffffffff80108188 <sys_pipe+0xdc>
  fd0 = -1;
ffffffff801080f9:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%rbp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
ffffffff80108100:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80108104:	48 89 c7             	mov    %rax,%rdi
ffffffff80108107:	e8 95 f2 ff ff       	callq  ffffffff801073a1 <fdalloc>
ffffffff8010810c:	89 45 fc             	mov    %eax,-0x4(%rbp)
ffffffff8010810f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff80108113:	78 15                	js     ffffffff8010812a <sys_pipe+0x7e>
ffffffff80108115:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80108119:	48 89 c7             	mov    %rax,%rdi
ffffffff8010811c:	e8 80 f2 ff ff       	callq  ffffffff801073a1 <fdalloc>
ffffffff80108121:	89 45 f8             	mov    %eax,-0x8(%rbp)
ffffffff80108124:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
ffffffff80108128:	79 43                	jns    ffffffff8010816d <sys_pipe+0xc1>
    if(fd0 >= 0)
ffffffff8010812a:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
ffffffff8010812e:	78 1e                	js     ffffffff8010814e <sys_pipe+0xa2>
      proc->ofile[fd0] = 0;
ffffffff80108130:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80108137:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010813b:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff8010813e:	48 63 d2             	movslq %edx,%rdx
ffffffff80108141:	48 83 c2 08          	add    $0x8,%rdx
ffffffff80108145:	48 c7 44 d0 08 00 00 	movq   $0x0,0x8(%rax,%rdx,8)
ffffffff8010814c:	00 00 
    fileclose(rf);
ffffffff8010814e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80108152:	48 89 c7             	mov    %rax,%rdi
ffffffff80108155:	e8 86 9d ff ff       	callq  ffffffff80101ee0 <fileclose>
    fileclose(wf);
ffffffff8010815a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010815e:	48 89 c7             	mov    %rax,%rdi
ffffffff80108161:	e8 7a 9d ff ff       	callq  ffffffff80101ee0 <fileclose>
    return -1;
ffffffff80108166:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010816b:	eb 1b                	jmp    ffffffff80108188 <sys_pipe+0xdc>
  }
  fd[0] = fd0;
ffffffff8010816d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80108171:	8b 55 fc             	mov    -0x4(%rbp),%edx
ffffffff80108174:	89 10                	mov    %edx,(%rax)
  fd[1] = fd1;
ffffffff80108176:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010817a:	48 8d 50 04          	lea    0x4(%rax),%rdx
ffffffff8010817e:	8b 45 f8             	mov    -0x8(%rbp),%eax
ffffffff80108181:	89 02                	mov    %eax,(%rdx)
  return 0;
ffffffff80108183:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80108188:	c9                   	leaveq 
ffffffff80108189:	c3                   	retq   

ffffffff8010818a <sys_chmod>:

int
sys_chmod(void)
{
ffffffff8010818a:	55                   	push   %rbp
ffffffff8010818b:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010818e:	48 83 ec 20          	sub    $0x20,%rsp
    char *path;
    int mode;
    struct inode *ip;
    if(argstr(0, &path) < 0 || argint(1, &mode) < 0)
ffffffff80108192:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80108196:	48 89 c6             	mov    %rax,%rsi
ffffffff80108199:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff8010819e:	e8 6f f0 ff ff       	callq  ffffffff80107212 <argstr>
ffffffff801081a3:	85 c0                	test   %eax,%eax
ffffffff801081a5:	78 15                	js     ffffffff801081bc <sys_chmod+0x32>
ffffffff801081a7:	48 8d 45 ec          	lea    -0x14(%rbp),%rax
ffffffff801081ab:	48 89 c6             	mov    %rax,%rsi
ffffffff801081ae:	bf 01 00 00 00       	mov    $0x1,%edi
ffffffff801081b3:	e8 87 ef ff ff       	callq  ffffffff8010713f <argint>
ffffffff801081b8:	85 c0                	test   %eax,%eax
ffffffff801081ba:	79 07                	jns    ffffffff801081c3 <sys_chmod+0x39>
        return -1;
ffffffff801081bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801081c1:	eb 71                	jmp    ffffffff80108234 <sys_chmod+0xaa>
    begin_op();
ffffffff801081c3:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801081c8:	e8 2d c1 ff ff       	callq  ffffffff801042fa <begin_op>
    if((ip = namei(path)) == 0) {
ffffffff801081cd:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801081d1:	48 89 c7             	mov    %rax,%rdi
ffffffff801081d4:	e8 97 b3 ff ff       	callq  ffffffff80103570 <namei>
ffffffff801081d9:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff801081dd:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff801081e2:	75 11                	jne    ffffffff801081f5 <sys_chmod+0x6b>
        end_op();
ffffffff801081e4:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801081e9:	e8 8e c1 ff ff       	callq  ffffffff8010437c <end_op>
        return -1;
ffffffff801081ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801081f3:	eb 3f                	jmp    ffffffff80108234 <sys_chmod+0xaa>
    }
    ilock(ip);
ffffffff801081f5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801081f9:	48 89 c7             	mov    %rax,%rdi
ffffffff801081fc:	e8 43 a6 ff ff       	callq  ffffffff80102844 <ilock>
    ip->mode = mode;
ffffffff80108201:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff80108204:	89 c2                	mov    %eax,%edx
ffffffff80108206:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010820a:	89 50 1c             	mov    %edx,0x1c(%rax)
    iupdate(ip); // Copy to disk
ffffffff8010820d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80108211:	48 89 c7             	mov    %rax,%rdi
ffffffff80108214:	e8 1f a4 ff ff       	callq  ffffffff80102638 <iupdate>
    iunlockput(ip);
ffffffff80108219:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010821d:	48 89 c7             	mov    %rax,%rdi
ffffffff80108220:	e8 15 a9 ff ff       	callq  ffffffff80102b3a <iunlockput>
    end_op();
ffffffff80108225:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff8010822a:	e8 4d c1 ff ff       	callq  ffffffff8010437c <end_op>
    return 0;
ffffffff8010822f:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80108234:	c9                   	leaveq 
ffffffff80108235:	c3                   	retq   

ffffffff80108236 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
ffffffff80108236:	55                   	push   %rbp
ffffffff80108237:	48 89 e5             	mov    %rsp,%rbp
  return fork();
ffffffff8010823a:	e8 34 dc ff ff       	callq  ffffffff80105e73 <fork>
}
ffffffff8010823f:	5d                   	pop    %rbp
ffffffff80108240:	c3                   	retq   

ffffffff80108241 <sys_exit>:

int
sys_exit(void)
{
ffffffff80108241:	55                   	push   %rbp
ffffffff80108242:	48 89 e5             	mov    %rsp,%rbp
  exit();
ffffffff80108245:	e8 0c de ff ff       	callq  ffffffff80106056 <exit>
  return 0;  // not reached
ffffffff8010824a:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff8010824f:	5d                   	pop    %rbp
ffffffff80108250:	c3                   	retq   

ffffffff80108251 <sys_wait>:

int
sys_wait(void)
{
ffffffff80108251:	55                   	push   %rbp
ffffffff80108252:	48 89 e5             	mov    %rsp,%rbp
  return wait();
ffffffff80108255:	e8 81 df ff ff       	callq  ffffffff801061db <wait>
}
ffffffff8010825a:	5d                   	pop    %rbp
ffffffff8010825b:	c3                   	retq   

ffffffff8010825c <sys_kill>:

int
sys_kill(void)
{
ffffffff8010825c:	55                   	push   %rbp
ffffffff8010825d:	48 89 e5             	mov    %rsp,%rbp
ffffffff80108260:	48 83 ec 10          	sub    $0x10,%rsp
  int pid;

  if(argint(0, &pid) < 0)
ffffffff80108264:	48 8d 45 fc          	lea    -0x4(%rbp),%rax
ffffffff80108268:	48 89 c6             	mov    %rax,%rsi
ffffffff8010826b:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff80108270:	e8 ca ee ff ff       	callq  ffffffff8010713f <argint>
ffffffff80108275:	85 c0                	test   %eax,%eax
ffffffff80108277:	79 07                	jns    ffffffff80108280 <sys_kill+0x24>
    return -1;
ffffffff80108279:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010827e:	eb 0a                	jmp    ffffffff8010828a <sys_kill+0x2e>
  return kill(pid);
ffffffff80108280:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80108283:	89 c7                	mov    %eax,%edi
ffffffff80108285:	e8 dd e3 ff ff       	callq  ffffffff80106667 <kill>
}
ffffffff8010828a:	c9                   	leaveq 
ffffffff8010828b:	c3                   	retq   

ffffffff8010828c <sys_getpid>:

int
sys_getpid(void)
{
ffffffff8010828c:	55                   	push   %rbp
ffffffff8010828d:	48 89 e5             	mov    %rsp,%rbp
  return proc->pid;
ffffffff80108290:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80108297:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010829b:	8b 40 1c             	mov    0x1c(%rax),%eax
}
ffffffff8010829e:	5d                   	pop    %rbp
ffffffff8010829f:	c3                   	retq   

ffffffff801082a0 <sys_sbrk>:

uintp
sys_sbrk(void)
{
ffffffff801082a0:	55                   	push   %rbp
ffffffff801082a1:	48 89 e5             	mov    %rsp,%rbp
ffffffff801082a4:	48 83 ec 10          	sub    $0x10,%rsp
  uintp addr;
  uintp n;

  if(arguintp(0, &n) < 0)
ffffffff801082a8:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff801082ac:	48 89 c6             	mov    %rax,%rsi
ffffffff801082af:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff801082b4:	e8 ae ee ff ff       	callq  ffffffff80107167 <arguintp>
ffffffff801082b9:	85 c0                	test   %eax,%eax
ffffffff801082bb:	79 09                	jns    ffffffff801082c6 <sys_sbrk+0x26>
    return -1;
ffffffff801082bd:	48 c7 c0 ff ff ff ff 	mov    $0xffffffffffffffff,%rax
ffffffff801082c4:	eb 2e                	jmp    ffffffff801082f4 <sys_sbrk+0x54>
  addr = proc->sz;
ffffffff801082c6:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801082cd:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801082d1:	48 8b 00             	mov    (%rax),%rax
ffffffff801082d4:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if(growproc(n) < 0)
ffffffff801082d8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff801082dc:	89 c7                	mov    %eax,%edi
ffffffff801082de:	e8 d2 da ff ff       	callq  ffffffff80105db5 <growproc>
ffffffff801082e3:	85 c0                	test   %eax,%eax
ffffffff801082e5:	79 09                	jns    ffffffff801082f0 <sys_sbrk+0x50>
    return -1;
ffffffff801082e7:	48 c7 c0 ff ff ff ff 	mov    $0xffffffffffffffff,%rax
ffffffff801082ee:	eb 04                	jmp    ffffffff801082f4 <sys_sbrk+0x54>
  return addr;
ffffffff801082f0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff801082f4:	c9                   	leaveq 
ffffffff801082f5:	c3                   	retq   

ffffffff801082f6 <sys_sleep>:

int
sys_sleep(void)
{
ffffffff801082f6:	55                   	push   %rbp
ffffffff801082f7:	48 89 e5             	mov    %rsp,%rbp
ffffffff801082fa:	48 83 ec 10          	sub    $0x10,%rsp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
ffffffff801082fe:	48 8d 45 f8          	lea    -0x8(%rbp),%rax
ffffffff80108302:	48 89 c6             	mov    %rax,%rsi
ffffffff80108305:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff8010830a:	e8 30 ee ff ff       	callq  ffffffff8010713f <argint>
ffffffff8010830f:	85 c0                	test   %eax,%eax
ffffffff80108311:	79 07                	jns    ffffffff8010831a <sys_sleep+0x24>
    return -1;
ffffffff80108313:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80108318:	eb 70                	jmp    ffffffff8010838a <sys_sleep+0x94>
  acquire(&tickslock);
ffffffff8010831a:	48 c7 c7 80 4f 19 80 	mov    $0xffffffff80194f80,%rdi
ffffffff80108321:	e8 78 e5 ff ff       	callq  ffffffff8010689e <acquire>
  ticks0 = ticks;
ffffffff80108326:	8b 05 bc cc 08 00    	mov    0x8ccbc(%rip),%eax        # ffffffff80194fe8 <ticks>
ffffffff8010832c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  while(ticks - ticks0 < n){
ffffffff8010832f:	eb 38                	jmp    ffffffff80108369 <sys_sleep+0x73>
    if(proc->killed){
ffffffff80108331:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80108338:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010833c:	8b 40 40             	mov    0x40(%rax),%eax
ffffffff8010833f:	85 c0                	test   %eax,%eax
ffffffff80108341:	74 13                	je     ffffffff80108356 <sys_sleep+0x60>
      release(&tickslock);
ffffffff80108343:	48 c7 c7 80 4f 19 80 	mov    $0xffffffff80194f80,%rdi
ffffffff8010834a:	e8 26 e6 ff ff       	callq  ffffffff80106975 <release>
      return -1;
ffffffff8010834f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80108354:	eb 34                	jmp    ffffffff8010838a <sys_sleep+0x94>
    }
    sleep(&ticks, &tickslock);
ffffffff80108356:	48 c7 c6 80 4f 19 80 	mov    $0xffffffff80194f80,%rsi
ffffffff8010835d:	48 c7 c7 e8 4f 19 80 	mov    $0xffffffff80194fe8,%rdi
ffffffff80108364:	e8 b8 e1 ff ff       	callq  ffffffff80106521 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
ffffffff80108369:	8b 05 79 cc 08 00    	mov    0x8cc79(%rip),%eax        # ffffffff80194fe8 <ticks>
ffffffff8010836f:	2b 45 fc             	sub    -0x4(%rbp),%eax
ffffffff80108372:	8b 55 f8             	mov    -0x8(%rbp),%edx
ffffffff80108375:	39 d0                	cmp    %edx,%eax
ffffffff80108377:	72 b8                	jb     ffffffff80108331 <sys_sleep+0x3b>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
ffffffff80108379:	48 c7 c7 80 4f 19 80 	mov    $0xffffffff80194f80,%rdi
ffffffff80108380:	e8 f0 e5 ff ff       	callq  ffffffff80106975 <release>
  return 0;
ffffffff80108385:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff8010838a:	c9                   	leaveq 
ffffffff8010838b:	c3                   	retq   

ffffffff8010838c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
ffffffff8010838c:	55                   	push   %rbp
ffffffff8010838d:	48 89 e5             	mov    %rsp,%rbp
ffffffff80108390:	48 83 ec 10          	sub    $0x10,%rsp
  uint xticks;
  
  acquire(&tickslock);
ffffffff80108394:	48 c7 c7 80 4f 19 80 	mov    $0xffffffff80194f80,%rdi
ffffffff8010839b:	e8 fe e4 ff ff       	callq  ffffffff8010689e <acquire>
  xticks = ticks;
ffffffff801083a0:	8b 05 42 cc 08 00    	mov    0x8cc42(%rip),%eax        # ffffffff80194fe8 <ticks>
ffffffff801083a6:	89 45 fc             	mov    %eax,-0x4(%rbp)
  release(&tickslock);
ffffffff801083a9:	48 c7 c7 80 4f 19 80 	mov    $0xffffffff80194f80,%rdi
ffffffff801083b0:	e8 c0 e5 ff ff       	callq  ffffffff80106975 <release>
  return xticks;
ffffffff801083b5:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
ffffffff801083b8:	c9                   	leaveq 
ffffffff801083b9:	c3                   	retq   

ffffffff801083ba <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
ffffffff801083ba:	55                   	push   %rbp
ffffffff801083bb:	48 89 e5             	mov    %rsp,%rbp
ffffffff801083be:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801083c2:	89 fa                	mov    %edi,%edx
ffffffff801083c4:	89 f0                	mov    %esi,%eax
ffffffff801083c6:	66 89 55 fc          	mov    %dx,-0x4(%rbp)
ffffffff801083ca:	88 45 f8             	mov    %al,-0x8(%rbp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
ffffffff801083cd:	0f b6 45 f8          	movzbl -0x8(%rbp),%eax
ffffffff801083d1:	0f b7 55 fc          	movzwl -0x4(%rbp),%edx
ffffffff801083d5:	ee                   	out    %al,(%dx)
}
ffffffff801083d6:	90                   	nop
ffffffff801083d7:	c9                   	leaveq 
ffffffff801083d8:	c3                   	retq   

ffffffff801083d9 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
ffffffff801083d9:	55                   	push   %rbp
ffffffff801083da:	48 89 e5             	mov    %rsp,%rbp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
ffffffff801083dd:	be 34 00 00 00       	mov    $0x34,%esi
ffffffff801083e2:	bf 43 00 00 00       	mov    $0x43,%edi
ffffffff801083e7:	e8 ce ff ff ff       	callq  ffffffff801083ba <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
ffffffff801083ec:	be 9c 00 00 00       	mov    $0x9c,%esi
ffffffff801083f1:	bf 40 00 00 00       	mov    $0x40,%edi
ffffffff801083f6:	e8 bf ff ff ff       	callq  ffffffff801083ba <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
ffffffff801083fb:	be 2e 00 00 00       	mov    $0x2e,%esi
ffffffff80108400:	bf 40 00 00 00       	mov    $0x40,%edi
ffffffff80108405:	e8 b0 ff ff ff       	callq  ffffffff801083ba <outb>
  picenable(IRQ_TIMER);
ffffffff8010840a:	bf 00 00 00 00       	mov    $0x0,%edi
ffffffff8010840f:	e8 87 d1 ff ff       	callq  ffffffff8010559b <picenable>
}
ffffffff80108414:	90                   	nop
ffffffff80108415:	5d                   	pop    %rbp
ffffffff80108416:	c3                   	retq   

ffffffff80108417 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  push %r15
ffffffff80108417:	41 57                	push   %r15
  push %r14
ffffffff80108419:	41 56                	push   %r14
  push %r13
ffffffff8010841b:	41 55                	push   %r13
  push %r12
ffffffff8010841d:	41 54                	push   %r12
  push %r11
ffffffff8010841f:	41 53                	push   %r11
  push %r10
ffffffff80108421:	41 52                	push   %r10
  push %r9
ffffffff80108423:	41 51                	push   %r9
  push %r8
ffffffff80108425:	41 50                	push   %r8
  push %rdi
ffffffff80108427:	57                   	push   %rdi
  push %rsi
ffffffff80108428:	56                   	push   %rsi
  push %rbp
ffffffff80108429:	55                   	push   %rbp
  push %rdx
ffffffff8010842a:	52                   	push   %rdx
  push %rcx
ffffffff8010842b:	51                   	push   %rcx
  push %rbx
ffffffff8010842c:	53                   	push   %rbx
  push %rax
ffffffff8010842d:	50                   	push   %rax

  mov  %rsp, %rdi  # frame in arg1
ffffffff8010842e:	48 89 e7             	mov    %rsp,%rdi
  call trap
ffffffff80108431:	e8 32 00 00 00       	callq  ffffffff80108468 <trap>

ffffffff80108436 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  pop %rax
ffffffff80108436:	58                   	pop    %rax
  pop %rbx
ffffffff80108437:	5b                   	pop    %rbx
  pop %rcx
ffffffff80108438:	59                   	pop    %rcx
  pop %rdx
ffffffff80108439:	5a                   	pop    %rdx
  pop %rbp
ffffffff8010843a:	5d                   	pop    %rbp
  pop %rsi
ffffffff8010843b:	5e                   	pop    %rsi
  pop %rdi
ffffffff8010843c:	5f                   	pop    %rdi
  pop %r8
ffffffff8010843d:	41 58                	pop    %r8
  pop %r9
ffffffff8010843f:	41 59                	pop    %r9
  pop %r10
ffffffff80108441:	41 5a                	pop    %r10
  pop %r11
ffffffff80108443:	41 5b                	pop    %r11
  pop %r12
ffffffff80108445:	41 5c                	pop    %r12
  pop %r13
ffffffff80108447:	41 5d                	pop    %r13
  pop %r14
ffffffff80108449:	41 5e                	pop    %r14
  pop %r15
ffffffff8010844b:	41 5f                	pop    %r15

  # discard trapnum and errorcode
  add $16, %rsp
ffffffff8010844d:	48 83 c4 10          	add    $0x10,%rsp
  iretq
ffffffff80108451:	48 cf                	iretq  

ffffffff80108453 <rcr2>:
  return result;
}

static inline uintp
rcr2(void)
{
ffffffff80108453:	55                   	push   %rbp
ffffffff80108454:	48 89 e5             	mov    %rsp,%rbp
ffffffff80108457:	48 83 ec 10          	sub    $0x10,%rsp
  uintp val;
  asm volatile("mov %%cr2,%0" : "=r" (val));
ffffffff8010845b:	0f 20 d0             	mov    %cr2,%rax
ffffffff8010845e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  return val;
ffffffff80108462:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
ffffffff80108466:	c9                   	leaveq 
ffffffff80108467:	c3                   	retq   

ffffffff80108468 <trap>:
#endif

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
ffffffff80108468:	55                   	push   %rbp
ffffffff80108469:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010846c:	48 83 ec 10          	sub    $0x10,%rsp
ffffffff80108470:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  if(tf->trapno == T_SYSCALL){
ffffffff80108474:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80108478:	48 8b 40 78          	mov    0x78(%rax),%rax
ffffffff8010847c:	48 83 f8 40          	cmp    $0x40,%rax
ffffffff80108480:	75 4f                	jne    ffffffff801084d1 <trap+0x69>
    if(proc->killed)
ffffffff80108482:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80108489:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010848d:	8b 40 40             	mov    0x40(%rax),%eax
ffffffff80108490:	85 c0                	test   %eax,%eax
ffffffff80108492:	74 05                	je     ffffffff80108499 <trap+0x31>
      exit();
ffffffff80108494:	e8 bd db ff ff       	callq  ffffffff80106056 <exit>
    proc->tf = tf;
ffffffff80108499:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801084a0:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801084a4:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff801084a8:	48 89 50 28          	mov    %rdx,0x28(%rax)
    syscall();
ffffffff801084ac:	e8 a1 ed ff ff       	callq  ffffffff80107252 <syscall>
    if(proc->killed)
ffffffff801084b1:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801084b8:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801084bc:	8b 40 40             	mov    0x40(%rax),%eax
ffffffff801084bf:	85 c0                	test   %eax,%eax
ffffffff801084c1:	0f 84 9a 02 00 00    	je     ffffffff80108761 <trap+0x2f9>
      exit();
ffffffff801084c7:	e8 8a db ff ff       	callq  ffffffff80106056 <exit>
    return;
ffffffff801084cc:	e9 90 02 00 00       	jmpq   ffffffff80108761 <trap+0x2f9>
  }

  switch(tf->trapno){
ffffffff801084d1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801084d5:	48 8b 40 78          	mov    0x78(%rax),%rax
ffffffff801084d9:	48 83 e8 20          	sub    $0x20,%rax
ffffffff801084dd:	48 83 f8 1f          	cmp    $0x1f,%rax
ffffffff801084e1:	0f 87 ca 00 00 00    	ja     ffffffff801085b1 <trap+0x149>
ffffffff801084e7:	48 8b 04 c5 a0 af 10 	mov    -0x7fef5060(,%rax,8),%rax
ffffffff801084ee:	80 
ffffffff801084ef:	ff e0                	jmpq   *%rax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
ffffffff801084f1:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff801084f8:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801084fc:	0f b6 00             	movzbl (%rax),%eax
ffffffff801084ff:	84 c0                	test   %al,%al
ffffffff80108501:	75 33                	jne    ffffffff80108536 <trap+0xce>
      acquire(&tickslock);
ffffffff80108503:	48 c7 c7 80 4f 19 80 	mov    $0xffffffff80194f80,%rdi
ffffffff8010850a:	e8 8f e3 ff ff       	callq  ffffffff8010689e <acquire>
      ticks++;
ffffffff8010850f:	8b 05 d3 ca 08 00    	mov    0x8cad3(%rip),%eax        # ffffffff80194fe8 <ticks>
ffffffff80108515:	83 c0 01             	add    $0x1,%eax
ffffffff80108518:	89 05 ca ca 08 00    	mov    %eax,0x8caca(%rip)        # ffffffff80194fe8 <ticks>
      wakeup(&ticks);
ffffffff8010851e:	48 c7 c7 e8 4f 19 80 	mov    $0xffffffff80194fe8,%rdi
ffffffff80108525:	e8 0a e1 ff ff       	callq  ffffffff80106634 <wakeup>
      release(&tickslock);
ffffffff8010852a:	48 c7 c7 80 4f 19 80 	mov    $0xffffffff80194f80,%rdi
ffffffff80108531:	e8 3f e4 ff ff       	callq  ffffffff80106975 <release>
    }
    lapiceoi();
ffffffff80108536:	e8 5b b8 ff ff       	callq  ffffffff80103d96 <lapiceoi>
    break;
ffffffff8010853b:	e9 73 01 00 00       	jmpq   ffffffff801086b3 <trap+0x24b>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
ffffffff80108540:	e8 c2 1e 00 00       	callq  ffffffff8010a407 <ideintr>
    lapiceoi();
ffffffff80108545:	e8 4c b8 ff ff       	callq  ffffffff80103d96 <lapiceoi>
    break;
ffffffff8010854a:	e9 64 01 00 00       	jmpq   ffffffff801086b3 <trap+0x24b>
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
ffffffff8010854f:	e8 1c b5 ff ff       	callq  ffffffff80103a70 <kbdintr>
    lapiceoi();
ffffffff80108554:	e8 3d b8 ff ff       	callq  ffffffff80103d96 <lapiceoi>
    break;
ffffffff80108559:	e9 55 01 00 00       	jmpq   ffffffff801086b3 <trap+0x24b>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
ffffffff8010855e:	e8 d3 03 00 00       	callq  ffffffff80108936 <uartintr>
    lapiceoi();
ffffffff80108563:	e8 2e b8 ff ff       	callq  ffffffff80103d96 <lapiceoi>
    break;
ffffffff80108568:	e9 46 01 00 00       	jmpq   ffffffff801086b3 <trap+0x24b>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
ffffffff8010856d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80108571:	48 8b 88 88 00 00 00 	mov    0x88(%rax),%rcx
ffffffff80108578:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010857c:	48 8b 90 90 00 00 00 	mov    0x90(%rax),%rdx
            cpu->id, tf->cs, tf->eip);
ffffffff80108583:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff8010858a:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010858e:	0f b6 00             	movzbl (%rax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
ffffffff80108591:	0f b6 c0             	movzbl %al,%eax
ffffffff80108594:	89 c6                	mov    %eax,%esi
ffffffff80108596:	48 c7 c7 f8 ae 10 80 	mov    $0xffffffff8010aef8,%rdi
ffffffff8010859d:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801085a2:	e8 fb 7f ff ff       	callq  ffffffff801005a2 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
ffffffff801085a7:	e8 ea b7 ff ff       	callq  ffffffff80103d96 <lapiceoi>
    break;
ffffffff801085ac:	e9 02 01 00 00       	jmpq   ffffffff801086b3 <trap+0x24b>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
ffffffff801085b1:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801085b8:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801085bc:	48 85 c0             	test   %rax,%rax
ffffffff801085bf:	74 13                	je     ffffffff801085d4 <trap+0x16c>
ffffffff801085c1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801085c5:	48 8b 80 90 00 00 00 	mov    0x90(%rax),%rax
ffffffff801085cc:	83 e0 03             	and    $0x3,%eax
ffffffff801085cf:	48 85 c0             	test   %rax,%rax
ffffffff801085d2:	75 4f                	jne    ffffffff80108623 <trap+0x1bb>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
ffffffff801085d4:	e8 7a fe ff ff       	callq  ffffffff80108453 <rcr2>
ffffffff801085d9:	48 89 c6             	mov    %rax,%rsi
ffffffff801085dc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801085e0:	48 8b 88 88 00 00 00 	mov    0x88(%rax),%rcx
              tf->trapno, cpu->id, tf->eip, rcr2());
ffffffff801085e7:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff801085ee:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801085f2:	0f b6 00             	movzbl (%rax),%eax
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
ffffffff801085f5:	0f b6 d0             	movzbl %al,%edx
ffffffff801085f8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801085fc:	48 8b 40 78          	mov    0x78(%rax),%rax
ffffffff80108600:	49 89 f0             	mov    %rsi,%r8
ffffffff80108603:	48 89 c6             	mov    %rax,%rsi
ffffffff80108606:	48 c7 c7 20 af 10 80 	mov    $0xffffffff8010af20,%rdi
ffffffff8010860d:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80108612:	e8 8b 7f ff ff       	callq  ffffffff801005a2 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
ffffffff80108617:	48 c7 c7 52 af 10 80 	mov    $0xffffffff8010af52,%rdi
ffffffff8010861e:	e8 dc 82 ff ff       	callq  ffffffff801008ff <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
ffffffff80108623:	e8 2b fe ff ff       	callq  ffffffff80108453 <rcr2>
ffffffff80108628:	49 89 c1             	mov    %rax,%r9
ffffffff8010862b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010862f:	48 8b 88 88 00 00 00 	mov    0x88(%rax),%rcx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
ffffffff80108636:	48 c7 c0 f0 ff ff ff 	mov    $0xfffffffffffffff0,%rax
ffffffff8010863d:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80108641:	0f b6 00             	movzbl (%rax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
ffffffff80108644:	44 0f b6 c0          	movzbl %al,%r8d
ffffffff80108648:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010864c:	48 8b b8 80 00 00 00 	mov    0x80(%rax),%rdi
ffffffff80108653:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80108657:	48 8b 50 78          	mov    0x78(%rax),%rdx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
ffffffff8010865b:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80108662:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80108666:	48 8d b0 d0 00 00 00 	lea    0xd0(%rax),%rsi
ffffffff8010866d:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80108674:	64 48 8b 00          	mov    %fs:(%rax),%rax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
ffffffff80108678:	8b 40 1c             	mov    0x1c(%rax),%eax
ffffffff8010867b:	41 51                	push   %r9
ffffffff8010867d:	51                   	push   %rcx
ffffffff8010867e:	45 89 c1             	mov    %r8d,%r9d
ffffffff80108681:	49 89 f8             	mov    %rdi,%r8
ffffffff80108684:	48 89 d1             	mov    %rdx,%rcx
ffffffff80108687:	48 89 f2             	mov    %rsi,%rdx
ffffffff8010868a:	89 c6                	mov    %eax,%esi
ffffffff8010868c:	48 c7 c7 58 af 10 80 	mov    $0xffffffff8010af58,%rdi
ffffffff80108693:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80108698:	e8 05 7f ff ff       	callq  ffffffff801005a2 <cprintf>
ffffffff8010869d:	48 83 c4 10          	add    $0x10,%rsp
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
ffffffff801086a1:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801086a8:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801086ac:	c7 40 40 01 00 00 00 	movl   $0x1,0x40(%rax)
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
ffffffff801086b3:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801086ba:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801086be:	48 85 c0             	test   %rax,%rax
ffffffff801086c1:	74 2b                	je     ffffffff801086ee <trap+0x286>
ffffffff801086c3:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801086ca:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801086ce:	8b 40 40             	mov    0x40(%rax),%eax
ffffffff801086d1:	85 c0                	test   %eax,%eax
ffffffff801086d3:	74 19                	je     ffffffff801086ee <trap+0x286>
ffffffff801086d5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801086d9:	48 8b 80 90 00 00 00 	mov    0x90(%rax),%rax
ffffffff801086e0:	83 e0 03             	and    $0x3,%eax
ffffffff801086e3:	48 83 f8 03          	cmp    $0x3,%rax
ffffffff801086e7:	75 05                	jne    ffffffff801086ee <trap+0x286>
    exit();
ffffffff801086e9:	e8 68 d9 ff ff       	callq  ffffffff80106056 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
ffffffff801086ee:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff801086f5:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff801086f9:	48 85 c0             	test   %rax,%rax
ffffffff801086fc:	74 26                	je     ffffffff80108724 <trap+0x2bc>
ffffffff801086fe:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff80108705:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff80108709:	8b 40 18             	mov    0x18(%rax),%eax
ffffffff8010870c:	83 f8 04             	cmp    $0x4,%eax
ffffffff8010870f:	75 13                	jne    ffffffff80108724 <trap+0x2bc>
ffffffff80108711:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80108715:	48 8b 40 78          	mov    0x78(%rax),%rax
ffffffff80108719:	48 83 f8 20          	cmp    $0x20,%rax
ffffffff8010871d:	75 05                	jne    ffffffff80108724 <trap+0x2bc>
    yield();
ffffffff8010871f:	e8 9b dd ff ff       	callq  ffffffff801064bf <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
ffffffff80108724:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff8010872b:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010872f:	48 85 c0             	test   %rax,%rax
ffffffff80108732:	74 2e                	je     ffffffff80108762 <trap+0x2fa>
ffffffff80108734:	48 c7 c0 f8 ff ff ff 	mov    $0xfffffffffffffff8,%rax
ffffffff8010873b:	64 48 8b 00          	mov    %fs:(%rax),%rax
ffffffff8010873f:	8b 40 40             	mov    0x40(%rax),%eax
ffffffff80108742:	85 c0                	test   %eax,%eax
ffffffff80108744:	74 1c                	je     ffffffff80108762 <trap+0x2fa>
ffffffff80108746:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010874a:	48 8b 80 90 00 00 00 	mov    0x90(%rax),%rax
ffffffff80108751:	83 e0 03             	and    $0x3,%eax
ffffffff80108754:	48 83 f8 03          	cmp    $0x3,%rax
ffffffff80108758:	75 08                	jne    ffffffff80108762 <trap+0x2fa>
    exit();
ffffffff8010875a:	e8 f7 d8 ff ff       	callq  ffffffff80106056 <exit>
ffffffff8010875f:	eb 01                	jmp    ffffffff80108762 <trap+0x2fa>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
ffffffff80108761:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
ffffffff80108762:	c9                   	leaveq 
ffffffff80108763:	c3                   	retq   

ffffffff80108764 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
ffffffff80108764:	55                   	push   %rbp
ffffffff80108765:	48 89 e5             	mov    %rsp,%rbp
ffffffff80108768:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff8010876c:	89 f8                	mov    %edi,%eax
ffffffff8010876e:	66 89 45 ec          	mov    %ax,-0x14(%rbp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
ffffffff80108772:	0f b7 45 ec          	movzwl -0x14(%rbp),%eax
ffffffff80108776:	89 c2                	mov    %eax,%edx
ffffffff80108778:	ec                   	in     (%dx),%al
ffffffff80108779:	88 45 ff             	mov    %al,-0x1(%rbp)
  return data;
ffffffff8010877c:	0f b6 45 ff          	movzbl -0x1(%rbp),%eax
}
ffffffff80108780:	c9                   	leaveq 
ffffffff80108781:	c3                   	retq   

ffffffff80108782 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
ffffffff80108782:	55                   	push   %rbp
ffffffff80108783:	48 89 e5             	mov    %rsp,%rbp
ffffffff80108786:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff8010878a:	89 fa                	mov    %edi,%edx
ffffffff8010878c:	89 f0                	mov    %esi,%eax
ffffffff8010878e:	66 89 55 fc          	mov    %dx,-0x4(%rbp)
ffffffff80108792:	88 45 f8             	mov    %al,-0x8(%rbp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
ffffffff80108795:	0f b6 45 f8          	movzbl -0x8(%rbp),%eax
ffffffff80108799:	0f b7 55 fc          	movzwl -0x4(%rbp),%edx
ffffffff8010879d:	ee                   	out    %al,(%dx)
}
ffffffff8010879e:	90                   	nop
ffffffff8010879f:	c9                   	leaveq 
ffffffff801087a0:	c3                   	retq   

ffffffff801087a1 <uartearlyinit>:

static int uart;    // is there a uart?

void
uartearlyinit(void)
{
ffffffff801087a1:	55                   	push   %rbp
ffffffff801087a2:	48 89 e5             	mov    %rsp,%rbp
ffffffff801087a5:	48 83 ec 10          	sub    $0x10,%rsp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
ffffffff801087a9:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801087ae:	bf fa 03 00 00       	mov    $0x3fa,%edi
ffffffff801087b3:	e8 ca ff ff ff       	callq  ffffffff80108782 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
ffffffff801087b8:	be 80 00 00 00       	mov    $0x80,%esi
ffffffff801087bd:	bf fb 03 00 00       	mov    $0x3fb,%edi
ffffffff801087c2:	e8 bb ff ff ff       	callq  ffffffff80108782 <outb>
  outb(COM1+0, 115200/9600);
ffffffff801087c7:	be 0c 00 00 00       	mov    $0xc,%esi
ffffffff801087cc:	bf f8 03 00 00       	mov    $0x3f8,%edi
ffffffff801087d1:	e8 ac ff ff ff       	callq  ffffffff80108782 <outb>
  outb(COM1+1, 0);
ffffffff801087d6:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801087db:	bf f9 03 00 00       	mov    $0x3f9,%edi
ffffffff801087e0:	e8 9d ff ff ff       	callq  ffffffff80108782 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
ffffffff801087e5:	be 03 00 00 00       	mov    $0x3,%esi
ffffffff801087ea:	bf fb 03 00 00       	mov    $0x3fb,%edi
ffffffff801087ef:	e8 8e ff ff ff       	callq  ffffffff80108782 <outb>
  outb(COM1+4, 0);
ffffffff801087f4:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801087f9:	bf fc 03 00 00       	mov    $0x3fc,%edi
ffffffff801087fe:	e8 7f ff ff ff       	callq  ffffffff80108782 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
ffffffff80108803:	be 01 00 00 00       	mov    $0x1,%esi
ffffffff80108808:	bf f9 03 00 00       	mov    $0x3f9,%edi
ffffffff8010880d:	e8 70 ff ff ff       	callq  ffffffff80108782 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
ffffffff80108812:	bf fd 03 00 00       	mov    $0x3fd,%edi
ffffffff80108817:	e8 48 ff ff ff       	callq  ffffffff80108764 <inb>
ffffffff8010881c:	3c ff                	cmp    $0xff,%al
ffffffff8010881e:	74 37                	je     ffffffff80108857 <uartearlyinit+0xb6>
    return;
  uart = 1;
ffffffff80108820:	c7 05 c2 c7 08 00 01 	movl   $0x1,0x8c7c2(%rip)        # ffffffff80194fec <uart>
ffffffff80108827:	00 00 00 

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
ffffffff8010882a:	48 c7 45 f8 a0 b0 10 	movq   $0xffffffff8010b0a0,-0x8(%rbp)
ffffffff80108831:	80 
ffffffff80108832:	eb 16                	jmp    ffffffff8010884a <uartearlyinit+0xa9>
    uartputc(*p);
ffffffff80108834:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80108838:	0f b6 00             	movzbl (%rax),%eax
ffffffff8010883b:	0f be c0             	movsbl %al,%eax
ffffffff8010883e:	89 c7                	mov    %eax,%edi
ffffffff80108840:	e8 55 00 00 00       	callq  ffffffff8010889a <uartputc>
  if(inb(COM1+5) == 0xFF)
    return;
  uart = 1;

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
ffffffff80108845:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
ffffffff8010884a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010884e:	0f b6 00             	movzbl (%rax),%eax
ffffffff80108851:	84 c0                	test   %al,%al
ffffffff80108853:	75 df                	jne    ffffffff80108834 <uartearlyinit+0x93>
ffffffff80108855:	eb 01                	jmp    ffffffff80108858 <uartearlyinit+0xb7>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
ffffffff80108857:	90                   	nop
  uart = 1;

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
ffffffff80108858:	c9                   	leaveq 
ffffffff80108859:	c3                   	retq   

ffffffff8010885a <uartinit>:

void
uartinit(void)
{
ffffffff8010885a:	55                   	push   %rbp
ffffffff8010885b:	48 89 e5             	mov    %rsp,%rbp
  if (!uart)
ffffffff8010885e:	8b 05 88 c7 08 00    	mov    0x8c788(%rip),%eax        # ffffffff80194fec <uart>
ffffffff80108864:	85 c0                	test   %eax,%eax
ffffffff80108866:	74 2f                	je     ffffffff80108897 <uartinit+0x3d>
    return;

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
ffffffff80108868:	bf fa 03 00 00       	mov    $0x3fa,%edi
ffffffff8010886d:	e8 f2 fe ff ff       	callq  ffffffff80108764 <inb>
  inb(COM1+0);
ffffffff80108872:	bf f8 03 00 00       	mov    $0x3f8,%edi
ffffffff80108877:	e8 e8 fe ff ff       	callq  ffffffff80108764 <inb>
  picenable(IRQ_COM1);
ffffffff8010887c:	bf 04 00 00 00       	mov    $0x4,%edi
ffffffff80108881:	e8 15 cd ff ff       	callq  ffffffff8010559b <picenable>
  ioapicenable(IRQ_COM1, 0);
ffffffff80108886:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff8010888b:	bf 04 00 00 00       	mov    $0x4,%edi
ffffffff80108890:	e8 2d ae ff ff       	callq  ffffffff801036c2 <ioapicenable>
ffffffff80108895:	eb 01                	jmp    ffffffff80108898 <uartinit+0x3e>

void
uartinit(void)
{
  if (!uart)
    return;
ffffffff80108897:	90                   	nop
  // enable interrupts.
  inb(COM1+2);
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
}
ffffffff80108898:	5d                   	pop    %rbp
ffffffff80108899:	c3                   	retq   

ffffffff8010889a <uartputc>:

void
uartputc(int c)
{
ffffffff8010889a:	55                   	push   %rbp
ffffffff8010889b:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010889e:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801088a2:	89 7d ec             	mov    %edi,-0x14(%rbp)
  int i;

  if(!uart)
ffffffff801088a5:	8b 05 41 c7 08 00    	mov    0x8c741(%rip),%eax        # ffffffff80194fec <uart>
ffffffff801088ab:	85 c0                	test   %eax,%eax
ffffffff801088ad:	74 45                	je     ffffffff801088f4 <uartputc+0x5a>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
ffffffff801088af:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801088b6:	eb 0e                	jmp    ffffffff801088c6 <uartputc+0x2c>
    microdelay(10);
ffffffff801088b8:	bf 0a 00 00 00       	mov    $0xa,%edi
ffffffff801088bd:	e8 f6 b4 ff ff       	callq  ffffffff80103db8 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
ffffffff801088c2:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff801088c6:	83 7d fc 7f          	cmpl   $0x7f,-0x4(%rbp)
ffffffff801088ca:	7f 14                	jg     ffffffff801088e0 <uartputc+0x46>
ffffffff801088cc:	bf fd 03 00 00       	mov    $0x3fd,%edi
ffffffff801088d1:	e8 8e fe ff ff       	callq  ffffffff80108764 <inb>
ffffffff801088d6:	0f b6 c0             	movzbl %al,%eax
ffffffff801088d9:	83 e0 20             	and    $0x20,%eax
ffffffff801088dc:	85 c0                	test   %eax,%eax
ffffffff801088de:	74 d8                	je     ffffffff801088b8 <uartputc+0x1e>
    microdelay(10);
  outb(COM1+0, c);
ffffffff801088e0:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff801088e3:	0f b6 c0             	movzbl %al,%eax
ffffffff801088e6:	89 c6                	mov    %eax,%esi
ffffffff801088e8:	bf f8 03 00 00       	mov    $0x3f8,%edi
ffffffff801088ed:	e8 90 fe ff ff       	callq  ffffffff80108782 <outb>
ffffffff801088f2:	eb 01                	jmp    ffffffff801088f5 <uartputc+0x5b>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
ffffffff801088f4:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
ffffffff801088f5:	c9                   	leaveq 
ffffffff801088f6:	c3                   	retq   

ffffffff801088f7 <uartgetc>:

static int
uartgetc(void)
{
ffffffff801088f7:	55                   	push   %rbp
ffffffff801088f8:	48 89 e5             	mov    %rsp,%rbp
  if(!uart)
ffffffff801088fb:	8b 05 eb c6 08 00    	mov    0x8c6eb(%rip),%eax        # ffffffff80194fec <uart>
ffffffff80108901:	85 c0                	test   %eax,%eax
ffffffff80108903:	75 07                	jne    ffffffff8010890c <uartgetc+0x15>
    return -1;
ffffffff80108905:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff8010890a:	eb 28                	jmp    ffffffff80108934 <uartgetc+0x3d>
  if(!(inb(COM1+5) & 0x01))
ffffffff8010890c:	bf fd 03 00 00       	mov    $0x3fd,%edi
ffffffff80108911:	e8 4e fe ff ff       	callq  ffffffff80108764 <inb>
ffffffff80108916:	0f b6 c0             	movzbl %al,%eax
ffffffff80108919:	83 e0 01             	and    $0x1,%eax
ffffffff8010891c:	85 c0                	test   %eax,%eax
ffffffff8010891e:	75 07                	jne    ffffffff80108927 <uartgetc+0x30>
    return -1;
ffffffff80108920:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80108925:	eb 0d                	jmp    ffffffff80108934 <uartgetc+0x3d>
  return inb(COM1+0);
ffffffff80108927:	bf f8 03 00 00       	mov    $0x3f8,%edi
ffffffff8010892c:	e8 33 fe ff ff       	callq  ffffffff80108764 <inb>
ffffffff80108931:	0f b6 c0             	movzbl %al,%eax
}
ffffffff80108934:	5d                   	pop    %rbp
ffffffff80108935:	c3                   	retq   

ffffffff80108936 <uartintr>:

void
uartintr(void)
{
ffffffff80108936:	55                   	push   %rbp
ffffffff80108937:	48 89 e5             	mov    %rsp,%rbp
  consoleintr(uartgetc);
ffffffff8010893a:	48 c7 c7 f7 88 10 80 	mov    $0xffffffff801088f7,%rdi
ffffffff80108941:	e8 40 82 ff ff       	callq  ffffffff80100b86 <consoleintr>
}
ffffffff80108946:	90                   	nop
ffffffff80108947:	5d                   	pop    %rbp
ffffffff80108948:	c3                   	retq   

ffffffff80108949 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  push $0
ffffffff80108949:	6a 00                	pushq  $0x0
  push $0
ffffffff8010894b:	6a 00                	pushq  $0x0
  jmp alltraps
ffffffff8010894d:	e9 c5 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108952 <vector1>:
.globl vector1
vector1:
  push $0
ffffffff80108952:	6a 00                	pushq  $0x0
  push $1
ffffffff80108954:	6a 01                	pushq  $0x1
  jmp alltraps
ffffffff80108956:	e9 bc fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010895b <vector2>:
.globl vector2
vector2:
  push $0
ffffffff8010895b:	6a 00                	pushq  $0x0
  push $2
ffffffff8010895d:	6a 02                	pushq  $0x2
  jmp alltraps
ffffffff8010895f:	e9 b3 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108964 <vector3>:
.globl vector3
vector3:
  push $0
ffffffff80108964:	6a 00                	pushq  $0x0
  push $3
ffffffff80108966:	6a 03                	pushq  $0x3
  jmp alltraps
ffffffff80108968:	e9 aa fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010896d <vector4>:
.globl vector4
vector4:
  push $0
ffffffff8010896d:	6a 00                	pushq  $0x0
  push $4
ffffffff8010896f:	6a 04                	pushq  $0x4
  jmp alltraps
ffffffff80108971:	e9 a1 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108976 <vector5>:
.globl vector5
vector5:
  push $0
ffffffff80108976:	6a 00                	pushq  $0x0
  push $5
ffffffff80108978:	6a 05                	pushq  $0x5
  jmp alltraps
ffffffff8010897a:	e9 98 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010897f <vector6>:
.globl vector6
vector6:
  push $0
ffffffff8010897f:	6a 00                	pushq  $0x0
  push $6
ffffffff80108981:	6a 06                	pushq  $0x6
  jmp alltraps
ffffffff80108983:	e9 8f fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108988 <vector7>:
.globl vector7
vector7:
  push $0
ffffffff80108988:	6a 00                	pushq  $0x0
  push $7
ffffffff8010898a:	6a 07                	pushq  $0x7
  jmp alltraps
ffffffff8010898c:	e9 86 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108991 <vector8>:
.globl vector8
vector8:
  push $8
ffffffff80108991:	6a 08                	pushq  $0x8
  jmp alltraps
ffffffff80108993:	e9 7f fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108998 <vector9>:
.globl vector9
vector9:
  push $0
ffffffff80108998:	6a 00                	pushq  $0x0
  push $9
ffffffff8010899a:	6a 09                	pushq  $0x9
  jmp alltraps
ffffffff8010899c:	e9 76 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089a1 <vector10>:
.globl vector10
vector10:
  push $10
ffffffff801089a1:	6a 0a                	pushq  $0xa
  jmp alltraps
ffffffff801089a3:	e9 6f fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089a8 <vector11>:
.globl vector11
vector11:
  push $11
ffffffff801089a8:	6a 0b                	pushq  $0xb
  jmp alltraps
ffffffff801089aa:	e9 68 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089af <vector12>:
.globl vector12
vector12:
  push $12
ffffffff801089af:	6a 0c                	pushq  $0xc
  jmp alltraps
ffffffff801089b1:	e9 61 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089b6 <vector13>:
.globl vector13
vector13:
  push $13
ffffffff801089b6:	6a 0d                	pushq  $0xd
  jmp alltraps
ffffffff801089b8:	e9 5a fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089bd <vector14>:
.globl vector14
vector14:
  push $14
ffffffff801089bd:	6a 0e                	pushq  $0xe
  jmp alltraps
ffffffff801089bf:	e9 53 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089c4 <vector15>:
.globl vector15
vector15:
  push $0
ffffffff801089c4:	6a 00                	pushq  $0x0
  push $15
ffffffff801089c6:	6a 0f                	pushq  $0xf
  jmp alltraps
ffffffff801089c8:	e9 4a fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089cd <vector16>:
.globl vector16
vector16:
  push $0
ffffffff801089cd:	6a 00                	pushq  $0x0
  push $16
ffffffff801089cf:	6a 10                	pushq  $0x10
  jmp alltraps
ffffffff801089d1:	e9 41 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089d6 <vector17>:
.globl vector17
vector17:
  push $17
ffffffff801089d6:	6a 11                	pushq  $0x11
  jmp alltraps
ffffffff801089d8:	e9 3a fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089dd <vector18>:
.globl vector18
vector18:
  push $0
ffffffff801089dd:	6a 00                	pushq  $0x0
  push $18
ffffffff801089df:	6a 12                	pushq  $0x12
  jmp alltraps
ffffffff801089e1:	e9 31 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089e6 <vector19>:
.globl vector19
vector19:
  push $0
ffffffff801089e6:	6a 00                	pushq  $0x0
  push $19
ffffffff801089e8:	6a 13                	pushq  $0x13
  jmp alltraps
ffffffff801089ea:	e9 28 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089ef <vector20>:
.globl vector20
vector20:
  push $0
ffffffff801089ef:	6a 00                	pushq  $0x0
  push $20
ffffffff801089f1:	6a 14                	pushq  $0x14
  jmp alltraps
ffffffff801089f3:	e9 1f fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801089f8 <vector21>:
.globl vector21
vector21:
  push $0
ffffffff801089f8:	6a 00                	pushq  $0x0
  push $21
ffffffff801089fa:	6a 15                	pushq  $0x15
  jmp alltraps
ffffffff801089fc:	e9 16 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a01 <vector22>:
.globl vector22
vector22:
  push $0
ffffffff80108a01:	6a 00                	pushq  $0x0
  push $22
ffffffff80108a03:	6a 16                	pushq  $0x16
  jmp alltraps
ffffffff80108a05:	e9 0d fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a0a <vector23>:
.globl vector23
vector23:
  push $0
ffffffff80108a0a:	6a 00                	pushq  $0x0
  push $23
ffffffff80108a0c:	6a 17                	pushq  $0x17
  jmp alltraps
ffffffff80108a0e:	e9 04 fa ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a13 <vector24>:
.globl vector24
vector24:
  push $0
ffffffff80108a13:	6a 00                	pushq  $0x0
  push $24
ffffffff80108a15:	6a 18                	pushq  $0x18
  jmp alltraps
ffffffff80108a17:	e9 fb f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a1c <vector25>:
.globl vector25
vector25:
  push $0
ffffffff80108a1c:	6a 00                	pushq  $0x0
  push $25
ffffffff80108a1e:	6a 19                	pushq  $0x19
  jmp alltraps
ffffffff80108a20:	e9 f2 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a25 <vector26>:
.globl vector26
vector26:
  push $0
ffffffff80108a25:	6a 00                	pushq  $0x0
  push $26
ffffffff80108a27:	6a 1a                	pushq  $0x1a
  jmp alltraps
ffffffff80108a29:	e9 e9 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a2e <vector27>:
.globl vector27
vector27:
  push $0
ffffffff80108a2e:	6a 00                	pushq  $0x0
  push $27
ffffffff80108a30:	6a 1b                	pushq  $0x1b
  jmp alltraps
ffffffff80108a32:	e9 e0 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a37 <vector28>:
.globl vector28
vector28:
  push $0
ffffffff80108a37:	6a 00                	pushq  $0x0
  push $28
ffffffff80108a39:	6a 1c                	pushq  $0x1c
  jmp alltraps
ffffffff80108a3b:	e9 d7 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a40 <vector29>:
.globl vector29
vector29:
  push $0
ffffffff80108a40:	6a 00                	pushq  $0x0
  push $29
ffffffff80108a42:	6a 1d                	pushq  $0x1d
  jmp alltraps
ffffffff80108a44:	e9 ce f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a49 <vector30>:
.globl vector30
vector30:
  push $0
ffffffff80108a49:	6a 00                	pushq  $0x0
  push $30
ffffffff80108a4b:	6a 1e                	pushq  $0x1e
  jmp alltraps
ffffffff80108a4d:	e9 c5 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a52 <vector31>:
.globl vector31
vector31:
  push $0
ffffffff80108a52:	6a 00                	pushq  $0x0
  push $31
ffffffff80108a54:	6a 1f                	pushq  $0x1f
  jmp alltraps
ffffffff80108a56:	e9 bc f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a5b <vector32>:
.globl vector32
vector32:
  push $0
ffffffff80108a5b:	6a 00                	pushq  $0x0
  push $32
ffffffff80108a5d:	6a 20                	pushq  $0x20
  jmp alltraps
ffffffff80108a5f:	e9 b3 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a64 <vector33>:
.globl vector33
vector33:
  push $0
ffffffff80108a64:	6a 00                	pushq  $0x0
  push $33
ffffffff80108a66:	6a 21                	pushq  $0x21
  jmp alltraps
ffffffff80108a68:	e9 aa f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a6d <vector34>:
.globl vector34
vector34:
  push $0
ffffffff80108a6d:	6a 00                	pushq  $0x0
  push $34
ffffffff80108a6f:	6a 22                	pushq  $0x22
  jmp alltraps
ffffffff80108a71:	e9 a1 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a76 <vector35>:
.globl vector35
vector35:
  push $0
ffffffff80108a76:	6a 00                	pushq  $0x0
  push $35
ffffffff80108a78:	6a 23                	pushq  $0x23
  jmp alltraps
ffffffff80108a7a:	e9 98 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a7f <vector36>:
.globl vector36
vector36:
  push $0
ffffffff80108a7f:	6a 00                	pushq  $0x0
  push $36
ffffffff80108a81:	6a 24                	pushq  $0x24
  jmp alltraps
ffffffff80108a83:	e9 8f f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a88 <vector37>:
.globl vector37
vector37:
  push $0
ffffffff80108a88:	6a 00                	pushq  $0x0
  push $37
ffffffff80108a8a:	6a 25                	pushq  $0x25
  jmp alltraps
ffffffff80108a8c:	e9 86 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a91 <vector38>:
.globl vector38
vector38:
  push $0
ffffffff80108a91:	6a 00                	pushq  $0x0
  push $38
ffffffff80108a93:	6a 26                	pushq  $0x26
  jmp alltraps
ffffffff80108a95:	e9 7d f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108a9a <vector39>:
.globl vector39
vector39:
  push $0
ffffffff80108a9a:	6a 00                	pushq  $0x0
  push $39
ffffffff80108a9c:	6a 27                	pushq  $0x27
  jmp alltraps
ffffffff80108a9e:	e9 74 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108aa3 <vector40>:
.globl vector40
vector40:
  push $0
ffffffff80108aa3:	6a 00                	pushq  $0x0
  push $40
ffffffff80108aa5:	6a 28                	pushq  $0x28
  jmp alltraps
ffffffff80108aa7:	e9 6b f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108aac <vector41>:
.globl vector41
vector41:
  push $0
ffffffff80108aac:	6a 00                	pushq  $0x0
  push $41
ffffffff80108aae:	6a 29                	pushq  $0x29
  jmp alltraps
ffffffff80108ab0:	e9 62 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ab5 <vector42>:
.globl vector42
vector42:
  push $0
ffffffff80108ab5:	6a 00                	pushq  $0x0
  push $42
ffffffff80108ab7:	6a 2a                	pushq  $0x2a
  jmp alltraps
ffffffff80108ab9:	e9 59 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108abe <vector43>:
.globl vector43
vector43:
  push $0
ffffffff80108abe:	6a 00                	pushq  $0x0
  push $43
ffffffff80108ac0:	6a 2b                	pushq  $0x2b
  jmp alltraps
ffffffff80108ac2:	e9 50 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ac7 <vector44>:
.globl vector44
vector44:
  push $0
ffffffff80108ac7:	6a 00                	pushq  $0x0
  push $44
ffffffff80108ac9:	6a 2c                	pushq  $0x2c
  jmp alltraps
ffffffff80108acb:	e9 47 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ad0 <vector45>:
.globl vector45
vector45:
  push $0
ffffffff80108ad0:	6a 00                	pushq  $0x0
  push $45
ffffffff80108ad2:	6a 2d                	pushq  $0x2d
  jmp alltraps
ffffffff80108ad4:	e9 3e f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ad9 <vector46>:
.globl vector46
vector46:
  push $0
ffffffff80108ad9:	6a 00                	pushq  $0x0
  push $46
ffffffff80108adb:	6a 2e                	pushq  $0x2e
  jmp alltraps
ffffffff80108add:	e9 35 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ae2 <vector47>:
.globl vector47
vector47:
  push $0
ffffffff80108ae2:	6a 00                	pushq  $0x0
  push $47
ffffffff80108ae4:	6a 2f                	pushq  $0x2f
  jmp alltraps
ffffffff80108ae6:	e9 2c f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108aeb <vector48>:
.globl vector48
vector48:
  push $0
ffffffff80108aeb:	6a 00                	pushq  $0x0
  push $48
ffffffff80108aed:	6a 30                	pushq  $0x30
  jmp alltraps
ffffffff80108aef:	e9 23 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108af4 <vector49>:
.globl vector49
vector49:
  push $0
ffffffff80108af4:	6a 00                	pushq  $0x0
  push $49
ffffffff80108af6:	6a 31                	pushq  $0x31
  jmp alltraps
ffffffff80108af8:	e9 1a f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108afd <vector50>:
.globl vector50
vector50:
  push $0
ffffffff80108afd:	6a 00                	pushq  $0x0
  push $50
ffffffff80108aff:	6a 32                	pushq  $0x32
  jmp alltraps
ffffffff80108b01:	e9 11 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b06 <vector51>:
.globl vector51
vector51:
  push $0
ffffffff80108b06:	6a 00                	pushq  $0x0
  push $51
ffffffff80108b08:	6a 33                	pushq  $0x33
  jmp alltraps
ffffffff80108b0a:	e9 08 f9 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b0f <vector52>:
.globl vector52
vector52:
  push $0
ffffffff80108b0f:	6a 00                	pushq  $0x0
  push $52
ffffffff80108b11:	6a 34                	pushq  $0x34
  jmp alltraps
ffffffff80108b13:	e9 ff f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b18 <vector53>:
.globl vector53
vector53:
  push $0
ffffffff80108b18:	6a 00                	pushq  $0x0
  push $53
ffffffff80108b1a:	6a 35                	pushq  $0x35
  jmp alltraps
ffffffff80108b1c:	e9 f6 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b21 <vector54>:
.globl vector54
vector54:
  push $0
ffffffff80108b21:	6a 00                	pushq  $0x0
  push $54
ffffffff80108b23:	6a 36                	pushq  $0x36
  jmp alltraps
ffffffff80108b25:	e9 ed f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b2a <vector55>:
.globl vector55
vector55:
  push $0
ffffffff80108b2a:	6a 00                	pushq  $0x0
  push $55
ffffffff80108b2c:	6a 37                	pushq  $0x37
  jmp alltraps
ffffffff80108b2e:	e9 e4 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b33 <vector56>:
.globl vector56
vector56:
  push $0
ffffffff80108b33:	6a 00                	pushq  $0x0
  push $56
ffffffff80108b35:	6a 38                	pushq  $0x38
  jmp alltraps
ffffffff80108b37:	e9 db f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b3c <vector57>:
.globl vector57
vector57:
  push $0
ffffffff80108b3c:	6a 00                	pushq  $0x0
  push $57
ffffffff80108b3e:	6a 39                	pushq  $0x39
  jmp alltraps
ffffffff80108b40:	e9 d2 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b45 <vector58>:
.globl vector58
vector58:
  push $0
ffffffff80108b45:	6a 00                	pushq  $0x0
  push $58
ffffffff80108b47:	6a 3a                	pushq  $0x3a
  jmp alltraps
ffffffff80108b49:	e9 c9 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b4e <vector59>:
.globl vector59
vector59:
  push $0
ffffffff80108b4e:	6a 00                	pushq  $0x0
  push $59
ffffffff80108b50:	6a 3b                	pushq  $0x3b
  jmp alltraps
ffffffff80108b52:	e9 c0 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b57 <vector60>:
.globl vector60
vector60:
  push $0
ffffffff80108b57:	6a 00                	pushq  $0x0
  push $60
ffffffff80108b59:	6a 3c                	pushq  $0x3c
  jmp alltraps
ffffffff80108b5b:	e9 b7 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b60 <vector61>:
.globl vector61
vector61:
  push $0
ffffffff80108b60:	6a 00                	pushq  $0x0
  push $61
ffffffff80108b62:	6a 3d                	pushq  $0x3d
  jmp alltraps
ffffffff80108b64:	e9 ae f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b69 <vector62>:
.globl vector62
vector62:
  push $0
ffffffff80108b69:	6a 00                	pushq  $0x0
  push $62
ffffffff80108b6b:	6a 3e                	pushq  $0x3e
  jmp alltraps
ffffffff80108b6d:	e9 a5 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b72 <vector63>:
.globl vector63
vector63:
  push $0
ffffffff80108b72:	6a 00                	pushq  $0x0
  push $63
ffffffff80108b74:	6a 3f                	pushq  $0x3f
  jmp alltraps
ffffffff80108b76:	e9 9c f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b7b <vector64>:
.globl vector64
vector64:
  push $0
ffffffff80108b7b:	6a 00                	pushq  $0x0
  push $64
ffffffff80108b7d:	6a 40                	pushq  $0x40
  jmp alltraps
ffffffff80108b7f:	e9 93 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b84 <vector65>:
.globl vector65
vector65:
  push $0
ffffffff80108b84:	6a 00                	pushq  $0x0
  push $65
ffffffff80108b86:	6a 41                	pushq  $0x41
  jmp alltraps
ffffffff80108b88:	e9 8a f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b8d <vector66>:
.globl vector66
vector66:
  push $0
ffffffff80108b8d:	6a 00                	pushq  $0x0
  push $66
ffffffff80108b8f:	6a 42                	pushq  $0x42
  jmp alltraps
ffffffff80108b91:	e9 81 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b96 <vector67>:
.globl vector67
vector67:
  push $0
ffffffff80108b96:	6a 00                	pushq  $0x0
  push $67
ffffffff80108b98:	6a 43                	pushq  $0x43
  jmp alltraps
ffffffff80108b9a:	e9 78 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108b9f <vector68>:
.globl vector68
vector68:
  push $0
ffffffff80108b9f:	6a 00                	pushq  $0x0
  push $68
ffffffff80108ba1:	6a 44                	pushq  $0x44
  jmp alltraps
ffffffff80108ba3:	e9 6f f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ba8 <vector69>:
.globl vector69
vector69:
  push $0
ffffffff80108ba8:	6a 00                	pushq  $0x0
  push $69
ffffffff80108baa:	6a 45                	pushq  $0x45
  jmp alltraps
ffffffff80108bac:	e9 66 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108bb1 <vector70>:
.globl vector70
vector70:
  push $0
ffffffff80108bb1:	6a 00                	pushq  $0x0
  push $70
ffffffff80108bb3:	6a 46                	pushq  $0x46
  jmp alltraps
ffffffff80108bb5:	e9 5d f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108bba <vector71>:
.globl vector71
vector71:
  push $0
ffffffff80108bba:	6a 00                	pushq  $0x0
  push $71
ffffffff80108bbc:	6a 47                	pushq  $0x47
  jmp alltraps
ffffffff80108bbe:	e9 54 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108bc3 <vector72>:
.globl vector72
vector72:
  push $0
ffffffff80108bc3:	6a 00                	pushq  $0x0
  push $72
ffffffff80108bc5:	6a 48                	pushq  $0x48
  jmp alltraps
ffffffff80108bc7:	e9 4b f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108bcc <vector73>:
.globl vector73
vector73:
  push $0
ffffffff80108bcc:	6a 00                	pushq  $0x0
  push $73
ffffffff80108bce:	6a 49                	pushq  $0x49
  jmp alltraps
ffffffff80108bd0:	e9 42 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108bd5 <vector74>:
.globl vector74
vector74:
  push $0
ffffffff80108bd5:	6a 00                	pushq  $0x0
  push $74
ffffffff80108bd7:	6a 4a                	pushq  $0x4a
  jmp alltraps
ffffffff80108bd9:	e9 39 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108bde <vector75>:
.globl vector75
vector75:
  push $0
ffffffff80108bde:	6a 00                	pushq  $0x0
  push $75
ffffffff80108be0:	6a 4b                	pushq  $0x4b
  jmp alltraps
ffffffff80108be2:	e9 30 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108be7 <vector76>:
.globl vector76
vector76:
  push $0
ffffffff80108be7:	6a 00                	pushq  $0x0
  push $76
ffffffff80108be9:	6a 4c                	pushq  $0x4c
  jmp alltraps
ffffffff80108beb:	e9 27 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108bf0 <vector77>:
.globl vector77
vector77:
  push $0
ffffffff80108bf0:	6a 00                	pushq  $0x0
  push $77
ffffffff80108bf2:	6a 4d                	pushq  $0x4d
  jmp alltraps
ffffffff80108bf4:	e9 1e f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108bf9 <vector78>:
.globl vector78
vector78:
  push $0
ffffffff80108bf9:	6a 00                	pushq  $0x0
  push $78
ffffffff80108bfb:	6a 4e                	pushq  $0x4e
  jmp alltraps
ffffffff80108bfd:	e9 15 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c02 <vector79>:
.globl vector79
vector79:
  push $0
ffffffff80108c02:	6a 00                	pushq  $0x0
  push $79
ffffffff80108c04:	6a 4f                	pushq  $0x4f
  jmp alltraps
ffffffff80108c06:	e9 0c f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c0b <vector80>:
.globl vector80
vector80:
  push $0
ffffffff80108c0b:	6a 00                	pushq  $0x0
  push $80
ffffffff80108c0d:	6a 50                	pushq  $0x50
  jmp alltraps
ffffffff80108c0f:	e9 03 f8 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c14 <vector81>:
.globl vector81
vector81:
  push $0
ffffffff80108c14:	6a 00                	pushq  $0x0
  push $81
ffffffff80108c16:	6a 51                	pushq  $0x51
  jmp alltraps
ffffffff80108c18:	e9 fa f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c1d <vector82>:
.globl vector82
vector82:
  push $0
ffffffff80108c1d:	6a 00                	pushq  $0x0
  push $82
ffffffff80108c1f:	6a 52                	pushq  $0x52
  jmp alltraps
ffffffff80108c21:	e9 f1 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c26 <vector83>:
.globl vector83
vector83:
  push $0
ffffffff80108c26:	6a 00                	pushq  $0x0
  push $83
ffffffff80108c28:	6a 53                	pushq  $0x53
  jmp alltraps
ffffffff80108c2a:	e9 e8 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c2f <vector84>:
.globl vector84
vector84:
  push $0
ffffffff80108c2f:	6a 00                	pushq  $0x0
  push $84
ffffffff80108c31:	6a 54                	pushq  $0x54
  jmp alltraps
ffffffff80108c33:	e9 df f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c38 <vector85>:
.globl vector85
vector85:
  push $0
ffffffff80108c38:	6a 00                	pushq  $0x0
  push $85
ffffffff80108c3a:	6a 55                	pushq  $0x55
  jmp alltraps
ffffffff80108c3c:	e9 d6 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c41 <vector86>:
.globl vector86
vector86:
  push $0
ffffffff80108c41:	6a 00                	pushq  $0x0
  push $86
ffffffff80108c43:	6a 56                	pushq  $0x56
  jmp alltraps
ffffffff80108c45:	e9 cd f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c4a <vector87>:
.globl vector87
vector87:
  push $0
ffffffff80108c4a:	6a 00                	pushq  $0x0
  push $87
ffffffff80108c4c:	6a 57                	pushq  $0x57
  jmp alltraps
ffffffff80108c4e:	e9 c4 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c53 <vector88>:
.globl vector88
vector88:
  push $0
ffffffff80108c53:	6a 00                	pushq  $0x0
  push $88
ffffffff80108c55:	6a 58                	pushq  $0x58
  jmp alltraps
ffffffff80108c57:	e9 bb f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c5c <vector89>:
.globl vector89
vector89:
  push $0
ffffffff80108c5c:	6a 00                	pushq  $0x0
  push $89
ffffffff80108c5e:	6a 59                	pushq  $0x59
  jmp alltraps
ffffffff80108c60:	e9 b2 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c65 <vector90>:
.globl vector90
vector90:
  push $0
ffffffff80108c65:	6a 00                	pushq  $0x0
  push $90
ffffffff80108c67:	6a 5a                	pushq  $0x5a
  jmp alltraps
ffffffff80108c69:	e9 a9 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c6e <vector91>:
.globl vector91
vector91:
  push $0
ffffffff80108c6e:	6a 00                	pushq  $0x0
  push $91
ffffffff80108c70:	6a 5b                	pushq  $0x5b
  jmp alltraps
ffffffff80108c72:	e9 a0 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c77 <vector92>:
.globl vector92
vector92:
  push $0
ffffffff80108c77:	6a 00                	pushq  $0x0
  push $92
ffffffff80108c79:	6a 5c                	pushq  $0x5c
  jmp alltraps
ffffffff80108c7b:	e9 97 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c80 <vector93>:
.globl vector93
vector93:
  push $0
ffffffff80108c80:	6a 00                	pushq  $0x0
  push $93
ffffffff80108c82:	6a 5d                	pushq  $0x5d
  jmp alltraps
ffffffff80108c84:	e9 8e f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c89 <vector94>:
.globl vector94
vector94:
  push $0
ffffffff80108c89:	6a 00                	pushq  $0x0
  push $94
ffffffff80108c8b:	6a 5e                	pushq  $0x5e
  jmp alltraps
ffffffff80108c8d:	e9 85 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c92 <vector95>:
.globl vector95
vector95:
  push $0
ffffffff80108c92:	6a 00                	pushq  $0x0
  push $95
ffffffff80108c94:	6a 5f                	pushq  $0x5f
  jmp alltraps
ffffffff80108c96:	e9 7c f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108c9b <vector96>:
.globl vector96
vector96:
  push $0
ffffffff80108c9b:	6a 00                	pushq  $0x0
  push $96
ffffffff80108c9d:	6a 60                	pushq  $0x60
  jmp alltraps
ffffffff80108c9f:	e9 73 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ca4 <vector97>:
.globl vector97
vector97:
  push $0
ffffffff80108ca4:	6a 00                	pushq  $0x0
  push $97
ffffffff80108ca6:	6a 61                	pushq  $0x61
  jmp alltraps
ffffffff80108ca8:	e9 6a f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108cad <vector98>:
.globl vector98
vector98:
  push $0
ffffffff80108cad:	6a 00                	pushq  $0x0
  push $98
ffffffff80108caf:	6a 62                	pushq  $0x62
  jmp alltraps
ffffffff80108cb1:	e9 61 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108cb6 <vector99>:
.globl vector99
vector99:
  push $0
ffffffff80108cb6:	6a 00                	pushq  $0x0
  push $99
ffffffff80108cb8:	6a 63                	pushq  $0x63
  jmp alltraps
ffffffff80108cba:	e9 58 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108cbf <vector100>:
.globl vector100
vector100:
  push $0
ffffffff80108cbf:	6a 00                	pushq  $0x0
  push $100
ffffffff80108cc1:	6a 64                	pushq  $0x64
  jmp alltraps
ffffffff80108cc3:	e9 4f f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108cc8 <vector101>:
.globl vector101
vector101:
  push $0
ffffffff80108cc8:	6a 00                	pushq  $0x0
  push $101
ffffffff80108cca:	6a 65                	pushq  $0x65
  jmp alltraps
ffffffff80108ccc:	e9 46 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108cd1 <vector102>:
.globl vector102
vector102:
  push $0
ffffffff80108cd1:	6a 00                	pushq  $0x0
  push $102
ffffffff80108cd3:	6a 66                	pushq  $0x66
  jmp alltraps
ffffffff80108cd5:	e9 3d f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108cda <vector103>:
.globl vector103
vector103:
  push $0
ffffffff80108cda:	6a 00                	pushq  $0x0
  push $103
ffffffff80108cdc:	6a 67                	pushq  $0x67
  jmp alltraps
ffffffff80108cde:	e9 34 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ce3 <vector104>:
.globl vector104
vector104:
  push $0
ffffffff80108ce3:	6a 00                	pushq  $0x0
  push $104
ffffffff80108ce5:	6a 68                	pushq  $0x68
  jmp alltraps
ffffffff80108ce7:	e9 2b f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108cec <vector105>:
.globl vector105
vector105:
  push $0
ffffffff80108cec:	6a 00                	pushq  $0x0
  push $105
ffffffff80108cee:	6a 69                	pushq  $0x69
  jmp alltraps
ffffffff80108cf0:	e9 22 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108cf5 <vector106>:
.globl vector106
vector106:
  push $0
ffffffff80108cf5:	6a 00                	pushq  $0x0
  push $106
ffffffff80108cf7:	6a 6a                	pushq  $0x6a
  jmp alltraps
ffffffff80108cf9:	e9 19 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108cfe <vector107>:
.globl vector107
vector107:
  push $0
ffffffff80108cfe:	6a 00                	pushq  $0x0
  push $107
ffffffff80108d00:	6a 6b                	pushq  $0x6b
  jmp alltraps
ffffffff80108d02:	e9 10 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d07 <vector108>:
.globl vector108
vector108:
  push $0
ffffffff80108d07:	6a 00                	pushq  $0x0
  push $108
ffffffff80108d09:	6a 6c                	pushq  $0x6c
  jmp alltraps
ffffffff80108d0b:	e9 07 f7 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d10 <vector109>:
.globl vector109
vector109:
  push $0
ffffffff80108d10:	6a 00                	pushq  $0x0
  push $109
ffffffff80108d12:	6a 6d                	pushq  $0x6d
  jmp alltraps
ffffffff80108d14:	e9 fe f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d19 <vector110>:
.globl vector110
vector110:
  push $0
ffffffff80108d19:	6a 00                	pushq  $0x0
  push $110
ffffffff80108d1b:	6a 6e                	pushq  $0x6e
  jmp alltraps
ffffffff80108d1d:	e9 f5 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d22 <vector111>:
.globl vector111
vector111:
  push $0
ffffffff80108d22:	6a 00                	pushq  $0x0
  push $111
ffffffff80108d24:	6a 6f                	pushq  $0x6f
  jmp alltraps
ffffffff80108d26:	e9 ec f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d2b <vector112>:
.globl vector112
vector112:
  push $0
ffffffff80108d2b:	6a 00                	pushq  $0x0
  push $112
ffffffff80108d2d:	6a 70                	pushq  $0x70
  jmp alltraps
ffffffff80108d2f:	e9 e3 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d34 <vector113>:
.globl vector113
vector113:
  push $0
ffffffff80108d34:	6a 00                	pushq  $0x0
  push $113
ffffffff80108d36:	6a 71                	pushq  $0x71
  jmp alltraps
ffffffff80108d38:	e9 da f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d3d <vector114>:
.globl vector114
vector114:
  push $0
ffffffff80108d3d:	6a 00                	pushq  $0x0
  push $114
ffffffff80108d3f:	6a 72                	pushq  $0x72
  jmp alltraps
ffffffff80108d41:	e9 d1 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d46 <vector115>:
.globl vector115
vector115:
  push $0
ffffffff80108d46:	6a 00                	pushq  $0x0
  push $115
ffffffff80108d48:	6a 73                	pushq  $0x73
  jmp alltraps
ffffffff80108d4a:	e9 c8 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d4f <vector116>:
.globl vector116
vector116:
  push $0
ffffffff80108d4f:	6a 00                	pushq  $0x0
  push $116
ffffffff80108d51:	6a 74                	pushq  $0x74
  jmp alltraps
ffffffff80108d53:	e9 bf f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d58 <vector117>:
.globl vector117
vector117:
  push $0
ffffffff80108d58:	6a 00                	pushq  $0x0
  push $117
ffffffff80108d5a:	6a 75                	pushq  $0x75
  jmp alltraps
ffffffff80108d5c:	e9 b6 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d61 <vector118>:
.globl vector118
vector118:
  push $0
ffffffff80108d61:	6a 00                	pushq  $0x0
  push $118
ffffffff80108d63:	6a 76                	pushq  $0x76
  jmp alltraps
ffffffff80108d65:	e9 ad f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d6a <vector119>:
.globl vector119
vector119:
  push $0
ffffffff80108d6a:	6a 00                	pushq  $0x0
  push $119
ffffffff80108d6c:	6a 77                	pushq  $0x77
  jmp alltraps
ffffffff80108d6e:	e9 a4 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d73 <vector120>:
.globl vector120
vector120:
  push $0
ffffffff80108d73:	6a 00                	pushq  $0x0
  push $120
ffffffff80108d75:	6a 78                	pushq  $0x78
  jmp alltraps
ffffffff80108d77:	e9 9b f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d7c <vector121>:
.globl vector121
vector121:
  push $0
ffffffff80108d7c:	6a 00                	pushq  $0x0
  push $121
ffffffff80108d7e:	6a 79                	pushq  $0x79
  jmp alltraps
ffffffff80108d80:	e9 92 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d85 <vector122>:
.globl vector122
vector122:
  push $0
ffffffff80108d85:	6a 00                	pushq  $0x0
  push $122
ffffffff80108d87:	6a 7a                	pushq  $0x7a
  jmp alltraps
ffffffff80108d89:	e9 89 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d8e <vector123>:
.globl vector123
vector123:
  push $0
ffffffff80108d8e:	6a 00                	pushq  $0x0
  push $123
ffffffff80108d90:	6a 7b                	pushq  $0x7b
  jmp alltraps
ffffffff80108d92:	e9 80 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108d97 <vector124>:
.globl vector124
vector124:
  push $0
ffffffff80108d97:	6a 00                	pushq  $0x0
  push $124
ffffffff80108d99:	6a 7c                	pushq  $0x7c
  jmp alltraps
ffffffff80108d9b:	e9 77 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108da0 <vector125>:
.globl vector125
vector125:
  push $0
ffffffff80108da0:	6a 00                	pushq  $0x0
  push $125
ffffffff80108da2:	6a 7d                	pushq  $0x7d
  jmp alltraps
ffffffff80108da4:	e9 6e f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108da9 <vector126>:
.globl vector126
vector126:
  push $0
ffffffff80108da9:	6a 00                	pushq  $0x0
  push $126
ffffffff80108dab:	6a 7e                	pushq  $0x7e
  jmp alltraps
ffffffff80108dad:	e9 65 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108db2 <vector127>:
.globl vector127
vector127:
  push $0
ffffffff80108db2:	6a 00                	pushq  $0x0
  push $127
ffffffff80108db4:	6a 7f                	pushq  $0x7f
  jmp alltraps
ffffffff80108db6:	e9 5c f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108dbb <vector128>:
.globl vector128
vector128:
  push $0
ffffffff80108dbb:	6a 00                	pushq  $0x0
  push $128
ffffffff80108dbd:	68 80 00 00 00       	pushq  $0x80
  jmp alltraps
ffffffff80108dc2:	e9 50 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108dc7 <vector129>:
.globl vector129
vector129:
  push $0
ffffffff80108dc7:	6a 00                	pushq  $0x0
  push $129
ffffffff80108dc9:	68 81 00 00 00       	pushq  $0x81
  jmp alltraps
ffffffff80108dce:	e9 44 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108dd3 <vector130>:
.globl vector130
vector130:
  push $0
ffffffff80108dd3:	6a 00                	pushq  $0x0
  push $130
ffffffff80108dd5:	68 82 00 00 00       	pushq  $0x82
  jmp alltraps
ffffffff80108dda:	e9 38 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ddf <vector131>:
.globl vector131
vector131:
  push $0
ffffffff80108ddf:	6a 00                	pushq  $0x0
  push $131
ffffffff80108de1:	68 83 00 00 00       	pushq  $0x83
  jmp alltraps
ffffffff80108de6:	e9 2c f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108deb <vector132>:
.globl vector132
vector132:
  push $0
ffffffff80108deb:	6a 00                	pushq  $0x0
  push $132
ffffffff80108ded:	68 84 00 00 00       	pushq  $0x84
  jmp alltraps
ffffffff80108df2:	e9 20 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108df7 <vector133>:
.globl vector133
vector133:
  push $0
ffffffff80108df7:	6a 00                	pushq  $0x0
  push $133
ffffffff80108df9:	68 85 00 00 00       	pushq  $0x85
  jmp alltraps
ffffffff80108dfe:	e9 14 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e03 <vector134>:
.globl vector134
vector134:
  push $0
ffffffff80108e03:	6a 00                	pushq  $0x0
  push $134
ffffffff80108e05:	68 86 00 00 00       	pushq  $0x86
  jmp alltraps
ffffffff80108e0a:	e9 08 f6 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e0f <vector135>:
.globl vector135
vector135:
  push $0
ffffffff80108e0f:	6a 00                	pushq  $0x0
  push $135
ffffffff80108e11:	68 87 00 00 00       	pushq  $0x87
  jmp alltraps
ffffffff80108e16:	e9 fc f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e1b <vector136>:
.globl vector136
vector136:
  push $0
ffffffff80108e1b:	6a 00                	pushq  $0x0
  push $136
ffffffff80108e1d:	68 88 00 00 00       	pushq  $0x88
  jmp alltraps
ffffffff80108e22:	e9 f0 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e27 <vector137>:
.globl vector137
vector137:
  push $0
ffffffff80108e27:	6a 00                	pushq  $0x0
  push $137
ffffffff80108e29:	68 89 00 00 00       	pushq  $0x89
  jmp alltraps
ffffffff80108e2e:	e9 e4 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e33 <vector138>:
.globl vector138
vector138:
  push $0
ffffffff80108e33:	6a 00                	pushq  $0x0
  push $138
ffffffff80108e35:	68 8a 00 00 00       	pushq  $0x8a
  jmp alltraps
ffffffff80108e3a:	e9 d8 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e3f <vector139>:
.globl vector139
vector139:
  push $0
ffffffff80108e3f:	6a 00                	pushq  $0x0
  push $139
ffffffff80108e41:	68 8b 00 00 00       	pushq  $0x8b
  jmp alltraps
ffffffff80108e46:	e9 cc f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e4b <vector140>:
.globl vector140
vector140:
  push $0
ffffffff80108e4b:	6a 00                	pushq  $0x0
  push $140
ffffffff80108e4d:	68 8c 00 00 00       	pushq  $0x8c
  jmp alltraps
ffffffff80108e52:	e9 c0 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e57 <vector141>:
.globl vector141
vector141:
  push $0
ffffffff80108e57:	6a 00                	pushq  $0x0
  push $141
ffffffff80108e59:	68 8d 00 00 00       	pushq  $0x8d
  jmp alltraps
ffffffff80108e5e:	e9 b4 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e63 <vector142>:
.globl vector142
vector142:
  push $0
ffffffff80108e63:	6a 00                	pushq  $0x0
  push $142
ffffffff80108e65:	68 8e 00 00 00       	pushq  $0x8e
  jmp alltraps
ffffffff80108e6a:	e9 a8 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e6f <vector143>:
.globl vector143
vector143:
  push $0
ffffffff80108e6f:	6a 00                	pushq  $0x0
  push $143
ffffffff80108e71:	68 8f 00 00 00       	pushq  $0x8f
  jmp alltraps
ffffffff80108e76:	e9 9c f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e7b <vector144>:
.globl vector144
vector144:
  push $0
ffffffff80108e7b:	6a 00                	pushq  $0x0
  push $144
ffffffff80108e7d:	68 90 00 00 00       	pushq  $0x90
  jmp alltraps
ffffffff80108e82:	e9 90 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e87 <vector145>:
.globl vector145
vector145:
  push $0
ffffffff80108e87:	6a 00                	pushq  $0x0
  push $145
ffffffff80108e89:	68 91 00 00 00       	pushq  $0x91
  jmp alltraps
ffffffff80108e8e:	e9 84 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e93 <vector146>:
.globl vector146
vector146:
  push $0
ffffffff80108e93:	6a 00                	pushq  $0x0
  push $146
ffffffff80108e95:	68 92 00 00 00       	pushq  $0x92
  jmp alltraps
ffffffff80108e9a:	e9 78 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108e9f <vector147>:
.globl vector147
vector147:
  push $0
ffffffff80108e9f:	6a 00                	pushq  $0x0
  push $147
ffffffff80108ea1:	68 93 00 00 00       	pushq  $0x93
  jmp alltraps
ffffffff80108ea6:	e9 6c f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108eab <vector148>:
.globl vector148
vector148:
  push $0
ffffffff80108eab:	6a 00                	pushq  $0x0
  push $148
ffffffff80108ead:	68 94 00 00 00       	pushq  $0x94
  jmp alltraps
ffffffff80108eb2:	e9 60 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108eb7 <vector149>:
.globl vector149
vector149:
  push $0
ffffffff80108eb7:	6a 00                	pushq  $0x0
  push $149
ffffffff80108eb9:	68 95 00 00 00       	pushq  $0x95
  jmp alltraps
ffffffff80108ebe:	e9 54 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ec3 <vector150>:
.globl vector150
vector150:
  push $0
ffffffff80108ec3:	6a 00                	pushq  $0x0
  push $150
ffffffff80108ec5:	68 96 00 00 00       	pushq  $0x96
  jmp alltraps
ffffffff80108eca:	e9 48 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ecf <vector151>:
.globl vector151
vector151:
  push $0
ffffffff80108ecf:	6a 00                	pushq  $0x0
  push $151
ffffffff80108ed1:	68 97 00 00 00       	pushq  $0x97
  jmp alltraps
ffffffff80108ed6:	e9 3c f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108edb <vector152>:
.globl vector152
vector152:
  push $0
ffffffff80108edb:	6a 00                	pushq  $0x0
  push $152
ffffffff80108edd:	68 98 00 00 00       	pushq  $0x98
  jmp alltraps
ffffffff80108ee2:	e9 30 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ee7 <vector153>:
.globl vector153
vector153:
  push $0
ffffffff80108ee7:	6a 00                	pushq  $0x0
  push $153
ffffffff80108ee9:	68 99 00 00 00       	pushq  $0x99
  jmp alltraps
ffffffff80108eee:	e9 24 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ef3 <vector154>:
.globl vector154
vector154:
  push $0
ffffffff80108ef3:	6a 00                	pushq  $0x0
  push $154
ffffffff80108ef5:	68 9a 00 00 00       	pushq  $0x9a
  jmp alltraps
ffffffff80108efa:	e9 18 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108eff <vector155>:
.globl vector155
vector155:
  push $0
ffffffff80108eff:	6a 00                	pushq  $0x0
  push $155
ffffffff80108f01:	68 9b 00 00 00       	pushq  $0x9b
  jmp alltraps
ffffffff80108f06:	e9 0c f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f0b <vector156>:
.globl vector156
vector156:
  push $0
ffffffff80108f0b:	6a 00                	pushq  $0x0
  push $156
ffffffff80108f0d:	68 9c 00 00 00       	pushq  $0x9c
  jmp alltraps
ffffffff80108f12:	e9 00 f5 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f17 <vector157>:
.globl vector157
vector157:
  push $0
ffffffff80108f17:	6a 00                	pushq  $0x0
  push $157
ffffffff80108f19:	68 9d 00 00 00       	pushq  $0x9d
  jmp alltraps
ffffffff80108f1e:	e9 f4 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f23 <vector158>:
.globl vector158
vector158:
  push $0
ffffffff80108f23:	6a 00                	pushq  $0x0
  push $158
ffffffff80108f25:	68 9e 00 00 00       	pushq  $0x9e
  jmp alltraps
ffffffff80108f2a:	e9 e8 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f2f <vector159>:
.globl vector159
vector159:
  push $0
ffffffff80108f2f:	6a 00                	pushq  $0x0
  push $159
ffffffff80108f31:	68 9f 00 00 00       	pushq  $0x9f
  jmp alltraps
ffffffff80108f36:	e9 dc f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f3b <vector160>:
.globl vector160
vector160:
  push $0
ffffffff80108f3b:	6a 00                	pushq  $0x0
  push $160
ffffffff80108f3d:	68 a0 00 00 00       	pushq  $0xa0
  jmp alltraps
ffffffff80108f42:	e9 d0 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f47 <vector161>:
.globl vector161
vector161:
  push $0
ffffffff80108f47:	6a 00                	pushq  $0x0
  push $161
ffffffff80108f49:	68 a1 00 00 00       	pushq  $0xa1
  jmp alltraps
ffffffff80108f4e:	e9 c4 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f53 <vector162>:
.globl vector162
vector162:
  push $0
ffffffff80108f53:	6a 00                	pushq  $0x0
  push $162
ffffffff80108f55:	68 a2 00 00 00       	pushq  $0xa2
  jmp alltraps
ffffffff80108f5a:	e9 b8 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f5f <vector163>:
.globl vector163
vector163:
  push $0
ffffffff80108f5f:	6a 00                	pushq  $0x0
  push $163
ffffffff80108f61:	68 a3 00 00 00       	pushq  $0xa3
  jmp alltraps
ffffffff80108f66:	e9 ac f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f6b <vector164>:
.globl vector164
vector164:
  push $0
ffffffff80108f6b:	6a 00                	pushq  $0x0
  push $164
ffffffff80108f6d:	68 a4 00 00 00       	pushq  $0xa4
  jmp alltraps
ffffffff80108f72:	e9 a0 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f77 <vector165>:
.globl vector165
vector165:
  push $0
ffffffff80108f77:	6a 00                	pushq  $0x0
  push $165
ffffffff80108f79:	68 a5 00 00 00       	pushq  $0xa5
  jmp alltraps
ffffffff80108f7e:	e9 94 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f83 <vector166>:
.globl vector166
vector166:
  push $0
ffffffff80108f83:	6a 00                	pushq  $0x0
  push $166
ffffffff80108f85:	68 a6 00 00 00       	pushq  $0xa6
  jmp alltraps
ffffffff80108f8a:	e9 88 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f8f <vector167>:
.globl vector167
vector167:
  push $0
ffffffff80108f8f:	6a 00                	pushq  $0x0
  push $167
ffffffff80108f91:	68 a7 00 00 00       	pushq  $0xa7
  jmp alltraps
ffffffff80108f96:	e9 7c f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108f9b <vector168>:
.globl vector168
vector168:
  push $0
ffffffff80108f9b:	6a 00                	pushq  $0x0
  push $168
ffffffff80108f9d:	68 a8 00 00 00       	pushq  $0xa8
  jmp alltraps
ffffffff80108fa2:	e9 70 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108fa7 <vector169>:
.globl vector169
vector169:
  push $0
ffffffff80108fa7:	6a 00                	pushq  $0x0
  push $169
ffffffff80108fa9:	68 a9 00 00 00       	pushq  $0xa9
  jmp alltraps
ffffffff80108fae:	e9 64 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108fb3 <vector170>:
.globl vector170
vector170:
  push $0
ffffffff80108fb3:	6a 00                	pushq  $0x0
  push $170
ffffffff80108fb5:	68 aa 00 00 00       	pushq  $0xaa
  jmp alltraps
ffffffff80108fba:	e9 58 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108fbf <vector171>:
.globl vector171
vector171:
  push $0
ffffffff80108fbf:	6a 00                	pushq  $0x0
  push $171
ffffffff80108fc1:	68 ab 00 00 00       	pushq  $0xab
  jmp alltraps
ffffffff80108fc6:	e9 4c f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108fcb <vector172>:
.globl vector172
vector172:
  push $0
ffffffff80108fcb:	6a 00                	pushq  $0x0
  push $172
ffffffff80108fcd:	68 ac 00 00 00       	pushq  $0xac
  jmp alltraps
ffffffff80108fd2:	e9 40 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108fd7 <vector173>:
.globl vector173
vector173:
  push $0
ffffffff80108fd7:	6a 00                	pushq  $0x0
  push $173
ffffffff80108fd9:	68 ad 00 00 00       	pushq  $0xad
  jmp alltraps
ffffffff80108fde:	e9 34 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108fe3 <vector174>:
.globl vector174
vector174:
  push $0
ffffffff80108fe3:	6a 00                	pushq  $0x0
  push $174
ffffffff80108fe5:	68 ae 00 00 00       	pushq  $0xae
  jmp alltraps
ffffffff80108fea:	e9 28 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108fef <vector175>:
.globl vector175
vector175:
  push $0
ffffffff80108fef:	6a 00                	pushq  $0x0
  push $175
ffffffff80108ff1:	68 af 00 00 00       	pushq  $0xaf
  jmp alltraps
ffffffff80108ff6:	e9 1c f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80108ffb <vector176>:
.globl vector176
vector176:
  push $0
ffffffff80108ffb:	6a 00                	pushq  $0x0
  push $176
ffffffff80108ffd:	68 b0 00 00 00       	pushq  $0xb0
  jmp alltraps
ffffffff80109002:	e9 10 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109007 <vector177>:
.globl vector177
vector177:
  push $0
ffffffff80109007:	6a 00                	pushq  $0x0
  push $177
ffffffff80109009:	68 b1 00 00 00       	pushq  $0xb1
  jmp alltraps
ffffffff8010900e:	e9 04 f4 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109013 <vector178>:
.globl vector178
vector178:
  push $0
ffffffff80109013:	6a 00                	pushq  $0x0
  push $178
ffffffff80109015:	68 b2 00 00 00       	pushq  $0xb2
  jmp alltraps
ffffffff8010901a:	e9 f8 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010901f <vector179>:
.globl vector179
vector179:
  push $0
ffffffff8010901f:	6a 00                	pushq  $0x0
  push $179
ffffffff80109021:	68 b3 00 00 00       	pushq  $0xb3
  jmp alltraps
ffffffff80109026:	e9 ec f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010902b <vector180>:
.globl vector180
vector180:
  push $0
ffffffff8010902b:	6a 00                	pushq  $0x0
  push $180
ffffffff8010902d:	68 b4 00 00 00       	pushq  $0xb4
  jmp alltraps
ffffffff80109032:	e9 e0 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109037 <vector181>:
.globl vector181
vector181:
  push $0
ffffffff80109037:	6a 00                	pushq  $0x0
  push $181
ffffffff80109039:	68 b5 00 00 00       	pushq  $0xb5
  jmp alltraps
ffffffff8010903e:	e9 d4 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109043 <vector182>:
.globl vector182
vector182:
  push $0
ffffffff80109043:	6a 00                	pushq  $0x0
  push $182
ffffffff80109045:	68 b6 00 00 00       	pushq  $0xb6
  jmp alltraps
ffffffff8010904a:	e9 c8 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010904f <vector183>:
.globl vector183
vector183:
  push $0
ffffffff8010904f:	6a 00                	pushq  $0x0
  push $183
ffffffff80109051:	68 b7 00 00 00       	pushq  $0xb7
  jmp alltraps
ffffffff80109056:	e9 bc f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010905b <vector184>:
.globl vector184
vector184:
  push $0
ffffffff8010905b:	6a 00                	pushq  $0x0
  push $184
ffffffff8010905d:	68 b8 00 00 00       	pushq  $0xb8
  jmp alltraps
ffffffff80109062:	e9 b0 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109067 <vector185>:
.globl vector185
vector185:
  push $0
ffffffff80109067:	6a 00                	pushq  $0x0
  push $185
ffffffff80109069:	68 b9 00 00 00       	pushq  $0xb9
  jmp alltraps
ffffffff8010906e:	e9 a4 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109073 <vector186>:
.globl vector186
vector186:
  push $0
ffffffff80109073:	6a 00                	pushq  $0x0
  push $186
ffffffff80109075:	68 ba 00 00 00       	pushq  $0xba
  jmp alltraps
ffffffff8010907a:	e9 98 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010907f <vector187>:
.globl vector187
vector187:
  push $0
ffffffff8010907f:	6a 00                	pushq  $0x0
  push $187
ffffffff80109081:	68 bb 00 00 00       	pushq  $0xbb
  jmp alltraps
ffffffff80109086:	e9 8c f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010908b <vector188>:
.globl vector188
vector188:
  push $0
ffffffff8010908b:	6a 00                	pushq  $0x0
  push $188
ffffffff8010908d:	68 bc 00 00 00       	pushq  $0xbc
  jmp alltraps
ffffffff80109092:	e9 80 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109097 <vector189>:
.globl vector189
vector189:
  push $0
ffffffff80109097:	6a 00                	pushq  $0x0
  push $189
ffffffff80109099:	68 bd 00 00 00       	pushq  $0xbd
  jmp alltraps
ffffffff8010909e:	e9 74 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801090a3 <vector190>:
.globl vector190
vector190:
  push $0
ffffffff801090a3:	6a 00                	pushq  $0x0
  push $190
ffffffff801090a5:	68 be 00 00 00       	pushq  $0xbe
  jmp alltraps
ffffffff801090aa:	e9 68 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801090af <vector191>:
.globl vector191
vector191:
  push $0
ffffffff801090af:	6a 00                	pushq  $0x0
  push $191
ffffffff801090b1:	68 bf 00 00 00       	pushq  $0xbf
  jmp alltraps
ffffffff801090b6:	e9 5c f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801090bb <vector192>:
.globl vector192
vector192:
  push $0
ffffffff801090bb:	6a 00                	pushq  $0x0
  push $192
ffffffff801090bd:	68 c0 00 00 00       	pushq  $0xc0
  jmp alltraps
ffffffff801090c2:	e9 50 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801090c7 <vector193>:
.globl vector193
vector193:
  push $0
ffffffff801090c7:	6a 00                	pushq  $0x0
  push $193
ffffffff801090c9:	68 c1 00 00 00       	pushq  $0xc1
  jmp alltraps
ffffffff801090ce:	e9 44 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801090d3 <vector194>:
.globl vector194
vector194:
  push $0
ffffffff801090d3:	6a 00                	pushq  $0x0
  push $194
ffffffff801090d5:	68 c2 00 00 00       	pushq  $0xc2
  jmp alltraps
ffffffff801090da:	e9 38 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801090df <vector195>:
.globl vector195
vector195:
  push $0
ffffffff801090df:	6a 00                	pushq  $0x0
  push $195
ffffffff801090e1:	68 c3 00 00 00       	pushq  $0xc3
  jmp alltraps
ffffffff801090e6:	e9 2c f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801090eb <vector196>:
.globl vector196
vector196:
  push $0
ffffffff801090eb:	6a 00                	pushq  $0x0
  push $196
ffffffff801090ed:	68 c4 00 00 00       	pushq  $0xc4
  jmp alltraps
ffffffff801090f2:	e9 20 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801090f7 <vector197>:
.globl vector197
vector197:
  push $0
ffffffff801090f7:	6a 00                	pushq  $0x0
  push $197
ffffffff801090f9:	68 c5 00 00 00       	pushq  $0xc5
  jmp alltraps
ffffffff801090fe:	e9 14 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109103 <vector198>:
.globl vector198
vector198:
  push $0
ffffffff80109103:	6a 00                	pushq  $0x0
  push $198
ffffffff80109105:	68 c6 00 00 00       	pushq  $0xc6
  jmp alltraps
ffffffff8010910a:	e9 08 f3 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010910f <vector199>:
.globl vector199
vector199:
  push $0
ffffffff8010910f:	6a 00                	pushq  $0x0
  push $199
ffffffff80109111:	68 c7 00 00 00       	pushq  $0xc7
  jmp alltraps
ffffffff80109116:	e9 fc f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010911b <vector200>:
.globl vector200
vector200:
  push $0
ffffffff8010911b:	6a 00                	pushq  $0x0
  push $200
ffffffff8010911d:	68 c8 00 00 00       	pushq  $0xc8
  jmp alltraps
ffffffff80109122:	e9 f0 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109127 <vector201>:
.globl vector201
vector201:
  push $0
ffffffff80109127:	6a 00                	pushq  $0x0
  push $201
ffffffff80109129:	68 c9 00 00 00       	pushq  $0xc9
  jmp alltraps
ffffffff8010912e:	e9 e4 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109133 <vector202>:
.globl vector202
vector202:
  push $0
ffffffff80109133:	6a 00                	pushq  $0x0
  push $202
ffffffff80109135:	68 ca 00 00 00       	pushq  $0xca
  jmp alltraps
ffffffff8010913a:	e9 d8 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010913f <vector203>:
.globl vector203
vector203:
  push $0
ffffffff8010913f:	6a 00                	pushq  $0x0
  push $203
ffffffff80109141:	68 cb 00 00 00       	pushq  $0xcb
  jmp alltraps
ffffffff80109146:	e9 cc f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010914b <vector204>:
.globl vector204
vector204:
  push $0
ffffffff8010914b:	6a 00                	pushq  $0x0
  push $204
ffffffff8010914d:	68 cc 00 00 00       	pushq  $0xcc
  jmp alltraps
ffffffff80109152:	e9 c0 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109157 <vector205>:
.globl vector205
vector205:
  push $0
ffffffff80109157:	6a 00                	pushq  $0x0
  push $205
ffffffff80109159:	68 cd 00 00 00       	pushq  $0xcd
  jmp alltraps
ffffffff8010915e:	e9 b4 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109163 <vector206>:
.globl vector206
vector206:
  push $0
ffffffff80109163:	6a 00                	pushq  $0x0
  push $206
ffffffff80109165:	68 ce 00 00 00       	pushq  $0xce
  jmp alltraps
ffffffff8010916a:	e9 a8 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010916f <vector207>:
.globl vector207
vector207:
  push $0
ffffffff8010916f:	6a 00                	pushq  $0x0
  push $207
ffffffff80109171:	68 cf 00 00 00       	pushq  $0xcf
  jmp alltraps
ffffffff80109176:	e9 9c f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010917b <vector208>:
.globl vector208
vector208:
  push $0
ffffffff8010917b:	6a 00                	pushq  $0x0
  push $208
ffffffff8010917d:	68 d0 00 00 00       	pushq  $0xd0
  jmp alltraps
ffffffff80109182:	e9 90 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109187 <vector209>:
.globl vector209
vector209:
  push $0
ffffffff80109187:	6a 00                	pushq  $0x0
  push $209
ffffffff80109189:	68 d1 00 00 00       	pushq  $0xd1
  jmp alltraps
ffffffff8010918e:	e9 84 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109193 <vector210>:
.globl vector210
vector210:
  push $0
ffffffff80109193:	6a 00                	pushq  $0x0
  push $210
ffffffff80109195:	68 d2 00 00 00       	pushq  $0xd2
  jmp alltraps
ffffffff8010919a:	e9 78 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010919f <vector211>:
.globl vector211
vector211:
  push $0
ffffffff8010919f:	6a 00                	pushq  $0x0
  push $211
ffffffff801091a1:	68 d3 00 00 00       	pushq  $0xd3
  jmp alltraps
ffffffff801091a6:	e9 6c f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801091ab <vector212>:
.globl vector212
vector212:
  push $0
ffffffff801091ab:	6a 00                	pushq  $0x0
  push $212
ffffffff801091ad:	68 d4 00 00 00       	pushq  $0xd4
  jmp alltraps
ffffffff801091b2:	e9 60 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801091b7 <vector213>:
.globl vector213
vector213:
  push $0
ffffffff801091b7:	6a 00                	pushq  $0x0
  push $213
ffffffff801091b9:	68 d5 00 00 00       	pushq  $0xd5
  jmp alltraps
ffffffff801091be:	e9 54 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801091c3 <vector214>:
.globl vector214
vector214:
  push $0
ffffffff801091c3:	6a 00                	pushq  $0x0
  push $214
ffffffff801091c5:	68 d6 00 00 00       	pushq  $0xd6
  jmp alltraps
ffffffff801091ca:	e9 48 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801091cf <vector215>:
.globl vector215
vector215:
  push $0
ffffffff801091cf:	6a 00                	pushq  $0x0
  push $215
ffffffff801091d1:	68 d7 00 00 00       	pushq  $0xd7
  jmp alltraps
ffffffff801091d6:	e9 3c f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801091db <vector216>:
.globl vector216
vector216:
  push $0
ffffffff801091db:	6a 00                	pushq  $0x0
  push $216
ffffffff801091dd:	68 d8 00 00 00       	pushq  $0xd8
  jmp alltraps
ffffffff801091e2:	e9 30 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801091e7 <vector217>:
.globl vector217
vector217:
  push $0
ffffffff801091e7:	6a 00                	pushq  $0x0
  push $217
ffffffff801091e9:	68 d9 00 00 00       	pushq  $0xd9
  jmp alltraps
ffffffff801091ee:	e9 24 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801091f3 <vector218>:
.globl vector218
vector218:
  push $0
ffffffff801091f3:	6a 00                	pushq  $0x0
  push $218
ffffffff801091f5:	68 da 00 00 00       	pushq  $0xda
  jmp alltraps
ffffffff801091fa:	e9 18 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801091ff <vector219>:
.globl vector219
vector219:
  push $0
ffffffff801091ff:	6a 00                	pushq  $0x0
  push $219
ffffffff80109201:	68 db 00 00 00       	pushq  $0xdb
  jmp alltraps
ffffffff80109206:	e9 0c f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010920b <vector220>:
.globl vector220
vector220:
  push $0
ffffffff8010920b:	6a 00                	pushq  $0x0
  push $220
ffffffff8010920d:	68 dc 00 00 00       	pushq  $0xdc
  jmp alltraps
ffffffff80109212:	e9 00 f2 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109217 <vector221>:
.globl vector221
vector221:
  push $0
ffffffff80109217:	6a 00                	pushq  $0x0
  push $221
ffffffff80109219:	68 dd 00 00 00       	pushq  $0xdd
  jmp alltraps
ffffffff8010921e:	e9 f4 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109223 <vector222>:
.globl vector222
vector222:
  push $0
ffffffff80109223:	6a 00                	pushq  $0x0
  push $222
ffffffff80109225:	68 de 00 00 00       	pushq  $0xde
  jmp alltraps
ffffffff8010922a:	e9 e8 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010922f <vector223>:
.globl vector223
vector223:
  push $0
ffffffff8010922f:	6a 00                	pushq  $0x0
  push $223
ffffffff80109231:	68 df 00 00 00       	pushq  $0xdf
  jmp alltraps
ffffffff80109236:	e9 dc f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010923b <vector224>:
.globl vector224
vector224:
  push $0
ffffffff8010923b:	6a 00                	pushq  $0x0
  push $224
ffffffff8010923d:	68 e0 00 00 00       	pushq  $0xe0
  jmp alltraps
ffffffff80109242:	e9 d0 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109247 <vector225>:
.globl vector225
vector225:
  push $0
ffffffff80109247:	6a 00                	pushq  $0x0
  push $225
ffffffff80109249:	68 e1 00 00 00       	pushq  $0xe1
  jmp alltraps
ffffffff8010924e:	e9 c4 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109253 <vector226>:
.globl vector226
vector226:
  push $0
ffffffff80109253:	6a 00                	pushq  $0x0
  push $226
ffffffff80109255:	68 e2 00 00 00       	pushq  $0xe2
  jmp alltraps
ffffffff8010925a:	e9 b8 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010925f <vector227>:
.globl vector227
vector227:
  push $0
ffffffff8010925f:	6a 00                	pushq  $0x0
  push $227
ffffffff80109261:	68 e3 00 00 00       	pushq  $0xe3
  jmp alltraps
ffffffff80109266:	e9 ac f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010926b <vector228>:
.globl vector228
vector228:
  push $0
ffffffff8010926b:	6a 00                	pushq  $0x0
  push $228
ffffffff8010926d:	68 e4 00 00 00       	pushq  $0xe4
  jmp alltraps
ffffffff80109272:	e9 a0 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109277 <vector229>:
.globl vector229
vector229:
  push $0
ffffffff80109277:	6a 00                	pushq  $0x0
  push $229
ffffffff80109279:	68 e5 00 00 00       	pushq  $0xe5
  jmp alltraps
ffffffff8010927e:	e9 94 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109283 <vector230>:
.globl vector230
vector230:
  push $0
ffffffff80109283:	6a 00                	pushq  $0x0
  push $230
ffffffff80109285:	68 e6 00 00 00       	pushq  $0xe6
  jmp alltraps
ffffffff8010928a:	e9 88 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010928f <vector231>:
.globl vector231
vector231:
  push $0
ffffffff8010928f:	6a 00                	pushq  $0x0
  push $231
ffffffff80109291:	68 e7 00 00 00       	pushq  $0xe7
  jmp alltraps
ffffffff80109296:	e9 7c f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010929b <vector232>:
.globl vector232
vector232:
  push $0
ffffffff8010929b:	6a 00                	pushq  $0x0
  push $232
ffffffff8010929d:	68 e8 00 00 00       	pushq  $0xe8
  jmp alltraps
ffffffff801092a2:	e9 70 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801092a7 <vector233>:
.globl vector233
vector233:
  push $0
ffffffff801092a7:	6a 00                	pushq  $0x0
  push $233
ffffffff801092a9:	68 e9 00 00 00       	pushq  $0xe9
  jmp alltraps
ffffffff801092ae:	e9 64 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801092b3 <vector234>:
.globl vector234
vector234:
  push $0
ffffffff801092b3:	6a 00                	pushq  $0x0
  push $234
ffffffff801092b5:	68 ea 00 00 00       	pushq  $0xea
  jmp alltraps
ffffffff801092ba:	e9 58 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801092bf <vector235>:
.globl vector235
vector235:
  push $0
ffffffff801092bf:	6a 00                	pushq  $0x0
  push $235
ffffffff801092c1:	68 eb 00 00 00       	pushq  $0xeb
  jmp alltraps
ffffffff801092c6:	e9 4c f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801092cb <vector236>:
.globl vector236
vector236:
  push $0
ffffffff801092cb:	6a 00                	pushq  $0x0
  push $236
ffffffff801092cd:	68 ec 00 00 00       	pushq  $0xec
  jmp alltraps
ffffffff801092d2:	e9 40 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801092d7 <vector237>:
.globl vector237
vector237:
  push $0
ffffffff801092d7:	6a 00                	pushq  $0x0
  push $237
ffffffff801092d9:	68 ed 00 00 00       	pushq  $0xed
  jmp alltraps
ffffffff801092de:	e9 34 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801092e3 <vector238>:
.globl vector238
vector238:
  push $0
ffffffff801092e3:	6a 00                	pushq  $0x0
  push $238
ffffffff801092e5:	68 ee 00 00 00       	pushq  $0xee
  jmp alltraps
ffffffff801092ea:	e9 28 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801092ef <vector239>:
.globl vector239
vector239:
  push $0
ffffffff801092ef:	6a 00                	pushq  $0x0
  push $239
ffffffff801092f1:	68 ef 00 00 00       	pushq  $0xef
  jmp alltraps
ffffffff801092f6:	e9 1c f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801092fb <vector240>:
.globl vector240
vector240:
  push $0
ffffffff801092fb:	6a 00                	pushq  $0x0
  push $240
ffffffff801092fd:	68 f0 00 00 00       	pushq  $0xf0
  jmp alltraps
ffffffff80109302:	e9 10 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109307 <vector241>:
.globl vector241
vector241:
  push $0
ffffffff80109307:	6a 00                	pushq  $0x0
  push $241
ffffffff80109309:	68 f1 00 00 00       	pushq  $0xf1
  jmp alltraps
ffffffff8010930e:	e9 04 f1 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109313 <vector242>:
.globl vector242
vector242:
  push $0
ffffffff80109313:	6a 00                	pushq  $0x0
  push $242
ffffffff80109315:	68 f2 00 00 00       	pushq  $0xf2
  jmp alltraps
ffffffff8010931a:	e9 f8 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010931f <vector243>:
.globl vector243
vector243:
  push $0
ffffffff8010931f:	6a 00                	pushq  $0x0
  push $243
ffffffff80109321:	68 f3 00 00 00       	pushq  $0xf3
  jmp alltraps
ffffffff80109326:	e9 ec f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010932b <vector244>:
.globl vector244
vector244:
  push $0
ffffffff8010932b:	6a 00                	pushq  $0x0
  push $244
ffffffff8010932d:	68 f4 00 00 00       	pushq  $0xf4
  jmp alltraps
ffffffff80109332:	e9 e0 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109337 <vector245>:
.globl vector245
vector245:
  push $0
ffffffff80109337:	6a 00                	pushq  $0x0
  push $245
ffffffff80109339:	68 f5 00 00 00       	pushq  $0xf5
  jmp alltraps
ffffffff8010933e:	e9 d4 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109343 <vector246>:
.globl vector246
vector246:
  push $0
ffffffff80109343:	6a 00                	pushq  $0x0
  push $246
ffffffff80109345:	68 f6 00 00 00       	pushq  $0xf6
  jmp alltraps
ffffffff8010934a:	e9 c8 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010934f <vector247>:
.globl vector247
vector247:
  push $0
ffffffff8010934f:	6a 00                	pushq  $0x0
  push $247
ffffffff80109351:	68 f7 00 00 00       	pushq  $0xf7
  jmp alltraps
ffffffff80109356:	e9 bc f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010935b <vector248>:
.globl vector248
vector248:
  push $0
ffffffff8010935b:	6a 00                	pushq  $0x0
  push $248
ffffffff8010935d:	68 f8 00 00 00       	pushq  $0xf8
  jmp alltraps
ffffffff80109362:	e9 b0 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109367 <vector249>:
.globl vector249
vector249:
  push $0
ffffffff80109367:	6a 00                	pushq  $0x0
  push $249
ffffffff80109369:	68 f9 00 00 00       	pushq  $0xf9
  jmp alltraps
ffffffff8010936e:	e9 a4 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109373 <vector250>:
.globl vector250
vector250:
  push $0
ffffffff80109373:	6a 00                	pushq  $0x0
  push $250
ffffffff80109375:	68 fa 00 00 00       	pushq  $0xfa
  jmp alltraps
ffffffff8010937a:	e9 98 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010937f <vector251>:
.globl vector251
vector251:
  push $0
ffffffff8010937f:	6a 00                	pushq  $0x0
  push $251
ffffffff80109381:	68 fb 00 00 00       	pushq  $0xfb
  jmp alltraps
ffffffff80109386:	e9 8c f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff8010938b <vector252>:
.globl vector252
vector252:
  push $0
ffffffff8010938b:	6a 00                	pushq  $0x0
  push $252
ffffffff8010938d:	68 fc 00 00 00       	pushq  $0xfc
  jmp alltraps
ffffffff80109392:	e9 80 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff80109397 <vector253>:
.globl vector253
vector253:
  push $0
ffffffff80109397:	6a 00                	pushq  $0x0
  push $253
ffffffff80109399:	68 fd 00 00 00       	pushq  $0xfd
  jmp alltraps
ffffffff8010939e:	e9 74 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801093a3 <vector254>:
.globl vector254
vector254:
  push $0
ffffffff801093a3:	6a 00                	pushq  $0x0
  push $254
ffffffff801093a5:	68 fe 00 00 00       	pushq  $0xfe
  jmp alltraps
ffffffff801093aa:	e9 68 f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801093af <vector255>:
.globl vector255
vector255:
  push $0
ffffffff801093af:	6a 00                	pushq  $0x0
  push $255
ffffffff801093b1:	68 ff 00 00 00       	pushq  $0xff
  jmp alltraps
ffffffff801093b6:	e9 5c f0 ff ff       	jmpq   ffffffff80108417 <alltraps>

ffffffff801093bb <v2p>:
#endif
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uintp v2p(void *a) { return ((uintp) (a)) - ((uintp)KERNBASE); }
ffffffff801093bb:	55                   	push   %rbp
ffffffff801093bc:	48 89 e5             	mov    %rsp,%rbp
ffffffff801093bf:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801093c3:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff801093c7:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff801093cb:	b8 00 00 00 80       	mov    $0x80000000,%eax
ffffffff801093d0:	48 01 d0             	add    %rdx,%rax
ffffffff801093d3:	c9                   	leaveq 
ffffffff801093d4:	c3                   	retq   

ffffffff801093d5 <p2v>:
static inline void *p2v(uintp a) { return (void *) ((a) + ((uintp)KERNBASE)); }
ffffffff801093d5:	55                   	push   %rbp
ffffffff801093d6:	48 89 e5             	mov    %rsp,%rbp
ffffffff801093d9:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff801093dd:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff801093e1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801093e5:	48 05 00 00 00 80    	add    $0xffffffff80000000,%rax
ffffffff801093eb:	c9                   	leaveq 
ffffffff801093ec:	c3                   	retq   

ffffffff801093ed <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
ffffffff801093ed:	55                   	push   %rbp
ffffffff801093ee:	48 89 e5             	mov    %rsp,%rbp
ffffffff801093f1:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff801093f5:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff801093f9:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff801093fd:	89 55 dc             	mov    %edx,-0x24(%rbp)
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
ffffffff80109400:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109404:	48 c1 e8 15          	shr    $0x15,%rax
ffffffff80109408:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff8010940d:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80109414:	00 
ffffffff80109415:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109419:	48 01 d0             	add    %rdx,%rax
ffffffff8010941c:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  if(*pde & PTE_P){
ffffffff80109420:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109424:	48 8b 00             	mov    (%rax),%rax
ffffffff80109427:	83 e0 01             	and    $0x1,%eax
ffffffff8010942a:	48 85 c0             	test   %rax,%rax
ffffffff8010942d:	74 1b                	je     ffffffff8010944a <walkpgdir+0x5d>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
ffffffff8010942f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109433:	48 8b 00             	mov    (%rax),%rax
ffffffff80109436:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff8010943c:	48 89 c7             	mov    %rax,%rdi
ffffffff8010943f:	e8 91 ff ff ff       	callq  ffffffff801093d5 <p2v>
ffffffff80109444:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80109448:	eb 4d                	jmp    ffffffff80109497 <walkpgdir+0xaa>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
ffffffff8010944a:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
ffffffff8010944e:	74 10                	je     ffffffff80109460 <walkpgdir+0x73>
ffffffff80109450:	e8 43 a4 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff80109455:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
ffffffff80109459:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff8010945e:	75 07                	jne    ffffffff80109467 <walkpgdir+0x7a>
      return 0;
ffffffff80109460:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80109465:	eb 4c                	jmp    ffffffff801094b3 <walkpgdir+0xc6>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
ffffffff80109467:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010946b:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80109470:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80109475:	48 89 c7             	mov    %rax,%rdi
ffffffff80109478:	e8 90 d7 ff ff       	callq  ffffffff80106c0d <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
ffffffff8010947d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80109481:	48 89 c7             	mov    %rax,%rdi
ffffffff80109484:	e8 32 ff ff ff       	callq  ffffffff801093bb <v2p>
ffffffff80109489:	48 83 c8 07          	or     $0x7,%rax
ffffffff8010948d:	48 89 c2             	mov    %rax,%rdx
ffffffff80109490:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109494:	48 89 10             	mov    %rdx,(%rax)
  }
  return &pgtab[PTX(va)];
ffffffff80109497:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010949b:	48 c1 e8 0c          	shr    $0xc,%rax
ffffffff8010949f:	25 ff 01 00 00       	and    $0x1ff,%eax
ffffffff801094a4:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff801094ab:	00 
ffffffff801094ac:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801094b0:	48 01 d0             	add    %rdx,%rax
}
ffffffff801094b3:	c9                   	leaveq 
ffffffff801094b4:	c3                   	retq   

ffffffff801094b5 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uintp size, uintp pa, int perm)
{
ffffffff801094b5:	55                   	push   %rbp
ffffffff801094b6:	48 89 e5             	mov    %rsp,%rbp
ffffffff801094b9:	48 83 ec 50          	sub    $0x50,%rsp
ffffffff801094bd:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff801094c1:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
ffffffff801094c5:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
ffffffff801094c9:	48 89 4d c0          	mov    %rcx,-0x40(%rbp)
ffffffff801094cd:	44 89 45 bc          	mov    %r8d,-0x44(%rbp)
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uintp)va);
ffffffff801094d1:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff801094d5:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff801094db:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  last = (char*)PGROUNDDOWN(((uintp)va) + size - 1);
ffffffff801094df:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
ffffffff801094e3:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801094e7:	48 01 d0             	add    %rdx,%rax
ffffffff801094ea:	48 83 e8 01          	sub    $0x1,%rax
ffffffff801094ee:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff801094f4:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
ffffffff801094f8:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
ffffffff801094fc:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80109500:	ba 01 00 00 00       	mov    $0x1,%edx
ffffffff80109505:	48 89 ce             	mov    %rcx,%rsi
ffffffff80109508:	48 89 c7             	mov    %rax,%rdi
ffffffff8010950b:	e8 dd fe ff ff       	callq  ffffffff801093ed <walkpgdir>
ffffffff80109510:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
ffffffff80109514:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff80109519:	75 07                	jne    ffffffff80109522 <mappages+0x6d>
      return -1;
ffffffff8010951b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80109520:	eb 54                	jmp    ffffffff80109576 <mappages+0xc1>
    if(*pte & PTE_P)
ffffffff80109522:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109526:	48 8b 00             	mov    (%rax),%rax
ffffffff80109529:	83 e0 01             	and    $0x1,%eax
ffffffff8010952c:	48 85 c0             	test   %rax,%rax
ffffffff8010952f:	74 0c                	je     ffffffff8010953d <mappages+0x88>
      panic("remap");
ffffffff80109531:	48 c7 c7 a8 b0 10 80 	mov    $0xffffffff8010b0a8,%rdi
ffffffff80109538:	e8 c2 73 ff ff       	callq  ffffffff801008ff <panic>
    *pte = pa | perm | PTE_P;
ffffffff8010953d:	8b 45 bc             	mov    -0x44(%rbp),%eax
ffffffff80109540:	48 98                	cltq   
ffffffff80109542:	48 0b 45 c0          	or     -0x40(%rbp),%rax
ffffffff80109546:	48 83 c8 01          	or     $0x1,%rax
ffffffff8010954a:	48 89 c2             	mov    %rax,%rdx
ffffffff8010954d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109551:	48 89 10             	mov    %rdx,(%rax)
    if(a == last)
ffffffff80109554:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80109558:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
ffffffff8010955c:	74 12                	je     ffffffff80109570 <mappages+0xbb>
      break;
    a += PGSIZE;
ffffffff8010955e:	48 81 45 f8 00 10 00 	addq   $0x1000,-0x8(%rbp)
ffffffff80109565:	00 
    pa += PGSIZE;
ffffffff80109566:	48 81 45 c0 00 10 00 	addq   $0x1000,-0x40(%rbp)
ffffffff8010956d:	00 
  }
ffffffff8010956e:	eb 88                	jmp    ffffffff801094f8 <mappages+0x43>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
ffffffff80109570:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
ffffffff80109571:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80109576:	c9                   	leaveq 
ffffffff80109577:	c3                   	retq   

ffffffff80109578 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
ffffffff80109578:	55                   	push   %rbp
ffffffff80109579:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010957c:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80109580:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80109584:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
ffffffff80109588:	89 55 dc             	mov    %edx,-0x24(%rbp)
  char *mem;
  
  if(sz >= PGSIZE)
ffffffff8010958b:	81 7d dc ff 0f 00 00 	cmpl   $0xfff,-0x24(%rbp)
ffffffff80109592:	76 0c                	jbe    ffffffff801095a0 <inituvm+0x28>
    panic("inituvm: more than a page");
ffffffff80109594:	48 c7 c7 ae b0 10 80 	mov    $0xffffffff8010b0ae,%rdi
ffffffff8010959b:	e8 5f 73 ff ff       	callq  ffffffff801008ff <panic>
  mem = kalloc();
ffffffff801095a0:	e8 f3 a2 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff801095a5:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  memset(mem, 0, PGSIZE);
ffffffff801095a9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801095ad:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff801095b2:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801095b7:	48 89 c7             	mov    %rax,%rdi
ffffffff801095ba:	e8 4e d6 ff ff       	callq  ffffffff80106c0d <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
ffffffff801095bf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801095c3:	48 89 c7             	mov    %rax,%rdi
ffffffff801095c6:	e8 f0 fd ff ff       	callq  ffffffff801093bb <v2p>
ffffffff801095cb:	48 89 c2             	mov    %rax,%rdx
ffffffff801095ce:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801095d2:	41 b8 06 00 00 00    	mov    $0x6,%r8d
ffffffff801095d8:	48 89 d1             	mov    %rdx,%rcx
ffffffff801095db:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff801095e0:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff801095e5:	48 89 c7             	mov    %rax,%rdi
ffffffff801095e8:	e8 c8 fe ff ff       	callq  ffffffff801094b5 <mappages>
  memmove(mem, init, sz);
ffffffff801095ed:	8b 55 dc             	mov    -0x24(%rbp),%edx
ffffffff801095f0:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
ffffffff801095f4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801095f8:	48 89 ce             	mov    %rcx,%rsi
ffffffff801095fb:	48 89 c7             	mov    %rax,%rdi
ffffffff801095fe:	e8 f9 d6 ff ff       	callq  ffffffff80106cfc <memmove>
}
ffffffff80109603:	90                   	nop
ffffffff80109604:	c9                   	leaveq 
ffffffff80109605:	c3                   	retq   

ffffffff80109606 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
ffffffff80109606:	55                   	push   %rbp
ffffffff80109607:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010960a:	53                   	push   %rbx
ffffffff8010960b:	48 83 ec 48          	sub    $0x48,%rsp
ffffffff8010960f:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
ffffffff80109613:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
ffffffff80109617:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
ffffffff8010961b:	89 4d b4             	mov    %ecx,-0x4c(%rbp)
ffffffff8010961e:	44 89 45 b0          	mov    %r8d,-0x50(%rbp)
  uint i, pa, n;
  pte_t *pte;

  if((uintp) addr % PGSIZE != 0)
ffffffff80109622:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80109626:	25 ff 0f 00 00       	and    $0xfff,%eax
ffffffff8010962b:	48 85 c0             	test   %rax,%rax
ffffffff8010962e:	74 0c                	je     ffffffff8010963c <loaduvm+0x36>
    panic("loaduvm: addr must be page aligned");
ffffffff80109630:	48 c7 c7 c8 b0 10 80 	mov    $0xffffffff8010b0c8,%rdi
ffffffff80109637:	e8 c3 72 ff ff       	callq  ffffffff801008ff <panic>
  for(i = 0; i < sz; i += PGSIZE){
ffffffff8010963c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)
ffffffff80109643:	e9 a1 00 00 00       	jmpq   ffffffff801096e9 <loaduvm+0xe3>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
ffffffff80109648:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff8010964b:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff8010964f:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
ffffffff80109653:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80109657:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff8010965c:	48 89 ce             	mov    %rcx,%rsi
ffffffff8010965f:	48 89 c7             	mov    %rax,%rdi
ffffffff80109662:	e8 86 fd ff ff       	callq  ffffffff801093ed <walkpgdir>
ffffffff80109667:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
ffffffff8010966b:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
ffffffff80109670:	75 0c                	jne    ffffffff8010967e <loaduvm+0x78>
      panic("loaduvm: address should exist");
ffffffff80109672:	48 c7 c7 eb b0 10 80 	mov    $0xffffffff8010b0eb,%rdi
ffffffff80109679:	e8 81 72 ff ff       	callq  ffffffff801008ff <panic>
    pa = PTE_ADDR(*pte);
ffffffff8010967e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109682:	48 8b 00             	mov    (%rax),%rax
ffffffff80109685:	25 00 f0 ff ff       	and    $0xfffff000,%eax
ffffffff8010968a:	89 45 dc             	mov    %eax,-0x24(%rbp)
    if(sz - i < PGSIZE)
ffffffff8010968d:	8b 45 b0             	mov    -0x50(%rbp),%eax
ffffffff80109690:	2b 45 ec             	sub    -0x14(%rbp),%eax
ffffffff80109693:	3d ff 0f 00 00       	cmp    $0xfff,%eax
ffffffff80109698:	77 0b                	ja     ffffffff801096a5 <loaduvm+0x9f>
      n = sz - i;
ffffffff8010969a:	8b 45 b0             	mov    -0x50(%rbp),%eax
ffffffff8010969d:	2b 45 ec             	sub    -0x14(%rbp),%eax
ffffffff801096a0:	89 45 e8             	mov    %eax,-0x18(%rbp)
ffffffff801096a3:	eb 07                	jmp    ffffffff801096ac <loaduvm+0xa6>
    else
      n = PGSIZE;
ffffffff801096a5:	c7 45 e8 00 10 00 00 	movl   $0x1000,-0x18(%rbp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
ffffffff801096ac:	8b 55 b4             	mov    -0x4c(%rbp),%edx
ffffffff801096af:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff801096b2:	8d 1c 02             	lea    (%rdx,%rax,1),%ebx
ffffffff801096b5:	8b 45 dc             	mov    -0x24(%rbp),%eax
ffffffff801096b8:	48 89 c7             	mov    %rax,%rdi
ffffffff801096bb:	e8 15 fd ff ff       	callq  ffffffff801093d5 <p2v>
ffffffff801096c0:	48 89 c6             	mov    %rax,%rsi
ffffffff801096c3:	8b 55 e8             	mov    -0x18(%rbp),%edx
ffffffff801096c6:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff801096ca:	89 d1                	mov    %edx,%ecx
ffffffff801096cc:	89 da                	mov    %ebx,%edx
ffffffff801096ce:	48 89 c7             	mov    %rax,%rdi
ffffffff801096d1:	e8 79 97 ff ff       	callq  ffffffff80102e4f <readi>
ffffffff801096d6:	3b 45 e8             	cmp    -0x18(%rbp),%eax
ffffffff801096d9:	74 07                	je     ffffffff801096e2 <loaduvm+0xdc>
      return -1;
ffffffff801096db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff801096e0:	eb 18                	jmp    ffffffff801096fa <loaduvm+0xf4>
  uint i, pa, n;
  pte_t *pte;

  if((uintp) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
ffffffff801096e2:	81 45 ec 00 10 00 00 	addl   $0x1000,-0x14(%rbp)
ffffffff801096e9:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff801096ec:	3b 45 b0             	cmp    -0x50(%rbp),%eax
ffffffff801096ef:	0f 82 53 ff ff ff    	jb     ffffffff80109648 <loaduvm+0x42>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
ffffffff801096f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff801096fa:	48 83 c4 48          	add    $0x48,%rsp
ffffffff801096fe:	5b                   	pop    %rbx
ffffffff801096ff:	5d                   	pop    %rbp
ffffffff80109700:	c3                   	retq   

ffffffff80109701 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
ffffffff80109701:	55                   	push   %rbp
ffffffff80109702:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109705:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80109709:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff8010970d:	89 75 e4             	mov    %esi,-0x1c(%rbp)
ffffffff80109710:	89 55 e0             	mov    %edx,-0x20(%rbp)

#if !defined(X64)
  if(newsz >= KERNBASE)
    return 0;
#endif
  if(newsz < oldsz)
ffffffff80109713:	8b 45 e0             	mov    -0x20(%rbp),%eax
ffffffff80109716:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
ffffffff80109719:	73 08                	jae    ffffffff80109723 <allocuvm+0x22>
    return oldsz;
ffffffff8010971b:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff8010971e:	e9 b0 00 00 00       	jmpq   ffffffff801097d3 <allocuvm+0xd2>

  a = PGROUNDUP(oldsz);
ffffffff80109723:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80109726:	48 05 ff 0f 00 00    	add    $0xfff,%rax
ffffffff8010972c:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff80109732:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  for(; a < newsz; a += PGSIZE){
ffffffff80109736:	e9 88 00 00 00       	jmpq   ffffffff801097c3 <allocuvm+0xc2>
    mem = kalloc();
ffffffff8010973b:	e8 58 a1 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff80109740:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    if(mem == 0){
ffffffff80109744:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80109749:	75 2d                	jne    ffffffff80109778 <allocuvm+0x77>
      cprintf("allocuvm out of memory\n");
ffffffff8010974b:	48 c7 c7 09 b1 10 80 	mov    $0xffffffff8010b109,%rdi
ffffffff80109752:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80109757:	e8 46 6e ff ff       	callq  ffffffff801005a2 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
ffffffff8010975c:	8b 55 e4             	mov    -0x1c(%rbp),%edx
ffffffff8010975f:	8b 4d e0             	mov    -0x20(%rbp),%ecx
ffffffff80109762:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109766:	48 89 ce             	mov    %rcx,%rsi
ffffffff80109769:	48 89 c7             	mov    %rax,%rdi
ffffffff8010976c:	e8 64 00 00 00       	callq  ffffffff801097d5 <deallocuvm>
      return 0;
ffffffff80109771:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80109776:	eb 5b                	jmp    ffffffff801097d3 <allocuvm+0xd2>
    }
    memset(mem, 0, PGSIZE);
ffffffff80109778:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010977c:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80109781:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80109786:	48 89 c7             	mov    %rax,%rdi
ffffffff80109789:	e8 7f d4 ff ff       	callq  ffffffff80106c0d <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
ffffffff8010978e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109792:	48 89 c7             	mov    %rax,%rdi
ffffffff80109795:	e8 21 fc ff ff       	callq  ffffffff801093bb <v2p>
ffffffff8010979a:	48 89 c2             	mov    %rax,%rdx
ffffffff8010979d:	48 8b 75 f8          	mov    -0x8(%rbp),%rsi
ffffffff801097a1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801097a5:	41 b8 06 00 00 00    	mov    $0x6,%r8d
ffffffff801097ab:	48 89 d1             	mov    %rdx,%rcx
ffffffff801097ae:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff801097b3:	48 89 c7             	mov    %rax,%rdi
ffffffff801097b6:	e8 fa fc ff ff       	callq  ffffffff801094b5 <mappages>
#endif
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
ffffffff801097bb:	48 81 45 f8 00 10 00 	addq   $0x1000,-0x8(%rbp)
ffffffff801097c2:	00 
ffffffff801097c3:	8b 45 e0             	mov    -0x20(%rbp),%eax
ffffffff801097c6:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
ffffffff801097ca:	0f 87 6b ff ff ff    	ja     ffffffff8010973b <allocuvm+0x3a>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
ffffffff801097d0:	8b 45 e0             	mov    -0x20(%rbp),%eax
}
ffffffff801097d3:	c9                   	leaveq 
ffffffff801097d4:	c3                   	retq   

ffffffff801097d5 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uintp oldsz, uintp newsz)
{
ffffffff801097d5:	55                   	push   %rbp
ffffffff801097d6:	48 89 e5             	mov    %rsp,%rbp
ffffffff801097d9:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff801097dd:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff801097e1:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
ffffffff801097e5:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  pte_t *pte;
  uintp a, pa;

  if(newsz >= oldsz)
ffffffff801097e9:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff801097ed:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
ffffffff801097f1:	72 09                	jb     ffffffff801097fc <deallocuvm+0x27>
    return oldsz;
ffffffff801097f3:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff801097f7:	e9 ba 00 00 00       	jmpq   ffffffff801098b6 <deallocuvm+0xe1>

  a = PGROUNDUP(newsz);
ffffffff801097fc:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80109800:	48 05 ff 0f 00 00    	add    $0xfff,%rax
ffffffff80109806:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff8010980c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  for(; a  < oldsz; a += PGSIZE){
ffffffff80109810:	e9 8f 00 00 00       	jmpq   ffffffff801098a4 <deallocuvm+0xcf>
    pte = walkpgdir(pgdir, (char*)a, 0);
ffffffff80109815:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
ffffffff80109819:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010981d:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff80109822:	48 89 ce             	mov    %rcx,%rsi
ffffffff80109825:	48 89 c7             	mov    %rax,%rdi
ffffffff80109828:	e8 c0 fb ff ff       	callq  ffffffff801093ed <walkpgdir>
ffffffff8010982d:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    if(!pte)
ffffffff80109831:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
ffffffff80109836:	75 0a                	jne    ffffffff80109842 <deallocuvm+0x6d>
      a += (NPTENTRIES - 1) * PGSIZE;
ffffffff80109838:	48 81 45 f8 00 f0 1f 	addq   $0x1ff000,-0x8(%rbp)
ffffffff8010983f:	00 
ffffffff80109840:	eb 5a                	jmp    ffffffff8010989c <deallocuvm+0xc7>
    else if((*pte & PTE_P) != 0){
ffffffff80109842:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109846:	48 8b 00             	mov    (%rax),%rax
ffffffff80109849:	83 e0 01             	and    $0x1,%eax
ffffffff8010984c:	48 85 c0             	test   %rax,%rax
ffffffff8010984f:	74 4b                	je     ffffffff8010989c <deallocuvm+0xc7>
      pa = PTE_ADDR(*pte);
ffffffff80109851:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109855:	48 8b 00             	mov    (%rax),%rax
ffffffff80109858:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff8010985e:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
      if(pa == 0)
ffffffff80109862:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff80109867:	75 0c                	jne    ffffffff80109875 <deallocuvm+0xa0>
        panic("kfree");
ffffffff80109869:	48 c7 c7 21 b1 10 80 	mov    $0xffffffff8010b121,%rdi
ffffffff80109870:	e8 8a 70 ff ff       	callq  ffffffff801008ff <panic>
      char *v = p2v(pa);
ffffffff80109875:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109879:	48 89 c7             	mov    %rax,%rdi
ffffffff8010987c:	e8 54 fb ff ff       	callq  ffffffff801093d5 <p2v>
ffffffff80109881:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
      kfree(v);
ffffffff80109885:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109889:	48 89 c7             	mov    %rax,%rdi
ffffffff8010988c:	e8 5d 9f ff ff       	callq  ffffffff801037ee <kfree>
      *pte = 0;
ffffffff80109891:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109895:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
ffffffff8010989c:	48 81 45 f8 00 10 00 	addq   $0x1000,-0x8(%rbp)
ffffffff801098a3:	00 
ffffffff801098a4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801098a8:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
ffffffff801098ac:	0f 82 63 ff ff ff    	jb     ffffffff80109815 <deallocuvm+0x40>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
ffffffff801098b2:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
}
ffffffff801098b6:	c9                   	leaveq 
ffffffff801098b7:	c3                   	retq   

ffffffff801098b8 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
ffffffff801098b8:	55                   	push   %rbp
ffffffff801098b9:	48 89 e5             	mov    %rsp,%rbp
ffffffff801098bc:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff801098c0:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  uint i;
  if(pgdir == 0)
ffffffff801098c4:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
ffffffff801098c9:	75 0c                	jne    ffffffff801098d7 <freevm+0x1f>
    panic("freevm: no pgdir");
ffffffff801098cb:	48 c7 c7 27 b1 10 80 	mov    $0xffffffff8010b127,%rdi
ffffffff801098d2:	e8 28 70 ff ff       	callq  ffffffff801008ff <panic>
  deallocuvm(pgdir, 0x3fa00000, 0);
ffffffff801098d7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff801098db:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff801098e0:	be 00 00 a0 3f       	mov    $0x3fa00000,%esi
ffffffff801098e5:	48 89 c7             	mov    %rax,%rdi
ffffffff801098e8:	e8 e8 fe ff ff       	callq  ffffffff801097d5 <deallocuvm>
  for(i = 0; i < NPDENTRIES-2; i++){
ffffffff801098ed:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff801098f4:	eb 54                	jmp    ffffffff8010994a <freevm+0x92>
    if(pgdir[i] & PTE_P){
ffffffff801098f6:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff801098f9:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff80109900:	00 
ffffffff80109901:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109905:	48 01 d0             	add    %rdx,%rax
ffffffff80109908:	48 8b 00             	mov    (%rax),%rax
ffffffff8010990b:	83 e0 01             	and    $0x1,%eax
ffffffff8010990e:	48 85 c0             	test   %rax,%rax
ffffffff80109911:	74 33                	je     ffffffff80109946 <freevm+0x8e>
      char * v = p2v(PTE_ADDR(pgdir[i]));
ffffffff80109913:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80109916:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffffffff8010991d:	00 
ffffffff8010991e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109922:	48 01 d0             	add    %rdx,%rax
ffffffff80109925:	48 8b 00             	mov    (%rax),%rax
ffffffff80109928:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff8010992e:	48 89 c7             	mov    %rax,%rdi
ffffffff80109931:	e8 9f fa ff ff       	callq  ffffffff801093d5 <p2v>
ffffffff80109936:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
      kfree(v);
ffffffff8010993a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010993e:	48 89 c7             	mov    %rax,%rdi
ffffffff80109941:	e8 a8 9e ff ff       	callq  ffffffff801037ee <kfree>
{
  uint i;
  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, 0x3fa00000, 0);
  for(i = 0; i < NPDENTRIES-2; i++){
ffffffff80109946:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff8010994a:	81 7d fc fd 01 00 00 	cmpl   $0x1fd,-0x4(%rbp)
ffffffff80109951:	76 a3                	jbe    ffffffff801098f6 <freevm+0x3e>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
ffffffff80109953:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109957:	48 89 c7             	mov    %rax,%rdi
ffffffff8010995a:	e8 8f 9e ff ff       	callq  ffffffff801037ee <kfree>
}
ffffffff8010995f:	90                   	nop
ffffffff80109960:	c9                   	leaveq 
ffffffff80109961:	c3                   	retq   

ffffffff80109962 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
ffffffff80109962:	55                   	push   %rbp
ffffffff80109963:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109966:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010996a:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff8010996e:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
ffffffff80109972:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
ffffffff80109976:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010997a:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff8010997f:	48 89 ce             	mov    %rcx,%rsi
ffffffff80109982:	48 89 c7             	mov    %rax,%rdi
ffffffff80109985:	e8 63 fa ff ff       	callq  ffffffff801093ed <walkpgdir>
ffffffff8010998a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if(pte == 0)
ffffffff8010998e:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
ffffffff80109993:	75 0c                	jne    ffffffff801099a1 <clearpteu+0x3f>
    panic("clearpteu");
ffffffff80109995:	48 c7 c7 38 b1 10 80 	mov    $0xffffffff8010b138,%rdi
ffffffff8010999c:	e8 5e 6f ff ff       	callq  ffffffff801008ff <panic>
  *pte &= ~PTE_U;
ffffffff801099a1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801099a5:	48 8b 00             	mov    (%rax),%rax
ffffffff801099a8:	48 83 e0 fb          	and    $0xfffffffffffffffb,%rax
ffffffff801099ac:	48 89 c2             	mov    %rax,%rdx
ffffffff801099af:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff801099b3:	48 89 10             	mov    %rdx,(%rax)
}
ffffffff801099b6:	90                   	nop
ffffffff801099b7:	c9                   	leaveq 
ffffffff801099b8:	c3                   	retq   

ffffffff801099b9 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
ffffffff801099b9:	55                   	push   %rbp
ffffffff801099ba:	48 89 e5             	mov    %rsp,%rbp
ffffffff801099bd:	53                   	push   %rbx
ffffffff801099be:	48 83 ec 48          	sub    $0x48,%rsp
ffffffff801099c2:	48 89 7d b8          	mov    %rdi,-0x48(%rbp)
ffffffff801099c6:	89 75 b4             	mov    %esi,-0x4c(%rbp)
  pde_t *d;
  pte_t *pte;
  uintp pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
ffffffff801099c9:	e8 a4 06 00 00       	callq  ffffffff8010a072 <setupkvm>
ffffffff801099ce:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
ffffffff801099d2:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
ffffffff801099d7:	75 0a                	jne    ffffffff801099e3 <copyuvm+0x2a>
    return 0;
ffffffff801099d9:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff801099de:	e9 0f 01 00 00       	jmpq   ffffffff80109af2 <copyuvm+0x139>
  for(i = 0; i < sz; i += PGSIZE){
ffffffff801099e3:	48 c7 45 e8 00 00 00 	movq   $0x0,-0x18(%rbp)
ffffffff801099ea:	00 
ffffffff801099eb:	e9 da 00 00 00       	jmpq   ffffffff80109aca <copyuvm+0x111>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
ffffffff801099f0:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
ffffffff801099f4:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
ffffffff801099f8:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff801099fd:	48 89 ce             	mov    %rcx,%rsi
ffffffff80109a00:	48 89 c7             	mov    %rax,%rdi
ffffffff80109a03:	e8 e5 f9 ff ff       	callq  ffffffff801093ed <walkpgdir>
ffffffff80109a08:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
ffffffff80109a0c:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
ffffffff80109a11:	75 0c                	jne    ffffffff80109a1f <copyuvm+0x66>
      panic("copyuvm: pte should exist");
ffffffff80109a13:	48 c7 c7 42 b1 10 80 	mov    $0xffffffff8010b142,%rdi
ffffffff80109a1a:	e8 e0 6e ff ff       	callq  ffffffff801008ff <panic>
    if(!(*pte & PTE_P))
ffffffff80109a1f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80109a23:	48 8b 00             	mov    (%rax),%rax
ffffffff80109a26:	83 e0 01             	and    $0x1,%eax
ffffffff80109a29:	48 85 c0             	test   %rax,%rax
ffffffff80109a2c:	75 0c                	jne    ffffffff80109a3a <copyuvm+0x81>
      panic("copyuvm: page not present");
ffffffff80109a2e:	48 c7 c7 5c b1 10 80 	mov    $0xffffffff8010b15c,%rdi
ffffffff80109a35:	e8 c5 6e ff ff       	callq  ffffffff801008ff <panic>
    pa = PTE_ADDR(*pte);
ffffffff80109a3a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80109a3e:	48 8b 00             	mov    (%rax),%rax
ffffffff80109a41:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff80109a47:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
    flags = PTE_FLAGS(*pte);
ffffffff80109a4b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80109a4f:	48 8b 00             	mov    (%rax),%rax
ffffffff80109a52:	25 ff 0f 00 00       	and    $0xfff,%eax
ffffffff80109a57:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
    if((mem = kalloc()) == 0)
ffffffff80109a5b:	e8 38 9e ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff80109a60:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
ffffffff80109a64:	48 83 7d c0 00       	cmpq   $0x0,-0x40(%rbp)
ffffffff80109a69:	74 72                	je     ffffffff80109add <copyuvm+0x124>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
ffffffff80109a6b:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80109a6f:	48 89 c7             	mov    %rax,%rdi
ffffffff80109a72:	e8 5e f9 ff ff       	callq  ffffffff801093d5 <p2v>
ffffffff80109a77:	48 89 c1             	mov    %rax,%rcx
ffffffff80109a7a:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80109a7e:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80109a83:	48 89 ce             	mov    %rcx,%rsi
ffffffff80109a86:	48 89 c7             	mov    %rax,%rdi
ffffffff80109a89:	e8 6e d2 ff ff       	callq  ffffffff80106cfc <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
ffffffff80109a8e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80109a92:	89 c3                	mov    %eax,%ebx
ffffffff80109a94:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
ffffffff80109a98:	48 89 c7             	mov    %rax,%rdi
ffffffff80109a9b:	e8 1b f9 ff ff       	callq  ffffffff801093bb <v2p>
ffffffff80109aa0:	48 89 c2             	mov    %rax,%rdx
ffffffff80109aa3:	48 8b 75 e8          	mov    -0x18(%rbp),%rsi
ffffffff80109aa7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109aab:	41 89 d8             	mov    %ebx,%r8d
ffffffff80109aae:	48 89 d1             	mov    %rdx,%rcx
ffffffff80109ab1:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80109ab6:	48 89 c7             	mov    %rax,%rdi
ffffffff80109ab9:	e8 f7 f9 ff ff       	callq  ffffffff801094b5 <mappages>
ffffffff80109abe:	85 c0                	test   %eax,%eax
ffffffff80109ac0:	78 1e                	js     ffffffff80109ae0 <copyuvm+0x127>
  uintp pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
ffffffff80109ac2:	48 81 45 e8 00 10 00 	addq   $0x1000,-0x18(%rbp)
ffffffff80109ac9:	00 
ffffffff80109aca:	8b 45 b4             	mov    -0x4c(%rbp),%eax
ffffffff80109acd:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
ffffffff80109ad1:	0f 87 19 ff ff ff    	ja     ffffffff801099f0 <copyuvm+0x37>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
ffffffff80109ad7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109adb:	eb 15                	jmp    ffffffff80109af2 <copyuvm+0x139>
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
ffffffff80109add:	90                   	nop
ffffffff80109ade:	eb 01                	jmp    ffffffff80109ae1 <copyuvm+0x128>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
ffffffff80109ae0:	90                   	nop
  }
  return d;

bad:
  freevm(d);
ffffffff80109ae1:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109ae5:	48 89 c7             	mov    %rax,%rdi
ffffffff80109ae8:	e8 cb fd ff ff       	callq  ffffffff801098b8 <freevm>
  return 0;
ffffffff80109aed:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80109af2:	48 83 c4 48          	add    $0x48,%rsp
ffffffff80109af6:	5b                   	pop    %rbx
ffffffff80109af7:	5d                   	pop    %rbp
ffffffff80109af8:	c3                   	retq   

ffffffff80109af9 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
ffffffff80109af9:	55                   	push   %rbp
ffffffff80109afa:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109afd:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80109b01:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80109b05:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
ffffffff80109b09:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
ffffffff80109b0d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109b11:	ba 00 00 00 00       	mov    $0x0,%edx
ffffffff80109b16:	48 89 ce             	mov    %rcx,%rsi
ffffffff80109b19:	48 89 c7             	mov    %rax,%rdi
ffffffff80109b1c:	e8 cc f8 ff ff       	callq  ffffffff801093ed <walkpgdir>
ffffffff80109b21:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  if((*pte & PTE_P) == 0)
ffffffff80109b25:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80109b29:	48 8b 00             	mov    (%rax),%rax
ffffffff80109b2c:	83 e0 01             	and    $0x1,%eax
ffffffff80109b2f:	48 85 c0             	test   %rax,%rax
ffffffff80109b32:	75 07                	jne    ffffffff80109b3b <uva2ka+0x42>
    return 0;
ffffffff80109b34:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80109b39:	eb 2b                	jmp    ffffffff80109b66 <uva2ka+0x6d>
  if((*pte & PTE_U) == 0)
ffffffff80109b3b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80109b3f:	48 8b 00             	mov    (%rax),%rax
ffffffff80109b42:	83 e0 04             	and    $0x4,%eax
ffffffff80109b45:	48 85 c0             	test   %rax,%rax
ffffffff80109b48:	75 07                	jne    ffffffff80109b51 <uva2ka+0x58>
    return 0;
ffffffff80109b4a:	b8 00 00 00 00       	mov    $0x0,%eax
ffffffff80109b4f:	eb 15                	jmp    ffffffff80109b66 <uva2ka+0x6d>
  return (char*)p2v(PTE_ADDR(*pte));
ffffffff80109b51:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80109b55:	48 8b 00             	mov    (%rax),%rax
ffffffff80109b58:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff80109b5e:	48 89 c7             	mov    %rax,%rdi
ffffffff80109b61:	e8 6f f8 ff ff       	callq  ffffffff801093d5 <p2v>
}
ffffffff80109b66:	c9                   	leaveq 
ffffffff80109b67:	c3                   	retq   

ffffffff80109b68 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
ffffffff80109b68:	55                   	push   %rbp
ffffffff80109b69:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109b6c:	48 83 ec 40          	sub    $0x40,%rsp
ffffffff80109b70:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
ffffffff80109b74:	89 75 d4             	mov    %esi,-0x2c(%rbp)
ffffffff80109b77:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
ffffffff80109b7b:	89 4d d0             	mov    %ecx,-0x30(%rbp)
  char *buf, *pa0;
  uintp n, va0;

  buf = (char*)p;
ffffffff80109b7e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
ffffffff80109b82:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  while(len > 0){
ffffffff80109b86:	e9 9c 00 00 00       	jmpq   ffffffff80109c27 <copyout+0xbf>
    va0 = (uint)PGROUNDDOWN(va);
ffffffff80109b8b:	8b 45 d4             	mov    -0x2c(%rbp),%eax
ffffffff80109b8e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
ffffffff80109b93:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    pa0 = uva2ka(pgdir, (char*)va0);
ffffffff80109b97:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80109b9b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80109b9f:	48 89 d6             	mov    %rdx,%rsi
ffffffff80109ba2:	48 89 c7             	mov    %rax,%rdi
ffffffff80109ba5:	e8 4f ff ff ff       	callq  ffffffff80109af9 <uva2ka>
ffffffff80109baa:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
    if(pa0 == 0)
ffffffff80109bae:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
ffffffff80109bb3:	75 07                	jne    ffffffff80109bbc <copyout+0x54>
      return -1;
ffffffff80109bb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffffffff80109bba:	eb 7a                	jmp    ffffffff80109c36 <copyout+0xce>
    n = PGSIZE - (va - va0);
ffffffff80109bbc:	8b 45 d4             	mov    -0x2c(%rbp),%eax
ffffffff80109bbf:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80109bc3:	48 29 c2             	sub    %rax,%rdx
ffffffff80109bc6:	48 89 d0             	mov    %rdx,%rax
ffffffff80109bc9:	48 05 00 10 00 00    	add    $0x1000,%rax
ffffffff80109bcf:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    if(n > len)
ffffffff80109bd3:	8b 45 d0             	mov    -0x30(%rbp),%eax
ffffffff80109bd6:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
ffffffff80109bda:	73 07                	jae    ffffffff80109be3 <copyout+0x7b>
      n = len;
ffffffff80109bdc:	8b 45 d0             	mov    -0x30(%rbp),%eax
ffffffff80109bdf:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    memmove(pa0 + (va - va0), buf, n);
ffffffff80109be3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109be7:	89 c6                	mov    %eax,%esi
ffffffff80109be9:	8b 45 d4             	mov    -0x2c(%rbp),%eax
ffffffff80109bec:	48 2b 45 e8          	sub    -0x18(%rbp),%rax
ffffffff80109bf0:	48 89 c2             	mov    %rax,%rdx
ffffffff80109bf3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109bf7:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
ffffffff80109bfb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80109bff:	89 f2                	mov    %esi,%edx
ffffffff80109c01:	48 89 c6             	mov    %rax,%rsi
ffffffff80109c04:	48 89 cf             	mov    %rcx,%rdi
ffffffff80109c07:	e8 f0 d0 ff ff       	callq  ffffffff80106cfc <memmove>
    len -= n;
ffffffff80109c0c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109c10:	29 45 d0             	sub    %eax,-0x30(%rbp)
    buf += n;
ffffffff80109c13:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109c17:	48 01 45 f8          	add    %rax,-0x8(%rbp)
    va = va0 + PGSIZE;
ffffffff80109c1b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109c1f:	05 00 10 00 00       	add    $0x1000,%eax
ffffffff80109c24:	89 45 d4             	mov    %eax,-0x2c(%rbp)
{
  char *buf, *pa0;
  uintp n, va0;

  buf = (char*)p;
  while(len > 0){
ffffffff80109c27:	83 7d d0 00          	cmpl   $0x0,-0x30(%rbp)
ffffffff80109c2b:	0f 85 5a ff ff ff    	jne    ffffffff80109b8b <copyout+0x23>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
ffffffff80109c31:	b8 00 00 00 00       	mov    $0x0,%eax
}
ffffffff80109c36:	c9                   	leaveq 
ffffffff80109c37:	c3                   	retq   

ffffffff80109c38 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
ffffffff80109c38:	55                   	push   %rbp
ffffffff80109c39:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109c3c:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80109c40:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80109c44:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  volatile ushort pd[5];

  pd[0] = size-1;
ffffffff80109c47:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80109c4a:	83 e8 01             	sub    $0x1,%eax
ffffffff80109c4d:	66 89 45 f0          	mov    %ax,-0x10(%rbp)
  pd[1] = (uintp)p;
ffffffff80109c51:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109c55:	66 89 45 f2          	mov    %ax,-0xe(%rbp)
  pd[2] = (uintp)p >> 16;
ffffffff80109c59:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109c5d:	48 c1 e8 10          	shr    $0x10,%rax
ffffffff80109c61:	66 89 45 f4          	mov    %ax,-0xc(%rbp)
#if X64
  pd[3] = (uintp)p >> 32;
ffffffff80109c65:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109c69:	48 c1 e8 20          	shr    $0x20,%rax
ffffffff80109c6d:	66 89 45 f6          	mov    %ax,-0xa(%rbp)
  pd[4] = (uintp)p >> 48;
ffffffff80109c71:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109c75:	48 c1 e8 30          	shr    $0x30,%rax
ffffffff80109c79:	66 89 45 f8          	mov    %ax,-0x8(%rbp)
#endif
  asm volatile("lgdt (%0)" : : "r" (pd));
ffffffff80109c7d:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80109c81:	0f 01 10             	lgdt   (%rax)
}
ffffffff80109c84:	90                   	nop
ffffffff80109c85:	c9                   	leaveq 
ffffffff80109c86:	c3                   	retq   

ffffffff80109c87 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
ffffffff80109c87:	55                   	push   %rbp
ffffffff80109c88:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109c8b:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff80109c8f:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80109c93:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  volatile ushort pd[5];

  pd[0] = size-1;
ffffffff80109c96:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80109c99:	83 e8 01             	sub    $0x1,%eax
ffffffff80109c9c:	66 89 45 f0          	mov    %ax,-0x10(%rbp)
  pd[1] = (uintp)p;
ffffffff80109ca0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109ca4:	66 89 45 f2          	mov    %ax,-0xe(%rbp)
  pd[2] = (uintp)p >> 16;
ffffffff80109ca8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109cac:	48 c1 e8 10          	shr    $0x10,%rax
ffffffff80109cb0:	66 89 45 f4          	mov    %ax,-0xc(%rbp)
#if X64
  pd[3] = (uintp)p >> 32;
ffffffff80109cb4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109cb8:	48 c1 e8 20          	shr    $0x20,%rax
ffffffff80109cbc:	66 89 45 f6          	mov    %ax,-0xa(%rbp)
  pd[4] = (uintp)p >> 48;
ffffffff80109cc0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109cc4:	48 c1 e8 30          	shr    $0x30,%rax
ffffffff80109cc8:	66 89 45 f8          	mov    %ax,-0x8(%rbp)
#endif
  asm volatile("lidt (%0)" : : "r" (pd));
ffffffff80109ccc:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
ffffffff80109cd0:	0f 01 18             	lidt   (%rax)
}
ffffffff80109cd3:	90                   	nop
ffffffff80109cd4:	c9                   	leaveq 
ffffffff80109cd5:	c3                   	retq   

ffffffff80109cd6 <ltr>:

static inline void
ltr(ushort sel)
{
ffffffff80109cd6:	55                   	push   %rbp
ffffffff80109cd7:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109cda:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80109cde:	89 f8                	mov    %edi,%eax
ffffffff80109ce0:	66 89 45 fc          	mov    %ax,-0x4(%rbp)
  asm volatile("ltr %0" : : "r" (sel));
ffffffff80109ce4:	0f b7 45 fc          	movzwl -0x4(%rbp),%eax
ffffffff80109ce8:	0f 00 d8             	ltr    %ax
}
ffffffff80109ceb:	90                   	nop
ffffffff80109cec:	c9                   	leaveq 
ffffffff80109ced:	c3                   	retq   

ffffffff80109cee <lcr3>:
  return val;
}

static inline void
lcr3(uintp val) 
{
ffffffff80109cee:	55                   	push   %rbp
ffffffff80109cef:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109cf2:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80109cf6:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  asm volatile("mov %0,%%cr3" : : "r" (val));
ffffffff80109cfa:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80109cfe:	0f 22 d8             	mov    %rax,%cr3
}
ffffffff80109d01:	90                   	nop
ffffffff80109d02:	c9                   	leaveq 
ffffffff80109d03:	c3                   	retq   

ffffffff80109d04 <v2p>:
#endif
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uintp v2p(void *a) { return ((uintp) (a)) - ((uintp)KERNBASE); }
ffffffff80109d04:	55                   	push   %rbp
ffffffff80109d05:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109d08:	48 83 ec 08          	sub    $0x8,%rsp
ffffffff80109d0c:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80109d10:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80109d14:	b8 00 00 00 80       	mov    $0x80000000,%eax
ffffffff80109d19:	48 01 d0             	add    %rdx,%rax
ffffffff80109d1c:	c9                   	leaveq 
ffffffff80109d1d:	c3                   	retq   

ffffffff80109d1e <tvinit>:
static pde_t *kpgdir0;
static pde_t *kpgdir1;

void wrmsr(uint msr, uint64 val);

void tvinit(void) {}
ffffffff80109d1e:	55                   	push   %rbp
ffffffff80109d1f:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109d22:	90                   	nop
ffffffff80109d23:	5d                   	pop    %rbp
ffffffff80109d24:	c3                   	retq   

ffffffff80109d25 <idtinit>:
void idtinit(void) {}
ffffffff80109d25:	55                   	push   %rbp
ffffffff80109d26:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109d29:	90                   	nop
ffffffff80109d2a:	5d                   	pop    %rbp
ffffffff80109d2b:	c3                   	retq   

ffffffff80109d2c <mkgate>:

static void mkgate(uint *idt, uint n, void *kva, uint pl, uint trap) {
ffffffff80109d2c:	55                   	push   %rbp
ffffffff80109d2d:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109d30:	48 83 ec 30          	sub    $0x30,%rsp
ffffffff80109d34:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
ffffffff80109d38:	89 75 e4             	mov    %esi,-0x1c(%rbp)
ffffffff80109d3b:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
ffffffff80109d3f:	89 4d e0             	mov    %ecx,-0x20(%rbp)
ffffffff80109d42:	44 89 45 d4          	mov    %r8d,-0x2c(%rbp)
  uint64 addr = (uint64) kva;
ffffffff80109d46:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80109d4a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  n *= 4;
ffffffff80109d4e:	c1 65 e4 02          	shll   $0x2,-0x1c(%rbp)
  trap = trap ? 0x8F00 : 0x8E00; // TRAP vs INTERRUPT gate;
ffffffff80109d52:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
ffffffff80109d56:	74 07                	je     ffffffff80109d5f <mkgate+0x33>
ffffffff80109d58:	b8 00 8f 00 00       	mov    $0x8f00,%eax
ffffffff80109d5d:	eb 05                	jmp    ffffffff80109d64 <mkgate+0x38>
ffffffff80109d5f:	b8 00 8e 00 00       	mov    $0x8e00,%eax
ffffffff80109d64:	89 45 d4             	mov    %eax,-0x2c(%rbp)
  idt[n+0] = (addr & 0xFFFF) | ((SEG_KCODE << 3) << 16);
ffffffff80109d67:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80109d6a:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80109d71:	00 
ffffffff80109d72:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109d76:	48 01 d0             	add    %rdx,%rax
ffffffff80109d79:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80109d7d:	0f b7 d2             	movzwl %dx,%edx
ffffffff80109d80:	81 ca 00 00 08 00    	or     $0x80000,%edx
ffffffff80109d86:	89 10                	mov    %edx,(%rax)
  idt[n+1] = (addr & 0xFFFF0000) | trap | ((pl & 3) << 13); // P=1 DPL=pl
ffffffff80109d88:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80109d8b:	83 c0 01             	add    $0x1,%eax
ffffffff80109d8e:	89 c0                	mov    %eax,%eax
ffffffff80109d90:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80109d97:	00 
ffffffff80109d98:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109d9c:	48 01 d0             	add    %rdx,%rax
ffffffff80109d9f:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80109da3:	66 ba 00 00          	mov    $0x0,%dx
ffffffff80109da7:	0b 55 d4             	or     -0x2c(%rbp),%edx
ffffffff80109daa:	8b 4d e0             	mov    -0x20(%rbp),%ecx
ffffffff80109dad:	83 e1 03             	and    $0x3,%ecx
ffffffff80109db0:	c1 e1 0d             	shl    $0xd,%ecx
ffffffff80109db3:	09 ca                	or     %ecx,%edx
ffffffff80109db5:	89 10                	mov    %edx,(%rax)
  idt[n+2] = addr >> 32;
ffffffff80109db7:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80109dba:	83 c0 02             	add    $0x2,%eax
ffffffff80109dbd:	89 c0                	mov    %eax,%eax
ffffffff80109dbf:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80109dc6:	00 
ffffffff80109dc7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109dcb:	48 01 d0             	add    %rdx,%rax
ffffffff80109dce:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
ffffffff80109dd2:	48 c1 ea 20          	shr    $0x20,%rdx
ffffffff80109dd6:	89 10                	mov    %edx,(%rax)
  idt[n+3] = 0;
ffffffff80109dd8:	8b 45 e4             	mov    -0x1c(%rbp),%eax
ffffffff80109ddb:	83 c0 03             	add    $0x3,%eax
ffffffff80109dde:	89 c0                	mov    %eax,%eax
ffffffff80109de0:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80109de7:	00 
ffffffff80109de8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109dec:	48 01 d0             	add    %rdx,%rax
ffffffff80109def:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
}
ffffffff80109df5:	90                   	nop
ffffffff80109df6:	c9                   	leaveq 
ffffffff80109df7:	c3                   	retq   

ffffffff80109df8 <tss_set_rsp>:

static void tss_set_rsp(uint *tss, uint n, uint64 rsp) {
ffffffff80109df8:	55                   	push   %rbp
ffffffff80109df9:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109dfc:	48 83 ec 18          	sub    $0x18,%rsp
ffffffff80109e00:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
ffffffff80109e04:	89 75 f4             	mov    %esi,-0xc(%rbp)
ffffffff80109e07:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  tss[n*2 + 1] = rsp;
ffffffff80109e0b:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80109e0e:	01 c0                	add    %eax,%eax
ffffffff80109e10:	83 c0 01             	add    $0x1,%eax
ffffffff80109e13:	89 c0                	mov    %eax,%eax
ffffffff80109e15:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80109e1c:	00 
ffffffff80109e1d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80109e21:	48 01 d0             	add    %rdx,%rax
ffffffff80109e24:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80109e28:	89 10                	mov    %edx,(%rax)
  tss[n*2 + 2] = rsp >> 32;
ffffffff80109e2a:	8b 45 f4             	mov    -0xc(%rbp),%eax
ffffffff80109e2d:	83 c0 01             	add    $0x1,%eax
ffffffff80109e30:	01 c0                	add    %eax,%eax
ffffffff80109e32:	89 c0                	mov    %eax,%eax
ffffffff80109e34:	48 8d 14 85 00 00 00 	lea    0x0(,%rax,4),%rdx
ffffffff80109e3b:	00 
ffffffff80109e3c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff80109e40:	48 01 d0             	add    %rdx,%rax
ffffffff80109e43:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80109e47:	48 c1 ea 20          	shr    $0x20,%rdx
ffffffff80109e4b:	89 10                	mov    %edx,(%rax)
}
ffffffff80109e4d:	90                   	nop
ffffffff80109e4e:	c9                   	leaveq 
ffffffff80109e4f:	c3                   	retq   

ffffffff80109e50 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
ffffffff80109e50:	55                   	push   %rbp
ffffffff80109e51:	48 89 e5             	mov    %rsp,%rbp
ffffffff80109e54:	48 83 ec 40          	sub    $0x40,%rsp
  uint64 *gdt;
  uint *tss;
  uint64 addr;
  void *local;
  struct cpu *c;
  uint *idt = (uint*) kalloc();
ffffffff80109e58:	e8 3b 9a ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff80109e5d:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  int n;
  memset(idt, 0, PGSIZE);
ffffffff80109e61:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109e65:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80109e6a:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80109e6f:	48 89 c7             	mov    %rax,%rdi
ffffffff80109e72:	e8 96 cd ff ff       	callq  ffffffff80106c0d <memset>

  for (n = 0; n < 256; n++)
ffffffff80109e77:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
ffffffff80109e7e:	eb 2b                	jmp    ffffffff80109eab <seginit+0x5b>
    mkgate(idt, n, vectors[n], 0, 0);
ffffffff80109e80:	8b 45 fc             	mov    -0x4(%rbp),%eax
ffffffff80109e83:	48 98                	cltq   
ffffffff80109e85:	48 8b 14 c5 78 c6 10 	mov    -0x7fef3988(,%rax,8),%rdx
ffffffff80109e8c:	80 
ffffffff80109e8d:	8b 75 fc             	mov    -0x4(%rbp),%esi
ffffffff80109e90:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109e94:	41 b8 00 00 00 00    	mov    $0x0,%r8d
ffffffff80109e9a:	b9 00 00 00 00       	mov    $0x0,%ecx
ffffffff80109e9f:	48 89 c7             	mov    %rax,%rdi
ffffffff80109ea2:	e8 85 fe ff ff       	callq  ffffffff80109d2c <mkgate>
  struct cpu *c;
  uint *idt = (uint*) kalloc();
  int n;
  memset(idt, 0, PGSIZE);

  for (n = 0; n < 256; n++)
ffffffff80109ea7:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
ffffffff80109eab:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%rbp)
ffffffff80109eb2:	7e cc                	jle    ffffffff80109e80 <seginit+0x30>
    mkgate(idt, n, vectors[n], 0, 0);
  mkgate(idt, 64, vectors[64], 3, 1);
ffffffff80109eb4:	48 8b 15 bd 29 00 00 	mov    0x29bd(%rip),%rdx        # ffffffff8010c878 <vectors+0x200>
ffffffff80109ebb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109ebf:	41 b8 01 00 00 00    	mov    $0x1,%r8d
ffffffff80109ec5:	b9 03 00 00 00       	mov    $0x3,%ecx
ffffffff80109eca:	be 40 00 00 00       	mov    $0x40,%esi
ffffffff80109ecf:	48 89 c7             	mov    %rax,%rdi
ffffffff80109ed2:	e8 55 fe ff ff       	callq  ffffffff80109d2c <mkgate>

  lidt((void*) idt, PGSIZE);
ffffffff80109ed7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff80109edb:	be 00 10 00 00       	mov    $0x1000,%esi
ffffffff80109ee0:	48 89 c7             	mov    %rax,%rdi
ffffffff80109ee3:	e8 9f fd ff ff       	callq  ffffffff80109c87 <lidt>

  // create a page for cpu local storage 
  local = kalloc();
ffffffff80109ee8:	e8 ab 99 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff80109eed:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  memset(local, 0, PGSIZE);
ffffffff80109ef1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109ef5:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff80109efa:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff80109eff:	48 89 c7             	mov    %rax,%rdi
ffffffff80109f02:	e8 06 cd ff ff       	callq  ffffffff80106c0d <memset>

  gdt = (uint64*) local;
ffffffff80109f07:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109f0b:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  tss = (uint*) (((char*) local) + 1024);
ffffffff80109f0f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109f13:	48 05 00 04 00 00    	add    $0x400,%rax
ffffffff80109f19:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
  tss[16] = 0x00680000; // IO Map Base = End of TSS
ffffffff80109f1d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80109f21:	48 83 c0 40          	add    $0x40,%rax
ffffffff80109f25:	c7 00 00 00 68 00    	movl   $0x680000,(%rax)

  // point FS smack in the middle of our local storage page
  wrmsr(0xC0000100, ((uint64) local) + (PGSIZE / 2));
ffffffff80109f2b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff80109f2f:	48 05 00 08 00 00    	add    $0x800,%rax
ffffffff80109f35:	48 89 c6             	mov    %rax,%rsi
ffffffff80109f38:	bf 00 01 00 c0       	mov    $0xc0000100,%edi
ffffffff80109f3d:	e8 d9 61 ff ff       	callq  ffffffff8010011b <wrmsr>

  c = &cpus[cpunum()];
ffffffff80109f42:	e8 9c 9d ff ff       	callq  ffffffff80103ce3 <cpunum>
ffffffff80109f47:	48 98                	cltq   
ffffffff80109f49:	48 89 c2             	mov    %rax,%rdx
ffffffff80109f4c:	48 89 d0             	mov    %rdx,%rax
ffffffff80109f4f:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80109f53:	48 89 c2             	mov    %rax,%rdx
ffffffff80109f56:	48 89 d0             	mov    %rdx,%rax
ffffffff80109f59:	48 c1 e0 04          	shl    $0x4,%rax
ffffffff80109f5d:	48 29 d0             	sub    %rdx,%rax
ffffffff80109f60:	48 05 60 07 19 80    	add    $0xffffffff80190760,%rax
ffffffff80109f66:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
  c->local = local;
ffffffff80109f6a:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80109f6e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff80109f72:	48 89 90 e8 00 00 00 	mov    %rdx,0xe8(%rax)

  cpu = c;
ffffffff80109f79:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
ffffffff80109f7d:	64 48 89 04 25 f0 ff 	mov    %rax,%fs:0xfffffffffffffff0
ffffffff80109f84:	ff ff 
  proc = 0;
ffffffff80109f86:	64 48 c7 04 25 f8 ff 	movq   $0x0,%fs:0xfffffffffffffff8
ffffffff80109f8d:	ff ff 00 00 00 00 

  addr = (uint64) tss;
ffffffff80109f93:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff80109f97:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
  gdt[0] =         0x0000000000000000;
ffffffff80109f9b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109f9f:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  gdt[SEG_KCODE] = 0x0020980000000000;  // Code, DPL=0, R/X
ffffffff80109fa6:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109faa:	48 83 c0 08          	add    $0x8,%rax
ffffffff80109fae:	48 bf 00 00 00 00 00 	movabs $0x20980000000000,%rdi
ffffffff80109fb5:	98 20 00 
ffffffff80109fb8:	48 89 38             	mov    %rdi,(%rax)
  gdt[SEG_UCODE] = 0x0020F80000000000;  // Code, DPL=3, R/X
ffffffff80109fbb:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109fbf:	48 83 c0 20          	add    $0x20,%rax
ffffffff80109fc3:	48 b9 00 00 00 00 00 	movabs $0x20f80000000000,%rcx
ffffffff80109fca:	f8 20 00 
ffffffff80109fcd:	48 89 08             	mov    %rcx,(%rax)
  gdt[SEG_KDATA] = 0x0000920000000000;  // Data, DPL=0, W
ffffffff80109fd0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109fd4:	48 83 c0 10          	add    $0x10,%rax
ffffffff80109fd8:	48 be 00 00 00 00 00 	movabs $0x920000000000,%rsi
ffffffff80109fdf:	92 00 00 
ffffffff80109fe2:	48 89 30             	mov    %rsi,(%rax)
  gdt[SEG_KCPU]  = 0x0000000000000000;  // unused
ffffffff80109fe5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109fe9:	48 83 c0 18          	add    $0x18,%rax
ffffffff80109fed:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  gdt[SEG_UDATA] = 0x0000F20000000000;  // Data, DPL=3, W
ffffffff80109ff4:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff80109ff8:	48 83 c0 28          	add    $0x28,%rax
ffffffff80109ffc:	48 bf 00 00 00 00 00 	movabs $0xf20000000000,%rdi
ffffffff8010a003:	f2 00 00 
ffffffff8010a006:	48 89 38             	mov    %rdi,(%rax)
  gdt[SEG_TSS+0] = (0x0067) | ((addr & 0xFFFFFF) << 16) |
ffffffff8010a009:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010a00d:	48 83 c0 30          	add    $0x30,%rax
ffffffff8010a011:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
ffffffff8010a015:	81 e2 ff ff ff 00    	and    $0xffffff,%edx
ffffffff8010a01b:	48 89 d1             	mov    %rdx,%rcx
ffffffff8010a01e:	48 c1 e1 10          	shl    $0x10,%rcx
                   (0x00E9LL << 40) | (((addr >> 24) & 0xFF) << 56);
ffffffff8010a022:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
ffffffff8010a026:	48 c1 ea 18          	shr    $0x18,%rdx
ffffffff8010a02a:	48 c1 e2 38          	shl    $0x38,%rdx
ffffffff8010a02e:	48 09 d1             	or     %rdx,%rcx
ffffffff8010a031:	48 ba 67 00 00 00 00 	movabs $0xe90000000067,%rdx
ffffffff8010a038:	e9 00 00 
ffffffff8010a03b:	48 09 ca             	or     %rcx,%rdx
  gdt[SEG_KCODE] = 0x0020980000000000;  // Code, DPL=0, R/X
  gdt[SEG_UCODE] = 0x0020F80000000000;  // Code, DPL=3, R/X
  gdt[SEG_KDATA] = 0x0000920000000000;  // Data, DPL=0, W
  gdt[SEG_KCPU]  = 0x0000000000000000;  // unused
  gdt[SEG_UDATA] = 0x0000F20000000000;  // Data, DPL=3, W
  gdt[SEG_TSS+0] = (0x0067) | ((addr & 0xFFFFFF) << 16) |
ffffffff8010a03e:	48 89 10             	mov    %rdx,(%rax)
                   (0x00E9LL << 40) | (((addr >> 24) & 0xFF) << 56);
  gdt[SEG_TSS+1] = (addr >> 32);
ffffffff8010a041:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010a045:	48 83 c0 38          	add    $0x38,%rax
ffffffff8010a049:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
ffffffff8010a04d:	48 c1 ea 20          	shr    $0x20,%rdx
ffffffff8010a051:	48 89 10             	mov    %rdx,(%rax)

  lgdt((void*) gdt, 8 * sizeof(uint64));
ffffffff8010a054:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010a058:	be 40 00 00 00       	mov    $0x40,%esi
ffffffff8010a05d:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a060:	e8 d3 fb ff ff       	callq  ffffffff80109c38 <lgdt>

  ltr(SEG_TSS << 3);
ffffffff8010a065:	bf 30 00 00 00       	mov    $0x30,%edi
ffffffff8010a06a:	e8 67 fc ff ff       	callq  ffffffff80109cd6 <ltr>
};
ffffffff8010a06f:	90                   	nop
ffffffff8010a070:	c9                   	leaveq 
ffffffff8010a071:	c3                   	retq   

ffffffff8010a072 <setupkvm>:
// because we need to find the other levels later, we'll stash
// backpointers to them in the top two entries of the level two
// table.
pde_t*
setupkvm(void)
{
ffffffff8010a072:	55                   	push   %rbp
ffffffff8010a073:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010a076:	53                   	push   %rbx
ffffffff8010a077:	48 83 ec 28          	sub    $0x28,%rsp
  pde_t *pml4 = (pde_t*) kalloc();
ffffffff8010a07b:	e8 18 98 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff8010a080:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  pde_t *pdpt = (pde_t*) kalloc();
ffffffff8010a084:	e8 0f 98 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff8010a089:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  pde_t *pgdir = (pde_t*) kalloc();
ffffffff8010a08d:	e8 06 98 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff8010a092:	48 89 45 d8          	mov    %rax,-0x28(%rbp)

  memset(pml4, 0, PGSIZE);
ffffffff8010a096:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a09a:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff8010a09f:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff8010a0a4:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a0a7:	e8 61 cb ff ff       	callq  ffffffff80106c0d <memset>
  memset(pdpt, 0, PGSIZE);
ffffffff8010a0ac:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010a0b0:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff8010a0b5:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff8010a0ba:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a0bd:	e8 4b cb ff ff       	callq  ffffffff80106c0d <memset>
  memset(pgdir, 0, PGSIZE);
ffffffff8010a0c2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010a0c6:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff8010a0cb:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff8010a0d0:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a0d3:	e8 35 cb ff ff       	callq  ffffffff80106c0d <memset>
  pml4[511] = v2p(kpdpt) | PTE_P | PTE_W | PTE_U;
ffffffff8010a0d8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a0dc:	48 8d 98 f8 0f 00 00 	lea    0xff8(%rax),%rbx
ffffffff8010a0e3:	48 8b 05 76 af 08 00 	mov    0x8af76(%rip),%rax        # ffffffff80195060 <kpdpt>
ffffffff8010a0ea:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a0ed:	e8 12 fc ff ff       	callq  ffffffff80109d04 <v2p>
ffffffff8010a0f2:	48 83 c8 07          	or     $0x7,%rax
ffffffff8010a0f6:	48 89 03             	mov    %rax,(%rbx)
  pml4[0] = v2p(pdpt) | PTE_P | PTE_W | PTE_U;
ffffffff8010a0f9:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010a0fd:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a100:	e8 ff fb ff ff       	callq  ffffffff80109d04 <v2p>
ffffffff8010a105:	48 83 c8 07          	or     $0x7,%rax
ffffffff8010a109:	48 89 c2             	mov    %rax,%rdx
ffffffff8010a10c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a110:	48 89 10             	mov    %rdx,(%rax)
  pdpt[0] = v2p(pgdir) | PTE_P | PTE_W | PTE_U; 
ffffffff8010a113:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010a117:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a11a:	e8 e5 fb ff ff       	callq  ffffffff80109d04 <v2p>
ffffffff8010a11f:	48 83 c8 07          	or     $0x7,%rax
ffffffff8010a123:	48 89 c2             	mov    %rax,%rdx
ffffffff8010a126:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
ffffffff8010a12a:	48 89 10             	mov    %rdx,(%rax)

  // virtual backpointers
  pgdir[511] = ((uintp) pml4) | PTE_P;
ffffffff8010a12d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010a131:	48 05 f8 0f 00 00    	add    $0xff8,%rax
ffffffff8010a137:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
ffffffff8010a13b:	48 83 ca 01          	or     $0x1,%rdx
ffffffff8010a13f:	48 89 10             	mov    %rdx,(%rax)
  pgdir[510] = ((uintp) pdpt) | PTE_P;
ffffffff8010a142:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
ffffffff8010a146:	48 05 f0 0f 00 00    	add    $0xff0,%rax
ffffffff8010a14c:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
ffffffff8010a150:	48 83 ca 01          	or     $0x1,%rdx
ffffffff8010a154:	48 89 10             	mov    %rdx,(%rax)

  return pgdir;
ffffffff8010a157:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
};
ffffffff8010a15b:	48 83 c4 28          	add    $0x28,%rsp
ffffffff8010a15f:	5b                   	pop    %rbx
ffffffff8010a160:	5d                   	pop    %rbp
ffffffff8010a161:	c3                   	retq   

ffffffff8010a162 <kvmalloc>:
// space for scheduler processes.
//
// linear map the first 4GB of physical memory starting at 0xFFFFFFFF80000000
void
kvmalloc(void)
{
ffffffff8010a162:	55                   	push   %rbp
ffffffff8010a163:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010a166:	53                   	push   %rbx
ffffffff8010a167:	48 83 ec 18          	sub    $0x18,%rsp
  int n;
  kpml4 = (pde_t*) kalloc();
ffffffff8010a16b:	e8 28 97 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff8010a170:	48 89 05 e1 ae 08 00 	mov    %rax,0x8aee1(%rip)        # ffffffff80195058 <kpml4>
  kpdpt = (pde_t*) kalloc();
ffffffff8010a177:	e8 1c 97 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff8010a17c:	48 89 05 dd ae 08 00 	mov    %rax,0x8aedd(%rip)        # ffffffff80195060 <kpdpt>
  kpgdir0 = (pde_t*) kalloc();
ffffffff8010a183:	e8 10 97 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff8010a188:	48 89 05 e1 ae 08 00 	mov    %rax,0x8aee1(%rip)        # ffffffff80195070 <kpgdir0>
  kpgdir1 = (pde_t*) kalloc();
ffffffff8010a18f:	e8 04 97 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff8010a194:	48 89 05 dd ae 08 00 	mov    %rax,0x8aedd(%rip)        # ffffffff80195078 <kpgdir1>
  iopgdir = (pde_t*) kalloc();
ffffffff8010a19b:	e8 f8 96 ff ff       	callq  ffffffff80103898 <kalloc>
ffffffff8010a1a0:	48 89 05 c1 ae 08 00 	mov    %rax,0x8aec1(%rip)        # ffffffff80195068 <iopgdir>
  memset(kpml4, 0, PGSIZE);
ffffffff8010a1a7:	48 8b 05 aa ae 08 00 	mov    0x8aeaa(%rip),%rax        # ffffffff80195058 <kpml4>
ffffffff8010a1ae:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff8010a1b3:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff8010a1b8:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a1bb:	e8 4d ca ff ff       	callq  ffffffff80106c0d <memset>
  memset(kpdpt, 0, PGSIZE);
ffffffff8010a1c0:	48 8b 05 99 ae 08 00 	mov    0x8ae99(%rip),%rax        # ffffffff80195060 <kpdpt>
ffffffff8010a1c7:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff8010a1cc:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff8010a1d1:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a1d4:	e8 34 ca ff ff       	callq  ffffffff80106c0d <memset>
  memset(iopgdir, 0, PGSIZE);
ffffffff8010a1d9:	48 8b 05 88 ae 08 00 	mov    0x8ae88(%rip),%rax        # ffffffff80195068 <iopgdir>
ffffffff8010a1e0:	ba 00 10 00 00       	mov    $0x1000,%edx
ffffffff8010a1e5:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff8010a1ea:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a1ed:	e8 1b ca ff ff       	callq  ffffffff80106c0d <memset>
  kpml4[511] = v2p(kpdpt) | PTE_P | PTE_W;
ffffffff8010a1f2:	48 8b 05 5f ae 08 00 	mov    0x8ae5f(%rip),%rax        # ffffffff80195058 <kpml4>
ffffffff8010a1f9:	48 8d 98 f8 0f 00 00 	lea    0xff8(%rax),%rbx
ffffffff8010a200:	48 8b 05 59 ae 08 00 	mov    0x8ae59(%rip),%rax        # ffffffff80195060 <kpdpt>
ffffffff8010a207:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a20a:	e8 f5 fa ff ff       	callq  ffffffff80109d04 <v2p>
ffffffff8010a20f:	48 83 c8 03          	or     $0x3,%rax
ffffffff8010a213:	48 89 03             	mov    %rax,(%rbx)
  kpdpt[511] = v2p(kpgdir1) | PTE_P | PTE_W;
ffffffff8010a216:	48 8b 05 43 ae 08 00 	mov    0x8ae43(%rip),%rax        # ffffffff80195060 <kpdpt>
ffffffff8010a21d:	48 8d 98 f8 0f 00 00 	lea    0xff8(%rax),%rbx
ffffffff8010a224:	48 8b 05 4d ae 08 00 	mov    0x8ae4d(%rip),%rax        # ffffffff80195078 <kpgdir1>
ffffffff8010a22b:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a22e:	e8 d1 fa ff ff       	callq  ffffffff80109d04 <v2p>
ffffffff8010a233:	48 83 c8 03          	or     $0x3,%rax
ffffffff8010a237:	48 89 03             	mov    %rax,(%rbx)
  kpdpt[510] = v2p(kpgdir0) | PTE_P | PTE_W;
ffffffff8010a23a:	48 8b 05 1f ae 08 00 	mov    0x8ae1f(%rip),%rax        # ffffffff80195060 <kpdpt>
ffffffff8010a241:	48 8d 98 f0 0f 00 00 	lea    0xff0(%rax),%rbx
ffffffff8010a248:	48 8b 05 21 ae 08 00 	mov    0x8ae21(%rip),%rax        # ffffffff80195070 <kpgdir0>
ffffffff8010a24f:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a252:	e8 ad fa ff ff       	callq  ffffffff80109d04 <v2p>
ffffffff8010a257:	48 83 c8 03          	or     $0x3,%rax
ffffffff8010a25b:	48 89 03             	mov    %rax,(%rbx)
  kpdpt[509] = v2p(iopgdir) | PTE_P | PTE_W;
ffffffff8010a25e:	48 8b 05 fb ad 08 00 	mov    0x8adfb(%rip),%rax        # ffffffff80195060 <kpdpt>
ffffffff8010a265:	48 8d 98 e8 0f 00 00 	lea    0xfe8(%rax),%rbx
ffffffff8010a26c:	48 8b 05 f5 ad 08 00 	mov    0x8adf5(%rip),%rax        # ffffffff80195068 <iopgdir>
ffffffff8010a273:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a276:	e8 89 fa ff ff       	callq  ffffffff80109d04 <v2p>
ffffffff8010a27b:	48 83 c8 03          	or     $0x3,%rax
ffffffff8010a27f:	48 89 03             	mov    %rax,(%rbx)
  for (n = 0; n < NPDENTRIES; n++) {
ffffffff8010a282:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)
ffffffff8010a289:	eb 4b                	jmp    ffffffff8010a2d6 <kvmalloc+0x174>
    kpgdir0[n] = (n << PDXSHIFT) | PTE_PS | PTE_P | PTE_W;
ffffffff8010a28b:	48 8b 05 de ad 08 00 	mov    0x8adde(%rip),%rax        # ffffffff80195070 <kpgdir0>
ffffffff8010a292:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff8010a295:	48 63 d2             	movslq %edx,%rdx
ffffffff8010a298:	48 c1 e2 03          	shl    $0x3,%rdx
ffffffff8010a29c:	48 01 c2             	add    %rax,%rdx
ffffffff8010a29f:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff8010a2a2:	c1 e0 15             	shl    $0x15,%eax
ffffffff8010a2a5:	0c 83                	or     $0x83,%al
ffffffff8010a2a7:	48 98                	cltq   
ffffffff8010a2a9:	48 89 02             	mov    %rax,(%rdx)
    kpgdir1[n] = ((n + 512) << PDXSHIFT) | PTE_PS | PTE_P | PTE_W;
ffffffff8010a2ac:	48 8b 05 c5 ad 08 00 	mov    0x8adc5(%rip),%rax        # ffffffff80195078 <kpgdir1>
ffffffff8010a2b3:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff8010a2b6:	48 63 d2             	movslq %edx,%rdx
ffffffff8010a2b9:	48 c1 e2 03          	shl    $0x3,%rdx
ffffffff8010a2bd:	48 01 c2             	add    %rax,%rdx
ffffffff8010a2c0:	8b 45 ec             	mov    -0x14(%rbp),%eax
ffffffff8010a2c3:	05 00 02 00 00       	add    $0x200,%eax
ffffffff8010a2c8:	c1 e0 15             	shl    $0x15,%eax
ffffffff8010a2cb:	0c 83                	or     $0x83,%al
ffffffff8010a2cd:	48 98                	cltq   
ffffffff8010a2cf:	48 89 02             	mov    %rax,(%rdx)
  memset(iopgdir, 0, PGSIZE);
  kpml4[511] = v2p(kpdpt) | PTE_P | PTE_W;
  kpdpt[511] = v2p(kpgdir1) | PTE_P | PTE_W;
  kpdpt[510] = v2p(kpgdir0) | PTE_P | PTE_W;
  kpdpt[509] = v2p(iopgdir) | PTE_P | PTE_W;
  for (n = 0; n < NPDENTRIES; n++) {
ffffffff8010a2d2:	83 45 ec 01          	addl   $0x1,-0x14(%rbp)
ffffffff8010a2d6:	81 7d ec ff 01 00 00 	cmpl   $0x1ff,-0x14(%rbp)
ffffffff8010a2dd:	7e ac                	jle    ffffffff8010a28b <kvmalloc+0x129>
    kpgdir0[n] = (n << PDXSHIFT) | PTE_PS | PTE_P | PTE_W;
    kpgdir1[n] = ((n + 512) << PDXSHIFT) | PTE_PS | PTE_P | PTE_W;
  }
  for (n = 0; n < 16; n++)
ffffffff8010a2df:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)
ffffffff8010a2e6:	eb 2c                	jmp    ffffffff8010a314 <kvmalloc+0x1b2>
    iopgdir[n] = (DEVSPACE + (n << PDXSHIFT)) | PTE_PS | PTE_P | PTE_W | PTE_PWT | PTE_PCD;
ffffffff8010a2e8:	48 8b 05 79 ad 08 00 	mov    0x8ad79(%rip),%rax        # ffffffff80195068 <iopgdir>
ffffffff8010a2ef:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff8010a2f2:	48 63 d2             	movslq %edx,%rdx
ffffffff8010a2f5:	48 c1 e2 03          	shl    $0x3,%rdx
ffffffff8010a2f9:	48 01 d0             	add    %rdx,%rax
ffffffff8010a2fc:	8b 55 ec             	mov    -0x14(%rbp),%edx
ffffffff8010a2ff:	c1 e2 15             	shl    $0x15,%edx
ffffffff8010a302:	81 ea 00 00 00 02    	sub    $0x2000000,%edx
ffffffff8010a308:	80 ca 9b             	or     $0x9b,%dl
ffffffff8010a30b:	89 d2                	mov    %edx,%edx
ffffffff8010a30d:	48 89 10             	mov    %rdx,(%rax)
  kpdpt[509] = v2p(iopgdir) | PTE_P | PTE_W;
  for (n = 0; n < NPDENTRIES; n++) {
    kpgdir0[n] = (n << PDXSHIFT) | PTE_PS | PTE_P | PTE_W;
    kpgdir1[n] = ((n + 512) << PDXSHIFT) | PTE_PS | PTE_P | PTE_W;
  }
  for (n = 0; n < 16; n++)
ffffffff8010a310:	83 45 ec 01          	addl   $0x1,-0x14(%rbp)
ffffffff8010a314:	83 7d ec 0f          	cmpl   $0xf,-0x14(%rbp)
ffffffff8010a318:	7e ce                	jle    ffffffff8010a2e8 <kvmalloc+0x186>
    iopgdir[n] = (DEVSPACE + (n << PDXSHIFT)) | PTE_PS | PTE_P | PTE_W | PTE_PWT | PTE_PCD;
  switchkvm();
ffffffff8010a31a:	e8 08 00 00 00       	callq  ffffffff8010a327 <switchkvm>
}
ffffffff8010a31f:	90                   	nop
ffffffff8010a320:	48 83 c4 18          	add    $0x18,%rsp
ffffffff8010a324:	5b                   	pop    %rbx
ffffffff8010a325:	5d                   	pop    %rbp
ffffffff8010a326:	c3                   	retq   

ffffffff8010a327 <switchkvm>:

void
switchkvm(void)
{
ffffffff8010a327:	55                   	push   %rbp
ffffffff8010a328:	48 89 e5             	mov    %rsp,%rbp
  lcr3(v2p(kpml4));
ffffffff8010a32b:	48 8b 05 26 ad 08 00 	mov    0x8ad26(%rip),%rax        # ffffffff80195058 <kpml4>
ffffffff8010a332:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a335:	e8 ca f9 ff ff       	callq  ffffffff80109d04 <v2p>
ffffffff8010a33a:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a33d:	e8 ac f9 ff ff       	callq  ffffffff80109cee <lcr3>
}
ffffffff8010a342:	90                   	nop
ffffffff8010a343:	5d                   	pop    %rbp
ffffffff8010a344:	c3                   	retq   

ffffffff8010a345 <switchuvm>:

void
switchuvm(struct proc *p)
{
ffffffff8010a345:	55                   	push   %rbp
ffffffff8010a346:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010a349:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010a34d:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  void *pml4;
  uint *tss;
  pushcli();
ffffffff8010a351:	e8 7a c7 ff ff       	callq  ffffffff80106ad0 <pushcli>
  if(p->pgdir == 0)
ffffffff8010a356:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a35a:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff8010a35e:	48 85 c0             	test   %rax,%rax
ffffffff8010a361:	75 0c                	jne    ffffffff8010a36f <switchuvm+0x2a>
    panic("switchuvm: no pgdir");
ffffffff8010a363:	48 c7 c7 76 b1 10 80 	mov    $0xffffffff8010b176,%rdi
ffffffff8010a36a:	e8 90 65 ff ff       	callq  ffffffff801008ff <panic>
  tss = (uint*) (((char*) cpu->local) + 1024);
ffffffff8010a36f:	64 48 8b 04 25 f0 ff 	mov    %fs:0xfffffffffffffff0,%rax
ffffffff8010a376:	ff ff 
ffffffff8010a378:	48 8b 80 e8 00 00 00 	mov    0xe8(%rax),%rax
ffffffff8010a37f:	48 05 00 04 00 00    	add    $0x400,%rax
ffffffff8010a385:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  tss_set_rsp(tss, 0, (uintp)proc->kstack + KSTACKSIZE);
ffffffff8010a389:	64 48 8b 04 25 f8 ff 	mov    %fs:0xfffffffffffffff8,%rax
ffffffff8010a390:	ff ff 
ffffffff8010a392:	48 8b 40 10          	mov    0x10(%rax),%rax
ffffffff8010a396:	48 8d 90 00 10 00 00 	lea    0x1000(%rax),%rdx
ffffffff8010a39d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010a3a1:	be 00 00 00 00       	mov    $0x0,%esi
ffffffff8010a3a6:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a3a9:	e8 4a fa ff ff       	callq  ffffffff80109df8 <tss_set_rsp>
  pml4 = (void*) PTE_ADDR(p->pgdir[511]);
ffffffff8010a3ae:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a3b2:	48 8b 40 08          	mov    0x8(%rax),%rax
ffffffff8010a3b6:	48 05 f8 0f 00 00    	add    $0xff8,%rax
ffffffff8010a3bc:	48 8b 00             	mov    (%rax),%rax
ffffffff8010a3bf:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffffffff8010a3c5:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  lcr3(v2p(pml4));
ffffffff8010a3c9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
ffffffff8010a3cd:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a3d0:	e8 2f f9 ff ff       	callq  ffffffff80109d04 <v2p>
ffffffff8010a3d5:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a3d8:	e8 11 f9 ff ff       	callq  ffffffff80109cee <lcr3>
  popcli();
ffffffff8010a3dd:	e8 3e c7 ff ff       	callq  ffffffff80106b20 <popcli>
}
ffffffff8010a3e2:	90                   	nop
ffffffff8010a3e3:	c9                   	leaveq 
ffffffff8010a3e4:	c3                   	retq   

ffffffff8010a3e5 <ideinit>:
static int disksize;
static uchar *memdisk;

void
ideinit(void)
{
ffffffff8010a3e5:	55                   	push   %rbp
ffffffff8010a3e6:	48 89 e5             	mov    %rsp,%rbp
  memdisk = _binary_fs_img_start;
ffffffff8010a3e9:	48 c7 05 94 ac 08 00 	movq   $0xffffffff8010cf26,0x8ac94(%rip)        # ffffffff80195088 <memdisk>
ffffffff8010a3f0:	26 cf 10 80 
  disksize = (uint)_binary_fs_img_size/BSIZE;
ffffffff8010a3f4:	48 c7 c0 00 d0 07 00 	mov    $0x7d000,%rax
ffffffff8010a3fb:	c1 e8 09             	shr    $0x9,%eax
ffffffff8010a3fe:	89 05 7c ac 08 00    	mov    %eax,0x8ac7c(%rip)        # ffffffff80195080 <disksize>
}
ffffffff8010a404:	90                   	nop
ffffffff8010a405:	5d                   	pop    %rbp
ffffffff8010a406:	c3                   	retq   

ffffffff8010a407 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
ffffffff8010a407:	55                   	push   %rbp
ffffffff8010a408:	48 89 e5             	mov    %rsp,%rbp
  // no-op
}
ffffffff8010a40b:	90                   	nop
ffffffff8010a40c:	5d                   	pop    %rbp
ffffffff8010a40d:	c3                   	retq   

ffffffff8010a40e <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
ffffffff8010a40e:	55                   	push   %rbp
ffffffff8010a40f:	48 89 e5             	mov    %rsp,%rbp
ffffffff8010a412:	48 83 ec 20          	sub    $0x20,%rsp
ffffffff8010a416:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  uchar *p;

  if(!(b->flags & B_BUSY))
ffffffff8010a41a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a41e:	8b 00                	mov    (%rax),%eax
ffffffff8010a420:	83 e0 01             	and    $0x1,%eax
ffffffff8010a423:	85 c0                	test   %eax,%eax
ffffffff8010a425:	75 0c                	jne    ffffffff8010a433 <iderw+0x25>
    panic("iderw: buf not busy");
ffffffff8010a427:	48 c7 c7 8a b1 10 80 	mov    $0xffffffff8010b18a,%rdi
ffffffff8010a42e:	e8 cc 64 ff ff       	callq  ffffffff801008ff <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
ffffffff8010a433:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a437:	8b 00                	mov    (%rax),%eax
ffffffff8010a439:	83 e0 06             	and    $0x6,%eax
ffffffff8010a43c:	83 f8 02             	cmp    $0x2,%eax
ffffffff8010a43f:	75 0c                	jne    ffffffff8010a44d <iderw+0x3f>
    panic("iderw: nothing to do");
ffffffff8010a441:	48 c7 c7 9e b1 10 80 	mov    $0xffffffff8010b19e,%rdi
ffffffff8010a448:	e8 b2 64 ff ff       	callq  ffffffff801008ff <panic>
  if(b->dev != 1)
ffffffff8010a44d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a451:	8b 40 04             	mov    0x4(%rax),%eax
ffffffff8010a454:	83 f8 01             	cmp    $0x1,%eax
ffffffff8010a457:	74 0c                	je     ffffffff8010a465 <iderw+0x57>
    panic("iderw: request not for disk 1");
ffffffff8010a459:	48 c7 c7 b3 b1 10 80 	mov    $0xffffffff8010b1b3,%rdi
ffffffff8010a460:	e8 9a 64 ff ff       	callq  ffffffff801008ff <panic>
  if(b->block >= disksize)
ffffffff8010a465:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a469:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff8010a46c:	8b 15 0e ac 08 00    	mov    0x8ac0e(%rip),%edx        # ffffffff80195080 <disksize>
ffffffff8010a472:	39 d0                	cmp    %edx,%eax
ffffffff8010a474:	72 0c                	jb     ffffffff8010a482 <iderw+0x74>
    panic("iderw: block out of range");
ffffffff8010a476:	48 c7 c7 d1 b1 10 80 	mov    $0xffffffff8010b1d1,%rdi
ffffffff8010a47d:	e8 7d 64 ff ff       	callq  ffffffff801008ff <panic>

  p = memdisk + b->block*BSIZE;
ffffffff8010a482:	48 8b 15 ff ab 08 00 	mov    0x8abff(%rip),%rdx        # ffffffff80195088 <memdisk>
ffffffff8010a489:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a48d:	8b 40 08             	mov    0x8(%rax),%eax
ffffffff8010a490:	c1 e0 09             	shl    $0x9,%eax
ffffffff8010a493:	89 c0                	mov    %eax,%eax
ffffffff8010a495:	48 01 d0             	add    %rdx,%rax
ffffffff8010a498:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  
  if(b->flags & B_DIRTY){
ffffffff8010a49c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a4a0:	8b 00                	mov    (%rax),%eax
ffffffff8010a4a2:	83 e0 04             	and    $0x4,%eax
ffffffff8010a4a5:	85 c0                	test   %eax,%eax
ffffffff8010a4a7:	74 2f                	je     ffffffff8010a4d8 <iderw+0xca>
    b->flags &= ~B_DIRTY;
ffffffff8010a4a9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a4ad:	8b 00                	mov    (%rax),%eax
ffffffff8010a4af:	83 e0 fb             	and    $0xfffffffb,%eax
ffffffff8010a4b2:	89 c2                	mov    %eax,%edx
ffffffff8010a4b4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a4b8:	89 10                	mov    %edx,(%rax)
    memmove(p, b->data, BSIZE);
ffffffff8010a4ba:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a4be:	48 8d 48 28          	lea    0x28(%rax),%rcx
ffffffff8010a4c2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010a4c6:	ba 00 02 00 00       	mov    $0x200,%edx
ffffffff8010a4cb:	48 89 ce             	mov    %rcx,%rsi
ffffffff8010a4ce:	48 89 c7             	mov    %rax,%rdi
ffffffff8010a4d1:	e8 26 c8 ff ff       	callq  ffffffff80106cfc <memmove>
ffffffff8010a4d6:	eb 1c                	jmp    ffffffff8010a4f4 <iderw+0xe6>
  } else
    memmove(b->data, p, BSIZE);
ffffffff8010a4d8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a4dc:	48 8d 48 28          	lea    0x28(%rax),%rcx
ffffffff8010a4e0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
ffffffff8010a4e4:	ba 00 02 00 00       	mov    $0x200,%edx
ffffffff8010a4e9:	48 89 c6             	mov    %rax,%rsi
ffffffff8010a4ec:	48 89 cf             	mov    %rcx,%rdi
ffffffff8010a4ef:	e8 08 c8 ff ff       	callq  ffffffff80106cfc <memmove>
  b->flags |= B_VALID;
ffffffff8010a4f4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a4f8:	8b 00                	mov    (%rax),%eax
ffffffff8010a4fa:	83 c8 02             	or     $0x2,%eax
ffffffff8010a4fd:	89 c2                	mov    %eax,%edx
ffffffff8010a4ff:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
ffffffff8010a503:	89 10                	mov    %edx,(%rax)
}
ffffffff8010a505:	90                   	nop
ffffffff8010a506:	c9                   	leaveq 
ffffffff8010a507:	c3                   	retq   
