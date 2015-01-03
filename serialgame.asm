	.org    0x0000
	ajmp    start_main

    .org    50h
NUM_2048:
    .DB "   2"
    .DB 00H
    .DB "   4"  ;5
    .DB 00H
    .DB "   8"  ;10
    .DB 00H
    .DB "  16"  ;15
    .DB 00H
    .DB "  32"  ;20
    .DB 00H
    .DB "  64"  ;25
    .DB 00H
    .DB " 128"  ;30
    .DB 00H
    .DB " 256"  ;35
    .DB 00H
    .DB " 512"  ;40
    .DB 00H
    .DB "1024"  ;45
    .DB 00H
    .DB "2048"  ;50
    .DB 00H
    .DB "4096"  ;55
    .DB 00H

; serial bus interrupt service routine (echos characters)
	.org    23h
	
	JNB RI, ISR_end 	; source is incoming? if not go directly to end
	clr	RI				; clear RI.
	mov	A, SBUF			;get char in buffer.
	;acall _TX_CHAR		;send character
    acall DETECT_ARROW
ISR_end:
	reti

	.org    100h
start_main:
; prepare the serial bus
	mov	SCON, #0x50	;Serial port work in mode 1, enable receive
	mov	TMOD, #0x20	;timer 1 work in mode 2
	mov	TH1, #255	;timer 1 reload value = 255
	setb	TR1		;start timer 1
	setb	TI		;send flag TI

    mov IE, #0x90	;enable serial interrupt
	mov A,#10       ; demo for positioning the cursor
	mov B,#10
	acall _CSI_POS
 
    mov A, #31              ; 30-39 set color 
    acall _CSI_M

    init:
    mov A,#30
    mov DPL,A
    mov DPH,#0
    mov A,#0   
    movx @DPTR,A

    mov A,#31
    mov DPL,A
    mov DPH,#0
    mov A,#0   
    movx @DPTR,A

    mov A,#32
    mov DPL,A
    mov DPH,#0
    mov A,#0
    movx @DPTR,A

    mov A,#33
    mov DPL,A
    mov DPH,#0
    mov A,#0 
    movx @DPTR,A

    mov A,#34
    mov DPL,A
    mov DPH,#0
    mov A,#3   
    movx @DPTR,A

    mov A,#35
    mov DPL,A
    mov DPH,#0
    mov A,#6   
    movx @DPTR,A

    mov A,#36
    mov DPL,A
    mov DPH,#0
    mov A,#0   
    movx @DPTR,A

    mov A,#37
    mov DPL,A
    mov DPH,#0
    mov A,#0  
    movx @DPTR,A

    mov A,#38
    mov DPL,A
    mov DPH,#0
    mov A,#0   
    movx @DPTR,A

    mov A,#39
    mov DPL,A
    mov DPH,#0
    mov A,#0
    movx @DPTR,A

    mov A,#3Ah
    mov DPL,A
    mov DPH,#0
    mov A,#0   
    movx @DPTR,A

    mov A,#3Bh
    mov DPL,A
    mov DPH,#0
    mov A,#0  
    movx @DPTR,A

    mov A,#3Ch
    mov DPL,A
    mov DPH,#0
    mov A,#0   
    movx @DPTR,A

    mov A,#3Dh
    mov DPL,A
    mov DPH,#0
    mov A,#0
    movx @DPTR,A

    mov A,#3Eh
    mov DPL,A
    mov DPH,#0
    mov A,#0   
    movx @DPTR,A

    mov A,#3Fh
    mov DPL,A
    mov DPH,#0
    mov A,#0   
    movx @DPTR,A


    ;acall DISPLAY
  	;mov   	dptr, #NUM_2048    ; send string 
	;acall   _TX_STR

; prepare the LED output
	mov	A, #20
	acall	_DELAY

	mov	DPTR, #0xA003
	mov	A, #0x82
	movx	@DPTR, A	;init 82C55 (port A output,port B input)

	mov	DPTR, #0xA000
	mov	A, #0x1
	movx	@DPTR, A

; inside the main threat we let the LED light move
loop_end:
	mov	A, #1
	acall	_DELAY

	mov	DPTR, #0xA000
	movx	A, @DPTR
	rl	A
   	movx	@DPTR, A

	ajmp loop_end

; sends m command
; expects the argument to be in acc
_CSI_M:                 
	push ACC
	acall _TX_CSI
    pop ACC
	acall _SEND_DEZ_NUM
	mov A,#'m'
	acall _TX_CHAR
   	ret

 ; positions the cursor on a position indicated by the A and B registers
