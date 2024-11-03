tmprb="$(mktemp --suffix='.rb')"
cat <<'RUBY' >"$tmprb"
$_.gsub!(
  /before/,
  %q|after|
)
RUBY
command "$EDITOR" "$tmprb"

# TODO: grep takes the "before" if given then via CLI
fd --type file --hidden --exclude .git |
	xargs grep --binary-files=without-match -l --fixed-strings -e '' |
	xargs ruby -i -pn "$tmprb"
