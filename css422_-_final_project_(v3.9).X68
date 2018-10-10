*-------------------------------------------------------------------------------
* Program    : Final Project (ver 3.3)
* Written by : Aaron Parks, Neal Natsheh, Mark Shipman
* Date       : 29 May 2010
* Description: Will dissassemble a program loaded to memory.
*
*    Part 1: Will prompt user for a starting and ending address value where the
*    the program is located in memory. Error checking will be performed on the
*    user input. If the user input is not correct as per the displayed input
*    parameters, user will be prompted again. When correct input is detected, 
*    addresses will be stored.
*    Program API: A0 -
*	      A1 - pointer to string location
*	      A2 - 
*	      A3 - USED BY SUBROUTINES ONLY
*	      A4 - holds starting address
* 	      A5 - holds ending address
*	      A6 - temp storage for address comparison
*	      D0 - holds task number
*	      D1 - holds string length
*	      D2 -
*	      D3 -
*	      D4 -
*	      D5 -
*	      D6 - temp storage for ascii patterns
*	      D7 - converted characaters for addresses
*
*    Part 2:
*    Program API: A0 - pointer to storage for patterns
*	      A1 - pointer to storage for binary of word / good_buffer / bad_buffer
*	      A2 - USED FOR SUBROUTINES ONLY
*	      A3 - USED FOR SUBROUTINES ONLY
*	      A4 - holds starting address
* 	      A5 - holds ending address
*	      A6 - assigned to flag
*	      D0 - word read in from memory
*	      D1 - temp holder for word read from memory
*	      D2 - holds first four MSB for comparison / temp copy of word in D0
*	      D3 - Effective Address register size
*	      D4 -
*	      D5 - USED FOR SUBROUTINES ONLY
*	      D6 - USED FOR SUBROUTINES ONLY
*	      D7 - Effective Address Mode
*
*    Part 3:
*-------------------------------------------------------------------------------
	OPT	CRE
*-------------------------------------------------------------------------------
*	EQU - Ascii Values
*-------------------------------------------------------------------------------
newline	EQU	$0A		* ascii value for new line
return	EQU	$0D		* ascii value for carriage return
sub	EQU	$1A		* ascii value for substitution
space	EQU	$20		* ascii value for space
dspace	EQU	$2020		* double space
qspace	EQU	$20202020		* quad spacing
num	EQU	$23		* ascii value for pound
hex	EQU	$24		* ascii value for dollar
bin	EQU	$25		* ascii value for percentage
opp	EQU	$28		* ascii value for open paren
clp	EQU	$29		* ascii value for closed paren
plus	EQU	$2B		* ascii value for plus
comma	EQU	$2C		* ascii value for comma
minus	EQU	$2D		* ascii value for minus
dot	EQU	$2E		* ascii value for period
byte	EQU	$42		* ascii value for B
long	EQU	$4C		* ascii value for L
word	EQU	$57		* ascii value for W
*-------------------------------------------------------------------------------
*	Tasks for I/O
*-------------------------------------------------------------------------------	
tsk0	EQU	$00		* display with newline
tsk1	EQU	$01		* display without newline
tsk2	EQU	$02		* accept user input
*-------------------------------------------------------------------------------
*	EQU - 
*-------------------------------------------------------------------------------
start_bnds	EQU	$00001000		* lower address bounds
end_bnds	EQU	$000FFFFF		* upper address bounds
stk_ptr	EQU	$00A00000		* start of stack

shift	EQU	4		* shift distance
increment	EQU	1		* increment amount
n_key	EQU	$30		* subtraction value for numbers
u_key	EQU	$37		* subtraction value for uppercase
l_key	EQU	$57		* subtraction value for lowercase
addcnt	EQU	$04		* used to convert mem add to ASCII
pattcnt	EQU	$02		* used to convert pattern to ASCII
dec_cnt	EQU	00000001		* used to decrement counter by 1
empty_cnt	EQU	00000000		* to check if max # error cnt reached
*-------------------------------------------------------------------------------
*	MASKS
*-------------------------------------------------------------------------------
* for converting entire long
mask_byte1	EQU	$FF000000		* isolate byte 4
mask_byte2	EQU	$00FF0000		* isolate byte 3
mask_byte3	EQU	$0000FF00		* isolate byte 2
mask_byte4	EQU	$000000FF		* isolate byte 1	
* for generating binary for word
mask_left	EQU	$00F0		* isolate left nibble
mask_right	EQU	$000F		* isolate right nibble
* for isolation in add
arith_mask1	EQU	$000FFF00		* isolate opmode
arith_mask2	EQU	$FFF00000	     	* isolate register
arith_mask3	EQU	$000000FF		* determine when to pass to EA
arith_mask4	EQU	$00FFFFFF		* isolate EA bits
arith_mask5	EQU	$0000FFF0		* second mask used to isolate register bits
* for isolation in specials and exchange
bit6_mask	EQU	$0040		* isolate bit 6
bit8_mask	EQU	$0100		* isolate bit 8
bit9_mask	EQU	$0200		* isolate bit 9
b911_mask	EQU	$0E00		* isolate bits 9 - 11
b45_mask	EQU	$0030		* isolate bits 4 and 5
b37_mask	EQU	$0078		* isolate bits 3 - 7 (exg mode)
b35_mask	EQU	$0038		* isolate bits 3 - 5 (ea mode)
size_mask	EQU	$00C0		* isolate bits 6 and 7 (for CLR and NEG)
swap_mask	EQU	$0007		* isolate bits 0 - 2
movm_mask	EQU	$0400		* isolate bit 10
* for isolation in exchange	
* for effective addressing
ea_mask0	EQU	$0000003F		* zero all bits but EA bits
ea_mask1	EQU	$00FFF000		* isolate mode
ea_mask2	EQU	$00000FFF		* isolate register
* other masks
opmd_mask	EQU	$01C0		* isolates bits for opmode (standard location)
reg_mask	EQU	$0E00		* isolates bits for register (standard location)
addr_mask1	EQU	$000000F0		* used to convert 1st nibble to ASCII
addr_mask2	EQU	$0000000F		* used to convert 2nd nibble to ASCII
mask_even	EQU	$FFFFFFFE		* for making addresses even
*-------------------------------------------------------------------------------
*	MODES
*-------------------------------------------------------------------------------
mode0	EQU	$0000		* mode zero
mode1	EQU	$0001		* mode one
mode2	EQU	$0010		* mode two
mode3	EQU	$0011		* mode three
mode4	EQU	$0100		* mode four
mode5	EQU	$0101		* mode five
mode6	EQU	$0110		* mode six
mode7	EQU	$0111		* mode seven
*-------------------------------------------------------------------------------
*	REGISTER VALUES (EFFECTIVE ADDRESS)
*-------------------------------------------------------------------------------
reg0	EQU	0		* value zero
reg1	EQU	1		* value one
reg4	EQU	4		* value four
*-------------------------------------------------------------------------------
*	MISC VALUES
*-------------------------------------------------------------------------------
increment	EQU	1		* increment amount
loop	EQU	2		* number of times to loop
bad	EQU	$FF		* value of bad flag
good	EQU	$00		* value of good flag
reset	EQU	$00		* zero (for counter)
empty	EQU	$00000000		* used to zero a register
nop_opcode	EQU	$4D71		* compare for NOP
rts_opcode	EQU	$4D75		* compare for RTS
wrd_patt	EQU	$D0A9		* TEST VALUE
next_patt	EQU	$46464645		* TEST VALUE
	
