{  ************************************************************************
   *
   *    File        : MTMLOAD.PAS
   *
   *    Description : Module loader for AMP
   *
   *    Copyright (C) 1993 Jussi Lahdenniemi
   *    Original C version (C) 1993 Otto Chrons
   *
   ************************************************************************ }

{$I+,R-,X+}

Unit MTMLoad;

{$O+}

interface
uses mcp,amp,loaders,csupport;

function loadMTM(var f:file;var module:PModule):longint;
function ampLoadMTM(name:string;options:longint):PModule;

implementation
{$IFDEF USE_EMS}
uses emhm;
{$ENDIF}

const BASIC_FREQ = 8368;

      instrRates : array[0..15] of word = ( 856,850,844,838,832,826,820,814,
                                            907,900,894,887,881,875,868,862 );

var curTrack:integer;
    patUsed:array[0..255] of byte;
    insc:byte;

type TMTMHeader         = Record
       ID               : array[0..2] of char;
       version          : byte;
       songname         : array[0..19] of char;
       trackCount       : word;
       patCount         : byte;
       orderCount       : byte;
       commentLength    : word;
       sampleCount      : byte;
       attribute        : byte;
       bpt              : byte;
       channelCount     : byte;
       pan              : array[0..31] of shortint;
     end;

     TMTMInstrument     = Record
       sampleName       : array[0..21] of char;
       sampleLength     : longint;
       loopStart,
       loopEnd          : longint;
       finetune         : byte;
       volume           : byte;
       attribute        : byte;
     end;

var mtmhdr:TMTMHeader;

Function loadInstruments(var f:file;module:PModule):integer;
var t,a:integer;
    b:word;
    mtmi:TMTMInstrument;
    instr:PInstrument;
begin
  blockread(f,mtmhdr,sizeof(TMTMHeader));
  move(mtmhdr.songname,module^.name,20);
  module^.name[20]:=#0;
  module^.channelCount:=mtmhdr.channelCount;
  for t:=0 to 31 do begin
    a:=mtmhdr.pan[t];
    if a in [7,8] then module^.channelPanning[t]:=0 else
      if a<7 then module^.channelPanning[t]:=(a-7)*9 else
        module^.channelPanning[t]:=(a-8)*9;
  end;
  insc:=mtmhdr.sampleCount;
  module^.instrumentCount:=insc;
  module^.instruments:=calloc(mtmhdr.sampleCount,sizeof(TInstrument));
  loadInstruments:=MERR_MEMORY;
  if module^.instruments=nil then exit;
  inc(module^.size,insc*sizeof(TInstrument));
  for t:=0 to mtmhdr.sampleCount-1 do begin
    blockread(f,mtmi,sizeof(TMTMInstrument));
    loadInstruments:=MERR_FILE;
    if ioresult<>0 then exit;
    instr:=@module^.instruments^[t];
    instr^.insType:=0;
    move(mtmi.sampleName,instr^.name,22);
    instr^.name[22]:=#0;
    instr^.sample:=nil;
    instr^.rate:=856*BASIC_FREQ div instrRates[MTMi.finetune and $f];
    if mtmi.volume>64 then instr^.volume:=64 else instr^.volume:=mtmi.volume;
    instr^.size:=mtmi.sampleLength;
    instr^.loopstart:=mtmi.loopStart;
    b:=mtmi.loopend;
    if b<3 then b:=0;
    instr^.loopend:=b;
    if instr^.loopend>instr^.size then instr^.loopend:=instr^.size;
    if instr^.loopstart>instr^.loopend then instr^.loopend:=0;
    if instr^.loopend=0 then instr^.loopstart:=0;
  end;
  loadInstruments:=MERR_NONE;
end;

Function loadPatterns(var f:file;module:PModule):integer;
type ta=array[0..0] of word;
var orders:array[0..127] of byte;
    ptr:pointer;
    a,t,i,count,lastPattern:integer;
    pat:PPattern;
    trackPtrs:^ta;
begin
  lastPattern:=0;
  blockread(f,orders,128);
  loadPatterns:=MERR_FILE;
  if IOresult<>0 then exit;
  count:=mtmhdr.orderCount+1;
  module^.patternCount:=count;
  module^.trackCount:=mtmhdr.trackCount;
  module^.patterns:=calloc(count,sizeof(TPattern));
  loadPatterns:=MERR_MEMORY;
  if module^.patterns=nil then exit;
  for t:=0 to module^.patternCount-1 do begin
    pat:=@module^.patterns^[t];
    for i:=0 to 31 do pat^.tracks[i]:=pointer(trackptrs^[orders[t]*32+i]);
  end;
  free(trackptrs);
  loadPatterns:=MERR_NONE;
