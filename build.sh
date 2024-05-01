#!/bin/sh

printf "XASM.ASM;@:XASM2;@:XASM.LST\0" > disk/args

cat<<EOF >build.in
BLOAD "ARGS",8,0,\$BF00
LOAD "XASM",8,1
RUN
POWEROFF
EOF

x16emu -fsroot disk -bas build.in -echo raw | ./pet


