package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"slices"
	"strings"
	"time"
)

const (
	// https://github.com/orgs/community/discussions/26279#discussioncomment-3251171
	ghcrTokenURL = "https://ghcr.io/token?scope=repository:kachick/home:pull"
	ghcrTagsURL  = "https://ghcr.io/v2/kachick/home/tags/list"
)

var errSelectionCanceled = errors.New("selection canceled")

func runGHCR(args []string, e env) error {
	if len(args) > 0 {
		return errors.New("usage: task ghcr")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client := &http.Client{Timeout: 30 * time.Second}
	tags, err := fetchGHCRUTCTags(ctx, client, ghcrTokenURL, ghcrTagsURL)
	if err != nil {
		return err
	}
	if len(tags) == 0 {
		return errors.New("no matching UTC tags found in ghcr.io/kachick/home")
	}

	tag, err := selectWithFzf(tags, "ghcr> ", "", e.stderr)
	if err != nil {
		if errors.Is(err, errSelectionCanceled) {
			return nil
		}
		return err
	}

	return e.runCmd("./containers/sandbox.bash", "--ghcr", tag)
}

func fetchGHCRUTCTags(ctx context.Context, client *http.Client, tokenURL, tagsURL string) ([]string, error) {
	tokenReq, err := http.NewRequestWithContext(ctx, http.MethodGet, tokenURL, nil)
	if err != nil {
		return nil, fmt.Errorf("creating GHCR token request: %w", err)
	}
	tokenResp, err := client.Do(tokenReq)
	if err != nil {
		return nil, fmt.Errorf("requesting GHCR token: %w", err)
	}
	defer tokenResp.Body.Close()

	if tokenResp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(tokenResp.Body)
		return nil, fmt.Errorf("GHCR token endpoint returned %d: %s", tokenResp.StatusCode, strings.TrimSpace(string(body)))
	}

	var tokenData struct {
		Token string `json:"token"`
	}
	if err := json.NewDecoder(tokenResp.Body).Decode(&tokenData); err != nil {
		return nil, fmt.Errorf("decoding GHCR token response: %w", err)
	}
	if tokenData.Token == "" {
		return nil, errors.New("GHCR token response was empty")
	}

	tagsReq, err := http.NewRequestWithContext(ctx, http.MethodGet, tagsURL, nil)
	if err != nil {
		return nil, fmt.Errorf("creating GHCR tags request: %w", err)
	}
	tagsReq.Header.Set("Authorization", "Bearer "+tokenData.Token)

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
	fzfBin, err := exec.LookPath("fzf")
	if err != nil {
		return "", fmt.Errorf("finding fzf: %w", err)
	}

	args := []string{"--reverse"}
	if prompt != "" {
		args = append(args, "--prompt="+prompt)
	}
	if header != "" {
		args = append(args, "--header="+header)
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
