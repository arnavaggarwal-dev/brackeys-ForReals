@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0\.."


set "ITCH_TARGET=CHANGEME/for-reals"
set "BUTLER=%USERPROFILE%\tools\butler\butler.exe"
set "VERSION=%~1"

echo.
echo === ForReals -^> itch.io =================================================
echo   target : %ITCH_TARGET%
if not "%VERSION%"=="" echo   version: %VERSION%
echo ==========================================================================
echo.

if "%ITCH_TARGET%"=="CHANGEME/for-reals" (
    echo [X] Edit this script and set ITCH_TARGET to your itch.io user/game slug.
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
    echo [X] No builds found. Export them first - see the README.
    goto :fail
)

set "VFLAG="
if not "%VERSION%"=="" set "VFLAG=--userversion %VERSION%"


echo [*] Pushing Windows...
"%BUTLER%" push "builds\windows" "%ITCH_TARGET%:windows" %VFLAG%
if errorlevel 1 goto :fail

echo [*] Pushing Linux...
"%BUTLER%" push "builds\Linux" "%ITCH_TARGET%:linux" %VFLAG%
if errorlevel 1 goto :fail

echo [*] Pushing web...
"%BUTLER%" push "builds\web" "%ITCH_TARGET%:html" %VFLAG%
if errorlevel 1 goto :fail

echo.
echo [*] Build status:
"%BUTLER%" status "%ITCH_TARGET%"

echo.
echo [+] Done.
echo.
echo     macOS is not pushed from here - it is built in CI, because it cannot
echo     be exported from Windows. Grab it from the GitHub release and push it
echo     with:
echo.
echo       gh release download v1.0.0 -p "ForReals-macos.zip"
echo       "%BUTLER%" push ForReals-macos.zip %ITCH_TARGET%:osx
echo.
echo     Then on the itch page, tick "This file will be played in the browser"
echo     on the html upload, set the viewport to 1280x720, and enable
echo     SharedArrayBuffer support or the web build will not boot.
echo.
endlocal
exit /b 0

:fail
echo.
echo [X] Failed. Nothing further was pushed.
echo.
endlocal
exit /b 1
