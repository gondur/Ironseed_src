
ideal
p486

global upscroll: far


segment scroller_text word 'code'
assume cs: scroller_text

proc upscroll far
 push bp
 mov bp, sp    ; bp+8=seg bp+6=ofs
 push ds       ; -2
 push es       ; -4
 sub sp, 2     ; -6=a
 mov ax, 0A000h
 mov es, ax
 mov [word ss:bp-6], 199
 mov bl, 160
@@loopa:
 mov ax, 0A000h
 mov ds, ax
 mov ax, [ss:bp-6]
 mov cl, 2
 div cl
 cmp ah, 0
  je @@continue
 xor di, di
 mov si, 320
 mov ax, [ss: bp-6]
 imul cx, ax, 80
  rep movsd
@@continue:
 mov ax, [ss:bp+8]
 mov ds, ax
 mov ax, [ss:bp-6]
 mul bl
 shl ax, 1
 xor di, di
 add di, ax
 mov si, [ss:bp+6]
 mov ax, 200
 sub ax, [ss: bp-6]
 imul cx, ax, 80
  rep movsd
 dec [word ss:bp-6]
 cmp [word ss:bp-6], 65
  jg  @@loopa
 add sp, 2
 pop es
 pop ds
 pop bp
 retf 4
endp upscroll

ends scroller_text
end
