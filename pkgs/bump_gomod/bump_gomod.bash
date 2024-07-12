go get "go@$(go version | grep -oP '(?<=go)\d\S+')"

git add go.mod go.sum
git update-index -q --really-refresh
git diff-index --quiet HEAD || git commit -m 'Update go.mod' go.mod go.sum
