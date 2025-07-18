script="$(
	cat <<'EOF'
echo -n "{}: "
git diff --exit-code --quiet <(echo "[]") <(<{} nixf-tidy --pretty-print --variable-lookup)
echo "$?"
EOF
)"

git ls-files '*.nix' | xargs -I{} bash -c "$script" | grep -Pv ': 0$'

# "1" means "worked, but empty" in grep
[[ $? -eq 1 ]]
