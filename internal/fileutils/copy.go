package fileutils

import (
	"io"
	"os"
)

type Copy struct {
	Src string
	Dst string
}

func (c Copy) Run() error {
	src, err := os.Open(c.Src)
	if err != nil {
		return err
	}
	defer src.Close()
	dst, err := os.Create(c.Dst)
	if err != nil {
		return err
	}
	defer dst.Close()

	_, err = io.Copy(dst, src)
	return err
}
