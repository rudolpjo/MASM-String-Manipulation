TITLE Program 6a     (Program6.asm)

; Author: John Rudolph
; Last Modified: 8 December 2019
; OSU email address: rudolpjo@oregonstate.edu
; Course number/section: CS 271- 400
; Project Number:   6              Due Date: 8 December 2019
; Description: Program gets 10 integers from user formatted as strings. Then converts strings to integers, calculates 
; sum and average. Then converts integers back to strings. Displays as strings all inputted numbers, sum, and average.

INCLUDE Irvine32.inc

;constants

;max length of string to be entered
MAX			EQU		30

;number of integers to get from user
inputNum	EQU		10

;Macro to get string from user. Stores input data at memory location designated
getString	 MACRO	 input, promt ;parameters must be passed in as OFFSET
	push	ecx
	push	edx
	mov		edx, promt
	call	WriteString
	mov		edx, input
	mov		ecx, MAX-1
	call	ReadString
	pop		edx
	pop		ecx
ENDM

;Macro to display string
displayString	MACRO	display ;parameter must be OFFSET of string to be displayed
	push	edx
	mov		edx, display
	call	WriteString
	pop		edx
ENDM


.data

	intro1		BYTE	"Demostrating low-level I/O procedures", 0
	intro2		BYTE	"Written by: John Rudolph", 0
	
	promt1		BYTE	"Please provide 10 decimal integers", 0
	promt2		BYTE	"Each number needs to small enough to fit inside a 32 bit register", 0
	promt3		BYTE	"After you have finished, I will display a list of the integers, their sum, and their average value", 0
	promt4		BYTE	"Please enter an integer number: ", 0
	promt5		BYTE	"You entered the following numbers: ", 0
	promt6		BYTE	"The sum of your numbers is: ", 0
	promt7		BYTE	"The average is: ", 0
	comma		BYTE	", ", 0
	
	error1		BYTE	"ERROR: You did not enter an integer, or it was too big.", 0
	error2		BYTE	"Please try again.", 0

	farewell	BYTE	"Thank you for using my program, goodbye!", 0
	
	userInput	BYTE	MAX DUP(?)
	outputStr	BYTE	MAX DUP(?)
	temp		BYTE	MAX DUP(?)
	inputArr	DWORD	inputNum DUP(?)
	tempNum		DWORD	0
	sum			DWORD	?
	ave			DWORD	?
	

.code
main PROC
	
	push	OFFSET intro1
	push	OFFSET intro2
	push	OFFSET promt1
	push	OFFSET promt2
	push	OFFSET promt3
	call	Welcome

	
	push	OFFSET inputArr
	push	tempNum
	push	OFFSET userInput
	call	ReadVal


	push	OFFSET inputArr
	push	OFFSET sum
	call	FindSum

	push	OFFSET ave
	push	sum
	call	FindAve

	call	CrLf
		
;Show numbers entered
	displayString OFFSET promt5
	mov		edi, OFFSET inputArr
	mov		ecx, inputNum

;iterate through array of input integers
;converts each integers to string and displays using WriteVal
LoopTop:
	push	ecx
	mov		eax, [edi]
	add		edi, 4
	PUSHAD
	push	OFFSET outputStr
	push	OFFSET temp
	push	eax
	call	WriteVal
	displayString OFFSET comma
	
	POPAD
	loop	LoopTop
	
	call	CrLf


;Show the sum of numbers entered
	displayString	OFFSET promt6
	push	OFFSET outputStr
	push	OFFSET temp
	push	sum
	call	WriteVal

	call	CrLf


;Show the average of numbers entered
	displayString	OFFSET promt7
	push	OFFSET outputStr
	push	OFFSET temp
	push	ave
	call	WriteVal

	call	CrLf
	displayString OFFSET farewell


	exit	; exit to operating system
main ENDP

;Procedure to welcome user
;Receives: intoduction strings pushed onto stack
;returns: none
;preconditions: location of string pushed onto stack
;registers changed: ebp, esp
Welcome PROC	
	push	ebp
	mov		ebp, esp
	displayString [ebp+24]
	call	CrLf
	displayString  [ebp+20]
	call	CrLf
	displayString [ebp+16]
	call	CrLf
	displayString [ebp+12]
	call	CrLf
	displayString [ebp+8]
	call	CrLf

	pop		ebp
	ret		20
Welcome ENDP


;Procedure to get and validate input from user
;Receives: location of string memory, [ebp+8]
;returns: 
;preconditions: location of string pushed onto stack
;registers changed: ebp, esp, eax, ecx
ReadVal PROC
	push	ebp
	mov		ebp, esp

	mov		edi, [ebp+16]	;set edi to address of inputArr
	mov		ecx, inputNum

