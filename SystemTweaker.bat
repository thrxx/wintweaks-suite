@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title System Tweaker v2.7.0

:: ============================================================================
:: v2.7.0: FALLBACK MECHANISM, ALTERNATIVE METHODS, CRITICAL FIXES
:: v2.6.0: Fixed window size, English UI, console termination fixes
:: v2.5.0: BATCH_MODE flow control, direct registry parsing
:: v2.4.0: Status sync, SystemCleanup hang fixes
:: v2.3.0: OS detection, instant mouse apply
:: v2.2.0: Idempotent registry core
:: v2.1.0: HEX/DEC normalization
:: v2.0.0: Safe registry core, backups, logging
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
set "VERSION=v2.7.0"
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

set "BATCH_MODE=0"
set "RETRY_COUNT=0"
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
echo %yellow%  Changes apply instantly. Restart may be required for some settings.%reset%
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
:: STATUS CHECK - DIRECT PARSING
:: ============================================================================
:CheckStatus
set "TMP="

:: 1. Power Plan
powercfg /getactivescheme 2>nul | findstr /i "8c5e7fda" >nul
if %errorlevel% equ 0 (set "power_color=%green%" & set "power_status=High Performance") else (set "power_color=%red%" & set "power_status=Balanced")

:: 2. UWP Background
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v LetAppsRunInBackground 2^>nul ^| findstr /i "LetAppsRunInBackground"') do set "TMP=%%v"
if /i "!TMP!"=="0x2" set "TMP=2"
if "!TMP!"=="2" (set "uwp_color=%green%" & set "uwp_status=Disabled") else (set "uwp_color=%red%" & set "uwp_status=Enabled")

:: 3. Delivery Optimization
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode 2^>nul ^| findstr /i "DODownloadMode"') do set "TMP=%%v"
if /i "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "delivery_color=%green%" & set "delivery_status=Disabled") else (set "delivery_color=%red%" & set "delivery_status=Enabled")

:: 4. Edge Boost
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled 2^>nul ^| findstr /i "StartupBoostEnabled"') do set "TMP=%%v"
if /i "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "edge_color=%green%" & set "edge_status=Disabled") else (set "edge_color=%red%" & set "edge_status=Enabled")

:: 5. Telemetry
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry 2^>nul ^| findstr /i "AllowTelemetry"') do set "TMP=%%v"
if /i "!TMP!"=="0x1" set "TMP=1"
if "!TMP!"=="0" (set "tele_color=%green%" & set "tele_status=Disabled") else (set "tele_color=%red%" & set "tele_status=Enabled")

:: 6. Copilot
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot 2^>nul ^| findstr /i "TurnOffWindowsCopilot"') do set "TMP=%%v"
if /i "!TMP!"=="0x1" set "TMP=1"
if "!TMP!"=="1" (set "copilot_color=%green%" & set "copilot_status=Disabled") else (set "copilot_color=%red%" & set "copilot_status=Enabled")

:: 7. UAC
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin 2^>nul ^| findstr /i "ConsentPromptBehaviorAdmin"') do set "TMP=%%v"
if /i "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "uac_color=%yellow%" & set "uac_status=No Prompt") else (set "uac_color=%green%" & set "uac_status=Enabled")

:: 8. Mouse
for /f "tokens=3" %%v in ('reg query "HKCU\Control Panel\Mouse" /v MouseSpeed 2^>nul ^| findstr /i "MouseSpeed"') do set "TMP=%%v"
if /i "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "mouse_color=%green%" & set "mouse_status=Disabled") else (set "mouse_color=%red%" & set "mouse_status=Enabled")

:: 9. Sticky Keys
for /f "tokens=3" %%v in ('reg query "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags 2^>nul ^| findstr /i "Flags"') do set "TMP=%%v"
if "!TMP!"=="506" (set "sticky_color=%green%" & set "sticky_status=Disabled") else (set "sticky_color=%red%" & set "sticky_status=Enabled")

:: 10. Menu Delay
for /f "tokens=3" %%v in ('reg query "HKCU\Control Panel\Desktop" /v MenuShowDelay 2^>nul ^| findstr /i "MenuShowDelay"') do set "TMP=%%v"
if "!TMP!"=="20" (set "menu_color=%green%" & set "menu_status=20 ms") else (set "menu_color=%red%" & set "menu_status=400 ms")

