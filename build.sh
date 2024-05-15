#!/bin/sh

. ./asm.sh

cp -f disk/xasm disk/XASM2

printf "XASM.ASM;@:XASM2;@:XASM.LST\0" > disk/args
run

