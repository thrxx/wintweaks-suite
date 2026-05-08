@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Explorer Config v1.5

:: === АВТОЗАПРОС ПРАВ АДМИНИСТРАТОРА ===
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [!] Для изменения настроек проводника требуются права администратора.
    echo     Пожалуйста, подтвердите запрос UAC.
    echo.
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs" >nul 2>&1
    exit /b
)
:: ========================================

:: === ОПРЕДЕЛЕНИЕ ВЕРСИИ WINDOWS ===
for /f "tokens=2 delims=." %%v in ('ver') do set "WIN_VER=%%v"
if %WIN_VER% GEQ 22000 (
    set "OS_TYPE=win11"
) else (
    set "OS_TYPE=win10"
)
:: ========================================

:: Цвета VT100 (без восклицательных знаков в именах переменных)
for /f "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "blue=%ESC%[96m"
set "green=%ESC%[92m"
set "red=%ESC%[91m"
set "yellow=%ESC%[93m"
set "white=%ESC%[97m"
set "reset=%ESC%[0m"

call :CheckExplorerStatus

:menu
cls
echo.
echo %blue%EXPLORER CONFIG v1.5%reset%
echo ================================================================================
echo.
if "%OS_TYPE%"=="win10" (
    echo %yellow%Обнаружена: Windows 10%reset%
) else (
    echo %yellow%Обнаружена: Windows 11%reset%
)
echo %yellow%  Для применения изменений необходимо перезапустить проводник.%reset%
echo.
echo %white%[1]%reset%  Открытие проводника          : %open_color%%open_status%%reset%
echo %white%[2]%reset%  Кнопка "Главное"             : %home_color%%home_status%%reset%  %red%[Win11]%reset%
echo %white%[3]%reset%  Кнопка "Галерея"             : %gallery_color%%gallery_status%%reset%  %red%[Win11]%reset%
echo %white%[4]%reset%  Кнопка "Сеть"                : %network_color%%network_status%%reset%
echo %white%[5]%reset%  Корзина в панели навигации   : %navbin_color%%navbin_status%%reset%
echo %white%[6]%reset%  Корзина на рабочем столе     : %desktopbin_color%%desktopbin_status%%reset%
echo %white%[7]%reset%  Компактный вид               : %compact_color%%compact_status%%reset%  %red%[Win11]%reset%
echo %white%[8]%reset%  Частые папки (Recent)        : %recent_color%%recent_status%%reset%
echo %white%[9]%reset%  Контекстное меню             : %context_color%%context_status%%reset%  %red%[Win11]%reset%
echo.
echo --------------------------------------------------------------------------------
echo %yellow%[R]%reset%  %yellow%Перезапустить проводник%reset%
echo.
echo %green%[A]%reset%  %green%Применить все настройки%reset%
echo %red%[D]%reset%  %red%Вернуть как было%reset%
echo %white%[0]%reset%  %white%Выход%reset%
echo.
echo ================================================================================
echo.
set /p choice="%white%Введите номер пункта для изменения: %reset%"

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

goto menu

:: ============================================================================
:: ПРОВЕРКА ТЕКУЩИХ НАСТРОЕК
:: ============================================================================
:CheckExplorerStatus
setlocal disabledelayedexpansion
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" 2>nul | findstr /i "0x1" >nul 2>&1
if %errorlevel% equ 0 (set "open_color=%green%" & set "open_status=Этот компьютер") else (set "open_color=%red%" & set "open_status=Главное")

if "%OS_TYPE%"=="win11" (
    reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" 2>nul | findstr /i "0x1" >nul 2>&1
    if %errorlevel% equ 0 (set "home_color=%green%" & set "home_status=Скрыта") else (set "home_color=%red%" & set "home_status=Видна")
) else (
    set "home_color=%yellow%" & set "home_status=Недоступно"
)

if "%OS_TYPE%"=="win11" (
    reg query "HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v "System.IsPinnedToNameSpaceTree" 2>nul | findstr /i "0x0" >nul 2>&1
    if %errorlevel% equ 0 (set "gallery_color=%green%" & set "gallery_status=Скрыта") else (set "gallery_color=%red%" & set "gallery_status=Видна")
) else (
    set "gallery_color=%yellow%" & set "gallery_status=Недоступно"
)

:: Кнопка "Сеть" – единый CLSID для всех версий
reg query "HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" 2>nul | findstr /i "0x0" >nul 2>&1
if %errorlevel% equ 0 (set "network_color=%green%" & set "network_status=Скрыта") else (set "network_color=%red%" & set "network_status=Видна")

reg query "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" 2>nul | findstr /i "0x1" >nul 2>&1
if %errorlevel% equ 0 (set "navbin_color=%green%" & set "navbin_status=Включена") else (set "navbin_color=%red%" & set "navbin_status=Отключена")

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" 2>nul | findstr /i "0x1" >nul 2>&1
if %errorlevel% equ 0 (set "desktopbin_color=%green%" & set "desktopbin_status=Скрыта") else (set "desktopbin_color=%red%" & set "desktopbin_status=Видна")

if "%OS_TYPE%"=="win11" (
    reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" 2>nul | findstr /i "0x1" >nul 2>&1
    if %errorlevel% equ 0 (set "compact_color=%green%" & set "compact_status=Включен") else (set "compact_color=%red%" & set "compact_status=Отключен")
) else (
    set "compact_color=%yellow%" & set "compact_status=Недоступно"
)

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" 2>nul | findstr /i "0x0" >nul 2>&1
if %errorlevel% equ 0 (set "recent_color=%green%" & set "recent_status=Отключены") else (set "recent_color=%red%" & set "recent_status=Включены")

if "%OS_TYPE%"=="win11" (
    reg query "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" >nul 2>&1
    if %errorlevel% equ 0 (set "context_color=%green%" & set "context_status=Классическое") else (set "context_color=%red%" & set "context_status=Современное")
) else (
    set "context_color=%yellow%" & set "context_status=Недоступно"
)
endlocal & (
    set "open_color=%open_color%"
    set "open_status=%open_status%"
    set "home_color=%home_color%"
    set "home_status=%home_status%"
    set "gallery_color=%gallery_color%"
    set "gallery_status=%gallery_status%"
    set "network_color=%network_color%"
    set "network_status=%network_status%"
    set "navbin_color=%navbin_color%"
    set "navbin_status=%navbin_status%"
    set "desktopbin_color=%desktopbin_color%"
    set "desktopbin_status=%desktopbin_status%"
    set "compact_color=%compact_color%"
    set "compact_status=%compact_status%"
    set "recent_color=%recent_color%"
    set "recent_status=%recent_status%"
    set "context_color=%context_color%"
    set "context_status=%context_status%"
)
goto :eof

:: ============================================================================
:: ОТДЕЛЬНЫЕ ФУНКЦИИ ПЕРЕКЛЮЧЕНИЯ
:: ============================================================================
:SetExplorerOpen
echo [*] Настройка открытия проводника...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d "1" /f >nul
echo [+] Проводник теперь открывается в "Этот компьютер"
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleHomeButton
if "%OS_TYPE%"=="win10" (
    echo [!] Эта функция доступна только в Windows 11
    timeout /t 2 /nobreak >nul
    goto menu
)
echo [*] Переключение кнопки "Главное"...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /t REG_DWORD /d "1" /f >nul
echo [+] Кнопка "Главное" скрыта
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleGalleryButton
if "%OS_TYPE%"=="win10" (
    echo [!] Эта функция доступна только в Windows 11
    timeout /t 2 /nobreak >nul
    goto menu
)
echo [*] Переключение кнопки "Галерея"...
reg add "HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul
echo [+] Кнопка "Галерея" скрыта
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleNetworkButton
echo [*] Переключение кнопки "Сеть"...
reg add "HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul
echo [+] Кнопка "Сеть" скрыта
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleNavBin
echo [*] Включение корзины в панели навигации...
reg add "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "1" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d "0" /f >nul
echo [+] Корзина добавлена в панель навигации
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleDesktopBin
echo [*] Скрытие корзины с рабочего стола...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d "1" /f >nul
echo [+] Корзина скрыта с рабочего стола
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleCompactView
if "%OS_TYPE%"=="win10" (
    echo [!] Эта функция доступна только в Windows 11
    timeout /t 2 /nobreak >nul
    goto menu
)
echo [*] Включение компактного вида...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /t REG_DWORD /d "1" /f >nul
echo [+] Компактный вид включен
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleRecentFolders
echo [*] Отключение частых папок...
if "%OS_TYPE%"=="win11" (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d "0" /f >nul
) else (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d "0" /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f >nul
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "0" /f >nul
)
echo [+] Частые папки отключены
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:ToggleContextMenu
if "%OS_TYPE%"=="win10" (
    echo [!] Эта функция доступна только в Windows 11
    timeout /t 2 /nobreak >nul
    goto menu
)
echo [*] Переключение контекстного меню...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul
echo [+] Контекстное меню изменено на классическое
call :CheckExplorerStatus
timeout /t 1 /nobreak >nul
goto menu

:: ============================================================================
:: ПЕРЕЗАПУСК ПРОВОДНИКА
:: ============================================================================
:RestartExplorer
cls
echo.
echo %yellow%[*] ПЕРЕЗАПУСК ПРОВОДНИКА...%reset%
echo ================================================================================
echo.
echo [*] Остановка проводника...
taskkill /F /IM explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul

echo [*] Запуск проводника...
start explorer.exe
timeout /t 2 /nobreak >nul

echo.
echo ================================================================================
echo %green%     ПРОВОДНИК ПЕРЕЗАПУЩЕН%reset%
echo ================================================================================
echo.
echo %yellow%  Изменения должны вступить в силу.%reset%
echo     Если что-то не применилось, перезапустите компьютер.
echo.
timeout /t 3 /nobreak >nul
goto menu

:: ============================================================================
:: ПРИМЕНИТЬ ВСЕ НАСТРОЙКИ (ПОЛНОСТЬЮ ИСПРАВЛЕННАЯ ВЕРСИЯ)
:: ============================================================================
:ApplyAllExplorer
setlocal disabledelayedexpansion
cls
echo %green%[*] ПРИМЕНЕНИЕ ВСЕХ НАСТРОЕК ПРОВОДНИКА...%reset%
echo ================================================================================
echo.

echo [ 1/9] Открытие в "Этот компьютер"...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d "1" /f >nul 2>&1
if errorlevel 1 echo     ^> Предупреждение: ошибка 1/9

if "%OS_TYPE%"=="win11" (
    echo [ 2/9] Скрытие кнопки "Главное"...
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /t REG_DWORD /d "1" /f >nul 2>&1
    if errorlevel 1 echo     ^> Предупреждение: ошибка 2/9

    echo [ 3/9] Скрытие кнопки "Галерея"...
    reg add "HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1
    if errorlevel 1 echo     ^> Предупреждение: ошибка 3/9

    echo [ 4/9] Скрытие кнопки "Сеть"...
    reg add "HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1
    if errorlevel 1 echo     ^> Предупреждение: ошибка 4/9

    echo [ 7/9] Включение компактного вида...
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /t REG_DWORD /d "1" /f >nul 2>&1
    if errorlevel 1 echo     ^> Предупреждение: ошибка 7/9

    echo [ 9/9] Классическое контекстное меню...
    reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1
    if errorlevel 1 echo     ^> Предупреждение: ошибка 9/9
) else (
    echo [ 2/9] Пропуск (Win10): Кнопка "Главное"
    echo [ 3/9] Пропуск (Win10): Кнопка "Галерея"

    echo [ 4/9] Скрытие кнопки "Сеть"...
    reg add "HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "0" /f >nul 2>&1
    if errorlevel 1 echo     ^> Предупреждение: ошибка 4/9

    echo [ 9/9] Пропуск (Win10): Контекстное меню
)

echo [ 5/9] Корзина в панели навигации...
reg add "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d "1" /f >nul 2>&1
if errorlevel 1 echo     ^> Предупреждение: ошибка 5/9 (панель)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d "0" /f >nul 2>&1
if errorlevel 1 echo     ^> Предупреждение: ошибка 5/9 (рабочий стол)

echo [ 6/9] Скрытие корзины с рабочего стола...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d "1" /f >nul 2>&1
if errorlevel 1 echo     ^> Предупреждение: ошибка 6/9

echo [ 8/9] Отключение частых папок...
if "%OS_TYPE%"=="win11" (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d "0" /f >nul 2>&1
    if errorlevel 1 echo     ^> Предупреждение: ошибка 8/9
) else (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d "0" /f >nul 2>&1
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f >nul 2>&1
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "0" /f >nul 2>&1
    if errorlevel 1 echo     ^> Предупреждение: ошибка 8/9
)

echo.
echo ================================================================================
echo %green%     ВСЕ НАСТРОЙКИ ПРИМЕНЕНЫ%reset%
echo ================================================================================
echo.
echo %yellow%Для полного вступления изменений в силу:%reset%
echo %yellow%  - перезапустите проводник (пункт [R])%reset%
echo %yellow%  - или перезагрузите компьютер.%reset%
echo.
pause
endlocal
call :CheckExplorerStatus
goto menu

:: ============================================================================
:: ВОССТАНОВЛЕНИЕ НАСТРОЕК ПО УМОЛЧАНИЮ
:: ============================================================================
:RestoreExplorerDefaults
setlocal disabledelayedexpansion
cls
echo %red%[!] ВОССТАНОВЛЕНИЕ НАСТРОЕК ПРОВОДНИКА%reset%
echo.
set /p confirm="Вы уверены? (Y/N): "
if /i not "%confirm%"=="Y" goto menu

echo.
echo [*] Восстановление настроек...
echo ================================================================================
echo.

echo [ 1/9] Открытие в "Главное"...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /f >nul 2>&1

if "%OS_TYPE%"=="win11" (
    echo [ 2/9] Показ кнопки "Главное"...
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f >nul 2>&1
    echo [ 3/9] Показ кнопки "Галерея"...
    reg delete "HKCU\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v "System.IsPinnedToNameSpaceTree" /f >nul 2>&1
) else (
    echo [ 2/9] Пропуск (Win10): Кнопка "Главное"
    echo [ 3/9] Пропуск (Win10): Кнопка "Галерея"
)

echo [ 4/9] Показ кнопки "Сеть"...
reg delete "HKCU\Software\Classes\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /v "System.IsPinnedToNameSpaceTree" /f >nul 2>&1

echo [ 5/9] Отключение корзины в навигации...
reg delete "HKCU\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}" /v "System.IsPinnedToNameSpaceTree" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /f >nul 2>&1

echo [ 6/9] Показ корзины на рабочем столе...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /f >nul 2>&1

if "%OS_TYPE%"=="win11" (
    echo [ 7/9] Отключение компактного вида...
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "UseCompactMode" /f >nul 2>&1
) else (
    echo [ 7/9] Пропуск (Win10): Компактный вид
)

echo [ 8/9] Включение частых папок...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /f >nul 2>&1
if "%OS_TYPE%"=="win10" (
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /f >nul 2>&1
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /f >nul 2>&1
)

if "%OS_TYPE%"=="win11" (
    echo [ 9/9] Современное контекстное меню...
    reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
) else (
    echo [ 9/9] Пропуск (Win10): Контекстное меню
)

echo.
echo ================================================================================
echo %green%     НАСТРОЙКИ ВОССТАНОВЛЕНЫ%reset%
echo ================================================================================
echo.
echo %yellow%  Для применения изменений необходимо перезапустить проводник.%reset%
echo.
set /p restart="Перезапустить проводник сейчас? (Y/N): "
if /i "%restart%"=="Y" (
    call :RestartExplorer
) else (
    echo [*] Перезапустите проводник позже через меню [R].
    timeout /t 2 /nobreak >nul
)
endlocal
call :CheckExplorerStatus
goto menu

:end
cls
echo.
echo %blue%Explorer Config v1.5%reset%
echo.
echo Спасибо за использование.
echo.
timeout /t 2 /nobreak >nul
exit