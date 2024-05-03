#!/bin/sh

. ./asm.sh

cp -f disk/XASM2 disk/XASM3
run
cmp disk/XASM2 disk/XASM3 || exit 1

printf "TEST.ASM;;@:TEST.LST\0" > disk/args
run


