program generatecargodata;

const
 maxcargo= 145;
type
 cargotype=
  record
   name: string[20];
   size,index: integer;
  end;
var
 cargo: cargotype;
 f: file of cargotype;
 ft: text;
 index,j,i: integer;
 c: char;

begin
 assign(f,'data\cargo.dta');
 rewrite(f);
 assign(ft,'makedata\cargo.txt');
 reset(ft);
 readln(ft);
 for i:=1 to maxcargo do
  begin
   read(ft,cargo.index);
   for j:=1 to 5 do read(ft,c);
   read(ft,cargo.name);
   readln(ft,cargo.size);
   write(f,cargo);
   writeln(cargo.name,'/',cargo.index,'/',cargo.size);
  end;
 close(f);
 close(ft);
end.
