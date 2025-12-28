all: basic47.hex basic47d.hex

basic47.hex: basic47.bin
	bin2ihex -i $< -o $@

basic47d.hex: basic47d.bin
	bin2ihex -i $< -o $@

basic47.bin: init.bin basic.bin
	cat $^ > $@

basic47d.bin: initd.bin basic.bin
	cat $^ > $@

init.bin: init.asm
	uz80as $< $@

initd.bin: initd.asm
	uz80as $< $@

basic.bin: basic.asm
	uz80as $< $@

.PHONY: clean
clean:
	rm -f *.lst
