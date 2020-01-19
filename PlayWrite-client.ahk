/*
    PlayWrite, copyright 2019 by Carsten Germer
    Version 20200117 Beta
    
    This program is free software. It comes without any warranty, to
    the extent permitted by applicable law. You can redistribute it
    and/or modify it under the terms of the Do What The Fuck You Want
    To Public License, Version 2, as published by Sam Hocevar.
    See http://www.wtfpl.net/ for more details.
     
     Restrictions pertaining Autohotkey may apply: https://www.autohotkey.com/docs/license.htm
*/

; Settings system stuff in AHK for this program
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#persistent ; For timers and such. https://www.autohotkey.com/docs/commands/_Persistent.htm
#SingleInstance Ignore ; Don't overwrite instance already running!

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory (namely _the_ dir).
SetTitleMatchMode 2 ; For WinActivate to match title on substring search
FileEncoding, UTF-8 ; This actually means the FILE HAS TO BE SAVED AS "UTF-8 with BOM"
SetKeyDelay , 150, 150 ; Relaxed key delays

; General settings
global com_Debug := False
global i18nArray := []
global iniPWTi18n := "i18n-PWT.ini"
global pwt_SystemLoc := "English"
global pwtc_Running := false
global pwtc_Stopping := false

; Settings for communication with the target system
global com_PreOut := i18n("com_PreOut", "System")
global com_Channel := i18n("com_Channel")
global com_PostOut := i18n("com_PostOut", "System")
global com_DefPauseEOL := % i18n("com_DefPauseEOL", "System") + 1 - 1 ; weird syntax for int(string) ...
global com_WinOutput := i18n("com_WinOutput")

; Settings for PlayWrites intersystems communication
global pwtc_ID := ""
global pwtc_Actor := ""
global pwt_Channel := i18n("pwt_Channel")
global pwt_FreeActors := []

; Settings for dealing with command-(log)file
global cfFilename := "logfile.txt"
global cfCurrentSize := 0
global cfLastSize := 0
global cfCurrentLineAmount := 0
global cfLastLineAmount := 0
global newFileLines := []
global cfLineClean := i18n("cfLineClean", "System")
global cfDirector := i18n("cfDirector", "System")
global cfFilePollTime := % i18n("cfFilePolltime", "System") + 1 - 1 ; weird syntax for int(string) ...

CheckAHK()

; explicitly check if already started to be able to clean stop and restart
if not (pwtc_Running)
{
	pwtc_Running := true
	Goto, StartPWTC
}
else
{
	pwtc_Stopping := true
	return
}

StartPWTC:

; (Re)Initialize some settings for current (re)start of play
global com_Channel := i18n("com_Channel")
global pwt_Channel := i18n("pwt_Channel")
global cfFilename := "logfile.txt"
global pwtc_Actor := ""
global pwtc_ID := ComObjCreate("Scriptlet.TypeLib").GUID ; generate ID for this run
; Remove possible harmfull characters
pwtc_ID := StrReplace(pwtc_ID, "{")
pwtc_ID := StrReplace(pwtc_ID, "}")
pwtc_ID := StrReplace(pwtc_ID, "-")

; GUI user choose command log file
FileSelectFile, cfFilename, 3, , Select chat log file with directors commands, chatlog (*.txt)
; check if log file is accessible
FileGetSize, logsizedummy, % cfFilename
if (ErrorLevel > 0)
{
	if (com_Debug)
		Debug.WriteNL("Couldn't open log file " . cfFilename . "<")
	MsgBox, % "Couldn't open log file: " . cfFilename . "<"
	pwt_Running := false
	pwt_Stopping := false
	ExitApp
}

; <GUI> Start of definitions and event code

