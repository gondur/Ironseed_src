program rotatebox;
uses crt,graph;


type
 colortype= array[1..3] of byte;
 planetype=array[1..4,1..3] of real;
 boxtype=array[1..12] of planetype;
 paltype= array[0..255] of colortype;
 screentype= array[0..199,0..319] of byte;
 bitmaptype= array[0..99,0..99] of byte;
const
 box: boxtype =
(
 ((5,5,5),(5,-5,5),(-5,-5,5),(-5,5,5)),
 ((5,5,-5),(5,-5,-5),(-5,-5,-5),(-5,5,-5)),
 ((5,5,5),(5,-5,5),(5,-5,-5),(5,5,-5)),
 ((-5,5,5),(-5,-5,5),(-5,-5,-5),(-5,5,-5)),
 ((5,5,5),(5,5,-5),(-5,5,-5),(-5,5,5)),
 ((5,-5,5),(5,-5,-5),(-5,-5,-5),(-5,-5,5)),

 ((10,10,10),(10,-10,10),(-10,-10,10),(-10,10,10)),
 ((10,10,-10),(10,-10,-10),(-10,-10,-10),(-10,10,-10)),
 ((10,10,10),(10,-10,10),(10,-10,-10),(10,10,-10)),
 ((-10,10,10),(-10,-10,10),(-10,-10,-10),(-10,10,-10)),
 ((10,10,10),(10,10,-10),(-10,10,-10),(-10,10,10)),
 ((10,-10,10),(10,-10,-10),(-10,-10,-10),(-10,-10,10))

 );

var
 x,y,z,sd,i,a,b,j,c,x1,j1,i2,j3: integer;
 ans: char;
 range,temp1,temp2,temp3: real;
 a1,a2,a3,yadj,pfac,xpart,yloc,ypart,xpart2,yloc2,ypart2,yhpart,yh: real;
 alt: integer;
 colors: paltype;
 points: boxtype;
 screen: screentype absolute $A000:0000;
 temp: ^screentype;
 tempp: planetype;
 bitmap: ^bitmaptype;

{$L vga256}
procedure vgadriver; external;
{$L mover}
{$F+}
procedure mymove(var src,tar; count: integer); external;
{$F-}

function fastkeypressed: boolean; assembler;
asm
 push ds
 mov ax, 40h
 mov ds, ax
 cli
 mov ax, [1Ah]
 cmp ax, [1Ch]
 sti
 mov ax, 0
 jz @nopress
 inc ax
@nopress:
 pop ds
end;

procedure loadscreen(s: string);
var vgafile: file of screentype;
begin
 assign(vgafile,s);
 reset(vgafile);
 read(vgafile,screen);
 close(vgafile);
end;

procedure loadpal(s: string);
var palfile: file of paltype;
begin
 assign(palfile,s);
 reset(palfile);
 read(palfile,colors);
 close(palfile);
end;

procedure setrgb256(palnum,r,g,b: byte); assembler;
asm
 xor bh, bh
 mov bl, palnum
 mov ax, 1010h
 mov dh, r
 mov ch, g
 mov cl, b
  int 10h
end;

procedure set256Colors(pal: paltype); assembler;
asm
 mov ax, 1012h
 mov bx, 0
 mov cx, 256
 les dx, Pal
  int 10h
end;

{$F+}
function testit : integer; assembler;
asm
 mov ax, 1A00h
  int 10h
 cmp al, 1Ah
 jne @@nope
 mov ax, 1
 jmp @@done
@@nope:
 mov ax, 0
@@done:
end;
{$F-}

procedure readygraph;
var testdriver,driver,mode,errcode: integer;
begin
 testdriver:=installuserdriver('vga256',@testit);
 errcode:=graphresult;
 if errcode<>grok then
  begin
   writeLn('Error Installing VGA Driver:',errcode);
   halt(4);
  end;
 registerbgidriver(@vgadriver);
 errcode:=graphresult;
 if errcode<>grok then
  begin
   writeLn('Error Registering VGA Driver:',errcode);
   halt(4);
  end;
 driver:=detect;
 initgraph(driver,mode,'');
 errcode:=graphresult;
 if errcode<>grok then
  begin
   writeln('Video Initialization Failure: ',errcode);
   halt(4);
  end;
 loadpal('data\main.pal');
 set256colors(colors);
 setgraphbufsize(0);
 checksnow:=false;
end;

