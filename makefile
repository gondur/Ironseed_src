
export WINEPREFIX=/home/xen/.wine-ironseed/
WINEEXE=wine

FIXNAMES=python code/fixnames.py

DMPSRC=$(shell find dmp -name "*.pas")
MAINSRC=$(shell find code -name "*.pas") $(DMPSRC)
CREWGENSRC=code/crewgen.pas code/data.pas code/gmouse.pas code/saveload.pas code/display.pas code/utils.pas code/modplay.pas $(DMPSRC)
INTROSRC=code/intro.pas code/version.pas code/gmouse.pas code/modplay.pas $(DMPSRC)
ISSRC=code/is.pas

TPC=$(WINEEXE) g:/bp/bin/tpc.exe /Tg:\\bp\\bin
TPCFLAGS=/B /Q /M /DUSE_EMS /L /GD /\$$N+ /\$$G+ /\$$S- /\$$I-
TPCTOOLFLAGS=/B /Q /M /DUSE_EMS /L /GD /\$$N+ /\$$G+ /\$$S- /\$$I+
# /Ecode /Ocode /Udmp /Idmp

CREWCONVS=data/conv0001.dta data/conv0002.dta data/conv0003.dta data/conv0004.dta data/conv0005.dta data/conv0006.dta
RACECONVS=data/conv1001.dta data/conv1002.dta data/conv1003.dta data/conv1004.dta data/conv1005.dta data/conv1006.dta data/conv1007.dta data/conv1008.dta data/conv1009.dta data/conv1010.dta data/conv1011.dta
SPECCONVS=data/conv1100.dta data/conv1101.dta data/conv1102.dta data/conv1103.dta
all: convmake logmake main.exe crewgen.exe intro.exe config.exe detsound.exe is.exe $(RACECONVS) $(SPECCONVS) $(CREWCONVS) data/log.dta datafiles

convmake: makedata/convmake.d makedata/data.d
	dmd makedata/convmake.d makedata/data.d

logmake: makedata/logmake.d makedata/data.d
	dmd makedata/logmake.d makedata/data.d

data/conv0001.dta: makedata/crewcon1.txt convmake
	./convmake makedata/crewcon1.txt data/conv0001
data/conv0002.dta: makedata/crewcon2.txt convmake
	./convmake makedata/crewcon2.txt data/conv0002
data/conv0003.dta: makedata/crewcon3.txt convmake
	./convmake makedata/crewcon3.txt data/conv0003
data/conv0004.dta: makedata/crewcon4.txt convmake
	./convmake makedata/crewcon4.txt data/conv0004
data/conv0005.dta: makedata/crewcon5.txt convmake
	./convmake makedata/crewcon5.txt data/conv0005
data/conv0006.dta: makedata/crewcon6.txt convmake
	./convmake makedata/crewcon6.txt data/conv0006

data/conv1001.dta: makedata/sengcon1.txt convmake
	./convmake makedata/sengcon1.txt data/conv1001
data/conv1002.dta: makedata/dpahcon1.txt convmake
	./convmake makedata/dpahcon1.txt data/conv1002
data/conv1003.dta: makedata/aardcon1.txt convmake
	./convmake makedata/aardcon1.txt data/conv1003
data/conv1004.dta: makedata/ermicon1.txt convmake
	./convmake makedata/ermicon1.txt data/conv1004
data/conv1005.dta: makedata/titecon1.txt convmake
	./convmake makedata/titecon1.txt data/conv1005
data/conv1006.dta: makedata/quacon1.txt convmake
	./convmake makedata/quacon1.txt  data/conv1006
data/conv1007.dta: makedata/scavcon1.txt convmake
	./convmake makedata/scavcon1.txt data/conv1007
data/conv1008.dta: makedata/iconcon1.txt convmake
	./convmake makedata/iconcon1.txt data/conv1008
data/conv1009.dta: makedata/guilcon1.txt convmake
	./convmake makedata/guilcon1.txt data/conv1009
