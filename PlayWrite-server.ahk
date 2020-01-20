/*
    PlayWrite, copyright 2019 by Carsten Germer
    Version 20200120 Beta
    
    This program is free software. It comes without any warranty, to
    the extent permitted by applicable law. You can redistribute it
    and/or modify it under the terms of the Do What The Fuck You Want
    To Public License, Version 2, as published by Sam Hocevar.
    See http://www.wtfpl.net/ for more details.
     
     Restrictions pertaining Autohotkey may apply: https://www.autohotkey.com/docs/license.htm
*/

/*
TODOs
    - enhance: Rework GUI to be purrty *lol*
    - refactor: global variables into global data-object(s) if sensible
    - refactor: rewrite, unify and clean up complete command-param handling in .pwt & to and from chat-sys
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
global pwts_Running := False
global pwts_WaitingLinedone := ""

; Settings for communication with the target system
global com_PreOut := i18n("com_PreOut", "System")
global com_Channel := i18n("com_Channel")
global com_PostOut := i18n("com_PostOut", "System")
global com_DefPauseEOL := % i18n("com_DefPauseEOL", "System") + 1 - 1 ; weird syntax for int(string) ...
global com_WinOutput := i18n("com_WinOutput")

; Settings for PlayWrites intersystems communication
global pwt_Channel := i18n("pwt_Channel")
global pwt_Comment := i18n("pwt_Comment", "System")
global pwt_Filename := "test.pwt"
global pwt_FreeActors := ""
global pwts_Actor := ""
global pwt_Actors := []
global pwt_LinesInScript := 0
global pwt_CurrentLine := 1
global lv_currClient := ""
global lv_currActor := ""
global lv_RowNumber := 0

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

if (com_Debug)
	Debug.WriteNL("Starting in " . A_WorkingDir)

; GUI user choose command log file
FileSelectFile, cfFilename, 3, , Select chat log file with clients replies, chatlog (*.txt)
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

; GUI user choose PlayWrite file
FileSelectFile, pwt_filename, 3, , Select PlayWrite play file, PlayWrite (*.pwt)
; Reading the file to array
FileRead, Filecont, %pwt_filename%
if (ErrorLevel > 0)
{
	if (com_Debug)
		Debug.WriteNL("Couldn't open file " . pwt_Filename)
	pwt_Running := false
	pwt_Stopping := false
	ExitApp
}
if (com_Debug)
	Debug.WriteNL("File " . pwt_Filename . " read")

; Split on new line into pwt_Script
pwt_Script := StrSplit(Filecont, "`n")

; Looping through the play extracting all actors and other parameters that may be present
Loop, % pwt_Script.MaxIndex()
{
	if ( RegExMatch(pwt_Script[A_Index], "^(\w+)\s*:", playactor) )
	{
		if not (ArrayContains(pwt_Actors, playactor1))
		{
			pwt_Actors.Push(playactor1)			
		}
	}
	if ( RegExMatch(pwt_Script[A_Index], "^#.*com_PreOut\s*\((.+)\)", playpreout) )
	{
		com_PreOut := playpreout1
		if (com_Debug)
			Debug.WriteNL("Found new com_PreOut >" . com_PreOut . "<")
	}
	if ( RegExMatch(pwt_Script[A_Index], "^#.*com_PostOut\s*\((.+)\)", playpostout) )
	{
		com_PostOut := playpostout1
		if (com_Debug)
			Debug.WriteNL("Found new com_PostOut >" . com_PostOut . "<")
	}
	if ( RegExMatch(pwt_Script[A_Index], "^#.*com_Channel\s*\((.+)\)", playchannel) )
	{
		com_Channel := Trim(playchannel1) . " "
		if (com_Debug)
			Debug.WriteNL("Found new com_Channel >" . com_Channel . "<")
	}
	if ( RegExMatch(pwt_Script[A_Index], "^#.*com_DefPauseEOL\s*\((.+)\)", playdefpause) )
	{
		com_DefPauseEOL := playdefpause1
		if (com_Debug)
			Debug.WriteNL("Found new com_DefPauseEOL >" . com_DefPauseEOL . "<")
	}
	pwt_LinesInScript := A_Index	
}

if (com_Debug)
	Debug.WriteNL("There are " . pwt_LinesInScript . " lines .pwt file to process.")

; If no actors found Warning and end
if (pwt_Actors.MaxIndex() < 1)
{
	if (com_Debug)
		Debug.WriteNL("No actors found in chosen script.")
	MsgBox, No actors can be found in the coosen script! Exiting.
	pwt_Running := false
	pwt_Stopping := false
	return
}

if (com_Debug)
{
    FoundActorsStr := ""
    For loopIndex, loopValue In pwt_Actors
        FoundActorsStr .= loopValue . "|"
	Debug.WriteNL("Actors found in PlayWrite file: " . FoundActorsStr)
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

Gui -MaximizeBox
Gui Add, Text, x30 y8 w60 h30 +0x200, Locale:
Gui Add, DropDownList, x80 y8 w80 vpwt_SystemLoc Sort gSetSysloc, % i18n("SysLocales", "System")
Gui Add, Text, x170 y8 w80 h30 +0x200, com_Channel:
Gui Add, Text, x250 y8 w80 h30 +0x200 vSetComC, % com_Channel
Gui Add, Text, x350 y8 w80 h30 +0x200, pwt_Channel:
Gui Add, Text, x450 y8 w80 h30 +0x200 vSetPwtC, % pwt_Channel
Gui Add, ListView, x15 y48 w600 h225 +Count3 +ReadOnly +Grid -Multi +LV0x4000 +NoSort +NoSortHdr +LV0x840 -LV0x10, Roles Name|Ready|Client ID
Gui Add, Button, x30 y288 w150 h30 gConfirmActorClient, Confirm Actor-Client
Gui Add, Button, x220 y288 w150 h30 gCheckActorClient, Readycheck Actor-Client
Gui Add, Button, x390 y288 w150 h30 gUnsetActor, Unset Actor
Gui Add, Button, x30 y328 w150 h30 gSetMyActor, Set My Actor
Gui Add, Button, x220 y328 w150 h30 gReadychekAll, Readycheck All
Gui Add, Button, x390 y328 w150 h30 gSendfreeActors, Send free Actors
Gui Add, Text, x40 y384 w174 h30 +0x200, Number of Lines in Play:
Gui Add, Text, x216 y384 w38 h30 +0x200, % pwt_LinesInScript
Gui Add, Text, x288 y384 w109 h30 +0x200, Current line # :
Gui Add, Edit, x392 y384 w51 h30 r1 Number vpwt_Currentline, % pwt_CurrentLine
Gui Add, UpDown, , % pwt_CurrentLine
Gui Add, Button, x464 y384 w104 h30 vPlayPause gPlayPause, PLAY
Gui Add, Text, x160 y432 w240 h23 +0x200 +Disabled vWaitingForLine, Waiting for confirmation of line done...
Gui Add, Button, x400 y432 w100 h23 +Disabled vCancelWaitLine gCancelWaitLine, Cancel waiting for linedone...
Gui Add, Button, x128 y480 w155 h30 gpwtRestart, RESTART
Gui Add, Button, x312 y480 w155 h30 gExitPWT, EXIT PlayWrite
Gui Show, w630 h545, PlayWrite Server

; Populate listview with found actors
For loopIndex, loopValue In pwt_Actors
    LV_Add("", loopValue)

; Start timer for polling the command file and reactig to events
setTimer, ParseCommandfile, % cfFilePollTime

; Start interpreting the play (.pwt) strictly serial
Loop
{
    ; honour !pwts_Running by sleeping a spell and relooping
    if not (pwts_Running)
    {
        Sleep, 300
        Continue
    }
    ; honour pwts_WaitingLinedone by sleeping a spell and relooping
    if not (pwts_Waitinglinedone = "")
    {
        Sleep, 300
        Continue
    }
    ParsePlay()
}

; This unreachable Return just in case user finds an unexpected way...
Return

; <GUI code>

GuiEscape:
Return

CancelWaitLine:
pwts_WaitingLinedone := ""
GuiControl, Disable, WaitingForLine
GuiControl, Disable, CancelWaitLine
Return

SetSysloc:
Gui, Submit, NoHide
com_Channel := i18n("com_Channel")
GuiControl,, SetComC, % com_Channel
pwt_Channel := i18n("pwt_Channel")
GuiControl,, SetPwtC, % pwt_Channel
com_WinOutput := i18n("com_WinOutput")
Return

ConfirmActorClient:
lv_RowNumber := LV_GetNext()
if lv_RowNumber
{
    LV_GetText(lv_currClient, lv_RowNumber, 3)
    if lv_currClient
    {
        LV_GetText(lv_currActor, lv_RowNumber, 1)
        if lv_currActor
        {
            LV_Modify(lv_RowNumber , "Col2", "...")
            OutputToTargetWindow(pwt_Channel . cfDirector . ": {#} actorconfirmed(" . lv_currClient . ", " . lv_currActor . ")")
        }
    }
}
Return

SetMyActor:
lv_RowNumber := LV_GetNext()
if lv_RowNumber
{
    LV_GetText(lv_currActor, lv_RowNumber, 1)
    if lv_currActor
    {
        pwts_Actor := lv_currActor
        LV_Modify(lv_RowNumber , "Col3", "My Actor")
        LV_Modify(lv_RowNumber , "Col2", "Yes")
        Gosub SendfreeActors
    }
}
Return

CheckActorClient:
lv_RowNumber := LV_GetNext()
if lv_RowNumber
{
    LV_GetText(lv_currClient, lv_RowNumber, 3)
    if lv_currClient
    {
        LV_Modify(lv_RowNumber , "Col2", "...")
        OutputToTargetWindow(pwt_Channel . cfDirector . ": {#} readycheck(" . lv_currClient . ")")
    }
}
Return

ReadychekAll:
OutputToTargetWindow(pwt_Channel . cfDirector . ": {#} readycheckall")
Loop % LV_GetCount()
{
    LV_GetText(lv_currClient, A_Index, 3)
    if lv_currClient
        LV_Modify(A_Index , "Col2", "...")
}
Return

UnsetActor:
lv_RowNumber := LV_GetNext()
LV_Modify(lv_RowNumber , "Col2", "")
LV_Modify(lv_RowNumber , "Col3", "")
Return

SendfreeActors:
pwt_FreeActors := ""
Loop % LV_GetCount()
{
    LV_GetText(lv_currActor, A_Index, 1)
    LV_GetText(lv_currClient, A_Index, 3)
    if not lv_currClient
        if not pwt_FreeActors
            pwt_FreeActors = % lv_currActor
        else
            pwt_FreeActors := pwt_FreeActors . "," . lv_currActor
}
OutputToTargetWindow(pwt_Channel . cfDirector . ": {#} actorsfree(" . pwt_FreeActors . ")")
Return

PlayPause:
Gui, Submit, NoHide
if not (pwts_Running)
{
    pwts_Running := True
    GuiControl,, PlayPause, PAUSE
}
else
{
    pwts_Running := False
    if (com_Debug)
        Debug.WriteNL("Pausing Play at line number " . pwt_CurrentLine . "<")
    else
        MsgBox, % "Pausing Play at line number " . pwt_CurrentLine . "<"
    GuiControl,, PlayPause, PLAY
}
Return

pwtRestart:
MsgBox 0x34, RESTART PLAYWRITE - This cancels the current play completely!
IfMsgBox Yes, {
    OutputToTargetWindow(pwt_Channel . cfDirector . ": {#}playdone")
    Reload
    Sleep 1000 ; If successful, the reload will close this instance during the Sleep, so the line below will never be reached.
    MsgBox 0x30, The script could not be reloaded, exiting completely.
    ExitApp
    Return
} Else IfMsgBox No, {
    Return
}
Return

GuiClose:
ExitPWT:
MsgBox 0x34, EXIT PLAYWRITE - This cancels the current play completely!
IfMsgBox Yes, {
    ExitApp
} Else IfMsgBox No, {
    Return
}
Return ; Just in case the user finds a way to dismiss the box w/o choosing...

; </GUI code>

ParseCommandfile()
{
	; make globals accessible to this function
	global com_Debug, pwt_Channel, pwts_Waitinglinedone
    global lv_currActor, cfCurrentSize, cfFilename, cfLastSize
    global curFile, cfCurrentLineAmount, cfLastLineAmount

    ; compare file size, don't go further if size didn't grow
    FileGetSize, cfCurrentSize, % cfFilename
    if not (cfCurrentSize > cfLastSize)
        return True
    cfLastSize := cfCurrentSize

    ; compare amount of lines, don't go further if amount didn't grow
    FileRead, curFile, % cfFilename
    StringReplace, locOutputVar, curFile, `n, `n, useerrorlevel
    cfCurrentLineAmount := ErrorLevel + 1
    if not (cfCurrentLineAmount > cfLastLineAmount)
        return True

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
                
        ; if line is from director (this instance) igore
        if ( RegExMatch(curLine, "(*ANYCRLF)^\s*" . i18n("cfDirector", "System") . "\s*:") )
        {
            if (com_Debug)
                Debug.WriteNL("newFileLine is from Director/me: " . curLine . "<")
            Continue
        }
        
        ; check if present and extract client ID
        if ( RegExMatch(curLine, "(*ANYCRLF)^\s*(.+)\s*:\s*.+$", curClientID) )
        {
            cur_ClientID := curClientID1
            if (com_Debug)
                Debug.WriteNL("Client ID extracted from newFileLine:" . cur_ClientID . "<")
            ; clean client ID from curline
            curLine := RegExReplace(curLine, "(*ANYCRLF)^(\s*.+\s*:\s*)")
        }
        Else
        {
            Continue
        }

        ; client sent actorsplz(pwtc_ID)
        if ( RegExMatch(curLine, "(*ANYCRLF)^\s*actorsplz\s*\(") )
        {
            Gosub SendfreeActors
            Continue
        }

        ; client sent plzactor(pwtc_ID,pwtc_Actor)
        if ( RegExMatch(curLine, "(*ANYCRLF)^\s*plzactor\s*\((.+)\)", plzactor) )
        {
            plzactorparams := StrSplit(plzactor1, ",")
            ; this ID = ID-sender OR BUST
            if not (plzactorparams[1] = cur_ClientID)
                Continue
            ; pwtc_Actor exists and not taken OR BUST
            Loop % LV_GetCount()
            {
                LV_GetText(lv_currActor, A_Index, 1)
                if not (lv_currActor = plzactorparams[2])
                    Continue
                LV_GetText(lv_currClient, A_Index, 3)
                if lv_currClient
                    Continue
                ; set actor as taken with this ID
                LV_Modify(A_Index , "Col3", cur_ClientID)
                ; set actor as waitingforconfirmation
                LV_Modify(A_Index , "Col2", "...")
                ; send actorconfirmed(myid,actorname)
                OutputToTargetWindow(pwt_Channel . cfDirector . ": {#} actorconfirmed(" . cur_ClientID . "," . lv_currActor . ")")
                Gosub SendfreeActors
                Break
            }
            Continue
        }
       	
        ; client sent isready(myid,actorname)
        if ( RegExMatch(curLine, "(*ANYCRLF)^\s*isready\s*\((.+)\)", isready) )
        {
            isreadyparams := StrSplit(isready1, ",")
            ; this ID = ID-sender OR BUST
            if not (isreadyparams[1] = cur_ClientID)
                Continue
            ; pwtc_Actor exists and taken by cur_ClientID OR BUST
            Loop % LV_GetCount()
            {
                LV_GetText(lv_currActor, A_Index, 1)
                if not (lv_currActor = isreadyparams[2])
                    Continue
                LV_GetText(lv_currClient, A_Index, 3)
                if not (lv_currClient = isreadyparams[1])
                    Continue
                ; set actor as confirmed with this ID
                LV_Modify(A_Index , "Col2", "Yes")
                Break
            }
            Continue
        }

        ; client sent linedone, reactivate parsing of play
        if ( RegExMatch(curLine, "(*ANYCRLF)^\s*linedone") )
        {
            if (cur_ClientID = pwts_WaitingLinedone)
            {
                pwts_WaitingLinedone := ""
                GuiControl, Disable, WaitingForLine
                GuiControl, Disable, CancelWaitLine
            }
            Continue
        }
    }
    if (com_Debug)
        Debug.WriteNL("- END processing new line(s) in commandfile")
    return True
}

ParsePlay()
{
	; make globals accessible to this function
	global com_Debug, pwt_Script, pwts_Actor, pwt_Channel, cfDirector
    global lv_currActor, pwts_Waitinglinedone, pwt_CurrentLine, pwts_Running

    ; Looping through the play
    While (pwt_CurrentLine <= pwt_Script.MaxIndex())
    {
        GuiControl,, pwt_Currentline, % pwt_Currentline

        curLine := pwt_Script[pwt_CurrentLine]
        
        ; kill all eventual newline and/or linefeed
        curLine := RegExReplace(curLine, "(\r\n|\r|\n)")
        
        ; jump over empty lines
        if (RegExMatch(curLine, "(*ANYCRLF)^\s*$"))
        {
            if (com_Debug)
                Debug.WriteNL("Found empty line: " . curline . "<")
            pwt_CurrentLine++
            continue
        }
        
        ; jump over comment lines
        if (RegExMatch(curLine, pwt_Comment))
        {
            if (com_Debug)
                Debug.WriteNL("Found comment line: " . curline . "<")
            pwt_CurrentLine++
            continue
        }
        
        ; pause may stand in its own line, to give the cast pause to move positions or such
        if (RegExMatch(curLine, "(*ANYCRLF)^\s*\*pause\*(.+?)\*\s*$", parameter))
        {
            if (com_Debug)
                Debug.WriteNL("Single pause in line detected: " . parameter1 . "<")
            if (parameter1 = "pause")
            {
                pwts_Running := False
                if (com_Debug)
                    Debug.WriteNL("Pausing Play at line number " . pwt_CurrentLine . "<")
                else
                    MsgBox, % "Pausing Play at line number " . pwt_CurrentLine . "<"
                GuiControl,, PlayPause, PLAY
            }
            else
            {
                Sleep, parameter1
            }
            pwt_CurrentLine++
            continue
        }
        ; extract actor from line
        RegExMatch(curLine, "(*ANYCRLF)^\s*(.+?)\s*:", foundActor)
        curActor := foundActor1
        ; extract actual line for client to process
        curLine := RegExReplace(curLine, "(*ANYCRLF)^\s*.+?\s*:\s*")
        ; current line may be for myself / pwts_Actor
        if (curActor = pwts_Actor)
        {
            if (com_Debug)
                Debug.WriteNL("Current actors line is for meself as actor " . pwts_Actor . "<")
            ProcessActor(curLine)
            pwt_CurrentLine++
            Return True
        }
        ; lookup clientID for actor-line
        curClientID := ""
        Loop % LV_GetCount()
        {
            LV_GetText(lv_currActor, A_Index, 1)
            if (lv_currActor = curActor)
            {
                LV_GetText(curClientID, A_Index, 3)
                Break
            }
        }
        if not curClientID
        {
            if (com_Debug)
                Debug.WriteNL("No client for actor: " . curActor . "<")
            pwt_CurrentLine++
            Continue
        }
        ; send ClientID: line
        OutputToTargetWindow(pwt_Channel . cfDirector . ": " . curClientID . ": " . curLine)
        ; now we need to wait for confirmation from curClientID
        pwts_Waitinglinedone := curClientID ; An diesem Punkt ist schon auf-text-zu-auf ??? woher das letzte auf??
        GuiControl, Enable, WaitingForLine
        GuiControl, Enable, CancelWaitLine
        pwt_CurrentLine++
        Break
    }
    if ( pwt_CurrentLine > pwt_Script.MaxIndex() )
    {
        pwts_Running := False
        GuiControl,, PlayPause, Play
        OutputToTargetWindow(pwt_Channel . cfDirector . ": {#}playdone")
    }
    Return True
}

; Pressing [Pause] calls PlayPause, same as the GUI-button
Pause::
Goto PlayPause
return

; Include general functions used in both, server and client
#Include PlayWrite-toolfuncs.ahk
#Include PlayWrite-com_LOTRO.ahk
#Include debughelper.ahk