_CSI_POS:                    
    push B
	push ACC
	acall _TX_CSI
	pop ACC
	acall _SEND_DEZ_NUM
	mov A,#0x3b    ;  ';'
	acall _TX_CHAR
	pop ACC
	acall _SEND_DEZ_NUM
	mov A,#'H'
	acall _TX_CHAR
	ret

; write a decimal number between 0-99 as ASCII over the serial bus
_SEND_DEZ_NUM:
	mov B, #10              ; separate higher digit from lower digit
	div AB
    mov dptr, #NUMBER_STR
	movc A, @dptr+A
	acall _TX_CHAR    
	mov A,B
	movc A, @dptr+A
	acall _TX_CHAR
	ret

; send a constant string over the serial bus, the starting pointer has to be stored in the dptr register
_TX_STR:
   	mov 	R4, #0
loop_str:
	mov	A,R4
	movc	A, @A+DPTR	
	inc R4
    jz 	str_end
	acall _TX_CHAR
	ajmp loop_str
str_end:
	ret

; send the content of the ACC as character over the serial bus...
_TX_CHAR:
	jnb	TI,_TX_CHAR	;if TI = 0,wait for send finish.
	clr	TI			;clear TI.
	mov	SBUF, A		;send char	
	ret

;receive a character
_RX_CHAR: 
	JNB	RI,_RX_CHAR	;if RI = 0,wait for receive to finish..
	clr	RI			;clear RI.
	mov	A, SBUF		;get char in buffer.
	ret

