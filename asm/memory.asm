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
symbols:        ; start of symbol table


