;		      ZDR2.ASM
;Small, horizontal directory.  Sorts directory
;entries alphabetically, and presents them in
;horizontal order.  The "Z" of zdr shows the path 
;of the cursor. Will take disk specification on 
;command line:
;	A>zdr B:
;Understands user specifications in ZCPR style also:
;	A>zdr D2:
;When other disks(D) or users(U) are selected, zdr
;returns to the original DU: on exit.  If a user
;is specified, zdr shows the files in that user
;# only, though it continues to show total disk
;space, that is, space for the entire disk, all 
;users.  The object file is less than 1k in size, 
;and zdr is particularly useful when disk space is 
;limited, as in the Epson Geneva PX-8.
;
;Mike Yarus, 2231 16th Street, Boulder, CO 80302
;Compuserve 73145,513		    July, 1985
;
cnout	equ	02h	;BDOS functions
pstr	equ	09h	;	|
seldsk	equ	0Eh	;	|
schfrst	equ	11h	;	|
schnext	equ	12h	;	|
getdsk	equ	19h	;	|
allocv	equ	1Bh	;	|
dpbaddr	equ	1Fh	;	|
usernr	equ	20h	;_______v______
cr	equ	0Dh
lf	equ	0Ah
tab	equ	09h
tpastrt	equ	0100h
bdos	equ 	0005h
fcb	equ	05Ch
dma	equ	080h
dummy	equ	0000h	;marks run time addr
			;
	org 	tpastrt
			;
;current disk and user number data
			;
	mvi	c,usernr
	mvi	e,0FFh	;get user #
	call 	bdos	;and store it
	sta	initusr	;for possible change
			;
	mvi	c,getdsk;get current disk
	call	bdos
	sta	initdsk	;store current disk
			;
;new disk and/or user number?
			; 
	lda	fcb	;get disk, CPM-style
	cpi	0	;default?
	jnz	drv	;no, disk change needed
			;also check ZCPR spec
	lda	fcb+2	;check user, ZCPR-style
	cpi	' '	;blank?
	jz	fillfcb	;yes, no change needed
	sui	30h	;no, convert user to hex
	mov	e,a	;reset user
	mvi	c,usernr
	call	bdos	;switch!
			;
	lda	fcb+1	;get disk, ZCPR-style
	sui	40h	;1=A:, 2=B:, etc.
			;
drv	sui	1	;calc disk #
	mov	e,a	;0=A:, 1=B:, etc.
	mvi	c,seldsk;select new disk
	call	bdos	;switch!
			;	
fillfcb	lxi	h,ambgfcb	;write the ambiguous
	lxi	d,ambgfcb+10h	;fcb to search directory
	lxi	b,fcb+1		;CP/M did drive at fcb
	call 	movbyte	;move 'em!
			;
;block size data for cases different from 1k
			;
	mvi	c,dpbaddr
	call	bdos	;dpb addr in hl
	lxi	d,02h	;offset to block shift
	dad	d	;BSH addr in hl
	mov	a,m	;BSH in a
	sui	3h	;0=1k, 1=2k, 2=4k,...
	xchg		;dpb+2 -> de
	cma
	adi	1	;-block power in a
	lxi	h,times1;addr for x 1
	add	l
	mov	l,a	;addr for x block size
	shld	mult+1	;jmp addr at run time
	xchg		;dpb+2 back
	inx	h	;dpb+3, addr BLM
	mov	a,m	;get BLM
	inr	a	;BLM+1 = sectors/block
	rrc!rrc!rrc	;(BLM+1)/8 = k/block
	sta	blksiz	;store block size in k
			;
;begin directory search 
			;
getdir	lda	dirfn	;search first or next
	mov	c,a	
	lxi	d,fcb	
	call 	bdos	;fill dma w/ dir
	cpi	0FFh	;done?
	jz	eotbl	;yes, terminate table
			;
;calculate address of the directory entry
			;
	add a!add a!add a!add a!add a	;code*32
	adi	dma	;addr dir entry in a
			;
