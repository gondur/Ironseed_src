program makescreen;
uses graph, crt, gmouse, data;

type
 icontype= array[1..17,1..15] of byte;
 fonttype= array[1..3] of byte;
 aniscrtype= array[0..34,0..49] of byte;
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
 aniscr: aniscrtype;

procedure save;
var vgadata: file of screentype;
begin
 screen[cury,curx]:=under;
 assign(vgadata,vgastr+'.vga');
 reset(vgadata);
 write(vgadata,screen);
 close(vgadata);
end;

procedure load;
var vgafile: file of screentype;
begin
 assign(vgafile,vgastr+'.vga');
 reset(vgafile);
 read(vgafile,screen);
 close(vgafile);
 last:=screen[cury,curx];
 under:=screen[cury,curx];
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

procedure readpalette;
var palfile: file of paltype;
begin
 assign(palfile,vgastr+'.pal');
 reset(palfile);
 read(palfile,colors);
 close(palfile);
 set256colors(colors);
end;

procedure showani;
var index: integer;
begin
 for i:=0 to 34 do
  move(screen[i],aniscr[i],50);
 index:=-1;
 repeat
  for index:=0 to 29 do
   begin
    if index>0 then
     for i:=0 to 34 do
      move(screen[i+(index div 6)*35,(index mod 6)*50],screen[i],50)
    else for i:=0 to 34 do
     move(aniscr[i],screen[i],50);
    delay(tslice);
   end;
  delay(tslice*4);
  for index:=29 downto 0 do
   begin
    if index>0 then
    for i:=0 to 34 do
     move(screen[i+(index div 6)*35,(index mod 6)*50],screen[i],50)
    else for i:=0 to 34 do
     move(aniscr[i],screen[i],50);
    delay(tslice);
   end;
  delay(tslice*4);
 until fastkeypressed;
 for i:=0 to 34 do
  move(aniscr[i],screen[i],50);
end;

procedure mainloop;
begin
 repeat
   inc(screen[cury,curx],3);
   if fastkeypressed then
   begin
   ans:=readkey;
   case upcase(ans) of
    #0: begin
         ans:=readkey;
         screen[cury,curx]:=under;
         case ans of
          #72: if cury<1 then cury:=199 else dec(cury);
          #80: if cury>198 then cury:=0 else inc(cury);
          #75: if curx<1 then curx:=319 else dec(curx);
          #77: if curx>318 then curx:=0 else inc(curx);
          #71: begin
                if curx<0 then curx:=0;
                curx:=(curx div 10) - 1;
                if curx<0 then curx:=31;
                curx:=(curx*10) mod 320;
               end;
          #79: begin
                if curx>319 then curx:=319;
                curx:=(curx div 10) + 1;
                curx:=(curx*10) mod 320;
               end;
          #73: begin
                if cury<0 then cury:=0;
                cury:=(cury div 10) - 1;
                if cury<0 then cury:=19;
                cury:=(cury*10) mod 200;
               end;
          #81: begin
                if cury>199 then cury:=199;
                cury:=(cury div 10) + 1;
                cury:=(cury*10) mod 200;
               end;
          #61: showani;
          #65: fillchar(screen,64000,under);
          #67: fillchar(screen[cury,curx],320-curx,under);
          #68: for j:=cury to 199 do
                screen[j,curx]:=under;
         end;
         under:=screen[cury,curx];
        end;
    ' ': under:=last;
    'S': save;
    'L': load;
    '1': begin under:=0; last:=0; end;
    '2': begin under:=16; last:=16; end;
    '3': begin under:=32; last:=32; end;
    '4': begin under:=48; last:=48; end;
    '5': begin under:=64; last:=64; end;
    '6': begin under:=80; last:=80; end;
    '7': begin under:=96; last:=96; end;
    '8': begin under:=112; last:=112; end;
    '9': begin under:=128; last:=128; end;
    'Q': begin under:=144; last:=144; end;
    'W': begin under:=160; last:=160; end;
    'E': begin under:=176; last:=176; end;
    'R': begin under:=192; last:=192; end;
    'T': begin under:=208; last:=208; end;
    '+': begin inc(under); last:=under; end;
    '-': begin dec(under); last:=under; end;
    'S': save;
    'L': load;
   end;
   end;
 until ans=#59;
end;

begin
 tslice:=120;
 vgastr:=paramstr(1);
 val(paramstr(1),x,j);
 if j<>0 then x:=125;
 randomize;
 textcolor:=31; backcolor:=0;
 curx:=0;
 cury:=0;
 load;
 readpalette;
 ans:=' ';
 mainloop;
 closegraph;
end.