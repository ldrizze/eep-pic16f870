#include "p16f870.inc"




    __CONFIG    _WDT_OFF & _CP_OFF & _XT_OSC & _PWRTE_ON & _LVP_OFF


#DEFINE     BANK0   BCF STATUS,RP0
#DEFINE     BANK1   BSF STATUS,RP0

    CBLOCK 0x20
        W_TMP ; TEMPORARIO PARA BACKUP DO WORK -> 0x20
        S_TMP ; TEMPORARIO PARA BACKUP DO STATUS -> 0x21

        SEG_SELECIONADO ; SEGMENTO SELECIONADO PARA EXIBIR -> 0x22
        SEG_CONTADOR ; CONTADOR PARA ALTERNAR O SEGMENTO -> 0x23
        SEG_INFORMACAO ; USADO COMO SELECIONAR PARA SEGUNDO (BIT 0), MINUTO (BIT 1) E HORA (BIT 2) -> 0x24
        SEG_INFORMACAO_CONTADOR ; USADO PARA ESPERAR ATE TROCAR DE INFORMACAO (HORA, MINUTO, SEGUNDO) -> 0x25

        DIGITO_DECIMAL ; USADO PARA CALCULOS COM O DIGITO DECIMAL -> 0x26
        DIGITO_UNITARIO ; USARO PARA CALCULOS COM O DIGITO UNITARIO -> 0x27

        MS ; MILISEGUNDOS PASSADOS -> 0x28
        MS_MULTIPLICADOR ; MULTIPLICADOR DOS MILISEGUNDOS (250 * MS_MULTIPLICADOR) -> PARA CONTAR OS SEGUNDOS -> 0x29
        HORAS ; REGISTRADOR DE HORA -> 0x2A
        MINUTOS ; REGISTRADOR DE MINUTOS -> 0x2B
        SEGUNDOS ; REGISTRADOR DE SEGUNDOS -> 0x2C

        NUMERO_DISPLAY ; NUMERO PARA SER EXIBIDO NO DISPLAY -> 0x2D
        LETRA_DISPLAY ; LETRA PARA SER EXIBIDA NO DISPLAY -> 0x2E

        TMP_NUMERO_DISPLAY ; USADO PARA CALCULAR O DECIMAL -> 0x2F
    ENDC

    ORG 0X00
    GOTO INICIO
    ORG 0x04
    BTFSC INTCON,2
    CALL BAK_REGISTERS ; FAZ BACKUP DOS REGISTRADORES STATUS E WORK
    CALL TRATA_INT_TMR0 ; TRATAMENTO TO TMR0
    CALL RESTORE_REGISTERS ; RESTAURA OS REGISTRADORES STATUS E WORK
    BCF INTCON,T0IF ; LIMPA A FLAG DE INTERRUPCAO
    RETFIE


