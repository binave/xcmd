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
:: Third-Party Programs ::
::::::::::::::::::::::::::

REM Init PATH
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

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
    setlocal enabledelayedexpansion & call :serrlv %errorlevel%
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
                    call :serrlv %errorlevel%
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
    call :this\gcols \\\col
    set /a \\\i=0, \\\col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (
        `set \\\args\%~n1 2^>nul`
    ) do if "%~1" neq "" (
        REM " Sort func name expansion
        set /a \\\i+=1
        set \\\target=%%~nxa %2 %3 %4 %5 %6 %7 %8 %9
        if !\\\i!==1 set \\\tmp=%%~nxa
        if !\\\i!==2 call :this\rpad !\\\tmp! %\\\col%
        if !\\\i! geq 2 call :this\rpad %%~nxa %\\\col%
    ) else call :this\2la %%~nxa "%%~b"
    REM Close rpad
    if !\\\i! gtr 0 call :this\rpad 0 0
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

REM Make the second column left-aligned
:this\2la
    if "%~2"=="" exit /b 1
    setlocal enabledelayedexpansion
    set \\\str=%~10123456789abcdef
    if "%\\\str:~31,1%" neq "" call :strModulo
    set /a \\\len=0x%\\\str:~15,1%
    set "\\\spaces=                "
    echo %~1!\\\spaces:~0,%\\\len%!%~2
    endlocal
    exit /b 0

REM Use right pads spaces, make all column left-aligned
:this\rpad
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

REM for :this\rpad
:strModulo
    set /a \\\rpad+=1
    set \\\str=%\\\str:~15%
    if "%\\\str:~31,1%"=="" exit /b 0
    goto %0

REM Get cmd cols
:this\gcols
    for /f "usebackq skip=4 tokens=2" %%a in (`mode.com con`) do (
        if "%~1"=="" (
            echo %%a
        ) else set %~1=%%a
        exit /b 0
    )
    exit /b 0

REM Set errorlevel variable
:serrlv
    if "%~1"=="" goto :eof
    exit /b %1

:: :: :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::                 Framework                 ::
:::::::::::::::::::::::::::::::::::::::::::::::

REM Test target in $path
:this\iinpath
    if "%~1"=="" exit /b 1
    if "%~$path:1" neq "" exit /b 0
    exit /b 1

::: "Oracle service start\stop"
:::: "Sid is empty, default is orcl"
:3rd\orcl
    if "%~1"=="" exit /b 1
    setlocal
    set \\\sid=OracleService%~1
    for /f "usebackq tokens=1,3" %%a in (
        `sc.exe query %\\\sid%`
    ) do if /i "%%a"=="STATE" (
        set \\\srv=OracleOraDb11g_home1TNSListener
        if "%%b"=="4" (
            call :orcl\setService
            call :orcl STOP START
        ) else call :orcl START STOP
    )
    if not defined \\\srv >&2 echo Error: No %\\\sid% Service
    echo.
    endlocal
    exit /b 0

REM For :3rd\orcl
:orcl
    echo Oracle Service allready %~2, Press {Enter} to %~1
    set /p \\\input=or type any characters to EXIT.
    if defined \\\input exit /b 0
    echo.
    net.exe %1 %\\\srv%
    net.exe %1 %\\\sid%
    exit /b 0

REM For :3rd\orcl
:orcl\setService
    for /f "usebackq tokens=1,3" %%a in (
        `sc.exe qc %\\\srv%`
    ) do if /i "%%a%%b" == "START_TYPE2" >nul (
        for %%c in (
            %\\\srv% %\\\sid%
        ) do sc.exe config %%c start= demand
        for %%c in (
			OracleVssWriterORCL
			OracleDBConsoleorcl
			OracleJobSchedulerORCL
			OracleMTSRecoveryService
			OracleOraDb11g_home1ClrAgent
		) do sc.exe config %%c start= disabled
    )
    exit /b 0

::: "Get docker tags" "" "    %~n0 tags [image_name]"
:::: "no bash.exe found, need install git for windows, and add it in environment variabl"
:3rd\tags
    for %%a in (bash.exe) do if "%%~$path:a"=="" exit /b 1
    for /f "usebackq tokens=2,4 " %%a in (
        `bash.exe -c 'curl https://index.docker.io/v1/repositories/%1/tags 2^>nul ^^^| sed -e "s/\}, /\n/g;s/,//g;s/\}\]//g"`
    ) do echo %%~a %1:%%~b
    exit /b 0

