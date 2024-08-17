tmprb="$(mktemp --suffix='.rb')"
cat <<'RUBY' >"$tmprb"
$_.gsub!(
  /before/,
  %q|after|
)
RUBY
command "$EDITOR" "$tmprb"

fd --type file --hidden --exclude .git --exec-batch ruby -i -pn "$tmprb"
