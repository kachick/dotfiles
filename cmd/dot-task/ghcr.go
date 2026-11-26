package main

import (
	"bytes"
	"cmp"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"time"
	"unicode/utf8"
)

const (
	// https://github.com/orgs/community/discussions/26279#discussioncomment-3251171
	ghcrTokenURL             = "https://ghcr.io/token?scope=repository:kachick/home:pull"
	ghcrTagsURL              = "https://ghcr.io/v2/kachick/home/tags/list"
	ghcrManifestBaseURL      = "https://ghcr.io/v2/kachick/home/manifests/"
	ghcrPackagesVersionsPath = "/users/kachick/packages/container/home/versions?per_page=100"
	ghcrImageRepo            = "ghcr.io/kachick/home"
	ghcrManifestAccept       = "application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json"
	ghcrManifestCacheVersion = 1
	ghcrManifestConcurrency  = 5
)

var errSelectionCanceled = errors.New("selection canceled")

type fzfOptions struct {
	prompt        string
	header        string
	delimiter     string
	withNth       string
	preview       string
	previewWindow string
	ansi          bool
}

type ghcrEntry struct {
	Tag        string
	Digest     string
	Tags       []string
	CreatedAt  time.Time
	Local      bool
	SizeBytes  int64
	LayerCount int
	Kind       string
	CommitSHA  string
	Subject    string
}

type ghcrPackageVersion struct {
	Name      string `json:"name"`
	CreatedAt string `json:"created_at"`
	Metadata  struct {
		Container struct {
			Tags []string `json:"tags"`
		} `json:"container"`
	} `json:"metadata"`
}

type cachedLayer struct {
	Digest string `json:"digest"`
	Size   int64  `json:"size"`
}

type cachedManifest struct {
	TotalBytes int64         `json:"total_bytes"`
	Layers     []cachedLayer `json:"layers,omitempty"`
}

type ghcrManifestCache struct {
	Version   int                       `json:"version"`
	Manifests map[string]cachedManifest `json:"manifests"`
}