*-------------------------------------------------------------------------------
*	PROGRAM CODE
*-------------------------------------------------------------------------------
	ORG	$1000		* program origin
	
prgm_start	MOVEA.L	#stk_ptr,SP		* load stack pointer
	JSR	display		* display program header
usr_prmpt1	MOVE.B	#tsk1,D0		* load task
	LEA	prompt1,A1		* get address of string
	MOVE.W	p_len1,D1		* get length of string
	TRAP	#15		* display prompt1
usr_inpt1	MOVE.B	#tsk2,D0		* load task
	LEA	s_addr,A1		* store string from user
	MOVE.W	#(e_addr-s_addr),D1	* length of user input
	TRAP	#15		* get user input
	MOVE.B	D1,s_a_l		* copy length to storage

	MOVE.L	#empty,D7		* zero register
	LEA	s_addr,A3		* load starting address
	JSR	convert		* subroutine "cnvrt"
	MOVE.L	D7,A4		* load register with hex s_addr

	JSR	isValid		* subroutine "isValid"
	CMP.L	#empty,D7		* compare flag
	BNE	usr_prmpt1		* branch to top (usr_prmpt1)

usr_prmpt2	MOVE.B	#tsk1,D0		* load task
	LEA	prompt2,A1		* get address of string
	MOVE.W	p_len2,D1		* get length of string
	TRAP	#15		* display prompt2
usr_inpt2	MOVE.B	#tsk2,D0		* load task
	LEA	e_addr,A1		* store string from user
	MOVE.B	#(counter-e_addr),D1	* length of user input
	TRAP	#15		* get user input	
	MOVE.B	D1,e_a_l		* load length to storage

	MOVE.L	#empty,D7		* zero register
	LEA	e_addr,A3		* load ending address
	JSR	convert		* subroutine "cnvrt"
	MOVEA.L	D7,A5		* load register with hex e_addr

	JSR	isValid		* subroutine "isValid"
	CMP.L	#empty,D7		* compare flag
	BNE	usr_prmpt2		* branch to top 'usr_prmpt2'

fst_chk	CMPA.L	A5,A4		* compare starting and ending addresses
	BLT	lst_chk		* branch to last check
	MOVE.B	#tsk1,D0		* load task number
	LEA	error4,A1		* get address of string
	MOVE.W	#e_len4,D1		* get length of string
	TRAP	#15		* display error message
	JMP	usr_prmpt2		* jump to top 'usr_prmpt2'
lst_chk	MOVEA.L	A5,A6		* load address
	SUBQ.L	#$2,A6		* subtract a word from ending address
	CMPA.L	A4,A6		* compare starting and ending addresses
	BGE	sub_main		* branch to 'main program
	MOVE.B	#tsk1,D0		* load task number
	LEA	error3,A1		* get address of string
	MOVE.W	#e_len3,D1		* get length of string
	TRAP	#15		* display error messasge
	JMP	usr_prmpt1		* jump to top 'usr_prpmt1'

*-------------------------------------------------------------------------------
* 	REGISTER CONDITIONS AFTER USER INPUT AND ERROR CHECKING
* 	A4 - starting address
* 	A5 - ending address
*-------------------------------------------------------------------------------
sub_main	JSR	clearReg		* clear all registers (except for A4 and A5)
	LEA	flag,A6		* load register with flag address
main	LEA	bin_pattern,A0	* load register  *THIS IS TOP OF LOOP, WILL RETURN HERE
	LEA	bin_storage,A1	* load register
	MOVE.B	#good,(A6)		* reset flag
	JSR	setBuffers		* initialize buffers
	LEA	bad_buffer,A2	* load address of bad buffer
	*MOVE.W	(A4)+,D0		* load word from memory	
	MOVE.W	#wrd_patt,D0	* load register,  FOR TESTING ONLY
	MOVE.W	D0,D1		* copy word to register D1
	ANDI.L	#mask_byte3,D0	* isolate byte 2
	ROR.L	#8,D0		* shift to LSB position
	*JSR	hexToA		* convert and copy to buffer
	MOVE.W	D1,D0		* copy word to register D0
	ANDI.L	#mask_byte4,D0	* isolate byte 1
	*JSR	hexToA		* convert and copy to buffer
	MOVE.B	#newline,(A2)+	* add new line to buffer
	MOVE.B	#return,(A2)+	* add carriage return to buffer
	
	MOVE.B	#reset,counter	* reset counter
gen_type	CMPI.B	#loop,counter	* check loop sentinel value
	BGE	op_type		* exit loop?
	ROL.W	#8,D0		* rotate MSBs to LSBs
	MOVE.W	D0,D1		* operate only on D1
	
	ANDI.W	#mask_left,D1	* isolate left nibble
	ROR.W	#4,D1		* shift to LSB
	ADD.W	D1,D1		* double value
	ADD.W	D1,A0		* shift pointer to pattern
	MOVE.W	(A0),(A1)+		* copy word to storage
	LEA	bin_pattern,A0	* restore pattern pointer
	MOVE.W	D0,D1		* restore register
	
	ANDI.W	#mask_right,D1	* isolate right nibble
	ADD.W	D1,D1		* double value
	ADD.W	D1,A0		* shift pointer to pattern
	MOVE.W	(A0),(A1)+		* copy word to storage
	LEA	bin_pattern,A0	* restore pattern pointer
	ADDQ.B	#increment,counter	* increment counter
	JMP	gen_type		* jump to top of loop
	
	* D0 contains word from memory
	* 'storage' contains binary for word
