# External Command
command-line wrapper for batch and shell

---------
# Licensing
extcmd is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/binave/extcmd/blob/master/LICENSE) for the full
license text.

---------
# New!
clipTransfer.vbs

        Copy file or folder between two Windows OS by clipboard
        通过剪贴板，在两个 windows 之间复制小文件。将目标文件或文件夹拖动到脚本上，提示完成后，在远程桌面上双击远端的脚本即可。


lib gpkg

        Get apk file from AppStore
        截获 AppStore 的原版安装包。完成后会放到 Download 文件夹中。
        (详细信息看 lib shell script 描述)

lib sip

        Search IPv4 by MAC or Host name
        通过 MAC 地址或别名搜索 IP 。（仅搜索本网段最后 255 个）
        （别名请参考 ini 文本文件格式，放入脚本所在路径或 HOME 路径下）

lib hosts

        (win mac)
        Update hosts by ini
        通过 ini 配置文件，自动更新 hosts。

lib _map _set

        map for shell
        基于 hash 算法实现的 map 。
        与基于 map 实现的 set。
        用于 shell 脚本内部调用，可以简化逻辑设计。

--------
Framework:
框架：

    If the function names conform to the specifications:
        External call function. (cmd will support short name completion)
        Error handling.
        Display help information.
        Print the functions list.

    对符合规范的函数提供：（包括 sh、cmd、vbs）
        外部调用 (cmd 格式的脚本支持通过短名称访问，类似自动补齐)。
        错误处理。
        输出帮助信息。
        输出函数列表。
        (lib 3rd 名称的脚本均支持以上特性。)

    e.g.
        ::: "[brief_introduction]" "" "[description_1]" "[description_2]" ...
        :::: "[error_description_1]" "[error_description_2]" ...
        :[script_name_without_suffix]\[function_name]
            ...
            [function_body]
            ...
            REM exit and display [error_description_1]
            exit /b 1
            ...
            REM return false status
            exit /b 10


--------

