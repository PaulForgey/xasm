    .dw $801
    .or $801

    ; 10 SYS 2062
    .dw zero, 10
    .db $9e,' 2062',0
zero:
    .dw 0

    *=2062

    .in 'zp.asm'
    .in 'kernal.asm'

options=$bf00

    tsx
    stx asmSP
    jsr ioInit
    jsr symInit
    stz pass
    stz listOpt
    stz outOpt
    stz lineIfs
    stz lineIfd
    lda #$ff
    sta ePtr
    bra begin
    
usage:
    ldx #<usageStr
    ldy #>usageStr
    jsr ioPrint
    jmp exit

begin:
    jsr askArgs         ; get interactively
    cmp #0
    beq usage
:got
    jsr ioCopySourceName
    sta inputOpt        ; source filename length
    lda ptr    
    sta inputName
    lda ptr+1
    sta inputName+1

    jsr getOpt          ; output
    cmp #0
    beq :nooutOpt
    jsr ioCopyDestName
    sta outOpt          ; dest filename length
    stx outName
    sty outName+1    
:nooutOpt

    jsr getOpt          ; listing
    cmp #0
    beq :nolistOpt
    jsr ioCopyListName
    sta listOpt
    lda ptr
    sta listName
    lda ptr+1
    sta listName+1
:nolistOpt    

asmPass:
    stz symScope
    stz symScope+1

    ldx inputName
    ldy inputName+1
    lda inputOpt
    jsr ioPush

    stz pc
    lda #$10
    sta pc+1            ; default pc=$1000

    ldx #<passStr       ; "pass:n"
    ldy #>passStr
    jsr ioPrint
    lda pass            ; pass #
    and #$07
    inc
    jsr ioPrintHex
    lda #13             ; cr
    jsr CHROUT    

:line
    jsr ioListing       ; possibly show pc for listing
    jsr ioReadLine      ; read next line
    jsr asmError        ; poll for error
    lda ioLFN           ; check for EOF
    beq :next

    jsr lineAsm         ; assemble line
    jsr asmError        ; poll for error     

    lda pass
    bpl :line           ; listing output in second pass, if enabled
    lda lineIfs
    bmi :line           ; do not list if'd out 

    jsr ioPadListing

    ldx #0    
:listLine
    lda lineBuf,x
    beq :listed         ; eof
    cmp #13
    beq :listed         ; cr
    jsr ioEmit
    inx
    bne :listLine
:listed
    lda #13
    jsr ioEmit
    bra :line

:next    
    lda pass            ; maybe done if non-z pass
    bne :listing
    inc                 ; pass++
    sta pass

    lda outOpt          ; do we have output?
    beq :listing        ; no, skip to listing (if enabled)

    ldx outName         ; set up output filename
    ldy outName+1
    jsr ioOpenDest      ; open
    jsr asmError        ; poll for error

    lda #<ioEmit        ; connect the output hose
    sta emit
    lda #>ioEmit
    sta emit+1
    jmp asmPass         ; go around again    

:listing
    jsr ioClose         ; flush and close output or listing
    jsr asmError

    lda pass
    bmi asmDone         ; listed, we are done
    inc
    ora #$80
    sta pass

    lda listOpt
    beq asmDone         ; no listing, we are done

    ldx listName        ; open the listing file  
    ldy listName+1

    jsr ioOpenDest      ; open
    jsr asmError        ; poll for error

    lda #<ioEmitListing
    sta emit
    lda #>ioEmitListing
    sta emit+1
    jmp asmPass

askArgs:
    lda #'?
    jsr CHROUT
    ldx #0
    stx optPtr
:loop
    jsr CHRIN
    cmp #13
    beq :done
    sta options,x
    inx
    bne :loop
:done
    stz options,x
    lda #13             ; cr
    jsr CHROUT
    stz optPtr
    jmp getOpt
    
asmDone:
    ldx #<symendStr     ; "symend="
    ldy #>symendStr
    jsr ioPrint
    lda symEnd+1
    jsr ioPrintHex
    lda symEnd
    jsr ioPrintHex
    ldx #<pcStr         ; "pc="
    ldy #>pcStr
    jsr ioPrint
    lda pc+1
    jsr ioPrintHex
    lda pc
    jsr ioPrintHex
    lda #13
    jsr CHROUT

exit:
    ldx #0              ; zero out options buf on our way out
:fill
    stz options,x
    inx
    bne :fill
    ldx asmSP           ; get top level stack pointer
    txs
    rts                 ; exit out completely    
    
asmError:
    lda error           ; error non-z?
    beq :fine
    jsr ioError         ; print error
    bra exit            ; abort
:fine
    rts

usageStr:
    .db 'usage: xasm input.asm[;output][;listing]',0
passStr:
    .db 13,'pass:',0
symendStr:
    .db 13,'symEnd=$',0
pcStr:
    .db 13,'pc=$',0

;
; returns next option in a/x/y
getOpt:
    ldx optPtr
    stx scratch
    ldy #0
:loop
    lda options,x
    beq :got
    cmp #13         ; cr (shouldn't see this, but be defensive)
    beq :got
    inx
    cmp #';
    beq :got
    iny
    bne :loop
:got
    tya
    stx optPtr
    ldx scratch
    ldy #>options
    rts
 
    .in 'symtab.asm'
    .in 'eval.asm'
    .in 'line.asm'
    .in 'io.asm'
    .in 'isns.asm'
    .in 'memory.asm'

