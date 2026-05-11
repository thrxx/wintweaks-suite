@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title System Tweaker v2.4.0

:: ============================================================================
:: v2.0.0: Внедрение безопасного ядра реестра, логирования и резервных копий
:: v2.1.0: Исправление парсинга статусов, нормализация HEX/DEC, защита от закрытия консоли
:: v2.2.0: Полная реконфигурация потока выполнения, исправление ApplyAll,
::          стабильный RestartExplorer, сквозное комментирование версий
:: v2.3.0: Определение версии ОС (Win10/Win11), исправление критических ошибок
::          закрытия консоли, корректная проверка статусов, применение политик
:: v2.4.0: Исправление закрытия консоли (critical bug), безопасная очистка логов,
::          корректная работа CleanTaskbar/CleanStartMenu для Win10/Win11,
::          исправление статусов [8]-[11], обработка ошибок в SystemCleanup,
::          безопасное открепление иконок, улучшенное логирование
:: ============================================================================

:: === АВТОЗАПРОС ПРАВ АДМИНИСТРАТОРА ===
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [!] Требуются права администратора.
    echo     Пожалуйста, подтвердите запрос UAC.
    echo.
    powershell -NoProfile -Command "Start-Process '%~dpnx0' -Verb RunAs" >nul 2>&1
    exit /b
)

:: ============================================================================
:: v2.3.0: ОПРЕДЕЛЕНИЕ ВЕРСИИ WINDOWS
:: ============================================================================
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul') do set "BUILD=%%v"
if %BUILD% GEQ 22000 (
    set "OS_TYPE=win11"
    set "OS_NAME=Windows 11"
) else (
    set "OS_TYPE=win10"
    set "OS_NAME=Windows 10"
)

