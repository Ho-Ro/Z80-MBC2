all: wozmon.h

HEX2HEADER = ./hex2header
ZASM = ./zasm

wozmon.h: wozmon.hex
	$(HEX2HEADER) wozmon.hex wozmon.h WozMon PROGMEM


wozmon.hex: wozmon.asm Makefile
	$(ZASM) -uw --target=ram -x wozmon.asm -o wozmon.hex
	fgrep '#CODE' wozmon.lst


.PHONY: clean
clean:
	rm -f wozmon.hex wozmon.h wozmon.lis
