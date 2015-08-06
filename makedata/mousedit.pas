program mouseeditor;

uses crt, graph, data;

var
 mouse: array[1..2,1..16,1..16] of byte;
 i,j,a,b,x,y,color: integer;
 ans: char;

procedure init;
begin
 for a:=1 to 2 do
  for j:=1 to 16 do
   for i:=1 to 16 do
    mouse[a,j,i]:=2-a;
 setcolor(31);
 rectangle(9,9,111,111);
 x:=1;
 y:=1;
end;

procedure draw;
begin
 for j:=1 to 16 do
  for i:=1 to 16 do
   begin
    color:=37;
    if mouse[1,j,i]=0 then color:=0;
    if mouse[2,j,i]=1 then color:=31;
    if mouse[1,j,i]=1 then color:=color+16;
    if (j=x) and (i=y) then setfillstyle(11,color)
     else setfillstyle(1,color);
    bar(j*10,i*10,j*10+10,i*10+10);
    screen[i+50,j+200]:=color;
   end;
end;

procedure mainloop;
begin
 repeat
  draw;
  ans:=readkey;
  case ans of
   #0:begin
      ans:=readkey;
      case ans of
       #72:if y=1 then y:=16 else dec(y);
       #80:if y=16 then y:=1 else inc(y);
       #75:if x=1 then x:=16 else dec(x);
       #77:if x=16 then x:=0 else inc(x);
      end;
     end;
   '1':begin   {background}
        mouse[1,x,y]:=1;
        mouse[2,x,y]:=0;
       end;
   '2':begin   {black}
        mouse[1,x,y]:=0;
        mouse[2,x,y]:=0;
       end;
   '3':begin   {white}
        mouse[1,x,y]:=0;
        mouse[2,x,y]:=1;
       end;
   '4':begin   {funky}
        mouse[1,x,y]:=1;
        mouse[2,x,y]:=1;
       end;
  end;
 until ans=#59;
end;

procedure convert;
var index,b: byte;
begin
 textmode(co80);
 writeln;
 writeln;
 for a:=1 to 2 do
   for i:=1 to 16 do
    begin
     b:=0;
     index:=128;
     for j:=9 to 16 do
      begin
       if mouse[a,i,j]=1 then b:=b+index;
       index:=index div 2;
      end;
     write(b,' ');
     b:=0;
     index:=128;
     for j:=1 to 8 do
      begin
       if mouse[a,i,j]=1 then b:=b+index;
       index:=index div 2;
      end;
     write(b,'| ');
   end;
end;

begin
 init;
 mainloop;
 convert;
end.