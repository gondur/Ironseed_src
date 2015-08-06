program generatestatic;
uses crt;
var
 j: word;
 i: byte;
 datafile: file of byte;

begin
 randomize;
 assign(datafile,'sound\static.dta');
 reset(datafile);
 for j:=1 to 40000 do
  begin
   i:=random(256);
   write(datafile,i);
  end;
 close(datafile);
end.
