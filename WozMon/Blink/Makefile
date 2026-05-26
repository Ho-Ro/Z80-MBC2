
TARGET = blink


HEX = $(TARGET).hex
Z80 = $(TARGET).z80

.PHONY:	all
all: $(HEX)


.PHONY:	clean
clean:
	rm *.lst *.prn *.hex

$(HEX): $(Z80) Makefile
	tnylpo zmac $< /hp