op_type	LEA	bin_storage,A1	* load register with addres of bin_storage
	LEA	good_buffer,A2	* load register with address of good_buffer
	MOVE.W	(A1)+,D2		* move first 4 bits to D2
	CMP.W	#$0000,D2		* nibble 0: ADDI, ANDI, CMPI, EORI, ORI, SUBI
	*BEq	logii_		* "immediate" branch
	CMP.W	#$0001,D2		* nibble 1: MOVE.B
	*BEq	moveb_		* "move type byte" branch
	CMP.W	#$0010,D2		* nibble 2: MOVE.L, MOVEA.L
	*BEq	movel_		* "move type long" branch
	CMP.W	#$0011,D2		* nibble 3: MOVE.W, MOVEA.W
	*BEq	movew_		* "move type word" branch
	CMP.W	#$0100,D2		* nibble 4: CLR, JMP, JSR, RTS, NEG, NOP, LEA, SWAP, MOVEM
	BEq	specl_		* "special codes" branch
	CMP.W	#$0101,D2		* nibble 5: BAD
	*BEq	setBad		* set bad flag
	CMP.W	#$0110,D2		* nibble 6: BSR, BRA, Bcc (Branch Condition Code)
	*BEq	brnch_		* "branch / BRA, BEq, BGT, BGE, BLT, BLE, BNE" branch
	CMP.W	#$0111,D2		* nibble 7: BAD
	*BEq	setBad		* set bad flag
	CMP.W	#$1000,D2		* nibble 8: OR
	*BEq	or_		* "or" branch
	CMP.W	#$1001,D2		* nibble 9: SUB, SUBA
	*BEq	sub_		* "subtraction" branch
	CMP.W	#$1011,D2		* nibble B: CMP, CMPA, EOR
	*BEq	comp_		* "compare and exclusive-or" branch
	CMP.W	#$1100,D2		* nibble C: AND, EXG
	BEq	ane_		* "and / exg" branch
	CMP.W	#$1101,D2		* nibble D: ADD, ADDA
	*BEq	add_		* "add" branch
	CMP.W	#$1110,D2		* nibble E: ASR, ASL, LSR, LSL, ROL, ROR
	*BEq	manip_		* "left-right manipulation" branch
	CMP.W	#$1111,D2		* nibble F: RESERVED (thus bad)

setBad	MOVE.B	#bad,flag		* set flag to bad
	JMP	prnttoscrn		* jump to printer
	
prnttoscrn	MOVE.L	#empty,D0		* clear register
	CMP.B	#good,flag		* check flag state
	BEq	prnt_good		* display good buffer
	LEA	bad_buffer,A1	* load address of bad buffer
	JMP	printer		* goto printer
prnt_good	LEA	good_buffer,A1	* load address of good buffer
printer	MOVE.B	#tsk0,D0		* load task
	MOVE.W	#$80,D1		* load length of storage
	TRAP	#15		* display storage
	
	* sentinel programming here
	
	STOP	#$2700		* return to program main
	
********************************************************************************	
*						       *
*		     OP-CODE BRANCHES		      	       *
*						       *
********************************************************************************
* Branch Description: ADD and ADDA (nibble D)
********************************************************************************

* code here

********************************************************************************
* Description: AND and EXG (nibble C)
********************************************************************************
ane_	MOVE.W	D0,D1		* copy word
	ANDI.L	#bit8_mask,D1	* isolate bit 8
	LSR.L	#8,D1		* shift to LSB position
	CMPI.B	#0,D1		* check if zero
	BEq	and_		* branch to "and_"label
	MOVE.W	D0,D1		* copy word
	ANDI.L	#b45_mask,D1	* isolate bits 4 and 5
	LSR.L	#4,D1		* shift to LSB position
	CMPI.B	#0,D1		* check if zero
	BEq	exg_		* branch to "exg_" label
	JMP	and_		* jmp to "and_" label

and_	LEA	lgic_stor,A0	* load storage
	MOVE.L	(A0),(A2)+		* copy long to buffer
	MOVE.W	D0,D1		* restore word in register D1
	ANDI.L	#opmd_mask,D1	* isolate op-mode
	LSR.L	#6,D1		* shift bits to LSB position
	MOVE.B	D1,D5		* store op-mode in D5
	MOVE.W	D0,D1		* restore word in register D1
	ANDI.L	#reg_mask,D1	* isolate register
	LSR.L	#8,D1		* shift bits towards LSB position
	LSR.L	#1,D1		* shift one more bit
	MOVE.B	D1,D6		* store register in D6
	ADDI.B	#$30,D6		* adjust value to ascii
	CMPI.B	#0,D5		* check if equal to zero
	BEq	and_byte		* branch to label
	CMPI.B	#1,D5		* check if equal to one
	BEq	and_word		* branch to label
	CMPI.B	#2,D5		* check if equal to two
	BEq	and_long		* branch to label
	CMPI.B	#4,D5		* check if equal to four
	BEq	and_byte		* branch to label
	CMPI.B	#5,D5		* check if equal to five
	BEq	and_word		* branch to label
	CMPI.B	#6,D5		* check if equal to six
	BEq	and_long		* branch to label
	JMP	setBad		* set bad flag
	
and_byte	MOVE.B	#byte,(A2)+		* add B to buffer
	JMP	and_geto		* branch to label
and_word	MOVE.B	#word,(A2)+		* add W to buffer
	JMP	and_geto		* branch to label
and_long	MOVE.B	#long,(A2)+		* add L to buffer
and_geto	MOVE.B	#space,(A2)+	* add space to buffer
	CMPI.B	#3,D5		* check op mode value
	BLT	and_ea_dn		* branch to label
	CMPI.B	#3,D5		* check op mode value
	BGT	and_dn_ea		* branch to label
and_dn_ea	MOVE.L	#empty,D5		* clear register
	MOVE.B	#$44,(A2)+		* add D to buffer
	MOVE.B	D3,(A2)+		* add register number to buffer
	MOVE.B	#comma,(A2)+	* add , to buffer
	ANDI.L	#ea_mask0,D0	* isolate effective addressing bits
	JSR	genEA		* generate Effective Address
	JMP	ane_done		* jump to end
and_ea_dn	MOVE.L	#empty,D5		* clear register	
	ANDI.L	#ea_mask0,D0	* isolate effective addressing bits
	JSR	genEA		* generate Effective Address
	MOVE.B	#comma,(A2)+	* add , to buffer
	MOVE.B	#$44,(A2)+		* add D to buffer
	MOVE.B	D3,(A2)+		* add register number to buffer
	JMP	ane_done		* jump to end
	
exg_	LEA	lgic_stor,A0	* load register with address of storage
	ADDA.L	#8,A0		* add displacemet to address
	MOVE.L	(A0),(A2)+		* copy word from storage to buffer
	MOVE.B	#space,(A2)+	* add space to buffer
	MOVE.W	D0,D1		* copy word to D1
	ANDI.L	#b911_mask,D1	* isolate bits for data register
	LSR.L	#8,D1		* shifts bits towards LSB position
	LSR.L	#1,D1		* shift one more
	ADDI.B	#$30,D1		* convert number to ascii
	MOVE.B	D1,D5		* store number in D5
	MOVE.W	D0,D1		* restore word to D1
	ANDI.L	#swap_mask,D1	* isolate bits for address register
	ADDI.B	#$30,D1		* convert number to ascii
	MOVE.B	D1,D6		* store number in D6
	MOVE.W	D0,D1		* restore word to D1
	ANDI.L	#b37_mask,D1	* isolate op-mode bits
	LSR.L	#3,D1		* shifts bits to LSB position
	CMPI.B	#8,D1		* check if equal to eight
	BEq	exg_dn_dn		* branch to label
	CMPI.B	#9,D1		* check if equal to nine
	BEq	exg_an_an		* branch to label
	CMPI.B	#$11,D1		* check if equal to eleven
	BEq	exg_dn_an		* branch to label
	JMP	setBad		* set bad flag
	
