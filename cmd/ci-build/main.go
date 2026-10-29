package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: ci-build <package|nixos|push|pin|sync-workflows> [options] [args]")
		os.Exit(1)
	}

	subcommand := os.Args[1]
	switch subcommand {
	case "package":
		if err := runPackage(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	case "nixos":
		if err := runNixos(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	case "push":
		if err := runPush(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	case "pin":
		if err := runPin(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	case "sync-workflows":
		if err := runSyncWorkflows(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	default:
		fmt.Fprintf(os.Stderr, "Unknown subcommand: %s\nUsage: ci-build <package|nixos|push|pin|sync-workflows> [options] [args]\n", subcommand)
		os.Exit(1)
	}
}

func getCurrentNixSystem() (string, error) {
	cmd := exec.Command("nix", "eval", "--raw", "--impure", "--expr", "builtins.currentSystem")
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("failed to detect current Nix system: %w", err)
	}
	system := strings.TrimSpace(out.String())
	if system == "" {
		return "", fmt.Errorf("current Nix system output was empty")
	}
	return system, nil
}

func runPackage(args []string) error {
	fs := flag.NewFlagSet("package", flag.ExitOnError)
	archFlag := fs.String("arch", "", "Target system architecture (defaults to nix builtins.currentSystem)")
	skipTests := fs.Bool("skip-tests", false, "Skip running passthru.tests")

	if err := fs.Parse(args); err != nil {
		return err
	}

	if fs.NArg() < 1 {
		return fmt.Errorf("package name is required")
	}

	pname := fs.Arg(0)
	arch := *archFlag
	if arch == "" {
		detectedArch, err := getCurrentNixSystem()
		if err != nil {
			return err
		}
		arch = detectedArch
	}

	isFree, err := isPackageFree(pname, arch)
	if err != nil {
		return fmt.Errorf("checking license for %s: %w", pname, err)
	}

	buildTarget := fmt.Sprintf(".#%s", pname)
	var outBuf bytes.Buffer
	buildArgs := []string{"build", buildTarget, "--no-link", "--print-out-paths", "--no-keep-build-log", "--show-trace"}
	var buildEnv []string

	if !isFree {
		// Only unfree packages require --impure and NIXPKGS_ALLOW_UNFREE=1.
		buildArgs = append(buildArgs, "--impure")
		buildEnv = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
	}

	buildCmd := exec.Command("nix", buildArgs...)
	if len(buildEnv) > 0 {
		buildCmd.Env = buildEnv
	}
	buildCmd.Stdout = io.MultiWriter(os.Stdout, &outBuf)
	buildCmd.Stderr = os.Stderr
	if err := buildCmd.Run(); err != nil {
		return err
	}

	if *skipTests {
		fmt.Printf("Skipping tests for %s as requested.\n", pname)
	} else {
		evalTarget := fmt.Sprintf(".#%s.passthru.tests", pname)
		evalArgs := []string{"eval", evalTarget}
		if !isFree {
			evalArgs = append(evalArgs, "--impure")
		}
		evalCmd := exec.Command("nix", evalArgs...)
		if !isFree {
			evalCmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
		}
		if err := evalCmd.Run(); err != nil {
			fmt.Printf("No passthru.tests found for %s, skipping.\n", pname)
		} else {
			testAttr := fmt.Sprintf("packages.%s.%s.passthru.tests", arch, pname)
			testCmd := exec.Command("nix-build", "--no-keep-build-log", "--attr", testAttr)
			if !isFree {
				testCmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
			}
			testCmd.Stdout = os.Stdout
			testCmd.Stderr = os.Stderr
			if err := testCmd.Run(); err != nil {
				return err
			}
		}
	}

	outPaths := strings.Fields(outBuf.String())
	if err := handleBuiltPaths(pname, isFree, outPaths); err != nil {
		return err
	}

	return nil
}

func isPackageFree(pname string, arch string) (bool, error) {
	repoRootBytes, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return false, fmt.Errorf("failed to detect repository root: %w", err)
	}
	repoRoot := strings.TrimSpace(string(repoRootBytes))

	expr := fmt.Sprintf(`
let
  flake = builtins.getFlake "%s";
  pkgs = flake.inputs.nixpkgs.legacyPackages.%s;
  lib = pkgs.lib;
  pkg = flake.packages.%s.%s;
  licenses = pkg.meta.license or lib.licenses.free;
in
if lib.isAttrs licenses && licenses ? "licenseType" then
  lib.licenses.isFree licenses
else if lib.isAttrs licenses then
  licenses.free or true
else if lib.isString licenses then
  true
else
  lib.all (l: l.free or true) licenses
`, repoRoot, arch, arch, pname)

	cmd := exec.Command("nix", "eval", "--impure", "--expr", expr)
	cmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
	out, err := cmd.Output()
	if err != nil {
		return false, fmt.Errorf("failed to evaluate license for %s: %w", pname, err)
	}
	result := strings.TrimSpace(string(out))
	switch result {
	case "true":
		return true, nil
	case "false":
		return false, nil
	default:
		return false, fmt.Errorf("unexpected license evaluation result for %s: %s", pname, result)
	}
}

func runNixos(args []string) error {
	fs := flag.NewFlagSet("nixos", flag.ExitOnError)
	if err := fs.Parse(args); err != nil {
		return err
	}

	if fs.NArg() < 1 {
		return fmt.Errorf("host name is required")
	}

	host := fs.Arg(0)

	buildTarget := fmt.Sprintf(".#nixosConfigurations.%s.config.system.build.toplevel", host)
	var outBuf bytes.Buffer
	buildCmd := exec.Command("nix", "build", buildTarget, "--no-link", "--print-out-paths", "--no-keep-build-log", "--show-trace")
	buildCmd.Stdout = io.MultiWriter(os.Stdout, &outBuf)
	buildCmd.Stderr = os.Stderr

	if err := buildCmd.Run(); err != nil {
		return err
	}

	outPaths := strings.Fields(outBuf.String())
	if err := handleBuiltPaths(host, true, outPaths); err != nil {
		return err
	}

	return nil
}

func handleBuiltPaths(targetName string, isFree bool, outPaths []string) error {
	if outPathsDir := os.Getenv("CI_BUILD_OUT_PATHS_DIR"); outPathsDir != "" {
		if !isFree {
			fmt.Printf("Skipping output path recording for unfree package: %s\n", targetName)
			return nil
		}
		return recordOutPaths(outPathsDir, targetName, outPaths)
	}
	return maybePushToNiks3(targetName, isFree, outPaths)
}

func recordOutPaths(dir string, targetName string, outPaths []string) error {
	if len(outPaths) == 0 {
		return nil
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return fmt.Errorf("creating output paths directory %s: %w", dir, err)
	}
	f, err := os.CreateTemp(dir, "paths-*.txt")
	if err != nil {
		return fmt.Errorf("creating output paths file for %s: %w", targetName, err)
	}
	defer f.Close()

	content := strings.Join(outPaths, "\n") + "\n"
	if _, err := f.WriteString(content); err != nil {
		return fmt.Errorf("writing output paths for %s: %w", targetName, err)
	}
	fmt.Printf("Recorded %d output path(s) for %s\n", len(outPaths), targetName)
	return nil
}

func readRecordedOutPaths(dir string) ([]string, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("reading output paths directory %s: %w", dir, err)
	}

	var paths []string
	seen := make(map[string]bool)
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		data, err := os.ReadFile(filepath.Join(dir, entry.Name()))
		if err != nil {
			return nil, fmt.Errorf("reading %s: %w", entry.Name(), err)
		}
		for _, field := range strings.Fields(string(data)) {
			if !seen[field] {
				seen[field] = true
				paths = append(paths, field)
			}
		}
	}
	return paths, nil
}

