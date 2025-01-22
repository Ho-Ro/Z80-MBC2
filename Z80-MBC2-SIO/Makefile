#
# Makefile to build the AVR IOS and CP/M BIOS for Z80-MBC2 with I2C SIO module
#

AVR_IOS = S220718-D160125_IOS-Z80-MBC2-SIO
CPM_BIOS = bios_devel.linux

.PHONY: all
all:	BIOS IOS16 IOS20

.PHONY: BIOS
BIOS:
	$(MAKE) -C $(CPM_BIOS)

.PHONY: IOS16
IOS16:
	CLK=16 $(MAKE) -C $(AVR_IOS)

.PHONY: IOS20
IOS20:
	CLK=20 $(MAKE) -C $(AVR_IOS)

.PHONY: clean
clean:
	$(MAKE) -C $(AVR_IOS) clean
	$(MAKE) -C $(CPM_BIOS) clean
