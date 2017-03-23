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

:::::::::::::::::::::::::::
:: dis = dism & diskpart ::
:::::::::::::::::::::::::::

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
if errorlevel 500 exit /b 1
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

REM for :lib\2la and :lib\rpad and
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
    for %%a in (%~1) do if "%%~$path:a" neq "" exit /b 0
    exit /b 1

::: "Copy Window PE boot file from CDROM" "" "usage: %~n0 bootfile [target_letter]"
:::: "target_letter not exist" "Window PE CDROM not found"
:dis\bootfile
    if not exist "%~d1" exit /b 1
    for /l %%a in (0,1,9) do if exist \\?\CDROM%%a\boot\boot.sdi (
        for %%b in (
            \bootmgr
            \boot\bcd
            \boot\boot.sdi
            \efi\boot\bootx64.efi
            \efi\microsoft\boot\bcd
            \sources\boot.wim
        ) do (
            if not exist %~d1%%~pb mkdir %~d1%%~pb
            copy /y \\?\CDROM%%a%%b %~d1%%b
        )
        exit /b 0
    )
    exit /b 2

::: "Add or Remove Web Credential" "" "usage: %~n0 crede [option] [args...]" "    --add,    -a [user]@[ip or host] [[password]]" "    --remove, -r [ip or host]"
:::: "option invalid" "parameter not enough" "Command error" "ho ip or host"
:dis\crede
    call :this\crede\%*
    goto :eof

:this\crede\--add
:this\crede\-a
    if "%~1"=="" exit /b 2
    setlocal
    set \\\prefix=
    set \\\suffix=
    for /f "usebackq tokens=1* delims=@" %%a in (
        '%~1'
    ) do set \\\prefix=%%a& set \\\suffix=%%b

    if not defined \\\suffix exit /b 4

    REM Clear Credential
    call :this\crede\-r %\\\suffix% >nul

    set \\\arg=
    if "%~2" neq "" set \\\arg=/pass:%~2
    REM Add credential
    echo cmdkey.exe /add:%\\\suffix% /user:%\\\prefix% %\\\arg%
    >nul cmdkey.exe /add:%\\\suffix% /user:%\\\prefix% %\\\arg% || exit /b 3
    endlocal
    exit /b 0

:this\crede\--remove
:this\crede\-r
    if "%~1"=="" exit /b 2
    cmdkey.exe /delete:%~1
    exit /b 0


::: "Mount / Umount samba" "" "usage: %~n0 smb [option] [args...]" "    --mount,     -m  [ip or hosts] [path...]   Mount samba" "    --umount,    -u  [ip or --all]             Umount samba" "    --umountall, -ua                           Umount all samba"
:::: "option invalid" "parameter not enough" "Command error"
:dis\smb
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
:::: "option invalid" "parameter is empty" "lib.cmd not found" "parameter not a ip" "can not connect remote host"
:dis\nfs
    call :this\nfs\%*
    exit /b 0

:this\nfs\--mount
:this\nfs\-m
    if "%~1"=="" exit /b 2
    call :this\iinpath lib.cmd || exit /b 3
    call lib.cmd iip %~1 || exit /b 4
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
    ) do reg.exe add HKLM\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default /v %%a /t REG_DWORD /d 0 /f
    call :dis\ocsetup ServicesForNFS-ClientOnly; ClientForNFS-Infrastructure; NFS-Administration
    REM start /w Ocsetup.exe ServicesForNFS-ClientOnly;ClientForNFS-Infrastructure;NFS-Administration /norestart
    exit /b 0

::: "Lock / Unlock partition with BitLocker" "" "usage: %~n0 block [option] [args...]" "    --lock   [[passwd]]" "    --unlock [[passwd]]"
:::: "option invalid" "Partition not found"
:dis\block
    if not exist "%~1" exit /b 2
    call :this\bit\%*
    goto :eof

:this\bit\--lock
    manage-bde.exe -on %~d1 -UsedSpaceOnly -Password %~2
    exit /b 0

:this\bit\--unlock
    manage-bde.exe -on %~d1 -UsedSpaceOnly -RecoveryPassword %~2
    exit /b 0

:::::::::
:: vhd ::
:::::::::

