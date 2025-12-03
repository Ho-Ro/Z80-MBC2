
all: memtest.hex memloop.hex

memtest.hex: memtest.asm
	zasm -x $<

memloop.hex: memloop.asm
	zasm -x $<

test: memtest.hex
	./iload.py $<

loop: memloop.hex
	./iload.py $<