end;

type ta=array[0..0] of byte;
     pa=^ta;

Function mtm2amf(buffer:pa;module:PModule):PTrack;
var track:PTrack;
    i,t,pos,tick,a,rowadd:integer;
    note,ins,volume,command,data,curins,curvolume:byte;
    nvalue:word;
    temptrack:array[0..575] of byte;

Procedure insertNote(a,b:integer);
Begin
  temptrack[pos*3]:=tick;
  temptrack[pos*3+1]:=a;
  temptrack[pos*3+2]:=b;
  inc(pos);
end;

Procedure insertCmd(a,b:integer);
Begin
  temptrack[pos*3]:=tick;
  temptrack[pos*3+1]:=a;
  temptrack[pos*3+2]:=b;
  inc(pos);
end;

begin
  pos:=0;
  tick:=0;
  ins:=0;
  curins:=$f0;
  fillchar(temptrack,576,$ff);
  for t:=0 to 63 do begin
    tick:=t;
    note:=$ff;
    nvalue:=buffer^[t*3] shr 2;
    if nvalue>0 then note:=nvalue+36;
    command:=buffer^[t*3+1] and $f;
    data:=buffer^[t*3+2];
    volume:=255;
    if command=$c then if data>64 then volume:=64 else volume:=data;
    ins:=((buffer^[t*3+1] and $f0) shr 4) or ((buffer^[t*3] and 3) shl 4);
    if ins<>0 then begin
      dec(ins);
      if ins<>curins then begin
        insertCmd(cmdInstr,ins);
        module^.instruments^[ins].insType:=1;
      end else begin
        if (note=$ff) and (volume>64) then begin
          insertCmd(cmdVolumeAbs,module^.instruments^[ins].volume);
          insertCmd(cmdOffset,0);
        end;
      end;
      curIns:=ins;
      inc(ins);
    end;
    if (command=$e) and ((data shr 4)=$d) and ((data and $f)<>0) and (note<>$ff) then begin
      insertCmd(cmdNoteDelay,data and $f);
      command:=$ff;
    end;
    if command=3 then begin
      insertCmd(cmdBenderTo,data);
      command:=$ff;
    end;
    if note<>$ff then begin
      dec(ins);
      if (ins<>$ff) and (command<>$c) then volume:=module^.instruments^[ins].volume;
      insertNote(note,volume);
    end else if volume<65 then insertCmd(cmdVolumeAbs,volume);
    case command of
      $f : if (data in [1..31]) and (loadOptions and LM_OLDTEMPO>0) then
             insertCmd(cmdTempo,data) else insertCmd(cmdExtTempo,data);
      $b : insertCmd(cmdGoto,data);
      $d : insertCmd(cmdBreak,0);
      $a : begin
             if data>=16 then data:=data div 16 else data:=-data;
             insertCmd(cmdVolume,data);
           end;
      2  : if data<>0 then begin
             if data>127 then data:=127;
             insertCmd(cmdBender,-data);
           end;
      1  : if data<>0 then begin
             if data>127 then data:=127;
             insertCmd(cmdBender,-data);
           end;
      4  : insertCmd(cmdVibrato,data);
      5  : begin
             if data>=16 then data:=data div 16 else data:=-data;
             insertCmd(cmdToneVol,data);
           end;
      6  : begin
             if data>=16 then data:=data div 16 else data:=-data;
             insertCmd(cmdVibrVol,data);
           end;
      7  : insertCmd(cmdTremolo,data);
      0  : if data<>0 then insertCmd(cmdArpeggio,data);
      9  : insertCmd(cmdOffset,data);
      8  : insertCmd(cmdPan,data-64);
      $e : begin
             i:=data shr 4;
             data:=data and $f;
             case i of
               9  : insertCmd(cmdRetrig,data);
               1  : insertCmd(cmdFinetune,-data);
               2  : insertCmd(cmdFinetune,data);
               $a : insertCmd(cmdFinevol,data);
               $b : insertCmd(cmdFinevol,-data);
               $c : insertCmd(cmdNoteCut,data);
               $d : insertCmd(cmdNoteDelay,data);
               8  : if data in [7,8] then insertCmd(cmdPan,0) else
                    if data<7 then insertCmd(cmdPan,(data-7)*9) else
                    insertCmd(cmdPan,(data-8)*9);
             end;
           end;
    end;
  end;
  if pos=0 then track:=nil else begin
    inc(pos);
    track:=malloc(pos*3+3);
    if track<>nil then begin
      inc(module^.size,pos*3+3);
      track^.size:=pos;
      track^.trkType:=0;
      move(temptrack,pointer(longint(track)+3)^,pos*3);
    end;
  end;
  mtm2amf:=track;
