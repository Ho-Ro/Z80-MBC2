;**********************************************************************************
;
; Z80-MBC2 uBIOS for Basic - Test mode for IM2
;
; Adapted from Grant Searle great work!
;
;
; ************* WARNING!!!! ONLY FOR TESTING - DO NOT USE!!! **********************
; THIS VERSION IS INTENDED ONLY TO SHOW THE USE OF THE SHARED IRQ SCHEME OF 
; IOS S210718-R170591_DEVEL2
; *********************************************************************************
; 
;
;
; NOTE: all changes in the following code are marked with this string "Z80-MBC2:" in the comment
;       (the basic.asm file is not modified)
;
;**********************************************************************************
;==================================================================================
; Contents of this file are copyright Grant Searle
;
; You have permission to use this for NON COMMERCIAL USE ONLY
; If you wish to use it elsewhere, please include an acknowledgement to myself.
;
; http://searle.hostei.com/grant/index.html
;
; eMail: home.micros01@btinternet.com
;
; If the above don't work, please perform an Internet search to see if I have
; updated the web page hosting service.
;
;==================================================================================

SER_BUFSIZE     .EQU     3FH
SER_FULLSIZE    .EQU     30H
SER_EMPTYSIZE   .EQU     5

RTS_HIGH        .EQU     0D6H
RTS_LOW         .EQU     096H

serBuf          .EQU     $2000
serInPtr        .EQU     serBuf+SER_BUFSIZE
serRdPtr        .EQU     serInPtr+2
serBufUsed      .EQU     serRdPtr+2
basicStarted    .EQU     serBufUsed+1
TEMPSTACK       .EQU     $20ED ; Top of BASIC line input buffer so is "free ram" when BASIC resets

RST_20          .EQU     $E7             ; Z80 Opcode for INT
RST_28          .EQU     $EF             ; Z80 Opcode for INT
RST_30          .EQU     $F7             ; Z80 Opcode for INT
RST_38          .EQU     $FF             ; Z80 Opcode for INT

#IFDEF          INTMODE0
INT_MODE        .EQU     0
#ENDIF

#IFDEF          INTMODE1
INT_MODE        .EQU     1
#ENDIF

#IFDEF          INTMODE2
INT_MODE        .EQU     2
#ENDIF

                .ORG $0000
;------------------------------------------------------------------------------
; Reset

RST00:          DI                       ;Disable interrupts
                JP       HWINIT          ;Initialize Hardware and go

;------------------------------------------------------------------------------
; TX a character over RS232 

                .ORG     0008H
RST08:          JP      TXA

;------------------------------------------------------------------------------
; RX a character over RS232 Channel A [Console], hold here until char ready.

                .ORG 0010H
RST10:          JP      RXA

;------------------------------------------------------------------------------
; Check serial status

                .ORG 0018H
RST18:          JP      CKINCHAR

;------------------------------------------------------------------------------
; INTERRUPT VECTOR [ for IM 0 ]
;
#IFDEF          INTMODE0
                .ORG    $20
                ;JR      serialInt
#ENDIF

;------------------------------------------------------------------------------
; INTERRUPT VECTOR [ for IM 1 ]
;
#IFDEF          INTMODE1
                .ORG    $38
                ;JR      serialInt
#ENDIF

;------------------------------------------------------------------------------
; INTERRUPT VECTOR [ for IM 2 ]
;
#IFDEF          INTMODE2
                .ORG    (($+1) & $7E)   ; put vector at even address
VECTOR:         .WORD   serialInt
#ENDIF

