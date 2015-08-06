program displaysystems;

type
 systemtype=
  record
   name: string[12];
   x,y,z,datey,visits: integer;
   numplanets,notes,datem,mode: byte;
  end;
 systemarray= array[1..250] of systemtype;
var
 systems: systemarray;
 f: file of systemarray;
 i,j: integer;

begin
 assign(f,'save5\systems.dta');
 reset(f);
 read(f,systems);
 close(f);
 for i:=1 to 250 do
  with systems[i] do
   begin
    writeln(i:3,' ',name,x:5,y:5,z:5);
   end;
end.