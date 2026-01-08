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
::     If the function names conform to the specifications:
::         External call function. (Support short name completion)
::         Error handling.
::         Display help information.
::         Print the functions list.
::
::     e.g.
::         ::: "[brief_introduction]" "" "[description]" ...
::         :[script_name_without_suffix]\[function_name]
::             ...
::             @REM call sub function
::             call :sub\[function_name]\%*
::             ...
::             @REM return false status
::             exit /b -1
::
::         ::: "[description_sub_function]" ...
::         :sub\[function_name]\[--arg]
::             ...
::             @REM exit and display [error_description_1]
::             exit /b 2 @REM [error_description_1]

::::::::::::::::::::::::::
:: Third-Party Programs ::
::::::::::::::::::::::::::

@REM init errorlevel
set errorlevel=

@REM Init PATH
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

if "%~2"=="-h" call :this\annotation :%~n0\%~1 & goto :eof
if "%~2"=="--help" call :this\annotation :%~n0\%~1 & goto :eof

2>nul call :%~n0\%*

if not errorlevel 0 exit /b 1

@REM Test type function
if errorlevel 1 call :this\annotation :%~n0\%* & goto :eof
exit /b 0

:x3rd\
:x3rd\--help
:x3rd\-h
    call :this\annotation
    exit /b 0

::: "Output version and exit"
:x3rd\version
    >&3 echo 0.21.4.11
    exit /b 0

::: "Backup git repositories"
:x3rd\gitb
    call :sub\path\--contain git.exe || exit /b 2 @REM git command not found
    setlocal enabledelayedexpansion

    for /r /d %%a in (
        hook?
    ) do if exist "%%~dpaobjects" (
        @REM git repository
        set "_src=%%~dpa"
        set "_src=!_src:~0,-1!"

        @REM project name
        set _name=!_src:\.git=!
        set _name=!_name:.git=!
        for %%b in ("!_name!") do set "_name=%%~nxb"

        @REM get latest update version
        for /f "usebackq delims=" %%b in (
            `git.exe --git-dir^="!_src!" log -1 --all --pretty^=format:%%cd --date^=format:%%y%%m%%d%%H%%M`
        ) do set _tamp=%%b

        if defined _tamp (
            set "_out=.\!_name!_!_tamp!.git"

            if not exist "!_out!" (
                echo create bundle: !_name!
                @REM git.exe --git-dir="!_src!" bundle create "!_out!" HEAD master
                git.exe --git-dir="!_src!" bundle create "!_out!" --all && git.exe bundle verify "!_out!"
                git.exe --git-dir="!_src!" gc
                echo.
            ) else echo exist: !_out!
        ) else echo skip: !_src!
    )
    endlocal
    exit /b 0

::: "Maven repository tools, Use '-h' for a description of the options" "" "usage: %~n0 m2 [option]" ""
:x3rd\m2
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\m2\%* 2>nul
    goto :eof

::: "    --trim, -c   [[repo_path]]      Print broken file from local maven repository"
:sub\m2\--trim
:sub\m2\-c
    setlocal
    set _lu=0
    set _m2_repo=%~1
    if not defined _m2_repo set _m2_repo=%userprofile%\.m2
    for /r "%_m2_repo%" %%a in (
        *.md5 *.sha1 *.lastUpdated
    ) do call :m2\show-trim-info "%%~a"
    echo @REM lastUpdated: %_lu%
    endlocal
    goto :eof

:m2\show-trim-info
    if /i "%~x1"==".lastUpdated" erase %1 && set /a _lu+=1 && goto :eof
    set _hash=
    set _t=
    set /p _hash=<%1
    if "%_hash%"=="" (set /p _hash=&set /p _hash=)<%1
    if "%~x1"==".sha1" set _hash=%_hash:~0,40%&set _t=SHA1
    if "%~x1"==".md5" set _hash=%_hash:~0,32%&set _t=MD5
    call :this\hash %_t% "%~dpn1" _h
    if /i "%_h%" neq "%_hash%" echo echo %_t% %_hash%, %_h% ^& erase %~dpn1* && goto :eof
    goto :eof

