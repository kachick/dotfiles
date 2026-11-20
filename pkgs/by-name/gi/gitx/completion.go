package main

import (
	"flag"
	"fmt"
	"io"
	"slices"
	"strings"
)

type argCompletionKind int

const (
	argCompleteNone argCompletionKind = iota
	argCompleteDirs
	argCompleteValues
)

type cliFlagSpec struct {
	name        string
	valueName   string // Non-empty when the flag requires an argument.
	description string
	values      []string
}

type cliCommandSpec struct {
	name            string
	description     string
	flags           []cliFlagSpec
	argKind         argCompletionKind
	argLabel        string
	argValues       []string
	supportsHelpCmd bool
	subcommands     []cliCommandSpec
}

type completionItem struct {
	value       string
	description string
}

type completionDirective string

const (
	completionDirectiveNone completionDirective = "none"
	completionDirectiveDir  completionDirective = "dir"
)

type completionResult struct {
	directive completionDirective
	items     []completionItem
}

type boolFlag interface {
	IsBoolFlag() bool
}

func supportedCompletionShells() []string {
	return []string{"bash", "zsh"}
}

func extractFlagsFromFlagSet(fs *flag.FlagSet, flagValues map[string][]string) []cliFlagSpec {
	if fs == nil {
		return nil
	}
	var specs []cliFlagSpec
	fs.VisitAll(func(f *flag.Flag) {
		valueName := ""
		if bf, ok := f.Value.(boolFlag); !ok || !bf.IsBoolFlag() {
			name, _ := flag.UnquoteUsage(f)
			if name == "" || name == "value" || name == "string" {
				name = f.Name
			}
			valueName = name
		}
		specs = append(specs, cliFlagSpec{
			name:        f.Name,
			valueName:   valueName,
			description: f.Usage,
			values:      slices.Clone(flagValues[f.Name]),
		})
	})
	return specs
}

func wtCommandSpecs() []cliCommandSpec {
	var specs []cliCommandSpec
	for _, sub := range allWTSubcommands() {
		if sub.hidden {
			continue
		}
		var flags []cliFlagSpec
		if sub.newFlags != nil {
			flags = extractFlagsFromFlagSet(sub.newFlags(io.Discard), sub.flagValues)
		}
		specs = append(specs, cliCommandSpec{
			name:        sub.name,
			description: sub.description,
			flags:       flags,
			argKind:     sub.argKind,
			argLabel:    sub.argLabel,
		})
	}
	return specs
}

func buildGitxCommandTree() cliCommandSpec {
	var children []cliCommandSpec
	for _, sub := range allGitxSubcommands() {
		var flags []cliFlagSpec
		if sub.newFlags != nil {
			flags = extractFlagsFromFlagSet(sub.newFlags(io.Discard), sub.flagValues)
		}
		flags = append(flags, sub.flags...)

		var subcmds []cliCommandSpec
		if sub.subcommands != nil {
			subcmds = sub.subcommands()
		}

		children = append(children, cliCommandSpec{
			name:            sub.name,
			description:     sub.description,
			flags:           flags,
			argKind:         sub.argKind,
			argLabel:        sub.argLabel,
			argValues:       slices.Clone(sub.argValues),
			supportsHelpCmd: sub.supportsHelpCmd,
			subcommands:     subcmds,
		})
	}

	return cliCommandSpec{
		name:            "gitx",
		description:     "Unified Git and GitHub workflow helper CLI",
		supportsHelpCmd: true,
		subcommands:     children,
	}
}

func withHelpSubcommand(cmd cliCommandSpec) []cliCommandSpec {
	subcommands := slices.Clone(cmd.subcommands)
	if cmd.supportsHelpCmd {
		subcommands = append(subcommands, cliCommandSpec{
			name:        "help",
			description: "Show help",
		})
	}
	return subcommands
}

