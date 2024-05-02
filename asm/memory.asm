;
; runtime data
; include LAST

    .or *%$100
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
fpack:          ; 5 bytes of space for packed floating point number
    .or *+5
emit:           ; emit vector
    .or *+2
ioDev:          ; current disk device
    .or *+1
ioLine:         ; current line
    .or *+2
ioFDS:          ; allocation bitmap of channels
    .or *+1
ioLFN:          ; current logical file number
    .or *+1
ioStatus:       ; input status
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
inputOpt:       ; input filename length
    .or *+1
listOpt:        ; listing filename length
    .or *+1
outOpt:         ; output filename length
    .or *+1
tScope:         ; save scope
    .or *+2
symbols:        ; start of symbol table

