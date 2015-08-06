program makeicons;
uses crt, graph, data;

type
 numtype= array[1..3] of byte;
const
 max = maxicons;
var
 index,curx,x,cury,i,j,a,curicon,backcolor,errcode,last,textcolor: integer;
 ans: char;
 lightindex,glowindex: integer;

procedure save;
var icondata: file of iconarray;
begin
 assign(icondata,'data\icons.cpr');
 reset(icondata);
 write(icondata,icons^);
 close(icondata);
end;

procedure load;
var icondata: file of iconarray;
begin
 assign(icondata,'data\icons.cpr');
 reset(icondata);
 read(icondata,icons^);
 close(icondata);
 last:=icons^[curicon,curx,cury];
end;

procedure drawicon;
begin
 for j:=0 to 16 do
  for i:=0 to 14 do
   begin
    if (curx=j) and (cury=i) then setfillstyle(11,icons^[curicon,j,i])
     else setfillstyle(1,icons^[curicon,j,i]);
    bar(j*10+15,i*10+15,j*10+24,i*10+24);
    screen[i+50,j+250]:=icons^[curicon,j,i];
   end;
 setfillstyle(1,last);
 bar(250,100,270,120);
end;

procedure writenum;
var s: string;
begin
 str(curicon,s);
 printxy(0,0,s+' ');
end;

procedure zoom;
var a,b: integer;
begin
 setfillstyle(0,0);
 bar(0,0,319,199);
  for a:=0 to max do
   for j:=0 to 16 do
    for i:=0 to 14 do
     screen[i+(a div 10)*18,j+(a mod 10)*20]:=icons^[a,j,i];
 readkey;
 bar(0,0,319,199);
 writenum;
end;

procedure copy;
var number: numtype;
    cursor,err,target,i,j: integer;
    strln: string;
begin
 printxy(0,0,'COPY FROM?');
 cursor:=1;
 for j:=1 to 3 do number[j]:=0;
 repeat
  for j:=1 to 3 do
   begin
    str(number[j],strln);
    printxy(50+j*5,0,strln);
   end;
  ans:=readkey;
  case ans of
   '0'..'9':
    begin
     val(ans,number[cursor],err);
     if cursor<3 then inc(cursor);
    end;
   #8:
    begin
     if cursor>1 then dec(cursor);
     number[cursor]:=0;
    end;
  end;
 until ans=#13;
 target:=number[1]*100+number[2]*10+number[3];
 for j:=0 to 16 do
  for i:=0 to 14 do
   icons^[curicon,j,i]:=icons^[target,j,i];
 printxy(0,0,'               ');
end;

procedure fillit2;
begin
 randomize;
 for i:=0 to 14 do
  for j:=0 to 16 do
   begin
    a:=random(3);
    if icons^[curicon,j,i]=last then icons^[curicon,j,i]:=icons^[curicon,j,i]+a;
   end;
end;

procedure fillit1;
begin
 randseed:=5129;
 for i:=0 to 14 do
  for j:=0 to 16 do
   begin
    a:=random(3);
    if icons^[curicon,j,i]=last then icons^[curicon,j,i]:=icons^[curicon,j,i]+a;
   end;
end;

procedure mainloop;
begin
 drawicon;
 ans:=' ';
 repeat
  if fastkeypressed then
   begin
   ans:=readkey;
   case upcase(ans) of
    #0:begin
        ans:=readkey;
        case ans of
         #72:if cury=0 then cury:=14 else dec(cury);
         #80:if cury=14 then cury:=0 else inc(cury);
         #75:if curx=0 then curx:=16 else dec(curx);
         #77:if curx=16 then curx:=0 else inc(curx);
        end;
       end;
    ' ':icons^[curicon,curx,cury]:=last;
    'C':copy;
    'S':save;
    'L':load;
    '1':begin icons^[curicon,curx,cury]:=0; last:=0; end;
    '2':begin icons^[curicon,curx,cury]:=16; last:=15; end;
    '3':begin icons^[curicon,curx,cury]:=32; last:=31; end;
    '4':begin icons^[curicon,curx,cury]:=48; last:=47; end;
    '5':begin icons^[curicon,curx,cury]:=64; last:=63; end;
    '6':begin icons^[curicon,curx,cury]:=80; last:=79; end;
    '7':begin icons^[curicon,curx,cury]:=96; last:=95; end;
    '8':begin icons^[curicon,curx,cury]:=112; last:=111; end;
    '9':begin icons^[curicon,curx,cury]:=128; last:=127; end;
    '0':begin icons^[curicon,curx,cury]:=128; last:=143; end;
    'Q':begin icons^[curicon,curx,cury]:=144; last:=159; end;
    'W':begin icons^[curicon,curx,cury]:=160; last:=175; end;
    'E':begin icons^[curicon,curx,cury]:=176; last:=191; end;
    'R':begin icons^[curicon,curx,cury]:=192; last:=207; end;
    'T':begin icons^[curicon,curx,cury]:=208; last:=223; end;
    'Y':begin icons^[curicon,curx,cury]:=208; last:=239; end;
    'U':begin icons^[curicon,curx,cury]:=208; last:=255; end;
    '+':begin inc(icons^[curicon,curx,cury]); last:=icons^[curicon,curx,cury]; end;
    '-':begin dec(icons^[curicon,curx,cury]); last:=icons^[curicon,curx,cury]; end;
    'S':save;
    'L':load;
    'Z':zoom;
    '>':begin if curicon<max then inc(curicon); writenum; end;
    '<':begin if curicon>0 then dec(curicon); writenum; end;
    '?':fillit2;
    '|':fillit1;
   end;
   drawicon;
  end;
 until ans=#59;
end;

procedure changes;
begin
{ for a:=0 to max do
  for i:=0 to 31 do
   for j:=0 to 31 do
    if icons[a,j,i]>63 then icons[a,j,i]:=(icons[a,j,i] mod 31)*2 + (icons[a,j,i] div 31)*31-2;
 }
{ for a:=0 to max do
  for i:=0 to 31 do
   for j:=0 to 31 do
    if icons[a,j,i] div 32=5 then icons[a,j,i]:=169;
}

end;

begin
 bkcolor:=0;
 tcolor:=63;
 new(icons);
 randomize;
 textcolor:=31; backcolor:=0;
 curicon:=0; curx:=0; cury:=0;
 tslice:=120;
 setfillstyle(0,0);
 bar(0,0,319,199);
 set256colors(colors);
 load;
 changes;
 writenum;
 mainloop;
 closegraph;
end.