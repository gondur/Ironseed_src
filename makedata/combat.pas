unit combat;

{$O+}

interface

type
 alientype=
  record
   name: string[15];
   techmin,techmax,anger,congeniality,victory,defeat,id: integer;
   war: boolean;
   front,side,long,short,back: integer;
  end;

procedure initiatecombat;
procedure createwandering(order: integer; alien: alientype);

implementation

uses crt, graph, data, gmouse, utils, display, journey, utils2;

const
 maxships = 5;
type
 alienshiparray= array[1..maxships] of alienshiptype;
var
 i,j,a,b,n,x2,y2,targetindex: integer;
 done: boolean;
 poweredup: array[1..10] of integer;
 ships: ^alienshiparray;

procedure createwandering(order: integer; alien: alientype);
var x,y: integer;
begin
 with ship.wandering do
  begin
   orders:=order;
   x:=hi(alien.techmin);
   y:=lo(alien.techmin);
   techlevel:=alien.techmin;
   if alien.defeat>alien.victory then
    begin
     i:=(alien.defeat-alien.victory) div 2;
     repeat
      inc(y);
      if y>9 then
       begin
        inc(x);
        y:=0;
        if x>6 then
         begin
          x:=6;
          y:=0;
         end;
       end;
      techlevel:=x*256+y;
      dec(i);
     until (i=0) or (techlevel=alien.techmax);
    end;
   congeniality:=abs(alien.congeniality+random(11)-5);
   anger:=abs(alien.anger+random(11)-5);
   alienid:=alien.id;
   case orders of
    0: begin
        relx:=3000+random(10000);
        if random(2)=1 then relx:=-relx;
        rely:=3000+random(10000);
        if random(2)=1 then rely:=-rely;
        relz:=3000+random(10000);
        if random(2)=1 then relz:=-relz;
       end;
    1: begin
        relx:=5000+random(12000);
        if random(2)=1 then relx:=-relx;
        rely:=5000+random(12000);
        if random(2)=1 then rely:=-rely;
        relz:=5000+random(12000);
        if random(2)=1 then relz:=-relz;
       end;
   end;
 end;
end;

procedure checkdamages;
begin
 mousehide;
 x:=round(ship.hulldamage*0.162);
 for i:=176 to 180 do
  begin
   fillchar(screen[i,25],x,i-96);
   if x<162 then
    fillchar(screen[i,25+x],162-x,0);
  end;
 x:=round((100-ship.damages[1])/2);
 for i:=152 to 156 do
  begin
   fillchar(screen[i,81],x,i-72);
   if x<50 then
    fillchar(screen[i,81+x],50-x,0);
  end;
 for j:=2 to 7 do
  begin
   a:=round((100-ship.damages[j])/2);
   x:=(j-2) mod 3;
   y:=(j-2) div 3;
   for i:=0 to 4 do
    begin
     fillchar(screen[i+y*8+160,x*68+13],a,i+80);
     if a<50 then
      fillchar(screen[i+y*8+160,x*68+13+a],50-a,i+64);
    end;
  end;
 mouseshow;
end;

procedure decpower;
begin
 if ship.shield>1501 then
  ship.battery:=ship.battery-round(weapons[ship.shield-1442].energy*ship.shieldlevel/100)+20;
 if ship.battery>32000 then ship.battery:=32000
 else if ship.battery<0 then
  begin
   tcolor:=88;
   printbigbox('COMPUTER:SECONDARY POWER FAILURE','SHIELDS POWERING DOWN...');
   ship.shieldlevel:=0;
   ship.battery:=0;
   tcolor:=95;
   for i:=192 to 196 do
    fillchar(screen[i,25],162,0);
  end;
 for j:=1 to n do
  with ships^[j] do
   begin
    battery:=battery-round(weapons[shield-1442].energy*shieldlevel/100)+regen;
    if battery>32000 then battery:=32000
     else if battery<0 then
     begin
      shieldlevel:=0;
      battery:=0;
      for i:=39 to 43 do
       fillchar(screen[i,26],162,0);
     end;
   end;
end;