:this\hash [type] [file_path] [var]
    if "%~3"=="" exit /b 2
    setlocal
    set _0=
    for /f "usebackq delims=" %%a in (
        `certutil.exe -hashfile %2 %~1`
    ) do for /f "usebackq tokens=1,2 delims=:" %%b in (
        '%%a'
    ) do if "%%a"=="%%b" call set "_0=%%a"
    endlocal & set %~3=%_0: =%
    exit /b 0

::: "Oracle service start\stop"
:x3rd\orcld
    if "%~1"=="" exit /b 2 @REM Sid is empty, default is orcl
    setlocal
    set _sid=OracleService%~1
    for /f "usebackq tokens=1,3" %%a in (
        `sc.exe query %_sid%`
    ) do if /i "%%a"=="STATE" (
        set _srv=OracleOraDb11g_home1TNSListener
        if "%%b"=="4" (
            call :orcld\setService
            call :orcld STOP START
        ) else call :orcld START STOP
    )
    if not defined _srv >&2 echo Error: No %_sid% Service
    echo.
    endlocal
    exit /b 0

@REM For :x3rd\orcl
:orcld
    echo Oracle Service allready %~2, Press {Enter} to %~1
    set /p _input=or type any characters to EXIT.
    if defined _input exit /b 0
    echo.
    net.exe %1 %_srv%
    net.exe %1 %_sid%
    exit /b 0

@REM For :x3rd\orcl
:orcld\setService
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

::: "VirtualBox Manage, Use '-h' for a description of the options" "" "usage: %~n0 vbox [args] [[vm_name]]" ""
:x3rd\vbox
    setlocal enabledelayedexpansion
    @REM Add vbox path
    set path=%path%;%VBOX_MSI_INSTALL_PATH%
    @REM Test VBoxManage command
    call :sub\path\--contain VBoxManage.exe || exit /b 2 @REM need install vbox

    2>nul call :sub\vbox\%*
    if %errorlevel%==1 if "%~2"=="" call :sub\vbox\start %*
    endlocal & exit /b %errorlevel%

@REM List all VM name, tag running VM
@REM todo MAC VBoxManage.exe showvminfo %_vms% --machinereadable | find "macaddress"
:sub\vbox\
    call :vbox\setVar vms _vms
    call :vbox\setVar runningvms _run
    for /f "usebackq delims==" %%a in (
        `set _vms 2^>nul`
    ) do if defined _run\%%~nxa (
        call :this\txt\--all-col-left %%~nxa
        call :this\txt\--all-col-left (running^)
        echo.
    ) else echo %%~nxa
    @REM call :this\txt\--all-col-left 0 0
    exit /b 0

@REM Start VM
::: "    start       Start VM by name"
:sub\vbox\start
    call :vbox\init %1 || exit /b 0
    if defined _run\%vm% (
        echo %vm% is running...
    ) else VBoxManage.exe startvm %vm% -type headless
    exit /b 0

@REM Stop VM
::: "    stop/save   Stop VM by name"
:sub\vbox\stop
@REM :sub\vbox\save
    call :vbox\init %1 || exit /b 0
    if defined _run\%vm% (
        VBoxManage.exe controlvm %vm% poweroff
    ) else echo %vm% not running...
    exit /b 0

@REM Stop All VM
::: "    stopAll     Stop all vm"
:sub\vbox\stopAll
    for /f "usebackq" %%a in (
        `VBoxManage.exe list runningvms`
    ) do VBoxManage.exe controlvm %%~a poweroff
    echo All vm stop
    exit /b 0

::: "" "    ova     [vm_name] [eula_file_path] " "                Package vm to ova format"
:sub\vbox\ova
    if "%~1"=="" exit /b 51 @REM vm name is empty
    if not exist "%~2" exit /b 52 @REM eula file not found
    setlocal enabledelayedexpansion
    call :vbox\init %1 && VBoxManage.exe export %vm% -o ".\%vm%.ova" --legacy09 --manifest --options nomacs --vsys 0 --eulafile %2
    endlocal
    exit /b 0

@REM Set vm variable
:vbox\init
    if "%1"=="" exit /b 1
    @REM Init variable
    call :vbox\setVar vms _vms
    call :vbox\setVar runningvms _run
    @REM sort name auto complete
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
    @REM make all column left-aligned over
    call :this\txt\--all-col-left 0 0
    if %i%==1 (
        exit /b 0
    ) else if %i% gtr 1 (
        >&2 echo Error: name conflict
    ) else >&2 echo Error: no name found
    exit /b 1

