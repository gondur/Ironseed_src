;/************************************************************************
; *
; *     File        :   GUS.ASM
; *
; *     Description :   Interface for Gravis Ultrasound
; *
; *     Copyright (C) 1993 Otto Chrons
; *
; ***********************************************************************
;
;       Revision history of GUS.ASM
;
;       1.0     31.7.93
;               Well, maybe it works
;       2.0     11.11.93
;               Now it seems to be working pretty well... Some probs with
;               IRQs from wavetable and volume ramps.. odd..
;
; ***********************************************************************/

        IDEAL
        JUMPS
        P386

        INCLUDE "MODEL.INC"
        INCLUDE "MCP.INC"
        INCLUDE "GUS.INC"
        INCLUDE "CDI.INC"

STRUC   GUSEVENT
    time        DD ?
IFDEF __32__
    func        DD ?
ELSE
    func        DW ?                    ; Pointer to function
ENDIF
    p1          DD ?                    ; Parameters
    p2          DD ?
    p3          DD ?
ENDS

STRUC   SAMPLELINK
    origSample  DD ?
    gusSample   DD ?
ENDS

	TIMER2  = 12

IFDEF __PASCAL__
	EXTRN   gushmAlloc:_FAR, gushmFreeAll:_FAR, gushmFree:_FAR
ELSE
	EXTRN   _gushmAlloc:_FAR, _gushmFreeAll:_FAR, _gushmFree:_FAR
ENDIF

STRUC   DMAPORT

	addr    DW ?
	count   DW ?
	page    DW ?
	wcntrl  DW ?
	wreq    DW ?
	wrsmr   DW ?
	wrmode  DW ?
	clear   DW ?
	wrclr   DW ?
	clrmask DW ?
	wrall   DW ?
ENDS

MACRO   checkPause

	movzx   ebx,[WORD @@channel]
	cmp     [_bx+chPaused],1
	je      @@exit
ENDM

MACRO   selectChannel x

        mov     al,x
        mov     dx,[gusChannelAddr]
        out     dx,al
ENDM

MACRO	memSet 	memOfs,memSize
	mov	_di,offset memOfs
IF (memSize AND 3) EQ 0
	mov	_cx,memSize/4
	rep	stosd
ELSEIF (memSize AND 1) EQ 0
	mov	_cx,memSize/2
	rep	stosw
ELSE
	mov	_cx,memSize
	rep	stosb
ENDIF

ENDM

CSEGMENTS GUS

CDATASEG

	MAXEVENT        = 200
	MAXSAMPLE       = 128
	TIME_DELTA      = 30000                 ; 30msec

	eventQueue              GUSEVENT MAXEVENT+8 dup(<>)
	sampleList              SAMPLELINK MAXSAMPLE dup(<>)
	sampleListLength        DW ?
	firstEvent              DW ?
	lastEvent               DW ?
	staticEvent             GUSEVENT <>
	curTime                 DD ?
	pseudoTime              DD ?
	deltaTime               DD ?
	gusVoices               DB ?
	gusBaseAddr             DW ?
	gusCmdAddr              DW ?
	gusChannelAddr          DW ?
	gusIRQ                  DB ?
	gusDMA                  DB ?
	oldIRQ                  DD ?
	chBase                  DD 32 dup(?)
	chFreq                  DD 32 dup(?)
	chVolume                DW 32 dup(?)
	chPaused                DB 32 dup(?)
	oldSS                   DW ?
	oldSP                   DW ?
	gusBUSY                 DW ?
	masterVol               DW ?
	curDMA                  DMAPORT <>
	dmaActive               DB ?
	irqStatus               DB ?
	testIRQ                 DB ?

IFDEF __PASCAL__
	extrn                   gusDeltaTime:DWORD
ELSE
	CPUBLIC		gusDeltaTime

	_gusDeltaTime		DD ?
	gusDeltaTime EQU _gusDeltaTime
ENDIF

IFDEF __PASCAL__

	EXTRN CDI_GUS:CDIDEVICE

ELSE
	CPUBLIC CDI_GUS

	_CDI_GUS        CDIDEVICE <\
	_far ptr _gusSetSample,\
	_far ptr _gusPlaySample,\
	_far ptr _gusSetVolume,\
	_far ptr _gusSetRate,\
	0,\
        _far ptr _gusSetPosition,\
	_far ptr _gusSetPanning,\
	_far ptr _gusSetMasterVolume,\
        _far ptr _gusPauseChannel,\
        _far ptr _gusResumeChannel,\
        _far ptr _gusStopChannel,\
        _far ptr _gusPauseAll,\
        _far ptr _gusResumeAll,\
        _far ptr _gusPoll,\
        _far ptr _gusGetDelta,\
        _far ptr _gusDownload,\
        _far ptr _gusUnloadAll,\
        _far ptr _gusGetVolume,\
        _far ptr _gusGetRate,\
        _far ptr _gusGetPosition,\
        _far ptr _gusGetPanning,\
        _far ptr _gusGetSample,\
        _far ptr _gusSetupChannels,\
        _far ptr _gusGetChannelStatus>
ENDIF

ENDS

CCODESEG GUS

	CPUBLIC gusInit, gusClose, gusStartVoice, gusStopVoice
        CPUBLIC gusSetSample, gusPlaySample, gusStopChannel, gusSetVolume, gusSetRate
        CPUBLIC gusSetPosition, gusSetPanning, gusSetMasterVolume, gusGetSamplingRate
        CPUBLIC gusPauseChannel, gusResumeChannel, gusPauseAll, gusResumeAll
        CPUBLIC gusPoll, gusGetDelta, gusDownload, gusUnload, gusUnloadAll
	CPUBLIC gusGetVolume, gusGetRate, gusGetPosition, gusGetPanning
        CPUBLIC gusGetSample, gusSetupChannels

        CPUBLIC gusPoke, gusPeek

        LABEL DMAports  DMAPORT

            DMAPORT <0,1,87h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
            DMAPORT <2,3,83h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
            DMAPORT <4,5,81h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
            DMAPORT <6,7,82h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
            DMAPORT <0,0,0,0,0,0,0,0,0,0,0>
            DMAPORT <0C4h,0C6h,8Bh,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>
            DMAPORT <0C8h,0CAh,89h,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>
            DMAPORT <0CCh,0CEh,8Ah,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>

IFDEF __C32__
	cpublic  debugit

CPROC   debugit

        mov     ebx,0B8000h
        mov     ah,07
        mov     [ebx],ax
        ret
ENDP

ENDIF

PROC    nullFunc NEAR
        ret
ENDP

PROC    gusDelay NEAR
        push    ax dx
	mov     dx,300h
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
	in      al,dx
        pop     dx ax
        ret
ENDP

;/*************************************************************************
; *
; *     Function    : initEventQueue();
; *
; *     Description : Initializes event queue
; *
; ************************************************************************/

PROC    initEventQueue NEAR

	push    _di
	PUSHDS
	POPES
	mov     _di,offset eventQueue
	cld
	mov     _cx,(SIZE GUSEVENT)*(MAXEVENT+8)
	mov     al,0FFh
	rep     stosb                   ; Clear events
	mov     [firstEvent],0
	mov     [lastEvent],0
	mov     [curTime],0
	mov     [pseudoTime],0
	mov     [deltaTime],320*TIMER2  ; 2560usec
	pop     _di
	ret
ENDP

;/*************************************************************************
; *
; *     Function    : insertEvent();
; *
; *     Description : Inserts an event to GUS' event queue (static structure)
; *
; ************************************************************************/

PROC    insertEvent NEAR

	push    _di _si

        saveIRQ

        movzx   edi,[lastEvent]
        inc     [lastEvent]
        cmp     [lastEvent],MAXEVENT
	jb      @@ok
        mov     [lastEvent],0
@@ok:
	mov	eax,[gusDeltaTime]
	add     [staticEvent.time],eax
        imul    _di,SIZE GUSEVENT
	add     _di,offset eventQueue
        mov     _si,offset staticEvent  ; DS:SI points to the event to be inserted
        PUSHDS
        POPES                           ; ES:DI points to event queue
        mov     _cx,SIZE GUSEVENT
        cld
        rep     movsb

        restoreIRQ

        pop     _si _di

        ret
ENDP

