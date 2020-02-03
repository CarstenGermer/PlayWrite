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

; Processing single command(s) taken from the current line
ProcessCommands(commandline)
{
	; make globals accessible to this function
	global com_Debug
	
	trashpos := RegExMatch(commandline, "(*ANYCRLF)^\*(\w+?)\*\w+?\*$", command)
	trashpos := RegExMatch(commandline, "(*ANYCRLF)^\*\w+?\*(\w+?)\*$", parameter)
	
	if (com_Debug)
		Debug.WriteNL("PROCESS command: >" . command1 . "< parameter: >" . parameter1 . "<")
	
	Switch command1
	{
        case "pause":
		{
			if (com_Debug)
				Debug.WriteNL("COMMAND pausing for " . parameter1 . "<")
            SetTimer, ParseCommandfile, Off
			Sleep, parameter1
            SetTimer, ParseCommandfile, On
		}
		case "emote":
		{
			if (com_Debug)
				Debug.WriteNL("COMMAND emoting >" . parameter1 . "<")
			OutputToTargetWindow("/" . i18n(parameter1))
		}
		case "freemote":
		{
			if (com_Debug)
				Debug.WriteNL("COMMAND freemoting >" . parameter1 . "<")
			OutputToTargetWindow("/" . i18n("freemote") . " " . parameter1)
		}
		case "stopemote":
		{
			if (com_Debug)
				Debug.WriteNL("COMMAND stopping ongoing emote through minimal movement.")
			Send, {w down}
			Sleep 20
			Send, {w up}
		}
		case "music":
		{
			if (com_Debug)
				Debug.WriteNL("COMMAND switching music mode " . parameter1)
			Switch parameter1
			{
				case "on":
				OutputToTargetWindow("/" . i18n("musicon"))
				case "off":
				OutputToTargetWindow("/" . i18n("musicoff"))
			}
		}
		case "playnote": ; Notes in LOTRO range from 1 to 24
		{
			if (com_Debug)
				Debug.WriteNL("COMMAND playing music note >" . parameter1 . "<")
			OutputToTargetRaw(parameter1)
		}
		case "playfile":
		{
			if (com_Debug)
				Debug.WriteNL("COMMAND playing music file >" . parameter1 . "<")
			OutputToTargetWindow("/" . i18n("playabc") . " " . parameter1)			
		}
		case "playfilesync":
		{
			if (com_Debug)
				Debug.WriteNL("COMMAND sync playing music file >" . parameter1 . "<")
			OutputToTargetWindow("/" . i18n("playabc") . " " . parameter1 . " sync")			
		}
		case "playstart":
		{
			if (com_Debug)
				Debug.WriteNL("COMMAND start sync playing music.")
			OutputToTargetWindow("/" . i18n("playstart"))			
		}
		default:
		{
			Debug.WriteNL("Error! ProcessCommands not found for :" . command1 . "(" . parameter1 . ")")
		}
	}
	return
}

