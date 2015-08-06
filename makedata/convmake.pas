program makeconversation;

uses crt;


type
   converseindex = record
		      event,runevent,rcode,index : integer;
		      keyword			 : string[75];
		   end;				 
   responsetype	 = record
		      index    : integer;
		      response : string[255];
		   end;	       

var
 ft: text;
 i,j,err: integer;
 ans: char;
 done: boolean;
 c: converseindex;
 r: responsetype;
 f: file of converseindex;
 f2: file of responsetype;
 str1: string[5];
 fname,fname2: string[30];

procedure error(s: string);
begin
   clrscr;
   writeln(#10#10,s);
   halt;
end;

begin
   fname:=paramstr(2);
   fname2:=paramstr(1);
   assign(f,'data\'+fname+'.ind');
   rewrite(f);
   if ioresult<>0 then error('Error creating data\'+fname+'.ind.');
   assign(f2,'data\'+fname+'.dta');
   if ioresult<>0 then error('Error creating data\'+fname+'.dta.');
   rewrite(f2);
   assign(ft,fname2);
   reset(ft);
   if ioresult<>0 then error(fname2+' not found.');
   done:=false;
   repeat
      read(ft,c.event);
      if c.event>-500 then
      begin
	 read(ft,c.runevent);
	 read(ft,c.rcode);
	 read(ft,c.index);
	 for i:=1 to 5 do read(ft,ans);
	 fillchar(c.keyword,76,ord(' '));
	 readln(ft,c.keyword);
	 writeln(c.event,' ',c.runevent,' ',c.rcode,' ',c.index,' ',c.keyword);
	 c.keyword[0]:=#75;
	 for j:=1 to 75 do
	    case c.keyword[j] of
	      ' ' ..'"': c.keyword[j]:=chr(ord(c.keyword[j])-31);
	      ''''..'?': c.keyword[j]:=chr(ord(c.keyword[j])-35);
	      'A' ..'Z': c.keyword[j]:=chr(ord(c.keyword[j])-36);
	      '%'	: c.keyword[j]:=#55;
	      '^'	: c.keyword[j]:=#200;
	      '@'	: c.keyword[j]:=#201;
	    else c.keyword[j]:=#1;
	    end;	
	 write(f,c);
      end;
   until c.event=-500;
   readln(ft);
   repeat
      read(ft,r.index);
      if r.index<>-500 then
      begin
	 for i:=1 to 5 do read(ft,ans);
	 if c.index<10 then read(ft,ans);
	 readln(ft,r.response);
	 writeln(r.index,' ',r.response);
	 for j:=1 to length(r.response) do
	    case r.response[j] of
	      ' ' ..'"': r.response[j]:=chr(ord(r.response[j])-31);
	      ''''..'?': r.response[j]:=chr(ord(r.response[j])-35);
	      'A' ..'Z': r.response[j]:=chr(ord(r.response[j])-36);
	      '%'	: r.response[j]:=#55;
	      '^'	: r.response[j]:=#200;
	      '@'	: r.response[j]:=#201;
	    else r.response[j]:=#1;
	    end;
	 write(f2,r);
      end;
   until r.index=-500;
   close(ft);
   close(f);
   close(f2);
end.









