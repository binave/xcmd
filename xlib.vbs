Option Explicit

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

' Framework
'     A function whose name conforms to the specification gets:
'         External invocation.
'         Error handling.
'         Help information.
'         The functions list.
'
'     The annotation ['''] is the help text and must sit directly above the function it describes;
'     any other comment must use a single [']. For example:
'         ''' [brief_introduction] 'Usage: xlib [function_name] [OPTION]... [OPERAND]...
'             '  -o, --option=FILE   [description]
'         Function [script_name_without_suffix]_[function_name]()
'             [function_body]
'             ...
'             setErr "[error_description]" ' Exit and display [error_description].
'             setErr 1 ' Return false status.
'         End Function

''' Print version and exit 'Usage: xlib version
Function xlib_version()
    printLine "0.26.9.26"
End Function

''' Sleep some milliseconds 'Usage: xlib sleep MS
Function xlib_sleep(ms)
    ' Ensure MS is numeric.
    If Not IsNumeric(ms) Then setErr "Args not a number"
    WScript.Sleep ms
End Function

''' Run a command in the background 'Usage: xlib vbhide COMMAND
Function xlib_vbhide(command)
    ' 0 hides the window; the call returns without waiting for the command.
    CreateObject("WScript.Shell").Run command, 0
End Function

''' Download a URL and save the response to a file 'Usage: xlib get URL FILE '  URL    address to download '  FILE   file to write the response body to
Function xlib_get(url, output)
    Dim htt, stream
    Set htt = gXmlHttp()
    htt.Open "GET", url, 0
    htt.Send
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 1
    stream.Open
    stream.Write htt.ResponseBody
    stream.SaveToFile output, 2
    stream.Close
End Function

''' Download a URL and print the response as text 'Usage: xlib getprint URL
Function xlib_getprint(url)
    Dim htt
    Set htt = gXmlHttp()
    htt.Open "GET", url, 0
    htt.Send
    printLine htt.ResponseText
End Function

' REF http://demon.tw/programming/vbs-unzip-file.html
''' Create a zip archive from a file or folder 'Usage: xlib zip SOURCE ZIPFILE '  SOURCE    file or folder to compress '  ZIPFILE   zip archive to create
Function xlib_zip(sourcePath, zipPath)
    Dim emptyZipFile, zipFile, fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    ' Shell.Application only accepts full paths.
    sourcePath = fso.GetAbsolutePathName(sourcePath)
    zipPath = fso.GetAbsolutePathName(zipPath)
    If Not fso.FileExists(sourcePath) Then
        If Not fso.FolderExists(sourcePath) Then setErr "The target was not found"
    End If
    ' Create an empty zip file.
    Set emptyZipFile = fso.CreateTextFile(zipPath, True)
    emptyZipFile.Write "PK" & Chr(5) & Chr(6) & String(18, Chr(0))
    emptyZipFile.Close
    Set zipFile = CreateObject("Shell.Application").NameSpace(zipPath)
    ' 4: no progress dialog, 16: yes to all, 512: no new folder prompt, 1024: no error dialog.
    zipFile.CopyHere sourcePath, 1556
    ' The empty archive is 22 bytes; a bigger, settled file means the source was added.
    If Not gWaitFile(zipPath, 22) Then setErr "Compress failed"
End Function

' REF http://demon.tw/programming/vbs-unzip-file.html
''' Extract a zip archive into a folder 'Usage: xlib unzip ZIPFILE DIRECTORY '  ZIPFILE     zip archive to extract '  DIRECTORY   folder to extract into
Function xlib_unZip(zipPath, targetPath)
    Dim fso, shellApp, source, target
    Set fso = CreateObject("Scripting.FileSystemObject")
    ' Shell.Application only accepts full paths.
    zipPath = fso.GetAbsolutePathName(zipPath)
    targetPath = fso.GetAbsolutePathName(targetPath)
    If Not fso.FileExists(zipPath) Then setErr "The target was not found"
    If Not fso.FolderExists(targetPath) Then fso.CreateFolder(targetPath)
    Set shellApp = CreateObject("Shell.Application")
    Set source = shellApp.NameSpace(zipPath).Items()
    Set target = shellApp.NameSpace(targetPath)
    ' 4: no progress dialog, 16: yes to all, 512: no new folder prompt, 1024: no error dialog.
    target.CopyHere source, 1556
    ' CopyHere returns before the files are written, so wait for the folder to settle.
    If source.Count > 0 Then
        If Not gWaitDir(targetPath) Then setErr "Extract failed"
    End If
End Function

''' Print the clipboard text 'Usage: xlib gClip
Function xlib_gClip()
    printLine gClip()
