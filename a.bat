@echo off
chcp 65001
PowerShell -ExecutionPolicy Bypass -Command "Get-NetTCPConnection -LocalPort 8090 -ErrorAction SilentlyContinue | Where-Object State -eq Listen | ForEach-Object {Stop-Process -Id $_.OwningProcess -Force};Get-Process dart -ErrorAction SilentlyContinue|Stop-Process -Force;if(Test-Path ./build){Remove-Item -Recurse -Force ./build};if(Test-Path ./.dart_tool){Remove-Item -Recurse -Force ./.dart_tool}"
echo ======================================
echo ✔已杀掉dart僵尸进程、释放8090端口、清理缓存
echo ⚠回到WorkBuddy里面重新运行你的项目
echo ======================================
pause
