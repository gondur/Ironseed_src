program intro;
{$M 4500,350000,350000}

{***************************

  Introduction Sequence for IronSeed

  Channel 7
  Destiny: Virtual

  Copywrite 1994

***************************}

{$I dsmi.inc}, emhm, crt, graph, gmouse, getcpu, dos;

const
 CPR_NONE=0;                    {   0 no compresion            }
 CPR_NOPAL=1;                   {   1 no palette, compressed   }
 CPR_PAL=2;                     {   2 palette, compressed      }
 CPR_HEADERINCL=3;              {   3 header included          }
 CPR_ERROR=255;                 { global error                 }
 CPR_CURRENT=CPR_HEADERINCL;    { current version              }
 CPR_BUFFSIZE= 8192;            { adjustable buffer size       }
type
 CPR_HEADER=
  record
   signature: word;             {RWM, no version. RM, version  }
   version: byte;
   width,height: word;
   palette: boolean;
  end;
 pCPR_HEADER= ^CPR_HEADER;
type
 planetype= array[1..4,1..3] of real;
 boxtype= array[1..6] of planetype;
 shippixtype= array[0..9,0..19,0..29] of byte;
 msgpixtype= array[0..9,0..4,0..9] of byte;
 overridetype= array[90..110,200..240] of byte;
 overridetype2= array[0..40,0..110] of byte;
 peoplepixtype= array[0..15,0..28,0..28] of byte;
 screentype= array[0..199,0..319] of byte;
 paltype=array[0..255,1..3] of byte;
 fonttype= array[0..2] of byte;
 plantype= array[1..120,1..120] of byte;
 landtype= array[1..240,1..120] of byte;
 pscreentype= ^screentype;
 bigbuffertype= array[0..4095] of byte;
 buftype= array[0..2047] of byte;
const
 id = 'apeiron';
 version= '1.00005';
 buffsize = 4096;
 font: array[1..82] of fonttype=
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
   (9,159,31),(15,36,240));

var
 song: pointer;
 tcolor,bkcolor,i,j,z,cursor,permx,permy,code,j2,m,index,alt,ecl,
  r2,c,radius,m1,m2,m3,m4,tslice,water,waterindex,x,ofsx,ofsy: integer;
 keymode,moderror: boolean;
 key: char;
 modth,modtm,modts,curth,curtm,curts: byte;
 vgahandles: array[0..8] of word;
 y,part,part2,c2: real;
 planet: ^plantype;
 landform: ^landtype;
 shippix: ^shippixtype;
 msgpix: ^msgpixtype;
 override: ^overridetype;
 override2: ^overridetype2;
 peoplepix: ^peoplepixtype;
 screen: screentype absolute $A000:0000;
 colors: paltype;
 s1,s2,s3: pscreentype;
 k: word;
 module: pmodule;
 sc: tsoundCard;
 spcindex: array[0..5] of integer;

{$L mover2}
{$L vga256}
{$L scroller}
{$L v3220pa}
{$F+}
procedure upscroll(s: screentype); external;
{$F-}
procedure vgadriver; external;
procedure mymove2(var src,tar; count: integer); external;
procedure init320200; external;
procedure setpix(x,y: integer; pcolor: byte); external;
function  getpix(x,y: integer): byte ; external;
procedure setpage(page: byte); external;
procedure showpage(page: byte); external;

procedure errorhandler(s: string; errtype: integer);
begin
 closegraph;
 writeln;
 case errtype of
  1: writeln('Open File Error: ',s);
  2: writeln('Mouse Error: ',s);
  3: writeln('Sound Error: ',s);
  4: writeln('EMS Error: ',s);
  5: writeln('Fatal File Error: ',s);
  6: writeln('Program Error: ',s);
  7: writeln('Music Error: ',s);
 end;
 halt(4);
end;

procedure initializemod;
var options: integer;
begin
 if emsinit(200,800)<>0 then
  begin
   moderror:=true;
   exit;
   errorhandler('Initializing.',4);
  end;
 options:=MCP_QUALITY;
 if getcputype and 4>0 then options:=options or MCP_486;
 if initdsmi(22000,4096,options,@sc)<>0 then errorhandler('Initializing Mod Player.',7);
end;

procedure stopmod;
var i: integer;
begin
 if moderror then exit;
 for i:=64 downto 0 do
  begin
   mcpsetmastervolume(i);
   delay(10);
  end;
 mcpclearbuffer;
 ampstopmodule;
 ampfreemodule(module);
end;

procedure setnewsampling(n: integer);
begin
 if moderror then exit;
 mcpsetsamplingrate(n);
end;

procedure playmod(looping: boolean;s: string);
var j: integer;
    voltable: array[0..31] of integer;
begin
 if moderror then exit;
 module:=amploadmod(s,LM_IML);
 if sc.id<>ID_GUS then mcpStartVoice else gusStartVoice;
 for j:=0 to 31 do voltable[j]:=j*2+1;
 cdiSetupChannels(0,module^.channelCount+4,@voltable);
 for j:=0 to module^.channelcount-1 do
  cdisetpan(j,40);
 for j:=0 to 3 do
  cdisetpan(module^.channelcount+j,Pan_Surround);
 mcpsetmastervolume(64);
 if looping then ampplaymodule(module,PM_Loop)
  else ampplaymodule(module,0);
end;

procedure soundeffect(s: string; rate: integer);
var f: file;
    size,j: integer;
    si: tsampleinfo;
begin
 assign(f,s);
 reset(f,1);
 if ioresult<>0 then errorhandler(s,1);
 size:=filesize(f);
 if memavail<size then errorhandler('Sample Memory too small.',7);
 getmem(si.sample,size);
 blockread(f,si.sample^,size);
 if ioresult<>0 then errorhandler(s,6);
 close(f);
 if rate=0 then rate:=11900;
 with si do
  begin
   length:=size;
   loopstart:=0;
   loopend:=0;
   mode:=0;
   sampleid:=0;
  end;
 mcpconvertsample(si.sample,size);
 for j:=0 to 3 do if mcpsetsample(module^.channelcount+j,@si)<>0 then errorhandler(s+',Setting sample.',7);
 for j:=0 to 3 do if mcpplaysample(module^.channelcount+j,rate,64)<>0 then errorhandler(s+',Playing.',7);
 freemem(si.sample,size);
end;

function fastkeypressed: boolean; assembler;
asm
 push ds
 mov bx, 40h
 mov ds, bx
 mov bx, [1Ah]
 cmp bx, [1Ch]
 mov ax, 0
 jz @nopress
 inc ax
@nopress:
 pop ds
end;

