@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "REMOTE_URL=https://github.com/arnavaggarwal-dev/brackeys-ForReals.git"
set "REPO=arnavaggarwal-dev/brackeys-ForReals"
set "BRANCH=main"
set "ITCH_TARGET=lazilydev/forreals"
set "BUTLER=%USERPROFILE%\tools\butler\butler.exe"

set "MESSAGE=%~1"
set "TAG=%~2"
set "ITCH=%~3"

if "%MESSAGE%"=="" (
    for /f "tokens=* usebackq" %%d in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"`) do set "MESSAGE=work in progress - %%d"
)

if /i "%TAG%"=="itch" (
    set "ITCH=itch"
    set "TAG="
)

if /i "%TAG%"=="notag" (
    set "TAG=none"
) else if "%TAG%"=="" (
    for /f "tokens=* usebackq" %%v in (`powershell -NoProfile -Command "$t=(git describe --tags --abbrev=0 2^>$null); if(-not $t){$t='v0.0.0'}; $t=$t -replace '^v',''; $p=$t.Split('.'); 'v{0}.{1}.{2}' -f $p[0],$p[1],([int]$p[2]+1)"`) do set "TAG=%%v"
)

echo.
echo === ForReals =============================================================
echo   branch  : %BRANCH%
echo   message : !MESSAGE!
if /i not "%TAG%"=="none" echo   tag     : !TAG!  (builds macOS in CI and publishes a release)
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
echo [*] Pushing to %BRANCH% ^(LFS objects make this the slow part^)...
git push -u origin %BRANCH%
if errorlevel 1 goto :fail

if /i "%TAG%"=="none" goto :itch

echo [*] Tagging !TAG!...
git tag -a "!TAG!" -m "!MESSAGE!"
if errorlevel 1 (
    echo [X] Could not create tag !TAG! - does it already exist?
    goto :fail
)
git push origin "!TAG!"
if errorlevel 1 goto :fail

where gh >nul 2>&1
if errorlevel 1 (
    echo [!] gh CLI not found - the release is building, but this script
    echo     cannot wait for it or fetch the macOS build.
    echo     https://github.com/%REPO%/actions
    goto :itch
)

echo [*] Waiting for GitHub to export Windows, Linux, macOS and web...
powershell -NoProfile -Command "Start-Sleep -Seconds 15"
for /f "tokens=* usebackq" %%r in (`gh run list --repo %REPO% --limit 1 --json databaseId --jq ".[0].databaseId"`) do set "RUNID=%%r"
if "!RUNID!"=="" (
    echo [!] Could not find the workflow run. Check it by hand.
    goto :itch
)
gh run watch !RUNID! --repo %REPO% --exit-status --interval 20
if errorlevel 1 (
    echo [X] The release build failed. See:
    echo     https://github.com/%REPO%/actions/runs/!RUNID!
    goto :fail
)
echo [+] Release !TAG! published with all four platforms.

:itch
if /i not "%ITCH%"=="itch" goto :done

echo.
echo [*] Uploading to itch.io...

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
if /i not "%TAG%"=="none" set "VFLAG=--userversion !TAG:v=!"

echo [*] itch: Windows...
"%BUTLER%" push "builds\windows" "%ITCH_TARGET%:windows" %VFLAG%
if errorlevel 1 goto :fail
echo [*] itch: Linux...
"%BUTLER%" push "builds\Linux" "%ITCH_TARGET%:linux" %VFLAG%
if errorlevel 1 goto :fail
echo [*] itch: web...
"%BUTLER%" push "builds\web" "%ITCH_TARGET%:html" %VFLAG%
if errorlevel 1 goto :fail

REM macOS cannot be exported on Windows, so it comes back off the release CI
REM just built. Without a tag there is no release to take it from.
if /i "%TAG%"=="none" (
    echo [!] No tag, so no macOS build to fetch. itch osx stays where it was.
    goto :status
)
where gh >nul 2>&1
if errorlevel 1 goto :status

echo [*] itch: macOS ^(from release !TAG!^)...
if exist "%TEMP%\ForReals-macos.zip" del /q "%TEMP%\ForReals-macos.zip"
gh release download "!TAG!" --repo %REPO% --pattern "ForReals-macos.zip" --dir "%TEMP%" --clobber
if errorlevel 1 (
    echo [!] Could not download the macOS build from release !TAG!.
    goto :status
)
"%BUTLER%" push "%TEMP%\ForReals-macos.zip" "%ITCH_TARGET%:osx" %VFLAG%
if errorlevel 1 goto :fail
del /q "%TEMP%\ForReals-macos.zip"

:status
echo.
"%BUTLER%" status "%ITCH_TARGET%"

:done
echo.
echo [+] Done.
echo     https://github.com/%REPO%
if /i "%ITCH%"=="itch" echo     https://lazilydev.itch.io/forreals
echo.
endlocal
exit /b 0

:fail
echo.
echo [X] Failed. Nothing further was pushed.
echo.
endlocal
exit /b 1
