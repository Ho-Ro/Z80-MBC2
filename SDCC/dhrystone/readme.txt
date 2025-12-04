Dhrystone Benchmark for the Z80-MBC2

Adapted from here: 
https://sourceforge.net/p/sdcc/code/HEAD/tree/trunk/sdcc-extra/historygraphs/dhrystone-z80/

-------------------------------------------------------------------------------------------------------------


NOTE 1: You have to upload the IOS firmware of the Z80-MBC2 to IOS S220718-R290823 (or following revision)

NOTE 2: You have to read the chapter "USING THE SDCC CROSS COMPILER" from the Z80-MBC2 project
        page (https://hackaday.io/project/159973/details/)




ON WINDOWS:

* Copy the content of this .zip file inside your working directory and run the DHRY.BAT batch file
  to compile and generate the output executable (Intel-Hex formatted) out.hex.


* To upload and execute on the Z80-MBC2 use the L.BAT bach file as usual.




ON LINUX:

* Copy the content of this .zip file inside your working directory and compile with the command:

             make


* To upload and execute on the Z80-MBC2 use the command: 

             minicom -w  -S minicom.mac -D /dev/ttyUSB0

 as usual (where /dev/ttyUSB0 must be adapted to the port you are using to connect the Z80-MBC2 on your system).
