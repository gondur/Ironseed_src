;/************************************************************************
; *
; *     File        :   SDI_SB.ASM
; *
; *     Description :   Sound Blaster (Pro) specific routines for MCP
; *
; *     Copyright (C) 1992 Otto Chrons
; *
; ************************************************************************
;
;       Revision history of SDI_SB.ASM
;
;       1.0     16.4.93
;               First version. SB and SB Pro routines.
;
; ***********************************************************************/

	IDEAL
	JUMPS
	P386N

       L_PASCAL        = 1             ; Uncomment this for pascal-style

IFDEF   L_PASCAL
	LANG    EQU     PASCAL
	MODEL TPASCAL
ELSE
	LANG    EQU     C
	MODEL LARGE,C
ENDIF

	INCLUDE "MODEL.INC"
	INCLUDE "MCP.INC"

MACRO   waitSB
	local   l1
l1:
	in      al,dx
	or      al,al
	js      l1
ENDM

MACRO   waitSBport
	local   l1

	mov     dx,[SoundBlaster.ioPort]
	add     dx,0Ch
l1:
	in      al,dx
	or      al,al
	js      l1
ENDM

MACRO   waitSBPROport
	local   l1

	mov     dx,[SoundBlasterPro.ioPort]
	add     dx,0Ch
l1:
	in      al,dx
	or      al,al
	js      l1
ENDM

DATASEG

	EXTRN   mcpStatus:BYTE
	EXTRN   bufferSize:WORD
	EXTRN   dataBuf:WORD
	EXTRN   SoundCard:CARDINFO

	DMApage         DB ?
	DMAoffset       DW ?
	saveDMAvector   DD ?
	samplingRate    DW ?
	SBrate          DB ?

CODESEG

	PUBLIC  SDI_SB
	PUBLIC  SDI_SBPro

	copyrightText   DB "SDI for SB & SB Pro v1.0 - (C) 1992 Otto Chrons",0,1Ah
	SoundBlaster    CARDINFO <1,0,"Sound Blaster",220h,7,1,4000,22050,0,0,1>
	SoundBlasterPro CARDINFO <2,0,"Sound Blaster Pro",220h,7,1,4000,22050,1,1,1>
	SoundDeviceSB   SOUNDDEVICE < \
		far ptr initSB,\
		far ptr initDMA,\
		far ptr initRate,\
		far ptr closeSB,\
		far ptr closeDMA,\
		far ptr startVoice,\
		far ptr stopVoice,\
		far ptr pauseVoice,\
		far ptr resumeVoice\
		far ptr getDMApos,\
		far ptr speakerOn,\
		far ptr speakerOff\
		>

	SoundDeviceSBPro        SOUNDDEVICE < \
		far ptr initSBPro,\
		far ptr initDMA,\
		far ptr initRate,\
		far ptr closeSB,\
		far ptr closeDMA,\
		far ptr startVoice,\
		far ptr stopVoice,\
		far ptr nullFunc,\
		far ptr nullFunc\
		far ptr getDMApos,\
		far ptr speakerOn,\
		far ptr speakerOff\
		>


;/*************************************************************************
; *
; *     Function    :   void SDI_SB(SOUNDDEVICE far *sdi);
; *
; *     Description :   Registers SB as a sound device
; *
; *     Input       :   Pointer to SD structure
; *
; *     Returns     :   Fills SD structure accordingly
; *
; ************************************************************************/

PROC    SDI_SB FAR USES di si,sdi:DWORD

	cld
	LESDI   [sdi]
	mov     si,offset SoundDeviceSB
	mov     cx,SIZE SOUNDDEVICE
	cli
	segcs
	rep movsb                       ; Copy structure
	sti
	sub     ax,ax                   ; indicate successful init
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   void SDI_SBPro(SOUNDDEVICE far *sdi);
; *
; *     Description :   Registers SBPro as a sound device
; *
; *     Input       :   Pointer to SD structure
; *
; *     Returns     :   Fills SD structure accordingly
; *
; ************************************************************************/

