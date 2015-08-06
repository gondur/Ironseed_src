(****************************************************************************

                                 DET_SB.PAS
                                 ----------

                          (C) 1993 Jussi Lahdenniemi

Turbo/Borland pascal unit header file for SB detection routines.
Original C header by Otto Chrons

****************************************************************************)

unit det_SB; { (C) 1993 Jussi Lahdenniemi }

{$O+}

interface
uses MCP;

Function  detectSB(SCard:PSoundCard):Integer;
Function  detectSBpro(SCard:PSoundCard):Integer;
Function  detectSB16(SCard:PSoundCard):Integer;

implementation

{$L detectSB.OBJ}

Function  detectSB(SCard:PSoundCard):Integer; external;
Function  detectSBpro(SCard:PSoundCard):Integer; external;
Function  detectSB16(SCard:PSoundCard):Integer; external;

end.
