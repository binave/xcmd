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
::             exit /b 10

::::::::::::::::::::::::::
:: Third-Party Programs ::
::::::::::::::::::::::::::

REM init errorlevel
set errorlevel=

REM Init PATH
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

if "%~2"=="-h" call :this\annotation :%~n0\%~1 & goto :eof
if "%~2"=="--help" call :this\annotation :%~n0\%~1 & goto :eof

call :%~n0\%* 2>nul

REM Test type function
if errorlevel 10 exit /b 1
if errorlevel 1 call :this\annotation :%~n0\%* & goto :eof
exit /b 0

:3rd\
:3rd\--help
:3rd\-h
    call :this\annotation
    exit /b 0

::: "Output version and exit"
:3rd\version
    >&3 echo 0.18.3
    exit /b 0

::: "Backup git repositories"
:::: "git command not found"
:3rd\gitb
    call :this\path\--contain git.exe || exit /b 1
    setlocal enabledelayedexpansion

    for /r /d %%a in (
        hook?
    ) do if exist "%%~dpaobjects" (
        REM git repository
        set "_src=%%~dpa"
        set "_src=!_src:~0,-1!"

        REM project name
        set _name=!_src:\.git=!
        set _name=!_name:.git=!
        for %%b in ("!_name!") do set "_name=%%~nxb"

        REM get latest update version
        for /f "usebackq delims=" %%b in (
            `git.exe --git-dir^="!_src!" log -1 --all --pretty^=format:%%cd --date^=format:%%y%%m%%d%%H%%M`
        ) do set _tamp=%%b

        if defined _tamp (
            set "_out=.\!_name!_!_tamp!.git"

            if not exist "!_out!" (
                echo create bundle: !_name!
                REM git.exe --git-dir="!_src!" bundle create "!_out!" HEAD master
                git.exe --git-dir="!_src!" bundle create "!_out!" --all && git.exe bundle verify "!_out!"
                git.exe --git-dir="!_src!" gc
                echo.
            ) else echo exist: !_out!
        ) else echo skip: !_src!
    )
    endlocal
    exit /b 0


::: "Oracle service start\stop"
:::: "Sid is empty, default is orcl"
:3rd\orcl
    if "%~1"=="" exit /b 1
    setlocal
    set _sid=OracleService%~1
    for /f "usebackq tokens=1,3" %%a in (
        `sc.exe query %_sid%`
    ) do if /i "%%a"=="STATE" (
        set _srv=OracleOraDb11g_home1TNSListener
        if "%%b"=="4" (
            call :orcl\setService
            call :orcl STOP START
        ) else call :orcl START STOP
    )
    if not defined _srv >&2 echo Error: No %_sid% Service
    echo.
    endlocal
    exit /b 0

REM For :3rd\orcl
:orcl
    echo Oracle Service allready %~2, Press {Enter} to %~1
    set /p _input=or type any characters to EXIT.
    if defined _input exit /b 0
    echo.
    net.exe %1 %_srv%
    net.exe %1 %_sid%
    exit /b 0

