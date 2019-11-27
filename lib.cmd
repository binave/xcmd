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
::     If the function names conform to the specifications:
::         External call function. (Support short name completion)
::         Error handling.
::         Display help information.
::         Print the functions list.
::
::     e.g.
::         ::: "[brief_introduction]" "" "[description_1]" "[description_2]" ...
::         :::: "[error_description_1]" "[error_description_2]" ...
::         :[script_name_without_suffix]\[function_name]
::             ...
::             [function_body]
::             ...
::             REM exit and display [error_description_1]
::             exit /b 1
::             ...
::             REM return false status
::             exit /b 30
::
:: Thread:
::     e.g.
::         \\:[function_name] [args1] [args2] ...
:: ...
:: :[function_name]
:: ...
:: goto :eof

::::::::::::::::::::::::::
:: some basic functions ::
::::::::::::::::::::::::::

REM init errorlevel
set errorlevel=

REM For thread
if "%~d1"=="\\" call :thread "%*" & exit

REM Init PATH
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

if "%~2"=="-h" call :this\annotation :%~n0\%~1 & exit /b 0
if "%~2"=="--help" call :this\annotation :%~n0\%~1 & exit /b 0

2>nul call :%~n0\%*

REM Test type function
if errorlevel 30 exit /b 1
if errorlevel 1 call :this\annotation :%~n0\%* & goto :eof
exit /b 0

:lib\
:lib\--help
:lib\-h
    call :this\annotation
    exit /b 0

::: "Output version and exit"
:lib\version
    >&3 echo 0.18.10
    exit /b 0

::: "Variable tool" "" "usage: %~n0 var [option] [...]" "    --unset, -u   [[var_name]]      Unset variable, where variable name left contains" "    --env,   -e   [key] [value]     Set environment variable" "" "    --set-errorlevel, -sel  [num]          Set errorlevel variable" "" "    --in-path,    -p   [file_name]         Test target in $env:path" "    --trim-path,  -sp  [var_name]          Path Standardize" "    --reset-path, -rp                      Reset default path environment variable" "" "    --install-config,   -ic   Support load %USERPROFILE%\.batchrc before cmd.exe run" "    --uninstall-config, -uc   remove config loader" "    --backspace,        -bs   [var_name]  Get some backspace (erases previous character)"
:::: "invalid option" "key is empty" "value is empty" "The parameter is empty" "first args is empty" "variable name is empty" "variable name not defined"
:lib\var
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\var\%*
    goto :eof

REM override:
REM "":         [variable_prefix_name*]
:this\var\--unset   [variable_prefix_name]
:this\var\-u
    if "%~1"=="" exit /b 4
    for /f "usebackq delims==" %%a in (
        `2^>nul set %1`
    ) do set %%a=
    exit /b 0

:this\var\--env
:this\var\-e
    if "%~1"=="" exit /b 2
    if "%~2"=="" exit /b 3
    REM for %%a in (setx.exe) do if "%%~$path:a" neq "" >nul setx.exe %~1 %2 /m & exit /b 0
    if defined %~1 wmic.exe environment where 'name="%~1" and username="<system>"' set VariableValue="%~2"
    if not defined %~1 wmic.exe environment create name="%~1",username="<system>",VariableValue="%~2"
    exit /b 0

:this\var\--set-errorlevel
:this\var\-sel
    if "%~1"=="" goto :eof
    exit /b %1

:this\var\--in-path
:this\var\-p
    if "%~1" neq "" if "%~$path:1" neq "" exit /b 0
    exit /b 30

:this\var\--trim-path
:this\var\-sp
    if "%~1"=="" exit /b 6
    if not defined %~1 exit /b 7
    setlocal enabledelayedexpansion
    REM TODO get var value in path
    REM Trim quotes
    set _var=!%~1:"=!
    REM " Trim head/tail semicolons
    if "%_var:~0,1%"==";" set _var=%_var:~1%
    if "%_var:~-1%"==";" set _var=%_var:~0,-1%
    REM Replace slash end of path
    set _var=%_var:\;=;%;
    REM Delete path if not exist
    call :this\path\trim "%_var:;=" "%"
    endlocal & set %~1=%_var:~0,-1%
    exit  /b 0

REM for :this\var\--trim-path, delete path if not exist
:this\path\trim
    if "%~1"=="" exit /b 0
    if not exist %1 set _var=!_var:%~1;=!
    shift /1
    goto %0

:this\var\--reset-path
:this\var\-rp
    for /f "usebackq tokens=2 delims==" %%a in (
        `wmic.exe ENVIRONMENT where "Caption='<SYSTEM>\\Path'" get VariableValue /format:list`
    ) do call set path=%%a
    exit /b 0

:this\var\--backspace
:this\var\-s
    if "%~1"=="" exit /b 6
    for /f %%a in ('"prompt $h & for %%a in (.) do REM"') do set %~1=%%a
    exit /b 0

:this\var\--install-config
:this\var\-ic
    setlocal

    call :this\var\--backspace _bs
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
        echo set path=%%path%%;%~dp0
        echo.
        echo title Command Prompt
    )
    endlocal
    exit /b 0

:this\var\--uninstall-config
:this\var\-uc
    setlocal
    call :regedit\on
    REM erase "%USERPROFILE%\.batchrc"
    reg.exe delete "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /f
    call :regedit\off
    endlocal
    exit /b 0


::: "Run by ..." "" "usage: %~n0 run [option]" "" "    --admin,  -a  [...]    Run As Administrator" "    --vbhide, -q  [...]    Run some command at background"
:::: "invalid option" "The first parameter is empty"
:lib\run
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\run\%*
    goto :eof

:this\run\--admin
:this\run\-a
    REM net.exe user administrator /active:yes
    REM net.exe user administrator ???
    runas.exe /savecred /user:administrator "%*"
    exit /b 0

