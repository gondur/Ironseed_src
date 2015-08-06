program makeland;

uses crt,graph,data;
var vgafile: file of screentype;
begin
 fillchar(screen,64000,0);
 setcolor(10);
 setlinestyle(0,0,3);
 rectangle(26,11,269,134);
 setcolor(12);
 setlinestyle(0,0,0);
 rectangle(26,11,269,134);

 rectangle(269,11,319,51);
 rectangle(269,51,319,91);
 rectangle(269,91,319,131);
 rectangle(269,131,319,171);

 assign(vgafile,'data\landform.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);

 readkey;
end.