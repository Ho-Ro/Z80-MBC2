# BIOS for Z80-MBC2-SIO modification

The zipped disk drive image `DS2N13.DSK.zip` (CP/M3 drive `N:`) contains the
source code, all build tools, and the binaries for a banked CP/M3 BIOS with
two additional SIO interfaces `SIOA` and `SIOB`, connected to the `I2C` bus.
The SIOs allow all original CP/M baud rates that can be set with `DEVICE.COM`
and the additional speeds 14400, 28800, 38400, 57600 and 115200 Bd.
The tool `DEVMODE.COM` (located in [`cpm_tools`](cpm_tools)) can be used
to set all possible baud rates 50 Bd .. 115200 Bd and disable (`NONE`)
or enable HW handshake (`RTSCTS`) for a physical device `PD`
or attach one or more physical device(s) `PD` to a logical device `LD`.

    Usage: DEVMODE [ PD [BAUD] [HDSH] | LD [PD [PD] ... ] | /H[ELP] ]

## HW preparation

Obtain an SC16IS752 I2C/SPI Bus Interface to UART Module (or UART expander),
select I2C mode and address `0x90` - connect `A0` and `A1` to `Vdd` (3.3V).
Don't be confused, the data sheet uses the 8-bit address `0x90`, while
IOS uses the 7-bit address `0x48h` (i.e. 0x90 >> 1), both are identical.

Attach the module to the Z80-MBC2, directly connecting the 4 lines:
- Vcc
- GND
- SCL
- SDA

No need for external pullup resistors. The SC16IS752 operates on 3.3 V,
but all inputs tolerate the 5 V signals coming from the Z80-MBC2.

The BIOS supports automatic HW handshake via RTS/CTS, therefore it is
recommended to route the signals TxD, RxD, RTS, and CTS with correct
RS232 level to the interface connector(s), e.g. using two
[MAX3232 RS-232 line driver and receiver modules](DOC/RS232_bottom_mod.jpeg)
for both SIO channels.

These level shifters are available as a cheap small module, even with a
DB9 connector, search the typical sources for
*"Converter RS232 - UART with connector DB9 - SP3232 3.3V/5V"*.

I decided to use the DCE (female) connector b/c this allows the direct
connection of an USB-RS232 interface or a real PC serial I/O.

## System preparation

### CP/M update

Unzip the drive `N:` image [`DS2N13.DSK.zip`](DS2N13.DSK.zip).
Take out the SD-card and copy the file `DS2N13.DSK` to the root directory,
replacing the old (previously) empty CP/M3 disk image for drive `N:`.
Make a backup of the old disk image if you like.
You can also use any other CP/M3 drive except `A:` aka `DS2N00.DSK`, just
rename the `DS2N??.DSK` file accordingly.

You shold also make a copy of your working drive `A:` image `DS2N00.DSK`,
e.g. as `DS2N00.SAV`. In case of trouble you can always go back.

### IOS update

The new BIOS requires an updated IOS, ver. S220718-R290823-D260125 or later.
Program one of the `S220718-D??????-IOS-Z80-MBC2-SIO_??MHz.hex` files on your
AVR, using a programmer HW with a tool like e.g. `avrdude`. Chose the correct
clock frequency 16MHz or 20 MHz, depending on your XTAL.

#### Update IOS using a bootloader

1. If you want to update via the serial bootloader then load one of the
`S220718-D??????-IOS-Z80-MBC2-SIO_BL_??MHz.hex` files initially (unless you
have already installed a bootloader, in which case you can proceed directly to 2.).
Check/set the correct AVR fuse values
lfuse = 0xAF, hfuse = 0xD6 (avrdude: `-U lfuse:w:0xAF:m -U hfuse:w:0xD6:m`)
and program the hex file with your programmer.

2. Later updates can be done via the serial interface using the Arduino IDE
or the `urboot` loader (`avrdude -p m32 -c urclock -U S22...-SIO_xxMHz.hex`),
no need to attach the HW programmer again.
The bootloader option depends on the serial DTR-Reset.

#### Extended RX buffer for CP/M XMODEM

Instead of 'hijacking' the LTO linker option of the MightyCore library
there's now an extra menu point `Serial Port Buffers (RX/TX)`,
select `128/64` or `256/64`:

```
  Default
  64/64
  128/64
  128/128
  256/64
  256/128
  256/256
```

