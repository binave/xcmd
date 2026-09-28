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

::::::::::::::::::::::::::
:: Third-Party Programs ::
::::::::::::::::::::::::::

:: Reset errorlevel.
set errorlevel=
:: Add this script's directory to PATH when it is not on PATH yet.
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

:: Re-entry for the pipe and the for /f form: a [\\] token is not a real path, so
:: this branch is the only one that runs it.  The token names the label to call
:: and the arguments follow it, e.g. [\\txt\--fence SOURCE TAG].  The indirection
:: matters: a pipe runs this file in a child cmd, where calling a label is not
:: allowed, whereas the call above runs the file again as a whole.  This is the
:: shape osdt.cmd uses with [call "%~f0" \\disk\detail_disk ^| diskpart].
if "%~d1"=="\\" call :%~pnx1 %2 %3 %4 %5 & goto :eof

if "%~2"=="-h" call :this\annotation :%~n0\%~1 & goto :eof
if "%~2"=="--help" call :this\annotation :%~n0\%~1 & goto :eof

2>nul call :%~n0\%*

if not errorlevel 0 exit /b 1

:: Show the function help when the function returns an error status.
if errorlevel 1 call :this\annotation :%~n0\%* & goto :eof
exit /b 0

:x3rd\
:x3rd\--help
:x3rd\-h
    call :this\annotation
    exit /b 0

::: "Print version and exit" "" "Usage: %~n0 version"
:x3rd\version
    >&3 echo 0.26.9.26
    exit /b 0

::: "Clink completion for xlib.cmd and x3rd.cmd, generated from the annotations" "Usage: %~n0 comp [OPTION]..."
:x3rd\comp
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\comp\%*
    if not errorlevel 0 exit /b %errorlevel%
    @REM Show the option help, or report the unknown option.
    call :this\annotation :%~n0\%~1 %~2
    exit /b 0

::: "    -c, --clink           print the clink completion script (Lua)"
:sub\comp\--clink
:sub\comp\-c
    call :comp\run --clink
    exit /b %errorlevel%

::: "    -i, --install[=DIR]   install the completion script to the clink directory"
:sub\comp\--install
:sub\comp\-i
    :: [--install] alone installs to the clink directory.  [--install=DIR] and
    :: [--install DIR] name the directory; the value is split off and passed
    :: as a separate argument, which survives the layers of expansion.
    if "%~1"=="" call :comp\run --install & exit /b %errorlevel%
    setlocal enabledelayedexpansion
    set "_idir=%~1"
    if "%~2" neq "" set "_idir=%~2"
    if "!_idir:~0,10!"=="--install=" set "_idir=!_idir:~10!"
    call :comp\run --install "!_idir!"
    set "_code=!errorlevel!"
    endlocal & exit /b %_code%

::: "    -k, --check           check the annotations and print warnings"
:sub\comp\--check
:sub\comp\-k
    call :comp\run --check
    exit /b %errorlevel%

::: "    -l, --list            print the parsed completion metadata"
:sub\comp\--list
:sub\comp\-l
    call :comp\run --list
    exit /b %errorlevel%

::: "Git tools" "" "Usage: %~n0 git [OPTION]... [ARG]..." ""
:x3rd\git
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\git\%* 2>nul
    goto :eof