PROC    SDI_SBPro FAR USES di si, sdi:DWORD

	cld
	LESDI   [sdi]
	mov     si,offset SoundDeviceSBPro
	mov     cx,SIZE SOUNDDEVICE
	cli
	segcs
	rep movsb                       ; Copy structure
	sti
	sub     ax,ax                   ; indicate successful init
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   checkPort_SB
; *
; *     Description :   Checks if given address is SB's I/O address
; *
; *     Input       :   DX = port to check
; *
; *     Returns     :   AX = 0  succesful
; *                     AX = 1  unsuccesful
; *
; ************************************************************************/

PROC    NOLANGUAGE checkPort_SB NEAR

	push    dx
	add     dl,6                    ; Init Sound Blaster
	mov     al,1
	out     dx,al
	in      al,dx                   ; Wait for awhile
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	mov     al,0
	out     dx,al
	sub     dl,6

	add     dl,0Eh                  ; DSP data available status
	mov     cx,1000
@@loop:
	in      al,dx                   ; port 22Eh
	or      al,al
	js      @@10
	loop    @@loop

	mov     ax,1
	jmp     @@exit
@@10:
	sub     dl,4
	in      al,dx                   ; port 22Ah
	cmp     al,0AAh                 ; Is ID 0AAh?
	mov     ax,0
	je      @@exit
	mov     ax,1
@@exit:
	pop     dx
	or      ax,ax                   ; Set zero-flag accordingly
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   cmdSB
; *
; *     Description :   Sends a command to Sound Blaster
; *
; *     Input       :   AL = Command to send
; *
; ************************************************************************/

PROC    cmdSB NEAR

	push    ecx
	mov     ecx,500000
	push    ax
	mov     dx,[SoundCard.ioPort]
	add     dl,0Ch
@@1:
	in      al,dx
	or      al,al
	jns     @@2
	loopd   @@1
@@2:
	pop     ax
	out     dx,al
	pop     ecx

	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   playDMA
; *
; *     Description :   Plays current buffer through DMA
; *
; ************************************************************************/

PROC    playDMA NEAR USES cx

	mov     cx,65500
	cmp     [SoundCard.ID],ID_SOUNDBLASTER
	jne     @@10
	mov     al,14h                  ; SB's command for output
	call    cmdSB
	mov     al,cl                   ; Count
	call    cmdSB
	mov     al,ch
	call    cmdSB
	jmp     @@exit
@@10:
	cmp     [SoundCard.ID],ID_SOUNDBLASTERPRO
	jne     @@exit
	mov     al,91h                  ; Start transfer
	call    cmdSB
@@exit:
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   interruptDMA
; *
; *     Description :   DMA interrupt routine for continous playing.
; *
; ************************************************************************/

PROC    NOLANGUAGE interruptDMA NEAR

	push    ax
	push    dx
	push    ds
	mov     ax,@data
	mov     ds,ax                   ; DS = data segment

	mov     dx,[SoundCard.ioPort]   ; Reset SB for next DMA
	add     dl,0Eh
	in      al,dx
	call    playDMA                 ; Output current buffer
	mov     al,20h                  ; End Of Interrupt (EOI)
	out     20h,al
	cmp     [SoundCard.dmaIRQ],7
	jle     @@10
	out     0A0h,al
@@10:
	pop     ds
	pop     dx
	pop     ax
	iret                            ; Interrupt return
ENDP

;/*************************************************************************
; *
; *     Function    :   int getDMApos():
; *
; *     Description :   Returns the position of DMA transfer
; *
; ************************************************************************/

PROC    getDMApos FAR

	cli
	sub     dh,dh
	mov     dl,[SoundCard.dmaChannel]
	shl     dx,1
	inc     dx
@@05:
	mov     al,0FFh
	out     0Ch,al
	in      al,dx
	mov     ah,al
	in      al,dx
	xchg    ah,al
	mov     bx,ax
	in      al,dx
	mov     ah,al
	in      al,dx
	xchg    ah,al
	sub     bx,ax
	cmp     bx,64
	jg      @@05
	cmp     bx,-64
	jl      @@05
	neg     ax
	add     ax,[bufferSize]         ; AX = DMA position
	sti

	ret
ENDP


