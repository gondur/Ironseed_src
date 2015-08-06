;/************************************************************************
; *
; *	File	    : SDI_PAS.ASM
; *
; *	Description : SDI for MediaVision cards
; *
; *	Copyright (C) 1993 Otto Chrons
; *
; ***********************************************************************
;
;	Revision history of SDI_PAS.ASM
;
;	1.0	16.4.93
;		First version. Works with all PAS cards. There were some
;		troubles with 8-bit DMA but they are now fixed.
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
        MASM
	QUIRKS
	INCLUDE COMMON.INC
	INCLUDE STATE.INC
	INCLUDE MASM.INC
	IDEAL
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
;
; This pointer points to a state table of hardware variables
;
	mvhwShadowPointer	DD	?	; points to the start of the data table

	HardwareShadowTable	DB	(size MVState) dup (?)


CODESEG

	PUBLIC	SDI_PAS

	copyrightText	DB "SDI for PAS,PAS+ and PAS 16 v1.0 - (C) 1993 Otto Chrons",0,1Ah

	PASnorm 	CARDINFO <3,0,"Pro Audio Spectrum",388h,0,0,3000,44100,1,1,1>
	PASplus		CARDINFO <4,0,"Pro Audio Spectrum+",388h,0,0,3000,44100,1,1,1>
	PAS16		CARDINFO <5,0,"Pro Audio Spectrum 16",388h,0,0,3000,44100,1,1,2>

	LABEL DMAports	DMAPORT

	    DMAPORT <0,1,87h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <2,3,83h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <4,5,81h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <6,7,82h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <0,0,0,0,0,0,0,0,0,0,0>
	    DMAPORT <0C4h,0C6h,8Bh,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>
	    DMAPORT <0C8h,0CAh,89h,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>
	    DMAPORT <0CCh,0CEh,8Ah,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>

	SoundDevicePAS	SOUNDDEVICE < \
		far ptr initPAS,\
		far ptr initDMA,\
		far ptr initRate,\
		far ptr closePAS,\
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
; *	Function    :	void SDI_PAS(SOUNDDEVICE far *sdi);
; *
; *	Description :	Registers Pro Audio Spectrum as a sound device
; *
; *	Input       :	Pointer to SD structure
; *
; *	Returns     :	Fills SD structure accordingly
; *
; ************************************************************************/

PROC	SDI_PAS FAR USES di si,sdi:DWORD

	cld
	LESDI	[sdi]
	mov	si,offset SoundDevicePAS
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
; *	Function    :	playDMA
; *
; *	Description :	Plays current buffer through DMA
; *
; ************************************************************************/

PROC	playDMA NEAR

	PUSHES
	push	di

	mov	ax,60000
MASM
	LESDI	[mvhwShadowPointer]

	push	ax

	disable

	mov     al,01110100b            ; 74h Timer 1 & rate generator
	mov	dx,TMRCTLR
	xor	dx,[ioPort]		; xlate the board address


	out     dx,al
	mov	[ESDI._tmrctlr],al	; local timer control register

	pop	ax

	mov     dx,SAMPLECNT
	xor	dx,[ioPort]		; xlate the board address
	mov	[ESDI._samplecnt],ax

	out     dx,al
	pause
	xchg	ah,al
	out	dx,al

	enable
IDEAL
@@exit:
	pop	di
	POPES

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

;	sti
;	push	ax
;	push	dx
;	push	ds
;	mov	ax,@data
;	mov	ds,ax			; DS = data segment
;
;	mov	dx,INTRCTLRST		; clear the interrupt
;	xor     dx,[ioPort]		; xlate the board address
;	in	al,dx
;
;	cmp	[mcpStatus],111b	; Inited and playing
;	jne	@@exit
;	call	playDMA			; Output current buffer
;@@exit:
;	mov	al,20h			; End Of Interrupt (EOI)
;	out	20h,al
;	cmp	[SoundCard.dmaIRQ],7
;	jle	@@10
;	out	0A0h,al
;@@10:
;	pop	ds
;	pop	dx
;	pop	ax
	iret				; Interrupt return
ENDP


;/*************************************************************************
; *
; *	Function    : calcsamplerate
; *
; *	Description : Calculates new sampling rate
; *
; *	Input       : EAX sampling rate
; *
; ************************************************************************/

PROC	calcsamplerate NEAR
MASM
	push	es
	push	di
	LESDI	[mvhwShadowPointer]

;
; make sure sample rate does not exceed 88200
;
	mov	ecx,eax
	cmp	ecx,88200
	ja	CaSaRa_bad
