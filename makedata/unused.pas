procedure loadshipdisplay(x,y: char);
var shipfile: file of shipdistype;
    temp: shipdistype;
    x1: integer;
begin
 assign(shipfile,'data\ship'+x+y+'.dta');
 reset(shipfile);
 if ioresult<>0 then errorhandler('data\ship'+x+y+'.dta');
 read(shipfile,temp);
 close(shipfile);
 case y of
  'A':x1:=60;
  'B':x1:=118;
  'C':x1:=176;
 end;
 for j:=0 to 57 do
  for i:=0 to 74 do
   if (temp[j,i]=0) or (temp[j,i]=38) then temp[j,i]:=4;
 for j:=x1 to x1+57 do
 begin
  for i:=37 to 112 do
   begin
    screen[10+i div 2,j div 2]:=temp[j-x1,i-37];
    inc(i);
   end;
  inc(j);
 end;
end;

procedure displayship;
var str1: string;
begin
 erasestars;
 tcolor:=47;
 j:=20;
 if ship.name[20]=' ' then
 repeat
  dec(j);
 until ship.name[j]<>' ';
 str1:=ship.name;
 str1[0]:=chr(j);
 printxy(73-j*3,10,'"'+str1+'"');
 setcolor(43);
 setfillstyle(1,4);
 bar(20,20,135,73);
 setlinestyle(0,0,3);
 rectangle(20,20,135,73);
 setcolor(47);
 setlinestyle(0,0,0);
 rectangle(20,20,135,73);
 case ship.shiptype[1] of
  'A':loadshipdisplay('1','A');
  'B':loadshipdisplay('2','A');
  'C':loadshipdisplay('3','A');
 end;
 case ship.shiptype[2] of
  '1':loadshipdisplay('1','B');
  '2':loadshipdisplay('2','B');
  '3':loadshipdisplay('3','B');
 end;
 case ship.shiptype[3] of
  'X':loadshipdisplay('1','C');
  'Y':loadshipdisplay('2','C');
  'Z':loadshipdisplay('3','C');
 end;
 bkcolor:=4;
 printxy(10,80,'CREW:');
 for j:=1 to 7 do
  begin
   case j of
    1: str1:='CPT';
    2: str1:='PSY';
    3: str1:='ENG';
    4: str1:='SCI';
    5: str1:='SEC';
    6: str1:='NAV';
    7: str1:='MED';
   end;
   tcolor:=14;
   printxy(24,81+j*7,str1);
   tcolor:=31;
   printxy(45,81+j*7,crew[j].name);
   case crew[j].status of
    0:bkcolor:=63;
   end;
   printxy(15,81+j*7,' ');
   bkcolor:=4;
  end;
 drawstars(0,0);
 bkcolor:=0;
end;

procedure rotatecube(src,tar: byte);
label skip1,skip2,skip3;
begin  {215,145}
 if tar+src=5 then
  begin
   if (tar=2) or (tar=3) then rotatecube(src,tar-2)
   else if (tar>0) then rotatecube(src,tar-1)
   else rotatecube(src,tar+1);
  end;
 getcube(src,tar);
 setfillstyle(0,0);
 mouse.hide;
 getback;
 vocstop;
 vocoutput(cubesound);
 for t:=1 to 31 do
  begin
  for i:=215 to 231 do
   begin
    q:=round(sin(t/20)*45);
    m:=round(51*(sqrt(2)-1)*0.5*sin(t/10));
    part:=45/q;
    for j:=133 to 145-m do screen[j,i]:=back1[i-215,j-133];
    for j:=0 to q-1 do
     begin
      index:=round(j*part);
      if index<46 then screen[j+145-m,i]:=cubetar^[index,i-215];
     end;
    if (45+2*m-q)=0 then goto skip1;
    part:=45/(45+2*m-q);
    for j:=145-m+q to 188+m do
     begin
      index:=round((j-145+m-q)*part);
      if index<46 then screen[j,i]:=cubesrc^[index,i-215];
     end;
skip1:
    for j:=190+m to 199 do screen[j,i]:=back2[i-215,j-190];
   end;
  for i:=232 to 249 do
   begin
    for j:=133 to 145-m do screen[j,i]:=back1[i-215,j-133];
    q:=round(sin((31-t)/20)*45);
    if q=0 then goto skip2;
    part:=45/q;
    for j:=0 to q-1 do
     begin
      index:=round(j*part);
      if index<46 then screen[j+145-m,i]:=cubesrc^[index,i-215];
     end;
    if (45+2*m-q)=0 then goto skip2;
    part:=45/(45+2*m-q);
    for j:=145-m+q to 188+m do
     begin
      index:=round((j-145+m-q)* part);
      if index<46 then screen[j,i]:=cubetar^[index,i-215];
     end;
skip2:
    for j:=190+m to 199 do screen[j,i]:=back2[i-215,j-190];
   end;
  for i:=250 to 265 do
   begin
    q:=round(sin(t/20)*45);
    part:=45/q;
    for j:=133 to 145-m do screen[j,i]:=back1[i-215,j-133];
    for j:=0 to q-1 do
     begin
      index:=round(j*part);
      if index<46 then screen[j+145-m,i]:=cubetar^[index,i-215];
     end;
    if (45+2*m-q)=0 then goto skip3;
    part:=45/(45+2*m-q);
    for j:=145-m+q to 188+m do
     begin
      index:=round((j-145+m-q)* part);
      if index<46 then screen[j,i]:=cubesrc^[index,i-215];
     end;
skip3:
    for j:=190+m to 199 do screen[j,i]:=back2[i-215,j-190];
   end;
  end;
 for j:=0 to 50 do
  for i:=0 to 44 do
   screen[i+145,j+215]:=cubetar^[i,j];
 mouse.show;
 cube:=tar;
end;

procedure fading(n: integer);
var a: integer;
begin
 temppal:=colors;
 for a:=0 to n do
  begin
   for j:=0 to 255 do
    for i:=0 to 2 do
      temppal[j,i]:=temppal[j,i] - (temppal[j,i] div 4);
   set256colors(temppal);
   if a<n then delay(tslice*3);
  end;
  for j:=0 to 255 do for i:=0 to 2 do temppal[j,i]:=0;
  set256colors(temppal);
  delay(tslice*5);
end;

procedure fadein(n: integer);
var a: integer;
begin
 for j:=0 to 255 do for i:=0 to 2 do temppal[j,i]:=0;
 for a:=0 to n do
  begin
   for j:=0 to 255 do
    for i:=0 to 2 do
     temppal[j,i]:=temppal[j,i] + ((colors[j,i]-temppal[j,i]) div 4);
   set256colors(temppal);
   delay(tslice*3);
  end;
 set256colors(colors);
 delay(tslice*5);
end;

procedure erasestars;
begin
 for j:=0 to 100 do
  if stars[j,4]=0 then screen[stars[j,2],stars[j,1]]:=2;
end;

procedure drawstars(x1,y1: integer);
var x,y: integer;
begin
 for j:=0 to 100 do
  begin
   x:=stars[j,1]+x1;
   y:=stars[j,2]+y1;
   if y>140 then y:=y-140
    else if y<0 then y:=y+140;
   if x>300 then x:=x-300
    else if x<0 then x:=x+310;
   stars[j,1]:=x;
   stars[j,2]:=y;
   if screen[y,x]=2 then stars[j,4]:=0
    else stars[j,4]:=1;
   if stars[j,4]=0 then screen[y,x]:=stars[j,3];
  end;