You can use the provided [`*.diff`](arduino15_packages_MightyCore_hardware_avr_3.0.2_boards.txt.diff)
file to change the MightyCore library,
go to the directory with the `boards.txt` file and apply the patch.
These are the Linux and Windows locations for the current library version:

```
/home/<username>/.arduino15/packages/MightyCore/hardware/avr/3.0.2
C:\Users\<username>\AppData\Local\Arduino15\packages\MightyCore\hardware\avr\3.0.2
```

## Testing

For a first test you can execute `N:TESTCPMX.COM`.
This boots your system with the new BIOS showing someting like:

```
...
60K TPA

Z80-MBC2 128KB (Banked) CP/M V3.0 with ZPM3
Z80-MBC2 CPMX BIOS: BIOSKRNL S170319, BOOT S220918-R180319
CHARIO S210918-R210923-D160125, MOVE S290918, SCB -, VDISK S200918
...
```

Pressing the `RESET` button brings you back to the original system.

## Installation - the simple way

If it works you can copy `N:CPMX.SYS` to `A:CPM3.SYS` - ready.
Your system will now start up with the new BIOS.

## Installation - the safe way

If you want a quick fallback-solution w/o SD-card handling keep your
original `A:CPM3.SYS` and copy the file `N:CPMX.SYS` to `A:CPMX.SYS`.
This can be done with `PIP A:=N:CPMX.SYS` or `MAKE INSTALL` from `N:`.
To boot either the original `CPM3.SYS` or the new `CPMX.SYS`, rename
the provided file [`cpmxldr.com`](bios_devel.linux/cpmxldr.com) to
`CPMLDR.COM` and put it on the root directory of the Z80-MBC2 SD card.
Depending on the status of the IOS `AUTOEXEC` bit it will load either
`A:CPM3.SYS` (`AUTOEXEC==OFF`) or `A:CPMX.SYS` (`AUTOEXEC==ON`).
When it doesn't find the `A:CPMX.SYS` file then it loads `A:CPM3.SYS`.
This procedure is strongly recommended if you want to modify your BIOS.

## Utilities

Also included are source and binaries of utility programs for these SIOs,
i.e. `DEVMODE.PAS` / `DEVMODE.COM` to handle all supported baud rates and the
assignment of physical devices to the logical devices `CRT:`, `AUX:`, `PRN:`
and `VERBOSE.PAS` / `VERBOSE.COM` to support debugging of the IOS functions.

## Build your own CP/M3 BIOS

### Using the CP/M toolchain

Building and installing is controlled by `MAKE.COM` and the `MAKEFILE`.
Implement your modifications with your editor of choice, e.g. `WS.COM` or
`TURBO.COM`; enter `MAKE` and the new system will be created.
`MAKE.COM` checks the dependencies defined in `MAKEFILE` and and creates the
file `MAKE@@@.SUB` with all necessary commands to resolve these dependencies.
It will only rebuild the modules with modified source code to speed up the
build (this feature requires a working RTC).
At the end of this analysis process the file `MAKE@@@.SUB` is automatically
executed and deleted after completion.
Test the result with `TESTCPMX` and install it as described above.
The disk image `DS2N13.DSK` contains all necessary tools needed for a build
on any recent Z80-MBC2 system.
In order to use the new `SIOA` and `SIOB` devices in the improved BIOS, it is
also necessary to update the IOS to the version maintained here.

### Cross build on Linux

CP/M takes some minutes for a complete build due to slow *'disk'* access.
Also the editing is slow and error prone due to the limitation of only
one source code file - aren't we all used to do a quick copy/paste?
I've set up a tool chain for Linux using a makefile and the CP/M command tool
[`tnylpo`](https://gitlab.com/gbrein/tnylpo).
This tool is not a full-blown CP/M emulation, but it executes CP/M 2.2 `*.COM`
files and accesses data from the Linux file system. You need the version from
my [GitLab fork](https://gitlab.com/Ho-Ro/tnylpo) if you want to handle also
UPPER case file names. To build type `make` - the full build finishes within
few seconds. Then I pull in the new `TESTCPMX.COM` via `XMODEM` or `KERMIT`
from CP/M and can test it. When it's all ok then I transfer also the modified
source files over to CP/M, rebuild everything there again and finally install
the newly created `CPMX.SYS` on `A:`.
The bios source code and the toolchain is in the directory [`bios_devel.linux`](bios_devel.linux).
Some of my own CP/M tools and some old but improved ones are in [`cpm_tools`](cpm_tools).
