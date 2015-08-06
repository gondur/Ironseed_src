program testsound;
{$M 16000,0,25000}
uses crt,voctool,data;

var
 speed: ^byte;
 i,j: integer;

begin
 runvoice('sound\engine2.voc');
 speed:=song;
 inc(speed,30);
 for j:=1 to 16 do
  begin
   repeat until vocstatusword=0;
   if speed^<160 then inc(speed^,12);
   vocoutput(song);
  end;
 vocstop;
end.