data/conv1010.dta: makedata/mochcon1.txt convmake
	./convmake makedata/mochcon1.txt data/conv1010
data/conv1011.dta: makedata/voidcon1.txt convmake
	./convmake makedata/voidcon1.txt data/conv1011
data/conv1100.dta: makedata/tek2con1.txt convmake
	./convmake makedata/tek2con1.txt data/conv1100
data/conv1101.dta: makedata/tek3con1.txt convmake
	./convmake makedata/tek3con1.txt data/conv1101
data/conv1102.dta: makedata/tek4con1.txt convmake
	./convmake makedata/tek4con1.txt data/conv1102
data/conv1103.dta: makedata/tek5con1.txt convmake
	./convmake makedata/tek5con1.txt data/conv1103

data/log.dta: makedata/logs.txt logmake
	./logmake makedata/logs.txt data/titles.dta data/log.dta 

# /CD /$$N+ /$$G+ /$$S- /$$I- 
main.exe: $(MAINSRC)
	$(TPC) $(TPCFLAGS) code\\main.pas #| linefix
	cat code/main.exe code/main.ovr > main.exe
	$(FIXNAMES) code
	touch main.exe --reference=code/main.exe

crewgen.exe: $(CREWGENSRC)
	$(TPC) $(TPCFLAGS) code\\crewgen.pas #| linefix
	$(FIXNAMES) code
	cp code/crewgen.exe ./crewgen.exe

intro.exe: $(INTROSRC)
	$(TPC) $(TPCFLAGS) code\\intro.pas #| linefix
	$(FIXNAMES) code
	cp code/intro.exe ./intro.exe

is.exe: $(ISSRC)
	$(TPC) $(TPCFLAGS) code\\is.pas #| linefix
	$(FIXNAMES) code
	cp code/is.exe ./is.exe

config.exe: code/config.pas makedata/win.pas
	$(TPC) $(TPCFLAGS) code\\config.pas #| linefix
	$(FIXNAMES) code
	cp code/config.exe ./config.exe

detsound.exe: code/detsound.pas
	$(TPC) $(TPCFLAGS) code\\detsound.pas #| linefix
	$(FIXNAMES) code
	cp code/detsound.exe ./detsound.exe

clean:
	rm -f code/*.tpu code/*.exe code/*.ovr 
	rm -f obj/*.o
	rm -f main.exe crewgen.exe intro.exe
	rm -f convmake logmake

code/itemmake.exe: makedata/itemmake.pas
	$(TPC) $(TPCTOOLFLAGS) makedata\\itemmake.pas #| linefix
	$(FIXNAMES) code
code/creamake.exe: makedata/creamake.pas
	$(TPC) $(TPCTOOLFLAGS) makedata\\creamake.pas #| linefix
	$(FIXNAMES) code
code/cargmake.exe: makedata/cargmake.pas
	$(TPC) $(TPCTOOLFLAGS) makedata\\cargmake.pas #| linefix
	$(FIXNAMES) code
code/scanmake.exe: makedata/scanmake.pas
	$(TPC) $(TPCTOOLFLAGS) makedata\\scanmake.pas #| linefix
	$(FIXNAMES) code

data/iteminfo.dta: code/itemmake.exe makedata/iteminfo.txt
	$(WINEEXE) code/itemmake.exe
	$(FIXNAMES) code data
data/creation.dta: code/creamake.exe makedata/creation.txt
	$(WINEEXE) code/creamake.exe
	$(FIXNAMES) code data
data/cargo.dta: code/cargmake.exe makedata/cargo.txt
	$(WINEEXE) code/cargmake.exe
	$(FIXNAMES) code data
data/scan.dta: code/scanmake.exe makedata/scandata.txt
	$(WINEEXE) code/scanmake.exe
	$(FIXNAMES) code data .

datafiles: data/iteminfo.dta data/creation.dta data/cargo.dta data/scandata.dta
