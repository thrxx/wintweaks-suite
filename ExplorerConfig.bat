@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Explorer Config v2.6.0

:: ============================================================================
:: v2.6.0: INTERACTIVE SYSTEM RESTART & RECYCLE BIN FIX
:: - Fixed: Status not updating after ApplyAll/Restore.
::   Solution: Removed internal Explorer restart logic which was causing race
::   conditions. Implemented interactive system restart prompt (Y/N). If the
::   user chooses N, the script reads the registry directly to update the menu
::   status, ensuring immediate feedback without killing the script context.
:: - Fixed: Recycle Bin not returning on [D] Restore.
::   Solution: Separated logic for Navigation vs Desktop. Explicitly sets
::   System.IsPinnedToNameSpaceTree=1 (for Navigation) and HideDesktopIcons=0
::   (for Desktop) to guarantee visibility.
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
:: WINDOW SIZE & OS DETECTION
:: ============================================================================
mode con cols=100 lines=35 >nul 2>&1
powershell -NoProfile -Command "[Console]::WindowWidth=100; [Console]::WindowHeight=35; [Console]::BufferWidth=100; [Console]::BufferHeight=35" >nul 2>&1

for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul') do set "BUILD=%%v"
if %BUILD% GEQ 22000 (
    set "OS_TYPE=win11"
    set "OS_NAME=Windows 11"
) else (
    set "OS_TYPE=win10"
    set "OS_NAME=Windows 10"
)

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
set "LOG_FILE=%LOG_DIR%\explorer_config.log"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul

set "EXEC_MODE=MANUAL"

echo [%date% %time%] [%EXEC_MODE%] Explorer Config v2.6.0 Started >> "%LOG_FILE%"

call :CheckExplorerStatus
goto menu

:: ============================================================================
:: MAIN MENU
:: ============================================================================
:menu
cls
echo.
echo %blue%EXPLORER CONFIG v2.6.0%reset%
echo ================================================================================
echo.
echo %yellow%  %OS_NAME% (Build %BUILD%)%reset%
echo %yellow%  Restarting system is required for some changes.%reset%
echo.
echo %white%[1]%reset%  Open Explorer to              : %open_color%%open_status%%reset%
echo %white%[2]%reset%  "Home" Button                 : %home_color%%home_status%%reset%  %red%[Win11]%reset%
echo %white%[3]%reset%  "Gallery" Button              : %gallery_color%%gallery_status%%reset%  %red%[Win11]%reset%
echo %white%[4]%reset%  "Network" Button              : %network_color%%network_status%%reset%
echo %white%[5]%reset%  Recycle Bin in Navigation     : %navbin_color%%navbin_status%%reset%
echo %white%[6]%reset%  Recycle Bin on Desktop        : %desktopbin_color%%desktopbin_status%%reset%
echo %white%[7]%reset%  Compact View                  : %compact_color%%compact_status%%reset%  %red%[Win11]%reset%
echo %white%[8]%reset%  Recent Folders (Recent)       : %recent_color%%recent_status%%reset%
echo %white%[9]%reset%  Context Menu                  : %context_color%%context_status%%reset%  %red%[Win11]%reset%
echo.
echo --------------------------------------------------------------------------------
echo %yellow%[R]%reset%  %yellow%Restart Explorer%reset%
echo.
echo %green%[A]%reset%  %green%Apply All Settings%reset%
echo %red%[D]%reset%  %red%Restore Defaults%reset%
echo %white%[0]%reset%  %white%Exit%reset%
echo.
echo ================================================================================
echo.
set /p choice="%white%Enter option number: %reset%"

if "%choice%"=="1" call :SetExplorerOpen
if "%choice%"=="2" call :ToggleHomeButton
if "%choice%"=="3" call :ToggleGalleryButton
if "%choice%"=="4" call :ToggleNetworkButton
if "%choice%"=="5" call :ToggleNavBin
if "%choice%"=="6" call :ToggleDesktopBin
if "%choice%"=="7" call :ToggleCompactView
if "%choice%"=="8" call :ToggleRecentFolders
if "%choice%"=="9" call :ToggleContextMenu
if /i "%choice%"=="R" call :RestartExplorer
if /i "%choice%"=="A" call :ApplyAllExplorer
if /i "%choice%"=="D" call :RestoreExplorerDefaults
if "%choice%"=="0" goto end

