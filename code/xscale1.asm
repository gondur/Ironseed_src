;=========================================================================
; XSCALE1.ASM by John A. Slagel, jas37876@uxa.cso.uiuc.edu
; This is some code to do bitmap scaling in VGA Mode X.  It can scale a
; bitmap of any size down to 2 pixels wide, or up to thousands of pixels
; wide.  It performs complete clipping, with only a small constant amount
; of time to clip, no matter how huge the image is.  It draws column by
; column to reduce the number of plane switches, which are slow. The inner
; column loop has been optimized for no memory accesses, except to read or
; write a pixel.  This uses MASM 5.1 features, and can be compiled in any
; memory model by changing the .MODEL line, but make sure that you always
; pass a far pointer to the bitmap data, regardless of memory model.
; C-callable as:
;   void XSCALE1( int X, int Y, int DW, int DY,
;                     int SW, int SH, void far * Bitmap );
; X,Y   are the upper left-hand coordinates of where to draw the bitmap.
; DW,DH are the width and height of the SCALEed bitmap
; SW,SH are the width and height of the source bitmap.
; Bitmap is a pointer to the bitmap bits.
;
;==========================================================================

MASM51

.MODEL LARGE, PASCAL
.386

.DATA
SC_INDEX1   EQU 03C4h               ; Port number of VGA Sequencer Reg
SC_INDEX2   EQU 03C5h               ; Port number of VGA Seqeuncer Data
MAP_MASK    EQU 2                   ; Map Mask register index into Sequencer

ClipLt      DW  1                  ; Left clipping boundry
ClipRt      DW  319                 ; Right clipping boundry
ClipTp      DW  1                  ; Top clipping boundry
ClipBt      DW  399                 ; Bottom clipping boundry
ModeXseg    DW  0A000h              ; Current VGA segment

.CODE

XSCALE1 PROC FAR USES DS DI SI, DestX:WORD, DestY:WORD,                 \
                                    DestWidth:WORD, DestHeight:WORD,        \
                                    SourceWidth:WORD, SourceHeight:WORD,    \
                                    Bitmap:NEAR PTR, PageAddr:WORD
LOCAL   DecisionX:WORD, DecisionY:WORD, ClippedWidth:WORD, ClippedHeight:WORD

PUBLIC XSCALE1
        cmp     DestWidth, 2        ; If destination width is less than 2
        jl      Done                ;     then don't draw it.

        cmp     DestHeight, 2       ; If destination height is less than 2
        jl      Done                ;     then don't draw it.

        mov     ax, DestY           ; If it is completely below the
        cmp     ax, ClipBt          ; lower clip bondry,
        jg      Done                ;     then don't draw it.

        add     ax, DestHeight      ; If it is above clip boundries
        dec     ax                  ;     then don't draw it.
        cmp     ax, ClipTp
        jl      Done

        mov     ax, DestX           ; If it is to the right of the
        mov     cx, ClipRt          ; right clip boundry
        cmp     ax, ClipRt          ;     then don't draw it.
        jg      Done

        add     ax, DestWidth       ; If it is completely to the left
        dec     ax                  ; of the left clip boundry,
        cmp     ax, ClipLt          ;     then don't draw it.
        jl      Done

        les     si, Bitmap

        mov     ax, DestWidth       ; ClippedWidth is initially set to
        mov     ClippedWidth, ax    ; the requested dest width.

        shl     ax,1                ; Initialize the X decision var
        neg     ax                  ; to be -2*DestWidth
        mov     DecisionX, ax       ;

        mov     ax, DestHeight      ; ClippedHeight is initially set to
        mov     ClippedHeight, ax   ; the requested dest size.

        shl     ax,1                ; Initialize the Y decision var
        neg     ax                  ; to be -2*DestHeight
        mov     DecisionY, ax       ;

        movsx   eax, ClipTp         ; If Y is below the top
        mov     edx, eax            ; clipping boundry, then we don't
        sub     dx, DestY           ; need to clip the top, so we can
        js      NoTopClip           ; jump over the clipping stuff.

        mov     DestY, ax           ; This block performs clipping on the
        sub     ClippedHeight, dx   ; top of the bitmap.  I have heavily
        movsx   ecx, SourceHeight   ; optimized this block to use only 4
        imul    ecx, edx            ; 32-bit registers, so I'm not even
        mov     eax, ecx            ; gonna try to explain what it's doing.
        mov     edx, 0              ; But I can tell you what results from
        movsx   ebx, DestHeight     ; this:  The DecisionY var is updated
        idiv    ebx                 ; to start at the right clipped row.
        movsx   edx, SourceWidth    ; Y is moved to the top clip
        imul    edx, eax            ; boundry. ClippedHeight is lowered since
        add     si, dx              ; we won't be drawing all the requested
        imul    eax, ebx            ; rows.  SI is changed to point over
        sub     ecx, eax            ; the bitmap data that is clipped off.
        sub     ecx, ebx            ;
        shl     ecx, 1              ;
        mov     DecisionY, cx       ; <end of top clipping block >

NoTopClip:
        mov     ax, DestY           ; If the bitmap doesn't extend over the
        add     ax, ClippedHeight   ; bottom clipping boundry, then we
        dec     ax                  ; don't need to clip the bottom, so we
        cmp     ax, ClipBt          ; can jump over the bottom clip code.
        jle     NoBottomClip        ;

        mov     ax, ClipBt          ; Clip off the bottom by reducing the
        sub     ax, DestY           ; ClippedHeight so that the bitmap won't
        inc     ax                  ; extend over the lower clipping
        mov     ClippedHeight, ax   ; boundry.