procedure uncompressfile(s: string; ts: pscreentype; h: pCPR_HEADER);
type bigbuffertype=array[0..CPR_BUFFSIZE-1] of byte;
var f: file;
    err,num,count,databyte,j,total,index,totalsize: word;
    buffer: ^bigbuffertype;

 procedure handleerror;
 begin
  h^.version:=CPR_ERROR;
  dispose(buffer);
  close(f);
  j:=ioresult;
 end;

 function handleversion(n: integer): boolean;

 begin
  handleversion:=false;
  case n of
   0: begin                                   { no compression }
       seek(f,0);
       num:=64000;
       blockread(f,ts^,num,err);
       if (err<num) or (ioresult<>0) then exit;
       dispose(buffer);
       close(f);
       h^.version:=CPR_NONE;
       h^.width:=320;
       h^.height:=200;
       h^.palette:=false;
      end;
   1: begin                                   { no extras }
       seek(f,3);
       total:=filesize(f)-3;
       h^.version:=CPR_NOPAL;
       h^.width:=320;
       h^.height:=200;
       h^.palette:=false;
      end;
   2: begin                                   { Imbedded palette }
       num:=768;
       seek(f,3);
       blockread(f,colors,num,err);
       if (err<num) or (ioresult<>0) then exit;
       total:=filesize(f)-771;
       h^.version:=CPR_PAL;
       h^.width:=320;
       h^.height:=200;
       h^.palette:=true;
      end;
   3: if h^.palette then                      { header included }
       begin
        num:=768;
        blockread(f,colors,num,err);
        if (err<num) or (ioresult<>0) then exit;
        total:=filesize(f)-768-sizeof(CPR_HEADER);
       end
      else total:=filesize(f)-sizeof(CPR_HEADER);
   else exit;
  end;
  handleversion:=true;
 end;

 function checkversion: boolean;
 begin
  checkversion:=false;
  num:=sizeof(CPR_HEADER);
  blockread(f,h^,num,err);
  if (err<num) or (ioresult<>0) then exit;
  if h^.signature<>22354 then
   begin
    if (h^.signature<>19794) and (not handleversion(0)) then exit
     else if (h^.signature=19794) and (not handleversion(h^.version)) then exit;
   end
  else handleversion(CPR_NOPAL);
  checkversion:=true;
 end;

 procedure getbuffer;
 begin
  if total>CPR_BUFFSIZE then num:=CPR_BUFFSIZE else num:=total;
  blockread(f,buffer^,num,err);
  if (err<num) or (ioresult<>0) then
   begin
    handleerror;
    exit;
   end;
  total:=total-num;
  index:=0;
 end;

begin
 if CPR_BUFFSIZE<1024 then
  begin
   handleerror;
   exit;
  end;
 new(buffer);
 assign(f,s);
 reset(f,1);
 if ioresult<>0 then
  begin
   handleerror;
   exit;
  end;
 if not checkversion then
  begin
   handleerror;
   exit;
  end;
 if h^.version=CPR_NONE then exit;
 getbuffer;
 j:=0;
 totalsize:=h^.width*h^.height;
 repeat
  if buffer^[index]=255 then
   begin
    inc(index);
    if index=CPR_BUFFSIZE then getbuffer;
    count:=buffer^[index];
    inc(index);
    if index=CPR_BUFFSIZE then getbuffer;
    databyte:=buffer^[index];
    if j+count>totalsize then count:=totalsize-j;
    fillchar(ts^[0,j],count,databyte);
    j:=j+count;
   end
  else
   begin
    ts^[0,j]:=buffer^[index];
    inc(j);
   end;
  inc(index);
  if index=CPR_BUFFSIZE then getbuffer;
 until j=totalsize;
 close(f);
 dispose(buffer);
end;

procedure loadpalette(s: string);
var palfile: file of paltype;
begin
 assign(palfile,s);
 reset(palfile);
 if ioresult<>0 then errorhandler(s,1);
 read(palfile,colors);
 if ioresult<>0 then errorhandler(s,5);
 close(palfile);
end;

procedure loadscreen(s: string; ts: pointer);
var ftype: CPR_HEADER;
    s2: string[30];
begin
 uncompressfile(s,ts,@ftype);
 if ftype.version=CPR_ERROR then errorhandler(s,5);
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
 xor di, di
 push es
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
 jne @@loop
 pop es
{ mov ax, 1012h
 mov bx, 0
 mov cx, 256
 les dx, Pal
  int 10h }
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

procedure fading;
var a,b: integer;
    temppal: paltype;
begin
 mymove2(colors,temppal,192);
 b:=tslice div 4;
 for a:=24 downto 0 do
  begin
   for j:=0 to 255 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/24);
   set256colors(temppal);
   delay(b);
  end;
end;