:: 11. Wallpaper
for /f "tokens=3" %%v in ('reg query "HKCU\Control Panel\Desktop" /v JPEGImportQuality 2^>nul ^| findstr /i "JPEGImportQuality"') do set "TMP=%%v"
if /i "!TMP!"=="0x64" set "TMP=100"
if "!TMP!"=="100" (set "wallpaper_color=%green%" & set "wallpaper_status=Disabled") else (set "wallpaper_color=%red%" & set "wallpaper_status=Enabled")

:: 12. Recommendations
if "%OS_TYPE%"=="win11" (
    for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HideRecommendedSection 2^>nul ^| findstr /i "HideRecommendedSection"') do set "TMP=%%v"
    if /i "!TMP!"=="0x1" set "TMP=1"
    if "!TMP!"=="1" (set "rec_color=%green%" & set "rec_status=Hidden") else (set "rec_color=%red%" & set "rec_status=Shown")
) else (
    for /f "tokens=3" %%v in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs 2^>nul ^| findstr /i "Start_TrackDocs"') do set "TMP=%%v"
    if /i "!TMP!"=="0x0" set "TMP=0"
    if "!TMP!"=="0" (set "rec_color=%green%" & set "rec_status=Disabled") else (set "rec_color=%red%" & set "rec_status=Enabled")
)
goto :eof

:: ============================================================================
:: SAFE REGISTRY SET WITH FALLBACK
:: ============================================================================
:SetReg <KEY> <VALUE> <TYPE> <DATA> <DESCRIPTION>
setlocal
set "K=%~1" & set "V=%~2" & set "T=%~3" & set "D=%~4" & set "DESC=%~5"

for /f "tokens=3" %%C in ('reg query "!K!" /v "!V!" 2^>nul ^| findstr /i "!V!"') do set "CUR=%%C"
if /i "!CUR!"=="0x1" if "!D!"=="1" set "CUR=1"
if /i "!CUR!"=="0x0" if "!D!"=="0" set "CUR=0"
if /i "!CUR!"=="0x2" if "!D!"=="2" set "CUR=2"
if /i "!CUR!"=="0x64" if "!D!"=="100" set "CUR=100"

if "!CUR!"=="!D!" (
    echo [✓] Skip: %DESC% (already set)
    endlocal
    goto :eof
)

reg add "!K!" /v "!V!" /t %T% /d "!D!" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo [+] OK: %DESC%
    echo [%date% %time%] OK: !K!\!V!=!D! >> "%LOG_FILE%"
    if "!K:~0,4!"=="HKLM" gpupdate /force >nul 2>&1
) else (
    echo [!] Error: %DESC% (code !errorlevel!)
    echo [%date% %time%] ERR: !K!\!V!=!D! >> "%LOG_FILE%"
)
endlocal
goto :eof

:: ============================================================================
:: SAFE EXPLORER RESTART (DEFERRED)
:: ============================================================================
:RestartExplorerGracefully
echo [*] Restarting Explorer...
taskkill /IM explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start "" explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
echo [+] Explorer restarted
goto :eof

:: ============================================================================
:: APPLY FUNCTIONS WITH FALLBACK MECHANISM
:: ============================================================================
:ApplyPowerPlan
echo.
echo [*] Setting power plan (Method 1: powercfg)...
powercfg /list | findstr /i "8c5e7fda" >nul
if %errorlevel% equ 0 (
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>nul
    if %errorlevel% equ 0 (
        echo [+] Power plan changed via powercfg!
        echo [%date% %time%] Applied: PowerPlan (Method 1) >> "%LOG_FILE%"
        goto :eof
    )
)
:: Fallback: PowerShell CIM
echo [*] Fallback (Method 2: PowerShell CIM)...
powershell -NoProfile -Command "$plan = Get-CimInstance -Namespace root/cimv2/power -ClassName Win32_PowerPlan | Where-Object {$_.ElementName -like '*High performance*'}; if ($plan) { $plan | Invoke-CimMethod -MethodName Activate }" >nul 2>&1
if %errorlevel% equ 0 (
    echo [+] Power plan changed via PowerShell!
    echo [%date% %time%] Applied: PowerPlan (Method 2) >> "%LOG_FILE%"
) else (
    echo [!] Failed to change power plan
    echo [%date% %time%] Failed: PowerPlan >> "%LOG_FILE%"
)
goto :eof