:::  "    -b, --backup             backup git repositories"
:sub\git\--backup
:sub\git\-b
    call :sub\path\--contain git.exe || exit /b 2 @REM The git command was not found.
    setlocal enabledelayedexpansion
    for /r /d %%a in (
        hook?
    ) do if exist "%%~dpaobjects" (
        :: Git repository.
        set "_src=%%~dpa"
        set "_src=!_src:~0,-1!"
        :: Project name.
        set _name=!_src:\.git=!
        set _name=!_name:.git=!
        for %%b in ("!_name!") do set "_name=%%~nxb"
        :: Get the latest commit timestamp for the bundle name.
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

:::  "    -ua, --update-all        update all repositories"
:sub\git\--update-all
:sub\git\-ua
    for /r /d %%a in (.g?t) do echo [INFO] %%~dpa&& git.exe --git-dir="%%a" --work-tree="%%~dpa" pull
    goto :eof

:::  "    -id, --install-doc       install the 'doc' alias to ~/.gitconfig"
:sub\git\--install-doc
:sub\git\-id
    call :sub\path\--contain git.exe || exit /b 2 @REM The git command was not found.
    :: The 'print' argument is for :sub\git\doc\--alias, which prints the 'doc' alias of this file.
    if /i "%~1"=="print" call :sub\git\doc\--alias & exit /b 0
    setlocal
    set "_cfg=%userprofile%\.gitconfig"
    if not exist "%_cfg%" type nul > "%_cfg%"

    :: x3rd writes the alias with backslash continuations, but this script writes
    :: CRLF, so it installs the same value on a single line instead. Both hold
    :: one value: compare the value git computes, not the text of the config.
    set "_new="
    for /f "usebackq delims=" %%a in (`
        call "%~f0" git -id print 2^>nul ^| git.exe config --file - alias.doc ^| git.exe hash-object --stdin
    `) do set "_new=%%a"
    set "_old="
    for /f "usebackq delims=" %%a in (`
        git.exe config --global alias.doc 2^>nul ^| git.exe hash-object --stdin
    `) do set "_old=%%a"
    if not defined _new exit /b 3 @REM Failed to read the 'doc' alias entry.
    if "%_new%"=="%_old%" (
        echo exist: alias.doc
        endlocal
        exit /b 0
    )
    git.exe config --global --unset-all alias.doc >nul 2>nul
    call :sub\git\doc\--add "%_cfg%" || exit /b 4 @REM Failed to install the 'doc' alias.
    echo install: alias.doc -^> "%_cfg%"
    endlocal
    exit /b 0

:: Append the 'doc' alias to the end of the config file, under an [alias] header.
:sub\git\doc\--add
    if "%~1"=="" exit /b 2
    setlocal disabledelayedexpansion
    set "_end="
    for /f "usebackq eol= delims=" %%a in (
        `findstr.exe /b /c:"[" "%~1"`
    ) do set "_end=%%a"

    set "_end=!_end: =!"
    set "_end=!_end:"=!"
    :: The blank line also ends a config file whose last line has no newline.
    >> "%~1" echo.
    if "!_end!"=="[alias]" (
        >> "%~1" call :sub\git\doc\--print
    ) else (
        >> "%~1" echo [alias]
        >> "%~1" call :sub\git\doc\--print
    )
    >> "%~1" echo.
    endlocal
    exit /b 0

:: Write the 'doc' alias to stdout without a trailing newline: the lines of the
:: [sh] block of this file are joined with the 7 spaces of the x3rd
:: continuations, and the indent of each line is dropped by 'set /p', so the
:: value stays on one line and matches the one x3rd installs.
:sub\git\doc\--print
    setlocal disabledelayedexpansion
    for /f "usebackq delims=" %%a in (`
        call "%~f0" \\txt\--fence "%~f0" sh
    `) do <nul set /p "=%%a       "
    endlocal
    exit /b 0

:: Print the alias as a config fragment for 'call "%~f0" git -id print': a
:: pipe runs the file in a child cmd, where calling a label is not allowed,
:: whereas the call above runs the file again as a whole; see 'hosts' in xlib.cmd.
:sub\git\doc\--alias
    echo [alias]
    call :sub\git\doc\--print
    exit /b 0

::: "Maven repository tools" "" "Usage: %~n0 m2 [OPTION]..." ""
:x3rd\m2
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\m2\%* 2>nul
    goto :eof

::: "    -c, --trim[=PATH]   print broken files in the local maven repository"
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

::: "Oracle service start/stop"
:x3rd\orcld
    if "%~1"=="" exit /b 2 @REM SID is empty, default is orcl
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

:: For :x3rd\orcld.
:orcld
    echo Oracle Service allready %~2, Press {Enter} to %~1
    set /p _input=or type any characters to EXIT.
    if defined _input exit /b 0
    echo.
    net.exe %1 %_srv%
    net.exe %1 %_sid%
    exit /b 0

:: For :x3rd\orcld.
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

::: "VirtualBox Manage" "" "Usage: %~n0 vbox {start,stop,stopAll,ova} [VM_NAME]" ""
:x3rd\vbox
    setlocal enabledelayedexpansion
    :: Add the VirtualBox install path to PATH.
    set path=%path%;%VBOX_MSI_INSTALL_PATH%
    :: Fail when VBoxManage.exe is not on PATH.
    call :sub\path\--contain VBoxManage.exe || exit /b 2 @REM VBoxManage.exe was not found.
    2>nul call :sub\vbox\%*
    if %errorlevel%==1 if "%~2"=="" call :sub\vbox\start %*
    endlocal & exit /b %errorlevel%

:: List all VM names and mark the running ones.
:: TODO: list the MAC address with VBoxManage.exe showvminfo %_vms% --machinereadable | find "macaddress".
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

:: Start a virtual machine.
::: "    start       start VM by name"
:sub\vbox\start
    call :vbox\init %1 || exit /b 0
    if defined _run\%vm% (
        echo %vm% is running...
    ) else VBoxManage.exe startvm %vm% -type headless
    exit /b 0

:: Stop a virtual machine.
::: "    stop/save   stop VM by name"
:sub\vbox\stop
@REM :sub\vbox\save
    call :vbox\init %1 || exit /b 0
    if defined _run\%vm% (
        VBoxManage.exe controlvm %vm% poweroff
    ) else echo %vm% not running...
    exit /b 0

:: Stop all running virtual machines.
::: "    stopAll     stop all running VMs"
:sub\vbox\stopAll
    for /f "usebackq" %%a in (
        `VBoxManage.exe list runningvms`
    ) do VBoxManage.exe controlvm %%~a poweroff
    echo All vm stop
    exit /b 0

::: "" "    ova         [VM_NAME] [EULA_FILE_PATH]" "                package the VM as an ova file"
:sub\vbox\ova
    if "%~1"=="" exit /b 51 @REM The VM name is empty.
    if not exist "%~2" exit /b 52 @REM The EULA file was not found.
    setlocal enabledelayedexpansion
    call :vbox\init %1 && VBoxManage.exe export %vm% -o ".\%vm%.ova" --legacy09 --manifest --options nomacs --vsys 0 --eulafile %2
    endlocal
    exit /b 0

:: Resolve a VM name prefix and set the 'vm' variable.
:vbox\init
    if "%1"=="" exit /b 1
    :: Load the registered and running VM names.
    call :vbox\setVar vms _vms
    call :vbox\setVar runningvms _run
    :: Enumerate the names that match the prefix and print the candidates.
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

    :: Close the left-aligned column layout.
    call :this\txt\--all-col-left 0 0
    if %i%==1 (
        exit /b 0
    ) else if %i% gtr 1 (
        >&2 echo Error: name conflict
    ) else >&2 echo Error: no name found
    exit /b 1

:: Register the virtual machine names reported by VBoxManage.
:vbox\setvar
    for /f "usebackq tokens=1,2" %%a in (
        `VBoxManage.exe list %1`
    ) do set %2\%%~a=%%b
    exit /b 0

:::::::::::::
:: Convert ::
:::::::::::::

::: "Convert to media" "" "Usage: %~n0 c2 [OPTION]... [OPERAND]..." ""
:x3rd\c2
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :sub\path\--contain ffmpeg.exe || exit /b 2 @REM The ffmpeg command was not found.
    call :sub\c2\%*
    goto :eof

::: "    -2f, --2flac        convert alac, ape, m4a, tta, tak, wav to flac format" "                        run it with the target directory as the current directory"
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

::: "" "    -b2, --vob2=[DRIVE:] [OUTPUT_FILE]" "                        convert a DVD drive to a video file" "                   e.g. %~n0 c2 -b2 D: E:\out.mkv"
:sub\c2\--vob2
:sub\c2\-b2
    if not exist "%~dp2" exit /b 22 @REM The output path was not found.
    if "%~x2"=="" exit /b 23 @REM The output file has no suffix.
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

::: "" "    -2g, --2gif=[VIDEO_FILE] [TIME_RANGE]" "                        convert a video to a gif" "                   e.g. %~n0 c2 -2g D:\src.mp4 796-797"
:sub\c2\--2gif
:sub\c2\-2g
::: "" "    -ss, --screenshot=[VIDEO_FILE] [TIME_RANGE]" "                        take screenshots of a video over a time range"
:sub\c2\--screenshot
:sub\c2\-ss
    if not exist "%~1" exit /b 32 @REM The input video path was not found.
    if "%~2"=="" exit /b 33 @REM The time range was not set.
    setlocal
    set "_range=%~2"
    if "%_range:-=%"=="%~2" exit /b 34 @REM The time range format is invalid.
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

::: "Play all media in a directory" "" "Usage: %~n0 play [OPTION]... [DIRECTORY]..." "" "    -r, --random             play in random order" "    -a, --ast=NUMBER         select the desired audio stream" "    -j, --skip=NUMBER        skip NUMBER files" "" "   PLAY_VOLUME               environment variable, e.g. 0.5" "" "   PLAY_SCALE                environment variable, e.g. -1:480"
:x3rd\play
    call :sub\path\--contain ffplay.exe || exit /b 12 @REM ffplay command not found
    if "%~1"=="" exit /b 13 @REM args is empty
    setlocal enabledelayedexpansion
    set _media=
    set _random=
    set _stream_specifier=
    set _skip=

:play\args
    if /i "%~1"=="--random" set _random=RANDOM
    if /i "%~1"=="-r" set _random=RANDOM
    :: -ast stream_specifier  select the desired audio stream.
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
    :: -sn ::disable subtitling.
    :: -ch_layout stereo ::ED..A... set number of audio channels (from 0 to INT_MAX) (default 0) ::Convert the 5.1 track to stereo.
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
@REM     call :sub\path\--contain ffmpeg.exe || exit /b 2 @REM The ffmpeg command was not found.
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

::: "Docker batch command" "Usage: %~n0 moby {start,stop}"
:x3rd\moby
    call :sub\path\--contain docker.exe || exit /b 2 @REM The docker client command was not found.
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
@REM     for %%a in (bash.exe) do if "%%~$path:a"=="" exit /b 2 @REM bash.exe was not found; install Git for Windows and add it to the PATH.
@REM     for /f "usebackq tokens=2,4 " %%a in (
@REM         `bash.exe -c 'curl https://index.docker.io/v1/repositories/%1/tags 2^>nul ^^^| sed -e "s/\}, /\n/g;s/,//g;s/\}\]//g"`
@REM     ) do echo %%~a %1:%%~b
@REM     exit /b 0

::: "Compress PNG images" "Usage: %~n0 cpng [SRC_DIR] [OUT_DIR]"
:x3rd\cpng
    call :sub\path\--contain pngquant.exe || exit /b 2 @REM The pngquant command was not found.
    if not exist "%~f1" exit /b 3 @REM The source path does not exist.
    if "%~2"=="" exit /b 4 @REM The output path was not set.
    if /i "%~f1"=="%~f2" exit /b 5 @REM The input and output directories are the same.
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

::: "Compress to tar.gz with 7za" "" "Usage: %~n0 tar.gz [PATH]"
:x3rd\tar.gz
::: "Compress to tar.bz2 with 7za" "" "Usage: %~n0 tar.bz2 [PATH]"
:x3rd\tar.bz2
    call :sub\path\--contain 7za.exe || exit /b 10 @REM 7za.exe was not found.
    setlocal enabledelayedexpansion
    if not exist "%~1" exit /b 2 @REM The target was not found.
	if "%~2"=="" call :this\equalsDeputySuffix %1 .tar && (
		call :this\tarDecompresses %1
		goto :eof
	)
	for %%a in (%0) do set _suffix=%%~nxa
	set _suffix=%_suffix:~4%
	call :this\tarCompresses %*
    endlocal
    exit /b 0

:: For the :x3rd\tar.gz and :x3rd\tar.bz2 commands.
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

:: For the :x3rd\tar.gz and :x3rd\tar.bz2 commands.
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

:: For the :x3rd\tar.gz and :x3rd\tar.bz2 commands.
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

:: Test whether the target is on the PATH.
:sub\path\--contain
    if "%~1" neq "" if "%~$path:1" neq "" exit /b 0
    exit /b 1

:: Print the clink command to run: [clink.bat] when it is on the PATH, else the
:: clink.bat of the directory named by CLINK_DIR, else the clink named by the
:: session macro, else the usual install directories.  Set the variable named by
:: %~1 and return 0, or return 1.
:: It writes in the caller's scope on purpose, so no setlocal is used.
:this\clink\--path [var]
    call :this\clink\--search %~1
    if defined %~1 exit /b 0
    exit /b 1

:this\clink\--search [var]
    set "%~1="
    if exist "%CLINK_DIR%\clink.bat" set "%~1=%CLINK_DIR%\clink.bat"
    for %%a in (clink.bat clink_x64.exe clink.cmd) do if not defined %~1 if not "%%~$path:a"=="" set "%~1=%%~$path:a"
    :: An injected clink names itself with the [clink] doskey macro, and a portable
    :: installation is on no PATH and in no usual directory, so read the launcher
    :: from there.  The macro is [clink="PATH" $*], and the first word that is a
    :: file is the launcher, whether it is [clink.bat] or [clink_x64.exe].
    for /f "usebackq tokens=1,* delims==" %%a in (`
        2^>nul doskey.exe /macros
    `) do if /i "%%a"=="clink" for %%f in (%%b) do if not defined %~1 if exist "%%~ff" set "%~1=%%~ff"
    for %%a in (
        "%LOCALAPPDATA%\clink\clink.bat"
        "%ProgramFiles%\clink\clink.bat"
        "%ProgramFiles(x86)%\clink\clink.bat"
    ) do if not defined %~1 if exist %%a set "%~1=%%~a"
    exit /b 0

:: Print the fenced block tagged [%~2] of any text file [%~1].  The block is
:: markdown: its opening fence carries the tag, its closing fence is a bare
:: ``` line.  The [lua] block of this file holds the completion generator
:: [comp]; the [sh] block holds the 'doc' alias that [git -id] installs.
::
:: A pipe cannot call a label, so reach it as a child with the token of the
:: re-entry branch, [call "%~f0" \\txt\--fence SOURCE TAG].
::
:: Delayed expansion is off while the block is copied, so an exclamation mark in
:: a block is kept; the 'doc' alias holds one.
:txt\--fence [source_path] [tag]
    if "%~2"=="" exit /b 2 @REM The block tag is empty.
    setlocal disabledelayedexpansion
    set "_on="
    for /f "usebackq delims=" %%a in ("%~1") do (
        if defined _on (
            if "%%~a"=="```" (set "_on=") else echo(%%a
        ) else if "%%~a"=="``` %~2" set _on=1
    )
    endlocal
    exit /b 0

