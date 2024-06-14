;
; runtime data
; include LAST

fpack:          ; 5 bytes of space for packed floating point number
    .or *+5
emit:           ; emit vector
    .or *+2
ioPtr:          ; io stack pointer
    .or *+1
input:          ; current input state
:lfn            ; logical file number
    .or *+1
:dev            ; device
    .or *+1
:status         ; eof/eol status of input buffer
    .or *+1
:inPtr          ; pointer into input buffer
    .or *+1
:in             ; input buffer
    .or *+2
:bufLen         ; input buffer length
    .or *+1
:bank           ; macro replay
    .or *+1
:himem          ; macro replay
    .or *+2
:name           ; filename
    .or *+2
:nameLen        ; filename length
    .or *+1
:line           ; line number
    .or *+2
:read           ; read another byte vector
    .or *+2
:size = *-input

ioFDS:          ; allocation bitmap of channels
    .or *+1
asmSP:          ; stack frame we started with
    .or *+1
lineSP:         ; stack frame for calls into per line assembly for error return
    .or *+1
argZ:           ; first zp of zp,arg
    .or *+1
ioColumn:       ; listing output column
    .or *+1
pc:             ; pc
    .or *+2
accum:          ; expression register
    .or *+2
inputOpt:       ; input filename length
    .or *+1
inputName:      ; input filename
    .or *+2
listOpt:        ; listing filename length
    .or *+1
listName:       ; listing filename
    .or *+2
outOpt:         ; output filename length
    .or *+1
outName:        ; output filename
    .or *+2
tScope:         ; save scope
    .or *+2
bank:           ; himem bank in use
    .or *+1
himem:          ; himem pointer ($a000-$bfff)
    .or *+2
inMac:          ; recording a macro (the only directive we see is .em)
    .or *+1
inArg:          ; @ state of reader
    .or *+1
ioBufs:         ; allocated io buffers
    .or *+$10
macArgs:        ; argument temp workspace
    .or *+20

    .or *%$100  ; page align
ioBuf:          ; binary output buffer
    .or *+$100
ioStack:        ; source file stack
    .or *+$100
eStack:         ; numeric evaluation stack
    .or *+$100
lineBuf:        ; line to parse
    .or *+$100
hashTable:      ; symbol hash table page
    .or *+$100
symbols:        ; start of symbol table


