Unit S3MLoad;

{$I-,R-,X+}

{$O+}

interface
Uses MCP,AMP,Loaders,CSupport;

Function loadS3M(var fl:file;modl:PModule):integer;

implementation
{$IFDEF USE_EMS}
uses emhm;
{$ENDIF}

Type TS3Mheader = Record
       name     : Array[0..27] of char;
       e,t      : byte;
       d1       : array[0..1] of byte;
       orders,
       ins,pats,
       flags,cwt,
       ffv      : word;
       magic    : array[0..3] of char;
       mv,is,
       it,mm    : byte;
       d2       : array[0..11] of char;
       channels : array[0..31] of byte;
     end;

     TS3Minst   = Record
       t        : byte;
       dosname  : array[0..12] of char;
       memseg   : word;
       length,loopstart,
       loopend  : longint;
       volume,dsk,pack,
       flag     : byte;
       c2spd,d1 : longint;
       d2,d3    : word;
       d4       : longint;
       name     : array[0..27] of char;
       magic    : longint;
     end;

var patUsed     : array[0..255] of byte;
    module      : PModule;
    f           : file;
    insPtr,
    patPtr      : array[0..255] of word;
    hdr         : TS3Mheader;
    lastChan    : integer;
    order16     : array[0..15] of byte;

Function loadHeader:Integer;
var orders     : array[0..255] of byte;
    ptr        : pointer;
    a,t,i,cnt  : integer;
    pat        : PPattern;
begin
  with module^ do begin
    cnt:=0;
    seek(f,0);
    blockread(f,hdr,sizeof(hdr));
    tempo:=hdr.it;
    speed:=hdr.is;
    instrumentCount:=hdr.ins;
    patternCount:=hdr.orders;
    cnt:=hdr.orders;
    channelCount:=0;
    for t:=0 to 15 do
      if hdr.channels[t]<>$ff then begin
        inc(channelCount);
{        module^.channelPanning[t]:=PAN_Left+byte(hdr.channels[t]>7)*(PAN_Right-PAN_Left);}
        if hdr.channels[t]>7 then module^.channelPanning[t]:=PAN_Right else
                                  module^.channelPanning[t]:=PAN_Left;
      end else module^.channelPanning[t]:=PAN_Middle;
    patterns:=calloc(cnt,sizeof(TPattern));
    if patterns=nil then begin
      loadHeader:=MERR_MEMORY;
      exit;
    end;
    blockread(f,orders,hdr.orders);
    blockread(f,insPtr,hdr.ins*2);
    blockread(f,patPtr,hdr.pats*2);
    inc(size,cnt*sizeof(TPattern));
    fillchar(patUsed,256,0);
    for t:=0 to cnt-1 do begin
      patUsed[orders[t]]:=1;
      pat:=addr(patterns^[t]);
      pat^.length:=64;
      for i:=0 to channelCount-1 do
        pat^.tracks[i]:=pointer(word(orders[t]<>$FF)*(word(orders[t])*word(channelCount)+1+i));
    end;
  end;
  loadHeader:=MERR_NONE;
end;

Function loadInstruments:integer;
var t,i,a,b    : Word;
    instr      : PInstrument;
    sins       : TS3Minst;
begin
  with module^ do begin
    instrumentCount:=hdr.ins;
    instruments:=calloc(hdr.ins,sizeof(TInstrument));
    if instruments=nil then begin
      loadInstruments:=MERR_MEMORY;
      exit;
    end;
    inc(size,hdr.ins*sizeof(TInstrument));
    for t:=0 to hdr.ins-1 do begin
      seek(f,longint(insPtr[t])*16);
      blockread(f,sins,sizeof(sins));
      if (sins.magic<>$53524353) and (sins.magic<>0) then begin
        loadInstruments:=MERR_TYPE;
        exit;
      end;
      instr:=addr(instruments^[t]);
      with instr^ do begin
        move(sins.name,name,sizeof(sins.name));
        move(sins.dosname,filename,sizeof(sins.dosname));
        rate:=sins.c2spd;
        volume:=sins.volume;
        size:=sins.length;
        loopstart:=sins.loopstart;
        loopend:=sins.loopend;
        if sins.flag and 1=0 then begin
          loopstart:=0;
          loopend:=0;
        end;
        sample:=pointer(sins.memseg);
      end;
    end;
  end;
  loadInstruments:=MERR_NONE;
