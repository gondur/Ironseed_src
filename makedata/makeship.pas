program makeship;
uses crt,graph,data,gmouse;
type
 icontype= array[1..17,1..15] of byte;
 fonttype= array[1..3] of byte;
 shpimg=array[0..57,0..74] of byte;
var
 tdelay,index,curx,x,cury,i,j,backcolor,
 testdriver,mode,driver,errcode,last,under,textcolor: integer;
 ans: char;
 vgastr: string;
 image: shpimg;

procedure save;
var vgadata: file of shpimg;
begin
 screen[cury,curx]:=under;
 assign(vgadata,vgastr+'.dta');
 reset(vgadata);
 for j:=0 to 57 do
  for i:=0 to 74 do
   if screen[i,j]=38 then screen[i,j]:=0;
 for j:=0 to 57 do
  for i:=0 to 74 do
   image[j,i]:=screen[i,j];
 write(vgadata,image);
 close(vgadata);
end;

procedure load;
var vgadata: file of shpimg;
begin
 assign(vgadata,vgastr+'.dta');
 reset(vgadata);
 read(vgadata,image);
 for j:=0 to 57 do
  for i:=0 to 74 do
   screen[i,j]:=image[j,i];
 close(vgadata);
 last:=screen[cury,curx];
 under:=screen[cury,curx];
end;

procedure mainloop;
begin
 repeat
   inc(screen[cury,curx]);
   if keypressed then
   begin
   ans:=readkey;
   case upcase(ans) of
    #0:begin
        ans:=readkey;
        screen[cury,curx]:=under;
        case ans of
         #72:if cury=0 then cury:=74 else dec(cury);
         #80:if cury=74 then cury:=0 else inc(cury);
         #75:if curx=0 then curx:=174 else dec(curx);
         #77:if curx=174 then curx:=0 else inc(curx);
         #71:begin curx:=(curx div 10) - 1; curx:=curx*10 mod 175; end;
         #79:begin curx:=(curx div 10) + 1; curx:=curx*10 mod 175; end;
         #73:begin cury:=(cury div 10) - 1; cury:=cury*10 mod 75; end;
         #81:begin cury:=(cury div 10) + 1; cury:=cury*10 mod 75; end;
        end;
        under:=screen[cury,curx];
       end;
    ' ':under:=last;
    'S':save;
    'L':load;
    '1':begin under:=0; last:=0; end;
    '2':begin under:=16; last:=16; end;
    '3':begin under:=32; last:=32; end;
    '4':begin under:=48; last:=48; end;
    '5':begin under:=64; last:=64; end;
    '6':begin under:=80; last:=80; end;
    '7':begin under:=96; last:=96; end;
    '8':begin under:=112; last:=112; end;
    '9':begin under:=128; last:=128; end;
    'Q':begin under:=144; last:=144; end;
    'W':begin under:=160; last:=160; end;
    'E':begin under:=176; last:=176; end;
    'R':begin under:=192; last:=192; end;
    'T':begin under:=208; last:=208; end;
    '+':begin inc(under); last:=under; end;
    '-':begin dec(under); last:=under; end;
    'S':save;
    'L':load;
   end;
   end;
 until ans=#59;
end;

function testit : integer;
begin testit:=1; end;

begin
 vgastr:=paramstr(1);
 val(paramstr(1),x,j);
 if j<>0 then x:=125;
 randomize;
 textcolor:=31; backcolor:=0;
 curx:=0; cury:=0;
 set256colors(colors);
 setfillstyle(1,43);
 bar(0,0,319,199);
 setfillstyle(0,0);
 bar(0,0,57,74);
 load;
 loadpal('data\char.pal');
 set256colors(colors);
 mainloop;
 closegraph;
end.