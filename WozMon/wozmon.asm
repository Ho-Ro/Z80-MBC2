; Ported to  Bare-ROM z80 systems By Dr. Peker 2025
; Monitor can run on standalone z80 systems. All CP/M depencencies removed.
; BUFFER structure changed to run in flexible memory locations.
; Backspace BUG corrected.
; uses 8251 for serial I/O but also 6551 or 6850 can be used with minor changes.
; 8251 init code added and must be called once before using the monitor to run as
; standalone system.
; Wozmon for Z80 By Dr.Peker 2025
; inspired code from  Christian Welzel 2023
; Christian Welzel 2023 - www.welzel-online.ch
;
; Code can be compiled in Zasm assembler by following parameters:
; ./zasm -uw --target=ram -x wozmon.asm -o wozmon.hex

; IO map
;
; Adresses and opcodes for serial I/O
;
EX_OPC          .EQU    $00             ; EXECUTE READ/WRITE OPCODE port
STO_OPC         .EQU    $01             ; STORE OPCODE write port
RXD             .EQU    $01             ; SERIAL RX read port
OPC_TX          .EQU    $01             ; SERIAL TX opcode
OPC_RXAVAIL     .EQU    $8B             ; Number if input char

; Keys and Characters
;
CTRLC           .EQU    $03             ; ^C
BS              .EQU    $08             ; Backspace
LF              .EQU    $0A             ; Line Feed
CR              .EQU    $0D             ; Carriage Return
FF              .EQU    $0C             ; Form feed
ESC             .EQU    $1B             ; Escape
SPC             .EQU    ' '             ; Space
DOT             .EQU    '.'             ; Period
COLON           .EQU    ':'             ; Colon
BACKSL          .EQU    $5C             ; back slash


INBUF           .EQU    $FE00           ; must start at 0xXX00
stack_top       .EQU    $0000           ; stack grows down


                .ORG    INBUF+0x80

                jp      RESET           ; coldstart

                                        ; I/O jump table
;----------------------------------------------------------------------------------
; Z80-MBC2: RXD ROUTINE receives 1 byte from serial in to A REGISTER
GETCHAR         jp      GETCH           ; XX83: Wait for char, ret in A

;----------------------------------------------------------------------------------
; Z80-MBC2: TXD ROUTINE sends contents of A REGISTER to serial out
OUTCHAR         jp      OUTCH           ; XX86: out char in A

;----------------------------------------------------------------------------------
PRTBYTE         jp      PRBYT           ; XX89: out A as HEX

;----------------------------------------------------------------------------------
CRLFOUT         ld      a, CR           ; XX8C: out CR,LF
                call    OUTCH
LFOUT           ld      a, LF           ; destroys A (A=LF)
                jp      OUTCH


RESET           ld      sp,stack_top    ; Init Stack
                ld      iy,INBUF
                jr      ESCAPE

NOTCR           cp      BS              ; Backspace key?
                jr      z, BACKSPACE
                cp      CTRLC           ; ^C?
                jr      z, ESCAPE       ; Yes.
                ;inc     iy              ; Advance text index.

                ld      b, iyl          ; Auto ESC if line longer than 127.
                bit     7, b            ;   ...
                jr      z, NEXTCHAR     ;     jp if bit 7 is not set (plus)

ESCAPE          call    CRLFOUT
                ld      a, BACKSL       ; "\".
                call    OUTCH           ; Output it.

GETLIN          call    CRLFOUT
                ld      iy, INBUF + 1   ; Initialize text index.

BACKSPACE       dec     iy              ; Back up text index.
                ld      b, iyl          ; Beyond start of line, reinitialize.
                bit     7, b            ;   ...
                jr      nz, GETLIN      ; jp if bit 7 is set (minus)
                call    OVERWRITE       ; overwrite with SPC and BS

NEXTCHAR        call    GETCH           ; wait for char in A
                cp      BS              ; Backspace key?
                call    z, BACKPACK
                inc     iy
                ld      (iy), a         ; Add to text buffer.
                call    OUTCH           ; Display character.
                cp      CR              ; CR?
                jr      nz, NOTCR       ; No.

                ld      iy, INBUF       ; Reset text index. (DEFAULT ınbuf)
                xor     a               ; For XAM mode.
                ld      ixl, a          ; TAX  ; X=0.
                ld      ixh, a          ; Init ix = 0 ('R' w/o address jumps to $0000)
SETBLOCK        sla     a               ; Leaves $2E<<2 = $B8 if setting BLOK XAM
SETSTOR         sla     a               ; Leaves $3A<<1 = $74 if setting STOR mode.
                ld      (MODE), a       ; $00 = XAM, $74 = STOR, $B8 = BLOK XAM.
BLSKIP          inc     iy              ; Advance text index.
NEXTITEM        ld      a, (iy)         ; Get character.
                cp      CR              ; CR?
                jr      z, GETLIN       ; Yes, done this line.
                cp      DOT             ; '.' (0x2E)?
                jr      c, BLSKIP       ; all char < '.', skip delimiter.
                jr      z, SETBLOCK     ; Set BLOCK XAM mode.
                cp      COLON           ; ':' (0x3A)?
                jr      z, SETSTOR      ; Yes, set STOR mode.
                cp      'R'             ; RUN?
                jr      nz, NXTI1       ; No
                jp      (ix)            ; Yes, run user program.
