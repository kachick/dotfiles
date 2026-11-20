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

	tree := buildGitxCommandTree()
	switch remaining[0] {
	case "bash":
		_, err := io.WriteString(stdout, generateBashCompletion(tree))
		return err
	case "zsh":
		_, err := io.WriteString(stdout, generateZshCompletion(tree))
		return err
	default:
		fs.Usage()
		return fmt.Errorf("unsupported shell: %s", remaining[0])
	}
}

type bashCompletionNode struct {
	id         string
	spec       cliCommandSpec
	subEntries []cliCommandSpec
	nextIDs    map[string]string
}

func collectBashNodes(spec cliCommandSpec, id string, out *[]bashCompletionNode) {
	subs := withHelpSubcommand(spec)
	nextIDs := make(map[string]string, len(subs))
	for _, sub := range subs {
		childID := id + "_" + sanitizeShellIdentifier(sub.name)
		nextIDs[sub.name] = childID
		collectBashNodes(sub, childID, out)
	}
	*out = append(*out, bashCompletionNode{
		id:         id,
		spec:       spec,
		subEntries: subs,
		nextIDs:    nextIDs,
	})
}

func sanitizeShellIdentifier(name string) string {
	var b strings.Builder
	for _, r := range name {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') {
			b.WriteRune(r)
		} else {
			b.WriteByte('_')
		}
	}
	return b.String()
}

func bashFlagWords(spec cliCommandSpec) string {
	words := []string{"-h", "--help"}
	for _, f := range spec.flags {
		words = append(words, "--"+f.name)
	}
	return strings.Join(words, " ")
}

