    .in 'zp.asm'
    .in 'kernal.asm'

;
; initialize
ioInit:
    jsr CLALL
    stz ioLFN
    stz ioNameL
    stz ioStatus
    stz error
    stz ioLine
    stz ioLine+1
    stz ioOutPtr
    stz ioFDS
    lda #$ff
    sta ioPtr
    lda #8          ; default to device 8
    sta ioDev
    lda #<:null
    sta emit
    lda #>:null
    sta emit+1
:null
    clc
    rts

;
; close all files and display error
ioError:
    jsr ioCloseAll
    lda #13         ; cr
    jsr CHROUT
    ldy #0
:print
    cpy ioNameL
    beq :printed
    lda (ioName),y  ; print "filename:"
    jsr CHROUT
    iny
    bne :print
:printed
    lda #':
    jsr CHROUT
    lda ioLine+1
    jsr ioPrintHex
    lda ioLine
    jsr ioPrintHex
    lda #32
    jsr CHROUT
    jsr ioPrintErr
    ldx #<:status
    ldy #>:status
    jsr ioPrint
    lda ioStatus
    jsr ioPrintHex
    lda #10         ; cr
    jmp CHROUT

:status
    .db ',status=$',0

;
; make a copy of a/x/y with ,p,w appended
; result in a/x/y
ioCopyDestName:
    jsr ioCopyName
    lda #',
    sta (ptr),y
    iny
    lda #'p
    sta (ptr),y
    iny
    lda #',
    sta (ptr),y
    iny
    lda #'w
    sta (ptr),y
    iny

    tya
    ldy ptr+1
    rts

;
; make a copy of a/x/y with ,s,w appended
ioCopyListName:
    jsr ioCopyName
    lda #',
    sta (ptr),y
    iny
    lda #'s
    sta (ptr),y
    iny
    lda #',
    sta (ptr),y
    iny
    lda #'w
    sta (ptr),y
    iny

    tya
    ldy ptr+1
    rts

;
; make a copy of a/x/y with ,s,r appended
; result in a/(ptr)
ioCopySourceName:
    jsr ioStringOut
    jsr ioCopyName
    lda #',
    sta (ptr),y
    iny
    lda #'s
    sta (ptr),y
    iny
    lda #',
    sta (ptr),y
    iny
    lda #'r
    sta (ptr),y
    iny

    tya
    ldy ptr+1
    rts    

ioCopyName:
    stx string
    sty string+1
    tay
    clc
    adc #4
    jsr symPush
    sty scratch
    ldy #0
:loop
    cpy scratch
    beq :done
    lda (string),y
    sta (ptr),y
    iny
    bne :loop
:done
    ldx ptr
    rts

;
; print string a/x/y with CR
; all preserved
ioStringOut:
    sta scratch
    stx string
    sty string+1
    ldy #0
:loop
    cpy scratch
    beq :done
    lda (string),y
    jsr CHROUT
    iny
    bne :loop
:done
    lda #13
    jsr CHROUT
    lda scratch
    ldx string
    ldy string+1
    rts

;
; open output file named in a/x/y with LFN 2
ioOpenDest:
    jsr SETNAM
    lda #2
    ldx ioDev
    ldy #2
    jsr SETLFS
    jsr OPEN
    bcc :opened
    sta ioStatus
    lda #errors:io
    sta error
:opened
    rts

;
; push input file a/x/y
ioPush:
    sta scratch
    stx ptr
    sty ptr+1
    jsr CLRCHN

    ldy ioPtr       ; push current state

    lda ioLFN       ; push current LFN (zero is done)
    sta ioStack,y
    dey

    lda ioDev       ; device
    sta ioStack,y
    dey

    lda ioStatus    ; status
    sta ioStack,y
    dey

    lda ioName+1    ; filename
    sta ioStack,y
    dey
    lda ioName
    sta ioStack,y
    dey

    lda ioNameL     ; filename length
    sta ioStack,y
    dey

    lda ioLine+1    ; line
    sta ioStack,y
    dey
    lda ioLine
    sta ioStack,y
    dey

    sty ioPtr       ; current state all pushed

    ; TODO: parse for @device:

    lda scratch     ; scratch/ptr -> nameL/name
    sta ioNameL
    ldx ptr
    stx ioName
    ldy ptr+1
    sty ioName+1
    jsr SETNAM      ; filename

    jsr ioAlloc     ; device secondary in Y
    bcs :toomany
    iny
    iny
    iny             ; ..and add 3 to it (we use 2 for the output)
    ldx ioDev
    tya             ; use LFN=device secondary
    sta ioLFN
    jsr SETLFS

    jsr OPEN        ; open the file
    bcs :error
    ldx ioLFN
    jsr CHKIN
    bcs :error      ; now current file for reading
    stz ioLine
    stz ioLine+1
    jmp ioReadStatus

