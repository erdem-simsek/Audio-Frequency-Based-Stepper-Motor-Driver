
;LABEL		DIRECTIVE		VALUE		COMMENT
			AREA		routine,		CODE, READONLY
			THUMB
			
			EXPORT Convrt ; make it available to other sources
			EXTERN	Nokia_Init			
			EXTERN	SetXY
			EXTERN	OutStrLCD
			EXTERN	OutCharLCD
			EXTERN	ClearLCD
			
		; X values 0-83 (decimal) passed via R0
		; Y values 0-5	(decimal) passed via R1 --- they are set in main 
		;R4 holds the value, 
		;R4 is converted to ASCII and then printed to LCD in specified coordinate
				
Convrt 		PROC
			PUSH 		{LR}
			PUSH 		{R0-R10}
			MOV 		R9,#10
			
loop		SDIV		R2,R4,R9 	; R2=R4/10
			MUL			R3,R2,R9	; R3=R2*10
			SUB			R4,R3		; R4=R4-R3  ; R4 has a decimal digit of the number
			ADD			R5,R4,#0x30 ;char character
			SUB			R0,#6
			B display
return		
			MOVS		R4,R2
			BNE			loop
			B 			finish
			
display
			
			BL SetXY
			BL OutCharLCD
			B return
			
finish		POP{R0-R10}
			POP 		{LR}
			BX 			LR ; return
			ENDP
			END