program testfont;
uses crt, graph, data;

var
 i,j: integer;

procedure printxy(x1,y1: integer; s: string);
var letter,a,index,t,i,j: integer;
begin
 t:=tcolor;
 for j:=1 to length(s) do
  begin
   tcolor:=t;
   letter:=ord(s[j]);
   index:=1;
   for i:=1 to 6 do
    begin
     for a:=4 to 7 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j*5+7-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j*5+7-a]:=bkcolor;
{     dec(tcolor,2);}
     inc(i);
     for a:=0 to 3 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j*5+3-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j*5+3-a]:=bkcolor;
     inc(index);
{     dec(tcolor,2); }
    end;
    if bkcolor<255 then for i:=1 to 6 do screen[y1+i,x1+j*5+4]:=bkcolor;
  end;
 tcolor:=t;
end;

procedure savescreen(s: string);
var vgafile: file of screentype;
begin
 assign(vgafile,s);
 rewrite(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

begin
 set256colors(colors);
 tcolor:=31;
 bkcolor:=4;
 for j:=1 to 55 do
  printxy(j*5-9,-1,chr(j));
 savescreen('makedata\font.vga');
 readkey;
 closegraph;
end.