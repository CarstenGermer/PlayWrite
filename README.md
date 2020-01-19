# PlayWrite
## What is it?
PlayWrite is a system to support player-run performances in LOTRO. The server (director) parses a textfile containing a play or sketch that's written in human-readable syntax and passes the lines and commands on to the respective clients (performers). All communication between server and clients is sent via the ingame chat-channels and is read by tailing a chat-log of that channel.
## Is there more?
I developed PlayWrite as a standalone system that's largely agnostic of the target system. PlayWrite can be easily customized to work with any other game or chat-system as long as it allows to have different channels and can write log-files of those.
## Why AutoHotkey?
AutoHotkey is an immensely useful tool that many gamers around the world already know and have installed. Persons who want to participate in an event don't need to download uncommon software in binary format, which could contain malware. The scripts that constitute PlayWrite can be easily checked by anyone with some experience in software development.
## Can I do something different with PlayWrite?
PlayWrite is specifically tuned to read, process and output plays and sketches at human-readable speeds. If you are proficient enough to rewrite PlayWrite to do some unassociated task, you would be far better off writing your own system from scratch.
## What was your motivation?
I was looking for a hobby project that keeps me trained learning to work with new programming languages and systems surrounding those. I looked into Swift, Golang and Rust, all of which I have done basic training with, but after initial research I found that at the time they lacked crucial specific functionality or libraries that I would need. I had done some desktop automatization with AHK before but nothing close to this involved. If I had just wanted to get PlayWrite done, I would have used Python.
Besides the training aspect, PlayWrite is a prototype of chaining into the communication of legacy distributed systems. This concept can be used to augment legacy systems with e.g. event sourcing or new command inputs without having to change the targeted software.
## Where is the manual?
There'll be a manual for running performances in LOTRO **when it's done**.
2020-01-19: Distributed client-server testing is done but I want to run some tests at larger scale, with 3-4 clients, before I write that manual.
## Legal stuff
_PlayWrite is wtfpl software (http://www.wtfpl.net/txt/copying/)_


_Alle erwähnten Marken oder Warenzeichen oder eingetragenen Marken oder Warenzeichen sind das Eigentum ihrer jeweiligen Besitzer._
