UNIT MIDTool;
{* Unit for reading SMF info *}
INTERFACE
Uses Dos, Crt;
CONST
   MIDToolVersion = 'v1.0';
   MChunkH = 'MThd';
   MChunkT = 'MTrk';
TYPE
   ChunkName = ARRAY[0..3] OF CHAR;
   ChunkSize = ARRAY[0..3] OF BYTE;
   DeltaType = RECORD
                Data : ARRAY[0..3] OF BYTE;
                Count: BYTE;
                END;
{ Data type for all necessary chunk information }
   MIDChunkInfo = RECORD
             ckID   : ChunkName;
             ckSize : ChunkSize;
             END;
{ Data type  - all SMF header chunk data needed for typecast accesses }
   MIDChunkHeader = RECORD
             ckID   : ChunkName;
             ckSize : ChunkSize;
             Format : WORD;
             Tracks : WORD;
             Divis  : WORD;
             END;
{ MIDFiletype is the standard file type }
   MIDFileType = FILE;
VAR
   MIDErrStat  : WORD;
   MIDFormat   : WORD;
   MIDTracks   : WORD;
   MIDDivis    : WORD;
PROCEDURE PrintMIDErrMessage;
FUNCTION  MIDGetBuffer(VAR MIDBuffer:Pointer;
                           MIDFilename:String):BOOLEAN;
FUNCTION  MIDFreeBuffer (VAR MIDBuffer : Pointer):BOOLEAN;
FUNCTION  MIDCalcSize(MSize : ChunkSize): LongInt;
FUNCTION  MIDCalcDeltaValue(DeltaVal:DeltaType):LongInt;
PROCEDURE MIDIncrementPtr(VAR MIDBuffer : Pointer;
                              InternSize : LongInt);
PROCEDURE MIDSkipChunk(VAR MIDBuffer : Pointer);
PROCEDURE MIDReadDeltaValue(VAR MIDBuffer:Pointer;
                            VAR DVal:DeltaType);
PROCEDURE MIDScanMetaEvent(VAR MIDBuffer : Pointer);
PROCEDURE MIDScanMIDIEvent(VAR MIDBuffer : Pointer);
PROCEDURE MIDInterpretChunk(VAR MIDBuffer : Pointer);
FUNCTION  MIDBuildScript(MIDFilename : String; Flag : BYTE):BOOLEAN;

IMPLEMENTATION
VAR
   Regs        : Registers;
   MIDFileSize : LongInt;
   MIDGlobSize : LongInt;
   MIDLoclSize : LongInt;
   M           : Text;
PROCEDURE PrintMIDErrMessage;
{* INPUT    : None
 * OUTPUT   : None
 * PURPOSE  : Displays MID error text without changing error status. }
BEGIN
   CASE MIDErrStat OF
      200 : Write(' MID file not found ');
      210 : Write(' No memory free for MID file ');
      220 : Write(' File is not in MID format ');
      300 : Write(' Memory allocation error occurred ');
      END;
   END;
FUNCTION Exists (Filename : STRING):BOOLEAN;
{* INPUT    : Filename as string
 * OUTPUT   : TRUE, if file exists, otherwise FALSE
 * PURPOSE  : Checks whether a file already exists, returns a Boolean exp. }
VAR
   F : File;
BEGIN
   Assign(F,Filename);
{$I-}
   Reset(F);
   Close(F);
{$I+}
   Exists := (IoResult = 0) AND (Filename <> '');
   END;
PROCEDURE AllocateMem (VAR Pt : Pointer; Size : LongInt);
{* INPUT    : Buffer variable as pointer, buffer size as LongInt
 * OUTPUT   : Pointer to buffer in variable or NIL
 * PURPOSE  : Reserves as many bytes as specified by size and then
 *            places the pointer in the Pt variable. If not enough
 *            memory is available, then Pt points to NIL. }
VAR
   SizeIntern : WORD; { Size of buffer for internal calculation }
