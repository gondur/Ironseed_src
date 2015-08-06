program testcloud;
uses crt,graph,data;

var
 x,y: integer;
 vgafile: file of screentype;
 done: boolean;

begin
 randomize;
 set256colors(colors);
 x:=160;
 y:=100;
 done:=false;
 repeat
  x:=x-1+random(3);
  y:=y-1+random(3);
  if x<0 then x:=319
   else if x>319 then x:=0;
  if y<0 then y:=199
   else if y>199 then y:=0;
  if screen[y,x]<31 then inc(screen[y,x]);
 until (keypressed) or (done);
{ assign(vgafile,'data\test.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);}
 closegraph;
end.