
HEX = tinybasic2.hex tinybasic8080.hex
HEADER = tinybasic2.h
README = README.md
ROMSIZE = 0x0800

.PHONY:	all
all: $(HEX) $(HEADER) $(README)


.PHONY:	clean
clean:
	rm -f *.cim *.lst *.hex


.PHONY:	load
load:	tinybasic2.hex
	python iload.py tinybasic2.hex

.PHONY:	ld8080
ld8080:	tinybasic8080.hex
	python iload.py $<


%.hex:  %.cim
	srec_cat $< -binary -output $@ -intel --address-length=2
	@grep ^BYTES_FREE `basename $< .cim`.lst

%.cim:	%.asm Makefile
	zmac -8 -c -o $@ -o `basename $< .asm`.lst $<

%.cim:	%.z80 Makefile
	zmac -c -o $@ -o `basename $< .z80`.lst $<

tinybasic2.h: tinybasic2.hex
	./hex2header $< $@ tinybasic2 PROGMEM


README.md: README.in README.8080.in README.z80.in tinybasic2.z80 tinybasic8080.asm Makefile
	cp README.in $@
	cat README.8080.in >> $@
	@echo '```' >> $@
	grep '.ASCII  "' tinybasic8080.asm | cut -d\I -f3- >> $@
	@echo '```' >> $@
	cat README.z80.in >> $@
	@echo '```' >> $@
	grep '.ASCII  "' tinybasic2.z80 | cut -d\I -f3- >> $@
	@echo '```' >> $@
	@echo >> $@
