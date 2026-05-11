@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title System Tweaker v3.0.0

:: ============================================================================
:: v3.0.0: COMPLETE REWRITE BASED ON STABLE v1.11
:: - Preserved working logic from v1.11
:: - Added English UI, logging, backups, OS detection
:: - Fixed window size, safe explorer restart
:: - Removed broken BATCH_MODE and complex fallbacks
:: ============================================================================

:: === AUTO ELEVATION ===
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [!] Administrator privileges required.
    echo     Please confirm the UAC prompt.
    echo.
    powershell -NoProfile -Command "Start-Process '%~dpnx0' -Verb RunAs" >nul 2>&1
    exit /b
)

:: ============================================================================
:: FIXED WINDOW SIZE & OS DETECTION
:: ============================================================================
mode con cols=100 lines=35

for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul') do set "BUILD=%%v"
if %BUILD% GEQ 22000 (
    set "OS_TYPE=win11"
    set "OS_NAME=Windows 11"
) else (
    set "OS_TYPE=win10"
    set "OS_NAME=Windows 10"
)

:: Colors
set "VERSION=v3.0.0"
for /f "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "blue=%ESC%[96m"
set "green=%ESC%[92m"
set "red=%ESC%[91m"
set "yellow=%ESC%[93m"
set "white=%ESC%[97m"
set "reset=%ESC%[0m"

:: Paths
set "LOG_DIR=%LOCALAPPDATA%\Tweaker"
set "LOG_FILE=%LOG_DIR%\system_tweaker.log"
set "BACKUP_DIR=%USERPROFILE%\Desktop\Tweaker_Backups"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul

echo [%date% %time%] === System Tweaker %VERSION% (%OS_NAME%) Started === >> "%LOG_FILE%"

:: Backup
if not exist "%BACKUP_DIR%\%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_init.reg" (
    echo [*] Creating registry backup...
    for %%K in (
        "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        "HKCU\Control Panel\Mouse"
        "HKCU\Control Panel\Desktop"
        "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
    ) do reg export "%%~K" "%BACKUP_DIR%\%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_init.reg" /y >nul 2>&1
    echo [%date% %time%] Backup created >> "%LOG_FILE%"
)

call :CheckStatus
goto menu

:: ============================================================================
:: MAIN MENU
:: ============================================================================
:menu
cls
echo.
echo %blue%SYSTEM TWEAKER %VERSION%%reset%
echo ================================================================================
echo.
echo %yellow%  %OS_NAME% (Build %BUILD%)%reset%
echo %yellow%  Changes apply instantly. Restart may be required.%reset%
echo %yellow%  Registry backup saved to Desktop.%reset%
echo.
echo %white%[1]%reset%  Power Plan                   : %power_color%%power_status%%reset%
echo %white%[2]%reset%  Background UWP Apps          : %uwp_color%%uwp_status%%reset%
echo %white%[3]%reset%  Delivery Optimization        : %delivery_color%%delivery_status%%reset%
echo %white%[4]%reset%  Edge Startup Boost           : %edge_color%%edge_status%%reset%
echo %white%[5]%reset%  Telemetry ^& Ads              : %tele_color%%tele_status%%reset%
echo %white%[6]%reset%  Windows Copilot AI           : %copilot_color%%copilot_status%%reset%
echo %white%[7]%reset%  User Account Control         : %uac_color%%uac_status%%reset%
echo %white%[8]%reset%  Mouse Acceleration           : %mouse_color%%mouse_status%%reset%
echo %white%[9]%reset%  Sticky Keys                  : %sticky_color%%sticky_status%%reset%
echo %white%[10]%reset% Context Menu Delay           : %menu_color%%menu_status%%reset%
echo %white%[11]%reset% Wallpaper Compression        : %wallpaper_color%%wallpaper_status%%reset%
if "%OS_TYPE%"=="win11" (
    echo %white%[12]%reset% Start Recommendations        : %rec_color%%rec_status%%reset%
) else (
    echo %white%[12]%reset% Document Tracking            : %rec_color%%rec_status%%reset%
)
echo.
echo --------------------------------------------------------------------------------
echo %yellow%[T]%reset%  %yellow%Configure Taskbar%reset%
echo %yellow%[S]%reset%  %yellow%Reset Start Menu%reset%
echo %yellow%[X]%reset%  %yellow%Safe System Cleanup%reset%
echo.
echo %green%[A]%reset%  %green%Apply All Settings%reset%
echo %red%[D]%reset%  %red%Restore Defaults%reset%
echo %white%[0]%reset%  %white%Exit%reset%
echo.
echo ================================================================================
echo.
set /p choice="%white%Enter option number: %reset%"

if "%choice%"=="1" call :ApplyPowerPlan
if "%choice%"=="2" call :ApplyUWP
if "%choice%"=="3" call :ApplyDelivery
if "%choice%"=="4" call :ApplyEdge
if "%choice%"=="5" call :ApplyTelemetry
if "%choice%"=="6" call :ApplyCopilot
if "%choice%"=="7" call :ApplyUAC
if "%choice%"=="8" call :ApplyMouse
if "%choice%"=="9" call :ApplySticky
if "%choice%"=="10" call :ApplyMenuDelay
if "%choice%"=="11" call :ApplyWallpaper
if "%choice%"=="12" call :ApplyRecommended
if /i "%choice%"=="T" call :CleanTaskbar
if /i "%choice%"=="S" call :CleanStartMenu
if /i "%choice%"=="X" call :SystemCleanup
if /i "%choice%"=="A" call :ApplyAll
if /i "%choice%"=="D" call :RestoreDefaults
if "%choice%"=="0" goto end

call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:: ============================================================================
:: STATUS CHECK - SIMPLE AND RELIABLE (v1.11 BASED)
:: ============================================================================
:CheckStatus
:: 1. Power Plan
powercfg /getactivescheme 2>nul | findstr /i "8c5e7fda" >nul
if %errorlevel% equ 0 (set "power_color=%green%" & set "power_status=High Performance") else (set "power_color=%red%" & set "power_status=Balanced")

:: 2. UWP Background
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled 2>nul | find "0x1" >nul
if %errorlevel% equ 0 (set "uwp_color=%green%" & set "uwp_status=Disabled") else (set "uwp_color=%red%" & set "uwp_status=Enabled")

:: 3. Delivery Optimization
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "delivery_color=%green%" & set "delivery_status=Disabled") else (set "delivery_color=%red%" & set "delivery_status=Enabled")

