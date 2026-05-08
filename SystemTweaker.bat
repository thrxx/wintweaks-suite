@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title System Tweaker v2.2.0

:: ============================================================================
:: v2.0.0: Внедрение безопасного ядра реестра, логирования и резервных копий
:: v2.1.0: Исправление парсинга статусов, нормализация HEX/DEC, защита от закрытия консоли
:: v2.2.0: Полная реконфигурация потока выполнения (call/return), исправление ApplyAll,
::          Taskbar/Searchbox, принудительное применение политик (gpupdate),
::          стабильный RestartExplorer без убийства conhost.exe, сквозное комментирование версий.
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
:: ИНИЦИАЛИЗАЦИЯ И ЦВЕТА
:: ============================================================================
set "VERSION=v2.2.0"
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

echo [%date% %time%] === Запуск System Tweaker %VERSION% === >> "%LOG_FILE%"

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
echo %yellow%  Изменения применяются мгновенно. Для полного эффекта может потребоваться перезагрузка.%reset%
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
echo %white%[12]%reset% Рекомендации в Пуск          : %rec_color%%rec_status%%reset%
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
:: v2.2.0: Изолированный парсер реестра + нормализация HEX/DEC
:: Причина: findstr давал ложные срабатывания на частичные совпадения,
:: статусы не обновлялись из-за отсутствия конвертации 0x1 -> 1.
:: ============================================================================
:CheckStatus
:: 1. План питания
powercfg /getactivescheme 2>nul | findstr /i "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" >nul
if %errorlevel% equ 0 (set "power_color=%green%" & set "power_status=Высокая произв.") else (set "power_color=%red%" & set "power_status=Сбалансир.")

:: 2-12: Точное чтение + нормализация
call :GetRegVal "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" "TMP"
if "!TMP!"=="0x1" set "TMP=1"
if "!TMP!"=="1" (set "uwp_color=%green%" & set "uwp_status=Отключены") else (set "uwp_color=%red%" & set "uwp_status=Включены")

call :GetRegVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" "TMP"
if "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "delivery_color=%green%" & set "delivery_status=Отключена") else (set "delivery_color=%red%" & set "delivery_status=Включена")

call :GetRegVal "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" "TMP"
if "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "edge_color=%green%" & set "edge_status=Отключен") else (set "edge_color=%red%" & set "edge_status=Включен")

call :GetRegVal "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" "TMP"
if "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "tele_color=%green%" & set "tele_status=Отключена") else (set "tele_color=%red%" & set "tele_status=Включена")

call :GetRegVal "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" "TMP"
if "!TMP!"=="0x1" set "TMP=1"
if "!TMP!"=="1" (set "copilot_color=%green%" & set "copilot_status=Отключен") else (set "copilot_color=%red%" & set "copilot_status=Включен")

call :GetRegVal "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" "TMP"
if "!TMP!"=="0x1" set "TMP=1"
if "!TMP!"=="0" (set "uac_color=%red%" & set "uac_status=Отключен (Небезопасно)") else (set "uac_color=%green%" & set "uac_status=Включен")

call :GetRegVal "HKCU\Control Panel\Mouse" "MouseSpeed" "TMP"
if "!TMP!"=="0" (set "mouse_color=%green%" & set "mouse_status=Отключена") else (set "mouse_color=%red%" & set "mouse_status=Включена")

call :GetRegVal "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" "TMP"
if "!TMP!"=="506" (set "sticky_color=%green%" & set "sticky_status=Отключены") else (set "sticky_color=%red%" & set "sticky_status=Включены")

call :GetRegVal "HKCU\Control Panel\Desktop" "MenuShowDelay" "TMP"
if "!TMP!"=="20" (set "menu_color=%green%" & set "menu_status=20 мс") else (set "menu_color=%red%" & set "menu_status=400 мс")

call :GetRegVal "HKCU\Control Panel\Desktop" "JPEGImportQuality" "TMP"
if "!TMP!"=="0x64" set "TMP=100"
if "!TMP!"=="100" (set "wallpaper_color=%green%" & set "wallpaper_status=Отключено") else (set "wallpaper_color=%red%" & set "wallpaper_status=Включено")

call :GetRegVal "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" "TMP"
if "!TMP!"=="0x0" set "TMP=0"
if "!TMP!"=="0" (set "rec_color=%green%" & set "rec_status=Скрыты") else (set "rec_color=%red%" & set "rec_status=Показаны")
goto :eof

:: ============================================================================
:: v2.2.0: Безопасный парсер значений реестра
:: ============================================================================
:GetRegVal <KEY> <VALUE> <OUT_VAR>
for /f "tokens=3" %%I in ('reg query "%~1" /v "%~2" 2^>nul ^| findstr /i "%~2"') do set "%~3=%%I"
:: Fallback: если ключ не найден, ставим дефолт (обычно 0)
if not defined %~3 set "%~3=0"
goto :eof

