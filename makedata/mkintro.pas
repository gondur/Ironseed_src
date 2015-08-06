program makeintroscreen;

uses crt,data,graph;

const
 cd: byte=2*16-2;
var
 i,j,a: integer;
 vgafile: file of screentype;
 temppal: paltype;

procedure savepalette(s: string);
var palfile: file of paltype;
begin
 assign(palfile,s);
 rewrite(palfile);
 write(palfile,colors);
 close(palfile);
 set256colors(colors);
end;

procedure part1;
begin
 loadscreen('makedata\intro.vga');
 loadpal('makedata\intro.pal');
 set256colors(colors);
 tslice:=200;
{ for a:=0 to 15 do
  for i:=40 to 90 do
   for j:=170 downto a do screen[i,j]:=screen[i,j-1];
}
 for j:=0 to 319 do
  for i:=0 to 199 do
   if screen[i,j] div 64=1 then screen[i,j]:=0;

 for j:=32 to 52 do
  begin
   colors[j,1]:=round((j-31)*2.2);
   colors[j,2]:=round((j-31)*2.0);
   colors[j,3]:=round((j-31)*3.0);
  end;
 tslice:=200;
 set256colors(colors);
 for a:=18 downto 2 do
 for j:=0 to 319 do
  for i:=0 to 199 do
   if (screen[i,j]<>0) and ((screen[i,j]<2+cd) or (screen[i,j]>a+cd)) then
    begin
     if screen[i,j-1]<2 then screen[i,j-1]:=a+cd;
     if screen[i,j+1]<2 then screen[i,j+1]:=a+cd;
     if screen[i-1,j]<2 then screen[i-1,j]:=a+cd;
     if screen[i+1,j]<2 then screen[i+1,j]:=a+cd;
    end;

 readkey;

{ mymove(colors,temppal,192);
 for a:=29 downto 1 do
  begin
   for j:=0 to 255 do
    if j<>51 then
     begin
      for i:=1 to 3 do
       temppal[j,i]:=round(a*colors[j,i]/30);
     end
    else
     begin
      if a>20 then
       begin
        for i:=1 to 3 do
         temppal[51,i]:=round((a-20)*colors[51,i]/10);
       end
      else
       begin
        temppal[51,1]:=round(63/20*(20-a));
       end;
     end;
   set256colors(temppal);
   delay(tslice);
  end;
 fillchar(temppal,768,0);
 set256colors(temppal);
 delay(tslice);
}
 assign(vgafile,'data\intro2.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

procedure part5;
begin
 loadscreen('makedata\c7.vga');
{ for j:=0 to 319 do
  for i:=0 to 199 do
   if screen[i,j]>0 then screen[i,j]:=(screen[i,j] mod 16) + 64;

 for j:=64 to 95 do
  begin
   colors[j,1]:=round((j-63)*1.0);
   colors[j,2]:=round((j-63)*2.0);
   colors[j,3]:=round((j-63)*3.0);
  end;

} for j:=32 to 47 do
  begin
   colors[j,1]:=round((j-31)*2.0);
   colors[j,2]:=round((j-31)*2.0);
   colors[j,3]:=round((j-31)*4.0);
  end;
 set256colors(colors);

 for a:=14 downto 2 do
 for j:=0 to 319 do
  for i:=0 to 199 do
   if (screen[i,j]>a+cd) then
    begin
     if screen[i,j-1]<2 then screen[i,j-1]:=a+cd;
     if screen[i,j+1]<2 then screen[i,j+1]:=a+cd;
     if screen[i-1,j]<2 then screen[i-1,j]:=a+cd;
     if screen[i+1,j]<2 then screen[i+1,j]:=a+cd;

     if screen[i,j-2]<2 then screen[i,j-1]:=a+cd;
     if screen[i,j+2]<2 then screen[i,j+1]:=a+cd;
     if screen[i-2,j]<2 then screen[i-1,j]:=a+cd;
     if screen[i+2,j]<2 then screen[i+1,j]:=a+cd;
    end;
 readkey;
 savepalette('data\channel7.pal');
 assign(vgafile,'data\channel7.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

procedure part2;
var temp: ^screentype;
begin
 new(temp);
 assign(vgafile,'data\intro2.vga');
 reset(vgafile);
 read(vgafile,temp^);
 close(vgafile);
 loadpal('data\intro2.pal');
 set256colors(colors);
 for a:=15 downto 2 do
  begin
  for j:=0 to 319 do
   begin
    for i:=0 to 199 do
     begin
      setfillstyle(1,temp^[i,j]);
      bar(j- a div 2,i-a div 2,j+a div 2,i+a div 2);
      i:=i+a;
      if i>199 then i:=199;
     end;
    j:=j+a;
    if j>319 then j:=319;
   end;
   delay(tslice div 4);
  end;
 screen:=temp^;
 readkey;
 for a:=2 to 15 do
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
  delay(tslice div 4);
 end;
 fillchar(screen,64000,0);
 readkey;
 dispose(temp);
end;

procedure part3;
var temp: ^screentype;
begin
 new(temp);
 for a:=0 to 9 do
  begin
   setfillstyle(1,16);
   bar(0,a*20,319,a*20+19);
   setcolor(22);
   line(0,a*20,319,a*20);
   line(0,a*20,0,a*20+19);
   setcolor(8);
   line(0,a*20+19,319,a*20+19);
   line(319,a*20,319,a*20+19);
  end;
 readkey;
 temp^:=screen;
 for a:=9 downto 0 do
  begin
   for i:=18 downto 1 do
    begin
     move(screen[a*20+i],screen[a*20+i+1],320);
    end;
   delay(tslice);
  end;
 readkey;
 dispose(temp);
end;

procedure part4;
var temp: ^screentype;
begin
 new(temp);
 loadscreen('data\main.vga');
 temp^:=screen;
 for a:=2 to 10 do
  begin
  for j:=0 to 319 do
   begin
    for i:=0 to 199 do
     begin
      setfillstyle(1,temp^[i,j]);
      bar(j*a,i*a,j*a+a,i*a+a);
     end;
   end;
  end;
 readkey;
 dispose(temp);
end;

begin
 part1;
end.
