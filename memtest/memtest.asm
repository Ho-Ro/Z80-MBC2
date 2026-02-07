; Z80-MBC2 MEMORY TEST PROGRAM
; James Pattinson 2018
;
; TESTS THE FOLLOWING REGIONS OF MEMORY
; $8500 - $FFFF			; Bit ugly but avoids this program and stack
; $0000 - $7FFF BANK 0
; $0000 - $7FFF BANK 1
; $0000 - $7FFF BANK 2

rx_port			.equ	$01				; IOS "serial Rx" read port address
opcode_port		.equ	$01				; IOS opcode write port address
exec_wport		.equ	$00				; IOS "execute opcode" write port address
exec_rport		.equ	$00				; IOS "execute opcode" write port address
tx_opcode		.equ	$01				; IOS "serial Tx" operation opcode
sb_opcode		.equ	$0d				; IOS "switch bank" opcode
sysflags_opcode		.equ	$83				; IOS "sysflags" opcode
wverbose_opcode		.equ	$7E				; IOS "write verbose" opcode
rverbose_opcode		.equ	$FE				; IOS "read verbose" opcode

eos				.equ	$00				; End of string
cr				.equ	$0d				; Carriage return
lf				.equ	$0a				; Line feed

	ORG $8000

	LD	SP, $84FF
	LD	A,wverbose_opcode
	OUT	(opcode_port),A
	LD	C,exec_wport
	OUT	(C),0
	LD	A,rverbose_opcode
	OUT	(opcode_port),A
	IN	A,(exec_rport)
	INC	A
	JP	NZ,NMOS	
	LD	HL, MSGCMOS
	JP	MOS
NMOS:
	LD	HL, MSGNMOS
MOS:
	CALL	puts
	LD	A,sysflags_opcode
	OUT	(opcode_port),A
	IN	A,(exec_rport)
	AND	$c0
	JP	NZ,RAM256
	LD	HL, MSG128
	CALL	puts
	LD	A,$03
	LD	(BANKS),A
	JP	RAMSIZE
RAM256:
	CP	$40
	JP	NZ,RAM512
	LD	HL, MSG256
	CALL	puts
	LD	A,$07
	LD	(BANKS),A
	JP	RAMSIZE
RAM512:
	LD	HL, MSG512
	CALL	puts
	LD	A,$0F
	LD	(BANKS),A
RAMSIZE:	
	LD	HL, MSGSTART
	CALL	puts

; test if any lower bank collides with the upper bank
	LD	A,$00
UNIQ1:
	LD	HL, MSGBANK1
	CALL	puts
	CALL	hexout
	CALL	SWBANK
	INC	A
	LD	(COLLISION-$8000),A
	LD	HL,COLLISION
	CP	(HL)
	JP	NZ,UNIQ2
	LD	HL, MSGUCOLLISION
	CALL	puts
	HALT
UNIQ2:	
	LD	HL, MSGUCOLOK
	CALL	puts
	LD	HL,BANKS
	CP	(HL)
	JP	C,UNIQ1
	
; Test if lower banks are colliding
	LD	A,$00
UNIQ3:
	LD	HL, MSGBANK1
	CALL	puts
	CALL	hexout
	CALL	SWBANK
	LD	HL, MSGBANK2
	CALL	puts
	LD	B,A
	LD	HL,COLLISION-$8000
	LD	A,(HL)
	DEC	A
	CALL	hexout
	CP	B
	JP	Z,UNIQ4
	LD	HL, MSGNONUNIQ
	CALL	puts
	LD	HL, FOUNDCOL 	; save collision count
	INC	(HL)
UNIQ4:	
	LD	A, B
	INC	A
	LD	HL,BANKS
	CP	(HL)
	JP	C,UNIQ3
	
; start upper bank ram tests
	LD	HL, MSGUPPER
	CALL	puts
	LD	HL, $8500
	LD	DE, $7BFF
	CALL	RAMTST
	CALL	CHKERROR

; start lower bank ram tests
	LD      A, $0
TESTBLOOP:
   	CALL    TESTBANK
	INC	A
	LD	HL,BANKS
	CP	(HL)
	JP      C,TESTBLOOP

;; 	LD	A, $0
;; BANKTST:
;; 	LD	HL, MSGBANK1
;; 	CALL	puts
;; 	CALL	hexout
;; 	LD	HL, MSGBANK2
;; 	CALL	puts
;; 	CALL	SWBANK
;; 	LD	B, A
;; 	LD	A, ($0000)
;; 	CALL	hexout
;; 	LD	A, B
;; 	INC	A
;; 	CP	$10
;; 	JP	NZ,BANKTST

	LD 	A,(FOUNDCOL)
	OR	A
	JP	Z, ALLGOOD
	LD	HL, MSGCOLFOUND1
	CALL	puts
	LD	A,(FOUNDCOL)
	CALL	hexout
	LD	HL, MSGCOLFOUND2
	CALL	puts

