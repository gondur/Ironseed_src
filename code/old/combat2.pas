unit combat2;

{***************************
   Battle/Combat unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}

interface

procedure initiatecombat2;

implementation

uses crt, graph, data, gmouse, utils, utils2, modplay, weird, saveload, usecode, crewtick, heapchk;

const
   maxships				  = 25;
   maxformations			  = 3;
   shipclass : array[0..14] of string[14] = 
   ('Shuttle       ','Scout         ','Fighter       ','Assault Scout ',
    'Patrol Craft  ','Corvette      ','Frigate       ','Lt. Destroyer ',
    'Hv. Destroyer ','Lt. Cruiser   ','Hv. Cruiser   ','Battle Cruiser',
    'Flagship      ','Battleship    ','Dreadnaught   ');
   formation : array[0..maxformations-1,0..4,1..3] of integer =
   (
    ((0,0,0),(-3000,0,0),(3000,0,0),(0,-3000,0),(0,3000,0)),               { planar plus }
    ((0,0,0),(-3000,-3000,0),(3000,3000,0),(-3000,3000,0),(3000,-3000,0)), { planar cross}
    ((0,0,0),(1000,0,1000),(2000,0,2000),(3000,0,3000),(4000,0,4000))      { 3d slash }
    );
type
   xyz		  = record
		       x, y, z : Real;
		    end;       
   xy		  = record
		       x, y : Integer;
		    end;    
   combatshiptype = record
		       p				  : xyz;{relative position}
		       v				  : xyz;{relative velocity}
		       a				  : xyz;{acceleration at last time point}
		       scr				  : xy;{position on screen (relative tocenter)}
		       faction, targetfaction		  : Word; {Faction bits, targetable faction bits}
		       target				  : Integer;  {}
		       targetrange			  : Real; {distance to target}
		       techlevel, skill			  : Integer;
		       hull, hullmax			  : Integer;
		       accelmax				  : Integer;
		       battery, batterycharge, batterymax : Integer;
		       shieldlevel, shieldset		  : Integer;
		       shieldtype			  : Integer;
		       gunnodes				  : array[1..10] of byte;
		       charges				  : array[1..10] of real;
		       damages				  : array[1..7] of real;
		       
		    end;       
   alienshiparray   = array[1..maxships] of alienshiptype;
   combatshiparray  = array[0..maxships] of combatshiptype;
var
   totalships					: Integer;
   scanning,autofire,engaging,alienpicmode,dead	: boolean;
   poweredup					: array[1..10] of integer;
 userpowerup					: array[1..10] of boolean;
 learnchance					: Integer;

{*******************************************************************************}

