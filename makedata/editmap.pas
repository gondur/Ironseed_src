program mapeditor;

uses crt, graph, graphics;

type
 maptype= array[0..254,0..254] of byte;
 tempscreentype= array[0..224,0..224] of byte;
var
 i,j,a,b,x,y,xc,yc,x3,y3,c,d: integer;
 map: ^maptype;
 ans: char;
 curx,cury: integer;
 done: boolean;
 str1,str2: string[3];
 facingdir,x1,x2,y1,y2,f,e,dx,g,h,dy,dx2,dy2: real;
 locx,locy: integer;
 temp: ^tempscreentype;

procedure loadmap;
var fm: file of maptype;
begin
 assign(fm,'data\map001.dta');
 reset(fm);
 read(fm,map^);
 close(fm);
end;

procedure savemap;
var fm: file of maptype;
begin
 assign(fm,'data\map001.dta');
 reset(fm);
 write(fm,map^);
 close(fm);
end;

procedure readydata;
var fi: file of iconarraytype;
begin
 assign(fi,'data\icons.vga');
 reset(fi);
 read(fi,icons);
 close(fi);
 new(map);
 new(temp);
 loadmap;
 done:=false;
 curx:=2;
 cury:=2;
 tcolor:=63;
 bkcolor:=0;
 locx:=16;
 locy:=16;
 facingdir:=1.57;
end;

procedure draw2;
begin
 for i:=0 to 160 do
  mymove(temp^[i+locy,locx],screen[10+i,10],40);
end;

procedure redraw;
begin
 for a:=-3+curx to 2+curx do
  for b:=-3+cury to 2+cury do
   begin
    if a<0 then c:=255+a
     else if a>254 then c:=a-255
     else c:=a;
    if b<0 then d:=255+b
     else if b>254 then d:=b-255
     else d:=b;
    y:=(b-cury)*32+96;
    x:=(a-curx)*32+96;
    for i:=0 to 31 do
     mymove(icons[map^[d,c],i],temp^[y+i,x],8);
   end;
end;

procedure drawmap;
begin
 x3:=locx;
 f:=yc;
 e:=xc;
 for j:=0 to 119 do
  begin
   f:=f+dy;
   e:=e+dx;
   inc(x3);
   y3:=locy;
   g:=0;
   h:=0;
   for i:=0 to 119 do
    begin
     inc(y3);
     g:=g+dy2;
     h:=h+dx2;
     screen[round(f-g),round(e+h)]:=temp^[y3,x3];
     screen[round(f-g)+1,round(e+h)]:=temp^[y3,x3];
    end;
  end;
end;

procedure mainloop;
begin
 redraw;
 x1:=-60*cos(-facingdir);
 y1:=-60*sin(-facingdir);
 x2:=60*cos(-facingdir+1.57);
 y2:=60*sin(-facingdir+1.57);
 xc:=round(x1+x2)+160;
 yc:=round(y1+y2)+100;
 dx:=(x1+160-xc)/60;
 dy:=(y1+100-yc)/60;
 dx2:=cos(facingdir);
 dy2:=sin(facingdir);
 repeat
  drawmap;
    ans:=readkey;
    case ans of
     #0: begin
          ans:=readkey;
          case ans of
           #72: begin
                 locx:=locx+round(7*cos(facingdir));
                 locy:=locy+round(7*sin(facingdir));
                 if locx>31 then
                   begin
                    if curx=254 then curx:=0 else inc(curx);
                    locx:=locx-32;
                    redraw;
                   end
                 else if locx<0 then
                   begin
                    if curx=0 then curx:=254 else dec(curx);
                    locx:=locx+32;
                    redraw;
                   end;
                 if locy>31 then
                   begin
                    if cury=254 then cury:=0 else inc(cury);
                    locy:=locy-32;
                    redraw;
                   end
                 else if locy<0 then
                   begin
                    if cury=0 then cury:=254 else dec(cury);
                    locy:=locy+32;
                    redraw;
                   end;
                end;
           #77: begin
                 facingdir:=facingdir+0.314;
                 if facingdir>6.28 then facingdir:=facingdir-6.28;
                 x1:=-60*cos(-facingdir);
                 y1:=-60*sin(-facingdir);
                 x2:=60*cos(-facingdir+1.57);
                 y2:=60*sin(-facingdir+1.57);
                 xc:=round(x1+x2)+160;
                 yc:=round(y1+y2)+100;
                 dx:=(x1+160-xc)/60;
                 dy:=(y1+100-yc)/60;
                 dx2:=cos(facingdir);
                 dy2:=sin(facingdir);
                end;
           #75: begin
                 facingdir:=facingdir-0.314;
                 if facingdir<0 then facingdir:=facingdir+6.28;
                 x1:=-60*cos(-facingdir);
                 y1:=-60*sin(-facingdir);
                 x2:=60*cos(-facingdir+1.57);
                 y2:=60*sin(-facingdir+1.57);
                 xc:=round(x1+x2)+160;
                 yc:=round(y1+y2)+100;
                 dx:=(x1+160-xc)/60;
                 dy:=(y1+100-yc)/60;
                 dx2:=cos(facingdir);
                 dy2:=sin(facingdir);
                end;
{          case ans of
           #72: if locy<4 then
                  begin
                   locy:=31;
                   if cury=0 then cury:=254 else dec(cury);
                   redraw;
                  end
                 else dec(locy,4);
           #80: if locy>27 then
                  begin
                   locy:=0;
                   if cury=254 then cury:=0 else inc(cury);
                   redraw;
                  end
                 else inc(locy,4);
           #75: if locx<4 then
                  begin
                   locx:=31;
                   if curx=0 then curx:=254 else dec(curx);
                   redraw;
                  end
                 else dec(locx,4);
           #77: if locx>27 then
                  begin
                   locx:=0;
                   if curx=254 then curx:=0 else inc(curx);
                   redraw;
                  end
                 else inc(locx,4);
           #77: if curx=254 then curx:=0 else inc(curx);
           #61: savemap;
           #59: done:=true;
}          end;
          str(curx:3,str1);
          str(cury:3,str2);
          printxy(280,20,str1+','+str2);
          str(locx:3,str1);
          str(locy:3,str2);
          printxy(280,30,str1+','+str2);
         end;
     '1': map^[cury,curx]:=random(2);
     '2': map^[cury,curx]:=random(5)+2;
     '3': map^[cury,curx]:=7;
     '4': map^[cury,curx]:=8;
     '5': map^[cury,curx]:=9;
     '6': map^[cury,curx]:=10;
     '7': map^[cury,curx]:=11;
     #27: done:=true;
    end;
 until done;
end;

procedure changes;
begin
{ for i:=0 to 254 do
  for j:=0 to 254 do
   map^[i,j]:=random(2);}
end;

begin
 readydata;
 changes;
 mainloop;
end.