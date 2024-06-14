    .in 'zp.asm'
    .in 'mode.asm'

;
; assembles lineBuf
lineAsm:
    tsx
    stx lineSP
    stz arg
    stz arg+1

    lda inMac       ; recording a macro?
    beq lineAsm2
    jmp macLine     ; yes, feed this line to it

lineAsm2:
    ldx #0

:start
    lda lineBuf,x
    jsr ePet
    jsr eIsSym
    bne :label
    inx
    bne :start
:label
    stz ptr         ; assume no label yet
    stz ptr+1

    stx labelEnd
    cpx #0          ; no label
    beq :post

    bit lineIfs     ; test if we are if'd out
    bmi :post

    jsr linePinLabel

:post
    jsr lineNextTokenExit

    cmp #'=
    BNE :op

    bit lineIfs
    BMI :opdone

    inx             ; skip '='
    lda ptr
    sta assign      ; assign=ptr
    lda ptr+1
    BEQ :assignError
    sta assign+1

    jsr lineEval    ; eval rhs

    ldy #4          ; store evaluated result
    lda #$81        ; this is not pc assigned
    sta (assign),y
    iny
    lda arg         ; store arg
    sta (assign),y
    iny
    lda arg+1
    sta (assign),y
    rts

:op
    lda lineBuf,x
    cmp #'*
    BEQ :star
    cmp #'_
    BEQ :accum
    cmp #'.
    BEQ :dot

    bit lineIfs
    BMI :opdone     ; if'd out

    jmp lineIsn

:assignError
    lda #errors:assign
    sta error
    rts

:backwardError
    lda #errors:backward
    sta error
    rts

:accum
    inx             ; skip '_'
    jsr lineNextTokenExit
    cmp #'=
    BNE :assignError
    inx
    jsr lineEval
    lda arg         ; accum=arg
    sta accum
    lda arg+1
    sta accum+1
    rts

:star
    inx             ; skip '*'
    jsr lineNextTokenExit
    cmp #'=
    BNE :opdone
    inx             ; consume '='
    inc pass        ; cannot be forward reference
    jsr lineEval
    dec pass

:starloop
    lda arg+1
    cmp pc+1
    BCC :backwardError
    bne :stardo
    lda arg
    cmp pc
    BCC :backwardError
    beq :stardone
:stardo
    lda #0
    jsr lineEmit    ; emit zeros until desired pc
    bra :starloop

:stardone
:opdone
    rts

:dot
    inx             ; skip '.'
    lda lineBuf+1,x
    tay             ; second char in Y
    lda lineBuf,x   ; first char in A
    inx
    inx             ; skip the two (if not present, we will err anyway)

    cmp #'e
    BEQ :E
    cmp #'f
    BEQ :F
    cmp #'i
    BEQ :I

    bit lineIfs
    BMI :opdone     ; if'd out

    cmp #'o
    BEQ :O
    cmp #'d
    BEQ :D
    cmp #'m
    BEQ :M

    ; fall thru

:dotOpError
    lda #errors:dotOp
    sta error
    rts

:E
    cpy #'i
    BEQ :EI
    cpy #'l
    BEQ :EL

    bit lineIfs
    BMI :opdone     ; if'd out

    cpy #'m
    BEQ :EM
    JMP :dotOpError

:F
    cpy #'i
    BEQ :FI
    JMP :dotOpError

:O
    cpy #'r
    BEQ :OR
    JMP :dotOpError

:I
    cpy #'f
    BEQ :IF

    bit lineIfs
    BMI :opdone     ; if'd out

    cpy #'n
    BEQ :IN
    cpy #'b
    BEQ :IB
    JMP :dotOpError
  
:D
    cpy #'b
    BEQ :DB
    cpy #'w
    BEQ :DW
    cpy #'f
    BEQ :DF
    JMP :dotOpError

:M
    cpy #'a
    BEQ :MA
    JMP :dotOpError

:EL
    bit lineIfd     ; have we chosen our destiny
    bpl :else
    lda #$80        ; prior destiny has already been set
    tsb lineIfs
    jmp lineAssertEnd