func isCacheableStorePath(path string) bool {
	// Exclude source tarballs, git clones, vendor directories, and large ISOs
	base := filepath.Base(path)
	if strings.HasSuffix(base, "-source") {
		return false
	}
	if strings.HasSuffix(base, "-vendor") {
		return false
	}
	if strings.HasSuffix(base, ".iso") {
		return false
	}
	if strings.HasSuffix(base, "nixpkgs.tar.gz") {
		return false
	}
	return true
}

func filterCacheablePaths(paths []string) []string {
	seen := make(map[string]bool)
	var filtered []string
	for _, p := range paths {
		trimmed := strings.TrimSpace(p)
		if trimmed == "" {
			continue
		}
		if seen[trimmed] {
			continue
		}
		seen[trimmed] = true
		if isCacheableStorePath(trimmed) {
			filtered = append(filtered, trimmed)
		}
	}
	return filtered
}

type pathInfoEntry struct {
	Signatures []string `json:"signatures"`
}

func filterUpstreamPaths(parsed map[string]pathInfoEntry) []string {
	var candidatePaths []string
	for p, info := range parsed {
		isUpstream := false
		for _, sig := range info.Signatures {
			if strings.HasPrefix(sig, "cache.nixos.org-1:") {
				isUpstream = true
				break
			}
		}
		if !isUpstream {
			candidatePaths = append(candidatePaths, p)
		}
	}
	sort.Strings(candidatePaths)
	return candidatePaths
}

