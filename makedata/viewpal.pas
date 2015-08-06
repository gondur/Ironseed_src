program viewpalette;

uses crt,graph,data;

var
 j: integer;


begin
 loadpal(paramstr(1));
 set256colors(colors);
 for j:=0 to 255 do
  begin
   setcolor(j);
   line(j,0,j,199);
  end;
 readkey;
 textmode(co80);
end.