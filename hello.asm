
_hello:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "types.h"
#include "stat.h"
#include "user.h"
int main(void)
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	83 ec 20             	sub    $0x20,%esp
   int i;
   hello(5);
   9:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
  10:	e8 45 03 00 00       	call   35a <hello>
   int PID;

       PID = fork(1000,1);
  15:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1c:	00 
  1d:	c7 04 24 e8 03 00 00 	movl   $0x3e8,(%esp)
  24:	e8 89 02 00 00       	call   2b2 <fork>
  29:	89 44 24 18          	mov    %eax,0x18(%esp)
        if(PID == 0) 
  2d:	83 7c 24 18 00       	cmpl   $0x0,0x18(%esp)
  32:	75 19                	jne    4d <main+0x4d>
                {
			for(i=0;i<100000000;i++); 
  34:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
  3b:	00 
  3c:	eb 05                	jmp    43 <main+0x43>
  3e:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
  43:	81 7c 24 1c ff e0 f5 	cmpl   $0x5f5e0ff,0x1c(%esp)
  4a:	05 
  4b:	7e f1                	jle    3e <main+0x3e>
		}
   exit();
  4d:	e8 68 02 00 00       	call   2ba <exit>

00000052 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  52:	55                   	push   %ebp
  53:	89 e5                	mov    %esp,%ebp
  55:	57                   	push   %edi
  56:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
  57:	8b 4d 08             	mov    0x8(%ebp),%ecx
  5a:	8b 55 10             	mov    0x10(%ebp),%edx
  5d:	8b 45 0c             	mov    0xc(%ebp),%eax
  60:	89 cb                	mov    %ecx,%ebx
  62:	89 df                	mov    %ebx,%edi
  64:	89 d1                	mov    %edx,%ecx
  66:	fc                   	cld    
  67:	f3 aa                	rep stos %al,%es:(%edi)
  69:	89 ca                	mov    %ecx,%edx
  6b:	89 fb                	mov    %edi,%ebx
  6d:	89 5d 08             	mov    %ebx,0x8(%ebp)
  70:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
  73:	5b                   	pop    %ebx
  74:	5f                   	pop    %edi
  75:	5d                   	pop    %ebp
  76:	c3                   	ret    

00000077 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
  77:	55                   	push   %ebp
  78:	89 e5                	mov    %esp,%ebp
  7a:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
  7d:	8b 45 08             	mov    0x8(%ebp),%eax
  80:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
  83:	90                   	nop
  84:	8b 45 08             	mov    0x8(%ebp),%eax
  87:	8d 50 01             	lea    0x1(%eax),%edx
  8a:	89 55 08             	mov    %edx,0x8(%ebp)
  8d:	8b 55 0c             	mov    0xc(%ebp),%edx
  90:	8d 4a 01             	lea    0x1(%edx),%ecx
  93:	89 4d 0c             	mov    %ecx,0xc(%ebp)
  96:	0f b6 12             	movzbl (%edx),%edx
  99:	88 10                	mov    %dl,(%eax)
  9b:	0f b6 00             	movzbl (%eax),%eax
  9e:	84 c0                	test   %al,%al
  a0:	75 e2                	jne    84 <strcpy+0xd>
    ;
  return os;
  a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  a5:	c9                   	leave  
  a6:	c3                   	ret    

000000a7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  a7:	55                   	push   %ebp
  a8:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
  aa:	eb 08                	jmp    b4 <strcmp+0xd>
    p++, q++;
  ac:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  b0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
  b4:	8b 45 08             	mov    0x8(%ebp),%eax
  b7:	0f b6 00             	movzbl (%eax),%eax
  ba:	84 c0                	test   %al,%al
  bc:	74 10                	je     ce <strcmp+0x27>
  be:	8b 45 08             	mov    0x8(%ebp),%eax
  c1:	0f b6 10             	movzbl (%eax),%edx
  c4:	8b 45 0c             	mov    0xc(%ebp),%eax
  c7:	0f b6 00             	movzbl (%eax),%eax
  ca:	38 c2                	cmp    %al,%dl
  cc:	74 de                	je     ac <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
  ce:	8b 45 08             	mov    0x8(%ebp),%eax
  d1:	0f b6 00             	movzbl (%eax),%eax
  d4:	0f b6 d0             	movzbl %al,%edx
  d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  da:	0f b6 00             	movzbl (%eax),%eax
  dd:	0f b6 c0             	movzbl %al,%eax
  e0:	29 c2                	sub    %eax,%edx
  e2:	89 d0                	mov    %edx,%eax
}
  e4:	5d                   	pop    %ebp
  e5:	c3                   	ret    

000000e6 <strlen>:

