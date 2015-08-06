program getscreen;
{$M 2000,70000,70000}
uses crt,Dos;
type
 screentype= array[0..199,0..319] of byte;
 colort2= array[0..2] of byte;
 colortype= array[0..255] of colort2;
 texttype= array[0..24,0..79] of integer;
var
  Int1cSave : Pointer;
  breakflag: boolean;
  vgafile: file of screentype;
  palfile: file of colortype;
  txtfile: file of texttype;
  j,i: integer;
  buffer: ^screentype;
  colors: colortype;
  screen: screentype absolute $A000:0000;
  textscreen: texttype absolute $B800:0000;
  buffer2: ^texttype;

procedure getrgb256(palnum: byte; var r,g,b); assembler;
asm
 xor bh, bh
 mov bl, palnum
 mov ax, 1015h
  int 10h
 les di, r
 mov es:[di], dh
 les di, g
 mov es:[di], ch
 les di, b
 mov es:[di], cl
end;

procedure convert;
var min, index: integer;
    temp: colort2;
begin
 min:=colors[0,0]+colors[0,1]+colors[0,2];
 if min=0 then exit;
 for j:=0 to 255 do
  if (colors[j,0]+colors[j,1]+colors[j,2])<min then
   begin
    index:=j;
    min:=colors[j,0]+colors[j,1]+colors[j,2];
   end;
 if index=0 then exit;
 temp:=colors[index];
 colors[index]:=colors[0];
 colors[0]:=temp;
 for j:=0 to 319 do
  for i:=0 to 199 do
   if buffer^[i,j]=0 then buffer^[i,j]:=index
    else if buffer^[i,j]=index then buffer^[i,j]:=0;
 writeln;
 writeln('0 to ',index,':',min);
end;

{$F+}
procedure BreakHandler; interrupt;
begin
 if port[$60]<>216 then exit;
 move(textscreen,buffer2^,4000);
 move(screen,buffer^,64000);
 for j:=0 to 255 do
  getrgb256(j,colors[j,0],colors[j,1],colors[j,2]);
 BreakFlag := TRUE;
end;
{$F-}

begin
 new(buffer);
 new(buffer2);
 breakflag:=false;
 GetIntVec($1c,Int1cSave);
 SetIntVec($1c,Addr(BreakHandler));
 swapvectors;
 exec('c:\dos\command.com','');
 swapvectors;
 SetIntVec($1c,Int1cSave);
 if breakflag then
  begin
   convert;
   assign(vgafile,'c:\ironseed\makedata\test.vga');
   rewrite(vgafile);
   write(vgafile,buffer^);
   close(vgafile);
   assign(palfile,'c:\ironseed\makedata\test.pal');
   rewrite(palfile);
   write(palfile,colors);
   close(palfile);

   assign(txtfile,'c:\ironseed\makedata\test.txt');
   rewrite(txtfile);
   write(txtfile,buffer2^);
   close(txtfile);

  end;
 dispose(buffer);
 dispose(buffer2);
end.