procedure powerup;
begin
 mousehide;
 for j:=1 to 10 do
  if (poweredup[j]>-1) and (poweredup[j]<100) then
   begin
    inc(poweredup[j]);
    i:=round(poweredup[j]*0.31);
    if i<16 then setcolor(80+i) else setcolor(32+i);
    x:=((j-1) mod 5)*23+204;
    y:=((j-1) div 5)*23+153;
    rectangle(x,y,x+21,y+21);
   end;
 x:=round(ship.battery*0.00506);
 for i:=184 to 188 do
  begin
   fillchar(screen[i,25],x,i-104);
   if x<162 then
    fillchar(screen[i,25+x],162-x,0);
  end;
 if ship.battery>0 then
  begin
   if ship.shieldlevel<ship.shieldopt[3] then
    inc(ship.shieldlevel);
   x:=round(ship.shieldlevel*1.62);
   for i:=192 to 196 do
    begin
     fillchar(screen[i,25],x,i-112);
     if x<162 then
      fillchar(screen[i,25+x],162-x,0);
    end;
  end;
 for j:=1 to n do
  begin
   if (ships^[j].battery>0) then
    begin
     if ships^[j].shieldlevel<100 then inc(ships^[j].shieldlevel);
     x:=round(ships^[j].shieldlevel*1.62);
     for i:=39 to 43 do
      begin
       fillchar(screen[i,26],x,i+41);
       if x<162 then
        fillchar(screen[i,26+x],162-x,0);
      end;
    end;
   x:=round(ships^[j].battery*0.00194);
   for i:=31 to 34 do
    begin
     fillchar(screen[i,14],x,i+49);
     if x<62 then
      fillchar(screen[i,14+x],62-x,0);
    end;
  end;
 mouseshow;
end;

procedure moveships;
begin

 {***find targets here!!****}
 for j:=1 to n do
  with ships^[j] do
   begin
    tarx:=5;
    tary:=5;
    tarz:=5;
   end;

 for j:=1 to n do
  with ships^[j] do
   begin
    if relx>tarx then dec(relx)
     else if relx<tarx then inc(relx);
    if rely>tary then dec(rely)
     else if rely<tary then inc(rely);
    if relz>tarz then dec(relz)
     else if relz<tarz then inc(relz);
  end;
end;

procedure showships;
begin
 setcolor(8);
 setwritemode(xorput);
 mousehide;
 for j:=1 to n do
  begin
   x:=ships^[j].relx;
   y:=ships^[j].rely;
   z:=ships^[j].relz;
   if z=0 then x1:=0.01 else x1:=z;
   ar:=x/sin(arctan(x/x1));
   br:=ar/2;
   if x=0 then x1:=0.01 else x1:=x;
   t2:=arctan(z/(2*x1));
   x1:=105+(ar*cos(t1+t2))/10;
   y1:=102+(br*sin(t1+t2)+y)/14;
   x2:=round(x1);
   y2:=round(y1);
   moveto(x,y);
   x:=ships^[j].relx;
   y:=0;
   z:=ships^[j].relz;
   if z=0 then x1:=0.01 else x1:=z;
   ar:=x/sin(arctan(x/x1));
   br:=ar/2;
   if x=0 then x1:=0.01 else x1:=x;
   t2:=arctan(z/(2*x1));
   x1:=105+(ar*cos(t1+t2))/10;
   y1:=102+(br*sin(t1+t2)+y)/14;
   x:=round(x1);
   y:=round(y1);
   line(x,y,x2,y2);
   screen[y,x]:=screen[y,x] xor 39;
  end;
 mouseshow;
 setwritemode(copyput);
end;

procedure findmouse;
var button: boolean;
begin
 if mouse.getstatus(left) then button:=true else button:=false;
 if not button then exit;
 {**************}
end;

procedure processkey;
var ans: char;
begin
 ans:=readkey;
 case ans of
  #27: begin
        done:=true;
        bkcolor:=0;
       end;
 end;
end;