;read the directory entry
			;
	mov	c,a	;lo nibble, address
	mvi	b,0	;hi nibble zeroed
	ldax	b	;file name or user byte
	cpi	0E5h	;erased?
	jz 	setdirf	;yes, ignore entry
fname	inx	b	;no, get next addr
	ldax	b	;get char
	ani	7Fh	;mask hi bit
	cpi	20h	;is this a char?
	jm	extent	;not char, its the extent
	call	mktable	;add to directory table
	jmp 	fname	;around again
			;
;get extent and calculate size of the file
			;
extent	add a!add a!add a!add a	;# extents*16 = k
	mov	d,a		;k in extents -> d
	inx b!inx b!inx b	;addr of # records
	ldax	b	;get # records, this extent
			;
;a -> records/8, round up,= #k, add to extents
			;
	rrc ! rrc ! rrc	;records div 8, sort of
	mov	b,a	;save a
	ani	0E0h	;remainder? mask 11100000b
	mov	a,b	;a back, flags same
	jz 	thru	;no remainder
	adi	1	;remainder, round up
thru	ani	1Fh	;a has #k in records
	add	d	;+k in extents
			;file size in a
	call 	block	;correct to data block size
	call	mktable	;add to directory table
			;tally the entry
	lda	count	;total dir entries so far
	inr	a	;+ 1
	sta	count	;re-store
			;reset dirfn
setdirf	mvi	a,schnext
	sta	dirfn	;search for next
	jmp	getdir	;next entry!
			;
;got all entries, write "end of table" into dirtbl
			;
eotbl	mvi	a,60h	;put in string of 60h
	mvi	b,60h-0Ch	;counter set
mo	call 	mktable	;one 60h to dirtbl
	inr	b	;counter incremented
	cmp	b	;= a yet?
	jnz	mo	;no, move another byte
			;
;sort list of strings of length nrchar
;# strings is in location -> count
;de - address of string #2
;hl - address of string #1
			;
listhed	call 	init	;counters = 0, get top addr
strcomp	lda	entries	;# directory entries done
	inr	a
	sta	entries
	mov	b,a	;test for end of table
	lda	count	;tot entries in table
	cmp	b	;done?
	jz	endchk	;yes, check for sort end
	jm	stats	;no entries, give disk size
			;
	call 	stradd	;get string addresses
	call 	compar	;compare them, nrchar=12
	jm	next	;a=0, str =: a>0, str #1 bigger
			;
	call	stradd	;#1 bigger, interchange them
	call 	switch	;does it
	lda	swnr
	inr	a
	sta	swnr	;count the switch
			;
next	call 	nextstr	;incr string addresses
	jmp	strcomp	;do next string
			;
endchk	lda	swnr	;# exchanges
	ora	a	;is it 0?
	jnz	listhed	;no, init another round
			;yes, print the ordered list
			;
;print a sorted list of directory entries
;have been sorted alfa, and also w/ increasing file size
;print when two successive file names DIFFER
;in order to handle multiple extents of the same file
			;
	mvi	a,0Bh	;11d
	sta	nrchar	;compar 11 char strings
			;
	call	init	;entries=0, string1->dirtbl
nxtntry	lhld	string1	;load address
	mov	a,m	;get first char, str #1
	cpi	60h	;is it the end of table?
	jz	stats	;yes, do space output 
			;
	call	stradd	;str addresses
	call	compar	;1st 11 char of str same?
	cnz	writit	;no, differ, write them
	call	nextstr	;incr addresses
	jmp	nxtntry	;another entry
			;
;disk size and usage section
			;
stats	call 	eol	;after all files
	mvi	c,getdsk;current disk
	call	bdos	;get it
	adi	41h	;make ascii
	call	print	;write disk
	lxi	d,dskstr
	call 	prntstr	;disk title
			;