;------------------------------------------------------------------------------
; *****************************************************************************
; NEW ISR ROUTINE WITH SHARED IRQ HANDLING (REQUIRED IOS S210718-R170591_DEVEL2
; *****************************************************************************
serialInt:      PUSH     AF
                PUSH     HL
                ;
                ; Z80-MBC2: check if SysTick IRQ is set
                ;
                LD       A,$89           ; A = SYSIRQ Opcode
                OUT      ($01),A         ; Write the Opcode to IOS
                IN       A,($00)         ; Read the SYSIRQ status byte in A
                LD       H,A             ; Save the SYSIRQ status byte in H
                AND      $02             ; Systick IRQ mask
                JR       Z,RxIRQCK       ; Jump to serial Rx IRQ check if Systick IRQ bit is not set
                ;
                ; Z80-MBC2: Systick ISR
                ;
                LD       A,(TickCount)   ; Decrement TickCount
                DEC      A
                LD       (TickCount),A
                JR       NZ,RxIRQCK      ; Jump if TickCount not zero
                LD       a,10            ; Set TickCount = 10
                LD       (TickCount),A
                LD       A,(UserLedStat) ; Change the User Led status
                XOR      1
                LD       (UserLedStat),A
                LD       L,A
                LD       A,$00           ; A = USERLED Opcode
                OUT      ($01),A         ; Write the Opcode to IOS
                LD       A,L
                OUT      ($00),A         ; Write the value
                ;
                ; Z80-MBC2: check if serial Rx IRQ is set
                ;
RxIRQCK:        LD       A,H             ; A = SYSIRQ status byte
                AND      $01             ; Serial Rx IRQ mask
                JR       Z,rts0          ; Jump if serial Rx IRQ bit is not set
                ;
                ; Z80-MBC2: Serial Rx ISR
                ;
                IN       A,($01)         ; Z80-MBC2: Changed port addr from $81 to $01
                PUSH     AF
                LD       A,(serBufUsed)
                CP       SER_BUFSIZE     ; If full then ignore
                JR       NZ,notFull
                POP      AF
                JR       rts0

notFull:        LD       HL,(serInPtr)
                INC      HL
                LD       A,L             ; Only need to check low byte becasuse buffer<256 bytes
                CP       (serBuf+SER_BUFSIZE) & $FF
                JR       NZ, notWrap
                LD       HL,serBuf
notWrap:        LD       (serInPtr),HL
                POP      AF
                LD       (HL),A
                LD       A,(serBufUsed)
                INC      A
                LD       (serBufUsed),A
rts0:           POP      HL
                POP      AF
                EI
                RETI

;------------------------------------------------------------------------------
RXA:
waitForChar:    LD       A,(serBufUsed)
                CP       $00
                JR       Z, waitForChar
                PUSH     HL
                LD       HL,(serRdPtr)
                INC      HL
                LD       A,L             ; Only need to check low byte becasuse buffer<256 bytes
                CP       (serBuf+SER_BUFSIZE) & $FF
                JR       NZ, notRdWrap
                LD       HL,serBuf
notRdWrap:      DI
                LD       (serRdPtr),HL
                LD       A,(serBufUsed)
                DEC      A
                LD       (serBufUsed),A
;rts1:
                LD       A,(HL)
                EI
                POP      HL
                RET                      ; Char ready in A

;------------------------------------------------------------------------------
TXA:
conout1:        PUSH     AF              ; Store character
                LD       A,$01           ; Z80-MBC2: (Added) A = Serial TX Operation Code
                OUT      ($01),A         ; Z80-MBC2: (Added) Write the Serial TX Opcode to IOS
                POP      AF              ; Retrieve character
                OUT      ($00),A         ; Z80-MBC2: Changed port addr from $81 to $01 ; Output the character
                RET

;------------------------------------------------------------------------------
CKINCHAR:       LD       A,(serBufUsed)
                CP       $0
                RET

PRINTS:         LD       A,(HL)          ; Get character
                OR       A               ; Is it $00 ?
                RET      Z               ; Then RETurn on terminator
                RST      08H             ; Print it
                INC      HL              ; Next Character
                JR       PRINTS          ; Continue until $00
                RET
;------------------------------------------------------------------------------
HWINIT:
                LD       A,0EH           ; SETIRQ opcode
                OUT      (01H),A
                LD       A,03H           ; Enable RX and SYSTICK IRQ
                OUT      (00H),A

#IFDEF          INTMODE0
                LD       A,13H           ; SETVECT opcode
                OUT      (01H),A
                LD       A,RST_20        ; Set RST 20 Z80 opcode as vector
                OUT      (00H),A
#ENDIF

#IFDEF          INTMODE1
#ENDIF

#IFDEF          INTMODE2
                LD       A,13H           ; SETVECT opcode
                OUT      (01H),A
                LD       A,VECTOR & $0FF ; LO byte of VECTOR
                OUT      (00H),A
                LD       A,VECTOR >> 8   ; HI byte of VECTOR
                LD       I,A
#ENDIF

                LD       HL,TEMPSTACK    ; Temp stack
                LD       SP,HL           ; Set up a temporary stack
                LD       HL,serBuf
                LD       (serInPtr),HL
                LD       (serRdPtr),HL
                XOR      A               ;0 to accumulator
                LD       (serBufUsed),A
                IM       INT_MODE
                EI
                LD       HL,SIGNON1      ; Sign-on message
                CALL     PRINTS          ; Output string
                LD       A,(basicStarted); Check the BASIC STARTED flag
                CP       'Y'             ; to see if this is power-up
                JR       NZ,COLDSTART    ; If not BASIC started then always do cold start
                LD       HL,SIGNON2      ; Cold/warm message
                CALL     PRINTS          ; Output string
CORW:
                CALL     RXA
                AND      %11011111       ; lower to uppercase
                CP       'C'
                JR       NZ, CHECKWARM
                RST      08H
                LD       A,$0D
                RST      08H
                LD       A,$0A
                RST      08H
COLDSTART:      LD       A,'Y'           ; Set the BASIC STARTED flag
                LD       (basicStarted),A
                JP       $0150           ; Start BASIC COLD
CHECKWARM:
                CP       'W'
                JR       NZ, CORW
                RST      08H
                LD       A,$0D
                RST      08H
                LD       A,$0A
                RST      08H
                JP       $0153           ; Start BASIC WARM

TickCount:      .BYTE    10
UserLedStat:    .BYTE    0
SIGNON1:        .BYTE    "BASIC47_IM",'0'+INT_MODE,$0D,$0A,0
SIGNON2:        .BYTE    $0D,$0A         ; Z80-MBC2: Changed SIGNON2 string
                .BYTE    "Cold / Warm start (C/W)?",0

                .ORG     $14F            ; Z80-MBC2: Last byte for this uBIOS (BASIC starts next one)!
LastByte:       .BYTE    $00

                .END