end;

procedure fading2;
var a: integer;
begin
 temppal:=colors;
 for a:=25 downto 1 do
  begin
   for j:=0 to 255 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*temppal[j,i]/25);
   set256colors(temppal);
   delay(tslice*2);
  end;
 for j:=0 to 255 do for i:=1 to 3 do temppal[j,i]:=0;
 set256colors(temppal);
 delay(tslice);
end;

procedure fadein2;
var a: integer;
begin
 for j:=0 to 255 do for i:=1 to 3 do temppal[j,i]:=0;
 for a:=1 to 25 do
  begin
   for j:=0 to 255 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/25);
   set256colors(temppal);
   delay(tslice*2);
  end;
 set256colors(colors);
 delay(tslice);
end;

 asm
  push ds
  push es
  mov ax, seg screen
  mov es, ax
  mov di, offset screen
  mov [tar1], es
  mov [tar2], di

  mov ax, [tempseg]
  mov ds, ax
  mov si, [tempofs]
  mov [src1], es
  mov [src2], si

  mov [a], 199
  mov bl, 160
 @@loopa:
  mov ax, [a]
  mov [i], ax
 @@loopi:
  mov ax, [i]
  mul bl
  shl ax, 1
  mov di, [tar2]
  add di, ax
  mov ax, [i]
  sub ax, [a]
  mul bl
  shl ax, 1
  mov si, [src2]
  add si, ax
  mov cx, 160
  repe movsw
  inc [i]
  cmp [i], 200
  jl @@loopi
  dec [a]
  cmp [a], 0
  jg @@loopa
  pop es
  pop ds
 end;

procedure staticin(s: string);
var temp: ^screentype;
    vgafile: file of screentype;
    seed,total: word;
begin
 new(temp);
 assign(vgafile,s);
 reset(vgafile);
 if ioresult<>0 then errorhandler(s);
 read(vgafile,temp^);
 close(vgafile);
 seed:=16;
 total:=800;
 repeat
  dec(total);
  for i:=192 to 223 do
   colors[i]:=colors[223+random(32)];
  set256colors(colors);
  if total mod 15=0 then
   begin
    dec(seed);
    for j:=0 to 319 do
     for i:=0 to 199 do
      if (temp^[i,j] mod 16=seed)
       and (temp^[i,j]>0)
       then screen[i,j]:=temp^[i,j];
   end;
 until seed=0;
 total:=50;
 repeat
  dec(total);
    for i:=192 to 223 do
     colors[i]:=colors[223+random(32)];
    set256colors(colors);
  delay(tslice*3);
 until total=0;
 total:=800;
 seed:=16;
 repeat
  dec(total);
  for i:=192 to 223 do
   colors[i]:=colors[223+random(32)];
  set256colors(colors);
  if total mod 15=0 then
   begin
    dec(seed);
    for j:=0 to 319 do
     for i:=0 to 199 do
      if (temp^[i,j] mod 16=seed)
       then screen[i,j]:=random(32)+192;
   end;
 until seed=0;
 dispose(temp);
end;

procedure glass(x1,y1,x2: integer);
var i,j: integer;
begin
 for j:=x1-6 to x2 do
  for i:=y1 to y1+10 do screen[i,j]:=0;
 setfillstyle(1,7);
 setcolor(5);
 pieslice(x1,y1+5,90,270,6);
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


 for a:=0 to 319 do
  begin
   for b:=0 to 149 do
    begin
     x:=a+backgrx;
     if x>319 then x:=x-319;
     y:=b+backgry;
     if y>199 then y:=y-199;
     if temp^[b,a]=255 then screen[b,a]:=backgr^[y,x];
    end;
   if voc.statusword=0 then
    begin
     inc(speed^,20);
     voc.output(vocptr);
    end;
  end;
 setwritemode(xorput);
 while t<471 do
  begin
   inc(t,2);
   if t>471 then t:=471;
   delay(tslice);
   if t>470 then delay(tslice*15);
   if voc.statusword=0 then
    begin
     inc(speed^,20);
     voc.output(vocptr);
    end;
  end;
 for a:=40 downto 1 do
  begin
   setcolor(95);
   if a>20 then
    begin
     moveto(160+round((a-20)*cos(t/100)),70+round((a-20)*sin(t/100)));
     lineto(160+round((a-20)*cos(t/100+2.09)),70+round((a-20)*sin(t/100+2.09)));
     lineto(160+round((a-20)*cos(t/100+4.18)),70+round((a-20)*sin(t/100+4.18)));
     lineto(160+round((a-20)*cos(t/100)),70+round((a-20)*sin(t/100)));
    end;
   moveto(160+round(a*cos(-t/100)),70+round(40*sin(-t/100)));
   lineto(160+round(a*cos(-t/100+2.09)),70+round(40*sin(-t/100+2.09)));
   lineto(160+round(a*cos(-t/100+4.18)),70+round(40*sin(-t/100+4.18)));
   lineto(160+round(a*cos(-t/100)),70+round(40*sin(-t/100)));
   setcolor(0);
   if a>20 then
    begin
     moveto(160+round((a-20)*cos(t/100)),70+round((a-20)*sin(t/100)));
     lineto(160+round((a-20)*cos(t/100+2.09)),70+round((a-20)*sin(t/100+2.09)));
     lineto(160+round((a-20)*cos(t/100+4.18)),70+round((a-20)*sin(t/100+4.18)));
     lineto(160+round((a-20)*cos(t/100)),70+round((a-20)*sin(t/100)));
    end;
   moveto(160+round(a*cos(-t/100)),70+round(40*sin(-t/100)));
   lineto(160+round(a*cos(-t/100+2.09)),70+round(40*sin(-t/100+2.09)));
   lineto(160+round(a*cos(-t/100+4.18)),70+round(40*sin(-t/100+4.18)));
   lineto(160+round(a*cos(-t/100)),70+round(40*sin(-t/100)));
  end;
 setwritemode(0);
 for a:=0 to 70 do
  begin
   for i:=69 downto 1 do
    if i>0 then move(backgr^[i-1],backgr^[i],320);
   fillchar(backgr^[0],320,0);
   for i:=71 to 140 do
    if i<140 then move(backgr^[i+1],backgr^[i],320);
   fillchar(backgr^[140],320,0);
   for j:=0 to 319 do
    begin
     for i:=0 to 69 do
      if temp^[i,j]=255 then screen[i,j]:=backgr^[i,j];
     for i:=71 to 140 do
      if temp^[i,j]=255 then screen[i,j]:=backgr^[i,j];
    end;
   setcolor(round(a*0.376));
   line(40,70,280,70);
   setcolor(round(a*0.188));
   line(80,69,240,69);
   line(80,71,240,71);
   setcolor(round(a*0.094));
   line(120,68,200,68);
   line(120,72,200,72);
   if voc.statusword=0 then
    begin
     if speed^<180 then inc(speed^,17);
     voc.output(vocptr);
    end;
  end;


procedure loadshipdisplay(x,y: char);
var shipfile: file of shipdistype;
    temp: ^shipdistype;
    x1: integer;