:error
    sta ioStatus
    lda #errors:io
    sta error
    rts

:toomany
    lda #errors:tooMany
    sta error
    rts

;
; pop current file state
ioPop:
    jsr CLRCHN      ; disconnect existing
    lda ioLFN
    jsr CLOSE       ; close current logical file
    ldy ioLFN
    dey
    dey
    dey
    jsr ioDealloc   ; deallocate device secondary

    ldy ioPtr

    iny             ; line number
    lda ioStack,y
    sta ioLine
    iny
    lda ioStack,y
    sta ioLine+1

    iny             ; filename length
    lda ioStack,y
    sta ioNameL

    iny             ; filename
    lda ioStack,y
    sta ioName
    iny
    lda ioStack,y
    sta ioName+1

    iny             ; status
    lda ioStack,y
    sta ioStatus

    iny
    lda ioStack,y   ; device
    sta ioDev

    iny             ; LFN
    ldx ioStack,y
    stx ioLFN
    
    sty ioPtr

    beq :zero       ; do not redirect from 0
    jmp CHKIN       ; this also becomes our current input
:zero
    rts

;
; allocate device secondary
; result in Y
ioAlloc:
    lda #$01
    ldy #0
    clc
:scan
    bit ioFDS
    beq :done
    iny
    asl
    bcc :scan
:done
    ora ioFDS
    sta ioFDS
    rts

;
; deallocate device secondary in Y
ioDealloc:
    lda #$01
:shift
    cpy #0
    beq :done
    asl
    dey
    bne :shift
:done
    eor #$ff        ; clear the bit
    and ioFDS
    sta ioFDS
    rts

;
; read a line of input from current file
; if ioLFN is 0 on return, at end of all files and nothing read
ioReadLine:
    lda ioStatus    ; check last eof
    beq :next       ; no eof, continue

    jsr ioPop
    lda ioLFN
    beq :done
    bra ioReadLine

:done
    rts             ; end of all files

:next
    sed             ; increment bcd line number
    clc
    lda ioLine
    adc #$01
    sta ioLine
    lda ioLine+1
    adc #0
    sta ioLine+1
    cld

    ldy #0
    jsr CHRIN       ; read first, check error
    sta lineBuf
    jsr ioReadStatus
    bne :eol
    lda lineBuf
:loop               ; this means if line does not end in CR, we can fail
    cmp #13         ; cr
    beq :eol
    jsr CHRIN
    iny
    sta lineBuf,y        
    bne :loop

:eol
    lda #0
    sta lineBuf,y

ioReadStatus:
    jsr READST
    sta ioStatus
    bit #$bf        ; everything except eof
    beq :done
    lda #errors:io
    sta error
:done
    bit #$ff        ; leave Z=0 if EOF
    rts

;
; emit binary output
ioEmit:
    stx emitX
    sty emitY
    ldy ioOutPtr
    sta ioBuf,y
    iny
    sty ioOutPtr
    clc             ; no error
    bne :out
    jsr ioFlushAlways
:out
    ldx emitX
    ldy emitY
    rts

;
; emit listing output
ioEmitListing:
    jsr ioHex
    lda #32
    jsr ioEmit
    bcs :out
    inc ioColumn
    lda ioColumn
    cmp #8
    bcc :out
    lda #13
    jsr ioEmit
    bcs :out
    jsr ioListing
:out
    rts


;
; flush any unwritten output
ioFlush:
    lda ioOutPtr
    beq ioSuccess
ioFlushAlways:
    jsr CLRCHN
    ldx #2
    jsr CHKOUT
    bcs :done

    lda ioOutPtr    ; try to write entire buffer
    ldx #<ioBuf     ; invariant: 0; this is page aligned
    ldy #>ioBuf
    jsr MCIOUT
    bcs :slow       ; not supported

    cpx ioOutPtr    ; did we write everything?
    beq :done
    bra :loop       ; byte bang the rest

:slow
    ldx #0          ; byte bang
:loop
    lda ioBuf,x
    jsr CHROUT
    inx
    cpx ioOutPtr
    bne :loop
:done
    stz ioOutPtr
    jsr CLRCHN
    ldx ioLFN
    beq :noread
    jsr CHKIN