end;

Function loadPatterns:integer;

type TArray                                       = Array[0..65519] of byte;
var pos,row,t,j,a,i,bufSize,chan,tick,curTrack    : integer;
    buffer                                        : ^TArray;
    c                                             : byte;
    patSize                                       : word;
    note,ins,volume,command,data,curins,curvolume : byte;
    nvalue,count,volsld                           : integer;
    track                                         : PTrack;
    temptrack                                     : Array[0..1199] of byte;

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

Label nopat;

begin
  bufSize:=1024;
  curTrack:=1;
  buffer:=malloc(bufSize);
  with module^ do begin
    count:=hdr.pats*channelCount;
    trackCount:=count;
    tracks:=calloc(count+4,sizeof(pointer));
    if tracks=nil then begin
      loadPatterns:=MERR_MEMORY;
      exit;
    end;
    inc(size,(count+4)*sizeof(pointer));
    for t:=0 to hdr.pats-1 do begin
      if patUsed[t]=0 then begin
        for j:=0 to channelCount-1 do tracks^[curTrack+j]:=nil;
        inc(curTrack,channelCount);
        goto nopat;
      end;
      seek(f,longint(patPtr[t])*16);
      blockread(f,patSize,2);
      if patSize>bufSize then begin
        bufSize:=patSize;
        free(buffer);
        buffer:=malloc(bufSize);
        if buffer=nil then begin
          loadPatterns:=MERR_MEMORY;
          exit;
        end;
      end;
      blockread(f,buffer^,patSize);
      if IOresult<>0 then begin
        loadPatterns:=MERR_FILE;
        exit;
      end;
      for j:=0 to channelCount-1 do begin
        fillchar(temptrack,800,$ff);
        pos:=0;
        ins:=0;
        curins:=$f0;
        i:=0;
        row:=0;
        volsld:=0;
        while row<64 do begin
          c:=buffer^[i];
          inc(i);
          tick:=row;
          if c=0 then inc(row) else begin
            a:=c and $1f;
            if a>lastChan then lastChan:=a;
            if (c and $1f)=j then begin
              note:=0;
              ins:=0;
              volume:=0;
              command:=0;
              data:=0;
              if c and $20>0 then begin
                note:=buffer^[i];
                inc(i);
                if note<>254 then
                  note:=(note shr 4)*12+(note and $f)+12;
                ins:=buffer^[i];
                inc(i);
              end;
              if c and $40>0 then begin volume:=buffer^[i]; inc(i) end;
              if c and $80>0 then begin
                command:=buffer^[i]+ord('A')-1; inc(i);
                data:=buffer^[i]; inc(i);
                if command=ord('G') then begin
                  if data>127 then data:=127;
                  insertCmd(cmdBenderTo,data);
                end;
              end;
              if (command=ord('S')) and ((data shr 4)=$d) and ((data and $f)<>0) and (note<>$ff) then
                insertCmd(cmdNoteDelay,data and $f);
              if c and $20>0 then begin
                if (ins<>0) and (ins<>curIns) and (ins<=hdr.ins) then begin
                  curins:=ins;
                  insertCmd(cmdInstr,ins-1);
                  instruments^[ins-1].insType:=1;
                end;
                if (c and $40=0) and (note<>0) and (note<>254) then
                  if ins=0 then insertNote(note,255) else
                    if ins<=hdr.ins then insertNote(note,instruments^[ins-1].volume);
                if (note=254) then insertNote(0,0);
              end;
              if c and $40>0 then
                if note=0 then insertCmd(cmdVolumeAbs,volume) else
                               insertNote(note,volume);
              if c and $80>0 then
                case chr(command) of
                  'A' : insertCmd(cmdTempo,data);
                  'B' : insertCmd(cmdGoto,data);
                  'C' : insertCmd(cmdBreak,0);
                  'D' : begin
                          if data>0 then volsld:=data else data:=volsld;
                          if (data and $f0)=$f0 then begin
                            if data=$f0 then data:=volsld;
                            insertCmd(cmdFinevol,-(data and $f));
                          end else
                          if (data and $f=$f) and (data>$f) then begin
                            if data=$f then data:=volsld;
                            insertCmd(cmdFineVol,data shr 4);
                          end else begin
                            if data>=16 then data:=data shr 4 else data:=-data;
                            insertCmd(cmdVolume,data);
                          end;
                        end;
                  'E' : begin
                          if data and $f0=$f0 then insertCmd(cmdExtraFineBender,data and $f) else
                          if data and $e0=$e0  then insertCmd(cmdExtraFineBender,data and $f) else begin
                            if data>127 then data:=127;
                            insertCmd(cmdBender,data);
                          end;
                        end;
                  'F' : begin
                          if data and $f0=$f0 then insertCmd(cmdFinetune,-(data and $f)) else
                          if data and $e0=$e0  then insertCmd(cmdExtraFineBender,-(data and $f)) else begin
                            if data>127 then data:=127;
                            if data=0 then insertCmd(cmdBender,-128) else
                              insertCmd(cmdBender,-data);
                          end;
                        end;
                  'H' : insertCmd(cmdVibrato,data);
                  'I',
                  'R' : insertCmd(cmdTremolo,data);
                  'J' : insertCmd(cmdArpeggio,data);
                  'K' : begin
                          if data>=16 then data:=data shr 4 else data:=-data;
                          if data>0 then volsld:=data else data:=volsld;
                          insertCmd(cmdToneVol,data);
                        end;
                  'L' : begin
                          if data>=16 then data:=data shr 4 else data:=-data;
                          if data>0 then volsld:=data else data:=volsld;
                          insertCmd(cmdVibrVol,data);
                        end;
                  'O' : insertCmd(cmdSync,data);
                  'T' : insertCmd(cmdExtTempo,data);
                  'Q' : insertCmd(cmdRetrig,data and $f);
                  'Z' : insertCmd(cmdSync,data);
                  'G' : ;
                  'S' : begin
                          a:=data shr 4;
                          data:=data and $f;
                          case a of
                            $c : insertCmd(cmdNoteCut,data);
                          end;
                        end;
                  '@' : ;
               {   else writeln('Command ',command,' data ',data,' ',j); }
                end;
            end else
              inc(i,((c and $20) shr 4)+((c and $c0) shr 6)); { skip note }
          end;
        end;
        if pos=0 then track:=nil else begin
          inc(pos);
          if (loadOptions and LM_IML)>0 then
            for i:=1 to curTrack-2 do
              if module^.tracks^[i]<>nil then
              if (module^.tracks^[i]^.size=pos) and
                 (memcmp(@temptrack,pointer(longint(module^.tracks^[i])+3),pos*3)=0) then begin
                   track:=tracks^[i];
                   pos:=0;
                   i:=curTrack-2;
                 end;
          if pos>0 then begin
            track:=PTrack(malloc(pos*3+3));
            if track<>nil then begin
              inc(module^.size,pos*3+3);
              track^.size:=pos;
              track^.trkType:=0;
              move(temptrack,pointer(longint(track)+3)^,pos*3);
            end else begin
              loadPatterns:=MERR_MEMORY;
              exit;
            end;
          end;
        end;
        tracks^[curTrack]:=track;
        inc(curTrack);
      end;
    nopat:
    end;
  end;
  free(buffer);
  loadPatterns:=MERR_NONE;
