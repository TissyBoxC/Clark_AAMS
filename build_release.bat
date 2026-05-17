@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "ROOT=%~dp0"
cd /d "%ROOT%" || exit /b 1

set "APP_VERSION=%~1"
set "BUILD_NUMBER=%~2"

if "%APP_VERSION%"=="" (
  set /p "APP_VERSION=Input version name, for example 1.1.0: "
)

if "%BUILD_NUMBER%"=="" (
  set /p "BUILD_NUMBER=Input build number, for example 1: "
)

if not exist "%ROOT%tools\build_release.ps1" (
  echo [ERROR] tools\build_release.ps1 not found.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%tools\build_release.ps1" -Version "%APP_VERSION%" -BuildNumber "%BUILD_NUMBER%"
exit /b %errorlevel%