:this\run\--vbhide
:this\run\-q
    if "%~1"=="" exit /b 2
    REM mshta.exe VBScript:CreateObject("WScript.Shell").Run("""%~1"" %~2", 0)(Window.close)
    REM see https://docs.microsoft.com/zh-tw/windows/desktop/shell/shell-shellexecute#code-snippet-1
    REM mshta.exe VBScript:CreateObject("Shell.Application").ShellExecute("%~1","%2 %3 %4 %5 %6 %7 %8 %9","","open",0)(window.close)
    call :lib\vbs vbhide "%~1"
    exit /b 0

::: "Test string status" "" "usage: %~n0 is [option] [[string]]" "" "    --integer, -i  [string]   Test string if integer" "    --pipe                    Test script run after pipe" "    --gui                     Test script start at GUI"
:lib\is
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\is\%*
    goto :eof

:this\is\--integer
:this\is\-i
    if "%~1"=="" exit /b 30
    setlocal
    set _tmp=
    REM quick return
    2>nul set /a _code=30, _tmp=%~1
    if "%~1"=="%_tmp%" set _code=0
    endlocal & exit /b %_code%

:this\is\--pipe
:this\is\--gui
    setlocal
    set cmdcmdline=
    set _cmdcmdline=%cmdcmdline:"='%
    rem "
    set _code=0
    if /i "%0"==":this\is\--pipe" if "%_cmdcmdline%"=="%_cmdcmdline:  /S /D /c' =%" set _code=30
    if /i "%0"==":this\is\--gui" if "%_cmdcmdline%"=="%_cmdcmdline: /c ''=%" set _code=30
    REM if /i "%0"==":this\is\--gui" for %%a in (%cmdcmdline%) do if /i %%~a==/c set _code=0
    endlocal & exit /b %_code%

:this\is\--ipv4
:this\is\-ip
    call :this\ip\--test %1 && exit /b 0
    exit /b 30

REM REM Test mac addr
:this\is\--MACaddr
:this\is\-mac
    setlocal enabledelayedexpansion
    set "_mac_addr=%~1"
    for %%z in (
        %_mac_addr:|= %
    ) do for /f "usebackq tokens=1-6 delims=-:" %%a in (
        '%%z'
    ) do (
        if "%%z" neq "%%a-%%b-%%c-%%d-%%e-%%f" if "%%z" neq "%%a:%%b:%%c:%%d:%%e:%%f" exit /b 30
        for %%g in (
            "%%a" "%%b" "%%c" "%%d" "%%e" "%%f"
        ) do (
            2>nul set /a _hx=0x%%~g || exit /b 30
            if !_hx! gtr 255 exit /b 30
        )
    )
    endlocal
    exit /b 0

::: "Process tools" ""  "usage: %~n0 ps [option] [...]" "" "    --kill, -k [process_name...]  kill process" "    --test, -t [exec_name]        Test exe if live"
:::: "invalid option" "first parameter is empty"
:lib\ps
    call :this\ps\%*
    goto :eof

:this\ps\
    for /f "usebackq tokens=1* delims==" %%a in (`
        wmic.exe process get CommandLine^,Description^,ProcessId /value
    `) do echo.%%b
    goto :eof

:this\ps\--test
:this\ps\-t
    REM tasklist.exe /v /FI "imagename eq %~n1.exe"
    if "%~1"=="" exit /b 2
    for /f usebackq^ tokens^=2^ delims^=^=^" %%a in (
        `2^>nul wmic.exe process where caption^="%~n1.exe" get commandline /value`
    ) do for %%b in (
        %%a
    ) do if "%%~nb"=="%~n1" exit /b 0
    REM "
    exit /b 30

:this\ps\--kill
:this\ps\-k
    if "%~1"=="" exit /b 2
    for %%a in (
        %*
    ) do wmic.exe process where name="%%a.exe" delete

    REM for /f "usebackq skip=1" %%a in (
    REM     `2^>nul wmic.exe process where "commandline like '%*'" get processid`
    REM ) do for %%b in (%%a) do >nul wmic.exe process where processid="%%b" delete

    REM start "" /b "%~f0" %*

    REM taskkill.exe /f /im %~1.exe
    exit /b 0

::: "Calculating time intervals, print use time" "" "must be run it before and after function"
:lib\ctime
    setlocal
    set time=
    for /f "tokens=1-4 delims=:." %%a in (
        "%time%"
    ) do set /a _tmp=%%a*360000+1%%b%%100*6000+1%%c%%100*100+1%%d%%100
    if defined _ctime (
        set /a _tmp-=_ctime
        set /a _h=_tmp/360000,_min=_tmp%%360000/6000,_s=_tmp%%6000/100,_cs=_tmp%%100
        set _tmp=
    )
    if defined _ctime echo %_h%h %_min%min %_s%s %_cs%cs
    endlocal & set _ctime=%_tmp%
    exit /b 0

::: "Update hosts by ini"
:::: "no ini file found"
:lib\hosts
    setlocal enabledelayedexpansion
    REM load ini config
    call :this\load_ini hosts 1 || exit /b 1
    REM get key array
    call :map --keys _keys 1
    REM override mac to ipv4
    for /f "usebackq tokens=1*" %%a in (
        `call %~nx0 ip --find %_keys%`
    ) do if not defined _set\%%b (
        call :map --put %%b %%a 1 && call :this\str\--2col-left %%~a %%b
        set _set\%%b=-
    )

    REM replace hosts in cache
    REM use tokens=2,3 will replace %%a
    for /f "usebackq tokens=1* delims=]" %%a in (
        `type %windir%\System32\drivers\etc\hosts ^| find.exe /n /v ""`
    ) do for /f "usebackq tokens=1-3" %%c in (
        '. %%b'
    ) do call :this\ip\--test %%d && (
        call :map --get %%e _value 1 && (
            for %%f in (
                !_value!
            ) do call :this\ip\--test "%%~f" && (
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
        call :this\ip\--test %%a && (
            call :page --put %%~a   !_key!
        )
        set _key=%%~a
    )

    > %windir%\System32\drivers\etc\hosts call :page --show

    endlocal
    goto :eof

::: "Ipv4 tools" "" "usage: %~n0 ip [option]" "" "    --test, -t [str]      Test string if ipv4" "    --list, -l            Show this ipv4" "    --find, -f [MAC] ...  Search IPv4 by MAC or Host name"
:::: "invalid option" "host name is empty" "args not mac addr"
:lib\ip
    if "%~1"=="" call :this\annotation %0 & goto :eof
    2>nul call :this\ip\%*
    goto :eof

:this\ip\--test
:this\ip\-t
    if "%~1"=="" exit /b 2
    REM [WARN] use usebackq will set all variable global, by :lib\hosts
    for /f "tokens=1-4 delims=." %%a in (
        "%~1"
    ) do (
        if "%~1" neq "%%a.%%b.%%c.%%d" exit /b 30
        for %%e in (
            "%%a" "%%b" "%%c" "%%d"
        ) do (
            call :this\is\--integer %%~e || exit /b 30
            if %%~e lss 0 exit /b 30
            if %%~e gtr 255 exit /b 30
        )
    )
    exit /b 0

:this\ip\--list
:this\ip\-l
    setlocal
    REM Get router ip
    call :this\get_route_ip _route
    REM "
    for %%a in (
        %_route%
    ) do for /f usebackq^ skip^=1^ tokens^=2^ delims^=^" %%b in (
        `wmic.exe NicConfig get IPAddress`
    ) do if "%%~nb"=="%%~na" echo %%b
    endlocal
    exit /b 0

:this\ip\--find
:this\ip\-f
    if "%~1"=="" exit /b 2
    setlocal enabledelayedexpansion

    REM get config
    call :this\load_ini sip_setting -f
    call :map --get route _routes -f
    call :map --get range _range -f
    call :map --clear -f
    if not defined _range set _range=1-127

    call :this\load_ini hosts -f

    set _mac_addr=

    for %%a in (
        %*
    ) do (
        REM Get value
        call :map --get %%a _arg -f && (
            set "_mac_addr=!_arg: =!"
        ) || set _mac_addr=%%a
        REM Format
        set "_mac_addr=!_mac_addr::=-!"
        call :map --put %%a "!_mac_addr!" -t
    )

    if not defined _mac_addr exit /b 0
    call :map --clear -f

    REM Get router ip
    call :this\get_route_ip _get_route_ip
    for %%a in (
        %_routes% %_get_route_ip%
    ) do if not defined _tmp\%%~na (
        set _tmp\%%~na=-
        set "_route=!_route! %%a"
    )

    call :map --keys _keys -t

    REM Clear arp cache
    arp.exe -d

    REM Search MAC
    for %%a in (
        %_route%
    ) do for /l %%b in (
        %_range:-=,1,%
    ) do (
        call :this\thread_valve 50 cmd.exe --find
        start /b %~nx0 \\:ip\--find %%~na.%%b %_keys%
    )

    REM print ipv4 for mac addr not catch
    for %%a in (
        %_keys%
    ) do call :map --get %%~a _value -t && for %%b in (
        !_value:^|^= !
    ) do call :this\ip\--test %%b && call :this\str\--2col-left %%b %%~a

    endlocal
    exit /b 0

REM nbtstat
REM For thread sip
:ip\--find
    REM some ping will fail, but arp success
    >nul 2>nul ping.exe -n 1 -w 1 %1
    setlocal enabledelayedexpansion
    for /f "usebackq skip=3 tokens=1,2" %%a in (
        `arp.exe -a %1`
    ) do for %%c in (
        %*
    ) do call :map --get %%~c _value -t ^
        && if "!_value:%%b=!" neq "!_value!" call :this\str\--2col-left %%a %%~c

    endlocal
    exit /b 0

REM Get router ip
:this\get_route_ip
    if "%~1"=="" exit /b 1
    REM "
    for /f usebackq^ skip^=1^ tokens^=2^ delims^=^" %%a in (
        `wmic.exe NicConfig get DefaultIPGateway`
    ) do set %1=%%a
    exit /b 0

::: "Directory tools" "" "usage: %~n0 dir [option] [...]" "" "    --isdir,  -id  [path]       Test path is directory" "    --islink, -il  [file_path]  Test path is Symbolic Link" "    --isfree, -if  [dir_path]   Test directory is empty" "    --clean,  -c   [dir_path]   Delete empty directory" "    --unique, -u   [[dir_path]] Move duplicate files to '.#Trash'"
:::: "invalid option" "Not directory" "target not found" "target not a directory"
:lib\dir
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\dir\%*
    goto :eof

:this\dir\--isdir
:this\dir\-id
    setlocal
    set _attribute=%~a1-
    REM quick return
    set _code=30
    if %_attribute:~0,1%==d set _code=0
    endlocal & exit /b %_code%

:this\dir\--islink
:this\dir\-il
    for /f "usebackq delims=" %%a in (
        `2^>nul dir /al /b "%~dp1"`
    ) do if "%%a"=="%~n1" exit /b 0
    REM quick return
    exit /b 30

:this\dir\--isfree
:this\dir\-if
    call :this\dir\--isdir %1 || exit /b 2
    for /f usebackq"" %%a in (
        `dir /a /b "%~1"`
    ) do exit /b 30
    exit /b 0

:this\dir\--clean
:this\dir\-c
    if not exist "%~1" exit /b 3
    call :this\dir\--isdir %1 || exit /b 4
    if exist %windir%\system32\sort.exe (
        call :dir\rdEmptyDirWithSort %1
    ) else call :dir\rdEmptyDir %1
    goto :eof

REM for :this\dir\--clean
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

REM for :this\dir\--clean
:dir\rdEmptyDirWithSort
    if "%~1"=="" exit /b 2
    for /f "usebackq delims=" %%a in (
        `dir /ad /b /s %1 ^| sort.exe /r`
    ) do 2>nul rmdir "%%~a"
    exit /b 0

:this\dir\--unique
:this\dir\-u
    setlocal enabledelayedexpansion

    if exist "%~1" pushd "%cd%"& chdir /d "%~1" || exit /b 4

    for /d %%a in (
        "%cd%\*"
    ) do if /i "%%~nxa" neq ".#Trash" call :dir\recursion "%%~a"

    for /f "usebackq delims=" %%a in (
        `dir /a-d /b "%cd%"`
    ) do for %%b in (
        "%cd%\%%~a"
    ) do set /a _#\%%~zb += 1 & set _$\%%~zb.!random!!random!=%%~b

    if exist "%~1" popd

    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _#\`
    ) do if %%b gtr 1 for /f "usebackq tokens=1* delims==" %%c in (
        `2^>nul set _$\%%~na.`
    ) do for /f "usebackq tokens=1,2 delims=(h" %%e in (
        `certutil.exe -hashfile "%%d" sha256`
    ) do if "%%f"=="" call :dir\hashkey "%%~na" "%%e" "%%d"

    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _c\`
    ) do if %%b gtr 1 (
        echo.
        echo find '%%b' duplicate file.
        for /f "usebackq tokens=1* delims==" %%c in (
            `2^>nul set _sh\%%~nxa.`
        ) do call :dir\pre8 %%~nc %%d
        for /f "usebackq skip=1 tokens=1* delims==" %%c in (
            `2^>nul set _sh\%%~nxa.`
        ) do >nul mkdir ".#Trash%%~pd"& echo !_size!,MOVE '%%~d' -^> '.#Trash%%~pd'& >nul move "%%~d" ".#Trash%%~pd"
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


::: "Operating system setting" "" "usage: %~n0 oset [option] [...]" "" "    --vergeq,   -vg    [version]                  Test current version is greater than the given value" "    --cleanup,  -c     [[path]]                   Component Cleanup" "    --version,  -v     [os_path] [[var_name]]     Get OS version" "    --bit,      -b     [os_path] [[var_name]]     Get OS bit" "    --language, -lang  [var_name] [[os_path]]     Get OS current language" "    --sid,      -s     [[user_name]] [[var_name]] Get sid by username. if not set path, will get online info" "" "    --feature-info,   -fi                         Get Feature list" "    --feature-enable, -fe  [name ...]             Enable Features" "    --set-power,      -sp                         Set power config as server type" "    --unsecure-write, -usw [--allow/--deny]       Allow / Deny write access to 'fixed' and 'removable' drives" "    --regedit,        -reg [--on/--off]" "    --gpedit,         -gp  [--on/--off]"
:::: "invalid option" "Parameter is empty or Not a float" "not a directory" "Not OS path or Low OS version" "parameter is empty" "System version is too old" "not operating system directory" "not support" "reg error" "scratch directory not exist"
:lib\oset
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\oset\%*
    goto :eof

:this\oset\--vergeq
:this\oset\-vg
    if "%~x1"=="" exit /b 2
    setlocal
    call :oset\this_version_multiply_10 _this_ver
    for /f "usebackq tokens=1,2 delims=." %%a in (
        '%~1'
    ) do set /a _ver=%_this_ver% - %%a * 10 - %%b
    endlocal & if %_ver% geq 0 exit /b 0
    exit /b 30

:oset\this_version_multiply_10 [variable_name]
    if "%~1"=="" exit /b 1
    for /f "usebackq skip=1" %%a in (
        `wmic.exe os get Version`
    ) do for %%b in (%%~na) do for /f "usebackq tokens=1,2 delims=." %%c in (
        '%%b'
    ) do set /a %~1=%%c * 10 + %%d
    exit /b 0

:this\oset\--cleanup
:this\oset\-c
    if "%~1"=="" dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase & exit /b 0
    call :this\dir\--isdir "%~1" || exit /b 3
    call :this\dir\--isdir "%~2" || exit /b 10
    dism.exe /Image:%1 /Cleanup-Image /StartComponentCleanup /ResetBase /ScratchDir:"%~2"
    exit /b 0

REM OS version
:this\oset\--version
:this\oset\-v
    if not exist "%~1" exit /b 3
    if "%~1"=="%~d1" (
        call :oset\version %~1\ %2
    ) else if "%~dp1"=="%~f1" (
        call :oset\version "%~f1" %2
    ) else call :oset\version "%~f1\" %2
    goto :eof

:oset\version
    for /f "usebackq" %%a in (
        `2^>nul dir /ad /b %~1Windows\servicing\Version\*.*`
    ) do if exist %~1Windows\servicing\Version\%%a\*_installed if "%~2"=="" (
        echo %%a& exit /b 0
    ) else set %~2=%%a& exit /b 0
    exit /b 4

:this\oset\--sid
:this\oset\-s
    if "%~1"=="" (
        for /f "usebackq skip=1" %%a in (
            `wmic.exe useraccount where name^='%username%' get sid`
        ) do for %%b in (%%a) do echo.%%b
    ) else for /f "usebackq skip=1" %%a in (
        `wmic.exe useraccount where name^='%1' get sid`
    ) do for %%b in (%%a) do if "%~2"=="" (
        echo.%%b
    ) else set %~2=%%b
    exit /b 0

:this\oset\--bit
:this\oset\-b
    if not exist "%~1" exit /b 3
    if "%~1"=="%~d1" (
        call :oset\bit %~1\ %2
    ) else if "%~dp1"=="%~f1" (
        call :oset\bit "%~f1" %2
    ) else call :oset\bit "%~f1\" %2
    goto :eof

:oset\bit
    if not exist %~1Windows\servicing\Version exit /b 4
    for /d %%a in (
        %~1Windows\servicing\Version\*.*
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
    exit /b 6

REM https://docs.microsoft.com/en-us/previous-versions/tn-archive/cc287874(v=office.12)
REM https://docs.microsoft.com/en-us/previous-versions/commerce-server/ee825488(v=cs.20)
:this\oset\--language
:this\oset\-lang
    setlocal
    call :regedit\on
    set _load_point=HKLM\load-point%random%
    if "%~2" neq "" (
        reg.exe load %_load_point% %~2\Windows\System32\config\DRIVERS || (
            call :regedit\off
            exit /b 7
        )
        for /f "usebackq tokens=1,4 delims=x " %%a in (
            `reg.exe query %_load_point%\select`
        ) do if "%%b"=="Default" call :lang\current %_load_point%\ControlSet00%%b _lang || (
            call :regedit\off
            exit /b 8
        )
        reg.exe unload %_load_point%
    ) else call :lang\current HKLM\SYSTEM\CurrentControlSet _lang || (
        call :regedit\off
        exit /b 8
    )
    call :regedit\off
    if "%~1"=="" echo.%_lang%
    endlocal & if "%~1" neq "" set %~1=%_lang%
    goto :eof

REM for :this\oset\--language
:lang\current
    for /f "usebackq tokens=1,3" %%a in (
        `reg.exe query %~1\Control\Nls\Language /v Default`
    ) do if "%%a"=="Default" for %%c in (
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

:this\oset\--feature-info
:this\oset\-fi
    for /f "usebackq tokens=1-4" %%a in (
        `dism.exe /English /Online /Get-Features`
    ) do (
        if "%%a%%b"=="FeatureName" call :this\txt\--all-col-left %%d
        if "%%a"=="State" call :this\txt\--all-col-left %%c & echo.
    )
    call :this\txt\--all-col-left 0 0
    exit /b 0

:this\oset\--feature-enable
:this\oset\-fe
    if "%~1"=="" exit /b 5
    for %%a in (
        %*
    ) do dism.exe /Online /Enable-Feature /FeatureName:%%a /NoRestart
    exit /b 0

:this\oset\--set-power
:this\oset\-sp
    call :this\oset\--vergeq 6.0 || exit /b 6

    REM powercfg
    powercfg.exe /h off

    for /f "usebackq skip=2 tokens=4" %%a in (
        `powercfg.exe /list`
    ) do for %%b in (
        ::?"while the system is powered by DC power"
        dc
        ::?"while the system is powered by AC power"
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

REM TODO
REM https://technet.microsoft.com/en-us/security/cc184924.aspx
:this\oset\--current-hotfix
:this\oset\-ch
    setlocal enabledelayedexpansion
    set _oset_uuid=8e16a4c7-dd28-4368-a83a-282c82fc212a

    call :oset\hot\setup %_oset_uuid%

    REM http://go.microsoft.com/fwlink/?LinkId=76054
    call :this\str\--now _odt_now

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

    if not exist %temp%\%_oset_uuid%\wsusscn2.cab call :lib\download ^
        http://download.windowsupdate.com/microsoftupdate/v6/wsusscan/wsusscn2.cab ^
            %temp%\%_oset_uuid%\wsusscn2.cab || exit /b 2

    REM create results
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

    >%temp%\%_oset_uuid%\chot.xsl call :this\txt\--subtxt "%~f0" chot.xml 3000

    REM split xml -> log
    call :lib\vbs doxsl ^
            "%temp%\results_%_odt_now%.xml" ^
            %temp%\%_oset_uuid%\chot.xsl ^
            %temp%\hotlist_%_odt_now%.log || exit /b 1

    REM install lang, like. ':this\oset\--language'
    set _lang=
    if %_hot_ver% lss 60 for /f "usebackq skip=1 tokens=1" %%a in (
        `wmic.exe os get OSLanguage`
    ) do for %%b in (
        cht.1028
        enu.1033
        jpn.1041
        kor.1042
        chs.2052
    ) do if ".%%a"=="%%~xb" set _lang=%%~nb

    REM support exfat
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

REM download and set in path
:oset\hot\setup
    for %%a in (mbsacli.exe) do if "%%~$path:a" neq "" exit /b 0

    set PATH=%temp%\%~1;%PATH%
    if not exist %temp%\%~1\mbsacli.exe (
        2>nul mkdir %temp%\%~1
        REM call :lib\download http://download.microsoft.com/download/A/1/0/A1052D8B-DA8D-431B-8831-4E95C00D63ED/MBSASetup-x%processor_architecture:~-2%-EN.msi %temp%\%~1\MBSASetup.msi || exit /b 1
        call :lib\download ^
            http://download.microsoft.com/download/8/E/1/8E16A4C7-DD28-4368-A83A-282C82FC212A/MBSASetup-x%processor_architecture:~-2%-EN.msi ^
                %temp%\%~1\MBSASetup.msi || exit /b 1

        pushd %cd%
            cd /d %temp%\%~1
            call :this\un\.msi %temp%\%~1\MBSASetup.msi
        popd

        REM mbsacli.exe wusscan.dll
        move /y "%temp%\%~1\MBSASetup\ProgramF\Microsoft Baseline Security Analyzer 2\??s?c??.???" %temp%\%~1
        rmdir /s /q %temp%\%~1\MBSASetup
    )

    exit /b 0

:this\oset\--regedit
:this\oset\-reg
    call :oset\regedit\%*
    goto :eof

:oset\regedit\--on
    REM https://docs.microsoft.com/en-us/windows-hardware/drivers/install/inf-defaultinstall-section

    >%temp%\b1444fb0-c076-5356-7ad3-25aa25d4e37a.inf call :this\txt\--subtxt "%~f0" regon.inf 3000
    REM pnputil.exe -i -a %temp%\b1444fb0-c076-5356-7ad3-25aa25d4e37a.inf
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

:this\oset\--gpedit
:this\oset\-gp
    setlocal
    call :regedit\on
    call :oset\gpedit\%*
    call :regedit\off
    endlocal
    goto :eof

:oset\gpedit\--on
    reg.exe delete HKCU\Software\Policies\Microsoft\MMC /f || exit /b 9
    >&3 echo complete.
    goto :eof

:oset\gpedit\--off
    reg.exe ^
        add HKCU\Software\Policies\Microsoft\MMC\{8FC0B734-A0E1-11D1-A7D3-0000F87571E3} ^
            /v Restrict_Run ^
            /t REG_DWORD ^
            /d 1 /f || exit /b 9
    >&3 echo complete.
    goto :eof

:this\oset\--unsecure-write
:this\oset\-usw
    setlocal
    call :regedit\on
    call :oset\write_access\%~1
    call :regedit\off
    endlocal
    goto :eof

REM deny write access to fixed/removable drives not protected by BitLocker
:oset\write_access\--deny
    >nul reg.exe ^
        add HKLM\Software\Policies\Microsoft\FVE ^
            /v RDVDenyCrossOrg ^
            /t REG_DWORD ^
            /d 0 /f || exit /b 7

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

::: "Thread lock" "" "usage: %~n0 lock [option] [...]" "" "    --ratelimit, -rl   [dir_path] [sec]       rate limit"
:::: "" "args not int"
:lib\lock
    goto :eof

:lock\--ratelimit   [dir_path] [sec]
:lock\-rl
    call :this\is\--integer %~2 || exit /b 2
    setlocal
    REM rate limit

    call :this\str\--now now_stamp

    REM get lock success
    2>nul mkdir "%~1\ratelimit.lock" && (
        >"%~1\ratelimit.lock\timestamp.log" echo %now_stamp%
        exit /b 0
    )

    REM get lock failed, read log
    set timestamp=
    for /f "usebackq delims=" %%a in (
        "%~1\ratelimit.lock\timestamp.log"
    ) do if "%%~a" neq "" set timestamp=%%~a

    call :this\is\--integer %timestamp% && (
        for /f "usebackq delims=" %%a in (`
            set /a 1%now_stamp:~6% - 1%timestamp:~6%
        `) do if %%a gtr %~2 (
            rmdir /s /q "%~1\ratelimit.lock"
            goto lock\--ratelimit
        ) else exit /b 1
    )
    endlocal
    if not exit exist "%~1\ratelimit.lock" goto lock\--ratelimit
    exit /b 1

::: "Volume info or edit" "" "usage: %~n0 vol [option] [...]" "" "    --free-letter,   -ul [[var_name]]           Get Unused Device Id" "    --change-letter, -xl [letter1:] [letter2:]  [DANGER^^^!] Change or exchange letters, need reboot system" "    --remove-letter, -rl [letter:]              [DANGER^^^!] Remove letter, need reboot system" "    --letters,       -li [var_name] [[l/r/n]]   Get Device IDs" "    --desc-letters,  -dl [var_name] [[l/r/n]]   Get Device IDs DESC" "                  ([l/r/n]: []no param view all / [l]ocal Fixed Disk, CD-[R]OM Disc / [N]etwork Connection)" "" "    --encrypts,       -ec   [letter:] [pw/vol]  Encrypts the volume by bitlocker" "    --decrypts,       -dc   [letter:/passwd]    Decrypts the volume" "    --encrypts-all,   -eca  [--safe] [letter:]  Encrypts all volumes by bitlocker, need removable drive" "                  ([--safe]: Deny write access to fixed and removable drives not protected by BitLocker)" "                                                not protected by BitLocker" "" "    --hide-bitlocker, -hb                       Hide bitlocker feature, [DANGER^^^!] This is an irreversible operation" "    --crypts-status,  -cs   [letter:]           Provides information about BitLocker-capable volumes" "                            [[--more/-m]]       display more crypts info" "" "    --wipes,     -w   [letter:]                 Wipes the free space on the volume" "    --trim,      -t   [letter:]                 Trim SSD, HDD will return false" ""
:::: "invalid option" "variable name is empty" "type command not support" "The first parameter is empty" "Target path not found" "target not a letter or not support" "reg error" "letter not found" "Partition not found" "not support winpe" "removable drive not found or read-only" "operating system version not support" "manage-bde error" "manage-bde feature not enable" "args error" "nothing to do"
:lib\vol
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\vol\%*
    goto :eof

:this\vol\--free-letter
:this\vol\-ul
    setlocal enabledelayedexpansion
    set _di=zyxwvutsrqponmlkjihgfedcba
    for /f "usebackq skip=1 delims=:" %%a in (
        `wmic.exe logicaldisk get DeviceID`
    ) do set _di=!_di:%%a=!
    endlocal & if "%~1"=="" (
        echo.%_di:~0,1%:
    ) else set %~1=%_di:~0,1%:
    exit /b 0

:this\vol\--change-letter
:this\vol\-xl
    if "%~2"=="" exit /b 6
    if /i "%~1" neq "%~d1" exit /b 6
    if /i "%~2" neq "%~d2" exit /b 6
    if /i "%~d1"=="%SystemDrive%" exit /b 6
    if /i "%~d2"=="%SystemDrive%" exit /b 6
    setlocal enabledelayedexpansion
    set _%~d1=
    set _%~d2=
    call :regedit\on
    for /f "usebackq tokens=1,3" %%a in (
        `reg.exe query HKLM\SYSTEM\MountedDevices /v \DosDevices\*`
    ) do (
        if /i "%%~a"=="\DosDevices\%~d1" set "_%~d1=%%~b"
        if /i "%%~a"=="\DosDevices\%~d2" set "_%~d2=%%~b"
    )
    if not defined _%~d1 exit /b 6
    if defined _%~d2 (
        >&2 echo will exchange %~d1 with %~d2
        reg.exe add HKLM\SYSTEM\MountedDevices /v "\DosDevices\%~d1" /t REG_BINARY /d !_%~d2! /f || (
            call :regedit\off
            exit /b 7
        )
    ) else (
        >&2 echo will change %~d1 to %~d2
        reg.exe delete HKLM\SYSTEM\MountedDevices /v "\DosDevices\%~d1" /f || (
            call :regedit\off
            exit /b 7
        )
    )
    reg.exe add HKLM\SYSTEM\MountedDevices /v "\DosDevices\%~d2" /t REG_BINARY /d !_%~d1! /f || (
        call :regedit\off
        exit /b 7
    )
    call :regedit\off
    >&2 echo.
    >&2 echo Need reboot system.
    endlocal
    exit /b 0

:this\vol\--remove-letter
:this\vol\-rl
    if /i "%~1"=="" exit /b 6
    if /i "%~1" neq "%~d1" exit /b 6
    if /i "%~d1"=="%SystemDrive%" exit /b 6
    setlocal enabledelayedexpansion
    call :regedit\on
    for /f "usebackq tokens=1,3" %%a in (
        `reg.exe query HKLM\SYSTEM\MountedDevices /v \DosDevices\*`
    ) do if /i "%%~a"=="\DosDevices\%~d1" (
        reg.exe delete HKLM\SYSTEM\MountedDevices /v "%%~a" /f || (
            call :regedit\off
            exit /b 7
        )
        call :this\uuid _uuid
        reg.exe add HKLM\SYSTEM\MountedDevices /v #{!_uuid!} /t REG_BINARY /d %%b /f || (
            call :regedit\off
            exit /b 7
        )
        >&2 echo.
        >&2 echo Need reboot system.
        call :regedit\off
        exit /b 0
    )
    call :regedit\off
    endlocal
    exit /b 8

REM mini uuid creater
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

:this\vol\--letters
:this\vol\-li
:this\vol\--desc-letters
:this\vol\-dl
    :::::::::::::::::::::::::::::::::::::::
    :: [WARNING] Not support nano server ::
    :::::::::::::::::::::::::::::::::::::::
    if "%~1"=="" exit /b 2
    set _var=
    setlocal enabledelayedexpansion
    set _desc=
    REM Test sort
    for %%a in (%0) do if "%%~na" neq "--letters" if "%%~na" neq "-li" set _desc=1
    REM add where conditions
    if "%~2" neq "" (
        set _DriveType=
        if /i "%~2"=="l" set _DriveType=3
        if /i "%~2"=="r" set _DriveType=5
        if /i "%~2"=="n" set _DriveType=4
        if not defined _DriveType exit /b 3
        set "_DriveType=where DriveType^^=!_DriveType!"
    )
    REM main
    for /f "usebackq skip=1 delims=:" %%a in (
        `wmic.exe logicaldisk %_DriveType% get DeviceID`
    ) do if defined _desc (
        set "_var=%%a !_var!"
    ) else set "_var=!_var! %%a"
    if defined _var set _var=%_var:~1,-2%
    endlocal & set %~1=%_var%
    exit /b 0

:this\vol\--hide-bitlocker
:this\vol\-hb

    setlocal enabledelayedexpansion
    call :regedit\on
    REM right-mouse menu
    for %%a in (
        encrypt-bde encrypt-bde-elev
        manage-bde
        resume-bde resume-bde-elev
        unlock-bde
    ) do >nul 2>nul reg.exe delete HKCR\Drive\shell\%%a /f

    REM control panel
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

    REM drive ico
    for /f "usebackq tokens=1-3" %%a in (
        `wmic.exe logicaldisk get DeviceID^,DriveType`
    ) do if "%%b"=="3" (
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

:this\vol\--encrypts-all
:this\vol\-eca
    for %%a in (manage-bde.exe) do if "%%~$path:a"=="" exit /b 14
    if /i "%username%"=="System" exit /b 10
    call :this\oset\--vergeq 10.0 || exit /b 12

    setlocal
    set _tmp_letter=
    if /i "%~1"=="%~d1" (
        if exist "%~1" set _tmp_letter=%~d1
    ) else if /i "%~2"=="%~d2" if exist "%~2" set _tmp_letter=%~d2

    set _removable_letter=
    if defined _tmp_letter (
        for /f "usebackq tokens=1-3" %%a in (
            `wmic.exe logicaldisk get DeviceID^,DriveType`
        ) do if /i "%%a%%b"=="%_tmp_letter%2" set _removable_letter=%%a

    ) else for /f "usebackq tokens=1-4" %%a in (
        `wmic.exe logicaldisk get Access^,DeviceID^,DriveType`
    ) do if "%%a%%c"=="02" set _removable_letter=%%b

    if not defined _removable_letter exit /b 11

    >&3 echo find removable drives '%_removable_letter%'

    2>nul mkdir %_removable_letter%\keys
    set /a _suf=%random% %% 900 + 100
    call :this\str\--now _log %_removable_letter%\keys\key- %_suf%.log
    >>%_log% (
        echo.
        echo =====================================================================================================
        echo %date% %time%
        echo.
        call :this\drv\--info
    )

    call :regedit\on
    REM get allow - gpedit.msc: Local Computer Policy - Computer Configuration - Administrative Templates - Windows Components - BitLocker Drive Encryption - Operating System Drives
    for %%a in (
        "UseAdvancedStartup /t REG_DWORD /d 1"
        "EnableBDEWithNoTPM /t REG_DWORD /d 1"
        "UseTPM /t REG_DWORD /d 2"
        "UseTPMPIN /t REG_DWORD /d 0"
        "UseTPMKey /t REG_DWORD /d 2"
        "UseTPMKeyPIN /t REG_DWORD /d 0"
    ) do >nul reg.exe add HKLM\Software\Policies\Microsoft\FVE /v %%~a /f

    REM allow removable drives write access
    >nul 2>nul reg.exe delete HKLM\System\CurrentControlSet\Policies\Microsoft\FVE ^
        /v RDVDenyWriteAccess /f && >&3 echo [WARN] Try to re insert removable drives

    REM start lock
    for /f "usebackq tokens=1-3" %%a in (
        `wmic.exe logicaldisk get DeviceID^,DriveType`
    ) do if "%%b"=="3" >>%_log% (
        if not exist %_removable_letter% (
            call :regedit\off
            exit /b 10
        )
        call :this\vol\--crypts-status %%a && (
            >&3 echo Skip encrypt '%%a'
        ) || call :bitLocker\on\key %%a %_removable_letter% || (
            call :regedit\off
            exit /b %errorlevel%
        )
    )

    attrib.exe -s -h -r %_removable_letter%\*.bek
    for /d %%a in (
        %_removable_letter%\keys\*
    ) do attrib.exe -s -h -r %%a\*.bek

    if "%~1" neq "--safe" if "%~1" neq "-s" goto :skip\deny_write_access
    call :oset\write_access\--deny
    :skip\deny_write_access

    call :regedit\off
    endlocal

    echo.
    exit /b 0

:this\vol\--encrypts
:this\vol\-ec
    for %%a in (manage-bde.exe) do if "%%~$path:a"=="" exit /b 14
    if /i "%username%"=="System" exit /b 10
    if /i "%~1" neq "%~d1" exit /b 6
    if "%~2"=="" exit /b 15
    if not exist "%~1" exit /b 8
    call :this\vol\--crypts-status %~d1 && (
        echo [%~d1] already encrypts.
        exit /b 0
    )

    if /i "%~2"=="%~d2" if exist "%~2" call :bitLocker\on\key %~d1 %~d2& goto :eof

    manage-bde.exe -on %~d1 ^
                -UsedSpaceOnly ^
                -Synchronous ^
                -Password %~2 || exit /b 13
    goto :eof

:this\vol\--decrypts
:this\vol\-dc
    for %%a in (manage-bde.exe) do if "%%~$path:a"=="" exit /b 14
    if /i "%username%"=="System" exit /b 10
    if not exist "%~1" exit /b 8

    REM not test crypts status at here
    if /i "%~d1" neq "%SystemDrive%" call :this\vol\--crypts-status %SystemDrive% && goto skip\allow_write_access
    call :this\oset\--unsecure-write --allow
    :skip\allow_write_access

    REM manage-bde.exe -autounlock -ClearAllKeys Volume
    manage-bde.exe -off %~d1 || exit /b 13
    exit /b 0

REM for ':this\vol\--encrypts-all', ':this\vol\--encrypts'
:bitLocker\on\key
    echo.
    echo.
    >&3 echo Encryption [%~d1] ...
    title Encryption [%~d1] ...

    setlocal
    set _vol=%~d1
    set _vol=%_vol::=%
    REM call :test\tpm
    set _arg=-StartupKey %~d2\
    if /i "%~d1" neq "%SystemDrive%" (
        2>nul mkdir %~d2\keys\%_vol%
        set _arg=-RecoveryKey %~d2\keys\%_vol%
    )

    manage-bde.exe ^
        -on %_vol%: ^
        -UsedSpaceOnly ^
        -EncryptionMethod xts_aes128 %_arg% ^
        -SkipHardwareTest || exit /b 13

    if /i "%~d1" neq "%SystemDrive%" manage-bde.exe -autounlock -enable %_vol%: || exit /b 13

    endlocal
    exit /b 0

:this\vol\--crypts-status
:this\vol\-cs
    for %%a in (manage-bde.exe) do if "%%~$path:a"=="" exit /b 14
    if "%~1"=="" exit /b 6
    if /i "%~1" neq "%~d1" exit /b 6

    if "%~2" neq "--more" if "%~2" neq "-m" goto skip\show_crypts_status
    manage-bde.exe -status %~d1
    exit /b 0
    :skip\show_crypts_status

    >nul manage-bde.exe -status %~d1 -ProtectionAsErrorLevel && exit /b 0
    exit /b 30

REM Trusted Platform Module (TPM)
:test\tpm
    2>nul PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command Get-TpmSupportedFeature && exit /b 0
    exit /b 1

:this\vol\--wipes
:this\vol\-w
    REM TODO mount directory
    if "%~1"=="" exit /b 5
    if /i "%~1" neq "%~d1" exit /b 5
    if not exist %~d1 exit /b 5
    call :this\vol\--crypts-status %~d1 && (
        manage-bde.exe -WipeFreeSpace %~d1
    ) || cipher.exe /w:%~d1
    goto :eof

:this\vol\--trim
:this\vol\-t
    REM TODO mount directory
    if "%~1"=="" exit /b 30
    if /i "%~1" neq "%~d1" exit /b 30
    if not exist "%~1" exit /b 30
    for /f "usebackq" %%a in (
        `defrag.exe %~d1 /l 2^>&1`
    ) do for %%b in (
        %%~a
    ) do if /i "%%b"=="(0x8900002A)" exit /b 0
    exit /b 30

::: "Uncompress package" "" "usage: %~n0 un [target_path]"
:::: "Format not supported" "Target not found" "System version is too old" "chm file not found" "not chm file" "out put file allready exist" "file format not msi" "cabarc.exe file not found"
:lib\un
    call :this\un\%~x1 %1
    goto :eof

:this\un\.cab
    mkdir ".\%~n1"
    expand.exe %1 -F:* ".\%~n1"
    REM for %%a in (cabarc.exe) do if "%%~$path:a"=="" exit /b 8
    REM pushd %cd%
    REM mkdir ".\%~n1" && chdir /d ".\%~n1" && cabarc.exe x %1 *
    REM popd
    exit /b 0

:this\un\.zip
    if not exist "%~1" exit /b 2
    setlocal
    set "_output=.\%~n1"
    if "%~2" neq "" set "_output=%~2"
    call :lib\vbs unzip "%~f1" "%_output%"
    endlocal
    exit /b 0

:this\un\.exe
    if not exist "%~1" exit /b 2
    call :this\oset\--vergeq 10.0 || exit /b 3
    compact.exe /u /exe /a /i /q /s:"%~f1"
    exit /b 0

REM "Uncompress chm file"
:this\un\.chm
    if not exist "%~1" exit /b 4
    if /i "%~x1" neq ".chm" exit /b 5
    if exist ".\%~sn1" exit /b 6
    start /wait hh.exe -decompile .\%~sn1 %~s1
    exit /b 0

REM "Uncompress msi file"
:this\un\.msi
    if not exist "%~1" exit /b 2
    if /i "%~x1" neq ".msi" exit /b 7
    2>nul mkdir ".\%~n1" || exit /b 6
    setlocal
    REM Init
    call :this\vol\--free-letter _letter
    subst.exe %_letter% ".\%~n1"

    REM Uncompress msi file
    start /wait msiexec.exe /a %1 /qn targetdir=%_letter%
    erase "%_letter%\%~nx1"
    REM for %%a in (".\%~n1") do echo output: %%~fa

    subst.exe %_letter% /d
    endlocal
    exit /b 0


::: "Compresses the specified files." "" "usage: %~n0 pkg [option]" "" "    --zip, -z  [source_path] [[target_path]]  make zip" "    --cab, -c  [targe_path]                   make cab" "    --udf, -u  [dir_path]                     Create iso file from directory" "    --exe, -e  [source_path]                  Use compression optimized for executable files " "                                              which are read frequently and not modified."
:::: "invalid option" "target not directory" "not support driver" "need etfsboot.com or efisys.bin"
:lib\pkg
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\pkg\%*
    goto :eof

:this\pkg\--zip
:this\pkg\-z
    setlocal
    set "_output=.\%~n1"
    if "%~2" neq "" set "_output=%~2"
    if /i "%~x1" neq ".zip" call :lib\vbs zip "%~f1" "%_output%.zip"
    endlocal
    REM >.\zip.ZFSendToTarget (
    REM     echo [Shell]
    REM     echo Command=2
    REM     echo IconFile=explorer.exe,3
    REM     echo [Taskbar]
    REM     echo Command=ToggleDesktop
    REM )
    goto :eof

:this\pkg\--cab
:this\pkg\-c
    for %%a in (cabarc.exe) do if "%%~$path:a"=="" exit /b 8
    REM By directory
    if "%~2"=="" call :this\dir\--isdir %1 ^
        && cabarc.exe -m LZX:21 n ".\%~n1.tmp" "%~1\*"

    REM By file
    call :this\dir\--isdir %1 ^
        || cabarc.exe -m LZX:21 n ".\%~n1.tmp" %*

    if exist ".\%~n1.tmp" rename ".\%~n1.tmp" "%~n1.cab"
    goto :eof

:this\pkg\--udf
:this\pkg\-u
    for %%a in (oscdimg.exe) do if "%%~$path:a"=="" >nul call :init\oscdimg
    call :this\dir\--isdir %1 ||  exit /b 2
    if /i "%~d1\"=="%~1" exit /b 3

    REM empty name
    if "%~n1"=="" (
        setlocal enabledelayedexpansion
        set _args=%~1
        if "!_args:~-1!" neq "\" (
            call :this\var\--set-errorlevel 3
        ) else call %0 "!_args:~0,-1!"
        endlocal & goto :eof
    )

    if exist "%~1\sources\boot.wim" (
        REM winpe iso
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 4
        if not exist %windir%\Boot\DVD\EFI\en-US\efisys.bin exit /b 4
        REM echo El Torito udf %~nx1
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
        REM winxp iso
        REM echo El Torito %~nx1
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 4
        oscdimg.exe ^
            -b%windir%\Boot\DVD\PCAT\etfsboot.com ^
                -k ^
                -l"%~nx1" ^
                -m ^
                -n ^
                -o ^
                -w1 %1 ".\%~nx1.tmp"
    ) else (
        REM normal iso
        REM echo oscdimg udf
        oscdimg.exe -l"%~nx1" -o -u2 -udfver102 %1 ".\%~nx1.tmp"
    )
    rename "./%~nx1.tmp" "*.iso"
    exit /b 0

:this\pkg\--exe
:this\pkg\-e
    compact.exe /c /exe /a /i /q /s:"%~f1"
    goto :eof


REM from Window 10 aik, will download oscdimg.exe at script path
:init\oscdimg
    for %%a in (_%0) do if %processor_architecture:~-2%==64 (
        REM amd64
        call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk ^
            bbf55224a0290f00676ddc410f004498 ^
            fild40c79d789d460e48dc1cbd485d6fc2e
    REM x86
    ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk ^
                    5d984200acbde182fd99cbfbe9bad133 ^
                    fil720cc132fbb53f3bed2e525eb77bdbc1
    exit /b 0

REM for :init\?, printf cab | md5sum -> 16ecfd64-586e-c6c1-ab21-2762c2c38a90
:this\getCab [file_name] [uri_sub] [cab] [file]
    2>nul mkdir %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90
    call :lib\download ^
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

::: "Change file/directory owner !username!" "" "usage: %~n0 own [path]"
:::: "path not found"
:lib\own
    if not exist "%~1" exit /b 1
    call :this\dir\--isdir %1 ^
        && takeown.exe /f %1 /r /d y ^
            && icacls.exe %1 /grant:r %username%:f /t /q

    call :this\dir\--isdir %1 ^
        || takeown.exe /f %1 ^
            && icacls.exe %1 /grant:r %username%:f /q

    exit /b 0

::::::::::::::::
:: PowerShell ::
::::::::::::::::

::: "Download something" "" "usage: %~n0 download [url] [output]"
:::: "url is empty" "output path is empty" "powershell version is too old" "download error"
:lib\download
    if "%~2"=="" exit /b 2
    REM certutil.exe -urlcache -split -f %1 %2
    REM windows 10 1803+
    for %%a in (curl.exe) do if "%%~$path:a" neq "" curl.exe -L --retry 10 -o %2 %1 && exit /b 0
    call :this\psv
    if errorlevel 3 PowerShell.exe ^
                        -NoLogo ^
                        -NonInteractive ^
                        -ExecutionPolicy Unrestricted ^
                        -Command "Invoke-WebRequest -uri %1 -OutFile %2 -UseBasicParsing" && exit /b 0

    call :lib\vbs get %1 %2 || exit /b 4
    exit /b 0

::: "Boot tools" "" "usage: %~n0 boot [option] [args...]" "" "    --file,    -f  [letter:]     Copy Window PE boot file from CDROM" "    --legacy,  -g  [[letter:]]   Set the old boot menu style" "    --winre,   -r  [file_path]   Setting Up recovery startup mirrors" "    --winpe,   -p  [file_path]   Create WinPE boot Menu" "    --rebuild, -rb [[letter:]]   Rebuilding the System boot Menu"
:::: "invalid option" "target_letter not exist" "Window PE CDROM not found" "target not found" "not wim file" "wim file must put in some directory"
:lib\boot
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\boot\%*
    goto :eof

:this\boot\--legacy
:this\boot\-g
    if "%~1"=="" (
        bcdedit.exe /set {default} bootmenupolicy legacy
    ) else (
        if exist "%~1" (
            bcdedit.exe /store "%~f1" /set {default} bootmenupolicy legacy
        ) else exit /b 4
    )
    goto :eof

:this\boot\--file
:this\boot\-f
    if not exist "%~d1" exit /b 2
    for /l %%a in (0,1,9) do if exist \\?\CDROM%%a\boot\boot.sdi (
        REM for macOS
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

        REM copy /y \\?\CDROM%%a\sources\sxs\* %~d1\sources\sxs
        exit /b 0
    )
    exit /b 3

REM error
:this\boot\--winre
:this\boot\-r
    if not exist "%~1" exit /b 4
    if /i "%~x1" neq ".wim" exit /b 5
    if "%~p1"=="\" exit /b 6
    reagentc.exe /disable
    reagentc.exe /setreimage /path "%~1"
    reagentc.exe /enable
    reagentc.exe /info
    REM attrib.exe +s +h +r "%~dp1" /d /s
    bcdedit.exe /set {default} bootmenupolicy legacy
    goto :eof

:this\boot\--winpe [wim]
:this\boot\-p
    if not exist "%~2" exit /b 4
    copy /y %windir%\Boot\DVD\PCAT\boot.sdi "%~dp1"
    2>nul mkdir %~d1\boot

    REM REM winpe boot from disk
    REM bcdedit.exe /createstore %~d1\boot\bcd
    REM bcdedit.exe /store %~d1\boot\bcd /create {bootmgr} /d "Boot Manager"
    REM bcdedit.exe /store %~d1\boot\bcd /set {bootmgr} device boot
    REM for /f "tokens=2 delims={}" %%a in (
    REM     'bcdedit.exe /store %~d1\boot\BCD /create /d "WINPE" /application osloader'
    REM ) do set GUID=%%a
    REM set GUID=%GUID:~0,-7%
    REM for %%c in (
    REM     "/set {%GUID%} osdevice boot"
    REM     "/set {%GUID%} device boot"
    REM     "/set {%GUID%} path \windows\system32\boot\winload.exe"
    REM     "/set {%GUID%} systemroot \windows"
    REM     "/set {%GUID%} winpe yes"
    REM     "/displayorder {%GUID%} /addlast"
    REM ) do bcdedit.exe /store %~d1\boot\bcd %%~c

    for /f "tokens=2 delims={}" %%a in (
        `bcdedit.exe /store "%~d1\boot\bcd" /create /d "winpe" /device`
    ) do for /f "tokens=2 delims={}" %%b in (
        `bcdedit.exe /store "%~d1\boot\bcd" /create /d "Windows Preinstallation or Recovery Environment" /application osloader`
    ) do for %%c in (
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

REM new boot


:this\boot\--is-vhd-os
    >nul chcp 437
    for /f "usebackq tokens=1*" %%a in (
        `bcdedit.exe /v /enum {current}`
    ) do if .%%a==.osdevice for /f "tokens=2,3 delims=[,=]" %%c in (
        "%%b"
    ) do if %%d. neq . if exist "%%c%%d" (
        if /i .%%~xd neq ..vhd exit /b 0
        if /i .%%~xd neq ..vhdx exit /b 0
    )
    exit /b 30

:this\boot\--rebuild
:this\boot\-rb
    goto :eof

::: "Add or Remove Web Credential" "" "usage: %~n0 crede [option] [args...]" "" "    --add,    -a [user]@[ip or host] [[password]]" "    --remove, -r [ip or host]"
:::: "invalid option" "parameter not enough" "Command error" "ho ip or host"
:lib\crede
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\crede\%*
    goto :eof

:this\crede\--add
:this\crede\-a
    if "%~1"=="" exit /b 2
    setlocal
    set _prefix=
    set _suffix=
    for /f "usebackq tokens=1* delims=@" %%a in (
        '%~1'
    ) do set _prefix=%%a& set _suffix=%%b

    if not defined _suffix exit /b 4

    REM Clear Credential
    >nul call :this\crede\-r %_suffix%

    set _arg=
    if "%~2" neq "" set _arg=/pass:%~2
    REM Add credential
    echo cmdkey.exe /add:%_suffix% /user:%_prefix% %_arg%
    >nul cmdkey.exe /add:%_suffix% /user:%_prefix% %_arg% || exit /b 3
    endlocal
    exit /b 0

:this\crede\--remove
:this\crede\-r
    if "%~1"=="" exit /b 2
    cmdkey.exe /delete:%~1
    exit /b 0


::: "Mount / Umount SMB" "" "usage: %~n0 smb [option] [args...]" "" "    --mount,     -m  [ip or hosts] [path...]   Mount SMB" "    --umount,    -u  [ip or --all]             Umount SMB" "    --umountall, -ua                           Umount all SMB"
:::: "invalid option" "parameter not enough" "Command error"
:lib\smb
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\smb\%*
    goto :eof

:this\smb\--mount
:this\smb\-m
    if "%~2"=="" exit /b 2
    for %%a in (%2 %3 %4 %5 %6 %7 %8 %9) do net.exe use * "\\%~1\%%~a" /savecred /persistent:yes || exit /b 3
    exit /b 0

:this\smb\--umount
:this\smb\-u
    if "%~1"=="" exit /b 2
    for /f "usebackq tokens=2,3" %%a in (`net.exe use`) do if "%%~pb"=="%~1\" net.exe use %%a /delete
    exit /b 0

:this\smb\--umountall
:this\smb\-ua
    net.exe use * /delete /y
    exit /b 0

::: "Mount / Umount NFS" "" "usage: %~n0 nfs [option] [args...]" "    --mount,  -m [ip]    Mount NFS" "    --umount, -u         Umount all NFS"
:::: "invalid option" "parameter is empty" "{UNUSE}" "parameter not a ip" "can not connect remote host"
:lib\nfs
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\nfs\%*
    exit /b 0

:this\nfs\--mount
:this\nfs\-m
    if "%~1"=="" exit /b 2
    call :this\ip\--test %~1 || exit /b 4
    >nul 2>nul ping.exe -n 1 -l 16 -w 100 %~1 || exit /b 5
    if not exist %windir%\system32\mount.exe call :nfs\initNfs
    for /f "usebackq skip=1" %%a in (
        `showmount.exe -e %~1`
    ) do mount.exe -o mtype=soft lang=ansi nolock \\%~1%%a *
    exit /b 0

:this\nfs\--umount
:this\nfs\-u
    if not exist %windir%\system32\umount.exe call :nfs\initNfs
    for /f "usebackq tokens=1,3 delims=:\" %%a in (
        `mount.exe`
    ) do umount.exe -f %%a:
    exit /b 0

REM Enable ServicesForNFS
:nfs\initNfs
    for %%a in (
        AnonymousUid AnonymousGid
    ) do reg.exe ^
            add HKLM\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default ^
                /v %%a ^
                /t REG_DWORD /d 0 /f

    call :this\oset\--feature-enable ^
            ServicesForNFS-ClientOnly; ^
            ClientForNFS-Infrastructure; ^
            NFS-Administration

    REM start /w Ocsetup.exe ServicesForNFS-ClientOnly;ClientForNFS-Infrastructure;NFS-Administration /norestart
    exit /b 0

:::::::::
:: vhd ::
:::::::::

::: "Virtual Hard Disk manager" "" "usage: %~n0 vhd [option] [args...]" "" "    --new,    -n  [new_vhd_path] [size[GB]] [[mount letter or path]]" "                                                       Creates a virtual disk file." "" "    --mount,  -m  [vhd_path] [[letter:]]                Mount vhd file" "    --umount, -u  [vhd_path]                           Unmount vhd file" "    --expand, -e  [vhd_path] [GB_size]                 Expands the maximum size available on a virtual disk." "    --differ, -d  [new_vhd_path] [source_vhd_path]     Create differencing vhd file by an existing virtual disk file" "    --merge,  -me [chile_vhd_path] [[merge_depth]]     Merges a child disk with its parents"
REM  "    --rec,    -r                                       Recovery child vhd if have parent" "" "e.g." "    %~n0 vhd -n E:\nano.vhdx 30 V:"
:::: "invalid option" "file suffix not vhd/vhdx" "file not found" "no volume find" "vhd size is empty" "letter already use" "diskpart error:" "not a letter or path" "{UNUSE}" "size not num" "parent vhd not found" "new file allready exist"
:lib\vhd
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\vhd\%*
    goto :eof

:this\vhd\--new
:this\vhd\-n
    if "%~1"=="" exit /b 3
    if not exist "%~dp1" exit /b 4
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    if "%~2"=="" exit /b 5
    if "%~3" neq "" (
        if /i "%~d3"=="%~3" if exist "%~d3" exit /b 6
        if /i "%~d3" neq "%~3" if not exist "%~3" exit /b 8
    )
    REM make vhd
    call set /a _size=%2 * 1024 + 8
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
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    >&3 echo complete.
    exit /b 0

:this\vhd\--mount
:this\vhd\-m
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    if "%~2" neq "" (
        if /i "%~d2"=="%~2" if exist "%~2" exit /b 6
        if /i "%~d2" neq "%~2" if not exist "%~2" exit /b 8
    )
    (
        echo select vdisk file="%~f1"
        echo attach vdisk
        if "%~2" neq "" (
            echo select partition 1
            REM skip error
            echo remove all noerr
            if /i "%~d2"=="%~2" (
                echo assign letter=%~2
            ) else echo assign mount="%~f2"
        )
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    >&3 echo complete.
    exit /b 0

:this\vhd\--umount
:this\vhd\-u
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    REM unmount vhd
    (
        echo select vdisk file="%~f1"
        echo detach vdisk
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    >&3 echo complete.
    exit /b 0

:this\vhd\--expand
:this\vhd\-e
    if not exist "%~1" exit /b 3
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 2
    call :this\is\--integer %~2 || exit /b 30
    REM unmount vhd
    call :lib\vumount %1 > nul
    setlocal
    set /a _size=%~2 * 1024 + 8
    (
        echo select vdisk file="%~f1"
        echo expand vdisk maximum=%_size%
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    endlocal
    exit /b 0

:this\vhd\--differ
:this\vhd\-d
    if not exist "%~2" exit /b 11
    if exist "%~1" exit /b 12
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 2
    echo create vdisk file="%~f1" parent="%~f2" | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    >&3 echo complete.
    exit /b 0

:this\vhd\--merge
:this\vhd\-me
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    setlocal
    call set _depth=1
    if "%~2" neq "" set _depth=%~2
    (
        echo select vdisk file="%~f1"
        echo merge vdisk depth=%_depth%
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    >&3 echo complete.
    endlocal
    exit /b 0

::::::::::
:: dism ::
::::::::::

::: "Wim manager" "" "usage: %~n0 wim [option] [args ...]" "" "    --info,   -i [image_path]                                Displays information about images in a WIM file." "    --new,    -n [[compress level]] [target_dir_path] [[image_name]]" "                                                             Capture file/directory to wim" "                                                      [WARN] if target path tail without '\', root path is parent directory" "" "    --apply,  -a [wim_path] [[output_path] [image_index]]    Apply WIM file" "    --mount,  -m [wim_path] [mount_path] [[image_index]]     Mount wim" "    --umount, -u [mount_path]                                Unmount wim" "    --commit, -c [mount_path]                                Unmount wim with commit" "    --export, -e [source_wim_path] [target_wim_path] [image_index] [[compress_level]]    Export wim image" "                                   compress level: 0:none, 1:WIMBoot, 2:fast, 3:max, 4:recovery(esd)" "" "    --umountall, -ua                                         Unmount all wim" "    --rmountall, -ra                                         Recovers mount all orphaned wim"
:::: "invalid option" "SCRATCH_DIR variable not set" "dism version is too old" "target not found" "need input image name" "dism error" "wim file not found" "not wim file" "output path allready use" "output path not found" "Not a path" "Target wim index not select" "compress level error"
:lib\wim
    if "%~1"=="" call :this\annotation %0 & goto :eof
    if /i "%username%"=="System" if not defined SCRATCH_DIR exit /b 2
    2>nul mkdir %temp% %tmp%
    setlocal
    if /i "%username%" neq "System" set scratch_dir=
    if defined scratch_dir set "scratch_dir=/ScratchDir:%scratch_dir:/ScratchDir:=%"
    call :this\wim\%*
    endlocal
    goto :eof

:this\wim\--new
:this\wim\-n
    call :this\oset\--vergeq 6.3 || exit /b 3

    setlocal enabledelayedexpansion
    call :this\is\--integer %~1 && call :wim\setCompress %~1 && shift

    if not exist "%~1" exit /b 4
    if "%~d1\"=="%~f1" if "%~2"=="" exit /b 5

    set _enable_export=
    if /i "%_compress_args%"=="/Compress:recovery" (
        set _compress_args=/Compress:fast
        set _enable_export=ture
    )

    set _is_root=
    set "_input=%~f1"
    REM trim path
    if "%_input:~-1%"=="\" set _is_root=true& set "_input=%_input:~0,-1%"

    REM wim name
    if "%~2" neq "" (
        set _name=%~2
    ) else for %%a in ("%_input%") do set "_name=%%~nxa"

    REM New or Append
    if exist ".\%_name%.wim" (set _create=Append) else set _create=Capture

    call :this\str\--now _conf "%tmp%\" .ini
    set _args=
    set _description=
    set _load_point=HKLM\load-point%random%
    REM Create exclusion list

    REM TODO: bug: ()
    if exist "%_input%\Windows\System32\config\SYSTEM" (
        >%_conf% call :this\txt\--subtxt "%~f0" wim.ini 3000
        set _args=/ConfigFile:"%_conf%"

        call :regedit\on
        REM /Description:Description
        REM [WARN] Windows 10 have ReleaseId
        >nul reg.exe load %_load_point% "%_input%\Windows\System32\config\SOFTWARE" && for /f "usebackq skip=1 tokens=2*" %%a in (
            `reg.exe query "%_load_point%\Microsoft\Windows NT\CurrentVersion" /v ProductName`
        ) do if "%%a"=="REG_SZ" for /f "usebackq skip=1 tokens=2*" %%c in (
            `reg.exe query "%_load_point%\Microsoft\Windows NT\CurrentVersion" /v ReleaseId`
        ) do if "%%c"=="REG_SZ" set _description=/Description:"%%b %%d"
        >nul reg.exe unload %_load_point%
        call :regedit\off

    ) else if defined _is_root (
        echo.
        echo root path: '%_input%'
    ) else (
        >%_conf% call :wim\ConfigFile "%_input%" && set _args=/ConfigFile:"%_conf%"
        REM input args
        for %%a in ("%_input%") do set "_input=%%~dpa"
        set "_input=!_input:~0,-1!"
        echo.
        echo root path: '!_input!'
    )

    REM Do capture
    dism.exe /%_create%-Image ^
        /ImageFile:".\%_name%.wim" ^
        /CaptureDir:"%_input%" ^
        /Name:"%_name%" %_description% %_compress_args% ^
        /Verify %_args% %scratch_dir% || exit /b 6

    if exist "%_conf%" erase "%_conf%"

    call :getWimLastIndex ".\%_name%.wim" _index

    echo new index is: %_index%

    if defined _enable_export dism.exe /Export-Image ^
                                /SourceImageFile:".\%_name%.wim" ^
                                /SourceIndex:%_index% ^
                                /DestinationImageFile:".\%_name%.esd" ^
                                /Compress:recovery ^
                                /CheckIntegrity %scratch_dir% || exit /b 6

    endlocal
    exit /b 0

REM create exclusion list
:wim\ConfigFile
    if not exist "%~1" exit /b 1
    if "%~pnx1"=="\" exit /b 2
    echo [ExclusionList]
    REM parent directory
    for /f "usebackq delims=" %%a in (
        `dir /a /b "%~dp1"`
    ) do if "%%a" neq "%~nx1" echo \%%a
    echo.
    exit /b 0

:this\wim\--apply
:this\wim\-a
    call :this\oset\--vergeq 6.3 || exit /b 3
    if not exist "%~1" exit /b 7
    if /i "%~x1" neq ".wim" if /i "%~x1" neq ".esd" exit /b 8
    setlocal
    set _out=.
    if "%~2" neq "" (
        call :this\dir\--isdir "%~2" || exit /b 30
        set _out=%~f2
    )
    REM Must trim path
    if "%_out:~-1%"=="\" set _out=%_out:~0,-1%
    if "%~3"=="" (
        call :getWimLastIndex %1 _index
    ) else set _index=%~3
    dism.exe /Apply-Image ^
                /ImageFile:"%~f1" ^
                /Index:%_index% ^
                /ApplyDir:"%_out%" ^
                /Verify || exit /b 6

    endlocal
    exit /b 0

REM for wim
:getWimLastIndex
    if "%~2"=="" exit /b 1
    for /f "usebackq tokens=1,3" %%a in (
         `dism.exe /English /Get-WimInfo /WimFile:"%~f1"`
     ) do if "%%a"=="Index" set /a %~2=%%b
    exit /b 0

:this\wim\--mount
:this\wim\-m
    if not exist "%~1" exit /b 7
    if /i "%~x1" neq ".wim" exit /b 8
    call :this\dir\--isdir %2 || exit /b 4
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
                /MountDir:"%~f2" %_arg% %scratch_dir% || exit /b 6

    endlocal
    exit /b 0

:this\wim\--umount
:this\wim\-u
    call :this\dir\--isdir %1 || exit /b 4
    dism.exe /Unmount-Wim ^
                /MountDir:"%~f1" ^
                /discard %scratch_dir% || exit /b 6
    exit /b 0

:this\wim\--commit
:this\wim\-c
    call :this\dir\--isdir %1 || exit /b 4
    dism.exe /Unmount-Wim ^
                /MountDir:"%~f1" ^
                /commit %scratch_dir% || exit /b 6
    exit /b 0

:: 0->4 none|WIMBoot|fast|max|recovery(esd),
:: recovery only support '/Export-Image' option
:wim\setCompress
    set _compress_args=
    if "%~1"=="0" set _compress_args=/Compress:none
    if "%~1"=="1" set _compress_args=/WIMBoot
    if "%~1"=="2" set _compress_args=/Compress:fast
    if "%~1"=="3" set _compress_args=/Compress:max
    if "%~1"=="4" set _compress_args=/Compress:recovery
    if defined _compress_args exit /b 0
    exit /b 1

:this\wim\--export
:this\wim\-e
    if not exist %1 exit /b 7
    if /i "%~x1" neq ".wim" if /i "%~x1" neq ".esd" exit /b 8
    if "%~f2" neq "%~2" exit /b 11
    if /i "%~x2" neq ".wim" if /i "%~x2" neq ".esd" exit /b 8
    if "%~3"=="" exit /b 12
    setlocal

    call :wim\setCompress %~4

    REM test suffix
    if /i "%~x2"==".esd" if defined _compress_args if "%_compress_args:~-8%" neq "recovery" exit /b 13

    REM auto esd
    if /i "%~x2"==".esd" if not defined _compress_args set _compress_args=/Compress:recovery

    REM test size, TODO get image size by index
    2>nul set "_size=%~z1" || exit /b 7
    REM 0x1fffffff = 536870911
    if "%_size:~9,1%"=="" if %_size% lss 536870911 if "%_compress_args%" neq "/WIMBoot" set "_compress_args=%_compress_args% /Bootable"

    dism.exe /Export-Image ^
                /SourceImageFile:"%~f1" ^
                /SourceIndex:%3 ^
                /DestinationImageFile:"%~f2" %_compress_args% ^
                /CheckIntegrity %scratch_dir% || exit /b 6
    endlocal
    exit /b 0

::: "Unmount all wim"
:this\wim\--umountall
:this\wim\-ua
    for /f "usebackq tokens=1-3*" %%a in (
        `dism.exe /English /Get-MountedWimInfo`
    ) do if "%%~a%%~b"=="MountDir" if exist "%%~d" call :this\wim\--umount "%%~d"
    dism.exe /Cleanup-Wim
    exit /b 0

::: "Recovers mount all orphaned wim"
:this\wim\--rmountall
:this\wim\-ra
    setlocal enabledelayedexpansion
    for /f "usebackq tokens=1-3*" %%a in (
        `dism.exe /English /Get-MountedWimInfo`
    ) do (
        if "%%~a"=="Mount" set _mount_dir=
        if "%%~a%%~b"=="MountDir" if exist "%%~d" set "_mount_dir=%%~d"
        if "%%~a%%~d"=="StatusRemount" if defined _mount_dir dism.exe /Remount-Wim /MountDir:"!_mount_dir!" %scratch_dir% || exit /b 6
    )
    endlocal
    echo.complete.
    exit /b 0

::: ""
:this\wim\--info
:this\wim\-i
    if not exist "%~1" exit /b 4
    for /f "usebackq tokens=1,2*" %%b in (
        `dism.exe /English /Get-WimInfo /WimFile:%1`
    ) do if "%%b"=="Index" (
        for /f "usebackq tokens=1,2*" %%f in (
            `dism.exe /English /Get-WimInfo /WimFile:%1 /Index:%%d`
        ) do if "%%h" neq "<undefined>" (
            if "%%f"=="Name" set /p=%%d. "%%h"<nul
            if "%%f"=="Size" call :this\wim\num %%h
            if "%%f%%g%%h"=="WIMBootable: Yes" set /p=, wimboot<nul
            if "%%f"=="Architecture" set /p=, %%h<nul
            if "%%f"=="Version" set /p=, %%h<nul
            if "%%f"=="Edition" set /p=, %%h<nul
            if "%%g"=="(Default)" set /p=, %%f <nul
        )
        echo.
    )
    exit /b 0

:this\wim\num
    setlocal
    set _num=%*
    set /p=, %_num:,=_%<nul
    endlocal
    goto :eof

::: "Drivers manager" "" "usage: %~n0 drv [option] [args...]" "" "    --add,    -a  [os_path] [drv_path ...]      Add drivers offline" "    --list,   -l  [[os_path]]                   Display OS drivers list" "    --remove, -r  [os_path] [[name].inf]        Remove drivers, 3rd party drivers like oem1.inf" "    --get,    -g                                Display hardware ids" "    --filter, -f  [inf_path] [drivers_dir]      Search device *.inf" "    --info,   -v                                Display device info"
:::: "invalid option" "OS path not found" "Not drivers name" "dism error" "drivers info file not found" "drivers path error" "SCRATCH_DIR variable not set"
:lib\drv
    if "%~1"=="" call :this\annotation %0 & goto :eof
    if /i "%username%"=="System" if not defined SCRATCH_DIR exit /b 7
    setlocal
    if /i "%username%" neq "System" set scratch_dir=
    if defined scratch_dir set "scratch_dir=/ScratchDir:%scratch_dir:/ScratchDir:=%"
    call :this\drv\%*
    endlocal
    goto :eof

:this\drv\--info
:this\drv\-v
    echo ;
    for /f "usebackq delims=" %%a in (`
        wmic.exe baseboard get Manufacturer^,Product^,Version ^&
        wmic.exe csproduct get Name^,UUID^,Vendor^,Version ^&
        wmic.exe cpu get Name^,NumberOfCores^,NumberOfLogicalProcessors ^&
        wmic.exe memphysical get MaxCapacity ^&
        wmic.exe diskdrive get Index^,InterfaceType^,Model^,SerialNumber^,Signature^,Size
    `) do echo ; %%~a
    exit /b 0

REM Will install at \Windows\System32\DriverStore\FileRepository
:this\drv\--add
:this\drv\-a
    for %%a in (%*) do call :this\dir\--isdir %1 && (
        dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a /Recurse %scratch_dir% || REM
    ) || if /i "%%~xa"==".inf" dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a %scratch_dir% || exit /b 4
    exit /b 0

:this\drv\--list
:this\drv\-l
    if "%~1" neq "" call :this\dir\--isdir %1 || exit /b 2
    if "%~1"=="" (
        dism.exe /Online /Get-Drivers /all || exit /b 4
    ) else dism.exe /Image:"%~f1" /Get-Drivers /all || exit /b 4
    exit /b 0

:this\drv\--remove
:this\drv\-r
    call :this\dir\--isdir %1 || exit /b 2
    if /i "%~x2" neq ".inf" exit /b 3
    dism.exe /Image:"%~f1" /Remove-Driver /Driver:%~2 %scratch_dir% || exit /b 4
    exit /b 0

REM "Hardware ids manager"
:this\drv\--get
:this\drv\-g
    call :this\var\--in-path devcon.exe || >nul call :init\devcon
    setlocal
    REM Trim Hardware and compatible ids
    for /f "usebackq tokens=1,2" %%a in (
        `devcon.exe hwids *`
    ) do if "%%b"=="" set "_$%%a=$"
    REM Print list
    for /f "usebackq tokens=2 delims==$" %%a in (
        `2^>nul set _$`
    ) do echo %%a
    endlocal
    exit /b 0

:this\drv\--filter
:this\drv\-f
    if not exist "%~1" exit /b 5
    call :this\dir\--isdir %2 || exit /b 6
    REM Create inf trim vbs
    setlocal enabledelayedexpansion
    call :this\str\--now _out %temp%\inf-
    mkdir %_out%
    set i=0
    for /r %2 %%a in (
        *.inf
    ) do (
        set /a i+=1
        REM Cache inf file path
        set _drv\inf\!i!=%%a
        REM trim file in a new path
        call :lib\vbs inftrim "%%~a" %_out%\!i!.tmp
        for %%b in (%_out%\!i!.tmp) do if "%%~zb"=="0" type "%%~a" > %_out%\!i!.tmp
    )
    REM Print hit file
    for /f "usebackq" %%a in (
        `findstr.exe /e /i /m /g:%1 %_out%\*.tmp`
    ) do echo !_drv\inf\%%~na!
    REM Clear temp file
    rmdir /s /q %_out%
    endlocal
    exit /b 0

:this\drv\--extract--env
:this\drv\-ee
    REM \Users\Default
    REM \Users\Default\NTUSER.DAT
    REM \Windows\servicing\Version\!_ver_drv!
    REM \Windows\servicing\Version\!_ver_drv!\amd64_installed
    REM \Windows\servicing\Version\!_ver_drv!\x86_installed
    REM \Windows\System32
    REM \Windows\System32\ntdll.dll
    REM \Windows\System32\SSShim.dll
    REM \Windows\System32\wdscore.dll
    REM \Windows\System32\config
    REM \Windows\System32\config\COMPONENTS 0kb
    REM \Windows\System32\config\DEFAULT    0kb
    REM \Windows\System32\config\DRIVERS
    REM \Windows\System32\config\SAM        0kb
    REM \Windows\System32\config\SECURITY   0kb
    REM \Windows\System32\config\SOFTWARE
    REM \Windows\System32\config\SYSTEM
    REM \Windows\System32\Dism
    REM \Windows\System32\Dism\CbsProvider.dll
    REM \Windows\System32\Dism\CompatProvider.dll
    REM \Windows\System32\Dism\DismCore.dll
    REM \Windows\System32\Dism\DismCorePS.dll
    REM \Windows\System32\Dism\DismHost.exe
    REM \Windows\System32\Dism\DismProv.dll
    REM \Windows\System32\Dism\DmiProvider.dll
    REM \Windows\System32\Dism\FolderProvider.dll
    REM \Windows\System32\Dism\GenericProvider.dll
    REM \Windows\System32\Dism\IBSProvider.dll
    REM \Windows\System32\Dism\ImagingProvider.dll
    REM \Windows\System32\Dism\IntlProvider.dll
    REM \Windows\System32\Dism\LogProvider.dll
    REM \Windows\System32\Dism\OSProvider.dll
    REM \Windows\System32\Dism\PEProvider.dll
    REM \Windows\System32\Dism\SmiProvider.dll
    REM \Windows\System32\Dism\UnattendProvider.dll
    REM \Windows\System32\Dism\VhdProvider.dll
    REM \Windows\System32\Dism\WimProvider.dll
    REM \Windows\System32\Dism\Wow64Provider.dll
    REM \Windows\System32\Dism\en-US
    REM \Windows\System32\Dism\en-US\CbsProvider.dll.mui
    REM \Windows\System32\Dism\en-US\CompatProvider.dll.mui
    REM \Windows\System32\Dism\en-US\DismCore.dll.mui
    REM \Windows\System32\Dism\en-US\DismProv.dll.mui
    REM \Windows\System32\Dism\en-US\DmiProvider.dll.mui
    REM \Windows\System32\Dism\en-US\FolderProvider.dll.mui
    REM \Windows\System32\Dism\en-US\GenericProvider.dll.mui
    REM \Windows\System32\Dism\en-US\IBSProvider.dll.mui
    REM \Windows\System32\Dism\en-US\ImagingProvider.dll.mui
    REM \Windows\System32\Dism\en-US\IntlProvider.dll.mui
    REM \Windows\System32\Dism\en-US\LogProvider.dll.mui
    REM \Windows\System32\Dism\en-US\OSProvider.dll.mui
    REM \Windows\System32\Dism\en-US\PEProvider.dll.mui
    REM \Windows\System32\Dism\en-US\SmiProvider.dll.mui
    REM \Windows\System32\Dism\en-US\UnattendProvider.dll.mui
    REM \Windows\System32\Dism\en-US\VhdProvider.dll.mui
    REM \Windows\System32\Dism\en-US\WimProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!
    REM \Windows\System32\Dism\!_lang_drv!\CbsProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\CompatProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\DismCore.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\DismProv.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\DmiProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\FolderProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\GenericProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\ImagingProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\IntlProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\LogProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\OSProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\PEProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\SmiProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\UnattendProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\VhdProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\WimProvider.dll.mui
    REM \Windows\System32\DriverStore\FileRepository
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\CbsCore.dll
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\DrUpdate.dll
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\drvstore.dll
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\wcp.dll
    goto :eof

REM from Window 10 wdk, will download devcon.exe at script path
:init\devcon
    for %%a in (_%0) do if %processor_architecture:~-2%==64 (
        REM amd64
        call :this\getCab %%~na ^
                    8/1/6/816FE939-15C7-4185-9767-42ED05524A95/wdk ^
                    787bee96dbd26371076b37b13c405890 ^
                    filbad6e2cce5ebc45a401e19c613d0a28f

    REM x86
    ) else call :this\getCab %%~na ^
                    8/1/6/816FE939-15C7-4185-9767-42ED05524A95/wdk ^
                    82c1721cd310c73968861674ffc209c9 ^
                    fil5a9177f816435063f779ebbbd2c1a1d2
    exit /b 0


:::::::::
:: KMS ::
:::::::::

::: "KMS Client" "" "usage: %~n0 kms [option] [args...]" "" "    --os,  -s [[host[:port]]]     Active operating system" "    --odt, -o [[host[:port]]]     Active office, which install by Office Deployment Tool" "    e.g." "        %~n0 kms --os 192.168.1.1" "" "    --all, -a [[host[:port]]]     Active operating system and office"
:::: "invalid option" "ospp.vbs not found" "Need ip or host" "OS not support" "No office found" "office not support" "slmgr.vbs error"
:lib\kms
    title kms
    if "%~1"=="" call :this\annotation %0 & goto :eof
    setlocal
    if "%~2"=="" (
        if "%~d0" neq "\\" exit /b 3
        for /f "usebackq delims=\" %%a in (
            '%~f0'
        ) do set _host=%%a
    ) else set _host=%2

    call :this\private\kms\%*
    endlocal
    goto :eof

REM [WARN] must call from ':lib\kms'
:this\private\kms\--all
:this\private\kms\-a
    call :this\private\kms\--os %*
    call :this\private\kms\--odt %*
    exit /b 0

REM for Operating System, [WARN] must call from ':lib\kms'
:this\private\kms\--os
:this\private\kms\-s
    if not defined _host exit /b 3

    REM Get this OS version
    set _verm10=
    call :oset\this_version_multiply_10 _verm10
    call :regedit\on

    set _currentbuild=
    for /f "usebackq tokens=3" %%a in (
        `reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild`
    ) do set _currentbuild=%%a

    REM Get this OS Edition ID
    set _editionid=
    for /f "usebackq tokens=3" %%a in (
        `reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID`
    ) do set _editionid=%%a

    REM Search kms key
    REM https://technet.microsoft.com/en-us/library/jj612867(v=ws.11).aspx
    REM https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys

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
        EnterpriseSN_100_10240@2F77B-TNFGY-69QQF-B8YKP-D69TJ
        EnterpriseSN_100_14393@QFFDN-GRT3P-VKWWX-X7T3R-8B639
        EnterpriseSN_100_17763@92NFX-8DJQP-P6BBQ-THF9C-7CG2H

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
    ) do for /f "usebackq tokens=1* delims=@" %%a in (
        '%%~k'
    ) do if /i "%_editionid%_%_verm10%"=="%%a" (
        set _gvlk=%%b
    ) else if /i "%_editionid%_%_verm10%_%_currentbuild%"=="%%a" set _gvlk=%%b

    REM If not find key
    if not defined _gvlk (
        call :regedit\off
        exit /b 4
    )

    REM Active
    for %%a in (
                                         ::?"active" ::?"display expires time" ::?"rm key"
        "/ipk %_gvlk%"  "/skms %_host%"      /ato        /xpr                      /ckms
    ) do cscript.exe //nologo //e:vbscript %windir%\System32\slmgr.vbs %%~a || exit /b 7
    call :regedit\off

    exit /b 0

REM for Office Deployment Tool only, [WARN] must call from ':lib\kms'
:this\private\kms\--odt
:this\private\kms\-o
    if not defined _host exit /b 3

    call :regedit\on
    call :odt\init_var
    if not exist "%_ospp%" (
        call :regedit\off
        exit /b 2
    )

    set _odtver=
    for /f "usebackq tokens=1,2*" %%a in (
        `reg.exe query HKLM\Software\Microsoft\Office\ClickToRun\Configuration /v ClientVersionToReport`
    ) do if "%%c" neq "" for /f "usebackq tokens=1 delims=." %%d in (
        '%%c'
    ) do set _odtver=%%d

    if not defined _odtver (
        call :regedit\off
        exit /b 2
    )

    REM Office 2010: http://technet.microsoft.com/en-us/library/ee624355(office.14).aspx
    for /f "usebackq tokens=2*" %%a in (
        `reg.exe query HKLM\Software\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds`
    ) do if "%%~b" neq "" for %%c in (
        %%~b
    ) do for %%k in (
        ::?https://docs.microsoft.com/en-us/DeployOffice/vlactivation/gvlks
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
        exit /b 6
    )

    REM Active
    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _gvlk\`
    ) do call :kms\dividing_line %%b && for %%c in (
                                            ::?"active" ::?"display expires time" ::?"rm key"
        "/inpkey:%%~na"    "/sethst:%_host%"   /act        /dstatus                  /remhst
    ) do for /f "usebackq delims=" %%d in (
        `cscript.exe //nologo //e:vbscript "%_ospp%" %%~c`
    ) do if "%%d" neq "---------------------------------------" if "%%d" neq "---Exiting-----------------------------" if "%%d" neq "---Processing--------------------------" echo.%%d
    call :regedit\off

    exit /b 0

:kms\dividing_line
    echo.
    echo ---------------------------------------
    echo.           %~1
    echo ---------------------------------------
    exit /b 0

::: "Office Deployment Tool" "" "usage: %~n0 odt [option] [[2016/2019]]" "    --deploy,  -d  [[path]]              Deployment Office Deployment Tool data" "    --install, -i  [[path]] [[names]]    Install office by names, will remove previous installation" "                                         default: 'base'" "" "      names:" "          base full" "          word excel powerpoint" "          access onenote outlook" "          project visio publisher" "" "      base:" "          word excel visio" "" "      full:" "          word excel powerpoint project visio"
:::: "invalid option" "target not found" "init fail" "must set office product ids" "install error" "setup error" "source not found"
:lib\odt
    title odt
    if "%~1"=="" call :this\annotation %0 & goto :eof
    setlocal
    set "_odt_source_path=%cd%"
    if "%~d0"=="\\" set "_odt_source_path=%~dp0"
    if "%~2" neq "" if "%~n2" neq "%~2" (
        if not exist "%~2" exit /b 2
        set "_odt_source_path=%~2"
    )
    if "%_odt_source_path:~-1%"=="\" set _odt_source_path=%_odt_source_path:~0,-1%

    set _odt_update=
    call :this\oset\--language _odt_lang || exit /b 2

    for %%a in (
        %*
    ) do (
        if "%%a"=="2016" set /a _odt_year=2016
        if "%%a"=="2019" set /a _odt_year=2019
    )
    if not defined _odt_year set _odt_year=2019

    set _odt_channel=PerpetualVL2019
    if %_odt_year% lss 2019 set _odt_channel=Broad

    call :this\odt\%*
    endlocal
    goto :eof

:this\odt\--deploy
:this\odt\-d
    3>nul call :odt\pro\full
    >%temp%\odt_download.xml call :this\txt\--subtxt "%~f0" odt.xml 3000

    title Deployed to '%_odt_source_path%'
    >&3 echo Deployed to '%_odt_source_path%'
    call :odt\ext\setup 27af1be6-dd20-4cb4-b154-ebab8a7d4a7e || exit /b 3
    odt.exe /download %temp%\odt_download.xml || exit /b 6
    erase %temp%\odt_download.xml
    goto :eof

:this\odt\--install
:this\odt\-i
    if not exist "%_odt_source_path%\Office\Data" exit /b 7

    REM shift can change %*
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

    if errorlevel 4 exit /b 4

    >%temp%\odt_install.xml call :this\txt\--subtxt "%~f0" odt.xml 3000

    title Installing from %_odt_source_path%\Office
    >&3 echo Installing...
    call :odt\ext\setup 27af1be6-dd20-4cb4-b154-ebab8a7d4a7e || exit /b 3
    odt.exe /configure %temp%\odt_install.xml || exit /b 6
    erase %temp%\odt_install.xml

    call :odt\init_var

    if %_odt_year% lss 2019 for /r "%_opath%" /d %%a in (
        License*
    ) do call :odt\cvlic "%%a" || exit /b 5
    echo.

    call :this\oset\--vergeq 10.0 && >&3 echo compress '%_opath%'&& >nul call :this\pkg\--exe "%_opath%"

    >&3 echo install complete. will try to activate

    REM can not call '\private\' function.
    call :lib\kms --odt
    exit /b 0

REM convert to volume license, for 2016 or 2013
:odt\cvlic
    for /r %1 %%a in (
        ProPlusVL_KMS*.xrm-ms
        ProjectProVL_KMS*.xrm-ms
        VisioProVL_KMS*.xrm-ms
        client-issuance-*.xrm-ms
        pkeyconfig-office.xrm?ms
    ) do >&3 set /p=.<nul& >nul cscript.exe //nologo "%_ospp%" /inslic:"%%~a" || exit /b 1
    REM >nul cscript.exe //nologo %windir%\System32\slmgr.vbs /ilc "%%~a"
    exit /b 0

:odt\pro\base
    call :odt\install_args word excel visio %*
    goto :eof

:odt\pro\full
    call :odt\install_args word excel powerpoint project visio %*
    goto :eof

:odt\install_args
    REM clear variable
    for /f "usebackq delims==" %%a in (
        `2^>nul set _odt__`
    ) do set %%a=
    REM Comment office professionalretail
    set _odt_pro_2016=odt.xml
    set _odt_pro_2019=odt.xml

    REM Groove: OneDriveforBusiness
    REM Lync: SkypeforBusiness

    REM ExcludeApp
    for %%a in (
        word excel powerpoint onenote onedrive skype access outlook publisher
    ) do set _odt__%%a_%_odt_year%=odt.xml
    for %%a in (
        word excel powerpoint onenote onedrive skype access outlook publisher
    ) do for %%b in (
        %*
    ) do if "%%~a"=="%%~b" set "_odt__%%a_%_odt_year%=" & set _odt_pro_%_odt_year%=

    REM must install some thing
    >nul 2>&1 set _odt__ || exit /b 5

    >&3 set /p=will install office %_odt_year%: <nul
    for %%a in (
        word excel powerpoint onenote onedrive skype access outlook publisher
    ) do if not defined _odt__%%a_%_odt_year% >&3 set /p='%%a' <nul

    REM Product
    for %%a in (%*) do for %%b in (
        project visio
    ) do if "%%~a"=="%%~b" set _odt__%%a_%_odt_year%=odt.xml
    for %%a in (
        project visio
    ) do if defined _odt__%%a_%_odt_year% >&3 set /p='%%a' <nul

    >&3 echo.
    >&3 echo [WARN] will remove all previous installation
    exit /b 0

:odt\init_var
    set _ospp=
    set _opath=
    pushd %cd%

    for /f "usebackq tokens=1,2*" %%a in (
        `reg.exe query HKLM\Software\Microsoft\Office\ClickToRun\Configuration /v InstallationPath`
    ) do if "%%c" neq "" cd /d "%%~c" || exit /b 1

    set _opath=%cd%

    for /r %%a in (
        ospp.vb?
    ) do set "_ospp=%%a"

    popd
    goto :eof

REM download and set in path
:odt\ext\setup
    for %%a in (odt.exe) do if "%%~$path:a" neq "" exit /b 0
    set PATH=%temp%\%~1;%PATH%
    if exist %temp%\%~1\odt.exe exit /b 0
    2>nul mkdir %temp%\%~1

    REM https://www.microsoft.com/download/details.aspx?id=49117
    REM https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117
    REM https://github.com/MicrosoftDocs/OfficeDocs-DeployOffice/blob/live/DeployOffice/office2019/deploy.md#deploy-languages-for-office-2019

    REM Version 16.0.6126.6351
    REM Version 16.0.6227.6350
    REM Version 16.0.6508.6350
    REM Version 16.0.6508.6351
    REM Version 16.0.6612.6353
    REM Version 16.0.6831.5775
    REM Version 16.0.7118.5775
    REM Version 16.0.7213.5776
    REM Version 16.0.7407.3600
    REM Version 16.0.7614.3602
    REM Version 16.0.8008.3601
    REM Version 16.0.8311.3600
    REM Version 16.0.8529.3600
    REM Version 16.0.9119.3601
    REM Version 16.0.9326.3600
    REM Version 16.0.10306.33602
    REM Version 16.0.10321.33602
    REM Version 16.0.10810.33603
    REM Version 16.0.11023.33600
    REM Version 16.0.11107.33602
    REM Version 16.0.11306.33602
    REM Version 16.0.11509.33604
    REM Version 16.0.11615.33602
    REM Version 16.0.11617.33601
    REM Version 16.0.11901.20022

    call :lib\download ^
            https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_11901-20022.exe ^
            %temp%\%~1\officedeploymenttool16.exe || exit /b 1

    %temp%\%~1\officedeploymenttool16.exe /extract:%temp%\%~1 /quiet || exit /b 1
    rename %temp%\%~1\setup.exe odt.exe || exit /b 1

    for %%a in (odt.exe) do if "%%~$path:a"=="" exit /b 1
    erase %temp%\%~1\officedeploymenttool16.exe %temp%\%~1\*.xml
    exit /b 0

::: "Visual Studio Installer" "" "usage: %~n0 vsi [branch] [option] [args]" "    branch:" "        enterprise" "        professional" "        community" "        core         (build tools without IDE)" "" "    option:" "        --deploy,  -d [directory_path]      Deployment visual studio build tools data" "        --install, -i [[directory_path]]    Install visual studio build tools online" "                                            when script in deploy path, will install offline"
:::: "invalid option" "args is empty" "can not get current language" "vs_install download error" "vs_buildtools error" "create soft link error" "can not install at root path" "target path not found"

:lib\vsi
    title vsi
    if "%~1"=="" call :this\annotation %0 & goto :eof
    if "%~2"=="" exit /b 2
    setlocal
    set _major_version=16
    call :this\vsi\%*

    if errorlevel 1 goto :eof

    if exist "%ProgramData%\Microsoft\VisualStudio\Packages" rmdir /s /q "%ProgramData%\Microsoft\VisualStudio\Packages"

    REM remove other parttition 'ProgramData' directory
    if "%~2" neq "" if exist %~d2\ProgramData\Microsoft\VisualStudio\Packages rmdir /s /q %~d2\ProgramData\Microsoft\VisualStudio\Packages
    call :this\dir\--clean %~d2\ProgramData
    call :this\dir\--isfree %~d2\ProgramData && rmdir /s /q %~d2\ProgramData
    endlocal
    exit /b 0

:this\vsi\enterprise
:this\vsi\professional
:this\vsi\community
:this\vsi\core
    set _install_args=--includeRecommended
    set _branch=
    for %%a in (%0) do set _branch=%%~na
    REM vs_buildtools: set _install_args=--add Microsoft.VisualStudio.Component.Static.Analysis.Tools --add Microsoft.VisualStudio.Component.VC.CoreBuildTools --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK --add Microsoft.VisualStudio.Component.TestTools.BuildTools --add Microsoft.VisualStudio.Component.Windows10SDK.17134 --add Microsoft.VisualStudio.Component.WinXP
    if "%_branch%"=="core" set "_branch=buildtools"& set _install_args=--add Microsoft.VisualStudio.Workload.VCTools;includeRecommended
    call :vsi\option\%*
    goto :eof

REM https://docs.microsoft.com/zh-cn/visualstudio/install/workload-component-id-vs-build-tools#visual-c-build-tools
REM https://docs.microsoft.com/zh-cn/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2019
:vsi\option\--deploy
:vsi\option\-d
    if "%~1"=="" exit /b 2
    2>nul mkdir "%~1"
    call :this\oset\--language _vsi_lang || exit /b 3
    call :vsi\ext\setup e64d79b4-0219-aea6-18ce-2fe10ebd5f0d %_branch% || exit /b 4

    REM error args: --allWorkloads
    start /wait vs_%_branch%.exe --wait --lang %_vsi_lang% --layout "%~1" %_install_args% || exit /b 5
    if not errorlevel 1 echo can use command '%~1\vs_setup.exe --passive --wait --norestart --nocache --noWeb'
    goto :eof

REM REM Debuggable Package Manager
REM powershell.exe -NoExit -Command "& { Import-Module Appx; Import-Module .\AppxDebug.dll; Show-AppxDebug}"
REM %comspec% /k "%VSINSTALLDIR%\Common7\Tools\VsDevCmd.bat"                REM Developer Command Prompt for VS 2017
REM %comspec% /k "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvars32.bat"           REM x86 Native Tools Command Prompt for VS 2017
REM %comspec% /k "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvars64.bat"           REM x64 Native Tools Command Prompt for VS 2017
REM %comspec% /k "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsx86_amd64.bat"    REM x86_x64 Cross Tools Command Prompt for VS 2017
REM %comspec% /k "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsamd64_x86.bat"    REM x64_x86 Cross Tools Command Prompt for VS 2017
REM https://docs.microsoft.com/zh-cn/visualstudio/install/build-tools-container
:vsi\option\--install
:vsi\option\-i
    if "%~1" neq "" (
        if "%~d1\"=="%~dp1" exit /b 7
        call :this\dir\--isfree "%~1" || exit /b 8
        2>nul mkdir "%~dp1Kits" "%~1"
        mklink /j "%ProgramFiles(x86)%\Windows Kits" "%~dp1Kits" || exit /b 6
        set _install_args=--installPath "%~1" %_install_args%
    )

    call :vsi\ext\setup e64d79b4-0219-aea6-18ce-2fe10ebd5f0d %_branch% || exit /b 4
    start /wait vs_%_branch%.exe --passive --wait --norestart --nocache %_install_args% || exit /b 5
    goto :eof

REM https://aka.ms/vs/16/release/vs_buildtools.exe
REM https://aka.ms/vs/16/release/vs_enterprise.exe
REM https://aka.ms/vs/16/release/vs_professional.exe
REM https://aka.ms/vs/16/release/vs_community.exe
:vsi\ext\setup
    for %%a in (vs_%~2.exe) do if "%%~$path:a" neq "" exit /b 0
    set PATH=%temp%\%~1;%PATH%
    if exist %temp%\%~1\vs_%~2.exe exit /b 0
    2>nul mkdir %temp%\%~1
    call :lib\download https://aka.ms/vs/16/release/vs_%~2.exe %temp%\%~1\vs_%~2.exe || exit /b 1
    exit /b 0

:::::::::::
:: other ::
:::::::::::

:::::::::::::
:: regedit ::
:::::::::::::

::: "Edit the Registry" "" "usage: %~n0 reg [option]" "" "    --intel-amd, -ia                   Run this before Chang CPU" "    --replace,   -x   [file_path] [src_str] [tag_str]" "                                       Replace reg string"
:::: "invalid option" "OS version is too low" "Not windows directory" "source string empty" "reg.exe error"
:lib\reg
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\reg\%*
    goto :eof

:this\reg\--intel-amd
:this\reg\-ia
    call :this\oset\--vergeq 6.0 || exit /b 2

    if "%~1"=="" (
        setlocal
        set /p _i=[Warning] Reg vhd will be change, Yes^|No:
        if /i "%_i%" neq "y" if /i "%_i%" neq "yes" exit /b 0
        call :regedit\on
        call :this\reg\delInteltag system
        call :regedit\off
        endlocal
        exit /b 0
    )

    setlocal
    set _target=%~f1
    if "%_target:~-1%"=="\" set _target=%_target:~0,-1%
    if not exist "%_target%\Windows\System32\config\SYSTEM" exit /b 3
    call :regedit\on
    set _load_point=HKLM\load-point%random%
    reg.exe load %_load_point% "%_target%\Windows\System32\config\SYSTEM" && call :this\reg\delInteltag tmp
    reg.exe unload %_load_point%
    call :regedit\off
    endlocal
    exit /b 0

REM for :this\reg\--intel-amd
:this\reg\delInteltag
    for /f "tokens=1,4 delims=x	 " %%a in (
        'reg.exe query HKLM\%1\Select'
    ) do if /i "%%a"=="Default" 2>nul reg.exe delete HKLM\%1\ControlSet00%%b\Services\intelppm /f
    exit /b 0

REM winpe \$windows.~bt -> ""
:this\reg\--replace
:this\reg\-x
    if "%~2"=="" exit /b 4
    setlocal
    call :regedit\on
    REM valueName: (Default) -> /ve
    for /f "usebackq" %%a in (
        `reg.exe query HKLM /ve`
    ) do set "_ve=%%a"

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
    REM replace
    for /f "usebackq delims=" %%a in (
        `reg.exe query %1 /f %2 /s`
    ) do >nul (
        set _line=%%a
        if "!_line:\%~n1=!"=="!_line!" (
            set _line=!_line:    =`!
            REM /d "X:\" /f -> /d "X:\\" /f
            set _line=!_line:\`=\\`!
            REM /v "X:\" /t -> /v "X:\\" /t
            if "!_line:~-1!"=="\" set _line=!_line!\
            set _line=!_line:"=\"!
            for /f "tokens=1,2* delims=`" %%b in (
                "!_line:%_src%=%_tag%!"
            ) do if "%%c" neq "" (

                if "%%b" neq "%_ve%" (
                    reg.exe add "!_key!" /v "%%b" /t %%c /d "%%d" /f || exit /b 5

                    REM delete
                    for /f "delims=`" %%e in (
                        "!_line!"
                    ) do if "%%b" neq "%%e" reg.exe delete "!_key!" /v "%%e" /f || exit /b 5

                ) else reg.exe add "!_key!" /ve /t %%c /d "%%d" /f || exit /b 5

                set /a _count+=1
            )
        ) else set _key=!_line:HKEY_LOCAL_MACHINE=HKLM!
    )
    echo all '%_count%' change.
    endlocal
    goto :eof

REM REM from Window 10 aik, will download imagex.exe at script path
REM :init\imagex
REM     for %%a in (_%0) do if %processor_architecture:~-2%==64 (
REM         REM amd64
REM         call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk d2611745022d67cf9a7703eb131ca487 fil4927034346f01b02536bd958141846b2

REM     REM x86
REM     ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk eacac0698d5fa03569c86b25f90113b5 fil6e1d5042624c9d5001511df2bfe4c40b
REM     exit /b 0

::: "String manage" "" "usage: %~n0 str [option] ..." "" "    --now,    -n [var_name] [[head_str]] [[tail_str]]    Display Time at [YYYYMMDDhhmmss]" "    --random, -r [count]                                 Print random string" "    --uuid,   -u [[var_name]]                            Get UUID string" "    --convert-pwd, -cp    [string] [[var_name]]          Encode password to base64 string for unattend.xml" "    --length,      -l     [string] [[var_name]]          Get string length" "    --2col-left,   -2l    [str_1] [str_2]                Make the second column left-aligned, default size is 15" "    --lcs                 [str1] [str2] [[var_name]]     Longest common subsequence"
:::: "invalid option" "variable name is empty" "System version is too old" "Args is empty" "string is empty"
:lib\str
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\str\%*
    goto :eof

:this\str\--now
:this\str\-n
    if "%~1"=="" exit /b 2
    set date=
    set time=
    REM en zh
    for /f "tokens=1-8 delims=-/:." %%a in (
      "%time: =%.%date: =.%"
    ) do if %%e gtr 1970 (
        set %~1=%~2%%e%%f%%g%%a%%b%%c%~3
    ) else if %%g gtr 1970 set %~1=%~2%%g%%e%%f%%a%%b%%c%~3
    exit /b 0

:this\str\--uuid
:this\str\-u
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

:this\str\--random
:this\str\-r
    setlocal
    2>nul set /a _password_length=%~1
    if "%~1"=="" set /a _password_length=8
    if %_password_length%==0 set /a _password_length=8
    PowerShell.exe ^
        -NoLogo ^
        -NonInteractive ^
        -ExecutionPolicy Unrestricted ^
        -Command ^
        "& { Add-Type -AssemblyName System.Web; [System.Web.Security.Membership]::GeneratePassword(%_password_length%, 0)}"
    endlocal
    goto :eof

:this\str\--convert-pwd
:this\str\-cp
    call :this\oset\--vergeq 6.1 || exit /b 3
    if "%~1"=="" exit /b 4
    for /f "usebackq" %%a in (
        `PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command ^
            "[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(\"%1OfflineAdministratorPassword\"))"`
    ) do if "%~2"=="" (echo %%a) else set %~2=%%a
    exit /b 0

:this\str\--length
:this\str\-l
    if "%~1"=="" exit /b 5
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

:this\str\--2col-left
:this\str\-2l
    if "%~2"=="" exit /b 5
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    echo %~1!_spaces:~0,%_len%!%~2
    endlocal
    exit /b 0

REM for :this\str\--2col-left and :this\txt\--all-col-left and
:strModulo
    set /a _acl+=1
    set _str=%_str:~15%
    if "%_str:~31,1%"=="" exit /b 0
    goto %0


REM Longest common subsequence
:this\str\--lcs
    if "%~2"=="" exit /b 5
    setlocal enabledelayedexpansion
    set "_1=%~1"
    set "_2=%~2"
    call :this\str\--length "%~1" #1
    call :this\str\--length "%~2" #2
    set _1m=
    set _2n=
    set _count=
    set _i=
    set _stat=
    set _sub=
    set /a _y=0, _len=0, _pre=0

    for /f "usebackq tokens=1,2 delims=#" %%a in (
        `set /a #1-1 ^& set /p^=#^<nul^& set /a -1*#2+1`
    ) do for /l %%c in (
        %%a,-1,%%b
    ) do (
        if %%c geq 0 (
            set /a _m=%%c, _n=0
        ) else set /a _m=0, _n=-1*%%c

        if not !_y! geq !#2! set /a _y+=1
        set /a _sub=_m, _count=0, _i=_y-_n-1

        for /l %%d in (
            0,1,!_i!
        ) do (
            set /a _1m=_m+%%d, _2n=_n+%%d
            call set _1m=%%_1:~!_1m!,1%%
            call set _2n=%%_2:~!_2n!,1%%
            if "!_1m!"=="!_2n!" (
                if not defined _stat set /a _sub=_m+%%d, _count=0, _stat=1
                set /a _count+=1
            ) else (
                set _stat=
                if !_count! gtr !_len! set /a _pre=_sub, _len=_count
            )
        )
        if !_count! gtr !_len! set /a _pre=_sub, _len=_count
    )
    set _i=!_pre!,!_len!
    endlocal & if "%~3"=="" (
        echo %_i%
    ) else set %~3=%_i%
    goto :eof


::: "Print text to standard output." "" "usage: %~n0 txt [option] [...]" "" "    --head,  -e  [-[count]]          Print the first some lines of FILE to standard output." "    --tail,  -t  [-[count]]          Print the last some lines of FILE to standard output." "    --skip,  -j  [source_file_path] [skip_line_num] [target_flie_path]" "                                     Print text skip some line" "" "    --subtxt, -o [source_path] [tag] [skip]" "                                     Show the subdocuments in the destination file by prefix" "                        subdocuments:" "                                     ::prefix: line 1" "                                     ::prefix: line 2" "                                     ::^^^!_var^^^!: line 3" "                                     ..." "" "    --all-col-left,   -al     [str] [[col_size]] " "                                     Use right pads spaces, make all column left-aligned" "                                     col_size is cols / 15. print nobr, but auto LF by col_size" "                       close command:    --all-col-left 0 0"
:::: "invalid option" "source file not found" "skip number error" "target file not found" "skip line is empty" "file not found" "powershell version is too old" "args error" "prefix is empty" "input string is empty"
:lib\txt
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\txt\%*
    goto :eof

:this\txt\--head
:this\txt\-e
    call :this\psv
    if not errorlevel 3 exit /b 7
    call :txt\ps1 -first %*|| exit /b 8
    goto :eof

:this\txt\--tail
:this\txt\-t
    call :this\psv
    if not errorlevel 3 exit /b 7
    call :txt\ps1 -Last %*|| exit /b 8
    goto :eof

REM for :this\txt\--head, :this\txt\--tail
:txt\ps1
    setlocal
    if "%~2"=="" exit /b 2
    set _count=%~2
    set _count=%_count:-=%
    call :this\is\--integer %_count% || exit /b 2
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

:this\txt\--skip
:this\txt\-j
    if not exist "%~1" exit /b 2
    call :this\is\--integer %~2 || exit /b 3
    if not exist "%~3" exit /b 4
    REM >%3 type nul
    REM for /f "usebackq skip=%~2 delims=" %%a in (
    REM     "%~f1"
    REM ) do >> %3 echo %%a
    < "%~f1" more.com +%~2 >%3
    exit /b 0

REM warring: must indent before code
:this\txt\--subtxt      [source_path] [tag] [skip]
:this\txt\-o
    if not exist "%~1" exit /b 2
    if "%~2"=="" exit /b 9
    setlocal enabledelayedexpansion
    if "%~3" neq "" 2>nul set /a _skip=%~3
    if not defined _skip set _skip=10
    if %_skip% leq 0 set _skip=10

    for /f "usebackq skip=%_skip% tokens=2* delims=:" %%a in (
        "%~f1"
    ) do if "%%a"=="%~2" echo.%%b

    endlocal
    goto :eof

:this\txt\--all-col-left
:this\txt\-al
    if "%~1"=="" exit /b 10
    if "%~2" neq "" if 1%~2 lss 12 (if defined _acl echo. & set _acl=) & exit /b 0
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    if "%~2" neq "" if 1%_acl% geq 1%~2 echo. & set /a _acl-=%~2-1
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    >&3 set /p=%~1!_spaces:~0,%_len%!<nul
    set /a _acl+=1
    if "%~2" neq "" if 1%_acl% geq 1%~2 echo. & set _acl=
    endlocal & set _acl=%_acl%
    exit /b 0

REM "    --line,  -l  [text_file_path] [skip_line] " "                                     Output text or read config"  "                                     need enabledelayedexpansion" "                                     skip must reset" "                                     text format: EOF [output_target] [command]"
REM :this\txt\--line
REM :this\txt\-l
REM     if "%~1"=="" exit /b 5
REM     if not exist "%~2" exit /b 6
REM     set _log=nul
REM     set "_exec=REM "
REM     for /f "usebackq skip=%~2 delims=" %%a in (
REM         "%~f1"
REM     ) do for /f "tokens=1,2*" %%b in (
REM         "%%a"
REM     ) do if "%%b"=="EOF" (
REM         if "%%c"=="%%~fc" if not exist "%%~dpc" (
REM             mkdir "%%~dpc"
REM         ) else if exist "%%~c" erase "%%~c"
REM         set "_log=%%~c"
REM         set "_exec=%%~d"
REM     ) else >>!_log! !_exec!%%~a
REM     set _log=
REM     set _exec=
REM     exit /b 0

REM REM text format for :lib\execline
REM EOF !temp!\!_now!.log "echo "
REM some codes
REM EOF nul set
REM a=1
REM EOF nul "rem "


::: "Print or check MD5 (128-bit) checksums." "" "usage: %~n0 md5 [file]"
:::: "powershell error"
:lib\MD5
::: "Print or check SHA1 (160-bit) checksums." "" "usage: %~n0 sha1 [file]"
:::: "powershell error"
:lib\SHA1
::: "Print or check SHA256 (256-bit) checksums." "" "usage: %~n0 sha256 [file]"
:::: "powershell error"
:lib\SHA256
::: "Print or check SHA512 (512-bit) checksums." "" "usage: %~n0 sha512 [file]"
:::: "powershell error"
:lib\SHA512
    for /f "usebackq delims=" %%a in (
        `2^>nul dir /a-d /b /s %*`
    ) do for %%b in (%0) do call :this\hash %%~nb "%%~a" || exit /b 1
    exit /b 0

:this\hash
    if exist "%~2" for /f "usebackq delims=" %%a in (
        `certutil.exe -hashfile %2 %~1`
    ) do for /f "usebackq tokens=1,2 delims=:" %%b in (
        '%%a'
    ) do if "%%a"=="%%b" call :hash\trim "%%a" %2& exit /b 0
    if exist "%~2" exit /b 1
    setlocal
    call :this\psv
    if not errorlevel 2 exit /b 1
    REM set _arg=-
    REM if exist "%~2" (
    REM     set "_arg=%~2"
    REM     for /f "usebackq" %%a in (
    REM         `PowerShell.exe ^
    REM            -NoLogo ^
    REM            -NonInteractive ^
    REM            -ExecutionPolicy Unrestricted ^
    REM            -Command ^
    REM            "[System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.%~1CryptoServiceProvider).ComputeHash([System.IO.File]::Open(\"%2\",[System.IO.Filemode]::Open,[System.IO.FileAccess]::Read))).ToString() -replace \"-\""`
    REM     ) do set _hash=%%a
    REM ) else
    for /f "usebackq" %%a in (
        `PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command ^
            "[System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.%~1CryptoServiceProvider).ComputeHash([Console]::OpenStandardInput())).ToString() -replace \"-\""`
    ) do set _hash=%%a
    if "%_hash%"=="" exit /b 2
    set _hash=%_hash:A=a%
    set _hash=%_hash:B=b%
    set _hash=%_hash:C=c%
    set _hash=%_hash:D=d%
    set _hash=%_hash:E=e%
    set _hash=%_hash:F=f%
    endlocal & echo %_hash%   -
    exit /b 0

:hash\trim
    setlocal
    set _str=%~1
    echo %_str: =%   %2
    endlocal
    goto :eof

REM ::: "Delete Login Notes"
REM :lib\delLoginNote
REM     net.exe use * /delete
REM     exit /b 0

REM Test PowerShell version, Return errorlevel
:this\psv
    for %%a in (PowerShell.exe) do if "%%~$path:a"=="" exit /b 0
    for /f "usebackq" %%a in (
        `2^>nul PowerShell.exe ^
            -NoLogo ^
            -NonInteractive ^
            -ExecutionPolicy Unrestricted ^
            -Command ^
            "$PSVersionTable.WSManStackVersion.Major"`
    ) do exit /b %%a
    exit /b 0

::: "Run PowerShell script" "" "usage: %~n0 ps1 [ps1_script_path]"
:::: "ps1 script not found" "file suffix error"
:lib\ps1
    if not exist "%~1" exit /b 1
    if /i "%~x1" neq ".ps1" exit /b 2
    PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -File %*
    goto :eof

::::::::::::::
:: VBScript ::
::::::::::::::

REM screnc.exe from http://download.microsoft.com/download/0/0/7/0073477f-bbf9-4510-86f9-ba51282531e3/sce10en.exe
REM if /i "%~x1"==".vbs" screnc.exe %1 ./%~n1.vbe

::: "Run VBScript library from lib.vbs" "" "usage: %~n0 vbs [[command...]]"
:::: "lib.vbs not found"
:lib\vbs
    REM cscript.exe //nologo //e:vbscript.encode %*
    for %%a in (lib.vbs) do if "%%~$path:a"=="" (
        exit /b 1
    ) else cscript.exe //nologo "%%~$path:a" %* 2>&3 || exit /b 30
    goto :eof

::: "Tag date time each line" "" "usage: %~n0 log [strftime format]"
:lib\log
    call :lib\vbs log %*
    goto :eof

::::::::::::::::::
::     Base     ::
  :: :: :: :: ::

REM set /a 0x7FFFFFFF
REM -2147483647 ~ 2147483647

REM start /b [command...]
:thread
    call %~pnx1
    goto :eof

::::: thread valve :::::
REM usage: :this\thread_valve [count] [name] [commandline]
:this\thread_valve
    set /a _thread\count+=1
    if %_thread\count% lss %~1 exit /b 0
    :thread_valve\loop
        set _thread\count=0
        for /f "usebackq" %%a in (
            `2^>nul wmic.exe process where "name='%~2' and commandline like '%%%~3%%'" get processid ^| %windir%\System32\find.exe /c /v ""`
        ) do set /a _thread\count=%%a - 2
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
    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _MAP%~2\`
    ) do set "_keys=!_keys! "%%~nxa""
    endlocal & set %~1=%_keys%
    exit /b 0

:this\map\--values
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _values=
    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _MAP%~2\`
    ) do set "_values=!_values! "%%~b""
    endlocal & set %~1=%_values%
    exit /b 0

:this\map\--array
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _kv=
    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _MAP%~2\`
    ) do set "_kv=!_kv! "%%~nxa" "%%~b""
    endlocal & set %~1=%_kv%
    exit /b 0

REM errorlevel value is count
:this\map\--size
    setlocal
    set _count=0
    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _MAP%~1\`
    ) do set /a _count+=1
    endlocal & exit /b %_count%

:this\map\--clear
    call :this\var\--unset _MAP%~1\
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
    for /f "usebackq tokens=1* delims==" %%a in (
        `set _page\`
    ) do echo%%b
    exit /b 0

:this\page\--clear
    call :this\var\--unset _page
    exit /b 0

REM load .*.ini config
:this\load_ini
    if "%~1"=="" exit /b 1
    set _bool_=
    REM trim ';' and cut it
    for /f "usebackq delims=" %%a in (
        `2^>nul type "%~dp0.*.ini" "%userprofile%\.*.ini"`
    ) do for /f "usebackq tokens=1 delims=;" %%b in (
        '%%a'
    ) do for /f "usebackq tokens=1* delims==" %%c in (
        '%%b^^'
    ) do if "%%d"=="" (
        if /i "%%c"=="[%~1]^" (
            set _bool_=true
        ) else set _bool_=
    ) else if defined _bool_ for /f "usebackq delims=^" %%e in (
        '%%d'
    ) do set _MAP%~2\%%c=%%e
    set _bool_=

    call :map --size %~2 && exit /b 1
    exit /b 0

  :: :: :: :: ::
::     Base     ::
::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::
::                 Framework                 ::
   :: :: :: :: :: :: :: :: :: :: :: :: :: ::

REM Show INFO or ERROR
:this\annotation
    setlocal enabledelayedexpansion & call :this\var\--set-errorlevel %errorlevel%
    for /f "usebackq skip=73 tokens=1,2* delims=\ " %%a in (
        "%~f0"
    ) do (
        REM Set annotation, errorlevel will reset after some times
        if %errorlevel% geq 1 (
            if /i "%%~a"=="::::" set _tmp=%errorlevel% %%b %%c
        ) else if /i "%%~a"==":::" set _tmp=%%b %%c

        if /i "%%~a"==":%~n0" (
            REM Display func info or error
            if /i "%%~a\%%~b"=="%~1" (
                if %errorlevel% geq 1 (
                    REM Inherit errorlevel
                    call :this\var\--set-errorlevel %errorlevel%
                    call %0\error %%~a\%%~b !_tmp!
                ) else call %0\more !_tmp!
                goto :eof
            )
            REM init func var, for display all func, or show sort func name
            set _args\%%~b=!_tmp! ""
            REM Clean var
            set _tmp=
        )
    )

    REM Foreach func list
    call :%~n0\cols _col
    set /a _i=0, _col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (
        `2^>nul set _args\%~n1`
    ) do if "%~1" neq "" (
        REM " Sort func name expansion
        set /a _i+=1
        set _target=%%~nxa %2 %3 %4 %5 %6 %7 %8 %9
        if !_i!==1 set _tmp=%%~nxa
        if !_i!==2 call :this\txt\--all-col-left !_tmp! %_col%
        if !_i! geq 2 call :this\txt\--all-col-left %%~nxa %_col%
    ) else call :this\str\--2col-left %%~nxa "%%~b"
    REM Close lals
    if !_i! gtr 0 call :this\txt\--all-col-left 0 0
    REM Display func or call func
    endlocal & if %_i% gtr 1 (
        echo.
        >&2 echo Warning: function sort name conflict
        exit /b 1
    ) else if %_i%==0 (
        if "%~1" neq "" >&2 echo Error: No function found& exit /b 1
    ) else if %_i%==1 call :%~n0\%_target% || call %0 :%~n0\%_target%
    goto :eof

:this\annotation\error
    for /l %%a in (1,1,%2) do shift /2
    if "%~2"=="" goto :eof
    REM color 0c
    >&2 echo.Error: %~2 (%~s0%~1)
    goto :eof

:this\annotation\more
    echo.%~1
    shift /1
    if "%~1%~2" neq "" goto %0
    exit /b 0

::: "Get cmd cols" "" "usage: %~n0 cols [[var_name]]"
:lib\cols
    for /f "usebackq skip=4 tokens=2" %%a in (
        `mode.com con`
    ) do (
        if "%~1"=="" (
            echo %%a
        ) else set %~1=%%a
        exit /b 0
    )
    exit /b 0

   :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::                 Framework                 ::
:::::::::::::::::::::::::::::::::::::::::::::::


REM for :lib\odt
                    ::odt.xml:<^!-- Office 365 client configuration file sample. To be used for Office 365 ProPlus apps,
                    ::odt.xml:     Office 365 Business apps, Project Pro for Office 365 and Visio Pro for Office 365.
                    ::odt.xml:
                    ::odt.xml:     For detailed information regarding configuration options visit: http://aka.ms/ODT.
                    ::odt.xml:     To use the configuration file be sure to remove the comments
                    ::odt.xml:
                    ::odt.xml:     The following sample allows you to download and install the 64 bit version of the Office 365 ProPlus apps
                    ::odt.xml:     and Visio Pro for Office 365 directly from the Office CDN using the Monthly Channel
                    ::odt.xml:     settings  -->
                    ::odt.xml:
                    ::odt.xml:<Configuration>
                    ::odt.xml:
                    ::odt.xml:    <Remove All="TRUE">
                    ::odt.xml:        <Product ID="Access2019Retail" />
                    ::odt.xml:        <Product ID="Access2019Volume" />
                    ::odt.xml:        <Product ID="AccessRetail" />
                    ::odt.xml:        <Product ID="AccessRuntimeRetail" />
                    ::odt.xml:        <Product ID="Excel2019Retail" />
                    ::odt.xml:        <Product ID="Excel2019Volume" />
                    ::odt.xml:        <Product ID="ExcelRetail" />
                    ::odt.xml:        <Product ID="HomeBusiness2019Retail" />
                    ::odt.xml:        <Product ID="HomeBusinessRetail" />
                    ::odt.xml:        <Product ID="HomeStudent2019Retail" />
                    ::odt.xml:        <Product ID="HomeStudentRetail" />
                    ::odt.xml:        <Product ID="LanguagePack" />
                    ::odt.xml:        <Product ID="O365BusinessRetail" />
                    ::odt.xml:        <Product ID="O365HomePremRetail" />
                    ::odt.xml:        <Product ID="O365ProPlusRetail" />
                    ::odt.xml:        <Product ID="O365SmallBusPremRetail" />
                    ::odt.xml:        <Product ID="OneNoteRetail" />
                    ::odt.xml:        <Product ID="Outlook2019Retail" />
                    ::odt.xml:        <Product ID="Outlook2019Volume" />
                    ::odt.xml:        <Product ID="OutlookRetail" />
                    ::odt.xml:        <Product ID="Personal2019Retail" />
                    ::odt.xml:        <Product ID="PowerPoint2019Retail" />
                    ::odt.xml:        <Product ID="PowerPoint2019Volume" />
                    ::odt.xml:        <Product ID="PowerPointRetail" />
                    ::odt.xml:        <Product ID="Professional2019Retail" />
                    ::odt.xml:        <Product ID="ProfessionalRetail" />
                    ::odt.xml:        <Product ID="ProjectPro2019Retail" />
                    ::odt.xml:        <Product ID="ProjectPro2019Volume" />
                    ::odt.xml:        <Product ID="ProjectProRetail" />
                    ::odt.xml:        <Product ID="ProjectProXVolume" />
                    ::odt.xml:        <Product ID="ProjectStd2019Retail" />
                    ::odt.xml:        <Product ID="ProjectStd2019Volume" />
                    ::odt.xml:        <Product ID="ProjectStdRetail" />
                    ::odt.xml:        <Product ID="ProjectStdXVolume" />
                    ::odt.xml:        <Product ID="ProPlus2019Volume" />
                    ::odt.xml:        <Product ID="Publisher2019Retail" />
                    ::odt.xml:        <Product ID="Publisher2019Volume" />
                    ::odt.xml:        <Product ID="PublisherRetail" />
                    ::odt.xml:        <Product ID="SkypeforBusiness2019Retail" />
                    ::odt.xml:        <Product ID="SkypeforBusiness2019Volume" />
                    ::odt.xml:        <Product ID="SkypeforBusinessEntry2019Retail" />
                    ::odt.xml:        <Product ID="SkypeforBusinessEntryRetail" />
                    ::odt.xml:        <Product ID="SkypeforBusinessRetail" />
                    ::odt.xml:        <Product ID="Standard2019Volume" />
                    ::odt.xml:        <Product ID="VisioPro2019Retail" />
                    ::odt.xml:        <Product ID="VisioPro2019Volume" />
                    ::odt.xml:        <Product ID="VisioProRetail" />
                    ::odt.xml:        <Product ID="VisioProXVolume" />
                    ::odt.xml:        <Product ID="VisioStd2019Retail" />
                    ::odt.xml:        <Product ID="VisioStd2019Volume" />
                    ::odt.xml:        <Product ID="VisioStdRetail" />
                    ::odt.xml:        <Product ID="VisioStdXVolume" />
                    ::odt.xml:        <Product ID="Word2019Retail" />
                    ::odt.xml:        <Product ID="Word2019Volume" />
                    ::odt.xml:        <Product ID="WordRetail" />
                    ::odt.xml:    </Remove>
                    ::odt.xml:
                    ::odt.xml:    <^!--  <Add OfficeClientEdition="64" Channel="Monthly">  -->
                    ::odt.xml:    <Add SourcePath="!_odt_source_path!\" OfficeClientEdition="64" Channel="!_odt_channel!">
                    ::odt.xml:
                    ::odt.xml:        <^!--  https://go.microsoft.com/fwlink/p/?LinkID=301891  -->
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

REM for :this\wim\--new
    ::wim.ini:[ExclusionList]
    ::wim.ini:\$*
    ::wim.ini:\boot*
; REM fix: \*.sys == *.sys
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

REM for current hotfix
    ::chot.xml:<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    ::chot.xml:    <xsl:output method="text"/><xsl:template match="/">
    ::chot.xml:        <xsl:for-each select="//References"><xsl:sort select="DownloadURL"/>
     ::!_chot!:            <xsl:if test="not(contains(DownloadURL, 'kb!_chot_kb!'))">
    ::chot.xml:            <xsl:value-of select="DownloadURL"/><xsl:text>&#10;</xsl:text>
     ::!_chot!:            </xsl:if>
    ::chot.xml:        </xsl:for-each>
    ::chot.xml:    </xsl:template>
    ::chot.xml:</xsl:transform>

REM for unattend.xml
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

REM hisecws.inf: Registry Values: 1:REG_SZ 2:REG_EXPAND_SZ 3:REG_BINARY 4:REG_DWORD 7:REG_MULTI_SZ
    ::hisecws.inf:[Unicode]
    ::hisecws.inf:Unicode=yes
    ::hisecws.inf:
    ::hisecws.inf:[System Access]
    ::hisecws.inf:MaximumPasswordAge = -1
    ::hisecws.inf:PasswordComplexity = 0
    ::hisecws.inf:
    ::hisecws.inf:[Registry Values]
    ::hisecws.inf:MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableCAD=4,1
    ::hisecws.inf:MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDriveTypeAutoRun=4,255
    ::hisecws.inf:MACHINE\Software\Policies\Microsoft\Windows NT\Reliability\**del.ShutdownReasonUI=1,""
    ::hisecws.inf:MACHINE\Software\Policies\Microsoft\Windows NT\Reliability\ShutdownReasonOn=4,0
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseAdvancedStartup=4,1
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\EnableBDEWithNoTPM=4,1
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPM=4,2
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPMPIN=4,0
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPMKey=4,2
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPMKeyPIN=4,0
    ::hisecws.inf:User\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoThumbnailCache=4,1
    ::hisecws.inf:User\Software\Policies\Microsoft\Windows\Explorer\DisableThumbsDBOnNetworkFolders=4,1
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
