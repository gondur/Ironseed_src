
ideal
p486

global mymove2: near


segment mover_text word 'code'
assume cs: mover_text

proc mymove2 near
 mov bx, sp
 push ds
 push es
 lds si, [ss: bx+8]
 les di, [ss: bx+4]
 mov cx, [ss: bx+2]
 cld
 rep movsd
 pop es
 pop ds
 ret 10   
endp mymove2

ends mover_text
end
