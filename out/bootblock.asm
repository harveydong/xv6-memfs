
out/bootblock.o:     file format elf32-i386


Disassembly of section .text:

00007c00 <start>:
    7c00:	fa                   	cli    
    7c01:	31 c0                	xor    %eax,%eax
    7c03:	8e d8                	mov    %eax,%ds
    7c05:	8e c0                	mov    %eax,%es
    7c07:	8e d0                	mov    %eax,%ss

00007c09 <seta20.1>:
    7c09:	e4 64                	in     $0x64,%al
    7c0b:	a8 02                	test   $0x2,%al
    7c0d:	75 fa                	jne    7c09 <seta20.1>
    7c0f:	b0 d1                	mov    $0xd1,%al
    7c11:	e6 64                	out    %al,$0x64

00007c13 <seta20.2>:
    7c13:	e4 64                	in     $0x64,%al
    7c15:	a8 02                	test   $0x2,%al
    7c17:	75 fa                	jne    7c13 <seta20.2>
    7c19:	b0 df                	mov    $0xdf,%al
    7c1b:	e6 60                	out    %al,$0x60
    7c1d:	0f 01 16             	lgdtl  (%esi)
    7c20:	68 7c 0f 20 c0       	push   $0xc0200f7c
    7c25:	66 83 c8 01          	or     $0x1,%ax
    7c29:	0f 22 c0             	mov    %eax,%cr0
    7c2c:	ea                   	.byte 0xea
    7c2d:	31 7c 08 00          	xor    %edi,0x0(%eax,%ecx,1)

00007c31 <start32>:
    7c31:	66 b8 10 00          	mov    $0x10,%ax
    7c35:	8e d8                	mov    %eax,%ds
    7c37:	8e c0                	mov    %eax,%es
    7c39:	8e d0                	mov    %eax,%ss
    7c3b:	66 b8 00 00          	mov    $0x0,%ax
    7c3f:	8e e0                	mov    %eax,%fs
    7c41:	8e e8                	mov    %eax,%gs
    7c43:	bc 00 7c 00 00       	mov    $0x7c00,%esp
    7c48:	e8 b9 00 00 00       	call   7d06 <bootmain>

00007c4d <spin>:
    7c4d:	eb fe                	jmp    7c4d <spin>
    7c4f:	90                   	nop

00007c50 <gdt>:
	...
    7c58:	ff                   	(bad)  
    7c59:	ff 00                	incl   (%eax)
    7c5b:	00 00                	add    %al,(%eax)
    7c5d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c64:	00                   	.byte 0x0
    7c65:	92                   	xchg   %eax,%edx
    7c66:	cf                   	iret   
	...

00007c68 <gdtdesc>:
    7c68:	17                   	pop    %ss
    7c69:	00 50 7c             	add    %dl,0x7c(%eax)
	...

00007c6e <readseg>:
    7c6e:	55                   	push   %ebp
    7c6f:	89 e5                	mov    %esp,%ebp
    7c71:	57                   	push   %edi
    7c72:	8d 3c 10             	lea    (%eax,%edx,1),%edi
    7c75:	89 ca                	mov    %ecx,%edx
    7c77:	c1 e9 09             	shr    $0x9,%ecx
    7c7a:	56                   	push   %esi
    7c7b:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
    7c81:	8d 71 01             	lea    0x1(%ecx),%esi
    7c84:	53                   	push   %ebx
    7c85:	29 d0                	sub    %edx,%eax
    7c87:	53                   	push   %ebx
    7c88:	89 7d f0             	mov    %edi,-0x10(%ebp)
    7c8b:	89 c3                	mov    %eax,%ebx
    7c8d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
    7c90:	73 6e                	jae    7d00 <readseg+0x92>
    7c92:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c97:	ec                   	in     (%dx),%al
    7c98:	83 e0 c0             	and    $0xffffffc0,%eax
    7c9b:	3c 40                	cmp    $0x40,%al
    7c9d:	75 f3                	jne    7c92 <readseg+0x24>
    7c9f:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7ca4:	b0 01                	mov    $0x1,%al
    7ca6:	ee                   	out    %al,(%dx)
    7ca7:	ba f3 01 00 00       	mov    $0x1f3,%edx
    7cac:	89 f0                	mov    %esi,%eax
    7cae:	ee                   	out    %al,(%dx)
    7caf:	89 f0                	mov    %esi,%eax
    7cb1:	ba f4 01 00 00       	mov    $0x1f4,%edx
    7cb6:	c1 e8 08             	shr    $0x8,%eax
    7cb9:	ee                   	out    %al,(%dx)
    7cba:	89 f0                	mov    %esi,%eax
    7cbc:	ba f5 01 00 00       	mov    $0x1f5,%edx
    7cc1:	c1 e8 10             	shr    $0x10,%eax
    7cc4:	ee                   	out    %al,(%dx)
    7cc5:	89 f0                	mov    %esi,%eax
    7cc7:	ba f6 01 00 00       	mov    $0x1f6,%edx
    7ccc:	c1 e8 18             	shr    $0x18,%eax
    7ccf:	83 c8 e0             	or     $0xffffffe0,%eax
    7cd2:	ee                   	out    %al,(%dx)
    7cd3:	b0 20                	mov    $0x20,%al
    7cd5:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7cda:	ee                   	out    %al,(%dx)
    7cdb:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7ce0:	ec                   	in     (%dx),%al
    7ce1:	83 e0 c0             	and    $0xffffffc0,%eax
    7ce4:	3c 40                	cmp    $0x40,%al
    7ce6:	75 f3                	jne    7cdb <readseg+0x6d>
    7ce8:	89 df                	mov    %ebx,%edi
    7cea:	b9 80 00 00 00       	mov    $0x80,%ecx
    7cef:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7cf4:	fc                   	cld    
    7cf5:	f3 6d                	rep insl (%dx),%es:(%edi)
    7cf7:	81 c3 00 02 00 00    	add    $0x200,%ebx
    7cfd:	46                   	inc    %esi
    7cfe:	eb 8d                	jmp    7c8d <readseg+0x1f>
    7d00:	58                   	pop    %eax
    7d01:	5b                   	pop    %ebx
    7d02:	5e                   	pop    %esi
    7d03:	5f                   	pop    %edi
    7d04:	5d                   	pop    %ebp
    7d05:	c3                   	ret    

