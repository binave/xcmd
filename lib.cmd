@echo off
REM     Copyright 2017 bin jin
REM
REM     Licensed under the Apache License, Version 2.0 (the "License");
REM     you may not use this file except in compliance with the License.
REM     You may obtain a copy of the License at
REM
REM         http://www.apache.org/licenses/LICENSE-2.0
REM
REM     Unless required by applicable law or agreed to in writing, software
REM     distributed under the License is distributed on an "AS IS" BASIS,
REM     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM     See the License for the specific language governing permissions and
REM     limitations under the License.

REM Framework:
REM
REM     If the function names conform to the specifications:
REM         External call function. (Support short name completion)
REM         Error handling.
REM         Display help information.
REM         Print the functions list.
REM
REM     e.g.
REM         ::: "[brief_introduction]" "" "[description_1]" "[description_2]" ...
REM         :::: "[error_description_1]" "[error_description_2]" ...
REM         :[script_name_without_suffix]\[function_name]
REM             ...
REM             [function_body]
REM             ...
REM             REM exit and display [error_description_1]
REM             exit /b 1
REM             ...
REM             REM return false status
REM             exit /b 10

::::::::::::::::::::::::::
:: some basic functions ::
::::::::::::::::::::::::::

REM For thread
if "%1"=="""" goto thread

REM Init PATH
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

REM :lib\g* -> get
REM :lib\i* -> if is
REM :lib\s* -> set
REM :lib\u* -> un

REM init errorlevel
set errorlevel=

REM Help
setlocal
    set \\\12=%~1%~2
    if not defined \\\12 set \\\12=-
    set \\\12=%\\\12:--help=%
    set \\\12=%\\\12:-h=%
endlocal & if "%~1%~2" neq "%\\\12%" (
    if "%~2"=="" (call :this\annotation) else call :this\annotation :%~n0\%~1
    goto :eof
)

call :%~n0\%* 2>nul
REM Test type function
if errorlevel 10 exit /b 1
if errorlevel 1 call :this\annotation :%~n0\%* & goto :eof
exit /b 0

:::::::::::::::::::::::::::::::::::::::::::::::
::                 Framework                 ::
:: :: :: :: :: :: :: :: :: :: :: :: :: :: :: ::

REM Show INFO or ERROR
:this\annotation
    setlocal enabledelayedexpansion & call :%~n0\serrlv %errorlevel%
    for /f "usebackq skip=90 tokens=1,2* delims=\ " %%a in (
        "%~f0"
    ) do (
        REM Set annotation, errorlevel will reset after some times
        if %errorlevel% geq 1 (
            if /i "%%~a"=="::::" set \\\tmp=%errorlevel% %%b %%c
        ) else if /i "%%~a"==":::" set \\\tmp=%%b %%c

        if /i "%%~a"==":%~n0" (
            REM Display func info or error
            if /i "%%~a\%%~b"=="%~1" (
                if %errorlevel% geq 1 (
                    REM Inherit errorlevel
                    call :%~n0\serrlv %errorlevel%
                    call %0\error %%~a\%%~b !\\\tmp!
                ) else call %0\more !\\\tmp!
                goto :eof
            )
            REM init func var, for display all func, or show sort func name
            set \\\args\%%~b=!\\\tmp! ""
            REM Clean var
            set \\\tmp=
        )
    )

    REM Foreach func list
    call :%~n0\gcols \\\col
    set /a \\\i=0, \\\col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (
        `set \\\args\%~n1 2^>nul`
    ) do if "%~1" neq "" (
        REM " Sort func name expansion
        set /a \\\i+=1
        set \\\target=%%~nxa %2 %3 %4 %5 %6 %7 %8 %9
        if !\\\i!==1 set \\\tmp=%%~nxa
        if !\\\i!==2 call :%~n0\rpad !\\\tmp! %\\\col%
        if !\\\i! geq 2 call :%~n0\rpad %%~nxa %\\\col%
    ) else call :%~n0\2la %%~nxa "%%~b"
    REM Close rpad
    if !\\\i! gtr 0 call :%~n0\rpad 0 0
    REM Display func or call func
    endlocal & if %\\\i% gtr 1 (
        echo.
        >&2 echo Warning: function sort name conflict
        exit /b 1
    ) else if %\\\i%==0 (
        if "%~1" neq "" >&2 echo Error: No function found& exit /b 1
    ) else if %\\\i%==1 call :%~n0\%\\\target% || call %0 :%~n0\%\\\target%
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

::: "Make the second column left-aligned" "" "    default size is 15" "usage: %~n0 2la [str_1] [str_2]"
:::: "input string is empty"
:lib\2la
    if "%~2"=="" exit /b 1
    setlocal enabledelayedexpansion
    set \\\str=%~10123456789abcdef
    if "%\\\str:~31,1%" neq "" call :strModulo
    set /a \\\len=0x%\\\str:~15,1%
    set "\\\spaces=                "
    echo %~1!\\\spaces:~0,%\\\len%!%~2
    endlocal
    exit /b 0

::: "Use right pads spaces, make all column left-aligned" "" "usage: %~n0 rpad [str] [[col_size]]" "       %~n0 rpad 0 0" "       close command" "       col_size is cols / 15" "       print nobr, but auto LF by col_size"
:::: "input string is empty"
:lib\rpad
    if "%~1"=="" exit /b 1
    if "%~2" neq "" if 1%~2 lss 12 (if defined \\\rpad echo. & set \\\rpad=) & exit /b 0
    setlocal enabledelayedexpansion
    set \\\str=%~10123456789abcdef
    if "%\\\str:~31,1%" neq "" call :strModulo
    if "%~2" neq "" if 1%\\\rpad% geq 1%~2 echo. & set /a \\\rpad-=%~2-1
    set /a \\\len=0x%\\\str:~15,1%
    set "\\\spaces=                "
    >&3 set /p=%~1!\\\spaces:~0,%\\\len%!<nul
    set /a \\\rpad+=1
    if "%~2" neq "" if 1%\\\rpad% geq 1%~2 echo. & set \\\rpad=
    endlocal & set \\\rpad=%\\\rpad%
    exit /b 0

REM for :lib\2la and :lib\rpad and
:strModulo
    set /a \\\rpad+=1
    set \\\str=%\\\str:~15%
    if "%\\\str:~31,1%"=="" exit /b 0
    goto %0

::: "Get cmd cols" "" "usage: %~n0 gcols [[var_name]]"
:lib\gcols
    for /f "usebackq skip=4 tokens=2" %%a in (`mode.com con`) do (
        if "%~1"=="" (
            echo %%a
        ) else set %~1=%%a
        exit /b 0
    )
    exit /b 0

::: "Set errorlevel variable"
:lib\serrlv
    if "%~1"=="" goto :eof
    exit /b %1

REM start /b [command...]
:thread
    shift /1
    call :thread\%1 %2 %3 %4 %5 %6 %7 %8 %9
    exit 0

:: :: :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::                 Framework                 ::
:::::::::::::::::::::::::::::::::::::::::::::::


::: "Search file in $env:path" "" "usage: %~n0 search [file_name]" "       support wildcards: * ?" "       e.g. %~n0 Search *ja?a"
:::: "first args is empty"
:lib\search
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    call :lib\gcols \\\col
    set /a \\\i=0, \\\col/=16
    call :lib\trimpath path
    for /f "usebackq delims==" %%a in (
        `dir /a-d /b "!path:;=\%~1*" "!\%~1*" 2^>nul`
    ) do if "%pathext%" neq "!pathext:%%~xa=!" (
        set /a \\\i+=1
        if !\\\i!==1 set \\\tmp=%%~nxa
        if !\\\i!==2 call :lib\rpad !\\\tmp! %\\\col%
        if !\\\i! geq 2 call :lib\rpad %%~nxa %\\\col%
    )
    REM Close rpad
    call :lib\rpad 0 0
    endlocal & if %\\\i% gtr 1 (
        echo.
        echo.Find %\\\i% exec file.
    ) else if %\\\i%==0 (
        echo.No exec file found.
    ) else call :lib\which %\\\tmp%
    exit /b 0

::: "Locate a program file in the user's path" "" "usage: %~n0 which [file_full_name]"
:lib\which
    if not defined \\\p (
        setlocal enabledelayedexpansion
        call :lib\trimpath path
        set \\\p=!path:;=\;!\
    )
    if "%~a$\\\p:1"=="" endlocal & exit /b 0
    echo %~$\\\p:1
    set \\\p=!\\\p:%~dp$\\\p:1=!
    goto %0

::: "Get UUID" "" "usage: %~n0 guuid [[var_name]]"
:lib\guuid
    setlocal enabledelayedexpansion
        for /l %%a in (
            1,1,8
        ) do (
            set /a \1=!random!%%16,\2=!random!%%16,\3=!random!%%16,\4=!random!%%16
            set \0=!\0!!\1!.!\2!.!\3!.!\4!.
            if %%a gtr 1 if %%a lss 6 set \0=!\0!-
        )
        set \0=%\0:10.=a%
        set \0=%\0:11.=b%
        set \0=%\0:12.=c%
        set \0=%\0:13.=d%
        set \0=%\0:14.=e%
        set \0=%\0:15.=f%
    endlocal & if "%~1"=="" (
        echo %\0:.=%
    ) else set %~1=%~2%\0:.=%%~3
    exit /b 0

::: "Get sid by username" "" "usage: %~n0 gsid [user_name] [[var_name]]"
:::: "first parameter is empty"
:lib\gsid
    if "%~1"=="" exit /b 1
    for /f "usebackq skip=1" %%a in (
        `wmic.exe useraccount where name^='%1' get sid`
    ) do for %%b in (%%a) do if "%~2"=="" (
        echo.%%b
    ) else set %~2=%%b
    exit /b 0

::: "Get string length" "" "usage: %~n0 glen [string] [[var_name]]"
:::: "string is empty"
:lib\glen
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set \\\len=
    set \\\str=%~1fedcba9876543210
    if "%\\\str:~31,1%" neq "" (
        for %%a in (
            4096 2048 1024 512 256 128 64 32 16 8 4 2 1
        ) do if !\\\str:~%%a^,1!. neq . set /a \\\len+=%%a & set \\\str=!\\\str:~%%a!
        set /a \\\len-=15
    ) else set /a \\\len=0x!\\\str:~15^,1!
    endlocal & if "%~2"=="" (
        echo %\\\len%
    ) else set %~2=%\\\len%
    exit /b 0

::: "Get first path foreach Partiton" "" "usage: %~n0 gfirstpath [path_name] [[var_name]]"
:::: "The first parameter is empty" "Target path not found"
:lib\gfirstpath
    if "%~1"=="" exit /b 1
    for /f "usebackq skip=1 tokens=1,2" %%a in (
        `wmic.exe logicaldisk get Caption`
    ) do if "%%~aa" neq "" if exist "%%a\%~1" (
        if "%~2"=="" (
            echo %%a\%~1
        ) else set "%~2=%%a\%~1"
        exit /b 0
    )
    exit /b 2

::: "Get Unused Device Id" "" "usage: %~n0 gfreeletter [[var_name]]"
:lib\gfreeletter
    setlocal enabledelayedexpansion
    set \\\di=zyxwvutsrqponmlkjihgfedcba
    for /f "usebackq skip=1 delims=:" %%a in (
        `wmic.exe logicaldisk get DeviceID`
    ) do set \\\di=!\\\di:%%a=!
    endlocal & if "%~1"=="" (
        echo.%\\\di:~0,1%:
    ) else set %~1=%\\\di:~0,1%:
    exit /b 0

::: "Get Device IDs" "" "usage: %~n0 gletters [var_name] [[l/r/n]]" "       no param view all" "       l: Local Fixed Disk" "       r: CD-ROM Disc" "       n: Network Connection"
:::: "variable name is empty" "type command not support"
:lib\gletters
::: "Get Device IDs DESC" "" "usage: %~n0 grettels [var_name] [[l/r/n]]" "       no param view all" "       l: Local Fixed Disk" "       r: CD-ROM Disc" "       n: Network Connection"
:::: "variable name is empty" "type command not support"
:lib\grettels
    :::::::::::::::::::::::::::::::::::::::
    :: [WARNING] Not support nano server ::
    :::::::::::::::::::::::::::::::::::::::
    if "%~1"=="" exit /b 1
    set \\\var=
    setlocal enabledelayedexpansion
    set \\\desc=
    REM Test sort
    for %%a in (%0) do if "%%~na"=="grettels" set \\\desc=1
    REM add where conditions
    if "%~2" neq "" (
        set \\\DriveType=
        if /i "%~2"=="l" set \\\DriveType=3
        if /i "%~2"=="r" set \\\DriveType=5
        if /i "%~2"=="n" set \\\DriveType=4
        if not defined \\\DriveType exit /b 2
        set "\\\DriveType=where DriveType^^=!\\\DriveType!"
    )
    REM main
    for /f "usebackq skip=1 delims=:" %%a in (
        `wmic.exe logicaldisk %\\\DriveType% get DeviceID`
    ) do if defined \\\desc (
        set "\\\var=%%a !\\\var!"
    ) else set "\\\var=!\\\var! %%a"
    if defined \\\var set \\\var=%\\\var:~1,-2%
    endlocal & set %~1=%\\\var%
    exit /b 0

::: "Get OS language bit and version" "" "usage: %~n0 gosinf [os_path] [[var_name]]" "       return [var].lang [var].bit [var].ver"
:::: Not OS path or Low OS version"
:lib\gosinf
    if not exist %~1\Windows\servicing exit /b 1

    for /d %%a in (
        %~1\Windows\servicing\Version\*
    ) do (
        REM OS version
        for /f "tokens=1,2 delims=." %%b in (
            "%%~na"
        ) do if "%~2"=="" (
            setlocal enabledelayedexpansion
            set /a \\\ver=%%b*10+%%c
            >&3 set /p=ver:!\\\ver!, <nul
            endlocal
        ) else set /a %2.ver=%%b*10+%%c

        REM OS bit
        if exist %%a\amd64_installed (
            if "%~2"=="" (
                >&3 set /p=bin:amd64, <nul
            ) else set %2.bit=amd64
        ) else if "%~2"=="" (
            >&3 set /p=bin:x86, <nul
        ) else set %2.bit=x86
    )
    REM OS language
    for /d %%a in (
        %~1\Windows\servicing\??-??
    ) do if "%~2"=="" (
        set /p=lang:%%~na<nul
    ) else set %2.lang=%%~na

    if "%~2"=="" echo.
    exit /b 0

::: "Test path is directory" "" "usage: call %~n0 idir [path]"
:lib\idir
    setlocal
    set \\\path=%~a1-
    REM quick return
    set \\\code=10
    if %\\\path:~0,1%==d set \\\code=0
    endlocal & exit /b %\\\code%

::: "Test path is Symbolic Link" "" "usage: call %~n0 iln [file_path]" "       e.g. call %~n0 iln C:\Test"
:lib\iln
    for /f "usebackq delims=" %%a in (
        `dir /al /b "%~dp1" 2^>nul`
    ) do if "%%a"=="%~n1" exit /b 0
    REM quick return
    exit /b 10

::: "Test directory is empty" "" "usage: call %~n0 ifreedir [dir_path]"
:::: "Not directory"
:lib\ifreedir
    call :lib\idir %1 || exit /b 1
    for /d %%a in ("%~1\*") do exit /b 10
    for /r %1 %%a in (*.*) do exit /b 10
    exit /b 0

::: "Test string if Num" "" "usage: call %~n0 inum [string]"
:lib\inum
    if "%~1"=="" exit /b 10
    setlocal
    set \\\tmp=
    REM quick return
    2>nul set /a \\\code=10, \\\tmp=%~1
    if "%~1"=="%\\\tmp%" set \\\code=0
    endlocal & exit /b %\\\code%

::: "Test string if ip" "" "usage: call %~n0 iip [string]"
:::: "first parameter is empty"
:lib\iip
    if "%~1"=="" exit /b 1
    for /f "usebackq tokens=1-4 delims=." %%a in (
        '%~1'
    ) do (
        if "%~1" neq "%%a.%%b.%%c.%%d" exit /b 10
        for %%e in (
            "%%a" "%%b" "%%c" "%%d"
        ) do (
            call :lib\inum %%~e || exit /b 10
            if %%~e lss 0 exit /b 10
            if %%~e gtr 255 exit /b 10
        )
    )
    exit /b 0

REM Test mac addr
:this\imac
    setlocal enabledelayedexpansion
    for /f "usebackq tokens=1-6 delims=-:" %%a in (
        '%~1'
    ) do (
        if "%~1" neq "%%a-%%b-%%c-%%d-%%e-%%f" if "%~1" neq "%%a:%%b:%%c:%%d:%%e:%%f" exit /b 10
        for %%g in (
            "%%a" "%%b" "%%c" "%%d" "%%e" "%%f"
        ) do (
            set /a \\\hx=0x%%~g 2>nul || exit /b 10
            if !\\\hx! gtr 255 exit /b 10
        )
    )
    endlocal
    exit /b 0

::: "Test script run after pipe"
:lib\ipipe
::: "Test script start at GUI"
:lib\igui
    setlocal
    set cmdcmdline=
    set \\\cmdcmdline=%cmdcmdline:"='%
    rem "
    set \\\code=0
    if /i "%0"==":lib\ipipe" if "%\\\cmdcmdline%"=="%\\\cmdcmdline:  /S /D /c' =%" set \\\code=10
    if /i "%0"==":lib\igui" if "%\\\cmdcmdline%"=="%\\\cmdcmdline: /c ''=%" set \\\code=10
    REM if /i "%0"==":lib\igui" for %%a in (%cmdcmdline%) do if /i %%~a==/c set \\\code=0
    endlocal & exit /b %\\\code%

::: "Test this system version" "" "usage: call %~n0 ivergeq [version]"
:::: "Parameter is empty or Not a float"
:lib\ivergeq
    if "%~x1"=="" exit /b 1
    setlocal
    if exist %windir%\servicing\Version\*.* (
        for /f "usebackq tokens=1,2 delims=." %%a in (
            `dir /ad /b %windir%\servicing\Version\*.*`
        ) do for /f "usebackq tokens=1,2 delims=." %%c in (
            '%~1'
        ) do set /a \\\tmp=%%a*10+%%b-%%c*10-%%d
    ) else for /f "usebackq delims=" %%a in (
        `ver`
    ) do for %%b in (%%a) do if "%%~xb" neq "" for /f "usebackq tokens=1-4 delims=." %%c in (
        '%~1.%%b'
    ) do set /a \\\tmp=%%e*10+%%f-%%c*10-%%d
    endlocal & if %\\\tmp% geq 0 exit /b 0
    exit /b 10

::: "Test exe if live" "" "usage: %~n0 irun [exec_name]"
:::: "First parameter is empty"
:lib\irun
    REM tasklist.exe /v /FI "imagename eq %~n1.exe"
    if "%~1"=="" exit /b 1
    for /f usebackq^ tokens^=2^ delims^=^=^" %%a in (
        `wmic.exe process where caption^="%~n1.exe" get commandline /value 2^>nul`
    ) do for %%b in (
        %%a
    ) do if "%%~nb"=="%~n1" exit /b 0
    REM "
    exit /b 10

::: "Kill process" "" "usage: %~n0 lib kill [process_name...]"
:::: "first parameter is empty"
:lib\kill
    if "%~1"=="" exit /b 1
    for %%a in (
        %*
    ) do wmic.exe process where name="%%a.exe" delete

    REM for /f "usebackq skip=1" %%a in (
    REM     `wmic.exe process where "commandline like '%*'" get processid 2^>nul`
    REM ) do for %%b in (%%a) do >nul wmic.exe process where processid="%%b" delete

    REM start "" /b "%~f0" %*

    REM taskkill.exe /f /im %~1.exe
    exit /b 0

::: "Delete empty directory" "" "usage: %~n0 trimdir [dir_path]"
:::: "target not found" "target not a directory"
:lib\trimdir
    if not exist "%~1" exit /b 1
    call :lib\idir %1 || exit /b 2
    if exist %windir%\system32\sort.exe (
        call :trimdir\rdNullDirWithSort %1
    ) else call :trimdir\rdNullDir %1
    exit /b 0

REM for :lib\trimdir
:trimdir\rdNullDir
    if "%~1"=="" exit /b 0
    if "%~2"=="" (
        call %0 "%~dp1" .
        exit /b 0
    ) else for /d %%a in (
        %1*
    ) do (
        rmdir "%%~a" 2>nul || call %0 "%%~a\" .
        call %0 "%%~a\" .
    )
    exit /b 0

REM for :lib\trimdir
:trimdir\rdNullDirWithSort
    if "%~1"=="" exit /b 1
    for /f "usebackq delims=" %%a in (
        `dir /ad /b /s %1 ^| sort.exe /r`
    ) do 2>nul rmdir "%%~a"
    exit /b 0

::: "Get some backspace (erases previous character)" "" "usage: %~n0 gbs [var_name]"
:::: "string length is empty"
:lib\gbs
    if "%~1"=="" exit /b 1
    for /f %%a in ('"prompt $h & for %%a in (.) do REM"') do set %~1=%%a
    exit /b 0

::: "Unset variable, where variable name left contains" "" "usage: %~n0 uset [var_left_name]"
:::: "The parameter is empty"
:lib\uset
    if "%~1"=="" exit /b 1
    for /f "usebackq delims==" %%a in (
        `set %1 2^>nul`
    ) do set %%a=
    exit /b 0

::: "Uncompress msi file" "" "usage: %~n0 umsi [msi_file_path]"
:::: "file not found" "file format not msi" "output directory already exist"
:lib\umsi
    if not exist "%~1" exit /b 1
    if /i "%~x1" neq ".msi" exit /b 2
    mkdir ".\%~n1" 2>nul || exit /b 3
    setlocal
    REM Init
    call :lib\gfreeletter \\\letter
    subst.exe %\\\letter% ".\%~n1"

    REM Uncompress msi file
    start /wait msiexec.exe /a %1 /qn targetdir=%\\\letter%
    erase "%\\\letter%\%~nx1"
    REM for %%a in (".\%~n1") do echo output: %%~fa

    subst.exe %\\\letter% /d
    endlocal
    exit /b 0

::: "Uncompress chm file" "" "usage: %~n0 uchm [chm_path]"
:::: "chm file not found" "not chm file" "out put file allready exist"
:lib\uchm
    if not exist "%~1" exit /b 1
    if /i "%~x1" neq ".chm" exit /b 2
    if exist ".\%~sn1" exit /b 3
    start /wait hh.exe -decompile .\%~sn1 %~s1
    exit /b 0

::: "Set environment variable" "" "usage: %~n0 senvar [key] [value]"
:::: "key is empty" "value is empty"
:lib\senvar
    if "%~1"=="" exit /b 1
    if "%~2"=="" exit /b 2
    for %%a in (setx.exe) do if "%%~$path:a" neq "" setx.exe %~1 %2 /m >nul & exit /b 0
    if defined %~1 wmic.exe environment where name="%~1" set VariableValue="%~2"
    if not defined %~1 wmic.exe environment create name="%~1",username="<system>",VariableValue="%~2"
    exit /b 0

REM ::: "Delete Login Notes"
REM :lib\delLoginNote
REM     net.exe use * /delete
REM     exit /b 0

::: "Reset default path environment variable"
:lib\repath
    for /f "usebackq tokens=2 delims==" %%a in (
        `wmic.exe ENVIRONMENT where "name='path'" get VariableValue /format:list`
    ) do set path=%%a
    REM Trim unprint char
    set path=%path%
    exit /b 0

::: "Run As Administrator" "" "usage: %~n0 a [*]"
:lib\a
    REM net.exe user administrator /active:yes
    REM net.exe user administrator ???
    runas.exe /savecred /user:administrator "%*"
    exit /b 0

::: "Calculating time intervals, print use time" "" "must be run it before and after function"
:lib\centiTime
    setlocal
    set time=
    for /f "tokens=1-4 delims=:." %%a in (
        "%time%"
    ) do set /a \\\tmp=%%a*360000+1%%b%%100*6000+1%%c%%100*100+1%%d%%100
    if defined \\\centiTime (
        set /a \\\tmp-=\\\centiTime
        set /a \\\h=\\\tmp/360000,\\\min=\\\tmp%%360000/6000,\\\s=\\\tmp%%6000/100,\\\cs=\\\tmp%%100
        set \\\tmp=
    )
    if defined \\\centiTime echo %\\\h%h %\\\min%min %\\\s%s %\\\cs%cs
    endlocal & set \\\centiTime=%\\\tmp%
    exit /b 0

::: "Show Ipv4"
:lib\lip
    setlocal
    REM Get router ip
    call :this\grouteIp \\\route
    REM "
    for %%a in (
        %\\\route%
    ) do for /f usebackq^ skip^=1^ tokens^=2^ delims^=^" %%b in (
        `wmic.exe NicConfig get IPAddress`
    ) do if "%%~nb"=="%%~na" echo %%b
    endlocal
    exit /b 0



::: "Update hosts by ini"
:::: "no ini file found"
:lib\hosts
    setlocal enabledelayedexpansion
    REM load ini config
    call :this\load_ini hosts 1 || exit /b 1
    REM get key array
    call :map -ks \\\keys 1
    REM override mac to ipv4
    for /f "usebackq tokens=1*" %%a in (
        `call lib.cmd sip %\\\keys%`
    ) do call :map -p %%a %%b 1 && call :lib\2la %%~a %%b

    REM replace hosts in cache
    REM use tokens=2,3 will replace %%a
    for /f "usebackq tokens=1* delims=]" %%a in (
        `type %windir%\System32\drivers\etc\hosts ^| find.exe /n /v ""`
    ) do for /f "usebackq tokens=1-3" %%c in (
        '. %%b'
    ) do call :lib\iip %%d && (
        if defined \\\MAP1\%%e (
            for %%f in (
                !\\\MAP1\%%e!
            ) do call :lib\iip %%f && (
                set \\\line=%%b
                call :page -p !\\\line:%%d=%%f!
            ) || call :page -p %%b
            set \\\MAP1\%%e=
        ) else call :page -p %%b
    ) || call :page -p %%b

    call :map -a \\\arr 1

    for %%a in (
        %\\\arr%
    ) do (
        call :lib\iip %%a && call :page -p %%~a   !\\\key!
        set \\\key=%%~a
    )

    call :page -s > %windir%\System32\drivers\etc\hosts
    endlocal
    goto :eof

::: "Search IPv4 by MAC or Host name" "" "usage: %~n0 sip [mac]"
:::: "MAC addr or Host name is empty" "args not mac addr"
:lib\sip
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion

    REM get config
    call :this\load_ini sip_setting
    call :map -g route \\\routes
    call :map -g range \\\range
    call :map -c
    if not defined \\\range set \\\range=1-127

    call :this\load_ini hosts

    set \\\macs=

    for %%a in (
        %*
    ) do (
        set \\\arg=
        REM Get value
        call :map -g %%a \\\arg
        if defined \\\arg (
            set \\\mac=!\\\arg: =!
        ) else set \\\mac=%%a
        REM Format
        set \\\mac=!\\\mac::=-!
        REM Test is mac addr
        call :this\imac !\\\mac! && (
            set "\\\macs=!\\\macs! !\\\mac!"
            if defined \\\arg set "\\\macs=!\\\macs!\%%a"
        )
    )

    if not defined \\\macs exit /b 0

    REM Get router ip
    call :this\grouteIp \\\grouteIp
    for %%a in (
        %\\\routes% %\\\grouteIp%
    ) do if not defined \\\tmp\%%~na (
        set \\\tmp\%%~na=-
        set "\\\route=!\\\route! %%a"
    )

    REM Clear arp cache
    arp.exe -d
    REM Search MAC
    for %%a in (
        %\\\route%
    ) do for /l %%b in (
        %\\\range:-=,1,%
    ) do (
        call :this\thread_valve 50 cmd.exe ping
        start /b lib.cmd "" sip %%~na.%%b %\\\macs%
    )
    endlocal
    exit /b 0

REM nbtstat
REM For thread sip
:thread\sip
    REM some ping will fail, but arp success
    ping.exe -n 1 -w 1 %1 >nul 2>nul
    for /f "usebackq skip=3 tokens=1,2" %%a in (
        `arp.exe -a %1`
    ) do for %%c in (
        %*
    ) do for /f "usebackq tokens=1,2 delims=\" %%d in (
        '%%c'
    ) do if /i "%%b"=="%%d" if "%%e"=="" (
        call :lib\2la %%d %%a
    ) else call :lib\2la %%e %%a
    exit /b 0

REM thread valve, usage: :this\thread_valve [count] [name] [commandline]
:this\thread_valve
    set /a \\\thread\count+=1
    if %\\\thread\count% lss %~1 exit /b 0
    :thread_valve\loop
        set \\\thread\count=0
        for /f "usebackq skip=2" %%a in (
            `wmic.exe process where "name='%~2' and commandline like '%%%~3%%'" get processid 2^>nul`
        ) do if %%a gtr 0 set /a \\\thread\count+=1
        if %\\\thread\count% gtr %~1 goto thread_valve\loop
    exit /b 0

REM Map
:map
    call :this\map\%*
    goto :eof

:this\map\--put
:this\map\-p
    if "%~2"=="" exit /b 0
    set "\\\MAP%~3\%~1=%~2"
    exit /b 0

:this\map\--get
:this\map\-g
    if "%~2"=="" exit /b 0
    setlocal enabledelayedexpansion
    set \\\value=
    if defined \\\MAP%~3\%~1 call set \\\value=!\\\MAP\%~1!
    endlocal & set %~2=%\\\value%
    exit /b 0

:this\map\--remove
:this\map\-r
    set \\\MAP%~2\%~1=
    exit /b 0

:this\map\--keys
:this\map\-ks
    if "%~1"=="" exit /b 0
    setlocal enabledelayedexpansion
    set \\\keys=
    for /f "usebackq tokens=1* delims==" %%a in (
        `set \\\MAP%~2\ 2^>nul`
    ) do set "\\\keys=!\\\keys! "%%~nxa""
    endlocal & set %~1=%\\\keys%
    exit /b 0

:this\map\--values
:this\map\-vs
    if "%~1"=="" exit /b 0
    setlocal enabledelayedexpansion
    set \\\values=
    for /f "usebackq tokens=1* delims==" %%a in (
        `set \\\MAP%~2\ 2^>nul`
    ) do set "\\\values=!\\\values! "%%~b""
    endlocal & set %~1=%\\\values%
    exit /b 0

:this\map\--arr
:this\map\-a
    if "%~1"=="" exit /b 0
    setlocal enabledelayedexpansion
    set \\\kv=
    for /f "usebackq tokens=1* delims==" %%a in (
        `set \\\MAP%~2\ 2^>nul`
    ) do set "\\\kv=!\\\kv! "%%~nxa" "%%~b""
    endlocal & set %~1=%\\\kv%
    exit /b 0

:this\map\--size
:this\map\-s
    setlocal
    set \\\count=0
    for /f "usebackq tokens=1* delims==" %%a in (
        `set \\\MAP%~1\ 2^>nul`
    ) do set /a \\\count+=1
    endlocal & exit /b %\\\count%

:this\map\--clear
:this\map\-c
    call :lib\uset \\\MAP%~1\
    exit /b 0

REM page
:page
    call :this\page\%*
    goto :eof

:this\page\--put
:this\page\-p
    if not defined \\\page set \\\page=1000000000
    set /a \\\page+=1
    if .%1==. (
        set \\\page\%\\\page%=.
    ) else set \\\page\%\\\page%=.%*
    exit /b 0

:this\page\--show
:this\page\-s
    for /f "usebackq tokens=1* delims==" %%a in (
        `set \\\page\`
    ) do echo%%b
    exit /b 0

:this\pads\--clear
:this\page\-c
    call :lib\uset \\\page
    exit /b 0

REM load .*.ini config
:this\load_ini
    if "%~1"=="" exit /b 1
    set \\\tag=
    for /f "usebackq delims=; 	" %%a in (
        `type "%~dp0.*ini" "%userprofile%\.*ini" 2^>nul ^| findstr.exe /v "^;"`
    ) do for /f "usebackq tokens=1,2 delims==" %%b in (
        '%%a'
    ) do if "%%c"=="" (
        if "%%b"=="[%~1]" (
            set \\\tag=true
        ) else set \\\tag=
    ) else if defined \\\tag set \\\MAP%~2\%%b=%%c
    set \\\tag=

    REM REM Load
    REM for /f "usebackq tokens=1* delims==" %%a in (
    REM     `set`
    REM ) do if "%%~da" neq "\\" (
    REM     call :this\imac %%~b && set \\\MAP%~2\%%a=%%~b
    REM     call :lib\iip %%~b && set \\\MAP%~2\%%a=%%~b
    REM )

    call :map -s %~2 && exit /b 1
    exit /b 0

REM Get router ip
:this\grouteIp
    if "%~1"=="" exit /b 1
    REM "
    for /f usebackq^ skip^=1^ tokens^=2^ delims^=^" %%a in (
        `wmic.exe NicConfig get DefaultIPGateway`
    ) do set %1=%%a
    exit /b 0

::: "Display Time at [YYYYMMDDhhmmss]" "" "usage: %~n0 gnow [var_name] [[head_string]] [[tail_string]]"
:::: "variable name is empty"
:lib\gnow
    if "%~1"=="" exit /b 1
::: "Display Time at [YYYY-MM-DD hh:mm:ss]" "" "usage: %~n0 now [[string]]" "      nobr"
REM :lib\now
REM en zh
    set date=
    set time=
    for /f "tokens=1-8 delims=-/:." %%a in (
      "%time: =%.%date: =.%"
    ) do if %%e gtr 1970 (
        REM if /i "%0"==":lib\gnow" (
            set %~1=%~2%%e%%f%%g%%a%%b%%c%~3
        REM ) else >&3 set /p=%*[%%e-%%f-%%g %%a:%%b:%%c]<nul
    ) else if %%g gtr 1970 (
        REM if /i "%0"==":lib\gnow" (
            set %~1=%~2%%g%%e%%f%%a%%b%%c%~3
        REM ) else >&3 set /p=%*[%%g-%%e-%%f %%a:%%b:%%c]<nul
    )
    exit /b 0

::: "Path Standardize" "" "usage: %~n0 trimpath [var_name]"
:::: "variable name is empty" "variable name not defined"
:lib\trimpath
    if "%~1"=="" exit /b 1
    if not defined %~1 exit /b 2
    setlocal enabledelayedexpansion
    REM Trim quotes
    set \\\var=!%~1:"=!
    REM " Trim head/tail semicolons
    if "%\\\var:~0,1%"==";" set \\\var=%\\\var:~1%
    if "%\\\var:~-1%"==";" set \\\var=%\\\var:~0,-1%
    REM Replace slash end of path
    set \\\var=%\\\var:\;=;%;
    REM Delete path if not exist
    call :this\trimpath "%\\\var:;=" "%"
    endlocal & set %~1=%\\\var:~0,-1%
    exit  /b 0

REM for :lib\trimpath, delete path if not exist
:this\trimpath
    if "%~1"=="" exit /b 0
    if not exist %1 set \\\var=!\\\var:%~1;=!
    shift /1
    goto %0

::: "Change file/directory owner !username!" "" "usage: %~n0 own [path]"
:::: "path not found"
:lib\own
    if not exist "%~1" exit /b 1
    call :lib\idir %1 && takeown.exe /f %1 /r /d y && icacls.exe %1 /grant:r %username%:f /t /q
    call :lib\idir %1 || takeown.exe /f %1 && icacls.exe %1 /grant:r %username%:f /q
    exit /b 0

::::::::::::::::
:: PowerShell ::
::::::::::::::::

::: "Download something" "" "usage: %~n0 download [url] [output]"
:::: "url is empty" "output path is empty" "powershell version is too old"
:lib\download
    if "%~1"=="" exit /b 1
    REM if "%~2"=="" exit /b 2
    call :this\gpsv
    if errorlevel 3 PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "Invoke-WebRequest -uri %1 -OutFile %2 -UseBasicParsing" & exit /b 0
    call :lib\vbs get %1 %2
    exit /b 0

::: "Print the last some lines of FILE to standard output." "" "usage: %~n0 tail [-[count]]"
:::: "powershell version is too old" "args error"
:lib\tail
    call :this\gpsv
    if not errorlevel 3 exit /b 1
    call :this\lines -Last %*|| exit /b 2
    goto :eof

::: "Print the first some lines of FILE to standard output." "" "usage: %~n0 head [-[count]]"
:::: "powershell version is too old" "args error"
:lib\head
    call :this\gpsv
    if not errorlevel 3 exit /b 1
    call :this\lines -first %*|| exit /b 2
    goto :eof

REM for head tail
:this\lines
    setlocal
    if "%~2"=="" exit /b 1
    set \\\count=%~2
    set \\\count=%\\\count:-=%
    call :lib\inum %\\\count% || exit /b 1
    if exist "%~3" (
        PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "Get-Content \"%~3\" %~1 %\\\count%"
    ) else PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "$Input | Select-Object %~1 %\\\count%"
    endlocal
    goto :eof


::: "Print or check MD5 (128-bit) checksums." "" "usage: %~n0 md5 [file]"
:::: "powershell error"
:lib\MD5
::: "Print or check SHA1 (160-bit) checksums." "" "usage: %~n0 sha1 [file]"
:::: "powershell error"
:lib\SHA1
::: "Print or check SHA256 (256-bit) checksums." "" "usage: %~n0 sha256 [file]"
:::: "powershell error"
:lib\SHA256
    for %%a in (%0) do call :this\hash %%~na %1|| exit /b 1
    exit /b 0

:this\hash
    setlocal
    call :this\gpsv
    if not errorlevel 2 exit /b 1
    set \\\arg=-
    if exist "%~2" (
        set "\\\arg=%~2"
        for /f "usebackq" %%a in (
            `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "[System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.%~1CryptoServiceProvider).ComputeHash([System.IO.File]::Open(\"%2\",[System.IO.Filemode]::Open,[System.IO.FileAccess]::Read))).ToString() -replace \"-\""`
        ) do set \\\hash=%%a
    ) else for /f "usebackq" %%a in (
        `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "[System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.%~1CryptoServiceProvider).ComputeHash([Console]::OpenStandardInput())).ToString() -replace \"-\""`
    ) do set \\\hash=%%a
    if "%\\\hash%"=="" exit /b 2
    set \\\hash=%\\\hash:A=a%
    set \\\hash=%\\\hash:B=b%
    set \\\hash=%\\\hash:C=c%
    set \\\hash=%\\\hash:D=d%
    set \\\hash=%\\\hash:E=e%
    set \\\hash=%\\\hash:F=f%
    endlocal & echo %\\\hash%   %\\\arg%
    exit /b 0

::: "Test PowerShell version" "" "Return errorlevel"
:this\gpsv
    for %%a in (PowerShell.exe) do if "%%~$path:a"=="" exit /b 0
    for /f "usebackq" %%a in (
        `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "$PSVersionTable.WSManStackVersion.Major" 2^>nul`
    ) do exit /b %%a
    exit /b 0

::: "Run PowerShell script" "" "usage: %~n0 ps1 [ps1_script_path]"
:::: "ps1 script not found" "file suffix error"
:lib\ps1
    if not exist "%~1" exit /b 1
    if /i "%~x1" neq ".ps1" exit /b 2
    PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -File %*
    goto :eof

::: "Encode password to base64 string for unattend.xml" "" "usage: %~n0 gbase64pw [string] [[var_name]]"
:::: "System version is too old" "Args is empty"
:lib\gbase64pw
    call :lib\ivergeq 6.1 || exit /b 1
    if "%~1"=="" exit /b 2
    for /f "usebackq" %%a in (
        `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(\"%1OfflineAdministratorPassword\"))"`
    ) do if "%~2"=="" (echo %%a) else set %~2=%%a
    exit /b 0

::::::::::::::
:: VBScript ::
::::::::::::::

::: "Run some command at background"
:::: "The first parameter is empty"
:lib\dobg
    if "%~1"=="" exit /b 1
    mshta.exe VBScript:CreateObject("WScript.Shell").Run("""%~1"" %~2", 0)(Window.close)
    exit /b 0

