ideal
p486

global bignum2str: near


segment num2str_text word 'code'
assume cs: num2str_text

proc bignum2str near
 mov bx, sp
 push es
 push bp
 sub sp, 14
 mov bp, sp

 mov eax, [ss: bx+2]
 mov ecx, 10
 xor di, di
 mov si, 4

 @@loop:
  xor edx, edx
  div ecx
  dec si
  jz @@addcomma
 @@continue:
  add dl, 48
  mov [ss:bp+di], dl
  inc di
  cmp eax, 0
  jg @@loop

 mov cx, di
 mov ax, [ss:bx+8]
 mov es, ax
 mov di, [ss:bx+6]
 mov [es: di], cl
 inc di

 mov si, bp
 add si, cx
 dec si

 @@copyloop:
  mov al, [ss: si]
  mov [es: di], al
  dec si
  inc di
  dec cx
  jnz @@copyloop

 add sp, 14
 pop bp
 pop es
 ret
 @@addcomma:
  mov dh, ','
  mov [ss:bp+di], dh
  inc di
  mov si, 3
  jmp @@continue
endp bignum2str

ends num2str_text

end