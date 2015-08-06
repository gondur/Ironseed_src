;/************************************************************************
; *
; *	File        :	SDI_SB16.ASM
; *
; *	Description :	Sound Blaster 16 specific routines for MCP
; *
; *	Copyright (C) 1993 Otto Chrons
; *
; ***********************************************************************
;
;	Revision history of SDI_SB16.ASM
;
;	1.0	16.4.93
;		First version. SB 16 routines. Works with 8- and 16-bit DMA
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
	saveDMAvector	DD ?
	samplingRate	DW ?
	curDMA		DMAPORT <>

CODESEG

	PUBLIC	SDI_SB16

	copyrightText	DB "SDI for SB16 v1.0 - (C) 1993 Otto Chrons",0,1Ah

	SoundBlaster16	CARDINFO <6,0,"Sound Blaster 16 ASP",220h,5,5,4000,44100,1,1,2>

	LABEL DMAports	DMAPORT

	    DMAPORT <0,1,87h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <2,3,83h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <4,5,81h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <6,7,82h,8,9,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh>
	    DMAPORT <0,0,0,0,0,0,0,0,0,0,0>
	    DMAPORT <0C4h,0C6h,8Bh,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>
	    DMAPORT <0C8h,0CAh,89h,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>
	    DMAPORT <0CCh,0CEh,8Ah,0D0h,0D2h,0D4h,0D6h,0D8h,0DAh,0DCH,0DEh>

	SoundDeviceSB16	SOUNDDEVICE < \
		far ptr initSB16,\
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

;/*************************************************************************
; *
; *	Function    :	void SDI_SB16(SOUNDDEVICE far *sdi);
; *
; *	Description :	Registers SB as a sound device
; *
; *	Input       :	Pointer to SD structure
; *
; *	Returns     :	Fills SD structure accordingly
; *
; ************************************************************************/

PROC	SDI_SB16 FAR USES di si,sdi:DWORD

	cld
	LESDI	[sdi]
	mov	si,offset SoundDeviceSB16
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
; *	Function    :	cmdSB
; *
; *	Description :   Sends a command to Sound Blaster
; *
; *	Input       :	AL = Command to send
; *
; ************************************************************************/

PROC	cmdSB NEAR

	push	cx
	mov	cx,65535
	push	ax
	mov	dx,[SoundCard.ioPort]
	add	dl,0Ch
@@1:
	in	al,dx
	or	al,al
	jns	@@2
	loop	@@1
@@2:
	pop	ax
	out	dx,al
	pop	cx

	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	playDMA
; *
; *	Description :	Plays current buffer through DMA
; *
; ************************************************************************/

PROC	playDMA NEAR USES cx

	mov	cx,60000
	mov	al,0B6h			; SB's command for 16 bit stereo output
	call	cmdSB
	mov	al,10h
	cmp	[SoundCard.stereo],0
	je	@@mono
	or	al,20h
@@mono:
	call	cmdSB
	mov	al,cl			; Count
	call	cmdSB
	mov	al,ch
	call	cmdSB
@@exit:
	ret
ENDP

;/*************************************************************************
; *
; *	Function    : 	interruptDMA
; *
; *	Description :	DMA interrupt routine for continuos playing.
; *
; ************************************************************************/

PROC	NOLANGUAGE interruptDMA FAR

	cli
	push	ax
	push	dx
	push	ds
	mov	ax,@data
	mov	ds,ax			; DS = data segment

	mov	al,[mcpStatus]
	and	al,111b
	cmp	al,111b			; Inited and playing
	jne	@@exit
	mov	dx,[SoundCard.ioPort]
	add	dx,4
	mov	al,82h
	out	dx,al
	inc	dx
	in	al,dx
	test	al,1
	jz	@@exit
	test	al,2
	jz	@@exit
	mov	al,0D9h
	call	cmdSB
	mov	al,0D5h
	call	cmdSB
	call	playDMA
@@exit:
	mov	dx,[SoundCard.ioPort]	; Reset SB for next DMA
	add	dl,0Fh
	in	al,dx
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
; *	Function    : 	checkPort_SB
; *
; *	Description :   Checks if given address is SB's I/O address
; *
; *	Input       : 	DX = port to check
; *
; *	Returns     :	AX = 0	succesful
; *		      	AX = 1	unsuccesful
; *
; ************************************************************************/