exg_dn_dn	MOVE.B	#$44,(A2)+		* add D to buffer
	MOVE.B	D5,(A2)+		* add number to buffer
	MOVE.B	#comma,(A2)+	* add , to buffer
	MOVE.B	#$44,(A2)+		* add D to buffer
	MOVE.B	D6,(A2)+		* add number to buffer
	JMP	ane_done		* jump to end	
exg_an_an	MOVE.B	#$41,(A2)+		* add A to buffer
	MOVE.B	D5,(A2)+		* add number to buffer
	MOVE.B	#comma,(A2)+	* add , to buffer
	MOVE.B	#$41,(A2)+		* add A to buffer
	MOVE.B	D6,(A2)+		* add number to buffer
	JMP	ane_done		* jump to end
exg_dn_an	MOVE.B	#$44,(A2)+		* add D to buffer
	MOVE.B	D5,(A2)+		* add number to buffer
	MOVE.B	#comma,(A2)+	* add , to buffer
	MOVE.B	#$41,(A2)+		* add A to buffer
	MOVE.B	D6,(A2)+		* add number to buffer
	JMP	ane_done		* jump to end

ane_done	MOVE.B	#newline,(A2)+	* add newline to buffer
	MOVE.B	#return,(A2)+	* add carriage return to buffer
	MOVE.L	#empty,D6		* clear register
	MOVE.L	#empty,D5		* clear register
	MOVE.L	#empty,D1		* clear register
	MOVE.L	#empty,D0		* clear register
	JMP	prnttoscrn		* jump to printer	

********************************************************************************
* Description: SUB and SUBA (nibble 9)
********************************************************************************

* code here


********************************************************************************
* Description: ADDI, ANDI, CMPI, EORI, ORI, SUBI (nibble 0)
********************************************************************************

* code here

********************************************************************************
* Description: CMP, CMPA, EOR (nibble B)
********************************************************************************

* code here

********************************************************************************
* Description: MOVE, MOVEA type Byte (nibble 1)
********************************************************************************

* code here

********************************************************************************
* Description: MOVE, MOVEA type Long (nibble 2)
********************************************************************************

* code here

********************************************************************************
* Description: MOVE, MOVEA type Word (nibble 3)
********************************************************************************

* code here

********************************************************************************
* Description: OR (nibble 8)
********************************************************************************

* code here

********************************************************************************
* Description: BSR (nibble 6)
********************************************************************************

* code here

********************************************************************************
* Description: ASL, ASR, LSL, LSR, ROL, ROR (nibble E)
********************************************************************************

* code here

********************************************************************************
* Description: Special Cases (nibble 4)
********************************************************************************
specl_	LEA	spec_stor,A0	* load address register with storage
	LEA	good_buffer,A2	* load address register with buffer
	MOVE.W	D0,D2		* copy word to temp register D2

	CMP.W	#nop_opcode,D0	* check for NOP
	BEq	nop_		* branch to "nop_" label
	CMP.W	#rts_opcode,D0	* check for RTS
	BEq	rts_		* branch to "rts_" label
	ANDI.L	#bit8_mask,D2	* isolate bit 8
	LSR.L	#8,D2		* shift bit to the left
	CMPI.B	#1,D2		* compare if 1 or 0
	BEq	lea_		* branch to "lea_" label
	MOVE.W	D0,D2		* restore word from D0
	ANDI.L	#b911_mask,D2	* isolate bits 9 through 11
	LSR.L	#8,D2		* shift bits
	LSR.L	#1,D2		* shift one more
	CMPI.B	#1,D2		* check if equal to 1
	BEq	clr_		* branch to "clr_" label
	CMPI.B	#2,D2		* check if equal to 2
	BEq	neg_		* branch to "neg_" label
	CMPI.B	#3,D2		* check if equal to 3
	BEq	not_		* branch to "not_" label
	MOVE.W	D0,D2		* restore word from D0
	ANDI.L	#b35_mask,D2	* isolate bits 3 - 5 (EA mode)
	LSR.L	#3,D2		* shift bits
	CMPI.B	#0,D2		* check if equal to zero
	BEq	swap_		* branch to "swap_" label
	MOVE.W	D0,D2		* restore word from D0
	ANDI.L	#bit9_mask,D2	* isolate bit 9
	LSR.L	#8,D2		* shift bits
	LSR.L	#1,D2		* shift twice more
	CMPI.B	#0,D2		* check if equal to 0
	BEq	movem_		* branch to "movem_" label
	MOVE.W	D0,D2		* restore word from D0
	ANDI.L	#bit6_mask,D2	* isolate bit 6
	LSR.L	#6,D2		* shift the bit
	CMPI.B	#0,D2		* check if equal to zero
	BEq	jsr_		* branch to "jsr_" label
	BRA	jmp_		* branch to "jmp_" label	
		
nop_	ADDA.L	#20,A0		* add displacement to address
	MOVE.L	(A0),(A2)+		* copy value from storage to buffer
	JMP	spc_done		* jump to end
rts_	ADDA.L	#28,A0		* add displacement to address
	MOVE.L	(A0),(A2)+		* copy value from storage to buffer
	JMP	spc_done		* jump to end
lea_	ADDA.L	#12,A0		* add displacement to address
	MOVE.L	(A0),(A2)+		* copy value from storage to buffer
	ADDI.B	#2,(A2)+		* advance buffer pointer by two bytes
	MOVE.B	#hex,(A2)+		* add # to buffer
	MOVE.W	D0,D2		* restore word from D0
	ANDI.L	#ea_mask0,D2	* isolate EA bits
	JSR	genEA		* generate Effective Address
	MOVE.W	D0,D2		* restore word from D0
	MOVE.B	#comma,(A2)+	* add , to buffer
	JSR	lea_reg		* goto subroutine to determine register
	JMP	spc_done		* jump to end
clr_	MOVE.L	(A0),(A2)+		* copy value from storage to buffer
	MOVE.W	D0,D2		* restore word from D0
	JSR	getSize		* goto subroutine to determine operator size
	MOVE.W	D0,D2		* restore word from D0
	JMP	spc_ea		* jump to effective addressing
neg_	ADDA.L	#16,A0		* add displacement to address
	MOVE.L	(A0),(A2)+		* copy value from storage to buffer
	MOVE.W	D0,D2		* restore word from D0
	JSR	getSize		* goto subroutine to determine operator size
	MOVE.W	D0,D2		* restore word from D0
	JMP	spc_ea		* jump to effective addressing
not_	ADDA.L	#24,A0		* add displacement to address
	MOVE.L	(A0),(A2)		* copy value from storage to buffer
	MOVE.W	D0,D2		* restore word from D0
	JSR	getSize		* goto subroutine to determine operator size
	MOVE.W	D0,D2		* restore word from D0
	JMP	spc_ea		* jump to effective addressing
