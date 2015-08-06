unit combat;

{***************************
   Battle/Combat unit for IronSeed

   Channel 7
   Destiny: Virtual


   (C) DEC. 31, 1993

***************************}

{$O+}

interface

procedure initiatecombat;

implementation

uses crt, graph, data, gmouse, utils, display, journey, utils2, saveload, weird, usecode;

const
 maxships = 15;
 shipclass : array[0..14] of string[14] =
  ('SHUTTLE       ','SCOUT         ','FIGHTER       ','ASSULT SCOUT  ',
   'PATROL CRAFT  ','CORVETTE      ','FRIGATE       ','LT. DESTROYER ',
   'HV. DESTROYER ','LT. CRUISER   ','HV. CRUISER   ','BATTLE CRUISER',
   'FLAGSHIP      ','BATTLESHIP    ','DREADNAUGHT   ');
type
 alienshiparray= array[1..maxships] of alienshiptype;
 statpictype= array[0..1,0..11] of byte;
 alienshipdisplay= array[140..193,201..314] of byte;
 barpictype= array[0..3,0..3] of byte;
 shieldpictype= array[0..6,0..3] of byte;
var
 oldshddmg,i,j,a,b,nships,targetindex,fireweapon: integer;
 range: longint;
 done,scanning,weapondisplay,autofire,engaging: boolean;
 poweredup: array[1..10] of integer;
 ships: ^alienshiparray;
 statpic,blank: ^statpictype;
 stats: array[1..3] of byte;
 part,r: real;
 asdisplay: ^alienshipdisplay;
 str1: string[10];
 barpic: ^barpictype;
 bar: array[1..4] of byte;
 shieldpic,shieldpic2: ^shieldpictype;

procedure displaystats;
var i: integer;
begin
 mousehide;
 part:=102/ship.hullmax*ship.hulldamage;
 if round(part)<>stats[1] then
  begin
   for i:=0 to 1 do
    move(blank^[i],screen[111-stats[1]+i,267],10);
   stats[1]:=round(part);
   y:=111-round(part);
   for i:=0 to 1 do
    move(statpic^[i],screen[y+i,267],10);
   end;
 part:=102/32000*ship.battery;
 if round(part)<>stats[2] then
  begin
   for i:=0 to 1 do
    move(blank^[i],screen[111-stats[2]+i,283],10);
   stats[2]:=round(part);
   y:=111-round(part);
   for i:=0 to 1 do
    move(statpic^[i],screen[y+i,283],10);
  end;
 part:=102/100*ship.shieldlevel;
 if round(part)<>stats[3] then
  begin
   for i:=0 to 1 do
    move(blank^[i],screen[111-stats[3]+i,299],10);
   stats[3]:=round(part);
   y:=111-round(part);
   for i:=0 to 1 do
    move(statpic^[i],screen[y+i,299],10);
  end;
 mouseshow;
end;

procedure displayshieldpic(n: integer);
begin
 mousehide;
 part:=102/100*ship.shieldopt[3];
 for i:=0 to 6 do
  fillchar(screen[108-round(part)+i,310],4,0);
 if n>100-ship.damages[2] then n:=100-ship.damages[2];
 ship.shieldopt[3]:=n;
 part:=102/100*ship.shieldopt[3];
 for i:=0 to 6 do
  mymove(shieldpic^[i],screen[108-round(part)+i,310],1);
 mouseshow;
end;

procedure displaytargetinfo2;
var str1: string[6];
begin
 with ships^[targetindex] do
  begin
   tcolor:=26;
   bkcolor:=0;
   printxy(252,141,chr(hi(techlevel)+48)+
    '.'+chr(lo(techlevel)+48));
   i:=270000 div accelmax;
   str(i,str1);
   printxy(223,187,str1);
   for i:=1 to 7 do
    begin
     b:=round((100-damages[i])/100*38);
     fillchar(screen[i*5+149,204],b,44);
     fillchar(screen[i*5+150,204],b,45);
     if b<38 then
      begin
       fillchar(screen[i*5+149,205+b],38-b,0);
       fillchar(screen[i*5+150,205+b],38-b,0);
      end;
    end;
  end;
