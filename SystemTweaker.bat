@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title System Tweaker v1.11

:: === АВТОЗАПРОС ПРАВ АДМИНИСТРАТОРА ===
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [!] Для применения системных настроек требуются права администратора.
    echo     Пожалуйста, подтвердите запрос UAC.
    echo.
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs" >nul 2>&1
    exit /b
)
:: ========================================

:: Настройка цветовых кодов (VT100) для Windows 10/11
for /f "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"

set "blue=%ESC%[96m"
set "green=%ESC%[92m"
set "red=%ESC%[91m"
set "yellow=%ESC%[93m"
set "white=%ESC%[97m"
set "reset=%ESC%[0m"

:: Проверка текущего состояния системы перед отрисовкой меню
call :CheckStatus

:menu
cls
echo.
echo %blue%SYSTEM TWEAKER v1.11%reset%
echo ================================================================================
echo.
echo %yellow%  Изменения вступят в силу после перезагрузки системы!%reset%
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
echo %yellow%[T]%reset%  %yellow%Очистить панель задач%reset%
echo %yellow%[S]%reset%  %yellow%Очистить меню Пуск%reset%
echo %yellow%[X]%reset%  %yellow%Очистка системы%reset%
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

goto menu

:: ============================================================================
:: ФУНКЦИИ ПРОВЕРКИ СТАТУСА
:: ============================================================================
:CheckStatus
:: 1. Power Plan (High Perf = Green)
powercfg /getactivescheme | findstr /i "8c5e7fda" >nul
if %errorlevel% equ 0 (set "power_color=%green%" & set "power_status=Высокая произв.") else (set "power_color=%red%" & set "power_status=Сбалансир.")

:: 2. UWP (Disabled = Green)
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled 2>nul | find "0x1" >nul
if %errorlevel% equ 0 (set "uwp_color=%green%" & set "uwp_status=Отключены") else (set "uwp_color=%red%" & set "uwp_status=Включены")

:: 3. Delivery Opt (Disabled = Green)
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "delivery_color=%green%" & set "delivery_status=Отключена") else (set "delivery_color=%red%" & set "delivery_status=Включена")

:: 4. Edge (Disabled = Green)
reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "edge_color=%green%" & set "edge_status=Отключен") else (set "edge_color=%red%" & set "edge_status=Включен")

:: 5. Telemetry (0 = Green)
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "tele_color=%green%" & set "tele_status=Отключена") else (set "tele_color=%red%" & set "tele_status=Включена")

:: 6. Copilot (Disabled = Green)
reg query "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot 2>nul | find "0x1" >nul
if %errorlevel% equ 0 (set "copilot_color=%green%" & set "copilot_status=Отключен") else (set "copilot_color=%red%" & set "copilot_status=Включен")

:: 7. UAC (Disabled = Green)
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "uac_color=%green%" & set "uac_status=Отключен") else (set "uac_color=%red%" & set "uac_status=Включен")

:: 8. Mouse Accel (Disabled = Green)
reg query "HKCU\Control Panel\Mouse" /v MouseSpeed 2>nul | find "0" >nul
if %errorlevel% equ 0 (set "mouse_color=%green%" & set "mouse_status=Отключена") else (set "mouse_color=%red%" & set "mouse_status=Включена")

:: 9. Sticky Keys (Disabled = Green)
reg query "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags 2>nul | find "506" >nul
if %errorlevel% equ 0 (set "sticky_color=%green%" & set "sticky_status=Отключены") else (set "sticky_color=%red%" & set "sticky_status=Включены")

:: 10. Menu Delay (20ms = Green)
reg query "HKCU\Control Panel\Desktop" /v MenuShowDelay 2>nul | find "20" >nul
if %errorlevel% equ 0 (set "menu_color=%green%" & set "menu_status=20 мс") else (set "menu_color=%red%" & set "menu_status=400 мс")

:: 11. Wallpaper (100% = Green)
reg query "HKCU\Control Panel\Desktop" /v JPEGImportQuality 2>nul | find "0x64" >nul
if %errorlevel% equ 0 (set "wallpaper_color=%green%" & set "wallpaper_status=Отключено") else (set "wallpaper_color=%red%" & set "wallpaper_status=Включено")

