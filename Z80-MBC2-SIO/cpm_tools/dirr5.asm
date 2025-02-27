; DIRR5.ASM - Directory program with print and disk options - 01/07/86
;
; Based on the Archives-supplied "D.COM" for which the original source
; code and supplier of same cannot be located but may have originally
; been written in 'C' by Rick Rump.
;
; Enhancements written by James R. King     December 17,1983
;
;	 NOTE:  CAN BE USED WITH 8080, 8085 OR Z80 PROCESSORS.
;		SUPPORTS BOTH CP/M V2.2 AND CP/M V3.0. - IMH
;
;-----------------------------------------------------------------------
;
; 01/07/86  Adapted to CP/M 3.0 so people with Commodore C128, Osborne
;    v5     Executive One, and others with CP/M+ could use it as well as
;	    those with CP/M 2.2 versions.  Suggest you rename it D.COM
;	    on your working disk, as very easy to type.
;					- Irv Hoff W6FFC
;
; 12/09/85  Sorry for the new update so soon.  The 'A' option for "all"
;    v4     user areas did not work correctly with v3.	Pre-distribution
;	    versions worked fine, until I decided to write some tighter
;	    code in the options area - then failed to test it adequately
;	    before release.  My apology.  Hopefully I was the first to
;	    notice that problem, when I tried it on somebody else's big
;	    system.  It's fixed now.  The 'A' option in conjunction with
;	    the 'E' and 'S' options are a wonderful feature of this pro-
;	    gram.			- Irv Hoff
;
; 12/07/85  Rewritten for Intel 8080 code.  Eliminated need for macro
;    v3     libraries, can now be assembled with any normal assembler.
;	    Added "QUIT" routine so program may be easily aborted, also
;	    added a help guide.  Extensively revised the header section.
;	    Added a "N" (non-stop) option.  Rewrote the options to be
;	    compatible (where possible) with the SD directory program.
;	    Now checks both the 4th character of the file name as well
;	    as the last byte of the extent to see if the file has been
;	    archived, and displays an 'A' if using the 'E' option which
;	    shows attributes and archive bits.	This all but eliminates
;	    any need for (or advantage to) any highlighting or reverse
;	    video.  Now has an extra row for the filesize to display
;	    files over 100k without jamming them against the end of the
;	    file extent.  Made the special printer and terminal routines
;	    optional with assembly-time equates.  Rewrote the stack area
;	    which was backwards.  Numerous other changes.
;					- Irv Hoff
;
;-----------------------------------------------------------------------
;
NO	EQU	0
YES	EQU	0FFH		; Some assemblers cannot use NOT NO here
;
FALSE	EQU	NO
TRUE	EQU	NOT NO		; Some assemblers cannot use 0FFH here
;
;
; The following two must be TRUE or FALSE, the YES or NO won't work
; properly with some assemblers, which need a 16-bit value for "IF" con-
; ditionals, while others have to have a 8-bit value (such as 0FFH) for
; YES for DB strings, sorry but that's the only way it can be made to
; work properly with "any assembler".

PNTRSP	EQU	FALSE		; TRUE if using special printer calls
VIDEO	EQU	FALSE		; TRUE if using VIDEO for highligting,
;				;   reverse, etc., then set in proper
;				;   values for your terminal, starting
;				;   at TRMINI: label, below
;
; BDOS equates
;
BDOS	EQU	0005H		; CP/M BDOS entry point
DFCB	EQU	005CH		; Default file control block
ALTFCB	EQU	006CH		; Alternate file control block
SBUFFR	EQU	5000H		; Location of stolen 'DI' output
TBUF	EQU	0080H		; Default buffer location
;
RDCON	EQU	1		; CP/M console input function
WRCON	EQU	2		; Send character to console
WRLST	EQU	5		; List output
CONST	EQU	11		; Check console status
CPMVER	EQU	12		; CP/M version
SELDSK	EQU	14		; Select disk drive function
CLOSEF	EQU	16		; Close disk file function
SRFST	EQU	17		; Search for first FCB match
SRNXT	EQU	18		; Search for next FCB match
DELETE	EQU	19		; Delete file function
WRSEQ	EQU	21		; Write sequentially to disk function
MAKEF	EQU	22		; Make file function
CURDSK	EQU	25		; Get current disk function
STDMA	EQU	26		; Set direct memory access function
GETADR	EQU	27		; Get the allocation block address
PARMS	EQU	31		; Get disk parameters address
GETUSR	EQU	32		; Get (or set) the user code
;
;
CR	EQU	0DH		; ASCII carriage return
LF	EQU	0AH		; ASCII line feed
FF	EQU	0CH		; ASCII form feed
ESC	EQU	1BH		; ASCII escape code (lead-in)
PLINES	EQU	56		; Number of lines for page printer
;
;
;***********************************************************************
;
;
	ORG	100H
;
;
	JMP	START

;
; The user flags start at 0103H and can be changed from NO to YES to
; default to that option.
;
AFLAG:	DB	NO		; Checks all user areas
CFLAG:	DB	NO		; Compresses display by suppressing size
EFLAG:	DB	NO		; Extended display - users & attributes
FFLAG:	DB	NO		; Disk file flag
NFLAG:	DB	NO		; Non-stop flag
PFLAG:	DB	NO		; Printer off, YES = default to printer
SFLAG:	DB	NO		; Display system files if YES
VFLAG:	DB	NO		; Shows version number and date
;
	DB	0,0,0,0		; Reserved for 4 extra flag bytes
;
HEIGHT:	DB	24,0		; Lines per screen
NUMROW:	DB	4		; Number of rows per line
;
;
;=======================================================================
;      p r i n t e r   i n i t i a l i z a t i o n   c o d e s
;=======================================================================
;
; Enter the escape codes to be sent to the printer here, such as bold
; type, compressed type, etc.  Maximum of 15 user bytes, 16th must = 0.
; Sent to list device prior to sending any characters and only if the
; "$P" (output to list device) option is selected.
;
	 IF	PNTRSP
PTRONM:	DB	ESC,'Q'		; C. ITOH compressed (17 cpi) type
	DB	CR,LF		; Flush printer buffer
	DW	0,0,0,0,0,0	; Patch area fills to 012fh
;
;
; Enter the escape sequence to be sent to printer at conclusion of
; directory printing to clear the special effects introduced above.
; Maximum is 16 bytes and the last byte must be 0.  This is sent after
; all other text has been sent, to restore normal printer attributes.
;
PTROFM:	DB	ESC,'N'		; C. ITOH pica pitch (10 cpi.) select
	DB	CR,LF		; Flush buffer
	DB	FF,CR		; Form feed and flush again
	DW	0,0,0,0,0	; Patch area ends with "0"
	 ENDIF			; PNTRSP
;
;
;=======================================================================
;   t e r m i n a l   p a t c h  a r e a   b e g i n s	 h e r e
;=======================================================================
;
; Used to initialize terminal background.  This is sent prior to any
; characters fron the directory listing.
;
	 IF	VIDEO
TRMINI:	DB	ESC,019H	; Set attributes for normal background
	DW	0,0		; During directory screen display. sent
	DW	0,0		; To terminal before anything else.
	DW	0,0,0		; User gets 15 bytes, 16th must be = 0
;
FGNDON:	DB	ESC,01FH	; Code required to highlight, underline,
	DW	0,0,0		;   etc.  Sent to terminal before send-
				;   ing character with bit 7 set ($R/O,
				;   $SYS  or archived) file flag indi-
				;   cator in screen display.  Sequence
				;   is used for highlighting, underlin-
				;   ing, inverse video, etc. as desired.
;
FGNDOF:	DB	ESC,019H	; Code to "UNDO" the above after one
	DW	0,0,0		;   special character has been sent.
				;   Returns attributes to normal.  May
				;   use the same code "TRMINI" above.
				;   8 bytes, must end with 0.be
;
CRSRUP:	DB	CR		; Move cursor to far left column, move
	DB	ESC,0CH		;   cursor up one line (HZ1500)  Patch
	DB	0,0,0,0,0	;   area must end with 0.  User gets 7
				;   7 bytes, 8th must = 0
;
CLREOL:	DB	ESC,0FH		; Patch clear to end-of-line code here
	DW	0,0,0		;   supported by your terminal.  Cannot
				;   exceed 7 bytes, 8th byte must be 0.
;
;
; "TRMUNI" is sent to the terminal after all directory characters have
; been sent to the terminal. this is used to restore the normal terminal
; characteristics.

TRMUNI:	DB	ESC,019H	; Background follows (HZ1500)
	DW	0,0,0		; 15 bytes for user to restore normal
	DW	0,0,0,0		;   screen attributes prior to return to
				;   CP/M, last byte must be 0.
;
PG2MSG:	DB	CR,LF,0FH	; Sent after hitting space for next page
	DW	0,0,0,0		;   display, insert carriage return and
				;   'clear to end of line' code here.
				;   Else insert CR,LF
	 ENDIF			; VIDEO
;
;
;=======================================================================
;	     s t a r t	 o f   m a i n	 p r o g r a m
;=======================================================================
;
;
START:	LXI	H,0
	DAD	SP		; Get CCP stack in <HL>
	SHLD	STACK		; Save for direct exit to CCP
	LXI	SP,STACK	; Set up the local stack
;
;
; Program to run the directory program, send the directory to the print-
; er printer if 'P' toggle is set, save the directory output to a disk
; file if the 'F' toggle is set, and return to CP/M command without in-
; voking a warm reboot.
;
SETUP:	LHLD	BDOS+1		; Get BDOS vector in <HL>
	SHLD	HERE+1		; Store in the 'save' routine
	SHLD	LSTOT1+1	; Store in the printer output routine
	SHLD	SNDC1+1		; Store in the console output routine
	LHLD	HEIGHT		; Compensate for the [more] message
	DCX	H
	SHLD	HEIGHT		; Screen height minus [more] message
	LDA	NFLAG		; Non-stop flag set to default?
	ORA	A
	JZ	SETUP1		; If not, exit
	LXI	H,0FFFFH
	SHLD	HEIGHT		; Else prevent any stopping