End Function

''' Set the clipboard to the given text 'Usage: xlib sClip STRING
Function xlib_sClip(text)
    Dim fso, logFile, logPath, wshShell, clipExe
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set wshShell = CreateObject("WScript.Shell")
    clipExe = fso.GetSpecialFolder(0) & "\System32\clip.exe"
    If fso.FileExists(clipExe) Then
        ' Use clip.exe when it is available, that is on Windows Vista and later.
        logPath = fso.GetSpecialFolder(2) & "\" & fso.GetTempName()
        ' The temporary file is written as Unicode so that the text survives the pipe.
        Set logFile = fso.CreateTextFile(logPath, True, True)
        logFile.Write text
        logFile.Close
        ' 'cmd /u' makes type emit UTF-16, which clip.exe reads exactly. Feeding the
        ' file in with '<' would copy the byte order mark into the clipboard as text.
        wshShell.Run "%ComSpec% /u /c type """ & logPath & """ | " & clipExe, 0, True
        fso.DeleteFile logPath
    Else
        ' Fall back to a JavaScript snippet run through mshta; Windows XP takes this path.
        wshShell.Environment("process").Item("@") = text
        wshShell.Run "mshta ""javascript:clipboardData.setData('text', new ActiveXObject('WScript.Shell').Environment('process').item('@'));close();""", 0, True
    End If
End Function

''' Decode a base64 text file into a binary file 'Usage: xlib txt2bin TEXTFILE BINFILE '  TEXTFILE   file containing the base64 text '  BINFILE    binary file to write
Function xlib_txt2bin(source, target)
    Dim content, text
    ' Read the source file and extract its base64 text.
    Set content = CreateObject("Scripting.FileSystemObject").OpenTextFile(source, 1)
    text = gBase64(content.ReadAll)
    content.Close
    If Len(text) = 0 Then setErr "No base64 text found"
    base64ToBin text, target
End Function

''' Encode a binary file as a base64 string 'Usage: xlib bin2Base64 FILE
Function xlib_bin2Base64(source)
    printLine bin2Base64(source)
End Function

''' Print a new GUID 'Usage: xlib guuid
Function xlib_guuid()
    ' Scriptlet.TypeLib is available on Windows XP and later; its Guid property carries
    ' a trailing Chr(0), so the 38 characters of the braced GUID are cut explicitly.
    xlib_guuid = Left(CreateObject("Scriptlet.TypeLib").Guid, 38)
    printLine xlib_guuid
End Function

''' Print the current date and time with hundredths of a second 'Usage: xlib gnow
Function xlib_gnow()
    Dim t
    t = Now
    ' yyyyMMddhhmmss plus hundredths of a second, for example 2017010112000099.
    xlib_gnow = gPad(Year(t), 4) & gPad(Month(t), 2) & gPad(Day(t), 2) _
        & gPad(Hour(t), 2) & gPad(Minute(t), 2) & gPad(Second(t), 2) _
        & gPad(Int(Timer * 100) Mod 100, 2)
    printLine xlib_gnow
End Function

''' Toggle the Unicode header of a file 'Usage: xlib ansi2unic FILE '  FILE   file to convert in place
Function xlib_ansi2unic(path)
    Dim bin, stream
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 1
    stream.Open
    stream.LoadFromFile path
    Set bin = CreateObject("Microsoft.XMLDOM").CreateElement("binary")
    bin.DataType = "bin.hex"
    bin.NodeTypedValue = stream.Read
    stream.Close
    If 1 = gType(bin.Text) Then
        bin.Text = Mid(bin.Text, 17)
    Else
        bin.Text = "fffe2026636c7326" & bin.Text
    End If
    stream.Open
    stream.Write bin.NodeTypedValue
    stream.SaveToFile path, 2
    stream.Close
End Function

