####################################
# Makefile for project Z80-MBC2-NG #
#      build with arduino-cli      #
#    under Debian Linux (stable)   #
####################################

# IOS project
PRJ = IOS-Z80-MBC2-NG

# target is 1284p unless Makefile was called "ATMEGA=xx make ..."
ifeq ($(ATMEGA),)
  ATMEGA = 1284p
endif

# serial port for uploading via avrdude or arduino-cli
URPORT = /dev/z80-mbc2
URSPEED = 500000
STKPORT = ch340

#############################################
## normally no need to change something below
#############################################

ifeq ($(ATMEGA),32)
  MBC2_CLK = 20
  FQBN = MightyCore:avr:32
  SERIALBUF = SB128_64
  BOD = 4v0
  FUSES_CMD = -Ulfuse:w:0x3F:m -Uhfuse:w:0xC6:m
  LOCK_CMD = -Ulock:w:0xEF:m
endif

ifeq ($(ATMEGA),1284)
  MBC2_CLK = 24
  FQBN = MightyCore:avr:1284
  VARIANT = variant=modelNonP,
  SERIALBUF = SB256_64
  BOD = 4v3
  FUSES_CMD = -Ulfuse:w:0xF7:m -Uhfuse:w:0xD6:m -Uefuse:w:0xFC:m
  LOCK_CMD = -Ulock:w:0xEF:m
endif

ifeq ($(ATMEGA),1284p)
  MBC2_CLK = 24
  FQBN = MightyCore:avr:1284
  VARIANT = variant=modelP,
  SERIALBUF = SB256_64
  BOD = 4v3
  FUSES_CMD = -Ulfuse:w:0xF7:m -Uhfuse:w:0xD6:m -Uefuse:w:0xFC:m
  LOCK_CMD = -Ulock:w:0xEF:m
endif

# use std clock value unless Makefile was called "CLK=nn make ..."
# set the frequency of the MBC2 XTAL
# 32: clock 16 MHz
# overclock to 20 MHz
# 1284(p): clock 20 MHz
# overclock to 24 MHz
# https://hackaday.io/project/159973-z80-mbc2-a-4-ics-homebrew-z80-computer/details

ifeq ($(CLK),)
  CLK = $(MBC2_CLK)
endif


# build options, copied from Arduino GUI build
BUILDOPTIONS = $(VARIANT)bootloader=uart0,eeprom=keep,baudrate=115200,SerialBuf=$(SERIALBUF),pinout=standard,BOD=$(BOD),LTO=Os_flto,clock=$(CLK)MHz_external

# fully qualified board name with build options
FQBN_BO = "$(FQBN):$(BUILDOPTIONS)"

# build directory inside the project directory (MightyCore.avr.nn)
BUILD = build/$(subst :,.,$(FQBN))

# source code for the Arduino project
INO = $(PRJ).ino
HEADER = *.h tinybasic2.h wozmon.h
SOURCE = *.cpp
BOOTLOADER = mbc2boot_m$(ATMEGA).hex
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
	$(MAKE) -C .. IOS32 IOS1284P

$(TARGET) : $(INO) $(SOURCE) $(HEADER) Makefile
	arduino-cli compile --export-binaries --warnings all --fqbn $(FQBN_BO) $(INO)
	@-cp $(IOS_INO_HEX) $@
	@unix2dos --keepdate --quiet $@

$(TARGET_BL) : $(TARGET)
	@./hexcat $(TARGET) $(BOOTLOADER) -o $@
	@unix2dos --keepdate --quiet $@
	@ls -l $(PRJ)_*.hex


tinybasic2.h: ../TinyBasic2/tinybasic2.z80
	$(MAKE) -C ../TinyBasic2
	cp ../TinyBasic2/tinybasic2.h $@


wozmon.h: ../WozMon/wozmon.asm
	$(MAKE) -C ../WozMon
	cp ../WozMon/wozmon.h $@


# update AVR via serial bootloader
.PHONY: update
update: $(TARGET)
	-killall picocom && sleep 1
	avrdude --part m$(ATMEGA) --port $(URPORT) --programmer urclock --baud $(URSPEED) -U $<

# update AVR via arduino serial bootloader
.PHONY: upload
upload: $(TARGET)
	arduino-cli upload --port $(URPORT) --fqbn $(FQBN_BO) $(INO)


# update AVR via SPI programmer
.PHONY: flash
flash: $(TARGET_BL)
	avrdude --part m$(ATMEGA) --port $(STKPORT) -U $< $(LOCK_CMD)

# set fuses via SPI programmer
.PHONY: fuses
fuses:
	avrdude --part m$(ATMEGA) --port $(STKPORT) $(FUSES_CMD)


.PHONY: clean
clean:
	-rm -Rf build *.lst

.PHONY: distclean
distclean: clean
	-rm -f $(PRJ)_*.hex
