package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/url"
	"os"
	"os/exec"
	"regexp"
	"slices"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

const prLookupBatchSize = 25

var resetBranchBackupPattern = regexp.MustCompile(`^backup-.+-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)

type localBranch struct {
	name   string
	wtPath string
	oid    string
}

type pullRequestInfo struct {
	State       string `json:"state"`
	HeadRefName string `json:"headRefName"`
	HeadRefOid  string `json:"headRefOid"`
}

type prLookupFunc func(workDir, repo string, branches []string) (map[string][]pullRequestInfo, error)

func listBranchesByMergeFilter(r *gitcmd.Runner, mergeFilter string) ([]localBranch, error) {
	// Specify --sort=refname so global branch.sort config does not change ordering.
	raw, err := r.OutputRaw("for-each-ref", "--sort=refname", mergeFilter, "--format=%(refname:short)%00%(worktreepath)%00%(objectname)", "refs/heads/")
	if err != nil {
		return nil, err
	}

	var result []localBranch
	for lineBytes := range bytes.SplitSeq(raw, []byte{'\n'}) {
		if len(lineBytes) == 0 {
			continue
		}
		fields := bytes.SplitN(lineBytes, []byte{0}, 3)
		branch := string(fields[0])
		if branch == "" {
			continue
		}
		var wtPath string
		if len(fields) >= 2 {
			wtPath = string(fields[1])
		}
		var oid string
		if len(fields) >= 3 {
			oid = string(fields[2])
		}
		result = append(result, localBranch{name: branch, wtPath: wtPath, oid: oid})
	}
	return result, nil
}

func parseGitHubRepoURL(rawURL string) (string, bool) {
	rawURL = strings.TrimSpace(rawURL)
	if rawURL == "" {
		return "", false
	}

	var host, path string
	if strings.Contains(rawURL, "://") {
		u, err := url.Parse(rawURL)
		if err != nil {
			return "", false
		}
		host = u.Hostname()
		path = u.Path
	} else if after, ok := strings.CutPrefix(rawURL, "git@"); ok {
		h, p, found := strings.Cut(after, ":")
		if !found {
			return "", false
		}
		host = h
		path = p
	} else {
		return "", false
	}

	if !strings.EqualFold(host, "github.com") {
		return "", false
	}

	path = strings.Trim(path, "/")
	path = strings.TrimSuffix(path, ".git")
	owner, repo, found := strings.Cut(path, "/")
	if !found || owner == "" || repo == "" || strings.Contains(repo, "/") {
		return "", false
	}
	return owner + "/" + repo, true
}

func resolveGitHubRepo(r *gitcmd.Runner) string {
	for _, remote := range []string{"upstream", "origin"} {
		rawURL, err := r.Output("remote", "get-url", remote)
		if err != nil {
			continue
		}
		if repo, ok := parseGitHubRepoURL(rawURL); ok {
			return repo
		}
	}
	return ""
}

func buildPRLookupQuery(branches []string) string {
	var vars strings.Builder
	var fields strings.Builder
	for i := range branches {
		fmt.Fprintf(&vars, ", $b%d: String!", i)
		fmt.Fprintf(&fields, " open%d: pullRequests(headRefName: $b%d, states: [OPEN], first: 1) { totalCount }", i, i)
		fmt.Fprintf(&fields, " merged%d: pullRequests(headRefName: $b%d, states: [MERGED], last: 20) { nodes { headRefOid } }", i, i)
	}
	return fmt.Sprintf("query($owner: String!, $name: String!%s) { repository(owner: $owner, name: $name) {%s } }", vars.String(), fields.String())
}

func lookupMergedBranchPRBatch(workDir, repo string, branches []string) (map[string][]pullRequestInfo, error) {
	query := buildPRLookupQuery(branches)
	args := []string{"api", "graphql"}
	if owner, name, ok := strings.Cut(repo, "/"); ok && owner != "" && name != "" {
		args = append(args, "-f", "owner="+owner, "-f", "name="+name)
	} else {
		args = append(args, "-F", "owner={owner}", "-F", "name={repo}")
	}
	args = append(args, "-f", "query="+query)
	for i, branch := range branches {
		args = append(args, "-f", fmt.Sprintf("b%d=%s", i, branch))
	}

	cmd := exec.Command("gh", args...)
	if workDir != "" {
		cmd.Dir = workDir
	}
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("gh api graphql: %w: %s", err, strings.TrimSpace(stderr.String()))
	}

	var resp struct {
		Data struct {
			Repository map[string]json.RawMessage `json:"repository"`
		} `json:"data"`
		Errors []struct {
			Message string `json:"message"`
		} `json:"errors"`
	}
	if err := json.Unmarshal(stdout.Bytes(), &resp); err != nil {
		return nil, fmt.Errorf("parse gh api graphql output: %w", err)
	}
	if len(resp.Errors) > 0 {
		return nil, fmt.Errorf("gh api graphql error: %s", resp.Errors[0].Message)
	}
	if resp.Data.Repository == nil {
		return nil, fmt.Errorf("repository not found in gh api graphql output")
	}

	result := make(map[string][]pullRequestInfo, len(branches))
	for i, branch := range branches {
		var openResp struct {
			TotalCount int `json:"totalCount"`
		}
		if raw, ok := resp.Data.Repository[fmt.Sprintf("open%d", i)]; ok {
			if err := json.Unmarshal(raw, &openResp); err != nil {
				return nil, fmt.Errorf("parse open PRs for %s: %w", branch, err)
			}
		}
		var mergedResp struct {
			Nodes []struct {
				HeadRefOid string `json:"headRefOid"`
			} `json:"nodes"`
		}
		if raw, ok := resp.Data.Repository[fmt.Sprintf("merged%d", i)]; ok {
			if err := json.Unmarshal(raw, &mergedResp); err != nil {
				return nil, fmt.Errorf("parse merged PRs for %s: %w", branch, err)
			}
		}

		var prs []pullRequestInfo
		if openResp.TotalCount > 0 {
			prs = append(prs, pullRequestInfo{State: "OPEN", HeadRefName: branch})
		}
		for _, node := range mergedResp.Nodes {
			prs = append(prs, pullRequestInfo{State: "MERGED", HeadRefName: branch, HeadRefOid: node.HeadRefOid})
		}
		result[branch] = prs
	}
	return result, nil
}

func lookupMergedBranchPRs(workDir, repo string, branches []string) (map[string][]pullRequestInfo, error) {
	result := make(map[string][]pullRequestInfo, len(branches))
	for chunk := range slices.Chunk(branches, prLookupBatchSize) {
		batchResult, err := lookupMergedBranchPRBatch(workDir, repo, chunk)
		if err != nil {
			return nil, err
		}
		for branch, prs := range batchResult {
			result[branch] = prs
		}
	}
	return result, nil
}

func shouldDeleteFromPRs(branchName, branchOID string, prs []pullRequestInfo) bool {
	if branchName == "" || branchOID == "" {
		return false
	}
	hasMergedTipMatch := false
	for _, pr := range prs {
		if pr.HeadRefName != branchName {
			continue
		}
		// Keep the branch if any PR for the same branch name is still open.
		if strings.EqualFold(pr.State, "OPEN") {
			return false
		}
		if strings.EqualFold(pr.State, "MERGED") && pr.HeadRefOid == branchOID {
			hasMergedTipMatch = true
		}
	}
	return hasMergedTipMatch
}

func resolveDeleteRunner(r *gitcmd.Runner, ctx gitcmd.RepoContext, defaultBranch, defaultWT string) *gitcmd.Runner {
	if defaultWT != "" && isDir(defaultWT) {
		return r.InDir(defaultWT)
	}
	if ctx.IsBare {
		commonRunner := r.InDir(ctx.CommonDir)
		if head, err := commonRunner.Output("symbolic-ref", "--short", "HEAD"); err == nil && head == defaultBranch {
			return commonRunner
		}
	}
	return r
}

func shouldSkipProtectedEntry(ctx gitcmd.RepoContext, defaultBranch string, entry localBranch, stderr io.Writer) bool {
	if entry.name == defaultBranch || gitcmd.IsProtectedBranch(entry.name) {
		return true
	}
	if gitcmd.IsCleanBareDefaultWorktree(ctx, defaultBranch, entry.wtPath) {
		// Never remove the default worktree directory even if a feature branch was checked out inside it.
		fmt.Fprintf(stderr, "Skipping branch %s (checked out in default worktree %s)\n", entry.name, entry.wtPath)
		return true
	}
	return false
}

func deleteBranchEntry(r, deleteRunner *gitcmd.Runner, entry localBranch, cwdReal string, forceDelete, dryRun bool, stdout, stderr io.Writer) error {
	if entry.wtPath != "" && isDir(entry.wtPath) {
		wtReal := resolveRealPath(entry.wtPath)
		if isSameOrInside(wtReal, cwdReal) {
			fmt.Fprintf(stderr, "Skipping merged branch %s (currently inside worktree %s)\n", entry.name, entry.wtPath)
			return nil
		}

		if dryRun {
			fmt.Fprintf(stdout, "[dry-run] git worktree remove %s\n", entry.wtPath)
		} else if err := r.Stream("worktree", "remove", entry.wtPath); err != nil {
			// Never pass --force so dirty worktrees or main worktrees stay safe.
			fmt.Fprintf(stderr, "Keeping worktree %s for branch %s\n", entry.wtPath, entry.name)
			return nil
		}
	}

	deleteFlag := "--delete"
	if forceDelete {
		deleteFlag = "-D"
	}

	if dryRun {
		fmt.Fprintf(stdout, "[dry-run] git branch %s %s\n", deleteFlag, entry.name)
		return nil
	}
	return deleteRunner.Stream("branch", deleteFlag, entry.name)
}

func runDeleteMergedBranches(args []string, workDir string, stdout, stderr io.Writer) error {
	return runDeleteMergedBranchesWithLookup(args, workDir, lookupMergedBranchPRs, stdout, stderr)
}

func runDeleteMergedBranchesWithLookup(args []string, workDir string, lookupPRs prLookupFunc, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("gitx delete-merged-branches", flag.ContinueOnError)
	fs.SetOutput(stderr)
	dryRun := fs.Bool("dry-run", false, "show actions without removing worktrees or deleting branches")
	prFlag := fs.Bool("pr", false, "also delete unmerged branches whose tip matches a merged GitHub PR")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: gitx delete-merged-branches [--dry-run] [--pr]\n\n")
		fmt.Fprintf(stderr, "Remove local branches merged into the default branch and their clean linked worktrees.\n\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no positional arguments, got %d", len(fs.Args()))
	}

	cwd := workDir
	if cwd == "" {
		var err error
		cwd, err = os.Getwd()
		if err != nil {
			return fmt.Errorf("resolve working directory: %w", err)
		}
	}
	cwdReal := resolveRealPath(cwd)

	ctx, err := gitcmd.DetectRepoContext(cwd, stdout, stderr)
	if err != nil {
		return err
	}

	r := gitcmd.NewIsolated(ctx.ContainerDir, stdout, stderr)
	defaultBranch, err := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
	if err != nil || defaultBranch == "" {
		return nil
	}
	targetRef := gitcmd.ResolveTargetRef(r, defaultBranch)
	if targetRef == "" {
		return nil
	}

	if !*dryRun {
		if err := r.Stream("worktree", "prune"); err != nil {
			return err
		}
	}

	defaultWT, _ := gitcmd.FindBranchWorktree(r, defaultBranch)
	merged, err := listBranchesByMergeFilter(r, "--merged="+targetRef)
	if err != nil {
		return err
	}

	deleteRunner := resolveDeleteRunner(r, ctx, defaultBranch, defaultWT)

	for _, entry := range merged {
		if shouldSkipProtectedEntry(ctx, defaultBranch, entry, stderr) {
			continue
		}
		if err := deleteBranchEntry(r, deleteRunner, entry, cwdReal, false, *dryRun, stdout, stderr); err != nil {
			return err
		}
	}

	if *prFlag {
		unmerged, err := listBranchesByMergeFilter(r, "--no-merged="+targetRef)
		if err != nil {
			return err
		}

		var candidates []localBranch
		for _, entry := range unmerged {
			if resetBranchBackupPattern.MatchString(entry.name) || shouldSkipProtectedEntry(ctx, defaultBranch, entry, stderr) {
				continue
			}
			if entry.wtPath != "" && isDir(entry.wtPath) && isSameOrInside(resolveRealPath(entry.wtPath), cwdReal) {
				fmt.Fprintf(stderr, "Skipping branch %s (currently inside worktree %s)\n", entry.name, entry.wtPath)
				continue
			}
			candidates = append(candidates, entry)
		}

		if len(candidates) > 0 {
			ghWorkDir := cwd
			if defaultWT != "" && isDir(defaultWT) {
				ghWorkDir = defaultWT
			}
			repo := resolveGitHubRepo(r)

			branchNames := make([]string, len(candidates))
			for i, entry := range candidates {
				branchNames[i] = entry.name
			}
			prsByBranch, err := lookupPRs(ghWorkDir, repo, branchNames)
			if err != nil {
				return err
			}

			for _, entry := range candidates {
				if !shouldDeleteFromPRs(entry.name, entry.oid, prsByBranch[entry.name]) {
					continue
				}
				if err := deleteBranchEntry(r, deleteRunner, entry, cwdReal, true, *dryRun, stdout, stderr); err != nil {
					return err
				}
			}
		}
	}

	if !*dryRun {
		if err := r.Stream("worktree", "prune"); err != nil {
			return err
		}
	}
	return nil
}
