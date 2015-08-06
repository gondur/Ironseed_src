unit comm;

{***************************
   Communication unit for IronSeed

   Channel 7
   Destiny: Virtual


   (C) DEC. 31, 1993

***************************}

{$O+}

interface

procedure initialcontact;
procedure conversewithcrew;
procedure continuecontact;

implementation

uses crt, data, gmouse, utils, combat, utils2, weird;

const
 numback= 14;
type
 localalienarray= array[1..6] of alientype;
 infodisplay= array[20..105,222..302] of byte;
var
 commlevel,i,j,techlvl,eattype,contactindex,cursorx,index: integer;
 alien: ^alientype;
 temp: ^conversetype;
 brighter,infomode: boolean;
 str1, str2: ^string;
 question: string[20];
 c: ^conversearray;
 r: ^responsearray;
 locals: ^localalienarray;
 tmpm: ^mouseicontype;
 t: ^infodisplay;

procedure gettechlevel(plan: integer);
var i: integer;
begin
 techlvl:=-2;
 case tempplan^[plan].system of
  93,138,78,191,171,221,45:
    begin
     techlvl:=6*256;
     exit;
    end;
 end;
 case tempplan^[plan].state of
  2: case tempplan^[plan].mode of
      2: techlvl:=-1;
      3: techlvl:=tempplan^[plan].age div 15000000;
     end;
  3: begin
      techlvl:=(tempplan^[plan].mode-1)*256;
      case tempplan^[plan].mode of
       1: techlvl:=techlvl+tempplan^[plan].age div 1500000;
       2: techlvl:=techlvl+tempplan^[plan].age div 1000;
       3: techlvl:=techlvl+tempplan^[plan].age div 800;
      end;
     end;
  4: begin
      techlvl:=(tempplan^[plan].mode+2)*256;
      case tempplan^[plan].mode of
       1: techlvl:=techlvl+tempplan^[plan].age div 400;
       2: techlvl:=techlvl+tempplan^[plan].age div 200;
      end;
     end;
  5: case tempplan^[plan].mode of
      1: begin
          i:=tempplan^[plan].age div 100000000;
          if i>9 then i:=9;
          techlvl:=techlvl+i;
         end;
      2: techlvl:=-1;
     end;
  6: if tempplan^[curplan].mode=2 then techlvl:=6*256;   {void dwellers}
 end;
 i:=random(9);                              { junk first random number }
 eattype:=random(3);
 randomize;
end;

procedure sprinkle(x1,y1,x2,y2,seed: integer);
var total,j,max: word;
begin
 max:=(x2-x1)*(y2-y1);
 total:=0;
 j:=0;
 repeat
  inc(total);
  j:=j+seed;
  if j>max then j:=j-max;
  screen[y1+j div (x2-x1),x1+j mod (x2-x1)]:=0;
  if total mod 50=0 then delay(x div 3);
  until total>max;
end;

procedure getname;
type nametype= string[15];
var str1: nametype;
    f: file of nametype;
    n: integer;
begin
 n:=contactindex-tempplan^[contactindex].system;
 assign(f,'data\planname.txt');
 reset(f);
 if ioresult<>0 then errorhandler('data\planname.txt',1);
 seek(f,n);
 if ioresult<>0 then errorhandler('data\planname.txt',6);
 read(f,str1);
 if ioresult<>0 then errorhandler('data\planname.txt',6);
 alien^.name:=str1;
 close(f);
end;

procedure addtofile;
var confile,target: file of alientype;
    err,add: boolean;
    temp: alientype;
    index: integer;
begin
 assign(confile,'save\contacts.dta');
 reset(confile);
 if ioresult<>0 then errorhandler('contacts.dta',1);
 err:=false;
 add:=false;
 index:=-1;
 repeat
  inc(index);
  read(confile,temp);
  if ioresult<>0 then err:=true;
  if (not err) and (temp.id=alien^.id) then
   begin
    seek(confile,index);
    if ioresult<>0 then errorhandler('contacts.dta',5);
    write(confile,alien^);
    if ioresult<>0 then errorhandler('contacts.dta',5);
    add:=true;
   end;
 until (err) or (add);
 if not add then
  begin
   seek(confile,index);
   if ioresult<>0 then errorhandler('contacts.dta',5);
   write(confile,alien^);
   if ioresult<>0 then errorhandler('contacts.dta',5);
  end;
 close(confile);
end;

procedure getspecial(n: integer);
var f: file of alientype;
begin
 assign(f,'data\contact0.dta');
 reset(f);
 if ioresult<>0 then errorhandler('data\contact0.dta',1);
 seek(f,n-1);
 if ioresult<>0 then errorhandler('data\contact0.dta',5);
 read(f,alien^);
 if ioresult<>0 then errorhandler('data\contact0.dta',5);
 alien^.id:=contactindex;
 case n of
   1: i:=103;
   2: i:=102;
   3: i:=114;
   4: i:=106;
   5: i:=111;
   6: i:=107;
   7: i:=113;
   8: i:=110;
   9: i:=104;
  10: i:=105;
  11: i:=101;
  else errorhandler('Nutty event in setting special...',6);
 end;
 runevent(i);
end;

