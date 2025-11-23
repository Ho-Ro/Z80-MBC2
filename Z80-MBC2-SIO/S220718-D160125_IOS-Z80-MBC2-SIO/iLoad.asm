;
; Loader for the iLoad function, build with:
; - z80asm -b iLoad.asm
; - srec_cat iLoad.bin -binary -output iLoad.include -C-Array boot_A_ -Postfix PROGMEN
; and copy the array into the *.ino file
;
;

CR      equ     0Dh
LF      equ     0Ah
SPC     equ     20h

        ORG     0FD10h

LFD10:  LD      SP,$
        LD      HL,hello_msg
        CALL    puts
        CALL    crlf
;
; Load an INTEL-Hex file into memory
;
        CALL    ih_load
        LD      A,0FFh
        CP      H
        JR      NZ,print_addr
        CP      L
        JR      NZ,print_addr
;
; Print an error message and halt cpu
;
        LD      HL,ih_load_msg_4
        CALL    puts
        LD      HL,load_msg_2
        CALL    puts
        HALT
;
; Print starting address
;
print_addr:
        PUSH    HL
        LD      HL,ih_load_msg_4
        CALL    puts
        LD      HL,load_msg_1
        CALL    puts
        POP     HL
        CALL    print_word
        CALL    crlf
        CALL    crlf
;
; Flush remaining input data (if any) and jump to the loaded program
;
flush_rx:
        IN      A,(01h)
        CP      0FFh
        JR      NZ,flush_rx
        JP      (HL)
;
; Message definitions
;
hello_msg:
        defb "iLoad - Intel-Hex Loader - S200718", 0

load_msg_1:
        defb "Starting Address: ", 0

load_msg_2:
        defb "Load error - System halted", 0

ih_load_msg_1:
        defb "Waiting input stream...", 0

ih_load_msg_2:
        defb "Syntax error!", 0

ih_load_msg_3:
        defb "Checksum error!", 0

ih_load_msg_4:
        defb "iLoad: ", 0

ih_load_msg_5:
        defb "Address violation!", 0


;******************************************************************************
;***
;*** Subroutines
;***
;******************************************************************************
;
; Load an INTEL-Hex file (a ROM image) into memory. This routine has been
; more or less stolen from a boot program written by Andrew Lynch and adapted
; to this simple Z80 based machine.
;
; The first address in the INTEL-Hex file is considerd as the Program Starting Address
; and is stored into HL.
;
; If an error is found HL=$FFFF on return.
;
; The INTEL-Hex format looks a bit awkward - a single line contains these
; parts:
; ':', Record length (2 hex characters), load address field (4 hex characters),
; record type field (2 characters), data field (2 * n hex characters),
; checksum field. Valid record types are 0 (data) and 1 (end of file).
;
; Please note that this routine will not echo what it read from stdin but
; what it "understood". :-)
;
ih_load:
        PUSH    AF
        PUSH    DE
        PUSH    BC
        LD      BC,0FFFFh
        LD      HL,ih_load_msg_1
        CALL    puts
        CALL    crlf
ih_load_loop:
        CALL    getc
        CP      CR
        JR      Z,ih_load_loop
        CP      LF
        JR      Z,ih_load_loop
        CP      ' '
        JR      Z,ih_load_loop
        CALL    to_upper
LFE15:  CALL    putc
        CP      ':'
        JP      NZ,ih_load_err
        CALL    get_byte
        LD      D,A
        LD      E,00h
        CALL    ih_load_chk
        CALL    get_word
        LD      A,0FFh
        CP      B
        JR      NZ,update_chk
        CP      C
        JR      NZ,update_chk
        LD      B,H
        LD      C,L
update_chk:
        LD      A,H
        CALL    ih_load_chk
        LD      A,L
LFE38:  CALL    ih_load_chk
        CALL    get_byte
        CALL    ih_load_chk
        CP      01h
        JR      NZ,ih_load_data
        CALL    get_byte
        CALL    ih_load_chk
LFE4B:  LD      A,E
        AND     A
        JR      Z,ih_load_exit
