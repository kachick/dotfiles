# Don't use absolute path even if used in NixOS. To share same config in Windows
$env.EDITOR = ["hx"]
if $nu.os-info.name == "linux" {
  $env.VISUAL = ["zeditor", "--wait"]
} else {
  $env.VISUAL = ["code", "--wait"]
}

mkdir ($nu.data-dir | path join "vendor/autoload")

starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

zoxide init nushell | save -f ($nu.data-dir | path join "vendor/autoload/zoxide.nu")