end;

procedure givedamage(n,d: integer);
var j: integer;
begin
 d:=round(d/100*(100-ship.damages[3]));
 with ships^[targetindex] do
  begin
   case n of
    1: inc(damages[5],d);
    2: dec(hulldamage,d);
    3: dec(hulldamage,d div 2);
    4: case random(8) of
        0: inc(damages[1],d);
        1: inc(damages[2],d);
        2: inc(damages[3],d);
        3: inc(damages[4],d);
        4: inc(damages[6],d);
        5: inc(damages[7],d);
        6,7: dec(hulldamage,d);
       end;
    5: inc(damages[2],d);
   end;
   if hulldamage<0 then hulldamage:=0;
   for j:=1 to 7 do if damages[j]>100 then damages[j]:=100;
   if shieldlevel<0 then shieldlevel:=0;
   if shield=1501 then shieldlevel:=damages[2];
   if damages[5]=100 then hulldamage:=0;
  end;
end;

procedure displaymap; forward;

procedure firingweapon(n: integer);
var j,i,a,b,c,d: integer;
begin
 if skillcheck(4) then
  begin
   c:=ship.gunnodes[n];
   b:=ships^[targetindex].shield-1442;
   for j:=1 to 4 do if weapons[c].dmgtypes[j]>0 then
    begin
     i:=round(weapons[c].dmgtypes[j]/100*weapons[c].damage*5);
     if ships^[targetindex].shieldlevel=0 then givedamage(j,i)
     else
      begin
       a:=round(weapons[b].dmgtypes[j]/100*weapons[b].damage*ships^[targetindex].shieldlevel/100);
       if a<i then
        begin
         givedamage(j,i-a);
         ships^[targetindex].shieldlevel:=1;
         if ships^[targetindex].shield=1501 then ships^[targetindex].damages[2]:=100;
        end
       else
        begin
         part:=i/ships^[targetindex].shieldlevel;
         part:=part*(1/weapons[b].damage);
         part:=part*100;
         a:=round(part*100);
         d:=ships^[targetindex].shieldlevel-a;
         if d<0 then
          begin
           givedamage(5,random(4)+1);
           if ships^[targetindex].shield=1501 then
            ships^[targetindex].damages[2]:=100;
           ships^[targetindex].shieldlevel:=1;
          end
         else
          begin
           ships^[targetindex].shieldlevel:=d;
           if ships^[targetindex].shield=1501 then
            ships^[targetindex].damages[2]:=100-d;
          end;
        end;
      end;
    end;
  end;
 if ships^[targetindex].hulldamage=0 then
  begin
   ships^[targetindex].hulldamage:=1;
   displaymap;
   ships^[targetindex].hulldamage:=0;
   y:=round(ships^[targetindex].rely/range*26.66);
   x:=round(ships^[targetindex].relx/range*80);
   z:=round(ships^[targetindex].relz/range*40);
   if (abs(x)<80) and (abs(y)<40) and (abs(z)<40) then
    begin
     if z<0 then
      for i:=y+70 to y+70-z do
       screen[i,x+160]:=screen[i,x+160] xor 6
     else
      for i:=y+70 downto y+70-z do
       screen[i,x+160]:=screen[i,x+160] xor 6;
     screen[y+70,x+160]:=screen[y+70,x+160] xor 85;
     screen[y+70-z,x+160]:=screen[y+70-z,x+160] xor 31;
    end;
   targetindex:=1;
   while (targetindex<=nships) and (ships^[targetindex].hulldamage=0) do inc(targetindex);
   if targetindex>nships then done:=true;
   displaymap;
  end;
 poweredup[n]:=0;
 fireweapon:=0;
 if not weapondisplay then displaytargetinfo2;
end;

