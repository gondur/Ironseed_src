program newwaves;
uses crt,voctool;
type
 buffertype= array[0..32000] of byte;
var
 j,i: integer;
 buffer: ^buffertype;


procedure savebuf;
var datafile: file of buffertype;
begin
 assign(datafile,'sound\test.voc');
 reset(datafile);
 write(datafile,buffer^);
 close(datafile);
 writeln('Saved!');
end;

procedure sinewave;
var a,index,index2: integer;
begin
{ for j:=0 to 1600 do
  if j mod 2=0 then
   for i:=1 to 20 do buffer^[j*20+i]:=128+round(127*sin(j/320)*-1)
  else for i:=1 to 20 do buffer^[j*20+i]:=128+round(127*sin(j/320));}
{ j:=0;
 i:=0;
 repeat
  inc(index);
  index:=index mod 3000;
  inc(index2);
  index2:=index2 mod 2000;
  for i:=1 to round(100*sin(index/1500)) do
   begin
    inc(j);
    if j mod 2=0 then buffer^[j]:=128 else
     buffer^[j]:=128+round(127*sin(index2/1000));
   end;
 until j>31900;}
 j:=0;
 index:=0;
 repeat
  inc(j);
  for i:=1 to round(20*sin(index/4000) + 30*sin(j/100)) do
   begin
    inc(index);
    if j mod 2=0 then buffer^[index]:=64
     else buffer^[index]:=192;
   end;
 until index>31950;

 writeln('Done!');
end;

begin
 new(buffer);
 sinewave;
 savebuf;
 dispose(buffer);
end.