;/*************************************************************************
; *
; *     Function    :   int initSB(CARDINFO *sCard);
; *
; *     Description :   Initializes Sound Blaster using given 'port' and
; *                     'DMA_int' values
; *
; *     Input       :   port    = Sound Blaster's I/O address (210h-260h)
; *                     DMA_int = DMA interrupt value (2,3,5 or 7)
; *
; *     Returns     :    0      = success
; *                     -1      = error
; *
; ************************************************************************/

PROC    initSB FAR USES di si,sCard:DWORD
	local   retvalue:WORD

	LESSI   [sCard]
	mov     [retvalue],-1           ; assume error
	mov     dx,[ESSI+CARDINFO.ioPort]
	ror     dx,4
	cmp     dx,21h                  ; check for valid addresses
	jb      @@exit
	cmp     dx,26h
	ja      @@exit

	cmp     [ESSI+CARDINFO.DMAIRQ],2        ; check for legal inteerupt values
	jz      @@DMA_OK
	cmp     [ESSI+CARDINFO.DMAIRQ],3
	jz      @@DMA_OK
	cmp     [ESSI+CARDINFO.DMAIRQ],5
	jz      @@DMA_OK
	cmp     [ESSI+CARDINFO.DMAIRQ],7
	jnz     @@exit
@@DMA_OK:
	mov     si,offset SoundBlaster          ; DS:SI = source
	mov     ax,ds
	mov     es,ax
	mov     di,offset SoundCard     ; ESDI = destination
	mov     cx,SIZE CARDINFO
	cld
	cli
	segcs
	rep     movsb                   ; Copy information
	sti

	LESSI   [sCard]
	mov     bx,[ESSI+CARDINFO.ioPort]
	mov     [SoundCard.ioPort],bx
	mov     bl,[ESSI+CARDINFO.DMAIRQ]
	mov     [SoundCard.DMAIRQ],bl
	mov     [SoundCard.DMAchannel],1        ; Channel is always 1

	mov     dx,[SoundCard.ioPort]   ; initialize Sound Blaster
	add     dx,6
	mov     al,1
	out     dx,al
	in      al,dx                   ; Wait for awhile
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	mov     al,0
	out     dx,al

	or      [mcpStatus],S_INIT      ; indicate successful initialization
	mov     [retvalue],0            ; return 0 = OK
@@exit:
	mov     ax,[retvalue]
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   int initSBpro(CARDINFO *sCard);
; *
; *     Description :   Initializes Sound Blaster Pro using values for
; *                     ioPort,dmaIRQ & dmaChannel in sCard
; *
; *     Input       :   sCard   = pointer to CARDINFO-structure
; *
; *     Returns     :    0      = success
; *                     -1      = error
; *
; ************************************************************************/

PROC    initSBpro FAR USES di si,sCard:DWORD
	local   retryCount:WORD,retvalue:WORD

	LESSI   [sCard]
	mov     [retvalue],-1           ; assume error
	mov     dx,[ESSI+CARDINFO.ioPort]
	cmp     dx,220h                 ; check for valid addresses
	je      @@OK
	cmp     dx,240h
	jne     @@exit
@@OK:
	cmp     [ESSI+CARDINFO.DMAIRQ],2        ; check for legal interrupt values
	je      @@DMA_OK
	cmp     [ESSI+CARDINFO.DMAIRQ],5
	je      @@DMA_OK
	cmp     [ESSI+CARDINFO.DMAIRQ],7
	je      @@DMA_OK
	cmp     [ESSI+CARDINFO.DMAIRQ],10
	jne     @@exit
@@DMA_OK:
	cmp     [ESSI+CARDINFO.DMAChannel],0    ; check for legal channel values
	je      @@channelOK
	cmp     [ESSI+CARDINFO.DMAChannel],1
	je      @@channelOK
	cmp     [ESSI+CARDINFO.DMAChannel],3
	jne     @@exit
@@channelOK:
	mov     si,offset SoundBlasterPro       ; DS:SI = source
	mov     ax,ds
	mov     es,ax
	mov     di,offset SoundCard     ; ESDI = destination
	mov     cx,SIZE CARDINFO
	cld
	cli
	segcs
	rep     movsb                   ; Copy information
	sti

	LESSI   [sCard]
	mov     bx,[ESSI+CARDINFO.ioPort]
	mov     [SoundCard.ioPort],bx
	mov     bl,[ESSI+CARDINFO.DMAIRQ]
	mov     [SoundCard.DMAIRQ],bl
	mov     bl,[ESSI+CARDINFO.DMAChannel]
	mov     [SoundCard.DMAchannel],bl

