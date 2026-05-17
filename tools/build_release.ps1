param(
  [Parameter(Mandatory = $true)]
  [string]$Version,

  [Parameter(Mandatory = $true)]
  [string]$BuildNumber
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) {
  Write-Host "[INFO] $Message"
}

function Write-Ok([string]$Message) {
  Write-Host "[OK] $Message"
}

function New-Utf8NoBomEncoding {
  return New-Object System.Text.UTF8Encoding -ArgumentList $false, $true
}

function New-Utf8WriteEncoding {
  return New-Object System.Text.UTF8Encoding -ArgumentList $false
}

function U([string]$HexValues) {
  return -join ($HexValues.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object {
    [char][Convert]::ToInt32($_, 16)
  })
}

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (!(Test-Path 'pubspec.yaml')) {
  throw 'pubspec.yaml not found.'
}

if (!(Test-Path 'android\gradlew.bat')) {
  throw 'android\gradlew.bat not found. This script only builds with the local Gradle wrapper.'
}

if ($Version -notmatch '^\d+\.\d+\.\d+([-.][0-9A-Za-z.-]+)?$') {
  throw 'Invalid version name. Example: 1.1.0'
}

if ($BuildNumber -notmatch '^[1-9]\d*$') {
  throw 'Invalid build number. Example: 1'
}

$utf8Read = New-Utf8NoBomEncoding
$utf8Write = New-Utf8WriteEncoding
$pubspecPath = Join-Path $root 'pubspec.yaml'
$pubspec = [System.IO.File]::ReadAllText($pubspecPath, $utf8Read)

if ($pubspec -notmatch '(?m)^version:\s*.+$') {
  throw 'version line not found in pubspec.yaml'
}

$newVersionLine = 'version: ' + $Version + '+' + $BuildNumber
$pubspec = [System.Text.RegularExpressions.Regex]::Replace(
  $pubspec,
  '(?m)^version:\s*.+$',
  $newVersionLine,
  1
)
[System.IO.File]::WriteAllText($pubspecPath, $pubspec, $utf8Write)
Write-Ok "pubspec.yaml version set to $Version+$BuildNumber"

$localPropertiesPath = Join-Path $root 'android\local.properties'
if (Test-Path $localPropertiesPath) {
  $localProperties = [System.IO.File]::ReadAllText($localPropertiesPath, $utf8Read)
  if ($localProperties -match '(?m)^flutter\.versionName=') {
    $localProperties = [System.Text.RegularExpressions.Regex]::Replace(
      $localProperties,
      '(?m)^flutter\.versionName=.*$',
      'flutter.versionName=' + $Version,
      1
    )
  } else {
    $localProperties = $localProperties.TrimEnd() + [Environment]::NewLine + 'flutter.versionName=' + $Version + [Environment]::NewLine
  }
  if ($localProperties -match '(?m)^flutter\.versionCode=') {
    $localProperties = [System.Text.RegularExpressions.Regex]::Replace(
      $localProperties,
      '(?m)^flutter\.versionCode=.*$',
      'flutter.versionCode=' + $BuildNumber,
      1
    )
  } else {
    $localProperties = $localProperties.TrimEnd() + [Environment]::NewLine + 'flutter.versionCode=' + $BuildNumber + [Environment]::NewLine
  }
  [System.IO.File]::WriteAllText($localPropertiesPath, $localProperties, $utf8Write)
  Write-Ok "android/local.properties version set to $Version+$BuildNumber"
}

Write-Step 'Scanning UTF-8 files and common mojibake markers before build...'
$markers = @(
  (U '7EC7') + '?',
  (U '935B') + '?',
  (U '947A') + '?',
  (U '93C8') + '?',
  (U '951B'),
  (U '95BF'),
  (U '6FDE 55F0'),
  (U '7ECB 5D07'),
  (U '6D60 5A49'),
  (U '59AB 7248'),
  (U '7EAD'),
  (U '7481 5267'),
  (U '7487 5267'),
  (U '93B4 623C'),
  (U '68E3 682D'),
  (U '941D'),
  (U '5A34 72B2'),
  (U '9855'),
  (U '9286'),
  (U 'FFFD')
)
$scanRoots = @('lib', 'android', 'test')
$extensions = @('.dart', '.kt', '.java', '.xml', '.gradle', '.properties', '.yaml', '.yml')
$hits = New-Object System.Collections.Generic.List[string]

foreach ($scanRoot in $scanRoots) {
  if (!(Test-Path $scanRoot)) {
    continue
  }
  Get-ChildItem $scanRoot -Recurse -File | Where-Object {
    $extensions -contains $_.Extension
  } | ForEach-Object {
    $file = $_.FullName
    $text = [System.IO.File]::ReadAllText($file, $utf8Read)
    foreach ($marker in $markers) {
      if ($text.Contains($marker)) {
        $relative = Resolve-Path -Relative $file
        $hits.Add("$relative contains mojibake marker.")
        break
      }
    }
  }
}

if ($hits.Count -gt 0) {
  $hits | ForEach-Object { Write-Error $_ }
  throw 'Mojibake scan failed. Fix encoding issues before release build.'
}
Write-Ok 'No common mojibake markers found.'

Write-Step 'Building release APK with android\gradlew.bat assembleRelease...'
Push-Location 'android'
try {
  & '.\gradlew.bat' 'assembleRelease'
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}

$apkPath = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
if (!(Test-Path $apkPath)) {
  throw "Release APK was not found: $apkPath"
}

$releaseDir = Join-Path $root 'release'
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
$targetApk = Join-Path $releaseDir "clark_aams_$($Version)_$($BuildNumber).apk"
Copy-Item -Force $apkPath $targetApk

$metadataPath = Join-Path $root 'build\app\outputs\apk\release\output-metadata.json'
if (Test-Path $metadataPath) {
  $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
  $element = $metadata.elements | Select-Object -First 1
  if ($element.versionName -ne $Version -or [string]$element.versionCode -ne $BuildNumber) {
    throw "Built APK metadata is $($element.versionName)+$($element.versionCode), expected $Version+$BuildNumber"
  }
  Write-Ok "Built APK metadata verified as $Version+$BuildNumber"
}

Write-Ok 'Release APK generated:'
Write-Host $targetApk
