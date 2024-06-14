    .in 'zp.asm'
    .in 'kernal.asm'

;
; initialize himem system
hiInit
    lda #1          ; user bank 1
    sta bank
    stz himem
    lda #$a0        ; start at $a000
    sta himem+1
    rts

;
; write text to himem
; error set if out of memory
hiWrite
    ldy himem
    ldx himem+1
    cpx #$c0        ; have we incremented to top of window?
    beq :nextbank   ; advance to next bank
    stz ptr         ; ptr=himem & $ff00
    stx ptr+1
    ldx bank
    stx $00         ; set active bank
    sta (ptr),y     ; write
    iny
    sty himem       ; increment lo pointer
    bne :lo
    inc himem+1     ; increment hi pointer if wrapped
:lo
    rts
:nextbank
    sta scratch     ; save the byte we are trying to write
    inc bank        ; increment bank
    sec
    jsr MEMTOP      ; query number of banks we have
    cmp bank
    beq :err        ; full
    lda #$a0        ; reset pointer in new bank
    stz himem
    sta himem+1
    lda scratch     ; restore byte we are trying to write
    bra hiWrite     ; try again in new bank

:err
    lda #errors:noMem
    sta error
    rts

;
; read from himem
; caller is responsible to know when to stop reading
hiRead
    ldy input:himem
    ldx input:himem+1
    cpx #$c0        ; have we increment to top of window?
    beq :nextbank   ; advance
    stz ptr
    stx ptr+1
    ldx input:bank
    stx $00         ; set active bank
    lda (ptr),y     ; read
    iny
    sty input:himem ; increment lo pointer
    bne :lo
    inc input:himem+1 ; increment hi pointer if wrapped
:lo
    bit #$ff        ; z=1 if zero
    rts
:nextbank
    inc input:bank  ; increment bank
    lda #$a0
    stz input:himem
    sta input:himem+1
    bra hiRead      ; try again in new bank

;
; unread last hiRead
; call only once after hiRead
hiUnread
    dec input:himem
    bne :out
    dec input:himem+1
:out
    rts
