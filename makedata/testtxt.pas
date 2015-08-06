program testtext;

uses crt;

type
 texttype=array[0..24,0..79] of integer;
var
 textscreen: texttype absolute $B800:0000;

procedure loadtext(s: string);
var f: file of texttype;
begin
 assign(f,s);
 reset(f);
 read(f,textscreen);
 close(f);
end;

begin
 loadtext('makedata\test.txt');
 readkey;
end.