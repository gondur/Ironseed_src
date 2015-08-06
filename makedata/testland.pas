program landformdisplay;
{$M 64000,0,128000}
uses crt,graph,data;


var
 landform: ^landtype;
 i,j,i2,j2,water,a,b: integer;
 part: real;
 y2,t1,t2,x1,y1: integer;
 ans: char;
 screen2: ^screentype;

{$F+}

procedure createplanet(xc,yc: integer);
var x1,y1: integer;
    a: longint;
begin
 x1:=xc;
 y1:=yc;
 for a:=1 to 40000 do
  begin
   x1:=x1-1+random(3);
   y1:=y1-1+random(3);
   if x1>240 then x1:=1 else if x1<1 then x1:=239;
   if y1>120 then y1:=1 else if y1<1 then y1:=119;
   if landform^[x1,y1]<245 then landform^[x1,y1]:=landform^[x1,y1]+5;
  end;
end;

procedure readyplanet;
begin
 water:=30;
 for i:=1 to 240 do
   for j:=1 to 120 do
     landform^[i,j]:=water-2;
 createplanet(200,90);
 createplanet(30,30);
 createplanet(120,60);
 for i:=10 to 100 do
  for j:=0 to 120 do screen2^[i,j]:=0;
end;

procedure erase(x,y: integer);
begin
 for i:=0 to 100 do
  for j:=0 to 120 do
   screen2^[i,j]:=0;
{ part:=8/(255-water);
 for j:=x to x+60 do
  for i:=y to y+60 do
  begin
   if j>240 then j2:=j-239 else j2:=j;
   if i>120 then i2:=i-119 else i2:=i;
   if landform^[j2,i2]<water then
     begin
      x1:=20+(j-x);
      y1:=(i-y)+40;
      screen[y1,x1]:=0
     end
   else
    begin
     y2:=round(part*landform^[j2,i2]);
     x1:=20+(j-x);
     y1:=(i-y)+40;
     setcolor(0);
     line(x1,y1,x1,y1-4*y2);
    end;
  end;}
end;

procedure display(x,y: integer);
begin
 part:=32/(255-water);
 for j:=x to x+120 do
  for i:=y to y+120 do
  begin
   if j>240 then j2:=j-240 else j2:=j;
   if i>120 then i2:=i-120 else i2:=i;
   if landform^[j2,i2]<water then
     begin
      x1:=20+(j-x);
      y1:=(i-y)+40;
      screen2^[y1,x1]:=40
     end
   else
    begin
     a:=round(landform^[j2,i2]*part);
     if a<7 then a:=43+a
     else if a=7 then a:=128;
     if a<8 then y2:=2
     else y2:=round(part*landform^[j2,i2]/4);
     x1:=20+(j-x);
     y1:=(i-y)+40;

     for b:=y1 downto y1-2*y2 do
      screen2^[b,x1]:=a;
{     screen2[y1-y2,x1]:=31;}
    end;
  end;
  i:=y+120;
  for j:=x to x+30 do
  begin
   if j>240 then j2:=j-240 else j2:=j;
   if i>120 then i2:=i-120 else i2:=i;
   if landform^[j2,i2]<water then
     begin
      x1:=20+(j-x);
      y1:=(i-y)+40;
      screen2^[y1,x1]:=6
     end
   else
    begin
     a:=round(landform^[j2,i2]*part);
     if a<8 then y2:=2
     else y2:=round(part*landform^[j2,i2]/4);
     if a<7 then a:=43+a
     else if a=7 then a:=128
     else a:=6;
     x1:=20+(j-x);
     y1:=(i-y)+40;

     for b:=y1 downto y1-2*y2 do
      screen2^[b,x1]:=a;
{     screen2[y1-y2,x1]:=31;}
    end;
  end;

 move(screen2^,screen,64000);
end;

begin
 new(landform);
 new(screen2);
 readyplanet;
 ans:=' ';
 t1:=1;
 t2:=1;
 repeat
  case ans of
   '6':if t1<240 then inc(t1,5) else t1:=t1-239;
   '2':if t2<120 then inc(t2,5) else t2:=t2-120;
   '4':if t1>1 then dec(t1,5) else t1:=t1+240;
   '8':if t2>1 then dec(t2,5) else t2:=t2+120;
  end;
  display(t1,t2);
  if keypressed then ans:=readkey;
  erase(t1,t2);
 until ans=#59;
 dispose(landform);
 dispose(screen2);
end.