call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:: ============================================================================
:: STATUS CHECK
:: ============================================================================
:CheckExplorerStatus
:: 1. Open Explorer (LaunchTo: 1=PC, 2=QuickAccess)
set "open_color=" & set "open_status="
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" 2>nul | find "0x1" >nul
if %errorlevel% equ 0 (set "open_color=%green%" & set "open_status=This PC") else (set "open_color=%red%" & set "open_status=Home/Quick Access")

:: 2. Home Button (Win11)
set "home_color=" & set "home_status="
if "%OS_TYPE%"=="win11" (
    reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" 2>nul | find "0x1" >nul
    if %errorlevel% equ 0 (set "home_color=%green%" & set "home_status=Hidden") else (set "home_color=%red%" & set "home_status=Visible")
) else (
    set "home_color=%yellow%" & set "home_status=N/A"
)

:: 3. Gallery Button (Win11)
set "gallery_color=" & set "gallery_status="
if "%OS_TYPE%"=="win11" (
    reg query "HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v "System.IsPinnedToNameSpaceTree" 2>nul | find "0x0" >nul
    if %errorlevel% equ 0 (set "gallery_color=%green%" & set "gallery_status=Hidden") else (set "gallery_color=%red%" & set "gallery_status=Visible")
) else (
    set "gallery_color=%yellow%" & set "gallery_status=N/A"
)

:: 4. Network Button
set "network_color=" & set "network_status="
reg query "HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "network_color=%green%" & set "network_status=Hidden") else (set "network_color=%red%" & set "network_status=Visible")

:: 5. Recycle Bin in Navigation
set "navbin_color=" & set "navbin_status="
reg query "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" 2>nul | find "0x1" >nul
if %errorlevel% equ 0 (set "navbin_color=%green%" & set "navbin_status=Enabled") else (set "navbin_color=%red%" & set "navbin_status=Disabled")

:: 6. Recycle Bin on Desktop
set "desktopbin_color=" & set "desktopbin_status="
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" 2>nul | find "0x1" >nul
if %errorlevel% equ 0 (set "desktopbin_color=%green%" & set "desktopbin_status=Hidden") else (set "desktopbin_color=%red%" & set "desktopbin_status=Visible")

:: 7. Compact View (Win11)
set "compact_color=" & set "compact_status="
if "%OS_TYPE%"=="win11" (
    reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" 2>nul | find "0x1" >nul
    if %errorlevel% equ 0 (set "compact_color=%green%" & set "compact_status=Enabled") else (set "compact_color=%red%" & set "compact_status=Disabled")
) else (
    set "compact_color=%yellow%" & set "compact_status=N/A"
)

:: 8. Recent Folders
set "recent_color=" & set "recent_status="
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "recent_color=%green%" & set "recent_status=Disabled") else (set "recent_color=%red%" & set "recent_status=Enabled")

:: 9. Context Menu (Win11 Classic)
set "context_color=" & set "context_status="
if "%OS_TYPE%"=="win11" (
    reg query "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" 2>nul | find /i "(Default)" >nul
    if %errorlevel% equ 0 (set "context_color=%green%" & set "context_status=Classic") else (set "context_color=%red%" & set "context_status=Modern")
) else (
    set "context_color=%yellow%" & set "context_status=N/A"
)
goto :eof

