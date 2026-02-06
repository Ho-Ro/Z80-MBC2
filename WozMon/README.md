# Z80 WozMon

An Adaption of Wozmon in Z80 assembly with Input/Output set up for for the Z80-MBC2.

The Woz Monitor, also known as Wozmon, is a simple memory monitor
and was the system software located in the 256 byte PROM on the Apple-1 from 1976.
Wozmon is used to inspect and modify memory contents or to execute programs
already located in memory.

The Z80 version occupies the high 512 byte of RAM where the address range `0xFE00-0xFE7F`
is used as input buffer and the range `0xFE80-0xFFFF` is used for code, data and stack.

The source code for the original Wozmon can be found here:
https://github.com/jefftranter/6502/blob/master/asm/wozmon/wozmon.s

 - [Usage](#usage)
 - [Building](#building)
 - [Running](#running-wozmon)
 - [Load and store](#load-and-store)

## Usage

Wozmon operates and adheres to the same syntax as the original Wozmon on the Apple-1. The commands contain memory addresses and special characters for specifying whether to perform a read, write, or execute operation on them.

On startup Wozmon will display a backslash follow by a new line.

```
\
```

Wozmon will interpret any hex value as a memory address. If the provided hex value is greater then 4 digits, then the last 4 digits is used as the address.

Wozmon has 4 different modes.
 
 1. [Examine mode ](#examine-mode)
 2. [Block Examine mode](#block-examine-mode)
 3. [Store mode](#store-mode)
 4. [Execute mode](#executing-code)

 ### Examine mode
  Entering a hex value and pressing enter will display the 1 byte value at that address

```
\
E000

E000: 31
```

 ### Block Examine mode
 Entering a hex value followed by a `.` folowed by an hex value will display all bytes in that range.

```
\
E000.E01F

E000: 31 00 24 01 7F 02 FE 08
E008: CA 25 E0 FE 1B CA 14 E0
E010: 0C F2 29 E0 3E 5C CD 59
E018: E1 3E 0D CD 59 E1 3E 0A

```

 ### Store mode
  Entering a hex value followed by a `:` will allow you to write bytes starting at that memory address. Wozmon will show what the first byte at the starting address was before the write

```
\
0000:FF

0000: 00
0000

0000: FF
```

```
\
0000:FF FF FF FF FF FF FF FF

0000: 00
0000.000F

0000: FF FF FF FF FF FF FF FF
0008: 00 00 00 00 00 00 00 00
```

 ### Executing code

 Entering `R` will jump to the last examined address

```
\
E000 R

E000: 31[JUMP]
```
```
\
E000 

E000: 31
R[JUMP]
```

## Building

This project can be assembled using `ZASM by Megatokio`. 

#### ZASM - Z80, 8080 Assembler

https://github.com/Megatokio/zasm

```
./zasm -uw --target=ram -x wozmon.asm -o wozmon.hex
```

## Running WozMon

WozMon can be executed directly from the Z80-MBC2 menu with the command `'W'`.

You should see wozmon start up with the backslash `'\'`.

Display its own code with `fe80.ffbf`:

```
\
fe80.ffbf
FE80: C3 89 FE C3 AC FF DB 01
FE88: C9 31 00 00 FD 21 00 FE
FE90: 18 0E FE 08 28 19 FE 03
FE98: 28 06 FD 45 CB 78 28 1A
FEA0: CD 42 FF 3E 5C CD AC FF
FEA8: CD 42 FF FD 21 01 FE FD
FEB0: 2B FD 45 CB 78 20 F1 CD
FEB8: 4D FF CD 86 FE FE FF 28
FEC0: F9 FE 08 CC 4B FF FD 23
FEC8: FD 77 00 CD AC FF FE 0D
FED0: 20 C0 FD 21 00 FE 3E 00
FED8: DD 6F CB 27 CB 27 32 B7
FEE0: FF FD 23 FD 7E 00 FE 0D
FEE8: 28 BE FE 2E 38 F3 28 EA
FEF0: FE 3A 28 E8 FE 52 28 47
FEF8: FE 51 CA 41 FF 21 00 00
FF00: FD 22 B5 FF FD 7E 00 EE
FF08: 30 FE 0A 38 08 F6 20 CE
FF10: 89 FE F9 38 15 CB 27 CB
FF18: 27 CB 27 CB 27 06 04 17
FF20: CB 15 CB 14 10 F9 FD 23
FF28: 18 DA FD 45 3A B5 FF B8
FF30: CA A0 FE 3A B7 FF CB 77
FF38: 28 1D 7D 12 13 18 A4 DD
FF40: E9 76 3E 0D CD AC FF 3E
FF48: 0A 18 61 FD 2B 3E 20 CD
FF50: AC FF 3E 08 C3 AC FF CB
FF58: 7F 20 26 54 5D E5 DD E1
FF60: BF C2 76 FF CD 42 FF DD
FF68: 7C CD 95 FF DD 7D CD 95
FF70: FF 3E 3A CD AC FF 3E 20
FF78: CD AC FF DD 7E 00 CD 95
FF80: FF AF 32 B7 FF DD 7D BD
FF88: DD 7C 9C 30 B0 DD 23 DD
FF90: 7D E6 07 18 CC F5 CB 3F
FF98: CB 3F CB 3F CB 3F CD A2
FFA0: FF F1 E6 0F F6 30 FE 3A
FFA8: 38 02 CE 07 F5 3E 01 D3
FFB0: 01 F1 D3 00 C9 06 FE 00
FFB8: F1 D3 00 C9 00 00 00 3E
```

## Load and store

The python tool `hex2woz` converts an Intel HEX file into a format that can be
transfered with `iload` and will be read by WozMon.

```
./hex2woz < program.hex > program.woz
./iload -r program.woz
```

To store Z80 programs from WozMon on the PC, display it in WozMon and copy/paste
it in the PC editor; to restore it, use `iload`.
