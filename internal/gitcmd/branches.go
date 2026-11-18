package gitcmd

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
)

// ErrSelectionCanceled indicates that the user aborted interactive selection in fzf.
var ErrSelectionCanceled = errors.New("selection canceled")

// BranchCandidate holds metadata for a local branch presented in interactive selection.
type BranchCandidate struct {
	Name       string
	ShortDate  string
	RelDate    string
	AuthorName string
	Subject    string
	IsCurrent  bool
	IsDefault  bool
	IsMerged   bool
	IsMine     bool
}

// CandidateOptions controls how CollectLocalBranchCandidates filters and tags branches.
type CandidateOptions struct {
	CurrentBranch        string
	DefaultBranch        string
	AllowCheckedOutDir   string
	IncludeUnbornCurrent bool
}

// FzfBranchSelectOptions configures fzf flags and preview invocation for branch selection.
type FzfBranchSelectOptions struct {
	SelfExe            string
	RepoDir            string
	DefaultBranch      string
	PreviewArgs        []string
	BorderLabel        string
	Header             string
	InitialSelectCount int
}

// WorktreeDirName converts a branch name into a flat worktree directory name.
func WorktreeDirName(branch string) (string, error) {
	// Replace "/" so all worktrees stay flat at depth 1 under the repository directory.
	branchDir := strings.ReplaceAll(branch, "/", "-")
	if branchDir == "" || branchDir == "." || branchDir == ".." || branchDir == ".git" {
		return "", fmt.Errorf("invalid target worktree directory name %q for branch %q", branchDir, branch)
	}
	return branchDir, nil
}

// ValidateTargetWorktreeDirs maps branch names to flat worktree paths and rejects name collisions.
func ValidateTargetWorktreeDirs(repoDir string, branches []string) (map[string]string, error) {
	dirs := make(map[string]string, len(branches))
	seenDirs := make(map[string]string, len(branches))
	for _, branch := range branches {
		dirName, err := WorktreeDirName(branch)
		if err != nil {
			return nil, err
		}
		if prevBranch, exists := seenDirs[dirName]; exists {
			return nil, fmt.Errorf("worktree directory collision %q between branches %q and %q", dirName, prevBranch, branch)
		}
		seenDirs[dirName] = branch
		dirs[branch] = filepath.Join(repoDir, dirName)
	}
	return dirs, nil
}

// ResolveTargetRef returns the first existing local or remote ref for branch, or "".
func ResolveTargetRef(r *Runner, branch string) string {
	if branch == "" {
		return ""
	}
	for _, ref := range []string{
		"refs/heads/" + branch,
		"refs/remotes/origin/" + branch,
		"refs/remotes/upstream/" + branch,
	} {
		if r.Ok("show-ref", "--verify", "--quiet", ref) {
			return ref
		}
	}
	return ""
}

func resolveRealPath(path string) string {
	abs, err := filepath.Abs(path)
	if err != nil {
		return filepath.Clean(path)
	}
	resolved, err := filepath.EvalSymlinks(abs)
	if err != nil {
		return abs
	}
	return resolved
}

func listMergedBranchSet(r *Runner, targetRef string) (map[string]bool, error) {
	merged := make(map[string]bool)
	if targetRef == "" {
		return merged, nil
	}
	raw, err := r.OutputRaw("for-each-ref", "--merged="+targetRef, "--format=%(refname:short)", "refs/heads/")
	if err != nil {
		return nil, err
	}
	for line := range bytes.SplitSeq(raw, []byte{'\n'}) {
		name := strings.TrimSpace(string(line))
		if name != "" {
			merged[name] = true
		}
	}
	return merged, nil
}

func candidateRank(c BranchCandidate) int {
	switch {
	case c.IsCurrent:
		return 0
	case c.IsDefault:
		return 1
	case !c.IsMerged && c.IsMine:
		return 2
	case !c.IsMerged:
		return 3
	default:
		return 4
	}
}

