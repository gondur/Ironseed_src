program makescreen;
uses graph, crt;

{$L vga256}
type
 colortype= array[1..3] of byte;
 paltype= array[0..255] of colortype;
 screentype= array[0..199,0..319] of byte;
 fonttype= array[0..2] of byte;
 fontarray= array[1..84] of fonttype;
 pscreentype= ^screentype;
const
 fontmax= 2;
 font: array[0..fontmax] of fontarray=
 (((0,0,0),(102,96,96),(85,0,0),(34,0,0),(36,68,32),
   (66,34,64),(9,105,0),(4,228,0),(0,2,36),(0,240,0),
   (0,0,32),(1,36,128),(107,221,96),(98,34,240),(241,104,240),
   (241,33,224),(153,241,16),(248,113,224),(248,249,240),(241,17,16),
   (249,105,240),(249,241,16),(102,6,96),(102,6,98),(18,66,16),
   (15,15,0),(132,36,128),(105,32,32),(121,185,144),(249,169,240),
   (248,136,240),(233,153,224),(240,200,240),(248,232,128),(248,153,240),
   (153,249,144),(114,34,112),(241,25,96),(158,153,144),(136,136,240),
   (159,153,144),(233,153,144),(249,153,240),(249,184,128),(105,154,80),
   (249,169,144),(132,33,224),(114,34,32),(153,153,240),(153,149,32),
   (153,187,96),(153,105,144),(153,113,16),(242,72,240),(9,36,144),
   (8,66,16),(7,155,144),(15,169,240),(15,136,240),(14,153,224),
   (14,12,224),(15,140,128),(15,137,240),(9,159,144),(7,34,112),
   (15,25,96),(9,233,144),(8,136,240),(9,249,144),(14,153,144),
   (15,153,240),(15,155,128),(15,155,240),(15,154,144),(4,33,224),
   (15,34,32),(9,153,96),(9,149,32),(9,155,96),(9,105,144),
   (9,151,16),(15,36,240),(53,170,83),(202,17,172)),

   ((0,0,0),(102,96,96),(85,0,0),(34,0,0),(36,68,32),
   (66,34,64),(9,105,0),(4,228,0),(0,2,36),(0,240,0),
   (0,0,32),(1,36,128),(107,221,96),(98,34,240),(105,104,240),
   (105,41,96),(19,95,16),(248,225,224),(104,233,96),(241,36,128),
   (105,105,96),(105,113,96),(2,2,0),(2,2,36),(18,66,16),
   (15,15,0),(132,36,128),(105,32,32),(105,249,144),(233,233,224),
   (105,137,96),(233,153,224),(248,232,240),(248,232,128),(104,185,96),
   (153,249,144),(114,34,112),(241,25,96),(158,153,144),(136,136,240),
   (159,153,144),(233,153,144),(105,153,96),(233,232,128),(105,155,112),
   (233,233,144),(120,97,224),(242,34,32),(153,153,96),(153,149,32),
   (153,187,96),(153,105,144),(153,113,96),(242,72,240),(9,36,144),
   (8,66,16),(6,153,112),(142,153,224),(7,136,112),(23,153,112),
   (6,158,112),(105,200,128),(6,151,150),(142,153,144),(32,34,32),
   (16,17,150),(137,233,144),(34,34,32),(9,249,144),(14,153,144),
   (6,153,96),(14,153,232),(6,153,113),(6,152,128),(7,66,224),
   (39,34,32),(9,153,96),(9,149,32),(9,155,96),(9,105,144),
   (9,151,22),(15,36,240),(53,170,83),(202,17,172)),

   ((0,0,0),(34,32,32),(85,0,0),(34,0,0),(36,68,32),
   (66,34,64),(9,105,0),(2,114,0),(0,2,36),(0,240,0),
   (0,0,32),(1,36,128),(107,221,96),(38,34,112),(241,248,240),
   (241,113,240),(170,175,32),(248,241,240),(248,249,240),(241,17,16),
   (249,105,240),(249,241,240),(2,2,0),(2,2,36),(18,66,16),
   (15,15,0),(132,36,128),(249,48,32),(249,249,144),(249,233,240),
   (249,137,240),(233,153,224),(248,232,240),(248,232,128),(248,185,240),
   (153,249,144),(114,34,112),(241,25,240),(158,153,144),(136,136,240),
   (159,153,144),(157,185,144),(249,153,240),(249,248,128),(249,155,240),
   (249,233,144),(120,97,224),(242,34,32),(153,153,240),(153,149,32),
   (153,187,96),(153,105,144),(153,241,240),(242,72,240),(9,36,144),
   (8,66,16),(15,155,208),(143,153,240),(15,136,240),(31,153,240),
   (15,188,240),(249,200,128),(15,151,159),(143,153,144),(32,34,32),
   (16,17,159),(137,233,144),(34,34,32),(9,249,144),(14,153,144),
   (15,153,240),(15,153,248),(15,153,241),(15,152,128),(7,66,224),
   (39,34,32),(9,153,240),(9,149,32),(9,155,96),(9,105,144),
   (9,159,31),(15,36,240),(53,170,83),(202,17,172)));
