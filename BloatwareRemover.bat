@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: === АВТОЗАПРОС ПРАВ АДМИНИСТРАТОРА ===
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [!] Требуются права администратора.
    echo     Запуск от имени администратора...
    echo.
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs" >nul 2>&1
    exit /b
)
:: ========================================

title Bloatware Remover v1.15

:: Настройка цветов (VT100)
for /f "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "blue=%ESC%[96m"
set "green=%ESC%[92m"
set "red=%ESC%[91m"
set "yellow=%ESC%[93m"
set "white=%ESC%[97m"
set "reset=%ESC%[0m"

call :CheckApps

:menu
cls
echo.
echo %blue%BLOATWARE REMOVER v1.15%reset%
echo ================================================================================
echo.
echo %white%[1]%reset%  Камера (Camera)              : %cam_color%%cam_status%%reset%
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
echo %green%[A]%reset%  %green%Удалить все отмеченные%reset%
echo %red%[R]%reset%  %red%Восстановить приложения%reset%
echo %white%[0]%reset%  %white%Выход%reset%
echo.
echo ================================================================================
echo.
set /p choice="%white%Введите номер приложения для удаления: %reset%"

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

goto menu

:: ============================================================================
:: ПРОВЕРКА ПРИЛОЖЕНИЙ (СПЕЦИАЛЬНО ДЛЯ COPILOT)
:: ============================================================================
:CheckApps
:: 1. Camera
call :FindPackage "WindowsCamera" "cam"
:: 2. Dev Home
call :FindPackage "DevHome" "dev"
:: 3. Feedback Hub
call :FindPackage "WindowsFeedbackHub" "feed"
:: 4. Copilot - СПЕЦИАЛЬНАЯ ПРОВЕРКА
call :CheckCopilot "copilot"
:: 5. Bing Search
call :FindPackage "BingSearch" "bing"
:: 6. Clipchamp
call :FindPackage "Clipchamp" "clip"
:: 7. News
call :FindPackage "BingNews" "news"
:: 8. OneDrive
call :FindPackage "OneDrive" "onedrive"
:: 9. Teams
call :FindPackage "Teams" "teams"
:: 10. To Do
call :FindPackage "ToDo" "todo"
:: 11. Outlook
call :FindPackage "Outlook" "outlook"
:: 12. Power Automate
call :FindPackage "PowerAutomate" "power"
:: 13. Quick Assist
call :FindPackage "QuickAssist" "quick"
:: 14. Solitaire
call :FindPackage "Solitaire" "sol"
:: 15. Sound Recorder
call :FindPackage "SoundRecorder" "sound"
:: 16. Sticky Notes
call :FindPackage "StickyNotes" "sticky"

goto :eof

:: ============================================================================
:: СПЕЦИАЛЬНАЯ ПРОВЕРКА COPILOT (системная функция Windows)
:: ============================================================================
:CheckCopilot
setlocal enabledelayedexpansion
set "pref=%~1"
set "found=0"

:: Способ 1: Проверяем наличие кнопки Copilot в реестре
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" 2>nul | find "0x1" >nul
if !errorlevel! equ 0 set "found=1"

:: Способ 2: Проверяем включен ли Copilot в системе
if !found! equ 0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Ai.Copilot" /v "CopilotEnabled" 2>nul >nul
    if !errorlevel! equ 0 set "found=1"
)

:: Способ 3: Проверяем наличие процесса Copilot
if !found! equ 0 (
    tasklist /FI "IMAGENAME eq explorer.exe" 2>nul | find "explorer.exe" >nul
    if !errorlevel! equ 0 (
        :: Copilot интегрирован в Explorer, проверяем наличие DLL
        if exist "%windir%\System32\Windows.AI.MachineLearning*" set "found=1"
    )
)

:: Способ 4: Проверяем через PowerShell наличие команды Copilot
if !found! equ 0 (
    powershell -Command "Get-Command *Copilot* -CommandType Application -ErrorAction SilentlyContinue" 2>nul | findstr /i "copilot" >nul
    if !errorlevel! equ 0 set "found=1"
)

:: Способ 5: Проверяем наличие папок Copilot
if !found! equ 0 (
    if exist "%windir%\SystemApps\Microsoft.Windows.Ai.Copilot*" set "found=1"
    dir "%ProgramFiles%\WindowsApps\*Copilot*" /b 2>nul | findstr /i "copilot" >nul
    if !errorlevel! equ 0 set "found=1"
)

:: Результат
if !found! equ 1 (
    endlocal & set "%pref%_color=%red%" & set "%pref%_status=Установлена"
) else (
    endlocal & set "%pref%_color=%green%" & set "%pref%_status=Удалена"
)
goto :eof

:: ============================================================================
:: ОБЫЧНЫЙ ПОИСК ПАКЕТА (для остальных приложений)
:: ============================================================================
:FindPackage
setlocal enabledelayedexpansion
set "keyword=%~1"
set "pref=%~2"

powershell -NoProfile -Command ^
    "$pkgs = Get-AppxPackage -AllUsers -EA 0; " ^
    "$found = $pkgs | Where-Object { $_.PackageFullName -like '*%keyword%*' -or $_.Name -like '*%keyword%*' }; " ^
    "if ($found) { exit 0 } else { exit 1 }" >nul 2>&1

if %errorlevel% equ 0 (
    endlocal & set "%pref%_color=%red%" & set "%pref%_status=Установлена"
) else (
    endlocal & set "%pref%_color=%green%" & set "%pref%_status=Удалена"
)
goto :eof