uint
strlen(char *s)
{
  e6:	55                   	push   %ebp
  e7:	89 e5                	mov    %esp,%ebp
  e9:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
  ec:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  f3:	eb 04                	jmp    f9 <strlen+0x13>
  f5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  f9:	8b 55 fc             	mov    -0x4(%ebp),%edx
  fc:	8b 45 08             	mov    0x8(%ebp),%eax
  ff:	01 d0                	add    %edx,%eax
 101:	0f b6 00             	movzbl (%eax),%eax
 104:	84 c0                	test   %al,%al
 106:	75 ed                	jne    f5 <strlen+0xf>
    ;
  return n;
 108:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 10b:	c9                   	leave  
 10c:	c3                   	ret    

0000010d <memset>:

void*
memset(void *dst, int c, uint n)
{
 10d:	55                   	push   %ebp
 10e:	89 e5                	mov    %esp,%ebp
 110:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 113:	8b 45 10             	mov    0x10(%ebp),%eax
 116:	89 44 24 08          	mov    %eax,0x8(%esp)
 11a:	8b 45 0c             	mov    0xc(%ebp),%eax
 11d:	89 44 24 04          	mov    %eax,0x4(%esp)
 121:	8b 45 08             	mov    0x8(%ebp),%eax
 124:	89 04 24             	mov    %eax,(%esp)
 127:	e8 26 ff ff ff       	call   52 <stosb>
  return dst;
 12c:	8b 45 08             	mov    0x8(%ebp),%eax
}
 12f:	c9                   	leave  
 130:	c3                   	ret    

00000131 <strchr>:

char*
strchr(const char *s, char c)
{
 131:	55                   	push   %ebp
 132:	89 e5                	mov    %esp,%ebp
 134:	83 ec 04             	sub    $0x4,%esp
 137:	8b 45 0c             	mov    0xc(%ebp),%eax
 13a:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 13d:	eb 14                	jmp    153 <strchr+0x22>
    if(*s == c)
 13f:	8b 45 08             	mov    0x8(%ebp),%eax
 142:	0f b6 00             	movzbl (%eax),%eax
 145:	3a 45 fc             	cmp    -0x4(%ebp),%al
 148:	75 05                	jne    14f <strchr+0x1e>
      return (char*)s;
 14a:	8b 45 08             	mov    0x8(%ebp),%eax
 14d:	eb 13                	jmp    162 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 14f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 153:	8b 45 08             	mov    0x8(%ebp),%eax
 156:	0f b6 00             	movzbl (%eax),%eax
 159:	84 c0                	test   %al,%al
 15b:	75 e2                	jne    13f <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 15d:	b8 00 00 00 00       	mov    $0x0,%eax
}
 162:	c9                   	leave  
 163:	c3                   	ret    

00000164 <gets>:

char*
gets(char *buf, int max)
{
 164:	55                   	push   %ebp
 165:	89 e5                	mov    %esp,%ebp
 167:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 16a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 171:	eb 4c                	jmp    1bf <gets+0x5b>
    cc = read(0, &c, 1);
 173:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 17a:	00 
 17b:	8d 45 ef             	lea    -0x11(%ebp),%eax
 17e:	89 44 24 04          	mov    %eax,0x4(%esp)
 182:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 189:	e8 44 01 00 00       	call   2d2 <read>
 18e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 191:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 195:	7f 02                	jg     199 <gets+0x35>
      break;
 197:	eb 31                	jmp    1ca <gets+0x66>
    buf[i++] = c;
 199:	8b 45 f4             	mov    -0xc(%ebp),%eax
 19c:	8d 50 01             	lea    0x1(%eax),%edx
 19f:	89 55 f4             	mov    %edx,-0xc(%ebp)
 1a2:	89 c2                	mov    %eax,%edx
 1a4:	8b 45 08             	mov    0x8(%ebp),%eax
 1a7:	01 c2                	add    %eax,%edx
 1a9:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 1ad:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 1af:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 1b3:	3c 0a                	cmp    $0xa,%al
 1b5:	74 13                	je     1ca <gets+0x66>
 1b7:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 1bb:	3c 0d                	cmp    $0xd,%al
 1bd:	74 0b                	je     1ca <gets+0x66>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
 1c2:	83 c0 01             	add    $0x1,%eax
 1c5:	3b 45 0c             	cmp    0xc(%ebp),%eax
 1c8:	7c a9                	jl     173 <gets+0xf>
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 1ca:	8b 55 f4             	mov    -0xc(%ebp),%edx
 1cd:	8b 45 08             	mov    0x8(%ebp),%eax
 1d0:	01 d0                	add    %edx,%eax
 1d2:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 1d5:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1d8:	c9                   	leave  
 1d9:	c3                   	ret    

000001da <stat>:

int
stat(char *n, struct stat *st)
{
 1da:	55                   	push   %ebp
 1db:	89 e5                	mov    %esp,%ebp
 1dd:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1e0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 1e7:	00 
 1e8:	8b 45 08             	mov    0x8(%ebp),%eax
 1eb:	89 04 24             	mov    %eax,(%esp)
 1ee:	e8 07 01 00 00       	call   2fa <open>
 1f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 1f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 1fa:	79 07                	jns    203 <stat+0x29>
    return -1;
 1fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 201:	eb 23                	jmp    226 <stat+0x4c>
  r = fstat(fd, st);
 203:	8b 45 0c             	mov    0xc(%ebp),%eax
 206:	89 44 24 04          	mov    %eax,0x4(%esp)
 20a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 20d:	89 04 24             	mov    %eax,(%esp)
 210:	e8 fd 00 00 00       	call   312 <fstat>
 215:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 218:	8b 45 f4             	mov    -0xc(%ebp),%eax
 21b:	89 04 24             	mov    %eax,(%esp)
 21e:	e8 bf 00 00 00       	call   2e2 <close>
  return r;
 223:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 226:	c9                   	leave  
 227:	c3                   	ret    

00000228 <atoi>:

int
atoi(const char *s)
{
 228:	55                   	push   %ebp
 229:	89 e5                	mov    %esp,%ebp
 22b:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 22e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 235:	eb 25                	jmp    25c <atoi+0x34>
    n = n*10 + *s++ - '0';
 237:	8b 55 fc             	mov    -0x4(%ebp),%edx
 23a:	89 d0                	mov    %edx,%eax
 23c:	c1 e0 02             	shl    $0x2,%eax
 23f:	01 d0                	add    %edx,%eax
 241:	01 c0                	add    %eax,%eax
 243:	89 c1                	mov    %eax,%ecx
 245:	8b 45 08             	mov    0x8(%ebp),%eax
 248:	8d 50 01             	lea    0x1(%eax),%edx
 24b:	89 55 08             	mov    %edx,0x8(%ebp)
 24e:	0f b6 00             	movzbl (%eax),%eax
 251:	0f be c0             	movsbl %al,%eax
 254:	01 c8                	add    %ecx,%eax
 256:	83 e8 30             	sub    $0x30,%eax
 259:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 25c:	8b 45 08             	mov    0x8(%ebp),%eax
 25f:	0f b6 00             	movzbl (%eax),%eax
 262:	3c 2f                	cmp    $0x2f,%al
 264:	7e 0a                	jle    270 <atoi+0x48>
 266:	8b 45 08             	mov    0x8(%ebp),%eax
 269:	0f b6 00             	movzbl (%eax),%eax
 26c:	3c 39                	cmp    $0x39,%al
 26e:	7e c7                	jle    237 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 270:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 273:	c9                   	leave  
 274:	c3                   	ret    

00000275 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 275:	55                   	push   %ebp
 276:	89 e5                	mov    %esp,%ebp
 278:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 27b:	8b 45 08             	mov    0x8(%ebp),%eax
 27e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 281:	8b 45 0c             	mov    0xc(%ebp),%eax
 284:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 287:	eb 17                	jmp    2a0 <memmove+0x2b>
    *dst++ = *src++;
 289:	8b 45 fc             	mov    -0x4(%ebp),%eax
 28c:	8d 50 01             	lea    0x1(%eax),%edx
 28f:	89 55 fc             	mov    %edx,-0x4(%ebp)
 292:	8b 55 f8             	mov    -0x8(%ebp),%edx
 295:	8d 4a 01             	lea    0x1(%edx),%ecx
 298:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 29b:	0f b6 12             	movzbl (%edx),%edx
 29e:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 2a0:	8b 45 10             	mov    0x10(%ebp),%eax
 2a3:	8d 50 ff             	lea    -0x1(%eax),%edx
 2a6:	89 55 10             	mov    %edx,0x10(%ebp)
 2a9:	85 c0                	test   %eax,%eax
 2ab:	7f dc                	jg     289 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 2ad:	8b 45 08             	mov    0x8(%ebp),%eax
}
 2b0:	c9                   	leave  
 2b1:	c3                   	ret    

000002b2 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 2b2:	b8 01 00 00 00       	mov    $0x1,%eax
 2b7:	cd 40                	int    $0x40
 2b9:	c3                   	ret    

000002ba <exit>:
SYSCALL(exit)
 2ba:	b8 02 00 00 00       	mov    $0x2,%eax
 2bf:	cd 40                	int    $0x40
 2c1:	c3                   	ret    

000002c2 <wait>:
SYSCALL(wait)
 2c2:	b8 03 00 00 00       	mov    $0x3,%eax
 2c7:	cd 40                	int    $0x40
 2c9:	c3                   	ret    

000002ca <pipe>:
SYSCALL(pipe)
 2ca:	b8 04 00 00 00       	mov    $0x4,%eax
 2cf:	cd 40                	int    $0x40
 2d1:	c3                   	ret    

000002d2 <read>:
SYSCALL(read)
 2d2:	b8 05 00 00 00       	mov    $0x5,%eax
 2d7:	cd 40                	int    $0x40
 2d9:	c3                   	ret    

000002da <write>:
SYSCALL(write)
 2da:	b8 10 00 00 00       	mov    $0x10,%eax
 2df:	cd 40                	int    $0x40
 2e1:	c3                   	ret    

000002e2 <close>:
SYSCALL(close)
 2e2:	b8 15 00 00 00       	mov    $0x15,%eax
 2e7:	cd 40                	int    $0x40
 2e9:	c3                   	ret    

000002ea <kill>:
SYSCALL(kill)
 2ea:	b8 06 00 00 00       	mov    $0x6,%eax
 2ef:	cd 40                	int    $0x40
 2f1:	c3                   	ret    

000002f2 <exec>:
SYSCALL(exec)
 2f2:	b8 07 00 00 00       	mov    $0x7,%eax
 2f7:	cd 40                	int    $0x40
 2f9:	c3                   	ret    

000002fa <open>:
SYSCALL(open)
 2fa:	b8 0f 00 00 00       	mov    $0xf,%eax
 2ff:	cd 40                	int    $0x40
 301:	c3                   	ret    

00000302 <mknod>:
SYSCALL(mknod)
 302:	b8 11 00 00 00       	mov    $0x11,%eax
 307:	cd 40                	int    $0x40
 309:	c3                   	ret    

0000030a <unlink>:
SYSCALL(unlink)
 30a:	b8 12 00 00 00       	mov    $0x12,%eax
 30f:	cd 40                	int    $0x40
 311:	c3                   	ret    

00000312 <fstat>:
SYSCALL(fstat)
 312:	b8 08 00 00 00       	mov    $0x8,%eax
 317:	cd 40                	int    $0x40
 319:	c3                   	ret    

0000031a <link>:
SYSCALL(link)
 31a:	b8 13 00 00 00       	mov    $0x13,%eax
 31f:	cd 40                	int    $0x40
 321:	c3                   	ret    

00000322 <mkdir>:
SYSCALL(mkdir)
 322:	b8 14 00 00 00       	mov    $0x14,%eax
 327:	cd 40                	int    $0x40
 329:	c3                   	ret    

0000032a <chdir>:
SYSCALL(chdir)
 32a:	b8 09 00 00 00       	mov    $0x9,%eax
 32f:	cd 40                	int    $0x40
 331:	c3                   	ret    

00000332 <dup>:
SYSCALL(dup)
 332:	b8 0a 00 00 00       	mov    $0xa,%eax
 337:	cd 40                	int    $0x40
 339:	c3                   	ret    

0000033a <getpid>:
SYSCALL(getpid)
 33a:	b8 0b 00 00 00       	mov    $0xb,%eax
 33f:	cd 40                	int    $0x40
 341:	c3                   	ret    

00000342 <sbrk>:
SYSCALL(sbrk)
 342:	b8 0c 00 00 00       	mov    $0xc,%eax
 347:	cd 40                	int    $0x40
 349:	c3                   	ret    

0000034a <sleep>:
SYSCALL(sleep)
 34a:	b8 0d 00 00 00       	mov    $0xd,%eax
 34f:	cd 40                	int    $0x40
 351:	c3                   	ret    

00000352 <uptime>:
SYSCALL(uptime)
 352:	b8 0e 00 00 00       	mov    $0xe,%eax
 357:	cd 40                	int    $0x40
 359:	c3                   	ret    

0000035a <hello>:
SYSCALL(hello)
 35a:	b8 16 00 00 00       	mov    $0x16,%eax
 35f:	cd 40                	int    $0x40
 361:	c3                   	ret    

00000362 <cps>:
SYSCALL(cps)
 362:	b8 17 00 00 00       	mov    $0x17,%eax
 367:	cd 40                	int    $0x40
 369:	c3                   	ret    

0000036a <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 36a:	55                   	push   %ebp
 36b:	89 e5                	mov    %esp,%ebp
 36d:	83 ec 18             	sub    $0x18,%esp
 370:	8b 45 0c             	mov    0xc(%ebp),%eax
 373:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 376:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 37d:	00 
 37e:	8d 45 f4             	lea    -0xc(%ebp),%eax
 381:	89 44 24 04          	mov    %eax,0x4(%esp)
 385:	8b 45 08             	mov    0x8(%ebp),%eax
 388:	89 04 24             	mov    %eax,(%esp)
 38b:	e8 4a ff ff ff       	call   2da <write>
}
 390:	c9                   	leave  
 391:	c3                   	ret    

00000392 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 392:	55                   	push   %ebp
 393:	89 e5                	mov    %esp,%ebp
 395:	56                   	push   %esi
 396:	53                   	push   %ebx
 397:	83 ec 30             	sub    $0x30,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 39a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 3a1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 3a5:	74 17                	je     3be <printint+0x2c>
 3a7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 3ab:	79 11                	jns    3be <printint+0x2c>
    neg = 1;
 3ad:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 3b4:	8b 45 0c             	mov    0xc(%ebp),%eax
 3b7:	f7 d8                	neg    %eax
 3b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
 3bc:	eb 06                	jmp    3c4 <printint+0x32>
  } else {
    x = xx;
 3be:	8b 45 0c             	mov    0xc(%ebp),%eax
 3c1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 3c4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 3cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 3ce:	8d 41 01             	lea    0x1(%ecx),%eax
 3d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
 3d4:	8b 5d 10             	mov    0x10(%ebp),%ebx
 3d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3da:	ba 00 00 00 00       	mov    $0x0,%edx
 3df:	f7 f3                	div    %ebx
 3e1:	89 d0                	mov    %edx,%eax
 3e3:	0f b6 80 64 0a 00 00 	movzbl 0xa64(%eax),%eax
 3ea:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 3ee:	8b 75 10             	mov    0x10(%ebp),%esi
 3f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
 3f4:	ba 00 00 00 00       	mov    $0x0,%edx
 3f9:	f7 f6                	div    %esi
 3fb:	89 45 ec             	mov    %eax,-0x14(%ebp)
 3fe:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 402:	75 c7                	jne    3cb <printint+0x39>
  if(neg)
 404:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 408:	74 10                	je     41a <printint+0x88>
    buf[i++] = '-';
 40a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 40d:	8d 50 01             	lea    0x1(%eax),%edx
 410:	89 55 f4             	mov    %edx,-0xc(%ebp)
 413:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 418:	eb 1f                	jmp    439 <printint+0xa7>
 41a:	eb 1d                	jmp    439 <printint+0xa7>
    putc(fd, buf[i]);
 41c:	8d 55 dc             	lea    -0x24(%ebp),%edx
 41f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 422:	01 d0                	add    %edx,%eax
 424:	0f b6 00             	movzbl (%eax),%eax
 427:	0f be c0             	movsbl %al,%eax
 42a:	89 44 24 04          	mov    %eax,0x4(%esp)
 42e:	8b 45 08             	mov    0x8(%ebp),%eax
 431:	89 04 24             	mov    %eax,(%esp)
 434:	e8 31 ff ff ff       	call   36a <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 439:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 43d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 441:	79 d9                	jns    41c <printint+0x8a>
    putc(fd, buf[i]);
}
 443:	83 c4 30             	add    $0x30,%esp
 446:	5b                   	pop    %ebx
 447:	5e                   	pop    %esi
 448:	5d                   	pop    %ebp
 449:	c3                   	ret    

0000044a <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 44a:	55                   	push   %ebp
 44b:	89 e5                	mov    %esp,%ebp
 44d:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 450:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 457:	8d 45 0c             	lea    0xc(%ebp),%eax
 45a:	83 c0 04             	add    $0x4,%eax
 45d:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 460:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 467:	e9 7c 01 00 00       	jmp    5e8 <printf+0x19e>
    c = fmt[i] & 0xff;
 46c:	8b 55 0c             	mov    0xc(%ebp),%edx
 46f:	8b 45 f0             	mov    -0x10(%ebp),%eax
 472:	01 d0                	add    %edx,%eax
 474:	0f b6 00             	movzbl (%eax),%eax
 477:	0f be c0             	movsbl %al,%eax
 47a:	25 ff 00 00 00       	and    $0xff,%eax
 47f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 482:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 486:	75 2c                	jne    4b4 <printf+0x6a>
      if(c == '%'){
 488:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 48c:	75 0c                	jne    49a <printf+0x50>
        state = '%';
 48e:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 495:	e9 4a 01 00 00       	jmp    5e4 <printf+0x19a>
      } else {
        putc(fd, c);
 49a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 49d:	0f be c0             	movsbl %al,%eax
 4a0:	89 44 24 04          	mov    %eax,0x4(%esp)
 4a4:	8b 45 08             	mov    0x8(%ebp),%eax
 4a7:	89 04 24             	mov    %eax,(%esp)
 4aa:	e8 bb fe ff ff       	call   36a <putc>
 4af:	e9 30 01 00 00       	jmp    5e4 <printf+0x19a>
      }
    } else if(state == '%'){
 4b4:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 4b8:	0f 85 26 01 00 00    	jne    5e4 <printf+0x19a>
      if(c == 'd'){
 4be:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 4c2:	75 2d                	jne    4f1 <printf+0xa7>
        printint(fd, *ap, 10, 1);
 4c4:	8b 45 e8             	mov    -0x18(%ebp),%eax
 4c7:	8b 00                	mov    (%eax),%eax
 4c9:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 4d0:	00 
 4d1:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 4d8:	00 
 4d9:	89 44 24 04          	mov    %eax,0x4(%esp)
 4dd:	8b 45 08             	mov    0x8(%ebp),%eax
 4e0:	89 04 24             	mov    %eax,(%esp)
 4e3:	e8 aa fe ff ff       	call   392 <printint>
        ap++;
 4e8:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 4ec:	e9 ec 00 00 00       	jmp    5dd <printf+0x193>
      } else if(c == 'x' || c == 'p'){
 4f1:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 4f5:	74 06                	je     4fd <printf+0xb3>
 4f7:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 4fb:	75 2d                	jne    52a <printf+0xe0>
        printint(fd, *ap, 16, 0);
 4fd:	8b 45 e8             	mov    -0x18(%ebp),%eax
 500:	8b 00                	mov    (%eax),%eax
 502:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 509:	00 
 50a:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 511:	00 
 512:	89 44 24 04          	mov    %eax,0x4(%esp)
 516:	8b 45 08             	mov    0x8(%ebp),%eax
 519:	89 04 24             	mov    %eax,(%esp)
 51c:	e8 71 fe ff ff       	call   392 <printint>
        ap++;
 521:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 525:	e9 b3 00 00 00       	jmp    5dd <printf+0x193>
      } else if(c == 's'){
 52a:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 52e:	75 45                	jne    575 <printf+0x12b>
        s = (char*)*ap;
 530:	8b 45 e8             	mov    -0x18(%ebp),%eax
 533:	8b 00                	mov    (%eax),%eax
 535:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 538:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 53c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 540:	75 09                	jne    54b <printf+0x101>
          s = "(null)";
 542:	c7 45 f4 16 08 00 00 	movl   $0x816,-0xc(%ebp)
        while(*s != 0){
 549:	eb 1e                	jmp    569 <printf+0x11f>
 54b:	eb 1c                	jmp    569 <printf+0x11f>
          putc(fd, *s);
 54d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 550:	0f b6 00             	movzbl (%eax),%eax
 553:	0f be c0             	movsbl %al,%eax
 556:	89 44 24 04          	mov    %eax,0x4(%esp)
 55a:	8b 45 08             	mov    0x8(%ebp),%eax
 55d:	89 04 24             	mov    %eax,(%esp)
 560:	e8 05 fe ff ff       	call   36a <putc>
          s++;
 565:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 569:	8b 45 f4             	mov    -0xc(%ebp),%eax
 56c:	0f b6 00             	movzbl (%eax),%eax
 56f:	84 c0                	test   %al,%al
 571:	75 da                	jne    54d <printf+0x103>
 573:	eb 68                	jmp    5dd <printf+0x193>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 575:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 579:	75 1d                	jne    598 <printf+0x14e>
        putc(fd, *ap);
 57b:	8b 45 e8             	mov    -0x18(%ebp),%eax
 57e:	8b 00                	mov    (%eax),%eax
 580:	0f be c0             	movsbl %al,%eax
 583:	89 44 24 04          	mov    %eax,0x4(%esp)
 587:	8b 45 08             	mov    0x8(%ebp),%eax
 58a:	89 04 24             	mov    %eax,(%esp)
 58d:	e8 d8 fd ff ff       	call   36a <putc>
        ap++;
 592:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 596:	eb 45                	jmp    5dd <printf+0x193>
      } else if(c == '%'){
 598:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 59c:	75 17                	jne    5b5 <printf+0x16b>
        putc(fd, c);
 59e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5a1:	0f be c0             	movsbl %al,%eax
 5a4:	89 44 24 04          	mov    %eax,0x4(%esp)
 5a8:	8b 45 08             	mov    0x8(%ebp),%eax
 5ab:	89 04 24             	mov    %eax,(%esp)
 5ae:	e8 b7 fd ff ff       	call   36a <putc>
 5b3:	eb 28                	jmp    5dd <printf+0x193>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5b5:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 5bc:	00 
 5bd:	8b 45 08             	mov    0x8(%ebp),%eax
 5c0:	89 04 24             	mov    %eax,(%esp)
 5c3:	e8 a2 fd ff ff       	call   36a <putc>
        putc(fd, c);
 5c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5cb:	0f be c0             	movsbl %al,%eax
 5ce:	89 44 24 04          	mov    %eax,0x4(%esp)
 5d2:	8b 45 08             	mov    0x8(%ebp),%eax
 5d5:	89 04 24             	mov    %eax,(%esp)
 5d8:	e8 8d fd ff ff       	call   36a <putc>
      }
      state = 0;
 5dd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 5e4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 5e8:	8b 55 0c             	mov    0xc(%ebp),%edx
 5eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
 5ee:	01 d0                	add    %edx,%eax
 5f0:	0f b6 00             	movzbl (%eax),%eax
 5f3:	84 c0                	test   %al,%al
 5f5:	0f 85 71 fe ff ff    	jne    46c <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 5fb:	c9                   	leave  
 5fc:	c3                   	ret    

000005fd <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 5fd:	55                   	push   %ebp
 5fe:	89 e5                	mov    %esp,%ebp
 600:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 603:	8b 45 08             	mov    0x8(%ebp),%eax
 606:	83 e8 08             	sub    $0x8,%eax
 609:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 60c:	a1 80 0a 00 00       	mov    0xa80,%eax
 611:	89 45 fc             	mov    %eax,-0x4(%ebp)
 614:	eb 24                	jmp    63a <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 616:	8b 45 fc             	mov    -0x4(%ebp),%eax
 619:	8b 00                	mov    (%eax),%eax
 61b:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 61e:	77 12                	ja     632 <free+0x35>
 620:	8b 45 f8             	mov    -0x8(%ebp),%eax
 623:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 626:	77 24                	ja     64c <free+0x4f>
 628:	8b 45 fc             	mov    -0x4(%ebp),%eax
 62b:	8b 00                	mov    (%eax),%eax
 62d:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 630:	77 1a                	ja     64c <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 632:	8b 45 fc             	mov    -0x4(%ebp),%eax
 635:	8b 00                	mov    (%eax),%eax
 637:	89 45 fc             	mov    %eax,-0x4(%ebp)
 63a:	8b 45 f8             	mov    -0x8(%ebp),%eax
 63d:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 640:	76 d4                	jbe    616 <free+0x19>
 642:	8b 45 fc             	mov    -0x4(%ebp),%eax
 645:	8b 00                	mov    (%eax),%eax
 647:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 64a:	76 ca                	jbe    616 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 64c:	8b 45 f8             	mov    -0x8(%ebp),%eax
 64f:	8b 40 04             	mov    0x4(%eax),%eax
 652:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 659:	8b 45 f8             	mov    -0x8(%ebp),%eax
 65c:	01 c2                	add    %eax,%edx
 65e:	8b 45 fc             	mov    -0x4(%ebp),%eax
 661:	8b 00                	mov    (%eax),%eax
 663:	39 c2                	cmp    %eax,%edx
 665:	75 24                	jne    68b <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 667:	8b 45 f8             	mov    -0x8(%ebp),%eax
 66a:	8b 50 04             	mov    0x4(%eax),%edx
 66d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 670:	8b 00                	mov    (%eax),%eax
 672:	8b 40 04             	mov    0x4(%eax),%eax
 675:	01 c2                	add    %eax,%edx
 677:	8b 45 f8             	mov    -0x8(%ebp),%eax
 67a:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 67d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 680:	8b 00                	mov    (%eax),%eax
 682:	8b 10                	mov    (%eax),%edx
 684:	8b 45 f8             	mov    -0x8(%ebp),%eax
 687:	89 10                	mov    %edx,(%eax)
 689:	eb 0a                	jmp    695 <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 68b:	8b 45 fc             	mov    -0x4(%ebp),%eax
 68e:	8b 10                	mov    (%eax),%edx
 690:	8b 45 f8             	mov    -0x8(%ebp),%eax
 693:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 695:	8b 45 fc             	mov    -0x4(%ebp),%eax
 698:	8b 40 04             	mov    0x4(%eax),%eax
 69b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 6a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6a5:	01 d0                	add    %edx,%eax
 6a7:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6aa:	75 20                	jne    6cc <free+0xcf>
    p->s.size += bp->s.size;
 6ac:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6af:	8b 50 04             	mov    0x4(%eax),%edx
 6b2:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6b5:	8b 40 04             	mov    0x4(%eax),%eax
 6b8:	01 c2                	add    %eax,%edx
 6ba:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6bd:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 6c0:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6c3:	8b 10                	mov    (%eax),%edx
 6c5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6c8:	89 10                	mov    %edx,(%eax)
 6ca:	eb 08                	jmp    6d4 <free+0xd7>
  } else
    p->s.ptr = bp;
 6cc:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6cf:	8b 55 f8             	mov    -0x8(%ebp),%edx
 6d2:	89 10                	mov    %edx,(%eax)
  freep = p;
 6d4:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6d7:	a3 80 0a 00 00       	mov    %eax,0xa80
}
 6dc:	c9                   	leave  
 6dd:	c3                   	ret    

