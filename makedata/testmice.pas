program mousetest;

uses crt, data, gmouse;

begin
 set256colors(colors);
 fillchar(screen,64000,95);
 mouseshow;
 repeat
  mousehide;
  for i:=75 to 125 do
   fillchar(screen[i,100],120,47);
  mouseshow;
  mousehide;
  for i:=75 to 125 do
   fillchar(screen[i,100],120,95);
  mouseshow;
 until keypressed;
 mousehide;
end.