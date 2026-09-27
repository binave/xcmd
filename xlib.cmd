0> /* :
@echo off
::     Copyright 2017 bin jin
::
::     Licensed under the Apache License, Version 2.0 (the "License");
::     you may not use this file except in compliance with the License.
::     You may obtain a copy of the License at
::
::         http://www.apache.org/licenses/LICENSE-2.0
::
::     Unless required by applicable law or agreed to in writing, software
::     distributed under the License is distributed on an "AS IS" BASIS,
::     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
::     See the License for the specific language governing permissions and
::     limitations under the License.
::
:: Framework:
::
::     A function whose name conforms to the specification gets:
::         External invocation. (Support short name completion)
::         Error handling.
::         Help information.
::         The functions list.
::
::     The annotation [:::] is the help text and must sit above the label it describes. For example:
::         ::: "[brief_introduction]" "" "Usage: %~n0 [function_name] [OPTION]..."
::         :[script_name_without_suffix]\[function_name]
::             [function_body]
::             :: Normal comment; [:::] is reserved for the annotation.
::             call :sub\[function_name]\%*
::             ...
::             :: Return false status.
::             exit /b 1
::
::         ::: "  -o, --option=FILE   [description]"
::         :sub\[function_name]\[--arg]
::             [function_body]
::             :: Exit and display [error_description_1].
::             exit /b 2 @REM [error_description_1]
::
::
:: Thread:
::     For example:
::         \\:[function_name] [args1] [args2] ...
:: ...
:: :[function_name]
:: ...
:: goto :eof

:::::::::::::::::::::
:: basic functions ::
  :::::::::::::::::

:: Reset errorlevel.
set errorlevel=

:: Re-run this script by its own path when the first argument is a UNC path.
if "%~d1"=="\\" call :thread "%*" & exit

:: Add this script's directory to PATH when it is not on PATH yet.
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

if "%~2"=="-h" call :this\annotation :%~n0\%~1 & exit /b 0
if "%~2"=="--help" call :this\annotation :%~n0\%~1 & exit /b 0

2>nul call :%~n0\%*

if not errorlevel 0 exit /b 1

:: Show the function help when the function returns an error status.
if errorlevel 1 call :this\annotation :%~n0\%* & goto :eof
exit /b 0

:::::::::::::::
:: functions ::
  :::::::::::

:xlib\
:xlib\--help
:xlib\-h
    call :this\annotation
    exit /b 0

::: "Print version and exit" "" "Usage: %~n0 version"
:xlib\version
    >&3 echo 0.26.9.26
    exit /b 0

::: "Manage environment variables" "" "Usage: %~n0 var [OPTION]..." ""
:xlib\var
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\var\%*
    goto :eof

:: Override the process environment.
:: The operand is a variable name prefix; a trailing '*' matches every name that starts with it.
::: "    -u, --unset=VAR                        unset VAR; a trailing '*' matches VAR by prefix"
:sub\var\--unset   [variable_prefix_name]
:sub\var\-u
    if "%~1"=="" exit /b 10 @REM The variable prefix is empty.
    for /f "usebackq delims==" %%a in (`
        2^>nul set %1
    `) do set %%a=
    exit /b 0

::: "    -e, --env=KEY VALUE                    set the system environment variable KEY to VALUE"
:sub\var\--env
:sub\var\-e
    if "%~1"=="" exit /b 22 @REM The key is empty.
    if "%~2"=="" exit /b 23 @REM The value is empty.
    @REM for %%a in (wmic.exe) do if "%%~$path:a"=="" exit /b 24 @REM 'wmic.exe' is not on the PATH.
    for %%a in (setx.exe) do if "%%~$path:a" neq "" >nul setx.exe %~1 %2 /m & exit /b 0
    @REM if defined %~1 wmic.exe environment where 'name="%~1" and username="<system>"' set VariableValue="%~2"
    @REM if not defined %~1 wmic.exe environment create name="%~1",username="<system>",VariableValue="%~2"
    exit /b 0

::: "    -sel, --set-errorlevel=NUM             set errorlevel to NUM"
:sub\var\--set-errorlevel
:sub\var\-sel
    if "%~1"=="" goto :eof
    exit /b %1

::: "    -p, --in-path=FILE                     test whether FILE is found on the PATH"
:sub\var\--in-path
:sub\var\-p
    if "%~1" neq "" if "%~$path:1" neq "" exit /b 0
    exit /b -1

::: "    -sp, --trim-path=VAR                   remove the empty and missing entries from the PATH-like variable VAR"
:sub\var\--trim-path
:sub\var\-sp
    if "%~1"=="" exit /b 56 @REM The variable name is empty.
    if not defined %~1 exit /b 57 @REM The variable name is not defined.
    setlocal enabledelayedexpansion
    :: TODO: get the variable value as a PATH.
    :: Trim the quotes.
    set _var=!%~1:"=!
    :: " Trim head/tail semicolons
    if "%_var:~0,1%"==";" set _var=%_var:~1%
    if "%_var:~-1%"==";" set _var=%_var:~0,-1%
    :: Drop the trailing backslash at the end of a directory entry.
    set _var=%_var:\;=;%;
    :: Delete every entry that does not exist.
    call :this\path\trim "%_var:;=" "%"
    endlocal & set %~1=%_var:~0,-1%
    exit  /b 0

:: Delete the PATH entries that do not exist, for :sub\var\--trim-path.
:this\path\trim
    if "%~1"=="" exit /b 0
    if not exist %1 set _var=!_var:%~1;=!
    shift /1
    goto %0

::: "    -rp, --reset-path                      reset PATH to the system value"
:sub\var\--reset-path
:sub\var\-rp
    call :this\cim || goto legacy\reset_path
    for /f "usebackq tokens=2 delims==" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "(Get-CimInstance Win32_Environment -Filter \"Name='Path' and SystemVariable=True\").VariableValue"
    `) do call set path=%%a
    goto :eof
    :legacy\reset_path
    for /f "usebackq tokens=2 delims==" %%a in (`
        wmic.exe ENVIRONMENT where "Caption='<SYSTEM>\\Path'" get VariableValue /format:list
    `) do call set path=%%a
    exit /b 0

::: "    -ic, --install-config                  install an AutoRun hook that loads %USERPROFILE%\.batchrc"
:sub\var\--install-config
:sub\var\-ic
    setlocal

    call :sub\var\--backspace _bs
    call :regedit\on
    reg.exe ^
        add "HKCU\SOFTWARE\Microsoft\Command Processor" ^
            /v AutoRun ^
            /t REG_SZ ^
            /d "if not defined BS set BS=%_bs%&& (for /f \"usebackq delims=\" %%a in (\"%%USERPROFILE%%\.batchrc\") do @call %%a)>nul 2>&1" /f
    call :regedit\off

    if exist "%USERPROFILE%\.batchrc" endlocal & exit /b 0
    > "%USERPROFILE%\.batchrc" (
        echo ;use ^>^&3 in script can print
        echo set devmgr_show_nonpresent_devices=1
        echo doskey.exe which=where.exe $*
        echo set path=%%path%%;%~dp0
        echo,
        echo title Command Prompt
    )
    endlocal
    exit /b 0

::: "    -uc, --uninstall-config                remove the AutoRun hook installed by --install-config"
:sub\var\--uninstall-config
:sub\var\-uc
    setlocal
    call :regedit\on
    @REM erase "%USERPROFILE%\.batchrc"
    reg.exe delete "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /f
    call :regedit\off
    endlocal
    exit /b 0

::: "Sleep for a number of milliseconds" "" "Usage: %~n0 sleep MS"
:xlib\sleep
    call :sub\is\--integer %~1 || exit /b 22 @REM The argument is not an integer.
    @REM start /min /w mshta.exe vbscript:setTimeout("window.close()",1200)
    start /w MsHta.exe JavaScript:document.write();setTimeout('close()',%~1);
    exit /b 0

::: "Run a command as administrator or in the background" "" "Usage: %~n0 run [OPTION]..." ""
:xlib\run
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\run\%*
    goto :eof

::: "    -a, --admin[=COMMAND]...   run COMMAND as the local administrator"
:sub\run\--admin
:sub\run\-a
    @REM net.exe user administrator /active:yes
    @REM net.exe user administrator ???
    runas.exe /savecred /user:administrator "%*"
    exit /b 0

::: "    -q, --vbhide=COMMAND       run COMMAND in the background with no window"
:sub\run\--vbhide
:sub\run\-q
    if "%~1"=="" exit /b 22 @REM The command is empty.
    @REM mshta.exe VBScript:CreateObject("WScript.Shell").Run("""%~1"" %~2", 0)(Window.close)
    :: See the ShellExecute code snippet at https://docs.microsoft.com/zh-tw/windows/desktop/shell/shell-shellexecute#code-snippet-1.
    @REM mshta.exe VBScript:CreateObject("Shell.Application").ShellExecute("%~1","%~2","","open",0)(window.close) 'No spaces are allowed in the preceding code 'e.g. "D:\demo.exe" "--config ""D:\demo 2.config"""
    call :xlib\vbs vbhide "%~1"
    exit /b 0

::: "Test a string or the run-time environment" "" "Usage: %~n0 is [OPTION]... [STRING]" ""
:xlib\is
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\is\%*
    goto :eof

::: "    -i, --integer[=STRING]    test whether STRING is an integer"
:sub\is\--integer
:sub\is\-i
    if "%~1"=="" exit /b -1
    setlocal
    set _tmp=
    :: A valid integer round-trips through 'set /a' unchanged.
    2>nul set /a _code=-1, _tmp=%~1
    if "%~1"=="%_tmp%" set _code=0
    endlocal & exit /b %_code%

::: "    --pipe                    test whether the script is running after a pipe"
:sub\is\--pipe
::: "    --gui                     test whether the script is running at the GUI"
:sub\is\--gui
    setlocal
    set cmdcmdline=
    set _cmdcmdline=%cmdcmdline:"='%
    :: "
    set _code=0
    if /i "%0"==":sub\is\--pipe" if "%_cmdcmdline%"=="%_cmdcmdline:  /S /D /c' =%" set _code=-1
    if /i "%0"==":sub\is\--gui" if "%_cmdcmdline%"=="%_cmdcmdline: /c ''=%" set _code=-1
    @REM if /i "%0"==":sub\is\--gui" for %%a in (%cmdcmdline%) do if /i %%~a==/c set _code=0
    endlocal & exit /b %_code%

:: Test whether a string is a MAC address.
:sub\is\--MACaddr
:sub\is\-mac
    setlocal enabledelayedexpansion
    set "_mac_addr=%~1"
    for %%z in (
        %_mac_addr:|= %
    ) do for /f "usebackq tokens=1-6 delims=-:" %%a in (
        '%%z'
    ) do (
        if "%%z" neq "%%a-%%b-%%c-%%d-%%e-%%f" if "%%z" neq "%%a:%%b:%%c:%%d:%%e:%%f" exit /b -1
        for %%g in (
            "%%a" "%%b" "%%c" "%%d" "%%e" "%%f"
        ) do (
            2>nul set /a _hx=0x%%~g || exit /b -1
            if !_hx! gtr 255 exit /b -1
        )
    )
    endlocal
    exit /b 0

::: "Process tools" "" "Usage: %~n0 ps [OPTION]..." ""
:xlib\ps
    call :sub\ps\%*
    goto :eof

:sub\ps\
    call :this\cim || goto legacy\ps
    for /f "usebackq tokens=1* delims==" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance Win32_Process | ForEach-Object { $_ | Select-Object -Property CommandLine,Description,ProcessId | Format-List } | Out-String -Stream"
    `) do if "%%~b" neq "" echo,%%b
    goto :eof
    :legacy\ps
    for /f "usebackq tokens=1* delims==" %%a in (`
        wmic.exe process get CommandLine^,Description^,ProcessId /value
    `) do echo,%%b
    exit /b 0

::: "    -qf=FILE                    list the processes that use FILE"
:sub\ps\--qf
:sub\ps\-qf
    if not exist "%~f1" exit /b 29 @REM The target file was not found.
    fsutil.exe file queryProcessesUsing "%~f1"
    goto :eof

::: "    -t, --test=EXE              test whether the process EXE is running"
:sub\ps\--test
:sub\ps\-t
    @REM tasklist.exe /v /FI "imagename eq %~n1.exe"
    if "%~1"=="" exit /b 32 @REM The process name is empty.
    call :this\cim || goto legacy\ps_test
    >nul 2>&1 call PowerShell.exe ^
        -NoLogo ^
        -NonInteractive ^
        -ExecutionPolicy Unrestricted ^
        -Command "Get-Process "%~n1" -ErrorAction Stop" && exit /b 0
    goto skip\legacy_ps_test
    :legacy\ps_test
    for /f usebackq^ tokens^=2^ delims^=^=^" %%a in (`
        2^>nul wmic.exe process where caption^="%~n1.exe" get commandline /value
    `) do for %%b in (
        %%a
    ) do if /i "%%~nb"=="%~n1" exit /b 0
    :skip\legacy_ps_test
    exit /b -1

::: "    -k, --kill=PROCESS...       kill the process named PROCESS"
:sub\ps\--kill
:sub\ps\-k
    if "%~1"=="" exit /b 42 @REM The process name is empty.
    for %%a in (
        %*
    ) do taskkill.exe /f /im "%%~na.exe" >nul 2>nul

    @REM for /f "usebackq skip=1 tokens=2 delims=," %%b in (`
    @REM     2^>nul tasklist.exe /fi "imagename eq %%a" /fo csv /nh
    @REM `) do for %%b in (%%a) do >nul taskkill.exe /f /pid %%~b

    @REM start "" /b "%~f0" %*

    @REM taskkill.exe /f /im %~1.exe
    exit /b 0

::: "Time tools" "" "Usage: %~n0 time [OPTION]..." ""
:xlib\time
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\time\%*
    goto :eof

::: "    -ts, --timestamp=VAR               print the Unix timestamp, like 'date +%%s'"
:sub\time\--timestamp
:sub\time\-ts
    if "%~1"=="" exit /b 12 @REM The variable name is empty.
    setlocal
    :: Win32_UTCTime = Win32_LocalTime - (Win32_TimeZone.Bias * 60)
    call :this\cim || goto legacy\timestamp
    for /f "usebackq tokens=1* delims==" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "$c=Get-CimInstance Win32_UTCTime; 'Year={0}' -f $c.Year; 'Month={0}' -f $c.Month; 'Day={0}' -f $c.Day; 'Hour={0}' -f $c.Hour; 'Minute={0}' -f $c.Minute; 'Second={0}' -f $c.Second"
    `) do if "%%~b" neq "" set _%%a=%%b
    goto skip\legacy_timestamp
    :legacy\timestamp
    for /f "usebackq tokens=1* delims==" %%a in (`
        wmic.exe /namespace:\\root\cimv2 path Win32_UTCTime GET /value
    `) do if "%%~b" neq "" set _%%a=%%b
    :skip\legacy_timestamp

    if %_Month% lss 3 set /a _Year-=1, _Month+=12
    set /a _timestamp=^
        (^
            _Year * 365 + _Year / 4 - _Year / 100 + _Year / 400 + ^
            (153 * _Month - 457) / 5 + ^
            _Day - 306 - 719163 ^
        ) * 24 * 60 * 60 + ^
            _Hour * 3600 + _Minute * 60 + _Second

    endlocal & set /a %~1=%_timestamp%
    goto :eof


::: "    -n, --now=VAR [HEAD] [TAIL]" "                                   set VAR to HEAD + [YYYYMMDDhhmmss] + TAIL"
:sub\time\--now
:sub\time\-n
    if "%~1"=="" exit /b 12 @REM The variable name is empty.
    @REM set date=
    @REM set time=
    @REM :: English and Chinese date formats.
    @REM for /f "tokens=1-8 delims=-/:." %%a in (
    @REM   "%time: =%.%date: =.%"
    @REM ) do if %%e gtr 1970 (
    @REM     set %~1=%~2%%e%%f%%g%%a%%b%%c%~3
    @REM ) else if %%g gtr 1970 set %~1=%~2%%g%%e%%f%%a%%b%%c%~3

    setlocal
    call :this\cim || goto legacy\now
    for /f "usebackq tokens=1,2 delims==+" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "$d=(Get-CimInstance Win32_OperatingSystem).LocalDateTime; 'LocalDateTime=' + $d.ToString('yyyyMMddHHmmss.ffffff') + $d.ToString('zzz').Replace(':','')"
    `) do if "%%~b" neq "" set _%%a=%%b
    goto skip\legacy_now
    :legacy\now
    for /f "usebackq tokens=1* delims==" %%a in (`
        wmic.exe /namespace:\\root\cimv2 path Win32_OperatingSystem GET LocalDateTime /value
    `) do if "%%~b" neq "" call set "_LocalDateTime=%%~b"
    call set "_LocalDateTime=%_LocalDateTime:~0,17%"
    :skip\legacy_now
    endlocal & set %~1=%~2%_LocalDateTime:~0,17%%~3
    exit /b 0

::: "    -c, --calculate                    print the time elapsed since the previous call" "" "The option must be called before and after the timed function."
:sub\time\--calculate
:sub\time\-c
    setlocal
    :: 1970/01/01 - 1601/01/01 = 134774 days = 11644473600 seconds
    call :this\cim || goto legacy\calculate
    for /f "usebackq tokens=1* delims==" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "$tz=Get-CimInstance Win32_TimeZone; $ts=Get-CimInstance Win32_PerfRawData_PerfOS_System; 'Bias={0}{1}Timestamp_Sys100NS={2}' -f $tz.Bias,[char]10,$ts.Timestamp_Sys100NS"
    `) do if "%%~b" neq "" set _%%a=%%b
    goto skip\legacy_calculate
    :legacy\calculate
    for /f "usebackq tokens=1* delims==" %%a in (`
        wmic.exe /namespace:\\root\cimv2 path Win32_TimeZone GET Bias /value ^&
        wmic.exe /namespace:\\root\cimv2 path Win32_PerfRawData_PerfOS_System get Timestamp_Sys100NS /value
    `) do if "%%~b" neq "" set _%%a=%%b
    :skip\legacy_calculate

    set _Timestamp_Milliseconds=%_Timestamp_Sys100NS:~0,-5%
    set _Timestamp_Seconds=%_Timestamp_Milliseconds:~0,-3%
    set _Milliseconds_part=%_Timestamp_Milliseconds:~-3%

    for /f "usebackq delims=" %%a in (`
        set /a %_Timestamp_Seconds:~0,-2% - 116444736 - _Bias * 60 / 100
    `) do set _timestamp=%%a%_Timestamp_Seconds:~-2%.%_Milliseconds_part%

    if defined _calculate_time (
        set /a "_diff_Timestamp=(%_timestamp:~0,-4% - %_calculate_time:~0,-4%) * 1000 + (%_timestamp:~-3% - %_calculate_time:~-3%)"
        set /a _Day=_diff_Timestamp / 86400000, _Hour=_diff_Timestamp %% 86400000 / 3600000, _Minute=_diff_Timestamp %% 3600000 / 60000, _Second=_diff_Timestamp %% 60000 / 1000, _Milliseconds=_diff_Timestamp %% 1000
    )
    if defined _calculate_time echo %_Day%d %_Hour%h %_Minute%min %_Second%s %_Milliseconds%ms
    endlocal & set _calculate_time=%_timestamp%
    exit /b 0

::: "Update the hosts file from the ini configuration" "" "Usage: %~n0 hosts"
:xlib\hosts
    setlocal enabledelayedexpansion
    :: Load the ini configuration.
    call :this\load_ini hosts 1 || exit /b 2 @REM No ini file was found.
    :: Get the host names from the ini map.
    call :map --keys _keys 1
    :: Replace every MAC address in the map with its IPv4 address.
    for /f "usebackq tokens=1*" %%a in (`
        call %~nx0 ip --find %_keys%
    `) do if not defined _set\%%b (
        call :map --put %%b %%a 1 && call :sub\str\--2col-left %%~a %%b
        set _set\%%b=-
    )

    :: Rewrite the hosts file entries in the page buffer.
    :: Parse the IPv4 address and the host names of each line.
    for /f "usebackq tokens=1* delims=]" %%a in (`
        type %windir%\System32\drivers\etc\hosts ^| find.exe /n /v ""
    `) do for /f "usebackq tokens=1-3" %%c in (
        '. %%b'
    ) do call :sub\ip\--test %%d && (
        call :map --get %%e _value 1 && (
            for %%f in (
                !_value!
            ) do call :sub\ip\--test "%%~f" && (
                set _line=%%b
                call :page --put !_line:%%d=%%f!
            ) || call :page --put %%b
            call :map --remove %%e 1
        ) || call :page --put %%b
    ) || call :page --put %%b

    call :map --array _arr 1

    for %%a in (
        %_arr%
    ) do (
        call :sub\ip\--test %%a && (
            call :page --put %%~a   !_key!
        )
        set _key=%%~a
    )

    > %windir%\System32\drivers\etc\hosts call :page --show

    endlocal
    goto :eof


::: "Wake on LAN" "" "Usage: %~n0 wol [OPTION]... TARGET" "TARGET...=ALIAS,HOSTIP   a MAC address, a hosts alias or an IPv4 address" ""
:xlib\wol
    if "%~1"=="" call :this\annotation %0 & goto :eof
    setlocal enabledelayedexpansion
    :: The [hosts] ini resolves a hosts alias or an IPv4 address to a MAC address.
    call :this\load_ini hosts 1
    set "_broadcast="
    set "_targets=%*"

    if /i "%~1"=="-b" goto wol\option
    if /i "%~1"=="--broadcast" goto wol\option

    :: Without the option the broadcast address belongs to the subnet of the
    :: default gateway, as in the bash version of this command.
    call :this\get_route_ip _route
    for %%a in (
        %_route%
    ) do if not defined _broadcast set "_broadcast=%%~na.255"
    if not defined _broadcast exit /b 19 @REM Cannot resolve the broadcast IPv4 address.
    goto wol\wake

    :wol\option
    call :sub\wol\--broadcast %*
    if errorlevel 1 exit /b %errorlevel%
    goto wol\wake

    :wol\wake
    :: Wake every TARGET, which is a MAC address, a hosts alias or an IPv4 address.
    set "_macs="
    for %%a in (
        %_targets%
    ) do (
        set "_addrs="
        call :sub\wol\--addr %%a _addrs
        set "_mac="
        for %%b in (
            !_addrs!
        ) do call :sub\is\--MACaddr %%b && (
            set "_mac=-"
            set "_macs=!_macs! %%b"
        )
        if not defined _mac exit /b 30 @REM Cannot resolve the MAC address.
    )
    for %%a in (
        %_macs%
    ) do call :wol %%a %_broadcast%
    endlocal
    exit /b 0

::: "    -b, --broadcast=ADDRESS,ALIAS   broadcast ADDRESS for all targets"
:sub\wol\--broadcast
:sub\wol\-b
    :: It writes _broadcast and _targets in the caller's scope on purpose, so no
    :: setlocal is used here.  The option may be written [-b ADDRESS] or
    :: [--broadcast=ADDRESS], and the rest of the line holds the targets.
    set "_opt=%~1"
    if /i "!_opt:~0,12!"=="--broadcast=" (
        set "_opt=!_opt:~12!"
        set "_targets=%~2 %~3 %~4 %~5 %~6 %~7 %~8 %~9"
    ) else (
        set "_opt=%~2"
        set "_targets=%~3 %~4 %~5 %~6 %~7 %~8 %~9"
    )
    if "!_opt!"=="" exit /b 19 @REM Cannot resolve the broadcast IPv4 address.
    if "!_targets: =!"=="" exit /b 30 @REM Cannot resolve the MAC address.
    set "_addrs="
    call :sub\wol\--addr !_opt! _addrs
    for %%a in (
        !_addrs!
    ) do if not defined _broadcast call :sub\ip\--test %%a && set "_broadcast=%%~a"
    if not defined _broadcast exit /b 19 @REM Cannot resolve the broadcast IPv4 address.
    exit /b 0

:: Set %~2 to the MAC and IPv4 addresses that %~1 names in the [hosts] ini, from
:: a MAC address, a hosts alias or an IPv4 address.  Map 1 must hold the ini; a
:: string that names nothing stands for itself.
:sub\wol\--addr
    if "%~2"=="" exit /b 1
    setlocal enabledelayedexpansion
    set "_line=%~1"
    :: By hosts alias.
    call :map --get %~1 _value 1 && set "_line=!_value!"

    :: By IPv4 address: the value of the alias that holds the address.
    call :sub\ip\--test %~1 && if "!_line!"=="%~1" call :sub\wol\--addr-by-ip %~1 _line

    :: The addresses of the resolved line, in the order they are written.
    set "_addr="
    for %%a in (
        !_line:^|^= !
    ) do (
        call :sub\ip\--test %%a && set "_addr=!_addr! %%a"
        call :sub\is\--MACaddr %%a && set "_addr=!_addr! %%a"
    )
    if not defined _addr exit /b 1
    endlocal & set "%~2=%_addr%"
    exit /b 0

:: Reverse lookup the IPv4 address %~1 in the [hosts] ini and then in the hosts
:: file, which the [hosts] command updates, and set %~2 to the value of the
:: alias that holds it.
:sub\wol\--addr-by-ip
    if "%~2"=="" exit /b 1
    setlocal enabledelayedexpansion
    set "_line="

    call :map --keys _keys 1
    for %%a in (
        %_keys%
    ) do if not defined _line (
        call :map --get %%~a _value 1
        for %%b in (
            !_value:^|^= !
        ) do if "%%~b"=="%~1" set "_line=!_value!"
    )

    if not defined _line for /f "usebackq tokens=1,*" %%a in (`
        type "%windir%\System32\drivers\etc\hosts"
    `) do if "%%~a"=="%~1" for %%c in (
        %%b
    ) do if not defined _line call :map --get %%c _value 1 && set "_line=!_value!"

    if not defined _line endlocal & exit /b 1
    endlocal & set "%~2=%_line%"
    exit /b 0

:wol
    PowerShell.exe ^
        -NoLogo ^
        -NonInteractive ^
        -ExecutionPolicy Unrestricted ^
        -Command "& {" ^
        "   $UC = New-Object System.Net.Sockets.UdpClient(\"%~2\", 9);" ^
        "   $UC.EnableBroadcast = $true;" ^
        "   $MP = [Byte[]] (, 0xFF * 6) + ((\"%~1\" -split \"[:-]\" | ForEach-Object { [Byte] \"0x$_\"})  * 16);" ^
        "   $UC.Send($MP, $MP.Length) | Out-Null; $UC.Close();" ^
        "}"
    goto :eof

::: "Show or find IPv4" "" "Usage: %~n0 ip [OPTION]..." ""
:xlib\ip
    if "%~1"=="" call :this\annotation %0 & goto :eof
    2>nul call :sub\ip\%*
    goto :eof

::: "    -t, --test=STRING     test whether STRING is an IPv4 address"
:sub\ip\--test
:sub\ip\-t
    if "%~1"=="" exit /b 12 @REM The address is empty.
    :: [WARN] 'usebackq' makes every variable global, as in :xlib\hosts.
    for /f "tokens=1-4 delims=." %%a in (
        "%~1"
    ) do (
        if "%~1" neq "%%a.%%b.%%c.%%d" exit /b -1
        for %%e in (
            "%%a" "%%b" "%%c" "%%d"
        ) do (
            call :sub\is\--integer %%~e || exit /b -1
            if %%~e lss 0 exit /b -1
            if %%~e gtr 255 exit /b -1
        )
    )
    exit /b 0

::: "    -l, --list            print the local IPv4 addresses"
:sub\ip\--list
:sub\ip\-l
    setlocal
    :: Get the IPv4 address of the router.
    call :this\get_route_ip _route
    :: "
    for %%a in (
        %_route%
    call :this\cim || goto legacy\iplist
    ) do for /f "usebackq" %%b in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress } | ForEach-Object { $_.IPAddress }"
    `) do if "%%~nb"=="%%~na" echo %%b
    goto skip\legacy_iplist
    :legacy\iplist
    ) do for /f usebackq^ skip^=1^ tokens^=2^ delims^=^" %%b in (`
        wmic.exe NicConfig get IPAddress
    `) do if "%%~nb"=="%%~na" echo %%b
    :skip\legacy_iplist
    endlocal
    exit /b 0

::: "    -f, --find=[MAC,HOST]...  search for IPv4 by MAC address or host name" ""
:sub\ip\--find
:sub\ip\-f
    if "%~1"=="" exit /b 32 @REM The host name is empty.
    setlocal enabledelayedexpansion

    :: Load the ini sections used by the search.
    call :this\load_ini sip_setting -f
    call :map --get route _routes -f
    call :map --get range _range -f
    call :map --get exclude _excludes -f
    call :map --clear -f
    if not defined _range set _range=1-127

    call :this\load_ini hosts -f

    set _mac_addr=

    for %%a in (
        %*
    ) do (
        :: Resolve the argument from the map, or keep it as given.
        call :map --get %%a _arg -f && (
            set "_mac_addr=!_arg: =!"
        ) || set _mac_addr=%%a
        :: Normalize the MAC address to dash-separated form.
        set "_mac_addr=!_mac_addr::=-!"
        call :map --put %%a "!_mac_addr!" -t
    )

    if not defined _mac_addr exit /b 0
    call :map --clear -f

    :: Get the IPv4 address of the router.
    call :this\get_route_ip _get_route_ip
    for %%a in (
        %_routes% %_get_route_ip%
    ) do if not defined _tmp\%%~na (
        set _tmp\%%~na=-
        set "_route=!_route! %%a"
    )

    call :map --keys _keys -t

    :: Clear the ARP cache.
    arp.exe -d

    :: Scan the range for the requested MAC addresses.
    for %%a in (
        %_route%
    ) do for /l %%b in (
        %_range:-=,1,%
    ) do (
        set _tag=1
        for %%c in (%_excludes%) do if "%%~na.%%b"=="%%c" set _tag=
        if defined _tag call :this\thread_valve 50 cmd.exe --find
        if defined _tag start /b %~nx0 \\:ip\--find %%~na.%%b %_keys%
    )

    :: Print the IPv4 addresses found for the requested MAC addresses.
    for %%a in (
        %_keys%
    ) do call :map --get %%~a _value -t && for %%b in (
        !_value:^|^= !
    ) do call :sub\ip\--test %%b && call :sub\str\--2col-left %%b %%~a

    endlocal
    exit /b 0

:: TODO: use nbtstat to resolve the NetBIOS name cache.
:: Thread entry point for the sip scan.
:ip\--find
    :: The ping may fail while the ARP lookup still succeeds.
    >nul 2>nul ping.exe -n 1 -w 1 %1
    setlocal enabledelayedexpansion
    for /f "usebackq skip=3 tokens=1,2" %%a in (`
        arp.exe -a %1
    `) do for %%c in (
        %*
    ) do call :map --get %%~c _value -t ^
        && if "!_value:%%b=!" neq "!_value!" call :sub\str\--2col-left %%a %%~c

    endlocal
    exit /b 0

:: Get the IPv4 address of the default gateway.
:this\get_route_ip
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _gateway=
    :: "
    call :this\cim || goto legacy\route_ip
    for /f "usebackq" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway } | ForEach-Object { $_.DefaultIPGateway }"
    `) do set _gateway=!_gateway! %%a
    goto skip\legacy_route_ip
    :legacy\route_ip
    for /f usebackq^ skip^=1^ tokens^=2^ delims^=^" %%a in (`
        wmic.exe NicConfig get DefaultIPGateway
    `) do set _gateway=!_gateway! %%a
    :skip\legacy_route_ip
    endlocal & set %1=%_gateway%
    exit /b 0

::: "    --forward=[LOCAL_IP:]PORT [TO_IP:]PORT" "                          forward an IPv4 port to a remote host"
:sub\ip\--forward
    call :sub\oset\--vergeq 6.0 || exit /b 41 @REM The OS version is too low.
    :: netsh.exe interface portproxy show all
    if "%~2"=="" exit /b 42 @REM The arguments are invalid.
    setlocal
    set _local_ip=%~1
    set _to_ip=%~2
    for /f "usebackq tokens=1-4" %%a in (
        '%_local_ip::= % %_to_ip::= %'
    ) do if "%%~d"=="" (
        netsh.exe interface portproxy add v4tov4 listenport=%%a connectport=%%c connectaddress=%%b
    ) else netsh.exe interface portproxy add v4tov4 listenport=%%b listenaddress=%%a connectport=%%d connectaddress=%%c
    endlocal
    exit /b 0

::: "Directory tools" "" "Usage: %~n0 dir [OPTION]..." ""
:xlib\dir
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\dir\%*
    goto :eof

::: "    -id, --isdir=PATH         test whether PATH is a directory"
:sub\dir\--isdir
:sub\dir\-id
    setlocal
    set _attribute=%~a1-
    :: The first attribute character is 'd' for a directory.
    set _code=-1
    if %_attribute:~0,1%==d set _code=0
    endlocal & exit /b %_code%

::: "    -il, --islink=FILE        test whether FILE is a symbolic link"
:sub\dir\--islink
:sub\dir\-il
    if not exist "%~f1" exit /b -1
    for /f "usebackq delims=" %%a in (`
        2^>nul dir /al /b "%~dp1"
    `) do if "%%a"=="%~n1" exit /b 0
    :: A symbolic link appears in the 'dir /al' listing of its directory.
    exit /b -1

::: "    -if, --isfree=DIR         test whether DIR is empty"
:sub\dir\--isfree
:sub\dir\-if
    call :sub\dir\--isdir %1 || exit /b 32 @REM The path is not a directory.
    for /f usebackq"" %%a in (`
        dir /a /b "%~1"
    `) do exit /b -1
    exit /b 0

::: "    -scs=DIR                  enable case sensitivity for DIR"
:sub\dir\--scs
:sub\dir\-scs
    fsutil.exe file setCaseSensitiveInfo "%~f1" enable
    goto :eof

::: "    -qcs=DIR [DEPTH]" "                                query the case sensitivity of DIR" "                                DEPTH is a recursion depth; -r queries the whole tree" ""
:sub\dir\--qcs
:sub\dir\-qcs
    setlocal
    set _depth=%~2
    if defined _depth (
        if /i "%~2"=="-r" (
            set _depth=recursive
        ) else set _depth=recursive %~2
    )
    fsutil.exe file queryCaseSensitiveInfo "%~f1" %_depth%
    endlocal
    goto :eof

::: "    -mcs, --mkcsdir[=DIR]..." "                                create DIR as a case-sensitive directory" ""
:sub\dir\--mkcsdir
:sub\dir\-mcs
    for %%a in (%*) do mkdir "%%~fa" && >nul fsutil.exe file setCaseSensitiveInfo "%%~fa" enable
    goto :eof

::: "    --clean=DIR               remove the empty directories under DIR"
:sub\dir\--clean
    if not exist "%~1" exit /b 43 @REM The target was not found.
    call :sub\dir\--isdir %1 || exit /b 44 @REM The target is not a directory.
    if exist %windir%\system32\sort.exe (
        call :dir\rdEmptyDirWithSort %1
    ) else call :dir\rdEmptyDir %1
    goto :eof

:: For :sub\dir\--clean.
:dir\rdEmptyDir
    if "%~1"=="" exit /b 0
    if "%~2"=="" (
        call %0 "%~dp1" .
        exit /b 0
    ) else for /d %%a in (
        %1*
    ) do (
        2>nul rmdir "%%~a" || call %0 "%%~a\" .
        call %0 "%%~a\" .
    )
    exit /b 0

:: For :sub\dir\--clean.
:dir\rdEmptyDirWithSort
    if "%~1"=="" exit /b 2
    for /f "usebackq delims=" %%a in (`
        dir /ad /b /s %1 ^| sort.exe /r
    `) do 2>nul rmdir "%%~a"
    exit /b 0

::: "    -u, --unique[=DIR]        move the duplicate files of DIR to '.#Trash'"
:sub\dir\--unique
:sub\dir\-u
    setlocal enabledelayedexpansion

    if exist "%~1" pushd "%cd%"& chdir /d "%~1" || exit /b 54 @REM The target is not a directory.

    for /d %%a in (
        "%cd%\*"
    ) do if /i "%%~nxa" neq ".#Trash" call :dir\recursion "%%~a"

    for /f "usebackq delims=" %%a in (`
        dir /a-d /b "%cd%"
    `) do for %%b in (
        "%cd%\%%~a"
    ) do set /a _#\%%~zb += 1 & set _$\%%~zb.!random!!random!=%%~b

    if exist "%~1" popd

    for /f "usebackq tokens=1* delims==" %%a in (`
        2^>nul set _#\
    `) do if %%b gtr 1 for /f "usebackq tokens=1* delims==" %%c in (`
        2^>nul set _$\%%~na.
    `) do for /f "usebackq tokens=1,2 delims=(h" %%e in (`
        certutil.exe -hashfile "%%d" sha256
    `) do if "%%f"=="" call :dir\hashkey "%%~na" "%%e" "%%d"

    for /f "usebackq tokens=1* delims==" %%a in (`
        2^>nul set _c\
    `) do if %%b gtr 1 (
        echo,
        echo find '%%b' duplicate file.
        for /f "usebackq tokens=1* delims==" %%c in (`
            2^>nul set _sh\%%~nxa.
        `) do call :dir\pre8 %%~nc %%d
        for /f "usebackq skip=1 tokens=1* delims==" %%c in (`
            2^>nul set _sh\%%~nxa.
        `) do >nul mkdir ".#Trash%%~pd"& echo !_size!,MOVE '%%~d' -^> '.#Trash%%~pd'& >nul move "%%~d" ".#Trash%%~pd"
    )

    endlocal
    goto :eof

:dir\recursion
    for /r %1 %%a in (*?*) do set /a _#\%%~za += 1 & set _$\%%~za.!random!!random!=%%~a
    goto :eof

:dir\hashkey
    setlocal
    set _arg=%~2
    set _arg=%_arg: =%.%~1
    endlocal & set /a _c\%_arg% += 1 & set _sh\%_arg%.%random%%random%=%~3
    goto :eof

:dir\pre8
    setlocal
    set _arg=%~1
    echo %_arg:~0,8%,%~2
    endlocal & for /f "usebackq delims=." %%a in ('%~x1') do set _size=%%~a
    goto :eof


::: "Windows Remote Management" "" "Usage: %~n0 wrm [OPTION]..." ""
:xlib\wrm
    :: TODO: add the Windows Remote Management commands.
    goto :eof

::: "Operating system settings" "" "Usage: %~n0 oset [OPTION]..." ""
:xlib\oset
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\oset\%*
    goto :eof

:: TODO: change the MAC address with: reg.exe add hklm\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}/0001 /v NetworkAddress /t REG_SZ /d abcdef012345 /f

::: "    -vg, --vergeq=VERSION                         test whether the current OS version is at least VERSION"
:sub\oset\--vergeq
:sub\oset\-vg
    if "%~x1"=="" exit /b 12 @REM The version is empty or has no decimal part.
    setlocal
    call :oset\this_version_multiply_10 _this_ver
    for /f "usebackq tokens=1,2 delims=." %%a in (
        '%~1'
    ) do set /a _ver=%_this_ver% - %%a * 10 - %%b
    endlocal & if %_ver% geq 0 exit /b 0
    exit /b -1

:oset\this_version_multiply_10 [variable_name]
    if "%~1"=="" exit /b 1
    call :this\cim || goto legacy\ver_x10
    for /f "usebackq tokens=1,2 delims=." %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "[System.Environment]::OSVersion.Version.ToString()"
    `) do set /a %~1=%%a * 10 + %%b
    goto skip\legacy_ver_x10
    :legacy\ver_x10
    for /f "usebackq skip=1" %%a in (`
        wmic.exe os get Version
    `) do for %%b in (%%~na) do for /f "usebackq tokens=1,2 delims=." %%c in (
        '%%b'
    ) do set /a %~1=%%c * 10 + %%d
    :skip\legacy_ver_x10
    exit /b 0

::: "    -c, --cleanup=PATH [SCRATCH]                  run a component cleanup of the image at PATH, or of the running system"
:sub\oset\--cleanup
:sub\oset\-c
    if "%~1"=="" dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase & exit /b 0
    call :sub\dir\--isdir "%~1" || exit /b 23 @REM The image path is not a directory.
    call :sub\dir\--isdir "%~2" || exit /b 20 @REM The scratch directory does not exist.
    dism.exe /Image:%1 /Cleanup-Image /StartComponentCleanup /ResetBase /ScratchDir:"%~2"
    exit /b 0

:: Read the version, the SID, the architecture and the language from an OS path.
::: "    -v, --version[=OS_PATH] [VAR]                 print the OS version of OS_PATH, or set VAR to it"
:sub\oset\--version
:sub\oset\-v
    if "%~1"=="" (
        @REM for /f "usebackq delims==" %%a in (`
        @REM     ver
        @REM `) do for %%b in (
        @REM     %%a
        @REM ) do if "%%~xb" neq "" echo %%~nb
        call :this\cim || goto legacy\os_version
        for /f "usebackq" %%a in (`
            PowerShell.exe ^
                -NoLogo ^
                -NonInteractive ^
                -ExecutionPolicy Unrestricted ^
                -Command "[System.Environment]::OSVersion.Version.ToString()"
        `) do echo %%a
        goto :eof
        :legacy\os_version
        for /f "usebackq tokens=1* delims==" %%a in (`
            wmic.exe os get Version /value
        `) do if "%%b" neq "" echo %%b
        goto :eof
    )
    if "%~1" neq "" if not exist "%~1" exit /b 33 @REM The OS path is not a directory.
    if "%~1"=="%~d1" (
        call :oset\version %~1\ %2
    ) else if "%~dp1"=="%~f1" (
        call :oset\version "%~f1" %2
    ) else call :oset\version "%~f1\" %2
    goto :eof

:oset\version
    for /f "usebackq" %%a in (`
        2^>nul dir /ad /b %~1Windows\servicing\Version\*.*
    `) do if exist %~1Windows\servicing\Version\%%a\*_installed if "%~2"=="" (
        echo %%a& exit /b 0
    ) else set %~2=%%a& exit /b 0
    exit /b 34 @REM The path is not an OS path or the version is too low.

::: "    -s, --sid[=USER] [VAR]                        print the SID of USER (default the current user), or set VAR" ""
:sub\oset\--sid
:sub\oset\-s
    call :this\cim || goto legacy\sid
    if "%~1"=="" (
        for /f "usebackq" %%a in (`
            PowerShell.exe ^
                -NoLogo ^
                -NonInteractive ^
                -ExecutionPolicy Unrestricted ^
                -Command "(New-Object System.Security.Principal.NTAccount('%username%')).Translate([System.Security.Principal.SecurityIdentifier]).Value"
        `) do echo,%%a
    ) else for /f "usebackq" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "(New-Object System.Security.Principal.NTAccount('%~1')).Translate([System.Security.Principal.SecurityIdentifier]).Value"
    `) do if "%~2"=="" (
        echo,%%a
    ) else set %~2=%%a
    goto :eof
    :legacy\sid
    if "%~1"=="" (
        for /f "usebackq skip=1" %%a in (`
            wmic.exe useraccount where name^='%username%' get sid
        `) do for %%b in (%%a) do echo,%%b
    ) else for /f "usebackq skip=1" %%a in (`
        wmic.exe useraccount where name^='%~1' get sid
    `) do for %%b in (%%a) do if "%~2"=="" (
        echo,%%b
    ) else set %~2=%%b
    exit /b 0

::: "    -b, --bit=OS_PATH [VAR]                       print the architecture of the OS at OS_PATH, or set VAR to it"
:sub\oset\--bit
:sub\oset\-b
    if not exist "%~1" exit /b 53 @REM The OS path is not a directory.
    if "%~1"=="%~d1" (
        call :oset\bit %~1\ %2
    ) else if "%~dp1"=="%~f1" (
        call :oset\bit "%~f1" %2
    ) else call :oset\bit "%~f1\" %2
    goto :eof

:oset\bit
    if not exist %~1Windows\servicing\Version exit /b 64 @REM The path is not an OS path or the version is too low.
    for /d %%a in (
        %~1Windows\servicing\Version\*.*
    ) do if exist %%a\arm64_installed (
        if "%~2"=="" (
            echo arm64
        ) else set "%~2=arm64"
        exit /b 0
    ) do if exist %%a\amd64_installed (
        if "%~2"=="" (
            echo amd64
        ) else set "%~2=amd64"
        exit /b 0
    ) else if exist %%a\x86_installed (
        if "%~2"=="" (
            echo x86
        ) else set "%~2=x86"
        exit /b 0
    )
    exit /b 66 @REM The system version is too old.

:: See https://docs.microsoft.com/en-us/previous-versions/tn-archive/cc287874(v=office.12).
:: See https://docs.microsoft.com/en-us/previous-versions/commerce-server/ee825488(v=cs.20).
::: "    -lang, --language=VAR [OS_PATH]               print or set the language code of the OS at OS_PATH"
:sub\oset\--language
:sub\oset\-lang
    setlocal
    call :regedit\on
    set _load_point=HKLM\load-point%random%
    if "%~2" neq "" (
        reg.exe load %_load_point% %~2\Windows\System32\config\DRIVERS || (
            call :regedit\off
            exit /b 77 @REM The path is not an operating system directory.
        )
        for /f "usebackq tokens=1,4 delims=x " %%a in (`
            reg.exe query %_load_point%\select
        `) do if "%%b"=="Default" call :lang\current %_load_point%\ControlSet00%%b _lang || (
            call :regedit\off
            exit /b 78 @REM The language is not supported.
        )
        reg.exe unload %_load_point%
    ) else call :lang\current HKLM\SYSTEM\CurrentControlSet _lang || (
        call :regedit\off
        exit /b 79 @REM The language is not supported.
    )
    call :regedit\off
    if "%~1"=="" echo,%_lang%
    endlocal & if "%~1" neq "" set %~1=%_lang%
    goto :eof

@REM For :sub\oset\--language.
:lang\current
    for /f "usebackq tokens=1,3" %%a in (`
        reg.exe query %~1\Control\Nls\Language /v Default
    `) do if "%%a"=="Default" for %%c in (
        af-ZA.0436 ar-AE.3801 ar-BH.3C01 ar-DZ.1401 ar-EG.0C01 ar-IQ.0801 ar-JO.2C01 ar-KW.3401 ar-LB.3001 ar-LY.1001 ar-MA.1801 ar-OM.2001 ar-QA.4001 ar-SA.0401 ar-SY.2801 ar-TN.1C01 ar-YE.2401
        be-BY.0423 bg-BG.0402
        ca-ES.0403 cs-CZ.0405 Cy-az-AZ.082C Cy-sr-SP.0C1A Cy-uz-UZ.0843
        da-DK.0406 de-AT.0C07 de-CH.0807 de-DE.0407 de-LI.1407 de-LU.1007 div-MV.0465
        el-GR.0408 en-AU.0C09 en-BZ.2809 en-CA.1009 en-CB.2409 en-GB.0809 en-IE.1809 en-JM.2009 en-NZ.1409 en-PH.3409 en-TT.2C09 en-US.0409 en-ZA.1C09 en-ZW.3009 es-AR.2C0A es-BO.400A es-CL.340A es-CO.240A
        es-CR.140A es-DO.1C0A es-EC.300A es-ES.0C0A es-GT.100A es-HN.480A es-MX.080A es-NI.4C0A es-PA.180A es-PE.280A es-PR.500A es-PY.3C0A es-SV.440A es-UY.380A es-VE.200A et-EE.0425 eu-ES.042D
        fa-IR.0429 fi-FI.040B fo-FO.0438 fr-BE.080C fr-CA.0C0C fr-CH.100C fr-FR.040C fr-LU.140C fr-MC.180C
        gl-ES.0456 gu-IN.0447
        he-IL.040D hi-IN.0439 hr-HR.041A hu-HU.040E hy-AM.042B
        id-ID.0421 is-IS.040F it-CH.0810 it-IT.0410
        ja-JP.0411
        ka-GE.0437 kk-KZ.043F kn-IN.044B kok-IN.0457 ko-KR.0412 ky-KZ.0440
        Lt-az-AZ.042C lt-LT.0427 Lt-sr-SP.081A Lt-uz-UZ.0443 lv-LV.0426
        mk-MK.042F mn-MN.0450 mr-IN.044E ms-BN.083E ms-MY.043E
        nb-NO.0414 nl-BE.0813 nl-NL.0413 nn-NO.0814
        pa-IN.0446 pl-PL.0415 pt-BR.0416 pt-PT.0816
        ro-RO.0418 ru-RU.0419
        sa-IN.044F sk-SK.041B sl-SI.0424 sq-AL.041C sv-FI.081D sv-SE.041D sw-KE.0441 syr-SY.045A
        ta-IN.0449 te-IN.044A th-TH.041E tr-TR.041F tt-RU.0444
        uk-UA.0422 ur-PK.0420
        vi-VN.042A
        zh-CHS.0004 zh-CHT.7C04 zh-CN.0804 zh-HK.0C04 zh-MO.1404 zh-SG.1004 zh-TW.0404
    ) do if /i ".%%~b"=="%%~xc" set "%~2=%%~nc"& exit /b 0
    exit /b 1

::: "    -fi, --feature-info                           list the Windows features and their state"
:sub\oset\--feature-info
:sub\oset\-fi
    for /f "usebackq tokens=1-4" %%a in (`
        dism.exe /English /Online /Get-Features
    `) do (
        if "%%a%%b"=="FeatureName" call :sub\txt\--all-col-left %%d
        if "%%a"=="State" call :sub\txt\--all-col-left %%c & echo,
    )
    call :sub\txt\--all-col-left 0 0
    exit /b 0

::: "    -fe, --feature-enable=NAME...                 enable the Windows features named NAME"
:sub\oset\--feature-enable
:sub\oset\-fe
    if "%~1"=="" exit /b 95 @REM The feature name is empty.
    for %%a in (
        %*
    ) do dism.exe /Online /Enable-Feature /FeatureName:%%a /NoRestart
    exit /b 0

::: "    --disable-apps                                disable the automatic installation of suggested apps"
:sub\oset\--disable-apps
    reg.exe ^
        add HKCU\Software\Policies\Microsoft\Windows\CloudContent ^
            /v DisableWindowsConsumerFeatures ^
            /t REG_QWORD ^
            /d 0x1 /f

    reg.exe ^
        add HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager ^
            /v SilentInstalledAppsEnabled ^
            /t REG_DWORD ^
            /d 0x0 /f

    exit /b 0

::: "    -ru, --re-update                              repair Windows Update errors such as 0x80070002"
:sub\oset\--re-update
:sub\oset\-ru
    sfc.exe /scannow
    sc.exe config wuauserv start= auto
    @REM sc.exe config bits start= auto
    sc.exe config cryptsvc start= auto
    @REM sc.exe config trustedinstaller start= auto
    sc.exe config wuauserv type=share
    net.exe stop wuauserv
    net.exe stop cryptSvc
    @REM net.exe stop bits
    @REM net.exe stop msiserver
    rmdir /s /q %SystemRoot%\SoftwareDistribution
    net.exe start wuauserv
    net.exe start cryptSvc
    @REM net.exe start bits
    @REM net.exe start msiserver
    exit /b 0

::: "    -os, --open-ssh                               install and start the OpenSSH client and server"
:sub\oset\--open-ssh
:sub\oset\-os
    call :sub\oset\--vergeq 10.0 || exit /b 97 @REM The OS version is too low.
    for %%a in (
        Client Server
    ) do for /f "usebackq tokens=1,2*" %%b in (`
        dism.exe /english /online /Get-CapabilityInfo /CapabilityName:OpenSSH.%%a~~~~0.0.1.0
    `) do if /i "State"=="%%b" if /i "Installed" neq "%%d" dism.exe /Online ^
        /Add-Capability ^
        /capabilityname:OpenSSH.%%a~~~~0.0.1.0 ^
        /NoRestart

    if not exist "%userprofile%\.ssh" mkdir "%userprofile%\.ssh"
    >> "%userprofile%\.ssh\authorized_key" type nul
    >> "%ProgramData%\ssh\administrators_authorized_keys" type nul
    >> "%programdata%\ssh\sshd_config" type nul
    for %%a in (
        "%ProgramData%\ssh\sshd_config"
    ) do if %%~za==0 for /d %%b in (
        %SystemRoot%\WinSxS\*_openssh-server-components-onecore_*
    ) do if exist "%%b\sshd_config_default" > "%programdata%\ssh\sshd_config" type "%%b\sshd_config_default"
    @REM ssh-keygen.exe -t ed25519 -P "" -C "$USER@$HOSTNAME" -f ~/.ssh/id_ed25519;
    icacls.exe "%ProgramData%\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"

    sc.exe config sshd start= AUTO
    sc.exe start sshd

    exit /b 0

:: TODO: add a --close-ssh option.

::: "    -ow, --open-winrm                             configure WinRM; an optional -c or --client also relaxes the client settings"
:sub\oset\--open-winrm
:sub\oset\-ow
    :: Configure the server and the client.
    call winrm.cmd quickconfig -force
    if "%~1" neq "-c" if "%~1" neq "--client" goto :eof
    :: Configure the client only.
    call winrm.cmd set winrm/config/service @{AllowUnencrypted="true"}
    call winrm.cmd set winrm/config/client @{TrustedHosts="*"}
    exit /b 0

:: TODO: add a --close-winrm option.

::: "    --desktop-style                               apply the desktop settings of Windows Server; --force skips the server-edition check" "                                                  [DANGER^^^!] This is an irreversible operation"
:sub\oset\--desktop-style
    setlocal
    set _editionid=
    for /f "usebackq tokens=3" %%a in (`
        reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID
    `) do set _editionid=%%a
    if "%~1" neq "--force" if /i "%_editionid:~0,6%" neq "Server" exit /b 98 @REM This is not a server operating system.

    ::: if login
    for /f "usebackq skip=1" %%a in (`
        query.exe user %username%
    `) do if /i "%%~a"==">%username%" 2>&3 net.exe localgroup "Remote Desktop Users" %username% /add || REM

    call :sub\time\--now _oset_now
    set _oset_now=%_oset_now:~0,14%
    SecEdit.exe /export /cfg %windir%\Setup\hisecws_backup-%_oset_now%.inf /log %windir%\Temp\hisecws-%_oset_now%.log
    >%windir%\Setup\hisecws.inf call :sub\txt\--subtxt "%~f0" hisecws.inf 4300
    SecEdit.exe /configure /db %windir%\Setup\hisecws-%_oset_now%.sdb /cfg %windir%\Setup\hisecws.inf /log %windir%\Temp\hisecws-%_oset_now%.log /quiet
    endlocal

    gpupdate.exe /force

    @REM powercfg.exe /hibernate off
    powercfg.exe /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61

    sc.exe start Audiosrv
    sc.exe config Audiosrv start= auto
    exit /b 0

::: "    --allow-guest                                 allow insecure guest access to SMB shares"
:sub\oset\--allow-guest
    reg.exe ^
        add HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters ^
            /v AllowInsecureGuestAuth ^
            /t REG_DWORD ^
            /d 0x1 /f
    goto :eof

::: "    --freed-7g                                    disable the storage that Windows reserves"
:sub\oset\--freed-7g
    reg.exe ^
        add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager ^
            /v ShippedWithReserves ^
            /t REG_DWORD ^
            /d 0x0 /f
    goto :eof

::: "    --intel-amd=OS_PATH                           remove the Intel CPU driver before changing the processor"
:sub\oset\--intel-amd
    call :sub\oset\--vergeq 6.0 || exit /b 12 @REM The OS version is too low.

    if "%~1"=="" (
        setlocal
        set /p _i=[Warning] Reg vhd will be change, Yes^|No:
        if /i "%_i%" neq "y" if /i "%_i%" neq "yes" exit /b 0
        call :regedit\on
        call :sub\oset\delInteltag system
        call :regedit\off
        endlocal
        exit /b 0
    )

    setlocal
    set _target=%~f1
    if "%_target:~-1%"=="\" set _target=%_target:~0,-1%
    if not exist "%_target%\Windows\System32\config\SYSTEM" exit /b 23 @REM The path is not a Windows directory.
    call :regedit\on
    set _load_point=HKLM\load-point%random%
    reg.exe load %_load_point% "%_target%\Windows\System32\config\SYSTEM" && call :sub\oset\delInteltag tmp
    reg.exe unload %_load_point%
    call :regedit\off
    endlocal
    exit /b 0

:: For :sub\oset\--intel-amd.
:sub\oset\delInteltag
    for /f "tokens=1,4 delims=x	 " %%a in (
        'reg.exe query HKLM\%1\Select'
    ) do if /i "%%a"=="Default" 2>nul reg.exe delete HKLM\%1\ControlSet00%%b\Services\intelppm /f
    exit /b 0

:: Example: replace the string '$windows.~bt' with an empty string in a WinPE offline registry hive.
::: "    --replace-reg=FILE [SRC] [TAG]                replace SRC with TAG" "                                                  in the string values of the registry hive FILE"
:sub\oset\--replace-reg
    if "%~2"=="" exit /b 24 @REM The source string is empty.
    setlocal
    call :regedit\on
    :: The '(Default)' value name maps to the /ve switch.
    for /f "usebackq" %%a in (`
        reg.exe query HKLM /ve
    `) do set "_ve=%%a"

    set _load_point=HKLM\load-point%random%
    if exist "%~1" (
        reg.exe load %_load_point% "%~1" && call :reg\replace %_load_point% %2 %3
        reg.exe unload %_load_point%
    ) else call :reg\replace %1 %2 %3
    call :regedit\off
    endlocal
    goto :eof

:reg\replace
    setlocal enabledelayedexpansion
    set _src=%~2
    set _src=%_src:"=\"%

    set _tag=%~3
    if defined _tag set _tag=!_tag:"=\"!

    set _count=0
    :: Replace the source string in every matching value of the key.
    for /f "usebackq delims=" %%a in (`
        reg.exe query %1 /f %2 /s
    `) do >nul (
        set _line=%%a
        if "!_line:\%~n1=!"=="!_line!" (
            set _line=!_line:    =`!
            :: Escape a trailing backslash: /d "X:\" becomes /d "X:\\".
            set _line=!_line:\`=\\`!
            :: Escape a backslash in a value name: /v "X:\" becomes /v "X:\\".
            if "!_line:~-1!"=="\" set _line=!_line!\
            set _line=!_line:"=\"!
            for /f "tokens=1,2* delims=`" %%b in (
                "!_line:%_src%=%_tag%!"
            ) do if "%%c" neq "" (

                if "%%b" neq "%_ve%" (
                    reg.exe add "!_key!" /v "%%b" /t %%c /d "%%d" /f || exit /b 25 @REM The registry could not be updated.

                    :: Delete the original value name when the source string was found in it.
                    for /f "delims=`" %%e in (
                        "!_line!"
                    ) do if "%%b" neq "%%e" reg.exe delete "!_key!" /v "%%e" /f || exit /b 25

                ) else reg.exe add "!_key!" /ve /t %%c /d "%%d" /f || exit /b 25

                set /a _count+=1
            )
        ) else set _key=!_line:HKEY_LOCAL_MACHINE=HKLM!
    )
    echo all '%_count%' change.
    endlocal
    goto :eof

::: "    -sp, --set-power                              apply server power settings"
:sub\oset\--set-power
:sub\oset\-sp
    call :sub\oset\--vergeq 6.0 || exit /b 106 @REM The system version is too old.

    :: Disable hibernation.
    powercfg.exe /h off

    for /f "usebackq skip=2 tokens=4" %%a in (`
        powercfg.exe /list
    `) do for %%b in (
        ::?"While the system is powered by DC power."
        dc
        ::?"While the system is powered by AC power."
        ac
    ) do for %%c in (
        ::?"[\0]: No action is taken when the system lid is opened.        https://docs.microsoft.com/en-us/windows-hardware/customize/power-settings/lid-open-wake-action"
        SUB_BUTTONS\LIDACTION\0
        ::?"[\3]: The system shuts down when the power button is pressed.  https://docs.microsoft.com/en-us/windows-hardware/customize/power-settings/power-button-and-lid-settings-power-button-action"
        SUB_BUTTONS\PBUTTONACTION\3
        ::?"[\0]: No action is taken when the sleep button is pressed.     https://docs.microsoft.com/en-us/windows-hardware/customize/power-settings/power-button-and-lid-settings-sleep-button-action"
        SUB_BUTTONS\SBUTTONACTION\0
        ::?"[\0]: Never idle to sleep.                                     https://docs.microsoft.com/en-us/windows-hardware/customize/power-settings/sleep-settings-sleep-idle-timeout"
        SUB_SLEEP\STANDBYIDLE\0
        ::?"[\0]: Never power off the display.                             https://docs.microsoft.com/en-us/windows-hardware/customize/power-settings/display-settings-display-idle-timeout"
        SUB_VIDEO\VIDEOIDLE\0
    ) do for /f "usebackq tokens=1-3 delims=\" %%d in (
        '%%c'
    ) do powercfg.exe /set%%bvalueindex %%a %%d %%e %%f
    exit /b 0

:: TODO
:: https://technet.microsoft.com/en-us/security/cc184924.aspx
:sub\oset\--current-hotfix
:sub\oset\-ch
    setlocal enabledelayedexpansion
    set _oset_uuid=8e16a4c7-dd28-4368-a83a-282c82fc212a

    call :oset\hot\setup %_oset_uuid%

    :: http://go.microsoft.com/fwlink/?LinkId=76054
    call :sub\time\--now _odt_now

    if exist %temp%\%_oset_uuid%\wsusscn2.cab (
        for %%a in (
            %temp%\%_oset_uuid%\wsusscn2.cab
        ) do set _file_time=%%~ta
        set _file_time=!_file_time:/=!
        set _file_time=!_file_time::=!
        set _file_time=!_file_time: =!

        set /a _file_time=!_odt_now:~0,8! - !_file_time:~0,8!

        if !_file_time! gtr 7 erase %temp%\%_oset_uuid%\wsusscn2.cab
    )

    if not exist %temp%\%_oset_uuid%\wsusscn2.cab call :xlib\download ^
        http://download.windowsupdate.com/microsoftupdate/v6/wsusscan/wsusscn2.cab ^
            %temp%\%_oset_uuid%\wsusscn2.cab || exit /b 112 @REM The file could not be downloaded.

    :: Create the XML results file with mbsacli.exe.
    2>nul >"%temp%\results_%_odt_now%.xml" mbsacli.exe ^
                /xmlout ^
                /catalog "%temp%\%_oset_uuid%\wsusscn2.cab" ^
                /unicode ^
                /nvc

    2>nul erase "%temp%\%_oset_uuid%\wsusscn2.cab.dat"

    set _chot_kb=
    set _op=
    set _chot=chot.xml
    call :oset\this_version_multiply_10 _hot_ver
    if %_hot_ver%==51 (
        set _op=xp
        set _chot_kb=936929
    ) else if %_hot_ver%==52 (
        set _op=server2003
        set _chot_kb=914961
        if %processor_architecture:~-2%==64 set _op=server2003.windowsxp
    ) else if %_hot_ver%==60 (
        set _chot_kb=936330
    ) else if %_hot_ver%==61 (
        set _chot_kb=976932
    ) else set _chot=

    >%temp%\%_oset_uuid%\chot.xsl call :sub\txt\--subtxt "%~f0" chot.xml 3000

    :: Transform the XML report into a plain-text log with chot.xsl.
    call :xlib\vbs doxsl ^
            "%temp%\results_%_odt_now%.xml" ^
            %temp%\%_oset_uuid%\chot.xsl ^
            %temp%\hotlist_%_odt_now%.log || exit /b 111 @REM The XML report could not be converted.

    :: Detect the OS language to pick the exFAT update, as in ':sub\oset\--language'.
    set _lang=
    if %_hot_ver% lss 60 call :this\cim || goto legacy\oslanguage
    if %_hot_ver% lss 60 for /f "usebackq" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "(Get-CimInstance Win32_OperatingSystem).OSLanguage"
    `) do for %%b in (
        cht.1028
        enu.1033
        jpn.1041
        kor.1042
        chs.2052
    ) do if ".%%a"=="%%~xb" set _lang=%%~nb
    goto skip\legacy_oslanguage
    :legacy\oslanguage
    if %_hot_ver% lss 60 for /f "usebackq skip=1 tokens=1" %%a in (`
        wmic.exe os get OSLanguage
    `) do for %%b in (
        cht.1028
        enu.1033
        jpn.1041
        kor.1042
        chs.2052
    ) do if ".%%a"=="%%~xb" set _lang=%%~nb
    :skip\legacy_oslanguage

    :: Install the exFAT update (KB955704) for the detected language.
    if defined _lang for %%a in (
        A/6/E/A6EFFC03-F035-4604-9FB0-3B8169ED6BB6/WindowsXP-KB955704-x86-ENU
        E/8/A/E8AE6D10-0187-4B9C-AC00-AAB60A404E12/WindowsXP-KB955704-x86-CHS
        B/4/5/B4510A9E-00C5-4D99-8133-9B3172143B8C/WindowsXP-KB955704-x86-CHT
        F/4/2/F420EB1B-9C04-4B40-9424-5C4593628479/WindowsXP-KB955704-x86-JPN
        A/E/0/AE04BF31-41C3-4B70-847F-1ACF21E75898/WindowsXP-KB955704-x86-KOR
        3/5/1/3512CC64-57BD-4C97-AC83-6D5C6B2B0524/WindowsServer2003-KB955704-x86-ENU
        3/9/1/3917805C-FF96-4D6B-9F49-D4943B0A6AE5/WindowsServer2003-KB955704-x86-CHS
        3/8/3/38331E36-D3CD-4E14-A7F7-C746F6285975/WindowsServer2003-KB955704-x86-CHT
        9/C/D/9CD14BBA-B7EA-4EE0-9600-B1D136B1FC77/WindowsServer2003-KB955704-x86-JPN
        3/8/6/38697B60-193D-495C-882F-794AB8D86019/WindowsServer2003-KB955704-x86-KOR
        C/0/5/C0526146-E09A-41F7-B417-73BA1E561E40/WindowsServer2003.WindowsXP-KB955704-x64-ENU
        A/9/3/A9376498-CC5C-4566-8540-8B718025940C/WindowsServer2003.WindowsXP-KB955704-x64-CHS
        0/C/4/0C47C96D-F0D6-4142-B720-723D76B3E5B3/WindowsServer2003.WindowsXP-KB955704-x64-CHT
        7/B/C/7BC77A57-9310-41E4-9974-E75C8CC6E0C3/WindowsServer2003.WindowsXP-KB955704-x64-JPN
        E/3/2/E3237925-C9FF-4901-8A46-AFFAAC3AF602/WindowsServer2003.WindowsXP-KB955704-x64-KOR
    ) do if "%%~na"=="Windows%_op%-KB955704-x%processor_architecture:~-2%-%_lang%" >>%temp%\hotlist_%_odt_now%.log echo http://download.microsoft.com/download/%%a.exe

    sort.exe /+67 %temp%\hotlist_%_odt_now%.log

    erase %temp%\hotlist_%_odt_now%.log

    endlocal
    goto :eof

:: Download MBSA and add its directory to PATH.
:oset\hot\setup
    for %%a in (mbsacli.exe) do if "%%~$path:a" neq "" exit /b 0

    set PATH=%temp%\%~1;%PATH%
    if not exist %temp%\%~1\mbsacli.exe (
        2>nul mkdir %temp%\%~1
        @REM call :xlib\download http://download.microsoft.com/download/A/1/0/A1052D8B-DA8D-431B-8831-4E95C00D63ED/MBSASetup-x%processor_architecture:~-2%-EN.msi %temp%\%~1\MBSASetup.msi || exit /b 1
        call :xlib\download ^
            http://download.microsoft.com/download/8/E/1/8E16A4C7-DD28-4368-A83A-282C82FC212A/MBSASetup-x%processor_architecture:~-2%-EN.msi ^
                %temp%\%~1\MBSASetup.msi || exit /b 1

        pushd %cd%
            cd /d %temp%\%~1
            call :this\un\.msi %temp%\%~1\MBSASetup.msi
        popd

        :: Move mbsacli.exe and wusscan.dll into the temp directory.
        move /y "%temp%\%~1\MBSASetup\ProgramF\Microsoft Baseline Security Analyzer 2\??s?c??.???" %temp%\%~1
        rmdir /s /q %temp%\%~1\MBSASetup
    )

    exit /b 0

::: "    -reg, --regedit                               allow or deny the registry editor; requires --on or --off"
:sub\oset\--regedit
:sub\oset\-reg
    call :oset\regedit\%*
    goto :eof

:oset\regedit\--on
    :: See the INF DefaultInstall section reference (https://docs.microsoft.com/en-us/windows-hardware/drivers/install/inf-defaultinstall-section).

    >%temp%\b1444fb0-c076-5356-7ad3-25aa25d4e37a.inf call :sub\txt\--subtxt "%~f0" regon.inf 3000
    @REM pnputil.exe -i -a %temp%\b1444fb0-c076-5356-7ad3-25aa25d4e37a.inf
    rundll32.exe ^
        syssetup,SetupInfObjectInstallAction ^
        DefaultInstall 128 %temp%\b1444fb0-c076-5356-7ad3-25aa25d4e37a.inf
    erase %temp%\b1444fb0-c076-5356-7ad3-25aa25d4e37a.inf
    goto :eof

:regedit\on
    set _disable_reg=
    >nul 2>nul reg.exe query HKLM /ve || set _disable_reg=true
    if defined _disable_reg call :oset\regedit\--on
    goto :eof

:oset\regedit\--off
    reg.exe ^
        add HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System ^
            /v DisableRegistryTools ^
            /t REG_DWORD ^
            /d 1 /f
    goto :eof

:regedit\off
    if defined _disable_reg call :oset\regedit\--off
    goto :eof

::: "    -gp, --gpedit                                 allow or deny the Group Policy editor; requires --on or --off"
:sub\oset\--gpedit
:sub\oset\-gp
    setlocal
    call :regedit\on
    call :oset\gpedit\%*
    call :regedit\off
    endlocal
    goto :eof

:oset\gpedit\--on
    reg.exe delete HKCU\Software\Policies\Microsoft\MMC /f || exit /b 139 @REM The registry could not be updated.
    >&3 echo complete.
    goto :eof

:oset\gpedit\--off
    reg.exe ^
        add HKCU\Software\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3} ^
            /v Restrict_Run ^
            /t REG_DWORD ^
            /d 1 /f || exit /b 138 @REM The registry could not be updated.
    >&3 echo complete.
    goto :eof

::: "    -usw, --unsecure-write                        allow or deny write access to 'fixed' and 'removable' drives; requires --allow or --deny"
:sub\oset\--unsecure-write
:sub\oset\-usw
    setlocal
    call :regedit\on
    call :oset\write_access\%~1
    call :regedit\off
    endlocal
    goto :eof

:: Deny write access to fixed and removable drives that are not protected by BitLocker.
:oset\write_access\--deny
    >nul reg.exe ^
        add HKLM\Software\Policies\Microsoft\FVE ^
            /v RDVDenyCrossOrg ^
            /t REG_DWORD ^
            /d 0 /f || exit /b 147 @REM The registry could not be updated.

    for %%a in (
        FDV RDV
    ) do >nul reg.exe ^
                add HKLM\System\CurrentControlSet\Policies\Microsoft\FVE ^
                    /v %%aDenyWriteAccess ^
                    /t REG_DWORD ^
                    /d 1 /f
    >&3 echo complete.
    exit /b 0

:oset\write_access\--allow
    >nul 2>nul reg.exe ^
        delete HKLM\Software\Policies\Microsoft\FVE ^
            /v RDVDenyCrossOrg /f

    for %%a in (
        FDV RDV
    ) do >nul 2>nul reg.exe ^
                add HKLM\System\CurrentControlSet\Policies\Microsoft\FVE ^
                    /v %%aDenyWriteAccess /f
    >&3 echo complete.
    exit /b 0

::: "    -cr, --clear-rdc=HOST                         clear the saved 'mstsc.exe' entry for the computer HOST"
:sub\oset\--clear-rdc
:sub\oset\-cr
    if "%~1"=="" exit /b 152 @REM The computer name is empty.
    for /f "usebackq tokens=1-3" %%a in (`
        2^>nul reg.exe query "HKCU\Software\Microsoft\Terminal Server Client\Default"
    `) do if "%%b"=="REG_SZ" if /i "%%c"=="%~1" reg.exe delete ^
        "HKCU\Software\Microsoft\Terminal Server Client\Default" /v %%a /f
    exit /b 0

::: "    --rdp-port=PORT                               set the remote desktop server port"
:sub\oset\--rdp-port
    setlocal
    if "%~1"=="" (
        set _port=3389

    ) else set _port=%~1
    if "%~1" neq "" if "%_port%" neq "%~1" exit /b 161 @REM The port number is not supported.
    if %_port% lss 3000 exit /b 161 @REM The port number is not supported.
    if %_port% gtr 65535 exit /b 161 @REM The port number is not supported.

    reg.exe add ^
        "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" ^
        /v PortNumber ^
        /t REG_DWORD ^
        /d %_port% /f || exit /b 169 @REM The registry could not be updated.

    echo new RDP port: %_port%.

    if "%~1" neq "" netsh.exe advfirewall firewall ^
        add rule name="rdp " dir=in action=allow protocol=TCP localport=%_port%

    endlocal
    exit /b 0

::: "    ---445-port                                   release TCP port 445 used by the SMB server"
:sub\oset\---445-port
    setlocal
    set _use=
    for /f "usebackq tokens=2,4-5" %%a in (`
        netstat.exe -abno ^| find.exe ":445 "
    `) do if "%%c%%b"=="4LISTENING" set "_use=%%a"
    if not defined _use exit /b 0

    sc.exe config LanmanServer start= disabled
    @REM sc.exe stop LanmanServer
    >&3 echo need reboot.
    exit /b 0

::: "    --firewall=NAME                               enable the firewall rules whose name starts with NAME"
:sub\oset\--firewall
    setlocal
    set _RegKeyName=HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules
    for /f "usebackq tokens=1,2*" %%a in (`
        reg.exe query %_RegKeyName% /f %~1*
    `) do if "%%b"=="REG_SZ" for /f "usebackq tokens=1-7* delims=|" %%d in (
        '%%c'
    ) do for /f "usebackq tokens=1,3 delims==|" %%l in (
        '%%i^|%%j'
    ) do if /i "%%m"=="Profile" (
        reg.exe add %_RegKeyName% /v %%a /t %%b /d "%%d|%%e|Active=TRUE|%%g|%%h|%%k" /f
    ) else if /i "%%l"=="Profile" (
        reg.exe add %_RegKeyName% /v %%a /t %%b /d "%%d|%%e|Active=TRUE|%%g|%%h|%%j|%%k" /f
    ) else reg.exe add %_RegKeyName% /v %%a /t %%b /d "%%d|%%e|Active=TRUE|%%g|%%h|%%i|%%j|%%k" /f
    endlocal
    goto :eof

::: "    --dav-http                                    allow the WebDAV client to use HTTP"
:sub\oset\--dav-http
    reg.exe add ^
        HKLM\SYSTEM\CurrentControlSet\Services\WebClient\Parameters ^
        /v BasicAuthLevel ^
        /t REG_DWORD ^
        /d 0x2 /f || exit /b 172 @REM The registry could not be updated.

    net.exe stop webclient
    net.exe start webclient
    exit /b 0

::: "    --dav-maxsize                                 set the WebDAV client file size limit to 4 GB"
:sub\oset\--dav-maxsize
    :: Raise the default 50 MB limit to 4 GB.
    reg.exe add ^
        HKLM\SYSTEM\CurrentControlSet\Services\WebClient\Parameters ^
        /v FileSizeLimitInBytes ^
        /t REG_DWORD ^
        /d 0xffffffff /f || exit /b 172 @REM The registry could not be updated.

    net.exe stop webclient
    net.exe start webclient
    exit /b 0

:: Sysprep command-line options (https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep-command-line-options?view=windows-11).
::: "    --sysprep                                     [DANGER^^^!] remove PC-specific information (not implemented)"
:sub\oset\--sysprep
    exit /b 172 @REM Not implemented.


::: "Directory lock tools" "" "Usage: %~n0 lock [OPTION]..." ""
:xlib\lock
    if "%~1"=="" call :this\annotation %0 & goto :eof
    setlocal
    call :sub\lock\%*
    endlocal
    goto :eof

::: "    -g, --get=DIR [SEC]               acquire the lock on DIR, waiting up to SEC seconds"
:sub\lock\--get   [dir_path] [[sec]]
:sub\lock\-g
    set _arg1=%~1
    if "%_arg1:~-1%"=="\" set _arg1=%_arg1:~0,-1%

    2>nul set /a _Timeout=%~2
    if not defined _Timeout set _Timeout=180

    :: Lock timestamp upper limit: 60 * 60 * 24 * 365 * 68.
    call :sub\time\--timestamp _timestamp

    :: The lock was acquired.
    2>nul mkdir "%_arg1%\.lock" && (
        attrib.exe +h "%_arg1%\.lock"
        >"%_arg1%\.lock\.timestamp" echo __timestamp=%_timestamp%, __Timeout=%_Timeout%
        exit /b 0
    )

    :: The lock is held; read its timestamp file.
    set _formula=
    2>nul (
        set /p _formula=< "%_arg1%\.lock\.timestamp"
    ) || exit /b -1

    2>nul set /a %_formula% || exit /b -1
    set _formula=

    for /f "usebackq delims=" %%a in (`
        set /a _timestamp - __timestamp
    `) do set /a _diff_sec=%%a - __Timeout

    if %_diff_sec% geq 0 (
        rmdir /s /q "%_arg1%\.lock"
        :: The lock expired; remove it and retry.
        goto sub\lock\--get
    ) else if %_diff_sec% lss -%__Timeout% exit /b 23 @REM The lock timestamp is invalid.

    >&3 echo busy, wait '%_diff_sec:~1%' secends.
    exit /b -1

::: "    -r, --renewal=DIR [SEC]           renew the lock on DIR with timeout SEC"
:sub\lock\--renewal   [dir_path] [[sec]]
:sub\lock\-r
    set _arg1=%~1
    if "%_arg1:~-1%"=="\" set _arg1=%_arg1:~0,-1%
    if not exist "%_arg1%\.lock" exit /b 24 @REM The lock was not found.

    set /a _Timeout=%~2
    if not defined _Timeout set _Timeout=180
    call :sub\time\--timestamp _timestamp
    >"%_arg1%\.lock\.timestamp" echo __timestamp=%_timestamp%, __Timeout=%_Timeout%
    exit /b 0

::: "    -d, --delete=DIR                  delete the lock on DIR"
:sub\lock\--delete   [dir_path]
:sub\lock\-d
    set _arg1=%~1
    if "%_arg1:~-1%"=="\" set _arg1=%_arg1:~0,-1%
    >nul attrib.exe -h "%_arg1%\.lock"
    rmdir /s /q "%_arg1%\.lock" || exit /b 25 @REM The lock was not found.
    exit /b 0

::: "Volume info or edit" "" "Usage: %~n0 vol [OPTION]... [ARG]..." ""
:xlib\vol
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\vol\%*
    goto :eof

::: "    -ul, --free-letter=VAR                    print or assign the first unused drive letter"
:sub\vol\--free-letter
:sub\vol\-ul
    setlocal enabledelayedexpansion
    set _di=zyxwvutsrqponmlkjihgfedcba
    call :this\cim || goto legacy\free_letter
    for /f "usebackq delims=:" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "(Get-CimInstance Win32_LogicalDisk).DeviceID"
    `) do set _di=!_di:%%a=!
    goto skip\legacy_free_letter
    :legacy\free_letter
    for /f "usebackq skip=1 delims=:" %%a in (`
        wmic.exe logicaldisk get DeviceID
    `) do set _di=!_di:%%a=!
    :skip\legacy_free_letter
    endlocal & if "%~1"=="" (
        echo,%_di:~0,1%:
    ) else set %~1=%_di:~0,1%:
    exit /b 0

::: "    -xl, --change-letter=LETTER: [LETTER:]    [DANGER^^^!] change or swap drive letters; reboot required"
:sub\vol\--change-letter
:sub\vol\-xl
    if "%~2"=="" exit /b 26 @REM The target is not a drive letter or is not supported.
    if /i "%~1" neq "%~d1" exit /b 26 @REM The target is not a drive letter or is not supported.
    if /i "%~2" neq "%~d2" exit /b 26 @REM The target is not a drive letter or is not supported.
    if /i "%~d1"=="%SystemDrive%" exit /b 26 @REM The target is not a drive letter or is not supported.
    if /i "%~d2"=="%SystemDrive%" exit /b 26 @REM The target is not a drive letter or is not supported.
    setlocal enabledelayedexpansion
    set _%~d1=
    set _%~d2=
    call :regedit\on
    for /f "usebackq tokens=1,3" %%a in (`
        reg.exe query HKLM\SYSTEM\MountedDevices /v \DosDevices\*
    `) do (
        if /i "%%~a"=="\DosDevices\%~d1" set "_%~d1=%%~b"
        if /i "%%~a"=="\DosDevices\%~d2" set "_%~d2=%%~b"
    )
    if not defined _%~d1 exit /b 26 @REM The target is not a drive letter or is not supported.
    if defined _%~d2 (
        >&2 echo will exchange %~d1 with %~d2
        reg.exe add HKLM\SYSTEM\MountedDevices /v "\DosDevices\%~d1" /t REG_BINARY /d !_%~d2! /f || (
            call :regedit\off
            exit /b 27 @REM The registry could not be updated.
        )
    ) else (
        >&2 echo will change %~d1 to %~d2
        reg.exe delete HKLM\SYSTEM\MountedDevices /v "\DosDevices\%~d1" /f || (
            call :regedit\off
            exit /b 27 @REM The registry could not be updated.
        )
    )
    reg.exe add HKLM\SYSTEM\MountedDevices /v "\DosDevices\%~d2" /t REG_BINARY /d !_%~d1! /f || (
        call :regedit\off
        exit /b 27 @REM The registry could not be updated.
    )
    call :regedit\off
    >&2 echo,
    >&2 echo Need reboot system.
    endlocal
    exit /b 0

::: "    -rl, --remove-letter=LETTER:              [DANGER^^^!] remove the drive letter and mount the volume by GUID"
:sub\vol\--remove-letter
:sub\vol\-rl
    if /i "%~1"=="" exit /b 36 @REM The target is not a drive letter or is not supported.
    if /i "%~1" neq "%~d1" exit /b 36 @REM The target is not a drive letter or is not supported.
    if /i "%~d1"=="%SystemDrive%" exit /b 36 @REM The target is not a drive letter or is not supported.
    setlocal enabledelayedexpansion
    call :regedit\on
    for /f "usebackq tokens=1,3" %%a in (`
        reg.exe query HKLM\SYSTEM\MountedDevices /v \DosDevices\*
    `) do if /i "%%~a"=="\DosDevices\%~d1" (
        reg.exe delete HKLM\SYSTEM\MountedDevices /v "%%~a" /f || (
            call :regedit\off
            exit /b 37 @REM The registry could not be updated.
        )
        call :this\uuid _uuid
        reg.exe add HKLM\SYSTEM\MountedDevices /v #{!_uuid!} /t REG_BINARY /d %%b /f || (
            call :regedit\off
            exit /b 37 @REM The registry could not be updated.
        )
        >&2 echo,
        >&2 echo Need reboot system.
        call :regedit\off
        exit /b 0
    )
    call :regedit\off
    endlocal
    exit /b 38 @REM The drive letter was not found.

:: Minimal UUID generator.
:this\uuid
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _str=
    set "_0f=0123456789abcdef"
    for /l %%a in (8,4,20) do set _%%a=1
    for /l %%a in (1,1,32) do (
        set /a _ran16=!random! %% 15
        call set "_str=!_str!%%_0f:~!_ran16!,1%%"
        if defined _%%a set "_str=!_str!-"
    )
    endlocal & set "%~1=%_str%"
    goto :eof

::: "    -li, --letters=VAR [TYPE]                 print or assign the drive letters in ascending order"
:sub\vol\--letters
:sub\vol\-li
::: "    -dl, --desc-letters=VAR [TYPE]            print or assign the drive letters in descending order" "                  TYPE: [l]ocal fixed disk, [r]emovable (CD-ROM), [n]etwork drive; omit for all" ""
:sub\vol\--desc-letters
:sub\vol\-dl
    :::::::::::::::::::::::::::::::::::::::
    :: [WARNING] Nano Server unsupported ::
    :::::::::::::::::::::::::::::::::::::::
    if "%~1"=="" exit /b 42 @REM The variable name is empty.
    set _var=
    setlocal enabledelayedexpansion
    set _desc=
    :: Enable descending order when invoked as --desc-letters.
    for %%a in (%0) do if "%%~na" neq "--letters" if "%%~na" neq "-li" set _desc=1
    :: Add the WHERE clause for the drive type filter.
    if "%~2" neq "" (
        set _DriveType=
        :: DriveType values (https://docs.microsoft.com/zh-cn/dotnet/api/system.io.drivetype).
        if /i "%~2"=="l" set _DriveType=3
        if /i "%~2"=="r" set _DriveType=5
        if /i "%~2"=="n" set _DriveType=4
        if not defined _DriveType exit /b 43 @REM The drive type is not supported.
        set "_DriveType=DriveType=!_DriveType!"
    )
    :: Query the drive letters and build the result list.
    call :this\cim || goto legacy\letters
    for /f "usebackq tokens=1* delims==" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "$q='SELECT DeviceID FROM Win32_LogicalDisk'; if ('!_DriveType!' -ne '') { $q=$q+' WHERE '+'!_DriveType!' }; Get-CimInstance -Query $q | ForEach-Object { 'DeviceID=' + $_.DeviceID }"
    `) do if "%%~b" neq "" for /f "usebackq tokens=1 delims=:" %%c in (
        '%%b'
    ) do if defined _desc (
        set "_var=%%c !_var!"
    ) else set "_var=!_var! %%c"
    goto skip\legacy_letters
    :legacy\letters
    if defined _DriveType (set "_DriveType=where !_DriveType!") else set "_DriveType="
    for /f "usebackq skip=1 delims=:" %%a in (`
        wmic.exe logicaldisk !_DriveType! get DeviceID
    `) do if defined _desc (
        set "_var=%%a !_var!"
    ) else set "_var=!_var! %%a"
    :skip\legacy_letters
    if defined _var set "_var=%_var:~1%"
    if defined _desc if defined _var set "_var=%_var:~0,-1%"
    endlocal & set %~1=%_var%
    exit /b 0

::: "    -lc, --lock=LETTER: [-f]                  lock the BitLocker volume; -f forces a dismount"
:sub\vol\--lock
:sub\vol\-lc
    :: TODO: mount the volume at a directory path.
    :: Valid targets are 'C:', '\\?\Volume{26a21bda-a627-11d7-9931-806e6f6e6963}\' or 'C:\MountVolume'.
    if "%~2"=="-f" (
        manage-bde.exe -lock %~d1 -ForceDismount
    ) else manage-bde.exe -lock %~d1
    goto :eof

::: "    -u, --unlock=LETTER: [KEY/PASSWORD]       unlock the volume with a recovery key file or password"
:sub\vol\--unlock
:sub\vol\-u
    if "%~2"=="" exit /b 91 @REM The argument is empty.
    if exist "%~2" (
        manage-bde.exe -unlock %~d1 -RecoveryKey "%~2"
    ) else manage-bde.exe -unlock %~d1 -Password %~2
    goto :eof

::: "    --auto-unlock=LETTER:                     enable auto-unlock for the BitLocker volume"
:sub\vol\--auto-unlock
    if /i "%~d1"=="%SystemDrive%" exit /b 84 @REM The system drive %SystemDrive% is skipped.
    :: Enable auto-unlock only when the system drive is encrypted.
    call :sub\vol\--crypts-status %SystemDrive% && manage-bde.exe ^
                                                    -autounlock ^
                                                    -enable %~d1 >nul || exit /b 83 @REM The manage-bde command failed.

    goto :eof

::: "    --hide-bitlocker                          [DANGER^^^!] hide the BitLocker feature; this is irreversible"
:sub\vol\--hide-bitlocker
    setlocal enabledelayedexpansion
    call :regedit\on
    :: Remove the BitLocker entries from the drive context menu.
    for %%a in (
        encrypt-bde encrypt-bde-elev
        manage-bde
        resume-bde resume-bde-elev
        unlock-bde
    ) do >nul 2>nul reg.exe delete HKCR\Drive\shell\%%a /f

    :: Hide the BitLocker applets in Control Panel.
    >nul 2>nul reg.exe ^
            add HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer ^
                /v DisallowCpl ^
                /t REG_DWORD ^
                /d 1 /f

    set _index=0
    >nul reg.exe ^
            delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowCpl /f
    for %%a in (
        BitLockerDriveEncryption Recovery
    ) do set /a _index +=1 & >nul reg.exe ^
            add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowCpl ^
                /v !_index! ^
                /t REG_SZ ^
                /d Microsoft.%%a /f

    :: Change the drive icon of every fixed disk.
    call :this\cim || goto legacy\bitlocker_icon
    for /f "usebackq tokens=1,2" %%a in (
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance -Query 'SELECT DeviceID,DriveType FROM Win32_LogicalDisk' | Select-Object -Property DeviceID,DriveType | Format-Table -HideTableHeaders"
    ) do if "%%b"=="3" (
    goto skip\legacy_bitlocker_icon
    :legacy\bitlocker_icon
    for /f "usebackq skip=1 tokens=1,2" %%a in (
        wmic.exe logicaldisk get DeviceID^,DriveType
    ) do if "%%b"=="3" (
    :skip\legacy_bitlocker_icon
        if /i "%%~a"=="%SystemDrive%" (
            set /a _index=31
        ) else set /a _index=27
        for /f "usebackq delims=:" %%d in (
            '%%~a'
        ) do >nul reg.exe ^
                add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons\%%d\DefaultIcon ^
                    /ve ^
                    /t REG_SZ ^
                    /d "%SystemRoot%\System32\imageres.dll,!_index!" /f
    )
    call :regedit\off
    endlocal

    >&3 echo complete.
    goto :eof

::: "    --encrypts-all=LETTER:                    encrypt every fixed volume with BitLocker using a removable drive" "                  pass --safe to also deny write access to fixed and removable drives not protected by BitLocker" ""
:sub\vol\--encrypts-all
    for %%a in (manage-bde.exe) do if "%%~$path:a"=="" exit /b 64 @REM The manage-bde feature is not enabled.
    if /i "%username%"=="System" exit /b 60 @REM Not supported in WinPE.
    call :sub\oset\--vergeq 10.0 || exit /b 62 @REM The operating system version is not supported.

    setlocal
    set _tmp_letter=
    if /i "%~1"=="%~d1" (
        if exist "%~1" set _tmp_letter=%~d1
    ) else if /i "%~2"=="%~d2" if exist "%~2" set _tmp_letter=%~d2

    set _removable_letter=
    call :this\cim || goto legacy\removable
    if defined _tmp_letter (
        for /f "usebackq" %%a in (`
            PowerShell.exe ^
                -NoLogo ^
                -NonInteractive ^
                -ExecutionPolicy Unrestricted ^
                -Command "Get-CimInstance -Query 'SELECT DeviceID FROM Win32_LogicalDisk WHERE DriveType=2' | ForEach-Object { $_.DeviceID }"
        `) do if /i "%%a"=="%_tmp_letter%" set _removable_letter=%%a

    ) else for /f "usebackq tokens=1,2 delims=," %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance -Query 'SELECT Access,DeviceID FROM Win32_LogicalDisk WHERE DriveType=2' | Select-Object -Property Access,DeviceID | Format-Table -HideTableHeaders"
    `) do if "%%a"=="0" set _removable_letter=%%b
    goto skip\legacy_removable
    :legacy\removable
    for %%a in (_tmp_letter) do if defined %%~a (
        for /f "usebackq skip=1 tokens=1" %%a in (`
            wmic.exe logicaldisk where "DriveType=2" get DeviceID
        `) do if /i "%%a"=="%_tmp_letter%" set _removable_letter=%%a
    ) else for /f "usebackq skip=1 tokens=1,2" %%a in (`
        wmic.exe logicaldisk where "Access=0 and DriveType=2" get Access^,DeviceID
    `) do if "%%a"=="0" set _removable_letter=%%b
    :skip\legacy_removable
    set _tmp_letter=

    if not defined _removable_letter exit /b 61 @REM The removable drive was not found or is read-only.

    >&3 echo find removable drives '%_removable_letter%'

    call :regedit\on
    :: Equivalent Group Policy path: Computer Configuration - Administrative Templates - Windows Components - BitLocker Drive Encryption - Operating System Drives.
    for %%a in (
        "UseAdvancedStartup /t REG_DWORD /d 1"
        "EnableBDEWithNoTPM /t REG_DWORD /d 1"
        "UseTPM /t REG_DWORD /d 0"
        "UseTPMPIN /t REG_DWORD /d 0"
        "UseTPMKey /t REG_DWORD /d 0"
        "UseTPMKeyPIN /t REG_DWORD /d 0"
    ) do >nul reg.exe add HKLM\Software\Policies\Microsoft\FVE /v %%~a /f

    :: Allow write access to removable drives.
    >nul 2>nul reg.exe delete HKLM\System\CurrentControlSet\Policies\Microsoft\FVE ^
        /v RDVDenyWriteAccess /f && >&3 echo [WARN] Try to re insert removable drives

    :: Populate the %_vol_c_info% variables used for the key directory.
    call :this\disk_serial_path

    call :this\baseboard_serial_path _baseboard_info
    call :sub\time\--now _now
    :: Prefix the baseboard info with the run time so repeated runs stay unique.
    set _baseboard_info=%_now:~0,-4%.%_baseboard_info%
    set _now=

    :: Encrypt each fixed volume with a key stored on the removable drive.
    call :this\cim || goto legacy\bitlocker_lock
    for /f "usebackq tokens=1,2" %%a in (
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance -Query 'SELECT DeviceID,DriveType FROM Win32_LogicalDisk' | Select-Object -Property DeviceID,DriveType | Format-Table -HideTableHeaders"
    ) do if "%%b"=="3" (
    goto skip\legacy_bitlocker_lock
    :legacy\bitlocker_lock
    for /f "usebackq skip=1 tokens=1,2" %%a in (
        wmic.exe logicaldisk get DeviceID^,DriveType
    ) do if "%%b"=="3" (
    :skip\legacy_bitlocker_lock
        if not exist %_removable_letter% (
            call :regedit\off
            exit /b 60 @REM The partition was not found.
        )
        call :bitLocker\on\key %%a %_removable_letter% || (
            call :regedit\off
            exit /b %errorlevel%
        )
    )

    if "%~1" neq "--safe" if "%~1" neq "-s" if "%~2" neq "--safe" if "%~2" neq "-s" goto :skip\deny_write_access
    call :oset\write_access\--deny
    :skip\deny_write_access

    call :regedit\off
    endlocal

    echo,
    exit /b 0

::: "    --encrypts=LETTER: [KEY_DRIVE:]           encrypt the volume with BitLocker, storing the key on KEY_DRIVE:"
:sub\vol\--encrypts
    for %%a in (manage-bde.exe) do if "%%~$path:a"=="" exit /b 74 @REM The manage-bde feature is not enabled.
    if /i "%username%"=="System" exit /b 70 @REM Not supported in WinPE.
    if /i "%~1" neq "%~d1" exit /b 76 @REM The target is not a drive letter or is not supported.
    if not exist "%~1" exit /b 78 @REM The drive letter was not found.
    call :sub\vol\--crypts-status %~d1 && (
        echo [%~d1] already encrypts.
        exit /b 0
    )

    if "%~2"=="" manage-bde.exe -on %~d1 ^
                -UsedSpaceOnly ^
                -Synchronous ^
                -Password || exit /b 73 @REM The manage-bde command failed.

    if "%~2"=="" goto :eof

    if /i "%~2" neq "%~d2" exit /b 77 @REM The argument is not a removable drive letter.
    if not exist "%~2" exit /b 79 @REM The removable drive letter does not exist.

    setlocal

    :: Populate the %_vol_c_info% variables used for the key directory.
    call :this\disk_serial_path

    call :this\baseboard_serial_path _baseboard_info
    call :sub\time\--now _now
    :: Prefix the baseboard info with the run time so other batch runs stay unique.
    set _baseboard_info=%_now:~0,-4%.%_baseboard_info%
    set _now=

    call :bitLocker\on\key %~d1 %~d2

    endlocal
    goto :eof

::: "    --decrypts=LETTER:                        decrypt the BitLocker volume"
:sub\vol\--decrypts
    for %%a in (manage-bde.exe) do if "%%~$path:a"=="" exit /b 84 @REM The manage-bde feature is not enabled.
    if /i "%username%"=="System" exit /b 80 @REM Not supported in WinPE.
    if not exist "%~1" exit /b 88 @REM The drive letter was not found.

    :: Check the system drive instead of the target volume.
    if /i "%~d1" neq "%SystemDrive%" call :sub\vol\--crypts-status %SystemDrive% && goto skip\allow_write_access
    call :sub\oset\--unsecure-write --allow
    :skip\allow_write_access

    @REM manage-bde.exe -autounlock -ClearAllKeys Volume
    manage-bde.exe -off %~d1 || exit /b 83 @REM The manage-bde command failed.
    exit /b 0

:: Shared by ':sub\vol\--encrypts-all' and ':sub\vol\--encrypts'.
:bitLocker\on\key
    echo,
    echo,
    >&3 echo Encryption [%~d1] ...
    @REM title Encryption [%~d1] ...

    setlocal enabledelayedexpansion
    set _vol=%~d1
    set _vol=%_vol::=%
    set _removable_letter=%~d2
    @REM call :test\tpm

    call :sub\vol\--crypts-status %_vol%: && (
        >&3 echo Skip encrypt [%_vol%:]
        if /i "%~d1" neq "%SystemDrive%" call :sub\vol\--auto-unlock %_vol%:
        goto :eof
    )

    set _key_type=StartupKey
    if /i "%~d1" neq "%SystemDrive%" set _key_type=RecoveryKey

    set _key_name=
    for /f "usebackq" %%a in (`
        manage-bde.exe ^
            -on %_vol%: ^
            -UsedSpaceOnly ^
            -EncryptionMethod xts_aes128 -%_key_type% %~d2\ ^
            -SkipHardwareTest
    `) do if /i "%%~xa"==".bek" set _key_name=%%~a

    if not defined _key_name exit /b 83 @REM The manage-bde command failed.

    attrib.exe -s -h -r %_removable_letter%\%_key_name%

    :: Key path example: K:\externalkeys\[disk_model]\[SN]\[time+baseboard_info]\[vol_SN]\K\.
    for %%b in (
        _vol_%_vol%_info
    ) do for %%c in (
        %_removable_letter%\externalkeys\!%%b!
    ) do set _key_dir=%%~dpc%_baseboard_info%\%%~nxc\%_vol%\

    2>nul mkdir %_key_dir%

    if /i "%~d1" neq "%SystemDrive%" (
        move %_removable_letter%\%_key_name% %_key_dir%
        call :sub\vol\--auto-unlock %_vol%:

    ) else copy %_removable_letter%\%_key_name% %_key_dir%

    endlocal
    exit /b 0

:this\baseboard_serial_path [var_name]
    setlocal enabledelayedexpansion
    :: Read the vendor, model name and UUID of the system board.
    for /f "usebackq tokens=1* delims==" %%a in (`
    call :this\cim || goto legacy\csproduct
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance Win32_ComputerSystemProduct | Select-Object -Property Name,UUID,Vendor | Format-List"
    goto skip\legacy_csproduct
    :legacy\csproduct
        wmic.exe csproduct get Name^,UUID^,Vendor /value
    :skip\legacy_csproduct
    `) do if "%%~b" neq "" call :this\joint_serial #$_+\%%a %%b
    :: Build the result as [vendor].[model_name].[uuid].
    endlocal & set %~1=%#$_+\Vendor%.%#$_+\Name%.%#$_+\UUID%
    goto :eof

:: Populate the %_vol_c_info% variables.
:this\disk_serial_path
    setlocal enabledelayedexpansion
    for /f "usebackq tokens=1* delims==" %%a in (`
    call :this\cim || goto legacy\diskdrive
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance Win32_DiskDrive | Where-Object { $_.InterfaceType -eq 'SCSI' -or $_.InterfaceType -eq 'IDE' } | Select-Object -Property Index,Model,SerialNumber | Format-List"
    goto skip\legacy_diskdrive
    :legacy\diskdrive
        wmic.exe diskdrive where "InterfaceType='SCSI' or InterfaceType='IDE'" get Index^,Model^,SerialNumber /value
    :skip\legacy_diskdrive
    `) do if "%%~b" neq "" (
        if "%%~a"=="Index" (
            set /a %%~a=%%~b
        ) else call :this\joint_serial #$_+\!Index!\%%~a %%~b
    )
    set Index=

    :: DriveType values (https://docs.microsoft.com/zh-cn/dotnet/api/system.io.drivetype).
    for /f "usebackq tokens=1,2 delims=," %%a in (`
    call :this\cim || goto legacy\volserial
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance -Query 'SELECT DeviceID,VolumeSerialNumber FROM Win32_LogicalDisk WHERE DriveType=3' | Select-Object -Property DeviceID,VolumeSerialNumber | Format-Table -HideTableHeaders"
    goto skip\legacy_volserial
    :legacy\volserial
        wmic.exe logicaldisk where "DriveType=3" get DeviceID^,VolumeSerialNumber
    :skip\legacy_volserial
    `) do if "%%~b" neq "" for /f "usebackq tokens=1 delims=:" %%c in (
        '%%a'
    ) do call :this\joint_serial #$_+\%%c\VolumeSerialNumber %%b

    set _vars=
    for /f "usebackq tokens=1* delims==" %%a in (`
    call :this\cim || goto legacy\ldtp
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance -Namespace root\cimv2 -ClassName Win32_LogicalDiskToPartition | ForEach-Object { 'Antecedent=' + $_.Antecedent + ' Dependent=' + $_.Dependent }"
    goto skip\legacy_ldtp
    :legacy\ldtp
        wmic.exe /namespace:\\root\cimv2 path Win32_LogicalDiskToPartition
    :skip\legacy_ldtp
    `) do for /f "usebackq tokens=2,4,5 delims=,#: " %%c in (
        '%%a^,%%b'
    ) do if defined #$_+\%%c\Model set _vars=!_vars! "_vol_%%e_info=!#$_+\%%c\Model!\!#$_+\%%c\SerialNumber!\!#$_+\%%e\VolumeSerialNumber!"

    :: Each _vol_[letter]_info variable holds [disk_model]\[SN]\[vol_SN].
    endlocal & for %%a in (%_vars%) do set %%~a
    goto :eof

:this\joint_serial
    if "%~2"=="" set %~1=!%~1:.=!& goto :eof
    for %%a in (
        Inc Co Ltd LLC Corp
    ) do if /i "%~2"=="%%a." shift /2 & goto this\joint_serial
    if not defined %~1 (
        set %~1=%~2
    ) else set %~1=!%~1!_%~2
    shift /2 & goto this\joint_serial

::: "    -cs, --crypts-status=LETTER: [--more/-m]  test whether the volume is BitLocker protected" "                                                return success when the volume is protected" "                  [--more/-m] print the manage-bde status report" ""
:sub\vol\--crypts-status
:sub\vol\-cs
    for %%a in (manage-bde.exe) do if "%%~$path:a"=="" exit /b 94 @REM The manage-bde feature is not enabled.
    if "%~1"=="" exit /b 96 @REM The target is not a drive letter or is not supported.
    if /i "%~1" neq "%~d1" exit /b 96 @REM The target is not a drive letter or is not supported.

    if "%~2" neq "--more" if "%~2" neq "-m" goto skip\show_crypts_status
    manage-bde.exe -status %~d1
    exit /b 0
    :skip\show_crypts_status

    @REM :: The volume is encrypted, return true.
    @REM >nul manage-bde.exe -status %~d1 -ProtectionAsErrorLevel && exit /b 0
    for /f "usebackq tokens=2*" %%a in (`
        manage-bde.exe -status %~d1
    `) do (
        if "%%b"=="2.0" exit /b 0
        if /i "%%b"=="AES 128" exit /b 0
        if /i "%%b"=="AES 256" exit /b 0
        if /i "%%b"=="XTS-AES 128" exit /b 0
        if /i "%%b"=="XTS-AES 256" exit /b 0
    )
    exit /b -1

:: Trusted Platform Module (TPM) test.
:test\tpm
    2>nul PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command Get-TpmSupportedFeature && exit /b 0
    exit /b 1

::: "    -w, --wipes=LETTER:                       wipe the free space on the volume"
:sub\vol\--wipes
:sub\vol\-w
    :: TODO: mount the volume at a directory path.
    if "%~1"=="" exit /b 105 @REM The target path was not found.
    if /i "%~1" neq "%~d1" exit /b 105 @REM The target path was not found.
    if not exist %~d1 exit /b 105 @REM The target path was not found.
    call :sub\vol\--crypts-status %~d1 && (
        manage-bde.exe -WipeFreeSpace %~d1
    ) || cipher.exe /w:%~d1
    goto :eof

::: "    -t, --trim[=LETTER:]                      trim the SSD; a hard disk is not supported"
:sub\vol\--trim
:sub\vol\-t
    :: TODO: mount the volume at a directory path.
    if "%~1"=="" exit /b -1
    if /i "%~1" neq "%~d1" exit /b -1
    if not exist "%~1" exit /b -1
    for /f "usebackq" %%a in (`
        defrag.exe %~d1 /l 2^>&1
    `) do for %%b in (
        %%~a
    ) do if /i "%%b"=="(0x8900002A)" exit /b 0
    exit /b -1

::: "Convert an integer to hexadecimal" "" "Usage: %~n0 2hex [INT] [VAR]"
:xlib\2hex
    setlocal
    set _0f=0123456789abcdef
    set /a _int=%~1
    if "%_int%" neq "%~1" exit /b 2 @REM Not an integer.
    :2hex_loop
    set /a _index=_int %% 16, _int /= 16
    call set _hex=%%_0f:~%_index%,1%%%_hex%
    if %_int% geq 10 goto 2hex_loop
    if %_int% neq 0 set _hex=%_int%%_hex%
    endlocal & if "%~2"=="" (
        echo 0x%_hex%
    ) else set %~2=0x%_hex%
    goto :eof

::: "Uncompress an archive or package" "" "Usage: %~n0 un [FILE] [DIR]"
:xlib\un
    call :sub\un\%~x1 %1
    goto :eof

:sub\un\.cab
    mkdir ".\%~n1"
    expand.exe %1 -F:* ".\%~n1"
    @REM for %%a in (cabarc.exe) do if "%%~$path:a"=="" exit /b 18 @REM The cabarc.exe command was not found.
    @REM pushd %cd%
    @REM mkdir ".\%~n1" && chdir /d ".\%~n1" && cabarc.exe x %1 *
    @REM popd
    exit /b 0

:sub\un\.zip
    if not exist "%~1" exit /b 22 @REM The target was not found.
    setlocal
    set "_output=.\%~n1"
    if "%~2" neq "" set "_output=%~2"
    call :xlib\vbs unzip "%~f1" "%_output%"
    endlocal
    exit /b 0

:sub\un\.exe
    if not exist "%~1" exit /b 32 @REM The target was not found.
    call :sub\oset\--vergeq 10.0 || exit /b 33 @REM The system version is too old.
    compact.exe /u /exe /a /i /q /s:"%~f1"
    exit /b 0

:: Uncompress a CHM help file.
:sub\un\.chm
    if not exist "%~1" exit /b 44 @REM The CHM file was not found.
    if /i "%~x1" neq ".chm" exit /b 45 @REM The file is not a CHM file.
    if exist ".\%~sn1" exit /b 46 @REM The output file already exists.
    start /wait hh.exe -decompile .\%~sn1 %~s1
    exit /b 0

:: Uncompress an MSI package.
:sub\un\.msi
    if not exist "%~1" exit /b 52 @REM The target was not found.
    if /i "%~x1" neq ".msi" exit /b 57 @REM The file is not an MSI package.
    2>nul mkdir ".\%~n1" || exit /b 56 @REM The output file already exists.
    setlocal
    :: Map the output directory to a free drive letter.
    call :sub\vol\--free-letter _letter
    subst.exe %_letter% ".\%~n1"

    :: Extract the MSI package onto the mapped drive.
    start /wait msiexec.exe /a %1 /qn targetdir=%_letter%
    erase "%_letter%\%~nx1"
    @REM for %%a in (".\%~n1") do echo output: %%~fa

    subst.exe %_letter% /d
    endlocal
    exit /b 0


::: "Compress files into an archive" "" "Usage: %~n0 pkg [OPTION]..." ""
:xlib\pkg
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\pkg\%*
    goto :eof

::: "    -z, --zip=SOURCE [TARGET]               create a ZIP archive from SOURCE"
:sub\pkg\--zip
:sub\pkg\-z
    setlocal
    set "_output=.\%~n1"
    if "%~2" neq "" set "_output=%~2"
    if /i "%~x1" neq ".zip" call :xlib\vbs zip "%~f1" "%_output%.zip"
    endlocal
    @REM >.\zip.ZFSendToTarget (
    @REM     echo [Shell]
    @REM     echo Command=2
    @REM     echo IconFile=explorer.exe,3
    @REM     echo [Taskbar]
    @REM     echo Command=ToggleDesktop
    @REM )
    goto :eof

::: "    -c, --cab=TARGET                        create a CAB archive from TARGET"
:sub\pkg\--cab
:sub\pkg\-c
    for %%a in (cabarc.exe) do if "%%~$path:a"=="" exit /b 28 @REM The cabarc.exe command was not found.
    :: Compress the whole directory when no file list is given.
    if "%~2"=="" call :sub\dir\--isdir %1 ^
        && cabarc.exe -m LZX:21 n ".\%~n1.tmp" "%~1\*"

    :: Compress the listed files when the target is not a directory.
    call :sub\dir\--isdir %1 ^
        || cabarc.exe -m LZX:21 n ".\%~n1.tmp" %*

    if exist ".\%~n1.tmp" rename ".\%~n1.tmp" "%~n1.cab"
    goto :eof

::: "    -u, --udf=DIR                           create an ISO image from the directory DIR"
:sub\pkg\--udf
:sub\pkg\-u
    for %%a in (oscdimg.exe) do if "%%~$path:a"=="" >nul call :init\oscdimg
    call :sub\dir\--isdir %1 ||  exit /b 32 @REM The target is not a directory.
    if /i "%~d1\"=="%~1" exit /b 33 @REM The drive root is not supported.

    :: Retry with the trailing backslash removed when the directory name is empty.
    if "%~n1"=="" (
        setlocal enabledelayedexpansion
        set _args=%~1
        if "!_args:~-1!" neq "\" (
            call :sub\var\--set-errorlevel 3
        ) else call %0 "!_args:~0,-1!"
        endlocal & goto :eof
    )

    if exist "%~1\sources\boot.wim" (
        :: Build a WinPE bootable image.
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 34 @REM The etfsboot.com file was not found.
        if not exist %windir%\Boot\DVD\EFI\en-US\efisys.bin exit /b 35 @REM The efisys.bin file was not found.
        @REM echo El Torito udf %~nx1
        >%temp%\bootorder.txt type nul
        for %%a in (
            bootmgr
            boot\bcd
            boot\boot.sdi
            efi\boot\bootx64.efi
            efi\microsoft\boot\bcd
            sources\boot.wim
        ) do if exist "%~1\%%a" >>%temp%\bootorder.txt echo %%a
        oscdimg.exe ^
            -bootdata:2#p0,e,b%windir%\Boot\DVD\PCAT\etfsboot.com#pEF,e,b%windir%\Boot\DVD\EFI\en-US\efisys.bin ^
                -yo%temp%\bootorder.txt ^
                -l"%~nx1" ^
                -o ^
                -u2 ^
                -udfver102 %1 ".\%~nx1.tmp"

        erase %temp%\bootorder.txt
    ) else if exist "%~1\I386\NTLDR" (
        :: Build a Windows XP bootable image.
        @REM echo El Torito %~nx1
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 34 @REM The etfsboot.com file was not found.
        oscdimg.exe ^
            -b%windir%\Boot\DVD\PCAT\etfsboot.com ^
                -k ^
                -l"%~nx1" ^
                -m ^
                -n ^
                -o ^
                -w1 %1 ".\%~nx1.tmp"
    ) else (
        :: Build a plain UDF image.
        @REM echo oscdimg udf
        oscdimg.exe -l"%~nx1" -o -u2 -udfver102 %1 ".\%~nx1.tmp"
    )
    rename "./%~nx1.tmp" "*.iso"
    exit /b 0

::: "    -e, --exe=SOURCE                        compress SOURCE with the algorithm for executable files" "                                              (files that are read frequently and not modified)"
:sub\pkg\--exe
:sub\pkg\-e
    compact.exe /c /exe /a /i /q /s:"%~f1"
    goto :eof


:: oscdimg.exe comes from the Windows 10 ADK; it is downloaded into a temp directory.
:init\oscdimg
    for %%a in (_%0) do if %processor_architecture:~-2%==64 (
        :: 64-bit (AMD64) download.
        call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk ^
            bbf55224a0290f00676ddc410f004498 ^
            fild40c79d789d460e48dc1cbd485d6fc2e
    :: 32-bit (x86) download.
    ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk ^
                    5d984200acbde182fd99cbfbe9bad133 ^
                    fil720cc132fbb53f3bed2e525eb77bdbc1
    exit /b 0

:: The temp directory name is the MD5 sum of the text 'cab': 16ecfd64-586e-c6c1-ab21-2762c2c38a90.
:this\getCab [file_name] [uri_sub] [cab] [file]
    2>nul mkdir %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90
    call :xlib\download ^
        http://download.microsoft.com/download/%~2/Installers/%~3.cab ^
            %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90\%~1.cab

    expand.exe ^
        %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90\%~1.cab ^
        -f:%~4 ^
        %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90

    erase %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90\%~1.cab
    rename %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90\%~4 %~1.exe
    for %%a in (%~1.exe) do if "%%~$path:a"=="" set PATH=%PATH%;%temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90
    exit /b 0

::: "Change the owner of a file or directory to the current user" "" "Usage: %~n0 own [PATH]"
:xlib\own
    if not exist "%~1" exit /b 2 @REM The path was not found.
    call :sub\dir\--isdir %1 ^
        && takeown.exe /f %1 /r /d y ^
            && icacls.exe %1 /grant:r %username%:f /t /q

    call :sub\dir\--isdir %1 ^
        || takeown.exe /f %1 ^
            && icacls.exe %1 /grant:r %username%:f /q

    exit /b 0

::::::::::::::::
:: PowerShell ::
::::::::::::::::

::: "Download a file from a URL" "" "Usage: %~n0 download [URL] [FILE]"
:xlib\download
    if "%~2"=="" exit /b 2 @REM output path is empty
    @REM certutil.exe -urlcache -split -f %1 %2
    :: Windows 10 1803 and later ship curl.exe.
    for %%a in (curl.exe) do if "%%~$path:a" neq "" curl.exe -L --retry 10 -o %2 %1 && exit /b 0
    call :this\psv
    if errorlevel 3 PowerShell.exe ^
                        -NoLogo ^
                        -NonInteractive ^
                        -ExecutionPolicy Unrestricted ^
                        -Command "Invoke-WebRequest -uri %1 -OutFile %2 -UseBasicParsing" && exit /b 0

    call :xlib\vbs get %1 %2 || exit /b 4 @REM download error
    exit /b 0

::: "Boot tools" "" "Usage: %~n0 boot [OPTION]..." ""
:xlib\boot
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\boot\%*
    goto :eof

::: "    -g, --legacy[=LETTER:]          set the legacy boot menu style"
:sub\boot\--legacy
:sub\boot\-g
    if "%~1"=="" (
        bcdedit.exe /set {default} bootmenupolicy legacy
    ) else (
        if exist "%~1" (
            bcdedit.exe /store "%~f1" /set {default} bootmenupolicy legacy
        ) else exit /b 14 @REM target not found
    )
    goto :eof

::: "    -f, --file=LETTER:              copy the Windows PE boot files from a CD-ROM"
:sub\boot\--file
:sub\boot\-f
    if /i "%~1" neq "%~d1" exit /b 21 @REM target not letter
    if not exist "%~d1" exit /b 22 @REM target_letter not exist
    for /l %%a in (0,1,9) do if exist \\?\CDROM%%a\boot\boot.sdi (
        :: Tell macOS Spotlight not to index the volume.
        >%~d1\.metadata_never_index type nul
        attrib.exe +s +h %~d1\.metadata_never_index
        for %%b in (
            \bootmgr
            \boot\bcd
            \boot\boot.sdi
            \efi\boot\bootx64.efi
            \efi\microsoft\boot\bcd
            \sources\sxs\
            ::?\sources\acpi_hal\
            ::?\sources\pci\cc_01\
            ::?\sources\pci\cc_02\
            \support\
        ) do (
            if not exist %~d1%%~pb mkdir %~d1%%~pb
            if exist \\?\CDROM%%a%%b copy /y \\?\CDROM%%a%%b %~d1%%b
        )

        @REM copy /y \\?\CDROM%%a\sources\sxs\* %~d1\sources\sxs
        exit /b 0
    )
    exit /b 23 @REM Window PE CDROM not found

:: Recovery environment.
::: "    -r, --winre=FILE                set up the Windows Recovery Environment image"
:sub\boot\--winre
:sub\boot\-r
    if not exist "%~1" exit /b 34 @REM target not found
    if /i "%~x1" neq ".wim" exit /b 35 @REM not wim file
    if "%~p1"=="\" exit /b 36 @REM wim file must put in some directory
    reagentc.exe /disable
    reagentc.exe /setreimage /path "%~1"
    reagentc.exe /enable
    reagentc.exe /info
    @REM attrib.exe +s +h +r "%~dp1" /d /s
    bcdedit.exe /set {default} bootmenupolicy legacy
    goto :eof

:: TODO
:winre\boot     [bcd_path] [boot_type] [wim_path]
    setlocal enabledelayedexpansion
    set _uuid=
    for /f "usebackq tokens=2 delims={}" %%a in (`
        bcdedit.exe /store %1 /create /d "Windows Recovery" /device
    `) do for /f "usebackq tokens=2 delims={}" %%b in (`
        bcdedit.exe /store %1 /create /d "Windows Recovery Environment" /application osloader
    `) do (
        for %%c in (
            "{%%a} ramdisksdidevice partition=%~d3"
            "{%%a} ramdisksdipath %~p3boot.sdi"
            "{%%b} device ramdisk=[%~d3]%~pnx3,{%%a}"
            "{%%b} path \Windows\system32\winload.%~2"
            "{%%b} osdevice ramdisk=[%~d3]%~pnx3,{%%a}"
            "{%%b} systemroot \Windows"
            "{%%b} nx OptIn"
            "{%%b} winpe Yes"
        ) do bcdedit.exe /store %1 /set %%~c

        for /f "usebackq tokens=1*" %%c in (`
            bcdedit.exe /store %1 /v
        `) do for /f "delims==" %%e in (
            "%%d"
        ) do (
            if "%%c"=="identifier" set _uuid=%%d
            if "%%c%%e"=="osdevicevhd" for %%f in (
                "!_uuid! recoverysequence {%%b}"
                "!_uuid! recoveryenabled yes"
            ) do bcdedit.exe /store %1 /set %%~f
        )
    )
    endlocal

    bcdedit.exe /store %1 /set {default} bootmenupolicy legacy
    goto :eof


::: "    -p, --winpe=FILE                create a WinPE boot menu"
:sub\boot\--winpe [wim]
:sub\boot\-p
    if not exist "%~2" exit /b 44 @REM target not found
    copy /y %windir%\Boot\DVD\PCAT\boot.sdi "%~dp1"
    2>nul mkdir %~d1\boot

    @REM :: winpe boot from disk
    @REM bcdedit.exe /createstore %~d1\boot\bcd
    @REM bcdedit.exe /store %~d1\boot\bcd /create {bootmgr} /d "Boot Manager"
    @REM bcdedit.exe /store %~d1\boot\bcd /set {bootmgr} device boot
    @REM for /f "tokens=2 delims={}" %%a in (
    @REM     'bcdedit.exe /store %~d1\boot\BCD /create /d "WINPE" /application osloader'
    @REM ) do set GUID=%%a
    @REM set GUID=%GUID:~0,-7%
    @REM for %%c in (
    @REM     "/set {%GUID%} osdevice boot"
    @REM     "/set {%GUID%} device boot"
    @REM     "/set {%GUID%} path \windows\system32\boot\winload.exe"
    @REM     "/set {%GUID%} systemroot \windows"
    @REM     "/set {%GUID%} winpe yes"
    @REM     "/displayorder {%GUID%} /addlast"
    @REM ) do bcdedit.exe /store %~d1\boot\bcd %%~c

    for /f "tokens=2 delims={}" %%a in (`
        bcdedit.exe /store "%~d1\boot\bcd" /create /d "winpe" /device
    `) do for /f "tokens=2 delims={}" %%b in (`
        bcdedit.exe /store "%~d1\boot\bcd" /create /d "Windows Preinstallation or Recovery Environment" /application osloader
    `) do for %%c in (
        "{%%a} ramdisksdidevice partition=%~d1"
        "{%%a} ramdisksdipath %~d1\boot\boot.sdi"
        "{%%b} device ramdisk=[%~d1]%~pnx1,{%%a}"
        ::?"{%%b} path \Windows\system32\winload.efi"
        "{%%b} path \Windows\system32\winload.exe"
        "{%%b} osdevice ramdisk=[%~d1]%~pnx1,{%%a}"
        "{%%b} systemroot \Windows"
        "{%%b} nx OptIn"
        "{%%b} winpe Yes"
    ) do bcdedit.exe /store "%~f1" /set %%~c

    goto :eof

:: Detect whether the current boot device is a VHD.
:sub\boot\--is-vhd-os
    >nul chcp 437
    for /f "usebackq tokens=1*" %%a in (`
        bcdedit.exe /v /enum {current}
    `) do if .%%a==.osdevice for /f "tokens=2,3 delims=[,=]" %%c in (
        "%%b"
    ) do if %%d. neq . if exist "%%c%%d" (
        if /i .%%~xd neq ..vhd exit /b 0
        if /i .%%~xd neq ..vhdx exit /b 0
    )
    exit /b -1

:::TODO "    -rb, --rebuild [LETTER:]   rebuild the system boot menu"
:sub\boot\--rebuild
:sub\boot\-rb
    goto :eof

::: "Add or remove web credentials" "" "Usage: %~n0 crede [OPTION]..." ""
:xlib\crede
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\crede\%*
    goto :eof

::: "    -a, --add=[USER]@[HOST] [PASSWORD]     add a credential for HOST"
:sub\crede\--add
:sub\crede\-a
    if "%~1"=="" exit /b 12 @REM parameter not enough
    setlocal
    set _prefix=
    set _suffix=
    for /f "usebackq tokens=1* delims=@" %%a in (
        '%~1'
    ) do set _prefix=%%a& set _suffix=%%b

    if not defined _suffix exit /b 14 @REM no ip or host

    :: Clear the existing credential.
    >nul call :sub\crede\-r %_suffix%

    set _arg=
    if "%~2" neq "" set _arg=/pass:%~2
    :: Add the credential.
    echo cmdkey.exe /add:%_suffix% /user:%_prefix% %_arg%
    >nul cmdkey.exe /add:%_suffix% /user:%_prefix% %_arg% || exit /b 13 @REM Command error
    endlocal
    exit /b 0

::: "    -r, --remove=HOST                      remove the credential for HOST"
:sub\crede\--remove
:sub\crede\-r
    if "%~1"=="" exit /b 22 @REM parameter not enough
    cmdkey.exe /delete:%~1
    exit /b 0


::: "Mount or unmount SMB shares" "" "Usage: %~n0 smb [OPTION]..." ""
:xlib\smb
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\smb\%*
    goto :eof

::: "    -m, --mount=HOST [PATH]...      mount SMB shares from HOST"
:sub\smb\--mount
:sub\smb\-m
    if "%~2"=="" exit /b 12 @REM parameter not enough
    for %%a in (%2 %3 %4 %5 %6 %7 %8 %9) do net.exe use * "\\%~1\%%~a" /savecred /persistent:yes || exit /b 13 @REM Command error
    exit /b 0

::: "    -u, --umount=HOST               unmount the SMB shares of HOST"
:sub\smb\--umount
:sub\smb\-u
    if "%~1"=="" exit /b 22 @REM parameter not enough
    for /f "usebackq tokens=2,3" %%a in (`
        net.exe use
    `) do if "%%~pb"=="%~1\" net.exe use %%a /delete
    exit /b 0

::: "    -ua, --umountall                unmount all SMB shares"
:sub\smb\--umountall
:sub\smb\-ua
    net.exe use * /delete /y
    exit /b 0

::: "Mount or unmount NFS exports" "" "Usage: %~n0 nfs [OPTION]..." ""
:xlib\nfs
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\nfs\%*
    exit /b 0

::: "    -m, --mount=IPV4                  mount all NFS exports of IPV4"
:sub\nfs\--mount
:sub\nfs\-m
    if "%~1"=="" exit /b 12 @REM parameter is empty
    call :sub\ip\--test %~1 || exit /b 14 @REM parameter not a ip
    >nul 2>nul ping.exe -n 1 -l 16 -w 100 %~1 || exit /b 15 @REM can not connect remote host
    if not exist %windir%\system32\mount.exe call :nfs\initNfs
    for /f "usebackq skip=1" %%a in (`
        showmount.exe -e %~1
    `) do mount.exe -o mtype=soft lang=ansi nolock \\%~1%%a *
    exit /b 0

::: "    -u, --umount                      unmount all NFS exports"
:sub\nfs\--umount
:sub\nfs\-u
    if not exist %windir%\system32\umount.exe call :nfs\initNfs
    for /f "usebackq tokens=1,3 delims=:\" %%a in (`
        mount.exe
    `) do umount.exe -f %%a:
    exit /b 0

:: Enable the Services for NFS optional features.
:nfs\initNfs
    for %%a in (
        AnonymousUid AnonymousGid
    ) do reg.exe ^
            add HKLM\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default ^
                /v %%a ^
                /t REG_DWORD /d 0 /f

    for /f "usebackq tokens=2,3" %%a in (`
        reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v InstallationType
    `) do if "%%a"=="REG_SZ" if /i "%%b"=="Client" (
        call :sub\oset\--feature-enable ^
                ServicesForNFS-ClientOnly; ^
                ClientForNFS-Infrastructure; ^
                NFS-Administration
    ) else call :sub\oset\--feature-enable ^
                ServicesForNFS-ServerAndClient; ^
                ClientForNFS-Infrastructure; ^
                ServerForNFS-Infrastructure; ^
                NFS-Administration

    @REM start /w Ocsetup.exe ServicesForNFS-ClientOnly;ClientForNFS-Infrastructure;NFS-Administration /norestart
    exit /b 0

:::::::::
:: vhd ::
:::::::::

::: "Virtual hard disk manager" "" "Usage: %~n0 vhd [OPTION]..." ""
:xlib\vhd
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\vhd\%*
    goto :eof

::: "    -n, --new=VHD [SIZE] [LETTER: or PATH or -]" "                                                       create a virtual disk file of SIZE GB" "                                            -        do not attach and format" ""
:sub\vhd\--new
:sub\vhd\-n
    if "%~1"=="" exit /b 13 @REM path is empty
    if not exist "%~dp1" exit /b 14 @REM no volume find
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 12 @REM file suffix not vhd/vhdx
    if "%~2"=="" exit /b 15 @REM vhd size is empty

    call set /a _size=%2 * 1024 + 8

    if "%~3"=="-" (
        echo create vdisk file="%~f1" maximum=%_size% type=expandable | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 17 @REM diskpart error:
        exit /b 0
    )

    :: Create, attach and format the virtual disk.
    if "%~3" neq "" (
        if /i "%~d3"=="%~3" if exist "%~d3" exit /b 16 @REM letter already use
        if /i "%~d3" neq "%~3" if not exist "%~3" exit /b 18 @REM not a letter or path
    )


    (
        echo create vdisk file="%~f1" maximum=%_size% type=expandable
        echo attach vdisk
        echo create partition primary
        echo format fs=ntfs quick
        if "%~3"=="" (
            echo assign
        ) else (
            if /i "%~d3"=="%~3" (
                echo assign letter=%~d3
            ) else echo assign mount="%~f3"
        )
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 17 @REM diskpart error:
    >&3 echo complete.
    exit /b 0

::: "    -m, --mount=VHD [LETTER:]       attach the virtual disk and assign the drive letter"
:sub\vhd\--mount
:sub\vhd\-m
    if not exist "%~1" exit /b 23 @REM file not found
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 22 @REM file suffix not vhd/vhdx
    if "%~2" neq "" (
        if /i "%~d2"=="%~2" if exist "%~2" exit /b 26 @REM letter already use
        if /i "%~d2" neq "%~2" if not exist "%~2" exit /b 28 @REM not a letter or path
    )
    (
        echo select vdisk file="%~f1"
        echo attach vdisk
        if "%~2" neq "" (
            echo select partition 1
            :: Ignore the error when the disk has no partition.
            echo remove all noerr
            if /i "%~d2"=="%~2" (
                echo assign letter=%~2
            ) else echo assign mount="%~f2"
        )
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 27 @REM diskpart error:
    >&3 echo complete.
    exit /b 0

::: "    -u, --umount=VHD                detach the virtual disk"
:sub\vhd\--umount
:sub\vhd\-u
    if not exist "%~1" exit /b 33 @REM file not found
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 32 @REM file suffix not vhd/vhdx
    :: Detach the virtual disk.
    (
        echo select vdisk file="%~f1"
        echo detach vdisk
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 37 @REM diskpart error:
    >&3 echo complete.
    exit /b 0

::: "    -e, --expand=VHD [SIZE]         expand the virtual disk to SIZE GB"
:sub\vhd\--expand
:sub\vhd\-e
    if not exist "%~1" exit /b 43 @REM file not found
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 42 @REM file suffix not vhd/vhdx
    call :sub\is\--integer %~2 || exit /b -1
    :: Detach the virtual disk before expanding it.
    call :xlib\vumount %1 > nul
    setlocal
    set /a _size=%~2 * 1024 + 8
    (
        echo select vdisk file="%~f1"
        echo expand vdisk maximum=%_size%
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 47 @REM diskpart error:
    endlocal
    exit /b 0

::: "    -d, --differ=VHD [PARENT]       create a differencing disk from the parent disk PARENT"
:sub\vhd\--differ
:sub\vhd\-d
    if not exist "%~2" exit /b 51 @REM parent vhd not found
    if exist "%~1" exit /b 52 @REM new file allready exist
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 53 @REM file suffix not vhd/vhdx
    echo create vdisk file="%~f1" parent="%~f2" | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 57 @REM diskpart error:
    >&3 echo complete.
    exit /b 0

::: "    -me, --merge=VHD [DEPTH]        merge the child disk into its parents"
:sub\vhd\--merge
:sub\vhd\-me
    if not exist "%~1" exit /b 63 @REM file not found
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 62 @REM file suffix not vhd/vhdx
    setlocal
    call set _depth=1
    if "%~2" neq "" set _depth=%~2
    (
        echo select vdisk file="%~f1"
        echo merge vdisk depth=%_depth%
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 67 @REM diskpart error:
    >&3 echo complete.
    endlocal
    exit /b 0

:::TODO  "    -r, --rec   recover a child VHD whose parent is missing" "" "e.g." "    %~n0 vhd -n E:\nano.vhdx 30 V:"
:sub\vhd\--rec
:sub\vhd\-r
    exit /b -1

::::::::::
:: dism ::
::::::::::

::: "WIM manager" "" "Usage: %~n0 wim [OPTION]..." ""
:xlib\wim
    if "%~1"=="" call :this\annotation %0 & goto :eof
    if /i "%username%"=="System" if not defined SCRATCH_DIR exit /b 2 @REM SCRATCH_DIR variable not set
    2>nul mkdir %temp% %tmp%
    setlocal
    if /i "%username%" neq "System" set scratch_dir=
    if defined scratch_dir set "scratch_dir=/ScratchDir:%scratch_dir:/ScratchDir:=%"
    call :sub\wim\%*
    endlocal
    goto :eof

::: "    -n, --new=LEVEL [TARGET] [IMAGE]" "                                                             capture TARGET into a new WIM image" "                                                      [WARN] when TARGET has no trailing '\', its parent directory is captured" ""
:sub\wim\--new
:sub\wim\-n
    call :sub\oset\--vergeq 6.3 || exit /b 13 @REM dism version is too old

    setlocal enabledelayedexpansion
    call :sub\is\--integer %~1 && call :wim\setCompress %~1 && shift

    if not exist "%~1" exit /b 14 @REM target not found
    if "%~d1\"=="%~f1" if "%~2"=="" exit /b 15 @REM need input image name

    set _enable_export=
    if /i "%_compress_args%"=="/Compress:recovery" (
        set _compress_args=/Compress:fast
        set _enable_export=ture
    )

    set _is_root=
    set "_input=%~f1"
    :: Trim the trailing backslash from the path.
    if "%_input:~-1%"=="\" set _is_root=true& set "_input=%_input:~0,-1%"

    :: Use the image name argument, defaulting to the directory name.
    if "%~2" neq "" (
        set _name=%~2
    ) else for %%a in ("%_input%") do set "_name=%%~nxa"

    :: Append to an existing WIM or capture a new one.
    if exist ".\%_name%.wim" (set _create=Append) else set _create=Capture

    call :sub\time\--now _conf "%tmp%\" .ini
    set _args=
    set _description=
    set _load_point=HKLM\load-point%random%
    :: Create the exclusion list.

    :: TODO: bug: ()
    if exist "%_input%\Windows\System32\config\SYSTEM" (
        >%_conf% call :sub\txt\--subtxt "%~f0" wim.ini 3000
        set _args=/ConfigFile:"%_conf%"

        call :regedit\on
        :: Build the image description from ProductName and ReleaseId.
        :: [WARN] ReleaseId only exists on Windows 10 and later.
        >nul reg.exe load %_load_point% "%_input%\Windows\System32\config\SOFTWARE" && for /f "usebackq skip=1 tokens=2*" %%a in (`
            reg.exe query "%_load_point%\Microsoft\Windows NT\CurrentVersion" /v ProductName
        `) do if "%%a"=="REG_SZ" for /f "usebackq skip=1 tokens=2*" %%c in (`
            reg.exe query "%_load_point%\Microsoft\Windows NT\CurrentVersion" /v ReleaseId
        `) do if "%%c"=="REG_SZ" set _description=/Description:"%%b %%d"
        >nul reg.exe unload %_load_point%
        call :regedit\off

    ) else if defined _is_root (
        echo,
        echo root path: '%_input%'
    ) else (
        >%_conf% call :wim\ConfigFile "%_input%" && set _args=/ConfigFile:"%_conf%"
        :: The target is a directory; capture its parent directory.
        for %%a in ("%_input%") do set "_input=%%~dpa"
        set "_input=!_input:~0,-1!"
        echo,
        echo root path: '!_input!'
    )

    :: Capture the image.
    dism.exe /%_create%-Image ^
        /ImageFile:".\%_name%.wim" ^
        /CaptureDir:"%_input%" ^
        /Name:"%_name%" %_description% %_compress_args% ^
        /Verify %_args% %scratch_dir% || exit /b 16 @REM dism error

    if exist "%_conf%" erase "%_conf%"

    call :getWimLastIndex ".\%_name%.wim" _index

    echo new index is: %_index%

    if defined _enable_export dism.exe /Export-Image ^
                                /SourceImageFile:".\%_name%.wim" ^
                                /SourceIndex:%_index% ^
                                /DestinationImageFile:".\%_name%.esd" ^
                                /Compress:recovery ^
                                /CheckIntegrity %scratch_dir% || exit /b 16 @REM dism error

    endlocal
    exit /b 0

:: Create the WIM exclusion list.
:wim\ConfigFile
    if not exist "%~1" exit /b 1
    if "%~pnx1"=="\" exit /b 2
    echo [ExclusionList]
    :: Exclude every entry of the parent directory except the target itself.
    for /f "usebackq delims=" %%a in (`
        dir /a /b "%~dp1"
    `) do if "%%a" neq "%~nx1" echo \%%a
    echo,
    exit /b 0

::: "    -a, --apply=WIM [DIR] [INDEX]   apply image INDEX of WIM to DIR"
:sub\wim\--apply
:sub\wim\-a
    call :sub\oset\--vergeq 6.3 || exit /b 23 @REM dism version is too old
    if not exist "%~1" exit /b 27 @REM wim file not found
    if /i "%~x1" neq ".wim" if /i "%~x1" neq ".esd" exit /b 28 @REM not wim file
    setlocal
    set _out=.
    if "%~2" neq "" (
        call :sub\dir\--isdir "%~2" || exit /b -1
        set _out=%~f2
    )
    :: Trim the trailing backslash from the output path.
    if "%_out:~-1%"=="\" set _out=%_out:~0,-1%
    if "%~3"=="" (
        call :getWimLastIndex %1 _index
    ) else set _index=%~3
    dism.exe /Apply-Image ^
                /ImageFile:"%~f1" ^
                /Index:%_index% ^
                /ApplyDir:"%_out%" ^
                /Verify || exit /b 26 @REM dism error

    endlocal
    exit /b 0

:: Get the index of the last image in the WIM file.
:getWimLastIndex
    if "%~2"=="" exit /b 1
    for /f "usebackq tokens=1,3" %%a in (`
         dism.exe /English /Get-WimInfo /WimFile:"%~f1"
    `) do if "%%a"=="Index" set /a %~2=%%b
    exit /b 0

::: "    -m, --mount=WIM [DIR] [INDEX]   mount image INDEX of WIM in DIR"
:sub\wim\--mount
:sub\wim\-m
    if not exist "%~1" exit /b 37 @REM wim file not found
    if /i "%~x1" neq ".wim" exit /b 38 @REM not wim file
    call :sub\dir\--isdir %2 || exit /b 34 @REM target not directory
    setlocal
    set _rw=%~a1
    set _arg=
    if "%_rw:r=%" neq "%_rw%" (
        set _arg=/ReadOnly
        >&3 echo [WARN] Mounted image to have read-only permissions.
    )
    if "%~3"=="" (
        call :getWimLastIndex %1 _index
    ) else set _index=%3
    dism.exe /Mount-Wim ^
                /WimFile:"%~f1" ^
                /index:%_index% ^
                /MountDir:"%~f2" %_arg% %scratch_dir% || exit /b 36 @REM dism error

    endlocal
    exit /b 0

::: "    -u, --umount=DIR                unmount the image mounted in DIR, discarding changes"
:sub\wim\--umount
:sub\wim\-u
    call :sub\dir\--isdir %1 || exit /b 44 @REM target not directory
    dism.exe /Unmount-Wim ^
                /MountDir:"%~f1" ^
                /discard %scratch_dir% || exit /b 46 @REM dism error
    exit /b 0

::: "    -c, --commit=DIR                unmount the image mounted in DIR, keeping changes"
:sub\wim\--commit
:sub\wim\-c
    call :sub\dir\--isdir %1 || exit /b 54 @REM target not directory
    dism.exe /Unmount-Wim ^
                /MountDir:"%~f1" ^
                /commit %scratch_dir% || exit /b 46 @REM dism error
    exit /b 0

:: Compression levels: 0 = none, 1 = WIMBoot, 2 = fast, 3 = max, 4 = recovery (ESD).
:: The recovery level is only supported by the '/Export-Image' option.
:wim\setCompress
    set _compress_args=
    if "%~1"=="0" set _compress_args=/Compress:none
    if "%~1"=="1" set _compress_args=/WIMBoot
    if "%~1"=="2" set _compress_args=/Compress:fast
    if "%~1"=="3" set _compress_args=/Compress:max
    if "%~1"=="4" set _compress_args=/Compress:recovery
    if defined _compress_args exit /b 0
    exit /b 1

::: "    -e, --export=SOURCE [TARGET] [INDEX] [LEVEL]   export image INDEX from SOURCE to TARGET" "                                   LEVEL: 0 none, 1 WIMBoot, 2 fast, 3 max, 4 recovery (ESD)" ""
:sub\wim\--export
:sub\wim\-e
    if not exist %1 exit /b 57 @REM wim file not found
    if /i "%~x1" neq ".wim" if /i "%~x1" neq ".esd" exit /b 58 @REM first arg not wim file
    if "%~f2" neq "%~2" exit /b 51 @REM Not a path
    if /i "%~x2" neq ".wim" if /i "%~x2" neq ".esd" exit /b 50 @REM secend arg not wim file
    if "%~3"=="" exit /b 52 @REM Target wim index not select
    setlocal

    call :wim\setCompress %~4

    :: An ESD target requires the recovery compression level.
    if /i "%~x2"==".esd" if defined _compress_args if "%_compress_args:~-8%" neq "recovery" exit /b 53 @REM compress level error

    :: Default to recovery compression for an ESD target.
    if /i "%~x2"==".esd" if not defined _compress_args set _compress_args=/Compress:recovery

    :: Mark the image bootable when it is smaller than 536870911 bytes (TODO: get the size by index).
    2>nul set "_size=%~z1" || exit /b 57 @REM wim file not found
    :: The threshold 0x1fffffff equals 536870911.
    if "%_size:~9,1%"=="" if %_size% lss 536870911 if "%_compress_args%" neq "/WIMBoot" set "_compress_args=%_compress_args% /Bootable"

    dism.exe /Export-Image ^
                /SourceImageFile:"%~f1" ^
                /SourceIndex:%3 ^
                /DestinationImageFile:"%~f2" %_compress_args% ^
                /CheckIntegrity %scratch_dir% || exit /b 56 @REM dism error
    endlocal
    exit /b 0

::: "    -ua, --umountall                unmount all mounted images"
:sub\wim\--umountall
:sub\wim\-ua
    for /f "usebackq tokens=1-3*" %%a in (`
        dism.exe /English /Get-MountedWimInfo
    `) do if "%%~a%%~b"=="MountDir" if exist "%%~d" call :sub\wim\--umount "%%~d"
    dism.exe /Cleanup-Wim
    exit /b 0

::: "    -ra, --rmountall                remount all orphaned images"
:sub\wim\--rmountall
:sub\wim\-ra
    setlocal enabledelayedexpansion
    for /f "usebackq tokens=1-3*" %%a in (`
        dism.exe /English /Get-MountedWimInfo
    `) do (
        if "%%~a"=="Mount" set _mount_dir=
        if "%%~a%%~b"=="MountDir" if exist "%%~d" set "_mount_dir=%%~d"
        if "%%~a%%~d"=="StatusRemount" if defined _mount_dir dism.exe /Remount-Wim /MountDir:"!_mount_dir!" %scratch_dir% || exit /b 76 @REM dism error
    )
    endlocal
    echo,complete.
    exit /b 0

::: "    -i, --info=WIM                  display information about the images in WIM"
:sub\wim\--info
:sub\wim\-i
    if not exist "%~1" exit /b 84 @REM file not exist
    for /f "usebackq tokens=1,2*" %%b in (`
        dism.exe /English /Get-WimInfo /WimFile:%1
    `) do if "%%b"=="Index" (
        for /f "usebackq tokens=1,2*" %%f in (`
            dism.exe /English /Get-WimInfo /WimFile:%1 /Index:%%d
        `) do if "%%h" neq "<undefined>" (
            if "%%f"=="Name" set /p=%%d. "%%h"<nul
            if "%%f"=="Size" call :this\wim\num %%h
            if "%%f%%g%%h"=="WIMBootable: Yes" set /p=, wimboot<nul
            if "%%f"=="Architecture" set /p=, %%h<nul
            if "%%f"=="Version" set /p=, %%h<nul
            if "%%f"=="Edition" set /p=, %%h<nul
            if "%%g"=="(Default)" set /p=, %%f <nul
        )
        echo,
    )
    exit /b 0

:this\wim\num
    setlocal
    set _num=%*
    set /p=, %_num:,=_%<nul
    endlocal
    goto :eof

::: "Driver manager" "" "Usage: %~n0 drv [OPTION]..." ""
:xlib\drv
    if "%~1"=="" call :this\annotation %0 & goto :eof
    if /i "%username%"=="System" if not defined SCRATCH_DIR exit /b 7 @REM SCRATCH_DIR variable not set
    setlocal
    if /i "%username%" neq "System" set scratch_dir=
    if defined scratch_dir set "scratch_dir=/ScratchDir:%scratch_dir:/ScratchDir:=%"
    call :sub\drv\%*
    endlocal
    goto :eof

::: "    -v, --info                        display hardware information"
:sub\drv\--info
:sub\drv\-v
    :: https://learn.microsoft.com/en-us/windows/win32/wmisdk/wql-operators
    echo ;
    call :this\cim || goto legacy\drv_info
    for /f "usebackq delims=" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance Win32_BaseBoard | Select-Object -Property Manufacturer,Product,SerialNumber,Version | Format-Table -AutoSize; Get-CimInstance Win32_BIOS | Select-Object -Property SerialNumber,SMBIOSBIOSVersion,Version | Format-Table -AutoSize; Get-CimInstance Win32_ComputerSystemProduct | Select-Object -Property IdentifyingNumber,Name,UUID,Vendor,Version | Format-Table -AutoSize; Get-CimInstance Win32_Processor | Select-Object -Property Name,NumberOfCores,NumberOfLogicalProcessors,ProcessorId | Format-Table -AutoSize; Get-CimInstance Win32_PhysicalMemory | Select-Object -Property BankLabel,Capacity,DataWidth,Manufacturer,PartNumber,SerialNumber,Speed | Format-Table -AutoSize; Get-CimInstance Win32_DiskDrive | Select-Object -Property Index,InterfaceType,Model,SerialNumber,Signature,Size | Format-Table -AutoSize; Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress } | Select-Object -Property Description,IPAddress,IPEnabled,MACAddress | Format-Table -AutoSize"
    `) do echo ; %%~a
    goto skip\legacy_drv_info
    :legacy\drv_info
    for /f "usebackq delims=" %%a in (`
        wmic.exe baseboard get Manufacturer^,Product^,SerialNumber^,Version ^&
        wmic.exe bios get serialnumber^,SMBIOSBIOSVersion^,Version ^&
        wmic.exe csproduct get IdentifyingNumber^,Name^,UUID^,Vendor^,Version ^&
        wmic.exe cpu get Name^,NumberOfCores^,NumberOfLogicalProcessors^,ProcessorId ^&
        wmic.exe memorychip get BankLabel^,Capacity^,DataWidth^,Manufacturer^,PartNumber^,SerialNumber^,Speed ^&
        wmic.exe diskdrive get Index^,InterfaceType^,Model^,SerialNumber^,Signature^,Size ^&
        2^>nul wmic.exe nicconfig where "MACAddress is not null" get Description^,IPAddress^,IPEnabled^,MACAddress
    `) do echo ; %%~a
    :skip\legacy_drv_info
    exit /b 0

:: Drivers are installed into \Windows\System32\DriverStore\FileRepository.
::: "    -a, --add=OS [DRV]...             add drivers to the offline OS image"
:sub\drv\--add
:sub\drv\-a
    for %%a in (%*) do call :sub\dir\--isdir %1 && (
        dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a /Recurse %scratch_dir% || REM
    ) || if /i "%%~xa"==".inf" dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a %scratch_dir% || exit /b 24 @REM dism error
    exit /b 0

::: "    -l, --list[=OS]                   list the drivers of OS, or of the running system"
:sub\drv\--list
:sub\drv\-l
    if "%~1" neq "" call :sub\dir\--isdir %1 || exit /b 32 @REM OS path not found
    if "%~1"=="" (
        dism.exe /Online /Get-Drivers /all || exit /b 34 @REM dism error
    ) else dism.exe /Image:"%~f1" /Get-Drivers /all || exit /b 34
    exit /b 0

::: "    -r, --remove=OS [NAME.inf]        remove the third-party driver NAME.inf from OS"
:sub\drv\--remove
:sub\drv\-r
    call :sub\dir\--isdir %1 || exit /b 42 @REM OS path not found
    if /i "%~x2" neq ".inf" exit /b 43 @REM Not drivers name
    dism.exe /Image:"%~f1" /Remove-Driver /Driver:%~2 %scratch_dir% || exit /b 44 @REM dism error
    exit /b 0

:: Hardware ID manager.
::: "    -g, --get                         display the hardware IDs of every device"
:sub\drv\--get
:sub\drv\-g
    setlocal
    call :this\cim || goto legacy\drv_get
    for /f "usebackq tokens=1* delims==" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "Get-CimInstance Win32_PnPEntity | ForEach-Object { $i=$_; 'Caption','CompatibleID','HardwareID','Manufacturer','PNPClass','Status','StatusInfo' | ForEach-Object { $n=$_; $n+'='+$i.$n } }"
    `) do if "%%~a" neq "" set "%%~a=%%b"& if /i "%%~a"=="StatusInfo" call :drv\print-info
    goto skip\legacy_drv_get
    :legacy\drv_get
    for /f "usebackq tokens=1* delims==" %%a in (`
        wmic.exe path Win32_PnPEntity get Caption^,CompatibleID^,HardwareID^,Manufacturer^,PNPClass^,Status^,StatusInfo /value
    `) do if "%%~a" neq "" set "%%~a=%%b"& if /i "%%~a"=="StatusInfo" call :drv\print-info
    :skip\legacy_drv_get
    exit /b 0
    @REM call :sub\var\--in-path devcon.exe || >nul call :init\devcon
    @REM setlocal
    @REM :: Trim Hardware and compatible IDs
    @REM for /f "usebackq tokens=1,2" %%a in (`
    @REM     devcon.exe hwids *
    @REM `) do if "%%b"=="" set "_$%%a=$"
    @REM :: Print list
    @REM for /f "usebackq tokens=2 delims==$" %%a in (`
    @REM     2^>nul set _$
    @REM `) do echo %%a
    @REM endlocal
    @REM exit /b 0

:drv\print-info
    echo=
    echo name: %Caption%
    if defined Status (
        echo     Manufacturer: %Manufacturer%
        echo     PNPClass: %PNPClass%
        echo     Status: %Status%
    )
    if not defined HardwareID goto inter\print-info
    echo     HardwareID:
    for %%a in (%HardwareID%) do echo         %%~a
  :inter\print-info
    if not defined CompatibleID goto :eof
    echo     CompatibleID:
    for %%a in (%CompatibleID%) do echo         %%~a
    echo;
    goto :eof


::: "    -ge, --get-err                    display the hardware info of devices with an error status"
:sub\drv\--get-err
:sub\drv\-ge
    setlocal
    call :this\cim || goto legacy\drv_get_err
    for /f "usebackq tokens=1* delims==" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "$q='SELECT Caption,CompatibleID,HardwareID,StatusInfo FROM Win32_PnPEntity WHERE Status=' + [char]39 + 'Error' + [char]39; Get-CimInstance -Query $q | ForEach-Object { $i=$_; 'Caption','CompatibleID','HardwareID','StatusInfo' | ForEach-Object { $n=$_; $n+'='+$i.$n } }"
    `) do if "%%~a" neq "" set "%%~a=%%b"& if /i "%%~a"=="StatusInfo" call :drv\print-info
    goto skip\legacy_drv_get_err
    :legacy\drv_get_err
    for /f "usebackq tokens=1* delims==" %%a in (`
        wmic.exe path Win32_PnPEntity where "Status='Error'" get Caption^,CompatibleID^,HardwareID^,StatusInfo /value
    `) do if "%%~a" neq "" set "%%~a=%%b"& if /i "%%~a"=="StatusInfo" call :drv\print-info
    :skip\legacy_drv_get_err
    endlocal
    exit /b 0

::: "    -f, --filter=INF [DIR]            search the INF files in DIR for the IDs listed in INF"
:sub\drv\--filter
:sub\drv\-f
    if not exist "%~1" exit /b 65 @REM drivers info file not found
    call :sub\dir\--isdir %2 || exit /b 66 @REM drivers path error
    :: Create a temporary directory for the trimmed INF files.
    setlocal enabledelayedexpansion
    call :sub\time\--now _out %temp%\inf-
    mkdir %_out%
    set i=0
    for /r %2 %%a in (
        *.inf
    ) do (
        set /a i+=1
        :: Cache the INF file path by index.
        set _drv\inf\!i!=%%a
        :: Write the trimmed INF file into the temporary directory.
        call :xlib\vbs inftrim "%%~a" %_out%\!i!.tmp
        for %%b in (%_out%\!i!.tmp) do if "%%~zb"=="0" type "%%~a" > %_out%\!i!.tmp
    )
    :: Print the path of every INF file that matches.
    for /f "usebackq" %%a in (`
        findstr.exe /e /i /m /g:%1 %_out%\*.tmp
    `) do echo !_drv\inf\%%~na!
    :: Remove the temporary directory.
    rmdir /s /q %_out%
    endlocal
    exit /b 0

:sub\drv\--extract--env
:sub\drv\-ee
    @REM \Users\Default
    @REM \Users\Default\NTUSER.DAT
    @REM \Windows\servicing\Version\!_ver_drv!
    @REM \Windows\servicing\Version\!_ver_drv!\amd64_installed
    @REM \Windows\servicing\Version\!_ver_drv!\x86_installed
    @REM \Windows\System32
    @REM \Windows\System32\ntdll.dll
    @REM \Windows\System32\SSShim.dll
    @REM \Windows\System32\wdscore.dll
    @REM \Windows\System32\config
    @REM \Windows\System32\config\COMPONENTS 0kb
    @REM \Windows\System32\config\DEFAULT    0kb
    @REM \Windows\System32\config\DRIVERS
    @REM \Windows\System32\config\SAM        0kb
    @REM \Windows\System32\config\SECURITY   0kb
    @REM \Windows\System32\config\SOFTWARE
    @REM \Windows\System32\config\SYSTEM
    @REM \Windows\System32\Dism
    @REM \Windows\System32\Dism\CbsProvider.dll
    @REM \Windows\System32\Dism\CompatProvider.dll
    @REM \Windows\System32\Dism\DismCore.dll
    @REM \Windows\System32\Dism\DismCorePS.dll
    @REM \Windows\System32\Dism\DismHost.exe
    @REM \Windows\System32\Dism\DismProv.dll
    @REM \Windows\System32\Dism\DmiProvider.dll
    @REM \Windows\System32\Dism\FolderProvider.dll
    @REM \Windows\System32\Dism\GenericProvider.dll
    @REM \Windows\System32\Dism\IBSProvider.dll
    @REM \Windows\System32\Dism\ImagingProvider.dll
    @REM \Windows\System32\Dism\IntlProvider.dll
    @REM \Windows\System32\Dism\LogProvider.dll
    @REM \Windows\System32\Dism\OSProvider.dll
    @REM \Windows\System32\Dism\PEProvider.dll
    @REM \Windows\System32\Dism\SmiProvider.dll
    @REM \Windows\System32\Dism\UnattendProvider.dll
    @REM \Windows\System32\Dism\VhdProvider.dll
    @REM \Windows\System32\Dism\WimProvider.dll
    @REM \Windows\System32\Dism\Wow64Provider.dll
    @REM \Windows\System32\Dism\en-US
    @REM \Windows\System32\Dism\en-US\CbsProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\CompatProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\DismCore.dll.mui
    @REM \Windows\System32\Dism\en-US\DismProv.dll.mui
    @REM \Windows\System32\Dism\en-US\DmiProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\FolderProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\GenericProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\IBSProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\ImagingProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\IntlProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\LogProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\OSProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\PEProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\SmiProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\UnattendProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\VhdProvider.dll.mui
    @REM \Windows\System32\Dism\en-US\WimProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!
    @REM \Windows\System32\Dism\!_lang_drv!\CbsProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\CompatProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\DismCore.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\DismProv.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\DmiProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\FolderProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\GenericProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\ImagingProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\IntlProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\LogProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\OSProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\PEProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\SmiProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\UnattendProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\VhdProvider.dll.mui
    @REM \Windows\System32\Dism\!_lang_drv!\WimProvider.dll.mui
    @REM \Windows\System32\DriverStore\FileRepository
    @REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!
    @REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\CbsCore.dll
    @REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\DrUpdate.dll
    @REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\drvstore.dll
    @REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\wcp.dll
    goto :eof

::: "    --vnet=ADDR [MASK]                create a Microsoft KM-TEST loopback adapter (virtual Ethernet)"
:sub\drv\--vnet
    if "%~1"=="" exit /b 71 @REM ip address is empty.
    setlocal
    for /f "usebackq tokens=1,4*" %%a in (`
        netsh.exe interface ipv4 show interfaces
    `) do if "%%b"=="connected" set "_if%%a=%%c"

    call :sub\var\--in-path devcon.exe || >nul call :init\devcon
    :: Alternatively use the Add Hardware Wizard (hdwwiz.exe).
    call devcon.exe install %windir%\inf\netloop.inf *msloop || exit /b 72 @REM install adapter error

    set _name=
    for /f "usebackq tokens=1,4*" %%a in (`
        netsh.exe interface ipv4 show interfaces
    `) do if "%%b"=="connected" if not defined _if%%a set "_name=%%c"

    if not defined _name || exit /b 73 @REM install adapter error

    >&3 echo New loopback adapter name is '%_name%'

    set _mask=%~2
    if "%~2"=="" set _mask=255.255.255.0

    netsh.exe interface ipv4 set address name="%_name%" source=static address=%~1 mask=%_mask% || exit /b 74 @REM set address error
    endlocal
    exit /b 0

:: devcon.exe comes from the Windows 10 WDK and is downloaded next to this script.
:init\devcon
    for %%a in (_%0) do if %processor_architecture:~-2%==64 (
        :: Download the amd64 build.
        call :this\getCab %%~na ^
                    8/1/6/816FE939-15C7-4185-9767-42ED05524A95/wdk ^
                    787bee96dbd26371076b37b13c405890 ^
                    filbad6e2cce5ebc45a401e19c613d0a28f

    :: Otherwise download the x86 build.
    ) else call :this\getCab %%~na ^
                    8/1/6/816FE939-15C7-4185-9767-42ED05524A95/wdk ^
                    82c1721cd310c73968861674ffc209c9 ^
                    fil5a9177f816435063f779ebbbd2c1a1d2
    exit /b 0

::: "    --ranc                            [WARNING^^^!] restart all network adapters"
:sub\drv\--ranc
    for /f "usebackq skip=2 tokens=3*" %%a in (`
        netsh.exe interface show interface
    `) do for %%c in (
        disable enable
    ) do netsh.exe interface set interface "%%b" %%c
    exit /b 0


:::::::::
:: KMS ::
:::::::::

::: "KMS client" "" "Usage: %~n0 kms [OPTION]..." ""
:xlib\kms
    title kms
    if "%~1"=="" call :this\annotation %0 & goto :eof
    setlocal
    if "%~2"=="" (
        if "%~d0" neq "\\" exit /b 3 @REM Need ip or host
        for /f "usebackq delims=\" %%a in (
            '%~f0'
        ) do set _host=%%a
    ) else set _host=%2

    call :sub\kms\%*
    endlocal
    goto :eof

:: [WARN] Must be called from ':xlib\kms'.
::: "    -a, --all[=HOST[:PORT]]   activate Windows and Office"
:sub\kms\--all
:sub\kms\-a
    call :sub\kms\--os %*
    call :sub\kms\--odt %*
    exit /b 0

:: For the operating system only; [WARN] must be called from ':xlib\kms'.
::: "    -s, --os[=HOST[:PORT]]    activate Windows"
:sub\kms\--os
:sub\kms\-s
    if not defined _host exit /b 23 @REM Need ip or host

    :: Get the version of the running OS.
    set _verm10=
    call :oset\this_version_multiply_10 _verm10
    call :regedit\on

    set _currentbuild=
    for /f "usebackq tokens=3" %%a in (`
        reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild
    `) do set _currentbuild=%%a

    :: Get the edition ID of the running OS.
    set _editionid=
    for /f "usebackq tokens=3" %%a in (`
        reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID
    `) do set _editionid=%%a

    :: Search for the matching GVLK.
    :: https://technet.microsoft.com/en-us/library/jj612867(v=ws.11).aspx
    :: https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys

    set _gvlk=
    for %%k in (
        Core_100@TX9XD-98N7V-6WMQ6-BX7FG-H8Q99
        CoreCountrySpecific_100@PVMJN-6DFY6-9CCP6-7BKTT-D3WVR
        CoreSingleLanguage_100@7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH

        Education_100@NW6C2-QMPVW-D7KKK-3GKT6-VCFB2
        EducationN_100@2WH4N-8QGBV-H22JP-CT43Q-MDWWJ

        Enterprise_60@VKK3X-68KWM-X2YGT-QR4M6-4BWMV
        Enterprise_61@33PXH-7Y6KF-2VJC9-XBBR8-HVTHH
        Enterprise_62@32JNW-9KQ84-P47T8-D8GGY-CWCK7
        Enterprise_63@MHF9N-XY6XB-WVXMC-BTDCT-MKKG7
        Enterprise_100@NPPR9-FWDCX-D2C8J-H872K-2YT43
        EnterpriseE_61@C29WB-22CC8-VJ326-GHFJW-H9DH4
        EnterpriseG_100@YYVX9-NTFWV-6MDM3-9PT4T-4M68B
        EnterpriseGN_100@44RPN-FTY23-9VTTB-MP9BX-T84FV
        EnterpriseN_61@YDRBP-3D83W-TY26F-D46B2-XCKRJ
        EnterpriseN_62@JMNMF-RHW7P-DMY6X-RF3DR-X2BQT
        EnterpriseN_63@TT4HM-HN7YT-62K67-RGRQJ-JFFXW
        EnterpriseN_100@DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4

        EnterpriseS_100_10240@WNMTR-4C88C-JK8YV-HQ7T2-76DF9
        EnterpriseS_100_14393@DCPHK-NFMTC-H88MJ-PFHPY-QJ4BJ
        EnterpriseS_100_17763@M7XTQ-FN8P6-TTKYV-9D4CC-J462D
        EnterpriseS_100_19044@M7XTQ-FN8P6-TTKYV-9D4CC-J462D
        EnterpriseS_100_26100@M7XTQ-FN8P6-TTKYV-9D4CC-J462D
        EnterpriseSN_100_10240@2F77B-TNFGY-69QQF-B8YKP-D69TJ
        EnterpriseSN_100_14393@QFFDN-GRT3P-VKWWX-X7T3R-8B639
        EnterpriseSN_100_17763@92NFX-8DJQP-P6BBQ-THF9C-7CG2H
        EnterpriseSN_100_19044@92NFX-8DJQP-P6BBQ-THF9C-7CG2H

        IoTEnterpriseS_100_26100@KBN8V-HFGQ4-MGXVD-347P6-PDQGT

        Professional_61@FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4
        Professional_62@NG4HW-VH26C-733KW-K6F98-J8CK4
        Professional_63@GCRJD-8NW9H-F2CDX-CCM8D-9D6T9
        Professional_100@W269N-WFGWX-YVC9B-4J6C9-T83GX
        ProfessionalE_61@W82YF-2Q76Y-63HXB-FGJG9-GF7QX
        ProfessionalEducation_100@6TP4R-GNPTD-KYYHQ-7B7DP-J447Y
        ProfessionalEducationN_100@YVWGF-BXNMC-HTQYQ-CPQ99-66QFC
        ProfessionalN_61@MRPKT-YTG23-K7D7T-X2JMM-QY7MG
        ProfessionalN_62@XCVCF-2NXM9-723PB-MHCB7-2RYQQ
        ProfessionalN_63@HMCNV-VVBFX-7HMBH-CTY9B-B4FXY
        ProfessionalN_100@MH37W-N47XK-V7XM9-C7227-GCQG9
        ProfessionalWorkstation_100@NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J
        ProfessionalWorkstationN_100@9FNHH-K3HBT-3W4TD-6383H-6XYWF

        ServerDatacenter_60@7M67G-PC374-GR742-YH8V4-TCBY3
        ServerDatacenter_61@74YFP-3QFB3-KQT8W-PMXWJ-7M648
        ServerDatacenter_62@48HP8-DN98B-MYWDG-T2DCC-8W83P
        ServerDatacenter_63@W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9
        ServerEnterprise_60@YQGMW-MPWTJ-34KDK-48M3W-X4Q6V
        ServerEnterprise_61@489J6-VHDMP-X63PK-3K798-CPX3Y
        ServerDatacenter_100_14393@CB7KF-BWN84-R7R2Y-793K2-8XDDG
        ServerDatacenter_100_16299@6Y6KB-N82V8-D8CQV-23MJW-BWTG6
        ServerDatacenter_100_17134@2HXDN-KRXHB-GPYC7-YCKFJ-7FVDG
        ServerDatacenter_100_17763@WMDGN-G9PQG-XVVXX-R3X43-63DFG
        ServerDatacenter_100_18362@6NMRW-2C8FM-D24W7-TQWMY-CWH2D
        ServerDatacenter_100_20348@WX4NM-KYWYW-QJJR4-XV3QB-6VM33
        ServerDatacenterACor_100@6NMRW-2C8FM-D24W7-TQWMY-CWH2D

        ServerEssentials_63@KNC87-3J2TX-XB4WP-VCPJV-M4FWM
        ServerEssentials_100_14393@JCKRF-N37P4-C2D82-9YXRT-4M63B
        ServerEssentials_100_17763@WVDHN-86M7X-466P6-VHXV7-YY726

        ServerStandard_60@TM24T-X9RMF-VWXK6-X8JC9-BFGM2
        ServerStandard_61@YC6KT-GKW9T-YTKYR-T4X34-R7VHC
        ServerStandard_62@XC9B7-NBPP2-83J2H-RHMBY-92BT4
        ServerStandard_63@D2N9P-3P6X9-2R39C-7RTCD-MDVJX
        ServerStandard_100_14393@WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY
        ServerStandard_100_16299@DPCNP-XQFKJ-BJF7R-FRC8D-GF6G4
        ServerStandard_100_17134@PTXN8-JFHJM-4WC78-MPCBR-9W4KR
        ServerStandard_100_17763@N69g4-B89J2-4G8F4-WWYCC-J464C
        ServerStandard_100_18362@N2KJX-J94YW-TQVFB-DG9YT-724CC
        ServerStandard_100_20348@VDYBN-27WPP-V4HQT-9VMD4-VMK7H
        ServerStandardACor_100@N2KJX-J94YW-TQVFB-DG9YT-724CC
    ) do for /f "usebackq tokens=1* delims=@" %%a in (
        '%%~k'
    ) do if /i "%_editionid%_%_verm10%"=="%%a" (
        set _gvlk=%%b
    ) else if /i "%_editionid%_%_verm10%_%_currentbuild%"=="%%a" set _gvlk=%%b

    :: Exit when no KMS key matches this edition.
    if not defined _gvlk (
        call :regedit\off
        exit /b 24 @REM OS not support
    )

    :: Install the product key and activate Windows.
    for %%a in (
                                         ::?"active" ::?"display expires time" ::?"rm key"
        "/ipk %_gvlk%"  "/skms %_host%"      /ato        /xpr                      /ckms
    ) do cscript.exe //nologo //e:vbscript %windir%\System32\slmgr.vbs %%~a || exit /b 27 @REM slmgr.vbs error
    call :regedit\off

    exit /b 0

:: For the Office Deployment Tool only; [WARN] must be called from ':xlib\kms'.
::: "    -o, --odt[=HOST[:PORT]]   activate Office installed by the Office Deployment Tool" "    e.g." "        %~n0 kms --odt 192.168.1.1"
:sub\kms\--odt
:sub\kms\-o
    if not defined _host exit /b 33 @REM Need ip or host
    for /f "usebackq tokens=1,2 delims=:" %%a in (
        '%_host%'
    ) do set _host=%%a& set _port=%%b
    if not defined _port set _port=1688

    call :regedit\on
    call :odt\init_var
    if not defined _ospp exit /b 34 @REM not found install
    if not exist "%_ospp%" (
        call :regedit\off
        exit /b 32 @REM ospp.vbs not found
    )

    set _odtver=
    for /f "usebackq tokens=1,2*" %%a in (`
        reg.exe query HKLM\Software\Microsoft\Office\ClickToRun\Configuration /v ClientVersionToReport
    `) do if "%%c" neq "" for /f "usebackq tokens=1 delims=." %%d in (
        '%%c'
    ) do set _odtver=%%d

    if not defined _odtver (
        call :regedit\off
        exit /b 35 @REM get office version failed
    )

    :: Office 2010: http://technet.microsoft.com/en-us/library/ee624355(office.14).aspx
    for /f "usebackq tokens=2*" %%a in (`
        reg.exe query HKLM\Software\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds
    `) do if "%%~b" neq "" for %%c in (
        %%~b
    ) do for %%k in (
        ::?https://docs.microsoft.com/en-us/DeployOffice/vlactivation/gvlks
        16_ProPlus2024Volume@XJ2XN-FW8RK-P4HMP-DKDBV-GCVGB
        16_VisioPro2024Volume@B7TN8-FJ8V3-7QYCP-HQPMV-YY89G
        16_ProjectPro2024Volume@FQQ23-N4YCY-73HQ3-FM9WC-76HF4

        16_ProPlus2021Volume@FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH
        16_VisioPro2021Volume@KNH8D-FGHT4-T8RK3-CTDYJ-K2HT4
        16_ProjectPro2021Volume@FTNWT-C6WBT-8HMGF-K9PRX-QV9H8

        16_ProPlus2019Volume@NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP
        16_VisioPro2019Volume@9BGNQ-K37YR-RQHF2-38RQ3-7VCBB
        16_ProjectPro2019Volume@B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B

        ::?https://docs.microsoft.com/en-us/deployoffice/office2016/gvlks-for-office-2016
        16_ProfessionalRetail@XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99
        16_VisioProRetail@PD3PC-RHNGV-FXJ29-8JK7D-RJRJK
        16_ProjectProRetail@YG9NW-3K39V-2T3HJ-93F3Q-G83KT

        ::?https://technet.microsoft.com/en-us/library/dn385360.aspx
        15_ProfessionalRetail@YC7DK-G2NP3-2QQC3-J6H88-GVGXT
        15_VisioProRetail@C2FG9-N6J68-H8BTJ-BW3QX-RM3B3
        15_ProjectProRetail@FN8TT-7WMH6-2D4X9-M337T-2342K

    ) do for /f "usebackq tokens=1* delims=@" %%d in (
        '%%~k'
    ) do if /i "%_odtver%_%%c"=="%%d" set _gvlk\%%e=%%c

    >nul set _gvlk\ || (
        call :regedit\off
        exit /b 36 @REM office not support
    )

    :: Activate Office.
    for /f "usebackq tokens=1* delims==" %%a in (`
        2^>nul set _gvlk\
    `) do call :kms\dividing_line %%b && for %%c in (
                                                                ::?"active" ::?"display expires time" ::?"rm key"
        "/inpkey:%%~na"    "/sethst:%_host%"    "/setprt:%_port%"   /act        /dstatus                  /remhst
    ) do for /f "usebackq delims=" %%d in (`
        cscript.exe //nologo //e:vbscript "%_ospp%" %%~c
    `) do if "%%d" neq "---------------------------------------" if "%%d" neq "---Exiting-----------------------------" if "%%d" neq "---Processing--------------------------" echo,%%d
    call :regedit\off

    exit /b 0

:kms\dividing_line
    echo,
    echo ---------------------------------------
    echo,           %~1
    echo ---------------------------------------
    exit /b 0

::: "Office Deployment Tool" "" "Usage: %~n0 odt [OPTION]... [{2016,2019,2021,2024}]" ""
:xlib\odt
    title odt
    if "%~1"=="" call :this\annotation %0 & goto :eof
    setlocal
    set "_odt_source_path=%cd%"
    if "%~d0"=="\\" set "_odt_source_path=%~dp0"
    if "%~2" neq "" if "%~n2" neq "%~2" (
        if not exist "%~2" exit /b 2 @REM target not found
        set "_odt_source_path=%~2"
    )
    if "%_odt_source_path:~-1%"=="\" set _odt_source_path=%_odt_source_path:~0,-1%

    set _odt_update=
    call :sub\oset\--language _odt_lang || exit /b 3 @REM language not support

    for %%a in (
        %*
    ) do for %%b in (
        2016 2019 2021 2024
    ) do if "%%a"=="%%b" set /a _odt_year=%%a
    if not defined _odt_year set _odt_year=2021

    if %_odt_year% lss 2019 (
        set _odt_channel=Broad
    ) else set _odt_channel=PerpetualVL%_odt_year%

    call :sub\odt\%*
    endlocal
    goto :eof

::: "    -d, --deploy[=DIR]                download the Office source files into DIR"
:sub\odt\--deploy
:sub\odt\-d
    3>nul call :odt\pro\full
    >%temp%\odt_download.xml call :sub\txt\--subtxt "%~f0" odt.xml 3700

    title Deployed to '%_odt_source_path%'
    >&3 echo Deployed to '%_odt_source_path%'
    call :odt\ext\setup 27af1be6-dd20-4cb4-b154-ebab8a7d4a7e || exit /b 13 @REM init fail
    odt.exe /download %temp%\odt_download.xml || exit /b 16 @REM setup error
    erase %temp%\odt_download.xml
    goto :eof

::: "    -a, --add[=DIR] [NAME]...         add Office applications without removing previous installations"
:sub\odt\--add
:sub\odt\-a
    set _odt_remove=odt.xml

::: "    -i, --install=DIR [NAME]...       install Office by names; [WARNING^^^!] removes previous" "                                         installations, default: 'base'" "" "      names:" "          base full" "          word excel powerpoint" "          access onenote outlook" "          project visio publisher teams" "" "      base:" "          word excel visio" "" "      full:" "          word excel powerpoint project visio"
:sub\odt\--install
:sub\odt\-i
    if not exist "%_odt_source_path%\Office\Data" exit /b 27 @REM source not found

    :: Drop the directory operand before parsing the application names.
    if exist "%~1" shift /1

    if "%~1" neq "" (
        if /i "%~1"=="base" (
            shift /1
            call :odt\pro\base %1 %2 %3 %4 %5 %6 %7 %8 %9
        ) else if /i "%~1"=="full" (
            shift /1
            call :odt\pro\full %1 %2 %3 %4 %5 %6 %7 %8 %9
        ) else call :odt\install_args %*
    ) else call :odt\pro\base

    if errorlevel 4 exit /b 24 @REM must set office product ids

    >%temp%\odt_install.xml call :sub\txt\--subtxt "%~f0" odt.xml 3700

    title Installing from %_odt_source_path%\Office
    >&3 echo Installing...
    call :odt\ext\setup 27af1be6-dd20-4cb4-b154-ebab8a7d4a7e || exit /b 23 @REM init fail
    odt.exe /configure %temp%\odt_install.xml || exit /b 26 @REM setup error
    erase %temp%\odt_install.xml

    call :odt\init_var

    if %_odt_year% lss 2019 for /r "%_opath%" /d %%a in (
        License*
    ) do call :odt\cvlic "%%a" || exit /b 25 @REM install error
    echo,

    call :sub\oset\--vergeq 10.0 && >&3 echo compress '%_opath%'&& >nul call :sub\pkg\--exe "%_opath%"

    >&3 echo install complete. will try to activate

    :: A private sub-function cannot be called directly from here.
    call :xlib\kms --odt
    exit /b 0

:: Convert Office 2016 or 2013 to a volume license.
:odt\cvlic
    for /r %1 %%a in (
        ProPlusVL_KMS*.xrm-ms
        ProjectProVL_KMS*.xrm-ms
        VisioProVL_KMS*.xrm-ms
        client-issuance-*.xrm-ms
        pkeyconfig-office.xrm?ms
    ) do >&3 set /p=.<nul& >nul cscript.exe //nologo "%_ospp%" /inslic:"%%~a" || exit /b 1
    @REM >nul cscript.exe //nologo %windir%\System32\slmgr.vbs /ilc "%%~a"
    exit /b 0

:odt\pro\base
    call :odt\install_args word excel visio %*
    goto :eof

:odt\pro\full
    call :odt\install_args word excel powerpoint project visio %*
    goto :eof

:odt\install_args
    :: Clear the _odt__ variables.
    for /f "usebackq delims==" %%a in (`
        2^>nul set _odt__
    `) do set %%a=
    :: Comment out the ProPlus product block.
    set _odt_pro_2016=odt.xml
    set _odt_pro_2019=odt.xml
    set _odt_pro_2021=odt.xml
    set _odt_pro_2024=odt.xml

    :: Groove is OneDrive for Business.
    :: Lync is Skype for Business.

    :: Exclude every application by default.
    for %%a in (
        word excel powerpoint onenote onedrive skype access outlook publisher teams
    ) do set _odt__%%a_%_odt_year%=odt.xml
    for %%a in (
        word excel powerpoint onenote onedrive skype access outlook publisher teams
    ) do for %%b in (
        %*
    ) do if "%%~a"=="%%~b" set "_odt__%%a_%_odt_year%=" & set _odt_pro_%_odt_year%=

    :: At least one application must be selected.
    >nul 2>&1 set _odt__ || exit /b 25

    >&3 set /p=will install office %_odt_year%: <nul
    for %%a in (
        word excel powerpoint onenote onedrive skype access outlook publisher teams
    ) do if not defined _odt__%%a_%_odt_year% >&3 set /p='%%a' <nul

    :: Enable the project and visio products.
    for %%a in (%*) do for %%b in (
        project visio
    ) do if "%%~a"=="%%~b" set _odt__%%a_%_odt_year%=odt.xml
    for %%a in (
        project visio
    ) do if defined _odt__%%a_%_odt_year% >&3 set /p='%%a' <nul

    >&3 echo,
    >&3 echo [WARN] will remove all previous installation
    exit /b 0

:odt\init_var
    set _ospp=
    set _opath=
    pushd %cd%

    for /f "usebackq tokens=1,2*" %%a in (`
        reg.exe query HKLM\Software\Microsoft\Office\ClickToRun\Configuration /v InstallationPath
    `) do if "%%c" neq "" cd /d "%%~c" || exit /b 1

    set _opath=%cd%

    for /r %%a in (
        ospp.vb?
    ) do set "_ospp=%%a"

    popd
    goto :eof

:: Download odt.exe and add its directory to PATH.
:odt\ext\setup
    for %%a in (odt.exe) do if "%%~$path:a" neq "" exit /b 0
    set PATH=%temp%\%~1;%PATH%
    if exist %temp%\%~1\odt.exe exit /b 0
    2>nul mkdir %temp%\%~1

    :: https://www.microsoft.com/download/details.aspx?id=49117
    :: https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117
    :: https://github.com/MicrosoftDocs/OfficeDocs-DeployOffice/blob/live/DeployOffice/office2019/deploy.md#deploy-languages-for-office-2019

    :: https://docs.microsoft.com/en-us/officeupdates/odt-release-history
    :: Version 16.0.6126.6351
    :: Version 16.0.6227.6350
    :: Version 16.0.6508.6350
    :: Version 16.0.6508.6351
    :: Version 16.0.6612.6353
    :: Version 16.0.6831.5775
    :: Version 16.0.7118.5775
    :: Version 16.0.7213.5776
    :: Version 16.0.7407.3600
    :: Version 16.0.7614.3602
    :: Version 16.0.8008.3601
    :: Version 16.0.8311.3600
    :: Version 16.0.8529.3600
    :: Version 16.0.9119.3601
    :: Version 16.0.9326.3600
    :: Version 16.0.10306.33602
    :: Version 16.0.10321.33602
    :: Version 16.0.10810.33603
    :: Version 16.0.11023.33600
    :: Version 16.0.11107.33602
    :: Version 16.0.11306.33602
    :: Version 16.0.11509.33604
    :: Version 16.0.11615.33602
    :: Version 16.0.11617.33601
    :: Version 16.0.11901.20022
    :: Version 16.0.12130.20272
    :: Version 16.0.12325.20288
    :: Version 16.0.12624.20320
    :: Version 16.0.12827.20268
    :: Version 16.0.13231.20368
    :: Version 16.0.13328.20292
    :: Version 16.0.13328.20356
    :: Version 16.0.13328.20420
    :: Version 16.0.13426.20308
    :: Version 16.0.13426.20370
    :: Version 16.0.13530.20376
    :: Version 16.0.13628.20274
    :: Version 16.0.13628.20476
    :: Version 16.0.13801.20360
    :: Version 16.0.13901.20336
    :: Version 16.0.13929.20296
    :: Version 16.0.14026.20254
    :: Version 16.0.14026.20306
    :: Version 16.0.14131.20278
    :: Version 16.0.14326.20404
    :: Version 16.0.14527.20178
    :: Version 16.0.14729.20228
    :: Version 16.0.14931.20120
    :: Version 16.0.15028.20160
    :: Version 16.0.15028.20242
    :: Version 16.0.15128.20224
    :: Version 16.0.15225.20204
    :: Version 16.0.15330.20230
    :: Version 16.0.15427.20220
    :: Version 16.0.15601.20148
    :: Version 16.0.15629.20208
    :: Version 16.0.15726.20202
    :: Version 16.0.15928.20216
    :: Version 16.0.16026.20170

    :: Version 16.0.16130.20186
    :: Version 16.0.16227.20244
    :: Version 16.0.16327.20214
    :: Version 16.0.16501.20140
    :: Version 16.0.16529.20164
    :: Version 16.0.16626.20148

    :: Version 16.0.18925.20138
    :: Version 16.0.19029.20136
    :: Version 16.0.19231.20072
    :: Version 16.0.19231.20156
    :: Version 16.0.19029.20278
    :: Version 16.0.19328.20210
    :: Version 16.0.19426.20170
    :: Version 16.0.19628.20046

    call :xlib\download ^
        https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_19628-20046.exe ^
        %temp%\%~1\officedeploymenttool16.exe || exit /b 1

    %temp%\%~1\officedeploymenttool16.exe /extract:%temp%\%~1 /quiet || exit /b 1
    rename %temp%\%~1\setup.exe odt.exe || exit /b 1

    for %%a in (odt.exe) do if "%%~$path:a"=="" exit /b 1
    erase %temp%\%~1\officedeploymenttool16.exe %temp%\%~1\*.xml
    exit /b 0

::: "Visual Studio Installer" "" "Usage: %~n0 vsi {enterprise,professional,community,core} VERSION [OPTION]... [ARG]..." "    BRANCH:" "        enterprise" "        professional" "        community" "        core         (build tools without IDE)" "" "    OPTION:"
:xlib\vsi
    title vsi
    if "%~1"=="" call :this\annotation %0 & goto :eof
    if "%~2"=="" exit /b 2
    setlocal
    call :sub\vsi\%*
    if errorlevel 1 goto :eof
    endlocal
    exit /b 0

:: https://learn.microsoft.com/zh-cn/visualstudio/install/workload-component-id-vs-build-tools
:sub\vsi\enterprise
:sub\vsi\professional
:sub\vsi\community
:sub\vsi\core
    setlocal
    set _install_args=--includeRecommended
    set _branch=
    for %%a in (%0) do set _branch=%%~na

    set _major_version=
    for %%a in (
        7.2003 8.2005 9.2008 10.2010 11.2012 12.2013 14.2015
        15.2017 16.2019 17.2022 18.2026
    ) do if ".%~1"=="%%~xa" set _major_version=%%~na

    if defined _major_version (
        if %_major_version%0 lss 150 exit /b 11 @REM Visual Studio version is too old
        shift /1
    ) else set _major_version=17

    set _win_sdk=10SDK.19041
    if %_major_version%==18 set _win_sdk=11SDK.26100

    if "%_branch%"=="core" set "_branch=buildtools"& set _install_args=--add Microsoft.VisualStudio.Workload.VCTools;includeRecommended ^
--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 ^
--add Microsoft.VisualStudio.Component.Windows%_win_sdk%
    set _win_sdk=

    call :sub\vsi\%~1 %2 %3
    goto :eof

:: https://docs.microsoft.com/zh-cn/visualstudio/install/workload-component-id-vs-build-tools#visual-c-build-tools
:: https://docs.microsoft.com/zh-cn/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022
::: "        -d, --deploy=DIR                    deploy Visual Studio build tools data"
:sub\vsi\--deploy
:sub\vsi\-d
    if "%~1"=="" exit /b 13 @REM argument is empty
    2>nul mkdir "%~1"
    call :sub\oset\--language _vsi_lang || exit /b 14 @REM cannot get the current language
    call :vsi\ext\setup e64d79b4-0219-aea6-18ce-2fe10ebd5f0d %_branch% %_major_version% || exit /b 15 @REM vs_install download failed

    start /wait vs_%_branch%.exe --wait --lang %_vsi_lang% --layout "%~1" %_install_args% --quiet --norestart || exit /b 16 @REM vs_buildtools failed
    if not errorlevel 1 echo can use command '%~1\vs_setup.exe --passive --wait --norestart --nocache --noWeb %_install_args%'
    goto :eof

:: :: Debuggable Package Manager
@REM %comspec% /k "%VSINSTALLDIR%\Common7\Tools\VsDevCmd.bat"          @REM Developer Command Prompt
@REM %comspec% /k "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsall.bat" %*
:: https://docs.microsoft.com/zh-cn/visualstudio/install/build-tools-container
::: "        -i, --install[=DIR]                 install Visual Studio build tools online" "                                            when the script is in the deploy path, install offline"
:sub\vsi\--install
:sub\vsi\-i
    if "%~1" neq "" (
        if "%~d1\"=="%~dp1" exit /b 27 @REM cannot install at the root path
        call :sub\dir\--isfree "%~1" || exit /b 28 @REM target is not an empty directory
        mklink /j "%ProgramFiles(x86)%\Windows Kits" "%~dp1WinSDK" || exit /b 26 @REM failed to create the soft link "%ProgramFiles(x86)%\Windows Kits"
        2>nul mkdir "%~dp1WinSDK" "%~1"
        set _install_args=--installPath "%~1" %_install_args%
    )

    call :vsi\ext\setup e64d79b4-0219-aea6-18ce-2fe10ebd5f0d %_branch% %_major_version% || exit /b 24 @REM vs_install download failed
    start /wait vs_%_branch%.exe --wait %_install_args% || exit /b 25 @REM vs_buildtools failed
    goto :eof

:: https://aka.ms/vs/17/release/vs_buildtools.exe
:: https://aka.ms/vs/16/release/vs_enterprise.exe
:: https://aka.ms/vs/15/release/vs_professional.exe
:: https://aka.ms/vs/17/release/vs_community.exe
:: https://aka.ms/vs/stable/vs_buildtools.exe
:: https://aka.ms/vs/stable/vs_enterprise.exe
:: https://aka.ms/vs/stable/vs_professional.exe
:: https://aka.ms/vs/stable/vs_community.exe
:vsi\ext\setup
    set PATH=%temp%\%~1%~3;%PATH%
    setlocal
    if exist %temp%\%~1%~3\vs_%~2.exe exit /b 0
    2>nul mkdir %temp%\%~1%~3
    set _url=https://aka.ms/vs/%~3/release/vs_%~2.exe
    if "%~3"=="18" set _url=https://aka.ms/vs/stable/vs_%~2.exe
    call :xlib\download %_url% %temp%\%~1%~3\vs_%~2.exe || exit /b 1
    endlocal
    exit /b 0

:::::::::::
:: other ::
:::::::::::

@REM :: From the Windows 10 AIK; it downloads imagex.exe to the script path
@REM :init\imagex
@REM     for %%a in (_%0) do if %processor_architecture:~-2%==64 (
@REM         :: amd64
@REM         call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk d2611745022d67cf9a7703eb131ca487 fil4927034346f01b02536bd958141846b2

@REM     :: x86
@REM     ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk eacac0698d5fa03569c86b25f90113b5 fil6e1d5042624c9d5001511df2bfe4c40b
@REM     exit /b 0

::: "String management" "" "Usage: %~n0 str [OPTION]... [STRING]..." ""
:xlib\str
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\str\%*
    goto :eof

::: "    -s, --backspace=VAR                                  get backspace (erases the previous character)"
:sub\str\--backspace
:sub\str\-s
    if "%~1"=="" exit /b 41 @REM variable name is empty
    for /f %%a in ('"prompt $h & for %%a in (.) do REM"') do set %~1=%%a
    exit /b 0

::: "    -lf, --linefeed=VAR                                  get the line feed character"
:sub\str\--linefeed
:sub\str\-lf
    if "%~1"=="" exit /b 42 @REM variable name is empty
    setlocal
    set \n=^


    set \n=^^^%\n%%\n%^%\n%%\n%
    endlocal & set %~1=%\n%
    exit /b 0

::: "    -u, --uuid[=VAR]                                     get a UUID string"
:sub\str\--uuid
:sub\str\-u
    setlocal enabledelayedexpansion
        for /l %%a in (
            1,1,8
        ) do (
            set /a _1=!random!%%16,_2=!random!%%16,_3=!random!%%16,_4=!random!%%16
            set _0=!_0!!_1!.!_2!.!_3!.!_4!.
            if %%a gtr 1 if %%a lss 6 set _0=!_0!-
        )
        set _0=%_0:10.=a%
        set _0=%_0:11.=b%
        set _0=%_0:12.=c%
        set _0=%_0:13.=d%
        set _0=%_0:14.=e%
        set _0=%_0:15.=f%
    endlocal & if "%~1"=="" (
        echo %_0:.=%
    ) else set %~1=%~2%_0:.=%%~3
    exit /b 0

::: "    -r, --random[=NUM]                                   print a random string of NUM characters"
:sub\str\--random
:sub\str\-r
    setlocal
    2>nul set /a _password_length=%~1
    if "%~1"=="" set /a _password_length=8
    if %_password_length%==0 set /a _password_length=8
    PowerShell.exe ^
        -NoLogo ^
        -NonInteractive ^
        -ExecutionPolicy Unrestricted ^
        -Command "& {" ^
        "   Add-Type -AssemblyName System.Web;" ^
        "   [System.Web.Security.Membership]::GeneratePassword(%_password_length%, 0);" ^
        "}"
    endlocal
    goto :eof

::: "    -cp, --convert-pwd=STR [VAR]                         encode the password to a base64 string for unattend.xml"
:sub\str\--convert-pwd
:sub\str\-cp
    call :sub\oset\--vergeq 6.1 || exit /b 43 @REM System version is too old
    if "%~1"=="" exit /b 44 @REM Args is empty
    for /f "usebackq" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(\"%1OfflineAdministratorPassword\"))"
    `) do if "%~2"=="" (echo %%a) else set %~2=%%a
    exit /b 0

::: "    -tup, --to-unix-path=NT_PATH VAR [PREFIX]            convert a Windows path to Unix style"
:sub\str\--to-unix-path        [nt_path] [var_name] [[prefix]]
:sub\str\-tup
    if "%~2"=="" exit /b 1
    if "%~1" neq "%~f1" set %~2=%~1& exit /b 0
    if not exist "%~1" exit /b 2
    setlocal enabledelayedexpansion

    set _drive=%~d1
    set _drive=%_drive::=%
    set _char=#abcdefghijklmnopqrstuvwxyz
    set _drive=!_char:%_drive%=.!
    for %%a in (!_drive!) do set _drive=!_char:%%~na=!

    set _path_name=%~pnx1
    set _path_name=%_path_name:\=/%
    set _path_name=!_drive:~0,1!%_path_name%

    endlocal & set "%~2=%~3/%_path_name%"
    exit /b 0

::: "    -l, --length=STR [VAR]                               get the length of STR"
:sub\str\--length
:sub\str\-l
    if "%~1"=="" exit /b 55 @REM string is empty
    setlocal enabledelayedexpansion
    set _len=
    set _str=%~1fedcba9876543210
    if "%_str:~31,1%" neq "" (
        for %%a in (
            4096 2048 1024 512 256 128 64 32 16 8 4 2 1
        ) do if !_str:~%%a^,1!. neq . set /a _len+=%%a & set _str=!_str:~%%a!
        set /a _len-=15
    ) else set /a _len=0x!_str:~15^,1!
    endlocal & if "%~2"=="" (
        echo %_len%
    ) else set %~2=%_len%
    exit /b 0

::: "    -2l, --2col-left=STR1 STR2                           make the second column left-aligned, default column size 15"
:sub\str\--2col-left
:sub\str\-2l
    if "%~2"=="" exit /b 65 @REM string is empty
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    echo %~1!_spaces:~0,%_len%!%~2
    endlocal
    exit /b 0

:: Called by :sub\str\--2col-left and :sub\txt\--all-col-left.
:strModulo
    set /a _acl+=1
    set _str=%_str:~15%
    if "%_str:~31,1%"=="" exit /b 0
    goto %0

::: "    -up, --upper=STR                                     convert STR to upper case"
:sub\str\--upper
:sub\str\-up
    if "%~1"=="" exit /b 72 @REM variable name is empty
    setlocal
    set _0=%~1
    set _0=%_0:a=A%
    set _0=%_0:b=B%
    set _0=%_0:c=C%
    set _0=%_0:d=D%
    set _0=%_0:e=E%
    set _0=%_0:f=F%
    set _0=%_0:g=G%
    set _0=%_0:h=H%
    set _0=%_0:i=I%
    set _0=%_0:j=J%
    set _0=%_0:k=K%
    set _0=%_0:l=L%
    set _0=%_0:m=M%
    set _0=%_0:n=N%
    set _0=%_0:o=O%
    set _0=%_0:p=P%
    set _0=%_0:q=Q%
    set _0=%_0:r=R%
    set _0=%_0:s=S%
    set _0=%_0:t=T%
    set _0=%_0:u=U%
    set _0=%_0:v=V%
    set _0=%_0:w=W%
    set _0=%_0:x=X%
    set _0=%_0:y=Y%
    set _0=%_0:z=Z%
    endlocal & if "%~2"=="" (
        echo %_0%
    ) else set %~2=%_0%
    goto :eof

::: "    -lo, --lower=STR                                     convert STR to lower case"
:sub\str\--lower
:sub\str\-lo
    if "%~1"=="" exit /b 82 @REM variable name is empty
    setlocal
    set _0=%~1
    set _0=%_0:A=a%
    set _0=%_0:B=b%
    set _0=%_0:C=c%
    set _0=%_0:D=d%
    set _0=%_0:E=e%
    set _0=%_0:F=f%
    set _0=%_0:G=g%
    set _0=%_0:H=h%
    set _0=%_0:I=i%
    set _0=%_0:J=j%
    set _0=%_0:K=k%
    set _0=%_0:L=l%
    set _0=%_0:M=m%
    set _0=%_0:N=n%
    set _0=%_0:O=o%
    set _0=%_0:P=p%
    set _0=%_0:Q=q%
    set _0=%_0:R=r%
    set _0=%_0:S=s%
    set _0=%_0:T=t%
    set _0=%_0:U=u%
    set _0=%_0:V=v%
    set _0=%_0:W=w%
    set _0=%_0:X=x%
    set _0=%_0:Y=y%
    set _0=%_0:Z=z%
    endlocal & if "%~2"=="" (
        echo %_0%
    ) else set %~2=%_0%
    goto :eof

:: Longest common subsequence.
::: "    --lcs=STR1 STR2 [VAR]                                print the longest common subsequence"
:sub\str\--lcs
    if "%~2"=="" exit /b 95 @REM string is empty
    setlocal enabledelayedexpansion
    set "_str1=%~1"
    set "_str2=%~2"
    call :sub\str\--length "%~1" _str1.len
    call :sub\str\--length "%~2" _str2.len
    set /a _cycle=0, _len=0, _pre=0
    set _stat=

    for /f "usebackq tokens=1,2 delims=#" %%a in (`
        set /a _str1.len-1 ^& set /p^=#^<nul^& set /a -1*_str2.len+1
    `) do for /l %%c in (
        %%a,-1,%%b
    ) do (
        if %%c geq 0 (
            set /a _tmp1=%%c, _tmp2=0
        ) else set /a _tmp1=0, _tmp2=-1*%%c

        if !_cycle! lss !_str2.len! set /a _cycle+=1
        set /a _sub=_tmp1, _count=0, _idx=_cycle-_tmp2-1

        for /l %%d in (
            0,1,!_idx!
        ) do (
            set /a _offset1=_tmp1+%%d, _offset2=_tmp2+%%d
            call set _offset1=%%_str1:~!_offset1!,1%%
            call set _offset2=%%_str2:~!_offset2!,1%%
            if "!_offset1!"=="!_offset2!" (
                if not defined _stat set /a _sub=_tmp1+%%d, _count=0, _stat=1
                set /a _count+=1
            ) else (
                set _stat=
                if !_count! gtr !_len! set /a _pre=_sub, _len=_count
            )
        )
        if !_count! gtr !_len! set /a _pre=_sub, _len=_count
    )
    set _lcs=!_str1:~%_pre%,%_len%!
    endlocal & if "%~3"=="" (
        echo %_lcs%
    ) else set %~3=%_lcs%
    goto :eof

::: "Print text to standard output" "" "Usage: %~n0 txt [OPTION]... [FILE]..." ""
:xlib\txt
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\txt\%*
    goto :eof

::: "    -e, --head=NUM                   print the first NUM lines of FILE to standard output"
:sub\txt\--head
:sub\txt\-e
    call :this\psv
    if not errorlevel 3 exit /b 17 @REM PowerShell version is too old
    call :txt\ps1 -first %*|| exit /b 18 @REM argument error
    goto :eof

::: "    -t, --tail=NUM                   print the last NUM lines of FILE to standard output"
:sub\txt\--tail
:sub\txt\-t
    call :this\psv
    if not errorlevel 3 exit /b 15 @REM PowerShell version is too old
    call :txt\ps1 -Last %*|| exit /b 16 @REM argument error
    goto :eof

:: Called by :sub\txt\--head and :sub\txt\--tail.
:txt\ps1
    setlocal
    if "%~2"=="" exit /b 12 @REM number is empty
    set _count=%~2
    set _count=%_count:-=%
    call :sub\is\--integer %_count% || exit /b 13 @REM not a number
    if exist "%~3" (
        PowerShell.exe ^
                -NoLogo ^
                -NonInteractive ^
                -ExecutionPolicy Unrestricted ^
                -Command "Get-Content \"%~3\" %~1 %_count%"
    ) else PowerShell.exe ^
                    -NoLogo ^
                    -NonInteractive ^
                    -ExecutionPolicy Unrestricted ^
                    -Command "$Input | Select-Object %~1 %_count%"
    endlocal
    goto :eof

::: "    -j, --skip=SOURCE_FILE SKIP TARGET_FILE" "                                                                copy SOURCE_FILE to TARGET_FILE, skipping the first SKIP lines" ""
:sub\txt\--skip
:sub\txt\-j
    if not exist "%~1" exit /b 22 @REM source file not found
    call :sub\is\--integer %~2 || exit /b 23 @REM invalid skip number
    if not exist "%~3" exit /b 24 @REM target file not found
    @REM >%3 type nul
    @REM for /f "usebackq skip=%~2 delims=" %%a in (
    @REM     "%~f1"
    @REM ) do >> %3 echo %%a
    < "%~f1" more.com +%~2 >%3
    exit /b 0

:: Warning: the subdocument lines must be indented.
::: "    -o, --subtxt=SOURCE_PATH TAG [SKIP]" "                                     print the subdocuments tagged TAG from SOURCE_PATH" "                        subdocuments:" "                                     ::tag: line 1" "                                     ::tag: line 2" "                                     ::^^^!_var^^^!: line 3" "                                     ..." ""
:sub\txt\--subtxt      [source_path] [tag] [skip]
:sub\txt\-o
    if not exist "%~1" exit /b 32 @REM source file not found
    if "%~2"=="" exit /b 9
    setlocal enabledelayedexpansion
    if "%~3" neq "" 2>nul set /a _skip=%~3
    if not defined _skip set _skip=10
    if %_skip% leq 0 set _skip=10

    for /f "usebackq skip=%_skip% tokens=2* delims=:" %%a in (
        "%~f1"
    ) do if "%%a"=="%~2" echo,%%b

    endlocal
    goto :eof

::: "    -al, --all-col-left=STR [COL_SIZE] " "                                     pad STR with spaces to keep all columns left-aligned" "                                     COL_SIZE is cols / 15; print without a line break but wrap by COL_SIZE" "                       close command:    --all-col-left 0 0"
:sub\txt\--all-col-left
:sub\txt\-al
    if "%~1"=="" exit /b 40 @REM input string is empty
    if "%~2" neq "" if 1%~2 lss 12 (if defined _acl echo, & set _acl=) & exit /b 0
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    if "%~2" neq "" if 1%_acl% geq 1%~2 echo, & set /a _acl-=%~2-1
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    >&3 set /p=%~1!_spaces:~0,%_len%!<nul
    set /a _acl+=1
    if "%~2" neq "" if 1%_acl% geq 1%~2 echo, & set _acl=
    endlocal & set _acl=%_acl%
    exit /b 0

@REM ::: "    --line,  -l  [text_file_path] [skip_line] " "                                     Output text or read config"  "                                     requires enabledelayedexpansion" "                                     skip must be reset" "                                     text format: EOF [output_target] [command]"
@REM :sub\txt\--line
@REM :sub\txt\-l
@REM     if "%~1"=="" exit /b 55 @REM skip line is empty
@REM     if not exist "%~2" exit /b 56 @REM file not found
@REM     set _log=nul
@REM     set "_exec=@REM "
@REM     for /f "usebackq skip=%~2 delims=" %%a in (
@REM         "%~f1"
@REM     ) do for /f "tokens=1,2*" %%b in (
@REM         "%%a"
@REM     ) do if "%%b"=="EOF" (
@REM         if "%%c"=="%%~fc" if not exist "%%~dpc" (
@REM             mkdir "%%~dpc"
@REM         ) else if exist "%%~c" erase "%%~c"
@REM         set "_log=%%~c"
@REM         set "_exec=%%~d"
@REM     ) else >>!_log! !_exec!%%~a
@REM     set _log=
@REM     set _exec=
@REM     exit /b 0

@REM :: text format for :xlib\execline
@REM EOF !temp!\!_now!.log "echo "
@REM :: some codes
@REM EOF nul set
@REM a=1
@REM EOF nul "rem "


::: "Print MD5 (128-bit) checksums" "" "Usage: %~n0 md5 [FILE]..."
:xlib\MD5
::: "Print SHA1 (160-bit) checksums" "" "Usage: %~n0 sha1 [FILE]..."
:xlib\SHA1
::: "Print SHA256 (256-bit) checksums" "" "Usage: %~n0 sha256 [FILE]..."
:xlib\SHA256
::: "Print SHA512 (512-bit) checksums" "" "Usage: %~n0 sha512 [FILE]..."
:xlib\SHA512
    :: TODO
    @REM for /f "usebackq delims=" %%a in (`
    @REM    2^>nul dir /a-d /b /s %*
    @REM `) do
    for %%a in (
        %*
    ) do for %%b in (%0) do call :this\hash %%~nb "%%~a" || exit /b 2 @REM hash error
    exit /b 0

:this\hash
    if exist "%~2" for /f "usebackq delims=" %%a in (`
        certutil.exe -hashfile %2 %~1
    `) do for /f "usebackq tokens=1,2 delims=:" %%b in (
        '%%a'
    ) do if "%%a"=="%%b" call :hash\trim "%%a" %2& exit /b 0
    if exist "%~2" exit /b 1
    setlocal
    call :this\psv
    if not errorlevel 2 exit /b 1
    @REM set _arg=-
    @REM if exist "%~2" (
    @REM     set "_arg=%~2"
    @REM     for /f "usebackq" %%a in (`
    @REM         PowerShell.exe ^
    @REM            -NoLogo ^
    @REM            -NonInteractive ^
    @REM            -ExecutionPolicy Unrestricted ^
    @REM            -Command ^
    @REM            "[System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.%~1CryptoServiceProvider).ComputeHash([System.IO.File]::Open(\"%2\",[System.IO.Filemode]::Open,[System.IO.FileAccess]::Read))).ToString() -replace \"-\""
    @REM     `) do set _hash=%%a
    @REM ) else
    for /f "usebackq" %%a in (`
        PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "[System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.%~1CryptoServiceProvider).ComputeHash([Console]::OpenStandardInput())).ToString() -replace \"-\""
    `) do set _hash=%%a
    if "%_hash%"=="" exit /b 2
    call :sub\str\--lower %_hash% _hash
    endlocal & echo %_hash%   -
    exit /b 0

:hash\trim
    setlocal
    call :sub\str\--lower %1 _str
    echo %_str: =%   %2
    endlocal
    goto :eof

@REM ::: "Delete Login Notes"
@REM :xlib\delLoginNote
@REM     net.exe use * /delete
@REM     exit /b 0

:: Test the PowerShell version and return it as an errorlevel. The result is cached in _psv, so probe once per session.
:this\psv
    if defined _psv exit /b %_psv%
    set _psv=0
    for %%a in (PowerShell.exe) do if "%%~$path:a"=="" exit /b %_psv%
    for /f "usebackq" %%a in (`
        2^>nul PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command "$PSVersionTable.WSManStackVersion.Major"
    `) do set _psv=%%a
    exit /b %_psv%

:: Test CIM availability; return false on a legacy OS (e.g. Windows XP), so the caller should fall back to wmic.
:: The CimCmdlets module provides Get-CimInstance; its presence is a filesystem-only
:: probe, so the common case costs no process at all. Only a legacy machine reaches :this\psv.
:this\cim
    if defined _psv goto cim\probe
    if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\Modules\CimCmdlets" set _psv=3& exit /b 0
    :cim\probe
    call :this\psv
    if not errorlevel 3 exit /b -1 @REM PowerShell is too old for CIM
    exit /b 0

::: "Run a PowerShell script" "" "Usage: %~n0 ps1 PS1_PATH [ARG]..."
:xlib\ps1
    if not exist "%~1" exit /b 3 @REM ps1 script not found
    if /i "%~x1" neq ".ps1" exit /b 2 @REM invalid file extension
    PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -File %*
    goto :eof

::::::::::::::
:: VBScript ::
::::::::::::::

:: Download screnc.exe from http://download.microsoft.com/download/0/0/7/0073477f-bbf9-4510-86f9-ba51282531e3/sce10en.exe
@REM if /i "%~x1"==".vbs" screnc.exe %1 ./%~n1.vbe

::: "Run the xlib.vbs VBScript library" "" "Usage: %~n0 vbs [COMMAND]..."
:::: "lib.vbs not found"
:xlib\vbs
    @REM cscript.exe //nologo //e:vbscript.encode %*
    for %%a in (xlib.vbs) do if "%%~$path:a"=="" (
        exit /b 1
    ) else cscript.exe //nologo "%%~$path:a" %* 2>&3 || exit /b -1
    goto :eof

::: "Tag each line with the date and time" "" "Usage: %~n0 log [FORMAT]"
:xlib\log
    call :xlib\vbs log %*
    goto :eof

::::::::::::::::::
::     Base     ::
  :: :: :: :: ::

@REM set /a 0x7FFFFFFF
:: -2147483647 ~ 2147483647

:: Usage: start /b [COMMAND]...
:thread
    call %~pnx1
    goto :eof

::::: thread valve :::::
:: Usage: :this\thread_valve COUNT NAME COMMANDLINE
:this\thread_valve
    set /a _thread\count+=1
    if %_thread\count% lss %~1 exit /b 0
    :thread_valve\loop
        set _thread\count=0
        call :this\cim || goto legacy\thread_valve
        for /f "usebackq" %%a in (`
            2^>nul PowerShell.exe ^
                -NoLogo ^
                -NonInteractive ^
                -ExecutionPolicy Unrestricted ^
                -Command "@(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq '%~2' -and $_.CommandLine -like '*%~3*' }).Count"
        `) do set /a _thread\count=%%a - 2
        goto skip\legacy_thread_valve
        :legacy\thread_valve
        for /f "usebackq" %%a in (`
            2^>nul wmic.exe process where "name='%~2' and commandline like '%%%~3%%'" get processid ^| %windir%\System32\find.exe /c /v ""
        `) do set /a _thread\count=%%a - 2
        :skip\legacy_thread_valve
        if %_thread\count% gtr %~1 goto thread_valve\loop
    exit /b 0

::::: Map :::::
:map
    call :this\map\%*
    goto :eof

:this\map\--put
    if "%~2"=="" exit /b 1
    set "_MAP%~3\%~1=%~2"
    exit /b 0

:this\map\--get
    if "%~2"=="" exit /b 1
    if not defined _MAP%~3\%~1 exit /b 1
    set %~2=
    setlocal enabledelayedexpansion
    set _tmp_=
    if defined _MAP%~3\%~1 call set "_tmp_=!_MAP%~3\%~1!"
    endlocal & set "%~2=%_tmp_%"
    exit /b 0

:this\map\--remove
    set _MAP%~2\%~1=
    exit /b 0

:this\map\--keys
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _keys=
    for /f "usebackq tokens=1* delims==" %%a in (`
        2^>nul set _MAP%~2\
    `) do set "_keys=!_keys! "%%~nxa""
    endlocal & set %~1=%_keys%
    exit /b 0

:this\map\--values
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _values=
    for /f "usebackq tokens=1* delims==" %%a in (`
        2^>nul set _MAP%~2\
    `) do set "_values=!_values! "%%~b""
    endlocal & set %~1=%_values%
    exit /b 0

:this\map\--array
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _kv=
    for /f "usebackq tokens=1* delims==" %%a in (`
        2^>nul set _MAP%~2\
    `) do set "_kv=!_kv! "%%~nxa" "%%~b""
    endlocal & set %~1=%_kv%
    exit /b 0

:: The count is returned as the errorlevel.
:this\map\--size
    setlocal
    set _count=0
    for /f "usebackq tokens=1* delims==" %%a in (`
        2^>nul set _MAP%~1\
    `) do set /a _count+=1
    endlocal & exit /b %_count%

:this\map\--clear
    call :sub\var\--unset _MAP%~1\
    exit /b 0


::::: page :::::
:page
    call :this\page\%*
    goto :eof

:this\page\--put
    if not defined _page (
        set _page=1000000000
    ) else set /a _page+=1
    if .%1==. (
        set _page\%_page%=.
    ) else set _page\%_page%=.%*
    exit /b 0

:this\page\--show
    for /f "usebackq tokens=1* delims==" %%a in (`
        set _page\
    `) do echo%%b
    exit /b 0

:this\page\--clear
    call :sub\var\--unset _page
    exit /b 0

:: Load the .*.ini configuration files into the requested map.
:this\load_ini
    if "%~1"=="" exit /b 1
    set b%%l=
    :: Use ' %%a' to skip '#' and ';', and '%%c^^' to keep an empty value.
    for /f "usebackq delims=" %%a in (`
        2^>nul type "%~dp0.*.ini" "%userprofile%\.*.ini"
    `) do for /f "usebackq tokens=1 delims=#;" %%b in (
        ' %%a'
    ) do for /f "usebackq tokens=*" %%c in (
        '%%b'
    ) do if not "%%c"=="" for /f "usebackq tokens=1* delims==" %%d in (
        '%%c^^'
    ) do if "%%e"=="" (
        if /i "%%d"=="[%~1]^" (
            set b%%l=true
        ) else set b%%l=
    ) else if defined b%%l for /f "usebackq delims=^" %%f in (
        '%%e'
    ) do set _MAP%~2\%%d=%%f
    set b%%l=

    call :map --size %~2 && exit /b 1
    exit /b 0

  :: :: :: :: ::
::     Base     ::
::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::
::                 Framework                 ::
   :: :: :: :: :: :: :: :: :: :: :: :: :: ::

:: Print the function list or a function's help, print an error message, and complete function names.
:this\annotation
    setlocal enabledelayedexpansion & set /a _err_code=%errorlevel%
    set _annotation_more=
    set _err_msg=
    for /f "usebackq skip=82 delims=" %%a in (
        "%~f0"
    ) do for /f "usebackq tokens=1,2* delims=\	 " %%b in (
        '%%a'
    ) do (
        if /i "%%~b"==":::" (
            set _annotation=%%a
            set _annotation=!_annotation:* =!

        ) else if defined _func_eof (
            if %_err_code% gtr 1 (
                set _err_msg=%%~a
                set _un_space=!_err_msg: =!
                :: Match the error message.
                if "!_un_space:exit/b%_err_code%=!" neq "!_un_space!" >&2 ^
                    echo [ERROR] !_err_msg:* @REM =! ^(%~f0!_func_eof!^)&& exit /b 1

            ) else if %_err_code%==1 >&2 echo [ERROR] invalid option '%~2' ^(%~f0!_func_eof!^)&& exit /b 1
        )

        :: Match the arguments of a subfunction.
        if /i "%%~b\%%~c"==":sub\%~nx1" (
            set _func_eof=%%~a
            if defined _annotation if %_err_code%==0 call %0\more !_annotation!
            set _annotation=

        ) else if /i "%%~b"==":%~n0" (
            :: Match a new function and clear the stored function name.
            if defined _annotation_more exit /b 0
            if defined _err_msg >&2 echo unknown error.& exit /b 1
            set _func_eof=

            :: Match the target function.
            if /i "%%~b\%%~c"=="%~1" (
                set _func_eof=%%~a
                if defined _annotation if %_err_code%==0 call %0\more !_annotation!
                set _annotation=

            )
            :: Initialize the function variables used to list all functions or a sorted function name.
            set _prefix_4_auto_complete\%%~c=!_annotation! ""

        )
    )

    if defined _annotation_more exit /b 0
    if defined _err_msg >&2 echo unknown error.& exit /b 1

    :: Iterate over the function list.
    call :%~n0\cols _col
    set /a _i=0, _col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (`
        2^>nul set _prefix_4_auto_complete\%~n1
    `) do if "%~1" neq "" (
        :: Cache the first function name and print the sorted function names in columns.
        set /a _i+=1
        if !_i!==1 (
            set _cache_arg=%%~nxa
            if "%~2" neq "" (
                set _args=%*
                set _args=%%~nxa !_args:* =!
            ) else set _args=%%~nxa

        ) else if !_i!==2 (
            call :sub\txt\--all-col-left !_cache_arg! %_col%
            call :sub\txt\--all-col-left %%~nxa %_col%

        ) else if !_i! geq 2 call :sub\txt\--all-col-left %%~nxa %_col%

    ) else call :sub\str\--2col-left %%~nxa "%%~b"

    :: Close the left-aligned output ('--all-col-left 0 0').
    if !_i! gtr 0 call :sub\txt\--all-col-left 0 0

    :: Print the function name or call the matching function.
    endlocal & if %_i% gtr 1 (
        echo,
        >&2 echo [WARN] function sort name conflict
        exit /b 1

    ) else if %_i%==0 (
        if "%~1" neq "" >&2 echo [ERROR] No function found& exit /b 1

    ) else if %_i%==1 2>nul call :%~n0\%_args% || call %0 :%~n0\%_args%
    goto :eof

:this\annotation\more
    echo,%~1
    shift /1
    if "%~1" neq "" goto %0
    if .%1==."" goto %0
    set _annotation_more=true
    exit /b 0

::: "Get the console width in columns" "" "Usage: %~n0 cols [VAR]"
:xlib\cols
    for /f "usebackq skip=4 tokens=2" %%a in (`
        mode.com con
    `) do (
        if "%~1"=="" (
            echo %%a
        ) else set %~1=%%a
        exit /b 0
    )
    exit /b 0

   :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::                 Framework                 ::
:::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::
::             Embedded Documents            ::
   :: :: :: :: :: :: :: :: :: :: :: :: :: ::

::: Templates for :xlib\odt
                    ::odt.xml:<^!-- Office 365 client configuration file sample. To be used for Office 365 ProPlus apps,
                    ::odt.xml:     Office 365 Business apps, Project Pro for Office 365 and Visio Pro for Office 365.
                    ::odt.xml:
                    ::odt.xml:     For detailed information regarding configuration options visit: http://aka.ms/ODT.
                    ::odt.xml:     To use the configuration file be sure to remove the comments
                    ::odt.xml:
                    ::odt.xml:     The following sample allows you to download and install the 64 bit version of the Office 365 ProPlus apps
                    ::odt.xml:     and Visio Pro for Office 365 directly from the Office CDN using the Current Channel
                    ::odt.xml:     settings  -->
                    ::odt.xml:
                    ::odt.xml:<Configuration>
                    ::odt.xml:
              ::!_odt_remove!:    <^!--
                    ::odt.xml:    <Remove All="TRUE">
                    ::odt.xml:        <Product ID="Access2019Retail" />
                    ::odt.xml:        <Product ID="Access2019Volume" />
                    ::odt.xml:        <Product ID="Access2021Retail" />
                    ::odt.xml:        <Product ID="Access2021Volume" />
                    ::odt.xml:        <Product ID="Access2024Retail" />
                    ::odt.xml:        <Product ID="Access2024Volume" />
                    ::odt.xml:        <Product ID="AccessRetail" />
                    ::odt.xml:        <Product ID="AccessRuntimeRetail" />
                    ::odt.xml:        <Product ID="Excel2019Retail" />
                    ::odt.xml:        <Product ID="Excel2019Volume" />
                    ::odt.xml:        <Product ID="Excel2021Retail" />
                    ::odt.xml:        <Product ID="Excel2021Volume" />
                    ::odt.xml:        <Product ID="Excel2024Retail" />
                    ::odt.xml:        <Product ID="Excel2024Volume" />
                    ::odt.xml:        <Product ID="ExcelRetail" />
                    ::odt.xml:        <Product ID="Home2024Retail" />
                    ::odt.xml:        <Product ID="HomeBusiness2019Retail" />
                    ::odt.xml:        <Product ID="HomeBusiness2021Retail" />
                    ::odt.xml:        <Product ID="HomeBusiness2024Retail" />
                    ::odt.xml:        <Product ID="HomeBusinessRetail" />
                    ::odt.xml:        <Product ID="HomeStudent2019Retail" />
                    ::odt.xml:        <Product ID="HomeStudent2021Retail" />
                    ::odt.xml:        <Product ID="HomeStudentRetail" />
                    ::odt.xml:        <Product ID="LanguagePack" />
                    ::odt.xml:        <Product ID="LyncEntryRetail" />
                    ::odt.xml:        <Product ID="LyncRetail" />
                    ::odt.xml:        <Product ID="O365HomePremRetail" />
                    ::odt.xml:        <Product ID="OneNote2021Volume" />
                    ::odt.xml:        <Product ID="OneNote2024Volume" />
                    ::odt.xml:        <Product ID="OneNoteFreeRetail" />
                    ::odt.xml:        <Product ID="OneNoteRetail" />
                    ::odt.xml:        <Product ID="Outlook2019Retail" />
                    ::odt.xml:        <Product ID="Outlook2019Volume" />
                    ::odt.xml:        <Product ID="Outlook2021Retail" />
                    ::odt.xml:        <Product ID="Outlook2021Volume" />
                    ::odt.xml:        <Product ID="Outlook2024Retail" />
                    ::odt.xml:        <Product ID="Outlook2024Volume" />
                    ::odt.xml:        <Product ID="OutlookRetail" />
                    ::odt.xml:        <Product ID="Personal2019Retail" />
                    ::odt.xml:        <Product ID="Personal2021Retail" />
                    ::odt.xml:        <Product ID="PowerPoint2019Retail" />
                    ::odt.xml:        <Product ID="PowerPoint2019Volume" />
                    ::odt.xml:        <Product ID="PowerPoint2021Retail" />
                    ::odt.xml:        <Product ID="PowerPoint2021Volume" />
                    ::odt.xml:        <Product ID="PowerPoint2024Retail" />
                    ::odt.xml:        <Product ID="PowerPoint2024Volume" />
                    ::odt.xml:        <Product ID="PowerPointRetail" />
                    ::odt.xml:        <Product ID="Professional2019Retail" />
                    ::odt.xml:        <Product ID="Professional2021Retail" />
                    ::odt.xml:        <Product ID="Professional2024Retail" />
                    ::odt.xml:        <Product ID="ProfessionalRetail" />
                    ::odt.xml:        <Product ID="ProjectPro2019Retail" />
                    ::odt.xml:        <Product ID="ProjectPro2019Volume" />
                    ::odt.xml:        <Product ID="ProjectPro2021Retail" />
                    ::odt.xml:        <Product ID="ProjectPro2021Volume" />
                    ::odt.xml:        <Product ID="ProjectPro2024Retail" />
                    ::odt.xml:        <Product ID="ProjectPro2024Volume" />
                    ::odt.xml:        <Product ID="ProjectProRetail" />
                    ::odt.xml:        <Product ID="ProjectProXVolume" />
                    ::odt.xml:        <Product ID="ProjectStd2019Retail" />
                    ::odt.xml:        <Product ID="ProjectStd2019Volume" />
                    ::odt.xml:        <Product ID="ProjectStd2021Retail" />
                    ::odt.xml:        <Product ID="ProjectStd2021Volume" />
                    ::odt.xml:        <Product ID="ProjectStd2024Retail" />
                    ::odt.xml:        <Product ID="ProjectStd2024Volume" />
                    ::odt.xml:        <Product ID="ProjectStdRetail" />
                    ::odt.xml:        <Product ID="ProjectStdXVolume" />
                    ::odt.xml:        <Product ID="ProPlus2019Retail" />
                    ::odt.xml:        <Product ID="ProPlus2019Volume" />
                    ::odt.xml:        <Product ID="ProPlus2021Retail" />
                    ::odt.xml:        <Product ID="ProPlus2021Volume" />
                    ::odt.xml:        <Product ID="ProPlus2024Retail" />
                    ::odt.xml:        <Product ID="ProPlus2024Volume" />
                    ::odt.xml:        <Product ID="ProPlusSPLA2021Volume" />
                    ::odt.xml:        <Product ID="Publisher2019Retail" />
                    ::odt.xml:        <Product ID="Publisher2019Volume" />
                    ::odt.xml:        <Product ID="Publisher2021Retail" />
                    ::odt.xml:        <Product ID="Publisher2021Volume" />
                    ::odt.xml:        <Product ID="PublisherRetail" />
                    ::odt.xml:        <Product ID="SkypeforBusiness2019Retail" />
                    ::odt.xml:        <Product ID="SkypeforBusiness2019Volume" />
                    ::odt.xml:        <Product ID="SkypeforBusiness2021Volume" />
                    ::odt.xml:        <Product ID="SkypeforBusiness2024Volume" />
                    ::odt.xml:        <Product ID="SkypeforBusinessEntry2019Retail" />
                    ::odt.xml:        <Product ID="SkypeforBusinessEntryRetail" />
                    ::odt.xml:        <Product ID="SkypeforBusinessRetail" />
                    ::odt.xml:        <Product ID="Standard2019Volume" />
                    ::odt.xml:        <Product ID="Standard2021Volume" />
                    ::odt.xml:        <Product ID="Standard2024Volume" />
                    ::odt.xml:        <Product ID="StandardSPLA2021Volume" />
                    ::odt.xml:        <Product ID="VisioPro2019Retail" />
                    ::odt.xml:        <Product ID="VisioPro2019Volume" />
                    ::odt.xml:        <Product ID="VisioPro2021Retail" />
                    ::odt.xml:        <Product ID="VisioPro2021Volume" />
                    ::odt.xml:        <Product ID="VisioPro2024Retail" />
                    ::odt.xml:        <Product ID="VisioPro2024Volume" />
                    ::odt.xml:        <Product ID="VisioProRetail" />
                    ::odt.xml:        <Product ID="VisioProXVolume" />
                    ::odt.xml:        <Product ID="VisioStd2019Retail" />
                    ::odt.xml:        <Product ID="VisioStd2019Volume" />
                    ::odt.xml:        <Product ID="VisioStd2021Retail" />
                    ::odt.xml:        <Product ID="VisioStd2021Volume" />
                    ::odt.xml:        <Product ID="VisioStd2024Retail" />
                    ::odt.xml:        <Product ID="VisioStd2024Volume" />
                    ::odt.xml:        <Product ID="VisioStdRetail" />
                    ::odt.xml:        <Product ID="VisioStdXVolume" />
                    ::odt.xml:        <Product ID="Word2019Retail" />
                    ::odt.xml:        <Product ID="Word2019Volume" />
                    ::odt.xml:        <Product ID="Word2021Retail" />
                    ::odt.xml:        <Product ID="Word2021Volume" />
                    ::odt.xml:        <Product ID="Word2024Retail" />
                    ::odt.xml:        <Product ID="Word2024Volume" />
                    ::odt.xml:        <Product ID="WordRetail" />
                    ::odt.xml:    </Remove>
              ::!_odt_remove!:    -->
                    ::odt.xml:
                    ::odt.xml:    <^!--  <Add OfficeClientEdition="64" Channel="Monthly">  -->
                    ::odt.xml:    <Add SourcePath="!_odt_source_path!\" OfficeClientEdition="64" Channel="!_odt_channel!">
                    ::odt.xml:
                    ::odt.xml:        <^!--  https://go.microsoft.com/fwlink/p/?LinkID=301891  -->
                    ::odt.xml:
            ::!_odt_pro_2024!:        <^!--
                    ::odt.xml:        <Product ID="ProPlus2024Volume">
                    ::odt.xml:            <Language ID="!_odt_lang!" />
                    ::odt.xml:            <Language ID="MatchPreviousMSI" />
        ::!_odt__access_2024!:            <ExcludeApp ID="Access" />
         ::!_odt__excel_2024!:            <ExcludeApp ID="Excel" />
         ::!_odt__skype_2024!:            <ExcludeApp ID="Lync" />
      ::!_odt__onedrive_2024!:            <ExcludeApp ID="OneDrive" />
       ::!_odt__onenote_2024!:            <ExcludeApp ID="OneNote" />
       ::!_odt__outlook_2024!:            <ExcludeApp ID="Outlook" />
    ::!_odt__powerpoint_2024!:            <ExcludeApp ID="PowerPoint" />
     ::!_odt__publisher_2024!:            <ExcludeApp ID="Publisher" />
         ::!_odt__teams_2024!:            <ExcludeApp ID="Teams" />
          ::!_odt__word_2024!:            <ExcludeApp ID="Word" />
                    ::odt.xml:        </Product>
            ::!_odt_pro_2024!:        -->
                    ::odt.xml:
       ::!_odt__project_2024!:        <Product ID="ProjectPro2024Volume">
       ::!_odt__project_2024!:            <Language ID="!_odt_lang!" />
       ::!_odt__project_2024!:            <Language ID="MatchPreviousMSI" />
       ::!_odt__project_2024!:        </Product>
       ::!_odt__project_2024!:
         ::!_odt__visio_2024!:        <Product ID="VisioPro2024Volume">
         ::!_odt__visio_2024!:            <Language ID="!_odt_lang!" />
         ::!_odt__visio_2024!:            <Language ID="MatchPreviousMSI" />
         ::!_odt__visio_2024!:        </Product>
         ::!_odt__visio_2024!:
                    ::odt.xml:
            ::!_odt_pro_2021!:        <^!--
                    ::odt.xml:        <Product ID="ProPlus2021Volume">
                    ::odt.xml:            <Language ID="!_odt_lang!" />
        ::!_odt__access_2021!:            <ExcludeApp ID="Access" />
         ::!_odt__excel_2021!:            <ExcludeApp ID="Excel" />
         ::!_odt__skype_2021!:            <ExcludeApp ID="Lync" />
      ::!_odt__onedrive_2021!:            <ExcludeApp ID="OneDrive" />
       ::!_odt__onenote_2021!:            <ExcludeApp ID="OneNote" />
       ::!_odt__outlook_2021!:            <ExcludeApp ID="Outlook" />
    ::!_odt__powerpoint_2021!:            <ExcludeApp ID="PowerPoint" />
     ::!_odt__publisher_2021!:            <ExcludeApp ID="Publisher" />
         ::!_odt__teams_2021!:            <ExcludeApp ID="Teams" />
          ::!_odt__word_2021!:            <ExcludeApp ID="Word" />
                    ::odt.xml:        </Product>
            ::!_odt_pro_2021!:        -->
                    ::odt.xml:
       ::!_odt__project_2021!:        <Product ID="ProjectPro2021Volume">
       ::!_odt__project_2021!:            <Language ID="!_odt_lang!" />
       ::!_odt__project_2021!:        </Product>
       ::!_odt__project_2021!:
         ::!_odt__visio_2021!:        <Product ID="VisioPro2021Volume">
         ::!_odt__visio_2021!:            <Language ID="!_odt_lang!" />
         ::!_odt__visio_2021!:        </Product>
         ::!_odt__visio_2021!:
                    ::odt.xml:
            ::!_odt_pro_2019!:        <^!--
                    ::odt.xml:        <Product ID="ProPlus2019Volume">
                    ::odt.xml:            <Language ID="!_odt_lang!" />
        ::!_odt__access_2019!:            <ExcludeApp ID="Access" />
         ::!_odt__excel_2019!:            <ExcludeApp ID="Excel" />
      ::!_odt__onedrive_2019!:            <ExcludeApp ID="OneDrive" /> <ExcludeApp ID="Groove" />
       ::!_odt__onenote_2019!:            <ExcludeApp ID="OneNote" />
       ::!_odt__outlook_2019!:            <ExcludeApp ID="Outlook" />
    ::!_odt__powerpoint_2019!:            <ExcludeApp ID="PowerPoint" />
     ::!_odt__publisher_2019!:            <ExcludeApp ID="Publisher" />
         ::!_odt__skype_2019!:            <ExcludeApp ID="Skype" />    <ExcludeApp ID="Lync" />
          ::!_odt__word_2019!:            <ExcludeApp ID="Word" />
                    ::odt.xml:        </Product>
            ::!_odt_pro_2019!:        -->
                    ::odt.xml:
       ::!_odt__project_2019!:        <Product ID="ProjectPro2019Volume">
       ::!_odt__project_2019!:            <Language ID="!_odt_lang!" />
       ::!_odt__project_2019!:        </Product>
       ::!_odt__project_2019!:
         ::!_odt__visio_2019!:        <Product ID="VisioPro2019Volume">
         ::!_odt__visio_2019!:            <Language ID="!_odt_lang!" />
         ::!_odt__visio_2019!:        </Product>
         ::!_odt__visio_2019!:
                    ::odt.xml:
            ::!_odt_pro_2016!:        <^!--
                    ::odt.xml:        <Product ID="ProfessionalRetail">
                    ::odt.xml:            <Language ID="!_odt_lang!" />
        ::!_odt__access_2016!:            <ExcludeApp ID="Access" />
         ::!_odt__excel_2016!:            <ExcludeApp ID="Excel" />
                    ::odt.xml:            <ExcludeApp ID="OneDrive" />
       ::!_odt__onenote_2016!:            <ExcludeApp ID="OneNote" />
       ::!_odt__outlook_2016!:            <ExcludeApp ID="Outlook" />
    ::!_odt__powerpoint_2016!:            <ExcludeApp ID="PowerPoint" />
     ::!_odt__publisher_2016!:            <ExcludeApp ID="Publisher" />
          ::!_odt__word_2016!:            <ExcludeApp ID="Word" />
                    ::odt.xml:        </Product>
            ::!_odt_pro_2016!:        -->
                    ::odt.xml:
       ::!_odt__project_2016!:        <Product ID="ProjectProRetail">
       ::!_odt__project_2016!:            <Language ID="!_odt_lang!" />
       ::!_odt__project_2016!:        </Product>
       ::!_odt__project_2016!:
         ::!_odt__visio_2016!:        <Product ID="VisioProRetail">
         ::!_odt__visio_2016!:            <Language ID="!_odt_lang!" />
         ::!_odt__visio_2016!:        </Product>
         ::!_odt__visio_2016!:
                    ::odt.xml:    </Add>
                    ::odt.xml:
                    ::odt.xml:    <RemoveMSI All="True" />
                    ::odt.xml:
                    ::odt.xml:    <^!--  <Updates Enabled="TRUE" Channel="Monthly" />  -->
              ::!_odt_update!:    <Updates Enabled="TRUE" UpdatePath="!_odt_source_path!\" Channel="!_odt_channel!" />
              ::!_odt_update!:
                    ::odt.xml:    <^!--  <Display Level="None" AcceptEULA="TRUE" />  -->
                    ::odt.xml:    <Display Level="Full" AcceptEULA="TRUE" />
                    ::odt.xml:
                    ::odt.xml:    <Logging Path="%temp%" />
                    ::odt.xml:
                    ::odt.xml:    <^!--  <Property Name="AUTOACTIVATE" Value="1" />  -->
                    ::odt.xml:
                    ::odt.xml:</Configuration>

::: for :sub\wim\--new
    ::wim.ini:[ExclusionList]
    ::wim.ini:\$*
    ::wim.ini:\boot*
; @REM fix: \*.sys == *.sys
    ::wim.ini:\hiberfil.sys
    ::wim.ini:\pagefile.sys
    ::wim.ini:\swapfile.sys
    ::wim.ini:\ProgramData\Microsoft\Windows\SQM
    ::wim.ini:\System Volume Information
    ::wim.ini:\Users\*\AppData\Local\GDIPFONTCACHEV1.DAT
    ::wim.ini:\Users\*\AppData\Local\Temp\*
    ::wim.ini:\Users\*\NTUSER.DAT*.TM.blf
    ::wim.ini:\Users\*\NTUSER.DAT*.regtrans-ms
    ::wim.ini:\Users\*\NTUSER.DAT*.log*
    ::wim.ini:\Windows\AppCompat\Programs\Amcache.hve*.TM.blf
    ::wim.ini:\Windows\AppCompat\Programs\Amcache.hve*.regtrans-ms
    ::wim.ini:\Windows\AppCompat\Programs\Amcache.hve*.log*
    ::wim.ini:\Windows\CSC
    ::wim.ini:\Windows\Debug\*
    ::wim.ini:\Windows\Logs\*
    ::wim.ini:\Windows\Panther\*.etl
    ::wim.ini:\Windows\Panther\*.log
    ::wim.ini:\Windows\Panther\FastCleanup
    ::wim.ini:\Windows\Panther\img
    ::wim.ini:\Windows\Panther\Licenses
    ::wim.ini:\Windows\Panther\MigLog*.xml
    ::wim.ini:\Windows\Panther\Resources
    ::wim.ini:\Windows\Panther\Rollback
    ::wim.ini:\Windows\Panther\Setup*
    ::wim.ini:\Windows\Panther\UnattendGC
    ::wim.ini:\Windows\Panther\upgradematrix
    ::wim.ini:\Windows\Prefetch\*
    ::wim.ini:\Windows\ServiceProfiles\LocalService\NTUSER.DAT*.TM.blf
    ::wim.ini:\Windows\ServiceProfiles\LocalService\NTUSER.DAT*.regtrans-ms
    ::wim.ini:\Windows\ServiceProfiles\LocalService\NTUSER.DAT*.log*
    ::wim.ini:\Windows\ServiceProfiles\NetworkService\NTUSER.DAT*.TM.blf
    ::wim.ini:\Windows\ServiceProfiles\NetworkService\NTUSER.DAT*.regtrans-ms
    ::wim.ini:\Windows\ServiceProfiles\NetworkService\NTUSER.DAT*.log*
    ::wim.ini:\Windows\System32\config\RegBack\*
    ::wim.ini:\Windows\System32\config\*.TM.blf
    ::wim.ini:\Windows\System32\config\*.regtrans-ms
    ::wim.ini:\Windows\System32\config\*.log*
    ::wim.ini:\Windows\System32\SMI\Store\Machine\SCHEMA.DAT*.TM.blf
    ::wim.ini:\Windows\System32\SMI\Store\Machine\SCHEMA.DAT*.regtrans-ms
    ::wim.ini:\Windows\System32\SMI\Store\Machine\SCHEMA.DAT*.log*
    ::wim.ini:\Windows\System32\sysprep\Panther
    ::wim.ini:\Windows\System32\winevt\Logs\*
    ::wim.ini:\Windows\System32\winevt\TraceFormat\*
    ::wim.ini:\Windows\Temp\*
    ::wim.ini:\Windows\TSSysprep.log
    ::wim.ini:

::: for current hotfix
    ::chot.xml:<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    ::chot.xml:    <xsl:output method="text"/><xsl:template match="/">
    ::chot.xml:        <xsl:for-each select="//References"><xsl:sort select="DownloadURL"/>
     ::!_chot!:            <xsl:if test="not(contains(DownloadURL, 'kb!_chot_kb!'))">
    ::chot.xml:            <xsl:value-of select="DownloadURL"/><xsl:text>&#10;</xsl:text>
     ::!_chot!:            </xsl:if>
    ::chot.xml:        </xsl:for-each>
    ::chot.xml:    </xsl:template>
    ::chot.xml:</xsl:transform>

::: for unattend.xml
        ::unattend.xml:<?xml version="1.0" encoding="utf-8"?>
        ::unattend.xml:<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
        ::unattend.xml:    <settings pass="oobeSystem">
    ::!_unattend_lang!:        <component name="Microsoft-Windows-International-Core" processorArchitecture="!_bit!" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
    ::!_unattend_lang!:            <InputLocale>!_lang!</InputLocale>
    ::!_unattend_lang!:            <SystemLocale>!_lang!</SystemLocale>
    ::!_unattend_lang!:            <UILanguage>!_lang!</UILanguage>
    ::!_unattend_lang!:            <UILanguageFallback>!_lang!</UILanguageFallback>
    ::!_unattend_lang!:            <UserLocale>!_lang!</UserLocale>
    ::!_unattend_lang!:        </component>
        ::unattend.xml:        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="!_bit!" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
        ::unattend.xml:            <AutoLogon>
        ::unattend.xml:                <Enabled>true</Enabled>
        ::unattend.xml:                <LogonCount>1</LogonCount>
        ::unattend.xml:                <Username>!_user!</Username>
        ::unattend.xml:            </AutoLogon>
        ::unattend.xml:            <OOBE>
        ::unattend.xml:                <SkipMachineOOBE>true</SkipMachineOOBE>
        ::unattend.xml:            </OOBE>
    ::!_unattend_user!:            <UserAccounts>
    ::!_unattend_user!:                <LocalAccounts>
    ::!_unattend_user!:                    <LocalAccount wcm:action="add">
    ::!_unattend_user!:                        <Password>
    ::!_unattend_user!:                            <Value></Value>
    ::!_unattend_user!:                            <PlainText>true</PlainText>
    ::!_unattend_user!:                        </Password>
    ::!_unattend_user!:                        <Group>administrators;!_user!</Group>
    ::!_unattend_user!:                        <Name>!_user!</Name>
    ::!_unattend_user!:                    </LocalAccount>
    ::!_unattend_user!:                </LocalAccounts>
    ::!_unattend_user!:            </UserAccounts>
    ::!_unattend_lang!:            <TimeZone>!_standard_time!</TimeZone>
        ::unattend.xml:        </component>
        ::unattend.xml:    </settings>
        ::unattend.xml:</unattend>

::: hisecws.inf: Registry Values: 1:REG_SZ 2:REG_EXPAND_SZ 3:REG_BINARY 4:REG_DWORD 7:REG_MULTI_SZ
    ::hisecws.inf:[Unicode]
    ::hisecws.inf:Unicode=yes
    ::hisecws.inf:
    ::hisecws.inf:[System Access]
    ::hisecws.inf:MaximumPasswordAge = -1
    ::hisecws.inf:MinimumPasswordLength = 7
    ::hisecws.inf:PasswordComplexity = 1
    ::hisecws.inf:
    ::hisecws.inf:[Registry Values]
    ::hisecws.inf:MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableCAD=4,1
    ::hisecws.inf:MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayLastUserName=4,1
    ::hisecws.inf:MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DontDisplayUserName=4,1
    ::hisecws.inf:MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDriveTypeAutoRun=4,255
    ::hisecws.inf:MACHINE\Software\Policies\Microsoft\Windows NT\Reliability\**del.ShutdownReasonUI=1,""
    ::hisecws.inf:MACHINE\Software\Policies\Microsoft\Windows NT\Reliability\ShutdownReasonOn=4,0
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseAdvancedStartup=4,1
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\EnableBDEWithNoTPM=4,1
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPM=4,2
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPMPIN=4,0
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPMKey=4,2
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPMKeyPIN=4,0
    ::hisecws.inf:MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymous=4,1
    ::hisecws.inf:MACHINE\System\CurrentControlSet\Control\Lsa\RestrictAnonymousSAM=4,1
    ::hisecws.inf:User\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoThumbnailCache=4,1
    ::hisecws.inf:User\Software\Policies\Microsoft\Windows\Explorer\DisableThumbsDBOnNetworkFolders=4,1
    ::hisecws.inf:
    ::hisecws.inf:[Privilege Rights]
    ::hisecws.inf:;SeDenyRemoteInteractiveLogonRight = Administrator
    ::hisecws.inf:SeRemoteInteractiveLogonRight = *S-1-5-32-555
    ::hisecws.inf:
    ::hisecws.inf:[Version]
    ::hisecws.inf:signature="$CHICAGO$"
    ::hisecws.inf:Revision=1
    ::hisecws.inf:

    ::DefaultLayouts.xml:<?xml version="1.0" encoding="utf-8"?>
    ::DefaultLayouts.xml:<FullDefaultLayoutTemplate
    ::DefaultLayouts.xml:    xmlns="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    ::DefaultLayouts.xml:    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    ::DefaultLayouts.xml:    Version="1">
    ::DefaultLayouts.xml:    <StartLayoutCollection>
    ::DefaultLayouts.xml:        <StartLayout
    ::DefaultLayouts.xml:            GroupCellWidth="6"
    ::DefaultLayouts.xml:            PreInstalledAppsEnabled="false">
    ::DefaultLayouts.xml:            <start:Group Name="">
    ::DefaultLayouts.xml:                <start:Tile
    ::DefaultLayouts.xml:                    AppUserModelID="Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge"
    ::DefaultLayouts.xml:                    Size="4x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="0"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Administrative Tools\services.lnk"
    ::DefaultLayouts.xml:                    Size="2x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="4"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Accessories\Notepad.lnk"
    ::DefaultLayouts.xml:                    Size="1x1"
    ::DefaultLayouts.xml:                    Row="2"
    ::DefaultLayouts.xml:                    Column="0"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationID="Microsoft.Windows.ControlPanel"
    ::DefaultLayouts.xml:                    Size="1x1"
    ::DefaultLayouts.xml:                    Row="2"
    ::DefaultLayouts.xml:                    Column="1"/>
    ::DefaultLayouts.xml:                <start:Tile
    ::DefaultLayouts.xml:                    AppUserModelID="Microsoft.WindowsStore_8wekyb3d8bbwe!App"
    ::DefaultLayouts.xml:                    Size="4x2"
    ::DefaultLayouts.xml:                    Row="2"
    ::DefaultLayouts.xml:                    Column="2"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Command Prompt.lnk"
    ::DefaultLayouts.xml:                    Size="1x1"
    ::DefaultLayouts.xml:                    Row="3"
    ::DefaultLayouts.xml:                    Column="1"/>
    ::DefaultLayouts.xml:            </start:Group>
    ::DefaultLayouts.xml:        </StartLayout>
    ::DefaultLayouts.xml:
    ::DefaultLayouts.xml:        <StartLayout
    ::DefaultLayouts.xml:            GroupCellWidth="6"
    ::DefaultLayouts.xml:            SKU="Server|ServerSolution">
    ::DefaultLayouts.xml:            <start:Group>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Server Manager.lnk"
    ::DefaultLayouts.xml:                    Size="2x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="0"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Command Prompt.lnk"
    ::DefaultLayouts.xml:                    Size="2x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="2"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationID="Microsoft.Windows.ControlPanel"
    ::DefaultLayouts.xml:                    Size="2x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="4"/>
    ::DefaultLayouts.xml:            </start:Group>
    ::DefaultLayouts.xml:        </StartLayout>
    ::DefaultLayouts.xml:    </StartLayoutCollection>
    ::DefaultLayouts.xml:</FullDefaultLayoutTemplate>
    ::DefaultLayouts.xml:

    ::regon.inf:[Version]
    ::regon.inf:signature="$CHICAGO$"
    ::regon.inf:
    ::regon.inf:[DefaultInstall]
    ::regon.inf:DelReg=regoff
    ::regon.inf:
    ::regon.inf:[regoff]
    ::regon.inf:HKCU,"Software\Microsoft\Windows\CurrentVersion\Policies\System","DisableRegistryTools"
    ::regon.inf:

   :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::             Embedded Documents            ::
:::::::::::::::::::::::::::::::::::::::::::::::
