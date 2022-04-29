@echo off

chcp 1251 > nul     &REM Non-latin strings encoding


:: chr(09) to %TAB% (for ltrim | rtrim in :Trim)
:: chr(27) to %ESC% (for echo coloring)
echo.0933>%TEMP%\tf & certUtil -decodeHex -f "%TEMP%\tf" "%TEMP%\tf" > nul & set /P TAB= < %TEMP%\tf & del %TEMP%\tf
set TAB=%TAB:3=%
echo.1B33>%TEMP%\tf & certUtil -decodeHex -f "%TEMP%\tf" "%TEMP%\tf" > nul & set /P ESC= < %TEMP%\tf & del %TEMP%\tf
set ESC=%ESC:3=%

echo.091B33>%TEMP%\tf & certUtil -decodeHex -f "%TEMP%\tf" "%TEMP%\tf" > nul & set /P SPECHAR=<%TEMP%\tf & del %TEMP%\tf
set TAB=%SPECHAR:~0,1%
set ESC=%SPECHAR:~1,1%



goto Main

REM ltrim and rtrim whitespaces
:Trim
:ltrim
if "!%1:~0,1!"==" " (set %1=!%1:~1!&goto ltrim)
if "!%1:~0,1!"=="%TAB%" (set %1=!%1:~1!&goto ltrim)
:rtrim
if "!%1:~-1!"==" " (set %1=!%1:~0,-1!&goto rtrim)
if "!%1:~-1!"=="%TAB%" (set %1=!%1:~0,-1!&goto rtrim)
exit /b


