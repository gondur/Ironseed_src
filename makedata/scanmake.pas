program generatecargodata;

type
 cargotype=
  record
   name: string[20];
   size,index: integer;
  end;
 scantype= array[1..12] of byte;
var
 cargo: cargotype;
 f: file of scantype;
 ft: text;
 index,j,i: integer;
 c: char;
 scan: scantype;

begin
 {assign(f,'\ironseed\data\scan.dta');
 reset(f);
 assign(ft,'\ironseed\makedata\scandata.txt');
 reset(ft);}
 assign(f,'data/scan.dta');
 reset(f);
 assign(ft,'makedata/scandata.txt');
 reset(ft);
 for i:=1 to 17 do
  begin
   for j:=1 to 11 do read(ft,scan[j]);
   readln(ft,scan[12]);
   write(f,scan);
  end;
 close(f);
 close(ft);
end.