procedure printxy(x1,y1: integer; s: string);
var letter,a,x,y,t: integer;
begin
 t:=tcolor;
 x1:=x1+4;               { this stupid offset is pissing me off!!!!}
 for j:=1 to length(s) do
  begin
   tcolor:=t;
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    'A' ..'Z': letter:=ord(s[j])-36;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    '%': letter:=55;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 5 do
    begin
     x:=x1;
     inc(y);
     for a:=7 downto 4 do
      begin
       inc(x);
       if font[letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
        else if bkcolor<255 then screen[y,x]:=bkcolor;
      end;
     dec(tcolor,2);
     x:=x1;
     inc(y);
     inc(i);
     for a:=3 downto 0 do
      begin
       inc(x);
       if font[letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
        else if bkcolor<255 then screen[y,x]:=bkcolor;
      end;
     dec(tcolor,2);
    end;
   x1:=x1+5;
   if bkcolor<255 then for i:=1 to 6 do screen[y1+i,x1]:=bkcolor;
  end;
 tcolor:=t;
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
 loadpalette('data\main.pal');
 set256colors(colors);
 setgraphbufsize(0);
 checksnow:=false;
end;

procedure fadein;
var a,b: integer;
    temppal: paltype;
begin
 b:=tslice div 4;
 fillchar(temppal,768,0);
 for a:=1 to 24 do
  begin
   for j:=0 to 255 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/24);
   set256colors(temppal);
   delay(b);
  end;
 set256colors(colors);
end;

procedure runintro; forward;

procedure blast(c1,c2,c3: integer);
var a: integer;
begin
 for a:=1 to 25 do
  begin
   for j:=0 to 255 do
    begin
     colors[j,1]:=colors[j,1] + round(a*(c1-colors[j,1])/25);
     colors[j,2]:=colors[j,2] + round(a*(c2-colors[j,2])/25);
     colors[j,3]:=colors[j,3] + round(a*(c3-colors[j,3])/25);
    end;
   set256colors(colors);
   delay(tslice);
  end;
 set256colors(colors);
end;

procedure loadstarfield;
begin
 new(s1);
 new(s2);
 new(s3);
 mousehide;
 mymove2(screen,s2^,16000);
 mouseshow;
 loadscreen('data\cloud.vga',s1);
end;

procedure startit;
begin
 case cursor of
  1: code:=1;
  2: begin
      dispose(s1);
      dispose(s2);
      dispose(s3);
      fading;
      mousehide;
      fillchar(screen,64000,0);
      stopmod;
      runintro;
      loadstarfield;
     end;
  3: code:=2;
  4: code:=4;
 end;
end;

procedure drawcursor;
begin
 if cursor=0 then exit;
 case cursor of
  1:rectangle(25,158,159,177);
  2:rectangle(43,178,159,197);
  3:rectangle(159,158,283,177);
  4:rectangle(159,178,267,197);
 end;
end;

procedure findmouse;
var button: boolean;
begin
 if mouse.getstatus(left) then button:=true else button:=false;
 if (permx<>mouse.x) or (permy<>mouse.y) then keymode:=false;
 if (keymode) and (not button) then exit;
 case mouse.y of
  158..177: case mouse.x of
           25..159: cursor:=1;
           160..283: cursor:=3;
           else cursor:=0;
          end;
  178..197: case mouse.x of
           43..159: cursor:=2;
           160..267: cursor:=4;
           else cursor:=0;
          end;
  else if not keymode then cursor:=0;
 end;
 if (button) and (cursor>0) then startit;
end;

procedure checkkey(c: char);
begin
 case c of
  #72: if cursor=0 then cursor:=1
       else if cursor=1 then cursor:=4 else dec(cursor);
  #80: if cursor=0 then cursor:=1
       else if cursor=4 then cursor:=1 else inc(cursor);
  #75: if cursor>2 then cursor:=cursor-2
       else cursor:=cursor+2;
  #77: if cursor>2 then cursor:=cursor-2
       else cursor:=cursor+2;
 end;
end;

procedure mainloop;
begin
 code:=0;
 cursor:=0;
 keymode:=false;
 loadstarfield;
 k:=random(32000);
 playmod(true,'sound\gener1.mod');
 setcolor(207);
 repeat
  dec(k);
  if k>63999 then k:=k+64000;
  asm
   push ds
   push es
   mov ax, [k]
   les di, [s3]
   lds si, [s1]
   mov cx, 64000
   sub cx, ax
   mov di, ax
   cld
   rep movsb
   mov cx, ax
   xor di, di
   rep movsb
   pop es
   pop ds
  end;
  asm
   push ds
   push es
   les si, [s2]
   lds di, [s3]
   mov si, 64000
   xor di, di
  @@loopit:
   cmp di, [es: si]
   je @@black
   mov al, [es: si]
   mov [ds: si], al
  @@black:
   dec si
   jnz @@loopit
   pop es
   pop ds
  end;
  mousehide;
  mymove2(s3^,screen,16000);
  drawcursor;
  mouseshow;
  findmouse;
  if fastkeypressed then
   begin
    keymode:=true;
    permx:=mouse.x;
    permy:=mouse.y;
    key:=readkey;
    if key=#0 then checkkey(readkey);
    if key=#13 then startit;
   end;
  delay(tslice);
 until code>0;
 dispose(s1);
 dispose(s2);
 dispose(s3);
 stopmod;
 fading;
 mousehide;
 closegraph;
 textmode(co80);
end;

procedure showmars;
var temp: pscreentype;
begin
 fillchar(colors,768,0);
 set256colors(colors);
 loadscreen('data\cloud.vga',@screen);
 new(temp);
 loadscreen('data\world.vga',temp);
 colors[29]:=colors[0];
 colors[30]:=colors[0];
 set256colors(colors);
 upscroll(temp^);
 dispose(temp);
end;

procedure gettime; assembler;
asm
 mov ah, 2Ch
  int 21h
 mov modth, ch
 mov modtm, cl
 mov modts, dh
end;

function timewait(t: integer): boolean;
begin
 asm
  mov ah, 2Ch
   int 21h
  mov curth, ch
  mov curtm, cl
  mov curts, dh
 end;
 i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
 if i>t then timewait:=true else timewait:=false;
end;

procedure wait(s: integer);
var modth,modtm,modts,curth,curtm,curts: byte;
begin
 asm
  mov ah, 2Ch
   int 21h
  mov modth, ch
  mov modtm, cl
  mov modts, dh
 end;
 repeat
  asm
   mov ah, 2Ch
    int 21h
   mov curth, ch
   mov curtm, cl
   mov curts, dh
  end;
  i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
 until i>s;
end;

procedure dothefade;
var temppal: paltype;
    a: integer;
begin
 mymove2(colors,temppal,192);
 for a:=31 downto 0 do
  begin
   for j:=0 to 31 do
    if j<>31 then
     begin
      for i:=1 to 3 do
       temppal[j,i]:=round(a*colors[j,i]/32);
     end
    else
     begin
      if a>16 then
       begin
        for i:=1 to 3 do
         temppal[31,i]:=round((a-16)*colors[31,i]/16);
       end
      else
       begin
        temppal[31,1]:=round(63/16*(16-a));
       end;
     end;
   set256colors(temppal);
   delay(round(tslice*1.6));
  end;
 mymove2(temppal,colors,192);
end;

procedure printxy2(x1,y1,tcolor: integer; s: string);
var letter,a,x,y: integer;
begin
 x1:=x1+4;               { this stupid offset is pissing me off!!!!}
 for j:=1 to length(s) do
  begin
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    'A' ..'Z': letter:=ord(s[j])-36;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    '%': letter:=55;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 5 do
    begin
     x:=x1;
     inc(y);
     for a:=7 downto 4 do
      begin
       inc(x);
       if font[letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor;
      end;
     x:=x1;
     inc(y);
     inc(i);
     for a:=3 downto 0 do
      begin
       inc(x);
       if font[letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor;
      end;
    end;
   x1:=x1+5;
  end;
end;

procedure writestr2(s1,s2,s3: string);
var i,j1,j2,j3,b: integer;
begin
 fillchar(screen,64000,0);
 j1:=156-((length(s1)*5) div 2);
 j2:=156-((length(s2)*5) div 2);
 j3:=156-((length(s3)*5) div 2);
 set256colors(colors);
 b:=tslice div 2;
 for i:=31 downto 0 do
  begin
   printxy2(j1-i,90-i,31-i,s1);
   printxy2(j1-i,90+i,31-i,s1);
   printxy2(j1+i,90-i,31-i,s1);
   printxy2(j1+i,90+i,31-i,s1);
   printxy2(j2-i,100-i,31-i,s2);
   printxy2(j2-i,100+i,31-i,s2);
   printxy2(j2+i,100-i,31-i,s2);
   printxy2(j2+i,100+i,31-i,s2);
   printxy2(j3-i,110-i,31-i,s3);
   printxy2(j3-i,110+i,31-i,s3);
   printxy2(j3+i,110-i,31-i,s3);
   printxy2(j3+i,110+i,31-i,s3);
   delay(b);
  end;
 dothefade;
end;

procedure domainscreen;
var backgr: pscreentype;
begin
 loadscreen('data\main.vga',@screen);
 new(backgr);
 loadscreen('data\cloud.vga',backgr);
 asm
  push es
  push ds
  les si, [backgr]
  mov ax, $A000
  mov ds, ax
  xor si, si
 @@loopit:
  mov al, [ds: si]
  cmp al, 255
  jne @@nodraw
  mov al, [es: si]
  mov [ds: si], al
 @@nodraw:
  inc si
  cmp si, 64000
  jne @@loopit
  pop ds
  pop es
 end;
 dispose(backgr);
end;

procedure scrollmainscreen;
var temp,backgr: pscreentype;
    y1,a,b,t: integer;
begin
 new(temp);
 new(backgr);
 loadscreen('data\main.vga',temp);
 loadscreen('data\cloud.vga',backgr);
 set256colors(colors);
 for i:=1 to 120 do
  mymove2(planet^[i],backgr^[i+12,28],30);
 for y1:=0 to 4 do
  for b:=6 to 138 do
   for a:=10 to 303 do
    if temp^[b,a]=255 then screen[b,a]:=backgr^[b+y1,a+y1];
 t:=tslice div 4;
 for y1:=0 to 36 do
  begin
   for j:=0 to 255 do
    begin
     colors[j,1]:=colors[j,1] + round((63-colors[j,1])/30);
     colors[j,2]:=colors[j,2] - round(colors[j,2]/30);
     colors[j,3]:=colors[j,3] - round(colors[j,3]/30);
    end;
   set256colors(colors);
   delay(t);
  end;
 dispose(backgr);
 dispose(temp);
end;

procedure powerupencodes;
var a,b,y,t,sd,range: integer;
    yadj,pfac,part,temp1,temp3: real;
begin
 sd:=500;
 range:=80;
 yadj:=1800/1920;
 setcolor(31);
 part:=31/36;
 t:=tslice div 2;
 for a:=0 to 5 do
  for b:=0 to 36 do
   begin
    screen[(a mod 3)*30+48,(a div 3)*258+b+13]:=round(b*part)+64;
    screen[(a mod 3)*30+49,(a div 3)*258+b+13]:=round(b*part)+64;
    for i:=128 to 143 do
     colors[i]:=colors[random(22)];
    for i:=144 to 159 do
     colors[i]:=colors[0];
    set256colors(colors);
    delay(t);
    for i:=144 to 159 do
     colors[i]:=colors[random(16)];
    for i:=128 to 143 do
     colors[i]:=colors[0];
    set256colors(colors);
    for i:=(a mod 3)*30+37 to (a mod 3)*30+42 do
     for j:=(a div 3)*138+89 to (a div 3)*138+93 do
      if screen[i,j] div 16=3 then screen[i,j]:=screen[i,j]+32;
   end;
end;

procedure createplanet(xc,yc: integer);
var x1,y1: integer;
    a: longint;
begin
 x1:=xc;
 y1:=yc;
 for a:=1 to 75000 do
  begin
   x1:=x1-1+random(3);
   y1:=y1-1+random(3);
   if x1>240 then x1:=1 else if x1<1 then x1:=240;
   if y1>120 then y1:=1 else if y1<1 then y1:=120;
   if landform^[x1,y1]<240 then landform^[x1,y1]:=landform^[x1,y1]+5;
  end;
end;

procedure generateplanet;
var f: file of landtype;
begin
 randomize;
 assign(f,'data\plan1.dta');
 reset(f);
 if ioresult<>0 then errorhandler('data\plan1.dta',1);
 read(f,landform^);
 if ioresult<>0 then errorhandler('data\plan1.dta',5);
 close(f);
 fillchar(planet^,14400,0);
 water:=50;
 part2:=28/(255-water);
 c:=0;
 ecl:=180;
 radius:=3025;
 c2:=1.09;
 r2:=round(sqrt(radius));
 waterindex:=33;
 for j:=0 to 3 do spcindex[j]:=48+j;
 spcindex[4]:=128;
 spcindex[5]:=129;
end;

procedure setupbreach1;
var a: integer;
begin
 new(shippix);
 new(msgpix);
 new(override);
 for a:=0 to 9 do
  for i:=0 to 19 do
   move(screen[i+(a div 5)*20+20,(a mod 5)*30+110],shippix^[a,i],30);
 for a:=0 to 9 do
  for i:=0 to 4 do
   move(screen[i+(a div 3)*10+20,(a mod 3)*10+60],msgpix^[a,i],10);
 for i:=90 to 110 do
  move(screen[i,200],override^[i,200],41);
 for i:=90 to 110 do
  fillchar(screen[i,200],41,0);
 for i:=20 to 60 do
  fillchar(screen[i,60],201,0);
 fadein;
end;

procedure breach1wait(t: integer);
var modth,modtm,modts,curth,curtm,curts: byte;
    a,b,c: integer;
begin
 asm
  mov ah, 2Ch
   int 21h
  mov modth, ch
  mov modtm, cl
  mov modts, dh
 end;
 repeat
  if random(2)=0 then
   begin
    a:=random(10);
    for i:=0 to 19 do
     move(shippix^[a,i],screen[i+91,100],30);
    for b:=0 to 3 do
     begin
      a:=random(6);
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+90+b*6,70],10);
      if random(2)=0 then
       begin
        a:=random(6);
        for i:=0 to 4 do
         move(msgpix^[a,i],screen[i+90+b*6,80],10);
        c:=90;
       end
      else
       begin
        c:=80;
        for i:=0 to 4 do
         fillchar(screen[i+90+b*6,90],10,0);
       end;
      a:=random(3)+6;
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+90+b*6,c],10);
     end;
    end;
  if random(2)=0 then
   begin
    a:=random(10);
    for i:=0 to 19 do
     move(shippix^[a,i],screen[i+91,220],30);
    for b:=0 to 3 do
     begin
      a:=random(6);
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+90+b*6,190],10);
      if random(2)=0 then
       begin
        a:=random(6);
        for i:=0 to 4 do
         move(msgpix^[a,i],screen[i+90+b*6,200],10);
        c:=210;
       end
      else
       begin
        c:=200;
        for i:=0 to 4 do
         fillchar(screen[i+90+b*6,210],10,0);
       end;
      a:=random(3)+6;
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+90+b*6,c],10);
     end;
   end;
  delay(tslice*10);
  asm
   mov ah, 2Ch
    int 21h
   mov curth, ch
   mov curtm, cl
   mov curts, dh
  end;
  i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
 until i>t;