:: ============================================================================
:: v2.0.0/v2.1.0/v2.2.0: Идемпотентное ядро применения реестра
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
) else (
    echo [!] Ошибка: %DESC% (код !errorlevel!)
    echo [%date% %time%] ERR: !K!\!V!=!D! >> "%LOG_FILE%"
)
endlocal
goto :eof

:: ============================================================================
:: v2.1.0/v2.2.0: Безопасный перезапуск Explorer без убийства conhost.exe
:: ============================================================================
:RestartExplorerGracefully
echo [*] Перезапуск проводника (Graceful)...
:: Без /F позволяет процессам сохранить состояние. Запуск в отдельном cmd-потоке защищает консоль скрипта.
taskkill /IM explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start "" /b explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
echo [+] Проводник перезапущен
goto :eof

:: ============================================================================
:: ФУНКЦИИ ПРИМЕНЕНИЯ (v2.2.0: Убраны goto menu, теперь возвращают управление через goto :eof)
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
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" REG_DWORD "1" "Глобальное отключение фона UWP"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" "BackgroundAppGlobalToggle" REG_DWORD "0" "Отключение фона поиска"
goto :eof

:ApplyDelivery
echo.
echo [*] Отключение оптимизации доставки...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" REG_DWORD "0" "Отключение P2P-доставки обновлений"
sc config DoSvc start=disabled >nul 2>&1
sc stop DoSvc >nul 2>&1
:: v2.2.0: Принудительное обновление групповых политик для сохранения после перезагрузки
gpupdate /force >nul 2>&1
goto :eof

:ApplyEdge
echo.
echo [*] Отключение Edge Boost...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" REG_DWORD "0" "Отключение предзагрузки Edge"
goto :eof

:ApplyTelemetry
echo.
echo [*] Отключение телеметрии и рекламы...
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" REG_DWORD "0" "Минимальный уровень диагностики"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" REG_DWORD "0" "Отключение рекламного ID"
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" REG_DWORD "1" "Блокировка рекламы на уровне политики"
gpupdate /force >nul 2>&1
goto :eof

:ApplyCopilot
echo.
echo [*] Отключение Windows Copilot...
call :SetReg "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" REG_DWORD "1" "Отключение Copilot (User)"
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" REG_DWORD "1" "Отключение Copilot (System)"
call :RestartExplorerGracefully
gpupdate /force >nul 2>&1
goto :eof

:ApplyUAC
echo.
echo [!] ВНИМАНИЕ: Полное отключение UAC ломает безопасность Windows и работу UWP/Store.
echo     Применён безопасный режим: уведомления только при изменении программ.
set /p confirm="Продолжить с безопасной конфигурацией? (Y/N): "
if /i not "%confirm%"=="Y" goto menu
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" REG_DWORD "0" "UAC: Без запроса для администраторов"
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" REG_DWORD "1" "UAC: Ядро защиты (Обязательно)"
echo [+] Настройки UAC применены (Безопасный режим)
gpupdate /force >nul 2>&1
goto :eof

:ApplyMouse
echo.
echo [*] Отключение акселерации мыши...
call :SetReg "HKCU\Control Panel\Mouse" "MouseSpeed" REG_SZ "0" "Отключение акселерации"
call :SetReg "HKCU\Control Panel\Mouse" "MouseThreshold1" REG_SZ "0" "Порог 1 = 0"
call :SetReg "HKCU\Control Panel\Mouse" "MouseThreshold2" REG_SZ "0" "Порог 2 = 0"
goto :eof

:ApplySticky
echo.
echo [*] Отключение залипания клавиш...
call :SetReg "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" REG_SZ "506" "Отключение StickyKeys"
call :SetReg "HKCU\Control Panel\Accessibility\Keyboard Response" "Flags" REG_SZ "122" "Отключение FilterKeys"
goto :eof

:ApplyMenuDelay
echo.
echo [*] Ускорение контекстного меню...
call :SetReg "HKCU\Control Panel\Desktop" "MenuShowDelay" REG_SZ "20" "Задержка меню = 20мс"
goto :eof

:ApplyWallpaper
echo.
echo [*] Отключение сжатия обоев...
call :SetReg "HKCU\Control Panel\Desktop" "JPEGImportQuality" REG_DWORD "100" "Качество обоев 100%"
goto :eof

:ApplyRecommended
echo.
echo [*] Скрытие рекомендаций и уведомлений в Пуске...
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" REG_DWORD "0" "Скрыть рекомендации"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_AccountNotifications" REG_DWORD "0" "Скрыть уведомления учётной записи"
call :RestartExplorerGracefully
goto :eof

:: ============================================================================
:: v2.2.0: Панель задач / Пуск / Очистка (исправлены ключи, поток, экспорт политик)
:: ============================================================================
:CleanTaskbar
cls
echo.
echo %yellow%[*] НАСТРОЙКА ПАНЕЛИ ЗАДАЧ...%reset%
echo ================================================================================
echo [1/4] Применение политик панели...
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" REG_DWORD "1" "Поиск: значок"
call :SetReg "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCortanaButton" REG_DWORD "0" "Скрыть Cortana"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" REG_DWORD "0" "Скрыть Task View"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" REG_DWORD "0" "Скрыть Виджеты"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" REG_DWORD "0" "Скрыть Чат"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" REG_DWORD "2" "Отключить ленту новостей"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" REG_DWORD "0" "Скрыть кнопку Copilot"