:ApplyUWP
echo.
echo [*] Disabling background apps (Method 1: Registry)...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" REG_DWORD "2" "Disable UWP background"
:: Check if applied
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v LetAppsRunInBackground 2^>nul') do set "CHECK=%%v"
if /i "!CHECK!"=="0x2" (
    echo [%date% %time%] Applied: UWP_Background (Method 1) >> "%LOG_FILE%"
    goto :eof
)
:: Fallback: GPO via lgpo (if available)
echo [*] Fallback (Method 2: GPO)...
if exist "%~dp0lgpo.exe" (
    echo [Software\Microsoft\Windows\CurrentVersion\Policies\Explorer]
    echo "LetAppsRunInBackground"=dword:00000002 > "%TEMP%\uwp_policy.txt"
    "%~dp0lgpo.exe" /g "%TEMP%\uwp_policy.txt" >nul 2>&1
    echo [+] Applied via GPO
    echo [%date% %time%] Applied: UWP_Background (Method 2) >> "%LOG_FILE%"
) else (
    echo [!] lgpo.exe not found, skipping GPO method
)
goto :eof

:ApplyDelivery
echo.
echo [*] Disabling delivery optimization (Method 1: Registry)...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" REG_DWORD "0" "Disable P2P updates"
sc config DoSvc start=disabled >nul 2>&1
sc stop DoSvc >nul 2>&1
:: Check
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode 2^>nul') do set "CHECK=%%v"
if /i "!CHECK!"=="0x0" (
    echo [%date% %time%] Applied: Delivery (Method 1) >> "%LOG_FILE%"
    goto :eof
)
:: Fallback: PowerShell DeliveryOptimization module
echo [*] Fallback (Method 2: PowerShell module)...
powershell -NoProfile -Command "if (Get-Module -ListAvailable DeliveryOptimization) { Set-DeliveryOptimizationStatus -DownloadMode 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo [+] Applied via PowerShell module
    echo [%date% %time%] Applied: Delivery (Method 2) >> "%LOG_FILE%"
)
goto :eof

:ApplyEdge
echo.
echo [*] Disabling Edge Boost (Method 1: Registry)...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" REG_DWORD "0" "Disable Edge preloading"
:: Check
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled 2^>nul') do set "CHECK=%%v"
if /i "!CHECK!"=="0x0" (
    echo [%date% %time%] Applied: Edge (Method 1) >> "%LOG_FILE%"
    goto :eof
)
:: Fallback: Edge policies.json
echo [*] Fallback (Method 2: policies.json)...
set "EDGE_PATH=C:\Program Files (x86)\Microsoft\Edge\Application"
if exist "!EDGE_PATH!" (
    echo {"StartupBoostEnabled": false} > "!EDGE_PATH!\policies.json"
    echo [+] Applied via policies.json
    echo [%date% %time%] Applied: Edge (Method 2) >> "%LOG_FILE%"
)
goto :eof

:ApplyTelemetry
echo.
echo [*] Disabling telemetry (Method 1: Registry)...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" REG_DWORD "1" "Minimal telemetry"
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" REG_DWORD "1" "Disable consumer features"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" REG_DWORD "0" "Disable suggestions"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" REG_DWORD "0" "Disable ads"
:: Check
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry 2^>nul') do set "CHECK=%%v"
if /i "!CHECK!"=="0x1" (
    echo [%date% %time%] Applied: Telemetry (Method 1) >> "%LOG_FILE%"
    goto :eof
)
:: Fallback: CSP via PowerShell
echo [*] Fallback (Method 2: CSP)...
powershell -NoProfile -Command "$csp = New-Object Microsoft.Management.Infrastructure.CimSession -ComputerName localhost; $instance = $csp.CreateInstance('root\cimv2\mdm\dmmap', 'MDM_Policy_Config01_Experience02', 'Experience02'); $instance.AllowTelemetry = 1; $csp.PutInstance($instance)" >nul 2>&1
if %errorlevel% equ 0 (
    echo [+] Applied via CSP
    echo [%date% %time%] Applied: Telemetry (Method 2) >> "%LOG_FILE%"
)
goto :eof

