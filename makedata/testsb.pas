
program testsb;

{$M 64000,0,160000}

uses voctool,crt;
type
  buffertype= array[0..64000] of byte;

var
 vocfile: file of byte;
 buffer1,buffer2: ^buffertype;
 i,j,vseg,vofs: word;
 length: word;

procedure readsongin;
begin
 for j:=0 to 5 do read(vocfile,buffer1^[j]);
 writeln('Block type:',buffer1^[0]);
 if buffer1^[0]=0 then exit;
 length:=buffer1^[1]+buffer1^[2]*256;
 writeln('Block length:',length);
 writeln('Sample rate:',buffer1^[4]);
 buffer1^[4]:=80;
 writeln('Pack Byte:',buffer1^[5]);
 for j:=1 to length-2 do read(vocfile,buffer1^[j+5]);
 buffer1^[length+4]:=0;
 VSeg := Seg(Buffer1^);
 VOfs := Ofs(Buffer1^);
 ASM
  MOV       BX,6
  MOV       ES,VSeg
  MOV       DI,VOfs
 end;

 repeat
 until voc.statusword=0;
 writeln('------------------------------------');
 for j:=0 to 5 do read(vocfile,buffer2^[j]);
 writeln('Block type:',buffer2^[0]);
 if buffer2^[0]=0 then exit;
 length:=buffer2^[1]+buffer2^[2]*256;
 writeln('Block length:',length);
 writeln('Sample rate:',buffer2^[4]);
 buffer2^[4]:=80;
 writeln('Pack Byte:',buffer2^[5]);
 for j:=1 to length-2 do read(vocfile,buffer2^[j+5]);
 buffer2^[length+4]:=0;
 VSeg := Seg(Buffer2^);
 VOfs := Ofs(Buffer2^);
 ASM
  MOV       BX,6
  MOV       ES,VSeg
  MOV       DI,VOfs
 @@loopit:
  cmp voc.statusword, 0
  jne @@loopit
  CALL      VOC.PtrToDriver
 END;
 repeat
 until voc.statusword=0;
 writeln('------------------------------------');
end;

begin
 textmode(co80);
 new(buffer1);
 new(buffer2);
 assign(vocfile,'c:\apps\sbpro\vedit2\song.voc');
 reset(vocfile);
 clrscr;
 for j:=0 to 25 do
  begin
   read(vocfile,buffer1^[j]);
   write(chr(buffer1^[j]));
  end;
 writeln;
 writeln('------------------------------------');
 for j:=0 to 5 do read(vocfile,buffer2^[j]);
 writeln('Block type:',buffer2^[0]);
 length:=buffer2^[1]+buffer2^[2]*256;
 writeln('Block length:',length);
 writeln('Sample rate:',buffer2^[4]);
 writeln('Pack Byte:',buffer2^[5]);
 for j:=1 to length-2 do read(vocfile,buffer2^[j+5]);
 buffer2^[length+4]:=0;
 buffer2^[length+5]:=0;
 buffer2^[4]:=140;
 VOC.SetSpeaker(TRUE);
 VSeg := Seg(Buffer2^);
 VOfs := Ofs(Buffer2^);
 ASM
  MOV       BX,6
  MOV       ES,VSeg
  MOV       DI,VOfs
  CALL      VOC.PtrToDriver
 END;
 writeln('------------------------------------');
{ for j:=length+3 downto 6 do buffer1^[length+9-j]:=buffer2^[j];
 for j:=0 to 5 do buffer1^[j]:=buffer2^[j];
 buffer1^[length+4]:=0;
 buffer1^[length+5]:=0;
 writeln('Block type:',buffer1^[0]);
 writeln('Block length:',length);
 writeln('Sample rate:',buffer1^[4]);
 writeln('Pack Byte:',buffer1^[5]);
 repeat
 until vocstatusword=0;
 VSeg := Seg(Buffer1^);
 VOfs := Ofs(Buffer1^);
 ASM
  MOV       BX,6
  MOV       ES,VSeg
  MOV       DI,VOfs
  CALL      VOCPtrToDriver
 END;
 writeln('------------------------------------');
} repeat
  readsongin;
 until (buffer1^[0]=0) or (buffer2^[0]=0);
 close(vocfile);
 readkey;
 dispose(buffer1);
 dispose(buffer2);
end.
