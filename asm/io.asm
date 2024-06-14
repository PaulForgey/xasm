    .in 'zp.asm'
    .in 'kernal.asm'

;
; initialize
ioInit:
    jsr CLALL
    ldx #input:size-1
:inloop
    stz input,x
    dex
    bpl :inloop
    stz error
    stz ioOutPtr
    stz ioFDS
    stz ioIn
    stz ioIn+1
    stz ioPtr
    lda #8          ; default to device 8
    sta input:dev
    lda #<:null
    sta emit
    lda #>:null
    sta emit+1
    ldx #$0f        ; initialize io buffers
:bufloop
    stz ioBufs,x
    dex
    bpl :bufloop
:null
    clc
    rts

;
; write a byte via the emit vector
ioEmit:
    inc pc
    bne :lo
    inc pc+1
:lo
    jmp (emit)

;
; close all files and display error
ioError:
    jsr ioCloseAll
    lda #13         ; cr
    jsr CHROUT
    jsr ioFileLine
    lda #32
    jsr CHROUT
    jsr errPrint
    lda #13         ; cr
    jmp CHROUT

;
; print filename and line number
ioFileLine:
    lda input:name
    ldy input:name+1
    sta ptr
    sty ptr+1
    ldy #0
:print
    cpy input:nameLen
    beq :printed
    lda (ptr),y     ; print "filename:"
    jsr CHROUT
    iny
    bne :print
:printed
    lda #':
    jsr CHROUT
    lda input:line+1
    jsr ioPrintHex
    lda input:line
    jsr ioPrintHex
    rts

ioSuffix:
:pw .db ',p,w'
:sw .db ',s,w'
:sr .db ',s,r'

;
; copy a/x/y to eStack
ioBufferName:
    stx symLabel
    sty symLabel+1
    sta symLength
    ldy #0
:copy
    lda (symLabel),y
    sta eStack,y
    iny
    cpy symLength
    bne :copy
    stz symLabel        ; point symLabel at eStack
    lda #>eStack
    sta symLabel+1
    rts

;
; append 4 byte suffix from x/y to buffered name
ioSuffixName:
    stx ptr
    sty ptr+1
    ldy #0
    ldx symLength
:loop
    lda (ptr),y
    sta eStack,x
    inx
    iny
    cpy #4
    bne :loop
    stx symLength
    rts

;
; intern eStack/symLength to same copy
; result in a/x/y
ioStoreName:
    jsr strGet
    lda ptr
    clc
    adc #5
    tax
    lda ptr+1
    adc #0
    tay
    lda symLength
    rts

;
; make a copy of a/x/y with ,p,w appended
; result in a/x/y
ioCopyDestName:
    jsr ioBufferName
    ldx #<ioSuffix:pw
    ldy #>ioSuffix:pw
    jsr ioSuffixName
    bra ioStoreName

;
; make a copy of a/x/y with ,s,w appended
ioCopyListName:
    jsr ioBufferName
    ldx #<ioSuffix:sw
    ldy #>ioSuffix:sw
    jsr ioSuffixName
    bra ioStoreName

;
; make a copy of a/x/y with ,s,r appended
; result in a/(ptr)
ioCopySourceName:
    jsr ioStringOut
    jsr ioBufferName
    ldx #<ioSuffix:sr
    ldy #>ioSuffix:sr
    jsr ioSuffixName
    bra ioStoreName

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
    ldx input:dev
    ldy #2
    jsr SETLFS
    jsr OPEN
    bcc :opened
    lda #errors:io
    sta error
:opened
    rts

;
; push current input state
ioPush:
    lda ioIn        ; copy zp shadow
    ldy ioIn+1
    sta input:in
    sty input:in+1

    ldy ioPtr       ; push input state block
    ldx #input:size-1
:loop
    lda input,x
    dey
    sta ioStack,y
    dex
    bpl :loop

    sty ioPtr       ; mark new stack location
    stz input:inPtr ; reset buffered input
    stz input:bufLen
    rts

;
; push input file a/x/y
ioPushFile:
    sta scratch
    stx ptr
    sty ptr+1
    jsr CLRCHN
    jsr ioPush

    lda #<ioReadFile
    ldy #>ioReadFile
    sta input:read
    sty input:read+1


    ; TODO: parse for @device:

    lda scratch     ; scratch/ptr -> nameL/name
    sta input:nameLen
    ldx ptr
    ldy ptr+1
    stx input:name
    sty input:name+1
    jsr SETNAM      ; filename

    jsr ioAlloc     ; device secondary in Y
    bcs :toomany
    iny
    iny
    iny             ; ..and add 3 to it (we use 2 for the output)
    ldx input:dev
    tya             ; use LFN=device secondary
    sta input:lfn
    jsr SETLFS

    jsr OPEN        ; open the file
    bcs :error
    ldx input:lfn
    jsr CHKIN
    bcs :error      ; now current file for reading

    stz input:line  ; reset to line 0
    stz input:line+1

    jmp ioReadStatus