begin
 new(temp);
 assign(shipfile,'data\ship'+x+y+'.dta');
 reset(shipfile);
 if ioresult<>0 then errorhandler('data\ship'+x+y+'.dta',1);
 read(shipfile,temp^);
 close(shipfile);
 case y of
  'A':x1:=60;
  'B':x1:=118;
  'C':x1:=176;
 end;
 for j:=0 to 57 do
  for i:=0 to 74 do
   if (temp^[j,i]=0) or (temp^[j,i]=38) then temp^[j,i]:=4;
 for j:=x1 to x1+57 do
 begin
  for i:=0 to 74 do
   begin
    if temp^[j-x1,i]<>4 then screen[61+i div 4,186+j div 4]:=temp^[j-x1,i];
    i:=i+2;
    if i>74 then i:=74
   end;
  j:=j+3;
  if j>x1+57 then j:=x1+57;
 end;
 dispose(temp);
end;

procedure displayship;
var str1: string;
begin
 case ship.shiptype[1] of
  'A':loadshipdisplay('1','A');
  'B':loadshipdisplay('2','A');
  'C':loadshipdisplay('3','A');
 end;
 case ship.shiptype[2] of
  '1':loadshipdisplay('1','B');
  '2':loadshipdisplay('2','B');
  '3':loadshipdisplay('3','B');
 end;
 case ship.shiptype[3] of
  'X':loadshipdisplay('1','C');
  'Y':loadshipdisplay('2','C');
  'Z':loadshipdisplay('3','C');
 end;
end;

procedure displayshortscan;
begin
 setwritemode(xorput);
 setcolor(120);
 mouse.hide;
 rectangle(198-scanindex,58-scanindex,246+scanindex,82+scanindex);
 inc(scanindex);
 if scanindex<31 then inc(scanindex) else scanindex:=0;
 if scanindex=0 then playvoice(19);
 rectangle(198-scanindex,58-scanindex,246+scanindex,82+scanindex);
 rectangle(198-scanindex2,58-scanindex2,246+scanindex2,82+scanindex2);
 inc(scanindex2);
 if scanindex2<31 then inc(scanindex2) else scanindex2:=0;
 if scanindex2=0 then playvoice(19);
 rectangle(198-scanindex2,58-scanindex2,246+scanindex2,82+scanindex2);
 mouse.show;
 setwritemode(copyput);
end;

procedure readyshortscan;
 viewmode:=2;
 tcolor:=63;
 println;
 print('INITIALIZING SHORT RANGE SCAN');
 bkcolor:=0;
 mouse.hide;
 setcolor(44);
 setlinestyle(0,0,3);
 rectangle(165,25,279,115);
 setcolor(47);
 setlinestyle(0,0,0);
 rectangle(165,25,279,115);
 rotatemapin(167,27,277,113);
 for j:=1 to 13 do
  for i:=27 to 113 do
   screen[i,166+j*8]:=33;
 for i:=1 to 10 do
  fillchar(screen[26+i*8,167],110,33);
 displayship;
 setwritemode(xorput);
 setcolor(120);
 rectangle(198-scanindex,58-scanindex,246+scanindex,82+scanindex);
 rectangle(198-scanindex2,58-scanindex2,246+scanindex2,82+scanindex2);
 playvoice(19);
 displayshortscan;
 mouse.show;
 anychange:=true;
end;

procedure makeastoroid;
label endcheck;
begin
 for i:=6 to 2*r2+4 do
   begin
    y:=sqrt(radius-sqr(i-r2-5));
    m:=round((r2-y)*c2);
    part:=r2/y;
    alt:=0;
    ofsy:=i+offset;
    for j:=1 to 2*r2+10 do
     begin
      index:=round(j*part);
      if index>2*r2+10 then goto endcheck;
      ofsx:=j+m+offset;
      if (ecl>170) then alt:=(index-ecl+186) div 2
       else if (ecl<171) and (index<ecl) then alt:=(ecl-index) div 2
       else alt:=0;
      if alt<0 then alt:=0;
      if (index+c)>240 then j2:=index+c-240
       else j2:=index+c;
      if alt>round(landform^[j2,i]*part2) then planet^[ofsy,ofsx]:=0
       else planet^[ofsy,ofsx]:=round(landform^[j2,i]*part2)-alt+1;
endcheck:
     end;
   end;
 mouse.hide;
 for i:=1 to 120 do
  mymove(planet^[i],screen[i+12,28],30);
 mouse.show;
end;

procedure makeastoroid;
label endcheck;
begin
 for i:=6 to 2*r2+4 do
   begin
    y:=sqrt(radius-sqr(i-r2-5));
    m:=round((r2-y)*c2);
    part:=r2/y;
    alt:=0;
    ofsy:=i+offset;
    for j:=1 to 2*r2+10 do
     begin
      index:=round(j*part);
      if index>2*r2+10 then goto endcheck;
      ofsx:=j+m+offset;
      if (ecl>170) then alt:=(index-ecl+186) div 2
       else if (ecl<171) and (index<ecl) then alt:=(ecl-index) div 2
       else alt:=0;
      if alt<0 then alt:=0;
      if (index+c)>240 then j2:=index+c-240
       else j2:=index+c;
      if alt>round(landform^[j2,i]*part2) then planet^[ofsy,ofsx]:=0
       else planet^[ofsy,ofsx]:=round(landform^[j2,i]*part2)-alt+1;
endcheck:
     end;
   end;
 mouse.hide;
 for i:=1 to 120 do
  mymove(planet^[i],screen[i+12,28],30);
 mouse.show;
end;

procedure lowerball;
var anifile: file of aniarraytype;
begin
 new(ani);
 assign(anifile,'data\charani.dta');
 reset(anifile);
 if ioresult<>0 then errorhandler('charani.dta',1);
 read(anifile,ani^);
 if ioresult<>0 then errorhandler('charani.dta',5);
 close(anifile);
 for j:=0 to 30 do
  begin
   for i:=0 to 34 do
    mymove(ani^[j,i],screen[i+81,22],12);
   delay(tslice div 2);
  end;
 dispose(ani);
end;

procedure raiseball;
var anifile: file of aniarraytype;
begin
 new(ani);
 assign(anifile,'data\charani.dta');
 reset(anifile);
 if ioresult<>0 then errorhandler('charani.dta',1);
 read(anifile,ani^);
 if ioresult<>0 then errorhandler('charani.dta',5);
 close(anifile);
 for j:=30 downto 0 do
  begin
   for i:=0 to 34 do
    mymove(ani^[j,i],screen[i+81,22],12);
   delay(tslice div 2);
  end;
 dispose(ani);
end;

procedure rotatemapin(x1,y1,x2,y2: integer);
var n: integer;
begin
 if ship.options[6]=0 then
  begin
   mousehide;
   j:=x2-x1+1;
   for i:=y1 to y2 do
    fillchar(screen[i,x1],j,4);
   mouseshow;
   exit;
  end;
 n:=(x2-x1) div 2;
 for a:=(x2-x1) downto 1 do
  begin
   for i:=y1 to y2 do
    begin
     index:=n+1;
     for j:=n+x1 downto x1 do
      if j mod a=0 then
       begin
        dec(index);
        screen[i,index+x1]:=4;
       end;
     for j:=index+x1 downto x1 do screen[i,j]:=0;
     index:=n-1;
     for j:=n+x1 to x2 do
      if j mod a=0 then
       begin
        inc(index);
        screen[i,index+x1]:=4;
       end;
     for j:=index+x1 to x2 do screen[i,j]:=0;
    end;
   a:=round(a*0.8);
   if a=0 then exit;
   delay(tslice);
  end;
 j:=x2-x1+1;
 for i:=y1 to y2 do
  fillchar(screen[i,x1],j,4);
