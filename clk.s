.device 	at90s1200 		;--------freq = 2.4576MHz
.nolist
.include	"1200def.inc"
.list

.def 	temp=r16
.def 	temp2=r17
.def 	mark240=r18
.def 	counter1=r19
.def 	counter2=r20
.def 	counter3=r21
.def 	MinOnes=r22
.def 	MinTens=r23
.def 	HourOnes=r24
.def 	HourTens=r25
.def 	minutes=r26
.def 	hours=r27
.def 	disp=r28

rjmp 	Init

;----------[Hours : Minutes] -> [HourTens HourOnes : MinTens MinOnes]----------
GetDecNum:
	clr 	MinOnes 		;initially "00:00" 
	clr 	MinTens
	clr 	HourOnes
	clr 	HourTens
	mov 	temp,hours		;save hours 
FindHourTens: 				;---get ind. 11
	subi 	hours,10
	brcs  	FindHourOnes		;got	
	inc 	HourTens 		;hasn't got, accum...
	rjmp 	FindHourTens
FindHourOnes:				;---get ind. 10
	subi 	hours,-10 		;10 back
	mov 	HourOnes,hours 		;got
	mov 	hours,temp 		;restore hours 
	mov 	temp,minutes 		;save minutes 
FindMinTens: 				;---get ind. 01
	subi 	minutes,10 		
	brcs  	FindMinOnes 		;got
	inc 	MinTens 		;hasn't got, accum...
	rjmp 	FindMinTens
FindMinOnes:				;---get ind. 00
	subi 	minutes,-10 		;10 back
	mov 	MinOnes,minutes 	;got
	mov 	minutes,temp		;restore minutes
	ret

;-----------------------display current 7seg-----------------------------------
Display:
	;display in 1/234 calls (~0.02 sec)
	dec 	disp
	breq 	PC+2
	ret 				;not 0 -> exit
	ldi 	disp,0xEA 		;full num. == 0 -> restart counter
	;-> 7seg
	mov 	temp2,ZL 		;save cur. dec. digit addr.
	ld 	temp,Z 			;read dec. digit
	mov 	ZL,temp 		;use as table index
	ld 	temp,Z 			;read 7seg-code
	sbic 	PortB,0 		;not change PB0
	sbr 	temp,0b00000001
	out 	PortB,temp 		;-> 7seg
	;get new dec. digit addr.
	mov 	ZL,temp2 		;restore cur. addr
	inc 	ZL 			;inc
	cpi 	ZL,26 			;to high?
	brne 	PC+2
	ldi 	ZL,22	 		;yep, make start
	;choose 7seg
	in 	temp,PortD 		;read cur. choose
	andi 	temp,0b00000011 	;leave only 7seg num.
	inc 	temp 			;choose next
	cpi 	temp,4 			;far?
	brne 	PC+2
	clr 	temp 			;yep, choose 7seg 00
	ori 	temp,0b01100100 	;buttons aren't pushed
	out 	PortD,temp 		;give 7seg num.
	ret

;------------------------------INIT--------------------------------------------- 
Init:
	;		PORTS
	ser 	temp 			;PB1..7 == 7seg, PB0 == ":"  
	out 	DDRB,temp 		
	ldi 	temp,0b10011011		;PD0,1 choose 7seg, PD2,5,6 read buttons, others aren't used.
	out 	DDRD,temp
	ldi 	temp,0b11111101		;init. 7seg == "0"
	out 	PortB,temp
	ldi 	temp,0b01100111		;PD0,1 choose HourTens (on next Display call will be MinOnes),
	out 	PortD,temp		;PD2,5,6 buttons off, others aren't used
	;		WATCHDOG
	clr 	temp
	out 	WDTCR,temp 		;"dog" off
	;       7SEG TABLE
	ldi 	temp,0b11111100	;	0
	mov 	R0,temp
	ldi 	temp,0b01100000	;	1
	mov 	R1,temp
	ldi 	temp,0b11011010 ;	2
	mov 	R2,temp
	ldi 	temp,0b11110010 ;	3
	mov 	R3,temp
	ldi 	temp,0b01100110 ;	4
	mov 	R4,temp
	ldi 	temp,0b10110110 ;	5
	mov 	R5,temp
	ldi 	temp,0b10111110 ;	6
	mov 	R6,temp
	ldi 	temp,0b11100000 ;	7
	mov 	R7,temp
	ldi 	temp,0b11111110	;	8
	mov 	R8,temp
	ldi 	temp,0b11110110 ;	9
	mov 	R9,temp		
	;     	out
	clr 	ZH 			;ZL=Z
	ldi 	ZL,22	  		;MinOnes addr.
	ldi 	disp,0xEA 		;Display after ~0.02 sec
	;       time
	clr 	minutes 		;init. "00:00"
	clr 	hours
	;	intervals
	ldi 	mark240,240		;1 min.
	ldi 	counter1,200
	ldi 	counter2,3
	ldi 	counter3,5 		;0.5 sec.
	;       timer
	ldi 	temp,0b00000101		;2400Hz
	out 	TCCR0,temp
	clr 	temp
	out 	TCNT0,temp		;start!

