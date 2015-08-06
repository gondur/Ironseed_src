program createmakechardisplay;
uses
  crt,Graph,gmouse,data;
type
 displaytype=array[0..193,0..93] of byte;
var
  bigimage: pointer;
  back1,back2: array[1..11,1..52] of byte;
  Driver, Mode, TestDriver,
  ErrCode,i,j,m,q,index,x  : Integer;
  part: real;
  evenpalette: paltype;
{$F+}

procedure loadpalette;
var palfile: file of paltype;
begin
 assign(palfile,'data\main.pal');
 reset(palfile);
 read(palfile,colors);
 close(palfile);
end;

procedure save;
var vgafile: file of screentype;
    disfile: file of displaytype;
    tempdis: ^displaytype;
begin
 mouse.hide;
 assign(vgafile,'data\char.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
 assign(disfile,'data\char2.dta');
 reset(disfile);
 new(tempdis);
 for j:=105 to 298 do
  for i:=22 to 115 do
   tempdis^[j-105,i-22]:=screen[i,j];
 write(disfile,tempdis^);
 close(disfile);
 mouse.show;
end;

procedure load;
var vgafile: file of screentype;
    disfile: file of displaytype;
    tempdis: ^displaytype;
begin
 mouse.hide;
 assign(vgafile,'data\char.vga');
 reset(vgafile);
 read(vgafile,screen);
 close(vgafile);
 assign(disfile,'data\char1.dta');
 reset(disfile);
 new(tempdis);
 read(disfile,tempdis^);
 setfillstyle(0,0);
 bar(105,22,298,115);
 for j:=105 to 298 do
  for i:=22 to 115 do
   screen[i,j]:=tempdis^[j-105,i-22];
 close(disfile);
 mouse.show;
end;


procedure fadein(n: integer);
var a: integer;
begin
 for j:=0 to 255 do for i:=0 to 2 do evenpalette[j,i]:=0;
 for a:=0 to n do
  begin
   for j:=0 to 255 do
    for i:=0 to 2 do
     evenpalette[j,i]:=evenpalette[j,i] + ((colors[j,i]-evenpalette[j,i]) div 4);
   set256colors(evenpalette);
   delay(x);
  end;
 set256colors(colors);
 delay(x);
end;


procedure curtain(x1,y1,x2,y2: integer);
begin
 for i:=y1 to (y1+y2 div 2) do
  begin
   for j:=x1 to x2 do
    begin
     screen[i,j]:=0;
     screen[y2-i+y1,j]:=0;
    end;
   delay(15);
  end;
end;

procedure plate(x1,y1,x2,y2:integer);
var a,c: integer;
begin
 a:=5; c:=12;
 for j:=x1 to x2 do
   for i:=y1 to y2 do
    begin
     dec(a);
     if a<5 then
      begin
       a:=random(5)*70;
       c:=c-1;
       if c<10 then c:=10+random(2)
        else if c>15 then c:=15-random(2)
        else c:=c+random(3);
      end;
     if screen[i,j]=31 then screen[i,j]:=c;
    end;
end;

procedure shiftit(x1,y1,x2,y2,Alt: integer);
var j: integer;
begin
 for j:=x2 downto x1 do
  for i:=y1 to y2 do
   screen[i,j]:=screen[i,j-2]+alt;
end;

procedure shiftback(x1,y1,x2,y2,Alt: integer);
var j,i: integer;
begin
 for j:=x1 to x2 do
  for i:=y1 to y2 do
   screen[i,j]:=screen[i,j+2]+alt;
end;

procedure glass(x1,y1,x2: integer);
var index,i,j: integer;
begin
 setfillstyle(1,80);
 setcolor(82);
 pieslice(x1,y1+5,0,360,6);
 for j:=x1 to x2 do
  begin
   index:=87;
   for i:=y1 to y1+10 do
    begin
     if (i-y1)>3 then dec(index,2) else inc(index,2);
     screen[i,j]:=index;
   end;
  end;
{ for i:=y1 to y1+10 do
   for j:=x2 downto x1 do
    screen[i,j]:=screen[i,j-i+y1];}
end;

procedure button(x1,y1,x2,y2,c1,c2,alt: integer);
begin
 if c1<c2 then shiftit(x1,y1,x2,y2,alt)
  else shiftback(x1,y1,x2,y2,alt);
 setcolor(c1);
 line(x1-1,y1-1,x1-1,y2+1);
 line(x1-1,y1-1,x2+1,y1-1);
 setcolor(c2);
 line(x2+1,y1,x2+1,y2+1);
 line(x1,y2+1,x2,y2+1);
end;

procedure fadearea(x1,y1,x2,y2,alt: integer);
begin
 for j:=x1 to x2 do
  for i:=y1 to y2 do
   screen[i,j]:=screen[i,j]+alt;
end;

procedure graphit(a,b,c: integer);
var y,ylast,d: integer;
    ans: char;
label ending;
begin {120,37,294,112}
 setcolor(0);
 line(120,75,294,75);
 ylast:=75;
 setfillstyle(0,0);
 bar(120,37,294,112);
 part:=37/100;
 setcolor(127);
 y:=75-round(a*part);
 line(110,y,114,y);
 y:=75+round(a*part);
 line(110,y,114,y);
 setcolor(198);
 y:=75-round(b*part);
 line(111,y,115,y);
 y:=75+round(b*part);
 line(111,y,115,y);
 setcolor(183);
 y:=75-round(c*part);
 line(112,y,116,y);
 y:=75+round(c*part);
 line(112,y,116,y);
 



 setcolor(175);
 j:=123;
 for j:=123 to 294 do
 begin
{  setwritemode(xorput);
  line(j,37,j,112);
  delay(x*50);
  line(j,37,j,112);
}  inc(j,2);
   if j>294 then exit;
{   begin
    j:=123;
    putimage(120,37,bigimage^,0);
   end;
}  setcolor(64+((j-123) mod 32));
  setwritemode(0);
   d:=random(6);
   case d of
    0:i:=round(a*part);
    1:i:=round(b*part);
    2:i:=round(c*part);
    3:i:=-round(a*part);
    4:i:=-round(b*part);
    5:i:=-round(c*part);
   end;
   line(j-2,ylast,j,i+75);
   ylast:=i+75;
 end;
end;


procedure drawscreen;
var max,i,j: integer;
    ans: char;
label endofline,endofline2;

begin
 setfillstyle(1,31);
 bar(0,0,319,198);
 plate(0,0,319,198);
 button(1,1,318,197,22,8,0);
 button(2,2,317,196,22,8,0);
 button(11,11,308,187,8,22,0);
 button(12,12,307,186,8,22,0);
 button(22,22,88,88,40,54,30);
 button(25,25,85,85,54,40,0);

 button(92,127,298,178,40,54,30);
 button(95,130,295,175,54,40,0);

{ fadearea(109,26,302,119,-5);
{ fadearea(109,26,299,116,+5);}
 button(105,22,298,115,40,54,30);
 button(120,37,295,112,54,40,0);
{ fadearea(120,37,294,112,-2);}

 setwritemode(0);
 for j:=0 to 4 do button(30,100+j*15,80,111+j*15,40,54,30);

 settextjustify(centertext,toptext);
 setcolor(0);
 settextstyle(2,horizdir,1);
 setusercharsize(10,6,2,2);
 setcolor(38);
 outtextxy(55,100,'NAME');
 setcolor(38);
 outtextxy(55,115,'STAT');
 setcolor(38);
 outtextxy(55,130,'ICON');
 setcolor(38);
 outtextxy(55,145,'SHIP');
 setcolor(38);
 outtextxy(55,160,'CREW');

 setcolor(5);
 outtextxy(54,99,'NAME');
 setcolor(5);
 outtextxy(54,114,'STAT');
 setcolor(5);
 outtextxy(54,129,'ICON');
 setcolor(5);
 outtextxy(54,144,'SHIP');
 setcolor(5);
 outtextxy(54,159,'CREW');

 settextstyle(2,0,4);
 setcolor(38);
 outtextxy(175,22,'ELECTROENCENPHALAGRAPH');
 setcolor(5);
 outtextxy(174,22,'ELECTROENCENPHALAGRAPH');

 ans:=' ';
 getmem(bigimage,64000);
 getimage(105,22,298,115,bigimage^);
 repeat
  if keypressed then
   begin
    ans:=readkey;
    if ans=' ' then
     begin
       putimage(105,22,bigimage^,0);
       graphit(random(100),random(100),random(100));
     end;
    end;
  dec(i);
  i:=i mod 32;
  for j:=64 to 96 do
   colors[j]:=colors[j-32+i];
  set256colors(colors);
  delay(x);
 until ans=#13;
 freemem(bigimage,64000);
 j:=120;
 i:=0;
 setwritemode(0);
 i:=random(100); j:=random(100);
 if (i+j)>175 then
 graphit(i,j,random(175-i-j));
 setwritemode(xorput);

{ getimage(99,99,151,151,image);
 getimage(99,99,151,151,image2);
 fadearea(104,104,155,155,-1);
 putimage(99,99,image2,copyput);
 button(100,100,150,150,40,54,40);
 readln;
 fadearea(104,104,155,155,+1);
 putimage(99,99,image,copyput);}
end;


procedure test;
var ans: char;
begin
 ans:=' ';
 getmem(bigimage,64000);
 getimage(105,22,298,115,bigimage^);
 repeat
  if keypressed then
   begin
    ans:=readkey;
    if ans=' ' then
     begin
       putimage(105,22,bigimage^,0);
       graphit(random(100),random(100),random(100));
     end;
    end;
  dec(i);
  i:=i mod 32;
  for j:=64 to 96 do
   colors[j]:=colors[j-32+i];
  set256colors(colors);
  delay(x);
 until ans=#13;
 freemem(bigimage,64000);
end;

procedure setpalette;
begin
 for j:=0 to 31 do for i:=1 to 2 do colors[j,i]:=0;
 index:=1;
 for j:=32 to 63 do
  begin
   for i:=0 to 2 do colors[j,i]:=index;
   inc(index,2);
  end;
 set256colors(colors);
end;

procedure changes;
begin
{ textcolor:=31;
 backcolor:=255;
 printxy(96,133,'1:');
 printxy(156,133,'2:');
 printxy(216,133,'3:');
 printxy(96,139,'4:');
 printxy(156,139,'5:');
 printxy(216,139,'6:');
 printxy(96,145,'7:');
 printxy(156,145,'8:');
 printxy(216,145,'9:');
 printxy(96,151,'4');
 printxy(96,157,'5');
 printxy(96,163,'6');
 printxy(96,169,'7');

 textcolor:=127;
 backcolor:=31;
 printxy(108,133,'ROBERT W MORGAN     ENG');
 setfillstyle(0,0);
 bar(96,131,253,174);
}
 for j:=0 to 319 do
  for i:=0 to 199 do
   if (screen[i,j]>31) and (screen[i,j]<64) then screen[i,j]:=screen[i,j]-32
   else if screen[i,j]<32 then screen[i,j]:=0;
end;

begin
  readygraph;
  val(paramstr(1),x,m);
  if m<>0 then x:=125;
  tcolor:=31;
  bkcolor:=0;
  randomize;
  loadpalette;
  load;
{  drawscreen;}
  changes;
  mouse.show;
  test;
{  save;}
  Closegraph;
  mouse.hide;
end.


