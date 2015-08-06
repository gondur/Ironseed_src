program test;

uses data, crt, graph;

var
 ans: char;
 j,i: integer;
 str1, str2: string;

{$L mover2}
{$L vga256}
procedure vgadriver; external;
procedure mymove2(var src,tar; count: integer); external;


{***************************************************************************}

procedure scale(startx,starty,sizex,sizey,newx,newy: integer; var s,t);
var sety, py, pdy, px, pdx, dcx, dcy: integer;
begin
 asm
  push ds
  push es
  les si, [s]         { es: si is our source location }
  lds di, [t]         { ds: di is our destination }
  imul di, [starty], 320
  mov [sety], di
  add di, [startx]

  mov ax, [sizex]
  xor dx, dx
  mov cx, [newx]
  div cx
  mov [px], ax
  mov [pdx], dx       { set up py and pdy }

  mov ax, [sizey]
  xor dx, dx
  mov cx, [newy]
  div cx
  mov [py], ax
  mov [pdy], dx       { set up py and pdy }

  xor cx, cx
  mov [dcx], cx
  mov [dcy], cx
  mov dx, [newy]

 @@iloop:
  add cx, [py]

  mov ax, [pdy]
  add [dcy], ax
  mov ax, [dcy]

  cmp ax, [newy]
  jl @@nodcychange
  inc cx
  sub ax, [newy]
  mov [dcy], ax

 @@nodcychange:

  imul si, cx, 320

  mov bx, [newx]

 @@jloop:
  add si, [px]

  mov ax, [pdx]
  add [dcx], ax
  mov ax, [dcx]
  cmp ax, [newx]
  jl @@nodcxchange

  inc si
  sub ax, [newx]
  mov [dcx], ax

 @@nodcxchange:

  mov al, [es: si]
  mov [ds: di], al     { finally draw it! }

  inc di
  dec bx
  jnz @@jloop

  add [sety], 320
  mov di, [sety]
  add di, [startx]

  dec dx
  jnz @@iloop

  pop es
  pop ds
 end;
end;

{***************************************************************************}

procedure loopscale(startx,starty,sizex,sizey,newx,newy: integer; var s,t);
var sety, py, pdy, px, pdx, dcx, dcy: integer;
begin
 asm
  push ds
  push es
  les si, [s]         { es: si is our source location }
  lds di, [t]
  imul di, [starty], 320
  mov [sety], di
  add di, [startx]

  mov ax, [sizex]
  xor dx, dx
  mov cx, [newx]
  div cx
  mov [px], ax
  mov [pdx], dx       { set up py and pdy }

  mov ax, [sizey]
  xor dx, dx
  mov cx, [newy]
  div cx
  mov [py], ax
  mov [pdy], dx       { set up py and pdy }

  xor cx, cx
  mov [dcx], cx
  mov [dcy], cx
  mov dx, [sizey]

 @@iloop:
  add cx, [py]

  mov ax, [pdy]
  add [dcy], ax
  mov ax, [newy]
  cmp ax, [dcy]
  jg @@nodcychange

  inc cx
  sub [dcy], ax

 @@nodcychange:

  cmp cx, [sizey]
  jb @@noloopy
  xor cx, cx

 @@noloopy:

  imul si, cx, 320

  mov bx, [sizex]

 @@jloop:
  add si, [px]

  mov ax, [pdx]
  add [dcx], ax
  mov ax, [newx]
  cmp ax, [dcx]
  jg @@nodcxchange

  inc si
  sub [dcx], ax

 @@nodcxchange:

  mov al, [es: si]
  mov [ds: di], al     { finally draw it! }

  inc di
  dec bx
  jnz @@jloop

  add [sety], 320
  mov di, [sety]
  add di, [startx]

  dec dx
  jnz @@iloop

  pop es
  pop ds
 end;
end;

{***************************************************************************}

procedure rotateloopscale(startx,starty,sizex,sizey,newx,newy,a: integer; var s,t);
var sety, py, pdy, px, pdx, dcx, dcy: integer;

    xb, yb: integer;

    x1,y1: integer;

    basey: integer;

    rotx,roty: integer;

begin

 rotx:=round(cos(a/100)*1000);
 roty:=round(sin(a/100)*1000);

 asm
  push ds
  push es
  les si, [s]         { es: si is our source location }
  lds di, [t]
  imul di, [starty], 320
  mov [sety], di
  add di, [startx]

  mov ax, [sizex]
  xor dx, dx
  mov cx, [newx]
  div cx
  mov [px], ax
  mov [pdx], dx       { set up py and pdy }

  mov ax, [sizey]
  xor dx, dx
  mov cx, [newy]
  div cx
  mov [py], ax
  mov [pdy], dx       { set up py and pdy }

  xor cx, cx
  mov [dcx], cx
  mov [dcy], cx
  mov dx, [sizey]

 @@iloop:
  add cx, [py]

  mov ax, [pdy]
  add [dcy], ax
  mov ax, [newy]
  cmp ax, [dcy]
  jg @@nodcychange

  inc cx
  sub [dcy], ax

 @@nodcychange:

  cmp cx, [sizey]
  jb @@noloopy
  xor cx, cx

 @@noloopy:

  imul si, cx, 320

  mov [basey], si

  mov bx, [sizex]

 @@jloop:
  add si, [px]

  mov ax, [pdx]
  add [dcx], ax
  mov ax, [newx]
  cmp ax, [dcx]
  jg @@nodcxchange

  inc si
  sub [dcx], ax

 @@nodcxchange:




  {

  x2:=round((si-basey)*rotx-(cx)*roty);
  y2:=round((cx)*rotx+(si-basey)*roty);

  }


  mov al, [es: si]
  mov [ds: di], al     { finally draw it! }

  inc di
  dec bx
  jnz @@jloop

  add [sety], 320
  mov di, [sety]
  add di, [startx]

  dec dx
  jnz @@iloop

  pop es
  pop ds
 end;