end;

procedure rotatemapout(x1,y1,x2,y2: integer);
var n: integer;
begin
 if ship.options[6]=0 then
  begin
   mousehide;
   j:=x2-x1+1;
   for i:=y1 to y2 do
    fillchar(screen[i,x1],j,0);
   mouseshow;
   exit;
  end;
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
        screen[i,index+x1]:=starmapscreen^[i,j];
       end;
     for j:=index+x1 downto x1 do screen[i,j]:=0;
     index:=n-1;
     for j:=n+x1 to x2 do
      if j mod a=0 then
       begin
        inc(index);
        screen[i,index+x1]:=starmapscreen^[i,j];
       end;
     for j:=index+x1 to x2 do screen[i,j]:=0;
    end;
   if a>25 then exit;
   a:=round(a*1.2);
   delay(tslice);
  end;
end;

procedure rotatescanout(x1,y1,x2,y2: integer);
var n: integer;
begin
 if ship.options[6]=0 then
  begin
   mousehide;
   j:=x2-x1+1;
    for i:=y1 to y2 do
     fillchar(screen[i,x1],j,4);
   mouseshow;
   exit;
  end;
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
        screen[i,index+x1]:=template2^[i,j];
       end;
     for j:=index+x1 downto x1 do screen[i,j]:=0;
     index:=n-1;
     for j:=n+x1 to x2 do
      if j mod a=0 then
       begin
        inc(index);
        screen[i,index+x1]:=template2^[i,j];
       end;
     for j:=index+x1 to x2 do screen[i,j]:=0;
    end;
   if a>25 then exit;
   a:=round(a*1.2);
   delay(tslice);
  end;
 j:=x2-x1+1;
 for i:=y1 to y2 do
  fillchar(screen[i,x1],j,4);
end;

procedure setflag(flag: byte);
begin
 biostsbyte:=biostsbyte or flag;
 asm
  mov ah, 1
   int 16h
 end;
end;

procedure clrflag(flag : byte);
begin
 biostsbyte:=biostsbyte and (not flag);
 asm
  mov ah, 1
   int 16h
 end;
end;

procedure zoomplanet2;
var indexi,indexj,a: integer;
    c2: real;
begin
 mousehide;
 for a:=80 downto 1 do
  begin
   if a>10 then
    begin
     c2:=sin(a/120*1.57);
     scrollback(round(c2*-4),0);
     dec(a);
    end
   else if a>5 then
    begin
     c2:=cos(a/10*1.57);
     scrollback(round(c2*2),round(c2*2));
    end;
   indexi:=0;
   i:=12;
   repeat
    inc(indexi,a);
    inc(i);
    indexj:=0;
    j:=26;
    repeat
     inc(indexj,a);
     inc(j);
     if (indexi<121) and (indexj<121) then screen[i,j+a]:=planet^[indexi,indexj];
    until (indexj>119);
   until (indexi>119);
   if a>10 then delay(tslice div 2)
    else delay(round(c2*tslice*7));
  end;
 mouseshow;
end;

procedure zoomplanet;
var indexi,indexj,a: integer;
    c2: real;
begin
 mousehide;
 for a:=80 downto 1 do
  begin
   if a>10 then
    begin
     c2:=sin(a/120*1.57);
     scrollback(round(c2*-4),round(c2*-4));
     dec(a);
    end
   else if a>5 then
    begin
     c2:=cos(a/10*1.57);
     scrollback(round(c2*2),round(c2*2));
    end;
   indexi:=0;
   i:=11;
   repeat
    inc(indexi,a);
    inc(i);
    indexj:=0;
    j:=26;
    repeat
     inc(indexj,a);
     inc(j);
     if (indexi<121) and (indexj<121) then screen[i+a,j+a]:=planet^[indexi,indexj];
    until (indexj>119);
   until (indexi>119);
   if a>10 then delay(tslice div 2)
    else delay(round(c2*tslice*7));
  end;
 mouseshow;
end;

procedure removeplanet;
var indexi,indexj,a,a2: integer;
    c2: real;
begin
 if not showplanet then exit;
 mousehide;
 for a:=1 to 80 do
  begin
   addtime;
   showtime;
   indexi:=0;
   i:=72-round(60/a);
   repeat
    inc(indexi,a);
    inc(i);
    indexj:=0;
    j:=87-round(60/a);
    repeat
     inc(indexj,a);
     inc(j);
     if (indexi<121) and (indexj<121) then screen[i,j]:=planet^[indexi,indexj];
    until (indexj>119);
   until (indexi>119);
   for i:=13 to 72-round(60/a) do
    begin
     a2:=backgry+i;
     if a2>199 then a2:=a2-200;
     for j:=27 to 146 do
      begin
       b:=backgrx+j;
       if b>319 then b:=b-320;
       screen[i,j]:=backgr^[a2,b];
      end;
    end;
   for i:=72+round(60/a) to 131 do
    begin
     a2:=backgry+i;
     if a2>199 then a2:=a2-200;
     for j:=27 to 146 do
      begin
       b:=backgrx+j;
       if b>319 then b:=b-320;
       screen[i,j]:=backgr^[a2,b];
      end;
    end;
   for i:=73-round(60/a) to 71+round(60/a) do
    begin
     a2:=backgry+i;
     if a2>199 then a2:=a2-200;
     for j:=26 to 87-round(60/a) do
      begin
       b:=backgrx+j;
       if b>319 then b:=b-320;
       screen[i,j]:=backgr^[a2,b];
      end;
     for j:=87+round(60/a) to 147 do
      begin
       b:=backgrx+j;
       if b>319 then b:=b-320;
       screen[i,j]:=backgr^[a2,b];
      end;
    end;
   delay(tslice div 2)
  end;
 mouseshow;
end;

procedure engage2(x1,y1: integer);
var vgafile: file of screentype;
    temp: ^screentype;
    c2: real;
begin
 new(temp);
 assign(vgafile,'data\main2.vga');
 reset(vgafile);
 if ioresult<>0 then errorhandler('main2.vga',1);
 read(vgafile,temp^);
 if ioresult<>0 then errorhandler('main2.vga',5);
 close(vgafile);
 setcolor(95);
 i:=0;
 t:=0;
 if y1>0 then
  repeat
   inc(t,2);
   for a:=0 to 319 do
    for b:=0 to 149 do
     begin
      x:=a+backgrx;
      if x>319 then x:=x-320;
      y:=b+backgry;
      if y>199 then y:=y-200;
      if temp^[b,a]=255 then screen[b,a]:=backgr^[y,x];
     end;
   if y1>0 then inc(backgry,round(4*sin(i/y1*3.14)))
    else dec(backgry,round(4*sin(i/y1*3.14)));
   if backgry>199 then backgry:=backgry-200
    else if backgry<0 then backgry:=backgry+200;
   if y1>0 then inc(i) else dec(i);
   inc(t,2);
  until i=y1;
 j:=0;
 if x1>0 then
  repeat
   inc(t,2);
   for a:=0 to 319 do
    for b:=0 to 149 do
     begin
      x:=a+backgrx;
      if x>319 then x:=x-320;
      y:=b+backgry;
      if y>199 then y:=y-200;
      if temp^[b,a]=255 then screen[b,a]:=backgr^[y,x];
     end;
   if x1>0 then inc(backgrx,round(4*sin(j/x1*3.14)))
    else dec(backgrx,round(4*sin(j/x1*3.14)));
   if backgrx>319 then backgrx:=backgrx-320
    else if backgrx<0 then backgrx:=backgrx+320;
   if x1>0 then inc(j) else dec(j);
   inc(t,2);
  until j=x1;
 t:=1;
 for j:=0 to 319 do
  begin
   x1:=backgrx+j;
   if x1>319 then x1:=x1-320;
   for i:=0 to 199 do
    begin
     y1:=backgry+i;
     if y1>199 then y1:=y1-200;
     temp^[y1,x1]:=backgr^[i,j];
    end;
  end;
 mymove(temp^,backgr^,16000);
 backgrx:=0;
 backgry:=0;
 dispose(temp);
 for a:=1 to 55 do
  begin
   addlotstime(17);
   showtime;
   for j:=1 to 319 do
    begin
     for i:=1 to 199 do
      if (backgr^[i,j]<>0) and (backgr^[i,j]<32) then
       begin
        x:=j+round((160-j)/200*a);
        y:=i+round((70-i)/200*a);
        backgr^[y,x]:=backgr^[i,j]+34;
        if (y<>i) or (j<>x) then backgr^[i,j]:=0;
       end;
    end;
   for j:=0 to 319 do
    for i:=0 to 199 do
     if backgr^[i,j]>31 then dec(backgr^[i,j],32);
   scrollback(0,0);
   delay(tslice div 6);
  end;