REM screnc.exe from http://download.microsoft.com/download/0/0/7/0073477f-bbf9-4510-86f9-ba51282531e3/sce10en.exe
REM if /i "%~x1"==".vbs" screnc.exe %1 ./%~n1.vbe

::: "Run VBScript library from lib.vbs" "" "usage: %~n0 vbs [[command...]]"
:::: "lib.vbs not found"
:lib\vbs
    REM cscript.exe //nologo //e:vbscript.encode %*
    for %%a in (lib.vbs) do if "%%~$path:a"=="" (
        exit /b 1
    ) else cscript.exe //nologo "%%~$path:a" %* 2>&3 || exit /b 10
    goto :eof


::: "Zip or unzip" "" "usage: %~n0 zip [source_path] [[target_path]]"
:lib\zip
    if not exist "%~1" exit /b 1
    setlocal
    set "\\\output=.\%~n1"
    if "%~2" neq "" set "\\\output=%~2"
    REM zip
    if /i "%~x1" neq ".zip" call :lib\vbs zip "%~f1" "%\\\output%.zip"
    REM unzip
    if /i "%~x1"==".zip" call :lib\vbs unzip "%~f1" "%\\\output%"
    endlocal
    REM >.\zip.ZFSendToTarget (
    REM     echo [Shell]
    REM     echo Command=2
    REM     echo IconFile=explorer.exe,3
    REM     echo [Taskbar]
    REM     echo Command=ToggleDesktop
    REM )
    exit /b 0

