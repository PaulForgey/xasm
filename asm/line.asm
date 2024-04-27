    .in 'zp.asm'
    .in 'error.asm'
    .in 'mode.asm'

;
; assembles lineBuf
lineAsm:
    tsx
    stx lineSP
    stz arg
    stz arg+1
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
    bne :op

    bit lineIfs
    bmi :opdone
    
    inx             ; skip '='
    lda ptr
    sta assign      ; assign=ptr
    lda ptr+1
    beq :assignError
    sta assign+1
    
    jsr lineEval    ; eval rhs
    
    ldy #5          ; store evaluated result
    lda arg
    sta (assign),y
    iny
    lda arg+1
    sta (assign),y
    rts

:op
    lda lineBuf,x
    cmp #'*
    beq :star
    cmp #'.
    beq :dot

    bit lineIfs
    bmi :opdone     ; if'd out    

    jmp lineIsn

:assignError
    lda #errorAssign
    sta error
    rts

:backwardError
    lda #errorBackward
    sta error
    rts

:star
    inx             ; skip '*'
    jsr lineNextTokenExit
    cmp #'=
    bne :opdone
    inx             ; consume '='
    inc pass        ; cannot be forward reference
    jsr lineEval
    dec pass

:starloop
    lda arg+1
    cmp pc+1
    bcc :backwardError
    bne :stardo
    lda arg
    cmp pc
    bcc :backwardError
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
    beq :E
    cmp #'f
    beq :F
    cmp #'i
    beq :I

    bit lineIfs
    bmi :opdone     ; if'd out

    cmp #'o
    beq :O
    cmp #'d
    beq :D
    ; fall thru

:dotOpError
    lda #errorDotOp
    sta error
    rts

:E
    cpy #'i
    beq :EI
    cpy #'l
    beq :EL
    bra :dotOpError

:F
    cpy #'i
    beq :FI
    bra :dotOpError

:O
    cpy #'r
    beq :ORb
    bra :dotOpError

:I
    cpy #'f
    beq :IFb
    
    bit lineIfs
    bmi :opdone     ; if'd out
    
    cpy #'n
    beq :INb
    cpy #'b
    beq :IBb
    bra :dotOpError
  
:D
    cpy #'b
    beq :DBb
    cpy #'w
    beq :DWb
    bra :dotOpError

:ORb
    jmp :OR

:IFb
    jmp :IF

:INb
    jmp :IN
    
:IBb
    jmp :IB
    
:DBb
    jmp :DB
    
:DWb
    jmp :DW

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
    jmp ioPush

:IB
    jsr lineGetName    
    rts             ; XXX write binary file

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

;
; resolve label field into ptr, adjusting symScope if necessary
linePinLabel:
    stz labelPtr
    jsr eResolveSym
    lda lineBuf
    cmp #58         ; ':'
    beq :local
    lda ptr
    sta symScope    ; this becomes our new scope
    lda ptr+1
    sta symScope+1
:local
    lda pass
    bne :out        ; if pass >0, just return it
    bit lineIfs
    bmi :out        ; if'd out, just return it
    ldy #4
    lda (ptr),y
    bne :dupLabel
    lda #1
    sta (ptr),y
    iny
    lda pc
    sta (ptr),y     ; initially store pc
    iny
    lda pc+1
    sta (ptr),y     ; may be set later with =expr
:out
    ldx labelEnd    ; restore x
    rts

:dupLabel
    lda #errorDupLabel
    sta error
    jmp lineExit

lineEmitError:
    lda #errorEmit
    sta error
    jmp lineExit

;
; normalize non-0 to $8xxx for if checking
lineTruth:
    lda #$ff
    bit arg
    bne :true
    bit arg+1
    beq :false
:true
    sta arg+1
:false
    rts
   
;
; emit byte
; pc incremented, (emit) called
lineEmit:
    inc pc          ; pc++
    bne :lo
    inc pc+1
:lo
    jsr :doEmit
    bcs lineEmitError
    rts
    
:doEmit
    jmp (emit)

lineOpError:
    lda #errorOp
    sta error
    rts

;
; isn (arg) part
lineIsn:
    jsr isnGet
    bcs lineOpError     
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
    beq :gob        ; implied
    cmp #'#
    beq :imm
    cmp #'(
    beq :ind

    jsr lineEval

    lda #modeAbs    ; abs (so far)
    sta isnMode
    
    lda lineBuf,x
    cmp #',
    bne :gob
    inx             ; consume ,
    lda lineBuf,x
    inx             ; consume x or y (expected)
    jsr ePet
    and #$7f        ; normalize case
    cmp #'x
    beq :absx
    cmp #'y
    beq :absy
    ; fall thru

:modeError:
    lda #errorMode
    sta error
    rts

:absx
    lda #modeAbsX   ; abs,x
    sta isnMode
    bra :gob

:absy
    lda #modeAbsY   ; abs,y
    sta isnMode
    ; fall thru

:gob
    jmp :go

:imm
    inx             ; skip #
    jsr lineEval

    lda #modeImm    ; imm
    sta isnMode
    bra :go

:ind
    inx             ; skip (
    jsr lineEval
    
    lda #modeAbsInd ; indirect
    sta isnMode
    
    lda lineBuf,x
    cmp #',
    beq :indx
    cmp #')
    beq :indy
    
    bra :modeError
    
:indx
    inx             ; skip ,
    lda lineBuf,x
    jsr ePet
    and #$7f
    cmp #'x
    bne :modeError
    inx
    lda lineBuf,x
    cmp #')
    bne :modeError
    inx
    
    lda #modeAbsIndX ; (ind,x)
    sta isnMode        
    bra :go

:indy
    inx             ; skip )
    lda lineBuf,x
    cmp #',
    bne :go         ; presume (ind)
    inx
    lda lineBuf,x
    jsr ePet
    and #$7f
    cmp #'y
    bne :modeError
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
    bne :modeErrorb
    lda #modeBitZero
    sta isnMode

:notbit    
    lda isnOp
    cmp #$54        ; BRK is special
    beq :brk        

    jsr opResolve   ; opcode in a
    bcs :modeErrorb
    
    adc isnBit      ; if bitn, adjust
    jsr lineEmit    ; opcode    

    lda isnMode
    cmp #modeRel
    beq :rel
    cmp #modeBitRel 
    bne :notrel

:rel
    lda pass
    beq :pass0      ; no check in first pass    

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
    bne :relError

:pass0    
    jmp lineEmit    ; send it

:brk
    lda isnMode
    cmp #modeImp
    bne :modeErrorb
    lda #0
    jmp lineEmit    ; emit the single $00
    
:modeErrorb
    jmp :modeError
        
:notrel:    
    cmp #modeImp
    beq :done
    
    lda arg         ; low byte or zp
    jsr lineEmit

    lda isnMode    
    cmp #5
    bcs :done
    
    lda arg+1       ; high byte
    jmp lineEmit

:done
    rts

:relError
    lda #errorRel
    sta error
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
    lda #errorDotArg
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
    lda #errorParse
    sta error
    bra lineExit
:out
    rts 
   
;
; lineNextToken with an error and fast exit if at end
lineAssertToken:
    jsr lineNextToken
    bne :out
    lda #errorNoArg
    sta error
    bra lineExit
:out
    rts

;
; call eEval and fast exit on error
lineEval
    jsr eEval
    bcc :out
    lda #errorEval
    sta error
    bra lineExit
:out
    rts
