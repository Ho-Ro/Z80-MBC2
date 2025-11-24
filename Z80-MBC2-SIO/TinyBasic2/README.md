# TINYBASIC

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
array `@` that occupies the remaining free RAM space. 

## TinyBASIC2

The 1st Z80 version was built and tested with my [Z80 dongle](https://github.com/Ho-Ro/Z80_dongle).
I converted the source code to Z80 and used the gained space to add some functionality - still using less than 2KB of code.

### Z80-MBC2 version

The I/O functions `ROUTC` and `CHKIO` and the memory size were modified for the `iLoad` command of the
[Z80-MBC2](https://github.com/Ho-Ro/Z80-MBC2).

*TinyBASIC2* can be build with the [zmac](https://github.com/gp48k/zmac) assembler.

### Commands

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
