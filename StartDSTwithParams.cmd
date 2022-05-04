@echo off

chcp 1251 > nul     &REM Non-latin strings encoding

REM See :NewConsole label below
if "%1" == "/goto" goto :%2

:: chr(09) to %TAB% (for ltrim | rtrim in :Trim)
:: chr(27) to %ESC% (for echo coloring)
echo.0933>%TEMP%\tf & certUtil -decodeHex -f "%TEMP%\tf" "%TEMP%\tf" > nul & set /P TAB= < %TEMP%\tf & del %TEMP%\tf
set TAB=%TAB:3=%
echo.1B33>%TEMP%\tf & certUtil -decodeHex -f "%TEMP%\tf" "%TEMP%\tf" > nul & set /P ESC= < %TEMP%\tf & del %TEMP%\tf
set ESC=%ESC:3=%

echo.091B33>%TEMP%\tf & certUtil -decodeHex -f "%TEMP%\tf" "%TEMP%\tf" > nul & set /P SPECHAR=<%TEMP%\tf & del %TEMP%\tf
set TAB=%SPECHAR:~0,1%
set ESC=%SPECHAR:~1,1%


set ServerConfigFile=%cd%\StartDSTwithParams.conf

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
    echo.::  При запуске без параметров генерируется/используется               ::
    echo.::  дефолтный конфиг ^(в текущей папке^):                                ::
    echo.::                                                                     ::
    echo.::      StartDSTwithParams.conf                                        ::
    echo.::                                                                     ::
    echo.::                                                                     ::
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    timeout 20
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
setlocal EnableDelayedExpansion
if exist "%ServerConfigFile%" (
    echo.Конфигурационный файл найден: %ServerConfigFile%.     &REM Configuration file found
) else (
    echo.%ESC%[41mКонфигурационный файл ^( %ServerConfigFile% ^) не найден.%ESC%[0m
    set /P AREYOUSURE="Создать с параметрами по умолчанию? (Если "НЕТ", то просто выходим из скрипта) Y/[N]? "
    if /I "!AREYOUSURE!" NEQ "Y" (
        echo. & echo.    Просто выходим из скрипта  &REM Just exiting
        exit /b
    ) else (
        echo.    %ESC%[93m Пробуем содать...%ESC%[0m%ESC%[46G : "%ServerConfigFile%"
:Get_Cluster_Name_again
        set /p cluster_name="Cluster Name: "
        if not defined cluster_name (
            echo.    %ESC%[93mИмя кластера не может быть пустым. Попробуйте еще раз либо Ctrl-C для выхода...%ESC%[0m
            goto :Get_Cluster_Name_again
            pause & exit
        )
        set cluster_folder=!cluster_name: =_!
        call :Generate_Config "%ServerConfigFile%"
        call :check_exist "%ServerConfigFile%"
        if defined check_exist_notfoud (
            echo.Невозможно создать конфигурационный файл "%ServerConfigFile%".
            echo.Выходим из скрипта.
            pause & exit
        )
    )
)

echo. & echo.Пробуем загрузить параметры...                &REM Trying to load

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

set mandatory_params=DST_steamcmd_dir DST_dst_bin DST_exe DST_persistent_storage_root DST_conf_dir DST_cluster_folder DST_shards DST_my_mods

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
set file_not_found=
setlocal EnableDelayedExpansion

call :check_exist "%DST_steamcmd_dir%"
if defined check_exist_notfoud (
    set /P AREYOUSURE="  %ESC%[93m Создать "%DST_steamcmd_dir%"? (Если "НЕТ", то просто выходим из скрипта) Y/[N]?%ESC%[0m "
    if /I "!AREYOUSURE!" NEQ "Y" (
        echo. & echo.    Просто выходим из скрипта  &REM Just exiting
        exit /b
    ) else (
        echo.    %ESC%[93m Пробуем содать...%ESC%[0m%ESC%[46G : "%DST_steamcmd_dir%"
        mkdir %DST_steamcmd_dir%
        call :check_exist "%DST_steamcmd_dir%"
        if defined check_exist_notfoud (
            echo.Невозможно создать папку "%DST_steamcmd_dir%".
            echo.Выходим из скрипта.
            pause & exit
        )
    )
)

set temp_file_name=%DST_steamcmd_dir%\steamcmd.exe
call :check_exist "!temp_file_name!"
if defined check_exist_notfoud (
    echo.    %ESC%[93m Пробуем скачать...%ESC%[0m%ESC%[46G : steamcmd.exe
    curl -L -s -o %DST_steamcmd_dir%\steamcmd.zip https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip>nul
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


call :check_and_create_folder "%DST_persistent_storage_root%"

call :check_and_create_folder "%DST_persistent_storage_root%\%DST_conf_dir%"

call :check_and_create_folder "%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%"

call :check_and_create_folder "%DST_persistent_storage_root%\%DST_my_mods%\%DST_cluster_folder%"



set mods_setup_lua="%DST_persistent_storage_root%\%DST_my_mods%\%DST_cluster_folder%\dedicated_server_mods_setup.lua"
REM call :check_exist %mods_setup_lua%

set mod_overrides_lua="%DST_persistent_storage_root%\%DST_my_mods%\%DST_cluster_folder%\modoverrides.lua"
REM call :check_exist %mod_overrides_lua%

set master_shard=
for %%a in (%DST_shards%) do (
    call :check_exist "%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%\%%a"
    if not defined master_shard (set master_shard=%%a) &REM first shard is master shard
)

if defined file_not_found (
    echo.
    echo.Не найдены необходимые папки и/или файлы.
    echo.Скрипт будет остановлен.  
    pause & exit /b
)


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Shard's Loop (search running shards)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

REM find existing
echo.
setlocal EnableDelayedExpansion
set CLUSTER_FULL_PATH=!DST_persistent_storage_root!\!DST_conf_dir!\!DST_cluster_folder!
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

start "Start steamcmd for load/update/validate DST dedicated server application." cmd /c "%0" /goto NewConsole
timeout 15
exit

:NewConsole
echo.
echo.
echo.Start steamcmd for load/update/validate DST dedicated server application.
echo.
echo.
echo.Press any key to skip load/update/validate game and mods
echo.^(you will be jumped to shard's load^).
echo.
echo.%ESC%[93mWarning! Only do this if you are absolutely sure what you are doing!%ESC%[0m
echo.
echo.
call :timeout_with_keypress_detect 15
if not defined key_pressed (
    echo %DST_steamcmd_dir%
    %DST_steamcmd_dir%\steamcmd.exe +login anonymous +app_update 343050 validate +quit
)


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Run shards
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cd /D %DST_steamcmd_dir%/%DST_dst_bin%

REM Copy 2 mods files to cluster and dst bin
copy %mods_setup_lua% ..\mods\
copy %mod_overrides_lua%  "%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%\%master_shard%\"  


setlocal EnableDelayedExpansion
for %%a in (%DST_shards%) do (
    set DST_shard=%%a
    set HH=%TIME: =0%
    set HH=!HH:~0,2!
    set MM=!TIME:~3,2!
    set SS=!TIME:~6,2!
    set HKCU_Console_Key=!DST_cluster_folder!_!DST_shard!
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
    set console_title_runtime=---   !CLUSTER_FULL_PATH!\!DST_shard!   ---   Started  !HH!:!MM!:!SS!  %DATE%   ---
    start "!HKCU_Console_Key!" cmd /C ^
        "title !console_title_runtime! " ^
        "& %DST_exe% " ^
            "-persistent_storage_root %DST_persistent_storage_root% " ^
            "-conf_dir %DST_conf_dir% " ^
            "-cluster %DST_cluster_folder%  " ^
            "-shard !DST_shard! ""
)
REM            :: -console has been deprecated Use the [MISC] / console_enabled setting instead. "-console " ^
setlocal DisableDelayedExpansion

timeout 25
exit


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
::
:: FUNCTIONS
::
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


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
REM Mandatory param - folder or file name
:check_exist
set check_exist_notfoud=
if not exist %1 (
    echo.    %ESC%[41m Каталог/файл не найден %ESC%[0m%ESC%[46G : %1
    set check_exist_notfoud=TRUE
) else (
    echo.    %ESC%[92m Каталог/файл найден    %ESC%[0m%ESC%[46G : %1
)
exit /b


REM Check if folder exsit. Try create non-existing folder. Exit from main script on error
REM Mandatory param - folder name
:check_and_create_folder
call :check_exist %1
if defined check_exist_notfoud (
    echo.   %ESC%[93m Пробуем содать...%ESC%[0m%ESC%[46G : %1
    mkdir "%1"
    call :check_exist %1
    if defined check_exist_notfoud (
        echo.    Невозможно создать папку %1. Продолжение невозможно.
        pause & exit
    )
)
exit /b



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Timeout with key press detect.
::
:: Mandatory parameter : seconds for timeout.
:: Return value        : key_pressed variable defined if key pressed
::                      (value - seconds when key was pressed).
::                       If key was not pressed - key_pressed is undefined.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:timeout_with_keypress_detect
    set time_to_out=%1
    set key_pressed=
    set /a SEC_BEFORE=1%TIME:~6,2% - 100
    timeout %time_to_out%
    set /a SEC_AFTER=1%TIME:~6,2%  - 100
    if %SEC_AFTER% GEQ %SEC_BEFORE% (set /a DIFF=%SEC_AFTER% - %SEC_BEFORE%) ^
        else (set /a DIFF=60 + %SEC_AFTER% - %SEC_BEFORE%)
    if %DIFF% LSS %time_to_out% (set /a key_pressed=%DIFF%)
    exit /b


REM Mandatory param - config name
:Generate_Config
setlocal EnableDelayedExpansion
(echo ^
[                                                                                             ]^

[   Конфигурационный файл для запуска скрипта StartDSTwithParams.cmd                          ]^

[   Секции используются только для наглядности. Все параметры загружаются одним списком.      ]^

[                                                                                             ]^

^

^

[STEAM]^

DST_steamcmd_dir    		    = !USERPROFILE!\steamcmd^

DST_dst_bin                  	= steamapps\common\Don't Starve Together Dedicated Server\bin64^

DST_exe                         = dontstarve_dedicated_server_nullrenderer_x64.exe^

^

^

[SERVER]^

[   parameters for dontstarve_dedicated_server_nullrenderer executable                        ]^

DST_persistent_storage_root  	= !USERPROFILE!\KleiDedicated^

DST_conf_dir                 	= DoNotStarveTogether^

DST_cluster_folder             	= %cluster_folder%^

^

^

[SHARDS]^

[   space separated dirnames, dirname cannot include spaces                                   ]^

[   Example: Master Caves                                                                     ]^

[   First shard is master always. TODO: parse cluster.ini server.ini to find master           ]^

DST_shards                      = Master Caves^

^

^

[MYMODS]^

[   dir for mods settings per cluster                                                         ]^

[   dir located inside %%DST_persistent_storage_root%%                                          ]^

[   for now only 2 files affected:                                                            ]^

[   1. dedicated_server_mods_setup.lua, 2. modoverrides.lua                                   ]^

[   This 2 files must be inside   %%DST_persistent_storage_root%%/%%MyMods%%/%%DST_cluster_folder%% ]^

DST_my_mods                     = MyMods^

^

^

[CONSOLE]^

[   Screen coordinates X Y for each shard's console window ^(optional^)                         ]^

[   Key    - shard's name ^(as listed at DST_shards^).                                          ]^

[   Value  - X Y ^(space separated, may be negative for second screen at left^)                 ]^

Master                          = X Y^

Caves                           = X Y^

)>%1
exit /b
