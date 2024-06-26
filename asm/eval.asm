    .in 'zp.asm'

esInit  = 0
esOp    = 1


eDone:
    ; err if not in esOp state
    clc
    lda eState
    beq :error
    rts
:error
    sec
    rts

;
; normalize petscii in A into lineBuf,x
ePet:
    sta scratch
    and #$e0
    cmp #$60        ; %011xxxxx -> %110xxxxx
    bne :nopet
    lda scratch
    eor #$a0
    sta lineBuf,x
    rts
:nopet
    lda scratch
    rts

;
; evaluate expression at lineBuf,x
eEval:
    stz eState
    stz eOp
    stz arg
    stz arg+1
    jsr ePush

:loop
    lda lineBuf,x
    BEQ eDone       ; eof
    cmp #',
    BEQ eDone
    cmp #';
    BEQ eDone
    cmp #')
    BEQ eDone

    ldy eState
    BNE :op

:init
    jsr eIsDec
    BCS :dec
    jsr eIsSym
    BEQ :tosym
    cmp #'%
    BEQ :bin
    cmp #'$
    BEQ :hex
    cmp #'(
    BEQ :sub
    cmp #'*
    BEQ :pc
    cmp #'_
    BEQ :accum
    cmp #''
    BEQ :char
    
    ldy #$80        ; indicate unary
    sty eOp
    ; fall thru

:op
    inx

    and #$7f        ; normalize petscii whitespace (shift+space)
    cmp #33         ; whitespace?
    bcc :loop

    ora eOp         ; push unary or binary op
    sta eOp

    cmp #'>
    beq :optwo
    
    cmp #'<
    beq :optwo

    cmp #'!
    beq :optwo
    
    bra :opone

:optwo
    lda lineBuf,x
    cmp #'=
    bne :opone 

    inx             ; this is >=, <=, or !=
    lda #$40        ; add 64 to indicate = suffix
    ora eOp
    sta eOp

:opone
    jsr ePush
    stz eState
    JMP :loop

:dec
    jsr eIsDec
    BCC :term       ; not a decimal digit?
    jsr eDec
    inx
    bne :dec

:hex
    inx
    jsr eIsHex
    BCC :term       ; not a hex digit?
    jsr eHex
    bra :hex
    
:bin
    inx
    jsr eIsBin
    BNE :term       ; not a binary digit?
    jsr eBin
    bra :bin

:tosym
    stx labelPtr    ; note where it starts
    
:sym
    jsr eIsSym
    bne :termsym
    inx
    bra :sym

:sub
    inx             ; skip '('
    jsr eEval       ; evaluate subexpression
    BCS :out
    lda lineBuf,x
    cmp #')
    BNE :term
    inx             ; consume ')'
    JMP :term

:pc
    inx             ; skip '*'
    lda pc          ; arg=pc
    sta arg
    lda pc+1
    sta arg+1
    JMP :term

:accum
    inx             ; skip '*'
    lda accum       ; arg=accum
    sta arg
    lda accum+1
    sta arg+1
    JMP :term

:char
    inx             ; skip '
    lda lineBuf,x   ; arg=literal character
    inx             ; consume
    sta arg
    stz arg+1
    JMP :term

:termsym
    stx labelEnd
    jsr eResolveSym ; resolve label value into arg
    BCS :out
    ldx labelEnd
    ; fall thru

:term
    jsr eExec       ; pop and execute what we have so far
    BCS :out
    lda #esOp       ; now in op state
    sta eState
    stz eOp         ; clear op, and not unary
    JMP :loop

:out    
    rts

;
; exec term
eExec:
    jsr eExecOne
    bcs :out
    bit eOp
    bmi eExec
:out
    rts