BEGIN
   Inc(Size,15);
   SizeIntern := (Size shr 4);
   Regs.AH := $48;
   Regs.BX := SizeIntern;
   MsDos(Regs);
   IF (Regs.BX <> SizeIntern) THEN Pt := NIL
   ELSE Pt := Ptr(Regs.AX,0);
   END;
FUNCTION  MIDGetBuffer(VAR MIDBuffer:Pointer;
                       MIDFilename:String):BOOLEAN;
{* INPUT    : Variable for buffer as pointer, filename as string
 * OUTPUT   : Pointer to buffer with MID data, TRUE/FALSE
 * PURPOSE  : Loads a file into memory and returns a value of TRUE
 *            if successfully loaded, otherwise returns FALSE. }
VAR
   FPresent   : BOOLEAN;
   MIDFile    : MIDFileType;
   Segs       : WORD;
   Read       : WORD;
BEGIN
   FPresent := Exists(MIDFilename);
{ MID file not found }
   IF Not(FPresent) THEN BEGIN
      MIDGetBuffer := FALSE;
      MIDErrStat   := 200;
      EXIT
      END;
   Assign(MIDFile,MIDFilename);
   Reset(MIDFile,1);
   MIDFileSize := Filesize(MIDFile);
   AllocateMem(MIDBuffer, MIDFileSize);
{ Not enough memory for MID file }
   IF (MIDBuffer = NIL) THEN BEGIN
      Close(MIDFile);
      MIDGetBuffer := FALSE;
      MIDErrStat   := 210;
      EXIT;
      END;
   Segs := 0;
   REPEAT
      Blockread(MIDFile,Ptr(Seg(MIDBuffer^)+4096*Segs,
                Ofs(MIDBuffer^))^,$FFFF,Read);
      Inc(Segs);
      UNTIL Read = 0;
   Close(MIDFile);
{ File not in MID format }
   IF ( MIDChunkInfo(MIDBuffer^).ckID <> MChunkH) THEN BEGIN
      MIDGetBuffer := FALSE;
      MIDErrStat := 220;
      EXIT;
      END;
{ Load successful }
   MIDGetBuffer := TRUE;
   MIDErrStat   := 0;
{ Read MIDI file type in global variable }
   MIDFormat := Swap(MIDChunkHeader(MIDBuffer^).Format);
{ Read number of tracks contained in global variable }
   MIDTracks := Swap(MIDChunkHeader(MIDBuffer^).Tracks);
{ Read division value in global variable }
   MIDDivis  := Swap(MIDChunkHeader(MIDBuffer^).Divis);
   END;
FUNCTION MIDFreeBuffer (VAR MIDBuffer : Pointer):BOOLEAN;
{* INPUT    : Pointer to buffer as pointer
 * OUTPUT   : None
 * PURPOSE  : Releases memory allocated by the MID data. }
BEGIN
   Regs.AH := $49;
   Regs.ES := seg(MIDBuffer^);
   MsDos(Regs);
   MIDFreeBuffer := TRUE;
   IF (Regs.AX = 7) OR (Regs.AX = 9) THEN BEGIN
      MIDFreeBuffer := FALSE;
      MIDErrStat := 300
      END;
   END;
FUNCTION MIDCalcSize(MSize : ChunkSize): LongInt;
{* INPUT    : 32 bit number as 4 byte array
 * OUTPUT   : Real 32 bit value as LongInt
 * PURPOSE  : Converts the reflected 32-bit value of the MID file
 *            to a real 32-bit LongInt value.}
VAR
   Power : REAL;
   Dummy : LongInt;
   Count : BYTE;
  BEGIN
   Dummy := 0;
   FOR Count := 3 DOWNTO 0 DO BEGIN
    Power := Exp(Count * Ln(256));
    Dummy := Dummy + (Trunc(Power)*MSize[3-Count]);
    END;
   MIDCalcSize := Dummy;
   END;
FUNCTION  MIDCalcDeltaValue(DeltaVal:DeltaType):LongInt;
{* INPUT    : DeltaVal as a record of DeltaType
 * OUTPUT   : Real Delta value as LongInt
 * PURPOSE  : Calculates the real value from the scanned Delta byte
 *            by masking the highest bit and then raising the values
 *            to corresponding higher values. This routine is used
 *            for determining Meta event sizes and DeltaTimes. }
