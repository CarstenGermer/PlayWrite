# PlayWrite / QuestWrite
## What's PlayWrite?
PlayWrite is a system to support solo or multiactor player-run performances in LOTRO. It reads textfiles containing a play or sketch that's written in human-readable syntax and outputs the included text and commands to the target system or passes them on to the respective clients (performers). For plays with many performers all communication between server and client(s) is sent via the ingame chat-channels and read by tailing a chat-log of that channel.
## What's QuestWrite?
QuestWrite is a similar system for player run quests and untilizes the same systems for explanations, story etc. It reads a chat-log of a general chat-channel and recognizes it's structure and keywords. Multi-stage quests are realized as multiple single quests that are chained together by story and tokens given out.
## Can you show me?
Sure, I'll link vids I made about PlayWrite / QuestWrite.  
https://www.youtube.com/watch?v=WQji1Ccy6k0  
https://www.youtube.com/watch?v=fGx0CUgV78c  
https://www.youtube.com/watch?v=JtVo4b6Rd28  
...
## Is there more?
I developed PlayWrite and QuestWrite as a standalone system that's largely agnostic of the target system. Both can be easily customized to work with any other game or chat-system as long as it allows to have different channels and can write log-files of those.
## Why AutoHotkey?
AutoHotkey is an immensely useful tool that many gamers around the world already know and have installed. Persons who want to participate in an event don't need to download uncommon software in binary format, which could contain malware. The scripts that constitute PlayWrite can be easily checked by anyone with some experience in software development.
## Can I do something different with PlayWrite / QuestWrite?
PlayWrite and QuestWrite are specifically tuned to read, process and output plays and sketches at human-readable speeds. If you are proficient enough to change this software to do some unassociated task, you would be far better off writing your own system from scratch.
## What was your motivation?
I was looking for a hobby project that keeps me trained learning to work with new programming languages and systems surrounding those. I looked into Swift, Golang and Rust, all of which I have done basic training with, but after initial research I found that at the time they lacked crucial specific functionality or libraries that I would need. I had done some desktop automatization with AHK before but nothing close to this involved. If I had just wanted to get PlayWrite done, I would have used Python.
Besides the training aspect, PlayWrite is a prototype of chaining into the communication of legacy distributed systems. This concept can be used to augment legacy systems with e.g. event sourcing or new command inputs without having to change the targeted software.
## Where are the manuals?
There's user documentation [right here](USERDOCUMENTATION.md).
## Can I get involved?
At the moment I'm really only looking for a few persons to help me test this further. I play as Gutur McGermot of the Kin 'Extraordinarily Adequate' on Ithil at GMT evenings. If you plan to customize PlayWrite for another game, I would be very much interested to hear from you, though I don't play any other games which PlayWrite could be used in atm.
## May I sponsor you?
Naa, buy me a coffee or a beer some time, maybe.
## Legal stuff
_PlayWrite and QuestWritw are wtfpl software (http://www.wtfpl.net/txt/copying/)_


_Alle erwähnten Marken oder Warenzeichen oder eingetragenen Marken oder Warenzeichen sind das Eigentum ihrer jeweiligen Besitzer._
