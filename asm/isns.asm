    .in 'zp.asm'
    .in 'mode.asm'

;
; return isn token at lineBuf,x
; isnOp: result
; C: not found
isnGet:
    ; A,B,C = a-'A', b-'A', c-'A'
    ; 
    ; bit fedcba9876543210
    ;     0AAAAABBBBBCCCCC
    ; ex "LDA" is $2c60
    ;
    lda lineBuf,x
    sec
    sbc #'a 
    asl
    asl
    sta isn2
    lda lineBuf+1,x
    sec
    sbc #'a     
    sta isn1
    lsr
    lsr
    lsr
    tsb isn2
    lda isn1
    asl
    asl
    asl
    asl
    asl
    sta isn1
    lda lineBuf+2,x
    sec
    sbc #'a
    tsb isn1

    ; incr=1 element (2 bytes per entry)
    ldy #2
    sty incr

:loop
    lda isn2        ; hi cmp
    cmp isns+1,y
    bne :cmp        ; if =, continue with lo cmp
    
    lda isn1        ; lo cmp
    cmp isns,y
    beq :found      ; if =, found

:cmp
    bcc :lo         ; needle < haystack location?
    jsr :next       ; no: extra advance to do it twice
    bcs :not

:lo
    jsr :next       ; advance
    bcs :not
    
    asl incr        ; double incr for next advance
    bcc :loop
:not
    rts             ; invariant: C=1

:found
    clc             ; C=0 to indicate found
    sty isnOp
    rts    

:next
    tya             ; y += incr
    clc
    adc incr        ; C=1 if over
    tay
    rts

;
; resolve deduced address mode and instruction
opResolve:
    ldx isnOp
    lda ops+1,x
    beq :imp
    sta ptr+1
    lda ops,x
    sta ptr

    ; can we zp this?
    lda arg+1       ; no, it is a 16 bit arg
    bne :try    

    lda isnMode     ; does this have a potential zp version?
    cmp #5
    bcs :try        ; no

    adc #10         ; try the zp form
    sta isnMode
    jsr :try
    bcc :out        ; we win (or it was relative)

    lda isnMode
    sbc #10
    sta isnMode     ; continue with original absolute

:try
    ldy isnMode
    lda (ptr),y
    bne :found      ; found it

    ldy #modeRel
    lda (ptr),y
    bne :found

    ldy #modeBitRel
    lda (ptr),y
    bne :found

    bra :err
    
:imp
    ldy isnMode     ; has to be modeImp
    cpy #modeImp
    bne :err
    lda ops,x
    ; fall thru

:found
    sty isnMode
    clc
:out
    rts

:err
    sec
    rts
        
    .in 'isns-table.asm'

