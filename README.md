# Kill Task Tracker (KT_Tracker)

A kill-task tracker plugin for the AC:Unreal client. The tracker reads quest status' from a /myquests dump and then displays relevant kill task information. The plugin runs whenever it is enabled and there are no specific start/stop buttons.
<img width="618" height="328" alt="KT_tracker_2" src="https://github.com/user-attachments/assets/2552f766-2297-4f96-8184-b339a5d053da" />
<img width="989" height="379" alt="KT_tracker_3" src="https://github.com/user-attachments/assets/9af312d4-6786-4a2b-a773-2373510978ac" />
<img width="235" height="405" alt="KT_tracker_5" src="https://github.com/user-attachments/assets/26790ff4-ecab-4766-b2c1-f00d60b4f124" />
<img width="235" height="405" alt="KT_tracker_4" src="https://github.com/user-attachments/assets/1f271d8f-b26e-40d0-aad6-a1bc62cc813f" />

## Features

-Displays kill task mobs on the minimap with a green triangle.
-Automatically points the navigation arrow to the closest mob.
-Automatically detects and adds custom quests, with the ability to edit quest information and categorize them by area.
-NPC indication symbols (!) based on quest status. Adjustable in the settings menu.
  -Yellow = Available
  -White = In progress
  -Red = On cool-down
  -Green = Ready to turn in
-Compares /myquests against a base set of known kill tasks quests. 

## Requirements

- AC:Unreal client build 126 (2026.10.19) or newer.
- Works on any ACE server. Built-in tasks cover Hoshino, Tou-Tou, Rynthid, Graveyard, Viridian Rise, Frozen Valley and Neftet. Other kill tasks are picked up from your quest list and chat.

## Install

1. Download the latest zip from the [Releases](../../releases) page.
2. Unzip and drop into `ACUnreal\Saved\ClientPlugins\Installed\KT_Tracker`.
4. Open the plugin menu, press **Refresh**, then **Enable** the Kill Task Tracker.

## Updating

Replace the files in `Installed\KT_Tracker` with the new download and press **Refresh** in Manage Plugins. Your tasks, progress and settings are saved outside this folder, so they are retained.

## In game

### The window

- **Show in NAV**: turns the green arrows over task monsters and NAV arrow integration on or off.
- **Area list**: pick **Active** (tasks you are working on or can turn in), a specific hunting area, or **Other**. Newly detected quests that are categorized will be placed into **Other**.
- **Task lines**: one line per task, showing the task name and your kill count. The color shows the state:
  - white: in progress, with your count (e.g. `Devourer Marguls  6/15`)
  - green: ready to turn in
  - yellow: available to pick up
  - red: on cooldown, with the time left
- **Open a task line** to see its progress bar and three buttons:
  - **Select**: selects the nearest task monster, or the quest giver if you aren't working on the task.
  - **Chat**: shows the task's details in your chat window (quest giver, location, kills needed, quest flags). Only you see these lines.
  - **Edit**: change the task's name, monsters, quest giver, kills required, cooldown or area. You can also reset its progress, undo your changes, or delete a task you added.

### In the world

- **!** over quest givers, colored by task state (colors can be changed in Options).
- **Green arrows** over task monsters near you.
- **NAV arrow** pointing to the closest task monster, or to a quest giver when a task is ready to turn in.

### How progress is tracked

- **Your quest list.** The tracker reads `/myquests` automatically when you log in, and every 65 seconds after that (adjustable in settings). These reads are hidden from your chat windows.
- **Kill messages.** Lines such as "You've killed 5 out of 20 ..." update the count immediately without relying on another /myquests poll.
- **Turn-ins.** These are confirmed by your quest flags, or by using the quest giver followed by the reward. The tracker never relies on what an NPC says, and never counts other players' chat or tells as progress.
- **Your data.** Everything is saved per character and per server, so characters with the same name on different servers stay separate.

### Manage

Open **Manage** at the bottom of the window:

- **Detected**: kill tasks found in your quest list or chat whose monster or quest giver isn't known yet. Fill them in and press **Save**, or press **Remove** to hide one. "Refresh list" in the quest-giver box lists the NPCs near you.
- **Add**: add your own task, and your own areas.
- **Quest log**: when your quest list was last read, any lines it didn't understand, and where your files are saved.
- **Options**:
  - NPC indication !
  - Automatic /myquests update
  - /myquests update interval
  - scan range
  - default cooldown
  - the ! colours

Long text in the window stays on one line. Hover over it to read all of it.

## Permissions

The plugin uses the following service requests:

| Permission | Used for |
|---|---|
| chat | reading kill messages and quest-list replies |
| chat_filter | hiding its own `/myquests` replies from your chat windows |
| say | sending `@myquests` |
| state | saving your settings and progress |
| profiles | saving your quest list and task database files |
| ui | its window, and the Chat button's local messages |
| markers | the ! and arrows |
| waypoint | the NAV arrow |
| data | your XP and actions, used to confirm turn-ins |

## Your files

Saved under `Saved/ClientPlugins/Profiles/kt_tracker/Library/`:

- `Quests/`: your quest list, one file per character and server. Other plugins can read it.
- `Database/`: tasks you added or edited, shared by your characters on that server.

## Credits

- Kill-task catalog based on the Oracle of Dereth `quests.csv` (MIT, curated by Advis).
- Built-in task data from Aunberean.
- AC:Unreal client and plugin framework by Thwargle.

## License

MIT. See [LICENSE](LICENSE).