MASM
COMMENT #
/*
	mov     dx,[SoundCard.ioPort]   ; initialize Sound Blaster
	call    checkPort_SB

	mov     [retrycount],10
@@retry:
	dec     [retrycount]
	jnz     @@continue
	mov     ax,0                    ; not found
	jmp     @@done
@@continue:
	mov     al,0E1h                 ; Read version number
	call    cmdSB

	add     dl,2                    ; DX = 22Eh
	sub     al,al
	mov     cx,1000
@@10:
	in      al,dx                   ; Read version high
	or      al,al
	js      @@10ok
	loop    @@10
	jmp     @@retry
@@10ok:
	mov     cx,1000
	sub     dl,4
	in      al,dx
	mov     ah,al

	add     dl,4
	sub     al,al
@@20:
	in      al,dx                   ; Read version low
	or      al,al
	js      @@20ok
	loop    @@20
	jmp     @@retry
@@20ok:
	sub     dl,4
	in      al,dx
@@done:
	cmp     ax,0300h                ; Is version 3.00 or higher?
	jl      @@exit                  ; No --> exit
*/
#
IDEAL

	mov     dx,[SoundCard.ioPort]   ; initialize Sound Blaster
	add     dx,6
	mov     al,1
	out     dx,al
	in      al,dx                   ; Wait for awhile
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	mov     al,0
	out     dx,al
	or      [mcpStatus],S_INIT      ; indicate successful initialization
	mov     [retvalue],0            ; return 0 = OK
@@exit:
	mov     ax,[retvalue]
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   initDMA(void far *buffer,int maxsize, int required);
; *
; *     Description :   Init DMA for output
; *
; ************************************************************************/

PROC    initDMA FAR buffer:DWORD,linear:DWORD,maxSize:DWORD,required:DWORD

	mov     ecx,[maxSize]
	mov     [bufferSize],cx
	mov     ax,[WORD HIGH buffer]
	mov     bx,[WORD LOW buffer]
	mov     [dataBuf],bx            ; Check if DMA buffers are on
	mov     eax,[linear]            ; a segment boundary
	neg     ax
	cmp     ax,cx                   ; Is buffer size >= data size
	ja      @@bufOK
	dec     ax
	and     ax,NOT 3
	mov     [bufferSize],ax
	shr     cx,1
	cmp     ax,cx                   ; Is it even half of it?
	ja      @@bufOK
	shl     cx,1
	add     [dataBuf],ax
	add     [dataBuf],7
	and     [dataBuf],NOT 3
	neg     ax
	add     ax,cx                   ; AX = dataSize - AX
	sub     ax,32
	and     ax,NOT 3
	mov     [bufferSize],ax
@@bufOK:
	cmp     [required],0
	je      @@sizeok
	cmp     ax,[word required]
	jbe     @@sizeok
	mov     ax,[word required]
	mov     [bufferSize],ax
@@sizeok:
	and     [bufferSize],NOT 3
	sub     ebx,ebx
	mov     eax,[linear]            ; Calculate DMA page and offset values
	mov     bx,[dataBuf]
	sub     bx,[WORD LOW buffer]    ; Relative offset
	add     eax,ebx
	mov     ebx,eax
	shr     ebx,16
	cmp     [SoundCard.DMAChannel],4
	jb      @@8bitDMA
	push    bx
	shr     bl,1
	rcr     ax,1                    ; For word addressing
	pop     bx
@@8bitDMA:
	mov     [DMApage],bl
	mov     [DMAoffset],ax

	mov     al,[SoundCard.DMAIRQ]
	test    al,8                    ; Is IRQ > 7
	jz      @@01
	add     al,60h                  ; Yes, base is 70h