:::::::::::::::::
:: advfirewall ::
:::::::::::::::::

::: "Open ssh/smb/docker port" "" "usage: %~n0 firewall [ssh/smb/docker]"
:lib\firewall
    REM ssh daemon
    if /i "%~1"=="ssh" netsh.exe advfirewall firewall add rule name="SSH" dir=in protocol=tcp localport=22 action=allow
    REM samba
    if /i "%~1"=="smb" netsh.exe advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
    REM Open docker daemon firewall
    if /i "%~1"=="docker" netsh.exe advfirewall firewall add rule name="Docker daemon " dir=in action=allow protocol=TCP localport=2376
    exit /b 0

::::::::::::::::::

::: "Create cab package"
:::: "cabarc.exe file not found"
:lib\cab
    for %%a in (cabarc.exe) do if "%%~$path:a"=="" exit /b 1

    REM By directory
    if "%~2"=="" call :lib\idir %1 && cabarc.exe -m LZX:21 n ".\%~n1.tmp" "%~1\*"&& goto cab\eof

    REM uncab
    pushd %cd%
    if "%~2"=="" if "%~x1"==".cab" mkdir ".\%~n1" && chdir /d ".\%~n1" && cabarc.exe x %1 *& goto cab\eof

    REM By file
    popd
    cabarc.exe -m LZX:21 n ".\%~n1.tmp" %*

    REM Complete
    :cab\eof
	if exist ".\%~n1.tmp" rename ".\%~n1.tmp" "%~n1.cab"
    exit /b 0


