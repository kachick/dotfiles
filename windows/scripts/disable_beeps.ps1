# https://github.com/kachick/times_kachick/issues/214
reg add "HKCU\Control Panel\Sound" /v Beep /t REG_SZ /d "no" /f
Write-Output 'Completed, you need to restart Windows'
