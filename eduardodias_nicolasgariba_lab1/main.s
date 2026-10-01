; main.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 24/08/2020
; Este programa espera o usu�rio apertar a chave USR_SW1.
; Caso o usu�rio pressione a chave, o LED1 piscar� a cada 0,5 segundo.

; -------------------------------------------------------------------------------
        THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
		
; Declara��es EQU - Defines
;<NOME>         EQU <VALOR>
; ========================

; -------------------------------------------------------------------------------
; �rea de Dados - Declara��es de vari�veis
		AREA  DATA, ALIGN=2
		; Se alguma vari�vel for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a vari�vel <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma vari�vel de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posi��o da RAM		
TemperaturaAlvo		SPACE		2
TemperaturaAtual	SPACE		2
Contador			SPACE		2
		EXPORT TemperaturaAlvo	[DATA,SIZE=2]
		EXPORT TemperaturaAtual [DATA,SIZE=2]

; -------------------------------------------------------------------------------
; �rea de C�digo - Tudo abaixo da diretiva a seguir ser� armazenado na mem�ria de 
;                  c�digo
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma fun��o do arquivo for chamada em outro arquivo	
        EXPORT Start                ; Permite chamar a fun��o Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma fun��o externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; fun��o <func>
		IMPORT  PLL_Init
		IMPORT  SysTick_Init
		IMPORT  SysTick_Wait1ms			
		IMPORT  GPIO_Init
        IMPORT  PortN_Output
		IMPORT  PAT_AllOff
		IMPORT  PAT_Data_Output
		IMPORT  PAT_Dezena_On
		IMPORT  PAT_Unidade_On
		IMPORT  PAT_LEDs_On


; -------------------------------------------------------------------------------
; Fun��o main()
Start  		
		BL PLL_Init                  ;Chama a subrotina para alterar o clock do microcontrolador para 80MHz
		BL SysTick_Init
		BL GPIO_Init                 ;Chama a subrotina que inicializa os GPIO
		
		;Carregar valores iniciais nas vari�veis
		LDR 	R0, =TemperaturaAlvo
		MOV		R1, #22
		STRH 	R1,[R0]
		
		LDR		R0, =TemperaturaAtual
		MOV		R1, #10
		STRH	R1,[R0]

		LDR 	R0, =Contador
		MOV		R1, #166
		STRH 	R1,[R0]
	
MainLoop
		; dezena:  dado, ativa Q2, Wait1ms, desativa Q2, Wait1ms
		; unidade: dado, ativa Q1, Wait1ms, desativa Q1, Wait1ms
		; LEDs:    dado, ativa Q3, Wait1ms, desativa Q3, Wait1ms
		
		; ---- separar dezena e unidade da temperatura atual ----
		LDR		R0, =TemperaturaAtual
		LDRH	R1, [R0]
		MOV		R2, #10
		UDIV	R4, R1, R2			; R4 = dezena
		MLS		R5, R4, R2, R1		; R5 = unidade = R1 - R4*10
		LDR		R6, =Tabela7Seg

		; ---- dezena: dado, ativa DS1, 1 ms, desativa, 1 ms ----
		LDRB	R0, [R6, R4]
		BL		PAT_AllOff
		BL		PAT_Data_Output
		BL		PAT_Dezena_On
		MOV		R0, #1
		BL		SysTick_Wait1ms
		BL		PAT_AllOff
		MOV		R0, #1
		BL		SysTick_Wait1ms

		; ---- unidade: dado, ativa DS2, 1 ms, desativa, 1 ms ----
		LDRB	R0, [R6, R5]
		BL		PAT_AllOff
		BL		PAT_Data_Output
		BL		PAT_Unidade_On
		MOV		R0, #1
		BL		SysTick_Wait1ms
		BL		PAT_AllOff
		MOV		R0, #1
		BL		SysTick_Wait1ms

		; ---- LEDs: setpoint em bin�rio, ativa LEDs, 1 ms, desativa, 1 ms ----
		LDR		R0, =TemperaturaAlvo
		LDRH	R0, [R0]
		BL		PAT_AllOff
		BL		PAT_Data_Output
		BL		PAT_LEDs_On
		MOV		R0, #1
		BL		SysTick_Wait1ms
		BL		PAT_AllOff
		MOV		R0, #1
		BL		SysTick_Wait1ms
		
		; =========================
		LDR   	R0, =Contador
		LDRH  	R1, [R0]
		SUBS  	R1, R1, #1
		STRH  	R1, [R0]
		BNE   	MainLoop                 ; ainda n�o completou 1 s

		MOV   	R1, #166
		STRH  	R1, [R0]             ; reinicia o contador
		BL    	AtualizaTemperatura
		B     	MainLoop

AtualizaTemperatura
		; comparar temperatura alvo com atual e atualizar o 
		; valor da temperatura atual de acordo
		; tamb�m atualizar os leds do port N
		LDR		R0, =TemperaturaAtual
		LDR		R1, =TemperaturaAlvo
		LDRH	R4, [R0]
		LDRH	R5, [R1]
		
		CMP 	R4, R5
		BLT		Aquecer 	; atual < alvo
		BGT		Resfriar	; atual > alvo
		B 		Equilibrio
AtualizaAtual
		LDR		R0, =TemperaturaAtual
		STRH	R4, [R0]
		B MainLoop
		
Aquecer
		ADD 	R4, R4, #1
		; PN1 acende
		; PN0 apaga
		MOV 	R0, #2_00000001
		BL		PortN_Output
		B 		AtualizaAtual

Resfriar
		SUB 	R4, R4, #1
		; PN1 apaga
		; PN0 acende
		MOV 	R0, #2_00000010
		BL 		PortN_Output
		B		AtualizaAtual

Equilibrio
		; PN1 acende
		; PN0 acende
		MOV 	R0, #2_00000011
		BL		PortN_Output
		B 		MainLoop

; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	


; Indice:      0     1    2    3      4     5     6     7     8     9 
Tabela7Seg
        DCB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

; -------------------------------------------------------------------------------------------------------------------------
	
	ALIGN                        ;Garante que o fim da se��o est� alinhada 
    END                          ;Fim do arquivo
