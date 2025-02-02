		LIST 	P=PIC16F877
		include	P16f877.inc
 __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_OFF & _HS_OSC & _WRT_ENABLE_ON & _LVP_OFF & _DEBUG_OFF & _CPD_OFF

;
LIST P=PIC16F877 
include <P16f877.inc>
org 0x00 
reset:
goto 	start 

org 	0x04 
goto timer1_overflow

;if it's timer1 interruption, go to Timer1()
btfsc ADCON0,TMR1IE
goto interrupt

;input voltage
;check if it's high or low
;count up or down
;delay 1 sec

start: 
	bcf STATUS, RP0
	bcf STATUS, RP1 ;-------> Bank 0
	clrf PORTD
	clrf PORTA
	bsf STATUS, RP0 ; -------> Babk 1
	movlw 0x02		;ADCON1 - configure the analog input pins and refernce voltages.
	movwf ADCON1 	;all A analog; E digital
					; format : 6 lower bit of ADRESL =0
	clrf TRISD ;PortD output
	movlw 0xFF
	movwf TRISA ;PortA input
	bcf STATUS,RP0 ;-------> Bank 0
	bcf INTCON,GIE ;disable all interrupts
	movlw 0x89	 ;10001001
	movwf ADCON0 ;bits 7-6 = 10 - Fosc/32; bits 5-3 = 001 - channel_1, (AN1/RA1); 0 - go/done; 1 - ADC on

lulaa: 
	movwf STATUS
	swapf STATUS,1
	bsf ADCON0,GO ;start conversion

waitc: btfsc ADCON0,GO ;wait end of conversion
	   goto waitc
   	   call d_4
	   movf ADRESH,W
	   movwf PORTD
	   goto lulaa

d_20: movlw 0x20
	  movwf 0x22

lulaa1: call timer1
		decfsz 0x22,1
		goto lulaa1
		return

d_4: movlw 0x06
	 movwf 0x22


lulaa2: decfsz 0x22,1
		goto lulaa2
		return

;-------------------------------------------------------------------------------------------------------------
;D = (V_in/V_ref)*(2^8 - 1)
;D = 0.5/2.5 * 255 = 51 ~= 25V 
;0.5V => D=51
;1.5V => D=153
;1.8V => D=184
;2.3V => D=234

;checks if the voltage in the lower or higher range
low_high_V:
	;check if D<51
	movlw 0x33
	subwf ADRESH,w
	btfsc STATUS,C
	return

	;check if D<77
;	movlw ADDRESS
	
	

;-------------------------------------------------------------------------------------------------------------
timer1:
		bsf STATUS,RP0		;bank 1
		bcf STATUS,RP1
		bcf PIE1,TMR1IE		;enable Timer1 interrupt
		
		bcf STATUS,RP0		;bank 0
		movlw 0x30
		movwf T1CON	;internal clock source with 1:8 prescaler
		movlw 0x6D	;TMR1H:TMR1L = 0X6D60
		movwf TMR1H	;Td = 200ns*(2^16 - TMR1H:TMR1L)*PS = 8*200*(65536 - 28000) ~= 1000ms = 1s
		movlw 0x60
		movwf TMR1L

		clrf PIR1			;clear peripheral interrupt flags
		bsf INTCON,PEIE	;enable peripheral interrupts
		bsf	INTCON,GIE		;enable globl interrupts
	
		bsf T1CON,TMR1ON	;start timer1

;infinite loop until an interrup occurs
loop: goto loop

interrupt:
    ; Timer1 interrupt handling
    bcf T1CON, TMR1ON     ; Stop Timer1 to reset the timer

    ; Save the context
    movwf 0x7A            ; Save W_REG to memory (for restoring later)
    swapf STATUS, W       ; Save STATUS register (to avoid overwriting)
    movwf 0x7B            ; Save STATUS to memory (0x7B)

    ; Handle Timer1 overflow event (this happens after 1 second)
    btfsc PIR1, TMR1IF    ; Check if the interrupt flag is set
    goto timer1_overflow

    ; After interrupt is serviced, clear the interrupt flag
    ;bcf PIR1, TMR1IF      ; Clear the Timer1 interrupt flag

    ; Restore the context
    swapf 0x7B, W
    movwf STATUS          ; Restore STATUS register
    swapf 0x7A, W
    ;movwf WREG            ; Restore W_REG

    ; Restart Timer1
    bsf T1CON, TMR1ON     ; Start Timer1 again
    retfie                ; Return from interrupt and re-enable global interrupts

timer1_overflow:
    ; Your action after Timer1 overflows (e.g., toggle a pin or other task)
    ; Add custom logic here for when the 1-second delay is completed
    goto interrupt        ; Jump back to the interrupt routine to handle the next interrupt



end