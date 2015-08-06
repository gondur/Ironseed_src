(****************************************************************************

                                 EXAMPLE4.PAS
                                 ------------

                          (C) 1993 Jussi Lahdenniemi

Example program #4 for DSMI tutorial

****************************************************************************)

{$I dsmi.inc} ,crt;

var module : PModule;
    f      : file;
    sample : TSampleinfo;
    sc     : TSoundCard;

begin
  if initDSMI(44100,2048,0,@sc)<>0 then halt(1);   { Error }
  if sc.ID<>ID_GUS then mcpStartVoice else gusStartVoice;
  cdiSetupChannels(0,8,nil);
  module:=ampLoadmodule('\utility\music\sourcep\EXAMPLE.AMF',0);
  ampplaymodule(module,PM_LOOP);
  assign(f,'sound\i1a.sam');
  reset(f,1);
  sample.sample:=malloc(fileSize(f));
  if sample.sample=nil then halt(1);
  blockread(f,sample.sample^,filesize(f));
  with sample do
   begin
    length:=filesize(f);
    loopstart:=500;
    loopend:=9400;
    mode:=0;
    sampleID:=0;
   end;


  mcpconvertsample(sample.sample,sample.length);
  cdiDownloadSample(31,sample.sample,sample.sample,sample.length);
  ampPlayModule(module,PM_LOOP);
  cdiSetInstrument(6,@sample);
  cdiSetInstrument(7,@sample);
  cdiPlayNote(6,8368,64);
  cdiPlayNote(7,8368,64);
  readkey;
  ampStopModule;
end.