00007d06 <bootmain>:
    7d06:	55                   	push   %ebp
    7d07:	31 c9                	xor    %ecx,%ecx
    7d09:	ba 00 20 00 00       	mov    $0x2000,%edx
    7d0e:	b8 00 00 01 00       	mov    $0x10000,%eax
    7d13:	89 e5                	mov    %esp,%ebp
    7d15:	57                   	push   %edi
    7d16:	56                   	push   %esi
    7d17:	53                   	push   %ebx
    7d18:	bb 00 00 01 00       	mov    $0x10000,%ebx
    7d1d:	83 ec 0c             	sub    $0xc,%esp
    7d20:	e8 49 ff ff ff       	call   7c6e <readseg>
    7d25:	81 3b 02 b0 ad 1b    	cmpl   $0x1badb002,(%ebx)
    7d2b:	8d 8b 00 00 ff ff    	lea    -0x10000(%ebx),%ecx
    7d31:	75 10                	jne    7d43 <bootmain+0x3d>
    7d33:	8b 43 04             	mov    0x4(%ebx),%eax
    7d36:	8b 53 08             	mov    0x8(%ebx),%edx
    7d39:	01 c2                	add    %eax,%edx
    7d3b:	81 fa fe 4f 52 e4    	cmp    $0xe4524ffe,%edx
    7d41:	74 0d                	je     7d50 <bootmain+0x4a>
    7d43:	83 c3 04             	add    $0x4,%ebx
    7d46:	81 fb 00 20 01 00    	cmp    $0x12000,%ebx
    7d4c:	75 d7                	jne    7d25 <bootmain+0x1f>
    7d4e:	eb 42                	jmp    7d92 <bootmain+0x8c>
    7d50:	a9 00 00 01 00       	test   $0x10000,%eax
    7d55:	74 3b                	je     7d92 <bootmain+0x8c>
    7d57:	8b 43 10             	mov    0x10(%ebx),%eax
    7d5a:	8b 7b 0c             	mov    0xc(%ebx),%edi
    7d5d:	39 f8                	cmp    %edi,%eax
    7d5f:	77 31                	ja     7d92 <bootmain+0x8c>
    7d61:	8b 53 14             	mov    0x14(%ebx),%edx
    7d64:	39 d0                	cmp    %edx,%eax
    7d66:	77 2a                	ja     7d92 <bootmain+0x8c>
    7d68:	89 c6                	mov    %eax,%esi
    7d6a:	29 c2                	sub    %eax,%edx
    7d6c:	29 fe                	sub    %edi,%esi
    7d6e:	01 f1                	add    %esi,%ecx
    7d70:	e8 f9 fe ff ff       	call   7c6e <readseg>
    7d75:	8b 4b 18             	mov    0x18(%ebx),%ecx
    7d78:	8b 7b 14             	mov    0x14(%ebx),%edi
    7d7b:	39 f9                	cmp    %edi,%ecx
    7d7d:	76 07                	jbe    7d86 <bootmain+0x80>
    7d7f:	29 f9                	sub    %edi,%ecx
    7d81:	31 c0                	xor    %eax,%eax
    7d83:	fc                   	cld    
    7d84:	f3 aa                	rep stos %al,%es:(%edi)
    7d86:	8b 43 1c             	mov    0x1c(%ebx),%eax
    7d89:	83 c4 0c             	add    $0xc,%esp
    7d8c:	5b                   	pop    %ebx
    7d8d:	5e                   	pop    %esi
    7d8e:	5f                   	pop    %edi
    7d8f:	5d                   	pop    %ebp
    7d90:	ff e0                	jmp    *%eax
    7d92:	83 c4 0c             	add    $0xc,%esp
    7d95:	5b                   	pop    %ebx
    7d96:	5e                   	pop    %esi
    7d97:	5f                   	pop    %edi
    7d98:	5d                   	pop    %ebp
    7d99:	c3                   	ret    
