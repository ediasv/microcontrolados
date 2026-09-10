; Exemplo.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 12/03/2018

; -------------------------------------------------------------------------------
        THUMB                        ; Instru��es do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declara��es EQU - Defines
BEGIN_PALINDROME_ADDRESS EQU 0x20000600
; -------------------------------------------------------------------------------
; �rea de Dados - Declara��es de vari�veis
		AREA  DATA, ALIGN=2
		; Se alguma vari�vel for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a vari�vel <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma vari�vel de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posi��o da RAM		

; -------------------------------------------------------------------------------
; �rea de C�digo - Tudo abaixo da diretiva a seguir ser� armazenado na mem�ria de 
;                  c�digo
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma funco do arquivo for chamada em outro arquivo	
        EXPORT BubbleSort               ; Permite chamar a fun��o Start a partir de 
			                        ; outro arquivo. No caso startup.s
									
		; Se chamar alguma funco externa	
        ;IMPORT <func>              ; Permite chamar dentro deste arquivo uma 
									; funco <func>

; -------------------------------------------------------------------------------
; Fun��o main()
; Comece o c�digo aqui <======================================================
BubbleSort

;entrada
    ;R0= qtd de palindromos(N)

    ;Se N for menor ou igual a 1, não tem o que ordenar
    CMP R0, #1 
    BLS Done

    ;Carrega i endereço inicial do vetor
	LDR R1, =BEGIN_PALINDROME_ADDRESS

    ;Copia N para o contador
    MOV R2, R0
    SUBS R2, R2, #1 

LoopExterno
    MOV R4, R1; Aponta para o inicio do vetor
    MOV R3,R2 ; copia o contador para R3

LoopInterno
    LDRH R5, [R4] ;Primeira posição do vetor
    LDRH R6, [R4, #2] ;Segunda posição do vetor

    CMP R5, R6 

    BHI Troca ;Se o primeiro for maior que o segundo, troca
    B   Avanca 

Troca
    STRH R6, [R4] ;Coloca o segundo valor na primeira posição
    STRH R5, [R4, #2] ;Coloca o primeiro valor na segunda posição

Avanca
    ADD R4, R4, #2 ; Avanca ponteiro para o proximo numero 
    SUBS R3, R3, #1
    BNE LoopInterno ;Se o contador não for zero, repete o loop

    SUBS R2, R2, #1 
    BNE LoopExterno ;Se o contador não for zero, repete o loop

Done
	NOP
    ALIGN                           ; garante que o fim da se��o est� alinhada 
    END                             ; fim do arquivo
