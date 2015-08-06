program screeneditorforportaits;
{$M 2048,0,145000,145000}
{$L vga256}
{$L mover2}

{**************************************************************************

 VGA RAW DATA SCREEN EDITOR

    - 1.000 MAIN ROUTINES
    - 1.100 x10 PEL JUMPS/BUGFIXES/ERROR CHECKING
    - 1.500 PALMODE TOGGLE/BUGFIXES/OPTIMIZED
    - 1.600 PALEDIT
    - 1.610 MEMORY RESTRICTIONS/COSMETICS
    - 1.620 CHANGED UNDERPALMODE TO HEAP NOT DATA
    - 1.700 CIRCLES ADDED
    - 1.710 CIRCLE BUGFIX
    - 1.730 COSMETICS/COORDINATE MODE/MULTIPLE PALCOLOR MODE
    - 1.740 BUGFIX IN PALADJUSTMENTS
    - 1.800 LINE SUPPORT ADDED
    - 1.810 BAR SUPPORT
    - 1.820 RECTANGLE SUPPORT
    - 1.840 PALEDIT ALLOWS EDITING OF MORE THAN 16 COLORS
    - 1.845 BUGFIX
    - 1.900 BETTER ERROR CHECKING/REMEMBERS TO CREATE NEW PAL IF NECESSARY
    - 1.950 MORE INFO IN STATUS/PALSTR/BUGFIX IN WRAPPING
    - 1.955 SUPPORTS ELLIPSES
    - 2.000 PALEDIT SUPPORTS <16 COLOR EDITING
    - 2.051 BUGFIXES
    - 2.100 VERTICAL FLIP
    - 2.200 HORIZONTAL FLIP
    - 2.300 MOVE/COPY BLOCKS SUPPORTED
    - 2.400 MASSIVE OVERHAUL, MODULARIZED ALL GENERAL EFFECTS(OPTIONS)
    - 2.450 MOVE OPERATIONS FIXED
    - 2.500 BUGFIXES IN UNDER COLOR/DO ALT ON AN AREA
    - 2.600 ROTATE 90ø SUPPORTED
    - 2.650 BUGFIX IN PAL PARTITIONING
    - 2.651 'Z' PICKS UP UNDER COLOR
    - 2.700 HELP SCREEN/COSMETICS
    - 2.710 BUGFIX IN FADE AREA
    - 2.800 DOS SHELL SUPPORTED
    - 2.900 PARTITIONING(RESIZING) SUPPORTED/COSMETICS IN DOS SHELL
    - 2.910 COSMETICS
    - 2.920 DEFAULT PALETTE MUST BE IN EXECUTED DIRECTORY/COSMETICS
    - 2.930 LOTS OF LITTLE STUFF
    - 2.931 MORE AND MORE LITTLE STUFF
    - 2.935 NASTY BUG IN PALEDIT CAUSING FUNNY COLORS

    * UNREGISTERED VERSION 1 HAS ALL FUNCTIONS BUT SHRINKS, FADES, FLIPS,
       ROTATES, COPY, AND DOSSHELL

    - 2.937 PATERN FILLS SUPPORTED/CHANGED A FEW OF THE HELP DESCRIPTIONS
    - 2.939 DIFFERENT LINE STYLES SUPPORTED/CHARANI REMOVED/SETRGB256 ADDED/GARBAGE REMOVED
    - 2.940 BUGFIXES/COSMETICS/MORE MEMORY!
    - 2.941 RECTANGLES ALSO ALLOW LINE STYLES
    - 2.943 FILLED CIRCLES
    - 2.944 FILL PATTERNS FOR CIRCLES
    - 2.945 MINOR INTERNALS
    - 2.946 MINOR STUPID INSECTOID
    - 2.948 NO LONGER CREATES FILES THAT ARE NOT FOUND
    - 2.950 LIMITED MOUSE SUPPORT
    - 2.960 MOUSE SUPPORT IN GENERAL OPTIONS (FIRST LEVEL ONLY)
    - 2.970 MOUSE SUPPORT IN GENERAL OPTIONS (ALL LEVELS) AND CIRCLES
    - 2.980 ABILITY TO ENTER TEXT MESSAGES USING DEFAULT FONT
    - 2.981 BUG FIX IN WRITING TEXT
    - 2.982 BUG FIX IN WRITING TEXT/MOVER CHANGED TO NEAR PROC (FASTER)
    - 2.983 HIGHLIGHT COLOR DARKER
    - 2.985 BETTER PARTITIONING/WAIT PROC REMOVED/TITLE AT END NOW
    - 2.990 LOAD COMMAND ALLOWS LOADING OTHER FILES
    - 3.000 CLIPBOARD FUNCTIONS
    - 3.100 SAVE CLIPBOARD TO FILE/VIEWING CLIPBOARD/LOTS OF COSMETICS
    - 3.150 LITTLE BIT LARGER STATUS BAR (MORE SPACE FOR INFO)
    - 3.200 SAVE CLIPBOARD ONLY ON CHANGE/EXIT WARNING/BUGS IN STATUS BAR
    - 3.201 LONGER VGA AND PAL STRINGS/COSMETICS
    - 3.202 FULL DOCS WRITTEN!/A FEW KEY CHANGES
    - 3.203 HEAP OVERFLOW ERROR ON EXIT
    - 3.21  RECTANGLES AND BARS MERGED/CLIPBOARD Y 1 LARGER/,. IN FUNCTIONS
    - 3.22  ABILITY TO FADE,BRIGHTEN WHILE MOVING BLOCK/MOVE BLOCK STARTS AT
             CURSOR POS RATHER THAN CENTER
    - 3.23  CLIPBOARD ERROR WITH SIZE/PARTITIONING OF PALETTE SMALLER
    - 3.233 MASKING FUNCTION IN MOVE BLOCK/BUG IN PARTITIONING WITH MOUSE
    - 3.234 MASKING FUNCTION AND FADE,BRIGHTEN IN GRAB BLOCK
    - 3.235 KEY CHANGES
    - 3.236 PARTITIONING USING BITMAP SCALING/CLIPBOARD BUG FIXED (MAYBE)

  Robert Morgan
  Channel 7
  Destiny: Virtual

  (C) Dec. 31, 1993

**************************************************************************}

uses graph, crt, dos;
const
 maxpaly= 23;
 maxyonpal= 176;
 cordofs= 6;
 tick1= 3;
 tick2= 13;
 graycolor= 26;
type
 underpaltype= array[0..maxpaly,0..319] of byte;
 colortype= array[1..3] of byte;
 paltype= array[0..255] of colortype;
 screentype= array[0..199,0..319] of byte;
 fonttype= array[1..3] of byte;
 portraittype= array[0..69,0..69] of byte;
