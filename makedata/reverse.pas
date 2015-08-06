program testsb;

{$M 64000,0,160000}

uses voctool,crt,graph;
type
  buffertype= array[0..64000] of byte;

var
 vocfile: file of byte;
 buffer1,buffer2: ^buffertype;
 i,j,vseg,vofs: word;
 length: word;

begin
 closegraph;
 new(buffer1);
 new(buffer2);
 assign(vocfile,paramstr(1));
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
 VOCSetSpeaker(TRUE);
 VSeg := Seg(Buffer2^);
 VOfs := Ofs(Buffer2^);
 ASM
  MOV       BX,6
  MOV       ES,VSeg
  MOV       DI,VOfs
  CALL      VOCPtrToDriver
 END;
 writeln('------------------------------------');
 for j:=length+3 downto 6 do buffer1^[length+9-j]:=buffer2^[j];
 for j:=0 to 5 do buffer1^[j]:=buffer2^[j];
 buffer1^[length+4]:=0;
 repeat until vocstatusword=0;
 VSeg := Seg(Buffer1^);
 VOfs := Ofs(Buffer1^);
 ASM
  MOV       BX,6
  MOV       ES,VSeg
  MOV       DI,VOfs
  CALL      VOCPtrToDriver
 END;
 repeat until vocstatusword=0;
 reset(vocfile);
 seek(vocfile,26);
 for j:=0 to length+4 do write(vocfile,buffer1^[j]);
 close(vocfile);

 dispose(buffer1);
 dispose(buffer2);
end.
