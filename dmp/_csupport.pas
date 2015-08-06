(***************************************************************************

                                 CSUPPORT.PAS
                                 ------------

                          (C) 1993 Jussi Lahdenniemi

C-language support functions

***************************************************************************)

Unit Csupport;

Interface

{ DO NOT USE THE FARMALLOC AND FARFREE ROUTINES; THEY ARE NOT FULLY FUNCTIONAL
  AND MAY HANG YOUR COMPUTER! }

Function  Ascz2Str(Var Az):String;
Function  MaxAvail:Longint;
Procedure Str2Ascz(S:String;Var Az);
Function  calloc(Cnt:Word;Size:Word):Pointer;
Function  malloc(Size:Word):Pointer;
Procedure free(p:pointer);
Function  farmalloc(Size:Longint):Pointer;
Procedure farfree(loc:pointer);
Procedure strcpy(var Dest,Sourc);
Procedure strncpy(var Dest,Sourc;MaxCnt:Word);
Function  memcmp(a,b:pointer;len:word):integer;
Procedure atexit(func:pointer);

Const mallocMinLeft : Longint = 0;  { Min. mem left before allocating }

Implementation
uses DOS;

const fflag : boolean = false;

Type TAscz = Array[0..255] of char;

Function MaxAvail:Longint;
Begin
MaxAvail:=1;
end;

Function Ascz2Str(Var Az):String;
Var S:String;
    W:Word;
