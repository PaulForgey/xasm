    .if errorAsm!=0
errorAsm=0

; keep syncd with ioPrintErr

errorFine       = 0 ; everything is fine
errorDupLabel   = 1 ; label defined elsewhere
errorStar       = 2 ; bad *= expression
errorBackward   = 3 ; *= would move PC backward
errorEval       = 4 ; expression failed
errorAssign     = 5 ; assignment goes nowhere
errorDotOp      = 6 ; unknown pseudo op
errorOp         = 7 ; unknown op
errorMode       = 8 ; bad address mode
errorRel        = 9 ; relative branch out of range
errorParse      = 10 ; unexpected contents
errorNoArg      = 11 ; arg expected
errorEmit       = 12 ; error writing output
errorDotArg     = 13 ; bad arg to pseudo op
errorIO         = 14 ; io error (see ioStatus)
errorTooMany    = 15 ; too many open files

    .fi ; errorAsm

