# Tiny BASIC

 - [Palo Alto Tiny BASIC](#palo_alto_tiny_basic)
 - [TinyBASIC2](#tinybasic2)
## Palo Alto Tiny BASIC

```
;*************************************************************
;
;                 TINY BASIC FOR INTEL 8080
;                       VERSION 2.0
;                     BY LI-CHEN WANG
;                  MODIFIED AND TRANSLATED
;                    TO INTEL MNEMONICS
;                     BY ROGER RAUSKOLB
;                      10 OCTOBER,1976
;                        @COPYLEFT
;                   ALL WRONGS RESERVED
;
;*************************************************************
```

This was one of the first *Open Source* projects for a broader audience, written 1976 by
[Li-Chen Wang](https://en.wikipedia.org/wiki/Li-Chen_Wang) who coined the term *"Copyleft"*
to describe his concept. *Tiny BASIC* was created as a reaction to Bill Gates'
[An Open Letter to Hobbyists](https://en.wikipedia.org/wiki/An_Open_Letter_to_Hobbyists)
in which Gates emphasised his view that hobbyists who copied his *Altair BASIC*
interpreter software were stealing from him personally.

*Tiny BASIC* uses 16bit signed integer arithmetic with the operators `+`, `-`, `*`, `/`
and nested parantheses, has 26 staticly assigned variables `A` to `Z` and one dynamic
array `@()` that occupies the remaining free RAM space.

*Tiny BASIC* can be build with the [zmac](https://github.com/gp48k/zmac) assembler.

### Z80-MBC2 version `tinybasic8080.asm`

The I/O functions `ROUTC` and `CHKIO` were modified for the
[Z80-MBC2](https://github.com/Ho-Ro/Z80-MBC2).
I made some formatting changes w/o functional impact.

### Commands of the original Tiny BASIC

```
  "LIST"          ; List program code (DIRECT ONLY)
  "RUN"           ; Execute program (DIRECT ONLY)
  "NEW"           ; Clear program code (DIRECT ONLY)
  "NEXT"          ; Next loop iteration
  "LET"           ; Variable assignment, can be omitted
  "IF"            ; Test condition
  "GOTO"          ; Go to program line
  "GOSUB"         ; Call subroutine
  "RETURN"        ; Return from subroutine
  "REM"           ; Remark, ignore rest of line
  "FOR"           ; Start a program loop
  "INPUT"         ; Wait for KBD input
  "PRINT"         ; Output values
  "STOP"          ; Warm start
  "RND"           ; Function RND(RANGE), get random [0..RANGE[
  "ABS"           ; Function ABS(ARG), return absolute value of ARG
  "SIZE"          ; Constant SIZE, get size of free memory
  "TO"            ; Final value of loop counter
  "STEP"          ; Increment value for loop counter
  ">="            ; Operator greater or equal
  "#"             ; Operator not equal
  ">"             ; Operator greater than
  "="             ; Operator equal
  "<="            ; Operator less or equal
  "<"             ; Operator less than
```
## TinyBASIC2

```
TinyBASIC2

OK
>
```

This improved Z80 version is contained in the IOS and can be used in systems without SD card.

It was initially built and tested with my [Z80 dongle](https://github.com/Ho-Ro/Z80_dongle).
Originally written in 8080 syntax I converted it to the nicer Z80 syntax using the
[8080 z80](https://hc-ddr.hucki.net/wiki/doku.php/cpm/8080_z80) tool and assembled it with the
[zmac](https://github.com/gp48k/zmac) assembler
(with [one fix](https://github.com/Ho-Ro/zmac/tree/fix_hash)).

I also added some HW-oriented functionality like `GET(addr)`, `PUT addr,val,val,...`
as well as char constants (`'x'`) and hex constants that are written as `$xxxx`
and the possibility to print values as `uint16_t` in different number bases n=2..16
using the format specifier `%n`, e.g. `PRINT %16,expression,...` prints in unsigned hex
up to the end of this `PRINT` statement.
The BASIC statement `HALT` executes the Z80 opcode `HALT` that halts the CPU.

*TinyBASIC2* supports these operators with decreasing priority level.

- arithmetic
  - `*`, `/`, `&` (level 3)
  - `+`, `-`, `|` (level 2)

- logical
  - `=`, `#` or `<>`, `<=`, `<`, `>=`, `>` (level 1)

The *TinyBASIC2* interpreter with my additions still uses less than 2K ROM.


### TinyBASIC2 examples ###

This little code line uses my HW extensions to hex-dump the content of the program memory.

```
>10 for a=$900 to top-size-1; print #4,%16,get(a),; next a
>run
   $A  $0 $66 $6F $72 $20 $61 $3D $24 $39 $30 $30 $20 $74 $6F $20
  $74 $6F $70 $2D $73 $69 $7A $65 $2D $31 $3B $20 $70 $72 $69 $6E
  $74 $20 $23 $34 $2C $25 $31 $36 $2C $67 $65 $74 $28 $61 $29 $2C
  $3B $20 $6E $65 $78 $74 $20 $61  $D
OK
```

Each line starts with the line number stored as int16_t followed by the unchanged ASCII text finished with CR.
To save space commands can be abbreviated with a full stop (and become almost unreadable).

```
>10 f.a=$900 t.t.-s.-1;p.#4,%16,g.(a),;n.a
>run
   $A  $0 $66 $2E $61 $3D $24 $39 $30 $30 $20 $74 $2E $74 $2E $2D
  $73 $2E $2D $31 $3B $70 $2E $23 $34 $2C $25 $31 $36 $2C $67 $2E
  $28 $61 $29 $2C $3B $6E $2E $61  $D
OK
```

Depending on the context `t.` could either be the constant `top` or the statement `to`,
same for `get()` and `goto`.

The `USR()` function calls the Z80 opcode at address `TOP` (i.e. RAM end - 0x100) with the
argument passed in register `HL` and returns the result in register `HL`. This not very useful
example puts the Z80 opcodes `INC HL` and `RET` into the `USR` program space and calls it
via the funtion `USR(123)`.

```
>put top,$23,$c9; REM: INC HL;  RET

OK
>print usr(123)
     124

OK
```

The `USR` function can also be used to output single ASCII chars:

```
>put top,$7d,$d7,$c9; REM: LD A,L;  RST ROUTC;  RET
>for a='a' to 'z'; x=usr(a); next a; x=usr($0d)
abcdefghijklmnopqrstuvwxyz

OK
```

*TinyBASIC2* has no intrinsic commands for saving and restoring code. To save BASIC
programs, list the program code with the command `LIST` and copy&paste it into the
PC editor. To restore a saved program clear the code space with `NEW` and than
send the BASIC code using the `iload` tool.

### Z80-MBC2 version

TinyBASIC2 supports 62 KB RAM (0x0800-0xFFFF). The I/O functions `ROUTC` and `CHKIO`
were modified for the [Z80-MBC2](https://github.com/Ho-Ro/Z80-MBC2) IOS ports.

*TinyBASIC2* can be build with the [zmac](https://github.com/gp48k/zmac) assembler.

### Commands TinyBASIC2

```
  "LIST"          ; List program code (DIRECT ONLY)
  "RUN"           ; Execute program (DIRECT ONLY)
  "NEW"           ; Clear program code (DIRECT ONLY)
  "NEXT"          ; Next loop iteration
  "LET"           ; Variable assignment, can be omitted
  "IF"            ; Test condition
  "GOTO"          ; Go to program line
  "GOSUB"         ; Call subroutine
  "RETURN"        ; Return from subroutine
  "REM"           ; Remark, ignore rest of line
  "FOR"           ; Start a program loop
  "INPUT"         ; Wait for KBD input
  "PRINT"         ; Output values
  "?"             ; Short for PRINT
  "PUT"           ; PUT ADDR, EXPR, EXPR,... put bytes.. into RAM at ADDR++
  "STOP"          ; Warm start
  "HALT"          ; HALT the Z80 CPU
  "RND"           ; Function RND(RANGE), get random [0..RANGE[
  "ABS"           ; Function ABS(ARG), return absolute value of ARG
  "GET"           ; Function GET(ADR), get byte from memory at ADR
  "USR"           ; Function USR(ARG), call function at TOP, return HL
  "CALL"          ; Function CALL(ADR), call opcode at ADR
  "SIZE"          ; Constant SIZE, get size of free memory
  "TOP"           ; Constant TOP, get address of TEXT TOP = USRSPC
  "TO"            ; Final value of loop counter
  "STEP"          ; Increment value for loop counter
  "="             ; Operator equal
  "#"             ; Operator not equal
  "<>"            ; Operator not equal
  "<="            ; Operator less or equal
  "<"             ; Operator less than
  ">="            ; Operator greater or equal
  ">"             ; Operator greater than
```

