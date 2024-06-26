    .if zpAsm != 0
zpAsm=0

    ; scratch (some overlapping, used locally, not guaranteed to persist across calls elsewhere)
scratch     = $22
string      = $23
nptr        = $25
ptr         = $27
isn1        = $22
isn2        = $23
incr        = $24
commaPtr    = $29
labelEnd    = $29

    ; global scratch, calls elsewhere will not alter
emitX       = $2a   ; X preservation during emit
emitY       = $2b   ; Y preservation during emit
isnBit      = $2c   ; bit # of bit instruction
optPtr      = $2d

    ; params
symScope    = $2e   ; scope label entry (first entry at symbols is root)
symLength   = $30   ; label string length
symLabel    = $31   ; label string
isnOp       = $33   ; parsed opcode
isnMode     = $34   ; parsed address mode candidate (never initially zp)
arg         = $35   ; evaluated arg
term        = $37   ; evaluated intermediate operand
assign      = $39   ; label in assignment
eOp         = $3b   ; current eval op
eState      = $3c   ; current eval state
labelPtr    = $3d   ; label pointer in lineBuf

    ; globals
pass        = $40   ; assembly pass
symEnd      = $41   ; allocation point for symbols
ePtr        = $43   ; eval stack pointer
lineIfs     = $44   ; if stack
lineIfd     = $45   ; if destiny stack
error       = $46   ; error code
ioOutPtr    = $4a   ; output buffer position
ioIn        = $4b   ; input buffer pointer
argPtr      = $4d   ; macro arg stack
argN        = $4f   ; argN into workspace

    .fi ; zpAsm