procedure powerup;
begin
 mousehide;
 for j:=1 to 10 do
  if (poweredup[j]>-1) and (poweredup[j]<100) then
   begin
    if (poweredup[j]=0) and (ship.battery>=weapons[ship.gunnodes[j]].energy) then
     begin
      dec(ship.battery,weapons[ship.gunnodes[j]].energy);
      poweredup[j]:=1;
     end
    else if poweredup[j]>0 then inc(poweredup[j]);
    if weapondisplay then
     begin
      i:=round(poweredup[j]*0.31);
      if i<16 then setcolor(80+i) else setcolor(32+i);
      x:=((j-1) mod 5)*22+203;
      y:=((j-1) div 5)*25+144;
      rectangle(x,y,x+21,y+21);
     end;
   end
  else if poweredup[j]=100 then
    begin
     part:=weapons[ship.gunnodes[j]].range;
     if part>=r then setcolor(47) else setcolor(63);
     if weapondisplay then
      begin
       x:=((j-1) mod 5)*22+203;
       y:=((j-1) div 5)*25+144;
       rectangle(x,y,x+21,y+21);
      end;
     if (part>=r) and ((autofire) or (fireweapon=j)) then firingweapon(j);
   end;
 mouseshow;
 if (ship.battery>0) and (ship.shieldlevel<ship.shieldopt[3]) then inc(ship.shieldlevel)
  else if (ship.battery=0) and (ship.shieldlevel>0) then dec(ship.shieldlevel)
  else if (Ship.shieldlevel>ship.shieldopt[3]) then dec(ship.shieldlevel);
 for j:=1 to nships do
  with ships^[j] do
   begin
    if shield>1501 then
     begin
      if (battery>0) and (shieldlevel<(100-damages[2])) then inc(shieldlevel)
       else if (battery=0) and (shieldlevel>0) then dec(shieldlevel)
       else if shieldlevel>(100-damages[2]) then dec(shieldlevel);
     end;
    for i:=1 to 20 do
     if charges[i]<100 then
      begin
       if (charges[i]=0) and (battery>=weapons[1].energy) then
        begin
         dec(battery,weapons[1].energy);
         charges[i]:=1;
        end
       else if charges[i]>0 then inc(charges[i]);
     end;
   end;
end;

procedure showweaponicon(x1,y1,weap,node: integer);
var j,i: integer;
begin
 if weap=0 then
  begin
   for i:=0 to 19 do
    fillchar(screen[y1+i,x1],20,3);
   exit;
  end;
 readweaicon(weap-1);
 case node of
  1,2,3,8: for i:=0 to 19 do
            for j:=0 to 19 do
             screen[y1+j,x1+i]:=tempicon^[i,j];
  4,6: for i:=0 to 19 do
        mymove(tempicon^[i],screen[y1+i,x1],5);
  5,7: for i:=0 to 19 do
        mymove(tempicon^[19-i],screen[y1+i,x1],5);
  9,10: for i:=0 to 19 do
         for j:=0 to 19 do
          screen[y1+j,x1+20-i]:=tempicon^[i,j];
 end;
end;

procedure displayweapons;
begin
 weapondisplay:=true;
 mousehide;
 for i:=140 to 193 do
  fillchar(screen[i,201],114,0);
 for j:=1 to 10 do
   begin
    x:=((j-1) mod 5)*22+203;
    y:=((j-1) div 5)*25+144;
    showweaponicon(x+1,y+1,ship.gunnodes[j],j);
    if ship.gunnodes[j]>0 then
     begin
      a:=round(poweredup[j]*0.31);
      if a<16 then setcolor(80+a) else setcolor(32+a);
      rectangle(x,y,x+21,y+21);
     end;
   end;
 mouseshow;
end;