:noread
    jsr READST
    cmp #0
    beq ioSuccess
    sta ioStatus
    lda #errors:io
    sta error
    sec
    rts
ioSuccess:
    clc
    rts

;
; flush output buffer and close
ioClose:
    jsr ioFlush
    lda #2
    jmp CLOSE

;
; close all disk before exiting abnormally
ioCloseAll:
    ; preserve filename and line number for error
    lda ioLine
    sta lineBuf
    lda ioLine+1
    sta lineBuf+1
    lda ioNameL
    sta lineBuf+2
    lda ioName
    sta lineBuf+3
    lda ioName+1
    sta lineBuf+4

    jsr ioClose
:loop
    lda ioLFN
    beq :done
    jsr ioPop
    bra :loop
:done
    lda lineBuf
    sta ioLine
    lda lineBuf+1
    sta ioLine+1
    lda lineBuf+2
    sta ioNameL
    lda lineBuf+3
    sta ioName
    lda lineBuf+4
    sta ioName+1

    rts

;
; emit listing address, reset column count
ioListing:
    lda pass
    bpl :silent     ; $80 must be set in pass for this output
    lda lineIfs
    bmi :silent     ; do not list if'd out
    lda pc+1        ; PC:
    jsr ioHex
    lda pc
    jsr ioHex
    lda #':
    jsr ioEmit
    stz ioColumn
:silent
    rts

;
; pad trailing spaced per ioColumn
ioPadListing:
    lda #3
    sec
    sbc ioColumn
    bcc :nextLine
    tax
    clc
:loop
    dex
    bmi :done
    ldy #3
    jsr :spaces
    bra :loop
:nextLine
    lda #13         ; cr
    jsr ioEmit
    bcs :done
    ldy #13         ; xxxx:aa bb cc
    jsr :spaces
    bra :loop
:spaces
    lda #32         ; space
    jsr ioEmit
    bcs :done
    dey
    bne :spaces
:done
    rts

;
; print hex byte in A
ioPrintHex:
    sta scratch
    lsr
    lsr
    lsr
    lsr
    jsr :digit
    lda scratch
    and #$0f
:digit
    cmp #10
    bcc :num
    adc #6          ; add 7 (C=1)
:num
    adc #'0
    jmp CHROUT

;
; emit hex byte in A
ioHex:
    sta scratch
    lsr
    lsr
    lsr
    lsr
    jsr :digit
    lda scratch
    and #$0f
:digit
    cmp #10
    bcc :num
    adc #6
:num
    adc #'0
    jmp ioEmit

;
; print 0 terminated string in X/Y
; uses ptr
ioPrint:
    stx ptr
    sty ptr+1
    ldy #0
:loop
    lda (ptr),y
    beq :done
    jsr CHROUT
    iny
    bne :loop
:done
    rts

;
; print errror message
ioPrintErr:
    lda error
    tax
    lda :table,x
    ldy :table+1,x
    tax
    jmp ioPrint
:table
errors:
:fine	=*-errors
    .dw :strings:fine
:dupLabel=*-errors
    .dw :strings:dupLabel
:star	=*-errors
    .dw :strings:star
:backward=*-errors
    .dw :strings:backward
:eval	=*-errors
    .dw :strings:eval
:assign	=*-errors
    .dw :strings:assign
:dotOp	=*-errors
    .dw :strings:dotOp
:op	=*-errors
    .dw :strings:op
:mode	=*-errors
    .dw :strings:mode
:rel	=*-errors
    .dw :strings:rel
:parse	=*-errors
    .dw :strings:parse
:noArg	=*-errors
    .dw :strings:noArg
:emit	=*-errors
    .dw :strings:emit
:dotArg	=*-errors
    .dw :strings:dotArg
:io	=*-errors
    .dw :strings:io
:tooMany=*-errors
    .dw :strings:tooMany

errors:strings:
:fine
    .db 'fine',0
:dupLabel
    .db 'dup label',0
:star
    .db 'star expr',0
:backward
    .db 'pc moved back',0
:eval
    .db 'bad expression',0
:assign
    .db 'bad assigment',0
:dotOp
    .db 'unknown pseudo op',0
:op
    .db 'unknown op',0
:mode
    .db 'bad address mode',0
:rel
    .db 'branch out of range',0
:parse
    .db 'syntax error',0
:noArg
    .db 'arg expected',0
:emit
    .db 'io write error',0
:dotArg
    .db 'bad pseudo op arg',0
:io
    .db 'io error',0
:tooMany
    .db 'too many open files',0

