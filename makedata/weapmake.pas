program generateweapondata;

uses crt;

type
 weapontype=
  record
   damage,energy: integer;
   cents: array[1..4] of byte;
   range: longint;
  end;
var
 weapons: weapontype;
 f: file of weapontype;
 ft: text;
 index,j: integer;
 c: char;
 dummy: string[20];

begin
 assign(f,'\ironseed\data\weapon.dta');
 rewrite(f);
 assign(ft,'\ironseed\makedata\weapon.txt');
 reset(ft);
 readln(ft);
 read(ft,index);
 repeat
  for j:=1 to 12 do read(ft,c);
  read(ft,dummy);
{  read(ft,weapons.name);
  for j:=1 to 20 do weapons.name[j]:=upcase(weapons.name[j]);}
  read(ft,weapons.energy);
  read(ft,weapons.damage);
  for j:=1 to 4 do read(ft,weapons.cents[j]);
  readln(ft,weapons.range);
  read(ft,index);
  write(f,weapons);
  writeln(dummy,'/',weapons.energy,'/',weapons.damage,'/',weapons.cents[1],'/',weapons.cents[2],
   '/',weapons.cents[3],'/',weapons.cents[4],':',weapons.range);
 until index=0;
 close(f);
 close(ft);
end.