@@01:
	add     al,8                    ; AL = DMA interrupt number
	push    ax
	mov     ah,35h                  ; Get interrupt vector
	int     21h
	mov     [WORD LOW saveDMAvector],bx     ; Save it
	mov     [WORD HIGH saveDMAvector],es
	pop     ax                      ; Replace vector with the address
	mov     ah,25h                  ; of own interrupt routine
	PUSHDS
	push    cs
	POPDS
	mov     dx,offset interruptDMA  ; Set interrupt vector
	int     21h
	POPDS

	mov     cl,[SoundCard.DMAIRQ]
	mov     ah,1
	test    cl,8                    ; Is IRQ > 7
	jnz     @@15
	shl     ah,cl
	not     ah
	in      al,21h
	and     al,ah
	out     21h,al                  ; Allow DMA interrupt
	jmp     @@20
@@15:
	and     cl,7
	shl     ah,cl
	not     ah
	in      al,0A1h
	and     al,ah
	out     0A1h,al                 ; Allow DMA interrupt
@@20:
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   initRate
; *
; *     Description :   Inits sound card's sampling rate
; *
; ************************************************************************/

PROC    initRate FAR sample_rate:DWORD

	mov     ax,[SoundCard.minRate]
	cmp     [word sample_rate],ax
	jae     @@rateok
	mov     [word sample_rate],ax
	jmp     @@rateok
	mov     ax,[SoundCard.maxRate]
	cmp     [word sample_rate],ax
	jbe     @@rateok
	mov     [word sample_rate],ax
@@rateok:
	cmp     [SoundCard.ID],ID_SOUNDBLASTER
	je      @@10
	cmp     [SoundCard.ID],ID_SOUNDBLASTERPRO
	jne     @@exit
@@10:
	mov     eax,0F4240h             ; Calculate sampling rate for SB
	sub     edx,edx                 ; EDX:EAX = 1000000
	mov     ecx,[sample_rate]
	cmp     [SoundCard.ID],ID_SOUNDBLASTERPRO
	jne     @@20
	shl     ecx,1
@@20:
	div     ecx
	push    ax
	neg     al                      ; AL = 256 - 1000000/rate
	mov     [SBrate],al
	mov     ah,al
	mov     al,40h                  ; Set SB's sampling rate
	call    cmdSB
	mov     al,ah
	call    cmdSB
	pop     ax

	cmp     [SoundCard.ID],ID_SOUNDBLASTERPRO
	jne     @@30
	shl     ax,1
@@30:

	mov     bx,ax                   ; Calculate real sampling rate
	sub     bh,bh
	mov     ax,4240h
	mov     dx,0Fh
	div     bx                      ; Save sampling rate into AX
@@exit:
	mov     [samplingRate],ax       ; and save it for future use
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   speakerOn
; *
; *     Description :   Connects SB's Digital Signal Processor to speaker
; *
; ************************************************************************/

PROC    speakerOn FAR

	mov     al,0D1h
	call    cmdSB
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   speakerOff
; *
; *     Description :   Disconnects speaker from DSP
; *
; ************************************************************************/

PROC    speakerOff FAR

	mov     al,0D3h
	call    cmdSB
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   setStereo
; *
; *     Description :   Sets SB Pro into stereo mode
; *
; ************************************************************************/

PROC    setStereo NEAR

	mov     al,0Eh
	mov     dx,[SoundCard.ioPort]
	add     dx,4
	out     dx,al
	inc     dx
	in      al,dx
	or      al,00000010b            ; Set stereo

	mov     ah,al
	mov     al,0Eh
	mov     dx,[SoundCard.ioPort]
	add     dx,4
	out     dx,al
	inc     dx
	mov     al,ah
	out     dx,al

	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   startVoice
; *
; *     Description :   Starts to output voice.
; *
; ************************************************************************/

PROC    startVoice FAR USES di

	mov     cl,[SoundCard.DMAIRQ]           ; Enable DMA interrupt
	mov     ah,1
	test    cl,8
	jnz     @@10
	shl     ah,cl
	not     ah
	in      al,21h
	and     al,ah
	out     21h,al
	jmp     @@20
@@10:
	and     cl,7
	shl     ah,cl
	not     ah
	in      al,0A1h
	and     al,ah
	out     0A1h,al