procedure setalienstructure(starting: integer);
begin
 case tempplan^[contactindex].system of
   93: getspecial(1);
  138: getspecial(2);
   45: getspecial(4);
  221: getspecial(5);
   78: getspecial(6);
  171: getspecial(8);
  191: getspecial(9);
  else
   begin
    alien^.conindex:=0;
    getname;
    x:=hi(techlvl);
    y:=lo(techlvl);
    with alien^ do
     begin
      y:=y-5;
      if y<0 then
       begin
        dec(x);
        y:=10+y;
       end;
      if x<0 then
       begin
        x:=0;
        y:=0;
       end;
      techmin:=x*256+y;
      y:=lo(techlvl);
      y:=y+5;
      if y>9 then
       begin
        inc(x);
        y:=y-10;
       end;
      if x>5 then
       begin
        x:=5;
        y:=0;
       end;
      techmax:=x*256+y;
      id:=contactindex;
      victory:=0;
      defeat:=0;
      war:=false;
      case starting of
       1: begin
           if random(3)=0 then war:=true;
           congeniality:=15;
           anger:=30;
           createwandering(0,alien^);
          end;
       2: begin
           congeniality:=20;
           anger:=10;
          end;
       3: begin
           congeniality:=40;
           anger:=0;
          end;
       4: begin
           congeniality:=20;
           anger:=15;
          end;
       5: begin
           congeniality:=5;
           anger:=0;
           createwandering(1,alien^);
          end;
      end;
     end;
   end;
 end;
 addtofile;
end;

procedure contactsequence(com: integer);
var a,b,index,contactmade: integer;
    t: ^char;
begin
 mousehide;
 for i:=23 to 56 do
  fillchar(screen[i,194],118,0);
 tcolor:=47;
 printxy(194,23,'SCANNING EM BANDS');
 for a:=1 to 2000 do
  begin
   t1:=t1+0.01;
   if t1=6.28 then t1:=0;
   for b:=0 to 34 do
    begin
     j:=abs(round(20*(sin(b*0.09+t1))));
     x:=20;
     for i:=0 to j do
      begin
       screen[55-j,b*3+199]:=x;
       screen[55-j,b*3+200]:=x;
      end;
     screen[54-j,b*3+199]:=0;
     screen[54-j,b*3+200]:=0;
    end;
  end;
 sprinkle(194,30,311,56,17);
 printxy(194,23,'AQUIRING TRANSMISSION');
 wait(2);
 printxy(194,23,'ANALYZING DATA STREAM');
 y:=0;
 x:=0;
 for a:=1 to 5000 do
  begin
   printxy(x*5+194,y*6+31,chr(48+random(2)));
   inc(x);
   if x>20 then
    begin
     x:=0;
     inc(y);
     if y>3 then y:=0;
    end;
   delay(tslice div 10);
  end;
 sprinkle(194,30,311,56,17);
 printxy(194,23,'INITIALIZE CYPHER KEY');
 t:=ptr(random(1000),0);
 for a:=1 to 5000 do
  begin
   inc(t);
   printxy(x*5+194,y*6+31,t^);
   inc(x);
   if x>20 then
    begin
     x:=0;
     inc(y);
     if y>3 then y:=0;
    end;
   delay(tslice div 10);
  end;
 sprinkle(194,30,311,56,17);
 printxy(194,23,'MATRIX ESTABLISHED   ');
 for i:=29 to 55 do
  fillchar(screen[i,194],118,0);
 wait(1);
 printxy(194,29,'TRANSFERING CYPHER');
 wait(1);
 gettechlevel(contactindex);
 if techlvl<1 then
  begin
   printxy(194,35,'UNINTELLIGIBLE CYPHER');
   tcolor:=94;
   printxy(194,41,'CONTACT FAILURE');
   mouseshow;
   exit;
  end;
 contactmade:=0;
 if (hi(techlvl)<4) then
  case eattype of
   0: if random(5)=0 then contactmade:=1;
   1: case com of
       0: contactmade:=5;
       1: contactmade:=3;
       2: contactmade:=2;
      end;
   2: if random(2)=0 then contactmade:=random(5)
   end
  else
   case eattype of
    0: case com of
        0: if random(2)=0 then contactmade:=1 else contactmade:=3;
        1: contactmade:=2+random(2);
        2: contactmade:=2;
       end;
    1: case com of
        0: contactmade:=4;
        1: contactmade:=2+random(2);
	2: contactmade:=2;
       end;
    2: if random(2)=0 then contactmade:=random(5);
   end;
 if contactmade>0 then
  begin
   tempplan^[contactindex].notes:=tempplan^[contactindex].notes or 2;
   setalienstructure(contactmade);
  end;
 printxy(194,35,'CYPHER ACKNOWLEDGED');
 wait(1);
 printxy(194,41,'AWAITING RESPONSE');
 wait(1);
 if contactmade>0 then
  printxy(194,47,'CONTACT ESTABLISHED')
 else
  begin
   tcolor:=94;
   printxy(194,47,'NO RESPONSE');
  end;
 mouseshow;
end;

procedure showoptions;
var str1: string[3];
    a: integer;
