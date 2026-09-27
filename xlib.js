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
//     A function whose name conforms to the specification gets:
//         External invocation.
//         Error handling.
//         Help information.
//         The functions list.
//
//     The annotation is the help text and must sit directly above the function; the parts of one
//     annotation are separated by [//]. Any other comment must use a single [//], and a function
//     that is called from the command line must be declared, not assigned. For example:
//         // [brief_introduction] //Usage: xlib [function_name] [OPTION]... [OPERAND]...
//             //  -o, --option=FILE   [description]
//         function [script_name_without_suffix]_[function_name](){
//             [function_body]
//             ...
//             setErr "[error_description]" // Exit and display [error_description].
//             setErr 1 // Return false status.
//         }
//
//     Example:
//         xlib.js                      Print the functions list.
//         xlib.js -h                   Print the functions list.
//         xlib.js [function_name] -h   Print the help of [function_name].
//         xlib.js [function_name]      Invoke [function_name].
//
//     The script runs under cscript.exe, which is part of Windows. Under wscript.exe the
//     output goes to message boxes instead of the console, and standard input is not available.

////////////////////////////////////////
/***************************************
*              Framework               *
***************************************/

// Throw the given error code or error message.
function setErr(desc){
    var err;
    // An empty description is not a status, and WScript.Quit cannot report it.
    if(typeof desc == "number" && !isNaN(desc) && desc > 0){
        err = new Error("Error Code: " + desc);
        err.number = desc;
    } else {
        err = new Error(desc);
        // 2 is the code VBScript uses for a custom error.
        err.number = 2;
        // The description reads better than the message prefix.
        err.description = desc;
    }
    // Mark the error as raised by this framework.
    err.iFrameErr = true;
    throw err;
}

// Return true when the script runs under cscript.exe.
function iCscript() {
    return "\\cscript.exe" == WScript.FullName.slice(-12).toLowerCase();
}

// Return this script name without its extension, for example xlib.
function gScriptName(){
    var sname = WScript.ScriptName;
    var i = sname.lastIndexOf('.');
    return i > 0 ? sname.substring(0, i) : sname;
}

// Print a line to stdout, or show a dialog under wscript.exe.
function printLine(desc){
    // A number is a common argument here, for example the hash of a string.
    desc = String(desc);
    if(iCscript()){
        // A leading byte order mark makes StdOut fail, for example when the text comes
        // from the clipboard; it has no meaning in a console stream.
        if("\uFEFF" == desc.charAt(0)) desc = desc.substring(1);
        WScript.StdOut.WriteLine(desc);
    } else {
        WScript.Echo(desc);
    }
}

// Print an error line to stderr, or show an error dialog.
function errLine(desc) {
    desc = String(desc);
    if(iCscript()){
        WScript.StdErr.WriteLine(desc);
    } else {
        WScript.Echo(desc);
    }
}

// A comment without the '// ' prefix marks a private function, which the framework does
// not list and cannot invoke from the command line; see gfuncAnno.

// BKDR hash function. Common BKDR seeds: 31, 131, 1313, 13131, 131313.
function BKDRHash(key) {
    var seed = 131, hash = 0;
    for (var i = 0; i < key.length; i++) {
        hash = hash * seed + key.charCodeAt(i);
        // The remainder keeps the accumulator inside the integer range, so that a long
        // string cannot lose its low digits.
        hash = hash % 2147483647;
    }
    return hash;
}

// Remove the surrounding whitespace.
function trim(str){
    return str.replace(/(^\s*)|(\s*$)/g,"");
}

// Print the lines of a string in sorted order.
// The lines are compared as text without case, as JScript compares the strings of an
// array by character code, which would put every capital letter first.
function sortPrint(str){
    printLine(str.split("\r\n").sort(function(a, b){
        a = a.toLowerCase();
        b = b.toLowerCase();
        return a < b ? -1 : (a > b ? 1 : 0);
    }).join("\r\n"));
}

// Left-pad a number with zeros to the requested width.
function gPad(value, width){
    var str = String(value);
    while(str.length < width) str = "0" + str;
    return str;
}

