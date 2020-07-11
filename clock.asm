.device 	at90s1200 		;--------РАБОЧАЯ ЧАСТОТА = 2.4576MHz
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
	clr 	MinOnes 	 	;результат изначально "00:00" 
	clr 	MinTens
	clr 	HourOnes
	clr 	HourTens
	mov 	temp,hours		;сохраним hours 
FindHourTens: 				;---получение индикатора №11
	subi 	hours,10 		
	brcs  	FindHourOnes 	;получено
	inc 	HourTens 	 	;еще не получено, накапливаем
	rjmp 	FindHourTens
FindHourOnes:				;---получение индикатора №10
	subi 	hours,-10 		;вернуть 10
	mov 	HourOnes,hours 	;получено
	mov 	hours,temp 		;восстановим hours 
	mov 	temp,minutes 	;сохраним minutes 
FindMinTens: 				;---получение индикатора №01
	subi 	minutes,10 		
	brcs  	FindMinOnes 	;получено
	inc 	MinTens 	 	;еще не получено, накапливаем
	rjmp 	FindMinTens
FindMinOnes:				;---получение индикатора №00
	subi 	minutes,-10 	;вернуть 10
	mov 	MinOnes,minutes ;получено
	mov 	minutes,temp	;восстановим minutes
	ret

;-----------------------display current 7seg-----------------------------------
Display:
	;выводит 1 раз на 770 вызовов (~ 0.02 сек интервал)
	subi 	LowerDisp,1 	;первый счетчик--
	brcs 	PC+2 			
	ret 					;не сброшен -> общее число =/= 0 -> выходим
	dec 	UpperDisp 		;второй счетчик--
	breq 	PC+2
	ret 					;не 0 -> выходим
	ldi 	LowerDisp,0x63 	;общее число = 0 -> рестарт счетчиков
	ldi 	UpperDisp,0x04
	;вывод на 7seg
	mov 	temp2,ZL 		;сохраним адрес текущего дес. разряда
	ld 		temp,Z 			;считали дес. цифру для индикатора
	mov 	ZL,temp 		;она исп. как адрес таблицы 7seg-кодов
	ld 		temp,Z 			;считали семисегментный код
	sbic 	PortB,0 		;PB0 не меняем
	sbr 	temp,0b00000001
	out 	PortB,temp 		;вывести на индикатор
	;получим адрес нового дес.разряда
	mov 	ZL,temp2 		;восстановим текущий адрес
	inc 	ZL 				;увеличим его
	cpi 	ZL,26 			;слишком большой адрес?
	brne 	PC+2
	ldi 	ZL,22	 		;тогда сделать начальным
	;выбор 7seg
	in 		temp,PortD 		;считали текущий выбор
	andi 	temp,0b00000011 ;оставить только номер 7seg
	inc 	temp 			;выбрать следующий
	cpi 	temp,4 			;далеко?
	brne 	PC+2
	clr 	temp 			;тогда выбрать 7seg №00
	ori 	temp,0b01100100 ;сделать кнопки не нажатыми (при нажатии земля окажется сильнее)
	out 	PortD,temp 		;выдать номер 7seg
	ret

;------------------------------INIT--------------------------------------------- 
Init:
	;		ПОРТЫ
	ser 	temp 			;PB1..7 управляют сегментом, PB0 дает ":"  
	out 	DDRB,temp 		
	ldi 	temp,0b10011011	;PD0,1 выбирают сегмент, PD2,5,6 считывают кнопки, остальные не исп.
	out 	DDRD,temp
	ldi 	temp,0b11111101	;изначально на 7seg "0"
	out 	PortB,temp
	ldi 	temp,0b01100111	;PD0,1 выб. HourTens (на след. вызове Display станет MinOnes),
	out 	PortD,temp		;PD2,5,6 выключ.кнопки, остальные не исп. 		
	;		WATCHDOG
	clr 	temp
	out 	WDTCR,temp 		;выключить "собаку"
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
	;     	вывод
	clr 	ZH 				;чтобы ZL=Z
	ldi 	ZL,22	  		;адрес MinOnes
	ldi 	LowerDisp,0x63 	;Display через ~0.02 сек 
	ldi 	UpperDisp,0x04	
	;       время
	clr 	minutes 		;изначально "00:00"
	clr 	hours
	;	  задержки
	ldi 	mark240,240		;1 мин
	ldi 	counter1,200
	ldi 	counter2,3
	ldi 	counter3,5 		;0.5 сек
	;      таймер
	ldi 	temp,0b00000101	;таймер на 2400Hz
	out 	TCCR0,temp
	clr 	temp
	out 	TCNT0,temp		;счет пошел!