FillArray:
	push ecx

Start:
	mov		eax, 0			;reset tempNum to 0
	mov		[ebp+12], eax
	getString [ebp+8], OFFSET promt4
	
	INVOKE	str_length, [ebp+8]		;get length of string entered by user
	cmp		eax, 9					;cap input to 9 digits to prevent overflow in sum
	jg		error
	mov		ecx, eax				;move that length into ecx, setting up loop counter
	mov		esi, [ebp+8]
	mov		ebx, 10
	cld

LoopTop:
	lodsb
	cmp		al, 48		;compare digit to ascii code for 0
	jl		Error		;jump to error if below
	cmp		al, 57		;compare digit to ascii code for 9
	jg		Error		;jump to error if above 

	sub		eax, 30h
	push	eax				;store eax value, integer value of string bit	
	mov		eax, [ebp+12]	;mov 'tempNum' into eax
	mul		ebx				;multiply 'tempNum' by 10
	mov		[ebp+12], eax
	pop		eax
	add		[ebp+12], eax

	loop	LoopTop
	jmp		finish

Error:
	displayString	OFFSET error1
	call			CrLf
	displayString	OFFSET error2
	call			CrLf
	jmp		start


finish:	 
	mov		eax, [ebp+12]
	mov		[edi], eax		;place integer into array	
	add		edi, 4			
	pop		ecx				;jump is too big for loop instruction
	dec		ecx
	cmp		ecx, 0
	jne		FillArray		;loop through according to const 'inputNum'

	pop		ebp	
	ret		12
ReadVal ENDP


;Procedure to calculate sum of integers in array 
;Receives: location of array in memory, location for sum to be stored 
;returns: sum
;preconditions: location of array pushed onto stack, location of sum on stack
;registers changed: ebp, esp, edi, eax, ebx, ecx
FindSum PROC
	push	ebp
	mov		ebp, esp

	mov		edi, [ebp+12]	;move address of array of input integers into edi
	mov		eax, 0	
	mov		ecx, inputNum	;set loop counter to size of array

loopTop:
	add		eax, [edi]
	;call	WriteInt
	;call	CrLf
	add		edi, 4
	loop	loopTop	

	mov		ebx, [ebp+8]
	mov		[ebx], eax
	pop		ebp
	ret		8
FindSum ENDP

;Procedure to calculate average of integers in array 
;Receives: value stored in sum, location for average to be stored 
;returns: average
;preconditions: value of sum on stack, location of average on stack
;registers changed: ebp, esp, eax, ebx, edx
FindAve PROC
	push	ebp
	mov		ebp, esp

	mov		edx, 0
	mov		eax, [ebp+8] ;mov sum into eax
	mov		ebx, inputNum

	div		ebx

	mov		ebx, [ebp+12]
	mov		[ebx], eax

	pop		ebp
	ret		8
FindAve ENDP



;Procedure to convert integer to string, writes string to console using 'displayString' macro
;Receives: integer to convert, temp string, output string
;returns: string format of integer input
;preconditions: location of temp string and ouput string pushed onto stack, value of integer on stack
;registers changed: ebp, esp, edi, eax, ebx, ecx, edx
WriteVal PROC
	push	ebp
	mov		ebp, esp

	mov		eax, [ebp+16]
	mov		ebx, 0
	mov		[eax], ebx
	
	mov		eax, [ebp+12]
	mov		ebx, 0
	mov		[eax], ebx

	mov		ecx, 0
	mov		edx, 0
	mov		ebx, 10
	mov		eax, [ebp+8]

numDigits:
	div		ebx
	inc		ecx
	mov		edx, 0
	cmp		eax, 0	
	jg		numDigits
	
	mov		edi, [ebp+12]	;set target to temp
	mov		eax, [ebp+8]	;value to be stored
	mov		edx, 0

LoopTop:
	div		ebx
	push	eax
	mov		eax, edx
	add		eax, 30h
	cld
	stosb
	pop		eax
	mov		edx, 0
	loop	LoopTop
	
;reverse the string
	INVOKE	str_length,[ebp+12]
	mov		ecx, eax
	mov		esi, [ebp+12]
	add		esi, ecx
	dec		esi
	mov		edi, [ebp+16]
	
reverse:
	std
	lodsb
	cld
	stosb
	loop	reverse

	displayString [ebp+16]

	pop		ebp
	ret		12
WriteVal ENDP


END main