''' Split an INF driver file into lines and strip whitespace 'Usage: xlib inftrim SOURCE TARGET '  SOURCE   INF file to read '  TARGET   file to write
Function xlib_inftrim(source, target)
    Dim fso, fIn, fOut, text
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set fIn = fso.OpenTextFile(source)
    text = fIn.ReadAll
    fIn.Close
    text = Replace(text, Chr(9), "")
    text = Replace(text, Chr(32), "")
    ' for i = 1 to 10
    '     text = replace(text, chr(32) & chr(32), chr(32))
    ' next
    ' Replace the ; (59) and , (44) separators with line breaks.
    text = Replace(text, Chr(59), vbNewLine)
    text = Replace(text, Chr(44), vbNewLine)
    ' text = replace(text, chr(32) & vbNewLine, chr(13))
    ' Create the output file.
    Set fOut = fso.CreateTextFile(target, True)
    fOut.WriteLine text
    fOut.Close
End Function

''' Transform an XML file with an XSL stylesheet 'Usage: xlib doxsl XML XSL OUTPUT '  XML      XML input file '  XSL      XSL stylesheet '  OUTPUT   file to write the result to
Function xlib_doxsl(xml, xsl, output)
    Dim ver, xmlObj, xslObj, fOut
    ' ver = 6
    ver = 3 ' Version 3 supports Windows NT 5.2.
    Set xmlObj = CreateObject("MSXML2.DOMDocument." & ver & ".0")
    xmlObj.async = False
    xmlObj.validateOnParse = False
    If Not xmlObj.load(xml) Then setErr "XML parse error: " & xmlObj.parseError.reason

    Set xslObj = CreateObject("MSXML2.DOMDocument." & ver & ".0")
    xslObj.async = False
    xslObj.validateOnParse = False
    If Not xslObj.load(xsl) Then setErr "XSL parse error: " & xslObj.parseError.reason

    Set fOut = CreateObject("Scripting.FileSystemObject").CreateTextFile(output, True)
    fOut.Write xmlObj.transformNode(xslObj)
    fOut.Close
End Function

