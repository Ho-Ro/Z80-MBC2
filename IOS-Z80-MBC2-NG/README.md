# Z80-MBC2 HW setup

## ATmega32

The original project uses an ATmega32 processor for IOS, regularyly clocked with 16 MHz.
An overclocking option of 20 MHz exists but it exceeds the max clock of the ATmega32.

### Set ATmega32 Fuses

```sh
avrdude -v -patmega32 -cstk500 -P /dev/ttyUSB0 -e -Ulfuse:w:0x3F:m -Uhfuse:w:0xC6:m
```

![ATmega32 fuses](ATmega32_fuses.png)

### ATmega32 Bootloader

I've set up an [urboot](https://github.com/stefanrueger/urboot) boot loader `urboot_m32.hex`
that flashes the Z80-MBC2 USER LED during data upload with these parameters:

```sh
make MCU=atmega32 AUTOBAUD=1 CHIP_ERASE=0 UPDATE_FL=4 BLINK=1 LED=AtmelPD5 LEDPOLARITY=-1 NAME=mbc2boot_m32
```
This boot loader is concatenated with the IOS hexfile to the file `IOS-Z80-MBC2-NG_BL_xxx.hex`
that can be programmed via ISP interface with the command `make flash`, this sets also the
LOCK bits to protect the boot loader from being overwritten.
This boot loader uses the `urclock` protocol supported by `avrdude` as well by the Arduino
upload command and allows the IOS update via the USB serial connection with `make update`
(directly using `avrdude`) or `make upload` (calling `avrdude` via `arduino-cli`).

## ATmega1284

Recent IOS versions support the ATmega1284p processor that allows a max clock frequency
of 20 MHz (in spec) with an overclocking option of 24 MHz (out of spec).

### Set ATmega1284p Fuses

```sh
avrdude -v -patmega1284p -cstk500 -P /dev/ttyUSB0 -Ulfuse:w:0xF7:m -Uhfuse:w:0xD6:m -Uefuse:w:0xFC:m
```

![ATmega1284 fuses](ATmega1284_fuses.png)

### ATmega1284 Bootloader

I've set up an [urboot](https://github.com/stefanrueger/urboot) boot loader `urboot_m1284.hex`
that flashes the Z80-MBC2 USER LED during data upload with these parameters:

```sh
make MCU=atmega1284 AUTOBAUD=1 CHIP_ERASE=0 UPDATE_FL=4 BLINK=1 LED=AtmelPD5 LEDPOLARITY=-1 NAME=mbc2boot_m1284
```
This boot loader is concatenated with the IOS hexfile to the file `IOS-Z80-MBC2-NG_BL_xxx.hex`
that can be programmed via ISP interface with the command `make flash`, this sets also the
LOCK bits to protect the boot loader from being overwritten.
This boot loader uses the `urclock` protocol supported by `avrdude` as well by the Arduino
upload command and allows the IOS update via the USB serial connection with `make update`
(directly using `avrdude`) or `make upload` (calling `avrdude` via `arduino-cli`).