begin
 tcolor:=26;
 mousehide;
 for i:=125 to 189 do
  fillchar(screen[i,15],278,0);
 case commlevel of
  0: begin
      printxy(15,125,'ESTABLISH INITIAL CONTACT WITH ALIENS');
      if (not showplanet) or (ship.orbiting=0) or (testbit(tempplan^[curplan].notes,1)) then tcolor:=10;
      printxy(25,135,'1. PLANET: SONIC/VISUAL/RADIO');
      if (not showplanet) then tcolor:=8 else tcolor:=26;
      printxy(25,145,'2. SYSTEM: RADIO/SUBSPACE');
     end;
  1: begin
      printxy(20,125,'ESTABLISH POSTURE');
      printxy(25,135,'1. HOSTILE');
      printxy(25,145,'2. FRIENDLY');
      printxy(25,155,'3. SERVILE');
     end;
  2: begin
      printxy(15,125,'CONTACT ALIENS ON NEARBY PLANET');
      y:=1;
      a:=1;
      j:=findfirstplanet(tempplan^[curplan].system);
      inc(j);
      if tempplan^[j].system=tempplan^[curplan].system then
       repeat
        gettechlevel(j);
        if (hi(techlvl)>=3) and (not testbit(tempplan^[j].notes,1))
         and (lo(techlvl)<10) then
         begin
          printxy(25,125+y*10,chr(48+y)+'.');
          printplanet(40,125+y*10,tempplan^[curplan].system,a);
          str(hi(techlvl),str1);
          printxy(110,125+y*10,'INDUSTRIAL LEVEL '+str1);
          inc(y);
         end;
        inc(j);
        inc(a);
       until tempplan^[j].system<>tempplan^[curplan].system;
      if y=1 then printxy(25,135,'NO NEARBY ALIENS DETECTED.');
     end;
 end;
 mouseshow;
end;

procedure command(com: integer);
var contactmade: integer;
begin
 case commlevel of
  0: case com of
      1: begin
          if (not showplanet) or (ship.orbiting=0)
           or (testbit(tempplan^[curplan].notes,1)) then exit;
          commlevel:=1;
          contactindex:=curplan;
          showoptions;
         end;
      2: begin
          if not showplanet then exit;
          commlevel:=2;
          showoptions;
         end;
     end;
  1: begin
      if (com>3) then exit;
      contactsequence(com-1);
      commlevel:=0;
      showoptions;
     end;
  2: begin
      y:=0;
      j:=findfirstplanet(tempplan^[curplan].system);
      inc(j);
      if tempplan^[j].system=tempplan^[curplan].system then
       repeat
        gettechlevel(j);
        if (hi(techlvl)>=3) and (not testbit(tempplan^[j].notes,1))
         and (lo(techlvl)<10) then
         inc(y);
        inc(j);
       until (tempplan^[j].system<>tempplan^[curplan].system) or (y=com);
      if y<>com then
       begin
        commlevel:=0;
        showoptions;
        exit;
       end;
      contactindex:=j-1;
      commlevel:=1;
      showoptions;
     end;
 end;
end;

procedure findmouse;
var button: boolean;
begin
 if mouse.getstatus(left) then button:=true else button:=false;
 if not button then exit;
 case mouse.x of
  308..317: if (mouse.y>142) and (mouse.y<167) then done:=true;
   15..290: case mouse.y of
             135..141: command(1);
             145..151: command(2);
             155..161: command(3);
             165..171: command(4);
             175..181: command(5);
             185..191: command(6);
            end;
 end;
 idletime:=0;
end;

procedure processkey;
var ans: char;
begin
 ans:=readkey;
 case ans of
  #27: if commlevel<>0 then
        begin
         commlevel:=0;
         showoptions;
        end
       else done:=true;
  '1'..'6': command(ord(ans)-48);
  '`': bossmode;
 end;
 idletime:=0;
end;

procedure mainloop;
begin
 repeat
  if fastkeypressed then processkey;
  findmouse;
  inc(idletime);
  if idletime=maxidle then screensaver;
  adjustlights;
  delay(tslice*9);
 until done;
end;

procedure readydata;
begin
 mousehide;
 savescreen;
 fading;
 loadscreen('data\com.vga');
 loadpal('data\com.pal');
 for i:=10 to 110 do
  for j:=0 to 319 do
   if (screen[i,j]=255) and ((i+j) mod 2=0) then screen[i,j]:=8
    else if (screen[i,j]=255) then screen[i,j]:=0;
 new(tmpm);
 for i:=0 to 15 do
  begin
   mymove(screen[i+130,20],tmpm^[i],4);
   fillchar(screen[i+130,20],16,0);
  end;
 mousesetcursor(tmpm^);
 dispose(tmpm);
 new(alien);
 oldt1:=t1;
 bkcolor:=0;
 tcolor:=31;
 done:=false;
 commlevel:=0;
 fadein;
 mouseshow;
end;

procedure initialcontact;
begin
 readydata;
 showoptions;
 mainloop;
 dispose(alien);
 mouse.setmousecursor(2);
 removedata;
end;

{***************************************************************************}

procedure loadconversation;
var fc: file of converseindex;
    fr: file of responsetype;
    s: string[2];
    str1: string[4];
begin
 fillchar(r^,sizeof(responsearray),0);
 fillchar(c^,sizeof(conversearray),0);
 str((contactindex+1):4,str1);
 if contactindex<1000 then str1[1]:='0';
 if contactindex<100 then str1[2]:='0';
 if contactindex<10 then str1[3]:='0';
 assign(fc,'data\conv'+str1+'.ind');
 reset(fc);
 if ioresult<>0 then errorhandler('conv'+str1+'.ind',1);
 i:=0;
 repeat
  inc(i);
  read(fc,c^[i]);
 until ioresult<>0;
 close(fc);
 assign(fr,'data\conv'+str1+'.dta');
 reset(fr);
 if ioresult<>0 then errorhandler('conv'+str1+'.dta',1);
 i:=0;
 repeat
  inc(i);
  read(fr,r^[i]);
 until ioresult<>0;
 close(fr);