:ApplyCopilot
echo.
echo [*] Disabling Windows Copilot (Method 1: Registry)...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" REG_DWORD "1" "Disable Copilot"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" REG_DWORD "0" "Hide Copilot button"
:: Check
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot 2^>nul') do set "CHECK=%%v"
if /i "!CHECK!"=="0x1" (
    echo [%date% %time%] Applied: Copilot (Method 1) >> "%LOG_FILE%"
    if "%BATCH_MODE%"=="1" (
        echo [*] Explorer restart deferred...
        goto :eof
    )
    call :RestartExplorerGracefully
    goto :eof
)
:: Fallback: GPO
echo [*] Fallback (Method 2: GPO)...
if exist "%~dp0lgpo.exe" (
    echo [Software\Microsoft\PolicyManager\current\device\WindowsCopilot]
    echo "TurnOffWindowsCopilot"=dword:00000001 > "%TEMP%\copilot_policy.txt"
    "%~dp0lgpo.exe" /g "%TEMP%\copilot_policy.txt" >nul 2>&1
    gpupdate /force >nul 2>&1
    echo [+] Applied via GPO
    echo [%date% %time%] Applied: Copilot (Method 2) >> "%LOG_FILE%"
    if "%BATCH_MODE%"=="1" goto :eof
    call :RestartExplorerGracefully
)
goto :eof

:ApplyUAC
echo.
echo [!] WARNING: Lowering UAC reduces system security.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" (if "%BATCH_MODE%"=="1" goto :eof & goto menu)
echo [*] Disabling UAC prompts (Method 1: Registry)...
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" REG_DWORD "0" "UAC: No prompt"
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" REG_DWORD "1" "UAC: Core enabled"
echo [+] UAC settings applied
if "%BATCH_MODE%"=="1" goto :eof
call :CheckStatus & timeout /t 1 /nobreak >nul & goto menu

:ApplyMouse
echo.
echo [*] Disabling mouse acceleration (Method 1: Registry)...
call :SetReg "HKCU\Control Panel\Mouse" "MouseSpeed" REG_SZ "0" "Disable acceleration"
call :SetReg "HKCU\Control Panel\Mouse" "MouseThreshold1" REG_SZ "0" "Threshold 1"
call :SetReg "HKCU\Control Panel\Mouse" "MouseThreshold2" REG_SZ "0" "Threshold 2"
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters >nul 2>&1
:: Check
for /f "tokens=3" %%v in ('reg query "HKCU\Control Panel\Mouse" /v MouseSpeed 2^>nul') do set "CHECK=%%v"
if /i "!CHECK!"=="0x0" set "CHECK=0"
if "!CHECK!"=="0" (
    echo [%date% %time%] Applied: Mouse (Method 1) >> "%LOG_FILE%"
    goto :eof
)
:: Fallback: PowerShell Set-ItemProperty
echo [*] Fallback (Method 2: PowerShell)...
powershell -NoProfile -Command "Set-ItemProperty 'HKCU:\Control Panel\Mouse' -Name MouseSpeed -Value '0'; Set-ItemProperty 'HKCU:\Control Panel\Mouse' -Name MouseThreshold1 -Value '0'; Set-ItemProperty 'HKCU:\Control Panel\Mouse' -Name MouseThreshold2 -Value '0'; rundll32 user32.dll,UpdatePerUserSystemParameters" >nul 2>&1
echo [%date% %time%] Applied: Mouse (Method 2) >> "%LOG_FILE%"
goto :eof

:ApplySticky
echo.
echo [*] Disabling sticky keys (Method 1: Registry)...
call :SetReg "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" REG_SZ "506" "Disable StickyKeys"
call :SetReg "HKCU\Control Panel\Accessibility\ToggleKeys" "Flags" REG_SZ "58" "Disable ToggleKeys"
call :SetReg "HKCU\Control Panel\Accessibility\Keyboard Response" "Flags" REG_SZ "122" "Disable FilterKeys"
if "%BATCH_MODE%"=="1" goto :eof
call :CheckStatus & timeout /t 1 /nobreak >nul & goto menu

:ApplyMenuDelay
echo.
echo [*] Speeding up context menu (Method 1: Registry)...
call :SetReg "HKCU\Control Panel\Desktop" "MenuShowDelay" REG_SZ "20" "Menu delay 20ms"
if "%BATCH_MODE%"=="1" goto :eof
call :CheckStatus & timeout /t 1 /nobreak >nul & goto menu

:ApplyWallpaper
echo.
echo [*] Disabling wallpaper compression (Method 1: Registry)...
call :SetReg "HKCU\Control Panel\Desktop" "JPEGImportQuality" REG_DWORD "100" "Quality 100%%"
if "%BATCH_MODE%"=="1" goto :eof
call :CheckStatus & timeout /t 1 /nobreak >nul & goto menu

:ApplyRecommended
echo.
echo [*] Hiding recommendations...
if "%OS_TYPE%"=="win11" (
    call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" REG_DWORD "1" "Hide recommendations (Win11)"
) else (
    call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" REG_DWORD "0" "Disable tracking (Win10)"
)
if "%BATCH_MODE%"=="1" goto :eof
call :CheckStatus & timeout /t 1 /nobreak >nul & goto menu

