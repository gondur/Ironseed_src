program generatecargodata;

type
 cargotype=
  record
   name: string[20];
   size,index: integer;
  end;
 elemtype= string[24];
var
 cargo: cargotype;
 f: file of elemtype;
 ft: text;
 index,j,i: integer;
 c: char;
 elem: elemtype;

begin
 assign(f,'\ironseed\data\elements.dta');
 reset(f);
 assign(ft,'\ironseed\makedata\element.txt');
 reset(ft);
 read(ft,index);
 repeat
  for j:=1 to 4 do read(ft,c);
  elem:='                        ';
  readln(ft,elem);
  elem[0]:=chr(24);
  i:=25;
  repeat
   dec(i);
  until elem[i]<>' ';
  if i<24 then for j:=i+1 to 24 do elem[j]:=' ';
  for j:=1 to 24 do elem[j]:=upcase(elem[j]);
  write(f,elem);
  writeln(elem);
  read(ft,index);
 until index=0;
 close(f);
 close(ft);
end.