program createmaindisplay;
{$M 64000,0,512000}
uses crt,graph,data,gmouse;
type
 fonttype= array[1..3] of byte;
 landtype= array[1..240,1..120] of byte;
 startype= array[1..4] of integer;
 plantype= array[1..120,1..120] of byte;
 imagetype= array[0..125,1..155] of byte;
 toptype=array[0..18,168..300] of byte;
var
  evenpalette: paltype;
  image,image2: ^imagetype;
  image3,image4: array[1..46,1..52] of byte;
  back1,back2: array[1..11,1..52] of byte;
  landform,landform2: ^landtype;
  i,j,m,q,index,x,y  : Integer;
  part,f: real;
  stars: array[0..200] of startype;
  planet: ^plantype;

{$F+}
procedure save;
var vgafile: file of screentype;
begin
 assign(vgafile,'data\main.vga');
 reset(vgafile);
 if ioresult<>0 then errorhandler('main.vga',1);
 write(vgafile,screen);
 close(vgafile);
end;

procedure load;
var vgafile: file of screentype;
begin
 assign(vgafile,'data\main.vga');
 reset(vgafile);
  if ioresult<>0 then errorhandler('main.vga',1);
 read(vgafile,screen);
 close(vgafile);
end;

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
   if a<n then delay(2*x);
  end;
  for j:=0 to 255 do for i:=0 to 2 do evenpalette[j,i]:=0;
  set256colors(evenpalette);
  delay(5*x);
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
   delay(2*x);
  end;
 set256colors(colors);
 delay(5*x);
end;

procedure curtain(x1,y1,x2,y2: integer);
begin
 for i:=y1 to (y1+y2 div 2) do
  begin
   for j:=x1 to x2 do
    begin
     screen[i,j]:=2;
     screen[y2-i+y1,j]:=2;
    end;
   delay(x);
  end;
end;

procedure fadearea(x1,y1,x2,y2,alt: integer);
var i,j: integer;
begin
 for j:=x1 to x2 do
  for i:=y1 to y2 do
   screen[i,j]:=screen[i,j]+alt;
end;

procedure fadearea2(x1,y1,x2,y2,alt: integer);
var i,j: integer;
begin
 for j:=x1 to x2 do
  for i:=y1 to y2 do
  if screen[i,j]>3 then screen[i,j]:=screen[i,j]+alt;
end;

procedure unsprinkle(x1,y1,x2,y2,seed: integer);
var total,j,max,a,b: word;
begin
 total:=0;
 max:=(x2-x1)*(y2-y1);
 j:=0;
 repeat
  inc(total);
  j:=j+seed;
  if j>max then j:=j-max;
  a:=j div (x2-x1);
  b:=j mod (x2-x1);
  if total<max then screen[y1+a,x1+b]:=image^[a,b];
  if total mod 50=0 then delay(x div 20);
 until total>=max;
end;

procedure sprinkle(x1,y1,x2,y2,seed: integer);
var total,j,max: word;
begin
 max:=(x2-x1)*(y2-y1);
 total:=0;
 j:=0;
 repeat
  inc(total);
  j:=j+seed;
  if j>max then j:=j-max;
  screen[y1+j div (x2-x1),x1+j mod (x2-x1)]:=2;
  if total mod 50=0 then delay(x div 20);
  until total>max;
end;

procedure getmainplate;
begin
 for j:=8 to 162 do
  for i:=8 to 132 do image^[i-8,j-8]:=screen[i,j];
end;

procedure getmainplate2;
begin
 for j:=11 to 160 do
  for i:=11 to 130 do image2^[i-11,j-11]:=screen[i,j];
end;

procedure getcube;
begin
 for j:=215 to 265 do
  for i:=145 to 189 do
   image3[i-144,j-214]:=screen[i,j];
end;

procedure getback;
begin
 for j:=215 to 265 do
  for i:=134 to 144 do
   back1[i-133,j-214]:=screen[i,j];
 for j:=215 to 265 do
  for i:=190 to 199 do
   back2[i-189,j-214]:=screen[i,j];
end;