end;

Function loadSamples:integer;
Var t,i           : Word;
    instr         : Pinstrument;
    length,a,b    : Longint;
    sample        : Pointer;
    {$IFDEF USE_EMS}
    handle        : TEmsh;
    {$ENDIF}
Begin
  for t:=0 to hdr.ins-1 do begin
    instr:=@module^.instruments^[t];
    seek(f,longint(word(instr^.sample))*16);
    length:=instr^.size;
    if (instr^.size>0) and (instr^.insType=1) then begin
      a:=instr^.loopend-instr^.loopstart;
      if (instr^.loopend<>0) and (a<crit_size) then begin
        b:=(Crit_Size div a)*a;
        instr^.loopend:=instr^.loopstart+b;
        loadSamples:=-1;
        instr^.sample:=malloc(instr^.loopend+16);
        if instr^.sample=nil then exit;
        inc(module^.size,instr^.loopend);
        loadSamples:=-2;
        blockread(f,instr^.sample^,instr^.size);
        if IOresult<>0 then exit;
        instr^.size:=instr^.loopend;
        for i:=1 to (Crit_Size div a)-1 do
          move(pointer(longint(instr^.sample)+instr^.loopstart)^,
               pointer(longint(instr^.sample)+instr^.loopstart+a*i)^,a);
      end else begin
        instr^.sample:=malloc(instr^.size);
        loadSamples:=-1;
        if instr^.sample=nil then exit;
        inc(module^.size,instr^.size);
        loadSamples:=-2;
        blockread(f,instr^.sample^,instr^.size);
        if IOresult<>0 then exit;
{$IFDEF USE_EMS}
        handle:=0;
        if instr^.size>2048 then begin
          write(emsHeapFree,' - ');
          handle:=emsAlloc(instr^.size);
          writeln(instr^.size,' = ',emsHeapFree);
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

