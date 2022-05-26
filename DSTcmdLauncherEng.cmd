@echo off
if "%~1" == "/goto" goto :%~2       &REM See :NewConsole label below for details
chcp 65001 > nul                    &REM Non-latin strings encoding

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Do not change structure of this line!
:: It's accessed with grep/find and splitted as "skip first 15 symbols and rest of the string will be version number".
set SCRIPT_VER=v1.2.19
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: WORKING_DIR - variable with folder by default for config file and cluster folder (changeable via .conf)
:: It MUST be set without EnableDelayedExpansion (with EnableDelayedExpansion sign "!" in the path will be big problem)
:: It can be changed later if the config file is specified with a full path
set WORKING_DIR=%cd%


:: Hack for define placeholders:  chr(09) to %TAB% (for ltrim | rtrim in :Trim)
::                                chr(27) to %ESC% (for echo coloring)
echo.091B33>%TEMP%\sdstwp & certUtil -decodeHex -f "%TEMP%\sdstwp" "%TEMP%\sdstwp" > nul & set /P SPECHAR=<"%TEMP%\sdstwp"
set TAB=%SPECHAR:~0,1%
set ESC=%SPECHAR:~1,1%

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Check the status of 8.3 on the system
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
    curl -L -s -o "%TEMP%\sdstwp" "https://raw.githubusercontent.com/trng/dstcmdlauncher/main/StartDSTwithParamsRus.cmd" > nul
    if exist "%TEMP%\sdstwp" findstr /b /l /c:"set SCRIPT_VER=" "%TEMP%\sdstwp" > "%TEMP%\sdstwp2" & set /P script_ver_online=<"%TEMP%\sdstwp2"
    if defined script_ver_online (
        call :Trim script_ver_online
        set script_ver_online=!script_ver_online:~15!
        if not "!SCRIPT_VER!"=="!script_ver_online!" (
            echo. & echo.
            echo %ESC%[93mDSTcmdLauncher%ESC%[0m
            echo.%ESC%[93mNew version availiable on github.%ESC%[0m
            echo.
            echo.    Running version   : "%SCRIPT_VER%"
            echo.    Version on github : "!script_ver_online!"
            echo.
            echo.What do you want to do:
            echo.    1. Continiue load dedicated server ^(default, 20 sec timeout^).
            echo.    2. Stop script and goto github.
            echo.    3. Do not check new versions in the future for this cluster ^(not recommended^).
            echo.
            echo | set /p=%ESC%[0m    [1,2,3]?
            CHOICE /T 20 /D 1 /C "123">nul
            echo.
            echo.
            if "!ERRORLEVEL!"=="2" (start explorer "https://github.com/trng/dstcmdlauncher" & goto :EOF)
            if "!ERRORLEVEL!"=="3" (
                echo.
                echo.
                echo.%ESC%[93mATTENTION^^!^^!^^!%ESC%[0m
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
if "%~s1"=="" (
    set "ServerConfigFile=%WORKING_DIR%\DSTcmdLauncher.conf"
) else (
    set "WORKING_DIR=%~dp1"
    set "ServerConfigFile=%~f1"
)

call :set_working_drive "%WORKING_DIR%"
goto :end_of_working_drive

:set_working_drive
    set WORKING_DRIVE=%~d1
    exit /b

:end_of_working_drive


REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Check the status of 8.3 on drive with config
REM :: If 8.3 disabled on all volumes on the system - show warning
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

for /f "delims=" %%A in ('fsutil behavior query disable8dot3 %WORKING_DRIVE% ^| find /C ": 1"') do (
    if "%%A"=="1" (
        echo %ESC%[93mATTENTION^!%ESC%[0m
        echo %ESC%[93m    Short names ^(8.3^) is disabled on working volume.%ESC%[0m
        echo %ESC%[93m    If you use non-Latin symbols, spaces, and some special symblos%ESC%[0m
        echo %ESC%[93m    in files and folders names - there may be problems.
        echo    ^(Script uses shortnames to resolve this trouble^).%ESC%[0m
        pause
    )
)

echo. & echo. & echo.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Check for config file (use existing or generate new)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
if exist "%ServerConfigFile%" (
    call :stupid_echo "Configuration file found   %ESC%[46G : '%ServerConfigFile%'"
    echo.
) else (
    echo.
    echo.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.::::                                                                            ::::
    echo.::::    DSTcmdLauncher  %SCRIPT_VER%                                  %ESC%[80G ::::
    echo.::::    Copyright ^(c^) trng                                          %ESC%[80G ::::
    echo.::::                                                                            ::::
    echo.::::                                                                            ::::
    echo.::::    Script to start a dedicated server Don't Starve together.     %ESC%[80G ::::
    echo.::::    Configuraton file must exist for server start.                %ESC%[80G ::::
    echo.::::    Two ways to run the script:                                   %ESC%[80G ::::
    echo.::::                                                                            ::::
    echo.::::        1. DSTcmdLauncherXXX.cmd                                  %ESC%[80G ::::
    echo.::::          ^(default name used         : DSTcmdLauncher.conf^)     %ESC%[80G ::::
    echo.::::                                                                            ::::
    echo.::::        2. DSTcmdLauncherXXX.cmd  config_file_name.conf           %ESC%[80G ::::
    echo.::::                                                                            ::::
    echo.::::    If no config file found with this name,                       %ESC%[80G ::::
    echo.::::    config with default params will be generated.                 %ESC%[80G ::::
    echo.::::                                                                            ::::
    echo.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.
    pause
    echo. & echo. & echo. & echo.
    call :stupid_echo "%ESC%[41m Configuration file ( %ServerConfigFile% ) not found. %ESC%[0m"
    echo. 
    setlocal EnableDelayedExpansion
    set /P AREYOUSURE="Create with default params? (If "NO" - just exit from script) [Y]/N? "
    if /I "!AREYOUSURE!" EQU "N" (
        echo. & echo.    Just exiting ^(from script^)
        goto :EOF
    ) else (
:Get_Cluster_Name_again
        echo.
        set /p cluster_name="%ESC%[93mCluster Name:%ESC%[0m "
        echo.
        echo.%ESC%[0m
        if not defined cluster_name (
            echo.    %ESC%[41mCluster name cannot be empty. Try again or Ctrl-C for exit...%ESC%[0m
            goto :Get_Cluster_Name_again
            pause & goto :EOF
        )
        set cluster_name=!cluster_name:"=!
        call :Trim cluster_name
        set new_cluster_folder=!cluster_name!

        setlocal DisableDelayedExpansion 
        call :stupid_echo "%ESC%[32m     Trying to create...%ESC%[0m%ESC%[46G : '%ServerConfigFile%'"
        call :check_and_create_folder "%WORKING_DIR%"
        call :Generate_Config "%ServerConfigFile%"
        call :check_exist "%ServerConfigFile%"

        if defined check_exist_notfoud (
            echo.Cannot create config file "%ServerConfigFile%".
            echo.Just exiting ^(from script^).
            pause & goto :EOF
        )
        set NewConfigCreated=True
    )
)
if not defined NewConfigCreated set cluster_name=Stupid trouble with undefined variable below


REM 
REM If config specified with full path in command line, we should change working dir.
REM 
cd /D "%WORKING_DIR%"


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Load parameters from ServerConfigFile into local variables
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo. & echo.Trying to load parameters...

for /f "usebackq delims== tokens=1,2 eol=#" %%a in ("%ServerConfigFile%") do (
    setlocal DisableDelayedExpansion
    call :setkey %%a
    call :setval %%b
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Checking is all required parameters are present in config file
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set mandatory_params=DST_steamcmd_dir DST_dst_bin DST_exe DST_persistent_storage_root DST_conf_dir DST_cluster_folder DST_shards DST_my_mods_templates_folder DST_cluster_templates_folder
setlocal EnableDelayedExpansion
for %%a in (%mandatory_params%) do (
    REM trick for OR statement (%%a not defined OR %%a is empty string)  
    set "or_="
    if not defined %%a set or_=true
    REM "!%%a: =!" trim all spaces (check var for empty value)
    if "!%%a: =!"=="" set or_=true
    if defined or_  (
        echo.%ESC%[41m     undefined: %%a%ESC%[0m
        set noargs=!noargs!  "%%a"
    ) else (
        echo.     %ESC%[92m^defined%ESC%[0m  : %ESC%[32m%%a%ESC%[0m %ESC%[46G = !%%a!
    )
)

echo.
if defined noargs (
    echo.%ESC%[41m^Additional parameters needed: %noargs%%ESC%[0m 
    echo.
    echo.%ESC%[41m^Script will be stopped.%ESC%[0m
    echo.
    pause & goto :EOF
)
setlocal DisableDelayedExpansion

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Check for mandatory folders and files
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo.
echo.Checking for required files...

call :check_and_create_folder "%DST_steamcmd_dir%" confirm || goto :eof
call :check_and_create_folder "%WORKING_DIR%\%DST_persistent_storage_root%\%DST_conf_dir%" || goto :eof

set file_not_found=

set temp_file_name=%DST_steamcmd_dir%\steamcmd.exe
call :check_exist "%temp_file_name%"

if defined check_exist_notfoud (
    echo.    %ESC%[93m Trying to load...%ESC%[0m%ESC%[46G : steamcmd.exe
    curl -L -s -o %DST_steamcmd_dir%\steamcmd.zip https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip>nul
    tar -xf %DST_steamcmd_dir%\steamcmd.zip -C %DST_steamcmd_dir%>nul
    del %DST_steamcmd_dir%\steamcmd.zip>nul
    if not exist "%temp_file_name%" (
        set file_not_found=TRUE
        echo.    %ESC%[41m Failed to download %ESC%[0m%ESC%[46G : steamcmd.exe
    ) else (
        set file_not_found=
        echo.    %ESC%[92m File downloaded    %ESC%[0m%ESC%[46G : steamcmd.exe
    )
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: this var used many times below
set CLUSTER_FOLDER_FULL_PATH=%WORKING_DIR%\%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :check_exist "%CLUSTER_FOLDER_FULL_PATH%"
if not defined check_exist_notfoud (
    REM cluster exist
    if defined NewConfigCreated (
        REM cluster exist AND new config generated.
        echo.
        echo.
        echo.%ESC%[93mCluster with the same name already exist.%ESC%[0m
		echo.%ESC%[93mNew config file with existing cluster will be used%ESC%[0m
        setlocal EnableDelayedExpansion
        set AREYOUSURE=
        set /P AREYOUSURE="Continiue? (If "NO" - just exit from script)) Y/[N]? "
        if /I "!AREYOUSURE!" NEQ "Y" (
            echo. & echo.    Just exiting ^(from script^)
            goto :EOF
        )
        setlocal DisableDelayedExpansion
    )
) else (
    echo.
    echo.
    call :stupid_echo "%ESC%[93mCluster not found         %ESC%[46G : '%DST_cluster_folder%'%ESC%[0m"
    call :stupid_echo "%ESC%[32m(Create with default parameters)%ESC%[0m"
    echo.
   
    echo.     Checking for mods templates availability
    call :check_exist "%~dp0%DST_my_mods_templates_folder%" rshift
    if defined check_exist_notfoud (
        set selected_mods=%ESC%[0G::::%ESC%[32m  Template for mods%ESC%[0m%ESC%[46G : -
        echo.
        echo.       %ESC%[41m Mods sets folder "%DST_my_mods_templates_folder%" not found. Add mods manually later. %ESC%[0m
        echo.
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
        call :stupid_echo "%ESC%[32m        Template for mods%ESC%[0m%ESC%[46G : %ESC%[93m!result!%ESC%[0m"
        set selected_mods=%ESC%[0G::::%ESC%[32m  Template for mods%ESC%[0m%ESC%[46G : !result!
		REM copy lua mods files to working dir (every next run its will be copied to right places)
        cd !result!
        setlocal DisableDelayedExpansion
        copy "*.lua"  "%WORKING_DIR%\">nul
    ) 
    mkdir "%CLUSTER_FOLDER_FULL_PATH%"
    echo.
    call :stupid_echo "%ESC%[32m     Generating the cluster configuration...%ESC%[0m%ESC%[46G : '%CLUSTER_FOLDER_FULL_PATH%'"
    xcopy "%~dp0%DST_cluster_templates_folder%\*.*" "%CLUSTER_FOLDER_FULL_PATH%\" /E>nul
    cd /D "%CLUSTER_FOLDER_FULL_PATH%"
	if not defined NewConfigCreated ( 
		REM Old config used. No Cluster name at this point availible.
		REM Cluster name stored in cluster.ini, but if we are here - new cluster will be generated with old config.
		REM So we need Cluster name. 2 variants: ask user, or use DST_cluster_folder as Cluster name.
		REM Since this situation is quite rare and Cluster name can be changed later in cluster.ini,
		REM we will use DST_cluster_folder without asking user
        call :save_cluster_name_to_ini "cluster_name = %DST_cluster_folder%"
        set stupid_cluster_name="%ESC%[0G::::  %ESC%[32mCluster name (showed in servers list) %ESC%[0m%ESC%[46G : %DST_cluster_folder%"%ESC%[1D 
	) else (
        call :save_cluster_name_to_ini "cluster_name = %cluster_name%"
        set stupid_cluster_name="%ESC%[0G::::  %ESC%[32mCluster name (showed in servers list) %ESC%[0m%ESC%[46G : %cluster_name%"%ESC%[1D 
    )
    rem setlocal EnableDelayedExpansion 
    echo. & echo. & echo.   
    echo.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.::::
    echo.::::  %ESC%[92mConfiguration successfully created^!^!^!%ESC%[0m
    echo.::::
    set stupid_cluster_name
    set selected_mods
    echo.::::  %ESC%[32mFolder with server config %ESC%[0m%ESC%[46G : "%CLUSTER_FOLDER_FULL_PATH%"
    echo.::::  %ESC%[32mScript config file %ESC%[0m%ESC%[46G : "%ServerConfigFile%"
    echo.::::  %ESC%[32mMods configuration files are located in%ESC%[0m%ESC%[46G : "%WORKING_DIR%\"
    echo.::::   
    echo.::::   
    echo.::::  When adding mods, do not forget to change both files:
    echo.::::        - dedicated_server_mods_setup.lua
    echo.::::        - modoverrides.lua
    echo.::::   
    echo.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    echo. & echo. & echo.
    echo.%ESC%[93mATTENTION ^!^!^!%ESC%[0m
    echo.%ESC%[93mServer will not start without your token^!%ESC%[0m
    echo.Write down the token in cluster_token.txt
    echo.Copy-paste or download from
    echo.https://accounts.klei.com/login?goto=https://accounts.klei.com/account/game/servers?game=DontStarveTogether
    echo. & echo. & echo. & echo. & echo.
    echo.%ESC%[93mScript will be stopped now.%ESC%[0m
    setlocal EnableDelayedExpansion
    set AREYOUSURE=
    set /P AREYOUSURE="Open cluster_token.txt in notepad? (If "NO" - just exit from script) Y/[N]? "
    if /I "!AREYOUSURE!"=="Y" (
        setlocal DisableDelayedExpansion
        start notepad.exe "%CLUSTER_FOLDER_FULL_PATH%\cluster_token.txt"
        REM call :stupid_start
    )
    goto :EOF
) 

set master_shard=
for %%a in (%DST_shards%) do (
    call :check_exist "%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%\%%a"
    if not defined master_shard (set master_shard=%%a) &REM first shard is master shard
)

if defined file_not_found (
    echo.
    echo.Shards folders not found.
    echo.Script will be stopped.  
    pause & goto :EOF
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Shard's Loop (search running shards)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM find existing
echo.
set shard_title_common_part=%DST_persistent_storage_root%\%DST_conf_dir%\%DST_cluster_folder%
set "cmd=tasklist /FI "IMAGENAME eq cmd.exe" /v /fo csv ^| find "%shard_title_common_part%""
:check_runnig_shards_again
set "pids_list="
for /F "usebackq tokens=2,9 delims=," %%p in (`%cmd%`) do (
    setlocal EnableDelayedExpansion
    if not defined first_time_loop (
        set first_time_loop=false
        echo.
        echo.%ESC%[41m ----------------------            ATTENTION ^^!^^!^^!           ---------------------- %ESC%[0m
        echo.%ESC%[41m ----------------------      Running shards found     ---------------------- %ESC%[0m
        echo.
    )
    set pid_with_quotes=%%p
    set pid_without_quotes=!pid_with_quotes:"=!
    set pids_list=!pids_list! !pid_without_quotes!
    setlocal DisableDelayedExpansion
    call :stupid_excl_m %%p %%q
)

if defined pids_list (
    set AREYOUSURE=
    set /P AREYOUSURE="Kill running shards? (If "NO" - just exit from script) Y/[N]? "
    setlocal EnableDelayedExpansion
    if /I "!AREYOUSURE!" NEQ "Y" (
        echo. & echo.Just exiting ^(from script^)
        goto :EOF
    ) else (
        setlocal DisableDelayedExpansion
        echo.Trying to kill runnig shards...
        for %%a in (%pids_list%) do taskkill /PID %%a
        echo. & echo A little pause to stop the shards...
        timeout 3
        goto :check_runnig_shards_again
    )
)

REM ==============================================================================
REM          World backup rotation (5 last pre-run backups stored)
REM ==============================================================================
cd /D "%WORKING_DIR%"
mkdir worldbackup 2>NUL

dir /a:-d /b "worldbackup\%DST_cluster_folder%*.*" 2>NUL | find /c /v "" > "%TEMP%sdstwp"
set /p backups_count=<"%TEMP%sdstwp"
echo.
if %backups_count% EQU 0 ( echo.No existing backups. A new one will be created.  ) else ( echo Existing backups: )

SET count=%backups_count%
FOR /f "tokens=*" %%G IN ('dir /a:-d /b "worldbackup\%DST_cluster_folder%*.*" 2^>NUL ') DO (call :subroutine "%%G")
GOTO :after_subroutine

:subroutine
    set /A c_no=%backups_count%-%count%+1
    if %count% LEQ 5 ( 
        echo.%ESC%[32m     %c_no% ^( leave  ^)%ESC%[0m%ESC%[46G : %1
    ) else (
        echo.%ESC%[92m     %c_no% ^( remove ^)%ESC%[0m%ESC%[46G : %1
        del worldbackup\%1
    )
    set /a count-=1
    exit /b

:after_subroutine

cd "%DST_persistent_storage_root%"
cd "%DST_conf_dir%"
set HH=%TIME: =0%
set HH=%HH:~0,2%
set MM=%TIME:~3,2%
set SS=%TIME:~6,2%
tar -czf "..\..\worldbackup\%DST_cluster_folder%_%DATE%_%HH%-%MM%-%SS%.tar.gz" "%DST_cluster_folder%"

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Start steamcmd.exe for load/update/validate DST application.
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
start "Start steamcmd for load/update/validate DST dedicated server application." cmd /C "%0" /goto NewConsole
echo. & echo Press any key if you want to leave this console window open
call :timeout_with_keypress_detect 10
if defined key_pressed cmd /K
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

REM ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: If lua interpreter exists, then dedicated_server_mods_setup.lua will be generated basing on modoverrides.lua
REM ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
cd /D "%WORKING_DIR%"
if "%LUA_use_lua%"=="true" (
    if exist "%LUA_exe_full_path%" (
        set "lua_exe=%LUA_exe_full_path%"
    ) else (
        for /f "tokens=* usebackq" %%f in (`where lua*.exe 2^>nul`) do set "lua_exe_temp=%%f"
        if "%ERRORLEVEL%" =="0" set lua_errorlevel_is_zero=true
    )
)
if defined lua_errorlevel_is_zero set "lua_exe=%lua_exe_temp%"
if defined lua_exe "%lua_exe%" -e "ms=dofile('modoverrides.lua');ds=io.open('dedicated_server_mods_setup.lua','w');for k,v in pairs(ms) do if v.enabled then ds:write('ServerModSetup(\"'..string.sub(k,10)..'\")\n');end;end;ds:close()"

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Run shards
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
exit



REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM
REM                  END OF MAIN SCRIPT. ONLY FUNCTIONS BELOW
REM
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:setkey
    set setkey_result=%1
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


:stupid_excl_m
    set tmpstr=%~2
    set tmpstr=%tmpstr:--=%
    set tmpstr=%tmpstr:  =%
    set tmpstr=%tmpstr:~0,-3%
    echo %1 %tmpstr:Started=%
    echo.
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
REM A hack against various console commands that break escape sequences for no apparent reason.
REM Its very similar like this commands call Win32 function SetConsoleMode 
REM and reset terminal with ENABLE_VIRTUAL_TERMINAL_INPUT ENABLE_VIRTUAL_TERMINAL_PROCESSING flags
REM But after call to any label with "exit /b" termial begin execute escape sequences again.
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
        echo.%spaces% %ESC%[41m Folder/file not found %ESC%[0m%ESC%[46G : "%~1"
        set check_exist_notfoud=TRUE
    ) else (
        echo.%spaces% %ESC%[92m Folder/file found    %ESC%[0m%ESC%[46G : "%~1"
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
            echo.%ESC%[93m         Create "%~1"?%ESC%[0m
            setlocal EnableDelayedExpansion
            set AREYOUSURE=
            set /P AREYOUSURE="%ESC%[93m     (If "NO" - just exit from script) Y/[N]?%ESC%[0m"
            if /I "!AREYOUSURE!" NEQ "Y" (
                echo. & echo.    Just exiting ^(from script^)
                exit /b 1
            )
            setlocal DisableDelayedExpansion
        )
        echo.        %ESC%[32mTrying to create... %ESC%[0m%ESC%[46G : "%~1"
        mkdir "%~1"
        call :check_exist "%~1" rshift
        if defined check_exist_notfoud (
            echo.        Cannot create folder "%~1". Cannot continue
            pause
            exit /b 1
        )
    )
    exit /b



:timeout_with_keypress_detect
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Timeout with key press detect.
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
set CRLF=^& echo.
(echo ^
#%CRLF%^
# Configuration file to run the script      DSTcmdLauncherXXX.cmd%CRLF%^
#%CRLF%%CRLF%%CRLF%^
#%CRLF%^
# FIRST RUN%CRLF%^
#%CRLF%^
#     DST_cluster_templates_folder: default set of files for new cluster ^(as from Klei website^)%CRLF%^
#     DST_my_mods_templates_folder: Dir for mod's sets templates ^(up to 9 templates^)%CRLF%^
#           For now "mod template" is 2 files: dedicated_server_mods_setup.lua, modoverrides.lua.%CRLF%^
#           During normal run ^(not first time^) this 2 files copies to right places every run.%CRLF%^
#     Both folders are located inside script folder.%CRLF%^
DST_cluster_templates_folder    = MyDediServerTemplate%CRLF%^
DST_my_mods_templates_folder    = MyModsTemplates%CRLF%%CRLF%%CRLF%^
#%CRLF%^
# STEAM%CRLF%^
#%CRLF%^
DST_steamcmd_dir    		    = %USERPROFILE%\steamcmd%CRLF%^
DST_dst_bin                  	= steamapps\common\Don't Starve Together Dedicated Server\bin64%CRLF%^
DST_exe                         = dontstarve_dedicated_server_nullrenderer_x64.exe%CRLF%%CRLF%%CRLF%^
#%CRLF%^
# DEDICATED SERVER%CRLF%^
#%CRLF%^
#     Parameters for dontstarve_dedicated_server_nullrenderer executable.%CRLF%^
#     3 nested dirs.%CRLF%^
#     DST_persistent_storage_root relative to current dir ^(defined in WORKING_DIR varable^):%CRLF%^
#     WORKING_DIR/DST_persistent_storage_root/DST_conf_dir/DST_cluster_folder%CRLF%^
DST_persistent_storage_root  	= KleiDedicated%CRLF%^
DST_conf_dir                 	= DoNotStarveTogether%CRLF%^
DST_cluster_folder             	= %new_cluster_folder_escaped%%CRLF%%CRLF%%CRLF%^
#%CRLF%^
# SHARDS%CRLF%^
#%CRLF%^
#     Space separated dirnames. Dirname cannot include spaces%CRLF%^
#     Example: Master Caves%CRLF%^
#     First shard is master always. TODO: parse cluster.ini server.ini to find master%CRLF%^
DST_shards                      = Master Caves%CRLF%%CRLF%%CRLF%^
#%CRLF%^
# CONSOLE%CRLF%^
#%CRLF%^
#     Screen coordinates X Y for each shard's console window ^(optional^).%CRLF%^
#     Key    - shard's name ^(as listed at DST_shards^).%CRLF%^
#     Value  - X Y ^(space separated, may be negative for second screen at left^)%CRLF%^
Master                          = X Y%CRLF%^
Caves                           = X Y%CRLF%%CRLF%%CRLF%^
#%CRLF%^
# LUA%CRLF%^
#%CRLF%^
#     Lua interpreter can be used for generating dedicated_server_mods_setup.lua.%CRLF%^
#     If interpreter not found - you should edit both files respectively:%CRLF%^
#     dedicated_server_mods_setup.lua, modoverrides.lua%CRLF%^
#     If LUA_use_lua = false, lua will not used even if present in the system.%CRLF%^
#     First of all script check for lua executable at LUA_exe_full_path ^(if defined^).%CRLF%^
#     Next - script serarch lua*.exe via PATH variable. Last one found will be used.%CRLF%^
LUA_use_lua                     = true%CRLF%^
LUA_exe_full_path               =%CRLF%)>%1
exit /b