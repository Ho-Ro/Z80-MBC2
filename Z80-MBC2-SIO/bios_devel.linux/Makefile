# Linux Makefile to build the cpm3.sys file for Z80-MBC2
# Used for BIOS development and test

# Execute CP/M 2.2 commands on Linux with tnylpo
# https://gitlab.com/gbrein/tnylpo/
# An utility to run CP/M-80 programs under Unix/Linux
# CP/M file names must be lower case (path do not care)

TNYLPO =  ./TNYLPO

GENCPM3 = $(TNYLPO) CPM.COM/gencpm3
LINK =    $(TNYLPO) CPM.COM/link
LOAD =    $(TNYLPO) CPM.COM/load
MAC =     $(TNYLPO) CPM.COM/mac
PIP =     $(TNYLPO) CPM.COM/pip
ZSM4 =    $(TNYLPO) CPM.COM/zsm4


# CP/M programs do not provide a reliable return value
# that can be used to exit the make process on error.
# -> output of ZSM4 is grepped for "Errors: 0" as success
# $(ZSM4) ... | tee /dev/tty | grep -q "Errors: 0"



.PHONY:		all
all:		cpmxldr.com testcpmx.com


# BIOS test #
# testcpmx.com boots the contained cpmx.sys from a running CP/M
# for CP/M 2.2 use the option [o] b/c cpmx.sys is a binary file
testcpmx.com:	bootsys.bin cpmx.sys
		@echo
		$(PIP) testcpmx.com=bootsys.bin[o],cpmx.sys[o]
		cp testcpmx.com tcx.com
		ls -l bootsys.bin *cpmx.*


# cpm3.sys #
# renamed to cpmx.sys, put it on A: and boot with the modified cpmldr3.com
cpmx.sys:	bnkbios3.spr bnkbdos3.spr resbdos3.spr gencpm.dat
		@echo
		$(GENCPM3) auto
		mv cpm3.sys cpmx.sys

bootsys.bin:	bootsys.rel
		@echo
		$(LINK) bootsys.bin=bootsys.rel

bootsys.rel:	bootsys.mac
		@echo -e \\n$(ZSM4) bootsys,bootsys.lis=bootsys.mac
		@$(ZSM4) bootsys,bootsys.lis=bootsys.mac | tee /dev/tty | grep -q "Errors: 0"


# CP/M boot loader #
# put cpmldr3.com as CPMLDR.com on the root of the SD card
cpmxldr.com:	cpmxldr.rel ldrbios.rel
		@echo
		$(LINK) cpmxldr=cpmxldr,ldrbios

# check the AUTOEXEC bit and load cpm3.sys (=0) or cpmx.sys (=1)
# to have a fallback solution for BIOS tests
cpmxldr.rel:	cpmxldr.mac
		@echo -e \\n$(ZSM4) cpmxldr,cpmxldr.lis=cpmxldr
		@$(ZSM4) cpmxldr,cpmxldr.lis=cpmxldr | tee /dev/tty | grep -q "Errors: 0"

ldrbios.rel:	ldrbios.mac
		@echo -e \\n$(ZSM4) ldrbios,ldrbios.lis=ldrbios
		@$(ZSM4) ldrbios,ldrbios.lis=ldrbios | tee /dev/tty | grep -q "Errors: 0"


# BIOS (banked and common part) #
bnkbios3.spr:	bioskrnl.rel boot.rel chario.rel move.rel scb.rel vdisk.rel
		@echo
		$(LINK) bnkbios3[B]=bioskrnl,boot,chario,move,scb,vdisk

# BIOS components #
bioskrnl.rel:	bioskrnl.mac config.lib
		@echo -e \\n$(ZSM4) bioskrnl,bioskrnl.lis=bioskrnl
		@$(ZSM4) bioskrnl,bioskrnl.lis=bioskrnl | tee /dev/tty | grep -q "Errors: 0"

boot.rel:	boot.mac config.lib
		@echo -e \\n$(ZSM4) boot,boot.lis=boot /DZPM=1
		@$(ZSM4) boot,boot.lis=boot /DZPM=1 | tee /dev/tty | grep -q "Errors: 0"

chario.rel:	chario.mac config.lib
		@echo -e \\n$(ZSM4) chario,chario.lis=chario
		@$(ZSM4) chario,chario.lis=chario | tee /dev/tty | grep -q "Errors: 0"

move.rel:	move.mac
		@echo -e \\n$(ZSM4) move,move.lis=move
		@$(ZSM4) move,move.lis=move | tee /dev/tty | grep -q "Errors: 0"

scb.rel:	scb.mac
		@echo -e \\n$(ZSM4) scb,scb.lis=scb
		@$(ZSM4) scb,scb.lis=scb | tee /dev/tty | grep -q "Errors: 0"

vdisk.rel:	vdisk.mac
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
		rm -f bnkbios3.spr cpmx.sys cpmxldr.com tcx.com testcpmx.com