lib.cmd

        1.  Some cmd function.
            一些批处理函数，放到环境变量中即可直接使用。

        2.  Support for /f command.
            支持在 for /f 中使用，进行判断操作时需要使用 call 命令。

        3.  Support sort function name.
            函数支持简名，会从左逐个字符进行命令匹配，直到匹配唯一的命令。
                如 call lib addpath ， a 是全局唯一，可用 call lib a 来代替。
                注意：简化命令会增加执行时间，请在其他脚本中调用时使用全名。

        4.  HELP: lib -h or lib [func] -h
            有关函数用法，使用 lib.cmd -h 或 lib.cmd ［函数名］-h。

        2la             Make the second column left-aligned
                        将第二列左对齐。

        cab             Create cab package
                        压缩 cab 包。

        centiTime       Calculating time intervals, print use time
                        输出执行时间。在从第二次开始输出距离上次执行的时间。

        dobg            Run some command at background
                        隐藏执行命令。

        download        Download something
                        下载文件。

        execline        Output text or read config
                        逐行执行，可以用于输出局部文本或设置变量等。

        firewall        Open ssh/smb/docker port
                        打开一些端口。

        gbase64pw       Encode password to base64 string for unattend.xml
                        支持 unattend.xml 使用的密码编码。

        gbs             Get some backspace (erases previous character)
                        获得退格符。

        gcols           Get cmd cols
                        获得当前 cmd 窗口的宽度。

        gfirstpath      Get first path foreach Partiton
                        遍历分区查找文件夹，并返回第一个匹配的。

        gfreeletter     Get Unused Device Id
                        获得一个未被使用的分区盘符。

        glen            Get string length
                        获得字符串的长度。

        gletters        Get Device IDs
                        获得所有分盘符。

        gnow            Display Time at [YYYYMMDDhhmmss]
                        以 [YYYYMMDDhhmmss] 的格式输出时间。

        gosinf          Get OS language bit and version
                        获得目标分区的操作系统版本、位数、语言信息。

        grettels        Get Device IDs DESC
                        获得倒序的盘符。

        gsid            Get sid by username
                        获得用户的 sid。

        guuid           Get UUID
                        获得 UUID。

        head            Print the first some lines of FILE to standard output.
                        输出文件前几行。

        hosts           Update hosts by ini
                        通过 ini 配置文件，自动更新 hosts。

        idir            Test path is directory
                        测试路径是否是目录。

        ifreedir        Test directory is empty
                        测试目标是否为空文件夹。

        igui            Test script start at GUI
                        测试脚本是否是双击启动。

        iip             Test string if ip
                        测试字符串是否是 ip。

        iln             Test path is Symbolic Link
                        测试路径是否是软链接。

        inum            Test string if Num
                        测试字符是否是 10 进制整数。

        ipipe           Test script run after pipe
                        测试脚本是否在管道命令之后。

        irun            Test exe if live
                        测试 exe 是否执行中。

        ivergeq         Test this system version
                        测试此系统版本是否高于给定版本号。

        kill            Kill process
                        关闭进程。

        lip             Show Ipv4
                        显示本机 IP。

        MD5             Print or check MD5 (128-bit) checksums.
                        计算文件 MD5。

        own             Change file/directory owner Administrator
                        将文件或目录的所有者变为当前用户。

        ps1             Run PowerShell script
                        执行 PowerShell script 脚本。

        repath          Reset default path environment variable
                        临时重置 PATH 变量为系统默认值。

        rpad            Right pads spaces
                        等宽输出字符串。用于批量显示结果。

        search          Search file in $env:path
                        用于寻找环境变量中的可执行文件，支持通配符。如果只匹配到一个结果，将显示其完整路径。

        senvar          Set environment variable
                        设置环境变量。

        serrlv          Set errorlevel variable
                        设置 errorlevel 的值。

        SHA1            Print or check SHA1 (160-bit) checksums.
                        计算文件 SHA1。

        SHA256          Print or check SHA256 (256-bit) checksums.
                        计算文件 SHA256。

        sip             Search IPv4 by MAC or Host name
                        通过 MAC 地址或别名，搜索设备 IP。
                        （别名请参考 ini 文本文件格式，放入脚本所在路径或 HOME 路径下）

        skiprint        Print text skip some line
                        跳过指定行输出文件的文本内容到另一个空文本中。

        tail            Print the last some lines of FILE to standard output.
                        输出文件后几行。

        trimdir         Delete empty directory
                        删除所有空文件夹。

        trimpath        Path Standardize
                        PATH 变量临时规范化，可以用于 dir 命令搜索。

        uchm            Uncompress chm file
                        解压 chm 文件。

        udf             Create iso file from directory
                        从文件夹新建 iso 文件。支持可启动操作系统盘的封装。

        umsi            Uncompress msi file
                        解压 msi 文件。

        uset            Unset variable, where variable name left contains
                        批量清空变量，从左匹配变量名。

        vbs             Run VBScript library from lib.vbs
                        执行 lib.vbs 中的函数。

        which           Locate a program file in the user's path
                        通过文件名获得其在 PATH 中的路径，可以显示重名文件。

        zip             Zip or unzip
                        压缩解压缩 zip

dis.cmd

        集中了一些对磁盘和 wim 的操作。

        batchrc         Support load %USERPROFILE%\.batchrc before cmd.exe run
                        使 cmd.exe 支持读取 %USERPROFILE%\.batchrc 中的变量配置。

        block           Lock / Unlock partition with BitLocker
                        使用 BitLocker 进行分区加密解密。

        bootfile        Copy Window PE boot file from CDROM
                        从 CDROM 中复制 winpe 基本启动文件。

        cexe            Compresses the specified files.
                        文件压缩（仅支持 win 10）

        cleanup         Component Cleanup

        cpreg           Copy reg to a reg file
                        reg 文件导出，用于批量修改注册表。

        crede           Add or Remove Web Credential
                        主要用于管理访问网络资源的凭证。

        devf            Hardware ids manager
                        硬件 ID 管理。用于生成硬件列表和查找匹配驱动。

        drv             Drivers manager
                        添加或删除驱动。

        intelAmd        Run this before Chang CPU
                        从 Intel 切换到 Amd 执行的命令。（避免蓝屏）

        kms             KMS Client
                        KMS 简化客户端

        nfs             Mount / Umount NFS
                        挂载或卸载 NFS。

        oc              Feature manager
                        开启或关闭 windows 应用。

        smb             Mount / Umount samba
                        挂载或卸载 samba。

        spower          Set power config as server type
                        使用服务器的电源模式。（不休眠，关闭盖子不进行任何操作）

        ucexe           Uncompress the specified files.

        vhd             Virtual Hard Disk manager
                        虚拟磁盘管理。

        wim             Wim manager
                        Wim 文件管理。



