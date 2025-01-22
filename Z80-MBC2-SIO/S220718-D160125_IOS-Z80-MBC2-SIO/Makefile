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
BUILDOPTIONS = bootloader=no_bootloader,eeprom=keep,baudrate=default,SerialBuf=SB256_64,pinout=standard,BOD=2v7,LTO=Os_flto,clock=$(CLK)MHz_external

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
IOS_HEX = $(BUILD)/$(PRJ).ino.hex

# target in intel hex format
TARGET = $(PRJ)_$(CLK)MHz.hex


.PHONY: all
all: $(TARGET)


$(TARGET): $(INO) $(SOURCE) $(HEADER) Makefile
	arduino-cli compile --export-binaries --warnings all --fqbn $(FQBN_BO) $(INO)
	@-cp $(IOS_HEX) $@
	@ls -l *.hex


.PHONY: program
program: $(TARGET)
	avrdude -pm32 -U $<


.PHONY: clean
clean:
	-rm -Rf build *.lst

.PHONY: distclean
distclean: clean
	-rm -f $(TARGET)
