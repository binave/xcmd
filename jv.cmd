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

REM Need import lib.cmd
for %%a in (lib.cmd) do if "%%~$path:a"=="" >&2 echo Error: Need lib.cmd& exit /b 1


setlocal enabledelayedexpansion
:: config
set JVMSource=Applications\JavaVirtualMachines
set JVMtarget=Applications\Utilities\JavaVM

:: init
call :this\getConfigureStatus || >%userprofile%\.jvm call :this\reset
:: test JVM
call :this\fileNotEmpty %userprofile%\.jvm || (
	echo Error: No JVM installation found.
	endlocal
	exit /b 1
)
:: get current JVM info
call :this\getCurrentIndex \\\currentIndex
if not defined \\\currentIndex set \\\currentIndex=0

set /a \\\newIndex=\\\currentIndex
for %%a in (%*) do (
	call lib.cmd inum %%~a && set \\\newIndex=%%~a
	if "%%~a"=="+" set /a \\\newIndex+=1
	if "%%~a"=="-" set /a \\\newIndex-=1
)
:: correction
if %\\\newIndex% lss 1 set \\\newIndex=1
if %\\\newIndex% gtr %\\\indexCount% set /a \\\newIndex=\\\indexCount

call :this\print %\\\newIndex% %\\\currentIndex%
endlocal
goto :eof

:this\getConfigureStatus
	if not exist "%userprofile%\.jvm" exit /b 1
	set \\\varCount=0
	for /f "usebackq delims=" %%a in (
		"%userprofile%\.jvm"
	) do set /a \\\varCount+=1 & set %%a
	call lib.cmd gfirstpath %JVMSource% \\\JVMSourcePath
	:: if statusCode not change, No JVM found
	for /d %%a in (
		%\\\JVMSourcePath%\*
	) do if exist "%%a\bin\java.exe" set /a \\\varCount-=1
	if %\\\varCount% neq 0 exit /b 1
	call :this\checkVariable || exit /b 1
	exit /b 0

:this\print
	if "%~2"=="" goto :eof
	setlocal enabledelayedexpansion
	set \\\str0=JRE
	set \\\str1=JDK
	set \\\index=0
	for /f "usebackq tokens=1* delims==" %%a in (
		`set \\\JVM\ 2^>nul`
	) do for /f "usebackq tokens=2-4 delims=\" %%c in (
		'%%a'
	) do (
		set "\\\use= "
		set /a \\\index+=1
		if "%~1"=="!\\\index!" (
			set \\\use=^*
			if "%~1" neq "%~2" call :this\reLink "%%b"
		)
		if "!\\\index:~1,1!"=="" (
			echo !\\\use! !\\\str%%e! 0!\\\index! %%d %%c-bit
		) else echo !\\\use! !\\\str%%e! !\\\index! %%d %%c-bit
	)
	endlocal
	goto :eof

:this\getCurrentIndex
	if "%~1"=="" exit /b 1
	for %%a in (java.exe) do set JAVA_HOME=%%~dp$path:a
	if not exist "%JAVA_HOME%" exit /b 1
	set JAVA_HOME=%JAVA_HOME:~0,-5%
	call :this\getJvmInfo %JAVA_HOME% \\\currentInfo
	set \\\indexCount=0
	for /f "usebackq delims==" %%a in (
		`set \\\JVM\ 2^>nul`
	) do set /a \\\indexCount+=1 & if /i "%%a"=="%\\\currentInfo%" set %~1=!\\\indexCount!
	set \\\currentInfo=
	goto :eof

:this\getJvmInfo
	if not exist %~1\bin\java.* exit /b 1
	set \\\version=
	set \\\temp=
	set \\\tmp=
	set /a \\\bit=32,\\\canMake=0
	for /f "usebackq delims=" %%a in (
		`%~1\bin\java -version 2^>^&1`
	) do for %%b in (%%a) do (
		set \\\tmp=%%b
		for %%c in (!\\\temp!) do if "!\\\tmp:%%c=!" neq "%%b" set \\\version=!\\\tmp:~0,-1!
		if "%%b"=="64-Bit" set \\\bit=64
		if "%%~b"==%%b set \\\temp=%%~b
	)
	if exist "%~1\bin\javac.exe" set \\\canMake=1
	if "%~2" neq "" (
		set %~2=\\\JVM\%\\\bit%\%\\\version%\%\\\canMake%
	) else set \\\JVM\%\\\bit%\%\\\version%\%\\\canMake%=%~1
	goto :eof

:this\checkVariable
	for /f "usebackq tokens=2 delims==" %%a in (
		`set \\\JVM\ 2^>nul`
	) do if not exist "%%a\bin\java.exe" exit /b 1
	exit /b 0

:this\reLink
	if not exist "%~1\bin\java.*" exit /b 1
	if not defined \\\JVMSourcePath call lib.cmd gfirstpath %JVMSource% \\\JVMSourcePath
	setlocal
	for %%a in (%\\\JVMSourcePath%) do set \\\JVMCurrentPath=%%~da\%JVMtarget%
	for %%a in (%\\\JVMCurrentPath%) do if not exist "%%~dpa" mkdir "%%~dpa"
	if exist "%\\\JVMCurrentPath%" rmdir /s /q "%\\\JVMCurrentPath%"
	>nul mklink /j "%\\\JVMCurrentPath%" %1
	endlocal
	exit /b 0

:this\reset
	call lib.cmd uset \\\JVM\
	if not defined \\\JVMSourcePath call lib.cmd gfirstpath %JVMSource% \\\JVMSourcePath
	for /d %%a in (
		%\\\JVMSourcePath%\*
	) do call :this\getJvmInfo %%a
	set \\\JVMSourcePath=
	set \\\JVM\ 2>nul
	goto :eof

:this\fileNotEmpty
	if not exist "%~1" exit /b 1
	if %~z1 lss 9 exit /b 1
	exit /b 0
