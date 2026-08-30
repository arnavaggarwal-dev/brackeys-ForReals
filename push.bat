@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "REMOTE_URL=https://github.com/arnavaggarwal-dev/brackeys-ForReals.git"
set "BRANCH=main"
set "ITCH_TARGET=CHANGEME/for-reals"
set "BUTLER=%USERPROFILE%\tools\butler\butler.exe"

set "MESSAGE=%~1"
set "TAG=%~2"
set "ITCH=%~3"

if "%MESSAGE%"=="" (
    for /f "tokens=* usebackq" %%d in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"`) do set "MESSAGE=work in progress - %%d"
)

echo.
echo === ForReals =============================================================
echo   branch  : %BRANCH%
echo   message : !MESSAGE!
if not "%TAG%"=="" echo   tag     : %TAG%  (this will publish a release)
if /i "%ITCH%"=="itch" echo   itch    : %ITCH_TARGET%
echo ==========================================================================
echo.

git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo [X] Not a git repository. Run this from the project folder.
    goto :fail
)

git lfs version >nul 2>&1
if errorlevel 1 (
    echo [X] Git LFS is not installed. The builds folder cannot be pushed
    echo     without it - ForReals.exe alone is over GitHub's 100 MB limit.
    echo     Get it from https://git-lfs.com then re-run this script.
    goto :fail
)

git lfs install --local >nul 2>&1

git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo [*] No 'origin' remote yet - pointing it at %REMOTE_URL%
    git remote add origin "%REMOTE_URL%"
    if errorlevel 1 goto :fail
)

echo [*] Staging...
git add -A
if errorlevel 1 goto :fail

git diff --cached --quiet
if not errorlevel 1 (
    echo [*] Nothing to commit - the tree is already clean.
    goto :push
)

echo.
git status --short
echo.

echo [*] Committing...
git commit -m "!MESSAGE!"
if errorlevel 1 goto :fail

:push
echo [*] Pushing LFS objects and commits to %BRANCH% ^(this is the slow part^)...
git push -u origin %BRANCH%
if errorlevel 1 goto :fail

if "%TAG%"=="" goto :itch

echo [*] Tagging %TAG%...
git tag -a "%TAG%" -m "!MESSAGE!"
if errorlevel 1 (
    echo [X] Could not create tag %TAG% - does it already exist?
    goto :fail
)

git push origin "%TAG%"
if errorlevel 1 goto :fail

echo.
echo [+] Tag pushed. GitHub is now exporting Windows, Linux, macOS and web.
echo     Watch it: https://github.com/arnavaggarwal-dev/brackeys-ForReals/actions

:itch
if /i not "%ITCH%"=="itch" goto :done

echo.
echo [*] Uploading builds to itch.io...

if "%ITCH_TARGET%"=="CHANGEME/for-reals" (
    echo [X] Edit this script and set ITCH_TARGET to your itch.io user/game slug.
    echo     The slug is the last part of the page URL, not the display title.
    goto :fail
)

if not exist "%BUTLER%" (
    echo [X] butler not found at %BUTLER%
    echo     Get it from https://itch.io/docs/butler/installing.html
    goto :fail
)

"%BUTLER%" login >nul 2>&1
if errorlevel 1 (
    echo [X] butler is not logged in. Run:  "%BUTLER%" login
    goto :fail
)

if not exist "builds\windows\ForReals.exe" (
    echo [X] No builds found to upload. Export them first - see the README.
    goto :fail
)

set "VFLAG="
if not "%TAG%"=="" set "VFLAG=--userversion %TAG:v=%"

echo [*] itch: Windows...
"%BUTLER%" push "builds\windows" "%ITCH_TARGET%:windows" %VFLAG%
if errorlevel 1 goto :fail

echo [*] itch: Linux...
"%BUTLER%" push "builds\Linux" "%ITCH_TARGET%:linux" %VFLAG%
if errorlevel 1 goto :fail

echo [*] itch: web...
"%BUTLER%" push "builds\web" "%ITCH_TARGET%:html" %VFLAG%
if errorlevel 1 goto :fail

echo.
"%BUTLER%" status "%ITCH_TARGET%"
echo.
echo     macOS is not uploaded from here - it cannot be exported on Windows.
echo     Once the release finishes building:
echo       gh release download %TAG% -p "ForReals-macos.zip"
echo       "%BUTLER%" push ForReals-macos.zip %ITCH_TARGET%:osx

:done
echo.
echo [+] Done.
echo     https://github.com/arnavaggarwal-dev/brackeys-ForReals
echo.
endlocal
exit /b 0

:fail
echo.
echo [X] Failed. Nothing further was pushed.
echo.
endlocal
exit /b 1