// CollectLocalBranchCandidates lists local branches sorted by relevance for worktree creation.
func CollectLocalBranchCandidates(r *Runner, opts CandidateOptions) ([]BranchCandidate, error) {
	userEmail, _ := r.Output("config", "--get", "user.email")
	userEmail = strings.TrimSpace(userEmail)

	mergedTarget := ResolveTargetRef(r, opts.DefaultBranch)
	mergedSet, err := listMergedBranchSet(r, mergedTarget)
	if err != nil {
		return nil, err
	}

	const format = "%(refname:short)%00%(worktreepath)%00%(committerdate:short)%00%(committerdate:relative)%00%(authoremail)%00%(authorname)%00%(contents:subject)"
	raw, err := r.OutputRaw("for-each-ref", "--sort=-committerdate", "--format="+format, "refs/heads/")
	if err != nil {
		return nil, err
	}

	realAllowDir := ""
	if opts.AllowCheckedOutDir != "" {
		realAllowDir = resolveRealPath(opts.AllowCheckedOutDir)
	}

	var candidates []BranchCandidate
	seenCurrent := false

	for lineBytes := range bytes.SplitSeq(raw, []byte{'\n'}) {
		if len(lineBytes) == 0 {
			continue
		}
		fields := bytes.SplitN(lineBytes, []byte{0}, 7)
		if len(fields) < 7 {
			continue
		}
		name := string(fields[0])
		wtPath := string(fields[1])
		shortDate := string(fields[2])
		relDate := string(fields[3])
		authorEmail := strings.Trim(strings.TrimSpace(string(fields[4])), "<>")
		authorName := string(fields[5])
		subject := string(fields[6])

		if name == "" {
			continue
		}
		if wtPath != "" && (realAllowDir == "" || resolveRealPath(wtPath) != realAllowDir) {
			// Skip branches already checked out in a linked worktree.
			continue
		}

		isCurrent := opts.CurrentBranch != "" && name == opts.CurrentBranch
		if isCurrent {
			seenCurrent = true
		}
		isDefault := opts.DefaultBranch != "" && name == opts.DefaultBranch
		isMine := userEmail != "" && strings.EqualFold(authorEmail, userEmail)

		candidates = append(candidates, BranchCandidate{
			Name:       name,
			ShortDate:  shortDate,
			RelDate:    relDate,
			AuthorName: authorName,
			Subject:    subject,
			IsCurrent:  isCurrent,
			IsDefault:  isDefault,
			IsMerged:   !isDefault && mergedSet[name],
			IsMine:     isMine,
		})
	}

	if opts.IncludeUnbornCurrent && opts.CurrentBranch != "" && !seenCurrent {
		candidates = append(candidates, BranchCandidate{
			Name:      opts.CurrentBranch,
			ShortDate: "-",
			RelDate:   "unborn",
			Subject:   "(unborn HEAD)",
			IsCurrent: true,
			IsDefault: opts.CurrentBranch == opts.DefaultBranch,
		})
	}

	slices.SortStableFunc(candidates, func(a, b BranchCandidate) int {
		return candidateRank(a) - candidateRank(b)
	})

	return candidates, nil
}

func sanitizeField(s string) string {
	return strings.ReplaceAll(s, "\t", " ")
}

func formatCandidateTags(c BranchCandidate) string {
	var tags []string
	if c.IsCurrent {
		tags = append(tags, "\x1b[1;36mcurrent\x1b[0m")
	}
	if c.IsDefault {
		tags = append(tags, "\x1b[32mdefault\x1b[0m")
	}
	if c.IsMine {
		tags = append(tags, "\x1b[33mmine\x1b[0m")
	}
	if !c.IsDefault && c.IsMerged {
		tags = append(tags, "\x1b[2mmerged\x1b[0m")
	} else if !c.IsDefault {
		tags = append(tags, "\x1b[35munmerged\x1b[0m")
	}
	return "[" + strings.Join(tags, ",") + "]"
}

// FormatCandidateLine formats a branch candidate as a tab-delimited line for fzf.
func FormatCandidateLine(c BranchCandidate) string {
	tags := formatCandidateTags(c)
	metaParts := []string{tags}
	if c.ShortDate != "" {
		metaParts = append(metaParts, fmt.Sprintf("\x1b[36m%s\x1b[0m (%s)", sanitizeField(c.ShortDate), sanitizeField(c.RelDate)))
	}
	if c.AuthorName != "" {
		metaParts = append(metaParts, sanitizeField(c.AuthorName))
	}
	if c.Subject != "" {
		metaParts = append(metaParts, sanitizeField(c.Subject))
	}
	return fmt.Sprintf("%s\t%s", sanitizeField(c.Name), strings.Join(metaParts, "  "))
}

// CountInitialSelections counts leading current/default candidates to pre-select in fzf.
func CountInitialSelections(candidates []BranchCandidate) int {
	count := 0
	for _, c := range candidates {
		if c.IsCurrent || c.IsDefault {
			count++
		} else {
			break
		}
	}
	return count
}