end;

procedure overridebreach1;
var a: integer;
begin
 for a:=0 to 10 do
  begin
   for i:=90 to 112 do
    begin
     fillchar(screen[i,190],61,0);
     fillchar(screen[i,70],61,0);
    end;
   delay(tslice*5);
   for i:=90 to 110 do
    begin
     move(override^[i,200],screen[i,200],41);
     move(override^[i,200],screen[i,80],41);
    end;
   delay(tslice*8);
  end;
end;

procedure uploadencodes;
var str1: string[4];
    a,b,c,i,j: integer;
begin
 str1:='7A1E';
 for j:=0 to 300 do
  begin
   for b:=0 to 3 do
    begin
     for c:=0 to random(4)+1 do
      begin
       a:=random(6);
       for i:=0 to 4 do
        move(msgpix^[a,i],screen[i+90+b*6,70+c*10],10);
      end;
      if c<4 then
       for i:=0 to 5 do
        fillchar(screen[i+90+b*6,80+c*10],(5-c)*10,0);
      a:=random(3)+6;
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+90+b*6,80+c*10],10);
    end;
   for b:=0 to 3 do
    begin
     for c:=0 to random(4)+1 do
      begin
       a:=random(6);
       for i:=0 to 4 do
        move(msgpix^[a,i],screen[i+90+b*6,190+c*10],10);
      end;
      if c<4 then
       for i:=0 to 5 do
        fillchar(screen[i+90+b*6,200+c*10],(5-c)*10,0);
      a:=random(3)+6;
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+90+b*6,200+c*10],10);
    end;
   delay(tslice div 2);
   printxy(70,30,str1);
   inc(str1[4]);
   if str1[4]='[' then
    begin
     str1[4]:='0';
     inc(str1[3]);
     if str1[3]='[' then
      begin
       str1[3]:='0';
       inc(str1[2]);
      end
     else if str1[3]=':' then str1[3]:='A';
    end
   else if str1[4]=':' then str1[4]:='A';
  end;
 for i:=89 to 112 do
  begin
   fillchar(screen[i,190],61,0);
   fillchar(screen[i,70],61,0);
  end;
end;

procedure setupbreach2;
var a: integer;
begin
 new(peoplepix);
 new(override2);
 for a:=0 to 3 do
  for i:=0 to 28 do
   move(screen[i+21,25+a*30],peoplepix^[a,i],29);
 for a:=0 to 3 do
  for i:=0 to 28 do
   move(screen[i+51,25+a*30],peoplepix^[a+4,i],29);
 for a:=0 to 3 do
  for i:=0 to 28 do
   move(screen[i+21,173+a*30],peoplepix^[a+8,i],29);
 for a:=0 to 3 do
  for i:=0 to 28 do
   move(screen[i+51,173+a*30],peoplepix^[a+12,i],29);
 for i:=0 to 40 do
  move(screen[i+130,30],override2^[i],111);
 for i:=21 to 79 do
  begin
   fillchar(screen[i,24],120,0);
   fillchar(screen[i,173],120,0);
   fillchar(screen[i+100,24],120,0);
  end;
 for i:=21 to 79 do
  begin
   move(screen[i+100,173],screen[i,24],120);
   move(screen[i+100,173],screen[i,173],120);
   move(screen[i+100,173],screen[i+100,24],120);
  end;
 for a:=0 to 9 do
  for i:=0 to 4 do
   for j:=0 to 9 do
    if msgpix^[a,i,j]>0 then msgpix^[a,i,j]:=111;
 a:=random(16);
 for i:=0 to 28 do
  move(peoplepix^[a,i],screen[36+i,191],29);
 a:=random(16);
 for i:=0 to 28 do
  move(peoplepix^[a,i],screen[136+i,191],29);
 a:=random(16);
 for i:=0 to 28 do
  move(peoplepix^[a,i],screen[36+i,42],29);
 a:=random(16);
 for i:=0 to 28 do
  move(peoplepix^[a,i],screen[136+i,42],29);