func runGHCR(args []string, e env) error {
	if len(args) > 0 {
		return errors.New("usage: task ghcr")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client := e.httpClient
	if client == nil {
		client = &http.Client{Timeout: 30 * time.Second}
	}

	return runGHCRWithEndpoints(ctx, client, ghcrTokenURL, ghcrTagsURL, ghcrManifestBaseURL, e)
}

func runGHCRWithEndpoints(ctx context.Context, client *http.Client, tokenURL, tagsURL, manifestBaseURL string, e env) error {
	var fallbackNotice string
	entries, err := fetchGHCRPackageVersions(e)
	if err != nil {
		fallbackNotice = formatGHCRFallbackNotice(err)
		if e.stderr != nil {
			fmt.Fprintf(e.stderr, "Note: %s\n", fallbackNotice)
		}
		tags, tagErr := fetchGHCRUTCTags(ctx, client, tokenURL, tagsURL)
		if tagErr != nil {
			return tagErr
		}
		entries = entriesFromUTCTags(tags)
	}

	if len(entries) == 0 {
		return errors.New("no matching tags found in ghcr.io/kachick/home")
	}

	cachePath := resolveGHCRCachePath(e)
	populateGHCRSizes(ctx, client, tokenURL, manifestBaseURL, cachePath, entries)
	markLocalGHCRImages(e, entries)
	populateGHCRCommitSubjects(e, entries)

	now := time.Now()
	if e.now != nil {
		now = e.now()
	}

	header, rows := formatGHCRTable(entries, now)
	if fallbackNotice != "" {
		// Repeat the fallback notice inside fzf's header because fzf takes over
		// the full screen and hides the earlier stderr line.
		header = fallbackNotice + "\n" + header
	}

	opts := fzfOptions{
		prompt:        "ghcr> ",
		header:        header,
		delimiter:     "\t",
		withNth:       "5",
		preview:       buildGHCRPreviewCommand(e),
		previewWindow: "right,50%,wrap,<100(down,40%,wrap)",
		ansi:          true,
	}

	picked, err := selectGHCRRow(rows, opts, e)
	if err != nil {
		if errors.Is(err, errSelectionCanceled) {
			return nil
		}
		return err
	}

	tag, _, _ := strings.Cut(picked, "\t")
	tag = strings.TrimSpace(tag)
	if tag == "" {
		return errSelectionCanceled
	}

	return e.runCmd("./containers/sandbox.bash", "--ghcr", tag)
}

func selectGHCRRow(rows []string, opts fzfOptions, e env) (string, error) {
	if e.selectItemWithOptions != nil {
		return e.selectItemWithOptions(rows, opts)
	}
	if e.selectItem != nil {
		return e.selectItem(rows, opts.prompt, opts.header)
	}
	return selectWithFzfOptions(rows, opts, e.stderr)
}

func fetchGHCRPackageVersions(e env) ([]ghcrEntry, error) {
	if e.cmdCombinedOutput == nil {
		return nil, errors.New("gh command runner is not configured")
	}

	out, err := e.cmdCombinedOutput(
		"gh", "api",
		"--header", "Accept: application/vnd.github+json",
		"--header", "X-GitHub-Api-Version: 2022-11-28",
		ghcrPackagesVersionsPath,
	)
	if err != nil {
		detail := strings.TrimSpace(string(out))
		if detail != "" {
			return nil, fmt.Errorf("%w: %s", err, detail)
		}
		return nil, err
	}

	var versions []ghcrPackageVersion
	if err := json.Unmarshal(out, &versions); err != nil {
		return nil, fmt.Errorf("decoding GHCR package versions: %w", err)
	}

	entries := make([]ghcrEntry, 0, len(versions))
	for _, v := range versions {
		entry, ok := buildGHCREntry(v)
		if !ok {
			continue
		}
		entries = append(entries, entry)
	}

	slices.SortFunc(entries, func(a, b ghcrEntry) int {
		if c := b.CreatedAt.Compare(a.CreatedAt); c != 0 {
			return c
		}
		return cmp.Compare(b.Tag, a.Tag)
	})
	return entries, nil
}

func buildGHCREntry(v ghcrPackageVersion) (ghcrEntry, bool) {
	if len(v.Metadata.Container.Tags) == 0 {
		return ghcrEntry{}, false
	}

	tags := slices.Clone(v.Metadata.Container.Tags)
	slices.Sort(tags)

	var (
		utcTag     string
		otherTag   string
		hasLatest  bool
		prLabel    string
		commitSHA  string
		createdAt  time.Time
		parsedTime bool
	)

	for _, tag := range tags {
		if strings.Contains(tag, "utc") {
			if utcTag == "" || tag > utcTag {
				utcTag = tag
			}
			if t, ok := parseUTCTagTime(tag); ok {
				createdAt = t
				parsedTime = true
			}
		} else if tag != "latest" && otherTag == "" {
			otherTag = tag
		}

		if tag == "latest" {
			hasLatest = true
		}
		if num, sha, ok := parsePRTag(tag); ok {
			prLabel = "PR #" + num
			if commitSHA == "" && sha != "" {
				commitSHA = sha
			}
		}
		if isFullCommitSHA(tag) {
			commitSHA = tag
		}
	}

	primaryTag := utcTag
	if primaryTag == "" {
		primaryTag = otherTag
	}
	if primaryTag == "" {
		primaryTag = tags[0]
	}

	if !parsedTime && v.CreatedAt != "" {
		if t, err := time.Parse(time.RFC3339, v.CreatedAt); err == nil {
			createdAt = t
		}
	}

	var kinds []string
	if hasLatest {
		kinds = append(kinds, "latest")
	}
	if prLabel != "" {
		kinds = append(kinds, prLabel)
	}

	return ghcrEntry{
		Tag:       primaryTag,
		Digest:    v.Name,
		Tags:      tags,
		CreatedAt: createdAt,
		SizeBytes: -1,
		Kind:      strings.Join(kinds, ","),
		CommitSHA: commitSHA,
	}, true
}

func entriesFromUTCTags(tags []string) []ghcrEntry {
	entries := make([]ghcrEntry, 0, len(tags))
	for _, tag := range tags {
		t, _ := parseUTCTagTime(tag)
		entries = append(entries, ghcrEntry{
			Tag:       tag,
			Tags:      []string{tag},
			CreatedAt: t,
			SizeBytes: -1,
		})
	}
	return entries
}

func formatGHCRFallbackNotice(err error) string {
	msg := strings.ToLower(err.Error())
	switch {
	case strings.Contains(msg, "read:packages"),
		strings.Contains(msg, "403"),
		strings.Contains(msg, "401"),
		strings.Contains(msg, "not logged into"),
		strings.Contains(msg, "authentication"):
		return "Falling back to tag list (run 'gh auth refresh --scopes read:packages' for size/commit columns)"
	case errors.Is(err, exec.ErrNotFound), strings.Contains(msg, "executable file not found"):
		return "Falling back to tag list ('gh' not found in PATH)"
	default:
		firstLine, _, _ := strings.Cut(strings.TrimSpace(err.Error()), "\n")
		return fmt.Sprintf("Falling back to tag list (gh api failed: %s)", firstLine)
	}
}

func parseUTCTagTime(tag string) (time.Time, bool) {
	if t, err := time.Parse("20060102-150405-utc", tag); err == nil {
		return t.UTC(), true
	}
	if t, err := time.Parse("20060102-utc", tag); err == nil {
		return t.UTC(), true
	}
	return time.Time{}, false
}

func parsePRTag(tag string) (prNum, sha string, ok bool) {
	rest, found := strings.CutPrefix(tag, "pr-")
	if !found {
		return "", "", false
	}
	num, suffix, hasSuffix := strings.Cut(rest, "-")
	if num == "" {
		return "", "", false
	}
	for _, r := range num {
		if r < '0' || r > '9' {
			return "", "", false
		}
	}
	if hasSuffix && isFullCommitSHA(suffix) {
		return num, suffix, true
	}
	return num, "", true
}

func isFullCommitSHA(s string) bool {
	if len(s) != 40 {
		return false
	}
	for _, r := range s {
		if (r < '0' || r > '9') && (r < 'a' || r > 'f') {
			return false
		}
	}
	return true
}

func resolveGHCRCachePath(e env) string {
	if e.getenv != nil {
		if xdg := e.getenv("XDG_CACHE_HOME"); xdg != "" {
			return filepath.Join(xdg, "dotfiles", "ghcr", "manifests.json")
		}
	}
	if e.cacheDir != nil {
		if dir, err := e.cacheDir(); err == nil && dir != "" {
			return filepath.Join(dir, "dotfiles", "ghcr", "manifests.json")
		}
	}
	return ""
}

func loadGHCRManifestCache(path string) ghcrManifestCache {
	empty := ghcrManifestCache{
		Version:   ghcrManifestCacheVersion,
		Manifests: make(map[string]cachedManifest),
	}
	if path == "" {
		return empty
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return empty
	}
	var cache ghcrManifestCache
	if err := json.Unmarshal(data, &cache); err != nil || cache.Version != ghcrManifestCacheVersion || cache.Manifests == nil {
		return empty
	}
	return cache
}

func saveGHCRManifestCache(path string, cache ghcrManifestCache) error {
	if path == "" {
		return nil
	}
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(cache, "", "  ")
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp(dir, "manifests-*.tmp")
	if err != nil {
		return err
	}
	tmpPath := tmp.Name()
	if _, err := tmp.Write(data); err != nil {
		_ = tmp.Close()
		_ = os.Remove(tmpPath)
		return err
	}
	if err := tmp.Close(); err != nil {
		_ = os.Remove(tmpPath)
		return err
	}
	if err := os.Rename(tmpPath, path); err != nil {
		_ = os.Remove(tmpPath)
		return err
	}
	return nil
}

func populateGHCRSizes(ctx context.Context, client *http.Client, tokenURL, manifestBaseURL, cachePath string, entries []ghcrEntry) {
	cache := loadGHCRManifestCache(cachePath)
	activeDigests := make(map[string]struct{}, len(entries))
	var missing []string

	for _, entry := range entries {
		if entry.Digest == "" {
			continue
		}
		activeDigests[entry.Digest] = struct{}{}
		if _, ok := cache.Manifests[entry.Digest]; !ok {
			missing = append(missing, entry.Digest)
		}
	}

	cacheDirty := false
	if len(missing) > 0 {
		token, err := fetchGHCRToken(ctx, client, tokenURL)
		if err == nil {
			fetched := fetchGHCRManifests(ctx, client, manifestBaseURL, token, missing)
			for digest, manifest := range fetched {
				cache.Manifests[digest] = manifest
				cacheDirty = true
			}
		}
	}

	// Prune digests that are no longer in the package version list so the cache stays bounded.
	if len(activeDigests) > 0 {
		for digest := range cache.Manifests {
			if _, ok := activeDigests[digest]; !ok {
				delete(cache.Manifests, digest)
				cacheDirty = true
			}
		}
	}

	if cacheDirty {
		_ = saveGHCRManifestCache(cachePath, cache)
	}

	for i := range entries {
		if m, ok := cache.Manifests[entries[i].Digest]; ok {
			entries[i].SizeBytes = m.TotalBytes
			entries[i].LayerCount = len(m.Layers)
		}
	}
}

func fetchGHCRManifests(ctx context.Context, client *http.Client, manifestBaseURL, token string, digests []string) map[string]cachedManifest {
	results := make(map[string]cachedManifest, len(digests))
	var (
		mu  sync.Mutex
		wg  sync.WaitGroup
		sem = make(chan struct{}, ghcrManifestConcurrency)
	)

	for _, digest := range digests {
		wg.Go(func() {
			select {
			case sem <- struct{}{}:
				defer func() { <-sem }()
			case <-ctx.Done():
				return
			}

			m, err := fetchSingleGHCRManifest(ctx, client, manifestBaseURL, token, digest)
			if err != nil {
				return
			}
			mu.Lock()
			results[digest] = m
			mu.Unlock()
		})
	}

	wg.Wait()
	return results
}

type ociManifestResponse struct {
	Config struct {
		Size int64 `json:"size"`
	} `json:"config"`
	Layers []struct {
		Digest string `json:"digest"`
		Size   int64  `json:"size"`
	} `json:"layers"`
	Manifests []struct {
		Digest   string `json:"digest"`
		Platform struct {
			OS           string `json:"os"`
			Architecture string `json:"architecture"`
		} `json:"platform"`
	} `json:"manifests"`
}

func fetchSingleGHCRManifest(ctx context.Context, client *http.Client, manifestBaseURL, token, ref string) (cachedManifest, error) {
	return fetchSingleGHCRManifestDepth(ctx, client, manifestBaseURL, token, ref, 0)
}

func fetchSingleGHCRManifestDepth(ctx context.Context, client *http.Client, manifestBaseURL, token, ref string, depth int) (cachedManifest, error) {
	if depth > 1 {
		return cachedManifest{}, errors.New("manifest index nesting too deep")
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, manifestBaseURL+ref, nil)
	if err != nil {
		return cachedManifest{}, err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Accept", ghcrManifestAccept)

	resp, err := client.Do(req)
	if err != nil {
		return cachedManifest{}, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return cachedManifest{}, fmt.Errorf("manifest endpoint returned %d", resp.StatusCode)
	}

	var parsed ociManifestResponse
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return cachedManifest{}, err
	}

	if len(parsed.Layers) == 0 && len(parsed.Manifests) > 0 {
		target := selectPlatformManifestDigest(parsed)
		if target == "" {
			return cachedManifest{}, errors.New("manifest index has no selectable platform manifest")
		}
		return fetchSingleGHCRManifestDepth(ctx, client, manifestBaseURL, token, target, depth+1)
	}

	total := parsed.Config.Size
	layers := make([]cachedLayer, 0, len(parsed.Layers))
	for _, layer := range parsed.Layers {
		total += layer.Size
		layers = append(layers, cachedLayer{
			Digest: layer.Digest,
			Size:   layer.Size,
		})
	}
	return cachedManifest{
		TotalBytes: total,
		Layers:     layers,
	}, nil
}

func selectPlatformManifestDigest(idx ociManifestResponse) string {
	for _, m := range idx.Manifests {
		if m.Platform.OS == "linux" && m.Platform.Architecture == "amd64" && m.Digest != "" {
			return m.Digest
		}
	}
	for _, m := range idx.Manifests {
		if m.Platform.OS != "" && m.Platform.OS != "unknown" && m.Digest != "" {
			return m.Digest
		}
	}
	if len(idx.Manifests) > 0 {
		return idx.Manifests[0].Digest
	}
	return ""
}

func markLocalGHCRImages(e env, entries []ghcrEntry) {
	if e.cmdCombinedOutput == nil {
		return
	}
	out, err := e.cmdCombinedOutput("podman", "images", "--format", "{{.Repository}}:{{.Tag}}\t{{.Digest}}")
	if err != nil {
		return
	}

	localRefs := make(map[string]struct{})
	localDigests := make(map[string]struct{})
	for line := range strings.SplitSeq(string(out), "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		ref, digest, _ := strings.Cut(line, "\t")
		if ref != "" {
			localRefs[ref] = struct{}{}
		}
		if digest != "" {
			localDigests[digest] = struct{}{}
		}
	}

	for i := range entries {
		if entries[i].Digest != "" {
			if _, ok := localDigests[entries[i].Digest]; ok {
				entries[i].Local = true
				continue
			}
		}
		for _, tag := range entries[i].Tags {
			if _, ok := localRefs[ghcrImageRepo+":"+tag]; ok {
				entries[i].Local = true
				break
			}
		}
	}
}

func populateGHCRCommitSubjects(e env, entries []ghcrEntry) {
	if e.cmdCombinedOutput == nil {
		return
	}

	seen := make(map[string]struct{})
	args := []string{"log", "--no-walk=unsorted", "--ignore-missing", "--format=%H%x09%s"}
	for _, entry := range entries {
		if entry.CommitSHA == "" {
			continue
		}
		if _, ok := seen[entry.CommitSHA]; ok {
			continue
		}
		seen[entry.CommitSHA] = struct{}{}
		args = append(args, entry.CommitSHA)
	}
	if len(seen) == 0 {
		return
	}

	out, err := e.cmdCombinedOutput("git", args...)
	if err != nil {
		return
	}

	subjects := make(map[string]string, len(seen))
	for line := range strings.SplitSeq(string(out), "\n") {
		sha, subject, ok := strings.Cut(line, "\t")
		if !ok || sha == "" {
			continue
		}
		subjects[sha] = sanitizeTableCell(subject)
	}

	for i := range entries {
		if subject, ok := subjects[entries[i].CommitSHA]; ok {
			entries[i].Subject = subject
		}
	}
}

func formatGHCRTable(entries []ghcrEntry, now time.Time) (header string, rows []string) {
	type formatted struct {
		tag     string
		age     string
		local   string
		size    string
		kind    string
		commit  string
		subject string
	}

	items := make([]formatted, len(entries))
	wTag := len("TAG")
	wAge := len("AGE")
	wLocal := len("LOCAL")
	wSize := len("DL SIZE")
	wKind := len("KIND")
	wCommit := len("COMMIT")

	for i, entry := range entries {
		localMark := ""
		if entry.Local {
			localMark = "●"
		}
		commitShort := "-"
		if len(entry.CommitSHA) >= 7 {
			commitShort = entry.CommitSHA[:7]
		}
		kind := entry.Kind
		if kind == "" {
			kind = "-"
		}
		subject := entry.Subject
		if subject == "" {
			subject = "-"
		}

		f := formatted{
			tag:     sanitizeTableCell(entry.Tag),
			age:     formatRelativeAge(entry.CreatedAt, now),
			local:   localMark,
			size:    formatBytes(entry.SizeBytes),
			kind:    sanitizeTableCell(kind),
			commit:  commitShort,
			subject: sanitizeTableCell(subject),
		}
		items[i] = f

		wTag = max(wTag, utf8.RuneCountInString(f.tag))
		wAge = max(wAge, utf8.RuneCountInString(f.age))
		wLocal = max(wLocal, utf8.RuneCountInString(f.local))
		wSize = max(wSize, utf8.RuneCountInString(f.size))
		wKind = max(wKind, utf8.RuneCountInString(f.kind))
		wCommit = max(wCommit, utf8.RuneCountInString(f.commit))
	}

	header = strings.Join([]string{
		padRight("TAG", wTag),
		padRight("AGE", wAge),
		padRight("LOCAL", wLocal),
		padLeft("DL SIZE", wSize),
		padRight("KIND", wKind),
		padRight("COMMIT", wCommit),
		"SUBJECT",
	}, "  ")

	rows = make([]string, len(entries))
	for i, entry := range entries {
		f := items[i]
		display := strings.Join([]string{
			padRight(f.tag, wTag),
			padRight(f.age, wAge),
			padRight(f.local, wLocal),
			padLeft(f.size, wSize),
			padRight(f.kind, wKind),
			padRight(f.commit, wCommit),
			f.subject,
		}, "  ")
		// Keep machine-readable metadata in hidden tab-delimited fields so fzf
		// --with-nth=5 displays only the aligned table while --preview receives exact values.
		rows[i] = strings.Join([]string{
			sanitizeTableCell(entry.Tag),
			sanitizeTableCell(entry.Digest),
			sanitizeTableCell(entry.CommitSHA),
			sanitizeTableCell(strings.Join(entry.Tags, ",")),
			display,
		}, "\t")
	}
	return header, rows
}

func formatRelativeAge(t, now time.Time) string {
	if t.IsZero() {
		return "-"
	}
	d := now.Sub(t)
	if d < 0 {
		d = 0
	}
	switch {
	case d < time.Minute:
		return "now"
	case d < time.Hour:
		return fmt.Sprintf("%dm ago", int(d/time.Minute))
	case d < 24*time.Hour:
		return fmt.Sprintf("%dh ago", int(d/time.Hour))
	case d < 30*24*time.Hour:
		return fmt.Sprintf("%dd ago", int(d/(24*time.Hour)))
	case d < 365*24*time.Hour:
		return fmt.Sprintf("%dmo ago", int(d/(30*24*time.Hour)))
	default:
		return fmt.Sprintf("%dy ago", int(d/(365*24*time.Hour)))
	}
}

func formatBytes(b int64) string {
	if b < 0 {
		return "-"
	}
	const (
		kib = 1024
		mib = 1024 * kib
		gib = 1024 * mib
	)
	switch {
	case b >= gib:
		return fmt.Sprintf("%.2f GiB", float64(b)/float64(gib))
	case b >= mib:
		return fmt.Sprintf("%.1f MiB", float64(b)/float64(mib))
	case b >= kib:
		return fmt.Sprintf("%.1f KiB", float64(b)/float64(kib))
	default:
		return fmt.Sprintf("%d B", b)
	}
}

func padRight(s string, width int) string {
	n := utf8.RuneCountInString(s)
	if n >= width {
		return s
	}
	return s + strings.Repeat(" ", width-n)
}

func padLeft(s string, width int) string {
	n := utf8.RuneCountInString(s)
	if n >= width {
		return s
	}
	return strings.Repeat(" ", width-n) + s
}

func sanitizeTableCell(s string) string {
	s = strings.ReplaceAll(s, "\t", " ")
	s = strings.ReplaceAll(s, "\r", " ")
	s = strings.ReplaceAll(s, "\n", " ")
	return strings.TrimSpace(s)
}

func buildGHCRPreviewCommand(e env) string {
	if e.executable == nil {
		return ""
	}
	exe, err := e.executable()
	if err != nil || exe == "" {
		return ""
	}
	return shellQuote(exe) + " ghcr-preview {1} {2} {3} {4}"
}

func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func runGHCRPreview(args []string, e env) error {
	if len(args) < 1 {
		return errors.New("usage: dot-task ghcr-preview <tag> [digest] [commit] [tags]")
	}

	tag := args[0]
	var digest, commitSHA, csvTags string
	if len(args) >= 2 {
		digest = args[1]
	}
	if len(args) >= 3 {
		commitSHA = args[2]
	}
	if len(args) >= 4 {
		csvTags = args[3]
	}

	var b strings.Builder
	fmt.Fprintf(&b, "Image:  %s:%s\n", ghcrImageRepo, tag)
	if t, ok := parseUTCTagTime(tag); ok {
		fmt.Fprintf(&b, "Built:  %s (%s)\n", t.Local().Format("2006-01-02 15:04:05 MST"), t.UTC().Format("2006-01-02 15:04:05 UTC"))
	}
	if csvTags != "" {
		fmt.Fprintf(&b, "Tags:   %s\n", strings.ReplaceAll(csvTags, ",", ", "))
	}
	if digest != "" {
		fmt.Fprintf(&b, "Digest: %s\n", digest)
	}

	if digest != "" {
		cache := loadGHCRManifestCache(resolveGHCRCachePath(e))
		if m, ok := cache.Manifests[digest]; ok {
			fmt.Fprintf(&b, "Size:   %s (%d layers, compressed)\n", formatBytes(m.TotalBytes), len(m.Layers))
			if len(m.Layers) > 0 {
				b.WriteString("\nLayers:\n")
				for i, layer := range m.Layers {
					shortDigest := layer.Digest
					if len(shortDigest) > 19 {
						shortDigest = shortDigest[:19]
					}
					fmt.Fprintf(&b, "  %2d. %10s  %s\n", i+1, formatBytes(layer.Size), shortDigest)
				}
			}
		}
	}

	if commitSHA != "" {
		b.WriteString("\n")
		if e.cmdCombinedOutput != nil {
			out, err := e.cmdCombinedOutput("git", "show", "--stat", "--color=always", commitSHA)
			if err == nil {
				b.Write(out)
			} else {
				fmt.Fprintf(&b, "Commit %s not found in local git history.\n", commitSHA)
			}
		}
	}

	if e.stdout != nil {
		_, err := io.WriteString(e.stdout, b.String())
		return err
	}
	return nil
}

func fetchGHCRToken(ctx context.Context, client *http.Client, tokenURL string) (string, error) {
	tokenReq, err := http.NewRequestWithContext(ctx, http.MethodGet, tokenURL, nil)
	if err != nil {
		return "", fmt.Errorf("creating GHCR token request: %w", err)
	}
	tokenResp, err := client.Do(tokenReq)
	if err != nil {
		return "", fmt.Errorf("requesting GHCR token: %w", err)
	}
	defer tokenResp.Body.Close()

	if tokenResp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(tokenResp.Body)
		return "", fmt.Errorf("GHCR token endpoint returned %d: %s", tokenResp.StatusCode, strings.TrimSpace(string(body)))
	}

	var tokenData struct {
		Token string `json:"token"`
	}
	if err := json.NewDecoder(tokenResp.Body).Decode(&tokenData); err != nil {
		return "", fmt.Errorf("decoding GHCR token response: %w", err)
	}
	if tokenData.Token == "" {
		return "", errors.New("GHCR token response was empty")
	}
	return tokenData.Token, nil
}