procedure putcube;
begin
 for j:=215 to 265 do
  for i:=145 to 189 do
   screen[i,j]:=image4[i-144,j-214];
end;

procedure rotate(x1,y1,x2,y2: integer);
var i,j,a,n,index: integer;
begin
 n:=(x2-x1) div 2;
 for a:=1 to 25 do
  begin
   for i:=y1 to y2 do
    begin
     index:=n+1;
     for j:=n+x1 downto x1 do
      if j mod a=0 then
       begin
        dec(index);
        screen[i,index+x1]:=image2^[i-x1,j-y1];
       end;
     for j:=index+x1 downto x1 do screen[i,j]:=2;
     index:=n-1;
     for j:=n+x1 to x2 do
      if j mod a=0 then
       begin
        inc(index);
        screen[i,index+x1]:=image2^[i-x1,j-y1];
       end;
     for j:=index+x1 to x2 do screen[i,j]:=2;
    end;
   if a>25 then exit;
   a:=round(a*1.2);
   delay(x);
  end;
end;

procedure rotate3(x1,y1,x2,y2: integer);
var i,j,a,n,index: integer;
begin
 n:=(x2-x1) div 2;
 for a:=1000 downto 1 do
  begin
   for i:=y1 to y2 do
    begin
     index:=n+1;
     for j:=n+x1 downto x1 do
      if j mod a=0 then
       begin
        dec(index);
        screen[i,index+x1]:=image2^[i-y1,j-x1];
       end;
     for j:=index+x1 downto x1 do screen[i,j]:=2;
     index:=n-1;
     for j:=n+x1 to x2 do
      if j mod a=0 then
       begin
        inc(index);
        screen[i,index+x1]:=image2^[i-y1,j-x1];
       end;
     for j:=index+x1 to x2 do screen[i,j]:=2;
    end;
   a:=a div 2;
   if a=0 then exit;
   delay(x);
  end;
end;

procedure plate(x1,y1,x2,y2:integer);
var a,c: integer;
begin
 a:=5; c:=8;
 for j:=x1 to x2 do
   for i:=y1 to y2 do
    begin
     dec(a);
     if a<5 then
      begin
       a:=random(5)*70;
       c:=c-1;
       if c<4 then c:=4+random(4)
        else if c>12 then c:=12-random(4)
        else c:=c+random(3);
      end;
     if screen[i,j]=31 then screen[i,j]:=c;
    end;
end;

procedure shiftit(x1,y1,x2,y2,alt: integer);
var j: integer;
begin
 for j:=x2 downto x1 do
  for i:=y1 to y2 do
   screen[i,j]:=screen[i,j-2]+alt;
end;

procedure shiftback(x1,y1,x2,y2,alt: integer);
var j: integer;
begin
 for j:=x1 to x2 do
  for i:=y1 to y2 do
   screen[i,j]:=screen[i,j+2]+alt;
end;

procedure glass(x1,y1,x2: integer);
var index,i,j: integer;
begin
 setfillstyle(1,7);
 setcolor(5);
 pieslice(x1,y1+5,0,360,6);
 for j:=x1 to x2 do
  begin
   index:=7;
   for i:=y1 to y1+10 do
    begin
     if (i-y1)>3 then dec(index,2) else inc(index,2);
     screen[i,j]:=index;
   end;
  end;
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

procedure sbutton(x1,y1,x2,y2,cs,c1,c2: integer);
begin
 setfillstyle(1,cs);
 bar(x1,y1,x2,y2);
 setcolor(c1);
 line(x1-1,y1-1,x1-1,y2+1);
 line(x1-1,y1-1,x2+1,y1-1);
 setcolor(c2);
 line(x2+1,y1,x2+1,y2+1);
 line(x1,y2+1,x2,y2+1);
end;

procedure erasestars;
begin
 for j:=0 to 200 do
  if stars[j,4]=0 then screen[stars[j,2],stars[j,1]]:=2;
end;