end;

procedure showportrait(n: integer);
var datafile: file of portraittype;
    s: string[2];
    portrait: ^portraittype;
begin
 new(portrait);
 str(n:2,s);
 if n<10 then s[1]:='0';
 assign(datafile,'data\image'+s+'.vga');
 if ioresult<>0 then errorhandler('portrait',1);
 reset(datafile);
 if ioresult<>0 then errorhandler('portrait',5);
 read(datafile,portrait^);
 close(datafile);
 for i:=0 to 34 do
  begin
   move(portrait^[i*2],screen[i*2+41,126],70);
   delay(tslice div 5);
  end;
 for i:=0 to 34 do
  begin
   move(portrait^[i*2+1],screen[i*2+42,126],70);
   delay(tslice div 5);
  end;
 dispose(portrait);
end;

procedure drawcursor;
begin
 for i:=(contactindex mod 3)*30+37 to (contactindex mod 3)*30+42 do
  for j:=(contactindex div 3)*138+89 to (contactindex div 3)*138+93 do
   if screen[i,j] div 16=3 then screen[i,j]:=screen[i,j]+32;
 showportrait(ship.crew[contactindex+1].index);
end;

procedure erasecursor;
begin
 for i:=(contactindex mod 3)*30+37 to (contactindex mod 3)*30+42 do
  for j:=(contactindex div 3)*138+89 to (contactindex div 3)*138+93 do
   if screen[i,j] div 16=5 then screen[i,j]:=screen[i,j]-32;
end;

procedure displaycrewnames;
var a,b: integer;
begin
 t1:=22/36;
 for a:=0 to 5 do
  begin
   i:=1;
   repeat
    printxy((a div 3)*230+12+i*5,(a mod 3)*30+37,ship.crew[a+1].name[i]);
    inc(i);
   until ship.crew[a+1].name[i]=' ';
   j:=round((0.40*ship.crew[a+1].men+0.60*ship.crew[a+1].emo-0.20*ship.crew[a+1].phy)*0.36);
   if j>36 then j:=36
   else if j<1 then j:=0;
   for b:=0 to j do
    begin
     screen[(a mod 3)*30+48,(a div 3)*258+b+13]:=round(t1*b)+73;
     screen[(a mod 3)*30+49,(a div 3)*258+b+13]:=round(t1*b)+73;
    end;
   if j<34 then
    for b:=j+1 to 36 do
     begin
     screen[(a mod 3)*30+48,(a div 3)*258+b+13]:=0;
     screen[(a mod 3)*30+49,(a div 3)*258+b+13]:=0;
    end;
  end;
end;

procedure command2(n: integer);
begin
 mousehide;
 for i:=135 to 189 do
  fillchar(screen[i,15],278,0);
 printxy(12,182,'SUBJECT:');
 if contactindex>-1 then erasecursor;
 contactindex:=n;
 drawcursor;
 showportrait(ship.crew[contactindex+1].index);
 mouseshow;
 loadconversation;
end;

procedure findmouse2;
begin
 if not mouse.getstatus(left) then exit;
 case mouse.y of
    30..50: case mouse.x of
                9..85: if contactindex<>0 then command2(0);
             235..311: if contactindex<>3 then command2(3);
            end;
    60..80: case mouse.x of
                9..85: if contactindex<>1 then command2(1);
             235..311: if contactindex<>4 then command2(4);
            end;
   90..110: case mouse.x of
                9..85: if contactindex<>2 then command2(2);
             235..311: if contactindex<>5 then command2(5);
            end;
  154..170: if mouse.x>309 then done:=true;
 end;
 idletime:=0;
end;

procedure printxy2(x1,y1,m,n,o: integer; s: string);
var letter,j2,a,index,t: integer;
label skipit;
begin
 t:=tcolor;
 brighter:=false;
 j2:=0;
 for j:=1 to length(s) do
  begin
   if s[j]=#200 then
    begin
     if brighter then brighter:=false else brighter:=true;
     goto skipit;
    end;
   letter:=ord(s[j]);
   if (brighter) then
    case ship.options[4] of
     0: tcolor:=m;
     1: tcolor:=n;
     2: tcolor:=o;
    end
    else tcolor:=o;
   bkcolor:=m;
   inc(j2);
   index:=1;
   for i:=1 to 6 do
    begin
     for a:=4 to 7 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j2*5+7-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j2*5+7-a]:=bkcolor;
     dec(tcolor,2);
     inc(i);
     for a:=0 to 3 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j2*5+3-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j2*5+3-a]:=bkcolor;
     inc(index);
     dec(tcolor,2);
    end;
   for i:=1 to 6 do screen[y1+i,x1+j2*5+4]:=bkcolor;
   delay(tslice div 3);
   index:=1;
   bkcolor:=0;
   if (brighter) then
    case ship.options[4] of
     0: tcolor:=m;
     1: tcolor:=n;
     2: tcolor:=o;
    end
    else tcolor:=o;
   for i:=1 to 6 do
    begin
     for a:=4 to 7 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j2*5+7-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j2*5+7-a]:=bkcolor;
     dec(tcolor,2);
     inc(i);
     for a:=0 to 3 do
      if testbit(font[letter,index],a) then screen[y1+i,x1+j2*5+3-a]:=tcolor
       else if bkcolor<255 then screen[y1+i,x1+j2*5+3-a]:=bkcolor;
     inc(index);
     dec(tcolor,2);
    end;
   for i:=1 to 6 do screen[y1+i,x1+j2*5+4]:=bkcolor;