:: Extract the embedded generator and run it with the Lua engine that clink
:: embeds, so no Lua interpreter has to be installed and no scratch file is
:: written.  The generator reads its inputs from the environment, because a
:: script on standard input has no arguments of its own.  The [ERROR] message
:: goes to the [>&3] console, which the [2>nul] of the dispatch line keeps.
:comp\run
    setlocal enabledelayedexpansion

    call :this\clink\--path _clink
    if not defined _clink (
        >&3 echo [ERROR] clink was not found.  Install clink, or set CLINK_DIR.
        endlocal & exit /b 3
    )

    :: The mode is the bare option name, so [--check] becomes [check].
    set "_mode=%~1"
    set "XCMD_SOURCE=%~dp0xlib.cmd"
    set "XCMD_SOURCE2=%~dp0x3rd.cmd"
    if "!_mode:~0,2!"=="--" set "_mode=!_mode:~2!"
    set "XCMD_MODE=!_mode!"
    if /i "%~1"=="--install" set "XCMD_DIR=%~2"

    call "%~f0" \\txt\--fence "%~f0" lua | "!_clink!" lua
    set "_code=!errorlevel!"

    endlocal & exit /b %_code%

:: Test whether a string is an integer. \* @see xlib.cmd *\
:sub\is\--integer
    if "%~1"=="" exit /b 10
    setlocal
    set _tmp=
    :: A valid integer round-trips through 'set /a' unchanged.
    2>nul set /a _code=10, _tmp=%~1
    if "%~1"=="%_tmp%" set _code=0
    endlocal & exit /b %_code%

:: Test whether a path is a directory. \* @see dis.cmd *\
:sub\dir\--isdir
    setlocal
    set _path=%~a1-
    :: The first attribute character is 'd' for a directory.
    set _code=10
    if %_path:~0,1%==d set _code=0
    endlocal & exit /b %_code%

:: Display the time as [YYYYMMDDhhmmss]. \* @see xlib.cmd *\
:sub\str\--now
    if "%~1"=="" exit /b 2
    set date=
    set time=
    :: English and Chinese date formats.
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