:else
    lda lineIfs     ; flip top if bit
    eor #$80
    sta lineIfs
    jmp lineAssertEnd

:EI
    jsr lineAssertToken

    bit lineIfd     ; have we chosen our destiny
    bpl :elseif
    lda #$80        ; stay false
    tsb lineIfs     ; prior destiny has already been set
    rts

:elseif
    jsr lineEval
    jsr lineTruth
    asl lineIfs
    lda arg+1       ; top of ifs stack becomes condition
    and #$80
    tsb lineIfd     ; destiny set
    eor #$80
    asl
    ror lineIfs
    jmp lineAssertEnd

:FI
    asl lineIfs     ; pop if stack
    asl lineIfd     ; pop destiny stack
    jmp lineAssertEnd

:DB
    stz arg
    jsr lineNextTokenExit
    cmp #''
    beq :string
    cmp #',
    beq :DBcomma

    jsr lineEval
    lda arg         ; send it
    jsr lineEmit

    bra :DB

:DBcomma
    inx             ; consume ',' ready for next
    bra :DB

:string
    inx
    lda lineBuf,x
    beq :stringEOF
    cmp #''
    beq :DBcomma

    jsr lineEmit    ; send it
    bra :string
:stringEOF
    rts

:DW
    jsr lineNextTokenExit
    cmp #',
    beq :DWcomma

    jsr lineEval

    lda arg         ; send it
    jsr lineEmit
    lda arg+1
    jsr lineEmit

    bra :DW

:DWcomma
    inx             ; consume ',' ready for next word
    bra :DW

:DF
    jsr lineNextTokenExit

    stx emitX
:DFscan
    jsr lineEnd
    beq :DFscanned
    cmp #',
    beq :DFscanned
    inx
    bne :DFscan

:DFscanned
    stx scratch
    txa
    sec
    sbc emitX       ; A: length
    ldx emitX       ; X/Y: string
    ldy #>lineBuf
    jsr VAL1
    ldx #<fpack
    ldy #>fpack
    jsr MOVMF       ; pack FACC->constant

    ldx scratch     ; get X back
    ldy #0

:DFemit
    lda fpack,y     ; write 5 byte packed output
    jsr lineEmit
    iny
    cpy #5
    bne :DFemit

:DFnext
    lda lineBuf,x
    cmp #',
    bne :DF
    inx             ; consume ,
    bra :DF

:OR
    jsr lineAssertToken

    jsr lineEval

    lda arg
    sta pc
    lda arg+1
    sta pc+1
    rts

:IN
    jsr lineGetName
    jmp ioPushFile

:IB
    jsr lineGetName
    jsr ioPushFile
    jmp ioCopy

:IF
    jsr lineAssertToken

    bit lineIfs
    bmi :falseIf

    jsr lineEval
    jsr lineTruth
    lda arg+1
    and #$80
    asl
    ror lineIfd     ; desinty set
    lda arg+1
    eor #$80
    asl             ; truth->C
    ror lineIfs     ; push if stack
    jmp lineAssertEnd

:falseIf
    sec
    ror lineIfs     ; stay in false state
    sec
    ror lineIfd     ; and this is our destiny at this level
    rts

:assignErrorB
    jmp :assignError

:inMacError
    lda #errors:inMac
    sta error
    rts

:MA
    jsr lineAssertEnd
    lda ptr+1       ; check we have a label
    BEQ :assignError
    lda inMac       ; are we already doing a macro?
    BNE :inMacError
    lda pass
    bne :MApass     ; pass 0 only
    ldy #4
    lda #$02        ; indicate macro
    sta (ptr),y
    iny
    lda bank
    sta (ptr),y     ; note the bank and himem area we start
    iny
    lda himem
    sta (ptr),y
    iny
    lda himem+1
    sta (ptr),y
:MApass
    inc inMac       ; and we're now recording
    rts

:noMacError
    lda #errors:noMac
    sta error
    rts

:EM
    jsr lineAssertEnd
    lda inMac       ; are we doing a macro?
    BEQ :noMacError
    lda pass
    bne :out        ; pass 0 only
    lda #0          ; write our terminating 0
    jsr hiWrite
