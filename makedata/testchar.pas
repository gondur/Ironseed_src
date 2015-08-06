program testplan;


uses crt,data;

var
 planfile: file of planettype;
 planets: array[1..1000] of planettype;
 j: integer;

begin
 textmode(co80);
 assign(planfile,'save2\planets.dta');
 reset(planfile);
 for j:=1 to 1000 do read(planfile,planets[j]);
 close(planfile);
 for j:=1 to 1000 do
  begin
   if planets[j].mode=0 then
    readkey;
   writeln(j,' ',planets[j].mode);
  end;
end.