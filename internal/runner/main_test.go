package runner

import (
	"bytes"
	"log"
	"strings"
	"testing"
)

func TestParallelRunCollectsAllErrors(t *testing.T) {
	var buf bytes.Buffer
	origOut := log.Writer()
	log.SetOutput(&buf)
	defer log.SetOutput(origOut)

	cmds := Commands{
		{Path: "sh", Args: []string{"-c", "echo fail-one; exit 1"}},
		{Path: "sh", Args: []string{"-c", "echo ok-two"}},
		{Path: "sh", Args: []string{"-c", "echo fail-three; exit 2"}},
	}

	err := cmds.ParallelRun()
	if err == nil {
		t.Fatal("expected error from ParallelRun, got nil")
	}

	logged := buf.String()
	for _, want := range []string{"fail-one", "ok-two", "fail-three"} {
		if !strings.Contains(logged, want) {
			t.Errorf("expected log output to contain %q, got:\n%s", want, logged)
		}
	}
}

func TestSequentialRunStopsOnFirstError(t *testing.T) {
	var buf bytes.Buffer
	origOut := log.Writer()
	log.SetOutput(&buf)
	defer log.SetOutput(origOut)

	cmds := Commands{
		{Path: "sh", Args: []string{"-c", "echo step-one; exit 1"}},
		{Path: "sh", Args: []string{"-c", "echo step-two"}},
	}

	err := cmds.SequentialRun()
	if err == nil {
		t.Fatal("expected error from SequentialRun, got nil")
	}

	logged := buf.String()
	if !strings.Contains(logged, "step-one") {
		t.Errorf("expected log output to contain step-one, got:\n%s", logged)
	}
	if strings.Contains(logged, "step-two") {
		t.Errorf("expected SequentialRun to stop before step-two, got:\n%s", logged)
	}
}