// Query only top-level paths here. niks3 push walks closures itself and checks
// /api/present per root before uploading.
func queryPathInfoJSON(paths []string) ([]byte, error) {
	args := append([]string{"path-info", "--json-format", "1", "--json", "--"}, paths...)
	out, err := exec.Command("nix", args...).Output()
	if err == nil {
		return out, nil
	}
	// Fallback for older Nix versions without --json-format
	fallbackArgs := append([]string{"path-info", "--json", "--"}, paths...)
	return exec.Command("nix", fallbackArgs...).Output()
}

func getUncachedRootPaths(paths []string) ([]string, error) {
	if len(paths) == 0 {
		return nil, nil
	}
	out, err := queryPathInfoJSON(paths)
	if err != nil {
		return nil, fmt.Errorf("failed to query path-info: %w", err)
	}
	var parsed map[string]pathInfoEntry
	if err := json.Unmarshal(out, &parsed); err != nil {
		return nil, fmt.Errorf("failed to parse path-info json: %w", err)
	}
	candidates := filterUpstreamPaths(parsed)
	return filterCacheablePaths(candidates), nil
}

func maybePushToNiks3(targetName string, isFree bool, outPaths []string) error {
	if !isFree {
		fmt.Printf("Skipping niks3 push for unfree package: %s\n", targetName)
		return nil
	}

	serverURL := os.Getenv("NIKS3_SERVER_URL")
	if serverURL == "" {
		fmt.Printf("Skipping niks3 push for %s: NIKS3_SERVER_URL not set\n", targetName)
		return nil
	}

	if len(outPaths) == 0 {
		return fmt.Errorf("no output paths to push to niks3 for %s", targetName)
	}

	rootPaths, err := getUncachedRootPaths(outPaths)
	if err != nil {
		return fmt.Errorf("filtering root paths for %s: %w", targetName, err)
	}

	if len(rootPaths) == 0 {
		fmt.Printf("No cacheable paths found for %s, skipping niks3 push\n", targetName)
		return nil
	}

	authToken, err := getNiks3OIDCToken()
	if err != nil {
		return fmt.Errorf("getting niks3 OIDC token: %w", err)
	}
	tokenFile, err := os.CreateTemp("", "niks3-token-*")
	if err != nil {
		return fmt.Errorf("creating temp token file: %w", err)
	}
	defer os.Remove(tokenFile.Name())
	if _, err := tokenFile.WriteString(authToken); err != nil {
		return fmt.Errorf("writing temp token file: %w", err)
	}
	if err := tokenFile.Close(); err != nil {
		return fmt.Errorf("closing temp token file: %w", err)
	}
	tokenArgs := []string{"--auth-token-path", tokenFile.Name()}

	fmt.Printf("Pushing %s to niks3 (%d root paths)...\n", targetName, len(rootPaths))

	// Avoid --stdin here because niks3 StreamPusher reports upload failures as
	// JSON lines on stdout and still exits with status 0.
	niks3Bin, err := exec.LookPath("niks3")
	var pushCmd *exec.Cmd
	if err == nil {
		args := []string{"push", "--server-url", serverURL}
		args = append(args, tokenArgs...)
		args = append(args, "--")
		args = append(args, rootPaths...)
		pushCmd = exec.Command(niks3Bin, args...)
	} else {
		args := []string{"run", ".#niks3", "--", "push", "--server-url", serverURL}
		args = append(args, tokenArgs...)
		args = append(args, "--")
		args = append(args, rootPaths...)
		pushCmd = exec.Command("nix", args...)
	}

	pushCmd.Stdout = os.Stdout
	pushCmd.Stderr = os.Stderr

	return pushCmd.Run()
}

func getNiks3OIDCToken() (string, error) {
	reqURL := os.Getenv("ACTIONS_ID_TOKEN_REQUEST_URL")
	reqToken := os.Getenv("ACTIONS_ID_TOKEN_REQUEST_TOKEN")
	if reqURL == "" || reqToken == "" {
		return "", errors.New("GitHub Actions OIDC environment variables (ACTIONS_ID_TOKEN_REQUEST_URL, ACTIONS_ID_TOKEN_REQUEST_TOKEN) are not set")
	}

	audience := os.Getenv("NIKS3_OIDC_AUDIENCE")
	if audience == "" {
		audience = "https://cache.kachick.dev"
	}
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	return fetchGHAOIDCToken(ctx, reqURL, reqToken, audience)
}