@REM Reg VM names
:vbox\setvar
    for /f "usebackq tokens=1,2" %%a in (
        `VBoxManage.exe list %1`
    ) do set %2\%%~a=%%b
    exit /b 0

:::::::::::::
:: Convert ::
:::::::::::::

::: "Convert to media, Use '-h' for a description of the options" "" "usage: %~n0 c2 [option] ..." ""
:x3rd\c2
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\path\--contain ffmpeg.exe || exit /b 2 @REM ffmpeg command not found
    call :sub\c2\%*
    goto :eof

::: "    --2flac, -2f        Convert alac,ape,m4a,tta,tak,wav to flac format" "                        need changes the current directory at target"
:sub\c2\--2flac
:sub\c2\-2f
    pushd "%cd%"
    for /r . %%a in (
        *.alac *.ape *.m4a *.tta *.tak *.wav
    ) do cd /d "%%~dpa" && (
        echo cd /d %%~dpa
        if not exist .\"%%~na.flac" ffmpeg.exe -hide_banner -i ".\%%~nxa" -acodec flac ".\%%~na.flac" 2>&1
    )
    popd
    exit /b 0

::: "" "    --vob2, -b2         [drive:] [output_file_path]" "                        Convert dvd drive to video file" "                   e.g. %~n0 c2 -b2 D: E:\out.mkv"
:sub\c2\--vob2
:sub\c2\-b2
    if not exist "%~dp2" exit /b 22 @REM output path not found
    if "%~x2"=="" exit /b 23 @REM no output suffix
    @REM if /i "%~d1"=="%~d2" exit /b 4
    setlocal enabledelayedexpansion
    set _src=
    for /f "usebackq delims=" %%a in (
        `dir /b %~d1\VTS_01_*.VOB`
    ) do if defined _src (
        set _src=!_src!^|%~d1\%%a
    ) else set _src=%~d1\%%a
    endlocal & ffmpeg.exe -hide_banner -i concat:"%_src%" "%~f2"
    goto :eof

::: "" "    --2gif, -2g         [video_file] [time-range]" "                        Convert video to gif" "                   e.g. %~n0 c2 -2g D:\src.mp4 796-797"
:sub\c2\--2gif
:sub\c2\-2g
::: "" "    --screenshot, -ss   [video_file] [time-range]" "                        Screenshot video by time range"
:sub\c2\--screenshot
:sub\c2\-ss
    if not exist "%~1" exit /b 32 @REM input video path not found
    if "%~2"=="" exit /b 33 @REM time range not set
    setlocal
    set "_range=%~2"
    if "%_range:-=%"=="%~2" exit /b 34 @REM time range format error
    set _out=%~n1_%_range::=%

    for /f "usebackq tokens=3 delims=2" %%a in ('%0') do goto c2\gif

    ::: screenshot :::
    mkdir "%_out%"
    ffmpeg.exe -hide_banner -ss %_range:-= -to % -i %1 -y -qscale:v 3 "%_out%\screenshot_%%d.png"
    endlocal
    goto :eof

    ::: gif :::
    :c2\gif
    set /a _width=480, _fps=10
    @REM ffmpeg.exe -hide_banner -ss %_range:-= -to % -i %1 -r %_fps% -vf "fps=%_fps%,scale=%_width%:-1" -y -f gif "%_out%.gif"
    ffmpeg.exe -hide_banner -ss %_range:-= -to % -i %1 -r %_fps% -vf fps=%_fps%,scale=%_width%:-1:flags=lanczos,palettegen -y "%tmp%\%_out%.png"
    ffmpeg.exe -hide_banner -ss %_range:-= -to % -i %1 -i "%tmp%\%_out%.png" -r %_fps% -lavfi fps=%_fps%,scale=%_width%:-1:flags=lanczos[x];[x][1:v]paletteuse -y -f gif "%_out%.gif"
    erase "%tmp%\%_out%.png"
    endlocal
    goto :eof


