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

ifeq ($(ATMEGA),32)
  BOD=4v0
  FUSES_OPT = -Ulfuse:w:0x3F:m -Uhfuse:w:0xC6:m
  LOCK_OPT = -Ulock:w:0xEF:m
endif

ifeq ($(ATMEGA),1284)
  BOD=4v3
  FUSES_OPT = -Ulfuse:w:0xF7:m -Uhfuse:w:0xD6:m -Uefuse:w:0xFC:m
  LOCK_OPT = -Ulock:w:0xEF:m
endif


# build options, copied from Arduino GUI build
BUILDOPTIONS = bootloader=uart0,eeprom=keep,baudrate=115200,SerialBuf=SB256_64,pinout=standard,BOD=$(BOD),LTO=Os_flto,clock=$(CLK)MHz_external

# fully qualified board name with build options
FQBN_BO = "$(FQBN):$(BUILDOPTIONS)"

# build directory inside the project directory
BUILD = build/$(subst :,.,$(FQBN))

# source code for the Arduino project
INO = $(PRJ).ino
HEADER = *.h
SOURCE = *.cpp
BOOTLOADER = urboot_m$(ATMEGA).hex
HEX = $(BUILD)/*.hex
LST = *.lst $(BUILD)/*.lst

# build result
IOS_INO_HEX = $(BUILD)/$(PRJ).ino.hex
IOS_INO_BL_HEX = $(BUILD)/$(PRJ).ino.with_bootloader.hex

# targets in intel hex format
SPEC = ATmega$(ATMEGA)_$(CLK)MHz
TARGET = $(PRJ)_$(SPEC).hex
TARGET_BL = $(PRJ)_BL_$(SPEC).hex
TARGETS = $(TARGET) $(TARGET_BL)


.PHONY: IOS
IOS: $(TARGETS)

.PHONY: all
all:
	$(MAKE) -C .. IOS32 IOS1284

$(TARGET) : $(INO) $(SOURCE) $(HEADER) Makefile
	arduino-cli compile --export-binaries --warnings all --fqbn $(FQBN_BO) $(INO)
	@-cp $(IOS_INO_HEX) $@
	@unix2dos --keepdate --quiet $@

$(TARGET_BL) : $(TARGET)
	@./hexcat $(TARGET) $(BOOTLOADER) -o $@
	@unix2dos --keepdate --quiet $@
	@ls -l $(PRJ)_*.hex


iLoad.h: iLoad.asm Makefile
	z80assembler -c iLoad.asm
	sed -i 's/iLoadAddr/boot_A_StrAddr/g; s/iLoadSize/boot_A_Size/g; s/iLoad\[\]/boot_A_\[\] PROGMEM/g' $@


# update AVR via serial bootloader
.PHONY: update
update: $(TARGET)
	avrdude -pm$(ATMEGA) -P $(PORT) -c urclock -U $<

# update AVR via arduino serial bootloader
.PHONY: upload
upload: $(TARGET)
	arduino-cli upload -p $(PORT) --fqbn $(FQBN_BO) $(INO)


# update AVR via SPI programmer
.PHONY: flash
flash: $(TARGET_BL)
	avrdude -P $(PORT) -pm$(ATMEGA) -U$< $(LOCK_OPT)

# set fuses via SPI programmer
.PHONY: fuses
fuses:
	avrdude -P $(PORT) -pm$(ATMEGA) $(FUSES_OPT)


.PHONY: clean
clean:
	-rm -Rf build *.lst

.PHONY: distclean
distclean: clean
	-rm -f $(PRJ)_*.hex
