# External Command
command-line wrapper for batch and shell.

一些常用的 batch 和 shell 方法合集。

---------
# Licensing
extcmd is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/binave/extcmd/blob/master/LICENSE) for the full
license text.

---------


> 将脚本文件放入环境变量后，通过 `-h` 或者 `--help` 参数获得使用帮助。
> <br/>`shell` 脚本需要注意赋予可执行权限，注意行尾序列使用 `LF`，否则脚本会无法执行。
> <br/>`windows` 脚本支持从 `UNC` 路径启动，方便作为服务来使用，注意行尾序列使用 `CRLF`，否则脚本会无法执行，同时避免在脚本中使用非 `ANSI` 字符。

---------
### Q: 如何在不支持 `TPM` 的计算机上，快速使用 `windows` 系统的 `BitLocker` 加密所有磁盘。
A:

1. 准备一个 `FAT32` 格式的 `USB` 存储设备，连接到计算机，用于存放开机密钥。
2. 下载 `lib.cmd` 到本地计算机，执行

    ```bat
    lib vol --encrypts-all
    ```

    2.1. 或者从 `smb` 服务器（如 `192.168.1.1`）的 `UNC` 路径执行

    ```bat
    \\192.168.1.1\extcmd\lib vol --encrypts-all
    ```

3. 更详细的操作方法（包括禁止非加密磁盘写入，隐藏加密特征，指定 `USB` 存储设备盘符等），可以使用

    ```bat
    lib vol --help
    ```

    进行查询。

---------

### Q: 如何在 `macOS` 系统上截获 `AppStore` 原版 `pkg` 安装包。
A:

1. 下载 `lib` 到本地计算机执行

    ```sh
    lib pkg -g 5
    ```

2. 打开 `AppStore` 下载（而不是更新）任意若干个应用。
3. 在 `Download` 文件夹中等待应用 `pkg` 包的出现。

---------

### Q: 如何批量搜索`同一网络`中的 `IP` 不固定的计算机，并用固定的名称访问。而不是登录每个电脑去看 `IP` 地址。
A:

1. 收集需要搜寻电脑网卡的 `MAC` 地址。
2. 在用户目录 `%USERPROFILE%` 或 `$HOME` 下建立 `.host.ini` 空文件，并按照下列方式进行编辑

    ```ini
    [hosts]
    ; 单个 mac 地址，匹配不到会忽略。
    gl.inet=00:11:00:00:00:00

    ; 从左开始匹配，都匹配不到会设置为最后的 |127.0.0.1
    syno-15=00-11-00-00-11-00|11:00:00:00:00:11|00-11-00-00-00-11|127.0.0.1 ;nat hosts

    ; 直接设置为固定的 IPv4
    binave.com=127.0.0.1

    [sip_setting]
    ; 搜寻的 IPv4 范围
    range=1-120
    ```

3. 在 `windows` 系统下下载 `lib.cmd` 或在 `macOS` 系统下下载 `lib` 执行

    ```
    lib hosts
    ```

    等待打印搜寻结果，结果会写入 `hosts` 文件中，所以需要管理员权限执行命令。

---------

### Q: 如何搭建一个最新版 `Microsoft Office` 可定制安装服务。
A:

