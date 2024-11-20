	TITLE 'SYSTEM CONTROL BLOCK DEFINITION FOR CP/M3 BIOS'

	PUBLIC @CIVEC, @COVEC, @AIVEC, @AOVEC, @LOVEC, @BNKBF
	PUBLIC @CRDMA, @CRDSK, @VINFO, @RESEL, @FX, @USRCD 
        PUBLIC @MLTIO, @ERMDE, @ERDSK, @MEDIA, @BFLGS
	PUBLIC @DATE, @HOUR, @MIN, @SEC, ?ERJMP, @MXTPA


SCB$BASE EQU    0FE00H          ; BASE OF THE SCB

@CIVEC  EQU     SCB$BASE+22H    ; CONSOLE INPUT REDIRECTION 
                                ; VECTOR (WORD, R/W)
@COVEC  EQU     SCB$BASE+24H    ; CONSOLE OUTPUT REDIRECTION 
                                ; VECTOR (WORD, R/W)
@AIVEC  EQU     SCB$BASE+26H    ; AUXILIARY INPUT REDIRECTION 
                                ; VECTOR (WORD, R/W)
@AOVEC  EQU     SCB$BASE+28H    ; AUXILIARY OUTPUT REDIRECTION 
                                ; VECTOR (WORD, R/W)
@LOVEC  EQU     SCB$BASE+2AH    ; LIST OUTPUT REDIRECTION 
                                ; VECTOR (WORD, R/W)
@BNKBF  EQU     SCB$BASE+35H    ; ADDRESS OF 128 BYTE BUFFER 
                                ; FOR BANKED BIOS (WORD, R/O)
@CRDMA  EQU     SCB$BASE+3CH    ; CURRENT DMA ADDRESS 
                                ; (WORD, R/O)
@CRDSK  EQU     SCB$BASE+3EH    ; CURRENT DISK (BYTE, R/O)
@VINFO  EQU     SCB$BASE+3FH    ; BDOS VARIABLE "INFO" 
                                ; (WORD, R/O)
@RESEL  EQU     SCB$BASE+41H    ; FCB FLAG (BYTE, R/O)
@FX     EQU     SCB$BASE+43H    ; BDOS FUNCTION FOR ERROR 
                                ; MESSAGES (BYTE, R/O)
@USRCD  EQU     SCB$BASE+44H    ; CURRENT USER CODE (BYTE, R/O)
@MLTIO	EQU	SCB$BASE+4AH	; CURRENT MULTI-SECTOR COUNT
				; (BYTE,R/W)
@ERMDE  EQU     SCB$BASE+4BH    ; BDOS ERROR MODE (BYTE, R/O)
@ERDSK	EQU	SCB$BASE+51H	; BDOS ERROR DISK (BYTE,R/O)
@MEDIA	EQU	SCB$BASE+54H	; SET BY BIOS TO INDICATE
				; OPEN DOOR (BYTE,R/W)
@BFLGS  EQU     SCB$BASE+57H    ; BDOS MESSAGE SIZE FLAG (BYTE,R/O)  
@DATE   EQU     SCB$BASE+58H    ; DATE IN DAYS SINCE 1 JAN 78 
                                ; (WORD, R/W)
@HOUR   EQU     SCB$BASE+5AH    ; HOUR IN BCD (BYTE, R/W)
@MIN    EQU     SCB$BASE+5BH    ; MINUTE IN BCD (BYTE, R/W)
@SEC    EQU     SCB$BASE+5CH    ; SECOND IN BCD (BYTE, R/W)
?ERJMP  EQU     SCB$BASE+5FH    ; BDOS ERROR MESSAGE JUMP
                                ; (WORD, R/W)
@MXTPA  EQU     SCB$BASE+62H    ; TOP OF USER TPA 
                                ; (ADDRESS AT 6,7)(WORD, R/O)
	END
