# Z80 Monitor From Scratch
This repo documents the evolution of a simple Z80 monitor for single board computer
like [Z80-MBC2](https://github.com/Ho-Ro/Z80-MBC2).

## Z80-MBC2
This little computer already uses the Z80 version of
[WozMon](https://github.com/Ho-Ro/Z80-MBC2/blob/main/WozMon),
the tiny Apple ][ ROM monitor. Due to the reduced commands I decided to start a new
monitor with extended command set.

## The Monitor

### Setup
80s-like this monitor is written in Z80 assembler. The single source `monitor.z80`
is assembled with [zasm](https://github.com/Megatokio/zasm) (Megatokio zasm, included
in this repo) on Linux. A build switch (`MBC2` / `CPM`) selects the target:

- the **CP/M** variant (`MBC2 equ FALSE`, `org 0100h`) is a CP/M program to simplify
  testing, run on my Linux machine under [zxcc](https://github.com/Ho-Ro/ZXCC) or
  alternatively [tnylpo](https://github.com/Ho-Ro/tnylpo), or on real hardware.
- the **Z80-MBC2** variant (`MBC2 equ TRUE`, `org 0F800h`) is the standalone ROM image.

The only two HW-related functions are

- **in_char** (wait for char and return it in register A)
- **out_char** (output char in register A)

On cold start (and after a `G0` exit or a `^C` restart) the monitor prints a short
start message: `MBC2 MON` in the Z80-MBC2 build, `CP/M MON` in the CP/M build.

The typical use case for Z80 SBCs is the combination with a terminal program running on the PC
that connects to the serial port of the SBC. So the simplest way of program storage is to copy
it from or to the terminal screen and store it on the PC. Therefore I decided to support the
[WozMon format](https://github.com/Ho-Ro/Z80-MBC2/blob/main/WozMon/README.md) for simple data storage.

### Building
`make` builds all artifacts. Under the hood:

    make monitor.hex    # CP/M variant:  zasm -uw --target=ram -x monitor.z80 -o monitor.hex
    make mbc2mon.hex    # Z80-MBC2 ROM:  zasm -uw --target=ram -x mbc2mon.z80 -o mbc2mon.hex

`mbc2mon.z80` is generated from `monitor.z80` by flipping the build switch
(`MBC2 equ FALSE` -> `MBC2 equ TRUE`) with `sed`; the Makefile does this automatically,
so `monitor.z80` is the only file to edit. The CP/M `.com` images are produced from the
`.hex` files with `zxcpm load`.

The Z80-MBC2 jump list (`init`, `in_char`, `out_char`, `out_byte`, `out_crlf`,
`out_word`, `out_string`, `hex_to_bc`) lives at `0F800h`, so user programs can
call the monitor API at that fixed base.

> Note: zasm labels are **case-sensitive** (`call BDOS`, not `call bdos`).

### Commands
The monitor program offers these functions with the following syntax:

    <CMD><ADDRESS>[ <ARG> <ARG> ...]<RETURN>

- **VIEW** memory content
  - `VAAAA` - View 16 bytes at `AAAA` as hex and ASCII (`AAAA  DD DD ...  CC ..`).
  - `V` (or CR alone) - View the next 16 bytes after previous dump.
  - `WAAAA` - Dump 16 bytes at `AAAA` in WozMon fmt (`AAAA: DD DD ...`).
  - `W` (or CR alone) - Dump the next 16 bytes after previous dump in WozMon fmt.

- **MODIFY** memory content
  - `AAAA: DD DD ...` - Modify mem at `AAAA` using WozMon fmt (as shown by `WAAAA`).
    The address may be any 1-4 hex digits (`A:`, `12:`, `123:`, `1234:`).
  - CR alone after a `AAAA: DD DD ...` line re-displays 16 bytes at `AAAA` in WozMon fmt.

- **GOTO** program location
  - `GAAAA` - Goto program at `AAAA`.
  - `GAAAA BBBB` - Goto program at `AAAA` and set a breakpoint at `BBBB`.
  - `G` (or CR alone) - Goto program counter of user context, e.g. resume from last breakpoint.
  - `G0` - Exit to CP/M or restart the Z80-MBC2 monitor.

- **BREAKPOINT** set or clear
  - `K` - clear breaKpoint.
  - `K0` - clear breaKpoint.
  - `KAAAA` - set breaKpoint at `AAAA`.
  - `KAAAA BBBB` - set breaKpoint at `AAAA` and reactivate it at `BBBB`.
    Breakpoints and reactivation points are implemented by replacing the opcode at `AAAA` and `BBBB` with `RST` instructions.  
    This only works if the addresses `AAAA` and `BBBB` point to the first byte of the opcode (M1).
  - **stepping**: `KAAAA BBBB` with `BBBB` placed just after `AAAA`, then `G<start>`
    to run and `G` (or CR) repeatedly. Each breakpoint hit is displayed with the
    register dump; the reactivation point re-arms the breakpoint, so a loop
    advances one iteration per `G` — continue until the program's output appears
    and returns to the monitor prompt.

- **IOS** I/O commands (Z80-MBC2 build only)
  - `O CMD DD` - store IOS output opcode `CMD` and write a data byte `DD` to it.
    Examples: `O 00 01` (USER LED on), `O 00 00` (USER LED off), `O 03 FF` (GPIOA all high).  
    Same port sequence as `out_char` (`STO_OPC` store, `EX_OPC` execute write).
  - `Q CMD [NN]` - store IOS input opcode `CMD` and read `NN` bytes (default 1);
    multi-byte reads (e.g. `Q 84 7` DATETIME) are read sequentially without re-store.
  - The commands are only compiled in the `MBC2` build; in the `CP/M` (`zxcc`)
    build they report `?`. `CMD`, `DD` and `NN` are 1-2 hex digits.
  - Useful opcodes (see `IOS-Z80-MBC2-NG`):

    | `CMD` | Dir | Function |
    |---|---|---|
    | `00` | W | USER LED (bit 0: 0 = off, 1 = on) |
    | `01` | W | Serial TX |
    | `03`/`04` | W | GPIOA / GPIOB |
    | `05`/`06` | W | IODIRA / IODIRB (direction) |
    | `07`/`08` | W | GPPUA / GPPUB (pull-ups) |
    | `80` | R | USER KEY |
    | `81`/`82` | R | GPIOA / GPIOB |
    | `83` | R | SYSFLAGS |
    | `84` | R | DATETIME (7 bytes: s min h d mon y temp) |
    | `85` | R | ERRDISK |
    | `89` | R | SYSIRQ |

- **REGISTER** display
  - `R` - show the user register including the 2nd register set `AF'`, `BC'`, `DE'`, `HL'` and, if applicable, the address of the breakpoint and its recovery.

```
           A  F  BC   DE   HL  A' F'  BC'  DE'  HL'  IX   IY   I  R  PC   SP
          DE 8B 0600 0003 C504 55 00 0000 0000 0000 0000 0000 00 1B 100C 0740
          Sz...p.C             sz...p.c                      BrkPt: 100C/100D
```

- **SET REGISTER** prepare user context for the following `G` command
  - `A dd` - set register `A`
  - `B dd` - set register `B`
  - `C dd` - set register `C`
  - `D dd` - set register `D`
  - `E dd` - set register `E`
  - `H dd` - set register `H`
  - `L dd` - set register `L`
  - `F dd` - set flags
  - `I dd` - set interrupt vector register
  - `P dddd` - set program counter
  - `S dddd` - set stack pointer
  - `X dddd` - set register `IX`
  - `Y dddd` - set register `IY`


The command line input uses `BS` or `RUB` to delete to the left. Control
characters other than `BS`/`RUB`/`CR`/`^C` are ignored. `^C` returns to CP/M
(CP/M build) or restarts the monitor (Z80-MBC2 build).
