# Z80-MBC2

![Z80-MBC2](https://cdn.hackaday.io/images/4364631532527997411.jpg)

## Development version

I forked from [upstream](https://github.com/SuperFabius/Z80-MBC2) to document my BIOS development in
[CPM_3_Custom_BIOS](CPM_3_Custom_BIOS). My target is the addition of a 2nd serial interface via the I2C
port of the AVR chip. The serial module is inspired by the
[idea of eightbitswide](https://github.com/eightbitswide/z80-mbc2-I2C-to-Serial),
but I'll implement it gapless into the BIOS as AUX device.

I edit the source code on my Debian Linux and build directly on the CP/M system via `MAKE.COM`.
Files are transfered between Linux and CP/M with `lrzsz` and `XM.COM`, using the xmodem protocol.

Current status:

- Original BIOS source code in Z80 syntax (`*.MAC`) builds a working `CPM3.SYS`.
- `MAKEFILE` allows the faster build that translates only changed parts.
- `CHARIO.MAC` provides a dummy `AUXIN` (returns `EOF`) and `AUXOUT` (kind of `/dev/null`).
- `S220718-R290823_IOS-Z80-MBC2.ino` provides I/O commands for `AUXIN`, `AUXOUT`, `AUXSTAT` and `AUXCTRL`.
- `Makefile` allows the compiling of the `*.ino` via `arduino-cli` tool.

Next goal:

- Implementation of a simple I2C target on an Arduino Nano to test the signal flow,
  initially as bufferless AUXOUT without handshake signals.

Further steps:

- Add a serial buffer and handshake signals on the target.
- AUXIN ...

## Original README file from [upstream](https://github.com/SuperFabius/Z80-MBC2)

The Z80-MBC2 is an easy to build Z80 SBC (Single Board Computer). It is the "evolution" of the Z80-MBC (https://hackaday.io/project/19000-a-4-4ics-z80-homemade-computer-on-breadboard), with a SD as "disk emulator" and with a 128KB banked RAM for CP/M 3 (but it can run CP/M 2.2, QP/M 2.71, UCSD Pascal and others).

It has an optional on board 16x GPIO expander, and uses common cheap add-on modules for the SD and the RTC options. It has an "Arduino heart" using an Atmega32A as EEPROM and "universal" I/O emulator (so a "legacy" EPROM programmer is not needed).

It is a complete development "ecosystem", and using the iLoad boot mode it is possible cross-compile, load and execute on the target an Assembler or C program (using the SDCC compiler) with a single command (like in the Arduino IDE). 

Project page: https://hackaday.io/project/159973-z80-mbc2-4ics-homemade-z80-computer

Latest IOS revision: IOS S220718-R290823
