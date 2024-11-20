In this folder there are the source files of the custom modules of the CP/M 3 BIOS for the Z80-MBC2.

CP/M 3 requires you use the original tools for system generation, so simpler way is using an emulator.

Inside the Z80Emu_disks.zip file there are two disk images for the Z80Emu v2 emulator used to create the 
CP/M 3 loader (CPMLDR.COM) and the CP/M 3 system file (CPM3.SYS) for both the not banked (64KB) and banked (128KB) CP/M 3 
versions.

The Z80Emu v.2 can be found here: https://www.shaels.net/index.php/z80emu/z80emu-downloads

When using the emulator, set as disk A: the provided CP/M 2.2 system disk, and as disk B: one of the 
development disks in the zip file.


--> To generate the loader (CPMLDR.COM) use only the 64KB not banked version disk (CPMLDR.COM is the same 
    for both not banked and banked version), set B: as current drive and give the command:

                  SUBMIT GENLDR


--> To generate the system (CPM3.SYS) for the 64KB not banked version use the 64KB not banked version disk, 
    set B: as current drive and give the command:

                  SUBMIT GENSYS


--> To generate the system (CPM3.SYS) for the 128KB banked version use the 128KB banked version disk, set B: 
    as current drive and give the command:

                  SUBMIT GENSYSB



Note: all the previous revisions of BIOS modules are present here (see the Changelog inside each file).

-----

Ho-Ro: Another possibility is to create the BIOS directly on the MBC2 system.
So I extracted the source files with cpmtools, with this [format definition](diskdefs_z80emu_cpmdsk)
and put them into the directories `gencpm_64k` and `gencpm_128k`. Then I copied the files on
`DS2N06.DSK` (CP/M3 disc G:) and `DS2N07.DSK` (CP/M3 disc H:) of the SD card.
I also created the tool [`CPMTST.ASM`](gencpm_128k/cpmtst.asm),
a [slightly modified](gencpm_128k/cpmtst.asm.patch) `CPMLDR.ASM`, which takes the 1st
command line argument as file name and loads this file as a new `CPM3.SYS` file.
You can experiment with the BIOS functions, create a new `CPM3.SYS`,
copy it as e.g. `BIOSV7.SYS` to drive `A:` and load it with `CPMTST BIOSV7.SYS`.
If you are not satisfied with the result, go back to the stable system by simply typing `CPMLDR`.
And even if your `BIOSV7.SYS` crashes, just press RESET and you are back in business
without pulling the SD card and replacing CPM3.SYS.

