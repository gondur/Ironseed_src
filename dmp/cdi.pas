{ -------------------------------------------------------------------------- }
{                                                                            }
{                                  CDI.PAS                                   }
{                                  -------                                   }
{                                                                            }
{                         (C) 1993 Jussi Lahdenniemi                         }
{         Original C file (C) 1993 Otto Chrons                               }
{                                                                            }
{ Channel Distributor unit file                                              }
{                                                                            }
{ -------------------------------------------------------------------------- }

unit cdi;

interface

type    PCDIdevice = ^TCDIdevice;
        TCDIdevice = Record
          setsample, playsample, setvolume, setfrequency, setlinearrate,
          setposition, setpanning, setmastervolume, pausechannel,
          resumechannel, stopchannel, pauseall, resumeall, poll, getdelta,
          download, unload, getvolume, getfrequency, getposition, getpan,
          getsample, setupch : pointer;
        end;

var     cdiStatus  : word;

{#if 0
	GLOBAL	cdiInit:FAR, cdiRegister:FAR, cdiClose:FAR

	GLOBAL	cdiSetInstrument:FAR, cdiPlayNote:FAR, cdiStopNote:FAR
	GLOBAL	cdiSetVolume:FAR, cdiSetFrequency:FAR, cdiSetLinear:FAR, cdiSetPosition:FAR
	GLOBAL	cdiPan:FAR, cdiSetMasterVolume:FAR, cdiPause:FAR, cdiResume:FAR
	GLOBAL	cdiPauseAll:FAR, cdiResumeAll:FAR, cdiPoll:FAR, cdiGetDelta:FAR
#endif}

Function  cdiInit:integer;
Function  cdiRegister(cdi:PCDIdevice;firstch,lastch:longint):integer;
Procedure cdiClose;
Procedure cdiSetInstrument(channel:longint;inst:pointer);
Procedure cdiPlayNote(channel:longint;freq:longint;volume:longint);
Procedure cdiStopNote(channel:longint);
Procedure cdiSetVolume(channel:longint;volume:longint);
Procedure cdiSetFrequency(channel:longint;freq:longint);
Procedure cdiSetPosition(channel:longint;pos:longint);
Procedure cdiSetPan(channel:longint;pan:longint);
Procedure cdiSetMasterVolume(channel,volume:longint);
Procedure cdiPause(channel:longint);
Procedure cdiResume(channel:longint);
Procedure cdiPauseAll(channel:longint);
Procedure cdiResumeAll(channel:longint);
Function  cdiPoll(channel:longint):integer;
Function  cdiGetDelta(channel:longint):longint;
Procedure cdiDownloadSample(channel:longint;sample,sampletag:pointer;len:longint);
Procedure cdiUnloadSamples(channel:longint);

Function  cdiSetLinear(channel:longint;linearRate:longint):integer;
Function  cdiGetVolume(channel:longint):word;
Function  cdiGetFrequency(channel:longint):longint;
Function  cdiGetPosition(channel:longint):longint;
Function  cdiGetPan(channel:longint):integer;
Function  cdiGetInstrument(channel:longint):pointer;
Function  cdiSetupChannels(channel,count:longint;volTable:pointer):integer;

implementation

Function  cdiInit:integer; external;
Function  cdiRegister(cdi:PCDIdevice;firstch,lastch:longint):integer; external;
Procedure cdiClose; external;
Procedure cdiSetInstrument(channel:longint;inst:Pointer); external;
Procedure cdiPlayNote(channel:longint;freq:longint;volume:longint); external;
Procedure cdiStopNote(channel:longint); external;
Procedure cdiSetVolume(channel:longint;volume:longint); external;
Procedure cdiSetFrequency(channel:longint;freq:longint); external;
Procedure cdiSetPosition(channel:longint;pos:longint); external;
Procedure cdiSetPan(channel:longint;pan:longint); external;
Procedure cdiSetMasterVolume(channel,volume:longint); external;
Procedure cdiPause(channel:longint); external;
Procedure cdiResume(channel:longint); external;
Procedure cdiPauseAll(channel:longint); external;
Procedure cdiResumeAll(channel:longint); external;
Function  cdiPoll(channel:longint):integer; external;
Function  cdiGetDelta(channel:longint):longint; external;
Procedure cdiDownloadSample(channel:longint;sample,sampletag:pointer;len:longint); external;
Procedure cdiUnloadSamples(channel:longint); external;

Function  cdiSetLinear(channel:longint;linearRate:longint):integer; external;
Function  cdiGetVolume(channel:longint):word; external;
Function  cdiGetFrequency(channel:longint):longint; external;
Function  cdiGetPosition(channel:longint):longint; external;
Function  cdiGetPan(channel:longint):integer; external;
Function  cdiGetInstrument(channel:longint):pointer; external;
Function  cdiSetupChannels(channel,count:longint;volTable:pointer):integer; external;

{$L cdi.obj}

end.