procedure drawstars(x1,y1: integer);
var x,y: integer;
begin
 for j:=0 to 200 do
  begin
   x:=stars[j,1]+x1;
   y:=stars[j,2]+y1;
   if y>150 then y:=y-150
    else if y<0 then y:=y+150;
   if x>310 then x:=x-310
    else if x<0 then x:=x+310;
   stars[j,1]:=x;
   stars[j,2]:=y;
   if screen[y,x]=2 then stars[j,4]:=0
    else stars[j,4]:=1;
   if stars[j,4]=0 then screen[y,x]:=stars[j,3];
  end;
end;

{****************************************************************************}
procedure drawscreen;
var max,a,b: integer;
begin
 setfillstyle(1,2);
 bar(0,0,319,199);
 
 setcolor(31);
 rectangle(0,0,299,199);
 rectangle(1,1,298,198);
 setfillstyle(solidfill,31);
 bar(0,140,319,199);
 bar(160,120,319,140);
 bar(300,0,319,160);
 max:=19;
 for j:=160 to 180 do
  begin
   for i:=120 to 120+max do screen[i,j]:=2;
   dec(max);
  end;
 setcolor(26);
 line(3,139,160,139);
 setcolor(20);
 line(160,140,180,120);
 line(159,139,179,119);
 line(160,140,179,119);
 line(159,139,180,120);
 setcolor(26);
 line(180,120,298,120);
 line(181,119,298,119);
 line(297,119,297,4);
 setcolor(6);
 line(2,2,298,2);
 line(3,3,298,3);
 setcolor(8);
 line(2,2,2,140);
 line(3,3,3,140);
 setcolor(26);
 line(298,120,298,3);
 line(2,140,160,140);
 setfillstyle(1,10);
 bar(303,8,315,43);

 plate(0,0,319,199);

 shiftback(5,145,175,195,2);
 sbutton(11,149,172,191,3,24,8);

 for j:=0 to 2 do
  button(186,131+j*20,203,139+j*20,22,8,0);
 for j:=0 to 2 do
  button(280,131+j*20,297,139+j*20,22,8,0);
 tcolor:=31;
 printxy(183,132,'PSY');
 printxy(183,152,'ENG');
 printxy(183,172,'SCI');
 printxy(277,132,'SEC');
 printxy(277,152,'AST');
 printxy(277,172,'MED');

 for j:=0 to 2 do
  for i:=0 to 2 do
   sbutton(216+j*17,136+i*15,230+j*17,148+i*15,199,203,194);

{  for b:=0 to 25 do
   print(11+b*5,151,chr(b+65));
  print(11,157,' !"''()*+,-./0123456789:;<=>?');
  print(11,163,'HELLO THERE!');
  print(11,169,'DOES IT WORK?');
  print(11,175,'TRY AGAIN....');
  print(11,181,'123456789012345678901234567890');
}
 setcolor(26);
 line(6,145,177,145);
 line(6,145,6,195);
 setcolor(8);
 line(177,145,177,195);
 line(7,195,177,195);
 setfillstyle(1,224);
 bar(304,9,314,18);
 setfillstyle(1,227);
 bar(305,10,315,19);
 setfillstyle(1,228);
 bar(304,21,314,30);
 setfillstyle(1,231);
 bar(305,22,315,31);
 setfillstyle(1,232);
 bar(304,33,314,42);
 setfillstyle(1,235);
 bar(305,34,315,43);

 setcolor(224);
 for j:=0 to 6 do
  begin
   setcolor(236+j);
   setfillstyle(1,236+j);
    pieslice(310,65+j*20,0,360,4);
   setcolor(8);
   arc(310,65+j*20,45,260,4);
   setcolor(20);
   arc(310,65+j*20,260,360,4);
   arc(310,65+j*20,0,45,4);
  end;
 tcolor:=47;
 bkcolor:=255;
 printxy(298,55,'PWR');
 printxy(298,75,'SHD');
 printxy(298,95,'WEA');
 printxy(298,115,'ENG');
 printxy(298,135,'LIF');
 printxy(298,155,'COM');
 printxy(298,175,'CPU');
 tcolor:=31;

{ setfillstyle(1,2);
 bar(10,10,160,130);
 setcolor(42);
 setlinestyle(0,0,3);
 setcolor(45);
 rectangle(9,9,161,131);
 setcolor(47);
 setlinestyle(0,0,0);
 rectangle(9,9,161,131);}

