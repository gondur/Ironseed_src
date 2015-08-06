unit voctool;
{version 4.1}

interface

procedure playvoice(n: integer);
procedure playadjustedvoice(n: integer; s: byte);
procedure playloop(n: integer);

const
 vocbreakend= 0;
 vocbreaknow= 1;
type
 voctype=
  object
   statusword,errstat,version,driversize: word;
   fileheader: string;
   fileheaderlength: byte;
   paused,installed: boolean;
   ptrtodriver,oldexitproc: pointer;
   function getvocerrmessage: string;
   procedure vocexitproc;
   procedure getversion;
   procedure setport(portnumber: word);
   procedure setirq(irqnumber: word);
   procedure deinstalldriver;
   procedure setspeaker(onoff: boolean);
   procedure output(bufferaddress: pointer);
   procedure outputloop (bufferaddress: pointer);
   procedure stop;
   procedure pause;
   procedure continue;
   procedure breakloop(breakmode: word);
   constructor initialize;
  end;
 cachetype=
  object
   index,cacheindex: byte;
   oldexitproc: pointer;
   handles,files: array[0..10] of word;
   constructor initialize;
   procedure findfile(n: integer);
   procedure loadfile(n: integer);
   procedure cacheexitproc;
  end;
var
 voc: voctype;
 cache: cachetype;
 vocptr: pointer;
 speed: ^byte;

implementation

uses data,emstool;

type
 typecasttype= array [0..6000] of char;
 tempvoctype= array[0..8000] of byte;

procedure playvoice(n: integer);
begin
 if (not voc.installed) or (ship.options[3]=0) then exit;
 voc.stop;
 if cache.files[cache.cacheindex]<>n then
  begin
   ems.handle:=cache.handles[cache.cacheindex];
   ems.savemap;
   cache.findfile(n);
   ems.handle:=cache.handles[cache.cacheindex];
   ems.restoremap;
  end;
 voc.output(vocptr);
end;

procedure playadjustedvoice(n: integer; s: byte);
begin
 if (not voc.installed) or (ship.options[3]=0) then exit;
 voc.stop;
 if cache.files[cache.cacheindex]<>n then
  begin
   ems.handle:=cache.handles[cache.cacheindex];
   ems.savemap;
   cache.findfile(n);
   ems.handle:=cache.handles[cache.cacheindex];
   ems.restoremap;
  end;
 speed:=vocptr;
 inc(speed,30);
 speed^:=s;
 voc.output(vocptr);
end;

procedure playloop(n: integer);
begin
 if (not voc.installed) or (ship.options[3]=0) then exit;
 voc.stop;
 if cache.files[cache.cacheindex]<>n then
  begin
   ems.handle:=cache.handles[cache.cacheindex];
   ems.savemap;
   cache.findfile(n);
   ems.handle:=cache.handles[cache.cacheindex];
   ems.restoremap;
  end;
 voc.outputloop(vocptr);
end;

{$F+}
procedure voctype.vocexitproc;
{$F-}
begin
 voctype.deinstalldriver;
 exitproc:=voc.oldexitproc;
end;

function voctype.getvocerrmessage: string;
var s: string;
begin
 case voc.errstat of
  100: s:='Driver File CT-VOICE.DRV Not Found.';
  110: s:='No Memory Available For Driver File.';
  120: s:='False Driver File.';
  200: s:='Voc File Not Found.';
  210: s:='No Memory Available For Driver File.';
  220: s:='File Not In Voc Format.';
  300: s:='Memory Allocation Error Occurred.';
  400: s:='No Sound Blaster Card Found.';
  410: s:='False Port Address Used.';
  420: s:='False Interrupt Used.';
  500: s:='No Loop In Process.';
  510: s:='No Sample For Output.';
  520: s:='No Sample Available.';
  else s:='Unknown Failure.';
 end;
 getvocerrmessage:=s;
end;

procedure voctype.getversion;
var
 vdummy : word;
begin
 asm
  mov bx, 0
  call voc.ptrtodriver
  mov vdummy, ax
 end;
 voc.version:=vdummy;
end;

procedure voctype.setport(portnumber: word);
begin
 asm
  mov bx, 1
  mov ax, portnumber
  call voc.ptrtodriver
 end;
end;

procedure voctype.setirq(irqnumber: word);
begin
 asm
  mov bx, 2
  mov ax, irqnumber
  call voc.PtrToDriver
 end;
end;

constructor voctype.initialize;
var
 out,vseg,vofs: word;
 f: File;
begin
 voc.statusword:=0;
 voc.errstat:=0;
 voc.paused:=false;
 voc.fileheaderlength:=$1A;
 voc.fileheader:='Creative Voice File'+#$1A+#$1A+#$00+#$0A+#$01+#$29+#$11+#$01;
 voc.ptrtodriver:=nil;
 assign(f,'ct-voice.drv');
 reset(f,1);
 if ioresult<>0 then errorhandler('CT-VOICE.DRV',1);
 voc.driversize:=filesize(f);
 getmem(ptrtodriver,voc.driversize);
 if ptrtodriver=nil then
  begin
   voc.installed:=false;
   voc.errstat:=110;
   exit;
  end;
 blockread(f,ptrtodriver^,voc.driversize);
 if ioresult<>0 then errorhandler('CT-VOICE.DRV',5);
 close(f);
 if (typecasttype(ptrtodriver^)[3]<>'C') or
  (typecasttype(ptrtodriver^)[4]<>'T') then
  begin
   voc.installed:=false;
   voc.errstat:=120;
   exit;
  end;
 voc.getversion;
 vseg:=seg(statusword);
 vofs:=ofs(statusword);
 asm
  mov bx, 3
  call voc.ptrtodriver
  mov out, ax
  mov bx, 5
  mov es, vseg
  mov di, vofs
  call voc.ptrtodriver
 end;
 case out of
  1:voc.errstat:=400;
  2:voc.errstat:=410;
  3:voc.errstat:=420;
 end;
 if voc.errstat<>0 then
  begin
   voc.installed:=false;
   exit;
  end;
 voc.installed:=true;
 voc.oldexitproc:=exitproc;
 exitproc:=@voctype.vocexitproc;
