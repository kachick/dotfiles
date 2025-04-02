package githooks

import (
	"fmt"
	"log"
	"os"
	"slices"
	"strings"
	"sync"
)

type Linter struct {
	Tag    string
	Script func() error
}

func MutexakeSkipChecker() func(string) bool {
	// `SKIP` is adjusted for pre-commit convention. See https://github.com/gitleaks/gitleaks/blob/v8.24.0/README.md?plain=1#L121-L127
	// Unnecessary to consider strict CSV spec such as https://pre-commit.com/
	skips := strings.Split(os.Getenv("SKIP"), ",")

	return func(tag string) bool {
		return slices.Contains(skips, tag)
	}
}

func RunLinters(linters map[string]Linter, shouldSkip func(string) bool) error {
	var mu sync.Mutex
	errs := map[string]error{}
	wg := &sync.WaitGroup{}

	for desc, linter := range linters {
		if shouldSkip(linter.Tag) {
			continue
		}

		wg.Add(1)
		go func(desc string, linter Linter) {
			defer wg.Done()
			log.Println(desc)
			if err := linter.Script(); err != nil {
				mu.Lock()
				errs[desc] = err
				mu.Unlock()
			}
		}(desc, linter)
	}
	wg.Wait()

	if len(errs) > 0 {
		return fmt.Errorf("linter errors: %v", errs)
	}
	return nil
}
