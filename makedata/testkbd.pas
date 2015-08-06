program testkbd;

uses crt;

begin
 repeat
  writeln(port[$60]);
  delay(200);
 until port[$60]=187;
end.