;/*************************************************************************
; *
; *     Function    : getEvent();
; *
; *     Description : Gets an event from GUS' event queue
; *
; ************************************************************************/

PROC    getEvent NEAR

        push    _di _si
	mov     _ax,-1                  ; -1 = no event
	movzx   esi,[firstEvent]
	cmp     si,[lastEvent]
	je      @@exit
@@ok:
	imul    _si,SIZE GUSEVENT
	add     _si,offset eventQueue
	mov     _di,offset staticEvent  ; ES:(E)DI points to the event to be fetched
	PUSHDS
	POPES                           ; DS:(E)SI points to event queue
	mov     _cx,SIZE GUSEVENT
	cld
	rep     movsb
	sub     _ax,_ax                 ; Event is loaded into the static buffer
@@exit:
	pop     _si _di
	ret
ENDP

;/*************************************************************************
; *
; *     Function    : processEvent();
; *
; *     Description : Processes current event in queue
; *
; ************************************************************************/

PROC    processEvent NEAR

	mov     _ax,-1                  ; -1 = not processed
	mov     edx,[curTime]
	cmp     [staticEvent.time],edx  ; Is it time?
	ja      @@exit
	mov     eax,[staticEvent.p1]    ; Pass parametres
	mov     ebx,[staticEvent.p2]
	mov     ecx,[staticEvent.p3]
	cmp	[staticEvent.func],0	; Is pointer NULL?
	je	@@nocall
	call    [staticEvent.func]      ; Call function
@@nocall:
        inc     [firstEvent]            ; Purge event
        cmp     [firstEvent],MAXEVENT
        jl      @@ok
        mov     [firstEvent],0
@@ok:
        sub     _ax,_ax                 ; 0 = processed
@@exit:
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   interruptHandler
; *
; *     Description :   Handles GUS' interrupts
; *
; ************************************************************************/

PROC    interruptHandler NEAR

        mov     eax,[deltaTime]
        add     [curTime],eax

@@again:
        mov     dx,[gusBaseAddr]
        add     dx,6
        in      al,dx                   ; IRQ status
        mov     [irqStatus],al
        sti

        cmp     al,0
        je      @@busy

        test    [irqStatus],10000000b   ; DMA IRQ?
        jz      @@notDMAIRQ

	mov     dx,[gusCmdAddr]
        mov     al,41h
        out     dx,al
        add     dx,2
        in      al,dx
;       test    al,01000000b
;       jz      @@notDMAIRQ
        mov     [dmaActive],0

@@notDMAIRQ:
        test    [irqStatus],00001000b   ; Timer 2
        jz      @@busy

        mov     dx,[gusCmdAddr]
        mov     al,45h
        out     dx,al
        add     dx,2
        sub     al,al
        out     dx,al
	sub     dx,2
        DELAY
        mov     al,45h
        out     dx,al
        add     dx,2
        mov     al,8
        out     dx,al

        cmp     [gusBUSY],0
        jne     @@busy

        mov     [gusBUSY],1
        PUSHDS
        POPES
@@loop:
        call    getEvent
        or      ax,ax
        jnz     @@exit
        call    processEvent
        or      ax,ax
        jz      @@loop
@@exit:
	mov     [gusBUSY],0
@@busy:
        ret
ENDP

;/*************************************************************************
; *
; *     Function    : interruptGUS();
; *
; *     Description : Interrupt service routine for handling events
; *
; ************************************************************************/

PROC    interruptGUS

        pushad
        push    es ds

        mov     ax,DGROUP
        mov     ds,ax
        mov     es,ax

        mov     al,20h
        out     20h,al
        out     0A0h,al

IFDEF __C32__
	mov     al,[testIRQ]
        inc     [testIRQ]
        ecall   debugit
ENDIF
        call    near interruptHandler

        pop     ds es
        popad
        nop
IFDEF __C32__
        iretd
ELSE
        iret
ENDIF
ENDP

;/*************************************************************************
; *
; *     Function    :   long(eax) findSample(void *ptr);
; *
; *     Description :   Returns the offset of the sample in GUS' memory
; *
; *     Returns     :   EAX = offset
; *                     BX = offset to sample list
; *
; ************************************************************************/

CPROC   findSample @@pptr

        ENTERPROC

        sub     eax,eax
        movzx   ecx,[sampleListLength]
        jcxz    @@exit
        sub     _bx,_bx
@@loop:
        mov     edx,[_bx+sampleList.origSample]
        cmp     edx,[@@pptr]
        je      @@found
        add     _bx,SIZE SAMPLELINK
	loop    @@loop
	sub	_bx,_bx
@@found:
        mov     eax,[_bx+sampleList.gusSample]
@@exit:
        LEAVEPROC
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   void insertSample(void *ptr, long offset);
; *
; *     Description :   Inserts a sample to sample list
; *
; ************************************************************************/

CPROC   insertSample @@pptr,@@gusoffset

        ENTERPROC
        mov     _cx,MAXSAMPLE
        sub     _bx,_bx
@@loop:
        cmp     [_bx+sampleList.origSample],0
	je      @@found
        add     _bx,SIZE SAMPLELINK
        loop    @@loop
        jmp     @@exit
@@found:
        mov     eax,[@@pptr]
        mov     [_bx+sampleList.origSample],eax
        mov     eax,[@@gusoffset]
        mov     [_bx+sampleList.gusSample],eax
        shr     _bx,3
        inc     _bx
        cmp     bx,[sampleListLength]
        jle     @@exit
        mov     [sampleListLength],bx
@@exit:
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusStartVoice(void);
; *
; *     Description :   Starts output
; *
; ************************************************************************/

CPROC   gusStartVoice

        mov     al,[gusIRQ]
        test    al,8                    ; Is IRQ > 7
        jz      @@01
        add     al,60h                  ; Yes, base is 70h
@@01:
        add     al,8                    ; AL = DMA interrupt number
        push    es
        push    ax
        mov     ah,35h                  ; Get interrupt vector
        int     21h
        mov     [WORD LOW oldIRQ],bx    ; Save it
        mov     [WORD HIGH oldIRQ],es
        pop     ax                      ; Replace vector with the address
        pop     es
        mov     ah,25h                  ; of own interrupt routine
        push    ds
	push    cs
        pop     ds
        mov     _dx,offset interruptGUS ; Set interrupt vector
        int     21h
	pop     ds

        mov     cl,[gusIRQ]
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
        saveIRQ

        mov     dx,[gusCmdAddr]
	mov     al,47h
        out     dx,al
        add     dx,2
        mov     al,256-TIMER2           ; = 320*TIMER2
        out     dx,al

        sub     dx,2
        mov     al,45h
        out     dx,al
        add     dx,2
        mov     al,8                    ; Enable timer 2
        out     dx,al

        mov     dx,[gusBaseAddr]        ; Start timer
        add     dx,8
        mov     al,4
        out     dx,al
        inc     dx
	mov     al,2h
        out     dx,al

        restoreIRQ

        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusStopVoice(void);
; *
; *     Description :   Stops output
; *
; ************************************************************************/

CPROC   gusStopVoice

        mov     dx,[gusCmdAddr]
        mov     al,47h
        out     dx,al
        add     dx,2
        mov     al,256-TIMER2           ; = 320*TIMER2
        out     dx,al

        sub     dx,2
        mov     al,45h
	out     dx,al
        add     dx,2
        mov     al,0                    ; Disable timer 2
        out     dx,al

        mov     dx,[gusBaseAddr]        ; Stop timer
        add     dx,8
        mov     al,4
        out     dx,al
        inc     dx
        mov     al,0C0h
        out     dx,al

        mov     cl,[gusIRQ]             ; Disable interrupt
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
        PUSH    ds
        mov     al,[gusIRQ]
        test    al,8                    ; Is IRQ > 7
        jz      @@01
        add     al,60h                  ; Yes, base is 70h
@@01:
        add     al,8
IF32    <sub     edx,edx>
        mov     dx,[WORD LOW oldIRQ]
        mov     ds,[WORD HIGH oldIRQ]
        mov     ah,25h
        int     21h                     ; Restore IRQ vector
        POP     ds

        mov     _cx,16
        sub     eax,eax
