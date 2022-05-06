@echo off
REM !WORKING_DIR! - Folder for config and cluster by default (changeable via .conf)
set WORKING_DIR=%cd%

setlocal EnableDelayedExpansion     &REM Till the end of whole script!
chcp 1251 > nul                     &REM Non-latin strings encoding
if "%1" == "/goto" goto :%2         &REM See :NewConsole label below for details


:: Hack for define placeholders:
::    - chr(09) to %TAB% (for ltrim | rtrim in :Trim)
::    - chr(27) to %ESC% (for echo coloring)
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
echo.
echo.


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Load parameters from ServerConfigFile into local variables
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if exist "%ServerConfigFile%" (
    echo.Конфигурационный файл найден: %ServerConfigFile%.     &REM Configuration file found
    set cluster_name=ClusterName&REM Very bad! Change!
) else (
    echo.%ESC%[41mКонфигурационный файл ^( %ServerConfigFile% ^) не найден.%ESC%[0m
    echo.&echo.&echo.&echo.
    echo.%ESC%[4A
    set /P AREYOUSURE="Создать с параметрами по умолчанию? (Если "НЕТ", то просто выходим из скрипта) Y/[N]? "
    if /I "!AREYOUSURE!" NEQ "Y" (
        echo. & echo.    Просто выходим из скрипта  &REM Just exiting
        exit /b
    ) else (
:Get_Cluster_Name_again
        echo.
        set /p cluster_name="%ESC%[93mCluster Name: "
        echo.
        echo.%ESC%[0m
        if not defined cluster_name (
            echo.    %ESC%[41mИмя кластера не может быть пустым. Попробуйте еще раз либо Ctrl-C для выхода...%ESC%[0m
            goto :Get_Cluster_Name_again
            pause & exit
        )
        set new_cluster_folder=!cluster_name: =_!
        echo.    %ESC%[32m Пробуем создать...%ESC%[0m%ESC%[46G : "%ServerConfigFile%"
        call :Generate_Config "%ServerConfigFile%"
        call :check_exist "%ServerConfigFile%"
        if defined check_exist_notfoud (
            echo.Невозможно создать конфигурационный файл "%ServerConfigFile%".
            echo.Выходим из скрипта.
            pause & exit
        )
    )
)

echo !cluster_name!

echo. & echo.Пробуем загрузить параметры...                &REM Trying to load
for /f "delims== tokens=1,2 eol=[" %%a in (%ServerConfigFile%) do (
    :: ltrim/rtrim spaces from parameter name and value
    set keyname=%%a
    call :Trim keyname
    set keyvalue=%%b
    call :Trim keyvalue
    :: define variable with with loaded value
    set !keyname!=!keyvalue!
)



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Checking if all required parameters are present in config file
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

set mandatory_params=DST_steamcmd_dir DST_dst_bin DST_exe DST_persistent_storage_root DST_conf_dir DST_cluster_folder DST_shards DST_my_mods_templates_folder DST_cluster_templates_folder

for %%a in (%mandatory_params%) do (
    REM trick for OR statement (%%a not defined OR %%a is empty string)  
    set "or_="
    if not defined %%a set or_=true
    REM "!%%a: =!" trim all spaces (check var for empty value)
    if "!%%a: =!"=="" set or_=true
    if defined or_  (
        echo.%ESC%[41m     undefined: %%a%ESC%[0m   &REM  ^<ESC^>[35m [35mMagenta[0m
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



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Check for mandatory folders and files
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo.Проверка наличия необходимых файлов...

call :check_and_create_folder "%DST_steamcmd_dir%" confirm

call :check_and_create_folder "%DST_persistent_storage_root%"

call :check_and_create_folder "%DST_persistent_storage_root%\%DST_conf_dir%"


set file_not_found=

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

set cluster_folder_full_path=%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%
call :check_exist "%cluster_folder_full_path%"
if defined check_exist_notfoud (
    echo.
    echo.%ESC%[93mКластер %DST_cluster_folder% не найден.%ESC%[0m
    set /P AREYOUSURE="%ESC%[0mСоздать с параметрами по умолчанию? (Если "НЕТ", то просто выходим из скрипта) Y/[N]? "
    if /I "!AREYOUSURE!" NEQ "Y" (
        echo. & echo.    Просто выходим из скрипта  &REM Just exiting
        exit
    ) else (
        cd /D "%~dp0%!DST_my_mods_templates_folder!"
        echo.
        echo.    Select mods set:
        rem echo.        1. %ESC%[92mNo mods%ESC%[0m
        rem set var[1]=No Mods
        set /a i=0
        FOR /D %%G in ("*") DO (
            set /a i= !i!+1
            set var!i!=%%~nxG
            set dntemp=%%~nxG
            call :Trim dntemp
            echo.        !i!. !dntemp!
        )
        call :choice_trim 123456789 !i!
        CHOICE /T 21 /D 1 /C "!choice_trim_RESULT!"
        call :getvar var!ERRORLEVEL!
        echo "!result!"
        echo.    %ESC%[32m Генерируем конфигурацию кластера...%ESC%[0m%ESC%[46G : "!cluster_folder_full_path!"
        mkdir "!cluster_folder_full_path!"

        xcopy "%~dp0%!DST_cluster_templates_folder!\*.*" "!cluster_folder_full_path!\" /e>nul
        echo cluster_name = %cluster_name% >> !cluster_folder_full_path!\cluster.ini

        REM copy lua mods files to working dir (next run its will be copied to right places)
        copy "!result!\*.lua"  "!WORKING_DIR!\">nul
        echo.
        echo.     %ESC%[93mВНИМАНИЕ Сервер не будет запущен без вашего токена. %ESC%[0m
        echo.     %ESC%[93mВпишите токен в %temp_file%\cluster_token.txt%ESC%[0m
        echo.     %ESC%[93m^(копипаст либо скачайте с https://accounts.klei.com/login?goto=https://accounts.klei.com/account/game/servers^)%ESC%[0m
        echo.     %ESC%[93mСкрипт будет остановлен.%ESC%[0m
        pause & exit
    )
)

echo.debug
pause
exit



call :check_and_create_folder "%DST_persistent_storage_root%\%DST_my_mods%"
exit
call :check_and_create_folder "%DST_persistent_storage_root%\%DST_my_mods%\%DST_cluster_folder%"
exit

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
    set console_title_runtime=---   !CLUSTER_FULL_PATH!\!DST_shard!   ---   Started  !HH!:!MM!:!SS!   %DATE%   ---
    start "!HKCU_Console_Key!" cmd /C title !console_title_runtime! ^
        "& %DST_exe% " ^
            "-persistent_storage_root %DST_persistent_storage_root% " ^
            "-conf_dir %DST_conf_dir% " ^
            "-cluster %DST_cluster_folder%  " ^
            "-shard !DST_shard! ""
)
REM            :: -console has been deprecated Use the [MISC] / console_enabled setting instead. "-console " ^

timeout 25
exit



REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM
REM
REM                  END OF MAIN SCRIPT. ONLY FUNCTIONS BELOW
REM
REM
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: Hack for ERRORLEVEL (doesn't update inside control blocks).
:: (helper for dynamic variable name like !string%ERRORLEVEL%!
:getvar
    set result=!%1!
    exit /b


:: String trim. %1 is string, %2 is length
:choice_trim
    set choice_trim_RESULT=%1
    set choice_trim_RESULT=!choice_trim_RESULT:~0,%2!
    exit /b



:Trim
REM ltrim and rtrim whitespaces. %1 - variable NAME
    :ltrim
    if "!%1:~0,1!"==" " (set %1=!%1:~1!&goto ltrim)
    if "!%1:~0,1!"=="%TAB%" (set %1=!%1:~1!&goto ltrim)
    :rtrim
    if "!%1:~-1!"==" " (set %1=!%1:~0,-1!&goto rtrim)
    if "!%1:~-1!"=="%TAB%" (set %1=!%1:~0,-1!&goto rtrim)
    exit /b



:check_exist
REM check file/dir exist
REM Mandatory param - folder or file name
    set check_exist_notfoud=
    if "%2"=="rshift" (set spaces=      ) else (set spaces=   )
    if not exist %1 (
        echo.%spaces% %ESC%[41m Каталог/файл не найден %ESC%[0m%ESC%[46G : %1
        set check_exist_notfoud=TRUE
    ) else (
        echo.%spaces% %ESC%[92m Каталог/файл найден    %ESC%[0m%ESC%[46G : %1
    )
    exit /b



:check_and_create_folder
REM Check if folder exsit, try create non-existing folder.
REM If the folder cannot be created - script will be termitated inside function!
REM     Mandatory param: %1 - folder name.
REM     Optional param : %2 - if %2==confirm then confirmation will be asked.    
    call :check_exist %1
    if defined check_exist_notfoud (
        if "%2"=="confirm" (
            set /P AREYOUSURE="%ESC%[93m         Создать "%DST_steamcmd_dir%"? (Если "НЕТ", то просто выходим из скрипта) Y/[N]?%ESC%[0m "
            if /I "!AREYOUSURE!" NEQ "Y" (
                echo. & echo.    Просто выходим из скрипта  &REM Just exiting
                exit /b
            )
        ) 
        echo.       %ESC%[32m Пробуем создать...%ESC%[0m%ESC%[46G : %1
        mkdir "%1"
        call :check_exist %1 rshift
        if defined check_exist_notfoud (
            echo.        Невозможно создать папку %1. Продолжение невозможно.
            pause & exit
        )
    )
    exit /b



:timeout_with_keypress_detect
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Timeout with key press detect.
::
:: Mandatory parameter : seconds for timeout.
:: Return value        : key_pressed variable defined if key pressed
::                      (value - seconds when key was pressed).
::                       If key was not pressed - key_pressed is undefined.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    set time_to_out=%1
    set key_pressed=
    set /a SEC_BEFORE=1%TIME:~6,2% - 100
    timeout %time_to_out%
    set /a SEC_AFTER=1%TIME:~6,2%  - 100
    if %SEC_AFTER% GEQ %SEC_BEFORE% (set /a DIFF=%SEC_AFTER% - %SEC_BEFORE%) ^
        else (set /a DIFF=60 + %SEC_AFTER% - %SEC_BEFORE%)
    if %DIFF% LSS %time_to_out% (set /a key_pressed=%DIFF%)
    exit /b


REM
REM Mandatory param - config name
REM
:Generate_Config
(echo ^
[                                                                                             ]^

[   Конфигурационный файл для запуска скрипта StartDSTwithParams.cmd                          ]^

[   Секции используются только для наглядности. Все параметры загружаются одним списком.      ]^

[                                                                                             ]^

^

^

[FIRST_RUN]^

[   DST_cluster_templates_folder: default set of files for new cluster ^(as from Klei website^) ]^

[   DST_my_mods_templates_folder: Dir for mod's sets templates ^(up to 9 templates^)            ]^

[       For now "mod template" is 2 files: dedicated_server_mods_setup.lua, modoverrides.lua. ]^

[       During normal run ^(not first time^) this 2 files copies to right places every run.     ]^

[   Both folders are located inside script folder.                                            ]^

DST_cluster_templates_folder    = MyDediServerTemplate^

DST_my_mods_templates_folder    = MyModsTemplates^

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

[   DST_persistent_storage_root must be full-path                                             ]^

DST_persistent_storage_root  	= %cd%\KleiDedicated^

DST_conf_dir                 	= DoNotStarveTogether^

DST_cluster_folder             	= %new_cluster_folder%^

^

^

[SHARDS]^

[   space separated dirnames, dirname cannot include spaces                                   ]^

[   Example: Master Caves                                                                     ]^

[   First shard is master always. TODO: parse cluster.ini server.ini to find master           ]^

DST_shards                      = Master Caves^

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