;calc total disk space from the disk param block
			;
	mvi	c,dpbaddr	;get DPB address
	call 	bdos	;addr in hl
	lxi	d,05h	;offset for DSM
	dad	d	;hl -> addr DSM
	call 	getwd	;(hl) -> hl
	inx	h	;# data blocks in hl
	shld	tot	;store # blocks/disk
			;
	call	mult	;multiply by block size
	call 	decimal	;#k total output from hl
	lxi	d,totstr
	call	prntstr	;tot title
			;
;find the address of the allocation vector, 
;then read the bit map and mask out the space 
;allocation for the disk.  Uses word arithmetic
;for total space.
;
;a-the bit mask, tests
;hl-address of bytes to be masked, the bit map
			;
getvect	mvi	c,allocv
	call	bdos
			;have the alloc addr in hl
	lda	mask	;get the byte mask, 1h
abyte	mov	b,m	;get a byte
	inx	h	;addr of next byte
			;
bitloop	rrc		;shift mask right
	sta	mask	;store mask
	ana	b	;bit set?
	cnz	nralloc	;yes, count this one
	push	h	;save addr of bit map
	call	totnr	;increment total, de<- totgrps
			;
	lhld	tot	;hl <- groups/disk
	call 	equal	;done? if a=0, were equal
	pop	h	;get addr back
	ora	a	;a=0?
	jz	done	;yep, done
			;o'wise, do another group
	lda 	mask	;get mask back
	cpi	1	;masked the last bit?
	jz	abyte	;yes,get another byte, mask=1
	jmp 	bitloop	;another bit
			;
done	lhld	alcgrps	;get allocated groups
	call	mult	;multiply by block size
	call 	decimal	;output!
	lxi	d,usedstr
	call 	prntstr	;print used title
			;
	lhld	alcgrps	;get allocated
	call 	neghl	;negate it, 2's complement
	xchg		;-alcgrps to de
	lhld	totgrps	;get tot grps/disk
	dad	d	;space word in hl
			;
	call 	mult	;multiply by block size
	call 	decimal	;output!
	lxi	d,lftstr
	call 	prntstr	;print remains title
			;
;reset to original disk and user, in case changed
			;
	mvi	c,usernr
	lda	initusr	;load original user #
	mov	e,a
	call 	bdos	;switch!
			;
	mvi	c,seldsk
	lda	initdsk	;select init disk
	mov	e,a
	call 	bdos	;switch!
			;done
back	ret		;back to CP/M <<< END, MAIN
			;
;format and write one dir entry to the screen
;gets address of string stored at string1
;writes 11 char, then file size thru "decimal"
			;
writit	lxi	d,estr	;'> ' before entries
	call 	prntstr	;write it
			;
	lhld	string1	;load the address
	mov	b,h
	mov	c,l	;set up for writit
	lxi	d,0Bh	;set counter, d=0, e=11
			;
nextchr	ldax	b	;get char
	inx	b	;next get
	call	print	;write it
	inr	d	;increment char count
	mov	a,e	;# char -> a
	cmp	d	;whole name yet?
	jnz	nextchr	;no, another char
	ldax	b	;get size of file
			;
	mvi	h,0	;set up
	mov	l,a	;for output
	call	decimal	;and do it
			;
	lxi	d,kstr
	call	prntstr	;'k ' out
			;
	lda	entries	;total dir entries so far
	inr	a	;+ 1
	sta	entries	;re-store
			;
;format output into lines with four files/line
			;
	ani	3	;00000011b mask
	cz	eol	;eol if a mod 4 = 0
	ret		;end of entry
			;
;string comparison routine, compares "nrchar" bytes
;h - address of string #1 < on exit = addr of difference
;d - address of string #2 < or addr after string, if =.
;b - counter < on exit, has # chars compared
;a=0, strings same: a>0, #1 bigger: a<0, #2 bigger
;flags also set to indicate result & can be used
			;
compar	mvi	b,0	;set byte counter
compar1	mov	a,m	;str #1 char -> a
	xchg		;#2 addr -> hl
	mov	c,m	;str #2 char -> c
	inr	b	;incr counter
	sub	c	;a=c?, strings same?
	rnz		;no
	xchg		;keep #1 in hl
	inx	d
	inx	h	;incr string addresses
			;
	lda	nrchar	;# char to check
	sub	b	;done?
	jnz	compar1	;no
	ret		;yes
			;
