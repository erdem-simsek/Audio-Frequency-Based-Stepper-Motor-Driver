
;LABEL			DIRECTIVE	VALUE		COMMENT
Location		EQU 0x20000400 
Status_ADR		EQU	0x20000300	;Sets the direction and 0x01=CW, 0x00=CCW, 0x20=Slow, 0x40=Normal, 0x80=Fast
PBout_data 		EQU 0x4000503C ; data address to B[0,3] pins
MSG				EQU	0x20000200
			
				AREA main, CODE, READONLY
				THUMB	
				EXPORT __main
				EXTERN	init_mic
				EXTERN  init_stepmotor
				EXTERN  buttons_init
				EXTERN  decision
				EXTERN	arm_cfft_q15
				EXTERN	arm_cfft_sR_q15_len256
				EXTERN Convrt
				
				;Screen functions
				EXTERN	Nokia_Init			
				EXTERN	SetXY
				EXTERN	OutStrLCD
				EXTERN	OutCharLCD
				EXTERN	ClearLCD	

present_freq	DCB		"FREQ:",0x04
present_amp		DCB		"AMPL:",0x04					
threshold		DCB		"AMP-TH:100    FRQ-1-TH:200HzFRQ-2-TH:600Hz",0x04		
					
__main			PROC
;***************************************************************************************
;Initialization part
				BL init_mic
				BL init_stepmotor
				BL buttons_init
				BL Nokia_Init
				CPSIE I
				LDR			R1,=Status_ADR		
				MOV			R0,#0x41
				STR			R0,[R1]			;initially step motor set to CW direction and normal speed
;****************************************************************************************
;FFT calculation
;FFT calculation couldn't be done correctly
loop		
				LDR	R0,=arm_cfft_sR_q15_len256
				LDR R1,=0x20000400
				MOV	R2,#0
				MOV R3,#1
				BL	arm_cfft_q15
				
				MOV R8,#0
				MOV R7,#0
				MOV R4,#0 ; holds highest magnitude
				MOV R0,#255 ; counter
				LDR R5,=0xFFFF0000
				LDR R6,=0x0000FFFF
				MOV R2,#0  ; highest index
				LDR R1,=0x20000400
				
search			LDR R3,[R1],#4
				AND R7,R3,R5 ;real part
				AND R8,R3,R6 ;imaginary part
				ROR R7,#16
				ROR R8,#16
				LSR R8,#16
				MUL R8,R8
				MUL R7,R7
				ADD R3,R7,R8  ; magnitude^2
				UDIV R3,R3
				CMP R3,R4  ; compared to previous value
				BLS skip   ; if current value is lower than highest magnitude skip
				MOVS R4,R3 ; store current magnitude as highest
				MOVS R2,R0 ; if it is higher previous value store the index.
				
skip			
				SUBS R0,#1
				BNE search
				
				LDR R1,=0x20000400
				ADD R1,R2 ;highest value index
				LDR R4,[R1] 
				LDR R5,=0xFFFF0000
				LDR R6,=0x0000FFFF
				
				AND R0,R4,R5 ;real part
				AND R1,R4,R6 ;imaginary part
				ROR R0,#16
				ROR R1,#16
				MOVS R8,R0  ; R8 holds the current frequency
				MUL R1,R1
				MUL R0,R0
				ADD R3,R0,R1  ; magnitude^2
				UDIV R7,R3,R3 ;R7 holds current magnitude (sqrt of magnitude^2)
				
;***************************************************************************************
;Decision Part according yo amplitude and frequency levels
				;MOV R7,#90 ; R7= amplitude level
				;MOV	R8,#950 ; R8=frequency level 
				NOP
				NOP
				NOP
				BL decision
;***************************************************************************************				
;LCD part
				; X values 0-83 (decimal) passed via R0
				; Y values 0-5	(decimal) passed via R1
				;BL ClearLCD
				NOP
				NOP
				MOV R0,#0  ;X axis
				MOV R1,#0	;Y axis
				BL SetXY   
				LDR R5,=threshold ;threhold values are displayed
				BL OutStrLCD
				NOP
				NOP
				MOV R0,#0  ;X axis
				MOV R1,#3	;Y axis
				BL SetXY
				LDR R5,=present_amp ; amplitude message is displayed
				BL OutStrLCD
				NOP
				NOP
				MOVS R4,R7
				MOV R1,#3	;Y axis
				MOV R0,#80  ;X axis end
				BL Convrt  ; amplitude value sent to Convrt for displaying its digits
				
				MOV R0,#0  ;X axis
				MOV R1,#4	;Y axis
				BL SetXY
				LDR R5,=present_freq  ;freq message is displayed
				BL OutStrLCD
				NOP
				NOP
				MOVS R4,R8
				MOV R1,#4	;Y axis
				MOV R0,#80  ;X axis end
				BL Convrt ; frequency value sent to Convrt for displaying its digits
				B	loop



				ENDP
				ALIGN
				END