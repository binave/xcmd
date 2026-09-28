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
3. Add the script directory to your PATH:
   - bash/zsh: `export PATH="$PATH:/path/to/xcmd"`
   - fish: `fish_add_path /path/to/xcmd` (do **not** use the bash `A=$A:...` form in fish, it replaces PATH)
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

### Shell Completion (macOS/Linux)

Completion for all commands, options and argument values is auto-generated from the script annotations:

```bash
# Generate and install for the current shell (bash/zsh/fish), print the file
xlib comp -i

# Or print to stdout for a custom setup
xlib comp --bash
xlib comp --zsh
xlib comp --fish

# Check the annotation, print warnings
xlib comp --check
```

`xlib comp -i` auto-detects the running shell: for bash/zsh it writes the completion file and appends the `source` line to `~/.bashrc` or `~/.zshrc` when it is missing (for zsh the line must come after `compinit`); for fish it writes `~/.config/fish/completions/xlib.fish`, which fish loads on demand without an rc line. Restart the shell afterwards. Re-run `xlib comp -i` after the script is edited. Argument values are completed too: `wol <TAB>` completes `[hosts]` aliases and the IPs that exist only in `/etc/hosts`, `wol -b <TAB>` completes aliases and local IPv4, and `ip -f <TAB>` completes MAC addresses and aliases. If completion falls back to the current directory, the completion file is not loaded by your rc.

Help and completion share one annotation next to the code: a `###` block above the command, and an indented `###` line above each `case` branch, using GNU style (`-o, --option=FILE`, `NAME=TYPE`). The metavariable names the completion source; `xlib` supports `FILE IMAGE DIRECTORY DEVICE PATH HOST ADDRESS MAC ALIAS HOSTIP SHELL KIND` (`HOSTIP` is an IP in `/etc/hosts` that is not in the `[hosts]` ini), and `{a|b}` is an enumeration. `###` is reserved for annotation — any other comment must use `#`, otherwise `xlib comp --check` will report it. The generic engine lives in `comp.xlib` and is shared by `xlib` and `x3rd`; a host declares its own vocabulary and candidates with `__COMP_KINDS`, `__comp_kind_host` and `__comp_value_host`, so `x3rd` completes only the generic kinds. Use `x3rd comp -i` for the `x3rd` completion.

### Clink Completion (Windows)

Clink completion for both `xlib.cmd` and `x3rd.cmd` is generated and installed by `x3rd comp`:

```batch
:: Generate and install the completion for xlib.cmd and x3rd.cmd
x3rd comp -i

:: Check the annotation, print warnings
x3rd comp --check
```

It completes commands, options and argument values, auto-generated from the same `:::` annotations that already provide `--help`; the GNU-style metavariable names the completion source (`FILE IMAGE PATH DIRECTORY DIR DEVICE ADDRESS IP IPV4 MAC HOST ALIAS HOSTIP SHELL KIND`), and `{a|b}` is an enumeration. The generator is a Lua program, so it lives in `x3rd.cmd` — `xlib.cmd` stays first-party tools only. It is embedded at the end of `x3rd.cmd` as a tagged subdocument, following the same `::tag:` config-embedding scheme that `xlib.cmd` already uses for its `.inf`/`.xml`/`.ini` subdocuments, and it runs on the Lua engine that Clink itself embeds (`clink lua`), so no separate Lua interpreter needs to be installed. Requires Windows and [Clink](https://github.com/chrisant996/clink).

A command or an option that exists on one platform only is marked with a short tag at the end of its annotation line — `### Volume info or edit [macOS]`, or `###   -u, --unique[=DIRECTORY]   search for duplicate files in DIRECTORY [Linux]`. The no-argument list and `-h` show the tag at the end of the brief, while `comp -i` / `comp --bash` / `comp --zsh` / `comp --fish` skip every entry that does not match the running platform. `xlib comp --list PLATFORM` prints the parsed metadata for `macos`, `linux` or `all`.

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
- Clink completion for `xlib.cmd` and `x3rd.cmd` commands, options and argument values (`x3rd comp -i`)
- Multi-process control support (e.g., `hosts` function)
- Virtual disk control, WIM file manipulation, string operations, hash calculation
- VBS script integration via `xlib vbs` command for downloads and transcoding

### xlib / bash.xlib (macOS/Linux)

- Shell implementation of complex data structures (dictionaries, queues, etc.)
- Platform-specific functions for macOS and Linux
- Auto-generated shell completion for all commands, options and argument values (`xlib comp -i`)

### xjar (Linux)

- Process Management: Start/Stop/Restart JAR applications
- Log Management: View, split (auto-rotate), and clean logs
- Status Monitoring: Display process information, CPU/memory usage, network connections, and thread details
- Batch Operations: Supports multi-directory batch management
- Debugging Support: Supports JDWP remote debugging

### qrsender (Linux -> Windows)

- Features: Transfer files in isolated environments where USB, network, or Bluetooth cannot be used.
- Principle: The sender displays the QR code sequence sequentially as an animation on the terminal (with progress numbers). The receiver automatically scans the QR code sequence to reconstruct the original file and calculates packet loss. The sender retransmits based on the sequence numbers.

---

## 📄 License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for the full license text.

