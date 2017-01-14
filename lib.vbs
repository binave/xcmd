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
'     If the function names conform to the specifications:
'         External call function.
'         Error handling.
'         Display help information.
'         Print the functions list.
'
'     e.g.
'         ''' [brief_introduction] '[description_1] '[description_2] ...
'         Function [script_name_without_suffix]_[function_name]()
'             ...
'             [function_body]
'             '''
'             setErr "[error_description]" ' exit and display [error_description]
'             ...
'             setErr 1 ' return false status
'         End Function


''' Sleep some milliseconds 'Usage: lib sleep [ms]
Function lib_sleep(ms)
    ' Test ms
    If Not IsNumeric(ms) Then setErr "Args not a number"
    WScript.Sleep ms
End Function

''' Download and save 'Usage: lib get [url] [output_path]
Function lib_get(url, output)
    Set htt = gXmlHttp()
    htt.Open "GET", url, 0
    htt.Send
    Set str = CreateObject("ADODB.Stream")
    str.Type = 1
    str.Open
    str.Write htt.ResponseBody
    str.SaveToFile output, 2
End Function

''' Download and print as text 'Usage: lib getprint [url]
Function lib_getprint(url)
    Set htt = gXmlHttp()
    htt.Open "GET", url, 0
    htt.Send
    printLine htt.ResponseText
End Function

' REF http://demon.tw/programming/vbs-unzip-file.html
''' Create zip file 'Usage: lib zip [source_path] [zip_output_path]
Function lib_zip(sourcePath, zipPath)
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
End Function

' REF http://demon.tw/programming/vbs-unzip-file.html
''' Uncompress 'Usage: lib unzip [zip_path] [output_path]
Function lib_unZip(zipPath, targetPath)
    Dim shellApp, source, target
    If not fso.FolderExists(targetPath) Then
        fso.CreateFolder(targetPath)
    End If
    Set shellApp = CreateObject("Shell.Application")
    Set source = shellApp.NameSpace(zipPath).Items()
    Set target = shellApp.NameSpace(targetPath)
    target.CopyHere source, 256
End Function

''' Get clipboard data
Function lib_gClip()
    printLine gClip()
End Function

''' Set clipboard data 'Usage: lib sClip [String]
Function lib_sClip(base64Strng)
    Dim fso, logFile, logPath, wshShell
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set wshShell = CreateObject("WScript.Shell")
    If fso.FileExists(fso.GetSpecialFolder(0) & "\System32\clip.exe") Then
        ' use clip.exe
        logPath = fso.GetSpecialFolder(2) & "\" & guid & ".log"
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
End Function

''' Convert base64 to binary file from text 'Usage: lib txt2bin [text_path] [output_path]
Function lib_txt2bin(source, target)
    Dim content, text
    ' Read base64 text from file
    Set content = CreateObject("Scripting.FileSystemObject").opentextfile(source, 1)
    text = gBase64(content.readall)
    content.Close
    base64ToBin text, target
End Function

''' Convert binary file to base64 string 'Usage: lib bin2Base64 [file_path]
Function lib_bin2Base64(source)
    printLine bin2Base64(source)
End Function

''' Get guid
Function lib_guuid()
    lib_guuid = Left(CreateObject("Scriptlet.TypeLib").Guid, 38)
    printLine lib_guuid
End Function

''' Get format time
Function lib_gnow()
    Dim regEx
    Set regEx = New RegExp
    regEx.Pattern = "[\D]"
    regEx.Global = True
    lib_gnow = regEx.Replace(Now & right(FormatNumber(timer * 100, 0), 2), "")
    printLine lib_gnow
End Function

''' Convert ansi head to unicode head, or reconvert 'Usage: lib ansi2unic
Function lib_ansi2unic(path)
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
        bin.Text = mid(bin.Text, 17, len(bin.Text))
    Else
        bin.Text = "fffe2026636c7326" & bin.Text
    End If
    stream.Open
    stream.Write bin.NodeTypedValue
    stream.saveToFile path, 2
    stream.Close
