;GPIO Registers
GPIO_PORTF_DATA			EQU	0x400253FC	; Port F Data
GPIO_PORTF_IM      		EQU 0x40025410	; Interrupt Mask
GPIO_PORTF_DIR   		EQU 0x40025400	; Port Direction
GPIO_PORTF_AFSEL 		EQU 0x40025420	; Alt Function enable
GPIO_PORTF_DEN   		EQU 0x4002551C	; Digital Enable
GPIO_PORTF_AMSEL 		EQU 0x40025528	; Analog enable
GPIO_PORTF_PCTL  		EQU 0x4002552C	; Alternate Functions
GPIO_PORTF_PUR  		EQU 0x40025510	; Pull Up
GPIO_PORTF_IS			EQU	0x40025404	;edge level select
GPIO_PORTF_IBE			EQU 0x40025408	;both edges or not
GPIO_PORTF_IEV			EQU 0x4002540C	;falling or rising edges
GPIO_PORTF_RIS			EQU 0x40025414	;raw interrupt status
GPIO_PORTF_LOCK			EQU	0x40025520
GPIO_PORTF_CR			EQU	0x40025524
GPIO_PORTF_ICR  		EQU 0x4002541C	; Interrupt Clear
NVIC_PRI0_R				EQU	0xE000E400
NVIC_EN0_R				EQU	0xE000E100
	
;System Registers
SYSCTL_RCGCGPIO  		EQU 0x400FE608	; GPIO Gate Control

	
				AREA but , READONLY, CODE
				THUMB				
				EXPORT	buttons_init				
				
;gpio interrupts are adjusted. pf4 and pf0 are in pull up and falling edge detect mode. PF1,PF2,PF3 are configured as
;output.
buttons_init	PROC
				PUSH	{R0-R7}
				LDR 	R1, =SYSCTL_RCGCGPIO	; start GPIO clock for port F
				LDR 	R0, [R1]                   
				ORR 	R0, #0x20					
				STR 	R0, [R1]                   
				NOP								; allow clock to settle
				NOP
				NOP	
				LDR		R1,=GPIO_PORTF_LOCK		; unlock commit register
				MOV32 	R0, #0x4C4F434B				
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_CR		;make PF0 configurable
				MOV 	R0, #0x1								
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_LOCK		; lock commit register again
				MOV 	R0, #0x0				
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_DIR		; make PF0 and PF4 pins input
				MOV 	R0, #0x00
				ORR		R0,#0x0E          		;make PF1,PF2,PF3 pins output 
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_AFSEL	; disable alt funct 
				MOV 	R0, #0x00				;
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_DEN		; enable digital I/O at PF0,1,2,3,4
				MOV 	R0, #0x1F				;
				STR		R0,[R1]					
				LDR		R1,=GPIO_PORTF_PCTL 	; no alt funct
				MOV 	R0, #0x0					
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_PUR		; enable pull up at pins
				MOV 	R0, #0x1F				
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_AMSEL	; disable analog functionality
				LDR		R0, [R1]
				BIC 	R0, #0xFF				
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_IM		; interrupts are masked
				MOV 	R0, #0x0				
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_IS		; edge sensitive
				MOV 	R0, #0x0				
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_IBE		; not both edges
				MOV 	R0, #0x0				
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_IEV		; falling edges
				LDR		R0, [R1]
				BIC 	R0, #0x11				
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_RIS		; clear raw interrupt status
				MOV 	R0, #0x0				
				STR		R0,[R1]
				LDR		R1,=GPIO_PORTF_IM		; interrupts are unmasked (enabled)
				MOV 	R0, #0x11				; for now they are disabled
				STR		R0,[R1]
				
				POP		{R0-R7}
				BX 		LR
				ENDP
				ALIGN
				END