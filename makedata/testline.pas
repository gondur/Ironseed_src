program TestLines;

uses crt;

type
 screentype= array[0..199,0..319] of byte;
 paltype= array[0..255,1..3] of byte;

var
 screen: screentype absolute $A000:0000;
 colors: paltype;

 x1,y1,x2,y2,j: integer;

procedure errorhandler(s: string; errtype: integer);
begin                              { handles errors and outputs a message}
 textmode(co80);
 writeln;
 case errtype of
  1: writeln('File Error: ',s);
  2: writeln('Mouse Error: ',s);
  3: writeln('Sound Error: ',s);
  4: writeln('EMS Error: ',s);
  5: writeln('Fatal File Error: ',s);
  6: writeln('Program Error: ',s);
 end;
 halt(4);
end;

procedure setvidmode(mode: byte);  { sets different video modes }
begin
 asm
  mov ah, 00
  mov al, [mode]
   int 10h
 end;
end;

procedure loadscreen(s: string);   { load up the screen }
var vgafile: file of screentype;
begin
 assign(vgafile,s);
 reset(vgafile);
 if ioresult<>0 then errorhandler(s,1);
 read(vgafile,screen);
 if ioresult<>0 then errorhandler(s,5);
 close(vgafile);
end;

procedure loadpal(s: string);      { load up the palette but don't set }
var palfile: file of paltype;
begin
 assign(palfile,s);
 reset(palfile);
 if ioresult<>0 then errorhandler(s,1);
 read(palfile,colors);
 if ioresult<>0 then errorhandler(s,5);
 close(palfile);
end;

procedure setrgb256(palnum,r,g,b: byte); assembler;
asm                                { this is an extra, sets 1 color }
 xor bh, bh
 mov bl, palnum
 mov ax, 1010h
 mov dh, r
 mov ch, g
 mov cl, b
  int 10h
end;

procedure getrgb256(palnum: byte; var r,g,b); assembler;
asm                                { this is an extra, gets 1 color }
 xor bh, bh
 mov bl, palnum
 mov ax, 1015h
  int 10h
 les di, r
 mov es:[di], dh
 les di, g
 mov es:[di], ch
 les di, b
 mov es:[di], cl
end;

procedure set256Colors(pal: paltype); assembler;
asm                                { sets all colors }
 mov ax, 1012h
 mov bx, 0
 mov cx, 256
 les dx, Pal
  int 10h
end;

procedure fading;                  { nice clean fade function }
var a,i,j: integer;
    temppal: paltype;
begin
 move(colors,temppal,768);
 for a:=31 downto 1 do
  begin
   for j:=0 to 255 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/32);
   set256colors(temppal);
   delay(40);
  end;
 fillchar(temppal,768,0);
 set256colors(temppal);
end;

procedure fadein;                  { nice fade in function }
var a,i,j: integer;
    temppal: paltype;
begin
 fillchar(temppal,768,0);
 for a:=0 to 15 do
  begin
   for j:=0 to 15 do
    for i:=a to 15 do
     temppal[j*16+i]:=colors[j*16+a];
   set256colors(temppal);
   delay(40);
  end;
 set256colors(colors);
end;

