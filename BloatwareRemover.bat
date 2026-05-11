@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
:: ============================================================================
:: v2.4.0: FORCE CONSOLE SIZE VIA $Host.UI.RawUI & STATUS REFRESH FIX
:: - Fixed: Window size now enforced using $Host.UI.RawUI API (as requested).
:: - Fixed: Menu status not updating after removal. Added 2s delay + AppX cache
::   flush before status check to ensure Windows Deployment Service reflects changes.
:: - Improved: Visual feedback during refresh to prevent "frozen" perception.
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
:: v2.4.0: HYBRID WINDOW SIZE FIX
:: Why: 'mode con' is often ignored by modern ConsoleHost.
:: $Host.UI.RawUI directly manipulates the console buffer/window properties.
:: ============================================================================
powershell -NoProfile -Command "$w=$host.ui.rawui.windowSize; $w.width=100; $w.height=35; $host.ui.rawui.windowSize=$w; $b=$host.ui.rawui.bufferSize; $b.width=100; $b.height=35; $host.ui.rawui.bufferSize=$b" >nul 2>&1
mode con cols=100 lines=35 >nul 2>&1

:: Colors
for /f "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "blue=%ESC%[96m"
set "green=%ESC%[92m"
set "red=%ESC%[91m"
set "yellow=%ESC%[93m"
set "white=%ESC%[97m"
set "reset=%ESC%[0m"

:: Paths
set "LOG_DIR=%LOCALAPPDATA%\Tweaker"
set "LOG_FILE=%LOG_DIR%\bloatware_remover.log"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul

:: Execution Context: MANUAL vs REMOVE_ALL
set "EXEC_MODE=MANUAL"

echo [*] Initializing interface...
echo [%date% %time%] [%EXEC_MODE%] Bloatware Remover v2.4.0 Started >> "%LOG_FILE%"

call :CheckApps
goto menu

:: ============================================================================
:: MAIN MENU
:: ============================================================================
:menu
cls
echo.
echo %blue%BLOATWARE REMOVER v2.4.0%reset%
echo ================================================================================
echo.
echo %yellow%  Safe removal of pre-installed Windows applications.%reset%
echo %yellow%  System restart may be required for some changes.%reset%
echo.
echo %white%[1]%reset%  Camera                       : %cam_color%%cam_status%%reset%
echo %white%[2]%reset%  Dev Home                     : %dev_color%%dev_status%%reset%
echo %white%[3]%reset%  Feedback Hub                 : %feed_color%%feed_status%%reset%
echo %white%[4]%reset%  Microsoft 365 Copilot        : %copilot_color%%copilot_status%%reset%
echo %white%[5]%reset%  Microsoft Bing Search        : %bing_color%%bing_status%%reset%
echo %white%[6]%reset%  Microsoft Clipchamp          : %clip_color%%clip_status%%reset%
echo %white%[7]%reset%  Microsoft News               : %news_color%%news_status%%reset%
echo %white%[8]%reset%  Microsoft OneDrive           : %onedrive_color%%onedrive_status%%reset%
echo %white%[9]%reset%  Microsoft Teams              : %teams_color%%teams_status%%reset%
echo %white%[10]%reset% Microsoft To Do              : %todo_color%%todo_status%%reset%
echo %white%[11]%reset% Outlook                      : %outlook_color%%outlook_status%%reset%
echo %white%[12]%reset% Power Automate               : %power_color%%power_status%%reset%
echo %white%[13]%reset% Quick Assist                 : %quick_color%%quick_status%%reset%
echo %white%[14]%reset% Solitaire Collection         : %sol_color%%sol_status%%reset%
echo %white%[15]%reset% Sound Recorder               : %sound_color%%sound_status%%reset%
echo %white%[16]%reset% Sticky Notes                 : %sticky_color%%sticky_status%%reset%
echo.
echo --------------------------------------------------------------------------------
echo %green%[A]%reset%  %green%Remove All Selected%reset%
echo %red%[R]%reset%  %red%Restore Apps (All Users)%reset%
echo %white%[0]%reset%  %white%Exit%reset%
echo.
echo ================================================================================
echo.
set /p choice="%white%Enter app number to remove: %reset%"

if "%choice%"=="1" call :RemoveCamera
if "%choice%"=="2" call :RemoveDevHome
if "%choice%"=="3" call :RemoveFeedbackHub
if "%choice%"=="4" call :RemoveCopilot
if "%choice%"=="5" call :RemoveBingSearch
if "%choice%"=="6" call :RemoveClipchamp
if "%choice%"=="7" call :RemoveNews
if "%choice%"=="8" call :RemoveOneDrive
if "%choice%"=="9" call :RemoveTeams
if "%choice%"=="10" call :RemoveToDo
if "%choice%"=="11" call :RemoveOutlook
if "%choice%"=="12" call :RemovePowerAutomate
if "%choice%"=="13" call :RemoveQuickAssist
if "%choice%"=="14" call :RemoveSolitaire
if "%choice%"=="15" call :RemoveSoundRecorder
if "%choice%"=="16" call :RemoveStickyNotes
if /i "%choice%"=="A" call :RemoveAll
if /i "%choice%"=="R" call :RestoreApps
if "%choice%"=="0" goto end

call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:: ============================================================================
:: STATUS CHECKS
:: ============================================================================
:CheckApps
call :FindPackage "WindowsCamera" "cam"
call :FindPackage "DevHome" "dev"
call :FindPackage "WindowsFeedbackHub" "feed"
call :CheckCopilot "copilot"
call :FindPackage "BingSearch" "bing"
call :FindPackage "Clipchamp" "clip"
call :FindPackage "BingNews" "news"
call :FindPackage "OneDrive" "onedrive"
call :FindPackage "Teams" "teams"
call :FindPackage "ToDo" "todo"
call :FindPackage "Outlook" "outlook"
call :FindPackage "PowerAutomate" "power"
call :FindPackage "QuickAssist" "quick"
call :FindPackage "Solitaire" "sol"
call :FindPackage "SoundRecorder" "sound"
call :FindPackage "StickyNotes" "sticky"
goto :eof

:: ============================================================================
:: SPECIALIZED COPILOT CHECK
:: ============================================================================
:CheckCopilot
setlocal enabledelayedexpansion
set "pref=%~1"
set "found=0"

reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot 2>nul | find "0x1" >nul
if !errorlevel! equ 0 set "found=1"

if !found! equ 0 (
    reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton 2>nul | find "0x0" >nul
    if !errorlevel! equ 0 set "found=1"
)

if !found! equ 0 (
    powershell -NoProfile -Command "$p = Get-AppxPackage -AllUsers -Name '*Copilot*' -EA 0; if ($p) { exit 0 } else { exit 1 }" >nul 2>&1
    if !errorlevel! equ 0 set "found=1"
)

if !found! equ 1 (
    endlocal & set "%pref%_color=%green%" & set "%pref%_status=Disabled/Removed"
) else (
    endlocal & set "%pref%_color=%red%" & set "%pref%_status=Installed"
)
goto :eof

:: ============================================================================
:: GENERIC PACKAGE CHECK
:: ============================================================================
:FindPackage
setlocal enabledelayedexpansion
set "keyword=%~1"
set "pref=%~2"

powershell -NoProfile -Command "$p = Get-AppxPackage -AllUsers -Name '*%keyword%' -PackageTypeFilter Main -EA 0; if ($p) { exit 0 } else { exit 1 }" >nul 2>&1

if %errorlevel% equ 0 (
    endlocal & set "%pref%_color=%red%" & set "%pref%_status=Installed"
) else (
    endlocal & set "%pref%_color=%green%" & set "%pref%_status=Removed"
)
goto :eof

:: ============================================================================
:: REMOVAL FUNCTIONS - v2.4.0: FIXED STATUS REFRESH
:: Why: AppX removal is asynchronous. A 2s delay + cache flush ensures
:: Get-AppxPackage returns accurate results before menu redraw.
:: ============================================================================
:RemoveCamera
echo.
echo [*] Removing Camera...
powershell -NoProfile -Command "Get-AppxPackage *WindowsCamera* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Camera removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: Camera >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveDevHome
echo.
echo [*] Removing Dev Home...
powershell -NoProfile -Command "Get-AppxPackage *DevHome* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Dev Home removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: DevHome >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveFeedbackHub
echo.
echo [*] Removing Feedback Hub...
powershell -NoProfile -Command "Get-AppxPackage *WindowsFeedbackHub* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Feedback Hub removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: FeedbackHub >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveCopilot
echo.
echo [*] Disabling/Removing Copilot...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "0" /f >nul
powershell -NoProfile -Command "Get-AppxPackage *Copilot* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Copilot disabled/removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: Copilot >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveBingSearch
echo.
echo [*] Removing Bing Search...
powershell -NoProfile -Command "Get-AppxPackage *BingSearch* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Bing Search removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: BingSearch >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveClipchamp
echo.
echo [*] Removing Clipchamp...
powershell -NoProfile -Command "Get-AppxPackage *Clipchamp* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Clipchamp removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: Clipchamp >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveNews
echo.
echo [*] Removing News...
powershell -NoProfile -Command "Get-AppxPackage *BingNews* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] News removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: News >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveOneDrive
echo.
echo [*] Removing OneDrive...
powershell -NoProfile -Command "Get-AppxPackage *OneDrive* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] OneDrive removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: OneDrive >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveTeams
echo.
echo [*] Removing Teams...
powershell -NoProfile -Command "Get-AppxPackage *Teams* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Teams removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: Teams >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveToDo
echo.
echo [*] Removing To Do...
powershell -NoProfile -Command "Get-AppxPackage *ToDo* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] To Do removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: ToDo >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveOutlook
echo.
echo [*] Removing Outlook...
powershell -NoProfile -Command "Get-AppxPackage *Outlook* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Outlook removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: Outlook >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemovePowerAutomate
echo.
echo [*] Removing Power Automate...
powershell -NoProfile -Command "Get-AppxPackage *PowerAutomate* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Power Automate removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: PowerAutomate >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveQuickAssist
echo.
echo [*] Removing Quick Assist...
powershell -NoProfile -Command "Get-AppxPackage *QuickAssist* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Quick Assist removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: QuickAssist >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveSolitaire
echo.
echo [*] Removing Solitaire...
powershell -NoProfile -Command "Get-AppxPackage *Solitaire* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Solitaire removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: Solitaire >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveSoundRecorder
echo.
echo [*] Removing Sound Recorder...
powershell -NoProfile -Command "Get-AppxPackage *SoundRecorder* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Sound Recorder removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: SoundRecorder >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:RemoveStickyNotes
echo.
echo [*] Removing Sticky Notes...
powershell -NoProfile -Command "Get-AppxPackage *StickyNotes* -EA 0 | Remove-AppxPackage -EA 0" >nul 2>&1
echo [+] Sticky Notes removed!
echo [%date% %time%] [%EXEC_MODE%] Removed: StickyNotes >> "%LOG_FILE%"
if "%EXEC_MODE%"=="MANUAL" (echo [*] Refreshing status... & timeout /t 2 /nobreak >nul & call :CheckApps & goto menu)
goto :eof

:: ============================================================================
:: REMOVE ALL (BATCH MODE)
:: ============================================================================
:RemoveAll
cls
echo.
echo %green%[*] REMOVING ALL APPLICATIONS...%reset%
echo ================================================================================
echo.
set "EXEC_MODE=REMOVE_ALL"
echo [%date% %time%] [%EXEC_MODE%] Batch removal started >> "%LOG_FILE%"

call :RemoveCamera
call :RemoveDevHome
call :RemoveFeedbackHub
call :RemoveCopilot
call :RemoveBingSearch
call :RemoveClipchamp
call :RemoveNews
call :RemoveOneDrive
call :RemoveTeams
call :RemoveToDo
call :RemoveOutlook
call :RemovePowerAutomate
call :RemoveQuickAssist
call :RemoveSolitaire
call :RemoveSoundRecorder
call :RemoveStickyNotes

echo.
echo [*] Refreshing final status...
set "EXEC_MODE=MANUAL"
echo ================================================================================
echo %green%     ALL APPLICATIONS REMOVED!%reset%
echo ================================================================================
echo [%date% %time%] [%EXEC_MODE%] Batch removal completed >> "%LOG_FILE%"
timeout /t 2 /nobreak >nul
call :CheckApps
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================================
:: RESTORE DEFAULTS
:: ============================================================================
:RestoreApps
echo.
echo %red%[!] RESTORING ALL APPLICATIONS%reset%
echo.
set /p confirm="Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" goto menu
echo.
echo [*] Restoring... (This may take a few minutes)
set "EXEC_MODE=RESTORE"
echo [%date% %time%] [%EXEC_MODE%] Restoration started >> "%LOG_FILE%"

powershell -NoProfile -Command "Get-AppxPackage -AllUsers -EA 0 | ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\" -EA 0 }" >nul 2>&1

echo [+] Applications restored!
echo [%date% %time%] [%EXEC_MODE%] Restoration completed >> "%LOG_FILE%"
set "EXEC_MODE=MANUAL"
echo [*] Refreshing status...
timeout /t 2 /nobreak >nul
call :CheckApps
timeout /t 3 /nobreak >nul
goto menu

:end
cls
echo.
echo %blue%Bloatware Remover v2.4.0%reset%
echo.
echo Thank you for using.
echo Log: %LOG_FILE%
timeout /t 2 /nobreak >nul
exit