func generateBashCompletion(tree cliCommandSpec) string {
	var nodes []bashCompletionNode
	collectBashNodes(tree, "root", &nodes)

	var b strings.Builder
	b.WriteString("# bash completion for gitx -*- shell-script -*-\n\n")
	b.WriteString("_gitx_reply_words() {\n")
	b.WriteString("  local words=\"$1\"\n")
	b.WriteString("  local cur=\"$2\"\n")
	b.WriteString("  local prefix=\"${3:-}\"\n")
	b.WriteString("  local line\n")
	b.WriteString("  COMPREPLY=()\n")
	b.WriteString("  while IFS= read -r line; do\n")
	b.WriteString("    COMPREPLY+=(\"$line\")\n")
	b.WriteString("  done < <(compgen -P \"$prefix\" -W \"$words\" -- \"$cur\")\n")
	b.WriteString("}\n\n")

	b.WriteString("_gitx_reply_dirs() {\n")
	b.WriteString("  local cur=\"$1\"\n")
	b.WriteString("  local line\n")
	b.WriteString("  COMPREPLY=()\n")
	b.WriteString("  while IFS= read -r line; do\n")
	b.WriteString("    COMPREPLY+=(\"$line\")\n")
	b.WriteString("  done < <(compgen -d -- \"$cur\")\n")
	b.WriteString("}\n\n")

	b.WriteString("_gitx() {\n")
	b.WriteString("  local cur=\"${COMP_WORDS[COMP_CWORD]}\"\n")
	b.WriteString("  local node=\"root\"\n")
	b.WriteString("  local expect_flag_val=\"\"\n")
	b.WriteString("  local stop_opts=0\n")
	b.WriteString("  local pos_count=0\n")
	b.WriteString("  local i word\n\n")

	b.WriteString("  for (( i = 1; i < COMP_CWORD; i++ )); do\n")
	b.WriteString("    word=\"${COMP_WORDS[i]}\"\n")
	b.WriteString("    if [[ -n \"$expect_flag_val\" ]]; then\n")
	b.WriteString("      expect_flag_val=\"\"\n")
	b.WriteString("      continue\n")
	b.WriteString("    fi\n")
	b.WriteString("    if [[ $stop_opts -eq 0 && \"$word\" == \"--\" ]]; then\n")
	b.WriteString("      stop_opts=1\n")
	b.WriteString("      continue\n")
	b.WriteString("    fi\n")
	b.WriteString("    if [[ $stop_opts -eq 0 && \"$word\" == -* ]]; then\n")
	b.WriteString("      if [[ \"$word\" != *=* ]]; then\n")
	b.WriteString("        case \"${node}:${word}\" in\n")
	for _, node := range nodes {
		var valFlags []string
		for _, f := range node.spec.flags {
			if f.valueName != "" {
				valFlags = append(valFlags, node.id+":--"+f.name)
			}
		}
		if len(valFlags) > 0 {
			fmt.Fprintf(&b, "          %s)\n", strings.Join(valFlags, "|"))
			b.WriteString("            expect_flag_val=\"$word\"\n")
			b.WriteString("            ;;\n")
		}
	}
	b.WriteString("        esac\n")
	b.WriteString("      fi\n")
	b.WriteString("      continue\n")
	b.WriteString("    fi\n\n")

	b.WriteString("    case \"${node}:${word}\" in\n")
	for _, node := range nodes {
		for _, sub := range node.subEntries {
			fmt.Fprintf(&b, "      %s:%s)\n", node.id, sub.name)
			fmt.Fprintf(&b, "        node=%s\n", shellQuote(node.nextIDs[sub.name]))
			b.WriteString("        pos_count=0\n")
			b.WriteString("        ;;\n")
		}
	}
	b.WriteString("      *)\n")
	b.WriteString("        pos_count=$((pos_count + 1))\n")
	b.WriteString("        ;;\n")
	b.WriteString("    esac\n")
	b.WriteString("  done\n\n")

	b.WriteString("  if [[ -n \"$expect_flag_val\" ]]; then\n")
	b.WriteString("    case \"${node}:${expect_flag_val}\" in\n")
	for _, node := range nodes {
		for _, f := range node.spec.flags {
			if f.valueName != "" && len(f.values) > 0 {
				fmt.Fprintf(&b, "      %s:--%s)\n", node.id, f.name)
				fmt.Fprintf(&b, "        _gitx_reply_words %s \"$cur\"\n", shellQuote(strings.Join(f.values, " ")))
				b.WriteString("        ;;\n")
			}
		}
	}
	b.WriteString("      *)\n")
	b.WriteString("        COMPREPLY=()\n")
	b.WriteString("        ;;\n")
	b.WriteString("    esac\n")
	b.WriteString("    return\n")
	b.WriteString("  fi\n\n")

	b.WriteString("  if [[ $stop_opts -eq 0 && \"$cur\" == --*=* ]]; then\n")
	b.WriteString("    local flag_name=\"${cur%%=*}\"\n")
	b.WriteString("    local flag_val=\"${cur#*=}\"\n")
	b.WriteString("    case \"${node}:${flag_name}\" in\n")
	for _, node := range nodes {
		for _, f := range node.spec.flags {
			if f.valueName != "" && len(f.values) > 0 {
				fmt.Fprintf(&b, "      %s:--%s)\n", node.id, f.name)
				fmt.Fprintf(&b, "        _gitx_reply_words %s \"$flag_val\" \"${flag_name}=\"\n", shellQuote(strings.Join(f.values, " ")))
				b.WriteString("        ;;\n")
			}
		}
	}
	b.WriteString("      *)\n")
	b.WriteString("        COMPREPLY=()\n")
	b.WriteString("        ;;\n")
	b.WriteString("    esac\n")
	b.WriteString("    return\n")
	b.WriteString("  fi\n\n")

	b.WriteString("  if [[ $stop_opts -eq 0 && \"$cur\" == -* ]]; then\n")
	b.WriteString("    case \"$node\" in\n")
	for _, node := range nodes {
		fmt.Fprintf(&b, "      %s)\n", node.id)
		fmt.Fprintf(&b, "        _gitx_reply_words %s \"$cur\"\n", shellQuote(bashFlagWords(node.spec)))
		b.WriteString("        ;;\n")
	}
	b.WriteString("    esac\n")
	b.WriteString("    return\n")
	b.WriteString("  fi\n\n")

	b.WriteString("  case \"$node\" in\n")
	for _, node := range nodes {
		switch {
		case len(node.subEntries) > 0:
			names := make([]string, 0, len(node.subEntries))
			for _, sub := range node.subEntries {
				names = append(names, sub.name)
			}
			fmt.Fprintf(&b, "    %s)\n", node.id)
			fmt.Fprintf(&b, "      _gitx_reply_words %s \"$cur\"\n", shellQuote(strings.Join(names, " ")))
			b.WriteString("      ;;\n")
		case node.spec.argKind == argCompleteValues && len(node.spec.argValues) > 0:
			fmt.Fprintf(&b, "    %s)\n", node.id)
			b.WriteString("      if [[ $pos_count -eq 0 ]]; then\n")
			fmt.Fprintf(&b, "        _gitx_reply_words %s \"$cur\"\n", shellQuote(strings.Join(node.spec.argValues, " ")))
			b.WriteString("      fi\n")
			b.WriteString("      ;;\n")
		case node.spec.argKind == argCompleteDirs:
			fmt.Fprintf(&b, "    %s)\n", node.id)
			b.WriteString("      if [[ $pos_count -eq 0 ]]; then\n")
			b.WriteString("        _gitx_reply_dirs \"$cur\"\n")
			b.WriteString("      fi\n")
			b.WriteString("      ;;\n")
		}
	}
	b.WriteString("  esac\n")
	b.WriteString("}\n\n")
	b.WriteString("complete -F _gitx gitx\n")
	return b.String()
}

func sanitizeZshDescription(s string) string {
	s = strings.ReplaceAll(s, "\r\n", " ")
	s = strings.ReplaceAll(s, "\n", " ")
	return strings.TrimSpace(s)
}