:: ============================================================================
:: SAFE EXPLORER RESTART
:: ============================================================================
:RestartExplorer
echo.
echo %yellow%[*] RESTARTING EXPLORER...%reset%
echo ================================================================================
echo [*] Stopping Explorer...
taskkill /IM explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
echo [*] Starting Explorer...
start explorer.exe
timeout /t 1 /nobreak >nul
echo.
echo ================================================================================
echo %green%     EXPLORER RESTARTED%reset%
echo ================================================================================
echo [%date% %time%] [%EXEC_MODE%] Explorer Restarted >> "%LOG_FILE%"
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================================
:: APPLY FUNCTIONS
:: ============================================================================
:SetExplorerOpen
echo.
echo [*] Setting Explorer to "This PC"...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d "1" /f >nul
echo [+] Done!
echo [%date% %time%] [%EXEC_MODE%] Set LaunchTo=1 >> "%LOG_FILE%"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleHomeButton
if "%OS_TYPE%"=="win10" goto Unsupported
echo [*] Toggling "Home" Button...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /t REG_DWORD /d "1" /f >nul
echo [+] Home Button Hidden!
echo [%date% %time%] [%EXEC_MODE%] Hidden Home Button >> "%LOG_FILE%"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleGalleryButton
if "%OS_TYPE%"=="win10" goto Unsupported
echo [*] Toggling "Gallery" Button...
reg add "HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul
echo [+] Gallery Button Hidden!
echo [%date% %time%] [%EXEC_MODE%] Hidden Gallery Button >> "%LOG_FILE%"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleNetworkButton
echo [*] Toggling "Network" Button...
reg add "HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul
echo [+] Network Button Hidden!
echo [%date% %time%] [%EXEC_MODE%] Hidden Network Button >> "%LOG_FILE%"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleNavBin
echo [*] Enabling Recycle Bin in Navigation...
reg add "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "1" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d "0" /f >nul
echo [+] Recycle Bin Added to Navigation!
echo [%date% %time%] [%EXEC_MODE%] Enabled NavBin >> "%LOG_FILE%"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleDesktopBin
echo [*] Toggling Recycle Bin on Desktop...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d "1" /f >nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{645FF040-5081-101B-9F08-00AA002F954E}" /f >nul 2>&1
echo [+] Recycle Bin Hidden from Desktop!
echo [%date% %time%] [%EXEC_MODE%] Hid DesktopBin >> "%LOG_FILE%"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleCompactView
if "%OS_TYPE%"=="win10" goto Unsupported
echo [*] Enabling Compact View...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /t REG_DWORD /d "1" /f >nul
echo [+] Compact View Enabled!
echo [%date% %time%] [%EXEC_MODE%] Enabled CompactView >> "%LOG_FILE%"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleRecentFolders
echo [*] Disabling Recent Folders...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d "0" /f >nul
if "%OS_TYPE%"=="win10" (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f >nul
)
echo [+] Recent Folders Disabled!
echo [%date% %time%] [%EXEC_MODE%] Disabled Recent >> "%LOG_FILE%"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleContextMenu
if "%OS_TYPE%"=="win10" goto Unsupported
echo [*] Switching to Classic Context Menu...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul
echo [+] Context Menu Changed to Classic!
echo [%date% %time%] [%EXEC_MODE%] Enabled Classic Context >> "%LOG_FILE%"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:Unsupported
echo.
echo [!] This feature is only available in Windows 11.
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================================
:: APPLY ALL - v2.6.0: INTERACTIVE SYSTEM RESTART
:: ============================================================================
:ApplyAllExplorer
cls
echo %green%[*] APPLYING ALL EXPLORER SETTINGS...%reset%
echo ================================================================================
set "EXEC_MODE=APPLY_ALL"
echo [%date% %time%] [%EXEC_MODE%] Batch execution started >> "%LOG_FILE%"

echo [ 1/9] Open to "This PC"...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d "1" /f >nul 2>&1

echo [ 2/9] Hide "Home" Button...
if "%OS_TYPE%"=="win11" reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /t REG_DWORD /d "1" /f >nul 2>&1

echo [ 3/9] Hide "Gallery" Button...
if "%OS_TYPE%"=="win11" reg add "HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1

echo [ 4/9] Hide "Network" Button...
reg add "HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1