Gui -MaximizeBox
Gui Add, Text, x16 y8 w180 h28 +0x200 +Right, This clients ID:
Gui Add, Text, x208 y8 w240 h28 +0x200, % pwtc_ID
Gui Add, Text, x16 y38 w180 h28 +0x200 +Right, Target system language:
Gui Add, Text, x16 y70 w180 h28 +0x200 +Right, Available actors:
Gui Add, Text, x16 y150 w180 h28 +0x200 +Right, My actor:
Gui Add, Text, x208 y150 w120 h28 +0x200 vSetActor, % pwtc_Actor
Gui Add, Text, x18 y185 w582 h2 +0x10
Gui Add, DropDownList, x208 y42 w218 vpwt_SystemLoc Sort gSetSysloc, % i18n("SysLocales", "System")
Gui Add, DropDownList, x208 y74 w218 vpwtc_Actor Sort, n/a
Gui Add, Button, x440 y70 w155 h28 gRequestActorRefresh vpwtcguiar, Request Refresh
Gui Add, Button, x176 y100 w266 h37 gRequestActorSet vpwtcguias, Request chosen actor to be set
Gui Add, Button, x32 y200 w265 h28 gPlayCancel, Cancel participation in this play
Gui Add, Button, x320 y200 w268 h28 gExitPWT, Exit PlayWrite
Gui Show, w620 h250, PlayWrite client controls

; jump over GUIs event labels
GOTO StartPollingLoop

GuiEscape:
Return

SetSysloc:
Gui, Submit, NoHide
com_Channel := i18n("com_Channel")
pwt_Channel := i18n("pwt_Channel")
com_WinOutput := i18n("com_WinOutput")
Return

RequestActorRefresh:
OutputToTargetWindow(pwt_Channel . pwtc_ID . ": actorsplz(" . pwtc_ID . ")")
; Gui, Show
Return

RequestActorSet:
Gui, Submit, NoHide
OutputToTargetWindow(pwt_Channel . pwtc_ID . ": plzactor(" . pwtc_ID . "," . pwtc_Actor . ")")
; Gui, Show
Return

PlayCancel:
MsgBox 0x34, CANCEL PLAY - You sure?, This cancels your participation in the play currently running!
IfMsgBox Yes, {
    pwtc_Stopping := true
    Return
} Else IfMsgBox No, {
    Return
}
Return ; Just in case the user finds a way to end the box wo choosing...

GuiClose:
ExitPWT:
MsgBox 0x34, EXIT PLAYWRITE - You sure?, This cancels your participation completely!
IfMsgBox Yes, {
    pwtc_Stopping := true
    ExitApp
} Else IfMsgBox No, {
    Return
}
Return ; Just in case the user finds a way to end the box wo choosing...

; </GUI> End of definitions and event code

StartPollingLoop:

if (com_Debug)
{
	Debug.WriteNL("--- Starting in " . A_WorkingDir)
	Debug.WriteNL("Machines ID: " . pwtc_ID . "<")
	Debug.WriteNL("Command log file: " . cfFilename . "<")
}

; initiate cfLastSize and cfLastLineAmount and start timer
FileGetSize, cfLastSize, % cfFilename
if (ErrorLevel > 0)
{
	if (com_Debug)
		Debug.WriteNL("Couldn't open file " . cfFilename)
	MsgBox, % "Couldn't open file: " . cfFilename . "<"
	pwt_Running := false
	pwt_Stopping := false
	return
}
FileRead, curFile, % cfFilename
StringReplace, OutputVar, curFile, `n, `n, useerrorlevel
cfLastLineAmount := ErrorLevel + 1
if (com_Debug)
{
	Debug.WriteNL("cf initial size: " . cfLastSize . "<")
	Debug.WriteNL("cf initial lines: " . cfLastLineAmount . "<")
}
setTimer, ParseCommandFile, % cfFilePollTime ; gets called into thread periodically
return


ParseCommandFile:

; pwtc_Stopping? End current run
if (pwtc_Stopping)
{
	pwtc_Stopping := false
    ; Resets for choosing anew
    pwtc_Actor := ""
    GuiControl, Enable, pwtc_Actor
    GuiControl, Enable, pwtcguiar
    GuiControl, Enable, pwtcguias
	if (com_Debug)
		Debug.WriteNL("- Current participation cancelled")
	return
}

; compare file size, don't go further if size didn't grow
FileGetSize, cfCurrentSize, % cfFilename
if not (cfCurrentSize > cfLastSize)
	return
cfLastSize := cfCurrentSize

; compare amount of lines, don't go further if amount didn't grow
FileRead, curFile, % cfFilename
StringReplace, OutputVar, curFile, `n, `n, useerrorlevel
cfCurrentLineAmount := ErrorLevel + 1
if not (cfCurrentLineAmount > cfLastLineAmount)
	return