eExecOne:
    jsr ePop
    lda eOp
    BEQ :assign
    cmp #'+
    BEQ :add
    cmp #'-
    BEQ :sub
    cmp #$80+'- ; unary -
    BEQ :sub
    cmp #'&
    BEQ :and
    cmp #'^
    BEQ :xor
    cmp #'.
    BEQ :or
    cmp #$80+'! ; unary '!'
    BEQ :not
    cmp #$80+'< ; unary '<'
    BEQ :lo
    cmp #$80+'> ; unary '>'
    BEQ :hi
    cmp #'=
    BEQ :eq
    cmp #'>
    BEQ :gt
    cmp #'<
    BEQ :lt
    cmp #$40+'> ; >=
    BEQ :ge
    cmp #$40+'< ; <=
    BEQ :le
    cmp #$40+'! ; !=
    BEQ :ne
    cmp #'%
    BEQ :align
    sec
    rts

;
; arg=arg
:assign
    clc
    rts

;
; arg+=term
:add
    lda arg
    clc
    adc term
    sta arg
    lda arg+1
    adc term+1
    sta arg+1
    clc
    rts

;
; arg=term-arg
:sub
    lda term
    sec
    sbc arg
    sta arg
    lda term+1
    sbc arg+1
    sta arg+1
    clc
    rts

;
; arg&=term
:and
    lda arg
    and term
    sta arg
    lda arg+1
    and term+1
    sta arg+1
    clc
    rts

;
; arg.=term
:or
    lda arg
    ora term
    sta arg
    lda arg+1
    ora term+1
    sta arg+1
    clc
    rts

;
; arg^=term
:xor
    lda arg
    eor term
    sta arg
    lda arg+1
    eor term+1
    sta arg+1
    clc
    rts

;
; arg=!arg
:not
    lda arg
    eor #$ff
    sta arg
    lda arg+1
    eor #$ff
    sta arg+1
    clc
    rts

;
; arg=>arg
:hi
    lda arg+1
    sta arg
    ; fall thru

;
; arg=<arg
:lo
    stz arg+1
    clc
    rts

;
; arg=term?
:eq
    lda arg
    cmp term
    bne :false
    lda arg+1
    cmp term+1
    bne :false
    bra :true

;
; term>arg?
:gt
    lda arg+1
    cmp term+1
    bcc :true
    bne :false
    lda arg
    cmp term
    bcc :true
    bra :false

;
; term<arg?
:lt
    lda term+1
    cmp arg+1
    bcc :true
    bne :false
    lda term
    cmp arg
    bcc :true
    bra :false

;
; term>=arg?
:ge
    lda term+1
    cmp arg+1
    bcc :false
    bne :true
    lda term
    cmp arg
    bcc :false
    bra :true

; term<=arg?
:le
    lda arg+1
    cmp term+1
    bcc :false
    bne :true
    lda arg
    cmp term
    bcc :false
    bra :true

; term!=arg?
:ne
    lda arg+1
    cmp term+1
    bne :true
    lda arg
    cmp term
    beq :false

:true
    lda #$ff
    sta arg
    sta arg+1
    clc
    rts

:false
    stz arg
    stz arg+1
    clc
    rts

; arg=term%arg
:align              ; limited to $100 max
    dec arg
    lda arg
    and term
    eor arg
    inc
    and arg
    sta arg
    stz arg+1
    JMP :add

;
; add decimal digit in lineBuf,x to arg
eDec:
    lda arg         ; scratch=arg*8
    asl
    sta scratch
    lda arg+1
    rol
    sta scratch+1

    asl scratch
    rol scratch+1
    asl scratch
    rol scratch+1

    asl arg         ; arg=arg*2
    rol arg+1

    lda arg         ; arg=arg+scratch
    clc
    adc scratch
    sta arg
    lda arg+1
    adc scratch+1
    sta arg+1

    lda lineBuf,x
    sec
    sbc #'0
    clc
    adc arg
    sta arg
    bcc :out
    inc arg+1
:out
    rts

;
; add hex digit in lineBuf,x to arg
eHex:
    asl arg
    rol arg+1
    asl arg
    rol arg+1
    asl arg
    rol arg+1
    asl arg
    rol arg+1

    lda lineBuf,x
    sec
    sbc #'9+1
    bcc :digit
    sbc #7
    clc
:digit
    adc #10

    ora arg
    sta arg
    rts

;
; add binary digit in lineBuf,x to arg
eBin:
    asl arg
    rol arg+1
    sec
    sbc #'0
    ora arg
    sta arg
    rts

