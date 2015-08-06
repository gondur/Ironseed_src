program testmove;


var
 t,s: array[0..1023] of byte;


begin
 fillchar(s,1024,0);
 move(s,t,1024);
end.