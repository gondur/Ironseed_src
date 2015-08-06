program grabit;

var
 f,f2: file of byte;
 j: longint;
 temp: byte;


begin
 assign(f2,'test.s3m');
 reset(f2);
 assign(f,'c:\apps\demo\unreal.exe');
 reset(f);
 seek(f,805274);
 for j:=0 to 163088 do
  begin
   read(f,temp);
   write(f2,temp);
  end;
 close(f);
 close(f2);
end.