procedure displaydamage;
var a,b,i: integer;
begin
 mousehide;
 for a:=1 to 7 do
  begin
   b:=round((100-ship.damages[a])/100*51);
   fillchar(screen[a*9+63,7],b,44);
   fillchar(screen[a*9+64,7],b,45);
   if b<50 then
    begin
     fillchar(screen[a*9+63,8+b],50-b,0);
     fillchar(screen[a*9+64,8+b],50-b,0);
    end;
  end;
 if 100-ship.damages[2]<ship.shieldopt[3] then displayshieldpic(100-ship.damages[2]);
 part:=108-(102/100*(100-ship.damages[2]));
 if round(part)<>oldshddmg then
  begin
   for i:=0 to 6 do
    fillchar(screen[oldshddmg+i,294],4,0);
   for i:=0 to 6 do
    mymove(shieldpic2^[i],screen[round(part)+i,294],1);
   oldshddmg:=round(part);
  end;
 mouseshow;
end;

procedure suckpower;
begin
 if ship.shield>1501 then
  ship.battery:=ship.battery-round(weapons[ship.shield-1442].energy*ship.shieldlevel/100);
 ship.battery:=ship.battery+round((100-ship.damages[1])/4);
 if ship.battery<0 then ship.battery:=0
  else if ship.battery>32000 then ship.battery:=32000;
 for j:=1 to nships do if ships^[j].hulldamage>0 then
  with ships^[j] do
   begin
    if shield>1501 then dec(battery,round(weapons[shield-1442].energy*shieldlevel/100));
    inc(battery,round(regen*(100-damages[1])/100));
    if battery<0 then battery:=0
     else if battery>32000 then battery:=32000;
   end;
end;

procedure displaytargetinfo;
var b: integer;
begin
 mousehide;
 with ships^[targetindex] do
  begin
   r:=sqr(relx/10);
   r:=r+sqr(rely/10);
   r:=r+sqr(relz/10);
   r:=sqrt(r)*100;
   str(r:10:3,str1);
   tcolor:=60;
   printxy(32,158,str1+' KM');
   tcolor:=95;
   b:=ships^[targetindex].maxhull;
   if b<1000 then b:=b div 100
   else b:=((b-1000) div 1600) + 9;
   printxy(4,150,shipclass[b]+' '+chr(48+targetindex));
   b:=round(hulldamage/maxhull*91);
   if b<>bar[1] then
    begin
     for i:=0 to 3 do
      fillchar(screen[i+167,bar[1]+22],4,0);
     for i:=0 to 3 do
      mymove(barpic^[i],screen[i+167,b+22],1);
     bar[1]:=b;
    end;
   b:=round(battery/32000*91);
   if b<>bar[2] then
    begin
     for i:=0 to 3 do
      fillchar(screen[i+174,bar[2]+22],4,0);
     for i:=0 to 3 do
      mymove(barpic^[i],screen[i+174,b+22],1);
     bar[2]:=b;
    end;
   b:=round((100-damages[5])/100*91);
   if b<>bar[3] then
    begin
     for i:=0 to 3 do
      fillchar(screen[i+181,bar[3]+22],4,0);
     for i:=0 to 3 do
      mymove(barpic^[i],screen[i+181,b+22],1);
     bar[3]:=b;
    end;
   b:=round(shieldlevel/100*91);
   if b<>bar[4] then
    begin
     for i:=0 to 3 do
      fillchar(screen[i+188,bar[4]+22],4,0);
     for i:=0 to 3 do
      mymove(barpic^[i],screen[i+188,b+22],1);
     bar[4]:=b;
    end;
  end;
 mouseshow;
end;

