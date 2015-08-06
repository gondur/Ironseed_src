program getiteminfostuff;

type
 iteminfotype=
  record
   index: integer;
   info: array[0..3] of string[28];
  end;
var
 iteminfo: iteminfotype;
 f: file of iteminfotype;
 ft: text;
 i,j,count: integer;

begin
 assign(ft,'makedata\iteminfo.txt');
 reset(ft);
 assign(f,'data\iteminfo.dta');
 rewrite(f);
 readln(ft,iteminfo.index);
 count:=0;
 repeat
  for i:=0 to 3 do
   begin
    readln(ft,iteminfo.info[i]);
    if iteminfo.info[i,0]<chr(28) then
     for j:=length(iteminfo.info[i])+1 to 28 do
      iteminfo.info[i,j]:=' ';
    iteminfo.info[i,0]:=chr(28);
   end;
  inc(count);
  writeln(count,':',iteminfo.index);
{  for i:=0 to 3 do
   for j:=1 to 28 do
    iteminfo.info[i,j]:=upcase(iteminfo.info[i,j]); }
  for i:=0 to 3 do writeln(iteminfo.info[i]);
  readln(ft);
  write(f,iteminfo);
  readln(ft,iteminfo.index);
  writeln;
 until iteminfo.index=0;
 close(ft);
 close(f);
end.