;
; push arg,op,state
ePush:
    ldy ePtr

    lda eOp
    sta eStack,y
    dey

    lda arg+1
    sta eStack,y
    dey

    lda arg
    sta eStack,y
    dey

    sty ePtr

    stz eOp
    stz arg
    stz arg+1
    rts

;
; pop term,op,state
ePop:
    ldy ePtr

    iny
    lda eStack,y
    sta term

    iny
    lda eStack,y
    sta term+1

    iny
    lda eStack,y
    sta eOp

    sty ePtr
    rts

;
; test if lineBuf,x is decimal digit
; C=1 if so
eIsDec:
    lda lineBuf,x
    cmp #'9+1
    bcs eIsNot

    cmp #'0
    rts

eIsNot:
    clc
    rts

;
; test if lineBuf,x is octal digit
; C=1 if so, also returns char in A
eIsOct:
    lda lineBuf,x
    cmp #'7+1
    bcs eIsNot

    cmp #'0
    rts

;
; test if lineBuf,x is hex digit
; C=1 if so
; side effect: uppercase normalized
eIsHex:
    jsr eIsDec
    bcs :out
    jsr ePet
    and #$7f

    cmp #'f+1
    bcs eIsNot

    cmp #'a
:out
    rts

;
; test if lineBuf,x is binary digit
; Z=1 if so
eIsBin:
    lda lineBuf,x
    cmp #'1
    beq :out
    cmp #'0
:out
    rts

;
; test if lineBuf,X is alpha
; C=1 if so
eIsAlpha:
    lda lineBuf,x
    jsr ePet

    cmp #'z+128+1   ; 'Z'
    bcs eIsNot      ; > 'Z'

    cmp #'a
    bcc :out        ; < 'a'

    cmp #'a+128     ; 'A'
    bcs :out        ; >= 'A' and <= 'Z'

    cmp #'z+1
    bcs eIsNot      ; > 'z'

    sec
:out
    rts

;
; test if lineBuf,x is a valid symbol character
; Z=1 if so
eIsSym:
    jsr eIsAlpha
    bcs :yes
    jsr eIsDec
    bcs :yes
    cmp #':
    beq :zero
    cmp #'@
:zero
    rts
:yes
    bit #0          ; set zero
    rts

;
; resolve label from lineBuf into arg
eResolveSym:
    lda symScope    ; note our current scope
    sta tScope
    lda symScope+1
    sta tScope+1

    ldy labelPtr    ; start of label sequence
    lda lineBuf,y
    cmp #':
    beq :loop

    stz symScope    ; global scope
    stz symScope+1

:loop
    jsr :next
    lda symLength
    beq :skip       ; empty label in sequence means do not adjust scope

    sty emitY
    jsr symGet
    ldy emitY

    lda ptr
    sta symScope
    lda ptr+1
    sta symScope+1

:skip
    cpy labelEnd
    bne :loop

:done
    clc
    ldy #4
    lda (ptr),y     ; no forward reference in pass >0
    bne :fine
    lda pass
    beq :fine
    sec             ; set error

:fine
    iny             ; symbol value in arg
    lda (ptr),y
    sta arg
    iny
    lda (ptr),y
    sta arg+1

    lda tScope      ; put scope back
    sta symScope
    lda tScope+1
    sta symScope+1

    rts

:next
    lda lineBuf,y
    cmp #'@         ; @ is a special case
    bne :label

    iny             ; consume @
    lda ioPtr       ; reach into file/line including or playing us
    clc
    adc #input:name-input
    sta symLabel
    lda #>ioStack
    sta symLabel+1  ; ioStack is page aligned
    lda #5
    sta symLength
    rts

:label
    sty symLabel    ; point symLabel at lineBuf+y
    lda #>lineBuf   ; lineBuf is page aligned
    sta symLabel+1
    stz symLength   ; reset length=0

:search
    lda lineBuf,y
    iny
    cmp #':
    beq :out        ; colon terminate at scope seperator
    inc symLength
    cpy labelEnd
    bne :search
:out
    rts

