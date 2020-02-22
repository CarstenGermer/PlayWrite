# PlayWrite / QuestWrite User Documentation
* [Word of caution](#word-of-caution)
* [About PlayWrite](#about-playwrite)
* [About QuestWrite](#about-questwrite)
* [Other target systems / games](#other-target-systems--games)
* [Installation](#installation)
* [Team](#team)
* [License](#license)
* [i18n-PWT.ini](#i18n-pwtini)
* [PlayWrite](#playwrite)
* [PlayWrite server](#playwrite-server)
* [PlayWrite client](#playwrite-client)
* [PLAY.pwt file(s)](#playpwt-files)
* [How To - solo performances](#how-to---solo-performances)
* [How To - multiplayer performances](#how-to---multiplayer-performances)
* [QuestWrite](#questwrite)
* [QUEST.qwt file(s)](#questqwt-files)
* [How To Solo](#how-to-solo)
* [How To Multi](#how-to-multi)
## Word of caution!
### To get PlayWrite and QuestWrite to do what you want, you need to have a good understanding of Windows-OS, *.ini-files, the chat-system of the game you're targeting, installing and setting up software etc.
### Anyone participating in the play, whether as director or actor can't chat during the play!
PlayWrite uses the chat system for client-server communication and to output the 'spoken' lines. To do this it needs to activate the game and enter text as if you would be doing that with your fingers and keyboard. If you try to use the chat while PlayWrite is using it, you're going to have a bad time.
Using your mouse to click things and/or movement works and should be used for stage movement.
### PlayWrite / Questwrite needs to activate and bring the game/system to the front to use the chat!
Which puts your GUI for PlayWrite-server, PlayWrite-client or QuestWrite to the back. Best advice is to leave your game/system upfront during a play and not bother with looking at the GUI unless you have the play on pause.
### I recommend strongly to have a dedicated 'stage technician'
To help with any installation or configuration issues that come up during preparations or rehearsals for every troupe that sets out to do productions.
### I recommend your troupe to be in voice-chat during rehearses and play!
Obviously...
### If you use language specific characters in your play, you need to save the file as UTF-8
AutoHotkeys documentation is a bit unclear about that atm. I'd say, save as 'UTF-8 with BOM' and test.
## About PlayWrite
PlayWrite is a system to support solo or multi-actor player-run performances in LOTRO. It reads textfiles containing a play or sketch that's written in human-readable syntax and outputs the included text and commands to the target system or passes them on to the respective clients (performers). For plays with many performers all communication between server and client(s) is sent via the ingame chat-channels and read by tailing a chat-log of that channel.
## About QuestWrite
QuestWrite is a similar system for player-run quests and utilizes the same systems for explanations, story etc. It reads a chat-log of a general chat-channel and recognizes it's structure and keywords. Multi-stage quests are realized as multiple single quests that are chained together by story and tokens given out.
## Other target systems / games
I developed PlayWrite and QuestWrite as standalone systems that are largely agnostic of the target system. Both can be easily customized to work with any other game or chat-system as long as it allows to have different channels and can write log-files of those.
## Installation
Have a recent [AutoHotkey](https://www.autohotkey.com/) installed.
Download the latest release of PlayWrite (QuestWrite comes included) from [GitHub](https://github.com/CarstenGermer/PlayWrite/releases) and you just have to run the AHK-scripts as necessary, which is detailed in the respective How To.
## Team
So far just me, which is fine.
## License
PlayWrite / QuestWrite, copyright 2020 by Carsten Germer
This program is free software. It comes without any warranty, to the extent permitted by applicable law. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.
Restrictions pertaining Autohotkey may apply: https://www.autohotkey.com/docs/license.htm
# i18n-PWT.ini
## I just want to use PlayWrite / QuestWrite
No need to alter anything in there.
## I want to add another language
Add a language in the value for 'SysLocales'. Copy one of the existing languages and translate everything.  I'd be happy if you would report that back here for inclusion in the release.
## There is an additional emote not yet translated
Add a line translating that emote from English below the existing ones. I'd be happy if you would report that back here for inclusion in the release.
## I want to alter PlayWrite / QuestWrite to work with another game
You should know exactly what you're doing to begin with.
# PlayWrite
PlayWrite consists of a few vital parts:
- PlayWrite-server.ahk for solo plays or for being 'the director' in multi-plays.
- PlayWrite-client.ahk for the other 'actors' during multi-plays.
- The theplay.pwt file containing all spoken lines, emotes and music played during the performance.
- The Know-how to write a .pwt file and conduct a solo performance or multi-player performance.
# PlayWrite server
## Dialog box "Select chat log file with clients replies"
Choose the log-file that is actively written by your target system (game) of the channel that is chosen for PlayWrites client-server communication.
## Dialog box "Select PlayWrite play file"
Choose the myplay.pwt file that contains all instructions for your play.
## A list of the GUI elements for reference
### locale
The language of your target system (Did you install LOTRO in English, German, French...?)
### com_Channel
Which chat-channel prefix is used for output of actors 'spoken' lines. This defaults to '/say'.
### pwt_Channel
Which chat-channel is used for PlayWrites client-server communication and is actively written to the log-file chosen before. This defaults to '/f'.
### Table of roles and clients
After reading the chosen *.pwt this gets populated with all found roles. As clients request a role their PWT-ID and ready-status is shown.
### Confirm Actor-Client
If a client has requested performing a role you can choose that line in the table and confirm the participation.
### Readycheck Actor-Client
If needed, you can request a new ready-signal from the clients PlayWrite system.
### Unset Actor
If needed, you can remove any PlayWrite-client from the table, whether seen ready or not.
### Set My Actor
If needed, you can choose a single Role and set yourself as the 'actor'.
### Readycheck All
If needed, you can request a new ready-signal from all clients PlayWrite systems.
### Send free Actors
If needed, you can re-send a list of roles still available to all clients.
### Number of Lines in Play
After reading the chosen *.pwt this gets populated with the total number of lines found.
### Current line #
Shows the current line that is being processed. If needed, this can be set while the play is on 'pause'.
### Play / Pause
Start and pause the play. During pause you can set the current line, e.g. roll back a few lines after a break.
You can also toggle Play/Pause by pressing the "Pause"-button on your keyboard. This is the recommended way to do it during a play, as your target system / game should stay up front.
### Waiting for confirmation of line done
This element gets activated while the server is waiting for the signal 'line done' from a client for the current line.
### Cancel waiting for linedone
If necessary, waiting for the signal 'line done' from a client for the current line can be canceled.
### RESTART
Exit and restart the PlayWrite-server app.
### Exit PlayWrite
Exit the PlayWrite-server app.
# PlayWrite client
## Dialog box "Select chat log file with directors commands"
Choose the log-file that is actively written by your target system (game) of the channel that is chosen for PlayWrites client-server communication.
## A list of the GUI elements for reference
### This clients ID
Display of the generated (hopefully) unique ID for the current participation.
### Target system language
The language of your target system (Did you install LOTRO in English, German, French...?)
### Available actors
This dropdown gets populated with the list of available actors the director/server sends.
### Request Refresh
If needed, you can request a refresh of the available actors from the director/server.
### Request chosen actor to be set
Once you picked an available role from the dropdown you can request your participation as that role be recognized and set by the director/server.
### My actor
This shows your set role for the current participation once confirmed by the director/server.
### Cancel participation in this play
If necessary, this tries to cancel your participation in a running play as cleanly as possible.
### Exit PlayWrite
Exit the PlayWrite-client app.
# PLAY.pwt file(s)
This is where your magic happens!
I feel I can't write much more than you hopefully completely understand by reading the examples I provided but I'll try...
## Strong advice
### Keep in mind that humans are supposed to read it!
Persons read at different speeds. So, err on the slow side and be liberal with pauses at the end of lines.
### Remind audience to set "chat bubbles: on"
This is done in System -> Options -> UI Settings -> Chat Bubbles.
Any kind of performance is much more enjoyable if the audience doesn't have to look at the chat-window the whole time.
### Use lots of emotes
None likes to watch wooden puppets spewing lines of text. Use emotes liberally.
### Keep the lines short
Short lines of text can be easily digested at a glance, so keep the spoken lines short and break up long sentences.
You're theoretically able to put a five minutes monologue into one line but that makes your *.pwt unreadable.
While we're at it, performing an emote in the middle of a long(ish) line also breaks up the line into two outputs. So, think of the pause for reading!
### Break up long(er) plays
To preserve your sanity and that of your audience, break up long plays into chunks of about 5-10 minutes. That way short breaks can be easily incorporated and if something goes whack (e.g. one of your actors has to leave), you'll have a break lined up to reorganize before carrying on.
### Rehearse, rehearse, rehearse
Can't stress this enough. Just do it.
## List of commands
### Beginning of line "#"
Tags this line as a comment that is ignored while processing the play. Put your stage directions as such or whatever you deem helpful.
### Beginning of line "Name: "
All names that are found like this make up the list of actors for your play.
### \*pause\*milliseconds\*
Pause processing of the play for 'milliseconds' milliseconds.
### \*emote\*type\*
Perform an emote. For LOTRO this gets put out as '/type'.
### \*freemote\*text\*
Output a free emote. For LOTRO this gets put out as '/em text'
### \*stopemote\*none\*
Some emotes, like dances, go on for a long(ish) time. This way you can stop the performance of an ongoing emote. Keep in mind that commands need some dummy parameter, which is ignored.
### \*com_channel\*i18nKey\*
Gets the value for i18nKey for the systems locale from the ini-file and sets the output channel to that. To for instance /shout a word or send a single line to /regional. Handle with care! Only use if really necessary! Different channels may have different time-outs for spam protection within the target system. Allthough PlayWrites defaults are very chill, it is recommended to add an extra *pause*FewSeconds* after having sent something to a non-standard channel.
### \*music\*on|off\*
Switch the character into music mode, aka grab the instrument. Performative emotes are not animated while in music mode.
### \*playnote\*key for note in AHK-format\*
Do not use this. I did put it in for testing and didn't bother to remove it. It's a surefire way to annoy your audience.
### \*playfile\*filename\*
If the character is in music mode, this plays 'filename', just like if it was entered into chat.
### \*playfilesync\*filename\*
If the character is in music mode, this readies 'filename' for synchronized play, just like if it was entered into chat.
### \*playstart\*none\*
If the character is in music mode and has synced play with others ready, this starts the synced play.
# How To - solo performances
- Start PlayWrite-sever.ahk
- Just select a dummy *.txt as there's no communication with clients. 
- Select the playname.pwt you want to perform.
- Choose an actor from the table and use the button to 'Set my Actor'.
- Click the 'Play'-button, sit back and enjoy.
# How To - multiplayer performances
This recipe is for LOTRO in particular and assumes none of the defaults have been changed.
- All participating need to be in a fellowship.
- All participating have a separate chat-tab for 'fellow' and ideally for 'fellow' only.
- All participating need to have started a chat log of this 'fellow' chat-tab.
- The director starts the PlayWrite-server.ahk script and selects the chat-log and the play.pwt that is to be performed.
- If needed, the director sets the language of his or her installation of the target system / game.
- All participating clients start PlayWrite-client.ahk and select the chat-log.
- If needed, the clients set the language of their individual installation of the target system / game.
- The director sends a list of available actors.
- The clients choose their individual role from the dropdown and request them to be acknowledged by the director.
- The director acknowledges all requests for necessary roles with the 'Confirm Actor-Client' button.
- Once all necessary roles are allotted and the actors are in place the director starts the play with the 'Play' button.
- No one tries to use the text chat of the game until the play has finished.
- Depending on the play, the actors use the mouse to turn and move around stage, change costumes etc.
- Player run event = Yay, fun!
# QuestWrite
Questwrite has it's own format and commands for the MyQuest.qwt files and can use *.pwt files for longer story or drama parts.
## Advice
If you want to incorporate multi-actor plays in your quest you need to have both systems and all participants started and ready. For simplicity, I would recommend having one player as the 'quest-handler' and other players standing by for the performance.
## Dialog box "Select chat log file with players communication"
Choose the log-file that is actively written by your target system (game) of the general chat-channel that players use to speak with you.
## Dialog box "Select QuestWrite file"
Choose the myquest.qwt file that contains all instructions for your quest or part of the bigger quest-line.
## A list of the GUI elements for reference
### Locale
The language of your target system (Did you install LOTRO in English, German, French...?)
### Quest
The name of the quest as taken from the directory name your myquest.qwt is in.
### Role
Your role and name, used by players to address and interact with you. It's taken from the name of the myquest.qwt.
### Table of players name and their current section of the quest
As soon as QuestWrite identifies players interacting with you by saying your name in general chat it stores the players name together with the information which section of the quest this player is in.
### Last interaction with
The name of the last player interacting with you.
### Button 'Player Name'
Pressing this button highlights the particular player in the list, as this list might get long.
### Next Step
If a player is chosen in the list, this button advances the player to the next section of the quest. Use this for example to advance the player to the next section after she or he handed you some items you want the players to collect.
### Remove
This removes the player from the list completely. This might be desired if the player accidentally chose a wrong language or something.
### Key "Pause"
Pressing the Pause-key on your keyboard pauses processing of the current *.qwt or *.pwt. This is helpful if you need to text-chat during an ongoing event.
### ONLY during optional *.pwt : Number of lines in Play
See PlayWrite documentation.
### ONLY during optional *.pwt : Current line #
See PlayWrite documentation.
### ONLY during optional *.pwt : Play / Pause Button
See PlayWrite documentation.
# QUEST.qwt file(s)
This is where your magic happens!
I feel I can't write much more than you hopefully understand by reading the examples I provided but I'll try...
## Strong advice
See above. Basically all advice for PLAY.pwt file(s) also applies for writing quest.qwt files.
### Keep lines the quest-handler performs extra snappy!
While the quest-handler is performing she or he is not able to process new requests. Requests that may be coming in while performing will be ignored. Try to keep story, drama and explanation as short as possible.
## List of commands
### [section name]
Tags the beginning of a section or step in this quest.
### [prequest]
Is a reserved section and is processed when new/additional players communicate with you by saying your roles name who are not already set as being in a section.
### (only in [prequest]) qwt_teaser = line to perform
This line is performed at an interval to tease new / additional players into talking to you.
### (only in [prequest]) qwt_interval = milliseconds
Time in milliseconds between performance of qwt_teaser.
### qwt_Intro = line to perform
Line to perform once a player advances to this section.
### qwt_NoCommand = line to perform
Line to perform if the system recognizes a player talking to you but does not recognize any of the keywords of that players current section.
### qwt_next = section name
This is the name of the section a player gets advanced to when you click the 'Next Step' button
### keyword(|keyword2|keyword3...) = line to perform
One or more keywords which are looked for if a player talk to you by saying your roles name. The first on that is found in the players talk will be executed.
### cur_player
A special keyword in performing-lines that gets replaced by the players name.
### cur_time
A special keyword in performing-lines that gets replaced by the hh:mm:ss current local time.
### qwt_goto:section name
A special keyword:parameter in performing-lines that advances the player automatically to the named section.
### qwt_remove
A special keyword in performing-lines that removes the player from the table completely. Doing this allows the player to repeat the quest from the beginning.
### playwrite.pwt commands
Basically all command from *.pwt files can be used in performing-lines. Test the more involved one like playing synced music at your own peril.
# How To Solo
This recipe is for LOTRO in particular and assumes none of the defaults have been changed.
- Have a separate chat-tab for 'say' and ideally for 'say' only.
- Have a chat log of this 'say' chat-tab started.
- Start QuestWrite.ahk
- Select the chat-log and the rolename.qwt you want to perform.
- Wait for players starting to interact with you.
- If there's a part in your quest where players need to give or show you certain items you need to do that manually by using the mouse and need to manually advance the player to the next section using the GUI.
- Enjoy the puzzled looks and frustration when people are trying to figure out how it works ;)
# How To Multi
I hope your quest-line has a story?
Just send the players to the next stage with a line like "You need to go to X and speak with Y, now.".
If you want lasting indicators that players have completed a previous stage, hand out crafted tokens, for example "Tier 1 cookie, crafted by ..." and have them hand it in at the next stage.
This also is psychologically a very good idea as it's a reminder and creates a feeling of commitment.
Go wild!
