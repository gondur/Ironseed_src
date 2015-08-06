program converttext;

var
 f: text;
 t: char;

begin
 assign(f,paramstr(1));
 reset(f);
 repeat
  read(f,t);
  if ord(t)<128 then {write(t)} else
  if ord(t)=145 then write(#10,#13) else
   write(chr(ord(t)-128));
 until eof(f);
 close(f);
end.