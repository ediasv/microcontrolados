; gpio.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 24/08/2020

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declarações EQU - Defines
; ========================
; Definições de Valores
BIT0	EQU 2_0001
BIT1	EQU 2_0010
; ========================
; Definições dos Registradores Gerais
SYSCTL_RCGCGPIO_R	 EQU	0x400FE608
SYSCTL_PRGPIO_R		 EQU    0x400FEA08

; Clock das portas A, B, J, N, P e Q
GPIO_CLOCK_MASK EQU 0x00007103

; ========================
; Definições dos Ports
; PORT J
GPIO_PORTJ_AHB_LOCK_R    	EQU    0x40060520
GPIO_PORTJ_AHB_CR_R      	EQU    0x40060524
GPIO_PORTJ_AHB_AMSEL_R   	EQU    0x40060528
GPIO_PORTJ_AHB_PCTL_R    	EQU    0x4006052C
GPIO_PORTJ_AHB_DIR_R     	EQU    0x40060400
GPIO_PORTJ_AHB_AFSEL_R   	EQU    0x40060420
GPIO_PORTJ_AHB_DEN_R     	EQU    0x4006051C
GPIO_PORTJ_AHB_PUR_R     	EQU    0x40060510	
GPIO_PORTJ_AHB_DATA_R    	EQU    0x400603FC
GPIO_PORTJ_AHB_DATA_BITS_R  EQU    0x40060000
GPIO_PORTJ_AHB_IM_R 		EQU	   0x40060410
GPIO_PORTJ_AHB_IS_R 		EQU	   0x40060404
GPIO_PORTJ_AHB_IBE_R 		EQU	   0x40060408
GPIO_PORTJ_AHB_IEV_R 		EQU	   0x4006040C
GPIO_PORTJ_AHB_ICR_R 		EQU	   0x4006041C
GPIO_PORTJ_AHB_MIS_R 		EQU	   0x40060418	
GPIO_PORTJ               	EQU    2_000000100000000
; PORT N
GPIO_PORTN_LOCK_R    	EQU    0x40064520
GPIO_PORTN_CR_R      	EQU    0x40064524
GPIO_PORTN_AMSEL_R   	EQU    0x40064528
GPIO_PORTN_PCTL_R    	EQU    0x4006452C
GPIO_PORTN_DIR_R     	EQU    0x40064400
GPIO_PORTN_AFSEL_R   	EQU    0x40064420
GPIO_PORTN_DEN_R     	EQU    0x4006451C
GPIO_PORTN_PUR_R     	EQU    0x40064510	
GPIO_PORTN_DATA_R    	EQU    0x400643FC
GPIO_PORTN_DATA_BITS_R  EQU    0x40064000
GPIO_PORTN               	EQU    2_001000000000000	
	
; PORT A - dados da PAT em PA4 a PA7
GPIO_PORTA_DATA_R    EQU 0x400583FC
GPIO_PORTA_DIR_R     EQU 0x40058400
GPIO_PORTA_AFSEL_R   EQU 0x40058420
GPIO_PORTA_DEN_R     EQU 0x4005851C
GPIO_PORTA_AMSEL_R   EQU 0x40058528
GPIO_PORTA_PCTL_R    EQU 0x4005852C

; PORT Q - dados da PAT em PQ0 a PQ3
GPIO_PORTQ_DATA_R    EQU 0x400663FC
GPIO_PORTQ_DIR_R     EQU 0x40066400
GPIO_PORTQ_AFSEL_R   EQU 0x40066420
GPIO_PORTQ_DEN_R     EQU 0x4006651C
GPIO_PORTQ_AMSEL_R   EQU 0x40066528
GPIO_PORTQ_PCTL_R    EQU 0x4006652C
	
; PORT B - selecao da PAT em PB4 e PB5
GPIO_PORTB_DATA_R    EQU 0x400593FC
GPIO_PORTB_DIR_R     EQU 0x40059400
GPIO_PORTB_AFSEL_R   EQU 0x40059420
GPIO_PORTB_DEN_R     EQU 0x4005951C
GPIO_PORTB_AMSEL_R   EQU 0x40059528
GPIO_PORTB_PCTL_R    EQU 0x4005952C

