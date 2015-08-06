;/************************************************************************
; *
; *	File	    : SDI_WSS.ASM
; *
; *	Description : SDI for Windows Sound System
; *
; *	Copyright (C) 1993 Otto Chrons
; *
; ***********************************************************************
;
;	Revision history of SDI_WSS.ASM
;
;	1.0	20.6.93
;		First version.
;
; ***********************************************************************/

	IDEAL
	JUMPS
	P386N

;	L_PASCAL	= 1		; Uncomment this for pascal-style

IFDEF	L_PASCAL
	LANG	EQU	PASCAL
	MODEL TPASCAL
ELSE
	LANG	EQU	C
	MODEL LARGE,C
ENDIF

        INCLUDE "MODEL.INC"
        INCLUDE "MCP.INC"

STRUC	DMAPORT

	addr	DW ?
	count	DW ?
	page	DW ?
	wcntrl	DW ?
	wreq	DW ?
	wrsmr	DW ?
	wrmode	DW ?
	clear	DW ?
	wrclr	DW ?
	clrmask	DW ?
	wrall	DW ?
ENDS

DATASEG

	EXTRN	mcpStatus:BYTE
	EXTRN	bufferSize:WORD
	EXTRN	dataBuf:WORD
	EXTRN	SoundCard:CARDINFO

	DMApage		DB ?
	DMAoffset	DW ?
	ioPort		DW ?
	saveDMAvector	DD ?
	samplingRate	DW ?
	curDMA		DMAPORT <>

CODESEG

	PUBLIC	SDI_WSS

	copyrightText	DB "SDI for Windows Sound System v1.0 - (C) 1993 Otto Chrons",0,1Ah

	WSSnorm		CARDINFO <9,0,"Windows Sound System",530h,0,0,4000,48000,1,1,2>

	LABEL DMAports	DMAPORT

	    DMAPORT <0,1,87h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <2,3,83h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <4,5,81h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <6,7,82h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <0,0,0,0,0,0,0,0,0,0,0>
	    DMAPORT <0C4h,0C6h,8Bh,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>
	    DMAPORT <0C8h,0CAh,89h,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>
	    DMAPORT <0CCh,0CEh,8Ah,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>

	WSS_IRQ	DB 0,0,0,0,0,0,0,8h,0,10h,18h,20h,0,0,0,0
	WSS_DMA DB 1,2,0,3,0,0,0,0

	LABEL WSS_rates	WORD

	    DW 8000,0
	    DW 5513,1
	    DW 16000,2
	    DW 11025,3
	    DW 27429,4
	    DW 18900,5
	    DW 32000,6
	    DW 22050,7
	    DW 0,8
	    DW 37800,9
	    DW 0,0Ah
	    DW 44100,0Bh
	    DW 48000,0Ch
	    DW 33075,0Dh
	    DW 9600,0Eh
	    DW 6615,0Fh

	SoundDeviceWSS	SOUNDDEVICE < \
		far ptr initWSS,\
		far ptr initDMA,\
		far ptr initRate,\
		far ptr closeWSS,\
		far ptr closeDMA,\
		far ptr startVoice,\
		far ptr stopVoice,\
		far ptr pauseVoice,\
		far ptr resumeVoice\
		far ptr getDMApos,\
		far ptr speakerOn,\
		far ptr speakerOff\
		>

;/*************************************************************************
; *
; *	Function    :	void SDI_WSS(SOUNDDEVICE far *sdi);
; *
; *	Description :	Registers Windows Sound System as a sound device
; *
; *	Input       :	Pointer to SD structure
; *
; *	Returns     :	Fills SD structure accordingly
; *
; ************************************************************************/

PROC	SDI_WSS FAR USES di si,sdi:DWORD

	cld
	LESDI	[sdi]
	mov	si,offset SoundDeviceWSS
	mov	cx,SIZE SOUNDDEVICE
	cli
	segcs
	rep movsb			; Copy structure
	sti
	sub	ax,ax			; indicate successful init
	ret
ENDP

;/*************************************************************************
; *
; *	Function    : 	interruptDMA
; *
; *	Description :	DMA interrupt routine for continuos playing.
; *
;/************************************************************************/

PROC	NOLANGUAGE interruptDMA NEAR

	sti
	push	ax
	push	dx
	push	ds
	mov	ax,@data
	mov	ds,ax			; DS = data segment

	mov	al,[mcpStatus]
	and	al,111b
	cmp	al,111b			; Inited and playing
	jne	@@exit
	mov	dx,[ioPort]
	add	dx,6
	mov	al,0
	out	dx,al			; Acknowledge interrupt
@@exit:
	mov	al,20h			; End Of Interrupt (EOI)
	out	20h,al
	cmp	[SoundCard.dmaIRQ],7
	jle	@@10
	out	0A0h,al