::: "VirtualBox Manage" "" "usage: %~n0 vbox [args] [[vm_name]]" "" "    start       Start VM by name" "    stop/save   Stop VM by name" "    stopAll     Stop all vm"
:::: "need install vbox" "No eula text found"
:3rd\vbox
    setlocal enabledelayedexpansion
    REM Add vbox path
    set path=%path%;%VBOX_MSI_INSTALL_PATH%
    REM Test VBoxManage command
    call :this\iinpath VBoxManage.exe || exit /b 1

    call :this\vbox\%* 2>nul
    if %errorlevel%==1 if "%~2"=="" call :this\vbox\start %*
    endlocal & exit /b %errorlevel%

REM List all VM name, tag running VM
:this\vbox\
    call :vbox\setVar vms \\\vms
    call :vbox\setVar runningvms \\\run
    for /f "usebackq delims==" %%a in (
        `set \\\vms 2^>nul`
    ) do if defined \\\run\%%~nxa (
        call :this\rpad %%~nxa
        call :this\rpad (running^)
        echo.
    ) else echo %%~nxa
    REM call :this\rpad 0 0
    exit /b 0

REM Start VM
:this\vbox\start
    call :vbox\init %1 || exit /b 0
    if defined \\\run\%vm% (
        echo %vm% is running...
    ) else VBoxManage.exe startvm %vm% -type headless
    exit /b 0

REM Stop VM
:this\vbox\stop
:this\vbox\save
    call :vbox\init %1 || exit /b 0
    if defined \\\run\%vm% (
        VBoxManage.exe controlvm %vm% savestate
    ) else echo %vm% not running...
    exit /b 0

REM Stop All VM
:this\vbox\stopAll
    for /f "usebackq" %%a in (
        `VBoxManage.exe list runningvms`
    ) do VBoxManage.exe controlvm %%~a savestate
    echo All vm stop
    exit /b 0

REM Set vm variable
:vbox\init
    if "%1"=="" exit /b 1
    REM Init variable
    call :vbox\setVar vms \\\vms
    call :vbox\setVar runningvms \\\run
    REM sort name auto complete
    set vm=
    set i=0
    for /f "usebackq delims==" %%a in (
        `set \\\vms\%1 2^>nul`
    ) do (
        set /a i+=1
        if !i!==2 call :this\rpad !vm!
        set vm=%%~nxa
        if !i! gtr 1 call :this\rpad %%~nxa
    )
    REM rpad over
    call :this\rpad 0 0
    if %i%==1 (
        exit /b 0
    ) else if %i% gtr 1 (
        >&2 echo Error: name conflict
    ) else >&2 echo Error: no name found
    exit /b 1

REM Reg VM names
:vbox\setvar
    for /f "usebackq tokens=1,2" %%a in (
        `VBoxManage.exe list %1`
    ) do set %2\%%~a=%%b
    exit /b 0

::::::::::::
:: ffmpeg ::
::::::::::::

::: "Convert alac,ape,m4a,tta,tak,wav to flac format" "need changes the current directory at target"
:::: "ffmpeg command not found"
:3rd\cflac
    call :this\iinpath ffmpeg.exe || exit /b 1
    pushd "%cd%"
    for /r . %%a in (
        *.alac *.ape *.m4a *.tta *.tak *.wav
    ) do cd /d "%%~dpa" && (
        echo cd /d %%~dpa
        if not exist .\"%%~na.flac" ffmpeg.exe -i ".\%%~nxa" -acodec flac ".\%%~na.flac" 2>&1
    )
    popd
    exit /b 0

