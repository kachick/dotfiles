substituteLeafNode() {
	nu --stdin --commands 'lines | each { str replace "\u{2514}" "\u{251c}" } | to text'
}

git diff <(tree "$1" | substituteLeafNode) <(tree "$2" | substituteLeafNode)
