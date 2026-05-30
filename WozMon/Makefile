
PRJ = wozmon

SRC = $(PRJ).z80
HEX = $(PRJ).hex
LST = $(PRJ).lst
HEADER = $(PRJ).h

all: $(HEADER)

HEX2HEADER = ./hex2header
ZASM = ./zasm

$(HEADER): $(HEX)
	$(HEX2HEADER) $< $@ WozMon PROGMEM


$(HEX): $(SRC) Makefile
	$(ZASM) -uw --target=ram -x $< -o $@
	fgrep '#CODE' $(LST)


.PHONY: clean
clean:
	rm -f $(HEADER) $(HEX) $(LST) *~