func fetchGHAOIDCToken(ctx context.Context, reqURL, reqToken, audience string) (string, error) {
	u, err := url.Parse(reqURL)
	if err != nil {
		return "", fmt.Errorf("parsing ACTIONS_ID_TOKEN_REQUEST_URL: %w", err)
	}
	q := u.Query()
	q.Set("audience", audience)
	u.RawQuery = q.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
	if err != nil {
		return "", fmt.Errorf("creating OIDC request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+reqToken)

	client := newHTTPClient()
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("requesting OIDC token: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("OIDC endpoint returned %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	var res struct {
		Value string `json:"value"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return "", fmt.Errorf("decoding OIDC response: %w", err)
	}
	if res.Value == "" {
		return "", errors.New("OIDC response value is empty")
	}
	return res.Value, nil
}

func runPush(args []string) error {
	fs := flag.NewFlagSet("push", flag.ExitOnError)
	fromDir := fs.String("from-dir", "", "Directory containing recorded output path files")
	pinName := fs.String("pin", "", "Name of the pin to create for the pushed store path (single path only)")
	if err := fs.Parse(args); err != nil {
		return err
	}

	if *fromDir != "" {
		if *pinName != "" {
			return errors.New("--pin cannot be used with --from-dir")
		}
		paths, err := readRecordedOutPaths(*fromDir)
		if err != nil {
			return err
		}
		if len(paths) == 0 {
			fmt.Printf("No recorded output paths found in %s, skipping niks3 push\n", *fromDir)
			return nil
		}
		return maybePushToNiks3("recorded-paths", true, paths)
	}

	if fs.NArg() < 1 {
		return fmt.Errorf("at least one path or --from-dir is required")
	}

	paths := fs.Args()
	if *pinName != "" && len(paths) > 1 {
		return errors.New("--pin requires exactly one store path")
	}

	if err := maybePushToNiks3("manual-push", true, paths); err != nil {
		return err
	}

	if *pinName != "" {
		serverURL := os.Getenv("NIKS3_SERVER_URL")
		if serverURL == "" {
			return errors.New("NIKS3_SERVER_URL not set")
		}
		token, err := getNiks3OIDCToken()
		if err != nil {
			return fmt.Errorf("getting OIDC token for pin: %w", err)
		}
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		if err := createPin(ctx, serverURL, token, *pinName, paths[0]); err != nil {
			return err
		}
	}

	return nil
}

func runPin(args []string) error {
	fs := flag.NewFlagSet("pin", flag.ExitOnError)
	if err := fs.Parse(args); err != nil {
		return err
	}
	if fs.NArg() < 2 {
		return fmt.Errorf("pin name and store path are required (usage: ci-build pin <name> <store-path>)")
	}

	pinName := fs.Arg(0)
	storePath := fs.Arg(1)

	serverURL := os.Getenv("NIKS3_SERVER_URL")
	if serverURL == "" {
		return errors.New("NIKS3_SERVER_URL not set")
	}

	token, err := getNiks3OIDCToken()
	if err != nil {
		return fmt.Errorf("getting OIDC token for pin: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	return createPin(ctx, serverURL, token, pinName, storePath)
}

func createPin(ctx context.Context, serverURL, token, pinName, rawStorePath string) error {
	storePath, err := resolveStorePath(rawStorePath)
	if err != nil {
		return fmt.Errorf("resolving store path %q: %w", rawStorePath, err)
	}

	u := fmt.Sprintf("%s/api/pins/%s", strings.TrimRight(serverURL, "/"), url.PathEscape(pinName))
	payload, err := json.Marshal(map[string]string{"store_path": storePath})
	if err != nil {
		return fmt.Errorf("marshaling pin request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, u, bytes.NewReader(payload))
	if err != nil {
		return fmt.Errorf("creating pin request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	client := newHTTPClient()
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("requesting create pin: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("create pin returned %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	fmt.Printf("Created pin %q for %s\n", pinName, storePath)
	return nil
}

func resolveStorePath(path string) (string, error) {
	if strings.HasPrefix(path, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("resolving home directory: %w", err)
		}
		path = filepath.Join(home, path[2:])
	}

	resolved, err := filepath.EvalSymlinks(path)
	if err == nil {
		path = resolved
	} else if errors.Is(err, os.ErrNotExist) {
		// If the target doesn't exist on disk (e.g. in unit tests or mocked paths),
		// fall back to reading the symlink target directly.
		if target, readErr := os.Readlink(path); readErr == nil {
			path = target
		}
	} else {
		return "", fmt.Errorf("evaluating symlinks for %s: %w", path, err)
	}

	abs, err := filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("getting absolute path for %s: %w", path, err)
	}
	cleanPath := filepath.ToSlash(abs)
	idx := strings.Index(cleanPath, "/nix/store/")
	if idx == -1 {
		return "", fmt.Errorf("store path must start with /nix/store/, got: %s", cleanPath)
	}
	return cleanPath[idx:], nil
}

func newHTTPClient() *http.Client {
	return &http.Client{
		Transport:     nil,
		CheckRedirect: nil,
		Jar:           nil,
		Timeout:       0,
	}
}
