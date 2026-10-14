PRJ = mbc2mon
IOS_NAME = MBC2Mon

SRC = $(PRJ).z80
HEX = $(PRJ).hex
LST = $(PRJ).lst
HEADER = $(PRJ).h

all: $(HEADER) monitor.z80

HEX2HEADER = ./hex2header
ZASM = ./zasm

$(HEADER): $(HEX)
	$(HEX2HEADER) $< $@ $(IOS_NAME) PROGMEM
	@grep $(IOS_NAME)Size $(HEADER)


$(HEX): $(SRC) Makefile
	$(ZASM) -uw --target=ram -x $< -o $@
	@fgrep '#CODE' $(LST)


upload: $(HEX)
	iload $(HEX) && touch $@


# convert $(SRC) (target: MBC2) to src code monitor.z80 (target: CP/M)
monitor.z80: $(SRC)
	sed -e 's/^\([[:space:]]*MBC2[[:space:]]\+equ[[:space:]]\+\)TRUE\>/\1FALSE/' $< > $@


.PHONY: clean
clean:
	rm -f $(HEADER) $(HEX) *.lst monitor.com *~