(*procedure moveships;
var am, ar, r, d : real;
    a,j,i,t	 : integer;
   ax, ay, az	 : Integer;
   pax, pay, paz : Integer;
   
begin
   a:=ship.accelmax;
   if ship.damages[4]>89 then a:=a div 4;
   if shipdir<4 then ay:=1
   else if shipdir>6 then ay:=-1 else ay := 0;
   if shipdir mod 3=1 then ax:=+1
   else if shipdir mod 3=0 then ax:=-1 else ax := 0;
   if shipdir2=1 then az:=-1
   else if shipdir2=2 then az:=1 else az := 0;
   ar := sqrt(ax * ax + ay * ay + az * az);
   if ar > 0 then
   begin
      pax := round(ax * a / ar);
      pay := round(ay * a / ar);
      paz := round(az * a / ar);
   end else begin
      pax := 0;
      pay := 0;
      paz := 0;
   end;

   for j:=1 to nships do
      with ships^[j] do
      begin
	 dx := dx + pax;
	 dy := dy + pay;
	 dz := dz + paz;
	 if {(moveindex=5) and} (hulldamage>0) and (damages[4]<90) {and not fled} then
	 begin
	    am := accelmax;
	 end else begin
	    am := 0;
	 end;
	    
	 if am < a then
	 begin
	    dx := dx - round(ax * am / ar);
	    dy := dy - round(ay * am / ar);
	    dz := dz - round(az * am / ar);
	 end else begin
	    r := sqrt(1.0 * relx * relx + 1.0 * rely * rely + 1.0 * relz * relz);
	    if r < 1 then r := 1;
	    if {(moveindex=5) and} (hulldamage>0) and (damages[4]<90) {and not fled} then
	    begin
	       d := sqrt(1.0 * dx * dx + 1.0 * dy * dy + 1.0 * dz * dz);
	       am := accelmax;
	       if ar > 0 then
	       begin
		  dx := Round(dx - (am - a) * relx / r);
		  dy := Round(dy - (am - a) * rely / r);
		  dz := Round(dz - (am - a) * relz / r);
		  dx := dx - round(ax * a / ar);
		  dy := dy - round(ay * a / ar);
		  dz := dz - round(az * a / ar);
	       end else begin
		  dx := Round(dx - am * relx / r);
		  dy := Round(dy - am * rely / r);
		  dz := Round(dz - am * relz / r);
	       end;
		 
	    end;
	 end;
	 if dx < -3000 then dx := -3000;
	 if dx > 3000 then dx := 3000;
	 if dy < -3000 then dy := -3000;
	 if dy > 3000 then dy := 3000;
	 if dz < -3000 then dz := -3000;
	 if dz > 3000 then dz := 3000;

	 inc(relx, dx div 10);
	 inc(rely, dy div 10);
	 inc(relz, dz div 10);

	 if relx > 100000000 then relx := 100000000;
	 if relx < -100000000 then relx := -100000000;
	 if rely > 100000000 then rely := 100000000;
	 if rely < -100000000 then rely := -100000000;
	 if relz > 100000000 then relz := 100000000;
	 if relz < -100000000 then relz := -100000000;

	 r := r * 10;
	 ( *if (moveindex=5) and (hulldamage>0) and (damages[4]<90) and not fled then
	 begin
	    if (relx<5000) and (relx>0) and (dx<-3000) then inc(dx,accelmax)
	    else if (relx>-5000) and (relx<0) and (dx>3000) then dec(dx,accelmax)
	    else if (relx>0) and (dx>-1000) then dec(dx,accelmax)
	    else if (relx<0) and (dx<1000) then inc(dx,accelmax);
	    if (rely<5000) and (rely>0) and (dy<-3000) then inc(dy,accelmax)
	    else if (rely>-5000) and (rely<0) and (dy>3000) then dec(dy,accelmax)
	    else if (rely>0) and (dy>-1000) then dec(dy,accelmax)
	    else if (rely<0) and (dy<1000) then inc(dy,accelmax);
	    if (relz<5000) and (relz>0) and (dz<-3000) then inc(dz,accelmax)
	    else if (relz>-5000) and (relz<0) and (dz>3000) then dec(dz,accelmax)
	    else if (relz>0) and (dz>-1000) then dec(dz,accelmax)
	    else if (relz<0) and (dz<1000) then inc(dz,accelmax);
	 end;
	 relx:=relx+round(dx/5);
	 rely:=rely+round(dy/5);
	 relz:=relz+round(dz/5);
	 r:=sqr(relx/10);
	 r:=r+sqr(rely/10);
	 r:=r+sqr(relz/10);
	 r:=sqrt(r)*100;
	 
	 a:=ship.accelmax;
	 if ship.damages[4]>89 then a:=a div 4;
	 if shipdir<4 then rely:=rely+a
	 else if shipdir>6 then rely:=rely-a;
	 if shipdir mod 3=1 then relx:=relx+a
	 else if shipdir mod 3=0 then relx:=relx-a;
	 if shipdir2=1 then relz:=relz-a
	 else if shipdir2=2 then relz:=relz+a;
	  * )
	 part:=ships^[j].range;
	 if (hulldamage>0) {and not fled} then
	    for a:=1 to 20 do
	       if (charges[a]=100) then
	       begin
		  if part>=r then
		  begin
		     i:=random(120)-15*ship.options[4];
		     {if (i<skill) or ((scanning) and (random(100)<20)) then}
		     if not SkillTest(True, 4, skill + (ord(scanning) * 20), learnchance) then
		     begin
			displaymap;
			impact(j,maxweapons);
			displaymap;
		     end;
		     charges[a]:=0;
		  end;
	       end;
	 if (abs(r)>1200000) then {fled:=true;}hulldamage:=0;
	 if ((hulldamage=0) {or fled}) and (targetindex=j) then
	 begin
	    targetindex:=1;
	    while (targetindex<=nships) and ((ships^[targetindex].hulldamage=0) {or fled}) do inc(targetindex);
	    if targetindex>nships then done:=true;
	 end;
      end;
   if moveindex=5 then moveindex:=0 else inc(moveindex);
end;
*)