;
; load 1193180 in bx:cx for 32x32 bit division
;
	mov	eax,001234DCh
	sub	edx,edx
	div	ecx
	mov	[ESDI._samplerate],ax	; save just the low order
	sub	ecx,ecx
	mov	cx,ax
	mov	eax,001234DCh
	sub	edx,edx
	div	ecx
	jmp	short CaSaRa_exit
;
CaSaRa_bad:
;
CaSaRa_exit:

	pop     di
	pop	es
	ret
IDEAL
ENDP

;/*************************************************************************
; *
; *	Function    : int initPAS(CARDINFO *scard);
; *
; *	Description : Initializes a PAS card.
; *
; *	Input       : Pointer to CARDINFO structure
; *
; *	Returns     : 0 no error
; *		      other = error
; *
; *************************************************************************/

PROC	initPAS FAR USES si di, scard:FAR PTR CARDINFO
	LOCAL	retvalue:WORD

	mov	[retvalue],-1
	les	si,[scard]
	mov	al,[ESSI+CARDINFO.ID]
	mov	si,offset PASnorm	; SI = source
	cmp	al,ID_PAS		; Check for valid ID
	je	@@idOK
	mov	si,offset PASplus	; SI = source
	cmp	al,ID_PASPLUS
	je	@@idOK
	mov	si,offset PAS16		; SI = source
	cmp	al,ID_PAS16
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

	les	si,[scard]
	mov	ax,[ESSI+CARDINFO.ioPort]
	mov	[SoundCard.ioPort],ax
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
MASM
;
; setup a pointer to our local hardware state table
;
	lea	bx,[HardwareShadowTable]
	mov	wptr [mvhwShadowPointer+0],bx
	mov	wptr [mvhwShadowPointer+2],ds
	push	ds
	pop	es
	mov	di,bx
	mov	cx,SIZE MVState		; Clear state table
	sub	al,al
	rep	stosb
	mov	[bx._crosschannel],9	; cross channel l-2-l, r-2-r
	mov	[bx._audiofilt],31h	; lowest filter setting
;
; find the int 2F interface and if found, use it's state table pointer

	mov	ax,0BC00h		; MVSOUND.SYS ID check
	mov	bx,'??'
	sub	cx,cx
	sub	dx,dx

	int	2fh			; will return something if loaded

	xor	bx,cx
	xor	bx,dx
	cmp	bx,'MV'                 ; is the int 2F interface here?
	jnz	imvsp_done		; no, exit home

	mov	ax,0BC02H		; get the pointer
	int     2fh
	cmp	ax,'MV'                 ; busy or intercepted
	jnz	imvsp_done

	mov	wptr [mvhwShadowPointer+0],bx
	mov	wptr [mvhwShadowPointer+2],dx

imvsp_done:
IDEAL

	mov	dx,[SoundCard.ioPort]
	xor	dx,DEFAULT_BASE
	mov	[ioPort],dx

	mov	dx,INTRCTLRST			; flush any pending PCM irq
	xor	dx,[ioPort]			; xlate the board address
	out	dx,al

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

PROC	initDMA FAR buffer:DWORD,linear:DWORD,maxSize:DWORD,required:DWORD

	mov	cx,[word maxSize]
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
	cmp	ax,[word required]
	jbe	@@sizeok
	mov	ax,[word required]
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
; *	Function    :	initRate
; *
; *	Description :   Inits sound card's sampling rate
; *
; ************************************************************************/

PROC	initRate FAR USES di,sample_rate:DWORD

	sub	eax,eax
	mov	ax,[SoundCard.minRate]
	cmp	[word sample_rate],ax
	jae	@@rateok
	mov	[word sample_rate],ax
	jmp	@@rateok
	mov	ax,[SoundCard.maxRate]
	cmp	[word sample_rate],ax
	jbe	@@rateok
	mov	[word sample_rate],ax
@@rateok:
	mov	ax,[word sample_rate]
	cmp	[SoundCard.stereo],0
	je	@@mono
	shl	eax,1
@@mono:
	call	calcsamplerate
	mov	cl,[SoundCard.stereo]
	shr	eax,cl
	mov	[samplingRate],ax
MASM
	les     di,[mvhwShadowPointer]
	mov     al,00110110b            ; 36h Timer 0 & square wave
	mov	dx,TMRCTLR
	xor	dx,[ioPort]		; xlate the board address

	cli

	out	dx,al			; setup the mode, etc
	mov     [ESDI._tmrctlr],al

	mov	ax,[ESDI._samplerate]	; pre-calculated & saved in prior code
	mov	dx,SAMPLERATE
	xor	dx,[ioPort]		; xlate the board address
	out	dx,al			; output the timer value

	pause

	xchg    ah,al
	out	dx,al
	sti
IDEAL
@@exit:
	movzx	eax,[samplingRate]
	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	speakerOn
; *
; *	Description :	Connects PAS speaker
; *
; ************************************************************************/