ih_load_chk_err:
        CALL    crlf
        LD      HL,ih_load_msg_4
        CALL    puts
        LD      HL,ih_load_msg_3
        CALL    puts
        LD      BC,0FFFFh
        JR      ih_load_exit
ih_load_data:  LD      A,D
        AND     A
        JR      Z,LFE93
        CALL    get_byte
        CALL    ih_load_chk
        PUSH    HL
        PUSH    BC
        AND     A
        LD      BC,0FCF0h
        SBC     HL,BC
        POP     BC
        POP     HL
        JP      C,store_byte
        CALL    crlf
        LD      HL,ih_load_msg_4
        CALL    puts
        LD      HL,ih_load_msg_5
        CALL    puts
        LD      BC,0FFFFh
        JR      ih_load_exit
store_byte:
        LD      (HL),A
        INC     HL
        DEC     D
        JR      ih_load_data
LFE93:  CALL    get_byte
        CALL    ih_load_chk
        LD      A,E
        AND     A
        JR      NZ,ih_load_chk_err
        CALL    crlf
        JP      ih_load_loop

ih_load_err:
        CALL    crlf
        LD      HL,ih_load_msg_4
        CALL    puts
        LD      HL,ih_load_msg_2
        CALL    puts
        LD      BC,0FFFFh
ih_load_exit:
        CALL    crlf
        LD      H,B
        LD      L,C
        POP     BC
        POP     DE
        POP     AF
        RET

ih_load_chk:
        PUSH    BC
        LD      C,A
        LD      A,E
        SUB     C
        LD      E,A
        LD      A,C
        POP     BC
        RET

puts:
        PUSH    AF
        PUSH    HL
puts_loop:
        LD      A,(HL)
        CP      00h
        JR      Z,puts_end
        CALL    putc
        INC     HL
        JR      puts_loop
puts_end:
        POP     HL
        POP     AF
        RET

get_word:
        PUSH    AF
        CALL    get_byte
        LD      H,A
        CALL    get_byte
        LD      L,A
        POP     AF
        RET

get_byte:
        PUSH    BC
        CALL    get_nibble
        RLC     A
        RLC     A
        RLC     A
        RLC     A
        LD      B,A
        CALL    get_nibble
        OR      B
        POP     BC
        RET

get_nibble:
        CALL    getc
        CALL    to_upper
        CALL    is_hex
        JR      NC,get_nibble
        CALL    nibble2val
        CALL    print_nibble
        RET

is_hex:
        CP      'F'+1
        RET     NC
        CP      '0'
        JR      NC,is_hex_1
        CCF
        RET
is_hex_1:
        CP      '9'+1
        RET     C
        CP      'A'
        JR      NC,is_hex_2
        CCF
        RET
is_hex_2:
        SCF
        RET

to_upper:
        CP      'a'
        RET     C
        CP      'z'+1
        RET     NC
        AND     5Fh
        RET

nibble2val:
        CP      '9'+1
        JR      C,nibble2val_1
        SUB     7
nibble2val_1:
        SUB     '0'
        AND     0Fh
        RET

print_nibble:
        PUSH    AF
        AND     0Fh
        ADD     A,'0'
        CP      '9'+1
        JR      C,print_nibble_1
        ADD     A,7
print_nibble_1:
        CALL    putc
        POP     AF
        RET

crlf:
        PUSH    AF
        LD      A,CR
        CALL    putc
        LD      A,LF
        CALL    putc
        POP     AF
        RET

print_word:
        PUSH    HL
        PUSH    AF
        LD      A,H
        CALL    print_byte
        LD      A,L
        CALL    print_byte
        POP     AF
        POP     HL
        RET

print_byte:
        PUSH    AF
        PUSH    BC
        LD      B,A
        RRCA
        RRCA
        RRCA
        RRCA
        CALL    print_nibble
        LD      A,B
        CALL    print_nibble
        POP     BC
        POP     AF
        RET

putc:
        PUSH    AF
        LD      A,01h
        OUT     (01h),A
        POP     AF
        OUT     (00h),A
        RET

getc:
        IN      A,(01h)
        CP      0FFh
        JP      Z,getc
        RET