:: ============================================================================
:: ФУНКЦИИ УДАЛЕНИЯ (ТЕПЕРЬ ТОЖЕ ИСПОЛЬЗУЮТ ГИБКИЙ ПОИСК)
:: ============================================================================
:RemoveCamera
echo.
echo [*] Удаление Камеры...
powershell -Command "Get-AppxPackage *WindowsCamera* | Remove-AppxPackage" >nul 2>&1
echo [+] Камера удалена!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveDevHome
echo.
echo [*] Удаление Dev Home...
powershell -Command "Get-AppxPackage *DevHome* | Remove-AppxPackage" >nul 2>&1
echo [+] Dev Home удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveFeedbackHub
echo.
echo [*] Удаление Feedback Hub...
powershell -Command "Get-AppxPackage *WindowsFeedbackHub* | Remove-AppxPackage" >nul 2>&1
echo [+] Feedback Hub удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveCopilot
echo.
echo [*] Удаление Copilot...
powershell -Command "Get-AppxPackage *Copilot* | Remove-AppxPackage" >nul 2>&1
echo [+] Copilot удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveBingSearch
echo.
echo [*] Удаление Bing Search...
powershell -Command "Get-AppxPackage *BingSearch* | Remove-AppxPackage" >nul 2>&1
echo [+] Bing Search удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveClipchamp
echo.
echo [*] Удаление Clipchamp...
powershell -Command "Get-AppxPackage *Clipchamp* | Remove-AppxPackage" >nul 2>&1
echo [+] Clipchamp удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveNews
echo.
echo [*] Удаление News...
powershell -Command "Get-AppxPackage *BingNews* | Remove-AppxPackage" >nul 2>&1
echo [+] News удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveOneDrive
echo.
echo [*] Удаление OneDrive...
powershell -Command "Get-AppxPackage *OneDrive* | Remove-AppxPackage" >nul 2>&1
echo [+] OneDrive удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveTeams
echo.
echo [*] Удаление Teams...
powershell -Command "Get-AppxPackage *Teams* | Remove-AppxPackage" >nul 2>&1
echo [+] Teams удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveToDo
echo.
echo [*] Удаление To Do...
powershell -Command "Get-AppxPackage *ToDo* | Remove-AppxPackage" >nul 2>&1
echo [+] To Do удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveOutlook
echo.
echo [*] Удаление Outlook...
powershell -Command "Get-AppxPackage *Outlook* | Remove-AppxPackage" >nul 2>&1
echo [+] Outlook удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemovePowerAutomate
echo.
echo [*] Удаление Power Automate...
powershell -Command "Get-AppxPackage *PowerAutomate* | Remove-AppxPackage" >nul 2>&1
echo [+] Power Automate удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveQuickAssist
echo.
echo [*] Удаление Quick Assist...
powershell -Command "Get-AppxPackage *QuickAssist* | Remove-AppxPackage" >nul 2>&1
echo [+] Quick Assist удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveSolitaire
echo.
echo [*] Удаление Solitaire...
powershell -Command "Get-AppxPackage *Solitaire* | Remove-AppxPackage" >nul 2>&1
echo [+] Solitaire удалена!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveSoundRecorder
echo.
echo [*] Удаление Sound Recorder...
powershell -Command "Get-AppxPackage *SoundRecorder* | Remove-AppxPackage" >nul 2>&1
echo [+] Sound Recorder удален!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveStickyNotes
echo.
echo [*] Удаление Sticky Notes...
powershell -Command "Get-AppxPackage *StickyNotes* | Remove-AppxPackage" >nul 2>&1
echo [+] Sticky Notes удалены!
call :CheckApps
timeout /t 1 /nobreak >nul
goto menu

:RemoveAll
echo.
echo [*] Удаление всех приложений...
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
echo ================================================================================
echo     ВСЕ ПРИЛОЖЕНИЯ УДАЛЕНЫ!
echo ================================================================================
call :CheckApps
timeout /t 2 /nobreak >nul
goto menu

:RestoreApps
echo.
echo [!] ВОССТАНОВЛЕНИЕ ВСЕХ ПРИЛОЖЕНИЙ
echo.
set /p confirm="Вы уверены? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

echo.
echo [*] Восстановление...
powershell -Command "Get-AppxPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\"}" >nul 2>&1
echo [+] Приложения восстановлены!
call :CheckApps
timeout /t 3 /nobreak >nul
goto menu

:end
cls
echo.
echo %blue%Bloatware Remover v1.15%reset%
echo.
echo Спасибо за использование.
echo.
timeout /t 2 /nobreak >nul
exit

:: ============================================================================
:: ВОССТАНОВЛЕНИЕ
:: ============================================================================
:RestoreApps
echo.
echo [!] ВОССТАНОВЛЕНИЕ ВСЕХ ПРИЛОЖЕНИЙ
echo.
set /p confirm="Вы уверены? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

echo.
echo [*] Восстановление...
powershell -Command "Get-AppxPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\"}" >nul 2>&1
echo [+] Приложения восстановлены!
call :CheckApps
timeout /t 3 /nobreak >nul
goto menu

:end
cls
echo.
echo %blue%Bloatware Remover v1.15%reset%
echo.
echo Спасибо за использование.
echo.
timeout /t 2 /nobreak >nul
exit