func findFlagSpec(flags []cliFlagSpec, rawFlag string) (cliFlagSpec, bool) {
	name := strings.TrimPrefix(rawFlag, "--")
	if name == rawFlag {
		name = strings.TrimPrefix(rawFlag, "-")
	}
	for _, f := range flags {
		if f.name == name {
			return f, true
		}
	}
	return cliFlagSpec{}, false
}

func filterPrefixItems(items []completionItem, prefix string) []completionItem {
	var matched []completionItem
	for _, item := range items {
		if strings.HasPrefix(item.value, prefix) {
			matched = append(matched, item)
		}
	}
	return matched
}

func completeArgs(tree cliCommandSpec, args []string) completionResult {
	if len(args) == 0 {
		args = []string{""}
	}

	completed := args[:len(args)-1]
	cur := args[len(args)-1]

	node := tree
	var expectFlag *cliFlagSpec
	stopOpts := false
	posCount := 0

	for _, word := range completed {
		if expectFlag != nil {
			expectFlag = nil
			continue
		}
		if !stopOpts && word == "--" {
			stopOpts = true
			continue
		}
		if !stopOpts && strings.HasPrefix(word, "-") {
			if !strings.Contains(word, "=") {
				if f, ok := findFlagSpec(node.flags, word); ok && f.valueName != "" {
					expectFlag = &f
				}
			}
			continue
		}

		matchedSub := false
		for _, sub := range withHelpSubcommand(node) {
			if sub.name == word {
				node = sub
				posCount = 0
				matchedSub = true
				break
			}
		}
		if !matchedSub {
			posCount++
		}
	}

	if expectFlag != nil {
		items := make([]completionItem, 0, len(expectFlag.values))
		for _, v := range expectFlag.values {
			items = append(items, completionItem{value: v})
		}
		return completionResult{
			directive: completionDirectiveNone,
			items:     filterPrefixItems(items, cur),
		}
	}

	if !stopOpts && strings.HasPrefix(cur, "--") && strings.Contains(cur, "=") {
		flagToken, valPrefix, _ := strings.Cut(cur, "=")
		f, ok := findFlagSpec(node.flags, flagToken)
		if !ok || f.valueName == "" {
			return completionResult{directive: completionDirectiveNone}
		}
		var items []completionItem
		for _, v := range f.values {
			if strings.HasPrefix(v, valPrefix) {
				items = append(items, completionItem{value: flagToken + "=" + v})
			}
		}
		return completionResult{
			directive: completionDirectiveNone,
			items:     items,
		}
	}

	if !stopOpts && strings.HasPrefix(cur, "-") {
		items := make([]completionItem, 0, 2+len(node.flags))
		items = append(items,
			completionItem{value: "-h", description: "Show help"},
			completionItem{value: "--help", description: "Show help"},
		)
		for _, f := range node.flags {
			items = append(items, completionItem{
				value:       "--" + f.name,
				description: f.description,
			})
		}
		return completionResult{
			directive: completionDirectiveNone,
			items:     filterPrefixItems(items, cur),
		}
	}

	subs := withHelpSubcommand(node)
	if len(subs) > 0 {
		items := make([]completionItem, 0, len(subs))
		for _, sub := range subs {
			items = append(items, completionItem{
				value:       sub.name,
				description: sub.description,
			})
		}
		return completionResult{
			directive: completionDirectiveNone,
			items:     filterPrefixItems(items, cur),
		}
	}

	if node.argKind == argCompleteValues && posCount == 0 {
		items := make([]completionItem, 0, len(node.argValues))
		for _, v := range node.argValues {
			items = append(items, completionItem{value: v})
		}
		return completionResult{
			directive: completionDirectiveNone,
			items:     filterPrefixItems(items, cur),
		}
	}

	if node.argKind == argCompleteDirs && posCount == 0 {
		return completionResult{directive: completionDirectiveDir}
	}

	return completionResult{directive: completionDirectiveNone}
}

