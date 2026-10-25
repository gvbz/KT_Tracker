# Changelog

## 4.17.5

- One use of a quest giver can start several tasks. Gregoria and Hunter hand out three at once; each reply that names a task's monster now starts that task (before, only one started).
- Replies using irregular plurals, such as "Gurog Henchmen", are now recognized.

## 4.17.4

- Lighter on the client (build 135 or newer): the plugin runs once a second and asks only for the data it uses, so the client no longer builds its full snapshot (inventory, spells, vendor data) for it. Older builds ignore these settings.
- Quest lines are credited only when the object you have selected is an NPC. Chests, quest items and portals send the same "You may complete this quest again in..." text and no longer give a quest giver a cooldown.

## 4.17.3

- Quest givers that share a name, such as the five Royal Guards at Tou-Tou fort, are now learned from the one you select and use. When he names his task's monster (on pickup, or in a progress reply), or he is the only one with a task ready to turn in, his weenie class is saved to that task in the task database. From then on he gets the task's "!", and his pickups and turn-ins are recognized immediately.
- NPC replies count only from the NPC you have selected, so another NPC with the same name can't be mistaken for him.

## 4.17.2

- Quest-giver information now comes only from the NPC you have selected and used. Lines like "You may complete this quest again in..." are no longer credited to whatever stands nearby.
- Pets and summons ("<player>'s ...") are never treated as NPCs, so they no longer get a "!".
- Only kill-task givers get a "!". Cooldowns saved earlier for anything else (such as a pet) are removed automatically.

## 4.17.1

- Options labels use US spelling: "! color: ...".

## 4.17.0 (2026-10-21)

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