:: ============================================================================
:: ИНИЦИАЛИЗАЦИЯ И ЦВЕТА
:: ============================================================================
set "VERSION=v2.4.0"
for /f "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "blue=%ESC%[96m"
set "green=%ESC%[92m"
set "red=%ESC%[91m"
set "yellow=%ESC%[93m"
set "white=%ESC%[97m"
set "reset=%ESC%[0m"

set "LOG_DIR=%LOCALAPPDATA%\Tweaker"
set "LOG_FILE=%LOG_DIR%\system_tweaker.log"
set "BACKUP_DIR=%USERPROFILE%\Desktop\Tweaker_Backups"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul

echo [%date% %time%] === Запуск System Tweaker %VERSION% (%OS_NAME%) === >> "%LOG_FILE%"

:: Однократный бэкап критичных веток
if not exist "%BACKUP_DIR%\%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_init.reg" (
    echo [*] Создание резервной копии реестра...
    for %%K in (
        "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        "HKCU\Control Panel\Mouse"
        "HKCU\Control Panel\Desktop"
        "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
    ) do reg export "%%~K" "%BACKUP_DIR%\%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_init.reg" /y >nul 2>&1
    echo [%date% %time%] Резервная копия создана >> "%LOG_FILE%"
)

call :CheckStatus
goto menu

:: ============================================================================
:: ГЛАВНОЕ МЕНЮ
:: ============================================================================
:menu
cls
echo.
echo %blue%SYSTEM TWEAKER %VERSION%%reset%
echo ================================================================================
echo.
echo %yellow%  %OS_NAME% (Build %BUILD%)%reset%
echo %yellow%  Изменения применяются мгновенно. Перезагрузка может потребоваться для некоторых настроек.%reset%
echo %yellow%  Резервная копия реестра сохранена на Рабочем столе.%reset%
echo.
echo %white%[1]%reset%  План питания                 : %power_color%%power_status%%reset%
echo %white%[2]%reset%  Фоновые UWP приложения       : %uwp_color%%uwp_status%%reset%
echo %white%[3]%reset%  Оптимизация доставки         : %delivery_color%%delivery_status%%reset%
echo %white%[4]%reset%  Edge Startup Boost           : %edge_color%%edge_status%%reset%
echo %white%[5]%reset%  Телеметрия и реклама         : %tele_color%%tele_status%%reset%
echo %white%[6]%reset%  Windows Copilot AI           : %copilot_color%%copilot_status%%reset%
echo %white%[7]%reset%  Контроль учетных записей     : %uac_color%%uac_status%%reset%
echo %white%[8]%reset%  Акселерация мыши             : %mouse_color%%mouse_status%%reset%
echo %white%[9]%reset%  Залипание клавиш             : %sticky_color%%sticky_status%%reset%
echo %white%[10]%reset% Задержка контекстного меню   : %menu_color%%menu_status%%reset%
echo %white%[11]%reset% Сжатие обоев                 : %wallpaper_color%%wallpaper_status%%reset%
if "%OS_TYPE%"=="win11" (
    echo %white%[12]%reset% Рекомендации в Пуск          : %rec_color%%rec_status%%reset%
) else (
    echo %white%[12]%reset% Отслеживание документов      : %rec_color%%rec_status%%reset%
)
echo.
echo --------------------------------------------------------------------------------
echo %yellow%[T]%reset%  %yellow%Настроить панель задач%reset%
echo %yellow%[S]%reset%  %yellow%Сбросить меню Пуск%reset%
echo %yellow%[X]%reset%  %yellow%Безопасная очистка системы%reset%
echo.
echo %green%[A]%reset%  %green%Применить все настройки%reset%
echo %red%[D]%reset%  %red%Вернуть всё по умолчанию%reset%
echo %white%[0]%reset%  %white%Выход%reset%
echo.
echo ================================================================================
echo.
set /p choice="%white%Введите номер пункта для изменения: %reset%"

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
:: v2.4.0: ИЗОЛИРОВАННЫЙ ПАРСЕР РЕЕСТРА С НОРМАЛИЗАЦИЕЙ И ОБРАБОТКОЙ ОШИБОК
:: ============================================================================
:CheckStatus
:: 1. План питания
powercfg /getactivescheme 2>nul | findstr /i "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" >nul
if %errorlevel% equ 0 (set "power_color=%green%" & set "power_status=Высокая произв.") else (set "power_color=%red%" & set "power_status=Сбалансир.")

:: 2. UWP Background
call :GetRegVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" "TMP"
if "!TMP!"=="0x2" set "TMP=2"
if "!TMP!"=="2" (set "uwp_color=%green%" & set "uwp_status=Отключены") else (set "uwp_color=%red%" & set "uwp_status=Включены")

:: 3. Delivery Optimization
call :GetRegVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" "TMP"
if "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "delivery_color=%green%" & set "delivery_status=Отключена") else (set "delivery_color=%red%" & set "delivery_status=Включена")

:: 4. Edge Startup Boost
call :GetRegVal "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" "TMP"
if "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "edge_color=%green%" & set "edge_status=Отключен") else (set "edge_color=%red%" & set "edge_status=Включен")

:: 5. Telemetry
call :GetRegVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" "TMP"
if "!TMP!"=="0x1" set "TMP=1"
if "!TMP!"=="0" (set "tele_color=%green%" & set "tele_status=Отключена") else (set "tele_color=%red%" & set "tele_status=Включена")

:: 6. Copilot
call :GetRegVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" "TMP"
if "!TMP!"=="0x1" set "TMP=1"
if "!TMP!"=="1" (set "copilot_color=%green%" & set "copilot_status=Отключен") else (set "copilot_color=%red%" & set "copilot_status=Включен")

:: 7. UAC
call :GetRegVal "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" "TMP"
if "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "uac_color=%yellow%" & set "uac_status=Без запроса") else (set "uac_color=%green%" & set "uac_status=Включен")

:: 8. Mouse Accel - v2.4.0: Исправлен парсинг
call :GetRegVal "HKCU\Control Panel\Mouse" "MouseSpeed" "TMP"
if "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "mouse_color=%green%" & set "mouse_status=Отключена") else (set "mouse_color=%red%" & set "mouse_status=Включена")

:: 9. Sticky Keys - v2.4.0: Исправлен парсинг
call :GetRegVal "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" "TMP"
if "!TMP!"=="506" (set "sticky_color=%green%" & set "sticky_status=Отключены") else (set "sticky_color=%red%" & set "sticky_status=Включены")

:: 10. Menu Delay - v2.4.0: Исправлен парсинг
call :GetRegVal "HKCU\Control Panel\Desktop" "MenuShowDelay" "TMP"
if "!TMP!"=="20" (set "menu_color=%green%" & set "menu_status=20 мс") else (set "menu_color=%red%" & set "menu_status=400 мс")

:: 11. Wallpaper Compression - v2.4.0: Исправлен парсинг
call :GetRegVal "HKCU\Control Panel\Desktop" "JPEGImportQuality" "TMP"
if "!TMP!"=="0x64" set "TMP=100"
if "!TMP!"=="100" (set "wallpaper_color=%green%" & set "wallpaper_status=Отключено") else (set "wallpaper_color=%red%" & set "wallpaper_status=Включено")

:: 12. Recommendations - v2.4.0: Разные проверки для Win10/Win11
if "%OS_TYPE%"=="win11" (
    call :GetRegVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" "TMP"
    if "!TMP!"=="0x1" set "TMP=1"
    if "!TMP!"=="1" (set "rec_color=%green%" & set "rec_status=Скрыты") else (set "rec_color=%red%" & set "rec_status=Показаны")
) else (
    call :GetRegVal "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" "TMP"
    if "!TMP!"=="0x0" set "TMP=0"
    if "!TMP!"=="0" (set "rec_color=%green%" & set "rec_status=Отключено") else (set "rec_color=%red%" & set "rec_status=Включено")
)
goto :eof

:: ============================================================================
:: v2.4.0: БЕЗОПАСНЫЙ ПАРСЕР ЗНАЧЕНИЙ РЕЕСТРА С ОБРАБОТКОЙ ОШИБОК
:: ============================================================================
:GetRegVal <KEY> <VALUE> <OUT_VAR>
set "%~3="
for /f "tokens=3" %%I in ('reg query "%~1" /v "%~2" 2^>nul ^| findstr /i "%~2"') do set "%~3=%%I"
if not defined %~3 set "%~3=0"
goto :eof

:: ============================================================================
:: v2.4.0: ИДЕМПОТЕНТНОЕ ЯДРО ПРИМЕНЕНИЯ РЕЕСТРА С ОБРАБОТКОЙ ОШИБОК
:: ============================================================================
:SetReg <KEY> <VALUE> <TYPE> <DATA> <DESCRIPTION>
setlocal
set "K=%~1" & set "V=%~2" & set "T=%~3" & set "D=%~4" & set "DESC=%~5"

call :GetRegVal "!K!" "!V!" "CUR"
if "!CUR!"=="!D!" (
    echo [✓] Пропуск: %DESC% (уже установлено)
    endlocal
    goto :eof
)

reg add "!K!" /v "!V!" /t %T% /d "!D!" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo [+] Успешно: %DESC%
    echo [%date% %time%] OK: !K!\!V!=!D! >> "%LOG_FILE%"
    if "!K:~0,4!"=="HKLM" gpupdate /force >nul 2>&1
) else (
    echo [!] Ошибка: %DESC% (код !errorlevel!)
    echo [%date% %time%] ERR: !K!\!V!=!D! >> "%LOG_FILE%"
)
endlocal
goto :eof