NXTI1           ld      hl, $0000       ; $00 -> L and H.
                ld      (YSAV), iy      ; Save Y for comparison

NEXTHEX         ld      a, (iy)         ; Get character for hex test.
                xor     $30             ; Map digits to $0-9.
                cp      $0A             ; Digit?
                jr      c, DIG          ; Yes.
                                        ; A-F: $71-$76, a-f: $51-$56
                or      $20             ; map both to $71-$76
                adc     a, $89          ; Map letter "A"-"F" to $FA-FF.
                cp      $F9             ; Hex letter?
                jr      c, NOTHEX       ; No, character not hex.

DIG             sla     a
                sla     a               ; Hex digit to MSD of A.
                sla     a
                sla     a
                ld      b, 4            ; Shift count.
HEXSHIFT        rla                     ; Hex digit left, MSB to carry.
                rl      l               ; Rotate into LSD.
                rl      h               ; Rotate into MSD's.
                djnz    HEXSHIFT        ; Done 4 shifts?
                                        ; No, loop.
                inc     iy              ; Advance text index.
                jr      NEXTHEX         ; Always taken. Check next character for hex.

NOTHEX          ld      b, iyl          ; Check if L, H empty (no hex digits).
                ld      a, (YSAV)       ;   ...
                cp      b               ;     ...
                jp      z, ESCAPE       ; Yes, generate ESC sequence.

                ld      a, (MODE)       ; Load MODE to A
                bit     6, a            ; Test MODE byte: "overflow" bit
                jr      z, NOTSTOR      ; B6=1 is STOR, 0 is XAM and BLOCK XAM.

                ld      a, l            ; LSD's of hex data.
                ld      (de), a         ;   ...
                inc     de              ; Increment store index.

TONEXTITEM      jr      NEXTITEM        ; Get next command item.


GETCH           in      a,(RXD)         ; Read a char from "virtual" UART
                cp      $FF             ; Char? ($FF from UART = no char)
                jr      z, GETCH        ; No, loop until valid character
                ret


;Backspace bug removed with this code below
BACKPACK        dec     iy              ; Back up text index.
OVERWRITE       ld      a, SPC          ; Send space (overwrite)
                call    OUTCH
                ld      a, BS           ; and Backspace again.
                jp      OUTCH

NOTSTOR         bit     7, a
                jr      nz, XAMNEXT     ; B7 = 0 for XAM, 1 for BLOCK XAM.
SETADR          ld      de, hl          ; Copy hex data to 'store index'.
                push    hl              ; And to 'XAM index'.
                pop     ix              ;   ...
                cp      a               ; Set zero flag

NXTPRNT         jp      nz, PRDATA      ; NE means no address to print.
                call    CRLFOUT         ; Output it.
                ld      a, ixh          ; 'Examine index' high-order byte.
                call    PRBYT           ; Output it in hex format.
                ld      a, ixl          ; Low-order 'examine index' byte.
                call    PRBYT           ; Output it in hex format.
                ld      a, COLON        ; ":".
                call    OUTCH           ; Output it.

PRDATA          ld      a, SPC          ; Blank.
                call    OUTCH           ; Output it.
                ld      a, (ix)         ; Get data byte at 'examine index'.
                call    PRBYT           ; Output it in hex format.
XAMNEXT         xor     a
                ld      (MODE), a       ; 0 -> MODE (XAM mode).
                ld      a, ixl
                cp      l               ; Compare 'examine index' to hex data.
                ld      a, ixh
                sbc     a, h
                jr      nc, TONEXTITEM  ; Not less, so no more data to output.

                inc     ix              ; Increment 'examine index'.

MOD8CHK         ld      a, ixl          ; Check low-order 'examine index' byte
                and     a, $07          ; For MOD 8 = 0
                jr      NXTPRNT         ; Always taken.

PRBYT           push    af              ; Save A for LSD.
                srl     a
                srl     a
                srl     a               ; MSD to LSD position.
                srl     a
                call    PRHEX           ; Output hex digit.
                pop     af              ; Restore A.

PRHEX           and     $0F             ; Mask LSD for hex print.
                or      $30             ; Add "0".
                cp      $3A             ; Digit?
                jr      c, OUTCH        ; Yes, output it.
                adc     $07             ; Add offset for letter
                                        ;  and fall-through to OUTCH.

;----------------------------------------------------------------------------------
; Z80-MBC2: TXD ROUTINE sends contents of A REGISTER to serial out

OUTCH           push    af              ; Save TXD char
                ld      a, OPC_TX       ; TXD opcode
                out     (STO_OPC),a     ; Prepare execution
                pop     af
                out     (EX_OPC),a      ; Execute TXD
                ret

YSAV            dw      0
MODE            db      0


                .END