::: "Play all multi-media in directory" "" "usage: %~n0 play [options] ... [directory...]" "" "    --random, -r             random play" "    --ast,    -a [num]       select desired audio stream" "    --skip,   -j [count]     skip some file" "" "   PLAY_VOLUME               environment variable e.g. 0.5" "" "   PLAY_SCALE                environment variable e.g. -1:480"
:::: "ffplay command not found" "args is empty"
:x3rd\play
    call :sub\path\--contain ffplay.exe || exit /b 1
    if "%~1"=="" exit /b 2
    setlocal enabledelayedexpansion
    set _media=
    set _random=
    set _stream_specifier=
    set _skip=
:play\args
    if /i "%~1"=="--random" set _random=RANDOM
    if /i "%~1"=="-r" set _random=RANDOM
    @REM -ast stream_specifier  select desired audio stream
    if /i "%~1"=="--ast" call :sub\is\--integer %~2 && set "_stream_specifier=-ast %~2"& shift /1
    if /i "%~1"=="-a" call :sub\is\--integer %~2 && set "_stream_specifier=-ast %~2"& shift /1
    if /i "%~1"=="--skip" call :sub\is\--integer %~2 && set "_skip=%~2"& shift /1
    if /i "%~1"=="-j" call :sub\is\--integer %~2 && set "_skip=%~2"& shift /1
    call :sub\dir\--isdir %1 && set _media=%_media% "%~1"
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
    ) do set /a _i+=1& call :this\ff "%%a"

    endlocal
    exit /b 0

:this\ff
    echo Progress #%_i% / %_c%, %_random%
    @REM -sn ::disable subtitling
    @REM -ch_layout stereo ::ED..A... set number of audio channels (from 0 to INT_MAX) (default 0) ::Convert the 5.1 track to stereo
    if not defined PLAY_VOLUME set PLAY_VOLUME=0.85
    if not defined PLAY_SCALE set PLAY_SCALE=-1:-1
    for %%a in (
        avi divx flv mkv mp4 mpg rm rmvb vob webm wmv
    ) do if /i "%~x1"==".%%a" ffplay.exe -hide_banner %_stream_specifier% -ch_layout stereo -sn -autoexit -vf "scale=%PLAY_SCALE%" -af "volume=%PLAY_VOLUME%" %1 2>&1
    for %%a in (
        alac ape flac m4a mp3 ogg tta tak wav wma
    ) do if /i "%~x1"==".%%a" start /b /wait /min ffplay.exe -hide_banner -autoexit -af "volume=0.05" %1 2>&1
    exit /b 0

@REM :x3rd\cam
@REM     if "%~1"=="" call :this\annotation %0 & goto :eof
@REM     call :sub\path\--contain ffmpeg.exe || exit /b 2 @REM ffmpeg command not found
@REM     call :sub\cam\%*
@REM     goto :eof
@REM
@REM :sub\cam\--list
@REM :sub\cam\-l
@REM     ffmpeg.exe -hide_banner -f dshow -list_devices true -i "" 2>&1 | find.exe "]"
@REM     exit /b 0
@REM
@REM :sub\cam\--show
@REM :sub\cam\-s
@REM     ffplay.exe -hide_banner -f dshow -video_size $size -framerate 25 -pixel_format 0rgb -probesize 10M -i "0":"0" 2>&1
@REM     exit /b 0

::: "Docker batch command, Use '-h' for a description of the options" "Usage: %~n0 dockers [start/stop]"
:x3rd\moby
    call :sub\path\--contain docker.exe || exit /b 2 @REM docker client command not found
    2>nul call :sub\moby\%*
    goto :eof

:sub\moby\start
    for /f "usebackq skip=1" %%a in (
        `docker.exe ps -f status=exited`
    ) do docker.exe start %%a
    exit /b 0

:sub\moby\stop
    for /f "usebackq skip=1" %%a in (
        `docker.exe ps`
    ) do docker.exe stop %%a
    exit /b 0

