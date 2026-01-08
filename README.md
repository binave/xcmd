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
- [Usage](#-usage)
- [Examples](#-examples)
- [Features Detail](#-features-detail)
- [License](#-license)

---

## ✨ Features

- **xlib/xlib.cmd** - Uses only first-party tools, works out of the box with dozens of practical commands
- **x3rd/x3rd.cmd** - Wraps third-party command-line tools
- Cross-platform support for Windows, macOS, and Linux
- Built-in error handling and help system
- Support for UNC paths (Windows SMB)
- Minimal dependencies and easy to deploy

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

# Show version
xlib version
```

---

## 🚀 Usage

### Basic Syntax

```bash
# Windows
xlib.cmd <command> [options]

# macOS/Linux
xlib <command> [options]
```

### Available Help

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

### BitLocker Encryption

Encrypt all disks on a computer without TPM support:

```batch
# Prepare a FAT32 USB device for storing startup keys
xlib vol --encrypts-all

# Run from UNC path (SMB server)
\\192.168.1.1\xcmd\xlib vol --encrypts-all

# Hide encryption indicators and BitLocker menu
xlib vol --hide-bitlocker

# For more details
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

### Microsoft Office Deployment

Set up a customizable Microsoft Office installation service:

```batch
# Download latest Office installation files
xlib odt -d \\192.168.1.1\xcmd

# Install specific components
\\192.168.1.1\xcmd\xlib odt -i word excel powerpoint
```

### KMS Activation

Activate Windows and Office using KMS service:

```batch
# Activate Windows
xlib kms -s 192.168.1.1

# Activate Office
xlib kms -o 192.168.1.1
```

### Clipboard File Transfer

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

---

## 📄 License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for the full license text.