@@closeLoop:
        push    eax _cx
        ecall   gusStopChannel eax
        pop     _cx eax
        inc     eax
        loop    @@closeloop

        mov     dx,[gusCmdAddr]         ; Close outputs/inputs
        mov     al,00001011b
        out     dx,al

        mov     ax,14
        mov     bx,[gusBaseAddr]
        call    NEAR _gusReset

        ret
ENDP

u_IRQLatch      db      0,0,1,3,0,2,0,4,0,0,0,5,6,0,0,7
u_DMALatch      db      0,1,0,2,0,3,4,5

;/*************************************************************************
; *
; *     Function    :   short gusInit(CARDINFO *scard);
; *
; *     Description :   Inits GUS
; *
; ************************************************************************/

CPROC   gusInit @@scard

        ENTERPROC esi edi
IFDEF __C32__
        mov     al,'Û'
        ecall   debugit
ENDIF
        LESSI   [@@scard]
        mov     al,[ESSI+CARDINFO.DMAIRQ]
        mov     [gusIRQ],al
        mov     al,[ESSI+CARDINFO.DMAchannel]
        mov     [gusDMA],al

        cli
        sub     _bx,_bx
        mov     bl,[ESSI+1+CARDINFO.extraField]
	mov     cl,[_bx+u_IRQLatch]
        shl     cl,3
	mov     bl,[ESSI+CARDINFO.DMAIRQ]
        or      cl,[_bx+u_IRQLatch]
        cmp     bl,[ESSI+1+CARDINFO.extraField]
        jne     @@JustStore
        or      cl,40h
@@JustStore:
        push    cx
        mov     bl,[ESSI+CARDINFO.DMAchannel]
        mov     cl,[_bx+u_DMALatch]
        shl     cl,3
        mov     bl,[ESSI+CARDINFO.extraField]
        or      cl,[_bx+u_DMALatch]
        cmp     bl,[ESSI+CARDINFO.DMAchannel]
        jne     @@JustStore2
        or      cl,40h
@@JustStore2:
	mov     bl,cl
        pop     cx

        ; Set up for Digital ASIC
	mov     dx,[ESSI+CARDINFO.ioPort]
        add     dl,0fh
        mov     al,5
        out     dx,al
	mov     dx,[ESSI+CARDINFO.ioPort]
        xor     al,al
        out     dx,al
        add     dl,0Bh
        out     dx,al
        add     dl,4
        out     dx,al
        sub     dl,0Fh

        ; First do DMA control register
        xor     al,al
        out     dx,al
        add     dl,0Bh
        mov     al,bl
        or      al,80h
        out     dx,al
        sub     dl,0Bh

        ; IRQ CONTROL REG
	mov     al,40h
        out     dx,al
	add     dl,0Bh
        mov     al,cl
        out     dx,al
        sub     dl,0Bh

        ; First do DMA control register
        xor     al,al
        out     dx,al
        add     dl,0Bh
        mov     al,bl
        out     dx,al
        sub     dl,0Bh

        ; IRQ CONTROL REG
        mov     al,40h
        out     dx,al
	add     dl,0Bh
        mov     al,cl
        out     dx,al
        sub     dl,0Bh

        ; IRQ CONTROL, ENABLE IRQ
        ; just to Lock out writes to irq\dma register ...
        selectChannel   0

        ; enable output & irq, disable line & mic input
        mov     dx,[ESSI+CARDINFO.ioPort]
        mov     al,9
        out     dx,al

        ; IRQ CONTROL, ENABLE IRQ
        ; just to Lock out writes to irq\dma register ...
        selectChannel   0
        sti
@@Exit:
        cld
        PUSHES
        push    _si
        movzx   _bx,[ESSI+CARDINFO.DMAchannel]
        imul    _bx,_bx,SIZE DMAPORT
        lea     _si,[_bx+DMAports]      ; SI = DMAports[DMAchannel]
        PUSHDS
        POPES
	mov     _di,offset curDMA       ; ESDI = curDMA
        mov     _cx,SIZE DMAPORT
	cli
        _segcs
        rep     movsb                   ; Copy structure
        sti
        pop     _si
        POPES

        mov     dx,[ESSI+CARDINFO.ioPort]         ; Close outputs/inputs
        mov     al,00001011b
        out     dx,al

        mov     ax,16
        mov     bx,[ESSI+CARDINFO.ioPort]
        call    _gusReset

        mov     dx,[gusCmdAddr]         ; Open output
	mov     al,00001001b
        out     dx,al

        call    initEventQueue
	mov     ax,[gusBaseAddr]
        sub     ebx,ebx
        mov     cl,0
        call    __gusPoke
	mov     ax,[gusBaseAddr]
	mov     ebx,1
	mov     cl,0
	call    __gusPoke

	mov     [sampleListLength],0
	mov     [masterVol],200
	mov     [dmaActive],0
	mov     [gusBUSY],0
	mov     [irqStatus],0
	mov	[gusDeltaTime],TIME_DELTA

	PUSHDS                          ; Prepare for clearing tables
	POPES
	sub	eax,eax
	cld

	memSet	sampleList,<(SIZE SAMPLELINK)*MAXSAMPLE>
	memSet	chBase,32*4
	memSet	chPaused,32
	memSet	chFreq,32*4
	memSet	chVolume,32*2

	LEAVEPROC esi edi
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   void gusClose(void);
; *
; *     Description :   Closes GUS
; *
; ************************************************************************/

CPROC   gusClose

	ecall   gusStopVoice
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusSetSample(short channel, SAMPLEINFO *sinfo);
; *
; *     Description :   Sets a new sample on a channel
; *
; ************************************************************************/

CPROC   gusSetSample @@channel,@@sinfo

        ENTERPROC
        mov     eax,[pseudoTime]
        mov     [staticEvent.time],eax
        mov     [staticEvent.func],offset __gusPrimeVoice
        LESBX   [@@sinfo]
        mov     eax,[@@channel]
        mov     edx,[ESBX+SAMPLEINFO.loopStart]
        shl     edx,8
        or      eax,edx
        mov     [staticEvent.p1],eax
        mov     eax,[ESBX+SAMPLEINFO.voiceData]
        mov     [staticEvent.p2],eax
        mov     eax,[ESBX+SAMPLEINFO.loopEnd]
	mov     edx,[ESBX+SAMPLEINFO.length]
        shl     edx,16
        or      eax,edx
	mov     [staticEvent.p3],eax

	call    insertEvent
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusPlaySample(short @@channel, long freq, short volume);
; *
; *     Description :   Plays the sample
; *
; ************************************************************************/

CPROC   gusPlaySample @@channel,@@freq,@@volume

        ENTERPROC
        mov     eax,[pseudoTime]
        mov     [staticEvent.time],eax
        mov     [staticEvent.func],offset __gusGoVoice
        mov     eax,[@@channel]
        mov     [staticEvent.p1],eax
        mov     eax,[@@freq]
        mov     [staticEvent.p2],eax
        mov     eax,[@@volume]
        mov     [staticEvent.p3],eax
        call    insertEvent
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusSetVolume(short @@channel, short volume);
; *
; *     Description :   Sets new volume on a @@channel
; *
; ************************************************************************/

CPROC   gusSetVolume @@channel,@@volume

        ENTERPROC
        mov     eax,[pseudoTime]
        mov     [staticEvent.time],eax
	mov     [staticEvent.func],offset __gusSetVolume
        mov     eax,[@@channel]
	mov     [staticEvent.p1],eax
        mov     eax,[@@volume]
        mov     [staticEvent.p2],eax
        call    insertEvent
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusSetRate(short @@channel, long freq);
; *
; *     Description :   Sets new playing frequency
; *
; ************************************************************************/

CPROC   gusSetRate @@channel,@@freq

        ENTERPROC
        mov     eax,[pseudoTime]
        mov     [staticEvent.time],eax
        mov     [staticEvent.func],offset __gusSetRate
        mov     eax,[@@channel]
        mov     [staticEvent.p1],eax
        mov     eax,[@@freq]
        mov     [staticEvent.p2],eax
        call    insertEvent
        LEAVEPROC

        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusSetPosition(short @@channel, long position);
; *
; *     Description :   Resets sample to a new playing position
; *
; ************************************************************************/