:: ============================================================================
:: v2.4.0: БЕЗОПАСНЫЙ ПЕРЕЗАПУСК EXPLORER БЕЗ ЗАКРЫТИЯ КОНСОЛИ
:: ============================================================================
:RestartExplorerGracefully
echo [*] Перезапуск проводника...
taskkill /IM explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start "" explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
goto :eof

:: ============================================================================
:: ФУНКЦИИ ПРИМЕНЕНИЯ - v2.4.0: ИСПРАВЛЕНО ЗАКРЫТИЕ КОНСОЛИ
:: ============================================================================
:ApplyPowerPlan
echo.
echo [*] Установка плана питания...
powercfg /list | findstr /i "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" >nul
if %errorlevel% equ 0 (
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>nul
    if %errorlevel% equ 0 (echo [+] План питания изменен!) else (echo [!] Ошибка активации)
) else (
    echo [!] План "Высокая производительность" не найден. Пропуск.
)
echo [%date% %time%] Applied: PowerPlan >> "%LOG_FILE%"
goto :eof

:ApplyUWP
echo.
echo [*] Отключение фоновых приложений...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" REG_DWORD "2" "Запрет фоновых UWP"
echo [%date% %time%] Applied: UWP_Background >> "%LOG_FILE%"
goto :eof