end;


procedure scrollback(x1,y1: integer);
var temp: ^screentype;
    vgafile: file of screentype;
begin
 new(temp);
 assign(vgafile,'data\main2.vga');
 reset(vgafile);
 if ioresult<>0 then errorhandler('main2.vga',1);
 read(vgafile,temp^);
 close(vgafile);
 backgry:=backgry+y1;
 backgrx:=backgrx+x1;
 if backgrx>319 then backgrx:=backgrx-320
  else if backgrx<0 then backgrx:=backgrx+320;
 if backgry>199 then backgry:=backgry-200
  else if backgry<0 then backgry:=backgry+200;
 for a:=0 to 319 do
  for b:=0 to 149 do
   begin
    j:=a+backgrx;
    if j>319 then j:=j-320;
    i:=b+backgry;
    if i>199 then i:=i-200;
    if temp^[b,a]=255 then screen[b,a]:=backgr^[i,j];
   end;
 dispose(temp);
end;

procedure focus;
var temp: ^screentype;
    a: integer;
    vgafile: file of screentype;
begin
 new(temp);
 mymove2(screen,temp^,16000);
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


{ for i:=23 to 56 do
  fillchar(screen[i,194],118,0);
 tcolor:=47;
 printxy(194,23,'SCANNING EM BANDS');
 for a:=1 to 2000 do
  begin
   t1:=t1+0.01;
   if t1=6.28 then t1:=0;
   for b:=0 to 34 do
    begin
     j:=abs(round(20*(sin(b*0.09+t1))));
     x:=20;
     for i:=0 to j do
      begin
       screen[55-j,b*3+199]:=x;
       screen[55-j,b*3+200]:=x;
      end;
     screen[54-j,b*3+199]:=0;
     screen[54-j,b*3+200]:=0;
    end;
  end;
 sprinkle(194,30,311,56,17);
 printxy(194,23,'AQUIRING TRANSMISSION');
 printxy(194,23,'ANALYZING DATA STREAM');
 y:=0;
 x:=0;
 for a:=1 to 5000 do
  begin
   printxy(x*5+194,y*6+31,chr(48+random(2)));
   inc(x);
   if x>20 then
    begin
     x:=0;
     inc(y);
     if y>3 then y:=0;
    end;
   delay(tslice div 10);
  end;
 sprinkle(194,30,311,56,17);
 printxy(194,23,'INITIALIZE CYPHER KEY');
 t:=ptr(random(1000),0);
 for a:=1 to 2000 do
  begin
   inc(t);
   printxy(x*5+194,y*6+31,t^);
   inc(x);
   if x>20 then
    begin
     x:=0;
     inc(y);
     if y>3 then y:=0;
    end;
   delay(tslice div 10);
  end;
 sprinkle(194,30,311,56,17);
 printxy(194,23,'MATRIX ESTABLISHED   ');
 for i:=29 to 55 do
  fillchar(screen[i,194],118,0);
 printxy(194,29,'TRANSFERING CYPHER');
}



{----------------------------------------------------------------------------}
procedure displaysanity;
begin
 j:=ship.crew[crewindex].san;
 if j>100 then j:=100 else if j<1 then j:=1;
 t1:=22/(j*0.64);
 for i:=88 downto 88-round(j*0.64) do
  fillchar(screen[i,303],10,round((88-i)*t1)+73);
 if j<100 then
  for i:=24 to 88-round(j*0.65) do
   fillchar(screen[i,303],10,0);
end;

procedure redraw2;
var a: integer;
    s: string[20];
begin {120,37,294,112}
 mousehide;
 displaycursor;
 drawstats(crewindex);
 showportrait(ship.crew[crewindex].index);
 s:=ship.crew[crewindex].name;
 i:=20;
 while (i>1) and (s[i]=' ') do dec(i);
 s[0]:=chr(i);
 for i:=103 to 108 do
  fillchar(screen[i,121],119,0);
 x:=ship.crew[crewindex].emo;
 y:=ship.crew[crewindex].phy;
 z:=ship.crew[crewindex].men;
 printxy(123+(120-length(s)*6) div 2,103,s);
 str(ship.crew[crewindex].xp:10,s);
 for i:=1 to 7 do if s[i]=' ' then s[i]:='0';
 printxy(198,120,s);
 str(ship.crew[crewindex].level:2,s);
 printxy(154,120,s);
 displaylevel(ship.crew[crewindex].level);
 displaysanity;
 case ship.crew[crewindex].men of
    0..5: s:='         Braindead';
   6..19: s:='           Foolish';
  20..39: s:='     Below Average';
  40..59: s:='           Average';
  60..79: s:='Highly Intelligent';
  80..98: s:='            Genius';
      99: s:='       Supragenius';
  else errorhandler('crew bug 1',6);
 end;
 printxy(140,137,s);
 case ship.crew[crewindex].phy of
    0..5: s:='   Skeletal';
   6..19: s:=' Ill Health';
  20..39: s:='Poor Health';
  40..59: s:='    Average';
  60..79: s:='  Atheletic';
  80..98: s:='   Powerful';
      99: s:='  Herculean';
  else errorhandler('crew bug 2',6);
 end;
 printxy(175,144,s);
 case ship.crew[crewindex].emo of
    0..5: s:='  Psychotic';
   6..19: s:='   Neurotic';
  20..39: s:='   Unstable';
  40..59: s:='    Average';
  60..79: s:='       Calm';
  80..98: s:='    Logical';
      99: s:='Calculating';
  else errorhandler('crew bug 3',6);
 end;
 printxy(175,151,s);
 i:=round((y+x*y/100)/100) mod 100;
 if i<0 then i:=0;
 case i of
   0..24: s:=' Introverted';
  25..49: s:='    Reserved';
  50..74: s:='    Friendly';
  75..99: s:='Affectionate';
  else errorhandler('crew bug 4',6);
 end;
 printxy(170,158,s);
 if y=0 then i:=z else i:=round(z-x/y) mod 100;
 if i<0 then i:=0;
 case i of
   0..24: s:='Unscrupulous';
  25..49: s:='  Suspicious';
  50..74: s:='   Concerned';
  75..99: s:=' Sympathetic';
  else errorhandler('crew bug 5',6);
 end;
 printxy(170,165,s);
 i:=abs(round(x-z/4+y/4)) mod 100;
 if i<0 then i:=0;
 case i of
    0..24: s:='     Ruthless';
   25..49: s:='Uncooperative';
   50..74: s:='     Trusting';
   75..99: s:='  Softhearted';
   else errorhandler('crew bug 7',6);
 end;
 printxy(165,172,s);
 if x=0 then i:=z else i:=round(z-y/x) mod 100;
 if i<0 then i:=0;
 case i of
   0..24: s:=' Conforming';
  25..49: s:='  Practical';
  50..74: s:='Independent';
  75..99: s:='Imaginative';
  else errorhandler('crew bug 8',6);
 end;
 printxy(175,179,s);
 i:=abs(2*z-y-x) mod 100;
 if i<0 then i:=0;
 case i of
   0..24: s:='  Slothful';
  25..49: s:='  Carefree';
  50..74: s:='Restrained';
  75..99: s:='Compulsive';
  else errorhandler('crew bug 9',6);
 end;
 printxy(180,186,s);
 mouseshow;
