program makecrew;

type
 crewtype=record
   name: string[20];
   phy,men,emo,status,skilllevel: byte;
   xp: integer;
  end;
var
 j,emo,phy,men: integer;
 ft: text;
 i: string[6];


begin
 assign(ft,'makedata\crew.txt');
 rewrite(ft);
 randomize;
 for j:=1 to 30 do
  begin
   phy:=random(100);
   men:=random(100);
   emo:=random(abs(175-men-phy));
   if emo>100 then emo:=emo mod 100;
   if random(100)<40 then i:='FEMALE' else i:='MALE';
   writeln(ft,phy:3,men:8,emo:8,random(8):8,i:8);
  end;
 close(ft);
end.