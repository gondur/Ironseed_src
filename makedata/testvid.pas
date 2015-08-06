program testvideo;

uses crt,graph,data;

const

 crtaddr = $3D4;
 crtstat = $3DA;
 crtattr = $3C0;
type
 colortype=array[1..3] of byte;
 paltype=array[0..255] of colortype;
 screentype= array[0..199,0..319] of byte;

var
 a,b,i,j,total,max: word;
 temp: ^screentype;
 seed,tslice: integer;
 vgafile: file of screentype;
 palfile: file of paltype;
 colors: paltype;
 screen: screentype absolute $A000:0000;
 offs: word;

{$L v3220pa}

procedure init320200; external;
procedure setpix(x,y: integer; pcolor: byte); external;
function getpix(x,y: integer): byte; external;
procedure setpage(page: byte); external;
procedure showpage(page: byte); external;

procedure set256Colors(pal: paltype); assembler;
asm
 mov ax, 1012h
 mov bx, 0
 mov cx, 256
 les dx, Pal
  int 10h
end;

procedure init;
begin
 for j:=208 to 240 do colors[j]:=colors[j-208];
 set256colors(colors);
 for j:=0 to 318 do
  for i:=0 to 199 do
   screen[i,j]:=random(32)+196;
end;

procedure snowing3;
var index: integer;
    temp: colortype;
begin
 for j:=1 to 10000 do
  begin
   i:=192+random(31);
   setcolor(i);
   setfillstyle(1,i);
   pieslice(random(320),random(200),0,360,random(2)+1);
  end;
 for j:=192 to 223 do
  begin
   colors[j,3]:=j-208;
   colors[j,1]:=0;
   colors[j,2]:=0;
  end;
 for j:=224 to 255 do colors[j]:=colors[j-32];
 set256colors(colors);
  repeat
   inc(index);
   if index<32 then inc(index) else index:=0;
    temp:=colors[192];
    for i:=192 to 222 do
     colors[i]:=colors[i+1];
    colors[223]:=temp;
    set256colors(colors);
  delay(tslice*5);
 until keypressed;
end;

procedure snowing2;
begin
 total:=64000;
 seed:=16;
 for j:=192 to 223 do
  begin
   colors[j,3]:=j-208;
   colors[j,1]:=j-208;
   colors[j,2]:=j-208;
  end;
 for j:=223 to 255 do colors[j]:=colors[j-32];
 for j:=0 to 32 do
  begin
   colors[j,1]:=j*2;
   colors[j,2]:=j*2;
   colors[j,3]:=j*2;
  end;
 repeat
  for i:=192 to 223 do
   colors[i]:=colors[223+random(32)];
  set256colors(colors);
  if total mod 4000=0 then
   begin
    dec(seed);
    for j:=0 to 319 do
     for i:=0 to 199 do
      if (temp^[i,j] mod 16=seed)
       and (temp^[i,j]>0)
       then screen[i,j]:=temp^[i,j];
   end;
 until seed=0;
 repeat
    for i:=192 to 223 do
     colors[i]:=colors[223+random(32)];
    set256colors(colors);
  delay(tslice*3);
 until keypressed;
end;

procedure snowing;
begin
 
  total:=0;
  max:=64000;
  j:=0;
  seed:=17;
 repeat
   inc(total);
   j:=j+seed;
   if j>max then j:=j-max;
   a:=j div 319;
   b:=j mod 319;
   if total<max then screen[a,b]:=temp^[a,b];
  if total mod 100=0 then
   begin
    for i:=208 to 240 do
     colors[i]:=colors[random(32)];
    set256colors(colors);
   end;
 until total>=max;
 max:=64000;
 total:=0;
 j:=0;
 repeat
  inc(total);
  j:=j+seed;
  if j>max then j:=j-max;
  screen[j div 319,j mod 319]:=random(32)+208;
  if total mod 100=0 then
   begin
    for i:=208 to 240 do
     colors[i]:=colors[random(32)];
    set256colors(colors);
   end;
  until total>max;
end;

procedure shiftit;
begin
 offs:=140;
 asm
  mov dx, crtstat
 @@wait48:
  in ax, dx
  test ax, 8
  jz @@wait48
 @@wait40:
  in ax, dx
  test ax, 8
  jnz @@wait40
  mov dx, crtaddr
  mov cx, offs
  cli
  mov ah, ch
  mov al, 0Ch
  out dx, ax
  mov ah, cl
  mov al, 0Dh
  out dx, ax
  sti
  mov dx, crtstat
 @@wait48b:
  in ax, dx
  test ax, 08h
  jz @@wait48b
  mov dx, crtaddr
  cli
  mov ah, 0
  mov al, 08h
  out dx, ax
  mov dx, crtattr
  mov al, 33h
  out dx, al
  mov al, 0
  out dx, al
  sti
 end;
end;

procedure scrollit2(x: byte);
begin
 asm
  mov ax, 1000h
  mov bh, 33h
  mov bl, x
   int 10h
 end;
end;

procedure scrollit(x,y: byte);
var offs: word;
begin
{  if y>0 then offs:=offs+80*y else offs:=0;}
  offs:=j mod 5;
   asm
    mov dx, crtstat
   @@wait48:
    in ax, dx
    test ax, 8
    jz @@wait48
   @@wait40:
    in ax, dx
    test ax, 8
    jnz @@wait40
    mov dx, crtaddr
    mov cx, offs
    cli
    mov ah, ch
    mov al, 0Ch
    out dx, ax
    mov ah, cl
    mov al, 0Dh
    out dx, ax
    sti
{    mov dx, crtstat
   @@wait48b:
    in ax, dx
    test ax, 08h
    jz @@wait48b
    mov dx, crtaddr
    cli
    mov ah, y
    mov al, 08h
    out dx, ax
    mov dx, crtattr
    mov al, 33h
    out dx, al
    mov al, x
    out dx, al
    sti
}   end;
end;

procedure loadscreen2(s: string);
begin
 assign(vgafile,s);
 reset(vgafile);
 read(vgafile,temp^);
 close(vgafile);
 for j:=0 to 319 do
  for i:=0 to 199 do
   setpix(j,i,temp^[i,j]);
end;

procedure loadpal2(s: string);
begin
 assign(palfile,s);
 reset(palfile);
 read(palfile,colors);
 close(palfile);
 set256colors(colors);
end;

procedure test1;
begin
 randomize;
 tslice:=120;
 init320200;
 loadpal2('data\mars.pal');
 new(temp);
 setpage(0);
 showpage(0);
 loadscreen2('data\cloud.vga');
 setpage(1);
 loadscreen('data\mars.vga');
 setpage(2);
 loadscreen2('data\cloud.vga');
 for j:=1 to 100 do
  begin
   scrollit2(4);
   readkey;
  end;
 dispose(temp);
 closegraph;
end;

begin
 loadpal('data\mars.pal');
 loadscreen('data\mars.vga');
 set256colors(colors);
 readkey;
 offs:=0;
 for j:=1 to 200 do
  begin
   scrollit(0,2);
  end;
 closegraph;
end.