{ setfillstyle(1,3);
 bar(170,10,290,110);}
{ for j:=0 to 3 do
  glass(178,20+j*20,288);
}
{debug!!!}
{fadearea(178,20,250,30,+32);
 fadearea(178,40,200,50,+80);
 fadearea2(173,20,177,30,+32);
 fadearea2(173,40,177,50,+80);
}
{ tcolor:=10;
 print(173,13,'HULL INTEGRITY');
 print(173,33,'PRIMARY POWER');
 print(173,53,'SECONDARY POWER');
 print(173,73,'SHIELD STRENGTH');
 print(173,95,'STARDATE:');
 print(173,103,'LOCATION:');
 
 tcolor:=31;
 print(172,12,'HULL INTEGRITY');
 print(172,32,'PRIMARY POWER');
 print(172,52,'SECONDARY POWER');
 print(172,72,'SHIELD STRENGTH');
 print(172,94,'STARDATE:');
 print(172,102,'LOCATION:');
}

{ setlinestyle(0,0,3);
 setcolor(83);
 rectangle(169,9,291,112);
 setcolor(85);
 setlinestyle(0,0,0);
 rectangle(169,9,291,112);}
end;
{****************************************************************************}

procedure changes;
var temp: array[0..20,0..130] of byte;
    tempptr: pointer;
    a,b: integer;
    temp2: toptype;
    temp2file: file of toptype;
begin
{ for j:=0 to 20 do
  for i:=0 to 130 do
   temp[j,i]:=screen[j+120,i+170];
 for j:=0 to 20 do
  for i:=0 to 130 do
   screen[j,i+170]:=temp[20-j,i];
 setfillstyle(0,0);
 bar(180,2,295,16);
 print(177,3,'PLANETARY SCAN:');
 print(177,9,'  IN PROGRESS..FFEE');

 getmem(tempptr,12000);
 getimage(175,140,210,190,tempptr^);
 putimage(175,145,tempptr^,0);
 getimage(275,140,300,190,tempptr^);
 putimage(275,145,tempptr^,0);
 getimage(175,122,300,140,tempptr^);
 putimage(175,0,tempptr^,0);
 freemem(tempptr,16000);
  setfillstyle(0,0);
 bar(180,124,295,138);

 for a:=0 to 2 do
  for i:=144 to 218 do
   begin
    b:=screen[i,276-a];
    for j:=276-a to 300-a do
     screen[i,j]:=screen[i,j+1];
    screen[i,300-a]:=b;
   end;
 setcolor(24);
 line(162,149,162,191);
}
{ assign(temp2file,'data\toppanel.vga');
 reset(temp2file);
 for j:=168 to 300 do
  for i:=0 to 18 do
   temp2[i,j]:=screen[i,j];
 write(temp2file,temp2);
 close(temp2file);
 for j:=0 to 3 do
  begin
   glass(292,35+j*20,297);
   fadearea(293,34+j*20,297,46+j*20,6);
  end;}
{ for a:=0 to 99 do
  for j:=186+a to 192+a do
   for i:=1 to 4 do
    for b:=0 to 10 do
     screen[i*20+15+b,j-1]:=screen[i*20+15+b,j];
}
{ bkcolor:=255;
  tcolor:=10;
 printxy(192,37,'HULL INTEGRITY');
 printxy(192,57,'PRIMARY POWER');
 printxy(192,77,'SECONDARY POWER');
 printxy(192,97,'SHIELD STRENGTH');
 tcolor:=31;
 printxy(191,36,'HULL INTEGRITY');
 printxy(191,56,'PRIMARY POWER');
 printxy(191,76,'SECONDARY POWER');
 printxy(191,96,'SHIELD STRENGTH');
}

 for a:=0 to 2 do
  for j:=185 to 195 do
   for i:=0 to 10 do
    screen[35+a*20+i,j]:=screen[i+95,j];


