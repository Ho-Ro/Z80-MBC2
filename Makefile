#
# Makefile to build the AVR IOS and CP/M BIOS for Z80-MBC2-NG
#

AVR_IOS = IOS-Z80-MBC2-NG
CPM_BIOS = bios_devel.linux

.PHONY: all
all:	BIOS IOS16 IOS20 IOS24

.PHONY: BIOS
BIOS:
	$(MAKE) -C $(CPM_BIOS)

.PHONY: IOS16
IOS16:
	CLK=16 $(MAKE) -C $(AVR_IOS)

.PHONY: IOS20
IOS20:
	CLK=20 $(MAKE) -C $(AVR_IOS)

.PHONY: IOS24
IOS24:
	CLK=24 $(MAKE) -C $(AVR_IOS)

.PHONY: clean
clean:
	$(MAKE) -C $(AVR_IOS) clean
	$(MAKE) -C $(CPM_BIOS) clean

.PHONY: update
update:
	$(MAKE) -C $(AVR_IOS) update