REM For :3rd\orcl
:orcl\setService
    for /f "usebackq tokens=1,3" %%a in (
        `sc.exe qc %_srv%`
    ) do if /i "%%a%%b" == "START_TYPE2" >nul (
        for %%c in (
            %_srv% %_sid%
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

REM ::: "Get docker tags" "" "    %~n0 tags [image_name]"
REM :::: "no bash.exe found, need install git for windows, and add it in environment variabl"
REM :3rd\tags
REM     for %%a in (bash.exe) do if "%%~$path:a"=="" exit /b 1
REM     for /f "usebackq tokens=2,4 " %%a in (
REM         `bash.exe -c 'curl https://index.docker.io/v1/repositories/%1/tags 2^>nul ^^^| sed -e "s/\}, /\n/g;s/,//g;s/\}\]//g"`
REM     ) do echo %%~a %1:%%~b
REM     exit /b 0

::: "VirtualBox Manage" "" "usage: %~n0 vbox [args] [[vm_name]]" "" "    start       Start VM by name" "    stop/save   Stop VM by name" "    stopAll     Stop all vm"
:::: "need install vbox" "No eula text found"
:3rd\vbox
    setlocal enabledelayedexpansion
    REM Add vbox path
    set path=%path%;%VBOX_MSI_INSTALL_PATH%
    REM Test VBoxManage command
    call :this\path\--contain VBoxManage.exe || exit /b 1

    call :this\vbox\%* 2>nul
    if %errorlevel%==1 if "%~2"=="" call :this\vbox\start %*
    endlocal & exit /b %errorlevel%

REM List all VM name, tag running VM
REM todo MAC VBoxManage.exe showvminfo %_vms% --machinereadable | find "macaddress"
:this\vbox\
    call :vbox\setVar vms _vms
    call :vbox\setVar runningvms _run
    for /f "usebackq delims==" %%a in (
        `set _vms 2^>nul`
    ) do if defined _run\%%~nxa (
        call :this\txt\--all-col-left %%~nxa
        call :this\txt\--all-col-left (running^)
        echo.
    ) else echo %%~nxa
    REM call :this\txt\--all-col-left 0 0
    exit /b 0

REM Start VM
:this\vbox\start
    call :vbox\init %1 || exit /b 0
    if defined _run\%vm% (
        echo %vm% is running...
    ) else VBoxManage.exe startvm %vm% -type headless
    exit /b 0

REM Stop VM
:this\vbox\stop
REM :this\vbox\save
    call :vbox\init %1 || exit /b 0
    if defined _run\%vm% (
        VBoxManage.exe controlvm %vm% poweroff
    ) else echo %vm% not running...
    exit /b 0

REM Stop All VM
:this\vbox\stopAll
    for /f "usebackq" %%a in (
        `VBoxManage.exe list runningvms`
    ) do VBoxManage.exe controlvm %%~a poweroff
    echo All vm stop
    exit /b 0

REM Set vm variable
:vbox\init
    if "%1"=="" exit /b 1
    REM Init variable
    call :vbox\setVar vms _vms
    call :vbox\setVar runningvms _run
    REM sort name auto complete
    set vm=
    set i=0
    for /f "usebackq delims==" %%a in (
        `set _vms\%1 2^>nul`
    ) do (
        set /a i+=1
        if !i!==2 call :this\txt\--all-col-left !vm!
        set vm=%%~nxa
        if !i! gtr 1 call :this\txt\--all-col-left %%~nxa
    )
    REM make all column left-aligned over
    call :this\txt\--all-col-left 0 0
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

::: "Convert alac,ape,m4a,tta,tak,wav to flac format" "" "    need changes the current directory at target"
:::: "ffmpeg command not found"
:3rd\2flac
    call :this\path\--contain ffmpeg.exe || exit /b 1
    pushd "%cd%"
    for /r . %%a in (
        *.alac *.ape *.m4a *.tta *.tak *.wav
    ) do cd /d "%%~dpa" && (
        echo cd /d %%~dpa
        if not exist .\"%%~na.flac" ffmpeg.exe -hide_banner -i ".\%%~nxa" -acodec flac ".\%%~na.flac" 2>&1
    )
    popd
    exit /b 0

::: "Play all multi-media in directory" "" "usage: %~n0 play [options] ... [directory...]" "" "    --random, -r" "    --ast,    -a " "    --skip,   -j [count]"
:::: "ffplay command not found" "args is empty"
:3rd\play
    call :this\path\--contain ffplay.exe || exit /b 1
    if "%~1"=="" exit /b 2
    setlocal enabledelayedexpansion
    set _media=
    set _random=
    set _stream_specifier=
    set _skip=
:play\args
    if /i "%~1"=="--random" set _random=RANDOM
    if /i "%~1"=="-r" set _random=RANDOM
    REM -ast stream_specifier  select desired audio stream
    if /i "%~1"=="--ast" call :this\is\--integer %~2 && set "_stream_specifier=-ast %~2"& shift /1
    if /i "%~1"=="-a" call :this\is\--integer %~2 && set "_stream_specifier=-ast %~2"& shift /1
    if /i "%~1"=="--skip" call :this\is\--integer %~2 && set "_skip=%~2"& shift /1
    if /i "%~1"=="-j" call :this\is\--integer %~2 && set "_skip=%~2"& shift /1
    call :this\dir\--isdir %1 && set _media=%_media% "%~1"
    shift /1
    if "%~1" neq "" goto play\args

    set _c=1000000000
    set /a _skip+=_c
    for %%a in (
        %_media%
    ) do (
        pushd "%cd%"
        cd /d "%%~a"
        if defined _random (
            for /r %%b in (
                *.alac *.ape *.avi *.divx *.flac *.flv *.m4a *.mkv *.mp? *.ogg *.rm *.rmvb *.tta *.tak *.vob *.wav *.webm *.wm?
            ) do (
                set /a _c+=1
                set "_track!random!=%%b"
            )
        ) else (
            for /f "usebackq delims=" %%b in (
                `dir /b /s /on *.alac *.ape *.avi *.divx *.flac *.flv *.m4a *.mkv *.mp? *.ogg *.rm *.rmvb *.tta *.tak *.vob *.wav *.webm *.wm?`
            ) do (
                set /a _c+=1
                if !_c! geq %_skip% set "_track!_c!=%%b"
            )
        )
        popd
    )
    set /a _c=%_c% %% 1000000000, _i=%_skip% %% 1000000000

    for /f "usebackq tokens=2 delims==" %%a in (
        `set _track 2^>nul`
    ) do set /a _i+=1& call :this\ffplay "%%a"

    endlocal
    exit /b 0

:this\ffplay
    echo Progress #%_i% / %_c%, %_random%
    REM -sn ::disable subtitling
    REM -ac 2 ::ED..A... set number of audio channels (from 0 to INT_MAX) (default 0) ::Convert the 5.1 track to stereo
    for %%a in (
        avi divx flv mkv mp4 mpg rm rmvb vob webm wmv
    ) do if /i "%~x1"==".%%a" ffplay.exe -hide_banner %_stream_specifier% -ac 2 -sn -autoexit -af "volume=0.85" %1 2>&1
    for %%a in (
        alac ape flac m4a mp3 ogg tta tak wav wma
    ) do if /i "%~x1"==".%%a" start /b /wait /min ffplay.exe -hide_banner -autoexit -af "volume=0.05" %1 2>&1
    exit /b 0

REM :3rd\lcam
REM     ffmpeg.exe -hide_banner -f dshow -list_devices true -i "" 2>&1 | find.exe "]"
REM     exit /b 0

REM :3rd\scam
REM     ffplay.exe -hide_banner -f dshow -video_size $size -framerate 25 -pixel_format 0rgb -probesize 10M -i "0":"0" 2>&1
REM     exit /b 0

::: "Convert dvd" "" "usage: %~n0 vob2 [drive:] [output_file_path]" "  e.g. %~n0 vob2 D: E:\out.mkv
:::: "ffmpeg command not found" "output path not found" "no output suffix"
:3rd\vob2
    call :this\path\--contain ffmpeg.exe || exit /b 1
    if not exist "%~dp2" exit /b 2
    if "%~x2"=="" exit /b 3
    REM if /i "%~d1"=="%~d2" exit /b 4
    setlocal enabledelayedexpansion
    set _src=
    for /f "usebackq delims=" %%a in (
        `dir /b %~d1\VTS_01_*.VOB`
    ) do if defined _src (
        set _src=!_src!^|%~d1\%%a
    ) else set _src=%~d1\%%a
    endlocal & ffmpeg.exe -hide_banner -i concat:"%_src%" "%~f2"
    goto :eof

::: "Package vm to ova format" "" "usage: %~n0 ova [vm_name] [eula_file_path]"
:::: "vm name is empty" "eula file not found" "need install vbox"
:3rd\ova
    if "%~1"=="" exit /b 1
    if not exist "%~2" exit /b 2
    setlocal enabledelayedexpansion
    REM Add vbox path
    set path=%path%;%VBOX_MSI_INSTALL_PATH%
    REM Test VBoxManage command
    call :this\path\--contain VBoxManage.exe || exit /b 3

    call :vbox\init %1 && VBoxManage.exe export %vm% -o ".\%vm%.ova" --legacy09 --manifest --options nomacs --vsys 0 --eulafile %2
    endlocal
    exit /b 0

::: "Docker batch command" "Usage: %~n0 docker [start/stop]"
:::: "option invalid" "docker client command not found"
:3rd\docker
    call :this\path\--contain docker.exe || exit /b 2
    call :this\docker\%* 2>nul
    goto :eof

:this\docker\start
    for /f "usebackq skip=1" %%a in (
        `docker.exe ps -f status=exited`
    ) do docker.exe start %%a
    exit /b 0

:this\docker\stop
    for /f "usebackq skip=1" %%a in (
        `docker.exe ps`
    ) do docker.exe stop %%a
    exit /b 0

::: "Compress PNG images" "Usage: %~n0 png [src_dir] [out_dir]" "" "    [WARN] only support ascii name"
:::: "option invalid" "pngquant command not found" "source path not exist" "output path not set" "out put dir is same" "pngquant error"
:3rd\png
    call :this\path\--contain pngquant.exe || exit /b 2
    if not exist "%~f1" exit /b 3
    if "%~2"=="" exit /b 4
    if /i "%~f1"=="%~f2" exit /b 5

    setlocal enabledelayedexpansion
    set "_src=%~f1"
    set "_out=%~f2"
    if "%_src:~-1%"=="\" set "_src=%_src:~0,-1%"
    if "%_out:~-1%"=="\" set "_out=%_out:~0,-1%"

    for /r %1 %%a in (
        *.png
    ) do set "_tag=%%~dpa"& call ^
        set "_tag=%_out%\!_tag:%_src%\=!"& (
        echo.
        if not exist "!_tag!" mkdir "!_tag!"
    ) & 2>&1 pngquant.exe --quality 70-90 --speed 1 --strip --verbose --output "!_tag!%%~nxa" "%%~fa"
    endlocal
    exit /b 0

::: "tar.gz compresses by 7za" "" "Usage: %~n0 tar.gz [path]"
:::: "7za not fount" "target not found"
:3rd\tar.gz
::: "tar.bz2 compresses by 7za" "" "Usage: %~n0 tar.bz2 [path]"
:::: "7za not fount" "target not found"
:3rd\tar.bz2
    call :this\path\--contain 7za.exe || exit /b 1
    setlocal enabledelayedexpansion
    if not exist "%~1" exit /b 2
	if "%~2"=="" call :this\equalsDeputySuffix %1 .tar && (
		call :this\tarDecompresses %1
		goto :eof
	)
	for %%a in (%0) do set _suffix=%%~nxa
	set _suffix=%_suffix:~4%
	call :this\tarCompresses %*
    endlocal
    exit /b 0

REM for :3rd\tar.*
:this\tarCompresses
	if not defined _tarName set _tarName=%~n1
	if "%~2"=="" call :this\dir\--isdir %1 || for %%a in (
		7z cab rar zip
	) do if /i "%~x1"==".%%~a" (
		pushd %cd%
		call :this\str\--now _nowTar && set _nowTar=%temp%\!_nowTar!
		mkdir !_nowTar! && chdir /d !_nowTar! && 7za.exe x %1 -aoa
		popd
		call %0 !_nowTar!\*
		rmdir /s /q !_nowTar! && set _nowTar=
		goto :eof
	)
	7za.exe a dummy -ttar -so %* | 7za.exe a -si -t%_suffix:z=zip% "!_tarName!.tar.%_suffix%" -aoa
	set _tarName=
	goto :eof

REM for :3rd\tar.*
:this\tarDecompresses
	for %%a in ("%~n1") do (
		7za.exe x %1 -so | 7za.exe x -si -ttar -o. -aoa
		REM call :this\molting ".\%%~na" %2
	)
	goto :eof

REM REM for :this\tarDecompresses
REM :this\molting
REM 	if "%~1"=="" goto :eof
REM 	REM if "%~2"=="" goto :eof
REM 	for /f "usebackq delims=" %%a in (
REM 		`dir /a /b "%~1"`
REM 	) do if not defined _molting (
REM 		call :this\dir\--isdir "%~1\%%a" || goto :eof
REM 		set "_molting=%%a"
REM 	) else set _molting= & goto :eof
REM 	call :this\str\--now _nowM && rename "%~1" !_nowM!
REM 	>nul move /y "%~dp1!_nowM!\!_molting!" "%~dp1" && rmdir /s /q "%~dp1!_nowM!"
REM 	set _nowM=
REM 	REM set "%~2=%~dp1!_molting!"
REM 	set _molting=
REM 	REM call %0 "!%~2!" %~2
REM 	goto :eof

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

::::::::::::::::::
::     Base     ::
  :: :: :: :: ::

REM Test target in $path
:this\path\--contain
    if "%~1" neq "" if "%~$path:1" neq "" exit /b 0
    exit /b 1

REM Test string if Num \* @see lib.cmd *\
:this\is\--integer
    if "%~1"=="" exit /b 10
    setlocal
    set _tmp=
    REM quick return
    2>nul set /a _code=10, _tmp=%~1
    if "%~1"=="%_tmp%" set _code=0
    endlocal & exit /b %_code%

REM Test path is directory \* @see dis.cmd *\
:this\dir\--isdir
    setlocal
    set _path=%~a1-
    REM quick return
    set _code=10
    if %_path:~0,1%==d set _code=0
    endlocal & exit /b %_code%

REM Display Time at [YYYYMMDDhhmmss] \* @see lib.cmd *\
:this\str\--now
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

  :: :: :: :: ::
::     Base     ::
::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::
::                 Framework                 ::
   :: :: :: :: :: :: :: :: :: :: :: :: :: ::

REM Show INFO or ERROR
:this\annotation
    setlocal enabledelayedexpansion & call :this\var\--set-errorlevel %errorlevel%
    for /f "usebackq skip=62 tokens=1,2* delims=\ " %%a in (
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
    call :this\cols _col
    set /a _i=0, _col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (
        `set _args\%~n1 2^>nul`
    ) do if "%~1" neq "" (
        REM " Sort func name expansion
        set /a _i+=1
        set _target=%%~nxa %2 %3 %4 %5 %6 %7 %8 %9
        if !_i!==1 set _tmp=%%~nxa
        if !_i!==2 call :this\txt\--all-col-left !_tmp! %_col%
        if !_i! geq 2 call :this\txt\--all-col-left %%~nxa %_col%
    ) else call :this\str\--2col-left %%~nxa "%%~b"
    REM Close make all column left-aligned
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

REM Make the second column left-aligned
:this\str\--2col-left
    if "%~2"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    echo %~1!_spaces:~0,%_len%!%~2
    endlocal
    exit /b 0

REM Use right pads spaces, make all column left-aligned
:this\txt\--all-col-left
    if "%~1"=="" exit /b 1
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

REM for :this\txt\--all-col-left
:strModulo
    set /a _acl+=1
    set _str=%_str:~15%
    if "%_str:~31,1%"=="" exit /b 0
    goto %0

REM Get cmd cols
:this\cols
    for /f "usebackq skip=4 tokens=2" %%a in (`mode.com con`) do (
        if "%~1"=="" (
            echo %%a
        ) else set %~1=%%a
        exit /b 0
    )
    exit /b 0

REM Set errorlevel variable
:this\var\--set-errorlevel
    if "%~1"=="" goto :eof
    exit /b %1

   :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::                 Framework                 ::
:::::::::::::::::::::::::::::::::::::::::::::::