::: "Virtual Hard Disk manager" "" "usage: %~n0 vhd [option] [args...]" "" "    --new,    -n  [new_vhd_path] [size[GB]] [[mount_letter]]    Creates a virtual disk file." "    --mount,  -m  [vhd_path] [[letter]]                Mount vhd file" "    --umount, -u  [vhd_path]                           Unmount vhd file" "    --expand, -e  [vhd_path] [GB_size]                 Expands the maximum size available on a virtual disk." "    --differ, -d  [new_vhd_path] [source_vhd_path]     Create differencing vhd file by an existing virtual disk file" "    --merge,  -me  [chile_vhd_path] [[merge_depth]]    Merges a child disk with its parents" "    --rec,    -r                                       Recovery child vhd if have parent" "e.g." "    %~n0 vhd -n E:\nano.vhdx 30 V:"
:::: "option invalid" "file suffix not vhd/vhdx" "file not found" "no volume find" "vhd size is empty" "letter already use" "diskpart error:" "not a letter" "lib.cmd not found" "size not num" "parent vhd not found" "new file allready exist"
:dis\vhd
    call :this\vhd\%*
    goto :eof

:this\vhd\--new
:this\vhd\-n
    if "%~1"=="" exit /b 3
    if not exist "%~dp1" exit /b 4
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    if "%~2"=="" exit /b 5
    if "%~3" neq "" if exist "%~d3" exit /b 6
    REM make vhd
    >%tmp%\.diskpart (
        setlocal enabledelayedexpansion
        set /a \\\size=%2*1024+8
        echo create vdisk file="%~f1" maximum=!\\\size! type=expandable
        endlocal
        echo attach vdisk
        echo create partition primary
        echo format fs=ntfs quick
        if "%~3"=="" (echo assign) else echo assign letter=%~d3
    )
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:this\vhd\--mount
:this\vhd\-m
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    if "%~2" neq "" (
        if "%~d2" neq "%~2" exit /b 8
        if exist "%~2" exit /b 6
    )
    >%tmp%\.diskpart (
        echo select vdisk file="%~f1"
        echo attach vdisk
        if "%~2"=="" (echo assign) else echo assign letter=%~3
    )
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:this\vhd\--umount
:this\vhd\-u
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    REM unmount vhd
    >%tmp%\.diskpart (
        echo select vdisk file="%~f1"
        echo detach vdisk
    )
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:this\vhd\--expand
:this\vhd\-e
    if not exist "%~1" exit /b 3
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 2
    call :this\iinpath lib.cmd || exit /b 9
    call lib.cmd inum %~2 || exit /b 10
    REM unmount vhd
    call :dis\vumount %1 > nul
    setlocal
    set /a \\\size=%~2*1024+8
    >%tmp%\.diskpart (
        echo select vdisk file="%~f1"
        echo expand vdisk maximum=%\\\size%
    )
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    endlocal
    exit /b 0

:this\vhd\--differ
:this\vhd\-d
    if not exist "%~2" exit /b 11
    if exist "%~1" exit /b 12
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 2
    >%tmp%\.diskpart echo create vdisk file="%~f1" parent="%~f2"
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:this\vhd\--merge
:this\vhd\-me
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    setlocal
    set \\\depth=1
    if "%~2" neq "" set \\\depth=%~2
    >%tmp%\.diskpart (
        echo select vdisk file="%~f1"
        echo merge vdisk depth=%\\\depth%
    )
    endlocal
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:::
:this\vhd\--rec
:this\vhd\-r
    setlocal
    set /p \\\i=[Warning] Child vhd will be recovery, Yes^|No:
    if /i "%\\\i%" neq "y" if /i "%\\\i%" neq "yes" exit /b 0
    endlocal

    chcp.com 437 >nul

    REM Make vdisk info script
    >%tmp%\.diskpart type nul
    for /f "usebackq skip=1" %%a in (
        `wmic.exe logicaldisk where DriveType^=3 get name`
    ) do if exist %%a\*.vhd? for /f "usebackq delims=" %%b in (
        `dir /a /b %%a\*.vhd?`
    ) do >>%tmp%\.diskpart (
        echo select vdisk file="%%a\%%b"
        echo detail vdisk
    )

    REM Make create child vhd script
    for /f "usebackq tokens=1,2*" %%a in (
        `diskpart.exe /s %tmp%\.diskpart ^& ^>%tmp%\.diskpart type nul`
    ) do >>%tmp%\.diskpart (
        if "%%a"=="Filename:" set /p=create vdisk file="%%b"<nul
        if "%%a%%b"=="ParentFilename:" echo. parent="%%c"
    )

    move /y %tmp%\.diskpart %tmp%\.tmp

    REM Filter parent vhd, and delete child vhd
    for /f "usebackq delims=" %%a in (
        "%tmp%\.tmp"
    ) do for /f usebackq^ tokens^=2^,4^ delims^=^" %%b in (
        '%%a'
    ) do if "%%c"=="" (
        REM "
        move "%%b" "%%b.snapshot"
        >>%tmp%\.diskpart echo create vdisk file="%%b" parent="%%b.snapshot"
    ) else (
        erase /a /q %%b
        >>%tmp%\.diskpart echo %%a
    )

    REM Create new child vhd
    diskpart.exe /s %tmp%\.diskpart

    exit /b 0

