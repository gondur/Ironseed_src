program testshipdraw;
uses crt, data, graph, dos;

type
 portraittype= array[0..69,0..69] of byte;
 scrtype=array[40..132,94..226] of byte;
 holotype= array[35..63,84..120] of byte;
var
 a,b,c,i,j: integer;
 vgafile: file of screentype;
 palfile: file of paltype;

procedure savescreen(s: string);
begin
 assign(vgafile,s);
 rewrite(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

procedure savepal(s: string);
begin
 assign(palfile,s);
 rewrite(palfile);
 write(palfile,colors);
 close(palfile);
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

procedure ship;
begin
 fillchar(screen,64000,31);
 for a:=1 to 200 do
  begin
   setfillstyle(1,random(12)+4);
   j:=random(320);
   i:=random(200);
   bar(j,i,j+random(40),i+random(40));
  end;
 plate(0,0,319,199);
 readkey;
end;

procedure stars;
var vgafile: file of screentype;
begin
 fillchar(screen,64000,0);
 for a:=1 to 75 do
  begin
   j:=random(320);
   i:=random(200);
   c:=random(10)+10;
   screen[i,j]:=c;
   if random(2)=0 then
   for b:=1 to random(4) do
    begin
     screen[i+b,j]:=c div (b+1);
     screen[i-b,j]:=c div (b+1);
     screen[i,j+b]:=c div (b+1);
     screen[i,j-b]:=c div (b+1);
    end;
 end;
 readkey;
 assign(vgafile,'data\cloud.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

procedure makehighspeed;
var f: file of screentype;
    str1: string[1];
    a,b,total,count,x: integer;
    f2: file of paltype;
begin
 setcolor(10);
 setaspectratio(3,5);
 for j:=0 to 3 do
  begin
   str(j,str1);
   assign(f,'data\highspd'+str1+'.vga');
   reset(f);
   for i:=0 to 63 do
    begin
     colors[i,1]:=i;
     colors[i,2]:=round(i/1.2);
     colors[i,3]:=round(i/1.2);
    end;
   for i:=64 to 127 do
    for a:=0 to 3 do colors[i,a]:=i-64;
   set256colors(colors);
   fillchar(screen,64000,0);
   for i:=0 to 230 do
    begin
     setcolor(round(i/230*64));
     circle(160,100,i);
    end;
   setcolor(12);
   b:=1;
   for i:=0 to 11 do
    begin
     b:=b*2;
     circle(160,100,b+round(b/4*j));
    end;
   for x:=0 to 319 do
    for i:=0 to 199 do
     if screen[i,x]=0 then
      begin
       total:=0;
       count:=0;
       for a:=-1 to 1 do
        for b:=-1 to 1 do
         if screen[i+b,x+a]<>0 then
          begin
           inc(count);
           inc(total,screen[i+b,x+a]);
          end;
       screen[i,x]:=round(total/count);
      end;
   for i:=110 to 199 do
    begin
     a:=1-j;
     setcolor(round((i-110)/99*40)+66+a);
     line(61+i,i,259-i,i);
     line(61+i,199-i,259-i,199-i);
    end;
   setcolor(80);
   readkey;
   write(f,screen);
   close(f);
  end;
 assign(f2,'data\highspd.pal');
 reset(f2);
 write(f2,colors);
 close(f2);
end;

procedure redocargo;
var i: integer;
    vgafile: file of screentype;
begin
 loadscreen('data\cargo.vga',@screen);
 loadpal('data\main.pal');
{ for i:=0 to 19 do
  for j:=160 downto 0 do
    screen[i,319-j]:=screen[i,j];
 for i:=131 to 199 do
  for j:=0 to 160 do
   if ((screen[i,319-j]<32) and (screen[i,319-j]<>0))
      or ((screen[i,319-j]>111) and (screen[i,319-j]<128))

    then screen[i,j]:=screen[i,319-j];
}

 for i:=0 to 19 do
  for j:=1 to 160 do
   screen[i,320-j]:=screen[i,j];

 assign(vgafile,'data\cargo.vga');
 reset(vgafile);
{ write(vgafile,screen);}
 close(vgafile);
 readkey;
end;

procedure newintro;
var a: integer;
    c,d,e: real;
    f,g,h: real;
    ans: char;
    vgafile: file of screentype;
    f2: file of paltype;
begin
 loadscreen('makedata\intro.vga',@screen);
 loadpal('data\main.pal');
 colors[15]:=colors[31];
 for i:=0 to 199 do
  for j:=0 to 319 do
   if (screen[i,j]>0) then screen[i,j]:=128+(screen[i,j] mod 32);
 for i:=0 to 157 do
  begin
   a:=128-round(i/157*63);
   for j:=0 to 319 do if screen[i,j]=0 then screen[i,j]:=a;
  end;
 c:=1.95;
 d:=1.0;
 e:=0.9;
 f:=0.8;
 g:=0.0;
 h:=0.35;
 repeat
  ans:=readkey;
  case upcase(ans) of
   'Q': c:=c+0.05;
   'W': d:=d+0.05;
   'E': e:=e+0.05;
   'A': c:=c-0.05;
   'S': d:=d-0.05;
   'D': e:=e-0.05;
   'I': f:=f+0.05;
   'O': g:=g+0.05;
   'P': h:=h+0.05;
   'K': f:=f-0.05;
   'L': g:=g-0.05;
   ';': h:=h-0.05;
  end;
  for j:=64 to 127 do
  begin
   colors[j,1]:=round((j-64)*f);
   colors[j,2]:=round((j-64)*g);
   colors[j,3]:=round((j-64)*h);
  end;
  for j:=128 to 159 do
  begin
   colors[j,1]:=round((j-128)*c);
   colors[j,2]:=round((j-128)*d);
   colors[j,3]:=round((j-128)*e);
  end;
  set256colors(colors);         {1.7,0.6,1.6}   {2.4,1.2,1.6}
 until ans=#27;
{ assign(vgafile,'data\intro.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
 assign(f2,'data\intro.pal');
 reset(f2);
 write(f2,colors);
 close(f2);
} closegraph;
 writeln(c,'/',d,'/',e);
 writeln(f,'/',g,'/',h);
  {awesome!!!!!  2.0,0.8,1.25, 0.6,0,0.3}
  {              1.85,1.1,1.15 0.8,0,0.3}
end;

procedure newpalette;
var palfile: file of paltype;
begin
 loadpal('data\main.pal');
 for j:=192 to 255 do
  for i:=1 to 3 do colors[j,i]:=j-192;
 assign(palfile,'data\bw.pal');
 reset(palfile);
 write(palfile,colors);
 close(palfile);
end;

procedure newresearch;
var
 ans: char;
 vgafile: file of screentype;
 palfile: file of paltype;
begin
 loadscreen('data\research.vga',@screen);
 loadpal('data\main.pal');
 for i:=0 to 160 do
  for j:=0 to 319 do
   if screen[i,j]=0 then screen[i,j]:=random(2)+250;
 for i:=132 to 148 do
  fillchar(screen[i,123],75,0);
 for j:=1 to 3 do
  for i:=0 to 16 do
   fillchar(screen[j*40-28+i,123],75,0);
 for i:=52 to 68 do
  fillchar(screen[i,223],85,0);
 for i:=22 to 118 do
  fillchar(screen[i,13],95,0);
 colors[250,1]:=10;
 colors[250,2]:=9;
 colors[250,3]:=0;
 colors[251,1]:=6;
 colors[251,2]:=10;
 colors[251,3]:=13;
 repeat
  ans:=readkey;
  case upcase(ans) of
   'Q': inc(colors[250,1]);
   'W': inc(colors[250,2]);
   'E': inc(colors[250,3]);
   'A': dec(colors[250,1]);
   'S': dec(colors[250,2]);
   'D': dec(colors[250,3]);
   'I': inc(colors[251,1]);
   'O': inc(colors[251,2]);
   'P': inc(colors[251,3]);
   'K': dec(colors[251,1]);
   'L': dec(colors[251,2]);
   ';': dec(colors[251,3]);
  end;
  set256colors(colors);
 until ans=#27;
 assign(vgafile,'data\research.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
 assign(palfile,'data\research.pal');
 reset(palfile);
 write(palfile,colors);
 close(palfile);
end;

procedure newchar;
var vgafile: file of screentype;
    palfile: file of paltype;
    i2: integer;
begin
 loadscreen('data\char.vga',@screen);
 loadpal('data\char.pal');
{ for a:=18 downto 1 do
  begin
   for i:=a to 199 do
    move(screen[i+1],screen[i],100);
  end;
 for i:=0 to 199 do
  move(screen[i,12],screen[i],88);
 for i:=0 to 199 do
  fillchar(screen[i,88],12,0);
 for i:=119 to 199 do
  fillchar(screen[i],268,0);
 for a:=24 downto 1 do
  for i:=a to 119 do
   move(screen[i+1,88],screen[i,88],231);
}
 for i:=0 to 31 do colors[i]:=colors[128+i];


 for i:=0 to 199 do
  for j:=0 to 319 do
   case screen[i,j] of
    128..159: screen[i,j]:=screen[i,j]-128;
   end;

 repeat
  dec(i2);
  if i2<1 then i2:=31;
  i:=i2;
  for j:=0 to 31 do
   begin
    inc(i);
    if i>31 then i:=0;
    colors[j+128]:=colors[i*2+128];
   end;
  set256colors(colors);
  delay(200);
 until fastkeypressed;

 assign(vgafile,'data\char.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
 assign(palfile,'data\char.pal');
 reset(palfile);
 write(palfile,colors);
 close(palfile);
end;

procedure newcharani;
var temp: ^screentype;
    vgafile: file of screentype;
    palfile: file of paltype;
    c: integer;
begin
 new(temp);
 loadpal('data\char.pal');
 set256colors(colors);
 loadscreen('data\char.vga',@screen);
 move(screen,temp^,64000);
 loadscreen('data\char.vga',@screen);
 fillchar(screen,64000,0);
 c:=0;
 for b:=0 to 4 do
  for a:=0 to 5 do
   begin
    inc(c);
    for i:=19+c downto c do
     move(temp^[i+80,32],temp^[i+81,32],25);

    for i:=0 to 34 do
     move(temp^[i+81,22],screen[b*35+i,a*50],49);
   end;
 readkey;
 assign(vgafile,'data\charani.vga');
 reset(vgafile);
{ write(vgafile,screen);}
 close(vgafile);
 dispose(temp);
end;

procedure newimages;
var datafile: file of portraittype;
    s: string[2];
    portrait: ^portraittype;
    n: integer;
begin
 new(portrait);
 loadpal('data\char.pal');
 set256colors(colors);
 for n:=1 to 4 do
  begin
   str(n:2,s);
   if n<10 then s[1]:='0';
   assign(datafile,'data\image'+s+'.vga');
   if ioresult<>0 then errorhandler('portrait',1);
   reset(datafile);
   if ioresult<>0 then errorhandler('portrait',5);
   read(datafile,portrait^);
   for j:=0 to 69 do
    for i:=0 to 69 do
     begin
      if (portrait^[i,j]>128)
       and (portrait^[i,j]<160) then dec(portrait^[i,j],128);
      screen[i+7,j+13]:=portrait^[i,j];
     end;
   readkey;
   reset(datafile);
{   write(datafile,portrait^);}
   close(datafile);
  end;
 dispose(portrait);
end;

procedure newscan;
var vgafile: file of screentype;
begin
 loadscreen('data\scan.vga',@screen);
 set256colors(colors);
 setcolor(31);
 circle(250,150,36);
 circle(250,150,18);
 readkey;
 assign(vgafile,'data\scan.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

procedure cliff;
begin


 for j:=32 to 47 do
  begin
   colors[j,1]:=j-30;
   colors[j,2]:=j-30;
   colors[j,3]:=j-30;
  end;
 for j:=48 to 63 do
  begin
   colors[j,1]:=round((64-j)*1.9);
   colors[j,2]:=round((64-j)*0.9);
   colors[j,3]:=0;
  end;
 for j:=64 to 95 do
  begin
   colors[j,1]:=round((j-55)*1.9);
   colors[j,2]:=round((j-55)*0.9);
   colors[j,3]:=0;
  end;


 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=random(16)+32+round((199-i)/4);

 readkey;
end;

procedure newpal1;
var temp: ^screentype;
    colors2: paltype;
    c: integer;
    vgafile: file of screentype;
    palfile: file of paltype;
begin
 new(temp);
 loadpal('data\land2.pal');
 colors2:=colors;
 loadpal('data\land1.pal');
 loadscreen('data\land2.vga',@screen);
 move(screen,temp^,64000);
 loadscreen('data\land1.vga',@screen);
 for j:=0 to 63 do for i:=1 to 3 do colors[j,i]:=j;
 set256colors(colors);
 x:=20;
 for i:=0 to 199 do
  begin
   if i mod 32=0 then dec(x);
   for j:=0 to 319 do
    begin
     c:=round(colors2[temp^[i,j],1]*0.30+colors2[temp^[i,j],2]*0.59+colors2[temp^[i,j],3]*0.11);
     screen[100+round(i/10),143+round(j/16)+x]:=c;
    end;
  end;
 readkey;
 assign(vgafile,'data\land1.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
 assign(palfile,'data\land1.pal');
 reset(palfile);
 write(palfile,colors);
 close(palfile);
 dispose(temp);
end;

procedure newpal2;
var palfile: file of paltype;
begin
 loadpal('data\land2.pal');
 for j:=0 to 63 do
  for i:=1 to 3 do colors[j,i]:=j;
 for j:=64 to 127 do
  begin
   colors[j,1]:=j-64;
   colors[j,2]:=0;
   colors[j,3]:=0;
  end;
 readkey;
 assign(palfile,'data\land2.pal');
 reset(palfile);
 write(palfile,colors);
 close(palfile);
end;

procedure newplanicons;
var vgafile: file of screentype;
begin
 loadscreen('data\planicon.vga',@screen);
 for a:=8 to 11 do
  for i:=10 to 29 do
   move(screen[i,140],screen[i,a*20],20);

 readkey;
 assign(vgafile,'data\planicon.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;


procedure newresearch2;
var vgafile: file of screentype;
begin
 loadscreen('data\research.vga',@screen);
 for i:=165 to 199 do
  for j:=152 to 318 do
    if screen[i,j]=0 then screen[i,j]:=random(2)+250;

 colors[250,1]:=10;
 colors[250,2]:=9;
 colors[250,3]:=0;
 colors[251,1]:=6;
 colors[251,2]:=10;
 colors[251,3]:=13;
 set256colors(colors);

 readkey;

 assign(vgafile,'data\research.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

procedure newcombat;
var vgafile: file of screentype;
begin
 loadscreen('data\tactic.vga',@screen);

 setcolor(47);

 circle(265,102,45);

 setaspectratio(1,4);

 circle(105,102,102);

 readkey;
 assign(vgafile,'data\tactic.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);

end;

procedure newcombat2;
var j: longint;
   ans: char;
   temp: ^screentype;
   total: integer;
begin

 loadscreen('data\tactic.vga',@screen);

  for i:=37 downto 31 do
   move(screen[i-1],screen[i],80);
  fillchar(screen[30],80,0);

  for i:=37 downto 15 do
   move(screen[i-1,80],screen[i,80],120);


 readkey;

{ assign(vgafile,'data\tactic.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
}

end;

procedure makebitmap;
begin
 set256colors(colors);
 loadscreen('makedata\bitmap.vga',@screen);
{ for i:=0 to 99 do
  fillchar(screen[i],100,32);
 setcolor(123);   }


 setfillstyle(1,0);
 arc(50,50,200,340,30);
 screen[50,50]:=0;

 readkey;
 assign(vgafile,'makedata\bitmap.vga');
 rewrite(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

{$L mover}
{$f+}
procedure mymove(var src,tar; count: word); external;
{$f-}

procedure testmoves;
var temp,temp2: ^screentype;
begin
 loadscreen('data\main.vga',@screen);
 new(temp);
 new(temp2);
 mymove(screen,temp^,16000);
 fillchar(temp2^,64000,0);
 for j:=1 to 500 do
  begin
   mymove(temp2^,screen,12800);
   mymove(temp^,screen,12800);
  end;
{ for j:=1 to 500 do
  begin
   for i:=40 to 132 do
    move(temp2^[i,94],screen[i,94],132);
   for i:=40 to 132 do
    move(temp^[i,94],screen[i,94],132);
  end;
} dispose(temp2);
 dispose(temp);
end;

procedure newchar2;
var temp: ^screentype;
begin
 new(temp);
 loadpal('data\char.pal');
 set256colors(colors);
 loadscreen('data\sector.vga',@screen);
 temp^:=screen;
 loadscreen('data\char2.vga',@screen);
 for j:=60 to 110 do
  for i:=80 to 110 do
   begin
    a:=temp^[i,j];
    if a<31 then
     begin
      a:=a*4;
      if a>31 then a:=175+a;
     end;
    screen[i-45,j+125]:=a;
   end;
 readkey;
 dispose(temp);
 savescreen('data\char2.vga');
end;


procedure newmain2;
begin
 colors[255,1]:=63;
 colors[255,2]:=0;
 colors[255,3]:=63;
 set256colors(colors);
 loadscreen('data\main.vga',@screen);
 for a:=0 to 99 do
   for j:=292 downto 186+a do
    for i:=1 to 4 do
     for b:=0 to 10 do
      screen[i*20+15+b,j]:=screen[i*20+15+b,j-1];
 readkey;
 savescreen('data\main2.vga');
end;

procedure newchar2_4;
begin
 loadscreen('data\char2.vga',@screen);
 loadpal('data\char2.pal');
 set256colors(colors);
 for a:=1 to 6 do
  for i:=180 to 195 do
   mymove(screen[i,10],screen[i,a*17+10],4);
 readkey;
 savescreen('data\char2.vga');
end;

procedure newbreach1_1;
begin
 loadscreen('data\breach1.vga',@screen);
 set256colors(colors);
 for i:=80 to 199 do
  for j:=0 to 160 do
   screen[i,320-j]:=screen[i,j];
 readkey;
 savescreen('data\breach1.vga');
end;

procedure newbreach2_1;
begin
 loadscreen('data\breach2.vga',@screen);
 set256colors(colors);
 for i:=0 to 100 do
  for j:=1 to 160 do
   screen[i,320-j]:=screen[i,j];
 for i:=199 downto 101 do
  for j:=0 to 319 do
   screen[i,j]:=screen[200-i,j];
 readkey;
 savescreen('data\breach2.vga');
end;

procedure newbreach2_2;
begin
 loadscreen('data\breach2.vga',@screen);
 set256colors(colors);
 for i:=0 to 90 do
  for j:=1 to 160 do
   screen[i,319-j]:=screen[i,j];
 for i:=110 to 199 do
  for j:=1 to 160 do
   screen[i,319-j]:=screen[i,j];
 readkey;
 savescreen('data\breach2.vga');
end;

procedure newresearch3;
begin
 loadscreen('data\research.vga',@screen);
 for i:=0 to 199 do
  for j:=0 to 319 do
   if screen[i,j]>249 then screen[i,j]:=0;
 readkey;
end;

procedure newtactic;
var temp: ^screentype;
begin
 new(Temp);
 loadscreen('data\war.vga',@screen);
 for i:=0 to 199 do
  move(screen[i],temp^[199-i],320);
 move(temp^,screen,64000);
 readkey;
 savescreen('data\war.vga');
 dispose(temp);
end;

procedure newtech2_1;
begin
 loadscreen('data\tech2.vga',@screen);
 for i:=0 to 17 do
  move(screen[i+105,134],screen[i+40,134],186);
 for i:=0 to 17 do
  move(Screen[i+138,134],screen[i+78,134],186);
 readkey;
 savescreen('data\tech2.vga');
end;

procedure putpixxy(x,y,n: integer);
var t: portraittype;
    f: file of portraittype;
    part: real;
    str1: string[2];
begin
 str(n:2,str1);
 if n<10 then str1[1]:='0';
 assign(f,'data\image'+str1+'.vga');
 reset(f);
 read(f,t);
 part:=28/69;
 for i:=0 to 69 do
  for j:=0 to 69 do
   screen[round(y+i*part),round(x+j*part)]:=t[i,j] mod 64;
 close(f);
end;


procedure newbreach2_3;
begin
 loadscreen('data\breach2.vga',@screen);
 loadpal('data\breach2.pal');
 set256colors(colors);

{ for i:=0 to 199 do
  for j:=0 to 319 do
   if screen[i,j]<31 then screen[i,j]:=64+screen[i,j]
    else screen[i,j]:=screen[i,j] mod 16 + 96;
 for i:=0 to 95 do
  for j:=319 downto 160 do
   screen[i,319-j]:=screen[i,j];}

 putpixxy(25,21,1);
 putpixxy(25,51,2);
 putpixxy(55,21,3);
 putpixxy(55,51,4);
 putpixxy(85,21,5);
 putpixxy(85,51,6);
 putpixxy(115,21,7);
 putpixxy(115,51,8);

 putpixxy(173,21,9);
 putpixxy(173,51,10);
 putpixxy(203,21,11);
 putpixxy(203,51,12);
 putpixxy(233,21,13);
 putpixxy(233,51,14);
 putpixxy(263,21,15);
 putpixxy(263,51,16);
 readkey;
end;

procedure newmain;
var holo: ^holotype;
begin
 loadscreen('data\char2.vga',@screen);
 new(holo);
 for i:=35 to 63 do
  mymove(screen[i,84],holo^[i,84],9);
 loadscreen('data\main.vga',@screen);
 for i:=35 to 63 do
  mymove(holo^[i,84],screen[i+117,136+84],9);
 for i:=35+117 to 63+117 do
  for j:=136+84 to 136+120 do
   screen[i,j]:=(screen[i,j] mod 64) div 2;

 dispose(holo);
 readkey;
 savescreen('data\main.vga');
end;

procedure testportrait;
var t: ^portraittype;
    f: file of portraittype;
begin
 loadpal('data\char2.pal');
 set256colors(colors);
 new(t);
 assign(f,'data\image15.vga');
 reset(f);
 read(f,t^);
 close(f);
 repeat
{  for i:=0 to 69 do
   move(t^[i],screen[i],70);}
  for i:=0 to 34 do
   begin
    move(t^[i*2],screen[i*2],70);
    fillchar(screen[i*2+1],70,0);
   end;
  delay(1);
  for i:=0 to 34 do
   begin
    move(t^[i*2+1],screen[i*2+1],70);
    fillchar(screen[i*2],70,0);
   end;
  delay(2);
 until fastkeypressed;
 dispose(t);
end;

procedure newtech2;
var t: ^screentype;
begin
 new(t);
 loadscreen('data\tech2.vga',@screen);
 mymove(screen,t^,16000);
 loadscreen('data\tech1.vga',@screen);
 for i:=33 to 102 do
  move(t^[i,122],screen[i,122],198);
 for i:=105 to 155 do
  move(t^[i,122],screen[i,122],198);
 readkey;
 dispose(t);
 savescreen('data\tech2.vga');
end;

procedure newcom;
begin
 loadscreen('data\com.vga',@screen);
 set256colors(colors);
 for a:=0 to 3 do
  for i:=198 downto 180 do
   move(screen[i-1],screen[i],319);
 readkey;
end;

procedure newalien;
begin
 loadpal('data\alien.pal');
 set256colors(colors);
 loadscreen('data\alien.vga',@screen);
 for i:=0 to 199 do
  for j:=0 to 159 do
   screen[i,320-j]:=screen[i,j];
 for j:=90 to 230 do
  for i:=100 to 199 do
   screen[199-i,j]:=screen[i,j];
 readkey;
{ savescreen('data\alien.vga');}
end;

procedure newstarfield;
begin
 set256colors(colors);
 loadscreen('data\test.vga',@screen);
 for i:=0 to 199 do
  for j:=0 to 319 do
   if screen[i,j]>0 then screen[i,j]:=31-(screen[i,j] div 8);
 readkey;
 savescreen('data\starfeld.vga');
end;

procedure newworld;
var temp: ^screentype;
    temppal: paltype;
begin
 new(temp);
 loadpal('data\cloud2.pal');
 temppal:=colors;
 loadpal('data\world.pal');
 for i:=1 to 55 do
  colors[i]:=temppal[i+200];
 set256colors(colors);
 loadscreen('data\world.vga',@screen);
 for i:=0 to 189 do
  mymove(screen[i+9],screen[i],320);
 readkey;
{ savescreen('data\world.vga');
 savepal('data\world.pal');}
 dispose(temp);
end;

procedure newlensflare;
var temppal: paltype;
begin
 loadpal('data\main.pal');
 temppal:=colors;
 loadpal('data\test.pal');
 for j:=0 to 104 do
  colors[j]:=temppal[j];
 set256colors(colors);
 loadscreen('data\test.vga',@screen);
 readkey;
 savepal('data\battle1.pal');
 savescreen('data\battle1.vga');
end;

procedure newcloud2;
begin
 loadpal('data\world.pal');
 loadscreen('data\cloud2.vga',@screen);
 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=screen[i,j]-200;
 readkey;
 savescreen('data\cloud2.vga');
end;

procedure newintrostuff;
var t: ^screentype;
    a,seed,j,index,max: word;
    temppal: paltype;
    vgafile: file of screentype;
begin
 new(t);
 fillchar(colors,768,0);
 set256colors(colors);
 assign(vgafile,'data\channel7.vga');
 reset(vgafile);
 if ioresult<>0 then errorhandler('channel7.vga',1);
 read(vgafile,t^);
 if ioresult<>0 then errorhandler('channel7.vga',5);
 close(vgafile);
 loadpal('data\main.pal');
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=random(16)+200+(i mod 2)*16;
 tslice:=60;
 max:=38000;
 index:=0;
 j:=0;
 seed:=159;
 repeat
  for i:=200 to 215 do
   colors[i]:=colors[random(16)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  for i:=1 to 70+(60-tslice) do
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
  delay(tslice div 3);
 until index>max;
 a:=31;
 mymove(colors,temppal,192);
 index:=0;
 repeat
  inc(index);
  if a>0 then
   for j:=0 to 199 do
    for i:=1 to 3 do
     colors[j,i]:=round(a*temppal[j,i]/32);
  for i:=200 to 215 do
   colors[i]:=colors[random(16)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice);
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2);
  if index mod 4=0 then dec(a);
 until (fastkeypressed) or (a=0);
 dispose(t);
end;

procedure tryinvertpal;
begin
 loadpal('data\world.pal');
 for i:=32 to 255 do
  begin
 {  colors[i,1]:=round((63-colors[i,1])*0.45);
  colors[i,2]:=round((63-colors[i,2])*0.55); }
   colors[i,3]:=round((63-colors[i,3])*0.85);
  end;
 set256colors(colors);
 loadscreen('data\world.vga',@screen);
 readkey;
end;

procedure tryconvertpal;
var t: colortype;
    min,c,a,b,index: integer;
    indexpal: array[0..255] of byte;
    indexpal2: array[0..255] of byte;
begin
 loadpal('data\world2.pal');
 for j:=0 to 255 do
  for i:=0 to 199 do
   screen[i,j]:=j;
 for j:=0 to 255 do
  indexpal[j]:=j;
 for j:=32 to 255 do
  begin
   min:=colors[j,1]+colors[j,2]+colors[j,3];
   index:=j;
   for i:=j+1 to 255 do
    begin
     c:=colors[i,1]+colors[i,2]+colors[i,3];
     if c<min then
      begin
       index:=i;
       min:=c;
      end
    end;
   if index<>j then
    begin
     c:=indexpal[index];
     indexpal[index]:=indexpal[j];
     indexpal[j]:=c;
     t:=colors[index];
     colors[index]:=colors[j];
     colors[j]:=t;
     set256colors(colors);
     delay(200);
    end;
  end;
 readkey;
 loadscreen('data\world2.vga',@screen);
 for j:=0 to 255 do
  for i:=0 to 255 do
   if indexpal[i]=j then indexpal2[j]:=i;
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=indexpal2[screen[i,j]];
 readkey;
end;

procedure grayscale;
var a,c: integer;
begin
 loadscreen('data\world.vga',@screen);
 loadpal('data\world.pal');
 set256colors(colors);
 for i:=0 to 63 do
  for j:=1 to 3 do colors[i,j]:=i;
 set256colors(colors);
 for j:=0 to 255 do
  for i:=190 to 199 do
   screen[i,j]:=j;
 for i:=0 to 189 do
  for j:=0 to 319 do
   begin
    c:=screen[i,j];
    a:=round(colors[c,1]*0.29+colors[c,2]*0.60+colors[c,3]*0.11);
    screen[i,j]:=a;
   end;
 readkey;
end;

procedure newsweep;
begin
 loadpal('data\scan.pal');
 set256colors(colors);
 loadscreen('data\scan.vga',@screen);
 for i:=0 to 199 do
  for j:=0 to 319 do
   begin
    c:=144+round(55*(199-i+319-j)/520);
    if screen[i,j]=0 then screen[i,j]:=c;
   end;
 readkey;
end;

procedure sector;
begin
 loadpal('data\sector.pal');
 set256colors(colors);
 loadscreen('data\sector.vga',@screen);
 for i:=0 to 30 do
  for j:=0 to 319 do
   begin
    c:=160+round(50*(199-i+319-j)/520);
    if screen[i,j]=0 then screen[i,j]:=c;
   end;
 for i:=0 to 199 do
  for j:=310 to 319 do
   begin
    c:=160+round(50*(199-i+319-j)/520);
    if screen[i,j]=0 then screen[i,j]:=c;
   end;
 for i:=157 to 199 do
  for j:=0 to 319 do
   begin
    c:=160+round(50*(199-i+319-j)/520);
    if screen[i,j]=0 then screen[i,j]:=c;
   end;
 readkey;
end;

procedure psyche2;
begin
 loadpal('data\psyche.pal');
 set256colors(colors);
 loadscreen('data\psyche.vga',@screen);
 for i:=0 to 199 do
  for j:=0 to 319 do
   if screen[i,j] div 32=1 then screen[i,j]:=screen[i,j]+128 else
   if screen[i,j] div 32=5 then screen[i,j]:=screen[i,j]-128;
 readkey;
end;

procedure psyche3;
begin
 loadpal('data\psyche.pal');
 set256colors(colors);
 loadscreen('data\psyche.vga',@screen);
 for i:=50 to 120 do
  for j:=35 to 90 do
   if screen[i,j] div 32=2 then screen[i,j]:=screen[i,j]+32;
 readkey;
 savescreen('data\psyche.vga');
end;

procedure war;
begin
 loadpal('data\war.pal');
 set256colors(colors);
 loadscreen('data\war.vga',@screen);
 for i:=0 to 199 do
  for j:=0 to 319 do
   begin
    c:=160+round(55*(199-i+319-j)/520);
    if screen[i,j]=0 then screen[i,j]:=c;
   end;
 readkey;
end;

procedure newship;
begin
 loadscreen('data\lilship.vga',@screen);
 loadpal('data\lilship.pal');
 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   if screen[i,j]>112 then screen[i,j]:=0;
 readkey;
end;

procedure newworld2;
var t: ^screentype;
begin
 new(t);
 loadscreen('data\cloud.vga',@screen);
 mymove(screen,t^,16000);
 loadpal('data\world2.pal');
 loadscreen('data\world2.vga',@screen);
 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   if (screen[i,j]=0) and (t^[i+40,j]>0) then
    screen[i,j]:=t^[i,j]+64;
 readkey;
 dispose(t);
end;

procedure newalien2;
var t: ^screentype;
begin
 new(t);
 loadpal('data\alien.pal');
 set256colors(colors);
 loadscreen('data\cloud.vga',@screen);
 mymove(screen,t^,16000);
 loadscreen('data\alien.vga',@screen);
 for i:=31 to 138 do
  for j:=3 to 318 do
   if screen[i,j]=0 then screen[i,j]:=t^[i,j];
 readkey;
end;

procedure war2;
begin
 loadpal('data\war.pal');
 set256colors(colors);
 loadscreen('data\war.vga',@screen);
 for i:=55 to 135 do
  for j:=0 to 60 do
   begin
    c:=round(23*(199-i+319-j)/520)-12;
    if screen[i,j]=0 then screen[i,j]:=c;
   end;
 readkey;
end;

procedure newback;
var t: ^screentype;
begin
 loadscreen('makedata\land0001.vga',@screen);
 loadpal('makedata\land0001.pal');
 set256colors(colors);
 readkey;
 for i:=255 downto 64 do
  colors[i]:=colors[i-64];
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=screen[i,j]+64;
 set256colors(colors);
 readkey;
end;

procedure newwar2;
begin
 loadpal('data\war.pal');
 set256colors(colors);
 loadscreen('data\war.vga',@screen);
 setaspectratio(1,3);
 setcolor(47);
 circle(160,70,80);
 screen[70,160]:=47;
 readkey;
end;

procedure logo2;
begin
 loadscreen('data\intro2.vga',@screen);
 loadpal('logo2.pal');
 set256colors(colors);
 for j:=0 to 319 do
  for i:=0 to 199 do
   if screen[i,j] div 32=4 then screen[i,j]:=screen[i,j]+96
    else screen[i,j]:=0;
 readkey;
end;

procedure logo3;
begin
 randomize;
 loadpal('demo.pal');
 x:=100;
 y:=100;
 for i:=1 to 60 do
  for j:=60-i to 60 do
   screen[i+y,x+j-round((60-i)/2)]:=223;
 readkey;
end;

procedure logo4;
begin
 loadpal('logo2.pal');
 loadscreen('demo2.vga',@screen);
 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   begin
    if screen[i,j]=0 then screen[i,j]:=0
     else screen[i,j]:=round(j/320*54)+74;

   end;
 readkey;
end;

procedure scrolly;
begin
 loadpal('logo.pal');
 set256colors(colors);
 for i:=0 to 40 do
  fillchar(screen[i+10,10],40,200-i);
 readkey;
end;

procedure introchange;
begin
 loadscreen('data\intro5.vga',@screen);
 loadpal('data\intro5.pal');
 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   if screen[i,j] div 32=4 then screen[i,j]:=screen[i,j]-64
    else screen[i,j]:=0;
 readkey;
end;

procedure filllogo;
begin
 setgraphbufsize(16000);
 loadpal('water.pal');
 set256colors(colors);
 loadscreen('water.vga',@screen);
 a:=0;
 for i:=0 to 199 do
  begin
   a:=0;
   b:=0;
   for j:=0 to 319 do
    begin
     if (screen[i,j]>0) and (a<>1) then
      begin
       a:=1;
       if b=0 then b:=1 else b:=0;
      end
     else if (a=1) and (screen[i,j]=0) then a:=2;
     if b=1 then screen[i,j]:=205;
    end;
  end;
 readkey;
end;

procedure filllogo2;
begin
 loadpal('water.pal');
 set256colors(colors);
 loadscreen('water.vga',@screen);
 for i:=0 to 199 do
  for j:=0 to 319 do
   if screen[i,j]>0 then screen[i,j]:=screen[i,j]-48+round(i/199*40);
 readkey;
end;

procedure newlogo3;
begin
 loadpal('ocean.pal');
 set256colors(colors);
 loadscreen('ocean.vga',@screen);
 for i:=10 to 100 do
  for j:=0 to 319 do
   if screen[i,j]<223 then screen[i,j]:=random(20)+183;
 readkey;
end;

procedure newsaver;
begin
 loadscreen('data\saver.vga',@screen);
 loadpal('data\saver.pal');
 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   if screen[i,j]>0 then screen[i,j]:=(screen[i,j] mod 32)*2;
 readkey;
end;

procedure newlog;
begin
 loadpal('data\log.pal');
 set256colors(colors);
 loadscreen('data\log.vga',@screen);
 for i:=0 to 199 do
  for j:=0 to 319 do
   if (screen[i,j]>127) and (screen[i,j]<255) then screen[i,j]:=0;

 readkey;

end;

procedure newdragon;
begin
 loadscreen('data\test.vga',@screen);
 loadpal('data\test.pal');
 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=screen[i,j] div 4;
 readkey;
end;

procedure newpic;
begin
 loadscreen('data\test.vga',@screen);
 loadpal('data\test.pal');
 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=screen[i,j] div 4;
 readkey;
 savescreen('makedata\jeremy.vga');
end;

procedure loadshipdisplay2(index,x1,y1: integer);
var shipfile: file of shipdistype;
    temp: ^shipdistype;
    i,j: integer;
begin
 new(temp);
 assign(shipfile,'data\shippix.dta');
 reset(shipfile);
 if ioresult<>0 then errorhandler('data\shippix.dta',1);
 seek(shipfile,index);
 if ioresult<>0 then errorhandler('data\shippix.dta',5);
 read(shipfile,temp^);
 if ioresult<>0 then errorhandler('data\shippix.dta',5);
 close(shipfile);
 for j:=x1 to x1+57 do
  for i:=0 to 74 do
   screen[y1+i,j]:=temp^[j-x1,i];
 dispose(temp);
end;

procedure showships;
begin
 fillchar(screen,64000,4);
 for j:=0 to 8 do
  loadshipdisplay2(j,(j mod 5)*61+3,(j div 5)*77+3);
 readkey;
 savescreen('makedata\shippart.vga');
end;

procedure convertscreens;
var ft: searchrec;
    name,path,dir,ext: string[40];
    f: file;
    i: word;
begin
 findfirst('data\*.vga',$3f,ft);
 while doserror=0 do
  begin
   assign(f,'data\'+ft.name);
   reset(f,1);
   i:=filesize(f);
   if i=64000 then
    begin
     loadscreen('data\'+ft.name,@screen);
     compressfile('data\'+ft.name,@screen);
    end;
   close(f);
   findnext(ft);
  end;
end;

procedure convertscr2;
begin
 loadscreen('scav1.vga',@screen);
 set256colors(colors);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=(screen[i,j] div 8)+191;
 savescreen('scavenger.vga');
 for i:=0 to 31 do
  for j:=1 to 3 do
   colors[i+191,j]:=i*2;
 set256colors(colors);
 savepal('scavenger.pal');
 readkey;
end;

procedure showportrait(n,x,y: integer);
var datafile: file of portraittype;
    s: string[2];
    portrait: ^portraittype;
begin
 new(portrait);
 str(n:2,s);
 if n<10 then s[1]:='0';
 assign(datafile,'data\image'+s+'.vga');
 if ioresult<>0 then errorhandler('portrait',1);
 reset(datafile);
 if ioresult<>0 then errorhandler('portrait',5);
 read(datafile,portrait^);
 close(datafile);
 for i:=0 to 69 do
  move(portrait^[i],screen[i+y,x],70);
 dispose(portrait);
end;

procedure test;
begin
 showportrait(20,0,0);
 showportrait(20,100,0);
 loadpal('makedata\test2.pal');
 set256colors(colors);
 for j:=0 to 69 do
  for i:=0 to 69 do
   begin
    a:=screen[i,j];
    if a<32 then screen[i,j]:=(a div 2)+32
    else screen[i,j]:=(((a mod 32)+32) div 2) + 32;
   end;


 readkey;
end;

begin
 randomize;
 convertscr2;
end.