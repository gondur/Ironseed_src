program intro;
{$M 2000,120000,120000}

uses crt, graph, data, emstool, gmouse, modplay;

var
 song: pointer;
 i,j,cursor,permx,permy,code: integer;
 temp2: array[0..319,160..199] of byte;
 keymode,quit: boolean;
 key: char;
 modth,modtm,modts,
 curth,curtm,curts: byte;
 vgahandles: array[0..8] of word;

{$L scroller}
{$L v3220pa}
{$F+}
procedure upscroll(tseg,tofs: word); external;
{$F-}
procedure init320200;                            external;
procedure setpix32(x,y: integer; pcolor: byte ); external;
function  getpix32(x,y: integer ): byte ;        external;
procedure setpage32(page: byte );                external;
procedure showpage32(page: byte );               external;

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
   delay(tslice*2);
  end;
 set256colors(colors);
 delay(tslice);
end;

procedure startit;
begin
 case cursor of
  1: code:=1;
  2: runintro;
  3: code:=2;
  4: quit:=true;
 end;
end;

procedure drawcursor;
begin
 if cursor=0 then exit;
 mousehide;
 case cursor of
  1:rectangle(25,158,159,177);
  2:rectangle(43,178,159,197);
  3:rectangle(159,158,283,177);
  4:rectangle(159,178,267,197);
 end;
 mouseshow;
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
 quit:=false;
 repeat
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
  setcolor(207);
  drawcursor;
  delay(tslice*2);
  setcolor(0);
  drawcursor;
 until (quit) or (code>0);
 if quit then
  begin
   blast(63,63,63);
   fading;
   closegraph;
   textmode(co80);
   halt(4);
  end;
end;

procedure showmars;
var vgafile: file of screentype;
    temp: ^screentype;
begin
 fillchar(colors,768,0);
 set256colors(colors);
 loadscreen('data\cloud2.vga');
 new(temp);
 assign(vgafile,'data\world.vga');
 reset(vgafile);
 if ioresult<>0 then errorhandler('data\world.vga',1);
 read(vgafile,temp^);
 if ioresult<>0 then errorhandler('data\world.vga',5);
 close(vgafile);
 loadpal('data\world.pal');
 set256colors(colors);
 upscroll(seg(temp^),ofs(temp^));
 dispose(temp);
end;

procedure focus;
var temp: ^screentype;
    a: integer;
    vgafile: file of screentype;
begin
 new(temp);
 mymove(screen,temp^,16000);
 for a:=2 to 17 do
  begin
  for j:=0 to 319 do
   begin
    for i:=0 to 199 do
     begin
      setfillstyle(1,temp^[i,j]);
      bar(j-a div 2,i-a div 2,j+a div 2,i+a div 2);
      i:=i+a;
      if i>199 then i:=199;
     end;
    j:=j+a;
    if j>319 then j:=319;
   end;
   delay(tslice div 2);
  end;
 assign(vgafile,'data\destiny.vga');
 reset(vgafile);
 read(vgafile,temp^);
 close(vgafile);
 loadpal('data\destiny.pal');
 for a:=17 downto 2 do
  begin
  if a=8 then set256colors(colors);
  for j:=0 to 319 do
   begin
    for i:=0 to 199 do
     begin
      setfillstyle(1,temp^[i,j]);
      bar(j-a div 2,i-a div 2,j+a div 2,i+a div 2);
      i:=i+a;
      if i>199 then i:=199;
     end;
    j:=j+a;
    if j>319 then j:=319;
   end;
  delay(tslice div 2);
 end;
 screen:=temp^;
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

procedure loadhighspeedscreens;
var temp: ^screentype;
    a: integer;
begin
 temp:=ptr(ems.frame0,0);
 init320200;
 set256colors(colors);
 ems.handle:=vgahandles[8];
 ems.restoremap;
 for j:=0 to 319 do
  for i:=0 to 199 do
   setpix32(j,i,temp^[i,j]);
 loadpal('data\land2.pal');
 set256colors(colors);
 ems.savemap;
 for a:=1 to 3 do
  begin
   ems.handle:=vgahandles[a];
   ems.restoremap;
   setpage32(a);
   for j:=0 to 319 do
    for i:=0 to 199 do
     setpix32(j,i,temp^[i,j]);
   ems.savemap;
  end;
end;

procedure displayflares;
var temp: ^screentype;
    a: integer;
begin
 temp:=ptr(ems.frame0,0);
 loadpal('data\flare0.pal');
 set256colors(colors);
 for j:=0 to 3 do
  begin
   ems.handle:=vgahandles[j+4];
   ems.restoremap;
   if ems.error<>0 then errorhandler(ems.getemserrmessage,4);
   mymove(temp^,screen,16000);
   ems.savemap;
   if ems.error<>0 then errorhandler(ems.getemserrmessage,4);
   delay(tslice*4);
  end;
end;

procedure loadlasthighspeed;
var temp: ^screentype;
begin
 temp:=ptr(ems.frame0,0);
 fillchar(colors,768,0);
 set256colors(colors);
 setpage32(0);
 ems.handle:=vgahandles[0];
 ems.restoremap;
 for j:=0 to 319 do
   for i:=0 to 199 do
    setpix32(j,i,temp^[i,j]);
 loadpal('data\highspd.pal');
 set256colors(colors);
 ems.savemap;