VAR
   Power : REAL;
   Dummy : LongInt;
   Loop  : BYTE;
BEGIN
   Dummy := 0;
   WITH DeltaVal DO BEGIN
      FOR Loop := (Count-1) DOWNTO 0 DO BEGIN
       Power := Exp(Loop * Ln(128));
       Dummy := Dummy+(Trunc(Power)*(Data[(Count-1)-Loop] AND $7F));
       END;
      END;
   MIDCalcDeltaValue := Dummy;
   END;
PROCEDURE MIDIncrementPtr(VAR MIDBuffer : Pointer;
                              InternSize : LongInt);
{* INPUT    : Pointer variable to current position in the MID data
 *            as reference parameter, increment value as LongInt
 * OUTPUT   : None (new pointer from reference)
 * PURPOSE  : Increments the value of the passed pointer by the value
 *            InternSize. Increases beyond a segment limit are taken
 *            into account. }
VAR
  Segment    : WORD;
  Offset     : WORD;
  Offnew     : WORD;
  SegCount   : LongInt;
BEGIN
{ Negative increment not allowed }
  IF (InternSize < 0) THEN Exit;
  Segment := Seg(MIDBuffer^);
  Offset  := Ofs(MIDBuffer^);
{ How many segments must be incremented? }
  SegCount := (InternSize DIV $10000);
{ Calculate new offset address }
  Offnew  := Offset+InternSize;
{ Was the increment value smaller than a segment, but the results  }
{ still exceed the segment limit? Increment segment by 1.          }
  IF ((Offnew <= Offset) AND (SegCount = 0) AND (InternSize > 0))
  THEN SegCount := 1;
  INC(Segment, SegCount*$1000);
  MIDBuffer := Ptr(Segment,Offnew);
  INC(MIDGlobSize,InternSize);
  INC(MIDLoclSize,InternSize);
  END;
PROCEDURE MIDSkipChunk(VAR MIDBuffer : Pointer);
{* INPUT    : Pointer variable to current position in the MID data as
 *            reference parameter
 * OUTPUT   : None (new pointer from reference)
 * PURPOSE  : Skips the adjacent chunk with the help of the size
 *            information in the chunk itself. }
VAR
  InternSize : LongInt;
  Segment    : WORD;
  Offset     : WORD;
BEGIN
{ Determine the size of the data, and then add the 8 bytes for }
{ the ID bytes and the size bytes                              }
  InternSize := MIDCalcSize(MIDChunkInfo(MIDBuffer^).ckSize)+8;
  MIDIncrementPtr(MIDBuffer,InternSize);
  END;
PROCEDURE MIDReadDeltaValue(VAR MIDBuffer:Pointer; VAR DVal:DeltaType);
{* INPUT    : Pointer variable to current position in MID data as
 *            reference parameter, record for DeltaTime as reference
 * OUTPUT   : (new pointer from reference)
 *            (filled array in record from reference)
 *            (number of scanned Delta bytes in reference record)
 * PURPOSE  : Selects the size coded Delta values from the MID data
 *            and writes them to the passed array of the record. }
VAR
   ActData  : BYTE;
   ActDelta : BYTE;
BEGIN
{ Delete passed array, so that there are no longer any "false" }
{ byte scontained. This is only a cosmetic improvement.        }
   FOR ActDelta := 0 to 3 DO DVal.Data[ActDelta] := 0;
{ Set bit 7 }
   ActData  := 128;
   ActDelta := 0;
{ while bit 7 is set, read Delta bytes }
   WHILE ((ActData AND $80)=$80) DO BEGIN
      ActData := BYTE(MIDBuffer^);
      DVal.Data[ActDelta] := ActData;
      INC(ActDelta);
      MIDIncrementPtr(MIDBuffer,1);
      END;
   DVal.Count := ActDelta;
   END;
