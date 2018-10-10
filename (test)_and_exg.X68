*-----------------------------------------------------------
* Program    : op-code AND and EXG
* Written by : Aaron Parks
* Date       : 11 June 2010
* Description:
*-----------------------------------------------------------
	
sample_and	EQU	$CE81	* 1100-1110-1000-0001 AND.L D7,D1
sample_exg1	EQU	$CB42	* 1100-1011-0100-0010
sample_exg2	EQU	$CB8A	* 1100-1011-1000-1010
opmode	EQU	$01C0	* 0000-0001-1100-0000
register	EQU	$0E00	* 0000-1110-0000-0000
bit8	EQU	$0100	* 0000-0001-0000-0000
bit45	EQU	$0030	* 0000-0000-0011-0000
bit37	EQU	$00F8	* 0000-0000-1111-1000
	
	ORG	$1000
	
	*MOVE.W	#sample_and,D0
	MOVE.W	#sample_exg1,D0
	
top	JMP	skip
	MOVE.W	D0,D1	* copy word
	ANDI.L	#bit8,D1	* isolate bit 8
	LSR.L	#8,D1	* shift to LSB position
	CMPI.B	#0,D1	* and
	BEq	and_	* branch to label
	MOVE.W	D0,D1	* copy word
	ANDI.L	#bit45,D1	* isolate bits 4 and 5
	LSR.L	#4,D1	* shift to LSB position
	CMPI.B	#0,D1	* and
	BEq	exg_	* branch to label
	JMP	and_	* jmp to and
exg_	NOP	
and_	NOP
	MOVE.W	D0,D1	* restore word in D1
	ANDI.L	#opmode,D1	* isolate opmode
	LSR.L	#6,D1	* shift bits to LSB position
	
skip	MOVE.L	D0,D1	* copy word value
	ANDI.L	#bit37,D1	* isolate op-mode
	LSR.L	#3,D1	* shift bits to LSB position
	
	MOVE.W	#sample_exg2,D0
	JMP	top
done	STOP	#$2700
	
	
	END	$1000

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~12~
