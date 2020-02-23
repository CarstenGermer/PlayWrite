/*
    PlayWrite, copyright 2020 by Carsten Germer
    Version 20200203 Beta
    
    This program is free software. It comes without any warranty, to
    the extent permitted by applicable law. You can redistribute it
    and/or modify it under the terms of the Do What The Fuck You Want
    To Public License, Version 2, as published by Sam Hocevar.
    See http://www.wtfpl.net/ for more details.
     
    Restrictions pertaining Autohotkey may apply: https://www.autohotkey.com/docs/license.htm
*/

; i18n-ish function
i18n(msg_key, inisection := false)
{
	global com_Debug, iniPWTi18n, pwt_SystemLoc, pwt_Running, pwt_Stopping, i18nArray
	i18n_Debug := False
	ini_section := "none"
	array_key := "" ; section and key get concatenated to "secion-key" for simplification
	ini_key := ""
	ini_value := ""
	
	if (i18n_Debug)
		Debug.WriteNL("  i18n: looking up >" . msg_key . "< with section >" . inisection . "<")
	
	; check if the ini was read already, if not leach it
	if (i18nArray.SetCapacity(0) = 0)
	{
		if (i18n_Debug)
			Debug.WriteNL("  i18n: Ini i18n wasn't read before, leaching now.")
		
		; check if file is accessible
		FileGetSize, i18nDummy, % iniPWTi18n
		if (ErrorLevel > 0)
		{
			if (com_Debug)
				Debug.WriteNL("  i18n: Couldn't open INI file " . iniPWTi18n . "<")
			MsgBox, % "Couldn't open INI file: " . iniPWTi18n . "<"
			pwt_Running := false
			pwt_Stopping := false
			Return % msg_key
		}
		
		Loop Read, % iniPWTi18n
		{
			; Line starts a section?
			if RegExMatch(A_LoopReadLine, "^\s*\[(\w+)\]", foundSection)
			{
				ini_section := foundSection1
				continue
			}
			; Line is a (valid) key/value pair?
			if RegExMatch(A_LoopReadLine, "^\s*([^\s]+)\s*=\s*(.+)", foundKeyValue)
			{
				array_key = % ini_section . "-" . foundKeyValue1
				i18nArray.Insert(array_key,foundKeyValue2)
				continue
			}
		}
	}
	
	if not (inisection)
		inisection := pwt_SystemLoc
	
	array_key = % inisection . "-" . msg_key
	
	;IniRead, msg, % iniPWTi18n, % inisection, % msg_key ; AHK needs the INI file as UTF-16 if you use non ANSI chars!
	if (i18nArray[array_key])
	{
		if (i18n_Debug)
			Debug.WriteNL("  i18n: Found SECTION and KEY, value is >" . i18nArray[array_key] . "<")
		Return % i18nArray[array_key]
	}
	else
	{
		if (com_Debug)
			Debug.WriteNL("Couldn't find key " . msg_key . "< with section >" . inisection . "<")
		Return % msg_key
	}
}

; Item in array lookup
ArrayContains(array, searchfor)
{
	Loop, % array.MaxIndex()
	{
		if(array[A_Index] = searchfor)
		{
			return 1
			break
		}
	}
	return 0
}

; Return N last lines of file
FileTail(k, file) ; tail read file
{
	filelines := []
	returnlines := []
	; read whole file into array
	Loop Read, % file
	{    
		filelines.Push(A_LoopReadLine)
	}    
	
	; transfer only last k lines
	Loop, % filelines.MaxIndex()
	{
		if (A_Index <= ( filelines.MaxIndex() - k ) )
			continue
		returnlines.Push(filelines[A_Index])
	}
	
	return returnlines
}