:: 4. Edge Boost
reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "edge_color=%green%" & set "edge_status=Disabled") else (set "edge_color=%red%" & set "edge_status=Enabled")

:: 5. Telemetry
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "tele_color=%green%" & set "tele_status=Disabled") else (set "tele_color=%red%" & set "tele_status=Enabled")

:: 6. Copilot
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot 2>nul | find "0x1" >nul
if %errorlevel% equ 0 (set "copilot_color=%green%" & set "copilot_status=Disabled") else (set "copilot_color=%red%" & set "copilot_status=Enabled")

:: 7. UAC
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "uac_color=%yellow%" & set "uac_status=Disabled") else (set "uac_color=%green%" & set "uac_status=Enabled")

:: 8. Mouse Accel
reg query "HKCU\Control Panel\Mouse" /v MouseSpeed 2>nul | find "0" >nul
if %errorlevel% equ 0 (set "mouse_color=%green%" & set "mouse_status=Disabled") else (set "mouse_color=%red%" & set "mouse_status=Enabled")

:: 9. Sticky Keys
reg query "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags 2>nul | find "506" >nul
if %errorlevel% equ 0 (set "sticky_color=%green%" & set "sticky_status=Disabled") else (set "sticky_color=%red%" & set "sticky_status=Enabled")

:: 10. Menu Delay
reg query "HKCU\Control Panel\Desktop" /v MenuShowDelay 2>nul | find "20" >nul
if %errorlevel% equ 0 (set "menu_color=%green%" & set "menu_status=20 ms") else (set "menu_color=%red%" & set "menu_status=400 ms")

:: 11. Wallpaper
reg query "HKCU\Control Panel\Desktop" /v JPEGImportQuality 2>nul | find "0x64" >nul
if %errorlevel% equ 0 (set "wallpaper_color=%green%" & set "wallpaper_status=Disabled") else (set "wallpaper_color=%red%" & set "wallpaper_status=Enabled")

:: 12. Recommendations
if "%OS_TYPE%"=="win11" (
    reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HideRecommendedSection 2>nul | find "0x1" >nul
) else (
    reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs 2>nul | find "0x0" >nul
)
if %errorlevel% equ 0 (set "rec_color=%green%" & set "rec_status=Hidden") else (set "rec_color=%red%" & set "rec_status=Shown")

goto :eof

:: ============================================================================
:: SAFE EXPLORER RESTART (WITHOUT KILLING CONSOLE)
:: ============================================================================
:RestartExplorerGracefully
echo [*] Restarting Explorer...
taskkill /IM explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start "" explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
goto :eof

