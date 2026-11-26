package main

import (
	"crypto/rand"
	_ "embed"
	"errors"
	"flag"
	"fmt"
	"io"
	"math/big"
	"os"
	"strings"
)

//go:embed eff_large_wordlist.txt
var rawWordlist string

// Strength comes from the random EFF words, not from symbols or digits.
// -number and -symbol only help pass site password rules, so this small set
// sticks to widely accepted ASCII symbols and skips shell-hostile ones like quotes and '$'.
const defaultSymbols = "!@#%&*+-=?"

type options struct {
	words      int
	sep        string
	count      int
	capitalize bool
	number     bool
	symbol     bool
}

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

func run(args []string, stdout, stderr io.Writer) int {
	var opts options
	fs := flag.NewFlagSet("diceware", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.IntVar(&opts.words, "w", 6, "number of words per passphrase")
	fs.IntVar(&opts.words, "words", 6, "number of words per passphrase")
	fs.StringVar(&opts.sep, "s", "-", "separator between words")
	fs.StringVar(&opts.sep, "sep", "-", "separator between words")
	fs.IntVar(&opts.count, "n", 1, "number of passphrases to generate")
	fs.IntVar(&opts.count, "count", 1, "number of passphrases to generate")
	fs.BoolVar(&opts.capitalize, "c", false, "capitalize the first letter of each word")
	fs.BoolVar(&opts.capitalize, "capitalize", false, "capitalize the first letter of each word")
	fs.BoolVar(&opts.number, "number", false, "append one random digit to a random word")
	fs.BoolVar(&opts.symbol, "symbol", false, "append one random symbol to a random word")
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: diceware [options]\n\n")
		fmt.Fprintf(stderr, "Generate offline passphrases from the embedded EFF Large Wordlist.\n\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return 0
		}
		return 2
	}

	if fs.NArg() != 0 {
		fmt.Fprintf(stderr, "Error: unexpected positional arguments\n")
		fs.Usage()
		return 2
	}
	if opts.words < 1 {
		fmt.Fprintf(stderr, "Error: -words must be at least 1\n")
		return 2
	}
	if opts.count < 1 {
		fmt.Fprintf(stderr, "Error: -count must be at least 1\n")
		return 2
	}

	words, err := parseWordlist(rawWordlist)
	if err != nil {
		fmt.Fprintf(stderr, "Error: %v\n", err)
		return 1
	}

	for range opts.count {
		passphrase, err := generatePassphrase(words, opts, rand.Reader)
		if err != nil {
			fmt.Fprintf(stderr, "Error: %v\n", err)
			return 1
		}
		fmt.Fprintln(stdout, passphrase)
	}
	return 0
}

func parseWordlist(raw string) ([]string, error) {
	lines := strings.Split(strings.TrimRight(raw, "\r\n"), "\n")
	words := make([]string, 0, len(lines))
	for i, line := range lines {
		line = strings.TrimRight(line, "\r")
		parts := strings.Split(line, "\t")
		if len(parts) != 2 || len(parts[0]) != 5 || parts[1] == "" {
			return nil, fmt.Errorf("invalid wordlist entry at line %d", i+1)
		}
		for j := range len(parts[0]) {
			if parts[0][j] < '1' || parts[0][j] > '6' {
				return nil, fmt.Errorf("invalid dice roll at line %d", i+1)
			}
		}
		words = append(words, parts[1])
	}
	if len(words) == 0 {
		return nil, errors.New("wordlist is empty")
	}
	return words, nil
}

func generatePassphrase(words []string, opts options, rng io.Reader) (string, error) {
	chosen := make([]string, opts.words)
	for i := range opts.words {
		idx, err := randInt(rng, len(words))
		if err != nil {
			return "", err
		}
		w := words[idx]
		if opts.capitalize {
			w = strings.ToUpper(w[:1]) + w[1:]
		}
		chosen[i] = w
	}

	if opts.number {
		target, err := randInt(rng, opts.words)
		if err != nil {
			return "", err
		}
		digit, err := randInt(rng, 10)
		if err != nil {
			return "", err
		}
		chosen[target] = fmt.Sprintf("%s%d", chosen[target], digit)
	}

	if opts.symbol {
		target, err := randInt(rng, opts.words)
		if err != nil {
			return "", err
		}
		symIdx, err := randInt(rng, len(defaultSymbols))
		if err != nil {
			return "", err
		}
		chosen[target] = chosen[target] + string(defaultSymbols[symIdx])
	}

	return strings.Join(chosen, opts.sep), nil
}

func randInt(rng io.Reader, limit int) (int, error) {
	n, err := rand.Int(rng, big.NewInt(int64(limit)))
	if err != nil {
		return 0, fmt.Errorf("read random number: %w", err)
	}
	return int(n.Int64()), nil
}
