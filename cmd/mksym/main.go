package main

import (
	"flag"
	"log"
	"os"
	"path/filepath"
)

func main() {
	linkerFlag := flag.String("linker", "", "path - from")
	linkedFlag := flag.String("linked", "", "path - to")

	flag.Parse()

	linker := *linkerFlag
	linked := *linkedFlag

	if linker == "" || linked == "" {
		flag.Usage()
		log.Fatalln("empty path is given")
	}

	linked, err := filepath.Abs(linked)
	if err != nil {
		log.Fatalln(err)
	}

	_, err = os.Stat(linked)
	if err != nil {
		log.Fatalf("target does not exist, fix `linked` option - %v\n", err)
	}
	_, err = os.Stat(linker)
	if err == nil || !os.IsNotExist(err) {
		log.Fatalf("this script does not override existing symlinker files, fix `linker` option or manually remove the file - %v\n", err)
	}

	parent := filepath.Dir(linker)
	err = os.MkdirAll(parent, 0755)
	if err != nil {
		log.Fatalln(err)
	}

	err = os.Symlink(linked, linker)
	if err != nil {
		log.Fatalln(err)
	}
}