func escapeZshArgBracketDesc(s string) string {
	s = sanitizeZshDescription(s)
	replacer := strings.NewReplacer(
		`\`, `\\`,
		`[`, `\[`,
		`]`, `\]`,
		`:`, `\:`,
	)
	return replacer.Replace(s)
}

func zshQuoted(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func zshFlagSpecLine(f cliFlagSpec) string {
	desc := escapeZshArgBracketDesc(f.description)
	spec := fmt.Sprintf("--%s[%s]", f.name, desc)
	if f.valueName != "" {
		label := escapeZshArgBracketDesc(f.valueName)
		if len(f.values) > 0 {
			spec += fmt.Sprintf(":%s:(%s)", label, strings.Join(f.values, " "))
		} else {
			spec += fmt.Sprintf(":%s:", label)
		}
	}
	return zshQuoted(spec)
}

func writeZshCommandFunction(b *strings.Builder, spec cliCommandSpec, fnName string, breadcrumb string) {
	subs := withHelpSubcommand(spec)
	for _, sub := range subs {
		childFn := fnName + "_" + sanitizeShellIdentifier(sub.name)
		writeZshCommandFunction(b, sub, childFn, breadcrumb+" "+sub.name)
	}

	fmt.Fprintf(b, "%s() {\n", fnName)
	var argSpecs []string
	argSpecs = append(argSpecs, `'(-h --help)'{-h,--help}'[Show help]'`)
	for _, f := range spec.flags {
		argSpecs = append(argSpecs, zshFlagSpecLine(f))
	}

	if len(subs) > 0 {
		b.WriteString("  local context state state_descr line\n")
		b.WriteString("  typeset -A opt_args\n\n")
		argSpecs = append(argSpecs, `'1:subcommand:->cmds'`, `'*::arg:->args'`)
		b.WriteString("  _arguments -C \\\n")
		for i, a := range argSpecs {
			if i < len(argSpecs)-1 {
				fmt.Fprintf(b, "    %s \\\n", a)
			} else {
				fmt.Fprintf(b, "    %s\n\n", a)
			}
		}

		b.WriteString("  case \"$state\" in\n")
		b.WriteString("    cmds)\n")
		b.WriteString("      local -a commands\n")
		b.WriteString("      commands=(\n")
		for _, sub := range subs {
			escapedName := strings.ReplaceAll(sub.name, ":", `\:`)
			entry := escapedName + ":" + sanitizeZshDescription(sub.description)
			fmt.Fprintf(b, "        %s\n", zshQuoted(entry))
		}
		b.WriteString("      )\n")
		fmt.Fprintf(b, "      _describe -t commands %s commands\n", zshQuoted(breadcrumb+" subcommand"))
		b.WriteString("      ;;\n")
		b.WriteString("    args)\n")
		b.WriteString("      case \"$line[1]\" in\n")
		for _, sub := range subs {
			childFn := fnName + "_" + sanitizeShellIdentifier(sub.name)
			fmt.Fprintf(b, "        %s)\n", sub.name)
			fmt.Fprintf(b, "          %s\n", childFn)
			b.WriteString("          ;;\n")
		}
		b.WriteString("      esac\n")
		b.WriteString("      ;;\n")
		b.WriteString("  esac\n")
	} else {
		switch spec.argKind {
		case argCompleteValues:
			if len(spec.argValues) > 0 {
				label := spec.argLabel
				if label == "" {
					label = "value"
				}
				argSpecs = append(argSpecs, zshQuoted(fmt.Sprintf("1:%s:(%s)", escapeZshArgBracketDesc(label), strings.Join(spec.argValues, " "))))
			}
		case argCompleteDirs:
			label := spec.argLabel
			if label == "" {
				label = "directory"
			}
			argSpecs = append(argSpecs, zshQuoted(fmt.Sprintf("1:%s:_files -/", escapeZshArgBracketDesc(label))))
		}

		b.WriteString("  _arguments \\\n")
		for i, a := range argSpecs {
			if i < len(argSpecs)-1 {
				fmt.Fprintf(b, "    %s \\\n", a)
			} else {
				fmt.Fprintf(b, "    %s\n", a)
			}
		}
	}

	b.WriteString("}\n\n")
}

func generateZshCompletion(tree cliCommandSpec) string {
	var b strings.Builder
	b.WriteString("#compdef gitx\n\n")
	writeZshCommandFunction(&b, tree, "_gitx", "gitx")
	b.WriteString("if [ \"$funcstack[1]\" = \"_gitx\" ]; then\n")
	b.WriteString("  _gitx \"$@\"\n")
	b.WriteString("else\n")
	b.WriteString("  (( $+functions[compdef] )) && compdef _gitx gitx\n")
	b.WriteString("fi\n")
	return b.String()
}
