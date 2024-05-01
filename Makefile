
ASMS=	$(wildcard asm/*.asm)
PETS=	$(patsubst asm/%,disk/%,$(ASMS))

.PHONY: all
all: disk disk/XASM2 disk/XASM.LST

.PHONY: pets
pets: disk $(PETS)

.PHONY: dist
dist: disk/XASM2 disk/XASM.LST
	./pet disk/XASM.LST > bin/xasm.lst
	cp -f disk/XASM2 bin/xasm.prg

disk:
	mkdir -p disk

disk/XASM2 disk/XASM.LST: disk/xasm $(PETS)
	./build.sh

disk/xasm: bin/xasm.prg
	cp $< $@

asm/isns-table.asm: gen
	./gen > $@

$(PETS) :: pet

disk/%.asm : asm/%.asm
	./pet -pet $< > $@

pet: cmd/pet/*.go
	go build ./cmd/pet

gen: cmd/gen/*.go
	go build ./cmd/gen


