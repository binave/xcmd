@echo off
::     Copyright 2023 bin jin
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

if /i "%~1"=="single-line" call :cat\%* & goto :eof

for %%a in (
    nircmd.exe
    zbarimg.exe
) do if "%%~$path:a"=="" >&2 echo %%~a not in PATH & exit /b 1

setlocal enabledelayedexpansion

set tmp_img=%temp%\qreceiver-%random%%random%%random%.png
set /a acc=0, null_count=100
set end_timestamp=
set dir_name=
set qr_count=
set out_pre=
set screen=

:screenshot
set idx=
set qr_decode=

:: nircmd.exe savescreenshot [filename] {x y width height}
nircmd.exe savescreenshot %tmp_img% %~1 %~2 %~3 %~4

for /f "usebackq tokens=1-3*" %%a in (`
    zbarimg.exe --raw --quiet %tmp_img%
`) do set qr_decode=1& if "%%~b" neq "" (
    if "%%~b"=="begin" if not defined _begin set "dir_name=.qreceiver-%%~d-%%~c"& 2>nul mkdir "!dir_name!"& set filename=%%~d& set sha1=%%~c& set /p=name:%%~d,<nul
    if not defined _%%~b set idx=%out_pre%%%~b& >nul 2>nul move /y "!dir_name!\%out_pre%%%~b" "!dir_name!\%out_pre%%%~b.old"
    @REM if "%%~b"=="end" set end_timestamp=%%~d
    set _%%~b=1

) else if defined _begin 2>nul ( >> "!dir_name!\!idx!" echo %%a)

if defined idx (
    set /p=%idx:*.=%,<nul
    set acc=0
) else (
    set /p=,<nul
    set /a acc+=1
    if !acc! gtr %null_count% (
        >&2 echo "more than %null_count% attempts"
        exit /b 1
    )
)

@REM if not defined qr_decode if defined dir_name (
@REM     set /a screen+=1
@REM     >nul copy /y %tmp_img% %dir_name%\!screen!.png
@REM     goto screenshot
@REM )

@REM start /w MsHta.exe JavaScript:document.write();setTimeout('close()',100);

if "%idx:*.=%"=="begin" (
    for /f "usebackq tokens=1-6 delims=," %%a in (
        "%dir_name%\begin"
    ) do set /a step_rows=%%~c, qr_count=%%~d, max_nr=%%~e& set out_type=%%~f& set out_pre=%%~c.
    if defined qr_count if !qr_count! gtr %null_count% set null_count=!qr_count!
    set /p=qr_count:!qr_count!,step_rows:!step_rows! -^> <nul
)

if "%idx:*.=%"=="end" goto end

goto screenshot

:end
echo.
erase /q %tmp_img%

if not defined _begin exit /b 1

set index_list=
for /l %%a in (
    1,1,%qr_count%
) do if not exist "%dir_name%\%out_pre%%%a" set "index_list=!index_list! %%a"

if defined index_list (
    >&2 echo ./qrsender.sh %filename% -s %step_rows% -l "%index_list:~1%"
    exit /b 1
)

for %%a in (
    openssl.exe tar.exe
    7z.exe 7za.exe
) do if "%%~$path:a" neq "" set _%%~na=1

if defined _7za (
    set _7z=7za.exe
) else if defined _7z set _7z=7z.exe

set complete_in_nt=1
set src_file_gz_suf=
for %%a in (%filename%) do if /i "%%~xa"==".gz" set src_file_gz_suf=1

if defined _openssl (
    if "%out_type%"=="d" (
        if defined _7z call "%~f0" single-line "%dir_name%" %qr_count% %out_pre% | openssl.exe base64 -A -d -in - | %_7z% x -si -tgzip -so | %_7z% x -si -ttar -o. -aoa && goto complete
        if defined _tar call "%~f0" single-line "%dir_name%" %qr_count% %out_pre% | openssl.exe base64 -A -d -in - | tar.exe -xzf - && goto complete
    )
    if "%out_type%"=="f" (
        if defined src_file_gz_suf call "%~f0" single-line "%dir_name%" %qr_count% %out_pre% | openssl.exe base64 -A -d -in - > "%filename%" && goto complete
        if defined _7z if not defined src_file_gz_suf call "%~f0" single-line "%dir_name%" %qr_count% %out_pre% | openssl.exe base64 -A -d -in - | %_7z% x -si -tgzip -so > "%filename%" && goto complete
    )
)

@REM TODO CertUtil.exe -decode InFile OutFile

set \n=^


set \n=^^^%\n%%\n%^%\n%%\n%
set complete_in_nt=
>"%filename%.base64" type nul
:: for /f "usebackq delims=0123456789" -> grep -v '^^[0-9]\+$'
for /l %%a in (
    1,1,%qr_count%
) do set /p=.<nul& for /f "usebackq delims=" %%b in (
    "%dir_name%\%out_pre%%%a"
) do for /f "usebackq delims=0123456789" %%c in (
    '%%b'
) do >>"%filename%.base64" set /p=%%~b%\n%<nul

echo.

echo cat "%filename%.base64" ^| [ "$(sha1sum -)" == "%sha1%  -" ] ^&^& echo OK
echo.
set /p=base64 -d "%filename%.base64" <nul
if "%out_type%"=="d" echo ^| tar -xzf -
if "%out_type%"=="f" for %%a in (%filename%) do if /i "%%~xa" neq ".gz" set /p=^| zcat <nul
if "%out_type%"=="f" echo ^> "%filename%"

:complete

if defined complete_in_nt echo complete! receive file '%filename%'
rmdir /s /q "%dir_name%"

goto :eof

:cat\single-line
    if not exist "%~f1" exit /b 1
    if "%~2"=="" exit /b 1
    for /l %%a in (
        1,1,%~2
    ) do for /f "usebackq delims=" %%b in (
        "%~f1\%~3%%a"
    ) do for /f "usebackq delims=0123456789" %%c in (
        '%%b'
    ) do set /p=%%~b<nul
    goto :eof
