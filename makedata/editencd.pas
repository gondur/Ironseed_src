program edit_encode_animation_sequence;

uses crt, graph, data, gmouse;

type
 aniscrtype= array[0..60,0..54] of byte;
var
 aniscr: aniscrtype;
 i,j,a,b: integer;


procedure convert;
begin
 loadscreen('data\char.vga');
 for i:=100 to 160 do
  for j:=40 to 94 do
   aniscr[i-100,j-40]:=screen[i,j];
 fillchar(screen,64000,0);
 for b:=0 to 2 do
 for a:=0 to 4 do
  for i:=0 to 60 do
   for j:=0 to 54 do
    screen[i+b*60,j+a*60]:=aniscr[i,j];
end;

procedure save;
var vgafile: file of screentype;
begin
 assign(vgafile,'data\charani.vga');
 reset(vgafile);
 write(vgafile,screen);
 close(vgafile);
end;

begin
 convert;
 save;

 readkey;
 closegraph;
end.