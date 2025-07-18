  # nushell and handling dir symlink looks strange. Might be broken. And adjusted to same results with other environments
  def la [...paths: string] {
    eza --long --all --group-directories-first --time-style=iso --color=always --no-user --sort=modified ...$paths
  }