if (com_Debug)
{
	Debug.WriteNL("cfCurrentSize: " . cfCurrentSize . "<")
	Debug.WriteNL("cfCurrentLineAmount: " . cfCurrentLineAmount . "<")
}

; fetch new lines to process
toread := (cfCurrentLineAmount - cfLastLineAmount)
newFileLines := FileTail(toread, cfFilename)
cfLastLineAmount := cfCurrentLineAmount

if (com_Debug)
	Debug.WriteNL("- processing new line(s) in commandfile")

; process new lines
Loop, % newFileLines.MaxIndex()
{
	if (com_Debug)
		Debug.WriteNL("> newFileLine " . A_Index . ": " . newFileLines[A_Index] . "<")
	
	curLine := newFileLines[A_Index]
	
	if (com_Debug)
		Debug.WriteNL("Processing newFileLines #" . A_Index . "<")
	
	; identify lines that are ment to be processed & cut target systems leading and trailing chars
	if not (cfLineClean = "")
	{
		if ( RegExMatch(curLine, cfLineClean, foundLineRaw) )
		{
			curLine := foundLineRaw1
			if (com_Debug)
				Debug.WriteNL("cfLineClean found:" . curLine . "<")
		}
		else
		{
			if (com_Debug)
				Debug.WriteNL("No cfLineClean in Line:" . curLine . "<")
			continue
		}
	}
	
	; ignore empty lines
	if (RegExMatch(curLine, "(*ANYCRLF)^\s*$"))
	{
		if (com_Debug)
			Debug.WriteNL("Found empty newFileLine: " . curLine . "<")
		continue
	}
	
	; trim line from stray whitespaces
	curLine := Trim(curLine)
	
	; verify the line is from director
	if ( RegExMatch(curLine, "(*ANYCRLF)^\s*" . i18n("cfDirector", "System") . ":\s*(.+)$", foundLineRaw) )
	{
		curline := foundLineRaw1
		; check if line is ment for this client or plain directors command, call respective processing
		if (RegExMatch(curLine, "(*ANYCRLF)^\s*" . pwtc_ID . ":\s*(.+)$", foundLineRaw))
		{
			curLine := foundLineRaw1
			curLine := Trim(curLine)
			if (com_Debug)
				Debug.WriteNL("Current line for Actor: " . curLine)
			; Call actor processing
			if ProcessActor(curLine)
			{
                OutputToTargetWindow(pwt_Channel . pwtc_ID . ": linedone")
				if (com_Debug)
					Debug.WriteNL(pwtc_ID . ": line done")
			}
			else
			{
				OutputToTargetWindow(pwt_Channel . pwtc_ID . ": line ERROR")
				if (com_Debug)
					Debug.WriteNL(pwtc_ID . ": line ERROR")
			}
		}
		else
		{
			if (com_Debug)
				Debug.WriteNL("Current line Director commands: " . curLine . "<")
			; Call director processing for general commands, infos and settings
			if not ProcessDirector(curLine)
			{
				OutputToTargetWindow(pwt_Channel . pwtc_ID . ": line ERROR")
				if (com_Debug)
					Debug.WriteNL(pwtc_ID . ": line ERROR")
			}
		}
	}
	else
	{
		if (com_Debug)
			Debug.WriteNL("Director not identified in newFileLines #" . A_Index . ". Ignoring.")
	}
}
if (com_Debug)
    Debug.WriteNL("- END processing new line(s) in commandfile")
return

