@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:MAIN_MENU
cls
echo ============================================================
echo   RKN Block Checker — Меню управления
echo ============================================================
echo.
echo   [1]  Полная проверка (whitelist + blacklist)
echo   [2]  Только whitelist (сайты, которые ДОЛЖНЫ работать)
echo   [3]  Только blacklist (сайты РКН)
echo   [4]  Проверить один или несколько URL
echo   [5]  Полная проверка + JSON вывод
echo   [6]  Только blacklist + JSON (для jq/скриптов)
echo   [7]  Только whitelist + JSON
echo   [8]  Быстрая проверка (таймаут 2с, 20 потоков)
echo   [9]  Медленная/надёжная проверка (таймаут 15с, 5 потоков)
echo   [10] Расширенный вывод (verbose -v)
echo   [11] Debug вывод (-vv)
echo   [12] Установить / обновить rkn-block-checker
echo   [13] Проверить установку
echo   [14] Сохранить результат в файл (полный отчёт)
echo   [15] Сохранить JSON в файл
echo   [16] Удалить rkn-block-checker
echo   [0]  Выход
echo.
set /p CHOICE="  Выберите действие [0-16]: "

if "%CHOICE%"=="1"  goto RUN_FULL
if "%CHOICE%"=="2"  goto RUN_WHITE
if "%CHOICE%"=="3"  goto RUN_BLACK
if "%CHOICE%"=="4"  goto RUN_URL
if "%CHOICE%"=="5"  goto RUN_JSON
if "%CHOICE%"=="6"  goto RUN_BLACK_JSON
if "%CHOICE%"=="7"  goto RUN_WHITE_JSON
if "%CHOICE%"=="8"  goto RUN_FAST
if "%CHOICE%"=="9"  goto RUN_SLOW
if "%CHOICE%"=="10" goto RUN_VERBOSE
if "%CHOICE%"=="11" goto RUN_DEBUG
if "%CHOICE%"=="12" goto INSTALL
if "%CHOICE%"=="13" goto CHECK_INSTALL
if "%CHOICE%"=="14" goto SAVE_REPORT
if "%CHOICE%"=="15" goto SAVE_JSON
if "%CHOICE%"=="16" goto UNINSTALL
if "%CHOICE%"=="0"  goto EXIT

echo   [!] Неверный выбор. Попробуйте снова.
timeout /t 2 >nul
goto MAIN_MENU

:: ============================================================
:: Подпрограмма проверки наличия Python и pip.
:: PY_MISSING=1 если python не найден, PIP_MISSING=1 если pip не найден.
:: ============================================================
:CHECK_PYTHON
set PY_MISSING=0
set PIP_MISSING=0
where python >nul 2>&1
if not %ERRORLEVEL%==0 (
    set PY_MISSING=1
    echo   [!] Python не найден в PATH.
    echo   Скачайте и установите Python 3.10+ с https://python.org/downloads/
    echo   При установке обязательно отметьте "Add Python to PATH".
    echo.
)
where pip >nul 2>&1
if not %ERRORLEVEL%==0 (
    set PIP_MISSING=1
    echo   [!] pip не найден в PATH.
    if "!PY_MISSING!"=="0" (
        echo   Python найден, но pip недоступен. Попробуйте: python -m ensurepip
    )
    echo.
)
exit /b

:: ============================================================
:: Подпрограмма проверки наличия rkn-check.
:: RKN_MISSING=1 если пакет не найден.
:: ============================================================
:CHECK_RKN
set RKN_MISSING=0
where rkn-check >nul 2>&1
if not %ERRORLEVEL%==0 (
    set RKN_MISSING=1
    echo   [!] rkn-check не найден в PATH.
    echo   Установите пакет через пункт [12] меню.
    echo.
)
exit /b

:: ============================================================
:: Макрос: проверить python + pip + rkn-check.
:: Используется во всех пунктах запуска (1-11, 14-15).
:: ============================================================
:CHECK_ALL
call :CHECK_PYTHON
call :CHECK_RKN
exit /b

:: ============================================================

:RUN_FULL
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Запуск полной проверки (whitelist + blacklist)...
echo   Нажмите Ctrl+C для остановки.
echo.
rkn-check
echo.
pause
goto MAIN_MENU

:RUN_WHITE
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Проверка whitelist (сайты, которые ДОЛЖНЫ работать)...
echo.
rkn-check --white
echo.
pause
goto MAIN_MENU

:RUN_BLACK
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Проверка blacklist (заблокированные сайты РКН)...
echo.
rkn-check --black
echo.
pause
goto MAIN_MENU