(*
procedure findmouse;
begin
 if not mouse.getstatus then exit;
 case mouse.x of
  105..125: case mouse.y of
             131..151: fireweapon:=1;
             152..156: if (mouse.x>108) and (mouse.x<122) then
                        begin
                         if userpowerup[1] then
                          begin
                           plainfadearea(109,152,121,154,32);
                           userpowerup[1]:=false;
                          end
                         else
                          begin
                           plainfadearea(109,152,121,154,-32);
                           userpowerup[1]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>108) and (mouse.x<122) then
                        begin
                         if userpowerup[6] then
                          begin
                           plainfadearea(109,159,121,161,32);
                           userpowerup[6]:=false;
                          end
                         else
                          begin
                           plainfadearea(109,159,121,161,-32);
                           userpowerup[6]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=6;
             else findtarget;
            end;
  128..148: case mouse.y of
             131..151: fireweapon:=2;
             152..156: if (mouse.x>131) and (mouse.x<145) then
                        begin
                         if userpowerup[2] then
                          begin
                           plainfadearea(132,152,144,154,32);
                           userpowerup[2]:=false;
                          end
                         else
                          begin
                           plainfadearea(132,152,144,154,-32);
                           userpowerup[2]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>131) and (mouse.x<145) then
                        begin
                         if userpowerup[7] then
                          begin
                           plainfadearea(132,159,144,161,32);
                           userpowerup[7]:=false;
                          end
                         else
                          begin
                           plainfadearea(132,159,144,161,-32);
                           userpowerup[7]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=7;
             else findtarget;
            end;
  151..171: case mouse.y of
             131..151: fireweapon:=3;
             152..156: if (mouse.x>154) and (mouse.x<168) then
                        begin
                         if userpowerup[3] then
                          begin
                           plainfadearea(155,152,167,154,32);
                           userpowerup[3]:=false;
                          end
                         else
                          begin
                           plainfadearea(155,152,167,154,-32);
                           userpowerup[3]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>154) and (mouse.x<168) then
                        begin
                         if userpowerup[8] then
                          begin
                           plainfadearea(155,159,167,161,32);
                           userpowerup[8]:=false;
                          end
                         else
                          begin
                           plainfadearea(155,159,167,161,-32);
                           userpowerup[8]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=8;
             else findtarget;
            end;
  174..194: case mouse.y of
             131..151: fireweapon:=4;
             152..156: if (mouse.x>177) and (mouse.x<191) then
                        begin
                         if userpowerup[4] then
                          begin
                           plainfadearea(178,152,190,154,32);
                           userpowerup[4]:=false;
                          end
                         else
                          begin
                           plainfadearea(178,152,190,154,-32);
                           userpowerup[4]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>177) and (mouse.x<191) then
                        begin
                         if userpowerup[9] then
                          begin
                           plainfadearea(178,159,190,161,32);
                           userpowerup[9]:=false;
                          end
                         else
                          begin
                           plainfadearea(178,159,190,161,-32);
                           userpowerup[9]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=9;
             191..195: if (mouse.x>183) then switchalienmode else findtarget;
             else findtarget;
            end;
  195..196: case mouse.y of
             191..195: switchalienmode;
             else findtarget;
            end;
  197..217: case mouse.y of
             131..151: fireweapon:=5;
             152..156: if (mouse.x>200) and (mouse.x<214) then
                        begin
                         if userpowerup[5] then
                          begin
                           plainfadearea(201,152,213,154,32);
                           userpowerup[5]:=false;
                          end
                         else
                          begin
                           plainfadearea(201,152,213,154,-32);
                           userpowerup[5]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>200) and (mouse.x<214) then
                        begin
                         if userpowerup[10] then
                          begin
                           plainfadearea(201,159,213,161,32);
                           userpowerup[10]:=false;
                          end
                         else
                          begin
                           plainfadearea(201,159,213,161,-32);
                           userpowerup[10]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=10;
             191..195: if (mouse.x<209) then switchalienmode else findtarget;
             else findtarget;
            end;
  223..225: if (mouse.y>184) and (mouse.y<193) then previoustarget;
  226..242: case mouse.y of
             124..144: if range>5000 then
                        begin
                         displaymap;
                         dec(range,5000);
                         str(range:7,str1);
                         printxy(33,110,str1);
                         displaymap;
                        end;
             151..173: if not autofire then
                        begin
                         autofire:=true;
                         mousehide;
                         for i:=125 to 126 do
                          fillchar(screen[i,163],52,63);
                         mouseshow;
                        end
                       else
                        begin
                         autofire:=false;
                         mousehide;
                         for i:=125 to 126 do
                          fillchar(screen[i,163],52,95);
                         mouseshow;
                        end;
             185..192: if (mouse.x<241) then previoustarget;
               89..97: if mouse.x<237 then setdir(1) else setdir(2);
              99..107: if mouse.x<237 then setdir(4) else setdir(5);
             109..117: if mouse.x<237 then setdir(7) else setdir(8);
             else findtarget;
            end;
  244..260: case mouse.y of
             124..144: if range<5000000 then
                        begin
                         displaymap;
                         inc(range,5000);
                         str(range:7,str1);
                         printxy(33,110,str1);
                         displaymap;
                        end;
             151..173: if not scanning then
                        begin
                         scanning:=true;
                         mousehide;
                         for i:=187 to 188 do
                          fillchar(screen[i,163],52,63);
                         mouseshow;
                        end
                       else
                        begin
                         scanning:=false;
                         mousehide;
                         for i:=187 to 188 do
                          fillchar(screen[i,163],52,95);
                         mouseshow;
                        end;
             185..192: if (mouse.x>245) then nexttarget;
               69..77: if mouse.x>248 then setdir2(1);
               79..87: if mouse.x>248 then setdir2(2);
               89..97: if mouse.x<249 then setdir(2) else setdir(3);
              99..107: if mouse.x<249 then setdir(5) else setdir(6);
             109..117: if mouse.x<249 then setdir(8) else setdir(9);
             else findtarget;
            end;
  261..263: if (mouse.y>184) and (mouse.y<193) then nexttarget else findtarget;
  271..279: if (mouse.y<10) and (ship.options[2]>1) then
             begin
              dec(ship.options[2]);
              tslice:=ship.options[2];
              displaytimedelay;
             end;
  291..312: case mouse.y of
             11..117: displayshieldpic(round((117-mouse.y)*100/102));
             1..9: if (mouse.x>299) and (mouse.x<309) and (ship.options[2]<255) then
                    begin
                     inc(ship.options[2]);
                     tslice:=ship.options[2];
                     displaytimedelay;
                    end;
            end;
  else findtarget;
 end;
