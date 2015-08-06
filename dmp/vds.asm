;/************************************************************************
; *
; *     File        : VDS.ASM
; *
; *     Description : Virtual DMA services
; *
; *     Copyright (C) 1993 Otto Chrons
; *
; ***********************************************************************/

        IDEAL
        JUMPS
        P386

;       L_PASCAL        = 1             ; Uncomment this for pascal-style

IFDEF   L_PASCAL
        LANG    EQU     PASCAL
        MODEL TPASCAL
ELSE
        LANG    EQU     C
        MODEL LARGE,C
ENDIF
        INCLUDE "MODEL.INC"

DATASEG

        vdsInited       DB ?

CODESEG

        PUBLIC  vdsInit
        PUBLIC  vdsEnableDMATranslation, vdsDisableDMATranslation
        PUBLIC  vdsLockDMA, vdsUnlockDMA


;/*************************************************************************
; *
; *     Function    :   int vdsInit(void);
; *
; *     Description :   Initializes VDS
; *
; *     Returns     :   0 = OK
; *                     -1 = error
; *
; ************************************************************************/

PROC    vdsInit

        mov     [vdsInited],0

        mov     ax,40h
        mov     es,ax
        mov     al,[es:7Bh]
        test    al,00100000b            ; Are services available?
        mov     ax,-1                   ; Set error code
        jz      @@exit
        mov     [vdsInited],1
        mov     ax,0
@@exit:
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   int vdsEnableDMATranslation(short DMAchannel);
; *
; *     Description :   Enables DMA buffer translation (default)
; *
; *     Input       :   DMA channel
; *
; *     Returns     :   0 = OK
; *                     -1 = error
; *
; ************************************************************************/

PROC    vdsEnableDMATranslation DMAchannel:WORD

        mov     ax,-1
        cmp     [vdsInited],1
        jne     @@exit
        mov     ax,810Ch
        mov     bx,[DMAchannel]         ; Enable DMA
        sub     dx,dx
        int     4Bh                     ; call VDS
        mov     ax,-1
        jc      @@exit                  ; Carry = error
        sub     ax,ax
@@exit:
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   int vdsDisableDMATranslation(short DMAchannel);
; *
; *     Description :   Disables DMA buffer translation
; *
; *     Input       :   DMA channel
; *
; *     Returns     :   0 = OK
; *                     -1 = error
; *
; ************************************************************************/

PROC    vdsDisableDMATranslation DMAchannel:WORD

        mov     ax,-1
        cmp     [vdsInited],1
        jne     @@exit
        mov     ax,810Bh
        mov     bx,[DMAchannel]         ; Disable DMA
        sub     dx,dx
        int     4Bh                     ; call VDS
        mov     ax,-1
        jc      @@exit                  ; Carry = error
        sub     ax,ax
@@exit:
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   int vdsLockDMA(DDS *dds);
; *
; *     Description :   Locks DMA region
; *
; *     Input       :   Pointer to DDS structure
; *
; *     Returns     :   0 = OK
; *                     -1 = error
; *
; ************************************************************************/

PROC    vdsLockDMA USES di,pdds:DWORD

        mov     ax,-1
        cmp     [vdsInited],1
        jne     @@exit

        LESDI   [pdds]
        mov     ax,8103h                ; Lock DMA region
        mov     dx,0
        int     4Bh
        mov     ax,-1
        jc      @@exit
        sub     ax,ax
@@exit:
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   int vdsUnlockDMA(DDS *dds);
; *
; *     Description :   Unlocks DMA region
; *
; *     Input       :   Pointer to DDS structure
; *
; *     Returns     :   0 = OK
; *                     -1 = error
; *
; ************************************************************************/

PROC    vdsUnlockDMA USES di,pdds:DWORD

        mov     ax,-1
        cmp     [vdsInited],1
        jne     @@exit

        LESDI   [pdds]
        mov     ax,8104h                ; Unlock DMA region
        mov     dx,0
        int     4Bh
        mov     ax,-1
        jc      @@exit
        sub     ax,ax
@@exit:
        ret
ENDP

END
