zero=$50
abs=$5040

    adc abs
    adc abs,x
    adc abs,y
    adc #0
    adc zero
    adc (zero,x)
    adc zero,x
    adc (zero)
    adc (zero),y

    and abs
    and abs,x
    and abs,y
    and #0
    and zero
    and (zero,x)
    and zero,x
    and (zero)
    and (zero),y

    asl abs
    asl abs,x
    asl
    asl zero
    asl zero,x

    bbr0 zero,*
    bbr1 zero,*
    bbr2 zero,*
    bbr3 zero,*
    bbr4 zero,*
    bbr5 zero,*
    bbr6 zero,*
    bbr7 zero,*
    
    bbs0 zero,*
    bbs1 zero,*
    bbs2 zero,*
    bbs3 zero,*
    bbs4 zero,*
    bbs5 zero,*
    bbs6 zero,*
    bbs7 zero,*

    bcc *
    bcs *
    beq *
    
    bit abs
    bit abs,x
    bit #0
    bit zero
    bit zero,x

    bmi *
    bne *
    bpl *
    bra *

    brk

    bvc *
    bvs *

    clc
    cld
    cli
    clv

    cmp abs
    cmp abs,x
    cmp abs,y
    cmp #0
    cmp zero
    cmp (zero,x)
    cmp zero,x
    cmp (zero)
    cmp (zero),y

    cpx abs
    cpx #0
    cpx zero
    
    cpy abs
    cpy #0
    cpy zero

    dec abs
    dec abs,x
    dec 
    dec zero
    dec zero,x

    dex
    dey

    eor abs
    eor abs,x
    eor abs,y
    eor #0
    eor zero
    eor (zero,x)
    eor zero,x
    eor (zero)
    eor (zero),y

    inc abs
    inc abs,x
    inc
    inc zero
    inc zero,x

    inx
    iny

    jmp abs
    jmp (abs,x)
    jmp (abs)

    jsr abs

    lda abs
    lda abs,x
    lda abs,y
    lda #0
    lda zero
    lda (zero,x)
    lda zero,x
    lda (zero)
    lda (zero),y

    ldx abs
    ldx abs,y
    ldx #0
    ldx zero
    ldx zero,y

    ldy abs
    ldy abs,x
    ldy #0
    ldy zero
    ldy zero,x

    lsr abs
    lsr abs,x
    lsr 
    lsr zero
    lsr zero,x

    nop

    ora abs
    ora abs,x
    ora abs,y
    ora #0
    ora zero
    ora (zero,x)
    ora zero,x
    ora (zero)
    ora (zero),y

    pha
    php
    phx
    phy
    pla
    plp
    plx
    ply

    rmb0 zero
    rmb1 zero
    rmb2 zero
    rmb3 zero
    rmb4 zero
    rmb5 zero
    rmb6 zero
    rmb7 zero

    rol abs
    rol abs,x
    rol
    rol zero
    rol zero,x
  
    ror abs
    ror abs,x
    ror
    ror zero
    ror zero,x

    rti
    rts

    sbc abs
    sbc abs,x
    sbc abs,y
    sbc #0
    sbc zero
    sbc (zero,x)
    sbc zero,x
    sbc (zero)
    sbc (zero),y

    sec
    sed
    sei

    smb0 zero
    smb1 zero
    smb2 zero
    smb3 zero
    smb4 zero
    smb5 zero
    smb6 zero
    smb7 zero

    sta abs
    sta abs,x
    sta abs,y
    sta zero
    sta (zero,x)
    sta zero,x
    sta (zero)
    sta (zero),y

    stp

    stx abs
    stx zero
    stx zero,y

    sty abs
    sty zero
    sty zero,x

    stz abs
    stz abs,x
    stz zero
    stz zero,x

    tax
    tay
    
    trb abs
    trb zero

    tsb abs
    tsb zero

    tsx
    txa
    txs
    tya
    wai
