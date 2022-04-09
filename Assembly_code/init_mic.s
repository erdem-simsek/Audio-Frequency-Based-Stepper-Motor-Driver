;LABEL			  DIRECTIVE		VALUE		COMMENT
;GPIO PORTE registers
GPIO_PORTE_DATA 	EQU 		0x400243FC ; data address to all pins
GPIO_PORTE_DIR 		EQU 		0x40024400
GPIO_PORTE_AFSEL 	EQU 		0x40024420
GPIO_PORTE_DEN 		EQU 		0x4002451C
GPIO_PORTE_AMSEL	EQU 		0x40024528
GPIO_PORTE_PCTL		EQU 		0x4002452C
	
; ADC Registers
; ADC0 base address EQU 0x40038000
ADC0_ACTSS 			EQU 		0x40038000 ; Sample sequencer (ADC0 base address)
ADC0_RIS 			EQU 		0x40038004 ; Interrupt status
ADC0_IM				EQU 		0x40038008 ; Interrupt select
ADC0_EMUX 			EQU 		0x40038014 ; Trigger select
ADC0_PSSI 			EQU 		0x40038028 ; Initiate sample
ADC0_SSMUX3 		EQU 		0x400380A0 ; Input channel select
ADC0_SSCTL3 		EQU 		0x400380A4 ; Sample sequence control
ADC0_SSFIFO3 		EQU 		0x400380A8 ; Channel 3 results
ADC0_PC 			EQU 		0x40038FC4 ; Sample rate

;System Clock registers
SYSCTL_RCGCGPIO 	EQU 		0x400FE608
RCGCADC 			EQU 		0x400FE638 ; ADC clock register

;***************************************************************
; Program section					      
;***************************************************************
;LABEL		DIRECTIVE	VALUE			COMMENT
			AREA 		|. text| , READONLY, CODE, ALIGN=2
			THUMB
			EXTERN initsystick
			EXPORT init_mic
				
init_mic	PROC
			PUSH {LR}
			;firstly configure GPIO to reach ADC
			LDR 		R1 , =SYSCTL_RCGCGPIO
			LDR 		R0 , [R1]
			ORR 		R0 , R0 , #0x10
			STR 		R0 , [R1]		;turn on clock for port E
			NOP
			NOP
			NOP 						; let GPIO clock stabilize
			
			;Configuration of ADC
			LDR 		R1, =RCGCADC ; Turn on ADC clock
			LDR 		R0, [R1]
			ORR 		R0, R0, #0x01 ; set bit 0 to enable ADC0 clock
			STR 		R0, [R1]
			NOP
			NOP
			NOP 		; Let clock stabilize
			
			LDR 		R1 , =GPIO_PORTE_AFSEL
			LDR 		R0 , [R1]				;GPIO Alternate Function Select
			ORR 		R0 , #0x08				;
			STR			R0 , [R1]				;set alternate functions to 1 for PE3
			
			;Since PE3 has only one alternate function i.e. AIN0
			;LDR 		R1 , =GPIO_PORTE_PCTL
			
			LDR 		R1 , =GPIO_PORTE_DIR 	
			LDR			R0 , [R1]
			BIC 		R0 , #0x08				;
			STR 		R0 , [R1]				;set pin 3 as INPUT
			
			; Disable digital on PE3
			LDR 		R1, =GPIO_PORTE_DEN
			LDR 		R0, [R1]
			BIC 		R0, R0, #0x08 ; clear bit 3 to disable digital on PE3
			STR 		R0, [R1]
			
			LDR 		R1 , =GPIO_PORTE_AMSEL 	
			LDR			R0 , [R1]
			ORR 		R0 , #0x08				;
			STR 		R0 , [R1]				;connect pin 3 to ADC 
			
			;ADC Setup
			; Disable sequencer while ADC setup
			LDR 		R1, =ADC0_ACTSS
			LDR 		R0, [R1]
			BIC 		R0, R0, #0x08 ; clear bit 3 to disable seq 3
			STR 		R0, [R1]
			
			; Select trigger source
			LDR 		R1, =ADC0_EMUX
			LDR 		R0, [R1]
			BIC 		R0, R0, #0xF000 ; clear bits 15:12 to select SOFTWARE
			STR 		R0, [R1] ; trigger
			
			; Select input channel
			LDR 		R1, =ADC0_SSMUX3
			LDR 		R0, [R1]
			BIC 		R0, R0, #0x000F ; clear bits 3:0 to select AIN0
			STR 		R0, [R1]
			
			; Config sample sequence
			LDR 		R1, =ADC0_SSCTL3 ;RIS, polling method
			LDR 		R0, [R1]
			ORR 		R0, R0, #0x06 ; set bits 2:1 (IE0, END0)
			STR 		R0, [R1]
			
			; Set sample rate
			LDR 		R1, =ADC0_PC
			LDR 		R0, [R1]
			ORR 		R0, R0, #0x01 ; set bits 3:0 to 1 for 125k sps
			STR 		R0, [R1]
			
			; Done with setup, enable sequencer
			LDR 		R1, =ADC0_ACTSS
			LDR 		R0, [R1]
			ORR 		R0, R0, #0x08 ; set bit 3 to enable seq 3
			STR 		R0, [R1] ; sampling enabled but not initiated yet
			
			BL	initsystick
			POP {LR}
			BX	LR
			ENDP			
			ALIGN
			END
			