::::::::::
:: dism ::
::::::::::

::: "Wim manager" "" "usage: %~n0 wim [option] [args ...]" "    --new,    -n [target_dir_path] [[image_name]]            Capture file/directory to wim" "    --apply,  -a [wim_path] [[output_path] [image_index]]    Apply WIM file" "    --mount,  -m [wim_path] [mount_path] [[image_index]]     Mount wim" "    --umount, -u [mount_path]                                Unmount wim" "    --commit, -c [mount_path]                                Unmount wim with commit" "    --export, -e [source_wim_path] [target_wim_path] [image_index] [[compress_level]]    Export wim image" "                                   compress level: 0 none, 1 fast, 2 recovery, 3 WIMBoot, 4 max" "    --umountall, -ua                                         Unmount all wim" "    --rmountall, -ra                                         Recovers mount all orphaned wim"
:::: "option invalid" "lib.cmd not found" "dism version is too old" "target not found" "need input image name" "dism error" "wim file not found" "not wim file" "output path allready use" "output path not found" "Not a path" "Target wim index not select"
:dis\wim
    call :this\iinpath lib.cmd || exit /b /b 2
    call :this\wim\%*
    goto :eof

:this\wim\--new
:this\wim\-n
    call lib.cmd ivergeq 6.3 || exit /b 3
    if not exist "%~1" exit /b 4
    if "%~n1%~2"=="" exit /b 5
    setlocal
    REM wim name
    if "%~2"=="" (
        set \\\name=%~nx1
    ) else set \\\name=%~2

    REM input args
    call lib.cmd idir %1 && (
        set \\\input=%~f1
    ) || set \\\input=%~dp1
    if "%\\\input:~-1%"=="\" set \\\input=%\\\input:~0,-1%
    REM New or Append
    if exist ".\%\\\name%.wim" (set \\\create=Append) else set \\\create=Capture
    REM Create exclusion list
    call lib.cmd gnow \\\conf "%tmp%\" .log
    set \\\args=
    call :wim\ConfigFile %1 > %\\\conf% && set \\\args=/ConfigFile:"%\\\conf%"
    REM Do capture
    dism.exe /English /%\\\create%-Image /ImageFile:".\%\\\name%.wim" /CaptureDir:"%\\\input%" /Name:"%\\\name%" /Verify %\\\args% || exit /b 6
    if exist "%\\\conf%" erase "%\\\conf%"
    endlocal
    exit /b 0

REM create exclusion list
:wim\ConfigFile
    if not exist "%~1" exit /b 1
    call lib.cmd idir %1 && exit /b 2
    echo [ExclusionList]
    for /f "usebackq delims=" %%a in (
        `dir /a /b "%~dp1"`
    ) do if "%%a" neq "%~nx1" echo \%%a
    exit /b 0

:this\wim\--apply
:this\wim\-a
    call lib.cmd ivergeq 6.3 || exit /b 3
    if not exist "%~1" exit /b 7
    if /i "%~x1" neq ".wim" exit /b 8
    if "%~2"=="" mkdir ".\%~n1" 2>nul || exit /b 9
    if "%~2" neq "" call lib.cmd idir "%~2" || exit /b 10
    setlocal
    if "%~2"=="" (
        set \\\out=.\%~n1
    ) else set \\\out=%~f2
    REM Trim path
    if "%\\\out:~-1%"=="\" set \\\out=%\\\out:~0,-1%
    if "%~3"=="" (
        call :getWimLastIndex %1 \\\index
    ) else set \\\index=%~3
    dism.exe /English /Apply-Image /ImageFile:"%~f1" /Index:%\\\index% /ApplyDir:"%\\\out%" /Verify || exit /b 6
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
    call lib.cmd idir %2 || exit /b 4
    setlocal
    if "%~3"=="" (
        call :getWimLastIndex %1 \\\index
    ) else set \\\index=%3
    dism.exe /Mount-Wim /WimFile:"%~f1" /index:%\\\index% /MountDir:"%~f2" || exit /b 6
    endlocal
    exit /b 0