{  for a:=0 to 99 do
 for j:=292 downto 186+a do
  for i:=1 to 4 do
   for b:=0 to 10 do
    screen[i*20+15+b,j]:=screen[i*20+15+b,j-1];
}
end;

procedure testcube;
var t: integer;
label skip1,skip2,skip3;
begin  {218,144}
 getcube;
 for j:=1 to 51 do for i:=1 to 45 do image4[i,j]:=image3[i,j];
 setfillstyle(0,0);
 for t:=1 to 31 do
  begin
  for i:=215 to 232 do
   begin
    q:=round(sin(t/20)*45);
    m:=round(51*(sqrt(2)-1)*0.5*sin(t/10));
    part:=45/q;
    for j:=134 to 144-m do screen[j,i]:=back1[j-133,i-214];
    for j:=1 to q do
     begin
      index:=round(j*part);
      if index<46 then screen[j+144-m,i]:=image4[index,i-214];
     end;
    if (45+2*m-q)=0 then goto skip1;
    part:=45/(45+2*m-q);
    for j:=144-m+q to 189+m do
     begin
      index:=round((j-143+m-q)*part);
      if index<46 then screen[j,i]:=image3[index,i-214];
     end;
skip1:
    for j:=179+m to 189 do screen[j,i]:=back2[j-178-m,i-214];
   end;
  for i:=233 to 249 do
   begin
    for j:=134 to 144-m do screen[j,i]:=back1[j-133,i-214];
    q:=round(sin((31-t)/20)*45);
    if q=0 then goto skip2;
    part:=45/q;
    for j:=1 to q do
     begin
      index:=round(j*part);
      if index<46 then screen[j+144-m,i]:=image4[index,i-214];
     end;
    if (45+2*m-q)=0 then goto skip2;
    part:=45/(45+2*m-q);
    for j:=144-m+q to 189+m do
     begin
      index:=round((j-143+m-q)* part);
      if index<46 then screen[j,i]:=image3[index,i-214];
     end;
skip2:
    for j:=179+m to 189 do screen[j,i]:=back2[j-178-m,i-214];
   end;
  for i:=250 to 265 do
   begin
    q:=round(sin(t/20)*45);
    part:=45/q;
    for j:=134 to 144-m do screen[j,i]:=back1[j-133,i-214];
    for j:=1 to q do
     begin
      index:=round(j*part);
      if index<46 then screen[j+144-m,i]:=image4[index,i-214];
     end;
    if (45+2*m-q)=0 then goto skip3;
    part:=45/(45+2*m-q);
    for j:=144-m+q to 189+m do
     begin
      index:=round((j-143+m-q)* part);
      if index<46 then screen[j,i]:=image3[index,i-214];
     end;
skip3:
    for j:=179+m to 189 do screen[j,i]:=back2[j-178-m,i-214];
   end;
  end;
 putcube;
end;

procedure makesphere(x1,x2,y2,r,water,ecl: integer);
var y,part2,part3,c: real;
    j2,r2,alt: integer;
label endcheck;
begin
 part2:=32/(255-water);
 if r<900 then c:=1.30
  else if r>2000 then c:=1.09
  else c:=1.15;
 r2:=round(sqrt(r));
 for i:=6 to 2*r2+4 do
   begin
    y:=sqrt(r-sqr(i-r2-5));
    m:=round((r2-y)*c);
    part:=r2/y;
    alt:=0;
    for j:=1 to 2*r2+10 do
     begin
      index:=abs(round(j*part));
      if ((ecl>170) and (index>(ecl-170))) then alt:=(index-ecl+170) div 2
       else if (ecl<171) and (index<ecl) then alt:=(ecl-index) div 2
       else alt:=0;
      if alt<0 then alt:=0;
      if (index+x1)>240 then j2:=index+x1-240
       else j2:=index+x1;
      if index>2*r2+10 then goto endcheck;
      if (alt<5) and (landform^[j2,i]<water) then planet^[i,j+m]:=38-alt
       else if landform^[j2,i]<water then planet^[i,j+m]:=33
       else if alt>round(landform^[j2,i]*part2) then planet^[i,j+m]:=1
       else planet^[i,j+m]:=round(landform^[j2,i]*part2)-alt;
