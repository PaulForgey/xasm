;
; return true if arg can relative branch from pc+branch instruction
ISREL   .ma
    ; branch distance from instruction
    _ = @0-(*+2)
    ; range -128 to 127
    _ = (_ < $80) . (!_ < $80)
    .em

;
; jmp or bra
JMP .ma
    ISREL @0
    .if _
        bra @0
    .el
        jmp @0
    .fi
    .em

;
; beq with potential long
BEQ .ma
    ISREL @0
    .if _
        beq @0
    .el
        bne :@:not
        jmp @0
:@:not:
    .fi
    .em

;
; bne with potential long
BNE .ma
    ISREL @0
    .if _
        bne @0
    .el
        beq :@:not
        jmp @0
:@:not:
    .fi
    .em

;
; bcs with potential long
BCS .ma
    ISREL @0
    .if _
        bcs @0
    .el
        bcc :@:not
        jmp @0
:@:not:
    .fi
    .em

;
; bcc with potential long
BCC .ma
    ISREL @0
    .if _
        bcc @0
    .el
        bcs :@:not
        jmp @0
:@:not:
    .fi
    .em

;
; bmi with potential long
BMI .ma
    ISREL @0
    .if _
        bmi @0
    .el
        bpl :@:not
        jmp @0
:@:not:
    .fi
    .em

;
; bpl with potential long
BPL .ma
    ISREL @0
    .if _
        bpl @0
    .el
        bmi :@:not
        jmp @0
:@:not:
    .fi
    .em

;
; load ax with 16 bit immediate
LAX .ma
    lda #<@0
    ldx #>@0
    .em

;
; load xy with 16 bit immediate
LXY .ma
    ldx #<@0
    ldy #>@0
    .em

;
; assign zp ptr @0 to zp ptr @1
TXPTR   .ma
    lda @1
    sta @0
    lda @1+1
    sta @1+1
    .em