; PORT P - selecao da PAT em PP5
GPIO_PORTP_DATA_R    EQU 0x400653FC
GPIO_PORTP_DIR_R     EQU 0x40065400
GPIO_PORTP_AFSEL_R   EQU 0x40065420
GPIO_PORTP_DEN_R     EQU 0x4006551C
GPIO_PORTP_AMSEL_R   EQU 0x40065528
GPIO_PORTP_PCTL_R    EQU 0x4006552C

; NVIC
NVIC_EN1_R		EQU    0xE000E104
NVIC_PRI12_R	EQU    0xE000E430	 

; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo	
        EXPORT GPIO_Init            ; Permite chamar GPIO_Init de outro arquivo
		EXPORT PortN_Output			; Permite chamar PortN_Output de outro arquivo
		EXPORT GPIOPortJ_Handler
		EXPORT PAT_Data_Output
		EXPORT PAT_AllOff
		EXPORT PAT_Dezena_On
        EXPORT PAT_Unidade_On
        EXPORT PAT_LEDs_On
		
		IMPORT TemperaturaAlvo
												

;--------------------------------------------------------------------------------
; Função GPIO_Init
; Parâmetro de entrada: Não tem
; Parâmetro de saída: Não tem
GPIO_Init
			; Habilitar as portas A, B, J, N, P e Q
			LDR R0, =SYSCTL_RCGCGPIO_R
			LDR R1, [R0]
			LDR R2, =GPIO_CLOCK_MASK
			ORR R1, R1, R2
			STR R1, [R0]

			; Esperar todas essas portas ficarem prontas
			LDR R0, =SYSCTL_PRGPIO_R

EsperaGPIO
			LDR R1, [R0]
			AND R1, R1, R2
			CMP R1, R2
			BNE EsperaGPIO

			; ===== PB4 e PB5: selecao dos displays =====

			; Preparar nivel inicial 0: desativado
			LDR R0, =GPIO_PORTB_DATA_R
			LDR R1, [R0]
			BIC R1, R1, #0x30
			STR R1, [R0]

			; Desabilitar funcao analogica
			LDR R0, =GPIO_PORTB_AMSEL_R
			LDR R1, [R0]
			BIC R1, R1, #0x30
			STR R1, [R0]

			; Selecionar GPIO
			LDR R0, =GPIO_PORTB_AFSEL_R
			LDR R1, [R0]
			BIC R1, R1, #0x30
			STR R1, [R0]

			LDR R0, =GPIO_PORTB_PCTL_R
			LDR R1, [R0]
			LDR R2, =0x00FF0000
			BIC R1, R1, R2
			STR R1, [R0]

			; Configurar PB4 e PB5 como saidas
			LDR R0, =GPIO_PORTB_DIR_R
			LDR R1, [R0]
			ORR R1, R1, #0x30
			STR R1, [R0]

			; Habilitar funcao digital
			LDR R0, =GPIO_PORTB_DEN_R
			LDR R1, [R0]
			ORR R1, R1, #0x30
			STR R1, [R0]

			; ===== PP5: selecao dos oito LEDs =====

			; Preparar nivel inicial 0:desativado
			LDR R0, =GPIO_PORTP_DATA_R
			LDR R1, [R0]
			BIC R1, R1, #0x20
			STR R1, [R0]

			LDR R0, =GPIO_PORTP_AMSEL_R
			LDR R1, [R0]
			BIC R1, R1, #0x20
			STR R1, [R0]

			LDR R0, =GPIO_PORTP_AFSEL_R
			LDR R1, [R0]
			BIC R1, R1, #0x20
			STR R1, [R0]

			LDR R0, =GPIO_PORTP_PCTL_R
			LDR R1, [R0]
			LDR R2, =0x00F00000
			BIC R1, R1, R2
			STR R1, [R0]

			LDR R0, =GPIO_PORTP_DIR_R
			LDR R1, [R0]
			ORR R1, R1, #0x20
			STR R1, [R0]

			LDR R0, =GPIO_PORTP_DEN_R
			LDR R1, [R0]
			ORR R1, R1, #0x20
			STR R1, [R0]


			 
