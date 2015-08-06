program grabportrait;

uses crt, graph, data;
const
 maxx=69;
 maxy=69;
type
 portraittype= array[0..maxy,0..maxx] of byte;
var
 portrait: ^portraittype;
 i,j,x,y: integer;
 ans: char;
 datafile: file of portraittype;
 vgafile: file of screentype;
 ratio: real;

procedure convert;
begin
 for j:=0 to 319 do
  for i:=0 to 199 do
   screen[i,j]:=screen[i,j] div 4;
 for j:=0 to 319 do
  for i:=0 to 199 do
   if screen[i,j]>31 then screen[i,j]:=screen[i,j]+128;
end;

procedure saveit;
begin
 assign(datafile,'data\'+paramstr(2)+'.vga');
 rewrite(datafile);
 write(datafile,portrait^);
 close(datafile);
end;

procedure mainloop;
begin
 repeat
  ans:=readkey;
  rectangle(x,y,x+round(maxx*ratio),y+round(maxy*ratio));
  case upcase(ans) of
    #0: begin
         ans:=readkey;
         case ans of
          #72: if y>0 then dec(y) else y:=199;
          #80: if y<199 then inc(y) else y:=0;
          #75: if x>0 then dec(x) else x:=319;
          #77: if x<319 then inc(x) else x:=0;
         end;
        end;
   'S': saveit;
   '+': ratio:=ratio+0.1;
   '-': ratio:=ratio-0.1;
  end;
  for j:=0 to maxx do
   for i:=0 to maxy do
    portrait^[i,j]:=screen[round(i*ratio)+y,round(j*ratio)+x];
  for i:=0 to maxy do
   move(portrait^[i],screen[i+130,250],maxx);
  rectangle(x,y,x+round(ratio*maxx),y+round(ratio*maxy));
 until ans=#27;
end;

begin
 new(portrait);
 x:=0;
 y:=0;
 ratio:=1;
 loadscreen(paramstr(1),@screen);
 loadpal('\save\data\char.pal');
 setcolor(191);
 set256colors(colors);
 convert;
 setwritemode(xorput);
 rectangle(x,y,x+maxx,y+maxy);
 mainloop;
 closegraph;
end.