procedure line(x1,y1,x2,y2,c: integer);
var dx,dy,incre,incrne,d,x,y: integer;
begin
 if x1>x2 then
  begin
   x:=x1;
   x1:=x2;
   x2:=x;
   y:=y1;
   y1:=y2;
   y2:=y;
  end;
 dx:=x2-x1;
 dy:=y2-y1;
 if (abs(dy)<dx) and (dy<0) then
  begin
   if y1<y2 then
    begin
     y:=y1;
     y1:=y2;
     y2:=y;
    end;
   dy:=y1-y2;
   d:=dy*2-dx;
   incre:=dy*2;
   incrne:=(dy-dx)*2;
   x:=x1;
   y:=y1;
   screen[y,x]:=c;
   while x<x2 do
    begin
     if d<=0 then
      begin
       inc(d,incre);
       inc(x);
      end
     else
      begin
       inc(d,incrne);
       inc(x);
       dec(y);
      end;
     screen[y,x]:=c;
    end;
  end
 else if (dy<0) then
  begin
   if y1<y2 then
    begin
     y:=y1;
     y1:=y2;
     y2:=y;
    end;
   dy:=y1-y2;
   d:=dx*2-dy;
   incre:=dx*2;
   incrne:=(dx-dy)*2;
   x:=y1;
   y:=x1;
   screen[x,y]:=c;
   while x>y2 do
    begin
     if d<=0 then
      begin
       inc(d,incre);
       dec(x);
      end
     else
      begin
       inc(d,incrne);
       dec(x);
       inc(y);
      end;
     screen[x,y]:=c;
    end;
  end
 else if dy>dx then
  begin
   if y1>y2 then
    begin
     y:=y1;
     y1:=y2;
     y2:=y;
    end;
   dy:=y2-y1;
   d:=dx*2-dy;
   incre:=dx*2;
   incrne:=(dx-dy)*2;
   x:=y1;
   y:=x1;
   screen[x,y]:=c;
   while x<y2 do
    begin
     if d<=0 then
      begin
       inc(d,incre);
       inc(x);
      end
     else
      begin
       inc(d,incrne);
       inc(x);
       inc(y);
      end;
     screen[x,y]:=c;
    end;
  end
 else
  begin
   if y1>y2 then
    begin
     y:=y1;
     y1:=y2;
     y2:=y;
    end;
   dy:=y2-y1;
   d:=dy*2-dx;
   incre:=dy*2;
   incrne:=(dy-dx)*2;
   x:=x1;
   y:=y1;
   screen[y,x]:=c;
   while x<x2 do
    begin
     if d<=0 then
      begin
       inc(d,incre);
       inc(x);
      end
     else
      begin
       inc(d,incrne);
       inc(x);
       inc(y);
      end;
     screen[y,x]:=c;
    end;
  end;
end;

procedure line2(x1,y1,x2,y2,c: integer);
var dx,dy,incre,incrne,d,x,y: integer;
begin
 if x1>x2 then
  begin
   x:=x1;
   x1:=x2;
   x2:=x;
   y:=y1;
   y1:=y2;
   y2:=y;
  end;
 dx:=x2-x1;
 dy:=y2-y1;
 if (abs(dy)<dx) and (dy<0) then
  begin
   if y1<y2 then
    begin
     y:=y1;
     y1:=y2;
     y2:=y;
    end;
   dy:=y1-y2;
   d:=dy*2-dx;
   incre:=dy*2;
   incrne:=(dy-dx)*2;
   x:=x1;
   y:=y1;
   screen[y,x]:=c;
   while x<x2 do
    begin
     if d<=0 then
      begin
       inc(d,incre);
       inc(x);
      end
     else
      begin
       inc(d,incrne);
       inc(x);
       dec(y);
      end;
     screen[y,x]:=c;
    end;
  end
 else if (dy<0) then
  begin
   if y1<y2 then
    begin
     y:=y1;
     y1:=y2;
     y2:=y;
    end;
   dy:=y1-y2;
   d:=dx*2-dy;
   incre:=dx*2;
   incrne:=(dx-dy)*2;
   x:=y1;
   y:=x1;
   screen[x,y]:=c;
   while x>y2 do
    begin
     if d<=0 then
      begin
       inc(d,incre);
       dec(x);
      end
     else
      begin
       inc(d,incrne);
       dec(x);
       inc(y);
      end;
     screen[x,y]:=c;
    end;
  end
 else if dy>dx then
  begin
   if y1>y2 then
    begin
     y:=y1;
     y1:=y2;
     y2:=y;
    end;
   dy:=y2-y1;
   d:=dx*2-dy;
   incre:=dx*2;
   incrne:=(dx-dy)*2;
   x:=y1;
   y:=x1;
   screen[x,y]:=c;
   while x<y2 do
    begin
     if d<=0 then
      begin
       inc(d,incre);
       inc(x);
      end
     else
      begin
       inc(d,incrne);
       inc(x);
       inc(y);
      end;
     screen[x,y]:=c;
    end;
  end
 else
  begin
   if y1>y2 then
    begin
     y:=y1;
     y1:=y2;
     y2:=y;
    end;
   dy:=y2-y1;
   d:=dy*2-dx;
   incre:=dy*2;
   incrne:=(dy-dx)*2;
   x:=x1;
   y:=y1;
   screen[y,x]:=c;
   while x<x2 do
    begin
     if d<=0 then
      begin
       inc(d,incre);
       inc(x);
      end
     else
      begin
       inc(d,incrne);
       inc(x);
       inc(y);
      end;
     screen[y,x]:=c;
    end;
  end;
