
ASMS=	$(wildcard asm/*.asm)
PETS=	$(patsubst asm/%,disk/%,$(ASMS))

.PHONY: all
all: disk disk/XASM2 disk/XASM.LST disk/TEST.LST

.PHONY: pets
pets: disk $(PETS)

.PHONY: dist
dist: disk/XASM2 disk/XASM.LST disk/TEST.LST
	./pet disk/XASM.LST > bin/xasm.lst
	./pet disk/TEST.LST > bin/test.lst
	cp -f disk/XASM2 bin/xasm.prg

.PHONY: test
test: test.lst
	cmp test.lst bin/test.lst || diff test.lst bin/test.lst

test.lst : disk/TEST.LST
	./pet $< > $@

disk:
	mkdir -p disk

disk/XASM2 disk/XASM.LST disk/TEST.LST : disk/xasm disk/test.asm $(PETS)
	./build.sh

disk/xasm: bin/xasm.prg
	cp $< $@

disk/test.asm: test/test.asm
	./pet -pet $< > $@

asm/isns-table.asm: gen
	./gen > $@

$(PETS) :: pet

disk/%.asm : asm/%.asm
	./pet -pet $< > $@

pet: cmd/pet/*.go
	go build ./cmd/pet

gen: cmd/gen/*.go
	go build ./cmd/gen


