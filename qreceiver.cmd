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

:screenshot
set idx=

@REM nircmd.exe savescreenshot %tmp_img% 1210 370 1200 900
nircmd.exe savescreenshot %tmp_img%

for /f "usebackq tokens=1-3*" %%a in (`
    zbarimg.exe --raw --quiet %tmp_img%
`) do if "%%~b" neq "" (
    if not defined _%%~b set idx=%%~b
    if "%%~b"=="begin" if not defined _begin set "dir_name=.qreceiver-%%~d-%%~c"& 2>nul mkdir "!dir_name!"& set filename=%%~d& set sha1=%%~c
    2>nul erase "!dir_name!\%%~b"
    @REM if "%%~b"=="end" set end_timestamp=%%~d
    set _%%~b=1

) else if defined _begin 2>nul ( >> "!dir_name!\!idx!" echo %%a)

@REM start /w MsHta.exe JavaScript:document.write();setTimeout('close()',100);

if "%idx%"=="begin" (
    for /f "usebackq tokens=1-6 delims=," %%a in (
        "%dir_name%\begin"
    ) do set /a qr_count=%%~d, step_rows=%%~c
    set /p=step:!step_rows!,count:!qr_count!,<nul
    set "dir_name=%dir_name%\!step_rows!"& 2>nul mkdir "!dir_name!"
)

set /p=!idx!,<nul
if defined idx (
    set acc=0
) else (
    set /a acc+=1
    if defined qr_count (
        if !acc! gtr %qr_count% goto end
    ) else if !acc! gtr %null_count% exit /b 0

)
if "%idx%"=="end" goto end

goto screenshot

:end
echo.
erase /q %tmp_img%

if not defined _begin exit /b 1

set index_list=
for /l %%a in (
    1,1,%qr_count%
) do if not exist "%dir_name%\%%a" set "index_list=!index_list! %%a"

if defined index_list (
    >&2 echo ./qrsender.sh %filename% -s %step_rows% -l "%index_list:~1%"
    exit /b 1
)

>"%filename%.base64" type nul
for /l %%a in (
    1,1,%qr_count%
) do set /p=.<nul& for /f "usebackq delims=" %%b in (
    "%dir_name%\%%a"
) do >>"%filename%.base64" echo %%b
echo.

for /f "usebackq tokens=1-6 delims=," %%a in (
    "%dir_name%\..\begin"
) do set out_type=%%~f

set /p=sed 's/[[:space:]]//g' "%filename%.base64" ^| grep -v '^[0-9]\+$' ^| base64 -d <nul
if "%out_type%"=="d" set /p=^| tar -xzf - <nul
if "%out_type%"=="f" for %%a in (%filename%) do if /i "%%~xa" neq ".gz" set /p=^| zcat <nul
echo ^> "%filename%"

rmdir /s /q "%dir_name%"

goto :eof