procedure displaymap;
begin
 mousehide;
 for j:=1 to nships do if ships^[j].hulldamage>0 then
  begin
   y:=round(ships^[j].rely/range*26.66);
   x:=round(ships^[j].relx/range*80);
   z:=round(ships^[j].relz/range*40);
   if (abs(x)<80) and (abs(y)<40) and (abs(z)<40) then
    begin
     if z<0 then
      for i:=y+70 to y+70-z do
       screen[i,x+160]:=screen[i,x+160] xor 6
     else
      for i:=y+70 downto y+70-z do
       screen[i,x+160]:=screen[i,x+160] xor 6;
     screen[y+70,x+160]:=screen[y+70,x+160] xor 85;
     screen[y+70-z,x+160]:=screen[y+70-z,x+160] xor 31;
     if j=targetindex then
      begin
       screen[y+70-z-2,x+160-2]:=screen[y+70-z-2,x+160-2] xor 60;
       screen[y+70-z-2,x+160-1]:=screen[y+70-z-2,x+160-1] xor 60;
       screen[y+70-z-1,x+160-2]:=screen[y+70-z-1,x+160-2] xor 60;
       screen[y+70-z+2,x+160+1]:=screen[y+70-z+2,x+160+1] xor 60;
       screen[y+70-z+2,x+160+2]:=screen[y+70-z+2,x+160+2] xor 60;
       screen[y+70-z+1,x+160+2]:=screen[y+70-z+1,x+160+2] xor 60;
      end;
    end;
  end;
 mouseshow;
end;

procedure takedamage(n,d: integer);
var j: integer;
begin
 case n of
  1: inc(ship.damages[5],d);
  2: dec(ship.hulldamage,d);
  3: dec(ship.hulldamage,d div 2);
  4: case random(8) of
      0: inc(ship.damages[1],d);
      1: inc(ship.damages[2],d);
      2: inc(ship.damages[3],d);
      3: inc(ship.damages[4],d);
      4: inc(ship.damages[6],d);
      5: inc(ship.damages[7],d);
      6,7: dec(ship.hulldamage,d);
     end;
  5: inc(ship.damages[2],d);
 end;
 for j:=1 to 7 do if ship.damages[j]>100 then ship.damages[j]:=100;
 if ship.hulldamage<0 then ship.hulldamage:=0;
 displaydamage;
 if ship.hulldamage=0 then deathsequence(0)
  else if ship.damages[5]=100 then deathsequence(1);
 if ship.shield=1501 then ship.shieldlevel:=ship.damages[2];
end;

procedure impact(s,n: integer);
var a,b,c,j,i: integer;
begin
 b:=ship.shield-1442;
 for j:=1 to 4 do if weapons[n].dmgtypes[j]>0 then
  begin
   i:=round(weapons[n].dmgtypes[j]/100*weapons[n].damage*5);
   if ship.shieldlevel=0 then takedamage(j,i)
   else
    begin
     a:=round(weapons[b].dmgtypes[j]/100*weapons[b].damage*ship.shieldlevel/100);
     if a<i then
      begin
       takedamage(j,round((i-a)/100*(100-ships^[s].damages[3])));
       ship.shieldlevel:=0;
       if ship.shield=1501 then ship.damages[2]:=100;
      end
     else
      begin
       a:=round((i/(ship.shieldlevel/100*weapons[b].damage)*100));
       c:=ship.shieldlevel-a;
       if c<0 then
        begin
         takedamage(5,random(4)+1);
         if ship.shield=1501 then
          begin
           ship.damages[2]:=100;
           displaydamage;
          end;
         ship.shieldlevel:=1;
        end
       else
        begin
         ship.shieldlevel:=c;
         if ship.shield=1501 then
          begin
           ship.damages[2]:=100-c;
           displaydamage;
          end;
        end;
      end;
    end;
  end;
 displaystats;
end;

procedure moveships;
begin
 for j:=1 to nships do if ships^[j].hulldamage>0 then
  with ships^[j] do
  begin
   if (relx<5000) and (relx>0) and (dx<-2000) then inc(dx,accelmax)
    else if (relx>-5000) and (relx<0) and (dx>2000) then dec(dx,accelmax)
    else if (relx>0) and (dx>-1000) then dec(dx,accelmax)
    else if (relx<0) and (dx<1000) then inc(dx,accelmax);
   if (rely<5000) and (rely>0) and (dy<-2000) then inc(dy,accelmax)
    else if (rely>-5000) and (rely<0) and (dy>2000) then dec(dy,accelmax)
    else if (rely>0) and (dy>-1000) then dec(dy,accelmax)
    else if (rely<0) and (dy<1000) then inc(dy,accelmax);
   if (relz<5000) and (relz>0) and (dz<-2000) then inc(dz,accelmax)
    else if (relz>-5000) and (relz<0) and (dz>2000) then dec(dz,accelmax)
    else if (relz>0) and (dz>-1000) then dec(dz,accelmax)
    else if (relz<0) and (dz<1000) then inc(dz,accelmax);
   relx:=relx+dx;
   rely:=rely+dy;
   relz:=relz+dz;
   r:=sqr(relx/10);
   r:=r+sqr(rely/10);
   r:=r+sqr(relz/10);
   r:=sqrt(r)*100;
   for a:=1 to 20 do
    if (charges[a]=100) then
     begin
      part:=ships^[j].range;
      if part>=r then
       begin
        i:=random(100);
        if i<skill then impact(j,1);
        charges[a]:=0;
       end;
     end;
  end;