''' Print the drive letters of drives with the given file system 'Usage: xlib gfsd {NTFS|FAT32|EXFAT}
Function xlib_gfsd(tag)
    Dim drv
    For Each drv In CreateObject("Scripting.FileSystemObject").Drives
        If drv.IsReady Then
            If LCase(tag) = LCase(drv.FileSystem) Then
                printLine drv.DriveLetter & Chr(58)
            End If
        End If
    Next
End Function

''' Create a shortcut to a file 'Usage: xlib lnkd SOURCE TARGET '  SOURCE   file the shortcut points to '  TARGET   Desktop, AllUsersDesktop, or a folder path
Function xlib_lnkd(sourceFilePath, targetFolder)
    Dim WshShell, Fso, targetDir, lnk
    Set WshShell = CreateObject("WScript.Shell")
    Set Fso = CreateObject("Scripting.FileSystemObject")
    If Not Fso.FileExists(sourceFilePath) Then setErr "The target was not found"

    ' A shell folder name resolves to its path; anything else is used as a path.
    targetDir = ""
    On Error Resume Next
    targetDir = WshShell.SpecialFolders(targetFolder)
    On Error GoTo 0
    If targetDir = "" Then targetDir = targetFolder

    Set lnk = WshShell.CreateShortcut(targetDir & "\" & Fso.GetBaseName(sourceFilePath) & ".lnk")
    lnk.TargetPath = sourceFilePath
    lnk.Arguments = ""
    lnk.WorkingDirectory = Fso.GetFile(sourceFilePath).ParentFolder.Path
    lnk.WindowStyle = 1 ' Normal window.
    lnk.Hotkey = ""
    lnk.IconLocation = sourceFilePath & ", 0"
    lnk.Description = ""
    lnk.Save
End Function


''''''''''''''''
'   Template   '
''''''''''''''''

''' Tag each line from standard input with a formatted time prefix 'Usage: COMMAND | xlib log FORMAT '  FORMAT   format string; $F, $T, $Y, $y, $m, $d, $H, $M and $S are replaced
Function xlib_log(format)
    Dim StdIn, StdOut, t
    ' The standard streams are only available under cscript.exe.
    If Not iCscript() Then setErr "Requires cscript.exe"
    Set StdIn = WScript.StdIn
    Set StdOut = WScript.StdOut
    Do While Not StdIn.AtEndOfStream
        t = Now
        StdOut.WriteLine gStamp(format, t) & StdIn.ReadLine
    Loop
End Function

' Function xlib_log(separator)
'     Set StdIn = WScript.StdIn
'     Do While Not StdIn.AtEndOfStream
'         line = StdIn.ReadLine
'         printLine Replace(FormatDateTime(Now()) , "/", "-") & separator & line
'     Loop
' End Function

''''''''''''''''''''''
'   Private functions   '
''''''''''''''''''''''

' Create a Microsoft.XMLHTTP object for HTTP requests.
Function gXmlHttp()
    ' The object name is split to reduce antivirus false positives.
    Set gXmlHttp = CreateObject("Microsoft" & Chr(46) & "XML" & "HT" & Chr(84) & "P")
End Function

' BKDR hash function.
''' Print the BKDR hash of a string 'Usage: xlib hash STRING
Function xlib_hash(key)
    Dim seed, hash, i
    seed = 131 ' Common BKDR seeds: 31, 131, 1313, 13131, 131313.
    hash = 0
    ' CDbl keeps the arithmetic inside the Double range, and the remainder keeps the
    ' accumulator inside the Long range, so that a long string cannot overflow it.
    For i = 1 To Len(key)
        hash = CDbl(hash) * seed + Asc(Mid(key, i, 1))
        hash = hash - Int(hash / 2147483647) * 2147483647
    Next
    printLine hash
End Function

' Read text from the clipboard.
Function gClip()
    Dim ieApp, text
    text = ""
    On Error Resume Next
    ' htmlfile, xmlfile or mhtmlfile can provide clipboardData.
    text = "" & CreateObject("htmlfile").parentWindow.clipboardData.getData("text")
    If Len(text) = 0 Then
        text = "" & GetObject("\", "htmlfile").parentWindow.clipboardData.getData("text")
    End If
    If Len(text) = 0 Then
        Set ieApp = CreateObject("InternetExplorer.Application")
        ieApp.navigate "about:blank"
        ieApp.visible = False
        text = "" & ieApp.document.parentwindow.clipboarddata.getdata("text")
        ieApp.Quit
    End If
    On Error GoTo 0
    gClip = text
End Function

' Wrap a string into lines of 64 characters.
Function to64Column(strng)
    Dim regEx
    ' Drop the line breaks of the source before wrapping it again.
    strng = Replace(Replace(strng, vbCrLf, ""), vbLf, "")
    Set regEx = New RegExp
    regEx.Pattern = "(.{64})"
    regEx.Global = True
    to64Column = regEx.Replace(strng, "$1" & vbNewLine) & vbNewLine
End Function

' Test whether a string is base64 text; used internally.
Function iBase64(strng)
    Dim regEx
    Set regEx = New RegExp
    ' Accept the base64 alphabet with or without line breaks.
    regEx.Pattern = "^[0-9a-zA-Z/+" & Chr(61) & vbCrLf & "]*$"
    iBase64 = regEx.Test(strng)
End Function

' Extract base64 text from a string; used internally.
Function gBase64(strng)
    Dim regEx, matches, i, text, best
    ' Drop the line breaks and the remaining whitespace first; the same pass joins the
    ' lines of a wrapped payload, whatever their width.
    text = Replace(Replace(Replace(strng, vbCr, ""), vbLf, ""), vbTab, "")
    text = Replace(text, " ", "")
    Set regEx = New RegExp
    regEx.Pattern = "^[0-9a-zA-Z/+]+={0,2}$"
    If 0 < Len(text) Then
        ' Base64 is a multiple of four characters long.
        If Len(text) Mod 4 = 0 Then
            If regEx.Test(text) Then
                ' The whole file is base64 text.
                gBase64 = text
                Exit Function
            End If
        End If
    End If
    ' Otherwise join the consecutive lines that hold nothing but base64 text, so that
    ' the text around the payload is ignored, and keep the longest payload found.
    ' Every line of the block must run to the end of its line.
    regEx.Global = True
    regEx.Pattern = "(?:^|[\r\n]+)[ \t]*(" _
        & "[0-9a-zA-Z/+]{4,}={0,2}[ \t]*(?=[\r\n]|$)" _
        & "(?:[\r\n]+[ \t]*[0-9a-zA-Z/+]{4,}={0,2}[ \t]*(?=[\r\n]|$))*" _
        & ")"
    Set matches = regEx.Execute(strng)
    best = ""
    For i = 0 To matches.Count - 1
        text = Replace(Replace(Replace(matches(i).SubMatches(0), vbCr, ""), vbLf, ""), vbTab, "")
        text = Replace(text, " ", "")
        ' A payload is padded or long; a shorter run is a word of the surrounding text.
        If Len(text) Mod 4 = 0 Then
            If 16 <= Len(text) Or Chr(61) = Right(text, 1) Then
                If Len(text) > Len(best) Then best = text
            End If
        End If
    Next
    gBase64 = best
End Function

' Convert a binary file to a base64 string.
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

' Write a base64 string to a binary file.
Sub base64ToBin(base64Strng, path)
    Dim bin, stream
    Set bin = CreateObject("Microsoft.XMLDOM").CreateElement("binary")
    bin.DataType = "bin.base64"
    bin.Text = base64Strng
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 1
    stream.Open
    stream.Write bin.NodeTypedValue
    stream.SaveToFile path, 2
    stream.Close
End Sub

' Execute the contents of another VBScript file.
Sub vbs(path)
    Dim file
    Set file = CreateObject("Scripting.FileSystemObject").OpenTextFile(path)
    Execute file.ReadAll
    file.Close
End Sub

' Detect the file type from its header bytes; the trailing tags name the encoding.
Function gType(source)
    If "fffe2026636c7326" = (Mid(source, 1, 16)) Then ' Unicode text; the header is a hex string.
        gType = 1
    ElseIf "UEsDB" = (Mid(source, 1, 5)) Then ' Zip archive; the base64 header starts with UEsDBBQAAAAIA.
        gType = 2
    ElseIf "H4sIA" = (Mid(source, 1, 5)) Then ' Gzip archive; the base64 header starts with H4sIA.
        gType = 3
    ElseIf "QlpoO" = (Mid(source, 1, 5)) Then ' Bzip2 archive; the base64 header starts with QlpoOTFBWSZTW.
        gType = 4
    ElseIf "4d5a" = (Mid(source, 1, 4)) Then ' DOS or Windows executable; the header is the hex string 4d5a.
        gType = 5
    ElseIf "7f45" = (Mid(source, 1, 4)) Then ' Unix executable; the header is the hex string 7f45.
        gType = 6
    Else
        gType = 0
    End If
End Function

' Left-pad a number with zeros to the requested width.
Function gPad(value, width)
    gPad = Right(String(width, Chr(48)) & value, width)
End Function

' Replace the date and time placeholders of the log format.
Function gStamp(format, t)
    Dim stamp
    stamp = format
    stamp = Replace(stamp, "$F", gPad(Year(t), 4) & "-" & gPad(Month(t), 2) & "-" & gPad(Day(t), 2))
    stamp = Replace(stamp, "$T", gPad(Hour(t), 2) & ":" & gPad(Minute(t), 2) & ":" & gPad(Second(t), 2))
    stamp = Replace(stamp, "$Y", gPad(Year(t), 4))
    stamp = Replace(stamp, "$y", Right(gPad(Year(t), 4), 2))
    stamp = Replace(stamp, "$m", gPad(Month(t), 2))
    stamp = Replace(stamp, "$d", gPad(Day(t), 2))
    stamp = Replace(stamp, "$H", gPad(Hour(t), 2))
    stamp = Replace(stamp, "$M", gPad(Minute(t), 2))
    stamp = Replace(stamp, "$S", gPad(Second(t), 2))
    gStamp = stamp
End Function

' Return the VBScript literal of an argument, for example "value" or "va""lue".
Function gQuoted(strng)
    gQuoted = Chr(34) & Replace(strng, Chr(34), Chr(34) & Chr(34)) & Chr(34)
End Function

' Wait until a file that is written asynchronously stops growing.
' MIN_SIZE is the size of the file before the write starts; the empty zip is 22 bytes.
Function gWaitFile(path, minSize)
    Dim fso, i, same, size, lastSize
    Set fso = CreateObject("Scripting.FileSystemObject")
    same = 0
    size = 0
    lastSize = -1
    For i = 1 To 240
        If fso.FileExists(path) Then size = fso.GetFile(path).Size
        If size > minSize Then
            If size = lastSize Then
                same = same + 1
                If same >= 3 Then
                    gWaitFile = True
                    Exit Function
                End If
            Else
                same = 0
                lastSize = size
            End If
        End If
        WScript.Sleep 250
    Next
    gWaitFile = False
End Function

' Wait until a folder that is written asynchronously stops growing.
Function gWaitDir(path)
    Dim i, same, size, lastSize
    same = 0
    size = 0
    lastSize = -1
    For i = 1 To 240
        size = gDirSize(path)
        If size = lastSize Then
            same = same + 1
            If same >= 3 Then
                gWaitDir = True
                Exit Function
            End If
        Else
            same = 0
            lastSize = size
        End If
        WScript.Sleep 500
    Next
    gWaitDir = False
End Function

' Return the total size of the files below a folder, recursively.
Function gDirSize(path)
    Dim fso, folder, file, child, total
    Set fso = CreateObject("Scripting.FileSystemObject")
    total = CDbl(0)
    If Not fso.FolderExists(path) Then
        gDirSize = 0
        Exit Function
    End If
    Set folder = fso.GetFolder(path)
    For Each file In folder.Files
        total = total + CDbl(file.Size)
    Next
    For Each child In folder.SubFolders
        total = total + gDirSize(child.Path)
    Next
    gDirSize = total
End Function



' Function copy(path)
'     Dim input, output
'     Set input = CreateObject("ADODB.Stream")
'     input.Type = 1
'     input.Open
'     input.LoadFromFile path

'     Set output = CreateObject("ADODB.Stream")
'     output.Type = 1
'     output.Open

'     Do
'         output.Position = output.size
'         output.Write input.read(100000)
'         ' WScript.Sleep 5000
'         output.saveToFile path & ".bak", 2
'         output.Flush
'         ' output.Position = 0
'         ' output.SetEOS
'     Loop Until input.EOS
'     input.close
'     output.close
' End Function

' CreateObject("WScript.Shell").Run WScript.Arguments(0), 0

' Function getDp0
'     getDp0 = getThis.ParentFolder.Path
' End Function



'''''''''''''''''''''''''''''''''''''''''''''''''''
'                    Framework                    '
' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '

' Raise an error code, or raise a custom error with a description.
Sub setErr(Description)
    Err.Clear
    Err.Source = "Custom Error:"
    If IsNumeric(Description) Then
        Err.Raise Description
    Else
        Err.Description = Description
        Err.Raise 2
    End If
End Sub

' Return True when the script runs under cscript.exe.
Function iCscript()
    iCscript = ("\cscript.exe" = LCase(Right(WScript.FullName, 12)))
End Function

' Print a line to stdout, or show a message box under wscript.exe.
Sub printLine(desc)
    If iCscript() Then
        ' A leading byte order mark makes StdOut fail, for example when the text
        ' comes from the clipboard; it has no meaning in a console stream.
        If ChrW(65279) = Left(desc, 1) Then desc = Mid(desc, 2)
        WScript.StdOut.WriteLine desc
    Else
        MsgBox desc
    End If
End Sub

' Print an error line to stderr, or show an error message box.
Sub errLine(desc)
    If iCscript() Then
        WScript.StdErr.WriteLine desc
    Else
        MsgBox desc, 48, "Error"
    End If
End Sub

' Return the script file name without its extension.
Function gScriptName()
    Dim name, i
    name = WScript.ScriptName
    i = InStrRev(name, Chr(46))
    If i > 1 Then
        gScriptName = Left(name, i - 1)
    Else
        gScriptName = name
    End If
End Function

' Print the lines of a string in sorted order.
' System.Collections.ArrayList is unavailable in Windows PE, so sorting is done manually.
Sub sortPrint(str)
    Dim arr
    arr = Split(str, vbNewLine)
    quickSort arr, LBound(arr), UBound(arr)
    printLine Join(arr, vbNewLine)
End Sub

' Sort an array in place using quick sort.
' REF http://www.cnblogs.com/falconshh/archive/2011/05/30/2063204.html
Sub quickSort(arr, low, high)
    Dim pivotPos
    If low < high Then
        pivotPos = partition(arr, low, high)
        quickSort arr, low, pivotPos - 1
        quickSort arr, pivotPos + 1, high
    End If
End Sub

' Partition an array for quickSort and return the pivot position.
' REF http://www.cnblogs.com/falconshh/archive/2011/05/30/2063204.html
Function partition(arr, low, high)
    Dim i, j, pivot
    i = low
    j = high
    pivot = arr(low)
    While i < j
        ' Compare as text so that the list matches the order of xlib.cmd.
        While i < j And StrComp(arr(j), pivot, vbTextCompare) >= 0
            j = j - 1
        Wend
        arr(i) = arr(j)
        While i < j And StrComp(arr(i), pivot, vbTextCompare) <= 0
            i = i + 1
        Wend
        arr(j) = arr(i)
    Wend
    arr(i) = pivot
    partition = i
End Function

' Scan this script for function annotations.
Function gfuncAnno(method)
    Dim text, line, decl, annotation, name, brief, prefix, target, i
    Dim names(), briefs(), count, width
    prefix = LCase(gScriptName()) & Chr(95)
    target = prefix & LCase(method)
    count = 0
    width = 0
    ' Open this script file to collect the annotations.
    Set text = CreateObject("Scripting.FileSystemObject").OpenTextFile(WScript.ScriptFullName)
    Do Until text.AtEndOfStream
        ' Remove surrounding whitespace.
        line = Trim(text.ReadLine)
        If Chr(39) & Chr(39) & Chr(39) & Chr(32) = Left(line, 4) Then
            ' Store the annotation line just read.
            annotation = Trim(Mid(line, 4))
        ElseIf "function " = LCase(Left(line, 9)) Then
            ' Extract the declared name, for example xlib_sleep.
            decl = Trim(Mid(line, 10, InStr(line & Chr(40), Chr(40)) - 10))
            ' An empty method matches every function of this script.
            If target = LCase(decl) Or (Len(method) = 0 And Left(LCase(decl), Len(prefix)) = prefix) Then
                If Len(method) > 0 Then
                    ' Print every part of the annotation on its own line.
                    For Each brief In Split(annotation, Chr(39))
                        brief = RTrim(brief)
                        If Len(brief) > 0 Then
                            If gfuncAnno = "" Then brief = Trim(brief)
                            gfuncAnno = gfuncAnno & brief & vbNewLine
                        End If
                    Next
                    If Len(gfuncAnno) > Len(vbNewLine) Then
                        gfuncAnno = Left(gfuncAnno, Len(gfuncAnno) - Len(vbNewLine))
                    End If
                    text.Close
                    Exit Function
                End If
                ' Keep only the brief, i.e. the text before the first apostrophe.
                brief = annotation
                i = InStr(brief, Chr(39))
                If i > 0 Then brief = Left(brief, i - 1)
                brief = Trim(brief)
                ' Collect the name without the prefix and the brief for the list.
                name = Mid(decl, Len(prefix) + 1)
                ReDim Preserve names(count)
                ReDim Preserve briefs(count)
                names(count) = name
                briefs(count) = brief
                If Len(name) > width Then width = Len(name)
                count = count + 1
            End If
            ' An annotation only describes the declaration directly below it.
            annotation = ""
        ElseIf "sub " = LCase(Left(line, 4)) Then
            ' A sub cannot be invoked from the command line.
            annotation = ""
        End If
    Loop
    text.Close
    ' Build the function list and line the briefs up in one column.
    For i = 0 To count - 1
        gfuncAnno = gfuncAnno & names(i) & Space(width - Len(names(i)) + 2) & briefs(i) & vbNewLine
    Next
    If Len(gfuncAnno) > Len(vbNewLine) Then
        gfuncAnno = Left(gfuncAnno, Len(gfuncAnno) - Len(vbNewLine))
    End If
End Function

' Return the expression for one argument; "-" means standard input.
Function rArg(i)
    Dim value
    value = WScript.Arguments(i)
    If "-" = value Then
        rArg = "WScript.StdIn.ReadAll"
    Else
        rArg = gQuoted(value)
    End If
End Function

' Test whether the argument asks for help.
Function iHelp(i)
    Dim str
    If 0 = WScript.Arguments.Count Then
        iHelp = True
        Exit Function
    End If
    str = LCase(WScript.Arguments(i))
    iHelp = ("-h" = str Or "--help" = str)
End Function

Sub main()
    Dim arg, MethoParas, funcName, help, i, errNum, errDesc
    MethoParas = ""
    funcName = ""
    i = 0
    ' ' Cache arguments
    ' Set args = WScript.Arguments
    ' ' Cache arguments count
    ' count = args.Count
    ' ' From secend arguments
    ' For i = 1 To count

    ' Next

    ' Assemble the method name and its parameter list.
    ' WScript.Arguments is a collection, not an array.
    For Each arg In WScript.Arguments
        i = i + 1
        If i = 1 Then
            ' A help flag in the first position prints the function list.
            If LCase(arg) = "-h" Or LCase(arg) = "--help" Then
                i = 0
                Exit For ' i stays 0, so the function list is printed.
            End If
            ' Start the call expression, for example xlib_sleep(.
            MethoParas = gScriptName() & Chr(95) & arg & Chr(40)
            funcName = arg
        ElseIf i = 2 Then
            ' A help flag in the second position prints one function help.
            If LCase(arg) = "-h" Or LCase(arg) = "--help" Then
                help = gfuncAnno(funcName)
                If Len(help) = 0 Then
                    errLine "Error: No function found"
                    WScript.Quit 13
                End If
                printLine help
                WScript.Quit 0
            End If
            ' Append the first argument, for example xlib_sleep("100".
            MethoParas = MethoParas & gQuoted(arg)
        Else
            ' Append further arguments, for example xlib_sleep("100","200".
            MethoParas = MethoParas & Chr(44) & gQuoted(arg)
        End If
    Next

    If i = 0 Then
        ' Print the introduction list of all functions.
        help = gfuncAnno("")
        If Len(help) > 0 Then sortPrint help
        WScript.Quit 0
    End If

    ' Close the parameter list so that the call can be evaluated.
    MethoParas = MethoParas & Chr(41)
    On Error Resume Next
    ' Invoke the function with the assembled arguments.
    Eval MethoParas
    ' Fall through to the error handling below.
    errNum = Err.Number
    errDesc = Err.Description

    Select Case errNum
        Case 0
            ' No error; quit with a True status.
            WScript.Quit 0
        Case 1
            ' setErr 1: return a False status to the caller after printing the help.
            printLine gfuncAnno(funcName)
            WScript.Quit 1
        Case 2
            ' Custom error raised by setErr with a description.
            errLine "Error: " & errDesc & Chr(32) _
            & Chr(40) & WScript.ScriptFullName & Chr(58) & gScriptName() & Chr(95) & funcName & Chr(41)
        Case 13, 1002
            errLine "Error: No function found"
        Case 450
            ' The arguments do not match the declaration; show the function help.
            errLine "Error: " & errDesc & Chr(32) _
            & Chr(40) & WScript.ScriptFullName & Chr(58) & gScriptName() & Chr(95) & funcName & Chr(41)
            printLine gfuncAnno(funcName)
        Case Else
            errLine "Error Code: " & errNum & vbNewLine _
            & errDesc & vbNewLine & "args: " & MethoParas
    End Select
    WScript.Quit errNum
    ' On Error GoTo 0
End Sub

' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '
'                    Framework                    '
'''''''''''''''''''''''''''''''''''''''''''''''''''

main()

'' Error numbers already in use.
' 0, 5, 6, 7, 9,
' 10, 11, 13, 14, 17,
' 28, 35, 48,
' 51, 52, 53, 54, 55, 57, 58,
' 61, 62, 67, 68,
' 70, 71, 74, 75, 76,
' 91, 92, 94,
' 322,
' 424, 429, 430, 432, 438, 440, 445, 446, 447, 448, 449, 450, 451, 453, 455, 457, 458, 462, 481,
' 500, 501, 502, 503, 504, 505, 506, 507,
' 1001, 1002, 1003, 1005, 1006, 1007, 1010, 1011, 1012, 1013, 1014, 1015, 1016, 1017, 1018, 1019, 1020, 1021, 1022, 1023, 1024, 1025, 1026, 1027, 1028, 1029, 1030, 1031, 1032, 1033, 1034, 1037, 1038, 1039, 1040, 1041, 1042, 1043, 1044, 1045, 1046, 1047, 1048, 1049, 1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058,
' 4096, 4097,
' 5016, 5017, 5018, 5019, 5020, 5021,
' 30000, 32766, 32767, 32768, 32769, 32770, 32811, 32812, 32813,
' 65536
''
