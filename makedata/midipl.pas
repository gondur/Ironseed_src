
{ ---------------------------------------

   Plays Format-0 Midi-Files
   using Soundblaster-Midi-Interface
   (Format-1-Midi-Files are played
   track-chunk by track-chunk)

  ---------------------------------------

   This program should only demonstrate
   how to write data to the Soundblaster-
   Midi-Interface.

  ---------------------------------------

   Eckhard Koch & Juergen Witte,
   MicroConsult, Oldenburg, Germany

   CompuServe-Adress:
     100037,313 (Eckhard Koch)

  -------------------------------------- }

program midiplay;
uses dos,crt;
const dsp_reset  = $226;    { The second digit could be from 1 to 6, }
      dsp_read   = $22A;    { e.g.  $216 to $226, $21A to $26A etc.  }
      dsp_write  = $22C;
      dsp_avail  = $22E;

      dsp_ready  = $AA;

var f:file of byte;
    cl:longint;

procedure sb_reset;
begin
  port[dsp_reset]:=1;
  delay(3);
  port[dsp_reset]:=0;
  while (port[dsp_avail] and $80)=0 do ;
  if port[dsp_read]<>dsp_ready then ;
end;

procedure write_midi(b:byte);
begin
  while (port[dsp_write] and $80)>0 do ;
  port[dsp_write]:=$38;
  while (port[dsp_write] and $80)>0 do ;
  port[dsp_write]:=b;
end;

{ Midi-Funktionen }
function ReadDeltatime : longint;
var i:array[1..4] of byte; count,n:byte; multi:word; result:longint;
begin
  count:=1;
  read(f,i[count]);
  while i[count]>$80 do begin
    inc(count);
    read(f,i[count]);
  end;
  multi:=1;
  if count>1 then
    for n:=2 to count do
      multi:=multi*$80;
  result:=0;
  n:=1;
  repeat
    result:=result+multi*(i[n] and $7F);
    inc(n);
    if n<=count then multi:=multi div $80;
  until n>count;
  cl:=cl+count;
  ReadDeltatime:=result;
end;

function ReadLength : longint;
var i:byte; sum:longint;
begin
  read(f,i);
  sum:=$1000000*i;
  read(f,i);
  sum:=sum+$10000*i;
  read(f,i);
  sum:=sum+$100*i;
  read(f,i);
  sum:=sum+i;
  ReadLength:=sum;
  cl:=cl+4;
end;

function ReadWord : word;
var i:byte; sum:longint;
begin
  read(f,i);
  sum:=$100*i;
  read(f,i);
  sum:=sum+i;
  ReadWord:=sum;
  cl:=cl+2;
end;

function ReadByte : byte;
var i:byte;
begin
  read(f,i);
  ReadByte:=i;
  cl:=cl+1;
end;

function ReadString(l:word) : string;
var s:string; i,n:byte;
begin
  s:='';
  for n:=1 to l do begin
    read(f,i);
    s:=s+chr(i);
  end;
  ReadString:=s;
end;

procedure SkipOver(l:longint);
var n:longint; i:byte;
begin
  if l>0 then for n:=1 to l do read(f,i);
  cl:=cl+l;
end;

const No_Midi = 'This is no standard-midi-file';

var i:byte;
    channel:byte; note:byte; deltatime:longint;

{ Data from Midi-Header (mthd) }

var HeaderLength:longint;
    format, trackchunks, division : word;
    ms_deltatime : word;
    tc : word;

{ Data from Midi-Chunk }

var ChunkLength,rl:longint;
    status,firstval,value:byte;
    midifile:string;

begin
  clrscr;
  writeln('Play Midi-Files',#13#10);
  write('Filename: ');
  readln(midifile);
  sb_reset;
  assign(f,midifile);
  reset(f);

  if ReadString(4)<>'MThd' then begin
    writeln(no_midi);
    close(f); exit;
  end;

  HeaderLength:=ReadLength;
  format:=ReadWord;
  trackchunks:=ReadWord;
  division:=ReadWord;

  ms_deltatime:=3;

  SkipOver(HeaderLength-6);


  for tc:=1 to TrackChunks do begin
    SkipOver(4);
    ChunkLength:=ReadLength;
    cl:=0;
    repeat
      deltatime:=ReadDeltatime;
      delay(deltatime*ms_deltatime);
      read(f,firstval); inc(cl);
      if firstval>=$F0 then
        status:=firstval
      else
       if firstval>=$80 then begin
         status:=firstval;
         read(f,firstval); inc(cl);
         write_midi(status);
       end;
      case status of
        $80..$9F: begin            { Note on/Note off }
          write_midi(firstval);
          read(f,value); inc(cl);
          write_midi(value);
        end;
        $A0..$BF: begin            { Key-Pressure und Parameter }
          write_midi(firstval);
          read(f,value); inc(cl);
          write_midi(value);
        end;
        $C0..$DF: begin            { Program und Channel }
          write_midi(firstval);
        end;
        $E0..$EF: begin            { Pitch Wheel }
          write_midi(firstval);
          read(f,value); inc(cl);
          write_midi(value);
        end;
        $F0: begin
          SkipOver(ReadByte);
        end;
        $F7: begin
          SkipOver(ReadByte);
        end;
        $FF: begin
          SkipOver(1);
          SkipOver(ReadByte);
        end;
      end;
    until cl=ChunkLength;
  end;

  close(f);

end.