procedure draw;
begin
 for x:=1 to 12 do
   begin
    pfac:=sd/(range-box[x,y,3]);
    points[x,y,1]:=160+box[x,y,1]*pfac;
    points[x,y,2]:=100-yadj*box[x,y,2]*pfac;
{   moveto(round(160+box[x,4,1]*sd/(range-box[x,4,3])),
        round(100-yadj*(box[x,4,2]*sd/(range-box[x,4,3]))));
}   for y:=1 to 4 do
    begin
     pfac:=sd/(range-box[x,y,3]);
     points[x,y,1]:=160+box[x,y,1]*pfac;
     points[x,y,2]:=100-yadj*box[x,y,2]*pfac;
 {    lineto(round(points[x,y,1]),round(points[x,y,2]));
  }  end;
  end;

 for j:=1 to 4 do
  begin
   b:=0;
   for x:=1 to 4 do b:=b+round(box[j,x,3]);
   for i:=j to 4 do
    begin
     a:=0;
     for x:=1 to 4 do a:=a+round(box[i,x,3]);
     if a<b then
      begin
       tempp:=box[i];
       box[i]:=box[j];
       box[j]:=tempp;
      end;
    end;
  end;

 for x:=3 to 4 do
  begin
   xpart:=(points[x,4,1]-points[x,1,1]);
   yloc:=points[x,1,2];
   yloc2:=points[x,2,2];
   ypart:=(points[x,4,2]-points[x,1,2])/xpart;
   for j:=1 to round(abs(xpart)) do
    begin
     if xpart<0 then j1:=-j else j1:=j;
     x1:=round(points[x,1,1]+j1);
     yh:=yloc2-ypart*2*j1-yloc;
     i2:=round(yloc+j1*ypart);
     j3:=round(j*100/xpart);
     for i:=1 to round(yh) do
      temp^[i+i2,x1]:=bitmap^[round(i*100/yh),j3];
    end;
  end;
end;

procedure altx;
begin
 for x:=1 to 12 do
  for y:=1 to 4 do
   begin
    temp2:=box[x,y,2];
    temp3:=box[x,y,3];
    box[x,y,2]:=(0.95533)*temp2-(0.29552)*temp3;
    box[x,y,3]:=(0.29552)*temp2+(0.95533)*temp3;
   end;
end;

procedure alty;
begin
 for x:=1 to 12 do
  for y:=1 to 4 do
   begin
    temp1:=box[x,y,1];
    temp3:=box[x,y,3];
    box[x,y,1]:=(0.95533)*temp1-(0.29552)*temp3;
    box[x,y,3]:=(0.29552)*temp1+(0.95533)*temp3;
   end;
end;

procedure alty2;
begin
 for x:=1 to 12 do
  for y:=1 to 4 do
   begin
    temp1:=box[x,y,1];
    temp3:=box[x,y,3];
    box[x,y,1]:=(0.95533)*temp1+(0.29552)*temp3;
    box[x,y,3]:=(-0.29552)*temp1+(0.95533)*temp3;
   end;
end;

procedure altz;
begin
 for x:=1 to 12 do
  for y:=1 to 4 do
   begin
    temp1:=box[x,y,1];
    temp2:=box[x,y,2];
    box[x,y,1]:=(0.95533)*temp1-(0.29552)*temp2;
    box[x,y,2]:=(0.29552)*temp1+(0.95533)*temp2;
   end;
end;

begin
 readygraph;
 fillchar(colors,768,0);
 set256colors(colors);
 loadscreen('makedata\bitmap.vga');
 new(bitmap);
 for i:=0 to 99 do
  begin
   move(screen[i],bitmap^[i],100);
   fillchar(screen[i],100,0);
  end;
 loadpal('data\main.pal');
 set256colors(colors);
 range:=200;
 yadj:=1600/1920;
 sd:=500;
 alt:=0;
 setcolor(47);
 new(temp);
 repeat
  repeat
    fillchar(temp^,64000,0);
   case alt of
    0:;
    1:altx;
    2:altx;
    3:alty2;
    4:alty;
    5:altz;
    6:altz;
    7:range:=range+4;
    8:range:=range-4;
    9:begin altx; alty; altz; end;
   end;
   draw;
   mymove(temp^,screen,16000);
  until fastkeypressed;
  ans:=readkey;
  case upcase(ans) of
   'R': alt:=8;
   'F': alt:=7;
   'A': alt:=1;
   'Z': alt:=2;
   'S': alt:=3;
   'X': alt:=4;
   'D': alt:=5;
   'C': alt:=6;
   '+':;
   '-':;
   'M': alt:=9;
   else alt:=0;
  end;
  draw;
 until ans=#27;
 dispose(bitmap);
 dispose(temp);
 closegraph;
end.