REM check file/dir exist
:check_exist
if not exist %1 (
    echo.    %ESC%[41m Каталог/файл не найден %ESC%[0m%ESC%[46G : %1
    set file_not_found=TRUE
) else (
    echo.    %ESC%[92m Каталог/файл найден    %ESC%[0m%ESC%[46G : %1
    set file_not_found=
)
exit /b



:Main

set ServerConfigFile=StartDSTwithParams.conf

if %1.==. (
    echo.
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.::                                                                     ::
    echo.::  StartDSTwithParams v.1.0                                           ::
    echo.::  Copyright ^(c^) trng                                                 ::
    echo.::                                                                     ::
    echo.::                                                                     ::
    echo.::  Скрипт запуска выделенного сервера Don't Starve together.          ::
    echo.::  Для запуска обязательно наличие конфигурационного файла.           ::
    echo.::  Имя файла конфигурации указывается в командной строке:             ::
    echo.::                                                                     ::
    echo.::      StartDSTwithParams.cmd MyDSTDedicatedServer.conf               ::
    echo.::                                                                     ::
    echo.::                                                                     ::
    echo.::  При запуске без параметров испольуется дефолтный конфиг:           ::
    echo.::                                                                     ::
    echo.::      StartDSTwithParams.conf                                        ::
    echo.::                                                                     ::
    echo.::                                                                     ::
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
) else (
    echo.::::::::::::::::::::::::::::::::
    echo.::  StartDSTwithParams v.1.0  ::
    echo.::::::::::::::::::::::::::::::::
    set ServerConfigFile=%1
)
echo.


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Load parameters from ServerConfigFile into local variables
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
if exist %ServerConfigFile% (
    echo.Конфигурационный файл найден: %ServerConfigFile%.     &REM Configuration file found
    echo.Пробуем загрузить параметры... & echo.                &REM Trying to load
) else (
    echo.%ESC%[41mКонфигурационный файл ^( %ServerConfigFile% ^) не найден. Останавливаем скрипт... %ESC%[0m& echo. &REM Configuration file %ServerConfigFile% not found. Exiting...
    pause & exit /b
)

setlocal EnableDelayedExpansion
for /f "delims== tokens=1,2 eol=[" %%a in (%ServerConfigFile%) do (
    :: ltrim/rtrim spaces from parameter name and value
    set keyname=%%a
    call :Trim keyname
    set keyvalue=%%b
    call :Trim keyvalue
    :: define variable 
    set !keyname!=!keyvalue!
)
setlocal DisableDelayedExpansion


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Checking if all required parameters are present in config file
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

set mandatory_params=DST_steamcmd_dir DST_dst_bin DST_persistent_storage_root DST_conf_dir DST_cluster DST_shards DST_my_mods

setlocal EnableDelayedExpansion

for %%a in (%mandatory_params%) do (
    REM trick for OR statement (%%a not defined OR %%a is empty string)  
    set "or_="
    if not defined %%a set or_=true
    REM "!%%a: =!" trim all spaces (check var for empty value)
    if "!%%a: =!"=="" set or_=true
    if defined or_  (
        echo %ESC%[41m     undefined: %%a%ESC%[0m   &REM  ^<ESC^>[35m [35mMagenta[0m
        set noargs=!noargs!  "%%a"
    ) else (
        echo.     %ESC%[92m^defined%ESC%[0m  : %ESC%[32m%%a%ESC%[0m %ESC%[46G = !%%a!
    )
)

echo. 
if defined noargs (
    echo.%ESC%[41m^Требуются дополнительные параметры: %noargs%%ESC%[0m &REM Additional args needed:
    echo.
    echo.%ESC%[41m^Скрипт будет остановлен.%ESC%[0m                       &REM Script will be stopped.
    echo.
    pause & exit /b
)
setlocal DisableDelayedExpansion
                                    


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Check for mandatory folders and files
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo.Проверка наличия необходимых файлов...
setlocal EnableDelayedExpansion

call :check_exist "%DST_steamcmd_dir%"
if not defined file_not_found (
    set temp_file_name=%DST_steamcmd_dir%\steamcmd.exe
    call :check_exist "!temp_file_name!"
    if defined file_not_found (
        echo.    %ESC%[93m Пробуем скачать...%ESC%[0m%ESC%[46G : steamcmd.exe
        curl -s -o %DST_steamcmd_dir%\steamcmd.zip https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip>nul
        tar -xf %DST_steamcmd_dir%\steamcmd.zip -C %DST_steamcmd_dir%>nul
        del %DST_steamcmd_dir%\steamcmd.zip>nul
        if not exist "!temp_file_name!" (
            set file_not_found=TRUE
            echo.    %ESC%[41m Не удалось скачать %ESC%[0m%ESC%[46G : steamcmd.exe
        ) else (
            set file_not_found=
            echo.    %ESC%[92m Удалось скачать    %ESC%[0m%ESC%[46G : steamcmd.exe
        )
    ) 
)

call :check_exist "%DST_persistent_storage_root%"

call :check_exist "%DST_persistent_storage_root%\%DST_conf_dir%"

call :check_exist "%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster%"

call :check_exist "%DST_persistent_storage_root%\%DST_my_mods%\%DST_cluster%"

set mods_setup_lua="%DST_persistent_storage_root%\%DST_my_mods%\%DST_cluster%\dedicated_server_mods_setup.lua"
call :check_exist %mods_setup_lua%

set mod_overrides_lua="%DST_persistent_storage_root%\%DST_my_mods%\%DST_cluster%\modoverrides.lua"
call :check_exist %mod_overrides_lua%

set master_shard=
for %%a in (%DST_shards%) do (
    call :check_exist "%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster%\%%a"
    if not defined master_shard (set master_shard=%%a)
)

if defined file_not_found (
    echo.
    echo.Не найдены необходимые папки и/или файлы.
    echo.Скрипт будет остановлен.  
    pause & exit /b
)


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Shard's Loop
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

REM find existing
echo.
setlocal EnableDelayedExpansion
set CLUSTER_FULL_PATH=!DST_persistent_storage_root!\!DST_conf_dir!\!DST_cluster!
for %%a in (%DST_shards%) do (
    set DST_shard=%%a
    set shard_title=!CLUSTER_FULL_PATH!\!DST_shard!
    set "cmd=tasklist /FI "IMAGENAME eq cmd.exe" /v /fo csv | find "!shard_title!""
    for /F "usebackq tokens=2,9 delims=," %%p in (`!cmd!`) do (
        set pid_with_quotes=%%p
        set pid_without_quotes=!pid_with_quotes:"=!
        set !pid_without_quotes!=%%q
        set pids_list=!pids_list! !pid_without_quotes!
    )
)

if defined pids_list (
    echo.
    echo.%ESC%[41m ------         ВНИМАНИЕ ^^!^^!^^!        ------ %ESC%[0m    &REM WARNING
    echo.%ESC%[41m ------   Найдены запущенные шарды  ------ %ESC%[0m          &REM Running shards found  
    echo.
    for %%a in (%pids_list%) do (
        echo %%a: !%%a!
        REM taskkill /PID %%a
    )
    echo.
    REM set /P AREYOUSURE="Kill running shards (if "NO" script will exit immediately) Y/[N] ?"
    set /P AREYOUSURE="Шарды уже запущены! Остановить их? (Если "НЕТ", то просто выходим из скрипта) Y/[N]? "
    if /I "!AREYOUSURE!" NEQ "Y" (
        echo. & echo.Просто выходим из скрипта  &REM Just exiting
        exit /b
    ) else (
        echo.Пытаемся остановить запущенные шарды...   &REM Trying to kill shards
        for %%a in (%pids_list%) do (
            taskkill /PID %%a
        )
        echo. & echo.Шарды остановлены. Можно запускать снова & echo. &REM Shards killed. Time to start new ones
        pause
    )
)
setlocal DisableDelayedExpansion



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Start steamcmd.exe. Load/update/validate DST application.
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

REM %DST_steamcmd_dir%\steamcmd.exe +login anonymous +app_update 343050 validate +quit



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Run shards
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cd /D %DST_steamcmd_dir%/%DST_dst_bin%

copy %mods_setup_lua% ..\mods\
copy %mod_overrides_lua%  "%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster%\%master_shard%\"  


setlocal EnableDelayedExpansion
for %%a in (%DST_shards%) do (
    set DST_shard=%%a
    rem start StartDSTshard.cmd %DST_shard%
    rem start dontstarve_dedicated_server_nullrenderer_x64 -console -cluster MyDediServer -shard Master

    set HH=%TIME: =0%
    set HH=!HH:~0,2!
    set MM=!TIME:~3,2!
    set SS=!TIME:~6,2!
    set HKCU_Console_Key=!DST_cluster!_!DST_shard!
    if defined HKCU_Console_Key reg delete "hkcu\console\!HKCU_Console_Key!" /f > nul
    if defined %%a (
        for /F "tokens=1-2" %%X in ("!%%a!") do (
            if not "%%X"=="" (
                SET "var="
                for /f "delims=-0123456789" %%i in ("%%X") do (set var=%%i)
                if not defined var set xpos=%%X
            ) 
            if not "%%Y"=="" (
                SET "var="
                for /f "delims=-0123456789" %%i in ("%%Y") do (set var=%%i)
                if not defined var set ypos=%%Y
            )
        )

        if defined xpos (if defined ypos (
                set /a "pos=(!ypos! << 16) + !xpos!"
                reg add "hkcu\console\!HKCU_Console_Key!" /v WindowPosition /t REG_DWORD /d "!pos!" /f
            ) else (
                echo Y coord not defined
            )
        ) else (
            echo X coord not defined
        )
    )
    set console_title_runtime=!CLUSTER_FULL_PATH!\!DST_shard!   Started  !HH!:!MM!:!SS!  %DATE%  ---
    start "!HKCU_Console_Key!" cmd /C ^
        "title !console_title_runtime! " ^
        "& dontstarve_dedicated_server_nullrenderer_x64 " ^
            "-console " ^
            "-persistent_storage_root %DST_persistent_storage_root% " ^
            "-conf_dir %DST_conf_dir% " ^
            "-cluster %DST_cluster%  " ^
            "-shard !DST_shard! ""
)
setlocal DisableDelayedExpansion

echo.
echo.Шарды запущены   &REM Shards started
echo.
pause
exit /b