1. 搭建一个 `smb` 服务（比如 `192.168.1.1`），并建立目录 `extcmd\`
2. 使用

    ```bat
    lib odt -d \\192.168.1.1\extcmd
    ```

    下载最新的 `Microsoft Office` 安装文件。
3. 下载 `lib.cmd` 放入 `\\192.168.1.1\extcmd`
4. 服务搭建完成，在目标计算机上执行

    ```bat
    \\192.168.1.1\extcmd\lib odt -i word excel powerpoint
    ```
    安装 `word` `excel` `powerpoint`，其余 `office` 组件将被忽略。

---------
### Q: 我有 `kms` 服务部署在 `192.168.1.1` 上，如何快速激活 `windows` 和 `office`。
A:

1. 下载 `lib.cmd` 并执行

    ```bat
    lib kms -s 192.168.1.1
    ```

    激活  `windows`。
    <br/>执行

    ```bat
    lib kms -o 192.168.1.1
    ```

    激活 `office`

---------

### Q: 如何在旧版本的 `windows` 之间，通过远程桌面的剪贴板，传输小文件或文件夹。
A:

1. 在本地和远端下载 `clipTransfer.vbs`，或将源码复制到任意 `vbs` 中。
2. 在任意一端，把文件或文件夹拖动到 `vbs` 脚本上。
3. 等待提示完成。
4. 在另一端双击 `vbs` 脚本即可。
5. 视网好坏将等待不同的时间。

---------
### Q: 如何将多个 `batch` （批处理）函数，或者 `shell` 函数放入一个脚本中，通过方法名快速调用，并支持错误输出。
A:

1. mac 和 linux 下新建 sh 文件，并写入以下内容（注意赋予可执行权限）。

    ```sh
    #!/bin/bash

    #################################################
    #               Custom Functions                #
    # # # # # # # # # # # # # # # # # # # # # # #


    ### somefunc ##Usage: somefunc info # need modify
    _pre_somefunc () {
        : # function body
        exit 1 # error info, need modify
    }

    # # # # # # # # # # # # # # # # # # # # # # #
    #               Custom Functions                #
    #################################################

    # Print Error info
    _func_err () {
        [[ "$4$6" == exit_${0##*/}* ]] && {
            local err=`sed -n $2p "$0"` # local err=`awk 'NR=='$2'{print}' "$0"`;
            printf "\033[31mError:${err##*#} \033[33m($0:$2)\033[0m\n" >&2; # Print line text after '#'
            exit $(($5 % 256))
        };

        [ "$4" == "return" ] && exit $(($5 % 256)); # WARRAN: 0 <= $? <= 255, return 256: $? = 0
        [ $1 == 127 ] && { # Get script line
            printf "\033[31mError: No function found \033[0m\n" >&2; # No function found
            exit 1
        };
        exit 0
    }

    _func_annotation () { # Show function info
        local i j k OLDIFS IFS=$IFS\({;
        OLDIFS=$IFS; # Cache IFS
        [ "$1" ] && { # show select
            while read i j; do
                [ "$i" == "###" ] && { # Make array splite with
                    IFS=#;
                    k=($j);
                    IFS=$OLDIFS
                };
                [ "$k" -a "$i" == "_${0##*/}_$1" ] && { # At target func name
                    for i in ${!k[@]}; do
                        printf "${k[$i]}\n"; # Print all annotation
                    done;
                    return 0
                };
                [[ "$i" == _${0##*/}* ]] && [ "$j" == ")" ] && unset k; # Reset var
            done < "$0"; # Scan this script
            return 1
        } || {
            while read i j; do # show all
                [ "$i" == "###" ] && k=${j%%#*}; # Cache intro
                [ "${i%_*}" == "_${0##*/}" -a "$j" == ")" ] && { # At func name
                    printf "%-15s$k\n" ${i##*_}; # Left aligned at 15 char
                    unset k # Clear var
                };
            done < "$0"; # Scan this script
        }
    }
    # Cache exit
    trap '_func_err $? $LINENO $BASH_LINENO $BASH_COMMAND ${FUNCNAME[@]}' EXIT

    [[ ! "$1" || "$1" == "-h" || "$1" == "--help" ]] && { # Test if help
        _func_annotation | sort;
        exit 0
    } || [[ "$2" == "-h" || "$2" == "--help" ]] && {

        _func_annotation $1 || printf "\033[31mError: No function found \033[0m\n" >&2; # Test if help
        exit $?
    };

    _pre_"$@" # main $*, "$*", $@ can not keep $#, only "$@" can save native structural

    ```

2. windows 下新建 cmd 文件，写入以下内容

    ```bat
    @echo off

    REM init errorlevel
    set errorlevel=

    REM Init PATH
    for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

    if "%~2"=="-h" call :this\annotation :pre\%~1 & exit /b 0
    if "%~2"=="--help" call :this\annotation :pre\%~1 & exit /b 0

    2>nul call :pre\%*

    REM Test type function
    if errorlevel 30 exit /b 1
    if errorlevel 1 call :this\annotation :pre\%* & goto :eof
    exit /b 0

    :::::::::::::::::::::::::::::::::::::::::::::::
    ::             Custom Functions              ::
    :: :: :: :: :: :: :: :: :: :: :: :: :: ::

    ::: "Update hosts by ini"
    :::: "no ini file found"
    :pre\somefunc
        REM function body
        exit /b 1
        goto :eof

    :: :: :: :: :: :: :: :: :: :: :: :: :: ::
    ::             Custom Functions              ::
    :::::::::::::::::::::::::::::::::::::::::::::::

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

            if /i "%%~a"==":pre" (
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
        call :pre\cols _col
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
        ) else if %_i%==1 call :pre\%_target% || call %0 :pre\%_target%
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

    ::: "Get cmd cols" "" "usage: pre cols [[var_name]]"
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

    ```

--------

### 关于 `lib.cmd` 的补充说明

    1.  Support for /f command.
        支持在 for /f 中使用，进行判断操作时需要使用 call 命令。

    2.  Support sort function name.
        函数支持简名，会从左逐个字符进行命令匹配，直到匹配唯一的命令。
            如 call lib addpath ， a 是全局唯一，可用 call lib a 来代替。
            注意：简化命令会增加执行时间，请在其他脚本中调用时使用全名。

    3.  支持简单的多进程控制。（`hosts` 函数）

    4.  包含“虚拟磁盘控制”，“`wim` 文件控制”，“字符喘操作”，“`hash` 计算”等功能

--------

### 关于 `lib` 、 `_lib` 的说明

    1.  包含 shell 实现的复杂数据结构。如“字典”、“队列”等

    2.  区分部分函数 macOS 和 linux 版本。

--------

### 关于 `3rd` 、 `3rd.cmd` 的说明

    1.  对一些常用的命令行工具，进行了二次命令封装。
