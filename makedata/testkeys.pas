program testkeys;
uses crt;

var
 ans: char;

begin
 repeat
  if keypressed then
   begin
    write(readkey);
   end;
 until ans=#27;
end.