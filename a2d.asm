

		LIST 	P=PIC16F877
		include	<P16f877.inc>
 __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _WRT_ENABLE_ON & _LVP_OFF & _DEBUG_OFF & _CPD_OFF

		org		0x00
reset:	goto	start_adc

		org		0x04
		btfsc	PIR1, TMR1IF
		goto	psika
		goto waitc

		org		0x10

init_timer1:	
		overflow_counts EQU 0x30	;it takes 2 overflows of Timer1 to measure 1 second
		movlw 0x03
		movwf overflow_counts

		bcf	STATUS, RP0
		bcf	STATUS, RP1			; Bank0 <------
		clrf INTCON

		movlw	0x30				;Internal clock with 1:8 prescaler
		movwf	T1CON

set_timer1:
		clrf TMR1H			;Timer1=0	
		clrf TMR1L	
		
		clrf	PIR1				;clear peripheral interrupt flags

		bsf		T1CON, TMR1ON		; Timer 1 starts to increment
;----------------------------------------------------------------------------------------------
wait:	btfss	PIR1, TMR1IF		; Checking the overflow flag in Timer1
		goto wait
		decfsz overflow_counts
		goto set_timer1
		return

		;incf	PORTD
		;movlw	0x83				;0x83 = 131d
		;movwf	TMR0				;	Td = 200ns*(256-TMR0)*PS = 200ns*(256-131)*4 = 100us


;---------------------------------------------------------------------------------------
loop:	goto	loop
;---------------------------------------------------------------------------------------

psika:	bcf		T1CON, TMR1ON
		movwf	0x7A				;store W_reg --> 0x7A
		swapf	STATUS, w
		movwf	0x7B				;store STATUS --> 0x7B
		
		swapf	0x7B, w
		movwf	STATUS				;restore STATUS <-- 0x7B
		swapf	0x7A, f
		swapf	0x7A, w				;restore W_reg <-- 0x7A
		;bsf		T1CON, TMR1ON
		retfie

		;btfsc	PIR1, TMR1IF
		;goto	Timer1
ERR:	goto	ERR

Timer1:	;incf	PORTD

;		movlw	0xF0
;		movwf	TMR1L
;		movlw	0xFF
;		movwf	TMR1H
;		bcf		PIR1, TMR1IF

;		swapf	0x7B, w
;		movwf	STATUS				;restore STATUS <-- 0x7B
;		swapf	0x7A, f
;		swapf	0x7A, w				;restore W_reg <-- 0x7A
;		bsf		T1CON, TMR1ON
;		retfie

;---------------------------------------------------------------------------------------

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



end