skipit:
  end;
 tcolor:=t;
end;

function parsestatement(y,n,p,q,s: integer): integer;
var done: boolean;
    a,b,c,i2,letter: integer;
begin
 str1^:=r^[n].response;
 i:=1;
 j:=1;
 repeat
  if str1^[i]=#201 then
   begin
    inc(i);
    a:=ord(str1^[i])+35-48;
    b:=20;
    while ship.crew[a].name[b]=' ' do dec(b);
    for c:=1 to b do
     begin
      letter:=ord(ship.crew[a].name[c]);
      case chr(letter) of
       ' ' ..'"': letter:=letter-31;
       ''''..'?': letter:=letter-35;
       'A' ..'Z': letter:=letter-36;
       else letter:=1;
      end;
      str2^[j]:=chr(letter);
      inc(j);
     end;
    dec(j);
   end
  else str2^[j]:=str1^[i];
  inc(j);
  inc(i);
 until i>ord(str1^[0]);
 str2^[0]:=chr(j-1);
 done:=false;
 repeat
  str1^:=str2^;
  i:=56;
  if ord(str1^[0])>56 then
   begin
    while str1^[i]<>#1 do dec(i);
    str2^:=copy(str1^,i+1,ord(str1^[0])-i);
    str1^[0]:=chr(i-1);
   end else done:=true;
  printxy2(12,135+y*6,p,q,s,str1^);
  inc(y);
  if y=8 then
   begin
    tcolor:=207;
    printxy(146,191,'MORE');
    i2:=4;
    mouseshow;
    repeat
     for j:=183 to 188 do
      fillchar(screen[j,15],288,0);
     inc(i2);
     if i2=28 then i2:=4;
     if i2<16 then
      for j:=192 to 207 do
       colors[j,2]:=round((j-191)/16*4*i2)
     else
      for j:=192 to 207 do
       colors[j,2]:=round((j-191)/16*4*(31-i2));
     set256colors(colors);
     delay(tslice*5);
    until (fastkeypressed) or (mouse.getstatus(left));
    while fastkeypressed do readkey;
    mousehide;
    printxy(146,191,'    ');
    tcolor:=s;
    y:=1;
    for j:=141 to 188 do
     fillchar(screen[j,15],288,0);
   end;
 until done;
 parsestatement:=y;
end;

procedure checkstring(p,q,s: integer);
var index,index2,i,i2: integer;
begin
 mousehide;
 for i:=135 to 181 do
  fillchar(screen[i,15],288,0);
 for i:=182 to 187 do
  fillchar(screen[i,61],100,0);
 tcolor:=s;
 printxy(12,135,question);
 i:=20;
 while question[i]=' ' do dec(i);
 if i=0 then
  begin
   mouseshow;
   exit;
  end;
 question[0]:=chr(i);
 for j:=1 to i do
  case question[j] of
   ' ' ..'"': question[j]:=chr(ord(question[j])-31);
   ''''..'?': question[j]:=chr(ord(question[j])-35);
   'A' ..'Z': question[j]:=chr(ord(question[j])-36);
   '%': question[j]:=#55;
   else question[j]:=#1;
  end;
 index:=0;
 repeat
  inc(index);
  j:=pos(#1+question+#1,c^[index].keyword);
 until ((j>0) and (checkevent(c^[index].event))) or (c^[index].rcode=0);
 runevent(c^[index].runevent);
 fillchar(question,21,ord(' '));
 question[0]:=#20;
 cursorx:=1;
 if j=0 then
  begin
   mouseshow;
   exit;
  end;
 i:=1;
 while r^[i].index<>c^[index].index do inc(i);
 case c^[index].rcode of
  1: parsestatement(1,i,p,q,s);
  2: begin
      j:=1;
      while r^[i+j].index=c^[index].index do inc(j);
      parsestatement(1,i+random(j),p,q,s);
     end;
  3: begin
      index2:=i;
      i2:=1;
      repeat
       i2:=parsestatement(i2,index2,p,q,s);
       inc(index2);
      until r^[i].index<>r^[index2].index;
      printxy(12,182,'SUBJECT:');
     end;
 end;
 if (c^[index].runevent=20000) or (c^[index].index=2) then
  begin
   for i:=182 to 187 do
    fillchar(screen[i,12],200,0);
   contactindex:=-1;
  end;
 mouseshow;
end;

procedure processkey2;
var ans: char;
    old: integer;
begin
 ans:=upcase(readkey);
 tcolor:=31;
 case ans of
  'A'..'Z',' ','0'..'9','''','-': if contactindex>-1 then
        begin
         if cursorx<20 then
          begin
           for j:=20 downto cursorx do question[j]:=question[j-1];
           question[cursorx]:=ans;
           inc(cursorx);
          end else question[cursorx]:=ans;
         mousehide;
         printxy(57,182,question);
         mouseshow;
        end;
   #8: if contactindex>-1 then
        begin
         if cursorx>1 then dec(cursorx);
         for j:=cursorx to 19 do question[j]:=question[j+1];
         question[20]:=' ';
         mousehide;
         printxy(57,182,question);
         mouseshow;
        end;
   #0: if contactindex>-1 then
        begin
         ans:=readkey;
         case ans of
          #77: if cursorx<20 then inc(cursorx);
          #75: if cursorx>1 then dec(cursorx);
          #83: begin
                for j:=cursorx to 19 do question[j]:=question[j+1];
                mousehide;
                printxy(57,182,question);
                mouseshow;
               end;
         end;
        end;
  #13: if contactindex>-1 then
        begin
         old:=contactindex;
         checkstring(95,176,170);
         if contactindex=-1 then
          begin
           contactindex:=old;
           erasecursor;
           contactindex:=-1;
          end;
        end;
  #27: done:=true;
  '`': bossmode;
 end;
 idletime:=0;
end;

procedure mainloop2;
begin
 repeat
  if fastkeypressed then processkey2;
  findmouse2;
  if idletime=maxidle then screensaver;
  if contactindex>-1 then
   begin
    bkcolor:=95;
    printxy(cursorx*5+52,182,question[cursorx]);
    delay(tslice*2);
    bkcolor:=0;
    printxy(cursorx*5+52,182,question[cursorx]);
    delay(tslice*2);
   end
  else delay(tslice*4);
 until done;
end;

procedure readycrewdata;
begin
 mousehide;
 savescreen;
 fading;
 loadscreen('data\charcom.vga');
 loadpal('data\charcom.pal');
 oldt1:=t1;
 bkcolor:=0;
 tcolor:=170;
 printxy(12,182,'CONVERSE WITH CREW MEMBER:');
 done:=false;
 contactindex:=-1;
 fillchar(question,21,ord(' '));
 question[0]:=#20;
 new(temp);
 new(str1);
 new(str2);
 new(r);
 new(c);
 cursorx:=1;
 displaycrewnames;
 fadein2;
 mouseshow;
end;

procedure conversewithcrew;
begin
 readycrewdata;
 mainloop2;
 dispose(str2);
 dispose(str1);
 dispose(temp);
 dispose(c);
 dispose(r);
 removedata;
end;

{*****************************************************************************}

procedure loadbackground(n: integer);
var f: file of screentype;
    str1: string[2];
    t: ^screentype;
begin
 new(t);
 str(((n-1) div 2)+1,str1);
 loadpal('data\back'+str1+'.pal');
 set256colors(colors);
 assign(f,'data\back'+str1+'.vga');
 reset(f);
 if ioresult<>0 then errorhandler('back'+str1+'.vga',1);
 read(f,t^);
 if ioresult<>0 then errorhandler('back'+str1+'.vga',5);
 close(f);
 y:=((n-1) mod 2)*100;
 for i:=10 to 110 do
  for j:=0 to 319 do
   if (backgr^[i,j]=255) then screen[i,j]:=t^[i-10+y,j];
 dispose(t);
end;

procedure loadalienpic(n: integer);
var f: file of screentype;
    str1: string[2];
    t: ^screentype;
    p: ^paltype;
    fp: file of paltype;
begin
 str(n,str1);
 new(p);
 assign(fp,'data\alien'+str1+'.pal');
 reset(fp);
 if ioresult<>0 then errorhandler('data\alien'+str1+'.pal',1);
 read(fp,p^);
 if ioresult<>0 then errorhandler('data\alien'+str1+'.pal',5);
 close(fp);
 for j:=160 to 255 do colors[j]:=p^[j];
 set256colors(colors);
 dispose(p);
 new(t);
 assign(f,'data\alien'+str1+'.vga');
 reset(f);
 if ioresult<>0 then errorhandler('alien'+str1+'.vga',1);
 read(f,t^);
 if ioresult<>0 then errorhandler('alien'+str1+'.vga',5);
 close(f);
 for i:=10 to 110 do
  for j:=0 to 160 do
   if (backgr^[i,j+70]=255) and (t^[i-10,j]>0) then screen[i,j+70]:=t^[i-10,j];
 dispose(t);
end;

procedure getshipinfo;
var confile: file of alientype;
    done: boolean;
    temp: alientype;
    str1: string[11];
    r: real;
begin
 assign(confile,'save\contacts.dta');
 reset(confile);
 if ioresult<>0 then errorhandler('contacts.dta',1);
 done:=false;
 repeat
  read(confile,temp);
  if ioresult<>0 then done:=true;
  if (not done) and (temp.id>0) and (temp.id=ship.wandering.alienid) then done:=true;
 until done;
 close(confile);
 printxy(217,20,temp.name);
 printxy(217,20,temp.name);
 printxy(217,30,'VIDCOM');
 printxy(217,40,systems[tempplan^[temp.id].system].name);
 str1:=chr(hi(temp.techmin)+48)+'.'+chr(lo(temp.techmin)+48);
 printxy(217,50,'MIN TECH: '+str1);
 str1:=chr(hi(temp.techmax)+48)+'.'+chr(lo(temp.techmax)+48);
 printxy(217,60,'MAX TECH: '+str1);
 printxy(217,70,'STATUS:');
 if temp.war then printxy(252,70,'WAR')
  else printxy(252,70,'PEACE');
 if temp.anger=0 then
  begin
   if temp.congeniality>20 then i:=3
    else i:=1;
  end
 else
  begin
   r:=temp.congeniality/temp.anger;
   if r<0.3 then i:=5
   else if r<0.7 then i:=4
   else if round(r)=1 then i:=2
   else i:=3;
  end;
 case i of
  1: str1:='AFRAID';
  2: str1:='INDIFFERENT';
  3: str1:='FRIENDLY';
  4: str1:='ANGRY';
  5: str1:='VIOLENT';
 end;
 printxy(217,80,str1);
end;

procedure displayoptions3;
var done: boolean;
    j: integer;
begin
 tcolor:=28;
 mousehide;
 for i:=125 to 189 do
  fillchar(screen[i,15],278,0);
 case commlevel of
  -2: begin
       printxy(15,125,'CONTINUE TRANSACTION WITH ALIENS.');
       j:=1;
       while (j<8) and (locals^[j].id<>curplan) do inc(j);
       if (j<8) and (locals^[j].id=curplan) then tcolor:=26
        else tcolor:=16;
       printxy(25,135,'1. PLANET: SONIC/VISUAL/RADIO');
       j:=1;
       while (j<8) and (locals^[j].id<32000) do inc(j);
       if j=1 then tcolor:=16 else tcolor:=26;
       printxy(25,145,'2. SYSTEM: RADIO/SUBSPACE');
       if ship.wandering.alienid<16000 then
        tcolor:=26 else tcolor:=16;
       printxy(25,155,'3. SHIP HAIL: VIDCOM');
       tcolor:=28;
      end;
 -1: begin
      printxy(15,125,'CONTACT ALIEN:');
      y:=0;
      for j:=1 to 6 do
       if locals^[j].id<32000 then
        begin
         inc(y);
         printxy(25,125+y*10,chr(y+48)+'. '+locals^[j].name);
        end;
      if y=0 then printxy(25,135,'NO ALIENS CONTACTED IN SYSTEM.');
     end;
  0: begin
      tcolor:=28;
      printxy(12,182,'SUBJECT:');
     end;
end;
 mouseshow;
end;

procedure getcontactindex;
var i: integer;
begin
 if index=5000 then;          {************************ we got problems!!!!}
 i:=0;
 if locals^[index].conindex=0 then
  begin
   i:=1099;
   loadbackground(random(numback)+1);
   loadalienpic(12+random(4));
  end
 else
  begin
   i:=locals^[index].conindex;
   loadbackground(random(numback)+1);
   loadalienpic(i);
   i:=i+999;
  end;
 contactindex:=i;
end;

procedure command3(com: integer);
begin
 case commlevel of
  -2: begin
       if com>3 then exit;
       case com of
        1: begin
            j:=1;
            while (j<7) and (locals^[j].id<>curplan) do inc(j);
            if (j<7) and (locals^[j].id=curplan) then
             begin
              index:=j;
              commlevel:=0;
              getcontactindex;
              displayoptions3;
             end
            else
             begin
              index:=0;
              commlevel:=-2;
              displayoptions3;
             end;
           end;
        2: begin
            j:=1;
            while (j<7) and (locals^[j].id<32000) do inc(j);
            if j=1 then commlevel:=-2 else commlevel:=-1;
            displayoptions3;
          end;
        3: if ship.wandering.alienid<16000 then
            begin
             commlevel:=0;
             index:=5000;
             getcontactindex;
             displayoptions3;
            end
           else
            begin
             commlevel:=-2;
             displayoptions3;
            end;
       end;
      end;
 -1: if locals^[com].id<32000 then
      begin
       commlevel:=0;
       index:=com;
       getcontactindex;
       displayoptions3;
      end;
 end;
 if contactindex>-1 then loadconversation;
end;

procedure getinfo;
var str1: string[11];
    r: real;
begin
 if infomode then
  begin
   infomode:=false;
   mousehide;
   for i:=20 to 105 do
    mymove(t^[i],screen[i,222],20);
   mouseshow;
   exit;
  end;
 if contactindex=0 then exit;
 infomode:=true;
 mousehide;
 for i:=20 to 105 do
  mymove(screen[i,222],t^[i],20);
 mouseshow;
 tcolor:=31;
 bkcolor:=255;
 if index=5000 then getshipinfo
 else begin
  printxy(217,20,locals^[index].name);
  if curplan=locals^[index].id then
   begin
    if hi(locals^[index].techmax)>=3 then printxy(217,30,'RADIO')
     else printxy(217,30,'VISUAL');
   end
  else printxy(217,30,'SUBSPACE');
  printxy(217,40,systems[tempplan^[curplan].system].name);
  str1:=chr(hi(locals^[index].techmin)+48)+'.'+chr(lo(locals^[index].techmin)+48);
  printxy(217,50,'MIN TECH: '+str1);
  str1:=chr(hi(locals^[index].techmax)+48)+'.'+chr(lo(locals^[index].techmax)+48);
  printxy(217,60,'MAX TECH: '+str1);
  printxy(217,70,'STATUS:');
  if locals^[index].war then printxy(252,70,'WAR')
   else printxy(252,70,'PEACE');
  if locals^[index].anger=0 then
   begin
    if locals^[index].congeniality>20 then i:=3
     else i:=1;
   end
  else
   begin
    r:=locals^[index].congeniality/locals^[index].anger;
    if r<0.3 then i:=5
    else if r<0.7 then i:=4
    else if round(r)=1 then i:=2
    else i:=3;
   end;
  case i of
   1: str1:='AFRAID';
   2: str1:='INDIFFERENT';
   3: str1:='FRIENDLY';
   4: str1:='ANGRY';
   5: str1:='VIOLENT';
  end;
  printxy(217,80,str1);
 end;
end;

procedure findmouse3;
var button: boolean;
begin
 if mouse.getstatus(left) then button:=true else button:=false;
 if not button then exit;
 case mouse.x of
  308..317: if (mouse.y>142) and (mouse.y<169) then done:=true;
  247..267: case mouse.y of
             135..141: command3(1);
             145..151: command3(2);
             155..161: command3(3);
             165..171: command3(4);
             175..181: command3(5);
             185..191: command3(6);
             105..110: if contactindex>0 then getinfo;
            end;
   15..290: case mouse.y of
             135..141: command3(1);
             145..151: command3(2);
             155..161: command3(3);
             165..171: command3(4);
             175..181: command3(5);
             185..191: command3(6);
            end;
 end;
 idletime:=0;
end;

procedure processkey3;
var ans: char;
begin
 ans:=upcase(readkey);
 tcolor:=26;
 case ans of
  'A'..'Z',' ','0'..'9','''','-': if contactindex>-1 then
        begin
         if cursorx<20 then
          begin
           for j:=20 downto cursorx do question[j]:=question[j-1];
           question[cursorx]:=ans;
           inc(cursorx);
          end else question[cursorx]:=ans;
         mousehide;
         printxy(57,182,question);
         mouseshow;
        end;
   #8: if contactindex>-1 then
        begin
         if cursorx>1 then dec(cursorx);
         for j:=cursorx to 19 do question[j]:=question[j+1];
         question[20]:=' ';
         mousehide;
         printxy(57,182,question);
         mouseshow;
        end;
   #0: if contactindex>-1 then
        begin
         ans:=readkey;
         case ans of
          #77: if cursorx<20 then inc(cursorx);
          #75: if cursorx>1 then dec(cursorx);
          #83: begin
                for j:=cursorx to 19 do question[j]:=question[j+1];
                mousehide;
                printxy(57,182,question);
                mouseshow;
               end;
         end;
        end;
  #13: if contactindex>-1 then checkstring(47,31,28);
  #27: done:=true;
  '`': bossmode;
 end;
 idletime:=0;
end;

procedure mainloop3;
begin
 repeat
  findmouse3;
  if fastkeypressed then processkey3;
  if idletime=maxidle then screensaver;
  if contactindex>-1 then
   begin
    bkcolor:=47;
    printxy(cursorx*5+52,182,question[cursorx]);
    delay(tslice*2);
    bkcolor:=0;
    printxy(cursorx*5+52,182,question[cursorx]);
    delay(tslice*2);
   end
  else delay(tslice*4);
 until done;
end;

procedure getlocals;
var confile: file of alientype;
    done: boolean;
    temp: alientype;
begin
 assign(confile,'save\contacts.dta');
 reset(confile);
 if ioresult<>0 then errorhandler('contacts.dta',1);
 i:=0;
 done:=false;
 for j:=1 to 6 do locals^[j].id:=32000;
 repeat
  read(confile,temp);
  if ioresult<>0 then done:=true;
  if (not done) and (temp.id>0) and (tempplan^[temp.id].system=tempplan^[curplan].system) then
   begin
    inc(i);
    locals^[i]:=temp;
   end;
 until (done) or (i=7);
 if i=7 then errorhandler('Too many aliens in system.',6);
 close(confile);
end;

procedure readydata3;
begin
 mousehide;
 savescreen;
 fading;
 loadscreen('data\com.vga');
 loadpal('data\com.pal');
 mymove(screen,backgr^,16000);
 for i:=10 to 110 do
  for j:=0 to 319 do
   if (screen[i,j]=255) and ((i+j) mod 2=0) then screen[i,j]:=8
    else if (screen[i,j]=255) then screen[i,j]:=0;
 new(tmpm);
 for i:=0 to 15 do
  begin
   mymove(screen[i+130,20],tmpm^[i],4);
   fillchar(screen[i+130,20],16,0);
  end;
 mousesetcursor(tmpm^);
 dispose(tmpm);
 done:=false;
 bkcolor:=0;
 tcolor:=28;
 infomode:=false;
 fillchar(question,21,ord(' '));
 question[0]:=#20;
 commlevel:=-2;
 contactindex:=-1;
 oldt1:=t1;
 cursorx:=1;
 new(temp);
 new(locals);
 new(str1);
 new(str2);
 new(c);
 new(r);
 new(t);
 getlocals;
 displayoptions3;
 fadein;
 mouseshow;
end;

procedure reloadbackground;
var vgafile: file of screentype;
begin
 assign(vgafile,'data\cloud.vga');
 reset(vgafile);
 if ioresult<>0 then errorhandler('data\cloud.vga',1);
 read(vgafile,backgr^);
 if ioresult<>0 then errorhandler('data\cloud.vga',5);
 close(vgafile);
end;

procedure continuecontact;
begin
 readydata3;
 mainloop3;
 dispose(str2);
 dispose(str1);
 dispose(temp);
 dispose(locals);
 dispose(c);
 dispose(r);
 dispose(t);
 reloadbackground;
 mouse.setmousecursor(1);
 removedata;
end;

begin
end.
