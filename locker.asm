		LIST 	P=PIC16F877
		include	P16f877.inc
 __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _WRT_ENABLE_ON & _LVP_OFF & _DEBUG_OFF & _CPD_OFF
;karina meriina
;  LCD
;
		org		0x00
reset	goto	start

		org	0x10

start	bcf		STATUS, RP0
		bcf		STATUS, RP1		;Bank 0
		clrf	PORTD
		clrf	PORTE

		bsf		STATUS, RP0		;Bank 1
		movlw	0x06
		movwf	ADCON1

		clrf	TRISE		;porte output 
		clrf	TRISD		;portd output

		bcf			INTCON,GIE		;No interrupt
		movlw		0x0F
		movwf		TRISB
		bcf			OPTION_REG,0x7	;Enable PortB Pull-Up

		bcf		STATUS, RP0		;Bank 0
		call set_password
		call init_lcd
		goto check_password


;----------------------------------------------------------

wait	goto	wait


;subroutine to initialize LCD
init_lcd	movlw	0x30
			movwf	0x20
			call 	lcdc
			call	delay_41
	
			movlw	0x30
			movwf	0x20
			call 	lcdc
			call	delay_01
	
			movlw	0x30
			movwf	0x20
			call 	lcdc
			call	m_delay
	
			movlw	0x01		; display clear
			movwf	0x20
			call 	lcdc
			call	m_delay
	
			movlw	0x06		; ID=1,S=0 increment,no  shift 000001 ID S
			movwf	0x20
			call 	lcdc
			call	m_delay
	
			movlw	0x0c		; D=1,C=B=0 set display ,no cursor, no blinking
			movwf	0x20
			call 	lcdc
			call	m_delay
	
			movlw	0x38		; dl=1 ( 8 bits interface,n=12 lines,f=05x8 dots)
			movwf	0x20
			call 	lcdc
			call	m_delay
			return


;subroutine to write command to LCD
lcdc	movlw	0x00		; E=0,RS=0 
		movwf	PORTE
		movf	0x20,w
		movwf	PORTD
		movlw	0x01		; E=1,RS=0
		movwf	PORTE
        call	s_delay
		movlw	0x00		; E=0,RS=0
		movwf	PORTE
		return

;subroutine to write data to LCD
lcdd	movlw		0x02		; E=0, RS=1
		movwf		PORTE
		movf		0x20,w
		movwf		PORTD
        movlw		0x03		; E=1, rs=1  
		movwf		PORTE
		call		s_delay
		movlw		0x02		; E=0, rs=1  
		movwf		PORTE
		return

;----------------------------*------------------------------
;password is 7635, registers that hold it - 0x30,0x31,0x32,0x33
;score=3 in 0x41; used in check_password()
set_password:
	movlw 0x07  ;set password
	movwf 0x30
	movlw 0x06
	movwf 0x31
	movlw 0x03
	movwf 0x32
	movlw 0x05
	movwf 0x33

	movlw 0x04  ;set score
	movwf 0x41
	
	return
	
;checks the num that came from kb_input. if right, score--
;score (0x41) - counts if all numbers pressed were right. if score==0 in num3, open
check_password:
		call kb_input	;check password[0]
		subwf 0x30,1
		btfss STATUS,0x02
		decf 0x41,1
		
		call m_delay
		call kb_input	;check password[1]
		subwf 0x31,1
		btfss STATUS,0x02
		decf 0x41,1

		call m_delay
		call kb_input   ;check password[2]
		subwf 0x32,1
		btfss STATUS,0x02
		decf 0x41,1
		
		call m_delay
		call kb_input   ;check password[3]
		subwf 0x33,1
		btfss STATUS,0x02
		decf 0x41,1
		goto locker


locker:
	btfss 0x41,0x01
	btfsc 0x41,0x00
	goto close
	goto open