@REM ::: "Get docker tags" "" "    %~n0 tags [image_name]"
@REM :sub\moby\tags
@REM     for %%a in (bash.exe) do if "%%~$path:a"=="" exit /b 2 @REM no bash.exe found, need install git for windows, and add it in environment variabl
@REM     for /f "usebackq tokens=2,4 " %%a in (
@REM         `bash.exe -c 'curl https://index.docker.io/v1/repositories/%1/tags 2^>nul ^^^| sed -e "s/\}, /\n/g;s/,//g;s/\}\]//g"`
@REM     ) do echo %%~a %1:%%~b
@REM     exit /b 0

::: "Compress PNG images" "Usage: %~n0 cpng [src_dir] [out_dir]"
:x3rd\cpng
    call :sub\path\--contain pngquant.exe || exit /b 2 @REM pngquant command not found
    if not exist "%~f1" exit /b 3 @REM source path not exist
    if "%~2"=="" exit /b 4 @REM output path not set
    if /i "%~f1"=="%~f2" exit /b 5 @REM out put dir is same

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
:x3rd\tar.gz
::: "tar.bz2 compresses by 7za" "" "Usage: %~n0 tar.bz2 [path]"
:x3rd\tar.bz2
    call :sub\path\--contain 7za.exe || exit /b 10 @REM 7za not fount
    setlocal enabledelayedexpansion
    if not exist "%~1" exit /b 2 @REM target not found
	if "%~2"=="" call :this\equalsDeputySuffix %1 .tar && (
		call :this\tarDecompresses %1
		goto :eof
	)
	for %%a in (%0) do set _suffix=%%~nxa
	set _suffix=%_suffix:~4%
	call :this\tarCompresses %*
    endlocal
    exit /b 0

@REM for :x3rd\tar.*
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

@REM for :x3rd\tar.*
:this\tarDecompresses
	for %%a in ("%~n1") do (
		7za.exe x %1 -so | 7za.exe x -si -ttar -o. -aoa
		@REM call :this\molting ".\%%~na" %2
	)
	goto :eof

@REM @REM for :this\tarDecompresses
@REM :this\molting
@REM 	if "%~1"=="" goto :eof
@REM 	@REM if "%~2"=="" goto :eof
@REM 	for /f "usebackq delims=" %%a in (
@REM 		`dir /a /b "%~1"`
@REM 	) do if not defined _molting (
@REM 		call :this\dir\--isdir "%~1\%%a" || goto :eof
@REM 		set "_molting=%%a"
@REM 	) else set _molting= & goto :eof
@REM 	call :this\str\--now _nowM && rename "%~1" !_nowM!
@REM 	>nul move /y "%~dp1!_nowM!\!_molting!" "%~dp1" && rmdir /s /q "%~dp1!_nowM!"
@REM 	set _nowM=
@REM 	@REM set "%~2=%~dp1!_molting!"
@REM 	set _molting=
@REM 	@REM call %0 "!%~2!" %~2
@REM 	goto :eof

@REM for :x3rd\tar.*
:this\equalsDeputySuffix
	for %%a in (
		"%~n1"
	) do if /i "%%~xa"=="%~2" exit /b 0
	exit /b 1


@REM :x3rd\ftp
@REM 	>%temp%\.bb315509-cf9c-5caa-c096-24d258c3d95d (
@REM 		call :this\ftp\init [ip] [name] [password] [dir]
@REM 		if "%~1"=="" (
@REM 			call :this\ftp\dir
@REM 		) else call :this\ftp\upload %*
@REM 	)
@REM  	ftp.exe -s:%temp%\.bb315509-cf9c-5caa-c096-24d258c3d95d
@REM  	erase %temp%\.bb315509-cf9c-5caa-c096-24d258c3d95d
@REM     exit /b 0
@REM
@REM :this\ftp\init
@REM 	echo open %~1
@REM 	echo %~2
@REM 	echo %3
@REM 	echo cd %4
@REM 	goto :eof
@REM
@REM :this\ftp\upload
@REM 	echo binary
@REM 	for %%a in (
@REM 		%*
@REM 	) do if exist "%%~a" echo put "%%~a"
@REM 	echo close
@REM 	echo quit
@REM 	goto :eof
@REM
@REM :this\ftp\dir
@REM 	echo dir
@REM 	echo quit
@REM 	goto :eof

::::::::::::::::::
::     Base     ::
  :: :: :: :: ::

