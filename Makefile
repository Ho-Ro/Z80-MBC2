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




#############################################
## normally no need to change something below
#############################################

# build options, copied from Arduino GUI build
BUILDOPTIONS = bootloader=uart0,eeprom=keep,baudrate=default,pinout=standard,BOD=4v0,LTO=Os,clock=16MHz_external

# fully qualified board name with build options
FQBN_BO = "$(FQBN):$(BUILDOPTIONS)"

# build directory inside the project directory
BUILD = $(PRJ)/build/$(subst :,.,$(FQBN))

# source code for the Arduino project
INO = $(PRJ)/$(PRJ).ino

# target in intel hex format
HEX = $(BUILD)/$(PRJ).ino.hex


.PHONY: compile
compile: $(HEX)

$(HEX): $(INO) Makefile
	arduino-cli compile --export-binaries --warnings all --fqbn $(FQBN_BO) $(INO)


.PHONY: burn-bootloader
burn-bootloader: $(HEX)
	arduino-cli burn-bootloader --fqbn $(FQBN_BO) -
