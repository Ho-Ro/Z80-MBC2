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

init_im0.bin: init_im0.asm
	uz80as $< $@

init_im1.bin: init_im1.asm
	uz80as $< $@

init_im2.bin: init_im2.asm
	uz80as $< $@

basic.bin: basic.asm
	uz80as $< $@

.PHONY: clean
clean:
	rm -f *.lst
