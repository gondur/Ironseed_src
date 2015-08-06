Unit GetCPU;
{$O+}

Interface

Function GetCPUtype:Integer;
Function inV86:Boolean;

Implementation

Function GetCPUtype:Integer;
  Begin
  GetCPUtype:=1;
  end;
// External;
Function inV86:Boolean;// External;
Begin
inV86:=true;
end;
{$L GETCPU.OBJ}
{$L CHECKV86.OBJ}

end.
