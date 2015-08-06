program makescreen;
uses crt;

type
 icontype= array[1..17,1..15] of byte;
 fonttype= array[1..3] of byte;
 colortype= array[1..3] of byte;
 paltype= array[0..255] of colortype;
 screentype=array[0..199,0..319] of byte;

const
  font: array[1..54] of fonttype=(
(0,0,0),       { }(102,96,96),   {!}(85,80,0),     {"}(34,0,0),      {'}
(36,68,32),    {(}(66,34,64),    {)}(9,105,0),     {*}(4,228,0),     {+}
(0,2,36),      {,}(0,240,0),     {-}(0,6,96),      {.}(1,36,128),    {/}
(107,221,96),  {0}(38,34,112),   {1}(105,36,240),  {2}(225,97,224),  {3}
(53,241,16),   {4}(248,113,224), {5}(36,233,96),   {6}(241,36,128),  {7}
(105,105,96),  {8}(105,113,32),  {9}(102,6,96),    {:}(102,6,98),    {;}
(18,66,16),    {<}(15,15,0),     {=}(132,36,128),  {>}(105,32,32),   {?}

(105,249,144), {a}(233,233,224), {b}
(105,137,96),  {c}(233,153,224), {d}(248,232,240), {e}(248,232,128), {f}
(105,139,96),  {g}(153,249,144), {h}(114,34,112),  {i}(17,25,96),    {j}
(154,202,144), {k}(136,136,240), {l}(159,153,144), {m}(157,185,144), {n}
(105,153,96),  {o}(233,232,128), {p}(105,155,112), {q}(233,234,144), {r}
(120,97,224),  {s}(114,34,32),   {t}(153,153,96),  {u}(153,150,96),  {v}
(153,187,96),  {w}(153,105,144), {x}(153,114,64),  {y}(242,72,240))  {z};

var
 tdelay,index,curx,x,cury,i,j,backcolor,
 testdriver,mode,driver,errcode,last,under,textcolor: integer;
 ans: char;
 vgastr: string;
 temppal,colors: paltype;


{$L video}

procedure initvga; external;
procedure setpix(x,y: integer; pcolor: byte); external;
function  getpix(x,y: integer ): byte; external;

{$F+}

procedure loadpal(s: string);
var palfile: file of paltype;
begin
 assign(palfile,s);
 reset(palfile);
 read(palfile,colors);
 close(palfile);
end;

procedure set256Colors(var pal : paltype); assembler;
asm
 mov ax, 1012h
 mov bx, 0
 mov cx, 256
 les dx, Pal
 int 10h
end;

procedure save;
var vgadata: file of screentype;
    temp: ^screentype;
begin
 new(temp);
 setpix(curx,cury,under);
 assign(vgadata,vgastr+'.sga');
 reset(vgadata);
 for i:=0 to 199 do
  for j:=0 to 319 do
    temp^[i,j]:=getpix(j,i);
 write(vgadata,temp^);
 for i:=0 to 199 do
  for j:=0 to 319 do
    temp^[i,j]:=getpix(j,i+200);
 write(vgadata,temp^);
 close(vgadata);
 dispose(temp);
end;

procedure load;
var vgadata: file of screentype;
    temp: ^screentype;
begin
 new(temp);
 assign(vgadata,vgastr+'.sga');
 reset(vgadata);
 read(vgadata,temp^);
 for i:=0 to 199 do
  for j:=0 to 319 do
   setpix(j,i,temp^[i,j]);
 read(vgadata,temp^);
 for i:=0 to 199 do
  for j:=0 to 319 do
   setpix(j,i+200,temp^[i,j]);
 close(vgadata);
 dispose(temp);
 last:=getpix(curx,cury);
 under:=getpix(curx,cury);
end;

procedure savepalette;
var palfile: file of paltype;
begin
 assign(palfile,vgastr+'.pal');
 reset(palfile);
 write(palfile,colors);
 close(palfile);
 set256colors(colors);
end;

procedure myswap(a,b: byte);
var c: colortype;
begin
 c:=colors[a];
 colors[a]:=colors[b];
 colors[b]:=c;
end;

procedure converterasdfasd;
var temp: ^screentype;
begin
 new(temp);
 for i:=0 to 199 do
  for j:=0 to 319 do
   temp^[i,j]:=getpix(j,i);
 for i:=0 to 199 do
  for j:=0 to 319 do
   begin
    setpix(j,i*2,temp^[i,j]);
    setpix(j,i*2+1,temp^[i,j]);
   end;
 dispose(temp);
end;

procedure readpalette;
var palfile: file of paltype;
begin
 assign(palfile,vgastr+'.pal');
 reset(palfile);
 read(palfile,colors);
 close(palfile);
 set256colors(colors);
end;

procedure mainloop;
begin
 repeat
   setpix(curx,cury,getpix(curx,cury)+2);
   if keypressed then
   begin
   ans:=readkey;
   case upcase(ans) of
    #0:begin
        ans:=readkey;
        setpix(curx,cury,under);
        case ans of
         #72:if cury=0 then cury:=399 else dec(cury);
         #80:if cury=399 then cury:=0 else inc(cury);
         #75:if curx=0 then curx:=319 else dec(curx);
         #77:if curx=319 then curx:=0 else inc(curx);
         #71:begin curx:=(curx div 10) - 1; curx:=curx*10 mod 320; end;
         #79:begin curx:=(curx div 10) + 1; curx:=curx*10 mod 320; end;
         #73:begin cury:=(cury div 10) - 1; cury:=cury*10 mod 400; end;
         #81:begin cury:=(cury div 10) + 1; cury:=cury*10 mod 400; end;
        end;
        under:=getpix(curx,cury);
       end;
    ' ':under:=last;
    'S':save;
    'L':load;
    '1':begin under:=0; last:=0; end;
    '2':begin under:=16; last:=16; end;
    '3':begin under:=32; last:=32; end;
    '4':begin under:=48; last:=48; end;
    '5':begin under:=64; last:=64; end;
    '6':begin under:=80; last:=80; end;
    '7':begin under:=96; last:=96; end;
    '8':begin under:=112; last:=112; end;
    '9':begin under:=128; last:=128; end;
    'Q':begin under:=144; last:=144; end;
    'W':begin under:=160; last:=160; end;
    'E':begin under:=176; last:=176; end;
    'R':begin under:=192; last:=192; end;
    'T':begin under:=208; last:=208; end;
    '+':begin inc(under); last:=under; end;
    '-':begin dec(under); last:=under; end;
    'S':save;
    'L':load;
   end;
   end;
 until ans=#59;
end;

begin
 initvga;
 vgastr:=paramstr(1);

 x:=100;
 curx:=0;
 cury:=0;
 load;
 readpalette;
 mainloop;
 textmode(co80);
end.