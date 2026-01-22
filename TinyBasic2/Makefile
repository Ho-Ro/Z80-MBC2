
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


#tinybasic2.hex: tinybasic2.cim
#	srec_cat $< -binary -output $@ -intel --address-length=2
#	@grep ^BYTES_FREE tinybasic2.lst

#tinybasic2.cim: tinybasic2.asm Makefile
#	zmac -c -o $@ -o tinybasic2.lst $<

#tinybasic2dms.hex: tinybasic2dms.cim
#	srec_cat $< -binary -output $@ -intel --address-length=2
#	@grep ^BYTES_FREE tinybasic2dms.lst #| cut -d: -f2

#tinybasic2dms.cim: tinybasic2dms.asm Makefile
#	zmac -8 -c -o $@ -o tinybasic2dms.lst $<


README.md: README.8080.in README.z80.in tinybasic2.z80 tinybasic8080.asm Makefile
	cp README.8080.in $@
	@echo '```' >> $@
	grep '.ASCII  "' tinybasic8080.asm | cut -d\I -f3- >> $@
	@echo '```' >> $@
	cat README.z80.in >> $@
	@echo '```' >> $@
	grep '.ASCII  "' tinybasic2.z80 | cut -d\I -f3- >> $@
	@echo '```' >> $@
	@echo >> $@