::: "Create iso file from directory" "" "usage: %~n0 udf [dir_path]"
:::: "target not directory" "not support driver" "need etfsboot.com or efisys.bin"
 :lib\udf
    for %%a in (oscdimg.exe) do if "%%~$path:a"=="" call :init\oscdimg >nul
    call :lib\idir %1 ||  exit /b 1
    if /i "%~d1\"=="%~1" exit /b 2

    REM empty name
    if "%~n1"=="" (
        setlocal enabledelayedexpansion
        set \\\args=%~1
        if "!\\\args:~-1!" neq "\" (
            call :lib\serrlv 2
        ) else call %0 "!\\\args:~0,-1!"
        endlocal & goto :eof
    )

    if exist "%~1\sources\boot.wim" (
        REM winpe iso
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 3
        if not exist %windir%\Boot\DVD\EFI\en-US\efisys.bin exit /b 3
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
        oscdimg.exe -bootdata:2#p0,e,b%windir%\Boot\DVD\PCAT\etfsboot.com#pEF,e,b%windir%\Boot\DVD\EFI\en-US\efisys.bin -yo%temp%\bootorder.txt -l"%~nx1" -o -u2 -udfver102 %1 ".\%~nx1.tmp"
        erase %temp%\bootorder.txt
    ) else if exist "%~1\I386\NTLDR" (
        REM winxp iso
        REM echo El Torito %~nx1
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 3
        oscdimg.exe -b%windir%\Boot\DVD\PCAT\etfsboot.com -k -l"%~nx1" -m -n -o -w1 %1 ".\%~nx1.tmp"
    ) else (
        REM normal iso
        REM echo oscdimg udf
        oscdimg.exe -l"%~nx1" -o -u2 -udfver102 %1 ".\%~nx1.tmp"
    )
    rename "./%~nx1.tmp" "*.iso"
    exit /b 0

