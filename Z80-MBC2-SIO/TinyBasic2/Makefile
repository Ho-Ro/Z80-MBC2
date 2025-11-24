
HEX = tinybasic2.hex
README = README.md
ROMSIZE = 0x0800

.PHONY:	all
all: $(HEX) $(README)


.PHONY:	clean
clean:
	rm -f *.cim *.lst *.hex


.PHONY:	load
load:	tinybasic2.hex
	python iload.py tinybasic2.hex


tinybasic2.hex: tinybasic2.cim
	srec_cat $< -binary -output $@ -intel --address-length=2
	@grep BYTES_FREE: tinybasic2.lst | cut -d: -f2

tinybasic2.cim: tinybasic2.asm Makefile
	zmac -c -o $@ -o tinybasic2.lst $<

README.md: README.md.in tinybasic2.asm
	cp README.md.in $@
	echo '```' >> $@
	grep '.ASCII  "' tinybasic2.asm | cut -d\I -f3- >> $@
	echo '```' >> $@