:this\wim\--umount
:this\wim\-u
    call lib.cmd idir %1 || exit /b 4
    dism.exe /Unmount-Wim /MountDir:"%~f1" /discard
    exit /b 0

:this\wim\--commit
:this\wim\-c
    call lib.cmd idir %1 || exit /b 4
    dism.exe /Unmount-Wim /MountDir:"%~f1" /commit
    exit /b 0

:this\wim\--export
:this\wim\-e
    if not exist %1 exit /b 7
    if /i "%~x1" neq ".wim" exit /b 8
    if "%~f2" neq "%~2" exit /b 11
    if /i "%~x2" neq ".wim" exit /b 8
    if "%~3"=="" exit /b 12
    setlocal
    set \\\compress=
    if "%~4"=="0" set \\\compress=/Compress:none
    if "%~4"=="1" set \\\compress=/Compress:fast
    if "%~4"=="2" set \\\compress=/Compress:recovery
    if "%~4"=="3" set \\\compress=/WIMBoot
    if "%~4"=="4" set \\\compress=/Compress:max
    dism.exe /Export-Image /SourceImageFile:"%~f1" /SourceIndex:%3 /DestinationImageFile:"%~f2" /Bootable %\\\compress% /CheckIntegrity
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
        if "%%~a"=="Mount" set \\\m=
        if "%%~a%%~b"=="MountDir" if exist "%%~d" set "\\\m=%%~d"
        if "%%~a%%~d"=="StatusRemount" if defined \\\m dism.exe /Remount-Wim /MountDir:"!\\\m!"
    )
    endlocal
    echo.complate.
    exit /b 0

REM ::: ""
REM :this\wim\--info
REM     for /f "usebackq tokens=1,2*" %%b in (
REM         `dism.exe /English /Get-WimInfo /WimFile:%1`
REM     ) do if "%%b"=="Index" for /f "usebackq tokens=1,2*" %%f in (
REM         `dism.exe /English /Get-WimInfo /WimFile:%1 /Index:%%d`
REM     ) do if "%%h" neq "<undefined>" (
REM         if "%%f"=="Description" set /p=%%h <nul
REM         if "%%f"=="Size" set /p=%%h <nul
REM         if "%%f%%g%%h"=="WIMBootable: Yes" set /p=wimboot <nul
REM         if "%%f"=="Architecture" set /p=%%h <nul
REM         if "%%f"=="Version" set /p=%%h <nul
REM         if "%%f"=="Edition" set /p=%%h <nul
REM         if "%%g"=="(Default)" set /p=%%f <nul
REM     )
REM     exit /b 0

::: "Component Cleanup" "" "usage: %~n0 cleanup [path]"
:::: "option invalid" "lib.cmd not found" "not a directory"
:dis\cleanup
    if "%~1"=="" dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase & exit /b 0
    call :this\iinpath lib.cmd || exit /b 2
    call lib.cmd idir "%~1" || exit /b 3
    dism.exe /Image:%1 /Cleanup-Image /StartComponentCleanup /ResetBase
    exit /b 0

::: "Drivers manager" "" "usage: %~n0 drv [option] [args...]" "    --add    [os_path] [drv_path ...]   Add drivers offline" "    --list   [[os_path]]                Show OS drivers list" "    --remove [os_path] [[name].inf]     remove drivers, 3rd party drivers like oem1.inf"
:::: "option invalid" "lib.cmd not found" "OS path not found" "Not drivers name" "dism error"
:dis\drv
    call :this\iinpath lib.cmd || exit /b 2
    call :this\drv\%*
    goto :eof

:this\drv\-a
:this\drv\--add
    call lib.cmd idir %1 || exit /b 3
    REM Will install at \Windows\System32\DriverStore\FileRepository
    for %%a in (%*) do call lib.cmd idir && (
        dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a /Recurse || REM
    ) || if /i "%%~xa"==".inf" dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a
    exit /b 0