end;


procedure scale2(startx,starty,sizex,sizey,newx,newy: integer; var t);
var x, y, py, pdy, px, pdx, ry, rx, dx, dy: integer;
begin
 py:=sizey div newy;
 pdy:=sizey mod newy;
 px:=sizex div newx;
 pdx:=sizex mod newx;
 ry:=starty+sizey;
 rx:=startx+sizex;
 dy:=0;
 dx:=0;
 x:=0;
 y:=0;
 for i:=starty to ry do
  begin
   y:=y+py;
   dy:=dy+pdy;
   if dy>= newy then
    begin
     inc(y);
     dy:=dy-newy;
    end;
   x:=0;
   for j:=startx to rx do
    begin
     x:=x+px;
     dx:=dx+pdx;
     if dx >= newx then
      begin
       inc(x);
       dx:=dx-newx;
      end;
     if (x>sizex) or (y>sizey) then screen[i,j]:=0
      else
       begin
        asm
         push es
         push ds
         les si, [t]
         imul di, [i], 320
         add di, [j]
         imul si, [y], 320
         add si, [x]
         mov ax, $A000
         mov ds, ax
         mov al, [es: si]
         mov [ds: di], al
         pop ds
         pop es
        end;
       end;
    end;
 end;
end;

procedure rotatescale2(startx,starty,sizex,sizey,newx,newy,a: integer; var t);
var x, y, py, pdy, px, pdx, ry, rx, dx, dy: integer;
    rotx,roty: real;
    x2,y2: integer;
begin

 rotx:=cos(a/100);
 roty:=sin(a/100);

 py:=sizey div newy;
 pdy:=sizey mod newy;
 px:=sizex div newx;
 pdx:=sizex mod newx;
 ry:=starty+100;
 rx:=startx+160;
 dy:=0;
 dx:=0;
 x:=0;
 y:=0;
 for i:=starty to ry do
  begin
   y:=y+py;
   dy:=dy+pdy;
   if dy>= newy then
    begin
     inc(y);
     dy:=dy-newy;
    end;
   x:=0;
   for j:=startx to rx do
    begin
     x:=x+px;
     dx:=dx+pdx;
     if dx >= newx then
      begin
       inc(x);
       dx:=dx-newx;
      end;
      x2:=round(x*rotx-y*roty);
      y2:=round(y*rotx+x*roty);
      asm
       push es
       push ds
       les si, [t]
       imul di, [i], 320
       add di, [j]
       imul si, [y2], 320
       add si, [x2]
       mov ax, $A000
       mov ds, ax
       mov al, [es: si]
       mov [ds: di], al
       pop ds
       pop es
      end;
    end;
 end;
end;

procedure shrinkalienscreen;
var t: ^screentype;
    partx,party,b: real;
    a,i2,startx,max,starty: integer;
    temppal: paltype;
    t2: ^screentype;
begin
 new(t);
 new(t2);
 mymove2(screen,t^,16000);
 for i:=0 to 199 do
  mymove2(screen[199-i],t2^[i],80);


{ for i:=0 to 199 do
  begin
   fillchar(t2^[i],10,0);
   move(screen[i,160],t2^[i,10],170);
   fillchar(t^[i,160],160,0);
  end;
 }
{ for i:=22 to 199 do
  mymove2(screen[i,13],t^[i-22],306);}

 max:=20;
 repeat
{  for a:=0 to 314 do
   rotatescale2(0,0,319,199,80,50,a*4,t^);}


  for a:=4 to max do
   begin
    partx:=320/max*a;
    party:=200/max*a;
    scale(0,0,319,199,round(partx),round(party),t^,screen);
   end;
  for a:=max downto 4 do
   begin
    partx:=320/max*a;
    party:=200/max*a;
    scale(0,0,320,199,round(partx),round(party),t^,screen);
   end;


{  for a:=1 to 39 do
   begin
    scale(a*2,a*2,170,200,170-a*4,199-a*4,t^);
    scale((39-a)*2+160,(39-a)*2,170,200,160-(39-a)*4,199-(39-a)*4,t2^);
   end;
  for a:=38 downto 0 do
   begin
    scale(a*2,a*2,170,200,170-a*4,199-a*4,t^);
    scale((39-a)*2+160,(39-a)*2,170,200,160-(39-a)*4,199-(39-a)*4,t2^);
   end;
 }
 until fastkeypressed;


{ max:=50;
  for a:=0 to max do
   begin
    partx:=306-234/max*a;        { we want 72 pels in max moves from 306
    party:=177-142/max*a;        { we want 35 pels in max moves from 177
    starty:=176-round(party)+42;
    startx:=305-round(partx)+43;
    scale(startx,starty,306,177,round(partx),round(party),t^);
   end;
 }
{ for i:=142 to 176 do
  mymove2(screen[i,234],t^[i,234],18);
 loadscreen('data\alien.vga');
 for i:=142 to 176 do
  mymove2(t^[i,234],screen[i,234],18);}
 dispose(t);
 dispose(t2);
 delay(500);
end;

begin
 loadpal('data\intro5.pal');
 set256colors(colors);
 loadscreen('data\intro5.vga');
 shrinkalienscreen;
end.