const
 cr= #13#10;
 version= 3.236;
 font: array[1..55] of fonttype=
  ((0,0,0),       { } (102,96,96),   {!} (85,80,0),     {"} (34,0,0),      {'}
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
 curx,cury,i,j,backcolor,paly,palcur,tcolor,bkcolor,multimode,
  r,rx,ry,mdx,mdy,multimode2,clipx,clipy: integer;
 under,last,change: byte;
 vgastr,palstr: string[40];
 pathstr,curpath: string[79];
 underpal: ^underpaltype;
 mouseinstalled,palmodeon,done,donepal,coordon,palchange,
  clipboardchange: boolean;
 colors: paltype;
 screen: screentype absolute $A000:0000;
 ans: char;
 clipboard,t: ^screentype;
 str1,str2: string[3];

procedure vgadriver; external;
procedure mymove2(var src,tar; count: integer); external;

procedure drawtitlemessage;
begin
 textcolor(5);
 writeln(cr,cr,cr,cr,' CHANNEL 7, DESTINY: VIRTUAL');
 textcolor(9);
 writeln('        ROBERT MORGAN');
 textcolor(14);
 writeln('     Screen Edit  v',version:0:3,cr);
 textcolor(15);
end;

procedure errorhandler(s: string; errtype: integer);
begin
 closegraph;
 writeln;
 writeln;
 case errtype of
  1: writeln('Opening File Error: ',s);
  5: writeln('Read/Write File Error: ',s);
  6: writeln('Program Error: ',s);
  7: writeln('DOS Error: ',s);
 end;
 halt(4);
end;

{$F+}
function testit : integer; assembler;
{$F-}
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
 setgraphbufsize(0);
 checksnow:=false;
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
var letter,a,index: integer;
begin
 for j:=1 to length(s) do
  begin
   case s[j] of
    ' ' ..'"':letter:=ord(s[j])-31;
    ''''..'?':letter:=ord(s[j])-35;
    'A' ..'Z':letter:=ord(s[j])-36;
    '%': letter:=55;
    '\': letter:=12;
    else letter:=1;
   end;
   index:=1;
   for i:=1 to 6 do
    begin
     for a:=4 to 7 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j*5+7-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j*5+7-a]:=bkcolor;
     inc(i);
     for a:=0 to 3 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j*5+3-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j*5+3-a]:=bkcolor;
     inc(index);
    end;
    if bkcolor<255 then for i:=1 to 6 do screen[y1+i,x1+j*5+4]:=bkcolor;
  end;
end;

procedure drawpaleditscreen;
begin
 for i:=4 to 176 do
  fillchar(screen[i,34],172,0);
 setcolor(255);
 rectangle(35,5,204,175);
 rectangle(37,7,202,173);
 for j:=0 to 255 do
  for i:=0 to 8 do
   fillchar(screen[(j div 16)*10+i+10,(j mod 16)*10+40],9,j);
 palcur:=last;
 for i:=74 to 126 do
  fillchar(screen[i,214],92,0);
 rectangle(215,75,304,125);
 rectangle(217,77,302,123);
 printxy(240,82, '+ Q  W  E');
 printxy(240,112,'- A  S  D');
end;

procedure writecolorstats;
var str1,str2,str3: string[3];
begin
 str(colors[palcur,1]:3,str1);
 str(colors[palcur,2]:3,str2);
 str(colors[palcur,3]:3,str3);
 printxy(240,97,str1+str2+str3);
end;

procedure undocursor;
begin
 if multimode=0 then
  begin
   fillchar(screen[((palcur-multimode2+1) div 16)*10+9,((palcur-multimode2+1) mod 16)*10+39],1+10*multimode2,0);
   fillchar(screen[((palcur-multimode2+1) div 16)*10+19,((palcur-multimode2+1) mod 16)*10+39],1+10*multimode2,0);
   for i:=0 to 10 do
    begin
     screen[((palcur-multimode2+1) div 16)*10+9+i,((palcur-multimode2+1) mod 16)*10+39]:=0;
     screen[(palcur div 16)*10+9+i,(palcur mod 16)*10+49]:=0;
    end;
  end
 else
  begin
   fillchar(screen[(palcur div 16)*10+9-10*(multimode-1),39],161,0);
   fillchar(screen[(palcur div 16)*10+9+10*multimode-10*(multimode-1),39],161,0);
   for i:=0 to 10*multimode do
    begin
     screen[(palcur div 16)*10-10*(multimode-1)+9+i,39]:=0;
     screen[(palcur div 16)*10-10*(multimode-1)+9+i,199]:=0;
    end;
  end;
end;

procedure drawcursor;
begin
 if multimode=0 then
  begin
   fillchar(screen[((palcur-multimode2+1) div 16)*10+9,((palcur-multimode2+1) mod 16)*10+39],1+10*multimode2,255);
   fillchar(screen[((palcur-multimode2+1) div 16)*10+19,((palcur-multimode2+1) mod 16)*10+39],1+10*multimode2,255);
   for i:=0 to 10 do
    begin
     screen[((palcur-multimode2+1) div 16)*10+9+i,((palcur-multimode2+1) mod 16)*10+39]:=255;
     screen[(palcur div 16)*10+9+i,(palcur mod 16)*10+49]:=255;
    end;
   for i:=0 to 11 do
    fillchar(screen[94+i,230],15,palcur);
  end
 else
  begin
   fillchar(screen[(palcur div 16)*10+9-10*(multimode-1),39],161,255);
   fillchar(screen[(palcur div 16)*10+9+10*multimode-10*(multimode-1),39],161,255);
   for i:=0 to 10*multimode do
    begin
     screen[(palcur div 16)*10-10*(multimode-1)+i+9,39]:=255;
     screen[(palcur div 16)*10-10*(multimode-1)+i+9,199]:=255;
    end;
   for i:=0 to 11 do
    fillchar(screen[94+i,230],15,palcur);
  end;
end;

procedure setpal(a,b,c: integer);
var part1,part2,part3: real;
begin
 if (colors[palcur,1]=63) and (a=1) then colors[palcur,1]:=0
  else if (colors[palcur,1]=0) and (a=-1) then colors[palcur,1]:=63
  else colors[palcur,1]:=colors[palcur,1]+a;
 if (colors[palcur,2]=63) and (b=1) then colors[palcur,2]:=0
  else if (colors[palcur,2]=0) and (b=-1) then colors[palcur,2]:=63
  else colors[palcur,2]:=colors[palcur,2]+b;
 if (colors[palcur,3]=63) and (c=1) then colors[palcur,3]:=0
  else if (colors[palcur,3]=0) and (c=-1) then colors[palcur,3]:=63
  else colors[palcur,3]:=colors[palcur,3]+c;
 if multimode>0 then
  begin
   part1:=colors[palcur,1]/(16*multimode+3);
   part2:=colors[palcur,2]/(16*multimode+3);
   part3:=colors[palcur,3]/(16*multimode+3);
   for i:=1 to 16*multimode-1 do
    begin
     colors[palcur-i,1]:=round(part1*(16*multimode-i)+3);
     colors[palcur-i,2]:=round(part2*(16*multimode-i)+3);
     colors[palcur-i,3]:=round(part3*(16*multimode-i)+3);
     for j:=1 to 3 do
      if colors[palcur-i,j]>63 then colors[palcur-i,j]:=63;
    end;
  end
 else if multimode2>1 then
  begin
   part1:=colors[palcur,1]/(multimode2+3);
   part2:=colors[palcur,2]/(multimode2+3);
   part3:=colors[palcur,3]/(multimode2+3);
   for i:=1 to multimode2-1 do
    begin
     colors[palcur-i,1]:=round(part1*(multimode2-i+3));
     colors[palcur-i,2]:=round(part2*(multimode2-i+3));
     colors[palcur-i,3]:=round(part3*(multimode2-i+3));
    end;
  end;
 set256colors(colors);
end;

procedure processpalkey;
begin
 ans:=readkey;
 case upcase(ans) of
   #0: begin
        undocursor;
        ans:=readkey;
        case ans of
         #77: if (multimode=0) and (multimode2=1) then inc(palcur)
               else if (multimode=0) and (palcur mod 16<15) then inc(palcur);
         #75: if (multimode=0) and (multimode2=1) then dec(palcur)
               else if (multimode=0) and ((palcur-multimode2+1) mod 16>0) then dec(palcur);
         #80: inc(palcur,16);
         #72: dec(palcur,16);
        end;
        if palcur<0 then palcur:=palcur+256
        else if palcur>255 then palcur:=palcur-256;
        if (multimode>0) and ((palcur-multimode*16+1)<0) then palcur:=255;
      end;
  #27: donepal:=true;
  'Q': setpal(1,0,0);
  'W': setpal(0,1,0);
  'E': setpal(0,0,1);
  'A': setpal(-1,0,0);
  'S': setpal(0,-1,0);
  'D': setpal(0,0,-1);
  '+': if multimode>0 then
        begin
         undocursor;
         inc(multimode);
         if multimode>16 then multimode:=16;
         palcur:=multimode*16-1;
        end
       else
        begin
         undocursor;
         inc(multimode2);
         if multimode2=17 then
          begin
           multimode:=2;
           multimode2:=15;
           palcur:=31;
          end
         else palcur:=multimode2-1;
        end;
  '-': if multimode>0 then
        begin
         undocursor;
         dec(multimode);
         if multimode=0 then palcur:=14;
        end
       else
        begin
         undocursor;
         dec(multimode2);
         if multimode2=0 then multimode2:=1;
         palcur:=multimode2-1;
        end;
 end;
 writecolorstats;
end;

procedure paledit;
var temppal: ^paltype;
begin
 new(t);
 new(temppal);
 temppal^:=colors;
 mymove2(screen,t^,16000);
 drawpaleditscreen;
 donepal:=false;
 multimode:=0;
 multimode2:=1;
 palcur:=last;
 writecolorstats;
 repeat
  drawcursor;
  if fastkeypressed then processpalkey;
 until donepal;
 mymove2(t^,screen,16000);
 dispose(t);
 last:=palcur;
 if not palchange then
  begin
   i:=0;
   for i:=0 to 255 do
    for j:=1 to 3 do
     if colors[i,j]<>temppal^[i,j] then
      begin
       palchange:=true;
       dispose(temppal);
       exit;
      end;
  end;
 dispose(temppal);
end;

procedure redrawpalmode;
begin
 for i:=0 to maxpaly do
  fillchar(screen[i+paly],320,0);
 setcolor(255);
 rectangle(0,paly+1,319,paly+maxpaly-1);
 for j:=0 to 255 do
  for i:=cordofs to cordofs+5 do
   screen[i+paly,j+2]:=j;
 under:=screen[cury,curx];
 rectangle(298,4+paly,317,19+paly);
 for i:=6 to 17 do
  fillchar(screen[i+paly,300],16,last);
 screen[paly+tick2,change+2]:=0;
 screen[paly+tick2,last+2]:=255;
 screen[paly+tick1,change+2]:=0;
 screen[paly+tick1,last+2]:=255;
 screen[paly+tick2+1,change+2]:=0;
 screen[paly+tick2+1,last+2]:=255;
 screen[paly+tick1+1,change+2]:=0;
 screen[paly+tick1+1,last+2]:=255;
 printxy(-3,paly+maxpaly-8,'VGA='+vgastr);
 printxy(145,paly+maxpaly-8,'PAL='+palstr);
end;

function checkmousegeneraloption: integer;
label done;
begin
 asm
  mov ax, 5
  mov bx, 0
   int 33h
  test bx, 1
  jnz done
  mov ax, 0Bh
   int 33h
  mov mdx, cx
  mov mdy, dx
 end;
 if (mdx=0) and (mdy=0) then
  begin
   checkmousegeneraloption:=0;
   exit;
  end;
 rx:=rx+mdx;
 if rx>319 then rx:=319
  else if rx<0 then rx:=0;
 ry:=ry+mdy;
 if ry>199 then ry:=199
  else if ry<0 then ry:=0;
 checkmousegeneraloption:=1;
 exit;
done:
 checkmousegeneraloption:=2;
end;

procedure doacircle;
var mouse,alt: integer;
    dx,dy: word;
    filled: boolean;
begin
 new(t);
 mymove2(screen,t^,16000);
 setcolor(last);
 setfillstyle(1,last);
 donepal:=false;
 if palmodeon then
  begin
   for i:=0 to maxpaly do
    mymove2(underpal^[i],screen[i+paly],80);
  end;
 screen[cury,curx]:=under;
 mymove2(screen,t^,16000);
 getaspectratio(dx,dy);
 filled:=false;
 alt:=1;
 rx:=curx;
 ry:=cury;
 circle(rx,ry,r);
 repeat
  mouse:=0;
  repeat
   if mouseinstalled then mouse:=checkmousegeneraloption;
  until (fastkeypressed) or (mouse>0);
  if mouse=0 then ans:=readkey
   else if mouse=2 then ans:=#13
   else ans:=' ';
  mymove2(t^,screen,16000);
  case upcase(ans) of
    #0: begin
         ans:=readkey;
         case ans of
          #80: if dy>1 then dec(dy,50);
          #72: inc(dy,50);
          #75: if dx>1 then dec(dx,50);
          #77: inc(dx,50);
         end;
         setaspectratio(dx,dy);
        end;
   #13: begin
         if not filled then circle(rx,ry,r)
          else pieslice(rx,ry,0,360,r);
         dispose(t);
         if palmodeon then
          begin
           for i:=0 to maxpaly do
            mymove2(screen[i+paly],underpal^[i],80);
           redrawpalmode;
          end;
         exit;
        end;
   #27: begin
         dispose(t);
         if palmodeon then
          begin
           for i:=0 to maxpaly do
            mymove2(screen[i+paly],underpal^[i],80);
           redrawpalmode;
          end;
         exit;
        end;
   'F': if not filled then filled:=true else filled:=false;
   'Z': begin
         if alt<11 then inc(alt) else alt:=0;
         setfillstyle(alt,last);
        end;
   '.': inc(r);
   ',': dec(r);
   '+': begin
         dec(last);
         setcolor(last);
         setfillstyle(alt,last);
        end;
   '-': begin
         inc(last);
         setcolor(last);
         setfillstyle(alt,last);
        end;
  end;
  if not filled then circle(rx,ry,r)
   else pieslice(rx,ry,0,360,r);
 until donepal;
 dispose(t);
end;

procedure gettarget(x1,y1,x2,y2: integer);
var quit,masking: boolean;
    mouse,a1,b1,a2,b2,alt: integer;
    a: byte;
begin
 quit:=false;
 rx:=x1;
 ry:=y1;
 if x1>x2 then begin a1:=x2; a2:=x1; end
  else begin a1:=x1; a2:=x2; end;
 if y1>y2 then begin b1:=y2; b2:=y1; end
  else begin b1:=y1; b2:=y2; end;
 for i:=b1 to b2 do
  move(t^[i,a1],screen[ry+i-b1,rx],a2-a1+1);
 alt:=0;
 masking:=false;
 repeat
  mouse:=0;
  repeat
   if mouseinstalled then mouse:=checkmousegeneraloption;
  until (fastkeypressed) or (mouse>0);
  if mouse=0 then ans:=upcase(readkey)
   else if mouse=2 then ans:=#13
   else ans:=' ';
  mymove2(t^,screen,16000);
  case ans of
   #0: begin
        ans:=upcase(readkey);
        case ans of
         #72: if ry<1 then ry:=199 else dec(ry);
         #80: if ry>198 then ry:=0 else inc(ry);
         #75: if rx<1 then rx:=319 else dec(rx);
         #77: if rx>318 then rx:=0 else inc(rx);
         #71: begin
               if rx<0 then rx:=0;
               rx:=(rx div 10) - 1;
               if rx<0 then rx:=31;
               rx:=(rx*10) mod 320;
              end;
         #79: begin
               if rx>319 then rx:=319;
               rx:=(rx div 10) + 1;
               rx:=(rx*10) mod 320;
              end;
         #73: begin
               if ry<0 then ry:=0;
               ry:=(ry div 10) - 1;
               if ry<0 then ry:=19;
               ry:=(ry*10) mod 200;
              end;
         #81: begin
               if ry>199 then ry:=199;
               ry:=(ry div 10) + 1;
               ry:=(ry*10) mod 200;
              end;
        end;
       end;
   ',','-': dec(alt);
   '.','+': inc(alt);
   'M': if masking then masking:=false else masking:=true;
   #13: begin
         if masking then
          begin
           for i:=0 to b2-b1 do
            for j:=0 to a2-a1 do
             begin
              a:=alt+t^[i+b1,j+a1];
             if a<>255 then screen[ry+i,rx+j]:=a;
             end;
          end
         else
          for i:=0 to b2-b1 do
           for j:=0 to a2-a1 do
            screen[ry+i,rx+j]:=t^[i+b1,j+a1]+alt;
         exit;
        end;
   #27: quit:=true;
  end;
  if masking then
   begin
    for i:=0 to b2-b1 do
     for j:=0 to a2-a1 do
      begin
       a:=alt+t^[i+b1,j+a1];
      if a<>255 then screen[ry+i,rx+j]:=a;
      end;
   end
  else
   for i:=0 to b2-b1 do
    for j:=0 to a2-a1 do
     screen[ry+i,rx+j]:=t^[i+b1,j+a1]+alt;
 until quit;
 mymove2(t^,screen,16000);
end;

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

procedure gettarget2(x1,y1,x2,y2: integer);
var quit: boolean;
    curx,cury,a1,b1,a2,b2,mouse: integer;
begin
 quit:=false;
 curx:=160;
 cury:=100;
 if x1>x2 then begin a1:=x2; a2:=x1; end
  else begin a1:=x1; a2:=x2; end;
 if y1>y2 then begin b1:=y2; b2:=y1; end
  else begin b1:=y1; b2:=y2; end;
 rx:=a1;
 ry:=b1;
 for i:=b1 to b2 do
  move(t^[i,a1],clipboard^[i-b1],a2-a1+1);
 clipy:=b2-b1;
 clipx:=a2-a1;
 repeat
  mouse:=0;
  repeat
   if mouseinstalled then mouse:=checkmousegeneraloption;
  until (fastkeypressed) or (mouse>0);
  if mouse=0 then ans:=readkey
   else if mouse=2 then ans:=#13
   else
    begin
      mymove2(t^,screen,16000);
      scale(rx,ry,clipx,clipy,a2-a1+1,b2-b1,clipboard^,screen);
      ans:=' ';
    end;
  case ans of
    #0: begin
         mymove2(t^,screen,16000);
         ans:=readkey;
         case ans of
          #72: if b2>b1+1 then dec(b2);
          #80: inc(b2);
          #75: if a2>a1+1 then dec(a2);
          #77: inc(a2);
          #71: if a2-a1>10 then dec(a2,10);
          #79: inc(a2,10);
          #73: if b2-b1>10 then dec(b2,10);
          #81: inc(b2,10);
         end;
         scale(rx,ry,clipx,clipy,a2-a1+1,b2-b1,clipboard^,screen);
        end;
   #13: begin
         scale(rx,ry,clipx,clipy,a2-a1+1,b2-b1,clipboard^,screen);
         quit:=true;
        end;
   #27: begin
         mymove2(t^,screen,16000);
         quit:=true;
        end;
  end;
 until quit;
end;

procedure generaloption(opt: integer);
var mouse,x1,x2,y1,y2,alt: integer;
    masking: boolean;
    a: byte;
begin
 if (opt=10) and (clipx=0) and (clipy=0) then exit;
 new(t);
 rx:=curx;
 ry:=cury;
 masking:=false;
 if opt<3 then
  begin
   setcolor(last);
   setfillstyle(1,last);
  end
 else
  begin
   setrgb256(255,48,0,0);
   setwritemode(xorput);
   setcolor(255);
  end;
 donepal:=false;
 if palmodeon then
  begin
   for i:=0 to maxpaly do
    mymove2(underpal^[i],screen[i+paly],80);
  end;
 screen[cury,curx]:=under;
 mymove2(screen,t^,16000);
 case opt of
  1: alt:=1;
  6..8: alt:=3;
  else alt:=0;
 end;
 if opt=10 then
  for i:=0 to clipy do
   move(clipboard^[i],screen[ry+i,rx],clipx);
 repeat
  mouse:=0;
  repeat
   if mouseinstalled then mouse:=checkmousegeneraloption;
  until (fastkeypressed) or (mouse>0);
  if mouse=0 then ans:=upcase(readkey)
   else if mouse=2 then ans:=#13
   else ans:=' ';
  mymove2(t^,screen,16000);
  case ans of
    #0: begin
         ans:=readkey;
         case ans of
          #72: if ry>0 then dec(ry) else ry:=199;
          #80: if ry<199 then inc(ry) else ry:=0;
          #75: if rx>0 then dec(rx) else rx:=319;
          #77: if rx<319 then inc(rx) else rx:=0;
          #71: begin
                if rx<0 then rx:=0;
                rx:=(rx div 10) - 1;
                if rx<0 then rx:=31;
                rx:=(rx*10) mod 320;
               end;
          #79: begin
                if rx>319 then rx:=319;
                rx:=(rx div 10) + 1;
                rx:=(rx*10) mod 320;
               end;
          #73: begin
                if ry<0 then ry:=0;
                ry:=(ry div 10) - 1;
                if ry<0 then ry:=19;
                ry:=(ry*10) mod 200;
               end;
          #81: begin
                if ry>199 then ry:=199;
                ry:=(ry div 10) + 1;
                ry:=(ry*10) mod 200;
               end;
         end;
        end;
   #13: begin
         setwritemode(copyput);
         setrgb256(255,graycolor,graycolor,graycolor);
         if cury>ry then begin y1:=ry; y2:=cury; end
          else begin y1:=cury; y2:=ry; end;
         if curx>rx then begin x1:=rx; x2:=curx; end
          else begin x1:=curx; x2:=rx; end;
         case opt of
          0: line(curx,cury,rx,ry);
          1: bar(curx,cury,rx,ry);
          2: rectangle(curx,cury,rx,ry);
          3: for i:=y1 to y2 do
              move(t^[i,x1],screen[y2-i+y1,x1],x2-x1+1);
          4: for i:=y1 to y2 do
              for j:=x1 to x2 do
               screen[i,x2-j+x1]:=t^[i,j];
          5: gettarget(curx,cury,rx,ry);
          6: for i:=y1 to y2 do
              for j:=x1 to x2 do
               screen[i,j]:=screen[i,j]+alt;
          7: for i:=0 to alt do
              for j:=0 to alt do
               screen[cury+i,curx+j]:=t^[alt-j+cury,curx+i];
          8: gettarget2(curx,cury,rx,ry);
          9: begin
              for i:=y1 to y2 do
               move(screen[i,x1],clipboard^[i-y1],x2-x1+1);
              clipx:=x2-x1;
              clipy:=y2-y1;
              clipboardchange:=true;
             end;
         10: if masking then
              begin
               for i:=0 to clipy do
                for j:=0 to clipx do
                 begin
                  a:=alt+clipboard^[i,j];
                 if a<>255 then screen[ry+i,rx+j]:=a;
                 end;
              end
             else
              for i:=0 to clipy do
               for j:=0 to clipx do
                screen[ry+i,rx+j]:=clipboard^[i,j]+alt;
         end;
         dispose(t);
         if palmodeon then
          begin
           for i:=0 to maxpaly do
            mymove2(screen[i+paly],underpal^[i],80);
           redrawpalmode;
          end;
         setlinestyle(0,0,0);
         exit;
        end;
   #27: begin
         setlinestyle(0,0,0);
         setrgb256(255,graycolor,graycolor,graycolor);
         dispose(t);
         if palmodeon then
          begin
           for i:=0 to maxpaly do
            mymove2(screen[i+paly],underpal^[i],80);
           redrawpalmode;
          end;
         exit;
        end;
   ',': case opt of
         0,2: begin
             if alt>0 then dec(alt) else alt:=7;
             if alt div 4=0 then setlinestyle(alt,0,1)
              else setlinestyle(alt mod 4,0,3);
            end;
         1: begin
             if alt>0 then dec(alt) else alt:=11;
             setfillstyle(alt,last);
            end;
        end;
   '.': case opt of
         0,2: begin
             if alt<7 then inc(alt) else alt:=0;
             if alt div 4=0 then setlinestyle(alt,0,1)
              else setlinestyle(alt mod 4,0,3);
            end;
         1: begin
             if alt<11 then inc(alt) else alt:=0;
             setfillstyle(alt,last);
            end;
        end;
   'M': if opt=10 then
         begin
          if masking then masking:=false else masking:=true;
         end;
   'F': if opt=1 then opt:=2
         else if opt=2 then opt:=1;
   '+': case opt of
         0..2: begin
                inc(last);
                setcolor(last);
                setfillstyle(alt,last);
               end;
         6,7,8,10: inc(alt);
        end;
   '-': case opt of
         0..2: begin
                dec(last);
                setcolor(last);
                setfillstyle(alt,last);
               end;
         6,7,8,10: dec(alt);
        end;
  end;
  case opt of
    0: line(curx,cury,rx,ry);
    1: bar(curx,cury,rx,ry);
    6: begin
        if cury>ry then begin y1:=ry; y2:=cury; end
         else begin y1:=cury; y2:=ry; end;
        if curx>rx then begin x1:=rx; x2:=curx; end
         else begin x1:=curx; x2:=rx; end;
        for i:=y1 to y2 do
         for j:=x1 to x2 do
          screen[i,j]:=screen[i,j]+alt;
       end;
    7: rectangle(rx,ry,rx+alt,ry+alt);
   10: if masking then
        begin
         for i:=0 to clipy do
          for j:=0 to clipx do
           begin
            a:=alt+clipboard^[i,j];
           if a<>255 then screen[ry+i,rx+j]:=a;
           end;
        end
       else
        for i:=0 to clipy do
         for j:=0 to clipx do
          screen[ry+i,rx+j]:=clipboard^[i,j]+alt;
   else rectangle(curx,cury,rx,ry);
  end;
 until donepal;
 setlinestyle(0,0,0);
 setrgb256(255,graycolor,graycolor,graycolor);
end;

procedure saveclipboard;
var vgafile: file of screentype;
begin
 if (clipboardchange) and (clipx>0) and (clipy>0) then
  begin
   if clipy<199 then
    for i:=clipy+1 to 199 do
     fillchar(clipboard^[i],320,0);
   if clipx<319 then
    for i:=0 to clipy do
     fillchar(clipboard^[i,clipx+1],319-clipx,0);
   assign(vgafile,pathstr+'clip.vga');
   rewrite(vgafile);
   if ioresult<>0 then errorhandler('Saving Clipboard failure.',1);
   write(vgafile,clipboard^);
   if ioresult<>0 then errorhandler('Saving Clipboard failure.',5);
   close(vgafile);
  end;
 clipboardchange:=false;
end;

procedure savepalette;
var palfile: file of paltype;
begin
 palstr:=vgastr;
 assign(palfile,vgastr+'.pal');
 reset(palfile);
 if ioresult<>0 then
  begin
   rewrite(palfile);
   if ioresult<>0 then errorhandler(vgastr+'.PAL, creating',5);
  end;
 write(palfile,colors);
 if ioresult<>0 then errorhandler(vgastr+'.PAL, writing',5);
 close(palfile);
 set256colors(colors);
 palchange:=false;
end;

procedure save;
var vgadata: file of portraittype;
    p: ^portraittype;
begin
 saveclipboard;
 if palchange then savepalette;
 if palmodeon then
  begin
   for i:=0 to maxpaly do
    mymove2(underpal^[i],screen[i+paly],80);
  end;
 screen[cury,curx]:=under;
 new(p);
 for i:=0 to 69 do
  move(screen[i],p^[i],70);
 assign(vgadata,vgastr+'.vga');
 reset(vgadata);
 if ioresult<>0 then
  begin
   rewrite(vgadata);
   if ioresult<>0 then errorhandler(vgastr+'.VGA, creating',1);
  end;
 write(vgadata,p^);
 dispose(p);
 if ioresult<>0 then errorhandler(vgastr+'.VGA, writing',5);
 close(vgadata);
 if palmodeon then redrawpalmode;
end;

function getnewfilename: boolean;
var tempstr: string[40];
begin
 new(t);
 if palmodeon then
  begin
   for i:=0 to maxpaly do
    mymove2(underpal^[i],screen[i+paly],80);
  end;
 mymove2(screen,t^,16000);
 for i:=90 to 109 do
  fillchar(screen[i,45],220,0);
 setcolor(255);
 rectangle(45,90,264,109);
 rectangle(47,92,262,107);
 tempstr:=vgastr;
 rx:=length(tempstr)+1;
 if rx>40 then rx:=40;
 if length(tempstr)<30 then
  for j:=length(tempstr)+1 to 40 do tempstr[j]:=' ';
 tempstr[0]:=#40;
 setrgb256(254,63,0,0);
 tcolor:=255;
 bkcolor:=0;
 printxy(51,96,tempstr);
 tcolor:=255;
 repeat
  repeat
   bkcolor:=254;
   printxy(46+rx*5,96,tempstr[rx]);
   delay(50);
   bkcolor:=0;
   printxy(46+rx*5,96,tempstr[rx]);
   delay(50);
  until fastkeypressed;
  ans:=upcase(readkey);
  case ans of
   'A'..'Z',' ','0'..'9','''','\':
       begin
        if rx<40 then
         begin
          for j:=40 downto rx do tempstr[j]:=tempstr[j-1];
          tempstr[rx]:=ans;
          inc(rx);
         end else tempstr[rx]:=ans;
       end;
   #8: begin
        if rx>1 then dec(rx);
        for j:=rx to 39 do tempstr[j]:=tempstr[j+1];
        tempstr[40]:=' ';
       end;
   #0: begin
         ans:=readkey;
         case ans of
          #77: if rx<40 then inc(rx);
          #75: if rx>1 then dec(rx);
          #83: for j:=rx to 39 do tempstr[j]:=tempstr[j+1];
         end;
       end;
  end;
  printxy(51,96,tempstr);
 until (ans=#27) or (ans=#13);
 if ans=#13 then
  begin
   i:=40;
   while tempstr[i]=' ' do dec(i);
   tempstr[0]:=chr(i);
   vgastr:=tempstr;
   palstr:=tempstr;
   getnewfilename:=true;
  end
 else
  begin
   getnewfilename:=false;
   mymove2(t^,screen,16000);
   if palmodeon then redrawpalmode;
  end;
 dispose(t);
 set256colors(colors);
end;

procedure readpalette;
var palfile: file of paltype;
begin
 assign(palfile,palstr+'.PAL');
 reset(palfile);
 if ioresult<>0 then
  begin
   palstr:='DATA\CHAR';
   assign(palfile,palstr+'.PAL');
   reset(palfile);
   if ioresult<>0 then errorhandler(palstr+'.PAL',1);
  end;
 read(palfile,colors);
 if ioresult<>0 then errorhandler(palstr+'.PAL, reading',5);
 close(palfile);
 colors[255,1]:=24;
 colors[255,2]:=24;
 colors[255,3]:=24;
 set256colors(colors);
end;

procedure load(ask: boolean);
var vgafile: file of portraittype;
    p: ^portraittype;
begin
 if (ask) and (not getnewfilename) then exit;
 readpalette;
 assign(vgafile,vgastr+'.vga');
 reset(vgafile);
 if ioresult<>0 then
  begin
   fillchar(screen,64000,0);
   if palmodeon then
    begin
     for i:=0 to maxpaly do
      mymove2(screen[i+paly],underpal^[i],80);
     redrawpalmode;
    end;
   exit;
  end;
 new(p);
 read(vgafile,p^);
 if ioresult<>0 then errorhandler(vgastr+'.VGA reading',5);
 close(vgafile);
 fillchar(screen,64000,0);
 for i:=0 to 69 do
  move(p^[i],screen[i],70);
 dispose(p);
 last:=screen[cury,curx];
 under:=screen[cury,curx];
 if palmodeon then
  begin
   for i:=0 to maxpaly do
    mymove2(screen[i+paly],underpal^[i],80);
   redrawpalmode;
  end;
end;

procedure loadclipboard;
var vgafile: file of screentype;
begin
 new(clipboard);
 assign(vgafile,pathstr+'clip.vga');
 reset(vgafile);
 if ioresult<>0 then
  begin
   fillchar(clipboard^,64000,0);
   clipx:=0;
   clipy:=0;
   exit;
  end;
 read(vgafile,clipboard^);
 if ioresult<>0 then errorhandler('Loading ClipBoard failure.',5);
 close(vgafile);
 rx:=0;
 i:=199;
 while (rx=0) and (i>0) do
  begin
   for j:=0 to 319 do
    if clipboard^[i,j]>0 then rx:=1;
   if rx=0 then dec(i);
  end;
 clipy:=i;
 rx:=0;
 j:=319;
 while (rx=0) and (i>0) do
  begin
   for i:=0 to clipy do
    if clipboard^[i,j]>0 then rx:=1;
   if rx=0 then dec(j);
  end;
 clipx:=j;
end;

procedure getpath;
var t1,t2,s: string[79];
begin
 s:=fexpand(paramstr(0));
 fsplit(s,pathstr,t1,t2);
 getdir(0,curpath);
 if ioresult<>0 then errorhandler('Cannot get current directory.',1);
end;

procedure savetemp;
var vgafile: file of screentype;
    palfile: file of paltype;
begin
 assign(vgafile,pathstr+'tmp.vga');
 rewrite(vgafile);
 if ioresult<>0 then errorhandler('tmp.vga',1);
 write(vgafile,screen);
 if ioresult<>0 then errorhandler('tmp.vga',5);
 close(vgafile);
 assign(palfile,pathstr+'tmp.pal');
 rewrite(palfile);
 if ioresult<>0 then errorhandler('tmp.pal',1);
 write(palfile,colors);
 if ioresult<>0 then errorhandler('tmp.pal',5);
 close(palfile);
 if ioresult<>0 then errorhandler('tmp.pal',5);
end;

procedure loadtemp;
var vgafile: file of screentype;
    palfile: file of paltype;
begin
 assign(palfile,pathstr+'tmp.pal');
 reset(palfile);
 if ioresult<>0 then errorhandler('tmp.pal',1);
 read(palfile,colors);
 if ioresult<>0 then errorhandler('tmp.pal',5);
 close(palfile);
 erase(palfile);
 if ioresult<>0 then errorhandler('tmp.pal',5);
 set256colors(colors);
 assign(vgafile,pathstr+'tmp.vga');
 reset(vgafile);
 if ioresult<>0 then errorhandler('tmp.vga',1);
 read(vgafile,screen);
 if ioresult<>0 then errorhandler('tmp.vga',5);
 close(vgafile);
 erase(vgafile);
 if ioresult<>0 then errorhandler('tmp.vga',5);
end;

procedure dosshell;
var s: string[79];
begin
 savetemp;
 textmode(co80);
 clrscr;
 writeln(cr,cr);
 drawtitlemessage;
 textcolor(8);
 writeln(cr,'To return to SE type "EXIT".');
 textcolor(15);
 swapvectors;
 s:=getenv('COMSPEC');
 if s='' then s:='c:\command.com';
 exec(s,'/K'+pathstr+'PROMPT.BAT');
 if doserror<>0 then errorhandler('Cannot run dosshell.',7);
 swapvectors;
 chdir(curpath);
 if ioresult<>0 then errorhandler('Cannot change directory.',7);
 setgraphmode(0);
 loadtemp;
end;

procedure helpscreen;
var str1: string[5];
begin
 tcolor:=255;
 new(t);
 mymove2(screen,t^,16000);
 for i:=14 to 186 do fillchar(screen[i,7],307,0);
 setcolor(255);
 rectangle(8,15,312,185);
 rectangle(10,17,310,183);
 str(version:0:3,str1);
 printxy(11,19,'SCREEN EDIT (V'+str1+') COMMANDS:');
 printxy(18,30,  'ALT-A  FADE\BRIGHTEN AREA');
 printxy(18,40,  'ALT-B  BAR/PATTERN FILL');
 printxy(18,50,  'ALT-C  CIRCLE/ELLIPSE');
 printxy(18,60,  'ALT-D  DOS SHELL');
 printxy(18,70,  'ALT-F  90'' ROTATE');
 printxy(18,80,  'ALT-G  GRAB FROM CLIPBOARD');
 printxy(18,90,  'ALT-H  HORIZONTAL FLIP');
 printxy(18,100, 'ALT-I  INSERT TO CLIPBOARD');
 printxy(18,110, 'ALT-L  LOAD SCREEN AND PALETTE');
 printxy(18,120, 'ALT-M  MOVE/COPY BLOCK');
 printxy(18,130, 'ALT-N  SHRINK/GROW BLOCK');
 printxy(18,140, 'ALT-O  OPEN CLIPBOARD');
 printxy(18,150, 'ALT-P  EDIT PALETTE');
 printxy(18,160, 'ALT-R  RECTANGLE');
 printxy(18,170, 'ALT-S  SAVE SCREEN AND PALETTE');
 printxy(183,30, 'ALT-T  LINE');
 printxy(183,40, 'ALT-V  VERTICAL FLIP');
 printxy(183,50, 'ALT-W  WRITE TEXT LINE');
 printxy(183,60, 'ALT-X  QUIT');
 printxy(183,75, 'F1  COORDINATE TOGGLE');
 printxy(183,85, 'F2  PALETTE TOGGLE');
 printxy(183,95, 'F7  FILL SCREEN');
 printxy(183,105,'F8  HORIZONTAL LINE');
 printxy(183,115,'F9  VERTICAL LINE');
 printxy(183,130,'+;  ADD 1 COLOR VALUE');
 printxy(183,140,'-.  SUB 1 COLOR VALUE');
 printxy(183,150,'Z   GET UNDER COLOR');
 printxy(183,160,'SP  USE LAST COLOR');
 printxy(183,170,'ESC HELP SCREEN');
 readkey;
 while fastkeypressed do readkey;
 mymove2(t^,screen,16000);
 dispose(t);
end;

procedure entertext;
var s: string[30];
begin
 new(t);
 mymove2(screen,t^,16000);
 fillchar(s[1],30,' ');
 s[0]:=chr(30);
 bkcolor:=255;
 tcolor:=last;
 rx:=1;
 repeat
  printxy(curx-5,cury-1,s);
  ans:=upcase(readkey);
  mymove2(t^,screen,16000);
  case ans of
   #8: if rx>1 then
        begin
         s[rx]:=' ';
         dec(rx);
         s[rx]:=' ';
        end
       else s[rx]:=' ';
   #27: begin
         dispose(t);
         bkcolor:=0;
         tcolor:=255;
         exit;
        end;
   else
    begin
     s[rx]:=ans;
     inc(rx);
     if rx=31 then rx:=30;
    end;
  end;
 until ans=#13;
 dispose(t);
 printxy(curx-5,cury-1,s);
 bkcolor:=0;
 tcolor:=255;
end;

procedure viewclipboard;
begin
 if (clipx=0) and (clipy=0) then exit;
 new(t);
 mymove2(screen,t^,16000);
 for i:=0 to clipy do
  move(clipboard^[i],screen[i],clipx+1);
 readkey;
 while fastkeypressed do readkey;
 mymove2(t^,screen,16000);
 dispose(t);
end;

procedure checkexit;
var vgafile: file of screentype;
    palfile: file of paltype;
    srcpal,tarpal: ^paltype;
begin
 assign(vgafile,vgastr+'.vga');
 reset(vgafile);
 if ioresult<>0 then
  begin
   done:=true;
   exit;
  end;
 new(t);
 read(vgafile,t^);
 if ioresult<>0 then errorhandler(vgastr+'.vga reading.',5);
 close(vgafile);
 if palmodeon then
  for i:=0 to maxpaly do
   mymove2(underpal^[i],screen[i+paly],80);
 j:=0;
 asm
  push ds
  push es
  les di, [t]
  mov ax, $A000
  mov ds, ax
  xor si, si
  mov cx, 32000
  cld
  repe cmpsw
  pop es
  pop ds
  je @@done
  mov [j], 1
 @@done:
 end;
 if j=0 then
  begin
   new(srcpal);
   new(tarpal);
   mymove2(colors,srcpal^,192);
   assign(palfile,palstr+'.pal');
   reset(palfile);
   if ioresult<>0 then
    begin
     done:=true;
     dispose(t);
     exit;
    end;
   read(palfile,tarpal^);
   if ioresult<>0 then errorhandler(palstr+'.pal reading.',5);
   close(palfile);
   j:=0;
   asm
    push ds
    push es
    les di, [srcpal]
    lds si, [tarpal]
    mov cx, 765
    cld
    repe cmpsb
    pop es
    pop ds
    je @@done
    mov [j], 1
   @@done:
   end;
   dispose(srcpal);
   dispose(tarpal);
   if j=0 then
    begin
     done:=true;
     dispose(t);
     exit;
    end;
  end;
 mymove2(screen,t^,16000);
 for i:=90 to 109 do
  fillchar(screen[i,65],180,0);
 rectangle(66,91,243,108);
 rectangle(68,93,241,106);
 printxy(66,96,'FILE NOT SAVED. EXIT ANYWAY? (Y/N)');
 ans:=readkey;
 if upcase(ans)='Y' then done:=true
  else
   begin
    while fastkeypressed do readkey;
    mymove2(t^,screen,16000);
    if palmodeon then redrawpalmode;
   end;
 dispose(t);
end;

procedure processkey;
begin
 ans:=readkey;
 change:=last;
 case upcase(ans) of
  ' ': under:=last;
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
        #59: if coordon then
              begin
               coordon:=false;
               if palmodeon then printxy(257,paly+cordofs,'       ');
              end
              else coordon:=true;
        #60: if palmodeon then
              begin
               palmodeon:=false;
               for i:=0 to maxpaly do
                mymove2(underpal^[i],screen[i+paly],80);
               end
              else
               begin
                palmodeon:=true;
                if cury>140 then paly:=0 else paly:=maxyonpal;
                for i:=0 to maxpaly do
                 mymove2(screen[i+paly],underpal^[i],80);
                redrawpalmode;
               end;
        #65: fillchar(screen,64000,last);
        #67: fillchar(screen[cury,curx],320-curx,last);
        #68: for j:=cury to 199 do screen[j,curx]:=last;
        #31: save;
        #38: load(true);
        #25: paledit;
        #46: doacircle;
        #20: generaloption(0);   { draw line           }
        #48: generaloption(1);   { fill bar            }
        #19: generaloption(2);   { rectangle           }
        #47: generaloption(3);   { verticle flip       }
        #35: generaloption(4);   { horizontal flip     }
        #50: generaloption(5);   { move                }
        #30: generaloption(6);   { brighten/fade area  }
        #33: generaloption(7);   { rotate block        }
        #49: generaloption(8);   { partition block     }
        #23: generaloption(9);   { insert to clipboard }
        #34: generaloption(10);  { grab from clipboard }
        #32: dosshell;
        #17: entertext;
        #24: viewclipboard;
        #16,#45: checkexit;
       end;
       under:=screen[cury,curx];
      end;
  '+',',': begin inc(under); last:=under; end;
  '-','.': begin dec(under); last:=under; end;
  '1': last:=0;
  '2': last:=15;
  '3': last:=31;
  '4': last:=47;
  '5': last:=63;
  '6': last:=79;
  '7': last:=95;
  '8': last:=111;
  '9': last:=127;
  'Q': last:=143;
  'W': last:=159;
  'E': last:=175;
  'R': last:=191;
  'T': last:=207;
  'Y': last:=223;
  'U': last:=239;
  'I': last:=255;
  'Z': last:=under;
  #27: helpscreen;
 end;
 if palmodeon then
  begin
   if change<>last then
    begin
     for i:=6 to 17 do
      fillchar(screen[i+paly,300],16,last);
     screen[paly+tick2,change+2]:=0;
     screen[paly+tick2,last+2]:=255;
     screen[paly+tick1,change+2]:=0;
     screen[paly+tick1,last+2]:=255;
     screen[paly+tick2+1,change+2]:=0;
     screen[paly+tick2+1,last+2]:=255;
     screen[paly+tick1+1,change+2]:=0;
     screen[paly+tick1+1,last+2]:=255;
    end;
   if (cury<60) and (paly=0) then
    begin
     for i:=0 to maxpaly do
      mymove2(underpal^[i],screen[i+paly],80);
     paly:=maxyonpal;
     for i:=0 to maxpaly do
      mymove2(screen[i+paly],underpal^[i],80);
     redrawpalmode;
    end
   else if (cury>140) and (paly=maxyonpal) then
    begin
     for i:=0 to maxpaly do
      mymove2(underpal^[i],screen[i+paly],80);
     paly:=0;
     for i:=0 to maxpaly do
      mymove2(screen[i+paly],underpal^[i],80);
     redrawpalmode;
    end;
   if coordon then
    begin
     str(curx:3,str1);
     str(cury:3,str2);
     printxy(257,paly+cordofs,str1+','+str2);
    end;
  end;
end;

procedure checkmouse;
begin
 change:=last;
 asm
  mov ax, 5
  mov bx, 0
   int 33h
  test bx, 1
  jz @@continue
  mov al, last
  mov under, al
@@continue:
  mov ax, 0Bh
   int 33h
  mov mdx, cx
  mov mdy, dx
 end;
 if (mdx=0) and (mdy=0) then exit;
 mdx:=mdx div 4;
 mdy:=mdy div 4;
 screen[cury,curx]:=under;
 cury:=cury+mdy;
 if cury>199 then cury:=199
  else if cury<0 then cury:=0;
 curx:=curx+mdx;
 if curx>319 then curx:=319
  else if curx<0 then curx:=0;
 under:=screen[cury,curx];
 if palmodeon then
  begin
   if change<>last then
    begin
     for i:=6 to 17 do
      fillchar(screen[i+paly,300],16,last);
     screen[paly+tick2,change+2]:=0;
     screen[paly+tick2,last+2]:=255;
     screen[paly+tick1,change+2]:=0;
     screen[paly+tick1,last+2]:=255;
     screen[paly+tick2+1,change+2]:=0;
     screen[paly+tick2+1,last+2]:=255;
     screen[paly+tick1+1,change+2]:=0;
     screen[paly+tick1+1,last+2]:=255;
    end;
   if coordon then
    begin
     str(curx:3,str1);
     str(cury:3,str2);
     printxy(257,paly+cordofs,str1+','+str2);
    end;
   if (cury<60) and (paly=0) then
    begin
     for i:=0 to maxpaly do
      mymove2(underpal^[i],screen[i+paly],80);
     paly:=maxyonpal;
     for i:=0 to maxpaly do
      mymove2(screen[i+paly],underpal^[i],80);
     redrawpalmode;
    end
   else if (cury>140) and (paly=maxyonpal) then
    begin
     for i:=0 to maxpaly do
      mymove2(underpal^[i],screen[i+paly],80);
     paly:=0;
     for i:=0 to maxpaly do
      mymove2(screen[i+paly],underpal^[i],80);
     redrawpalmode;
    end;
  end;
end;

procedure mainloop;
begin
 repeat
  inc(screen[cury,curx],2);
  if mouseinstalled then checkmouse;
  if fastkeypressed then processkey;
 until done;
end;

procedure paramerror;
begin
 textcolor(12);
 writeln(cr,'Invalid parameter.  You must enter the command line in');
 writeln(' this format: ');
 writeln(cr,'  SE filename [filename]',cr);
 writeln(' Filename must not have a filename extention (*.vga or *.pal).');
 writeln(' The first filename is the screen file, the second, palette.');
 writeln(' Palette file is optional.');
 textcolor(15);
 halt(255);
end;

procedure checkformouse; assembler;
asm
 mov ax, 0
  int 33h
 cmp ax, 0
 je @@error
 mov mouseinstalled, 1
@@error:
end;

procedure initialize;
begin
 tcolor:=255;
 bkcolor:=0;
 done:=false;
 palchange:=false;
 palmodeon:=true;
 coordon:=true;
 clipboardchange:=false;
 r:=10;
 if (paramcount>2) or (paramcount=0) then paramerror;
 vgastr:=paramstr(1);
 for i:=1 to length(vgastr) do vgastr[i]:=upcase(vgastr[i]);
 if (paramcount=2) then
  begin
   palstr:=paramstr(2);
   for i:=1 to length(vgastr) do palstr[i]:=upcase(palstr[i]);
  end
 else palstr:=vgastr;
 getpath;
 new(underpal);
 loadclipboard;
 curx:=160;
 cury:=100;
 paly:=maxyonpal;
 readygraph;
 load(false);
 printxy(257,paly+cordofs,'160,100');
 mouseinstalled:=false;
 checkformouse;
end;

begin
 initialize;
 mainloop;
 closegraph;
 dispose(underpal);
 saveclipboard;
 dispose(clipboard);
 drawtitlemessage;
end.