:: ============================================================================
:: APPLY FUNCTIONS - SIMPLE AND RELIABLE (v1.11 BASED)
:: ============================================================================
:ApplyPowerPlan
echo.
echo [*] Setting power plan...
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>nul
if %errorlevel% equ 0 (
    echo [+] Power plan changed!
    echo [%date% %time%] Applied: PowerPlan >> "%LOG_FILE%"
) else (
    echo [!] Error changing power plan
)
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyUWP
echo.
echo [*] Disabling background apps...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f >nul
echo [+] Background apps disabled!
echo [%date% %time%] Applied: UWP_Background >> "%LOG_FILE%"
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyDelivery
echo.
echo [*] Disabling delivery optimization...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d "0" /f >nul
sc config DoSvc start=disabled >nul 2>&1
sc stop DoSvc >nul 2>&1
echo [+] Delivery optimization disabled!
echo [%date% %time%] Applied: Delivery >> "%LOG_FILE%"
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyEdge
echo.
echo [*] Disabling Edge Boost...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /t REG_DWORD /d "0" /f >nul
echo [+] Edge Startup Boost disabled!
echo [%date% %time%] Applied: Edge >> "%LOG_FILE%"
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyTelemetry
echo.
echo [*] Disabling telemetry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d "1" /f >nul
echo [+] Telemetry and ads disabled!
echo [%date% %time%] Applied: Telemetry >> "%LOG_FILE%"
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyCopilot
echo.
echo [*] Disabling Windows Copilot...
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f >nul
call :RestartExplorerGracefully
echo [+] Windows Copilot disabled!
echo [%date% %time%] Applied: Copilot >> "%LOG_FILE%"
call :CheckStatus
timeout /t 2 /nobreak >nul
goto menu

:ApplyUAC
echo.
echo [!] WARNING: Disabling UAC reduces system security.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto menu
echo [*] Disabling UAC...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f >nul
echo [+] UAC disabled! Restart required.
echo [%date% %time%] Applied: UAC >> "%LOG_FILE%"
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyMouse
echo.
echo [*] Disabling mouse acceleration...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul
echo [+] Mouse acceleration disabled!
echo [%date% %time%] Applied: Mouse >> "%LOG_FILE%"
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplySticky
echo.
echo [*] Disabling sticky keys...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f >nul
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f >nul
echo [+] Sticky keys disabled!
echo [%date% %time%] Applied: StickyKeys >> "%LOG_FILE%"
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyMenuDelay
echo.
echo [*] Speeding up context menu...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "20" /f >nul
echo [+] Menu delay set to 20 ms!
echo [%date% %time%] Applied: MenuDelay >> "%LOG_FILE%"
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyWallpaper
echo.
echo [*] Disabling wallpaper compression...
reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "100" /f >nul
echo [+] Wallpaper compression disabled!
echo [%date% %time%] Applied: Wallpaper >> "%LOG_FILE%"
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyRecommended
echo.
echo [*] Hiding recommendations...
if "%OS_TYPE%"=="win11" (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d "0" /f >nul
) else (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f >nul
)
call :RestartExplorerGracefully
echo [+] Recommendations hidden!
echo [%date% %time%] Applied: Recommended >> "%LOG_FILE%"
call :CheckStatus
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================================
:: CLEANUP FUNCTIONS
:: ============================================================================
:CleanTaskbar
cls
echo.
echo %yellow%[*] CONFIGURING TASKBAR...%reset% (%OS_NAME%)
echo ================================================================================
echo [1/4] Applying policies...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "0" /f >nul 2>&1

echo [2/4] Clearing pin cache...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams" /f >nul 2>&1
del /f /q "%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.*" >nul 2>&1

echo [3/4] Restarting Explorer...
call :RestartExplorerGracefully

echo [4/4] Pinning Explorer...
if "%OS_TYPE%"=="win10" (
    powershell -NoProfile -Command "$s=New-Object -Com Shell.Application; $f=$s.NameSpace('C:\Windows'); $i=$f.ParseName('explorer.exe'); $i.InvokeVerb('taskbarpin')" >nul 2>&1
)
echo [+] Taskbar configured.
timeout /t 2 /nobreak >nul
goto menu

:CleanStartMenu
cls
echo.
echo %yellow%[*] RESETTING START MENU...%reset%
echo ================================================================================
echo [1/3] Removing shortcuts...
del /f /q "%AppData%\Microsoft\Windows\Start Menu\Programs\*.*" >nul 2>&1

echo [2/3] Clearing layout cache...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore" /f >nul 2>&1
call :RestartExplorerGracefully

echo [3/3] Removing binary caches...
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenu*.bin" >nul 2>&1
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenulayout.bin" >nul 2>&1
echo [+] Start menu reset.
timeout /t 2 /nobreak >nul
goto menu