;exchange two strings of bytes of the coded length
;de - address of string #2
;hl - address of string #1
;b - counter
			;
switch	mvi	b,0	;initialize counter
switch1	mov	c,m	;str #1 char -> c
	ldax	d	;str #2 char -> a
	mov	m,a	;str #2 char -> #1
	mov	a,c	;#1 char -> a
	stax	d	;#1 char -> #2
			;
	inx	d
	inx	h	;incr addresses
	inr	b	;incr byte counter
	mov	a,b	;get counter
	cpi	12d	;12 char done?
	jnz	switch1	;no
	ret		;move done
			;
;set up string #1 and string #2 addr for sort or compar
			;
stradd	lhld	string1	;get current
	lxi	d,0Ch	;str offset
	dad	d	;get str #2 addr
	xchg
	lhld	string1	;get str #1 addr
	ret		;return
			;
;initialize for sort or print of sorted list
			;
init	xra	a	;a=0
	sta 	entries ;directory counter
	sta	swnr	;# switches, for sort
	lxi	h,dirtbl
	shld	string1	;address of current string
	ret		;
			;
;increment string address
			;
nextstr	lhld	string1	;get current
	lxi	d,0Ch	;offset between str
	dad	d
	shld	string1	;put back
	ret		;done
			;
;print char in a to console, save b and d
			;
print	push	b	;save b
	push	d	;save d
	mov	e,a	;posn to go -> cons
	mvi	c,cnout	;bdos #2
	call 	bdos
	pop	d	;d back
	pop	b	;b back
	ret		;done
			;
;bdos #9, print string at d, terminated by $
			;
prntstr	mvi	c,pstr
	call 	bdos
	ret		;done
			;
eol	lxi	d,crlf
	call	prntstr
	ret		;crlf at line end done
			;
;relocate the bytes beginning at  hl
;	      bytes end + 1   at  de
;		    to addr   at  bc
			;
movbyte	mov	a,m	;get a byte
	stax	b	;put byte to bc
	inx	b	;increment put addr
	inx	h	;increment get addr
			;
	mov	a,h	;hi nibble, get addr
	cmp	d	; = hi nibble, end?
	jnz	movbyte	;no, move another byte
			;
	mov	a,l	;lo nibble, get addr
	cmp	e	; = lo nibble, end?
	jnz	movbyte	;no, move another byte
			;
	ret		;done w/ move
			;
;gets file size in a in kbytes, calculates real size
;in a by adjusting to end on block borders
			;
block	mov	b,a	;size in k -> b
	lda 	blksiz	;get block size
	dcr	a	;mod mask
	cma		;complement of mask
	mov	c,a	;store
	cma		;mask back
	ana	b	;siz mod block = 0?
	mov	a,b	;get the number
	rz		;yes, return size unchanged
	lda	blksiz	;get block size
	add	b	;add one block to size
	ana	c	;mask off remainder
	ret		;done
			;
;output the hex number in hl as a decimal w/ lead blks
;puts the number in space 3 wide
			;
decimal	mvi	b,0FFh	;set counter to -1
			;
cento	lxi	d,-100	;100's
	dad	d	;hl - 100d
	inr	b	;count it
	mov	a,h
	ani	80h	;result negative? if a=0, no.
	jz	cento	;another 100?
			;
	mov	a,b	;get 100's
	sta	cs	;store them
	mvi	b,0FFh	;reset counter to -1
	lxi	d,100
	dad	d	;reset number
			;
deci	lxi	d,-10	;10's
	dad	d
	inr	b
	mov	a,h	;negative result?
	ani	80h
	jz	deci	;no, another 10?
			;
	mov	a,b	;get 10's
	sta	ts	;store
	lxi	d,10
	dad	d	;1's in hl
			;
	mov	a,l	;get 1's
	sta	os	;store them
			;
	lda	cs
	call 	prdeci	;100's
	lda	ts
	call 	prdeci	;10's
	lda	os
	call 	prdeci	;1's
			;
	xra	a	;zero to reset the
	sta	zflag	;print zeros flag
	ret
			;