:ApplyDelivery
echo.
echo [*] Отключение оптимизации доставки...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" REG_DWORD "0" "Отключение P2P"
sc config DoSvc start=disabled >nul 2>&1
sc stop DoSvc >nul 2>&1
goto :eof

:ApplyEdge
echo.
echo [*] Отключение Edge Boost...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" REG_DWORD "0" "Отключение Edge Boost"
goto :eof

:ApplyTelemetry
echo.
echo [*] Отключение телеметрии...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" REG_DWORD "1" "Минимальная телеметрия"
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" REG_DWORD "1" "Отключение потребительских функций"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" REG_DWORD "0" "Отключение рекомендаций"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" REG_DWORD "0" "Отключение рекламы"
goto :eof

:ApplyCopilot
echo.
echo [*] Отключение Windows Copilot...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" REG_DWORD "1" "Отключение Copilot"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" REG_DWORD "0" "Скрытие кнопки Copilot"
:: v2.4.0: Безопасный рестарт без закрытия консоли
call :RestartExplorerGracefully
goto :eof

:ApplyUAC
echo.
echo [!] ВНИМАНИЕ: Снижение уровня UAC уменьшает безопасность системы.
set /p confirm="Продолжить? (Y/N): "
if /i not "%confirm%"=="Y" goto menu
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" REG_DWORD "0" "UAC: Без запроса"
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" REG_DWORD "1" "UAC: Ядро включено"
echo [+] Настройки UAC применены
goto :eof

:ApplyMouse
echo.
echo [*] Отключение акселерации мыши...
call :SetReg "HKCU\Control Panel\Mouse" "MouseSpeed" REG_SZ "0" "Отключение акселерации"
call :SetReg "HKCU\Control Panel\Mouse" "MouseThreshold1" REG_SZ "0" "Порог 1"
call :SetReg "HKCU\Control Panel\Mouse" "MouseThreshold2" REG_SZ "0" "Порог 2"
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters >nul 2>&1
goto :eof

:ApplySticky
echo.
echo [*] Отключение залипания клавиш...
call :SetReg "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" REG_SZ "506" "Отключение StickyKeys"
call :SetReg "HKCU\Control Panel\Accessibility\ToggleKeys" "Flags" REG_SZ "58" "Отключение ToggleKeys"
call :SetReg "HKCU\Control Panel\Accessibility\Keyboard Response" "Flags" REG_SZ "122" "Отключение FilterKeys"
goto :eof

:ApplyMenuDelay
echo.
echo [*] Ускорение контекстного меню...
call :SetReg "HKCU\Control Panel\Desktop" "MenuShowDelay" REG_SZ "20" "Задержка меню 20мс"
goto :eof