INICIO BANK1
       CLRF TRISB    ; PORTB COMO SAIDA
       BCF  TRISC,RC2 ; 7SEG 1 COMO SAIDA
       BCF  TRISC,RC3 ; 7SEG 2 COMO SAIDA
       BCF  TRISC,RC4 ; 7SEG 3 COMO SAIDA
       MOVLW B'00000001' ; 1:4 PRESCALER -> FEITO PARA CONTAR 1ms (250 * 4 = 1,024ms)
       MOVWF OPTION_REG
       MOVLW B'10100000' ; ATIVA A INTERRUPCAO DO TMR0
       MOVWF INTCON

       BANK0 ; RETORNA AO BANK0

        CLRF W_TMP ; TEMPORARIO PARA BACKUP DO WORK -> 0x20
        CLRF S_TMP ; TEMPORARIO PARA BACKUP DO STATUS -> 0x21

        CLRF SEG_SELECIONADO ; SEGMENTO SELECIONADO PARA EXIBIR -> 0x22
        CLRF SEG_CONTADOR ; CONTADOR PARA ALTERNAR O SEGMENTO -> 0x23
        CLRF SEG_INFORMACAO ; USADO COMO SELECIONAR PARA SEGUNDO (BIT 0), MINUTO (BIT 1) E HORA (BIT 2) -> 0x24
        CLRF SEG_INFORMACAO_CONTADOR ; USADO PARA ESPERAR ATE TROCAR DE INFORMACAO (HORA, MINUTO, SEGUNDO) -> 0x25

        CLRF DIGITO_DECIMAL ; USADO PARA CALCULOS COM O DIGITO DECIMAL -> 0x26
        CLRF DIGITO_UNITARIO ; USARO PARA CALCULOS COM O DIGITO UNITARIO -> 0x27

        CLRF MS ; MILISEGUNDOS PASSADOS -> 0x28
        CLRF MS_MULTIPLICADOR ; MULTIPLICADOR DOS MILISEGUNDOS (250 * MS_MULTIPLICADOR) -> PARA CONTAR OS SEGUNDOS -> 0x29
        CLRF HORAS ; REGISTRADOR DE HORA -> 0x2A
        CLRF MINUTOS ; REGISTRADOR DE MINUTOS -> 0x2B
        CLRF SEGUNDOS ; REGISTRADOR DE SEGUNDOS -> 0x2C

        CLRF NUMERO_DISPLAY ; NUMERO PARA SER EXIBIDO NO DISPLAY -> 0x2D
        CLRF LETRA_DISPLAY ; LETRA PARA SER EXIBIDA NO DISPLAY -> 0x2E

        CLRF TMP_NUMERO_DISPLAY ; USADO PARA CALCULAR O DECIMAL -> 0x2F

       BSF  SEG_SELECIONADO,0 ; SELECIONA DE FORMA INVERSA PARA USAR O DECREMENTO POSTERIORMENTE
       BSF  SEG_INFORMACAO,0 ; COMECA EXIBINDO PELOS SEGUNDOS

       BSF PORTC,RC2 ; DESABILITA DISPLAY 1
       BSF PORTC,RC3 ; DESABILITA DISPLAY 2
       BSF PORTC,RC4 ; DESABILITA DISPLAY 3

       ;-------------------------------
       ;    CONFIGURA O HORARIO
       ;-------------------------------
       MOVLW .12
       MOVWF HORAS

       MOVLW .30
       MOVWF MINUTOS

       MOVLW .0
       MOVWF SEGUNDOS

       MOVLW .0
       MOVWF MS
       ;-------------------------------

       CALL RESETA_TMR0 ; COLOCA O TEMPO EM 6 DE INICIO PARA CONTAR ATE 250ms
       CALL SEGMENTO_ZERO ; CHAMA O SEGMENTO ZERO
       GOTO $ ; LOOP INFINITO





SEGMENTO_ZERO   BSF PORTC,RC2 ; DESENHA NO SEGMENTO 0
                BSF PORTC,RC3 ; DESLIGA OS DEMAIS DISPLAYS
                BCF PORTC,RC4
                CALL EXIBE_DIGITO_DECIMAL_DISPLAY
                RETURN

SEGMENTO_UM     BSF PORTC,RC2 ; DESENHA NO SEGMENTO 1
                BCF PORTC,RC3 ; DESLIGA OS DEMAIS DISPLAYS
                BSF PORTC,RC4
                CALL EXIBE_DIGITO_UNITARIO_DISPLAY
                RETURN

SEGMENTO_DOIS   BCF PORTC,RC2 ; DESENHA NO SEGMENTO 2
                BSF PORTC,RC3 ; DESLIGA OS DEMAIS DISPLAYS
                BSF PORTC,RC4
                CALL EXIBE_LETRA_DISPLAY
                RETURN

EXIBE_DIGITO_DECIMAL_DISPLAY MOVLW .0
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO0
                     MOVLW .1
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO1
                     MOVLW .2
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO2
                     MOVLW .3
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO3
                     MOVLW .4
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO4
                     MOVLW .5
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO5
                     MOVLW .6
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO6
                     MOVLW .7
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO7
                     MOVLW .8
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO8
                     MOVLW .9
                     SUBWF DIGITO_DECIMAL,0
                     BTFSC STATUS,Z
                     CALL NUMERO9
                     RETURN

EXIBE_DIGITO_UNITARIO_DISPLAY MOVWF .0
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO0
                     MOVLW .1
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO1
                     MOVLW .2
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO2
                     MOVLW .3
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO3
                     MOVLW .4
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO4
                     MOVLW .5
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO5
                     MOVLW .6
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO6
                     MOVLW .7
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO7
                     MOVLW .8
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO8
                     MOVLW .9
                     SUBWF DIGITO_UNITARIO,0
                     BTFSC STATUS,Z
                     CALL NUMERO9
                     RETURN

EXIBE_LETRA_DISPLAY BTFSC SEG_INFORMACAO,0
                    CALL LETRA_S
                    BTFSC SEG_INFORMACAO,1
                    CALL LETRA_M
                    BTFSC SEG_INFORMACAO,2
                    CALL LETRA_H
                    RETURN