Begin
  S:='';
  W:=0;
  While (TAscz(Az)[w]<>#0) and (W<255) do begin
    S:=S+TAscz(Az)[W];
    Inc(W);
  end;
  Ascz2Str:=s;
end;

Procedure Str2Ascz(S:String; Var Az);
Var W:Word;
Begin
  For w:=1 to length(S) do TAscz(Az)[w]:=S[w];
end;

Function calloc(Cnt:Word;Size:Word):Pointer;
var p:pointer;
Begin
  p:=malloc(Cnt*Size);
  fillchar(p^,Cnt*Size,0);
  calloc:=p;
end;

Function malloc(Size:Word):Pointer;
type
  ttt = Record
  size: word;
  barray: barray[];

  end;
Var p:ttt;

Begin
  if MaxAvail<Size+4+8+mallocMinLeft then malloc:=nil else begin
    Getmem(p,Size+4+8);
    Word(p[0]):=Size;
    //meml[seg(p^):ofs(p^)]:=Size;
    malloc:=pointer(longint(p)+4);
  end;
end;

Procedure free(p:pointer);
var b:boolean;
begin
{$IFNDEF DPMI}
  if (p<>nil) and (seg(p^)>=seg(heapOrg^)) and (seg(p^)<=seg(heapPtr^)) then
{$ELSE}
  asm
    verw [word ptr p+2]
    db 0fh,94h,0c0h    { setz al }
    mov [b],al
  end;
  fflag:=true;
  if b then
{$ENDIF}
  if (ofs(p^)=4) or (ofs(p^)=12) then
    if meml[seg(p^):ofs(p^)-4]>=65520 then farfree(p) else
      freemem(pointer(longint(p)-4),meml[seg(p^):ofs(p^)-4]+4+8);
  fflag:=false;
end;

Type PfreeRec = ^TfreeRec;
     TfreeRec = record
                  next : PfreeRec;
                  size : Pointer;
                end;

Function farmalloc;

{$IFNDEF DPMI}

var go_on:boolean;
    PtoC:PFreeRec;
    lastP:PFreeRec;
    fsize:Longint;
    next:Pointer;
    loc:Pointer;
begin
  if size<65520 then farmalloc:=malloc(size) else begin
    go_on:=true;
    loc:=nil;                       { Assume not enough free memory }
    PtoC:=freeList;
    lastP:=nil;
    PfreeRec(heapPtr)^.next:=nil;
    fsize:=seg(heapEnd^)-seg(heapPtr^);
    fsize:=fsize*16+ofs(heapEnd^)-ofs(heapPtr^);
    PfreeRec(heapPtr)^.size:=ptr(fsize div 16,fsize mod 16);
    while loc=nil do begin
      fsize:=seg(PtoC^.size^);
      fsize:=fsize*16+ofs(PtoC^.size^);
      if fsize>=size then begin { enough }
        loc:=PtoC;
        dec(fsize,size);
        if fsize>0 then begin
          inc(longint(PtoC),(size div 16)*65536+(size mod 16));
          PtoC^.next:=PfreeRec(loc)^.next;
          PtoC^.size:=ptr(fsize div 16,fsize mod 16);
          if loc=heapPtr then heapPtr:=PtoC;
          if lastP=nil then freeList:=PtoC else lastP^.next:=PtoC;
        end else begin
          if loc=heapPtr then heapPtr:=heapEnd;
          if lastP=nil then freeList:=PtoC^.next else
                            lastP^.next:=PtoC^.next;
        end;
      end;
      lastP:=PtoC;
      PtoC:=PtoC^.next;
    end;
    meml[seg(loc^):ofs(loc^)]:=size;
    inc(longint(loc),4);
    farMalloc:=loc;
  end;
end;

{$ELSE}

begin
  if size<65520 then farmalloc:=malloc(size) else farmalloc:=nil;
end;

{$ENDIF}

Procedure defragmentHeap;
var PtoC,PtoC2:PfreeRec;
    lastP,lastP2:PfreeRec;
    hlp,hlp2:longint;
begin
{$IFNDEF DPMI}
  if heapPtr<>heapEnd then with PfreeRec(heapPtr)^ do begin
    next:=nil;
    hlp:=seg(heapEnd^)-seg(heapPtr^);
    hlp:=hlp*16+ofs(heapEnd^)-ofs(heapPtr^);
    size:=ptr(hlp div 16,hlp mod 16);
  end;
  PtoC:=freeList;
  lastP:=nil;
  PtoC2:=freeList;
  lastP2:=nil;
  while (PtoC<>heapPtr) do begin
    hlp:=seg(PtoC^.size^)+seg(PtoC^);
    hlp:=hlp*16+ofs(PtoC^.size^)+ofs(PtoC^);
    hlp2:=seg(PtoC2^);
    hlp2:=hlp2*16+ofs(PtoC2^);
    if (PtoC<>PtoC2) and (Hlp=Hlp2) then begin
         hlp:=seg(PtoC^.size^)+seg(PtoC2^.size^);
         hlp:=hlp*16+ofs(PtoC^.size^)+ofs(PtoC2^.size^);
         PtoC^.size:=ptr(hlp div 16,hlp mod 16);
         if PtoC2=heapPtr then begin
           if lastP=nil then freeList:=PtoC^.next else lastP^.next:=PtoC^.next;
           heapPtr:=PtoC;
           if PtoC^.next^.next=nil then
             if lastP=nil then freeList:=heapPtr else lastP^.next:=heapPtr;
           PtoC^.next:=nil;
           if lastP2=nil then freeList:=heapPtr else
             if lastP2<>heapPtr then lastP2^.next:=heapPtr;
         end else
           if lastP2=nil then freeList:=PtoC2^.next else lastP2^.next:=PtoC2^.next;
         PtoC:=freeList;
         PtoC2:=freeList;
         lastP:=nil;
         lastP2:=nil;
       end else begin
         lastP2:=PtoC2;
         PtoC2:=PtoC2^.next;
         if PtoC2=nil then begin
           PtoC2:=freeList;
           lastP2:=nil;
           lastP:=PtoC;
           PtoC:=PtoC^.next;
         end;
       end;
  end;
{$ENDIF}
end;

Procedure farfree;
{$IFNDEF DPMI}

var p,q:pointer;
    size:longint;

begin
  size:=meml[seg(loc^):ofs(loc^)-4];
  dec(longint(loc),4);
  p:=freeList;
  q:=nil;
  while longint(p)<longint(loc) do begin q:=p; p:=PfreeRec(p)^.next end;
  PfreeRec(loc)^.size:=ptr(size div 16,size mod 16);
  PfreeRec(loc)^.next:=p;
  if q=nil then freeList:=loc else PfreeRec(q)^.next:=loc;
  defragmentHeap;
end;

{$ELSE}

begin
{  if not fflag then free(p);
  p:=nil;}
end;

{$ENDIF}

Procedure strcpy;
Var w:word;
Begin
  w:=0;
  repeat
    TAscz(Dest)[w]:=TAscz(Sourc)[w];
    inc(w);
  until Tascz(Sourc)[w-1]=#0;
end;

Procedure strncpy;
Var w:word;
Begin
  w:=0;
  repeat
    TAscz(Dest)[w]:=TAscz(Sourc)[w];
    inc(w);
  until (Tascz(Sourc)[w-1]=#0) or (w=MaxCnt);
end;

Function memcmp;
begin
  asm
            push        ds
            mov         ax,[len]
            mov         ax,cx
            Jcxz        @@Null
            Lds         si,[a]
            Les         di,[b]
            Cld
            Rep         Cmpsb
            Mov         al,[si-1]
            Xor         ah,ah
            Mov         cl,es:[di-1]
            Xor         ch,ch
@@Null:     Pop         ds
            Sub         ax,cx
  end;
end;

{$F+}

type TExitProc  = Procedure;
var oldExit     : Pointer;
    exitProcs   : Array[1..20] of TExitProc;
const exitCnt   : word = 0;

Procedure atexit_proc;
var w:word;

begin
 if exitcnt>0 then for w:=exitCnt downto 1 do exitProcs[w];
 exitProc:=oldExit;
end;

Procedure atexit;
begin
  inc(exitCnt);
  exitProcs[exitCnt]:=TExitProc(func);
end;

begin
  oldExit:=exitProc;
  exitProc:=@atexit_proc;
end.