end;

procedure findmouse2;
var before: integer;
begin
 if not mouse.getstatus(left) then exit;
 before:=crewindex;
 case mouse.x of
  280..297: case mouse.y of
             146..160: if crewindex=1 then crewindex:=6 else dec(crewindex);
             162..176: if crewindex=6 then crewindex:=1 else inc(crewindex);
            end;
  302..311: if (mouse.y>154) and (mouse.y<170) then done:=true;
 end;
 if before<>crewindex then redraw2;
 idletime:=0;
end;

procedure processkey2;
var ans: char;
    before: integer;
begin
 ans:=readkey;
 before:=crewindex;
 case ans of
  #27: done:=true;
  #0: begin
       ans:=readkey;
       case ans of
        #72: if crewindex=1 then crewindex:=6 else dec(crewindex);
        #80: if crewindex=6 then crewindex:=1 else inc(crewindex);
       end;
      end;
  '`': bossmode;
 end;
 if before<>crewindex then redraw2;
 idletime:=0;
end;

procedure mainloop2;
begin
 repeat
  findmouse2;
  if fastkeypressed then processkey2;
  inc(idletime);
  if idletime=maxidle then screensaver;
  adjustgraph;
  adjustlights;
  if mouseindex<6 then inc(mouseindex) else mouseindex:=0;
  mousehide;
  mousesetcursor(mcursor^[mouseindex]);
  mouseshow;
  if msgindex<32 then inc(msgindex) else msgindex:=0;
  if msgindex=0 then displaymsg
  else displaylittlemsgs;
  delay(tslice*5);
 until done;
end;

procedure readypsychicdata;
begin
 mousehide;
 compressfile(tempdir+'\current.vga',@screen);
 fading;
 playmod(true,'sound\creweval.mod');
 loadscreen('data\char3.vga',@screen);
 new(mcursor);
 new(holo);
 new(msgs);
 new(littlemsgs);
 for a:=0 to 6 do
  for i:=0 to 15 do
   mymove(screen[i+180,10+a*17],mcursor^[a,i],4);
 for i:=35 to 63 do
  mymove(screen[i,84],holo^[i,84],9);
 for a:=0 to 8 do
  for i:=0 to 8 do
   mymove(screen[(a div 3)*10+145+i,(a mod 3)*40+10],msgs^[a,i],10);
 for a:=0 to 7 do
  for i:=0 to 4 do
   mymove(screen[(a div 2)*10+145+i,(a mod 2)*20+130],littlemsgs^[a,i],4);
 for i:=130 to 196 do
  fillchar(screen[i,4],262,0);
 tcolor:=176;
 printxy(19,137,'Mental Capacity');
 printxy(16,144,'Physical Prowess');
 printxy(9,151,'Emotional Stability');
 printxy(27,158,'Extroversion');
 printxy(14,165,'Conscientiousness');
 printxy(24,172,'Agreeableness');
 printxy(32,179,'Creativity');
 printxy(32,186,'Discipline');
 graphindex:=0;
 adjustgraph;
 crewindex:=1;
 mouseindex:=0;
 displaycursor;
 tcolor:=170;
 bkcolor:=0;
 redraw2;
 fadein;
 mouseshow;
 done:=false;
 graphindex:=1;
 msgindex:=32;
 oldt1:=t1;
end;

procedure psychicevaluation;
begin
 readypsychicdata;
 mainloop2;
 dispose(littlemsgs);
 dispose(msgs);
 dispose(holo);
 dispose(mcursor);
 stopmod;
 removedata;
end;


procedure getspikes;
var tech: integer;
begin
 tech:=hi(ship.wandering.techlevel)*10+lo(ship.wandering.techlevel);
 randseed:=ship.wandering.alienid*ship.wandering.alienid*ship.wandering.alienid;
 for j:=1 to 4 do spikes[1,j]:=random(249)+31;
 randomize;
 for j:=1 to 4 do spikes[2,j]:=0;
 j:=1;
 randseed:=ship.wandering.alienid;
 while (tech>0) and (j<4) do
  begin
   spikes[2,j]:=random(tech)+random(4);
   tech:=tech-spikes[2,j]+random(4);
   inc(j);
  end;
 if tech>0 then spikes[2,4]:=tech;
 randomize;
end;

procedure drawscope;
begin
 randseed:=tempplan^[curplan].seed;
 if showplanet then
  begin
   x1:=random(628)/100;
   i:=random(20)+4;
   x:=round(cos(x1)*i)+250;
   y:=round(sin(x1)*i)+150;
   for j:=0 to 35+random(20) do
    begin
     x1:=random(628)/100;
     i:=random(7);
     screen[round(i*sin(x1))+y,round(i*cos(x1))+x]:=random(31);
    end;
  end;
 for j:=0 to random(45)+15 do
  begin
   x1:=random(628)/100;
   i:=random(30);
   screen[round(i*sin(x1))+150,round(i*cos(x1))+250]:=random(31);
  end;
 for i:=120 to 180 do
  mymove(screen[i,210],scope^[i,210],20);
 randomize;
end;

procedure drawcleangraph;
begin
 mousehide;
 randomize;
 if ship.wandering.alienid<16000 then
  begin
   dist:=ship.wandering.relx;
   if ship.wandering.rely>dist then dist:=ship.wandering.rely;
   if ship.wandering.relz>dist then dist:=ship.wandering.relz;
   dist:=abs(round(dist/1280));
  end
 else dist:=18;
 for i:=21 to 49 do
  fillchar(screen[i,31],249,0);
 for i:=61 to 89 do
  fillchar(screen[i,31],249,0);
 for j:=31 to 279 do screen[43,j]:=random(22)+8;
 for j:=1 to 4 do if spikes[2,j]>0 then
  begin
   signaly:=round(spikes[2,j]*(19-dist)*ship.crew[3].level/3150*spikes[2,j]);
   if signaly>18 then signaly:=18;
   if ship.wandering.alienid<16000 then screen[40-signaly,spikes[1,j]]:=random(22)+8;
  end;
 line(31,64+dist,279,64+dist);
 if (ship.wandering.alienid<16000) then
  begin
   x:=ship.wandering.relx;
   y:=ship.wandering.rely;
   z:=ship.wandering.relz;
   x:=round((x+z)*0.0005);
   y:=round((y+z)*0.0005);
   scope^[150+y,250+x]:=random(10)+7;
  end;
 for i:=120 to 180 do
  mymove(scope^[i,210],screen[i,210],20);
 mouseshow;
