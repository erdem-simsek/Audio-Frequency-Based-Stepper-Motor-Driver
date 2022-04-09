
;LABEL		DIRECTIVE	VALUE		COMMENT
; ADC Registers
; ADC0 base address EQU 0x40038000
ADC0_ACTSS 		EQU 0x40038000 ; Sample sequencer (ADC0 base address)
ADC0_RIS 		EQU 0x40038004 ; Interrupt status
ADC0_IM			EQU 0x40038008 ; Interrupt select
ADC0_EMUX 		EQU 0x40038014 ; Trigger select
ADC0_PSSI 		EQU 0x40038028 ; Initiate sample
ADC0_SSMUX3 	EQU 0x400380A0 ; Input channel select
ADC0_SSCTL3 	EQU 0x400380A4 ; Sample sequence control
ADC0_SSFIFO3 	EQU 0x400380A8 ; Channel 3 results
ADC0_PC 		EQU 0x40038FC4 ; Sample rate
ADC0_ISC		EQU 0x4003800C ;

NVIC_ST_CTRL	EQU 0xE000E010
NVIC_ST_RELOAD  EQU 0xE000E014
NVIC_ST_CURRENT EQU 0xE000E018
SHP_SYSPRI3		EQU 0xE000ED20

; 0x7D0 = 2000 -> 2000*250 ns = 500mus 7a120
RELOAD_VALUE	EQU 0x000007D0
Location		EQU 0x20000400 


				AREA initisr , CODE, READONLY, ALIGN=2
				THUMB
				EXPORT initsystick
				
				
;adjust systick
initsystick PROC
				PUSH {LR}
				LDR R1 , =NVIC_ST_CTRL	;disable first
				MOV R0 , #0
				STR R0 , [ R1 ]
				LDR R1 , =NVIC_ST_RELOAD	;set period
				LDR R0 , =RELOAD_VALUE
				STR R0 , [ R1 ]
				LDR R1 , =NVIC_ST_CURRENT	;current value is set to reload value
				STR R0 , [ R1 ]		
				LDR R1 , =SHP_SYSPRI3
				MOV R0 , #0x80000000
				STR R0 , [ R1 ]
				LDR R1 , =NVIC_ST_CTRL		;enable systick 
				MOV R0 , #0x3
				STR R0 , [ R1 ]	
				POP {LR}
				BX LR
				ENDP
;ISR of systick
;checks which pin of motor is energized, sets the next one, resets the current one
				EXPORT My_ST_ISR
My_ST_ISR 		PROC
				PUSH  		{LR}
				PUSH		{R0-R10}
				LDR 		R3,=NVIC_ST_CTRL ;disable systick
				MOV 		R2,#0
				STR 		R2,[R3]
				
				LDR 		R3, =ADC0_RIS 	; interrupt address
				LDR 		R5, =ADC0_SSFIFO3 ; result address
				LDR 		R2, =ADC0_PSSI 	; sample sequence initiate address
				LDR 		R6, =ADC0_ISC
				MOV			R1,#255
				LDR			R7,=Location
				
				; initiate sampling by enabling sequencer 3 in ADC0_PSSI
Smpl 			LDR 		R0, [R2]
				ORR 		R0, R0, #0x08 ; set bit 3 for SS3
				STR 		R0, [R2]
				; check for sample complete (bit 3 of ADC0_RIS set)
loop 			LDR 		R0, [R3]
				ANDS 		R0, R0, #8
				BEQ 		loop
				;branch fails if the flag is set so data can be read and flag is cleared
				LDR 		R4,[R5]	;R4 holds the binary equivalent of the measured voltage
				SUB			R4,R4,#0x4C5 ; 1.25 V offset
				LSL			R4,#4        ; to not lose precision shift left 4
				STR			R4,[R7],#4
				
				MOV 		R0, #8
				STR 		R0, [R6] ; clear flag
				NOP
				NOP
				NOP
				SUBS		R1,#1;	
				BNE 		Smpl
isrend			NOP
				
				LDR 	R3,=NVIC_ST_RELOAD ; store reload value
				LDR 	R2,=RELOAD_VALUE
				STR 	R2,[R3]
				LDR R1 , =NVIC_ST_CTRL		;enable systick 
				MOV R0 , #0x3
				STR R0 , [ R1 ]
				
				POP			{R0-R10}
				POP 		{LR}
				BX 			LR 
				ENDP

