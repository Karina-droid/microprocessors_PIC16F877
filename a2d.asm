

		LIST 	P=PIC16F877
		include	<P16f877.inc>
 __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _WRT_ENABLE_ON & _LVP_OFF & _DEBUG_OFF & _CPD_OFF

		org		0x00

reset:	goto start

start:
		ones EQU 0x40
		tens EQU 0x41
		hundreds EQU 0x42
		clrf ones
		clrf tens
		clrf hundreds

		call init_lcd
		goto start_adc

;---------------------------------------------------------------------------------------------------------------------------
;delay 1 sec with Timer1
;Timer1 = = (65536 * 200 * 8) ns ~= 105 ms
init_timer1:	
	overflow_counts EQU 0x30	;it takes ~9 overflows of Timer1 to measure 1 second
	movlw 0x09
	movwf overflow_counts

	bcf	STATUS, RP0
	bcf	STATUS, RP1			; Bank0 <------
	clrf INTCON

	movlw	0x30		;Internal clock with 1:8 prescaler
	movwf	T1CON

set_timer1:
	clrf TMR1H			;Timer1=0	
	clrf TMR1L	
	bsf	T1CON, TMR1ON		; Timer 1 starts to increment

wait:	
	btfss	PIR1, TMR1IF		; Checking the overflow flag in Timer1
	goto wait
	decfsz overflow_counts
	goto set_timer1
	return

;--------------------------------------------------------------------------------------------------------------------------
;adc conversion
start_adc:  
	bcf STATUS, RP0
	bcf STATUS, RP1 ;-------> Bank 0
	clrf PORTD
	clrf PORTA
	bsf STATUS, RP0 ; -------> Babk 1
	movlw 0x02
	movwf ADCON1 ; all A analog; E digital
	; format : 6 lower bit of ADRESL =0
	clrf TRISD ;PortD output
	movlw 0xFF
	movwf TRISA ;PortA input
	bcf STATUS,RP0 ;-------> Bank 0
	bcf INTCON,GIE ;disable interrupts
	movlw 0x81
	movwf ADCON0 ;Fosc/32; channel_1; ADC on

lulaa: 
	call delay_95us ;Delay TACQ
	bsf ADCON0,GO ;start conversion

waitc: 
	btfsc ADCON0,GO ;wait end of conversion, GO=1 - conversion still going
	goto waitc
	call delay_1us
	movf ADRESH,W
	movwf PORTD
	goto low_high_V
	end_loop:
	call init_timer1
	goto lulaa

delay_95us: 	;95 microseconds 
	movlw 0x20
	movwf 0x22

loop_95us: 
	decfsz 0x22,1
	goto loop_95us
	return

delay_1us: 	;1 microsecond
	movlw 0x06
	movwf 0x22

loop_1us: 
	decfsz 0x22,1
	goto loop_1us
	return

;----------------------------------------------------------------------------------------------------------------------
;determine if count up/down

;;D = (V_in/V_ref)*(2^8 - 1)
;D = 0.5/2.5 * 255 = 51 ~= 25V 
;0.5V => D=51
;1.5V => D=153
;1.8V => D=184
;2.3V => D=234
;checks if the voltage is in the low range (51 < D < 153) or in high (184 < D < 234)
low_high_V:
	;check if D<51
	movlw 0x33
	subwf ADRESH,w
	btfsc STATUS,C
	goto end_loop		;no counting

	;check if D<153
	movlw 0x99
	subwf ADRESH,W
	btfsc STATUS,C
	goto count_down_lcd

	;check if D<184
	movlw 0xB8
	subwf ADRESH,w
	btfsc STATUS,C
	goto end_loop		;no counting

	;check if D<234
	movlw 0xEA
	subwf ADRESH,w
	btfsc STATUS,C
	goto count_up_lcd
	goto end_loop


count_down_lcd:	
	movlw	0xC4		;place for the data on the LCD on the lower line
	movwf	0x20
	call 	lcdc
	call	m_delay

	movlw	'd'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
	call	s_delay

	movlw	'o'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
	call	s_delay

	movlw	'w'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
	call	s_delay

	movlw	'n'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
	call	s_delay

	call dec_num
	call print_num
	return

	
count_up_lcd:
	movlw	0xC4		;place for the data on the LCD on the lower line
	movwf	0x20
	call 	lcdc
	call	m_delay

	movlw	'u'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
	call	s_delay

	movlw	'p'			; CHAR (the data )
	movwf	0x20
	call 	lcdd
	call	s_delay

	call inc_num
	call print_num
	
	return


print_num:	
	movlw 0x84		;place for the data on the LCD on the upper line
	movwf 0x20
	call lcdc
	call m_delay

	movf ones,1		;ones -> w
	addlw 0x30		;w += 30 to get the ascii of the number
	movlw 0x20
	call lcdd
	call s_delay
	
	movf tens,1		;ones -> w
	addlw 0x30		;w += 30 to get the ascii of the number
	movlw 0x20
	call lcdd
	call s_delay

	movf hundreds,1		;ones -> w
	addlw 0x30		;w += 30 to get the ascii of the number
	movlw 0x20
	call lcdd
	call s_delay

	return
;------------------------------------------------------------------------------------------------------------------------
;counting
inc_num:
	bcf STATUS,Z
	movlw 0x09		
	subwf ones,w
	btfsc STATUS,Z	;if ones=9, inrement tens
	goto inc_tens
	incf ones,1		;ones++
	goto inc_num

	inc_tens:
		bcf STATUS,Z
		movlw 0x09
		subwf tens,w
		btfsc STATUS,Z		;if ones=9, inrement hundreds
		goto inc_hundreds	
		incf tens,1			;ten++, ones=0
		clrf ones
		goto inc_num

		inc_hundreds:
			bcf STATUS,Z
			movlw 0x02
			subwf tens,w
			btfsc STATUS,Z	;if hundreds=2, don't increment
			return
			incf hundreds,1	;hundreds++, tens=0, ones=0
			clrf ones		
			clrf tens
			return


dec_num:
	bcf STATUS,Z
	movlw 0x00
	subwf ones,w
	btfsc STATUS,Z	;if ones=0, decrement tens
	goto dec_tens
	decf ones,1		;ones--
	goto dec_num
	
	dec_tens:
		bcf STATUS,Z
		movlw 0x00
		subwf tens,w
		btfsc STATUS,Z
		goto dec_hundreds	;if tens=0, decrement hundreds
		decf tens,1		;tens--, ones=9
		movlw 0x09
		movwf ones
		goto dec_num

		dec_hundreds:
			bcf STATUS,Z
			movlw 0x00
			subwf hundreds,w	;if hundreds=0, return
			btfsc STATUS,Z
			return
			decf hundreds,1		;hundreds--, tens=9, ones=9
			movlw 0x09
			movwf ones
			movwf tens
			return

;------------------------------------------------------------------------------------------------------------------------
;lcd init and delays for it

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


end
