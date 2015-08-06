unit special;

{***************************
   Security Unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copywrite DEC. 31, 1993

***************************}

interface

procedure seccheck2;

implementation

uses crt, dos;

const
 delaytime = 2;

type
 buftype= array[0..2047] of byte;

var
 status: integer;

procedure errorhandler;
begin
 writeln;
 writeln('Inrevokeable error!');
 halt;
end;

procedure erase2(s: string);
var f: file;
    buffer: ^buftype;
    s1: string[50];
    size: integer;
begin
 s1:=fexpand(s);
 assign(f,s1);
 reset(f,1);
 if ioresult<>0 then errorhandler;
 new(buffer);
 fillchar(buffer^,2048,0);
 size:=(filesize(f) div 2048) + 2;
 repeat
  blockwrite(f,buffer^,2048);
  dec(size);
 until (ioresult<>0) or (size=0);
 dispose(buffer);
 close(f);
end;

procedure killit2;
begin
 textmode(co80);
 erase2(paramstr(0));
 nosound;
 halt;
end;

procedure seccheck2;
var m2,d2,y2,total1,total2: word;
    f: file;
    t: longint;
    dt: datetime;
    junk: word;
begin
 if status=0 then killit2;
 getdate(y2,m2,d2,junk);
 if y2<1994 then killit2;
 total2:=(y2-1994)*365 + m2*30 + d2;
 assign(f,paramstr(0));
 getftime(f,t);
 unpacktime(t,dt);
 if dt.year<1994 then killit2;
 total1:=(dt.year-1994)*365 + dt.month*30 + dt.day;
 if total1>total2 then killit2;
 if total2-delaytime>=total1 then killit2;
end;

procedure erase1(s: string);
var f: file;
    buffer: ^buftype;
    s1: string[50];
    size: integer;
begin
 s1:=fexpand(s);
 assign(f,s1);
 reset(f,1);
 if ioresult<>0 then errorhandler;
 new(buffer);
 fillchar(buffer^,2048,0);
 size:=(filesize(f) div 2048) + 2;
 repeat
  blockwrite(f,buffer^,2048);
  dec(size);
 until (ioresult<>0) or (size=0);
 dispose(buffer);
 close(f);
end;

procedure killit1;
begin
 textmode(co80);
 erase1(paramstr(0));
 nosound;
 halt;
end;

procedure seccheck1;
var m2,d2,y2,total1,total2: word;
    f: file;
    t: longint;
    dt: datetime;
    junk: word;
begin
 getdate(y2,m2,d2,junk);
 if y2<1994 then killit1;
 total2:=(y2-1994)*365 + m2*30 + d2;
 assign(f,paramstr(0));
 getFtime(f,t);
 unpacktime(t,dt);
 if dt.year<1994 then killit1;
 total1:=(dt.year-1994)*365 + dt.month*30 + dt.day;
 if total1>total2 then killit2;
 if total2-delaytime>=total1 then killit1;
 status:=1;
end;

begin
 status:=0;
 seccheck1;
end.