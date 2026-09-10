; Exemplo.s
; Desenvolvido para a placa EK-TM4C1294XL
; Prof. Guilherme Peron
; 12/03/2018

; -------------------------------------------------------------------------------
        THUMB                        ; Instruções do tipo Thumb-2
; -------------------------------------------------------------------------------
; Declarações EQU - Defines
;<NOME>         EQU <VALOR>
BEGIN_SCAN_ADDRESS EQU 0x20000400
BEGIN_PALINDROME_ADDRESS EQU 0x20000600
; -------------------------------------------------------------------------------
; Área de Dados - Declarações de variáveis
		AREA  DATA, ALIGN=2
		; Se alguma variável for chamada em outro arquivo
		;EXPORT  <var> [DATA,SIZE=<tam>]   ; Permite chamar a variável <var> a 
		                                   ; partir de outro arquivo
;<var>	SPACE <tam>                        ; Declara uma variável de nome <var>
                                           ; de <tam> bytes a partir da primeira 
                                           ; posição da RAM		

; -------------------------------------------------------------------------------
; Área de Código - Tudo abaixo da diretiva a seguir será armazenado na memória de 
;                  código
        AREA    |.text|, CODE, READONLY, ALIGN=2

		; Se alguma função do arquivo for chamada em outro arquivo	
        EXPORT Start                ; Permite chamar a função Start a partir de 
									; outro arquivo. No caso startup.s
									
		; Se chamar alguma função externa	
		IMPORT BubbleSort              ; Permite chamar dentro deste arquivo uma 
									; função <func>

; -------------------------------------------------------------------------------
; Função main()
; Comece o código aqui <======================================================

Start
	LDR R8, =BEGIN_SCAN_ADDRESS
	LDR R7, =BEGIN_PALINDROME_ADDRESS

SearchRam ; inicio do loop vasculhando ram
	LDRH R1, [R8], #0x2
	CBZ R1, DoneSearchRam ; se achar zero acabou
	
	; verificar se eh palindromo
	; =================	
	MOV R0, R1
	PUSH {R2}
	BL Palindrome
	POP {R2}
	
	; se R0 == 1 tem que armazenar R1 na RAM
	CMP R0, #1
	ITT EQ
	ADDEQ R2, R2, #1 ; R2 contador de palindromos
	STRHEQ R1, [R7], #0x2

	; ================

	B SearchRam
	
DoneSearchRam ; fim do loop (viu todos os valores do vetor na ram)
	MOV R0, R2

	B Done

; ======== funcoes auxiliares =====

Palindrome ; Retorna R0 = 1 se R0 for palindromo
		   ; Retorna R0 = 0 caso contrario
		   
	MOV R1, #0 ; registrador que vai receber o numero invertido inicializado
	MOV R2, R0 ; copia do numero original que vai ser "destruida"
	MOV R3, #10 ; divisor

LoopMirrorNum
	CBZ R2, DoneLoopMirrorNum ; se R2 for zero acabou o loop
	
	UDIV R4, R2, R3 ; R4 = R2 / 10
	MLS R5, R3, R4, R2 ; R5 = R2 - 10*R4
	; R5 eh o resto da divisao de R2 por 10
	
	MUL R1, R1, R3
	ADD R1, R1, R5
	
	MOV R2, R4	
	
	B LoopMirrorNum

DoneLoopMirrorNum

	CMP R0, R1
	BEQ IsPalindrome
	
	MOV R0, #0
	BX LR
	
IsPalindrome
	MOV R0, #1
	BX LR

; ============

Done
	NOP
    ALIGN                           ; garante que o fim da seção está alinhada 
    END                             ; fim do arquivo
