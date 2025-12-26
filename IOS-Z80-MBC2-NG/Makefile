####################################
# Makefile for project Z80-MBC2-NG #
#      build with arduino-cli      #
#    under Debian Linux (stable)   #
####################################

# IOS project
PRJ = IOS-Z80-MBC2-NG

ATMEGA32=32

# set the frequency of the MBC2 XTAL
# clock 16 MHz
# overclock to 20 MHz, 22 MHz, 24 MHz
# https://hackaday.io/project/159973-z80-mbc2-a-4-ics-homebrew-z80-computer/details
MBC2_CLK = 20

# serial port for uploading via avrdude or arduino-cli
PORT = /dev/ttyUSB0

#############################################
## normally no need to change something below
#############################################

# use std clock value unless Makefile was called "CLK=nn make ..."
ifeq ($(CLK),)
  CLK = $(MBC2_CLK)
endif

# target is ATmega32 unless Makefile was called "ATMEGA=xx make ..."
ifeq ($(ATMEGA),)
  ATMEGA = $(ATMEGA32)
endif

# fully qualified board name for ATmega
FQBN = MightyCore:avr:$(ATMEGA)


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
TARGET = $(PRJ)_ATmega$(ATMEGA)_$(CLK)MHz.hex
TARGET_BL = $(PRJ)_ATmega$(ATMEGA)_BL_$(CLK)MHz.hex
ALL_TARGETS = $(TARGET) $(TARGET_BL)


.PHONY: all
all: $(ALL_TARGETS)


$(TARGET_BL) : $(INO) $(SOURCE) $(HEADER) Makefile
	arduino-cli compile --export-binaries --warnings all --fqbn $(FQBN_BO) $(INO)
	@-cp $(IOS_INO_BL_HEX) $@
	@unix2dos --keepdate --quiet $@

$(TARGET) : $(TARGET_BL)
	@-cp $(IOS_INO_HEX) $@
	@unix2dos --keepdate --quiet $@
	@ls -l *.hex


# iLoad bootloader
# iLoad.asm contains the disassembled and commented source code
# of the hex bytes in the array boot_A_[]
# iLoad.h provides these two consts:
#   const uint16_t iLoadAddr = 0xFD10;
#   const uint16_t iLoadSize = 618;
#   const uint8_t iLoad[] = { ... }
# for $(BOOT_A__H) it must be changed to:
#   const uint16_t boot_A_StrAddr = 0xFD10;
#   const uint16_t boot_A_Size = 618;
#   const uint8_t boot_A_[] PROGMEM = { ... }

iLoad.h: iLoad.asm Makefile
	z80assembler -c iLoad.asm
	sed -i 's/iLoadAddr/boot_A_StrAddr/g; s/iLoadSize/boot_A_Size/g; s/iLoad\[\]/boot_A_\[\] PROGMEM/g' $@


# update AVR via serial bootloader
.PHONY: update
update: $(TARGET)
	avrdude -pm32 -P $(PORT) -c urclock -U $<

# update AVR via arduino serial bootloader
.PHONY: upload
upload: $(TARGET)
	arduino-cli upload -p $(PORT) --fqbn $(FQBN_BO) $(INO)

# update AVR via SPI programmer
.PHONY: flash
flash: $(TARGET_BL)
	avrdude -pm32 -P $(PORT) -U $<


.PHONY: clean
clean:
	-rm -Rf build *.lst

.PHONY: distclean
distclean: clean
	-rm -f *.hex