PROCEDURE MIDScanSysExEvent(VAR MIDBuffer : Pointer);
{* INPUT    : Pointer variable to current position in MID data
 *            as reference parameter
 * OUTPUT   : None (new pointer from reference)
 * PURPOSE  : If the passed pointer points to a SysEx event in the
 *            MID data in memory, then the message is displayed here,
 *            and the rest of the events are skipped. }
VAR
   DeltaTime : DeltaType;
   SysExSize : LongInt;
BEGIN
   WriteLn(M,'System Exclusive (');
   MIDIncrementPtr(MIDBuffer,1);
{ Determine size of the Meta event }
   MIDReadDeltaValue(MIDBuffer, DeltaTime);
   SysExSize := MIDCalcDeltaValue(DeltaTime);
   WriteLn(SysExSize,' Bytes)');
   MIDIncrementPtr(MIDBuffer, SysExSize);
   END;
PROCEDURE MIDScanMetaEvent(VAR MIDBuffer : Pointer);
{* INPUT    : Pointer variable to current position in the MID data
 *            as reference parameter
 * OUTPUT   : None (new pointer from reference)
 * PURPOSE  : If pointer passed points to Meta event in the MID data
 *            in memory, then the event is interpreted according to
 *            its data, and the appropriate text is displayed. }
TYPE
  Overhead = ARRAY[0..5] OF BYTE;
VAR
   ActEvent : BYTE;
   EventType: BYTE;
   DeltaVal: DeltaType;
   MetaSize : LongInt;
   MetaWord : WORD;
   MetaLong : LongInt;
   ActCount : LongInt;