PROC	NOLANGUAGE checkPort_SB NEAR

	push	dx
	add	dl,6			; Init Sound Blaster
	mov	al,1
	out	dx,al
	in	al,dx			; Wait for awhile
	in	al,dx
	in	al,dx
	in	al,dx
	in	al,dx
	mov	al,0
	out	dx,al
	sub	dl,6

	add	dl,0Eh          	; DSP data available status
	mov	cx,1000
@@loop:
	in	al,dx			; port 22Eh
	or	al,al
	js	@@10
	loop	@@loop

	mov	ax,1
	jmp	@@exit
@@10:
	sub	dl,4
	in	al,dx			; port 22Ah
	cmp	al,0AAh			; Is ID 0AAh?
	mov	ax,0
	je	@@exit
	mov	ax,1
@@exit:
	pop	dx
	or	ax,ax			; Set zero-flag accordingly
	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	int getDMApos():
; *
; *	Description :	Returns the position of DMA transfer
; *
; ************************************************************************/

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
; *	Function    :	int initSB16(CARDINFO *sCard);
; *
; *	Description : 	Initializes Sound Blaster 16 using values for
; *		      	ioPort,dmaIRQ & dmaChannel in sCard
; *
; *	Input       : 	sCard   = pointer to CARDINFO-structure
; *
; *	Returns     : 	 0	= success
; *			-1	= error
; *
; ************************************************************************/

PROC	initSB16 FAR USES di si,sCard:DWORD
	local	retryCount:WORD,retvalue:WORD

	LESSI	[sCard]
	mov	[retvalue],-1		; assume error
	mov	dx,[ESSI+CARDINFO.ioPort]
	cmp	dx,220h			; check for valid addresses
	je	@@OK
	cmp	dx,240h			; check for valid addresses
	je	@@OK
	cmp	dx,260h			; check for valid addresses
	je	@@OK
	cmp	dx,280h
	jne	@@exit
@@OK:
	cmp	[ESSI+CARDINFO.DMAIRQ],2	; check for legal interrupt values
	je	@@DMA_OK
	cmp	[ESSI+CARDINFO.DMAIRQ],5
	je	@@DMA_OK
	cmp	[ESSI+CARDINFO.DMAIRQ],7
	je	@@DMA_OK
	cmp	[ESSI+CARDINFO.DMAIRQ],10
	jne	@@exit
@@DMA_OK:
	cmp	[ESSI+CARDINFO.DMAChannel],0	; check for legal channel values
	je	@@channelOK
	cmp	[ESSI+CARDINFO.DMAChannel],1
	je	@@channelOK
	cmp	[ESSI+CARDINFO.DMAChannel],3
	je	@@channelOK
	cmp	[ESSI+CARDINFO.DMAChannel],5
	je	@@channelOK
	cmp	[ESSI+CARDINFO.DMAChannel],6
	je	@@channelOK
	cmp	[ESSI+CARDINFO.DMAChannel],7
	jne	@@exit
@@channelOK:
	mov	si,offset SoundBlaster16	; DS:SI = source
	mov	ax,ds
	mov	es,ax
	mov	di,offset SoundCard	; ESDI = destination
	mov	cx,SIZE CARDINFO
	cld
	cli
	segcs
	rep	movsb			; Copy information
	sti

	LESSI	[sCard]
	mov	bl,[ESSI+CARDINFO.DMAchannel]
	sub	bh,bh
	imul	bx,SIZE DMAPORT
	lea	si,[bx+DMAports]	; SI = DMAports[DMAchannel]
	mov	ax,ds
	mov	es,ax
	mov	di,offset curDMA	; ESDI = curDMA
	mov	cx,SIZE DMAPORT
	cli
	segcs
	rep	movsb			; Copy structure
	sti

	LESSI	[sCard]
	mov	bx,[ESSI+CARDINFO.ioPort]
	mov	[SoundCard.ioPort],bx
	mov	bl,[ESSI+CARDINFO.DMAIRQ]
	mov	[SoundCard.DMAIRQ],bl
	mov	bl,[ESSI+CARDINFO.DMAChannel]
	mov	[SoundCard.DMAchannel],bl
	mov	bl,[ESSI+CARDINFO.stereo]
	mov	[SoundCard.stereo],bl

	mov	dx,[SoundCard.ioPort]	; initialize Sound Blaster
	call	checkPort_SB

	mov	[retrycount],10
@@retry:
	dec	[retrycount]
	jnz	@@continue
	mov	ax,0			; not found
	jmp	@@done
@@continue:
	mov	al,0E1h			; Read version number
	call	cmdSB

	add	dl,2			; DX = 22Eh
	sub	al,al
	mov	cx,1000
