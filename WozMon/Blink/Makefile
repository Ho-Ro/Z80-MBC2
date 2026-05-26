
TARGET = blink

CPM.COM = ../../CPM.COM
Z80ASM = $(CPM.COM)/TNYLPO $(CPM.COM)/z80asm

ILOAD = ../../memtest/iload

HEX = $(TARGET).hex
Z80 = $(TARGET).z80

.PHONY:	all
all: $(HEX)


$(HEX): $(Z80) Makefile
	$(Z80ASM) $(TARGET)/fh

.PHONY: hexload
hexload: $(HEX)
	$(ILOAD) $<

.PHONY: wozload
wozload: $(HEX)
	$(ILOAD) --woz $<

.PHONY:	clean
clean:
	rm -f *.lst *.hex

.PHONY:	distclean
distclean: clean
	rm -f *~ .*~