End Function

''' Trim *.inf text for drivers 'Usage: lib inftrim [source_path] [target_path]
Function lib_inftrim(source, target)
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set fIn = fso.opentextfile(source)
    text = fIn.readall
    fIn.close
    text = replace(text, chr(9), "")
    text = replace(text, chr(32), "")
    ' for i = 1 to 10
    '     text = replace(text, chr(32) & chr(32), chr(32))
    ' next
    ' {59 ;} {44 ,}
    text = replace(text, chr(59), vbNewLine)
    text = replace(text, chr(44), vbNewLine)
    ' text = replace(text, chr(32) & vbNewLine, chr(13))
    ' create new text file
    Set fOut = fso.CreateTextFile(target, true)
    fOut.writeline text
    fOut.close
End Function

''' XML trans form Node by XSL 'Usage: lib doxsl [xml_path] [xsl_path] [output_path]
Function lib_doxsl(xml, xsl, output)
    Dim ver
    ' ver = 6 '
    ver = 3 ' support NT52
    Set xmlObj = CreateObject("MSXML2.DOMDocument." & ver & ".0")
    xmlObj.async = False
    xmlObj.validateOnParse = False
    xmlObj.load xml

    Set xslObj = CreateObject("MSXML2.DOMDocument." & ver & ".0")
    xslObj.async = False
    xslObj.validateOnParse = False
    xslObj.load xsl

    Set fso = CreateObject("Scripting.FileSystemObject").createTextFile(output, True)
    fso.Write(xmlObj.transformNode(xslObj))
    fso.Close()
End Function

