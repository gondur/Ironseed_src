program convertplanicons;
uses crt, data;

type
 weaponicontype= array[0..19,0..19] of byte;

var
 ft: file of smallbuffer;
 fw: file of weaponicontype;
 t: ^smallbuffer;
 s: pscreentype;
 w: ^weaponicontype;
 i,j,a: integer;

begin
 new(t);
 new(w);
 set256colors(colors);
 new(s);
 loadscreen('makedata\planicon',s);

 assign(ft,'data\planicon.dta');
 rewrite(ft);
 move(s^,t^,sizeof(smallbuffer));
 write(ft,t^);
 close(ft);

 assign(fw,'data\weapicon.dta');
 rewrite(fw);
 for a:=0 to 80 do
  begin
   for i:=0 to 19 do
    move(s^[i+10+(a div 15)*20,(a mod 15)*20],w^[i],20);
   write(fw,w^);
   for i:=0 to 19 do
    move(w^[i],screen[i],20);
  end;
 for a:=0 to 5 do
  begin
   for i:=0 to 19 do
    move(s^[i+110,a*20],w^[i],20);
   write(fw,w^);
   for i:=0 to 19 do
    move(w^[i],screen[i],20);
  end;
 for a:=0 to 2 do
  begin
   for i:=0 to 19 do
    move(s^[i+130,a*16],w^[i],20);
   write(fw,w^);
   for i:=0 to 19 do
    move(w^[i],screen[i],20);
  end;
 close(fw);
 dispose(s);
end.