BEGIN
   Write(M,'Meta event : ');
   ActEvent  := Overhead(MIDBuffer^)[0];
   EventType := Overhead(MIDBuffer^)[1];
   MIDIncrementPtr(MIDBuffer,2);
{ Determine size of Meta event }
   MIDReadDeltaValue(MIDBuffer, DeltaVal);
   MetaSize := MIDCalcDeltaValue(DeltaVal);
   CASE EventType OF
{ Event 0 - Sequence number }
   00 : BEGIN
         MetaWord := Swap(WORD(MIDBuffer^));
         WriteLn(M,'Sequence number : ',MetaWord);
         MIDIncrementPtr(MIDBuffer, MetaSize);
         END;
{ Event 1 - General text }
   01 : BEGIN
         Write(M,'Text : ');
         FOR ActCount := 0 TO (MetaSize-1) DO BEGIN
            Write(M,CHAR(MIDBuffer^));
            MIDIncrementPtr(MIDBuffer, 1);
            END;
         WriteLn(M);
         END;
{ Event 2 - Copyright text }
   02 : BEGIN
         Write(M,'Copyright : ');
         FOR ActCount := 0 TO (MetaSize-1) DO BEGIN
            Write(M,CHAR(MIDBuffer^));
            MIDIncrementPtr(MIDBuffer, 1);
            END;
         WriteLn(M);
         END;
{ Event 3 - Track name as text }
   03 : BEGIN
         Write(M,'Track Name : ');
         FOR ActCount := 0 TO (MetaSize-1) DO BEGIN
            Write(M,CHAR(MIDBuffer^));
            MIDIncrementPtr(MIDBuffer, 1);
            END;
         WriteLn(M);
         END;
{ Event 4 - Instrument name as text }
   04 : BEGIN
         Write(M,'Instrument : ');
         FOR ActCount := 0 TO (MetaSize-1) DO BEGIN
            Write(M,CHAR(MIDBuffer^));
            MIDIncrementPtr(MIDBuffer, 1);
            END;
         WriteLn(M);
         END;
{ Event 5 - Song text }
   05 : BEGIN
         Write(M,'Lyric : ');
         FOR ActCount := 0 TO (MetaSize-1) DO BEGIN
            Write(M,CHAR(MIDBuffer^));
            MIDIncrementPtr(MIDBuffer, 1);
            END;
         WriteLn(M);
         END;
{ Event 6 - Marker value }
   06 : BEGIN
         Write(M,'Marker : ');
         FOR ActCount := 0 TO (MetaSize-1) DO BEGIN
            Write(M,CHAR(MIDBuffer^));
            MIDIncrementPtr(MIDBuffer, 1);
            END;
         WriteLn(M);
         END;
{ Event 7 - Cue Point for video / film }
   07 : BEGIN
         Write(M,'Cue Point : ');
         FOR ActCount := 0 TO (MetaSize-1) DO BEGIN
            Write(M,CHAR(MIDBuffer^));
            MIDIncrementPtr(MIDBuffer, 1);
            END;
         WriteLn(M);
         END;
{ Events 8-15 - not yet allocated, but reserved }
   08, 09, 10, 11, 12, 13, 14, 15
       : BEGIN
          WriteLn(M,'Reserved but unallocated.');
          MIDIncrementPtr(MIDBuffer, MetaSize);
          END;
{ Event 33 - Channel selector ID }
   31  : BEGIN
          Write(M,'Channel Prefix Data ');
          WriteLn(M,BYTE(MIDBuffer^));
          MIDIncrementPtr(MIDBuffer, 1);
          END;
{ Event 47 - Display end of track }
   47  : BEGIN
          WriteLn(M,'End of Track');
          END;
{ Event 81 - Microsecond per quarter note for MIDI clock }
   81  : BEGIN
          Write(M,'Set Tempo ');
          MetaLong := 65536 * Overhead(MIDBuffer^)[0];
          INC(MetaLong,256 * Overhead(MIDBuffer^)[1]);
          INC(MetaLong,Overhead(MIDBuffer^)[2]);
          WriteLn(M,MetaLong,' Microsecs. per quarter note');
          MIDIncrementPtr(MIDBuffer, 3);
          END;
{ Event 84 - SMPTE parameters }
   84  : BEGIN
          Write(M,'SMPTE Offset ');
          Write(M,Overhead(MIDBuffer^)[0],'hr ');
          Write(M,Overhead(MIDBuffer^)[1],'min ');
          Write(M,Overhead(MIDBuffer^)[2],'sec ');
          Write(M,Overhead(MIDBuffer^)[3],'Frames ');
          WriteLn(M,Overhead(MIDBuffer^)[4],' 1/100 frames');
          MIDIncrementPtr(MIDBuffer, 5);
          END;
{ Event 88 - Parameters for MIDI clock }
   88  : BEGIN
          WriteLn(M,'Time Signature ');
          WriteLn(M,'             Numerator   : ',Overhead(MIDBuffer^)[0]);
          WriteLn(M,'             Denominator : ',Overhead(MIDBuffer^)[1]);
          WriteLn(M,'             MIDI Clocks : ',Overhead(MIDBuffer^)[2]);
          WriteLn(M,'             32/4  : ',Overhead(MIDBuffer^)[3]);
          MIDIncrementPtr(MIDBuffer, 4);
          END;
{ Event 127 - Parameters for MIDI clock }
  127  : BEGIN
          Write(M,'Sequencer Specific - ');
          WriteLn(M,'Format Unknown');
          MIDIncrementPtr(MIDBuffer, MetaSize);
          END
{ Event unknown - will not be interpreted }
   ELSE BEGIN
       WriteLn(M,'Event Unknown');
       MIDIncrementPtr(MIDBuffer, MetaSize);
       END;
      END;
   END;
PROCEDURE MIDScanMIDIEvent(VAR MIDBuffer : Pointer);
{* INPUT    : Pointer variable to current position in the MID data
 *            as reference parameter
 * OUTPUT   : None (new pointer from reference)
 * PURPOSE  : If pointer passed points to MIDI event in the MID data
 *            in memory, then the event is interpreted according to
 *            its data and an appropriate text is displayed. }
TYPE
   Overhead = ARRAY[0..5] OF BYTE; { Type for necessary typecast }
VAR
   ActEvent : BYTE;  { Contains number of current MIDI event }
   ActData  : BYTE;
