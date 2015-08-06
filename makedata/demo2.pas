program seefire;

{$M 3000,214000,214000}

uses graph, crt;


const
 maxlines= 1;
 strs : array[0..maxlines] of string[40] =
('CHANNEL 7','DESTINY: VIRTUAL');

type
 Image = RECORD
   ImageP: POINTER;
   X: WORD;
   Y: WORD;
  END;
 ballpic = array[0..100,0..100] of byte;
 paltype = array[0..255,1..3] of byte;
 screentype = array[0..199,0..319] of byte;
 fonttype = array[1..3] of byte;
const
  font: array[1..55] of fonttype=(
(0,0,0),       { } (102,96,96),   {!} (85,80,0),     {"} (34,0,0),      {'}
(36,68,32),    {(} (66,34,64),    {)} (9,105,0),     {*} (4,228,0),     {+}
(0,2,36),      {,} (0,240,0),     {-} (0,0,32),      {.} (1,36,128),    {/}
(107,221,96),  {0} (98,34,240),   {1} (241,104,240), {2} (241,33,224),  {3}
(153,241,16),  {4} (248,113,224), {5} (248,249,240), {6} (241,17,16),   {7}
(249,105,240), {8} (249,241,16),  {9} (102,6,96),    {:} (102,6,98),    {;}
(18,66,16),    {<} (15,15,0),     {=} (132,36,128),  {>} (105,32,32),   {?}
(121,185,144), {a} (249,169,240), {b} (248,136,240), {c} (233,153,224), {d}
(240,200,240), {e} (248,232,128), {f} (248,153,240), {g} (153,249,144), {h}
(114,34,112),  {i} (241,25,96),   {j} (158,153,144), {k} (136,136,240), {l}
(159,153,144), {m} (233,153,144), {n} (249,153,240), {o} (249,152,128), {p}
(105,155,112), {q} (249,169,144), {r} (132,33,224),  {s} (114,34,32),   {t}
(153,153,240), {u} (153,153,96),  {v} (153,187,96),  {w} (153,105,144), {x}
(153,113,16),  {y} (242,72,240),  {z} (9,36,144));   {%}
var
  screen: screentype absolute $A000:0000;
  colors: paltype;
  s,s2: ^screentype;
  water,waterindex,j2,ofsx,index,alt,radius,c,ecl,m,r2,i,j: integer;
  part2,part,c2,y: real;

{$L mover2}
{$L vga256}
procedure vgadriver; external;
procedure mymove2(var src,tar; count: integer); external;

procedure errorhandler(s: string; errtype: integer);
begin
 closegraph;
 writeln;
 case errtype of
  1: writeln('File Error: ',s);
  2: writeln('Mouse Error: ',s);
  3: writeln('Sound Error: ',s);
  4: writeln('EMS Error: ',s);
  5: writeln('Fatal File Error: ',s);
  6: writeln('Program Error: ',s);
  7: writeln('Music Error: ',s);
 end;
 halt(4);
end;

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

procedure loadpal(s: string);
var palfile: file of paltype;
begin
 assign(palfile,s);
 reset(palfile);
 if ioresult<>0 then errorhandler(s,1);
 read(palfile,colors);
 if ioresult<>0 then errorhandler(s,5);
 close(palfile);
end;

procedure set256Colors(pal: paltype); assembler;
asm
 mov ax, 1012h
 mov bx, 0
 mov cx, 256
 les dx, Pal
  int 10h
end;

function testbit(b,bit: byte) : boolean; assembler;
asm
 mov cl, bit
 mov bl, 1
 shl bl, CL
 mov al, 0
 test b, bl
 jz @@no
 inc al
@@no:
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
 loadpal('landform.pal');
 set256colors(colors);
 setgraphbufsize(0);
 checksnow:=false;
end;

procedure rotate;
label endcheck;
begin
 for i:=6 to 2*r2+4 do
   begin
    y:=sqrt(radius-sqr(i-r2-5));
    m:=round((r2-y)*c2);
    part:=r2/y;
    alt:=0;
    for j:=1 to 2*r2+10 do
     begin
      index:=round(j*part);
      if index>2*r2+10 then goto endcheck;
      ofsx:=j+m;
      if (ecl>170) then alt:=(index-ecl+186) div 2
       else if (ecl<171) and (index<ecl) then alt:=(ecl-index) div 2
       else alt:=0;
      if alt<0 then alt:=0;
      if (index+c)>320 then j2:=index+c-320
       else j2:=index+c;
      if (alt<6) and (s^[i,j2]<water) then s2^[i,ofsx]:=waterindex+6-alt
       else if s^[i,j2]<water then s2^[i,ofsx]:=waterindex
       else if alt>round((s^[i,j2]-water)*part2) then s2^[i,ofsx]:=1
       else s2^[i,ofsx]:=round((s^[j2,i]-water)*part2)-alt+4;
endcheck:
     end;
   end;
 mymove2(s2^,screen,16000);
end;

procedure generate;
var x1,y1,b: integer;
    a: longint;
begin
 fillchar(s^,64000,30);
 for b:=1 to 5 do
  begin
   x1:=random(320);
   y1:=random(200);
   for a:=1 to 105000 do
    begin
     x1:=x1-1+random(3);
     y1:=y1-1+random(3);
     if x1>320 then x1:=0 else if x1<0 then x1:=319;
     if y1>200 then y1:=0 else if y1<0 then y1:=199;
     if s^[y1,x1]<250 then s^[y1,x1]:=s^[y1,x1]+5;
    end;
  end;
end;

begin
 readygraph;
 new(s);
 new(s2);
 generate;
 fillchar(s2^,64000,0);

 c:=0;
 ecl:=50;
 c2:=1.09;
 radius:=5000;
 r2:=round(sqrt(radius));
 water:=0;
 waterindex:=41;
 part2:=28/(255-water);

 repeat
  inc(c,5);
  if c>320 then c:=0;
  rotate;

 until fastkeypressed;
 dispose(s);
 dispose(s2);
 closegraph;
 writeln(#13+#10+#10+'(C) 1994 by Robert Morgan, Channel 7, Destiny: Virtual.');
end.