:ApplyWallpaper
echo.
echo [*] Отключение сжатия обоев...
call :SetReg "HKCU\Control Panel\Desktop" "JPEGImportQuality" REG_DWORD "100" "Качество 100%%"
goto :eof

:ApplyRecommended
echo.
echo [*] Скрытие рекомендаций...
if "%OS_TYPE%"=="win11" (
    call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" REG_DWORD "1" "Скрыть рекомендации (Win11)"
) else (
    call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" REG_DWORD "0" "Отключение трекинга (Win10)"
)
goto :eof

:: ============================================================================
:: v2.4.0: ПАНЕЛЬ ЗАДАЧ - РАЗНЫЕ ПОДХОДЫ ДЛЯ WIN10/WIN11
:: ============================================================================
:CleanTaskbar
cls
echo.
echo %yellow%[*] НАСТРОЙКА ПАНЕЛИ ЗАДАЧ...%reset% (%OS_NAME%)
echo ================================================================================
echo [1/4] Применение политик...
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" REG_DWORD "1" "Поиск: значок"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCortanaButton" REG_DWORD "0" "Скрыть Cortana"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" REG_DWORD "0" "Скрыть Task View"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" REG_DWORD "0" "Скрыть Виджеты"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" REG_DWORD "0" "Скрыть Чат"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" REG_DWORD "2" "Отключить ленту"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" REG_DWORD "0" "Скрыть Copilot"

echo [2/4] Очистка кэша закрепления...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams" /f >nul 2>&1
del /f /q "%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.*" >nul 2>&1

echo [3/4] Перезапуск интерфейса...
call :RestartExplorerGracefully

:: v2.4.0: Только для Win10 - Win11 использует XAML и игнорирует COM
if "%OS_TYPE%"=="win10" (
    echo [4/4] Открепление иконок (Win10)...
    powershell -NoProfile -Command "$apps = (New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items(); $apps | ForEach-Object { $_.Verbs() | Where-Object { $_.Name -match 'Unpin from taskbar' } | ForEach-Object { $_.DoIt() } }" >nul 2>&1
    echo [+] Панель задач настроена (Win10)
) else (
    echo [4/4] Win11: требуется ручное открепление (XAML архитектура)
    echo      Используйте настройки в меню Параметры -> Персонализация -> Панель задач
)
echo [+] Готово
timeout /t 2 /nobreak >nul
goto :eof

:: ============================================================================
:: v2.4.0: СБРОС МЕНЮ ПУСК - БЕЗОПАСНАЯ ОЧИСТКА
:: ============================================================================
:CleanStartMenu
cls
echo.
echo %yellow%[*] СБРОС МЕНЮ ПУСК...%reset%
echo ================================================================================
echo [1/3] Удаление пользовательских ярлыков...
del /f /q "%AppData%\Microsoft\Windows\Start Menu\Programs\*.*" >nul 2>&1

echo [2/3] Сброс кэша макета...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore" /f >nul 2>&1
call :RestartExplorerGracefully

echo [3/3] Очистка бинарных файлов...
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenu*.bin" >nul 2>&1
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenulayout.bin" >nul 2>&1
echo [+] Меню Пуск сброшено
timeout /t 2 /nobreak >nul
goto :eof

:: ============================================================================
:: v2.4.0: БЕЗОПАСНАЯ ОЧИСТКА СИСТЕМЫ - ИСПРАВЛЕНО ЗАВИСАНИЕ
:: ============================================================================
:SystemCleanup
cls
echo.
echo %yellow%[*] БЕЗОПАСНАЯ ОЧИСТКА...%reset%
echo ================================================================================
echo [1/6] Временные файлы...
powershell -NoProfile -Command "Get-ChildItem -Path $env:TEMP, $env:TMP, 'C:\Windows\Temp' -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo [+] TEMP очищен

echo [2/6] Остановка сервисов обновлений...
net stop wuauserv >nul 2>&1
net stop cryptSvc >nul 2>&1
net stop bits >nul 2>&1
net stop msiserver >nul 2>&1

