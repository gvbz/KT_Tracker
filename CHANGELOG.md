# Changelog

## 4.17.0

- Removed the chat log (the "Log NPC and kill-task chat" option). Logs saved by earlier versions are not deleted: you can remove the `Profiles/kt_tracker/Library/Logs` folder yourself.
- Removed two testing aids:
  - the extra raw copy of each `/myquests` reply (`..._lastread.json`), which was saved after every read but never used
  - the "Last kill message" line in Quest log
- Your quest list file is unchanged. Old `_lastread.json` files can be deleted from `Profiles/kt_tracker/Library/Quests`.
- Updated the description at the top of `main.lua`.

## 4.16.0 (2026-10-21)

First public release.

- The **Chat** button now shows task details as local messages in your chat window, instead of tells to yourself. Nothing is sent to the server.
- Long text in the window stays on one line instead of wrapping. Hover over it to read all of it.
- Needs AC:Unreal client build 126 or newer.
