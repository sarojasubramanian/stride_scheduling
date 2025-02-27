
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 4e 37 10 80       	mov    $0x8010374e,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 1c 86 10 	movl   $0x8010861c,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 8a 4f 00 00       	call   80104fd8 <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 70 05 11 80 64 	movl   $0x80110564,0x80110570
80100055:	05 11 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 74 05 11 80 64 	movl   $0x80110564,0x80110574
8010005f:	05 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 74 05 11 80       	mov    0x80110574,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 74 05 11 80       	mov    %eax,0x80110574

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint blockno)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 37 4f 00 00       	call   80104ff9 <acquire>

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 74 05 11 80       	mov    0x80110574,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->blockno == blockno){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	83 c8 01             	or     $0x1,%eax
801000f6:	89 c2                	mov    %eax,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 52 4f 00 00       	call   8010505b <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 da 4a 00 00       	call   80104bfe <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 70 05 11 80       	mov    0x80110570,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->blockno = blockno;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 da 4e 00 00       	call   8010505b <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
  }

  // Not cached; recycle some non-busy and clean buffer.
  // "clean" because B_DIRTY and !B_BUSY means log.c
  // hasn't yet committed the changes to the buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 64 05 11 80 	cmpl   $0x80110564,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 23 86 10 80 	movl   $0x80108623,(%esp)
8010019f:	e8 96 03 00 00       	call   8010053a <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, blockno);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID)) {
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 00 26 00 00       	call   801027d8 <iderw>
  }
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 34 86 10 80 	movl   $0x80108634,(%esp)
801001f6:	e8 3f 03 00 00       	call   8010053a <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	83 c8 04             	or     $0x4,%eax
80100203:	89 c2                	mov    %eax,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 c3 25 00 00       	call   801027d8 <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 3b 86 10 80 	movl   $0x8010863b,(%esp)
80100230:	e8 05 03 00 00       	call   8010053a <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 b8 4d 00 00       	call   80104ff9 <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 74 05 11 80    	mov    0x80110574,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 64 05 11 80 	movl   $0x80110564,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 74 05 11 80       	mov    0x80110574,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 74 05 11 80       	mov    %eax,0x80110574

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	83 e0 fe             	and    $0xfffffffe,%eax
80100290:	89 c2                	mov    %eax,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 38 4a 00 00       	call   80104cda <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 ad 4d 00 00       	call   8010505b <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	83 ec 14             	sub    $0x14,%esp
801002b6:	8b 45 08             	mov    0x8(%ebp),%eax
801002b9:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002bd:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
801002c1:	89 c2                	mov    %eax,%edx
801002c3:	ec                   	in     (%dx),%al
801002c4:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
801002c7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801002cb:	c9                   	leave  
801002cc:	c3                   	ret    

801002cd <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002cd:	55                   	push   %ebp
801002ce:	89 e5                	mov    %esp,%ebp
801002d0:	83 ec 08             	sub    $0x8,%esp
801002d3:	8b 55 08             	mov    0x8(%ebp),%edx
801002d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801002d9:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002dd:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002e0:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002e4:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002e8:	ee                   	out    %al,(%dx)
}
801002e9:	c9                   	leave  
801002ea:	c3                   	ret    

801002eb <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002eb:	55                   	push   %ebp
801002ec:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002ee:	fa                   	cli    
}
801002ef:	5d                   	pop    %ebp
801002f0:	c3                   	ret    

801002f1 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002f1:	55                   	push   %ebp
801002f2:	89 e5                	mov    %esp,%ebp
801002f4:	56                   	push   %esi
801002f5:	53                   	push   %ebx
801002f6:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
801002f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801002fd:	74 1c                	je     8010031b <printint+0x2a>
801002ff:	8b 45 08             	mov    0x8(%ebp),%eax
80100302:	c1 e8 1f             	shr    $0x1f,%eax
80100305:	0f b6 c0             	movzbl %al,%eax
80100308:	89 45 10             	mov    %eax,0x10(%ebp)
8010030b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010030f:	74 0a                	je     8010031b <printint+0x2a>
    x = -xx;
80100311:	8b 45 08             	mov    0x8(%ebp),%eax
80100314:	f7 d8                	neg    %eax
80100316:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100319:	eb 06                	jmp    80100321 <printint+0x30>
  else
    x = xx;
8010031b:	8b 45 08             	mov    0x8(%ebp),%eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100321:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100328:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010032b:	8d 41 01             	lea    0x1(%ecx),%eax
8010032e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100331:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100334:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100337:	ba 00 00 00 00       	mov    $0x0,%edx
8010033c:	f7 f3                	div    %ebx
8010033e:	89 d0                	mov    %edx,%eax
80100340:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
80100347:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
8010034b:	8b 75 0c             	mov    0xc(%ebp),%esi
8010034e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100351:	ba 00 00 00 00       	mov    $0x0,%edx
80100356:	f7 f6                	div    %esi
80100358:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010035b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010035f:	75 c7                	jne    80100328 <printint+0x37>

  if(sign)
80100361:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100365:	74 10                	je     80100377 <printint+0x86>
    buf[i++] = '-';
80100367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010036a:	8d 50 01             	lea    0x1(%eax),%edx
8010036d:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100370:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
80100375:	eb 18                	jmp    8010038f <printint+0x9e>
80100377:	eb 16                	jmp    8010038f <printint+0x9e>
    consputc(buf[i]);
80100379:	8d 55 e0             	lea    -0x20(%ebp),%edx
8010037c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010037f:	01 d0                	add    %edx,%eax
80100381:	0f b6 00             	movzbl (%eax),%eax
80100384:	0f be c0             	movsbl %al,%eax
80100387:	89 04 24             	mov    %eax,(%esp)
8010038a:	e8 c1 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
8010038f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100393:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100397:	79 e0                	jns    80100379 <printint+0x88>
    consputc(buf[i]);
}
80100399:	83 c4 30             	add    $0x30,%esp
8010039c:	5b                   	pop    %ebx
8010039d:	5e                   	pop    %esi
8010039e:	5d                   	pop    %ebp
8010039f:	c3                   	ret    

801003a0 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a0:	55                   	push   %ebp
801003a1:	89 e5                	mov    %esp,%ebp
801003a3:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a6:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ab:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b2:	74 0c                	je     801003c0 <cprintf+0x20>
    acquire(&cons.lock);
801003b4:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bb:	e8 39 4c 00 00       	call   80104ff9 <acquire>

  if (fmt == 0)
801003c0:	8b 45 08             	mov    0x8(%ebp),%eax
801003c3:	85 c0                	test   %eax,%eax
801003c5:	75 0c                	jne    801003d3 <cprintf+0x33>
    panic("null fmt");
801003c7:	c7 04 24 42 86 10 80 	movl   $0x80108642,(%esp)
801003ce:	e8 67 01 00 00       	call   8010053a <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d3:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e0:	e9 21 01 00 00       	jmp    80100506 <cprintf+0x166>
    if(c != '%'){
801003e5:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003e9:	74 10                	je     801003fb <cprintf+0x5b>
      consputc(c);
801003eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ee:	89 04 24             	mov    %eax,(%esp)
801003f1:	e8 5a 03 00 00       	call   80100750 <consputc>
      continue;
801003f6:	e9 07 01 00 00       	jmp    80100502 <cprintf+0x162>
    }
    c = fmt[++i] & 0xff;
801003fb:	8b 55 08             	mov    0x8(%ebp),%edx
801003fe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100402:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100405:	01 d0                	add    %edx,%eax
80100407:	0f b6 00             	movzbl (%eax),%eax
8010040a:	0f be c0             	movsbl %al,%eax
8010040d:	25 ff 00 00 00       	and    $0xff,%eax
80100412:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100415:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100419:	75 05                	jne    80100420 <cprintf+0x80>
      break;
8010041b:	e9 06 01 00 00       	jmp    80100526 <cprintf+0x186>
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4f                	je     80100477 <cprintf+0xd7>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0xa0>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13c>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xaf>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x14a>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 57                	je     8010049c <cprintf+0xfc>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2d                	je     80100477 <cprintf+0xd7>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x14a>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8d 50 04             	lea    0x4(%eax),%edx
80100455:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100458:	8b 00                	mov    (%eax),%eax
8010045a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80100461:	00 
80100462:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100469:	00 
8010046a:	89 04 24             	mov    %eax,(%esp)
8010046d:	e8 7f fe ff ff       	call   801002f1 <printint>
      break;
80100472:	e9 8b 00 00 00       	jmp    80100502 <cprintf+0x162>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100477:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010047a:	8d 50 04             	lea    0x4(%eax),%edx
8010047d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100480:	8b 00                	mov    (%eax),%eax
80100482:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100489:	00 
8010048a:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80100491:	00 
80100492:	89 04 24             	mov    %eax,(%esp)
80100495:	e8 57 fe ff ff       	call   801002f1 <printint>
      break;
8010049a:	eb 66                	jmp    80100502 <cprintf+0x162>
    case 's':
      if((s = (char*)*argp++) == 0)
8010049c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049f:	8d 50 04             	lea    0x4(%eax),%edx
801004a2:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004a5:	8b 00                	mov    (%eax),%eax
801004a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004aa:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004ae:	75 09                	jne    801004b9 <cprintf+0x119>
        s = "(null)";
801004b0:	c7 45 ec 4b 86 10 80 	movl   $0x8010864b,-0x14(%ebp)
      for(; *s; s++)
801004b7:	eb 17                	jmp    801004d0 <cprintf+0x130>
801004b9:	eb 15                	jmp    801004d0 <cprintf+0x130>
        consputc(*s);
801004bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004be:	0f b6 00             	movzbl (%eax),%eax
801004c1:	0f be c0             	movsbl %al,%eax
801004c4:	89 04 24             	mov    %eax,(%esp)
801004c7:	e8 84 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004cc:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 e1                	jne    801004bb <cprintf+0x11b>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x162>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x162>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 bf fe ff ff    	jne    801003e5 <cprintf+0x45>
      consputc(c);
      break;
    }
  }

  if(locking)
80100526:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052a:	74 0c                	je     80100538 <cprintf+0x198>
    release(&cons.lock);
8010052c:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100533:	e8 23 4b 00 00       	call   8010505b <release>
}
80100538:	c9                   	leave  
80100539:	c3                   	ret    

8010053a <panic>:

void
panic(char *s)
{
8010053a:	55                   	push   %ebp
8010053b:	89 e5                	mov    %esp,%ebp
8010053d:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100540:	e8 a6 fd ff ff       	call   801002eb <cli>
  cons.locking = 0;
80100545:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054c:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
8010054f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100555:	0f b6 00             	movzbl (%eax),%eax
80100558:	0f b6 c0             	movzbl %al,%eax
8010055b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010055f:	c7 04 24 52 86 10 80 	movl   $0x80108652,(%esp)
80100566:	e8 35 fe ff ff       	call   801003a0 <cprintf>
  cprintf(s);
8010056b:	8b 45 08             	mov    0x8(%ebp),%eax
8010056e:	89 04 24             	mov    %eax,(%esp)
80100571:	e8 2a fe ff ff       	call   801003a0 <cprintf>
  cprintf("\n");
80100576:	c7 04 24 61 86 10 80 	movl   $0x80108661,(%esp)
8010057d:	e8 1e fe ff ff       	call   801003a0 <cprintf>
  getcallerpcs(&s, pcs);
80100582:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100585:	89 44 24 04          	mov    %eax,0x4(%esp)
80100589:	8d 45 08             	lea    0x8(%ebp),%eax
8010058c:	89 04 24             	mov    %eax,(%esp)
8010058f:	e8 16 4b 00 00       	call   801050aa <getcallerpcs>
  for(i=0; i<10; i++)
80100594:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059b:	eb 1b                	jmp    801005b8 <panic+0x7e>
    cprintf(" %p", pcs[i]);
8010059d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a0:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801005a8:	c7 04 24 63 86 10 80 	movl   $0x80108663,(%esp)
801005af:	e8 ec fd ff ff       	call   801003a0 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005b8:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bc:	7e df                	jle    8010059d <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005be:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c5:	00 00 00 
  for(;;)
    ;
801005c8:	eb fe                	jmp    801005c8 <panic+0x8e>

801005ca <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005ca:	55                   	push   %ebp
801005cb:	89 e5                	mov    %esp,%ebp
801005cd:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d0:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005d7:	00 
801005d8:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005df:	e8 e9 fc ff ff       	call   801002cd <outb>
  pos = inb(CRTPORT+1) << 8;
801005e4:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005eb:	e8 c0 fc ff ff       	call   801002b0 <inb>
801005f0:	0f b6 c0             	movzbl %al,%eax
801005f3:	c1 e0 08             	shl    $0x8,%eax
801005f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005f9:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100600:	00 
80100601:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100608:	e8 c0 fc ff ff       	call   801002cd <outb>
  pos |= inb(CRTPORT+1);
8010060d:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100614:	e8 97 fc ff ff       	call   801002b0 <inb>
80100619:	0f b6 c0             	movzbl %al,%eax
8010061c:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
8010061f:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100623:	75 30                	jne    80100655 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100625:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100628:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010062d:	89 c8                	mov    %ecx,%eax
8010062f:	f7 ea                	imul   %edx
80100631:	c1 fa 05             	sar    $0x5,%edx
80100634:	89 c8                	mov    %ecx,%eax
80100636:	c1 f8 1f             	sar    $0x1f,%eax
80100639:	29 c2                	sub    %eax,%edx
8010063b:	89 d0                	mov    %edx,%eax
8010063d:	c1 e0 02             	shl    $0x2,%eax
80100640:	01 d0                	add    %edx,%eax
80100642:	c1 e0 04             	shl    $0x4,%eax
80100645:	29 c1                	sub    %eax,%ecx
80100647:	89 ca                	mov    %ecx,%edx
80100649:	b8 50 00 00 00       	mov    $0x50,%eax
8010064e:	29 d0                	sub    %edx,%eax
80100650:	01 45 f4             	add    %eax,-0xc(%ebp)
80100653:	eb 35                	jmp    8010068a <cgaputc+0xc0>
  else if(c == BACKSPACE){
80100655:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065c:	75 0c                	jne    8010066a <cgaputc+0xa0>
    if(pos > 0) --pos;
8010065e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100662:	7e 26                	jle    8010068a <cgaputc+0xc0>
80100664:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100668:	eb 20                	jmp    8010068a <cgaputc+0xc0>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066a:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
80100670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100673:	8d 50 01             	lea    0x1(%eax),%edx
80100676:	89 55 f4             	mov    %edx,-0xc(%ebp)
80100679:	01 c0                	add    %eax,%eax
8010067b:	8d 14 01             	lea    (%ecx,%eax,1),%edx
8010067e:	8b 45 08             	mov    0x8(%ebp),%eax
80100681:	0f b6 c0             	movzbl %al,%eax
80100684:	80 cc 07             	or     $0x7,%ah
80100687:	66 89 02             	mov    %ax,(%edx)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x11c>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 65 4c 00 00       	call   8010531c <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	8d 14 00             	lea    (%eax,%eax,1),%edx
801006c6:	a1 00 90 10 80       	mov    0x80109000,%eax
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 c8                	add    %ecx,%eax
801006d2:	89 54 24 08          	mov    %edx,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 04 24             	mov    %eax,(%esp)
801006e1:	e8 67 4b 00 00       	call   8010524d <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 d3 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 ba fb ff ff       	call   801002cd <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 a6 fb ff ff       	call   801002cd <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 90 fb ff ff       	call   801002cd <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 87 fb ff ff       	call   801002eb <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 e3 64 00 00       	call   80106c5e <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 d7 64 00 00       	call   80106c5e <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 cb 64 00 00       	call   80106c5e <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 be 64 00 00       	call   80106c5e <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 1f fe ff ff       	call   801005ca <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
801007ba:	e8 3a 48 00 00       	call   80104ff9 <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 37 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 64                	je     8010083a <consoleintr+0x8d>
801007d6:	e9 91 00 00 00       	jmp    8010086c <consoleintr+0xbf>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 55                	je     8010083a <consoleintr+0x8d>
801007e5:	e9 82 00 00 00       	jmp    8010086c <consoleintr+0xbf>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 91 45 00 00       	call   80104d80 <procdump>
      break;
801007ef:	e9 07 01 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 3c 08 11 80       	mov    %eax,0x8011083c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
80100816:	a1 38 08 11 80       	mov    0x80110838,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	74 16                	je     80100835 <consoleintr+0x88>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
8010081f:	a1 3c 08 11 80       	mov    0x8011083c,%eax
80100824:	83 e8 01             	sub    $0x1,%eax
80100827:	83 e0 7f             	and    $0x7f,%eax
8010082a:	0f b6 80 b4 07 11 80 	movzbl -0x7feef84c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100831:	3c 0a                	cmp    $0xa,%al
80100833:	75 bf                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100835:	e9 c1 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083a:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
80100840:	a1 38 08 11 80       	mov    0x80110838,%eax
80100845:	39 c2                	cmp    %eax,%edx
80100847:	74 1e                	je     80100867 <consoleintr+0xba>
        input.e--;
80100849:	a1 3c 08 11 80       	mov    0x8011083c,%eax
8010084e:	83 e8 01             	sub    $0x1,%eax
80100851:	a3 3c 08 11 80       	mov    %eax,0x8011083c
        consputc(BACKSPACE);
80100856:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
8010085d:	e8 ee fe ff ff       	call   80100750 <consputc>
      }
      break;
80100862:	e9 94 00 00 00       	jmp    801008fb <consoleintr+0x14e>
80100867:	e9 8f 00 00 00       	jmp    801008fb <consoleintr+0x14e>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100870:	0f 84 84 00 00 00    	je     801008fa <consoleintr+0x14d>
80100876:	8b 15 3c 08 11 80    	mov    0x8011083c,%edx
8010087c:	a1 34 08 11 80       	mov    0x80110834,%eax
80100881:	29 c2                	sub    %eax,%edx
80100883:	89 d0                	mov    %edx,%eax
80100885:	83 f8 7f             	cmp    $0x7f,%eax
80100888:	77 70                	ja     801008fa <consoleintr+0x14d>
        c = (c == '\r') ? '\n' : c;
8010088a:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
8010088e:	74 05                	je     80100895 <consoleintr+0xe8>
80100890:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100893:	eb 05                	jmp    8010089a <consoleintr+0xed>
80100895:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089a:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
8010089d:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008a2:	8d 50 01             	lea    0x1(%eax),%edx
801008a5:	89 15 3c 08 11 80    	mov    %edx,0x8011083c
801008ab:	83 e0 7f             	and    $0x7f,%eax
801008ae:	89 c2                	mov    %eax,%edx
801008b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008b3:	88 82 b4 07 11 80    	mov    %al,-0x7feef84c(%edx)
        consputc(c);
801008b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008bc:	89 04 24             	mov    %eax,(%esp)
801008bf:	e8 8c fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c4:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008c8:	74 18                	je     801008e2 <consoleintr+0x135>
801008ca:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008ce:	74 12                	je     801008e2 <consoleintr+0x135>
801008d0:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008d5:	8b 15 34 08 11 80    	mov    0x80110834,%edx
801008db:	83 ea 80             	sub    $0xffffff80,%edx
801008de:	39 d0                	cmp    %edx,%eax
801008e0:	75 18                	jne    801008fa <consoleintr+0x14d>
          input.w = input.e;
801008e2:	a1 3c 08 11 80       	mov    0x8011083c,%eax
801008e7:	a3 38 08 11 80       	mov    %eax,0x80110838
          wakeup(&input.r);
801008ec:	c7 04 24 34 08 11 80 	movl   $0x80110834,(%esp)
801008f3:	e8 e2 43 00 00       	call   80104cda <wakeup>
        }
      }
      break;
801008f8:	eb 00                	jmp    801008fa <consoleintr+0x14d>
801008fa:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
801008fb:	8b 45 08             	mov    0x8(%ebp),%eax
801008fe:	ff d0                	call   *%eax
80100900:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100903:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100907:	0f 89 b7 fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
8010090d:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100914:	e8 42 47 00 00       	call   8010505b <release>
}
80100919:	c9                   	leave  
8010091a:	c3                   	ret    

8010091b <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
8010091b:	55                   	push   %ebp
8010091c:	89 e5                	mov    %esp,%ebp
8010091e:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100921:	8b 45 08             	mov    0x8(%ebp),%eax
80100924:	89 04 24             	mov    %eax,(%esp)
80100927:	e8 7d 10 00 00       	call   801019a9 <iunlock>
  target = n;
8010092c:	8b 45 10             	mov    0x10(%ebp),%eax
8010092f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100932:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100939:	e8 bb 46 00 00       	call   80104ff9 <acquire>
  while(n > 0){
8010093e:	e9 aa 00 00 00       	jmp    801009ed <consoleread+0xd2>
    while(input.r == input.w){
80100943:	eb 42                	jmp    80100987 <consoleread+0x6c>
      if(proc->killed){
80100945:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010094b:	8b 40 24             	mov    0x24(%eax),%eax
8010094e:	85 c0                	test   %eax,%eax
80100950:	74 21                	je     80100973 <consoleread+0x58>
        release(&input.lock);
80100952:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100959:	e8 fd 46 00 00       	call   8010505b <release>
        ilock(ip);
8010095e:	8b 45 08             	mov    0x8(%ebp),%eax
80100961:	89 04 24             	mov    %eax,(%esp)
80100964:	e8 f2 0e 00 00       	call   8010185b <ilock>
        return -1;
80100969:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010096e:	e9 a5 00 00 00       	jmp    80100a18 <consoleread+0xfd>
      }
      sleep(&input.r, &input.lock);
80100973:	c7 44 24 04 80 07 11 	movl   $0x80110780,0x4(%esp)
8010097a:	80 
8010097b:	c7 04 24 34 08 11 80 	movl   $0x80110834,(%esp)
80100982:	e8 77 42 00 00       	call   80104bfe <sleep>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100987:	8b 15 34 08 11 80    	mov    0x80110834,%edx
8010098d:	a1 38 08 11 80       	mov    0x80110838,%eax
80100992:	39 c2                	cmp    %eax,%edx
80100994:	74 af                	je     80100945 <consoleread+0x2a>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100996:	a1 34 08 11 80       	mov    0x80110834,%eax
8010099b:	8d 50 01             	lea    0x1(%eax),%edx
8010099e:	89 15 34 08 11 80    	mov    %edx,0x80110834
801009a4:	83 e0 7f             	and    $0x7f,%eax
801009a7:	0f b6 80 b4 07 11 80 	movzbl -0x7feef84c(%eax),%eax
801009ae:	0f be c0             	movsbl %al,%eax
801009b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
801009b4:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009b8:	75 19                	jne    801009d3 <consoleread+0xb8>
      if(n < target){
801009ba:	8b 45 10             	mov    0x10(%ebp),%eax
801009bd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009c0:	73 0f                	jae    801009d1 <consoleread+0xb6>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009c2:	a1 34 08 11 80       	mov    0x80110834,%eax
801009c7:	83 e8 01             	sub    $0x1,%eax
801009ca:	a3 34 08 11 80       	mov    %eax,0x80110834
      }
      break;
801009cf:	eb 26                	jmp    801009f7 <consoleread+0xdc>
801009d1:	eb 24                	jmp    801009f7 <consoleread+0xdc>
    }
    *dst++ = c;
801009d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801009d6:	8d 50 01             	lea    0x1(%eax),%edx
801009d9:	89 55 0c             	mov    %edx,0xc(%ebp)
801009dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
801009df:	88 10                	mov    %dl,(%eax)
    --n;
801009e1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009e5:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009e9:	75 02                	jne    801009ed <consoleread+0xd2>
      break;
801009eb:	eb 0a                	jmp    801009f7 <consoleread+0xdc>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009ed:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009f1:	0f 8f 4c ff ff ff    	jg     80100943 <consoleread+0x28>
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&input.lock);
801009f7:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
801009fe:	e8 58 46 00 00       	call   8010505b <release>
  ilock(ip);
80100a03:	8b 45 08             	mov    0x8(%ebp),%eax
80100a06:	89 04 24             	mov    %eax,(%esp)
80100a09:	e8 4d 0e 00 00       	call   8010185b <ilock>

  return target - n;
80100a0e:	8b 45 10             	mov    0x10(%ebp),%eax
80100a11:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a14:	29 c2                	sub    %eax,%edx
80100a16:	89 d0                	mov    %edx,%eax
}
80100a18:	c9                   	leave  
80100a19:	c3                   	ret    

80100a1a <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a1a:	55                   	push   %ebp
80100a1b:	89 e5                	mov    %esp,%ebp
80100a1d:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a20:	8b 45 08             	mov    0x8(%ebp),%eax
80100a23:	89 04 24             	mov    %eax,(%esp)
80100a26:	e8 7e 0f 00 00       	call   801019a9 <iunlock>
  acquire(&cons.lock);
80100a2b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a32:	e8 c2 45 00 00       	call   80104ff9 <acquire>
  for(i = 0; i < n; i++)
80100a37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a3e:	eb 1d                	jmp    80100a5d <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a40:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a43:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a46:	01 d0                	add    %edx,%eax
80100a48:	0f b6 00             	movzbl (%eax),%eax
80100a4b:	0f be c0             	movsbl %al,%eax
80100a4e:	0f b6 c0             	movzbl %al,%eax
80100a51:	89 04 24             	mov    %eax,(%esp)
80100a54:	e8 f7 fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a60:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a63:	7c db                	jl     80100a40 <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a65:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a6c:	e8 ea 45 00 00       	call   8010505b <release>
  ilock(ip);
80100a71:	8b 45 08             	mov    0x8(%ebp),%eax
80100a74:	89 04 24             	mov    %eax,(%esp)
80100a77:	e8 df 0d 00 00       	call   8010185b <ilock>

  return n;
80100a7c:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a7f:	c9                   	leave  
80100a80:	c3                   	ret    

80100a81 <consoleinit>:

void
consoleinit(void)
{
80100a81:	55                   	push   %ebp
80100a82:	89 e5                	mov    %esp,%ebp
80100a84:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a87:	c7 44 24 04 67 86 10 	movl   $0x80108667,0x4(%esp)
80100a8e:	80 
80100a8f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a96:	e8 3d 45 00 00       	call   80104fd8 <initlock>
  initlock(&input.lock, "input");
80100a9b:	c7 44 24 04 6f 86 10 	movl   $0x8010866f,0x4(%esp)
80100aa2:	80 
80100aa3:	c7 04 24 80 07 11 80 	movl   $0x80110780,(%esp)
80100aaa:	e8 29 45 00 00       	call   80104fd8 <initlock>

  devsw[CONSOLE].write = consolewrite;
80100aaf:	c7 05 ec 11 11 80 1a 	movl   $0x80100a1a,0x801111ec
80100ab6:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ab9:	c7 05 e8 11 11 80 1b 	movl   $0x8010091b,0x801111e8
80100ac0:	09 10 80 
  cons.locking = 1;
80100ac3:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100aca:	00 00 00 

  picenable(IRQ_KBD);
80100acd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ad4:	e8 12 33 00 00       	call   80103deb <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ad9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100ae0:	00 
80100ae1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae8:	e8 a7 1e 00 00       	call   80102994 <ioapicenable>
}
80100aed:	c9                   	leave  
80100aee:	c3                   	ret    

80100aef <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100aef:	55                   	push   %ebp
80100af0:	89 e5                	mov    %esp,%ebp
80100af2:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  begin_op();
80100af8:	e8 4a 29 00 00       	call   80103447 <begin_op>
  if((ip = namei(path)) == 0){
80100afd:	8b 45 08             	mov    0x8(%ebp),%eax
80100b00:	89 04 24             	mov    %eax,(%esp)
80100b03:	e8 fe 18 00 00       	call   80102406 <namei>
80100b08:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b0b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b0f:	75 0f                	jne    80100b20 <exec+0x31>
    end_op();
80100b11:	e8 b5 29 00 00       	call   801034cb <end_op>
    return -1;
80100b16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1b:	e9 e8 03 00 00       	jmp    80100f08 <exec+0x419>
  }
  ilock(ip);
80100b20:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b23:	89 04 24             	mov    %eax,(%esp)
80100b26:	e8 30 0d 00 00       	call   8010185b <ilock>
  pgdir = 0;
80100b2b:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b32:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b39:	00 
80100b3a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b41:	00 
80100b42:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b48:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b4c:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b4f:	89 04 24             	mov    %eax,(%esp)
80100b52:	e8 11 12 00 00       	call   80101d68 <readi>
80100b57:	83 f8 33             	cmp    $0x33,%eax
80100b5a:	77 05                	ja     80100b61 <exec+0x72>
    goto bad;
80100b5c:	e9 7b 03 00 00       	jmp    80100edc <exec+0x3ed>
  if(elf.magic != ELF_MAGIC)
80100b61:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100b67:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100b6c:	74 05                	je     80100b73 <exec+0x84>
    goto bad;
80100b6e:	e9 69 03 00 00       	jmp    80100edc <exec+0x3ed>

  if((pgdir = setupkvm()) == 0)
80100b73:	e8 37 72 00 00       	call   80107daf <setupkvm>
80100b78:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100b7b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100b7f:	75 05                	jne    80100b86 <exec+0x97>
    goto bad;
80100b81:	e9 56 03 00 00       	jmp    80100edc <exec+0x3ed>

  // Load program into memory.
  sz = 0;
80100b86:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100b8d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b94:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100b9a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100b9d:	e9 cb 00 00 00       	jmp    80100c6d <exec+0x17e>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100ba2:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100ba5:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100bac:	00 
80100bad:	89 44 24 08          	mov    %eax,0x8(%esp)
80100bb1:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100bb7:	89 44 24 04          	mov    %eax,0x4(%esp)
80100bbb:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bbe:	89 04 24             	mov    %eax,(%esp)
80100bc1:	e8 a2 11 00 00       	call   80101d68 <readi>
80100bc6:	83 f8 20             	cmp    $0x20,%eax
80100bc9:	74 05                	je     80100bd0 <exec+0xe1>
      goto bad;
80100bcb:	e9 0c 03 00 00       	jmp    80100edc <exec+0x3ed>
    if(ph.type != ELF_PROG_LOAD)
80100bd0:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100bd6:	83 f8 01             	cmp    $0x1,%eax
80100bd9:	74 05                	je     80100be0 <exec+0xf1>
      continue;
80100bdb:	e9 80 00 00 00       	jmp    80100c60 <exec+0x171>
    if(ph.memsz < ph.filesz)
80100be0:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100be6:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100bec:	39 c2                	cmp    %eax,%edx
80100bee:	73 05                	jae    80100bf5 <exec+0x106>
      goto bad;
80100bf0:	e9 e7 02 00 00       	jmp    80100edc <exec+0x3ed>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100bf5:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100bfb:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c01:	01 d0                	add    %edx,%eax
80100c03:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c07:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c11:	89 04 24             	mov    %eax,(%esp)
80100c14:	e8 64 75 00 00       	call   8010817d <allocuvm>
80100c19:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c1c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c20:	75 05                	jne    80100c27 <exec+0x138>
      goto bad;
80100c22:	e9 b5 02 00 00       	jmp    80100edc <exec+0x3ed>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c27:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c2d:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c33:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c39:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c3d:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c41:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c44:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c48:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c4f:	89 04 24             	mov    %eax,(%esp)
80100c52:	e8 3b 74 00 00       	call   80108092 <loaduvm>
80100c57:	85 c0                	test   %eax,%eax
80100c59:	79 05                	jns    80100c60 <exec+0x171>
      goto bad;
80100c5b:	e9 7c 02 00 00       	jmp    80100edc <exec+0x3ed>
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c60:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100c64:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c67:	83 c0 20             	add    $0x20,%eax
80100c6a:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c6d:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100c74:	0f b7 c0             	movzwl %ax,%eax
80100c77:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100c7a:	0f 8f 22 ff ff ff    	jg     80100ba2 <exec+0xb3>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100c80:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c83:	89 04 24             	mov    %eax,(%esp)
80100c86:	e8 54 0e 00 00       	call   80101adf <iunlockput>
  end_op();
80100c8b:	e8 3b 28 00 00       	call   801034cb <end_op>
  ip = 0;
80100c90:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100c97:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c9a:	05 ff 0f 00 00       	add    $0xfff,%eax
80100c9f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100ca4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100ca7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100caa:	05 00 20 00 00       	add    $0x2000,%eax
80100caf:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cb3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cb6:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cbd:	89 04 24             	mov    %eax,(%esp)
80100cc0:	e8 b8 74 00 00       	call   8010817d <allocuvm>
80100cc5:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cc8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100ccc:	75 05                	jne    80100cd3 <exec+0x1e4>
    goto bad;
80100cce:	e9 09 02 00 00       	jmp    80100edc <exec+0x3ed>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100cd3:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cd6:	2d 00 20 00 00       	sub    $0x2000,%eax
80100cdb:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ce2:	89 04 24             	mov    %eax,(%esp)
80100ce5:	e8 c3 76 00 00       	call   801083ad <clearpteu>
  sp = sz;
80100cea:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100ced:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100cf0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100cf7:	e9 9a 00 00 00       	jmp    80100d96 <exec+0x2a7>
    if(argc >= MAXARG)
80100cfc:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d00:	76 05                	jbe    80100d07 <exec+0x218>
      goto bad;
80100d02:	e9 d5 01 00 00       	jmp    80100edc <exec+0x3ed>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d07:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d0a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d11:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d14:	01 d0                	add    %edx,%eax
80100d16:	8b 00                	mov    (%eax),%eax
80100d18:	89 04 24             	mov    %eax,(%esp)
80100d1b:	e8 97 47 00 00       	call   801054b7 <strlen>
80100d20:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100d23:	29 c2                	sub    %eax,%edx
80100d25:	89 d0                	mov    %edx,%eax
80100d27:	83 e8 01             	sub    $0x1,%eax
80100d2a:	83 e0 fc             	and    $0xfffffffc,%eax
80100d2d:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d33:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100d3a:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d3d:	01 d0                	add    %edx,%eax
80100d3f:	8b 00                	mov    (%eax),%eax
80100d41:	89 04 24             	mov    %eax,(%esp)
80100d44:	e8 6e 47 00 00       	call   801054b7 <strlen>
80100d49:	83 c0 01             	add    $0x1,%eax
80100d4c:	89 c2                	mov    %eax,%edx
80100d4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d51:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
80100d58:	8b 45 0c             	mov    0xc(%ebp),%eax
80100d5b:	01 c8                	add    %ecx,%eax
80100d5d:	8b 00                	mov    (%eax),%eax
80100d5f:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d63:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d67:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d6e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d71:	89 04 24             	mov    %eax,(%esp)
80100d74:	e8 f9 77 00 00       	call   80108572 <copyout>
80100d79:	85 c0                	test   %eax,%eax
80100d7b:	79 05                	jns    80100d82 <exec+0x293>
      goto bad;
80100d7d:	e9 5a 01 00 00       	jmp    80100edc <exec+0x3ed>
    ustack[3+argc] = sp;
80100d82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d85:	8d 50 03             	lea    0x3(%eax),%edx
80100d88:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100d8b:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d92:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100d96:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d99:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100da0:	8b 45 0c             	mov    0xc(%ebp),%eax
80100da3:	01 d0                	add    %edx,%eax
80100da5:	8b 00                	mov    (%eax),%eax
80100da7:	85 c0                	test   %eax,%eax
80100da9:	0f 85 4d ff ff ff    	jne    80100cfc <exec+0x20d>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100daf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100db2:	83 c0 03             	add    $0x3,%eax
80100db5:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dbc:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100dc0:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100dc7:	ff ff ff 
  ustack[1] = argc;
80100dca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dcd:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100dd3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dd6:	83 c0 01             	add    $0x1,%eax
80100dd9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100de0:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100de3:	29 d0                	sub    %edx,%eax
80100de5:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100deb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dee:	83 c0 04             	add    $0x4,%eax
80100df1:	c1 e0 02             	shl    $0x2,%eax
80100df4:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfa:	83 c0 04             	add    $0x4,%eax
80100dfd:	c1 e0 02             	shl    $0x2,%eax
80100e00:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e04:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e0a:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e0e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e11:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e18:	89 04 24             	mov    %eax,(%esp)
80100e1b:	e8 52 77 00 00       	call   80108572 <copyout>
80100e20:	85 c0                	test   %eax,%eax
80100e22:	79 05                	jns    80100e29 <exec+0x33a>
    goto bad;
80100e24:	e9 b3 00 00 00       	jmp    80100edc <exec+0x3ed>

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e29:	8b 45 08             	mov    0x8(%ebp),%eax
80100e2c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e32:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e35:	eb 17                	jmp    80100e4e <exec+0x35f>
    if(*s == '/')
80100e37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e3a:	0f b6 00             	movzbl (%eax),%eax
80100e3d:	3c 2f                	cmp    $0x2f,%al
80100e3f:	75 09                	jne    80100e4a <exec+0x35b>
      last = s+1;
80100e41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e44:	83 c0 01             	add    $0x1,%eax
80100e47:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e4a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e51:	0f b6 00             	movzbl (%eax),%eax
80100e54:	84 c0                	test   %al,%al
80100e56:	75 df                	jne    80100e37 <exec+0x348>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e5e:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e61:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e68:	00 
80100e69:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e6c:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e70:	89 14 24             	mov    %edx,(%esp)
80100e73:	e8 f5 45 00 00       	call   8010546d <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100e78:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e7e:	8b 40 04             	mov    0x4(%eax),%eax
80100e81:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100e84:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e8a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100e8d:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100e90:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e96:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100e99:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100e9b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ea1:	8b 40 18             	mov    0x18(%eax),%eax
80100ea4:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100eaa:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100ead:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb3:	8b 40 18             	mov    0x18(%eax),%eax
80100eb6:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100eb9:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100ebc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ec2:	89 04 24             	mov    %eax,(%esp)
80100ec5:	e8 d6 6f 00 00       	call   80107ea0 <switchuvm>
  freevm(oldpgdir);
80100eca:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100ecd:	89 04 24             	mov    %eax,(%esp)
80100ed0:	e8 3e 74 00 00       	call   80108313 <freevm>
  return 0;
80100ed5:	b8 00 00 00 00       	mov    $0x0,%eax
80100eda:	eb 2c                	jmp    80100f08 <exec+0x419>

 bad:
  if(pgdir)
80100edc:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100ee0:	74 0b                	je     80100eed <exec+0x3fe>
    freevm(pgdir);
80100ee2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ee5:	89 04 24             	mov    %eax,(%esp)
80100ee8:	e8 26 74 00 00       	call   80108313 <freevm>
  if(ip){
80100eed:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100ef1:	74 10                	je     80100f03 <exec+0x414>
    iunlockput(ip);
80100ef3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ef6:	89 04 24             	mov    %eax,(%esp)
80100ef9:	e8 e1 0b 00 00       	call   80101adf <iunlockput>
    end_op();
80100efe:	e8 c8 25 00 00       	call   801034cb <end_op>
  }
  return -1;
80100f03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f08:	c9                   	leave  
80100f09:	c3                   	ret    

80100f0a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f0a:	55                   	push   %ebp
80100f0b:	89 e5                	mov    %esp,%ebp
80100f0d:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f10:	c7 44 24 04 75 86 10 	movl   $0x80108675,0x4(%esp)
80100f17:	80 
80100f18:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f1f:	e8 b4 40 00 00       	call   80104fd8 <initlock>
}
80100f24:	c9                   	leave  
80100f25:	c3                   	ret    

80100f26 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f26:	55                   	push   %ebp
80100f27:	89 e5                	mov    %esp,%ebp
80100f29:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f2c:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f33:	e8 c1 40 00 00       	call   80104ff9 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f38:	c7 45 f4 74 08 11 80 	movl   $0x80110874,-0xc(%ebp)
80100f3f:	eb 29                	jmp    80100f6a <filealloc+0x44>
    if(f->ref == 0){
80100f41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f44:	8b 40 04             	mov    0x4(%eax),%eax
80100f47:	85 c0                	test   %eax,%eax
80100f49:	75 1b                	jne    80100f66 <filealloc+0x40>
      f->ref = 1;
80100f4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f4e:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f55:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f5c:	e8 fa 40 00 00       	call   8010505b <release>
      return f;
80100f61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f64:	eb 1e                	jmp    80100f84 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f66:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100f6a:	81 7d f4 d4 11 11 80 	cmpl   $0x801111d4,-0xc(%ebp)
80100f71:	72 ce                	jb     80100f41 <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100f73:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f7a:	e8 dc 40 00 00       	call   8010505b <release>
  return 0;
80100f7f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100f84:	c9                   	leave  
80100f85:	c3                   	ret    

80100f86 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100f86:	55                   	push   %ebp
80100f87:	89 e5                	mov    %esp,%ebp
80100f89:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100f8c:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100f93:	e8 61 40 00 00       	call   80104ff9 <acquire>
  if(f->ref < 1)
80100f98:	8b 45 08             	mov    0x8(%ebp),%eax
80100f9b:	8b 40 04             	mov    0x4(%eax),%eax
80100f9e:	85 c0                	test   %eax,%eax
80100fa0:	7f 0c                	jg     80100fae <filedup+0x28>
    panic("filedup");
80100fa2:	c7 04 24 7c 86 10 80 	movl   $0x8010867c,(%esp)
80100fa9:	e8 8c f5 ff ff       	call   8010053a <panic>
  f->ref++;
80100fae:	8b 45 08             	mov    0x8(%ebp),%eax
80100fb1:	8b 40 04             	mov    0x4(%eax),%eax
80100fb4:	8d 50 01             	lea    0x1(%eax),%edx
80100fb7:	8b 45 08             	mov    0x8(%ebp),%eax
80100fba:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80100fbd:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100fc4:	e8 92 40 00 00       	call   8010505b <release>
  return f;
80100fc9:	8b 45 08             	mov    0x8(%ebp),%eax
}
80100fcc:	c9                   	leave  
80100fcd:	c3                   	ret    

80100fce <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100fce:	55                   	push   %ebp
80100fcf:	89 e5                	mov    %esp,%ebp
80100fd1:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80100fd4:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80100fdb:	e8 19 40 00 00       	call   80104ff9 <acquire>
  if(f->ref < 1)
80100fe0:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe3:	8b 40 04             	mov    0x4(%eax),%eax
80100fe6:	85 c0                	test   %eax,%eax
80100fe8:	7f 0c                	jg     80100ff6 <fileclose+0x28>
    panic("fileclose");
80100fea:	c7 04 24 84 86 10 80 	movl   $0x80108684,(%esp)
80100ff1:	e8 44 f5 ff ff       	call   8010053a <panic>
  if(--f->ref > 0){
80100ff6:	8b 45 08             	mov    0x8(%ebp),%eax
80100ff9:	8b 40 04             	mov    0x4(%eax),%eax
80100ffc:	8d 50 ff             	lea    -0x1(%eax),%edx
80100fff:	8b 45 08             	mov    0x8(%ebp),%eax
80101002:	89 50 04             	mov    %edx,0x4(%eax)
80101005:	8b 45 08             	mov    0x8(%ebp),%eax
80101008:	8b 40 04             	mov    0x4(%eax),%eax
8010100b:	85 c0                	test   %eax,%eax
8010100d:	7e 11                	jle    80101020 <fileclose+0x52>
    release(&ftable.lock);
8010100f:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80101016:	e8 40 40 00 00       	call   8010505b <release>
8010101b:	e9 82 00 00 00       	jmp    801010a2 <fileclose+0xd4>
    return;
  }
  ff = *f;
80101020:	8b 45 08             	mov    0x8(%ebp),%eax
80101023:	8b 10                	mov    (%eax),%edx
80101025:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101028:	8b 50 04             	mov    0x4(%eax),%edx
8010102b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010102e:	8b 50 08             	mov    0x8(%eax),%edx
80101031:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101034:	8b 50 0c             	mov    0xc(%eax),%edx
80101037:	89 55 ec             	mov    %edx,-0x14(%ebp)
8010103a:	8b 50 10             	mov    0x10(%eax),%edx
8010103d:	89 55 f0             	mov    %edx,-0x10(%ebp)
80101040:	8b 40 14             	mov    0x14(%eax),%eax
80101043:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101046:	8b 45 08             	mov    0x8(%ebp),%eax
80101049:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
80101050:	8b 45 08             	mov    0x8(%ebp),%eax
80101053:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101059:	c7 04 24 40 08 11 80 	movl   $0x80110840,(%esp)
80101060:	e8 f6 3f 00 00       	call   8010505b <release>
  
  if(ff.type == FD_PIPE)
80101065:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101068:	83 f8 01             	cmp    $0x1,%eax
8010106b:	75 18                	jne    80101085 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010106d:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101071:	0f be d0             	movsbl %al,%edx
80101074:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101077:	89 54 24 04          	mov    %edx,0x4(%esp)
8010107b:	89 04 24             	mov    %eax,(%esp)
8010107e:	e8 18 30 00 00       	call   8010409b <pipeclose>
80101083:	eb 1d                	jmp    801010a2 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101085:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101088:	83 f8 02             	cmp    $0x2,%eax
8010108b:	75 15                	jne    801010a2 <fileclose+0xd4>
    begin_op();
8010108d:	e8 b5 23 00 00       	call   80103447 <begin_op>
    iput(ff.ip);
80101092:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101095:	89 04 24             	mov    %eax,(%esp)
80101098:	e8 71 09 00 00       	call   80101a0e <iput>
    end_op();
8010109d:	e8 29 24 00 00       	call   801034cb <end_op>
  }
}
801010a2:	c9                   	leave  
801010a3:	c3                   	ret    

801010a4 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010a4:	55                   	push   %ebp
801010a5:	89 e5                	mov    %esp,%ebp
801010a7:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010aa:	8b 45 08             	mov    0x8(%ebp),%eax
801010ad:	8b 00                	mov    (%eax),%eax
801010af:	83 f8 02             	cmp    $0x2,%eax
801010b2:	75 38                	jne    801010ec <filestat+0x48>
    ilock(f->ip);
801010b4:	8b 45 08             	mov    0x8(%ebp),%eax
801010b7:	8b 40 10             	mov    0x10(%eax),%eax
801010ba:	89 04 24             	mov    %eax,(%esp)
801010bd:	e8 99 07 00 00       	call   8010185b <ilock>
    stati(f->ip, st);
801010c2:	8b 45 08             	mov    0x8(%ebp),%eax
801010c5:	8b 40 10             	mov    0x10(%eax),%eax
801010c8:	8b 55 0c             	mov    0xc(%ebp),%edx
801010cb:	89 54 24 04          	mov    %edx,0x4(%esp)
801010cf:	89 04 24             	mov    %eax,(%esp)
801010d2:	e8 4c 0c 00 00       	call   80101d23 <stati>
    iunlock(f->ip);
801010d7:	8b 45 08             	mov    0x8(%ebp),%eax
801010da:	8b 40 10             	mov    0x10(%eax),%eax
801010dd:	89 04 24             	mov    %eax,(%esp)
801010e0:	e8 c4 08 00 00       	call   801019a9 <iunlock>
    return 0;
801010e5:	b8 00 00 00 00       	mov    $0x0,%eax
801010ea:	eb 05                	jmp    801010f1 <filestat+0x4d>
  }
  return -1;
801010ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801010f1:	c9                   	leave  
801010f2:	c3                   	ret    

801010f3 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801010f3:	55                   	push   %ebp
801010f4:	89 e5                	mov    %esp,%ebp
801010f6:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801010f9:	8b 45 08             	mov    0x8(%ebp),%eax
801010fc:	0f b6 40 08          	movzbl 0x8(%eax),%eax
80101100:	84 c0                	test   %al,%al
80101102:	75 0a                	jne    8010110e <fileread+0x1b>
    return -1;
80101104:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101109:	e9 9f 00 00 00       	jmp    801011ad <fileread+0xba>
  if(f->type == FD_PIPE)
8010110e:	8b 45 08             	mov    0x8(%ebp),%eax
80101111:	8b 00                	mov    (%eax),%eax
80101113:	83 f8 01             	cmp    $0x1,%eax
80101116:	75 1e                	jne    80101136 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101118:	8b 45 08             	mov    0x8(%ebp),%eax
8010111b:	8b 40 0c             	mov    0xc(%eax),%eax
8010111e:	8b 55 10             	mov    0x10(%ebp),%edx
80101121:	89 54 24 08          	mov    %edx,0x8(%esp)
80101125:	8b 55 0c             	mov    0xc(%ebp),%edx
80101128:	89 54 24 04          	mov    %edx,0x4(%esp)
8010112c:	89 04 24             	mov    %eax,(%esp)
8010112f:	e8 e8 30 00 00       	call   8010421c <piperead>
80101134:	eb 77                	jmp    801011ad <fileread+0xba>
  if(f->type == FD_INODE){
80101136:	8b 45 08             	mov    0x8(%ebp),%eax
80101139:	8b 00                	mov    (%eax),%eax
8010113b:	83 f8 02             	cmp    $0x2,%eax
8010113e:	75 61                	jne    801011a1 <fileread+0xae>
    ilock(f->ip);
80101140:	8b 45 08             	mov    0x8(%ebp),%eax
80101143:	8b 40 10             	mov    0x10(%eax),%eax
80101146:	89 04 24             	mov    %eax,(%esp)
80101149:	e8 0d 07 00 00       	call   8010185b <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010114e:	8b 4d 10             	mov    0x10(%ebp),%ecx
80101151:	8b 45 08             	mov    0x8(%ebp),%eax
80101154:	8b 50 14             	mov    0x14(%eax),%edx
80101157:	8b 45 08             	mov    0x8(%ebp),%eax
8010115a:	8b 40 10             	mov    0x10(%eax),%eax
8010115d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101161:	89 54 24 08          	mov    %edx,0x8(%esp)
80101165:	8b 55 0c             	mov    0xc(%ebp),%edx
80101168:	89 54 24 04          	mov    %edx,0x4(%esp)
8010116c:	89 04 24             	mov    %eax,(%esp)
8010116f:	e8 f4 0b 00 00       	call   80101d68 <readi>
80101174:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101177:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010117b:	7e 11                	jle    8010118e <fileread+0x9b>
      f->off += r;
8010117d:	8b 45 08             	mov    0x8(%ebp),%eax
80101180:	8b 50 14             	mov    0x14(%eax),%edx
80101183:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101186:	01 c2                	add    %eax,%edx
80101188:	8b 45 08             	mov    0x8(%ebp),%eax
8010118b:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010118e:	8b 45 08             	mov    0x8(%ebp),%eax
80101191:	8b 40 10             	mov    0x10(%eax),%eax
80101194:	89 04 24             	mov    %eax,(%esp)
80101197:	e8 0d 08 00 00       	call   801019a9 <iunlock>
    return r;
8010119c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010119f:	eb 0c                	jmp    801011ad <fileread+0xba>
  }
  panic("fileread");
801011a1:	c7 04 24 8e 86 10 80 	movl   $0x8010868e,(%esp)
801011a8:	e8 8d f3 ff ff       	call   8010053a <panic>
}
801011ad:	c9                   	leave  
801011ae:	c3                   	ret    

801011af <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011af:	55                   	push   %ebp
801011b0:	89 e5                	mov    %esp,%ebp
801011b2:	53                   	push   %ebx
801011b3:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
801011b6:	8b 45 08             	mov    0x8(%ebp),%eax
801011b9:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801011bd:	84 c0                	test   %al,%al
801011bf:	75 0a                	jne    801011cb <filewrite+0x1c>
    return -1;
801011c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011c6:	e9 20 01 00 00       	jmp    801012eb <filewrite+0x13c>
  if(f->type == FD_PIPE)
801011cb:	8b 45 08             	mov    0x8(%ebp),%eax
801011ce:	8b 00                	mov    (%eax),%eax
801011d0:	83 f8 01             	cmp    $0x1,%eax
801011d3:	75 21                	jne    801011f6 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
801011d5:	8b 45 08             	mov    0x8(%ebp),%eax
801011d8:	8b 40 0c             	mov    0xc(%eax),%eax
801011db:	8b 55 10             	mov    0x10(%ebp),%edx
801011de:	89 54 24 08          	mov    %edx,0x8(%esp)
801011e2:	8b 55 0c             	mov    0xc(%ebp),%edx
801011e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801011e9:	89 04 24             	mov    %eax,(%esp)
801011ec:	e8 3c 2f 00 00       	call   8010412d <pipewrite>
801011f1:	e9 f5 00 00 00       	jmp    801012eb <filewrite+0x13c>
  if(f->type == FD_INODE){
801011f6:	8b 45 08             	mov    0x8(%ebp),%eax
801011f9:	8b 00                	mov    (%eax),%eax
801011fb:	83 f8 02             	cmp    $0x2,%eax
801011fe:	0f 85 db 00 00 00    	jne    801012df <filewrite+0x130>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101204:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
8010120b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101212:	e9 a8 00 00 00       	jmp    801012bf <filewrite+0x110>
      int n1 = n - i;
80101217:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010121a:	8b 55 10             	mov    0x10(%ebp),%edx
8010121d:	29 c2                	sub    %eax,%edx
8010121f:	89 d0                	mov    %edx,%eax
80101221:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101224:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101227:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010122a:	7e 06                	jle    80101232 <filewrite+0x83>
        n1 = max;
8010122c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010122f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101232:	e8 10 22 00 00       	call   80103447 <begin_op>
      ilock(f->ip);
80101237:	8b 45 08             	mov    0x8(%ebp),%eax
8010123a:	8b 40 10             	mov    0x10(%eax),%eax
8010123d:	89 04 24             	mov    %eax,(%esp)
80101240:	e8 16 06 00 00       	call   8010185b <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101245:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80101248:	8b 45 08             	mov    0x8(%ebp),%eax
8010124b:	8b 50 14             	mov    0x14(%eax),%edx
8010124e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101251:	8b 45 0c             	mov    0xc(%ebp),%eax
80101254:	01 c3                	add    %eax,%ebx
80101256:	8b 45 08             	mov    0x8(%ebp),%eax
80101259:	8b 40 10             	mov    0x10(%eax),%eax
8010125c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80101260:	89 54 24 08          	mov    %edx,0x8(%esp)
80101264:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80101268:	89 04 24             	mov    %eax,(%esp)
8010126b:	e8 5c 0c 00 00       	call   80101ecc <writei>
80101270:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101273:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101277:	7e 11                	jle    8010128a <filewrite+0xdb>
        f->off += r;
80101279:	8b 45 08             	mov    0x8(%ebp),%eax
8010127c:	8b 50 14             	mov    0x14(%eax),%edx
8010127f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101282:	01 c2                	add    %eax,%edx
80101284:	8b 45 08             	mov    0x8(%ebp),%eax
80101287:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
8010128a:	8b 45 08             	mov    0x8(%ebp),%eax
8010128d:	8b 40 10             	mov    0x10(%eax),%eax
80101290:	89 04 24             	mov    %eax,(%esp)
80101293:	e8 11 07 00 00       	call   801019a9 <iunlock>
      end_op();
80101298:	e8 2e 22 00 00       	call   801034cb <end_op>

      if(r < 0)
8010129d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012a1:	79 02                	jns    801012a5 <filewrite+0xf6>
        break;
801012a3:	eb 26                	jmp    801012cb <filewrite+0x11c>
      if(r != n1)
801012a5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012a8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012ab:	74 0c                	je     801012b9 <filewrite+0x10a>
        panic("short filewrite");
801012ad:	c7 04 24 97 86 10 80 	movl   $0x80108697,(%esp)
801012b4:	e8 81 f2 ff ff       	call   8010053a <panic>
      i += r;
801012b9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012bc:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801012bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012c2:	3b 45 10             	cmp    0x10(%ebp),%eax
801012c5:	0f 8c 4c ff ff ff    	jl     80101217 <filewrite+0x68>
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801012cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012ce:	3b 45 10             	cmp    0x10(%ebp),%eax
801012d1:	75 05                	jne    801012d8 <filewrite+0x129>
801012d3:	8b 45 10             	mov    0x10(%ebp),%eax
801012d6:	eb 05                	jmp    801012dd <filewrite+0x12e>
801012d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012dd:	eb 0c                	jmp    801012eb <filewrite+0x13c>
  }
  panic("filewrite");
801012df:	c7 04 24 a7 86 10 80 	movl   $0x801086a7,(%esp)
801012e6:	e8 4f f2 ff ff       	call   8010053a <panic>
}
801012eb:	83 c4 24             	add    $0x24,%esp
801012ee:	5b                   	pop    %ebx
801012ef:	5d                   	pop    %ebp
801012f0:	c3                   	ret    

801012f1 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801012f1:	55                   	push   %ebp
801012f2:	89 e5                	mov    %esp,%ebp
801012f4:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801012f7:	8b 45 08             	mov    0x8(%ebp),%eax
801012fa:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101301:	00 
80101302:	89 04 24             	mov    %eax,(%esp)
80101305:	e8 9c ee ff ff       	call   801001a6 <bread>
8010130a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010130d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101310:	83 c0 18             	add    $0x18,%eax
80101313:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010131a:	00 
8010131b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010131f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101322:	89 04 24             	mov    %eax,(%esp)
80101325:	e8 f2 3f 00 00       	call   8010531c <memmove>
  brelse(bp);
8010132a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010132d:	89 04 24             	mov    %eax,(%esp)
80101330:	e8 e2 ee ff ff       	call   80100217 <brelse>
}
80101335:	c9                   	leave  
80101336:	c3                   	ret    

80101337 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101337:	55                   	push   %ebp
80101338:	89 e5                	mov    %esp,%ebp
8010133a:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010133d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101340:	8b 45 08             	mov    0x8(%ebp),%eax
80101343:	89 54 24 04          	mov    %edx,0x4(%esp)
80101347:	89 04 24             	mov    %eax,(%esp)
8010134a:	e8 57 ee ff ff       	call   801001a6 <bread>
8010134f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101352:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101355:	83 c0 18             	add    $0x18,%eax
80101358:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
8010135f:	00 
80101360:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101367:	00 
80101368:	89 04 24             	mov    %eax,(%esp)
8010136b:	e8 dd 3e 00 00       	call   8010524d <memset>
  log_write(bp);
80101370:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101373:	89 04 24             	mov    %eax,(%esp)
80101376:	e8 d7 22 00 00       	call   80103652 <log_write>
  brelse(bp);
8010137b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010137e:	89 04 24             	mov    %eax,(%esp)
80101381:	e8 91 ee ff ff       	call   80100217 <brelse>
}
80101386:	c9                   	leave  
80101387:	c3                   	ret    

80101388 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
80101388:	55                   	push   %ebp
80101389:	89 e5                	mov    %esp,%ebp
8010138b:	83 ec 38             	sub    $0x38,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
8010138e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101395:	8b 45 08             	mov    0x8(%ebp),%eax
80101398:	8d 55 d8             	lea    -0x28(%ebp),%edx
8010139b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010139f:	89 04 24             	mov    %eax,(%esp)
801013a2:	e8 4a ff ff ff       	call   801012f1 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801013a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013ae:	e9 07 01 00 00       	jmp    801014ba <balloc+0x132>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
801013b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
801013bc:	85 c0                	test   %eax,%eax
801013be:	0f 48 c2             	cmovs  %edx,%eax
801013c1:	c1 f8 0c             	sar    $0xc,%eax
801013c4:	8b 55 e0             	mov    -0x20(%ebp),%edx
801013c7:	c1 ea 03             	shr    $0x3,%edx
801013ca:	01 d0                	add    %edx,%eax
801013cc:	83 c0 03             	add    $0x3,%eax
801013cf:	89 44 24 04          	mov    %eax,0x4(%esp)
801013d3:	8b 45 08             	mov    0x8(%ebp),%eax
801013d6:	89 04 24             	mov    %eax,(%esp)
801013d9:	e8 c8 ed ff ff       	call   801001a6 <bread>
801013de:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801013e1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801013e8:	e9 9d 00 00 00       	jmp    8010148a <balloc+0x102>
      m = 1 << (bi % 8);
801013ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801013f0:	99                   	cltd   
801013f1:	c1 ea 1d             	shr    $0x1d,%edx
801013f4:	01 d0                	add    %edx,%eax
801013f6:	83 e0 07             	and    $0x7,%eax
801013f9:	29 d0                	sub    %edx,%eax
801013fb:	ba 01 00 00 00       	mov    $0x1,%edx
80101400:	89 c1                	mov    %eax,%ecx
80101402:	d3 e2                	shl    %cl,%edx
80101404:	89 d0                	mov    %edx,%eax
80101406:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101409:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010140c:	8d 50 07             	lea    0x7(%eax),%edx
8010140f:	85 c0                	test   %eax,%eax
80101411:	0f 48 c2             	cmovs  %edx,%eax
80101414:	c1 f8 03             	sar    $0x3,%eax
80101417:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010141a:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
8010141f:	0f b6 c0             	movzbl %al,%eax
80101422:	23 45 e8             	and    -0x18(%ebp),%eax
80101425:	85 c0                	test   %eax,%eax
80101427:	75 5d                	jne    80101486 <balloc+0xfe>
        bp->data[bi/8] |= m;  // Mark block in use.
80101429:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010142c:	8d 50 07             	lea    0x7(%eax),%edx
8010142f:	85 c0                	test   %eax,%eax
80101431:	0f 48 c2             	cmovs  %edx,%eax
80101434:	c1 f8 03             	sar    $0x3,%eax
80101437:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010143a:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010143f:	89 d1                	mov    %edx,%ecx
80101441:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101444:	09 ca                	or     %ecx,%edx
80101446:	89 d1                	mov    %edx,%ecx
80101448:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010144b:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
8010144f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101452:	89 04 24             	mov    %eax,(%esp)
80101455:	e8 f8 21 00 00       	call   80103652 <log_write>
        brelse(bp);
8010145a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010145d:	89 04 24             	mov    %eax,(%esp)
80101460:	e8 b2 ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101465:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101468:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010146b:	01 c2                	add    %eax,%edx
8010146d:	8b 45 08             	mov    0x8(%ebp),%eax
80101470:	89 54 24 04          	mov    %edx,0x4(%esp)
80101474:	89 04 24             	mov    %eax,(%esp)
80101477:	e8 bb fe ff ff       	call   80101337 <bzero>
        return b + bi;
8010147c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010147f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101482:	01 d0                	add    %edx,%eax
80101484:	eb 4e                	jmp    801014d4 <balloc+0x14c>

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101486:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010148a:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101491:	7f 15                	jg     801014a8 <balloc+0x120>
80101493:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101496:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101499:	01 d0                	add    %edx,%eax
8010149b:	89 c2                	mov    %eax,%edx
8010149d:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014a0:	39 c2                	cmp    %eax,%edx
801014a2:	0f 82 45 ff ff ff    	jb     801013ed <balloc+0x65>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
801014a8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014ab:	89 04 24             	mov    %eax,(%esp)
801014ae:	e8 64 ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
801014b3:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801014ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014bd:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014c0:	39 c2                	cmp    %eax,%edx
801014c2:	0f 82 eb fe ff ff    	jb     801013b3 <balloc+0x2b>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801014c8:	c7 04 24 b1 86 10 80 	movl   $0x801086b1,(%esp)
801014cf:	e8 66 f0 ff ff       	call   8010053a <panic>
}
801014d4:	c9                   	leave  
801014d5:	c3                   	ret    

801014d6 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801014d6:	55                   	push   %ebp
801014d7:	89 e5                	mov    %esp,%ebp
801014d9:	83 ec 38             	sub    $0x38,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
801014dc:	8d 45 dc             	lea    -0x24(%ebp),%eax
801014df:	89 44 24 04          	mov    %eax,0x4(%esp)
801014e3:	8b 45 08             	mov    0x8(%ebp),%eax
801014e6:	89 04 24             	mov    %eax,(%esp)
801014e9:	e8 03 fe ff ff       	call   801012f1 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801014ee:	8b 45 0c             	mov    0xc(%ebp),%eax
801014f1:	c1 e8 0c             	shr    $0xc,%eax
801014f4:	89 c2                	mov    %eax,%edx
801014f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801014f9:	c1 e8 03             	shr    $0x3,%eax
801014fc:	01 d0                	add    %edx,%eax
801014fe:	8d 50 03             	lea    0x3(%eax),%edx
80101501:	8b 45 08             	mov    0x8(%ebp),%eax
80101504:	89 54 24 04          	mov    %edx,0x4(%esp)
80101508:	89 04 24             	mov    %eax,(%esp)
8010150b:	e8 96 ec ff ff       	call   801001a6 <bread>
80101510:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101513:	8b 45 0c             	mov    0xc(%ebp),%eax
80101516:	25 ff 0f 00 00       	and    $0xfff,%eax
8010151b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010151e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101521:	99                   	cltd   
80101522:	c1 ea 1d             	shr    $0x1d,%edx
80101525:	01 d0                	add    %edx,%eax
80101527:	83 e0 07             	and    $0x7,%eax
8010152a:	29 d0                	sub    %edx,%eax
8010152c:	ba 01 00 00 00       	mov    $0x1,%edx
80101531:	89 c1                	mov    %eax,%ecx
80101533:	d3 e2                	shl    %cl,%edx
80101535:	89 d0                	mov    %edx,%eax
80101537:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
8010153a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010153d:	8d 50 07             	lea    0x7(%eax),%edx
80101540:	85 c0                	test   %eax,%eax
80101542:	0f 48 c2             	cmovs  %edx,%eax
80101545:	c1 f8 03             	sar    $0x3,%eax
80101548:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010154b:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101550:	0f b6 c0             	movzbl %al,%eax
80101553:	23 45 ec             	and    -0x14(%ebp),%eax
80101556:	85 c0                	test   %eax,%eax
80101558:	75 0c                	jne    80101566 <bfree+0x90>
    panic("freeing free block");
8010155a:	c7 04 24 c7 86 10 80 	movl   $0x801086c7,(%esp)
80101561:	e8 d4 ef ff ff       	call   8010053a <panic>
  bp->data[bi/8] &= ~m;
80101566:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101569:	8d 50 07             	lea    0x7(%eax),%edx
8010156c:	85 c0                	test   %eax,%eax
8010156e:	0f 48 c2             	cmovs  %edx,%eax
80101571:	c1 f8 03             	sar    $0x3,%eax
80101574:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101577:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010157c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
8010157f:	f7 d1                	not    %ecx
80101581:	21 ca                	and    %ecx,%edx
80101583:	89 d1                	mov    %edx,%ecx
80101585:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101588:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010158c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010158f:	89 04 24             	mov    %eax,(%esp)
80101592:	e8 bb 20 00 00       	call   80103652 <log_write>
  brelse(bp);
80101597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010159a:	89 04 24             	mov    %eax,(%esp)
8010159d:	e8 75 ec ff ff       	call   80100217 <brelse>
}
801015a2:	c9                   	leave  
801015a3:	c3                   	ret    

801015a4 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
801015a4:	55                   	push   %ebp
801015a5:	89 e5                	mov    %esp,%ebp
801015a7:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
801015aa:	c7 44 24 04 da 86 10 	movl   $0x801086da,0x4(%esp)
801015b1:	80 
801015b2:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801015b9:	e8 1a 3a 00 00       	call   80104fd8 <initlock>
}
801015be:	c9                   	leave  
801015bf:	c3                   	ret    

801015c0 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
801015c0:	55                   	push   %ebp
801015c1:	89 e5                	mov    %esp,%ebp
801015c3:	83 ec 38             	sub    $0x38,%esp
801015c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801015c9:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
801015cd:	8b 45 08             	mov    0x8(%ebp),%eax
801015d0:	8d 55 dc             	lea    -0x24(%ebp),%edx
801015d3:	89 54 24 04          	mov    %edx,0x4(%esp)
801015d7:	89 04 24             	mov    %eax,(%esp)
801015da:	e8 12 fd ff ff       	call   801012f1 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801015df:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801015e6:	e9 98 00 00 00       	jmp    80101683 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801015eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015ee:	c1 e8 03             	shr    $0x3,%eax
801015f1:	83 c0 02             	add    $0x2,%eax
801015f4:	89 44 24 04          	mov    %eax,0x4(%esp)
801015f8:	8b 45 08             	mov    0x8(%ebp),%eax
801015fb:	89 04 24             	mov    %eax,(%esp)
801015fe:	e8 a3 eb ff ff       	call   801001a6 <bread>
80101603:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101606:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101609:	8d 50 18             	lea    0x18(%eax),%edx
8010160c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010160f:	83 e0 07             	and    $0x7,%eax
80101612:	c1 e0 06             	shl    $0x6,%eax
80101615:	01 d0                	add    %edx,%eax
80101617:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
8010161a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010161d:	0f b7 00             	movzwl (%eax),%eax
80101620:	66 85 c0             	test   %ax,%ax
80101623:	75 4f                	jne    80101674 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101625:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010162c:	00 
8010162d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101634:	00 
80101635:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101638:	89 04 24             	mov    %eax,(%esp)
8010163b:	e8 0d 3c 00 00       	call   8010524d <memset>
      dip->type = type;
80101640:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101643:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101647:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
8010164a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010164d:	89 04 24             	mov    %eax,(%esp)
80101650:	e8 fd 1f 00 00       	call   80103652 <log_write>
      brelse(bp);
80101655:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101658:	89 04 24             	mov    %eax,(%esp)
8010165b:	e8 b7 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101660:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101663:	89 44 24 04          	mov    %eax,0x4(%esp)
80101667:	8b 45 08             	mov    0x8(%ebp),%eax
8010166a:	89 04 24             	mov    %eax,(%esp)
8010166d:	e8 e5 00 00 00       	call   80101757 <iget>
80101672:	eb 29                	jmp    8010169d <ialloc+0xdd>
    }
    brelse(bp);
80101674:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101677:	89 04 24             	mov    %eax,(%esp)
8010167a:	e8 98 eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
8010167f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101683:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101686:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101689:	39 c2                	cmp    %eax,%edx
8010168b:	0f 82 5a ff ff ff    	jb     801015eb <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101691:	c7 04 24 e1 86 10 80 	movl   $0x801086e1,(%esp)
80101698:	e8 9d ee ff ff       	call   8010053a <panic>
}
8010169d:	c9                   	leave  
8010169e:	c3                   	ret    

8010169f <iupdate>:

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
8010169f:	55                   	push   %ebp
801016a0:	89 e5                	mov    %esp,%ebp
801016a2:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
801016a5:	8b 45 08             	mov    0x8(%ebp),%eax
801016a8:	8b 40 04             	mov    0x4(%eax),%eax
801016ab:	c1 e8 03             	shr    $0x3,%eax
801016ae:	8d 50 02             	lea    0x2(%eax),%edx
801016b1:	8b 45 08             	mov    0x8(%ebp),%eax
801016b4:	8b 00                	mov    (%eax),%eax
801016b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801016ba:	89 04 24             	mov    %eax,(%esp)
801016bd:	e8 e4 ea ff ff       	call   801001a6 <bread>
801016c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
801016c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016c8:	8d 50 18             	lea    0x18(%eax),%edx
801016cb:	8b 45 08             	mov    0x8(%ebp),%eax
801016ce:	8b 40 04             	mov    0x4(%eax),%eax
801016d1:	83 e0 07             	and    $0x7,%eax
801016d4:	c1 e0 06             	shl    $0x6,%eax
801016d7:	01 d0                	add    %edx,%eax
801016d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801016dc:	8b 45 08             	mov    0x8(%ebp),%eax
801016df:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801016e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016e6:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801016e9:	8b 45 08             	mov    0x8(%ebp),%eax
801016ec:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801016f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016f3:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801016f7:	8b 45 08             	mov    0x8(%ebp),%eax
801016fa:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801016fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101701:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101705:	8b 45 08             	mov    0x8(%ebp),%eax
80101708:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010170c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010170f:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101713:	8b 45 08             	mov    0x8(%ebp),%eax
80101716:	8b 50 18             	mov    0x18(%eax),%edx
80101719:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010171c:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
8010171f:	8b 45 08             	mov    0x8(%ebp),%eax
80101722:	8d 50 1c             	lea    0x1c(%eax),%edx
80101725:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101728:	83 c0 0c             	add    $0xc,%eax
8010172b:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101732:	00 
80101733:	89 54 24 04          	mov    %edx,0x4(%esp)
80101737:	89 04 24             	mov    %eax,(%esp)
8010173a:	e8 dd 3b 00 00       	call   8010531c <memmove>
  log_write(bp);
8010173f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101742:	89 04 24             	mov    %eax,(%esp)
80101745:	e8 08 1f 00 00       	call   80103652 <log_write>
  brelse(bp);
8010174a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010174d:	89 04 24             	mov    %eax,(%esp)
80101750:	e8 c2 ea ff ff       	call   80100217 <brelse>
}
80101755:	c9                   	leave  
80101756:	c3                   	ret    

80101757 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101757:	55                   	push   %ebp
80101758:	89 e5                	mov    %esp,%ebp
8010175a:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
8010175d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101764:	e8 90 38 00 00       	call   80104ff9 <acquire>

  // Is the inode already cached?
  empty = 0;
80101769:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101770:	c7 45 f4 74 12 11 80 	movl   $0x80111274,-0xc(%ebp)
80101777:	eb 59                	jmp    801017d2 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101779:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010177c:	8b 40 08             	mov    0x8(%eax),%eax
8010177f:	85 c0                	test   %eax,%eax
80101781:	7e 35                	jle    801017b8 <iget+0x61>
80101783:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101786:	8b 00                	mov    (%eax),%eax
80101788:	3b 45 08             	cmp    0x8(%ebp),%eax
8010178b:	75 2b                	jne    801017b8 <iget+0x61>
8010178d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101790:	8b 40 04             	mov    0x4(%eax),%eax
80101793:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101796:	75 20                	jne    801017b8 <iget+0x61>
      ip->ref++;
80101798:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010179b:	8b 40 08             	mov    0x8(%eax),%eax
8010179e:	8d 50 01             	lea    0x1(%eax),%edx
801017a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017a4:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
801017a7:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801017ae:	e8 a8 38 00 00       	call   8010505b <release>
      return ip;
801017b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017b6:	eb 6f                	jmp    80101827 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
801017b8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017bc:	75 10                	jne    801017ce <iget+0x77>
801017be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017c1:	8b 40 08             	mov    0x8(%eax),%eax
801017c4:	85 c0                	test   %eax,%eax
801017c6:	75 06                	jne    801017ce <iget+0x77>
      empty = ip;
801017c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017cb:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017ce:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
801017d2:	81 7d f4 14 22 11 80 	cmpl   $0x80112214,-0xc(%ebp)
801017d9:	72 9e                	jb     80101779 <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801017db:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801017df:	75 0c                	jne    801017ed <iget+0x96>
    panic("iget: no inodes");
801017e1:	c7 04 24 f3 86 10 80 	movl   $0x801086f3,(%esp)
801017e8:	e8 4d ed ff ff       	call   8010053a <panic>

  ip = empty;
801017ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801017f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f6:	8b 55 08             	mov    0x8(%ebp),%edx
801017f9:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801017fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fe:	8b 55 0c             	mov    0xc(%ebp),%edx
80101801:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101807:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010180e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101811:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101818:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
8010181f:	e8 37 38 00 00       	call   8010505b <release>

  return ip;
80101824:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101827:	c9                   	leave  
80101828:	c3                   	ret    

80101829 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101829:	55                   	push   %ebp
8010182a:	89 e5                	mov    %esp,%ebp
8010182c:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
8010182f:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101836:	e8 be 37 00 00       	call   80104ff9 <acquire>
  ip->ref++;
8010183b:	8b 45 08             	mov    0x8(%ebp),%eax
8010183e:	8b 40 08             	mov    0x8(%eax),%eax
80101841:	8d 50 01             	lea    0x1(%eax),%edx
80101844:	8b 45 08             	mov    0x8(%ebp),%eax
80101847:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010184a:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101851:	e8 05 38 00 00       	call   8010505b <release>
  return ip;
80101856:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101859:	c9                   	leave  
8010185a:	c3                   	ret    

8010185b <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
8010185b:	55                   	push   %ebp
8010185c:	89 e5                	mov    %esp,%ebp
8010185e:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101861:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101865:	74 0a                	je     80101871 <ilock+0x16>
80101867:	8b 45 08             	mov    0x8(%ebp),%eax
8010186a:	8b 40 08             	mov    0x8(%eax),%eax
8010186d:	85 c0                	test   %eax,%eax
8010186f:	7f 0c                	jg     8010187d <ilock+0x22>
    panic("ilock");
80101871:	c7 04 24 03 87 10 80 	movl   $0x80108703,(%esp)
80101878:	e8 bd ec ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
8010187d:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101884:	e8 70 37 00 00       	call   80104ff9 <acquire>
  while(ip->flags & I_BUSY)
80101889:	eb 13                	jmp    8010189e <ilock+0x43>
    sleep(ip, &icache.lock);
8010188b:	c7 44 24 04 40 12 11 	movl   $0x80111240,0x4(%esp)
80101892:	80 
80101893:	8b 45 08             	mov    0x8(%ebp),%eax
80101896:	89 04 24             	mov    %eax,(%esp)
80101899:	e8 60 33 00 00       	call   80104bfe <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
8010189e:	8b 45 08             	mov    0x8(%ebp),%eax
801018a1:	8b 40 0c             	mov    0xc(%eax),%eax
801018a4:	83 e0 01             	and    $0x1,%eax
801018a7:	85 c0                	test   %eax,%eax
801018a9:	75 e0                	jne    8010188b <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
801018ab:	8b 45 08             	mov    0x8(%ebp),%eax
801018ae:	8b 40 0c             	mov    0xc(%eax),%eax
801018b1:	83 c8 01             	or     $0x1,%eax
801018b4:	89 c2                	mov    %eax,%edx
801018b6:	8b 45 08             	mov    0x8(%ebp),%eax
801018b9:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
801018bc:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801018c3:	e8 93 37 00 00       	call   8010505b <release>

  if(!(ip->flags & I_VALID)){
801018c8:	8b 45 08             	mov    0x8(%ebp),%eax
801018cb:	8b 40 0c             	mov    0xc(%eax),%eax
801018ce:	83 e0 02             	and    $0x2,%eax
801018d1:	85 c0                	test   %eax,%eax
801018d3:	0f 85 ce 00 00 00    	jne    801019a7 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
801018d9:	8b 45 08             	mov    0x8(%ebp),%eax
801018dc:	8b 40 04             	mov    0x4(%eax),%eax
801018df:	c1 e8 03             	shr    $0x3,%eax
801018e2:	8d 50 02             	lea    0x2(%eax),%edx
801018e5:	8b 45 08             	mov    0x8(%ebp),%eax
801018e8:	8b 00                	mov    (%eax),%eax
801018ea:	89 54 24 04          	mov    %edx,0x4(%esp)
801018ee:	89 04 24             	mov    %eax,(%esp)
801018f1:	e8 b0 e8 ff ff       	call   801001a6 <bread>
801018f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801018f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018fc:	8d 50 18             	lea    0x18(%eax),%edx
801018ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101902:	8b 40 04             	mov    0x4(%eax),%eax
80101905:	83 e0 07             	and    $0x7,%eax
80101908:	c1 e0 06             	shl    $0x6,%eax
8010190b:	01 d0                	add    %edx,%eax
8010190d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101910:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101913:	0f b7 10             	movzwl (%eax),%edx
80101916:	8b 45 08             	mov    0x8(%ebp),%eax
80101919:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010191d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101920:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101924:	8b 45 08             	mov    0x8(%ebp),%eax
80101927:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
8010192b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010192e:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101932:	8b 45 08             	mov    0x8(%ebp),%eax
80101935:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101939:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010193c:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101940:	8b 45 08             	mov    0x8(%ebp),%eax
80101943:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101947:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010194a:	8b 50 08             	mov    0x8(%eax),%edx
8010194d:	8b 45 08             	mov    0x8(%ebp),%eax
80101950:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101953:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101956:	8d 50 0c             	lea    0xc(%eax),%edx
80101959:	8b 45 08             	mov    0x8(%ebp),%eax
8010195c:	83 c0 1c             	add    $0x1c,%eax
8010195f:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101966:	00 
80101967:	89 54 24 04          	mov    %edx,0x4(%esp)
8010196b:	89 04 24             	mov    %eax,(%esp)
8010196e:	e8 a9 39 00 00       	call   8010531c <memmove>
    brelse(bp);
80101973:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101976:	89 04 24             	mov    %eax,(%esp)
80101979:	e8 99 e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
8010197e:	8b 45 08             	mov    0x8(%ebp),%eax
80101981:	8b 40 0c             	mov    0xc(%eax),%eax
80101984:	83 c8 02             	or     $0x2,%eax
80101987:	89 c2                	mov    %eax,%edx
80101989:	8b 45 08             	mov    0x8(%ebp),%eax
8010198c:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
8010198f:	8b 45 08             	mov    0x8(%ebp),%eax
80101992:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101996:	66 85 c0             	test   %ax,%ax
80101999:	75 0c                	jne    801019a7 <ilock+0x14c>
      panic("ilock: no type");
8010199b:	c7 04 24 09 87 10 80 	movl   $0x80108709,(%esp)
801019a2:	e8 93 eb ff ff       	call   8010053a <panic>
  }
}
801019a7:	c9                   	leave  
801019a8:	c3                   	ret    

801019a9 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
801019a9:	55                   	push   %ebp
801019aa:	89 e5                	mov    %esp,%ebp
801019ac:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
801019af:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801019b3:	74 17                	je     801019cc <iunlock+0x23>
801019b5:	8b 45 08             	mov    0x8(%ebp),%eax
801019b8:	8b 40 0c             	mov    0xc(%eax),%eax
801019bb:	83 e0 01             	and    $0x1,%eax
801019be:	85 c0                	test   %eax,%eax
801019c0:	74 0a                	je     801019cc <iunlock+0x23>
801019c2:	8b 45 08             	mov    0x8(%ebp),%eax
801019c5:	8b 40 08             	mov    0x8(%eax),%eax
801019c8:	85 c0                	test   %eax,%eax
801019ca:	7f 0c                	jg     801019d8 <iunlock+0x2f>
    panic("iunlock");
801019cc:	c7 04 24 18 87 10 80 	movl   $0x80108718,(%esp)
801019d3:	e8 62 eb ff ff       	call   8010053a <panic>

  acquire(&icache.lock);
801019d8:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
801019df:	e8 15 36 00 00       	call   80104ff9 <acquire>
  ip->flags &= ~I_BUSY;
801019e4:	8b 45 08             	mov    0x8(%ebp),%eax
801019e7:	8b 40 0c             	mov    0xc(%eax),%eax
801019ea:	83 e0 fe             	and    $0xfffffffe,%eax
801019ed:	89 c2                	mov    %eax,%edx
801019ef:	8b 45 08             	mov    0x8(%ebp),%eax
801019f2:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
801019f5:	8b 45 08             	mov    0x8(%ebp),%eax
801019f8:	89 04 24             	mov    %eax,(%esp)
801019fb:	e8 da 32 00 00       	call   80104cda <wakeup>
  release(&icache.lock);
80101a00:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a07:	e8 4f 36 00 00       	call   8010505b <release>
}
80101a0c:	c9                   	leave  
80101a0d:	c3                   	ret    

80101a0e <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101a0e:	55                   	push   %ebp
80101a0f:	89 e5                	mov    %esp,%ebp
80101a11:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a14:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a1b:	e8 d9 35 00 00       	call   80104ff9 <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a20:	8b 45 08             	mov    0x8(%ebp),%eax
80101a23:	8b 40 08             	mov    0x8(%eax),%eax
80101a26:	83 f8 01             	cmp    $0x1,%eax
80101a29:	0f 85 93 00 00 00    	jne    80101ac2 <iput+0xb4>
80101a2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101a32:	8b 40 0c             	mov    0xc(%eax),%eax
80101a35:	83 e0 02             	and    $0x2,%eax
80101a38:	85 c0                	test   %eax,%eax
80101a3a:	0f 84 82 00 00 00    	je     80101ac2 <iput+0xb4>
80101a40:	8b 45 08             	mov    0x8(%ebp),%eax
80101a43:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101a47:	66 85 c0             	test   %ax,%ax
80101a4a:	75 76                	jne    80101ac2 <iput+0xb4>
    // inode has no links and no other references: truncate and free.
    if(ip->flags & I_BUSY)
80101a4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a4f:	8b 40 0c             	mov    0xc(%eax),%eax
80101a52:	83 e0 01             	and    $0x1,%eax
80101a55:	85 c0                	test   %eax,%eax
80101a57:	74 0c                	je     80101a65 <iput+0x57>
      panic("iput busy");
80101a59:	c7 04 24 20 87 10 80 	movl   $0x80108720,(%esp)
80101a60:	e8 d5 ea ff ff       	call   8010053a <panic>
    ip->flags |= I_BUSY;
80101a65:	8b 45 08             	mov    0x8(%ebp),%eax
80101a68:	8b 40 0c             	mov    0xc(%eax),%eax
80101a6b:	83 c8 01             	or     $0x1,%eax
80101a6e:	89 c2                	mov    %eax,%edx
80101a70:	8b 45 08             	mov    0x8(%ebp),%eax
80101a73:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101a76:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101a7d:	e8 d9 35 00 00       	call   8010505b <release>
    itrunc(ip);
80101a82:	8b 45 08             	mov    0x8(%ebp),%eax
80101a85:	89 04 24             	mov    %eax,(%esp)
80101a88:	e8 7d 01 00 00       	call   80101c0a <itrunc>
    ip->type = 0;
80101a8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101a90:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101a96:	8b 45 08             	mov    0x8(%ebp),%eax
80101a99:	89 04 24             	mov    %eax,(%esp)
80101a9c:	e8 fe fb ff ff       	call   8010169f <iupdate>
    acquire(&icache.lock);
80101aa1:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101aa8:	e8 4c 35 00 00       	call   80104ff9 <acquire>
    ip->flags = 0;
80101aad:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101ab7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aba:	89 04 24             	mov    %eax,(%esp)
80101abd:	e8 18 32 00 00       	call   80104cda <wakeup>
  }
  ip->ref--;
80101ac2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac5:	8b 40 08             	mov    0x8(%eax),%eax
80101ac8:	8d 50 ff             	lea    -0x1(%eax),%edx
80101acb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ace:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ad1:	c7 04 24 40 12 11 80 	movl   $0x80111240,(%esp)
80101ad8:	e8 7e 35 00 00       	call   8010505b <release>
}
80101add:	c9                   	leave  
80101ade:	c3                   	ret    

80101adf <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101adf:	55                   	push   %ebp
80101ae0:	89 e5                	mov    %esp,%ebp
80101ae2:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101ae5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae8:	89 04 24             	mov    %eax,(%esp)
80101aeb:	e8 b9 fe ff ff       	call   801019a9 <iunlock>
  iput(ip);
80101af0:	8b 45 08             	mov    0x8(%ebp),%eax
80101af3:	89 04 24             	mov    %eax,(%esp)
80101af6:	e8 13 ff ff ff       	call   80101a0e <iput>
}
80101afb:	c9                   	leave  
80101afc:	c3                   	ret    

80101afd <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101afd:	55                   	push   %ebp
80101afe:	89 e5                	mov    %esp,%ebp
80101b00:	53                   	push   %ebx
80101b01:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b04:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b08:	77 3e                	ja     80101b48 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b0a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0d:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b10:	83 c2 04             	add    $0x4,%edx
80101b13:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b17:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b1a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b1e:	75 20                	jne    80101b40 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b20:	8b 45 08             	mov    0x8(%ebp),%eax
80101b23:	8b 00                	mov    (%eax),%eax
80101b25:	89 04 24             	mov    %eax,(%esp)
80101b28:	e8 5b f8 ff ff       	call   80101388 <balloc>
80101b2d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b30:	8b 45 08             	mov    0x8(%ebp),%eax
80101b33:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b36:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b39:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b3c:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101b40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101b43:	e9 bc 00 00 00       	jmp    80101c04 <bmap+0x107>
  }
  bn -= NDIRECT;
80101b48:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101b4c:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101b50:	0f 87 a2 00 00 00    	ja     80101bf8 <bmap+0xfb>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101b56:	8b 45 08             	mov    0x8(%ebp),%eax
80101b59:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b5f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b63:	75 19                	jne    80101b7e <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101b65:	8b 45 08             	mov    0x8(%ebp),%eax
80101b68:	8b 00                	mov    (%eax),%eax
80101b6a:	89 04 24             	mov    %eax,(%esp)
80101b6d:	e8 16 f8 ff ff       	call   80101388 <balloc>
80101b72:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b75:	8b 45 08             	mov    0x8(%ebp),%eax
80101b78:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b7b:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101b7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b81:	8b 00                	mov    (%eax),%eax
80101b83:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b86:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b8a:	89 04 24             	mov    %eax,(%esp)
80101b8d:	e8 14 e6 ff ff       	call   801001a6 <bread>
80101b92:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101b95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b98:	83 c0 18             	add    $0x18,%eax
80101b9b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101b9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ba1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ba8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bab:	01 d0                	add    %edx,%eax
80101bad:	8b 00                	mov    (%eax),%eax
80101baf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bb2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bb6:	75 30                	jne    80101be8 <bmap+0xeb>
      a[bn] = addr = balloc(ip->dev);
80101bb8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101bbb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101bc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101bc5:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101bc8:	8b 45 08             	mov    0x8(%ebp),%eax
80101bcb:	8b 00                	mov    (%eax),%eax
80101bcd:	89 04 24             	mov    %eax,(%esp)
80101bd0:	e8 b3 f7 ff ff       	call   80101388 <balloc>
80101bd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bdb:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101bdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101be0:	89 04 24             	mov    %eax,(%esp)
80101be3:	e8 6a 1a 00 00       	call   80103652 <log_write>
    }
    brelse(bp);
80101be8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101beb:	89 04 24             	mov    %eax,(%esp)
80101bee:	e8 24 e6 ff ff       	call   80100217 <brelse>
    return addr;
80101bf3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101bf6:	eb 0c                	jmp    80101c04 <bmap+0x107>
  }

  panic("bmap: out of range");
80101bf8:	c7 04 24 2a 87 10 80 	movl   $0x8010872a,(%esp)
80101bff:	e8 36 e9 ff ff       	call   8010053a <panic>
}
80101c04:	83 c4 24             	add    $0x24,%esp
80101c07:	5b                   	pop    %ebx
80101c08:	5d                   	pop    %ebp
80101c09:	c3                   	ret    

80101c0a <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c0a:	55                   	push   %ebp
80101c0b:	89 e5                	mov    %esp,%ebp
80101c0d:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c10:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c17:	eb 44                	jmp    80101c5d <itrunc+0x53>
    if(ip->addrs[i]){
80101c19:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c1f:	83 c2 04             	add    $0x4,%edx
80101c22:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c26:	85 c0                	test   %eax,%eax
80101c28:	74 2f                	je     80101c59 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c30:	83 c2 04             	add    $0x4,%edx
80101c33:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c37:	8b 45 08             	mov    0x8(%ebp),%eax
80101c3a:	8b 00                	mov    (%eax),%eax
80101c3c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c40:	89 04 24             	mov    %eax,(%esp)
80101c43:	e8 8e f8 ff ff       	call   801014d6 <bfree>
      ip->addrs[i] = 0;
80101c48:	8b 45 08             	mov    0x8(%ebp),%eax
80101c4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c4e:	83 c2 04             	add    $0x4,%edx
80101c51:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101c58:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101c5d:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101c61:	7e b6                	jle    80101c19 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101c63:	8b 45 08             	mov    0x8(%ebp),%eax
80101c66:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c69:	85 c0                	test   %eax,%eax
80101c6b:	0f 84 9b 00 00 00    	je     80101d0c <itrunc+0x102>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101c71:	8b 45 08             	mov    0x8(%ebp),%eax
80101c74:	8b 50 4c             	mov    0x4c(%eax),%edx
80101c77:	8b 45 08             	mov    0x8(%ebp),%eax
80101c7a:	8b 00                	mov    (%eax),%eax
80101c7c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c80:	89 04 24             	mov    %eax,(%esp)
80101c83:	e8 1e e5 ff ff       	call   801001a6 <bread>
80101c88:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101c8b:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101c8e:	83 c0 18             	add    $0x18,%eax
80101c91:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101c94:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101c9b:	eb 3b                	jmp    80101cd8 <itrunc+0xce>
      if(a[j])
80101c9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ca0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101ca7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101caa:	01 d0                	add    %edx,%eax
80101cac:	8b 00                	mov    (%eax),%eax
80101cae:	85 c0                	test   %eax,%eax
80101cb0:	74 22                	je     80101cd4 <itrunc+0xca>
        bfree(ip->dev, a[j]);
80101cb2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cb5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101cbc:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101cbf:	01 d0                	add    %edx,%eax
80101cc1:	8b 10                	mov    (%eax),%edx
80101cc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc6:	8b 00                	mov    (%eax),%eax
80101cc8:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ccc:	89 04 24             	mov    %eax,(%esp)
80101ccf:	e8 02 f8 ff ff       	call   801014d6 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101cd4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101cd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cdb:	83 f8 7f             	cmp    $0x7f,%eax
80101cde:	76 bd                	jbe    80101c9d <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101ce0:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ce3:	89 04 24             	mov    %eax,(%esp)
80101ce6:	e8 2c e5 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101ceb:	8b 45 08             	mov    0x8(%ebp),%eax
80101cee:	8b 50 4c             	mov    0x4c(%eax),%edx
80101cf1:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf4:	8b 00                	mov    (%eax),%eax
80101cf6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cfa:	89 04 24             	mov    %eax,(%esp)
80101cfd:	e8 d4 f7 ff ff       	call   801014d6 <bfree>
    ip->addrs[NDIRECT] = 0;
80101d02:	8b 45 08             	mov    0x8(%ebp),%eax
80101d05:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d0c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d0f:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d16:	8b 45 08             	mov    0x8(%ebp),%eax
80101d19:	89 04 24             	mov    %eax,(%esp)
80101d1c:	e8 7e f9 ff ff       	call   8010169f <iupdate>
}
80101d21:	c9                   	leave  
80101d22:	c3                   	ret    

80101d23 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d23:	55                   	push   %ebp
80101d24:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d26:	8b 45 08             	mov    0x8(%ebp),%eax
80101d29:	8b 00                	mov    (%eax),%eax
80101d2b:	89 c2                	mov    %eax,%edx
80101d2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d30:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d33:	8b 45 08             	mov    0x8(%ebp),%eax
80101d36:	8b 50 04             	mov    0x4(%eax),%edx
80101d39:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d3c:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d42:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d46:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d49:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4f:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d53:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d56:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101d5a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d5d:	8b 50 18             	mov    0x18(%eax),%edx
80101d60:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d63:	89 50 10             	mov    %edx,0x10(%eax)
}
80101d66:	5d                   	pop    %ebp
80101d67:	c3                   	ret    

80101d68 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101d68:	55                   	push   %ebp
80101d69:	89 e5                	mov    %esp,%ebp
80101d6b:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101d6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d71:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101d75:	66 83 f8 03          	cmp    $0x3,%ax
80101d79:	75 60                	jne    80101ddb <readi+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101d7b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d82:	66 85 c0             	test   %ax,%ax
80101d85:	78 20                	js     80101da7 <readi+0x3f>
80101d87:	8b 45 08             	mov    0x8(%ebp),%eax
80101d8a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d8e:	66 83 f8 09          	cmp    $0x9,%ax
80101d92:	7f 13                	jg     80101da7 <readi+0x3f>
80101d94:	8b 45 08             	mov    0x8(%ebp),%eax
80101d97:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101d9b:	98                   	cwtl   
80101d9c:	8b 04 c5 e0 11 11 80 	mov    -0x7feeee20(,%eax,8),%eax
80101da3:	85 c0                	test   %eax,%eax
80101da5:	75 0a                	jne    80101db1 <readi+0x49>
      return -1;
80101da7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101dac:	e9 19 01 00 00       	jmp    80101eca <readi+0x162>
    return devsw[ip->major].read(ip, dst, n);
80101db1:	8b 45 08             	mov    0x8(%ebp),%eax
80101db4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101db8:	98                   	cwtl   
80101db9:	8b 04 c5 e0 11 11 80 	mov    -0x7feeee20(,%eax,8),%eax
80101dc0:	8b 55 14             	mov    0x14(%ebp),%edx
80101dc3:	89 54 24 08          	mov    %edx,0x8(%esp)
80101dc7:	8b 55 0c             	mov    0xc(%ebp),%edx
80101dca:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dce:	8b 55 08             	mov    0x8(%ebp),%edx
80101dd1:	89 14 24             	mov    %edx,(%esp)
80101dd4:	ff d0                	call   *%eax
80101dd6:	e9 ef 00 00 00       	jmp    80101eca <readi+0x162>
  }

  if(off > ip->size || off + n < off)
80101ddb:	8b 45 08             	mov    0x8(%ebp),%eax
80101dde:	8b 40 18             	mov    0x18(%eax),%eax
80101de1:	3b 45 10             	cmp    0x10(%ebp),%eax
80101de4:	72 0d                	jb     80101df3 <readi+0x8b>
80101de6:	8b 45 14             	mov    0x14(%ebp),%eax
80101de9:	8b 55 10             	mov    0x10(%ebp),%edx
80101dec:	01 d0                	add    %edx,%eax
80101dee:	3b 45 10             	cmp    0x10(%ebp),%eax
80101df1:	73 0a                	jae    80101dfd <readi+0x95>
    return -1;
80101df3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101df8:	e9 cd 00 00 00       	jmp    80101eca <readi+0x162>
  if(off + n > ip->size)
80101dfd:	8b 45 14             	mov    0x14(%ebp),%eax
80101e00:	8b 55 10             	mov    0x10(%ebp),%edx
80101e03:	01 c2                	add    %eax,%edx
80101e05:	8b 45 08             	mov    0x8(%ebp),%eax
80101e08:	8b 40 18             	mov    0x18(%eax),%eax
80101e0b:	39 c2                	cmp    %eax,%edx
80101e0d:	76 0c                	jbe    80101e1b <readi+0xb3>
    n = ip->size - off;
80101e0f:	8b 45 08             	mov    0x8(%ebp),%eax
80101e12:	8b 40 18             	mov    0x18(%eax),%eax
80101e15:	2b 45 10             	sub    0x10(%ebp),%eax
80101e18:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e1b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e22:	e9 94 00 00 00       	jmp    80101ebb <readi+0x153>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e27:	8b 45 10             	mov    0x10(%ebp),%eax
80101e2a:	c1 e8 09             	shr    $0x9,%eax
80101e2d:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e31:	8b 45 08             	mov    0x8(%ebp),%eax
80101e34:	89 04 24             	mov    %eax,(%esp)
80101e37:	e8 c1 fc ff ff       	call   80101afd <bmap>
80101e3c:	8b 55 08             	mov    0x8(%ebp),%edx
80101e3f:	8b 12                	mov    (%edx),%edx
80101e41:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e45:	89 14 24             	mov    %edx,(%esp)
80101e48:	e8 59 e3 ff ff       	call   801001a6 <bread>
80101e4d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e50:	8b 45 10             	mov    0x10(%ebp),%eax
80101e53:	25 ff 01 00 00       	and    $0x1ff,%eax
80101e58:	89 c2                	mov    %eax,%edx
80101e5a:	b8 00 02 00 00       	mov    $0x200,%eax
80101e5f:	29 d0                	sub    %edx,%eax
80101e61:	89 c2                	mov    %eax,%edx
80101e63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e66:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101e69:	29 c1                	sub    %eax,%ecx
80101e6b:	89 c8                	mov    %ecx,%eax
80101e6d:	39 c2                	cmp    %eax,%edx
80101e6f:	0f 46 c2             	cmovbe %edx,%eax
80101e72:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101e75:	8b 45 10             	mov    0x10(%ebp),%eax
80101e78:	25 ff 01 00 00       	and    $0x1ff,%eax
80101e7d:	8d 50 10             	lea    0x10(%eax),%edx
80101e80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e83:	01 d0                	add    %edx,%eax
80101e85:	8d 50 08             	lea    0x8(%eax),%edx
80101e88:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e8b:	89 44 24 08          	mov    %eax,0x8(%esp)
80101e8f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101e93:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e96:	89 04 24             	mov    %eax,(%esp)
80101e99:	e8 7e 34 00 00       	call   8010531c <memmove>
    brelse(bp);
80101e9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ea1:	89 04 24             	mov    %eax,(%esp)
80101ea4:	e8 6e e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ea9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eac:	01 45 f4             	add    %eax,-0xc(%ebp)
80101eaf:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eb2:	01 45 10             	add    %eax,0x10(%ebp)
80101eb5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eb8:	01 45 0c             	add    %eax,0xc(%ebp)
80101ebb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ebe:	3b 45 14             	cmp    0x14(%ebp),%eax
80101ec1:	0f 82 60 ff ff ff    	jb     80101e27 <readi+0xbf>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101ec7:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101eca:	c9                   	leave  
80101ecb:	c3                   	ret    

80101ecc <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101ecc:	55                   	push   %ebp
80101ecd:	89 e5                	mov    %esp,%ebp
80101ecf:	83 ec 28             	sub    $0x28,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101ed2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ed5:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101ed9:	66 83 f8 03          	cmp    $0x3,%ax
80101edd:	75 60                	jne    80101f3f <writei+0x73>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101edf:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ee6:	66 85 c0             	test   %ax,%ax
80101ee9:	78 20                	js     80101f0b <writei+0x3f>
80101eeb:	8b 45 08             	mov    0x8(%ebp),%eax
80101eee:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101ef2:	66 83 f8 09          	cmp    $0x9,%ax
80101ef6:	7f 13                	jg     80101f0b <writei+0x3f>
80101ef8:	8b 45 08             	mov    0x8(%ebp),%eax
80101efb:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101eff:	98                   	cwtl   
80101f00:	8b 04 c5 e4 11 11 80 	mov    -0x7feeee1c(,%eax,8),%eax
80101f07:	85 c0                	test   %eax,%eax
80101f09:	75 0a                	jne    80101f15 <writei+0x49>
      return -1;
80101f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f10:	e9 44 01 00 00       	jmp    80102059 <writei+0x18d>
    return devsw[ip->major].write(ip, src, n);
80101f15:	8b 45 08             	mov    0x8(%ebp),%eax
80101f18:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f1c:	98                   	cwtl   
80101f1d:	8b 04 c5 e4 11 11 80 	mov    -0x7feeee1c(,%eax,8),%eax
80101f24:	8b 55 14             	mov    0x14(%ebp),%edx
80101f27:	89 54 24 08          	mov    %edx,0x8(%esp)
80101f2b:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f2e:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f32:	8b 55 08             	mov    0x8(%ebp),%edx
80101f35:	89 14 24             	mov    %edx,(%esp)
80101f38:	ff d0                	call   *%eax
80101f3a:	e9 1a 01 00 00       	jmp    80102059 <writei+0x18d>
  }

  if(off > ip->size || off + n < off)
80101f3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101f42:	8b 40 18             	mov    0x18(%eax),%eax
80101f45:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f48:	72 0d                	jb     80101f57 <writei+0x8b>
80101f4a:	8b 45 14             	mov    0x14(%ebp),%eax
80101f4d:	8b 55 10             	mov    0x10(%ebp),%edx
80101f50:	01 d0                	add    %edx,%eax
80101f52:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f55:	73 0a                	jae    80101f61 <writei+0x95>
    return -1;
80101f57:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f5c:	e9 f8 00 00 00       	jmp    80102059 <writei+0x18d>
  if(off + n > MAXFILE*BSIZE)
80101f61:	8b 45 14             	mov    0x14(%ebp),%eax
80101f64:	8b 55 10             	mov    0x10(%ebp),%edx
80101f67:	01 d0                	add    %edx,%eax
80101f69:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101f6e:	76 0a                	jbe    80101f7a <writei+0xae>
    return -1;
80101f70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f75:	e9 df 00 00 00       	jmp    80102059 <writei+0x18d>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101f7a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101f81:	e9 9f 00 00 00       	jmp    80102025 <writei+0x159>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101f86:	8b 45 10             	mov    0x10(%ebp),%eax
80101f89:	c1 e8 09             	shr    $0x9,%eax
80101f8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f90:	8b 45 08             	mov    0x8(%ebp),%eax
80101f93:	89 04 24             	mov    %eax,(%esp)
80101f96:	e8 62 fb ff ff       	call   80101afd <bmap>
80101f9b:	8b 55 08             	mov    0x8(%ebp),%edx
80101f9e:	8b 12                	mov    (%edx),%edx
80101fa0:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fa4:	89 14 24             	mov    %edx,(%esp)
80101fa7:	e8 fa e1 ff ff       	call   801001a6 <bread>
80101fac:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101faf:	8b 45 10             	mov    0x10(%ebp),%eax
80101fb2:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fb7:	89 c2                	mov    %eax,%edx
80101fb9:	b8 00 02 00 00       	mov    $0x200,%eax
80101fbe:	29 d0                	sub    %edx,%eax
80101fc0:	89 c2                	mov    %eax,%edx
80101fc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101fc5:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101fc8:	29 c1                	sub    %eax,%ecx
80101fca:	89 c8                	mov    %ecx,%eax
80101fcc:	39 c2                	cmp    %eax,%edx
80101fce:	0f 46 c2             	cmovbe %edx,%eax
80101fd1:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80101fd4:	8b 45 10             	mov    0x10(%ebp),%eax
80101fd7:	25 ff 01 00 00       	and    $0x1ff,%eax
80101fdc:	8d 50 10             	lea    0x10(%eax),%edx
80101fdf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fe2:	01 d0                	add    %edx,%eax
80101fe4:	8d 50 08             	lea    0x8(%eax),%edx
80101fe7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101fea:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fee:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ff1:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ff5:	89 14 24             	mov    %edx,(%esp)
80101ff8:	e8 1f 33 00 00       	call   8010531c <memmove>
    log_write(bp);
80101ffd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102000:	89 04 24             	mov    %eax,(%esp)
80102003:	e8 4a 16 00 00       	call   80103652 <log_write>
    brelse(bp);
80102008:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010200b:	89 04 24             	mov    %eax,(%esp)
8010200e:	e8 04 e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102013:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102016:	01 45 f4             	add    %eax,-0xc(%ebp)
80102019:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010201c:	01 45 10             	add    %eax,0x10(%ebp)
8010201f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102022:	01 45 0c             	add    %eax,0xc(%ebp)
80102025:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102028:	3b 45 14             	cmp    0x14(%ebp),%eax
8010202b:	0f 82 55 ff ff ff    	jb     80101f86 <writei+0xba>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102031:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102035:	74 1f                	je     80102056 <writei+0x18a>
80102037:	8b 45 08             	mov    0x8(%ebp),%eax
8010203a:	8b 40 18             	mov    0x18(%eax),%eax
8010203d:	3b 45 10             	cmp    0x10(%ebp),%eax
80102040:	73 14                	jae    80102056 <writei+0x18a>
    ip->size = off;
80102042:	8b 45 08             	mov    0x8(%ebp),%eax
80102045:	8b 55 10             	mov    0x10(%ebp),%edx
80102048:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
8010204b:	8b 45 08             	mov    0x8(%ebp),%eax
8010204e:	89 04 24             	mov    %eax,(%esp)
80102051:	e8 49 f6 ff ff       	call   8010169f <iupdate>
  }
  return n;
80102056:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102059:	c9                   	leave  
8010205a:	c3                   	ret    

8010205b <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
8010205b:	55                   	push   %ebp
8010205c:	89 e5                	mov    %esp,%ebp
8010205e:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
80102061:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102068:	00 
80102069:	8b 45 0c             	mov    0xc(%ebp),%eax
8010206c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102070:	8b 45 08             	mov    0x8(%ebp),%eax
80102073:	89 04 24             	mov    %eax,(%esp)
80102076:	e8 44 33 00 00       	call   801053bf <strncmp>
}
8010207b:	c9                   	leave  
8010207c:	c3                   	ret    

8010207d <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
8010207d:	55                   	push   %ebp
8010207e:	89 e5                	mov    %esp,%ebp
80102080:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102083:	8b 45 08             	mov    0x8(%ebp),%eax
80102086:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010208a:	66 83 f8 01          	cmp    $0x1,%ax
8010208e:	74 0c                	je     8010209c <dirlookup+0x1f>
    panic("dirlookup not DIR");
80102090:	c7 04 24 3d 87 10 80 	movl   $0x8010873d,(%esp)
80102097:	e8 9e e4 ff ff       	call   8010053a <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
8010209c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020a3:	e9 88 00 00 00       	jmp    80102130 <dirlookup+0xb3>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801020a8:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801020af:	00 
801020b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020b3:	89 44 24 08          	mov    %eax,0x8(%esp)
801020b7:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801020be:	8b 45 08             	mov    0x8(%ebp),%eax
801020c1:	89 04 24             	mov    %eax,(%esp)
801020c4:	e8 9f fc ff ff       	call   80101d68 <readi>
801020c9:	83 f8 10             	cmp    $0x10,%eax
801020cc:	74 0c                	je     801020da <dirlookup+0x5d>
      panic("dirlink read");
801020ce:	c7 04 24 4f 87 10 80 	movl   $0x8010874f,(%esp)
801020d5:	e8 60 e4 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
801020da:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801020de:	66 85 c0             	test   %ax,%ax
801020e1:	75 02                	jne    801020e5 <dirlookup+0x68>
      continue;
801020e3:	eb 47                	jmp    8010212c <dirlookup+0xaf>
    if(namecmp(name, de.name) == 0){
801020e5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801020e8:	83 c0 02             	add    $0x2,%eax
801020eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801020ef:	8b 45 0c             	mov    0xc(%ebp),%eax
801020f2:	89 04 24             	mov    %eax,(%esp)
801020f5:	e8 61 ff ff ff       	call   8010205b <namecmp>
801020fa:	85 c0                	test   %eax,%eax
801020fc:	75 2e                	jne    8010212c <dirlookup+0xaf>
      // entry matches path element
      if(poff)
801020fe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102102:	74 08                	je     8010210c <dirlookup+0x8f>
        *poff = off;
80102104:	8b 45 10             	mov    0x10(%ebp),%eax
80102107:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010210a:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010210c:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102110:	0f b7 c0             	movzwl %ax,%eax
80102113:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102116:	8b 45 08             	mov    0x8(%ebp),%eax
80102119:	8b 00                	mov    (%eax),%eax
8010211b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010211e:	89 54 24 04          	mov    %edx,0x4(%esp)
80102122:	89 04 24             	mov    %eax,(%esp)
80102125:	e8 2d f6 ff ff       	call   80101757 <iget>
8010212a:	eb 18                	jmp    80102144 <dirlookup+0xc7>
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
8010212c:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102130:	8b 45 08             	mov    0x8(%ebp),%eax
80102133:	8b 40 18             	mov    0x18(%eax),%eax
80102136:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102139:	0f 87 69 ff ff ff    	ja     801020a8 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
8010213f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102144:	c9                   	leave  
80102145:	c3                   	ret    

80102146 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102146:	55                   	push   %ebp
80102147:	89 e5                	mov    %esp,%ebp
80102149:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
8010214c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102153:	00 
80102154:	8b 45 0c             	mov    0xc(%ebp),%eax
80102157:	89 44 24 04          	mov    %eax,0x4(%esp)
8010215b:	8b 45 08             	mov    0x8(%ebp),%eax
8010215e:	89 04 24             	mov    %eax,(%esp)
80102161:	e8 17 ff ff ff       	call   8010207d <dirlookup>
80102166:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102169:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010216d:	74 15                	je     80102184 <dirlink+0x3e>
    iput(ip);
8010216f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102172:	89 04 24             	mov    %eax,(%esp)
80102175:	e8 94 f8 ff ff       	call   80101a0e <iput>
    return -1;
8010217a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010217f:	e9 b7 00 00 00       	jmp    8010223b <dirlink+0xf5>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102184:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010218b:	eb 46                	jmp    801021d3 <dirlink+0x8d>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010218d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102190:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102197:	00 
80102198:	89 44 24 08          	mov    %eax,0x8(%esp)
8010219c:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010219f:	89 44 24 04          	mov    %eax,0x4(%esp)
801021a3:	8b 45 08             	mov    0x8(%ebp),%eax
801021a6:	89 04 24             	mov    %eax,(%esp)
801021a9:	e8 ba fb ff ff       	call   80101d68 <readi>
801021ae:	83 f8 10             	cmp    $0x10,%eax
801021b1:	74 0c                	je     801021bf <dirlink+0x79>
      panic("dirlink read");
801021b3:	c7 04 24 4f 87 10 80 	movl   $0x8010874f,(%esp)
801021ba:	e8 7b e3 ff ff       	call   8010053a <panic>
    if(de.inum == 0)
801021bf:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801021c3:	66 85 c0             	test   %ax,%ax
801021c6:	75 02                	jne    801021ca <dirlink+0x84>
      break;
801021c8:	eb 16                	jmp    801021e0 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801021ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021cd:	83 c0 10             	add    $0x10,%eax
801021d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021d6:	8b 45 08             	mov    0x8(%ebp),%eax
801021d9:	8b 40 18             	mov    0x18(%eax),%eax
801021dc:	39 c2                	cmp    %eax,%edx
801021de:	72 ad                	jb     8010218d <dirlink+0x47>
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
801021e0:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801021e7:	00 
801021e8:	8b 45 0c             	mov    0xc(%ebp),%eax
801021eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801021ef:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021f2:	83 c0 02             	add    $0x2,%eax
801021f5:	89 04 24             	mov    %eax,(%esp)
801021f8:	e8 18 32 00 00       	call   80105415 <strncpy>
  de.inum = inum;
801021fd:	8b 45 10             	mov    0x10(%ebp),%eax
80102200:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102204:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102207:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010220e:	00 
8010220f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102213:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102216:	89 44 24 04          	mov    %eax,0x4(%esp)
8010221a:	8b 45 08             	mov    0x8(%ebp),%eax
8010221d:	89 04 24             	mov    %eax,(%esp)
80102220:	e8 a7 fc ff ff       	call   80101ecc <writei>
80102225:	83 f8 10             	cmp    $0x10,%eax
80102228:	74 0c                	je     80102236 <dirlink+0xf0>
    panic("dirlink");
8010222a:	c7 04 24 5c 87 10 80 	movl   $0x8010875c,(%esp)
80102231:	e8 04 e3 ff ff       	call   8010053a <panic>
  
  return 0;
80102236:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010223b:	c9                   	leave  
8010223c:	c3                   	ret    

8010223d <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
8010223d:	55                   	push   %ebp
8010223e:	89 e5                	mov    %esp,%ebp
80102240:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
80102243:	eb 04                	jmp    80102249 <skipelem+0xc>
    path++;
80102245:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102249:	8b 45 08             	mov    0x8(%ebp),%eax
8010224c:	0f b6 00             	movzbl (%eax),%eax
8010224f:	3c 2f                	cmp    $0x2f,%al
80102251:	74 f2                	je     80102245 <skipelem+0x8>
    path++;
  if(*path == 0)
80102253:	8b 45 08             	mov    0x8(%ebp),%eax
80102256:	0f b6 00             	movzbl (%eax),%eax
80102259:	84 c0                	test   %al,%al
8010225b:	75 0a                	jne    80102267 <skipelem+0x2a>
    return 0;
8010225d:	b8 00 00 00 00       	mov    $0x0,%eax
80102262:	e9 86 00 00 00       	jmp    801022ed <skipelem+0xb0>
  s = path;
80102267:	8b 45 08             	mov    0x8(%ebp),%eax
8010226a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
8010226d:	eb 04                	jmp    80102273 <skipelem+0x36>
    path++;
8010226f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
80102273:	8b 45 08             	mov    0x8(%ebp),%eax
80102276:	0f b6 00             	movzbl (%eax),%eax
80102279:	3c 2f                	cmp    $0x2f,%al
8010227b:	74 0a                	je     80102287 <skipelem+0x4a>
8010227d:	8b 45 08             	mov    0x8(%ebp),%eax
80102280:	0f b6 00             	movzbl (%eax),%eax
80102283:	84 c0                	test   %al,%al
80102285:	75 e8                	jne    8010226f <skipelem+0x32>
    path++;
  len = path - s;
80102287:	8b 55 08             	mov    0x8(%ebp),%edx
8010228a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010228d:	29 c2                	sub    %eax,%edx
8010228f:	89 d0                	mov    %edx,%eax
80102291:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102294:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102298:	7e 1c                	jle    801022b6 <skipelem+0x79>
    memmove(name, s, DIRSIZ);
8010229a:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022a1:	00 
801022a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801022a9:	8b 45 0c             	mov    0xc(%ebp),%eax
801022ac:	89 04 24             	mov    %eax,(%esp)
801022af:	e8 68 30 00 00       	call   8010531c <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022b4:	eb 2a                	jmp    801022e0 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
801022b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801022b9:	89 44 24 08          	mov    %eax,0x8(%esp)
801022bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022c0:	89 44 24 04          	mov    %eax,0x4(%esp)
801022c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801022c7:	89 04 24             	mov    %eax,(%esp)
801022ca:	e8 4d 30 00 00       	call   8010531c <memmove>
    name[len] = 0;
801022cf:	8b 55 f0             	mov    -0x10(%ebp),%edx
801022d2:	8b 45 0c             	mov    0xc(%ebp),%eax
801022d5:	01 d0                	add    %edx,%eax
801022d7:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
801022da:	eb 04                	jmp    801022e0 <skipelem+0xa3>
    path++;
801022dc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
801022e0:	8b 45 08             	mov    0x8(%ebp),%eax
801022e3:	0f b6 00             	movzbl (%eax),%eax
801022e6:	3c 2f                	cmp    $0x2f,%al
801022e8:	74 f2                	je     801022dc <skipelem+0x9f>
    path++;
  return path;
801022ea:	8b 45 08             	mov    0x8(%ebp),%eax
}
801022ed:	c9                   	leave  
801022ee:	c3                   	ret    

801022ef <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801022ef:	55                   	push   %ebp
801022f0:	89 e5                	mov    %esp,%ebp
801022f2:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801022f5:	8b 45 08             	mov    0x8(%ebp),%eax
801022f8:	0f b6 00             	movzbl (%eax),%eax
801022fb:	3c 2f                	cmp    $0x2f,%al
801022fd:	75 1c                	jne    8010231b <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801022ff:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102306:	00 
80102307:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010230e:	e8 44 f4 ff ff       	call   80101757 <iget>
80102313:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102316:	e9 af 00 00 00       	jmp    801023ca <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
8010231b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102321:	8b 40 68             	mov    0x68(%eax),%eax
80102324:	89 04 24             	mov    %eax,(%esp)
80102327:	e8 fd f4 ff ff       	call   80101829 <idup>
8010232c:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010232f:	e9 96 00 00 00       	jmp    801023ca <namex+0xdb>
    ilock(ip);
80102334:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102337:	89 04 24             	mov    %eax,(%esp)
8010233a:	e8 1c f5 ff ff       	call   8010185b <ilock>
    if(ip->type != T_DIR){
8010233f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102342:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102346:	66 83 f8 01          	cmp    $0x1,%ax
8010234a:	74 15                	je     80102361 <namex+0x72>
      iunlockput(ip);
8010234c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010234f:	89 04 24             	mov    %eax,(%esp)
80102352:	e8 88 f7 ff ff       	call   80101adf <iunlockput>
      return 0;
80102357:	b8 00 00 00 00       	mov    $0x0,%eax
8010235c:	e9 a3 00 00 00       	jmp    80102404 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
80102361:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102365:	74 1d                	je     80102384 <namex+0x95>
80102367:	8b 45 08             	mov    0x8(%ebp),%eax
8010236a:	0f b6 00             	movzbl (%eax),%eax
8010236d:	84 c0                	test   %al,%al
8010236f:	75 13                	jne    80102384 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
80102371:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102374:	89 04 24             	mov    %eax,(%esp)
80102377:	e8 2d f6 ff ff       	call   801019a9 <iunlock>
      return ip;
8010237c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010237f:	e9 80 00 00 00       	jmp    80102404 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102384:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010238b:	00 
8010238c:	8b 45 10             	mov    0x10(%ebp),%eax
8010238f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102393:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102396:	89 04 24             	mov    %eax,(%esp)
80102399:	e8 df fc ff ff       	call   8010207d <dirlookup>
8010239e:	89 45 f0             	mov    %eax,-0x10(%ebp)
801023a1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801023a5:	75 12                	jne    801023b9 <namex+0xca>
      iunlockput(ip);
801023a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023aa:	89 04 24             	mov    %eax,(%esp)
801023ad:	e8 2d f7 ff ff       	call   80101adf <iunlockput>
      return 0;
801023b2:	b8 00 00 00 00       	mov    $0x0,%eax
801023b7:	eb 4b                	jmp    80102404 <namex+0x115>
    }
    iunlockput(ip);
801023b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023bc:	89 04 24             	mov    %eax,(%esp)
801023bf:	e8 1b f7 ff ff       	call   80101adf <iunlockput>
    ip = next;
801023c4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801023ca:	8b 45 10             	mov    0x10(%ebp),%eax
801023cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801023d1:	8b 45 08             	mov    0x8(%ebp),%eax
801023d4:	89 04 24             	mov    %eax,(%esp)
801023d7:	e8 61 fe ff ff       	call   8010223d <skipelem>
801023dc:	89 45 08             	mov    %eax,0x8(%ebp)
801023df:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801023e3:	0f 85 4b ff ff ff    	jne    80102334 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801023e9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023ed:	74 12                	je     80102401 <namex+0x112>
    iput(ip);
801023ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023f2:	89 04 24             	mov    %eax,(%esp)
801023f5:	e8 14 f6 ff ff       	call   80101a0e <iput>
    return 0;
801023fa:	b8 00 00 00 00       	mov    $0x0,%eax
801023ff:	eb 03                	jmp    80102404 <namex+0x115>
  }
  return ip;
80102401:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102404:	c9                   	leave  
80102405:	c3                   	ret    

80102406 <namei>:

struct inode*
namei(char *path)
{
80102406:	55                   	push   %ebp
80102407:	89 e5                	mov    %esp,%ebp
80102409:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
8010240c:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010240f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102413:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010241a:	00 
8010241b:	8b 45 08             	mov    0x8(%ebp),%eax
8010241e:	89 04 24             	mov    %eax,(%esp)
80102421:	e8 c9 fe ff ff       	call   801022ef <namex>
}
80102426:	c9                   	leave  
80102427:	c3                   	ret    

80102428 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102428:	55                   	push   %ebp
80102429:	89 e5                	mov    %esp,%ebp
8010242b:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
8010242e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102431:	89 44 24 08          	mov    %eax,0x8(%esp)
80102435:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010243c:	00 
8010243d:	8b 45 08             	mov    0x8(%ebp),%eax
80102440:	89 04 24             	mov    %eax,(%esp)
80102443:	e8 a7 fe ff ff       	call   801022ef <namex>
}
80102448:	c9                   	leave  
80102449:	c3                   	ret    

8010244a <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010244a:	55                   	push   %ebp
8010244b:	89 e5                	mov    %esp,%ebp
8010244d:	83 ec 14             	sub    $0x14,%esp
80102450:	8b 45 08             	mov    0x8(%ebp),%eax
80102453:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102457:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010245b:	89 c2                	mov    %eax,%edx
8010245d:	ec                   	in     (%dx),%al
8010245e:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102461:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102465:	c9                   	leave  
80102466:	c3                   	ret    

80102467 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102467:	55                   	push   %ebp
80102468:	89 e5                	mov    %esp,%ebp
8010246a:	57                   	push   %edi
8010246b:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
8010246c:	8b 55 08             	mov    0x8(%ebp),%edx
8010246f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102472:	8b 45 10             	mov    0x10(%ebp),%eax
80102475:	89 cb                	mov    %ecx,%ebx
80102477:	89 df                	mov    %ebx,%edi
80102479:	89 c1                	mov    %eax,%ecx
8010247b:	fc                   	cld    
8010247c:	f3 6d                	rep insl (%dx),%es:(%edi)
8010247e:	89 c8                	mov    %ecx,%eax
80102480:	89 fb                	mov    %edi,%ebx
80102482:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102485:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102488:	5b                   	pop    %ebx
80102489:	5f                   	pop    %edi
8010248a:	5d                   	pop    %ebp
8010248b:	c3                   	ret    

8010248c <outb>:

static inline void
outb(ushort port, uchar data)
{
8010248c:	55                   	push   %ebp
8010248d:	89 e5                	mov    %esp,%ebp
8010248f:	83 ec 08             	sub    $0x8,%esp
80102492:	8b 55 08             	mov    0x8(%ebp),%edx
80102495:	8b 45 0c             	mov    0xc(%ebp),%eax
80102498:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010249c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010249f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801024a3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801024a7:	ee                   	out    %al,(%dx)
}
801024a8:	c9                   	leave  
801024a9:	c3                   	ret    

801024aa <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801024aa:	55                   	push   %ebp
801024ab:	89 e5                	mov    %esp,%ebp
801024ad:	56                   	push   %esi
801024ae:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801024af:	8b 55 08             	mov    0x8(%ebp),%edx
801024b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801024b5:	8b 45 10             	mov    0x10(%ebp),%eax
801024b8:	89 cb                	mov    %ecx,%ebx
801024ba:	89 de                	mov    %ebx,%esi
801024bc:	89 c1                	mov    %eax,%ecx
801024be:	fc                   	cld    
801024bf:	f3 6f                	rep outsl %ds:(%esi),(%dx)
801024c1:	89 c8                	mov    %ecx,%eax
801024c3:	89 f3                	mov    %esi,%ebx
801024c5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801024c8:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
801024cb:	5b                   	pop    %ebx
801024cc:	5e                   	pop    %esi
801024cd:	5d                   	pop    %ebp
801024ce:	c3                   	ret    

801024cf <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
801024cf:	55                   	push   %ebp
801024d0:	89 e5                	mov    %esp,%ebp
801024d2:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801024d5:	90                   	nop
801024d6:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801024dd:	e8 68 ff ff ff       	call   8010244a <inb>
801024e2:	0f b6 c0             	movzbl %al,%eax
801024e5:	89 45 fc             	mov    %eax,-0x4(%ebp)
801024e8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801024eb:	25 c0 00 00 00       	and    $0xc0,%eax
801024f0:	83 f8 40             	cmp    $0x40,%eax
801024f3:	75 e1                	jne    801024d6 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801024f5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801024f9:	74 11                	je     8010250c <idewait+0x3d>
801024fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801024fe:	83 e0 21             	and    $0x21,%eax
80102501:	85 c0                	test   %eax,%eax
80102503:	74 07                	je     8010250c <idewait+0x3d>
    return -1;
80102505:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010250a:	eb 05                	jmp    80102511 <idewait+0x42>
  return 0;
8010250c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102511:	c9                   	leave  
80102512:	c3                   	ret    

80102513 <ideinit>:

void
ideinit(void)
{
80102513:	55                   	push   %ebp
80102514:	89 e5                	mov    %esp,%ebp
80102516:	83 ec 28             	sub    $0x28,%esp
  int i;
  
  initlock(&idelock, "ide");
80102519:	c7 44 24 04 64 87 10 	movl   $0x80108764,0x4(%esp)
80102520:	80 
80102521:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102528:	e8 ab 2a 00 00       	call   80104fd8 <initlock>
  picenable(IRQ_IDE);
8010252d:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102534:	e8 b2 18 00 00       	call   80103deb <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102539:	a1 40 29 11 80       	mov    0x80112940,%eax
8010253e:	83 e8 01             	sub    $0x1,%eax
80102541:	89 44 24 04          	mov    %eax,0x4(%esp)
80102545:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010254c:	e8 43 04 00 00       	call   80102994 <ioapicenable>
  idewait(0);
80102551:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102558:	e8 72 ff ff ff       	call   801024cf <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
8010255d:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102564:	00 
80102565:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010256c:	e8 1b ff ff ff       	call   8010248c <outb>
  for(i=0; i<1000; i++){
80102571:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102578:	eb 20                	jmp    8010259a <ideinit+0x87>
    if(inb(0x1f7) != 0){
8010257a:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102581:	e8 c4 fe ff ff       	call   8010244a <inb>
80102586:	84 c0                	test   %al,%al
80102588:	74 0c                	je     80102596 <ideinit+0x83>
      havedisk1 = 1;
8010258a:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
80102591:	00 00 00 
      break;
80102594:	eb 0d                	jmp    801025a3 <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102596:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010259a:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801025a1:	7e d7                	jle    8010257a <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801025a3:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
801025aa:	00 
801025ab:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025b2:	e8 d5 fe ff ff       	call   8010248c <outb>
}
801025b7:	c9                   	leave  
801025b8:	c3                   	ret    

801025b9 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801025b9:	55                   	push   %ebp
801025ba:	89 e5                	mov    %esp,%ebp
801025bc:	83 ec 28             	sub    $0x28,%esp
  if(b == 0)
801025bf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025c3:	75 0c                	jne    801025d1 <idestart+0x18>
    panic("idestart");
801025c5:	c7 04 24 68 87 10 80 	movl   $0x80108768,(%esp)
801025cc:	e8 69 df ff ff       	call   8010053a <panic>
  if(b->blockno >= FSSIZE)
801025d1:	8b 45 08             	mov    0x8(%ebp),%eax
801025d4:	8b 40 08             	mov    0x8(%eax),%eax
801025d7:	3d e7 03 00 00       	cmp    $0x3e7,%eax
801025dc:	76 0c                	jbe    801025ea <idestart+0x31>
    panic("incorrect blockno");
801025de:	c7 04 24 71 87 10 80 	movl   $0x80108771,(%esp)
801025e5:	e8 50 df ff ff       	call   8010053a <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
801025ea:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
801025f1:	8b 45 08             	mov    0x8(%ebp),%eax
801025f4:	8b 50 08             	mov    0x8(%eax),%edx
801025f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801025fa:	0f af c2             	imul   %edx,%eax
801025fd:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102600:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
80102604:	7e 0c                	jle    80102612 <idestart+0x59>
80102606:	c7 04 24 68 87 10 80 	movl   $0x80108768,(%esp)
8010260d:	e8 28 df ff ff       	call   8010053a <panic>
  
  idewait(0);
80102612:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102619:	e8 b1 fe ff ff       	call   801024cf <idewait>
  outb(0x3f6, 0);  // generate interrupt
8010261e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102625:	00 
80102626:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
8010262d:	e8 5a fe ff ff       	call   8010248c <outb>
  outb(0x1f2, sector_per_block);  // number of sectors
80102632:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102635:	0f b6 c0             	movzbl %al,%eax
80102638:	89 44 24 04          	mov    %eax,0x4(%esp)
8010263c:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102643:	e8 44 fe ff ff       	call   8010248c <outb>
  outb(0x1f3, sector & 0xff);
80102648:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010264b:	0f b6 c0             	movzbl %al,%eax
8010264e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102652:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102659:	e8 2e fe ff ff       	call   8010248c <outb>
  outb(0x1f4, (sector >> 8) & 0xff);
8010265e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102661:	c1 f8 08             	sar    $0x8,%eax
80102664:	0f b6 c0             	movzbl %al,%eax
80102667:	89 44 24 04          	mov    %eax,0x4(%esp)
8010266b:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102672:	e8 15 fe ff ff       	call   8010248c <outb>
  outb(0x1f5, (sector >> 16) & 0xff);
80102677:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010267a:	c1 f8 10             	sar    $0x10,%eax
8010267d:	0f b6 c0             	movzbl %al,%eax
80102680:	89 44 24 04          	mov    %eax,0x4(%esp)
80102684:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010268b:	e8 fc fd ff ff       	call   8010248c <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80102690:	8b 45 08             	mov    0x8(%ebp),%eax
80102693:	8b 40 04             	mov    0x4(%eax),%eax
80102696:	83 e0 01             	and    $0x1,%eax
80102699:	c1 e0 04             	shl    $0x4,%eax
8010269c:	89 c2                	mov    %eax,%edx
8010269e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801026a1:	c1 f8 18             	sar    $0x18,%eax
801026a4:	83 e0 0f             	and    $0xf,%eax
801026a7:	09 d0                	or     %edx,%eax
801026a9:	83 c8 e0             	or     $0xffffffe0,%eax
801026ac:	0f b6 c0             	movzbl %al,%eax
801026af:	89 44 24 04          	mov    %eax,0x4(%esp)
801026b3:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026ba:	e8 cd fd ff ff       	call   8010248c <outb>
  if(b->flags & B_DIRTY){
801026bf:	8b 45 08             	mov    0x8(%ebp),%eax
801026c2:	8b 00                	mov    (%eax),%eax
801026c4:	83 e0 04             	and    $0x4,%eax
801026c7:	85 c0                	test   %eax,%eax
801026c9:	74 34                	je     801026ff <idestart+0x146>
    outb(0x1f7, IDE_CMD_WRITE);
801026cb:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
801026d2:	00 
801026d3:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801026da:	e8 ad fd ff ff       	call   8010248c <outb>
    outsl(0x1f0, b->data, BSIZE/4);
801026df:	8b 45 08             	mov    0x8(%ebp),%eax
801026e2:	83 c0 18             	add    $0x18,%eax
801026e5:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801026ec:	00 
801026ed:	89 44 24 04          	mov    %eax,0x4(%esp)
801026f1:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801026f8:	e8 ad fd ff ff       	call   801024aa <outsl>
801026fd:	eb 14                	jmp    80102713 <idestart+0x15a>
  } else {
    outb(0x1f7, IDE_CMD_READ);
801026ff:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102706:	00 
80102707:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010270e:	e8 79 fd ff ff       	call   8010248c <outb>
  }
}
80102713:	c9                   	leave  
80102714:	c3                   	ret    

80102715 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102715:	55                   	push   %ebp
80102716:	89 e5                	mov    %esp,%ebp
80102718:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010271b:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102722:	e8 d2 28 00 00       	call   80104ff9 <acquire>
  if((b = idequeue) == 0){
80102727:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010272c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010272f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102733:	75 11                	jne    80102746 <ideintr+0x31>
    release(&idelock);
80102735:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010273c:	e8 1a 29 00 00       	call   8010505b <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102741:	e9 90 00 00 00       	jmp    801027d6 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102746:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102749:	8b 40 14             	mov    0x14(%eax),%eax
8010274c:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102751:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102754:	8b 00                	mov    (%eax),%eax
80102756:	83 e0 04             	and    $0x4,%eax
80102759:	85 c0                	test   %eax,%eax
8010275b:	75 2e                	jne    8010278b <ideintr+0x76>
8010275d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102764:	e8 66 fd ff ff       	call   801024cf <idewait>
80102769:	85 c0                	test   %eax,%eax
8010276b:	78 1e                	js     8010278b <ideintr+0x76>
    insl(0x1f0, b->data, BSIZE/4);
8010276d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102770:	83 c0 18             	add    $0x18,%eax
80102773:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010277a:	00 
8010277b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010277f:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102786:	e8 dc fc ff ff       	call   80102467 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010278b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010278e:	8b 00                	mov    (%eax),%eax
80102790:	83 c8 02             	or     $0x2,%eax
80102793:	89 c2                	mov    %eax,%edx
80102795:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102798:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010279a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010279d:	8b 00                	mov    (%eax),%eax
8010279f:	83 e0 fb             	and    $0xfffffffb,%eax
801027a2:	89 c2                	mov    %eax,%edx
801027a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027a7:	89 10                	mov    %edx,(%eax)
  wakeup(b);
801027a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027ac:	89 04 24             	mov    %eax,(%esp)
801027af:	e8 26 25 00 00       	call   80104cda <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
801027b4:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027b9:	85 c0                	test   %eax,%eax
801027bb:	74 0d                	je     801027ca <ideintr+0xb5>
    idestart(idequeue);
801027bd:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027c2:	89 04 24             	mov    %eax,(%esp)
801027c5:	e8 ef fd ff ff       	call   801025b9 <idestart>

  release(&idelock);
801027ca:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027d1:	e8 85 28 00 00       	call   8010505b <release>
}
801027d6:	c9                   	leave  
801027d7:	c3                   	ret    

801027d8 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
801027d8:	55                   	push   %ebp
801027d9:	89 e5                	mov    %esp,%ebp
801027db:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
801027de:	8b 45 08             	mov    0x8(%ebp),%eax
801027e1:	8b 00                	mov    (%eax),%eax
801027e3:	83 e0 01             	and    $0x1,%eax
801027e6:	85 c0                	test   %eax,%eax
801027e8:	75 0c                	jne    801027f6 <iderw+0x1e>
    panic("iderw: buf not busy");
801027ea:	c7 04 24 83 87 10 80 	movl   $0x80108783,(%esp)
801027f1:	e8 44 dd ff ff       	call   8010053a <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
801027f6:	8b 45 08             	mov    0x8(%ebp),%eax
801027f9:	8b 00                	mov    (%eax),%eax
801027fb:	83 e0 06             	and    $0x6,%eax
801027fe:	83 f8 02             	cmp    $0x2,%eax
80102801:	75 0c                	jne    8010280f <iderw+0x37>
    panic("iderw: nothing to do");
80102803:	c7 04 24 97 87 10 80 	movl   $0x80108797,(%esp)
8010280a:	e8 2b dd ff ff       	call   8010053a <panic>
  if(b->dev != 0 && !havedisk1)
8010280f:	8b 45 08             	mov    0x8(%ebp),%eax
80102812:	8b 40 04             	mov    0x4(%eax),%eax
80102815:	85 c0                	test   %eax,%eax
80102817:	74 15                	je     8010282e <iderw+0x56>
80102819:	a1 38 b6 10 80       	mov    0x8010b638,%eax
8010281e:	85 c0                	test   %eax,%eax
80102820:	75 0c                	jne    8010282e <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102822:	c7 04 24 ac 87 10 80 	movl   $0x801087ac,(%esp)
80102829:	e8 0c dd ff ff       	call   8010053a <panic>

  acquire(&idelock);  //DOC:acquire-lock
8010282e:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102835:	e8 bf 27 00 00       	call   80104ff9 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
8010283a:	8b 45 08             	mov    0x8(%ebp),%eax
8010283d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80102844:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
8010284b:	eb 0b                	jmp    80102858 <iderw+0x80>
8010284d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102850:	8b 00                	mov    (%eax),%eax
80102852:	83 c0 14             	add    $0x14,%eax
80102855:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102858:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010285b:	8b 00                	mov    (%eax),%eax
8010285d:	85 c0                	test   %eax,%eax
8010285f:	75 ec                	jne    8010284d <iderw+0x75>
    ;
  *pp = b;
80102861:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102864:	8b 55 08             	mov    0x8(%ebp),%edx
80102867:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102869:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010286e:	3b 45 08             	cmp    0x8(%ebp),%eax
80102871:	75 0d                	jne    80102880 <iderw+0xa8>
    idestart(b);
80102873:	8b 45 08             	mov    0x8(%ebp),%eax
80102876:	89 04 24             	mov    %eax,(%esp)
80102879:	e8 3b fd ff ff       	call   801025b9 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
8010287e:	eb 15                	jmp    80102895 <iderw+0xbd>
80102880:	eb 13                	jmp    80102895 <iderw+0xbd>
    sleep(b, &idelock);
80102882:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
80102889:	80 
8010288a:	8b 45 08             	mov    0x8(%ebp),%eax
8010288d:	89 04 24             	mov    %eax,(%esp)
80102890:	e8 69 23 00 00       	call   80104bfe <sleep>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102895:	8b 45 08             	mov    0x8(%ebp),%eax
80102898:	8b 00                	mov    (%eax),%eax
8010289a:	83 e0 06             	and    $0x6,%eax
8010289d:	83 f8 02             	cmp    $0x2,%eax
801028a0:	75 e0                	jne    80102882 <iderw+0xaa>
    sleep(b, &idelock);
  }

  release(&idelock);
801028a2:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028a9:	e8 ad 27 00 00       	call   8010505b <release>
}
801028ae:	c9                   	leave  
801028af:	c3                   	ret    

801028b0 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
801028b0:	55                   	push   %ebp
801028b1:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028b3:	a1 14 22 11 80       	mov    0x80112214,%eax
801028b8:	8b 55 08             	mov    0x8(%ebp),%edx
801028bb:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028bd:	a1 14 22 11 80       	mov    0x80112214,%eax
801028c2:	8b 40 10             	mov    0x10(%eax),%eax
}
801028c5:	5d                   	pop    %ebp
801028c6:	c3                   	ret    

801028c7 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801028c7:	55                   	push   %ebp
801028c8:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028ca:	a1 14 22 11 80       	mov    0x80112214,%eax
801028cf:	8b 55 08             	mov    0x8(%ebp),%edx
801028d2:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
801028d4:	a1 14 22 11 80       	mov    0x80112214,%eax
801028d9:	8b 55 0c             	mov    0xc(%ebp),%edx
801028dc:	89 50 10             	mov    %edx,0x10(%eax)
}
801028df:	5d                   	pop    %ebp
801028e0:	c3                   	ret    

801028e1 <ioapicinit>:

void
ioapicinit(void)
{
801028e1:	55                   	push   %ebp
801028e2:	89 e5                	mov    %esp,%ebp
801028e4:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
801028e7:	a1 44 23 11 80       	mov    0x80112344,%eax
801028ec:	85 c0                	test   %eax,%eax
801028ee:	75 05                	jne    801028f5 <ioapicinit+0x14>
    return;
801028f0:	e9 9d 00 00 00       	jmp    80102992 <ioapicinit+0xb1>

  ioapic = (volatile struct ioapic*)IOAPIC;
801028f5:	c7 05 14 22 11 80 00 	movl   $0xfec00000,0x80112214
801028fc:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
801028ff:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102906:	e8 a5 ff ff ff       	call   801028b0 <ioapicread>
8010290b:	c1 e8 10             	shr    $0x10,%eax
8010290e:	25 ff 00 00 00       	and    $0xff,%eax
80102913:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102916:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010291d:	e8 8e ff ff ff       	call   801028b0 <ioapicread>
80102922:	c1 e8 18             	shr    $0x18,%eax
80102925:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102928:	0f b6 05 40 23 11 80 	movzbl 0x80112340,%eax
8010292f:	0f b6 c0             	movzbl %al,%eax
80102932:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102935:	74 0c                	je     80102943 <ioapicinit+0x62>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102937:	c7 04 24 cc 87 10 80 	movl   $0x801087cc,(%esp)
8010293e:	e8 5d da ff ff       	call   801003a0 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102943:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010294a:	eb 3e                	jmp    8010298a <ioapicinit+0xa9>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
8010294c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010294f:	83 c0 20             	add    $0x20,%eax
80102952:	0d 00 00 01 00       	or     $0x10000,%eax
80102957:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010295a:	83 c2 08             	add    $0x8,%edx
8010295d:	01 d2                	add    %edx,%edx
8010295f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102963:	89 14 24             	mov    %edx,(%esp)
80102966:	e8 5c ff ff ff       	call   801028c7 <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
8010296b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010296e:	83 c0 08             	add    $0x8,%eax
80102971:	01 c0                	add    %eax,%eax
80102973:	83 c0 01             	add    $0x1,%eax
80102976:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010297d:	00 
8010297e:	89 04 24             	mov    %eax,(%esp)
80102981:	e8 41 ff ff ff       	call   801028c7 <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102986:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010298a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010298d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102990:	7e ba                	jle    8010294c <ioapicinit+0x6b>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102992:	c9                   	leave  
80102993:	c3                   	ret    

80102994 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102994:	55                   	push   %ebp
80102995:	89 e5                	mov    %esp,%ebp
80102997:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
8010299a:	a1 44 23 11 80       	mov    0x80112344,%eax
8010299f:	85 c0                	test   %eax,%eax
801029a1:	75 02                	jne    801029a5 <ioapicenable+0x11>
    return;
801029a3:	eb 37                	jmp    801029dc <ioapicenable+0x48>

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
801029a5:	8b 45 08             	mov    0x8(%ebp),%eax
801029a8:	83 c0 20             	add    $0x20,%eax
801029ab:	8b 55 08             	mov    0x8(%ebp),%edx
801029ae:	83 c2 08             	add    $0x8,%edx
801029b1:	01 d2                	add    %edx,%edx
801029b3:	89 44 24 04          	mov    %eax,0x4(%esp)
801029b7:	89 14 24             	mov    %edx,(%esp)
801029ba:	e8 08 ff ff ff       	call   801028c7 <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801029bf:	8b 45 0c             	mov    0xc(%ebp),%eax
801029c2:	c1 e0 18             	shl    $0x18,%eax
801029c5:	8b 55 08             	mov    0x8(%ebp),%edx
801029c8:	83 c2 08             	add    $0x8,%edx
801029cb:	01 d2                	add    %edx,%edx
801029cd:	83 c2 01             	add    $0x1,%edx
801029d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801029d4:	89 14 24             	mov    %edx,(%esp)
801029d7:	e8 eb fe ff ff       	call   801028c7 <ioapicwrite>
}
801029dc:	c9                   	leave  
801029dd:	c3                   	ret    

801029de <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801029de:	55                   	push   %ebp
801029df:	89 e5                	mov    %esp,%ebp
801029e1:	8b 45 08             	mov    0x8(%ebp),%eax
801029e4:	05 00 00 00 80       	add    $0x80000000,%eax
801029e9:	5d                   	pop    %ebp
801029ea:	c3                   	ret    

801029eb <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
801029eb:	55                   	push   %ebp
801029ec:	89 e5                	mov    %esp,%ebp
801029ee:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
801029f1:	c7 44 24 04 fe 87 10 	movl   $0x801087fe,0x4(%esp)
801029f8:	80 
801029f9:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102a00:	e8 d3 25 00 00       	call   80104fd8 <initlock>
  kmem.use_lock = 0;
80102a05:	c7 05 54 22 11 80 00 	movl   $0x0,0x80112254
80102a0c:	00 00 00 
  freerange(vstart, vend);
80102a0f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a12:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a16:	8b 45 08             	mov    0x8(%ebp),%eax
80102a19:	89 04 24             	mov    %eax,(%esp)
80102a1c:	e8 26 00 00 00       	call   80102a47 <freerange>
}
80102a21:	c9                   	leave  
80102a22:	c3                   	ret    

80102a23 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102a23:	55                   	push   %ebp
80102a24:	89 e5                	mov    %esp,%ebp
80102a26:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102a29:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a2c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a30:	8b 45 08             	mov    0x8(%ebp),%eax
80102a33:	89 04 24             	mov    %eax,(%esp)
80102a36:	e8 0c 00 00 00       	call   80102a47 <freerange>
  kmem.use_lock = 1;
80102a3b:	c7 05 54 22 11 80 01 	movl   $0x1,0x80112254
80102a42:	00 00 00 
}
80102a45:	c9                   	leave  
80102a46:	c3                   	ret    

80102a47 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a47:	55                   	push   %ebp
80102a48:	89 e5                	mov    %esp,%ebp
80102a4a:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a4d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a50:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a55:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a5a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a5d:	eb 12                	jmp    80102a71 <freerange+0x2a>
    kfree(p);
80102a5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a62:	89 04 24             	mov    %eax,(%esp)
80102a65:	e8 16 00 00 00       	call   80102a80 <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a6a:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a74:	05 00 10 00 00       	add    $0x1000,%eax
80102a79:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102a7c:	76 e1                	jbe    80102a5f <freerange+0x18>
    kfree(p);
}
80102a7e:	c9                   	leave  
80102a7f:	c3                   	ret    

80102a80 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102a80:	55                   	push   %ebp
80102a81:	89 e5                	mov    %esp,%ebp
80102a83:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102a86:	8b 45 08             	mov    0x8(%ebp),%eax
80102a89:	25 ff 0f 00 00       	and    $0xfff,%eax
80102a8e:	85 c0                	test   %eax,%eax
80102a90:	75 1b                	jne    80102aad <kfree+0x2d>
80102a92:	81 7d 08 3c 53 11 80 	cmpl   $0x8011533c,0x8(%ebp)
80102a99:	72 12                	jb     80102aad <kfree+0x2d>
80102a9b:	8b 45 08             	mov    0x8(%ebp),%eax
80102a9e:	89 04 24             	mov    %eax,(%esp)
80102aa1:	e8 38 ff ff ff       	call   801029de <v2p>
80102aa6:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102aab:	76 0c                	jbe    80102ab9 <kfree+0x39>
    panic("kfree");
80102aad:	c7 04 24 03 88 10 80 	movl   $0x80108803,(%esp)
80102ab4:	e8 81 da ff ff       	call   8010053a <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102ab9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102ac0:	00 
80102ac1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102ac8:	00 
80102ac9:	8b 45 08             	mov    0x8(%ebp),%eax
80102acc:	89 04 24             	mov    %eax,(%esp)
80102acf:	e8 79 27 00 00       	call   8010524d <memset>

  if(kmem.use_lock)
80102ad4:	a1 54 22 11 80       	mov    0x80112254,%eax
80102ad9:	85 c0                	test   %eax,%eax
80102adb:	74 0c                	je     80102ae9 <kfree+0x69>
    acquire(&kmem.lock);
80102add:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102ae4:	e8 10 25 00 00       	call   80104ff9 <acquire>
  r = (struct run*)v;
80102ae9:	8b 45 08             	mov    0x8(%ebp),%eax
80102aec:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102aef:	8b 15 58 22 11 80    	mov    0x80112258,%edx
80102af5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102af8:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102afa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102afd:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102b02:	a1 54 22 11 80       	mov    0x80112254,%eax
80102b07:	85 c0                	test   %eax,%eax
80102b09:	74 0c                	je     80102b17 <kfree+0x97>
    release(&kmem.lock);
80102b0b:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102b12:	e8 44 25 00 00       	call   8010505b <release>
}
80102b17:	c9                   	leave  
80102b18:	c3                   	ret    

80102b19 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102b19:	55                   	push   %ebp
80102b1a:	89 e5                	mov    %esp,%ebp
80102b1c:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102b1f:	a1 54 22 11 80       	mov    0x80112254,%eax
80102b24:	85 c0                	test   %eax,%eax
80102b26:	74 0c                	je     80102b34 <kalloc+0x1b>
    acquire(&kmem.lock);
80102b28:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102b2f:	e8 c5 24 00 00       	call   80104ff9 <acquire>
  r = kmem.freelist;
80102b34:	a1 58 22 11 80       	mov    0x80112258,%eax
80102b39:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b3c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b40:	74 0a                	je     80102b4c <kalloc+0x33>
    kmem.freelist = r->next;
80102b42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b45:	8b 00                	mov    (%eax),%eax
80102b47:	a3 58 22 11 80       	mov    %eax,0x80112258
  if(kmem.use_lock)
80102b4c:	a1 54 22 11 80       	mov    0x80112254,%eax
80102b51:	85 c0                	test   %eax,%eax
80102b53:	74 0c                	je     80102b61 <kalloc+0x48>
    release(&kmem.lock);
80102b55:	c7 04 24 20 22 11 80 	movl   $0x80112220,(%esp)
80102b5c:	e8 fa 24 00 00       	call   8010505b <release>
  return (char*)r;
80102b61:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b64:	c9                   	leave  
80102b65:	c3                   	ret    

80102b66 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102b66:	55                   	push   %ebp
80102b67:	89 e5                	mov    %esp,%ebp
80102b69:	83 ec 14             	sub    $0x14,%esp
80102b6c:	8b 45 08             	mov    0x8(%ebp),%eax
80102b6f:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102b73:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102b77:	89 c2                	mov    %eax,%edx
80102b79:	ec                   	in     (%dx),%al
80102b7a:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102b7d:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102b81:	c9                   	leave  
80102b82:	c3                   	ret    

80102b83 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102b83:	55                   	push   %ebp
80102b84:	89 e5                	mov    %esp,%ebp
80102b86:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102b89:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102b90:	e8 d1 ff ff ff       	call   80102b66 <inb>
80102b95:	0f b6 c0             	movzbl %al,%eax
80102b98:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102b9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b9e:	83 e0 01             	and    $0x1,%eax
80102ba1:	85 c0                	test   %eax,%eax
80102ba3:	75 0a                	jne    80102baf <kbdgetc+0x2c>
    return -1;
80102ba5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102baa:	e9 25 01 00 00       	jmp    80102cd4 <kbdgetc+0x151>
  data = inb(KBDATAP);
80102baf:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102bb6:	e8 ab ff ff ff       	call   80102b66 <inb>
80102bbb:	0f b6 c0             	movzbl %al,%eax
80102bbe:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102bc1:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102bc8:	75 17                	jne    80102be1 <kbdgetc+0x5e>
    shift |= E0ESC;
80102bca:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102bcf:	83 c8 40             	or     $0x40,%eax
80102bd2:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102bd7:	b8 00 00 00 00       	mov    $0x0,%eax
80102bdc:	e9 f3 00 00 00       	jmp    80102cd4 <kbdgetc+0x151>
  } else if(data & 0x80){
80102be1:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102be4:	25 80 00 00 00       	and    $0x80,%eax
80102be9:	85 c0                	test   %eax,%eax
80102beb:	74 45                	je     80102c32 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102bed:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102bf2:	83 e0 40             	and    $0x40,%eax
80102bf5:	85 c0                	test   %eax,%eax
80102bf7:	75 08                	jne    80102c01 <kbdgetc+0x7e>
80102bf9:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102bfc:	83 e0 7f             	and    $0x7f,%eax
80102bff:	eb 03                	jmp    80102c04 <kbdgetc+0x81>
80102c01:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c04:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102c07:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c0a:	05 20 90 10 80       	add    $0x80109020,%eax
80102c0f:	0f b6 00             	movzbl (%eax),%eax
80102c12:	83 c8 40             	or     $0x40,%eax
80102c15:	0f b6 c0             	movzbl %al,%eax
80102c18:	f7 d0                	not    %eax
80102c1a:	89 c2                	mov    %eax,%edx
80102c1c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c21:	21 d0                	and    %edx,%eax
80102c23:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c28:	b8 00 00 00 00       	mov    $0x0,%eax
80102c2d:	e9 a2 00 00 00       	jmp    80102cd4 <kbdgetc+0x151>
  } else if(shift & E0ESC){
80102c32:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c37:	83 e0 40             	and    $0x40,%eax
80102c3a:	85 c0                	test   %eax,%eax
80102c3c:	74 14                	je     80102c52 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102c3e:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102c45:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c4a:	83 e0 bf             	and    $0xffffffbf,%eax
80102c4d:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102c52:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c55:	05 20 90 10 80       	add    $0x80109020,%eax
80102c5a:	0f b6 00             	movzbl (%eax),%eax
80102c5d:	0f b6 d0             	movzbl %al,%edx
80102c60:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c65:	09 d0                	or     %edx,%eax
80102c67:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102c6c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c6f:	05 20 91 10 80       	add    $0x80109120,%eax
80102c74:	0f b6 00             	movzbl (%eax),%eax
80102c77:	0f b6 d0             	movzbl %al,%edx
80102c7a:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c7f:	31 d0                	xor    %edx,%eax
80102c81:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102c86:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c8b:	83 e0 03             	and    $0x3,%eax
80102c8e:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102c95:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c98:	01 d0                	add    %edx,%eax
80102c9a:	0f b6 00             	movzbl (%eax),%eax
80102c9d:	0f b6 c0             	movzbl %al,%eax
80102ca0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102ca3:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ca8:	83 e0 08             	and    $0x8,%eax
80102cab:	85 c0                	test   %eax,%eax
80102cad:	74 22                	je     80102cd1 <kbdgetc+0x14e>
    if('a' <= c && c <= 'z')
80102caf:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102cb3:	76 0c                	jbe    80102cc1 <kbdgetc+0x13e>
80102cb5:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102cb9:	77 06                	ja     80102cc1 <kbdgetc+0x13e>
      c += 'A' - 'a';
80102cbb:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102cbf:	eb 10                	jmp    80102cd1 <kbdgetc+0x14e>
    else if('A' <= c && c <= 'Z')
80102cc1:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102cc5:	76 0a                	jbe    80102cd1 <kbdgetc+0x14e>
80102cc7:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102ccb:	77 04                	ja     80102cd1 <kbdgetc+0x14e>
      c += 'a' - 'A';
80102ccd:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102cd1:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102cd4:	c9                   	leave  
80102cd5:	c3                   	ret    

80102cd6 <kbdintr>:

void
kbdintr(void)
{
80102cd6:	55                   	push   %ebp
80102cd7:	89 e5                	mov    %esp,%ebp
80102cd9:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102cdc:	c7 04 24 83 2b 10 80 	movl   $0x80102b83,(%esp)
80102ce3:	e8 c5 da ff ff       	call   801007ad <consoleintr>
}
80102ce8:	c9                   	leave  
80102ce9:	c3                   	ret    

80102cea <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102cea:	55                   	push   %ebp
80102ceb:	89 e5                	mov    %esp,%ebp
80102ced:	83 ec 14             	sub    $0x14,%esp
80102cf0:	8b 45 08             	mov    0x8(%ebp),%eax
80102cf3:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102cf7:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102cfb:	89 c2                	mov    %eax,%edx
80102cfd:	ec                   	in     (%dx),%al
80102cfe:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102d01:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102d05:	c9                   	leave  
80102d06:	c3                   	ret    

80102d07 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102d07:	55                   	push   %ebp
80102d08:	89 e5                	mov    %esp,%ebp
80102d0a:	83 ec 08             	sub    $0x8,%esp
80102d0d:	8b 55 08             	mov    0x8(%ebp),%edx
80102d10:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d13:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102d17:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d1a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102d1e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102d22:	ee                   	out    %al,(%dx)
}
80102d23:	c9                   	leave  
80102d24:	c3                   	ret    

80102d25 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102d25:	55                   	push   %ebp
80102d26:	89 e5                	mov    %esp,%ebp
80102d28:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102d2b:	9c                   	pushf  
80102d2c:	58                   	pop    %eax
80102d2d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80102d30:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80102d33:	c9                   	leave  
80102d34:	c3                   	ret    

80102d35 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102d35:	55                   	push   %ebp
80102d36:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102d38:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102d3d:	8b 55 08             	mov    0x8(%ebp),%edx
80102d40:	c1 e2 02             	shl    $0x2,%edx
80102d43:	01 c2                	add    %eax,%edx
80102d45:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d48:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102d4a:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102d4f:	83 c0 20             	add    $0x20,%eax
80102d52:	8b 00                	mov    (%eax),%eax
}
80102d54:	5d                   	pop    %ebp
80102d55:	c3                   	ret    

80102d56 <lapicinit>:
//PAGEBREAK!

void
lapicinit(void)
{
80102d56:	55                   	push   %ebp
80102d57:	89 e5                	mov    %esp,%ebp
80102d59:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102d5c:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102d61:	85 c0                	test   %eax,%eax
80102d63:	75 05                	jne    80102d6a <lapicinit+0x14>
    return;
80102d65:	e9 43 01 00 00       	jmp    80102ead <lapicinit+0x157>

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102d6a:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102d71:	00 
80102d72:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102d79:	e8 b7 ff ff ff       	call   80102d35 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102d7e:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102d85:	00 
80102d86:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102d8d:	e8 a3 ff ff ff       	call   80102d35 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102d92:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102d99:	00 
80102d9a:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102da1:	e8 8f ff ff ff       	call   80102d35 <lapicw>
  lapicw(TICR, 10000000); 
80102da6:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102dad:	00 
80102dae:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102db5:	e8 7b ff ff ff       	call   80102d35 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102dba:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dc1:	00 
80102dc2:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102dc9:	e8 67 ff ff ff       	call   80102d35 <lapicw>
  lapicw(LINT1, MASKED);
80102dce:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dd5:	00 
80102dd6:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102ddd:	e8 53 ff ff ff       	call   80102d35 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102de2:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102de7:	83 c0 30             	add    $0x30,%eax
80102dea:	8b 00                	mov    (%eax),%eax
80102dec:	c1 e8 10             	shr    $0x10,%eax
80102def:	0f b6 c0             	movzbl %al,%eax
80102df2:	83 f8 03             	cmp    $0x3,%eax
80102df5:	76 14                	jbe    80102e0b <lapicinit+0xb5>
    lapicw(PCINT, MASKED);
80102df7:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dfe:	00 
80102dff:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102e06:	e8 2a ff ff ff       	call   80102d35 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102e0b:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102e12:	00 
80102e13:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102e1a:	e8 16 ff ff ff       	call   80102d35 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102e1f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e26:	00 
80102e27:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e2e:	e8 02 ff ff ff       	call   80102d35 <lapicw>
  lapicw(ESR, 0);
80102e33:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e3a:	00 
80102e3b:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e42:	e8 ee fe ff ff       	call   80102d35 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102e47:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e4e:	00 
80102e4f:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102e56:	e8 da fe ff ff       	call   80102d35 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102e5b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e62:	00 
80102e63:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102e6a:	e8 c6 fe ff ff       	call   80102d35 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102e6f:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102e76:	00 
80102e77:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102e7e:	e8 b2 fe ff ff       	call   80102d35 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102e83:	90                   	nop
80102e84:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102e89:	05 00 03 00 00       	add    $0x300,%eax
80102e8e:	8b 00                	mov    (%eax),%eax
80102e90:	25 00 10 00 00       	and    $0x1000,%eax
80102e95:	85 c0                	test   %eax,%eax
80102e97:	75 eb                	jne    80102e84 <lapicinit+0x12e>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102e99:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ea0:	00 
80102ea1:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102ea8:	e8 88 fe ff ff       	call   80102d35 <lapicw>
}
80102ead:	c9                   	leave  
80102eae:	c3                   	ret    

80102eaf <cpunum>:

int
cpunum(void)
{
80102eaf:	55                   	push   %ebp
80102eb0:	89 e5                	mov    %esp,%ebp
80102eb2:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102eb5:	e8 6b fe ff ff       	call   80102d25 <readeflags>
80102eba:	25 00 02 00 00       	and    $0x200,%eax
80102ebf:	85 c0                	test   %eax,%eax
80102ec1:	74 25                	je     80102ee8 <cpunum+0x39>
    static int n;
    if(n++ == 0)
80102ec3:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102ec8:	8d 50 01             	lea    0x1(%eax),%edx
80102ecb:	89 15 40 b6 10 80    	mov    %edx,0x8010b640
80102ed1:	85 c0                	test   %eax,%eax
80102ed3:	75 13                	jne    80102ee8 <cpunum+0x39>
      cprintf("cpu called from %x with interrupts enabled\n",
80102ed5:	8b 45 04             	mov    0x4(%ebp),%eax
80102ed8:	89 44 24 04          	mov    %eax,0x4(%esp)
80102edc:	c7 04 24 0c 88 10 80 	movl   $0x8010880c,(%esp)
80102ee3:	e8 b8 d4 ff ff       	call   801003a0 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102ee8:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102eed:	85 c0                	test   %eax,%eax
80102eef:	74 0f                	je     80102f00 <cpunum+0x51>
    return lapic[ID]>>24;
80102ef1:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102ef6:	83 c0 20             	add    $0x20,%eax
80102ef9:	8b 00                	mov    (%eax),%eax
80102efb:	c1 e8 18             	shr    $0x18,%eax
80102efe:	eb 05                	jmp    80102f05 <cpunum+0x56>
  return 0;
80102f00:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102f05:	c9                   	leave  
80102f06:	c3                   	ret    

80102f07 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102f07:	55                   	push   %ebp
80102f08:	89 e5                	mov    %esp,%ebp
80102f0a:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102f0d:	a1 5c 22 11 80       	mov    0x8011225c,%eax
80102f12:	85 c0                	test   %eax,%eax
80102f14:	74 14                	je     80102f2a <lapiceoi+0x23>
    lapicw(EOI, 0);
80102f16:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f1d:	00 
80102f1e:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f25:	e8 0b fe ff ff       	call   80102d35 <lapicw>
}
80102f2a:	c9                   	leave  
80102f2b:	c3                   	ret    

80102f2c <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102f2c:	55                   	push   %ebp
80102f2d:	89 e5                	mov    %esp,%ebp
}
80102f2f:	5d                   	pop    %ebp
80102f30:	c3                   	ret    

80102f31 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102f31:	55                   	push   %ebp
80102f32:	89 e5                	mov    %esp,%ebp
80102f34:	83 ec 1c             	sub    $0x1c,%esp
80102f37:	8b 45 08             	mov    0x8(%ebp),%eax
80102f3a:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
80102f3d:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102f44:	00 
80102f45:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102f4c:	e8 b6 fd ff ff       	call   80102d07 <outb>
  outb(CMOS_PORT+1, 0x0A);
80102f51:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102f58:	00 
80102f59:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102f60:	e8 a2 fd ff ff       	call   80102d07 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102f65:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80102f6c:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f6f:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80102f74:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102f77:	8d 50 02             	lea    0x2(%eax),%edx
80102f7a:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f7d:	c1 e8 04             	shr    $0x4,%eax
80102f80:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80102f83:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102f87:	c1 e0 18             	shl    $0x18,%eax
80102f8a:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f8e:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102f95:	e8 9b fd ff ff       	call   80102d35 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102f9a:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80102fa1:	00 
80102fa2:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fa9:	e8 87 fd ff ff       	call   80102d35 <lapicw>
  microdelay(200);
80102fae:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102fb5:	e8 72 ff ff ff       	call   80102f2c <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80102fba:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80102fc1:	00 
80102fc2:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fc9:	e8 67 fd ff ff       	call   80102d35 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80102fce:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102fd5:	e8 52 ff ff ff       	call   80102f2c <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80102fda:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80102fe1:	eb 40                	jmp    80103023 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80102fe3:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102fe7:	c1 e0 18             	shl    $0x18,%eax
80102fea:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fee:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102ff5:	e8 3b fd ff ff       	call   80102d35 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102ffa:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ffd:	c1 e8 0c             	shr    $0xc,%eax
80103000:	80 cc 06             	or     $0x6,%ah
80103003:	89 44 24 04          	mov    %eax,0x4(%esp)
80103007:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
8010300e:	e8 22 fd ff ff       	call   80102d35 <lapicw>
    microdelay(200);
80103013:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010301a:	e8 0d ff ff ff       	call   80102f2c <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
8010301f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103023:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103027:	7e ba                	jle    80102fe3 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103029:	c9                   	leave  
8010302a:	c3                   	ret    

8010302b <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
8010302b:	55                   	push   %ebp
8010302c:	89 e5                	mov    %esp,%ebp
8010302e:	83 ec 08             	sub    $0x8,%esp
  outb(CMOS_PORT,  reg);
80103031:	8b 45 08             	mov    0x8(%ebp),%eax
80103034:	0f b6 c0             	movzbl %al,%eax
80103037:	89 44 24 04          	mov    %eax,0x4(%esp)
8010303b:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80103042:	e8 c0 fc ff ff       	call   80102d07 <outb>
  microdelay(200);
80103047:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010304e:	e8 d9 fe ff ff       	call   80102f2c <microdelay>

  return inb(CMOS_RETURN);
80103053:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
8010305a:	e8 8b fc ff ff       	call   80102cea <inb>
8010305f:	0f b6 c0             	movzbl %al,%eax
}
80103062:	c9                   	leave  
80103063:	c3                   	ret    

80103064 <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
80103064:	55                   	push   %ebp
80103065:	89 e5                	mov    %esp,%ebp
80103067:	83 ec 04             	sub    $0x4,%esp
  r->second = cmos_read(SECS);
8010306a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80103071:	e8 b5 ff ff ff       	call   8010302b <cmos_read>
80103076:	8b 55 08             	mov    0x8(%ebp),%edx
80103079:	89 02                	mov    %eax,(%edx)
  r->minute = cmos_read(MINS);
8010307b:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80103082:	e8 a4 ff ff ff       	call   8010302b <cmos_read>
80103087:	8b 55 08             	mov    0x8(%ebp),%edx
8010308a:	89 42 04             	mov    %eax,0x4(%edx)
  r->hour   = cmos_read(HOURS);
8010308d:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80103094:	e8 92 ff ff ff       	call   8010302b <cmos_read>
80103099:	8b 55 08             	mov    0x8(%ebp),%edx
8010309c:	89 42 08             	mov    %eax,0x8(%edx)
  r->day    = cmos_read(DAY);
8010309f:	c7 04 24 07 00 00 00 	movl   $0x7,(%esp)
801030a6:	e8 80 ff ff ff       	call   8010302b <cmos_read>
801030ab:	8b 55 08             	mov    0x8(%ebp),%edx
801030ae:	89 42 0c             	mov    %eax,0xc(%edx)
  r->month  = cmos_read(MONTH);
801030b1:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801030b8:	e8 6e ff ff ff       	call   8010302b <cmos_read>
801030bd:	8b 55 08             	mov    0x8(%ebp),%edx
801030c0:	89 42 10             	mov    %eax,0x10(%edx)
  r->year   = cmos_read(YEAR);
801030c3:	c7 04 24 09 00 00 00 	movl   $0x9,(%esp)
801030ca:	e8 5c ff ff ff       	call   8010302b <cmos_read>
801030cf:	8b 55 08             	mov    0x8(%ebp),%edx
801030d2:	89 42 14             	mov    %eax,0x14(%edx)
}
801030d5:	c9                   	leave  
801030d6:	c3                   	ret    

801030d7 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801030d7:	55                   	push   %ebp
801030d8:	89 e5                	mov    %esp,%ebp
801030da:	83 ec 58             	sub    $0x58,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801030dd:	c7 04 24 0b 00 00 00 	movl   $0xb,(%esp)
801030e4:	e8 42 ff ff ff       	call   8010302b <cmos_read>
801030e9:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801030ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030ef:	83 e0 04             	and    $0x4,%eax
801030f2:	85 c0                	test   %eax,%eax
801030f4:	0f 94 c0             	sete   %al
801030f7:	0f b6 c0             	movzbl %al,%eax
801030fa:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for (;;) {
    fill_rtcdate(&t1);
801030fd:	8d 45 d8             	lea    -0x28(%ebp),%eax
80103100:	89 04 24             	mov    %eax,(%esp)
80103103:	e8 5c ff ff ff       	call   80103064 <fill_rtcdate>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
80103108:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
8010310f:	e8 17 ff ff ff       	call   8010302b <cmos_read>
80103114:	25 80 00 00 00       	and    $0x80,%eax
80103119:	85 c0                	test   %eax,%eax
8010311b:	74 02                	je     8010311f <cmostime+0x48>
        continue;
8010311d:	eb 36                	jmp    80103155 <cmostime+0x7e>
    fill_rtcdate(&t2);
8010311f:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103122:	89 04 24             	mov    %eax,(%esp)
80103125:	e8 3a ff ff ff       	call   80103064 <fill_rtcdate>
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
8010312a:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
80103131:	00 
80103132:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103135:	89 44 24 04          	mov    %eax,0x4(%esp)
80103139:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010313c:	89 04 24             	mov    %eax,(%esp)
8010313f:	e8 80 21 00 00       	call   801052c4 <memcmp>
80103144:	85 c0                	test   %eax,%eax
80103146:	75 0d                	jne    80103155 <cmostime+0x7e>
      break;
80103148:	90                   	nop
  }

  // convert
  if (bcd) {
80103149:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010314d:	0f 84 ac 00 00 00    	je     801031ff <cmostime+0x128>
80103153:	eb 02                	jmp    80103157 <cmostime+0x80>
    if (cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if (memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
80103155:	eb a6                	jmp    801030fd <cmostime+0x26>

  // convert
  if (bcd) {
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80103157:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010315a:	c1 e8 04             	shr    $0x4,%eax
8010315d:	89 c2                	mov    %eax,%edx
8010315f:	89 d0                	mov    %edx,%eax
80103161:	c1 e0 02             	shl    $0x2,%eax
80103164:	01 d0                	add    %edx,%eax
80103166:	01 c0                	add    %eax,%eax
80103168:	8b 55 d8             	mov    -0x28(%ebp),%edx
8010316b:	83 e2 0f             	and    $0xf,%edx
8010316e:	01 d0                	add    %edx,%eax
80103170:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103173:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103176:	c1 e8 04             	shr    $0x4,%eax
80103179:	89 c2                	mov    %eax,%edx
8010317b:	89 d0                	mov    %edx,%eax
8010317d:	c1 e0 02             	shl    $0x2,%eax
80103180:	01 d0                	add    %edx,%eax
80103182:	01 c0                	add    %eax,%eax
80103184:	8b 55 dc             	mov    -0x24(%ebp),%edx
80103187:	83 e2 0f             	and    $0xf,%edx
8010318a:	01 d0                	add    %edx,%eax
8010318c:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
8010318f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103192:	c1 e8 04             	shr    $0x4,%eax
80103195:	89 c2                	mov    %eax,%edx
80103197:	89 d0                	mov    %edx,%eax
80103199:	c1 e0 02             	shl    $0x2,%eax
8010319c:	01 d0                	add    %edx,%eax
8010319e:	01 c0                	add    %eax,%eax
801031a0:	8b 55 e0             	mov    -0x20(%ebp),%edx
801031a3:	83 e2 0f             	and    $0xf,%edx
801031a6:	01 d0                	add    %edx,%eax
801031a8:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
801031ab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801031ae:	c1 e8 04             	shr    $0x4,%eax
801031b1:	89 c2                	mov    %eax,%edx
801031b3:	89 d0                	mov    %edx,%eax
801031b5:	c1 e0 02             	shl    $0x2,%eax
801031b8:	01 d0                	add    %edx,%eax
801031ba:	01 c0                	add    %eax,%eax
801031bc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801031bf:	83 e2 0f             	and    $0xf,%edx
801031c2:	01 d0                	add    %edx,%eax
801031c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
801031c7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801031ca:	c1 e8 04             	shr    $0x4,%eax
801031cd:	89 c2                	mov    %eax,%edx
801031cf:	89 d0                	mov    %edx,%eax
801031d1:	c1 e0 02             	shl    $0x2,%eax
801031d4:	01 d0                	add    %edx,%eax
801031d6:	01 c0                	add    %eax,%eax
801031d8:	8b 55 e8             	mov    -0x18(%ebp),%edx
801031db:	83 e2 0f             	and    $0xf,%edx
801031de:	01 d0                	add    %edx,%eax
801031e0:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801031e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031e6:	c1 e8 04             	shr    $0x4,%eax
801031e9:	89 c2                	mov    %eax,%edx
801031eb:	89 d0                	mov    %edx,%eax
801031ed:	c1 e0 02             	shl    $0x2,%eax
801031f0:	01 d0                	add    %edx,%eax
801031f2:	01 c0                	add    %eax,%eax
801031f4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801031f7:	83 e2 0f             	and    $0xf,%edx
801031fa:	01 d0                	add    %edx,%eax
801031fc:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801031ff:	8b 45 08             	mov    0x8(%ebp),%eax
80103202:	8b 55 d8             	mov    -0x28(%ebp),%edx
80103205:	89 10                	mov    %edx,(%eax)
80103207:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010320a:	89 50 04             	mov    %edx,0x4(%eax)
8010320d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80103210:	89 50 08             	mov    %edx,0x8(%eax)
80103213:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103216:	89 50 0c             	mov    %edx,0xc(%eax)
80103219:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010321c:	89 50 10             	mov    %edx,0x10(%eax)
8010321f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103222:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103225:	8b 45 08             	mov    0x8(%ebp),%eax
80103228:	8b 40 14             	mov    0x14(%eax),%eax
8010322b:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
80103231:	8b 45 08             	mov    0x8(%ebp),%eax
80103234:	89 50 14             	mov    %edx,0x14(%eax)
}
80103237:	c9                   	leave  
80103238:	c3                   	ret    

80103239 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(void)
{
80103239:	55                   	push   %ebp
8010323a:	89 e5                	mov    %esp,%ebp
8010323c:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010323f:	c7 44 24 04 38 88 10 	movl   $0x80108838,0x4(%esp)
80103246:	80 
80103247:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010324e:	e8 85 1d 00 00       	call   80104fd8 <initlock>
  readsb(ROOTDEV, &sb);
80103253:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103256:	89 44 24 04          	mov    %eax,0x4(%esp)
8010325a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103261:	e8 8b e0 ff ff       	call   801012f1 <readsb>
  log.start = sb.size - sb.nlog;
80103266:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103269:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010326c:	29 c2                	sub    %eax,%edx
8010326e:	89 d0                	mov    %edx,%eax
80103270:	a3 94 22 11 80       	mov    %eax,0x80112294
  log.size = sb.nlog;
80103275:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103278:	a3 98 22 11 80       	mov    %eax,0x80112298
  log.dev = ROOTDEV;
8010327d:	c7 05 a4 22 11 80 01 	movl   $0x1,0x801122a4
80103284:	00 00 00 
  recover_from_log();
80103287:	e8 9a 01 00 00       	call   80103426 <recover_from_log>
}
8010328c:	c9                   	leave  
8010328d:	c3                   	ret    

8010328e <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010328e:	55                   	push   %ebp
8010328f:	89 e5                	mov    %esp,%ebp
80103291:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103294:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010329b:	e9 8c 00 00 00       	jmp    8010332c <install_trans+0x9e>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801032a0:	8b 15 94 22 11 80    	mov    0x80112294,%edx
801032a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032a9:	01 d0                	add    %edx,%eax
801032ab:	83 c0 01             	add    $0x1,%eax
801032ae:	89 c2                	mov    %eax,%edx
801032b0:	a1 a4 22 11 80       	mov    0x801122a4,%eax
801032b5:	89 54 24 04          	mov    %edx,0x4(%esp)
801032b9:	89 04 24             	mov    %eax,(%esp)
801032bc:	e8 e5 ce ff ff       	call   801001a6 <bread>
801032c1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801032c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801032c7:	83 c0 10             	add    $0x10,%eax
801032ca:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
801032d1:	89 c2                	mov    %eax,%edx
801032d3:	a1 a4 22 11 80       	mov    0x801122a4,%eax
801032d8:	89 54 24 04          	mov    %edx,0x4(%esp)
801032dc:	89 04 24             	mov    %eax,(%esp)
801032df:	e8 c2 ce ff ff       	call   801001a6 <bread>
801032e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801032e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032ea:	8d 50 18             	lea    0x18(%eax),%edx
801032ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032f0:	83 c0 18             	add    $0x18,%eax
801032f3:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801032fa:	00 
801032fb:	89 54 24 04          	mov    %edx,0x4(%esp)
801032ff:	89 04 24             	mov    %eax,(%esp)
80103302:	e8 15 20 00 00       	call   8010531c <memmove>
    bwrite(dbuf);  // write dst to disk
80103307:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010330a:	89 04 24             	mov    %eax,(%esp)
8010330d:	e8 cb ce ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103312:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103315:	89 04 24             	mov    %eax,(%esp)
80103318:	e8 fa ce ff ff       	call   80100217 <brelse>
    brelse(dbuf);
8010331d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103320:	89 04 24             	mov    %eax,(%esp)
80103323:	e8 ef ce ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103328:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010332c:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103331:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103334:	0f 8f 66 ff ff ff    	jg     801032a0 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
8010333a:	c9                   	leave  
8010333b:	c3                   	ret    

8010333c <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010333c:	55                   	push   %ebp
8010333d:	89 e5                	mov    %esp,%ebp
8010333f:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103342:	a1 94 22 11 80       	mov    0x80112294,%eax
80103347:	89 c2                	mov    %eax,%edx
80103349:	a1 a4 22 11 80       	mov    0x801122a4,%eax
8010334e:	89 54 24 04          	mov    %edx,0x4(%esp)
80103352:	89 04 24             	mov    %eax,(%esp)
80103355:	e8 4c ce ff ff       	call   801001a6 <bread>
8010335a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010335d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103360:	83 c0 18             	add    $0x18,%eax
80103363:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103366:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103369:	8b 00                	mov    (%eax),%eax
8010336b:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  for (i = 0; i < log.lh.n; i++) {
80103370:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103377:	eb 1b                	jmp    80103394 <read_head+0x58>
    log.lh.block[i] = lh->block[i];
80103379:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010337c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010337f:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103383:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103386:	83 c2 10             	add    $0x10,%edx
80103389:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103390:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103394:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103399:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010339c:	7f db                	jg     80103379 <read_head+0x3d>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
8010339e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033a1:	89 04 24             	mov    %eax,(%esp)
801033a4:	e8 6e ce ff ff       	call   80100217 <brelse>
}
801033a9:	c9                   	leave  
801033aa:	c3                   	ret    

801033ab <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801033ab:	55                   	push   %ebp
801033ac:	89 e5                	mov    %esp,%ebp
801033ae:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801033b1:	a1 94 22 11 80       	mov    0x80112294,%eax
801033b6:	89 c2                	mov    %eax,%edx
801033b8:	a1 a4 22 11 80       	mov    0x801122a4,%eax
801033bd:	89 54 24 04          	mov    %edx,0x4(%esp)
801033c1:	89 04 24             	mov    %eax,(%esp)
801033c4:	e8 dd cd ff ff       	call   801001a6 <bread>
801033c9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801033cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033cf:	83 c0 18             	add    $0x18,%eax
801033d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801033d5:	8b 15 a8 22 11 80    	mov    0x801122a8,%edx
801033db:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033de:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801033e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801033e7:	eb 1b                	jmp    80103404 <write_head+0x59>
    hb->block[i] = log.lh.block[i];
801033e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033ec:	83 c0 10             	add    $0x10,%eax
801033ef:	8b 0c 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%ecx
801033f6:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033f9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033fc:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
80103400:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103404:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103409:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010340c:	7f db                	jg     801033e9 <write_head+0x3e>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
8010340e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103411:	89 04 24             	mov    %eax,(%esp)
80103414:	e8 c4 cd ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103419:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010341c:	89 04 24             	mov    %eax,(%esp)
8010341f:	e8 f3 cd ff ff       	call   80100217 <brelse>
}
80103424:	c9                   	leave  
80103425:	c3                   	ret    

80103426 <recover_from_log>:

static void
recover_from_log(void)
{
80103426:	55                   	push   %ebp
80103427:	89 e5                	mov    %esp,%ebp
80103429:	83 ec 08             	sub    $0x8,%esp
  read_head();      
8010342c:	e8 0b ff ff ff       	call   8010333c <read_head>
  install_trans(); // if committed, copy from log to disk
80103431:	e8 58 fe ff ff       	call   8010328e <install_trans>
  log.lh.n = 0;
80103436:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
8010343d:	00 00 00 
  write_head(); // clear the log
80103440:	e8 66 ff ff ff       	call   801033ab <write_head>
}
80103445:	c9                   	leave  
80103446:	c3                   	ret    

80103447 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103447:	55                   	push   %ebp
80103448:	89 e5                	mov    %esp,%ebp
8010344a:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010344d:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103454:	e8 a0 1b 00 00       	call   80104ff9 <acquire>
  while(1){
    if(log.committing){
80103459:	a1 a0 22 11 80       	mov    0x801122a0,%eax
8010345e:	85 c0                	test   %eax,%eax
80103460:	74 16                	je     80103478 <begin_op+0x31>
      sleep(&log, &log.lock);
80103462:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
80103469:	80 
8010346a:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103471:	e8 88 17 00 00       	call   80104bfe <sleep>
80103476:	eb 4f                	jmp    801034c7 <begin_op+0x80>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
80103478:	8b 0d a8 22 11 80    	mov    0x801122a8,%ecx
8010347e:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80103483:	8d 50 01             	lea    0x1(%eax),%edx
80103486:	89 d0                	mov    %edx,%eax
80103488:	c1 e0 02             	shl    $0x2,%eax
8010348b:	01 d0                	add    %edx,%eax
8010348d:	01 c0                	add    %eax,%eax
8010348f:	01 c8                	add    %ecx,%eax
80103491:	83 f8 1e             	cmp    $0x1e,%eax
80103494:	7e 16                	jle    801034ac <begin_op+0x65>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103496:	c7 44 24 04 60 22 11 	movl   $0x80112260,0x4(%esp)
8010349d:	80 
8010349e:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801034a5:	e8 54 17 00 00       	call   80104bfe <sleep>
801034aa:	eb 1b                	jmp    801034c7 <begin_op+0x80>
    } else {
      log.outstanding += 1;
801034ac:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801034b1:	83 c0 01             	add    $0x1,%eax
801034b4:	a3 9c 22 11 80       	mov    %eax,0x8011229c
      release(&log.lock);
801034b9:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801034c0:	e8 96 1b 00 00       	call   8010505b <release>
      break;
801034c5:	eb 02                	jmp    801034c9 <begin_op+0x82>
    }
  }
801034c7:	eb 90                	jmp    80103459 <begin_op+0x12>
}
801034c9:	c9                   	leave  
801034ca:	c3                   	ret    

801034cb <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
801034cb:	55                   	push   %ebp
801034cc:	89 e5                	mov    %esp,%ebp
801034ce:	83 ec 28             	sub    $0x28,%esp
  int do_commit = 0;
801034d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801034d8:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
801034df:	e8 15 1b 00 00       	call   80104ff9 <acquire>
  log.outstanding -= 1;
801034e4:	a1 9c 22 11 80       	mov    0x8011229c,%eax
801034e9:	83 e8 01             	sub    $0x1,%eax
801034ec:	a3 9c 22 11 80       	mov    %eax,0x8011229c
  if(log.committing)
801034f1:	a1 a0 22 11 80       	mov    0x801122a0,%eax
801034f6:	85 c0                	test   %eax,%eax
801034f8:	74 0c                	je     80103506 <end_op+0x3b>
    panic("log.committing");
801034fa:	c7 04 24 3c 88 10 80 	movl   $0x8010883c,(%esp)
80103501:	e8 34 d0 ff ff       	call   8010053a <panic>
  if(log.outstanding == 0){
80103506:	a1 9c 22 11 80       	mov    0x8011229c,%eax
8010350b:	85 c0                	test   %eax,%eax
8010350d:	75 13                	jne    80103522 <end_op+0x57>
    do_commit = 1;
8010350f:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103516:	c7 05 a0 22 11 80 01 	movl   $0x1,0x801122a0
8010351d:	00 00 00 
80103520:	eb 0c                	jmp    8010352e <end_op+0x63>
  } else {
    // begin_op() may be waiting for log space.
    wakeup(&log);
80103522:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103529:	e8 ac 17 00 00       	call   80104cda <wakeup>
  }
  release(&log.lock);
8010352e:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103535:	e8 21 1b 00 00       	call   8010505b <release>

  if(do_commit){
8010353a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010353e:	74 33                	je     80103573 <end_op+0xa8>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103540:	e8 de 00 00 00       	call   80103623 <commit>
    acquire(&log.lock);
80103545:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010354c:	e8 a8 1a 00 00       	call   80104ff9 <acquire>
    log.committing = 0;
80103551:	c7 05 a0 22 11 80 00 	movl   $0x0,0x801122a0
80103558:	00 00 00 
    wakeup(&log);
8010355b:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103562:	e8 73 17 00 00       	call   80104cda <wakeup>
    release(&log.lock);
80103567:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010356e:	e8 e8 1a 00 00       	call   8010505b <release>
  }
}
80103573:	c9                   	leave  
80103574:	c3                   	ret    

80103575 <write_log>:

// Copy modified blocks from cache to log.
static void 
write_log(void)
{
80103575:	55                   	push   %ebp
80103576:	89 e5                	mov    %esp,%ebp
80103578:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010357b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103582:	e9 8c 00 00 00       	jmp    80103613 <write_log+0x9e>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103587:	8b 15 94 22 11 80    	mov    0x80112294,%edx
8010358d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103590:	01 d0                	add    %edx,%eax
80103592:	83 c0 01             	add    $0x1,%eax
80103595:	89 c2                	mov    %eax,%edx
80103597:	a1 a4 22 11 80       	mov    0x801122a4,%eax
8010359c:	89 54 24 04          	mov    %edx,0x4(%esp)
801035a0:	89 04 24             	mov    %eax,(%esp)
801035a3:	e8 fe cb ff ff       	call   801001a6 <bread>
801035a8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801035ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801035ae:	83 c0 10             	add    $0x10,%eax
801035b1:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
801035b8:	89 c2                	mov    %eax,%edx
801035ba:	a1 a4 22 11 80       	mov    0x801122a4,%eax
801035bf:	89 54 24 04          	mov    %edx,0x4(%esp)
801035c3:	89 04 24             	mov    %eax,(%esp)
801035c6:	e8 db cb ff ff       	call   801001a6 <bread>
801035cb:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
801035ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
801035d1:	8d 50 18             	lea    0x18(%eax),%edx
801035d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035d7:	83 c0 18             	add    $0x18,%eax
801035da:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801035e1:	00 
801035e2:	89 54 24 04          	mov    %edx,0x4(%esp)
801035e6:	89 04 24             	mov    %eax,(%esp)
801035e9:	e8 2e 1d 00 00       	call   8010531c <memmove>
    bwrite(to);  // write the log
801035ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035f1:	89 04 24             	mov    %eax,(%esp)
801035f4:	e8 e4 cb ff ff       	call   801001dd <bwrite>
    brelse(from); 
801035f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801035fc:	89 04 24             	mov    %eax,(%esp)
801035ff:	e8 13 cc ff ff       	call   80100217 <brelse>
    brelse(to);
80103604:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103607:	89 04 24             	mov    %eax,(%esp)
8010360a:	e8 08 cc ff ff       	call   80100217 <brelse>
static void 
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010360f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103613:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103618:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010361b:	0f 8f 66 ff ff ff    	jg     80103587 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from); 
    brelse(to);
  }
}
80103621:	c9                   	leave  
80103622:	c3                   	ret    

80103623 <commit>:

static void
commit()
{
80103623:	55                   	push   %ebp
80103624:	89 e5                	mov    %esp,%ebp
80103626:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103629:	a1 a8 22 11 80       	mov    0x801122a8,%eax
8010362e:	85 c0                	test   %eax,%eax
80103630:	7e 1e                	jle    80103650 <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
80103632:	e8 3e ff ff ff       	call   80103575 <write_log>
    write_head();    // Write header to disk -- the real commit
80103637:	e8 6f fd ff ff       	call   801033ab <write_head>
    install_trans(); // Now install writes to home locations
8010363c:	e8 4d fc ff ff       	call   8010328e <install_trans>
    log.lh.n = 0; 
80103641:	c7 05 a8 22 11 80 00 	movl   $0x0,0x801122a8
80103648:	00 00 00 
    write_head();    // Erase the transaction from the log
8010364b:	e8 5b fd ff ff       	call   801033ab <write_head>
  }
}
80103650:	c9                   	leave  
80103651:	c3                   	ret    

80103652 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103652:	55                   	push   %ebp
80103653:	89 e5                	mov    %esp,%ebp
80103655:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103658:	a1 a8 22 11 80       	mov    0x801122a8,%eax
8010365d:	83 f8 1d             	cmp    $0x1d,%eax
80103660:	7f 12                	jg     80103674 <log_write+0x22>
80103662:	a1 a8 22 11 80       	mov    0x801122a8,%eax
80103667:	8b 15 98 22 11 80    	mov    0x80112298,%edx
8010366d:	83 ea 01             	sub    $0x1,%edx
80103670:	39 d0                	cmp    %edx,%eax
80103672:	7c 0c                	jl     80103680 <log_write+0x2e>
    panic("too big a transaction");
80103674:	c7 04 24 4b 88 10 80 	movl   $0x8010884b,(%esp)
8010367b:	e8 ba ce ff ff       	call   8010053a <panic>
  if (log.outstanding < 1)
80103680:	a1 9c 22 11 80       	mov    0x8011229c,%eax
80103685:	85 c0                	test   %eax,%eax
80103687:	7f 0c                	jg     80103695 <log_write+0x43>
    panic("log_write outside of trans");
80103689:	c7 04 24 61 88 10 80 	movl   $0x80108861,(%esp)
80103690:	e8 a5 ce ff ff       	call   8010053a <panic>

  acquire(&log.lock);
80103695:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
8010369c:	e8 58 19 00 00       	call   80104ff9 <acquire>
  for (i = 0; i < log.lh.n; i++) {
801036a1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801036a8:	eb 1f                	jmp    801036c9 <log_write+0x77>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
801036aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036ad:	83 c0 10             	add    $0x10,%eax
801036b0:	8b 04 85 6c 22 11 80 	mov    -0x7feedd94(,%eax,4),%eax
801036b7:	89 c2                	mov    %eax,%edx
801036b9:	8b 45 08             	mov    0x8(%ebp),%eax
801036bc:	8b 40 08             	mov    0x8(%eax),%eax
801036bf:	39 c2                	cmp    %eax,%edx
801036c1:	75 02                	jne    801036c5 <log_write+0x73>
      break;
801036c3:	eb 0e                	jmp    801036d3 <log_write+0x81>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
801036c5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801036c9:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801036ce:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801036d1:	7f d7                	jg     801036aa <log_write+0x58>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
801036d3:	8b 45 08             	mov    0x8(%ebp),%eax
801036d6:	8b 40 08             	mov    0x8(%eax),%eax
801036d9:	8b 55 f4             	mov    -0xc(%ebp),%edx
801036dc:	83 c2 10             	add    $0x10,%edx
801036df:	89 04 95 6c 22 11 80 	mov    %eax,-0x7feedd94(,%edx,4)
  if (i == log.lh.n)
801036e6:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801036eb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801036ee:	75 0d                	jne    801036fd <log_write+0xab>
    log.lh.n++;
801036f0:	a1 a8 22 11 80       	mov    0x801122a8,%eax
801036f5:	83 c0 01             	add    $0x1,%eax
801036f8:	a3 a8 22 11 80       	mov    %eax,0x801122a8
  b->flags |= B_DIRTY; // prevent eviction
801036fd:	8b 45 08             	mov    0x8(%ebp),%eax
80103700:	8b 00                	mov    (%eax),%eax
80103702:	83 c8 04             	or     $0x4,%eax
80103705:	89 c2                	mov    %eax,%edx
80103707:	8b 45 08             	mov    0x8(%ebp),%eax
8010370a:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
8010370c:	c7 04 24 60 22 11 80 	movl   $0x80112260,(%esp)
80103713:	e8 43 19 00 00       	call   8010505b <release>
}
80103718:	c9                   	leave  
80103719:	c3                   	ret    

8010371a <v2p>:
8010371a:	55                   	push   %ebp
8010371b:	89 e5                	mov    %esp,%ebp
8010371d:	8b 45 08             	mov    0x8(%ebp),%eax
80103720:	05 00 00 00 80       	add    $0x80000000,%eax
80103725:	5d                   	pop    %ebp
80103726:	c3                   	ret    

80103727 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103727:	55                   	push   %ebp
80103728:	89 e5                	mov    %esp,%ebp
8010372a:	8b 45 08             	mov    0x8(%ebp),%eax
8010372d:	05 00 00 00 80       	add    $0x80000000,%eax
80103732:	5d                   	pop    %ebp
80103733:	c3                   	ret    

80103734 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103734:	55                   	push   %ebp
80103735:	89 e5                	mov    %esp,%ebp
80103737:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
8010373a:	8b 55 08             	mov    0x8(%ebp),%edx
8010373d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103740:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103743:	f0 87 02             	lock xchg %eax,(%edx)
80103746:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103749:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010374c:	c9                   	leave  
8010374d:	c3                   	ret    

8010374e <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010374e:	55                   	push   %ebp
8010374f:	89 e5                	mov    %esp,%ebp
80103751:	83 e4 f0             	and    $0xfffffff0,%esp
80103754:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103757:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010375e:	80 
8010375f:	c7 04 24 3c 53 11 80 	movl   $0x8011533c,(%esp)
80103766:	e8 80 f2 ff ff       	call   801029eb <kinit1>
  kvmalloc();      // kernel page table
8010376b:	e8 fc 46 00 00       	call   80107e6c <kvmalloc>
  mpinit();        // collect info about this machine
80103770:	e8 46 04 00 00       	call   80103bbb <mpinit>
  lapicinit();
80103775:	e8 dc f5 ff ff       	call   80102d56 <lapicinit>
  seginit();       // set up segments
8010377a:	e8 80 40 00 00       	call   801077ff <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
8010377f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103785:	0f b6 00             	movzbl (%eax),%eax
80103788:	0f b6 c0             	movzbl %al,%eax
8010378b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010378f:	c7 04 24 7c 88 10 80 	movl   $0x8010887c,(%esp)
80103796:	e8 05 cc ff ff       	call   801003a0 <cprintf>
  picinit();       // interrupt controller
8010379b:	e8 79 06 00 00       	call   80103e19 <picinit>
  ioapicinit();    // another interrupt controller
801037a0:	e8 3c f1 ff ff       	call   801028e1 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801037a5:	e8 d7 d2 ff ff       	call   80100a81 <consoleinit>
  uartinit();      // serial port
801037aa:	e8 9f 33 00 00       	call   80106b4e <uartinit>
  pinit();         // process table
801037af:	e8 6f 0b 00 00       	call   80104323 <pinit>
  tvinit();        // trap vectors
801037b4:	e8 47 2f 00 00       	call   80106700 <tvinit>
  binit();         // buffer cache
801037b9:	e8 76 c8 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801037be:	e8 47 d7 ff ff       	call   80100f0a <fileinit>
  iinit();         // inode cache
801037c3:	e8 dc dd ff ff       	call   801015a4 <iinit>
  ideinit();       // disk
801037c8:	e8 46 ed ff ff       	call   80102513 <ideinit>
  if(!ismp)
801037cd:	a1 44 23 11 80       	mov    0x80112344,%eax
801037d2:	85 c0                	test   %eax,%eax
801037d4:	75 05                	jne    801037db <main+0x8d>
    timerinit();   // uniprocessor timer
801037d6:	e8 70 2e 00 00       	call   8010664b <timerinit>
  startothers();   // start other processors
801037db:	e8 7f 00 00 00       	call   8010385f <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801037e0:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801037e7:	8e 
801037e8:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
801037ef:	e8 2f f2 ff ff       	call   80102a23 <kinit2>
  userinit();      // first user process
801037f4:	e8 66 0c 00 00       	call   8010445f <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
801037f9:	e8 1a 00 00 00       	call   80103818 <mpmain>

801037fe <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801037fe:	55                   	push   %ebp
801037ff:	89 e5                	mov    %esp,%ebp
80103801:	83 ec 08             	sub    $0x8,%esp
  switchkvm(); 
80103804:	e8 7a 46 00 00       	call   80107e83 <switchkvm>
  seginit();
80103809:	e8 f1 3f 00 00       	call   801077ff <seginit>
  lapicinit();
8010380e:	e8 43 f5 ff ff       	call   80102d56 <lapicinit>
  mpmain();
80103813:	e8 00 00 00 00       	call   80103818 <mpmain>

80103818 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103818:	55                   	push   %ebp
80103819:	89 e5                	mov    %esp,%ebp
8010381b:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010381e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103824:	0f b6 00             	movzbl (%eax),%eax
80103827:	0f b6 c0             	movzbl %al,%eax
8010382a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010382e:	c7 04 24 93 88 10 80 	movl   $0x80108893,(%esp)
80103835:	e8 66 cb ff ff       	call   801003a0 <cprintf>
  idtinit();       // load idt register
8010383a:	e8 35 30 00 00       	call   80106874 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
8010383f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103845:	05 a8 00 00 00       	add    $0xa8,%eax
8010384a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103851:	00 
80103852:	89 04 24             	mov    %eax,(%esp)
80103855:	e8 da fe ff ff       	call   80103734 <xchg>
  scheduler();     // start running processes
8010385a:	e8 a6 11 00 00       	call   80104a05 <scheduler>

8010385f <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010385f:	55                   	push   %ebp
80103860:	89 e5                	mov    %esp,%ebp
80103862:	53                   	push   %ebx
80103863:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103866:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010386d:	e8 b5 fe ff ff       	call   80103727 <p2v>
80103872:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103875:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010387a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010387e:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
80103885:	80 
80103886:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103889:	89 04 24             	mov    %eax,(%esp)
8010388c:	e8 8b 1a 00 00       	call   8010531c <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103891:	c7 45 f4 60 23 11 80 	movl   $0x80112360,-0xc(%ebp)
80103898:	e9 85 00 00 00       	jmp    80103922 <startothers+0xc3>
    if(c == cpus+cpunum())  // We've started already.
8010389d:	e8 0d f6 ff ff       	call   80102eaf <cpunum>
801038a2:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801038a8:	05 60 23 11 80       	add    $0x80112360,%eax
801038ad:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801038b0:	75 02                	jne    801038b4 <startothers+0x55>
      continue;
801038b2:	eb 67                	jmp    8010391b <startothers+0xbc>

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801038b4:	e8 60 f2 ff ff       	call   80102b19 <kalloc>
801038b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801038bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038bf:	83 e8 04             	sub    $0x4,%eax
801038c2:	8b 55 ec             	mov    -0x14(%ebp),%edx
801038c5:	81 c2 00 10 00 00    	add    $0x1000,%edx
801038cb:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801038cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038d0:	83 e8 08             	sub    $0x8,%eax
801038d3:	c7 00 fe 37 10 80    	movl   $0x801037fe,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801038d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038dc:	8d 58 f4             	lea    -0xc(%eax),%ebx
801038df:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
801038e6:	e8 2f fe ff ff       	call   8010371a <v2p>
801038eb:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
801038ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038f0:	89 04 24             	mov    %eax,(%esp)
801038f3:	e8 22 fe ff ff       	call   8010371a <v2p>
801038f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801038fb:	0f b6 12             	movzbl (%edx),%edx
801038fe:	0f b6 d2             	movzbl %dl,%edx
80103901:	89 44 24 04          	mov    %eax,0x4(%esp)
80103905:	89 14 24             	mov    %edx,(%esp)
80103908:	e8 24 f6 ff ff       	call   80102f31 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010390d:	90                   	nop
8010390e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103911:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103917:	85 c0                	test   %eax,%eax
80103919:	74 f3                	je     8010390e <startothers+0xaf>
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
8010391b:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103922:	a1 40 29 11 80       	mov    0x80112940,%eax
80103927:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010392d:	05 60 23 11 80       	add    $0x80112360,%eax
80103932:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103935:	0f 87 62 ff ff ff    	ja     8010389d <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
8010393b:	83 c4 24             	add    $0x24,%esp
8010393e:	5b                   	pop    %ebx
8010393f:	5d                   	pop    %ebp
80103940:	c3                   	ret    

80103941 <p2v>:
80103941:	55                   	push   %ebp
80103942:	89 e5                	mov    %esp,%ebp
80103944:	8b 45 08             	mov    0x8(%ebp),%eax
80103947:	05 00 00 00 80       	add    $0x80000000,%eax
8010394c:	5d                   	pop    %ebp
8010394d:	c3                   	ret    

8010394e <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010394e:	55                   	push   %ebp
8010394f:	89 e5                	mov    %esp,%ebp
80103951:	83 ec 14             	sub    $0x14,%esp
80103954:	8b 45 08             	mov    0x8(%ebp),%eax
80103957:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010395b:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010395f:	89 c2                	mov    %eax,%edx
80103961:	ec                   	in     (%dx),%al
80103962:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103965:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103969:	c9                   	leave  
8010396a:	c3                   	ret    

8010396b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010396b:	55                   	push   %ebp
8010396c:	89 e5                	mov    %esp,%ebp
8010396e:	83 ec 08             	sub    $0x8,%esp
80103971:	8b 55 08             	mov    0x8(%ebp),%edx
80103974:	8b 45 0c             	mov    0xc(%ebp),%eax
80103977:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010397b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010397e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103982:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103986:	ee                   	out    %al,(%dx)
}
80103987:	c9                   	leave  
80103988:	c3                   	ret    

80103989 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103989:	55                   	push   %ebp
8010398a:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
8010398c:	a1 44 b6 10 80       	mov    0x8010b644,%eax
80103991:	89 c2                	mov    %eax,%edx
80103993:	b8 60 23 11 80       	mov    $0x80112360,%eax
80103998:	29 c2                	sub    %eax,%edx
8010399a:	89 d0                	mov    %edx,%eax
8010399c:	c1 f8 02             	sar    $0x2,%eax
8010399f:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801039a5:	5d                   	pop    %ebp
801039a6:	c3                   	ret    

801039a7 <sum>:

static uchar
sum(uchar *addr, int len)
{
801039a7:	55                   	push   %ebp
801039a8:	89 e5                	mov    %esp,%ebp
801039aa:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801039ad:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801039b4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801039bb:	eb 15                	jmp    801039d2 <sum+0x2b>
    sum += addr[i];
801039bd:	8b 55 fc             	mov    -0x4(%ebp),%edx
801039c0:	8b 45 08             	mov    0x8(%ebp),%eax
801039c3:	01 d0                	add    %edx,%eax
801039c5:	0f b6 00             	movzbl (%eax),%eax
801039c8:	0f b6 c0             	movzbl %al,%eax
801039cb:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801039ce:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801039d2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801039d5:	3b 45 0c             	cmp    0xc(%ebp),%eax
801039d8:	7c e3                	jl     801039bd <sum+0x16>
    sum += addr[i];
  return sum;
801039da:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801039dd:	c9                   	leave  
801039de:	c3                   	ret    

801039df <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
801039df:	55                   	push   %ebp
801039e0:	89 e5                	mov    %esp,%ebp
801039e2:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
801039e5:	8b 45 08             	mov    0x8(%ebp),%eax
801039e8:	89 04 24             	mov    %eax,(%esp)
801039eb:	e8 51 ff ff ff       	call   80103941 <p2v>
801039f0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
801039f3:	8b 55 0c             	mov    0xc(%ebp),%edx
801039f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039f9:	01 d0                	add    %edx,%eax
801039fb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
801039fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a01:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103a04:	eb 3f                	jmp    80103a45 <mpsearch1+0x66>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103a06:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103a0d:	00 
80103a0e:	c7 44 24 04 a4 88 10 	movl   $0x801088a4,0x4(%esp)
80103a15:	80 
80103a16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a19:	89 04 24             	mov    %eax,(%esp)
80103a1c:	e8 a3 18 00 00       	call   801052c4 <memcmp>
80103a21:	85 c0                	test   %eax,%eax
80103a23:	75 1c                	jne    80103a41 <mpsearch1+0x62>
80103a25:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103a2c:	00 
80103a2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a30:	89 04 24             	mov    %eax,(%esp)
80103a33:	e8 6f ff ff ff       	call   801039a7 <sum>
80103a38:	84 c0                	test   %al,%al
80103a3a:	75 05                	jne    80103a41 <mpsearch1+0x62>
      return (struct mp*)p;
80103a3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a3f:	eb 11                	jmp    80103a52 <mpsearch1+0x73>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103a41:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103a45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a48:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103a4b:	72 b9                	jb     80103a06 <mpsearch1+0x27>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103a4d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103a52:	c9                   	leave  
80103a53:	c3                   	ret    

80103a54 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103a54:	55                   	push   %ebp
80103a55:	89 e5                	mov    %esp,%ebp
80103a57:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103a5a:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103a61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a64:	83 c0 0f             	add    $0xf,%eax
80103a67:	0f b6 00             	movzbl (%eax),%eax
80103a6a:	0f b6 c0             	movzbl %al,%eax
80103a6d:	c1 e0 08             	shl    $0x8,%eax
80103a70:	89 c2                	mov    %eax,%edx
80103a72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a75:	83 c0 0e             	add    $0xe,%eax
80103a78:	0f b6 00             	movzbl (%eax),%eax
80103a7b:	0f b6 c0             	movzbl %al,%eax
80103a7e:	09 d0                	or     %edx,%eax
80103a80:	c1 e0 04             	shl    $0x4,%eax
80103a83:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103a86:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103a8a:	74 21                	je     80103aad <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103a8c:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103a93:	00 
80103a94:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a97:	89 04 24             	mov    %eax,(%esp)
80103a9a:	e8 40 ff ff ff       	call   801039df <mpsearch1>
80103a9f:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103aa2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103aa6:	74 50                	je     80103af8 <mpsearch+0xa4>
      return mp;
80103aa8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103aab:	eb 5f                	jmp    80103b0c <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103aad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ab0:	83 c0 14             	add    $0x14,%eax
80103ab3:	0f b6 00             	movzbl (%eax),%eax
80103ab6:	0f b6 c0             	movzbl %al,%eax
80103ab9:	c1 e0 08             	shl    $0x8,%eax
80103abc:	89 c2                	mov    %eax,%edx
80103abe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ac1:	83 c0 13             	add    $0x13,%eax
80103ac4:	0f b6 00             	movzbl (%eax),%eax
80103ac7:	0f b6 c0             	movzbl %al,%eax
80103aca:	09 d0                	or     %edx,%eax
80103acc:	c1 e0 0a             	shl    $0xa,%eax
80103acf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103ad2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ad5:	2d 00 04 00 00       	sub    $0x400,%eax
80103ada:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103ae1:	00 
80103ae2:	89 04 24             	mov    %eax,(%esp)
80103ae5:	e8 f5 fe ff ff       	call   801039df <mpsearch1>
80103aea:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103aed:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103af1:	74 05                	je     80103af8 <mpsearch+0xa4>
      return mp;
80103af3:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103af6:	eb 14                	jmp    80103b0c <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103af8:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103aff:	00 
80103b00:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103b07:	e8 d3 fe ff ff       	call   801039df <mpsearch1>
}
80103b0c:	c9                   	leave  
80103b0d:	c3                   	ret    

80103b0e <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103b0e:	55                   	push   %ebp
80103b0f:	89 e5                	mov    %esp,%ebp
80103b11:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103b14:	e8 3b ff ff ff       	call   80103a54 <mpsearch>
80103b19:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103b1c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103b20:	74 0a                	je     80103b2c <mpconfig+0x1e>
80103b22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b25:	8b 40 04             	mov    0x4(%eax),%eax
80103b28:	85 c0                	test   %eax,%eax
80103b2a:	75 0a                	jne    80103b36 <mpconfig+0x28>
    return 0;
80103b2c:	b8 00 00 00 00       	mov    $0x0,%eax
80103b31:	e9 83 00 00 00       	jmp    80103bb9 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103b36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b39:	8b 40 04             	mov    0x4(%eax),%eax
80103b3c:	89 04 24             	mov    %eax,(%esp)
80103b3f:	e8 fd fd ff ff       	call   80103941 <p2v>
80103b44:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103b47:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103b4e:	00 
80103b4f:	c7 44 24 04 a9 88 10 	movl   $0x801088a9,0x4(%esp)
80103b56:	80 
80103b57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b5a:	89 04 24             	mov    %eax,(%esp)
80103b5d:	e8 62 17 00 00       	call   801052c4 <memcmp>
80103b62:	85 c0                	test   %eax,%eax
80103b64:	74 07                	je     80103b6d <mpconfig+0x5f>
    return 0;
80103b66:	b8 00 00 00 00       	mov    $0x0,%eax
80103b6b:	eb 4c                	jmp    80103bb9 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103b6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b70:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103b74:	3c 01                	cmp    $0x1,%al
80103b76:	74 12                	je     80103b8a <mpconfig+0x7c>
80103b78:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b7b:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103b7f:	3c 04                	cmp    $0x4,%al
80103b81:	74 07                	je     80103b8a <mpconfig+0x7c>
    return 0;
80103b83:	b8 00 00 00 00       	mov    $0x0,%eax
80103b88:	eb 2f                	jmp    80103bb9 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103b8a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b8d:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103b91:	0f b7 c0             	movzwl %ax,%eax
80103b94:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b9b:	89 04 24             	mov    %eax,(%esp)
80103b9e:	e8 04 fe ff ff       	call   801039a7 <sum>
80103ba3:	84 c0                	test   %al,%al
80103ba5:	74 07                	je     80103bae <mpconfig+0xa0>
    return 0;
80103ba7:	b8 00 00 00 00       	mov    $0x0,%eax
80103bac:	eb 0b                	jmp    80103bb9 <mpconfig+0xab>
  *pmp = mp;
80103bae:	8b 45 08             	mov    0x8(%ebp),%eax
80103bb1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103bb4:	89 10                	mov    %edx,(%eax)
  return conf;
80103bb6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103bb9:	c9                   	leave  
80103bba:	c3                   	ret    

80103bbb <mpinit>:

void
mpinit(void)
{
80103bbb:	55                   	push   %ebp
80103bbc:	89 e5                	mov    %esp,%ebp
80103bbe:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103bc1:	c7 05 44 b6 10 80 60 	movl   $0x80112360,0x8010b644
80103bc8:	23 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103bcb:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103bce:	89 04 24             	mov    %eax,(%esp)
80103bd1:	e8 38 ff ff ff       	call   80103b0e <mpconfig>
80103bd6:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103bd9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103bdd:	75 05                	jne    80103be4 <mpinit+0x29>
    return;
80103bdf:	e9 9c 01 00 00       	jmp    80103d80 <mpinit+0x1c5>
  ismp = 1;
80103be4:	c7 05 44 23 11 80 01 	movl   $0x1,0x80112344
80103beb:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103bee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bf1:	8b 40 24             	mov    0x24(%eax),%eax
80103bf4:	a3 5c 22 11 80       	mov    %eax,0x8011225c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103bf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bfc:	83 c0 2c             	add    $0x2c,%eax
80103bff:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c05:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c09:	0f b7 d0             	movzwl %ax,%edx
80103c0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c0f:	01 d0                	add    %edx,%eax
80103c11:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c14:	e9 f4 00 00 00       	jmp    80103d0d <mpinit+0x152>
    switch(*p){
80103c19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c1c:	0f b6 00             	movzbl (%eax),%eax
80103c1f:	0f b6 c0             	movzbl %al,%eax
80103c22:	83 f8 04             	cmp    $0x4,%eax
80103c25:	0f 87 bf 00 00 00    	ja     80103cea <mpinit+0x12f>
80103c2b:	8b 04 85 ec 88 10 80 	mov    -0x7fef7714(,%eax,4),%eax
80103c32:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103c34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c37:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103c3a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103c3d:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103c41:	0f b6 d0             	movzbl %al,%edx
80103c44:	a1 40 29 11 80       	mov    0x80112940,%eax
80103c49:	39 c2                	cmp    %eax,%edx
80103c4b:	74 2d                	je     80103c7a <mpinit+0xbf>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103c4d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103c50:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103c54:	0f b6 d0             	movzbl %al,%edx
80103c57:	a1 40 29 11 80       	mov    0x80112940,%eax
80103c5c:	89 54 24 08          	mov    %edx,0x8(%esp)
80103c60:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c64:	c7 04 24 ae 88 10 80 	movl   $0x801088ae,(%esp)
80103c6b:	e8 30 c7 ff ff       	call   801003a0 <cprintf>
        ismp = 0;
80103c70:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103c77:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103c7a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103c7d:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103c81:	0f b6 c0             	movzbl %al,%eax
80103c84:	83 e0 02             	and    $0x2,%eax
80103c87:	85 c0                	test   %eax,%eax
80103c89:	74 15                	je     80103ca0 <mpinit+0xe5>
        bcpu = &cpus[ncpu];
80103c8b:	a1 40 29 11 80       	mov    0x80112940,%eax
80103c90:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103c96:	05 60 23 11 80       	add    $0x80112360,%eax
80103c9b:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103ca0:	8b 15 40 29 11 80    	mov    0x80112940,%edx
80103ca6:	a1 40 29 11 80       	mov    0x80112940,%eax
80103cab:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103cb1:	81 c2 60 23 11 80    	add    $0x80112360,%edx
80103cb7:	88 02                	mov    %al,(%edx)
      ncpu++;
80103cb9:	a1 40 29 11 80       	mov    0x80112940,%eax
80103cbe:	83 c0 01             	add    $0x1,%eax
80103cc1:	a3 40 29 11 80       	mov    %eax,0x80112940
      p += sizeof(struct mpproc);
80103cc6:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103cca:	eb 41                	jmp    80103d0d <mpinit+0x152>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103ccc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ccf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103cd2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103cd5:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103cd9:	a2 40 23 11 80       	mov    %al,0x80112340
      p += sizeof(struct mpioapic);
80103cde:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103ce2:	eb 29                	jmp    80103d0d <mpinit+0x152>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103ce4:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103ce8:	eb 23                	jmp    80103d0d <mpinit+0x152>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103cea:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ced:	0f b6 00             	movzbl (%eax),%eax
80103cf0:	0f b6 c0             	movzbl %al,%eax
80103cf3:	89 44 24 04          	mov    %eax,0x4(%esp)
80103cf7:	c7 04 24 cc 88 10 80 	movl   $0x801088cc,(%esp)
80103cfe:	e8 9d c6 ff ff       	call   801003a0 <cprintf>
      ismp = 0;
80103d03:	c7 05 44 23 11 80 00 	movl   $0x0,0x80112344
80103d0a:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103d0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d10:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103d13:	0f 82 00 ff ff ff    	jb     80103c19 <mpinit+0x5e>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103d19:	a1 44 23 11 80       	mov    0x80112344,%eax
80103d1e:	85 c0                	test   %eax,%eax
80103d20:	75 1d                	jne    80103d3f <mpinit+0x184>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103d22:	c7 05 40 29 11 80 01 	movl   $0x1,0x80112940
80103d29:	00 00 00 
    lapic = 0;
80103d2c:	c7 05 5c 22 11 80 00 	movl   $0x0,0x8011225c
80103d33:	00 00 00 
    ioapicid = 0;
80103d36:	c6 05 40 23 11 80 00 	movb   $0x0,0x80112340
    return;
80103d3d:	eb 41                	jmp    80103d80 <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103d3f:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103d42:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103d46:	84 c0                	test   %al,%al
80103d48:	74 36                	je     80103d80 <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103d4a:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103d51:	00 
80103d52:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103d59:	e8 0d fc ff ff       	call   8010396b <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103d5e:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103d65:	e8 e4 fb ff ff       	call   8010394e <inb>
80103d6a:	83 c8 01             	or     $0x1,%eax
80103d6d:	0f b6 c0             	movzbl %al,%eax
80103d70:	89 44 24 04          	mov    %eax,0x4(%esp)
80103d74:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103d7b:	e8 eb fb ff ff       	call   8010396b <outb>
  }
}
80103d80:	c9                   	leave  
80103d81:	c3                   	ret    

80103d82 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103d82:	55                   	push   %ebp
80103d83:	89 e5                	mov    %esp,%ebp
80103d85:	83 ec 08             	sub    $0x8,%esp
80103d88:	8b 55 08             	mov    0x8(%ebp),%edx
80103d8b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d8e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103d92:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103d95:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103d99:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103d9d:	ee                   	out    %al,(%dx)
}
80103d9e:	c9                   	leave  
80103d9f:	c3                   	ret    

80103da0 <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103da0:	55                   	push   %ebp
80103da1:	89 e5                	mov    %esp,%ebp
80103da3:	83 ec 0c             	sub    $0xc,%esp
80103da6:	8b 45 08             	mov    0x8(%ebp),%eax
80103da9:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103dad:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103db1:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103db7:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103dbb:	0f b6 c0             	movzbl %al,%eax
80103dbe:	89 44 24 04          	mov    %eax,0x4(%esp)
80103dc2:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103dc9:	e8 b4 ff ff ff       	call   80103d82 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103dce:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103dd2:	66 c1 e8 08          	shr    $0x8,%ax
80103dd6:	0f b6 c0             	movzbl %al,%eax
80103dd9:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ddd:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103de4:	e8 99 ff ff ff       	call   80103d82 <outb>
}
80103de9:	c9                   	leave  
80103dea:	c3                   	ret    

80103deb <picenable>:

void
picenable(int irq)
{
80103deb:	55                   	push   %ebp
80103dec:	89 e5                	mov    %esp,%ebp
80103dee:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103df1:	8b 45 08             	mov    0x8(%ebp),%eax
80103df4:	ba 01 00 00 00       	mov    $0x1,%edx
80103df9:	89 c1                	mov    %eax,%ecx
80103dfb:	d3 e2                	shl    %cl,%edx
80103dfd:	89 d0                	mov    %edx,%eax
80103dff:	f7 d0                	not    %eax
80103e01:	89 c2                	mov    %eax,%edx
80103e03:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103e0a:	21 d0                	and    %edx,%eax
80103e0c:	0f b7 c0             	movzwl %ax,%eax
80103e0f:	89 04 24             	mov    %eax,(%esp)
80103e12:	e8 89 ff ff ff       	call   80103da0 <picsetmask>
}
80103e17:	c9                   	leave  
80103e18:	c3                   	ret    

80103e19 <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103e19:	55                   	push   %ebp
80103e1a:	89 e5                	mov    %esp,%ebp
80103e1c:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103e1f:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103e26:	00 
80103e27:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e2e:	e8 4f ff ff ff       	call   80103d82 <outb>
  outb(IO_PIC2+1, 0xFF);
80103e33:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103e3a:	00 
80103e3b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103e42:	e8 3b ff ff ff       	call   80103d82 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103e47:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103e4e:	00 
80103e4f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103e56:	e8 27 ff ff ff       	call   80103d82 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103e5b:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103e62:	00 
80103e63:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e6a:	e8 13 ff ff ff       	call   80103d82 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103e6f:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103e76:	00 
80103e77:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e7e:	e8 ff fe ff ff       	call   80103d82 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103e83:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103e8a:	00 
80103e8b:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103e92:	e8 eb fe ff ff       	call   80103d82 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103e97:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103e9e:	00 
80103e9f:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103ea6:	e8 d7 fe ff ff       	call   80103d82 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103eab:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103eb2:	00 
80103eb3:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103eba:	e8 c3 fe ff ff       	call   80103d82 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103ebf:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103ec6:	00 
80103ec7:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103ece:	e8 af fe ff ff       	call   80103d82 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103ed3:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103eda:	00 
80103edb:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103ee2:	e8 9b fe ff ff       	call   80103d82 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103ee7:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103eee:	00 
80103eef:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103ef6:	e8 87 fe ff ff       	call   80103d82 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103efb:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103f02:	00 
80103f03:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103f0a:	e8 73 fe ff ff       	call   80103d82 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103f0f:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103f16:	00 
80103f17:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103f1e:	e8 5f fe ff ff       	call   80103d82 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103f23:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103f2a:	00 
80103f2b:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103f32:	e8 4b fe ff ff       	call   80103d82 <outb>

  if(irqmask != 0xFFFF)
80103f37:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103f3e:	66 83 f8 ff          	cmp    $0xffff,%ax
80103f42:	74 12                	je     80103f56 <picinit+0x13d>
    picsetmask(irqmask);
80103f44:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103f4b:	0f b7 c0             	movzwl %ax,%eax
80103f4e:	89 04 24             	mov    %eax,(%esp)
80103f51:	e8 4a fe ff ff       	call   80103da0 <picsetmask>
}
80103f56:	c9                   	leave  
80103f57:	c3                   	ret    

80103f58 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103f58:	55                   	push   %ebp
80103f59:	89 e5                	mov    %esp,%ebp
80103f5b:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103f5e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103f65:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f68:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103f6e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f71:	8b 10                	mov    (%eax),%edx
80103f73:	8b 45 08             	mov    0x8(%ebp),%eax
80103f76:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103f78:	e8 a9 cf ff ff       	call   80100f26 <filealloc>
80103f7d:	8b 55 08             	mov    0x8(%ebp),%edx
80103f80:	89 02                	mov    %eax,(%edx)
80103f82:	8b 45 08             	mov    0x8(%ebp),%eax
80103f85:	8b 00                	mov    (%eax),%eax
80103f87:	85 c0                	test   %eax,%eax
80103f89:	0f 84 c8 00 00 00    	je     80104057 <pipealloc+0xff>
80103f8f:	e8 92 cf ff ff       	call   80100f26 <filealloc>
80103f94:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f97:	89 02                	mov    %eax,(%edx)
80103f99:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f9c:	8b 00                	mov    (%eax),%eax
80103f9e:	85 c0                	test   %eax,%eax
80103fa0:	0f 84 b1 00 00 00    	je     80104057 <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103fa6:	e8 6e eb ff ff       	call   80102b19 <kalloc>
80103fab:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103fae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103fb2:	75 05                	jne    80103fb9 <pipealloc+0x61>
    goto bad;
80103fb4:	e9 9e 00 00 00       	jmp    80104057 <pipealloc+0xff>
  p->readopen = 1;
80103fb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fbc:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103fc3:	00 00 00 
  p->writeopen = 1;
80103fc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fc9:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103fd0:	00 00 00 
  p->nwrite = 0;
80103fd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fd6:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103fdd:	00 00 00 
  p->nread = 0;
80103fe0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fe3:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103fea:	00 00 00 
  initlock(&p->lock, "pipe");
80103fed:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ff0:	c7 44 24 04 00 89 10 	movl   $0x80108900,0x4(%esp)
80103ff7:	80 
80103ff8:	89 04 24             	mov    %eax,(%esp)
80103ffb:	e8 d8 0f 00 00       	call   80104fd8 <initlock>
  (*f0)->type = FD_PIPE;
80104000:	8b 45 08             	mov    0x8(%ebp),%eax
80104003:	8b 00                	mov    (%eax),%eax
80104005:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
8010400b:	8b 45 08             	mov    0x8(%ebp),%eax
8010400e:	8b 00                	mov    (%eax),%eax
80104010:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80104014:	8b 45 08             	mov    0x8(%ebp),%eax
80104017:	8b 00                	mov    (%eax),%eax
80104019:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
8010401d:	8b 45 08             	mov    0x8(%ebp),%eax
80104020:	8b 00                	mov    (%eax),%eax
80104022:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104025:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80104028:	8b 45 0c             	mov    0xc(%ebp),%eax
8010402b:	8b 00                	mov    (%eax),%eax
8010402d:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80104033:	8b 45 0c             	mov    0xc(%ebp),%eax
80104036:	8b 00                	mov    (%eax),%eax
80104038:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
8010403c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010403f:	8b 00                	mov    (%eax),%eax
80104041:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80104045:	8b 45 0c             	mov    0xc(%ebp),%eax
80104048:	8b 00                	mov    (%eax),%eax
8010404a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010404d:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80104050:	b8 00 00 00 00       	mov    $0x0,%eax
80104055:	eb 42                	jmp    80104099 <pipealloc+0x141>

//PAGEBREAK: 20
 bad:
  if(p)
80104057:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010405b:	74 0b                	je     80104068 <pipealloc+0x110>
    kfree((char*)p);
8010405d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104060:	89 04 24             	mov    %eax,(%esp)
80104063:	e8 18 ea ff ff       	call   80102a80 <kfree>
  if(*f0)
80104068:	8b 45 08             	mov    0x8(%ebp),%eax
8010406b:	8b 00                	mov    (%eax),%eax
8010406d:	85 c0                	test   %eax,%eax
8010406f:	74 0d                	je     8010407e <pipealloc+0x126>
    fileclose(*f0);
80104071:	8b 45 08             	mov    0x8(%ebp),%eax
80104074:	8b 00                	mov    (%eax),%eax
80104076:	89 04 24             	mov    %eax,(%esp)
80104079:	e8 50 cf ff ff       	call   80100fce <fileclose>
  if(*f1)
8010407e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104081:	8b 00                	mov    (%eax),%eax
80104083:	85 c0                	test   %eax,%eax
80104085:	74 0d                	je     80104094 <pipealloc+0x13c>
    fileclose(*f1);
80104087:	8b 45 0c             	mov    0xc(%ebp),%eax
8010408a:	8b 00                	mov    (%eax),%eax
8010408c:	89 04 24             	mov    %eax,(%esp)
8010408f:	e8 3a cf ff ff       	call   80100fce <fileclose>
  return -1;
80104094:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104099:	c9                   	leave  
8010409a:	c3                   	ret    

8010409b <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
8010409b:	55                   	push   %ebp
8010409c:	89 e5                	mov    %esp,%ebp
8010409e:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
801040a1:	8b 45 08             	mov    0x8(%ebp),%eax
801040a4:	89 04 24             	mov    %eax,(%esp)
801040a7:	e8 4d 0f 00 00       	call   80104ff9 <acquire>
  if(writable){
801040ac:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801040b0:	74 1f                	je     801040d1 <pipeclose+0x36>
    p->writeopen = 0;
801040b2:	8b 45 08             	mov    0x8(%ebp),%eax
801040b5:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
801040bc:	00 00 00 
    wakeup(&p->nread);
801040bf:	8b 45 08             	mov    0x8(%ebp),%eax
801040c2:	05 34 02 00 00       	add    $0x234,%eax
801040c7:	89 04 24             	mov    %eax,(%esp)
801040ca:	e8 0b 0c 00 00       	call   80104cda <wakeup>
801040cf:	eb 1d                	jmp    801040ee <pipeclose+0x53>
  } else {
    p->readopen = 0;
801040d1:	8b 45 08             	mov    0x8(%ebp),%eax
801040d4:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
801040db:	00 00 00 
    wakeup(&p->nwrite);
801040de:	8b 45 08             	mov    0x8(%ebp),%eax
801040e1:	05 38 02 00 00       	add    $0x238,%eax
801040e6:	89 04 24             	mov    %eax,(%esp)
801040e9:	e8 ec 0b 00 00       	call   80104cda <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
801040ee:	8b 45 08             	mov    0x8(%ebp),%eax
801040f1:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801040f7:	85 c0                	test   %eax,%eax
801040f9:	75 25                	jne    80104120 <pipeclose+0x85>
801040fb:	8b 45 08             	mov    0x8(%ebp),%eax
801040fe:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104104:	85 c0                	test   %eax,%eax
80104106:	75 18                	jne    80104120 <pipeclose+0x85>
    release(&p->lock);
80104108:	8b 45 08             	mov    0x8(%ebp),%eax
8010410b:	89 04 24             	mov    %eax,(%esp)
8010410e:	e8 48 0f 00 00       	call   8010505b <release>
    kfree((char*)p);
80104113:	8b 45 08             	mov    0x8(%ebp),%eax
80104116:	89 04 24             	mov    %eax,(%esp)
80104119:	e8 62 e9 ff ff       	call   80102a80 <kfree>
8010411e:	eb 0b                	jmp    8010412b <pipeclose+0x90>
  } else
    release(&p->lock);
80104120:	8b 45 08             	mov    0x8(%ebp),%eax
80104123:	89 04 24             	mov    %eax,(%esp)
80104126:	e8 30 0f 00 00       	call   8010505b <release>
}
8010412b:	c9                   	leave  
8010412c:	c3                   	ret    

8010412d <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
8010412d:	55                   	push   %ebp
8010412e:	89 e5                	mov    %esp,%ebp
80104130:	83 ec 28             	sub    $0x28,%esp
  int i;

  acquire(&p->lock);
80104133:	8b 45 08             	mov    0x8(%ebp),%eax
80104136:	89 04 24             	mov    %eax,(%esp)
80104139:	e8 bb 0e 00 00       	call   80104ff9 <acquire>
  for(i = 0; i < n; i++){
8010413e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104145:	e9 a6 00 00 00       	jmp    801041f0 <pipewrite+0xc3>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010414a:	eb 57                	jmp    801041a3 <pipewrite+0x76>
      if(p->readopen == 0 || proc->killed){
8010414c:	8b 45 08             	mov    0x8(%ebp),%eax
8010414f:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80104155:	85 c0                	test   %eax,%eax
80104157:	74 0d                	je     80104166 <pipewrite+0x39>
80104159:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010415f:	8b 40 24             	mov    0x24(%eax),%eax
80104162:	85 c0                	test   %eax,%eax
80104164:	74 15                	je     8010417b <pipewrite+0x4e>
        release(&p->lock);
80104166:	8b 45 08             	mov    0x8(%ebp),%eax
80104169:	89 04 24             	mov    %eax,(%esp)
8010416c:	e8 ea 0e 00 00       	call   8010505b <release>
        return -1;
80104171:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104176:	e9 9f 00 00 00       	jmp    8010421a <pipewrite+0xed>
      }
      wakeup(&p->nread);
8010417b:	8b 45 08             	mov    0x8(%ebp),%eax
8010417e:	05 34 02 00 00       	add    $0x234,%eax
80104183:	89 04 24             	mov    %eax,(%esp)
80104186:	e8 4f 0b 00 00       	call   80104cda <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
8010418b:	8b 45 08             	mov    0x8(%ebp),%eax
8010418e:	8b 55 08             	mov    0x8(%ebp),%edx
80104191:	81 c2 38 02 00 00    	add    $0x238,%edx
80104197:	89 44 24 04          	mov    %eax,0x4(%esp)
8010419b:	89 14 24             	mov    %edx,(%esp)
8010419e:	e8 5b 0a 00 00       	call   80104bfe <sleep>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801041a3:	8b 45 08             	mov    0x8(%ebp),%eax
801041a6:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
801041ac:	8b 45 08             	mov    0x8(%ebp),%eax
801041af:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801041b5:	05 00 02 00 00       	add    $0x200,%eax
801041ba:	39 c2                	cmp    %eax,%edx
801041bc:	74 8e                	je     8010414c <pipewrite+0x1f>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
801041be:	8b 45 08             	mov    0x8(%ebp),%eax
801041c1:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801041c7:	8d 48 01             	lea    0x1(%eax),%ecx
801041ca:	8b 55 08             	mov    0x8(%ebp),%edx
801041cd:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
801041d3:	25 ff 01 00 00       	and    $0x1ff,%eax
801041d8:	89 c1                	mov    %eax,%ecx
801041da:	8b 55 f4             	mov    -0xc(%ebp),%edx
801041dd:	8b 45 0c             	mov    0xc(%ebp),%eax
801041e0:	01 d0                	add    %edx,%eax
801041e2:	0f b6 10             	movzbl (%eax),%edx
801041e5:	8b 45 08             	mov    0x8(%ebp),%eax
801041e8:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
801041ec:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801041f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041f3:	3b 45 10             	cmp    0x10(%ebp),%eax
801041f6:	0f 8c 4e ff ff ff    	jl     8010414a <pipewrite+0x1d>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
801041fc:	8b 45 08             	mov    0x8(%ebp),%eax
801041ff:	05 34 02 00 00       	add    $0x234,%eax
80104204:	89 04 24             	mov    %eax,(%esp)
80104207:	e8 ce 0a 00 00       	call   80104cda <wakeup>
  release(&p->lock);
8010420c:	8b 45 08             	mov    0x8(%ebp),%eax
8010420f:	89 04 24             	mov    %eax,(%esp)
80104212:	e8 44 0e 00 00       	call   8010505b <release>
  return n;
80104217:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010421a:	c9                   	leave  
8010421b:	c3                   	ret    

8010421c <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
8010421c:	55                   	push   %ebp
8010421d:	89 e5                	mov    %esp,%ebp
8010421f:	53                   	push   %ebx
80104220:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80104223:	8b 45 08             	mov    0x8(%ebp),%eax
80104226:	89 04 24             	mov    %eax,(%esp)
80104229:	e8 cb 0d 00 00       	call   80104ff9 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010422e:	eb 3a                	jmp    8010426a <piperead+0x4e>
    if(proc->killed){
80104230:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104236:	8b 40 24             	mov    0x24(%eax),%eax
80104239:	85 c0                	test   %eax,%eax
8010423b:	74 15                	je     80104252 <piperead+0x36>
      release(&p->lock);
8010423d:	8b 45 08             	mov    0x8(%ebp),%eax
80104240:	89 04 24             	mov    %eax,(%esp)
80104243:	e8 13 0e 00 00       	call   8010505b <release>
      return -1;
80104248:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010424d:	e9 b5 00 00 00       	jmp    80104307 <piperead+0xeb>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80104252:	8b 45 08             	mov    0x8(%ebp),%eax
80104255:	8b 55 08             	mov    0x8(%ebp),%edx
80104258:	81 c2 34 02 00 00    	add    $0x234,%edx
8010425e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104262:	89 14 24             	mov    %edx,(%esp)
80104265:	e8 94 09 00 00       	call   80104bfe <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010426a:	8b 45 08             	mov    0x8(%ebp),%eax
8010426d:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104273:	8b 45 08             	mov    0x8(%ebp),%eax
80104276:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010427c:	39 c2                	cmp    %eax,%edx
8010427e:	75 0d                	jne    8010428d <piperead+0x71>
80104280:	8b 45 08             	mov    0x8(%ebp),%eax
80104283:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104289:	85 c0                	test   %eax,%eax
8010428b:	75 a3                	jne    80104230 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
8010428d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104294:	eb 4b                	jmp    801042e1 <piperead+0xc5>
    if(p->nread == p->nwrite)
80104296:	8b 45 08             	mov    0x8(%ebp),%eax
80104299:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010429f:	8b 45 08             	mov    0x8(%ebp),%eax
801042a2:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801042a8:	39 c2                	cmp    %eax,%edx
801042aa:	75 02                	jne    801042ae <piperead+0x92>
      break;
801042ac:	eb 3b                	jmp    801042e9 <piperead+0xcd>
    addr[i] = p->data[p->nread++ % PIPESIZE];
801042ae:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042b1:	8b 45 0c             	mov    0xc(%ebp),%eax
801042b4:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801042b7:	8b 45 08             	mov    0x8(%ebp),%eax
801042ba:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
801042c0:	8d 48 01             	lea    0x1(%eax),%ecx
801042c3:	8b 55 08             	mov    0x8(%ebp),%edx
801042c6:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
801042cc:	25 ff 01 00 00       	and    $0x1ff,%eax
801042d1:	89 c2                	mov    %eax,%edx
801042d3:	8b 45 08             	mov    0x8(%ebp),%eax
801042d6:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
801042db:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801042dd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801042e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042e4:	3b 45 10             	cmp    0x10(%ebp),%eax
801042e7:	7c ad                	jl     80104296 <piperead+0x7a>
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
801042e9:	8b 45 08             	mov    0x8(%ebp),%eax
801042ec:	05 38 02 00 00       	add    $0x238,%eax
801042f1:	89 04 24             	mov    %eax,(%esp)
801042f4:	e8 e1 09 00 00       	call   80104cda <wakeup>
  release(&p->lock);
801042f9:	8b 45 08             	mov    0x8(%ebp),%eax
801042fc:	89 04 24             	mov    %eax,(%esp)
801042ff:	e8 57 0d 00 00       	call   8010505b <release>
  return i;
80104304:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104307:	83 c4 24             	add    $0x24,%esp
8010430a:	5b                   	pop    %ebx
8010430b:	5d                   	pop    %ebp
8010430c:	c3                   	ret    

8010430d <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
8010430d:	55                   	push   %ebp
8010430e:	89 e5                	mov    %esp,%ebp
80104310:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104313:	9c                   	pushf  
80104314:	58                   	pop    %eax
80104315:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104318:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010431b:	c9                   	leave  
8010431c:	c3                   	ret    

8010431d <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010431d:	55                   	push   %ebp
8010431e:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104320:	fb                   	sti    
}
80104321:	5d                   	pop    %ebp
80104322:	c3                   	ret    

80104323 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104323:	55                   	push   %ebp
80104324:	89 e5                	mov    %esp,%ebp
80104326:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104329:	c7 44 24 04 08 89 10 	movl   $0x80108908,0x4(%esp)
80104330:	80 
80104331:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104338:	e8 9b 0c 00 00       	call   80104fd8 <initlock>
}
8010433d:	c9                   	leave  
8010433e:	c3                   	ret    

8010433f <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(int stride)
{
8010433f:	55                   	push   %ebp
80104340:	89 e5                	mov    %esp,%ebp
80104342:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
80104345:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
8010434c:	e8 a8 0c 00 00       	call   80104ff9 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104351:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104358:	eb 71                	jmp    801043cb <allocproc+0x8c>
    if(p->state == UNUSED)
8010435a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435d:	8b 40 0c             	mov    0xc(%eax),%eax
80104360:	85 c0                	test   %eax,%eax
80104362:	75 60                	jne    801043c4 <allocproc+0x85>
      goto found;
80104364:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104365:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104368:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
8010436f:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104374:	8d 50 01             	lea    0x1(%eax),%edx
80104377:	89 15 04 b0 10 80    	mov    %edx,0x8010b004
8010437d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104380:	89 42 10             	mov    %eax,0x10(%edx)
  p->passo = STRIDE(stride);
80104383:	b8 e8 03 00 00       	mov    $0x3e8,%eax
80104388:	99                   	cltd   
80104389:	f7 7d 08             	idivl  0x8(%ebp)
8010438c:	89 c2                	mov    %eax,%edx
8010438e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104391:	89 50 7c             	mov    %edx,0x7c(%eax)
  p->passada = 0;
80104394:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104397:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%eax)
8010439e:	00 00 00 
  release(&ptable.lock);
801043a1:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801043a8:	e8 ae 0c 00 00       	call   8010505b <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
801043ad:	e8 67 e7 ff ff       	call   80102b19 <kalloc>
801043b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043b5:	89 42 08             	mov    %eax,0x8(%edx)
801043b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043bb:	8b 40 08             	mov    0x8(%eax),%eax
801043be:	85 c0                	test   %eax,%eax
801043c0:	75 36                	jne    801043f8 <allocproc+0xb9>
801043c2:	eb 23                	jmp    801043e7 <allocproc+0xa8>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801043c4:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
801043cb:	81 7d f4 94 4a 11 80 	cmpl   $0x80114a94,-0xc(%ebp)
801043d2:	72 86                	jb     8010435a <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801043d4:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801043db:	e8 7b 0c 00 00       	call   8010505b <release>
  return 0;
801043e0:	b8 00 00 00 00       	mov    $0x0,%eax
801043e5:	eb 76                	jmp    8010445d <allocproc+0x11e>
  p->passada = 0;
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
801043e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043ea:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
801043f1:	b8 00 00 00 00       	mov    $0x0,%eax
801043f6:	eb 65                	jmp    8010445d <allocproc+0x11e>
  }
  sp = p->kstack + KSTACKSIZE;
801043f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043fb:	8b 40 08             	mov    0x8(%eax),%eax
801043fe:	05 00 10 00 00       	add    $0x1000,%eax
80104403:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104406:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
8010440a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010440d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104410:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104413:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104417:	ba bb 66 10 80       	mov    $0x801066bb,%edx
8010441c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010441f:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104421:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104425:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104428:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010442b:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010442e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104431:	8b 40 1c             	mov    0x1c(%eax),%eax
80104434:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010443b:	00 
8010443c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104443:	00 
80104444:	89 04 24             	mov    %eax,(%esp)
80104447:	e8 01 0e 00 00       	call   8010524d <memset>
  p->context->eip = (uint)forkret;
8010444c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010444f:	8b 40 1c             	mov    0x1c(%eax),%eax
80104452:	ba d2 4b 10 80       	mov    $0x80104bd2,%edx
80104457:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
8010445a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010445d:	c9                   	leave  
8010445e:	c3                   	ret    

8010445f <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010445f:	55                   	push   %ebp
80104460:	89 e5                	mov    %esp,%ebp
80104462:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc(N_TICKETS);
80104465:	c7 04 24 fa 00 00 00 	movl   $0xfa,(%esp)
8010446c:	e8 ce fe ff ff       	call   8010433f <allocproc>
80104471:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
80104474:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104477:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm()) == 0)
8010447c:	e8 2e 39 00 00       	call   80107daf <setupkvm>
80104481:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104484:	89 42 04             	mov    %eax,0x4(%edx)
80104487:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010448a:	8b 40 04             	mov    0x4(%eax),%eax
8010448d:	85 c0                	test   %eax,%eax
8010448f:	75 0c                	jne    8010449d <userinit+0x3e>
    panic("userinit: out of memory?");
80104491:	c7 04 24 0f 89 10 80 	movl   $0x8010890f,(%esp)
80104498:	e8 9d c0 ff ff       	call   8010053a <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010449d:	ba 2c 00 00 00       	mov    $0x2c,%edx
801044a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044a5:	8b 40 04             	mov    0x4(%eax),%eax
801044a8:	89 54 24 08          	mov    %edx,0x8(%esp)
801044ac:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
801044b3:	80 
801044b4:	89 04 24             	mov    %eax,(%esp)
801044b7:	e8 4b 3b 00 00       	call   80108007 <inituvm>
  p->sz = PGSIZE;
801044bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044bf:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
801044c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044c8:	8b 40 18             	mov    0x18(%eax),%eax
801044cb:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
801044d2:	00 
801044d3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801044da:	00 
801044db:	89 04 24             	mov    %eax,(%esp)
801044de:	e8 6a 0d 00 00       	call   8010524d <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
801044e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044e6:	8b 40 18             	mov    0x18(%eax),%eax
801044e9:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
801044ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044f2:	8b 40 18             	mov    0x18(%eax),%eax
801044f5:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
801044fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044fe:	8b 40 18             	mov    0x18(%eax),%eax
80104501:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104504:	8b 52 18             	mov    0x18(%edx),%edx
80104507:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010450b:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010450f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104512:	8b 40 18             	mov    0x18(%eax),%eax
80104515:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104518:	8b 52 18             	mov    0x18(%edx),%edx
8010451b:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010451f:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104523:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104526:	8b 40 18             	mov    0x18(%eax),%eax
80104529:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
80104530:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104533:	8b 40 18             	mov    0x18(%eax),%eax
80104536:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
8010453d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104540:	8b 40 18             	mov    0x18(%eax),%eax
80104543:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
8010454a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010454d:	83 c0 6c             	add    $0x6c,%eax
80104550:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104557:	00 
80104558:	c7 44 24 04 28 89 10 	movl   $0x80108928,0x4(%esp)
8010455f:	80 
80104560:	89 04 24             	mov    %eax,(%esp)
80104563:	e8 05 0f 00 00       	call   8010546d <safestrcpy>
  p->cwd = namei("/");
80104568:	c7 04 24 31 89 10 80 	movl   $0x80108931,(%esp)
8010456f:	e8 92 de ff ff       	call   80102406 <namei>
80104574:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104577:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
8010457a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010457d:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104584:	c9                   	leave  
80104585:	c3                   	ret    

80104586 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104586:	55                   	push   %ebp
80104587:	89 e5                	mov    %esp,%ebp
80104589:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010458c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104592:	8b 00                	mov    (%eax),%eax
80104594:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104597:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010459b:	7e 34                	jle    801045d1 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010459d:	8b 55 08             	mov    0x8(%ebp),%edx
801045a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045a3:	01 c2                	add    %eax,%edx
801045a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045ab:	8b 40 04             	mov    0x4(%eax),%eax
801045ae:	89 54 24 08          	mov    %edx,0x8(%esp)
801045b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045b5:	89 54 24 04          	mov    %edx,0x4(%esp)
801045b9:	89 04 24             	mov    %eax,(%esp)
801045bc:	e8 bc 3b 00 00       	call   8010817d <allocuvm>
801045c1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801045c4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801045c8:	75 41                	jne    8010460b <growproc+0x85>
      return -1;
801045ca:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045cf:	eb 58                	jmp    80104629 <growproc+0xa3>
  } else if(n < 0){
801045d1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801045d5:	79 34                	jns    8010460b <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
801045d7:	8b 55 08             	mov    0x8(%ebp),%edx
801045da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045dd:	01 c2                	add    %eax,%edx
801045df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045e5:	8b 40 04             	mov    0x4(%eax),%eax
801045e8:	89 54 24 08          	mov    %edx,0x8(%esp)
801045ec:	8b 55 f4             	mov    -0xc(%ebp),%edx
801045ef:	89 54 24 04          	mov    %edx,0x4(%esp)
801045f3:	89 04 24             	mov    %eax,(%esp)
801045f6:	e8 5c 3c 00 00       	call   80108257 <deallocuvm>
801045fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
801045fe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104602:	75 07                	jne    8010460b <growproc+0x85>
      return -1;
80104604:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104609:	eb 1e                	jmp    80104629 <growproc+0xa3>
  }
  proc->sz = sz;
8010460b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104611:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104614:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104616:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010461c:	89 04 24             	mov    %eax,(%esp)
8010461f:	e8 7c 38 00 00       	call   80107ea0 <switchuvm>
  return 0;
80104624:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104629:	c9                   	leave  
8010462a:	c3                   	ret    

8010462b <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(int passo, char epasso)
{
8010462b:	55                   	push   %ebp
8010462c:	89 e5                	mov    %esp,%ebp
8010462e:	57                   	push   %edi
8010462f:	56                   	push   %esi
80104630:	53                   	push   %ebx
80104631:	83 ec 2c             	sub    $0x2c,%esp
80104634:	8b 45 0c             	mov    0xc(%ebp),%eax
80104637:	88 45 d4             	mov    %al,-0x2c(%ebp)
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc( (epasso && passo >=  MIN_TICKETS && passo <= MAX_TICKETS) ? passo : N_TICKETS)) == 0)
8010463a:	80 7d d4 00          	cmpb   $0x0,-0x2c(%ebp)
8010463e:	74 14                	je     80104654 <fork+0x29>
80104640:	83 7d 08 18          	cmpl   $0x18,0x8(%ebp)
80104644:	7e 0e                	jle    80104654 <fork+0x29>
80104646:	81 7d 08 e8 03 00 00 	cmpl   $0x3e8,0x8(%ebp)
8010464d:	7f 05                	jg     80104654 <fork+0x29>
8010464f:	8b 45 08             	mov    0x8(%ebp),%eax
80104652:	eb 05                	jmp    80104659 <fork+0x2e>
80104654:	b8 fa 00 00 00       	mov    $0xfa,%eax
80104659:	89 04 24             	mov    %eax,(%esp)
8010465c:	e8 de fc ff ff       	call   8010433f <allocproc>
80104661:	89 45 e0             	mov    %eax,-0x20(%ebp)
80104664:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80104668:	75 0a                	jne    80104674 <fork+0x49>
    return -1;
8010466a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010466f:	e9 52 01 00 00       	jmp    801047c6 <fork+0x19b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
80104674:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010467a:	8b 10                	mov    (%eax),%edx
8010467c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104682:	8b 40 04             	mov    0x4(%eax),%eax
80104685:	89 54 24 04          	mov    %edx,0x4(%esp)
80104689:	89 04 24             	mov    %eax,(%esp)
8010468c:	e8 62 3d 00 00       	call   801083f3 <copyuvm>
80104691:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104694:	89 42 04             	mov    %eax,0x4(%edx)
80104697:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010469a:	8b 40 04             	mov    0x4(%eax),%eax
8010469d:	85 c0                	test   %eax,%eax
8010469f:	75 2c                	jne    801046cd <fork+0xa2>
    kfree(np->kstack);
801046a1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046a4:	8b 40 08             	mov    0x8(%eax),%eax
801046a7:	89 04 24             	mov    %eax,(%esp)
801046aa:	e8 d1 e3 ff ff       	call   80102a80 <kfree>
    np->kstack = 0;
801046af:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046b2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801046b9:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046bc:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801046c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046c8:	e9 f9 00 00 00       	jmp    801047c6 <fork+0x19b>
  }
  np->sz = proc->sz;
801046cd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046d3:	8b 10                	mov    (%eax),%edx
801046d5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046d8:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801046da:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801046e1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046e4:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801046e7:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046ea:	8b 50 18             	mov    0x18(%eax),%edx
801046ed:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046f3:	8b 40 18             	mov    0x18(%eax),%eax
801046f6:	89 c3                	mov    %eax,%ebx
801046f8:	b8 13 00 00 00       	mov    $0x13,%eax
801046fd:	89 d7                	mov    %edx,%edi
801046ff:	89 de                	mov    %ebx,%esi
80104701:	89 c1                	mov    %eax,%ecx
80104703:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104705:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104708:	8b 40 18             	mov    0x18(%eax),%eax
8010470b:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104712:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104719:	eb 3d                	jmp    80104758 <fork+0x12d>
    if(proc->ofile[i])
8010471b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104721:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104724:	83 c2 08             	add    $0x8,%edx
80104727:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010472b:	85 c0                	test   %eax,%eax
8010472d:	74 25                	je     80104754 <fork+0x129>
      np->ofile[i] = filedup(proc->ofile[i]);
8010472f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104735:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104738:	83 c2 08             	add    $0x8,%edx
8010473b:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010473f:	89 04 24             	mov    %eax,(%esp)
80104742:	e8 3f c8 ff ff       	call   80100f86 <filedup>
80104747:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010474a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010474d:	83 c1 08             	add    $0x8,%ecx
80104750:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104754:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104758:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
8010475c:	7e bd                	jle    8010471b <fork+0xf0>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
8010475e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104764:	8b 40 68             	mov    0x68(%eax),%eax
80104767:	89 04 24             	mov    %eax,(%esp)
8010476a:	e8 ba d0 ff ff       	call   80101829 <idup>
8010476f:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104772:	89 42 68             	mov    %eax,0x68(%edx)

  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104775:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010477b:	8d 50 6c             	lea    0x6c(%eax),%edx
8010477e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104781:	83 c0 6c             	add    $0x6c,%eax
80104784:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010478b:	00 
8010478c:	89 54 24 04          	mov    %edx,0x4(%esp)
80104790:	89 04 24             	mov    %eax,(%esp)
80104793:	e8 d5 0c 00 00       	call   8010546d <safestrcpy>
 
  pid = np->pid;
80104798:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010479b:	8b 40 10             	mov    0x10(%eax),%eax
8010479e:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
801047a1:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801047a8:	e8 4c 08 00 00       	call   80104ff9 <acquire>
  np->state = RUNNABLE;
801047ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
801047b0:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  release(&ptable.lock);
801047b7:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801047be:	e8 98 08 00 00       	call   8010505b <release>
  
  return pid;
801047c3:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
801047c6:	83 c4 2c             	add    $0x2c,%esp
801047c9:	5b                   	pop    %ebx
801047ca:	5e                   	pop    %esi
801047cb:	5f                   	pop    %edi
801047cc:	5d                   	pop    %ebp
801047cd:	c3                   	ret    

801047ce <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
801047ce:	55                   	push   %ebp
801047cf:	89 e5                	mov    %esp,%ebp
801047d1:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
801047d4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801047db:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801047e0:	39 c2                	cmp    %eax,%edx
801047e2:	75 0c                	jne    801047f0 <exit+0x22>
    panic("init exiting");
801047e4:	c7 04 24 33 89 10 80 	movl   $0x80108933,(%esp)
801047eb:	e8 4a bd ff ff       	call   8010053a <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
801047f0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801047f7:	eb 44                	jmp    8010483d <exit+0x6f>
    if(proc->ofile[fd]){
801047f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047ff:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104802:	83 c2 08             	add    $0x8,%edx
80104805:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104809:	85 c0                	test   %eax,%eax
8010480b:	74 2c                	je     80104839 <exit+0x6b>
      fileclose(proc->ofile[fd]);
8010480d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104813:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104816:	83 c2 08             	add    $0x8,%edx
80104819:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010481d:	89 04 24             	mov    %eax,(%esp)
80104820:	e8 a9 c7 ff ff       	call   80100fce <fileclose>
      proc->ofile[fd] = 0;
80104825:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010482b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010482e:	83 c2 08             	add    $0x8,%edx
80104831:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104838:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104839:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010483d:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104841:	7e b6                	jle    801047f9 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
80104843:	e8 ff eb ff ff       	call   80103447 <begin_op>
  iput(proc->cwd);
80104848:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010484e:	8b 40 68             	mov    0x68(%eax),%eax
80104851:	89 04 24             	mov    %eax,(%esp)
80104854:	e8 b5 d1 ff ff       	call   80101a0e <iput>
  end_op();
80104859:	e8 6d ec ff ff       	call   801034cb <end_op>
  proc->cwd = 0;
8010485e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104864:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
8010486b:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104872:	e8 82 07 00 00       	call   80104ff9 <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104877:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010487d:	8b 40 14             	mov    0x14(%eax),%eax
80104880:	89 04 24             	mov    %eax,(%esp)
80104883:	e8 11 04 00 00       	call   80104c99 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104888:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
8010488f:	eb 3b                	jmp    801048cc <exit+0xfe>
    if(p->parent == proc){
80104891:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104894:	8b 50 14             	mov    0x14(%eax),%edx
80104897:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010489d:	39 c2                	cmp    %eax,%edx
8010489f:	75 24                	jne    801048c5 <exit+0xf7>
      p->parent = initproc;
801048a1:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
801048a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048aa:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801048ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048b0:	8b 40 0c             	mov    0xc(%eax),%eax
801048b3:	83 f8 05             	cmp    $0x5,%eax
801048b6:	75 0d                	jne    801048c5 <exit+0xf7>
        wakeup1(initproc);
801048b8:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801048bd:	89 04 24             	mov    %eax,(%esp)
801048c0:	e8 d4 03 00 00       	call   80104c99 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801048c5:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
801048cc:	81 7d f4 94 4a 11 80 	cmpl   $0x80114a94,-0xc(%ebp)
801048d3:	72 bc                	jb     80104891 <exit+0xc3>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
801048d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048db:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
801048e2:	e8 07 02 00 00       	call   80104aee <sched>
  panic("zombie exit");
801048e7:	c7 04 24 40 89 10 80 	movl   $0x80108940,(%esp)
801048ee:	e8 47 bc ff ff       	call   8010053a <panic>

801048f3 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
801048f3:	55                   	push   %ebp
801048f4:	89 e5                	mov    %esp,%ebp
801048f6:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
801048f9:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104900:	e8 f4 06 00 00       	call   80104ff9 <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104905:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010490c:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104913:	e9 9d 00 00 00       	jmp    801049b5 <wait+0xc2>
      if(p->parent != proc)
80104918:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010491b:	8b 50 14             	mov    0x14(%eax),%edx
8010491e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104924:	39 c2                	cmp    %eax,%edx
80104926:	74 05                	je     8010492d <wait+0x3a>
        continue;
80104928:	e9 81 00 00 00       	jmp    801049ae <wait+0xbb>
      havekids = 1;
8010492d:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104934:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104937:	8b 40 0c             	mov    0xc(%eax),%eax
8010493a:	83 f8 05             	cmp    $0x5,%eax
8010493d:	75 6f                	jne    801049ae <wait+0xbb>
        // Found one.
        pid = p->pid;
8010493f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104942:	8b 40 10             	mov    0x10(%eax),%eax
80104945:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104948:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010494b:	8b 40 08             	mov    0x8(%eax),%eax
8010494e:	89 04 24             	mov    %eax,(%esp)
80104951:	e8 2a e1 ff ff       	call   80102a80 <kfree>
        p->kstack = 0;
80104956:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104959:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104960:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104963:	8b 40 04             	mov    0x4(%eax),%eax
80104966:	89 04 24             	mov    %eax,(%esp)
80104969:	e8 a5 39 00 00       	call   80108313 <freevm>
        p->state = UNUSED;
8010496e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104971:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104978:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010497b:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104982:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104985:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
8010498c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010498f:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104993:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104996:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
8010499d:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801049a4:	e8 b2 06 00 00       	call   8010505b <release>
        return pid;
801049a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801049ac:	eb 55                	jmp    80104a03 <wait+0x110>

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049ae:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
801049b5:	81 7d f4 94 4a 11 80 	cmpl   $0x80114a94,-0xc(%ebp)
801049bc:	0f 82 56 ff ff ff    	jb     80104918 <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801049c2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801049c6:	74 0d                	je     801049d5 <wait+0xe2>
801049c8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049ce:	8b 40 24             	mov    0x24(%eax),%eax
801049d1:	85 c0                	test   %eax,%eax
801049d3:	74 13                	je     801049e8 <wait+0xf5>
      release(&ptable.lock);
801049d5:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
801049dc:	e8 7a 06 00 00       	call   8010505b <release>
      return -1;
801049e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049e6:	eb 1b                	jmp    80104a03 <wait+0x110>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
801049e8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049ee:	c7 44 24 04 60 29 11 	movl   $0x80112960,0x4(%esp)
801049f5:	80 
801049f6:	89 04 24             	mov    %eax,(%esp)
801049f9:	e8 00 02 00 00       	call   80104bfe <sleep>
  }
801049fe:	e9 02 ff ff ff       	jmp    80104905 <wait+0x12>
}
80104a03:	c9                   	leave  
80104a04:	c3                   	ret    

80104a05 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104a05:	55                   	push   %ebp
80104a06:	89 e5                	mov    %esp,%ebp
80104a08:	83 ec 28             	sub    $0x28,%esp
  struct proc *p, *min;
  int max;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104a0b:	e8 0d f9 ff ff       	call   8010431d <sti>

    // Loop over process table looking for process to run.

    acquire(&ptable.lock);
80104a10:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104a17:	e8 dd 05 00 00       	call   80104ff9 <acquire>
    for(p = ptable.proc, max = MAX_STRIDE, min = 0; p < &ptable.proc[NPROC]; p++){
80104a1c:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104a23:	c7 45 ec 00 09 3d 00 	movl   $0x3d0900,-0x14(%ebp)
80104a2a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104a31:	eb 34                	jmp    80104a67 <scheduler+0x62>
      if(p->state != RUNNABLE)
80104a33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a36:	8b 40 0c             	mov    0xc(%eax),%eax
80104a39:	83 f8 03             	cmp    $0x3,%eax
80104a3c:	74 02                	je     80104a40 <scheduler+0x3b>
        continue;
80104a3e:	eb 20                	jmp    80104a60 <scheduler+0x5b>
	  if(p->passada < max){
80104a40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a43:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80104a49:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104a4c:	7d 12                	jge    80104a60 <scheduler+0x5b>
		max = p->passada;
80104a4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a51:	8b 80 80 00 00 00    	mov    0x80(%eax),%eax
80104a57:	89 45 ec             	mov    %eax,-0x14(%ebp)
               
		min = p;  
80104a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    sti();

    // Loop over process table looking for process to run.

    acquire(&ptable.lock);
    for(p = ptable.proc, max = MAX_STRIDE, min = 0; p < &ptable.proc[NPROC]; p++){
80104a60:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
80104a67:	81 7d f4 94 4a 11 80 	cmpl   $0x80114a94,-0xc(%ebp)
80104a6e:	72 c3                	jb     80104a33 <scheduler+0x2e>
               
		min = p;  
	  }
	}

	if(min){
80104a70:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104a74:	74 67                	je     80104add <scheduler+0xd8>
	  min->passada += min->passo;
80104a76:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a79:	8b 90 80 00 00 00    	mov    0x80(%eax),%edx
80104a7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a82:	8b 40 7c             	mov    0x7c(%eax),%eax
80104a85:	01 c2                	add    %eax,%edx
80104a87:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a8a:	89 90 80 00 00 00    	mov    %edx,0x80(%eax)
	  // Switch to chosen process.  It is the process's job
	  // to release ptable.lock and then reacquire it
	  // before jumping back to us.
	  proc = min;
80104a90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a93:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
	  switchuvm(min);
80104a99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104a9c:	89 04 24             	mov    %eax,(%esp)
80104a9f:	e8 fc 33 00 00       	call   80107ea0 <switchuvm>
	  min->state = RUNNING;
80104aa4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104aa7:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
	  swtch(&cpu->scheduler, proc->context);
80104aae:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ab4:	8b 40 1c             	mov    0x1c(%eax),%eax
80104ab7:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104abe:	83 c2 04             	add    $0x4,%edx
80104ac1:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ac5:	89 14 24             	mov    %edx,(%esp)
80104ac8:	e8 11 0a 00 00       	call   801054de <swtch>
	  switchkvm();
80104acd:	e8 b1 33 00 00       	call   80107e83 <switchkvm>

	  // Process is done running for now.
	  // It should have changed its p->state before coming back.
	  proc = 0;
80104ad2:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104ad9:	00 00 00 00 
	}
  release(&ptable.lock);
80104add:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104ae4:	e8 72 05 00 00       	call   8010505b <release>
  }
80104ae9:	e9 1d ff ff ff       	jmp    80104a0b <scheduler+0x6>

80104aee <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104aee:	55                   	push   %ebp
80104aef:	89 e5                	mov    %esp,%ebp
80104af1:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104af4:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104afb:	e8 23 06 00 00       	call   80105123 <holding>
80104b00:	85 c0                	test   %eax,%eax
80104b02:	75 0c                	jne    80104b10 <sched+0x22>
    panic("sched ptable.lock");
80104b04:	c7 04 24 4c 89 10 80 	movl   $0x8010894c,(%esp)
80104b0b:	e8 2a ba ff ff       	call   8010053a <panic>
  if(cpu->ncli != 1)
80104b10:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b16:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104b1c:	83 f8 01             	cmp    $0x1,%eax
80104b1f:	74 0c                	je     80104b2d <sched+0x3f>
    panic("sched locks");
80104b21:	c7 04 24 5e 89 10 80 	movl   $0x8010895e,(%esp)
80104b28:	e8 0d ba ff ff       	call   8010053a <panic>
  if(proc->state == RUNNING)
80104b2d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b33:	8b 40 0c             	mov    0xc(%eax),%eax
80104b36:	83 f8 04             	cmp    $0x4,%eax
80104b39:	75 0c                	jne    80104b47 <sched+0x59>
    panic("sched running");
80104b3b:	c7 04 24 6a 89 10 80 	movl   $0x8010896a,(%esp)
80104b42:	e8 f3 b9 ff ff       	call   8010053a <panic>
  if(readeflags()&FL_IF)
80104b47:	e8 c1 f7 ff ff       	call   8010430d <readeflags>
80104b4c:	25 00 02 00 00       	and    $0x200,%eax
80104b51:	85 c0                	test   %eax,%eax
80104b53:	74 0c                	je     80104b61 <sched+0x73>
    panic("sched interruptible");
80104b55:	c7 04 24 78 89 10 80 	movl   $0x80108978,(%esp)
80104b5c:	e8 d9 b9 ff ff       	call   8010053a <panic>
  intena = cpu->intena;
80104b61:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b67:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104b6d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104b70:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b76:	8b 40 04             	mov    0x4(%eax),%eax
80104b79:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104b80:	83 c2 1c             	add    $0x1c,%edx
80104b83:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b87:	89 14 24             	mov    %edx,(%esp)
80104b8a:	e8 4f 09 00 00       	call   801054de <swtch>
  cpu->intena = intena;
80104b8f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104b95:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104b98:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104b9e:	c9                   	leave  
80104b9f:	c3                   	ret    

80104ba0 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104ba0:	55                   	push   %ebp
80104ba1:	89 e5                	mov    %esp,%ebp
80104ba3:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104ba6:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104bad:	e8 47 04 00 00       	call   80104ff9 <acquire>
  proc->state = RUNNABLE;
80104bb2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bb8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104bbf:	e8 2a ff ff ff       	call   80104aee <sched>
  release(&ptable.lock);
80104bc4:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104bcb:	e8 8b 04 00 00       	call   8010505b <release>
}
80104bd0:	c9                   	leave  
80104bd1:	c3                   	ret    

80104bd2 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104bd2:	55                   	push   %ebp
80104bd3:	89 e5                	mov    %esp,%ebp
80104bd5:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104bd8:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104bdf:	e8 77 04 00 00       	call   8010505b <release>

  if (first) {
80104be4:	a1 08 b0 10 80       	mov    0x8010b008,%eax
80104be9:	85 c0                	test   %eax,%eax
80104beb:	74 0f                	je     80104bfc <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104bed:	c7 05 08 b0 10 80 00 	movl   $0x0,0x8010b008
80104bf4:	00 00 00 
    initlog();
80104bf7:	e8 3d e6 ff ff       	call   80103239 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104bfc:	c9                   	leave  
80104bfd:	c3                   	ret    

80104bfe <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104bfe:	55                   	push   %ebp
80104bff:	89 e5                	mov    %esp,%ebp
80104c01:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104c04:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c0a:	85 c0                	test   %eax,%eax
80104c0c:	75 0c                	jne    80104c1a <sleep+0x1c>
    panic("sleep");
80104c0e:	c7 04 24 8c 89 10 80 	movl   $0x8010898c,(%esp)
80104c15:	e8 20 b9 ff ff       	call   8010053a <panic>

  if(lk == 0)
80104c1a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104c1e:	75 0c                	jne    80104c2c <sleep+0x2e>
    panic("sleep without lk");
80104c20:	c7 04 24 92 89 10 80 	movl   $0x80108992,(%esp)
80104c27:	e8 0e b9 ff ff       	call   8010053a <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104c2c:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104c33:	74 17                	je     80104c4c <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104c35:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c3c:	e8 b8 03 00 00       	call   80104ff9 <acquire>
    release(lk);
80104c41:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c44:	89 04 24             	mov    %eax,(%esp)
80104c47:	e8 0f 04 00 00       	call   8010505b <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104c4c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c52:	8b 55 08             	mov    0x8(%ebp),%edx
80104c55:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104c58:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c5e:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104c65:	e8 84 fe ff ff       	call   80104aee <sched>

  // Tidy up.
  proc->chan = 0;
80104c6a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c70:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104c77:	81 7d 0c 60 29 11 80 	cmpl   $0x80112960,0xc(%ebp)
80104c7e:	74 17                	je     80104c97 <sleep+0x99>
    release(&ptable.lock);
80104c80:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104c87:	e8 cf 03 00 00       	call   8010505b <release>
    acquire(lk);
80104c8c:	8b 45 0c             	mov    0xc(%ebp),%eax
80104c8f:	89 04 24             	mov    %eax,(%esp)
80104c92:	e8 62 03 00 00       	call   80104ff9 <acquire>
  }
}
80104c97:	c9                   	leave  
80104c98:	c3                   	ret    

80104c99 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104c99:	55                   	push   %ebp
80104c9a:	89 e5                	mov    %esp,%ebp
80104c9c:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c9f:	c7 45 fc 94 29 11 80 	movl   $0x80112994,-0x4(%ebp)
80104ca6:	eb 27                	jmp    80104ccf <wakeup1+0x36>
    if(p->state == SLEEPING && p->chan == chan)
80104ca8:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104cab:	8b 40 0c             	mov    0xc(%eax),%eax
80104cae:	83 f8 02             	cmp    $0x2,%eax
80104cb1:	75 15                	jne    80104cc8 <wakeup1+0x2f>
80104cb3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104cb6:	8b 40 20             	mov    0x20(%eax),%eax
80104cb9:	3b 45 08             	cmp    0x8(%ebp),%eax
80104cbc:	75 0a                	jne    80104cc8 <wakeup1+0x2f>
      p->state = RUNNABLE;
80104cbe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104cc1:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104cc8:	81 45 fc 84 00 00 00 	addl   $0x84,-0x4(%ebp)
80104ccf:	81 7d fc 94 4a 11 80 	cmpl   $0x80114a94,-0x4(%ebp)
80104cd6:	72 d0                	jb     80104ca8 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104cd8:	c9                   	leave  
80104cd9:	c3                   	ret    

80104cda <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104cda:	55                   	push   %ebp
80104cdb:	89 e5                	mov    %esp,%ebp
80104cdd:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104ce0:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104ce7:	e8 0d 03 00 00       	call   80104ff9 <acquire>
  wakeup1(chan);
80104cec:	8b 45 08             	mov    0x8(%ebp),%eax
80104cef:	89 04 24             	mov    %eax,(%esp)
80104cf2:	e8 a2 ff ff ff       	call   80104c99 <wakeup1>
  release(&ptable.lock);
80104cf7:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104cfe:	e8 58 03 00 00       	call   8010505b <release>
}
80104d03:	c9                   	leave  
80104d04:	c3                   	ret    

80104d05 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104d05:	55                   	push   %ebp
80104d06:	89 e5                	mov    %esp,%ebp
80104d08:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104d0b:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d12:	e8 e2 02 00 00       	call   80104ff9 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d17:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104d1e:	eb 44                	jmp    80104d64 <kill+0x5f>
    if(p->pid == pid){
80104d20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d23:	8b 40 10             	mov    0x10(%eax),%eax
80104d26:	3b 45 08             	cmp    0x8(%ebp),%eax
80104d29:	75 32                	jne    80104d5d <kill+0x58>
      p->killed = 1;
80104d2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d2e:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104d35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d38:	8b 40 0c             	mov    0xc(%eax),%eax
80104d3b:	83 f8 02             	cmp    $0x2,%eax
80104d3e:	75 0a                	jne    80104d4a <kill+0x45>
        p->state = RUNNABLE;
80104d40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d43:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104d4a:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d51:	e8 05 03 00 00       	call   8010505b <release>
      return 0;
80104d56:	b8 00 00 00 00       	mov    $0x0,%eax
80104d5b:	eb 21                	jmp    80104d7e <kill+0x79>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d5d:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
80104d64:	81 7d f4 94 4a 11 80 	cmpl   $0x80114a94,-0xc(%ebp)
80104d6b:	72 b3                	jb     80104d20 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104d6d:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104d74:	e8 e2 02 00 00       	call   8010505b <release>
  return -1;
80104d79:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104d7e:	c9                   	leave  
80104d7f:	c3                   	ret    

80104d80 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104d80:	55                   	push   %ebp
80104d81:	89 e5                	mov    %esp,%ebp
80104d83:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104d86:	c7 45 f0 94 29 11 80 	movl   $0x80112994,-0x10(%ebp)
80104d8d:	e9 d9 00 00 00       	jmp    80104e6b <procdump+0xeb>
    if(p->state == UNUSED)
80104d92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d95:	8b 40 0c             	mov    0xc(%eax),%eax
80104d98:	85 c0                	test   %eax,%eax
80104d9a:	75 05                	jne    80104da1 <procdump+0x21>
      continue;
80104d9c:	e9 c3 00 00 00       	jmp    80104e64 <procdump+0xe4>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104da1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104da4:	8b 40 0c             	mov    0xc(%eax),%eax
80104da7:	83 f8 05             	cmp    $0x5,%eax
80104daa:	77 23                	ja     80104dcf <procdump+0x4f>
80104dac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104daf:	8b 40 0c             	mov    0xc(%eax),%eax
80104db2:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104db9:	85 c0                	test   %eax,%eax
80104dbb:	74 12                	je     80104dcf <procdump+0x4f>
      state = states[p->state];
80104dbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dc0:	8b 40 0c             	mov    0xc(%eax),%eax
80104dc3:	8b 04 85 0c b0 10 80 	mov    -0x7fef4ff4(,%eax,4),%eax
80104dca:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104dcd:	eb 07                	jmp    80104dd6 <procdump+0x56>
    else
      state = "???";
80104dcf:	c7 45 ec a3 89 10 80 	movl   $0x801089a3,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104dd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104dd9:	8d 50 6c             	lea    0x6c(%eax),%edx
80104ddc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ddf:	8b 40 10             	mov    0x10(%eax),%eax
80104de2:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104de6:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104de9:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ded:	89 44 24 04          	mov    %eax,0x4(%esp)
80104df1:	c7 04 24 a7 89 10 80 	movl   $0x801089a7,(%esp)
80104df8:	e8 a3 b5 ff ff       	call   801003a0 <cprintf>
    if(p->state == SLEEPING){
80104dfd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e00:	8b 40 0c             	mov    0xc(%eax),%eax
80104e03:	83 f8 02             	cmp    $0x2,%eax
80104e06:	75 50                	jne    80104e58 <procdump+0xd8>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104e08:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104e0b:	8b 40 1c             	mov    0x1c(%eax),%eax
80104e0e:	8b 40 0c             	mov    0xc(%eax),%eax
80104e11:	83 c0 08             	add    $0x8,%eax
80104e14:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104e17:	89 54 24 04          	mov    %edx,0x4(%esp)
80104e1b:	89 04 24             	mov    %eax,(%esp)
80104e1e:	e8 87 02 00 00       	call   801050aa <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104e23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104e2a:	eb 1b                	jmp    80104e47 <procdump+0xc7>
        cprintf(" %p", pc[i]);
80104e2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e2f:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104e33:	89 44 24 04          	mov    %eax,0x4(%esp)
80104e37:	c7 04 24 b0 89 10 80 	movl   $0x801089b0,(%esp)
80104e3e:	e8 5d b5 ff ff       	call   801003a0 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104e43:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104e47:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104e4b:	7f 0b                	jg     80104e58 <procdump+0xd8>
80104e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104e50:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104e54:	85 c0                	test   %eax,%eax
80104e56:	75 d4                	jne    80104e2c <procdump+0xac>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104e58:	c7 04 24 b4 89 10 80 	movl   $0x801089b4,(%esp)
80104e5f:	e8 3c b5 ff ff       	call   801003a0 <cprintf>
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e64:	81 45 f0 84 00 00 00 	addl   $0x84,-0x10(%ebp)
80104e6b:	81 7d f0 94 4a 11 80 	cmpl   $0x80114a94,-0x10(%ebp)
80104e72:	0f 82 1a ff ff ff    	jb     80104d92 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104e78:	c9                   	leave  
80104e79:	c3                   	ret    

80104e7a <cps>:



int
cps()
{
80104e7a:	55                   	push   %ebp
80104e7b:	89 e5                	mov    %esp,%ebp
80104e7d:	53                   	push   %ebx
80104e7e:	83 ec 34             	sub    $0x34,%esp
    struct proc *p;

    // Enable interrupts on this processor.
    sti();
80104e81:	e8 97 f4 ff ff       	call   8010431d <sti>

    // Loop over process table looking for process with pid.
    acquire(&ptable.lock);
80104e86:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104e8d:	e8 67 01 00 00       	call   80104ff9 <acquire>
    cprintf("name          pid        state     \n");
80104e92:	c7 04 24 b8 89 10 80 	movl   $0x801089b8,(%esp)
80104e99:	e8 02 b5 ff ff       	call   801003a0 <cprintf>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104e9e:	c7 45 f4 94 29 11 80 	movl   $0x80112994,-0xc(%ebp)
80104ea5:	e9 d4 00 00 00       	jmp    80104f7e <cps+0x104>
    {
        if(p->state == SLEEPING)
80104eaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ead:	8b 40 0c             	mov    0xc(%eax),%eax
80104eb0:	83 f8 02             	cmp    $0x2,%eax
80104eb3:	75 3c                	jne    80104ef1 <cps+0x77>
            cprintf("%s         %d       SLEEPING   %d  %d  \n", p->name, p->pid,p->passada,p->passo);
80104eb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eb8:	8b 48 7c             	mov    0x7c(%eax),%ecx
80104ebb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ebe:	8b 90 80 00 00 00    	mov    0x80(%eax),%edx
80104ec4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ec7:	8b 40 10             	mov    0x10(%eax),%eax
80104eca:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80104ecd:	83 c3 6c             	add    $0x6c,%ebx
80104ed0:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80104ed4:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104ed8:	89 44 24 08          	mov    %eax,0x8(%esp)
80104edc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80104ee0:	c7 04 24 e0 89 10 80 	movl   $0x801089e0,(%esp)
80104ee7:	e8 b4 b4 ff ff       	call   801003a0 <cprintf>
80104eec:	e9 86 00 00 00       	jmp    80104f77 <cps+0xfd>
        else if(p->state == RUNNING)
80104ef1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ef4:	8b 40 0c             	mov    0xc(%eax),%eax
80104ef7:	83 f8 04             	cmp    $0x4,%eax
80104efa:	75 39                	jne    80104f35 <cps+0xbb>
            cprintf("%s         %d       RUNNING    %d  %d  \n", p->name, p->pid,p->passada,p->passo);
80104efc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104eff:	8b 48 7c             	mov    0x7c(%eax),%ecx
80104f02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f05:	8b 90 80 00 00 00    	mov    0x80(%eax),%edx
80104f0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f0e:	8b 40 10             	mov    0x10(%eax),%eax
80104f11:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80104f14:	83 c3 6c             	add    $0x6c,%ebx
80104f17:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80104f1b:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104f1f:	89 44 24 08          	mov    %eax,0x8(%esp)
80104f23:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80104f27:	c7 04 24 0c 8a 10 80 	movl   $0x80108a0c,(%esp)
80104f2e:	e8 6d b4 ff ff       	call   801003a0 <cprintf>
80104f33:	eb 42                	jmp    80104f77 <cps+0xfd>
        else if(p->state == RUNNABLE)
80104f35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f38:	8b 40 0c             	mov    0xc(%eax),%eax
80104f3b:	83 f8 03             	cmp    $0x3,%eax
80104f3e:	75 37                	jne    80104f77 <cps+0xfd>
            cprintf("%s         %d       RUNNABLE   %d  %d  \n", p->name, p->pid,p->passada,p->passo);
80104f40:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f43:	8b 48 7c             	mov    0x7c(%eax),%ecx
80104f46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f49:	8b 90 80 00 00 00    	mov    0x80(%eax),%edx
80104f4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104f52:	8b 40 10             	mov    0x10(%eax),%eax
80104f55:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80104f58:	83 c3 6c             	add    $0x6c,%ebx
80104f5b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80104f5f:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104f63:	89 44 24 08          	mov    %eax,0x8(%esp)
80104f67:	89 5c 24 04          	mov    %ebx,0x4(%esp)
80104f6b:	c7 04 24 38 8a 10 80 	movl   $0x80108a38,(%esp)
80104f72:	e8 29 b4 ff ff       	call   801003a0 <cprintf>
    sti();

    // Loop over process table looking for process with pid.
    acquire(&ptable.lock);
    cprintf("name          pid        state     \n");
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104f77:	81 45 f4 84 00 00 00 	addl   $0x84,-0xc(%ebp)
80104f7e:	81 7d f4 94 4a 11 80 	cmpl   $0x80114a94,-0xc(%ebp)
80104f85:	0f 82 1f ff ff ff    	jb     80104eaa <cps+0x30>
            cprintf("%s         %d       RUNNING    %d  %d  \n", p->name, p->pid,p->passada,p->passo);
        else if(p->state == RUNNABLE)
            cprintf("%s         %d       RUNNABLE   %d  %d  \n", p->name, p->pid,p->passada,p->passo);
    }

    release(&ptable.lock);
80104f8b:	c7 04 24 60 29 11 80 	movl   $0x80112960,(%esp)
80104f92:	e8 c4 00 00 00       	call   8010505b <release>

    return 22;
80104f97:	b8 16 00 00 00       	mov    $0x16,%eax
}
80104f9c:	83 c4 34             	add    $0x34,%esp
80104f9f:	5b                   	pop    %ebx
80104fa0:	5d                   	pop    %ebp
80104fa1:	c3                   	ret    

80104fa2 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104fa2:	55                   	push   %ebp
80104fa3:	89 e5                	mov    %esp,%ebp
80104fa5:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104fa8:	9c                   	pushf  
80104fa9:	58                   	pop    %eax
80104faa:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104fad:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104fb0:	c9                   	leave  
80104fb1:	c3                   	ret    

80104fb2 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104fb2:	55                   	push   %ebp
80104fb3:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104fb5:	fa                   	cli    
}
80104fb6:	5d                   	pop    %ebp
80104fb7:	c3                   	ret    

80104fb8 <sti>:

static inline void
sti(void)
{
80104fb8:	55                   	push   %ebp
80104fb9:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104fbb:	fb                   	sti    
}
80104fbc:	5d                   	pop    %ebp
80104fbd:	c3                   	ret    

80104fbe <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104fbe:	55                   	push   %ebp
80104fbf:	89 e5                	mov    %esp,%ebp
80104fc1:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104fc4:	8b 55 08             	mov    0x8(%ebp),%edx
80104fc7:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fca:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104fcd:	f0 87 02             	lock xchg %eax,(%edx)
80104fd0:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104fd3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104fd6:	c9                   	leave  
80104fd7:	c3                   	ret    

80104fd8 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104fd8:	55                   	push   %ebp
80104fd9:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104fdb:	8b 45 08             	mov    0x8(%ebp),%eax
80104fde:	8b 55 0c             	mov    0xc(%ebp),%edx
80104fe1:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104fe4:	8b 45 08             	mov    0x8(%ebp),%eax
80104fe7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104fed:	8b 45 08             	mov    0x8(%ebp),%eax
80104ff0:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104ff7:	5d                   	pop    %ebp
80104ff8:	c3                   	ret    

80104ff9 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104ff9:	55                   	push   %ebp
80104ffa:	89 e5                	mov    %esp,%ebp
80104ffc:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104fff:	e8 49 01 00 00       	call   8010514d <pushcli>
  if(holding(lk))
80105004:	8b 45 08             	mov    0x8(%ebp),%eax
80105007:	89 04 24             	mov    %eax,(%esp)
8010500a:	e8 14 01 00 00       	call   80105123 <holding>
8010500f:	85 c0                	test   %eax,%eax
80105011:	74 0c                	je     8010501f <acquire+0x26>
    panic("acquire");
80105013:	c7 04 24 8b 8a 10 80 	movl   $0x80108a8b,(%esp)
8010501a:	e8 1b b5 ff ff       	call   8010053a <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
8010501f:	90                   	nop
80105020:	8b 45 08             	mov    0x8(%ebp),%eax
80105023:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010502a:	00 
8010502b:	89 04 24             	mov    %eax,(%esp)
8010502e:	e8 8b ff ff ff       	call   80104fbe <xchg>
80105033:	85 c0                	test   %eax,%eax
80105035:	75 e9                	jne    80105020 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105037:	8b 45 08             	mov    0x8(%ebp),%eax
8010503a:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105041:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105044:	8b 45 08             	mov    0x8(%ebp),%eax
80105047:	83 c0 0c             	add    $0xc,%eax
8010504a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010504e:	8d 45 08             	lea    0x8(%ebp),%eax
80105051:	89 04 24             	mov    %eax,(%esp)
80105054:	e8 51 00 00 00       	call   801050aa <getcallerpcs>
}
80105059:	c9                   	leave  
8010505a:	c3                   	ret    

8010505b <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
8010505b:	55                   	push   %ebp
8010505c:	89 e5                	mov    %esp,%ebp
8010505e:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105061:	8b 45 08             	mov    0x8(%ebp),%eax
80105064:	89 04 24             	mov    %eax,(%esp)
80105067:	e8 b7 00 00 00       	call   80105123 <holding>
8010506c:	85 c0                	test   %eax,%eax
8010506e:	75 0c                	jne    8010507c <release+0x21>
    panic("release");
80105070:	c7 04 24 93 8a 10 80 	movl   $0x80108a93,(%esp)
80105077:	e8 be b4 ff ff       	call   8010053a <panic>

  lk->pcs[0] = 0;
8010507c:	8b 45 08             	mov    0x8(%ebp),%eax
8010507f:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80105086:	8b 45 08             	mov    0x8(%ebp),%eax
80105089:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80105090:	8b 45 08             	mov    0x8(%ebp),%eax
80105093:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010509a:	00 
8010509b:	89 04 24             	mov    %eax,(%esp)
8010509e:	e8 1b ff ff ff       	call   80104fbe <xchg>

  popcli();
801050a3:	e8 e9 00 00 00       	call   80105191 <popcli>
}
801050a8:	c9                   	leave  
801050a9:	c3                   	ret    

801050aa <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
801050aa:	55                   	push   %ebp
801050ab:	89 e5                	mov    %esp,%ebp
801050ad:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801050b0:	8b 45 08             	mov    0x8(%ebp),%eax
801050b3:	83 e8 08             	sub    $0x8,%eax
801050b6:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801050b9:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801050c0:	eb 38                	jmp    801050fa <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
801050c2:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
801050c6:	74 38                	je     80105100 <getcallerpcs+0x56>
801050c8:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
801050cf:	76 2f                	jbe    80105100 <getcallerpcs+0x56>
801050d1:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
801050d5:	74 29                	je     80105100 <getcallerpcs+0x56>
      break;
    pcs[i] = ebp[1];     // saved %eip
801050d7:	8b 45 f8             	mov    -0x8(%ebp),%eax
801050da:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801050e1:	8b 45 0c             	mov    0xc(%ebp),%eax
801050e4:	01 c2                	add    %eax,%edx
801050e6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050e9:	8b 40 04             	mov    0x4(%eax),%eax
801050ec:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
801050ee:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050f1:	8b 00                	mov    (%eax),%eax
801050f3:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
801050f6:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801050fa:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
801050fe:	7e c2                	jle    801050c2 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105100:	eb 19                	jmp    8010511b <getcallerpcs+0x71>
    pcs[i] = 0;
80105102:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105105:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010510c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010510f:	01 d0                	add    %edx,%eax
80105111:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105117:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
8010511b:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010511f:	7e e1                	jle    80105102 <getcallerpcs+0x58>
    pcs[i] = 0;
}
80105121:	c9                   	leave  
80105122:	c3                   	ret    

80105123 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105123:	55                   	push   %ebp
80105124:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80105126:	8b 45 08             	mov    0x8(%ebp),%eax
80105129:	8b 00                	mov    (%eax),%eax
8010512b:	85 c0                	test   %eax,%eax
8010512d:	74 17                	je     80105146 <holding+0x23>
8010512f:	8b 45 08             	mov    0x8(%ebp),%eax
80105132:	8b 50 08             	mov    0x8(%eax),%edx
80105135:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010513b:	39 c2                	cmp    %eax,%edx
8010513d:	75 07                	jne    80105146 <holding+0x23>
8010513f:	b8 01 00 00 00       	mov    $0x1,%eax
80105144:	eb 05                	jmp    8010514b <holding+0x28>
80105146:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010514b:	5d                   	pop    %ebp
8010514c:	c3                   	ret    

8010514d <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
8010514d:	55                   	push   %ebp
8010514e:	89 e5                	mov    %esp,%ebp
80105150:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105153:	e8 4a fe ff ff       	call   80104fa2 <readeflags>
80105158:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
8010515b:	e8 52 fe ff ff       	call   80104fb2 <cli>
  if(cpu->ncli++ == 0)
80105160:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105167:	8b 82 ac 00 00 00    	mov    0xac(%edx),%eax
8010516d:	8d 48 01             	lea    0x1(%eax),%ecx
80105170:	89 8a ac 00 00 00    	mov    %ecx,0xac(%edx)
80105176:	85 c0                	test   %eax,%eax
80105178:	75 15                	jne    8010518f <pushcli+0x42>
    cpu->intena = eflags & FL_IF;
8010517a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105180:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105183:	81 e2 00 02 00 00    	and    $0x200,%edx
80105189:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010518f:	c9                   	leave  
80105190:	c3                   	ret    

80105191 <popcli>:

void
popcli(void)
{
80105191:	55                   	push   %ebp
80105192:	89 e5                	mov    %esp,%ebp
80105194:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80105197:	e8 06 fe ff ff       	call   80104fa2 <readeflags>
8010519c:	25 00 02 00 00       	and    $0x200,%eax
801051a1:	85 c0                	test   %eax,%eax
801051a3:	74 0c                	je     801051b1 <popcli+0x20>
    panic("popcli - interruptible");
801051a5:	c7 04 24 9b 8a 10 80 	movl   $0x80108a9b,(%esp)
801051ac:	e8 89 b3 ff ff       	call   8010053a <panic>
  if(--cpu->ncli < 0)
801051b1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801051b7:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801051bd:	83 ea 01             	sub    $0x1,%edx
801051c0:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801051c6:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801051cc:	85 c0                	test   %eax,%eax
801051ce:	79 0c                	jns    801051dc <popcli+0x4b>
    panic("popcli");
801051d0:	c7 04 24 b2 8a 10 80 	movl   $0x80108ab2,(%esp)
801051d7:	e8 5e b3 ff ff       	call   8010053a <panic>
  if(cpu->ncli == 0 && cpu->intena)
801051dc:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801051e2:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801051e8:	85 c0                	test   %eax,%eax
801051ea:	75 15                	jne    80105201 <popcli+0x70>
801051ec:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801051f2:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801051f8:	85 c0                	test   %eax,%eax
801051fa:	74 05                	je     80105201 <popcli+0x70>
    sti();
801051fc:	e8 b7 fd ff ff       	call   80104fb8 <sti>
}
80105201:	c9                   	leave  
80105202:	c3                   	ret    

80105203 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105203:	55                   	push   %ebp
80105204:	89 e5                	mov    %esp,%ebp
80105206:	57                   	push   %edi
80105207:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105208:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010520b:	8b 55 10             	mov    0x10(%ebp),%edx
8010520e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105211:	89 cb                	mov    %ecx,%ebx
80105213:	89 df                	mov    %ebx,%edi
80105215:	89 d1                	mov    %edx,%ecx
80105217:	fc                   	cld    
80105218:	f3 aa                	rep stos %al,%es:(%edi)
8010521a:	89 ca                	mov    %ecx,%edx
8010521c:	89 fb                	mov    %edi,%ebx
8010521e:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105221:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105224:	5b                   	pop    %ebx
80105225:	5f                   	pop    %edi
80105226:	5d                   	pop    %ebp
80105227:	c3                   	ret    

80105228 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105228:	55                   	push   %ebp
80105229:	89 e5                	mov    %esp,%ebp
8010522b:	57                   	push   %edi
8010522c:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010522d:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105230:	8b 55 10             	mov    0x10(%ebp),%edx
80105233:	8b 45 0c             	mov    0xc(%ebp),%eax
80105236:	89 cb                	mov    %ecx,%ebx
80105238:	89 df                	mov    %ebx,%edi
8010523a:	89 d1                	mov    %edx,%ecx
8010523c:	fc                   	cld    
8010523d:	f3 ab                	rep stos %eax,%es:(%edi)
8010523f:	89 ca                	mov    %ecx,%edx
80105241:	89 fb                	mov    %edi,%ebx
80105243:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105246:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105249:	5b                   	pop    %ebx
8010524a:	5f                   	pop    %edi
8010524b:	5d                   	pop    %ebp
8010524c:	c3                   	ret    

8010524d <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010524d:	55                   	push   %ebp
8010524e:	89 e5                	mov    %esp,%ebp
80105250:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105253:	8b 45 08             	mov    0x8(%ebp),%eax
80105256:	83 e0 03             	and    $0x3,%eax
80105259:	85 c0                	test   %eax,%eax
8010525b:	75 49                	jne    801052a6 <memset+0x59>
8010525d:	8b 45 10             	mov    0x10(%ebp),%eax
80105260:	83 e0 03             	and    $0x3,%eax
80105263:	85 c0                	test   %eax,%eax
80105265:	75 3f                	jne    801052a6 <memset+0x59>
    c &= 0xFF;
80105267:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010526e:	8b 45 10             	mov    0x10(%ebp),%eax
80105271:	c1 e8 02             	shr    $0x2,%eax
80105274:	89 c2                	mov    %eax,%edx
80105276:	8b 45 0c             	mov    0xc(%ebp),%eax
80105279:	c1 e0 18             	shl    $0x18,%eax
8010527c:	89 c1                	mov    %eax,%ecx
8010527e:	8b 45 0c             	mov    0xc(%ebp),%eax
80105281:	c1 e0 10             	shl    $0x10,%eax
80105284:	09 c1                	or     %eax,%ecx
80105286:	8b 45 0c             	mov    0xc(%ebp),%eax
80105289:	c1 e0 08             	shl    $0x8,%eax
8010528c:	09 c8                	or     %ecx,%eax
8010528e:	0b 45 0c             	or     0xc(%ebp),%eax
80105291:	89 54 24 08          	mov    %edx,0x8(%esp)
80105295:	89 44 24 04          	mov    %eax,0x4(%esp)
80105299:	8b 45 08             	mov    0x8(%ebp),%eax
8010529c:	89 04 24             	mov    %eax,(%esp)
8010529f:	e8 84 ff ff ff       	call   80105228 <stosl>
801052a4:	eb 19                	jmp    801052bf <memset+0x72>
  } else
    stosb(dst, c, n);
801052a6:	8b 45 10             	mov    0x10(%ebp),%eax
801052a9:	89 44 24 08          	mov    %eax,0x8(%esp)
801052ad:	8b 45 0c             	mov    0xc(%ebp),%eax
801052b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801052b4:	8b 45 08             	mov    0x8(%ebp),%eax
801052b7:	89 04 24             	mov    %eax,(%esp)
801052ba:	e8 44 ff ff ff       	call   80105203 <stosb>
  return dst;
801052bf:	8b 45 08             	mov    0x8(%ebp),%eax
}
801052c2:	c9                   	leave  
801052c3:	c3                   	ret    

801052c4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801052c4:	55                   	push   %ebp
801052c5:	89 e5                	mov    %esp,%ebp
801052c7:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801052ca:	8b 45 08             	mov    0x8(%ebp),%eax
801052cd:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801052d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801052d3:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801052d6:	eb 30                	jmp    80105308 <memcmp+0x44>
    if(*s1 != *s2)
801052d8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052db:	0f b6 10             	movzbl (%eax),%edx
801052de:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052e1:	0f b6 00             	movzbl (%eax),%eax
801052e4:	38 c2                	cmp    %al,%dl
801052e6:	74 18                	je     80105300 <memcmp+0x3c>
      return *s1 - *s2;
801052e8:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052eb:	0f b6 00             	movzbl (%eax),%eax
801052ee:	0f b6 d0             	movzbl %al,%edx
801052f1:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052f4:	0f b6 00             	movzbl (%eax),%eax
801052f7:	0f b6 c0             	movzbl %al,%eax
801052fa:	29 c2                	sub    %eax,%edx
801052fc:	89 d0                	mov    %edx,%eax
801052fe:	eb 1a                	jmp    8010531a <memcmp+0x56>
    s1++, s2++;
80105300:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105304:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105308:	8b 45 10             	mov    0x10(%ebp),%eax
8010530b:	8d 50 ff             	lea    -0x1(%eax),%edx
8010530e:	89 55 10             	mov    %edx,0x10(%ebp)
80105311:	85 c0                	test   %eax,%eax
80105313:	75 c3                	jne    801052d8 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105315:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010531a:	c9                   	leave  
8010531b:	c3                   	ret    

8010531c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010531c:	55                   	push   %ebp
8010531d:	89 e5                	mov    %esp,%ebp
8010531f:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105322:	8b 45 0c             	mov    0xc(%ebp),%eax
80105325:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105328:	8b 45 08             	mov    0x8(%ebp),%eax
8010532b:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010532e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105331:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105334:	73 3d                	jae    80105373 <memmove+0x57>
80105336:	8b 45 10             	mov    0x10(%ebp),%eax
80105339:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010533c:	01 d0                	add    %edx,%eax
8010533e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105341:	76 30                	jbe    80105373 <memmove+0x57>
    s += n;
80105343:	8b 45 10             	mov    0x10(%ebp),%eax
80105346:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80105349:	8b 45 10             	mov    0x10(%ebp),%eax
8010534c:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
8010534f:	eb 13                	jmp    80105364 <memmove+0x48>
      *--d = *--s;
80105351:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105355:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80105359:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010535c:	0f b6 10             	movzbl (%eax),%edx
8010535f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105362:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105364:	8b 45 10             	mov    0x10(%ebp),%eax
80105367:	8d 50 ff             	lea    -0x1(%eax),%edx
8010536a:	89 55 10             	mov    %edx,0x10(%ebp)
8010536d:	85 c0                	test   %eax,%eax
8010536f:	75 e0                	jne    80105351 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105371:	eb 26                	jmp    80105399 <memmove+0x7d>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80105373:	eb 17                	jmp    8010538c <memmove+0x70>
      *d++ = *s++;
80105375:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105378:	8d 50 01             	lea    0x1(%eax),%edx
8010537b:	89 55 f8             	mov    %edx,-0x8(%ebp)
8010537e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105381:	8d 4a 01             	lea    0x1(%edx),%ecx
80105384:	89 4d fc             	mov    %ecx,-0x4(%ebp)
80105387:	0f b6 12             	movzbl (%edx),%edx
8010538a:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
8010538c:	8b 45 10             	mov    0x10(%ebp),%eax
8010538f:	8d 50 ff             	lea    -0x1(%eax),%edx
80105392:	89 55 10             	mov    %edx,0x10(%ebp)
80105395:	85 c0                	test   %eax,%eax
80105397:	75 dc                	jne    80105375 <memmove+0x59>
      *d++ = *s++;

  return dst;
80105399:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010539c:	c9                   	leave  
8010539d:	c3                   	ret    

8010539e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
8010539e:	55                   	push   %ebp
8010539f:	89 e5                	mov    %esp,%ebp
801053a1:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801053a4:	8b 45 10             	mov    0x10(%ebp),%eax
801053a7:	89 44 24 08          	mov    %eax,0x8(%esp)
801053ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801053ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801053b2:	8b 45 08             	mov    0x8(%ebp),%eax
801053b5:	89 04 24             	mov    %eax,(%esp)
801053b8:	e8 5f ff ff ff       	call   8010531c <memmove>
}
801053bd:	c9                   	leave  
801053be:	c3                   	ret    

801053bf <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801053bf:	55                   	push   %ebp
801053c0:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801053c2:	eb 0c                	jmp    801053d0 <strncmp+0x11>
    n--, p++, q++;
801053c4:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801053c8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801053cc:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801053d0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053d4:	74 1a                	je     801053f0 <strncmp+0x31>
801053d6:	8b 45 08             	mov    0x8(%ebp),%eax
801053d9:	0f b6 00             	movzbl (%eax),%eax
801053dc:	84 c0                	test   %al,%al
801053de:	74 10                	je     801053f0 <strncmp+0x31>
801053e0:	8b 45 08             	mov    0x8(%ebp),%eax
801053e3:	0f b6 10             	movzbl (%eax),%edx
801053e6:	8b 45 0c             	mov    0xc(%ebp),%eax
801053e9:	0f b6 00             	movzbl (%eax),%eax
801053ec:	38 c2                	cmp    %al,%dl
801053ee:	74 d4                	je     801053c4 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
801053f0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053f4:	75 07                	jne    801053fd <strncmp+0x3e>
    return 0;
801053f6:	b8 00 00 00 00       	mov    $0x0,%eax
801053fb:	eb 16                	jmp    80105413 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
801053fd:	8b 45 08             	mov    0x8(%ebp),%eax
80105400:	0f b6 00             	movzbl (%eax),%eax
80105403:	0f b6 d0             	movzbl %al,%edx
80105406:	8b 45 0c             	mov    0xc(%ebp),%eax
80105409:	0f b6 00             	movzbl (%eax),%eax
8010540c:	0f b6 c0             	movzbl %al,%eax
8010540f:	29 c2                	sub    %eax,%edx
80105411:	89 d0                	mov    %edx,%eax
}
80105413:	5d                   	pop    %ebp
80105414:	c3                   	ret    

80105415 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105415:	55                   	push   %ebp
80105416:	89 e5                	mov    %esp,%ebp
80105418:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010541b:	8b 45 08             	mov    0x8(%ebp),%eax
8010541e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105421:	90                   	nop
80105422:	8b 45 10             	mov    0x10(%ebp),%eax
80105425:	8d 50 ff             	lea    -0x1(%eax),%edx
80105428:	89 55 10             	mov    %edx,0x10(%ebp)
8010542b:	85 c0                	test   %eax,%eax
8010542d:	7e 1e                	jle    8010544d <strncpy+0x38>
8010542f:	8b 45 08             	mov    0x8(%ebp),%eax
80105432:	8d 50 01             	lea    0x1(%eax),%edx
80105435:	89 55 08             	mov    %edx,0x8(%ebp)
80105438:	8b 55 0c             	mov    0xc(%ebp),%edx
8010543b:	8d 4a 01             	lea    0x1(%edx),%ecx
8010543e:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105441:	0f b6 12             	movzbl (%edx),%edx
80105444:	88 10                	mov    %dl,(%eax)
80105446:	0f b6 00             	movzbl (%eax),%eax
80105449:	84 c0                	test   %al,%al
8010544b:	75 d5                	jne    80105422 <strncpy+0xd>
    ;
  while(n-- > 0)
8010544d:	eb 0c                	jmp    8010545b <strncpy+0x46>
    *s++ = 0;
8010544f:	8b 45 08             	mov    0x8(%ebp),%eax
80105452:	8d 50 01             	lea    0x1(%eax),%edx
80105455:	89 55 08             	mov    %edx,0x8(%ebp)
80105458:	c6 00 00             	movb   $0x0,(%eax)
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
8010545b:	8b 45 10             	mov    0x10(%ebp),%eax
8010545e:	8d 50 ff             	lea    -0x1(%eax),%edx
80105461:	89 55 10             	mov    %edx,0x10(%ebp)
80105464:	85 c0                	test   %eax,%eax
80105466:	7f e7                	jg     8010544f <strncpy+0x3a>
    *s++ = 0;
  return os;
80105468:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010546b:	c9                   	leave  
8010546c:	c3                   	ret    

8010546d <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010546d:	55                   	push   %ebp
8010546e:	89 e5                	mov    %esp,%ebp
80105470:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105473:	8b 45 08             	mov    0x8(%ebp),%eax
80105476:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
80105479:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010547d:	7f 05                	jg     80105484 <safestrcpy+0x17>
    return os;
8010547f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105482:	eb 31                	jmp    801054b5 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
80105484:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105488:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010548c:	7e 1e                	jle    801054ac <safestrcpy+0x3f>
8010548e:	8b 45 08             	mov    0x8(%ebp),%eax
80105491:	8d 50 01             	lea    0x1(%eax),%edx
80105494:	89 55 08             	mov    %edx,0x8(%ebp)
80105497:	8b 55 0c             	mov    0xc(%ebp),%edx
8010549a:	8d 4a 01             	lea    0x1(%edx),%ecx
8010549d:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801054a0:	0f b6 12             	movzbl (%edx),%edx
801054a3:	88 10                	mov    %dl,(%eax)
801054a5:	0f b6 00             	movzbl (%eax),%eax
801054a8:	84 c0                	test   %al,%al
801054aa:	75 d8                	jne    80105484 <safestrcpy+0x17>
    ;
  *s = 0;
801054ac:	8b 45 08             	mov    0x8(%ebp),%eax
801054af:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801054b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801054b5:	c9                   	leave  
801054b6:	c3                   	ret    

801054b7 <strlen>:

int
strlen(const char *s)
{
801054b7:	55                   	push   %ebp
801054b8:	89 e5                	mov    %esp,%ebp
801054ba:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801054bd:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801054c4:	eb 04                	jmp    801054ca <strlen+0x13>
801054c6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801054ca:	8b 55 fc             	mov    -0x4(%ebp),%edx
801054cd:	8b 45 08             	mov    0x8(%ebp),%eax
801054d0:	01 d0                	add    %edx,%eax
801054d2:	0f b6 00             	movzbl (%eax),%eax
801054d5:	84 c0                	test   %al,%al
801054d7:	75 ed                	jne    801054c6 <strlen+0xf>
    ;
  return n;
801054d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801054dc:	c9                   	leave  
801054dd:	c3                   	ret    

801054de <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
801054de:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
801054e2:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
801054e6:	55                   	push   %ebp
  pushl %ebx
801054e7:	53                   	push   %ebx
  pushl %esi
801054e8:	56                   	push   %esi
  pushl %edi
801054e9:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
801054ea:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
801054ec:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
801054ee:	5f                   	pop    %edi
  popl %esi
801054ef:	5e                   	pop    %esi
  popl %ebx
801054f0:	5b                   	pop    %ebx
  popl %ebp
801054f1:	5d                   	pop    %ebp
  ret
801054f2:	c3                   	ret    

801054f3 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
801054f3:	55                   	push   %ebp
801054f4:	89 e5                	mov    %esp,%ebp
  if(addr >= proc->sz || addr+4 > proc->sz)
801054f6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801054fc:	8b 00                	mov    (%eax),%eax
801054fe:	3b 45 08             	cmp    0x8(%ebp),%eax
80105501:	76 12                	jbe    80105515 <fetchint+0x22>
80105503:	8b 45 08             	mov    0x8(%ebp),%eax
80105506:	8d 50 04             	lea    0x4(%eax),%edx
80105509:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010550f:	8b 00                	mov    (%eax),%eax
80105511:	39 c2                	cmp    %eax,%edx
80105513:	76 07                	jbe    8010551c <fetchint+0x29>
    return -1;
80105515:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010551a:	eb 0f                	jmp    8010552b <fetchint+0x38>
  *ip = *(int*)(addr);
8010551c:	8b 45 08             	mov    0x8(%ebp),%eax
8010551f:	8b 10                	mov    (%eax),%edx
80105521:	8b 45 0c             	mov    0xc(%ebp),%eax
80105524:	89 10                	mov    %edx,(%eax)
  return 0;
80105526:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010552b:	5d                   	pop    %ebp
8010552c:	c3                   	ret    

8010552d <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
8010552d:	55                   	push   %ebp
8010552e:	89 e5                	mov    %esp,%ebp
80105530:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= proc->sz)
80105533:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105539:	8b 00                	mov    (%eax),%eax
8010553b:	3b 45 08             	cmp    0x8(%ebp),%eax
8010553e:	77 07                	ja     80105547 <fetchstr+0x1a>
    return -1;
80105540:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105545:	eb 46                	jmp    8010558d <fetchstr+0x60>
  *pp = (char*)addr;
80105547:	8b 55 08             	mov    0x8(%ebp),%edx
8010554a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010554d:	89 10                	mov    %edx,(%eax)
  ep = (char*)proc->sz;
8010554f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105555:	8b 00                	mov    (%eax),%eax
80105557:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
8010555a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010555d:	8b 00                	mov    (%eax),%eax
8010555f:	89 45 fc             	mov    %eax,-0x4(%ebp)
80105562:	eb 1c                	jmp    80105580 <fetchstr+0x53>
    if(*s == 0)
80105564:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105567:	0f b6 00             	movzbl (%eax),%eax
8010556a:	84 c0                	test   %al,%al
8010556c:	75 0e                	jne    8010557c <fetchstr+0x4f>
      return s - *pp;
8010556e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105571:	8b 45 0c             	mov    0xc(%ebp),%eax
80105574:	8b 00                	mov    (%eax),%eax
80105576:	29 c2                	sub    %eax,%edx
80105578:	89 d0                	mov    %edx,%eax
8010557a:	eb 11                	jmp    8010558d <fetchstr+0x60>

  if(addr >= proc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)proc->sz;
  for(s = *pp; s < ep; s++)
8010557c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105580:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105583:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105586:	72 dc                	jb     80105564 <fetchstr+0x37>
    if(*s == 0)
      return s - *pp;
  return -1;
80105588:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010558d:	c9                   	leave  
8010558e:	c3                   	ret    

8010558f <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
8010558f:	55                   	push   %ebp
80105590:	89 e5                	mov    %esp,%ebp
80105592:	83 ec 08             	sub    $0x8,%esp
  return fetchint(proc->tf->esp + 4 + 4*n, ip);
80105595:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010559b:	8b 40 18             	mov    0x18(%eax),%eax
8010559e:	8b 50 44             	mov    0x44(%eax),%edx
801055a1:	8b 45 08             	mov    0x8(%ebp),%eax
801055a4:	c1 e0 02             	shl    $0x2,%eax
801055a7:	01 d0                	add    %edx,%eax
801055a9:	8d 50 04             	lea    0x4(%eax),%edx
801055ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801055af:	89 44 24 04          	mov    %eax,0x4(%esp)
801055b3:	89 14 24             	mov    %edx,(%esp)
801055b6:	e8 38 ff ff ff       	call   801054f3 <fetchint>
}
801055bb:	c9                   	leave  
801055bc:	c3                   	ret    

801055bd <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801055bd:	55                   	push   %ebp
801055be:	89 e5                	mov    %esp,%ebp
801055c0:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801055c3:	8d 45 fc             	lea    -0x4(%ebp),%eax
801055c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801055ca:	8b 45 08             	mov    0x8(%ebp),%eax
801055cd:	89 04 24             	mov    %eax,(%esp)
801055d0:	e8 ba ff ff ff       	call   8010558f <argint>
801055d5:	85 c0                	test   %eax,%eax
801055d7:	79 07                	jns    801055e0 <argptr+0x23>
    return -1;
801055d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055de:	eb 3d                	jmp    8010561d <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
801055e0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055e3:	89 c2                	mov    %eax,%edx
801055e5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055eb:	8b 00                	mov    (%eax),%eax
801055ed:	39 c2                	cmp    %eax,%edx
801055ef:	73 16                	jae    80105607 <argptr+0x4a>
801055f1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801055f4:	89 c2                	mov    %eax,%edx
801055f6:	8b 45 10             	mov    0x10(%ebp),%eax
801055f9:	01 c2                	add    %eax,%edx
801055fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105601:	8b 00                	mov    (%eax),%eax
80105603:	39 c2                	cmp    %eax,%edx
80105605:	76 07                	jbe    8010560e <argptr+0x51>
    return -1;
80105607:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010560c:	eb 0f                	jmp    8010561d <argptr+0x60>
  *pp = (char*)i;
8010560e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105611:	89 c2                	mov    %eax,%edx
80105613:	8b 45 0c             	mov    0xc(%ebp),%eax
80105616:	89 10                	mov    %edx,(%eax)
  return 0;
80105618:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010561d:	c9                   	leave  
8010561e:	c3                   	ret    

8010561f <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010561f:	55                   	push   %ebp
80105620:	89 e5                	mov    %esp,%ebp
80105622:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105625:	8d 45 fc             	lea    -0x4(%ebp),%eax
80105628:	89 44 24 04          	mov    %eax,0x4(%esp)
8010562c:	8b 45 08             	mov    0x8(%ebp),%eax
8010562f:	89 04 24             	mov    %eax,(%esp)
80105632:	e8 58 ff ff ff       	call   8010558f <argint>
80105637:	85 c0                	test   %eax,%eax
80105639:	79 07                	jns    80105642 <argstr+0x23>
    return -1;
8010563b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105640:	eb 12                	jmp    80105654 <argstr+0x35>
  return fetchstr(addr, pp);
80105642:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105645:	8b 55 0c             	mov    0xc(%ebp),%edx
80105648:	89 54 24 04          	mov    %edx,0x4(%esp)
8010564c:	89 04 24             	mov    %eax,(%esp)
8010564f:	e8 d9 fe ff ff       	call   8010552d <fetchstr>
}
80105654:	c9                   	leave  
80105655:	c3                   	ret    

80105656 <syscall>:
[SYS_cps]   sys_cps,
};

void
syscall(void)
{
80105656:	55                   	push   %ebp
80105657:	89 e5                	mov    %esp,%ebp
80105659:	53                   	push   %ebx
8010565a:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010565d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105663:	8b 40 18             	mov    0x18(%eax),%eax
80105666:	8b 40 1c             	mov    0x1c(%eax),%eax
80105669:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
8010566c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105670:	7e 30                	jle    801056a2 <syscall+0x4c>
80105672:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105675:	83 f8 17             	cmp    $0x17,%eax
80105678:	77 28                	ja     801056a2 <syscall+0x4c>
8010567a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010567d:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105684:	85 c0                	test   %eax,%eax
80105686:	74 1a                	je     801056a2 <syscall+0x4c>
    proc->tf->eax = syscalls[num]();
80105688:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010568e:	8b 58 18             	mov    0x18(%eax),%ebx
80105691:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105694:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010569b:	ff d0                	call   *%eax
8010569d:	89 43 1c             	mov    %eax,0x1c(%ebx)
801056a0:	eb 3d                	jmp    801056df <syscall+0x89>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
801056a2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056a8:	8d 48 6c             	lea    0x6c(%eax),%ecx
801056ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax

  num = proc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
801056b1:	8b 40 10             	mov    0x10(%eax),%eax
801056b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056b7:	89 54 24 0c          	mov    %edx,0xc(%esp)
801056bb:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801056bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801056c3:	c7 04 24 b9 8a 10 80 	movl   $0x80108ab9,(%esp)
801056ca:	e8 d1 ac ff ff       	call   801003a0 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
801056cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801056d5:	8b 40 18             	mov    0x18(%eax),%eax
801056d8:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
801056df:	83 c4 24             	add    $0x24,%esp
801056e2:	5b                   	pop    %ebx
801056e3:	5d                   	pop    %ebp
801056e4:	c3                   	ret    

801056e5 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801056e5:	55                   	push   %ebp
801056e6:	89 e5                	mov    %esp,%ebp
801056e8:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801056eb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801056ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801056f2:	8b 45 08             	mov    0x8(%ebp),%eax
801056f5:	89 04 24             	mov    %eax,(%esp)
801056f8:	e8 92 fe ff ff       	call   8010558f <argint>
801056fd:	85 c0                	test   %eax,%eax
801056ff:	79 07                	jns    80105708 <argfd+0x23>
    return -1;
80105701:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105706:	eb 50                	jmp    80105758 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
80105708:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010570b:	85 c0                	test   %eax,%eax
8010570d:	78 21                	js     80105730 <argfd+0x4b>
8010570f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105712:	83 f8 0f             	cmp    $0xf,%eax
80105715:	7f 19                	jg     80105730 <argfd+0x4b>
80105717:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010571d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105720:	83 c2 08             	add    $0x8,%edx
80105723:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105727:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010572a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010572e:	75 07                	jne    80105737 <argfd+0x52>
    return -1;
80105730:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105735:	eb 21                	jmp    80105758 <argfd+0x73>
  if(pfd)
80105737:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010573b:	74 08                	je     80105745 <argfd+0x60>
    *pfd = fd;
8010573d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105740:	8b 45 0c             	mov    0xc(%ebp),%eax
80105743:	89 10                	mov    %edx,(%eax)
  if(pf)
80105745:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105749:	74 08                	je     80105753 <argfd+0x6e>
    *pf = f;
8010574b:	8b 45 10             	mov    0x10(%ebp),%eax
8010574e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105751:	89 10                	mov    %edx,(%eax)
  return 0;
80105753:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105758:	c9                   	leave  
80105759:	c3                   	ret    

8010575a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
8010575a:	55                   	push   %ebp
8010575b:	89 e5                	mov    %esp,%ebp
8010575d:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105760:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105767:	eb 30                	jmp    80105799 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105769:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010576f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105772:	83 c2 08             	add    $0x8,%edx
80105775:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105779:	85 c0                	test   %eax,%eax
8010577b:	75 18                	jne    80105795 <fdalloc+0x3b>
      proc->ofile[fd] = f;
8010577d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105783:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105786:	8d 4a 08             	lea    0x8(%edx),%ecx
80105789:	8b 55 08             	mov    0x8(%ebp),%edx
8010578c:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105790:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105793:	eb 0f                	jmp    801057a4 <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105795:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105799:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
8010579d:	7e ca                	jle    80105769 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
8010579f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801057a4:	c9                   	leave  
801057a5:	c3                   	ret    

801057a6 <sys_dup>:

int
sys_dup(void)
{
801057a6:	55                   	push   %ebp
801057a7:	89 e5                	mov    %esp,%ebp
801057a9:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
801057ac:	8d 45 f0             	lea    -0x10(%ebp),%eax
801057af:	89 44 24 08          	mov    %eax,0x8(%esp)
801057b3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801057ba:	00 
801057bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801057c2:	e8 1e ff ff ff       	call   801056e5 <argfd>
801057c7:	85 c0                	test   %eax,%eax
801057c9:	79 07                	jns    801057d2 <sys_dup+0x2c>
    return -1;
801057cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057d0:	eb 29                	jmp    801057fb <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
801057d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057d5:	89 04 24             	mov    %eax,(%esp)
801057d8:	e8 7d ff ff ff       	call   8010575a <fdalloc>
801057dd:	89 45 f4             	mov    %eax,-0xc(%ebp)
801057e0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801057e4:	79 07                	jns    801057ed <sys_dup+0x47>
    return -1;
801057e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057eb:	eb 0e                	jmp    801057fb <sys_dup+0x55>
  filedup(f);
801057ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057f0:	89 04 24             	mov    %eax,(%esp)
801057f3:	e8 8e b7 ff ff       	call   80100f86 <filedup>
  return fd;
801057f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801057fb:	c9                   	leave  
801057fc:	c3                   	ret    

801057fd <sys_read>:

int
sys_read(void)
{
801057fd:	55                   	push   %ebp
801057fe:	89 e5                	mov    %esp,%ebp
80105800:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105803:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105806:	89 44 24 08          	mov    %eax,0x8(%esp)
8010580a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105811:	00 
80105812:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105819:	e8 c7 fe ff ff       	call   801056e5 <argfd>
8010581e:	85 c0                	test   %eax,%eax
80105820:	78 35                	js     80105857 <sys_read+0x5a>
80105822:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105825:	89 44 24 04          	mov    %eax,0x4(%esp)
80105829:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105830:	e8 5a fd ff ff       	call   8010558f <argint>
80105835:	85 c0                	test   %eax,%eax
80105837:	78 1e                	js     80105857 <sys_read+0x5a>
80105839:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010583c:	89 44 24 08          	mov    %eax,0x8(%esp)
80105840:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105843:	89 44 24 04          	mov    %eax,0x4(%esp)
80105847:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010584e:	e8 6a fd ff ff       	call   801055bd <argptr>
80105853:	85 c0                	test   %eax,%eax
80105855:	79 07                	jns    8010585e <sys_read+0x61>
    return -1;
80105857:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010585c:	eb 19                	jmp    80105877 <sys_read+0x7a>
  return fileread(f, p, n);
8010585e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105861:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105864:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105867:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010586b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010586f:	89 04 24             	mov    %eax,(%esp)
80105872:	e8 7c b8 ff ff       	call   801010f3 <fileread>
}
80105877:	c9                   	leave  
80105878:	c3                   	ret    

80105879 <sys_write>:

int
sys_write(void)
{
80105879:	55                   	push   %ebp
8010587a:	89 e5                	mov    %esp,%ebp
8010587c:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010587f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105882:	89 44 24 08          	mov    %eax,0x8(%esp)
80105886:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010588d:	00 
8010588e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105895:	e8 4b fe ff ff       	call   801056e5 <argfd>
8010589a:	85 c0                	test   %eax,%eax
8010589c:	78 35                	js     801058d3 <sys_write+0x5a>
8010589e:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801058a5:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801058ac:	e8 de fc ff ff       	call   8010558f <argint>
801058b1:	85 c0                	test   %eax,%eax
801058b3:	78 1e                	js     801058d3 <sys_write+0x5a>
801058b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801058b8:	89 44 24 08          	mov    %eax,0x8(%esp)
801058bc:	8d 45 ec             	lea    -0x14(%ebp),%eax
801058bf:	89 44 24 04          	mov    %eax,0x4(%esp)
801058c3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801058ca:	e8 ee fc ff ff       	call   801055bd <argptr>
801058cf:	85 c0                	test   %eax,%eax
801058d1:	79 07                	jns    801058da <sys_write+0x61>
    return -1;
801058d3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058d8:	eb 19                	jmp    801058f3 <sys_write+0x7a>
  return filewrite(f, p, n);
801058da:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801058dd:	8b 55 ec             	mov    -0x14(%ebp),%edx
801058e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058e3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801058e7:	89 54 24 04          	mov    %edx,0x4(%esp)
801058eb:	89 04 24             	mov    %eax,(%esp)
801058ee:	e8 bc b8 ff ff       	call   801011af <filewrite>
}
801058f3:	c9                   	leave  
801058f4:	c3                   	ret    

801058f5 <sys_close>:

int
sys_close(void)
{
801058f5:	55                   	push   %ebp
801058f6:	89 e5                	mov    %esp,%ebp
801058f8:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801058fb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058fe:	89 44 24 08          	mov    %eax,0x8(%esp)
80105902:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105905:	89 44 24 04          	mov    %eax,0x4(%esp)
80105909:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105910:	e8 d0 fd ff ff       	call   801056e5 <argfd>
80105915:	85 c0                	test   %eax,%eax
80105917:	79 07                	jns    80105920 <sys_close+0x2b>
    return -1;
80105919:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010591e:	eb 24                	jmp    80105944 <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105920:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105926:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105929:	83 c2 08             	add    $0x8,%edx
8010592c:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105933:	00 
  fileclose(f);
80105934:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105937:	89 04 24             	mov    %eax,(%esp)
8010593a:	e8 8f b6 ff ff       	call   80100fce <fileclose>
  return 0;
8010593f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105944:	c9                   	leave  
80105945:	c3                   	ret    

80105946 <sys_fstat>:

int
sys_fstat(void)
{
80105946:	55                   	push   %ebp
80105947:	89 e5                	mov    %esp,%ebp
80105949:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010594c:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010594f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105953:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010595a:	00 
8010595b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105962:	e8 7e fd ff ff       	call   801056e5 <argfd>
80105967:	85 c0                	test   %eax,%eax
80105969:	78 1f                	js     8010598a <sys_fstat+0x44>
8010596b:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105972:	00 
80105973:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105976:	89 44 24 04          	mov    %eax,0x4(%esp)
8010597a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105981:	e8 37 fc ff ff       	call   801055bd <argptr>
80105986:	85 c0                	test   %eax,%eax
80105988:	79 07                	jns    80105991 <sys_fstat+0x4b>
    return -1;
8010598a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010598f:	eb 12                	jmp    801059a3 <sys_fstat+0x5d>
  return filestat(f, st);
80105991:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105994:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105997:	89 54 24 04          	mov    %edx,0x4(%esp)
8010599b:	89 04 24             	mov    %eax,(%esp)
8010599e:	e8 01 b7 ff ff       	call   801010a4 <filestat>
}
801059a3:	c9                   	leave  
801059a4:	c3                   	ret    

801059a5 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801059a5:	55                   	push   %ebp
801059a6:	89 e5                	mov    %esp,%ebp
801059a8:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801059ab:	8d 45 d8             	lea    -0x28(%ebp),%eax
801059ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801059b2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801059b9:	e8 61 fc ff ff       	call   8010561f <argstr>
801059be:	85 c0                	test   %eax,%eax
801059c0:	78 17                	js     801059d9 <sys_link+0x34>
801059c2:	8d 45 dc             	lea    -0x24(%ebp),%eax
801059c5:	89 44 24 04          	mov    %eax,0x4(%esp)
801059c9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801059d0:	e8 4a fc ff ff       	call   8010561f <argstr>
801059d5:	85 c0                	test   %eax,%eax
801059d7:	79 0a                	jns    801059e3 <sys_link+0x3e>
    return -1;
801059d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059de:	e9 42 01 00 00       	jmp    80105b25 <sys_link+0x180>

  begin_op();
801059e3:	e8 5f da ff ff       	call   80103447 <begin_op>
  if((ip = namei(old)) == 0){
801059e8:	8b 45 d8             	mov    -0x28(%ebp),%eax
801059eb:	89 04 24             	mov    %eax,(%esp)
801059ee:	e8 13 ca ff ff       	call   80102406 <namei>
801059f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801059f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801059fa:	75 0f                	jne    80105a0b <sys_link+0x66>
    end_op();
801059fc:	e8 ca da ff ff       	call   801034cb <end_op>
    return -1;
80105a01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a06:	e9 1a 01 00 00       	jmp    80105b25 <sys_link+0x180>
  }

  ilock(ip);
80105a0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a0e:	89 04 24             	mov    %eax,(%esp)
80105a11:	e8 45 be ff ff       	call   8010185b <ilock>
  if(ip->type == T_DIR){
80105a16:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a19:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105a1d:	66 83 f8 01          	cmp    $0x1,%ax
80105a21:	75 1a                	jne    80105a3d <sys_link+0x98>
    iunlockput(ip);
80105a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a26:	89 04 24             	mov    %eax,(%esp)
80105a29:	e8 b1 c0 ff ff       	call   80101adf <iunlockput>
    end_op();
80105a2e:	e8 98 da ff ff       	call   801034cb <end_op>
    return -1;
80105a33:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a38:	e9 e8 00 00 00       	jmp    80105b25 <sys_link+0x180>
  }

  ip->nlink++;
80105a3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a40:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105a44:	8d 50 01             	lea    0x1(%eax),%edx
80105a47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a4a:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105a4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a51:	89 04 24             	mov    %eax,(%esp)
80105a54:	e8 46 bc ff ff       	call   8010169f <iupdate>
  iunlock(ip);
80105a59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a5c:	89 04 24             	mov    %eax,(%esp)
80105a5f:	e8 45 bf ff ff       	call   801019a9 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105a64:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105a67:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105a6a:	89 54 24 04          	mov    %edx,0x4(%esp)
80105a6e:	89 04 24             	mov    %eax,(%esp)
80105a71:	e8 b2 c9 ff ff       	call   80102428 <nameiparent>
80105a76:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105a79:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105a7d:	75 02                	jne    80105a81 <sys_link+0xdc>
    goto bad;
80105a7f:	eb 68                	jmp    80105ae9 <sys_link+0x144>
  ilock(dp);
80105a81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a84:	89 04 24             	mov    %eax,(%esp)
80105a87:	e8 cf bd ff ff       	call   8010185b <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105a8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a8f:	8b 10                	mov    (%eax),%edx
80105a91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a94:	8b 00                	mov    (%eax),%eax
80105a96:	39 c2                	cmp    %eax,%edx
80105a98:	75 20                	jne    80105aba <sys_link+0x115>
80105a9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a9d:	8b 40 04             	mov    0x4(%eax),%eax
80105aa0:	89 44 24 08          	mov    %eax,0x8(%esp)
80105aa4:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105aa7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105aab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aae:	89 04 24             	mov    %eax,(%esp)
80105ab1:	e8 90 c6 ff ff       	call   80102146 <dirlink>
80105ab6:	85 c0                	test   %eax,%eax
80105ab8:	79 0d                	jns    80105ac7 <sys_link+0x122>
    iunlockput(dp);
80105aba:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105abd:	89 04 24             	mov    %eax,(%esp)
80105ac0:	e8 1a c0 ff ff       	call   80101adf <iunlockput>
    goto bad;
80105ac5:	eb 22                	jmp    80105ae9 <sys_link+0x144>
  }
  iunlockput(dp);
80105ac7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aca:	89 04 24             	mov    %eax,(%esp)
80105acd:	e8 0d c0 ff ff       	call   80101adf <iunlockput>
  iput(ip);
80105ad2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ad5:	89 04 24             	mov    %eax,(%esp)
80105ad8:	e8 31 bf ff ff       	call   80101a0e <iput>

  end_op();
80105add:	e8 e9 d9 ff ff       	call   801034cb <end_op>

  return 0;
80105ae2:	b8 00 00 00 00       	mov    $0x0,%eax
80105ae7:	eb 3c                	jmp    80105b25 <sys_link+0x180>

bad:
  ilock(ip);
80105ae9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105aec:	89 04 24             	mov    %eax,(%esp)
80105aef:	e8 67 bd ff ff       	call   8010185b <ilock>
  ip->nlink--;
80105af4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105af7:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105afb:	8d 50 ff             	lea    -0x1(%eax),%edx
80105afe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b01:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105b05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b08:	89 04 24             	mov    %eax,(%esp)
80105b0b:	e8 8f bb ff ff       	call   8010169f <iupdate>
  iunlockput(ip);
80105b10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b13:	89 04 24             	mov    %eax,(%esp)
80105b16:	e8 c4 bf ff ff       	call   80101adf <iunlockput>
  end_op();
80105b1b:	e8 ab d9 ff ff       	call   801034cb <end_op>
  return -1;
80105b20:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105b25:	c9                   	leave  
80105b26:	c3                   	ret    

80105b27 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105b27:	55                   	push   %ebp
80105b28:	89 e5                	mov    %esp,%ebp
80105b2a:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105b2d:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105b34:	eb 4b                	jmp    80105b81 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105b36:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b39:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105b40:	00 
80105b41:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b45:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105b48:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b4c:	8b 45 08             	mov    0x8(%ebp),%eax
80105b4f:	89 04 24             	mov    %eax,(%esp)
80105b52:	e8 11 c2 ff ff       	call   80101d68 <readi>
80105b57:	83 f8 10             	cmp    $0x10,%eax
80105b5a:	74 0c                	je     80105b68 <isdirempty+0x41>
      panic("isdirempty: readi");
80105b5c:	c7 04 24 d5 8a 10 80 	movl   $0x80108ad5,(%esp)
80105b63:	e8 d2 a9 ff ff       	call   8010053a <panic>
    if(de.inum != 0)
80105b68:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105b6c:	66 85 c0             	test   %ax,%ax
80105b6f:	74 07                	je     80105b78 <isdirempty+0x51>
      return 0;
80105b71:	b8 00 00 00 00       	mov    $0x0,%eax
80105b76:	eb 1b                	jmp    80105b93 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105b78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b7b:	83 c0 10             	add    $0x10,%eax
80105b7e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b81:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105b84:	8b 45 08             	mov    0x8(%ebp),%eax
80105b87:	8b 40 18             	mov    0x18(%eax),%eax
80105b8a:	39 c2                	cmp    %eax,%edx
80105b8c:	72 a8                	jb     80105b36 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105b8e:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105b93:	c9                   	leave  
80105b94:	c3                   	ret    

80105b95 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105b95:	55                   	push   %ebp
80105b96:	89 e5                	mov    %esp,%ebp
80105b98:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105b9b:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105b9e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ba2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ba9:	e8 71 fa ff ff       	call   8010561f <argstr>
80105bae:	85 c0                	test   %eax,%eax
80105bb0:	79 0a                	jns    80105bbc <sys_unlink+0x27>
    return -1;
80105bb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105bb7:	e9 af 01 00 00       	jmp    80105d6b <sys_unlink+0x1d6>

  begin_op();
80105bbc:	e8 86 d8 ff ff       	call   80103447 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105bc1:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105bc4:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105bc7:	89 54 24 04          	mov    %edx,0x4(%esp)
80105bcb:	89 04 24             	mov    %eax,(%esp)
80105bce:	e8 55 c8 ff ff       	call   80102428 <nameiparent>
80105bd3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105bd6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105bda:	75 0f                	jne    80105beb <sys_unlink+0x56>
    end_op();
80105bdc:	e8 ea d8 ff ff       	call   801034cb <end_op>
    return -1;
80105be1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105be6:	e9 80 01 00 00       	jmp    80105d6b <sys_unlink+0x1d6>
  }

  ilock(dp);
80105beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bee:	89 04 24             	mov    %eax,(%esp)
80105bf1:	e8 65 bc ff ff       	call   8010185b <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105bf6:	c7 44 24 04 e7 8a 10 	movl   $0x80108ae7,0x4(%esp)
80105bfd:	80 
80105bfe:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105c01:	89 04 24             	mov    %eax,(%esp)
80105c04:	e8 52 c4 ff ff       	call   8010205b <namecmp>
80105c09:	85 c0                	test   %eax,%eax
80105c0b:	0f 84 45 01 00 00    	je     80105d56 <sys_unlink+0x1c1>
80105c11:	c7 44 24 04 e9 8a 10 	movl   $0x80108ae9,0x4(%esp)
80105c18:	80 
80105c19:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105c1c:	89 04 24             	mov    %eax,(%esp)
80105c1f:	e8 37 c4 ff ff       	call   8010205b <namecmp>
80105c24:	85 c0                	test   %eax,%eax
80105c26:	0f 84 2a 01 00 00    	je     80105d56 <sys_unlink+0x1c1>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105c2c:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105c2f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105c33:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105c36:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c3d:	89 04 24             	mov    %eax,(%esp)
80105c40:	e8 38 c4 ff ff       	call   8010207d <dirlookup>
80105c45:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105c48:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105c4c:	75 05                	jne    80105c53 <sys_unlink+0xbe>
    goto bad;
80105c4e:	e9 03 01 00 00       	jmp    80105d56 <sys_unlink+0x1c1>
  ilock(ip);
80105c53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c56:	89 04 24             	mov    %eax,(%esp)
80105c59:	e8 fd bb ff ff       	call   8010185b <ilock>

  if(ip->nlink < 1)
80105c5e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c61:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105c65:	66 85 c0             	test   %ax,%ax
80105c68:	7f 0c                	jg     80105c76 <sys_unlink+0xe1>
    panic("unlink: nlink < 1");
80105c6a:	c7 04 24 ec 8a 10 80 	movl   $0x80108aec,(%esp)
80105c71:	e8 c4 a8 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105c76:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c79:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c7d:	66 83 f8 01          	cmp    $0x1,%ax
80105c81:	75 1f                	jne    80105ca2 <sys_unlink+0x10d>
80105c83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c86:	89 04 24             	mov    %eax,(%esp)
80105c89:	e8 99 fe ff ff       	call   80105b27 <isdirempty>
80105c8e:	85 c0                	test   %eax,%eax
80105c90:	75 10                	jne    80105ca2 <sys_unlink+0x10d>
    iunlockput(ip);
80105c92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c95:	89 04 24             	mov    %eax,(%esp)
80105c98:	e8 42 be ff ff       	call   80101adf <iunlockput>
    goto bad;
80105c9d:	e9 b4 00 00 00       	jmp    80105d56 <sys_unlink+0x1c1>
  }

  memset(&de, 0, sizeof(de));
80105ca2:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105ca9:	00 
80105caa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105cb1:	00 
80105cb2:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105cb5:	89 04 24             	mov    %eax,(%esp)
80105cb8:	e8 90 f5 ff ff       	call   8010524d <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105cbd:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105cc0:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105cc7:	00 
80105cc8:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ccc:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105ccf:	89 44 24 04          	mov    %eax,0x4(%esp)
80105cd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cd6:	89 04 24             	mov    %eax,(%esp)
80105cd9:	e8 ee c1 ff ff       	call   80101ecc <writei>
80105cde:	83 f8 10             	cmp    $0x10,%eax
80105ce1:	74 0c                	je     80105cef <sys_unlink+0x15a>
    panic("unlink: writei");
80105ce3:	c7 04 24 fe 8a 10 80 	movl   $0x80108afe,(%esp)
80105cea:	e8 4b a8 ff ff       	call   8010053a <panic>
  if(ip->type == T_DIR){
80105cef:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cf2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105cf6:	66 83 f8 01          	cmp    $0x1,%ax
80105cfa:	75 1c                	jne    80105d18 <sys_unlink+0x183>
    dp->nlink--;
80105cfc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cff:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105d03:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d09:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105d0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d10:	89 04 24             	mov    %eax,(%esp)
80105d13:	e8 87 b9 ff ff       	call   8010169f <iupdate>
  }
  iunlockput(dp);
80105d18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d1b:	89 04 24             	mov    %eax,(%esp)
80105d1e:	e8 bc bd ff ff       	call   80101adf <iunlockput>

  ip->nlink--;
80105d23:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d26:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105d2a:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d30:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105d34:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d37:	89 04 24             	mov    %eax,(%esp)
80105d3a:	e8 60 b9 ff ff       	call   8010169f <iupdate>
  iunlockput(ip);
80105d3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d42:	89 04 24             	mov    %eax,(%esp)
80105d45:	e8 95 bd ff ff       	call   80101adf <iunlockput>

  end_op();
80105d4a:	e8 7c d7 ff ff       	call   801034cb <end_op>

  return 0;
80105d4f:	b8 00 00 00 00       	mov    $0x0,%eax
80105d54:	eb 15                	jmp    80105d6b <sys_unlink+0x1d6>

bad:
  iunlockput(dp);
80105d56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d59:	89 04 24             	mov    %eax,(%esp)
80105d5c:	e8 7e bd ff ff       	call   80101adf <iunlockput>
  end_op();
80105d61:	e8 65 d7 ff ff       	call   801034cb <end_op>
  return -1;
80105d66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d6b:	c9                   	leave  
80105d6c:	c3                   	ret    

80105d6d <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105d6d:	55                   	push   %ebp
80105d6e:	89 e5                	mov    %esp,%ebp
80105d70:	83 ec 48             	sub    $0x48,%esp
80105d73:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105d76:	8b 55 10             	mov    0x10(%ebp),%edx
80105d79:	8b 45 14             	mov    0x14(%ebp),%eax
80105d7c:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105d80:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105d84:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105d88:	8d 45 de             	lea    -0x22(%ebp),%eax
80105d8b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d8f:	8b 45 08             	mov    0x8(%ebp),%eax
80105d92:	89 04 24             	mov    %eax,(%esp)
80105d95:	e8 8e c6 ff ff       	call   80102428 <nameiparent>
80105d9a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105d9d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105da1:	75 0a                	jne    80105dad <create+0x40>
    return 0;
80105da3:	b8 00 00 00 00       	mov    $0x0,%eax
80105da8:	e9 7e 01 00 00       	jmp    80105f2b <create+0x1be>
  ilock(dp);
80105dad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105db0:	89 04 24             	mov    %eax,(%esp)
80105db3:	e8 a3 ba ff ff       	call   8010185b <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105db8:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105dbb:	89 44 24 08          	mov    %eax,0x8(%esp)
80105dbf:	8d 45 de             	lea    -0x22(%ebp),%eax
80105dc2:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dc9:	89 04 24             	mov    %eax,(%esp)
80105dcc:	e8 ac c2 ff ff       	call   8010207d <dirlookup>
80105dd1:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105dd4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105dd8:	74 47                	je     80105e21 <create+0xb4>
    iunlockput(dp);
80105dda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ddd:	89 04 24             	mov    %eax,(%esp)
80105de0:	e8 fa bc ff ff       	call   80101adf <iunlockput>
    ilock(ip);
80105de5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105de8:	89 04 24             	mov    %eax,(%esp)
80105deb:	e8 6b ba ff ff       	call   8010185b <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105df0:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105df5:	75 15                	jne    80105e0c <create+0x9f>
80105df7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dfa:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105dfe:	66 83 f8 02          	cmp    $0x2,%ax
80105e02:	75 08                	jne    80105e0c <create+0x9f>
      return ip;
80105e04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e07:	e9 1f 01 00 00       	jmp    80105f2b <create+0x1be>
    iunlockput(ip);
80105e0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e0f:	89 04 24             	mov    %eax,(%esp)
80105e12:	e8 c8 bc ff ff       	call   80101adf <iunlockput>
    return 0;
80105e17:	b8 00 00 00 00       	mov    $0x0,%eax
80105e1c:	e9 0a 01 00 00       	jmp    80105f2b <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105e21:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105e25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e28:	8b 00                	mov    (%eax),%eax
80105e2a:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e2e:	89 04 24             	mov    %eax,(%esp)
80105e31:	e8 8a b7 ff ff       	call   801015c0 <ialloc>
80105e36:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105e39:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105e3d:	75 0c                	jne    80105e4b <create+0xde>
    panic("create: ialloc");
80105e3f:	c7 04 24 0d 8b 10 80 	movl   $0x80108b0d,(%esp)
80105e46:	e8 ef a6 ff ff       	call   8010053a <panic>

  ilock(ip);
80105e4b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e4e:	89 04 24             	mov    %eax,(%esp)
80105e51:	e8 05 ba ff ff       	call   8010185b <ilock>
  ip->major = major;
80105e56:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e59:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105e5d:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105e61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e64:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105e68:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105e6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e6f:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105e75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e78:	89 04 24             	mov    %eax,(%esp)
80105e7b:	e8 1f b8 ff ff       	call   8010169f <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105e80:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105e85:	75 6a                	jne    80105ef1 <create+0x184>
    dp->nlink++;  // for ".."
80105e87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e8a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105e8e:	8d 50 01             	lea    0x1(%eax),%edx
80105e91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e94:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105e98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e9b:	89 04 24             	mov    %eax,(%esp)
80105e9e:	e8 fc b7 ff ff       	call   8010169f <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105ea3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ea6:	8b 40 04             	mov    0x4(%eax),%eax
80105ea9:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ead:	c7 44 24 04 e7 8a 10 	movl   $0x80108ae7,0x4(%esp)
80105eb4:	80 
80105eb5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105eb8:	89 04 24             	mov    %eax,(%esp)
80105ebb:	e8 86 c2 ff ff       	call   80102146 <dirlink>
80105ec0:	85 c0                	test   %eax,%eax
80105ec2:	78 21                	js     80105ee5 <create+0x178>
80105ec4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ec7:	8b 40 04             	mov    0x4(%eax),%eax
80105eca:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ece:	c7 44 24 04 e9 8a 10 	movl   $0x80108ae9,0x4(%esp)
80105ed5:	80 
80105ed6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ed9:	89 04 24             	mov    %eax,(%esp)
80105edc:	e8 65 c2 ff ff       	call   80102146 <dirlink>
80105ee1:	85 c0                	test   %eax,%eax
80105ee3:	79 0c                	jns    80105ef1 <create+0x184>
      panic("create dots");
80105ee5:	c7 04 24 1c 8b 10 80 	movl   $0x80108b1c,(%esp)
80105eec:	e8 49 a6 ff ff       	call   8010053a <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105ef1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ef4:	8b 40 04             	mov    0x4(%eax),%eax
80105ef7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105efb:	8d 45 de             	lea    -0x22(%ebp),%eax
80105efe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f05:	89 04 24             	mov    %eax,(%esp)
80105f08:	e8 39 c2 ff ff       	call   80102146 <dirlink>
80105f0d:	85 c0                	test   %eax,%eax
80105f0f:	79 0c                	jns    80105f1d <create+0x1b0>
    panic("create: dirlink");
80105f11:	c7 04 24 28 8b 10 80 	movl   $0x80108b28,(%esp)
80105f18:	e8 1d a6 ff ff       	call   8010053a <panic>

  iunlockput(dp);
80105f1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f20:	89 04 24             	mov    %eax,(%esp)
80105f23:	e8 b7 bb ff ff       	call   80101adf <iunlockput>

  return ip;
80105f28:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105f2b:	c9                   	leave  
80105f2c:	c3                   	ret    

80105f2d <sys_open>:

int
sys_open(void)
{
80105f2d:	55                   	push   %ebp
80105f2e:	89 e5                	mov    %esp,%ebp
80105f30:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105f33:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105f36:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f3a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f41:	e8 d9 f6 ff ff       	call   8010561f <argstr>
80105f46:	85 c0                	test   %eax,%eax
80105f48:	78 17                	js     80105f61 <sys_open+0x34>
80105f4a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105f4d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f51:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f58:	e8 32 f6 ff ff       	call   8010558f <argint>
80105f5d:	85 c0                	test   %eax,%eax
80105f5f:	79 0a                	jns    80105f6b <sys_open+0x3e>
    return -1;
80105f61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f66:	e9 5c 01 00 00       	jmp    801060c7 <sys_open+0x19a>

  begin_op();
80105f6b:	e8 d7 d4 ff ff       	call   80103447 <begin_op>

  if(omode & O_CREATE){
80105f70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f73:	25 00 02 00 00       	and    $0x200,%eax
80105f78:	85 c0                	test   %eax,%eax
80105f7a:	74 3b                	je     80105fb7 <sys_open+0x8a>
    ip = create(path, T_FILE, 0, 0);
80105f7c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f7f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105f86:	00 
80105f87:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105f8e:	00 
80105f8f:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105f96:	00 
80105f97:	89 04 24             	mov    %eax,(%esp)
80105f9a:	e8 ce fd ff ff       	call   80105d6d <create>
80105f9f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80105fa2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fa6:	75 6b                	jne    80106013 <sys_open+0xe6>
      end_op();
80105fa8:	e8 1e d5 ff ff       	call   801034cb <end_op>
      return -1;
80105fad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fb2:	e9 10 01 00 00       	jmp    801060c7 <sys_open+0x19a>
    }
  } else {
    if((ip = namei(path)) == 0){
80105fb7:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105fba:	89 04 24             	mov    %eax,(%esp)
80105fbd:	e8 44 c4 ff ff       	call   80102406 <namei>
80105fc2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105fc5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105fc9:	75 0f                	jne    80105fda <sys_open+0xad>
      end_op();
80105fcb:	e8 fb d4 ff ff       	call   801034cb <end_op>
      return -1;
80105fd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fd5:	e9 ed 00 00 00       	jmp    801060c7 <sys_open+0x19a>
    }
    ilock(ip);
80105fda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fdd:	89 04 24             	mov    %eax,(%esp)
80105fe0:	e8 76 b8 ff ff       	call   8010185b <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105fe5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fe8:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105fec:	66 83 f8 01          	cmp    $0x1,%ax
80105ff0:	75 21                	jne    80106013 <sys_open+0xe6>
80105ff2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ff5:	85 c0                	test   %eax,%eax
80105ff7:	74 1a                	je     80106013 <sys_open+0xe6>
      iunlockput(ip);
80105ff9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ffc:	89 04 24             	mov    %eax,(%esp)
80105fff:	e8 db ba ff ff       	call   80101adf <iunlockput>
      end_op();
80106004:	e8 c2 d4 ff ff       	call   801034cb <end_op>
      return -1;
80106009:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010600e:	e9 b4 00 00 00       	jmp    801060c7 <sys_open+0x19a>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106013:	e8 0e af ff ff       	call   80100f26 <filealloc>
80106018:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010601b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010601f:	74 14                	je     80106035 <sys_open+0x108>
80106021:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106024:	89 04 24             	mov    %eax,(%esp)
80106027:	e8 2e f7 ff ff       	call   8010575a <fdalloc>
8010602c:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010602f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106033:	79 28                	jns    8010605d <sys_open+0x130>
    if(f)
80106035:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106039:	74 0b                	je     80106046 <sys_open+0x119>
      fileclose(f);
8010603b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010603e:	89 04 24             	mov    %eax,(%esp)
80106041:	e8 88 af ff ff       	call   80100fce <fileclose>
    iunlockput(ip);
80106046:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106049:	89 04 24             	mov    %eax,(%esp)
8010604c:	e8 8e ba ff ff       	call   80101adf <iunlockput>
    end_op();
80106051:	e8 75 d4 ff ff       	call   801034cb <end_op>
    return -1;
80106056:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010605b:	eb 6a                	jmp    801060c7 <sys_open+0x19a>
  }
  iunlock(ip);
8010605d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106060:	89 04 24             	mov    %eax,(%esp)
80106063:	e8 41 b9 ff ff       	call   801019a9 <iunlock>
  end_op();
80106068:	e8 5e d4 ff ff       	call   801034cb <end_op>

  f->type = FD_INODE;
8010606d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106070:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80106076:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106079:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010607c:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
8010607f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106082:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80106089:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010608c:	83 e0 01             	and    $0x1,%eax
8010608f:	85 c0                	test   %eax,%eax
80106091:	0f 94 c0             	sete   %al
80106094:	89 c2                	mov    %eax,%edx
80106096:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106099:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
8010609c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010609f:	83 e0 01             	and    $0x1,%eax
801060a2:	85 c0                	test   %eax,%eax
801060a4:	75 0a                	jne    801060b0 <sys_open+0x183>
801060a6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060a9:	83 e0 02             	and    $0x2,%eax
801060ac:	85 c0                	test   %eax,%eax
801060ae:	74 07                	je     801060b7 <sys_open+0x18a>
801060b0:	b8 01 00 00 00       	mov    $0x1,%eax
801060b5:	eb 05                	jmp    801060bc <sys_open+0x18f>
801060b7:	b8 00 00 00 00       	mov    $0x0,%eax
801060bc:	89 c2                	mov    %eax,%edx
801060be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060c1:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
801060c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
801060c7:	c9                   	leave  
801060c8:	c3                   	ret    

801060c9 <sys_mkdir>:

int
sys_mkdir(void)
{
801060c9:	55                   	push   %ebp
801060ca:	89 e5                	mov    %esp,%ebp
801060cc:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801060cf:	e8 73 d3 ff ff       	call   80103447 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
801060d4:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060d7:	89 44 24 04          	mov    %eax,0x4(%esp)
801060db:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801060e2:	e8 38 f5 ff ff       	call   8010561f <argstr>
801060e7:	85 c0                	test   %eax,%eax
801060e9:	78 2c                	js     80106117 <sys_mkdir+0x4e>
801060eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060ee:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801060f5:	00 
801060f6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801060fd:	00 
801060fe:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106105:	00 
80106106:	89 04 24             	mov    %eax,(%esp)
80106109:	e8 5f fc ff ff       	call   80105d6d <create>
8010610e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106111:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106115:	75 0c                	jne    80106123 <sys_mkdir+0x5a>
    end_op();
80106117:	e8 af d3 ff ff       	call   801034cb <end_op>
    return -1;
8010611c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106121:	eb 15                	jmp    80106138 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106123:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106126:	89 04 24             	mov    %eax,(%esp)
80106129:	e8 b1 b9 ff ff       	call   80101adf <iunlockput>
  end_op();
8010612e:	e8 98 d3 ff ff       	call   801034cb <end_op>
  return 0;
80106133:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106138:	c9                   	leave  
80106139:	c3                   	ret    

8010613a <sys_mknod>:

int
sys_mknod(void)
{
8010613a:	55                   	push   %ebp
8010613b:	89 e5                	mov    %esp,%ebp
8010613d:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_op();
80106140:	e8 02 d3 ff ff       	call   80103447 <begin_op>
  if((len=argstr(0, &path)) < 0 ||
80106145:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106148:	89 44 24 04          	mov    %eax,0x4(%esp)
8010614c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106153:	e8 c7 f4 ff ff       	call   8010561f <argstr>
80106158:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010615b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010615f:	78 5e                	js     801061bf <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80106161:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106164:	89 44 24 04          	mov    %eax,0x4(%esp)
80106168:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010616f:	e8 1b f4 ff ff       	call   8010558f <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
80106174:	85 c0                	test   %eax,%eax
80106176:	78 47                	js     801061bf <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80106178:	8d 45 e4             	lea    -0x1c(%ebp),%eax
8010617b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010617f:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80106186:	e8 04 f4 ff ff       	call   8010558f <argint>
  int len;
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
8010618b:	85 c0                	test   %eax,%eax
8010618d:	78 30                	js     801061bf <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
8010618f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106192:	0f bf c8             	movswl %ax,%ecx
80106195:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106198:	0f bf d0             	movswl %ax,%edx
8010619b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_op();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
8010619e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801061a2:	89 54 24 08          	mov    %edx,0x8(%esp)
801061a6:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801061ad:	00 
801061ae:	89 04 24             	mov    %eax,(%esp)
801061b1:	e8 b7 fb ff ff       	call   80105d6d <create>
801061b6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801061b9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801061bd:	75 0c                	jne    801061cb <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
801061bf:	e8 07 d3 ff ff       	call   801034cb <end_op>
    return -1;
801061c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c9:	eb 15                	jmp    801061e0 <sys_mknod+0xa6>
  }
  iunlockput(ip);
801061cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061ce:	89 04 24             	mov    %eax,(%esp)
801061d1:	e8 09 b9 ff ff       	call   80101adf <iunlockput>
  end_op();
801061d6:	e8 f0 d2 ff ff       	call   801034cb <end_op>
  return 0;
801061db:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061e0:	c9                   	leave  
801061e1:	c3                   	ret    

801061e2 <sys_chdir>:

int
sys_chdir(void)
{
801061e2:	55                   	push   %ebp
801061e3:	89 e5                	mov    %esp,%ebp
801061e5:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_op();
801061e8:	e8 5a d2 ff ff       	call   80103447 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
801061ed:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061f0:	89 44 24 04          	mov    %eax,0x4(%esp)
801061f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061fb:	e8 1f f4 ff ff       	call   8010561f <argstr>
80106200:	85 c0                	test   %eax,%eax
80106202:	78 14                	js     80106218 <sys_chdir+0x36>
80106204:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106207:	89 04 24             	mov    %eax,(%esp)
8010620a:	e8 f7 c1 ff ff       	call   80102406 <namei>
8010620f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106212:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106216:	75 0c                	jne    80106224 <sys_chdir+0x42>
    end_op();
80106218:	e8 ae d2 ff ff       	call   801034cb <end_op>
    return -1;
8010621d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106222:	eb 61                	jmp    80106285 <sys_chdir+0xa3>
  }
  ilock(ip);
80106224:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106227:	89 04 24             	mov    %eax,(%esp)
8010622a:	e8 2c b6 ff ff       	call   8010185b <ilock>
  if(ip->type != T_DIR){
8010622f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106232:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106236:	66 83 f8 01          	cmp    $0x1,%ax
8010623a:	74 17                	je     80106253 <sys_chdir+0x71>
    iunlockput(ip);
8010623c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010623f:	89 04 24             	mov    %eax,(%esp)
80106242:	e8 98 b8 ff ff       	call   80101adf <iunlockput>
    end_op();
80106247:	e8 7f d2 ff ff       	call   801034cb <end_op>
    return -1;
8010624c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106251:	eb 32                	jmp    80106285 <sys_chdir+0xa3>
  }
  iunlock(ip);
80106253:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106256:	89 04 24             	mov    %eax,(%esp)
80106259:	e8 4b b7 ff ff       	call   801019a9 <iunlock>
  iput(proc->cwd);
8010625e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106264:	8b 40 68             	mov    0x68(%eax),%eax
80106267:	89 04 24             	mov    %eax,(%esp)
8010626a:	e8 9f b7 ff ff       	call   80101a0e <iput>
  end_op();
8010626f:	e8 57 d2 ff ff       	call   801034cb <end_op>
  proc->cwd = ip;
80106274:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010627a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010627d:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80106280:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106285:	c9                   	leave  
80106286:	c3                   	ret    

80106287 <sys_exec>:

int
sys_exec(void)
{
80106287:	55                   	push   %ebp
80106288:	89 e5                	mov    %esp,%ebp
8010628a:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80106290:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106293:	89 44 24 04          	mov    %eax,0x4(%esp)
80106297:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010629e:	e8 7c f3 ff ff       	call   8010561f <argstr>
801062a3:	85 c0                	test   %eax,%eax
801062a5:	78 1a                	js     801062c1 <sys_exec+0x3a>
801062a7:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
801062ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801062b1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801062b8:	e8 d2 f2 ff ff       	call   8010558f <argint>
801062bd:	85 c0                	test   %eax,%eax
801062bf:	79 0a                	jns    801062cb <sys_exec+0x44>
    return -1;
801062c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062c6:	e9 c8 00 00 00       	jmp    80106393 <sys_exec+0x10c>
  }
  memset(argv, 0, sizeof(argv));
801062cb:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801062d2:	00 
801062d3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801062da:	00 
801062db:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801062e1:	89 04 24             	mov    %eax,(%esp)
801062e4:	e8 64 ef ff ff       	call   8010524d <memset>
  for(i=0;; i++){
801062e9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
801062f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062f3:	83 f8 1f             	cmp    $0x1f,%eax
801062f6:	76 0a                	jbe    80106302 <sys_exec+0x7b>
      return -1;
801062f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062fd:	e9 91 00 00 00       	jmp    80106393 <sys_exec+0x10c>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80106302:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106305:	c1 e0 02             	shl    $0x2,%eax
80106308:	89 c2                	mov    %eax,%edx
8010630a:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106310:	01 c2                	add    %eax,%edx
80106312:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106318:	89 44 24 04          	mov    %eax,0x4(%esp)
8010631c:	89 14 24             	mov    %edx,(%esp)
8010631f:	e8 cf f1 ff ff       	call   801054f3 <fetchint>
80106324:	85 c0                	test   %eax,%eax
80106326:	79 07                	jns    8010632f <sys_exec+0xa8>
      return -1;
80106328:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010632d:	eb 64                	jmp    80106393 <sys_exec+0x10c>
    if(uarg == 0){
8010632f:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106335:	85 c0                	test   %eax,%eax
80106337:	75 26                	jne    8010635f <sys_exec+0xd8>
      argv[i] = 0;
80106339:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010633c:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106343:	00 00 00 00 
      break;
80106347:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106348:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010634b:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80106351:	89 54 24 04          	mov    %edx,0x4(%esp)
80106355:	89 04 24             	mov    %eax,(%esp)
80106358:	e8 92 a7 ff ff       	call   80100aef <exec>
8010635d:	eb 34                	jmp    80106393 <sys_exec+0x10c>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
8010635f:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106365:	8b 55 f4             	mov    -0xc(%ebp),%edx
80106368:	c1 e2 02             	shl    $0x2,%edx
8010636b:	01 c2                	add    %eax,%edx
8010636d:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106373:	89 54 24 04          	mov    %edx,0x4(%esp)
80106377:	89 04 24             	mov    %eax,(%esp)
8010637a:	e8 ae f1 ff ff       	call   8010552d <fetchstr>
8010637f:	85 c0                	test   %eax,%eax
80106381:	79 07                	jns    8010638a <sys_exec+0x103>
      return -1;
80106383:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106388:	eb 09                	jmp    80106393 <sys_exec+0x10c>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010638a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
8010638e:	e9 5d ff ff ff       	jmp    801062f0 <sys_exec+0x69>
  return exec(path, argv);
}
80106393:	c9                   	leave  
80106394:	c3                   	ret    

80106395 <sys_pipe>:

int
sys_pipe(void)
{
80106395:	55                   	push   %ebp
80106396:	89 e5                	mov    %esp,%ebp
80106398:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010639b:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801063a2:	00 
801063a3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801063a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801063aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063b1:	e8 07 f2 ff ff       	call   801055bd <argptr>
801063b6:	85 c0                	test   %eax,%eax
801063b8:	79 0a                	jns    801063c4 <sys_pipe+0x2f>
    return -1;
801063ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063bf:	e9 9b 00 00 00       	jmp    8010645f <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
801063c4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801063c7:	89 44 24 04          	mov    %eax,0x4(%esp)
801063cb:	8d 45 e8             	lea    -0x18(%ebp),%eax
801063ce:	89 04 24             	mov    %eax,(%esp)
801063d1:	e8 82 db ff ff       	call   80103f58 <pipealloc>
801063d6:	85 c0                	test   %eax,%eax
801063d8:	79 07                	jns    801063e1 <sys_pipe+0x4c>
    return -1;
801063da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063df:	eb 7e                	jmp    8010645f <sys_pipe+0xca>
  fd0 = -1;
801063e1:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
801063e8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801063eb:	89 04 24             	mov    %eax,(%esp)
801063ee:	e8 67 f3 ff ff       	call   8010575a <fdalloc>
801063f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801063f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063fa:	78 14                	js     80106410 <sys_pipe+0x7b>
801063fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063ff:	89 04 24             	mov    %eax,(%esp)
80106402:	e8 53 f3 ff ff       	call   8010575a <fdalloc>
80106407:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010640a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010640e:	79 37                	jns    80106447 <sys_pipe+0xb2>
    if(fd0 >= 0)
80106410:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106414:	78 14                	js     8010642a <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106416:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010641c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010641f:	83 c2 08             	add    $0x8,%edx
80106422:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106429:	00 
    fileclose(rf);
8010642a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010642d:	89 04 24             	mov    %eax,(%esp)
80106430:	e8 99 ab ff ff       	call   80100fce <fileclose>
    fileclose(wf);
80106435:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106438:	89 04 24             	mov    %eax,(%esp)
8010643b:	e8 8e ab ff ff       	call   80100fce <fileclose>
    return -1;
80106440:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106445:	eb 18                	jmp    8010645f <sys_pipe+0xca>
  }
  fd[0] = fd0;
80106447:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010644a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010644d:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
8010644f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106452:	8d 50 04             	lea    0x4(%eax),%edx
80106455:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106458:	89 02                	mov    %eax,(%edx)
  return 0;
8010645a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010645f:	c9                   	leave  
80106460:	c3                   	ret    

80106461 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106461:	55                   	push   %ebp
80106462:	89 e5                	mov    %esp,%ebp
80106464:	83 ec 18             	sub    $0x18,%esp
  return fork(0, 0);
80106467:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010646e:	00 
8010646f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106476:	e8 b0 e1 ff ff       	call   8010462b <fork>
}
8010647b:	c9                   	leave  
8010647c:	c3                   	ret    

8010647d <sys_exit>:

int
sys_exit(void)
{
8010647d:	55                   	push   %ebp
8010647e:	89 e5                	mov    %esp,%ebp
80106480:	83 ec 08             	sub    $0x8,%esp
  exit();
80106483:	e8 46 e3 ff ff       	call   801047ce <exit>
  return 0;  // not reached
80106488:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010648d:	c9                   	leave  
8010648e:	c3                   	ret    

8010648f <sys_wait>:

int
sys_wait(void)
{
8010648f:	55                   	push   %ebp
80106490:	89 e5                	mov    %esp,%ebp
80106492:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106495:	e8 59 e4 ff ff       	call   801048f3 <wait>
}
8010649a:	c9                   	leave  
8010649b:	c3                   	ret    

8010649c <sys_kill>:

int
sys_kill(void)
{
8010649c:	55                   	push   %ebp
8010649d:	89 e5                	mov    %esp,%ebp
8010649f:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801064a2:	8d 45 f4             	lea    -0xc(%ebp),%eax
801064a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801064a9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064b0:	e8 da f0 ff ff       	call   8010558f <argint>
801064b5:	85 c0                	test   %eax,%eax
801064b7:	79 07                	jns    801064c0 <sys_kill+0x24>
    return -1;
801064b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064be:	eb 0b                	jmp    801064cb <sys_kill+0x2f>
  return kill(pid);
801064c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801064c3:	89 04 24             	mov    %eax,(%esp)
801064c6:	e8 3a e8 ff ff       	call   80104d05 <kill>
}
801064cb:	c9                   	leave  
801064cc:	c3                   	ret    

801064cd <sys_getpid>:

int
sys_getpid(void)
{
801064cd:	55                   	push   %ebp
801064ce:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801064d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064d6:	8b 40 10             	mov    0x10(%eax),%eax
}
801064d9:	5d                   	pop    %ebp
801064da:	c3                   	ret    

801064db <sys_sbrk>:

int
sys_sbrk(void)
{
801064db:	55                   	push   %ebp
801064dc:	89 e5                	mov    %esp,%ebp
801064de:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801064e1:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801064e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064ef:	e8 9b f0 ff ff       	call   8010558f <argint>
801064f4:	85 c0                	test   %eax,%eax
801064f6:	79 07                	jns    801064ff <sys_sbrk+0x24>
    return -1;
801064f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064fd:	eb 24                	jmp    80106523 <sys_sbrk+0x48>
  addr = proc->sz;
801064ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106505:	8b 00                	mov    (%eax),%eax
80106507:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010650a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010650d:	89 04 24             	mov    %eax,(%esp)
80106510:	e8 71 e0 ff ff       	call   80104586 <growproc>
80106515:	85 c0                	test   %eax,%eax
80106517:	79 07                	jns    80106520 <sys_sbrk+0x45>
    return -1;
80106519:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010651e:	eb 03                	jmp    80106523 <sys_sbrk+0x48>
  return addr;
80106520:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106523:	c9                   	leave  
80106524:	c3                   	ret    

80106525 <sys_sleep>:

int
sys_sleep(void)
{
80106525:	55                   	push   %ebp
80106526:	89 e5                	mov    %esp,%ebp
80106528:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010652b:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010652e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106532:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106539:	e8 51 f0 ff ff       	call   8010558f <argint>
8010653e:	85 c0                	test   %eax,%eax
80106540:	79 07                	jns    80106549 <sys_sleep+0x24>
    return -1;
80106542:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106547:	eb 6c                	jmp    801065b5 <sys_sleep+0x90>
  acquire(&tickslock);
80106549:	c7 04 24 a0 4a 11 80 	movl   $0x80114aa0,(%esp)
80106550:	e8 a4 ea ff ff       	call   80104ff9 <acquire>
  ticks0 = ticks;
80106555:	a1 e0 52 11 80       	mov    0x801152e0,%eax
8010655a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
8010655d:	eb 34                	jmp    80106593 <sys_sleep+0x6e>
    if(proc->killed){
8010655f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106565:	8b 40 24             	mov    0x24(%eax),%eax
80106568:	85 c0                	test   %eax,%eax
8010656a:	74 13                	je     8010657f <sys_sleep+0x5a>
      release(&tickslock);
8010656c:	c7 04 24 a0 4a 11 80 	movl   $0x80114aa0,(%esp)
80106573:	e8 e3 ea ff ff       	call   8010505b <release>
      return -1;
80106578:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010657d:	eb 36                	jmp    801065b5 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
8010657f:	c7 44 24 04 a0 4a 11 	movl   $0x80114aa0,0x4(%esp)
80106586:	80 
80106587:	c7 04 24 e0 52 11 80 	movl   $0x801152e0,(%esp)
8010658e:	e8 6b e6 ff ff       	call   80104bfe <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106593:	a1 e0 52 11 80       	mov    0x801152e0,%eax
80106598:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010659b:	89 c2                	mov    %eax,%edx
8010659d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801065a0:	39 c2                	cmp    %eax,%edx
801065a2:	72 bb                	jb     8010655f <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801065a4:	c7 04 24 a0 4a 11 80 	movl   $0x80114aa0,(%esp)
801065ab:	e8 ab ea ff ff       	call   8010505b <release>
  return 0;
801065b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801065b5:	c9                   	leave  
801065b6:	c3                   	ret    

801065b7 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801065b7:	55                   	push   %ebp
801065b8:	89 e5                	mov    %esp,%ebp
801065ba:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801065bd:	c7 04 24 a0 4a 11 80 	movl   $0x80114aa0,(%esp)
801065c4:	e8 30 ea ff ff       	call   80104ff9 <acquire>
  xticks = ticks;
801065c9:	a1 e0 52 11 80       	mov    0x801152e0,%eax
801065ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801065d1:	c7 04 24 a0 4a 11 80 	movl   $0x80114aa0,(%esp)
801065d8:	e8 7e ea ff ff       	call   8010505b <release>
  return xticks;
801065dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801065e0:	c9                   	leave  
801065e1:	c3                   	ret    

801065e2 <sys_cps>:

int
sys_cps(void)
{
801065e2:	55                   	push   %ebp
801065e3:	89 e5                	mov    %esp,%ebp
801065e5:	83 ec 08             	sub    $0x8,%esp
  return cps();
801065e8:	e8 8d e8 ff ff       	call   80104e7a <cps>
}
801065ed:	c9                   	leave  
801065ee:	c3                   	ret    

801065ef <sys_hello>:

int sys_hello(void)
{
801065ef:	55                   	push   %ebp
801065f0:	89 e5                	mov    %esp,%ebp
801065f2:	83 ec 28             	sub    $0x28,%esp
   int n;
   if(argint(0, &n) < 0)
801065f5:	8d 45 f4             	lea    -0xc(%ebp),%eax
801065f8:	89 44 24 04          	mov    %eax,0x4(%esp)
801065fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106603:	e8 87 ef ff ff       	call   8010558f <argint>
80106608:	85 c0                	test   %eax,%eax
8010660a:	79 07                	jns    80106613 <sys_hello+0x24>
    return -1;
8010660c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106611:	eb 18                	jmp    8010662b <sys_hello+0x3c>
   cprintf("Hello world!! %d \n",n);
80106613:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106616:	89 44 24 04          	mov    %eax,0x4(%esp)
8010661a:	c7 04 24 38 8b 10 80 	movl   $0x80108b38,(%esp)
80106621:	e8 7a 9d ff ff       	call   801003a0 <cprintf>
   return 0;
80106626:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010662b:	c9                   	leave  
8010662c:	c3                   	ret    

8010662d <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010662d:	55                   	push   %ebp
8010662e:	89 e5                	mov    %esp,%ebp
80106630:	83 ec 08             	sub    $0x8,%esp
80106633:	8b 55 08             	mov    0x8(%ebp),%edx
80106636:	8b 45 0c             	mov    0xc(%ebp),%eax
80106639:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010663d:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106640:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106644:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106648:	ee                   	out    %al,(%dx)
}
80106649:	c9                   	leave  
8010664a:	c3                   	ret    

8010664b <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
8010664b:	55                   	push   %ebp
8010664c:	89 e5                	mov    %esp,%ebp
8010664e:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106651:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106658:	00 
80106659:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
80106660:	e8 c8 ff ff ff       	call   8010662d <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106665:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
8010666c:	00 
8010666d:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106674:	e8 b4 ff ff ff       	call   8010662d <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106679:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
80106680:	00 
80106681:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106688:	e8 a0 ff ff ff       	call   8010662d <outb>
  picenable(IRQ_TIMER);
8010668d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106694:	e8 52 d7 ff ff       	call   80103deb <picenable>
}
80106699:	c9                   	leave  
8010669a:	c3                   	ret    

8010669b <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
8010669b:	1e                   	push   %ds
  pushl %es
8010669c:	06                   	push   %es
  pushl %fs
8010669d:	0f a0                	push   %fs
  pushl %gs
8010669f:	0f a8                	push   %gs
  pushal
801066a1:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801066a2:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801066a6:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801066a8:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801066aa:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801066ae:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801066b0:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801066b2:	54                   	push   %esp
  call trap
801066b3:	e8 d8 01 00 00       	call   80106890 <trap>
  addl $4, %esp
801066b8:	83 c4 04             	add    $0x4,%esp

801066bb <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
801066bb:	61                   	popa   
  popl %gs
801066bc:	0f a9                	pop    %gs
  popl %fs
801066be:	0f a1                	pop    %fs
  popl %es
801066c0:	07                   	pop    %es
  popl %ds
801066c1:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
801066c2:	83 c4 08             	add    $0x8,%esp
  iret
801066c5:	cf                   	iret   

801066c6 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
801066c6:	55                   	push   %ebp
801066c7:	89 e5                	mov    %esp,%ebp
801066c9:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801066cc:	8b 45 0c             	mov    0xc(%ebp),%eax
801066cf:	83 e8 01             	sub    $0x1,%eax
801066d2:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801066d6:	8b 45 08             	mov    0x8(%ebp),%eax
801066d9:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801066dd:	8b 45 08             	mov    0x8(%ebp),%eax
801066e0:	c1 e8 10             	shr    $0x10,%eax
801066e3:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801066e7:	8d 45 fa             	lea    -0x6(%ebp),%eax
801066ea:	0f 01 18             	lidtl  (%eax)
}
801066ed:	c9                   	leave  
801066ee:	c3                   	ret    

801066ef <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801066ef:	55                   	push   %ebp
801066f0:	89 e5                	mov    %esp,%ebp
801066f2:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801066f5:	0f 20 d0             	mov    %cr2,%eax
801066f8:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
801066fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801066fe:	c9                   	leave  
801066ff:	c3                   	ret    

80106700 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106700:	55                   	push   %ebp
80106701:	89 e5                	mov    %esp,%ebp
80106703:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106706:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010670d:	e9 c3 00 00 00       	jmp    801067d5 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106712:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106715:	8b 04 85 a0 b0 10 80 	mov    -0x7fef4f60(,%eax,4),%eax
8010671c:	89 c2                	mov    %eax,%edx
8010671e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106721:	66 89 14 c5 e0 4a 11 	mov    %dx,-0x7feeb520(,%eax,8)
80106728:	80 
80106729:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010672c:	66 c7 04 c5 e2 4a 11 	movw   $0x8,-0x7feeb51e(,%eax,8)
80106733:	80 08 00 
80106736:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106739:	0f b6 14 c5 e4 4a 11 	movzbl -0x7feeb51c(,%eax,8),%edx
80106740:	80 
80106741:	83 e2 e0             	and    $0xffffffe0,%edx
80106744:	88 14 c5 e4 4a 11 80 	mov    %dl,-0x7feeb51c(,%eax,8)
8010674b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010674e:	0f b6 14 c5 e4 4a 11 	movzbl -0x7feeb51c(,%eax,8),%edx
80106755:	80 
80106756:	83 e2 1f             	and    $0x1f,%edx
80106759:	88 14 c5 e4 4a 11 80 	mov    %dl,-0x7feeb51c(,%eax,8)
80106760:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106763:	0f b6 14 c5 e5 4a 11 	movzbl -0x7feeb51b(,%eax,8),%edx
8010676a:	80 
8010676b:	83 e2 f0             	and    $0xfffffff0,%edx
8010676e:	83 ca 0e             	or     $0xe,%edx
80106771:	88 14 c5 e5 4a 11 80 	mov    %dl,-0x7feeb51b(,%eax,8)
80106778:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010677b:	0f b6 14 c5 e5 4a 11 	movzbl -0x7feeb51b(,%eax,8),%edx
80106782:	80 
80106783:	83 e2 ef             	and    $0xffffffef,%edx
80106786:	88 14 c5 e5 4a 11 80 	mov    %dl,-0x7feeb51b(,%eax,8)
8010678d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106790:	0f b6 14 c5 e5 4a 11 	movzbl -0x7feeb51b(,%eax,8),%edx
80106797:	80 
80106798:	83 e2 9f             	and    $0xffffff9f,%edx
8010679b:	88 14 c5 e5 4a 11 80 	mov    %dl,-0x7feeb51b(,%eax,8)
801067a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067a5:	0f b6 14 c5 e5 4a 11 	movzbl -0x7feeb51b(,%eax,8),%edx
801067ac:	80 
801067ad:	83 ca 80             	or     $0xffffff80,%edx
801067b0:	88 14 c5 e5 4a 11 80 	mov    %dl,-0x7feeb51b(,%eax,8)
801067b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067ba:	8b 04 85 a0 b0 10 80 	mov    -0x7fef4f60(,%eax,4),%eax
801067c1:	c1 e8 10             	shr    $0x10,%eax
801067c4:	89 c2                	mov    %eax,%edx
801067c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c9:	66 89 14 c5 e6 4a 11 	mov    %dx,-0x7feeb51a(,%eax,8)
801067d0:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
801067d1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801067d5:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
801067dc:	0f 8e 30 ff ff ff    	jle    80106712 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
801067e2:	a1 a0 b1 10 80       	mov    0x8010b1a0,%eax
801067e7:	66 a3 e0 4c 11 80    	mov    %ax,0x80114ce0
801067ed:	66 c7 05 e2 4c 11 80 	movw   $0x8,0x80114ce2
801067f4:	08 00 
801067f6:	0f b6 05 e4 4c 11 80 	movzbl 0x80114ce4,%eax
801067fd:	83 e0 e0             	and    $0xffffffe0,%eax
80106800:	a2 e4 4c 11 80       	mov    %al,0x80114ce4
80106805:	0f b6 05 e4 4c 11 80 	movzbl 0x80114ce4,%eax
8010680c:	83 e0 1f             	and    $0x1f,%eax
8010680f:	a2 e4 4c 11 80       	mov    %al,0x80114ce4
80106814:	0f b6 05 e5 4c 11 80 	movzbl 0x80114ce5,%eax
8010681b:	83 c8 0f             	or     $0xf,%eax
8010681e:	a2 e5 4c 11 80       	mov    %al,0x80114ce5
80106823:	0f b6 05 e5 4c 11 80 	movzbl 0x80114ce5,%eax
8010682a:	83 e0 ef             	and    $0xffffffef,%eax
8010682d:	a2 e5 4c 11 80       	mov    %al,0x80114ce5
80106832:	0f b6 05 e5 4c 11 80 	movzbl 0x80114ce5,%eax
80106839:	83 c8 60             	or     $0x60,%eax
8010683c:	a2 e5 4c 11 80       	mov    %al,0x80114ce5
80106841:	0f b6 05 e5 4c 11 80 	movzbl 0x80114ce5,%eax
80106848:	83 c8 80             	or     $0xffffff80,%eax
8010684b:	a2 e5 4c 11 80       	mov    %al,0x80114ce5
80106850:	a1 a0 b1 10 80       	mov    0x8010b1a0,%eax
80106855:	c1 e8 10             	shr    $0x10,%eax
80106858:	66 a3 e6 4c 11 80    	mov    %ax,0x80114ce6
  
  initlock(&tickslock, "time");
8010685e:	c7 44 24 04 4c 8b 10 	movl   $0x80108b4c,0x4(%esp)
80106865:	80 
80106866:	c7 04 24 a0 4a 11 80 	movl   $0x80114aa0,(%esp)
8010686d:	e8 66 e7 ff ff       	call   80104fd8 <initlock>
}
80106872:	c9                   	leave  
80106873:	c3                   	ret    

80106874 <idtinit>:

void
idtinit(void)
{
80106874:	55                   	push   %ebp
80106875:	89 e5                	mov    %esp,%ebp
80106877:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
8010687a:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106881:	00 
80106882:	c7 04 24 e0 4a 11 80 	movl   $0x80114ae0,(%esp)
80106889:	e8 38 fe ff ff       	call   801066c6 <lidt>
}
8010688e:	c9                   	leave  
8010688f:	c3                   	ret    

80106890 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106890:	55                   	push   %ebp
80106891:	89 e5                	mov    %esp,%ebp
80106893:	57                   	push   %edi
80106894:	56                   	push   %esi
80106895:	53                   	push   %ebx
80106896:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106899:	8b 45 08             	mov    0x8(%ebp),%eax
8010689c:	8b 40 30             	mov    0x30(%eax),%eax
8010689f:	83 f8 40             	cmp    $0x40,%eax
801068a2:	75 3f                	jne    801068e3 <trap+0x53>
    if(proc->killed)
801068a4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801068aa:	8b 40 24             	mov    0x24(%eax),%eax
801068ad:	85 c0                	test   %eax,%eax
801068af:	74 05                	je     801068b6 <trap+0x26>
      exit();
801068b1:	e8 18 df ff ff       	call   801047ce <exit>
    proc->tf = tf;
801068b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801068bc:	8b 55 08             	mov    0x8(%ebp),%edx
801068bf:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
801068c2:	e8 8f ed ff ff       	call   80105656 <syscall>
    if(proc->killed)
801068c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801068cd:	8b 40 24             	mov    0x24(%eax),%eax
801068d0:	85 c0                	test   %eax,%eax
801068d2:	74 0a                	je     801068de <trap+0x4e>
      exit();
801068d4:	e8 f5 de ff ff       	call   801047ce <exit>
    return;
801068d9:	e9 2d 02 00 00       	jmp    80106b0b <trap+0x27b>
801068de:	e9 28 02 00 00       	jmp    80106b0b <trap+0x27b>
  }

  switch(tf->trapno){
801068e3:	8b 45 08             	mov    0x8(%ebp),%eax
801068e6:	8b 40 30             	mov    0x30(%eax),%eax
801068e9:	83 e8 20             	sub    $0x20,%eax
801068ec:	83 f8 1f             	cmp    $0x1f,%eax
801068ef:	0f 87 bc 00 00 00    	ja     801069b1 <trap+0x121>
801068f5:	8b 04 85 f4 8b 10 80 	mov    -0x7fef740c(,%eax,4),%eax
801068fc:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
801068fe:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106904:	0f b6 00             	movzbl (%eax),%eax
80106907:	84 c0                	test   %al,%al
80106909:	75 31                	jne    8010693c <trap+0xac>
      acquire(&tickslock);
8010690b:	c7 04 24 a0 4a 11 80 	movl   $0x80114aa0,(%esp)
80106912:	e8 e2 e6 ff ff       	call   80104ff9 <acquire>
      ticks++;
80106917:	a1 e0 52 11 80       	mov    0x801152e0,%eax
8010691c:	83 c0 01             	add    $0x1,%eax
8010691f:	a3 e0 52 11 80       	mov    %eax,0x801152e0
      wakeup(&ticks);
80106924:	c7 04 24 e0 52 11 80 	movl   $0x801152e0,(%esp)
8010692b:	e8 aa e3 ff ff       	call   80104cda <wakeup>
      release(&tickslock);
80106930:	c7 04 24 a0 4a 11 80 	movl   $0x80114aa0,(%esp)
80106937:	e8 1f e7 ff ff       	call   8010505b <release>
    }
    lapiceoi();
8010693c:	e8 c6 c5 ff ff       	call   80102f07 <lapiceoi>
    break;
80106941:	e9 41 01 00 00       	jmp    80106a87 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106946:	e8 ca bd ff ff       	call   80102715 <ideintr>
    lapiceoi();
8010694b:	e8 b7 c5 ff ff       	call   80102f07 <lapiceoi>
    break;
80106950:	e9 32 01 00 00       	jmp    80106a87 <trap+0x1f7>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106955:	e8 7c c3 ff ff       	call   80102cd6 <kbdintr>
    lapiceoi();
8010695a:	e8 a8 c5 ff ff       	call   80102f07 <lapiceoi>
    break;
8010695f:	e9 23 01 00 00       	jmp    80106a87 <trap+0x1f7>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106964:	e8 97 03 00 00       	call   80106d00 <uartintr>
    lapiceoi();
80106969:	e8 99 c5 ff ff       	call   80102f07 <lapiceoi>
    break;
8010696e:	e9 14 01 00 00       	jmp    80106a87 <trap+0x1f7>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106973:	8b 45 08             	mov    0x8(%ebp),%eax
80106976:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106979:	8b 45 08             	mov    0x8(%ebp),%eax
8010697c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106980:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106983:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106989:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010698c:	0f b6 c0             	movzbl %al,%eax
8010698f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106993:	89 54 24 08          	mov    %edx,0x8(%esp)
80106997:	89 44 24 04          	mov    %eax,0x4(%esp)
8010699b:	c7 04 24 54 8b 10 80 	movl   $0x80108b54,(%esp)
801069a2:	e8 f9 99 ff ff       	call   801003a0 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801069a7:	e8 5b c5 ff ff       	call   80102f07 <lapiceoi>
    break;
801069ac:	e9 d6 00 00 00       	jmp    80106a87 <trap+0x1f7>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801069b1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801069b7:	85 c0                	test   %eax,%eax
801069b9:	74 11                	je     801069cc <trap+0x13c>
801069bb:	8b 45 08             	mov    0x8(%ebp),%eax
801069be:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801069c2:	0f b7 c0             	movzwl %ax,%eax
801069c5:	83 e0 03             	and    $0x3,%eax
801069c8:	85 c0                	test   %eax,%eax
801069ca:	75 46                	jne    80106a12 <trap+0x182>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801069cc:	e8 1e fd ff ff       	call   801066ef <rcr2>
801069d1:	8b 55 08             	mov    0x8(%ebp),%edx
801069d4:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
801069d7:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
801069de:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801069e1:	0f b6 ca             	movzbl %dl,%ecx
801069e4:	8b 55 08             	mov    0x8(%ebp),%edx
801069e7:	8b 52 30             	mov    0x30(%edx),%edx
801069ea:	89 44 24 10          	mov    %eax,0x10(%esp)
801069ee:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801069f2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801069f6:	89 54 24 04          	mov    %edx,0x4(%esp)
801069fa:	c7 04 24 78 8b 10 80 	movl   $0x80108b78,(%esp)
80106a01:	e8 9a 99 ff ff       	call   801003a0 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106a06:	c7 04 24 aa 8b 10 80 	movl   $0x80108baa,(%esp)
80106a0d:	e8 28 9b ff ff       	call   8010053a <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106a12:	e8 d8 fc ff ff       	call   801066ef <rcr2>
80106a17:	89 c2                	mov    %eax,%edx
80106a19:	8b 45 08             	mov    0x8(%ebp),%eax
80106a1c:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106a1f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106a25:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106a28:	0f b6 f0             	movzbl %al,%esi
80106a2b:	8b 45 08             	mov    0x8(%ebp),%eax
80106a2e:	8b 58 34             	mov    0x34(%eax),%ebx
80106a31:	8b 45 08             	mov    0x8(%ebp),%eax
80106a34:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106a37:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a3d:	83 c0 6c             	add    $0x6c,%eax
80106a40:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106a43:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106a49:	8b 40 10             	mov    0x10(%eax),%eax
80106a4c:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106a50:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106a54:	89 74 24 14          	mov    %esi,0x14(%esp)
80106a58:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106a5c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106a60:	8b 75 e4             	mov    -0x1c(%ebp),%esi
80106a63:	89 74 24 08          	mov    %esi,0x8(%esp)
80106a67:	89 44 24 04          	mov    %eax,0x4(%esp)
80106a6b:	c7 04 24 b0 8b 10 80 	movl   $0x80108bb0,(%esp)
80106a72:	e8 29 99 ff ff       	call   801003a0 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106a77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a7d:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106a84:	eb 01                	jmp    80106a87 <trap+0x1f7>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106a86:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106a87:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a8d:	85 c0                	test   %eax,%eax
80106a8f:	74 24                	je     80106ab5 <trap+0x225>
80106a91:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106a97:	8b 40 24             	mov    0x24(%eax),%eax
80106a9a:	85 c0                	test   %eax,%eax
80106a9c:	74 17                	je     80106ab5 <trap+0x225>
80106a9e:	8b 45 08             	mov    0x8(%ebp),%eax
80106aa1:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106aa5:	0f b7 c0             	movzwl %ax,%eax
80106aa8:	83 e0 03             	and    $0x3,%eax
80106aab:	83 f8 03             	cmp    $0x3,%eax
80106aae:	75 05                	jne    80106ab5 <trap+0x225>
    exit();
80106ab0:	e8 19 dd ff ff       	call   801047ce <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106ab5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106abb:	85 c0                	test   %eax,%eax
80106abd:	74 1e                	je     80106add <trap+0x24d>
80106abf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ac5:	8b 40 0c             	mov    0xc(%eax),%eax
80106ac8:	83 f8 04             	cmp    $0x4,%eax
80106acb:	75 10                	jne    80106add <trap+0x24d>
80106acd:	8b 45 08             	mov    0x8(%ebp),%eax
80106ad0:	8b 40 30             	mov    0x30(%eax),%eax
80106ad3:	83 f8 20             	cmp    $0x20,%eax
80106ad6:	75 05                	jne    80106add <trap+0x24d>
    yield();
80106ad8:	e8 c3 e0 ff ff       	call   80104ba0 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106add:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106ae3:	85 c0                	test   %eax,%eax
80106ae5:	74 24                	je     80106b0b <trap+0x27b>
80106ae7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106aed:	8b 40 24             	mov    0x24(%eax),%eax
80106af0:	85 c0                	test   %eax,%eax
80106af2:	74 17                	je     80106b0b <trap+0x27b>
80106af4:	8b 45 08             	mov    0x8(%ebp),%eax
80106af7:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106afb:	0f b7 c0             	movzwl %ax,%eax
80106afe:	83 e0 03             	and    $0x3,%eax
80106b01:	83 f8 03             	cmp    $0x3,%eax
80106b04:	75 05                	jne    80106b0b <trap+0x27b>
    exit();
80106b06:	e8 c3 dc ff ff       	call   801047ce <exit>
}
80106b0b:	83 c4 3c             	add    $0x3c,%esp
80106b0e:	5b                   	pop    %ebx
80106b0f:	5e                   	pop    %esi
80106b10:	5f                   	pop    %edi
80106b11:	5d                   	pop    %ebp
80106b12:	c3                   	ret    

80106b13 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106b13:	55                   	push   %ebp
80106b14:	89 e5                	mov    %esp,%ebp
80106b16:	83 ec 14             	sub    $0x14,%esp
80106b19:	8b 45 08             	mov    0x8(%ebp),%eax
80106b1c:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106b20:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80106b24:	89 c2                	mov    %eax,%edx
80106b26:	ec                   	in     (%dx),%al
80106b27:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80106b2a:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80106b2e:	c9                   	leave  
80106b2f:	c3                   	ret    

80106b30 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106b30:	55                   	push   %ebp
80106b31:	89 e5                	mov    %esp,%ebp
80106b33:	83 ec 08             	sub    $0x8,%esp
80106b36:	8b 55 08             	mov    0x8(%ebp),%edx
80106b39:	8b 45 0c             	mov    0xc(%ebp),%eax
80106b3c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106b40:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106b43:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106b47:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106b4b:	ee                   	out    %al,(%dx)
}
80106b4c:	c9                   	leave  
80106b4d:	c3                   	ret    

80106b4e <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106b4e:	55                   	push   %ebp
80106b4f:	89 e5                	mov    %esp,%ebp
80106b51:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106b54:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b5b:	00 
80106b5c:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106b63:	e8 c8 ff ff ff       	call   80106b30 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106b68:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106b6f:	00 
80106b70:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106b77:	e8 b4 ff ff ff       	call   80106b30 <outb>
  outb(COM1+0, 115200/9600);
80106b7c:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106b83:	00 
80106b84:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106b8b:	e8 a0 ff ff ff       	call   80106b30 <outb>
  outb(COM1+1, 0);
80106b90:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106b97:	00 
80106b98:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106b9f:	e8 8c ff ff ff       	call   80106b30 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106ba4:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106bab:	00 
80106bac:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106bb3:	e8 78 ff ff ff       	call   80106b30 <outb>
  outb(COM1+4, 0);
80106bb8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106bbf:	00 
80106bc0:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106bc7:	e8 64 ff ff ff       	call   80106b30 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106bcc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106bd3:	00 
80106bd4:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106bdb:	e8 50 ff ff ff       	call   80106b30 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106be0:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106be7:	e8 27 ff ff ff       	call   80106b13 <inb>
80106bec:	3c ff                	cmp    $0xff,%al
80106bee:	75 02                	jne    80106bf2 <uartinit+0xa4>
    return;
80106bf0:	eb 6a                	jmp    80106c5c <uartinit+0x10e>
  uart = 1;
80106bf2:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106bf9:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106bfc:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106c03:	e8 0b ff ff ff       	call   80106b13 <inb>
  inb(COM1+0);
80106c08:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106c0f:	e8 ff fe ff ff       	call   80106b13 <inb>
  picenable(IRQ_COM1);
80106c14:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106c1b:	e8 cb d1 ff ff       	call   80103deb <picenable>
  ioapicenable(IRQ_COM1, 0);
80106c20:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106c27:	00 
80106c28:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106c2f:	e8 60 bd ff ff       	call   80102994 <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106c34:	c7 45 f4 74 8c 10 80 	movl   $0x80108c74,-0xc(%ebp)
80106c3b:	eb 15                	jmp    80106c52 <uartinit+0x104>
    uartputc(*p);
80106c3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c40:	0f b6 00             	movzbl (%eax),%eax
80106c43:	0f be c0             	movsbl %al,%eax
80106c46:	89 04 24             	mov    %eax,(%esp)
80106c49:	e8 10 00 00 00       	call   80106c5e <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106c4e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106c52:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c55:	0f b6 00             	movzbl (%eax),%eax
80106c58:	84 c0                	test   %al,%al
80106c5a:	75 e1                	jne    80106c3d <uartinit+0xef>
    uartputc(*p);
}
80106c5c:	c9                   	leave  
80106c5d:	c3                   	ret    

80106c5e <uartputc>:

void
uartputc(int c)
{
80106c5e:	55                   	push   %ebp
80106c5f:	89 e5                	mov    %esp,%ebp
80106c61:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106c64:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106c69:	85 c0                	test   %eax,%eax
80106c6b:	75 02                	jne    80106c6f <uartputc+0x11>
    return;
80106c6d:	eb 4b                	jmp    80106cba <uartputc+0x5c>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106c6f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106c76:	eb 10                	jmp    80106c88 <uartputc+0x2a>
    microdelay(10);
80106c78:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106c7f:	e8 a8 c2 ff ff       	call   80102f2c <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106c84:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106c88:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106c8c:	7f 16                	jg     80106ca4 <uartputc+0x46>
80106c8e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106c95:	e8 79 fe ff ff       	call   80106b13 <inb>
80106c9a:	0f b6 c0             	movzbl %al,%eax
80106c9d:	83 e0 20             	and    $0x20,%eax
80106ca0:	85 c0                	test   %eax,%eax
80106ca2:	74 d4                	je     80106c78 <uartputc+0x1a>
    microdelay(10);
  outb(COM1+0, c);
80106ca4:	8b 45 08             	mov    0x8(%ebp),%eax
80106ca7:	0f b6 c0             	movzbl %al,%eax
80106caa:	89 44 24 04          	mov    %eax,0x4(%esp)
80106cae:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106cb5:	e8 76 fe ff ff       	call   80106b30 <outb>
}
80106cba:	c9                   	leave  
80106cbb:	c3                   	ret    

80106cbc <uartgetc>:

static int
uartgetc(void)
{
80106cbc:	55                   	push   %ebp
80106cbd:	89 e5                	mov    %esp,%ebp
80106cbf:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106cc2:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106cc7:	85 c0                	test   %eax,%eax
80106cc9:	75 07                	jne    80106cd2 <uartgetc+0x16>
    return -1;
80106ccb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cd0:	eb 2c                	jmp    80106cfe <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106cd2:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106cd9:	e8 35 fe ff ff       	call   80106b13 <inb>
80106cde:	0f b6 c0             	movzbl %al,%eax
80106ce1:	83 e0 01             	and    $0x1,%eax
80106ce4:	85 c0                	test   %eax,%eax
80106ce6:	75 07                	jne    80106cef <uartgetc+0x33>
    return -1;
80106ce8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106ced:	eb 0f                	jmp    80106cfe <uartgetc+0x42>
  return inb(COM1+0);
80106cef:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106cf6:	e8 18 fe ff ff       	call   80106b13 <inb>
80106cfb:	0f b6 c0             	movzbl %al,%eax
}
80106cfe:	c9                   	leave  
80106cff:	c3                   	ret    

80106d00 <uartintr>:

void
uartintr(void)
{
80106d00:	55                   	push   %ebp
80106d01:	89 e5                	mov    %esp,%ebp
80106d03:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106d06:	c7 04 24 bc 6c 10 80 	movl   $0x80106cbc,(%esp)
80106d0d:	e8 9b 9a ff ff       	call   801007ad <consoleintr>
}
80106d12:	c9                   	leave  
80106d13:	c3                   	ret    

80106d14 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106d14:	6a 00                	push   $0x0
  pushl $0
80106d16:	6a 00                	push   $0x0
  jmp alltraps
80106d18:	e9 7e f9 ff ff       	jmp    8010669b <alltraps>

80106d1d <vector1>:
.globl vector1
vector1:
  pushl $0
80106d1d:	6a 00                	push   $0x0
  pushl $1
80106d1f:	6a 01                	push   $0x1
  jmp alltraps
80106d21:	e9 75 f9 ff ff       	jmp    8010669b <alltraps>

80106d26 <vector2>:
.globl vector2
vector2:
  pushl $0
80106d26:	6a 00                	push   $0x0
  pushl $2
80106d28:	6a 02                	push   $0x2
  jmp alltraps
80106d2a:	e9 6c f9 ff ff       	jmp    8010669b <alltraps>

80106d2f <vector3>:
.globl vector3
vector3:
  pushl $0
80106d2f:	6a 00                	push   $0x0
  pushl $3
80106d31:	6a 03                	push   $0x3
  jmp alltraps
80106d33:	e9 63 f9 ff ff       	jmp    8010669b <alltraps>

80106d38 <vector4>:
.globl vector4
vector4:
  pushl $0
80106d38:	6a 00                	push   $0x0
  pushl $4
80106d3a:	6a 04                	push   $0x4
  jmp alltraps
80106d3c:	e9 5a f9 ff ff       	jmp    8010669b <alltraps>

80106d41 <vector5>:
.globl vector5
vector5:
  pushl $0
80106d41:	6a 00                	push   $0x0
  pushl $5
80106d43:	6a 05                	push   $0x5
  jmp alltraps
80106d45:	e9 51 f9 ff ff       	jmp    8010669b <alltraps>

80106d4a <vector6>:
.globl vector6
vector6:
  pushl $0
80106d4a:	6a 00                	push   $0x0
  pushl $6
80106d4c:	6a 06                	push   $0x6
  jmp alltraps
80106d4e:	e9 48 f9 ff ff       	jmp    8010669b <alltraps>

80106d53 <vector7>:
.globl vector7
vector7:
  pushl $0
80106d53:	6a 00                	push   $0x0
  pushl $7
80106d55:	6a 07                	push   $0x7
  jmp alltraps
80106d57:	e9 3f f9 ff ff       	jmp    8010669b <alltraps>

80106d5c <vector8>:
.globl vector8
vector8:
  pushl $8
80106d5c:	6a 08                	push   $0x8
  jmp alltraps
80106d5e:	e9 38 f9 ff ff       	jmp    8010669b <alltraps>

80106d63 <vector9>:
.globl vector9
vector9:
  pushl $0
80106d63:	6a 00                	push   $0x0
  pushl $9
80106d65:	6a 09                	push   $0x9
  jmp alltraps
80106d67:	e9 2f f9 ff ff       	jmp    8010669b <alltraps>

80106d6c <vector10>:
.globl vector10
vector10:
  pushl $10
80106d6c:	6a 0a                	push   $0xa
  jmp alltraps
80106d6e:	e9 28 f9 ff ff       	jmp    8010669b <alltraps>

80106d73 <vector11>:
.globl vector11
vector11:
  pushl $11
80106d73:	6a 0b                	push   $0xb
  jmp alltraps
80106d75:	e9 21 f9 ff ff       	jmp    8010669b <alltraps>

80106d7a <vector12>:
.globl vector12
vector12:
  pushl $12
80106d7a:	6a 0c                	push   $0xc
  jmp alltraps
80106d7c:	e9 1a f9 ff ff       	jmp    8010669b <alltraps>

80106d81 <vector13>:
.globl vector13
vector13:
  pushl $13
80106d81:	6a 0d                	push   $0xd
  jmp alltraps
80106d83:	e9 13 f9 ff ff       	jmp    8010669b <alltraps>

80106d88 <vector14>:
.globl vector14
vector14:
  pushl $14
80106d88:	6a 0e                	push   $0xe
  jmp alltraps
80106d8a:	e9 0c f9 ff ff       	jmp    8010669b <alltraps>

80106d8f <vector15>:
.globl vector15
vector15:
  pushl $0
80106d8f:	6a 00                	push   $0x0
  pushl $15
80106d91:	6a 0f                	push   $0xf
  jmp alltraps
80106d93:	e9 03 f9 ff ff       	jmp    8010669b <alltraps>

80106d98 <vector16>:
.globl vector16
vector16:
  pushl $0
80106d98:	6a 00                	push   $0x0
  pushl $16
80106d9a:	6a 10                	push   $0x10
  jmp alltraps
80106d9c:	e9 fa f8 ff ff       	jmp    8010669b <alltraps>

80106da1 <vector17>:
.globl vector17
vector17:
  pushl $17
80106da1:	6a 11                	push   $0x11
  jmp alltraps
80106da3:	e9 f3 f8 ff ff       	jmp    8010669b <alltraps>

80106da8 <vector18>:
.globl vector18
vector18:
  pushl $0
80106da8:	6a 00                	push   $0x0
  pushl $18
80106daa:	6a 12                	push   $0x12
  jmp alltraps
80106dac:	e9 ea f8 ff ff       	jmp    8010669b <alltraps>

80106db1 <vector19>:
.globl vector19
vector19:
  pushl $0
80106db1:	6a 00                	push   $0x0
  pushl $19
80106db3:	6a 13                	push   $0x13
  jmp alltraps
80106db5:	e9 e1 f8 ff ff       	jmp    8010669b <alltraps>

80106dba <vector20>:
.globl vector20
vector20:
  pushl $0
80106dba:	6a 00                	push   $0x0
  pushl $20
80106dbc:	6a 14                	push   $0x14
  jmp alltraps
80106dbe:	e9 d8 f8 ff ff       	jmp    8010669b <alltraps>

80106dc3 <vector21>:
.globl vector21
vector21:
  pushl $0
80106dc3:	6a 00                	push   $0x0
  pushl $21
80106dc5:	6a 15                	push   $0x15
  jmp alltraps
80106dc7:	e9 cf f8 ff ff       	jmp    8010669b <alltraps>

80106dcc <vector22>:
.globl vector22
vector22:
  pushl $0
80106dcc:	6a 00                	push   $0x0
  pushl $22
80106dce:	6a 16                	push   $0x16
  jmp alltraps
80106dd0:	e9 c6 f8 ff ff       	jmp    8010669b <alltraps>

80106dd5 <vector23>:
.globl vector23
vector23:
  pushl $0
80106dd5:	6a 00                	push   $0x0
  pushl $23
80106dd7:	6a 17                	push   $0x17
  jmp alltraps
80106dd9:	e9 bd f8 ff ff       	jmp    8010669b <alltraps>

80106dde <vector24>:
.globl vector24
vector24:
  pushl $0
80106dde:	6a 00                	push   $0x0
  pushl $24
80106de0:	6a 18                	push   $0x18
  jmp alltraps
80106de2:	e9 b4 f8 ff ff       	jmp    8010669b <alltraps>

80106de7 <vector25>:
.globl vector25
vector25:
  pushl $0
80106de7:	6a 00                	push   $0x0
  pushl $25
80106de9:	6a 19                	push   $0x19
  jmp alltraps
80106deb:	e9 ab f8 ff ff       	jmp    8010669b <alltraps>

80106df0 <vector26>:
.globl vector26
vector26:
  pushl $0
80106df0:	6a 00                	push   $0x0
  pushl $26
80106df2:	6a 1a                	push   $0x1a
  jmp alltraps
80106df4:	e9 a2 f8 ff ff       	jmp    8010669b <alltraps>

80106df9 <vector27>:
.globl vector27
vector27:
  pushl $0
80106df9:	6a 00                	push   $0x0
  pushl $27
80106dfb:	6a 1b                	push   $0x1b
  jmp alltraps
80106dfd:	e9 99 f8 ff ff       	jmp    8010669b <alltraps>

80106e02 <vector28>:
.globl vector28
vector28:
  pushl $0
80106e02:	6a 00                	push   $0x0
  pushl $28
80106e04:	6a 1c                	push   $0x1c
  jmp alltraps
80106e06:	e9 90 f8 ff ff       	jmp    8010669b <alltraps>

80106e0b <vector29>:
.globl vector29
vector29:
  pushl $0
80106e0b:	6a 00                	push   $0x0
  pushl $29
80106e0d:	6a 1d                	push   $0x1d
  jmp alltraps
80106e0f:	e9 87 f8 ff ff       	jmp    8010669b <alltraps>

80106e14 <vector30>:
.globl vector30
vector30:
  pushl $0
80106e14:	6a 00                	push   $0x0
  pushl $30
80106e16:	6a 1e                	push   $0x1e
  jmp alltraps
80106e18:	e9 7e f8 ff ff       	jmp    8010669b <alltraps>

80106e1d <vector31>:
.globl vector31
vector31:
  pushl $0
80106e1d:	6a 00                	push   $0x0
  pushl $31
80106e1f:	6a 1f                	push   $0x1f
  jmp alltraps
80106e21:	e9 75 f8 ff ff       	jmp    8010669b <alltraps>

80106e26 <vector32>:
.globl vector32
vector32:
  pushl $0
80106e26:	6a 00                	push   $0x0
  pushl $32
80106e28:	6a 20                	push   $0x20
  jmp alltraps
80106e2a:	e9 6c f8 ff ff       	jmp    8010669b <alltraps>

80106e2f <vector33>:
.globl vector33
vector33:
  pushl $0
80106e2f:	6a 00                	push   $0x0
  pushl $33
80106e31:	6a 21                	push   $0x21
  jmp alltraps
80106e33:	e9 63 f8 ff ff       	jmp    8010669b <alltraps>

80106e38 <vector34>:
.globl vector34
vector34:
  pushl $0
80106e38:	6a 00                	push   $0x0
  pushl $34
80106e3a:	6a 22                	push   $0x22
  jmp alltraps
80106e3c:	e9 5a f8 ff ff       	jmp    8010669b <alltraps>

80106e41 <vector35>:
.globl vector35
vector35:
  pushl $0
80106e41:	6a 00                	push   $0x0
  pushl $35
80106e43:	6a 23                	push   $0x23
  jmp alltraps
80106e45:	e9 51 f8 ff ff       	jmp    8010669b <alltraps>

80106e4a <vector36>:
.globl vector36
vector36:
  pushl $0
80106e4a:	6a 00                	push   $0x0
  pushl $36
80106e4c:	6a 24                	push   $0x24
  jmp alltraps
80106e4e:	e9 48 f8 ff ff       	jmp    8010669b <alltraps>

80106e53 <vector37>:
.globl vector37
vector37:
  pushl $0
80106e53:	6a 00                	push   $0x0
  pushl $37
80106e55:	6a 25                	push   $0x25
  jmp alltraps
80106e57:	e9 3f f8 ff ff       	jmp    8010669b <alltraps>

80106e5c <vector38>:
.globl vector38
vector38:
  pushl $0
80106e5c:	6a 00                	push   $0x0
  pushl $38
80106e5e:	6a 26                	push   $0x26
  jmp alltraps
80106e60:	e9 36 f8 ff ff       	jmp    8010669b <alltraps>

80106e65 <vector39>:
.globl vector39
vector39:
  pushl $0
80106e65:	6a 00                	push   $0x0
  pushl $39
80106e67:	6a 27                	push   $0x27
  jmp alltraps
80106e69:	e9 2d f8 ff ff       	jmp    8010669b <alltraps>

80106e6e <vector40>:
.globl vector40
vector40:
  pushl $0
80106e6e:	6a 00                	push   $0x0
  pushl $40
80106e70:	6a 28                	push   $0x28
  jmp alltraps
80106e72:	e9 24 f8 ff ff       	jmp    8010669b <alltraps>

80106e77 <vector41>:
.globl vector41
vector41:
  pushl $0
80106e77:	6a 00                	push   $0x0
  pushl $41
80106e79:	6a 29                	push   $0x29
  jmp alltraps
80106e7b:	e9 1b f8 ff ff       	jmp    8010669b <alltraps>

80106e80 <vector42>:
.globl vector42
vector42:
  pushl $0
80106e80:	6a 00                	push   $0x0
  pushl $42
80106e82:	6a 2a                	push   $0x2a
  jmp alltraps
80106e84:	e9 12 f8 ff ff       	jmp    8010669b <alltraps>

80106e89 <vector43>:
.globl vector43
vector43:
  pushl $0
80106e89:	6a 00                	push   $0x0
  pushl $43
80106e8b:	6a 2b                	push   $0x2b
  jmp alltraps
80106e8d:	e9 09 f8 ff ff       	jmp    8010669b <alltraps>

80106e92 <vector44>:
.globl vector44
vector44:
  pushl $0
80106e92:	6a 00                	push   $0x0
  pushl $44
80106e94:	6a 2c                	push   $0x2c
  jmp alltraps
80106e96:	e9 00 f8 ff ff       	jmp    8010669b <alltraps>

80106e9b <vector45>:
.globl vector45
vector45:
  pushl $0
80106e9b:	6a 00                	push   $0x0
  pushl $45
80106e9d:	6a 2d                	push   $0x2d
  jmp alltraps
80106e9f:	e9 f7 f7 ff ff       	jmp    8010669b <alltraps>

80106ea4 <vector46>:
.globl vector46
vector46:
  pushl $0
80106ea4:	6a 00                	push   $0x0
  pushl $46
80106ea6:	6a 2e                	push   $0x2e
  jmp alltraps
80106ea8:	e9 ee f7 ff ff       	jmp    8010669b <alltraps>

80106ead <vector47>:
.globl vector47
vector47:
  pushl $0
80106ead:	6a 00                	push   $0x0
  pushl $47
80106eaf:	6a 2f                	push   $0x2f
  jmp alltraps
80106eb1:	e9 e5 f7 ff ff       	jmp    8010669b <alltraps>

80106eb6 <vector48>:
.globl vector48
vector48:
  pushl $0
80106eb6:	6a 00                	push   $0x0
  pushl $48
80106eb8:	6a 30                	push   $0x30
  jmp alltraps
80106eba:	e9 dc f7 ff ff       	jmp    8010669b <alltraps>

80106ebf <vector49>:
.globl vector49
vector49:
  pushl $0
80106ebf:	6a 00                	push   $0x0
  pushl $49
80106ec1:	6a 31                	push   $0x31
  jmp alltraps
80106ec3:	e9 d3 f7 ff ff       	jmp    8010669b <alltraps>

80106ec8 <vector50>:
.globl vector50
vector50:
  pushl $0
80106ec8:	6a 00                	push   $0x0
  pushl $50
80106eca:	6a 32                	push   $0x32
  jmp alltraps
80106ecc:	e9 ca f7 ff ff       	jmp    8010669b <alltraps>

80106ed1 <vector51>:
.globl vector51
vector51:
  pushl $0
80106ed1:	6a 00                	push   $0x0
  pushl $51
80106ed3:	6a 33                	push   $0x33
  jmp alltraps
80106ed5:	e9 c1 f7 ff ff       	jmp    8010669b <alltraps>

80106eda <vector52>:
.globl vector52
vector52:
  pushl $0
80106eda:	6a 00                	push   $0x0
  pushl $52
80106edc:	6a 34                	push   $0x34
  jmp alltraps
80106ede:	e9 b8 f7 ff ff       	jmp    8010669b <alltraps>

80106ee3 <vector53>:
.globl vector53
vector53:
  pushl $0
80106ee3:	6a 00                	push   $0x0
  pushl $53
80106ee5:	6a 35                	push   $0x35
  jmp alltraps
80106ee7:	e9 af f7 ff ff       	jmp    8010669b <alltraps>

80106eec <vector54>:
.globl vector54
vector54:
  pushl $0
80106eec:	6a 00                	push   $0x0
  pushl $54
80106eee:	6a 36                	push   $0x36
  jmp alltraps
80106ef0:	e9 a6 f7 ff ff       	jmp    8010669b <alltraps>

80106ef5 <vector55>:
.globl vector55
vector55:
  pushl $0
80106ef5:	6a 00                	push   $0x0
  pushl $55
80106ef7:	6a 37                	push   $0x37
  jmp alltraps
80106ef9:	e9 9d f7 ff ff       	jmp    8010669b <alltraps>

80106efe <vector56>:
.globl vector56
vector56:
  pushl $0
80106efe:	6a 00                	push   $0x0
  pushl $56
80106f00:	6a 38                	push   $0x38
  jmp alltraps
80106f02:	e9 94 f7 ff ff       	jmp    8010669b <alltraps>

80106f07 <vector57>:
.globl vector57
vector57:
  pushl $0
80106f07:	6a 00                	push   $0x0
  pushl $57
80106f09:	6a 39                	push   $0x39
  jmp alltraps
80106f0b:	e9 8b f7 ff ff       	jmp    8010669b <alltraps>

80106f10 <vector58>:
.globl vector58
vector58:
  pushl $0
80106f10:	6a 00                	push   $0x0
  pushl $58
80106f12:	6a 3a                	push   $0x3a
  jmp alltraps
80106f14:	e9 82 f7 ff ff       	jmp    8010669b <alltraps>

80106f19 <vector59>:
.globl vector59
vector59:
  pushl $0
80106f19:	6a 00                	push   $0x0
  pushl $59
80106f1b:	6a 3b                	push   $0x3b
  jmp alltraps
80106f1d:	e9 79 f7 ff ff       	jmp    8010669b <alltraps>

80106f22 <vector60>:
.globl vector60
vector60:
  pushl $0
80106f22:	6a 00                	push   $0x0
  pushl $60
80106f24:	6a 3c                	push   $0x3c
  jmp alltraps
80106f26:	e9 70 f7 ff ff       	jmp    8010669b <alltraps>

80106f2b <vector61>:
.globl vector61
vector61:
  pushl $0
80106f2b:	6a 00                	push   $0x0
  pushl $61
80106f2d:	6a 3d                	push   $0x3d
  jmp alltraps
80106f2f:	e9 67 f7 ff ff       	jmp    8010669b <alltraps>

80106f34 <vector62>:
.globl vector62
vector62:
  pushl $0
80106f34:	6a 00                	push   $0x0
  pushl $62
80106f36:	6a 3e                	push   $0x3e
  jmp alltraps
80106f38:	e9 5e f7 ff ff       	jmp    8010669b <alltraps>

80106f3d <vector63>:
.globl vector63
vector63:
  pushl $0
80106f3d:	6a 00                	push   $0x0
  pushl $63
80106f3f:	6a 3f                	push   $0x3f
  jmp alltraps
80106f41:	e9 55 f7 ff ff       	jmp    8010669b <alltraps>

80106f46 <vector64>:
.globl vector64
vector64:
  pushl $0
80106f46:	6a 00                	push   $0x0
  pushl $64
80106f48:	6a 40                	push   $0x40
  jmp alltraps
80106f4a:	e9 4c f7 ff ff       	jmp    8010669b <alltraps>

80106f4f <vector65>:
.globl vector65
vector65:
  pushl $0
80106f4f:	6a 00                	push   $0x0
  pushl $65
80106f51:	6a 41                	push   $0x41
  jmp alltraps
80106f53:	e9 43 f7 ff ff       	jmp    8010669b <alltraps>

80106f58 <vector66>:
.globl vector66
vector66:
  pushl $0
80106f58:	6a 00                	push   $0x0
  pushl $66
80106f5a:	6a 42                	push   $0x42
  jmp alltraps
80106f5c:	e9 3a f7 ff ff       	jmp    8010669b <alltraps>

80106f61 <vector67>:
.globl vector67
vector67:
  pushl $0
80106f61:	6a 00                	push   $0x0
  pushl $67
80106f63:	6a 43                	push   $0x43
  jmp alltraps
80106f65:	e9 31 f7 ff ff       	jmp    8010669b <alltraps>

80106f6a <vector68>:
.globl vector68
vector68:
  pushl $0
80106f6a:	6a 00                	push   $0x0
  pushl $68
80106f6c:	6a 44                	push   $0x44
  jmp alltraps
80106f6e:	e9 28 f7 ff ff       	jmp    8010669b <alltraps>

80106f73 <vector69>:
.globl vector69
vector69:
  pushl $0
80106f73:	6a 00                	push   $0x0
  pushl $69
80106f75:	6a 45                	push   $0x45
  jmp alltraps
80106f77:	e9 1f f7 ff ff       	jmp    8010669b <alltraps>

80106f7c <vector70>:
.globl vector70
vector70:
  pushl $0
80106f7c:	6a 00                	push   $0x0
  pushl $70
80106f7e:	6a 46                	push   $0x46
  jmp alltraps
80106f80:	e9 16 f7 ff ff       	jmp    8010669b <alltraps>

80106f85 <vector71>:
.globl vector71
vector71:
  pushl $0
80106f85:	6a 00                	push   $0x0
  pushl $71
80106f87:	6a 47                	push   $0x47
  jmp alltraps
80106f89:	e9 0d f7 ff ff       	jmp    8010669b <alltraps>

80106f8e <vector72>:
.globl vector72
vector72:
  pushl $0
80106f8e:	6a 00                	push   $0x0
  pushl $72
80106f90:	6a 48                	push   $0x48
  jmp alltraps
80106f92:	e9 04 f7 ff ff       	jmp    8010669b <alltraps>

80106f97 <vector73>:
.globl vector73
vector73:
  pushl $0
80106f97:	6a 00                	push   $0x0
  pushl $73
80106f99:	6a 49                	push   $0x49
  jmp alltraps
80106f9b:	e9 fb f6 ff ff       	jmp    8010669b <alltraps>

80106fa0 <vector74>:
.globl vector74
vector74:
  pushl $0
80106fa0:	6a 00                	push   $0x0
  pushl $74
80106fa2:	6a 4a                	push   $0x4a
  jmp alltraps
80106fa4:	e9 f2 f6 ff ff       	jmp    8010669b <alltraps>

80106fa9 <vector75>:
.globl vector75
vector75:
  pushl $0
80106fa9:	6a 00                	push   $0x0
  pushl $75
80106fab:	6a 4b                	push   $0x4b
  jmp alltraps
80106fad:	e9 e9 f6 ff ff       	jmp    8010669b <alltraps>

80106fb2 <vector76>:
.globl vector76
vector76:
  pushl $0
80106fb2:	6a 00                	push   $0x0
  pushl $76
80106fb4:	6a 4c                	push   $0x4c
  jmp alltraps
80106fb6:	e9 e0 f6 ff ff       	jmp    8010669b <alltraps>

80106fbb <vector77>:
.globl vector77
vector77:
  pushl $0
80106fbb:	6a 00                	push   $0x0
  pushl $77
80106fbd:	6a 4d                	push   $0x4d
  jmp alltraps
80106fbf:	e9 d7 f6 ff ff       	jmp    8010669b <alltraps>

80106fc4 <vector78>:
.globl vector78
vector78:
  pushl $0
80106fc4:	6a 00                	push   $0x0
  pushl $78
80106fc6:	6a 4e                	push   $0x4e
  jmp alltraps
80106fc8:	e9 ce f6 ff ff       	jmp    8010669b <alltraps>

80106fcd <vector79>:
.globl vector79
vector79:
  pushl $0
80106fcd:	6a 00                	push   $0x0
  pushl $79
80106fcf:	6a 4f                	push   $0x4f
  jmp alltraps
80106fd1:	e9 c5 f6 ff ff       	jmp    8010669b <alltraps>

80106fd6 <vector80>:
.globl vector80
vector80:
  pushl $0
80106fd6:	6a 00                	push   $0x0
  pushl $80
80106fd8:	6a 50                	push   $0x50
  jmp alltraps
80106fda:	e9 bc f6 ff ff       	jmp    8010669b <alltraps>

80106fdf <vector81>:
.globl vector81
vector81:
  pushl $0
80106fdf:	6a 00                	push   $0x0
  pushl $81
80106fe1:	6a 51                	push   $0x51
  jmp alltraps
80106fe3:	e9 b3 f6 ff ff       	jmp    8010669b <alltraps>

80106fe8 <vector82>:
.globl vector82
vector82:
  pushl $0
80106fe8:	6a 00                	push   $0x0
  pushl $82
80106fea:	6a 52                	push   $0x52
  jmp alltraps
80106fec:	e9 aa f6 ff ff       	jmp    8010669b <alltraps>

80106ff1 <vector83>:
.globl vector83
vector83:
  pushl $0
80106ff1:	6a 00                	push   $0x0
  pushl $83
80106ff3:	6a 53                	push   $0x53
  jmp alltraps
80106ff5:	e9 a1 f6 ff ff       	jmp    8010669b <alltraps>

80106ffa <vector84>:
.globl vector84
vector84:
  pushl $0
80106ffa:	6a 00                	push   $0x0
  pushl $84
80106ffc:	6a 54                	push   $0x54
  jmp alltraps
80106ffe:	e9 98 f6 ff ff       	jmp    8010669b <alltraps>

80107003 <vector85>:
.globl vector85
vector85:
  pushl $0
80107003:	6a 00                	push   $0x0
  pushl $85
80107005:	6a 55                	push   $0x55
  jmp alltraps
80107007:	e9 8f f6 ff ff       	jmp    8010669b <alltraps>

8010700c <vector86>:
.globl vector86
vector86:
  pushl $0
8010700c:	6a 00                	push   $0x0
  pushl $86
8010700e:	6a 56                	push   $0x56
  jmp alltraps
80107010:	e9 86 f6 ff ff       	jmp    8010669b <alltraps>

80107015 <vector87>:
.globl vector87
vector87:
  pushl $0
80107015:	6a 00                	push   $0x0
  pushl $87
80107017:	6a 57                	push   $0x57
  jmp alltraps
80107019:	e9 7d f6 ff ff       	jmp    8010669b <alltraps>

8010701e <vector88>:
.globl vector88
vector88:
  pushl $0
8010701e:	6a 00                	push   $0x0
  pushl $88
80107020:	6a 58                	push   $0x58
  jmp alltraps
80107022:	e9 74 f6 ff ff       	jmp    8010669b <alltraps>

80107027 <vector89>:
.globl vector89
vector89:
  pushl $0
80107027:	6a 00                	push   $0x0
  pushl $89
80107029:	6a 59                	push   $0x59
  jmp alltraps
8010702b:	e9 6b f6 ff ff       	jmp    8010669b <alltraps>

80107030 <vector90>:
.globl vector90
vector90:
  pushl $0
80107030:	6a 00                	push   $0x0
  pushl $90
80107032:	6a 5a                	push   $0x5a
  jmp alltraps
80107034:	e9 62 f6 ff ff       	jmp    8010669b <alltraps>

80107039 <vector91>:
.globl vector91
vector91:
  pushl $0
80107039:	6a 00                	push   $0x0
  pushl $91
8010703b:	6a 5b                	push   $0x5b
  jmp alltraps
8010703d:	e9 59 f6 ff ff       	jmp    8010669b <alltraps>

80107042 <vector92>:
.globl vector92
vector92:
  pushl $0
80107042:	6a 00                	push   $0x0
  pushl $92
80107044:	6a 5c                	push   $0x5c
  jmp alltraps
80107046:	e9 50 f6 ff ff       	jmp    8010669b <alltraps>

8010704b <vector93>:
.globl vector93
vector93:
  pushl $0
8010704b:	6a 00                	push   $0x0
  pushl $93
8010704d:	6a 5d                	push   $0x5d
  jmp alltraps
8010704f:	e9 47 f6 ff ff       	jmp    8010669b <alltraps>

80107054 <vector94>:
.globl vector94
vector94:
  pushl $0
80107054:	6a 00                	push   $0x0
  pushl $94
80107056:	6a 5e                	push   $0x5e
  jmp alltraps
80107058:	e9 3e f6 ff ff       	jmp    8010669b <alltraps>

8010705d <vector95>:
.globl vector95
vector95:
  pushl $0
8010705d:	6a 00                	push   $0x0
  pushl $95
8010705f:	6a 5f                	push   $0x5f
  jmp alltraps
80107061:	e9 35 f6 ff ff       	jmp    8010669b <alltraps>

80107066 <vector96>:
.globl vector96
vector96:
  pushl $0
80107066:	6a 00                	push   $0x0
  pushl $96
80107068:	6a 60                	push   $0x60
  jmp alltraps
8010706a:	e9 2c f6 ff ff       	jmp    8010669b <alltraps>

8010706f <vector97>:
.globl vector97
vector97:
  pushl $0
8010706f:	6a 00                	push   $0x0
  pushl $97
80107071:	6a 61                	push   $0x61
  jmp alltraps
80107073:	e9 23 f6 ff ff       	jmp    8010669b <alltraps>

80107078 <vector98>:
.globl vector98
vector98:
  pushl $0
80107078:	6a 00                	push   $0x0
  pushl $98
8010707a:	6a 62                	push   $0x62
  jmp alltraps
8010707c:	e9 1a f6 ff ff       	jmp    8010669b <alltraps>

80107081 <vector99>:
.globl vector99
vector99:
  pushl $0
80107081:	6a 00                	push   $0x0
  pushl $99
80107083:	6a 63                	push   $0x63
  jmp alltraps
80107085:	e9 11 f6 ff ff       	jmp    8010669b <alltraps>

8010708a <vector100>:
.globl vector100
vector100:
  pushl $0
8010708a:	6a 00                	push   $0x0
  pushl $100
8010708c:	6a 64                	push   $0x64
  jmp alltraps
8010708e:	e9 08 f6 ff ff       	jmp    8010669b <alltraps>

80107093 <vector101>:
.globl vector101
vector101:
  pushl $0
80107093:	6a 00                	push   $0x0
  pushl $101
80107095:	6a 65                	push   $0x65
  jmp alltraps
80107097:	e9 ff f5 ff ff       	jmp    8010669b <alltraps>

8010709c <vector102>:
.globl vector102
vector102:
  pushl $0
8010709c:	6a 00                	push   $0x0
  pushl $102
8010709e:	6a 66                	push   $0x66
  jmp alltraps
801070a0:	e9 f6 f5 ff ff       	jmp    8010669b <alltraps>

801070a5 <vector103>:
.globl vector103
vector103:
  pushl $0
801070a5:	6a 00                	push   $0x0
  pushl $103
801070a7:	6a 67                	push   $0x67
  jmp alltraps
801070a9:	e9 ed f5 ff ff       	jmp    8010669b <alltraps>

801070ae <vector104>:
.globl vector104
vector104:
  pushl $0
801070ae:	6a 00                	push   $0x0
  pushl $104
801070b0:	6a 68                	push   $0x68
  jmp alltraps
801070b2:	e9 e4 f5 ff ff       	jmp    8010669b <alltraps>

801070b7 <vector105>:
.globl vector105
vector105:
  pushl $0
801070b7:	6a 00                	push   $0x0
  pushl $105
801070b9:	6a 69                	push   $0x69
  jmp alltraps
801070bb:	e9 db f5 ff ff       	jmp    8010669b <alltraps>

801070c0 <vector106>:
.globl vector106
vector106:
  pushl $0
801070c0:	6a 00                	push   $0x0
  pushl $106
801070c2:	6a 6a                	push   $0x6a
  jmp alltraps
801070c4:	e9 d2 f5 ff ff       	jmp    8010669b <alltraps>

801070c9 <vector107>:
.globl vector107
vector107:
  pushl $0
801070c9:	6a 00                	push   $0x0
  pushl $107
801070cb:	6a 6b                	push   $0x6b
  jmp alltraps
801070cd:	e9 c9 f5 ff ff       	jmp    8010669b <alltraps>

801070d2 <vector108>:
.globl vector108
vector108:
  pushl $0
801070d2:	6a 00                	push   $0x0
  pushl $108
801070d4:	6a 6c                	push   $0x6c
  jmp alltraps
801070d6:	e9 c0 f5 ff ff       	jmp    8010669b <alltraps>

801070db <vector109>:
.globl vector109
vector109:
  pushl $0
801070db:	6a 00                	push   $0x0
  pushl $109
801070dd:	6a 6d                	push   $0x6d
  jmp alltraps
801070df:	e9 b7 f5 ff ff       	jmp    8010669b <alltraps>

801070e4 <vector110>:
.globl vector110
vector110:
  pushl $0
801070e4:	6a 00                	push   $0x0
  pushl $110
801070e6:	6a 6e                	push   $0x6e
  jmp alltraps
801070e8:	e9 ae f5 ff ff       	jmp    8010669b <alltraps>

801070ed <vector111>:
.globl vector111
vector111:
  pushl $0
801070ed:	6a 00                	push   $0x0
  pushl $111
801070ef:	6a 6f                	push   $0x6f
  jmp alltraps
801070f1:	e9 a5 f5 ff ff       	jmp    8010669b <alltraps>

801070f6 <vector112>:
.globl vector112
vector112:
  pushl $0
801070f6:	6a 00                	push   $0x0
  pushl $112
801070f8:	6a 70                	push   $0x70
  jmp alltraps
801070fa:	e9 9c f5 ff ff       	jmp    8010669b <alltraps>

801070ff <vector113>:
.globl vector113
vector113:
  pushl $0
801070ff:	6a 00                	push   $0x0
  pushl $113
80107101:	6a 71                	push   $0x71
  jmp alltraps
80107103:	e9 93 f5 ff ff       	jmp    8010669b <alltraps>

80107108 <vector114>:
.globl vector114
vector114:
  pushl $0
80107108:	6a 00                	push   $0x0
  pushl $114
8010710a:	6a 72                	push   $0x72
  jmp alltraps
8010710c:	e9 8a f5 ff ff       	jmp    8010669b <alltraps>

80107111 <vector115>:
.globl vector115
vector115:
  pushl $0
80107111:	6a 00                	push   $0x0
  pushl $115
80107113:	6a 73                	push   $0x73
  jmp alltraps
80107115:	e9 81 f5 ff ff       	jmp    8010669b <alltraps>

8010711a <vector116>:
.globl vector116
vector116:
  pushl $0
8010711a:	6a 00                	push   $0x0
  pushl $116
8010711c:	6a 74                	push   $0x74
  jmp alltraps
8010711e:	e9 78 f5 ff ff       	jmp    8010669b <alltraps>

80107123 <vector117>:
.globl vector117
vector117:
  pushl $0
80107123:	6a 00                	push   $0x0
  pushl $117
80107125:	6a 75                	push   $0x75
  jmp alltraps
80107127:	e9 6f f5 ff ff       	jmp    8010669b <alltraps>

8010712c <vector118>:
.globl vector118
vector118:
  pushl $0
8010712c:	6a 00                	push   $0x0
  pushl $118
8010712e:	6a 76                	push   $0x76
  jmp alltraps
80107130:	e9 66 f5 ff ff       	jmp    8010669b <alltraps>

80107135 <vector119>:
.globl vector119
vector119:
  pushl $0
80107135:	6a 00                	push   $0x0
  pushl $119
80107137:	6a 77                	push   $0x77
  jmp alltraps
80107139:	e9 5d f5 ff ff       	jmp    8010669b <alltraps>

8010713e <vector120>:
.globl vector120
vector120:
  pushl $0
8010713e:	6a 00                	push   $0x0
  pushl $120
80107140:	6a 78                	push   $0x78
  jmp alltraps
80107142:	e9 54 f5 ff ff       	jmp    8010669b <alltraps>

80107147 <vector121>:
.globl vector121
vector121:
  pushl $0
80107147:	6a 00                	push   $0x0
  pushl $121
80107149:	6a 79                	push   $0x79
  jmp alltraps
8010714b:	e9 4b f5 ff ff       	jmp    8010669b <alltraps>

80107150 <vector122>:
.globl vector122
vector122:
  pushl $0
80107150:	6a 00                	push   $0x0
  pushl $122
80107152:	6a 7a                	push   $0x7a
  jmp alltraps
80107154:	e9 42 f5 ff ff       	jmp    8010669b <alltraps>

80107159 <vector123>:
.globl vector123
vector123:
  pushl $0
80107159:	6a 00                	push   $0x0
  pushl $123
8010715b:	6a 7b                	push   $0x7b
  jmp alltraps
8010715d:	e9 39 f5 ff ff       	jmp    8010669b <alltraps>

80107162 <vector124>:
.globl vector124
vector124:
  pushl $0
80107162:	6a 00                	push   $0x0
  pushl $124
80107164:	6a 7c                	push   $0x7c
  jmp alltraps
80107166:	e9 30 f5 ff ff       	jmp    8010669b <alltraps>

8010716b <vector125>:
.globl vector125
vector125:
  pushl $0
8010716b:	6a 00                	push   $0x0
  pushl $125
8010716d:	6a 7d                	push   $0x7d
  jmp alltraps
8010716f:	e9 27 f5 ff ff       	jmp    8010669b <alltraps>

80107174 <vector126>:
.globl vector126
vector126:
  pushl $0
80107174:	6a 00                	push   $0x0
  pushl $126
80107176:	6a 7e                	push   $0x7e
  jmp alltraps
80107178:	e9 1e f5 ff ff       	jmp    8010669b <alltraps>

8010717d <vector127>:
.globl vector127
vector127:
  pushl $0
8010717d:	6a 00                	push   $0x0
  pushl $127
8010717f:	6a 7f                	push   $0x7f
  jmp alltraps
80107181:	e9 15 f5 ff ff       	jmp    8010669b <alltraps>

80107186 <vector128>:
.globl vector128
vector128:
  pushl $0
80107186:	6a 00                	push   $0x0
  pushl $128
80107188:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010718d:	e9 09 f5 ff ff       	jmp    8010669b <alltraps>

80107192 <vector129>:
.globl vector129
vector129:
  pushl $0
80107192:	6a 00                	push   $0x0
  pushl $129
80107194:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107199:	e9 fd f4 ff ff       	jmp    8010669b <alltraps>

8010719e <vector130>:
.globl vector130
vector130:
  pushl $0
8010719e:	6a 00                	push   $0x0
  pushl $130
801071a0:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801071a5:	e9 f1 f4 ff ff       	jmp    8010669b <alltraps>

801071aa <vector131>:
.globl vector131
vector131:
  pushl $0
801071aa:	6a 00                	push   $0x0
  pushl $131
801071ac:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801071b1:	e9 e5 f4 ff ff       	jmp    8010669b <alltraps>

801071b6 <vector132>:
.globl vector132
vector132:
  pushl $0
801071b6:	6a 00                	push   $0x0
  pushl $132
801071b8:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801071bd:	e9 d9 f4 ff ff       	jmp    8010669b <alltraps>

801071c2 <vector133>:
.globl vector133
vector133:
  pushl $0
801071c2:	6a 00                	push   $0x0
  pushl $133
801071c4:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801071c9:	e9 cd f4 ff ff       	jmp    8010669b <alltraps>

801071ce <vector134>:
.globl vector134
vector134:
  pushl $0
801071ce:	6a 00                	push   $0x0
  pushl $134
801071d0:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801071d5:	e9 c1 f4 ff ff       	jmp    8010669b <alltraps>

801071da <vector135>:
.globl vector135
vector135:
  pushl $0
801071da:	6a 00                	push   $0x0
  pushl $135
801071dc:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801071e1:	e9 b5 f4 ff ff       	jmp    8010669b <alltraps>

801071e6 <vector136>:
.globl vector136
vector136:
  pushl $0
801071e6:	6a 00                	push   $0x0
  pushl $136
801071e8:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801071ed:	e9 a9 f4 ff ff       	jmp    8010669b <alltraps>

801071f2 <vector137>:
.globl vector137
vector137:
  pushl $0
801071f2:	6a 00                	push   $0x0
  pushl $137
801071f4:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801071f9:	e9 9d f4 ff ff       	jmp    8010669b <alltraps>

801071fe <vector138>:
.globl vector138
vector138:
  pushl $0
801071fe:	6a 00                	push   $0x0
  pushl $138
80107200:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80107205:	e9 91 f4 ff ff       	jmp    8010669b <alltraps>

8010720a <vector139>:
.globl vector139
vector139:
  pushl $0
8010720a:	6a 00                	push   $0x0
  pushl $139
8010720c:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80107211:	e9 85 f4 ff ff       	jmp    8010669b <alltraps>

80107216 <vector140>:
.globl vector140
vector140:
  pushl $0
80107216:	6a 00                	push   $0x0
  pushl $140
80107218:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010721d:	e9 79 f4 ff ff       	jmp    8010669b <alltraps>

80107222 <vector141>:
.globl vector141
vector141:
  pushl $0
80107222:	6a 00                	push   $0x0
  pushl $141
80107224:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107229:	e9 6d f4 ff ff       	jmp    8010669b <alltraps>

8010722e <vector142>:
.globl vector142
vector142:
  pushl $0
8010722e:	6a 00                	push   $0x0
  pushl $142
80107230:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107235:	e9 61 f4 ff ff       	jmp    8010669b <alltraps>

8010723a <vector143>:
.globl vector143
vector143:
  pushl $0
8010723a:	6a 00                	push   $0x0
  pushl $143
8010723c:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107241:	e9 55 f4 ff ff       	jmp    8010669b <alltraps>

80107246 <vector144>:
.globl vector144
vector144:
  pushl $0
80107246:	6a 00                	push   $0x0
  pushl $144
80107248:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010724d:	e9 49 f4 ff ff       	jmp    8010669b <alltraps>

80107252 <vector145>:
.globl vector145
vector145:
  pushl $0
80107252:	6a 00                	push   $0x0
  pushl $145
80107254:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107259:	e9 3d f4 ff ff       	jmp    8010669b <alltraps>

8010725e <vector146>:
.globl vector146
vector146:
  pushl $0
8010725e:	6a 00                	push   $0x0
  pushl $146
80107260:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107265:	e9 31 f4 ff ff       	jmp    8010669b <alltraps>

8010726a <vector147>:
.globl vector147
vector147:
  pushl $0
8010726a:	6a 00                	push   $0x0
  pushl $147
8010726c:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107271:	e9 25 f4 ff ff       	jmp    8010669b <alltraps>

80107276 <vector148>:
.globl vector148
vector148:
  pushl $0
80107276:	6a 00                	push   $0x0
  pushl $148
80107278:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010727d:	e9 19 f4 ff ff       	jmp    8010669b <alltraps>

80107282 <vector149>:
.globl vector149
vector149:
  pushl $0
80107282:	6a 00                	push   $0x0
  pushl $149
80107284:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107289:	e9 0d f4 ff ff       	jmp    8010669b <alltraps>

8010728e <vector150>:
.globl vector150
vector150:
  pushl $0
8010728e:	6a 00                	push   $0x0
  pushl $150
80107290:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107295:	e9 01 f4 ff ff       	jmp    8010669b <alltraps>

8010729a <vector151>:
.globl vector151
vector151:
  pushl $0
8010729a:	6a 00                	push   $0x0
  pushl $151
8010729c:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801072a1:	e9 f5 f3 ff ff       	jmp    8010669b <alltraps>

801072a6 <vector152>:
.globl vector152
vector152:
  pushl $0
801072a6:	6a 00                	push   $0x0
  pushl $152
801072a8:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801072ad:	e9 e9 f3 ff ff       	jmp    8010669b <alltraps>

801072b2 <vector153>:
.globl vector153
vector153:
  pushl $0
801072b2:	6a 00                	push   $0x0
  pushl $153
801072b4:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801072b9:	e9 dd f3 ff ff       	jmp    8010669b <alltraps>

801072be <vector154>:
.globl vector154
vector154:
  pushl $0
801072be:	6a 00                	push   $0x0
  pushl $154
801072c0:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801072c5:	e9 d1 f3 ff ff       	jmp    8010669b <alltraps>

801072ca <vector155>:
.globl vector155
vector155:
  pushl $0
801072ca:	6a 00                	push   $0x0
  pushl $155
801072cc:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801072d1:	e9 c5 f3 ff ff       	jmp    8010669b <alltraps>

801072d6 <vector156>:
.globl vector156
vector156:
  pushl $0
801072d6:	6a 00                	push   $0x0
  pushl $156
801072d8:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801072dd:	e9 b9 f3 ff ff       	jmp    8010669b <alltraps>

801072e2 <vector157>:
.globl vector157
vector157:
  pushl $0
801072e2:	6a 00                	push   $0x0
  pushl $157
801072e4:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801072e9:	e9 ad f3 ff ff       	jmp    8010669b <alltraps>

801072ee <vector158>:
.globl vector158
vector158:
  pushl $0
801072ee:	6a 00                	push   $0x0
  pushl $158
801072f0:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801072f5:	e9 a1 f3 ff ff       	jmp    8010669b <alltraps>

801072fa <vector159>:
.globl vector159
vector159:
  pushl $0
801072fa:	6a 00                	push   $0x0
  pushl $159
801072fc:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80107301:	e9 95 f3 ff ff       	jmp    8010669b <alltraps>

80107306 <vector160>:
.globl vector160
vector160:
  pushl $0
80107306:	6a 00                	push   $0x0
  pushl $160
80107308:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010730d:	e9 89 f3 ff ff       	jmp    8010669b <alltraps>

80107312 <vector161>:
.globl vector161
vector161:
  pushl $0
80107312:	6a 00                	push   $0x0
  pushl $161
80107314:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107319:	e9 7d f3 ff ff       	jmp    8010669b <alltraps>

8010731e <vector162>:
.globl vector162
vector162:
  pushl $0
8010731e:	6a 00                	push   $0x0
  pushl $162
80107320:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107325:	e9 71 f3 ff ff       	jmp    8010669b <alltraps>

8010732a <vector163>:
.globl vector163
vector163:
  pushl $0
8010732a:	6a 00                	push   $0x0
  pushl $163
8010732c:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107331:	e9 65 f3 ff ff       	jmp    8010669b <alltraps>

80107336 <vector164>:
.globl vector164
vector164:
  pushl $0
80107336:	6a 00                	push   $0x0
  pushl $164
80107338:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010733d:	e9 59 f3 ff ff       	jmp    8010669b <alltraps>

80107342 <vector165>:
.globl vector165
vector165:
  pushl $0
80107342:	6a 00                	push   $0x0
  pushl $165
80107344:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107349:	e9 4d f3 ff ff       	jmp    8010669b <alltraps>

8010734e <vector166>:
.globl vector166
vector166:
  pushl $0
8010734e:	6a 00                	push   $0x0
  pushl $166
80107350:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107355:	e9 41 f3 ff ff       	jmp    8010669b <alltraps>

8010735a <vector167>:
.globl vector167
vector167:
  pushl $0
8010735a:	6a 00                	push   $0x0
  pushl $167
8010735c:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107361:	e9 35 f3 ff ff       	jmp    8010669b <alltraps>

80107366 <vector168>:
.globl vector168
vector168:
  pushl $0
80107366:	6a 00                	push   $0x0
  pushl $168
80107368:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010736d:	e9 29 f3 ff ff       	jmp    8010669b <alltraps>

80107372 <vector169>:
.globl vector169
vector169:
  pushl $0
80107372:	6a 00                	push   $0x0
  pushl $169
80107374:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107379:	e9 1d f3 ff ff       	jmp    8010669b <alltraps>

8010737e <vector170>:
.globl vector170
vector170:
  pushl $0
8010737e:	6a 00                	push   $0x0
  pushl $170
80107380:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107385:	e9 11 f3 ff ff       	jmp    8010669b <alltraps>

8010738a <vector171>:
.globl vector171
vector171:
  pushl $0
8010738a:	6a 00                	push   $0x0
  pushl $171
8010738c:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107391:	e9 05 f3 ff ff       	jmp    8010669b <alltraps>

80107396 <vector172>:
.globl vector172
vector172:
  pushl $0
80107396:	6a 00                	push   $0x0
  pushl $172
80107398:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
8010739d:	e9 f9 f2 ff ff       	jmp    8010669b <alltraps>

801073a2 <vector173>:
.globl vector173
vector173:
  pushl $0
801073a2:	6a 00                	push   $0x0
  pushl $173
801073a4:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801073a9:	e9 ed f2 ff ff       	jmp    8010669b <alltraps>

801073ae <vector174>:
.globl vector174
vector174:
  pushl $0
801073ae:	6a 00                	push   $0x0
  pushl $174
801073b0:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801073b5:	e9 e1 f2 ff ff       	jmp    8010669b <alltraps>

801073ba <vector175>:
.globl vector175
vector175:
  pushl $0
801073ba:	6a 00                	push   $0x0
  pushl $175
801073bc:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801073c1:	e9 d5 f2 ff ff       	jmp    8010669b <alltraps>

801073c6 <vector176>:
.globl vector176
vector176:
  pushl $0
801073c6:	6a 00                	push   $0x0
  pushl $176
801073c8:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801073cd:	e9 c9 f2 ff ff       	jmp    8010669b <alltraps>

801073d2 <vector177>:
.globl vector177
vector177:
  pushl $0
801073d2:	6a 00                	push   $0x0
  pushl $177
801073d4:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801073d9:	e9 bd f2 ff ff       	jmp    8010669b <alltraps>

801073de <vector178>:
.globl vector178
vector178:
  pushl $0
801073de:	6a 00                	push   $0x0
  pushl $178
801073e0:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801073e5:	e9 b1 f2 ff ff       	jmp    8010669b <alltraps>

801073ea <vector179>:
.globl vector179
vector179:
  pushl $0
801073ea:	6a 00                	push   $0x0
  pushl $179
801073ec:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801073f1:	e9 a5 f2 ff ff       	jmp    8010669b <alltraps>

801073f6 <vector180>:
.globl vector180
vector180:
  pushl $0
801073f6:	6a 00                	push   $0x0
  pushl $180
801073f8:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801073fd:	e9 99 f2 ff ff       	jmp    8010669b <alltraps>

80107402 <vector181>:
.globl vector181
vector181:
  pushl $0
80107402:	6a 00                	push   $0x0
  pushl $181
80107404:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107409:	e9 8d f2 ff ff       	jmp    8010669b <alltraps>

8010740e <vector182>:
.globl vector182
vector182:
  pushl $0
8010740e:	6a 00                	push   $0x0
  pushl $182
80107410:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107415:	e9 81 f2 ff ff       	jmp    8010669b <alltraps>

8010741a <vector183>:
.globl vector183
vector183:
  pushl $0
8010741a:	6a 00                	push   $0x0
  pushl $183
8010741c:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107421:	e9 75 f2 ff ff       	jmp    8010669b <alltraps>

80107426 <vector184>:
.globl vector184
vector184:
  pushl $0
80107426:	6a 00                	push   $0x0
  pushl $184
80107428:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010742d:	e9 69 f2 ff ff       	jmp    8010669b <alltraps>

80107432 <vector185>:
.globl vector185
vector185:
  pushl $0
80107432:	6a 00                	push   $0x0
  pushl $185
80107434:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107439:	e9 5d f2 ff ff       	jmp    8010669b <alltraps>

8010743e <vector186>:
.globl vector186
vector186:
  pushl $0
8010743e:	6a 00                	push   $0x0
  pushl $186
80107440:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107445:	e9 51 f2 ff ff       	jmp    8010669b <alltraps>

8010744a <vector187>:
.globl vector187
vector187:
  pushl $0
8010744a:	6a 00                	push   $0x0
  pushl $187
8010744c:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107451:	e9 45 f2 ff ff       	jmp    8010669b <alltraps>

80107456 <vector188>:
.globl vector188
vector188:
  pushl $0
80107456:	6a 00                	push   $0x0
  pushl $188
80107458:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
8010745d:	e9 39 f2 ff ff       	jmp    8010669b <alltraps>

80107462 <vector189>:
.globl vector189
vector189:
  pushl $0
80107462:	6a 00                	push   $0x0
  pushl $189
80107464:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107469:	e9 2d f2 ff ff       	jmp    8010669b <alltraps>

8010746e <vector190>:
.globl vector190
vector190:
  pushl $0
8010746e:	6a 00                	push   $0x0
  pushl $190
80107470:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107475:	e9 21 f2 ff ff       	jmp    8010669b <alltraps>

8010747a <vector191>:
.globl vector191
vector191:
  pushl $0
8010747a:	6a 00                	push   $0x0
  pushl $191
8010747c:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107481:	e9 15 f2 ff ff       	jmp    8010669b <alltraps>

80107486 <vector192>:
.globl vector192
vector192:
  pushl $0
80107486:	6a 00                	push   $0x0
  pushl $192
80107488:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
8010748d:	e9 09 f2 ff ff       	jmp    8010669b <alltraps>

80107492 <vector193>:
.globl vector193
vector193:
  pushl $0
80107492:	6a 00                	push   $0x0
  pushl $193
80107494:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107499:	e9 fd f1 ff ff       	jmp    8010669b <alltraps>

8010749e <vector194>:
.globl vector194
vector194:
  pushl $0
8010749e:	6a 00                	push   $0x0
  pushl $194
801074a0:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
801074a5:	e9 f1 f1 ff ff       	jmp    8010669b <alltraps>

801074aa <vector195>:
.globl vector195
vector195:
  pushl $0
801074aa:	6a 00                	push   $0x0
  pushl $195
801074ac:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
801074b1:	e9 e5 f1 ff ff       	jmp    8010669b <alltraps>

801074b6 <vector196>:
.globl vector196
vector196:
  pushl $0
801074b6:	6a 00                	push   $0x0
  pushl $196
801074b8:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801074bd:	e9 d9 f1 ff ff       	jmp    8010669b <alltraps>

801074c2 <vector197>:
.globl vector197
vector197:
  pushl $0
801074c2:	6a 00                	push   $0x0
  pushl $197
801074c4:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801074c9:	e9 cd f1 ff ff       	jmp    8010669b <alltraps>

801074ce <vector198>:
.globl vector198
vector198:
  pushl $0
801074ce:	6a 00                	push   $0x0
  pushl $198
801074d0:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801074d5:	e9 c1 f1 ff ff       	jmp    8010669b <alltraps>

801074da <vector199>:
.globl vector199
vector199:
  pushl $0
801074da:	6a 00                	push   $0x0
  pushl $199
801074dc:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801074e1:	e9 b5 f1 ff ff       	jmp    8010669b <alltraps>

801074e6 <vector200>:
.globl vector200
vector200:
  pushl $0
801074e6:	6a 00                	push   $0x0
  pushl $200
801074e8:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801074ed:	e9 a9 f1 ff ff       	jmp    8010669b <alltraps>

801074f2 <vector201>:
.globl vector201
vector201:
  pushl $0
801074f2:	6a 00                	push   $0x0
  pushl $201
801074f4:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801074f9:	e9 9d f1 ff ff       	jmp    8010669b <alltraps>

801074fe <vector202>:
.globl vector202
vector202:
  pushl $0
801074fe:	6a 00                	push   $0x0
  pushl $202
80107500:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107505:	e9 91 f1 ff ff       	jmp    8010669b <alltraps>

8010750a <vector203>:
.globl vector203
vector203:
  pushl $0
8010750a:	6a 00                	push   $0x0
  pushl $203
8010750c:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107511:	e9 85 f1 ff ff       	jmp    8010669b <alltraps>

80107516 <vector204>:
.globl vector204
vector204:
  pushl $0
80107516:	6a 00                	push   $0x0
  pushl $204
80107518:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
8010751d:	e9 79 f1 ff ff       	jmp    8010669b <alltraps>

80107522 <vector205>:
.globl vector205
vector205:
  pushl $0
80107522:	6a 00                	push   $0x0
  pushl $205
80107524:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107529:	e9 6d f1 ff ff       	jmp    8010669b <alltraps>

8010752e <vector206>:
.globl vector206
vector206:
  pushl $0
8010752e:	6a 00                	push   $0x0
  pushl $206
80107530:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107535:	e9 61 f1 ff ff       	jmp    8010669b <alltraps>

8010753a <vector207>:
.globl vector207
vector207:
  pushl $0
8010753a:	6a 00                	push   $0x0
  pushl $207
8010753c:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107541:	e9 55 f1 ff ff       	jmp    8010669b <alltraps>

80107546 <vector208>:
.globl vector208
vector208:
  pushl $0
80107546:	6a 00                	push   $0x0
  pushl $208
80107548:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
8010754d:	e9 49 f1 ff ff       	jmp    8010669b <alltraps>

80107552 <vector209>:
.globl vector209
vector209:
  pushl $0
80107552:	6a 00                	push   $0x0
  pushl $209
80107554:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107559:	e9 3d f1 ff ff       	jmp    8010669b <alltraps>

8010755e <vector210>:
.globl vector210
vector210:
  pushl $0
8010755e:	6a 00                	push   $0x0
  pushl $210
80107560:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107565:	e9 31 f1 ff ff       	jmp    8010669b <alltraps>

8010756a <vector211>:
.globl vector211
vector211:
  pushl $0
8010756a:	6a 00                	push   $0x0
  pushl $211
8010756c:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107571:	e9 25 f1 ff ff       	jmp    8010669b <alltraps>

80107576 <vector212>:
.globl vector212
vector212:
  pushl $0
80107576:	6a 00                	push   $0x0
  pushl $212
80107578:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
8010757d:	e9 19 f1 ff ff       	jmp    8010669b <alltraps>

80107582 <vector213>:
.globl vector213
vector213:
  pushl $0
80107582:	6a 00                	push   $0x0
  pushl $213
80107584:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107589:	e9 0d f1 ff ff       	jmp    8010669b <alltraps>

8010758e <vector214>:
.globl vector214
vector214:
  pushl $0
8010758e:	6a 00                	push   $0x0
  pushl $214
80107590:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107595:	e9 01 f1 ff ff       	jmp    8010669b <alltraps>

8010759a <vector215>:
.globl vector215
vector215:
  pushl $0
8010759a:	6a 00                	push   $0x0
  pushl $215
8010759c:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
801075a1:	e9 f5 f0 ff ff       	jmp    8010669b <alltraps>

801075a6 <vector216>:
.globl vector216
vector216:
  pushl $0
801075a6:	6a 00                	push   $0x0
  pushl $216
801075a8:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
801075ad:	e9 e9 f0 ff ff       	jmp    8010669b <alltraps>

801075b2 <vector217>:
.globl vector217
vector217:
  pushl $0
801075b2:	6a 00                	push   $0x0
  pushl $217
801075b4:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801075b9:	e9 dd f0 ff ff       	jmp    8010669b <alltraps>

801075be <vector218>:
.globl vector218
vector218:
  pushl $0
801075be:	6a 00                	push   $0x0
  pushl $218
801075c0:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801075c5:	e9 d1 f0 ff ff       	jmp    8010669b <alltraps>

801075ca <vector219>:
.globl vector219
vector219:
  pushl $0
801075ca:	6a 00                	push   $0x0
  pushl $219
801075cc:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801075d1:	e9 c5 f0 ff ff       	jmp    8010669b <alltraps>

801075d6 <vector220>:
.globl vector220
vector220:
  pushl $0
801075d6:	6a 00                	push   $0x0
  pushl $220
801075d8:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801075dd:	e9 b9 f0 ff ff       	jmp    8010669b <alltraps>

801075e2 <vector221>:
.globl vector221
vector221:
  pushl $0
801075e2:	6a 00                	push   $0x0
  pushl $221
801075e4:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801075e9:	e9 ad f0 ff ff       	jmp    8010669b <alltraps>

801075ee <vector222>:
.globl vector222
vector222:
  pushl $0
801075ee:	6a 00                	push   $0x0
  pushl $222
801075f0:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801075f5:	e9 a1 f0 ff ff       	jmp    8010669b <alltraps>

801075fa <vector223>:
.globl vector223
vector223:
  pushl $0
801075fa:	6a 00                	push   $0x0
  pushl $223
801075fc:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107601:	e9 95 f0 ff ff       	jmp    8010669b <alltraps>

80107606 <vector224>:
.globl vector224
vector224:
  pushl $0
80107606:	6a 00                	push   $0x0
  pushl $224
80107608:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
8010760d:	e9 89 f0 ff ff       	jmp    8010669b <alltraps>

80107612 <vector225>:
.globl vector225
vector225:
  pushl $0
80107612:	6a 00                	push   $0x0
  pushl $225
80107614:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107619:	e9 7d f0 ff ff       	jmp    8010669b <alltraps>

8010761e <vector226>:
.globl vector226
vector226:
  pushl $0
8010761e:	6a 00                	push   $0x0
  pushl $226
80107620:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107625:	e9 71 f0 ff ff       	jmp    8010669b <alltraps>

8010762a <vector227>:
.globl vector227
vector227:
  pushl $0
8010762a:	6a 00                	push   $0x0
  pushl $227
8010762c:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107631:	e9 65 f0 ff ff       	jmp    8010669b <alltraps>

80107636 <vector228>:
.globl vector228
vector228:
  pushl $0
80107636:	6a 00                	push   $0x0
  pushl $228
80107638:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
8010763d:	e9 59 f0 ff ff       	jmp    8010669b <alltraps>

80107642 <vector229>:
.globl vector229
vector229:
  pushl $0
80107642:	6a 00                	push   $0x0
  pushl $229
80107644:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107649:	e9 4d f0 ff ff       	jmp    8010669b <alltraps>

8010764e <vector230>:
.globl vector230
vector230:
  pushl $0
8010764e:	6a 00                	push   $0x0
  pushl $230
80107650:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107655:	e9 41 f0 ff ff       	jmp    8010669b <alltraps>

8010765a <vector231>:
.globl vector231
vector231:
  pushl $0
8010765a:	6a 00                	push   $0x0
  pushl $231
8010765c:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107661:	e9 35 f0 ff ff       	jmp    8010669b <alltraps>

80107666 <vector232>:
.globl vector232
vector232:
  pushl $0
80107666:	6a 00                	push   $0x0
  pushl $232
80107668:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
8010766d:	e9 29 f0 ff ff       	jmp    8010669b <alltraps>

80107672 <vector233>:
.globl vector233
vector233:
  pushl $0
80107672:	6a 00                	push   $0x0
  pushl $233
80107674:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107679:	e9 1d f0 ff ff       	jmp    8010669b <alltraps>

8010767e <vector234>:
.globl vector234
vector234:
  pushl $0
8010767e:	6a 00                	push   $0x0
  pushl $234
80107680:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107685:	e9 11 f0 ff ff       	jmp    8010669b <alltraps>

8010768a <vector235>:
.globl vector235
vector235:
  pushl $0
8010768a:	6a 00                	push   $0x0
  pushl $235
8010768c:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107691:	e9 05 f0 ff ff       	jmp    8010669b <alltraps>

80107696 <vector236>:
.globl vector236
vector236:
  pushl $0
80107696:	6a 00                	push   $0x0
  pushl $236
80107698:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
8010769d:	e9 f9 ef ff ff       	jmp    8010669b <alltraps>

801076a2 <vector237>:
.globl vector237
vector237:
  pushl $0
801076a2:	6a 00                	push   $0x0
  pushl $237
801076a4:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
801076a9:	e9 ed ef ff ff       	jmp    8010669b <alltraps>

801076ae <vector238>:
.globl vector238
vector238:
  pushl $0
801076ae:	6a 00                	push   $0x0
  pushl $238
801076b0:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801076b5:	e9 e1 ef ff ff       	jmp    8010669b <alltraps>

801076ba <vector239>:
.globl vector239
vector239:
  pushl $0
801076ba:	6a 00                	push   $0x0
  pushl $239
801076bc:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801076c1:	e9 d5 ef ff ff       	jmp    8010669b <alltraps>

801076c6 <vector240>:
.globl vector240
vector240:
  pushl $0
801076c6:	6a 00                	push   $0x0
  pushl $240
801076c8:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801076cd:	e9 c9 ef ff ff       	jmp    8010669b <alltraps>

801076d2 <vector241>:
.globl vector241
vector241:
  pushl $0
801076d2:	6a 00                	push   $0x0
  pushl $241
801076d4:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801076d9:	e9 bd ef ff ff       	jmp    8010669b <alltraps>

801076de <vector242>:
.globl vector242
vector242:
  pushl $0
801076de:	6a 00                	push   $0x0
  pushl $242
801076e0:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801076e5:	e9 b1 ef ff ff       	jmp    8010669b <alltraps>

801076ea <vector243>:
.globl vector243
vector243:
  pushl $0
801076ea:	6a 00                	push   $0x0
  pushl $243
801076ec:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801076f1:	e9 a5 ef ff ff       	jmp    8010669b <alltraps>

801076f6 <vector244>:
.globl vector244
vector244:
  pushl $0
801076f6:	6a 00                	push   $0x0
  pushl $244
801076f8:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801076fd:	e9 99 ef ff ff       	jmp    8010669b <alltraps>

80107702 <vector245>:
.globl vector245
vector245:
  pushl $0
80107702:	6a 00                	push   $0x0
  pushl $245
80107704:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107709:	e9 8d ef ff ff       	jmp    8010669b <alltraps>

8010770e <vector246>:
.globl vector246
vector246:
  pushl $0
8010770e:	6a 00                	push   $0x0
  pushl $246
80107710:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107715:	e9 81 ef ff ff       	jmp    8010669b <alltraps>

8010771a <vector247>:
.globl vector247
vector247:
  pushl $0
8010771a:	6a 00                	push   $0x0
  pushl $247
8010771c:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107721:	e9 75 ef ff ff       	jmp    8010669b <alltraps>

80107726 <vector248>:
.globl vector248
vector248:
  pushl $0
80107726:	6a 00                	push   $0x0
  pushl $248
80107728:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010772d:	e9 69 ef ff ff       	jmp    8010669b <alltraps>

80107732 <vector249>:
.globl vector249
vector249:
  pushl $0
80107732:	6a 00                	push   $0x0
  pushl $249
80107734:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107739:	e9 5d ef ff ff       	jmp    8010669b <alltraps>

8010773e <vector250>:
.globl vector250
vector250:
  pushl $0
8010773e:	6a 00                	push   $0x0
  pushl $250
80107740:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107745:	e9 51 ef ff ff       	jmp    8010669b <alltraps>

8010774a <vector251>:
.globl vector251
vector251:
  pushl $0
8010774a:	6a 00                	push   $0x0
  pushl $251
8010774c:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107751:	e9 45 ef ff ff       	jmp    8010669b <alltraps>

80107756 <vector252>:
.globl vector252
vector252:
  pushl $0
80107756:	6a 00                	push   $0x0
  pushl $252
80107758:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
8010775d:	e9 39 ef ff ff       	jmp    8010669b <alltraps>

80107762 <vector253>:
.globl vector253
vector253:
  pushl $0
80107762:	6a 00                	push   $0x0
  pushl $253
80107764:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107769:	e9 2d ef ff ff       	jmp    8010669b <alltraps>

8010776e <vector254>:
.globl vector254
vector254:
  pushl $0
8010776e:	6a 00                	push   $0x0
  pushl $254
80107770:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107775:	e9 21 ef ff ff       	jmp    8010669b <alltraps>

8010777a <vector255>:
.globl vector255
vector255:
  pushl $0
8010777a:	6a 00                	push   $0x0
  pushl $255
8010777c:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107781:	e9 15 ef ff ff       	jmp    8010669b <alltraps>

80107786 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107786:	55                   	push   %ebp
80107787:	89 e5                	mov    %esp,%ebp
80107789:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010778c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010778f:	83 e8 01             	sub    $0x1,%eax
80107792:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107796:	8b 45 08             	mov    0x8(%ebp),%eax
80107799:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010779d:	8b 45 08             	mov    0x8(%ebp),%eax
801077a0:	c1 e8 10             	shr    $0x10,%eax
801077a3:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
801077a7:	8d 45 fa             	lea    -0x6(%ebp),%eax
801077aa:	0f 01 10             	lgdtl  (%eax)
}
801077ad:	c9                   	leave  
801077ae:	c3                   	ret    

801077af <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
801077af:	55                   	push   %ebp
801077b0:	89 e5                	mov    %esp,%ebp
801077b2:	83 ec 04             	sub    $0x4,%esp
801077b5:	8b 45 08             	mov    0x8(%ebp),%eax
801077b8:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801077bc:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801077c0:	0f 00 d8             	ltr    %ax
}
801077c3:	c9                   	leave  
801077c4:	c3                   	ret    

801077c5 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
801077c5:	55                   	push   %ebp
801077c6:	89 e5                	mov    %esp,%ebp
801077c8:	83 ec 04             	sub    $0x4,%esp
801077cb:	8b 45 08             	mov    0x8(%ebp),%eax
801077ce:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
801077d2:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801077d6:	8e e8                	mov    %eax,%gs
}
801077d8:	c9                   	leave  
801077d9:	c3                   	ret    

801077da <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
801077da:	55                   	push   %ebp
801077db:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801077dd:	8b 45 08             	mov    0x8(%ebp),%eax
801077e0:	0f 22 d8             	mov    %eax,%cr3
}
801077e3:	5d                   	pop    %ebp
801077e4:	c3                   	ret    

801077e5 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
801077e5:	55                   	push   %ebp
801077e6:	89 e5                	mov    %esp,%ebp
801077e8:	8b 45 08             	mov    0x8(%ebp),%eax
801077eb:	05 00 00 00 80       	add    $0x80000000,%eax
801077f0:	5d                   	pop    %ebp
801077f1:	c3                   	ret    

801077f2 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
801077f2:	55                   	push   %ebp
801077f3:	89 e5                	mov    %esp,%ebp
801077f5:	8b 45 08             	mov    0x8(%ebp),%eax
801077f8:	05 00 00 00 80       	add    $0x80000000,%eax
801077fd:	5d                   	pop    %ebp
801077fe:	c3                   	ret    

801077ff <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801077ff:	55                   	push   %ebp
80107800:	89 e5                	mov    %esp,%ebp
80107802:	53                   	push   %ebx
80107803:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107806:	e8 a4 b6 ff ff       	call   80102eaf <cpunum>
8010780b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107811:	05 60 23 11 80       	add    $0x80112360,%eax
80107816:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107819:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010781c:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107822:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107825:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010782b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010782e:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107832:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107835:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107839:	83 e2 f0             	and    $0xfffffff0,%edx
8010783c:	83 ca 0a             	or     $0xa,%edx
8010783f:	88 50 7d             	mov    %dl,0x7d(%eax)
80107842:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107845:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107849:	83 ca 10             	or     $0x10,%edx
8010784c:	88 50 7d             	mov    %dl,0x7d(%eax)
8010784f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107852:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107856:	83 e2 9f             	and    $0xffffff9f,%edx
80107859:	88 50 7d             	mov    %dl,0x7d(%eax)
8010785c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010785f:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107863:	83 ca 80             	or     $0xffffff80,%edx
80107866:	88 50 7d             	mov    %dl,0x7d(%eax)
80107869:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107870:	83 ca 0f             	or     $0xf,%edx
80107873:	88 50 7e             	mov    %dl,0x7e(%eax)
80107876:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107879:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010787d:	83 e2 ef             	and    $0xffffffef,%edx
80107880:	88 50 7e             	mov    %dl,0x7e(%eax)
80107883:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107886:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010788a:	83 e2 df             	and    $0xffffffdf,%edx
8010788d:	88 50 7e             	mov    %dl,0x7e(%eax)
80107890:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107893:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107897:	83 ca 40             	or     $0x40,%edx
8010789a:	88 50 7e             	mov    %dl,0x7e(%eax)
8010789d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078a0:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801078a4:	83 ca 80             	or     $0xffffff80,%edx
801078a7:	88 50 7e             	mov    %dl,0x7e(%eax)
801078aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ad:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
801078b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b4:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
801078bb:	ff ff 
801078bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c0:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
801078c7:	00 00 
801078c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078cc:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
801078d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d6:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078dd:	83 e2 f0             	and    $0xfffffff0,%edx
801078e0:	83 ca 02             	or     $0x2,%edx
801078e3:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ec:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078f3:	83 ca 10             	or     $0x10,%edx
801078f6:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ff:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107906:	83 e2 9f             	and    $0xffffff9f,%edx
80107909:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010790f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107912:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107919:	83 ca 80             	or     $0xffffff80,%edx
8010791c:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107922:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107925:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010792c:	83 ca 0f             	or     $0xf,%edx
8010792f:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107935:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107938:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010793f:	83 e2 ef             	and    $0xffffffef,%edx
80107942:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107948:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010794b:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107952:	83 e2 df             	and    $0xffffffdf,%edx
80107955:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010795b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010795e:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107965:	83 ca 40             	or     $0x40,%edx
80107968:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010796e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107971:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107978:	83 ca 80             	or     $0xffffff80,%edx
8010797b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107981:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107984:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010798b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010798e:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107995:	ff ff 
80107997:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010799a:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
801079a1:	00 00 
801079a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079a6:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
801079ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079b0:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801079b7:	83 e2 f0             	and    $0xfffffff0,%edx
801079ba:	83 ca 0a             	or     $0xa,%edx
801079bd:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c6:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801079cd:	83 ca 10             	or     $0x10,%edx
801079d0:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079d9:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801079e0:	83 ca 60             	or     $0x60,%edx
801079e3:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ec:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
801079f3:	83 ca 80             	or     $0xffffff80,%edx
801079f6:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
801079fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ff:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a06:	83 ca 0f             	or     $0xf,%edx
80107a09:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a12:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a19:	83 e2 ef             	and    $0xffffffef,%edx
80107a1c:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a25:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a2c:	83 e2 df             	and    $0xffffffdf,%edx
80107a2f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a38:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a3f:	83 ca 40             	or     $0x40,%edx
80107a42:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a4b:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107a52:	83 ca 80             	or     $0xffffff80,%edx
80107a55:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107a5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a5e:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a68:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107a6f:	ff ff 
80107a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a74:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107a7b:	00 00 
80107a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a80:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107a87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a8a:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107a91:	83 e2 f0             	and    $0xfffffff0,%edx
80107a94:	83 ca 02             	or     $0x2,%edx
80107a97:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aa0:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107aa7:	83 ca 10             	or     $0x10,%edx
80107aaa:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107ab0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ab3:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107aba:	83 ca 60             	or     $0x60,%edx
80107abd:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107ac3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac6:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107acd:	83 ca 80             	or     $0xffffff80,%edx
80107ad0:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107ad6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad9:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107ae0:	83 ca 0f             	or     $0xf,%edx
80107ae3:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107ae9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aec:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107af3:	83 e2 ef             	and    $0xffffffef,%edx
80107af6:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aff:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107b06:	83 e2 df             	and    $0xffffffdf,%edx
80107b09:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107b0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b12:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107b19:	83 ca 40             	or     $0x40,%edx
80107b1c:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107b22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b25:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107b2c:	83 ca 80             	or     $0xffffff80,%edx
80107b2f:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107b35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b38:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107b3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b42:	05 b4 00 00 00       	add    $0xb4,%eax
80107b47:	89 c3                	mov    %eax,%ebx
80107b49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b4c:	05 b4 00 00 00       	add    $0xb4,%eax
80107b51:	c1 e8 10             	shr    $0x10,%eax
80107b54:	89 c1                	mov    %eax,%ecx
80107b56:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b59:	05 b4 00 00 00       	add    $0xb4,%eax
80107b5e:	c1 e8 18             	shr    $0x18,%eax
80107b61:	89 c2                	mov    %eax,%edx
80107b63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b66:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107b6d:	00 00 
80107b6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b72:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107b79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b7c:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107b82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b85:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107b8c:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b8f:	83 c9 02             	or     $0x2,%ecx
80107b92:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107b98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b9b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107ba2:	83 c9 10             	or     $0x10,%ecx
80107ba5:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107bab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bae:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107bb5:	83 e1 9f             	and    $0xffffff9f,%ecx
80107bb8:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107bbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bc1:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107bc8:	83 c9 80             	or     $0xffffff80,%ecx
80107bcb:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107bd1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bd4:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107bdb:	83 e1 f0             	and    $0xfffffff0,%ecx
80107bde:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107be4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107be7:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107bee:	83 e1 ef             	and    $0xffffffef,%ecx
80107bf1:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107bf7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bfa:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107c01:	83 e1 df             	and    $0xffffffdf,%ecx
80107c04:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107c0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c0d:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107c14:	83 c9 40             	or     $0x40,%ecx
80107c17:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c20:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107c27:	83 c9 80             	or     $0xffffff80,%ecx
80107c2a:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107c30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c33:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107c39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c3c:	83 c0 70             	add    $0x70,%eax
80107c3f:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107c46:	00 
80107c47:	89 04 24             	mov    %eax,(%esp)
80107c4a:	e8 37 fb ff ff       	call   80107786 <lgdt>
  loadgs(SEG_KCPU << 3);
80107c4f:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107c56:	e8 6a fb ff ff       	call   801077c5 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107c5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c5e:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107c64:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107c6b:	00 00 00 00 
}
80107c6f:	83 c4 24             	add    $0x24,%esp
80107c72:	5b                   	pop    %ebx
80107c73:	5d                   	pop    %ebp
80107c74:	c3                   	ret    

80107c75 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107c75:	55                   	push   %ebp
80107c76:	89 e5                	mov    %esp,%ebp
80107c78:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107c7b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107c7e:	c1 e8 16             	shr    $0x16,%eax
80107c81:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107c88:	8b 45 08             	mov    0x8(%ebp),%eax
80107c8b:	01 d0                	add    %edx,%eax
80107c8d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107c90:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c93:	8b 00                	mov    (%eax),%eax
80107c95:	83 e0 01             	and    $0x1,%eax
80107c98:	85 c0                	test   %eax,%eax
80107c9a:	74 17                	je     80107cb3 <walkpgdir+0x3e>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107c9c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107c9f:	8b 00                	mov    (%eax),%eax
80107ca1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ca6:	89 04 24             	mov    %eax,(%esp)
80107ca9:	e8 44 fb ff ff       	call   801077f2 <p2v>
80107cae:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107cb1:	eb 4b                	jmp    80107cfe <walkpgdir+0x89>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107cb3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107cb7:	74 0e                	je     80107cc7 <walkpgdir+0x52>
80107cb9:	e8 5b ae ff ff       	call   80102b19 <kalloc>
80107cbe:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107cc1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107cc5:	75 07                	jne    80107cce <walkpgdir+0x59>
      return 0;
80107cc7:	b8 00 00 00 00       	mov    $0x0,%eax
80107ccc:	eb 47                	jmp    80107d15 <walkpgdir+0xa0>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107cce:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107cd5:	00 
80107cd6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107cdd:	00 
80107cde:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce1:	89 04 24             	mov    %eax,(%esp)
80107ce4:	e8 64 d5 ff ff       	call   8010524d <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107ce9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cec:	89 04 24             	mov    %eax,(%esp)
80107cef:	e8 f1 fa ff ff       	call   801077e5 <v2p>
80107cf4:	83 c8 07             	or     $0x7,%eax
80107cf7:	89 c2                	mov    %eax,%edx
80107cf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107cfc:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107cfe:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d01:	c1 e8 0c             	shr    $0xc,%eax
80107d04:	25 ff 03 00 00       	and    $0x3ff,%eax
80107d09:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107d10:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d13:	01 d0                	add    %edx,%eax
}
80107d15:	c9                   	leave  
80107d16:	c3                   	ret    

80107d17 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107d17:	55                   	push   %ebp
80107d18:	89 e5                	mov    %esp,%ebp
80107d1a:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107d1d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d20:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107d25:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107d28:	8b 55 0c             	mov    0xc(%ebp),%edx
80107d2b:	8b 45 10             	mov    0x10(%ebp),%eax
80107d2e:	01 d0                	add    %edx,%eax
80107d30:	83 e8 01             	sub    $0x1,%eax
80107d33:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107d38:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107d3b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107d42:	00 
80107d43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d46:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d4a:	8b 45 08             	mov    0x8(%ebp),%eax
80107d4d:	89 04 24             	mov    %eax,(%esp)
80107d50:	e8 20 ff ff ff       	call   80107c75 <walkpgdir>
80107d55:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107d58:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107d5c:	75 07                	jne    80107d65 <mappages+0x4e>
      return -1;
80107d5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107d63:	eb 48                	jmp    80107dad <mappages+0x96>
    if(*pte & PTE_P)
80107d65:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d68:	8b 00                	mov    (%eax),%eax
80107d6a:	83 e0 01             	and    $0x1,%eax
80107d6d:	85 c0                	test   %eax,%eax
80107d6f:	74 0c                	je     80107d7d <mappages+0x66>
      panic("remap");
80107d71:	c7 04 24 7c 8c 10 80 	movl   $0x80108c7c,(%esp)
80107d78:	e8 bd 87 ff ff       	call   8010053a <panic>
    *pte = pa | perm | PTE_P;
80107d7d:	8b 45 18             	mov    0x18(%ebp),%eax
80107d80:	0b 45 14             	or     0x14(%ebp),%eax
80107d83:	83 c8 01             	or     $0x1,%eax
80107d86:	89 c2                	mov    %eax,%edx
80107d88:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d8b:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107d8d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d90:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107d93:	75 08                	jne    80107d9d <mappages+0x86>
      break;
80107d95:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107d96:	b8 00 00 00 00       	mov    $0x0,%eax
80107d9b:	eb 10                	jmp    80107dad <mappages+0x96>
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
    a += PGSIZE;
80107d9d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107da4:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107dab:	eb 8e                	jmp    80107d3b <mappages+0x24>
  return 0;
}
80107dad:	c9                   	leave  
80107dae:	c3                   	ret    

80107daf <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107daf:	55                   	push   %ebp
80107db0:	89 e5                	mov    %esp,%ebp
80107db2:	53                   	push   %ebx
80107db3:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107db6:	e8 5e ad ff ff       	call   80102b19 <kalloc>
80107dbb:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107dbe:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107dc2:	75 0a                	jne    80107dce <setupkvm+0x1f>
    return 0;
80107dc4:	b8 00 00 00 00       	mov    $0x0,%eax
80107dc9:	e9 98 00 00 00       	jmp    80107e66 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107dce:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107dd5:	00 
80107dd6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107ddd:	00 
80107dde:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107de1:	89 04 24             	mov    %eax,(%esp)
80107de4:	e8 64 d4 ff ff       	call   8010524d <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107de9:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107df0:	e8 fd f9 ff ff       	call   801077f2 <p2v>
80107df5:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107dfa:	76 0c                	jbe    80107e08 <setupkvm+0x59>
    panic("PHYSTOP too high");
80107dfc:	c7 04 24 82 8c 10 80 	movl   $0x80108c82,(%esp)
80107e03:	e8 32 87 ff ff       	call   8010053a <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107e08:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107e0f:	eb 49                	jmp    80107e5a <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107e11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e14:	8b 48 0c             	mov    0xc(%eax),%ecx
80107e17:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e1a:	8b 50 04             	mov    0x4(%eax),%edx
80107e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e20:	8b 58 08             	mov    0x8(%eax),%ebx
80107e23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e26:	8b 40 04             	mov    0x4(%eax),%eax
80107e29:	29 c3                	sub    %eax,%ebx
80107e2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e2e:	8b 00                	mov    (%eax),%eax
80107e30:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107e34:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107e38:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107e3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e43:	89 04 24             	mov    %eax,(%esp)
80107e46:	e8 cc fe ff ff       	call   80107d17 <mappages>
80107e4b:	85 c0                	test   %eax,%eax
80107e4d:	79 07                	jns    80107e56 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107e4f:	b8 00 00 00 00       	mov    $0x0,%eax
80107e54:	eb 10                	jmp    80107e66 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107e56:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107e5a:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107e61:	72 ae                	jb     80107e11 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107e63:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107e66:	83 c4 34             	add    $0x34,%esp
80107e69:	5b                   	pop    %ebx
80107e6a:	5d                   	pop    %ebp
80107e6b:	c3                   	ret    

80107e6c <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107e6c:	55                   	push   %ebp
80107e6d:	89 e5                	mov    %esp,%ebp
80107e6f:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107e72:	e8 38 ff ff ff       	call   80107daf <setupkvm>
80107e77:	a3 38 53 11 80       	mov    %eax,0x80115338
  switchkvm();
80107e7c:	e8 02 00 00 00       	call   80107e83 <switchkvm>
}
80107e81:	c9                   	leave  
80107e82:	c3                   	ret    

80107e83 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107e83:	55                   	push   %ebp
80107e84:	89 e5                	mov    %esp,%ebp
80107e86:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107e89:	a1 38 53 11 80       	mov    0x80115338,%eax
80107e8e:	89 04 24             	mov    %eax,(%esp)
80107e91:	e8 4f f9 ff ff       	call   801077e5 <v2p>
80107e96:	89 04 24             	mov    %eax,(%esp)
80107e99:	e8 3c f9 ff ff       	call   801077da <lcr3>
}
80107e9e:	c9                   	leave  
80107e9f:	c3                   	ret    

80107ea0 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107ea0:	55                   	push   %ebp
80107ea1:	89 e5                	mov    %esp,%ebp
80107ea3:	53                   	push   %ebx
80107ea4:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107ea7:	e8 a1 d2 ff ff       	call   8010514d <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107eac:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107eb2:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107eb9:	83 c2 08             	add    $0x8,%edx
80107ebc:	89 d3                	mov    %edx,%ebx
80107ebe:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107ec5:	83 c2 08             	add    $0x8,%edx
80107ec8:	c1 ea 10             	shr    $0x10,%edx
80107ecb:	89 d1                	mov    %edx,%ecx
80107ecd:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107ed4:	83 c2 08             	add    $0x8,%edx
80107ed7:	c1 ea 18             	shr    $0x18,%edx
80107eda:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107ee1:	67 00 
80107ee3:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107eea:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107ef0:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107ef7:	83 e1 f0             	and    $0xfffffff0,%ecx
80107efa:	83 c9 09             	or     $0x9,%ecx
80107efd:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107f03:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107f0a:	83 c9 10             	or     $0x10,%ecx
80107f0d:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107f13:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107f1a:	83 e1 9f             	and    $0xffffff9f,%ecx
80107f1d:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107f23:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107f2a:	83 c9 80             	or     $0xffffff80,%ecx
80107f2d:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107f33:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f3a:	83 e1 f0             	and    $0xfffffff0,%ecx
80107f3d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f43:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f4a:	83 e1 ef             	and    $0xffffffef,%ecx
80107f4d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f53:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f5a:	83 e1 df             	and    $0xffffffdf,%ecx
80107f5d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f63:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f6a:	83 c9 40             	or     $0x40,%ecx
80107f6d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f73:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107f7a:	83 e1 7f             	and    $0x7f,%ecx
80107f7d:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107f83:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107f89:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107f8f:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107f96:	83 e2 ef             	and    $0xffffffef,%edx
80107f99:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107f9f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107fa5:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107fab:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107fb1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107fb8:	8b 52 08             	mov    0x8(%edx),%edx
80107fbb:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107fc1:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107fc4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107fcb:	e8 df f7 ff ff       	call   801077af <ltr>
  if(p->pgdir == 0)
80107fd0:	8b 45 08             	mov    0x8(%ebp),%eax
80107fd3:	8b 40 04             	mov    0x4(%eax),%eax
80107fd6:	85 c0                	test   %eax,%eax
80107fd8:	75 0c                	jne    80107fe6 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107fda:	c7 04 24 93 8c 10 80 	movl   $0x80108c93,(%esp)
80107fe1:	e8 54 85 ff ff       	call   8010053a <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107fe6:	8b 45 08             	mov    0x8(%ebp),%eax
80107fe9:	8b 40 04             	mov    0x4(%eax),%eax
80107fec:	89 04 24             	mov    %eax,(%esp)
80107fef:	e8 f1 f7 ff ff       	call   801077e5 <v2p>
80107ff4:	89 04 24             	mov    %eax,(%esp)
80107ff7:	e8 de f7 ff ff       	call   801077da <lcr3>
  popcli();
80107ffc:	e8 90 d1 ff ff       	call   80105191 <popcli>
}
80108001:	83 c4 14             	add    $0x14,%esp
80108004:	5b                   	pop    %ebx
80108005:	5d                   	pop    %ebp
80108006:	c3                   	ret    

80108007 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80108007:	55                   	push   %ebp
80108008:	89 e5                	mov    %esp,%ebp
8010800a:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
8010800d:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80108014:	76 0c                	jbe    80108022 <inituvm+0x1b>
    panic("inituvm: more than a page");
80108016:	c7 04 24 a7 8c 10 80 	movl   $0x80108ca7,(%esp)
8010801d:	e8 18 85 ff ff       	call   8010053a <panic>
  mem = kalloc();
80108022:	e8 f2 aa ff ff       	call   80102b19 <kalloc>
80108027:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
8010802a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108031:	00 
80108032:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108039:	00 
8010803a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010803d:	89 04 24             	mov    %eax,(%esp)
80108040:	e8 08 d2 ff ff       	call   8010524d <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80108045:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108048:	89 04 24             	mov    %eax,(%esp)
8010804b:	e8 95 f7 ff ff       	call   801077e5 <v2p>
80108050:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108057:	00 
80108058:	89 44 24 0c          	mov    %eax,0xc(%esp)
8010805c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108063:	00 
80108064:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010806b:	00 
8010806c:	8b 45 08             	mov    0x8(%ebp),%eax
8010806f:	89 04 24             	mov    %eax,(%esp)
80108072:	e8 a0 fc ff ff       	call   80107d17 <mappages>
  memmove(mem, init, sz);
80108077:	8b 45 10             	mov    0x10(%ebp),%eax
8010807a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010807e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108081:	89 44 24 04          	mov    %eax,0x4(%esp)
80108085:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108088:	89 04 24             	mov    %eax,(%esp)
8010808b:	e8 8c d2 ff ff       	call   8010531c <memmove>
}
80108090:	c9                   	leave  
80108091:	c3                   	ret    

80108092 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108092:	55                   	push   %ebp
80108093:	89 e5                	mov    %esp,%ebp
80108095:	53                   	push   %ebx
80108096:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80108099:	8b 45 0c             	mov    0xc(%ebp),%eax
8010809c:	25 ff 0f 00 00       	and    $0xfff,%eax
801080a1:	85 c0                	test   %eax,%eax
801080a3:	74 0c                	je     801080b1 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
801080a5:	c7 04 24 c4 8c 10 80 	movl   $0x80108cc4,(%esp)
801080ac:	e8 89 84 ff ff       	call   8010053a <panic>
  for(i = 0; i < sz; i += PGSIZE){
801080b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801080b8:	e9 a9 00 00 00       	jmp    80108166 <loaduvm+0xd4>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
801080bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080c0:	8b 55 0c             	mov    0xc(%ebp),%edx
801080c3:	01 d0                	add    %edx,%eax
801080c5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801080cc:	00 
801080cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801080d1:	8b 45 08             	mov    0x8(%ebp),%eax
801080d4:	89 04 24             	mov    %eax,(%esp)
801080d7:	e8 99 fb ff ff       	call   80107c75 <walkpgdir>
801080dc:	89 45 ec             	mov    %eax,-0x14(%ebp)
801080df:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801080e3:	75 0c                	jne    801080f1 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801080e5:	c7 04 24 e7 8c 10 80 	movl   $0x80108ce7,(%esp)
801080ec:	e8 49 84 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
801080f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801080f4:	8b 00                	mov    (%eax),%eax
801080f6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801080fb:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801080fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108101:	8b 55 18             	mov    0x18(%ebp),%edx
80108104:	29 c2                	sub    %eax,%edx
80108106:	89 d0                	mov    %edx,%eax
80108108:	3d ff 0f 00 00       	cmp    $0xfff,%eax
8010810d:	77 0f                	ja     8010811e <loaduvm+0x8c>
      n = sz - i;
8010810f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108112:	8b 55 18             	mov    0x18(%ebp),%edx
80108115:	29 c2                	sub    %eax,%edx
80108117:	89 d0                	mov    %edx,%eax
80108119:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010811c:	eb 07                	jmp    80108125 <loaduvm+0x93>
    else
      n = PGSIZE;
8010811e:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80108125:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108128:	8b 55 14             	mov    0x14(%ebp),%edx
8010812b:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010812e:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108131:	89 04 24             	mov    %eax,(%esp)
80108134:	e8 b9 f6 ff ff       	call   801077f2 <p2v>
80108139:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010813c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80108140:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108144:	89 44 24 04          	mov    %eax,0x4(%esp)
80108148:	8b 45 10             	mov    0x10(%ebp),%eax
8010814b:	89 04 24             	mov    %eax,(%esp)
8010814e:	e8 15 9c ff ff       	call   80101d68 <readi>
80108153:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108156:	74 07                	je     8010815f <loaduvm+0xcd>
      return -1;
80108158:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010815d:	eb 18                	jmp    80108177 <loaduvm+0xe5>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
8010815f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108166:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108169:	3b 45 18             	cmp    0x18(%ebp),%eax
8010816c:	0f 82 4b ff ff ff    	jb     801080bd <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80108172:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108177:	83 c4 24             	add    $0x24,%esp
8010817a:	5b                   	pop    %ebx
8010817b:	5d                   	pop    %ebp
8010817c:	c3                   	ret    

8010817d <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
8010817d:	55                   	push   %ebp
8010817e:	89 e5                	mov    %esp,%ebp
80108180:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80108183:	8b 45 10             	mov    0x10(%ebp),%eax
80108186:	85 c0                	test   %eax,%eax
80108188:	79 0a                	jns    80108194 <allocuvm+0x17>
    return 0;
8010818a:	b8 00 00 00 00       	mov    $0x0,%eax
8010818f:	e9 c1 00 00 00       	jmp    80108255 <allocuvm+0xd8>
  if(newsz < oldsz)
80108194:	8b 45 10             	mov    0x10(%ebp),%eax
80108197:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010819a:	73 08                	jae    801081a4 <allocuvm+0x27>
    return oldsz;
8010819c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010819f:	e9 b1 00 00 00       	jmp    80108255 <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
801081a4:	8b 45 0c             	mov    0xc(%ebp),%eax
801081a7:	05 ff 0f 00 00       	add    $0xfff,%eax
801081ac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
801081b4:	e9 8d 00 00 00       	jmp    80108246 <allocuvm+0xc9>
    mem = kalloc();
801081b9:	e8 5b a9 ff ff       	call   80102b19 <kalloc>
801081be:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
801081c1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801081c5:	75 2c                	jne    801081f3 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
801081c7:	c7 04 24 05 8d 10 80 	movl   $0x80108d05,(%esp)
801081ce:	e8 cd 81 ff ff       	call   801003a0 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
801081d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801081d6:	89 44 24 08          	mov    %eax,0x8(%esp)
801081da:	8b 45 10             	mov    0x10(%ebp),%eax
801081dd:	89 44 24 04          	mov    %eax,0x4(%esp)
801081e1:	8b 45 08             	mov    0x8(%ebp),%eax
801081e4:	89 04 24             	mov    %eax,(%esp)
801081e7:	e8 6b 00 00 00       	call   80108257 <deallocuvm>
      return 0;
801081ec:	b8 00 00 00 00       	mov    $0x0,%eax
801081f1:	eb 62                	jmp    80108255 <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801081f3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801081fa:	00 
801081fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108202:	00 
80108203:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108206:	89 04 24             	mov    %eax,(%esp)
80108209:	e8 3f d0 ff ff       	call   8010524d <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010820e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108211:	89 04 24             	mov    %eax,(%esp)
80108214:	e8 cc f5 ff ff       	call   801077e5 <v2p>
80108219:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010821c:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108223:	00 
80108224:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108228:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010822f:	00 
80108230:	89 54 24 04          	mov    %edx,0x4(%esp)
80108234:	8b 45 08             	mov    0x8(%ebp),%eax
80108237:	89 04 24             	mov    %eax,(%esp)
8010823a:	e8 d8 fa ff ff       	call   80107d17 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
8010823f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108246:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108249:	3b 45 10             	cmp    0x10(%ebp),%eax
8010824c:	0f 82 67 ff ff ff    	jb     801081b9 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80108252:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108255:	c9                   	leave  
80108256:	c3                   	ret    

80108257 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108257:	55                   	push   %ebp
80108258:	89 e5                	mov    %esp,%ebp
8010825a:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
8010825d:	8b 45 10             	mov    0x10(%ebp),%eax
80108260:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108263:	72 08                	jb     8010826d <deallocuvm+0x16>
    return oldsz;
80108265:	8b 45 0c             	mov    0xc(%ebp),%eax
80108268:	e9 a4 00 00 00       	jmp    80108311 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
8010826d:	8b 45 10             	mov    0x10(%ebp),%eax
80108270:	05 ff 0f 00 00       	add    $0xfff,%eax
80108275:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010827a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010827d:	e9 80 00 00 00       	jmp    80108302 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108282:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108285:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010828c:	00 
8010828d:	89 44 24 04          	mov    %eax,0x4(%esp)
80108291:	8b 45 08             	mov    0x8(%ebp),%eax
80108294:	89 04 24             	mov    %eax,(%esp)
80108297:	e8 d9 f9 ff ff       	call   80107c75 <walkpgdir>
8010829c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
8010829f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801082a3:	75 09                	jne    801082ae <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
801082a5:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
801082ac:	eb 4d                	jmp    801082fb <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
801082ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082b1:	8b 00                	mov    (%eax),%eax
801082b3:	83 e0 01             	and    $0x1,%eax
801082b6:	85 c0                	test   %eax,%eax
801082b8:	74 41                	je     801082fb <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
801082ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082bd:	8b 00                	mov    (%eax),%eax
801082bf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801082c4:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
801082c7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801082cb:	75 0c                	jne    801082d9 <deallocuvm+0x82>
        panic("kfree");
801082cd:	c7 04 24 1d 8d 10 80 	movl   $0x80108d1d,(%esp)
801082d4:	e8 61 82 ff ff       	call   8010053a <panic>
      char *v = p2v(pa);
801082d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082dc:	89 04 24             	mov    %eax,(%esp)
801082df:	e8 0e f5 ff ff       	call   801077f2 <p2v>
801082e4:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
801082e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
801082ea:	89 04 24             	mov    %eax,(%esp)
801082ed:	e8 8e a7 ff ff       	call   80102a80 <kfree>
      *pte = 0;
801082f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801082f5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801082fb:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108302:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108305:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108308:	0f 82 74 ff ff ff    	jb     80108282 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
8010830e:	8b 45 10             	mov    0x10(%ebp),%eax
}
80108311:	c9                   	leave  
80108312:	c3                   	ret    

80108313 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80108313:	55                   	push   %ebp
80108314:	89 e5                	mov    %esp,%ebp
80108316:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80108319:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010831d:	75 0c                	jne    8010832b <freevm+0x18>
    panic("freevm: no pgdir");
8010831f:	c7 04 24 23 8d 10 80 	movl   $0x80108d23,(%esp)
80108326:	e8 0f 82 ff ff       	call   8010053a <panic>
  deallocuvm(pgdir, KERNBASE, 0);
8010832b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108332:	00 
80108333:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
8010833a:	80 
8010833b:	8b 45 08             	mov    0x8(%ebp),%eax
8010833e:	89 04 24             	mov    %eax,(%esp)
80108341:	e8 11 ff ff ff       	call   80108257 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108346:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010834d:	eb 48                	jmp    80108397 <freevm+0x84>
    if(pgdir[i] & PTE_P){
8010834f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108352:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108359:	8b 45 08             	mov    0x8(%ebp),%eax
8010835c:	01 d0                	add    %edx,%eax
8010835e:	8b 00                	mov    (%eax),%eax
80108360:	83 e0 01             	and    $0x1,%eax
80108363:	85 c0                	test   %eax,%eax
80108365:	74 2c                	je     80108393 <freevm+0x80>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80108367:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010836a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108371:	8b 45 08             	mov    0x8(%ebp),%eax
80108374:	01 d0                	add    %edx,%eax
80108376:	8b 00                	mov    (%eax),%eax
80108378:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010837d:	89 04 24             	mov    %eax,(%esp)
80108380:	e8 6d f4 ff ff       	call   801077f2 <p2v>
80108385:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108388:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010838b:	89 04 24             	mov    %eax,(%esp)
8010838e:	e8 ed a6 ff ff       	call   80102a80 <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108393:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108397:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
8010839e:	76 af                	jbe    8010834f <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
801083a0:	8b 45 08             	mov    0x8(%ebp),%eax
801083a3:	89 04 24             	mov    %eax,(%esp)
801083a6:	e8 d5 a6 ff ff       	call   80102a80 <kfree>
}
801083ab:	c9                   	leave  
801083ac:	c3                   	ret    

801083ad <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801083ad:	55                   	push   %ebp
801083ae:	89 e5                	mov    %esp,%ebp
801083b0:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801083b3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801083ba:	00 
801083bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801083be:	89 44 24 04          	mov    %eax,0x4(%esp)
801083c2:	8b 45 08             	mov    0x8(%ebp),%eax
801083c5:	89 04 24             	mov    %eax,(%esp)
801083c8:	e8 a8 f8 ff ff       	call   80107c75 <walkpgdir>
801083cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
801083d0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801083d4:	75 0c                	jne    801083e2 <clearpteu+0x35>
    panic("clearpteu");
801083d6:	c7 04 24 34 8d 10 80 	movl   $0x80108d34,(%esp)
801083dd:	e8 58 81 ff ff       	call   8010053a <panic>
  *pte &= ~PTE_U;
801083e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083e5:	8b 00                	mov    (%eax),%eax
801083e7:	83 e0 fb             	and    $0xfffffffb,%eax
801083ea:	89 c2                	mov    %eax,%edx
801083ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083ef:	89 10                	mov    %edx,(%eax)
}
801083f1:	c9                   	leave  
801083f2:	c3                   	ret    

801083f3 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801083f3:	55                   	push   %ebp
801083f4:	89 e5                	mov    %esp,%ebp
801083f6:	53                   	push   %ebx
801083f7:	83 ec 44             	sub    $0x44,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801083fa:	e8 b0 f9 ff ff       	call   80107daf <setupkvm>
801083ff:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108402:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108406:	75 0a                	jne    80108412 <copyuvm+0x1f>
    return 0;
80108408:	b8 00 00 00 00       	mov    $0x0,%eax
8010840d:	e9 fd 00 00 00       	jmp    8010850f <copyuvm+0x11c>
  for(i = 0; i < sz; i += PGSIZE){
80108412:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108419:	e9 d0 00 00 00       	jmp    801084ee <copyuvm+0xfb>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010841e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108421:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108428:	00 
80108429:	89 44 24 04          	mov    %eax,0x4(%esp)
8010842d:	8b 45 08             	mov    0x8(%ebp),%eax
80108430:	89 04 24             	mov    %eax,(%esp)
80108433:	e8 3d f8 ff ff       	call   80107c75 <walkpgdir>
80108438:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010843b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010843f:	75 0c                	jne    8010844d <copyuvm+0x5a>
      panic("copyuvm: pte should exist");
80108441:	c7 04 24 3e 8d 10 80 	movl   $0x80108d3e,(%esp)
80108448:	e8 ed 80 ff ff       	call   8010053a <panic>
    if(!(*pte & PTE_P))
8010844d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108450:	8b 00                	mov    (%eax),%eax
80108452:	83 e0 01             	and    $0x1,%eax
80108455:	85 c0                	test   %eax,%eax
80108457:	75 0c                	jne    80108465 <copyuvm+0x72>
      panic("copyuvm: page not present");
80108459:	c7 04 24 58 8d 10 80 	movl   $0x80108d58,(%esp)
80108460:	e8 d5 80 ff ff       	call   8010053a <panic>
    pa = PTE_ADDR(*pte);
80108465:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108468:	8b 00                	mov    (%eax),%eax
8010846a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010846f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
80108472:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108475:	8b 00                	mov    (%eax),%eax
80108477:	25 ff 0f 00 00       	and    $0xfff,%eax
8010847c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
8010847f:	e8 95 a6 ff ff       	call   80102b19 <kalloc>
80108484:	89 45 e0             	mov    %eax,-0x20(%ebp)
80108487:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010848b:	75 02                	jne    8010848f <copyuvm+0x9c>
      goto bad;
8010848d:	eb 70                	jmp    801084ff <copyuvm+0x10c>
    memmove(mem, (char*)p2v(pa), PGSIZE);
8010848f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108492:	89 04 24             	mov    %eax,(%esp)
80108495:	e8 58 f3 ff ff       	call   801077f2 <p2v>
8010849a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801084a1:	00 
801084a2:	89 44 24 04          	mov    %eax,0x4(%esp)
801084a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801084a9:	89 04 24             	mov    %eax,(%esp)
801084ac:	e8 6b ce ff ff       	call   8010531c <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
801084b1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801084b4:	8b 45 e0             	mov    -0x20(%ebp),%eax
801084b7:	89 04 24             	mov    %eax,(%esp)
801084ba:	e8 26 f3 ff ff       	call   801077e5 <v2p>
801084bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
801084c2:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801084c6:	89 44 24 0c          	mov    %eax,0xc(%esp)
801084ca:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801084d1:	00 
801084d2:	89 54 24 04          	mov    %edx,0x4(%esp)
801084d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084d9:	89 04 24             	mov    %eax,(%esp)
801084dc:	e8 36 f8 ff ff       	call   80107d17 <mappages>
801084e1:	85 c0                	test   %eax,%eax
801084e3:	79 02                	jns    801084e7 <copyuvm+0xf4>
      goto bad;
801084e5:	eb 18                	jmp    801084ff <copyuvm+0x10c>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
801084e7:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801084ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801084f1:	3b 45 0c             	cmp    0xc(%ebp),%eax
801084f4:	0f 82 24 ff ff ff    	jb     8010841e <copyuvm+0x2b>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), flags) < 0)
      goto bad;
  }
  return d;
801084fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084fd:	eb 10                	jmp    8010850f <copyuvm+0x11c>

bad:
  freevm(d);
801084ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108502:	89 04 24             	mov    %eax,(%esp)
80108505:	e8 09 fe ff ff       	call   80108313 <freevm>
  return 0;
8010850a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010850f:	83 c4 44             	add    $0x44,%esp
80108512:	5b                   	pop    %ebx
80108513:	5d                   	pop    %ebp
80108514:	c3                   	ret    

80108515 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108515:	55                   	push   %ebp
80108516:	89 e5                	mov    %esp,%ebp
80108518:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010851b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108522:	00 
80108523:	8b 45 0c             	mov    0xc(%ebp),%eax
80108526:	89 44 24 04          	mov    %eax,0x4(%esp)
8010852a:	8b 45 08             	mov    0x8(%ebp),%eax
8010852d:	89 04 24             	mov    %eax,(%esp)
80108530:	e8 40 f7 ff ff       	call   80107c75 <walkpgdir>
80108535:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108538:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010853b:	8b 00                	mov    (%eax),%eax
8010853d:	83 e0 01             	and    $0x1,%eax
80108540:	85 c0                	test   %eax,%eax
80108542:	75 07                	jne    8010854b <uva2ka+0x36>
    return 0;
80108544:	b8 00 00 00 00       	mov    $0x0,%eax
80108549:	eb 25                	jmp    80108570 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
8010854b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010854e:	8b 00                	mov    (%eax),%eax
80108550:	83 e0 04             	and    $0x4,%eax
80108553:	85 c0                	test   %eax,%eax
80108555:	75 07                	jne    8010855e <uva2ka+0x49>
    return 0;
80108557:	b8 00 00 00 00       	mov    $0x0,%eax
8010855c:	eb 12                	jmp    80108570 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
8010855e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108561:	8b 00                	mov    (%eax),%eax
80108563:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108568:	89 04 24             	mov    %eax,(%esp)
8010856b:	e8 82 f2 ff ff       	call   801077f2 <p2v>
}
80108570:	c9                   	leave  
80108571:	c3                   	ret    

80108572 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
80108572:	55                   	push   %ebp
80108573:	89 e5                	mov    %esp,%ebp
80108575:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108578:	8b 45 10             	mov    0x10(%ebp),%eax
8010857b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010857e:	e9 87 00 00 00       	jmp    8010860a <copyout+0x98>
    va0 = (uint)PGROUNDDOWN(va);
80108583:	8b 45 0c             	mov    0xc(%ebp),%eax
80108586:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010858b:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010858e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108591:	89 44 24 04          	mov    %eax,0x4(%esp)
80108595:	8b 45 08             	mov    0x8(%ebp),%eax
80108598:	89 04 24             	mov    %eax,(%esp)
8010859b:	e8 75 ff ff ff       	call   80108515 <uva2ka>
801085a0:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801085a3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801085a7:	75 07                	jne    801085b0 <copyout+0x3e>
      return -1;
801085a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801085ae:	eb 69                	jmp    80108619 <copyout+0xa7>
    n = PGSIZE - (va - va0);
801085b0:	8b 45 0c             	mov    0xc(%ebp),%eax
801085b3:	8b 55 ec             	mov    -0x14(%ebp),%edx
801085b6:	29 c2                	sub    %eax,%edx
801085b8:	89 d0                	mov    %edx,%eax
801085ba:	05 00 10 00 00       	add    $0x1000,%eax
801085bf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801085c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085c5:	3b 45 14             	cmp    0x14(%ebp),%eax
801085c8:	76 06                	jbe    801085d0 <copyout+0x5e>
      n = len;
801085ca:	8b 45 14             	mov    0x14(%ebp),%eax
801085cd:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
801085d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801085d3:	8b 55 0c             	mov    0xc(%ebp),%edx
801085d6:	29 c2                	sub    %eax,%edx
801085d8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801085db:	01 c2                	add    %eax,%edx
801085dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085e0:	89 44 24 08          	mov    %eax,0x8(%esp)
801085e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801085eb:	89 14 24             	mov    %edx,(%esp)
801085ee:	e8 29 cd ff ff       	call   8010531c <memmove>
    len -= n;
801085f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085f6:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801085f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085fc:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801085ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108602:	05 00 10 00 00       	add    $0x1000,%eax
80108607:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010860a:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010860e:	0f 85 6f ff ff ff    	jne    80108583 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108614:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108619:	c9                   	leave  
8010861a:	c3                   	ret    
