    .in 'zp.asm'

;
; initialize macros
macInit:
    stz argPtr      ; arg stack starts at the top from (not including) $9f00
    lda #$9f
    sta argPtr+1
    rts

;
; copy lineBuf to macro line
; if line's op is .em then sent back to lineAsm
macLine:
    ldx #0
:sym
    jsr eIsSym      ; hop over possible symbol
    bne :field
    inx
    bne :sym
:field
    jsr lineNextToken
    beq :write      ; and into the pseudo-op field
    cmp #'.         ; look for .em
    bne :write
    lda lineBuf+1,x
    cmp #'e
    bne :ma
    lda lineBuf+2,x
    cmp #'m
    bne :write
    jmp lineAsm2    ; feed this back to lineAsm instead

:ma
    cmp #'m         ; look for .ma
    bne :write
    lda lineBuf+2,x
    cmp #'a
    bne :write
    jmp lineAsm2    ; feed this back to lineAsm


:write
    lda pass        ; pass 0 only
    bne :out

    stz string
:loop
    ldx string      ; copy line until EOL
    lda lineBuf,x
    beq :cr         ; EOL
    cmp #';         ; comment line (be careful not to put ; in a .db string)
    beq :cr
    cmp #33         ; check for consecutive whitespace
    bcs :writec
    ldy lineBuf+1,x
    cpy #33
    bcs :writec
    inc string      ; both us and next are whitespace, so skip this one
    bne :loop
:writec
    jsr hiWrite     ; write
    lda error       ; check error
    bne :out
    inc string      ; next line char
    bne :loop
:cr
    lda #13         ; cr
    jmp hiWrite
:out
    rts

;
; replay a macro
; ptr contains the symbol entry
; x points in lineBuf at first byte after symbol
macPlay:
    stx commaPtr
    jsr ioPush      ; push input state
    ldx #7          ; copy 8 bytes from (ptr),5 to input:bank
    ldy #5+7        ; this covers bank, ptr, name, len, line
:input
    lda (ptr),y
    sta input:bank,x
    dey
    dex
    bpl :input

    lda #1          ; pseudo-lfn for macro replay
    sta input:lfn
    lda #<macRead
    sta input:read
    lda #>macRead
    sta input:read+1

    lda argPtr      ; make note of arg stack
    ldy argPtr+1
    sta nptr
    sty nptr+1
    stz argN        ; count positional args supplied

    ldx commaPtr
:args
    jsr lineNextToken
    beq :done
    stx commaPtr
:search
    cmp #',
    beq :arg
    inx
    jsr lineEnd
    bne :search
:arg
    txa
    sec
    sbc commaPtr
    jsr macPushArg  ; push the actual arg data
    bra :args
:done

:pushN
    ldy argN        ; push positional args in reverse order
    beq :pushed
    dey
    dey
    sty argN
    lda macArgs,y
    ldx macArgs+1,y
    jsr macPushN
    bra :pushN

:pushed
    lda nptr
    ldx nptr+1
    jmp macPushN

;
; copy a bytes from lineBuf,commaPtr to stack
; x is left at 0 or one past comma
macPushArg:
    sta scratch
    inc
    jsr macPush     ; allocate the space
    ldy argN        ; make note in positional args list
    lda argPtr
    sta macArgs,y
    lda argPtr+1
    sta macArgs+1,y
    iny
    iny
    sty argN        ; argN += 2 (indexes 16 bit values)

    ldx commaPtr    ; start copying
    ldy #0
:loop
    lda lineBuf,x
    beq :zero
    cmp #';
    beq :zero
    inx
    sta (argPtr),y
    iny
    dec scratch
    bpl :loop
    dey             ; back up over the comma
:zero
    lda #0          ; write our terminating 0 to the arg data
    sta (argPtr),y
    rts

;
; push 16 bit ax to macro stack
macPushN:
    sta scratch
    lda #2
    jsr macPush
    lda scratch
    sta (argPtr)
    ldy #1
    txa
    sta (argPtr),y
    rts

;
; take a bytes from top of macro stack
macPush:
    sta scratch+1
    lda argPtr
    sec
    sbc scratch+1
    sta argPtr
    lda argPtr+1
    sbc #0
    sta argPtr+1
    rts

;
; pop original argPtr
macPop:
    lda (argPtr)
    tax
    ldy #1
    lda (argPtr),y
    sta argPtr+1
    stx argPtr
    rts

;
; character input for macro replay
macRead:
    jsr hiRead      ; read macro text
    beq :eof        ; eof

    cmp #'@         ; arg
    bne :out

    jsr hiRead      ; peek next

    cmp #'9+1
    bcs :notArg

    cmp #'0
    bcc :notArg

    sec
    sbc #'0-1       ; get argN where @0 -> 1, @9 -> 10
    asl
    tay             ; index into stack
    lda (argPtr),y  ; set us up to read arg buffer
    sta ioIn
    iny
    lda (argPtr),y
    sta ioIn+1
    stz input:inPtr

    lda #<macArg
    ldy #>macArg
    sta input:read
    sty input:read+1
    bra macArg      ; and execute first go

:notArg             ; not arg, unread and return the @
    jsr hiUnread
    lda #'@

:out
    clc             ; normal byte
    rts

:eof
    jsr macPop
    sec
    rts

;
; character input for macro arg
macArg:
    ldy input:inPtr
    lda (ioIn),y
    beq :eoa        ; end of arg

    inc input:inPtr
    clc
    rts

:eoa
    lda #<macRead   ; resume input back from macro
    ldy #>macRead
    sta input:read
    sty input:read+1
    bra macRead