end;

Function loadTracks(var f:file;module:PModule):integer;
var count:byte;
    t,i,a,c:integer;
    buffer:array[0..191] of shortint;
begin
 count:=module^.trackCount;
 module^.tracks:=calloc(count+4,sizeof(PTrack));
 loadTracks:=MERR_MEMORY;
 if module^.tracks=nil then exit;
 inc(module^.size,(count+4)*sizeof(PTrack));
 module^.tracks^[0]:=nil;
 curTrack:=1;
 seek(f,sizeof(TMTMHeader)+mtmhdr.sampleCount*sizeof(TMTMInstrument)+128);
 for t:=0 to mtmhdr.trackCount-1 do
  begin
   blockread(f,buffer,192);
   module^.tracks^[curTrack]:=mtm2amf(@buffer,module);
  end;
 loadTracks:=MERR_NONE;
end;

Function loadSamples(var f:file; var module:PModule):integer;
Var t,i,a,b,l     : Word;
    c             : Longint;
    instr         : PInstrument;
    temp          : Array[0..31] of byte;
    {$IFDEF USE_EMS}
    handle        : TEMSH;
    {$ENDIF}
Begin
  seek(f,sizeof(TMTMHeader)+mtmhdr.sampleCount*sizeof(TMTMInstrument)+128+
    mtmhdr.trackCount*192+(mtmhdr.patCount+1)*32*2+mtmhdr.commentLength);
  for t:=0 to module^.instrumentCount-1 do begin
    instr:=@module^.instruments^[t];
    if ((loadOptions and LM_IML)>0) and (instr^.insType=0) then begin
      seek(f,filepos(f)+instr^.size);
      instr^.size:=0;
    end;
    if instr^.size>4 then begin
      a:=instr^.loopend-instr^.loopstart;
      if (instr^.loopend<>0) and (a<crit_size) then begin
        b:=(Crit_Size div a)*a;
        instr^.loopend:=instr^.loopstart+b;
        loadSamples:=MERR_MEMORY;
        instr^.sample:=malloc(instr^.loopend);
        if instr^.sample=nil then exit;
        inc(module^.size,instr^.loopend);
        if instr^.size>instr^.loopend then begin
          loadSamples:=MERR_FILE;
          blockread(f,instr^.sample^,instr^.loopend);
          if IOresult<>0 then exit;
          seek(f,filepos(f)+instr^.size-instr^.loopend);
        end else begin
          loadSamples:=MERR_FILE;
          blockread(f,instr^.sample^,instr^.size);
          if IOresult<>0 then exit;
        end;
        instr^.size:=instr^.loopend;
        for i:=1 to (Crit_Size div a)-1 do
          move(pointer(longint(instr^.sample)+instr^.loopstart)^,
               pointer(longint(instr^.sample)+instr^.loopstart+a*i)^,a);
      end else begin
        if instr^.size>65510 then a:=65510 else a:=instr^.size;
        instr^.sample:=malloc(a);
        loadSamples:=MERR_MEMORY;
        if instr^.sample=nil then exit;
        inc(module^.size,a);
        loadSamples:=MERR_CORRUPT;
        blockread(f,instr^.sample^,a);
        if IOresult<>0 then exit;
        if a<instr^.size then begin
          blockread(f,temp,instr^.size-a);
          instr^.size:=a;
        end;
{$IFDEF USE_EMS}
        handle:=0;
        if instr^.size>2048 then begin
          handle:=emsAlloc(instr^.size);
          if handle>0 then begin
            emsCopyTo(handle,instr^.sample,0,instr^.size);
            free(instr^.sample);
            instr^.sample:=ptr($ffff,handle);
          end;
        end;
{$ENDIF}
      end;
    end else begin
      instr^.size:=0;
      instr^.sample:=nil;
    end;
  end;
  loadSamples:=MERR_NONE;
end;

