#################################
# Makefile for project Z80-MBC2 #
#    build with arduino-cli     #
#  under Debian Linux (stable)  #
#################################

# IOS project
PRJ = S220718-D160125_IOS-Z80-MBC2-SIO


# fully qualified board name for ATmega32
FQBN = MightyCore:avr:32


# set the frequency of the MBC2 XTAL
# clock 16 MHz
# overclock 20 MHz
# https://hackaday.io/project/159973-z80-mbc2-a-4-ics-homebrew-z80-computer/details
MBC2_CLK = 20


#############################################
## normally no need to change something below
#############################################

# use std clock value unless Makefile was called "CLK=nn make ..."
ifeq ($(CLK),)
  CLK = $(MBC2_CLK)
endif


# build options, copied from Arduino GUI build
#BUILDOPTIONS = bootloader=no_bootloader,eeprom=keep,baudrate=default,SerialBuf=SB256_64,pinout=standard,BOD=2v7,LTO=Os_flto,clock=$(CLK)MHz_external
BUILDOPTIONS = bootloader=uart0,eeprom=keep,baudrate=115200,SerialBuf=SB256_64,pinout=standard,BOD=2v7,LTO=Os_flto,clock=$(CLK)MHz_external
# fully qualified board name with build options
FQBN_BO = "$(FQBN):$(BUILDOPTIONS)"

# build directory inside the project directory
BUILD = build/$(subst :,.,$(FQBN))

# source code for the Arduino project
INO = $(PRJ).ino
HEADER = *.h
SOURCE = *.cpp
HEX = $(BUILD)/*.hex
LST = *.lst $(BUILD)/*.lst

# build result
IOS_INO_HEX = $(BUILD)/$(PRJ).ino.hex
IOS_INO_BL_HEX = $(BUILD)/$(PRJ).ino.with_bootloader.hex

# targets in intel hex format
TARGET = $(PRJ)_$(CLK)MHz.hex
TARGET_BL = $(PRJ)_BL_$(CLK)MHz.hex
ALL_TARGETS = $(TARGET) $(TARGET_BL)


.PHONY: all
all: $(ALL_TARGETS)


$(TARGET_BL) : $(INO) $(SOURCE) $(HEADER) Makefile
	arduino-cli compile --export-binaries --warnings all --fqbn $(FQBN_BO) $(INO)
	@-cp $(IOS_INO_BL_HEX) $@

$(TARGET) : $(TARGET_BL)
	@-cp $(IOS_INO_HEX) $@
	@ls -l *.hex


# update AVR via serial bootloader
.PHONY: update
update: $(TARGET)
	avrdude -pm32 -c urclock -U $<


.PHONY: clean
clean:
	-rm -Rf build *.lst

.PHONY: distclean
distclean: clean
	-rm -f *.hex