:this\drv\-l
:this\drv\--list
    if "%~1" neq "" call lib.cmd idir %1 || exit /b 3
    if "%~1"=="" (
        dism.exe /Online /Get-Drivers /all || exit /b 5
    ) else dism.exe /Image:"%~f1" /Get-Drivers /all || exit /b 5
    exit /b 0

:this\drv\-r
:this\drv\--remove
    call lib.cmd idir %1 || exit /b 2
    if /i "%~x2" neq ".inf" exit /b 4
    dism.exe /Image:"%~f1" /Remove-Driver /Driver:%~2 || exit /b 5
    exit /b 0


::: "Feature manager" "" "usage: %~n0 oc [option] [args ...]" "    --info,   -i               Get Feature list" "    --enable, -e [name ...]    Enable Feature"
:::: "option invalid" "parameter is empty"
:dis\oc
    call :this\oc\%*
    goto :eof

:this\oc\--info
:this\oc\-i
    for /f "usebackq tokens=1-4" %%a in (
        `dism.exe /English /Online /Get-Features`
    ) do (
        if "%%a%%b"=="FeatureName" call :this\rpad %%d
        if "%%a"=="State" call :this\rpad %%c & echo.
    )
    call :this\rpad 0 0
    exit /b 0

:this\oc\--enable
:this\oc\-e
    if "%~1"=="" exit /b 2
    for %%a in (
        %*
    ) do dism.exe /English /Online /Enable-Feature /FeatureName:%%a /NoRestart
    exit /b 0

:::::::::
:: KMS ::
:::::::::

::: "KMS Client" "" "usage: %~n0 kms [option] [args...]" "    --os     [[ipv4]]    Active OS" "    --office [[ipv4]]    Active office" "e.g." "    %~n0 kms --os 192.168.1.1"
:::: "option invalid" "lib.cmd not found" "Need ip or host" "OS not support" "No office found" "office not support"
:dis\kms
    call :this\kms\%*
    goto :eof

REM OS
:this\kms\--os
    call :this\iinpath lib.cmd || exit /b 2

    setlocal
    if "%~1"=="" (
        if "%~d0" neq "\\" exit /b 3
        for /f "usebackq delims=\" %%a in (
            '%~p0'
        ) do set \\\ip=%%a
    ) else set \\\ip=%1

    REM Get this OS version
    call lib.cmd gosinf %SystemDrive% \\\sd

    REM Get this OS Edition ID
    for /f "usebackq tokens=3" %%a in (
        `reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "EditionID"`
    ) do set \\\eid=%%a

    REM Search kms key
    REM https://technet.microsoft.com/en-us/library/jj612867(v=ws.11).aspx
    REM [EditionID]@[key] or "[[EditionID]@[key].[BuildLab_number]],[[EditionID]@[key].[BuildLab_number]], ..."
    for %%a in (
        100_ServerStandard@WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY
        100_ServerDatacenter@CB7KF-BWN84-R7R2Y-793K2-8XDDG
        "100_EnterpriseS@WNMTR-4C88C-JK8YV-HQ7T2-76DF9.10240,DCPHK-NFMTC-H88MJ-PFHPY-QJ4BJ.14393"
        100_Enterprise@NPPR9-FWDCX-D2C8J-H872K-2YT43
        100_Professional@W269N-WFGWX-YVC9B-4J6C9-T83GX

        63_ServerStandard@D2N9P-3P6X9-2R39C-7RTCD-MDVJX
        63_ServerDatacenter@W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9
        63_Professional@GCRJD-8NW9H-F2CDX-CCM8D-9D6T9
        63_Enterprise@MHF9N-XY6XB-WVXMC-BTDCT-MKKG7

        62_ServerStandard@XC9B7-NBPP2-83J2H-RHMBY-92BT4
        62_ServerDatacenter@48HP8-DN98B-MYWDG-T2DCC-8W83P
        62_Professional@NG4HW-VH26C-733KW-K6F98-J8CK4
        62_Enterprise@32JNW-9KQ84-P47T8-D8GGY-CWCK7

        61_ServerStandard@YC6KT-GKW9T-YTKYR-T4X34-R7VHC
        61_ServerEnterprise@489J6-VHDMP-X63PK-3K798-CPX3Y
        61_ServerDatacenter@74YFP-3QFB3-KQT8W-PMXWJ-7M648
        61_Enterprise@33PXH-7Y6KF-2VJC9-XBBR8-HVTHH
        61_Professional@FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4

        60_ServerStandard@TM24T-X9RMF-VWXK6-X8JC9-BFGM2
        60_ServerEnterprise@YQGMW-MPWTJ-34KDK-48M3W-X4Q6V
        60_ServerDatacenter@7M67G-PC374-GR742-YH8V4-TCBY3
        60_Enterprise@VKK3X-68KWM-X2YGT-QR4M6-4BWMV
        60_Business@YFKBB-PQJJV-G996G-VWGXY-2V3X8
    ) do for /f "usebackq tokens=1,2 delims=@" %%b in (
        '%%~a'
    ) do if /i "%\\\sd.ver%_%\\\eid%"=="%%b" set \\\key=%%c

    REM If not find key
    if not defined \\\key exit /b 4

    REM Processing same EditionID by BuildLab number
    if "%\\\key:~30,1%" neq "" for /f "usebackq tokens=3 delims=. " %%a in (
        `reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLab`
    ) do for %%b in (
        %\\\key%
    ) do if ".%%a"=="%%~xb" set \\\key=%%~nb

    REM Not found key in same EditionID
    if "%\\\key:~30,1%" neq "" exit /b 4

    REM Active
    for %%a in (
        "/ipk %\\\key%"
        "/skms %\\\ip%"
        /ato ::?"active"
        /xpr ::?"display expires time"
        /ckms ::?"rm key"
    ) do cscript.exe //nologo //e:vbscript %windir%\System32\slmgr.vbs %%~a

    endlocal
    exit /b 0

