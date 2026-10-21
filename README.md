# Kill Task Tracker (KT_Tracker)

A kill-task tracker plugin for the AC:Unreal client. It keeps track of your kill tasks: how many kills you have, which tasks are ready to turn in, and which are on cooldown. It also marks quest givers and task monsters around you.

It runs whenever it is enabled. There is nothing to start or stop.

## Requirements

- AC:Unreal client build 126 (2026.10.19) or newer.
- Works on any ACE server. Built-in tasks cover Hoshino, Tou-Tou, Rynthid, Graveyard, Viridian Rise, Frozen Valley and Neftet. Other kill tasks are picked up from your quest list and chat.

## Install

1. Download the latest zip from the [Releases](../../releases) page.
2. In the client, open **Manage Plugins** (Plugins on the login screen, or Game Play → Manage Plugins).
3. Press **Open plugin folder** and copy the `KT_Tracker` folder into it. The path should end in `Installed\KT_Tracker\plugin.json`, not `KT_Tracker\KT_Tracker\...`.
4. Press **Refresh**, then **Enable** Kill Task Tracker.

## Update

Replace the files in `Installed\KT_Tracker` with the new ones and press **Refresh** in Manage Plugins. Your tasks, progress and settings are saved outside this folder, so they are kept.

## In game

### The window

- **Show in NAV**: turns the arrows over task monsters and the NAV arrow on or off.
- **Area list**: pick **Active** (tasks you are working on or can turn in), a hunting area, one of your own areas, or **Other**.
- **Task lines**: one line per task, showing the task name and your kill count. The colour shows the state:
  - white: in progress, with your count (e.g. `Devourer Marguls  6/15`)
  - green: ready to turn in
  - yellow: available to pick up
  - red: on cooldown, with the time left
- **Open a task line** to see its progress bar and three buttons:
  - **Select**: selects the nearest task monster, or the quest giver if you aren't working on the task.
  - **Chat**: shows the task's details in your chat window (quest giver, location, kills needed, quest flags). Only you see these lines.
  - **Edit**: change the task's name, monsters, quest giver, kills required, cooldown or area. You can also reset its progress, undo your changes, or delete a task you added.

### In the world

- **!** over quest givers, coloured by task state (colours can be changed in Options).
- **Green arrows** over task monsters near you.
- **NAV arrow** pointing to the closest task monster, or to a quest giver when a task is ready to turn in.

### How progress is tracked

- **Your quest list.** The tracker reads `/myquests` automatically when you log in, and every 65 seconds after that. These reads are hidden from your chat windows.
- **Kill messages.** Lines such as "You've killed 5 out of 20 ..." update the count straight away.
- **Turn-ins.** These are confirmed by your quest flags, or by using the quest giver followed by the reward. The tracker never relies on what an NPC says, and never counts other players' chat or tells as progress.
- **Your data.** Everything is saved per character and per server, so characters with the same name on different servers stay separate.

### Manage

Open **Manage** at the bottom of the window:

- **Detected**: kill tasks found in your quest list or chat whose monster or quest giver isn't known yet. Fill them in and press **Save**, or press **Remove** to hide one. "Refresh list" in the quest-giver box lists the NPCs near you.
- **Add**: add your own task, and your own areas.
- **Quest log**: when your quest list was last read, where your files are saved, and the last kill message seen.
- **Options**:
  - NPC indication !
  - Automatic /myquests update
  - /myquests update interval
  - scan range
  - default cooldown
  - the ! colours

Long text in the window stays on one line. Hover over it to read all of it.

## Permissions

When you enable it, the plugin asks for:

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