@@10:
	pop	ds
	pop	dx
	pop	ax
	iret				; Interrupt return
ENDP


;/*************************************************************************
; *
; *	Function    : int initWSS(CARDINFO *scard);
; *
; *	Description : Initializes a WSS card.
; *
; *	Input       : Pointer to CARDINFO structure
; *
; *	Returns     : 0 no error
; *		      other = error
; *
; *************************************************************************/

PROC	initWSS FAR USES si di, scard:FAR PTR CARDINFO
	LOCAL	retvalue:WORD

	mov	[retvalue],-1
	LESSI	[scard]
	mov	al,[ESSI+CARDINFO.ID]
	mov	si,offset WSSnorm	; SI = source
	cmp	al,ID_WSS		; Check for valid ID
	jne	@@exit
@@idOK:
	mov	ax,ds
	mov	es,ax
	mov	di,offset SoundCard	; ES:DI = destination
	mov	cx,SIZE CARDINFO
	cld
	cli
	segcs
	rep	movsb			; Copy information
	sti

	LESSI	[scard]
	mov	ax,[ESSI+CARDINFO.ioPort]
	mov	[SoundCard.ioPort],ax
	mov	[ioPort],ax
	mov	al,[ESSI+CARDINFO.DMAIRQ]
	cmp	al,16 			; Is it > 15?
	jae	@@exit
	mov	[SoundCard.DMAIRQ],al
	mov	al,[ESSI+CARDINFO.DMAchannel]
	cmp	al,4			; Channel 4 is invalid
	je	@@exit
	cmp	al,8
	jae	@@exit			; So are > 7
	mov	[SoundCard.DMAchannel],al

	mov	bh,[ESSI+CARDINFO.stereo]
	cmp	bh,1
	ja	@@exit

	mov	bl,[ESSI+CARDINFO.sampleSize]

	mov	[SoundCard.sampleSize],bl	; Save values
	mov	[SoundCard.stereo],bh

	mov	bl,[ESSI+CARDINFO.DMAchannel]
	sub	bh,bh
	imul	bx,bx,SIZE DMAPORT
	lea	si,[bx+DMAports]	; SI = DMAports[DMAchannel]
	mov	ax,ds
	mov	es,ax
	mov	di,offset curDMA	; ES:DI = curDMA
	mov	cx,SIZE DMAPORT
	cli
	segcs
	rep	movsb			; Copy structure
	sti

	mov	dx,[ioPort]
	mov	bl,[SoundCard.DMAIRQ]
	sub	bh,bh
	mov	al,[WSS_IRQ+bx]
	mov	bl,[SoundCard.DMAchannel]
	or	al,[WSS_DMA+bx]
	out	dx,al			; Setup IRQ and DMA

	mov	al,[SoundCard.DMAIRQ]
	test	al,8			; Is IRQ > 7
	jz	@@01
	add	al,60h			; Yes, base is 70h
@@01:
	add	al,8			; AL = DMA interrupt number
	push	ax
	mov	ah,35h			; Get interrupt vector
	int	21h
	mov	[WORD LOW saveDMAvector],bx	; Save it
	mov	[WORD HIGH saveDMAvector],es
	pop	ax			; Replace vector with the address
	mov	ah,25h			; of own interrupt routine
	PUSHDS
	push	cs
	pop	ds
	mov	dx,offset interruptDMA	; Set interrupt vector
	int	21h
	pop	ds

	or	[mcpStatus],S_INIT	; indicate successful initialization
	mov	[retvalue],0
@@exit:
	mov	ax,[retvalue]
	ret
ENDP

;/***********************************************************************
; *
; *	Function    :	int getDMApos():
; *
; *	Description :	Returns the position of DMA transfer
; *
; **********************************************************************/

PROC	getDMApos FAR

	cli
@@05:
	mov	al,0FFh
	mov	dx,[curDMA.clear]
	out	dx,al
	mov	dx,[curDMA.count]
	in	al,dx
	mov	ah,al
	in	al,dx
	xchg	ah,al
	mov	bx,ax
	in	al,dx
	mov	ah,al
	in	al,dx
	xchg	ah,al
	sub	bx,ax
	cmp	bx,64
	jg	@@05
	cmp	bx,-64
	jl	@@05
	neg	ax
	cmp	[SoundCard.DMAChannel],4
	jb	@@dma8
	shl	ax,1			; 16-bit to 8-bit
@@dma8:
	add	ax,[bufferSize]		; AX = DMA position
	sti

	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	initDMA(void far *buffer,int maxsize, int required);
; *
; *	Description :   Init DMA for output
; *
; ************************************************************************/

