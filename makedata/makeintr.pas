program makeintro;
uses crt,data,graph,voctool;
{$M 64000,0,32000}
const
 x: byte=120;
var
 j,i: integer;
 song: pointer;
 evenpalette: paltype;
 temp: array[0..319,160..199] of byte;
   

procedure fading(n: integer);
var a: integer;
begin
 evenpalette:=colors;
 for a:=0 to n do
  begin
   for j:=0 to 255 do
    for i:=0 to 2 do
      evenpalette[j,i]:=evenpalette[j,i] - (evenpalette[j,i] div 4);
   set256colors(evenpalette);
   if a<n then delay(tslice*3);
  end;
  for j:=0 to 255 do for i:=0 to 2 do evenpalette[j,i]:=0;
  set256colors(evenpalette);
  delay(tslice*5);
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
   delay(tslice*3);
  end;
 set256colors(colors);
 delay(tslice*5);
end;

procedure plate(x1,y1,x2,y2:integer);
var a,c,part: integer;
begin
 a:=5; c:=8;
 for j:=x1 to x2 do
  begin
   part:=abs(j-160) div 10;
   c:=8;
   for i:=y1 to y2 do
    begin
     dec(a);
     if a<5 then
      begin
       a:=(random(5)+1)*100;
       c:=c-1;
       if c<(5+part) then c:=5+part+random(3)
        else if c>(11+part) then c:=11+part-random(3)
        else c:=c+random(3);
      end;
     if screen[i,j]=12 then screen[i,j]:=c;
    end;
   end;
end;

procedure load;
var vgafile: file of screentype;
begin
 fading(11);
 if (vocgetbuffer(song,'sound\present2.voc'))
  and (vocdriverinstalled) then vocoutput(song);
 assign(vgafile,'data\nexus.vga');
 reset(vgafile);
 read(vgafile,screen);
 close(vgafile);
 fadein(13);
 repeat
 until  vocstatusword=0;
 fading(11);
 if (vocgetbuffer(song,'sound\song2.voc'))
  and (vocdriverinstalled) then vocoutput(song);
 assign(vgafile,'data\intro.vga');
 reset(vgafile);
 read(vgafile,screen);
 close(vgafile);
 for j:=0 to 319 do
  for i:=160 to 199 do
   begin
    temp[j,i]:=screen[i,j];
    screen[i,j]:=0;
   end;
 fadein(13);
end;

procedure save;
var vgafile: file of screentype;
begin
 assign(vgafile,'data\intro.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

procedure drawgrid;
begin
 setcolor(0);
 for j:=1 to 19 do line(0,j*10,319,j*10);
 for j:=1 to 31 do line(j*10,0,j*10,199);
end;

procedure drawscreen;
begin
 setfillstyle(1,3);
 bar(0,0,319,199);
 setcolor(12);
 setfillstyle(1,12);
 setaspectratio(1,4);
 pieslice(160,75,0,360,131);
 drawgrid;
 settextjustify(lefttext,toptext);
{ settextstyle(2,horizdir,1);
 setusercharsize(1,1,5,4);}
 settextstyle(5,horizdir,1);
 setcolor(12);
 settextjustify(righttext,toptext);
 outtextxy(149,184,'INTRODUCTION');
 outtextxy(149,164,'BEGIN NEW GAME');
 settextjustify(lefttext,toptext);
 outtextxy(169,164,'CONTINUE GAME');
 outtextxy(169,184,'QUIT TO DOS');
 setcolor(12);
 settextjustify(righttext,toptext);
 outtextxy(150,185,'INTRODUCTION');
 outtextxy(150,165,'BEGIN NEW GAME');
 settextjustify(lefttext,toptext);
 outtextxy(170,165,'CONTINUE GAME');
 outtextxy(170,185,'QUIT TO DOS');
{ plate(0,0,319,199);}
end;

procedure changes;
begin
 for j:=0 to 319 do
  for i:=0 to 199 do
   if screen[i,j]=3 then screen[i,j]:=0;
end;

procedure test;
var t: integer;
    index: byte;
begin
 setcolor(47);
 setlinestyle(0,0,0);
 setwritemode(xorput);
 repeat
 until vocstatusword=0;
 if (vocgetbuffer(song,'sound\intrlzr.voc'))
  and (vocdriverinstalled) then vocoutput(song);
 for t:=20 to 300 do
  begin
   line(120,75,t,160);
   line(120,75,t,199);
   line(t,160,t,199);
   delay(tslice div 8);
   line(120,75,t,160);
   line(120,75,t,199);
   line(t,160,t,199);
   for j:=160 to 199 do
    screen[j,t]:=temp[t,j];
  end;
{ screen[74,120]:=255;
 screen[75,120]:=255;
 screen[76,120]:=255;
 screen[75,119]:=255;
 screen[75,120]:=255;
 screen[75,121]:=255;
 screen[74,119]:=255;
 screen[76,119]:=255;
 screen[74,121]:=255;
 screen[76,121]:=255;
 index:=0;
 repeat
  inc(index);
  index:=index mod 64;
  if index<32 then t:=index else t:=64-index;
  setrgb256(255,t+32,t+32,t+32);
  delay(10);
 until fastkeypressed;}
end;


begin
 load;
{ drawscreen;}
{ plate(0,0,319,199);}
 test;
 readln;
 closegraph;
end.