package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	for _, env := range os.Environ() {
		kv := strings.SplitN(env, "=", 2)
		key, val := kv[0], kv[1]
		fmt.Printf("%s=%s\n", key, val[:25])
	}
}