; 2. Limpar o AMSEL para desabilitar a analógica
            MOV     R1, #0x00						;Colocar 0 no registrador para desabilitar a função analógica
            LDR     R0, =GPIO_PORTJ_AHB_AMSEL_R     ;Carrega o R0 com o endereço do AMSEL para a porta J
            STR     R1, [R0]						;Guarda no registrador AMSEL da porta J da memória
            LDR     R0, =GPIO_PORTN_AMSEL_R			;Carrega o R0 com o endereço do AMSEL para a porta N
            STR     R1, [R0]					    ;Guarda no registrador AMSEL da porta N da memória
 
; 3. Limpar PCTL para selecionar o GPIO
            MOV     R1, #0x00					    ;Colocar 0 no registrador para selecionar o modo GPIO
            LDR     R0, =GPIO_PORTJ_AHB_PCTL_R		;Carrega o R0 com o endereço do PCTL para a porta J
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta J da memória
            LDR     R0, =GPIO_PORTN_PCTL_R      	;Carrega o R0 com o endereço do PCTL para a porta N
            STR     R1, [R0]                        ;Guarda no registrador PCTL da porta N da memória
; 4. DIR para 0 se for entrada, 1 se for saída
            LDR     R0, =GPIO_PORTN_DIR_R			;Carrega o R0 com o endereço do DIR para a porta N
			MOV     R1, #2_0011						;PNO e PN1 como saida
            STR     R1, [R0]						;Guarda no registrador
			; O certo era verificar os outros bits da PJ para não transformar entradas em saídas desnecessárias
            LDR     R0, =GPIO_PORTJ_AHB_DIR_R		;Carrega o R0 com o endereço do DIR para a porta J
            MOV     R1, #0x00               		;Colocar 0 no registrador DIR para funcionar com saída
            STR     R1, [R0]						;Guarda no registrador PCTL da porta J da memória
; 5. Limpar os bits AFSEL para 0 para selecionar GPIO 
;    Sem função alternativa
            MOV     R1, #0x00						;Colocar o valor 0 para não setar função alternativa
            LDR     R0, =GPIO_PORTN_AFSEL_R			;Carrega o endereço do AFSEL da porta N
            STR     R1, [R0]						;Escreve na porta
            LDR     R0, =GPIO_PORTJ_AHB_AFSEL_R     ;Carrega o endereço do AFSEL da porta J
            STR     R1, [R0]                        ;Escreve na porta
; 6. Setar os bits de DEN para habilitar I/O digital
            LDR     R0, =GPIO_PORTN_DEN_R			    ;Carrega o endereço do DEN
            MOV     R1, #2_00000011                     ;PN0 E PN1
            STR     R1, [R0]							;Escreve no registrador da memória funcionalidade digital 
 
            LDR     R0, =GPIO_PORTJ_AHB_DEN_R			;Carrega o endereço do DEN
			MOV     R1, #2_00000011                     ;J0     
            STR     R1, [R0]                            ;Escreve no registrador da memória funcionalidade digital
			