swap_	ADDA.L	#32,A0		* add displacement to address
	MOVE.L	(A0),(A2)+		* copy value from storage to buffer
	MOVE.B	#space,(A2)+	* add space to buffer
	MOVE.B	#space,(A2)+	* add space to buffer
	MOVE.B	#space,(A2)+	* add space to buffer
	MOVE.B	#$44,(A2)+		* add D to buffer
	MOVE.W	D0,D2		* restore word from D0
	ANDI.L	#swap_mask,D2	* isolate register size
	ADDI.B	#$30,D2		* convert to ascii
	MOVE.B	D2,(A2)+		* copy ascii value to buffer
	JMP	spc_done		* jump to end
movem_	LEA	move_stor,A0	* load storage for 'move'
	MOVE.L	(A0),(A2)+		* copy value from storage to buffer
	MOVE.B	#$4D,(A2)+		* add "M" to buffer
	MOVE.B	#space,(A2)+	* add a space to buffer
	MOVE.B	#space,(A2)+	* add a space to buffer	
	MOVE.W	D0,D2		* restore word from D0
	JSR	movemsr		* goto "movemsr" subroutine
	JMP	spc_done		* jump to end
jsr_	ADDA.L	#4,A0		* add displacement to address
	MOVE.L	(A0),(A2)+		* copy value from storage to buffer
	JMP	spc_ea		* jump to effective addressing
jmp_	ADDA.L	#8,A0		* add displacement to address
	MOVE.L	(A0),(A2)+		* copy value from storage to buffer
spc_ea	MOVE.W	D0,D2		* restore word from D0
	ANDI.L	#ea_mask0,D2	* isolate last six bits 
	JSR	genEA		* generate Effective Address	
spc_done	JMP	prnttoscrn		* jump to printer			
********************************************************************************	
*						       *
*		       SUBROUTINES			       *
*						       *
********************************************************************************	
*-------------------------------------------------------------------------------
* Subroutine: genEA
* Description: Will generate the proper Effective Address the last six bits in
*              stored in D2
* API: 	A0 - points to binary pattern storage
*	A2 - pointer to good_buffer 
*	A6 - points to flag
*	D2 - contains six bits for 
*	D3 - holds register number
*	D7 - holds mode      
*-------------------------------------------------------------------------------
genEA	LEA	flag,A6		* load register with flag address
	MOVE.L	#empty,D3		* clear register
	MOVE.L	#empty,D7		* clear register
	MOVE.L	D2,D7		* copy to temp location
	ANDI.L	#ea_mask1,D7	* isolate mode
	LSR.L	#8,D7		* shift some
	LSR.L	#4,D7		* shift more
	AND.L	#ea_mask2,D2	* isolate register
	LEA	bin_pattern,A0	* re-initalize A0 to point to begining of patterns
	JSR	bin_to_dec		* convert value in D2 to decimal
	ADDI.B	#$30,D3		* determine data register value in ASCII

	CMP.W	#mode0,D7		* is equal to zero
	BEq	mode_dn		* branch to data register
	CMP.W	#mode1,D7		* is equal to one
	BEq	mode_an		* branch to address register
	CMP.W	#mode2,D7		* is equal to two
	BEq	mode_anin		* branch to address indirect
	CMP.W	#mode3,D7		* is equal to three
	BEq	mode_anplus		* branch to address register post-increment
	CMP.W	#mode4,D7		* is equal to four
	BEq	mode_andec		* branch to address register pre-decrement
	CMP.W 	#mode5,D7		* is equal to five
	BEq	mode_aninx		* branch to address indirect with index
	CMP.W	#mode7,D7		* is equal to seven
	BEq	mode_svn		* branch to mode seven
	MOVE.B	#bad,(A6)		* set flag to bad
	JMP	genEA_done		* jump to end
	
mode_dn	MOVE.B	#$44,(A2)+		* add 'D' to buffer
	MOVE.B	D3,(A2)		* copy register number to buffer
	JMP	genEA_done		* jump to end of subroutine
mode_an	MOVE.B	#$41,(A2)+		* add 'A' to buffer
	MOVE.B	D3,(A2)		* copy register number to buffer
	JMP	genEA_done		* jump to end of subroutine
mode_anin	MOVE.B	#opp,(A2)+		* add '(' to buffer
	MOVE.B	#$41,(A2)+		* add 'A' to buffer
	MOVE.B	D3,(A2)+		* copy register number to buffer
	MOVE.B	#clp,(A2)		* add ')' to buffer
	JMP	genEA_done		* jump to end of subroutine
mode_anplus	MOVE.B	#opp,(A2)+		* add '(' to buffer
	MOVE.B	#$41,(A2)+		* add 'A' to buffer
	MOVE.B	D3,(A2)+		* copy register number to buffer
	MOVE.B	#clp,(A2)+		* add ')' to buffer
	MOVE.B	#plus,(A2)		* add '+' to buffer
	JMP	genEA_done		* jump to end of subroutine
mode_andec	MOVE.B	#minus,(A2)+	* add '-' to buffer
	MOVE.B	#opp,(A2)+		* add '(' to buffer
	MOVE.B	#$41,(A2)+		* add 'A' to buffer
	MOVE.B	D3,(A2)+		* copy register number to buffer
	MOVE.B	#clp,(A2)		* add ')' to buffer
	JMP	genEA_done		* jump to end of subroutine
mode_aninx	MOVE.B	#opp,(A2)+		* add '(' to buffer
	MOVE.B	#hex,(A2)+		* add '$' to buffer
	MOVE.L	#next_patt,(A2)+	* add word to buffer
	MOVE.B	#comma,(A2)+	* add ',' to buffer
	MOVE.B	#$41,(A2)+		* add 'A' to buffer
	MOVE.B	D3,(A2)+		* copy register number of buffer
	MOVE.B	#clp,(A2)+		* add ')' to buffer	
	JMP	genEA_done		* jump to end of subroutine
mode_svn	JSR	submodesvn		* subroutine 'submodesvn'	
genEA_done	RTS
*-------------------------------------------------------------------------------
* Subroutine: submodesvn
* Description:
* D2 contains six bits for ea (mode / register)
*
* API:	A2 - pointer to good_buffer
*	D3 - register value (decimal) / stores word read from memory
*	D7 - temp storage for word stored in D0      
*-------------------------------------------------------------------------------
submodesvn	MOVE.W	D0,D7		* copy word to D7
	CMP.B	#reg0,D3		* compare D3 to 000
	BEq	reg_long		* branch if register is 000
	CMP.B	#reg1,D3		* compare D3 to 001
	BEq	reg_word		* branch if register is 001
	CMP.B	#reg4,D3		* compare D3 to 100
	BEq	reg_four		* branch if register is 100
	MOVE.B	#bad,(A6)		* set bad flag
	JMP	sms_done		* jump to end
reg_long	MOVE.B	#hex,(A2)+		* add $ to buffer
	MOVE.W	(A4)+,D3		* copy word from memory to register
	MOVE.W	D3,D0		* copy word to D0
	ANDI.L	#mask_byte3,D0	* isolate byte 2
	ROR.L	#8,D0		* shift to LSB position
	*JSR	hexToA		* convert byte to ascii
	MOVE.W	D3,D0		* copy word to D0
	ANDI.L	#mask_byte4,D0	* isolate byte 1
	*JSR	hexToA		* convert byte to ascii
	MOVE.L	#empty,D3		* clear register
	MOVE.L	#empty,D0		* clear register
	JMP	sms_next		* jump to next word