func sanitizeCompletionField(s string) string {
	replacer := strings.NewReplacer("\t", " ", "\r", " ", "\n", " ")
	return strings.TrimSpace(replacer.Replace(s))
}

func runComplete(args []string, stdout, _ io.Writer) error {
	result := completeArgs(buildGitxCommandTree(), args)
	if _, err := fmt.Fprintln(stdout, result.directive); err != nil {
		return err
	}
	for _, item := range result.items {
		value := sanitizeCompletionField(item.value)
		desc := sanitizeCompletionField(item.description)
		if desc != "" {
			if _, err := fmt.Fprintf(stdout, "%s\t%s\n", value, desc); err != nil {
				return err
			}
		} else {
			if _, err := fmt.Fprintln(stdout, value); err != nil {
				return err
			}
		}
	}
	return nil
}

func printCompletionUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: gitx completion <bash|zsh>\n\n")
	fmt.Fprintf(w, "Generate shell completion script for bash or zsh.\n")
}

func runCompletion(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("gitx completion", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		printCompletionUsage(stderr)
	}
	if err := fs.Parse(args); err != nil {
		return err
	}

	remaining := fs.Args()
	if len(remaining) != 1 {
		fs.Usage()
		return fmt.Errorf("expected 1 shell argument (%s), got %d", strings.Join(supportedCompletionShells(), "|"), len(remaining))
	}

	switch remaining[0] {
	case "bash":
		_, err := io.WriteString(stdout, bashCompletionScript)
		return err
	case "zsh":
		_, err := io.WriteString(stdout, zshCompletionScript)
		return err
	default:
		fs.Usage()
		return fmt.Errorf("unsupported shell: %s", remaining[0])
	}
}

// Keep shell wrappers thin and delegate parsing to `gitx __complete` so subcommand
// and flag changes in Go never drift from generated completion scripts.
const bashCompletionScript = `# bash completion for gitx -*- shell-script -*-

_gitx() {
  local out directive value _desc
  local -a args=("${COMP_WORDS[@]:1:COMP_CWORD}")
  if [[ ${#args[@]} -eq 0 ]]; then
    args=("")
  fi

  local bin="${COMP_WORDS[0]:-gitx}"
  if ! out="$(command "$bin" __complete "${args[@]}" 2>/dev/null)"; then
    COMPREPLY=()
    return
  fi

  COMPREPLY=()
  {
    IFS= read -r directive || return
    while IFS=$'\t' read -r value _desc; do
      [[ -n "$value" ]] && COMPREPLY+=("$value")
    done
  } <<< "$out"

  if [[ "$directive" == "dir" ]]; then
    local cur="${COMP_WORDS[COMP_CWORD]}"
    while IFS= read -r value; do
      COMPREPLY+=("$value")
    done < <(compgen -d -- "$cur")
  fi
}

complete -F _gitx gitx
`

const zshCompletionScript = `#compdef gitx

_gitx() {
  local out directive line value desc
  local -a args items

  args=("${(@)words[2,CURRENT]}")
  if (( ${#args} == 0 )); then
    args=("")
  fi

  out="$(command "${words[1]}" __complete "${args[@]}" 2>/dev/null)" || return 1

  local first=1
  for line in "${(@f)out}"; do
    if (( first )); then
      directive="$line"
      first=0
      continue
    fi
    [[ -z "$line" ]] && continue
    value="${line%%$'\t'*}"
    if [[ "$line" == *$'\t'* ]]; then
      desc="${line#*$'\t'}"
      items+=("${value//:/\\:}:${desc}")
    else
      items+=("${value//:/\\:}")
    fi
  done

  if (( ${#items} > 0 )); then
    _describe -t completions 'gitx' items
  fi

  if [[ "$directive" == "dir" ]]; then
    _files -/
  fi
}

if [ "$funcstack[1]" = "_gitx" ]; then
  _gitx "$@"
else
  (( $+functions[compdef] )) && compdef _gitx gitx
fi
`