:: 12. Recommended (Hidden = Green)
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_IrisRecommendations 2>nul | find "0x0" >nul
if %errorlevel% equ 0 (set "rec_color=%green%" & set "rec_status=Скрыты") else (set "rec_color=%red%" & set "rec_status=Показаны")

goto :eof

:: ============================================================================
:: ФУНКЦИИ ПРИМЕНЕНИЯ НАСТРОЕК
:: ============================================================================
:ApplyPowerPlan
echo.
echo [*] Установка плана питания...
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>nul
if %errorlevel% equ 0 (echo [+] План питания изменен!) else (echo [!] Ошибка изменения плана питания)
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyUWP
echo.
echo [*] Отключение фоновых приложений...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f >nul
echo [+] Фоновые приложения отключены!
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyDelivery
echo.
echo [*] Отключение оптимизации доставки...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d "0" /f >nul
sc config DoSvc start=disabled >nul 2>&1
sc stop DoSvc >nul 2>&1
echo [+] Оптимизация доставки отключена!
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyEdge
echo.
echo [*] Отключение Edge Boost...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /t REG_DWORD /d "0" /f >nul
echo [+] Edge Startup Boost отключен!
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyTelemetry
echo.
echo [*] Отключение телеметрии...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d "1" /f >nul
echo [+] Телеметрия и реклама отключены!
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyCopilot
echo.
echo [*] Отключение Copilot...
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f >nul
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
echo [+] Windows Copilot отключен!
call :CheckStatus
timeout /t 2 /nobreak >nul
goto menu

:ApplyUAC
echo.
echo [*] Отключение UAC...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f >nul
echo [+] UAC отключен! Требуется перезагрузка.
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyMouse
echo.
echo [*] Отключение акселерации мыши...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul
echo [+] Акселерация мыши отключена!
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplySticky
echo.
echo [*] Отключение залипания клавиш...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f >nul
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f >nul
echo [+] Залипание клавиш отключено!
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyMenuDelay
echo.
echo [*] Ускорение меню...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "20" /f >nul
echo [+] Задержка меню установлена на 20 мс!
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyWallpaper
echo.
echo [*] Отключение сжатия обоев...
reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "100" /f >nul
echo [+] Сжатие обоев отключено!
call :CheckStatus
timeout /t 1 /nobreak >nul
goto menu

:ApplyRecommended
echo.
echo [*] Скрытие рекомендаций...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d "0" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_AccountNotifications" /t REG_DWORD /d "0" /f >nul
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
echo [+] Рекомендации скрыты!
call :CheckStatus
timeout /t 2 /nobreak >nul
goto menu

:: ============================================================================
:: ФУНКЦИИ ОЧИСТКИ
:: ============================================================================
:CleanTaskbar
cls
echo.
echo %yellow%[*] НАСТРОЙКА ПАНЕЛИ ЗАДАЧ...%reset%
echo ================================================================================
echo.

echo [1/5] Настройка параметров панели...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d "0" /f >nul 2>&1

echo [2/5] Остановка и полная очистка кэша...
taskkill /F /IM explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams" /f >nul 2>&1
del /f /q "%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.*" >nul 2>&1

echo [3/5] Запуск проводника...
start explorer.exe
timeout /t 3 /nobreak >nul

echo [4/5] Автоматическое закрепление Проводника...
powershell -NoProfile -Command "$s=New-Object -Com Shell.Application; $f=$s.NameSpace('C:\Windows'); $i=$f.ParseName('explorer.exe'); $i.InvokeVerb('taskbarpin')" >nul 2>&1
timeout /t 2 /nobreak >nul

echo [5/5] Финализация...
echo     ✓ Готово

echo.
echo ================================================================================
echo %green%     ПАНЕЛЬ ЗАДАЧ НАСТРОЕНА!%reset%
echo ================================================================================
echo.
echo Итоговый вид: [Пуск] [Поиск] [Проводник]
echo %yellow%  Cortana скрыта, поиск - значок, лишние кнопки отключены.%reset%
echo.
echo %white% Если Проводник не появился (Windows заблокировала действие):%reset%
echo %white%   1. Откройте C:\Windows%reset%
echo %white%   2. Найдите explorer.exe%reset%
echo %white%   3. Перетащите его на панель задач один раз%reset%
echo %white%   Система запомнит это навсегда. Повторно применять не нужно.%reset%
echo.
timeout /t 4 /nobreak >nul
goto menu