@@20:
	mov     ah,[DMApage]            ; Load correct DMA page and offset
	mov     bx,[DMAoffset]          ; values
	mov     cx,[bufferSize]
	dec     cx

	cli                             ; Set the DMA up and running
	mov     al,[SoundCard.DMAChannel]
	add     al,4
	out     0Ah,al                  ; Break On
	mov     al,[SoundCard.DMAChannel]
	or      al,58h
	out     0Bh,al
	mov     dx,83h
	cmp     [SoundCard.DMAChannel],1 ; Is DMA channel 1?
	je      @@30
	mov     dx,87h
	cmp     [SoundCard.DMAChannel],0 ; Is DMA channel 0?
	je      @@30
	mov     dx,82h                  ; DMA channel is 3
@@30:
	mov     al,ah
	out     dx,al                   ; Page

	mov     al,0FFh
	out     0Ch,al

	sub     dx,dx
	mov     dl,[SoundCard.DMAChannel]
	shl     dx,1
	mov     al,bl
	out     dx,al                   ; Offset
	mov     al,bh
	out     dx,al
	inc     dx
	mov     al,cl
	out     dx,al                   ; Count
	mov     al,ch
	out     dx,al
	mov     al,[SoundCard.DMAChannel]
	out     0Ah,al                  ; Break Off

	mov     dx,[SoundCard.ioPort]
	add     dl,6                    ; Init Sound Blaster
	mov     al,1
	out     dx,al
	in      al,dx                   ; Wait for awhile
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	mov     al,0
	out     dx,al

	mov     al,40h                  ; Set SB's sampling rate
	call    cmdSB
	mov     al,[SBrate]
	call    cmdSB

        mov     al,0D1h
	call    cmdSB

	mov     cx,65500
	cmp     [SoundCard.ID],ID_SOUNDBLASTERPRO
	jne     @@normSB
	mov     al,48h                  ; SB's command for stereo output
	call    cmdSB
	mov     al,cl                   ; Count
	call    cmdSB
	mov     al,ch
	call    cmdSB
@@normSB:
	call    playDMA

	call    setStereo

	sti
@@exit:
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   stopVoice
; *
; *     Description :   Stops voice output.
; *
; ************************************************************************/

PROC    stopVoice FAR

	cli
	mov     dx,[SoundCard.ioPort]
	add     dl,6                    ; Init Sound Blaster
	mov     al,1
	out     dx,al
	in      al,dx                   ; Wait for awhile
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	mov     al,0
	out     dx,al

	mov     dx,[SoundCard.ioPort]
	add     dx,0Eh
	in      al,dx


	mov     cl,[SoundCard.DMAIRQ]           ; Disable DMA interrupt
	mov     ah,1
	test    cl,8
	jnz     @@10
	shl     ah,cl
	in      al,21h
	or      al,ah
	out     21h,al
	jmp     @@20
@@10:
	and     cl,7
	shl     ah,cl
	in      al,0A1h
	or      al,ah
	out     0A1h,al
@@20:
	mov     al,0
	out     0Ch,al
	mov     al,[SoundCard.DMAChannel] ; Reset DMA
	or      al,4
	out     0Ah,al
	sti

@@exit:
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   closeDMA
; *
; *     Description :   Returns DMA's IRQ vector
; *
; ************************************************************************/

PROC closeDMA FAR
	PUSHDS
	mov     al,[SoundCard.DMAIRQ]
	test    al,8                    ; Is IRQ > 7
	jz      @@01
	add     al,60h                  ; Yes, base is 70h
@@01:
	add     al,8
	mov     dx,[WORD LOW saveDMAvector]
	mov     ds,[WORD HIGH saveDMAvector]
	mov     ah,25h
	int     21h                     ; Restore DMA vector
	POPDS
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   closeSB
; *
; *     Description :   Does nothing currently :)
; *
; ************************************************************************/

PROC    closeSB FAR
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   pauseVoice
; *
; *     Description :   Pauses voice output
; *
; ************************************************************************/

PROC    pauseVoice FAR
       mov     al,0D0h
       call    cmdSB
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   resumeVoice
; *
; *     Description :   Resumes voice output
; *
; ************************************************************************/

PROC    resumeVoice FAR
       mov     al,0D4h
       call    cmdSB
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   nullFunc
; *
; *     Description :   Does nothing...
; *
; ************************************************************************/

PROC    nullFunc FAR

	ret
ENDP


END