; Processing a line for the current systems actor
ProcessActor(curLine)
{
	; make globals accessible to this function
	global com_Debug, com_Channel
	
	;Replace special chars that act as funtion keys in AHK
	curLine := RegExReplace(curLine, "\!", "{!}")
	
    if (com_Debug)
        Debug.WriteNL("ProcessActor curLine: " . curLine)

    ;Split line with intermediate commands into sublines and process parts in subloop
	if (RegExMatch(curLine, "\*\w+?\*\w+?\*"))
	{
		if (com_Debug)
			Debug.WriteNL("Actors line has subcommands")
		partsLine := Array()
		;as long as there is subcommands within the line...
		while (RegExMatch(curLine, "\*\w+?\*\w+?\*"))
		{
			;Trim curLine just to be on the safe side of stray whitespace
			curLine := Trim(curLine)
			if (com_Debug)
				Debug.WriteNL("while curLine: " . curLine)
			;find the position of the leftmost subcommand...
			foundPos := RegExMatch(curLine, "\*\w+?\*\w+?\*",foundSubCommand)
			if (com_Debug)
				Debug.WriteNL("foundPos " . foundPos)
			;if the leftmost subcommand _is not_ immediately at the beginning of the line...
			if (foundPos > 1)
			{
				;add everything left of the subcommand to the sublines array
				partsLine.Push( Trim( SubStr( curLine,1, (foundPos-1) ) ) )
				;and cut out everything left of the command from the current line. 
				curLine := SubStr( curLine,foundPos,StrLen(curLine)-(foundPos-1) )
			}
				;if the leftmost subcommand _is_ immediately at the beginning of the line...
			else
			{
				;add the found subcommand to the sublines array...
				partsLine.Push(foundSubCommand)
				;and cut the subcommand from the current line.
				curLine := RegExReplace(curLine, "\*\w+?\*\w+?\*", "", , 1)
			}
		}
		;add the remainder of the current line, if any, as subcommand to the subline array.
		if(StrLen(curLine) > 1)
		{
			curLine := RegExReplace(curLine, "(\r\n|\r|\n)")
			partsLine.Push( Trim(curLine) )
		}
		;loop over subcommands and treat them individually as single commands.
		Loop, % partsLine.MaxIndex()
		{
			if (com_Debug)
				Debug.WriteNL("partsLine " . A_Index . ": " . partsLine[A_Index])
			; this part a command or spoken text?
			if (RegExMatch(partsLine[A_Index], "(*ANYCRLF)^\*\w+?\*\w+?\*$"))
			{
				; is a command - process
				ProcessCommands(partsLine[A_Index])
			}
			else
			{
				; is spoken text - output
				OutputToTargetWindow(com_Channel . " " . partsLine[A_Index])
			}
		}
		if (com_Debug)
			Debug.WriteNL("--- Sublines end")
	}
	else
	{
		;This is text for the actors default com_Channel		
		curLine := RegExReplace(curLine, "(\r\n|\r|\n)")
        if (com_Debug)
            Debug.WriteNL("ProcessActor output raw curLine: " . curLine)
		OutputToTargetWindow(com_Channel . " " . curLine)
	}
	return true
}

; Check AHK Version
CheckAHK()
{
    if (A_AhkVersion < "1.1.32.00")
    {
       MsgBox, Your AutoHotkey version is out of date.
       ExitApp
    }
}

; Output to target systems chat function, including com_PreOut, com_PostOut and anti-spam timeouts
OutputToTargetWindow(textout)
{
	; make globals accessible to this function
	global com_Debug, com_DefPauseEOL, com_PreOut, com_PostOut
	
	if (com_Debug)
		Debug.WriteNL("SENDING CHAT " . com_PreOut . textout . com_PostOut . "< to >" . i18n("com_WinOutput") . "<")
	
	; Output to target window
	if WinExist(i18n("com_WinOutput"))
	{
        SetTimer, ParseCommandFile, Off
		WinActivate, % i18n("com_WinOutput")
        WinSet, Top, , % i18n("com_WinOutput")
        Sleep, (com_DefPauseEOL/2)
        Send % com_PreOut ; presses Enter and opens the chat
		Send % textout ; types the actual text into open chat
        Send % com_PostOut ; presses Enter and sends the chatline
        Sleep, (com_DefPauseEOL/2)
        SetTimer, ParseCommandFile, On
	}
    return
}

; Output to target system directly, as a keypress
OutputToTargetRaw(textout)
{
	; make globals accessible to this function
	global com_Debug, com_WinOutput
	
	if (com_Debug)
		Debug.WriteNL("SENDING RAW >" . textout . "< to >" . i18n("com_WinOutput") . "<")
	
	; Output to target window
	if WinExist(i18n("com_WinOutput"))
	{
        SetTimer, ParseCommandFile, Off
		WinActivate, % i18n("com_WinOutput")
        WinSet, Top, , % i18n("com_WinOutput")
		Send % textout
        SetTimer, ParseCommandFile, On
	}
    return

}