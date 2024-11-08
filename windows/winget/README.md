# WinGet

## How to export winget list?

```pwsh
winget export --include-versions --output "\\wsl.localhost\Ubuntu-24.04\home\kachick\repos\github.com\kachick\dotfiles\windows\winget\winget-pkgs-$(Get-Date -UFormat '%F')-raw.json"
```

It may be better to remove some packages such as `Mozilla.Firefox.DeveloperEdition`.

## Which programs excluded winget-pkgs are needed?

- <https://github.com/karakaram/alt-ime-ahk>
- <https://github.com/yuru7/PlemolJP>
- <https://www.realforce.co.jp/support/download/>
- <https://www.kensington.com/ja-jp/software/kensingtonworks/#download> # [winget cannot support v3.1.8+](https://github.com/microsoft/winget-pkgs/pull/136817)
- <https://www.kioxia.com/ja-jp/personal/software/ssd-utility.html>

## Why avoiding winget to install Firefox Developer Edition?

No Japanese locale is registered in winget yet, official installer is supporting.

- <https://github.com/kachick/times_kachick/issues/235>
- <https://github.com/microsoft/winget-pkgs/tree/be851349a154acb14af6275812d79b70fadb9ddf/manifests/m/Mozilla/Firefox/DeveloperEdition/117.0b9>
