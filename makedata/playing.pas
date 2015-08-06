program testdata;

uses crt;

type
 buffer= array[0..3075] of char;

var
 b: buffer;
 f: file of buffer;
 j: integer;
 i: char;

begin
 clrscr;
 assign(f,'d:\games\tsn2\twinion\twinchar.dat');
 reset(f);
 read(f,b);
 close(f);
 for j:=0 to 3075 do
  begin
   i:=b[j];

   i:=chr(ord(i)+16);

   b[j]:=i;
  end;

 for j:=0 to 1075 do
  write(b[j]);
 readkey;
end.