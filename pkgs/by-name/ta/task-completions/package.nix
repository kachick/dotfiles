{
  runCommandLocal,
  go-task,
}:

# Why not install pkgs.go-task directly?
# 1. Avoid exposing a global task executable because projects should decide their own go-task versions in devShells.
# 2. Extracting only completions keeps runtime closure tiny (~9 KiB vs ~50 MiB) with zero runtime references to go-task.
# 3. Mismatched completion scripts across versions are acceptable trade-offs, but running unintended task binaries is not.
runCommandLocal "task-completions"
  {
    meta = {
      description = "Shell completions for go-task without the main binary";
    };
  }
  ''
    mkdir -p "$out/share"
    cp -r "${go-task}/share/bash-completion" "$out/share/"
    cp -r "${go-task}/share/zsh" "$out/share/"
  ''