end;

procedure breach2wait(t: integer);
var modth,modtm,modts,curth,curtm,curts: byte;
    a,b: integer;
begin
 asm
  mov ah, 2Ch
   int 21h
  mov modth, ch
  mov modtm, cl
  mov modts, dh
 end;
 repeat
  for b:=0 to 3 do
    begin
     for c:=0 to random(3)+2 do
      begin
       a:=random(6);
       for i:=0 to 4 do
        move(msgpix^[a,i],screen[i+138+b*6,230+c*10],10);
      end;
      if c<5 then
       for i:=0 to 5 do
        fillchar(screen[i+138+b*6,220+c*10],(7-c)*10,0);
      a:=random(3)+6;
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+138+b*6,220+c*10],10);
    end;
  for b:=0 to 3 do
    begin
     for c:=0 to random(3)+2 do
      begin
       a:=random(6);
       for i:=0 to 4 do
        move(msgpix^[a,i],screen[i+38+b*6,230+c*10],10);
      end;
      if c<5 then
       for i:=0 to 5 do
        fillchar(screen[i+38+b*6,220+c*10],(7-c)*10,0);
      a:=random(3)+6;
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+38+b*6,220+c*10],10);
    end;
  for b:=0 to 3 do
    begin
     for c:=0 to random(3)+2 do
      begin
       a:=random(6);
       for i:=0 to 4 do
        move(msgpix^[a,i],screen[i+138+b*6,81+c*10],10);
      end;
      if c<5 then
       for i:=0 to 5 do
        fillchar(screen[i+138+b*6,71+c*10],(7-c)*10,0);
      a:=random(3)+6;
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+138+b*6,71+c*10],10);
    end;
  for b:=0 to 3 do
    begin
     for c:=0 to random(3)+2 do
      begin
       a:=random(6);
       for i:=0 to 4 do
        move(msgpix^[a,i],screen[i+38+b*6,81+c*10],10);
      end;
      if c<5 then
       for i:=0 to 5 do
        fillchar(screen[i+38+b*6,71+c*10],(7-c)*10,0);
      a:=random(3)+6;
      for i:=0 to 4 do
       move(msgpix^[a,i],screen[i+38+b*6,71+c*10],10);
    end;
  if random(2)=0 then
   begin
    a:=random(16);
    for i:=0 to 28 do
     move(peoplepix^[a,i],screen[36+i,191],29);
   end;
  if random(2)=0 then
   begin
    a:=random(16);
    for i:=0 to 28 do
     move(peoplepix^[a,i],screen[136+i,191],29);
   end;
  if random(2)=0 then
   begin
    a:=random(16);
    for i:=0 to 28 do
     move(peoplepix^[a,i],screen[36+i,42],29);
   end;
  if random(2)=0 then
   begin
    a:=random(16);
    for i:=0 to 28 do
     move(peoplepix^[a,i],screen[136+i,42],29);
   end;
  delay(tslice*10);
  asm
   mov ah, 2Ch
    int 21h
   mov curth, ch
   mov curtm, cl
   mov curts, dh
  end;
  i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
 until i>t;
end;

procedure overridebreach2;
var a: integer;
begin
 for a:=0 to 10 do
  begin
   for i:=0 to 40 do
    begin
     fillchar(screen[i+30,30],111,0);
     fillchar(screen[i+130,30],111,0);
     fillchar(screen[i+30,179],111,0);
     fillchar(screen[i+130,179],111,0);
    end;
   delay(tslice*4);
   for i:=0 to 40 do
    begin
     move(override2^[i],screen[i+30,30],111);
     move(override2^[i],screen[i+130,30],111);
     move(override2^[i],screen[i+30,179],111);
     move(override2^[i],screen[i+130,179],111);
    end;
   delay(tslice*9);
  end;
end;

procedure makeplanet(t: integer; eclipse: boolean);
var modth,modtm,modts,curth,curtm,curts: byte;
label endcheck;
begin
 asm
  mov ah, 2Ch
   int 21h
  mov modth, ch
  mov modtm, cl
  mov modts, dh
 end;
 repeat
  inc(c,1);
  if c>240 then c:=c-240;
  if (eclipse) and (c mod 2=0) then
   begin
    inc(ecl);
    if ecl>340 then ecl:=ecl-340;
   end;
  x:=2*r2+10;
  ofsy:=0;
  for i:=6 to 2*r2+4 do
    begin
     y:=sqrt(radius-sqr(i-r2-5));
     m:=round((r2-y)*c2);
     part:=r2/y;
     inc(ofsy);
     ofsx:=m;
     for j:=1 to x do
      begin
       index:=round(j*part);
       if index>x then goto endcheck;
       inc(ofsx);
       if ecl>170 then
        begin
         if j=1 then alt:=10
          else alt:=(index-ecl+186) div 2;
        end
        else if ecl<171 then
         begin
          if index=x then alt:=10
           else alt:=(ecl-index) div 2
         end
        else alt:=0;
       if alt<0 then alt:=0;
       if (index+c)>240 then j2:=index+c-240
        else j2:=index+c;
       if (alt<6) and (landform^[j2,i]<water) then planet^[ofsy,ofsx]:=waterindex+6-alt
        else if landform^[j2,i]<water then planet^[ofsy,ofsx]:=waterindex
        else
         begin
          z:=round((landform^[j2,i]-water)*part2);
          case z of
           6..31: if z>alt then z:=z-alt else z:=1;
           0..5: if alt>spcindex[z] mod 16 then z:=1 else z:=spcindex[z]-alt;
          end;
          planet^[ofsy,ofsx]:=z;
         end;
 endcheck:
      end;
    end;
  for i:=1 to 120 do
   mymove2(planet^[i],screen[i+12,28],30);
  delay(tslice);
  asm
   mov ah, 2Ch
    int 21h
   mov curth, ch
   mov curtm, cl
   mov curts, dh
  end;
  i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
 until i>t;
end;

procedure readyencode;
begin
 for i:=128 to 143 do
  colors[i]:=colors[random(22)];
 for i:=144 to 159 do
  colors[i]:=colors[0];
 set256colors(colors);
 for i:=0 to 69 do
  for j:=0 to 68 do
   screen[i+40,j+126]:=random(16)+128+(i mod 2)*16;
end;

procedure charcomstuff(t: integer);
var modth,modtm,modts,curth,curtm,curts: byte;
    sd,range,y: integer;
    pfac,yadj,temp1,temp3: real;
begin
 asm
  mov ah, 2Ch
   int 21h
  mov modth, ch
  mov modtm, cl
  mov modts, dh
 end;
 sd:=500;
 range:=80;
 yadj:=1800/1920;
 repeat
  for i:=128 to 143 do
   colors[i]:=colors[random(22)];
  for i:=144 to 159 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2);
  for i:=144 to 159 do
   colors[i]:=colors[random(16)];
  for i:=128 to 143 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2);
  asm
   mov ah, 2Ch
    int 21h
   mov curth, ch
   mov curtm, cl
   mov curts, dh
  end;
  i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
  delay(tslice div 5);
 until i>t;
end;

procedure loadscreens;
var t: pscreentype;
    a,b: integer;
    temppal: paltype;
begin
 fillchar(colors,768,0);
 init320200;
 set256colors(colors);
 new(t);
 for a:=1 to 4 do
  begin
   loadscreen('data\blast0'+chr(a+48)+'.vga',t);
   setpage(a-1);
   for i:=0 to 199 do
    for j:=0 to 319 do
     setpix(j,i,t^[i,j]);
  end;
 dispose(t);
 b:=0;
 fillchar(temppal,768,0);
 for a:=1 to 24 do
  begin
   showpage(b);
   inc(b);
   if b=4 then b:=0;
   for j:=0 to 255 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/24);
   showpage(b);
   inc(b);
   if b=4 then b:=0;
   set256colors(temppal);
   delay(tslice);
  end;
 set256colors(colors);
