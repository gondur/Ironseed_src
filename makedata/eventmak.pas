program eventmake;

uses crt;

type
 eventtype=
  record
   want,give: integer;
   msg: string[255];
  end;
 pstring= ^string;
var
 t: eventtype;
 ft: text;
 f: file of eventtype;
 j,i: integer;
 ans: char;

procedure upcasestring(s: pstring);
var i: integer;
begin
 i:=length(s^);
 asm
  push ds
  lds dx, s
  inc dx
  mov cx, [i]
  mov ax, 6521h
   int 21h
  pop ds
 end
end;

begin
 clrscr;
 assign(ft,'makedata\event.txt');
 reset(ft);
 assign(f,'data\event.dta');
 rewrite(f);
 for j:=0 to 10 do
  begin
   readln(ft,t.msg);
   for i:=0 to 9 do
    begin
     fillchar(t.msg,255,$20);
     read(ft,t.want);
     read(ft,t.give);
     if (t.want>0) or (t.give>0) then
      begin
       read(ft,ans);
       read(ft,ans);
       readln(ft,t.msg);
       upcasestring(@t.msg);
      end
     else
      begin
       t.msg:='Nothing happens.';
       readln(ft);
      end;
     writeln(t.want:6,t.give:6,'  ',t.msg);
     write(f,t);
    end;
  end;
 close(f);
 close(ft);
end.