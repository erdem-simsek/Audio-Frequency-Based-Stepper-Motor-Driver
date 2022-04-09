;LABEL		DIRECTIVE	VALUE		COMMENT
GPIO_PORTB_DATA	 	EQU 0x400053FC
GPIO_PORTB_DIR 		EQU 0x40005400
GPIO_PORTB_AFSEL 	EQU 0x40005420
GPIO_PORTB_PCTL 	EQU 0x4000552C
GPIO_PORTB_DEN 		EQU 0x4000551C
SYSCTL_RCGCGPIO 	EQU 0x400FE608	
			
					AREA initstep , READONLY, CODE, ALIGN=2
					THUMB
					EXTERN	GPTM_init
					EXPORT	init_stepmotor
;starts the setup of stepmotor
init_stepmotor		PROC
					PUSH {LR}
					LDR R1 , =SYSCTL_RCGCGPIO	;start clock for port B
					LDR R0 , [ R1 ]
					ORR R0 , R0 , #0x2
					STR R0 , [ R1 ]
					NOP
					NOP
					NOP 
					NOP
					LDR R1 , =GPIO_PORTB_DIR 	;pins pb0-pb4 are set to output
					LDR R0 , [ R1 ]
					BIC R0 , #0xFF		;reset prev. settings of portB
					ORR R0 , #0x0F		;00001111				
					STR R0 , [ R1 ]				
					LDR R1 , =GPIO_PORTB_AFSEL	;no alternate function
					LDR R0 , [ R1 ]
					BIC R0 , #0xFF
					STR R0 , [ R1 ]				
					LDR R1 , =GPIO_PORTB_PCTL	;no alternate function
					LDR R0 , [ R1 ]
					BIC R0 , #0xFF
					STR R0 , [ R1 ]
					LDR R1 , =GPIO_PORTB_DEN	;pins are digital
					LDR R0 , [ R1 ]
					ORR R0 , #0xFF
					STR R0 , [ R1 ] 				
					LDR R1 , =GPIO_PORTB_DATA	;set first pin high
					LDR R0 , [ R1 ]
					MOV R0 , #0x01
					STR R0 , [ R1 ]
					BL GPTM_init
					POP {LR}
					BX LR
					ENDP
					