:error
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
    lda input:lfn
    cmp #2          ; 0: eof, 1: macro playback
    bcc :noclose
    jsr CLOSE       ; close current logical file (if using a file)
    ldy input:lfn
    dey
    dey
    dey
    jsr ioDealloc   ; deallocate device secondary
:noclose

    ldy ioPtr       ; copy input block from stack
    ldx #0
:loop
    lda ioStack,y
    iny
    sta input,x
    inx
    cpx #input:size
    bne :loop
    sty ioPtr       ; stack info popped

    lda input:in    ; copy shadow zp
    ldy input:in+1
    sta ioIn
    sty ioIn+1

    ldx input:lfn
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
    rts
:done
    tsb ioFDS
    tya             ; potentially allocate input buffer
    asl
    tax
    lda ioBufs+1,x
    bne :alloced

    lda #$80        ; allocate a buffer
    jsr symPush
    lda ptr
    sta ioBufs,x
    lda ptr+1
    sta ioBufs+1,x

:alloced            ; allocated
    sta ioIn+1
    lda ioBufs,x
    sta ioIn
    clc
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
    trb ioFDS
    rts

;
; read a line of input from current file
; if ioLFN is 0 on return, at end of all files and nothing read
ioReadLine:
    sed             ; increment bcd line number
    clc
    lda input:line
    adc #$01
    sta input:line
    lda input:line+1
    adc #0
    sta input:line+1
    cld

    stz scratch
:loop
    jsr ioRead      ; read from input buffer until CR or EOF
    ldx scratch
    bcs :readerr
    inc scratch
    cmp #13         ; CR?
    beq :linedone
    sta lineBuf,x
    bra :loop
:readerr
    lda scratch     ; if we read something, deal with it
    bne :linedone

    lda error       ; non eof error?
    bne :done

    jsr ioPop       ; eof; pop this input
    lda input:lfn
    bne ioReadLine  ; continue previous input
:done
    rts

:linedone
    stz lineBuf,x   ; mark end of line
    rts

;
; call READST, set error if not EOF
; Z=1 if all clear
ioReadStatus:
    jsr READST
    sta input:status
    bit #$bf        ; everything except eof
    beq :done
    lda #errors:io
    sta error
:done
    bit #$ff        ; leave Z=0 if EOF
    rts

;
; read byte
ioRead:
    jmp (input:read)

;
; read byte from input buffer, refilling if needed
ioReadFile:
    ldy input:inPtr
    cpy input:bufLen
    beq :refill
    inc input:inPtr
    lda (ioIn),y
    clc
    rts
:refill
    stz input:inPtr ; reset input
    stz input:bufLen
    lda input:status ; check for end of file
    bne :end
    lda #$80        ; read max 128 bytes into buffer
    ldx ioIn
    ldy ioIn+1
    clc
    jsr MACPTR
    bcs :bytes      ; unsupported or error
    cpx #0
    beq :eof        ; end of file
    stx input:bufLen
    jsr ioReadStatus
    bra ioRead
:bytes
    jsr ioReadStatus
    bne :end
    ldy #0
:loop
    jsr CHRIN
    sta (ioIn),y
    jsr ioReadStatus
    bne :bytesdone  ; error or eof
    iny
    bpl :loop       ; read max 128 bytes
:partial
    sty input:bufLen
    bra ioRead
:bytesdone
    cpy #0
    bne :partial    ; if we made progress, use partial read
:end
    sec
    rts
:eof
    lda #$40
    sta input:status
    bra :end

;
; copy current input file to output until end or error
ioCopy:
    lda error
    bne :done
    jsr ioRead
    bcs :done
    jsr ioEmit
    bcc ioCopy
:done
    lda error
    beq :out
    jmp ioPop
:out
    rts

;
; emit byte to output (binary or listing char)
ioEmitBin:
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
    jsr ioEmitBin
    bcs :out
    inc ioColumn
    lda ioColumn
    cmp #8
    bcc :out
    lda #13
    jsr ioEmitBin
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
    ldx input:lfn
    beq :noread
    jsr CHKIN
:noread
    jsr READST
    cmp #0
    beq ioSuccess
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
    ldx #4
:save
    lda input:name,x
    sta lineBuf,x
    dex
    bpl :save

    jsr ioClose
    jsr CLRCHN

:loop
    lda input:lfn
    beq :done

    jsr ioFileLine  ; print file and line stack
    lda #13
    jsr CHROUT

    jsr ioPop
    bra :loop
:done

    ldx #4
:restore
    lda lineBuf,x
    sta input:name,x
    dex
    bpl :restore

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
    jsr ioEmitBin
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
    jsr ioEmitBin
    bcs :done
    ldy #13         ; xxxx:aa bb cc
    jsr :spaces
    bra :loop
:spaces
    lda #32         ; space
    jsr ioEmitBin
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
    jmp ioEmitBin

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