;-------------------------measure---------------------------------------
Start:
	;out time
	rcall 	GetDecNum 		;hours,minutes -> HourTens,HourOnes,MinTens,MinOnes   
	rcall 	Display 		;out
	;check buttons
	sbic 	PinD,2 			;is SET pressed?
	rjmp 	PC+4	 		;no
	sbis 	PinD,2 			;yep, wait for release...
	rjmp 	PC-1
	rjmp 	SetTime 		;start settings...
	;is minute over?
	in 	temp,TCNT0 		;read timer
	cp 	temp,mark240 		;dec counter0 ?
	brne 	Start 			;no, -> start
	subi 	mark240,-240 		;yep, inc boundary
	dec 	counter1 		;dec counter2 ?
	brne 	Start 			;no, -> start
	ldi 	counter1,200 		;yep, restart counter1
	dec 	counter2 		;more iters?
	brne 	Start 			;yep, -> start
	;restart delay registers
	ldi 	counter2,3		;counter1 = 200
	;inc time
	inc 	minutes  		;int mins
	cpi 	minutes,60 		;60?
	brne 	Start 			
	clr 	minutes 		;yep, reset mins... 
	inc 	hours 			;... & inc hours
	cpi 	hours,24 		;24?
	brne 	Start
	clr 	hours			;yep, reset hours
	rjmp 	Start 			;repeat...
;-------------------------set mode---------------------------------------
SetTime:
	;out
	rcall 	GetDecNum  
	rcall 	Display	
	;check "HRS"
	sbic 	PinD,5		 	;"HRS" is pressed?
	rjmp 	PC+7 			
	inc 	hours  			;yep, ++hours
	cpi 	hours,24 		;many hours?
	brne 	PC+2
	clr 	hours 			;yep -> reset hours
	sbis 	PinD,5 			;wait for release...
	rjmp 	PC-1
	;check "MINS"
	sbic 	PinD,6 			;"MINS" is pressed?
	rjmp 	PC+7
	inc 	minutes			;yep, ++mins
	cpi 	minutes,60 		;many mins?
	brne 	PC+2 		
	clr 	minutes 		;yep -> reset mins	
	sbis 	PinD,6 			;wait for release...
	rjmp 	PC-1 	
	;check "SET"
	sbic 	PinD,2 			;"SET" is pressed?
	rjmp 	PC+8
	ldi 	mark240,240		;yep, count from start
	ldi 	counter1,200
	ldi 	counter2,3
	sbi 	PortB,0 		;stop blink
	sbis 	PinD,2 			;wait for release...
	rjmp 	PC-1
	rjmp 	Start-2	 		;-> counter = 0
	;0.5 sec over?
	in 	temp,TCNT0 		;read timer
	cp 	temp,mark240 		;dec counter3 ?
	brne 	SetTime 		;no, -> start
	subi 	mark240,-240 		;yep, inc boundary
	dec 	counter3 		;more iters?
	brne 	SetTime 		;yep, -> start
	;delay register restart
	ldi 	counter3,5 		;0.5 sec
	;change blink stage
	in 	temp,PinB 		;read PB0
	ldi 	temp2,0b00000001
	eor 	temp,temp2 		;invert PB0
	out 	PortB,temp 	 	;give PB0
	rjmp 	SetTime 		;repeat...
