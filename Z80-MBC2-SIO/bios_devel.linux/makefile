# Linux Makefile to build the CPM3.SYS file for Z80-MBC2
# Used for BIOS development and test

# Execute CP/M 2.2 commands on Linux with tnylpo
# https://gitlab.com/gbrein/tnylpo/
# A utility to run CP/M-80 programs under Unix/Linux

TNYLPO = ./tnylpo -u


.PHONY:		all
all:		CPMLDR3.COM TESTCPMX.COM


# BIOS test #
# testcpmx.com boots the contained cpmx.sys from a running CP/M
# for CP/M 2.2 use the option [o] b/c cpmx.sys is a binary file
TESTCPMX.COM:	BOOTSYS.COM CPMX.SYS
		$(TNYLPO) CPM.COM/PIP TESTCPMX.COM=BOOTSYS.COM,CPMX.SYS[o]
		cp TESTCPMX.COM TCX.COM
		ls -l BOOTSYS.COM *CPMX.*


# CPM3.SYS #
# renamed to CPMX.SYS, put it on A: and boot with the modified CPMLDR3.COM
CPMX.SYS:	BNKBIOS3.SPR BNKBDOS3.SPR RESBDOS3.SPR GENCPM.DAT
		$(TNYLPO) CPM.COM/GENCPM3 AUTO
		mv CPM3.SYS CPMX.SYS

BOOTSYS.COM:	BOOTSYS.REL
		$(TNYLPO) CPM.COM/LINK BOOTSYS

BOOTSYS.REL:	BOOTSYS.MAC
		$(TNYLPO) CPM.COM/ZSM4 BOOTSYS,BOOTSYS.LIS=BOOTSYS.MAC


# CP/M boot loader #
# put cpmldr3.com as CPMLDR.COM on the root of the SD card
CPMLDR3.COM:	CPMLDR3.REL LDRBIOS.REL
		$(TNYLPO) CPM.COM/LINK CPMLDR3=CPMLDR3,LDRBIOS

# check the AUTOEXEC bit and load CPM3.SYS (=0) or CPMX.SYS (=1)
# to have a fallback solution for BIOS tests
CPMLDR3.REL:	CPMLDR3.MAC
		$(TNYLPO) CPM.COM/ZSM4 CPMLDR3,CPMLDR3.LIS=CPMLDR3

LDRBIOS.REL:	LDRBIOS.MAC
		$(TNYLPO) CPM.COM/ZSM4 LDRBIOS,LDRBIOS.LIS=LDRBIOS


# BIOS (banked and common part) #
BNKBIOS3.SPR:	BIOSKRNL.REL BOOT.REL CHARIO.REL MOVE.REL SCB.REL VDISK.REL
		$(TNYLPO) CPM.COM/LINK BNKBIOS3[B]=BIOSKRNL,BOOT,CHARIO,MOVE,SCB,VDISK

# BIOS components #
BIOSKRNL.REL:	BIOSKRNL.MAC CONFIG.LIB
		$(TNYLPO) CPM.COM/ZSM4 BIOSKRNL,BIOSKRNL.LIS=BIOSKRNL

BOOT.REL:	BOOT.MAC CONFIG.LIB
		$(TNYLPO) CPM.COM/ZSM4 BOOT,BOOT.LIS=BOOT /DZPM=1

CHARIO.REL:	CHARIO.MAC CONFIG.LIB
		$(TNYLPO) CPM.COM/ZSM4 CHARIO,CHARIO.LIS=CHARIO

MOVE.REL:	MOVE.MAC
		$(TNYLPO) CPM.COM/ZSM4 MOVE,MOVE.LIS=MOVE

SCB.REL:	SCB.MAC
		$(TNYLPO) CPM.COM/ZSM4 SCB,SCB.LIS=SCB

VDISK.REL:	VDISK.MAC
		$(TNYLPO) CPM.COM/ZSM4 VDISK,VDISK.LIS=VDISK


Z80TYPE.COM:	Z80TYPE.ASM
		$(TNYLPO) CPM.COM/MAC Z80TYPE
		$(TNYLPO) CPM.COM/LOAD Z80TYPE


.PHONY:	clean
clean:
		rm -f *~ *.LIS *.REL *.SYM *.HEX *.PRN

.PHONY:	distclean
distclean:	clean
		rm -f BNKBIOS3.SPR CPMX.SYS BOOTSYS.COM CPMLDR3.COM TCX.COM TESTCPMX.COM