end;

procedure circlepoints(x1,y1,x,y: integer; c: byte);
begin
asm
 push es
 mov ax, $A000
 mov es, ax
 mov bx, [x1]
 mov cx, [y1]
 mov dl, [c]

 mov ax, cx
 add ax, [x]
 imul di, ax, 320
 add di, bx
 add di, [y]
 mov [es:di], dl

 mov ax, cx
 add ax, [x]
 imul di, ax, 320
 add di, bx
 sub di, [y]
 mov [es:di], dl

 mov ax, cx
 sub ax, [x]
 imul di, ax, 320
 add di, bx
 add di, [y]
 mov [es:di], dl

 mov ax, cx
 sub ax, [x]
 imul di, ax, 320
 add di, bx
 sub di, [y]
 mov [es:di], dl

 mov ax, cx
 add ax, [y]
 imul di, ax, 320
 add di, bx
 add di, [x]
 mov [es:di], dl

 mov ax, cx
 add ax, [y]
 imul di, ax, 320
 add di, bx
 sub di, [x]
 mov [es:di], dl

 mov ax, cx
 sub ax, [y]
 imul di, ax, 320
 add di, bx
 add di, [x]
 mov [es:di], dl

 mov ax, cx
 sub ax, [y]
 imul di, ax, 320
 add di, bx
 sub di, [x]
 mov [es:di], dl

 pop es
end;
end;

procedure circle(x1,y1,r,c: integer);
var x,y,d,de,dse: integer;
label loop;
begin
asm
 mov [x], 0
 mov ax, [r]
 mov [y], ax
 mov bx, 1
 sub bx, ax
 mov [d], bx
 mov [de], 3
 shl ax, 1
 mov [dse], 5
 sub [dse], ax
end;
 circlepoints(x1,y1,x,y,c);
asm
loop:
 cmp [d], 0
 jge @@se
@@e:
 mov ax, [de]
 add [d], ax
 add [dse], 2
 jmp @@done
@@se:
 mov ax, [dse]
 add [d], ax
 add [dse], 4
 dec [y]
@@done:
 inc [x]
 add [de], 2
end;
 circlepoints(x1,y1,x,y,c);
asm
 mov ax, [y]
 cmp ax, [x]
 jg loop
end;
end;

begin
 setvidmode($13);                  { set the vga video mode }
 loadpal('data\main.pal');
 set256colors(colors);             { set cleared palette }
 randomize;

 for j:=50 to 50 do
  begin
   circle(160,100,j,31);
   delay(100);
  end;
{ for j:=0 to 500 do
  begin
   x1:=random(320);
   y1:=random(200);
   x2:=random(320);
   y2:=random(200);
   line(x1,y1,x2,y2,63);
   screen[y1,x1]:=47;
   screen[y2,x2]:=95;
  end; }
 readkey;

 textmode(co80);                   { reset video to text mode }
end.