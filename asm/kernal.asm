    .if kernalAsm!=0
kernalAsm=0

CINT    =$ff81
IOINIT  =$ff84
RAMTAS  =$ff87
RESTOR  =$ff8a
VECTOR  =$ff8d
SETMSG  =$ff90
SECOND  =$ff93
TKSA    =$ff96
MEMTOP  =$ff99
MEMBOT  =$ff9c
SCNKEY  =$ff9f
SETTMO  =$ffa2
ACPTR   =$ffa5
CIOUT   =$ffa8
UNTLK   =$ffab
UNLSN   =$ffae
LISTEN  =$ffb1
TALK    =$ffb4
READST  =$ffb7
SETLFS  =$ffba
SETNAM  =$ffbd
OPEN    =$ffc0
CLOSE   =$ffc3
CHKIN   =$ffc6
CHKOUT  =$ffc9
CLRCHN  =$ffcc
CHRIN   =$ffcf
CHROUT  =$ffd2
LOAD    =$ffd5
SAVE    =$ffd8
SETTIM  =$ffdb
RDTIM   =$ffde
STOP    =$ffe1
GETIN   =$ffe4
CLALL   =$ffe7
UDTIM   =$ffea
SCREEN  =$ffed
PLOT    =$fff0
IOBASE  =$fff3

    .fi ; kernalAsm