reg_word	MOVE.B	#hex,(A2)+		* add $ to buffer
sms_next	MOVE.W	(A4)+,D3		* copy word from memory to register
	MOVE.W	D3,D0		* copy word to D0
	ANDI.L	#mask_byte3,D0	* isolate byte 2
	ROR.L	#8,D0		* shift to LSB position
	*JSR	hexToA		* convert byte to ascii
	MOVE.W	D3,D0		* copy word to D0
	ANDI.L	#mask_byte4,D0	* isolate byte 1
	*JSR	hexToA		* convert byte to ascii
	MOVE.L	#empty,D3		* clear register
	MOVE.L	#empty,D0		* clear register
	JMP	sms_done		* jump to end
reg_four	* not sure what to do            
sms_done	RTS
*-------------------------------------------------------------------------------
* Subroutine: appends
* Description: Used to append either an 'L', 'W', or 'B' to the print buffer
* API: A2
*      D3 - 
*-------------------------------------------------------------------------------
appends	CMP.B	#$0,D3
	BEQ	isbyte
	CMP.B	#$1,D3
	BEQ	isword
	CMP.B	#$2,D3
	BEQ	islong
islong	MOVE.B	#$4C,(A2)+	* move ASCII value for 'L' to buffer
	BRA	app_done
isbyte	MOVE.B	#$42,(A2)+	* move ASCII value for 'B' to buffer
	BRA	app_done
