#!/bin/sh

docker run --rm -v .:/disk -w /disk paulforgey/x16emu /x16emu $@

