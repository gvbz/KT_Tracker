# Changelog

## 5.2.3

- Fixed: the window went blank about 2 seconds after starting near Elder Chaos Dragons. Moving the old Chaos Dragon timer entry to the corrected task left the deleted entry in the monster list, and the next look-up stopped the plugin. The lists are now rebuilt after the move, and a task that no longer exists is skipped instead of stopping the plugin.
- The window's status line is on again. It stays empty while the tracker runs and shows the client's message if the plugin is ever stopped.

## 5.2.1

- Fixed: the window could go blank about 2 seconds after starting. Building the quest-flag lists ran one pattern test per flag in your quest list, and with a long list that went over the client's limit for pattern work in one update, which stops the plugin. The lists now use plain text checks and are made one update after the quest file loads.

## 5.2.0

- Areas with more than 14 tasks have pages (**<** and **>** under the bars) instead of "+N more".
- Quest-flag boxes are search boxes: type part of a flag to see up to 5 matches and click one. Matches include flags not in your quest list right now (a task's counter flag only appears while the task is in progress). The two drop-downs are gone.
- A flag that only an unused catalog task has can now be used for your task (it is moved, with a note).
- Catalog fix (Conquest): `killtaskchaosdrag` is Luitbald's Chaos Dragon task (25 Elder Chaos Dragons), with `killtaskchaosdragwait` as its completion flag. It was listed as "Chaos Drudge Kill Task", plus a separate "quest timer" entry. Details you saved on the timer entry move to the corrected task.
- Edit menus: "Reset progress" is now **Reset** and "Undo my changes" is now **Undo**.
- Your own area stays selected after login (5.1.0 could switch to Hoshino before the task database loaded).

## 5.1.0

- Task bars have no S and E buttons any more. Each bar has three click areas instead, left to right: **Select**, **Chat** and **Edit** (hover to see which). Rows are closer together.
- Quest log: a search box for every kill task read from your quest list (name, monster, quest giver or quest flag). Click a result to open its edit menu.
- The area list no longer has **Active**. A saved Active view opens the area of a task in progress.
- Only one edit menu is open at a time.

## 5.0.0

Needs AC:Unreal client v146 or newer.

- **Window**
  - Each task is a progress bar with its name and count (no more drop-down per task). Click the bar for the task's details in chat.
  - **S** (Select) and **E** (Edit) sit beside each bar. E opens the edit menu under the bar.
  - The edit menu has two new fields, the counter quest flag and the completion quest flag, filled in from your `/myquests` list, each with a list of your quest list's kill-task flags.
  - Detected: each task opens to the full edit menu, five per page.
  - Manage is hidden while the window is pinned.
- **Chat**
  - The tracker subscribes only to the lines it uses (server lines and NPC speech), so busy combat chat no longer delays kill counts, and less work is done per update.
  - The client says who sent each line. Other players' chat can never count, even with an NPC's name.
  - After a Refresh, the tracker starts at the newest line instead of replaying the login's chat.
- **Pickups and turn-ins**
  - The client now reports which NPC you used. The NPC no longer needs to be selected or within 6 m, and chests and items are told apart from NPCs.
  - After a pickup or turn-in, `/myquests` is read again as soon as the server allows (once per minute) to confirm it.
- Removed fallbacks for clients older than v146.

## 4.17.11

- Options: "Automatic /myquests update" now also covers the read after login. Turned off, the tracker sends nothing on its own.
- New option "Hide /myquests in chat" (on by default). Turned off, the tracker's own reads show in chat immediately.

## 4.17.10

- Lighter near towns and outposts: items, doors, portals, chests, lifestones and corpses are skipped before any checks, using the object type the client now reports (build 137). Nothing visible changes. Older clients work as before.

## 4.17.9

- Lighter: the window is rebuilt only when something in it may have changed (a kill, pickup, turn-in, quest-list read, click or setting, or the minute for cooldown times), and at least every 5 seconds. The "!" markers and arrows are still worked out every half second but sent only when they change. Kill counts, clicks and markers update as fast as before.

## 4.17.8

- The five Royal Guards at Tou-Tou fort (Conquest) are built in: Void Knights, Hellfire Sorcerers, Pillars of Hellfire, Panumbris Shadows and Bushi Skeletons, each with its own guard, kill count and location. Every guard shows its "!" without having to be learned first.
- Monster names with the plural on the first word, such as "Pillars of Hellfire", are now recognized in kill messages and quest-giver replies.
- When two tasks share a monster (Panumbris Shadows at Tou-Tou outpost and at the fort), a kill message counts toward the task in progress whose kill goal matches.
- A misspelled monster name ("Penumbris Shadow") saved in the task database is replaced by the built-in name.

## 4.17.7

- Your quest list now overrules everything the tracker worked out from chat. After each `/myquests` read:
  - kill counts show the server's counter
  - a task the server has no counter for is no longer shown as in progress
  - a turn-in the server didn't record is undone (when several tasks are handed in at once, the tracker could credit the wrong one)
  - cooldowns follow the quest's own timer
- Kill messages that arrive after the read still count immediately.

## 4.17.6

- Runs every 0.5 seconds again. After a Refresh the client hands a plugin the chat since login, 128 lines at a time; at once a second, new kill messages waited behind that backlog.

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