func fetchGHCRUTCTags(ctx context.Context, client *http.Client, tokenURL, tagsURL string) ([]string, error) {
	token, err := fetchGHCRToken(ctx, client, tokenURL)
	if err != nil {
		return nil, err
	}

	tagsReq, err := http.NewRequestWithContext(ctx, http.MethodGet, tagsURL, nil)
	if err != nil {
		return nil, fmt.Errorf("creating GHCR tags request: %w", err)
	}
	tagsReq.Header.Set("Authorization", "Bearer "+token)

	tagsResp, err := client.Do(tagsReq)
	if err != nil {
		return nil, fmt.Errorf("requesting GHCR tags: %w", err)
	}
	defer tagsResp.Body.Close()

	if tagsResp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(tagsResp.Body)
		return nil, fmt.Errorf("GHCR tags endpoint returned %d: %s", tagsResp.StatusCode, strings.TrimSpace(string(body)))
	}

	var tagsData struct {
		Tags []string `json:"tags"`
	}
	if err := json.NewDecoder(tagsResp.Body).Decode(&tagsData); err != nil {
		return nil, fmt.Errorf("decoding GHCR tags response: %w", err)
	}

	return filterAndReverseUTCTags(tagsData.Tags), nil
}

func filterAndReverseUTCTags(tags []string) []string {
	var filtered []string
	for _, tag := range tags {
		if strings.Contains(tag, "utc") {
			filtered = append(filtered, tag)
		}
	}
	slices.Reverse(filtered)
	return filtered
}

