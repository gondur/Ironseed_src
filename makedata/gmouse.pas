unit gmouse;

interface

type
 curtype = array[0..63] of byte;
 mousetype =
  object
   error,but1,but2,but3: boolean;
   x,y: integer;
   buttons: byte;
   procedure show;
   procedure hide;
   constructor initialize;
   procedure getpos;
   function getstatus(button: byte) : boolean;
   procedure setxy(x1,y1: integer);
   procedure sethoriz(xmin,xmax: integer);
   procedure setvert(ymin,ymax: integer);
   procedure setsensitivity(xratio,yratio: integer);
   procedure setcursor(curseg,curofs,hotx,hoty: word);
  end;
const
 left: byte  = 0;
 right: byte = 1;
 defaultcur : curtype =
(255,239,255,227,255,240,63,152,15,204,7,230,15,227,159,241,
207,240,103,248,51,248,153,252,204,253,229,255,241,255,251,255,
0,0,0,48,0,60,0,63,192,31,240,31,128,15,192,15,
224,7,240,6,120,2,60,2,30,0,12,0,4,0,0,0);
 targetcur : curtype =
(255,255,127,252,31,240,143,226,231,206,231,206,243,159,131,130,
243,159,231,206,231,206,143,226,31,240,127,252,255,255,255,255,
0,0,0,0,128,3,224,15,240,31,240,31,248,63,248,62,248,
63,240,31,240,31,224,15,128,3,0,0,0,0,0,0);

var
 mouse:mousetype;

implementation

uses data;

constructor mousetype.initialize; assembler;
asm
 mov ax, 0
 int 51
 mov mouse.error, 0
 cmp ax, 0
 jne @@noerror
 mov mouse.error, 1
@@noerror:
 mov mouse.buttons, bl
end;

procedure mousetype.hide; assembler;
asm
 mov ax, 2
 int 51
end;

procedure mousetype.show; assembler;
asm
 mov ax, 1
 int 51
end;

procedure mousetype.getpos; assembler;
asm
 mov ax, 3
 int 51
 mov mouse.x, cx
 mov mouse.y, dx
end;

function mousetype.getstatus(button: byte) : boolean; assembler;
asm
 mov ax, 3
 int 51
 shr cx, 1
 mov mouse.x, cx
 mov mouse.y, dx
 cmp button, 1
 je @@right
 test bx, 1
 jz @@nope
 mov ax, 1
 jmp @@done
@@right:
 test bx, 2
 jz @@nope
 mov ax, 1
 jmp @@done
@@nope:
 mov ax, 0
@@done:
end;

procedure mousetype.setXY(x1,y1: integer); assembler;
asm
 mov ax, 4
 mov cx, x1
 mov dx, y1
 int 51
end;

procedure mousetype.sethoriz(xmin,xmax: integer); assembler;
asm
 mov ax, 7
 mov cx, xmin
 mov dx, xmax
 int 51
end;

procedure mousetype.setvert(ymin,ymax: integer); assembler;
asm
 mov ax, 8
 mov cx, ymin
 mov dx, ymax
 int 51
end;

procedure mousetype.setSensitivity(xratio,yratio:integer); assembler;
asm
 mov ax, 15
 mov cx, xratio
 mov dx, yratio
 int 51
end;

procedure mousetype.setcursor(curseg,curofs,hotx,hoty: word); assembler;
asm
 push es
 mov ax, curseg
 mov es, ax
 mov dx, curofs
 mov bx, hotx
 mov cx, hoty
 mov ax, 9
 int 51
 pop es
end;

begin
 mouse.initialize;
end.