PROC    initDMA FAR buffer:DWORD,linear:DWORD,maxSize:DWORD,required:DWORD

        mov     cx,[word maxSize]
	mov	[bufferSize],cx
	mov	ax,[WORD HIGH buffer]
	mov	bx,[WORD LOW buffer]
	add	bx,3
	and	bx,NOT 3
	mov	[dataBuf],bx		; Check if DMA buffers are on
	mov	eax,[linear]		; a segment boundary
	add	eax,3
	and	eax,NOT 3
	neg	ax
	cmp	ax,cx			; Is buffer size >= data size
	ja	@@bufOK
	dec	ax
	and	ax,NOT 3
	mov	[bufferSize],ax
	shr	cx,1
	cmp	ax,cx			; Is it even half of it?
	ja	@@bufOK
	shl	cx,1
	add	[dataBuf],ax
	add	[dataBuf],7
	and	[dataBuf],NOT 3
	neg	ax
	add	ax,cx			; AX = dataSize - AX
	sub	ax,32
	and	ax,NOT 3
	mov	[bufferSize],ax
@@bufOK:
	cmp	[required],0
	je	@@sizeok
        cmp     ax,[word required]
	jbe	@@sizeok
        mov     ax,[word required]
	mov	[bufferSize],ax
@@sizeok:
	and	[bufferSize],NOT 3
	sub	ebx,ebx
	mov	eax,[linear]		; Calculate DMA page and offset values
	mov	bx,[dataBuf]
	sub	bx,[WORD LOW buffer]	; Relative offset
	add	eax,ebx
	mov	ebx,eax
	shr	ebx,16
	cmp	[SoundCard.DMAChannel],4
	jb	@@8bitDMA
	push	bx
	shr	bl,1
	rcr	ax,1			; For word addressing
	pop	bx
@@8bitDMA:
	mov	[DMApage],bl
	mov	[DMAoffset],ax

	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	setSamplingRate
; *
; *	Description :	Sets closest sampling rate possible on WSS
; *
; *	Input       :	AX = rate wanted
; *
; *	Returns     :	AX = closest possible rate
; *
; ************************************************************************/

PROC	setSamplingRate NEAR USES si di
	LOCAL delta:WORD,realrate:WORD

	mov	cx,16			; 16 possible rates (actually 14)
	mov	[delta],32000		; Delta is very big in the beginning
	mov	si,0			; SI = closest match
	mov	di,ax			; DI = original rate
	sub	bx,bx			; BX = index
@@loop:
	mov	ax,di
	sub	ax,[bx+WSS_rates]
	cwd				; AX = abs(AX)
	xor	ax,dx
	sub	ax,dx
	cmp	ax,[delta]
	ja	@@next
	mov	[delta],ax		; New delta
	mov	si,[bx+WSS_rates+2]	; This position
	mov	ax,[bx+WSS_rates]
	mov	[realrate],ax
@@next:
	add	bx,4
	loop	@@loop

	mov	dx,[ioPort]
	add	dx,4
	mov	al,48h
	out	dx,al			; Mute on
	inc	dx
	mov	ax,si
	cmp	[SoundCard.stereo],1
	jne	@@mono
	or	al,010h			; Set stereo
@@mono:
	cmp	[SoundCard.sampleSize],1
	je	@@8bit
	or	al,040h			; Set 16-bit
@@8bit:
	out	dx,al			; Set CODEC format
	dec	dx
	mov	al,08h
	out	dx,al			; Mute off
	mov	ax,[realrate]
	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	initRate
; *
; *	Description :   Inits sound card's sampling rate
; *
; ************************************************************************/

PROC    initRate FAR USES di,sample_rate:DWORD

	sub	eax,eax
	mov	ax,[SoundCard.minRate]
        cmp     [word sample_rate],ax
	jae	@@rateok
        mov     [word sample_rate],ax
	jmp	@@rateok
	mov	ax,[SoundCard.maxRate]
        cmp     [word sample_rate],ax
	jbe	@@rateok
        mov     [word sample_rate],ax
@@rateok:
        mov     ax,[word sample_rate]
	call	setSamplingRate
	mov	[samplingRate],ax
@@exit:
	mov	ax,[samplingRate]
	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	speakerOn
; *
; *	Description :	Connects WSS speaker
; *
; ************************************************************************/

PROC	speakerOn FAR

	mov	dx,[ioPort]
	add	dx,4
	mov	al,07h
	out	dx,al			; Mute off
	inc	dx
	in	al,dx
	and	al,7Fh
	out	dx,al

	mov	dx,[ioPort]
	add	dx,4
	mov	al,06h
	out	dx,al			; Mute off
	inc	dx
	in	al,dx
	and	al,7Fh
	out	dx,al

	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	speakerOff
; *
; *	Description :	Disconnects speaker from WSS
; *
; ************************************************************************/

