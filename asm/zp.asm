    .if zpAsm != 0
zpAsm=0

symScope    = $22   ; scope label entry (first entry at symbols is root)
symScopeH   = $23
symLength   = $24   ; label string length
symLabel    = $25   ; label string
symLabelH   = $26
isnOp       = $27   ; parsed opcode
isnMode     = $28   ; parsed address mode candidate (never initially zp)
pc          = $29   ; current program counter
arg         = $2b   ; evaluated arg
term        = $2d   ; evaluated intermediate operand
ePtr        = $2f   ; eval stack pointer
ptr         = $30
emit        = $41   ; routine to emit output
error       = $43   ; error code
lineSP      = $44   ; quick return
isnBit      = $45   ; bit # of bit instruction
ioPtr       = $46   ; source file stack pointer
ioDev       = $47   ; device number
ioName      = $48   ; current filename
ioNameL     = $50   ; current filename length
ioLFN       = $51   ; current logical file number
ioLine      = $52   ; current line number (bcd)
ioStatus    = $54   ; current status (EOF)
ioOutPtr    = $55   ; output buffer
ioColumn    = $56   ; listing output column
ioFDS       = $57   ; allocation bitmap of device files

nptr        = $32   ; traversal
string      = $34
scratch     = $36
eOp         = $38   ; current eval op
eState      = $39   ; current eval state
pass        = $3a   ; assembly pass
symEnd      = $3b   ; allocation point for symbols
tScope      = $3d   ; temporary scope during resolution
labelPtr    = $3f   ; label pointer in lineBuf
labelEnd    = $40

lineIfs     = $58   ; if stack
optPtr      = $59
asmSP       = $5a   ; top level stack pointer for fast exit
assign      = $5b   ; label in assignment
outOpt      = $5d   ; length if outputing
outName     = $5e   ; output filename
lineIfd     = $60   ; if destiny stack
incr        = $61   ; search increment
isn1        = $62   ; search term
isn2        = $63   ; search term
linePet     = $64   ; pet normalization scratch
listOpt     = $66   ; length if outputing
listName    = $67   ; listing filename
inputOpt    = $69   ; root source filename length
inputName   = $6a   ; root source filename
listLFN     = $6c   ; listing output LFN
emitX       = $6d   ; X preservation during emit
emitY       = $6e   ; Y preservation during emit

    .fi ; zpAsm

