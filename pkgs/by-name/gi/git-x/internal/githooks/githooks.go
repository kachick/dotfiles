package githooks

import (
	"fmt"
	"log"
	"sync"
)

type Linter struct {
	Tag    string
	Script func() error
}

func RunLinters(linters map[string]Linter) error {
	var mu sync.Mutex
	errs := map[string]error{}
	wg := new(sync.WaitGroup)

	for desc, linter := range linters {
		wg.Go(func() {
			log.Println(desc)
			if err := linter.Script(); err != nil {
				mu.Lock()
				errs[desc] = err
				mu.Unlock()
			}
		})
	}
	wg.Wait()

	if len(errs) > 0 {
		return fmt.Errorf("linter errors: %v", errs)
	}
	return nil
}
