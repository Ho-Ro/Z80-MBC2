# memtest

Warning, this memtest assumes a IOS version which is reporting the RAM size via 0x83 aka SYSFLAGS, else it only tests the first 128kBytes.

## how to build

* install zasm from https://github.com/Megatokio/zasm/releases
* zasm -x memtest.asm

(tested with zasm 4.4.17 for linux amd64)

## how to start

use iload and paste the content of memtest.hex file. Be aware that you might need to slow down your terminal if you get checksum errors while pasting. 
