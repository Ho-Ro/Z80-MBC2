# Z80-MBC2 HW setup

## ATmega32

The original project uses an ATmega32 processor for IOS, regularyly clocked with 16 MHz.
An overclocking option of 20 MHz exists but it exceeds the max clock of the ATmega32.

### Set ATmega32 Fuses

```sh
avrdude -v -patmega32 -cstk500 -P /dev/ttyUSB0 -e -Ulfuse:w:0x3F:m -Uhfuse:w:0xC6:m
```

![ATmega32 fuses](ATmega32_fuses.png)

## ATmega1284p

Recent IOS versions support the ATmega1284p processor that allows a max clock frequency
of 20 MHz (in spec) with an (out of spec) overclocking option of 24 MHz (clocking the Z80 with 12 MHz).
![Z80-MBC2 New Menu](../Z80-MBC2_menu.png)

### Set ATmega1284p Fuses

```sh
avrdude -v -patmega1284p -cstk500 -P /dev/ttyUSB0 -Ulfuse:w:0xF7:m -Uhfuse:w:0xD6:m -Uefuse:w:0xFC:m
```

![ATmega1284 fuses](ATmega1284_fuses.png)

## Bootloader

The [urboot](https://github.com/stefanrueger/urboot) bootloaders `mbc2boot_m32.hex` and `mbc2boot_m1284p.hex`
have been adapted to the Z80-MBC2 hardware so that the Z80-MBC2 USER LED flashes during data upload.
They were built with the following parameters:

```sh
make MCU=atmega32 AUTOBAUD=1 CHIP_ERASE=0 UPDATE_FL=4 BLINK=1 LED=AtmelPD5 LEDPOLARITY=-1 NAME=mbc2boot_m32
make MCU=atmega1284p AUTOBAUD=1 CHIP_ERASE=0 UPDATE_FL=4 BLINK=1 LED=AtmelPD5 LEDPOLARITY=-1 NAME=mbc2boot_m1284p
```
The `mbc2boot_m32.hex` or `mbc2boot_m1284p.hex` bootloaders are concatenated with the corresponding
IOS hex file to the file `IOS-Z80-MBC2-NG_BL_ATmega32_xxMHz.hex`
or `IOS-Z80-MBC2-NG_BL_ATmega1284p_xxMHz.hex`, which can be programmed via the ISP interface
with the command `make flash`.
This also sets the LOCK bits to protect the bootloader from being overwritten.
These bootloaders use the `urclock` protocol and enable IOS updates via the serial USB connection
with `make update` (directly with `avrdude`) or `make upload` (calling `avrdude` via `arduino-cli`).

|Size|Usage|Version|Features|Hex file|
|:-:|:-:|:-:|:-:|:--|
|330|512|u8.0|`weU-hpra-`|mbc2boot_m32.hex|
|350|1024|u8.0|`weU-hpra-`|mbc2boot_m1284p.hex|

- **Size:** Bootloader code size including small table at top end
- **Usage:** How many bytes of flash are needed, ie, HW boot section or a multiple of the page size
- **Version:** For example, u7.6 is an urboot version, o5.2 is an optiboot version
- **Features:**
  + `w` bootloader provides `pgm_write_page(sram, flash)` for the application at `FLASHEND-4+1`
  + `e` EEPROM read/write support
  + `U` checks whether flash pages need writing before doing so
  + `h` hardware boot section: make sure fuses are set for reset to jump to boot section
  + `p` bootloader protects itself from being overwritten
  + `r` preserves reset flags for the application in the register R2
  + `a` autobaud detection (f_cpu/8n using discrete divisors, n = 1, 2, ..., 256)
  + `-` corresponding feature not present
