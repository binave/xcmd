# eXternal Command

<div align="center">

**eXternal Command - command-line wrapper for batch and shell**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.21.4.11-green.svg)](https://github.com/binave/xcmd)

A collection of commonly used batch and shell functions.

[简体中文](README.zh-CN.md)

</div>

---

## 📖 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Examples](#-examples)
- [Features Detail](#-features-detail)
- [License](#-license)

---

## ✨ Features

- **xlib/xlib.cmd** - Uses only first-party tools, works out of the box with dozens of practical commands
- **x3rd/x3rd.cmd** - Wraps third-party command-line tools
    - Support for Windows, macOS, and Linux
    - Built-in error handling and help system
    - Support for UNC paths (Windows SMB)
    - Easy to deploy

- **xjar** - JAR application process manager and operations tool, (for linux only)
- **qrsender.sh/qrsender.cmd** - Transfer files from Linux to Windows via `QR code`
---

## 📦 Installation

### For Windows

1. Download `xlib.cmd` and/or `x3rd.cmd`
2. Add the script directory to your PATH environment variable
3. Ensure the script uses `CRLF` line endings
4. Avoid using non-ANSI characters in the script

### For macOS/Linux

1. Download `xlib` and/or `x3rd`
2. Add execute permission: `chmod +x xlib`
3. Add the script directory to your PATH
4. Ensure the script uses `LF` line endings

### Quick Test

```bash
# Show help
xlib -h
xlib --help

# Show command help
xlib <command> -h
xlib <command> --help

# Show version
xlib version
```

---

- Use `-h` or `--help` to get usage help for any command
- Use `-h` or `--help` after a command to get detailed help for that specific command

---

## 💡 Examples

### Wake on LAN

Wake up a computer on the same network:

```bash
# aa:bb:cc:dd:ee:ff is the target NIC MAC address
xlib wol aa:bb:cc:dd:ee:ff
```

### Support for cmd.exe environment variable configuration files (Windows)

Load the file `%USERPROFILE%\.batchrc` before running `cmd.exe`<br/>
Similar to Linux/Mac's `~/.bashrc`

```batch
xlib var --install-config
:: or
xlib var -ic
```

### BitLocker Encryption (Windows)

Encrypt all disks on a computer without TPM support:

```batch
:: Prepare a FAT32 USB device for storing startup keys
xlib vol --encrypts-all

:: Run from UNC path (SMB server)
\\192.168.1.1\xcmd\xlib vol --encrypts-all

:: Hide encryption indicators and BitLocker menu
xlib vol --hide-bitlocker

:: For more details
xlib vol --help
```

### Capture AppStore PKG Files (macOS)

Capture original PKG installation packages from AppStore:

```bash
xlib pkg -g 5
```

Then open AppStore and download apps. PKG files will appear in the Downloads folder.

### Network Host Discovery

Search and access computers with dynamic IPs using fixed names:

1. Create `.host.ini` in `%USERPROFILE%` or `$HOME`:

```ini
[hosts]
; Single MAC address, ignored if not matched
gl.inet=00:11:00:00:00:00

; Match from left, fallback to 127.0.0.1 if no match
syno-15=00-11-00-00-11-00|11:00:00:00:00:11|00-11-00-00-00-11|127.0.0.1

; Direct IPv4 address
binave.com=127.0.0.1

[sip_setting]
; IPv4 search range
range=1-120
```

2. Run the command (requires admin privileges):

```bash
xlib hosts
```

### Microsoft Office Deployment (Windows)

Automated Microsoft Office Installation

```batch
:: help info
xlib odt -h

:: Download the latest Office installation files first
xlib odt -d \\192.168.1.1\xcmd 2024
xlib odt -d D:\ 2021

:: Automatically install specified components
\\192.168.1.1\xcmd\xlib odt -i word excel powerpoint 2024
```

### KMS Activation (Windows)

Automatically activate Windows and Office using KMS service:

```batch
:: Using KMS service activate Windows
xlib kms -s 192.168.1.1

:: Using KMS service activate Office
xlib kms -o 192.168.1.1

:: Using KMS service activate Windows and Office
\\192.168.1.1\xcmd\xlib kms -a
```

### Clipboard File Transfer (Windows)

Transfer small files/folders via RDP clipboard (for older Windows versions):

1. Download `clipTransfer.vbs` on both local and remote machines
2. Drag files/folders onto the VBS script on one end
3. Wait for completion
4. Double-click the VBS script on the other end to receive

---

## 🔧 Features Detail

### xlib.cmd (Windows)

- Supports use in `for /f` commands (use `call` for conditional operations)
- Function name auto-completion (matches characters from left to right)
- Multi-process control support (e.g., `hosts` function)
- Virtual disk control, WIM file manipulation, string operations, hash calculation
- VBS script integration via `xlib vbs` command for downloads and transcoding

### xlib / bash.xlib (macOS/Linux)

- Shell implementation of complex data structures (dictionaries, queues, etc.)
- Platform-specific functions for macOS and Linux

### xjar (Linux)

- Process Management: Start/Stop/Restart JAR applications
- Log Management: View, redirect, auto-rotate, and clean logs
- Status Monitoring: Display process information, CPU/memory usage, network connections, and thread details
- Batch Operations: Supports multi-directory batch management
- Debugging Support: Supports JDWP remote debugging

### qrsender (Linux -> Windows)

- Features: Transfer files in isolated environments where USB, network, or Bluetooth cannot be used.
- Principle: The sender displays the QR code sequence sequentially as an animation on the terminal (with progress numbers). The receiver automatically scans the QR code sequence to reconstruct the original file and calculates packet loss. The sender retransmits based on the sequence numbers.

---

## 📄 License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for the full license text.