endcheck:
     end;
   end;
 mouse.hide;
 for j:=1 to 120 do
  for i:=1 to 120 do
   if planet^[i,j]<>0 then screen[i+y2,j+x2]:=planet^[i,j];
 mouse.show;
end;

procedure makesphere2(x1,x1b,x2,y2,r,water,ecl: integer);
var y,part2,part3,c: real;
    j2,j3,r2,alt: integer;
label endcheck;
begin
 part2:=32/(255-water);
 if r<900 then c:=1.30
  else if r>2000 then c:=1.09
  else c:=1.15;
 r2:=round(sqrt(r));
 for i:=6 to 2*r2+4 do
   begin
    y:=sqrt(r-sqr(i-r2-5));
    m:=round((r2-y)*c);
    part:=r2/y;
    alt:=0;
    for j:=1 to 2*r2+10 do
     begin
      index:=abs(round(j*part));
      if ((ecl>170) and (index>(ecl-170))) then alt:=(index-ecl+170) div 2
       else if (ecl<171) and (index<ecl) then alt:=(ecl-index) div 2
       else alt:=0;
      if alt<0 then alt:=0;
      if (index+x1)>240 then j2:=index+x1-240
       else j2:=index+x1;
      if index>2*r2+10 then goto endcheck;

      if (index+x1b)>240 then j3:=index+x1b-240
       else j3:=index+x1b;
      if landform2^[j3,i]>water then planet^[i,j+m]:=round(landform2^[j3,i]*part2)
       else if (alt<5) and (landform^[j2,i]<water) then planet^[i,j+m]:=38-alt
       else if landform^[j2,i]<water then planet^[i,j+m]:=33
       else if alt>round(landform^[j2,i]*part2) then planet^[i,j+m]:=1
       else planet^[i,j+m]:=round(landform^[j2,i]*part2)-alt;
endcheck:
     end;
   end;
 mouse.hide;
 for j:=1 to 120 do
  for i:=1 to 120 do
   if planet^[i,j]<>0 then screen[i+y2,j+x2]:=planet^[i,j];
 mouse.show;
end;

procedure test;
var ans: char;
    index,i,c,ecl,c2: integer;
begin
 index:=8; i:=0;
{  rotate(11,11,159,129);
  curtain(50,11,100,129);
  sprinkle(8,8,163,133,21);}
 for j:=236 to 255 do colors[j]:=colors[3];
 while keypressed do ans:=readkey;
 ans:='3';
{ unsprinkle(8,8,163,133,137);} {139,137,123,271,297}
 mouse.show;
 for j:=1 to 120 do
  for i:=1 to 120 do planet^[i,j]:=0;
 ecl:=16;
 repeat
  if keypressed then ans:=readkey;
  inc(index);
  inc(i);
  if i>6 then i:=0;
  if index=15 then index:=8;
  if ans=' ' then testcube;
  if ans='1' then
   begin
    for j:=0 to 3 do colors[228+j]:=colors[112+j];
    for j:=0 to 3 do colors[232+j]:=colors[48+j];
    for j:=0 to 3 do colors[224+j]:=colors[index+78+j];
   end else
  if ans='2' then
   begin
    for j:=0 to 3 do colors[228+j]:=colors[110+j+index];
    for j:=0 to 3 do colors[232+j]:=colors[48+j];
    for j:=0 to 3 do colors[224+j]:=colors[80+j];
   end else
  if ans='3' then
   begin
    for j:=0 to 3 do colors[228+j]:=colors[112+j];
    for j:=0 to 3 do colors[232+j]:=colors[46+j+index];
    for j:=0 to 3 do colors[224+j]:=colors[80+j];
   end else
   begin
    for j:=0 to 3 do colors[228+j]:=colors[112+j];
    for j:=0 to 3 do colors[232+j]:=colors[48+j];
    for j:=0 to 3 do colors[224+j]:=colors[80+j];
   end;
  set256colors(colors);
  for j:=0 to 6 do if i=j then colors[236+j]:=colors[35]
   else colors[236+j]:=colors[3];
  inc(c);
  if c>240 then c:=c-240;
  if c mod 2=0 then inc(ecl);
  if c mod 3=0 then inc(c2);
  if c2>320 then c2:=c2-320;
  if ecl>320 then ecl:=ecl-320;
  makesphere(c,25,10,3025,20,ecl);
  delay(x*10);
 until ans=#13;
