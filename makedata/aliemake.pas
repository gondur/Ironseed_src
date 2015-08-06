program makealiencontacts;

type
 alientype=
  record
   name: string[15];
   techmin,techmax,anger,congeniality,victory,id,conindex: integer;
   war: boolean;
  end;
var
 alien: alientype;
 i,j: integer;
 ft: text;
 f: file of alientype;

begin
 assign(f,'data\contact0.dta');
 rewrite(f);
 assign(ft,'makedata\contact.txt');
 reset(ft);
 readln(ft);
 for j:=1 to 11 do
  begin
   read(ft,alien.name);
   read(ft,i);
   alien.techmin:=i*256;
   read(ft,i);
   alien.techmin:=alien.techmin+i;
   read(ft,i);
   alien.techmax:=i*256;
   read(ft,i);
   alien.techmax:=alien.techmax+i;
   read(ft,alien.anger);
   read(ft,alien.congeniality);
   read(ft,alien.victory);
   read(ft,i);
   readln(ft,i);
   if i=0 then alien.war:=false else alien.war:=true;
   alien.id:=0;
   alien.conindex:=j;
   write(f,alien);
   writeln(alien.name);
  end;
 close(f);
 close(ft);
end.