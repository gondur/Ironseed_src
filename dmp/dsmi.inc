(****************************************************************************

                                   DSMI.INC
                                   --------

                          (C) 1993 Jussi Lahdenniemi

Include file with a Uses-clause that includes all the necessary units of DSMI

****************************************************************************)

Uses MCP,AMP,CDI,Mixer,VDS

{$IFDEF DPMI}
,dpmiAPI
{$ELSE}
,SDI__DAC
{$ENDIF}

{$IFDEF USE_EMS}
,mcpems
{$ELSE}
,mcpreala
{$ENDIF}

