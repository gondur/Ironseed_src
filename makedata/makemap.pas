program testmap;
uses crt,data,graph,saveload,gmouse;

const
 n: byte = 250;
 tslice: byte = 125;
 posx= 0;
 posy= 0;
 posz= 0;
type
 planettype=
  record
   system,orbit,psize,water,state: byte;
   seed,lastdate,visits: integer;
  end;
var
 a,b,c,t,t2: real;
 j,i,curplan: integer;
 index: byte;
 x1,y1: real;
 ans: char;
 planets: array[1..250] of planettype;
 screen2: array[10..180,50..190] of byte;

procedure generatesystems;
begin
 curplan:=0;
 for j:=1 to 250 do
  begin
   systems[j].x:=random(100)-50;
   systems[j].y:=random(100)-50;
   systems[j].z:=random(100)-50;
   systems[j].numplanets:=random(8)+1;
   for i:=1 to systems[j].numplanets do
    begin
     inc(curplan);
     with planets[curplan] do
      begin
       system:=j;
       water:=random(50);
       seed:=random(65535);
      end;
    end;
   if systems[j].x=0 then dec(j);
   if systems[j].y=0 then dec(j);
   if systems[j].z=0 then dec(j);
  end;
end;

function coordx(x,y,z: integer): integer;
var e: real;
begin
   if (x=0) or (z=0) then begin coordx:=0; exit; end;
   a:=x/sin(arctan(x/z));
   b:=a/2;
   t2:=arctan(z/(2*x));
   x1:=a*cos(t+t2);
   y1:=b*sin(t+t2)+y;
  coordx:=round(x1);
end;

function coordy(x,y,z: integer): integer;
var f: real;
begin
  if (y=0) or (z=0) then begin coordy:=0; exit; end;
  a:=x/sin(arctan(x/z));
   b:=a/2;
   t2:=arctan(z/(2*x));
   x1:=a*cos(t+t2);
   y1:=b*sin(t+t2)+y;
   coordy:=round(y1);
end;

procedure drawsystems(x,y: integer);
label skip2;
begin
 fillchar(screen2,sizeof(screen2),0);
 for j:=1 to n do
  begin
      if systems[j].x=0 then goto skip2;
   a:=systems[j].x/sin(arctan(systems[j].x/systems[j].z));
   b:=a/2;
      if systems[j].x=0 then goto skip2;
   t2:=arctan(systems[j].z/(2*systems[j].x));
   x1:=a*cos(t+t2);
   y1:=b*sin(t+t2)+systems[j].y;
   screen2[y-round(y1),x-round(x1)]:=31;
skip2:
  end;
 for i:=10 to 180 do
  move(screen2[i,50],screen[i,50],140);
end;

begin
 randomize;
 generatesystems;
 mouse.hide;
 t:=0; t2:=0.785;
 ans:='1';
 repeat
  if keypressed then ans:=readkey;
  if ans='1' then begin t:=t+0.01; end
   else if ans='2' then begin t:=t-0.01; end;
  inc(index);
  index:=index mod 8;
  if t>6.28 then t:=0;
  if t<0 then t:=6.28;
  drawsystems(120,100);
 until ans=#59;
 closegraph;
end.