;-------------------------режим измерения---------------------------------------
Start:
	;вывод времени
	rcall 	GetDecNum 		;hours,minutes -> HourTens,HourOnes,MinTens,MinOnes   
	rcall 	Display 		;вывод
	;проверка кнопок
	sbic 	PinD,2 			;нажата SET?
	rjmp 	PC+4	 		;нет
	sbis 	PinD,2 			;да, ожидание отпускания...
	rjmp 	PC-1
	rjmp 	SetTime 		;начать настройку...
	;прошла минута?
	in 		temp,TCNT0 		;считать таймер	
	cp 		temp,mark240 	;уменьшить счетчик1 ?
	brne 	Start 			;рано, вернуться в начало
	subi 	mark240,-240 	;да, увеличить границу 
	dec 	counter1 		;уменьшить счетчик2 ?
	brne 	Start 			;рано, вернуться в начало
	ldi 	counter1,200 	;да, рестарт счетчик1
	dec 	counter2 		;есть еще итерации?
	brne 	Start 			;да, вернуться в начало
	;рестарт регистров задержки
	ldi 	counter2,3		;в counter1 только что загружено 200 
	;увеличение времени
	inc 	minutes  		;увеличим минуты
	cpi 	minutes,60 		;60?
	brne 	Start 			
	clr 	minutes 		;тогда сбросить минуты... 
	inc 	hours 			;...и увеличить часы
	cpi 	hours,24 		;24?
	brne 	Start
	clr 	hours			;тогда сбросить часы
	rjmp 	Start 			;повторить секцию измерения...
;-------------------------режим настройки---------------------------------------
SetTime:
	;вывод
	rcall 	GetDecNum  
	rcall 	Display	
	;проверка "HRS"
	sbic 	PinD,5		 	;нажата "HRS"?
	rjmp 	PC+7 			
	inc 	hours  			;да, ++часы
	cpi 	hours,24 		;много часов?
	brne 	PC+2
	clr 	hours 			;да -> сбросить часы
	sbis 	PinD,5 			;ожидание отпускания...
	rjmp 	PC-1
	;проверка "MINS"
	sbic 	PinD,6 			;нажата "MINS"?
	rjmp 	PC+7
	inc 	minutes			;да, ++минуты
	cpi 	minutes,60 		;много минут?
	brne 	PC+2 		
	clr 	minutes 		;да -> сбросить минуты	
	sbis 	PinD,6 			;ожидание отпускания...
	rjmp 	PC-1 	
	;проверка "SET"
	sbic 	PinD,2 			;нажата "SET"?
	rjmp 	PC+8
	ldi 	mark240,240		;да, начать считать с начала
	ldi 	counter1,200
	ldi 	counter2,3
	sbi 	PortB,0 		;прекратить мигания
	sbis 	PinD,2 			;ожидание отпускания...
	rjmp 	PC-1
	rjmp 	Start-2	 		;выход из секции настройки на обнуление счетчика
	;прошло 0.5 сек?
	in 		temp,TCNT0 		;считать таймер
	cp 		temp,mark240 	;уменьшить счетчик3 ?
	brne 	SetTime 		;рано, вернуться в начало
	subi 	mark240,-240 	;да, увеличить границу
	dec 	counter3 		;есть еще итерации?
	brne 	SetTime 		;да, вернуться в начало
	;рестарт регистра задержки
	ldi 	counter3,5 		;0.5 сек
	;смена этапа мигания
	in 		temp,PinB 		;считать PB0
	ldi 	temp2,0b00000001
	eor 	temp,temp2 		;инвертировать PB0
	out 	PortB,temp 	 	;выдать PB0
	rjmp 	SetTime 		;повторить секцию настройки...










