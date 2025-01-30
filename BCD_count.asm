;Blink D0 with delay
;registers that are in use: 0x41 - lsd, 0x42 - msd, 0x43 - up/down


LIST P=PIC16F877 
include <P16f877.inc> 
org 0x00 
reset:
goto start
org 0x04 
start: 

 bcf STATUS, RP0 
 bcf STATUS, RP1 
 clrf PORTD
 
 bsf STATUS, RP0 
 clrf TRISD
 bcf STATUS, RP0

 addlw 10000000
 addwf 0x40,0

lulaa: 
 bcf PORTD,0X00 

counter:
	clrf 0x41
	movlw 0x0f
	movwf 0x42 ;msd
	btfsc 0x43,0	;0x43=0 ? countup:countdown
	goto countdown
	goto countup

	countdown:
		call delay	
		call blink 	
		call checkif0	
		decf 0x41,1
		goto countdown

	countup:
		call delay
		call checkif9
		incf 0x41,1
		call blink
		goto countup

 bsf PORTD,0X00

 goto lulaa


;----------------------------------------------------------------------------
;countup: checks if lsd=9, if yes checks if msd=9, otherwise returns counting
checkif9:
	btfsc 0x41, 0   ;if lsd[0]==0 return
	btfss 0x41, 3   ;if lsd[3]==1, clear lsd, incr msd
	return
	goto checkif99
	
checkif99:
	btfsc 0x42, 0   
	btfss 0x42, 3   
	goto nextDigit
	goto zeroOut

;countdown
checkif0:
	btfsc 0x41,0
	return 
	btfsc 0x41,1
	return
	btfsc 0x41,2
	return
	btfsc 0x41,3
	return
	goto checkif00

checkif00:
	btfsc 0x42,0
	goto prevDigit 
	btfsc 0x42,1
	goto prevDigit
	btfsc 0x42,2
	goto prevDigit
	btfsc 0x42,3
	goto prevDigit
	goto setAll

;------------------------------------------------------------
;countUp: go here if num=99, the function sets num=00
zeroOut:
	clrw 
	movwf 0x41
	movwf 0x42
	goto countup

;countDown: go here if num=00, the function sets num=99
setAll:
	call blink
	addlw 0x09
	movwf 0x41
	movwf 0x42
	goto countdown

;------------------------------------------------------------
;countUp: go here if lsd=9, lsd=0, msd++
nextDigit:
	;lsd=0
	clrf 0x41
	;msd++
	incf 0x42,1
	call blink
	goto countup		

;countDown: go here if lsd=0, sets lsd=9, msd--
prevDigit:
	;lsd=9
	call blink
	movlw 0x09
   	movwf 0x41
	decf 0x42,1 ;msd==0 ? setAll():msd--
	goto countdown

;-----------------------------------------------------------------
;put before each increment of num
delay:					;-----> 500ms delay
		movlw		0x32		;N1 = 50d
		movwf		0x51
CONT5:	movlw		0x80			;N2 = 128d
		movwf		0x52
CONT6:	movlw		0x80			;N3 = 128d
		movwf		0x53
CONT7:	decfsz		0x53, f
		goto		CONT7
		decfsz		0x52, f
		goto		CONT6
		decfsz		0x51, f
		goto		CONT5
		return			;D = (5+4N1+4N1N2+3N1N2N3)*200nsec = (5+4*50+4*50*128+3*50*128*128)*200ns = 496.7ms=~500ms


;-------------------------------------------------------------------------------
;0x41(lsd) -> PORTD[0:3], 0x42(msd) -> PORTD[4:7]
;call before each change in registers 0x41,0x42 to put their contents into PORTD
blink:
	swapf 0x42,0 ;move msd to PORTD[3:]
	movwf PORTD
	movf 0x41,0  ;PORTD+=lsd
	addwf PORTD,1
    	return

end