000006de <morecore>:

static Header*
morecore(uint nu)
{
 6de:	55                   	push   %ebp
 6df:	89 e5                	mov    %esp,%ebp
 6e1:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 6e4:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 6eb:	77 07                	ja     6f4 <morecore+0x16>
    nu = 4096;
 6ed:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 6f4:	8b 45 08             	mov    0x8(%ebp),%eax
 6f7:	c1 e0 03             	shl    $0x3,%eax
 6fa:	89 04 24             	mov    %eax,(%esp)
 6fd:	e8 40 fc ff ff       	call   342 <sbrk>
 702:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 705:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 709:	75 07                	jne    712 <morecore+0x34>
    return 0;
 70b:	b8 00 00 00 00       	mov    $0x0,%eax
 710:	eb 22                	jmp    734 <morecore+0x56>
  hp = (Header*)p;
 712:	8b 45 f4             	mov    -0xc(%ebp),%eax
 715:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 718:	8b 45 f0             	mov    -0x10(%ebp),%eax
 71b:	8b 55 08             	mov    0x8(%ebp),%edx
 71e:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 721:	8b 45 f0             	mov    -0x10(%ebp),%eax
 724:	83 c0 08             	add    $0x8,%eax
 727:	89 04 24             	mov    %eax,(%esp)
 72a:	e8 ce fe ff ff       	call   5fd <free>
  return freep;
 72f:	a1 80 0a 00 00       	mov    0xa80,%eax
}
 734:	c9                   	leave  
 735:	c3                   	ret    