end;

procedure findmouse;
begin
 if not mouse.getstatus(left) then exit;
 case mouse.x of
  291..312: case mouse.y of
             134..139: begin
                        if weapondisplay then
                         begin
                          mousehide;
                          for i:=140 to 193 do
                           move(asdisplay^[i],screen[i,201],114);
                          mouseshow;
                          weapondisplay:=false;
                          displaytargetinfo2;
                         end
                        else
                         begin
                          weapondisplay:=true;
                          displayweapons;
                         end;
                       end;
                 5..111: displayshieldpic(round((111-mouse.y)*100/102));
               144..164: if weapondisplay then fireweapon:=5;
               169..189: if weapondisplay then fireweapon:=10;
             end;
  127..147: case mouse.y of
             141..157: if range>5000 then
                        begin
                         displaymap;
                         dec(range,5000);
                         str(range:7,str1);
                         printxy(99,122,str1);
                         displaymap;
                        end;
             159..174: if not autofire then
                        begin
                         autofire:=true;
                         mousehide;
                         for i:=132 to 135 do screen[i,112]:=63;
                         mouseshow;
                        end
                       else
                        begin
                         autofire:=false;
                         mousehide;
                         for i:=132 to 135 do screen[i,112]:=95;
                         mouseshow;
                        end;
            end;
  149..160: case mouse.y of
             141..157: if range<5000000 then
                        begin
                         displaymap;
                         inc(range,5000);
                         str(range:7,str1);
                         printxy(99,122,str1);
                         displaymap;
                        end;
             159..174: begin
                        displaymap;
                        inc(targetindex);
                        while (targetindex<=nships) and (ships^[targetindex].hulldamage=0) do inc(targetindex);
                        if (targetindex>nships) or (ships^[targetindex].hulldamage=0) then
                         begin
                          targetindex:=1;
                          while (targetindex<nships) and (ships^[targetindex].hulldamage=0) do inc(targetindex);
                         end;
                        if not weapondisplay then
                         begin
                          mousehide;
                          for i:=140 to 193 do
                           move(asdisplay^[i],screen[i,201],114);
                          mouseshow;
                          displaytargetinfo2;
                         end;
                        displaymap;
                       end;
             176..197: begin engaging:=true; done:=true; end;
            end;
  161..171: case mouse.y of
             141..157: if range<5000000 then
                        begin
                         displaymap;
                         inc(range,5000);
                         str(range:7,str1);
                         printxy(99,122,str1);
                         displaymap;
                        end;
             159..174: begin
                        displaymap;
                        dec(targetindex);
                        while (targetindex>0) and (ships^[targetindex].hulldamage=0) do dec(targetindex);
                        if (targetindex=0) then
                         begin
                          targetindex:=nships;
                          while (targetindex>0) and (ships^[targetindex].hulldamage=0) do dec(targetindex);
                         end;
                        if not weapondisplay then
                         begin
                          mousehide;
                          for i:=140 to 193 do
                           move(asdisplay^[i],screen[i,201],114);
                          mouseshow;
                          displaytargetinfo2;
                         end;
                        displaymap;
                       end;
             176..197: begin engaging:=true; done:=true; end;
            end;
  173..193: case mouse.y of
             141..157: if not scanning then
                        begin
                         scanning:=true;
                         mousehide;
                         for i:=132 to 135 do screen[i,207]:=63;
                         mouseshow;
                        end
                       else
                        begin
                         scanning:=false;
                         mousehide;
                         for i:=132 to 135 do screen[i,207]:=95;
                         mouseshow;
                        end;
            end;
  203..222: if weapondisplay then
             case mouse.y of
              144..164: fireweapon:=1;
              169..189: fireweapon:=6;
             end;
  225..245: if weapondisplay then
             case mouse.y of
              144..164: fireweapon:=2;
              169..189: fireweapon:=7;
             end;
  247..267: if weapondisplay then
             case mouse.y of
              144..164: fireweapon:=3;
              169..189: fireweapon:=8;
             end;
  269..289: if weapondisplay then
             case mouse.y of
              144..164: fireweapon:=4;
              169..189: fireweapon:=9;
             end;
 end;