procedure mainloop;
var index: integer;
begin
 index:=0;
 showships;
 repeat
  findmouse;
  if fastkeypressed then processkey;
  inc(index);
  if index=8 then
   begin
    decpower;
    index:=0;
   end;
  powerup;
  showships;
  moveships;
  showships;
  delay(tslice*7);
 until done;
end;

procedure showweaponicon(x1,y1,weap,node: integer);
var j,i: integer;
begin
 readweaicon(weap-1);
 case node of
  1,2,6,7: begin
            for i:=0 to 9 do
             for j:=0 to 19 do
              screen[y1+j,x1+i]:=tempicon^[i,a+j];
            for i:=0 to 9 do
             for j:=0 to 19 do
              screen[y1+j,x1+i+10]:=tempicon^[i,a+j];
           end;
      3,4: begin
            for i:=0 to 19 do
             mymove(tempicon^[i,a],screen[y1+i,x1],5);
           end;
      8,9: begin
            for i:=0 to 19 do
             mymove(tempicon^[19-i,a],screen[y1+i,x1],5);
           end;
     5,10: begin
            for i:=0 to 9 do
             for j:=0 to 19 do
              screen[y1+j,x1+20-i]:=tempicon^[i,a+j];
            for i:=0 to 9 do
             for j:=0 to 19 do
              screen[y1+j,x1+10-i]:=tempicon^[i,a+j];
           end;

 end;
end;

procedure getshipinfo(n: integer);
var f: file of alienshiptype;
    i,j: integer;
begin
 assign(f,'data\ships.dta');
 reset(f);
 if ioresult<>0 then errorhandler('ships.dta',1);
 i:=lo(ship.wandering.techlevel);
 j:=hi(ship.wandering.techlevel);
 if j<4 then begin j:=4; i:=0; end;
 j:=j-4;
 seek(f,j+i);
 if ioresult<>0 then errorhandler('ships.dta'+chr(j+i+48),5);
 read(f,ships^[n]);
 if ioresult<>0 then errorhandler('ships.dta'+chr(j+i+48),5);
 close(f);
end;

procedure showtargetinfo;
var str1: string[5];
    t: longint;
begin
 t:=ships^[targetindex].maxhull*5;
 str(t:5,str1);
 printxy(70,18,str1+' KT');

 {*****************}

end;

procedure readyships;
var f: file of alientype;
    t: alientype;
begin
 n:=1;
 for j:=1 to n do
  with ships^[j] do
   begin
    getshipinfo(n);
    relx:=ship.wandering.relx-10+random(21);
    rely:=ship.wandering.rely-10+random(21);
    relz:=ship.wandering.relz-10+random(21);
    if (shield<1502) then shieldlevel:=100;
   end;
 assign(f,'save\contacts.dta');
 reset(f);
 if ioresult<>0 then errorhandler('contacts.dta',1);
 repeat
  read(f,t);
  if ioresult<>0 then errorhandler('contacts.dta',5);
 until t.id=ship.wandering.alienid;
 close(f);
 printxy(40,6,t.name);
end;

procedure readydata;
begin
 mousehide;
 savescreen;
 fading;
 loadscreen('data\war.vga');
 done:=false;
 new(ships);
 tcolor:=95;
 bkcolor:=0;
 oldt1:=t1;
 targetindex:=1;
 for j:=1 to 10 do poweredup[j]:=-1;
 for j:=1 to 10 do
  if checkloc(j) then
   begin
    case j of
      1,2,10: i:=j;
      3: i:=7;
      4: i:=3;
      5: i:=8;
      6: i:=4;
      7: i:=9;
      8: i:=6;
      9: i:=5;
    end;
    if ship.armed then poweredup[i]:=99 else poweredup[i]:=0;
    if ship.gunnodes[j]=0 then poweredup[i]:=-1
     else showweaponicon(((i-1) mod 5)*23+205,((i-1) div 5)*23+154,ship.gunnodes[j],i);
   end;
 checkdamages;
 readyships;
 showtargetinfo;
 powerup;
 fadein;
 mouseshow;
end;

procedure initiatecombat;
begin
 readydata;
 mainloop;
 dispose(ships);
 removedata;
end;

begin
end.