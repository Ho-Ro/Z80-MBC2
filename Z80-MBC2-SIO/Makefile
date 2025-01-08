#################################
# Makefile for project Z80-MBC2 #
#    build with arduino-cli     #
#  under Debian Linux (stable)  #
#################################

# IOS project
PRJ = S220718-R290823_IOS-Z80-MBC2

# IOS-LITE project
# PRJ = S220618_IOS-LITE-Z80-MBC2


# fully qualified board name for ATmega32
FQBN = MightyCore:avr:32

# default clock 16 MHz
# CLK = 16

# overclock 20 MHz
# https://hackaday.io/project/159973-z80-mbc2-a-4-ics-homebrew-z80-computer/details
CLK = 20


#############################################
## normally no need to change something below
#############################################

# build options, copied from Arduino GUI build
BUILDOPTIONS = bootloader=uart0,eeprom=keep,baudrate=default,SerialBuf=SB256_64,pinout=standard,BOD=2v7,LTO=Os_flto,clock=$(CLK)MHz_external

# fully qualified board name with build options
FQBN_BO = "$(FQBN):$(BUILDOPTIONS)"

# build directory inside the project directory
BUILD = $(PRJ)/build/$(subst :,.,$(FQBN))

# source code for the Arduino project
INO = $(PRJ)/$(PRJ).ino

# target in intel hex format
HEX = $(BUILD)/$(PRJ).ino.hex
HEX_BL = $(BUILD)/$(PRJ).ino.with_bootloader.hex
HEX_BL_CLK = $(PRJ)/$(PRJ).ino.with_bootloader_$(CLK)MHz.hex

.PHONY: compile
compile: $(HEX_BL_CLK)

$(HEX_BL_CLK): $(INO) Makefile
	arduino-cli compile --export-binaries --warnings all --fqbn $(FQBN_BO) $(INO)
	-rm $(HEX_BL_CLK)
	-ln $(HEX_BL) $(HEX_BL_CLK)


.PHONY: burn-bootloader
burn-bootloader: $(HEX_BL_CLK)
	#arduino-cli burn-bootloader --fqbn $(FQBN_BO) -
	avrdude -pm32 -U $(HEX_BL_CLK)
