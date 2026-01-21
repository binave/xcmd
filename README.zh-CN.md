# eXternal Command

<div align="center">

**eXternal Command - 批处理和 Shell 的命令行封装工具**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.21.4.11-green.svg)](https://github.com/binave/xcmd)

常用的批处理和 Shell 方法合集。

</div>

---

## 📖 目录

- [特性](#-特性)
- [安装](#-安装)
- [使用示例](#-使用示例)
- [功能详情](#-功能详情)
- [开源协议](#-开源协议)

---

## ✨ 特性

- **xlib/xlib.cmd** - 仅使用第一方工具，开箱即用，包含数十个实用命令
- **x3rd/x3rd.cmd** - 对第三方命令行工具进行封装
    - 支持 Windows、macOS 和 Linux 平台
    - 内置错误处理和帮助系统
    - 支持 UNC 路径（Windows SMB）
    - 易于部署

- **xjar** - JAR 应用程序进程管理与运维工具，（linux 专用）
- **qrsender.sh/qrsender.cmd** - 通过`二维码`将文件从 Linux 传输到 Windows
---

## 📦 安装

### Windows 系统

1. 下载 `xlib.cmd` 和/或 `x3rd.cmd`
2. 将脚本目录添加到 PATH 环境变量
3. 确保脚本使用 `CRLF` 换行符
4. 避免在脚本中使用非 ANSI 字符

### macOS/Linux 系统

1. 下载 `xlib` 和/或 `x3rd`
2. 添加执行权限：`chmod +x xlib`
3. 将脚本目录添加到 PATH
4. 确保脚本使用 `LF` 换行符

### 快速测试

```bash
# 显示帮助
xlib -h
xlib --help

# 显示命令帮助
xlib <命令> -h
xlib <命令> --help

# 显示版本
xlib version
```

---

- 使用 `-h` 或 `--help` 获取命令使用帮助
- 在命令后使用 `-h` 或 `--help` 获取该命令的详细帮助

---

## 💡 使用示例

### 局域网唤醒（Wake on LAN）

唤醒同一网段的电脑：

```bash
# aa:bb:cc:dd:ee:ff 为目标网卡的 MAC 地址
xlib wol aa:bb:cc:dd:ee:ff
```

### 支持 cmd.exe 环境变量配置文件（Windows）

在运行 `cmd.exe` 之前加载文件 `%USERPROFILE%\.batchrc`。<br/>
类似于 Linux/Mac 中的 `~/.bashrc`

```batch
xlib var --install-config
:: or
xlib var -ic
```

### BitLocker 加密（Windows）

在不支持 TPM 的计算机上快速加密所有磁盘：

```batch
:: 准备一个 FAT32 格式的 USB 设备，用于存放开机密钥
xlib vol --encrypts-all

:: 从 UNC 路径（SMB 服务器）执行
\\192.168.1.1\xcmd\xlib vol --encrypts-all

:: 隐藏加密标识和 BitLocker 菜单
xlib vol --hide-bitlocker

:: 查看更多详情
xlib vol --help
```

### 截获 AppStore PKG 安装包（macOS）

截获 AppStore 原版 PKG 安装包：

```bash
xlib pkg -g 5
```

然后打开 AppStore 下载应用。PKG 文件将出现在下载文件夹中。

### 网络主机发现

批量搜索同一网络中 IP 不固定的计算机，并用固定名称访问：

1. 在 `%USERPROFILE%` 或 `$HOME` 下创建 `.host.ini` 文件：

```ini
[hosts]
; 单个 MAC 地址，匹配不到会忽略
gl.inet=00:11:00:00:00:00

; 从左开始匹配，都匹配不到会设置为最后的 |127.0.0.1
syno-15=00-11-00-00-11-00|11:00:00:00:00:11|00-11-00-00-00-11|127.0.0.1

; 直接设置为固定的 IPv4
binave.com=127.0.0.1

[sip_setting]
; 搜寻的 IPv4 范围
range=1-120
```

2. 执行命令（需要管理员权限）：

```bash
xlib hosts
```

### Microsoft Office 部署（Windows）

自动化安装 Microsoft Office

```batch
:: 帮助信息
xlib odt -h

:: 先下载最新的 Office 安装文件
xlib odt -d D:\ 2021
xlib odt -d \\192.168.1.1\xcmd 2024

:: 自动安装指定组件
\\192.168.1.1\xcmd\xlib odt -i word excel powerpoint 2024
```

### KMS 激活（Windows）

使用 KMS 服务自动激活 Windows 和 Office：

```batch
:: 使用 KMS 服务激活 Windows
xlib kms -s 192.168.1.1

:: 使用 KMS 服务激活 Office
xlib kms -o 192.168.1.1

:: 使用 KMS 服务激活 Windows 和 Office
\\192.168.1.1\xcmd\xlib kms -a
```

### 剪贴板文件传输（Windows）

通过远程桌面剪贴板传输小文件或文件夹（适用于旧版本 Windows）：

1. 在本地和远程机器上下载 `clipTransfer.vbs`
2. 在一端将文件/文件夹拖放到 VBS 脚本上
3. 等待完成
4. 在另一端双击 VBS 脚本即可接收

---

## 🔧 功能详情

### xlib.cmd (Windows)

- 支持在 `for /f` 命令中使用（进行判断操作时需要使用 `call` 命令）
- 函数名自动补全（从左到右逐字符匹配）
- 简单的多进程控制支持（如 `hosts` 函数）
- 虚拟磁盘控制、WIM 文件操作、字符串操作、哈希计算
- 通过 `xlib vbs` 命令调用 VBS 脚本进行下载和转码等操作

### xlib / bash.xlib (macOS/Linux)

- Shell 实现的复杂数据结构（字典、队列等）
- 区分 macOS 和 Linux 版本的函数

### xjar (Linux)

- 进程管理：start/stop/restart JAR 应用
- 日志管理：查看、重定向、自动轮转、清理日志
- 状态监控：显示进程信息、CPU/内存占用、网络连接、线程详情
- 批量操作：支持多目录批量管理
- 调试支持：支持 JDWP 远程调试

### qrsender (Linux -> Windows)

- 特性：在无法使用 USB、网络或蓝牙的隔离环境中传输文件
- 原理：发送端在终端上以动画形式逐个显示 QR 码序列（带进度编号），接收端自动扫描 QR 码序列后还原原始文件，并计算丢包。发送端根据编号进行重传。

---

## 📄 开源协议

本项目采用 Apache License 2.0 开源协议。详见 [LICENSE](LICENSE) 文件。