CPROC   gusSetPosition @@channel,@@position

        ENTERPROC
	mov     eax,[pseudoTime]
        mov     [staticEvent.time],eax
	mov     [staticEvent.func],offset __gusSetPosition
        mov     eax,[@@channel]
        mov     [staticEvent.p1],eax
        mov     eax,[@@position]
        mov     [staticEvent.p2],eax
        call    insertEvent
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusSetPanning(short @@channel, short panning);
; *
; *     Description :   Sets voice's panning position
; *
; ************************************************************************/

CPROC   gusSetPanning @@channel,@@panning

        ENTERPROC
        mov     eax,[pseudoTime]
        mov     [staticEvent.time],eax
        mov     [staticEvent.func],offset __gusSetPan
        mov     eax,[@@channel]
        mov     [staticEvent.p1],eax
        mov     eax,[@@panning]
        cmp     eax,PAN_SURROUND
        jne     @@noSurround
        mov     eax,PAN_MIDDLE
@@noSurround:
        mov     [staticEvent.p2],eax
        call    insertEvent
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusSetMasterVolume(short volume);
; *
; *     Description :   Sets new master volume
; *
; ************************************************************************/

CPROC   gusSetMasterVolume @@volume

        ENTERPROC
        mov     eax,[@@volume]
        shl     ax,2
        mov     [masterVol],ax

        movzx   ecx,[gusVoices]
        sub     _dx,_dx
@@loop:
        mov     _ax,_dx
        mov     _bx,_dx
        shl     _bx,1
	mov     bx,[chVolume+_bx]
        push    _cx _dx
	call    __gusSetVolume
	pop     _dx _cx
        inc     _dx
        loop    @@loop
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusPauseChannel(short @@channel);
; *
; *     Description :   Pauses the voice
; *
; ************************************************************************/

CPROC   gusPauseChannel @@channel

        ENTERPROC
        saveIRQ

        mov     ebx,[@@channel]
        mov     [_bx+chPaused],1

        selectChannel bl

	mov     ax,0
	call    rampVolume

	REPT 3
	mov     dx,[gusCmdAddr]
	mov     al,0
	out     dx,al
	add     dx,2
	in      al,dx
	or      al,3                    ; Stop voice
	out     dx,al
	sub	dx,2
	DELAY
	ENDM

	restoreIRQ
	LEAVEPROC
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusResumeChannel(short @@channel);
; *
; *     Description :   Resumes the voice
; *
; ************************************************************************/

CPROC   gusResumeChannel @@channel

        ENTERPROC
        saveIRQ

        mov     ebx,[@@channel]
        mov     [_bx+chPaused],0

        selectChannel bl

	REPT 3
	mov     dx,[gusCmdAddr]
	mov     al,0
	out     dx,al
	add     dx,2
	in      al,dx
	and     al,NOT 3                ; Continue voice
	out     dx,al
	sub	dx,2
	DELAY
	ENDM

        mov     ebx,[@@channel]
	shl     _bx,1
        mov     ax,[chVolume+_bx]
	call    rampVolume

        restoreIRQ
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusPauseAll(void);
; *
; *     Description :   Pauses all channels
; *
; ************************************************************************/

CPROC   gusPauseAll

        movzx   ecx,[gusVoices]
@@loop:
        push    ecx
        dec     ecx
        ecall   gusPauseChannel ecx
        pop     ecx
        loop    @@loop

        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusResumeAll(void);
; *
; *     Description :   Resumes all channels
; *
; ************************************************************************/

CPROC   gusResumeAll

        movzx   ecx,[gusVoices]
@@loop:
        push    ecx
        dec     ecx
        ecall   gusResumeChannel ecx
	pop     ecx
        loop    @@loop
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusPoll(long time);
; *
; *     Description :   "Plays buffer"
; *
; ************************************************************************/

CPROC   gusPoll @@time

	ENTERPROC
        mov     eax,[curTime]
        cmp     eax,[pseudoTime]
	jb      @@ok
        mov     [pseudoTime],eax
@@ok:
        mov     eax,[@@time]
        add     [pseudoTime],eax
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   long gusGetDelta(void);
; *
; *     Description :   Gets "delta" time
; *
; ************************************************************************/

CPROC   gusGetDelta

        mov     eax,[pseudoTime]
        sub     eax,[curTime]
        jns     @@ok
        sub     eax,eax
@@ok:
	cmp     eax,[gusDeltaTime]
        jbe     @@now
        mov     eax,0
@@now:
	sub     eax,[gusDeltaTime]
	neg     eax
IFDEF __16__
        shld    edx,eax,16
ENDIF
        ret
ENDP

LABEL   gusVolumes WORD
        dw      00E00h
GusVol          dw 20000,39120,41376,42656,43936,45072,45696,46240,46848,47408
                dw 47952,48528,49072,49360,49632,49920,50160,50432,50704,50928
                dw 51168,51424,51680,51952,52160,52448,52672,52912,53152,53312
                dw 53440,53584,53664,53808,53952,54048,54144,54288,54400,54496
		dw 54608,54720,54832,54944,55072,55184,55312,55440,55552,55696
                dw 55760,55888,56016,56096,56240,56304,56448,56528,56672,56752
                dw 56896,56976,57136,57216
IF 0
        dw      0B000h,0B800h,0BC00h,0BE00h,0C000h,0C400h,0C800h,0CC00h
        dw      0D000h,0D200h,0D400h,0D600h,0D800h,0DA00h,0DC00h,0DE00h
        dw      0E000h,0E100h,0E200h,0E300h,0E400h,0E500h,0E600h,0E700h
        dw      0E800h,0E900h,0EA00h,0EB00h,0EC00h,0ED00h,0EE00h,0EF00h
        dw      0F080h,0F100h,0F180h,0F200h,0F280h,0F300h,0F380h,0F400h
        dw      0F480h,0F500h,0F580h,0F600h,0F680h,0F700h,0F780h,0F800h
        dw      0F880h,0F900h,0F980h,0FA00h,0FA80h,0FB00h,0FB80h,0FC00h
        dw      0FC80h,0FD00h,0FD80h,0FE00h,0FE40h,0FE80h,0FEC0h,0FF00h
ENDIF

LABEL   freqs WORD
        DW 44100,41160,38587,36317,34300,32494,30870,29400,28063,26843,25725
        DW 24696,23746,22866,22050,21289,20580,19916,19293

;/*************************************************************************
; *
; *     Function    :   rampVolume
; *
; *     Description :   Ramps the volume to AX
; *
; *     Input       :   AX = end volume
; *
; ************************************************************************/

PROC    rampVolume NEAR

	cmp     ax,64
        jbe     @@volok
	mov     ax,64
@@volok:
        imul    [masterVol]
        shr     ax,8
        movzx   ebx,ax
        shl     ebx,1
        mov     cx,[gusVolumes+_bx]

        mov     dx,[gusCmdAddr]
        mov     al,89h
        out     dx,al
        inc     dx
        in      ax,dx
	push    cx
        push    ax
        shr     ax,8
	shr     cx,8
        cmp     ax,cx
;       je      @@Done2
        jbe     @@OK
        xchg    cx,ax
@@OK:
        push    ax
        mov     dx,[gusCmdAddr]
        mov     al,7
        out     dx,al
        add     dx,2
        pop     ax
        out     dx,al
        mov     dx,[gusCmdAddr]
        mov     al,8
        out     dx,al
        add     dx,2
        mov     ax,cx
        out     dx,al
        mov     dx,[gusCmdAddr]
        mov     al,6
        out     dx,al
        add     dx,2
        mov     al,00011111b
        out     dx,al
        mov     bl,00000000b
        pop     ax
	pop     cx
        cmp     ax,cx
	jb      @@OK2
        or      bl,01000000b
@@OK2:
	REPT 2
	mov     dx,[gusCmdAddr]
	mov     al,0Dh
	out     dx,al
	add     dx,2
	mov     al,bl
	out     dx,al
	DELAY
	ENDM
	jmp     @@Done
@@Done2:
	pop     ax ax
@@Done:

	ret
ENDP

;/*************************************************************************
; *
; *     Description : Sets up ('primes') a sample to be played in the @@channel
; *
; *     Input       :   ax      = @@channel
; *
; ************************************************************************/