''' Get target file system drive Letter 'Usage: lib gfsd [NTFS/FAT32/EXFAT]
Function lib_gfsd(tag)
    Dim drv
    For Each drv in CreateObject("Scripting.FileSystemObject").Drives
        If drv.IsReady Then
            If "tag" = drv.FileSystem Then
                printLine drv.DriveLetter & chr(58)
            End If
        End If
    Next
End Function

''''''''''''''''
'   Template   '
''''''''''''''''

Function lib_unattend(tag, ix86)
    Dim xml, bit, n
    n = vbNewLine
    bit = "amd64"
    If ix86 Then bit = "x86"

    xml = "<?xml version=""1.0"" encoding=""utf-8""?>" _
        & n & "<unattend xmlns=""urn:schemas-microsoft-com:unattend"" xmlns:wcm=""http://schemas.microsoft.com/WMIConfig/2002/State"">"

    Select Case tag
        Case 1
            Dim lang
            lang = "zh-CN"
            ' Administrator zh-CN amd64
            xml = xml _
            & n & "    <settings pass=""oobeSystem"">" _
            & n & "        <component name=""Microsoft-Windows-International-Core"" processorArchitecture=""" & bit & """ publicKeyToken=""31bf3856ad364e35"" language=""neutral"" versionScope=""nonSxS"">" _
            & n & "            <InputLocale>" & lang & "</InputLocale>" _
            & n & "            <SystemLocale>" & lang & "</SystemLocale>" _
            & n & "            <UILanguage>" & lang & "</UILanguage>" _
            & n & "            <UILanguageFallback>" & lang & "</UILanguageFallback>" _
            & n & "            <UserLocale>" & lang & "</UserLocale>" _
            & n & "        </component>" _
            & n & "        <component name=""Microsoft-Windows-Shell-Setup"" processorArchitecture=""" & bit & """ publicKeyToken=""31bf3856ad364e35"" language=""neutral"" versionScope=""nonSxS"">" _
            & n & "            <AutoLogon>" _
            & n & "                <Enabled>true</Enabled>" _
            & n & "                <LogonCount>1</LogonCount>" _
            & n & "                <Username>Administrator</Username>" _
            & n & "            </AutoLogon>" _
            & n & "            <OOBE>" _
            & n & "                <SkipMachineOOBE>true</SkipMachineOOBE>" _
            & n & "            </OOBE>" _
            & n & "            <TimeZone>China Standard Time</TimeZone>" _
            & n & "        </component>" _
            & n & "    </settings>"

        Case 2
            ' User amd64
            Dim user
            user = "User"
            xml = xml _
            & n & "    <settings pass=""oobeSystem"">" _
            & n & "        <component name=""Microsoft-Windows-Shell-Setup"" processorArchitecture=""" & bit & """ publicKeyToken=""31bf3856ad364e35"" language=""neutral"" versionScope=""nonSxS"">" _
            & n & "            <AutoLogon>" _
            & n & "                <Enabled>true</Enabled>" _
            & n & "                <LogonCount>1</LogonCount>" _
            & n & "                <Username>" & user & "</Username>" _
            & n & "            </AutoLogon>" _
            & n & "            <OOBE>" _
            & n & "                <SkipMachineOOBE>true</SkipMachineOOBE>" _
            & n & "            </OOBE>" _
            & n & "            <UserAccounts>" _
            & n & "                <LocalAccounts>" _
            & n & "                    <LocalAccount wcm:action=""add"">" _
            & n & "                        <Password>" _
            & n & "                            <Value></Value>" _
            & n & "                            <PlainText>true</PlainText>" _
            & n & "                        </Password>" _
            & n & "                        <Group>administrators;" & user & "</Group>" _
            & n & "                        <Name>" & user & "</Name>" _
            & n & "                    </LocalAccount>" _
            & n & "                </LocalAccounts>" _
            & n & "            </UserAccounts>" _
            & n & "        </component>" _
            & n & "    </settings>"

        Case 3
            ' Audit amd64
            xml = xml _
            & n & "    <settings pass=""oobeSystem"">" _
            & n & "        <component name=""Microsoft-Windows-Deployment"" processorArchitecture=""" & bit & """ publicKeyToken=""31bf3856ad364e35"" language=""neutral"" versionScope=""nonSxS"" xmlns:wcm=""http://schemas.microsoft.com/WMIConfig/2002/State"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"">" _
            & n & "            <Reseal>" _
            & n & "                <Mode>Audit</Mode>" _
            & n & "            </Reseal>" _
            & n & "        </component>" _
            & n & "    </settings>"

        Case 4
            ' Administrator amd64
            xml = xml _
            & n & "    <settings pass=""oobeSystem"">" _
            & n & "        <component name=""Microsoft-Windows-Shell-Setup"" processorArchitecture=""" & bit & """ publicKeyToken=""31bf3856ad364e35"" language=""neutral"" versionScope=""nonSxS"">" _
            & n & "            <AutoLogon>" _
            & n & "                <Enabled>true</Enabled>" _
            & n & "                <LogonCount>1</LogonCount>" _
            & n & "                <Username>Administrator</Username>" _
            & n & "            </AutoLogon>" _
            & n & "            <OOBE>" _
            & n & "                <SkipMachineOOBE>true</SkipMachineOOBE>" _
            & n & "            </OOBE>" _
            & n & "        </component>" _
            & n & "    </settings>"

        Case 5
            ' Nano server Administrator amd64
            xml = xml _
            & n & "    <settings pass=""offlineServicing"">" _
            & n & "        <component name=""Microsoft-Windows-Shell-Setup"" processorArchitecture=""" & bit & """ publicKeyToken=""31bf3856ad364e35"" language=""neutral"" versionScope=""nonSxS"">" _
            & n & "            <OfflineUserAccounts>" _
            & n & "                <OfflineAdministratorPassword>" _
            & n & "                    <Value>" & AdministratorPassword & "</Value>" _
            & n & "                    <PlainText>false</PlainText>" _
            & n & "                </OfflineAdministratorPassword>" _
            & n & "            </OfflineUserAccounts>" _
            & n & "            <ComputerName>" & ComputerName & "</ComputerName>" _
            & n & "        </component>" _
            & n & "    </settings>"

        Case Else
            setErr "Unknown tag"

    End Select

    printLine xml & n & "</unattend>"

End Function


Function lib_print(tag, ext)
    Dim strng, n
    n = vbNewLine

    Select Case tag
        Case 1
            ' For mbsacli
            strng = _
                  "<xsl:transform version=""1.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"">" _
            & n & "    <xsl:output method=""text""/>" _
            & n & "    <xsl:template match=""/"">" _
            & n & "        <xsl:for-each select=""//References"">" _
            & n & "            <xsl:sort select=""DownloadURL""/>"

            If Len(ext) Then
                strng = strng _
                & n & "            <xsl:if test=""not(contains(DownloadURL, '" & ext & "'))"">" _
                & n & "                <xsl:value-of select=""DownloadURL""/><xsl:text>&#10;</xsl:text>" _
                & n & "            </xsl:if>"
            End If

            strng = strng _
            & n & "        </xsl:for-each>" _
            & n & "    </xsl:template>" _
            & n & "</xsl:transform>"

        Case 2
            ' hisecws.inf for windows server
            strng = _
                  "[Unicode]" _
            & n & "Unicode=yes" _
            & n & "[System Access]" _
            & n & "MaximumPasswordAge = -1" _
            & n & "PasswordComplexity = 0" _
            & n & "[Registry Values]" _
            & n & "MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableCAD=4,1" _
            & n & "MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDriveTypeAutoRun=4,255" _
            & n & "MACHINE\Software\Policies\Microsoft\Windows NT\Reliability\**del.ShutdownReasonUI=1,""""" _
            & n & "MACHINE\Software\Policies\Microsoft\Windows NT\Reliability\ShutdownReasonOn=4,0" _
            & n & "User\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoThumbnailCache=4,1" _
            & n & "User\Software\Policies\Microsoft\Windows\Explorer\DisableThumbsDBOnNetworkFolders=4,1" _
            & n & "[Version]" _
            & n & "signature=""$CHICAGO$""" _
            & n & "Revision=1"

        Case 3

            ' Can not use ""do @start cmd.exe /c"", exec only first line of %USERPROFILE%\.onstart file"
            ' \Windows\System32\config\systemprofile"
            strng = _
                  "<?xml version=""1.0"" encoding=""UTF-16""?>" _
            & n & "<Task version=""1.3"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">" _
            & n & "    <Triggers>" _
            & n & "        <BootTrigger>" _
            & n & "            <Enabled>true</Enabled>" _
            & n & "        </BootTrigger>" _
            & n & "    </Triggers>" _
            & n & "    <Principals>" _
            & n & "        <Principal id=""Author"">" _
            & n & "            <UserId>S-1-5-18</UserId>" _
            & n & "            <RunLevel>HighestAvailable</RunLevel>" _
            & n & "        </Principal>" _
            & n & "    </Principals>" _
            & n & "    <Settings>" _
            & n & "        <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>" _
            & n & "        <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>" _
            & n & "        <Priority>5</Priority>" _
            & n & "    </Settings>" _
            & n & "    <Actions Context=""Author"">" _
            & n & "        <Exec>" _
            & n & "            <Command>cmd.exe</Command>" _
            & n & "            <Arguments>/c for /f ""usebackq delims="" %a in (""%USERPROFILE%\.onstart"") do @cmd.exe /c %a &gt;&gt;\Windows\Logs\onstart.log 2&gt;&amp;1</Arguments>" _
            & n & "            <WorkingDirectory>%USERPROFILE%</WorkingDirectory>" _
            & n & "        </Exec>" _
            & n & "    </Actions>" _
            & n & "</Task>"

        Case 4
            Dim lic
            lic = ""
            ' OEM license
            strng = _
                  "<?xml version=""1.0"" encoding=""utf-8""?>" _
            & n & "<r:license xmlns:r=""urn:mpeg:mpeg21:2003:01-REL-R-NS""" _
            & n & "           licenseId=""{" & lic & "}""" _
            & n & "           xmlns:sx=""urn:mpeg:mpeg21:2003:01-REL-SX-NS"" xmlns:mx=""urn:mpeg:mpeg21:2003:01-REL-MX-NS""" _
            & n & "           xmlns:sl=""http://www.microsoft.com/DRM/XrML2/SL/v2"" xmlns:tm=""http://www.microsoft.com/DRM/XrML2/TM/v2"">" _
            & n & "    <r:title>OEM Certificate</r:title>" _
            & n & "    <r:grant>" _
            & n & "        <sl:binding>" _
            & n & "            <sl:data Algorithm=""msft:rm/algorithm/bios/4.0"">kgAAAAAAAgB" & lic & "BAAEA" & lic & "=</sl:data>" _
            & n & "        </sl:binding>" _
            & n & "        <r:possessProperty/>" _
            & n & "        <sx:propertyUri definition=""trustedOem""/>" _
            & n & "    </r:grant>" _
            & n & "    <r:issuer>" _
            & n & "        <Signature xmlns=""http://www.w3.org/2000/09/xmldsig#"">" _
            & n & "            <SignedInfo>" _
            & n & "                <CanonicalizationMethod Algorithm=""http://www.microsoft.com/xrml/lwc14n""/>" _
            & n & "                <SignatureMethod Algorithm=""http://www.w3.org/2000/09/xmldsig#rsa-sha1""/>" _
            & n & "                <Reference>" _
            & n & "                    <Transforms>" _
            & n & "                        <Transform Algorithm=""urn:mpeg:mpeg21:2003:01-REL-R-NS:licenseTransform""/>" _
            & n & "                        <Transform Algorithm=""http://www.microsoft.com/xrml/lwc14n""/>" _
            & n & "                    </Transforms>" _
            & n & "                    <DigestMethod Algorithm=""http://www.w3.org/2000/09/xmldsig#sha1""/>" _
            & n & "                    <DigestValue>" & lic & "=</DigestValue>" _
            & n & "                </Reference>" _
            & n & "            </SignedInfo>" _
            & n & "            <SignatureValue>" & lic & "==</SignatureValue>" _
            & n & "            <KeyInfo>" _
            & n & "                <KeyValue>" _
            & n & "                    <RSAKeyValue>" _
            & n & "                        <Modulus>" _
            & n & "                            sotZn+w9juKPf7bMO9rNFriB+10v/t9bo/XWG+rzoDbw/uF4INZ5rGRIitiITY/bI4rANkv4Z5hG/8VxGMbqvqcaXJqnRFda7XAjgm1z9wkgX1R/d2tXLUUUQP0J1XuSbgzR89T/lpnc5q2Cdvy7Gv2pZvAzSeLOponXc8J3zOFr0IUXBGprXKnemVk1iJBFnyQGlWG3UoSpdlF0ichBQwPx/PgoTbcZsA7Gg62BGwPx/uDA3ZgwowrPlRwfLVAO6qE9xPJqRZdRFfPHbdQjp1YAq27wc6cTz5sPSTB1pJ4L9MD+NpvHj2OMZV5+LJ+bxZbTqhPcrzCp7ckkyD7Hzw==" _
            & n & "                        </Modulus>" _
            & n & "                        <Exponent>AQAB</Exponent>" _
            & n & "                    </RSAKeyValue>" _
            & n & "                </KeyValue>" _
            & n & "            </KeyInfo>" _
            & n & "        </Signature>" _
            & n & "        <r:details>" _
            & n & "            <r:timeOfIssue>200" & lic & "Z</r:timeOfIssue>" _
            & n & "        </r:details>" _
            & n & "    </r:issuer>" _
            & n & "    <r:otherInfo xmlns:r=""urn:mpeg:mpeg21:2003:01-REL-R-NS"">" _
            & n & "        <tm:infoTables xmlns:tm=""http://www.microsoft.com/DRM/XrML2/TM/v2"">" _
            & n & "            <tm:infoList tag=""#global"">" _
            & n & "                <tm:infoStr name=""applicationId"">{55c92734-d682-4d71-983e-d6ec3f16059f}</tm:infoStr>" _
            & n & "                <tm:infoStr name=""licenseCategory"">msft:sl/PPD</tm:infoStr>" _
            & n & "                <tm:infoStr name=""licenseType"">msft:sl/OEMCERT</tm:infoStr>" _
            & n & "                <tm:infoStr name=""licenseVersion"">2.0</tm:infoStr>" _
            & n & "                <tm:infoStr name=""licensorUrl"">http://licensing.microsoft.com</tm:infoStr>" _
            & n & "            </tm:infoList>" _
            & n & "        </tm:infoTables>" _
            & n & "    </r:otherInfo>" _
            & n & "</r:license>"

        Case Else
            setErr "Unknown tag"
    End Select

    printLine strng
End Function


''''''''''''''''''''''''
'   private function   '
''''''''''''''''''''''''

' Get HttpGet Object
Function gXmlHttp()
    ' To prevent antivirus false positives
    Set gXmlHttp = CreateObject("Microsoft" & Chr(46) & "XML" & "HT" & Chr(84) & "P")
End Function

' BKDRHash
''' BKDR Hash 'Usage: lib hash [strng]
Function lib_hash(key)
    Dim seed, hash, i
    seed = 131 ' 31 131 1313 13131 131313
    hash = 0
    For i = 1 To len(key)
        hash = hash * seed + Asc(Mid(key, i, 1))
    Next
    printLine hash Mod &H7FFFFFFF
