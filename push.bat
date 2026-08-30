@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

REM ---------------------------------------------------------------------------
REM  push.bat - commit everything and push to GitHub.
REM
REM    push.bat                        commit with a timestamp message
REM    push.bat "fixed the composer"   commit with your own message
REM    push.bat "v1 build" v1.0.0      ...and tag it, which fires the release
REM                                    workflow and publishes the exports
REM ---------------------------------------------------------------------------

set "REMOTE_URL=https://github.com/arnavaggarwal-dev/brackeys-ForReals.git"
set "BRANCH=main"

set "MESSAGE=%~1"
set "TAG=%~2"

if "%MESSAGE%"=="" (
    for /f "tokens=* usebackq" %%d in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"`) do set "MESSAGE=work in progress - %%d"
)

echo.
echo === ForReals =============================================================
echo   branch  : %BRANCH%
echo   message : !MESSAGE!
if not "%TAG%"=="" echo   tag     : %TAG%  (this will publish a release)
echo ==========================================================================
echo.

REM --- sanity checks --------------------------------------------------------

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

REM --- make sure a remote exists --------------------------------------------

git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo [*] No 'origin' remote yet - pointing it at %REMOTE_URL%
    git remote add origin "%REMOTE_URL%"
    if errorlevel 1 goto :fail
)

REM --- stage and commit -----------------------------------------------------

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

REM --- optional tag, which triggers .github/workflows/release.yml ------------

if "%TAG%"=="" goto :done

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
