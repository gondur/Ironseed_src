program testintro;

uses crt, graph;

type
 paltype= array[0..255,1..3] of byte;
 screentype= array[0..199,0..319] of byte;
var
 colors: paltype;
 i,j,a: integer;

{$L v3220pa}

procedure init320200; external;
procedure setpix( x, y : integer; pcolor : byte ); external;
function  getpix( x, y: integer ) : byte ; external;
procedure setpage( page : byte ); external;
procedure showpage( page : byte ); external;

procedure set256Colors(pal: paltype); assembler;
asm
 mov ax, 1012h
 mov bx, 0
 mov cx, 256
 les dx, Pal
  int 10h
end;

procedure loadpal(s: string);
var palfile: file of paltype;
begin
 assign(palfile,s);
 reset(palfile);
 read(palfile,colors);
 close(palfile);
end;


procedure loadscreens;
var vgafile: file of screentype;
    t: ^screentype;
begin
 new(t);
 for a:=1 to 4 do
  begin
   assign(vgafile,'data\blast0'+chr(a+48)+'.vga');
   reset(vgafile);
   read(vgafile,t^);
   setpage(a-1);
   for i:=0 to 199 do
    for j:=0 to 319 do
     setpix(j,i,t^[i,j]);
   close(vgafile);
  end;
 dispose(t);
end;

procedure cycle;
begin
 i:=0;
 repeat
  showpage(i);
  inc(i);
  if i=4 then i:=0;
  delay(30);
 until keypressed;
end;

begin
 init320200;
 loadpal('data\blast01.pal');
 set256colors(colors);
 loadscreens;
 cycle;
 closegraph;
end.