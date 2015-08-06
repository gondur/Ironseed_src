p286
segment hotkey_text byte public 'code'
 assume cs:hotkey_text
 assume ds:hotkey_text
 org 100h
comstart:
 jmp start

done db 0
oldseg dw 0
oldofs dw 0
filename db 'e:\ironseed\data\test.vga',0
handle dw 0

proc dumpit
 push bx
 push cx
 push dx
 push ds
 mov dx, cs
 mov ds, dx
 mov dx, offset filename
 mov ax, 3D02h
  int 21h
 jc @@error
 mov [handle], ax
 mov bx, [handle]
 mov cx, 64000
 mov dx, 0A000h
 mov ds, dx
 mov dx, 0
 mov ah, 40h
  int 21h
@@error:
 pop ds
 pop dx
 pop cx
 pop bx
 ret
endp dumpit

proc newvec
 push dx
 push ds
 cmp ah, 4Fh
 jne @@odd
 cmp al, 16h
 jne @@done
; call dumpit
 mov dl, 'W'
 mov ah, 02h
  int 21h
 jmp @@done
@@odd:
 mov dl, 'X'
 mov ah, 02h
  int 21h
; push [oldseg]
; push [oldofs]
; retf
@@done:
 mov [done], 1
 mov dl, 'O'
 mov ah, 02h
  int 21h
 stc
 pop ds
 pop dx
 iret
endp newvec

start:
 mov [done], 0
 mov ax, 3515h
  int 21h
 mov [oldofs], bx
 mov [oldseg], es
 mov dx, cs
 mov ds, dx
 mov dx, offset newvec
 mov ax, 2515h
  int 21h
@@loopit:
 cmp [done], 0
 jne @@loopit
 mov dx, [oldseg]
 mov ds, dx
 mov dx, [oldofs]
 mov ax, 2515h
  int 21h
 mov ax, 4C00h
  int 21h

 mov dx, 32
 mov ax, 3100h
  int 21h

ends hotkey_text
end comstart
