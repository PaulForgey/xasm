    .in 'zp.asm'
    .in 'kernal.asm'

;
; print errror message
errPrint:
    ldx error
    lda :table,x
    ldy :table+1,x
    tax
    jmp ioPrint
:table
errors:
:fine   =*-errors
    .dw :strings:fine
:dupLabel=*-errors
    .dw :strings:dupLabel
:star   =*-errors
    .dw :strings:star
:backward=*-errors
    .dw :strings:backward
:eval   =*-errors
    .dw :strings:eval
:assign =*-errors
    .dw :strings:assign
:dotOp  =*-errors
    .dw :strings:dotOp
:op =*-errors
    .dw :strings:op
:mode   =*-errors
    .dw :strings:mode
:rel    =*-errors
    .dw :strings:rel
:parse  =*-errors
    .dw :strings:parse
:noArg  =*-errors
    .dw :strings:noArg
:emit   =*-errors
    .dw :strings:emit
:dotArg =*-errors
    .dw :strings:dotArg
:io =*-errors
    .dw :strings:io
:tooMany=*-errors
    .dw :strings:tooMany
:noMem=*-errors
    .dw :strings:noMem
:inMac=*-errors
    .dw :strings:inMac
:noMac=*-errors
    .dw :strings:noMac
:looping=*-errors
    .dw :strings:looping

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
    .db 'label expected',0
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
:noMem
    .db 'out of macro space',0
:inMac
    .db 'already inside a macro def',0
:noMac
    .db 'not inside a macro def',0
:looping
    .db 'too many passes',0