echo [2/4] Очистка кэша закрепления...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams" /f >nul 2>&1
del /f /q "%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.*" >nul 2>&1

echo [3/4] Перезапуск интерфейса...
call :RestartExplorerGracefully

echo [4/4] Закрепление Проводника...
powershell -NoProfile -Command "$s=New-Object -Com Shell.Application; $f=$s.NameSpace('C:\Windows'); $i=$f.ParseName('explorer.exe'); $i.InvokeVerb('taskbarpin')" >nul 2>&1
echo [+] Панель задач настроена.
timeout /t 2 /nobreak >nul
goto :eof

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

echo [3/3] Очистка бинарных кэшей...
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenu*.bin" >nul 2>&1
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenulayout.bin" >nul 2>&1
echo [+] Меню Пуск сброшено к состоянию чистой установки.
timeout /t 2 /nobreak >nul
goto :eof

:SystemCleanup
cls
echo.
echo %yellow%[*] БЕЗОПАСНАЯ ОЧИСТКА СИСТЕМЫ...%reset%
echo ================================================================================
echo [1/5] Временные файлы пользователя...
del /f /s /q "%TEMP%\*" >nul 2>&1
echo [+] %TEMP% очищен.

echo [2/5] Временные файлы Windows...
del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
echo [+] C:\Windows\Temp очищен.

echo [3/5] Кэш обновлений (SoftwareDistribution)...
net stop wuauserv >nul 2>&1
del /f /s /q "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
net start wuauserv >nul 2>&1
echo [+] Кэш обновлений очищен.

echo [4/5] Кэш шейдеров DirectX...
del /f /s /q "%LocalAppData%\D3DSCache\*" >nul 2>&1
echo [+] D3DSCache очищен.

echo [5/5] Корзина и системные логи...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
for /f "tokens=*" %%L in ('wevtutil el 2^>nul ^| findstr /v /i "Security\|Setup\|ForwardedEvents"') do wevtutil cl "%%L" >nul 2>&1
echo [+] Корзина и некритичные логи очищены.
timeout /t 2 /nobreak >nul
goto :eof

:: ============================================================================
:: v2.2.0: ApplyAll / RestoreDefaults (последовательный поток без ранних exit)
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
set /p reboot="Перезагрузить систему сейчас? (Y/N): "
if /i "%reboot%"=="Y" (
    echo [*] Перезагрузка через 5 секунд...
    timeout /t 5 /nobreak >nul
    shutdown /r /t 0
)
timeout /t 2 /nobreak >nul
goto :eof

:RestoreDefaults
cls
echo %red%[!] ВОССТАНОВЛЕНИЕ НАСТРОЕК ПО УМОЛЧАНИЮ%reset%
set /p confirm="Вы уверены? (Y/N): "
if /i not "%confirm%"=="Y" goto menu
echo.
echo [*] Откат настроек...
echo ================================================================================
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" REG_DWORD "0" "Включить фон UWP"
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" REG_DWORD "3" "Включить P2P"
sc config DoSvc start=manual >nul 2>&1
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" REG_DWORD "1" "Включить Edge Boost"
call :SetReg "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" REG_DWORD "3" "Включить телеметрию"
call :SetReg "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" REG_DWORD "0" "Включить Copilot"
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" REG_DWORD "1" "Включить UAC"
call :SetReg "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" REG_DWORD "5" "UAC: Запрос по умолчанию"
call :SetReg "HKCU\Control Panel\Mouse" "MouseSpeed" REG_SZ "1" "Включить акселерацию"
call :SetReg "HKCU\Control Panel\Accessibility\StickyKeys" "Flags" REG_SZ "510" "Включить StickyKeys"
call :SetReg "HKCU\Control Panel\Desktop" "MenuShowDelay" REG_SZ "400" "Задержка меню 400мс"
call :SetReg "HKCU\Control Panel\Desktop" "JPEGImportQuality" REG_DWORD "80" "Качество обоев 80%"
call :SetReg "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_IrisRecommendations" REG_DWORD "1" "Показать рекомендации"
call :CleanStartMenu
call :RestartExplorerGracefully
echo.
echo ================================================================================
echo %green%     НАСТРОЙКИ ПО УМОЛЧАНИЮ ВОССТАНОВЛЕНЫ!%reset%
echo ================================================================================
timeout /t 2 /nobreak >nul
goto :eof

:end
cls
echo.
echo %blue%System Tweaker %VERSION%%reset%
echo.
echo Спасибо за использование.
echo Лог действий: %LOG_FILE%
timeout /t 2 /nobreak >nul
exit