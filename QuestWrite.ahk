/*
    QuestWrite, copyright 2020 by Carsten Germer
    Version 20200221 Beta

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
FileEncoding, UTF-8 ; According to AHKs documentation the file has to be saved as "UTF-8 with BOM" (?)
SetKeyDelay , 150, 150 ; Relaxed key delays

; General settings
global com_Debug := False
global i18nArray := []
global iniPWTi18n := "i18n-PWT.ini"
global pwt_SystemLoc := "English"
global pwts_Running := True

; Settings for communication with the target system
global com_PreOut := i18n("com_PreOut", "System")
global com_Channel := i18n("com_Channel")
global com_PostOut := i18n("com_PostOut", "System")
global com_DefPauseEOL := % i18n("com_DefPauseEOL", "System") + 1 - 1 ; weird syntax for int(string) ...
global com_WinOutput := i18n("com_WinOutput")

; Settings for PlayWrites intersystems communication
global pwt_Comment := i18n("pwt_Comment", "System")
global pwt_LinesInScript := 0
global pwt_CurrentLine := 1
global lv_currClient := ""
global lv_currSection := ""

; Settings for QuestWrite
global qwt_Actor := ""
global qwt_Questname := ""
global qwt_Filename := "test.qwt"
global QWTArray := {}
global qwt_Section := "prequest"
global qwt_Teaser := "No teaser defined"
global qwt_Interval := 30000
global qwt_NoCommand := "No NoCommand defined"
global qwt_RecentPlayer := ""
global qwt_CurrentPlayer := ""
global qwt_CurrTimestamp := ""
global qwt_InPlay := False
global qwt_CropTail := True
global curLine := ""
global PlayerNextStep := ""

; Settings for dealing with command-(log)file
global cfFilename := "logfile.txt"
global cfCurrentSize := 0
global cfLastSize := 0
global cfCurrentLineAmount := 0
global cfLastLineAmount := 0
global newFileLines := []
global cfLineClean := i18n("cfLineCleanQWT", "System")
global cfFilePollTime := % i18n("cfFilePolltime", "System") + 1 - 1 ; weird syntax for int(string) ...

CheckAHK()

if (com_Debug)
	Debug.WriteNL("Starting in " . A_WorkingDir)

; GUI user choose chat log file
FileSelectFile, cfFilename, 3, , Select chat log file with players communication, chatlog (*.txt)
; check if log file is accessible, initiate cfLastSize and cfLastLineAmount
FileGetSize, cfLastSize, % cfFilename
if (ErrorLevel > 0)
{
	if (com_Debug)
		Debug.WriteNL("Couldn't open file " . cfFilename)
	MsgBox, % "Couldn't open file: " . cfFilename . "<"
	ExitApp
}
FileRead, curFile, % cfFilename
StringReplace, OutputVar, curFile, `n, `n, useerrorlevel
cfLastLineAmount := ErrorLevel + 1
if (com_Debug)
{
	Debug.WriteNL("cf initial size: " . cfLastSize . "<")
	Debug.WriteNL("cf initial lines: " . cfLastLineAmount . "<")
}

; GUI user choose QuestWrite file
FileSelectFile, qwt_filename, 3, , Select QuestWrite file, QuestWrite (*.qwt)
; check if QuestWrite file is accessible
FileGetSize, qwtdummy, % qwt_filename
if (ErrorLevel > 0)
{
    if (com_Debug)
        Debug.WriteNL("Couldn't open .qwt file " . qwt_filename . "<")
    MsgBox, % "Couldn't open .qwt file: " . qwt_filename . "<"
    ExitApp
}

; set qwt_Actor based on filename.qwt
SplitPath, qwt_filename, , , , qwt_Actor
if (com_Debug)
{
	Debug.WriteNL("Playing role with ID: " . qwt_Actor . "<")
}

; set qwt_Questname based on filename.qwt
SplitPath, qwt_filename, , qwt_Questname
qwt_Questname := RegExReplace(qwt_Questname, "^.*\\")
if (com_Debug)
{
	Debug.WriteNL("Processing quest: " . qwt_Questname . "<")
}

; set initial QWT vars, leach *.qwt
qwt_Section := "prequest"
tempval := QWTfilefetch("qwt_Teaser")
if not (tempval = "qwt_Teaser")
    qwt_Teaser := tempval
tempval := QWTfilefetch("qwt_Interval")
if not (tempval = "qwt_Interval")
    qwt_Interval := tempval + 1 - 1
tempval := QWTfilefetch("qwt_NoCommand")
if not (tempval = "qwt_NoCommand")
    qwt_NoCommand := tempval
tempval := QWTfilefetch("qwt_CropTail")
if not (tempval = "qwt_CropTail")
    qwt_CropTail := tempval

Gui -MaximizeBox
Gui Add, Text, x30 y8 w60 h30 +0x200, Locale:
Gui Add, DropDownList, x80 y8 w100 h30 vpwt_SystemLoc Sort gSetSysloc, % i18n("SysLocales", "System")
Gui Add, Text, x200 y8 w80 h30 +0x200, Quest:
Gui Add, Text, x250 y8 w190 h30 +0x200, % qwt_Questname
Gui Add, Text, x450 y8 w30 h30 +0x200, Role:
Gui Add, Text, x490 y8 w80 h30 +0x200, % qwt_Actor
Gui Add, ListView, x15 y48 w600 h225 +Count2 +ReadOnly +Grid -Multi +LV0x4000 +NoSort +NoSortHdr +LV0x840 -LV0x10 gPlayerList, Player Name|Quest Step|Timestamp Advanced
Gui Add, Text, x30 y290 w120 h30 +0x200, Last interaction with
Gui Add, Button, x150 y290 w120 h30 Disabled vqwt_RecentPlayer gMarkPlayer, Player Name
Gui Add, Button, x290 y290 w120 h30 Disabled vPlayerNextStep gPlayerNextStep, Next Step
Gui Add, Button, x430 y290 w120 h30 Disabled vPlayerRemove gRemovePlayer, Remove
Gui Add, Text, x40 y330 w174 h30 +0x200 Disabled vNumLinesPlay, Number of Lines in Play:
Gui Add, Text, x216 y330 w38 h30 +0x200 Disabled vNumLinesScript, % pwt_LinesInScript
Gui Add, Text, x288 y330 w109 h30 +0x200 Disabled vCurrLine, Current line # :
Gui Add, Edit, x392 y330 w51 h30 r1 Number vpwt_Currentline Disabled, % pwt_CurrentLine
Gui Add, UpDown, Disabled vUDCurrLine, % pwt_CurrentLine
Gui Add, Button, x464 y330 w104 h30 vPlayPause gPlayPause Disabled, PAUSE
; TODO Buttons for save and load
Gui Add, Button, x150 y370 w120 h30 gListLoad, Load List
Gui Add, Button, x290 y370 w120 h30 gListSave, Save List

Gui Show, w630 h420, QuestWrite

; Start timer for polling the chatlog and reactig to players requests
SetTimer, ParseCommandfile, % cfFilePollTime

; Start timer for output of teaser
SetTimer, ProcessTeaser, % qwt_Interval

; All done, now it's up to timers, GUI-events and new lines in the chatlog
Return

; <GUI code>

ListLoad:
StopTimer()
ImportCSV()
StartTimer()
Return

ListSave:
StopTimer()
ExportCSV()
StartTimer()
Return

MarkPlayer:
Loop % LV_GetCount()
{
    LV_GetText(lv_currClient, A_Index, 1)
    if (lv_currClient = qwt_RecentPlayer)
    {
        LV_Modify(A_Index , "Vis")
        Break
    }
}
Return

RemovePlayer:
MsgBox , 0x34, Remove %qwt_RecentPlayer%?, Remove %qwt_RecentPlayer% from the list completely!
IfMsgBox Yes, {
    Loop % LV_GetCount()
    {
        LV_GetText(lv_currClient, A_Index, 1)
        if (lv_currClient = qwt_RecentPlayer)
        {
            LV_Delete(A_Index)
            GuiControl, Disable, qwt_RecentPlayer
            GuiControl, Disable, PlayerNextStep
            GuiControl, Disable, PlayerRemove
            Break
        }
    }
}
Return

PlayerList:
if A_GuiEvent = DoubleClick
{
    if (LV_GetText(lv_QueryPlayer, A_EventInfo, 1))
    {
        LV_GetText(qwt_RecentPlayer, A_EventInfo, 1)
        LV_GetText(qwt_Section, A_EventInfo, 2)
        PlayerNextStep := QWTfilefetch("qwt_next", lv_currSection)
        qwt_CurrentPlayer := qwt_RecentPlayer
        GuiControl,, qwt_RecentPlayer, % qwt_RecentPlayer
        GuiControl,, PlayerNextStep, % PlayerNextStep
        GuiControl, Enable, qwt_RecentPlayer
        GuiControl, Enable, PlayerNextStep
        GuiControl, Enable, PlayerRemove
    }
}
return

PlayerNextStep:
if (PlayerNextStep = "none")
    Return
qwt_Section := PlayerNextStep
Loop % LV_GetCount()
{
    LV_GetText(lv_currClient, A_Index, 1)
    if (lv_currClient = qwt_CurrentPlayer)
    {
        LV_Modify(A_Index , "Col2", qwt_Section)
        qwt_CurrTimestamp = %A_NowUTC% 
        qwt_CurrTimestamp -= 19700101000000,seconds
        LV_Modify(A_Index , "Col3", qwt_CurrTimestamp)
        Break
    }
}
PlayerNextStep := QWTfilefetch("qwt_next", qwt_Section)
GuiControl,, PlayerNextStep, % PlayerNextStep
curLine := QWTfilefetch("qwt_intro", qwt_Section)
curLine := RegExReplace(curLine, "cur_player", qwt_CurrentPlayer)
curLine := RegExReplace(curLine, "cur_time", A_Hour . ":" . A_Min . ":" . A_Sec)
StopTimer()
ProcessActor(curLine)
StartTimer()
Return

SetSysloc:
Gui, Submit, NoHide
com_Channel := i18n("com_Channel")
com_WinOutput := i18n("com_WinOutput")
Return

PlayPause:
Gui, Submit, NoHide
if (com_Debug)
    Debug.WriteNL("In PlayPause: with qwt_InPlay: " . qwt_InPlay . ", pwts_Running: " . pwts_Running . "<")
if qwt_InPlay
{
    if not (pwts_Running)
    {
        pwts_Running := True
        SoundPlay *48
        GuiControl,, PlayPause, PAUSE
    }
    else
    {
        pwts_Running := False
        SoundPlay *16
        GuiControl,, PlayPause, PLAY
    }
}
else
{
    if pwts_Running
    {
        pwts_Running := False
        StopTimer()
        GuiControl,, PlayPause, PLAY
        SoundPlay *16
    }
    else
    {
        pwts_Running := True
        StartTimer()
        GuiControl,, PlayPause, PAUSE
        SoundPlay *48
    }
}
Return

GuiEscape:
Return

GuiClose:
MsgBox , 0x34, Exit QuestWrite?, EXIT QUESTWRITE? This cancels the current quest completely!
IfMsgBox Yes, {
    ExitApp
} Else IfMsgBox No, {
    Return
}
Return ; Just in case the user finds a way to dismiss the box w/o choosing...

; </GUI code>

ProcessTeaser()
{
    global qwt_Teaser
    SetTimer, ProcessTeaser, Off
    ProcessActor(qwt_Teaser)
    SetTimer, ProcessTeaser, % qwt_Interval
}

; Leaching *.qwt into variables
QWTfilefetch(msg_key, inisection := false)
{
	global com_Debug, qwt_filename, qwt_Section, QWTArray, qwtdummy
	qwtfile_Debug := False
	ini_key := ""
	ini_value := ""
	if not (inisection)
		inisection := qwt_Section
	
	if (qwtfile_Debug)
		Debug.WriteNL("  QWT file looking up >" . msg_key . "< with section >" . inisection . "<")
	
	; check if the ini was read already, if not leach it
	if (QWTArray.SetCapacity(0) = 0)
	{
		if (qwtfile_Debug)
			Debug.WriteNL("  QWT file wasn't read before, leaching now.")
		
		; check if file is accessible
		FileGetSize, qwtDummy, % qwt_filename
		if (ErrorLevel > 0)
		{
			if (com_Debug)
				Debug.WriteNL("  Couldn't open QWT file " . qwt_filename . "<")
			MsgBox, % "Couldn't open QWT file: " . qwt_filename . "<"
            ExitApp
		}
		
		Loop Read, % qwt_filename
		{
			; Line starts a section?
			if RegExMatch(A_LoopReadLine, "^\s*\[(\w+)\]", foundSection)
			{
                if (qwtfile_Debug)
                    Debug.WriteNL("  QWT file looping, section now: " . foundSection1 . "<")
				ini_section := foundSection1
				continue
			}
			; Line is a (valid) key/value pair?
			if RegExMatch(A_LoopReadLine, "^\s*([^\s]+)\s*=\s*(.+)", foundKeyValue)
			{
                if (qwtfile_Debug)
                    Debug.WriteNL("  QWT file looping, key-value line : " . A_LoopReadLine . "<")
                QWTArray[ini_section, foundKeyValue1] := foundKeyValue2
				continue
			}
		}
	}
	if (QWTArray[inisection, msg_key])
	{
		if (qwtfile_Debug)
			Debug.WriteNL("  qwtfile: Found SECTION and KEY, value is >" . QWTArray[inisection, msg_key] . "<")
		Return % QWTArray[inisection, msg_key]
	}
	else
	{
		if (com_Debug)
			Debug.WriteNL("  qwtfile: Couldn't find key " . msg_key . "< in section " . inisection . "<")
		Return % msg_key
	}
}

ParseCommandfile()
{
	; make globals accessible to this function
	global com_Debug, qwt_CurrentPlayer, curLineLow, qwt_play, qwt_play1
    global cfCurrentSize, cfFilename, cfLastSize, qwt_Section, PlayerNextStep
    global curFile, cfCurrentLineAmount, cfLastLineAmount, lv_currClient, lv_currSection
    curLineLow := ""
    qwt_play := ""
    qwt_play1 := ""
    qwt_goto := ""
    qwt_remove := False

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

    StopTimer()

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
        {
            Debug.WriteNL("Processing newFileLines #" . A_Index . "<")
            Debug.WriteNL("curLine: " . curLine . "<")
        }
        
        ; make curLine all lowercase
        StringLower, curLineLow, curLine
        
        ; if we are not adressed, dismiss
        if not (RegExMatch(curLineLow, qwt_Actor))
        {
            if (com_Debug)
                Debug.WriteNL("can't find my name in line, dismissing.")
            continue
        }

        if ( RegExMatch(curLine, cfLineClean, foundLineRaw) )
        {
            if (com_Debug)
            {
                Debug.WriteNL("foundLineRaw1: " . foundLineRaw1 . "<")
                Debug.WriteNL("foundLineRaw2: " . foundLineRaw2 . "<")
            }
            qwt_CurrentPlayer := foundLineRaw1
            curLine := foundLineRaw2
            if (com_Debug)
                Debug.WriteNL(qwt_CurrentPlayer . " tells me " . curLine . "<")
        }
        else
        {
            if (com_Debug)
                Debug.WriteNL("No cfLineClean in Line:" . curLine . "<")
            continue
        }

        ; ignore empty lines
        if (RegExMatch(curLine, "(*ANYCRLF)^\s*$"))
        {
            if (com_Debug)
                Debug.WriteNL("Found empty newFileLine: " . curLine . "<")
            continue
        }
        
        ; speaker already in list or add new
        lv_currSection := ""
        Loop % LV_GetCount()
        {
            LV_GetText(lv_currClient, A_Index, 1)
            if (lv_currClient = qwt_CurrentPlayer)
            {
                LV_GetText(lv_currSection, A_Index, 2)
                Break
            }
        }
        if (lv_currSection = "") {
            lv_currSection := "prequest"
            qwt_CurrTimestamp = %A_NowUTC% 
            qwt_CurrTimestamp -= 19700101000000,seconds
            LV_Add(, qwt_CurrentPlayer, lv_currsection, qwt_CurrTimestamp)
            qwt_Section := lv_currSection
        }

        ; look for one of the keywords of the current section in curLineLow
        curKeyword := ""
        For Key, Value in QWTArray[lv_currSection]
        {
            if (RegExMatch(Key, "qwt_"))
                Continue
            if (RegExMatch(curLineLow, Key))
            {
                curKeyword := Key
                curLine := Value
                Break
            }
        }

        if (curKeyword = "")
        {
            ProcessActor(RegExReplace(QWTfilefetch("qwt_NoCommand"), "cur_player", qwt_CurrentPlayer))
            Continue
        }

        PlayerNextStep := QWTfilefetch("qwt_next", lv_currSection)
        qwt_RecentPlayer := qwt_CurrentPlayer
        GuiControl,, qwt_RecentPlayer, % qwt_RecentPlayer
        GuiControl,, PlayerNextStep, % PlayerNextStep
        GuiControl, Enable, qwt_RecentPlayer
        GuiControl, Enable, PlayerNextStep
        GuiControl, Enable, PlayerRemove
        
        curLine := RegExReplace(curLine, "cur_player", qwt_CurrentPlayer)
        curLine := RegExReplace(curLine, "cur_time", A_Hour . ":" . A_Min . ":" . A_Sec)

        if (RegExMatch(curLine, "qwt_play:(.+\.\w+)", qwt_play))
        {
            qwt_play := qwt_play1
            if (com_Debug)
                Debug.WriteNL("Found qwt_play " . qwt_play . " in line: " . curLine . "<")
            curLine := RegExReplace(curLine, "qwt_play:(.+\.\w+)")
        }

        if (RegExMatch(curLine, "qwt_goto:(\w+)", qwt_goto))
        {
            qwt_goto := qwt_goto1
            if (com_Debug)
                Debug.WriteNL("Found qwt_goto in line: " . curLine . "<")
            curLine := RegExReplace(curLine, "qwt_goto:(\w+)")
        }

        ; process qwt_remove
        if (RegExMatch(curLine, "qwt_remove"))
        {
            qwt_remove := True
            if (com_Debug)
                Debug.WriteNL("Found qwt_remove in line: " . curLine . "<")
            curLine := RegExReplace(curLine, "qwt_remove")
        }

        ; perform rest of line if any
        curLine := Trim(curLine)
        if not (curLine = "")
            ProcessActor(curLine)
            
        ; process qwt_play
        if not (qwt_play = "")
        {
            ParsePlay()
        }
        
        ; process qwt_goto
        if not (qwt_goto = "")
        {
            qwt_Section := qwt_goto
            Loop % LV_GetCount()
            {
                LV_GetText(lv_currClient, A_Index, 1)
                if (lv_currClient = qwt_CurrentPlayer)
                {
                    LV_Modify(A_Index , "Col2", qwt_Section)
                    qwt_CurrTimestamp = %A_NowUTC% 
                    qwt_CurrTimestamp -= 19700101000000,seconds
                    LV_Modify(A_Index , "Col3", qwt_CurrTimestamp)
                    Break
                }
            }
            ; button next neu
            PlayerNextStep := QWTfilefetch("qwt_next", qwt_section)
            GuiControl,, PlayerNextStep, % PlayerNextStep
            curLine := QWTfilefetch("qwt_intro", qwt_Section)
            curLine := RegExReplace(curLine, "cur_player", qwt_CurrentPlayer)
            curLine := RegExReplace(curLine, "cur_time", A_Hour . ":" . A_Min . ":" . A_Sec)
            ProcessActor(curLine)
        }
        
        ; process qwt_remove
        if(qwt_remove)
        {
            Loop % LV_GetCount()
            {
                LV_GetText(lv_currClient, A_Index, 1)
                if (lv_currClient = qwt_CurrentPlayer)
                {
                    LV_Delete(A_Index)
                    Break
                }
            }
            ;disable buttons
            GuiControl, Disable, qwt_RecentPlayer
            GuiControl, Disable, PlayerNextStep
        }
        
    }
    if (com_Debug)
        Debug.WriteNL("---- END processing new line(s) in commandfile")
    StartTimer()
    return True
}

ParsePlay()
{
	; make globals accessible to this function
	global com_Debug, pwt_Script, qwt_Actor, qwt_InPlay, qwt_play
    global pwt_CurrentLine, pwts_Running, qwt_Questname

    if not qwt_play
        Return

    if (com_Debug)
        Debug.WriteNL("Processing qwt_play " . qwt_play . "<")

    qwt_InPlay := True

    ; Reading qwt_play to array
    FileRead, Filecont, % qwt_Questname . "\" . qwt_play
    if (ErrorLevel > 0)
    {
        if (com_Debug)
            Debug.WriteNL("Couldn't open file " . qwt_Questname . "\" . qwt_play)
        Return
    }
    if (com_Debug)
        Debug.WriteNL("File " . qwt_play . " read")

    ; Split on new line into qwt_Script
    pwt_Script := StrSplit(Filecont, "`n")
    pwt_LinesInScript := % pwt_Script.MaxIndex()

    if (com_Debug)
        Debug.WriteNL("There are " . pwt_LinesInScript . " lines .pwt file to process.")

    pwt_Currentline := 1
    GuiControl,, PlayPause, PAUSE
    GuiControl, Enable, pwt_Currentline
    GuiControl, Enable, PlayPause
    GuiControl, Enable, NumLinesPlay
    GuiControl, Enable, NumLinesScript
    GuiControl, Enable, CurrLine
    GuiControl, Enable, UDCurrLine
    
    ; Looping through the play
    While (pwt_CurrentLine <= pwt_Script.MaxIndex())
    {
        GuiControl,, pwt_Currentline, % pwt_Currentline

        ; honour !pwts_Running by sleeping a spell in loop
        while not (pwts_Running)
        {
            Sleep, 1000
        }
    
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
        if (RegExMatch(curLine, "(*ANYCRLF)^\s*\*pause\*(\d+?)\*\s*$", parameter))
        {
            if (com_Debug)
                Debug.WriteNL("Single pause in line detected: " . parameter1 . "<")
            if (parameter1 = "pause")
            {
                Gosub PlayPause
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

        ; current line may be for myself / qwt_Actor
        if (curActor = qwt_Actor)
        {
            if (com_Debug)
                Debug.WriteNL("Current actors line is for meself as actor " . qwt_Actor . "<")
            ProcessActor(curLine)
            pwt_CurrentLine++
        }
    }
    if (com_Debug)
        Debug.WriteNL("Finished processing sub-pwt.")

    GuiControl, Disable, pwt_Currentline
    GuiControl, Disable, PlayPause
    GuiControl, Disable, NumLinesPlay
    GuiControl, Disable, NumLinesScript
    GuiControl, Disable, CurrLine
    GuiControl, Disable, UDCurrLine
    qwt_InPlay := False
   
    Return True
}

StopTimer()
{
    if (com_Debug)
        Debug.WriteNL("STOPPING Timer...")
    SetTimer, ProcessTeaser, Off
    SetTimer, ParseCommandfile, Off
    Return
}

StartTimer()
{
    global com_Debug, qwt_Interval, cfFilePollTime, cfLastSize, cfFilename, curFile, cfLastLineAmount, OutputVar, qwt_CropTail
    if qwt_CropTail
    {
        if (com_Debug)
            Debug.WriteNL("Cropping tail of " . cfFilename . " to ignore chatter.")
        ; reset cfLastSize and cfLastLineAmount cuz a lot of time may have passed
        FileGetSize, cfLastSize, % cfFilename
        if (ErrorLevel > 0)
        {
            if (com_Debug)
                Debug.WriteNL("Couldn't open file " . cfFilename)
            MsgBox, % "Couldn't open file: " . cfFilename . "<"
            ExitApp
        }
        FileRead, curFile, % cfFilename
        StringReplace, OutputVar, curFile, `n, `n, useerrorlevel
        cfLastLineAmount := ErrorLevel + 1
        if (com_Debug)
        {
            Debug.WriteNL("cf initial size: " . cfLastSize . "<")
            Debug.WriteNL("cf initial lines: " . cfLastLineAmount . "<")
        }
    }
    if (com_Debug)
        Debug.WriteNL("Starting Timer...")
    SetTimer, ProcessTeaser, % qwt_Interval
    SetTimer, ParseCommandfile, % cfFilePollTime
    Return
}

ExportCSV()
{
    Global qwt_Questname, qwt_Actor
    exportfile :=  ""
    exportfilename := A_NowUTC . "-" . qwt_Questname . "-" . qwt_Actor . ".csv"
    exportCol1 := ""
    exportCol2 := ""
    exportCol3 := ""
    exportLine := ""
    
    FileSelectFile, exportfilename, S2, % exportfilename, Select csv file to store this quests data (OR CANCEL TO ABORT), CSV (*.csv)

    exportfile := FileOpen(exportfilename, "w")   ; Creates a new file, overwriting any existing file.
    If (!IsObject(exportfile)) {
        Msgbox 0x40000,, % "Can't create "exportfilename " for writing."
        Return False
    }

    Loop % LV_GetCount() {
      LV_GetText(exportCol1, A_index, 1)
      LV_GetText(exportCol2, A_index, 2)
      LV_GetText(exportCol3, A_index, 3)
      exportLine := exportCol1 . ";" . exportCol2 . ";" . exportCol3
      exportfile.WriteLine(exportLine)
    }

    exportfile.Close()
    exportfilename := ""
    Return True
}

ImportCSV()
{
    importfile := ""
    dummy := 0
    FileSelectFile, importfile, 3, , Select csv file holding this quests save (OR CANCEL TO ABORT), CSV (*.csv)
    FileGetSize, dummy, % importfile
    if (ErrorLevel > 0) {
        Return False
    }
    LV_Delete()
    Loop, Read, % importfile     
    {          
        Array := StrSplit(A_LoopReadLine,";")
        LV_ADD("",Array*)
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