ProcessDirector(curLine)
{
	; make globals accessible to this function
	global com_Debug, com_PreOut, com_PostOut, com_Channel, com_DefPauseEOL
    global pwt_FreeActors, pwtc_Stopping, pwtc_Actor, pwtc_ID, pwt_Channel
	
	; actorconfirmed(myid,actorname) <- I have asked to be actor x (plzactor(myid,actorname))
	if ( RegExMatch(curLine, "^#.*actorconfirmed\s*\((.+)\)", actorconfirm) )
	{
		if (com_Debug)
			Debug.WriteNL("DirectorMsg: Actor choice confirmed >" . actorconfirm1 . "<")
		actorconfirmparams := StrSplit(actorconfirm1, ",")
		if (actorconfirmparams[1] = pwtc_ID)
		{
			pwtc_Actor := actorconfirmparams[2]
			if (com_Debug)
				Debug.WriteNL("I am now actor >" . pwtc_Actor . "<")
			OutputToTargetWindow(pwt_Channel . pwtc_ID . ": isready(" . pwtc_ID . "," . pwtc_Actor . ")")
            ; Disable the GUI-controls for choosing actor
            GuiControl, Disable, pwtc_Actor
            GuiControl, Disable, pwtcguiar
            GuiControl, Disable, pwtcguias
            GuiControl,, SetActor, % pwtc_Actor
		}
	}
	
	; readycheck(myid) -> isready(myid,actorname)
	if ( RegExMatch(curLine, "^#.*readycheck\s*\(\s*" . pwtc_ID . "\s*\)") )
	{
		if (com_Debug)
			Debug.WriteNL("DirectorMsg: Ready >" . pwtc_ID . "<?")
		OutputToTargetWindow(pwt_Channel . pwtc_ID . ": isready(" . pwtc_ID . "," . pwtc_Actor . ")")
	}
	
	; readycheckall -> isready(myid,actorname)
	if ( RegExMatch(curLine, "^#.*readycheckall\s*") )
	{
		if (com_Debug)
			Debug.WriteNL("DirectorMsg: All ready check.")
		OutputToTargetWindow(pwt_Channel . pwtc_ID . ": isready(" . pwtc_ID . "," . pwtc_Actor . ")")
	}
	
	; actorsfree(list of untaken actors)
	if ( RegExMatch(curLine, "^#.*actorsfree\s*\((.+)\)", actorsfree) )
	{
		if (com_Debug)
			Debug.WriteNL("DirectorMsg: List of free actors >" . actorsfree1 . "<")
		pwt_FreeActors := StrSplit(actorsfree1, ",")
        ; Assembling the strings for the DropDowns with all found actors and defined languages
        DDLStr := "|"
        For Index, Value In pwt_FreeActors
            DDLStr .= Value . "|"
        DDLStr := RTrim(DDLStr, "|") ; remove the last pipe (|)
        GuiControl,, pwtc_Actor, % DDLStr

	}
	
	; playdone -> stop current run
	if ( RegExMatch(curLine, "^#\s*playdone\s*") )
	{
		if (com_Debug)
			Debug.WriteNL("DirectorMsg: Play done.")
		pwtc_Stopping := true
	}
	
	; pwt_Channel(channel_identifier)
	if ( RegExMatch(curLine, "^#.*pwt_Channel\s*\((.+)\)", pwtchannel) )
	{
		pwt_Channel := pwtchannel1
		if (com_Debug)
			Debug.WriteNL("DirectorMsg: New pwt_Channel >" . pwt_Channel . "<")
	}
	
	if ( RegExMatch(curLine, "^#.*com_PreOut\s*\((.+)\)", preout) )
	{
		com_PreOut := preout1
		if (com_Debug)
			Debug.WriteNL("DirectorMsg: New com_PreOut >" . com_PreOut . "<")
	}
	if ( RegExMatch(curLine, "^#.*com_PostOut\s*\((.+)\)", postout) )
	{
		com_PostOut := postout1
		if (com_Debug)
			Debug.WriteNL("DirectorMsg new com_PreOut >" . com_PostOut . "<")
	}
	if ( RegExMatch(curLine, "^#.*com_Channel\s*\((.+)\)", channel) )
	{
		com_Channel := Trim(channel1) . " "
		if (com_Debug)
			Debug.WriteNL("DirectorMsg new com_Channel >" . com_Channel . "<")
	}
	if ( RegExMatch(curLine, "^#.*com_DefPauseEOL\s*\((.+)\)", defpause) )
	{
		com_DefPauseEOL := defpause1
		if (com_Debug)
			Debug.WriteNL("DirectorMsg new com_DefPauseEOL >" . com_DefPauseEOL . "<")
	}
	; error states would be signaled in the branches of individual commands
	return true
}

; Include general functions used in both, server and client
#Include PlayWrite-toolfuncs.ahk
#Include debughelper.ahk
