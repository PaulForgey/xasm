#!/bin/sh

. ./asm.sh

cp -f disk/XASM disk/XASM2

printf "XASM.ASM;@:XASM2;@:XASM.LST\0" > disk/args
run