BEGIN
   Write(M,'(MIDI) ');
   ActEvent := Overhead(MIDBuffer^)[0];
{ Note Off event for all 16 channels }
   IF (ActEvent IN [128..128+15]) THEN BEGIN
      Write(M,'Note Off       : ');
      Write(M,'Pitch = ',Overhead(MIDBuffer^)[1]:3,',  ');
      WriteLn(M,'Volume = ',Overhead(MIDBuffer^)[2]);
      MIDIncrementPtr(MIDBuffer,3);
      Exit;
      END;
{ Note On event for all 16 channels }
   IF (ActEvent IN [144..144+15]) THEN BEGIN
      Write(M,'Note On        : ');
      Write(M,'Pitch = ',Overhead(MIDBuffer^)[1]:3,',  ');
      WriteLn(M,'Volume = ',Overhead(MIDBuffer^)[2]);
      MIDIncrementPtr(MIDBuffer,3);
      Exit;
      END;
{ Aftertouch event for all 16 channels }
   IF (ActEvent IN [160..160+15]) THEN BEGIN
      Write(M,'Aftertouch     : ');
      Write(M,'Pitch = ',Overhead(MIDBuffer^)[1]:3,',  ');
      WriteLn(M,'Volume ',Overhead(MIDBuffer^)[2]);
      MIDIncrementPtr(MIDBuffer,3);
      Exit;
      END;
{ Control change event for all 16 channels }
   IF (ActEvent IN [176..176+15]) THEN BEGIN
      Write(M,'Control change : ');
      Write(M,'Number ',Overhead(MIDBuffer^)[1]:3,',  ');
      WriteLn(M,'Value   ',Overhead(MIDBuffer^)[2]);
      MIDIncrementPtr(MIDBuffer,3);
      Exit;
      END;
{ Program change event for all 16 channels }
   IF (ActEvent IN [192..192+15]) THEN BEGIN
      Write(M,'Program change : ');
      WriteLn(M,'Number ',Overhead(MIDBuffer^)[1]:3);
      MIDIncrementPtr(MIDBuffer,2);
      Exit;
      END;
{ Aftertouch event for all 16 channels }
   IF (ActEvent IN [208..208+15]) THEN BEGIN
      Write(M,'Aftertouch     : ');
      WriteLn(M,'Volume ',Overhead(MIDBuffer^)[1]);
      MIDIncrementPtr(MIDBuffer,2);
      Exit;
      END;
{ Pitch bend event for all 16 channels }
   IF (ActEvent IN [224..224+15]) THEN BEGIN
      Write(M,'Pitch Bender   : ');
      Write(M,'Low Byte ',Overhead(MIDBuffer^)[1]:3,',  ');
      WriteLn(M,'High Byte ',Overhead(MIDBuffer^)[2]);
      MIDIncrementPtr(MIDBuffer,3);
      Exit;
      END;
   END;
PROCEDURE MIDInterpretChunk(VAR MIDBuffer : Pointer);
{* INPUT    : Pointer variable to current position in the MID data
 *            as Reference parameter
 * OUTPUT   : None (new pointer from reference)
 * PURPOSE  : Scans chunk data and checks for known chunk IDs. When a
 *            header chunk is found, header data is displayed. When a
 *            track chunk is found, the data are interpreted by the
 *            function above for the different events. }
VAR
   ActSize  : LongInt;
   ActChunk : Chunkname;
   ActData  : BYTE;
   ActTime  : LongInt;
   DeltaVal : DeltaType;
   SizeCount: LongInt;
   SaveStart: Pointer;