REM from Window 10 aik, will download oscdimg.exe at script path
:init\oscdimg
    for %%a in (\\\%0) do if %processor_architecture:~-2%==64 (
        REM amd64
        call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk bbf55224a0290f00676ddc410f004498 fild40c79d789d460e48dc1cbd485d6fc2e

    REM x86
    ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk 5d984200acbde182fd99cbfbe9bad133 fil720cc132fbb53f3bed2e525eb77bdbc1
    exit /b 0

REM for :init\?
:this\getCab [file_name] [uri_sub] [cab] [file]
    call :lib\download http://download.microsoft.com/download/%~2/Installers/%~3.cab %temp%\%~1.cab
    expand.exe %temp%\%~1.cab -f:%~4 %temp%
    erase %temp%\%~1.cab
    move %temp%\%~4 %~dp0%~1.exe
    exit /b 0

::: "Print text skip some line" "" "usage: %~n0 skiprint [source_file_path] [skip_line_num] [target_flie_path]"
:::: "source file not found" "skip number error" "target file not found"
:lib\skiprint
    if not exist "%~1" exit /b 1
    call :lib\inum %~2 || exit /b 2
    if not exist "%~3" exit /b 3
    REM >%3 type nul
    REM for /f "usebackq skip=%~2 delims=" %%a in (
    REM     "%~f1"
    REM ) do >> %3 echo %%a
    < "%~f1" more.com +%~2 >%3
    exit /b 0

::: "Output text or read config" "" "usage: %~n0 execline [text_file_path] [skip_line]" "       need enabledelayedexpansion" "       skip must reset" "       text format: EOF [output_target] [command]"
:::: "skip line is empty" "file not found"
:lib\execline
    if "%~1"=="" exit /b 1
    if not exist "%~2" exit /b 2
    set \\\log=nul
    set "\\\exec=REM "
    for /f "usebackq skip=%~2 delims=" %%a in (
        "%~f1"
    ) do for /f "tokens=1,2*" %%b in (
        "%%a"
    ) do if "%%b"=="EOF" (
        if "%%c"=="%%~fc" if not exist "%%~dpc" (
            mkdir "%%~dpc"
        ) else if exist "%%~c" erase "%%~c"
        set "\\\log=%%~c"
        set "\\\exec=%%~d"
    ) else >>!\\\log! !\\\exec!%%~a
    set \\\log=
    set \\\exec=
    exit /b 0

REM text format for :lib\execline
EOF !temp!\!\\\now!.log "echo "
some codes
EOF nul set
a=1
EOF nul "rem "

;:: set /a 0x7FFFFFFF
;:: 2147483647 ~ -2147483647
;:: PowerShell : hyper-v install-windowsfeature server-gui-shell
;:: data:application/cab;base64,

REM :lib\sexport
REM     SecEdit.exe /export /cfg .\hisecws.inf
REM     exit /b 0
REM     SecEdit.exe /configure /db c:\Windows\Temp\hisecws.sdb /cfg c:\Windows\Temp\hisecws.inf /log c:\Windows\Temp\hisecws.log /quiet
