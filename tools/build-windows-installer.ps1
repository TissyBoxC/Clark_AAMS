# 在本机构建 Windows 桌面安装包。
#
# 用法（仓库根目录）：
#   powershell -ExecutionPolicy Bypass -File tools/build-windows-installer.ps1
#
# 会自动从 pubspec.yaml 读版本号，产物输出到 out/ 目录。

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

# 1. 读版本号
$line = Select-String -Path pubspec.yaml -Pattern '^version:' | Select-Object -First 1
$value = ($line.Line -replace '^version:\s*', '').Trim()
$parts = $value.Split('+')
$appVersion = $parts[0]
$appBuild = if ($parts.Count -gt 1) { $parts[1] } else { '1' }
Write-Host "版本：$appVersion (build $appBuild)"

# 2. 找 Inno Setup 编译器
$iscc = @(
  'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
  'C:\Program Files\Inno Setup 6\ISCC.exe',
  (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $iscc) {
  throw '没有找到 Inno Setup。请先安装：winget install JRSoftware.InnoSetup'
}

# 3. 先构建桌面程序，安装包只负责打包
Write-Host '正在构建桌面程序…'
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw '桌面程序构建失败' }

# 4. 打安装包
Write-Host '正在生成安装包…'
& $iscc "/DAppVersion=$appVersion" "/DAppBuild=$appBuild" 'windows\installer\clark_aams.iss'
if ($LASTEXITCODE -ne 0) { throw '安装包构建失败' }

$setup = Get-ChildItem out -Filter 'Clark_AAMS_*_windows_x64.exe' |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($setup) {
  $sizeMb = [math]::Round($setup.Length / 1MB, 1)
  Write-Host ''
  Write-Host "安装包已生成：$($setup.FullName)  (${sizeMb} MB)"
} else {
  throw '安装包没有生成'
}