00000736 <malloc>:

void*
malloc(uint nbytes)
{
 736:	55                   	push   %ebp
 737:	89 e5                	mov    %esp,%ebp
 739:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 73c:	8b 45 08             	mov    0x8(%ebp),%eax
 73f:	83 c0 07             	add    $0x7,%eax
 742:	c1 e8 03             	shr    $0x3,%eax
 745:	83 c0 01             	add    $0x1,%eax
 748:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 74b:	a1 80 0a 00 00       	mov    0xa80,%eax
 750:	89 45 f0             	mov    %eax,-0x10(%ebp)
 753:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 757:	75 23                	jne    77c <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 759:	c7 45 f0 78 0a 00 00 	movl   $0xa78,-0x10(%ebp)
 760:	8b 45 f0             	mov    -0x10(%ebp),%eax
 763:	a3 80 0a 00 00       	mov    %eax,0xa80
 768:	a1 80 0a 00 00       	mov    0xa80,%eax
 76d:	a3 78 0a 00 00       	mov    %eax,0xa78
    base.s.size = 0;
 772:	c7 05 7c 0a 00 00 00 	movl   $0x0,0xa7c
 779:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 77c:	8b 45 f0             	mov    -0x10(%ebp),%eax
 77f:	8b 00                	mov    (%eax),%eax
 781:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 784:	8b 45 f4             	mov    -0xc(%ebp),%eax
 787:	8b 40 04             	mov    0x4(%eax),%eax
 78a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 78d:	72 4d                	jb     7dc <malloc+0xa6>
      if(p->s.size == nunits)
 78f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 792:	8b 40 04             	mov    0x4(%eax),%eax
 795:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 798:	75 0c                	jne    7a6 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 79a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 79d:	8b 10                	mov    (%eax),%edx
 79f:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7a2:	89 10                	mov    %edx,(%eax)
 7a4:	eb 26                	jmp    7cc <malloc+0x96>
      else {
        p->s.size -= nunits;
 7a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7a9:	8b 40 04             	mov    0x4(%eax),%eax
 7ac:	2b 45 ec             	sub    -0x14(%ebp),%eax
 7af:	89 c2                	mov    %eax,%edx
 7b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7b4:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 7b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7ba:	8b 40 04             	mov    0x4(%eax),%eax
 7bd:	c1 e0 03             	shl    $0x3,%eax
 7c0:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 7c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7c6:	8b 55 ec             	mov    -0x14(%ebp),%edx
 7c9:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 7cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7cf:	a3 80 0a 00 00       	mov    %eax,0xa80
      return (void*)(p + 1);
 7d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 7d7:	83 c0 08             	add    $0x8,%eax
 7da:	eb 38                	jmp    814 <malloc+0xde>
    }
    if(p == freep)
 7dc:	a1 80 0a 00 00       	mov    0xa80,%eax
 7e1:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 7e4:	75 1b                	jne    801 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 7e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
 7e9:	89 04 24             	mov    %eax,(%esp)
 7ec:	e8 ed fe ff ff       	call   6de <morecore>
 7f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
 7f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 7f8:	75 07                	jne    801 <malloc+0xcb>
        return 0;
 7fa:	b8 00 00 00 00       	mov    $0x0,%eax
 7ff:	eb 13                	jmp    814 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 801:	8b 45 f4             	mov    -0xc(%ebp),%eax
 804:	89 45 f0             	mov    %eax,-0x10(%ebp)
 807:	8b 45 f4             	mov    -0xc(%ebp),%eax
 80a:	8b 00                	mov    (%eax),%eax
 80c:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 80f:	e9 70 ff ff ff       	jmp    784 <malloc+0x4e>
}
 814:	c9                   	leave  
 815:	c3                   	ret    
