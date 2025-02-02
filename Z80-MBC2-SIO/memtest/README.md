# memtest

Warning, this memtest assumes 256kBytes and 7 independent banks. It won't deliver correct results if your Z80-mbc2 hasn't modified for BANK2 signal and is wrongly configured to 256kByte!

## how to build

* install zasm from https://github.com/Megatokio/zasm/releases
* zasm -x memtest.asm

(tested with zasm 4.4.17 for linux amd64)


