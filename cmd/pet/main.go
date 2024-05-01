package main

import (
	"bufio"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
)

var pet bool

func main() {
	var buf [4096]byte
	var r io.Reader

	flag.BoolVar(&pet, "pet", pet, "to PETSCII (uppercase has high bit)")
	flag.Parse()

	if flag.NArg() > 0 {
		f, err := os.Open(flag.Args()[0])
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		defer f.Close()
		r = f
	} else {
		r = os.Stdin
	}

	w := bufio.NewWriter(os.Stdout)

	for {
		nr, err := r.Read(buf[:])
		for n := 0; n < nr; n++ {
			b := buf[n]
			switch {
			case b == 13:
				b = '\n'
			case b == '\n':
				b = 13
			case b >= 97 && b <= 122:
				b -= 32
			case b >= 65 && b <= 90:
				b += 32
				if pet {
					b += 96
				}
			case b >= 192 && b <= 223:
				b -= 96
				if b >= 97 && b <= 122 {
					b -= 32
				}
			default:
			}
			w.WriteByte(b)
		}

		if err != nil {
			if !errors.Is(err, io.EOF) {
				fmt.Fprintln(os.Stderr, err)
				os.Exit(1)
			}
			break
		}
	}

	w.Flush()
}
