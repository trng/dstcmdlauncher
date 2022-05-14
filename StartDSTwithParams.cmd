@echo off
if "%~1" == "/goto" goto :%~2       &REM See :NewConsole label below for details
chcp 65001 > nul                    &REM Non-latin strings encoding

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Do not change structure of this line!
:: It's accessed with grep/find and splitted as "skip first 15 symbols and rest of the string will be version number".
set SCRIPT_VER=v1.2.6
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: WORKING_DIR - variable with folder by default for config file and cluster folder (changeable via .conf)
:: It MUST be set without EnableDelayedExpansion (with EnableDelayedExpansion sign "!" in the path will be big problem)
set WORKING_DIR=%cd%
::Todo: set WORKING_DIR from config file path from command line argument


:: Hack for define placeholders:  chr(09) to %TAB% (for ltrim | rtrim in :Trim)
::                                chr(27) to %ESC% (for echo coloring)
echo.091B33>%TEMP%\sdstwp & certUtil -decodeHex -f "%TEMP%\sdstwp" "%TEMP%\sdstwp" > nul & set /P SPECHAR=<"%TEMP%\sdstwp"
set TAB=%SPECHAR:~0,1%
set ESC=%SPECHAR:~1,1%


REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Check the status of 8.3
REM :: If 8.3 disabled on all volumes on the system - show warning
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
for /f "delims=" %%A in ('fsutil behavior query disable8dot3 ^| find /C ": 1"') do (
    if "%%A"=="1" (
        echo %ESC%[93mWARNING^!%ESC%[0m
        echo %ESC%[93m    Short names ^(8.3^) is disabled on all volumes on the system.%ESC%[0m
        echo %ESC%[93m    If you use non-Latin symbols, spaces, and some special symblos in files/folders names,%ESC%[0m
        echo %ESC%[93m    there may be problems.
        echo    ^(Script uses shortnames to resolve this trouble^).%ESC%[0m
        pause
    )
)


REM Check new version on github. If this script file has read-only attribute, the new version check will be skipped.
call :Trim SCRIPT_VER
set attributes=%~af0
setlocal EnableDelayedExpansion
if "!attributes:~1,1!"=="-" (
    del %TEMP%\sdstwp 2> nul & del %TEMP%\sdstwp2 2> nul
    curl -L -s -o "%TEMP%\sdstwp" "https://raw.githubusercontent.com/trng/dstcmdlauncher/main/StartDSTwithParams.cmd" > nul
    if exist "%TEMP%\sdstwp" findstr /b /l /c:"set SCRIPT_VER=" "%TEMP%\sdstwp" > "%TEMP%\sdstwp2" & set /P script_ver_online=<"%TEMP%\sdstwp2"
    if defined script_ver_online (
        call :Trim script_ver_online
        set script_ver_online=!script_ver_online:~15!
        if not "!SCRIPT_VER!"=="!script_ver_online!" (
            echo. & echo.
            echo.%ESC%[93mNew version availiable on github.%ESC%[0m
            echo.
            echo.    Running version  : "%SCRIPT_VER%"
            echo.    Version on github: "!script_ver_online!"
            echo.
            echo.What do you want to do:
            echo.    1. Continiue load dedicated server ^(default, 20 sec timeout^).
            echo.    2. Stop script and goto github.
            echo.    3. Do not check new versions in the future for this cluster ^(not recommended^).
            echo.
            echo | set /p=%ESC%[0m    [1,2,3]?
            CHOICE /T 20 /D 1 /C "123">nul
            if "!ERRORLEVEL!"=="2" (start explorer "https://github.com/trng/dstcmdlauncher" & exit)
            if "!ERRORLEVEL!"=="3" (
                echo.
                echo.
                echo.%ESC%[93mWARNING^^!^^!^^!%ESC%[0m
                echo.    To skip check new versions %ESC%[93mread-only attribute%ESC%[0m will be applied to this script.
                echo.    You can re-enable check for new version by removing read-only attribute.
                attrib.exe +R "%~0"
                echo.
                pause
            )
        )
    )
)
setlocal DisableDelayedExpansion 

if %~1.==. (
    set "ServerConfigFile=%WORKING_DIR%\StartDSTwithParams.conf"
) else (
    set ServerConfigFile=%~1
)

echo.
echo.
echo.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Check for config file (use existing or generate new)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
if exist "%ServerConfigFile%" (
    call :stupid_echo "Конфигурационный файл найден   %ESC%[46G : '%ServerConfigFile%'"     &REM Configuration file found
    echo.
) else (
    echo.
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.::::                                                                 ::::
    echo.::::    StartDSTwithParams %SCRIPT_VER%                    %ESC%[69G ::::
    echo.::::    Copyright ^(c^) trng                                           ::::
    echo.::::                                                                 ::::
    echo.::::                                                                 ::::
    echo.::::    Скрипт запуска выделенного сервера Don't Starve together.    ::::
    echo.::::    Для запуска обязательно наличие конфигурационного файла.     ::::
    echo.::::    Два варианта запуска скрипта:                                ::::
    echo.::::                                                                 ::::
    echo.::::        1. StartDSTwithParams.cmd                                ::::
    echo.::::          ^(используется дефолтное имя: StartDSTwithParams.conf^)  ::::
    echo.::::                                                                 ::::
    echo.::::        2. StartDSTwithParams.cmd config_file_name.conf          ::::
    echo.::::                                                                 ::::
    echo.::::    Если файла конфигурации с таким именем не существует,        ::::
    echo.::::    генерируется конфиг с дефолтными параметрами.                ::::
    echo.::::                                                                 ::::
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.
    pause
    echo. & echo. & echo. & echo.
    call :stupid_echo "%ESC%[41mКонфигурационный файл ^( %ServerConfigFile% ^) не найден.%ESC%[0m"
    echo. 
    setlocal EnableDelayedExpansion
    set /P AREYOUSURE="Создать с параметрами по умолчанию? (Если "НЕТ", то просто выходим из скрипта) [Y]/N? "
    if /I "!AREYOUSURE!" EQU "N" (
        echo. & echo.    Просто выходим из скрипта  &REM Just exiting
        exit /b
    ) else (
:Get_Cluster_Name_again
        echo.
        set /p cluster_name="%ESC%[93mCluster Name:%ESC%[0m "
        echo.
        echo.%ESC%[0m
        if not defined cluster_name (
            echo.    %ESC%[41mИмя кластера не может быть пустым. Попробуйте еще раз либо Ctrl-C для выхода...%ESC%[0m
            goto :Get_Cluster_Name_again
            pause & exit
        )
        set cluster_name=!cluster_name:"=!
        call :Trim cluster_name
        set new_cluster_folder=!cluster_name!

        setlocal DisableDelayedExpansion 
        call :stupid_echo "%ESC%[32m     Пробуем создать...%ESC%[0m%ESC%[46G : '%ServerConfigFile%'"
        call :Generate_Config "%ServerConfigFile%"
        call :check_exist "%ServerConfigFile%"

        if defined check_exist_notfoud (
            echo.Невозможно создать конфигурационный файл "%ServerConfigFile%".
            echo.Выходим из скрипта.
            pause & exit
        )
        set NewConfigCreated=True
    )
)
if not defined NewConfigCreated set cluster_name=Stupid trouble with undefined variable below


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Load parameters from ServerConfigFile into local variables
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo. & echo.Пробуем загрузить параметры...                &REM Trying to load

REM setlocal EnableDelayedExpansion
for /f "usebackq delims== tokens=1,2 eol=[" %%a in ("%ServerConfigFile%") do (
    setlocal DisableDelayedExpansion
    call :setkey %%a
    call :setval %%b
)
setlocal EnableDelayedExpansion


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

setlocal DisableDelayedExpansion

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Check for mandatory folders and files
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo.Проверка наличия необходимых файлов...

call :check_and_create_folder "%DST_steamcmd_dir%" confirm
REM call :Ocheck_and_create_folder "!WORKING_DIR!\!DST_persistent_storage_root!"
call :check_and_create_folder "%WORKING_DIR%\%DST_persistent_storage_root%\%DST_conf_dir%"
set file_not_found=

set temp_file_name=%DST_steamcmd_dir%\steamcmd.exe
call :check_exist "%temp_file_name%"

if defined check_exist_notfoud (
    echo.    %ESC%[93m Пробуем скачать...%ESC%[0m%ESC%[46G : steamcmd.exe
    curl -L -s -o %DST_steamcmd_dir%\steamcmd.zip https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip>nul
    tar -xf %DST_steamcmd_dir%\steamcmd.zip -C %DST_steamcmd_dir%>nul
    del %DST_steamcmd_dir%\steamcmd.zip>nul
    if not exist "%temp_file_name%" (
        set file_not_found=TRUE
        echo.    %ESC%[41m Не удалось скачать %ESC%[0m%ESC%[46G : steamcmd.exe
    ) else (
        set file_not_found=
        echo.    %ESC%[92m Удалось скачать    %ESC%[0m%ESC%[46G : steamcmd.exe
    )
)

::
::
set CLUSTER_FOLDER_FULL_PATH=%WORKING_DIR%\%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%
::
::

call :check_exist "%CLUSTER_FOLDER_FULL_PATH%"
if not defined check_exist_notfoud (
    REM cluster exist
    if defined NewConfigCreated (
        REM cluster exist AND new config generated.
        echo.
        echo.
        echo.%ESC%[93mКластер с таким именем уже существует.%ESC%[0m
		echo.%ESC%[93mБудет использован новый конфигурационный файл с существующим кластером.%ESC%[0m
        setlocal EnableDelayedExpansion
        set AREYOUSURE=
        set /P AREYOUSURE="Продолжить? (Если "НЕТ", то просто выходим из скрипта) Y/[N]? "
        if /I "!AREYOUSURE!" NEQ "Y" (
            echo. & echo.    Просто выходим из скрипта  &REM Just exiting
            exit
        )
        setlocal DisableDelayedExpansion
    )
) else (
    echo.
    echo.
    call :stupid_echo "%ESC%[93mКластер не найден         %ESC%[46G : '%DST_cluster_folder%'.%ESC%[0m"
    call :stupid_echo "%ESC%[32m(Создаем с параметрами по умолчанию)%ESC%[0m"
    echo.
   
    echo.        Проверяем наличие шаблонов для модов
    call :check_exist "%~dp0%DST_my_mods_templates_folder%" rshift
    if defined check_exist_notfoud (
        echo.%ESC%[41m    Mod set templates folder "%DST_my_mods_templates_folder%" not found. Add mods manually.%ESC%[0m
    ) else (
        cd /D "%~dp0%DST_my_mods_templates_folder%"
        echo.
        echo.%ESC%[93m        Select mods set:%ESC%[0m
        set /a i=0
        setlocal EnableDelayedExpansion
        FOR /D %%G in ("*") DO (
            set /a i= !i!+1
            set var!i!=%%~nxG
            set dntemp=%%~nxG
            call :Trim dntemp
            call :stupid_echo "          !i!. !dntemp!"
        )
        call :choice_trim 123456789 !i!
        CHOICE /T 31 /D 1 /C "!choice_trim_RESULT!"
        call :getvar var!ERRORLEVEL!
        echo.
        call :stupid_echo "%ESC%[32m        Template для модов%ESC%[0m%ESC%[46G : %ESC%[93m!result!%ESC%[0m"
        set selected_mods=%ESC%[0G::::%ESC%[32m  Template для модов%ESC%[0m%ESC%[46G : !result!
		REM copy lua mods files to working dir (every next run its will be copied to right places)
        setlocal DisableDelayedExpansion
        copy "%result%\*.lua"  "%WORKING_DIR%\">nul
    ) 
    mkdir "%CLUSTER_FOLDER_FULL_PATH%"
    call :stupid_echo "%ESC%[32m        Генерируем конфигурацию кластера...%ESC%[0m%ESC%[46G : '%CLUSTER_FOLDER_FULL_PATH%'"
    xcopy "%~dp0%DST_cluster_templates_folder%\*.*" "%CLUSTER_FOLDER_FULL_PATH%\" /E>nul
    cd /D "%CLUSTER_FOLDER_FULL_PATH%"
	if not defined NewConfigCreated ( 
		REM Old config used. No Cluster name at this point availible.
		REM Cluster name stored in cluster.ini, but if we are here - new cluster will be generated with old config.
		REM So we need Cluster name. 2 variants: ask user, or use DST_cluster_folder as Cluster name.
		REM Since this situation is quite rare and Cluster name can be changed later in cluster.ini,
		REM we will use DST_cluster_folder without asking user
        call :save_cluster_name_to_ini "cluster_name = %DST_cluster_folder%"
        set stupid_cluster_name="%ESC%[0G::::  %ESC%[32mИмя кластера (видно в списке серверов) %ESC%[0m%ESC%[46G : %DST_cluster_folder%"%ESC%[1D 
	) else (
        call :save_cluster_name_to_ini "cluster_name = %cluster_name%"
        set stupid_cluster_name="%ESC%[0G::::  %ESC%[32mИмя кластера (видно в списке серверов) %ESC%[0m%ESC%[46G : %cluster_name%"%ESC%[1D 
    )
    rem setlocal EnableDelayedExpansion 
    echo.
    echo.   
    echo.   
    echo.::::
    echo.::::
    echo.::::
    echo.::::  %ESC%[92mКонфигурация создана успешно^!^!^!%ESC%[0m
    echo.::::
    set stupid_cluster_name
    set selected_mods
REM    set tmpstr=%ESC%[0G::::  %ESC%[32mПапка с настройками сервера %ESC%[0m%ESC%[46G : "%CLUSTER_FOLDER_FULL_PATH%"
REM    set tmpstr
    echo.::::  %ESC%[32mПапка с настройками сервера %ESC%[0m%ESC%[46G : "%CLUSTER_FOLDER_FULL_PATH%"
    echo.::::  %ESC%[32mКонфигурация скрипта %ESC%[0m%ESC%[46G : "%ServerConfigFile%"
    echo.::::  %ESC%[32mФайлы настройки модов находятся в%ESC%[0m%ESC%[46G : "%WORKING_DIR%\"
    echo.::::   
    echo.::::   
    echo.::::  При добавлении модов не забывайте менять оба файла:
    echo.::::        - dedicated_server_mods_setup.lua
    echo.::::        - modoverrides.lua
    echo.::::   
    echo.::::   
    echo.::::  %ESC%[93mВНИМАНИЕ ^!^!^!%ESC%[0m
    echo.::::  %ESC%[93mСервер не будет запущен без вашего токена^!%ESC%[0m
    echo.::::  Впишите токен в cluster_token.txt
    echo.::::  Копипаст либо скачайте с
    echo.::::  https://accounts.klei.com/login?goto=https://accounts.klei.com/account/game/servers?game=DontStarveTogether
    echo.::::
    echo.::::
    echo.::::   
    echo.
    echo.
    echo.%ESC%[93mСейчас скрипт будет остановлен.%ESC%[0m
    setlocal EnableDelayedExpansion
    set AREYOUSURE=
    set /P AREYOUSURE="Открыть cluster_token.txt в Блокноте? (Если "НЕТ", то просто выходим из скрипта) Y/[N]? "
    if /I "!AREYOUSURE!"=="Y" (
        setlocal DisableDelayedExpansion
        start notepad.exe "%CLUSTER_FOLDER_FULL_PATH%\cluster_token.txt"
        REM call :stupid_start
    )
    exit /b
) 


set master_shard=
for %%a in (%DST_shards%) do (
    call :check_exist "%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%\%%a"
    if not defined master_shard (set master_shard=%%a) &REM first shard is master shard
)

if defined file_not_found (
    echo.
    echo.Не найдены папки для шардов.
    echo.Скрипт будет остановлен.  
    pause & exit /b
)


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Shard's Loop (search running shards)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

REM find existing
echo.
set shard_title_common_part=%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%
set "cmd=tasklist /FI "IMAGENAME eq cmd.exe" /v /fo csv ^| find "%shard_title_common_part%""
for /F "usebackq tokens=2,9 delims=," %%p in (`%cmd%`) do (
    setlocal EnableDelayedExpansion
    set pid_with_quotes=%%p
    set pid_without_quotes=!pid_with_quotes:"=!
    set !pid_without_quotes!=%%q
    set pids_list=!pids_list! !pid_without_quotes!
    setlocal DisableDelayedExpansion
)


if defined pids_list (
    echo.
    echo.%ESC%[41m ----------------------            ВНИМАНИЕ ^!^!^!           ---------------------- %ESC%[0m    &REM WARNING
    echo.%ESC%[41m ----------------------      Найдены запущенные шарды     ---------------------- %ESC%[0m          &REM Running shards found  
    echo.
    for %%a in (%pids_list%) do (
        setlocal EnableDelayedExpansion
        set aaaaa=!%%a:--=!
        echo %%a: !aaaaa:  =!
        setlocal DisableDelayedExpansion
        REM taskkill /PID %%a
    )
    echo.
    REM set /P AREYOUSURE="Kill running shards (if "NO" script will exit immediately) Y/[N] ?"
    set /P AREYOUSURE="Шарды уже запущены! Остановить их? (Если "НЕТ", то просто выходим из скрипта) Y/[N]? "
    setlocal EnableDelayedExpansion
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
    setlocal DisableDelayedExpansion
)



:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Start steamcmd.exe. Load/update/validate DST application.
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

start "Start steamcmd for load/update/validate DST dedicated server application." cmd /c "%0" /goto NewConsole
timeout 5
exit

:NewConsole
call :StupidCmdBreaksEscSequences
echo.
echo.
echo.Start steamcmd for load/update/validate DST dedicated server application.
echo.
echo.
echo.Press any key to skip load/update/validate game and mods
echo.^(you will be jumped to shard's load^).
echo.
echo.%ESC%[93mWarning^!^!^!  Only do this if you are absolutely sure what are you doing!%ESC%[0m
echo.
echo.
call :timeout_with_keypress_detect 15
if not defined key_pressed (
    %DST_steamcmd_dir%\steamcmd.exe +login anonymous +app_update 343050 validate +quit
)


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Run shards
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

cd /D "%DST_steamcmd_dir%/%DST_dst_bin%"


REM Copy 2 mods files: to dst bin and to cluster shards (inside shards loop)
copy "%WORKING_DIR%\dedicated_server_mods_setup.lua" ..\mods\

for %%a in (%DST_shards%) do (
    copy "%WORKING_DIR%\modoverrides.lua"  "%CLUSTER_FOLDER_FULL_PATH%\%%a\"
    setlocal EnableDelayedExpansion
    set HKCU_Console_Key=!DST_cluster_folder!_%%a
    if defined HKCU_Console_Key reg delete "hkcu\console\!HKCU_Console_Key!" /f 2>nul
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
                reg add "hkcu\console\!HKCU_Console_Key!" /v WindowPosition /t REG_DWORD /d "!pos!" /f 2>nul
            ) else (
                REM  Y coord not defined
            )
        ) else (
            REM X coord not defined
        )
    )
    setlocal DisableDelayedExpansion
    call :set_very_long_command "%%a"

)

timeout 25
exit /b



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



:setkey
    set setkey_result=%1
    rem echo "%setkey_result%"
    exit /b

:setval
    set setval_result=%*
    set "%setkey_result%=%setval_result%"
    exit /b


:: Hack for ERRORLEVEL (doesn't updates inside control blocks).
:: (helper for dynamic variable name like !string%ERRORLEVEL%!
:getvar
    set result=!%1!
    exit /b


:: String trim. %1 is string, %2 is length
:choice_trim
    set choice_trim_RESULT=%1
    set choice_trim_RESULT=!choice_trim_RESULT:~0,%2!
    exit /b


:stupid_echo
    :: %~1 used! String must be double quoted!
    echo %~1
    exit /b


:convertTo8.3
:: %~1                  - path
:: convertTo8.3_result  - if it possible, path converted to 8.3, if no - return %1
    for %%A in ("%~1") do set convertTo8.3_result=%%~sA
    exit /b


:convertTo8.3onlyfilename
:: %~1                  - path (doublequoted!)
:: convertTo8.3_result  - if it possible, path converted to 8.3, if no - return %1
    call :c83ofn_helper "%~s1"
    exit /b

:c83ofn_helper
    set convertTo8.3onlyfilename_result=%~n1
    exit /b


:set_very_long_command
:: %~1  -->    "!DST_shard!"
:: start title must be equal to HKCU_Console_Key   -->   %DST_cluster_folder%_%%a
    set HH=%TIME: =0%
    set HH=%HH:~0,2%
    set MM=%TIME:~3,2%
    set SS=%TIME:~6,2%
    set console_title_runtime=---   %DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%\%~1   ---   Started  %HH%:%MM%:%SS%   %DATE%   ---

    call :convertTo8.3onlyfilename "%CLUSTER_FOLDER_FULL_PATH%"
    call :convertTo8.3 "%WORKING_DIR%\%DST_persistent_storage_root%"
    :: -console has been deprecated Use the [MISC] / console_enabled setting instead.
    set very_long_command="title %console_title_runtime% && %DST_exe%  -persistent_storage_root %convertTo8.3_result% -conf_dir %DST_conf_dir%  -cluster %convertTo8.3onlyfilename_result%  -shard %~1"
    start "%DST_cluster_folder%_%~1" cmd /C %very_long_command%
    exit /b


:save_cluster_name_to_ini
    echo %~1 >>"cluster.ini"
    exit /b



:StupidCmdBreaksEscSequences
:: A hack against various console commands that break escape sequences for no apparent reason.
:: Its very similar like this commands call Win32 function SetConsoleMode 
:: and reset terminal with ENABLE_VIRTUAL_TERMINAL_INPUT ENABLE_VIRTUAL_TERMINAL_PROCESSING flags
:: But after call to any label with "exit /b" termial begin execute escape sequences again.
:: 
:: A hack against various console commands that break escape sequences for no apparent reason.
:: Its very similar like this commands call Win32 function SetConsoleMode and
:: reset terminal with cleared flags ENABLE_VIRTUAL_TERMINAL_INPUT ENABLE_VIRTUAL_TERMINAL_PROCESSING.
:: But after call to any label with "exit /b" current termial begin execute escape sequences again.
    exit /b

:Trim
REM ltrim and rtrim whitespaces. %1 - variable NAME (input and output)
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
    if "%~2"=="rshift" (set spaces=      ) else (set spaces=   )
    if not exist "%~1" (
        echo.%spaces% %ESC%[41m Каталог/файл не найден %ESC%[0m%ESC%[46G : "%~1"
        set check_exist_notfoud=TRUE
    ) else (
        echo.%spaces% %ESC%[92m Каталог/файл найден    %ESC%[0m%ESC%[46G : "%~1"
    )
    exit /b



:check_and_create_folder
REM Check if folder exsit, try create non-existing folder.
REM If the folder cannot be created - script will be termitated inside function!
REM     Mandatory param: %1 - folder name.
REM     Optional param : %2 - if %2==confirm then confirmation will be asked.    
    call :check_exist "%~1"
    if defined check_exist_notfoud (
        if "%~2"=="confirm" (
            echo.%ESC%[93m         Создать "%~1"?%ESC%[0m
            set AREYOUSURE=
            set /P AREYOUSURE="%ESC%[93m     (Если "НЕТ", то просто выходим из скрипта) Y/[N]?%ESC%[0m"
            if /I "!AREYOUSURE!" NEQ "Y" (
                echo. & echo.    Просто выходим из скрипта  &REM Just exiting
                exit /b
            )
        )
        echo.        %ESC%[32mПробуем создать... %ESC%[0m%ESC%[46G : "%~1"
        mkdir "%~1"
        call :check_exist "%~1" rshift
        if defined check_exist_notfoud (
            echo.        Невозможно создать папку "%~1". Продолжение невозможно.
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


:Generate_Config
REM
REM Mandatory param %1 - config file name
REM
:: trouble with ")" - it cannot be echoed without escaping
set "new_cluster_folder_escaped=%new_cluster_folder:)=^)%"
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

DST_steamcmd_dir    		    = %USERPROFILE%\steamcmd^

DST_dst_bin                  	= steamapps\common\Don't Starve Together Dedicated Server\bin64^

DST_exe                         = dontstarve_dedicated_server_nullrenderer_x64.exe^

^

^

[SERVER]^

[   Parameters for dontstarve_dedicated_server_nullrenderer executable.                       ]^

[   3 nested dirs.                                                                            ]^

[    DST_persistent_storage_root relative to current dir ^(defined in WORKING_DIR varable^):    ]^

[    WORKING_DIR/DST_persistent_storage_root/DST_conf_dir/DST_cluster_folder                  ]^

DST_persistent_storage_root  	= KleiDedicated^

DST_conf_dir                 	= DoNotStarveTogether^

DST_cluster_folder             	= %new_cluster_folder_escaped%^

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
