package configsync

import (
	"bytes"
	"fmt"
	"strings"
)

const (
	diffContextLines = 3
	maxLCSCells      = 4_000_000
)

type diffOpKind uint8

const (
	opEqual diffOpKind = iota
	opDelete
	opInsert
)

type diffOp struct {
	kind diffOpKind
	line string
}

// UnifiedDiff returns a unified diff between oldBytes and newBytes.
// It returns an empty string when the contents are identical.
func UnifiedDiff(oldLabel, newLabel string, oldBytes, newBytes []byte) string {
	if bytes.Equal(oldBytes, newBytes) {
		return ""
	}
	if bytes.IndexByte(oldBytes, 0) >= 0 || bytes.IndexByte(newBytes, 0) >= 0 {
		return fmt.Sprintf("--- %s\n+++ %s\nBinary files differ (%d bytes -> %d bytes)\n",
			oldLabel, newLabel, len(oldBytes), len(newBytes))
	}

	oldLines := splitLines(string(oldBytes))
	newLines := splitLines(string(newBytes))
	ops := computeDiffOps(oldLines, newLines)

	hunks := buildHunks(ops, diffContextLines)
	if len(hunks) == 0 {
		return ""
	}

	var b strings.Builder
	fmt.Fprintf(&b, "--- %s\n+++ %s\n", oldLabel, newLabel)
	for _, h := range hunks {
		fmt.Fprintf(&b, "@@ -%d,%d +%d,%d @@\n", h.oldStart, h.oldCount, h.newStart, h.newCount)
		for _, op := range h.ops {
			switch op.kind {
			case opEqual:
				b.WriteByte(' ')
			case opDelete:
				b.WriteByte('-')
			case opInsert:
				b.WriteByte('+')
			}
			b.WriteString(op.line)
			b.WriteByte('\n')
		}
	}
	return b.String()
}

func splitLines(s string) []string {
	if s == "" {
		return nil
	}
	s = strings.ReplaceAll(s, "\r\n", "\n")
	s = strings.TrimSuffix(s, "\n")
	return strings.Split(s, "\n")
}

func computeDiffOps(oldLines, newLines []string) []diffOp {
	n := len(oldLines)
	m := len(newLines)

	// Guard against quadratic memory growth on huge files by falling back to a full replace diff.
	if n*m > maxLCSCells {
		ops := make([]diffOp, 0, n+m)
		for _, line := range oldLines {
			ops = append(ops, diffOp{kind: opDelete, line: line})
		}
		for _, line := range newLines {
			ops = append(ops, diffOp{kind: opInsert, line: line})
		}
		return ops
	}

	// Build suffix LCS table so forward reconstruction naturally orders deletes before inserts.
	dp := make([][]int, n+1)
	for i := range dp {
		dp[i] = make([]int, m+1)
	}
	for i := n - 1; i >= 0; i-- {
		for j := m - 1; j >= 0; j-- {
			if oldLines[i] == newLines[j] {
				dp[i][j] = dp[i+1][j+1] + 1
			} else if dp[i+1][j] >= dp[i][j+1] {
				dp[i][j] = dp[i+1][j]
			} else {
				dp[i][j] = dp[i][j+1]
			}
		}
	}

	ops := make([]diffOp, 0, n+m)
	i, j := 0, 0
	for i < n && j < m {
		if oldLines[i] == newLines[j] {
			ops = append(ops, diffOp{kind: opEqual, line: oldLines[i]})
			i++
			j++
		} else if dp[i+1][j] >= dp[i][j+1] {
			ops = append(ops, diffOp{kind: opDelete, line: oldLines[i]})
			i++
		} else {
			ops = append(ops, diffOp{kind: opInsert, line: newLines[j]})
			j++
		}
	}
	for i < n {
		ops = append(ops, diffOp{kind: opDelete, line: oldLines[i]})
		i++
	}
	for j < m {
		ops = append(ops, diffOp{kind: opInsert, line: newLines[j]})
		j++
	}
	return ops
}

type hunk struct {
	oldStart int
	oldCount int
	newStart int
	newCount int
	ops      []diffOp
}

func buildHunks(ops []diffOp, context int) []hunk {
	type indexedOp struct {
		op     diffOp
		oldPos int
		newPos int
	}

	indexed := make([]indexedOp, len(ops))
	oldPos, newPos := 1, 1
	for idx, op := range ops {
		indexed[idx] = indexedOp{op: op, oldPos: oldPos, newPos: newPos}
		switch op.kind {
		case opEqual:
			oldPos++
			newPos++
		case opDelete:
			oldPos++
		case opInsert:
			newPos++
		}
	}

	var hunks []hunk
	i := 0
	for i < len(indexed) {
		if indexed[i].op.kind == opEqual {
			i++
			continue
		}
		start := max(0, i-context)
		end := i
		for end < len(indexed) {
			if indexed[end].op.kind != opEqual {
				end++
				continue
			}
			// Merge nearby changes if the equal gap is small enough to share context.
			nextChange := end
			for nextChange < len(indexed) && indexed[nextChange].op.kind == opEqual {
				nextChange++
			}
			if nextChange < len(indexed) && nextChange-end <= context*2 {
				end = nextChange
				continue
			}
			break
		}
		end = min(len(indexed), end+context)

		h := hunk{
			oldStart: indexed[start].oldPos,
			newStart: indexed[start].newPos,
			ops:      make([]diffOp, 0, end-start),
		}
		for k := start; k < end; k++ {
			op := indexed[k].op
			h.ops = append(h.ops, op)
			switch op.kind {
			case opEqual:
				h.oldCount++
				h.newCount++
			case opDelete:
				h.oldCount++
			case opInsert:
				h.newCount++
			}
		}
		hunks = append(hunks, h)
		i = end
	}
	return hunks
}