PROC    __gusPrimeVoice NEAR
locs = 0
procargs = 0
LOCALVAR        _word @@channel
LOCALVAR        _dword @@sample
LOCALVAR        _dword @@loopStart
LOCALVAR        _dword @@loopEnd
LOCALVAR        _dword @@voicegus
LOCALVAR        _dword @@slength

        ENTERPROC _si
        mov     [@@channel],ax
        and     [word @@channel],7Fh
        shr     eax,8
        mov     [@@loopStart],eax
        mov     [@@sample],ebx
        mov     [@@loopEnd],ecx
        and     [dword @@loopEnd],0FFFFh
	shr     ecx,16
	mov     [@@slength],ecx

	saveIRQ

	PUSHES
	ecall   findSample <[dword @@sample]>
	POPES
	mov     [@@voicegus],eax
	movzx   ebx,[word @@channel]
	shl     ebx,2
	cmp     [_bx+chBase],eax
	je      @@done
	mov     [_bx+chBase],eax

	selectChannel <[byte @@channel]>

	mov     dx,[gusCmdAddr]
	sub     al,al
	out     dx,al
	cmp     [DWORD @@loopEnd],0
	jz      @@noloop
	or      al,8
@@noloop:
	or      al,2
	mov	cl,al
	add     dx,2
	out     dx,al
	DELAY
	sub     dx,2
	sub     al,al
	out     dx,al
	add     dx,2
	mov	al,cl
	out     dx,al

	mov     dx,[gusCmdAddr]
	mov     ebx,[@@voicegus]
	cmp     [DWORD @@loopEnd],0
	je      @@noloopings
	add     ebx,[@@loopStart]
@@noloopings:
	mov     al,02h
	out     dx,al                   ; Set start of loop
	inc     dx
	mov     eax,ebx
	shr     eax,7
	and     ax,1fffh
	out     dx,ax
	dec     dx
	mov     al,03h
	out     dx,al
	inc     dx
	mov     ax,bx
	and     ax,07fh
	shl     ax,9
	out     dx,ax

	mov     dx,[gusCmdAddr]
	mov     ebx,[@@voicegus]
	mov     eax,[@@loopEnd]
	or      eax,eax
	jne     @@looping
	mov     eax,[@@slength]
@@looping:
	add     ebx,eax
	mov     al,04h
	out     dx,al                   ; Set end of loop
	inc     dx
	mov     eax,ebx
	shr     eax,7
	and     ax,1fffh
	out     dx,ax
	dec     dx
	mov     al,05h
	out     dx,al
	inc     dx
	mov     ax,bx
	and     ax,07fh
	shl     ax,9
	out     dx,ax
@@done:
	restoreIRQ
	DELAY
	DELAY
@@exit:
        sub     _ax,_ax
        LEAVEPROC _si
	ret
ENDP

;/*************************************************************************
; *
; *     Description : Plays a sample that has been primed beforehand
; *
; *     Input       :   ax      = @@channel number
; *                     ebx     = rate
; *                     cx      = volume
; *
; ************************************************************************/

PROC    __gusGoVoice NEAR
locs = 0
procargs = 0
LOCALVAR        _word @@channel
LOCALVAR        _dword @@rate
LOCALVAR        _word @@vol
LOCALVAR        _dword @@base

	ENTERPROC
	mov     [@@channel],ax
	mov     [@@rate],ebx
	mov     [@@vol],cx

	saveIRQ

	movzx   ebx,[WORD @@channel]
	shl     ebx,1
	mov     ax,[@@vol]
	mov     [_bx+chVolume],ax
	shl     ebx,1
	mov     eax,[_bx+chBase]
	mov     [@@base],eax

	selectChannel <[byte @@channel]>

	mov     dx,[gusCmdAddr]         ; Stop old voice
	mov     al,80h
	out     dx,al
	add     dx,2
	in      al,dx
	or      al,3
	mov	cl,al
	sub     dx,2
	mov     al,0
	out     dx,al
	add     dx,2
	mov	al,cl
	out     dx,al
	sub     dx,2
	DELAY
	mov     al,0
	out     dx,al
	add     dx,2
	mov	al,cl
	out     dx,al
	sub     dx,2
	DELAY
	mov     al,0
	out     dx,al
	add     dx,2
	mov	al,cl
	out     dx,al

	REPT 2
	mov     dx,[gusCmdAddr]
	mov     al,0ah
	out     dx,al                   ; Set beginning of data
	inc     dx
	mov     eax,[@@base]
	shr     eax,7
	and     ax,1fffh
	out     dx,ax
	dec     dx
	mov     al,0bh
	out     dx,al
	inc     dx
	mov     ax,[WORD @@base]
	and     ax,07fh
	shl     ax,9
	out     dx,ax
	DELAY
	ENDM

	movzx   ebx,[gusVoices]
	sub     ebx,14
	shl     ebx,1
	movzx   eax,[freqs+_bx]         ; Set playing frequency
	mov     ecx,eax
	mov     ebx,[@@rate]
	shl     ebx,9
	shr     eax,1
	add     eax,ebx
	sub     edx,edx
	idiv    ecx
	shl     eax,1
	mov     ecx,eax
	REPT 2
	mov     dx,[gusCmdAddr]
	mov     al,1
	out     dx,al
	inc     dx
	mov     ax,cx
	out     dx,ax
	DELAY
	ENDM

	movzx   ebx,[WORD @@channel]
	shl     ebx,1
	mov     eax,[@@rate]
	mov     [_bx+chFreq],eax

	mov     dx,[gusCmdAddr]
	mov     al,9
	out     dx,al
	inc     dx
	mov     ax,0E00h                ; Volume = 0
	out     dx,ax
	DELAY
	out	dx,ax

	mov     dx,[gusCmdAddr]
	mov     al,80h
	out     dx,al
	add     dx,2
	in      al,dx			; Get voice status
	sub     dx,2
	and	al,not 3		; Enable playing
	mov	cl,al
	mov	al,0
	out	dx,al
	add	dx,2
	mov	al,cl
	out	dx,al			; Start voice 4 times!
	DELAY
	sub	dx,2
	mov	al,0
	out	dx,al
	add	dx,2
	mov	al,cl
	out	dx,al
	DELAY
	sub	dx,2
	mov	al,0
	out	dx,al
	add	dx,2
	mov	al,cl
	out	dx,al
	DELAY
	sub	dx,2
	mov	al,0
	out	dx,al
	add	dx,2
	mov	al,cl
	out	dx,al

	movzx   ebx,[WORD @@channel]
	cmp     [_bx+chPaused],1
	je      @@novol

	mov     ax,[@@vol]
	call    rampVolume
@@novol:

	restoreIRQ
@@exit:
	sub     _ax,_ax
	LEAVEPROC
	ret
ENDP

;/*************************************************************************
; *
; *     Function    : int gusSetVolume(int @@channel,unsigned volume);
; *
; *     Description : Changes the volume of a @@channel
; *
; *     Input       :   ax = @@channel nr.
; *                     bx = volume
; *
; ************************************************************************/

PROC    __gusSetVolume NEAR
locs = 0
procargs = 0
LOCALVAR        _word @@channel
LOCALVAR        _word @@vol

        ENTERPROC
        mov     [@@channel],ax
        mov     [@@vol],bx

        checkPause

        movzx   ebx,[WORD @@channel]
        shl     ebx,1
        mov     ax,[@@vol]
	mov     [_bx+chVolume],ax

        saveIRQ

        selectChannel <[byte @@channel]>

        mov     ax,[@@vol]
        call    rampVolume

	restoreIRQ
@@exit:
	LEAVEPROC
	ret
ENDP

;/*************************************************************************
; *
; *     Function    : int gusStopChannel(int @@channel);
; *
; *     Description : Stops the voice on @@channel
; *
; *     Input       :   ax = @@channel nr.
; *
; ************************************************************************/

