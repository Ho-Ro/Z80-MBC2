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

On startup *WozMon* prints a `CR/LF` followed by a backslash `'\'`,
which is its prompt.

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

### Executing Code (Run)

By entering a hexadecimal address followed by `R` you can jump to this address.
*WozMon* will then display the value of the byte at the start address before jumping.
If you omit the address, `R` will jump to address `0000` - but without displaying the content at this address. At reset IOS-Z80-MBC2 puts a jump to WozMon at this address,
so the `R` alone resets WozMon unless the three bytes at 0000 were modified.


```
\
E000 R

E000: 31 (execute code at this address)
```
```
\
R
\
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

Display its own code with `fe80.ffb7` (in `WOZ` format):


```
\
fe80.ffb7
FE80: C3 96 FE C3 44 FF C3 AC
FE88: FF C3 95 FF 3E 0D CD AC
FE90: FF 3E 0A C3 AC FF 31 00
FE98: 00 18 0A FE 08 28 15 FE
FEA0: 03 28 02 18 1A CD 8C FE
FEA8: 3E 5C CD AC FF CD 8C FE
FEB0: FD 21 01 FE FD 2B FD 45
FEB8: CB 78 20 F1 CD 4D FF CD
FEC0: 44 FF FE 08 CC 4B FF FD
FEC8: 23 FD 45 CB 78 20 D6 FD
FED0: 77 00 CD AC FF FE 0D 20
FED8: C2 FD 21 00 FE AF DD 6F
FEE0: DD 67 CB 27 CB 27 32 B7
FEE8: FF FD 23 FD 7E 00 FE 0D
FEF0: 28 BB FE 2E 38 F3 28 EA
FEF8: FE 3A 28 E8 FE 52 20 02
FF00: DD E9 21 00 00 FD 22 B5
FF08: FF FD 7E 00 EE 30 FE 0A
FF10: 38 08 F6 20 CE 89 FE F9
FF18: 38 15 CB 27 CB 27 CB 27
FF20: CB 27 06 04 17 CB 15 CB
FF28: 14 10 F9 FD 23 18 DA FD
FF30: 45 3A B5 FF B8 CA A5 FE
FF38: 3A B7 FF CB 77 28 18 7D
FF40: 12 13 18 A7 DB 01 FE FF
FF48: 28 FA C9 FD 2B 3E 20 CD
FF50: AC FF 3E 08 C3 AC FF CB
FF58: 7F 20 26 54 5D E5 DD E1
FF60: BF C2 76 FF CD 8C FE DD
FF68: 7C CD 95 FF DD 7D CD 95
FF70: FF 3E 3A CD AC FF 3E 20
FF78: CD AC FF DD 7E 00 CD 95
FF80: FF AF 32 B7 FF DD 7D BD
FF88: DD 7C 9C 30 B5 DD 23 DD
FF90: 7D E6 07 18 CC F5 CB 3F
FF98: CB 3F CB 3F CB 3F CD A2
FFA0: FF F1 E6 0F C6 30 FE 3A
FFA8: 38 02 C6 07 F5 3E 01 D3
FFB0: 01 F1 D3 00 C9 00 00 00

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

The project can be assembled in two ways — both produce the identical
`Intel HEX` image starting at `0xFE80`:

- with the `zasm` assembler (ZASM by Megatokio) that is **included** in the
  project directory (ready to build, no extra install needed);
- with `zx80asm`, the local wrapper around the SLR Z80ASM that ships with
  `zxcc` (needs zxcc installed).

#### ZASM (included)

https://github.com/Megatokio/zasm

```
./zasm -uw --target=ram -x wozmon.z80 -o wozmon.hex
```

#### zx80asm (needs zxcc)

```
zx80asm wozmon/hfs
```

where `/h` generates the `Intel HEX` output file, `/f` selects a full
listing (2 passes through the source) and `/s` generates an alphabetized
symbol table (flags can be combined).