ENCONTRA_DECIMAL MOVF NUMERO_DISPLAY ; MOVE PARA WORK O NUMERO PARA SER EXIBIDO NO DISPLAY
                 MOVWF TMP_NUMERO_DISPLAY
                 CLRF DIGITO_DECIMAL
DECREMENTA_10    MOVLW .10
                 SUBWF TMP_NUMERO_DISPLAY,1
                 INCF DIGITO_DECIMAL,1 ; INCREMENTA EM 1 O DIGITO DECIMAL
                 BTFSC STATUS,C ; SE A CARRY FLAG FOR 1, ENTAO PASSOU DOS DECIMAIS
                 GOTO DECREMENTA_10
                 DECF DIGITO_DECIMAL,1 ; DIMINUI O OVERFLOW
                 MOVLW .10
                 ADDWF TMP_NUMERO_DISPLAY,1 ; NUMERO UNITARIO
                 MOVF TMP_NUMERO_DISPLAY,0
                 MOVWF DIGITO_UNITARIO ; RESTO DO NUMERO DECREMENTADO, OU SEJA, UNIDADE
                 RETURN



ENCONTRA_UNIDADE


LETRA_H     MOVLW B'00001001' ; ESCREVE A LETRA H VIA PORTB
            MOVWF PORTB
            RETURN

LETRA_M     MOVLW B'01001000' ; ESCREVE A LETRA M VIA PORTB
            MOVWF PORTB
            RETURN

LETRA_S     MOVLW B'00010010' ; ESCREVE A LETRA S VIA PORTB
            MOVWF PORTB
            RETURN

NUMERO0 MOVLW B'11000000'
        Movwf PORTB
                     Return

NUMERO1 movlw B'11111001'
                    Movwf PORTB
                     Return

NUMERO2 movlw B'10100100'
                    Movwf PORTB
                     Return

NUMERO3  movlw B'10110000'
                    Movwf PORTB
                     Return

NUMERO4 movlw B'10011001'
                    Movwf PORTB
                     Return

NUMERO5 movlw B'10010010'
                    Movwf PORTB
                     Return

NUMERO6 movlw B'10000010'
                    Movwf PORTB
                     Return

NUMERO7 movlw B'11111000'
                    Movwf PORTB
                     Return

NUMERO8 movlw B'10000000'
                    Movwf PORTB
                     Return

NUMERO9 movlw B'10010000'
                    Movwf PORTB
                     Return

LETRAD movlw B'11000000'
               Movwf PORTB
               Return

LETRAA movlw B'10001000'
               Movwf PORTB
               Return



TRATA_INT_TMR0  INCF MS,1 ; INCREMENTA 1ms
                INCF SEG_CONTADOR,1 ; INCREMENTA NO CONTADOR DE SEGMENTO PARA ALTERAR ENTRE OS DISPLAYS
                CALL RESETA_TMR0 ; RESTA TMR0 PARA CONTAR E GERAR A INTERRUPCAO A PARTIR DE JA

                ;---------------------------------------
                ; TRATA AS INFORMACOES LOGICAS DE HORA
                ;---------------------------------------
                MOVLW .250 ; TESTA SE PASSARAM 250ms
                SUBWF MS,0
                BTFSC STATUS,Z
                CALL TRATA_MILIS

                MOVLW .5 ; TESTA SE PASSARAM 4x250ms (1s)
                SUBWF MS_MULTIPLICADOR,0
                BTFSC STATUS,Z
                CALL TRATA_SEGUNDOS

                MOVLW .60 ; TESTA SE PASSARAM 60s
                SUBWF SEGUNDOS,0
                BTFSC STATUS,Z
                CALL TRATA_MINUTOS

                MOVLW .60 ; TESTA SE PASSARAM 60min
                SUBWF MINUTOS,0
                BTFSC STATUS,Z
                CALL TRATA_HORAS

                MOVLW .24 ; TESTA SE PASSARAM 24h
                SUBWF HORAS,0
                BTFSC STATUS,Z
                CALL TRATA_DIAS
                ;---------------------------------------

                MOVLW .15 ; TESTA SE A INFORMACAO PRECISA SER ALTERADA
                SUBWF SEG_INFORMACAO_CONTADOR,0
                BTFSC STATUS,Z
                CALL TRATA_INFORMACAO_SEGMENTO


                MOVLW .4 ; TESTA O CONTADOR PARA ALTERNAR O DISPLAY
                SUBWF SEG_CONTADOR,0
                BTFSC STATUS,Z
                CALL TRATA_SEGMENTO

                BTFSC SEG_INFORMACAO,0 ; SE FOR INFORMACAO 0, EXIBE SEGUNDOS
                CALL EXIBE_SEGUNDOS

                BTFSC SEG_INFORMACAO,1 ; SE FOR INFORMACAO 1, EXIBE MINUTOS
                CALL EXIBE_MINUTOS

                BTFSC SEG_INFORMACAO,2 ; SE FOR INFORMACAO 2, EXIBE HORAS
                CALL EXIBE_HORAS

                CALL ENCONTRA_DECIMAL ; ENCONTRA OS NUMEROS DECIMAIS E UNITARIOS

                BTFSC SEG_SELECIONADO,0 ; TESTA PARA SABER QUAL DISPLAY ESCREVER
                CALL SEGMENTO_ZERO
                BTFSC SEG_SELECIONADO,1
                CALL SEGMENTO_UM
                BTFSC SEG_SELECIONADO,2
                CALL SEGMENTO_DOIS

                RETURN