:CleanStartMenu
cls
echo.
echo %yellow%[*] ОЧИСТКА МЕНЮ ПУСК...%reset%
echo ================================================================================
echo.

echo [1/4] Удаление пользовательских ярлыков...
del /f /q "%AppData%\Microsoft\Windows\Start Menu\Programs\*.*" >nul 2>&1

echo [2/4] Удаление системных ярлыков...
del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\*.*" >nul 2>&1

echo [3/4] Сброс кэша макета и базы Пуска...
taskkill /F /IM explorer.exe >nul 2>&1
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenu*.bin" >nul 2>&1
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenulayout.bin" >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore" /f >nul 2>&1

echo [4/4] Перезапуск проводника...
start explorer.exe
timeout /t 2 /nobreak >nul

echo.
echo ================================================================================
echo %green%     МЕНЮ ПУСК ОЧИЩЕНО!%reset%
echo ================================================================================
echo.
echo Все закрепления удалены. Меню возвращено к состоянию "из коробки".
echo Рекомендуется выполнить выход и вход в систему для полного обновления интерфейса.
echo.
timeout /t 3 /nobreak >nul
goto menu

:SystemCleanup
cls
echo.
echo %yellow%[*] ГЛУБОКАЯ ОЧИСТКА СИСТЕМЫ...%reset%
echo ================================================================================
echo.

echo [1/7] Временные файлы пользователя:
set count1=0
for /f "delims=" %%f in ('dir /b /a-d "%TEMP%\*" 2^>nul') do set /a count1+=1
del /f /s /q "%TEMP%\*" >nul 2>&1
echo Удалено: %count1% файлов
echo.

echo [2/7] Временные файлы Windows:
set count2=0
for /f "delims=" %%f in ('dir /b /a-d "C:\Windows\Temp\*" 2^>nul') do set /a count2+=1
del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
echo Удалено: %count2% файлов
echo.

echo [3/7] Кэш обновлений Windows:
set count3=0
for /f "delims=" %%f in ('dir /b /a-d "C:\Windows\SoftwareDistribution\Download\*" 2^>nul') do set /a count3+=1
del /f /s /q "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
echo Удалено: %count3% файлов
echo.

echo [4/7] Кэш DirectX Shader:
del /f /s /q "%LocalAppData%\D3DSCache\*" >nul 2>&1
echo Кэш очищен
echo.

echo [5/7] Журналы событий Windows:
wevtutil el >nul 2>&1
for /f "tokens=*" %%x in ('wevtutil el 2^>nul') do (
    wevtutil cl "%%x" >nul 2>&1
)
echo Журналы очищены
echo.

echo [6/7] Корзина:
echo Y| rd /s /q "C:\$Recycle.Bin" >nul 2>&1
echo Корзина очищена
echo.

echo [7/7] Временные файлы установщика:
del /f /s /q "C:\Windows\Installer\$PatchCache$\*" >nul 2>&1
echo Временные файлы удалены

echo.
echo ================================================================================
echo %green%     ОЧИСТКА ЗАВЕРШЕНА!%reset%
echo ================================================================================
echo.
echo Все временные файлы, кэш обновлений и системные логи успешно удалены.
echo Файлы, используемые системой прямо сейчас, будут очищены при следующей загрузке.
echo.
timeout /t 3 /nobreak >nul
goto menu


:: ============================================================================
:: ПРИМЕНИТЬ ВСЕ НАСТРОЙКИ (ИСПРАВЛЕННАЯ ВЕРСИЯ)
:: ============================================================================
:ApplyAll
cls
echo.
echo %green%[*] ПРИМЕНЕНИЕ ВСЕХ НАСТРОЕК...%reset%
echo ================================================================================
echo.

echo [ 1/12] План питания...
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>nul

echo [ 2/12] Фоновые UWP приложения...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f >nul

echo [ 3/12] Оптимизация доставки...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v "DODownloadMode" /t REG_DWORD /d "0" /f >nul
sc config DoSvc start=disabled >nul 2>&1
sc stop DoSvc >nul 2>&1

echo [ 4/12] Edge Startup Boost...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /t REG_DWORD /d "0" /f >nul