echo [ 5/9] Enable Recycle Bin in Navigation...
reg add "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d "0" /f >nul 2>&1

echo [ 6/9] Hide Recycle Bin from Desktop...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d "1" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{645FF040-5081-101B-9F08-00AA002F954E}" /f >nul 2>&1

echo [ 7/9] Enable Compact View...
if "%OS_TYPE%"=="win11" reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /t REG_DWORD /d "1" /f >nul 2>&1

echo [ 8/9] Disable Recent Folders...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d "0" /f >nul 2>&1
if "%OS_TYPE%"=="win10" reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f >nul 2>&1

echo [ 9/9] Classic Context Menu...
if "%OS_TYPE%"=="win11" reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1

echo.
echo ================================================================================
echo %green%     ALL SETTINGS APPLIED!%reset%
echo ================================================================================
echo.
echo %yellow%  For changes to take effect, a restart is required.%reset%
echo.
set /p restart_system="Restart system now? (Y/N): "
if /i "%restart_system%"=="Y" (
    echo [*] Restarting in 5 seconds...
    timeout /t 5 /nobreak >nul
    shutdown /r /t 0
)
call :CheckExplorerStatus
echo [%date% %time%] [%EXEC_MODE%] Batch execution completed >> "%LOG_FILE%"
set "EXEC_MODE=MANUAL"
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================================
:: RESTORE DEFAULTS - v2.6.0: FIX RECYCLE BIN & INTERACTIVE RESTART
:: ============================================================================
:RestoreExplorerDefaults
cls
echo %red%[!] RESTORING EXPLORER DEFAULTS%reset%
set /p confirm="Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" goto menu
echo.
echo [*] Restoring defaults...
echo ================================================================================
set "EXEC_MODE=RESTORE_DEFAULTS"
echo [%date% %time%] [%EXEC_MODE%] Restoration started >> "%LOG_FILE%"

echo [ 1/9] Open to Home/Quick Access...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /f >nul 2>&1

echo [ 2/9] Show "Home" Button...
if "%OS_TYPE%"=="win11" reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f >nul 2>&1

echo [ 3/9] Show "Gallery" Button...
if "%OS_TYPE%"=="win11" reg delete "HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v "System.IsPinnedToNameSpaceTree" /f >nul 2>&1

echo [ 4/9] Show "Network" Button...
reg delete "HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" /f >nul 2>&1

echo [ 5/9] Restore Recycle Bin in Navigation...
:: Fix: Ensure pinned status is 1
reg add "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "1" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /f >nul 2>&1

echo [ 6/9] Restore Recycle Bin on Desktop...
:: Fix: Ensure visible by setting HideDesktopIcons=0
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d "0" /f >nul 2>&1

echo [ 7/9] Disable Compact View...
if "%OS_TYPE%"=="win11" reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /f >nul 2>&1

echo [ 8/9] Enable Recent Folders...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /f >nul 2>&1
if "%OS_TYPE%"=="win10" (
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /f >nul 2>&1
)

echo [ 9/9] Restore Modern Context Menu...
if "%OS_TYPE%"=="win11" reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1

echo.
echo ================================================================================
echo %green%     DEFAULTS RESTORED!%reset%
echo ================================================================================
echo.
echo %yellow%  For changes to take effect, a restart is required.%reset%
echo.
set /p restart_system="Restart system now? (Y/N): "
if /i "%restart_system%"=="Y" (
    echo [*] Restarting in 5 seconds...
    timeout /t 5 /nobreak >nul
    shutdown /r /t 0
)
call :CheckExplorerStatus
echo [%date% %time%] [%EXEC_MODE%] Restoration completed >> "%LOG_FILE%"
set "EXEC_MODE=MANUAL"
timeout /t 2 /nobreak >nul
goto menu

:end
cls
echo.
echo %blue%Explorer Config v2.6.0%reset%
echo.
echo Thank you for using.
echo Log: %LOG_FILE%
timeout /t 2 /nobreak >nul
exit