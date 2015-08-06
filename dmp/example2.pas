(****************************************************************************
                                 EXAMPLE2.PAS
                                 ------------

                          (C) 1993 Jussi Lahdenniemi

Tutorial example program #2 for DSMI

****************************************************************************)

{$I dsmi.inc} ,crt;

var si     : TSampleInfo;
    f      : file;
    sc     : TSoundCard;
    module : pmodule;
    j: integer;

begin
  if initDSMI(44100,4096,0,@sc)<>0 then halt(1);   { Error }
  module:=amploadmodule('\projects\spell\sound\klf_arca.s3m',LM_IML);
  cdiSetupChannels(0,module^.channelcount+3,nil);

  if sc.ID<>ID_GUS then mcpStartVoice else gusStartVoice;
  ampplaymodule(module,PM_LOOP);

  assign(f,'sound\i1a.sam');
  reset(f,1);
  writeln(#10#10);
  writeln('1 ',memavail);
  si.sample:=malloc(fileSize(f));
  writeln('2 ',memavail);
  if si.sample=nil then halt(1);
  blockread(f,si.sample^,filesize(f));
  with si do begin
    length:=filesize(f);
    loopstart:=0;
    loopend:=0;   { No looping }
    mode:=0;
    sampleID:=0;
  end;
  mcpconvertsample(si.sample,si.length);
  cdiDownloadSample(module^.channelcount+1,si.sample,si.sample,si.length);
  cdiSetInstrument(module^.channelcount+1,@si);
  cdiPlayNote(module^.channelcount+1,8000,64);   { Play at 8800 Hz }
  readkey;
  cdistopNote(module^.channelcount+1);

  writeln('5 ',memavail);
  cdidownloadsample(module^.channelcount+1,si.sample,si.sample,si.length);
  free(si.sample);

{  assign(f,'sfx\gun2.sam');
  reset(f,1);
  writeln('1 ',memavail);
  sample.sample:=malloc(fileSize(f));
  writeln('2 ',memavail);
  if sample.sample=nil then halt(1);
  blockread(f,sample.sample^,filesize(f));
  with sample do begin
    length:=filesize(f);
    loopstart:=0;
    loopend:=0;
    mode:=0;
    sampleID:=0;
  end;
  mcpconvertsample(sample.sample,sample.length);
  writeln('3 ',memavail);
  cdiDownloadSample(0,sample.sample,sample.sample,sample.length);
  writeln('4 ',memavail);
  cdiSetInstrument(0,@sample);
  cdiPlayNote(0,8800,64);
  readkey;
  cdistopNote(0); }

  writeln('6 ',memavail);
end.