ALLGOOD:	
	LD	HL, MSGALLPASS
	CALL	puts

	HALT


CHKERROR:
	RET		NC
	LD		B, A
	PUSH	HL
	LD		HL, MSGERROR
	CALL	puts
	POP		HL
	CALL	dispadd
	LD		HL, MSGBITS
	CALL	puts
	LD		A, B
	CALL	hexout
	HALT

TESTBANK:
    ; A contains bank to switch to and test.
    ; Displays message and switches bank
	LD      B, A
    	LD	HL, MSGBANK
	CALL	puts
	CALL	hexout
	LD	A, cr
	CALL	putc
	ld	A, lf
	CALL	putc
	ld	A,B
	push 	af
	CALL	SWBANK
    	LD	HL, $0000
	LD	DE, $7FFF
	CALL	RAMTST
	CALL	CHKERROR
	pop	af
	LD	($0000),a
	RET
MSGCMOS         .BYTE   "CMOS Z80 found.", cr, lf, eos
MSGNMOS         .BYTE   "NMOS Z80 found!!!", cr, lf, eos
MSG128		.BYTE	"128", eos
MSG256		.BYTE   "256", eos
MSG512		.BYTE	"512", eos
MSGSTART	.BYTE	"kb RAM found. Memory test starting...", cr, lf, eos
NSGUNIQ		.BYTE	"uniqueness test startet", eos
MSGINFO		.BYTE	" bytes starting from address ", eos
MSGOK		.BYTE	"PASS", cr, lf, eos
MSGERROR	.BYTE	"Test failed at address ", eos
MSGBITS		.BYTE	" with bit pattern ", eos
MSG00		.BYTE	"Read and write 00000000 : ", eos
MSGFF		.BYTE	"Read and write 11111111 : ", eos
MSGAA		.BYTE	"Read and write 10101010 : ", eos
MSG55		.BYTE	"Read and write 01010101 : ", eos
MSGWLK		.BYTE	"Walking bit test        : ", eos
MSGUPPER	.BYTE	cr, lf, cr, lf, "Start bit tests", cr, lf, "first the upper bank", cr, lf, eos
MSGBANK		.BYTE	cr, lf, "Switching to BANK ", eos
MSGALLPASS	.BYTE	cr, lf, "All tests PASSED - HALT", cr, lf, eos
MSGBANK1	.BYTE   cr, lf, "Bank ", eos
MSGBANK2	.BYTE   " is stamped as ", eos
MSGUCOLOK	.BYTE	" check with upper bank ok.", eos	
MSGUCOLLISION	.BYTE	" collision with upper bank - HALT", cr, lf, eos
MSGNONUNIQ	.BYTE   " collision!", eos
MSGCOLFOUND1	.BYTE	"Found ", eos
MSGCOLFOUND2	.BYTE	" bank collisions - HALT", cr, lf, eos
	

	
SWBANK:
	LD	C, opcode_port
	LD	B, sb_opcode
	OUT     (C), B
	LD      C, exec_wport
	OUT     (C), A
	RET

RAMTST:
	; EXIT WITH NO ERRORS IF AREA SIZE IS 0
	LD		A, D
	OR		E
	RET		Z
	PUSH	HL
	LD		HL, DE
	CALL	dispadd
	LD		HL, MSGINFO
	CALL	puts
	POP		HL
	CALL	dispadd
	LD		A, cr
	CALL	putc
	LD		A, lf
	CALL	putc
	LD		B,D
	LD		C,E

	;FILL MEMORY WITH 0 AND TEST

	PUSH	HL
	LD		HL, MSG00
	CALL	puts
	POP		HL
	SUB		A
	CALL	FILCMP
	RET		C

	;FILL MEMORY WITH FF HEX AND TEST
	PUSH	HL
	LD		HL, MSGFF
	CALL	puts
	POP		HL
	LD		A, $FF
	CALL	FILCMP
	RET		C

	; FILL MEMORY WITH AA HEX AND TEST
	PUSH	HL
	LD		HL, MSGAA
	CALL	puts
	POP		HL
	LD		A, $AA
	CALL	FILCMP
	RET		C

	; FILL MEMORY WITH 55 HEX AND TEST
	PUSH	HL
	LD		HL, MSG55
	CALL	puts
	POP		HL
	LD		A, $55
	CALL	FILCMP
	RET		C

	PUSH	HL
	LD		HL, MSGWLK
	CALL	puts
	POP		HL
WLKLP:
	LD		A, $80		; BINARY 1000000
