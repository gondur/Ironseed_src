program convertchars;

uses data;

type
 crewtype=
  record
   name: string[20];
   phy,men,emo,status,level,index: byte;
   xp: longint;
  end;
 shiptype=
  record
   wandering: onealientype;
   crew: array[1..10] of crewtype;
   encodes: array[1..6] of crewtype;
   gunnodes: array[1..10] of byte;      {installation positions}
   armed: boolean;
   fuel,fuelmax,battery,hulldamage,cargomax,hullmax,
    accelmax,gunmax,shieldlevel,shield,posx,posy,posz,
    orbiting: integer;                  {kilograms, gigawatts}
   cargo: array[1..250] of integer;     {items => m3}
   numcargo: array[1..250] of integer;  {number of each item}
   engrteam: array[1..3] of teamtype;
   damages: array[1..7] of byte;        {0=none, 100=destroyed}
   shieldopt: array[1..3] of byte;
   options: array[1..6] of byte;
   research: byte;
   shiptype: array[1..3] of byte;
   events: array[0..200] of byte;
   stardate: array[1..5] of integer;    {month day year  hour minute}
  end;                                  {00    00  00    00   00    }
 crewtype2=
  record
   name: string[20];
   phy,men,emo,status,level,index,skill,perf,san: byte;
   xp: longint;
  end;
 shiptype2=
  record
   wandering: onealientype;
   crew: array[1..6] of crewtype2;
   encodes: array[1..6] of crewtype2;
   gunnodes: array[1..10] of byte;      {installation positions}
   armed: boolean;
   fuel,fuelmax,battery,hulldamage,cargomax,hullmax,
    accelmax,gunmax,shieldlevel,shield,posx,posy,posz,
    orbiting: integer;                  {kilograms, gigawatts}
   cargo: array[1..250] of integer;     {items => m3}
   numcargo: array[1..250] of integer;  {number of each item}
   engrteam: array[1..3] of teamtype;
   damages: array[1..7] of byte;        {0=none, 100=destroyed}
   shieldopt: array[1..3] of byte;
   options: array[1..6] of byte;
   research: byte;
   shiptype: array[1..3] of byte;
   events: array[0..200] of byte;
   stardate: array[1..5] of integer;    {month day year  hour minute}
  end;                                  {00    00  00    00   00    }

var
 shipfile: file of shiptype;
 shipfile2: file of shiptype2;
 systfile: file of systemarray;
 num,j: integer;
 ship: shiptype;
 ship2: shiptype2;

begin
 num:=4;
 assign(shipfile,'save'+chr(num+48)+'\ship.dta');
 reset(shipfile);
 if ioresult<>0 then errorhandler('ship.dta',1);
 read(shipfile,ship);
 if ioresult<>0 then errorhandler('ship.dta',5);
 close(shipfile);
 with ship2 do
  begin
   wandering:=ship.wandering;
   for j:=1 to 10 do gunnodes[j]:=ship.gunnodes[j];
   armed:=ship.armed;
   fuel:=ship.fuel;
   fuelmax:=ship.fuelmax;
   battery:=ship.battery;
   hulldamage:=ship.hulldamage;
   cargomax:=ship.cargomax;
   hullmax:=ship.hullmax;
   accelmax:=ship.accelmax;
   gunmax:=ship.gunmax;
   shieldlevel:=ship.shieldlevel;
   shield:=ship.shield;
   posx:=ship.posx;
   posy:=ship.posy;
   posz:=ship.posz;
   orbiting:=ship.orbiting;
   for j:=1 to 250 do cargo[j]:=ship.cargo[j];
   for j:=1 to 250 do numcargo[j]:=ship.numcargo[j];
   for j:=1 to 3 do engrteam[j]:=ship.engrteam[j];
   for j:=1 to 7 do damages[j]:=ship.damages[j];
   for j:=1 to 3 do shieldopt[j]:=ship.shieldopt[j];
   for j:=1 to 6 do options[j]:=ship.options[j];
   research:=ship.research;
   for j:=1 to 3 do shiptype[j]:=ship.shiptype[j];
   for j:=0 to 200 do events[j]:=ship.events[j];
   for j:=1 to 5 do stardate[j]:=ship.stardate[j];
   for j:=1 to 6 do
    with ship2.crew[j] do
     begin
      name:=ship.crew[j].name;
      phy:=ship.crew[j].phy;
      men:=ship.crew[j].men;
      emo:=ship.crew[j].emo;
      status:=ship.crew[j].status;
      level:=ship.crew[j].level;
      status:=ship.crew[j].status;
      xp:=ship.crew[j].xp;
      skill:=1;
      perf:=1;
      san:=1;
      index:=ship.crew[j].index;
      ship2.encodes[j]:=ship2.crew[j];
     end;
  end;
 assign(shipfile2,'save'+chr(num+48)+'\ship.dta');
 rewrite(shipfile2);
 if ioresult<>0 then errorhandler('ship.dta',1);
 write(shipfile2,ship2);
 if ioresult<>0 then errorhandler('ship.dta',5);
 close(shipfile2);
end.