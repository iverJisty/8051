	.org    0x0000
	ajmp    start_main

; serial bus interrupt service routine (echos characters)
	.org    23h
	
	JNB RI, ISR_end 	; source is incoming? if not go directly to end
	clr	RI				; clear RI.
	mov	A, SBUF			;get char in buffer.
	;acall _TX_CHAR		;send character
    acall MOVE_UP
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
 
;  	mov   	dptr, #STR_1    ; send string 
;	acall   _TX_STR

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

MOVE_UP:
    push ACC
    push B
    ;acall PUSH_UP
    ; compact
   
    mov A,#24
    mov DPTR,#0x30
    movx @DPTR,A

    mov A,#33
    mov DPTR,#0x31
    movx @DPTR,A
    
    mov A,#24
    mov DPTR,#0x34
    movx @DPTR,A

    mov A,#33
    mov DPTR,#0x35
    movx @DPTR,A
    
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

    mov DPL,#0x30
    mov DPH,#0
    movx A,@DPTR
    acall _SEND_DEZ_NUM

    mov DPL,#0x31
    mov DPH,#0
    movx A,@DPTR
    acall _SEND_DEZ_NUM

    ;acall PUSH_UP
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

    mov A,#'U'
    acall _TX_CHAR
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


DISPLAY:
	push ACC

	; move back cursor
	mov A,#10				; demo for positioning the cursor
	mov B,#10
	acall _CSI_POS
	; prompt
   	mov   	dptr, #STR_2    ; send string 
	acall   _TX_STR
	
	mov 30, #1
	mov 31, #2
	mov 32, #3
	mov 33, #4
	mov 34, #5
	mov 35, #6
	mov 36, #7
	mov 37, #8
	mov 38, #9
	mov 39, #10
	mov 3Ah, #11
	mov 3Bh, #12
	mov 3Ch, #13
	mov 3Dh, #14
	mov 3Eh, #15
	mov 3Fh, #16
	
print30:
	mov A, #0x0
	subb A, 30
	jz printDot30

   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
    mov A,30
    acall _SEND_DEZ_NUM
	sjmp print31
printDot30:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print31:
	mov A, #0x0
	subb A, 31
	jz printDot31
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,31
    acall _SEND_DEZ_NUM
	sjmp print32
printDot31:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print32:
	mov A, #0x0
	subb A, 32
	jz printDot32
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,32
    acall _SEND_DEZ_NUM
	sjmp print33
printDot32:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print33:
	mov A, #0x0
	subb A, 33
	jz printDot33

   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
    mov A,33
    acall _SEND_DEZ_NUM
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR
	sjmp print34
printDot33:
   	mov   	dptr, #Dot		; send string 
	acall   _TX_STR
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR

print34:
	mov A, #0x0
	subb A, 34
	jz printDot34

   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
    mov A,34
    acall _SEND_DEZ_NUM
	sjmp print35
printDot34:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print35:
	mov A, #0x0
	subb A, 35
	jz printDot35

   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
    mov A,35
    acall _SEND_DEZ_NUM
	sjmp print36
printDot35:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print36:
	mov A, #0x0
	subb A, 36
	jz printDot36
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,36
    acall _SEND_DEZ_NUM
	sjmp print37
printDot36:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print37:
	mov A, #0x0
	subb A, 37
	jz printDot37
    
   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
	mov A,37
    acall _SEND_DEZ_NUM
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR
	sjmp print38
printDot37:
   	mov   	dptr, #Dot		; send string 
	acall   _TX_STR

print38:
	mov A, #0x0
	subb A, 38
	jz printDot38

   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
    mov A,38
    acall _SEND_DEZ_NUM
	sjmp print39
printDot38:
   	mov   	dptr, #Dot	    ; send string 
	acall   _TX_STR
   	mov   	dptr, #newLine  ; send string 
	acall   _TX_STR

print39:
	mov A, #0x0
	subb A, 39
	jz printDot39

   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
    mov A,39
    acall _SEND_DEZ_NUM
	sjmp print3A
printDot39:
   	mov   	dptr, #Dot		; send string 
	acall   _TX_STR

print3A:
	mov A, #0x0
	subb A, 3Ah
	jz printDot3A
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,3Ah
    acall _SEND_DEZ_NUM
	sjmp print3B
printDot3A:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print3B:
	mov A, #0x0
	subb A, 3Bh
	jz printDot3B
    
   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
	mov A,3Bh
    acall _SEND_DEZ_NUM
   	mov   	dptr, #newLine	; send string 
	acall   _TX_STR
	sjmp print3C
printDot3B:
   	mov   	dptr, #Dot		; send string 
	acall   _TX_STR

print3C:
	mov A, #0x0
	subb A, 3Ch
	jz printDot3C

   	mov   	dptr, #Tab		; send string 
	acall   _TX_STR
    mov A,3Ch
    acall _SEND_DEZ_NUM
	sjmp print3D
printDot3C:
   	mov   	dptr, #Dot		; send string 
	acall   _TX_STR
   	mov   	dptr, #newLine  ; send string 
	acall   _TX_STR

print3D:
	mov A, #0x0
	subb A, 3Dh
	jz printDot3D

   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
    mov A,3Dh
    acall _SEND_DEZ_NUM
	sjmp print3E
printDot3D:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print3E:
	mov A, #0x0
	subb A, 3Eh
	jz printDot3E
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
	mov A,3Eh
    acall _SEND_DEZ_NUM
	sjmp print3F
printDot3E:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

print3F:
	mov A, #0x0
	subb A, 3Fh
	jz printDot3F
    
   	mov   	dptr, #Tab    ; send string 
	acall   _TX_STR
    
	mov A,3Fh
    acall _SEND_DEZ_NUM
	sjmp endPrint
printDot3F:
   	mov   	dptr, #Dot    ; send string 
	acall   _TX_STR

endPrint:
	pop ACC
    

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