@@10:
	in	al,dx			; Read version high
	or	al,al
	js	@@10ok
	loop	@@10
	jmp	@@retry
@@10ok:
	mov	cx,1000
	sub	dl,4
	in	al,dx
	mov	ah,al

	add	dl,4
	sub	al,al
@@20:
	in	al,dx			; Read version low
	or	al,al
	js	@@20ok
	loop	@@20
	jmp	@@retry
@@20ok:
	sub	dl,4
	in	al,dx
@@done:
	cmp	ax,0400h		; Is version 4.00 or higher?
	jl	@@exit			; No --> exit

	mov	dx,[SoundCard.ioPort]	; initialize Sound Blaster
	add	dx,6
	mov	al,1
	out	dx,al
	in	al,dx			; Wait for awhile
	in	al,dx
	in	al,dx
	in	al,dx
	in	al,dx
	mov	al,0
	out	dx,al


	or	[mcpStatus],S_INIT	; indicate successful initialization
	mov	[retvalue],0		; return 0 = OK
@@exit:
	mov	ax,[retvalue]
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

	; Init DMA

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

	mov	cl,[SoundCard.DMAIRQ]
	mov	ah,1
	test	cl,8			; Is IRQ > 7
	jnz	@@15
	shl	ah,cl
	not	ah
	in	al,21h
	and	al,ah
	out	21h,al			; Allow DMA interrupt
	jmp	@@20
@@15:
	and	cl,7
	shl	ah,cl
	not	ah
	in	al,0A1h
	and	al,ah
	out	0A1h,al			; Allow DMA interrupt
@@20:
	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	initRate
; *
; *	Description :   Inits sound card's sampling rate
; *
; ************************************************************************/

PROC    initRate FAR sample_rate:DWORD

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
	mov	eax,0F4240h		; Calculate sampling rate for SB
	sub	edx,edx			; EDX:EAX = 256000000
        movzx   ecx,[word sample_rate]
	div	ecx
	sub	ecx,ecx
	mov	cx,ax			; Calculate real sampling rate
	mov	eax,0F4240h
	sub	edx,edx
	div	ecx			; Save sampling rate into AX
	push	ax
	mov	cx,ax
	mov	al,42h			; Set SB's sampling rate
	call	cmdSB
	mov	al,ch
	call	cmdSB
	mov	al,cl
	call	cmdSB
	pop	ax
@@exit:
	mov	[samplingRate],ax	; and save it for future use
	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	speakerOn
; *
; *	Description :	Connects SB's Digital Signal Processor to speaker
; *
; ************************************************************************/

PROC	speakerOn FAR

	mov	al,0D1h
	call	cmdSB
	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	speakerOff
; *
; *	Description :	Disconnects speaker from DSP
; *
; ************************************************************************/

PROC	speakerOff FAR

	mov	al,0D3h
	call	cmdSB
	ret
ENDP

;/*************************************************************************
; *
; *	Function    :	startVoice
; *
; *	Description :	Starts to output voice.
; *
; ************************************************************************/

PROC	startVoice FAR

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
	or	al,58h
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

	call	playDMA
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

PROC	stopVoice FAR

	cli
	mov	dx,[SoundCard.ioPort]
	add	dl,6			; Init Sound Blaster
	mov	al,1
	out	dx,al
	in	al,dx			; Wait for awhile
	in	al,dx
	in	al,dx
	in	al,dx
	in	al,dx
	in	al,dx
	in	al,dx
	in	al,dx
	mov	al,0
	out	dx,al

	mov	dx,[SoundCard.ioPort]
	add	dx,0Eh
	in	al,dx

	mov	cl,[SoundCard.DMAIRQ]		; Disable DMA interrupt
	mov	ah,1
	test	cl,8
	jnz	@@10
	shl	ah,cl
	in	al,21h
	or	al,ah
	out	21h,al
	jmp	@@20
@@10:
	and	cl,7
	shl	ah,cl
	in	al,0A1h
	or	al,ah
	out	0A1h,al
@@20:
	mov	al,[SoundCard.DMAChannel] ; Reset DMA
	or	al,4
	mov	dx,[curDMA.wrsmr]
	out	dx,al
	mov	al,0
	mov	dx,[curDMA.clear]
	out	dx,al

	sti

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

PROC closeSB FAR
	ret
ENDP

PROC pauseVoice FAR
;	mov	al,0D0h
;	call	cmdSB
	ret
ENDP

PROC resumeVoice FAR
;	mov	al,0D4h
;	call	cmdSB
	ret
ENDP

END
