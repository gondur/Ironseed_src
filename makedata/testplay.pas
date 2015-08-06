program testsongplaying;

{$M 6000,200000,200000}


{$I dsmi.inc}, crt,modplay,data;

var j,i,t,vol,orgvol: integer;
    track: integer;
    hsample: pointer;
    sample: ^byte;
    pos: longint;
    textscreen: array[0..23,0..79] of integer absolute $B800:0000;
    voltable: array[0..31] of integer;
    ans: char;

procedure drawtracks;
begin
 for track:=0 to module^.channelcount+3 do
  begin
   orgvol:=cdigetvolume(track);
   if orgvol=0 then
    for j:=0 to 20 do textscreen[track,j]:=$082A
   else
    begin
     pos:=cdigetposition(track);
     hsample:=mcpGetsample(track);
     sample:=hsample;
     vol:=0;
     inc(sample,pos);
     for t:=0 to 79 do
      begin
       vol:=vol+abs(sample^);
       inc(sample);
      end;
     vol:=round(vol*orgvol/2000);
     if vol>0 then
      begin
       for j:=0 to vol do textscreen[track,j]:=$0F2A;
       if vol<20 then
        for j:=vol+1 to 20 do textscreen[track,j]:=$082A;
      end;
    end;
  end;
end;

procedure errorhandler(s: string);
begin
 textmode(co80);
 writeln;
 writeln(s);
 halt;
end;

{procedure soundeffect(n:integer; s: string);
var f: file;
    size: integer;
    si: tsampleinfo;
begin
 assign(f,s);
 reset(f,1);
 if ioresult<>0 then errorhandler('NO FILE!!!');
 size:=filesize(f);
 getmem(si.sample,size);
 blockread(f,si.sample^,size);
 if ioresult<>0 then errorhandler('WRONG SIZE!!!');
 close(f);

 with si do
  begin
   length:=size;
   loopstart:=0;
   loopend:=0;
   mode:=0;
   sampleid:=0;
  end;

 mcpconvertsample(si.sample,size);
 for j:=0 to 3 do
  begin
   if mcpsetsample(module^.channelcount+j,@si)<>0 then errorhandler('HUH? Sample.');
   if mcpplaysample(module^.channelcount+j,11900+j*10,64)<>0 then errorhandler('HUH? Playing.');
  end;
 freemem(si.sample,size);
end;
}


begin
 textmode(co80);

{ if initdsmi(22000,4096,MCP_QUALITY,@sc)<>0 then exit;
 module:=amploadmod('sound\combat.mod',LM_IML);
 if sc.id<>ID_GUS then mcpStartVoice else gusStartVoice;
 mcpclearbuffer;
 for i:=0 to 32 do voltable[i]:=2*i+1;
 cdiSetupChannels(0,module^.channelCount+4,@voltable);
 for j:=0 to module^.channelcount-1 do
  mcpSetVolume(j,64);
 for j:=0 to 3 do
  begin
   mcpsetvolume(module^.channelcount+j,64);
   cdisetpan(module^.channelcount+j,Pan_Surround);
  end;
 mcpclearbuffer;
 ampplaymodule(module,PM_Loop);
 clrscr;}

 ship.options[3]:=1;
 ship.options[9]:=64;
 ans:=' ';
 playmod(true,'\ironseed\sound\combat.mod');
{ cdisetpan(0,pan_middle);
 cdisetpan(1,pan_middle);}
 repeat
  drawtracks;
  if fastkeypressed then
   begin
    ans:=readkey;
    case upcase(ans) of
     'A': soundeffect('gun1.sam',0);
     'B': soundeffect('laser1.sam',7000);
     'C': soundeffect('laser2.sam',7000);
     'D': soundeffect('laser3.sam',7000);
     'E': soundeffect('laser4.sam',7000);
     'F': soundeffect('laser5.sam',7000);
     'G': soundeffect('laser6.sam',7000);
     'H': soundeffect('laser7.sam',7000);
     'I': soundeffect('explode2.sam',7000);
    end;
   end;
 until (ans=#27) or (ans=#13);

 ampstopmodule;
{ ampfreemodule(module); }
end.

