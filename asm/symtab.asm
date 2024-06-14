    .in 'zp.asm'

;
; initialize hash table
symInit:
    lda #<symbols
    sta symEnd
    lda #>symbols
    sta symEnd+1
    ldx #0

:fill
    stz hashTable,x
    inx
    bne :fill

    rts

; layout of a symbol entry:
; 00-01:    next (0 if end)
; 02-03:    scope (parent entry, or 0)
; 04:       caller status
; 05-07:    value
; 08-09:    filename declared in
; 0a:       filename length
; 0b-0c:    line number declared in

;
; enter or return existing symbol entry
; result in ptr
symGet:
    ; string = strGet
    ; nptr = (string).symbols
    jsr strGet
    ldy #2
    lda (ptr),y
    sta nptr
    lda ptr
    sta string
    iny
    lda (ptr),y
    sta nptr+1
    lda ptr+1
    sta string+1

:next
    jsr ptrNext
    beq :notFound

    ; compare scope
    lda (ptr),y
    cmp symScope
    bne :next
    iny
    lda (ptr),y
    cmp symScope+1
    bne :next

    ; found!
    rts

:notFound
    ; push our scoped entry
    ; ptr = symEnd
    ; symEnd += $d
    lda #$d
    jsr symPush


    ; nptr = (string).symbols
    ; (string).symbols = ptr
    ldy #2
    lda (string),y
    sta nptr
    lda ptr
    sta (string),y
    iny

    lda (string),y
    sta nptr+1
    lda ptr+1
    sta (string),y

    ; (ptr++)=nptr
    ; next linkage
    ldy #0
    lda nptr
    sta (ptr),y
    iny

    lda nptr+1
    sta (ptr),y
    iny

    ; (ptr++)=scope
    lda symScope
    sta (ptr),y
    iny

    lda symScope+1
    sta (ptr),y
    iny

    ; (ptr++)=0
    ; zero out flags when creating
    lda #0
    sta (ptr),y
    iny

    ; (++ptr)=non-zero
    ; default value (forward decl) not presumed to be zero page
    iny
    tya
    sta (ptr),y

    ; copy name/nameLen/line
    ldy #8+4
    ldx #4
:fileLine
    lda input:name,x
    sta (ptr),y
    dey
    dex
    bpl :fileLine

    rts


; layout of a string entry:
; 00-01:    next (0 if end)
; 02-03:    symbols having this label
; 04-??:    counted string

;
; enter or return existing counted string
; result in ptr
strGet:
    ; nptr = hash(symLabel)
    jsr strHash
    lda hashTable,x
    sta nptr
    lda hashTable+1,x
    sta nptr+1

:next
    jsr ptrNext
    beq :notFound

    ; compare string
    ; string = ptr+4
    lda ptr
    clc
    adc #4
    sta string
    lda ptr+1
    adc #0
    sta string+1
    jsr strEqual
    bne :next

    ; found/created, result in ptr
:done
    rts

:notFound
    ; write new entry to head of list
    ; nptr = hashEntry
    lda hashTable,x
    sta nptr
    lda hashTable+1,x
    sta nptr+1

    ; hash = symEnd
    ; ptr = symEnd
    ; symEnd += 5 + symLength
    lda #5
    jsr symPush

    lda ptr
    sta hashTable,x
    lda ptr+1
    sta hashTable+1,x

    lda symLength
    jsr symPush

    ; (ptr++) = nptr
    lda hashTable,x
    sta ptr
    lda hashTable+1,x
    sta ptr+1
    
    lda nptr
    sta (ptr)
    ldy #1
    lda nptr+1
    sta (ptr),y
    iny

    ; (ptr++) = $0000
    ; (symbol entries pointer)
    lda #0
    sta (ptr),y
    iny
    sta (ptr),y
    iny

    ; (ptr) = symLength
    lda symLength
    sta (ptr),y

    ; string = ptr+5
    lda ptr
    clc
    adc #5
    sta string
    lda ptr+1
    adc #0
    sta string+1

    ldy #0
:copy
    cpy symLength
    beq :done
    lda (symLabel),y
    sta (string),y
    iny
    bne :copy

;
; compute hash value for counted string
strHash:
    lda symLength
    tay
    clc
:loop
    beq :done
    dey
    rol                 ; c << output << c
    eor (symLabel),y    ; output = output xor byte
    iny
    dey
    bne :loop

    ; truncate to 7 bit
:done
    asl
    tax                 ; result in index form
    rts

;
; push symEnd by A bytes
; ptr=symEnd before increment
symPush:
    sta scratch
    lda symEnd
    sta ptr
    clc
    adc scratch
    sta symEnd
    lda symEnd+1
    sta ptr+1
    adc #0
    sta symEnd+1
    rts

;
; ptr=nptr, nptr=(ptr)
; Z if nptrH=0
; Y=2 otherwise
ptrNext:
    lda nptr+1
    beq :out            ; nptrH=0
    sta ptr+1
    lda nptr
    sta ptr
    ldy #0
    lda (ptr),y
    sta nptr
    iny
    lda (ptr),y         ; Z=0
    sta nptr+1
    iny
:out
    rts

;
; compare counted string at (string) against symLength/symLabel
; for equality, Z=1 if so
strEqual:
    ldy #0
    lda (string),y
    cmp symLength
    bne :out
:loop
    cpy symLength
    beq :out
    lda (symLabel),y
    iny
    cmp (string),y
    bne :out
    beq :loop
:out
    rts