CPROC   gusStopChannel @@channel

	ENTERPROC _si
	saveIRQ

	selectChannel <[byte @@channel]>

	mov     ebx,[@@channel]
	shl     ebx,1
        mov     [_bx+chFreq],0
        mov     [_bx+chVolume],0
	shl     ebx,1
	mov     [_bx+chBase],-1

	mov     ax,0
	call    rampVolume

	DELAY

	REPT 2
	mov     dx,[gusCmdAddr]
	mov     al,0Dh
	out     dx,al
	inc     dx
	mov     ax,11b                  ; Stop ramp
	out     dx,ax
	DELAY
	ENDM

	mov     dx,[gusCmdAddr]
	mov     al,0
	out     dx,al
	add     dx,2
	mov     al,3                    ; Stop voice
	out     dx,al
	sub     dx,2
	DELAY
	mov     al,0
	out     dx,al
	add     dx,2
	mov     al,3                    ; Stop voice second time
	out     dx,al
	sub     dx,2

        DELAY

	mov     dx,[gusCmdAddr]
	mov     al,9
        out     dx,al
        inc     dx
	mov     ax,0E00h                ; Volume = 0
	out     dx,ax

	REPT 2
	mov     dx,[gusCmdAddr]
	mov     al,0ah                  ; Current position
	out     dx,al
	inc     dx
	mov     ax,0
	out     dx,ax
	dec     dx
	mov     al,0bh
	out     dx,al
	inc     dx
	mov     ax,0
	out     dx,ax
	dec     dx
	DELAY
	ENDM

        mov     al,02h                  ; Loop start
        out     dx,al
        inc     dx
        mov     ax,0
        out     dx,ax
        dec     dx
        mov     al,03h
        out     dx,al
        inc     dx
        mov     ax,0
        out     dx,ax
	dec     dx

        mov     al,04h                  ; Loop end
	out     dx,al
	inc     dx
	mov     ax,0
	out     dx,ax
	dec     dx
	mov     al,05h
	out     dx,al
	inc     dx
	mov     ax,0
	out     dx,ax
	dec     dx

	mov	_cx,MAXEVENT
	sub	_si,_si
	mov	dl,[byte @@channel]
@@clearChannelEvents:
	cmp	dl,[byte _si+eventQueue.p1] ; Is channel the same?
	jne	@@next
	mov	[_si+eventQueue.func],0	; Don't call it
@@next:
	add	_si,SIZE GUSEVENT
	loop	@@clearChannelEvents

	restoreIRQ
	LEAVEPROC _si
	ret
ENDP

;/*************************************************************************
; *
; *     Function    : int gusSetRate(int @@channel,unsigned long rate);
; *
; *     Description : Changes the rate (frequency) of a @@channel
; *
; *     Input       :   ax  = @@channel
; *                     ebx = rate
; *
; ************************************************************************/

PROC    __gusSetRate NEAR
locs = 0
procargs = 0
LOCALVAR        _word @@channel
LOCALVAR        _dword @@rate

        ENTERPROC
        mov     [@@channel],ax
        mov     [@@rate],ebx
        mov     ecx,[@@rate]

        movzx   ebx,[WORD @@channel]
        shl     ebx,1
        cmp     [_bx+chFreq],ecx
	je      @@exit
        mov     [_bx+chFreq],ecx

	checkPause

        movzx   _bx,[gusVoices]
        sub     _bx,14
        shl     _bx,1
        movzx   eax,[freqs+_bx]
        mov     ecx,eax
	mov     ebx,[@@rate]
        shl     ebx,9
        shr     eax,1
	add     eax,ebx
        sub     edx,edx
        idiv    ecx
        shl     eax,1
	mov     cx,ax


        saveIRQ

        selectChannel <[byte @@channel]>

	DELAY

        mov     dx,[gusCmdAddr]
        mov     al,1
        out     dx,al
        inc     dx
        in      ax,dx
        cmp     ax,cx
        je      @@nochange
	mov     ax,cx
	out     dx,ax
@@nochange:
	restoreIRQ
@@exit:
	LEAVEPROC
	ret
ENDP



;/*************************************************************************
; *
; *     Description : Sets the sample position to an absolute location
; *
; *     Input       : ax = @@channel
; *                   ebx = pos
; *
; ************************************************************************/

PROC    __gusSetPosition NEAR
locs = 0
procargs = 0
LOCALVAR        _word @@channel
LOCALVAR        _dword @@pos

	ENTERPROC
	mov     [@@channel],ax
	mov     [@@pos],ebx

	checkPause

	saveIRQ

	movzx   ebx,[WORD @@channel]
	shl     ebx,2
	mov     eax,[_bx+chBase]
	add     [@@pos],eax

	selectChannel <[byte @@channel]>

	mov     dx,[gusCmdAddr]
	mov     al,0ah
	out     dx,al
	inc     dx
	mov     eax,[@@pos]
	shr     eax,7
	out     dx,ax
	dec     dx
	mov     al,0bh
	out     dx,al
	inc     dx
	mov     ax,[WORD @@pos]
	shl     ax,9
	out     dx,ax

	DELAY

	mov     dx,[gusCmdAddr]
	mov     al,0ah
	out     dx,al
	inc     dx
	mov     eax,[@@pos]
	shr     eax,7
	out     dx,ax
	dec     dx
	mov     al,0bh
	out     dx,al
	inc     dx
	mov     ax,[WORD @@pos]
	shl     ax,9
	out     dx,ax

	restoreIRQ
@@exit:
	LEAVEPROC
	ret
ENDP

;/*************************************************************************
; *
; *     Description : Sets the panning position
; *
; *     Input       : ax = @@channel
; *                   ebx = panning value (-63 - 63)
; *
; ************************************************************************/

PROC    __gusSetPan NEAR

	mov     dl,al

	saveIRQ

	selectChannel dl

	cmp     bl,-63
	jge     @@1
	mov     bl,-63
@@1:
	cmp     bl,63
	jle     @@2
	mov     bl,63
@@2:
	sar     bl,3
	add     bl,8
	and     bl,0Fh

	mov     dx,[gusCmdAddr]
	mov     al,0Ch
	out     dx,al
	add     dx,2
	mov     al,bl
	out     dx,al

	restoreIRQ

	ret
ENDP

CPROC   gusPoke @@addr, @@value

        ENTERPROC
	saveIRQ
        mov     ax,[gusBaseAddr]
        mov     ebx,[@@addr]
        mov     cl,[byte @@value]
        call    __gusPoke
        restoreIRQ
        LEAVEPROC
        ret
ENDP

CPROC   gusPeek @@addr

        ENTERPROC
        saveIRQ
        mov     ax,[gusBaseAddr]
        mov     ebx,[@@addr]
        call    __gusPeek
        mov     cx,ax
        restoreIRQ
        mov     ax,cx
        LEAVEPROC
        ret
ENDP

PROC    __gusPoke NEAR ;ax=port, ebx=addr, cl=data

        push    ax
        mov     dx,ax
        add     dx,103h
        mov     al,43h
        out     dx,al
        inc     dx
        mov     ax,bx
        out     dx,ax
        dec     dx
        mov     al,44h
	out     dx,al
        add     dx,2
        shr     ebx,16
	mov     al,bl
        out     dx,al
	pop     dx
        add     dx,107h
        mov     al,cl
        out     dx,al
        ret
ENDP

PROC    __gusPeek NEAR ;ax=port, ebx=addr

        push    ax
        mov     dx,ax
        add     dx,103h
        mov     al,43h
        out     dx,al
        inc     dx
        mov     ax,bx
        out     dx,ax
        dec     dx
        mov     al,44h
        out     dx,al
        add     dx,2
        shr     ebx,16
        mov     al,bl
        out     dx,al
        pop     dx
        add     dx,107h
        in      al,dx
        ret
ENDP

;/*************************************************************************
; *
; *     Description : Init
; *
; *     Input       :   ax = @@channel count
; *                     bx = base address
; *
; ************************************************************************/

PROC    _gusReset NEAR

        cmp     ax,14
        jae     @@ok
	mov     ax,14