end;

procedure voctype.deinstalldriver;
begin
 if voc.installed then
 asm
  mov bx, 9
  call voc.ptrtodriver
 end;
 freemem(voc.ptrtodriver,voc.driversize);
end;

procedure voctype.setspeaker(onoff: boolean);
var
 switch: byte;
begin
 switch:=ord(onoff) and $01;
 asm
  mov bx, 4
  mov al, switch
  call voc.ptrtodriver
 end;
end;

procedure voctype.output(bufferaddress: pointer);
var
 vseg,vofs: word;
begin
 if (not voc.installed) or (ship.options[3]=0) then exit;
 voc.setspeaker(true);
 vseg:=seg(bufferaddress^);
 vofs:=ofs(bufferaddress^)+voc.fileheaderlength;
 asm
  mov bx, 6
  mov es, vseg
  mov di, vofs
  call voc.ptrtodriver
 end;
end;

procedure voctype.outputloop(bufferaddress: pointer);
var
 vseg,vofs: word;
begin
 if (not voc.installed) or (ship.options[3]=0) then exit;
 vseg:=seg(bufferaddress^);
 vofs:=ofs(bufferaddress^)+voc.fileheaderlength;
 asm
  mov bx, 6
  mov es, vseg
  mov di, vofs
  call voc.ptrtodriver
 end;
end;

procedure voctype.stop;
begin
 asm
  mov bx, 8
  call voc.ptrtodriver
 end;
end;

procedure voctype.pause;
var
 switch: word;
begin
 voc.paused:=true;
 asm
  mov bx,10
  call voc.ptrtodriver
  mov switch, ax
 end;
 if switch=1 then
  begin
   voc.paused:=false;
   voc.errstat:=510;
  end;
end;

procedure voctype.continue;
var
 switch: word;
begin
 asm
  mov bx,11
  call voc.ptrtodriver
  mov switch, AX
 end;
 if switch=1 then
  begin
   voc.paused:=false;
   voc.errstat:=520;
  end;
end;

procedure voctype.breakloop(breakmode: word);
begin
 asm
  mov bx, 12
  mov ax, breakmode
  call voc.ptrtodriver
  mov breakmode, ax
 end;
 if breakmode=1 then voc.errstat:=500;
end;

constructor cachetype.initialize;
var j,i: integer;
begin
 cache.oldexitproc:=exitproc;
 exitproc:=@cachetype.cacheexitproc;
 cache.cacheindex:=0;
 for j:=0 to 10 do cache.handles[j]:=0;
 for j:=0 to 10 do
  begin
   ems.getmem(4);
   if ems.error<>0 then errorhandler(ems.getemserrmessage,4);
   for i:=0 to 3 do ems.setmapping(i,i);
   ems.savemap;
   cache.handles[j]:=ems.handle;
   cache.files[j]:=0;
  end;
 cache.index:=0;
end;

procedure cachetype.findfile(n: integer);
var j: integer;
begin
 j:=0;
 while (j<11) and (cache.files[j]<>n) do inc(j);
 if j=11 then loadfile(n)
  else
   cache.cacheindex:=j;
end;

procedure cachetype.loadfile(n: integer);
var temp: ^tempvoctype;
    vocfile: file;
    nums: string[3];
    j,total: word;
begin
 new(temp);
 ems.handle:=cache.handles[cache.index];
 ems.restoremap;
 str(n:3,nums);
 if n<100 then nums[1]:='0';
 if n<10 then nums[2]:='0';
 assign(vocfile,'SOUND\IS'+nums+'.VOC');
 reset(vocfile,1);
 total:=0;
 repeat
  blockread(vocfile,temp^,8000,j);
  move(temp^,ptr(ems.frame0,total)^,j);
  total:=total+j;
 until j<8000;
 if ioresult<>0 then errorhandler('SOUND\IS'+nums+'.VOC',1);
 close(vocfile);
 if ioresult<>0 then errorhandler('SOUND\IS'+nums+'.VOC',5);
 ems.savemap;
 cache.files[cache.index]:=n;
 cache.cacheindex:=cache.index;
 inc(cache.index);
 cache.index:=cache.index mod 11;
 dispose(temp);
end;

{$F+}
procedure cachetype.cacheexitproc;
{$F-}
var j: integer;
begin
 for j:=0 to 10 do
  if cache.handles[j]<>0 then
   begin
    ems.handle:=cache.handles[j];
    ems.restoremap;
    ems.freemem;
    cache.handles[j]:=0;
   end;
 exitproc:=cache.oldexitproc;
end;

begin
 vocptr:=ptr(ems.frame0,0);
 voc.initialize;
end.