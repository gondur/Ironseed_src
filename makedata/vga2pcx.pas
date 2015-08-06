program convertvgafilestopcxfiles;

uses crt, graph, data;

type
 pcxheadertype= record
   signature,version,rleflag,bitpx: byte;
   x1,y1,x2,y2,hres,vres: word;
   colors: array[0..47] of byte;
   vmode,nplanes: byte;
   bplin,paltype,scrnw,scrnh: word;
   filler: array[0..53] of byte;
  end;
{ colortype= array[1..3] of byte;
 paltype= array[0..255] of colortype; }
var
 pcxheader: pcxheadertype;
 colors: paltype;
 i,j: integer;

procedure errorhandler(s: string; errtype: integer);
begin
 writeln;
 writeln;
 case errtype of
  1: writeln('Opening File Error: ',s);
  5: writeln('Read/Write File Error: ',s);
  6: writeln('Program Error: ',s);
  7: writeln('DOS Error: ',s);
  8: writeln('PCX Error: ',s);
 end;
 halt(4);
end;

procedure initheader;
begin
 with pcxheader do
  begin
   signature:=10;
   version:=5;
   rleflag:=1;
   paltype:=1;
   vmode:=0;
   fillchar(colors,48,0);
   fillchar(filler,54,0);
  end;
 fillchar(colors,768,0);
end;

procedure displaystatus;
begin
 writeln('PCXHEADER:');
 with pcxheader do
  begin
   writeln('  signature: ',signature);
   write(  '  version  : ',version,', ');
   case version of
    0: writeln('version 2.5');
    2: writeln('version 2.8 with palette');
    3: writeln('version 2.8 without palette');
    5: writeln('version 3.0+');
    else writeln('unknown version');
   end;
   writeln('  rleflag  : ',rleflag);
   write(  '  paltype  : ',paltype,', ');
   case paltype of
    1: writeln('color image');
    2: writeln('grayscale image');
    else writeln('unknown image type');
   end;
   writeln('  vmode    : ',vmode);
   writeln('  bitpx    : ',bitpx);
   writeln('  nplanes  : ',nplanes);
   writeln('  bplin    : ',bplin);
   writeln('  x1       : ',x1);
   writeln('  y1       : ',y1);
   writeln('  x2       : ',x2);
   writeln('  y2       : ',y2);
   writeln('  hres     : ',hres);
   writeln('  vres     : ',vres);
   writeln('  scrnw    : ',scrnw);
   writeln('  scrnh    : ',scrnh);
  end;
end;

procedure getpalette(s: string);
var f: file;
    ft: file of paltype;
    j: word;
begin
 if pcxheader.bitpx=1 then
  begin
   colors[1,1]:=63;
   colors[1,2]:=63;
   colors[1,3]:=63;
  end
 else if pcxheader.bitpx=4 then
  move(pcxheader.colors,colors,48)
 else if (pcxheader.bitpx=8) and (pcxheader.nplanes=1) then
  begin
   assign(f,s);
   reset(f,1);
   j:=filesize(f)-771;
   if ioresult<>0 then errorhandler(s,1);
   seek(f,j);
   if ioresult<>0 then errorhandler(s,5);
   blockread(f,i,1);
   blockread(f,colors,768);
   if ioresult<>0 then errorhandler(s,5);
   close(f);

{   if colors[0,1]<>12 then fillchar(colors,768,0); }

   setgraphmode(0);
   set256colors(colors);
   for j:=0 to 255 do
    for i:=0 to 199 do
     screen[i,j]:=j;

   readkey;


  end;
 assign(ft,'tmp.pal');
 rewrite(ft);
 if ioresult<>0 then errorhandler('tmp.pal',5);
 write(ft,colors);
 if ioresult<>0 then errorhandler('tmp.pal',5);
 close(ft);
end;

procedure decode8bit(s: string);
var hdrbyte,datbyte: byte;
    cntbyte: integer;
    size,bytecnt: longint;
    f: file of byte;
    ft: file of byte;
    x,y: integer;
label jumpend;
begin
 assign(ft,'tmp.vga');
 if ioresult<>0 then errorhandler('tmp.vga',1);
 rewrite(ft);
 if ioresult<>0 then errorhandler('tmp.vga',5);
 assign(f,s);
 reset(f);
 if ioresult<>0 then errorhandler(s,1);
 seek(f,128);
 if ioresult<>0 then errorhandler(s,5);
 bytecnt:=0;
 cntbyte:=0;
 size:=(pcxheader.x2-pcxheader.x1+1);
 size:=size*(pcxheader.y2-pcxheader.y1+1);
 if size>64000 then size:=64000;
 x:=-1;
 y:=0;
 while (bytecnt<size) do
  begin
   read(f,hdrbyte);
   if ioresult<>0 then goto jumpend;
   if (hdrbyte and $C0)=$C0 then
    begin
     cntbyte:=hdrbyte and $3F;
     read(f,datbyte);
     if ioresult<>0 then goto jumpend;
    end
   else
    begin
     cntbyte:=1;
     datbyte:=hdrbyte;
    end;
   for j:=1 to cntbyte do
    begin
     inc(x);
     if (x>pcxheader.x2) then
      begin
       x:=-1;
       inc(y);
      end;
     if x<320 then
      begin
       write(ft,datbyte);
       screen[y,x]:=datbyte;
      end;
    end;
   bytecnt:=bytecnt+cntbyte;
  end;
jumpend:
 close(ft);
 close(f);
end;

procedure decode124bit(s: string);
begin
 {****************}
end;

procedure decodepcx(s: string);
var f: file;
begin
 textmode(co80);
 initheader;
 assign(f,s);
 reset(f,1);
 if ioresult<>0 then errorhandler(s,1);
 blockread(f,pcxheader,sizeof(pcxheader));
 if ioresult<>0 then errorhandler(s,5);
 close(f);
 displaystatus;
 if pcxheader.signature<>10 then errorhandler(s,8);
 getpalette(s);
 if pcxheader.bitpx=8 then
  decode8bit(s)
 else decode124bit(s);
end;

begin
 decodepcx('\data\images\example3.pcx');
 readkey;
end.