end;

procedure processkey;
var ans: char;
begin
 ans:=readkey;
 case upcase(ans) of
  '`': bossmode;
 end;
end;

procedure mainloop;
var index: integer;
begin
 index:=0;
 displaymap;
 repeat
  findmouse;
  if fastkeypressed then processkey;
  inc(index);
  if index=8 then
   begin
    suckpower;
    index:=0;
    displaymap;
    moveships;
    displaymap;
   end;
  displaystats;
  displaytargetinfo;
  powerup;
  delay(tslice*7);
 until done;
end;

procedure getshipinfo(n,j: integer);
var f: file of alienshiptype;
    i: integer;
begin
 if ship.wandering.alienid>2000 then i:=ship.wandering.alienid-2000 else i:=0;
 assign(f,'data\ships.dta');
 reset(f);
 if ioresult<>0 then errorhandler('ships.dta',5);
 seek(f,j+i*11);
 if ioresult<>0 then errorhandler('ships.dta',5);
 read(f,ships^[n]);
 if ioresult<>0 then errorhandler('ships.dta',5);
 close(f);
end;

procedure readyships;
var f: file of alientype;
    t: alientype;
begin
 nships:=0;
 assign(f,tempdir+'\contacts.dta');
 reset(f);
 if ioresult<>0 then errorhandler(tempdir+'\contacts.dta',1);
 repeat
  read(f,t);
  if ioresult<>0 then errorhandler(tempdir+'\contacts.dta',5);
 until t.id=ship.wandering.alienid;
 close(f);
 tcolor:=95;
 printxy(4,142,t.name);
 a:=t.victory;
 if a=0 then a:=1;
 repeat
  inc(nships);
  with ships^[nships] do
   begin
    if a<11 then c:=random(a)+1
     else c:=random(11)+1;
    getshipinfo(nships,c);
    dec(a,c);
    relx:=ship.wandering.relx*1000-500+random(1000);
    rely:=ship.wandering.rely*1000-500+random(1000);
    relz:=ship.wandering.relz*1000-500+random(1000);
    if (shield<1502) then shieldlevel:=100;
   end;
 until (nships=maxships) or (a=0);
end;