:RUN_URL
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Введите URL-адреса для проверки (по одному на строку).
echo   Можно вводить домены (example.com) или полные URL (https://example.com).
echo   Пустая строка — завершить ввод и запустить проверку.
echo.
set URL_COUNT=0
set URL_ARGS=
call :URL_INPUT_LOOP
if !URL_COUNT!==0 (
    echo   [!] Не введено ни одного URL.
    timeout /t 2 >nul
    goto MAIN_MENU
)
echo.
echo   Проверяем !URL_COUNT! адрес(ов)...
echo.
rkn-check !URL_ARGS!
echo.
pause
goto MAIN_MENU

:URL_INPUT_LOOP
set NEXT_URL=
set /p NEXT_URL="  > "
if "!NEXT_URL!"=="" exit /b
set /a URL_COUNT+=1
set URL_ARGS=!URL_ARGS! --url "!NEXT_URL!"
goto URL_INPUT_LOOP

:RUN_JSON
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Полная проверка + JSON вывод...
echo.
rkn-check --json
echo.
pause
goto MAIN_MENU

:RUN_BLACK_JSON
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Blacklist + JSON...
echo.
rkn-check --black --json
echo.
pause
goto MAIN_MENU

:RUN_WHITE_JSON
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Whitelist + JSON...
echo.
rkn-check --white --json
echo.
pause
goto MAIN_MENU

:RUN_FAST
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Быстрая проверка (таймаут 2с, 20 потоков)...
echo.
rkn-check --timeout 2 --workers 20
echo.
pause
goto MAIN_MENU

:RUN_SLOW
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Надёжная проверка (таймаут 15с, 5 потоков)...
echo.
rkn-check --timeout 15 --workers 5
echo.
pause
goto MAIN_MENU

:RUN_VERBOSE
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Полная проверка с расширенным логом (-v)...
echo.
rkn-check -v
echo.
pause
goto MAIN_MENU

:RUN_DEBUG
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Полная проверка с DEBUG логом (-vv)...
echo.
rkn-check -vv
echo.
pause
goto MAIN_MENU

:INSTALL
cls
call :CHECK_PYTHON
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Установка / обновление rkn-block-checker...
echo.
pip install --upgrade rkn-block-checker
echo.
echo   Готово! Проверка версии:
rkn-check --version 2>nul || echo   (команда --version не поддерживается в этой версии)
echo.
pause
goto MAIN_MENU

:CHECK_INSTALL
cls
call :CHECK_PYTHON
echo   Проверка установки...
echo.
where rkn-check >nul 2>&1
if %ERRORLEVEL%==0 (
    echo   [OK] rkn-check найден:
    where rkn-check
    echo.
    if "!PIP_MISSING!"=="0" (
        pip show rkn-block-checker
    ) else (
        echo   [!] pip недоступен — не удаётся показать детали пакета.
    )
) else (
    echo   [!] rkn-check не найден в PATH.
    echo   Запустите пункт [12] для установки.
)
echo.
pause
goto MAIN_MENU

:SAVE_REPORT
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
set TIMESTAMP=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%
set TIMESTAMP=%TIMESTAMP: =0%
set FILENAME=rkn-report-%TIMESTAMP%.txt
echo   Сохраняем полный отчёт в %FILENAME%...
echo.
set PYTHONUTF8=1
rkn-check > "%FILENAME%" 2>&1
set PYTHONUTF8=
if exist "%FILENAME%" (
    findstr /C:"Traceback" "%FILENAME%" >nul 2>&1
    if !ERRORLEVEL!==0 (
        echo   [!] Ошибка в rkn-check при сохранении. Содержимое файла:
        echo.
        type "%FILENAME%"
    ) else (
        echo   [OK] Отчёт сохранён: %FILENAME%
    )
) else (
    echo   [!] Файл не создан. Проверьте установку rkn-check.
)
echo.
pause
goto MAIN_MENU

:SAVE_JSON
cls
call :CHECK_ALL
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!RKN_MISSING!"=="1" ( pause & goto MAIN_MENU )
set TIMESTAMP=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%
set TIMESTAMP=%TIMESTAMP: =0%
set FILENAME=rkn-report-%TIMESTAMP%.json
echo   Сохраняем JSON в %FILENAME%...
echo.
set PYTHONUTF8=1
rkn-check --json > "%FILENAME%" 2>&1
set PYTHONUTF8=
if exist "%FILENAME%" (
    findstr /C:"Traceback" "%FILENAME%" >nul 2>&1
    if !ERRORLEVEL!==0 (
        echo   [!] Ошибка в rkn-check при сохранении. Содержимое файла:
        echo.
        type "%FILENAME%"
    ) else (
        echo   [OK] JSON сохранён: %FILENAME%
    )
) else (
    echo   [!] Файл не создан. Проверьте установку rkn-check.
)
echo.
pause
goto MAIN_MENU

:UNINSTALL
cls
call :CHECK_PYTHON
if "!PY_MISSING!"=="1" ( pause & goto MAIN_MENU )
if "!PIP_MISSING!"=="1" ( pause & goto MAIN_MENU )
echo   Удаление rkn-block-checker...
echo.
where rkn-check >nul 2>&1
if not %ERRORLEVEL%==0 (
    echo   [!] rkn-check не найден — возможно, уже удалён или не был установлен.
    echo.
    pause
    goto MAIN_MENU
)
echo   Будет удалён пакет rkn-block-checker.
set /p CONFIRM="  Подтвердите удаление [y/N]: "
if /i not "!CONFIRM!"=="y" (
    echo.
    echo   Отменено.
    timeout /t 2 >nul
    goto MAIN_MENU
)
echo.
pip uninstall rkn-block-checker -y
echo.
where rkn-check >nul 2>&1
if not %ERRORLEVEL%==0 (
    echo   [OK] rkn-block-checker успешно удалён.
) else (
    echo   [!] Что-то пошло не так — rkn-check всё ещё найден в PATH.
    echo   Попробуйте вручную: pip uninstall rkn-block-checker
)
echo.
pause
goto MAIN_MENU

:EXIT
cls
echo   Выход. Пока!
timeout /t 1 >nul
exit /b 0
