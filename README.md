# xasm

A 65c02 assembler for the Commander X16

## Overview

Xasm is a disk based two pass assembler. The output is written directly to the output program file, thus the program may be located anywhere without interfering with the running assembler.

Features:

- Conditional assembly
- Full expression support
- 65c02 instructions
- Multiple source files using `.in`
- Can generate a listing file

## Building

Prequisites:
- go
- x16emu

Makefile will create a disk/ directory for the emulator to run in, copy (or update) the ASCII source files from asm/ into their PETSCII forms in disk/. The emulator is invoked to assemble into XASM2 with listing file XASM2.LST.

The `dist` target will copy this output to bin/xasm.prg and bin/xasm.lst, with the listing file converted into ASCII form.

## Sample Program

Create `hello.asm`:

```
	.or $2000
	.dw *		; load ,8,1 header
	.or $2000

CHROUT	=$ffd2

start:
	ldx #0
:loop
	lda hello,x
	beq :done
	jsr CHROUT
	inx
	bne :loop
:done
	rts

hello:
	.db 13,`Hello!`,13,0
```

Assemble:

```
ready.
^xasm

searching for xasm
loading from $0801 to $1c70
ready.
run
? hello.asm;hello
```

The `?` is the prompt for the source, destination, and listing files. Only the source file is mandatory. If no destinaton file is given, no binary is written. For example,
```
? hello.asm;;hello.lst
```
Will not write a binary but emit a listing file.

```
ready.
load "hello",8,1

searching for hello
loading from $2000 to $2017
ready.
sys $2000

Hello!

ready.
```

To replace over an output file, prefix the name with `@:`:
```
? hello.asm;@:hello
```

TODO: allow a filename syntax specifying a device number, e.g. `@8:output`.

## Expressions

### Literals

All literals resolve to 16 bit integers. Zero page or immediate values will take the lower 8 bits.

| Literal |   |
| ------- | - |
| `65` | Decimal number. |
| `$41` | Hexadecimal number. |
| `%1000001` | Binary number. |
| `'A` | Character. |

### Labels

A label in the label field defines a label. Without an assignment `=`, it has the value of the current PC (`*`).
Labels may be scoped using `:`. The last label not starting with `:` establishes the scope.

```
Foo:
	ldy #0
:loop
	lda (ptr),y
	beq :out
	iny
	bne :loop
:out
	rts

Bar:
	ldx #0
:loop			; this is a different :loop
	inx
	bne :loop

```

Within the scope of `Bar:`, `:loop` refers to `Bar:loop`. Scoping can be done to infinite levels:

```
Bar:
	bvs :loop	; sees Bar:loop
Bar:loop:
	inx
	beq :out
	bra Bar:loop
:out			; this is Bar:loop:out
```

A trailing `:` has no special meaning and is ignored.

Of course, this may also provide structure to globals:
```
StateBlock:
:line		.dw 0
:filename	.dw ptr

Code:
	; StateBlock:line and StateBlock:filename are labels
```

Another example:

```
Messages:
:one = *-Messages
	.dw :oneMsg
:two = *-Messages
	.dw :twoMsg
:oneMsg
	.db 'arbitrary text',0
:twoMsg
	.db 'other test',0

code:
	ldx #Messages.two
	lda Messages,x
	sta ptr
	lda Messages+1,x
	sta ptr+1
	ldy #0
:loop
	lda (ptr),y
	beq :out
	jsr CHROUT
	iny
	bne :loop
:out
	rts
```



### Operators

There is no operator precedence among binary operators, and they are evaluated left to right. Use ( parenthesis ) to specify order of operation if needed. Unary operators have higher precedence.

| Opeartor |   |
| -------- | - |
| `+` | Add |
| `-` | Subtract |
| `-` (unary) | Negate |
| `&` | And |
| `^` | Xor |
| `.` | Or |
| `!` (unary) | Not |
| `<` (unary) | Low byte of 16 bit value |
| `>` (unary) | High byte of 16 bit value |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |
| `=` | Equal |
| `!=` | Not Equal |
| `%` | Align |

Truth operators return -1 ($ffff) for true, 0 otherwise.
The align operator is undefined with right hand values > $100 or not a power of two. It evaluates to the next value up to meet the alignment:
```
* 	= * % 4		; pad zeros in output to align up to next 4 byte bounary
dword:
	.dw 1,2

	.or * % $100	; set PC to next page bounary
buffer:			; buffer points at PC
```

## Program Counter

The special `*` symbol refers to the current PC. This value may be assigned, but only forward and will cause zeros to be emitted if the assignment is not the current PC.

```
someData: *=*+50	; writes 50 bytes worth of zeros

	* = * % 4
dword:	.dw 0,0		; align dword on 4 byte boundary

	*=*+0		; does nothing

	*=*-5		; causes an error
```

A more practical example:

```
	.dw $801
	.or $801

header:
	; 10 SYS 2062
	.dw :zero, 10
	.db $9e,' 2062',0
:zero
	.dw 0

	*=2062
start:
```

## Directives

`.or`

Originate. Sets the program counter to the result of a word expression. This can set the PC to literally any value and does not need to reflect where the actual output is. For example:

```
	; arbitrary code to be copied to $3000
savePC 	= *
	.or $3000
otherRoutine:
	...
:len 	= * - otherRoutine

	.or savePC + otherRoutine:len	; resume with PC at memory position
```

`.if`

Conditional assembly. If the evaluation is non-0, assembly proceeds. If conditions may be nested up to 8 levels.
(Exceeding this does not cause an error and has unpredictable results)

In addition to the same source files supporting multiple configurations or options in the program,
this mechanism can also support files providing no output code but definitions:

```
	.if zpAsm != 0 ; symbols have non zp value defaults on first pass
zpAsm=0

scratch	= $30
ptr	= $31

	.fi	; zpAsm
```

If this file were called `zp.asm`, then it could be included in mutiple included source files:

```
	.in 'zp.asm' 	; include at top for zero page definitions
...
```

`.fi`

Ends if `.if` section.

`.el`

If no conditional assembly inside the `.if` directive has yet ran, begin conditional assembly.

`.ei`

Else-If. If no conditional assembly inside the `.if` directive has yet ran and the evaluation is non-0, assembly proceeds.

`.in`

Include. Includes a soure file. The filename, like a `.db` string, must be withing single 'quotes'.

`.dw`

Data word. Emits a 16 bit value. Multiple values may be separated with commas.

```
	.dw 1,2,3
	.dw expression+2,*
	.dw 0
```

`.db`

Data byte. Emits an 8 bit value. Mutiple values may be separated with commas. Strings may be specified in 'single quotes'.

```
	.db 1,2,3
	.db 13,'Message'
	.db >msbFirst,<msbFirst
	.db * ; low 8 bits of PC
```