; send the beginning of a ANSI escape sequence (ESC+[) 
_TX_CSI:
	mov A, #0x1b
	acall _TX_CHAR
	mov A, #'['
	acall _TX_CHAR
    ret
; text strings

PUSH_UP:
    ; 30
    mov DPL,#30
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_31
    ;check 34
    mov DPL,#34
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_31

        mov DPL,#30
        mov DPH,#0
        movx @DPTR,A    ;34 -> 30
        mov DPL,#34h
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 34

UP_CHECK_31:
    ; 31
    mov DPL,#31
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_32
    ;check 35
    mov DPL,#35
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_32

        mov DPL,#31
        mov DPH,#0
        movx @DPTR,A    ;35 -> 31
        mov DPL,#35h
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 35

UP_CHECK_32:
    ; 32
    mov DPL,#32
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_33
    ;check 36
    mov DPL,#36
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_33

        mov DPL,#32
        mov DPH,#0
        movx @DPTR,A    ;36 -> 32
        mov DPL,#36h
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 36

UP_CHECK_33:
    ; 33
    mov DPL,#33
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_34
    ;check 37
    mov DPL,#37
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_34

        mov DPL,#33
        mov DPH,#0
        movx @DPTR,A    ;37 -> 33
        mov DPL,#37h
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 37

UP_CHECK_34:
    ; 34
    mov DPL,#34
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_35
    ;check 38
    mov DPL,#38
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_35

        mov DPL,#34
        mov DPH,#0
        movx @DPTR,A    ;38 -> 34
        mov DPL,#38h
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 38

UP_CHECK_35:
    ; 35
    mov DPL,#35
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_36
    ;check 39
    mov DPL,#39
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_36

        mov DPL,#35
        mov DPH,#0
        movx @DPTR,A    ;39 -> 35
        mov DPL,#39h
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 39

UP_CHECK_36:
    ; 36
    mov DPL,#36h
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_37
    ;check 3A
    mov DPL,#3Ah
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_37

        mov DPL,#36h
        mov DPH,#0
        movx @DPTR,A    ;3A -> 36
        mov DPL,#3Ah
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 3A

UP_CHECK_37:
    ; 37
    mov DPL,#37h
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_38
    ;check 3B
    mov DPL,#3Bh
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_38

        mov DPL,#37h
        mov DPH,#0
        movx @DPTR,A    ;3B -> 37
        mov DPL,#3Bh
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 3B

UP_CHECK_38:
    ; 38
    mov DPL,#38h
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_39
    ;check 3C
    mov DPL,#3Ch
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_39

        mov DPL,#38h
        mov DPH,#0
        movx @DPTR,A    ;3C -> 38
        mov DPL,#3Ch
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 3C
        
UP_CHECK_39:
    ; 39
    mov DPL,#39h
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_3A
    ;check 3D
    mov DPL,#3Dh
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_3A

        mov DPL,#39h
        mov DPH,#0
        movx @DPTR,A    ;3D -> 39
        mov DPL,#3Dh
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 3D

UP_CHECK_3A:
    ; 3A
    mov DPL,#3Ah
    mov DPH,#0
    movx A,@DPTR
    jnz UP_CHECK_3B
    ;check 3E
    mov DPL,#3Eh
    mov DPH,#0
    movx A,@DPTR
    jz UP_CHECK_3B

        mov DPL,#3Ah
        mov DPH,#0
        movx @DPTR,A    ;3E -> 3A
        mov DPL,#3Eh
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 3E

UP_CHECK_3B:
    ; 3B
    mov DPL,#3Bh
    mov DPH,#0
    movx A,@DPTR
    jnz PUSH_UP_EXIT
    ;check 3F
    mov DPL,#3Fh
    mov DPH,#0
    movx A,@DPTR
    jz PUSH_UP_EXIT

        mov DPL,#3Bh
        mov DPH,#0
        movx @DPTR,A    ;3F -> 3B
        mov DPL,#3Fh
        mov DPH,#0
        mov A,#0
        movx @DPTR,A    ;clear 3F

PUSH_UP_EXIT:
    ret

MOVE_UP:
    push ACC
    push B
    acall PUSH_UP    ;compact
   
    ;merge
    mov R0,#0x30     
    mov A,#12        ;repeat 12 times

LOOP_UP:
    dec A
    push ACC
    
    ;compare A with A+4
    mov DPL,R0
    mov DPH,#0          ;must clear DPH
    movx A,@DPTR
    JZ PASS_UP          ;if A == 0 then pass
    mov R1,A            ;R1 <-- A

    mov A,DPL
    add A,#4
    mov DPL,A
    mov DPH,#0
    movx A,@DPTR        ;A+4

    CJNE A,01H,PASS_UP  ;not equal ==> jmp
    ; add
    mov DPL,R0
    mov DPH,#0
    movx A,@DPTR
    inc A
	mov DPH,#0
    movx @DPTR,A
    ;clear A+4
    mov A,DPL
    add A,#4
    mov DPL,A
    mov A,#0
    mov DPH,#0
    movx @DPTR,A

PASS_UP:
    ;move to next 
    inc R0

    pop ACC
    jnz LOOP_UP 

;    mov DPL,#0x30
;    mov DPH,#0
;    movx A,@DPTR
;    acall _SEND_DEZ_NUM
;
;    mov DPL,#0x31
;    mov DPH,#0
;    movx A,@DPTR
;    acall _SEND_DEZ_NUM
;
;    mov DPTR,#NUM_2048
;    mov A,#40           ;add 5 at a time
;    add A,DPL
;    mov DPL,A
;    mov DPH,#0
;
;    acall _TX_STR
    acall PUSH_UP
    ;acall IF_DIE 
    pop B
    pop ACC
    ret


DETECT_ARROW:
    push ACC
    anl A,#0x9B		; Down
    jnz NOT_DOWN

    ;mov A,#'D'		;DO SOMETHING
    ;acall _TX_CHAR
    pop ACC
    sjmp DISPLAY 

NOT_DOWN:
    pop ACC
    push ACC
    anl A,#0x8A     ; Up
    jnz NOT_UP

    ;mov A,#'U'
    ;acall _TX_CHAR
    acall MOVE_UP
    pop ACC
    sjmp DISPLAY 

NOT_UP:
    pop ACC
    push ACC
    anl A,#0x93     ; Left
    jnz NOT_LEFT

    mov A,#'L'
    acall _TX_CHAR
    pop ACC
    sjmp DISPLAY 
    
NOT_LEFT:
    pop ACC
    push ACC
    anl A,#0x8D     ; Right
    jnz NOT_RIGHT

    mov A,#'R'
    acall _TX_CHAR
    pop ACC
    sjmp DISPLAY 

NOT_RIGHT:
    pop ACC
    sjmp DISPLAY 

PRINT_NUMBER:

    mov DPL,A
    mov DPH,#0
    movx A, @DPTR
    mov R3,A
    mov A,#0
    push ACC

FIND_TABLE:
    dec R3
    pop ACC
    add A,#5
    push ACC
    mov A,R3

    jnz FIND_TABLE    
    pop ACC
    subb A,#5       ; so we get the offset of NUM_2048 to display

    mov DPTR,#NUM_2048
    add A,DPL
    mov DPL,A
    mov DPH,#0
    acall _TX_STR
    
    ret

DISPLAY:
	push ACC

	; move back cursor
	mov A,#10				; demo for positioning the cursor
	mov B,#10
	acall _CSI_POS
	; prompt
   	mov   	dptr, #STR_2    ; send string 
	acall   _TX_STR

print30:
    mov DPL,#30
    mov DPH,#0
	movx A,@DPTR
	jz printDot30

   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
    mov A,#30
    acall PRINT_NUMBER 
	sjmp print31
printDot30:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print31:
    mov DPL,#31
    mov DPH,#0
	movx A,@DPTR
	jz printDot31
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,#31
    acall PRINT_NUMBER
	sjmp print32
printDot31:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print32:
    mov DPL,#32
    mov DPH,#0
	movx A,@DPTR
	jz printDot32
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,#32
    acall PRINT_NUMBER
	sjmp print33
printDot32:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print33:
    mov DPL,#33
    mov DPH,#0
	movx A,@DPTR
	jz printDot33

   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
    mov A,#33
    acall PRINT_NUMBER
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR
	sjmp print34
printDot33:
   	mov   	dptr, #Dot		; send string 
	acall   _TX_STR
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR

print34:
    mov DPL,#34
    mov DPH,#0
	movx A,@DPTR
	jz printDot34

   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
    mov A,#34
    acall PRINT_NUMBER 
	sjmp print35
printDot34:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print35:
    mov DPL,#35
    mov DPH,#0
	movx A,@DPTR
	jz printDot35
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,#35
    acall PRINT_NUMBER
	sjmp print36
printDot35:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print36:
    mov DPL,#36
    mov DPH,#0
	movx A,@DPTR
	jz printDot36
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,#36
    acall PRINT_NUMBER
	sjmp print37
printDot36:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print37:
    mov DPL,#37
    mov DPH,#0
	movx A,@DPTR
	jz printDot37

   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
    mov A,#37
    acall PRINT_NUMBER
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR
	sjmp print38
printDot37:
   	mov   	dptr, #Dot		; send string 
	acall   _TX_STR
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR

print38:
    mov DPL,#38
    mov DPH,#0
	movx A,@DPTR
	jz printDot38

   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
    mov A,#38
    acall PRINT_NUMBER 
	sjmp print39
printDot38:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print39:
    mov DPL,#39
    mov DPH,#0
	movx A,@DPTR
	jz printDot39
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,#39
    acall PRINT_NUMBER
	sjmp print3A
printDot39:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print3A:
    mov DPL,#3Ah
    mov DPH,#0
	movx A,@DPTR
	jz printDot3A
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,#3Ah
    acall PRINT_NUMBER
	sjmp print3B
printDot3A:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print3B:
    mov DPL,#3Bh
    mov DPH,#0
	movx A,@DPTR
	jz printDot3B

   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
    mov A,#3Bh
    acall PRINT_NUMBER
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR
	sjmp print3C
printDot3B:
   	mov   	dptr, #Dot		; send string 
	acall   _TX_STR
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR

print3C:
    mov DPL,#3Ch
    mov DPH,#0
	movx A,@DPTR
	jz printDot3C

   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
    mov A,#3Ch
    acall PRINT_NUMBER 
	sjmp print3D
printDot3C:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print3D:
    mov DPL,#3Dh
    mov DPH,#0
	movx A,@DPTR
	jz printDot3D
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,#3Dh
    acall PRINT_NUMBER
	sjmp print3E
printDot3D:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print3E:
    mov DPL,#3Eh
    mov DPH,#0
	movx A,@DPTR
	jz printDot3E
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,#3Eh
    acall PRINT_NUMBER
	sjmp print3F
printDot3E:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print3F:
    mov DPL,#3Fh
    mov DPH,#0
	movx A,@DPTR
	jz printDot3F

   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
    mov A,#3Fh
    acall PRINT_NUMBER
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR
	sjmp endPrint
printDot3F:
   	mov   	dptr, #Dot		; send string 
	acall   _TX_STR
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR

endPrint:
	pop ACC
    ret    

newLine:
	.DB "\r\n"
	.DB 00H

Dot:
	.DB "\t."
	.DB 00H

Tab:
	.DB "\t"
	.DB 00H

STR_1: 
	.DB "Serial Port Game\r\n\n\n\n\t.\t.\t.\t.\r\n\t.\t.\t.\t.\r\n\t.\t.\t.\t.\r\n\t.\t.\t.\t.\r\n"
	.DB 00H

STR_2:
	.DB "Serial Port Game\r\n\r\n"
	.DB 00H

NUMBER_STR:
	.DB "0123456789ABCDEF"




_DELAY:
	mov R0, A
_DELAY_I:
	mov R1, #100		;R1 = 100
_DELAY_J:
	mov R2, #100		;R2 = 100
_DELAY_K:
	djnz R2, _DELAY_K	;if(--R2 != 0) goto DELAY_K
	djnz R1, _DELAY_J	;if(--R1 != 0) goto DELAY_J
	djnz R0, _DELAY_I	;if(--R0 != 0) goto DELAY_I
	ret