func selectWithFzf(items []string, prompt, header string, stderr io.Writer) (string, error) {
	return selectWithFzfOptions(items, fzfOptions{
		prompt: prompt,
		header: header,
	}, stderr)
}

func selectWithFzfOptions(items []string, opts fzfOptions, stderr io.Writer) (string, error) {
	fzfBin, err := exec.LookPath("fzf")
	if err != nil {
		return "", fmt.Errorf("finding fzf: %w", err)
	}

	// Keep fzf's default bottom-up layout instead of --reverse so the first item
	// (e.g. the newest GHCR tag) stays at the bottom under the initial cursor.
	var args []string
	if opts.prompt != "" {
		args = append(args, "--prompt="+opts.prompt)
	}
	if opts.header != "" {
		args = append(args, "--header="+opts.header)
	}
	if opts.delimiter != "" {
		args = append(args, "--delimiter="+opts.delimiter)
	}
	if opts.withNth != "" {
		args = append(args, "--with-nth="+opts.withNth)
	}
	if opts.preview != "" {
		args = append(args, "--preview="+opts.preview)
	}
	if opts.previewWindow != "" {
		args = append(args, "--preview-window="+opts.previewWindow)
	}
	if opts.ansi {
		args = append(args, "--ansi")
	}

	cmd := exec.Command(fzfBin, args...)
	cmd.Stdin = strings.NewReader(strings.Join(items, "\n") + "\n")
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = stderr

	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) && (exitErr.ExitCode() == 1 || exitErr.ExitCode() == 130) {
			return "", errSelectionCanceled
		}
		return "", fmt.Errorf("fzf failed: %w", err)
	}

	picked := strings.TrimSpace(out.String())
	if picked == "" {
		return "", errSelectionCanceled
	}
	return picked, nil
}