@@ok:
	cmp     ax,32
        ja      @@err
        mov     [gusVoices],al
        mov     [gusBaseAddr],bx
        add     bx,102h
        mov     [gusChannelAddr],bx
        inc     bx
        mov     [gusCmdAddr],bx

        saveIRQ

        mov     dx,[gusCmdAddr]         ; Pull reset
        mov     al,4ch
        out     dx,al
        add     dx,2
        sub     al,al
        out     dx,al

        REPT    10
            DELAY
        ENDM

        mov     dx,[gusCmdAddr]         ; Release reset
        mov     al,4ch
        out     dx,al
        add     dx,2
        mov     al,1
        out     dx,al

        REPT    10
            DELAY
        ENDM

        mov     dx,[gusBaseAddr]        ; Reset MIDI
        add     dx,100h
        mov     al,3
        out     dx,al

        REPT    10
            DELAY
	ENDM

        mov     dx,[gusBaseAddr]
	add     dx,100h
        mov     al,0
	out     dx,al

        mov     dx,[gusCmdAddr]         ; Disable DMA
        mov     al,41h
        out     dx,al
        add     dx,2
        mov     al,0
        out     dx,al
        sub     dx,2

        mov     al,45h                  ; Disable timers
        out     dx,al
        add     dx,2
        mov     al,0
        out     dx,al
        sub     dx,2

        mov     al,49h                  ; Disable sampling
        out     dx,al
        add     dx,2
        mov     al,0
        out     dx,al
        sub     dx,2

        DELAY

        restoreIRQ
        DELAY
        saveIRQ

        mov     dx,[gusBaseAddr]        ; Ack any IRQ
        add     dx,6
        in      al,dx

        mov     dx,[gusCmdAddr]         ; Ack DMA IRQ
        mov     al,41h
        out     dx,al
        add     dx,2
        in      al,dx
        sub     dx,2

        mov     al,49h                  ; Ack sampling IRQ
        out     dx,al
	add     dx,2
        in      al,dx
	sub     dx,2

        mov     al,8fh
        out     dx,al
        add     dx,2
        in      al,dx

        mov     dx,[gusCmdAddr]
        mov     al,0eh                  ; Set the number of active voices
        out     dx,al
	add     dx,2
	mov     al,31
	or      al,0c0h
	out     dx,al

	mov     ecx,32
@@resetloop:
	push    ecx
	dec     ecx
	ecall   gusStopChannel ecx
	pop     ecx

	mov     dx,[gusChannelAddr]     ; Reset voices
	mov     al,cl
	dec     al
	out     dx,al

	inc     dx
	mov     al,6
	out     dx,al
	add     dx,2
	mov     al,0                    ; Volume ramp speed = 0
	out     dx,al
	sub     dx,2

	mov     al,0Dh                  ; Turn ramp off
	out     dx,al
	add     dx,2
	mov     al,11b
	out     dx,al
	DELAY
	out	dx,al
	sub     dx,2

	mov     al,9
	out     dx,al
	inc     dx
	sub     ax,ax
	out     dx,ax
	DELAY
	out	dx,ax
	dec     dx

	mov     al,0
	out     dx,al
	add     dx,2
	mov     al,11b                  ; Turn voice off
	out     dx,al
	DELAY
	out	dx,al

	loop    @@resetloop

	restoreIRQ
	DELAY
	saveIRQ

	mov     dx,[gusBaseAddr]        ; Ack any IRQ
	add     dx,6
	in      al,dx

        mov     dx,[gusCmdAddr]         ; Ack DMA IRQ
        mov     al,41h
        out     dx,al
        add     dx,2
        in      al,dx
        sub     dx,2

        mov     al,49h                  ; Ack sampling IRQ
        out     dx,al
        add     dx,2
        in      al,dx
        sub     dx,2

        mov     al,8fh
	out     dx,al
        add     dx,2
        in      al,dx

        mov     dx,[gusCmdAddr]
	mov     al,0eh                  ; Set the number of active voices
        out     dx,al
        add     dx,2
        mov     al,[byte gusVoices]
        dec     al
        or      al,0c0h
        out     dx,al

        mov     dx,[gusCmdAddr]         ; Reset
        mov     al,4ch
        out     dx,al
        add     dx,2
        mov     al,7
        out     dx,al

        mov     dx,[gusBaseAddr]
        mov     al,00001001b            ; Enable output
        out     dx,al

        restoreIRQ

        sub     _ax,_ax
        jmp     @@eksitti
@@err:
        mov     _ax,-1
@@eksitti:
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   void dma64(long gusStart,long start,unsigned length);
; *
; ************************************************************************/

CPROC   dma64 @@gusStart, @@start, @@len

        ENTERPROC
        cmp     [gusDMA],4
        jl      @@gus8
	mov     eax,[@@gusStart]                ; Translate address for 16-bit DMA
        mov     edx,eax
        shr     eax,1
	and     eax,0001FFFFh
        and     edx,000c0000h
	or      eax,edx
        mov     [@@gusStart],eax
@@gus8:
        mov     eax,[@@start]
        mov     edx,eax
        shr     edx,16                  ; EDX = page
        cmp     [gusDMA],4
        jl      @@8bit
        shr     eax,1                   ; 16-bit offset
@@8bit:
        mov     bx,ax                   ; Offset
        mov     ah,dl                   ; Page

        cli
        mov     al,[gusDMA]
        or      al,4
        mov     dx,[curDMA.wrsmr]
        out     dx,al                   ; Break On
        mov     al,[gusDMA]
        and     al,3
        or      al,048h
        mov     dx,[curDMA.wrmode]
        out     dx,al
        mov     dx,[curDMA.page]
        mov     al,ah
        out     dx,al                   ; Page
        mov     al,0
        mov     dx,[curDMA.clear]
        out     dx,al                   ; Reset counter

        mov     dx,[curDMA.addr]
        mov     al,bl
        out     dx,al                   ; Offset
        mov     al,bh
        out     dx,al

        mov     al,0
        mov     dx,[curDMA.clear]
        out     dx,al                   ; Reset counter

	mov     ecx,[@@len]
        cmp     [gusDMA],4
        jl      @@nodiv
	shr     cx,1
@@nodiv:
	jcxz    @@zero
        dec     cx
@@zero:
        mov     dx,[curDMA.count]
        mov     al,cl
        out     dx,al                   ; Count
        mov     al,ch
        out     dx,al

        mov     al,[gusDMA]
        and     al,3
        mov     dx,[curDMA.wrsmr]
        out     dx,al                   ; Break Off

        shr     [@@gusStart],4

        mov     [dmaActive],1

        mov     dx,[gusCmdAddr]
        mov     al,42h
        out     dx,al
        inc     dx
        mov     ax,[WORD @@gusStart]
        out     dx,ax
        dec     dx

        mov     al,41h
        out     dx,al
        add     dx,2
        mov     al,10101001b            ; Invert MSB, 1/2 speed, 8-bit DATA, IRQ enable
        cmp     [gusDMA],4
        jl      @@not16
        or      al,00000100b
@@not16:
        sti
        out     dx,al                   ; Start transfer

        mov     ecx,300000
@@wait:
        cmp     [dmaActive],1
        loopde  @@wait

IF 0
	mov     al,[gusDMA]
        or      al,4
	mov     dx,[curDMA.wrsmr]
        out     dx,al                   ; Break On
        mov     dx,[gusCmdAddr]
        mov     al,41h
        out     dx,al
        add     dx,2
        mov     al,0                    ; Stop GUS DMA
        out     dx,al
ENDIF
        LEAVEPROC
        ret
ENDP

__OLD__ = 0

;/*************************************************************************
; *
; *     Function : void gushmCopyTo(GUSH handle, void *ptr, long start, long length);
; *
; ************************************************************************/

CPROC   gushmCopyTo @@handle,@@pptr,@@start,@@len

        ENTERPROC _di _si

IFNDEF __OLD__

IF 0
        saveIRQ

        mov     dx,[gusBaseAddr]        ; Ack any IRQ
        add     dx,6
        in      al,dx

        mov     dx,[gusCmdAddr]         ; Ack DMA IRQ
        mov     al,41h
        out     dx,al
        add     dx,2
        in      al,dx

        restoreIRQ
ENDIF
        sub     edi,edi
        LESDI   [@@pptr]
        add     edi,[@@len]
	mov     al,[ESDI-1]
        mov     ah,al
        mov     [ESDI],ax
        mov     [ESDI+2],ax
        movzx   eax,[WORD LOW @@pptr]
        movzx   edx,[WORD HIGH @@pptr]
        add     [@@len],4
        shl     edx,4
        add     eax,edx                 ; EAX = linear address
        mov     dx,ax
        add     dx,[WORD @@len]         ; DMA overrun?
        jnc     @@normal
	movzx   edx,ax
        neg     edx
        push    eax edx
	ecall   dma64 [@@handle],eax,edx
        pop     edx eax
        add     [@@handle],edx
        add     eax,edx
        sub     [WORD @@len],dx