var
 colors: paltype;
 screen: screentype absolute $A000:0000;
 tcolor,bkcolor,index,curx,cury,i,j,backcolor,last,under,textcolor: integer;
 ans: char;
 vgastr: string[40];

procedure vgadriver; external;

procedure errorhandler(s: string; errtype: integer);
begin
 textmode(co80);
 writeln;
 writeln;
 case errtype of
  1: writeln('Opening File Error: ',s);
  5: writeln('Read/Write File Error: ',s);
  6: writeln('Program Error: ',s);
  7: writeln('DOS Error: ',s);
 end;
 halt;
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

procedure setrgb256(palnum,r,g,b: byte); assembler;
asm
 mov dx, 03c8h
 mov al, [palnum]
 out dx, al
 inc dx
 mov al, [r]
 out dx, al
 mov al, [g]
 out dx, al
 mov al, [b]
 out dx, al
end;

procedure set256Colors(pal: paltype); assembler;
asm
 push es
 xor di, di
 les si, [pal]
 mov dx, 03C8h
 xor ax, ax
 out dx, al
 inc dx
@@loop:
 mov al, [es:si]
 out dx, al
 mov al, [es:si+1]
 out dx, al
 mov al, [es:si+2]
 out dx, al
 add si, 3
 inc di
 cmp di, 256
 jl @@loop
 pop es
end;

procedure printxy(fontn,x1,y1: integer; s: string);
var letter,a,x,y: integer;
begin
 x:=x1;
 for j:=1 to length(s) do
  begin
   x:=x+5;
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    'A' ..'Z': letter:=ord(s[j])-36;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    '%': letter:=55;
    '\': letter:=56;
    #1: letter:=83;
    #2: begin
         letter:=84;
         dec(x);
        end;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 5 do
    begin
     inc(y);
     for a:=4 to 7 do
      if font[fontn,letter,i div 2] and (1 shl a)>0 then screen[y,x+3-a]:=tcolor
       else if bkcolor<255 then screen[y,x+3-a]:=bkcolor;
     inc(y);
     inc(i);
     for a:=0 to 3 do
      if font[fontn,letter,i div 2] and (1 shl a)>0 then screen[y,x-1-a]:=tcolor
       else if bkcolor<255 then screen[y,x-1-a]:=bkcolor;
    end;
   if bkcolor<255 then for i:=1 to 6 do screen[y1+i,x]:=bkcolor;
  end;
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

procedure save;
var vgadata: file of screentype;
begin
 screen[cury,curx]:=under;
 assign(vgadata,vgastr+'.vga');
 reset(vgadata);
 if ioresult<>0 then errorhandler(vgastr+'.vga',1);
 write(vgadata,screen);
 close(vgadata);
end;

procedure load;
var vgadata: file of screentype;
begin
 assign(vgadata,vgastr+'.vga');
 reset(vgadata);
 if ioresult<>0 then errorhandler(vgastr+'.vga',1);
 read(vgadata,screen);
 close(vgadata);
 last:=screen[cury,curx];
 under:=screen[cury,curx];
end;

procedure readpalette;
var palfile: file of paltype;
begin
 assign(palfile,vgastr+'.pal');
 reset(palfile);
 if ioresult<>0 then
  begin
   loadpal('data\main.pal');
   colors[255]:=colors[0];
  end
 else read(palfile,colors);
 close(palfile);
 set256colors(colors);
end;

procedure mainloop;
begin
 repeat
   inc(screen[cury,curx],2);
   if fastkeypressed then
   begin
   ans:=readkey;
   case upcase(ans) of
    #0:begin
        ans:=readkey;
        screen[cury,curx]:=under;
        case ans of
         #72:if cury=0 then cury:=199 else dec(cury);
         #80:if cury=199 then cury:=0 else inc(cury);
         #75:if curx=0 then curx:=319 else dec(curx);
         #77:if curx=319 then curx:=0 else inc(curx);
         #71:begin curx:=(curx div 10) - 1; curx:=curx*10 mod 320; end;
         #79:begin curx:=(curx div 10) + 1; curx:=curx*10 mod 320; end;
         #73:begin cury:=(cury div 10) - 1; cury:=cury*10 mod 200; end;
         #81:begin cury:=(cury div 10) + 1; cury:=cury*10 mod 200; end;
        end;
        under:=screen[cury,curx];
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
    'Z':begin under:=224; last:=224; end;
    'X':begin under:=228; last:=228; end;
    'C':begin under:=232; last:=232; end;
    '+':begin inc(under); last:=under; end;
    '-':begin dec(under); last:=under; end;
    'S':save;
    'L':load;
   end;
   end;
 until ans=#59;
end;

begin
 vgastr:=paramstr(1);
 randomize;
 textcolor:=31;
 backcolor:=0;
 curx:=0;
 cury:=0;
 readygraph;
 load;
 readpalette;
 ans:=' ';
 mainloop;
 closegraph;
end.
