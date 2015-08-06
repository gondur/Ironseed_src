(****************************************************************************

                                 EXAMPLE3.PAS
                                 ------------

                          (C) 1993 Jussi Lahdenniemi

Example program #3 for DSMI tutorial

****************************************************************************)

{$I dsmi.inc}, crt;

var module : PModule;
    sc     : TSoundCard;
    j,i: integer;
    track: ptrackdata;
    ctrack: ttrackdata;

procedure drawtracks;
begin
{ for j:=1 to module^.channelcount do
  begin}
   track:=ampgettrackdata(1);
   move(track^,ctrack,sizeof(ttrackdata));
   for i:=1 to ctrack.volume do write('*');
   if ctrack.volume<64 then
    for i:=ctrack.volume+1 to 64 do write(' ');
   write(#13);
   delay(15);
{  end; }
end;

begin
{  clrscr; }

{  emsinit(400,800); }

  if initDSMI(44100,2048,MCP_QUALITY,@sc)<>0 then exit;  { Error }
  module:=ampLoadMod('c:\ironseed\sound\psychic.mod',LM_IML);
  if sc.id<>ID_GUS then mcpStartVoice else gusStartVoice;
  cdiSetupChannels(0,module^.channelCount,nil);
  ampPlayModule(module,PM_Loop);   { Play looping }
  readkey;
{  repeat
   drawtracks;
  until keypressed; }
  ampStopModule;
  ampfreeModule(module);

end.

