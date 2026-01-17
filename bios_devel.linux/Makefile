# Linux Makefile to build the cpm3.sys file for Z80-MBC2
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


# CP/M programs do not provide a reliable return value
# that can be used to exit the make process on error.
# -> output of ZSM4 is grepped for "Errors: 0" as success
# $(ZSM4) ... | tee /dev/tty | grep -q "Errors: 0"



.PHONY:		all
all:		cpmxldr.com testcpm3.com


# BIOS test #
# testcpmx.com boots the contained cpmx.sys from a running CP/M
# for CP/M 2.2 use the option [o] b/c cpmx.sys is a binary file
testcpm3.com:	bootsys.com cpm3.sys
		@echo
		$(PIP) testcpm3.com=bootsys.com[o],cpm3.sys[o]
		ls -l bootsys.com *cpm3.*


# cpm3.sys #
# cpm3.sys, put it as cpmx.sys on A: and boot with the modified cpmxldr.com
cpm3.sys:	bnkbios3.spr bnkbdos3.spr resbdos3.spr gencpm.dat
		@echo
		$(GENCPM3) auto display > gencpm.log

bootsys.com:	bootsys.rel
		@echo
		$(LINK) bootsys

bootsys.rel:	bootsys.mac
		@echo -e \\n$(ZSM4) bootsys,bootsys.lis=bootsys.mac /dLINUX
		@$(ZSM4) bootsys,bootsys.lis=bootsys.mac /dLINUX | tee /dev/tty | grep -q "Errors: 0"


# CP/M boot loader #
# put cpmxldr.com on the root of the SD card
cpmxldr.com:	cpmxldr.rel ldrbios.rel
		@echo
		$(LINK) cpmxldr=cpmxldr,ldrbios

# check the USER KEY and load cpmx.sys (not pressed) or cpm3.sys (pressed)
# to have a fallback solution for BIOS tests
cpmxldr.rel:	cpmxldr.mac
		@echo -e \\n$(ZSM4) cpmxldr,cpmxldr.lis=cpmxldr
		@$(ZSM4) cpmxldr,cpmxldr.lis=cpmxldr | tee /dev/tty | grep -q "Errors: 0"

ldrbios.rel:	ldrbios.mac iosopcod.lib
		@echo -e \\n$(ZSM4) ldrbios,ldrbios.lis=ldrbios
		@$(ZSM4) ldrbios,ldrbios.lis=ldrbios | tee /dev/tty | grep -q "Errors: 0"


# BIOS (banked and common part) #
bnkbios3.spr:	bioskrnl.rel boot.rel chario.rel move.rel scb.rel vdisk.rel
		@echo
		$(LINK) bnkbios3[B]=bioskrnl,boot,chario,move,scb,vdisk

# BIOS components, enable debugging with /dDBG=1 on ZSM4 cmd line #
bioskrnl.rel:	bioskrnl.mac
		@echo -e \\n$(ZSM4) bioskrnl,bioskrnl.lis=bioskrnl
		@$(ZSM4) bioskrnl,bioskrnl.lis=bioskrnl | tee /dev/tty | grep -q "Errors: 0"

# enable ZPM3 message with /dZPM3=1
boot.rel:	boot.mac iosopcod.lib
		@echo -e \\n$(ZSM4) boot,boot.lis=boot /dZPM3=1
		@$(ZSM4) boot,boot.lis=boot /dZPM3=1 | tee /dev/tty | grep -q "Errors: 0"

chario.rel:	chario.mac iosopcod.lib
		@echo -e \\n$(ZSM4) chario,chario.lis=chario
		@$(ZSM4) chario,chario.lis=chario | tee /dev/tty | grep -q "Errors: 0"

move.rel:	move.mac iosopcod.lib
		@echo -e \\n$(ZSM4) move,move.lis=move
		@$(ZSM4) move,move.lis=move | tee /dev/tty | grep -q "Errors: 0"

scb.rel:	scb.mac
		@echo -e \\n$(ZSM4) scb,scb.lis=scb
		@$(ZSM4) scb,scb.lis=scb | tee /dev/tty | grep -q "Errors: 0"

vdisk.rel:	vdisk.mac iosopcod.lib
		@echo -e \\n$(ZSM4) vdisk,vdisk.lis=vdisk
		@$(ZSM4) vdisk,vdisk.lis=vdisk | tee /dev/tty | grep -q "Errors: 0"


z80type.com:	z80type.ASM
		$(MAC) z80type
		$(LOAD) z80type


.PHONY:	clean
clean:
		rm -f *~ *.lis *.rel *.bin *.sym *.hex *.prn

.PHONY:	distclean
distclean:	clean
		rm -f bnkbios3.spr cpm3.sys cpmxldr.com testcpm3.com

