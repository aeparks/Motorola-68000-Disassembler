*-----------------------------------------------------------
* Program    : MOVE Test
* Written by : Aaron Parks
* Date       : 11 June 2010
* Description:
*-----------------------------------------------------------
	
b68_mask	EQU	$01C0	* 0000-0001-1100-0000
addr	EQU	$00AB4436	* random address

movea_1	EQU	$2049	* 0010-0000-0100-1001 sample move
move_1	EQU	$2008	* 0010-0000-0000-1000 sample move
move_2	EQU	$3208	* 0011-0010-0000-1000 sample move
move_3	EQU	$2A5F	* 0010-1010-0101-1111 sample move


	
	ORG	$1000
	
	MOVE.W	#movea_1,D0
	
	ANDI.L	#b68_mask,D0
	LSR.L	#6,D0	* should be 1

	MOVE.W	#move_1,D0
	ANDI.L	#b68_mask,D0
	LSR.L	#6,D0	* should be 0

	MOVE.W	#move_2,D0
	ANDI.L	#b68_mask,D0
	LSR.L	#6,D0	* should be 0

	MOVE.W	#move_3,D0
	ANDI.L	#b68_mask,D0
	LSR.L	#6,D0	* should be 1	
	
	STOP	#$2700
	
	END	$1000

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~12~
