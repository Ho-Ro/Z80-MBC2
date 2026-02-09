# Z80 *WozMon*

 - [Usage](#usage)
 - [Running](#running-wozmon)
 - [Load and Store](#load-and-store)
 - [Building](#building)

An Adaption of *WozMon* in Z80 assembly with Input/Output set up for for the Z80-MBC2.

The *Woz Monitor*, also known as *WozMon*, is a simple memory monitor
and was the system software located in the 256 byte PROM on the Apple-1 from 1976.
*WozMon* is used to inspect and modify memory contents or to execute programs
already located in memory.

The Z80 version occupies the high 512 byte of RAM where the address range `0xFE00-0xFE7F`
is used as input buffer and the range `0xFE80-0xFFFF` is used for code, data and stack.

The source code for the original *WozMon* can be found here:
https://github.com/jefftranter/6502/blob/master/asm/wozmon/wozmon.s

## Usage

*WozMon* operates and adheres to the same syntax as the original *WozMon* on the Apple-1. The commands contain memory addresses and special characters for specifying whether to perform a read, write, or execute operation on them.

On startup *WozMon* will display a backslash follow by a new line.

```
\
```

*WozMon* has 4 different modes.
 
 1. [Examine mode ](#examine-mode)
 2. [Block Examine mode](#block-examine-mode)
 3. [Modify mode](#modify-mode)
 4. [Execute mode](#executing-code)

### Examine Mode

Entering a hex value and pressing enter will display the byte value at that address.
*WozMon* will interpret any hex value as a memory address. If the provided hex value
is greater then 4 digits, then the last 4 digits are used as the address.

```
\
E000

E000: 31
```

### Block Examine Mode

Entering a hex value followed by a dot `'.'` folowed by an hex value will display
all bytes in that range.

```
\
E000.E01F

E000: 31 00 24 01 7F 02 FE 08
E008: CA 25 E0 FE 1B CA 14 E0
E010: 0C F2 29 E0 3E 5C CD 59
E018: E1 3E 0D CD 59 E1 3E 0A

```

### Modify Mode

By entering a hexadecimal address followed by a colon `':'` and one or more bytes,
you can write these values starting at that memory location. *WozMon* will then display
the original value of the byte at the start address before writing.

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

The input can be terminated with `'^C'` without modifying the memory.

### Executing Code

Entering `R` will jump to the last examined address.

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

### Jump Table

*WozMon* provides a jump table at the beginning with fixed addresses
of useful subroutines for user programs:

- XX80: RESET   (WozMon cold start)
- XX83: GETCHAR (wait for char, return in A)
- XX86: OUTCHAR (output char in A)
- XX89: PRTBYTE (output byte in A as XX in HEX)
- XX8C: CRLFOUT (output CR, LF)

## Running *WozMon*

*WozMon* can be executed directly from the Z80-MBC2 menu with the command `'W'`.

After starting, Wozmon displays a backslash `'\'` and waits for input.

Display its own code with `fe80.ffb9` (in `WOZ` format):


```
\
fe80.ffb9
FE80: C3 96 FE C3 46 FF C3 AE
FE88: FF C3 97 FF 3E 0D CD AE
FE90: FF 3E 0A C3 AE FF 31 00
FE98: 00 FD 21 00 FE 18 0E FE
FEA0: 08 28 19 FE 03 28 06 FD
FEA8: 45 CB 78 28 1A CD 8C FE
FEB0: 3E 5C CD AE FF CD 8C FE
FEB8: FD 21 01 FE FD 2B FD 45
FEC0: CB 78 20 F1 CD 4F FF CD
FEC8: 46 FF FE 08 CC 4D FF FD
FED0: 23 FD 77 00 CD AE FF FE
FED8: 0D 20 C4 FD 21 00 FE AF
FEE0: DD 6F DD 67 CB 27 CB 27
FEE8: 32 B9 FF FD 23 FD 7E 00
FEF0: FE 0D 28 C1 FE 2E 38 F3
FEF8: 28 EA FE 3A 28 E8 FE 52
FF00: 20 02 DD E9 21 00 00 FD
FF08: 22 B7 FF FD 7E 00 EE 30
FF10: FE 0A 38 08 F6 20 CE 89
FF18: FE F9 38 15 CB 27 CB 27
FF20: CB 27 CB 27 06 04 17 CB
FF28: 15 CB 14 10 F9 FD 23 18
FF30: DA FD 45 3A B7 FF B8 CA
FF38: AD FE 3A B9 FF CB 77 28
FF40: 18 7D 12 13 18 A7 DB 01
FF48: FE FF 28 FA C9 FD 2B 3E
FF50: 20 CD AE FF 3E 08 C3 AE
FF58: FF CB 7F 20 26 54 5D E5
FF60: DD E1 BF C2 78 FF CD 8C
FF68: FE DD 7C CD 97 FF DD 7D
FF70: CD 97 FF 3E 3A CD AE FF
FF78: 3E 20 CD AE FF DD 7E 00
FF80: CD 97 FF AF 32 B9 FF DD
FF88: 7D BD DD 7C 9C 30 B5 DD
FF90: 23 DD 7D E6 07 18 CC F5
FF98: CB 3F CB 3F CB 3F CB 3F
FFA0: CD A4 FF F1 E6 0F F6 30
FFA8: FE 3A 38 02 CE 07 F5 3E
FFB0: 01 D3 01 F1 D3 00 C9 06
FFB8: FE 00

```


## Load and store

The python tool `hex2woz` converts an Intel HEX file into the `WOZ` format that
can be transfered with `iload` and will be read by *WozMon*.

```
./hex2woz < program.hex > program.woz
./iload -r program.woz
```

Also recent `iload` versions support the output in `WOZ` format with the cmd line
option `--woz` or `-w`.

```
./iload -r -w program.hex
```

To store Z80 programs from *WozMon* on the PC, display it in *WozMon* and copy/paste
it in the PC editor; to restore it, use `iload`.

### WOZ format

The `WOZ` format consists of the 16 bit hex address followed by 8 bit hex data.

    ADDR: DD DD DD DD ...

## Building

This project can be assembled using `ZASM by Megatokio`.

#### ZASM - Z80, 8080 Assembler

https://github.com/Megatokio/zasm

```
./zasm -uw --target=ram -x wozmon.asm -o wozmon.hex
```