procedure readydata;
begin
 mousehide;
 compressfile(tempdir+'\current.vga',@screen);
 fading;
 loadscreen('data\war.vga',@screen);
 loadpal('data\war.pal');
 done:=false;
 new(ships);
 new(statpic);
 new(blank);
 new(barpic);
 new(asdisplay);
 new(shieldpic);
 new(shieldpic2);
 for i:=10 to 11 do
  move(screen[i,80],statpic^[i-10],10);
 for i:=20 to 21 do
  move(screen[i,267],blank^[i-20],10);
 for i:=0 to 3 do
  mymove(screen[i+10,100],barpic^[i],1);
 for i:=0 to 6 do
  mymove(screen[i+10,110],shieldpic^[i],1);
 for i:=0 to 6 do
  mymove(screen[i+10,120],shieldpic2^[i],1);
 for i:=6 to 20 do
  fillchar(screen[i,72],177,0);
 tcolor:=95;
 bkcolor:=0;
 oldt1:=t1;
 targetindex:=1;
 if ship.options[4]=0 then
  begin
   autofire:=true;
   scanning:=true;
   for i:=132 to 135 do screen[i,207]:=63;
   for i:=132 to 135 do screen[i,112]:=63;
  end
 else
  begin
   autofire:=false;
   scanning:=false;
   for i:=132 to 135 do screen[i,207]:=95;
   for i:=132 to 135 do screen[i,112]:=95;
  end;
 stats[1]:=0;
 stats[2]:=0;
 stats[3]:=0;
 oldshddmg:=0;
 fireweapon:=0;
 engaging:=false;
 range:=60000;
 printxy(99,122,'  600000 KM.R.');
 for j:=1 to 10 do
  begin
   poweredup[j]:=-1;
   if ship.armed then poweredup[j]:=99 else poweredup[j]:=0;
   if ship.gunnodes[j]=0 then poweredup[j]:=-1;
  end;
 for i:=140 to 193 do
  move(screen[i,201],asdisplay^[i],114);
 for j:=1 to 4 do bar[j]:=0;
 for j:=1 to 3 do stats[j]:=0;
 displayweapons;
 displaystats;
 displaydamage;
 displayshieldpic(ship.shieldopt[3]);
 readyships;
 displaytargetinfo;
 mouseshow;
 fadein;
end;

procedure savevictories;
var f: file of alientype;
    t: alientype;
begin
 assign(f,tempdir+'\contacts.dta');
 reset(f);
 if ioresult<>0 then errorhandler(tempdir+'\contacts.dta',1);
 i:=-1;
 repeat
  inc(i);
  read(f,t);
  if ioresult<>0 then errorhandler(tempdir+'\contacts.dta',4);
 until t.id=ship.wandering.alienid;
 seek(f,i);
 if ioresult<>0 then errorhandler(tempdir+'\contacts.dta',4);
 inc(t.victory,nships);
 inc(t.defeat,nships);
 if t.victory>20000 then t.victory:=20000;
 write(f,t);
 if ioresult<>0 then errorhandler(tempdir+'\contacts.dta',4);
 close(f);
end;

procedure aftereffects;
var cargoitems: array[0..15] of integer;
begin
 mousehide;
 for i:=6 to 120 do
  fillchar(screen[i,72],178,0);
 for i:=140 to 193 do
  fillchar(screen[i,201],114,0);
 tcolor:=95;
 printxy(78,8,'VICTORY!');
 mouseshow;
 if yesnorequest('DEPLOY SCAVENGER BOTS?',0,31) then
  begin
   mousehide;
   tcolor:=22;
   bkcolor:=0;
   printxy(78,18,'SCAVENGER BOTS DEPLOYED...');
   tcolor:=28;
   fillchar(cargoitems,11,0);
   i:=nships+random(2);
   if i>15 then i:=15;
   a:=1;
   while cargo[a].index<>3000 do inc(a);
   for j:=0 to i do
    begin
     cargoitems[j]:=random(21);
     printxy(84,28+j*6,cargo[a+cargoitems[j]].name);
     addcargo2(cargoitems[j]+3000);
    end;
   mouseshow;
   while fastkeypressed do readkey;
   readkey;
  end;
 savevictories;
end;

procedure initiatecombat;
begin
 readydata;
 mainloop;
 dispose(statpic);
 dispose(blank);
 dispose(ships);
 dispose(asdisplay);
 dispose(barpic);
 dispose(shieldpic);
 dispose(shieldpic2);
 if not engaging then aftereffects;
 removedata;
 if (engaging) and (targetready) then
  engage(systems[nearby[target].index].x,systems[nearby[target].index].y,systems[nearby[target].index].z)
  else if engaging then
   begin
    targetready:=true;
    engage(ship.posx-10+random(20),ship.posy-10+random(20),ship.posz-10+random(20));
   end;
end;

begin
end.