REM Office
:this\kms\--office
    call :this\iinpath lib.cmd || exit /b 2

    setlocal
    if "%~1"=="" (
        if "%~d0" neq "\\" exit /b 3
        for /f "usebackq delims=\" %%a in (
            '%~p0'
        ) do set \\\ip=%%a
    ) else set \\\ip=%1

    REM Search kms key
    set \\\key=
    call :getOfficePath \\\office || exit /b 5
    if "%\\\office:~-1%"=="\" set \\\office=%\\\office:~0,-1%
    for %%a in (
        "%\\\office%"
    ) do for %%b in (
        Office15@YC7DK-G2NP3-2QQC3-J6H88-GVGXT
        Office15Visio@C2FG9-N6J68-H8BTJ-BW3QX-RM3B3
    ) do for /f "usebackq tokens=1,2 delims=@" %%c in (
        '%%b'
    ) do if /i "%%~na"=="%%c" set \\\key=%%d

    REM If not find key
    if not defined \\\key exit /b 6

    REM Active
    for %%a in (
        "/inpkey:%\\\key%"
        "/sethst:%\\\ip%"
        /act ::?"active"
        /dstatus ::?"display expires time"
        /remhst ::?"rm key"
    ) do cscript.exe //nologo //e:vbscript "%\\\office%\ospp.vbs" %%~a
    endlocal
    exit /b 0

REM for :dis\officekms
:getOfficePath
    if "%~1"=="" exit /b 1
    for /f "usebackq delims=" %%a in (
        `reg.exe query HKLM\Software\Microsoft\Office /f InstallRoot /s`
    ) do if "%%~na"=="InstallRoot" for /f "usebackq tokens=2*" %%b in (
        `reg.exe query "%%a" /v Path 2^>nul`
    ) do if exist "%%c\ospp.vbs" (
        set %~1=%%c
        exit /b 0
    )
    exit /b 1


:::::::::::
:: other ::
:::::::::::

::: "Set power config as server type"
:::: "lib.cmd not found" "System version is too old"
:dis\spower

    call :this\iinpath lib.cmd || exit /b 1
    call lib.cmd ivergeq 6.0 || exit /b 2

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
        ::?"0: No action is taken when the system lid is opened."
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt707941(v=vs.85).aspx"
        SUB_BUTTONS\LIDACTION\0

        ::?"3: The system shuts down when the power button is pressed."
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt608287(v=vs.85).aspx"
        SUB_BUTTONS\PBUTTONACTION\3

        ::?"0: No action is taken when the sleep button is pressed."
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt608289(v=vs.85).aspx"
        SUB_BUTTONS\SBUTTONACTION\0

        ::?"0: Never idle to sleep."
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt608298(v=vs.85).aspx"
        SUB_SLEEP\STANDBYIDLE\0

        ::?"0 (Never power off the display.)"
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt608277(v=vs.85).aspx"
        SUB_VIDEO\VIDEOIDLE\0

    ) do for /f "usebackq tokens=1-3 delims=\" %%d in (
        '%%c'
    ) do powercfg.exe /set%%bvalueindex %%a %%d %%e %%f
    exit /b 0