open:
		movlw	0xC4		;PLACE for the data on the LCD
		movwf	0x20
		call 	lcdc
		call	m_delay

		movlw	'o'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	s_delay

		movlw	'p'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	s_delay
		
		movlw	'e'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	s_delay

		movlw	'n'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	s_delay

		goto finish


close:
		movlw	0xC4		;PLACE for the data on the LCD
		movwf	0x20
		call 	lcdc
		call	m_delay

		movlw	'c'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	s_delay

		movlw	'l'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	s_delay
		
		movlw	'o'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	s_delay

		movlw	's'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	s_delay

		movlw	'e'			; CHAR (the data )
		movwf	0x20
		call 	lcdd
		call	s_delay

		goto finish

;--------------------------------------------------------------------------------------------------
;input the number & put it into 0x42 register
kb_input:	bcf			PORTB,0x4		;scan Row 1
			bsf			PORTB,0x5
			bsf			PORTB,0x6
			bsf			PORTB,0x7
			btfss		PORTB,0x0
			goto		kb11
			btfss		PORTB,0x1
			goto		kb12
			btfss		PORTB,0x2
			goto		kb13
			btfss		PORTB,0x3
			goto		kb14
	
			bsf			PORTB,0x4
			bcf			PORTB,0x5		;scan Row 2
			btfss		PORTB,0x0
			goto		kb21
			btfss		PORTB,0x1
			goto		kb22
			btfss		PORTB,0x2
			goto		kb23
			btfss		PORTB,0x3
			goto		kb24
	
			bsf			PORTB,0x5
			bcf			PORTB,0x6		;scan Row 3
			btfss		PORTB,0x0
			goto		kb31
			btfss		PORTB,0x1
			goto		kb32
			btfss		PORTB,0x2
			goto		kb33
			btfss		PORTB,0x3
			goto		kb34
	
			bsf			PORTB,0x6
			bcf			PORTB,0x7		;scan Row 4
			btfss		PORTB,0x0
			goto		kb41
			btfss		PORTB,0x1
			goto		kb42
			btfss		PORTB,0x2
			goto		kb43
			btfss		PORTB,0x3
			goto		kb44
	
			goto		kb_input


kb11:	movlw 0x01
		return

kb12:	movlw 0x02
		return

kb13:	movlw 0x03
		return

kb14:	movlw 0x0A
		return

kb21:	movlw 0x04
		return

kb22:	movlw 0x05
		return

kb23:	movlw 0x06
		return

kb24:	movlw 0x0A
		return

kb31:	movlw 0x07
		return

kb32:	movlw 0x08
		return

kb33:	movlw 0x9
		return

kb34:	movlw 0x0A
		return
		
kb41:	movlw 0x0A
		return

kb42:	movlw 0x0A
		return

kb43:	movlw 0x0A
		return

kb44:	movlw 0x0A
		return
;---------------------------------------------------------------------
;delays
delay_41 movlw 0xcd
		 movwf		0x23
lulaa6		movlw		0x20
			movwf		0x22
lulaa7		decfsz		0x22,1
		goto		lulaa7
		decfsz		0x23,1
		goto 		lulaa6 
		return


delay_01	movlw		0x20
		movwf		0x22
lulaa8	decfsz		0x22,1
		goto		lulaa8
		return


s_delay	movlw		0x19		; movlw = 1 cycle
		movwf		0x23		; movwf	= 1 cycle
lulaa2	movlw		0xfa
		movwf		0x22
lulaa1	decfsz		0x22,1		; decfsz= 12 cycle
		goto		lulaa1		; goto	= 2 cycles
		decfsz		0x23,1
		goto 		lulaa2 
		return


m_delay	movlw		0x3f
		movwf		0x24
lulaa5	movlw		0x19
		movwf		0x23
lulaa4	movlw		0xfa
		movwf		0x22
lulaa3	decfsz		0x22,1
		goto		lulaa3
		decfsz		0x23,1
		goto 		lulaa4 
		decfsz		0x24,1
		goto		lulaa5
		return

finish:
	goto finish

end