:: Show the function list or one function's help, print an error message, or complete a function name.
:this\annotation
    setlocal enabledelayedexpansion & set /a _err_code=%errorlevel%
    set _annotation_more=
    set _err_msg=
    for /f "usebackq skip=74 delims=" %%a in (
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
        :: Match a sub function label.
        if /i "%%~b\%%~c"==":sub\%~nx1" (
            set _func_eof=%%~a
            if defined _annotation if %_err_code%==0 call %0\more !_annotation!
            set _annotation=

        ) else if /i "%%~b"==":%~n0" (
            :: Match a new function and clear the previous one.
            if defined _annotation_more exit /b 0
            if defined _err_msg >&2 echo unknown error.& exit /b 1
            set _func_eof=
            :: Match the target function.
            if /i "%%~b\%%~c"=="%~1" (
                set _func_eof=%%~a
                if defined _annotation if %_err_code%==0 call %0\more !_annotation!
                set _annotation=

            )
            :: Register the annotation for the list and name completion; skip the dispatch labels (-h, --help).
            set _fn_name=%%~c
            if not "!_fn_name!"=="" if not "!_fn_name:~0,1!"=="-" set _prefix_4_auto_complete\%%~c=!_annotation! ""

        )
    )

    if defined _annotation_more exit /b 0
    if defined _err_msg >&2 echo unknown error.& exit /b 1

    :: Print the function list in columns.
    call :xlib\cols _col
    set /a _i=0, _col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (`
        2^>nul set _prefix_4_auto_complete\%~n1
    `) do if "%~1" neq "" (
        :: Print the matching function names in columns.
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

    :: Close the column layout.
    if !_i! gtr 0 call :sub\txt\--all-col-left 0 0

    :: Report the error, or call the matched function.
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

:: Make the second column left-aligned.
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

:: Pad with spaces on the right to make all columns left-aligned.
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

:: For :this\txt\--all-col-left.
:strModulo
    set /a _acl+=1
    set _str=%_str:~15%
    if "%_str:~31,1%"=="" exit /b 0
    goto %0

:: Get the console width in columns.
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


:::::::::::::::::::::::::::::::::::::::::::::::
::             Embedded Documents            ::
   :: :: :: :: :: :: :: :: :: :: :: :: :: ::

:: The blocks are markdown, and they are never reached when this file runs as a
:: batch script, because the batch part exits first.  [:txt\--fence] copies a
:: block with for /f, so nothing is written to disk.
::
:: The 'doc' alias that [git -id] installs to ~/.gitconfig.  The lines are
:: joined with the 7 spaces of the x3rd continuations, so the value stays on
:: one line, which is what x3rd's awk reads back.
``` sh
    doc = "!f() {
      root=\"$(git rev-parse --show-toplevel)\" || exit 1; repo=\"$(git rev-parse --show-superproject-working-tree 2>/dev/null)\";
      [ -n \"$repo\" ] && repo=\"$repo.${root##*/}\"; repo=\"${repo:-$root}.docs.git\"; spec=\"$root/.docpathspec\"; case $1 in
      status|add) cmd=$1; shift; [ \"$1\" = -- ] && { shift; exec git --git-dir=\"$repo\" --work-tree=\"$root\" \"$cmd\" \"$@\"; };
      [ \"$cmd\" = status ] && opt='-uall --ignored=matching' || opt='-f';
      [ -f \"$spec\" ] || { git --git-dir=\"$repo\" --work-tree=\"$root\" \"$cmd\" $opt -- ':(glob)**/*.md'; return; };
      set -- --; while IFS= read -r line; do case \"$line\" in ''|'#'*) ;; *) set -- \"$@\" \"$line\";; esac; done < \"$spec\";
      [ \"$cmd\" = add ] && git --git-dir=\"$repo\" --work-tree=\"$root\" \"$cmd\" $opt -- ':(top).docpathspec';
      git --git-dir=\"$repo\" --work-tree=\"$root\" \"$cmd\" $opt \"$@\";;
      clone) tmp=\"$(mktemp -d 2>/dev/null).$$.git\"; git clone --no-checkout --separate-git-dir=\"$repo\" \"$2\" \"$tmp\" || :; rm -fr \"$tmp\";;
      *) git --git-dir=\"$repo\" --work-tree=\"$root\" \"$@\";; esac;     }; f"
```

::
:: The clink completion generator for xlib.cmd and x3rd.cmd.  [:comp\run] copies
:: it with for /f and pipes it into the Lua engine that clink embeds, so no Lua
:: interpreter has to be installed.
``` lua
-- Framework:
--
--     Read the [:::] annotation of xlib.cmd and x3rd.cmd and write the clink
--     completion script.  The annotation is the help text and the completion
--     source at the same time, so both stay next to the code:
--
--         ::: "[brief]" "" "[usage]" ...
--         :xlib\[command]
--             ::: "    -o, --option=FILE   [description]"
--         :sub\[command]\[--option]
--
--     The metavariable of an option or of the usage line names the completion
--     source, using the GNU style:
--
--         FILE IMAGE PATH  -> a file        DIRECTORY DIR DEVICE -> a directory
--         ADDRESS IP IPV4  -> an IPv4       MAC    -> a MAC address
--         LETTER           -> a drive letter
--         HOST             -> a hosts ini alias or an IPv4
--         ALIAS            -> a hosts ini alias
--         HOSTIP           -> an IPv4 of the hosts file that the ini omits
--         SHELL KIND       -> a shell name or a completion kind
--         {a|b} {a,b}      -> an enumeration
--
--     Two completion scripts are written, [xlib.lua] and [x3rd.lua].  Clink
--     loads a script from a [completions] directory only when the command of
--     the same name is typed, so the file name is what makes it load.
--
--     The generator is embedded in x3rd.cmd and run by the Lua engine that
--     clink embeds, so no Lua interpreter has to be installed:
--
--         x3rd comp --install
--
-- Arguments:
--   Every argument may also be given as an XCMD_* environment variable, which
--   lets the generator run from standard input, where [arg] does not exist:
--     XCMD_MODE      clink | list | check | install
--     XCMD_SOURCE    the annotated script to scan; repeatable with XCMD_SOURCE2
--     XCMD_DIR       the [--install] directory
--     XCMD_RUNTIME   the static runtime file to install
--     XCMD_OUT       where [--clink] writes the data, instead of stdout

local script = {
    version = "0.21.5.0",

    -- The metavariable -> completion kind table.
    kinds = {
        FILE = "file",
        IMAGE = "file",
        PATH = "file",
        DIRECTORY = "dir",
        DIR = "dir",
        DEVICE = "dir",
        HOST = "host",
        ADDRESS = "ipv4",
        IP = "ipv4",
        IPV4 = "ipv4",
        MAC = "mac",
        ALIAS = "alias",
        HOSTIP = "hostip",
        SHELL = "shell",
        KIND = "kind",
        LETTER = "letter",
    },

    -- Metavariables that never name a completion source.
    kinds_skip = { OPTION = true, OPTIONS = true },
}

------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------

-- The report of [--check] goes to standard output, like the report of [--list]
-- and the status of [--install].  Only [die] writes to standard error, so a
-- message never mixes into the generated data of [--clink], and the report
-- survives the [2>nul] that masks the errors of the dispatch line.
local function warn(fmt, ...)
    io.write("WARN: " .. string.format(fmt, ...) .. "\n")
end

local function die(fmt, ...)
    io.stderr:write("ERROR: " .. string.format(fmt, ...) .. "\n")
    os.exit(1)
end

local function trim(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- A Lua literal for arbitrary text.
local function lua_string(s)
    return string.format("%q", s)
end

-- Split a quoted annotation payload into its quoted parts.
local function split_quoted(text)
    local parts, i = {}, 1
    while true do
        local b = text:find('"', i, true)
        if not b then break end
        local e = text:find('"', b + 1, true)
        if not e then break end
        parts[#parts + 1] = text:sub(b + 1, e - 1)
        i = e + 1
    end
    return parts
end

-- Resolve a path against the current directory.
local function resolve(path)
    if path:match("^[\\/]") or path:match("^%a:") then return path end
    local fh = io.open(path, "r")
    if fh then fh:close(); return path end
    return path
end

------------------------------------------------------------------------------
-- Kind resolution

-- The completion kinds of a metavariable expression, joined with ','.
--   ADDRESS      -> ipv4
--   MAC|HOST     -> mac,host
--   {yes|no}     -> enum:yes:no
local function kinds_of(expr)
    if not expr or expr == "" then return nil end
    expr = trim(expr)

    local enum = expr:match("^{(.*)}$")
    if enum then
        local vals = {}
        -- Both {a|b} and {a,b} are accepted.
        for v in enum:gmatch("[^|,]+") do
            v = trim(v)
            if v ~= "" then vals[#vals + 1] = v end
        end
        if #vals > 0 then return "enum:" .. table.concat(vals, ":") end
        return nil
    end

    local out = {}
    for word in expr:gmatch("[A-Za-z][A-Za-z0-9_]*") do
        local up = word:upper()
        if not script.kinds_skip[up] then
            local k = script.kinds[up]
            if k then out[#out + 1] = k end
        end
    end
    if #out == 0 then return nil end

    local seen, uniq = {}, {}
    for _, k in ipairs(out) do
        if not seen[k] then seen[k] = true; uniq[#uniq + 1] = k end
    end
    return table.concat(uniq, ",")
end

-- Split an option spec into its flag tokens and its metavariable kind.
--   "-o, --option=FILE"     -> { "-o", "--option" }, "file"
--   "-b, --broadcast=A,B"   -> { "-b", "--broadcast" }, "a,b"
local function flag_parts(spec)
    local flags, meta = {}, nil
    if type(spec) ~= "string" then return flags, meta end
    -- Split on spaces only: a metavariable list separates its names with a
    -- comma, as in [--find=[MAC,HOST]...], and the names are one expression.
    for tok in spec:gmatch("%S+") do
        local flag, expr = tok:match("^(%-[^=%[]*)[=%[]?(.*)$")
        if flag and flag ~= "" and flag:sub(1, 1) == "-" then
            flag = flag:gsub(",$", "")
            flags[#flags + 1] = flag
            if expr and expr ~= "" then
                local k = kinds_of((expr:gsub("]", "")))
                if k then meta = k end
            end
        end
    end
    return flags, meta
end

-- The operand kinds of a usage line, in order and without duplicates.
local function usage_kinds(usage)
    local out = {}
    for expr in usage:gmatch("{(.-)}") do
        local k = kinds_of("{" .. expr .. "}")
        if k then out[#out + 1] = k end
    end
    for expr in usage:gmatch("%[([^%]]*)%]") do
        local k = kinds_of(expr)
        if k then out[#out + 1] = k end
    end
    for expr in usage:gmatch("[A-Z][A-Z0-9_]+") do
        local k = kinds_of(expr)
        if k then out[#out + 1] = k end
    end
    local seen, uniq = {}, {}
    for _, k in ipairs(out) do
        if not seen[k] then seen[k] = true; uniq[#uniq + 1] = k end
    end
    return uniq
end

------------------------------------------------------------------------------
-- Annotation scanner
--
-- A [:::] line with a quoted string is an annotation; a [:::] line without one
-- is code ([::: if login], [::::::::::]).  [:::TODO] is a disabled annotation.
-- A label is [:xlib\...], [:x3rd\...], [:sub\[command]\[--option]] or an
-- internal [:this\...], [:legacy\...], [:skip\...] one.

local function scan(path)
    local fh = io.open(path, "r")
    if not fh then die("cannot read '%s'", path) end

    local records, i = {}, 0
    for line in fh:lines() do
        i = i + 1
        local body = line:match("^%s*(.*)$")

        if body:sub(1, 1) == ":" and body:sub(1, 2) ~= "::" then
            local scope, name = body:match("^:([^\\]+)\\([^\\]*)")
            if scope then
                records[#records + 1] = {
                    kind = (scope == "sub") and "sub" or "command",
                    scope = scope, name = name, line = i,
                }
            end
        elseif body:sub(1, 3) == ":::" then
            if body:find('"', 1, true) and body:sub(1, 4) ~= ":::T" then
                records[#records + 1] = {
                    kind = "annotation", parts = split_quoted(body), line = i,
                }
            end
        end
    end
    fh:close()
    return records
end

------------------------------------------------------------------------------
-- Annotation model
--
--   commands[k] = {
--       name, scope, brief, usage,
--       opts = { { spec, desc, flags = {...}, kinds }, ... },
--       operands = { { spec, desc }, ... }, operand_kinds = { kind, ... },
--   }

local function parse_model(path)
    local records = scan(path)
    local cmds, warns = {}, {}
    local pend, last_key = {}, nil

    local function command_for(scope, name, line)
        local key = scope .. "\0" .. name
        for _, c in ipairs(cmds) do
            if c.key == key then return c end
        end
        local cmd = {
            name = name, scope = scope, key = key, line = line,
            brief = "", usage = "", opts = {}, operands = {},
        }
        cmds[#cmds + 1] = cmd
        return cmd
    end

    -- Bind the accumulated annotation to the command [scope\name].
    local function flush_annot(scope, name, line)
        local cmd = command_for(scope, name, line)
        local brief, usage, extras = "", "", {}

        for _, rec in ipairs(pend) do
            for _, raw in ipairs(rec.parts) do
                local p = trim(raw)
                if p ~= "" then
                    if p:sub(1, 6) == "Usage:" then
                        if usage == "" then usage = p end
                    elseif brief == "" then
                        brief = p
                    else
                        extras[#extras + 1] = p
                    end
                end
            end
        end

        if cmd.brief == "" then cmd.brief = brief end
        if cmd.usage == "" and usage ~= "" then
            cmd.usage = usage
            cmd.operand_kinds = usage_kinds(usage)
        end
        for _, p in ipairs(extras) do
            local spec, desc = p:match("^(.-)%s%s+(.*)$")
            if spec then
                spec, desc = trim(spec), trim(desc)
                if spec:sub(1, 1) == "-" then
                    local flags, meta = flag_parts(spec)
                    if #flags > 0 then
                        cmd.opts[#cmd.opts + 1] = {
                            spec = spec, desc = desc, flags = flags, kinds = meta,
                        }
                    end
                else
                    cmd.operands[#cmd.operands + 1] = { spec = spec, desc = desc }
                    -- An operand spec names its completion kinds after the '=':
                    --   TARGET=ALIAS,HOSTIP   a MAC address, an alias or an IPv4
                    -- A '...' before the '=' marks an operand that may repeat, so
                    -- that every further operand is completed the same way.
                    local k = kinds_of(spec:match("=(.*)$") or spec)
                    if k then
                        cmd.operand_kinds = cmd.operand_kinds or {}
                        local seen = false
                        for _, v in ipairs(cmd.operand_kinds) do
                            if v == k then seen = true end
                        end
                        if not seen then
                            cmd.operand_kinds[#cmd.operand_kinds + 1] = k
                            if spec:find("%.%.%.") then
                                cmd.operand_loop = #cmd.operand_kinds
                            end
                        end
                    end
                end
            end
        end
        pend = {}
    end

    -- Bind one option annotation to the command [name].
    local function bind_option(rec, name, line)
        local parts = {}
        for _, raw in ipairs(rec.parts) do
            local p = trim(raw)
            if p ~= "" then parts[#parts + 1] = p end
        end

        local index = nil
        for j, p in ipairs(parts) do
            if p:sub(1, 1) == "-" then index = j; break end
        end

        local spec, desc = "", ""
        if index then
            local raw = parts[index]
            local head, tail = raw:match("^(.-)%s%s+(.*)$")
            if head then
                spec, desc = trim(head), trim(tail)
            else
                spec = raw
            end
            -- A part that reads as prose is the description.
            local function is_desc(p)
                local stripped = p:gsub("[%[%]%,:]", ""):gsub("%s", "")
                if stripped == "" then return false end
                if stripped:match("^[%u%d_]+$") then return false end
                return true
            end
            if desc == "" or not is_desc(desc) then
                for j = index + 1, #parts do
                    if is_desc(parts[j]) then desc = parts[j]; break end
                end
            end
        end

        local cmd = nil
        for _, c in ipairs(cmds) do
            if c.name == name then cmd = c; break end
        end

        local function add_sub(verb, verbdesc)
            if not cmd then
                warns[#warns + 1] = string.format(
                    "line %d: no command '%s' for subcommand '%s'",
                    rec.line, name, verb)
                return
            end
            cmd.subs = cmd.subs or {}
            cmd.subs[#cmd.subs + 1] = verb
            if verbdesc and verbdesc ~= "" then
                cmd.subdesc = cmd.subdesc or {}
                cmd.subdesc[verb] = verbdesc
            end
        end

        if spec == "" then
            -- The verb may sit in any part.  [::: "    start   start VM"]
            -- holds it in the first, [::: "" "    ova [VM]" "desc"] in the
            -- second.  Otherwise the text continues the previous option.
            local verb, verbdesc
            for _, raw in ipairs(rec.parts) do
                local p = trim(raw)
                if p ~= "" then
                    local head, tail = p:match("^(%S+)%s%s+(.*)$")
                    if head and head:sub(1, 1) ~= "-" then
                        verb, verbdesc = head, trim(tail)
                    elseif p:sub(1, 1) ~= "-" and not p:find("%s") then
                        verb = p
                    end
                    break
                end
            end
            if verb then
                add_sub(verb, verbdesc)
                return
            end
            local last = cmd and cmd.opts[#cmd.opts]
            if last and desc ~= "" then
                if last.desc == "" then last.desc = desc
                else last.desc = last.desc .. " " .. desc end
            else
                warns[#warns + 1] = string.format(
                    "line %d: unbound annotation", rec.line)
            end
            return
        end

        -- A single word that is not a flag is a subcommand verb.
        if spec:sub(1, 1) ~= "-" and not spec:find("%s") then
            add_sub(spec, desc)
            return
        end

        if not cmd then
            warns[#warns + 1] = string.format(
                "line %d: no command '%s' for option '%s'", rec.line, name, spec)
            return
        end
        local flags, meta = flag_parts(spec)
        if #flags > 0 then
            cmd.opts[#cmd.opts + 1] = {
                spec = spec, desc = desc, flags = flags, kinds = meta,
            }
        end
    end

    for _, r in ipairs(records) do
        if r.kind == "annotation" then
            pend[#pend + 1] = r
        elseif r.kind == "command" then
            local real = (r.scope == "xlib" or r.scope == "x3rd")
                and r.name ~= "" and r.name:sub(1, 1) ~= "-"
            if real then
                local key = r.scope .. "\0" .. r.name
                if #pend > 0 then
                    flush_annot(r.scope, r.name, r.line)
                    pend = {}
                    last_key = key
                elseif key == last_key then
                    command_for(r.scope, r.name, r.line)
                end
            elseif #pend > 0 then
                warns[#warns + 1] = string.format(
                    "line %d: unbound annotation", pend[1].line)
                pend = {}
            end
        elseif r.kind == "sub" then
            if #pend > 0 then
                bind_option(pend[1], r.name, r.line)
                pend = {}
            end
        end
    end
    if #pend > 0 then
        warns[#warns + 1] = string.format(
            "line %d: unbound annotation", pend[1].line)
    end

    return cmds, warns
end

------------------------------------------------------------------------------
-- Data emission

-- Write the completion data for every scanned script.  One entry per command,
-- with its option list and its operand kinds.
local function build_data(paths, sources)
    local out = {}
    out[#out + 1] = "-- eXternal Command clink completion data"
    out[#out + 1] = "-- Generated from the [:::] annotations by [x3rd comp]; do not edit."
    out[#out + 1] = "-- Sources: " .. table.concat(sources, " ")
    out[#out + 1] = ""
    out[#out + 1] = "return {"

    for _, path in ipairs(paths) do
        local commands = parse_model(path)
        for _, c in ipairs(commands) do
            local key = c.scope .. "\0" .. c.name
            out[#out + 1] = string.format("  [%s] = {", lua_string(key))
            out[#out + 1] = string.format("    brief = %s,", lua_string(c.brief))
            if c.usage ~= "" then
                out[#out + 1] = string.format("    usage = %s,", lua_string(c.usage))
            end
            if c.operand_kinds and #c.operand_kinds > 0 then
                local vals = {}
                for _, k in ipairs(c.operand_kinds) do
                    vals[#vals + 1] = lua_string(k)
                end
                out[#out + 1] = "    operands = { " .. table.concat(vals, ", ") .. " },"
            end
            if c.operand_loop then
                out[#out + 1] = string.format("    loop = %d,", c.operand_loop)
            end
            if #c.opts > 0 then
                out[#out + 1] = "    opts = {"
                for _, o in ipairs(c.opts) do
                    -- Each flag must be a quoted literal, or the generated
                    -- table parses the flag list as an expression.
                    local flags = {}
                    for _, f in ipairs(o.flags) do
                        flags[#flags + 1] = lua_string(f)
                    end
                    out[#out + 1] = string.format(
                        "      { {%s}, %s, %s },",
                        table.concat(flags, ", "),
                        o.kinds and lua_string(o.kinds) or "nil",
                        o.desc ~= "" and lua_string(o.desc) or "nil")
                end
                out[#out + 1] = "    },"
            end
            out[#out + 1] = "  },"
        end
    end

    out[#out + 1] = "}"
    return table.concat(out, "\n") .. "\n"
end

------------------------------------------------------------------------------
-- Check

local function cmd_check(paths)
    local bad = false
    for _, path in ipairs(paths) do
        local commands, warns = parse_model(path)
        for _, c in ipairs(commands) do
            if c.usage == "" then
                warn("%s %s: no usage line, so no operand completion",
                    c.scope, c.name)
            end
            if c.brief == "" then
                warn("%s %s: no brief", c.scope, c.name)
                bad = true
            end
            for _, o in ipairs(c.opts) do
                if o.desc == "" then
                    warn("%s %s: no description for '%s'", c.scope, c.name, o.spec)
                end
            end
        end
        for _, w in ipairs(warns) do warn("%s", w); bad = true end
    end
    if bad then os.exit(1) end
end

------------------------------------------------------------------------------
-- List

local function cmd_list(paths)
    for _, path in ipairs(paths) do
        for _, c in ipairs(parse_model(path)) do
            io.write(string.format("C\t%s\t%s\t\t%s\n", c.scope, c.name, c.brief))
            for _, o in ipairs(c.opts) do
                io.write(string.format("O\t%s\t%s\t%s\t%s\n",
                    c.scope, c.name, o.spec, o.desc))
            end
            for _, v in ipairs(c.subs or {}) do
                io.write(string.format("S\t%s\t%s\t%s\t%s\n",
                    c.scope, c.name, v, (c.subdesc or {})[v] or ""))
            end
        end
    end
end

------------------------------------------------------------------------------
-- The generated completion script
--
-- One file per command name.  Clink reads it when that command is typed, so
-- [xlib.lua] makes [xlib] complete and [x3rd.lua] makes [x3rd] complete.

-- The runtime, emitted once per generated file.  It is written as Lua source
-- so the generated script stays self-contained.
local RUNTIME = [[
-- The [hosts] section of the [.*.ini] configuration, in the order of the files:
-- the profile directory first and the script directory second, which is what
-- [xlib hosts] reads.  A row is { key = the alias, value = its addresses }.
local function hosts_ini()
    local dirs = {}
    local home = os.getenv("USERPROFILE") or os.getenv("HOME")
    if home and home ~= "" then dirs[#dirs + 1] = home:gsub("[\\/]$", "") end
    if xcmd_dir and xcmd_dir ~= "" then dirs[#dirs + 1] = xcmd_dir:gsub("[\\/]$", "") end

    local files = {}
    for _, d in ipairs(dirs) do
        local pipe = io.popen('dir /b /a-d "' .. d .. '\\.*.ini" 2>nul')
        if pipe then
            for line in pipe:lines() do
                local name = line:match("^%s*(.-)%s*$")
                if name ~= "" then files[#files + 1] = d .. "\\" .. name end
            end
            pipe:close()
        end
    end

    local out, section = {}, false
    for _, file in ipairs(files) do
        local fh = io.open(file, "r")
        if fh then
            for line in fh:lines() do
                -- Drop the line ending and the comment, then trim the text.
                local text = (line:gsub("\r", ""):gsub("[;#].*$", ""))
                text = text:match("^%s*(.-)%s*$")
                if text:match("^%[.*%]$") then
                    section = (text == "[hosts]")
                elseif section then
                    local key, value = text:match("^([^=]+)=(.*)$")
                    if key then
                        key = key:match("^%s*(.-)%s*$")
                        value = value:match("^%s*(.-)%s*$")
                        if key ~= "" and value ~= "" then
                            out[#out + 1] = { key = key, value = value }
                        end
                    end
                end
            end
            fh:close()
        end
    end
    return out
end

-- Local candidates, so a reload does not need the data file again.
local candidates = {
    letter = function()
        local out = {}
        for i = 0, 25 do
            local ch = string.char(65 + i)
            local ok, ty = pcall(os.getdrivetype, ch .. ":")
            if ok and ty and ty ~= "invalid" and ty ~= "" then
                out[#out + 1] = ch .. ":"
            end
        end
        return out
    end,

    ipv4 = function()
        local out = {}
        local pipe = io.popen('ipconfig.exe 2>nul')
        if pipe then
            for line in pipe:lines() do
                local ip = line:match("IPv4[^:]*:%s*([%d%.]+)")
                if ip then out[#out + 1] = ip end
            end
            pipe:close()
        end
        return out
    end,

    mac = function()
        local out = {}
        local pipe = io.popen('arp.exe -a 2>nul')
        if pipe then
            for line in pipe:lines() do
                local mac = line:match("^%s*[%d%.]+%s+([%x][%x%-]+)%s")
                if mac then out[#out + 1] = (mac:lower():gsub("%-", ":")) end
            end
            pipe:close()
        end
        return out
    end,

    host = function()
        local out = {}
        for _, row in ipairs(hosts_ini()) do
            out[#out + 1] = row.key
            for ip in row.value:gsub("|", " "):gmatch("%d+%.%d+%.%d+%.%d+") do
                out[#out + 1] = ip
            end
        end
        return out
    end,

    alias = function()
        local out = {}
        for _, row in ipairs(hosts_ini()) do out[#out + 1] = row.key end
        return out
    end,

    -- An IPv4 address of the hosts file that the [hosts] ini omits, which is
    -- how an address is completed before [xlib hosts] has named it.
    hostip = function()
        local known = {}
        for _, row in ipairs(hosts_ini()) do
            for ip in row.value:gsub("|", " "):gmatch("%d+%.%d+%.%d+%.%d+") do
                known[ip] = true
            end
        end
        local out = {}
        local root = os.getenv("SystemRoot") or "C:\\Windows"
        local fh = io.open(root .. "\\System32\\drivers\\etc\\hosts", "r")
        if fh then
            for line in fh:lines() do
                local ip = line:match("^%s*(%d+%.%d+%.%d+%.%d+)%s")
                if ip and not known[ip]
                    and not ip:match("^0%.") and not ip:match("^127%.")
                    and not ip:match("^169%.254%.")
                    and not ip:match("^2[2-5]%d%.") then
                    out[#out + 1] = ip
                end
            end
            fh:close()
        end
        return out
    end,

    shell = function()
        return { "cmd.exe", "bash.exe", "sh.exe", "powershell.exe" }
    end,

    kind = function()
        return { "file", "dir", "letter", "ipv4", "mac",
                 "host", "alias", "hostip", "shell", "kind" }
    end,
}

-- A match function for one kind expression, usable as an argmatcher argument.
-- [file] and [dir] are left to the clink default completion, so a parser that
-- only asks for those gets no function and keeps file completion.
local function value_fn(expr)
    if not expr or expr == "" then return nil end

    local enum = expr:match("^enum:(.*)$")
    if enum then
        local values = {}
        for v in enum:gmatch("[^:]+") do values[#values + 1] = v end
        return function(word)
            local out = {}
            for _, v in ipairs(values) do
                if word == "" or v:sub(1, #word) == word then out[#out + 1] = v end
            end
            return out
        end
    end

    -- A bare [file] or [dir] keeps the clink default completion, so no match
    -- function is made.  clink.filematches is a function, not a string, so it
    -- cannot be concatenated onto a flag either.
    if expr == "file" or expr == "dir" then return nil end

    local kinds = {}
    for k in expr:gmatch("[^,]+") do
        if candidates[k] then kinds[#kinds + 1] = k end
    end
    if #kinds == 0 then return nil end

    return function(word)
        local out, seen = {}, {}
        -- The matches of one kind stay together, so a metavariable list reads
        -- as groups and keeps the order the annotation declares.  Each kind is
        -- sorted on its own, and a value that two kinds share appears once.
        for _, k in ipairs(kinds) do
            local list = candidates[k]()
            table.sort(list)
            for _, v in ipairs(list) do
                if not seen[v] and (word == "" or v:sub(1, #word) == word) then
                    seen[v] = true
                    out[#out + 1] = v
                end
            end
        end
        return out
    end
end

-- Attach the descriptions, one call at a time.  A single call with all of them
-- is faster, but [unpack] is not a global in Lua 5.2 (the version clink embeds),
-- so the variadic use is avoided and each table is passed on its own.
local function add_descs(matcher, items)
    if #items == 0 then return end
    for _, item in ipairs(items) do
        pcall(function() matcher:adddescriptions(item) end)
    end
end

-- Link a flag that takes a value to a parser holding that value.
--
-- The link is built in TWO statements on purpose.  Inside a nested function
-- clink evaluates [flag .. "=" .. parser] as one constant expression and fails
-- with "attempt to concatenate constant '='", so the flag and the separator are
-- concatenated first and the parser is appended after.  [clink.filematches] is
-- a function, not a string, so a flag whose value is a plain file or directory
-- is returned unlinked and keeps the file completion clink already provides.
local function link_flag(flag, fn)
    if not fn then return flag end
    local value_parser = clink.argmatcher()
    -- [nosort] keeps the kinds of the metavariable in the declared order, the
    -- way the bash and zsh engines list them, instead of one sorted list.
    value_parser:addarg({ fn, nosort = true })
    local head = flag .. "="
    return head .. value_parser
end

-- Build the parser of one subcommand: its options, each linked to its value,
-- and its operands in order.  A data row is { { flags }, kind, description }.
local function sub_parser(cmd)
    local parser = clink.argmatcher()
    local flags = {}
    local descs = {}

    for _, row in ipairs(cmd.opts or {}) do
        local names, kind, desc = row[1], row[2], row[4]
        local fn = value_fn(kind)
        for _, f in ipairs(names or {}) do
            flags[#flags + 1] = link_flag(f, fn)
            if desc and desc ~= "" then
                descs[#descs + 1] = { f, description = desc }
            end
        end
    end
    if #flags > 0 then parser:addflags(flags) end

    local kinds = cmd.operands
    if kinds and #kinds > 0 then
        -- One argument position per operand kind, in order.  A kind with no
        -- value function keeps the file completion clink already provides.
        for _, k in ipairs(kinds) do
            local fn = value_fn(k)
            if fn then
                parser:addarg({ fn, nosort = true })
            else
                parser:addarg(clink.filematches)
            end
        end
        -- An operand marked as repeatable keeps completing the same way at
        -- every further position, the way the bash engine does.
        if cmd.loop then parser:loop(cmd.loop) end
    end

    add_descs(parser, descs)
    return parser
end

-- Register the commands of one scope: [xlib] or [x3rd].
-- Register the commands of one scope: [xlib] or [x3rd].
--
-- Only flags carry descriptions.  A command name is listed on its own, the way
-- the bash and zsh completion lists it, so [xlib <TAB>] shows command names
-- and not the help text of each command.
local function register(scope, data)
    if not clink or not clink.argmatcher then return end

    local cmds = {}
    for key, cmd in pairs(data) do
        if key:sub(1, #scope + 1) == scope .. "\0" then
            local name = key:sub(#scope + 2)
            cmds[#cmds + 1] = name .. sub_parser(cmd)
        end
    end
    if #cmds == 0 then return end

    local matcher = clink.argmatcher(scope)
    matcher:addarg(cmds)
    matcher:addflags({ "-h", "--help" })
    add_descs(matcher, { { "-h", "--help", description = "Show help" } })
end
]]

local function build_clink(paths, sources, scope)
    local out = {}
    out[#out + 1] = "-- eXternal Command clink completion for [" .. scope .. "]"
    out[#out + 1] = "-- Generated from the [:::] annotations by [x3rd comp]; do not edit."
    out[#out + 1] = "-- Sources: " .. table.concat(sources, " ")
    out[#out + 1] = ""
    out[#out + 1] = "-- The data sits beside this file, so a reload picks up an edit."
    out[#out + 1] = "local dir = debug.getinfo(1, \"S\").source:match(\"^@(.*[\\\\/])\") or \".\\\\\""
    out[#out + 1] = "local data = dofile(dir .. \"xcmd_completion.lua\")"
    -- The [#hosts] ini of the script directory is a candidate source, so the
    -- directory of the annotated script is passed on.
    local src_dir = paths[1] and paths[1]:match("^(.*[\\/])[^\\/]*$") or ""
    out[#out + 1] = "local xcmd_dir = " .. lua_string(src_dir)
    out[#out + 1] = ""
    out[#out + 1] = RUNTIME
    out[#out + 1] = ""
    out[#out + 1] = "register(" .. lua_string(scope) .. ", data)"
    return table.concat(out, "\n") .. "\n"
end

------------------------------------------------------------------------------
-- Install
--
-- Write [xlib.lua] and [x3rd.lua] into the clink completions directory, with
-- the shared data beside them.  Clink reads a file only when the command of
-- the same name is typed, so the file name is what makes it load.

local function read_file(path)
    local fh = io.open(path, "r")
    if not fh then return nil end
    local text = fh:read("*a")
    fh:close()
    return text
end

-- Create a directory, and say whether it exists afterwards.  The clink
-- [os.mkdir] is used rather than [os.execute "mkdir ..."], because a Windows
-- path does not survive the quoting of the shell command.
local function mkdir(path)
    if os.isdir(path) then return true end
    if os.mkdir then pcall(os.mkdir, path) else
        os.execute('mkdir "' .. path .. '" 2>nul')
    end
    return os.isdir(path) and true or false
end

-- The clink completions directory: the profile directory, else the local one.
local function clink_dir(override)
    if override and override ~= "" then return override end
    local env = os.getenv("CLINK_COMPLETIONS_DIR")
    if env and env ~= "" then return env:match("^([^;]+)") end
    local profile = os.getenv("CLINK_PROFILE")
    if profile and profile ~= "" then return profile .. "\\completions" end
    local local_app = os.getenv("LOCALAPPDATA")
    if local_app and local_app ~= "" then
        return local_app .. "\\clink\\completions"
    end
    return nil
end

local function cmd_install(paths, sources, dir)
    local target = clink_dir(dir)
    if not target then die("cannot locate the clink completions directory") end
    if not mkdir(target) then die("cannot create '%s'", target) end

    local data_file = target .. "\\xcmd_completion.lua"
    local fh = io.open(data_file, "w")
    if not fh then die("cannot write '%s'", data_file) end
    fh:write(build_data(paths, sources))
    fh:close()
    io.write(data_file, "\n")

    -- One script per scope.  Clink reads [scope.lua] when that command is
    -- typed, which is what makes the completion load on demand.
    local scopes = {}
    for _, path in ipairs(paths) do
        for _, c in ipairs(parse_model(path)) do
            local seen = false
            for _, s in ipairs(scopes) do if s == c.scope then seen = true end end
            if not seen then scopes[#scopes + 1] = c.scope end
        end
    end

    for _, scope in ipairs(scopes) do
        local file = target .. "\\" .. scope .. ".lua"
        local g = io.open(file, "w")
        if not g then die("cannot write '%s'", file) end
        g:write(build_clink(paths, sources, scope))
        g:close()
        io.write(file, "\n")
    end

    -- Clink reads a Lua script once per session, so tell the user how to make
    -- it load again rather than leaving the completion looking broken.
    io.write("\n")
    io.write("Reload clink to use them: press Ctrl-x Ctrl-r in the clink session,\n")
    io.write("or start a new cmd.exe.  Clink loads a completion script only when it\n")
    io.write("starts or when it is reloaded.\n")
end

------------------------------------------------------------------------------
-- Entry
--
-- Every value can also come from an XCMD_* environment variable, so that the
-- generator can run from standard input, where [arg] does not exist.

local function usage()
    io.write([[
Usage: comp [OPTION]...

  -c, --clink              print the clink completion data
  -i, --install[=DIR]      install the completion scripts to the clink directory
  -l, --list               print the parsed completion metadata
  -k, --check              check the annotation and print warnings
      --runtime=PATH       the static runtime file to install
  -h, --help               print this help

A script to scan may be given as a positional argument or with [--file=PATH].
When the generator runs from standard input, use XCMD_MODE, XCMD_SOURCE,
XCMD_SOURCE2, XCMD_DIR, XCMD_RUNTIME and XCMD_OUT instead.
]])
end

local function main(argv)
    argv = argv or {}
    local files, mode, dir, runtime = {}, os.getenv("XCMD_MODE"), nil, nil

    local env_dir = os.getenv("XCMD_DIR")
    if env_dir and env_dir ~= "" then dir = env_dir end
    local env_rt = os.getenv("XCMD_RUNTIME")
    if env_rt and env_rt ~= "" then runtime = env_rt end
    for _, var in ipairs({ "XCMD_SOURCE", "XCMD_SOURCE2" }) do
        local v = os.getenv(var)
        if v and v ~= "" then files[#files + 1] = v end
    end

    local i = 1
    while i <= #argv do
        local a = argv[i]
        if a == "-h" or a == "--help" then
            usage(); return 0
        elseif a == "-c" or a == "--clink" then
            mode = "clink"
        elseif a == "-i" or a == "--install" then
            mode = "install"
            local nxt = argv[i + 1]
            if nxt and nxt:sub(1, 1) ~= "-" then
                local probe = io.open(nxt, "r")
                if probe then probe:close() else dir = nxt; i = i + 1 end
            end
        elseif a:match("^%-%-install=") then
            mode, dir = "install", a:sub(11)
        elseif a == "-l" or a == "--list" then
            mode = "list"
        elseif a == "-k" or a == "--check" then
            mode = "check"
        elseif a == "--file" then
            files[#files + 1] = argv[i + 1]; i = i + 1
        elseif a:match("^%-%-file=") then
            files[#files + 1] = a:sub(8)
        elseif a == "--runtime" then
            runtime = argv[i + 1]; i = i + 1
        elseif a:match("^%-%-runtime=") then
            runtime = a:sub(11)
        else
            files[#files + 1] = a
        end
        i = i + 1
    end

    local paths, sources = {}, {}
    for _, f in ipairs(files) do
        paths[#paths + 1] = resolve(f)
        sources[#sources + 1] = f
    end

    if mode == "list" then
        cmd_list(paths)
        return 0
    elseif mode == "check" then
        cmd_check(paths)
        return 0
    end
    if #paths == 0 then die("no input; pass the annotated scripts") end

    if mode == "install" then
        cmd_install(paths, sources, dir, runtime)
    else
        local text = build_data(paths, sources)
        local out = os.getenv("XCMD_OUT")
        if out and out ~= "" then
            local fh = io.open(out, "w")
            if not fh then die("cannot write '%s'", out) end
            fh:write(text)
            fh:close()
        else
            io.write(text)
        end
    end
    return 0
end

-- When this file is piped into [clink lua], [arg] is nil: the arguments come
-- from the environment instead.
return main(arg)
```

   :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::             Embedded Documents            ::
:::::::::::::::::::::::::::::::::::::::::::::::
