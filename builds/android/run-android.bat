@echo off
setlocal enabledelayedexpansion
rem ---------------------------------------------------------------------------
rem  Boots the Android emulator, installs ForReals.apk next to this file, and
rem  starts it.
rem
rem    run-android.bat                 first AVD found, phone geometry
rem    run-android.bat Pixel_6a        that AVD
rem    run-android.bat Pixel_6a tablet 2560x1600 at 276dpi instead
rem
rem  Close the emulator window when you are done, or run: adb emu kill
rem ---------------------------------------------------------------------------

set "APK=%~dp0ForReals.apk"
set "PKG=com.forreals.game"
set "ACTIVITY=%PKG%/com.godot.game.GodotAppLauncher"

set "SDK=%ANDROID_HOME%"
if not defined SDK set "SDK=%ANDROID_SDK_ROOT%"
if not defined SDK set "SDK=%LOCALAPPDATA%\Android\Sdk"

set "ADB=%SDK%\platform-tools\adb.exe"
set "EMULATOR=%SDK%\emulator\emulator.exe"

if not exist "%ADB%" (
	echo Could not find adb at "%ADB%".
	echo Set ANDROID_HOME to your SDK folder and try again.
	exit /b 1
)
if not exist "%EMULATOR%" (
	echo Could not find the emulator at "%EMULATOR%".
	exit /b 1
)
if not exist "%APK%" (
	echo Could not find "%APK%".
	echo Build it first:  godot --headless --path . --export-release "Android" builds/android/ForReals.apk
	exit /b 1
)

set "AVD=%~1"
set "SHAPE=%~2"
if /i "%~1"=="tablet" (
	set "AVD="
	set "SHAPE=tablet"
)

if not defined AVD (
	for /f "usebackq delims=" %%A in (`"%EMULATOR%" -list-avds`) do (
		if not defined AVD set "AVD=%%A"
	)
)
if not defined AVD (
	echo No AVD exists yet. Make one in Android Studio's Device Manager.
	exit /b 1
)

"%ADB%" start-server >nul 2>&1
set "RUNNING="
for /f "usebackq tokens=2" %%D in (`"%ADB%" devices ^| findstr /r "device$"`) do set "RUNNING=1"

if defined RUNNING (
	echo A device is already attached, using that one.
) else (
	echo Booting %AVD% ...
	rem -gpu host, because software Vulkan crashes this emulator outright, and
	rem 4G, because the stock 2G lets the low memory killer take the game down.
	start "Android emulator - %AVD%" "%EMULATOR%" -avd %AVD% ^
		-memory 4096 -no-snapshot -no-boot-anim -no-audio -gpu host
)

"%ADB%" wait-for-device
echo Waiting for Android to finish booting ...
for /l %%I in (1,1,90) do (
	"%ADB%" shell getprop sys.boot_completed 2>nul | findstr /b "1" >nul && goto :booted
	ping -n 6 127.0.0.1 >nul
)
echo Gave up waiting for the emulator to boot.
exit /b 1

:booted
echo Booted.

if /i "%SHAPE%"=="tablet" (
	echo Switching the display to 2560x1600 at 276dpi ...
	"%ADB%" shell wm size 1600x2560 >nul
	"%ADB%" shell wm density 276 >nul
	ping -n 6 127.0.0.1 >nul
)

echo Installing ForReals.apk ...
"%ADB%" install -r "%APK%" || (
	echo Install failed. If it complains about signatures, remove the old copy:
	echo     adb uninstall %PKG%
	exit /b 1
)

"%ADB%" shell am force-stop %PKG% >nul 2>&1
"%ADB%" shell am start -n %ACTIVITY%
echo.
echo Running. The screen stays black for about half a minute on the first
echo launch while the shaders compile - that is normal.
echo.
if /i "%SHAPE%"=="tablet" (
	echo Put the display back afterwards with:
	echo     adb shell wm size reset ^&^& adb shell wm density reset
)
endlocal