::: "Play all multi-media in directory" "" "usage: %~n0 ffplay [path] [[audio_specifier]]"
:::: "ffplay command not found" "args is empty" "lib.cmd not found"
:3rd\ffplay
    call :this\iinpath ffplay.exe || exit /b 1
    if "%~1"=="" exit /b 2
    call :this\iinpath lib.cmd || exit /b 3
    setlocal
    REM -ast stream_specifier  select desired audio stream
    call lib.cmd inum %~2 && set "\\\stream_specifier=-ast %~2"
    call lib.cmd iDir %1 && for /r "%~1" %%a in (
        *.alac *.ape *.avi *.divx *.flac *.flv *.m4a *.mkv *.mp? *.ogg *.rm *.rmvb *.tta *.tak *.vob *.wav *.wm?
    ) do call :this\ffplay "%%a"
    call lib.cmd iDir %1 || call :this\ffplay %1
    endlocal
    exit /b 0

:this\ffplay
    REM -sn ::disable subtitling
    REM -ac 2 ::ED..A... set number of audio channels (from 0 to INT_MAX) (default 0) ::Convert the 5.1 track to stereo
    for %%a in (
        avi divx flv mkv mp4 mpg rm rmvb vob wmv
    ) do if /i "%~x1"==".%%a" ffplay.exe %\\\stream_specifier% -ac 2 -sn -autoexit %1
    for %%a in (
        alac ape flac m4a mp3 ogg tta tak wav wma
    ) do if /i "%~x1"==".%%a" start /b /wait /min ffplay.exe -autoexit %1
    exit /b 0

REM :3rd\lcam
REM     ffmpeg.exe -f dshow -list_devices true -i "" 2>&1 | find.exe "]"
REM     exit /b 0

REM :3rd\scam
REM     ffplay -f dshow -video_size $size -framerate 25 -pixel_format 0rgb -probesize 10M -i "0":"0" 2>&1
REM     exit /b 0

::: "Package vm to ova format" "" "usage: %~n0 ova [vm_name] [eula_file_path]"
:::: "vm name is empty" "eula file not found" "need install vbox"
:3rd\ova
    if "%~1"=="" exit /b 1
    if not exist "%~2" exit /b 2
    setlocal enabledelayedexpansion
    REM Add vbox path
    set path=%path%;%VBOX_MSI_INSTALL_PATH%
    REM Test VBoxManage command
    call :this\iinpath VBoxManage.exe || exit /b 3

    call :vbox\init %1 && VBoxManage.exe export %vm% -o ".\%vm%.ova" --legacy09 --manifest --options nomacs --vsys 0 --eulafile %2
    endlocal
    exit /b 0

::: "Docker batch command" "Usage: %~n0 dockers [start/stop]"
:::: "option invalid" "docker client command not found"
:3rd\dockers
    call :this\iinpath docker.exe || exit /b 2
    call :this\dockers\%* 2>nul
    goto :eof

:this\dockers\start
    for /f "usebackq skip=1" %%a in (
        `docker.exe ps -f status=exited`
    ) do docker.exe start %%a
    exit /b 0

:this\dockers\stop
    for /f "usebackq skip=1" %%a in (
        `docker.exe ps`
    ) do docker.exe stop %%a
    exit /b 0

::: "tar.gz compresses by 7za" "" "Usage: %~n0 tar.gz [path]"
:::: "7za not fount" "target not found" "lib.cmd not found"
:3rd\tar.gz
::: "tar.bz2 compresses by 7za" "" "Usage: %~n0 tar.bz2 [path]"
:::: "7za not fount" "target not found" "lib.cmd not found"
:3rd\tar.bz2
    call :this\iinpath 7za.exe || exit /b 1
    setlocal enabledelayedexpansion
    if not exist "%~1" exit /b 2
    call :this\iinpath lib.cmd || exit /b 3
	if "%~2"=="" call :this\equalsDeputySuffix %1 .tar && (
		call :this\tarDecompresses %1
		goto :eof
	)
	set \\\suffix=%0
	set \\\suffix=%\\\suffix:~5%
	call :this\tarCompresses %*
    endlocal
    exit /b 0

REM for :3rd\tar.*
:this\tarCompresses
	if not defined \\\tarName set \\\tarName=%~n1
	if "%~2"=="" call lib.cmd iDir %1 || for %%a in (
		7z cab rar zip
	) do if /i "%~x1"==".%%~a" (
		pushd %cd%
		call lib.cmd gNow \\\nowTar && set \\\nowTar=%temp%\!\\\nowTar!
		mkdir !\\\nowTar! && chdir /d !\\\nowTar! && 7za.exe x %1 -aoa
		popd
		call %0 !\\\nowTar!\*
		rmdir /s /q !\\\nowTar! && set \\\nowTar=
		goto :eof
	)
	7za.exe a dummy -ttar -so %* | 7za.exe a -si -t%\\\suffix:z=zip% "!\\\tarName!.tar.%\\\suffix%" -aoa
	set \\\tarName=
	goto :eof