; 7. Para habilitar resistor de pull-up interno, setar PUR para 1
			LDR     R0, =GPIO_PORTJ_AHB_PUR_R			;Carrega o endereço do PUR para a porta J
			MOV     R1, #2_11							;Habilitar funcionalidade digital de resistor de pull-up 
            STR     R1, [R0]							;Escreve no registrador da memória do resistor de pull-up
		
		   ; Limpar o AMSEL para desabilitar a analógica 
			LDR R0, =GPIO_PORTA_AMSEL_R
			LDR R1, [R0]
			BIC R1, R1, #0xF0
			STR R1, [R0]

			; Sem função alternativa
			LDR R0, =GPIO_PORTA_AFSEL_R
			LDR R1, [R0]
			BIC R1, R1, #0xF0
			STR R1, [R0]

			; Limpar os campos para selecionar PA4 a PA7
			LDR R0, =GPIO_PORTA_PCTL_R
			LDR R1, [R0]
			LDR R2, =0xFFFF0000
			BIC R1, R1, R2
			STR R1, [R0]

			; Configurar como saidas
			LDR R0, =GPIO_PORTA_DIR_R
			LDR R1, [R0]
			ORR R1, R1, #0xF0
			STR R1, [R0]

			; Habilitar funcao digital
			LDR R0, =GPIO_PORTA_DEN_R
			LDR R1, [R0]
			ORR R1, R1, #0xF0
			STR R1, [R0]

			; ===== PQ0 a PQ3: saidas digitais para dados da PAT =====

			LDR R0, =GPIO_PORTQ_AMSEL_R
			LDR R1, [R0]
			BIC R1, R1, #0x0F
			STR R1, [R0]

			LDR R0, =GPIO_PORTQ_AFSEL_R
			LDR R1, [R0]
			BIC R1, R1, #0x0F
			STR R1, [R0]

			LDR R0, =GPIO_PORTQ_PCTL_R
			LDR R1, [R0]
			LDR R2, =0x0000FFFF
			BIC R1, R1, R2
			STR R1, [R0]

			LDR R0, =GPIO_PORTQ_DIR_R
			LDR R1, [R0]
			ORR R1, R1, #0x0F
			STR R1, [R0]

			LDR R0, =GPIO_PORTQ_DEN_R
			LDR R1, [R0]
			ORR R1, R1, #0x0F
			STR R1, [R0]


; Interrupcoes
			LDR R1, =GPIO_PORTJ_AHB_IM_R
			MOV R2, #2_00
			STR R2, [R1]

			LDR R1, =GPIO_PORTJ_AHB_IS_R
			MOV R2, #2_00
			STR R2, [R1]

			LDR R1, =GPIO_PORTJ_AHB_IBE_R
			MOV R2, #2_00
			STR R2, [R1]

			; Borda de descida em PJ1 e PJ0
			LDR R1, =GPIO_PORTJ_AHB_IEV_R
			MOV R2, #2_00
			STR R2, [R1]

			LDR R1, =GPIO_PORTJ_AHB_ICR_R
			MOV R2, #2_11
			STR R2, [R1]

			LDR R1, =GPIO_PORTJ_AHB_IM_R
			MOV R2, #2_11
			STR R2, [R1]
			
			;NVIC
			LDR R1, =NVIC_EN1_R
			MOV R2, #2_1
			LSL R2, #19
			STR R2, [R1]
			
			LDR R1, =NVIC_PRI12_R
			LDR R2, [R1]

			; Limpar somente o campo de prioridade da porta J
			LDR R3, =0xE0000000
			BIC R2, R2, R3

			; Colocar prioridade 5 nos bits 31:29
			MOV R3, #5
			LSL R3, R3, #29
			ORR R2, R2, R3

			STR R2, [R1]
	
; ====================
			BX      LR

; -------------------------------------------------------------------------------
; Função PortN_Output
; Parâmetro de entrada: R0 --> se o BIT1 está ligado ou desligado
; Parâmetro de saída: Não tem
PortN_Output
    AND R0, R0, #2_00000011    ; somente PN0 e PN1
    LDR R1, =GPIO_PORTN_DATA_R
    LDR R2, [R1]
    BIC R2, R2, #2_00000011
    ORR R0, R0, R2
    STR R0, [R1]
    BX LR                      ;Retorno

; ------------------------------------------------------------------	
; Desativa os dois displays e o grupo de LEDs.
; Altera R1 e R2. Preserva R0.
PAT_AllOff
    LDR R1, =GPIO_PORTB_DATA_R
    LDR R2, [R1]
    BIC R2, R2, #0x30
    STR R2, [R1]

    LDR R1, =GPIO_PORTP_DATA_R
    LDR R2, [R1]
    BIC R2, R2, #0x20
    STR R2, [R1]

    BX LR
	
