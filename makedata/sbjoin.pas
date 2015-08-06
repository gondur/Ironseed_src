program testsb;

{$M 64000,0,220000}

uses crt, voctool;
type
  buffertype= array[0..64000] of byte;

var
 vocfile: file of byte;
 buffer1,buffer2: ^buffertype;
 j,vseg,vofs: word;
 length1,length2: word;
 i: integer;

procedure savebuf(num: byte);
begin
 if num=1 then
  begin
   assign(vocfile,paramstr(1));
   reset(vocfile);
   seek(vocfile,26);
   for j:=0 to length1+4 do write(vocfile,buffer1^[j]);
   close(vocfile);
  end;
 if num=2 then
  begin
   assign(vocfile,paramstr(1));
   reset(vocfile);
   seek(vocfile,26);
   for j:=0 to length2+4 do write(vocfile,buffer2^[j]);
   close(vocfile);
  end;
end;

procedure combine;
begin
 if length1>length2 then
  begin
   for j:=6 to length1 do
    begin
     i:=buffer1^[j]+buffer2^[j]-128;
     if i<0 then i:=0;
     if i>255 then i:=255;
     buffer1^[j]:=i;
    end;
    VSeg := Seg(Buffer1^);
    VOfs := Ofs(Buffer1^);
    ASM
     MOV       BX,6
     MOV       ES,VSeg
     MOV       DI,VOfs
     CALL      VOCPtrToDriver
    END;
    savebuf(1);
  end
 else
  begin
   for j:=6 to length2 do
    begin
     i:=buffer1^[j]+buffer2^[j]-128;
     if i<0 then i:=0;
     if i>255 then i:=255;
     buffer2^[j]:=i;
    end;
   VSeg := Seg(Buffer2^);
   VOfs := Ofs(Buffer2^);
   ASM
    MOV       BX,6
    MOV       ES,VSeg
    MOV       DI,VOfs
    CALL      VOCPtrToDriver
   END;
   savebuf(2);
  end;
end;

procedure combine2;
var length: longint;
    buffer3: ^buffertype;
    index: integer;
begin
 new(buffer3);
 for j:=0 to 5 do buffer3^[j]:=buffer1^[j];
 length:=length1+length2;
 buffer3^[2]:=length div 256;
 buffer3^[1]:=length mod 256;
 index:=6;
 buffer3^[length+4]:=0;
 buffer3^[4]:=round(buffer3^[4]*1.35);
 for j:=6 to length do
  if j mod 2=0 then buffer3^[j]:=buffer1^[index]
  else
   begin
    buffer3^[j]:=buffer2^[index];
    inc(index);
   end;
 VSeg := Seg(Buffer3^);
 VOfs := Ofs(Buffer3^);
 ASM
  MOV       BX,6
  MOV       ES,VSeg
  MOV       DI,VOfs
  CALL      VOCPtrToDriver
 END;
 dispose(buffer3);
end;

begin
 textmode(co80);
 new(buffer1);
 new(buffer2);
 for j:=0 to 64000 do buffer1^[j]:=128;
 for j:=0 to 64000 do buffer2^[j]:=128;
 assign(vocfile,paramstr(1));
 reset(vocfile);
 clrscr;
 for j:=0 to 25 do
  begin
   read(vocfile,buffer2^[j]);
   write(chr(buffer2^[j]));
  end;
 writeln;
 writeln('------------------------------------');
 for j:=0 to 5 do read(vocfile,buffer2^[j]);
 writeln('Block type:',buffer2^[0]);
 length1:=buffer2^[1]+buffer2^[2]*256;
 writeln('Block length:',length1);
 writeln('Sample rate:',buffer2^[4]);
 writeln('Pack Byte:',buffer2^[5]);
 for j:=1 to length1-2 do read(vocfile,buffer2^[j+5]);
 buffer2^[length1+4]:=0;
 buffer2^[length1+5]:=0;
 writeln('------------------------------------');
 close(vocfile);
 assign(vocfile,paramstr(2));
 reset(vocfile);
 for j:=0 to 25 do
  begin
   read(vocfile,buffer1^[j]);
   write(chr(buffer1^[j]));
  end;
 writeln;
 writeln('------------------------------------');
 for j:=0 to 5 do read(vocfile,buffer1^[j]);
 writeln('Block type:',buffer1^[0]);
 length2:=buffer1^[1]+buffer1^[2]*256;
 repeat until vocstatusword=0;
 writeln('Block length:',length2);
 writeln('Sample rate:',buffer1^[4]);
 writeln('Pack Byte:',buffer1^[5]);
 for j:=1 to length2-2 do read(vocfile,buffer1^[j+5]);
 buffer1^[length2+4]:=0;
 buffer1^[length2+5]:=0;
 writeln('------------------------------------');
 close(vocfile);
 combine2;
 repeat until vocstatusword=0;
 dispose(buffer1);
 dispose(buffer2);
end.
