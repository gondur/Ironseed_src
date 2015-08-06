unit graphics;

interface
const
 minmemory= 50;
type
 fonttype= array[1..3] of byte;
 colortype= array[1..3] of byte;
 paltype= array[0..255] of colortype;
 screentype= array[0..199,0..319] of byte;
const
 font: array[1..55] of fonttype=(
(0,0,0),       { } (102,96,96),   {!} (85,80,0),     {"} (34,0,0),      {'}
(36,68,32),    {(} (66,34,64),    {)} (9,105,0),     {*} (4,228,0),     {+}
(0,2,36),      {,} (0,240,0),     {-} (0,0,32),      {.} (1,36,128),    {/}
(107,221,96),  {0} (38,34,112),   {1} (105,36,240),  {2} (225,97,224),  {3}
(53,241,16),   {4} (248,113,224), {5} (36,233,96),   {6} (241,36,128),  {7}
(105,105,96),  {8} (105,113,32),  {9} (102,6,96),    {:} (102,6,98),    {;}
(18,66,16),    {<} (15,15,0),     {=} (132,36,128),  {>} (105,32,32),   {?}
(105,249,144), {a} (233,233,224), {b} (105,137,96),  {c} (233,153,224), {d}
(240,232,240), {e} (248,232,128), {f} (105,139,96),  {g} (153,249,144), {h}
(114,34,112),  {i} (17,25,96),    {j} (154,202,144), {k} (136,136,240), {l}
(159,153,144), {m} (157,185,144), {n} (105,153,96),  {o} (233,232,128), {p}
(105,155,112), {q} (233,170,144), {r} (120,97,224),  {s} (114,34,32),   {t}
(153,153,96),  {u} (153,150,96),  {v} (153,187,96),  {w} (153,105,144), {x}
(153,114,64),  {y} (242,72,240),  {z} (9,36,144));   {%}
var
 colors: paltype;
 screen: screentype absolute $A000:$0000;
 tcolor,bkcolor,tslice: integer;

procedure errorhandler(s: string;errtype: integer);
procedure setrgb256(palnum,r,g,b: byte);
procedure getrgb256(palnum: byte; var r,g,b);
procedure set256colors(pal : paltype);
procedure printxy(x1,y1: integer; s: string);
procedure fading;
procedure fadein;
procedure loadscreen(s: string);
procedure loadpal(s: string);
function testbit(b : byte; bit : byte) : boolean;
function fastkeypressed : boolean;
procedure fadein2;
procedure mymove(var src,tar; count: integer);

implementation

uses crt, graph;

var
 i,j: integer;

{$L vga256}
{$L mover}
procedure vgadriver; external;
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
 if ioresult<>0 then errorhandler(s,1);
 read(vgafile,screen);
 if ioresult<>0 then errorhandler(s,5);
 close(vgafile);
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

procedure getrgb256(palnum: byte; var r,g,b); assembler;
asm
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

procedure printxy(x1,y1: integer; s: string);
var letter,a,index,t: integer;
begin
 t:=tcolor;
 for j:=1 to length(s) do
  begin
   tcolor:=t;
   case s[j] of
    ' ' ..'"':letter:=ord(s[j])-31;
    ''''..'?':letter:=ord(s[j])-35;
    'A' ..'Z':letter:=ord(s[j])-36;
    '%': letter:=55;
    else letter:=1;
   end;
   index:=1;
   for i:=1 to 6 do
    begin
     for a:=4 to 7 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j*5+7-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j*5+7-a]:=bkcolor;
     dec(tcolor,2);
     inc(i);
     for a:=0 to 3 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j*5+3-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j*5+3-a]:=bkcolor;
     inc(index);
     dec(tcolor,2);
    end;
    for i:=1 to 6 do screen[y1+i,x1+j*5+4]:=bkcolor;
  end;
 tcolor:=t;
end;

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

procedure fading;
var a: integer;
    temppal: paltype;
begin
 mymove(colors,temppal,192);
 for a:=30 downto 1 do
  begin
   for j:=0 to 255 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*temppal[j,i]/30);
   set256colors(temppal);
   delay(tslice);
  end;
 fillchar(temppal,768,0);
 set256colors(temppal);
 delay(tslice);
end;

procedure fadein;
var a: integer;
    temppal: paltype;
begin
 fillchar(temppal,768,0);
 for a:=0 to 15 do
  begin
   for j:=0 to 15 do
    for i:=a to 15 do
     temppal[j*16+i]:=colors[j*16+a];
   set256colors(temppal);
   delay(tslice*2);
  end;
 set256colors(colors);
 delay(tslice);
end;

procedure fadein2;
var a: integer;
    temppal: paltype;
begin
 for j:=0 to 255 do for i:=1 to 3 do temppal[j,i]:=0;
 for a:=1 to 25 do
  begin
   for j:=0 to 255 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/25);
   set256colors(temppal);
   delay(tslice);
  end;
 set256colors(colors);
end;

begin
 checkbreak:=false;
 readygraph;
end.
