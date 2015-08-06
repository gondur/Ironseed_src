MACRO   saveIRQ
LOCAL   ll1,ll2
        in      al,21h
        mov     ah,al
        in      al,0A1h
        push    ax
        push    cx
        mov     cl,[gusIRQ]
        mov     ah,1
        test    cl,8
        jnz     ll1
        shl     ah,cl
        in      al,21h
        or      al,ah
        out     21h,al
        jmp     short ll2
ll1:
        and     cl,7
        shl     ah,cl
        in      al,0A1h
        or      al,ah
        out     0A1h,al
ll2:
        pop     cx
ENDM

MACRO   restoreIRQ
LOCAL   ll1,ll2
        pop     ax
        out     0A1h,al
        mov     al,ah
        out     21h,al
ENDM

MACRO   DELAY
        call    gusDelay
ENDM