// Scan this script for a function annotation.
// A non-empty method returns the help of that function; an empty method returns the
// functions list, whose briefs are lined up in one column.
function gfuncAnno(method){
    var names = [], briefs = [], count = 0, width = 0;
    var prefix = gScriptName().toLowerCase() + "_";
    var target = prefix + method.toLowerCase();
    var annotation = "", line, decl, brief, name, i, j, match;
    var help = "";
    // The annotations are single-line comments, so the source text holds them.
    var text = new ActiveXObject("Scripting.FileSystemObject").OpenTextFile(WScript.ScriptFullName);
    while(!text.AtEndOfStream){
        // Remove the surrounding whitespace.
        line = trim(text.ReadLine());
        if("// " == line.substring(0, 3)){
            // Store the annotation line just read.
            annotation = trim(line.substring(3));
        } else if(match = line.match(/^function\s+([A-Za-z0-9_$]+)\s*\(/)){
            // Extract the declared name, for example xlib_sleep.
            decl = match[1].toLowerCase();

            // An empty method matches every function of this script.
            if(target == decl || ("" == method && decl.substring(0, prefix.length) == prefix)){
                if("" != method){
                    // Print every part of the annotation on its own line.
                    var parts = annotation.split("//");
                    for(i = 0; i < parts.length; i++){
                        brief = parts[i].replace(/\s+$/, "");
                        if(brief.length > 0){
                            if("" == help) brief = trim(brief);
                            help += brief + "\r\n";
                        }
                    }
                    text.Close();
                    return help.slice(0, -2);
                }
                // Keep only the brief, i.e. the text before the first separator.
                brief = trim(annotation.split("//")[0]);
                // Collect the name without the prefix and the brief for the list.
                name = match[1].substring(prefix.length);
                names[count] = name;
                briefs[count] = brief;
                if(name.length > width) width = name.length;
                count = count + 1;
            }
            // An annotation only describes the declaration directly below it.
            annotation = "";
        } else if(/^(var|function)\s/.test(line)){
            // Only a function declaration can be invoked from the command line.
            annotation = "";
        }
    }
    text.Close();

    // Build the functions list.
    for(i = 0; i < count; i++){
        brief = names[i];
        for(j = brief.length; j < width + 2; j++) brief += " ";
        help += brief + briefs[i] + "\r\n";
    }
    return "" == help ? "" : help.slice(0, -2);
}

// Return the literal of an argument, for example "value" or "va\"lue".
function gQuoted(str){
    return "\"" + String(str).replace(/([\\"])/g, "\\$1") + "\"";
}

// Cache the command-line arguments.
// The Windows Script Host is the only host the framework runs under; another host, such
// as node, has to bring its own WScript.Arguments before the framework is loaded.
var objArgs = "undefined" == typeof WScript ? [] : WScript.Arguments;

// Translate the HRESULT of a JScript condition into the error code VBScript reports, so
// that the status of the script does not change from one host to the other.
// 13: the property or the method does not exist; the called function is unknown.
// 1002: an operator or a method is not supported by the type of the value.
// 450: the arguments do not match the declaration of the function.
var errMap = {
    0x800A138F: 13,    // Object required.
    0x800A01B6: 13,    // Object doesn't support this property or method.
    0x800A01C2: 1002,  // Wrong number of arguments or invalid property assignment.
    0x800A01CA: 450    // Wrong number of arguments.
};

// The result of the invocation, so that main can report the status in one place.
var gExit = {code: 0, message: "", err: false};

// Print a message and leave main; the status is 0 when there is nothing to report.
function quit(code, message, err){
    gExit.code = code;
    gExit.message = message;
    gExit.err = (err === true);
    // Follow the call stack out of main. WScript.Quit does not stop the script when it
    // is called from inside a function and the status is 0, so it is only the last resort.
    throw gExit;
}

function main(){
    var funcName = "", MethoParas = "", arg, help, i, errNum, errDesc;
    var err = null;

    try {
        // Assemble the method name and its parameter list.
        // WScript.Arguments is a collection, not an array.
        for(i = 0; i < objArgs.length; i++){
            arg = objArgs(i);
            if(0 == i){
                // A help flag in the first position prints the functions list.
                if("-h" == arg || "--help" == arg || "-?" == arg){
                    i = -1;
                    break; // i stays -1, so the functions list is printed.
                }
                // Start the call expression, for example xlib_sleep(.
                MethoParas = gScriptName() + "_" + arg + "(";
                funcName = arg;
            } else if(1 == i){
                // A help flag in the second position prints one function help.
                if("-h" == arg || "--help" == arg){
                    help = gfuncAnno(funcName);
                    if("" == help) quit(13, "Error: No function found", true);
                    quit(0, help);
                }
                // Append the first argument, for example xlib_sleep("100".
                MethoParas = MethoParas + gQuoted(arg);
            } else {
                // Append further arguments, for example xlib_sleep("100","200".
                MethoParas = MethoParas + "," + gQuoted(arg);
            }
        }

        if(0 == objArgs.length || -1 == i){
            // Print the introduction list of all functions.
            help = gfuncAnno("");
            if("" != help) sortPrint(help);
            quit(0, "");
        }

        // Close the parameter list so that the call can be evaluated.
        MethoParas = MethoParas + ")";
        try {
            // Invoke the function with the assembled arguments.
            eval(MethoParas);
        } catch(e){
            err = e;
        }
        // No error.
        if(null == err) quit(0, "");

        errNum = err.number;
        errDesc = err.description || err.message;

        if(err.iFrameErr){
            if(1 == errNum){
                // setErr 1: return a false status to the caller after printing the help.
                quit(1, gfuncAnno(funcName));
            }
            // Custom error raised by setErr with a status.
            quit(errNum, "Error: " + errDesc + " (" + WScript.ScriptFullName
                + ":" + gScriptName() + "_" + funcName + ")", true);
        }

        // The framework reports an exit status the way VBScript does; JScript reports the
        // HRESULT of the condition instead, so the known conditions are translated.
        var vbErr = errMap[errNum >>> 0];
        if(null != vbErr){
            if(13 == vbErr) quit(13, "Error: No function found", true);
            if(450 == vbErr) quit(450, "Error: " + errDesc + " (" + WScript.ScriptFullName
                + ":" + gScriptName() + "_" + funcName + ")".concat("\r\n", gfuncAnno(funcName)), true);
            quit(vbErr, "Error: " + errDesc + " (" + WScript.ScriptFullName
                + ":" + gScriptName() + "_" + funcName + ")", true);
        }
        quit(2, "Error Code: " + (errNum >>> 0) + "\r\n" + errDesc + "\r\nargs: " + MethoParas, true);
    } catch(e){
        // Leave main on the status of quit.
        if(gExit !== e) throw e;
    }

    if("" != gExit.message){
        if(gExit.err) errLine(gExit.message);
        else printLine(gExit.message);
    }
    // Report the status to the caller. WScript.Quit stops the script here, as main is
    // the last call of the script.
    if(0 != gExit.code) WScript.Quit(gExit.code);
}

/***************************************
*              Framework               *
***************************************/
////////////////////////////////////////

////////////////////////////////////////
/***************************************
*              Functions               *
***************************************/

// Print version and exit. //Usage: xlib version
function xlib_version(){
    printLine("0.26.9.26");
}

// Sleep some milliseconds. //Usage: xlib sleep MS
function xlib_sleep(ms){
    // Ensure MS is numeric.
    if(isNaN(parseInt(ms, 10))) setErr("Args not a number");
    WScript.Sleep(parseInt(ms, 10));
}

// Print the BKDR hash of a string. //Usage: xlib hash STRING
function xlib_hash(key){
    printLine(BKDRHash(key));
}

// Print a new GUID. //Usage: xlib guuid
function xlib_guuid(){
    var guid = new ActiveXObject("Scriptlet.TypeLib").Guid;
    // The Guid property carries a trailing Chr(0), and the braced GUID is 38 characters.
    printLine(guid.substring(0, 38));
}

// Print the current date and time with hundredths of a second. //Usage: xlib gnow
function xlib_gnow(){
    var t = new Date();
    // yyyyMMddhhmmss plus hundredths of a second, for example 2017010112000099.
    var hundredths = Math.floor(t.getMilliseconds() / 10);
    printLine(gPad(t.getFullYear(), 4) + gPad(t.getMonth() + 1, 2) + gPad(t.getDate(), 2)
        + gPad(t.getHours(), 2) + gPad(t.getMinutes(), 2) + gPad(t.getSeconds(), 2)
        + gPad(hundredths, 2));
}

/***************************************
*              Functions               *
***************************************/
////////////////////////////////////////

// The framework needs the Windows Script Host, which the built-in cscript.exe and
// wscript.exe provide. A compatibility layer for another host, such as node, goes here.
if("undefined" != typeof WScript) main();