func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

// FzfBranchSelectArgs builds fzf arguments for multi-selecting local branches with live preview.
func FzfBranchSelectArgs(opts FzfBranchSelectOptions) []string {
	previewParts := make([]string, 0, 1+len(opts.PreviewArgs)+2)
	previewParts = append(previewParts, shellQuote(opts.SelfExe))
	for _, arg := range opts.PreviewArgs {
		previewParts = append(previewParts, shellQuote(arg))
	}
	previewParts = append(previewParts, shellQuote(opts.RepoDir), shellQuote(opts.DefaultBranch), "{1}")
	previewCmd := strings.Join(previewParts, " ")
	args := []string{
		"--height=75%",
		"--tmux=90%,70%",
		"--layout=reverse",
		"--min-height=20+",
		"--border",
		"--no-separator",
		"--header-border=horizontal",
		"--border-label-pos=2",
		"--color=label:blue",
		"--border-label=" + opts.BorderLabel,
		"--multi",
		"--sync",
		"--ansi",
		"--delimiter=\t",
		"--with-nth=1,2",
		"--accept-nth=1",
		"--preview=" + previewCmd,
		"--preview-window=right,60%",
		"--preview-border=line",
		"--header=" + opts.Header,
		"--bind=ctrl-/:change-preview-window(down,60%|hidden|)",
	}
	if opts.InitialSelectCount == 1 {
		args = append(args, "--bind=load:pos(1)+select")
	} else if opts.InitialSelectCount >= 2 {
		args = append(args, "--bind=load:pos(1)+select+pos(2)+select+pos(1)")
	}
	return args
}

// SelectBranchesWithFzf runs fzf to pick one or more branches from candidates.
func SelectBranchesWithFzf(opts FzfBranchSelectOptions, candidates []BranchCandidate, stderr io.Writer) ([]string, error) {
	if opts.SelfExe == "" {
		selfExe, err := os.Executable()
		if err != nil {
			return nil, fmt.Errorf("resolve executable path: %w", err)
		}
		opts.SelfExe = selfExe
	}

	var input strings.Builder
	for _, c := range candidates {
		input.WriteString(FormatCandidateLine(c))
		input.WriteByte('\n')
	}

	cmd := exec.Command("fzf", FzfBranchSelectArgs(opts)...)
	cmd.Stdin = strings.NewReader(input.String())
	var fzfOut bytes.Buffer
	cmd.Stdout = &fzfOut
	cmd.Stderr = stderr

	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) && (exitErr.ExitCode() == 1 || exitErr.ExitCode() == 130) {
			return nil, ErrSelectionCanceled
		}
		return nil, fmt.Errorf("fzf failed: %w", err)
	}

	var picked []string
	for raw := range strings.SplitSeq(fzfOut.String(), "\n") {
		branch := strings.TrimSpace(raw)
		if branch != "" {
			picked = append(picked, branch)
		}
	}
	return picked, nil
}

// RenderBranchPreview writes target path, diff stat vs defaultBranch, and recent commits for branch.
func RenderBranchPreview(repoDir, defaultBranch, branch string, stdout, stderr io.Writer) error {
	if branch == "" {
		return nil
	}

	dirName, err := WorktreeDirName(branch)
	targetText := "(invalid directory name)"
	if err == nil {
		targetText = filepath.Join(repoDir, dirName)
	}
	fmt.Fprintf(stdout, "Branch:   %s\nWorktree: %s\n", branch, targetText)

	r := NewIsolated(repoDir, stdout, stderr)
	if !r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch) {
		fmt.Fprintln(stdout, "\n(unborn branch; no commits yet)")
		return nil
	}

	if defaultBranch != "" && branch != defaultBranch {
		if targetRef := ResolveTargetRef(r, defaultBranch); targetRef != "" {
			if stat, err := r.Output("diff", "--stat", "--color=always", targetRef+"..."+branch); err == nil && stat != "" {
				fmt.Fprintf(stdout, "\nDiff vs %s:\n%s\n", defaultBranch, stat)
			}
		}
	}

	fmt.Fprintln(stdout)
	return r.Stream("log",
		"--format=format:%C(cyan)%ad %C(auto)%h %C(auto)%s %C(auto)%d",
		"--date=short", "--color=always", "-n", "20", branch)
}