WLKLP1:
	LD		(HL), A		; STORE TEST PATTERN IN MEMORY
	CP		(HL)		; TRY TO READ IT BACK
	SCF					; SET CARRY N CASE OF ERROR
	RET		NZ			; RETURN IF ERROR
	RRCA				; ROTATE PATTERN 1 RIGHT
	CP		$80
	JR		NZ,WLKLP1	; CONT UNTIL BINARY 10000000 AGAIN
	LD		(HL), 0		; CLEAR BYTE JUST CHECKED
	INC		HL
	DEC		BC			; DEC AND TEST 16-BIT COUNTER
	LD		A, B
	OR		C			; CLEAR CARRY
	JR		NZ,WLKLP	; CONT UNTIL MEMORY TESTED
	PUSH	HL
	LD		HL, MSGOK
	CALL	puts
	POP		HL
	RET					; NO ERRORS

FILCMP:
	PUSH	HL			; SAVE BASE ADDRESS
	PUSH	BC			; SAVE SIZE OF AREA
	LD		E, A		; SAVE TEST VALUE
	LD		(HL), A		; STORE TEST VALUE IN FIRST BYTE
	DEC		BC			; REMAINING AREA = SIZE - 1
	LD		A, B		; CHECK IF ANY AREA REMAINS
	OR		C
	LD		A, E		; RESTORE TEST VALUE
	JR		Z, COMPARE	; BRANCH IF AREA WAS ONLY 1 BYTE

	; FILL REST OF AREA USING BLOCK MOVE
	; EACH ITERATION MOVES TEST VALUE TO NEXT HIGHER ADDRESS
	LD		D, H		; DESTINATION IS ALWAYS SOURCE + 1
	LD		E, L
	INC		DE
	LDIR				; FILL MEMORY

	; NOW THAT MEMORY HAS BEEN FILLED, TEST TO SEE IF
	; EACH BYTE CAN BE READ BACK CORRECTLY

COMPARE:
	POP		BC			; RESTORE SIZE OF AREA
	POP		HL			; RESTORE BASE ADDRESS
	PUSH	HL			; SAVE BASE ADDRESS
	PUSH	BC			; SAVE SIZE OF VALUE

	; COMPARE MEMORY AND TEST VALUE

CMPLP:
	CPI
	JR		NZ, CMPER	; JUMP IF NOT EQUAL
	JP		PE, CMPLP	; CONTINUE THROUGH ENTIRE AREA
						; NOTE CPI CLEARS P/V FLAG IF IT
						; DECREMENTS BC TO 0

	; NO ERRORS FOUND, SO CLEAR CARRY
	POP		BC			; BC = SIZE OF AREA
	POP		HL			; HL = BASE ADDRESS
	OR		A			; CLEARS CARRY
	PUSH	HL
	LD		HL, MSGOK
	CALL	puts
	POP		HL
	RET

	; ERROR EXIT, SET CARRY

CMPER:
	POP		BC
	POP		DE
	SCF
	RET

;
; Send a string to the serial line, HL contains the pointer to the string
;

puts			push	af
			push	hl
puts_loop		ld		a, (hl)
				cp		eos				; End of string reached?
				jr		z, puts_end		; Yes
				call	putc
				inc		hl				; Increment character pointer
				jr		puts_loop		; Transmit next character
puts_end		pop		hl
				pop		af
				ret

;
; Send a single character to the serial line (A contains the character)
;

putc			push	af				; Save A
				ld		a, tx_opcode	; A = IOS Serial Tx operation opcode
				out		(opcode_port), a; Send to IOS the Tx operation opcode
				pop		af				; Restore the output char into A
				out		(exec_wport), a ; Write A to the serial
				ret

;; Display '[aaaa]' - address of HL
dispadd:
		LD A, '['
		CALL putc
		LD A, H
		CALL hexout
		LD A, L
		CALL hexout
		LD A, ']'
		CALL putc
		RET

; OUTPUT VALUE OF A IN HEX ONE NYBBLE AT A TIME
hexout	PUSH BC
		PUSH AF
		LD B, A
		; Upper nybble
		SRL A
		SRL A
		SRL A
		SRL A
		CALL TOHEX
		CALL putc

		; Lower nybble
		LD A, B
		AND 0FH
		CALL TOHEX
		CALL putc

		POP AF
		POP BC
		RET

; TRANSLATE VALUE IN A TO 2 HEX CHAR CODES FOR DISPLAY
TOHEX:
		PUSH HL
		PUSH DE
		LD D, 0
		LD E, A
		LD HL, DATA
		ADD HL, DE
		LD A, (HL)
		POP DE
		POP HL
		RET

; LOOKUP TABLE FOR TOHEX ROUTINE
DATA:
		DEFB	30h ; 0
		DEFB	31h ; 1
		DEFB	32h ; 2
		DEFB	33h ; 3
		DEFB	34h ; 4
		DEFB	35h ; 5
		DEFB	36h ; 6
		DEFB	37h ; 7
		DEFB	38h ; 8
		DEFB	39h ; 9
		DEFB	41h ; A
		DEFB	42h ; B
		DEFB	43h ; C
		DEFB	44h ; D
		DEFB	45h ; E
		DEFB	46h ; F
BANKS:
		DEFB	00h
COLLISION:
		DEFB	00h
FOUNDCOL:	DEFB	00h
	
