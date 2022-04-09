
; This uses Channel 0, and a 1MHz Timer Clock (_TAPR = 15 )

;Nested Vector Interrupt Controller registers
NVIC_EN0_INT19		EQU 0x00080000 ; Interrupt 19 enable
NVIC_EN0			EQU 0xE000E100 ; IRQ 0 to 31 Set Enable Register
NVIC_PRI4			EQU 0xE000E410 ; IRQ 16 to 19 Priority Register
	
; 16/32 Timer Registers
TIMER0_CFG			EQU 0x40030000
TIMER0_TAMR			EQU 0x40030004
TIMER0_CTL			EQU 0x4003000C
TIMER0_IMR			EQU 0x40030018
TIMER0_RIS			EQU 0x4003001C ; Timer Interrupt Status
TIMER0_ICR			EQU 0x40030024 ; Timer Interrupt Clear
TIMER0_TAILR		EQU 0x40030028 ; Timer interval
TIMER0_TAPR			EQU 0x40030038
TIMER0_TAR			EQU	0x40030048 ; Timer register
	

;System Registers
SYSCTL_RCGCTIMER 	EQU 0x400FE604 ; GPTM Gate Control

;---------------------------------------------------
VALUE_1				EQU	0x0000C350	;50000
VALUE_2				EQU	0x000061A8	;25000
VALUE_3				EQU	0x000030D4	;12500
Status_ADR			EQU	0x20000300	
PBout_data 			EQU 0x4000503C ; data address to B[0,3] pins
;---------------------------------------------------
					
					AREA 	routines, CODE, READONLY
					THUMB
					EXPORT 	My_Timer0A_Handler
					EXPORT	GPTM_init
					
;---------------------------------------------------					
My_Timer0A_Handler	PROC
					PUSH	{LR}
					PUSH	{R0-R5}
					LDR 	R2, =PBout_data
					LDR		R1,=Status_ADR
					LDR		R0,[R1]		;R0=Status_data
					AND		R0,#0x0F    ;isolate R0[3:0]
					
					CBZ		R0,CCW		;if Status_data ==0 set CCW mode
					
					CMP		R0,#0x01 	;if Status_data ==1 Set CW mode
					BEQ		CW
									

CW					LDR 	R0,[R2]
					CMP		R0,#8  	
					BEQ		except8
					LSL		R0,#1
					STR		R0,[R2]
					B 		speed
except8				MOV 	R0,#1
					STR		R0,[R2]					
					B 		speed
					
CCW					LDR 	R0,[R2]
					CMP		R0,#1
					BEQ		except1
					LSR		R0,#1
					STR		R0,[R2]
					B 		speed
except1				MOV 	R0,#8
					STR		R0,[R2]
					B 		speed
			
		 
speed				
			
				; now set the time out period
					LDR		R1,=Status_ADR
					LDR		R0,[R1]		;R0=Status_data
;check the speed area					
					MOV 	R3,#0x20		;Checking the slow if the slow bit is set
					ANDS 	R3,R0			;R0=Status_data
					BNE		area1			;if it is set to slow-area1
					
					MOV 	R3,#0x80		;Checking the slow if the fast bit is set
					ANDS 	R3,R0			;R0=Status_data
					BNE		area3			;if it is set to slow-area1					
					
area2				LDR 	R2,=VALUE_2
					B		ACK_SPEED		; normal speed
					
area3				LDR		R2,=VALUE_3			
					B		ACK_SPEED	
					;if it is set to slow
area1				LDR 	R2,=VALUE_1
					B		ACK_SPEED

ACK_SPEED			LDR 	R3,=TIMER0_TAILR
					STR 	R2,[R3]
					
					
return				LDR R1, =TIMER0_ICR ; clear timeout interrupt
					MOV R0, #0x01		;Timer A Time-Out (TATO) Interrupt bit
					STR R0, [R1]
					
					POP	{R0-R5}
					POP {LR}
					BX 	LR 
					ENDP
;---------------------------------------------------

GPTM_init	PROC
					
					LDR R1, =SYSCTL_RCGCTIMER ; Start Timer0
					LDR R2, [R1]
					ORR R2, R2, #0x01
					STR R2, [R1]
					NOP ; allow clock to settle
					NOP
					NOP
					LDR R1, =TIMER0_CTL ; disable timer during setup 
					LDR R2, [R1]
					BIC R2, R2, #0x01
					STR R2, [R1]
					
					LDR R1, =TIMER0_CFG ; set 16 bit mode
					MOV R2, #0x04
					STR R2, [R1]
					LDR R1, =TIMER0_TAMR
					MOV R2, #0x02 ; set to periodic, count down
					STR R2, [R1]
					LDR R1, =TIMER0_TAILR ; initialize match clocks
					LDR R2, =VALUE_1		
					STR R2, [R1]
					LDR R1, =TIMER0_TAPR
					MOV R2, #63 ; divide clock by 64 to
					STR R2, [R1] ; get 1us clocks
					LDR R1, =TIMER0_IMR ; enable timeout interrupt
					MOV R2, #0x01		;Timer A Time-Out (TATO) Interrupt Mask
					STR R2, [R1]
; Configure interrupt priorities
; Timer0A is interrupt #19.
; Interrupts 16-19 are handled by NVIC register PRI4.
; Interrupt 19 is controlled by bits 31:29 of PRI4.
; set NVIC interrupt 19 to priority 2
					LDR R1, =NVIC_PRI4
					LDR R2, [R1]
					AND R2, R2, #0x00FFFFFF ; clear interrupt 19 priority
					ORR R2, R2, #0x40000000 ; set interrupt 19 priority to 2
					STR R2, [R1]
; NVIC has to be enabled
; Interrupts 0-31 are handled by NVIC register EN0
; Interrupt 19 is controlled by bit 19
; enable interrupt 19 in NVIC
					LDR R1, =NVIC_EN0
					MOVT R2, #0x08 ; set bit 19 to enable interrupt 19
					STR R2, [R1]
; Enable timer
					LDR R1, =TIMER0_CTL
					LDR R2, [R1]
					ORR R2, R2, #0x03 ; set bit0 to enable
					STR R2, [R1] ; and bit 1 to stall on debug
					BX LR ; return
					ENDP
					ALIGN
					END