TRATA_MILIS     ; FUNCAO PARA TRATAR OS MILISEGUNDOS QUE BATEM 250ms
                INCF MS_MULTIPLICADOR,1 ; INCREMENTA NO MULTIPLICADOR DE MILISEGUNDOS
                CLRF MS ; RESETA OS MILISEGUNDOS
                RETURN

TRATA_SEGUNDOS  ; FUNCAO PARA TRATAR QUANDO PASSAR 1s
                INCF SEGUNDOS,1 ; INCREMENTA EM SEGUNDOS
                INCF SEG_INFORMACAO_CONTADOR,1 ; INCREMENTA SEG INFORMACAO CONTADOR PARA ALTERAR A INFORMACAO ENTRE HORA, MINUTO E SEGUNDO NO DISPLAY
                CLRF MS_MULTIPLICADOR ; RESETA O MULTIPLICADOR DE MS
                RETURN

TRATA_MINUTOS   ; FUNCAO PARA TRATAR QUANDO PASSAR 60s
                CLRF SEGUNDOS ; RESETA SEGUNDOS
                INCF MINUTOS,1 ; INCREMENTA MINUTOS
                RETURN

TRATA_HORAS     ; FUNCAO PARA TRATAR QUANDO PASSAR 60min
                CLRF MINUTOS ; RESETA MINUTOS
                INCF HORAS,1 ; INCREMENTA HORAS
                RETURN

TRATA_DIAS      ; FUNCAO PARA TRATAR QUANDO PASSAR 24h
                CLRF HORAS ; RESETA HORAS
                RETURN


TRATA_SEGMENTO  ; FUNCAO PARA TRATA A TROCA DE SEGMENTO
                BTFSC SEG_SELECIONADO,0
                MOVLW B'00000010'
                BTFSC SEG_SELECIONADO,1
                MOVLW B'00000100'
                BTFSC SEG_SELECIONADO,2
                MOVLW B'00000001'

                MOVWF SEG_SELECIONADO
                CLRF SEG_CONTADOR
                RETURN

TRATA_INFORMACAO_SEGMENTO ; FUNCAO PARA TROCAR A INFORMACAO DO DISPLAY
                BTFSC SEG_INFORMACAO,0
                MOVLW B'00000010'
                BTFSC SEG_INFORMACAO,1
                MOVLW B'00000100'
                BTFSC SEG_INFORMACAO,2
                MOVLW B'00000001'

                MOVWF SEG_INFORMACAO
                CLRF SEG_INFORMACAO_CONTADOR
                RETURN

EXIBE_SEGUNDOS  MOVF SEGUNDOS,0
                MOVWF NUMERO_DISPLAY
                RETURN

EXIBE_MINUTOS   MOVF MINUTOS,0
                MOVWF NUMERO_DISPLAY
                RETURN

EXIBE_HORAS     MOVF HORAS,0
                MOVWF NUMERO_DISPLAY
                RETURN

RESETA_TMR0     MOVLW .6 ; RESETA O TMR0 PARA CONTAR ATE 250ms
                MOVWF TMR0
                RETURN

BAK_REGISTERS   MOVWF W_TMP ; FUNCAO DE BACKUP DOS REGISTRADORES STATUS E WORK
                MOVF  STATUS,0
                MOVWF S_TMP
                RETURN

RESTORE_REGISTERS   MOVF S_TMP,0
                    MOVWF STATUS ; RESTAURA REGISTRADOR STATUS
                    MOVF W_TMP,0 ; RESTAURA REGISTRADOR WORK
                    RETURN

    END