PROC	speakerOff FAR

	mov	dx,[ioPort]
	add	dx,4
	mov	al,07h
	out	dx,al			; Mute on
	inc	dx
	in	al,dx
	or	al,80h
	out	dx,al

	mov	dx,[ioPort]
	add	dx,4
	mov	al,06h
	out	dx,al			; Mute on
	inc	dx
	in	al,dx
	or	al,80h
	out	dx,al


	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	startVoice
; *
; *	Description :	Starts to output voice.
; *
; ************************************************************************/

PROC	startVoice FAR USES di

	mov	cl,[SoundCard.DMAIRQ]		; Enable DMA interrupt
	mov	ah,1
	test	cl,8
	jnz	@@10
	shl	ah,cl
	not	ah
	in	al,21h
	and	al,ah
	out	21h,al
	jmp	@@20
@@10:
	and	cl,7
	shl	ah,cl
	not	ah
	in	al,0A1h
	and	al,ah
	out	0A1h,al
@@20:
	cli
	mov	ah,[DMApage]		; Load correct DMA page and offset
	mov	bx,[DMAoffset]		; values
	mov	cx,[bufferSize]
	cmp	[SoundCard.DMAchannel],4
	jb	@@bufByte
	shr	cx,1			; Word count for 16-bit DMA
@@bufByte:
	dec	cx
	cli				; Set the DMA up and running
	mov	al,[SoundCard.DMAChannel]
	or	al,4
	mov	dx,[curDMA.wrsmr]
	out	dx,al			; Break On
	mov	al,[SoundCard.DMAChannel]
	and	al,3
	or	al,058h
	mov	dx,[curDMA.wrmode]
	out	dx,al
	mov	dx,[curDMA.page]
	mov	al,ah
	out	dx,al			; Page
	mov	al,0FFh
	mov	dx,[curDMA.clear]
	out	dx,al			; Reset counter

	mov	dx,[curDMA.addr]
	mov	al,bl
	out	dx,al			; Offset
	mov	al,bh
	out	dx,al

	mov	dx,[curDMA.count]
	mov	al,cl
	out	dx,al			; Count
	mov	al,ch
	out	dx,al
	mov	al,[SoundCard.DMAChannel]
	and	al,3
	mov	dx,[curDMA.wrsmr]
	out	dx,al			; Break Off
	sti

	mov	cx,60000		; Sample count
	mov	dx,[ioPort]
	add	dx,4
	mov	al,0Fh			; Low byte
	out	dx,al
	inc	dx
	mov	al,cl
	out	dx,al
	dec	dx
	mov	al,0Eh			; High byte
	out	dx,al
	inc	dx
	mov	al,ch
	out	dx,al

	mov	dx,[ioPort]
	add	dx,4
	mov	al,09h			; Interface configuration
	out	dx,al
	inc	dx
	mov	al,05h			; Use DMA playback
	out	dx,al
	dec	dx
	mov	al,0Ah			; PIN control register
	out	dx,al
	inc	dx
	mov	al,02h			; Turn on interrupts
	out	dx,al
@@exit:
	ret
ENDP


;/*************************************************************************
; *
; *	Function    :	stopVoice
; *
; *	Description :	Stops voice output.
; *
; ************************************************************************/

PROC	stopVoice FAR USES di

	cli
	mov	dx,[ioPort]
	mov	al,0Ah			; PIN control register
	out	dx,al
	inc	dx
	mov	al,0			; Turn off interrupts
	out	dx,al
	inc	dx
	out	dx,al			; Ack outstanding interrupts
	sub	dx,2
	mov	al,9			; Use Interface Configuration Reg.
	out	dx,al
	inc	dx
	mov	al,0
	out	dx,al			; Turn off CODEC's DMA

	mov	al,[SoundCard.DMAChannel] ; Reset DMA
	or	al,4
	mov	dx,[curDMA.wrsmr]
	out	dx,al
	mov	al,0FFh
	mov	dx,[curDMA.clear]
	out	dx,al
@@exit:
	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	closeDMA
; *
; *	Description :   Returns DMA's IRQ vector
; *
; ************************************************************************/

PROC closeDMA FAR
	PUSHDS
	mov	al,[SoundCard.DMAIRQ]
	test	al,8			; Is IRQ > 7
	jz	@@01
	add	al,60h			; Yes, base is 70h
@@01:
	add	al,8
	mov	dx,[WORD LOW saveDMAvector]
	mov	ds,[WORD HIGH saveDMAvector]
	mov	ah,25h
	int	21h			; Restore DMA vector
	POPDS
	ret
ENDP

PROC closeWSS FAR
	ret
ENDP

PROC pauseVoice FAR
	ret
ENDP

PROC resumeVoice FAR
	ret
ENDP


END