;print decimal digit in a unless it is a leading zero
;when it will be a blank
			;
prdeci	mov	d,a	;save nr
	xri	0	;is the number a zero?
	jz	zero	;yes
	mvi	a,1	;set zflag after 1st non-0
	sta	zflag	;now printing zeros
	jmp 	pr	;get nr back, print
			;
zero	lda	zflag	;print a zero?
	ora	a	;0 = no
	jnz	pr	;yes, print
			;no, not printing 0's
	mvi	a,' '	;use a blank
	jmp 	ready	;out the blank
			;
pr	mov	a,d	;get nr back
	adi	30h	;make into ascii
ready	call 	print	;out, note bc saved
	ret
			;
;multiply the word in hl by 1,2,4,8,16 in order
;to calculate space for group size <> 1k
			;
mult	jmp	dummy	;replaced at run time
	dad	h	;x 16k
	dad	h	;x 8k
	dad	h	;x 4k
	dad	h	;x 2k
times1	equ	$	;x 1k
	ret
			;
;increment allocated groups, preserve hl
			;
nralloc	push	h	;save addr in hl
	lhld	alcgrps
	inx	h
	shld	alcgrps
	pop	h
	ret		;return
			;
;increment total groups, return totgrps in de
			;
totnr	lhld	totgrps
	inx	h
	shld	totgrps
	xchg		;totgrps -> de
	ret		;return
			;
;test equality of two words in de and hl
;return a = 0 for equality, no difference
;return a <> 0 for non-equality, is a difference
			;
equal	mov	a,d	;get hi nibble, de
	sub	h	;a=h?
	rnz		;no, return
	mov	a,e	;get lo nibble
	sub	l	;lo nibbles =?
	ret		;0 if =, <>0 if not equal
			;
;load hl with word at address in hl, addr+1 -> de
			;
getwd	mov	e,m	;lo nibble into e
	inx	h	;next byte
	mov	d,m	;hi nibble into d
	xchg		;de <--> hl
	ret		;addr+1 in de
			;
;negate the word in hl, ie, take 2's complement
			;
neghl	mov	a,l	;get lo nibble
	cma		;complement it
	mov	l,a	;back
	mov	a,h	;get hi nibble
	cma		;complement
	mov	h,a	;back
	inx	h	;+1
	ret		;-hl in hl
			;
;write byte in a to the growing directory table
			;
mktable	lhld	tbladdr	;get current address
	mov	m,a	;store the current entry
	inx	h	;incr addr
	shld	tbladdr	;restore addr
	ret
			;
ambgfcb	db	'????????????',0,0,0	;ambiguous fcb
			;
dirfn	db	schfrst	;search for first, init
tot	dw	0000	;allocation blocks per disk
totgrps	dw	0000	;total groups counted
alcgrps	dw	0000	;allocated groups counted
			;
mask	db	1	;the byte mask
count	db	00	;# dir entries, # output
entries	db	00	;dir entry counter
nrchar	db	0Ch	;# char to compar
swnr	db	00	;# of switches during sort
string1	dw	dirtbl	;addr of current dir string
			;
initdsk	ds	1	;initial disk: 0=A:, 1=B:, etc
initusr	ds	1	;initial user #
blksiz	ds	1	;block size
			;
estr	db	'> $'	;pre-entry string
kstr	db	'k $'	;k title
crlf	db	cr,lf,'$'
dskstr	db	': $'
usedstr	db	'k used >>$'
totstr	db	'k total/$'
lftstr	db	'k left$'
zflag	db	00	;print zero? 0 = no, 1= yes
cs	db	00	;100's	
ts	db	00	;10's
os	db	00	;1's
			;
tbladdr	dw	dirtbl	;current value of table address
dirtbl	equ	$	;start here, grow up!
			;
	end
