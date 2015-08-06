program makecomputerlogs;


type
 titletype=record
	      id   : Integer;
	      text : string[49];
	   end;	   
 logtype= array[0..24] of string[49];

var
 l: logtype;
 title: titletype;
 ft: text;

 i,j,a: integer;

 f: file of logtype;
 f2: file of titletype;

begin
   assign(ft,'makedata\log.txt');
   reset(ft);
   assign(f,'data\log.dta');
   rewrite(f);
   assign(f2,'data\titles.dta');
   rewrite(f2);
   for j:=0 to 49 do
   begin
      title.id := j;
      readln(ft,title.text);
      if length(title.text)<49 then
	 for a:=length(title.text)+1 to 49 do title.text[a]:=' ';
      title.text[0]:=#49;
      for a:=1 to 49 do
	 case title.text[a] of
	   ' ' ..'"': title.text[a]:=chr(ord(title.text[a])-31);
	   ''''..'?': title.text[a]:=chr(ord(title.text[a])-35);
	   'A' ..'Z': title.text[a]:=chr(ord(title.text[a])-36);
	   'a' ..'z': title.text[a]:=chr(ord(title.text[a])-40);
	   '%'	    : title.text[a]:=#55;
	   '^'	    : title.text[a]:=#200;
	   '@'	    : title.text[a]:=#201;
	 else title.text[a]:=#1;
	 end;	     
      writeln(title.text);
      write(f2,title);
      
      for i:=0 to 24 do
      begin
	 readln(ft,l[i]);
	 if length(l[i])<49 then
	    for a:=length(l[i])+1 to 49 do l[i,a]:=' ';
	 l[i,0]:=#49;

	 for a:=1 to 49 do
	    case l[i,a] of
	      ' ' ..'"': l[i,a]:=chr(ord(l[i,a])-31);
	      ''''..'?': l[i,a]:=chr(ord(l[i,a])-35);
	      'A' ..'Z': l[i,a]:=chr(ord(l[i,a])-36);
	      'a' ..'z': l[i,a]:=chr(ord(l[i,a])-40);
	      '%'	: l[i,a]:=#55;
	      '^'	: l[i,a]:=#200;
	      '@'	: l[i,a]:=#201;
	    else l[i,a]:=#1;
	    end;	

	 writeln(l[i]);

      end;
      readln(ft);
      write(f,l);
   end;
   close(ft);
   close(f);
end.
