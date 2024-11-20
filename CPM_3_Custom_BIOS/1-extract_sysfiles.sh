#!/bin/sh

# 1st step for building a custom bios for Z80-MBC2 board:
# Extract CP/M bios source files from two z80emu cpmdsk images
# into two linux directories.

for SIZE in 64 128; do

	DIR=gencpm_${SIZE}k

	rm -rf $DIR
	mkdir -p $DIR

	CPMDSK=Z80Emu_disks/CPM3_${SIZE}K.cpmdsk

	for FILE in $(cpmls -fz80emu $CPMDSK); do
	cpmcp -fz80emu $CPMDSK 0:$FILE $DIR/$FILE
	done

done
