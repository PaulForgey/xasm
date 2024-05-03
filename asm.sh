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