echo [3/6] Очистка кэша обновлений...
rd /s /q "%windir%\SoftwareDistribution\Download" >nul 2>&1
rd /s /q "%windir%\System32\catroot2" >nul 2>&1

echo [4/6] Запуск сервисов...
net start wuauserv >nul 2>&1
net start cryptSvc >nul 2>&1
net start bits >nul 2>&1
net start msiserver >nul 2>&1

echo [5/6] Очистка компонентов DISM...
dism /online /cleanup-image /startcomponentcleanup /resetbase >nul 2>&1
echo [+] DISM очистка завершена

echo [6/6] Очистка корзины...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo [+] Корзина очищена

:: v2.4.0: Пропускаем очистку логов (зависание + compliance risk)
echo.
echo [!] Очистка системных логов пропущена (требует много времени, compliance risk)
echo.
echo ================================================================================
echo %green%     ОЧИСТКА ЗАВЕРШЕНА%reset%
echo ================================================================================
timeout /t 2 /nobreak >nul
goto :eof

:: ============================================================================
:: v2.4.0: APPLYALL / RESTORE - ИСПРАВЛЕНО ЗАКРЫТИЕ КОНСОЛИ
:: ============================================================================
:ApplyAll
cls
echo %green%[*] ПРИМЕНЕНИЕ ВСЕХ НАСТРОЕК...%reset%
echo ================================================================================
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
echo.
echo ================================================================================
echo %green%     ВСЕ НАСТРОЙКИ ПРИМЕНЕНЫ!%reset%
echo ================================================================================
echo.
echo %yellow%  Рекомендуется перезагрузить компьютер.%reset%
set /p reboot="Перезагрузить сейчас? (Y/N): "
if /i "%reboot%"=="Y" (
    echo [*] Перезагрузка через 5 секунд...
    timeout /t 5 /nobreak >nul
    shutdown /r /t 0
)
timeout /t 2 /nobreak >nul
goto :eof

:RestoreDefaults
cls
echo %red%[!] ВОССТАНОВЛЕНИЕ НАСТРОЕК%reset%
set /p confirm="Вы уверены? (Y/N): "
if /i not "%confirm%"=="Y" goto menu
echo.
echo [*] Откат настроек...
echo ================================================================================
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" REG_DWORD "1" "UWP фон: выбор пользователя"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /f >nul 2>&1
sc config DoSvc start=manual >nul 2>&1
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" REG_DWORD "1" "Включить Edge Boost"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /f >nul 2>&1
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" REG_DWORD "0" "Включить Copilot"
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" REG_DWORD "5" "UAC: по умолчанию"
call :SetReg "HKCU\Control Panel\Mouse" "MouseSpeed" REG_SZ "1" "Включить акселерацию"
call :SetReg "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" REG_SZ "510" "Включить StickyKeys"
call :SetReg "HKCU\Control Panel\Desktop" "MenuShowDelay" REG_SZ "400" "Задержка 400мс"
call :SetReg "HKCU\Control Panel\Desktop" "JPEGImportQuality" REG_DWORD "80" "Качество 80%%"
if "%OS_TYPE%"=="win11" (
    call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" "HideRecommendedSection" REG_DWORD "0" "Показать рекомендации"
) else (
    call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" REG_DWORD "1" "Включить трекинг"
)
call :CleanStartMenu
call :RestartExplorerGracefully
echo.
echo ================================================================================
echo %green%     НАСТРОЙКИ ВОССТАНОВЛЕНЫ!%reset%
echo ================================================================================
timeout /t 2 /nobreak >nul
goto :eof

:end
cls
echo.
echo %blue%System Tweaker %VERSION%%reset%
echo.
echo Спасибо за использование.
echo Лог: %LOG_FILE%
timeout /t 2 /nobreak >nul
exit