end;

procedure removeems;
begin
 for j:=0 to 7 do
  begin
   ems.handle:=vgahandles[j];
   ems.restoremap;
   ems.freemem;
  end;
end;

procedure readyems;
var vgafile: file of screentype;
    str1: string[1];
    temp: ^screentype;
begin
 temp:=ptr(ems.frame0,0);
 for j:=0 to 8 do
  begin
   ems.getmem(4);
   if ems.error<>0 then errorhandler(ems.getemserrmessage,4);
   for i:=0 to 3 do ems.setmapping(i,i);
   if ems.error<>0 then errorhandler(ems.getemserrmessage,4);
   ems.savemap;
   if ems.error<>0 then errorhandler(ems.getemserrmessage,4);
   vgahandles[j]:=ems.handle;
   if j<4 then
    begin
     ems.restoremap;
     str(j,str1);
     assign(vgafile,'data\highspd'+str1+'.vga');
     reset(vgafile);
     if ioresult<>0 then errorhandler('highspd'+str1+'.vga',1);
     read(vgafile,temp^);
     if ioresult<>0 then errorhandler('highspd'+str1+'.vga',5);
     close(vgafile);
     ems.savemap;
    end
   else if j<8 then
    begin
     ems.restoremap;
     str(j-4,str1);
     assign(vgafile,'data\flare'+str1+'.vga');
     reset(vgafile);
     if ioresult<>0 then errorhandler('flare'+str1+'.vga',1);
     read(vgafile,temp^);
     if ioresult<>0 then errorhandler('flare'+str1+'.vga',5);
     close(vgafile);
     ems.savemap;
    end;
  end;
 ems.restoremap;
 assign(vgafile,'data\land2.vga');
 reset(vgafile);
 if ioresult<>0 then errorhandler('land2.vga',1);
 read(vgafile,temp^);
 if ioresult<>0 then errorhandler('land2.vga',5);
 close(vgafile);
 ems.savemap;
end;

procedure runintro;
var total,a: integer;
label startintro,continue;
begin
 ship.options[2]:=120;
 ship.options[3]:=1;
 ship.options[4]:=1;
 fading;
 readyems;


 loadpal('data\channel7.pal');
 loadscreen('data\channel7.vga');
 fadein;
 gettime;
 repeat until timewait(1);

 gettime;
 focus;
 repeat until timewait(4);

 gettime;
 playmod('sound\techno.mod',2,14500);
 showmars;
 fillchar(colors,768,0);
 repeat
  if fastkeypressed then goto continue;
 until timewait(10);

 set256colors(colors);
 loadpal('data\flare4.pal');
 loadscreen('data\flare4.vga');
 fadein2;
 repeat
  if fastkeypressed then goto continue;
 until timewait(15);

 displayflares;
 fillchar(colors,768,0);
 set256colors(colors);
 loadpal('data\land1.pal');
 loadscreen('data\land1.vga');
 repeat
  if fastkeypressed then goto continue;
 until timewait(18);

 fadein2;
 fillchar(colors,768,0);
 repeat
  if fastkeypressed then goto continue;
 until timewait(22);

 loadhighspeedscreens;
 repeat
  if fastkeypressed then goto continue;
 until timewait(29);

 loadlasthighspeed;
 a:=-1;
 repeat
  inc(a);
  if a=4 then a:=0;
  showpage32(a);
  delay(tslice*2);
 until (timewait(46)) or (fastkeypressed);
 if fastkeypressed then goto continue;

 blast(63,0,0);
 setgraphmode(0);
 fading;
 loadpal('data\char.pal');
 loadscreen('data\spy.vga');
 repeat
  if fastkeypressed then goto continue;
 until timewait(76) or (fastkeypressed);

 fadein;
 repeat
  if fastkeypressed then goto continue;
 until timewait(105) or (fastkeypressed);

 fillchar(colors,768,0);
 set256colors(colors);
 loadpal('data\intro.pal');
 loadscreen('data\intro.vga');
 repeat
  if fastkeypressed then goto continue;
 until timewait(115);

 fadein2;
 repeat
  if fastkeypressed then goto continue;
 until timewait(144);

{************************************}
continue:
 modstop;
 removeems;
 if fastkeypressed then
  begin
   setgraphmode(0);
   while fastkeypressed do readkey;
   fillchar(colors,768,0);
   set256colors(colors);
   loadscreen('data\intro.vga');
   loadpal('data\intro.pal');
   set256colors(colors);
  end;
 mouseshow;
end;

begin
 tslice:=60;
 if paramstr(1)<>'/showseed' then
  begin
   closegraph;
   writeln('Invalid Passcode!');
   halt(4);
  end;
 if paramstr(2)='/done' then
  begin
   fillchar(colors,768,0);
   set256colors(colors);
   loadscreen('data\intro.vga');
   loadpal('data\intro.pal');
   fadein2;
   mouseshow;
   mainloop;
  end
 else
  begin
   runintro;
   mainloop;
  end;
 halt(code);
end.