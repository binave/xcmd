'   Copyright 2017 bin jin
'
'   Licensed under the Apache License, Version 2.0 (the "License");
'   you may not use this file except in compliance with the License.
'   You may obtain a copy of the License at
'
'       http://www.apache.org/licenses/LICENSE-2.0
'
'   Unless required by applicable law or agreed to in writing, software
'   distributed under the License is distributed on an "AS IS" BASIS,
'   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
'   See the License for the specific language governing permissions and
'   limitations under the License.

Sub zip(sourcePath, zipPath)
	Dim emptyZipFile, zipFile
	' Create empty zip file
	Set emptyZipFile = fso.CreateTextFile(zipPath, true)
	emptyZipFile.Write "PK" & Chr(5) & Chr(6) & String(18, Chr(0))
	emptyZipFile.Close
	Set zipFile = CreateObject("Shell.Application").NameSpace(zipPath)
	zipFile.CopyHere sourcePath, 256
	Do
		WScript.Sleep 1000
	Loop Until zipFile.Items.Count > 0
End Sub

Sub unZip(zipPath, targetPath)
	Dim shellApp, source, target
	If not fso.FolderExists(targetPath) Then
		fso.CreateFolder(targetPath)
	End If
	Set shellApp = CreateObject("Shell.Application")
	Set source = shellApp.NameSpace(zipPath).Items()
	Set target = shellApp.NameSpace(targetPath)
	target.CopyHere source, 256
End Sub

Function bin2Base64(path)
	Dim bin, stream
	Set stream = CreateObject("ADODB.Stream")
	stream.Type = 1
	stream.Open
	stream.LoadFromFile path
	Set bin = CreateObject("Microsoft.XMLDOM").CreateElement("binary")
	bin.DataType = "bin.base64"
	bin.NodeTypedValue = stream.Read
	stream.Close
	bin2Base64 = bin.Text
End Function

Sub base64ToBin(base64Strng, path)
	Dim bin, stream
	Set bin = CreateObject("Microsoft.XMLDOM").CreateElement("binary")
	bin.DataType = "bin.base64"
	bin.Text = base64Strng
	Set stream = CreateObject("ADODB.Stream")
	stream.Type = 1
	stream.Open
	stream.write bin.NodeTypedValue
	stream.saveToFile path, 2
	stream.Close
End Sub

Function getClip
	Dim ieApp, clipText
	' htmlfile, xmlfile, mhtmlfile
	clipText = CreateObject("htmlfile").parentWindow.clipboardData.getData("text")
	If len(clipText) = 0 Then
		clipText = GetObject("\", "htmlfile").parentWindow.clipboardData.getData("text")
		If len(clipText) = 0 Then
			Set ieApp = CreateObject("InternetExplorer.Application")
			ieApp.navigate "about:blank"
			ieApp.visible = False
			clipText = ieApp.document.parentwindow.clipboarddata.getdata("text")
		End If
	End If
	getClip = clipText
End Function

Sub setClip(base64Strng)
	Dim fso, logFile, logPath, wshShell
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set wshShell = CreateObject("WScript.Shell")
	If fso.FileExists(fso.GetSpecialFolder(0) & "\System32\clip.exe") Then
		' use clip.exe
		logPath = fso.GetSpecialFolder(2) & "\" & getNow & ".log"
		Set logFile = fso.CreateTextFile(logPath, true)
		logFile.Write base64Strng
		logFile.Close
		WshShell.Run "%ComSpec% /c ""%windir%\system32\clip.exe < """ & logPath, 0, true
		fso.deleteFile logPath
	Else
		' use javascript
		wshShell.Environment("process").item("@") = base64Strng
		wshShell.Run "mshta ""javascript:clipboardData.setData('text', new ActiveXObject('WScript.Shell').Environment('process').item('@'));close();""", 0, true
	End If
End Sub

Function to64Column(strng)
	Dim regEx
	Set regEx = New RegExp
	regEx.Pattern = "(.{64})"
	regEx.Global = True
	to64Column = regEx.Replace(Replace(strng, chr(10), ""), "$1" & chr(10)) & chr(10) & chr(10)
End Function

Function getNow
	Dim regEx
	Set regEx = New RegExp
	regEx.Pattern = "[\D]"
	regEx.Global = True
	getNow = regEx.Replace(Now & right(FormatNumber(timer * 100, 0), 2), "")
End Function

Function getDp0
	getDp0 = CreateObject("Scripting.FileSystemObject").GetFile(Wscript.ScriptFullName).ParentFolder.Path
End Function

Function isZipHead(base64Strng)
	' UEsDBBQAAAAIA
	isZipHead = (mid(base64Strng, 1, 5) = "UEsDB")
End Function

Function isGzHead(base64Strng)
	' H4sIA
	isGzHead = (mid(base64Strng, 1, 5) = "H4sIA")
End Function

Function isBz2Head(base64Strng)
	' QlpoOTFBWSZTW
	isBz2Head = (mid(base64Strng, 1, 5) = "QlpoO")
End Function

Dim arg, text, fso, zipPath
Set arg = WScript.Arguments
Set fso = CreateObject("Scripting.FileSystemObject")
zipPath = fso.GetSpecialFolder(2) & "\" & getNow & ".zip"

If arg.Count = 0 Then
	text = getClip
	If len(text) > 0 Then
		If isZipHead(text) Then
			base64ToBin text, zipPath
			unZip zipPath, getDp0
			fso.deleteFile zipPath
			WScript.Quit(0)
		ElseIf isGzHead(text) Then
			base64ToBin text, getDp0 & "\" & getNow & ".tar.gz"
			Wscript.Quit(0)
		ElseIf isBz2Head(text) Then
			base64ToBin text, getDp0 & "\" & getNow & ".tar.bz2"
			Wscript.Quit(0)
		End If
	End If
	Wscript.Echo "Nothing to do"
	WScript.Quit(1)
Else
	' get file to clip
	If not (fso.FolderExists(arg(0)) or fso.FileExists(arg(0))) Then
		Wscript.Echo "No such file or directory"
		WScript.Quit(1)
	Else
		If fso.GetExtensionName(arg(0)) = "gz" or fso.GetExtensionName(arg(0)) = "bz2" Then
			text = bin2Base64(arg(0))
			setClip to64Column(text)
		Else
			zip arg(0), zipPath
			text = bin2Base64(zipPath)
			fso.deleteFile zipPath
			setClip to64Column(text)
		End If
		Wscript.Echo "finish"
	End If
End If
