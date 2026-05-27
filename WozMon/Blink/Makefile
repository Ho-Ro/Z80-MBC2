
TARGET = blink

CPM.COM = ../../CPM.COM
Z80ASM = $(CPM.COM)/TNYLPO $(CPM.COM)/z80asm

ILOAD = ../../memtest/iload

Z80 = $(TARGET).z80
HEX = $(TARGET).hex
WOZ = $(TARGET).woz

.PHONY:	all
all: $(HEX) $(WOZ)


$(HEX): $(Z80) Makefile
	$(Z80ASM) $(TARGET)/fh

$(WOZ): $(HEX)
	$(ILOAD) --stdout --woz $< > $@

.PHONY: hexload
hexload: $(HEX)
	$(ILOAD) $<

.PHONY: wozload
wozload: $(HEX)
	$(ILOAD) --woz $<


.PHONY:	clean
clean:
	rm -f *.lst *.prn

.PHONY:	distclean
distclean: clean
	rm -f $(HEX) $(WOZ) *~ .*~