end;
*)
   
(*procedure processkey;
var ans: char;
begin
 ans:=readkey;
 case upcase(ans) of
   #0: begin
        ans:=readkey;
        case ans of
         #71: setdir(1);
         #72: setdir(2);
         #73: setdir(3);
         #75: setdir(4);
         #77: setdir(6);
         #79: setdir(7);
         #80: setdir(8);
         #81: setdir(9);
         #16,#45	 : if yesnorequest('Do you want to quit?',0,31) then
	 begin
	    quit:=true;
	    done:=true;
	    dead:=true;
	 end;
        end;
       end;
  '-': setdir2(1);
  '+': setdir2(2);
  ' ': switchalienmode;
  '<',',': previoustarget;
  '>','.': nexttarget;
  '`': bossmode;
  'Q': fireweapon:=1;
  'W': fireweapon:=2;
  'E': fireweapon:=3;
  'R': fireweapon:=4;
  'T': fireweapon:=5;
  'A': fireweapon:=6;
  'S': fireweapon:=7;
  'D': fireweapon:=8;
  'F': fireweapon:=9;
  'G': fireweapon:=10;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
 end;
end;
*)
   
(*
procedure mainloop;
var index,cindex: integer;
begin
 index:=0;
 cindex:=0;
 displaymap;
 repeat
  fadestep(8);
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
    if not done then
    begin
       if cindex<16 then i:=cindex+32 else i:=64-cindex;
       setrgb256(i,0,0,colors[i,3]);
       if cindex<31 then inc(cindex) else cindex:=0;
       if cindex<16 then i:=cindex+32 else i:=64-cindex;
       setrgb256(i,0,0,63);
       delay(tslice*3);
    end;
 until done;
 wait(1);
 set256colors(colors);
end;
*)

