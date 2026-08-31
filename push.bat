@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "REMOTE_URL=https://github.com/arnavaggarwal-dev/brackeys-ForReals.git"
set "REPO=arnavaggarwal-dev/brackeys-ForReals"
set "BRANCH=main"

set "MESSAGE=%~1"
set "TAG=%~2"

if "%MESSAGE%"=="" (
    for /f "tokens=* usebackq" %%d in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"`) do set "MESSAGE=work in progress - %%d"
)

if /i "%TAG%"=="notag" (
    set "TAG=none"
) else if "%TAG%"=="" (
    for /f "tokens=* usebackq" %%v in (`powershell -NoProfile -Command "$ts=@(git tag --list 'v*' --sort=-v:refname); $t = if($ts.Count){$ts[0]}else{'v0.0.0'}; $p=($t -replace '^v','').Split('.'); 'v{0}.{1}.{2}' -f $p[0],$p[1],([int]$p[2]+1)"`) do set "TAG=%%v"
)

echo.
echo === ForReals =============================================================
echo   branch  : %BRANCH%
echo   message : !MESSAGE!
if /i not "%TAG%"=="none" echo   tag     : !TAG!  (builds every platform in CI and publishes a release)
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

if /i "%TAG%"=="none" goto :done

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
    echo     cannot wait for it.
    echo     https://github.com/%REPO%/actions
    goto :done
)

echo [*] Waiting for GitHub to export Windows, Linux, macOS, web, Android and iOS...
powershell -NoProfile -Command "Start-Sleep -Seconds 15"
for /f "tokens=* usebackq" %%r in (`gh run list --repo %REPO% --limit 1 --json databaseId --jq ".[0].databaseId"`) do set "RUNID=%%r"
if "!RUNID!"=="" (
    echo [!] Could not find the workflow run. Check it by hand.
    goto :done
)
gh run watch !RUNID! --repo %REPO% --exit-status --interval 20
if errorlevel 1 (
    echo [X] The release build failed. See:
    echo     https://github.com/%REPO%/actions/runs/!RUNID!
    goto :fail
)
echo [+] Release !TAG! published with every platform.

:done
echo.
echo [+] Done.
echo     https://github.com/%REPO%
echo.
endlocal
exit /b 0

:fail
echo.
echo [X] Failed. Nothing further was pushed.
echo.
endlocal
exit /b 1
