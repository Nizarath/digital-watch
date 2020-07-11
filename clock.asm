.device 	at90s1200 		;--------������� ������� = 2.4576MHz
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
.def 	LowerDisp=r28
.def 	UpperDisp=r29

rjmp 	Init

;----------[Hours : Minutes] -> [HourTens HourOnes : MinTens MinOnes]----------
GetDecNum:
	clr 	MinOnes 	 	;��������� ���������� "00:00" 
	clr 	MinTens
	clr 	HourOnes
	clr 	HourTens
	mov 	temp,hours		;�������� hours 
FindHourTens: 				;---��������� ���������� �11
	subi 	hours,10 		
	brcs  	FindHourOnes 	;��������
	inc 	HourTens 	 	;��� �� ��������, �����������
	rjmp 	FindHourTens
FindHourOnes:				;---��������� ���������� �10
	subi 	hours,-10 		;������� 10
	mov 	HourOnes,hours 	;��������
	mov 	hours,temp 		;����������� hours 
	mov 	temp,minutes 	;�������� minutes 
FindMinTens: 				;---��������� ���������� �01
	subi 	minutes,10 		
	brcs  	FindMinOnes 	;��������
	inc 	MinTens 	 	;��� �� ��������, �����������
	rjmp 	FindMinTens
FindMinOnes:				;---��������� ���������� �00
	subi 	minutes,-10 	;������� 10
	mov 	MinOnes,minutes ;��������
	mov 	minutes,temp	;����������� minutes
	ret

;-----------------------display current 7seg-----------------------------------
Display:
	;������� 1 ��� �� 770 ������� (~ 0.02 ��� ��������)
	subi 	LowerDisp,1 	;������ �������--
	brcs 	PC+2 			
	ret 					;�� ������� -> ����� ����� =/= 0 -> �������
	dec 	UpperDisp 		;������ �������--
	breq 	PC+2
	ret 					;�� 0 -> �������
	ldi 	LowerDisp,0x63 	;����� ����� = 0 -> ������� ���������
	ldi 	UpperDisp,0x04
	;����� �� 7seg
	mov 	temp2,ZL 		;�������� ����� �������� ���. �������
	ld 		temp,Z 			;������� ���. ����� ��� ����������
	mov 	ZL,temp 		;��� ���. ��� ����� ������� 7seg-�����
	ld 		temp,Z 			;������� �������������� ���
	sbic 	PortB,0 		;PB0 �� ������
	sbr 	temp,0b00000001
	out 	PortB,temp 		;������� �� ���������
	;������� ����� ������ ���.�������
	mov 	ZL,temp2 		;����������� ������� �����
	inc 	ZL 				;�������� ���
	cpi 	ZL,26 			;������� ������� �����?
	brne 	PC+2
	ldi 	ZL,22	 		;����� ������� ���������
	;����� 7seg
	in 		temp,PortD 		;������� ������� �����
	andi 	temp,0b00000011 ;�������� ������ ����� 7seg
	inc 	temp 			;������� ���������
	cpi 	temp,4 			;������?
	brne 	PC+2
	clr 	temp 			;����� ������� 7seg �00
	ori 	temp,0b01100100 ;������� ������ �� �������� (��� ������� ����� �������� �������)
	out 	PortD,temp 		;������ ����� 7seg
	ret

;------------------------------INIT--------------------------------------------- 
Init:
	;		�����
	ser 	temp 			;PB1..7 ��������� ���������, PB0 ���� ":"  
	out 	DDRB,temp 		
	ldi 	temp,0b10011011	;PD0,1 �������� �������, PD2,5,6 ��������� ������, ��������� �� ���.
	out 	DDRD,temp
	ldi 	temp,0b11111101	;���������� �� 7seg "0"
	out 	PortB,temp
	ldi 	temp,0b01100111	;PD0,1 ���. HourTens (�� ����. ������ Display ������ MinOnes),
	out 	PortD,temp		;PD2,5,6 ������.������, ��������� �� ���. 		
	;		WATCHDOG
	clr 	temp
	out 	WDTCR,temp 		;��������� "������"
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
	;     	�����
	clr 	ZH 				;����� ZL=Z
	ldi 	ZL,22	  		;����� MinOnes
	ldi 	LowerDisp,0x63 	;Display ����� ~0.02 ��� 
	ldi 	UpperDisp,0x04	
	;       �����
	clr 	minutes 		;���������� "00:00"
	clr 	hours
	;	  ��������
	ldi 	mark240,240		;1 ���
	ldi 	counter1,200
	ldi 	counter2,3
	ldi 	counter3,5 		;0.5 ���
	;      ������
	ldi 	temp,0b00000101	;������ �� 2400Hz
	out 	TCCR0,temp
	clr 	temp
	out 	TCNT0,temp		;���� �����!