procedure readydata;
var
   j : Integer;
begin
   mousehide;
   compressfile(tempdir+'\current',@screen);
   fadestopmod(-8, 20);
   playmod(true,'sound\combat.mod');
   loadscreen('data\fight',@screen);
   loadscreen('data\cloud',backgr);
   
   done:=false;
   tcolor:=95;
   bkcolor:=0;
   autofire:=true;
   scanning:=false;
   loadscreen('data\waricon',backgr);
   for j:=1 to 10 do
   begin
      {poweredup[j]:=-1;
      if ship.armed then poweredup[j]:=99 else poweredup[j]:=0;
      if ship.gunnodes[j]=0 then poweredup[j]:=-1;}
   end;
   mouseshow;
end;

procedure unloaddata;
begin
   loadscreen('data\cloud',backgr);
   if ((tempplan^[curplan].state=6) and (tempplan^[curplan].mode=2)) then makeastoroidfield
   else if (tempplan^[curplan].state=0) and (tempplan^[curplan].mode=1) then makecloud;
end;
(*
procedure savevictories;
var f : file of alientype;
    t : alientype;
   j  : Integer;
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
 i:=nships div 4;
 if i=0 then i:=1;
 inc(t.victory,i);
 i:=0;
 for j:=1 to 7 do i:=i+ship.damages[j];
 if i=0 then inc(t.victory,nships);
 if t.anger<200 then inc(t.anger)
 else if t.congeniality>0 then dec(t.congeniality);
 if t.victory>20000 then t.victory:=20000;
 write(f,t);
 if ioresult<>0 then errorhandler(tempdir+'\contacts.dta',4);
 close(f);
end;
*)

(*
procedure aftereffects;
var cargoitems : array[0..13] of integer;
   j	       : Integer;
   dcnt	       : Integer;
begin
   dcnt := 0;
   for j:=1 to nships do
   begin
      if ships^[j].hulldamage <= 0 then inc(dcnt);
   end;
 playmod(true,'sound\victory.mod');
 mousehide;
 for i:=9 to 117 do
  fillchar(screen[i,6],254,0);
 for i:=125 to 189 do
  fillchar(screen[i,6],93,0);
 tcolor:=95;
   if dcnt <= 0 then
   begin
      printxy(18,8,'ESCAPED!');
   end else begin
      printxy(18,8,'VICTORY!');
   end;
 mouseshow;
 if (dcnt > 0) and yesnorequest('DEPLOY SCAVENGER BOTS?',0,31) then
  begin
   tcolor:=22;
   bkcolor:=0;
   mousehide;
   printxy(18,18,'SCAVENGER BOTS DEPLOYED...');
   mouseshow;
   tcolor:=28;
   fillchar(cargoitems,11,0);
   i:=random(dcnt{nships});
   if i>13 then i:=13;
   a:=1;
   while cargo[a].index<>3000 do inc(a);
   for j:=0 to i do
    begin
     cargoitems[j]:=random(21);
     mousehide;
     printxy(24,28+j*6,cargo[a+cargoitems[j]].name);
     mouseshow;
     addcargo2(cargoitems[j]+3000, true);
    end;
   while fastkeypressed do readkey;
   repeat
   until (fastkeypressed) or (mouse.getstatus);
   while fastkeypressed do readkey;
  end;
   if dcnt > 0 then
      savevictories;
end;
*)

procedure initiatecombat2;
begin
   readydata;
   {mainloop;}
   while fastkeypressed do readkey;
   repeat
   until (fastkeypressed) or (mouse.getstatus);
   while fastkeypressed do readkey;
   unloaddata;
 {if (not engaging) and (not dead) and (ship.wandering.alienid<1013) then aftereffects;}
 stopmod;
 removedata;
 if (engaging) and (targetready) then
  engage(systems[nearby[target].index].x,systems[nearby[target].index].y,systems[nearby[target].index].z)
 else if engaging then
  begin
   targetready:=true;
   engage(ship.posx-10+random(20),ship.posy-10+random(20),ship.posz-10+random(20));
  end;
end;

var
   j : Integer;
begin
 for j :=1 to 10 do userpowerup[j]:=true;
end.   