lib.vbs

        使用 lib.cmd vbs 命令进行调用。

        ansi2unic       Convert ansi head to unicode head, or reconvert
                        在 ANSI 文件前面加（减） UNICODE 头。

        bin2base64      Convert binary file to base64 string
                        将二进制文件转换成 base64 编码字符。

        doxsl           XML trans form Node by XSL
                        执行 xsl。

        gclip           Get clipboard data
                        获得剪贴板中的内容。

        get             Download and save
                        下载。

        getprint        Download and print as text
                        显示下载文件的文本内容。

        gfsd            Get target file system drive Letter
                        获得目标文件系统的盘符。

        gnow            Get format time
                        获得特定格式的当前时间。

        guuid           Get guid
                        获得 GUID。

        inftrim         Trim *.inf text for drivers
                        处理驱动用 inf 文件。

        print

        sclip           Set clipboard data
                        设置剪贴板。

        sleep           Sleep some milliseconds
                        暂停若干毫秒。

        txt2bin         Convert base64 to binary file from text
                        将 base64 字符转换为二进制文件。

        unattend

        unzip           Uncompress
                        解压缩 zip。

        zip             Create zip file
                        压缩 zip。


lib     (shell script)

        注意权限是否为可执行。

        aapp            Allow all app install
                        允许 mac 安装任意应用。

        cd2i            Convert a DMG file to ISO
                        将 DMG 文件转换为 ISO 格式。

        ci2d            Convert an ISO file to DMG format
                        将 ISO 文件转换为 DMG 格式。

        cim             Create instatll device, by OS X DMG
                        制作 OS X 系统安装盘。

        dhms            Format Unix timestamp to ??d ??h ??m ??s
                        格式化数字。

        garri           Get array index
                        通过值获得数组索引。

        gmd5pw          Get password for stdin chpasswd -e
                        获得 chpasswd 命令支持密码编码。

        gpkg            Get apk file from AppStore
                        截获 AppStore 的原版安装包。完成后会放到 Download 文件夹中。
                        对于小文件下载非常有效。
                        支持批量监听。
                        可以设置监听时间，默认监听 60 秒。
                        在监听时间内，新建下载和正在下载的 app 都会被纳入监控。
                        当监听结束后，脚本不会退出，会持续跟踪文件的下载状态，直到所有 app 都下载完成。
                        你可以随时使用 control + C 退出此命令。新启动的 gpkg 命令会处理上次遗留的 app。
                        （未来会加入下载失败的提示）

        hid             Hidden file/directory
                        显示或隐藏文件。

        hosts           Update hosts by ini
                        通过 ini 配置文件，自动更新 hosts。

        iipv4           Test string is ipv4
                        测试字符串是否是 ipv4

        inum            Test str is num
                        测试字符串是否是数字。

        lip             Show IPv4
                        显示本机的 ip。

        log             Tag date time each line
                        给输出添加日志标记。

        low             Convert lowercase
                        将字符转换成小写。

        nohid           No hidden directory

        own             Make owner
                        重置文件夹所有者。

        plist           Plist editer
                        操作

        pubrsa          Copy rsa public key to remote
                        将本地的公钥上传至远端。

        rboot           Rebuild boot file
                        重新建立启动文件。

        scpp            Auto scp with password

        sdd             Write img to disk
                        将镜像写入磁盘。

        sip             Search IPv4 by MAC or Host name
                        通过 MAC 地址或别名，搜索设备 IP。
                        （别名请参考 ini 文本文件格式，放入脚本所在路径或 HOME 路径下）

        tailto          save tail n line
                        保留文件的最后 n 行。

        trspace         Replace all space to one space
                        将多个空格替换成一个。

        trxml           Get xml without annotations
                        去掉 xml 中的注释。

        udf             Create ISO by directory
                        从文件夹新建 iso 文件。

        unascii         Print text not in ASCII char
                        输出非 ASCII 字符。

        upp             Convert uppercase
                        将字符转换为大写。

        vnc             Connect vnc server
                        链接 vnc 服务端。