::: "Support load %USERPROFILE%\.batchrc before cmd.exe run" "" "usage: %~n0 batchrc [[-d]]"
:::: "lib.cmd not found"
:dis\batchrc
    if /i "%~1"=="-d" >nul 2>nul (
        erase "%USERPROFILE%\.batchrc"
        reg.exe delete "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /f
        exit /b 0
    )
    call :this\iinpath lib.cmd || exit /b 2
    setlocal
    call lib.cmd gbs \\\bs
    reg.exe add "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "if not defined BS set BS=%\\\bs%&& (for /f \"usebackq delims=\" %%a in (\"%%USERPROFILE%%\.batchrc\") do @call %%a)>nul 2>&1" /f
    if exist "%USERPROFILE%\.batchrc" endlocal & exit /b 0

    > "%USERPROFILE%\.batchrc" (
        echo ;use ^>^&3 in script can print
        echo set devmgr_show_nonpresent_devices=1
        echo set path=%%path%%;%~dp0
    )
    endlocal
    exit /b 0

::: "Compresses the specified files." "" "usage: %~n0 cexe [target_path]"
:::: "Target not found" "OS is too old"
:dis\cexe
::: "Uncompress the specified files." "" "usage: %~n0 ucexe [target_path]"
:::: "Target not found" "OS is too old"
:dis\ucexe
    if not exist "%~1" exit /b 1
    call :this\iinpath lib.cmd || exit /b 1
    call lib.cmd ivergeq 10.0 || exit /b 2
    if "%0"==":dis\cexe" compact.exe /c /exe /a /i /q /s:"%~f1"
    if "%0"==":dis\ucexe" compact.exe /u /exe /a /i /q /s:"%~f1"
    exit /b 0

::: "Hardware ids manager" "" "usage: %~n0 devf [option] [args ...]" "    --get,    -g                               display hardware ids" "    --filter, -f [devinf_path] [drivers_path]  search device inf" "e.g." "    %~n0 devf -g" "    %~n0 devf -f D:\d.log D:\drv"
:::: "option invalid" "lib.cmd not found" "drivers info file not found" "drivers path error"
:dis\devf
    call :this\devf\%*
    goto :eof

:this\devf\--get
:this\devf\-g
    call :this\iinpath lib.cmd || exit /b 2
    call :this\iinpath devcon.exe || call :init\devcon >nul
    setlocal
    REM Trim Hardware and compatible ids
    for /f "usebackq tokens=1,2" %%a in (
        `devcon.exe hwids *`
    ) do if "%%b"=="" set "\\\$%%a=$"
    REM Print list
    for /f "usebackq tokens=2 delims==$" %%a in (
        `set \\\$ 2^>nul`
    ) do echo %%a
    endlocal
    exit /b 0

:this\devf\--filter
:this\devf\-f
    if not exist "%~1" exit /b 3
    call :this\iinpath lib.cmd || exit /b 2
    call lib.cmd idir %2 || exit /b 4
    REM Create inf trim vbs
    setlocal enabledelayedexpansion
    call lib.cmd gnow \\\out %temp%\inf-
    mkdir %\\\out%
    set i=0
    for /r %2 %%a in (
        *.inf
    ) do (
        set /a i+=1
        REM Cache inf file path
        set \\\drv\inf\!i!=%%a
        REM trim file in a new path
        call lib.cmd vbs inftrim "%%~a" %\\\out%\!i!.tmp
        for %%b in (%\\\out%\!i!.tmp) do if "%%~zb"=="0" type "%%~a" > %\\\out%\!i!.tmp
    )
    REM Print hit file
    for /f "usebackq" %%a in (
        `findstr.exe /e /i /m /g:%1 %\\\out%\*.tmp`
    ) do echo !\\\drv\inf\%%~na!
    REM Clear temp file
    rmdir /s /q %\\\out%
    endlocal
    exit /b 0

:::::::::::::
:: regedit ::
:::::::::::::

::: "Run this before Chang CPU"
:::: "lib.cmd not found" "OS version is too low" "Not windows directory"
:dis\intelAmd
    call :this\iinpath lib.cmd || exit /b 1
    call lib.cmd ivergeq 6.0 || exit /b 2

    if "%~1"=="" (
        setlocal
        set /p \\\i=[Warning] Reg vhd will be change, Yes^|No:
        if /i "%\\\i%" neq "y" if /i "%\\\i%" neq "yes" exit /b 0
        endlocal
        call :delInteltag system
        exit /b 0
    )

    if not exist "%~f1"\Windows\System32\config\SYSTEM exit /b 3
    reg.exe load HKLM\tmp "%~f1"\Windows\System32\config\SYSTEM
    call :delInteltag tmp
    reg.exe unload HKLM\tmp
    exit /b 0

REM for :dis\intelAmd
:delInteltag
    for /f "tokens=1,4 delims=x	 " %%a in (
		'reg.exe query HKLM\%1\Select'
	) do if /i "%%a"=="Default" reg.exe delete HKLM\%1\ControlSet00%%b\Services\intelppm /f 2>nul
    exit /b 0

::: "Copy reg to a reg file" "" "usage: %~n0 cpreg [reg_key_string] [reg_file_path]"
:::: "Reg key not exist" "Reg file not exist or Not reg format"
:dis\cpreg
    reg.exe query %1 >nul 2>nul || exit /b 1
    reg.exe load HKLM\tmp %2 || exit /b 2
    setlocal
    if not defined \\\reg\ve for /f %%a in (
        'reg.exe query HKLM /ve'
    ) do set "\\\reg\ve=%%a"

    for /f "usebackq delims=" %%a in (
        `reg.exe query %1 /s`
    ) do for /f "tokens=1,2* delims=\" %%b in (
        "%%a"
    ) do if "%%b" neq "HKEY_LOCAL_MACHINE" (
        set "\\\tmp=%%a"
        rem set "\\\tmp=!\\\tmp:$Windows.~bt\=!"
        rem set "\\\tmp=!\\\tmp:\=\\!"
        rem set "\\\tmp=!\\\tmp:"=\"!"
        for /f "tokens=1,2* delims=`" %%e in (
            "!\\\tmp:    =`!"
        ) do if "%%e"=="%\\\reg\ve%" (
            reg.exe add "HKLM\tmp\!\\\temp!" /ve /t %%f /d "%%g" /f
        ) else reg.exe add "HKLM\tmp\!\\\temp!" /v "%%e" /t %%f /d "%%g" /f
    ) else set "\\\temp=%%d"
    endlocal
    reg.exe unload HKLM\tmp
    exit /b 0