Procedure joinTracks2Patterns;
Var t,i     : Word;
    pat     : PPattern;
Begin
  for t:=0 to module^.patternCount-1 do begin
    pat:=@module^.patterns^[t];
    for i:=0 to module^.channelCount-1 do
      pat^.tracks[i]:=module^.tracks^[word(pat^.tracks[i])];
  end;
end;

Function loadS3M(var fl:file;modl:PModule):integer;
var a:integer;
begin
  move(fl,f,sizeof(f));
  module:=modl;
  module^.size:=0;
  lastChan:=0;
  a:=loadHeader; if a<MERR_NONE then begin loadS3M:=a; exit end;
  a:=loadInstruments; if a<MERR_NONE then begin loadS3M:=a; exit end;
  a:=loadPatterns; if a<MERR_NONE then begin loadS3M:=a; exit end;
  a:=loadSamples; if a<MERR_NONE then begin loadS3M:=a; exit end;
  joinTracks2Patterns;
  if module^.channelCount>lastChan+1 then module^.channelCount:=lastChan+1;
  loadS3M:=a;
end;

end.

MODULE far *ampLoadS3M(const char far *name, short options)
{
    FILE	*file;
    ulong	l;
    MODULE	*module;
    int		b;

    loadOptions = options;
    if((module = (MODULE*)malloc(sizeof(MODULE)))==NULL)
    {
	moduleError = MERR_MEMORY;
	return NULL;
    }
    memset(module,0,sizeof(MODULE));
    if((file = fopen(name,"rb")) == NULL)
    {
	moduleError = MERR_FILE;
	free(module);
	return NULL;
    }
    module->type = MOD_NONE;
    fseek(file,0x2C,SEEK_SET);
    fread(&l,4,1,file);
    if( l != 0x4D524353 ) // 'SCRM'
    {
	moduleError = MERR_TYPE;
	free(module);
	return NULL;
    }
    rewind(file);
    fread(module->name,28,1,file);
    module->name[28] = 0;
    moduleError = loadS3M(file,module);
    if( moduleError == MERR_NONE )
    {
	fseek(file,0,SEEK_END);
	module->filesize = ftell( file );
    }
    else
    {
	ampFreeModule(module);
	free(module);
	module = NULL;
    }
    fclose(file);
    return module;
}
