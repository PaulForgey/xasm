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
    .in 'xasm-macros.asm'

options=$bf00

    tsx
    stx asmSP
    jsr ioInit
    jsr symInit
    jsr hiInit
    jsr macInit
    stz pass
    stz listOpt
    stz outOpt
    stz lineIfs
    stz lineIfd
    lda #$ff
    sta ePtr
    stz inMac
    bra begin

usage:
    ldx #<usageStr
    ldy #>usageStr
    jsr ioPrint
    jmp exit

begin:
    stz $00             ; select system bank for params
    lda #4
    sta $01             ; select rom bank 4
    jsr getOpt
    cmp #0
    bne :got
    jsr askArgs         ; get interactively
    cmp #0
    beq usage
:got
    jsr ioCopySourceName
    sta inputOpt        ; source filename length
    stx inputName
    sty inputName+1

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
    stx listName
    sty listName+1
:nolistOpt

asmPass:
    stz symScope
    stz symScope+1

    ldx inputName
    ldy inputName+1
    lda inputOpt
    jsr ioPushFile

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
    lda input:lfn       ; check for EOF
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
    jsr ioEmitBin
    inx
    bne :listLine
:listed
    lda #13
    jsr ioEmitBin
    bra :line

:looping
    lda #errors:looping
    sta error
    jmp asmError

:next
    lda pass
    inc pass
    bit #$ff
    beq asmPass         ; pass 0 always goes around again

    lda #$40            ; check for additional passes
    trb pass
    beq :output         ; ready for output

    lda pass            ; check for excessive rescans
    cmp #10
    bcs :looping

    bra asmPass

:output
    lda pass
    bit #$a0
    beq :noclose        ; no output files open

    jsr ioClose         ; flush and close output or listing
    jsr asmError

:noclose
    lda outOpt          ; do we have output?
    beq :listing        ; no, skip to listing (if enabled)

    lda #$20            ; indicate writing binary
    tsb pass
    bne :listing        ; done writing binary

    ldx outName         ; set up output filename
    ldy outName+1
    jsr ioOpenDest      ; open
    jsr asmError        ; poll for error

    lda #<ioEmitBin     ; connect the output hose
    sta emit
    lda #>ioEmitBin
    sta emit+1
    jmp asmPass         ; go around again

:listing
    lda #$80            ; indicate listing
    tsb pass
    bne asmDone         ; done listing

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
    stx $00
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
    .db 'usage: ?input.asm[;output][;listing]',13
    .db 'github.com/PaulForgey/xasm',13,0
passStr:
    .db 13,'pass:',0
symendStr:
    .db 13,'symend=$',0
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
    .in 'himem.asm'
    .in 'macro.asm'
    .in 'error.asm'
    .in 'isns.asm'
    .in 'memory.asm'

