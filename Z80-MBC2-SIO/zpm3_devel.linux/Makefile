# Linux Makefile to build the zpm3 system for Z80-MBC2
# Used for BIOS development and test

# Execute CP/M 2.2 commands on Linux with tnylpo
# https://gitlab.com/gbrein/tnylpo/
# An utility to run CP/M-80 programs under Unix/Linux
# CP/M file names must be lower case (path do not care)

TNYLPO =  ../CPM.COM/TNYLPO

GENCPM3 = $(TNYLPO) ../CPM.COM/gencpm3
LINK =    $(TNYLPO) ../CPM.COM/link
LOAD =    $(TNYLPO) ../CPM.COM/load
MAC =     $(TNYLPO) ../CPM.COM/mac
PIP =     $(TNYLPO) ../CPM.COM/pip
ZSM4 =    $(TNYLPO) ../CPM.COM/zsm4

BIOS = ../bios_devel.linux


.PHONY: all
all: bnkbdos3.spr resbdos3.spr autotog.com clrhist.com


bnkbdos3.spr: bnkbdos3.rel
	$(LINK) bnkbdos3[b]

resbdos3.spr: resbdos3.rel
	$(LINK) resbdos3[b]


bnkbdos3.rel: bzpm0.z80 bzpm1.z80 bzpm2.z80 bzpm3.z80 bzpm4.z80 bzpm5.z80 bzpm6.z80 bzpm7.z80
	$(ZSM4) bnkbdos3=bzpm0.z80

resbdos3.rel: rzpm0.z80
	$(ZSM4) resbdos3=rzpm0.z80


autotog.com: autotog.rel
	$(LINK) autotog

autotog.rel: autotog.z80
	$(ZSM4) =autotog.z80


clrhist.com: clrhist.rel
	$(LINK) clrhist

clrhist.rel: clrhist.z80
	$(ZSM4) =clrhist.z80


.PHONY: install
install: $(BIOS)/bnkbdos3.spr $(BIOS)/resbdos3.spr

$(BIOS)/bnkbdos3.spr: bnkbdos3.spr
	cp $< $@

$(BIOS)/resbdos3.spr: resbdos3.spr
	cp $< $@

.PHONY: clean
clean:
	rm -f *~ *.rel *.sym *.lis

.PHONY: distclean
distclean: clean
	rm -f bnkbdos.spr resbdos.spr
