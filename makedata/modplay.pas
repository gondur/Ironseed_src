unit modplay;

interface

var
 stat: integer;
 playing: boolean;

procedure moddevice(var device:integer);
procedure modsetup(var status:integer;device,mixspeed,pro,loop:integer;var str:string);
procedure modstop;
procedure modinit;
procedure modvolume(v1,v2,v3,v4:integer);
procedure playmod(s: string; loop: integer);
procedure fademusic;

implementation

uses crt, data;

{$L MOD-OBJ}
{$F+}
procedure moddevice(var device:integer); external ;
procedure modsetup(var status:integer;device,mixspeed,pro,loop:integer;var str:string); external ;
procedure modstop; external ;
procedure modinit; external;
procedure modvolume(v1,v2,v3,v4:integer); external ;
{$F-}

procedure playmod(s: string;loop: integer);
var f: file;
    smp: integer;
begin
 if ship.options[3]=0 then
  begin
   tslice:=ship.options[2];
   exit;
  end;
 assign(f,s);
 reset(f);
 if ioresult<>0 then errorhandler(s,1);
 close(f);
 modvolume(255,255,255,255);
 case ship.options[3] of
  1: smp:=8000;
  2: smp:=12000;
  3: smp:=18000;
 end;
 modsetup(stat,7,smp,0,loop,s);
 playing:=true;
end;

procedure fademusic;
var j: integer;
begin
 if not playing then exit;
 playing:=false;
 if ship.options[3]=0 then
  begin
   modstop;
   exit;
  end;
 for j:=255 downto 0 do
  begin
   modvolume(j,j,j,j);
   delay(tslice div 8);
  end;
 modstop;
end;

begin
{ modinit;}
end.