p286
segment hotkey_text byte public 'code'
 assume cs:hotkey_text
 assume ds:hotkey_text
 org 100h
comstart:
 jmp start

oldseg   dw 0
oldofs   dw 0
filename db 'f:\ironseed\data\test.vga',0
palname  db 'f:\ironseed\data\test.pal',0
palnum   db 0
buffer   db 3 dup(0)
handle   dw 0

proc dumpit
 pushf
 push ax
 push bx
 push cx
 push dx
 push ds
 cli
 cld
 mov dx, cs
 mov ds, dx
 mov dx, offset filename
 mov ax, 3D02h
  int 21h           ; open file
 jc @@error
 mov bx, ax
 mov cx, 64000
 mov dx, 0A000h
 mov ds, dx
 mov dx, 0
 mov ah, 40h
  int 21h           ; save it
 jc @@error
 mov ah, 3Eh
  int 21h           ; close file
 jc @@error
 mov dx, cs
 mov ds, dx
 mov dx, offset palname
 mov ax, 3D02h
  int 21h           ; open file
 jc @@error
 mov [cs:handle], ax
 mov [cs:palnum], 0
@@outerloop:
 xor bh, bh
 mov bl, [cs:palnum]
 mov ax, 1015h
  int 10h
 mov [cs:buffer], dh
 mov [cs:buffer+1], ch
 mov [cs:buffer+2], cl
 mov cx, 3
 mov bx, [cs:handle]
 mov dx, cs
 mov ds, dx
 mov dx, offset buffer
 mov ah, 40h
  int 21h           ; saveit
 jc @@error
 inc [cs:palnum]
 cmp [cs:palnum], 0
 jne @@outerloop
 mov ah, 3Eh
  int 21h           ; close file
@@error:
 pop ds
 assume ds:nothing
 pop dx
 pop cx
 pop bx
 pop ax
 popf
 sti
 ret
endp dumpit

proc newvec far   ; new interrupt
 cmp ah, 4Fh
 jne @@done
 cmp al, 68
 jne @@done
 call dumpit
@@done:
 push [cs:oldseg]
 push [cs:oldofs]
 retf             ; go to old interrupt
endp newvec

start:
 mov ax, 3515h
  int 21h
 mov [cs:oldofs], bx
 mov [cs:oldseg], es
 mov dx, cs
 mov ds, dx
 mov dx, offset newvec
 mov ax, 2515h
  int 21h
 mov dx, 35
 mov ax, 3100h
  int 21h

ends hotkey_text
end comstart