end;

procedure drawgraph;
label error;
begin
 if ship.wandering.alienid<16000 then
  begin
   dist:=ship.wandering.relx;
   if ship.wandering.rely>dist then dist:=ship.wandering.rely;
   if ship.wandering.relz>dist then dist:=ship.wandering.relz;
   dist:=abs(round(dist/1280));
  end
 else dist:=18;
 mousehide;
 for i:=21 to 49 do
  fillchar(screen[i,31],249,0);
 for i:=61 to 89 do
  fillchar(screen[i,31],249,0);
 n2:=(n2*1.0-ship.crew[3].level/2000);
 if n2<0.11 then n2:=0.11;
 if rotatemode=0 then n2:=1;
 for j:=31 to 279 do screen[43-random(round(n2*noise))+round(n2/2),j]:=random(22)+8;
 moveto(31,83-random(round(n2*noise))+round(n2/2));
 setcolor(31);
 for j:=31 to 279 do
  begin
   inc(j,2);
   if j>279 then goto error;
   if random(12)=0 then lineto(j,83-random(19-dist))
    else lineto(j,83-random(round(n2*noise))+round(n2/2));
  end;
error:
 for j:=1 to 4 do if spikes[2,j]>0 then
  begin
   signaly:=round(spikes[2,j]*(19-dist)*ship.crew[3].level/3150*spikes[2,j]);
   if signaly>18 then signaly:=18;
   if ship.wandering.alienid<16000 then screen[40-signaly,spikes[1,j]]:=random(22)+8;
  end;
 for i:=120 to 180 do
  mymove(scope^[i,210],screen[i,210],20);
 for i:=1 to round(noise*n2) do
  begin
   x:=random(23000);
   y:=random(23000);
   z:=random(23000);
   x:=round((x+z)*0.0005);
   y:=round((y+z)*0.0005);
   screen[150+y,250+x]:=random(10)+5;
  end;
 if (ship.wandering.alienid<16000) then
  begin
   x:=ship.wandering.relx;
   y:=ship.wandering.rely;
   z:=ship.wandering.relz;
   x:=round((x+z)*0.0005);
   y:=round((y+z)*0.0005);
   scope^[150+y,250+x]:=random(10)+7;
  end;
 mouseshow;
end;

procedure cleanwhatzup;
var str1: string[5];
    esttech,tech: integer;
    r: real;
begin
 esttech:=0;
 if ship.wandering.alienid<16000 then
  begin
   tech:=hi(ship.wandering.techlevel)*10+lo(ship.wandering.techlevel);
   j:=1;
   randseed:=ship.wandering.alienid;
   while (tech>0) and (j<4) do
    begin
     i:=random(tech)+random(4);
     tech:=tech-i+random(4);
     inc(esttech,i);
     inc(j);
    end;
   if tech>0 then esttech:=esttech+tech;
  end;
 mousehide;
 printxy(37,119,'Interferance');
 printxy(37,126,'Noise Filter');
 printxy(37,136,'Estimating...');
 printxy(40,143,'Tech Level');
 printxy(45,150,'Distance');
 printxy(134,119,'Active');
 printxy(134,126,'Active');
 if ship.wandering.alienid<16000 then
  begin
   r:=sqr(ship.wandering.relx/10);
   r:=r+sqr(ship.wandering.rely/10);
   r:=r+sqr(ship.wandering.relz/10);
   r:=sqrt(r)*100;
  end
 else r:=0;
 str(r:8:1,str1);
 printxy(119,150,str1+' KKm');
 str((esttech/10):3:1,str1);
 printxy(149,143,str1);
 mouseshow;
end;

procedure whatzup;
var str1: string[5];
    total,a: integer;
    esttech,estdist: real;
begin
 mousehide;
 printxy(37,119,'Interferance');
 printxy(37,126,'Noise Filter');
 printxy(37,136,'Estimating...');
 printxy(40,143,'Tech Level');
 printxy(45,150,'Distance');
 str(round(noise*5.55556):3,str1);
 printxy(144,119,str1+'%');
 str((1-n2)*100:3:0,str1);
 printxy(144,126,str1+'%');
 if ship.wandering.alienid>15999 then
  begin
   esttech:=random(round(n2*noise));
   estdist:=random(round(n2*noise));
  end
 else
  begin
   esttech:=0;
   dist:=ship.wandering.relx;
   if ship.wandering.rely>dist then dist:=ship.wandering.rely;
   if ship.wandering.relz>dist then dist:=ship.wandering.relz;
   dist:=abs(round(dist/1280));
   for j:=1 to 4 do if spikes[2,j]>0 then
    begin
     signaly:=round(spikes[2,j]*(19-dist)*ship.crew[3].level/3150*spikes[2,j]);
     if signaly>=(round(n2*noise)-round(n2/2)) then esttech:=esttech+signaly;
    end;
   total:=0;
   a:=0;
   for j:=31 to 279 do
    begin
     if random(8)=0 then
      begin
       total:=total+random(19-dist);
       inc(a);
      end
     else
      begin
       i:=random(round(n2*noise))-round(n2/2);
       if i>1 then begin total:=total+i; inc(a); end;
      end;
    end;
   estdist:=18-total/a;
   if estdist<1 then estdist:=1;
   esttech:=sqrt(esttech/ship.crew[3].level*3150/(19-estdist));
  end;
 str((esttech/10):3:1,str1);
 printxy(149,143,str1);
 str((estdist*1280000):8:0,str1);
 printxy(119,150,str1+' KKM');
 mouseshow;
end;

procedure processsweepkey;
var ans: char;
begin
 ans:=readkey;
 case ans of
  #27: done:=true;
  '?': whatzup;
  '`': bossmode;
 end;
end;

procedure findsweepmouse;
var button: boolean;
begin
 if mouse.getstatus(left) then button:=true else button:=false;
 if not button then exit;
 case mouse.y of
    52..58: if (mouse.x>19) and (mouse.x<28) then
             begin
              if rotatemode=0 then
               begin
                rotatemode:=1;
                n2:=1;
                plainfadearea(21,53,26,57,-32);
               end
               else
                begin
                 rotatemode:=0;
                 plainfadearea(21,53,26,57,32);
                end;
             end;
  116..131: if (mouse.x>19) and (mouse.x<28) then
             begin
              if infoindex=0 then infoindex:=1 else
               begin
                infoindex:=0;
                printxy(134,119,'  ');
                printxy(134,126,'  ');
              end;
             end;
  133..151: if (mouse.x<29) and (mouse.x>18) then done:=true;
 end;
end;

procedure mainsweeploop;
begin
 repeat
  if fastkeypressed then processsweepkey;
  findsweepmouse;
  if infoindex=0 then
   begin
    drawgraph;
    whatzup;
   end
  else
   begin
    drawcleangraph;
    cleanwhatzup;
   end;
  adjustlights;
  delay(tslice*4);
 until done;
end;

procedure readysweepdata;
begin
 mousehide;
 compressfile(tempdir+'\current.vga',@screen);
 fading;
 playmod(true,'sound\scanner.mod');
 loadscreen('data\scan.vga',@screen);
 fadein;
 new(scope);
 drawscope;
 if ship.wandering.alienid<16000 then getspikes;
 mouseshow;
 done:=false;
 tcolor:=29;
 bkcolor:=0;
 rotatemode:=0;
 infoindex:=0;
 n2:=1;
 oldt1:=t1;
 if showplanet then
  begin
   if tempplan^[curplan].orbit=0 then noise:=18
    else noise:=round((exp(abs(tempplan^[curplan].orbit-6)))/10)
  end
  else noise:=0;
