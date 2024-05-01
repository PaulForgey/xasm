#!/bin/sh

run() {

cat<<EOF >build.in
BLOAD "ARGS",8,0,\$BF00
LOAD "XASM2",8,1
RUN
POWEROFF
EOF

x16emu -fsroot disk -bas build.in -echo raw | ./pet

}


cp -f disk/XASM disk/XASM2

printf "XASM.ASM;@:XASM2;@:XASM.LST\0" > disk/args
run

printf "TEST.ASM;;@:TEST.LST\0" > disk/args
run


