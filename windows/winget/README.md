# WinGet

## How to export winget list?

```pwsh
winget export --include-versions --output "\\wsl.localhost\Ubuntu-24.04\home\kachick\repos\github.com\kachick\dotfiles\windows\winget\winget-pkgs-$(Get-Date -UFormat '%F')-raw.json"
```

It may be better to remove some packages, this list may include other packages out of winget-pkgs.

## Which programs excluded winget-pkgs are needed?

- <https://github.com/jtroo/kanata>
- <https://github.com/yuru7/PlemolJP>
- <https://www.realforce.co.jp/support/download/>
- <https://www.kensington.com/ja-jp/software/kensingtonworks/#download> # [winget cannot support v3.1.8+](https://github.com/microsoft/winget-pkgs/pull/136817)
- <https://www.kioxia.com/ja-jp/personal/software/ssd-utility.html>