end;

procedure sweepinfo;
begin
 readysweepdata;
 mainsweeploop;
 dispose(scope);
 stopmod;
 removedata;
end;


{procedure setupbreach1;
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
   loadscreen('data\blast0'+chr(a+48)+'',t);
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
 loadscreen('data\lilship',t);
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
 loadscreen('data\world3',t);
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

(*{**************}

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
 loadscreen('data\breach1',@screen);
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
 loadscreen('data\breach2',@screen);
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
 loadscreen('data\charcom',@screen);
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
 loadscreen('data\cloud',@screen);
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
 colors[254,1]:=63;
 colors[255,1]:=63;
 wait(5);
 fading;

 if fastkeypressed then goto continue;
{#2.1}
 loadscreen('data\battle1',@screen);
 for i:=1 to 120 do
  mymove2(screen[i+12,28],planet^[i],30);
 makeplanet(0,false);
 fadein;
 makeplanet(12,false);
 fading;
 if fastkeypressed then goto continue;
{#2.2}
 loadscreen('data\ship1',@screen);
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
 loadscreen('data\battle1',@screen);
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
 loadscreen('data\world2',@screen);
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
*)

procedure rotatecube2(src,tar: byte; fkey: boolean);
label skip1,skip2,skip3;
begin  {215,145}
 getcube(src,tar);
 if (ship.options[6]=0) or (fkey) then
  begin
   mousehide;
   for i:=0 to 44 do
    move(cubetar^[i,0],screen[i+145,215],51);
   mouseshow;
   cube:=tar;
   exit;
  end;
 b:=tslice div 4;
 mousehide;
 for t:=1 to 21 do
  begin
   m:=round(10.5624*sin(3*t/20));
   q:=round(sin(3*t/40)*51);
   part:=51/q;
   for j:=0 to q-1 do
    begin
     index:=round(j*part);
     if index<51 then
      for i:=145 to 159 do
       screen[i,j+215-m]:=cubetar^[i-145,index];
    end;
   if (51+2*m-q)=0 then goto skip1;
   part:=51/(51+2*m-q);
   for j:=215-m+q to 266+m do
    begin
     index:=round((j-215+m-q)*part);
     if index<51 then
      for i:=145 to 159 do
       screen[i,j]:=cubesrc^[i-145,index];
    end;
 skip1:
{   q:=round(sin((16-t*3/4)/20)*51); }
   if q=0 then goto skip2;
   part:=51/q;
   for j:=0 to q-1 do
    begin
     index:=round(j*part);
     if index<51 then
      for i:=160 to 174 do
       screen[i,j+215-m]:=cubetar^[i-145,index];
    end;
   if (51+2*m-q)=0 then goto skip2;
   part:=51/(51+2*m-q);
   for j:=215-m+q to 266+m do
    begin
     index:=round((j-215+m-q)*part);
     if index<51 then
      for i:=160 to 174 do
       screen[i,j]:=cubesrc^[i-145,index];
    end;
 skip2:
   q:=round(sin(3*t/40)*51);
   part:=51/q;
   for j:=0 to q-1 do
    begin
     index:=round(j*part);
     if index<51 then
      for i:=175 to 189 do
       screen[i,j+215-m]:=cubetar^[i-145,index];
    end;
   if (51+2*m-q)=0 then goto skip3;
   part:=51/(51+2*m-q);
   for j:=215-m+q to 266+m do
    begin
     index:=round((j-215+m-q)*part);
     if index<51 then
      for i:=175 to 189 do
       screen[i,j]:=cubesrc^[i-145,index];
    end;
 skip3:
    for i:=145 to 189 do
     begin
      for j:=266+m to 278 do screen[i,j]:=back4[j-266,i-145];
      for j:=202 to 214-m do screen[i,j]:=back3[j-202,i-145];
     end;
    delay(b);
   end;
 for i:=0 to 44 do
  move(cubetar^[i,0],screen[i+145,215],51);
 mouseshow;
 cube:=tar;
end;

procedure rotatecube(src,tar: byte; fkey: boolean);
label skip1,skip2,skip3;
begin  {215,145}
 if tar+src=5 then
  begin
   if (tar=2) or (tar=3) then rotatecube2(src,tar-2,fkey)
   else if (tar>0) then rotatecube2(src,tar-1,fkey)
   else rotatecube2(src,tar+1,fkey);
  end;
 if random(4)=0 then
  begin
   rotatecube2(src,tar,fkey);
   exit;
  end;
 getcube(src,tar);
 if (ship.options[6]=0) or (fkey) then
  begin
   mousehide;
   for i:=0 to 44 do
    move(cubetar^[i,0],screen[i+145,215],51);
   mouseshow;
   cube:=tar;
   exit;
  end;
 mousehide;
 getback;
 b:=tslice div 4;
 for t:=1 to 20 do
  begin
  m:=round(10.5624*sin(3*t/20));
  q:=round(sin(3*t/40)*45);
  part:=45/q;
  for j:=0 to q-1 do
   begin
    index:=round(j*part);
    if index<46 then
     for i:=215 to 231 do
      screen[j+145-m,i]:=cubetar^[index,i-215];
   end;
  if (45+2*m-q)=0 then goto skip1;
  part:=45/(45+2*m-q);
  for j:=145-m+q to 188+m do
   begin
    index:=round((j-145+m-q)*part);
    if index<46 then
     for i:=215 to 231 do
      screen[j,i]:=cubesrc^[index,i-215];
   end;
skip1:
{  q:=round(sin((16-t*3/4)/10)*45); }
  if q=0 then goto skip2;
  part:=45/q;
  for j:=0 to q-1 do
   begin
    index:=round(j*part);
    if index<46 then
     for i:=232 to 249 do
      screen[j+145-m,i]:=cubetar^[index,i-215];
   end;
  if (45+2*m-q)=0 then goto skip2;
  part:=45/(45+2*m-q);
  for j:=145-m+q to 188+m do
   begin
    index:=round((j-145+m-q)*part);
    if index<46 then
     for i:=232 to 249 do
      screen[j,i]:=cubesrc^[index,i-215];
   end;
skip2:
  q:=round(sin(3*t/40)*45);
  part:=45/q;
  for j:=0 to q-1 do
   begin
    index:=round(j*part);
    if index<46 then
     for i:=250 to 265 do
      screen[j+145-m,i]:=cubetar^[index,i-215];
   end;
  if (45+2*m-q)=0 then goto skip3;
  part:=45/(45+2*m-q);
  for j:=145-m+q to 188+m do
   begin
    index:=round((j-145+m-q)* part);
    if index<46 then
     for i:=250 to 265 do
      screen[j,i]:=cubesrc^[index,i-215];
   end;
skip3:
   for j:=133 to 145-m do
    mymove(back1[j-133],screen[j,215],13);
   for j:=190+m to 199 do
    mymove(back2[j-190],screen[j,215],13);
   delay(b);
  end;
 for i:=0 to 44 do
  move(cubetar^[i],screen[i+145,215],51);
 mymove(back2,screen[190,215],13);
 mouseshow;
 cube:=tar;
end;