End Function

' Get clip
Function gClip()
    Dim ieApp
    ' htmlfile, xmlfile, mhtmlfile
    gClip = CreateObject("htmlfile").parentWindow.clipboardData.getData("text")
    If len(gClip) = 0 Then
        gClip = GetObject("\", "htmlfile").parentWindow.clipboardData.getData("text")
        If len(gClip) = 0 Then
            Set ieApp = CreateObject("InternetExplorer.Application")
            ieApp.navigate "about:blank"
            ieApp.visible = False
            gClip = ieApp.document.parentwindow.clipboarddata.getdata("text")
        End If
    End If
End Function

' Format line to 64 column
Function to64Column(strng)
    Dim regEx
    Set regEx = New RegExp
    regEx.Pattern = "(.{64})"
    regEx.Global = True
    to64Column = regEx.Replace(Replace(strng, chr(10), ""), "$1" & chr(10)) & chr(10) & chr(10)
End Function

'Test text is base64 'for built-in function
Function iBase64(Strng)
    Dim regEx
    Set regEx = New RegExp
    regEx.Global = True
    regEx.Pattern = "^([0-9a-zA-Z/+]{64}\r?\n)+([0-9a-zA-Z/+]{1,63}[=]{0,3})?"
    iBase64 = regEx.Test(strng)
    Set regEx = Nothing
End Function

' Get base64 text from source text 'for built-in function
Function gBase64(Strng)
    Dim Matches, regEx
    Set regEx = New RegExp
    regEx.Pattern = "([0-9a-zA-Z/+]{64}\r?\n)+([0-9a-zA-Z/+]{1,63}[=]{0,3})?"
    Set Matches = regEx.Execute(Strng)
    If Matches.Count > 0 Then
        gBase64 = Matches(0)
    Else
        gBase64 = ""
    End If
End Function

' Convert binary file to base64 string
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

' Convert base64 string to binary file
Sub base64ToBin(base64Strng, path)
    Dim bin, stream
    Set bin = CreateObject("Microsoft.XMLDOM").CreateElement("binary")
    bin.DataType = "bin.base64"
    bin.Text = base64Strng
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 1
    stream.Open
    stream.Write bin.NodeTypedValue
    stream.saveToFile path, 2
    stream.Close
End Sub

' Run other vbscript
Sub vbs(path)
    Execute(CreateObject("Scripting.FileSystemObject").OpenTextFile(path).ReadAll)
End Sub

' Test file head 'Hex or Base64
Function gType(source)
    If "fffe2026636c7326" = (mid(source, 1, 16)) Then ' Unicode [Hex]
        gType = 1
    ElseIf "UEsDB" = (mid(source, 1, 5)) Then ' zip UEsDBBQAAAAIA [Base64]
        gType = 2
    ElseIf "H4sIA" = (mid(source, 1, 5)) Then ' Gz [Base64]
        gType = 3
    ElseIf "QlpoO" = (mid(source, 1, 5)) Then ' Bz2 QlpoOTFBWSZTW [Base64]
        gType = 4
    ElseIf "4d5a" = (mid(source, 1, 4)) Then ' dos exec [Hex]
        gType = 5
    ElseIf "7f45" = (mid(source, 1, 4)) Then ' unix exec [Hex]
        gType = 6
    Else
        gType = 0
    End If
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

' Make Error code Or Output error info
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

' Test script run with cscript.exe
Function iCscript()
    If "\cscript.exe" = LCase(Right(WScript.FullName, 12)) Then
        iCscript = True
    Else
        iCscript = False
    End If
End Function

' Print strng, like WScript.Echo
Sub printLine(desc)
    If iCscript() Then
        WScript.StdOut.WriteLine desc
    Else
        MsgBox desc
    End If
End Sub

' Print strng
Sub errLine(desc)
    If iCscript() Then
        WScript.StdErr.WriteLine desc
    Else
        MsgBox desc, 48, "Error"
    End If
End Sub

' This script name
Function gScriptName()
    gScriptName = Mid(WScript.ScriptName, 1, InStrRev(WScript.ScriptName, Chr(46)) - 1)
End Function

' Print sort string
' System.Collections.ArrayList not support at Windows PE
Sub sortPrint(str)
    Dim arr
    arr = Split(str, vbNewLine)
    quickSort arr, Lbound(arr), Ubound(arr)
    printLine Join(arr, vbNewLine)
End Sub

' Quick sort
' REF http://www.cnblogs.com/falconshh/archive/2011/05/30/2063204.html
Sub quickSort(arr, low, high)
    Dim pivotPos
    If low < high Then
        pivotPos = partition(arr, low, high)
        quickSort arr, low, pivotPos - 1
        quickSort arr, pivotPos + 1, high
    End if
End Sub

' For quickSort sub
' REF http://www.cnblogs.com/falconshh/archive/2011/05/30/2063204.html
Function partition(arr, low, high)
    Dim i, j, pivot
    i = low
    j = high
    pivot = arr(low)
    While i < j
        While i < j And arr(j) >= pivot
            j = j - 1
        Wend
        arr(i) = arr(j)
        While i < j And arr(i) <= pivot
            i = i + 1
        Wend
        arr(j) = arr(i)
    Wend
    arr(i) = pivot
    partition = i
End Function

' Search this script function
Function gfuncAnno(method)
    Dim annotation, text, str, line, prefix, i
    prefix = gScriptName()
    ' This script body annotation
    Set text = CreateObject("Scripting.FileSystemObject").OpenTextFile(WScript.ScriptFullName)
    Do Until text.AtEndOfStream
        ' Trim line
        line = Trim(text.ReadLine)
        str = LCase(line)
        ' If case function name
        If "function " & prefix & Chr(95) & method = Mid(str, 1, Len(method) + 13) Then

            If Len(annotation) > 1 Then
                ' Get single function info
                If Len(method) > 0 Then
                    ' Get annotation replace ' to \n
                    For Each i In Split(annotation, Chr(39))
                        gfuncAnno = gfuncAnno & i & vbNewLine
                    Next
                    Exit Do
                End If
                ' Get first annotation split by '
                i = InStr(annotation, Chr(39)) - 2
                If i > 0 Then annotation = Left(annotation, i)
            End If

            ' Get function name
            str = Trim(Mid(str, 14, InStr(str, Chr(40)) - 14))
            ' Align annotation
            gfuncAnno = gfuncAnno & str & Space(15 - Len(str)) & annotation & vbNewLine
            ' Clear annotation
            annotation = ""
        ElseIf Chr(39) & Chr(39) & Chr(39) & Chr(32) = Mid(str, 1, 4) Then
            ' Get all annotations
            annotation = Trim(Mid(line, 4))
        End If
    Loop
    text.Close
End Function

' Replace $@ to StdIn.ReadAll
Function rArg(i)
    rArg = args(i)
    If "$@" = rArg Then
        rArg = "WScript.StdIn.ReadAll"
    Else
        rArg = "args(" & i & ")"
    End If
End Function

' Test help
Function iHelp(i)
    Dim str
    str = LCase(args(i))
    If 0 = args.Count Then
        iHelp = True
        Exit Function
    ElseIf "-h" = str Or "--help" = str Then
        iHelp = True
    Else
        iHelp = False
    End If
End Function

Sub main()
    Dim arg, MethoParas, funcName, ScriptName, i
    ScriptName = gScriptName()

    ' ' Cache arguments
    ' Set args = WScript.Arguments
    ' ' Cache arguments count
    ' count = args.Count
    ' ' From secend arguments
    ' For i = 1 To count

    ' Next

    i = 0
    ' Assembling method name and parameter list
    ' WScript.Arguments not array
    For Each arg In WScript.Arguments
        i = i + 1
        If i = 1 Then
            ' Info list
            If LCase(arg) = "-h" Or Lcase(arg) = "--help" Then
                i = 0
                Exit For ' Will print all function introduction
            End If
            ' e.g. lib_func(
            MethoParas = ScriptName & Chr(95) & arg & Chr(40)
            funcName = arg
        ElseIf i = 2 Then
            ' Info single
            If LCase(arg) = "-h" Or Lcase(arg) = "--help" Then
                ' Print target function annotation
                printLine gfuncAnno(funcName)
                i = -1
                Exit For
            End If
            ' e.g. lib_func("arg1"
            MethoParas = MethoParas & Chr(34) & arg & Chr(34)
        Else
            ' e.g. lib_func("arg1","arg2"
            MethoParas = MethoParas & Chr(44) & Chr(34) & arg & Chr(34)
        End If
    Next

    if i > 0 Then
        ' e.g. lib_func(...)
        If Len(MethoParas) > 0 Then MethoParas = MethoParas & Chr(41)
        On Error Resume Next
        ' Run Function by Arguments
        eval MethoParas
        ' Catch Error
    ElseIf i = 0 Then
        arg = gfuncAnno("")
        ' Print all function introduction
        sortPrint Left(arg, Len(arg) - Len(vbNewLine))
    End If

    Select Case Err.Number
        Case 0
            ' Boolean: True
            WScript.Quit(0)
        Case 1
            ' setErr 1: return False to caller
            Err.Clear
            WScript.Quit(1)
        Case 2
            ' Custom error
            errLine "Error: " & Err.Description & Chr(32) _
            & Chr(40) & WScript.ScriptFullName & Chr(58) & ScriptName & Chr(95) & funcName & Chr(41)
        Case 13
            errLine "Error: No function found"
        Case 450
            errLine "Error: " & Err.Description
        Case Else
            errLine "Error Code: " & Err.Number & vbNewLine _
            & Err.Description & vbNewLine & "args: " & MethoParas
    End Select
    WScript.Quit(Err.Number)
    ' On Error GoTo 0
End Sub

' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '
'                    Framework                    '
'''''''''''''''''''''''''''''''''''''''''''''''''''

main()

'' Err number in use
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