:out
    stz inMac
    rts

;
; resolve label field into ptr, adjusting symScope if necessary
linePinLabel:
    stz labelPtr
    jsr eResolveSym
    lda lineBuf
    cmp #':
    beq :local
    lda ptr
    sta symScope    ; this becomes our new scope
    lda ptr+1
    sta symScope+1
:local
    bit lineIfs
    bmi :out        ; if'd out, just return it
    ldy #4
    lda (ptr),y
    bne :check
    lda #$01        ; indicate label
    sta (ptr),y
    iny
:setpc
    lda pc
    sta (ptr),y     ; initially store pc
    iny
    lda pc+1
    sta (ptr),y     ; may be set later with =expr

:out
    ldx labelEnd    ; restore x
    rts

:check
    ldx pass        ; pass 0 should see these all first time
    BEQ lineDupLabel
    cmp #$01        ; label (not macro or assigment) moved?
    bne :out

    iny
    lda (ptr),y
    cmp pc
    bne :moved      ; yes
    iny
    lda (ptr),y
    cmp pc+1
    beq :out        ; no

:moved
    lda #$40        ; flag we need another pass
    tsb pass
    ldy #5
    bra :setpc      ; and update

lineDupLabel:
    lda #errors:dupLabel
    sta error
    jmp lineExit

lineEmitError:
    lda #errors:emit
    sta error
    jmp lineExit

;
; normalize non-0 to $8xxx for if checking
lineTruth:
    lda arg
    ora arg+1
    bne :true
    rts
:true
    lda #$ff
    sta arg+1
    rts

;
; emit byte
; pc incremented, (emit) called
lineEmit:
    jsr ioEmit
    bcs lineEmitError
    rts

lineOpError:
    lda #errors:op
    sta error
    rts

;
; isn (arg) part
lineIsn:
    jsr isnGet
    BCC :isn

    stx labelPtr
:macend
    jsr eIsSym
    bne :macended
    inx
    bne :macend
:macended
    stx labelEnd
    jsr eResolveSym ; see if it exists as macro name
    bcs lineOpError ; not a macro name
    ldy #4
    lda (ptr),y
    cmp #$02
    bne lineOpError ; not a macro name
    ldx labelEnd
    jmp macPlay     ; replay the macro data

:isn
    lda #modeImp
    sta isnMode     ; assume implied
    stz isnBit      ; start not assuming bit instruction
    inx             ; skip isn
    inx
    inx
    jsr eIsOct      ; test for bit number
    bcc :notbitn
    sta isnBit      ; '0'-'7' if this is a bitn
    inx

:notbitn
    jsr lineNextToken
    BEQ :go         ; implied
    cmp #'#
    BEQ :imm
    cmp #'(
    BEQ :ind

    jsr lineEval

    lda #modeAbs    ; abs (so far)
    sta isnMode

    lda lineBuf,x
    cmp #',
    BNE :go
    inx             ; consume ,
    lda lineBuf,x
    jsr ePet
    and #$7f        ; normalize case
    cmp #'x
    BEQ :absx
    cmp #'y
    BEQ :absy

    lda arg
    sta argZ        ; zp,rel
    jsr lineEval

    lda #modeBitRel
    sta isnMode
    JMP :go

:modeError:
    lda #errors:mode
    sta error
    rts

:absx
    inx             ; consume 'x'
    lda #modeAbsX   ; abs,x
    sta isnMode
    JMP :go

:absy
    inx             ; consume 'y'
    lda #modeAbsY   ; abs,y
    sta isnMode
    JMP :go

:imm
    inx             ; skip #
    jsr lineEval

    lda #modeImm    ; imm
    sta isnMode
    JMP :go

