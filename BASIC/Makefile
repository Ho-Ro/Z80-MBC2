all: basic47.hex basic47_im0.hex basic47_im1.hex basic47_im2.hex

basic47.hex: basic47.bin
	bin2ihex -i $< -o $@

basic47_im0.hex: basic47_im0.bin
	bin2ihex -i $< -o $@

basic47_im1.hex: basic47_im1.bin
	bin2ihex -i $< -o $@

basic47_im2.hex: basic47_im2.bin
	bin2ihex -i $< -o $@

basic47.bin: init.bin basic.bin
	cat $^ > $@

basic47_im0.bin: init_im0.bin basic.bin
	cat $^ > $@

basic47_im1.bin: init_im1.bin basic.bin
	cat $^ > $@

basic47_im2.bin: init_im2.bin basic.bin
	cat $^ > $@

init.bin: init.asm
	uz80as $< $@

init_im0.bin: init_im.asm
	uz80as -dINTMODE0 $< $@ init_im0.lst

init_im1.bin: init_im.asm
	uz80as -dINTMODE1 $< $@ init_im1.lst

init_im2.bin: init_im.asm
	uz80as -dINTMODE2 $< $@ init_im2.lst

basic.bin: basic.asm
	uz80as $< $@

.PHONY: clean
clean:
	rm -f *.lst

.PHONY: distclean
distclean: clean
	rm -f *.bin *.hex *~ .*~