:SystemCleanup
cls
echo.
echo %yellow%[*] SAFE SYSTEM CLEANUP...%reset%
echo ================================================================================
echo [1/5] Temporary files...
del /f /s /q "%TEMP%\*" >nul 2>&1
echo [+] TEMP cleaned

echo [2/5] Windows Temp...
del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
echo [+] Windows Temp cleaned

echo [3/5] Update cache...
net stop wuauserv >nul 2>&1
del /f /s /q "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
net start wuauserv >nul 2>&1
echo [+] Update cache cleaned

echo [4/5] DirectX Shader...
del /f /s /q "%LocalAppData%\D3DSCache\*" >nul 2>&1
echo [+] D3DSCache cleaned

echo [5/5] Recycle Bin...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo [+] Recycle Bin cleaned

echo ================================================================================
echo %green%     CLEANUP COMPLETE%reset%
echo ================================================================================
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================================
:: APPLY ALL - SEQUENTIAL (v1.11 BASED)
:: ============================================================================
:ApplyAll
cls
echo %green%[*] APPLYING ALL SETTINGS...%reset%
echo ================================================================================
echo [ 1/12] Power Plan...
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>nul
echo [ 2/12] Background UWP Apps...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f >nul
echo [ 3/12] Delivery Optimization...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d "0" /f >nul
sc config DoSvc start=disabled >nul 2>&1
sc stop DoSvc >nul 2>&1
echo [ 4/12] Edge Startup Boost...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /t REG_DWORD /d "0" /f >nul
echo [ 5/12] Telemetry ^& Ads...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d "1" /f >nul
echo [ 6/12] Windows Copilot...
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f >nul
echo [ 7/12] User Account Control...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f >nul
echo [ 8/12] Mouse Acceleration...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul
echo [ 9/12] Sticky Keys...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f >nul
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f >nul
echo [10/12] Menu Delay...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "20" /f >nul
echo [11/12] Wallpaper Compression...
reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "100" /f >nul
echo [12/12] Recommendations...
if "%OS_TYPE%"=="win11" (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecommendedSection" /t REG_DWORD /d "0" /f >nul
) else (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f >nul
)
call :RestartExplorerGracefully

echo.
echo ================================================================================
echo %green%     ALL SETTINGS APPLIED!%reset%
echo ================================================================================
echo.
echo %yellow%  System restart recommended.%reset%
set /p reboot="Restart now? (Y/N): "
if /i "%reboot%"=="Y" (
    echo [*] Restarting in 5 seconds...
    timeout /t 5 /nobreak >nul
    shutdown /r /t 0
)
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================================
:: RESTORE DEFAULTS - SEQUENTIAL (v1.11 BASED)
:: ============================================================================
:RestoreDefaults
cls
echo %red%[!] RESTORING DEFAULTS%reset%
set /p confirm="Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" goto menu
echo.
echo [*] Restoring...
echo ================================================================================
echo [ 1/12] Power Plan...
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
echo [ 2/12] Background UWP Apps...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /f >nul 2>&1
echo [ 3/12] Delivery Optimization...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /f >nul 2>&1
sc config DoSvc start=manual >nul 2>&1
echo [ 4/12] Edge Startup Boost...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /f >nul 2>&1
echo [ 5/12] Telemetry ^& Ads...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /f >nul 2>&1
echo [ 6/12] Windows Copilot...
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /f >nul 2>&1
echo [ 7/12] User Account Control...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "1" /f >nul
echo [ 8/12] Mouse Acceleration...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul
echo [ 9/12] Sticky Keys...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "510" /f >nul
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "126" /f >nul
echo [10/12] Menu Delay...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "400" /f >nul
echo [11/12] Wallpaper Compression...
reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "80" /f >nul
echo [12/12] Recommendations...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /f >nul 2>&1
echo [13/13] Reset Taskbar and Start Menu...
call :RestartExplorerGracefully

echo.
echo ================================================================================
echo %green%     DEFAULTS RESTORED!%reset%
echo ================================================================================
echo.
echo %yellow%  System restart recommended.%reset%
set /p reboot="Restart now? (Y/N): "
if /i "%reboot%"=="Y" (
    echo [*] Restarting in 5 seconds...
    timeout /t 5 /nobreak >nul
    shutdown /r /t 0
)
timeout /t 2 /nobreak >nul
goto menu

:end
cls
echo.
echo %blue%System Tweaker %VERSION%%reset%
echo.
echo Thank you for using.
echo Log: %LOG_FILE%
timeout /t 2 /nobreak >nul
exit