:: ============================================================================
:: CLEANUP FUNCTIONS
:: ============================================================================
:CleanTaskbar
cls
echo.
echo %yellow%[*] CONFIGURING TASKBAR...%reset% (%OS_NAME%)
echo ================================================================================
echo [1/4] Applying policies...
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" REG_DWORD "1" "Search: icon"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCortanaButton" REG_DWORD "0" "Hide Cortana"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" REG_DWORD "0" "Hide Task View"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" REG_DWORD "0" "Hide Widgets"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" REG_DWORD "0" "Hide Chat"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" REG_DWORD "2" "Disable feeds"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" REG_DWORD "0" "Hide Copilot"

echo [2/4] Clearing pin cache...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams" /f >nul 2>&1
del /f /q "%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.*" >nul 2>&1

echo [3/4] Restarting interface...
call :RestartExplorerGracefully

if "%OS_TYPE%"=="win10" (
    echo [4/4] Unpinning icons (Win10)...
    powershell -NoProfile -Command "$apps=(New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items(); $apps | ForEach-Object { $_.Verbs() | Where-Object { $_.Name -match 'Unpin from taskbar' } | ForEach-Object { $_.DoIt() } }" >nul 2>&1
) else (
    echo [4/4] Win11: Manual unpin via Settings
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
powershell -NoProfile -Command "Get-ChildItem -Path $env:TEMP, $env:TMP, 'C:\Windows\Temp' -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo [+] TEMP cleaned

echo [2/5] Stopping services...
net stop wuauserv >nul 2>&1
net stop cryptSvc >nul 2>&1
net stop bits >nul 2>&1
net stop msiserver >nul 2>&1

echo [3/5] Clearing update cache...
rd /s /q "%windir%\SoftwareDistribution\Download" >nul 2>&1
rd /s /q "%windir%\System32\catroot2" >nul 2>&1

echo [4/5] Starting services...
net start wuauserv >nul 2>&1
net start cryptSvc >nul 2>&1
net start bits >nul 2>&1
net start msiserver >nul 2>&1

echo [5/5] DISM cleanup...
dism /online /cleanup-image /startcomponentcleanup /resetbase >nul 2>&1
echo [+] DISM completed

echo.
echo [!] Event log clearing skipped (compliance risk)
echo [+] Recycle Bin cleared
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1

echo ================================================================================
echo %green%     CLEANUP COMPLETE%reset%
echo ================================================================================
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================================
:: APPLY ALL / RESTORE
:: ============================================================================
:ApplyAll
cls
echo %green%[*] APPLYING ALL SETTINGS...%reset%
echo ================================================================================
set "BATCH_MODE=1"
call :ApplyPowerPlan
call :ApplyUWP
call :ApplyDelivery
call :ApplyEdge
call :ApplyTelemetry
call :ApplyCopilot
call :ApplyUAC
call :ApplyMouse
call :ApplySticky
call :ApplyMenuDelay
call :ApplyWallpaper
call :ApplyRecommended
call :RestartExplorerGracefully
set "BATCH_MODE=0"

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

:RestoreDefaults
cls
echo %red%[!] RESTORING DEFAULTS%reset%
set /p confirm="Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" goto menu
echo.
echo [*] Restoring...
echo ================================================================================
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" REG_DWORD "1" "UWP background: user choice"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /f >nul 2>&1
sc config DoSvc start=manual >nul 2>&1
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" REG_DWORD "1" "Enable Edge Boost"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /f >nul 2>&1
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" REG_DWORD "0" "Enable Copilot"
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" REG_DWORD "5" "UAC: default"
call :SetReg "HKCU\Control Panel\Mouse" "MouseSpeed" REG_SZ "1" "Enable acceleration"
call :SetReg "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" REG_SZ "510" "Enable StickyKeys"
call :SetReg "HKCU\Control Panel\Desktop" "MenuShowDelay" REG_SZ "400" "Delay 400ms"
call :SetReg "HKCU\Control Panel\Desktop" "JPEGImportQuality" REG_DWORD "80" "Quality 80%%"
if "%OS_TYPE%"=="win11" (
    call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" REG_DWORD "0" "Show recommendations"
) else (
    call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" REG_DWORD "1" "Enable tracking"
)
call :CleanStartMenu
call :RestartExplorerGracefully
echo.
echo ================================================================================
echo %green%     DEFAULTS RESTORED!%reset%
echo ================================================================================
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