REM from Window 10 wdk, will download devcon.exe at script path
:init\devcon
    for %%a in (\\\%0) do if %processor_architecture:~-2%==64 (
        REM amd64
        call :this\getCab %%~na 8/1/6/816FE939-15C7-4185-9767-42ED05524A95/wdk 787bee96dbd26371076b37b13c405890 filbad6e2cce5ebc45a401e19c613d0a28f

    REM x86
    ) else call :this\getCab %%~na 8/1/6/816FE939-15C7-4185-9767-42ED05524A95/wdk 82c1721cd310c73968861674ffc209c9 fil5a9177f816435063f779ebbbd2c1a1d2
    exit /b 0

REM from Window 10 aik, will download imagex.exe at script path
:init\imagex
    for %%a in (\\\%0) do if %processor_architecture:~-2%==64 (
        REM amd64
        call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk d2611745022d67cf9a7703eb131ca487 fil4927034346f01b02536bd958141846b2

    REM x86
    ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk eacac0698d5fa03569c86b25f90113b5 fil6e1d5042624c9d5001511df2bfe4c40b
    exit /b 0

REM for :init\?
:this\getCab [file_name] [uri_sub] [cab] [file]
    call lib.cmd download http://download.microsoft.com/download/%~2/Installers/%~3.cab %temp%\%~1.cab
    expand.exe %temp%\%~1.cab -f:%~4 %temp%
    erase %temp%\%~1.cab
    move %temp%\%~4 %~dp0%~1.exe
    exit /b 0

