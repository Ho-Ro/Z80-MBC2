
all: memtest.hex memloop.hex

ZASM = zasm
ILOAD = ./iload

memtest.hex: memtest.asm
	$(ZASM) -x --target=ram $<

memloop.hex: memloop.asm
	$(ZASM) -x --target=ram $<

test: memtest.hex
	$(ILOAD) $<

loop: memloop.hex
	$(ILOAD) $<
