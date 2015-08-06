program testtime;

uses graftool;

var
 buf1,buf2: array[0..29999] of byte;
 j: word;

begin
 for j:=1 to 1005 do
  begin
   fillchar(buf1,30000,5);
   fillchar(buf2,30000,10);
   move(buf1,buf2,30000);
   move(buf1,buf2,30000);
  end;
end.