end;

procedure cycleengines(t: integer);
var modth,modtm,modts,curth,curtm,curts: byte;
begin
 asm
  mov ah, 2Ch
   int 21h
  mov modth, ch
  mov modtm, cl
  mov modts, dh
 end;
 i:=0;
 set256colors(colors);
 repeat
  showpage(i);
  inc(i);
  if i=4 then i:=0;
  asm
   mov ah, 2Ch
    int 21h
   mov curth, ch
   mov curtm, cl
   mov curts, dh
  end;
  delay(tslice div 2);
  j:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
 until j>t;
end;

procedure fadecharcom;
var a: integer;
    temppal: paltype;
begin
 index:=0;
 a:=24;
 mymove2(colors,temppal,192);
 repeat
  inc(index);
  if a>0 then
   for j:=0 to 255 do
    for i:=1 to 3 do
     colors[j,i]:=round(a*temppal[j,i]/24);
  for i:=128 to 143 do
   colors[i]:=colors[random(22)];
  for i:=144 to 159 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2);
  for i:=144 to 159 do
   colors[i]:=colors[random(16)];
  for i:=128 to 143 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2+1);
  if index mod 2=0 then dec(a);
 until a=0;
end;

procedure c7logo;
var t: pscreentype;
    y,x,a,seed,j,index,max: word;
    temppal: paltype;
begin
 new(t);
 tslice:=tslice div 2;
 fillchar(colors,768,0);
 set256colors(colors);
 loadscreen('data\channel7.vga',t);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=random(16)+200+(i mod 2)*16;
 max:=38000;
 index:=0;
 j:=0;
 seed:=159;
 if fastkeypressed then begin dispose(t); exit; end;
 repeat
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  for i:=1 to 70+(90-tslice) do
   begin
    inc(index);
    j:=j+seed;
    if j>max then j:=j-max;
    y:=(j div 300)+30;
    x:=j mod 300+20;
    if t^[y,x]>0 then screen[y,x]:=t^[y,x];
   end;
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 4);
 until index>max;
 a:=31;
 index:=0;
 if fastkeypressed then begin dispose(t); exit; end;
 repeat
  inc(index);
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice);
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 4);
 until index=75;
 index:=0;
 a:=24;
 mymove2(colors,temppal,192);
 if fastkeypressed then begin dispose(t); exit; end;
 repeat
  inc(index);
  if a>0 then
   for j:=0 to 199 do
    for i:=1 to 3 do
     colors[j,i]:=round(a*temppal[j,i]/24);
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2);
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 4);
  if index mod 4=0 then dec(a);
 until a=0;
 dispose(t);
 tslice:=tslice*2;
end;

procedure scale(startx,starty,sizex,sizey,newx,newy: integer; var s,t);
var sety, py, pdy, px, pdx, dcx, dcy, ofsy: integer;
begin
 asm
  push ds
  push es
  les si, [s]         { es: si is our source location }
  mov [ofsy], si
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
  add si, [ofsy]

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

procedure shrinkalienscreen;
var t: pscreentype;
    partx,party: real;
    a,startx,max,starty: integer;
    temppal: paltype;
begin
 fillchar(temppal,768,0);
 for i:=0 to 31 do
  temppal[i]:=colors[i];
 for i:=240 to 255 do
  temppal[i]:=colors[i];
 new(t);
 mymove2(screen,t^,16000);
 max:=25;
 for a:=1 to max do
  begin
   partx:=306-234/max*a;
   party:=177-142/max*a;
   starty:=166-round(party);
   startx:=305-round(partx);
   scale(startx,starty,305,176,320-startx,200-starty,t^,screen);
  end;
 for i:=142 to 176 do
  mymove2(screen[i,234],t^[i,234],18);
 set256colors(temppal);
 loadscreen('data\alien.vga',@screen);
 for i:=142 to 176 do
  mymove2(t^[i,234],screen[i,234],18);
 dispose(t);
end;

procedure fadeinalienscreen;
var a: integer;
    temppal: paltype;
begin
 for i:=240 to 255 do temppal[i]:=colors[i];
 for i:=0 to 31 do temppal[i]:=colors[i];
 for a:=1 to 24 do
  begin
   for j:=32 to 239 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/24);
   set256colors(temppal);
   delay(tslice);
  end;
end;

procedure fadeinintro2;
var a: integer;
    temppal: paltype;
begin
 fillchar(temppal,768,0);
 for a:=1 to 24 do
  begin
   for j:=0 to 31 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/24);
   for j:=49 to 255 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/24);
   set256colors(temppal);
   delay(tslice);
  end;
 for a:=0 to 34 do
  begin
   for i:=32 to 48 do
    colors[i,1]:=round((i-32)*a/17);
   set256colors(colors);
   delay(tslice);
  end;
end;

procedure shipschasing;
var a,b,x1,y1,x2,y2: integer;
    dx1,dx2,dy1,dy2: real;
    t: pscreentype;
begin
 x1:=60;
 y1:=199;
 x2:=20;
 y2:=240;
 dx1:=4.6;
 dx2:=4.9;
 dy1:=-1;
 dy2:=-1;
 new(t);
 mymove2(screen,t^,16000);
 for a:=0 to 180 do
  begin
   mymove2(t^[y1,x1],screen[y1,x1],1);
   mymove2(t^[y1+1,x1],screen[y1+1,x1],1);
   dx1:=dx1-0.05;
   dx2:=dx2-0.05;
   dy1:=dy1+0.003;
   dy2:=dy2-0.004;
   x1:=x1+round(dx1);
   y1:=y1+round(dy1);
   if a<165 then
    begin
     for b:=0 to random(3) do
      screen[y1+random(2),x1+random(2)]:=84+random(3);
     screen[y1,x1]:=17+random(3);
    end;
   if y2<200 then
    begin
     mymove2(t^[y2,x2],screen[y2,x2],1);
     mymove2(t^[y2+1,x2],screen[y2+1,x2],1);
    end;
   x2:=x2+round(dx2);
   y2:=y2+round(dy2);
   if y2<200 then
    begin
     for b:=0 to random(3) do
      screen[y2+random(2),x2+random(2)]:=84+random(3);
     screen[y2,x2]:=17+random(3);
    end;
   delay(round(tslice*1.5));
  end;
 dispose(t);
end;

procedure shipanimation;
var t,bg: pscreentype;
    a,b,x,y,x2,y2,i2,y3,x3: integer;
begin
 new(t);
 loadscreen('data\lilship.vga',t);
 set256colors(colors);
 new(bg);
 y3:=69;
 x2:=148;
 mymove2(screen,bg^,16000);
 for a:=0 to 8 do
  begin
   x:=(a mod 3)*90;
   y:=(a div 3)*60;
   for b:=0 to 5 do
    begin
     dec(y3,2);
     dec(x2,2);
     for i:=0 to 55 do
      begin
       y2:=i+y3;
       i2:=y+i;
       if y2>0 then
        for j:=0 to 82 do
         if t^[i2,x+j]>0 then screen[y2,x2+j]:=t^[i2,x+j]
          else screen[y2,x2+j]:=bg^[y2,x2+j];
       if a<2 then mymove2(bg^[y2,x2+82],screen[y2,x2+82],2);
      end;
     if a<2 then
      begin
       y2:=69-a*10-b;
       for i:=56 to 60 do
        mymove2(bg^[y2+i,x2],screen[y2+i,x2],27);
      end;
     delay(tslice div 3);
    end;
  end;
 wait(1);
 dispose(t);
 dispose(bg);