echo [ 5/12] Телеметрия и реклама...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d "1" /f >nul

echo [ 6/12] Windows Copilot...
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f >nul

echo [ 7/12] Контроль учетных записей (UAC)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f >nul

echo [ 8/12] Акселерация мыши...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul

echo [ 9/12] Залипание клавиш...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "506" /f >nul
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f >nul

echo [10/12] Задержка меню...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "20" /f >nul

echo [11/12] Сжатие обоев...
reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "100" /f >nul

echo [12/12] Рекомендации в Пуск...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /t REG_DWORD /d "0" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_AccountNotifications" /t REG_DWORD /d "0" /f >nul

echo.
echo ================================================================================
echo %green%     ВСЕ НАСТРОЙКИ ПРИМЕНЕНЫ!%reset%
echo ================================================================================
echo.
echo %yellow%  Для полного применения настроек требуется ПЕРЕЗАГРУЗКА системы!%reset%
echo.
set /p reboot="Перезагрузить систему сейчас? (Y/N): "
if /i "%reboot%"=="Y" (
    echo.
    echo [*] Перезагрузка через 5 секунд...
    timeout /t 5 /nobreak >nul
    shutdown /r /t 0
) else (
    echo.
    echo [*] Перезагрузите компьютер позже для применения всех настроек.
    timeout /t 2 /nobreak >nul
)

call :CheckStatus
goto menu

:: ============================================================================
:: ВОССТАНОВЛЕНИЕ НАСТРОЕК ПО УМОЛЧАНИЮ
:: ============================================================================
:RestoreDefaults
cls
echo.
echo %red%[!] ВОССТАНОВЛЕНИЕ НАСТРОЕК ПО УМОЛЧАНИЮ%reset%
echo.
set /p confirm="Вы уверены? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

echo.
echo [*] Восстановление настроек...
echo ================================================================================
echo.
echo [ 1/12] План питания...
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1

echo [ 2/12] Фоновые UWP приложения...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /f >nul 2>&1

echo [ 3/12] Оптимизация доставки...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /f >nul 2>&1
sc config DoSvc start=manual >nul 2>&1

echo [ 4/12] Edge Startup Boost...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /f >nul 2>&1

echo [ 5/12] Телеметрия и реклама...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /f >nul 2>&1

echo [ 6/12] Windows Copilot...
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /f >nul 2>&1

echo [ 7/12] Контроль учетных записей (UAC)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "1" /f >nul

echo [ 8/12] Акселерация мыши...
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul

echo [ 9/12] Залипание клавиш...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "510" /f >nul
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "122" /f >nul

echo [10/12] Задержка меню...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "400" /f >nul

echo [11/12] Сжатие обоев...
reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "80" /f >nul

echo [12/12] Рекомендации в Пуск...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_IrisRecommendations" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_AccountNotifications" /f >nul 2>&1

echo [13/13] Сброс панели задач и меню Пуск...
taskkill /F /IM explorer.exe >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams" /f >nul 2>&1
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenu*.bin" >nul 2>&1
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\startmenulayout.bin" >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore" /f >nul 2>&1
start explorer.exe

echo.
echo ================================================================================
echo %green%     НАСТРОЙКИ ПО УМОЛЧАНИЮ ВОССТАНОВЛЕНЫ!%reset%
echo ================================================================================
echo.
echo %yellow%  Для полного применения настроек требуется ПЕРЕЗАГРУЗКА системы!%reset%
echo.
echo %white% Пользовательские закрепления не восстанавливаются,%reset%
echo     так как Windows не хранит их историю. Панель и Пуск сброшены%reset%
echo     к состоянию чистой системы.%reset%
echo.
set /p reboot="Перезагрузить систему сейчас? (Y/N): "
if /i "%reboot%"=="Y" (
    echo.
    echo [*] Перезагрузка через 5 секунд...
    timeout /t 5 /nobreak >nul
    shutdown /r /t 0
) else (
    echo.
    echo [*] Перезагрузите компьютер позже для применения всех настроек.
    timeout /t 2 /nobreak >nul
)

call :CheckStatus
goto menu

:end
cls
echo.
echo %blue%System Tweaker v1.11%reset%
echo.
echo Спасибо за использование.
echo.
timeout /t 2 /nobreak >nul
exit