;
;
; Get command for enhancements portion of program
;
SETUP1:	LXI	H,DFCB+1	; Point to command line tail
	MOV	A,M		; Get a byte in the accumulator
	CPI	'$'		; Dollar sign there?
	JZ	SETUP2		; Yes, check the command tail
	LXI	H,DFCB+17	; Check alternate FCB too
	MOV	A,M		; Get that byte to check for "$"
	CPI	'$'		; Well, is there one here?
	JNZ	CKFNDO		; No, use defaults
;
;
; We scan whichever file control block we find the "$" heading in while
; looking for the printer, file non-stop toggles.  (no "$", no scan.)
; Original program will scan file control block for the rest of them.
;
SETUP2:	INX	H		; Bump the pointer to the next byte
	MVI	B,8		; We will check 9 bytes for options
;
SETUP3:	PUSH	B		; Save the count
	PUSH	H		; Save the memory pointer
	MOV	A,M		; Get a byte from tail (isn't this fun?)
	ANI	7FH		; Strip off any parity
	CPI	'?'		; Help wanted?
	JZ	HELP		; Exit if help is requested
	CPI	'F'		; Disk file save flag
	CZ	STSAVF		; Set the flag true
	CPI	'N'		; Non-stop request
	CZ	NOSTOP		; Set the non-stop flag
	CPI	'P'		; Want a printer copy?
	CZ	SPFLAG		; Set the printer flag
	POP	H		; Restore memory pointer
	INX	H		; Bump the pointer
	POP	B		; Restore count to <BC>
	DCR	B
	JNZ	SETUP3		; Loop until done
;
CKFNDO:	LDA	FFLAG		; Making a disk file?
	ORA	A
	CNZ	SNITCH		; Yes, set up for data capture
	LDA	PFLAG		; Get the printer toggle flag
	ORA	A		; Is flag set to true?
	CNZ	PTRON		; Turn printer on if so
	LXI	SP,STACK	; Expected <SP> location
	CALL	DBEGIN		; Now do the directory
	JMP	EXITJ		; Do the exit routine
;.....
;
;
;=======================================================================
;	      m a i n	o p e r a t i n g   l o o p
;=======================================================================
;
DBEGIN:	CALL	SELDRV		; Select proper drive
	CALL	SEARCH		; Search for requested files
	XRA	A
	LXI	D,XTNL10	; Get address of (?????) in <DE>
	CALL	A0B23
	ORA	L
	JZ	A022D
	MVI	A,1
	LXI	H,XTNL10
	CALL	A0B2E
	JNC	A022A
	CALL	A04AA
;
A022A:	CALL	A0665
;
A022D:	XRA	A
	LXI	D,XTNL0E
	CALL	A0B23
	ORA	L		; Did we find any files that match?
	JZ	XIT		; Exit if no files to display
	CALL	SIGNON		; Else we are on our way
;
XIT:	CALL	SUMMRY		; Get and display disk parameters
	RET			; Exit from directory program here
;.....
;
;
SPACE1:	MVI	C,' '		; ASCII space in <C> for F2OUT
;
SP1A:	JMP	F2OUT		; Send space to console, auto return
;
CRLF:	MVI	C,CR		; ASCII carriage return in <C> for F2OUT
	CALL	F2OUT		; Send the CR
	MVI	C,LF		; ASCII line feed in <C> for F2OUT
	JMP	SP1A		; Send the line feed, auto return
;.....
;
;
A0256:	LXI	H,XTNL42
	MOV	M,D
	DCX	H
	MOV	M,E
	DCX	H
	MOV	M,B
	DCX	H
	MOV	M,C
	LXI	B,XTNL41
	LXI	D,XTNL3F
	CALL	CMP16B		; 16B compare sets carry if (BC) < (DE)
	LHLD	XTNL41
	RNC			; @@@ added
	LHLD	XTNL3F
	RET
;.....
;
;
GETCMD:	LDA	DFCB+1		; Beginning of command tail
	CPI	'?'
	JNZ	GETCME
	LDA	DFCB+2		; Check 2nd character
	CPI	' '
	JZ	HELP
;
GETCME:	CPI	'$'		; Request delimiter there?
	JNZ	A028E		; Skip if not there
	LXI	B,12		; 12 characters to move
	PUSH	B		; Store 12 on stack
	LXI	D,ALTFCB	; <DE> points to alt FCB (destination)
	LXI	B,DFCB+1	; <BC> points to FCB (source)
	CALL	MOVMEM		; Move the FCB to new location
	LXI	H,DFCB+1	; Back to the first character
	MVI	M,' '		; Insert an ASCII space there
;
;
; Initialize the options flag area (original toggles)
;
A028E:	LXI	H,FLGIND	; Initialize the options flag area
	MVI	M,0
	LXI	H,XTNL43
	MVI	M,0
;
FLSCAN:	CALL	QUIT		; Want to quit?
	LXI	D,12
	LDA	XTNL43
	CALL	A0B0C
	JC	CFLGCK		; Check compressed filesize flag
;
	LHLD	XTNL43		; <L> = flag
	MVI	H,0		; Zap <H> but leave <L> in place
	LXI	B,ALTFCB	; Point to alternate file control block
	DAD	B		; Alt FCB address in <HL>
	MOV	A,M		; Get first byte
	STA	XTNL44		; Store it for later reference
	CPI	'A'		; Want to check all user areas?
	JNZ	C1		; Not there, check for other commands
	STA	AFLAG
;
C1:	LDA	XTNL44
	CPI	'C'		; Check for "compressed" toggle
	JNZ	E1		; Not there, check for other commands
	STA	CFLAG		; And store it at the proper location
;
E1:	LDA	XTNL44
	CPI	'E'		; Check for "extended" toggle
	JNZ	N1		; Not there, check for other commands
	STA	EFLAG		; And store it for later reference
;
N1:	LDA	XTNL44
	CPI	'N'		; Check for non-stop
	JNZ	S1
	MVI	A,0FFH
	STA	HEIGHT
	STA	HEIGHT+1
;
S1:	LDA	XTNL44
	CPI	'S'		; Want to check system files also?
	JNZ	V1		; Not there, check for other commands
	STA	SFLAG		; And store it at the proper location
;
V1:	LDA	XTNL44
	CPI	'V'
	JNZ	A02F4
	STA	VFLAG
;
A02F4:	LXI	H,XTNL43
	INR	M
	JMP	FLSCAN		; Loop until done
;.....
;
;
CFLGCK:	LDA	CFLAG		; Check for filesize
	ORA	A		; Carry flag is set if flag is "YES"
	JZ	ENHCK		; No, check for "extended"
	LXI	H,NUMROW	; Point to number of rows per line
	INR	M		; Add one, file size not being used
	RET
;.....
;
;
; Here we check for extended option & reduce screen width if EFLAG "YES"
;
ENHCK:	LDA	EFLAG		; Get 'extended' flag in <A>
	ORA	A
	RZ			; No, finished
	LXI	H,NUMROW	; Byte for number of rows per line
	DCR	M		; Additional information, reduce by one
	RET
;.....
;
;
PAGECK:	LXI	B,HEIGHT	; 'Number of lines on screen' byte
	LXI	D,LINECT	; Line count storage location
	CALL	CMP16B		; Sets carry if BC<DE
	ORA	L		; Align CPU flags
	SUI	1		; Make one less for subtract with borrow
	SBB	A		; 0FFH if BC=DE, else 00H
	RNC			; Done here if no carry
	LXI	B,HTSPCM	; Point to the '[more]' message
	CALL	SNDCON		; Tell user to hit space (console only)
	LDA	PFLAG		; Get printer flag byte
	INR	A		; Is the printer on?
	CZ	FORMFD		; Send formfeed to printer if it is on
	MVI	C,RDCON		; Wait for a keyboard response
	CALL	BDOS
;
	 IF	VIDEO
	LXI	B,PG2MSG	; Start a new line, clear to end of line
	JMP	SNDMSG
	 ENDIF			; VIDEO
;
	RET
;.....
;
;
SELDRV:	CALL	GETCMD		; Get command tail info
	LDA	DFCB		; Get first byte of tail in <acc>
	ORA	A		; Contains ASCII space if "$" delimited
				;   command follows in alt FCB, else
				;   drive code if other drive requested
	JZ	WLDCRD		; Default to current drive if empty
	DCR	A		; Reduce by one for disk select function
	MOV	E,A		; In <E> for disk select
	MVI	C,SELDSK	; CP/M disk select function
	CALL	BDOS		; Completes disk select
;
WLDCRD:	LDA	DFCB+1		; Check for contents of command tail
	CPI	' '		; ASCII blank indicates wildcard search
	JNZ	USER		; Skip if no ASCII space
	MVI	C,11		; Number of bytes to fill
	PUSH	B		; Save the count
	MVI	E,'?'		; Fill with "???????????" for wildcard
	LXI	B,DFCB+1	; Beginning of area to be filled
	CALL	FILL		; Fill it
;
USER:	LDA	AFLAG		; Get "USER" flag - true if $A appeared in tail
	RAR			; Set carry flag if false
	JNC	GUSRCD		; Get user code if true - skip if false
	LXI	H,INTFCB	; User code storage location is first byte
	MVI	M,'?'		; ASCII "?" for search of all user areas
	JMP	MKFCB		; Make a file control block
;
GUSRCD:	LXI	D,0FFH		; 0FFH in <E> for "GET"
	MVI	C,GETUSR	; Get/set user function
	CALL	BDOS		; Get current user code in <A>
	STA	INTFCB		; Store user code in memory
;
MKFCB:	MVI	C,11		; Number of bytes in filename+ext
	PUSH	B		; Save the count in <C>
	LXI	D,INTFCB+1	; Internal file control block for search parms
	LXI	B,DFCB+1	; Beginning of dfcb input/output line
	CALL	MOVMEM		; Move the DFCB to the internal FCB
;
;
; Now fill the default file control block with question marks
;
	MVI	C,13		; <C> contains number of bytes to fill
	PUSH	B		; Save count in <C> on stack
	MVI	E,'?'		; Fill with ASCII "?"
	LXI	B,DFCB		; Point to the default file control block
	CALL	FILL		; Fill the DFCB with ?????
	MVI	C,PARMS		; Get disk parameter address in <HL>
	CALL	BDOS
	LXI	D,INTDPB	; Store 15 bytes into INTDPT area
	MVI	B,15
;
RPTFCB:	MOV	A,M
	STAX	D
	INX	D
	INX	H
	DCR	B
	JNZ	RPTFCB
	LXI	H,STACK		; Get address of stack in <HL>
	SHLD	STAKAD		; Save the address of the stack here
	LHLD	DPBDRM		; Get maximum number of entries possible in dir
	INX	H		; Add one for zero offset
	INX	H		; Then another for headroom
	DAD	H		; Double it
	XCHG			; Now put it in <DE>
	LHLD	STAKAD		; Get address of stack in <HL>
	DAD	D		; Add them together
	SHLD	LSTLOC		; Store the sum here as pointer for first entry
	LHLD	DPBBLM		; <L> = block mask, <H> = extent mask
	MVI	H,0		; Eliminate the extent mask
	INX	H		; Add for zero offset
	MVI	C,007H		; Multiplier for use in H2CPWR routine
	CALL	H2CPWR		; Multiply <HL>*<HL>, <C> times
	SHLD	XTNL21
	LHLD	DPBDRM		; <HL> = number of directory entries possible
	INX	H		; Add one for zero offset
	SHLD	XTNL23
	MVI	C,10
	LXI	H,XTNL21
	CALL	A0AF2
	SHLD	XTNL25
	MVI	A,0FFH
	LXI	H,DPBDSM	; Point to disk storage capacity data in DPB
	CALL	A0B2E
	SBB	A
	STA	XTNL27
	RET
;.....
;
;
; Search the directory for the files specified on the command line
;
SEARCH:	LXI	D,DFCB		; Point to default file control block
	MVI	C,SRFST		; Search for first match function
	CALL	BDOS		; Get first match at 080H + 32*offset
	STA	NDSRCH		; A*32 = offset from 080H = start pos.
;
;
; Now get all the files that match our requirements written into memory
; as they come into the buffer area at 080H.
;
GETONE:	LDA	NDSRCH		; Get a directory entry in buffer at 080H + offset
	CPI	0FFH		; Did the last pass reach the end of matches
	RZ			; And done here if no more matches
	LDA	NDSRCH		; Redundant load gets last offset in <acc>
	ANI	3		; Strip all but 2l
	ADD	A		; Multiply accumulator by 32
	ADD	A		; *4
	ADD	A		; *8
	ADD	A		; *16
	ADD	A		; *32 = offset now in <A>
	ADI	080H		; Dma address + offset = true address of fn.ext
	MOV	L,A		; Put the address in <L>
	MVI	H,0		; Put 0 in <H> since we are in page 0
	SHLD	BUFLOC		; Store the buffer location here
	MOV	A,M		; Get the first byte in <A>
	CPI	0E5H		; Has it been erased?
	JZ	SNEXT		; Search for next match if so
	LHLD	XTNL23		; Else get (?) in <HL>
	DCX	H		; Decrease it one
	SHLD	XTNL23		; And put the decremented (?) back in same place
	LHLD	BUFLOC		; Get the buffer location in <HL>
	MOV	B,H		; And transfer it to <BC>
	MOV	C,L
	CALL	A0A59		; (?)
	RAR			; Rotate LSB into carry
	JNC	SNEXT		; Search for next match if no carry
	LXI	B,16		; Number of bytes to move
	LHLD	BUFLOC		; Where to get them
	DAD	B		; Add the count
	MOV	B,H		; Move <HL> to <BC>
	MOV	C,L		; <BC> now = <HL>
	CALL	A0A7F
	LXI	B,13
	PUSH	H
	LHLD	LSTLOC
	DAD	B
	POP	B
	MOV	M,C
	INX	H
	MOV	M,B
	LHLD	XTNL0C
	DAD	B
	SHLD	XTNL0C
	MVI	L,11
	PUSH	H
	LHLD	BUFLOC
	INX	H
	MOV	B,H
	MOV	C,L
	LHLD	LSTLOC
	XCHG
	POP	H
;
A0465:	LDAX	B
	STAX	D
	INX	B
	INX	D
	DCR	L
	JNZ	A0465
	LHLD	BUFLOC		; Get buffer location in <HL>
	LXI	B,11		; Number of characters in filename+ext
	PUSH	H
	LHLD	LSTLOC		; Last used location in <HL>
	DAD	B		; Add 11 to last used location
	POP	D
	LDAX	D
	MOV	M,A
	LHLD	XTNL10
	INX	H
	SHLD	XTNL10
	DAD	H
	XCHG
	LHLD	STAKAD		; Get the address of the stack in <HL>
	DAD	D
	PUSH	H
	LHLD	LSTLOC		; Get last location used in <HL>
	XCHG			; Now in <DE>
	POP	H
	MOV	M,E
	INX	H
	MOV	M,D
	LXI	D,15		; Number of bytes in memory per filename stored
	LHLD	LSTLOC		; Last location used
	DAD	D		; Add 15 to the last location used
	SHLD	LSTLOC		; And store it for the next pass
;
SNEXT:	LXI	D,0		; Zap <DE>
	MVI	C,SRNXT		; Search for next function call
	CALL	BDOS		; Continue the search beginning at last found
	STA	NDSRCH		; Returns 0FFH if no more matches
	JMP	GETONE		; Get one (more) directory entry that matches
;....
;
;
A04AA:	LXI	H,XTNL53
	MVI	M,1
	LXI	H,1
	SHLD	XTNL56
	LHLD	XTNL10
	SHLD	XTNL6E
;
A04BB:	XRA	A		; Zap <A>
	LXI	H,XTNL53	; Point to (?)
	CMP	M
	RNC			; Return if no carry
	LHLD	XTNL53
	MVI	H,0
	LXI	B,XTNL54
	DAD	H		; Multiply <HL> by 2
	DAD	B
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
	SHLD	XTNL4B
	DCX	B
	LDAX	B
	MOV	C,A
	MVI	B,0
	LXI	H,XTNL6C
	DAD	B
	DAD	B
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
	SHLD	XTNL4D
	LDA	XTNL53
	DCR	A
	STA	XTNL53
;
A04ED:	LXI	B,XTNL4D
	LXI	D,XTNL4B
	CALL	CMP16B		; 16b compare sets carry if (BC) < (DE)
	JNC	A04BB
	LHLD	XTNL4B
	SHLD	XTNL47
	LHLD	XTNL4D
	SHLD	XTNL49
	XCHG
	LHLD	XTNL4B
	DAD	D		; Get XTNL4D + XTNL4B in <HL>
	MVI	C,1
	CALL	A0AF6
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
	SHLD	XTNL4F
;
A051C:	LXI	D,XTNL49
	LXI	B,XTNL47
	CALL	CMP16B		; 16B compare sets carry if (BC) < (DE)
	JC	A05C7
;
A0528:	LHLD	XTNL47
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	MOV	C,M
	INX	H
	MOV	B,M
	LHLD	XTNL4F
	XCHG
	CALL	CMPR12
	CPI	0FFH
	JNZ	A054A
	LHLD	XTNL47
	INX	H
	SHLD	XTNL47
	JMP	A0528		; Loop until done
;.....
;
;
A054A:	LHLD	XTNL49
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M
	LHLD	XTNL4F
	MOV	B,H
	MOV	C,L
	CALL	CMPR12
	CPI	0FFH
	JNZ	A056D
	LHLD	XTNL49
	DCX	H
	SHLD	XTNL49
	JMP	A054A		; Loop until done
;.....
;
;
A056D:	LXI	D,XTNL49
	LXI	B,XTNL47
	CALL	CMP16B		; 16B compare sets carry if (BC) < (DE)
	JC	A051C
	LHLD	XTNL47
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
	SHLD	XTNL51
	LHLD	XTNL49
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	PUSH	H
	LHLD	XTNL47
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	XTHL
	MOV	C,M
	INX	H
	MOV	B,M
	POP	H
	MOV	M,C
	INX	H
	MOV	M,B
	LHLD	XTNL49
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	PUSH	H
	LHLD	XTNL51
	XCHG
	POP	H
	MOV	M,E
	INX	H
	MOV	M,D
	LHLD	XTNL47
	INX	H
	SHLD	XTNL47
	LHLD	XTNL49
	DCX	H
	SHLD	XTNL49
	JMP	A051C		; Back to beginning of big loop
;.....
;
;
A05C7:	LXI	B,XTNL4B
	LXI	D,XTNL49
	CALL	CMP16B		; 16B compare sets carry if (BC) < (DE)
	LXI	B,XTNL47
	LXI	D,XTNL4D
	PUSH	H
	CALL	CMP16B		; 16B compare sets carry if (BC) < (DE)
	POP	D
	CALL	A0B05
	JNC	A0621
	LXI	B,XTNL4D
	LXI	D,XTNL47
	CALL	CMP16B		; 16B compare sets carry if (BC) < (DE)
	JNC	A0618
	LDA	XTNL53
	INR	A
	STA	XTNL53
	MOV	C,A
	MVI	B,0
	LXI	H,XTNL54
	DAD	B
	DAD	B
	PUSH	H
	LHLD	XTNL47
	XCHG
	POP	H
	MOV	M,E
	INX	H
	MOV	M,D
	LHLD	XTNL53
	MVI	H,0
	LXI	B,XTNL6C
	DAD	H
	DAD	B
	PUSH	H
	LHLD	XTNL4D
	XCHG
	POP	H
	MOV	M,E
	INX	H
	MOV	M,D
;
A0618:	LHLD	XTNL49
	SHLD	XTNL4D
	JMP	A065E
;.....
;
;
A0621:	LXI	B,XTNL49
	LXI	D,XTNL4B
	CALL	CMP16B		; 16B compare sets carry if (BC) < (DE)
	JNC	A0658
	LDA	XTNL53
	INR	A
	STA	XTNL53
	MOV	C,A
	MVI	B,0
	LXI	H,XTNL54
	DAD	B
	DAD	B
	PUSH	H
	LHLD	XTNL4B
	XCHG
	POP	H
	MOV	M,E
	INX	H
	MOV	M,D
	LHLD	XTNL53
	MVI	H,0
	LXI	B,XTNL6C
	DAD	H
	DAD	B
	PUSH	H
	LHLD	XTNL49
	XCHG
	POP	H
	MOV	M,E
	INX	H
	MOV	M,D
;
A0658:	LHLD	XTNL47
	SHLD	XTNL4B
;
A065E:	JMP	A04ED
;.....
;
;
A0665:	LXI	H,0		; Zap <HL>
	SHLD	XTNL84
	SHLD	XTNL86
;
A066E:	LXI	B,XTNL10
	LXI	D,XTNL86
	CALL	CMP16B		; 16B compare sets carry if (BC) < (DE)
	JNC	A0723
	LHLD	XTNL86
	INX	H
	SHLD	XTNL86
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	PUSH	H
	LHLD	XTNL84
	INX	H
	SHLD	XTNL84
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	XTHL
	MOV	C,M
	INX	H
	MOV	B,M
	POP	H
	MOV	M,C
	INX	H
	MOV	M,B
;
A069D:	LXI	B,XTNL10
	LXI	D,XTNL86
	CALL	CMP16B		; 16B compare sets carry if (DE) < (BC)
	SBB	A
	PUSH	PSW
	LHLD	XTNL84
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	PUSH	H
	LHLD	XTNL86
	LXI	B,2
	DAD	H
	DAD	B
	XCHG
	LHLD	STAKAD
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M
	POP	H
	MOV	C,M
	INX	H
	MOV	B,M
	CALL	CMPR12
	SUI	0
	SUI	1
	SBB	A
	POP	B
	MOV	C,B
	ANA	C
	RAR
	JNC	A066E
	LHLD	XTNL86
	INX	H
	SHLD	XTNL86
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
	SHLD	LSTLOC
	LXI	B,13
	LHLD	LSTLOC
	DAD	B
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
	SHLD	XTNL88
	LHLD	XTNL84
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
	SHLD	LSTLOC
	LHLD	LSTLOC
	DAD	B
	LXI	D,XTNL88
	CALL	A0AAA
	LXI	B,13
	PUSH	H
	LHLD	LSTLOC
	DAD	B
	POP	B
	MOV	M,C
	INX	H
	MOV	M,B
	JMP	A069D		; Loop until done
;.....
;
;
A0723:	LHLD	XTNL84
	SHLD	XTNL0E
	RET
;.....
;
;
A072A:	LXI	H,XTNL8B
	MOV	M,B
	DCX	H
	MOV	M,C
	LHLD	XTNL8A
	DAD	H
	XCHG
	LHLD	STAKAD
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
	SHLD	LSTLOC
	LXI	H,XTNL8C
	MVI	M,0
;
A0745:	MVI	A,10
	LXI	H,XTNL8C
	CMP	M
	JC	A0769		; Send filesize when done here
	LHLD	XTNL8C
	MVI	H,0
	XCHG
	LHLD	LSTLOC
	DAD	D
	MOV	C,M		; Character in <C> for output
	CALL	CHROUT		; Send a character & hilite if necessary
	LDA	XTNL8C
	INR	A
	STA	XTNL8C
	CPI	8
	JNZ	A0745		; Loop until done
;;;
;;;  MVI C,' '			; *** (PUT A SPACE IF PREFERRED)
	MVI	C,'.'		; *** (PERIOD BETWEEN FILENAMD AND EXT.)
;;;
	CALL	CHROUT
	JMP	A0745
;.....
;
;
; See if using 'compressed', if not, compute and show file size.
;
A0769:	LDA	CFLAG		; Get compressed size flag in <A>
	CMA			; Complement the bits in <A>
	RAR			; Rotate <A> thru carry
	RNC			; Skip if flag was false
;
	LXI	B,13		; 13 bytes used if "C" option
	LHLD	LSTLOC		; Get the last address used in <HL>
	DAD	B		; Add 13 to it
	MOV	E,M
	INX	H
	MOV	D,M
	LHLD	XTNL25		; Get filesize
	CALL	A0AD4
	MOV	B,H
	MOV	C,L
	MVI	E,4		; *** filesize, plus leading spaces
	CALL	A0B66		; Compute and display the filesize
	MVI	C,'k'		; Tag the filesize with "k"
	CALL	F2OUT		; Send it to the console device
	LDA	EFLAG		; Want extended display?
	RAR			; Carry set if flag is YES
	RNC			; Skip the listing if flag was false
	LXI	B,11		; 11th byte is dir/sys status byte
	LHLD	LSTLOC		; Get filename pointer in <HL>
	DAD	B		; Add offset to get dir/sys status
	MOV	C,M		; Get status byte in <C>
	MVI	B,0		; Zap <B>
	MVI	E,3
	CALL	A0B66		; Compute and display dir/sys status
	CALL	SPACE1		; Insert a space in display
	LXI	B,3		; User archive bit (4th char. in name)
	LHLD	LSTLOC		; Address at start of filename
	DAD	B		; Index into the name for archive bit
	MOV	A,M		; Get the character there
	CPI	80H		; See if high bit is set
	JC	NOTAA		; If not, this file not archived
;
SENDA:	MVI	C,'A'		; Else show it is archived
	CALL	F2OUT
	JMP	NOTDR		; Skip the DRI archive check
;
NOTAA:	LXI	B,10		; Special DRI archive byte, end of extent
	LHLD	LSTLOC		; Start of filename
	DAD	B		; Index into filename to end of extent
	MOV	A,M		; Get the character at end of extent
	CPI	80H		; See if the high bit is set
	JNC	SENDA		; If yes, display it
	CALL	SPACE1		; Else put a blank for archive display
;
NOTDR:	LXI	B,8		; Count in <C> = 8
	LHLD	LSTLOC		; Get base address of filename
	DAD	B		; Add offset to filetype
	PUSH	H
	MOV	A,M		; Get first byte of extent in <A>
	CPI	80H		; Check for R/O status
	JC	NOTRR		; Skip - not R/O file
	MVI	C,'R'		; R/O indicator
	CALL	F2OUT		; Send indicator
	JMP	A07BE		; Do next
;
NOTRR:	CALL	SPACE1
;
A07BE:	POP	H		; Get address of R/O byte in extent back
	INX	H		; Next byte is the system flag byte
	MOV	A,M		; Get the byte in <A>
	CPI	080H		; Check for system file
	MVI	C,'S'		; System file, put "S" on screen too
	JNC	F2OUT
	JMP	SPACE1		; Send space if not system file, done
;.....
;
;
SIGNON:	LDA	VFLAG		; Want to show the version number?
	ORA	A
	LXI	B,VERMSG
	CNZ	SNDCON
	LDA	PFLAG		; Get the printer flag byte
	INR	A		; Set appropriate cpu flags
	JZ	SKPSIN		; Skip the cursor controls if printer on
;
	 IF	VIDEO
	LXI	B,TRMINI	; Point to user terminal initialization string
	CALL	SNDCON
	LXI	B,CRSRUP	; Move cursor up one line
	CALL	SNDCON
	LXI	B,CLREOL	; Clear the line
	CALL	SNDCON
	LXI	B,CRSRUP	; Move cursor up one line
	CALL	SNDCON
	LXI	B,CLREOL	; Clear the line
	CALL	SNDCON
	 ENDIF			; VIDEO
;
SKPSIN:	DCX	B		; Back up the pointer to the <lf>
	DCX	B		; Then to the <cr> at end of message
	STAX	B		; And stop the crlf output there
	LXI	H,ROWCNT	; Point to present row number count byte
	MVI	M,1		; Make this the first row
;
HEADER:	LDA	NUMROW		; Number of rows per line
	LXI	H,ROWCNT	; Row number count
	CMP	M		; Carry set if NUMROW < current number
	JC	A0827		;
	LDA	CFLAG		; Get compressed size flag
	CMA			; Invert it
	RAR			; Rotate through carry
	JNC	ADD3SP		; Skip if flag was set YES to suppress
;
ADD3SP:	LXI	H,NUMROW	; Number of rows per line
	LDA	ROWCNT		; Row count totalizer byte
	CMP	M		; Carry set if this is not the last row
	JNC	BMPCNC		; Skip sending 3 spaces if last row
	LXI	B,SPCS3M	; Send 3 spaces
	CALL	SNDMSG		; This call does it
;
BMPCNC:	LDA	ROWCNT		; Get current row number count
	INR	A		; Bump it
	STA	ROWCNT		; Store the incremented count
	JNZ	HEADER		; Loop until done
;
A0827:	LHLD	XTNL0E
	SHLD	XTNL95
	LXI	H,1
	SHLD	XTNL91
;
A0833:	XRA	A		; Zap <A>
	LXI	H,XTNL95
	CALL	A0B2E
	RNC			; Done here if no carry
	LHLD	XTNL95
	XCHG
	LHLD	NUMROW		; Number of rows per line
	MVI	H,0		; Make sure not more that 255 rows
	CALL	A0AB5
	XCHG
	SHLD	LINECT		; Store the line count
	LHLD	XTNL95
	XCHG
	LHLD	NUMROW		; Number of rows per line
	MVI	H,0		; Make sure not more than 255
	CALL	A0AB5
	XRA	A		; Zap <A>
	CALL	A0B02
	ORA	L		; Are we done?
	JZ	A086A
	LHLD	LINECT		; Get line count in <HL>
	INX	H		; Bump the count
	SHLD	LINECT		; And put it back
;
A086A:	LHLD	HEIGHT		; Get number of lines per screen
	MOV	B,H		; Put high order byte in <B>
	MOV	C,L		; Put low order byte in <C>
	LHLD	LINECT		; Get current line count in <HL>
	XCHG			; Then put line count in <DE>
	CALL	A0256
	SHLD	LINECT		; Store the line count
	LXI	H,0
	SHLD	XTNL8D		; Make zero for fresh start

A087F:	LXI	B,LINECT	; Point to current screen line number
	LXI	D,XTNL8D
	CALL	CMP16B		; 16B compare returns carry if (BC)=(DE)
	JNC	A08FA
	CALL	CRLF		; Send CRLF at end of line
	LXI	H,0		; Zap <HL>
	SHLD	XTNL8F
	MOV	A,L
	STA	ROWCNT		; Restore present row count to 0
;
A0898:	LDA	ROWCNT		; Get present row count in <A>
	INR	A		; Bump it up one
	STA	ROWCNT		; Store the incremented number
	MOV	C,A		; Now put it in <C> for comparison
	LDA	NUMROW		; Number of rows per line
	CMP	C		; Compare, carry set if not done
	JC	A08F0		; Bump the pointers and loop until done
	LHLD	XTNL8F
	XCHG
	LHLD	XTNL8D
	DAD	D
	PUSH	H
	LHLD	XTNL91
	POP	B
	DAD	B
	SHLD	XTNL93
	LXI	D,XTNL0E
	LXI	B,XTNL93
	CALL	CMP16B		; 16B compare sets carry if (BC) < (DE)
	JC	A08E2
	MVI	A,1
	LXI	H,ROWCNT	; Point to present row count
	CMP	M		; Set carry if more rows to follow
	JNC	A08D3
	LXI	B,CDELIM	; Row delimiter = ":" in <C>
	CALL	SNDMSG		; Show it to user on console
;
A08D3:	LHLD	XTNL93
	MOV	B,H
	MOV	C,L
	CALL	A072A
	LHLD	XTNL95
	DCX	H
	SHLD	XTNL95
;
A08E2:	LHLD	LINECT		; Line count in <HL>
	XCHG			; Put it in <DE>
	LHLD	XTNL8F
	DAD	D
	SHLD	XTNL8F
	JMP	A0898
;
A08F0:	LHLD	XTNL8D
	INX	H
	SHLD	XTNL8D
	JMP	A087F
;
A08FA:	LHLD	NUMROW		; Number of rows per line into <HL>
	MVI	H,0		; Make sure not more that 255
	XCHG			; Row count in <E>
	LHLD	LINECT		; Get line count in <HL>
	CALL	A0AD4
	XCHG
	LHLD	XTNL91
	DAD	D
	SHLD	XTNL91
	CALL	PAGECK		; Check for full screen or page
	JMP	A0833
;
SUMMRY:	LHLD	DPBDSM		; Get maximum disk storage capacity in <HL>
	INX	H		; Add one for the zero offset
	SHLD	XTNL9E		; Save as maximum capacity
	SHLD	XTNLA0
	SHLD	XTNLA2
	LHLD	DPBAL0		; Get alloc vect 0 in <L> alloc vector 1 in <h>
	SHLD	XTNL9C		; Store the space used data
;
A0928:	XRA	A		; Zap <A>
	LXI	D,XTNL9C	; Point to the drive space used data
	CALL	A0B23
	ORA	L
	JZ	A0952		; Calculate space remaining, display
	LDA	XTNL9C
	RAR
	JNC	A0942
	LHLD	XTNL9E
	DCX	H
	SHLD	XTNL9E
;
A0942:	MVI	C,1
	LXI	H,XTNL9C
	CALL	A0AF2
	XCHG
	DCX	H
	MOV	M,E
	INX	H
	MOV	M,D
	JMP	A0928
;.....
;
;
; Calculates disk space remaining, check first if CP/M 3.0
;
A0952:	MVI	C,CPMVER	; Check version #
	CALL	BDOS
	MOV	A,L
	CPI	30H		; Version 3.0?
	JC	A0955		; Use normal method if not CP/M+
;
	POP	H		; Remove "call CKCPM3" from stack
	MVI	C,CURDSK
	CALL	BDOS
	MOV	E,A
	MVI	C,46		; CP/M+ compute free space call
	CALL	BDOS
	MVI	C,3		; Answer is 3 bytes long (24 bits)
;
A0953:	LXI	H,TBUF+2	; Answer is located here
	MVI	B,3		; Convert to 'k' length
	ORA	A
;
A0954:	MOV	A,M
	RAR
	MOV	M,A
	DCX	H
	DCR	B
	JNZ	A0954		; Loop for 3 bytes
	DCR	C
	JNZ	A0953		; Shift 3 times
	LHLD	TBUF		; Get result in 'k'
	JMP	A0961		; Display result
;.....
;
;
A0955:	MVI	C,PARMS		; Current disk parameter block
	CALL	BDOS
	INX	H
	INX	H
	MOV	A,M		; Get block shift factor
	STA	A0964
	INX	H		; Bump to block mask
	MOV	A,M		; Get it
	STA	A0963
	INX	H
	INX	H
	MOV	E,M		; Get maximum block number
	INX	H
	MOV	D,M
	XCHG
	SHLD	A0962		; Put it away
	MVI	C,GETADR	; Address of CP/M allocation vector
	CALL	BDOS
	XCHG			; Get its length
	LHLD	A0962
	INX	H
	LXI	B,0		; Initialize block count to zero
;
A0956:	PUSH	D		; Save allocation address
	LDAX	D
	MVI	E,8		; Set to process 8 blocks
;
A0957:	RAL			; Test bit
	JC	A0958
	INX	B
;
A0958:	MOV	D,A		; Save bits
	DCX	H
	MOV	A,L
	ORA	H
	JZ	A0959		; Quit if out of blocks
	MOV	A,D		; Restore bits
	DCR	E		; Count down 8 bits
	JNZ	A0957		; Do another bit
	POP	D		; Next count of allocation vector
	INX	D
	JMP	A0956		; Process it
;
A0959:	POP	D		; Clear alloc vector pointer from stack
	MOV	L,C		; Copy block to HL
	MOV	H,B
	LDA	A0964		; Get block shift factor
	SUI	3		; Convert from records to thousands (k)
	JZ	A0961		; Skip shifts if 1k blocks
;
A0960:	DAD	H		; Multiply blocks by 'k' per block
	DCR	A
	JNZ	A0960
;

A0961:	SHLD	XTNLA0
	JMP	A09B6
;.....
;
;
; Uninitialized storage
;
A0962:	DB	0,0		; Highest block number on drive
A0963:	DB	0		; Rec/blk - 1
A0964:	DB	0		; # of shifts to multiply by rec/blk
;.....
;
;
A09B6:	CALL	CRLF
	CALL	CRLF
	LHLD	LINECT		; Get the line count for the printer
	INX	H
	SHLD	LINECT		; Increment it for this new line
	CALL	QUIT		; Want to quit now?
	LXI	D,0
	MVI	C,CURDSK	; Get current disk function call
	CALL	BDOS		; Get it with BDOS call
	ADI	'A'		; Make it ASCII
	MOV	C,A		; F2OUT expects character in <C>
	CALL	F2OUT		; Send the drive code
	MVI	C,':'		; ASCII colon in <C>
	CALL	F2OUT		; Send colon following drive code
	MVI	C,' '		; Space after the colon
	CALL	F2OUT
;
	LHLD	XTNL9E
	XCHG
	LHLD	XTNL25
	CALL	A0AD4		; Compute total capacity of drive
	MOV	B,H
	MOV	C,L
	MVI	E,1
	CALL	A0B66
	LXI	B,TCAPM		; Total capacity in k
	CALL	SNDMSG
	LXI	B,USEDM
	CALL	SNDMSG
;
	LHLD	XTNL0E
	MOV	B,H
	MOV	C,L
	MVI	E,1
	CALL	A0B66		; Compute number of files on disk
	LXI	B,FILESM	; Total files
	CALL	SNDMSG
;
	LHLD	XTNL0C
	XCHG
	LHLD	XTNL25
	CALL	A0AD4		; Compute amount of space used
	MOV	B,H
	MOV	C,L
	MVI	E,001H
	CALL	A0B66
	LXI	B,KOFMSG
	CALL	SNDMSG
;
	LHLD	XTNL23		; Get number of entries remaining <HL>
	MOV	B,H		; Move <HL> to <BC>
	MOV	C,L		; Complete the above move
	MVI	E,1
	CALL	A0B66		; Send the number remaining
	MVI	C,'/'
	CALL	F2OUT
;
	LHLD	XTNLA0		; Get space remaining in HL
	MOV	B,H		; Put into BC
	MOV	C,L
	MVI	E,001H		; Offset
	CALL	A0B66		; Send remaining space figures
	MVI	C,'k'
	CALL	F2OUT
	CALL	CRLF
;
	CALL	PAGECK		; Check for full screen (or page)
;
	 IF	VIDEO
	LXI	B,TRMUNI	; Point to user terminal restoration string
	CALL	SNDCON		; Send exit de-initialization if installed
	 ENDIF			; VIDEO
;
	RET
;.....
;
;
; Compare 12 characters (user area, filename, ext.)
;
CMPR12:	MVI	L,12		; Load character count
;
CMPRLP:	LDAX	D		; Get byte in <A>
	ANI	07FH		; Strip the parity if set
	MOV	H,A		; Save stripped byte in <H>
	LDAX	B		; Get a byte in <A>
	ANI	07FH		; Strip this one too
	SUB	H		; 0 if equal
	JNZ	DIFF12		; Jump if they are not equal
	INX	D		; Equal, bump the pointers
	INX	B		; Bump both pointers
	DCR	L		; Reduce the count
	JNZ	CMPRLP		; Loop until done
	RET
;...
;
;
DIFF12:	MVI	A,0FFH		; Set flag for return if (DE) > (BC)
	RC			; <DE> is larger
	MVI	A,1		; Else flag shows <DE> is smaller than <BC>
	RET			; And done here
;.....
;
;
; Check for match in INTFCB parms with user number
;
A0A59:	LXI	H,INTFCB	; Get address of first byte of search parms
	MVI	E,12		; 12 bytes to check
;
A0A5E:	MOV	A,M		; Get drive/user code in <A>
	CPI	'?'		; Wildcard?
	JZ	A0A6C		; Yes, search all user areas
	MOV	D,A		; Get user area in <D>
	LDAX	B		; Get user area from immediate filename
	ANI	07FH		; Strip the high bit if set
	CMP	D		; Are they equal?
	MVI	A,0		; Zap <A>, cannot use  XRA A  here
	RNZ			; Not same, no match, check no further
;
;
; Arrive here if we have match or all user areas to be shown
;
A0A6C:	INX	B		; Bump the filename pointer
	INX	H		; Bump the memory pointer too
	DCR	E		; One less byte to go
	JNZ	A0A5E		; Loop until done
	LDA	SFLAG		; Get system flag in <A>
	ORA	A		; Set the appropriate cpu flags
	RNZ			; Return if system flag is true
	DCX	B		; Back up the pointer
	DCX	B		; Pointer set to 2nd extent byte
	LDAX	B		; Get it in the <A>
	CMA			; Set carry if system file
	RLC			; Rotate carry into bit 0 position
	ANI	1		; Isolate bit 0
	RET			; Return 0 if dir file or 1 if system
;.....
;
;
A0A7F:	LXI	H,0		; Zap <HL
	LDA	XTNL27		; Get (???)
	ORA	A		; Align flags properly
	JNZ	A0A97
	MVI	E,16		; Byte count in <E>
;
A0A8B:	LDAX	B
	ORA	A
	JZ	A0A91
	INX	H
;
A0A91:	INX	B
	DCR	E
	JNZ	A0A8B
	RET
;.....
;
;
A0A97:	MVI	E,008H
;
A0A99:	LDAX	B
	MOV	D,A
	INX	B
	LDAX	B
	ORA	D
	JZ	A0AA2
	INX	H
;
A0AA2:	INX	B
	DCR	E
	JNZ	A0A99
	RET
;.....
;
;
A0AAA:	MOV	C,M
	INX	H
	MOV	B,M
	LDAX	D
	ADD	C
	MOV	L,A
	INX	D
	LDAX	D
	ADC	B
	MOV	H,A
	RET
;.....
;
;
A0AB5:	MOV	B,H
	MOV	C,L
	LXI	H,0
	MVI	A,16
;
A0ABC:	PUSH	PSW
	DAD	H
	XCHG
	SUB	A
	DAD	H
	XCHG
	ADC	L
	SUB	C
	MOV	L,A
	MOV	A,H
	SBB	B
	MOV	H,A
	INX	D
	JNC	A0ACE
	DAD	B
	DCX	D
;
A0ACE:	POP	PSW
	DCR	A
	JNZ	A0ABC
	RET
;.....
;
;
A0AD4:	MOV	B,H
	MOV	C,L
	LXI	H,0
	MVI	A,16
;
A0ADB:	DAD	H
	XCHG
	DAD	H
	XCHG
	JNC	A0AE3
	DAD	B
;
A0AE3:	DCR	A
	JNZ	A0ADB
	RET
;.....
;
;
; Raise the count in <HL> to the power of number in <C>
;
H2CPWR:	DAD	H		; Double <HL>
	DCR	C		; Reduce the count
	JNZ	H2CPWR		; Loop until done
	RET
;.....
;
;
A0AF2:	MOV	E,M
	INX	H
	MOV	D,M
	XCHG
;
A0AF6:	MOV	A,H
	ORA	A
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	DCR	C
	JNZ	A0AF6
	RET
;.....
;
;
A0B02:	MOV	E,A
	MVI	D,0
;
A0B05:	MOV	A,E
	SUB	L
	MOV	L,A
	MOV	A,D
	SBB	H
	MOV	H,A
	RET
;.....
;
;
A0B0C:	MOV	C,A
	MVI	B,0
	MOV	A,E
	SUB	C
	MOV	L,A
	MOV	A,D
	SBB	B
	MOV	H,A
	RET
;.....
;
;
; 16 bit comparison routine.  At entry <BC> points to memory address
; of the high limit and <DE> points to memory address of the present
; count to be checked.	Returns with two's complement of the actual
; difference in <HL>, carry flag is set if memory at <BC> is greater
; than that at <DE>, zero flag if difference is zero, <A> contains
; low order two's complement (<A> = <L>.
;
CMP16B:	MOV	L,C		; Move low order of count address to <L>
	MOV	H,B		; Move high order of count address to <H>
	MOV	C,M		; Move the low order count limit into <C>
	INX	H		; Point to high order of count limit
	MOV	B,M		; <BC> contains 16 bit count limit
	LDAX	D		; Get the low order present count in <acc>
	SUB	C		; Subtract high limit from present count
	MOV	L,A		; Move the remainder to <L>
	INX	D		; Point to high order of 16 bit present count
	LDAX	D		; Move high order bits of present ct to <A>
	SBB	B		; Subtract high limit from present
	MOV	H,A		; <HL> contains difference, <A> = <L>
	RET
;.....
;
;
A0B23:	MOV	L,A
	MVI	H,0
	LDAX	D		; Get ? from memory at <DE>
	SUB	L
	MOV	L,A
	INX	D
	LDAX	D		; Get next ? from memory
	SBB	H
	MOV	H,A
	RET
;.....
;
;
A0B2E:	MOV	E,A
	MVI	D,0
	MOV	A,E
	SUB	M
	MOV	E,A
	MOV	A,D
	INX	H
	SBB	M
	MOV	D,A
	XCHG
	RET
;.....
;
;
HILITE:	PUSH	B		; Save pointer
;
	 IF	VIDEO
	LXI	B,FGNDON	; Point to foreground on string
	CALL	SNDCON		; Send the string
	 ENDIF			; VIDEO
;
	POP	B		; Recover pointer
	LDAX	B		; Get the character
	INX	B		; Bump the pointer
	PUSH	B		; And save again
	ANI	07FH		; Clear the high bit
	MOV	C,A		; In <C> for output
	CALL	F2OUT		; Send character
;
	 IF	VIDEO
	LXI	B,FGNDOF	; Point to foreground off string
	CALL	SNDCON		; Send the turn off code
	 ENDIF			; VIDEO
;
	POP	B		; Recover the pointer
;
SNDMSG:	LDAX	B		; Get byte of message in <A>
	CPI	80H		; High bit set?
	JNC	HILITE		; Show it highlited if so
	ORA	A		; Are we done yet?
	RZ			; Return if so
;
	PUSH	B		; Else save <BC>
	MOV	C,A		; Put the character in <C> for F2OUT
	CALL	F2OUT		; Send a character
	POP	B		; Get address back
	INX	B		; Bump the pointer
	JMP	SNDMSG		; Loop until done
;.....
;
;
; Send "FGNDON" to console, send one character after stripping the
; high bit, then send "FGNDOF" to return to normal attributes
;
CHROUT:	MOV	A,C		; Get character in <A> for testing
	CPI	080H		; Is bit 7 high?
	JC	F2OUT		; No, use F2OUT routine
	ANI	7FH		; Now strip the high bit
	MOV	C,A		; And put in <C>
;
	 IF	VIDEO
	PUSH	B		; Alt. entry point for printer code output
	LXI	B,FGNDON	; Point to foreground "ON" escape sequence
	CALL	SNDCON		; Sent the escape sequence to the console
	POP	B		; Recover character in <c>
	 ENDIF			; VIDEO
;
	CALL	F2OUT		; Send the character
;
	 IF	VIDEO
	LXI	B,FGNDOF
	CALL	SNDCON
	 ENDIF			; VIDEO
;
	RET
;.....
;
;
; Send a string to the console only. Does not go to disk file or list
; device (printer)
;
SNDCON:	LDAX	B		; Get character in <A>
	ORA	A		; Are we done?
	RZ			; Return if done
	PUSH	B		; Save pointer
	MOV	E,A		; Character to <E> for console output
	MVI	C,2		; Console output function
;
SNDC1:	CALL	$-$		; Address provided at initialization
	POP	B		; Recover pointer
	INX	B		; Increment to next character
	JMP	SNDCON		; And loop until done
;.....
;
;
; CP/M function 2 (console output)
;
F2OUT:	MOV	E,C		; Move character from <C> to <E>
	PUSH	D		; Store the <E> value
	MVI	C,WRCON		; Console output function
	CALL	BDOS
	POP	D		; Get character in <E> back again
	LDA	PFLAG		; Printing also?
	ORA	A
	JZ	QUIT
	MVI	C,5		; If yes, send character to printer
	CALL	BDOS
	JMP	QUIT		; Want to quit now?
;.....
;
;
; See if operator has typed CTL-C to quit if yes, delete partial file
;
QUIT:	PUSH	H
	PUSH	D
	PUSH	B
	MVI	C,CONST		; Get keyboard status
	CALL	BDOS
	RAR			; Anything typed?
	JNC	QUIT2		; If not, back to work
	MVI	C,RDCON		; Otherwise get the character
	CALL	BDOS
	CPI	'C'-40H		; "CTL-C" to quit
	JZ	QUIT1
	CPI	'X'-40H		; "CTL-X" to quit
	JZ	QUIT1
	ANI	5FH		; Change to upper-case if needed
	CPI	'K'
	JZ	QUIT1
	CPI	'X'
	JNZ	QUIT2		; If neither, back to work
;
QUIT1:	POP	B		; Restore the stack
	POP	D
	POP	H
	POP	H		; Remove 'call quit' from stack
	JMP	EXIT
;
QUIT2:	POP	B		; Restore the stack
	POP	D
	POP	H
	RET
;.....
;
;
; Arrive here with source location in <BC>, destination in <DE>, and
; byte count on the stack just above the return address
;
MOVMEM:	POP	H		; Get the return address in <HL>
	XTHL			; Put it back on the stack
;
MOVMOR:	LDAX	B		; Get byte here
	STAX	D		; Put it there
	INX	B		; Bump pointers
	INX	D		; Both pointers
	DCR	L		; Reduce the count remaining
	JNZ	MOVMOR		; Loop until done
	RET
;.....
;
;
; Arrive here with fill byte in <E>, count as low order byte on stack
; just above return address, and beginning address to fill in <BC>
;
FILL:	POP	H		; Return address from last call in <HL>
	XTHL			; Put return address back on stack and
				;   get number of bytes to fill in <L>
	MOV	A,E		; Fill byte now in <A>
;
FLOOP:	STAX	B		; Store it at address indicated in <BC>
	INX	B		; Bump memory pointer
	DCR	L		; Reduce count remaining
	JNZ	FLOOP		; Loop until done
	RET
;.....
;
;
A0B66:	LXI	H,XTNLA8
	MOV	M,E
	DCX	H
	MOV	M,B
	DCX	H
	MOV	M,C
	LHLD	XTNLA6
	PUSH	H
	MVI	E,6
	LXI	B,XTNLAB
	CALL	A0BBC
	STA	XTNLAA
	INR	A
	STA	XTNLA9
;
A0B81:	LDA	XTNLA8
	LXI	H,XTNLA9
	CMP	M
	JC	A0B97
	MVI	C,' '		; ASCII space character
	CALL	F2OUT		; Send the space to the console
	LXI	H,XTNLA9
	INR	M
	JMP	A0B81
;
A0B97:	LXI	H,XTNLA9
	MVI	M,0
;
A0B9C:	LDA	XTNLAA
	DCR	A
	LXI	H,XTNLA9
	CMP	M
	RC			; Done here if carry flag set
	LHLD	XTNLA9
	MVI	H,0
	LXI	B,XTNLAB
	DAD	B
	MOV	C,M
	CALL	CHROUT
	LXI	H,XTNLA9
	INR	M
	JNZ	A0B9C		; Loop until done
	RET			; Else done here
;.....
;
;
A0BBC:	POP	H		; Get return address from the stack
	XTHL			; Restore return addr, get passed value in <HL>
	MVI	D,1
	XRA	A
	PUSH	PSW
	INX	SP
;
A0BC4:	DCR	E
	JZ	A0BD5
	INR	D
	CALL	A0BE1
	ADI	'0'
	PUSH	PSW
	INX	SP
	MOV	A,L
	ORA	H
	JNZ	A0BC4		; Loop until done
;
A0BD5:	MOV	E,D
	DCR	E
;
A0BD7:	DCX	SP
	POP	PSW
	STAX	B
	INX	B
	DCR	D
	JNZ	A0BD7
	MOV	A,E
	RET
;
A0BE1:	PUSH	B
	LXI	B,0100AH
	XRA	A
;
A0BE6:	DAD	H
	RAL
	CMP	C
	JC	A0BEE
	SUB	C
	INX	H
;
A0BEE:	DCR	B
	JNZ	A0BE6
	POP	B
	RET
;.....
;
;
; This module to "STEAL" the directory output from the BDOS by changing
; the BDOS jump address at 0006H to jump to this module, leave a byte
; intended for the console in memory, and then continue its journey with
; the console output byte unaltered.
;
SNITCH:	PUSH	H		; Save the pointer
	LXI	H,GETIT		; Point to beginning of getit routine
	SHLD	BDOS+1		; Set the BDOS pointer to "GETIT" module
	LXI	H,SBUFFR	; Set pointer to save buffer
	MVI	M,CR		; Insert a carriage return at beginning
	INX	H		; Bump pointer
	MVI	M,'Z'-40H	; End of file marker
	SHLD	NXTLOC		; Store the updated pointer
	POP	H		; Restore the pointer
	RET
;.....
;
;
NXTLOC:	DB	0,60H		; Page for buffer location
HLSTG1:	DB	0,0		; Storage for <HL> when it arrives with BDOS call
HLSTG2:	DB	0,0		; Stacktop stored here so we can push the psw to stack
;
;
; We arrive here with output character in <E>.	"GETIT" will get the
; character and store it for the save.	We store <HL> in local memory,
; pop <HL> to get the top of the stack in <HL>, store that and then push
; the PSW in case the flags need to be saved.  We reverse the procedure
; on the way out thus preserving things the way they were.  This method
; takes time and space but leaves the stack undisturbed for the direct-
; ory program.
;
GETIT:	SHLD	HLSTG1		; Save register <HL>
	POP	H		; Get stack top in <HL>
	SHLD	HLSTG2		; Save stack top here
	PUSH	PSW		; Save accumulator and flags on stack
	MOV	A,C		; Get the function call in <A>
;
CKFNC:	CPI	2		; Console output call?
	JNZ	NOPE		; Not correct function so do not save <E>
	LHLD	NXTLOC		; Get next buffer location
	MOV	M,E		; Save the byte
	INX	H		; Bump pointer
	SHLD	NXTLOC		; Save the incremented pointer for next pass
NOPE:	POP	PSW		; Restore the accumulator
	LHLD	HLSTG2		; Get the old stack top in <HL>
	PUSH	H		; And put it back on the stack
	LHLD	HLSTG1		; Restore <HL>
;
HERE:	JMP	BDOS		; Now jump to the BDOS via the old vector
				; This jump has the vector from 006H inserted
				; Under program control
;.....
;
;
; Put things in order, then do the exit routine
;
EXITJ:	LHLD	HERE+1		; Get true BDOS vector back in <HL>
	SHLD	BDOS+1		; And make it like it was
	LHLD	NXTLOC		; Get last written address in <HL>
	MVI	M,01AH		; End of file indicator
	LDA	FFLAG		; Saving to disk?
	ORA	A
	JNZ	SAVDIR		; If so, save the directory output
;
EXITJ1:	JMP	BK2CCP		; This jump instruction gets changed by "PTRON"
				;   if printer is selected
;.....
;
;
; Insert printer restoration code in DUNMSG as needed
;
BK2CCP:	LHLD	HERE+1		; Get proper BDOS address in <HL>
	SHLD	BDOS+1		; Make it so
	LHLD	STACK		; Get the original stack return again
	SPHL			; Set stack pointer to old stack
	RET			; And back to CCP without a warm reboot
;.....
;
;
DONEPR:	 IF	PNTRSP
	LXI	B,PTROFM	; Point to end message
	CALL	LSTOUT		; Send the message
	 ENDIF			; PNTRSP
;
	JMP	BK2CCP		; Return to CCP without a warm reboot
;
LSTOUT:	LDAX	B		; Get character
	ORA	A		; Test it
	RZ			; Done if zero
	PUSH	B
	MOV	E,A		; Character in <E> for output
	MVI	C,WRLST		; List device call
;
LSTOT1:	CALL	BDOS		; Send the character to list device
	POP	B		; Recover pointer
	INX	B		; Point to next character
	JMP	LSTOUT		; Loop until string sent
;.....
;
;
;=======================================================================
;
; Save routine used in new directory program to save the output to a
; a file called  (name inserted at "NUNAME") when "F" is toggled.
;
; Fill the last record with ^Z (1AH), and send all the data to a disk
; file named in the file control block
;
SAVDIR:	LHLD	NXTLOC		; Get last storage address in <HL>
;
NOTYET:	MVI	M,'Z'-40H	; Fill with CTL-Z EOF markers
	INX	H		; Bump memory pointer
	MOV	A,L		; Get low order byte in <A>
	ORA	A		; Are we done yet?
	JNZ	NOTYET		; No, do it again
;
	INX	H		; H = # of 256 byte blocks (including offset)
	LXI	D,SBUFFR	; Get buffer address (MSB) in <D>
	MOV	A,H		; Get last block (MSB) address in <A>
	SUB	D		; <A> = # of 256 byte blocks
	ADD	A		; <A> = # of 128 byte blocks
	STA	SAVENN		; # of 128 byte blocks to save to disk file
	LXI	H,NUNAME	; Point to our internal file control block
	LXI	D,DFCB		; The CP/M default file control block
	MVI	B,32		; Thirty-two bytes to move
;
SETNOT:	MOV	A,M
	STAX	D
	INX	H
	INX	D
	DCR	B
	JNZ	SETNOT
;
	MVI	C,CURDSK	; Get current disk number
	CALL	BDOS		; Number returns in 'A'
	PUSH	PSW		; Save for set drive function
;
;
; Note =====>>> If save on current drive is desired, change the next
;		byte to 0AFH, exclusive OR <A> with <A>.
;
CURRENT:NOP			;*This is the one to change, saves disk
				;   file to drive directory is from
	INR	A		; Bump it up one for fcb to select drive
				; Since FCB wants 1=A, 2=B, etc.
	STA	DFCB		; Store it there for later
	STA	NUNAME		; Store it there too
	POP	PSW		; Get current disk number back
	MOV	E,A		; Put current disk in e for disk select
	MVI	C,SELDSK	; Disk selection code
	CALL	BDOS		; Select current disk as active disk
	MVI	C,DELETE	; Delete file function call
	LXI	D,DFCB		; We will erase NUNAME.EXT if present now
	CALL	BDOS		; Erase old file if present in directory
	MVI	C,MAKEF		; Make file function
	LXI	D,DFCB		; Point to the name again
	CALL	BDOS		; Return with error code in <A>
	CPI	0FFH		; Error?
	JZ	ERROR		; Send error message
	LXI	D,SBUFFR	; Beginning of data left by directory program
;
SETDMA:	PUSH	D		; Save the pointer
	MVI	C,STDMA		; Set DMA address function
	CALL	BDOS		; Set DMA
	MVI	C,WRSEQ		; Write sequential function
	LXI	D,NUNAME	; Point to filename in FCB
	CALL	BDOS		; Write a 128 byte block
	ORA	A		; Check for successful write
	JNZ	ERROR		; Zero returned if all ok
	LDA	SAVENN		; Get number of remaining blocks
	DCR	A		; Reduce it and check for zero remaining
	JZ	CLOSE		; Close the file if zero
	STA	SAVENN		; Save it for the next pass
	POP	H		; Get old DMA pointer back, this time in <HL>
	LXI	D,080H		; Raise it 128 bytes here....
	DAD	D		; By adding to old value now in <HL>
	XCHG			; And exchanging to get new DMA address in <DE>
	JMP	SETDMA		; Loop until done
;.....
;
;
ERROR:	LXI	B,ERRMSG	; Point to error message
	CALL	SNDMSG		; Send the bad news
	JMP	EXIT		; Quit here
;.....
;
;
CLOSE:	LXI	D,NUNAME	; Point to name of file again
	MVI	C,CLOSEF	; Close file function
	CALL	BDOS		; Returns 0FFH on error
	CPI	0FFH		; Check for proper close
	JZ	ERROR		; Send error message and quit

EXIT:	JMP	EXITJ1		; Return to calling module
;.....
;
;
SAVENN:	DB	0		; This number will be changed during
				; Execution to save the correct file size.
;.....
;
;
NOSTOP:	LDA	NOSTPF		; Printer flag set?
	ORA	A
	RNZ			; If yes, disregard this request
	LHLD	0FFFFH		; Maximum number of lines
	SHLD	HEIGHT		; Will not stop each screenful
	RET
;.....
;
;
SPFLAG:	LDA	PFLAG		; Get the printer request flag
	CMA			; Reverse its sense
	STA	PFLAG		; And leave it there for later use
	STA	NOSTPF
	RET
;
NOSTPF:	DB	0
;.....
;
;
STSAVF:	MVI	A,0FFH		; Set the 'disk save' flag
	STA	FFLAG		; Store it for later reference
	MVI	A,PLINES	; Store for possible printing later
	STA	HEIGHT
	RET
;.....
;
;
PTRON:	MVI	A,5
	STA	CKFNC+1		; Checks for printer ready
	MVI	A,PLINES	; Put this number of lines on printer
	STA	HEIGHT		; Also change display height to agree
;
	 IF	PNTRSP
	LXI	B,PTRONM	; Printer setup codes
	CALL	LSTOUT		; Send the message
	 ENDIF			; PNTRSP
;
	LXI	H,DONEPR	; Get address of DONEPR in <HL>
	SHLD	EXITJ1+1	; Hot patch the exit jump address
	RET
;.....
;
;
FORMFD:	LXI	B,FORMFEED	; Point to formfeed string
	JMP	LSTOUT		; Send formfeed, auto return
;
FORMFEED:
	DB	CR,FF,CR,0
;.....
;
;
;-----------------------------------------------------------------------
;			  help message
;
HELP:	LXI	B,HLPMSG
	CALL	SNDMSG
	JMP	BK2CCP
;
HLPMSG:	DB	'DIRR extended directory program v5, 01/07/86',CR,LF
	DB	CR,LF,'  Directory program, accepts '
	DB	'wildcards, extra commands via $ char:',CR,LF,CR,LF
	DB	'  B>DIRR ?              help guide',CR,LF
	DB	'  B>DIRR                all normal files '
	DB	'in current user area',CR,LF
	DB	'  B>DIRR $ANV           all on this user '
	DB	'area plus options A,N,V',CR,LF
	DB	'  B>DIRR *.ASM $A       all .ASM files plus '
	DB	'option A',CR,LF,CR,LF,'  Options:',CR,LF,CR,LF
	DB	'103H  A - files from all user areas, this '
	DB	'drive (nice with ''E'' below)',CR,LF
	DB	'104H  C - compressed display, extra '
	DB	'row, no filesize, aborts extended',CR,LF
	DB	'105H  E - extended display, includes '
	DB	'user area and any attributes',CR,LF
	DB	'106H  F - makes a disk file named ~DIR '
	DB	'after displaying the request',CR,LF
	DB	'107H  N - do not stop each screenful, '
	DB	'else say [more] when full',CR,LF
	DB	'108H  P - send output to the printer '
	DB	'(paginates if more than one page)',CR,LF
	DB	'109H  S - include any system files that '
	DB	'meet the request',CR,LF
	DB	'10AH  V - version number and date',CR,LF,CR,LF
	DB	'  CTL-X, CTL-C, X or K to abort at any time.'
	DB	CR,LF,CR,LF,0
;......
;
;
;-----------------------------------------------------------------------
;			  message area
;
VERMSG:	DB	'DIRR extended directory program v5, 01/07/86',CR,LF,0
ERRMSG:	DB	'DISK FULL',0
HTSPCM:	DB	CR,LF,'[more]',0
SPCS3M:	DB	'   ',0		; 3 spaces used in output formatting
CDELIM:	DB	' : ',0		; Row delimiter
USEDM:	DB	'Used: ',0
FILESM:	DB	'/',0		; Follows number of files computation
KOFMSG:	DB	'k   Free: ',0	; Displays total space used
TCAPM:	DB	'k   ',0	; Follows total space avail. on disk
;.....
;
;
;-----------------------------------------------------------------------
;
;
; The following 12 bytes are not directly addressed in the program
;
	DW	0,0,0,0,0,0	; Do not remove these.
;
XTNL0C:	DW	0
XTNL0E:	DW	0
XTNL10:	DW	0
NDSRCH:	DB	0		; Contains offset from 080H or 0FFH...
				; At end of search
INTFCB:	DB	0		; Contains current drive or "?" for....
				; Wildcard search if "U" flag set true
	DB	0,0,0,0		; Internal file control block bytes 2
	DB	0,0,0,0		;   thru 12.  Filled with search parms
	DB	0,0,0		;   to be loaded into DFCB for lookup
XTNL21:	DW	0
XTNL23:	DW	0
XTNL25:	DW	0
XTNL27:	DB	0
LINECT:	DW	0		; Current screen line number
BUFLOC:	DW	0		; Location of filename in buffer beginning at 080H
;
;
;-----------------------------------------------------------------------
;			disk parameters
;
INTDPB:				; Copy of the search disk parameter block
;
DPBSPT:	DW	0		; Sectors per track
DPBBSH:	DB	0		; Block shift factor
DPBBLM:	DB	0		; Block mask (2[bsh-1])
DPBEXM:	DB	0		; Extent mask
;
DPBDSM:	DW	0		; Disk storage maximum
DPBDRM:	DW	0		; Directory maximum entries
DPBAL0:	DB	0		; Alloc vector 0
DPBAL1:	DB	0		; Alloc vector 1
;
DPBCKS:	DW	0		; Directory check vector
DPBOFF:	DW	0		; Number of reserved tracks
;
;-----------------------------------------------------------------------
;
LSTLOC:	DB	0,0
STAKAD:	DB	0,0
;
XTNL3F:	DB	0,0
XTNL41:	DB	0
XTNL42:	DB	0
XTNL43:	DB	0
;
XTNL44:	DB	0
FLGIND:	DB	0,0
XTNL47:	DB	0,0
XTNL49:	DB	0,0
;
XTNL4B:	DB	0,0
XTNL4D:	DB	0,0
XTNL4F:	DB	0,0
XTNL51:	DB	0,0
;
XTNL53:	DB	0
XTNL54:	DB	0,0
XTNL56:	DW	0,0,0,0,0,0,0,0,0,0,0
XTNL6C:	DB	0,0
;
XTNL6E:	DW	0,0,0,0,0,0,0,0,0,0,0
XTNL84:	DB	0,0
XTNL86:	DB	0,0
XTNL88:	DB	0,0
;
XTNL8A:	DB	0
XTNL8B:	DB	0
XTNL8C:	DB	0
XTNL8D:	DB	0,0
;
XTNL8F:	DB	0,0
XTNL91:	DB	0,0
XTNL93:	DB	0,0
XTNL95:	DB	0,0
;
ROWCNT:	DB	0		; Row number counter
XTNL98:	DB	0,0
ALLOCV:	DB	0,0
XTNL9C:	DB	0,0
XTNL9E:	DB	0,0
;
XTNLA0:	DB	0,0
XTNLA2:	DB	0,0
XTNLA4:	DB	0
XTNLA5:	DB	0
;
XTNLA6:	DB	0,0
XTNLA8:	DB	0
XTNLA9:	DB	0
XTNLAA:	DB	0
;
XTNLAB:	DW	0,0,0,0,0,0,0	; 21 bytes total
	DB	0,0,0,0,0,0,0
;.....
;
;
; The file control block must be filled with the information shown at
; "NUNAME".  Thirty-two (32) bytes are required, the first byte is the
; drive specification and the next eleven (11) are the filename and ex-
; tention.  Do not use the '.' between filename and extent.  The rest of
; the bytes are set to '0' and MUST be in place.
;
NUNAME:	DB	0		; Drive number (0 = default drive)
	DB	'~DIR       '	; *****   name of new file    *****
	DB	0,0,0,0,0,0	; *****  leave space in FCB   *****
	DB	0,0,0,0,0,0	; *****   do not alter this   *****
	DB	0,0,0,0,0,0
	DB	0,0
	DB	0,0,0,0		; Four byte buffer zone for good measure
	DS	40		; Reserved for the stack area
;
STACK:	DS	2
;
	END
