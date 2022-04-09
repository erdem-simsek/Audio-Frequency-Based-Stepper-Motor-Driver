;LABEL			DIRECTIVE	VALUE		COMMENT

GPIO_PORTF_RIS	EQU 0x40025414	;raw interrupt status
GPIO_PORTF_ICR  EQU 0x4002541C	; Interrupt Clear
GPIO_PORTF_DATA	EQU	0x400253FC	; Port F Data
Status_ADR		EQU	0x20000300
	
				AREA normalmode , READONLY, CODE
				THUMB				
				EXPORT	decision	
; CW direction -> SW1,,,, CCW direction -> SW2
;Sets the direction and 0x01=CW, 0x00=CCW, 0x20=Slow, 0x40=Normal, 0x80=Fast
;PF1=red, PF2=Blue,PF3=green
decision 		PROC
				PUSH	{LR}
				PUSH	{R0-R5}
				LDR		R4,=Status_ADR		;R1 holds the memory address of the status data
				LDR		R1,=GPIO_PORTF_RIS		;check if sw1 is pressed
direction_deci	LDR 	R0, [R1]
				CMP		R0,#0x01		;to check if sw2 pressed
				BEQ 	CCW				; if pressed,go CCW
				CMP		R0,#0x10		;to check if sw1 pressed
				BEQ 	CW				; if pressed,go CW
				B		ACK_INT			

CW				LDRB	R2,[R4]			;R2=[Status_ADR]
				MOV		R0,#0x01
				BFI 	R2,R0,#0,#4		;R2[3:0]=R0[3:0]
				STRB	R2,[R4]			;update the status data as 0xY1
				B		ACK_INT
			
CCW				LDRB	R2,[R4]			;R2=[Status_ADR]
				MOV		R0,#0x00
				BFI 	R2,R0,#0,#4		;R2[3:0]=R0[3:0]
				STRB	R2,[R4]			;update the status data as 0xY0
				B		ACK_INT

			;Acknowledge the interrupt
ACK_INT			LDR 	R3, =GPIO_PORTF_ICR
				MOV 	R0,#0xFF
				STR		R0,[R3]		;clear interrupt flag for PortF (R3=GPIO_PORTF_ICR)
				
				
ampl_decision   CMP		R7,#100  ;amplitude threshold
				BHI     freq_decision	;if higher than amplitude threshold go to freq decision		
				LDR		R0,=GPIO_PORTF_DATA
				LDR		R2,[R0]			;get all port f data
				AND		R2,#0x11      ;clear PF1,PF2,PF3 ; turn off led
				STR		R2,[R0]
				B return
				
freq_decision	CMP		R8,#200			; lower freq threshold
				BLS		area1
				CMP		R8,#600			;;higher threshold
				BHI		area3			
				
area2			LDRB	R2,[R4]			;R2=[Status_ADR]----normal speed	
				MOV		R0,#0x40
				BFC     R2,#4,#4        ;clear R2[7:4]
				ORR 	R2,R0			;R2[7:4]=R0[3:0]
				STRB	R2,[R4]			;update the status data as 0x4Y
				
				LDR		R0,=GPIO_PORTF_DATA
				LDR		R2,[R0]			;get all port f data
				ORR		R2,#0x08        ;turn on PF3-green
				STR		R2,[R0]
				B		return
				
area1			LDRB	R2,[R4]			;R2=[Status_ADR]----slow speed	
				MOV		R0,#0x20
				BFC     R2,#4,#4        ;clear R2[7:4]
				ORR 	R2,R0			;R2[7:4]=R0[3:0]
				STRB	R2,[R4]			;update the status data as 0x2Y
				
				LDR		R0,=GPIO_PORTF_DATA
				LDR		R2,[R0]			;get all port f data
				ORR		R2,#0x02        ;turn on PF1-red
				STR		R2,[R0]

				B		return
				
area3			LDRB	R2,[R4]			;R2=[Status_ADR]----fast speed	
				MOV		R0,#0x80
				BFC     R2,#4,#4        ;clear R2[7:4]
				ORR 	R2,R0			;R2[7:4]=R0[3:0]
				STRB	R2,[R4]			;update the status data as 0x8Y
				
				LDR		R0,=GPIO_PORTF_DATA
				LDR		R2,[R0]			;get all port f data
				ORR		R2,#0x04        ;turn on PF2-blue
				STR		R2,[R0]
				B		return
				
return			POP	{R0-R5}
				POP		{LR}
				BX 		LR 			; return			
				ENDP			
				ALIGN
				END