end;

procedure createplanet(xc,yc: integer);
var x1,y1: integer;
    a: longint;
begin
 x1:=xc;
 y1:=yc;
 for a:=1 to 80000 do
  begin
   x1:=x1-1+random(3);
   y1:=y1-1+random(3);
   if x1>240 then x1:=1 else if x1<1 then x1:=240;
   if y1>120 then y1:=1 else if y1<1 then y1:=120;
   if landform^[x1,y1]<245 then landform^[x1,y1]:=landform^[x1,y1]+5;
  end;
end;

procedure createplanet2(xc,yc: integer);
var x1,y1: integer;
    a: longint;
begin
 x1:=xc;
 y1:=yc;
 for a:=1 to 20000 do
  begin
   x1:=x1-1+random(3);
   y1:=y1-1+random(3);
   if x1>240 then x1:=1 else if x1<1 then x1:=240;
   if y1>120 then y1:=1 else if y1<1 then y1:=120;
   if landform2^[x1,y1]<245 then landform2^[x1,y1]:=255;
  end;
end;

procedure revcreateplanet(xc,yc: integer);
var x1,y1: integer;
    a: longint;
begin
 x1:=xc;
 y1:=yc;
 for a:=1 to 240000 do
  begin
   x1:=x1-1+random(3);
   y1:=y1-1+random(3);
   if x1>240 then x1:=1 else if x1<1 then x1:=1;
   if y1>120 then y1:=1 else if y1<1 then y1:=1;
   if landform2^[x1,y1]>3 then landform2^[x1,y1]:=landform2^[x1,y1]-3;
  end;
end;

procedure planet2;
var c,x2: integer;
    temp: byte;
begin
 c:=100;
 for i:=1 to 240 do
   for j:=1 to 120 do
    begin
     c:=c-2+random(5);
     landform2^[i,j]:=c;
    end;
{ c:=1;
 for x2:=2 to 120 do
 for j:=x2 to 120 do
  begin
   temp:=landform^[1,j];
   for i:=1 to 239 do
     landform2^[i,j]:=landform2^[i+1,j];
   landform2^[240,j]:=temp;
  end;}
end;

procedure testball;
var water,c: integer;
    y,part2,part3,c2: real;
    x2,y2,j2,r2,alt,ecl,r: integer;
    label endcheck;
begin
 for j:=0 to 200 do
   begin
    stars[j,1]:=random(320);
    stars[j,2]:=random(150);
    stars[j,3]:=random(20);
   end;
 c:=128;
 for i:=1 to 240 do
   for j:=1 to 120 do
     landform^[i,j]:=2;
 createplanet(200,90);
 createplanet(30,30);
 createplanet(120,60);
 createplanet2(200,90);
 createplanet2(30,30);
 createplanet2(120,60);
 water:=20+random(20);
 printxy(11,163,'ORBIT ACHIEVED...');
 part:=22/(255-water);
 c:=50;
 ecl:=10;
 r:=3025;
 part2:=22/(255-water);
 if r<900 then c2:=1.30
  else if r>2000 then c2:=1.09
  else c2:=1.15;
 r2:=round(sqrt(r));
 x2:=25; y2:=10;
 drawstars(0,0);
end;

begin
  new(landform);
  new(landform2);
  new(planet);
  new(image);
  new(image2);
  val(paramstr(1),x,j);
  if j<>0 then x:=120;
  x:=0;
  tcolor:=31;
  randomize;
  evenpalette:=colors;
  for j:=1 to 255 do evenpalette[j]:=evenpalette[0];
  load;
  changes;
  getback;
  tcolor:=31;
  bkcolor:=3;
  printxy(11,157,'TESTING PLANET GENERATION....');
  testball;
  test;
  Closegraph;
  mouse.hide;
end.