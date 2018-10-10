*-----------------------------------------------------------
* Program    : Displacement Test
* Written by : Aaron Parks
* Date       : 06 June 2010
* Description:
*-----------------------------------------------------------
	
tsk0	EQU	$00		* task 0 / for display
tsk1	EQU	$01		* task 1 / for display
increment	EQU	1		* increment amount
space	EQU	$20		* ascii space
nop_wrd	EQU	$4D71		* word for NOP

	ORG	$1000

	
	MOVE.W	#nop_wrd,D7		* load register
	LEA	specials, A0	* load register
	LEA	buffer,A1		* load register
	LEA	counter,A2		* load register
	
loop	CMP.B	#80,(A2)		* check counter
	BEq	break		* break out of loop?
	MOVE.B	#space,(A1)+	* write space to buffer
	ADDI.B	#increment,(A2)	* increment counter
	JMP	loop		* back to top
	
break	LEA	buffer, A1		* reload register
	CMP.W	#nop_wrd,D7		* compare values
	BEq	next		* branch to label
	
next	ADDA.L	#20,A0		* add displacement to storage address
	MOVE.L	(A0),(A1)+		* copy value to buffer
	
	MOVE.B	#space,(A1)+	* copy space
	MOVE.B	#space,(A1)+	* copy space
	
	LEA	specials,A0		* reload storage
	
	ADDA.L	#8,A0		* add displacement to storage address
	MOVE.L	(A0),(A1)+		* copy value to buffer
	
	MOVE.B	#tsk1,D0		* load task
	LEA	buffer,A1		* load buffer address
	MOVE.W	length,D1		* get length of string
	TRAP	#15		* display prompt1

	STOP	#$2700
	
buffer	DS.B	80		* storage for display
length	DC.W	length-buffer	* length of buffer
specials	DC.B	'CLR',$1A,'JSR',$1A,'JMP',$1A,'LEA',$1A,'NEG',$1A,'NOP',$1A,'RTS',$1A,'SWAP'
counter	DC.B	0		* counter for filling buffer
	
	END	$1000


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~12~