end;

procedure atmosphereanimation;
var t,bk: pscreentype;
    a,b,x,y: integer;
    dx,dy: real;
begin
 new(t);
 loadscreen('data\world3.vga',t);
 new(bk);
 mymove2(screen,bk^,16000);
 x:=260;
 y:=199;
 dx:=-5.5;
 dy:=-0.970;
 for a:=0 to 100 do
  begin
   mymove2(bk^[y,x],screen[y,x],1);
   mymove2(bk^[y+1,x],screen[y+1,x],1);
   dx:=dx+0.1;
   dy:=dy+0.005;
   x:=x+round(dx);
   y:=y+round(dy);
     for b:=0 to random(3) do
      screen[y+random(2),x+random(2)]:=224+random(3);
     screen[y,x]:=250+random(3);
   delay(round(tslice*1.5));
  end;
 for a:=0 to 15 do
  begin
   x:=(a mod 4)*70;
   y:=(a div 4)*50;
   for i:=0 to 49 do
    mymove2(t^[y+i,x],screen[80+i,190],17);
   delay(tslice*3);
  end;
 for i:=0 to 49 do
  mymove2(bk^[80+i,190],screen[80+i,190],17);
 wait(4);
 dispose(t);
 dispose(bk);
end;

procedure alienscreenwait;
var modth,modtm,modts,curth,curtm,curts: byte;
    x1,y1,x2,y2: integer;
begin
 asm
  mov ah, 2Ch
   int 21h
  mov modth, ch
  mov modtm, cl
  mov modts, dh
 end;
 x1:=183;
 y1:=131;
 x2:=62;
 y2:=148;
 screen[y1,x1]:=screen[y1,x1] xor 31;
 screen[y2,x2]:=screen[y2,x2] xor 31;
 for j:=1 to 7 do
  begin
   screen[y1,x1]:=screen[y1,x1] xor 31;
   screen[y2,x2]:=screen[y2,x2] xor 31;
   dec(x1);
   inc(y1);
   inc(y2);
   screen[y1,x1]:=screen[y1,x1] xor 31;
   screen[y2,x2]:=screen[y2,x2] xor 31;
   repeat
    asm
     mov ah, 2Ch
      int 21h
     mov curth, ch
     mov curtm, cl
     mov curts, dh
    end;
    i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
   until i>j;
  end;
 for j:=3 downto 1 do
  begin
   setcolor(175-j*2);
   circle(x1,y1,j*3+1);
   circle(x2,y2,j*3+1);
   delay(tslice*8);
  end;
end;

procedure fadearea(x1,y1,x2,y2,alt: integer);
begin
 for i:=y1 to y2 do
  for j:=x1 to x2 do
   if screen[i,j]>0 then screen[i,j]:=screen[i,j]+alt;
end;

procedure getbackgroundforis2;
var backgr: pscreentype;
begin
 new(backgr);
 loadscreen('data\cloud.vga',backgr);
 loadscreen('data\main3.vga',@screen);
 for j:=0 to 319 do
  for i:=0 to 199 do
   if screen[i,j]=255 then screen[i,j]:=backgr^[i,j];
 for i:=1 to 120 do
  mymove2(screen[i+12,28],planet^[i],30);
 radius:=400;
 c2:=1.30;
 r2:=round(sqrt(radius));
 c:=random(120);
 ecl:=50;
 makeplanet(0,false);
 m1:=291;
 m2:=201;
 m3:=234;
 m4:=280;
 fadearea(186,35,290,45,32);
 fadearea(186,55,200,65,32);
 fadearea(186,75,233,85,32);
 fadearea(186,95,279,105,32);
 dispose(backgr);
end;

procedure is2wait(alt1,alt2,alt3,alt4: integer);
var modth,modtm,modts,curth,curtm,curts: byte;
    x1,y1,x2,y2: integer;
begin
 asm
  mov ah, 2Ch
   int 21h
  mov modth, ch
  mov modtm, cl
  mov modts, dh
 end;
 repeat
  if m1>190 then
   begin
    fadearea(m1+alt1,35,m1-1,45,-32);
    m1:=m1+alt1;
   end;
  if m2>190 then
   begin
    fadearea(m2+alt2,55,m2-1,65,-32);
    m2:=m2+alt2;
   end;
  if m3>190 then
   begin
    fadearea(m3+alt3,75,m3-1,85,-32);
    m3:=m3+alt3;
   end;
  if m4>190 then
   begin
    fadearea(m4+alt4,95,m4-1,105,-32);
    m4:=m4+alt4;
   end;
  delay(tslice*7);
  asm
   mov ah, 2Ch
    int 21h
   mov curth, ch
   mov curtm, cl
   mov curts, dh
  end;
  i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
 until i>1;
end;

procedure staticscreen;
begin
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=random(16)+200+(i mod 2)*16;
 repeat
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice);
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 4);
 until fastkeypressed;
end;

