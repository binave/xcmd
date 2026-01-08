//   Copyright 2017 bin jin
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
// Framework
//     If the function names conform to the specifications:
//         External call function.
//         Error handling.
//         Display help information.
//         Print the functions list.
//
//     e.g.
//         // [brief_introduction] //[description_1] //[description_2] ...
//         function [script_name_without_suffix]_[function_name](){
//             ...
//             [function_body]
//             //
//             setErr "[error_description]" // exit and display [error_description]
//             ...
//             setErr 1 // return false status
//         }

////////////////////////////////////////
/***************************************
*              Framework               *
***************************************/

// Make Error code Or Output error info
function setErr(desc){
    throw desc;
}

// Test script run with cscript.exe
function iCscript() {
    return "\\cscript.exe" == WScript.FullName.slice(-12);
}

// This script name, e.g. lib
function gScriptName(){
    var sname = WScript.ScriptName;
    return sname.substring(0, sname.lastIndexOf('.'));
}

// Print strng, like WScript.Echo
function printLine(desc){
    if(iCscript()){
        WScript.StdOut.WriteLine(desc);
    } else {
        WScript.Echo(desc);
    }
}

function errLine(desc) {
    if(iCscript()){
        WScript.StdErr.WriteLine(desc);
    } else {
        WScript.Echo(desc);
    }
}

function BKDRHash(key) {
    // 31 131 1313 13131 131313
    var seed = 131, hash = 0;
    for (i = 0; i < key.length; i++) {
        hash = hash * seed + key.charCodeAt(i);
    }
    return hash & 0xFFFFFFFE;
}

function trim(str){
    return str.replace(/(^\s*)|(\s*$)/g,"");
}

// Print sort string
function sortPrint(str){
    return str.split("\r\n").sort().join("\r\n");
}

// Search this script function
function gfuncAnno(method){
    var line, str;
    var text = new ActiveXObject("Scripting.FileSystemObject").OpenTextFile(WScript.ScriptFullName);
    while (text.AtEndOfStream){
        line = trim(text);
        str = line.toLowerCase();
    };
}

// eval("WScript.Echo(0)");

// Object
var objArgs = WScript.Arguments;

for (i = 0; i < objArgs.length; i++){
   WScript.Echo(objArgs(i));
}

var a = new Array();
a['test'] = 6;
for (var i in a) {
    WScript.Echo(a[i])
}


// var input = "";
// while (!WScript.StdIn.AtEndOfLine)
// {
//    input += WScript.StdIn.Read(1);
// }
// WScript.Echo(input);

/***************************************
*              Framework               *
***************************************/
////////////////////////////////////////
