program testpixel;

uses crt;

{$L video}
procedure initvga; external;
procedure setpix(x,y: integer; pcolor: byte); external;
function  getpix(x,y: integer ): byte; external;

var
 under,dx,dy,x,y,countx,county: integer;


procedure movedot;
begin
 dx:=25;
 dy:=-4;
 x:=10;
 y:=15;
 under:=getpix(x,y);
 setpix(x,y,31);
 countx:=dx;
 county:=abs(dy);
 repeat
  dec(dx);
  inc(dy);
{  setpix(x,y,under);}
  x:=x+dx;
  y:=y+dy;
  setpix(x,y,31);
  delay(80*3);
 until (dy=24);
end;

begin
 initvga;
 movedot;
 readkey;
end.