:ind
    inx             ; skip (
    jsr lineEval
    
    lda #modeAbsInd ; indirect
    sta isnMode
    
    lda lineBuf,x
    cmp #',
    BEQ :indx
    cmp #')
    BEQ :indy
    
    JMP :modeError
    
:indx
    inx             ; skip ,
    lda lineBuf,x
    jsr ePet
    and #$7f
    cmp #'x
    BNE :modeError
    inx
    lda lineBuf,x
    cmp #')
    BNE :modeError
    inx

    lda #modeAbsIndX ; (ind,x)
    sta isnMode
    JMP :go

:indy
    inx             ; skip )
    lda lineBuf,x
    cmp #',
    BNE :go         ; presume (ind)
    inx
    lda lineBuf,x
    jsr ePet
    and #$7f
    cmp #'y
    BNE :modeError
    inx

    lda #modeZeroIndY
    sta isnMode     ; (ind),y
    ; fall thru

    ; resolved address mode
:go
    jsr lineAssertEnd
    lda isnBit      ; check for bitn
    beq :notbit
    sec
    sbc #'0
    asl
    asl
    asl
    asl
    sta isnBit
    lda isnMode
    cmp #modeAbs
    bne :notbit
    lda #modeBitZero
    sta isnMode

:notbit
    lda isnOp
    cmp #$54        ; BRK is special
    BEQ :brk

    jsr opResolve   ; opcode in a
    BCS :modeError

    adc isnBit      ; if bitn, adjust
    jsr lineEmit    ; opcode

    lda isnMode
    cmp #modeRel
    BEQ :rel
    cmp #modeBitRel
    BNE :notrel

    lda argZ
    jsr lineEmit    ; zp arg of bitRel

:rel
    lda pass
    bit #$a0
    BEQ :pass0      ; no check until final pass

    lda pc          ; relative
    clc
    adc #1          ; scratch=pc+1
    sta scratch
    lda pc+1
    adc #0
    sta scratch+1

    lda arg         ; arg-=scratch
    sec
    sbc scratch
    sta arg
    lda arg+1
    sbc scratch+1
    sta arg+1

    ldx #$ff
    lda arg         ; test for valid range
    bmi :checkBack
    ldx #$00
:checkBack
    cpx arg+1
    BNE :relError

:pass0
    jmp lineEmit    ; send it

:brk
    lda isnMode
    cmp #modeImp
    BNE :modeError
    lda #0
    jmp lineEmit    ; emit the single $00

:notrel
    cmp #modeImp
    BEQ :done

    lda arg         ; low byte or zp
    jsr lineEmit

    lda isnMode
    cmp #5
    BCS :done

    lda arg+1       ; high byte
    jmp lineEmit

:relError
    lda #errors:rel
    sta error
:done
    rts

;
; expect 'quoted string' and return in a/x/y
lineGetName:
    jsr lineAssertToken
    inx
    cmp #''
    bne lineErrorDotArg
    stx scratch
    ldy #0
:count
    jsr lineEndExit
    cmp #''
    beq :got
    iny
    inx
    bne :count
:got
    tya             ; length -> A
    ldx scratch
    ldy #>lineBuf
    jmp ioCopySourceName

lineErrorDotArg:
    lda #errors:dotArg
    sta error
    bra lineExit

;
; Z=1 if at end
lineEnd:
    lda lineBuf,x
    beq :out        ; eof
    cmp #';
:out
    rts

;
; Z=1 if at end (; or eof)
lineNextToken:
    jsr lineEnd
    beq :out
    cmp #33
    bcc :white
    cmp #160
    beq :white
    cmp #224
    beq :white
:out
    rts
:white
    inx
    bra lineNextToken

;
; lineNextToken with a fast exit at end
lineNextTokenExit:
    jsr lineNextToken
    bne lineExit:out
lineExit:
    ldx lineSP      ; rewind stack for fast exit
    txs
:out
    rts

;
; lineEnd with fast exit
lineEndExit:
    jsr lineEnd
    bne :out
    bra lineExit
:out
    rts

;
; lineNextToken with an error and fast exit if not at end
lineAssertEnd:
    jsr lineNextToken
    beq :out
    lda #errors:parse
    sta error
    bra lineExit
:out
    rts

;
; lineNextToken with an error and fast exit if at end
lineAssertToken:
    jsr lineNextToken
    bne :out
    lda #errors:noArg
    sta error
    bra lineExit
:out
    rts

;
; call eEval and fast exit on error
lineEval:
    jsr eEval
    bcc :out
    lda #errors:eval
    sta error
    bra lineExit
:out
    rts
