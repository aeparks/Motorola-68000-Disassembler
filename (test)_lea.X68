*-----------------------------------------------------------
* Program    : LEA Test
* Written by : Aaron Parks
* Date       : 06 June 2010
* Description:
*-----------------------------------------------------------
	
bit8_mask	EQU	%0000000100000000	* isolate bit 8
lea_value	EQU	%0100010111001001	* sample lea

	ORG	$1000
	
	MOVE.L	#lea_value,D0	* load data register
	MOVE.L	#bit8_mask,D1	* load data register
	
	ANDI.L	#bit8_mask,D0	* and values
	LSR.L	#8,D0		* shift bit
	
	CMP.B	#1,D0		* compare value
	
	STOP	#$2700
	
	END	$1000


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~12~
