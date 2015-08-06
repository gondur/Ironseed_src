program makeartifact;

type
 artifacttype=string[10];
var
 f: file of artifacttype;
 temp: artifacttype;
 ft: text;
 j,i: integer;

begin
 assign(ft,'makedata\anom.txt');
 reset(ft);
 assign(f,'data\artifact.dta');
 rewrite(f);
 for i:=1 to 60 do
  begin
   readln(ft,temp);
   writeln(temp);
   write(f,temp);
  end;
 close(ft);
 close(f);
end.