NoBottomClip:
        movsx   eax, ClipLt         ; If X is to the left of the
        mov     edx, eax            ; top clipping boundry, then we don't
        sub     dx, DestX           ; need to clip the left, so we can
        js      NoLeftClip          ; jump over the clipping stuff.

        mov     DestX, ax           ; This block performs clipping on the
        sub     ClippedWidth, dx    ; left of the bitmap.  I have heavily
        movsx   ecx, SourceWidth    ; optimized this block to use only 4
        imul    ecx, edx            ; 32-bit registers, so I'm not even
        mov     eax, ecx            ; gonna try to explain what it's doing.
        mov     edx, 0              ; But I can tell you what results from
        movsx   ebx, DestWidth      ; this:  The DecisionX var is updated
        idiv    ebx                 ; to start at the right clipped column.
        add     si, ax              ; X is moved to the left clip
        imul    eax, ebx            ; boundry. ClippedWidth is reduced since
        sub     ecx, eax            ; we won't be drawing all the requested
        sub     ecx, ebx            ; cols.  SI is changed to point over
        shl     ecx, 1              ; the bitmap data that is clipped off.
        mov     DecisionX, cx       ; <end of left clipping block >

NoLeftClip:
        mov     ax, DestX           ; If the bitmap doesn't extend over the
        add     ax, ClippedWidth    ; right clipping boundry, then we
        dec     ax                  ; don't need to clip the right, so we
        cmp     ax, ClipRt          ; can jump over the right clip code.
        jle     NoClipRight         ;

        mov     ax, ClipRt          ; Clip off the right by reducing the
        sub     ax, DestX           ; ClippedWidth so that the bitmap won't
        inc     ax                  ; extend over the right clipping
        mov     ClippedWidth, ax    ; boundry.

        ;Calculate starting video address
NoClipRight:
        mov     ax, ModeXseg        ; We are going to set DS:DI to point
        mov     ds, ax              ; to the place to start drawing in
        mov     di, DestY           ; VGA memory. This code sets DS to the
        imul    di, 80              ; VGA segment, which is usually at
        mov     ax, DestX           ; segment 0A000. The offset DI is
        mov     cx, ax              ; calculated by:
        shr     ax, 2               ;     DI = Y*80+X/2
        add     di, ax              ; DS:DI is ready!
        add     di, PageAddr
        mov     dx, SC_INDEX1       ; Point the VGA Sequencer to the Map
        mov     al, MAP_MASK        ; Mask register, so that we only need
        out     dx, al              ; to send out 1 byte per column.

        inc     dx                  ; Move to the Sequencer's Data register.
        and     cx, 3               ; Calculate the starting plane. This is
        mov     al, 11h             ; just:
        shl     al, cl              ; Plane =  (11h << (X AND 3))
        out     dx, al              ; Select the first plane.

                                    ; make sure that it is DWORD aligned.
RowLoop:
        push    si                  ; Save the starting source index
        push    di                  ; Save the starting dest index
        push    ax                  ; Save the current plane mask
        push    bp                  ; Save the current base pointer

        mov     ax, ClippedHeight   ; Use AL for row counter (0-239)
        mov     bx, DecisionY       ; Use BX for decision variable
        mov     cx, SourceWidth     ; Use CX for source width
        mov     dx, SourceHeight    ; Use DX for source height * 2
        shl     dx, 1
        mov     bp, DestHeight      ; Use BP for dest height * 2
        shl     bp, 1
        mov     ah, es:[si]         ; Get the first source pixel

ColumnLoop:
        cmp     ah, 0
        je      SkipDot
        mov     ds:[di], ah         ; Draw a pixel
SkipDot:
        dec     al                  ; Decrement line counter
        jz      DoneWithCol         ; See if we're done with this column
        add     di, 80              ; Go on to the next screen row
        add     bx, dx              ; Increment the decision variable
        js      ColumnLoop          ; Draw this source pixel again

IncSourceRow:
        add     si, cx              ; Move to the next source pixel
        sub     bx, bp              ; Decrement the decision variable
        jns     IncSourceRow        ; See if we need to skip another source pixel
        mov     ah, es:[si]         ; Get the next source pixel
        jmp     ColumnLoop          ; Start drawing this pixel

DoneWithCol:
        pop     bp                  ; Restore BP to access variables
        pop     ax                  ; Restore AL = plane mask
        pop     di                  ; Restore DI to top row of screen
        pop     si                  ; Restore SI to top row of source bits

        rol     al, 1               ; Move to next plane
        adc     di, 0               ; Go on to next screen column
        mov     dx, SC_INDEX2       ; Tell the VGA what column we're in
        out     dx, al              ; by updating the map mask register

        shl     cx, 1               ; CX = SourceWidth * 2
        mov     bx, DecisionX       ; Use BX for the X decision variable
        add     bx, cx              ; Increment the X decision variable
        js      NextCol             ; Jump if we're still in the same source col.
        mov     dx, DestWidth       ; DX = W * 2
        shl     dx, 1
IncSourceCol:
        inc     si                  ; Move to next source column
        sub     bx, dx              ; Decrement X decision variable
        jns     IncSourceCol        ; See if we skip another source column
NextCol:
        mov     DecisionX, bx       ; Free up BX for ColLoop
        dec     ClippedWidth        ; If we're not at last column
        jnz     RowLoop             ;    then do another column
Done:
        ret                         ; We're done!

XSCALE1     ENDP

            END