BEGIN
   SizeCount:= 0;
   ActData  := 0;
{ Determine the type of the chunk }
   ActChunk := MIDChunkInfo(MIDBuffer^).ckID;
{ Determine the size of the chunk }
   ActSize  := MIDCalcSize(MIDChunkInfo(MIDBuffer^).ckSize);
{ Header chunk has been found }
   IF (ActChunk = MChunkH) THEN BEGIN
      WriteLn(M,'========================================================');
      WriteLn(M,'MIDI header chunk');
      Write(M,'Chunk type    : ',(MIDChunkInfo(MIDBuffer^).ckID));
      WriteLn(M,'(',ActSize,' Bytes)');
      WriteLn(M,'MIDI file type : ', MIDFormat:1);
      WriteLn(M,'Track number  : ', MIDTracks);
      MIDSkipChunk(MIDBuffer);
      END
   ELSE
{ Track chunk has been found }
   IF (ActChunk = MChunkT) THEN BEGIN
      WriteLn(M,'========================================================');
      WriteLn(M,'MIDI track chunk');
      Write(M,'Chunk type  : ',(MIDChunkInfo(MIDBuffer^).ckID));
      WriteLn(M,'(',ActSize,' Bytes)');
      WriteLn(M,'--------------------------------------------------------');
      MIDIncrementPtr(MIDBuffer,SizeOf(MIDChunkInfo));
      SaveStart := MIDBuffer;
{ New chunk has been started, so set MIDLoclSize to 0 }
      MIDLoclSize := 0;
      WHILE (MIDLoclSize < ActSize) DO BEGIN
{ Read DeltaTime of event }
         MIDReadDeltaValue(MIDBuffer, DeltaVal);
         ActTime  := MIDCalcDeltaValue(DeltaVal);
{ What kind of event is it ? }
         ActData  := BYTE(MIDBuffer^);
{ It is a MIDI event }
         IF (ActData IN [$80..$EF]) THEN BEGIN
            Write(M,'Delta = ',ActTime:7,'-> ');
            MIDScanMIDIEvent(MIDBuffer);
            END;
{ It is a Meta event }
         IF (ActData = $FF) THEN MIDScanMetaEvent(MIDBuffer);
{ It is a System Exclusive event }
         IF (ActData IN [$F0, $F7]) THEN MIDScanSysExEvent(MIDBuffer);
         END;
      END
{ No chunk recognized }
   ELSE
    MIDSkipChunk(MIDBuffer);
   END;
FUNCTION MIDBuildScript(MIDFilename : String; Flag : BYTE):BOOLEAN;
{* INPUT    : Filename of desired MIDI file as string
 * OUTPUT   : None
 * PURPOSE  : Creates script file in SMF format from MIDI file, in
 *            which the events are broken down into details. }
VAR
   MIDBuffer : Pointer; { Variable for MID data in memory    }
   MIDIntern : Pointer; { Copy of variable above for processing }
   Check     : BOOLEAN;
   WorkStr   : String;
BEGIN
   IF (Flag = 1) THEN BEGIN
      IF (Pos('.',MIDFileName) > 0) THEN
         WorkStr := Copy(MIDFileName,1,Pos('.',MIDFileName)-1);
      Assign(M,WorkStr+'.TXT');
      END
   ELSE AssignCrt(M);
   ReWrite(M);
   MIDBuildScript := FALSE;
{ Read MID file into memory }
   Check := MIDGetBuffer(MIDBuffer, MIDFilename);
{ If error occurred and file was already in memory, release memory }
   IF (Check = FALSE) THEN BEGIN
      IF (MIDErrStat = 220) THEN Check := MIDFreeBuffer(MIDBuffer);
      Exit;
      END;
{ Display header }
   WriteLn(M,'MIDSCRIPT  -  A MIDI File Scripter');
   WriteLn(M,'----------------------------------');
   WriteLn(M,'Name of MIDI file  : ', MIDFilename);
   WriteLn(M,'File size in bytes : ', MIDFileSize);
   WriteLn(M);
{ Initialize global variable }
   MIDGlobSize := 0;
{ Make copy of pointer variable }
   MIDIntern := MIDBuffer;
{ Until end of data has been reached, continue taking data }
{ from memory and interpret it according to SMF standards. }
   REPEAT
      MIDInterpretChunk(MIDIntern);
      WriteLn('   ',(MIDGlobSize*100/MIDFileSize):3:2,'%  finished');
      Gotoxy(1, WhereY-1);
      UNTIL (MIDGlobSize >= MIDFileSize);
   WriteLn;
{ Finished working, free memory }
   Check := MIDFreeBuffer(MIDBuffer);
   Close(M);
   IF (Check = TRUE) THEN MIDBuildScript := TRUE;
   END;

BEGIN
   MIDErrStat := 0;
   END.
