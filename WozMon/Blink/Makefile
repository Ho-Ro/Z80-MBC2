
TARGET = blink

CPM.COM = ../../CPM.COM
ZMAC = $(CPM.COM)/TNYLPO $(CPM.COM)/zmac

ILOAD = ../../memtest/iload

HEX = $(TARGET).hex
Z80 = $(TARGET).z80

.PHONY:	all
all: $(HEX)


$(HEX): $(Z80) Makefile
	$(ZMAC) $< /hp

.PHONY: hexload
hexload: $(HEX)
	$(ILOAD) $<

.PHONY: wozload
wozload: $(HEX)
	$(ILOAD) --woz $<

.PHONY:	clean
clean:
	rm -f *.prn *.hex

.PHONY:	distclean
distclean: clean
	rm -f *~ .*~
