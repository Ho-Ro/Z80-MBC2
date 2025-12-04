TNYLPO = tnylpo

MAC = ../CPM.COM/mac
RMAC = ../CPM.COM/rmac
LINK = ../CPM.COM/link


TARGETS = ccp.com dump.com hexcom.com hexcom hexpat


all: $(TARGETS)


##############################################################################
#
# Build tools
#
hexcom:		hexcom.c
	${CC} -o hexcom hexcom.c

hexpat:		hexpat.c
	${CC} -o hexpat hexpat.c


##############################################################################
#
# Specific build rules
#
# The redirection to CCPPHASE.* produces two lists of addresses
# (one in CCP3.COM and one in LOADER3.PRL) which should match.
#

loader3.rel:	loader3.asm
	$(TNYLPO) $(RMAC) loader3 >ccpphase.lst

ccp3.hex:	ccp3.asm
	$(TNYLPO) $(MAC) ccp3 >> ccpphase.lst

ccp.com:	loader3d.tmp hexpat ccpdate.hex
	./hexpat $< $@ < ccpdate.hex

loader3d.tmp:	loader3c.tmp hexpat ccp3.hex
	./hexpat $< $@ < ccp3.hex

loader3c.tmp:	loader3a.tmp loader3b.tmp
	cat loader3a.tmp loader3b.tmp > $@

# Shave the header off loader3.prl to get the loader image
loader3a.tmp:	loader3.prl
	dd if=loader3.prl of=loader3a.tmp bs=128 skip=2

# This empty space will be overwritten by ccp3.hex
loader3b.tmp:
	dd if=/dev/zero of=loader3b.tmp bs=128 count=19


###########################################################################
#
# COM files from hex files
#
%.com:	%.hex hexcom
	./hexcom $@ < $<


###########################################################################
#
# HEX files from asm source
#
%.hex: %.asm makedate.lib
	$(TNYLPO) $(MAC) `basename $< .asm`


###########################################################################
#
# PRL and RSX files from .REL files
#
%.prl:	%.rel
	$(TNYLPO) $(LINK) `basename $< .rel`[OP]

%.spr:	%.rel loader*.tmp
	$(TNYLPO) $(LINK) `basename $< .rel`[OS]

%.rsx:	%.rel
	$(TNYLPO) $(LINK) `basename $< .rel`[OP]
	mv -f `basename $< .rel`.prl `basename $< .rel`.rsx

%.rel:	%.asm
	$(TNYLPO) $(RMAC) `basename $< .asm`


###########################################################################
#
# Clean
#
.PHONY:		clean
clean:
	rm -f *.hex *.lst *.rel *.sym *.tra *.rsx *.spr \
	*.mod *.obj *.prn *.prl loader*.tmp *~

.PHONY:		distclean
distclean:	clean
	rm -f $(TARGETS)