procedure runintro;
var total,a: integer;
label continue,jumpto;
begin
 bkcolor:=0;
 tcolor:=22;
 printxy(0,0,'Copywrite 1994 Channel 7, Destiny: Virtual');
 wait(0);
 new(planet);
 new(landform);
 if fastkeypressed then goto continue;
 generateplanet;
 if fastkeypressed then goto continue;
 playmod(true,'sound\intro1.mod');
 ampsetpanning(0,Pan_Surround);
 ampsetpanning(1,Pan_Surround);
 mouse.setmousecursor(1);
 if fastkeypressed then goto continue;
{PART I. *********************************************************************}
{#1.1}
 c7logo;
 if fastkeypressed then goto continue;
 loadscreen('data\intro2.vga',@screen);
 fadeinintro2;
 if fastkeypressed then goto continue;
 wait(2);
 fading;
 if fastkeypressed then goto continue;
{#1.2}
 loadpalette('data\main.pal');
 writestr2('A','Destiny: Virtual','Designed Game');
 if fastkeypressed then goto continue;
 wait(1);
 fading;
 if fastkeypressed then goto continue;
 {#1.3}
 showmars;
 printxy2(145,30,29,'Mars');
 printxy2(133,40,30,'3784 A.D.');
 for a:=0 to 63 do
  begin
   setrgb256(29,a,0,0);
   delay(tslice);
  end;
 for a:=0 to 63 do
  begin
   setrgb256(30,a,0,0);
   delay(tslice);
  end;
 colors[29,1]:=63;
 colors[29,2]:=0;
 colors[29,3]:=0;
 colors[30]:=colors[29];
 if fastkeypressed then goto continue;
 wait(2);
 fading;
 if fastkeypressed then goto continue;
{#1.4}
 loadpalette('data\main.pal');
 writestr2('Code Master:','Robert W.','Morgan III');
 if fastkeypressed then goto continue;
 wait(1);
 fading;
 if fastkeypressed then goto continue;
{#1.5}
 domainscreen;
 for i:=1 to 120 do
  mymove2(screen[i+12,28],planet^[i],30);
 makeplanet(0,true);
 fadein;
 tcolor:=31;
 bkcolor:=3;
 printxy(13,151,'Link Established.');
 makeplanet(1,true);
 printxy(13,157,'Security Override ALPHA-C7.');
 makeplanet(1,true);
 printxy(13,163,'Activating IRONSEED Phage.');
 makeplanet(1,true);
 printxy(13,169,'Approach Coordinates:');
 printxy(16,175,'(180.06,29.73,800.41)');
 makeplanet(1,true);
 printxy(13,181,'Autopilot Engaged.');
 makeplanet(1,true);
 scrollmainscreen;
 bkcolor:=0;
 fading;
 if fastkeypressed then goto continue;
{#1.6}
 loadpalette('data\main.pal');
 writestr2('World Design:','Jeremy','Holt');
 wait(1);
 fading;
 if fastkeypressed then goto continue;
{#1.7}
 loadscreen('data\breach1.vga',@screen);
 setupbreach1;
 tcolor:=31;
 breach1wait(1);
 printxy(50,20,'Receiving Transmission...');
 breach1wait(1);
 printxy(50,20,'Uploading Encodes to Port 0x96A9...');
 breach1wait(1);
 printxy(50,30,': 0x');
 uploadencodes;
 printxy(50,30,'Transmission Complete.');
 breach1wait(1);
 printxy(50,40,'Holo-Bitscan Phage Detect Virus');
 printxy(50,46,' at Port 0x96A9.');
 overridebreach1;
 printxy(50,56,'Security Breach!');
 printxy(50,62,' Virus Signature: "IRONSEED".');
 wait(1);
 dispose(shippix);
 dispose(override);
 fading;
 if fastkeypressed then goto continue;
{#1.8}
 loadpalette('data\main.pal');
 writestr2('Soundtrak:','Andrew G. Sega',' Necros of the Psychic Monks');
 wait(1);
 fading;
 if fastkeypressed then goto continue;
{#1.9}
 loadscreen('data\breach2.vga',@screen);
 setupbreach2;
 fadein;
 breach2wait(2);
 overridebreach2;
 dispose(override2);
 dispose(peoplepix);
 dispose(msgpix);
 wait(1);
 fading;
 if fastkeypressed then goto continue;
{#1.10}
 loadpalette('data\main.pal');
 writestr2('Design Consultant:','Chris P.','Cash');
 wait(1);
 fading;
 if fastkeypressed then goto continue;
{#1.11}
 loadscreen('data\charcom.vga',@screen);
 fadein;
 readyencode;
 tcolor:=191;
 printxy(20,153,'Ship IRONSEED to Relay Point:');
 charcomstuff(1);
 printxy(170,153,'Link Established.');
 charcomstuff(1);
 printxy(20,159,'Receiving Encode Variants.');
 powerupencodes;
 charcomstuff(1);
 printxy(20,165,'Wiping Source Encodes.');
 charcomstuff(1);
 printxy(20,171,'Terminating Transmission.');
 charcomstuff(1);
 printxy(20,177,'Control Protocol Transfered to Human Encode "PRIME".');
 charcomstuff(1);
 fadecharcom;
 if fastkeypressed then goto continue;
{#1.12}
 loadpalette('data\main.pal');
 writestr2('Tech Consultant:','David W.','Rankin Jr.');
 wait(1);
 fading;
 if fastkeypressed then goto continue;
{#1.13}
 loadscreens;
 cycleengines(3);
 blast(63,63,63);
 setgraphmode(0);
 set256colors(colors);
 loadscreen('data\cloud.vga',@screen);
 set256colors(colors);
 if fastkeypressed then goto continue;
{#1.14}
 shipanimation;
 fading;
 if fastkeypressed then goto continue;
{PART II. ********************************************************************}
{#2.0}
 stopmod;
 playmod(false,'sound\intro2.mod');
 ampsetpanning(0,Pan_Surround);
 ampsetpanning(1,Pan_Surround);
 wait(2);
 fillchar(colors,768,0);
 fillchar(screen,64000,0);
 set256colors(colors);
 printxy2(117,170,254,'Sometime Later...');
 printxy2(80,180,255,'Thousands of Light Years Away...');
 for a:=0 to 63 do
  begin
   setrgb256(254,a,0,0);
   delay(tslice);
  end;
 wait(3);
 for a:=10 to 63 do
  begin
   setrgb256(255,a,0,0);
   delay(tslice);
  end;
 for i:=1 to 120 do
  for j:=1 to 240 do
   landform^[j,i]:=255-landform^[j,i];
 colors[254,1]:=63;
 colors[255,1]:=63;
 wait(5);
 fading;
 radius:=2000;
 c2:=1.16;
 r2:=round(sqrt(radius));
 c:=random(120);
 ecl:=105;
 if fastkeypressed then goto continue;
{#2.1}
 loadscreen('data\battle1.vga',@screen);
 for i:=1 to 120 do
  mymove2(screen[i+12,28],planet^[i],30);
 makeplanet(0,false);
 fadein;
 makeplanet(12,false);
 fading;
 if fastkeypressed then goto continue;
{#2.2}
 loadscreen('data\ship1.vga',@screen);
 set256colors(colors);
 tcolor:=255;
 wait(2);
 printxy(50,125,'Orders: Approach and Destroy.');
 wait(2);
 printxy(50,135,'Jamming all Emissions.');
 wait(2);
 printxy(50,145,'Targeting...');
 wait(2);
 printxy(50,155,'Locked and Loading...');
 wait(2);
 printxy(50,165,'Closing for Fire...');
 wait(2);
 if fastkeypressed then goto continue;
{#2.3}
 shrinkalienscreen;
 fadeinalienscreen;
 alienscreenwait;
 fading;
 if fastkeypressed then goto continue;
{#2.4}
 getbackgroundforis2;
 fadein;
 tcolor:=26;
 printxy(13,160,'Enemy Closing Rapidly..');
 wait(2);
 printxy(13,167,'Shields Imploding...');
 is2wait(-1,0,0,-2);
 wait(1);
 printxy(13,174,'Destruction Immanent.');
 is2wait(-3,0,-1,-1);
 wait(1);
 printxy(13,182,'Attempting Crash Landing.');
 is2wait(-1,-1,0,0);
 wait(1);
 fading;
 if fastkeypressed then goto continue;
{#2.5}
 radius:=2000;
 c2:=1.16;
 r2:=round(sqrt(radius));
 c:=random(120);
 ecl:=105;
 loadscreen('data\battle1.vga',@screen);
 for i:=1 to 120 do
  mymove2(screen[i+12,28],planet^[i],30);
 makeplanet(0,false);
 fadein;
 wait(4);
 if fastkeypressed then goto continue;
{#2.6}
 shipschasing;
 fading;
 if fastkeypressed then goto continue;
{#2.7}
 loadscreen('data\world2.vga',@screen);
 fadein;
 wait(4);
 atmosphereanimation;
 if fastkeypressed then goto continue;
{#2.8}
 wait(8);
 blast(63,0,0);
 if fastkeypressed then goto continue;
{#end}
 fillchar(colors,768,0);
 set256colors(colors);
                                        { <-- wait here !!!!!}
 loadscreen('data\intro5.vga',@screen);
 fadein;
 while fastkeypressed do readkey;
{FINAL********************************************************************}
continue:
 stopmod;
 dispose(landform);
 dispose(planet);
 if fastkeypressed then
  begin
   while fastkeypressed do readkey;
   fillchar(colors,768,0);
   set256colors(colors);
   loadscreen('data\intro5.vga',@screen);
   fadein;
  end;
 mouseshow;
end;

procedure checkparams;
begin
 if (paramstr(1)<>'/showseed') then
  begin
   closegraph;
   writeln('Do not run this program separately.  Please run IS.EXE.');
   halt(4);
  end;
 if (paramstr(2)='/done') then
  begin
   fillchar(colors,768,0);
   set256colors(colors);
   loadscreen('data\intro5.vga',@screen);
   fadein;
   mouseshow;
   mainloop;
  end
 else if paramcount=10 then
  begin
   textmode(co80);
   writeln(#13+#10+id);
   halt(0);
  end
 else
  begin
   runintro;
   mainloop;
  end;
end;

begin
 initializemod;
 readygraph;
 tslice:=15;
 checkparams;
 closegraph;
 halt(code);
end.


{asega = andy sega}
{homebase = me, beta}
{apeiron = me, beta with music }