isword	MOVE.B	#$57,(A2)+  * move ASCII value for 'W' to buffer
app_done	RTS		* get out of subroutine
*-------------------------------------------------------------------------------
* Subroutine: isValid
* Description: Will validate a user inputted addresses
* API: A0 - used internally to store address being tested
*      A1 - used internally for Trap statement (pointer to error)
*      D0 - used internally for Trap statement (display error)
*      D1 - used internally for Trap statement (error length)
*      D7 - used as a flag ($00000000 == good ; !0 == bad
*-------------------------------------------------------------------------------
isValid	NOP
	MOVEA.L	D7,A0		* copy address to register A0
	CMP.L	#start_bnds,A0	* compare starting address to lower bounds
	BGE	check_2		* branch to 'check_2' if valid
	MOVE.B	#tsk1,D0		* load task
	LEA	error1,A1		* get address of string
	MOVE.W	#e_len1,D1		* get length of string
	TRAP	#15		* display error
	JMP	set_bad		* jump to 'set_bad'
check_2	CMPA.L 	#end_bnds,A0	* compare ending address to upperbounds
	BLT	set_good		* branch to next 'set_good' if valid
	MOVE.B	#tsk1,D0		* load task
	LEA	error2,A1		* get address of string
	MOVE.W	#e_len2,D1		* get length of string
	TRAP	#15		* display error
	JMP	set_bad		* jump to 'set_bad'
set_good	MOVE.L	#empty,D7		* clear register / set flag
set_bad	RTS			* return to program main	
*-------------------------------------------------------------------------------
* Subroutine: convert
* Description: Will convert the ascii pattern found at the storage
*              pointed to by A3 to hex digits. Conversion is done
*              on a character by character basis.
*              Initialization of registers occurs before subroutine.
*              Because of this, no need to push any registers to the
*              stack.
*              NOTE: there is no error checking in this subroutine as
*              per assignment parameters.
* API: A3 - starting address of storage with user input
*      D1 - length of user input
*      D6 - storage for each ascii code read
*      D7 - storage for converted characters
*-------------------------------------------------------------------------------
convert	MOVE.B	#reset,counter	* reset counter to zero
lloop	CMP.B	counter,D1		* compare counter to length
	BLE	cnvt_done		* ascii translated?			
	MOVE.B	(A3)+,D6		* load data register
	CMP.B	#l_key,D6		* compare key to data	
	BLE	uloop		* branch to lowercase?
	ASL.L	#shift,D7		* need to know how to shift correctly
	SUBI.B	#l_key,D6		* subtract l_key value
	OR.B	D6,D7		* isolate bits and combine
	ADDQ.B	#increment,counter	* increment counter
	JMP	lloop		* jump to 'lloop'
	
uloop	CMP.B	#$40,D6		* is number?
	BLE	nloop		* branch to nloop
	ASL.L	#shift,D7		* need to know how to shift correctly
	SUBI.B	#u_key,D6		* subtract u_key value
	OR.B	D6,D7		* isolate bits and combine
	ADDQ.B	#increment,counter	* increment counter
	JMP	lloop		* jump to 'lloop'

nloop	ASL.L	#shift,D7		* need to know how to shift correctly	
	SUBI.B	#n_key,D6		* subtract n_key value
	OR.B	D6,D7		* isolate bits and combine
	ADDQ.B	#increment,counter	* increment counter
	JMP	lloop		* jump to 'lloop'

cnvt_done	AND.L	#mask_even,D7	* make address even if odd
	RTS			* return to program main	
*-------------------------------------------------------------------------------
* Subroutine: hexToA
* Description: Will convert the bad address location, the pattern
*	   written, and the pattern read from hex values to
*	   ascii values.  This has to be done in order to
*	   print out this information to screen.  The ascii
*	   values are stored in a print buffer which is pointed
*	   to by A4.
* API: A2 - points to good_buffer
*      A3 - byte currently being converted
*      A4 - points to print buffer, places converted ASCII into buffer
*      D4 - holds current byte being converted
*      D6 - holds left nibble of byte being converted
*      D5 - holds right nibble of byte being converted
*-------------------------------------------------------------------------------
hexToA	MOVE.B	(A3)+,D4		* move byte to convert to D4
	CMP.B	#0,counter		* see if counter is 0
	BEQ	getout		* done converting, exit sub routine
	SUBQ.B	#1,counter		* subtract 1 from counter
		
	MOVE.L	#mask_left,D6	* mask used to isolate left nibble 	
	MOVE.L	#mask_right,D5	* mask used to isolate right nibble
	AND.L	D4,D6		* logical AND of left nibble w/ mask
	LSR.L	#shift,D6		* shift to the right once
	CMP.B	#$0A,D6		* value being converted is a number?
	BGE	letr_conv		* no, it's a letter, branch
	ADDI.B	#$30,D6		* yes, it's a number, add 30 to get ASCII
	MOVE.B	D6,(A2)+		* push into print buffer
	
r_nib	AND.L	D4,D5		* logical AND of right nibble w/ mask		
	CMP.B	#$0A,D5		* value being converted is a number?
	BGE	letr_conv2		* no, it's a letter, branch
	ADDI.B	#$30,D5		* yes, it's a number, add 30 to get ASCII
	MOVE.B	D5,(A2)+		* push into print buffer
	BRA	hexToA		* loop to continue converting
	
letr_conv	ADDI.B	#$37,D6		* add 37 to get ASCII value
	MOVE.B	D6,(A2)+		* push into print buffer
	BRA	r_nib		* branch to convert right nibble
	
letr_conv2	ADDI.B	#$37,D5		* add 37 to get ASCII value
	MOVE.B	D5,(A2)+		* push right nibble to print buffer
	BRA	hexToA		* loop to continue converting
	
getout	RTS			* exit from this subroutine
*-------------------------------------------------------------------------------
* Subroutine: bin_to_dec
* Description:
* API: D2 - 
*      D3 - 
* subroutine bin_to_dec - used to convert binary to decimal
*-------------------------------------------------------------------------------
bin_to_dec	CMP.W	(A0)+,D2
	BEQ	btd_done
	ADDQ.W	#1,D3
	BRA	bin_to_dec
btd_done	RTS
*-------------------------------------------------------------------------------
* Subroutine:  lea_reg
* Description: Will isolate bits 9 - 11 to determine which register is will be
*              loaded with the effective address.  Note: If result is 7 (111),
*              SP, not An will be written to the buffer.
* API:	A2 - pointer to good buffer
*	D2 - Binary pattern for word
*-------------------------------------------------------------------------------
lea_reg	ANDI.L	#b911_mask,D2	* isolate bits 9 - 11 (register number)
	LSR.L	#8,D2		* shift bits
	LSR.L	#1,D2		* shift one more
	CMPI.B	#7,D2		* check if equal to seven
	BEq	sp_size		* branch to "sp_size" label
	ADDI.B	#$30,D2		* change to ascii value
	MOVE.B	D2,(A2)+		* copy ascii value to buffer
sp_size	MOVE.L	#$53,(A2)+		* add S to buffer
	MOVE.L	#$50,(A2)+		* add P to buffer
lr_done	RTS			* return from subroutine
*-------------------------------------------------------------------------------
* Subroutine: movemsr
* Description: MOVEM Subroutine
*              This is a "helper" subroutine for MOVEM to generate the register
*              list and the order in which it's printed to the screen.
*              
* API:	A0 - used internally as pointer to string storage
*	A2 - pointer to 'good' buffer
*	D2 - holds binary world value
*-------------------------------------------------------------------------------
movemsr	ANDI.L	#movm_mask,D2	* isolate bit 10
	LSR.L	#8,D2		* shift bit
	LSR.L	#2,D2		* shift more
	CMPI.B	#0,D2		* check if register to memory
	BEq	reg2mem		* branch to label
	JMP	mem2reg		* branch to label
reg2mem	* code here
	JMP	mmsr_done		* jump to end
mem2reg	* code here	
mmsr_done	RTS
*-------------------------------------------------------------------------------
* Subroutine:  getSize
* Description: Will isolate bits 6 and 7 to determine the size of the op code
*              operation.
*	   00 - Byte
*              01 - Word
*              10 - Long
*              11 - error (set bad flag)
* API:	A2 - pointer to good buffer
*	D2 - binary pattern for word
*-------------------------------------------------------------------------------
getSize	MOVE.L	(A1),D2		* restore bits from storage
	ANDI.L	#size_mask,D2	* isolate size bits
	LSR.L	#6,D2		* shift bits
	CMPI.B	#0,D2		* check if equal to zero (byte)
	BEq	gs_b		* branch to byte
	CMPI.B	#1,D2		* check if equal to one (word)
	BEq	gs_w		* branch to word
	CMPI.B	#2,D2		* check if equal to two (long)
	BEq	gs_l		* branch to long
	MOVE.B	#bad,(A6)		* set bad flag
	JMP	prnttoscrn		* jump to printer
gs_b	MOVE.B	#byte,(A2)+		* add B to buffer
	JMP	gs_done		* jump to effective addressing
gs_w	MOVE.B	#word,(A2)+		* add W to buffe
	JMP	gs_done		* jump to effective addressing
gs_l	MOVE.B	#long,(A2)+		* add L to buffer
gs_done	MOVE.B	#space,(A2)+	* add space to buffer
	MOVE.B	#space,(A2)+	* add space to buffer
	RTS			* return from subroutine
*-------------------------------------------------------------------------------
* Subroutine:  setBuffers
* Description: Will clear buffers by filling buffers with spaces (in ascii).
*              Then will initialize buffers with the following:
*              GOOD_BUFFER
*              xxxxxxxx_(x represents address)
*              BAD_BUFFER
*              xxxxxxxx_DATA_$wwww_$0D,$0A
*
*              At the end of the subroutine, A1 will point to good_buffer, A2 and
*              A3 will be cleared as well as the counter
* API:	A0 - pointer to storage
*	A1 - pointer to the good buffer
*           A2 - pointer to the bad buffer
*	A3 - pointer to counter
*	A4 - current address
*	D0 - copy of current address
*-------------------------------------------------------------------------------
setBuffers	LEA	good_buffer,A1	* load register with good buffer
	LEA	bad_buffer,A2	* load register with bad buffer
	LEA	counter,A3		* load register with counter
sb_clr	CMPI.B	#80,counter		* check if counter is 80
	BGE	sb_next		* branch to next stage
	MOVE.B	#space,(A1)+	* write space to buffer
	MOVE.B	#space,(A2)+	* write space to buffer
	ADDI.B	#increment,(A3)	* increment counter
	JMP	sb_clr		* goto top of loop
sb_next	MOVE.B	#reset,(A3)		* clear counter
	LEA	good_buffer,A2	* reload good_buffer
	MOVE.L	A4,D0		* copy address to data register
byte_4	ANDI.L	#mask_byte1,D0	* isolate byte four
	ROL.L	#8,D0		* shift to LSB position
	*JSR	hexToA		* convert byte and copy to buffer
byte_3	MOVE.L	A0,D0		* restore address copy
	ANDI.L	#mask_byte2,D0	* isolate byte three
	ROL.L	#8,D0		* shift toward LSB position
	ROL.L	#8,D0		* shift again
	*JSR	hexToA		* convert byte and copy to buffer
byte_2	MOVE.L	A0,D0		* restore address copy
	ANDI.L	#mask_byte3,D0	* isolate byte two
	ROR.L	#8,D0		* shift to LSB position
	*JSR	hexToA		* convert byte and copy to buffer
byte_1	MOVE.L	A0,D0		* restore address copy
	ANDI.L	#mask_byte4,D0	* isolate byte one
	*JSR	hexToA		* convert byte and copy to buffer
	LEA	good_buffer,A2	* reload good_buffer
	LEA	bad_buffer,A3	* reload bad_buffer
	MOVE.L	(A2)+,(A3)+		* copy first "word" from good_buffer
	MOVE.L	(A2),(A3)		* copy second "word" from good_buffer
	MOVE.B	#space,(A2)		* add space to good_buffer
	MOVE.B	#sub,(A2)+		* add substitution to good_buffer
switch	LEA	bad_buffer,A2	* load register with bad_buffer
	MOVE.B	#space,(A2)+	* add space to bad_buffer
	MOVE.B	#sub,(A2)+		* add substitution to bad_buffer
	LEA	move_stor,A0	* load storage
	ADDA.L	#4,A0		* add displacement value to address
	MOVE.L	(A0),(A2)		* copy long from storage to buffer
	MOVE.B	#space,(A2)+	* add space to buffer
	MOVE.B	#hex,(A2)+		* add $ to buffer
	RTS			* return to program main
*-------------------------------------------------------------------------------
* Subroutine: clearRegs
* Description: Will zero the following registers: A0-A3,A6 / D0-D7
*              Registers A4 and A5 are skipped because they contain the address
*              boundries entered by the user.
* API: None
*-------------------------------------------------------------------------------	
clearReg	MOVE.L	#empty,D0		* clear register
	MOVE.L	#empty,D1		* clear register
	MOVE.L	#empty,D2		* clear register
	MOVE.L	#empty,D3		* clear register
	MOVE.L	#empty,D4		* clear register
	MOVE.L	#empty,D5		* clear register
	MOVE.L	#empty,D6		* clear register
	MOVE.L	#empty,D7		* clear register
	MOVE.L	#empty,A0		* clear register
	MOVE.L	#empty,A1		* clear register
	MOVE.L	#empty,A2		* clear register
	MOVE.L	#empty,A3		* clear register
	MOVE.L	#empty,A6		* clear register
	RTS			* return to program main
*-------------------------------------------------------------------------------
* Subroutine: display
* Description: Will display information header for program and will display box
*              with criteria for valid addresses.
* API: A1 - used internally for Trap statement (pointer to notes)
*      D0 - used internally for Trap statement (display note)
*      D1 - used internally for Trap statement (note length)
*-------------------------------------------------------------------------------
display	MOVE.B	#tsk0,D0		* load task
head1	LEA	header1,A1		* address of string
	MOVE.W	head_len1,D1	* length of string
	TRAP	#15		* display first
head2	LEA	header2,A1		* address of string
	MOVE.W	head_len2,D1	* length of string
	TRAP	#15		* display second
head3	LEA	header3,A1		* address of string
	MOVE.W	head_len3,D1	* length of string
	TRAP	#15		* display third
head4	LEA	header4,A1		* address of string
	MOVE.W	head_len4,D1	* length of string
	TRAP	#15		* display fourth
head5	LEA	header5,A1		* address of string
	MOVE.W	head_len5,D1	* length of string
	TRAP	#15		* display fifth
head6	LEA	header6,A1		* address of string
	MOVE.W	head_len6,D1	* length of string
	TRAP	#15		* display sixth	
	
valid1	LEA	v_msg1,A1		* address of string
	MOVE.W	v_len1,D1		* length of string
	TRAP	#15		* display first
valid2	LEA	v_msg2,A1		* address of string
	MOVE.W	v_len2,D1		* length of string
	TRAP	#15		* display second
valid3	LEA	v_msg3,A1		* address of string
	MOVE.W	v_len3,D1		* length of string
	TRAP	#15		* display third
valid4	LEA	v_msg4,A1		* address of string
	MOVE.W	v_len4,D1		* length of string
	TRAP	#15		* display fourth
	RTS			* return to program main
*-------------------------------------------------------------------------------
* 	DATA AREA
*-------------------------------------------------------------------------------
s_addr	DS.L	2		* stores starting address
e_addr	DS.L	2		* stores ending address
counter	DC.B	0		* counter for loops
flag	DC.B	0		* program state (GOOD == 00 / BAD = FF)

bin_pattern	DC.W	$0000,$0001,$0010,$0011,$0100,$0101,$0110,$0111,$1000,$1001,$1010,$1011,$1100,$1101,$1110,$1111
bin_storage	DS.W	16		* storage for binary

* buffer elements
math_stor	DC.B	'ADD.','ADDA','ADDI','SUB.','SUBA','SUBI'
immi_stor	DC.B	'ANDI','CMPI','EORI','ORI.'
lgic_stor	DC.B	'AND.','OR.',$1A,'EXG',$20
mani_stor	DC.B	'ASL.','ASR.','LSL.','LSR.','ROL.','ROR.'
comp_stor	DC.B	'CMP.','CMPA','EOR.'
brch_stor	DC.B	'BRA',$20,'BEq',$20,'BNE',$20,'BGT',$20,'BGE',$20,'BLT',$20,'BLE',$20
move_stor	DC.B	'MOVE','DATA'
spec_stor	DC.B	'CLR.','JSR',$20,'JMP',$20,'LEA',$20,'NEG',$20,'NOP',$1A,'NOT.','RTS',$1A,'SWAP'

* display message buffers
good_buffer	DS.B	80			* good buffer
gb_size	DC.W	gb_size-good_buffer		* size of good buffer
bad_buffer	DS.B	80			* bad buffer
bb_size	DC.W	bb_size-bad_buffer		* size of bad buffer

* header strings
header1	DC.B	'****************************************************************************'
head_len1	DC.W	head_len1-header1
header2	DC.B	'* CSS 422 - Spring 2010   |   Motorola 68K Disassembler (ver x.x)          *'
head_len2	DC.W	head_len2-header2
header3	DC.B	'* - Aaron Parks                                                            *'
head_len3	DC.W	head_len3-header3
header4	DC.B	'* - Neal Natsheh                                                           *'
head_len4	DC.W	head_len4-header4
header5	DC.B	'* - Mark Shipman                                                           *'
head_len5	DC.W	head_len5-header5
header6	DC.B	'****************************************************************************',$0A
head_len6	DC.W	head_len6-header6

* reminder messages
v_msg1	DC.B	' Notes about valid addresses: '
v_len1	DC.W	v_len1-v_msg1
v_msg2	DC.B	'-> Input too short will be appended with zeros'
v_len2	DC.W	v_len2-v_msg2
v_msg3	DC.B	'-> Only the last eight charcters of input will be used'
v_len3	DC.W	v_len3-v_msg3
v_msg4	DC.B	'-> Any odd address will be converted to even',$0A
v_len4	DC.W	v_len4-v_msg4

* user prompts
prompt1	DC.B	'Enter starting address (greater than $00001000): '
p_len1	DC.W	p_len1-prompt1		
prompt2	DC.B	'Enter ending address (less than $000FFFFF): '
p_len2	DC.W	p_len2-prompt2				

* error messages
error1	DC.B	'   Error: Address must be greater than $00001000',$0A,$0D
e_len1	DC.W	e_len1-error1
error2	DC.B	'   Error: Address must be less than $000FFFFF',$0D,$0A
e_len2	DC.W	e_len2-error2
error3	DC.B	'   Error: Address range too small',$0D,$0A
e_len3	DC.W	e_len3-error3
error4	DC.B	'   Error: Ending address must be at least one word greater than starting address',$0D,$0A
e_len4	DC.W	e_len4-error4

s_a_l	DC.B	0			* Starting Address Length
e_a_l	DC.B	0			* Ending Address Length

	END	$1000










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~12~