PROC	speakerOn FAR

	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	speakerOff
; *
; *	Description :	Disconnects speaker from PAS
; *
; ************************************************************************/

PROC	speakerOff FAR

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
IF 0
	mov	ah,[DMApage]		; Load correct DMA page and offset
	mov	bx,[DMAoffset]		; values
	mov	cx,[bufferSize]
	cmp	[SoundCard.DMAchannel],4
	jb	@@bufByte2
	shr	cx,1			; Word count for 16-bit DMA
@@bufByte2:
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
ENDIF

	les     di,[mvhwShadowPointer]
	cmp	[SoundCard.sampleSize],2
	jne	@@no16bit
	mov	cx,(((NOT(bSC216bit+bSC212bit) AND 0FFh)*256) + bSC216bit)
	mov	dx,SYSCONFIG2
	xor	dx,[ioPort]		; xlate the board address
	in	al,dx
	and	al,ch			; clear the bits
	or	al,cl			; set the appropriate bits
	out	dx,al
@@no16bit:
	mov	al,bCCmono		; get the stereo/mono mask bit
	cmp	[SoundCard.stereo],0
	je	@@mono
	sub	al,al
@@mono:
	or	al,bCCdac		; get the direction bit mask
	or	al,bCCenapcm		; enable the PCM state machine
	mov     dx,CROSSCHANNEL
	xor	dx,[ioPort]	; xlate the board address

MASM
	mov	ah,0fh + bCCdrq 	; get a mask to load non PCM bits
	and	ah,[ESDI._crosschannel]; grab all but PCM/DRQ/MONO/DIRECTION
	or	al,ah			; merge the two states
	xor	al,bCCenapcm		; disable the PCM bit
	out	dx,al			; send to the hardware
	pause
	xor	al,bCCenapcm		; enable the PCM bit
	out	dx,al			; send to the hardware
	mov	[ESDI._crosschannel],al; and save the new state
;
; Setup the audio filter sample bits
;
	mov	al,[ESDI._audiofilt]
	or	al,(bFIsrate+bFIsbuff)	; enable the sample count/buff counters
	mov	dx,AUDIOFILT
	xor	dx,[ioPort]	; xlate the board address
	out	dx,al
	mov	[ESDI._audiofilt],al

	mov	al,[ESDI._crosschannel]; get the state
	mov     dx,CROSSCHANNEL
	xor     dx,[ioPort]		; xlate the board address
	or	al,bCCdrq		; set the DRQ bit to control it
	out	dx,al
	mov	[ESDI._crosschannel],al; and save the new state
IDEAL
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


MASM
	LESDI	[mvhwShadowPointer]
;
; clear the audio filter sample bits
;
	mov	dx,AUDIOFILT
	xor	dx,[ioPort]	; xlate the board address
	disable 			; drop dead...
	mov	al,[ESDI._audiofilt]	; get the state
	and	al,not (bFIsrate+bFIsbuff) ; flush the sample timer bits
	mov	[ESDI._audiofilt],al	; save the new state
	out	dx,al
IDEAL
;	mov	cx,0
@@wait:
;	loop	@@wait
	mov	al,[SoundCard.DMAChannel] ; Reset DMA
	or	al,4
	mov	dx,[curDMA.wrsmr]
	out	dx,al
	mov	al,0
	mov	dx,[curDMA.clear]
	out	dx,al

	cmp	[SoundCard.ID],ID_PAS16
	jne	@@no16bit
;
; disable the 16 bit stuff
;
	mov	dx,SYSCONFIG2
	xor	dx,[ioPort]	   ; xlate the board address
	in	al,dx
	and	al,not bSC216bit+bSC212bit ; flush the 16 bit stuff
	out	dx,al
;
@@no16bit:
MASM
stpc02:
;
; clear the appropriate Interrupt Control Register bit
;
	mov	ah,bICsampbuff
	and	ah,bICsamprate+bICsampbuff
	not	ah
	mov	dx,INTRCTLR
	xor	dx,[ioPort]	; xlate the board address
	in	al,dx
	and	al,ah			; kill sample timer interrupts
	out	dx,al
	mov	[ESDI._intrctlr],al

	mov     al,[ESDI._crosschannel]; get the state
	mov     dx,CROSSCHANNEL
	xor     dx,[ioPort]		; xlate the board address
	and	al,not bCCdrq		; clear the DRQ bit
	and	al,not bCCenapcm	; clear the PCM enable bit
	or	al,bCCdac
	out	dx,al

	mov     [ESDI._crosschannel],al; and save the new state
IDEAL
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
	ret
ENDP

PROC closePAS FAR
	ret
ENDP

PROC pauseVoice FAR
	ret
ENDP

PROC resumeVoice FAR
	ret
ENDP


END
