unit emstool;

interface

type
 emstype=
  object
   error,version: byte;                  {error code, version in bcd}
   installed: boolean;
   frame0,totalpages,freepages,          {ems page frame 0, total ems, free ems}
   handle: word;                         {current handle}
   constructor initialize;
   function getemserrmessage: string;
   procedure getmem(pages: word);
   procedure freemem;
   procedure setmapping(logpage: word; phypage: byte);
   procedure savemap;
   procedure restoremap;
   procedure getstatus;
  end;
var
 ems: emstype;

{
 to setup handle:
  1. ems.getmem(size)
  2. ems.setmapping(firstlogpage,0)
          .
     ems.setmapping(endlogpage,4)
  3. ems.savemap
  *myhandle := ems.handle

 to alter data:
  *ems.handle := myhandle
  4. ems.restoremap
  5. alter data at ptr(ems.frame0,0)
  6. ems.savemap

 to free ems pages:
  *ems.handle := myhandle
  7. ems.restoremap
  8. ems.freemem
}

implementation

uses dos;

constructor emstype.initialize; assembler;
asm
 mov ah, 40h
  int 67h              {check installation}
 cmp ah, 0
 jne @@notfound
 mov ems.installed, 1
 mov ah, 41h
  int 67h              {find first frame addr}
 cmp ah, 0
 jne @@done
 mov ems.frame0, bx
 mov ah, 42h
  int 67h              {free & used pages}
 cmp ah, 0
 jne @@done
 mov ems.freepages, bx
 mov ems.totalpages, dx
 mov ah, 46h
  int 67h              {get EMM version}
 cmp ah, 0
 jne @@done
 mov ems.version, al
 jmp @@done
@@notfound:
 mov ems.installed, 0
@@done:
 mov ems.error, ah
 mov ems.handle, 0
end;

procedure emstype.getmem(pages: word);
begin
 asm
  mov ah, 43h
  mov bx, pages
   int 67h
  mov ems.error, ah
  mov ems.handle, dx
 end;
end;

function emstype.getemserrmessage: string;
var s: string;
begin
 case error of
  $00: s:='';
  $80: s:='Internal Error.';
  $81: s:='Hardware Error.';
  $83: s:='Invalid Handle.';
  $85: s:='Handle Error.';
  $86: s:='Deallocation Failure.';
  $87: s:='Out of EMS memory.';
  $8A,$8B: s:='Invalid EMS Page.';
  $8D: s:='Page in Frame. No Need to Restore.';
  else s:='Unknown EMS error.';
 end;
 getemserrmessage:=s;
end;

procedure emstype.freemem; assembler;
asm
 mov ah, 45h
 mov dx, ems.handle
  int 67h
 mov ems.error, ah
end;

procedure emstype.setmapping(logpage: word; phypage: byte); assembler;
asm
 mov ah, 44h
 mov al, phypage
 mov dx, ems.handle
 mov bx, logpage
  int 67h
 mov ems.error, ah
end;

procedure emstype.savemap; assembler;
asm
 mov ah, 47h
 mov dx, ems.handle
  int 67h
 mov ems.error, ah
end;

procedure emstype.restoremap; assembler;
asm
 mov ah, 48h
 mov dx, ems.handle
  int 67h
 mov ems.error, ah
end;

procedure emstype.getstatus; assembler;
asm
 mov ah, 42h
  int 67h
 cmp ah, 0
 jne @@done
 mov ems.freepages, bx
 mov ems.totalpages, dx
@@done:
 mov ems.error, ah
end;

begin
 ems.initialize;
end.