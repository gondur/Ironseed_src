program getshipdata;

type
 alienshiptype=
  record
   relx,rely,relz,techlevel,skill,shield,battery,shieldlevel,hulldamage,
   maxhull,accelmax: integer;
   damages: array[1..7] of byte;
   gunnodes: array[1..10] of byte;
   charges: array[1..20] of byte;
  end;
var
 ft: text;
 temp: alienshiptype;
 i,j: integer;

begin
 assign(ft,'makedata\alienship.txt');
 reset(ft);
 readln(ft);
 readln(ft);
 for j:=1 to 88 do
  begin
   read(ft,i);
   temp.techlevel:=i;
   read(ft,i);
   temp.techlevel:=temp.techlevel*256+i;
   read(ft,temp.skill);
   read(ft,temp.shieldlevel);
   read(ft,temp.maxhull);
   temp.hulldamage:=temp.maxhull;
   read(ft,temp.accelmax);




  end;
 close(ft);
end.