;-------------------------����� ���������---------------------------------------
Start:
	;����� �������
	rcall 	GetDecNum 		;hours,minutes -> HourTens,HourOnes,MinTens,MinOnes   
	rcall 	Display 		;�����
	;�������� ������
	sbic 	PinD,2 			;������ SET?
	rjmp 	PC+4	 		;���
	sbis 	PinD,2 			;��, �������� ����������...
	rjmp 	PC-1
	rjmp 	SetTime 		;������ ���������...
	;������ ������?
	in 		temp,TCNT0 		;������� ������	
	cp 		temp,mark240 	;��������� �������1 ?
	brne 	Start 			;����, ��������� � ������
	subi 	mark240,-240 	;��, ��������� ������� 
	dec 	counter1 		;��������� �������2 ?
	brne 	Start 			;����, ��������� � ������
	ldi 	counter1,200 	;��, ������� �������1
	dec 	counter2 		;���� ��� ��������?
	brne 	Start 			;��, ��������� � ������
	;������� ��������� ��������
	ldi 	counter2,3		;� counter1 ������ ��� ��������� 200 
	;���������� �������
	inc 	minutes  		;�������� ������
	cpi 	minutes,60 		;60?
	brne 	Start 			
	clr 	minutes 		;����� �������� ������... 
	inc 	hours 			;...� ��������� ����
	cpi 	hours,24 		;24?
	brne 	Start
	clr 	hours			;����� �������� ����
	rjmp 	Start 			;��������� ������ ���������...
;-------------------------����� ���������---------------------------------------
SetTime:
	;�����
	rcall 	GetDecNum  
	rcall 	Display	
	;�������� "HRS"
	sbic 	PinD,5		 	;������ "HRS"?
	rjmp 	PC+7 			
	inc 	hours  			;��, ++����
	cpi 	hours,24 		;����� �����?
	brne 	PC+2
	clr 	hours 			;�� -> �������� ����
	sbis 	PinD,5 			;�������� ����������...
	rjmp 	PC-1
	;�������� "MINS"
	sbic 	PinD,6 			;������ "MINS"?
	rjmp 	PC+7
	inc 	minutes			;��, ++������
	cpi 	minutes,60 		;����� �����?
	brne 	PC+2 		
	clr 	minutes 		;�� -> �������� ������	
	sbis 	PinD,6 			;�������� ����������...
	rjmp 	PC-1 	
	;�������� "SET"
	sbic 	PinD,2 			;������ "SET"?
	rjmp 	PC+8
	ldi 	mark240,240		;��, ������ ������� � ������
	ldi 	counter1,200
	ldi 	counter2,3
	sbi 	PortB,0 		;���������� �������
	sbis 	PinD,2 			;�������� ����������...
	rjmp 	PC-1
	rjmp 	Start-2	 		;����� �� ������ ��������� �� ��������� ��������
	;������ 0.5 ���?
	in 		temp,TCNT0 		;������� ������
	cp 		temp,mark240 	;��������� �������3 ?
	brne 	SetTime 		;����, ��������� � ������
	subi 	mark240,-240 	;��, ��������� �������
	dec 	counter3 		;���� ��� ��������?
	brne 	SetTime 		;��, ��������� � ������
	;������� �������� ��������
	ldi 	counter3,5 		;0.5 ���
	;����� ����� �������
	in 		temp,PinB 		;������� PB0
	ldi 	temp2,0b00000001
	eor 	temp,temp2 		;������������� PB0
	out 	PortB,temp 	 	;������ PB0
	rjmp 	SetTime 		;��������� ������ ���������...