@@normal:
        ecall   dma64 [@@handle],eax,[@@len]

ELSE
;       saveIRQ

        sub     edi,edi
        LESDI   [@@pptr]
        add     edi,[@@len]
        mov     al,[ESDI-1]
        mov     ah,al
        mov     [ESDI],ax
        mov     [ESDI+2],ax
        mov     eax,[@@start]
        add     [@@handle],eax
        mov     si,[WORD HIGH @@handle]
        mov     di,[WORD LOW @@handle]
        mov     ecx,[@@len]
        add     ecx,4
        mov     dx,[gusCmdAddr]
        mov     al,44h          ; Dump upper byte, only do it on carry from now
        cli
        out     dx,al           ; on.
        add     dx,2
        mov     ax,si
	out     dx,al
        sti
        sub     dx,2
        PUSHDS
        LDSBX   [@@pptr]
ALIGN 4
@@MainLoop:
        mov     al,43h
        cli
        out     dx,al
        inc     dx
        mov     ax,di
	out     dx,ax           ; Set address
        sti

	add     dx,3
        mov     al,[_bx]
        xor     al,80h
        inc     _bx
        out     dx,al           ; Download byte
        sub     dx,4
        add     di,1
	jc      @@DoLoop
	loop    @@MainLoop
	jmp     short @@exit
@@DoLoop:
	inc     si
	mov     al,44h
	cli
	out     dx,al
	add     dx,2
	mov     ax,si
	out     dx,al
	sti
	sub     dx,2
	loop    @@MainLoop
@@exit:
	POPDS
;       restoreIRQ
ENDIF
	LEAVEPROC _di _si
	ret
ENDP

;/*************************************************************************
; *
; *     Function : void gusDownload(void *ptr, long ptag, long length);
; *
; ************************************************************************/

CPROC   gusDownload @@pptr,@@ptag,@@len

	ENTERPROC edi esi
	ecall   gushmAlloc [@@len]
IFDEF __32__
	push    eax
	ecall   gushmCopyTo eax,[@@pptr],<LARGE 0>,[@@len]
	pop     eax
	ecall   insertSample [@@ptag],eax
ELSE
	push    dx ax
	ecall   gushmCopyTo <dx ax>,[@@pptr],<LARGE 0>,[@@len]
	pop     ax dx
	ecall   insertSample [@@ptag],<dx ax>
ENDIF
	LEAVEPROC edi esi
	ret
ENDP

;/*************************************************************************
; *
; *     Function : void gusUnload(void *ptr);
; *
; ************************************************************************/

CPROC   gusUnload @@pptr

	ENTERPROC
	ecall   findSample [@@pptr]
	mov     [_bx+sampleList.origSample],0   ; Clear entry
	ecall   gushmFree eax
	LEAVEPROC
	ret
ENDP

;/*************************************************************************
; *
; *     Function : void gusUnloadAll(void);
; *
; ************************************************************************/

CPROC   gusUnloadAll

	ENTERPROC _di _si
	ecall   gushmFreeAll
	PUSHDS                          ; Clear sample list
	POPES
	mov     _di,offset sampleList
	sub     eax,eax
	mov     _cx,(SIZE SAMPLELINK)*MAXSAMPLE/4
	cld
	rep     stosd
	mov     [sampleListLength],0
	LEAVEPROC _di _si
	ret
ENDP

;/*************************************************************************
; *
; *     Function : long gusGetSamplingRate(void);
; *
; ************************************************************************/

CPROC   gusGetSamplingRate

	movzx   ebx,[gusVoices]
	sub     ebx,14
        shl     ebx,1
        movzx   eax,[freqs+_bx]
        cwd
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   ushort gusGetVolume(short @@channel);
; *
; *     Description :   Returns the current volume on '@@channel'
; *
; ************************************************************************/

CPROC   gusGetVolume @@channel

        ENTERPROC
        mov     ebx,[@@channel]
	shl     ebx,1
        movzx   eax,[chVolume+_bx]
        cwd
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   ulong gusGetRate(short @@channel);
; *
; *     Description :   Returns the current frequency on '@@channel'
; *
; ************************************************************************/

CPROC   gusGetRate @@channel

        ENTERPROC
	mov     ebx,[@@channel]
        shl     ebx,1
        mov     eax,[chFreq+_bx]
IF16    <shld   edx,eax,16>
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   ulong gusGetPosition(short @@channel);
; *
; *     Description :   Returns the current position on '@@channel'
; *
; ************************************************************************/

CPROC   gusGetPosition @@channel
LOCALVAR        _dword @@pos

        ENTERPROC
        saveIRQ

        selectChannel <[byte @@channel]>

        mov     dx,[gusCmdAddr]         ; Get position
        mov     al,8ah
        out     dx,al
	inc     dx
        sub     eax,eax
        in      ax,dx
        and     ax,01FFFh
        shl     eax,7
        mov     [@@pos],eax
        dec     dx
        mov     al,8bh
        out     dx,al
        inc     dx
        in      ax,dx
        shr     ax,9
        or      [WORD @@pos],ax

        restoreIRQ

        mov     eax,[@@pos]             ; Absolute position
        mov     ebx,[@@channel]         ; Convert it to relative
	shl     ebx,2                   ; position
	sub     eax,[chBase+_bx]
IF16    <shld   edx,eax,16>
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   ushort gusGetPanning(short @@channel);
; *
; *     Description :   Returns the current pan value on '@@channel'
; *
; ************************************************************************/

CPROC   gusGetPanning @@channel

        ENTERPROC
        saveIRQ

        selectChannel <[byte @@channel]>

        mov     dx,[gusCmdAddr]         ; Get Pan position
        mov     al,8Ch
        out     dx,al
        add     dx,2
        in      al,dx
	sub     al,8
        shl     al,3
        sub     ah,ah
        mov     bx,ax

        restoreIRQ

IF32    <movsx  eax,bx>
IF16    <mov    ax,bx>
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   ulong gusGetSample(short @@channel);
; *
; *     Description :   Returns a pointer to the current sample on '@@channel'
; *
; ************************************************************************/

CPROC   gusGetSample @@channel

        ENTERPROC
        mov     ebx,[@@channel]
        shl     ebx,2
	mov     eax,[chBase+_bx]
IF16    <shld   edx,eax,16>
        LEAVEPROC
        ret
ENDP

;/*************************************************************************
; *
; *     Function    :   short gusSetupChannels(short count, ushort *volTable);
; *
; *     Description :   Sets a 'count' channels on GUS
; *
; ************************************************************************/

CPROC   gusSetupChannels @@count,@@volTable

	ENTERPROC
	saveIRQ
        mov     eax,[@@count]
	cmp     ax,14
        jg      @@10
        mov     ax,14
@@10:
        mov     [gusVoices],al
        mov     dx,[gusCmdAddr]
        mov     al,0eh                  ; Set the number of active voices
        out     dx,al
        add     dx,2
        mov     al,[gusVoices]
        dec     al
        or      al,0c0h
        out     dx,al
@@exit:
	restoreIRQ
	LEAVEPROC
	ret
ENDP

;/*************************************************************************
; *
; *     Function    :   int gusGetChannelStatus(short @@channel);
; *
; *     Description :   Returns the status of the channel
; *
; ************************************************************************/

CPROC   gusGetChannelStatus @@channel

        ENTERPROC _si
        sub       _si,_si
        saveIRQ
        mov     ebx,[@@channel]
        shl     ebx,1
        cmp     [_bx+chPaused],1
        jne     @@1
        or      _si,CH_PAUSED
        jmp     @@exit
@@1:
        selectChannel <[byte @@channel]>

        mov     dx,[gusCmdAddr]         ; Get voice status
        mov     al,80h
        out     dx,al
        add     dx,2
	in      al,dx
	test    al,00000001b
	jnz     @@2
	or      _si,CH_PLAYING
	test    al,00001000b
	jz      @@2
	or      _si,CH_LOOPING
@@2:
@@exit:
	restoreIRQ
	mov       _ax,_si           ; Return status in (E)AX
	LEAVEPROC _si
	ret
ENDP

ENDS

END
