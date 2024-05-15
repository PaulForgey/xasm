#!/bin/sh

. ./asm.sh

printf "XASM.ASM;@:XASM2;@:XASM.LST\0" > disk/args
cp -f disk/XASM2 disk/XASM3
run
cmp disk/XASM2 disk/XASM3 || exit 1

printf "TEST.ASM;;@:TEST.LST\0" > disk/args
run