@REM Test target in $path
:sub\path\--contain
    if "%~1" neq "" if "%~$path:1" neq "" exit /b 0
    exit /b 1

@REM Test string if Num \* @see xlib.cmd *\
:sub\is\--integer
    if "%~1"=="" exit /b 10
    setlocal
    set _tmp=
    @REM quick return
    2>nul set /a _code=10, _tmp=%~1
    if "%~1"=="%_tmp%" set _code=0
    endlocal & exit /b %_code%

@REM Test path is directory \* @see dis.cmd *\
:sub\dir\--isdir
    setlocal
    set _path=%~a1-
    @REM quick return
    set _code=10
    if %_path:~0,1%==d set _code=0
    endlocal & exit /b %_code%

@REM Display Time at [YYYYMMDDhhmmss] \* @see xlib.cmd *\
:sub\str\--now
    if "%~1"=="" exit /b 2
    set date=
    set time=
    @REM en zh
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

@REM Show function list, func info or error message, complete function name
:this\annotation
    setlocal enabledelayedexpansion & set /a _err_code=%errorlevel%
    set _annotation_more=
    set _err_msg=
    for /f "usebackq skip=65 delims=" %%a in (
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
                @REM match error message
                if "!_un_space:exit/b%_err_code%=!" neq "!_un_space!" >&2 ^
                    echo [ERROR] !_err_msg:* @REM =! ^(%~f0!_func_eof!^)&& exit /b 1

            ) else if %_err_code%==1 >&2 echo [ERROR] invalid option '%~2' ^(%~f0!_func_eof!^)&& exit /b 1
        )

        @REM match arguments, sub function
        if /i "%%~b\%%~c"==":sub\%~nx1" (
            set _func_eof=%%~a
            if defined _annotation if %_err_code%==0 call %0\more !_annotation!
            set _annotation=

        ) else if /i "%%~b"==":%~n0" (
            @REM match new function, clear function name
            if defined _annotation_more exit /b 0
            if defined _err_msg >&2 echo unknown error.& exit /b 1
            set _func_eof=

            @REM match target function
            if /i "%%~b\%%~c"=="%~1" (
                set _func_eof=%%~a
                if defined _annotation if %_err_code%==0 call %0\more !_annotation!
                set _annotation=

            )
            @REM init func var, for display all func, or show sort func name
            set _prefix_4_auto_complete\%%~c=!_annotation! ""

        )

    )

    if defined _annotation_more exit /b 0
    if defined _err_msg >&2 echo unknown error.& exit /b 1

    @REM Foreach func list
    call :xlib\cols _col
    set /a _i=0, _col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (`
        2^>nul set _prefix_4_auto_complete\%~n1
    `) do if "%~1" neq "" (
        @REM " Sort func name expansion
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

    @REM Close lals
    if !_i! gtr 0 call :sub\txt\--all-col-left 0 0

    @REM Display func or call func
    endlocal & if %_i% gtr 1 (
        echo.
        >&2 echo [WARN] function sort name conflict
        exit /b 1

    ) else if %_i%==0 (
        if "%~1" neq "" >&2 echo [ERROR] No function found& exit /b 1

    ) else if %_i%==1 2>nul call :%~n0\%_args% || call %0 :%~n0\%_args%
    goto :eof

:this\annotation\more
    echo.%~1
    shift /1
    if "%~1" neq "" goto %0
    if .%1==."" goto %0
    set _annotation_more=true
    exit /b 0

@REM Make the second column left-aligned
:sub\str\--2col-left
    if "%~2"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    echo %~1!_spaces:~0,%_len%!%~2
    endlocal
    exit /b 0

@REM Use right pads spaces, make all column left-aligned
:sub\txt\--all-col-left
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

@REM for :this\txt\--all-col-left
:strModulo
    set /a _acl+=1
    set _str=%_str:~15%
    if "%_str:~31,1%"=="" exit /b 0
    goto %0

@REM Get cmd cols
:xlib\cols
    for /f "usebackq skip=4 tokens=2" %%a in (`mode.com con`) do (
        if "%~1"=="" (
            echo %%a
        ) else set %~1=%%a
        exit /b 0
    )
    exit /b 0

   :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::                 Framework                 ::
:::::::::::::::::::::::::::::::::::::::::::::::