REM for :3rd\tar.*
:this\tarDecompresses
	for %%a in ("%~n1") do (
		7za.exe x %1 -so | 7za.exe x -si -ttar -o"%%~na" -aoa
		call :this\molting ".\%%~na" %2
	)
	goto :eof

REM for :this\tarDecompresses
:this\molting
	if "%~1"=="" goto :eof
	REM if "%~2"=="" goto :eof
	for /f "usebackq delims=" %%a in (
		`dir /a /b "%~1"`
	) do if not defined \\\molting (
		call lib.cmd iDir "%~1\%%a" || goto :eof
		set "\\\molting=%%a"
	) else set \\\molting= & goto :eof
	call lib.cmd gNow \\\nowM && rename "%~1" !\\\nowM!
	>nul move /y "%~dp1!\\\nowM!\!\\\molting!" "%~dp1" && rmdir /s /q "%~dp1!\\\nowM!"
	set \\\nowM=
	REM set "%~2=%~dp1!\\\molting!"
	set \\\molting=
	REM call %0 "!%~2!" %~2
	goto :eof

REM for :3rd\tar.*
:this\equalsDeputySuffix
	for %%a in (
		"%~n1"
	) do if /i "%%~xa"=="%~2" exit /b 0
	exit /b 1


::: "Init golang"
:::: "go or git not in path" "Not a golang path"
:3rd\goinit
    for %%a in (go.exe git.exe) do if "%%~$path:a"=="" exit /b 1
    call :go\isGoPath || exit /b 2
    set GOPATH=%cd%
    if not exist .\bin\gocode.exe go.exe get -u -v github.com/nsf/gocode
    if not exist .\bin\godef.exe go.exe get -u -v github.com/rogpeppe/godef
    if not exist .\bin\golint.exe go.exe get -u -v github.com/golang/lint/golint
    if not exist .\bin\go-outline.exe go.exe get -u -v github.com/lukehoban/go-outline
    if not exist .\bin\goreturns.exe go.exe get -u -v sourcegraph.com/sqs/goreturns
    if not exist .\bin\gorename.exe go.exe get -u -v golang.org/x/tools/cmd/gorename
    if not exist .\bin\gopkgs.exe go.exe get -u -v github.com/tpng/gopkgs
    if not exist .\bin\go-symbols.exe go.exe get -u -v github.com/newhook/go-symbols
    if not exist .\bin\guru.exe go.exe get -u -v golang.org/x/tools/cmd/guru
    REM https://github.com/derekparker/delve/tree/master/Documentation/installation
    if not exist .\bin\dlv.exe go.exe get -u -v github.com/derekparker/delve/cmd/dlv
    exit /b 0

REM Test go file
:go\isGoPath
    for /r .\src %%a in (*.go) do exit /b 0
    exit /b 1

REM :3rd\ftp
REM 	>%temp%\.bb315509-cf9c-5caa-c096-24d258c3d95d (
REM 		call :this\ftpInit [ip] [name] [password] [dir]
REM 		if "%~1"=="" (
REM 			call :this\ftpDir
REM 		) else call :this\ftpUpload %*
REM 	)
REM  	ftp.exe -s:%temp%\.bb315509-cf9c-5caa-c096-24d258c3d95d
REM  	erase %temp%\.bb315509-cf9c-5caa-c096-24d258c3d95d
REM     exit /b 0

REM :this\ftpInit
REM 	echo open %~1
REM 	echo %~2
REM 	echo %3
REM 	echo cd %4
REM 	goto :eof

REM :this\ftpUpload
REM 	echo binary
REM 	for %%a in (
REM 		%*
REM 	) do if exist "%%~a" echo put "%%~a"
REM 	echo close
REM 	echo quit
REM 	goto :eof

REM :this\ftpDir
REM 	echo dir
REM 	echo quit
REM 	goto :eof