; ------------------------------------------------------------------
; Ativa DS1, usado para a dezena: PB4 = 1
; Chamar depois de PAT_AllOff e PAT_Data_Output.
; ------------------------------------------------------------------
PAT_Dezena_On
    LDR R1, =GPIO_PORTB_DATA_R
    LDR R2, [R1]
    ORR R2, R2, #0x10
    STR R2, [R1]
    BX LR

; ------------------------------------------------------------------
; Ativa DS2, usado para a unidade: PB5 = 1
; Chamar depois de PAT_AllOff e PAT_Data_Output.
; ------------------------------------------------------------------
PAT_Unidade_On
    LDR R1, =GPIO_PORTB_DATA_R
    LDR R2, [R1]
    ORR R2, R2, #0x20
    STR R2, [R1]
    BX LR

; ------------------------------------------------------------------
; Ativa o grupo de oito LEDs: PP5 = 1
; Chamar depois de PAT_AllOff e PAT_Data_Output.
; ------------------------------------------------------------------
PAT_LEDs_On
    LDR R1, =GPIO_PORTP_DATA_R
    LDR R2, [R1]
    ORR R2, R2, #0x20
    STR R2, [R1]
    BX LR
	
	
	
; ------------------------------------------------------------------
; PAT_Data_Output
; Parâmetro de entrada: R0 = padrao de 8 bits
; Paraêtro de saida: bits 7:4 -> PA7:PA4; bits 3:0 -> PQ3:PQ0
; Altera: R1, R2 e R3. Preserva R0
; Chamar com os tres grupos da PAT desativados.
; ------------------------------------------------------------------
PAT_Data_Output
    ; Separar os quatro bits destinados a porta A
    AND R3, R0, #0xF0

    ; Substituir PA4 a PA7
    LDR R1, =GPIO_PORTA_DATA_R
    LDR R2, [R1]
    BIC R2, R2, #0xF0
    ORR R2, R2, R3
    STR R2, [R1]

    ; Separar os quatro bits destinados para Q
    AND R3, R0, #0x0F

    ; Substituir somente PQ0 a PQ3
    LDR R1, =GPIO_PORTQ_DATA_R
    LDR R2, [R1]
    BIC R2, R2, #0x0F
    ORR R2, R2, R3
    STR R2, [R1]

    BX LR

; -------------------------------------------------------------------------------

GPIOPortJ_Handler
	LDR R0, =GPIO_PORTJ_AHB_MIS_R
	
	LDR R1, [R0]
	; J0 pressionado?
	TST R1, #2_01
    BNE AumentarAlvo

    ; Se nao J0, J1 pressionado?
    TST R1, #2_10
    BNE DiminuirAlvo

    ; Nenhum dos dois 
    BX LR
	
AumentarAlvo

	LDR R0, =GPIO_PORTJ_AHB_ICR_R
	MOV R1, #2_01
	STR R1, [R0]
	
	;Ler a temp alvo
	LDR R0 ,= TemperaturaAlvo
	LDRH R1, [R0]
	
	;Se ja chegou em 50,nao aumenta
	CMP R1, #50
	BHS FimInterrupcaoJ
	
	ADD R1, R1, #1
    STRH R1, [R0]
	
    B FimInterrupcaoJ

DiminuirAlvo
	LDR R0, =GPIO_PORTJ_AHB_ICR_R
	MOV R1, #2_10
	STR R1, [R0]
	
		;Ler a temp alvo
	LDR R0 ,= TemperaturaAlvo
	LDRH R1, [R0]
	
	;Se ja chegou em 5,nao diminui
	CMP R1, #5
	BLS FimInterrupcaoJ
	
	SUB R1, R1, #1
    STRH R1, [R0]
	
FimInterrupcaoJ

	BX LR 


    ALIGN                           ; garante que o fim da seção está alinhada 
    END                             ; fim do arquivo