(*
              static int loadSamples(FILE *file, MODULE *module)
              {
                  ushort      t,i,a,b,l;
                  long        c;
                  INSTRUMENT  *instr;
                  char        temp[32];
              #ifdef _USE_EMS
                  EMSH        handle;
              #endif


                  fseek(file,sizeof(MTMHEADER)+MTMhdr.sampleCount*sizeof(MTMINSTRUMENT)+128+\
                             MTMhdr.trackCount*192+(MTMhdr.patCount+1)*32*2+MTMhdr.commentLength,SEEK_SET);
                  for( t = 0; t < module->instrumentCount; t++ )
                  {
                      instr = &(*module->instruments)[t];
                      if((loadOptions & LM_IML) && (instr->type == 0 ))
                      {
                          fseek(file,instr->size,SEEK_CUR);
                          instr->size = 0;
                          instr->sample = NULL;
                          continue;
                      }
                      if( instr->size > 4 )
                      {
                          if( instr->loopend != 0 && (a = instr->loopend - instr->loopstart) < CRIT_SIZE )
                          {
                              b = (CRIT_SIZE/a)*a;
                              instr->loopend = instr->loopstart + b;
                              if((instr->sample = malloc(instr->loopend+16)) == NULL) return MERR_MEMORY;
                              module->size += instr->loopend;
                              if( instr->size > instr->loopend )
                              {
                                  if(fread(instr->sample,instr->loopend,1,file) == 0) return MERR_FILE;
                                  fseek(file,instr->size - instr->loopend,SEEK_CUR);
                              }
                              else
                                  if(fread(instr->sample,instr->size,1,file) == 0) return MERR_FILE;
                              instr->size = instr->loopend;
                              for( i = 1; i < CRIT_SIZE/a; i++)
                              {
                                  memcpy((char*) (*instr->sample+instr->loopstart+a*i,\
                                         (char*) (*instr->sample+instr->loopstart,a);
                              }
                          }
                          else
                          {
                              a = (instr->size > 65510) ? 65510 : instr->size;
                              if((instr->sample = malloc(a+16)) == NULL) return MERR_MEMORY;
                              module->size += a;
                              memset(instr->sample,0,a+16);
                              if( fread(instr->sample,a,1,file ) == 0)
                              {
                                  return MERR_CORRUPT;
                              }
                              if( a < instr->size )
                              {
                                  fread(temp,instr->size - a,1,file);
                                  instr->size = a;
                              }
              #ifdef _USE_EMS
                              handle = 0;
                              if( instr->size > 2048 )
                              {
                                  if((handle = emsAlloc(instr->size+16)) > 0)
                                  {
                                      emsCopyTo(handle,instr->sample,0,instr->size);
                                      free(instr->sample);
                                      instr->sample = MK_FP(0xFFFF,handle);
                                  }
                              }
              #endif
                          }
                      }
                      else { instr->size = 0; instr->sample = 0; }
                  }
                  return MERR_NONE;
              }

*)

Procedure joinTracks2Patterns(var module:PModule);
Var t,i     : Word;
    pat     : PPattern;
Begin
  for t:=0 to module^.patternCount-1 do begin
    pat:=@module^.patterns^[t];
    for i:=0 to module^.channelCount-1 do
      pat^.tracks[i]:=module^.tracks^[word(pat^.tracks[i])];
  end;
end;

Function loadMTM;
var a:integer;
begin
  module^.tempo:=125;
  module^.speed:=6;
  a:=loadInstruments(f,module);
  loadMTM:=a;
  if a<MERR_NONE then exit;
  a:=loadPatterns(f,module);
  loadMTM:=a;
  if a<MERR_NONE then exit;
  a:=loadSamples(f,module);
  loadMTM:=a;
  if a<MERR_NONE then exit;
  a:=loadTracks(f,module);
  loadMTM:=a;
  if a<MERR_NONE then exit;
  joinTracks2Patterns(module);
  loadMTM:=a;
end;

Function ampLoadMTM;
var f: file;
    l: longint;
    module: PModule;
    b: integer;
    ID: string[3];
begin
  loadOptions:=options;
  module:=malloc(sizeof(TModule));
  if module=nil then begin
    moduleError:=MERR_MEMORY;
    ampLoadMTM:=nil;
    exit
  end;
  fillchar(module^,sizeof(TModule),0);
  assign(f,name);
  reset(f,1);
  if ioresult<>0 then begin
    moduleError:=MERR_FILE;
    ampLoadMTM:=nil;
    free(module);
    exit
  end;
  module^.modType:=MOD_NONE;
  blockread(f,id[1],3);
  id[0]:=#3;
  if id='MTM' then module^.modType:=MOD_MTM;
  if module^.modType=MOD_NONE then
   begin
    moduleError:=MERR_TYPE;
    ampLoadMTM:=nil;
    free(module);
    exit
   end;
  b:=loadMTM(f,module);
  moduleError:=b;
  if b=MERR_NONE then
   begin
    seek(f,0);
    module^.filesize:=filepos(f);
   end
  else
   begin
    ampFreeModule(module);
    free(module);
    module:=nil;
   end;
  close(f);
  ampLoadMTM:=module;
end;

end.
