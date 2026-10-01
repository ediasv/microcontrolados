; main.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 24/08/2020
; Este programa espera o usuário apertar a chave USR_SW1.
; Caso o usuário pressione a chave, o LED1 piscará a cada 0,5 segundo.

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
		
; Declarações EQU - Defines
;<NOME>         EQU <VALOR>
; ========================

; -------------------------------------------------------------------------------
; Área de Dados - Declarações de variáveis
		AREA  DATA, ALIGN=2
		; Se alguma variável for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a variável <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma variável de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posição da RAM		
TemperaturaAlvo		SPACE		2
TemperaturaAtual	SPACE		2
Contador			SPACE		2
		EXPORT TemperaturaAlvo	[DATA,SIZE=2]
		EXPORT TemperaturaAtual [DATA,SIZE=2]

; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo	
        EXPORT Start                ; Permite chamar a função Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma função externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; função <func>
		IMPORT  PLL_Init
		IMPORT  SysTick_Init
		IMPORT  SysTick_Wait1ms			
		IMPORT  GPIO_Init
        IMPORT  PortN_Output


; -------------------------------------------------------------------------------
; Função main()
Start  		
		BL PLL_Init                  ;Chama a subrotina para alterar o clock do microcontrolador para 80MHz
		BL SysTick_Init
		BL GPIO_Init                 ;Chama a subrotina que inicializa os GPIO
		
		;Carregar valores iniciais nas variáveis
		LDR 	R0, =TemperaturaAlvo
		MOV		R1, #22
		STRH 	R1,[R0]
		
		LDR	R0, =TemperaturaAtual
		MOV		R1, #10
		STRH	R1,[R0]

		LDR 	R0, =Contador
		MOV		R1, #166
		STRH 	R1,[R0]
	
MainLoop
		; dezena:  dado, ativa Q2, Wait1ms, desativa Q2, Wait1ms
		; unidade: dado, ativa Q1, Wait1ms, desativa Q1, Wait1ms
		; LEDs:    dado, ativa Q3, Wait1ms, desativa Q3, Wait1ms

		LDR   	R0, =Contador
		LDRH  	R1, [R0]
		SUBS  	R1, R1, #1
		STRH  	R1, [R0]
		BNE   	MainLoop                 ; ainda não completou 1 s

		MOV   	R1, #166
		STRH  	R1, [R0]             ; reinicia o contador
		BL    	AtualizaTemperatura
		B     	MainLoop

AtualizaTemperatura
		; comparar temperatura alvo com atual e atualizar o 
		; valor da temperatura atual de acordo
		; também atualizar os leds do port N
		LDR		R0, =TemperaturaAtual
		LDR		R1, =TemperaturaAlvo
		LDRH	R4, [R0]
		LDRH	R5, [R1]
		
		CMP 	R4, R5
		BLT		Aquecer 	; atual < alvo
		BGT		Resfriar	; atual > alvo
		B 		Equilibrio
		
Aquecer
		ADD 	R4, R4, #1
		; TODO: atualizar leds 
		B 		MainLoop

Resfriar
		SUB 	R4, R4, #1
		; TODO: atualizar leds 
		B		MainLoop

Equilibrio
		; TODO: atualizar leds 
		B 		MainLoop

; -------------------------------------------------------------------------------------------------------------------------
; Fim do Arquivo
; -------------------------------------------------------------------------------------------------------------------------	
    ALIGN                        ;Garante que o fim da seção está alinhada 
    END                          ;Fim do arquivo
