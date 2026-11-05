-- KT_Tracker 5.2.3: kill-task tracker for the AC:Unreal client (API 2 companion).
-- Needs client v146 or newer (chat_subscriptions, sender_type, use events,
-- progress labels, clickable frames, overlays, hide_when_pinned).
--
-- Window (title and icon from plugin.json "presentation"): "Show in NAV", the
-- area selector (a hunting area, one of your own areas, or Other), then one
-- progress bar per task showing the monster/task name and "kills / goal"
-- (white in progress, green ready to turn in, yellow available, red on
-- cooldown with the time left). Three invisible click areas lie over each bar,
-- left to right (tooltips say which):
--   Select  the nearest task monster, or the quest giver
--   Chat    the task's details (giver, location, kills, quest flags) as local
--           notices in chat (only you see them, nothing is sent)
--   Edit    the task's fields in place, under the bar (saved to the task database)
-- Manage (hidden while the window is pinned) holds:
--   Detected  kill tasks found in your quest list or chat whose monster or giver
--             is unknown, 5 per page; each opens to the full edit form
--   Add       a new task, and areas of your own
--   Quest log when the quest list was read, lines it didn't understand, files,
--             and a search of the kill tasks read (each result opens its edit menu)
--   Options
-- The edit form has two quest-flag fields: the counter flag (kill count) and
-- the completion flag (stamped on turn-in). Both are filled in from your
-- /myquests list when the tracker can tell which flags belong to the task.
-- 5.2.0: typing in either box lists up to 5 matching flags under it (your
-- quest list first, then the catalog and task database); click one to use it.
-- A flag that only an unused catalog task has can be moved to your task.
-- More than 14 tasks in an area: pages with < and > under the bars.
--
-- Chat (5.0.0): plugin.json "chat_subscriptions" deliver only the lines the
-- tracker uses: server lines (quest list, kill counts, stamps, experience,
-- "Destroy N of these", "again in", /myquests replies) and NPC/vendor speech.
-- "sender_type" says who sent each line, so a player's chat never counts.
-- "chat_history": false starts at the newest line (no replay after Refresh).
--
-- NPC use (5.0.0): the client's "use" events (data permission) name the used
-- object and its weenie class. Only that NPC's tells, and server lines in the
-- 10 s after it was used, count for pickups, "Destroy N", cooldowns and
-- turn-ins (use + experience line, or a stamp). Shared-name givers (five
-- "Royal Guard"s at Tou-Tou fort) are learned by the used NPC's weenie class.
-- Pets ("<player>'s ...") are never treated as NPCs.
--
-- Your quest list (@myquests) is the foundation: read 8 s after login, every
-- "/myquests update interval" (default 65 s), and as soon as the server's 60 s
-- limit allows after a pickup or turn-in. Each complete read overrules what
-- was worked out from chat before it was sent (counts, pickups, turn-ins,
-- cooldowns). The tracker's own reads are hidden from the chat windows (server
-- lines only); reads you type yourself are shown.
--
-- Storage (Saved/ClientPlugins/Profiles/kt_tracker/Library/), per server:
--   Quests/<server>_<character>_<id>.json   the whole quest list (other plugins
--                                            can read it)
--   Database/KillTaskDB_<server>.json        task details (monsters, givers,
--                                            quest flags, your tasks)
--   plus per-character progress and timers in the plugin's saved state.
--
-- Catalog: kill-task quests from Oracle of Dereth's quests.csv (quest names,
-- givers, towns, coordinates, kill counts, quest flags). Built-in tasks (TASKS)
-- come from Aunberean data.
--
-- Markers: "!" over quest givers (yellow available, white in progress, green
-- ready to turn in, red on cooldown), green arrows over task monsters, and the
-- NAV arrow to the closest one, from the nearby-object list.

-- Kill-task catalog generated from Oracle of Dereth quests.csv (MIT, curated by Advis).
-- q quest, f quest flags, n quest givers, m monsters, g kills, c giver coords, t town, s server-only, r repeatable
local CATALOG = {
  {q="Crystalline Adventurer", f={"killtaskintensewispscorinca","killtaskintensewispscorincawait","killtaskintensewispsshivol","killtaskintensewispsshivolwait"}, n={"Tokashi Ando","Shade of Ja'qu","Lever"}, c="14.6S 62.2W", t="Crystalline Crag", r=true},
  {q="Arctic Mattekar Kill Task", f={"arcticmattekarkillcount","arcticmattekarkilltask"}, n={"Enzo Ilario","Enzo LLario"}, m={"Arctic Mattekar"}, g=25, c="87.4N 70.5W", t="Silyun", r=true},
  {q="Baby Dragon Kill Task", f={"babydragonkillcount","babydragonkilltaskwait"}, m={"Baby Dragon"}, s="Conquest", r=true},
  {q="Empyrean Cloister Quest", f={"hopeslayerobsidiandagger","hopeslayerskull"}, n={"Chosen of Asheron"}, c="23.4S 5.8E", t="Empyrean Cloister", r=false},
  {q="Rare Game Kill Task", f={"belindakilltasksstart","killtaskraregame_0609","killtaskraregamewait_0609"}, n={"Belinda du Loc","Belinda Du Loc"}, m={"Rare Game"}, c="68.9N 21.6W", r=true},
  {q="Benek Niffis Kill Task", f={"benekniffiskillcount","benekniffiskilltask"}, n={"Colista Fluress"}, m={"Benek Niffis"}, g=50, c="77.8N 67.1E", t="Vissidal", r=true},
  {q="Black Dragon Kill Task", f={"blackdragonkillcount","blackdragonkilltask","blackdragonkilltaskstarted"}, m={"Black Dragon"}, s="Conquest", r=true},
  {q="Black Coral Golem Kill Task", f={"blackmarketblackcoralgolemkilltask","blackmarketblackcoralgolemkilltaskwait"}, n={"Malrin","Chiriko"}, m={"Black Coral Golem","Coral Golems"}, g=50, c="71.8N 60.8W", t="Sanamar", r=true},
  {q="Blighted Coral Golem Kill Task", f={"blackmarketblightedcoralgolemkilltask","blackmarketblightedcoralgolemkilltaskwait"}, n={"Malrin","Hanzo"}, m={"Blighted Coral Golem","Coral Golems"}, g=50, c="71.8N 60.8W", t="Sanamar", r=true},
  {q="Killing Bosh Bosh", f={"boshboshslayertokenpickuptimer"}, n={"Kuuru"}, r=true},
  {q="Bronze Dragon Kill Task", f={"bronzedragonkillcount","bronzedragonkilltask","bronzedragonkilltaskstarted"}, m={"Bronze Dragon"}, s="Conquest", r=true},
  {q="Bronze Gauntlet Trooper Kill Task", f={"bronzegauntlettrooperkillcount","bronzegauntlettrooperkilltask"}, n={"Lieutenant Grenlin"}, m={"Bronze Gauntlet Trooper","Bronze Gauntlet Troopers"}, g=25, c="33.4S 6.3E", r=true},
  {q="Harvesting the Bulb of Mornings", f={"sanctumguardiankilltask","sanctumguardiankilltask_completed"}, n={"Kaltus","Sanctum Guardian Spirit","Shah-hi"}, c="22.2S 8.6E", t="Neftet Excavation Site", r=false},
  {q="Fuzzy Bunny Slayer Quest", f={"bunnyslippergiven"}, n={"Larry the Rabbit Master","William Witty"}, c="17.9N 64.3E", t="Asheron's Island", r=false},
  {q="Ithaenc Quiddity Seed Quest", f={"clawofthehopeslayerfirstrun","clawofthehopeslayerpickuptimer"}, n={"Emissary of Asheron","Aun Aemaua","Shade of Dule"}, c="17.9N 64.3E", t="Asheron's Island", r=false},
  {q="Copper Cog Trooper Kill Task", f={"coppercogtrooperkillcount","coppercogtrooperkilltask"}, n={"Lieutenant Zin"}, m={"Copper Cog Trooper","Copper Cog Troopers"}, g=25, c="22.4S 0.2E", t="Yaraq to Ijaniya portal", r=true},
  {q="Coral Golem Kill Task", f={"coralgolemkillcount"}, n={"Malrin"}, m={"Coral Golem","Coral Golems"}, g=50, c="71.8N 60.8W", t="Sanamar", r=true},
  {q="The Crystal Idol of the A'nekshay", f={"crystalidolneftetkillcount","crystalidolneftetkilltask"}, n={"Bemeth the Gatherer","Altar of the Black Crystal","Ancient Tablet of the Crystal Idol"}, m={"A'nekshay"}, g=20, c="22.2S 6.1E", t="Encampment near Neftet", r=true},
  {q="Aun Golem Hunters", f={"fellowshipcrystallordslayerquest"}, n={"Aun Tahuirea"}, r=false},
  {q="Deathcap Thrungus Kill Task", f={"deathcapthrunguskillcount","deathcapthrunguskilltask"}, n={"Jiang Li"}, m={"Deathcap Thrungus"}, g=25, c="72.7N 73.3W", t="Westwatch", r=true},
  {q="Desert Cactus Kill Task", f={"desertcactuskillcount","desertcactuskilltask"}, n={"Sir Unell bin Rakke"}, m={"Desert Cactus","Desert Cacti"}, g=6, c="22.2S 6.1E", t="Encampment near Neftet", r=true},
  {q="Dire Mattekar Kill Task", f={"diremattekarkillcount","diremattekarkilltask"}, n={"Fergal the Dire"}, m={"Dire Mattekar"}, g=10, c="49.4S 62.4E", t="Baishi", r=true},
  {q="Dragon Egg Kill Task", f={"dragoneggkillcount","dragoneggkilltask","dragoneggkilltaskstarted"}, m={"Dragon Egg"}, s="Conquest", r=false},
  {q="Drudge Plan", f={"drudgekilltasks_start"}, n={"Jarvis Hammerstone"}, c="25.6N 49.4E", r=true},
  {q="Ebon Gromnie Kill Task", f={"ebongromniekills","ebongromnietask"}, n={"Afra bint Abbas"}, m={"Ebon Gromnie","Ebon Gromnies"}, g=25, c="40.8N 83.0W", t="Redspire", r=true},
  {q="The Empyrean Portalspace Stabilizer", f={"killtaskapostatevirindihigh_0710","killtaskapostatevirindilow_0710","killtaskapostatevirindimid_0710"}, n={"Emissary of Asheron","Emissary"}, m={"Apostate Virindi Aggressors"}, g=30, c="69.6N 17.6E", t="Neydisa Castle", r=true},
  {q="Floeshark Kill Task", f={"floesharkkillcount","floesharkkilltask"}, n={"Ryuichi Tai"}, m={"Floeshark","Floesharks Isle of Ruin"}, g=50, c="90.3N 43.0W", t="Eastwatch", r=true},
  {q="Fort Bushi Kill Task", f={"fortbushikillcount","fortbushikilltaskwait"}, n={"Royal Guard"}, m={"Bushi Skeletons"}, d="Fort Bushi Skeletons", g=50, c="10.0S 63.9W", t="Tou-Tou fort", a="Tou-Tou", w=43370055, s="Conquest", r=true},
  {q="Fort Knight Kill Task", f={"fortknightkillcount","fortknightkilltaskwait"}, n={"Royal Guard"}, m={"Void Knights"}, d="Fort Void Knights", g=50, c="10.1S 63.9W", t="Tou-Tou fort", a="Tou-Tou", w=43370054, s="Conquest", r=true},
  {q="Fort Shadow Kill Task", f={"fortshadowkillcount","fortshadowkilltaskwait"}, n={"Royal Guard"}, m={"Panumbris Shadows"}, d="Fort Panumbris Shadows", g=50, c="10.1S 63.9W", t="Tou-Tou fort", a="Tou-Tou", w=43370053, s="Conquest", r=true},
  {q="Moarsmen Jailbreak", f={"freebooterkilltask0809","freebooterkilltaskboss10809","freebooterkilltaskboss1wait0809","freebooterkilltaskboss20809","freebooterkilltaskboss2wait0809","freebooterkilltaskboss30809","freebooterkilltaskboss3wait0809","freebooterkilltaskwait0809"}, n={"Avarin","Gate Warden Kris"}, c="56.4S 96.9E", t="Freebooter Isle", r=true},
  {q="Frost Golem Kill Task", f={"frostgolemkillcount","frostgolemkilltask"}, n={"George"}, m={"Frost Golem","Frost Golems"}, g=20, c="83.8N 4.3W", r=true},
  {q="Frozen Crystal Kill Task", f={"frozencrystalkillcount","frozencrystalkilltask"}, n={"Boone"}, m={"Frozen Crystal","Frozen Crystals"}, g=4, c="83.7N 4.3W", t="Frozen North", r=true},
  {q="Frozen Dread Kill Task", f={"frozendreadkillcount","frozendreadkilltask"}, n={"Kumiko"}, m={"Frozen Dread","Frozen Dreads"}, g=20, c="83.8N 4.3W", t="Frozen Valley", r=true},
  {q="Frozen Fortress Testing Grounds Quest", f={"frozenfortresstestinggroundskilltask_0513"}, n={"Bloodstone NPC","Sir Donovan","Frozen Fortress Testing Grounds Attunement Shard"}, c="83.8N 4.3W", t="Frozen Valley", r=false},
  {q="Frozen Wight Kill Task", f={"frozenwightkillcount","frozenwightkilltask"}, n={"Leilah"}, m={"Frozen Wight","Frozen Wights"}, g=20, c="83.8N 4.3W", t="Frozen Valley", r=true},
  {q="Gear Knight Kill Task", f={"gearknightinvasionhighkilltask_1009","gearknightinvasionhighkillwait_1009"}, n={"Sir Yanov"}, m={"Gear Knight","Gear Knight Knights"}, g=10, c="12.3S 74.9W", r=true},
  {q="Gear Knight Phalanx Kill Task", f={"gearknightinvasionphalanxkilltask_0513","gearknightinvasionphalanxkillwait_0513"}, n={"Ladice"}, m={"Gear Knight Phalanx"}, r=true},
  {q="Gear Knight Squire Kill Task", f={"gearknightinvasionsquirekilltask_0513","gearknightinvasionsquirekillwait_0513"}, n={"Sir Yanov"}, m={"Gear Knight Squire","Gear Knight Squires"}, g=10, c="12.3S 74.9W", r=true},
  {q="Gearknight Lesser Lords", f={"gearknightlesserlordkillcount","gearknightlesserlordkilltask"}, n={"Dame Alistra"}, c="22.4S 0.2E", t="Yaraq to Ijaniya portal at", r=true},
  {q="Glenden Wood Invaders", f={"glendeninvaderskills"}, n={"Londigul Ellic the Armorer","Londigul"}, m={"Invaders"}, g=20, c="29.9N 27.1E", t="Glenden Wood", r=true},
  {q="Gold Gear Trooper Kill Task", f={"goldgeartrooperkillcount","goldgeartrooperkilltask"}, n={"Sir Stavitor"}, m={"Gold Gear Trooper","Gold Gear Troopers"}, g=25, c="33.4S 6.3E", r=true},
  {q="Coral Golem Viceroy Kill Task", f={"golemcoralviceroyslayerquest","ongolemcoralviceroyslayerquest","totalgolemcoralviceroydead"}, n={"Aun Aukherea"}, m={"Coral Golem Viceroy","Coral Golem Viceroys"}, g=5, c="60.8S 88.0W", t="Ayan Baqur", r=true},
  {q="Glacial Golem Margrave Kill Task", f={"golemglacialmargraveslayerquest","ongolemglacialmargraveslayerquest","totalgolemglacialmargravedead"}, n={"Aun Maerirea"}, m={"Glacial Golem Margrave","Glacial Golem Margraves"}, g=5, c="74.5S 19.3E", t="Qalaba'r", r=true},
  {q="Copper Golem Kingpin Kill Task", f={"golemironkingpinslayerquest","ongolemironkingpinslayerquest","totalgolemironkingpindead"}, n={"Aun Tiulerea"}, m={"Copper Golem Kingpin","Copper Golem Kingpins"}, g=5, c="16.5N 63.6E", r=true},
  {q="Magma Golem Exarch Kill Task", f={"golemmagmaexarch_kt","golemmagmaexarchslayerquest","magmaexarchcooldown","ongolemmagmaexarchslayerquest","totalgolemmagmaexarchdead"}, n={"Aun Autuorea"}, m={"Magma Golem Exarch","Magma Golem Exarchs"}, g=5, c="87.5S 67.0W", t="Candeth Keep", s="Levistras", r=true},
  {q="Magma Golem Exarch Kill Task Cooldown", f={"golemmagmaexarch_kt_wait"}, m={"Magma Golem Exarch"}, s="Levistras", r=false},
  {q="Mud Golem Sludge Lord Kill Task", f={"golemmudsludgelordslayerquest","ongolemmudsludgelordslayerquest","totalgolemmudsludgelorddead"}, n={"Aun Akuarea"}, m={"Mud Golem Sludge Lord","Mud Golem Sludge Lords"}, g=5, c="2.6S 20.0E", t="Samsur", r=true},
  {q="Platinum Golem Mountain King Kill Task", f={"golemplatinumkingslayerquest","ongolemplatinumkingslayerquest","totalgolemplatinumkingdead"}, n={"Aun Khekierea"}, m={"Platinum Golem Mountain King","Platinum Golem Mountain Kings"}, g=5, c="60.8S 88.0W", t="Ayan Baqur", r=true},
  {q="Grievver Violator Kill Task", f={"grievverv","grievvervkillcount"}, n={"Moina"}, m={"Grievver Violator","Grievver Violators"}, g=100, c="90.4N 43.1W", r=true},
  {q="Guruk Basher Kill Task", f={"gurukbasherkillcount","gurukbasherkilltask"}, n={"Shiruuk"}, m={"Guruk Basher"}, r=true},
  {q="Guruk Colossus Kill Task", f={"gurukcolossuskillcount","gurukcolossuskilltask"}, n={"Brogosh"}, m={"Guruk Colossus"}, r=true},
  {q="Guruk Fiend Kill Task", f={"gurukfiendkillcount","gurukfiendkilltask"}, n={"Mohor"}, m={"Guruk Fiend"}, r=true},
  {q="Guruk Marauder Kill Task", f={"gurukmarauderkillcount","gurukmarauderkilltask"}, n={"Kurket"}, m={"Guruk Marauder"}, r=true},
  {q="Guruk Monstrosity Kill Task", f={"gurukmonstrositykillcount","gurukmonstrositykilltask"}, n={"Borsh"}, m={"Guruk Monstrosity"}, r=true},
  {q="Guruk Smasher Kill Task", f={"guruksmasherkillcount","guruksmasherkilltask"}, n={"Kushuk"}, m={"Guruk Smasher","Guruk Smashers"}, g=40, r=true},
  {q="Three Eyed Snowman Kill Task", f={"hassnowglobeneydisa","heardblindsnowmansadstory","killtaskthreeeyedsnowman","killtaskthreeeyedsnowmanwait"}, n={"Blind Snowman"}, m={"Three Eyed Snowman"}, g=5, c="40.2N 35.1E", t="Holtburg", r=true},
  {q="Hea Windreave Kill Task", f={"heawindreavekillcount","heawindreavekilltask"}, n={"Susana du Loc"}, m={"Hea Windreave","Hea Windreaves"}, g=25, c="40.7N 83.2W", r=true},
  {q="Hell Bovine Kill Task", f={"hellbovinekillcount","hellbovinekilltaskwait"}, m={"Hell Bovine"}, s="Conquest", r=true},
  {q="Hellfire Sorcerer Kill Task", f={"hellfiresorckillcount","hellfiresorckilltaskwait"}, n={"Royal Guard"}, m={"Hellfire Sorcerers"}, d="Fort Hellfire Sorcerers", g=50, c="10.1S 63.9W", t="Tou-Tou fort", a="Tou-Tou", w=43370057, s="Conquest", r=true},
  {q="High Priest of T'thuun Kill Task", f={"highpriestacolytedead","highpriestfirstdead","highpriestseconddead","highpriestthirddead","holysymbolpickuptimer","killtaskmoarsmanhighprieststarted","killtaskmoarsmanhighpriestwait"}, n={"Kaymor ibn Dumandi","High Priest's First","High Priest's Third"}, m={"High Priest of T'thuun"}, c="92.6S 53.0W", t="Moarsman City", r=true},
  {q="Holly Jolly Helper Quest", f={"killtaskmosswartcynicwait_1121"}, n={"Osdryd"}, m={"Mosswart Cynics"}, g=15, c="29.0S 58.9E", t="Sawato", r=false},
  {q="Shadow Captain's Heaume Quest", f={"hopeslayerheart"}, n={"Chosen of Asheron"}, c="66.2N 14.3E", t="Stone Triad Dell portal", r=false},
  {q="Mnemosyne Quest", f={"hopeslayerobsidiankey"}, r=false},
  {q="Virindi Servant's Amulet Quest", f={"hopeslayersingularity"}, c="52.9S 62.7W", t="Chakron Gate", r=false},
  {q="Hope Slayer Treasure Map", f={"hopeslayertreasuremapfound"}, s="Conquest", r=false},
  {q="Ice Giant Kill Task", f={"icegiantkillcount","icegiantkilltask"}, m={"Ice Giant"}, s="Conquest", r=true},
  {q="Iron Blade Trooper Kill Task", f={"ironbladetrooperkillcount","ironbladetrooperkilltask"}, n={"Lieutenant Micham"}, m={"Iron Blade Trooper"}, c="33.4S 6.3E", r=true},
  {q="Iron Spined Chittick Kill Task", f={"ironspinedchittickkills","ironspinedchitticktask"}, n={"Aidene"}, m={"Iron Spined Chittick"}, g=50, c="2.0N 95.6E", t="Oolatanga's Refuge", r=true},
  {q="Investigating the Societies", f={"killtask-blightspirit","killtask-blightspiritwait"}, n={"Jondor Torgren","Candrus Steady-Hand","Joku Shunja"}, c="13.6N 0.7E", t="Zaikhal", r=true},
  {q="Harvest Reaper Kill Task", f={"killtask-harvestreaper","killtask-harvestreapercompletions"}, n={"Majestic Pumpkin"}, m={"Harvest Reaper","Harvest Reapers"}, g=10, c="30.7N 27.8E", t="Glenden Wood", r=true},
  {q="Pumpkin Lord Kill Task", f={"killtask-pumpkinlord"}, n={"Majestic Pumpkin"}, m={"Pumpkin Lord","Pumpkin Lords"}, g=3, c="30.7N 27.8E", t="Glenden Wood", r=true},
  {q="Altered Drudge Kill Task", f={"killtaskaltereddrudges_0507","killtaskaltereddrudgeswait_0507"}, n={"Jarvis Hammerstone"}, m={"Altered Drudge","Altered Drudges"}, g=40, c="25.6N 49.4E", t="Cragstone", r=true},
  {q="Ancient Dragon Kill Task", f={"killtaskancientdrag","killtaskancientdragwait"}, m={"Ancient Dragon"}, s="Conquest", r=false},
  {q="Augmented Drudge Kill Task", f={"killtaskaugmenteddrudges_0507","killtaskaugmenteddrudgeswait_0507"}, n={"Jarvis Hammerstone"}, m={"Augmented Drudge","Augmented Drudges"}, g=40, c="25.6N 49.4E", t="Cragstone", r=true},
  {q="Banished Creature Kill Task", f={"killtaskbanishedcreature_0609","killtaskbanishedcreaturewait_0609"}, n={"Belinda du Loc"}, m={"Banished Creature"}, c="68.9N 21.6W", t="Stonehold", r=true},
  {q="Blood Disciple Kill Task", f={"killtaskblooddisciple"}, m={"Blood Disciple"}, s="Conquest", r=false},
  {q="Blood Shreth Kill Task", f={"killtaskbloodshreth","killtaskbloodshrethwait"}, n={"San Ming"}, m={"Blood Shreth","Blood Shreths"}, g=10, c="33.5S 72.8E", r=true},
  {q="Chaos Dragon Kill Task", f={"killtaskchaosdrag","killtaskchaosdragwait"}, n={"Luitbald"}, m={"Elder Chaos Dragon"}, g=25, s="Conquest", r=true},
  {q="Corrupted Gravestone Kill Task", f={"killtaskcorruptedgravestones_1311","killtaskcorruptedgravestoneswait_1311"}, n={"Slubbley"}, m={"Corrupted Gravestone","Corrupted Gravestones"}, g=6, c="65.3S 43.3W", t="Arcanum Lookout", r=true},
  {q="Crystalline Killer", f={"killtaskcrystallinewisps10109","killtaskcrystallinewisps10109wait"}, n={"Oorjit"}, m={"Crystalline Wisps"}, g=100, c="14.6S 62.0W", t="Crystalline Crag", r=true},
  {q="Armoredillo Hunting: Lost City of Neftet", f={"killtaskdesertareaarmoredillo_0511","killtaskdesertareaarmoredillowait_0511"}, n={"Dame Tularin"}, m={"Armoredillos"}, g=30, r=true},
  {q="Golem Hunting: Lost City of Neftet", f={"killtaskdesertareagolem_0511","killtaskdesertareagolemwait_0511"}, n={"Sir Ibreh bin Kassim"}, m={"Golems"}, g=15, r=true},
  {q="Mumiyah Hunting: Lost City of Neftet", f={"killtaskdesertareamumiyah_0511","killtaskdesertareamumiyahwait_0511"}, n={"Sir Adarl"}, m={"Mu-miyahs"}, g=30, r=true},
  {q="Reedshark Hunting: Lost City of Neftet", f={"killtaskdesertareareedshark_0511","killtaskdesertareareedsharkwait_0511"}, n={"Sir Hassim bin Tamarek"}, m={"Reedsharks"}, g=30, r=true},
  {q="Drudge Lurker Kill Task", f={"killtaskdrudgelurkers_0507","killtaskdrudgelurkerswait_0507"}, n={"Jarvis Hammerstone"}, m={"Drudge Lurker","Drudge Lurkers"}, g=100, c="25.6N 49.4E", t="Cragstone", r=true},
  {q="Drudge Ravener Kill Task", f={"killtaskdrudgeraveners_0507","killtaskdrudgeravenerswait_0507"}, n={"Jarvis Hammerstone"}, m={"Drudge Ravener","Drudge Raveners"}, g=50, c="25.6N 49.4E", t="Cragstone", r=true},
  {q="Drudge Stalker Kill Task", f={"killtaskdrudgestalkers_0507","killtaskdrudgestalkerswait_0507"}, n={"Jarvis Hammerstone"}, m={"Drudge Stalker","Drudge Stalkers"}, g=100, c="25.6N 49.4E", t="Cragstone", r=true},
  {q="Elemental Kill Task", f={"killtaskelemental_0609","killtaskelementalwait_0609"}, n={"Zahir"}, m={"Elemental"}, c="68.7N 21.5W", r=true},
  {q="Stop the Rebuilding", f={"killtaskengineer1","killtaskengineer1completed","killtaskengineer2","killtaskengineer2completed","killtaskengineer3","killtaskengineer3completed","killtaskengineer4","killtaskengineer4completed"}, n={"Isin Dule"}, m={"Shadow Engineers"}, g=4, c="33.4N 56.9E", t="Arwic", r=true},
  {q="Rynthid Artifact Collection", f={"killtaskenragedshadows","killtaskenragedshadowsstarted","killtaskenragedshadowswait","killtasktormentedshadows","killtasktormentedshadowsstarted","killtasktormentedshadowswait"}, n={"Encampment","Corrupted Crystal of Rage","Corrupted Crystal of Torments"}, m={"Tormented Shadows"}, g=20, c="62.1S 65.8W", r=true},
  {q="Fallen Creature Kill Task", f={"killtaskfallencreature_0609","killtaskfallencreaturewait_0609"}, n={"Belinda du Loc"}, m={"Fallen Creature","Fallen"}, g=10, c="68.9N 21.6W", t="Stonehold", r=true},
  {q="Golem Samurai Kill Task", f={"killtaskgolemsamurai0812","killtaskgolemsamuraicompleted0812"}, n={"Lieutenant Aurin"}, m={"Golem Samurai"}, g=10, c="80.7N 43.0W", r=true},
  {q="Grave Rat Kill Task", f={"killtaskgraveyardgraverat_1107","killtaskgraveyardgraveratwait_1107","loshoenspackratskilled_1107","loshoenspacktimer_1107"}, n={"Lo Shoen"}, m={"Grave Rat","Grave Rats"}, g=100, c="65.3S 43.4W", r=true},
  {q="Graveyard Skeleton Kill Task", f={"killtaskgraveyardskeleton_1309","killtaskgraveyardskeletonwait_1309"}, n={"Yoite"}, m={"Graveyard Skeleton","Graveyard Skeletons"}, g=30, c="65.4S 44.0W", t="Graveyard", r=true},
  {q="Graveyard Spirit Kill Task", f={"killtaskgraveyardspirit_1309","killtaskgraveyardspiritwait_1309"}, n={"Aethelswith"}, m={"Graveyard Spirit","Graveyard Spirits"}, g=10, c="65.4S 44.0W", t="Graveyard", r=true},
  {q="Graveyard Wight Kill Task", f={"killtaskgraveyardwight_1309","killtaskgraveyardwightwait_1309"}, n={"Gadi"}, m={"Graveyard Wight","Graveyard Wights"}, g=30, c="65.4S 44.0W", t="Graveyard", r=true},
  {q="Graveyard Wisp Kill Task", f={"killtaskgraveyardwisp_1309","killtaskgraveyardwispwait_1309"}, n={"Renata"}, m={"Graveyard Wisp","Graveyard Wisps"}, g=5, c="65.4S 44.0W", t="Graveyard", r=true},
  {q="Guardian Statue Kill Task", f={"killtaskguardianstatue","killtaskguardianstatuewait"}, n={"Shade of Fordroth"}, m={"Guardian Statue","Guardian Statues"}, g=10, c="64.7S 45.2W", t="Mhoire Castle Northeast Tower", r=true},
  {q="Gurog Kill Task", f={"killtaskguroghenchman1110","killtaskguroghenchmancompleted1110","killtaskgurogminion1110","killtaskgurogminioncompleted1110","killtaskgurogsoldier1110","killtaskgurogsoldiercompleted1110"}, n={"Gregoria Gurog Destroyer","Gregoria"}, m={"Gurog","Gurog Soldiers"}, g=20, c="83.8N 4.3W", t="Cabin by the Frozen Valley", r=true},
  {q="Khaos Disciple Kill Task", f={"killtaskkhaodisciple"}, m={"Khaos Disciple"}, s="Conquest", r=true},
  {q="Kilif Zefir Kill Task", f={"killtaskkilifzefir","killtaskkilifzefirwait"}, n={"Hadiya bint Anan"}, m={"Kilif Zefir","Kilif Zefirs"}, g=35, c="33.7S 73.1E", r=true},
  {q="Magshuth Moarsmen Kill Task", f={"killtaskmagshuthmoarsman","killtaskmagshuthmoarsmanwait"}, n={"Faction Stronghold","Alderic"}, m={"Magshuth Moarsmen"}, g=20, r=true},
  {q="Weeding of the Deru Tree", f={"killtaskmcgreggortentacle_0908","killtaskmcgreggortentaclewait_0908","killtasktentacleoftthuun_0908","killtasktentacleoftthuunwait_0908"}, n={"Valerian McGreggor","Tamara du Cinghalle"}, m={"Slithis"}, g=50, c="62.0S 96.0E", t="Freebooter Isle", r=true},
  {q="Monthly Game Hunter", f={"killtaskmghabhorrenteater","killtaskmghharvestreaper","killtaskmghpyrechampion","killtaskmghremoran","killtaskmghtumerok","killtaskmghundeadsailor","killtaskmghvoraciouseater","killtaskmghvscarecrows","killtaskmghwasp","killtaskmghwightcaptain"}, n={"Rand Game Hunter","Rand"}, c="42.2N 33.9E", r=true},
  {q="Moguth Moarsman Kill Task", f={"killtaskmoguthmoarsman","killtaskmoguthmoarsmanwait"}, n={"Faction Stronghold","Alderic"}, m={"Moguth Moarsman"}, g=60, r=true},
  {q="Mosswart Townsfolk Kill Task", f={"killtaskmosswarttownsfolk_0507","killtaskmosswarttownsfolkwait_0507"}, n={"Corporal Massein"}, m={"Mosswart Townsfolk"}, g=40, c="74.4S 84.6E", t="Kryst", r=true},
  {q="Olthoi Drone Kill Task", f={"killtaskolthoidrone","killtaskolthoidronewait"}, n={"Olthoi Hunter"}, m={"Olthoi Drone","Olthoi Drones"}, g=20, c="30.9N 56.3E", t="Arwic", r=true},
  {q="Olthoi Nettler Kill Task", f={"killtaskolthoinettler","killtaskolthoinettlerwait"}, n={"Olthoi Hunter"}, m={"Olthoi Nettler","Olthoi Nettlers"}, g=10, c="30.9N 56.3E", t="Arwic", r=true},
  {q="Olthoi Nymph Kill Task", f={"killtaskolthoinymph","killtaskolthoinymphwait"}, n={"Olthoi Hunter"}, m={"Olthoi Nymph","Olthoi Nymphs"}, g=20, c="30.9N 56.3E", t="Arwic", r=true},
  {q="Killer Phyntos Wasp Kill Task", f={"killtaskphyntoskiller1109","killtaskphyntoskillerwait1109"}, n={"Khanldun"}, m={"Killer Phyntos Wasp"}, g=50, c="63.1S 97.5E", t="Freebooter Phyntos Wasp Hive", r=true},
  {q="Phyntos Larva Kill Task", f={"killtaskphyntoslarvae1109","killtaskphyntoslarvaewait1109"}, n={"Alderic"}, m={"Phyntos Larva"}, g=20, c="63.1S 97.5E", t="Freebooter Phyntos Wasp Hive", r=true},
  {q="Putrid Moar Kill Task", f={"killtaskputridmoar_0307","killtaskputridmoarstarted_0307","killtaskputridmoarwait_0307","spiketoothshead_pickuptimer"}, n={"Tibik"}, m={"Putrid Moar","Putrid Moars"}, g=25, r=true},
  {q="Tenebrous Rift Kill Task", f={"killtaskrifttenebrous0907","killtaskrifttenebrouswait0907"}, n={"Solange"}, m={"Tenebrous Rift","Tenebrous Rifts"}, g=350, c="97.4S 94.6W", r=true},
  {q="Umbral Rift Kill Task", f={"killtaskriftumbral0907","killtaskriftumbralwait0907"}, n={"Solange"}, m={"Umbral Rift","Umbral Rifts"}, g=30, c="97.4S 94.6W", s="Conquest", r=true},
  {q="Ruschk Kill Task", f={"killtaskruschk_0301","receivedsmallicetotem"}, n={"Commander Rylane"}, m={"Ruschk"}, c="93.2N 48.2W", t="Shattered Outlands", r=true},
  {q="Rynthid Crystal Kill Task", f={"killtaskrynthidcrystals","killtaskrynthidcrystalswait"}, n={"Lohrn"}, m={"Rynthid Crystal"}, c="61.6S 63.3W", r=true},
  {q="Kill: Rynthid Minions", f={"killtaskrynthidminions0813","killtaskrynthidminionscompleted0813"}, n={"Marcus"}, m={"Rynthid Minions"}, g=25, c="61.6S 63.3W", r=true},
  {q="Kill: Rynthid Ragers", f={"killtaskrynthidragercompleted0813","killtaskrynthidragers0813"}, n={"Ranulf"}, m={"Rynthid Ragers"}, g=15, c="61.6S 63.3W", r=true},
  {q="Kill: Rynthid Rare Boss", f={"killtaskrynthidrares0813","killtaskrynthidrarescompleted0813"}, n={"Hernd"}, m={"Rynthid Berserker"}, g=1, c="61.6S 63.3W", r=true},
  {q="Kill: Rynthid Rifts", f={"killtaskrynthidriftcompleted0813","killtaskrynthidrifts0813"}, n={"Rhys"}, m={"Rynthid Rifts"}, g=10, c="61.6S 63.3W", r=true},
  {q="Kill: Rynthid Slayers", f={"killtaskrynthidslayercompleted0813","killtaskrynthidslayers0813"}, n={"Sylvanus"}, m={"Rynthid Slayers"}, g=15, c="61.6S 63.3W", r=true},
  {q="Kill: Rynthid Sorcerers", f={"killtaskrynthidsorcerercompleted0813","killtaskrynthidsorcerers0813"}, n={"Wido"}, m={"Rynthid Sorcerers"}, g=15, c="61.6S 63.3W", r=true},
  {q="Kill: Empowered Wisps", f={"killtaskrynthidwisps0813","killtaskrynthidwispscompleted0813"}, n={"Tillahan"}, m={"Empowered Wisps"}, g=3, c="61.6S 63.3W", r=true},
  {q="Sawato Extortion", f={"killtasksawatobandit"}, n={"Sergeant Huang","Unfriendly Barkeeper","Trap Door"}, c="28.9S 59.3E", t="Sawato", r=true},
  {q="Kill Task Sawato Red Dragon", f={"killtasksawatoreddrag","killtasksawatoreddragwait"}, s="Conquest", r=false},
  {q="Shadow Assault", f={"killtaskshadowvortex","killtaskshadowvortexcompleted","killtasksoldier","killtasksoldiercompleted"}, n={"Isin Dule","the","Shadow Captain"}, c="33.4N 56.9E", t="Arwic", r=true},
  {q="Shoguth Moarsman Kill Task", f={"killtaskshoguthmoarsman","killtaskshoguthmoarsmanwait"}, n={"Faction Stronghold","Gavin Hammerstone"}, m={"Shoguth Moarsman","Shoguth Moarsmen"}, g=40, r=true},
  {q="kill counter", f={"killtaskshoreking"}, s="Conquest", r=false},
  {q="Shore King Kill Task", f={"killtaskshorekingwait"}, m={"Shore King"}, s="Conquest", r=true},
  {q="Small Fledgling Mukkir Kill Task", f={"killtasksmallfledglingmukkir0806","killtasksmallfledglingmukkircompleted0806"}, n={"Royal Guard"}, m={"Small Fledgling Mukkir","Small Fledgling Mukkirs"}, g=15, c="43.5N 36.1E", t="Holtburg", r=true},
  {q="Spectral Archer Kill Task", f={"killtaskspectralarchers0812","killtaskspectralarcherscompleted0812"}, n={"Sergeant Trebuus"}, m={"Spectral Archer","Spectral Archers"}, g=15, c="80.7N 43.0W", r=true},
  {q="Spectral Mage Kill Task", f={"killtaskspectralbloodmages0812","killtaskspectralbloodmagescompleted0812"}, n={"Lord Eorlinde"}, m={"Spectral Mage","Spectral Bloodmages"}, g=5, c="80.7N 43.0W", r=true},
  {q="Spectral Bushi Kill Task", f={"killtaskspectralbushi0812","killtaskspectralbushicompleted0812"}, n={"Corporal Irashi"}, m={"Spectral Bushi","Spectral Bushis"}, g=10, c="80.7N 43.0W", t="Royal Tent", r=true},
  {q="Spectral Blade and Claw Kill Task", f={"killtaskspectralclawsblades0812","killtaskspectralclawsbladescompleted0812"}, n={"Griffon"}, m={"Spectral Blade and Claw","Spectral Claws"}, g=10, c="80.7N 43.0W", r=true},
  {q="Spectral Minion Kill Task", f={"killtaskspectralminions0812","killtaskspectralminionscompleted0812"}, n={"Aun Kirtal"}, m={"Spectral Minion","Spectral Minions"}, g=15, c="80.7N 43.0W", r=true},
  {q="Spectral Nanjou Shou-jen Kill Task", f={"killtaskspectralninjas0812","killtaskspectralninjascompleted0812"}, n={"Hanamoto Aki'ko"}, m={"Spectral Nanjou Shou-jen"}, g=5, c="80.7N 43.0W", r=true},
  {q="Spectral Samurai Kill Task", f={"killtaskspectralsamurai0812","killtaskspectralsamuraicompleted0812"}, n={"Lieutenant Takamaki"}, m={"Spectral Samurai","Spectral Samurais"}, g=10, c="80.7N 43.0W", r=true},
  {q="Torgash's Tasks", f={"killtasktorgashstasks_0301"}, n={"Torgash"}, m={"Viamontian Knights"}, g=30, c="94.0N 45.9W", t="Shattered Outlands", r=true},
  {q="Tou-Tou Blockade", f={"killtasktoutoublockade","killtasktoutoublockadecompleted","killtasktoutoutownsfolk","killtasktoutoutownsfolkcompleted"}, n={"Isin Dule"}, m={"Tou-Tou"}, g=5, c="33.4N 56.9E", t="Arwic", r=true},
  {q="Shadow Flyer Kill Task", f={"killtasktoutouflyers0812","killtasktoutouflyerscompleted0812"}, n={"Umbral Guard"}, m={"Shadow Flyer","Shadow Flyers"}, g=15, r=true},
  {q="Grievver Shredder Kill Task", f={"killtasktoutougrievvers0812","killtasktoutougrievverscompleted0812"}, n={"Royal Guard"}, m={"Grievver Shredder","Grievver Shredders"}, g=15, c="30.3S 94.8E", t="Tou-Tou Outpost", r=true},
  {q="Void Lord Kill Task", f={"killtasktoutouknights0812","killtasktoutouknightscompleted0812"}, n={"Royal Guard"}, m={"Void Lord","Void Lords"}, g=15, c="30.3S 94.8E", t="Tou-Tou Outpost", r=true},
  {q="Devourer Margul Kill Task", f={"killtasktoutoumarguls0812","killtasktoutoumargulscompleted0812"}, n={"Umbral Guard"}, m={"Devourer Margul","Devourer Marguls"}, g=15, c="30.3S 94.8E", t="Tou-Tou Outpost", r=true},
  {q="Shadowy Pillar Kill Task", f={"killtasktoutoupillars0812","killtasktoutoupillarscompleted0812"}, n={"Royal Guard"}, m={"Shadowy Pillar"}, c="0.3S 94.8E", r=true},
  {q="Shadow Kill Task", f={"killtasktoutoushadows0812","killtasktoutoushadowscompleted0812"}, n={"Royal Guard"}, m={"Shadow","Shadows"}, g=25, c="30.2S 94.8E", t="Tou-Tou Outpost", r=true},
  {q="Tumerok Gladiator Kill Task", f={"killtasktumerokgladiator","killtasktumerokgladiatorwait"}, n={"Lieutenant Rothe","Lietenant Rothe"}, m={"Tumerok Gladiator","Tumerok Gladiators"}, g=25, c="8.2S 73.1E", t="Dryreach", r=true},
  {q="Umberclaw Ripper Kill Task", f={"killtaskumberclawripper","killtaskumberclawripperwait"}, m={"Umberclaw Ripper"}, s="Conquest", r=false},
  {q="Viridian A'nekshen Kill Task", f={"killtaskviridiananek","killtaskviridiananekwait"}, n={"Brellegia"}, m={"Viridian A'nekshen","A'nekshen"}, g=10, c="42.4S 43.0E", t="Viridian Rise", r=true},
  {q="Viridian Gromnie Kill Task", f={"killtaskviridiangrom","killtaskviridiangromwait"}, m={"Viridian Gromnie"}, s="Conquest", r=false},
  {q="Viridian Oak Kill Task", f={"killtaskviridianoak","killtaskviridianoakwait"}, m={"Viridian Oak"}, s="Conquest", r=false},
  {q="Viridian Wasp Kill Task", f={"killtaskviridianwasp","killtaskviridianwaspwait"}, n={"Aangesilus' Marker","Aangesilus"}, m={"Viridian Wasp"}, c="43.1S 41.9E", t="Viridian Rise", r=true},
  {q="Viridian Wisp Kill Task", f={"killtaskviridianwisp","killtaskviridianwispwait"}, m={"Viridian Wisp"}, s="Conquest", r=false},
  {q="Viridian Zefir Kill Task", f={"killtaskviridianzefir","killtaskviridianzefirwait"}, n={"Swift"}, m={"Viridian Zefir","Viridian Zefirs"}, g=10, c="42.3S 43.5E", t="Viridian Rise", r=true},
  {q="K'nath An'dras Kill Task", f={"knathandraskillcount","knathandraskilltask"}, n={"Nona"}, m={"K'nath An'dras"}, g=25, c="61.8S 51.3W", t="Wai Jhou", r=true},
  {q="Littoral Siraluun Kill Task", f={"littoralsiraluunkillcount","littoralsiraluunkilltask"}, n={"Rico Cellini"}, m={"Littoral Siraluun"}, g=25, r=true},
  {q="Mosswart Worshipper Kill Task", f={"mosswartworshipperkillcount","mosswartworshipperkilltask"}, n={"Orfeo Orlando"}, m={"Mosswart Worshipper","Mosswart Worshippers"}, g=175, c="90.2N 43.1W", t="Eastwatch", r=true},
  {q="Mottled Carenzi Kill Task", f={"mottledcarenzikillcount","mottledcarenzikilltask"}, n={"Grania the Bold"}, m={"Mottled Carenzi","Mottled Carenzis"}, g=50, c="87.6S 67.4W", t="Candeth Keep", r=true},
  {q="Mucky Moarsman Kill Task", f={"muckymoarsmankillcount","muckymoarsmankilltask"}, n={"Algar Oreksun"}, m={"Mucky Moarsman"}, g=50, c="77.8N 67.1E", r=true},
  {q="Naughty Skeleton Kill Task", f={"naughtyskeletonkillcount","naughtyskeletonkilltask"}, n={"Taku Yukio"}, m={"Naughty Skeleton","Naughty Skeletons"}, g=100, c="90.3N 43.1W", t="Eastwatch", r=true},
  {q="Nyr'leha Moarsman Kill Task", f={"nyrlehamoarsmankillcount","nyrlehamoarsmankilltask"}, n={"Kagami","Bayani"}, m={"Nyr'leha Moarsman"}, r=true},
  {q="Nyr'leha Sclavus Kill Task", f={"nyrlehasclavuskillcount","nyrlehasclavuskilltask"}, n={"Bayami"}, m={"Nyr'leha Sclavus"}, r=true},
  {q="Olthoi Ripper Kill Task", f={"olthoiripperkillcount","olthoiripperkilltask"}, n={"Marcello"}, m={"Olthoi Ripper","Olthoi Rippers"}, g=250, c="90.2N 43.1W", t="Eastwatch", r=true},
  {q="Paradox-touched Grub Kill Task", f={"paradoxgrubkilltask","paradoxgrubkilltaskwait"}, n={"Alicia Swiftblade"}, m={"Paradox-touched Grub","Paradox-touched Olthoi Grubs"}, g=50, c="43.8N 54.9E", t="Olthoi North", r=true},
  {q="Paradox-touched Nymph Kill Task", f={"paradoxnymphkilltask","paradoxnymphkilltaskwait"}, n={"Tomihino"}, m={"Paradox-touched Nymph","Paradox-touched Olthoi Nymphs"}, g=50, c="43.8N 54.9E", t="Olthoi North", r=true},
  {q="Pillar Hellfire Kill Task", f={"pillarhellfirekillcount","pillarhellfirekilltaskwait"}, n={"Royal Guard"}, m={"Pillars of Hellfire"}, d="Fort Pillars of Hellfire", g=5, c="10.1S 63.9W", t="Tou-Tou fort", a="Tou-Tou", w=43370056, s="Conquest", r=true},
  {q="Plate Armoredillo Kill Task", f={"platearmoredillokillcount","platearmoredillokilltask"}, n={"Saqr"}, m={"Plate Armoredillo","Plate Armoredillos"}, g=25, c="1.5N 71.8W", t="Fort Tethana", r=true},
  {q="Polardillo Kill Task", f={"polardillokills","polardillotask"}, n={"Alessandro Mardor"}, m={"Polardillo","Polardillos"}, g=10, c="72.0N 61.2W", t="Sanamar", r=true},
  {q="Polar Ursuin Kill Task", f={"polarursuin","polarursuinkillcount"}, n={"Mariabella Varanese"}, m={"Polar Ursuin","Polar Ursuins"}, g=25, c="95.6N 56.3W", t="Fiun Outpost", r=true},
  {q="Remoran Sea Raptor Kill Task", f={"remoransearaptorkillcount","remoransearaptorkilltask"}, n={"Peng-Ya"}, m={"Remoran Sea Raptor","Remoran Sea Raptors"}, g=50, c="77.8N 67.1E", r=true},
  {q="Repugnant Eater Kill Task", f={"repugeaterkillcount","repugnanteaterkilltask"}, n={"Xun Yu"}, m={"Repugnant Eater","Repugnant Eaters"}, g=50, c="90.2N 43.1W", r=true},
  {q="Assassin's Roost Quest", f={"roostcarenzikillcount","roostratkillcount"}, n={"Collector","Lander","Maniel"}, r=true},
  {q="Sarcophagus Kill Task", f={"sarcophaguskillcount","sarcophaguskilltask"}, n={"Sergeant Freng"}, m={"Sarcophagus"}, c="7.0N 43.0W", r=true},
  {q="Scavenger Hunt (Feb): Blood Of The Hopeslayer", f={"scav_hunt_feb_2038909bloodofthehopeslayer"}, s="Levistras", r=false},
  {q="Harbinger Quest", f={"sclavusslayer"}, n={"Issk"}, r=false},
  {q="Shadow-touched Virindi Paradox Kill Task", f={"shadowtouchedvirindiparadoxkillcount","shadowtouchedvirindiparadoxkilltask"}, n={"Guard Li"}, m={"Shadow-touched Virindi Paradox","Shadow-touched Virindi Paradoxes"}, g=75, c="61.8S 51.3W", t="Wai Jhou", r=true},
  {q="Shadow-touched Virindi Quidiox Kill Task", f={"shadowtouchedvirindiquidioxkillcount","shadowtouchedvirindiquidioxkilltask"}, n={"Guard Alfric"}, m={"Shadow-touched Virindi Quidiox","Shadow-touched Virindi Quidioxes"}, g=75, c="87.9S 67.4W", t="Candeth Keep", r=true},
  {q="Shallows Gorger Kill Task", f={"shallowsgorgerkillcount","shallowsgorgerkilltask"}, n={"Dayla Bint Kazm"}, m={"Shallows Gorger","Shallows Gorgers"}, g=50, c="77.8N 67.1E", r=true},
  {q="Silver Scope Trooper Kill Task", f={"silverscopetrooperkillcount","silverscopetrooperkilltask"}, n={"Lieutenant Faen"}, m={"Silver Scope Trooper","Silver Scope Troopers"}, g=25, c="22.4S 0.2E", t="Yaraq to Ijaniya portal", r=true},
  {q="Sishalti Slithis Kill Task", f={"sishaltislithiskillcount","sishaltislithiskilltask"}, n={"Zava bint Laurma","Zava Bint Laurma"}, m={"Sishalti Slithis"}, g=150, c="12.6S 46.7E", r=true},
  {q="Snow Tusker Kill Task", f={"snowtuskerkillcount","snowtuskerkillleadercount","snowtuskerkillleadertask","snowtuskerkilltask","snowtuskerkillwarriorcount","snowtuskerkillwarriortask"}, n={"Hunter"}, m={"Snow Tusker","Snow Tuskers"}, g=20, c="83.8N 4.3W", t="Frozen Valley", r=true},
  {q="Tanada Slaughter", f={"tanadaslaughterkilltask_0912"}, n={"Kousha","Kinchou"}, m={"Tanada Neophytes"}, g=6, c="78.4N 40.5W", t="Hoshino Town #3", r=true},
  {q="Defeating Vaeshok", f={"taskdiruschkbosskilltask","taskdiruschkbosskilltaskwait"}, n={"Faction Stronghold NPC","Takahara Masikawa"}, c="86.9N 59.7E", t="Dark Isle", r=true},
  {q="Blessed Moarsman Kill Task", f={"taskfreebootermoarsmankilltask","taskfreebootermoarsmankilltaskwait"}, n={"Kieran Stronghammer"}, m={"Blessed Moarsman","Blessed Moarsmen"}, g=50, r=true},
  {q="Wight Blade Sorcerer Kill Task", f={"taskgrave1wightmagekilltask","taskgrave1wightmagewait"}, n={"Mashira bint Tamur","Zumaq","Idaris bint Qumal"}, m={"Wight Blade Sorcerer"}, r=true},
  {q="Tukora Lieutenant Kill Task", f={"tukoralieutenantkillcount","tukoralieutenantkilltask"}, n={"Claire Artmad"}, m={"Tukora Lieutenant","Tukora Lieutenants"}, g=250, c="90.2N 43.1W", t="Eastwatch", r=true},
  {q="Tusker Guard Kill Task", f={"tuskerg","tuskergkillcount"}, n={"Shoichi"}, m={"Tusker Guard","Tusker Guards"}, g=500, c="54.4S 72.9E", r=true},
  {q="Viamontian Man-at-Arms Kill Task", f={"viamontianmanatarmskillcount","viamontianmanatarmskilltask"}, n={"Robert Gutsmasher"}, m={"Viamontian Man-at-Arms"}, g=50, c="43.9N 73.9W", t="Marae Lassel", r=true},
  {q="Virindi Paradox Kill Task", f={"virindiparadoxkillcount","virindiparadoxkilltask"}, n={"Guard Taziq"}, m={"Virindi Paradox"}, g=75, c="74.3S 19.1E", r=true},
  {q="Virindi Quidiox Kill Task", f={"virindiquidioxkillcount","virindiquidioxkilltask"}, n={"Guard Q'alia"}, m={"Virindi Quidiox","Shadow-touched Virindi Quidioxes"}, g=75, c="60.0S 88.0W", r=true},
  {q="Voracious Eater Kill Task", f={"voraciouseaterkillcount","voraciouseaterkilltask"}, n={"Aun Ruperea"}, m={"Voracious Eater","Voracious Eaters"}, g=50, c="44.3N 77.9W", t="Timaru", r=true},
  {q="Wicked Skeleton Kill Task", f={"wickedskeletonkillcount","wickedskeletonkilltask"}, n={"Ruqaya al Mubarak"}, m={"Wicked Skeleton","Wicked Skeletons"}, g=100, c="90.3N 43.1W", t="Eastwatch", r=true},
}

local TASKS = {
  {area="Hoshino", name="Golem Samurais", npc=46678, flag="killtaskgolemsamurai0812", done_flag="killtaskgolemsamuraicompleted0812", mobs={"Bronze Golem Samurai", "Clay Golem Samurai", "Iron Golem Samurai"}},
  {area="Hoshino", name="Sarcophagi", npc=52294, flag="sarcophaguskillcount", done_flag="sarcophaguskilltask", mobs={"Sarcophagus"}},
  {area="Hoshino", name="Spectral Archers", npc=46679, flag="killtaskspectralarchers0812", done_flag="killtaskspectralarcherscompleted0812", mobs={"Spectral Archer"}},
  {area="Hoshino", name="Spectral Bushis", npc=46681, flag="killtaskspectralbushi0812", done_flag="killtaskspectralbushicompleted0812", mobs={"Spectral Bushi"}},
  {area="Hoshino", name="Spectral Claws", npc=46682, flag="killtaskspectralclawsblades0812", done_flag="killtaskspectralclawsbladescompleted0812", mobs={"Spectral Blade Adept", "Spectral Blade Master", "Spectral Claw Adept", "Spectral Claw Master", "Claw Master Gatekeeper"}},
  {area="Hoshino", name="Spectral Mages", npc=46680, flag="killtaskspectralbloodmages0812", done_flag="killtaskspectralbloodmagescompleted0812", mobs={"Spectral Voidmage", "Spectral Bloodmage"}},
  {area="Hoshino", name="Spectral Minions", npc=46683, flag="killtaskspectralminions0812", done_flag="killtaskspectralminionscompleted0812", mobs={"Spectral Minion"}},
  {area="Hoshino", name="Spectral Nanjou Shou-jens", npc=46684, flag="killtaskspectralninjas0812", done_flag="killtaskspectralninjascompleted0812", mobs={"Spectral Nanjou Shou-jen"}},
  {area="Hoshino", name="Spectral Samurais", npc=46686, flag="killtaskspectralsamurai0812", done_flag="killtaskspectralsamuraicompleted0812", mobs={"Spectral Samurai"}},
  {area="Tou-Tou", name="Grievver Shredders", npc=46015, flag="killtasktoutougrievvers0812", done_flag="killtasktoutougrievverscompleted0812", mobs={"Grievver Shredder"}},
  {area="Tou-Tou", name="Shadowy Pillars", npc=52272, flag="killtasktoutoupillars0812", done_flag="killtasktoutoupillarscompleted0812", mobs={"Shadowy Pillar"}},
  {area="Tou-Tou", name="Void Lords", npc=46018, flag="killtasktoutouknights0812", done_flag="killtasktoutouknightscompleted0812", mobs={"Void Lord"}},
  {area="Tou-Tou", name="Panumbris Shadows", npc=46017, flag="killtasktoutoushadows0812", done_flag="killtasktoutoushadowscompleted0812", mobs={"Panumbris Shadow"}},
  {area="Tou-Tou", name="Shadow Flyers", npc=46014, flag="killtasktoutouflyers0812", done_flag="killtasktoutouflyerscompleted0812", mobs={"Shadow Flyer"}},
  {area="Tou-Tou", name="Devourer Marguls", npc=46016, flag="killtasktoutoumarguls0812", done_flag="killtasktoutoumargulscompleted0812", mobs={"Devourer Margul"}},
  {area="Rynthid", name="Rynthid Sorcerers", npc=51865, flag="killtaskrynthidsorcerers0813", done_flag="killtaskrynthidsorcerercompleted0813", mobs={"Rynthid Sorcerer", "Raging Rynthid Sorcerer"}},
  {area="Rynthid", name="Rynthid Rifts", npc=51866, flag="killtaskrynthidrifts0813", done_flag="killtaskrynthidriftcompleted0813", mobs={"Rift of Blind Rage", "Rift of Consuming Torment", "Rift of Torment", "Rift of Rage"}},
  {area="Rynthid", name="Rynthid Minions", npc=51862, flag="killtaskrynthidminions0813", done_flag="killtaskrynthidminionscompleted0813", mobs={"Rynthid Minion", "Rynthid Minion of Rage"}},
  {area="Rynthid", name="Rynthid Slayers", npc=51863, flag="killtaskrynthidslayers0813", done_flag="killtaskrynthidslayercompleted0813", mobs={"Rynthid Slayer"}},
  {area="Rynthid", name="Rynthid Rare Boss", npc=51861, flag="killtaskrynthidrares0813", done_flag="killtaskrynthidrarescompleted0813", mobs={"Rynthid Berserker", "Rynthid Ravager", "Aspect of Rage", "Aspect of Torment"}},
  {area="Rynthid", name="Rynthid Empowered Wisps", npc=51860, flag="killtaskrynthidwisps0813", done_flag="killtaskrynthidwispscompleted0813", mobs={"Empowered Sorrow Wisp", "Empowered Hatred Wisp", "Empowered Despair Wisp"}},
  {area="Rynthid", name="Rynthid Crystals", npc=52281, flag="killtaskrynthidcrystals", done_flag="killtaskrynthidcrystalswait", mobs={"Rynthid Crystal"}},
  {area="Rynthid", name="Rynthid Ragers", npc=51864, flag="killtaskrynthidragers0813", done_flag="killtaskrynthidragercompleted0813", mobs={"Rynthid Rager"}},
  {area="Graveyard", name="Graveyard Wisps", npc=51955, flag="killtaskgraveyardwisp_1309", done_flag="killtaskgraveyardwispwait_1309", mobs={"Despair Wisp", "Hatred Wisp", "Sorrow Wisp"}},
  {area="Graveyard", name="Graveyard Skeletons", npc=51957, flag="killtaskgraveyardskeleton_1309", done_flag="killtaskgraveyardskeletonwait_1309", mobs={"Pyre Minion", "Pyre Skeleton", "Pyre Champion"}},
  {area="Graveyard", name="Graveyard Wights", npc=51958, flag="killtaskgraveyardwight_1309", done_flag="killtaskgraveyardwightwait_1309", mobs={"Wight", "Wight Captain", "Wight Blade Sorcerer"}},
  {area="Graveyard", name="Graveyard Spirits", npc=51956, flag="killtaskgraveyardspirit_1309", done_flag="killtaskgraveyardspiritwait_1309", mobs={"Corrupted Dread", "Spectral Dread"}},
  {area="Graveyard", name="Grave Rats", npc=36236, flag="killtaskgraveyardgraverat_1107", done_flag="killtaskgraveyardgraveratwait_1107", mobs={"Grave Rat"}},
  {area="Graveyard", name="Guardian Statues", npc=42030, flag="killtaskguardianstatue", done_flag="killtaskguardianstatuewait", mobs={"Guardian Statue"}},
  {area="Viridian Rise", name="Zefir Thorns", npc=53283, flag="killtaskviridianzefir", done_flag="killtaskviridianzefirwait", mobs={"Zefir Thorn Poisoner", "Zefir Thorn Ranger", "Zefir Thorn Reaver", "Zefir Thorn Stalker"}},
  {area="Viridian Rise", name="Brier Wasps", npc=53281, flag="killtaskviridianwasp", done_flag="killtaskviridianwaspwait", mobs={"Brier Wasp Swarm", "Poisonous Brier Wasp", "Venomous Brier Wasp"}},
  {area="Viridian Rise", name="A'nekshens", npc=53280, flag="killtaskviridiananek", done_flag="killtaskviridiananekwait", mobs={"A'nekshen Storm Caller", "A'nekshen Storm Reaver", "A'nekshen Thorn Dancer", "A'nekshen Thorn Reaver", "A'nekshen Tender", "A'nekshen Caretaker"}},
  {area="Frozen Valley", name="Gurog Minions", npc=43495, flag="killtaskgurogminion1110", done_flag="killtaskgurogminioncompleted1110", mobs={"Gurog Minion"}},
  {area="Frozen Valley", name="Gurog Henchmen", npc=43495, flag="killtaskguroghenchman1110", done_flag="killtaskguroghenchmancompleted1110", mobs={"Gurog Henchman"}},
  {area="Frozen Valley", name="Gurog Soldiers", npc=43495, flag="killtaskgurogsoldier1110", done_flag="killtaskgurogsoldiercompleted1110", mobs={"Gurog Soldier"}},
  {area="Frozen Valley", name="Snow Tuskers", npc=43740, flag="snowtuskerkillcount", done_flag="snowtuskerkilltask", mobs={"Snow Tusker"}},
  {area="Frozen Valley", name="Snow Tusker Warriors", npc=43740, flag="snowtuskerkillwarriorcount", done_flag="snowtuskerkillwarriortask", mobs={"Snow Tusker Warrior"}},
  {area="Frozen Valley", name="Snow Tusker Leaders", npc=43740, flag="snowtuskerkillleadercount", done_flag="snowtuskerkillleadertask", mobs={"Snow Tusker Leader"}},
  {area="Frozen Valley", name="Frost Golems", npc=51959, flag="frostgolemkillcount", done_flag="frostgolemkilltask", mobs={"Frost Golem"}},
  {area="Frozen Valley", name="Frozen Dreads", npc=51960, flag="frozendreadkillcount", done_flag="frozendreadkilltask", mobs={"Frozen Dread"}},
  {area="Frozen Valley", name="Frozen Crystals", npc=52286, flag="frozencrystalkillcount", done_flag="frozencrystalkilltask", mobs={"Frozen Crystal"}},
  {area="Frozen Valley", name="Frozen Wights", npc=51961, flag="frozenwightkillcount", done_flag="frozenwightkilltask", mobs={"Frozen Wight", "Frozen Wight Sorcerer", "Frozen Wight Captain", "Frozen Wight Archer", "Frozen Wight High Acolyte"}},
  {area="Neftet", name="Reedsharks", npc=44263, flag="killtaskdesertareareedshark_0511", done_flag="killtaskdesertareareedsharkwait_0511", mobs={"War Reaper", "Reedshark Seeker", "Tamed Reaper", "Reedshark Hunter"}},
  {area="Neftet", name="Mumiyahs", npc=44262, flag="killtaskdesertareamumiyah_0511", done_flag="killtaskdesertareamumiyahwait_0511", mobs={"Mu-miyah Vizier", "Mu-miyah Lord", "Mu-miyah Soldier", "Mu-miyah Champion", "Mu-miyah Guardian", "Mu-miyah Channeller", "Mu-miyah Soothsayer", "Mu-miyah Sentinel", "Mu-miyah Grand Vizier"}},
  {area="Neftet", name="Golems", npc=44261, flag="killtaskdesertareagolem_0511", done_flag="killtaskdesertareagolemwait_0511", mobs={"Burning Sands Golem", "Dust Golem"}},
  {area="Neftet", name="Armoredillos", npc=44260, flag="killtaskdesertareaarmoredillo_0511", done_flag="killtaskdesertareaarmoredillowait_0511", mobs={"War Armoredillo", "Tamed Armoredillo", "Guardian Armoredillo"}},
  {area="Neftet", name="Desert Cacti", npc=52289, flag="desertcactuskillcount", done_flag="desertcactuskilltask", mobs={"Desert Cactus"}},
}

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
-- Areas: the built-in hunting areas, then areas you add (saved in the task
-- database for this server), then Other.
local BASE_AREAS = {"Hoshino", "Tou-Tou", "Rynthid", "Graveyard", "Viridian Rise", "Frozen Valley", "Neftet"}
local AREAS = {"Hoshino", "Tou-Tou", "Rynthid", "Graveyard", "Viridian Rise", "Frozen Valley", "Neftet", "Other"}
local VIEWS = {"Hoshino", "Tou-Tou", "Rynthid", "Graveyard", "Viridian Rise", "Frozen Valley", "Neftet", "Other"}
local AREA_SET = {Other = true}
for _, a in ipairs(BASE_AREAS) do AREA_SET[a] = true end
local COLORS = {"yellow", "green", "red", "blue", "white", "purple"}
local MYQ_MIN_GAP = 60  -- the server answers @myquests at most once per 60 s
local MYQ_HIDE = 60     -- seconds our quest-list reply is hidden from chat
local NAV_MOVE_M, NAV_MIN_S = 10, 3  -- re-aim NAV when the target moved this far, at most this often
local KILL_WORDS = {"killtask", "killcount", "slayerquest", "kills", "cull"}
local DEFAULT_OPT = {
  view = "", show_nav = true, npc_marks = true, auto_myq = true, myq_s = 65, myq_hide = true,
  range = 150, cooldown_hours = 20,
  col_available = "yellow", col_progress = "white", col_turnin = "green", col_cooldown = "red",
}
local DB_GROUP, DB_NAME = "Database", "KillTaskDB"
local QUEST_GROUP = "Quests"

-- ACE only runs chat commands that start with "@" (the chat box turns "/" into "@").
local MYQUESTS = "@myquests"
local MAX_ROWS = 14
-- Text sizes: body 13 (labels of text, buttons, checkboxes, fields, sections),
-- details and notes 11. Field contents and dropdown values keep the client's size.
local TXT = {small = 11, body = 13}  -- one table: the main chunk is limited to 200 locals

---------------------------------------------------------------------------
-- Helpers (no string.find/match/gsub in the sandbox)
---------------------------------------------------------------------------
local function contains(hay, needle)
  return type(hay) == "string" and #hay <= 4096 and #needle <= 256 and string.contains(hay, needle)
end
-- Whole numbers for display: saved state comes back as floats ("4.0").
local function int(x)
  x = tonumber(x)
  if not x then return nil end
  return math.floor(x + 0.5)
end
local function trim(s)
  local a, b = 1, #s
  while a <= b and string.byte(s, a) <= 32 do a = a + 1 end
  while b >= a and string.byte(s, b) <= 32 do b = b - 1 end
  return string.sub(s, a, b)
end
local function split_commas(s)
  local out, cur = {}, ""
  for i = 1, #s do
    local c = string.sub(s, i, i)
    if c == "," then cur = trim(cur); if #cur > 0 then out[#out + 1] = string.lower(cur) end; cur = ""
    else cur = cur .. c end
  end
  cur = trim(cur); if #cur > 0 then out[#out + 1] = string.lower(cur) end
  return out
end
local function slug(s)
  local out = ""
  for i = 1, math.min(#s, 40) do
    local c = string.lower(string.sub(s, i, i))
    local b = string.byte(c)
    if (b >= 97 and b <= 122) or (b >= 48 and b <= 57) then out = out .. c end
  end
  return out
end
-- Singular forms a plural ("Drift-Touched Tuskers") may come from.
local singulars
singulars = function(plural, head_only)
  local p = string.lower(trim(plural))
  local f = {p}
  -- "pillars of hellfire" -> "pillar of hellfire": the plural is on the first word.
  if not head_only and string.contains(p, " of ") then
    local m = regexmatch(p, "^(.+?) of (.+)$")
    if m then
      local h = singulars(m["1"], true)
      for i = 2, #h do f[#f + 1] = h[i] .. " of " .. m["2"] end
    end
  end
  local function add(x) if #x > 0 then f[#f + 1] = x end end
  if string.sub(p, -1) == "s" then add(string.sub(p, 1, -2)) end
  if string.sub(p, -2) == "es" then add(string.sub(p, 1, -3)) end
  if string.sub(p, -3) == "ies" then add(string.sub(p, 1, -4) .. "y") end
  if string.sub(p, -3) == "ves" then add(string.sub(p, 1, -4) .. "f"); add(string.sub(p, 1, -4) .. "fe") end
  if string.sub(p, -1) == "i" then add(string.sub(p, 1, -2) .. "us") end
  if string.sub(p, -3) == "men" then add(string.sub(p, 1, -4) .. "man") end
  return f
end
local DIRS = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
local function global_xy(p)
  if type(p) ~= "table" or type(p.cell) ~= "number" then return nil end
  local cell = math.floor(p.cell)
  return ((cell // 16777216) % 256) * 192 + (tonumber(p.x) or 0), ((cell // 65536) % 256) * 192 + (tonumber(p.y) or 0)
end
local function compass(from, to)
  local fx, fy = global_xy(from); local tx, ty = global_xy(to)
  if not fx or not tx then return "" end
  local dx, dy = tx - fx, ty - fy
  if dx * dx + dy * dy < 4 then return "here" end
  local deg = math.deg(math.atan(dx, dy)); if deg < 0 then deg = deg + 360 end
  return DIRS[(math.floor((deg + 22.5) / 45) % 8) + 1]
end
-- Map coordinates (NS, EW) of an outdoor position; nil inside dungeons/buildings.
local function dist(a, b)
  local ax, ay = global_xy(a); local bx, by = global_xy(b)
  if not ax or not bx then return 1e9 end
  return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end
local function dur(sec)
  sec = math.max(0, math.floor(sec))
  local d, h, m = sec // 86400, (sec % 86400) // 3600, (sec % 3600) // 60
  if d > 0 then return d .. "d " .. h .. "h" end
  if h > 0 then return h .. "h " .. m .. "m" end
  if m > 0 then return m .. "m" end
  return sec .. "s"
end
-- "19h 59m 3s" / "1d 2h" / "45m 10s" -> seconds
local function parse_duration(text)
  local total, num, found = 0, nil, false
  local i = 1
  while i <= #text do
    local b = string.byte(text, i)
    if b >= 48 and b <= 57 then
      num = (num or 0) * 10 + (b - 48)
    else
      if num then
        local u = string.lower(string.sub(text, i, i))
        local mult = (u == "d" and 86400) or (u == "h" and 3600) or (u == "m" and 60) or (u == "s" and 1) or nil
        if mult then total = total + num * mult; found = true end
        num = nil
      end
    end
    i = i + 1
  end
  return found and total or nil
end
local function is_kill_key(key)
  for _, w in ipairs(KILL_WORDS) do if contains(key, w) then return true end end
  return false
end

---------------------------------------------------------------------------
-- Built-in tasks (Aunberean data) keyed by their counter quest flag
---------------------------------------------------------------------------
local BASE, BASE_ORDER, BY_DONE = {}, {}, {}
for _, t in ipairs(TASKS) do
  local mobs = {}
  for _, m in ipairs(t.mobs) do mobs[#mobs + 1] = string.lower(m) end
  BASE[t.flag] = {name = t.name, area = t.area, mobs = mobs, wcid = t.npc, key = t.flag, done = t.done_flag}
  BASE_ORDER[#BASE_ORDER + 1] = t.flag
  BY_DONE[t.done_flag] = t.flag
end

---------------------------------------------------------------------------
-- Kill-task catalog (Oracle of Dereth quests.csv): quest names, quest givers,
-- locations, kill counts and every quest flag a task uses. Built-in tasks gain
-- their givers' names; the rest become "Other" tasks keyed by their counter flag.
---------------------------------------------------------------------------
local CAT, CAT_BY_FLAG = {}, {}
-- "30.3S 94.8E" -> global metres (the same grid as global_xy); nil if unreadable.
local function coords_xy(c)
  if type(c) ~= "string" then return nil end
  local nums, dirs, num, frac, scale = {}, {}, nil, false, 1
  for i = 1, #c + 1 do
    local ch = string.sub(c, i, i)
    local b = string.byte(ch) or 32
    if b >= 48 and b <= 57 then
      num = num or 0
      if frac then scale = scale / 10; num = num + (b - 48) * scale else num = num * 10 + (b - 48) end
    elseif ch == "." and num then frac = true
    else
      if num then nums[#nums + 1] = num; num, frac, scale = nil, false, 1 end
      local u = string.upper(ch)
      if u == "N" or u == "S" or u == "E" or u == "W" then dirs[#dirs + 1] = u end
    end
  end
  if #nums < 2 or #dirs < 2 then return nil end
  local ns = nums[1] * (dirs[1] == "S" and -1 or 1)
  local ew = nums[2] * (dirs[2] == "W" and -1 or 1)
  return {(ew + 101.95) * 240, (ns + 101.95) * 240}
end
-- Catalog quests that are kill tasks by name; others (multi-step quests with a
-- kill step, e.g. The Crystal Idol of the A'nekshay) never mark their NPCs.
local function kill_task_named(q)
  q = string.lower(q or "")
  return string.contains(q, "kill") or string.contains(q, "slaughter") or string.contains(q, "hunting") or string.contains(q, "task")
end
-- Giver names shared by several NPCs: they mark an NPC only when its weenie
-- class (or the catalog location) also matches.
local SHARED = {["royal guard"] = true, ["umbral guard"] = true, ["hunter"] = true, ["guard"] = true, ["sentry"] = true,
  ["collector"] = true, ["emissary"] = true, ["emissary of asheron"] = true, ["the"] = true, ["lever"] = true}
do
  local seen = {}
  for _, e in ipairs(CATALOG) do
    for _, n in ipairs(e.n or {}) do
      local k = string.lower(n)
      local where = e.c or "?"
      if seen[k] and seen[k] ~= where then SHARED[k] = true end
      seen[k] = seen[k] or where
    end
  end
end
local function flag_role(f)
  if contains(f, "wait") or contains(f, "completed") or contains(f, "timer")
     or string.sub(f, -8) == "killtask" or string.sub(f, -4) == "task" then return "done" end
  if contains(f, "start") then return "start" end
  return "counter"
end
for _, e in ipairs(CATALOG) do
  local counter, done
  for _, f in ipairs(e.f) do
    local r = flag_role(f)
    if r == "counter" and not counter then counter = f elseif r == "done" and not done then done = f end
  end
  -- One catalog quest can hold several built-in tasks (Snow Tuskers, Snow Tusker
  -- Warriors and Snow Tusker Leaders share the Hunter's quest): every one of
  -- them gets the giver and location, not only the last one listed.
  local base_id, bases, in_bases = nil, {}, {}
  for _, f in ipairs(e.f) do
    local b_id = BASE[f] and f or BY_DONE[f]
    if b_id then
      base_id = b_id
      if not in_bases[b_id] then in_bases[b_id] = true; bases[#bases + 1] = b_id end
    end
  end
  local loc = (e.t and (e.t .. " ") or "") .. (e.c or "")
  if #loc == 0 then loc = nil end
  if base_id then
    for _, b_id in ipairs(bases) do
      local b = BASE[b_id]
      b.npc = b.npc or (e.n and e.n[1]); b.npcs = e.n; b.loc = loc; b.quest = e.q; b.lxy = coords_xy(e.c)
      if #bases == 1 then b.goal = b.goal or e.g end  -- a shared quest's count belongs to one of them
    end
    -- Kill messages name the task's plural ("Spectral Blade and Claws"), not
    -- the monsters, so the catalog's names count toward the built-in task too
    -- (only when the quest is that one task).
    if #bases == 1 then
      local b = BASE[base_id]
      local have = {}
      for _, m in ipairs(b.mobs) do have[m] = true end
      for _, m in ipairs(e.m or {}) do for _, f in ipairs(singulars(m)) do
        if not have[f] then have[f] = true; b.mobs[#b.mobs + 1] = f end
      end end
    end
    for _, f in ipairs(e.f) do
      local b_id = BASE[f] and f or BY_DONE[f]
      CAT_BY_FLAG[f] = b_id or base_id
    end
  else
    local id = counter or done or e.f[1]
    local mobs = {}
    for _, m in ipairs(e.m or {}) do for _, f in ipairs(singulars(m)) do mobs[#mobs + 1] = f end end
    -- d: display name, a: area, w: the giver's weenie class (for givers with a shared name).
    CAT[id] = {name = e.q, mname = e.d or (e.m and e.m[1]), area = e.a or "Other", mobs = mobs, goal = e.g, npc = e.n and e.n[1], npcs = e.n,
      wcid = e.w, key = counter, done = done, loc = loc, server = e.s, catalog = true, lxy = coords_xy(e.c), kt = kill_task_named(e.q)}
    for _, f in ipairs(e.f) do CAT_BY_FLAG[f] = id end
  end
end

---------------------------------------------------------------------------
-- State
--   db  shared by all characters: Profiles/kt_tracker/Library/Database/KillTaskDB.json
--       db.tasks[id] = {name, area, mobs, goal, npc, wcid, cd_h, custom}
--   st  this character (plugin state, 64 KiB): prog[id] = {n, g, done, at},
--       cd[id] = unix ready, npc_cd[npc] = unix ready, q[flag] = kill-task flags, opt
--   QALL every /myquests flag of this character, saved in full to
--       Profiles/kt_tracker/Library/Quests/<character>.json
---------------------------------------------------------------------------
local st, db = nil, nil
local dirty, db_dirty = false, false
local QALL = {}

local function mark_db() db_dirty = true; dirty = true end
local function opt(k) local v = st.opt[k]; if v == nil then return DEFAULT_OPT[k] end; return v end
local function area_of(t) if not t.area or not AREA_SET[t.area] then return "Other" end; return t.area end
local function refresh_areas()
  AREAS, AREA_SET = {}, {}
  for _, a in ipairs(BASE_AREAS) do AREAS[#AREAS + 1] = a; AREA_SET[a] = true end
  for _, a in ipairs((db and db.areas) or {}) do
    if type(a) == "string" and not AREA_SET[a] and #AREAS < 40 then AREAS[#AREAS + 1] = a; AREA_SET[a] = true end
  end
  AREAS[#AREAS + 1] = "Other"; AREA_SET.Other = true
  VIEWS = {}
  for _, a in ipairs(AREAS) do VIEWS[#VIEWS + 1] = a end
end

local function task(id)
  local b, d = BASE[id] or CAT[id], db.tasks[id]
  if not b then return d end
  if not d then return b end
  return {name = d.name or b.name, mname = (not d.name) and b.mname or nil, area = d.area or b.area,
    mobs = (d.mobs and #d.mobs > 0) and d.mobs or b.mobs, goal = d.goal or b.goal, npc = d.npc or b.npc, npcs = b.npcs,
    wcid = d.wcid or b.wcid, key = d.key or (not d.nokey and b.key) or nil, done = d.done or (not d.nodone and b.done) or nil, cd_h = d.cd_h, loc = b.loc, quest = b.quest,
    server = b.server, catalog = b.catalog, lxy = b.lxy, kt = b.kt, own_npc = d.npc ~= nil, edited = true}
end
local function display(t) return t.mname or t.name or "?" end
-- NPC names are compared case-insensitively with spaces trimmed and collapsed.
local NORM, norm_n = {}, 0
local function norm(n)
  n = n or ""
  local c = NORM[n]
  if c then return c end
  local out = string.lower(n)
  if string.contains(out, "  ") or string.byte(out, 1) == 32 or string.byte(out, -1) == 32 then
    local t = trim(out); out = ""
    local sp = false
    for i = 1, #t do
      local ch = string.sub(t, i, i)
      if ch == " " then sp = true else if sp then out = out .. " " end; sp = false; out = out .. ch end
    end
  end
  if norm_n > 3000 then NORM, norm_n = {}, 0 end
  NORM[n] = out; norm_n = norm_n + 1
  return out
end
local function db_task(id)  -- writable overlay entry
  local d = db.tasks[id]
  if not d then d = {}; db.tasks[id] = d end
  return d
end
local ids_cache, need_rebuild = nil, false
local function all_ids()
  if ids_cache then return ids_cache end
  local ids = {}
  for _, id in ipairs(BASE_ORDER) do ids[#ids + 1] = id end
  local extra, seen = {}, {}
  for id in pairs(db.tasks) do if not BASE[id] then extra[#extra + 1] = id; seen[id] = true end end
  -- Catalog tasks appear once this character has something on them.
  for id, c in pairs(CAT) do
    if not seen[id] and (st.prog[id] or st.cd[id] or (c.key and st.q[c.key]) or (c.done and st.q[c.done])) then extra[#extra + 1] = id end
  end
  table.sort(extra)
  for _, id in ipairs(extra) do ids[#ids + 1] = id end
  ids_cache = ids
  return ids
end

-- Session
local guard = {players = {}, pending = nil, BAR = {}, DSLOT = {}, dpage = 1, FLAG = {}, FLAG_HINT = "(your quest flags)"}
local started_at, unix_now, tick_now = nil, nil, 0
local last_note = ""
local function note(t) last_note = string.sub(t, 1, 240) end
-- Queue of chat lines still to process: entries chat_queue[queue_head .. queue_tail].
-- (Explicit indexes: the # operator is unreliable once the front has been cleared.)
local chat_queue, queue_head, queue_tail = {}, 1, 0
local function queued() return queue_tail - queue_head + 1 end
local function enqueue(item) queue_tail = queue_tail + 1; chat_queue[queue_tail] = item end
local QUEUE_MAX = 6000             -- our own backlog of relevant lines (the client keeps the rest)
local chat_left = 0                -- client backlog still to be delivered (chat_pending)
local nav = {id = 0, at = -1e9, pos = nil}
local draft = {area = "Other"}     -- Manage > Add: new task form
local EDIT_IDS, AREA_IDS = {}, {}  -- button id -> task id / area name (from the last window build)
local SEL_IDS, SEL_TARGET = {}, {} -- Select button id -> task id; task id -> object to select
local pending_select = nil         -- object to select on this callback (from a Select click)
local picker_names = nil           -- nearby NPC names for the giver pickers, read when "Refresh list" is picked
local PICK_HINT, PICK_REFRESH = "(nearby NPCs)", "Refresh list"
local new_area = ""
local fill = {}                    -- Detected tab: the edit form per task (typed values)
local my_name, my_player, my_server = nil, nil, nil

-- /myquests: replies arrive in batches (128 lines per callback); a "run" is one
-- reply, ended by 4 s without new quest lines once the client backlog and our
-- queue are empty. A complete run (no lost lines) removes flags that are no
-- longer on the server (turned in or expired).
local mq = {sent_at = nil, req_at = nil, via = nil, lines = 0, gap = false, login_done = false,
  run = 0, active = false, run_lines = 0, run_gap = false, seen_at = -1e9, end_at = -1e9, gap_at = -1e9,
  done_lines = 0, done_ok = nil, done_unix = nil,
  unparsed = 0, unparsed_sample = nil, done_unparsed = 0}

---------------------------------------------------------------------------
-- Service requests (profiles files, chat) with retry on the client's rate limits
---------------------------------------------------------------------------
local req_queue, req_inflight, req_sent_at, req_serial = {}, {}, -1e9, 0
local chat_out, chat_sent_at = {}, -1e9
local function request(r) req_queue[#req_queue + 1] = r end
local function say(text)
  chat_out[#chat_out + 1] = text
end
-- Local, display-only line in chat (green, prefixed with the plugin name).
-- Nothing is sent to the server.
local function notice(text)
  req_serial = req_serial + 1
  request({id = "notice" .. req_serial, service = "notice", operation = "show", text = string.sub(text, 1, 500)})
end
local function flush_requests(now, out)
  if now - req_sent_at < 0.6 then return end
  local batch = {}
  -- A request carrying a file (data) goes alone: one callback's requests share a
  -- 256 KiB text limit.
  while #req_queue > 0 and #batch < 3 do
    if req_queue[1].data and #batch > 0 then break end
    batch[#batch + 1] = table.remove(req_queue, 1)
    if batch[#batch].data then break end
  end
  if #chat_out > 0 and now - chat_sent_at >= 1.2 then
    local c = table.remove(chat_out, 1)
    req_serial = req_serial + 1
    batch[#batch + 1] = {id = "chat" .. req_serial, service = "chat", operation = "send", text = c}; chat_sent_at = now
    -- Hide our own quest-list read from the chat windows (display only: the
    -- lines still reach this plugin and the chat log). The client installs the
    -- rule before this request is sent; it expires after MYQ_HIDE seconds, so a
    -- /myquests you type yourself later stays visible.
    if c == MYQUESTS and opt("myq_hide") ~= false then
      out.chat_filters = {{id = "kt_myquests", contains = " solves (", sender_type = "server", seconds = MYQ_HIDE}}
    end
  end
  if #batch == 0 then return end
  for _, r in ipairs(batch) do req_inflight[r.id] = r end
  out.requests = batch; req_sent_at = now
end
-- Returns the original request when it failed only because of a rate limit.
local function retry_if_limited(e)
  local r = req_inflight[e.id]
  req_inflight[e.id] = nil
  if r and e.ok == false and type(e.error) == "string" and (contains(e.error, "rate limit") or contains(e.error, "one send per second")) then
    if r.service == "chat" then table.insert(chat_out, 1, r.text)
    else table.insert(req_queue, 1, r) end
    return true
  end
  return false
end

-- One read per MYQ_MIN_GAP seconds (server limit): an earlier request waits.
local function request_myquests(via, now)
  if mq.req_at and now - mq.req_at < MYQ_MIN_GAP then
    mq.wait_at, mq.wait_via = mq.req_at + MYQ_MIN_GAP, via
    if via == "button" or via == "command" then note("Quest list: one read per minute; reading in " .. dur(mq.wait_at - now)) end
    return false
  end
  mq.wait_at, mq.wait_via = nil, nil
  say(MYQUESTS)
  mq.sent_at, mq.req_at, mq.via, mq.new_run = unix_now, now, via, true
  return true
end
-- 5.0.0: after a pickup or turn-in, the next quest-list read is sent as soon
-- as the server allows (one read per 60 s), so the list confirms it quickly.
function guard.confirm_read()
  if opt("auto_myq") == false then return end
  local at = math.max(tick_now + 3, (mq.req_at or -1e9) + MYQ_MIN_GAP)
  if not mq.wait_at or at < mq.wait_at then mq.wait_at, mq.wait_via = at, "confirm" end
end
-- "4 min" -> 4; "Off" -> nil
-- Seconds between automatic reads (Options, 1-300); nil when switched off.
local function refresh_seconds()
  if opt("auto_myq") == false then return nil end
  local n = math.floor(tonumber(opt("myq_s")) or 65)
  if n < 1 then n = 1 elseif n > 300 then n = 300 end
  return n
end

---------------------------------------------------------------------------
-- Indexes
---------------------------------------------------------------------------
local MOB, NPC_BY_NAME, NPC_BY_WCID, DONE_OWNER = {}, {}, {}, {}
-- Tasks created from a kill message (4.12 and earlier made one when a message
-- named a built-in task by its plural, e.g. "Spectral Blade and Claws") are
-- merged into the built-in or catalog task their name now matches. Progress
-- moves over unless the target has newer progress. db.merged remembers the
-- merge so other characters' progress moves too.
local function from_chat(d)
  if d.auto then return true end
  if type(d.mobs) ~= "table" or type(d.name) ~= "string" then return false end
  local f = singulars(d.name)
  if #f ~= #d.mobs then return false end
  for i = 1, #f do if f[i] ~= d.mobs[i] then return false end end
  return true
end
local function move_progress(from, to)
  local a, b = st.prog[from], st.prog[to]
  if a and (not b or (a.at or 0) > (b.at or 0)) then st.prog[to] = a end
  st.prog[from], st.cd[from], st.done_at[from] = nil, nil, nil
  dirty = true
end
guard.MOVED = {killtaskchaosdragwait = "killtaskchaosdrag"}
local function merge_duplicates()
  local merged = false
  db.merged = db.merged or {}
  for id, d in pairs(db.tasks) do
    if d.custom and not d.key and from_chat(d) then
      local target
      for _, f in ipairs(singulars(d.name)) do target = target or MOB[f] end
      if target and target ~= id then
        db.merged[id] = target; db.tasks[id] = nil; mark_db(); merged = true
        move_progress(id, target)
        note(d.name .. " now counts toward " .. display(task(target)))
      end
    end
  end
  -- 5.2.0: catalog corrections. Details you saved under an old catalog id move
  -- to the corrected task (the Chaos Dragon task was saved under its timer).
  for from, to in pairs(guard.MOVED) do
    local d = db.tasks[from]
    if d and not BASE[from] and not CAT[from] and CAT[to] then
      local nd = db_task(to)
      for _, k in ipairs({"name", "mobs", "npc", "wcid", "goal", "area", "cd_h"}) do if nd[k] == nil then nd[k] = d[k] end end
      db.tasks[from] = nil; db.merged[from] = to; mark_db(); merged = true
      if st.cd[from] and not st.cd[to] then st.cd[to] = st.cd[from] end
      if st.done_at[from] and not st.done_at[to] then st.done_at[to] = st.done_at[from] end
      move_progress(from, to)
      note("Moved " .. (d.name or from) .. " to " .. CAT[to].name)
    end
  end
  for from, to in pairs(db.merged) do if st.prog[from] then move_progress(from, to) end end
  if merged then ids_cache = nil end
  return merged
end
local function rebuild_indexes()
  ids_cache = nil
  MOB, NPC_BY_NAME, NPC_BY_WCID, DONE_OWNER = {}, {}, {}, {}
  guard.FLAG = {}   -- counter flag -> task (5.0.0: flags can be edited)
  -- MOB[name] = the first task for a monster; MOB[0][name] = every task for it
  -- (two tasks can share a monster: Tou-Tou outpost and fort Panumbris Shadows).
  local all = {}; MOB[0] = all
  local ids, listed = {}, {}
  for _, id in ipairs(all_ids()) do ids[#ids + 1] = id; listed[id] = true end
  for id in pairs(CAT) do if not listed[id] then ids[#ids + 1] = id end end
  -- Built-in and catalog monster names first, so a kill counts toward them
  -- rather than toward a task created earlier from the same chat line.
  for _, id in ipairs(ids) do
    local d = db.tasks[id]
    if not (d and d.custom) then for _, m in ipairs(task(id).mobs or {}) do
      MOB[m] = MOB[m] or id
      local l = all[m] or {}; all[m] = l; if l[#l] ~= id then l[#l + 1] = id end
    end end
  end
  -- A merge removes tasks the monster index above already lists, so the
  -- indexes are built again from the start (5.2.3: the removed Chaos Dragon
  -- timer entry stayed in the index and stopped the plugin near the dragons).
  if merge_duplicates() then return rebuild_indexes() end
  for _, id in ipairs(ids) do
    local t = task(id)
    if db.tasks[id] and db.tasks[id].custom then for _, m in ipairs(t.mobs or {}) do MOB[m] = MOB[m] or id end end
    if t.done then DONE_OWNER[t.done] = DONE_OWNER[t.done] or id end
    if t.key then guard.FLAG[t.key] = guard.FLAG[t.key] or id end
    local names = {}
    if t.npc and #t.npc > 0 then names[1] = t.npc end
    -- Only catalog quests that name monsters mark their givers (keeps generic NPCs quiet).
    if t.npcs and (not t.catalog or (t.mobs and #t.mobs > 0)) then for _, n in ipairs(t.npcs) do names[#names + 1] = n end end
    if t.catalog and not t.edited and (not t.mobs or #t.mobs == 0) then names = {} end
    local quiet = t.catalog and not t.kt and not t.own_npc
    if quiet then names = {} end
    for _, n in ipairs(names) do
      local k = norm(n); local l = NPC_BY_NAME[k] or {}
      local dup = false; for _, x in ipairs(l) do if x == id then dup = true end end
      if not dup then l[#l + 1] = id; NPC_BY_NAME[k] = l end
    end
    if t.wcid and t.wcid > 0 and not quiet then
      local l = NPC_BY_WCID[t.wcid] or {}; l[#l + 1] = id; NPC_BY_WCID[t.wcid] = l
    end
  end
end
local function resolve(plural)
  for _, f in ipairs(singulars(plural)) do if MOB[f] then return MOB[f] end end
  return nil
end
-- Your position (global metres), set each callback; used for giver locations.
local my_x, my_y = nil, nil
local GIVER_RANGE = 1000  -- metres from the catalog's giver coordinates
-- A shared giver name ("Royal Guard") matches only when the weenie class agrees,
-- or (no weenie class known) when you are near the catalog's giver location.
local function shared(name) return SHARED[norm(name)] == true end
local function name_ok(id, wcid)
  local t = task(id)
  if not t then return false end
  if t.wcid and t.wcid > 1 and wcid > 1 then return t.wcid == wcid end
  if t.lxy and my_x then
    local dx, dy = my_x - t.lxy[1], my_y - t.lxy[2]
    return dx * dx + dy * dy <= GIVER_RANGE * GIVER_RANGE
  end
  return false
end
local function npc_ids(name, wcid)
  local out, seen = {}, {}
  wcid = math.floor(tonumber(wcid) or 0)
  local strict = shared(name)
  for _, id in ipairs(NPC_BY_NAME[norm(name)] or {}) do
    if not seen[id] and (not strict or name_ok(id, wcid)) then seen[id] = true; out[#out + 1] = id end
  end
  for _, id in ipairs(NPC_BY_WCID[math.floor(wcid or 0)] or {}) do if not seen[id] then seen[id] = true; out[#out + 1] = id end end
  return out
end

---------------------------------------------------------------------------
-- Task status: active | turnin | cooldown | available
---------------------------------------------------------------------------
local function status(id)
  local t = task(id)
  if not t then return nil end   -- a task that no longer exists
  local p = st.prog[id]
  local d = t.done and (st.q[t.done] or QALL[t.done])
  -- A completion flag stamped after the last kill means the task was turned in;
  -- so does a turn-in seen here (rewarded while using its quest giver).
  local done_at = st.done_at[id]
  if p and d and d.t and d.t > 0 and (p.at or 0) <= d.t then p = nil end
  if p and done_at and (p.at or 0) <= done_at then p = nil end
  if p then
    local n, g = int(p.n) or 0, int(p.g)
    if p.done or (g and g > 0 and n >= g) then return "turnin", {n = n, g = g, done = p.done} end
    return "active", {n = n, g = g}
  end
  local q = t.key and st.q[t.key]
  if q and d and d.t and q.t and d.t >= q.t and d.t > 0 then q = nil end
  if q and done_at and (q.t or 0) <= done_at then q = nil end
  if q then
    if q.m and q.m > 0 and q.s >= q.m then return "turnin", {n = int(q.s), g = int(q.m)} end
    return "active", {n = int(q.s) or 0, g = int((q.m and q.m > 0) and q.m or t.goal)}
  end
  if st.cd[id] and unix_now and st.cd[id] > unix_now then return "cooldown", nil, st.cd[id] - unix_now end
  if d and unix_now and d.d and d.d > 0 and d.t and unix_now < d.t + d.d then return "cooldown", nil, d.t + d.d - unix_now end
  -- The quest giver said "You may complete this quest again in ..." (timer per
  -- giver); a completion flag with its own timer in the quest list wins.
  if t.npc and unix_now and not (d and (d.d or 0) > 0) then
    local g = (t.wcid and t.wcid > 1 and st.npc_cd["w" .. t.wcid]) or ((not shared(t.npc)) and st.npc_cd[norm(t.npc)])
    if g and g > unix_now then return "cooldown", nil, g - unix_now end
  end
  return "available"
end

---------------------------------------------------------------------------
-- Events from chat
---------------------------------------------------------------------------
local function new_custom(plural, goal, npc, wcid)
  local forms = singulars(plural)
  local id = "c_" .. slug(forms[#forms > 1 and 2 or 1])
  if #id <= 2 then return nil end
  if not db.tasks[id] then
    local name = trim(plural)
    db.tasks[id] = {name = name, area = "Other", mobs = forms, goal = goal, npc = npc, wcid = wcid, custom = true, auto = true, srv = my_server}
    note("New task: " .. name .. " (area Other)")
  end
  mark_db()
  for _, f in ipairs(forms) do MOB[f] = MOB[f] or id end
  need_rebuild = true
  return id
end

local function link_npc(id, npc, wcid)
  if not id or not npc or npc == "" then return end
  local t = task(id)
  if t.npc ~= npc or (wcid and wcid > 0 and t.wcid ~= wcid) then
    local d = db_task(id); d.npc = npc; if wcid and wcid > 0 then d.wcid = wcid end
    mark_db()
    local k = norm(npc); local l = NPC_BY_NAME[k] or {}; l[#l + 1] = id; NPC_BY_NAME[k] = l
    if wcid and wcid > 0 then local w = NPC_BY_WCID[wcid] or {}; w[#w + 1] = id; NPC_BY_WCID[wcid] = w end
    need_rebuild = true
  end
end

local function set_progress(id, n, g, done)
  ids_cache = nil
  local prev = st.prog[id] or {}
  local goal = g or prev.g or task(id).goal
  st.prog[id] = {n = n, g = goal, done = done or (goal and goal > 0 and n >= goal) or false, at = unix_now}
  st.cd[id] = nil
  if goal and goal > 0 and not task(id).goal then db_task(id).goal = goal; mark_db() end
  dirty = true
end

local function link_counter(plural, n, g)
  local cands = {}
  for key, q in pairs(st.q) do
    local t = db.tasks[key]
    if t and (not t.mobs or #t.mobs == 0) and (not g or q.m == g) and (q.s == n - 1 or q.s == n) then cands[#cands + 1] = key end
  end
  if #cands ~= 1 then return nil end
  db.tasks[cands[1]].mobs = singulars(plural); mark_db(); rebuild_indexes()
  note("Linked " .. plural .. " to quest " .. cands[1])
  return cands[1]
end

local function on_kill_progress(plural, n, g, done, npc, wcid)
  local id = resolve(plural)
  -- A monster shared by several tasks: the one in progress whose kill goal
  -- matches the message ("You must kill 50" is the fort task, not the outpost's).
  local all = id and MOB[0]
  if all then
    local cands, seen = {}, {}
    for _, f in ipairs(singulars(plural)) do
      for _, x in ipairs(all[f] or {}) do if not seen[x] then seen[x] = true; cands[#cands + 1] = x end end
    end
    if #cands > 1 then
      local score = -1
      for _, x in ipairs(cands) do
        local stt, p = status(x)
        local goal = (p and p.g) or int(task(x).goal)
        local sc = ((stt == "active" or stt == "turnin") and 2 or 0) + ((g and goal == g) and 1 or 0)
        if sc > score then id, score = x, sc end
      end
    end
  end
  id = id or link_counter(plural, n, g)
  if not id then id = new_custom(plural, g, npc, wcid) end
  if not id then return end
  set_progress(id, n, g, done)
  if npc then link_npc(id, npc, wcid) end
end

local function on_task_start(npc, wcid, plural, goal)
  local by_npc = NPC_BY_NAME[norm(npc)]
  local id = resolve(plural) or (by_npc and #by_npc == 1 and by_npc[1]) or new_custom(plural, goal, npc, wcid)
  if not id then return end
  link_npc(id, npc, wcid)
  if goal and not task(id).goal then db_task(id).goal = goal; mark_db() end
  if not st.prog[id] then st.prog[id] = {n = 0, g = goal, done = false, at = unix_now}; dirty = true; guard.confirm_read() end
  st.cd[id] = nil; ids_cache = nil
  note(display(task(id)) .. ": started (" .. (int(goal) or "?") .. " to kill)")
end

local function npc_cd_key(name, wcid) if wcid and wcid > 1 then return "w" .. wcid end; return norm(name) end
-- Pets and lines waiting for their NPC's use (fields, not locals: the main chunk
-- is near Lua's 200-local limit).
-- "Gvbz's Mythic Dragon": a pet or summon of you or a nearby player, never an NPC.
function guard.is_pet(name)
  if type(name) ~= "string" or not string.contains(name, "'s ") then return false end
  local m = regexmatch(name, "^(.+)'s ")
  if not m then return false end
  local owner = string.lower(m["1"])
  return (my_name and owner == string.lower(my_name)) or guard.players[owner] == true
end
-- Keep saved giver cooldowns only for known kill-task givers (drops ones once
-- credited to a pet or another nearby object).
function guard.purge_cd()
  for k in pairs(st.npc_cd) do
    local keep
    if string.sub(k, 1, 1) == "w" and tonumber(string.sub(k, 2)) then keep = NPC_BY_WCID[math.floor(tonumber(string.sub(k, 2)))] ~= nil
    else keep = NPC_BY_NAME[k] ~= nil end
    if not keep then st.npc_cd[k] = nil; dirty = true end
  end
end
-- 4.17.8: the fort tasks' monsters were saved by hand as "penumbris shadow",
-- "pillar of hellfire" etc.; the catalog now has them (the game spells it
-- Panumbris), so those saved names are dropped once.
function guard.fix_fort_db()
  local OLD = {fortshadowkillcount = "penumbris shadow", pillarhellfirekillcount = "pillar of hellfire",
    fortknightkillcount = "void knight", fortbushikillcount = "bushi skeleton", hellfiresorckillcount = "hellfire sorcerer"}
  for id, old in pairs(OLD) do
    local d = db.tasks[id]
    if d and type(d.mobs) == "table" and #d.mobs == 1 and d.mobs[1] == old then d.mobs = nil; mark_db(); need_rebuild = true end
  end
end
local function on_cooldown(npc, wcid, secs)
  if not unix_now then return end
  local ids = npc_ids(npc, wcid)
  if #ids == 0 then return end   -- not a kill-task giver
  st.npc_cd[npc_cd_key(npc, wcid)] = unix_now + secs
  if #ids == 1 and not st.prog[ids[1]] then st.cd[ids[1]] = unix_now + secs end
  dirty = true
  note(npc .. ": available again in " .. dur(secs))
end

local npc_told, npc_told_n = {}, 0  -- object id -> tick of its last tell to you
local npc_used, used_ids = {}, {}  -- object id -> tick you last used it (client "use" events); ids seen
-- Run fn(npc) once that NPC's use is confirmed: at once if it was used in
-- the last 10 s, else when its use arrives within 3 s (else dropped).
function guard.after_use(npc, fn)
  local u = npc_used[npc.id]
  if u and tick_now - u <= 10 then fn(npc)
  else guard.pending = {npc = npc, fn = fn, at = tick_now} end
end
-- Pickup by use: using a giver that has an available task starts it. What the
-- giver tells you in the next 2 s decides which task (its monster named in the
-- tell, any wording), else its only available task. In-progress tasks are never
-- touched. A start nobody confirms (no counter on the next complete quest-list
-- read, no kills since) is undone by that read.
local pickup = nil                  -- {npc, at, tells}
local recent_tells = {}             -- object id -> {at, lines} (last few seconds)
-- Tasks this NPC may give. A shared name ("Royal Guard") whose weenie class isn't
-- linked yet offers every task with that giver name; the pickup then needs the
-- NPC's reply to name the task's monster (broad = true).
local function available_for(npc)
  local out, broad = {}, false
  local ids = npc_ids(npc.name, math.floor(tonumber(npc.wcid) or 0))
  if #ids == 0 and shared(npc.name) then ids = NPC_BY_NAME[norm(npc.name)] or {}; broad = true end
  for _, id in ipairs(ids) do
    if status(id) == "available" then out[#out + 1] = id end
  end
  return out, broad
end
-- May this NPC's weenie class be linked to task id? Not when that weenie class
-- already belongs to another task with the same giver name.
function guard.can_link(id, npc)
  local w = math.floor(tonumber(npc.wcid) or 0)
  if w <= 1 then return false end
  for _, x in ipairs(NPC_BY_WCID[w] or {}) do
    if x ~= id and task(x) and norm(task(x).npc or "") == norm(npc.name) then return false end
  end
  return true
end
local function first_number(txt)
  local n
  for i = 1, #txt do
    local b = string.byte(txt, i)
    if b >= 48 and b <= 57 then n = (n or 0) * 10 + (b - 48) elseif n then break end
  end
  if n and n >= 1 and n <= 999 then return n end
  return nil
end
local function begin_pickup(npc)
  if pickup and pickup.npc.id == npc.id then return end
  if #available_for(npc) == 0 then return end
  local tells = {}
  local r = recent_tells[npc.id]
  if r and tick_now - r.at <= 3 then for _, l in ipairs(r.lines) do tells[#tells + 1] = l end end
  pickup = {npc = npc, at = tick_now, tells = tells}
end
-- Irregular plurals a reply may use for a task's monster ("Gurog Henchmen" for
-- "gurog henchman"); a regular plural already contains the singular.
function guard.forms(m)
  -- "pillar of hellfire": the plural goes on the first word ("pillars of hellfire").
  if string.contains(m, " of ") then
    local x = regexmatch(m, "^(.+?) of (.+)$")
    if x then
      local out = {m}
      for i, h in ipairs(guard.forms(x["1"])) do if i > 1 then out[#out + 1] = h .. " of " .. x["2"] end end
      out[#out + 1] = x["1"] .. "s of " .. x["2"]
      return out
    end
  end
  if string.sub(m, -3) == "man" then return {m, string.sub(m, 1, -4) .. "men"} end
  if string.sub(m, -1) == "y" then return {m, string.sub(m, 1, -2) .. "ies"} end
  if string.sub(m, -1) == "f" then return {m, string.sub(m, 1, -2) .. "ves"} end
  return {m}
end
-- 4.17.5: one use can hand out several tasks (Gregoria and Hunter give three
-- at once, one reply each). Every reply line starts the available task whose
-- monster it names (the longest name wins, so "Snow Tusker Warriors" isn't
-- read as "Snow Tuskers"); a giver with one available task and no naming
-- reply starts that one.
local function resolve_pickup()
  local p = pickup; pickup = nil
  local cands, broad = available_for(p.npc)   -- a cooldown reply or a "Destroy N" start empties this
  if #cands == 0 then return end
  local picks, seen = {}, {}
  for _, line in ipairs(p.tells) do
    local low = string.lower(line)
    local pick, best = nil, 0
    for _, id in ipairs(cands) do
      for _, m in ipairs(task(id).mobs or {}) do
        if #m > best then
          for _, f in ipairs(guard.forms(m)) do
            if string.contains(low, f) then pick, best = id, #m; break end
          end
        end
      end
    end
    if pick and not seen[pick] then seen[pick] = true; picks[#picks + 1] = {id = pick, goal = first_number(line)} end
  end
  if #picks == 0 and #cands == 1 and not broad then picks[1] = {id = cands[1]} end
  for _, k in ipairs(picks) do
    -- A shared-name giver named this task's monster: remember its weenie class.
    local ok = true
    if broad then
      ok = guard.can_link(k.id, p.npc)
      if ok then link_npc(k.id, p.npc.name, math.floor(tonumber(p.npc.wcid) or 0)) end
    end
    if ok then
      local t = task(k.id)
      local goal = k.goal or int(t.goal)
      st.prog[k.id] = {n = 0, g = goal, done = false, at = unix_now, prov = true}
      st.cd[k.id] = nil; ids_cache = nil; dirty = true; guard.confirm_read()
      note(display(t) .. ": started (" .. (goal or "?") .. " to kill)")
    end
  end
end
local pending_reward = nil          -- {npc, at}: a reward waiting for its use (<= 10 s)
local function on_turn_in(use_npc, forced)
  -- An experience reward right after you used a quest giver (client "use"
  -- event, within 10 s) completes that giver's finished task. If the NPC isn't
  -- known as a giver yet and only one finished task has no giver (or only one
  -- task is finished), that task was turned in and the NPC is remembered as its
  -- giver (never for shared names such as "Royal Guard").
  -- ACE prints "You've earned N experience." for monster kills too, so a reward
  -- with no NPC used just before it never counts.
  if not use_npc then return end
  -- Proof you used it: its use event, or a tell from it, within 10 s.
  local told, used = npc_told[use_npc.id], npc_used[use_npc.id]
  local proof = forced or (used and tick_now - used <= 10) or (told and tick_now - told <= 10)
  if not proof then pending_reward = {npc = use_npc, at = tick_now}; return end
  pending_reward = nil
  local cands, no_giver = {}, {}
  for _, id in ipairs(all_ids()) do
    if status(id) == "turnin" then
      cands[#cands + 1] = id
      if not task(id).npc then no_giver[#no_giver + 1] = id end
    end
  end
  if #cands == 0 then return end
  local wcid = math.floor(use_npc.wcid or 0)
  local known = npc_ids(use_npc.name, wcid)
  local pick
  for _, id in ipairs(known) do for _, c in ipairs(cands) do if c == id then pick = pick or id end end end
  if not pick and #known == 0 and not shared(use_npc.name) then
    if #no_giver == 1 then pick = no_giver[1] elseif #cands == 1 then pick = cands[1] end
    if pick then link_npc(pick, use_npc.name, wcid) end
  end
  -- A shared-name giver not linked yet: the only task with that giver name that
  -- is ready to turn in is its task; remember its weenie class.
  if not pick and #known == 0 and shared(use_npc.name) then
    local mine = {}
    for _, id in ipairs(NPC_BY_NAME[norm(use_npc.name)] or {}) do
      for _, c in ipairs(cands) do if c == id then mine[#mine + 1] = id end end
    end
    if #mine == 1 and guard.can_link(mine[1], use_npc) then pick = mine[1]; link_npc(pick, use_npc.name, wcid) end
  end
  if not pick then return end
  local t = task(pick)
  st.prog[pick] = nil
  st.done_at[pick] = unix_now
  if t.key then st.q[t.key] = nil; QALL[t.key] = nil end
  local hours = t.cd_h or tonumber(opt("cooldown_hours")) or 20
  st.cd[pick] = unix_now + hours * 3600
  ids_cache = nil
  if t.npc and #npc_ids(t.npc, t.wcid) == 1 then st.npc_cd[npc_cd_key(t.npc, t.wcid)] = unix_now + hours * 3600 end
  dirty = true; guard.confirm_read()
  note(display(t) .. ": turned in" .. (t.npc and (" to " .. t.npc) or "") .. ", next in " .. dur(hours * 3600))
end

-- 5.0.0: the client reports each use (snapshot events, type "use"): stage
-- "requested" the moment you use something (with its GUID and weenie class),
-- "completed" (with an error number) when the server finishes it. Using a
-- living, non-monster creature or vendor near you (not a player or a pet) is
-- an NPC use: it starts the pickup check, confirms a waiting reward, and
-- attributes the next few seconds of "Destroy N of these" / "again in" lines
-- and that NPC's tells. No selection or distance guesswork.
function guard.used_npc(window)
  local u = guard.use
  if u and not u.err and tick_now - u.at <= (window or 10) then return u.npc end
  return nil
end
function guard.on_use(e, s)
  local id = tonumber(e.target) or tonumber(e.source)
  if not id then return end
  if e.stage == "completed" then
    local u = guard.use
    if u and u.npc.id == id and (tonumber(e.error) or 0) ~= 0 then
      u.err = true
      if pickup and pickup.npc.id == id then pickup = nil end
    end
    return
  end
  if e.stage ~= "requested" then return end
  local o
  for _, x in ipairs(s.objects or {}) do if x.id == id then o = x; break end end
  if not o or o.player or o.monster or o.corpse or type(o.name) ~= "string" or guard.is_pet(o.name)
    or (o.object_type and o.object_type ~= "creature" and o.object_type ~= "vendor") then guard.use = nil; return end
  local npc = {id = o.id, name = o.name, wcid = math.floor(tonumber(e.wcid) or tonumber(o.wcid) or 0)}
  guard.use = {npc = npc, at = tick_now}
  if next(npc_used) and #used_ids > 200 then npc_used, used_ids = {}, {} end
  if not npc_used[npc.id] then used_ids[#used_ids + 1] = npc.id end
  npc_used[npc.id] = tick_now
  local pd = guard.pending
  if pd and pd.npc.id == npc.id and tick_now - pd.at <= 3 then guard.pending = nil; pd.fn(npc) end
  begin_pickup(npc)
  local pr = pending_reward
  if pr and pr.npc.id == npc.id and tick_now - pr.at <= 10 then on_turn_in(pr.npc, true) end
end

-- /myquests line: key - solves solves (last)"desc" max delay
-- Tolerant like Oracle of Dereth's: servers differ in spacing, may leave out the
-- message/max/delay part, or add text at the end.
local MYQ = '^(\\S+) - (-?\\d+) solves \\((\\d*)\\)\\s*(?:"(.*)"\\s*(-?\\d+)\\s+(-?\\d+))?.*$'
local function on_myquests(key, solves, last, desc, max, delay)
  if not mq.active then
    mq.active = true
    -- A burst within 30 s of the last one, with no new request in between, is
    -- the rest of the same reply (a slow server).
    if mq.new_run or tick_now - mq.end_at > 30 then
      mq.run = mq.run + 1; mq.run_lines = 0; mq.run_gap = false
    end
    mq.new_run = false
    if tick_now - mq.gap_at < 5 then mq.run_gap = true end
  end
  mq.run_lines = mq.run_lines + 1
  mq.seen_at = tick_now
  mq.lines = mq.run_lines
  local d = (desc and #desc > 0) and string.sub(desc, 1, 120) or nil
  QALL[key] = {s = solves, t = last, m = max, d = delay, desc = d, r = mq.run}
  local known = guard.FLAG[key] or DONE_OWNER[key] or BASE[key] or BY_DONE[key] or CAT_BY_FLAG[key] or db.tasks[key]
  if not known and not is_kill_key(key) then return end
  local q = st.q[key] or {}
  q.s, q.t, q.m, q.d, q.r = solves, last, max, delay, mq.run
  if d then q.desc = d end
  st.q[key] = q
  -- An unknown kill counter (not a timer/completion flag) becomes a task in the Other area.
  if not known and flag_role(key) == "counter" then
    db.tasks[key] = {name = d and string.sub(d, 1, 60) or key, area = "Other",
      mobs = {}, goal = (max and max > 0) and max or nil, key = key, custom = true, srv = my_server}
    mark_db(); need_rebuild = true
  end
  -- A completion flag stamped after the last kill: the task was turned in.
  local owner = DONE_OWNER[key]
  if owner and st.prog[owner] and last and last > 0 and (st.prog[owner].at or 0) <= last then
    st.prog[owner] = nil; st.cd[owner] = nil
  end
  -- A progress message is newer than a counter flag only if it came later.
  local id = guard.FLAG[key] or BY_DONE[key] or DONE_OWNER[key] or CAT_BY_FLAG[key] or (db.tasks[key] and key)
  ids_cache = nil
  if id and st.prog[id] and st.prog[id].at and last and last > st.prog[id].at then st.prog[id] = nil end
  dirty = true
end

-- "You've stamped <flag>!" (some servers announce every quest stamp; Oracle of
-- Dereth reads the same line). A stamp on a task's completion flag means it was
-- just turned in; on its counter, a kill was counted.
local STAMP_RE = "^You['\u{2019}]ve stamped ([^\\s!]+)(?: on first completion)?!"
local function on_stamp(key)
  key = string.lower(key)
  local e = QALL[key] or {s = 0, t = 0}
  e.s, e.t, e.r = (e.s or 0) + 1, unix_now or 0, mq.run
  QALL[key] = e
  local owner = DONE_OWNER[key]
  if not owner then
    -- An unlisted task's completion flag, matched by name (busydoorkilltask -> busydoorkillcount).
    for id, d in pairs(db.tasks) do
      if d.key and not d.done then
        local stem = d.key
        for _, suf in ipairs({"killcounter", "killcount", "counter", "count", "kills"}) do
          if #stem > #suf and string.sub(stem, -#suf) == suf then stem = string.sub(stem, 1, #stem - #suf); break end
        end
        if #stem >= 5 and key ~= d.key and string.sub(key, 1, #stem) == stem and flag_role(key) == "done" then
          d.done = key; DONE_OWNER[key] = id; owner = id; mark_db(); break
        end
      end
    end
  end
  local counter_of = guard.FLAG[key] or (BASE[key] and key) or (CAT_BY_FLAG[key] and CAT[CAT_BY_FLAG[key]] and CAT[CAT_BY_FLAG[key]].key == key and CAT_BY_FLAG[key]) or (db.tasks[key] and key)
  if owner or counter_of or is_kill_key(key) then st.q[key] = {s = e.s, t = e.t, m = e.m, d = e.d, desc = e.desc} end
  if owner then
    local t = task(owner)
    st.prog[owner] = nil
    st.done_at[owner] = unix_now
    if not (e.d and e.d > 0) then st.cd[owner] = (unix_now or 0) + (t.cd_h or tonumber(opt("cooldown_hours")) or 20) * 3600 end
    note(display(t) .. ": turned in (quest stamp " .. key .. ")"); guard.confirm_read()
  end
  ids_cache = nil; dirty = true
end

local KILL_PATTERNS = {
  {re = "^You have killed (\\d+) (.+?)! You must kill (\\d+) to complete your task", n = 1, name = 2, goal = 3},
  {re = "^You have killed (\\d+) (.+?)! Your task is complete", n = 1, name = 2, done = true},
  {re = "^You've killed (\\d+) out of (\\d+) (.+?)\\.?$", n = 1, goal = 2, name = 3},
}
local START_RE = "Destroy (\\d+) of these (.+?) and you will be rewarded"
local AGAIN_RE = "complete this quest again in (.+)$"

local function kill_line(txt, npc, wcid)
  for _, p in ipairs(KILL_PATTERNS) do
    local m = regexmatch(txt, p.re)
    if m then
      on_kill_progress(m[tostring(p.name)], tonumber(m[tostring(p.n)]) or 0,
        p.goal and tonumber(m[tostring(p.goal)]) or nil, p.done, npc, wcid)
      return true
    end
  end
  return false
end

local function quest_line(txt)
  local m = regexmatch(txt, MYQ)
  if m and m["1"] then
    on_myquests(string.lower(m["1"]), tonumber(m["2"]) or 0, tonumber(m["3"]) or 0, m["4"], tonumber(m["5"]), tonumber(m["6"]))
  else
    mq.unparsed = mq.unparsed + 1
    mq.unparsed_sample = string.sub(txt, 1, 160)
  end
end

local function process_line(item)
  local txt, sender = item.txt, item.sender
  if sender == "" then
    if contains(txt, " solves (") then quest_line(txt)
    elseif contains(txt, "stamped") then
      local m = regexmatch(txt, STAMP_RE)
      if m and m["1"] then on_stamp(m["1"]) end
    elseif contains(txt, "killed") then
      kill_line(txt)
    elseif (contains(txt, "You've earned") or contains(txt, "You have earned")) and contains(txt, "experience") then
      on_turn_in(item.use)
    elseif item.use and contains(txt, "of these") and contains(txt, "Destroy") then
      local m = regexmatch(txt, START_RE)
      if m then guard.after_use(item.use, function(o) on_task_start(o.name, math.floor(o.wcid or 0), m["2"], tonumber(m["1"])) end) end
    elseif item.use and contains(txt, "complete this quest again in") then
      local m = regexmatch(txt, AGAIN_RE)
      local secs = m and parse_duration(m["1"])
      if secs then guard.after_use(item.use, function(o) on_cooldown(o.name, math.floor(o.wcid or 0), secs) end) end
    elseif contains(txt, "myquests\" is not currently enabled") then
      note("This server has /myquests disabled; tracking uses chat only")
    elseif contains(txt, "Quest list is empty") then
      mq.active, mq.end_at, mq.done_lines, mq.done_ok, mq.done_unix = false, tick_now, 0, true, unix_now
    end
  elseif item.npc then
    local npc, wcid = item.npc.name, item.npc.wcid
    if contains(txt, "of these") and contains(txt, "Destroy") then
      local m = regexmatch(txt, START_RE)
      if m then on_task_start(npc, wcid, m["2"], tonumber(m["1"])) end
    elseif contains(txt, "complete this quest again in") then
      local m = regexmatch(txt, AGAIN_RE)
      local secs = m and parse_duration(m["1"])
      if secs then on_cooldown(npc, wcid, secs) end
    elseif contains(txt, "killed") then
      kill_line(txt, npc, wcid)
    end
  end
end

local function drain(max, budgeted)
  local done = 0
  while queue_head <= queue_tail and done < max do
    if budgeted and not workavailable() then break end
    local item = chat_queue[queue_head]
    chat_queue[queue_head] = nil; queue_head = queue_head + 1; done = done + 1
    process_line(item)
  end
  if queue_head > queue_tail then chat_queue, queue_head, queue_tail = {}, 1, 0 end
  return done
end

-- 5.0.0: the client delivers only the lines plugin.json subscribes to
-- ("chat_subscriptions": quest-list rows, kill counts, stamps, experience,
-- "Destroy N of these", "again in" and /myquests replies from the server, and
-- NPC/vendor speech), starting at the newest line ("chat_history": false), so
-- nothing waits behind other chat or a replay after a Refresh. Each line says
-- who sent it (sender_type): only server lines and the NPC you just used count.
local function read_chat(s)
  chat_left = tonumber(s.chat_pending) or 0
  if s.chat_gap or (tonumber(s.chat_dropped) or 0) > 0 then
    mq.gap_at = tick_now
    if mq.active then mq.run_gap = true end
    mq.gap = true
  end
  local used = guard.used_npc(10)
  for _, e in ipairs(s.chat_events or {}) do
    local txt = e.raw_text or e.text or ""
    local kind = e.sender_type
    if #txt > 0 and #txt <= 4096 then
      if kind == "server" or (kind == nil and (e.sender == "" or e.sender == nil)) then
        if queued() >= QUEUE_MAX then
          mq.gap_at = tick_now; if mq.active then mq.run_gap = true end
        else
          local item = {txt = txt, sender = "", use = used}
          -- Quest-list lines can come in hundreds and wait their turn; everything
          -- else (kill counts, rewards, stamps) is handled the moment it arrives.
          if contains(txt, " solves (") then enqueue(item) else process_line(item) end
        end
      elseif (kind == "npc" or kind == "vendor") and used and type(e.sender) == "string"
        and string.lower(e.sender) == string.lower(used.name) then
        -- Only the NPC you just used is listened to; a tell from any other NPC
        -- (or a player) is ignored, so a shared name can't mislead.
        local o = used
        if npc_told_n > 200 then npc_told, npc_told_n = {}, 0 end
        if not npc_told[o.id] then npc_told_n = npc_told_n + 1 end
        npc_told[o.id] = tick_now
        local r = recent_tells[o.id]
        if not r or tick_now - r.at > 3 then r = {at = tick_now, lines = {}}; recent_tells[o.id] = r end
        r.at = tick_now
        if #r.lines < 8 then r.lines[#r.lines + 1] = txt end
        if pickup and pickup.npc.id == o.id and #pickup.tells < 8 then pickup.tells[#pickup.tells + 1] = txt end
        process_line({txt = txt, sender = e.sender, npc = {name = o.name, wcid = o.wcid}})
      end
    end
  end
  drain(40, false)
end

---------------------------------------------------------------------------
-- Quest list file: the full /myquests dump for this character, read at start
-- (the basis) and rewritten after each reply.
---------------------------------------------------------------------------
local qfile = {phase = "wait", name = nil, saved = nil, count = 0, err = nil, want_save = false, fails = 0}
local function safe_name(s)
  local out = ""
  for i = 1, math.min(#s, 40) do
    local c = string.sub(s, i, i); local b = string.byte(c)
    if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or (b >= 48 and b <= 57) or c == "-" or c == "_" then out = out .. c
    elseif c == " " or c == "'" or c == "." then out = out .. "_" end
  end
  return out
end
-- Files are per server: characters on different servers can share a name and
-- even an ID.
local function quest_file_name()
  if not my_player or not my_server then return nil end
  local sv = string.sub(safe_name(my_server), 1, 16)
  local n = my_name and string.sub(safe_name(my_name), 1, 30) or ""
  return (#sv > 0 and (sv .. "_") or "") .. (#n > 0 and (n .. "_") or "q_") .. string.format("%08X", my_player)
end
local function legacy_quest_file_name()
  local n = my_name and safe_name(my_name) or ""
  return (#n > 0 and (n .. "_") or "q_") .. string.format("%08X", my_player)
end
local function db_file_name()
  local sv = my_server and string.sub(safe_name(my_server), 1, 30) or ""
  return (#sv > 0) and (DB_NAME .. "_" .. sv) or DB_NAME
end
local function count_keys(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
-- Kill tasks on your quest list: tasks whose counter or completion flag the server listed.
local function kill_tasks_read()
  local n = 0
  for _, id in ipairs(all_ids()) do
    local t = task(id)
    if (t.key and st.q[t.key]) or (t.done and st.q[t.done]) then n = n + 1 end
  end
  return n
end

local function quest_file_data(server)
  local q, bytes, n = {}, 0, 0
  for k, v in pairs(QALL) do
    n = n + 1
    local e = {s = v.s or 0, t = v.t or 0, m = v.m or 0, d = v.d or 0}
    bytes = bytes + #k + 24
    if v.desc and bytes < 200000 then e.x = v.desc; bytes = bytes + #v.desc end
    q[k] = e
  end
  return {kt_quests = true, character = my_name or "", server = server or "", saved = qfile.data_at or unix_now or 0, count = n, q = q}
end

local function on_quest_file(data)
  if type(data) ~= "table" or type(data.q) ~= "table" then return end
  local n = 0
  for k, v in pairs(data.q) do
    if type(v) == "table" and type(k) == "string" then
      n = n + 1
      local e = QALL[k]
      if not e then
        e = {s = tonumber(v.s) or 0, t = tonumber(v.t) or 0, m = tonumber(v.m), d = tonumber(v.d), desc = v.x}
        QALL[k] = e
      elseif not e.desc then e.desc = v.x end
      local known = guard.FLAG[k] or DONE_OWNER[k] or BASE[k] or BY_DONE[k] or CAT_BY_FLAG[k] or db.tasks[k]
      if (known or is_kill_key(k)) and not st.q[k] then
        st.q[k] = {s = e.s, t = e.t, m = e.m, d = e.d, desc = e.desc}; dirty = true
      elseif st.q[k] and not st.q[k].desc then st.q[k].desc = e.desc end
    end
  end
  qfile.saved, qfile.count = tonumber(data.saved), n
  qfile.data_at = tonumber(data.saved)
  ids_cache = nil
end

-- Tasks found in your quest list (no catalog entry): their completion flag is
-- the one sharing the counter's name, e.g. busydoorkillcount -> busydoorkilltask.
local learn_pending = false
local DONE_END = {task = true, wait = true, imer = true, eted = true, lete = true}
local function learn_done_flags()
  learn_pending = false
  local need = false
  for id, d in pairs(db.tasks) do if d.key and not d.done and not BASE[id] and not CAT[id] then need = true; break end end
  if not need then return end
  local function strip(k, sufs)
    for _, suf in ipairs(sufs) do
      if #k > #suf and string.sub(k, -#suf) == suf then return string.sub(k, 1, #k - #suf) end
    end
    return nil
  end
  local DONE_SUF = {"killtaskwait", "killtask", "taskwait", "completed", "complete", "timer", "wait", "task"}
  local COUNT_SUF = {"killcounter", "killcount", "counter", "count", "kills"}
  local by_stem = {}
  for k in pairs(QALL) do
    if DONE_END[string.sub(k, -4)] then
      local stem = strip(k, DONE_SUF)
      if stem and #stem >= 5 then by_stem[stem] = by_stem[stem] or k end
    end
  end
  for id, d in pairs(db.tasks) do
    if d.key and not d.done and not BASE[id] and not CAT[id] then
      local stem = strip(d.key, COUNT_SUF)
      local k = stem and by_stem[stem]
      if k and k ~= d.key then d.done = k; DONE_OWNER[k] = id; mark_db() end
    end
  end
end

-- After a complete reply, drop flags the server no longer lists.
local function finish_myquests()
  if not mq.active or tick_now - mq.seen_at < 4 or queued() > 0 or chat_left > 0 then return end
  mq.active, mq.end_at = false, tick_now
  mq.done_lines, mq.done_ok, mq.done_unix = mq.run_lines, not mq.run_gap, unix_now
  mq.done_unparsed = mq.unparsed
  qfile.data_at = unix_now
  mq.unparsed = 0
  local gone = 0
  if not mq.run_gap and mq.run_lines >= 3 then
    local drop = {}
    for k, q in pairs(st.q) do if q.r ~= mq.run then drop[#drop + 1] = k end end
    for _, k in ipairs(drop) do st.q[k] = nil end
    gone = #drop
    drop = {}
    for k, q in pairs(QALL) do if q.r ~= mq.run then drop[#drop + 1] = k end end
    for _, k in ipairs(drop) do QALL[k] = nil end
    learn_pending = true
    -- A finished task whose counter is no longer on the server was turned in.
    for id, pr in pairs(st.prog) do
      local t = task(id)
      if t and t.key and pr.done and not QALL[t.key] and (pr.at or 0) < (mq.sent_at or 0) then
        st.prog[id] = nil; gone = gone + 1; st.done_at[id] = unix_now
        if not (t.done and QALL[t.done]) and unix_now then st.cd[id] = unix_now + (t.cd_h or tonumber(opt("cooldown_hours")) or 20) * 3600 end
      end
    end
    -- A pickup from using a giver: its counter on the server confirms it; no
    -- counter (and no kills since) means the giver didn't hand it out.
    for id, pr in pairs(st.prog) do
      local t = task(id)
      if pr.prov and t and t.key then
        if QALL[t.key] then pr.prov = nil
        elseif (int(pr.n) or 0) == 0 and (pr.at or 0) < (mq.sent_at or 0) then st.prog[id] = nil; gone = gone + 1 end
      end
    end
    -- 4.17.7: the quest list overrules everything worked out from chat before
    -- the read was sent (newer kill messages still count until the next read).
    local sent = mq.sent_at or 0
    for id, pr in pairs(st.prog) do
      local t = task(id)
      -- The server's counter is shown instead; no counter: not picked up.
      if t and t.key and (pr.at or 0) < sent and (QALL[t.key] or not pr.done) then st.prog[id] = nil end
    end
    for id, at in pairs(st.done_at) do
      local t = task(id)
      local q, d = t and t.key and QALL[t.key], t and t.done and QALL[t.done]
      if at < sent and t.done then
        -- A turn-in the tracker credited, but the server kept the counter and
        -- didn't stamp the completion flag then: it wasn't this task.
        if q and (q.t or 0) <= at and not (d and (d.t or 0) >= at - 120) then st.done_at[id] = nil; st.cd[id] = nil
        -- The completion flag's own timer gives the cooldown.
        elseif d and (d.d or 0) > 0 then st.cd[id] = nil end
      end
    end
  elseif mq.run_gap then
    note("Some quest lines were lost (chat backlog overflow); nothing was removed")
  end
  qfile.want_save = true
  ids_cache = nil; dirty = true
  note("Kill tasks read: " .. kill_tasks_read() .. (gone > 0 and (", " .. gone .. " finished cleared") or ""))
end

---------------------------------------------------------------------------
-- Shared task database file (profiles service): read once, save when changed
---------------------------------------------------------------------------
local dbf = {phase = "start", err = nil, save_at = nil, fails = 0}
local legacy_custom = {}   -- tasks from the old shared database, adopted when this character has their flags
local function adopt_legacy()
  for tid, t in pairs(legacy_custom) do
    if (t.key and QALL[t.key]) or (t.done and QALL[t.done]) or st.prog[tid] then
      if not db.tasks[tid] then db.tasks[tid] = t; db_dirty = true; dirty = true; need_rebuild = true end
      legacy_custom[tid] = nil
    end
  end
end
local function merge_db(src)
  if type(src) ~= "table" or type(src.tasks) ~= "table" then return end
  if type(src.areas) == "table" then
    db.areas = db.areas or {}
    local have = {}
    for _, a in ipairs(db.areas) do have[a] = true end
    for _, a in ipairs(src.areas) do if type(a) == "string" and not have[a] then db.areas[#db.areas + 1] = a; have[a] = true end end
    refresh_areas()
  end
  for id, t in pairs(src.tasks) do
    if type(t) == "table" then
      local cur = db.tasks[id]
      if not cur then db.tasks[id] = t
      else for k, v in pairs(t) do if cur[k] == nil then cur[k] = v end end end
    end
  end
end

local function file_services(s, now)
  if dbf.phase == "start" and my_server then
    request({id = "db_read", service = "profiles", operation = "read", group = DB_GROUP, name = db_file_name()}); dbf.phase = "reading"
  elseif dbf.phase == "ready" and db_dirty then
    dbf.save_at = dbf.save_at or (now + 5); db_dirty = false
  end
  if dbf.phase == "ready" and dbf.save_at and now >= dbf.save_at then
    request({id = "db_save", service = "profiles", operation = "save", group = DB_GROUP, name = db_file_name(), data = {kt_db_file = true, server = my_server, kt_db = db}})
    dbf.save_at = nil
  end
  if qfile.phase == "wait" then
    qfile.name = quest_file_name()
    if qfile.name then
      request({id = "qf_read", service = "profiles", operation = "read", group = QUEST_GROUP, name = qfile.name}); qfile.phase = "reading"
    end
  elseif qfile.phase == "ready" and qfile.want_save and qfile.name then
    qfile.want_save = false
    request({id = "qf_save", service = "profiles", operation = "save", group = QUEST_GROUP, name = qfile.name, data = quest_file_data(s.server)})
  end
  if next(legacy_custom) and qfile.phase == "ready" then adopt_legacy() end
end

local function handle_results(s)
  for _, e in ipairs(s.events or {}) do
    if e.type == "result" and type(e.id) == "string" then
      if not retry_if_limited(e) then
        local id = e.id
        if id == "db_read" then
          if e.ok and type(e.data) == "table" then merge_db(e.data.kt_db); need_rebuild = true; dbf.phase = "ready"
          else
            -- First time on this server: take generic details (goals, giver IDs) from the
            -- old shared file; its own tasks are adopted only if this character has them.
            request({id = "db_read_old", service = "profiles", operation = "read", group = DB_GROUP, name = DB_NAME})
          end
        elseif id == "db_read_old" then
          if e.ok and type(e.data) == "table" and type(e.data.kt_db) == "table" and type(e.data.kt_db.tasks) == "table" then
            for tid, t in pairs(e.data.kt_db.tasks) do
              if type(t) == "table" then
                if BASE[tid] or CAT[tid] then
                  local cur = db.tasks[tid] or {}
                  for k, v in pairs(t) do if cur[k] == nil then cur[k] = v end end
                  db.tasks[tid] = cur
                elseif t.custom then legacy_custom[tid] = t end
              end
            end
            need_rebuild = true; db_dirty = true
          end
          dbf.phase = "ready"
        elseif id == "db_save" then
          if e.ok then dbf.err = nil; dbf.fails = 0
          else dbf.err = tostring(e.error); dbf.fails = dbf.fails + 1; if dbf.fails < 3 then db_dirty = true end end
        elseif id == "qf_read" then
          if e.ok then on_quest_file(e.data); qfile.phase = "ready"; guard.busy_at = tick_now
          else
            request({id = "qf_read_old", service = "profiles", operation = "read", group = QUEST_GROUP, name = legacy_quest_file_name()})
          end
        elseif id == "qf_read_old" then
          -- Old file name (no server): use it only if it was saved on this server.
          if e.ok and type(e.data) == "table" and e.data.server == my_server then on_quest_file(e.data); qfile.want_save = true; guard.busy_at = tick_now end
          qfile.phase = "ready"
        elseif id == "qf_save" then
          if e.ok then qfile.err = nil; qfile.saved = qfile.data_at or unix_now; qfile.count = count_keys(QALL)
          else qfile.err = tostring(e.error); qfile.fails = qfile.fails + 1; if qfile.fails < 3 then qfile.want_save = true end end
        elseif string.sub(id, 1, 4) == "chat" and e.ok == false then
          note("Chat send failed: " .. tostring(e.error))
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Task details (window and "Show in chat")
---------------------------------------------------------------------------
local function info_lines(id)
  local t = task(id)
  local stt, p, left = status(id)
  local out = {}
  local head = (t.quest or t.name or id)
  if t.npc then head = head .. " - giver: " .. t.npc end
  if t.loc then head = head .. " (" .. t.loc .. ")" end
  out[#out + 1] = head
  -- Distinct monster names only (skip "niffi" when "niffis" is listed).
  local mobs = {}
  for _, m in ipairs(t.mobs or {}) do
    local dup = false
    for _, k in ipairs(mobs) do if string.sub(m, 1, #k) == k or string.sub(k, 1, #m) == m then dup = true end end
    if not dup and #mobs < 3 then mobs[#mobs + 1] = m end
  end
  local goal = int((p and p.g) or t.goal)
  local line = "Kill " .. (goal and (goal .. " ") or "") .. (#mobs > 0 and table.concat(mobs, " / ") or "(monster unknown - add it under Manage > Detected)")
  if stt == "active" then line = line .. " - progress " .. p.n .. (p.g and ("/" .. p.g) or "")
  elseif stt == "turnin" then line = line .. " - done, turn in"
  elseif stt == "cooldown" then line = line .. " - available again in " .. dur(left)
  else line = line .. " - available" end
  out[#out + 1] = line
  local flags = {}
  for _, k in ipairs({t.key, t.done}) do
    local q = k and (st.q[k] or QALL[k])
    if q then
      local f = k .. " " .. (int(q.s) or 0) .. ((q.m and q.m > 0) and ("/" .. int(q.m)) or "") .. " solves"
      if q.d and q.d > 0 then f = f .. ", repeat " .. dur(q.d) end
      if q.t and q.t > 0 and unix_now then f = f .. ", last " .. dur(unix_now - q.t) .. " ago" end
      flags[#flags + 1] = f
    end
  end
  if #flags > 0 then out[#out + 1] = "Quest flags: " .. table.concat(flags, "; ") end
  if t.server and #t.server > 0 then out[#out + 1] = "Catalog note: listed for " .. t.server .. " only" end
  for i, l in ipairs(out) do out[i] = string.sub(l, 1, 400) end
  return out
end

local function show_in_chat(tid)
  if not task(tid) then return end
  local lines = info_lines(tid)
  if not task(tid).npc then lines[#lines + 1] = "Quest giver unknown: add it under Manage > Detected, or it is learned when you turn the task in." end
  for _, l in ipairs(lines) do
    notice(l)
  end
end

---------------------------------------------------------------------------
-- Task editor (Manage > Tasks)
---------------------------------------------------------------------------
local function join_mobs(mobs)
  -- Show one name per monster (skip the singular/plural duplicates).
  local shown = {}
  for _, m in ipairs(mobs or {}) do
    local dup = false
    for _, k in ipairs(shown) do if string.sub(m, 1, #k) == k or string.sub(k, 1, #m) == m then dup = true end end
    if not dup then shown[#shown + 1] = m end
  end
  return table.concat(shown, ", ")
end
-- Forms: `edraft` edits one listed task in place (its Edit button); `draft`
-- is the new-task form under Manage > Add.
local edit_id, edraft = nil, {}
-- 5.0.0: the edit menu shows both quest flags. Known tasks fill them in from
-- the built-in data and catalog; otherwise from your quest list: a kill
-- counter whose description names the task's monster, and the completion flag
-- sharing the counter's name (busydoorkillcount -> busydoorkilltask).
function guard.suggest(id)
  local t = task(id)
  local key, done = t.key, t.done
  -- Candidates are the (cached) kill-like flags offered in the pickers.
  local flags = guard.flag_lists()
  if not key and t.mobs and #t.mobs > 0 then
    for i = 2, #flags.k do
      local k = flags.k[i]
      local q = QALL[k]
      if not guard.FLAG[k] and not DONE_OWNER[k] and q and q.desc then
        local d = string.lower(q.desc)
        for _, m in ipairs(t.mobs) do if #m >= 4 and contains(d, m) then key = k; break end end
        if key then break end
      end
    end
  end
  if key and not done then
    local stem = key
    for _, suf in ipairs({"killcounter", "killcount", "counter", "count", "kills"}) do
      if #stem > #suf and string.sub(stem, -#suf) == suf then stem = string.sub(stem, 1, #stem - #suf); break end
    end
    if #stem >= 5 then
      for i = 2, #flags.d do
        local k = flags.d[i]
        if string.sub(k, 1, #stem) == stem and not DONE_OWNER[k] then done = k; break end
      end
    end
  end
  return key or "", done or ""
end
local function form_from(id)
  local t = task(id)
  local key, done = guard.suggest(id)
  return {id = id, name = t.name or "", mobs = join_mobs(t.mobs), goal = t.goal and tostring(int(t.goal)) or "",
    npc = t.npc or "", area = area_of(t), cd = t.cd_h and tostring(int(t.cd_h) == t.cd_h and int(t.cd_h) or t.cd_h) or "",
    key = key, done = done}
end
-- A quest flag as typed: lower case, no spaces; "" when blank.
function guard.flag_text(v)
  local f = string.lower(trim(tostring(v or "")))
  if #f > 80 or contains(f, " ") then return nil end
  return f
end
-- Saves a form; returns the task id, or nil (with a note) when something is missing.
local function save_form(f)
  local name = trim(f.name or "")
  local mobs = {}
  for _, m in ipairs(split_commas(f.mobs or "")) do for _, x in ipairs(singulars(m)) do mobs[#mobs + 1] = x end end
  local npc = trim(f.npc or "")
  local goal, cd = tonumber(f.goal), tonumber(f.cd)
  local key, done = guard.flag_text(f.key), guard.flag_text(f.done)
  if not key or not done then note("Quest flags are one word, up to 80 characters"); return nil end
  local id = f.id
  local new_id = (not id) and ("c_" .. slug(name)) or nil
  -- A flag can belong to one task only. One that only an unused catalog task
  -- (no details of yours, no progress) has is moved to this task.
  local take = {}
  for _, k in ipairs({key, done}) do
    local owner = k ~= "" and (guard.FLAG[k] or DONE_OWNER[k])
    if owner and owner ~= (id or new_id) then
      local od = db.tasks[owner]
      if CAT[owner] and not BASE[owner] and not st.prog[owner] and not (od and (od.name or od.mobs or od.npc or od.goal or od.area or od.key or od.done)) then
        take[#take + 1] = {owner, k}
      else note(k .. " already belongs to " .. display(task(owner))); return nil end
    end
  end
  if key ~= "" and key == done then note("The counter and completion flags must differ"); return nil end
  for _, tk in ipairs(take) do
    local ot = task(tk[1])
    local od = db_task(tk[1])
    if ot.key == tk[2] then od.nokey = true end
    if ot.done == tk[2] then od.nodone = true end
  end
  if not id then
    if #name == 0 or #mobs == 0 then note("Enter a name and at least one monster"); return nil end
    id = new_id
    if #id <= 2 then note("Enter a name with letters or digits"); return nil end
    db.tasks[id] = {name = name, custom = true, srv = my_server}
  end
  local d = db_task(id)
  local b = BASE[id] or CAT[id]
  if #name > 0 and (not b or name ~= b.name) then d.name = name end
  d.mobs = (#mobs > 0) and mobs or nil
  d.goal = goal and int(goal) or nil
  d.npc = (#npc > 0) and npc or nil
  d.area = AREA_SET[f.area or ""] and f.area or "Other"
  d.cd_h = cd
  -- Flags: an override only where it differs from the built-in/catalog flag.
  if b then
    d.key = (key ~= "" and key ~= b.key) and key or nil
    d.done = (done ~= "" and done ~= b.done) and done or nil
  else
    if key ~= "" then d.key = key end
    d.done = (done ~= "") and done or nil
  end
  mark_db(); rebuild_indexes()
  -- The quest list already holds these flags: count them now.
  local t = task(id)
  for _, k in ipairs({t.key, t.done}) do
    local q = k and QALL[k]
    if q and not st.q[k] then st.q[k] = {s = q.s, t = q.t, m = q.m, d = q.d, desc = q.desc, r = q.r} end
  end
  ids_cache = nil; dirty = true; guard.fs = nil
  note("Saved " .. display(task(id)) .. ((#take > 0) and (" (" .. take[1][2] .. " moved from " .. display(task(take[1][1])) .. ")") or ""))
  return id
end
local function reset_task(tid)
  st.prog[tid] = nil; st.cd[tid] = nil; st.done_at[tid] = nil; ids_cache = nil; dirty = true
  note("Progress cleared for " .. display(task(tid)))
end
local function delete_task(tid)
  local was_custom = db.tasks[tid] and db.tasks[tid].custom
  db.tasks[tid] = nil; mark_db()
  if was_custom then st.prog[tid] = nil; st.cd[tid] = nil; note("Deleted task")
  else note("Restored the original task details") end
  rebuild_indexes()
end
-- Areas you add: 1-30 characters, not a name already in use.
local function add_area(name)
  name = trim(name or "")
  if #name == 0 or #name > 30 then note("Area names are 1-30 characters"); return end
  for _, a in ipairs(VIEWS) do if string.lower(a) == string.lower(name) then note(a .. " already exists"); return end end
  db.areas = db.areas or {}
  if #db.areas >= 30 then note("At most 30 areas of your own"); return end
  db.areas[#db.areas + 1] = name
  refresh_areas(); mark_db(); ids_cache = nil
  note("Added area " .. name)
end
local function remove_area(name)
  local keep = {}
  for _, a in ipairs(db.areas or {}) do if a ~= name then keep[#keep + 1] = a end end
  db.areas = keep
  for _, d in pairs(db.tasks) do if d.area == name then d.area = nil end end  -- back to its own area (or Other)
  refresh_areas(); mark_db(); rebuild_indexes()
  if st.opt.view == name then st.opt.view = nil; dirty = true end
  note("Removed area " .. name .. " (its tasks went back to their own area or Other)")
end

---------------------------------------------------------------------------
-- UI events
---------------------------------------------------------------------------
-- The form behind an edit-menu control: "ie" (E), "ed" (Manage > Add) or
-- "d1".."d5" (the Detected page's slots).
function guard.form_of(pfx)
  if pfx == "ie" then return edit_id and edraft or nil end
  if pfx == "ed" then return draft end
  if pfx == "qe" then return guard.qsel and guard.qdraft or nil, guard.qsel end
  local n = string.sub(pfx, 1, 1) == "d" and tonumber(string.sub(pfx, 2))
  local tid = n and guard.DSLOT[n]
  if not tid then return nil end
  fill[tid] = fill[tid] or form_from(tid)
  return fill[tid], tid
end
local function handle_events(s, now)
  for _, e in ipairs(s.events or {}) do
    local id = type(e.id) == "string" and e.id or ""
    local cut = string.contains(id, "_") and regexmatch(id, "^([a-z0-9]+)_([a-z]+)$")
    local pfx, field = cut and cut["1"], cut and cut["2"]
    if e.type == "click" then
      if string.sub(id, 1, 5) == "chat|" and guard.BAR[id] then show_in_chat(guard.BAR[id])
      elseif SEL_IDS[id] then
        local target = SEL_TARGET[SEL_IDS[id]]
        if target then pending_select = target else note("None in range") end
      elseif EDIT_IDS[id] then
        -- E opens this task's edit menu under its bar; E again closes it.
        -- One edit menu at a time (a window holds at most 256 controls).
        if edit_id == EDIT_IDS[id] then edit_id = nil else edit_id = EDIT_IDS[id]; edraft = form_from(edit_id); guard.qsel = nil end
      elseif id == "ie_save" and edit_id then
        edraft.id = edit_id
        if save_form(edraft) then edit_id = nil end
      elseif id == "ie_cancel" then edit_id = nil
      elseif id == "ie_reset" and edit_id then reset_task(edit_id); edit_id = nil
      elseif id == "ie_del" and edit_id then delete_task(edit_id); edit_id = nil
      elseif id == "ed_save" then
        draft.id = nil
        if save_form(draft) then draft = {area = draft.area or "Other"} end
      elseif guard.FM and guard.FM[id] then
        local m, f = guard.FM[id], pfx and guard.form_of(pfx)
        if f then
          guard.fs_ignore = {pfx = pfx, field = m.field, text = f[m.field]}
          f[m.field] = m.flag
        end
        guard.fs = nil
      elseif id == "bp_prev" then guard.bpage = math.max(1, (guard.bpage or 1) - 1)
      elseif id == "bp_next" then guard.bpage = (guard.bpage or 1) + 1
      elseif string.sub(id, 1, 3) == "qr|" and guard.QRES[id] then
        -- Quest log search: a result opens its edit menu under the list; again closes it.
        local tid = guard.QRES[id]
        if guard.qsel == tid then guard.qsel = nil else guard.qsel = tid; guard.qdraft = form_from(tid); edit_id = nil end
      elseif id == "qe_save" and guard.qsel then
        guard.qdraft.id = guard.qsel
        if save_form(guard.qdraft) then guard.qsel = nil end
      elseif id == "qe_cancel" then guard.qsel = nil
      elseif id == "qe_reset" and guard.qsel then reset_task(guard.qsel); guard.qsel = nil
      elseif id == "qe_del" and guard.qsel then delete_task(guard.qsel); guard.qsel = nil
      elseif id == "qp_prev" then guard.qpage = math.max(1, (guard.qpage or 1) - 1)
      elseif id == "qp_next" then guard.qpage = (guard.qpage or 1) + 1
      elseif id == "dp_prev" then guard.dpage = math.max(1, (guard.dpage or 1) - 1)
      elseif id == "dp_next" then guard.dpage = (guard.dpage or 1) + 1
      elseif pfx and (field == "save" or field == "rm") and string.sub(pfx, 1, 1) == "d" then
        local f, tid = guard.form_of(pfx)
        if tid and field == "save" then
          f.id = tid
          if save_form(f) then fill[tid] = nil end
        elseif tid then
          -- Remove from Detected: a task made from a kill message is deleted; one
          -- from your quest list (it would come back with the next read), a
          -- built-in or a catalog task just stops being listed there.
          local d = db.tasks[tid]
          fill[tid] = nil
          if d and d.custom and not d.key then delete_task(tid)
          else db_task(tid).nofill = true; mark_db(); note("Removed " .. display(task(tid)) .. " from Detected") end
        end
      elseif id == "na_add" then add_area(new_area); new_area = ""
      elseif AREA_IDS[id] then remove_area(AREA_IDS[id])
      end
      if e.ok == false and e.error and #e.error > 0 then note(e.error) end
    elseif e.type == "change" then
      local v = e.value
      local f = pfx and guard.form_of(pfx)
      if id == "view" then st.opt.view = v; dirty = true; guard.bpage = 1
      elseif id == "qs_text" then guard.qs = string.sub(tostring(v or ""), 1, 60); guard.qpage = 1
      elseif f and field == "pick" then
        if v == PICK_REFRESH then
          -- Giver pickers are filled only on request: the NPCs within 30 m now, sorted.
          local names, seen = {}, {}
          for _, o in ipairs(s.objects or {}) do
            if (tonumber(o.distance) or 1e9) > 30 then break end  -- nearest first
            if type(o.name) == "string" and not o.monster and not o.player and not o.corpse and not seen[o.name] and #names < 24 then
              seen[o.name] = true; names[#names + 1] = o.name
            end
          end
          table.sort(names)
          picker_names = names
          if #names == 0 then note("No NPCs within 30 m") end
        elseif v and v ~= PICK_HINT then f.npc = tostring(v) end
      elseif f and (field == "key" or field == "done") then
        local txt = tostring(v or "")
        local ig = guard.fs_ignore
        -- After a match is picked, the box can still send what was typed when it
        -- loses focus; that is ignored so the picked flag stays.
        if ig and ig.pfx == pfx and ig.field == field and ig.text == txt then guard.fs_ignore = nil
        else
          f[field] = txt
          guard.fs = {pfx = pfx, field = field, text = string.lower(trim(txt))}
        end
      elseif f and field then f[field] = v
      elseif id == "na_name" then new_area = tostring(v or "")
      elseif string.sub(id, 1, 4) == "opt|" then st.opt[string.sub(id, 5)] = v; dirty = true
        if id == "opt|myq_hide" and v == false then guard.clear_filters = true end
        if id == "opt|show_nav" and v == false and nav.id ~= 0 then
          request({id = "nav_clear", service = "waypoint", operation = "clear"})
          nav.id, nav.pos = 0, nil
        end
      end
    elseif e.type == "use" then guard.on_use(e, s)
    elseif e.type == "command" then
      local t = string.lower(trim(e.text or ""))
      if t == "reset" then st.prog, st.cd, st.npc_cd, st.q, st.done_at = {}, {}, {}, {}, {}; ids_cache = nil; dirty = true; note("Progress cleared")
      elseif t == "refresh" then request_myquests("command", now) end
    end
  end
end

---------------------------------------------------------------------------
-- Unknown counters: link a monster named in the quest description
---------------------------------------------------------------------------
local desc_tried, desc_sig = {}, ""
local function auto_link_descriptions(monsters)
  local unl = {}
  for key, q in pairs(st.q) do
    local t = db.tasks[key]
    if t and (not t.mobs or #t.mobs == 0) and q.desc and #q.desc > 0 then unl[#unl + 1] = {key = key, desc = string.lower(q.desc)} end
  end
  if #unl == 0 then return end
  local sig = #unl .. ":" .. unl[1].key
  if sig ~= desc_sig then desc_tried, desc_sig = {}, sig end
  local budget = 1500
  for _, o in ipairs(monsters) do
    local lname = string.lower(o.name)
    if not MOB[lname] and not desc_tried[lname] and budget >= #unl then
      budget = budget - #unl; desc_tried[lname] = true
      for _, u in ipairs(unl) do
        if contains(u.desc, lname) then
          db.tasks[u.key].mobs = {lname}; mark_db(); rebuild_indexes()
          note("Linked " .. o.name .. " to quest " .. u.key)
          return
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function uid(prefix, key) return prefix .. string.sub(key, 1, 64 - #prefix) end
local function ago(sec) if sec < 60 then return "just now" end; return dur(sec) .. " ago" end

-- Markers, the NAV target and the Select buttons' targets: every callback,
-- from the nearby objects. Only the tasks of nearby givers and monsters are
-- looked at (each once), so this stays cheap and always current.
function guard.marks(scan)
  local markers = {}
  SEL_TARGET = {}
  local memo = {}
  local function st_of(id)
    local m = memo[id]
    if m == nil then m = status(id) or false; memo[id] = m end
    return m or nil
  end
  -- Quest-giver "!": turn in > in progress > available > cooldown
  local RANK = {turnin = 4, active = 3, available = 2, cooldown = 1}
  local COLOR = {turnin = opt("col_turnin"), active = opt("col_progress"), available = opt("col_available"), cooldown = opt("col_cooldown")}
  local npc_state, giver_obj = {}, {}
  for _, o in ipairs(scan.npcs) do
    local best
    for _, id in ipairs(npc_ids(o.name, o.wcid)) do
      giver_obj[id] = giver_obj[id] or o
      local stt = st_of(id)
      if stt and (not best or RANK[stt] > RANK[best]) then best = stt end
    end
    local cd = st.npc_cd[npc_cd_key(o.name, math.floor(tonumber(o.wcid) or 0))] or ((not shared(o.name)) and st.npc_cd[norm(o.name)])
    if (not best or best == "available") and cd and unix_now and cd > unix_now then best = "cooldown" end
    if best then
      npc_state[o.id] = best
      if opt("npc_marks") and #markers < 32 then markers[#markers + 1] = {id = o.id, shape = "!", color = COLOR[best]} end
    end
  end

  -- Monster arrows + nearest per task
  local near, nav_target = {}, nil
  for _, o in ipairs(scan.monsters) do
    local lname = string.lower(o.name)
    local id = MOB[lname]
    local l = MOB[0] and MOB[0][lname]
    if l and #l > 1 then for _, x in ipairs(l) do if st_of(x) == "active" then id = x; break end end end
    if id and st_of(id) == "active" then
      near[id] = near[id] or o
      nav_target = nav_target or o
      if opt("show_nav") and #markers < 32 then markers[#markers + 1] = {id = o.id, shape = "arrow", color = "green"} end
    end
  end
  -- Nothing to hunt nearby: point at a quest giver waiting for a turn-in.
  if not nav_target then
    for _, o in ipairs(scan.npcs) do if npc_state[o.id] == "turnin" then nav_target = o; break end end
  end
  -- Select: the nearest monster of a task in progress, else its quest giver.
  for id, o in pairs(giver_obj) do SEL_TARGET[id] = o.id end
  for id, o in pairs(near) do SEL_TARGET[id] = o.id end
  return markers, nav_target
end

-- One text key per marker list, so markers are sent only when they change.
function guard.marker_key(markers)
  local k = {}
  for i, m in ipairs(markers) do k[i] = m.id .. m.shape .. tostring(m.color) end
  return table.concat(k, ",")
end

-- 5.0.0: one edit menu everywhere (E, Detected, Manage > Add).
-- The flag lists change only when a quest-list read ends or the quest file
-- loads, so they are worked out then and reused by every window build.
function guard.flag_lists()
  local sig = tostring(mq.done_unix) .. "|" .. tostring(qfile.phase)
  if guard.flags and guard.flags_sig == sig then return guard.flags end
  -- Loading the quest file is the heaviest update; the lists wait for the next one.
  if guard.busy_at == tick_now then guard.flags_pending = true; return guard.flags or {k = {guard.FLAG_HINT}, d = {guard.FLAG_HINT}} end
  guard.flags_pending = false
  local k, d = {}, {}
  -- Plain text tests only: the client allows about 20 ms of regex work per
  -- update, and a pattern test on every flag of a long quest list went over it.
  for key, q in pairs(QALL) do
    local kill = contains(key, "kill") or contains(key, "slay") or contains(key, "cull")
    if kill or (q.m and q.m > 1) then
      local role = flag_role(key)
      if role == "counter" then k[#k + 1] = key
      elseif role == "done" and kill then d[#d + 1] = key end
    end
  end
  table.sort(k); table.sort(d)
  local K, D = {guard.FLAG_HINT}, {guard.FLAG_HINT}
  for i = 1, math.min(#k, 120) do K[#K + 1] = k[i] end
  for i = 1, math.min(#d, 120) do D[#D + 1] = d[i] end
  guard.flags, guard.flags_sig = {k = K, d = D}, sig
  return guard.flags
end
function guard.editor(pfx, f, picker, flags)
  local B = TXT.body
  return {
    {id = pfx .. "_name", type = "input", size = B, text = "Name", value = f.name or ""},
    {id = pfx .. "_mobs", type = "input", size = B, text = "Monster name(s), comma separated", value = f.mobs or ""},
    {id = pfx .. "_npc", type = "input", size = B, text = "Quest giver", value = f.npc or ""},
    {id = pfx .. "_pick", type = "select", size = B, text = "...or pick a nearby NPC", value = picker[1], options = picker},
    {id = pfx .. "_goal", type = "input", size = B, text = "Kills required", value = f.goal or ""},
    {id = pfx .. "_cd", type = "input", size = B, text = "Cooldown hours (blank = default)", value = f.cd or ""},
    {id = pfx .. "_area", type = "select", size = B, text = "Area", value = AREA_SET[f.area or ""] and f.area or "Other", options = AREAS},
    {id = pfx .. "_key", type = "input", size = B, text = "Counter quest flag", value = f.key or "", live = true, placeholder = "Type to search",
      tooltip = "The quest flag that counts your kills"},
    {id = pfx .. "_done", type = "input", size = B, text = "Completion quest flag", value = f.done or "", live = true, placeholder = "Type to search",
      tooltip = "The quest flag stamped when you turn the task in (its timer)"}}
end
-- 5.2.0: quest-flag search. Typing in a flag box lists up to 5 matching flags
-- under it (your quest list first, then the catalog and task database), for
-- that box only; clicking one fills it in.
guard.LETTER = {"a", "b", "c", "d", "e"}
function guard.flag_matches(text, field)
  local fs = guard.fs
  if fs.res and fs.res_text == text then return fs.res end
  local seen, mine, other = {}, {}, {}
  local function consider(k, listed)
    if type(k) ~= "string" or seen[k] or not contains(k, text) then return end
    seen[k] = true
    if (flag_role(k) == "done") ~= (field == "done") then return end
    if listed then mine[#mine + 1] = k else other[#other + 1] = k end
  end
  for k in pairs(QALL) do consider(k, true) end
  for _, e in ipairs(CATALOG) do for _, k in ipairs(e.f) do consider(k, false) end end
  for _, t in ipairs(TASKS) do consider(t.flag, false); consider(t.done_flag, false) end
  for _, d in pairs(db.tasks) do consider(d.key, false); consider(d.done, false) end
  table.sort(mine); table.sort(other)
  local res = {}
  for _, k in ipairs(mine) do if #res < 5 then res[#res + 1] = k end end
  for _, k in ipairs(other) do if #res < 5 then res[#res + 1] = k end end
  fs.res, fs.res_text = res, text
  return res
end
-- The editor's fields plus, under the flag box being typed in, its matches.
function guard.editor_with_search(pfx, f, picker, flags, mytid)
  local list = guard.editor(pfx, f, picker, flags)
  local fs = guard.fs
  if not (fs and fs.pfx == pfx and #fs.text >= 3) then return list end
  local out = {}
  for _, c in ipairs(list) do
    out[#out + 1] = c
    if c.id == pfx .. "_" .. fs.field then
      local res = guard.flag_matches(fs.text, fs.field)
      for n, k in ipairs(res) do
        local mid = pfx .. "_" .. string.sub(fs.field, 1, 1) .. guard.LETTER[n]
        guard.FM[mid] = {field = fs.field, flag = k}
        local owner = guard.FLAG[k] or DONE_OWNER[k]
        out[#out + 1] = {id = mid, type = "text", size = TXT.body, text = "   " .. k .. ((owner and owner ~= mytid) and (" - " .. display(task(owner))) or ""),
          clickable = true, tooltip = "Use this flag"}
      end
      if #res == 0 then out[#out + 1] = {id = pfx .. "_" .. string.sub(fs.field, 1, 1) .. "none", type = "text", size = TXT.small, text = "   No matching quest flags"} end
    end
  end
  return out
end
-- Each task's bar: fill and label color by state (soft fills keep the label readable).
guard.BAR_FILL = {active = "#D9D9D955", turnin = "#2E7D3299", available = "#00000000", cooldown = "#00000000"}
guard.BAR_TEXT = {active = "white", turnin = "green", available = "yellow", cooldown = "red"}

local function build(s)
  local ui = {}
  EDIT_IDS, AREA_IDS, SEL_IDS, guard.BAR, guard.FM = {}, {}, {}, {}, {}
  local flags = guard.flag_lists()
  local view = opt("view")

  -- Status, name and area of every task once (sorting must not call task()).
  local info = {}
  for _, id in ipairs(all_ids()) do
    local stt, p, left = status(id)
    local t = task(id)
    info[id] = {status = stt, p = p, left = left, name = display(t), area = area_of(t)}
  end
  -- 5.1.0: no "Active" list. With no saved area (or the old Active), show the
  -- area of a task in progress, else the first area.
  if not AREA_SET[view] then
    view = nil
    for _, id in ipairs(all_ids()) do
      local i = info[id]
      if i.status == "turnin" or i.status == "active" then view = i.area; break end
    end
    view = view or AREAS[1]
    -- Saved only once the task database (with your own areas) has loaded.
    if dbf.phase == "ready" then st.opt.view = view; dirty = true end
  end

  -- Top: Show in NAV, then the area selector
  ui[#ui + 1] = {id = "opt|show_nav", type = "checkbox", size = TXT.body, text = "Show in NAV", value = opt("show_nav") ~= false,
    tooltip = "Arrows over task monsters, and the NAV arrow pointing to the closest one"}
  ui[#ui + 1] = {id = "view", type = "select", size = TXT.body, value = view, options = VIEWS, tooltip = "Area"}

  -- Names of NPCs around you, to pick the quest giver exactly as the game spells it.
  local picker, seen_p = {PICK_HINT, PICK_REFRESH}, {}
  for _, n in ipairs(picker_names or {}) do
    if #picker >= 26 then break end
    if not seen_p[n] then seen_p[n] = true; picker[#picker + 1] = n end
  end
  -- One collapsible line per task: monster and count; details when opened.
  local rows = {}
  for _, id in ipairs(all_ids()) do
    local i = info[id]
    if i.area == view then rows[#rows + 1] = id end
  end
  -- Sort with precomputed text keys (the built-in comparison costs no Lua work).
  local ORDER = {turnin = 1, active = 2, available = 3, cooldown = 4}
  local keyed, by_key = {}, {}
  for _, id in ipairs(rows) do
    local k = ORDER[info[id].status] .. string.lower(info[id].name) .. "|" .. id
    keyed[#keyed + 1] = k; by_key[k] = id
  end
  table.sort(keyed)
  rows = {}
  for i, k in ipairs(keyed) do rows[i] = by_key[k] end
  -- 5.2.0: 14 bars per page, with < and > under them.
  local bpages = math.max(1, math.ceil(#rows / MAX_ROWS))
  guard.bpage = math.max(1, math.min(guard.bpage or 1, bpages))
  local first = (guard.bpage - 1) * MAX_ROWS
  local shown = 0
  for n = first + 1, math.min(#rows, first + MAX_ROWS) do
    local id = rows[n]
    shown = shown + 1
    local t, i = task(id), info[id]
    -- 5.1.0: one bar per task (name and progress) with three invisible click
    -- areas over it, left to right: Select, Chat (details in chat), Edit.
    local label, frac = display(t), 0
    local g = i.p and i.p.g and i.p.g > 0 and i.p.g or nil
    if i.status == "active" then
      label = label .. "  " .. i.p.n .. (g and (" / " .. g) or "")
      frac = g and math.min(1, i.p.n / g) or 0
    elseif i.status == "turnin" then
      if g then label = label .. "  " .. i.p.n .. " / " .. g end
      frac = 1
    elseif i.status == "cooldown" then label = label .. "  " .. dur(i.left) end
    local sb, cb, eb = uid("sel|", id), uid("chat|", id), uid("edit|", id)
    guard.BAR[cb], SEL_IDS[sb], EDIT_IDS[eb] = id, id, id
    local function zone(zid, tip) return {id = zid, type = "frame", color = "#00000000", clickable = true, height = 16, padding = 0, tooltip = tip} end
    ui[#ui + 1] = {id = uid("r|", id), type = "overlay", padding = 0, children = {
      {id = uid("bar|", id), type = "progress", size = TXT.body, padding = 0, value = frac, text = label,
        color = guard.BAR_FILL[i.status], text_color = guard.BAR_TEXT[i.status]},
      {id = uid("z|", id), type = "row", padding = 0, children = {zone(sb, "Select"), zone(cb, "Chat"), zone(eb, "Edit")}}}}
    if edit_id == id then
      -- Edit in place, under the bar: the fields of this task, saved to the task database.
      local is_custom = db.tasks[id] and db.tasks[id].custom
      local ebtn = {{id = "ie_save", type = "button", size = TXT.body, text = "Save"}, {id = "ie_cancel", type = "button", size = TXT.body, text = "Cancel"},
        {id = "ie_reset", type = "button", size = TXT.body, text = "Reset", tooltip = "Clear this task's kill count and timer for this character"}}
      if is_custom then ebtn[#ebtn + 1] = {id = "ie_del", type = "button", size = TXT.body, text = "Delete"}
      elseif db.tasks[id] then ebtn[#ebtn + 1] = {id = "ie_del", type = "button", size = TXT.body, text = "Undo", tooltip = "Back to the original task details"} end
      local body = guard.editor_with_search("ie", edraft, picker, flags, id)
      body[#body + 1] = {id = "ie_btns", type = "row", children = ebtn}
      ui[#ui + 1] = {id = "ie_box", type = "column", children = body}
    end
  end
  if bpages > 1 then
    ui[#ui + 1] = {id = "bp", type = "row", children = {
      {id = "bp_prev", type = "button", size = TXT.body, text = "<", auto_width = true, enabled = guard.bpage > 1},
      {id = "bp_n", type = "text", size = TXT.body, text = guard.bpage .. " / " .. bpages .. "  (" .. #rows .. " tasks)"},
      {id = "bp_next", type = "button", size = TXT.body, text = ">", auto_width = true, enabled = guard.bpage < bpages}}}
  end
  if shown == 0 then
    ui[#ui + 1] = {id = "empty", type = "text", size = TXT.body, text = "No tasks here yet."}
  end
  if #last_note > 0 then ui[#ui + 1] = {id = "note", type = "text", text = last_note, size = TXT.small} end
  if s.error and s.error ~= "" then ui[#ui + 1] = {id = "err", type = "text", size = TXT.body, color = "red", text = string.sub(s.error, 1, 200)} end

  -- Manage > Add: a new task, and areas of your own.
  local editor = {{id = "ed_head", type = "text", size = TXT.body, text = "New task", bold = true}}
  for _, c in ipairs(guard.editor_with_search("ed", draft, picker, flags)) do editor[#editor + 1] = c end
  editor[#editor + 1] = {id = "ed_save", type = "button", size = TXT.body, text = "Add task"}
  editor[#editor + 1] = {id = "na_head", type = "text", size = TXT.body, text = "Areas", bold = true}
  editor[#editor + 1] = {id = "na_row", type = "row", children = {
    {id = "na_name", type = "input", size = TXT.body, text = "New area", value = new_area},
    {id = "na_add", type = "button", size = TXT.body, text = "Add area"}}}
  for k, a in ipairs(db.areas or {}) do
    local bid = "ar|" .. k
    AREA_IDS[bid] = a
    editor[#editor + 1] = {id = bid, type = "button", size = TXT.body, text = "Remove " .. a, tooltip = "Its tasks go back to their own area, or Other"}
  end

  -- Detected: tasks found in your quest list or chat that still miss a monster
  -- or quest giver. 5.0.0: each is a closed drop-down holding the full edit
  -- menu, 5 per page (a window holds at most 256 controls).
  local detected, dkeys, dmap = {}, {}, {}
  for _, id in ipairs(all_ids()) do
    local t, d = task(id), db.tasks[id]
    local mine = (d and d.custom) or st.prog[id] or (t.key and st.q[t.key])
    if mine and not (d and d.nofill) and (not t.mobs or #t.mobs == 0 or not t.npc) then
      local k = ORDER[info[id].status] .. string.lower(info[id].name) .. "|" .. id
      dkeys[#dkeys + 1] = k; dmap[k] = id
    end
  end
  table.sort(dkeys)
  local per = 5
  local dpages = math.max(1, math.ceil(#dkeys / per))
  guard.dpage = math.max(1, math.min(guard.dpage or 1, dpages))
  guard.DSLOT = {}
  local WORD = {active = "in progress", turnin = "ready to turn in", cooldown = "on cooldown", available = "available"}
  for n = 1, per do
    local k = dkeys[(guard.dpage - 1) * per + n]
    if not k then break end
    local tid = dmap[k]
    guard.DSLOT[n] = tid
    local t = task(tid)
    -- A form made while the flag lists wait is not kept (it would miss its suggested flags).
    local form = fill[tid] or form_from(tid)
    if not guard.flags_pending then fill[tid] = form end
    local pfx = "d" .. n
    local body = guard.editor_with_search(pfx, form, picker, flags, tid)
    local q = t.key and (st.q[t.key] or QALL[t.key])
    if q and q.desc and q.desc ~= info[tid].name then
      table.insert(body, 1, {id = pfx .. "_desc", type = "text", size = TXT.small, text = t.key .. ": " .. q.desc})
    end
    body[#body + 1] = {id = pfx .. "_btns", type = "row", children = {
      {id = pfx .. "_save", type = "button", size = TXT.body, text = "Save"},
      {id = pfx .. "_rm", type = "button", size = TXT.body, text = "Remove", tooltip = "Remove from Detected"}}}
    detected[#detected + 1] = {id = uid("dsec|", tid), type = "section", size = TXT.body,
      text = info[tid].name .. " - " .. WORD[info[tid].status], expanded = false, children = body}
  end
  if dpages > 1 then
    detected[#detected + 1] = {id = "dp", type = "row", children = {
      {id = "dp_prev", type = "button", size = TXT.body, text = "<", auto_width = true, enabled = guard.dpage > 1},
      {id = "dp_n", type = "text", size = TXT.body, text = guard.dpage .. " / " .. dpages},
      {id = "dp_next", type = "button", size = TXT.body, text = ">", auto_width = true, enabled = guard.dpage < dpages}}}
  end
  if #detected == 0 then detected[1] = {id = "fnone", type = "text", size = TXT.body, text = "Nothing to fill in.",
    tooltip = "Kill tasks found in your quest list or in chat appear here when their monster or quest giver is unknown."} end

  -- Kill tasks on your quest list (counter or completion flag listed), for the
  -- count and the search below.
  local readids = {}
  for _, id in ipairs(all_ids()) do
    local t = task(id)
    if (t.key and st.q[t.key]) or (t.done and st.q[t.done]) then readids[#readids + 1] = id end
  end
  local nkill = #readids
  local qline
  if mq.active then
    qline = "Reading /myquests..."
  elseif mq.done_ok ~= nil then
    qline = "Kill tasks read: " .. nkill .. " (" .. ago((unix_now or 0) - (mq.done_unix or 0)) .. ")"
      .. (mq.done_ok and "" or ", some lines lost")
  elseif qfile.saved then
    qline = "Kill tasks read: " .. nkill .. " (saved " .. ago((unix_now or 0) - qfile.saved) .. ")"
  else
    qline = "No /myquests read yet"
  end
  if mq.req_at and not mq.active and mq.done_ok == nil and tick_now - mq.req_at > 10 then
    qline = qline .. " (asked " .. dur(tick_now - mq.req_at) .. " ago, no reply seen)"
  end
  local log = {
    {id = "lg1", type = "text", size = TXT.body, text = qline},
    {id = "lg1b", type = "text", size = TXT.small, text = ((mq.done_unparsed or 0) > 0) and (mq.done_unparsed .. " lines not understood (example: "
      .. tostring(mq.unparsed_sample) .. ")") or ""},
    {id = "lg2", type = "text", size = TXT.small, text = "Quest file: " .. (qfile.name and ("Profiles/kt_tracker/Library/Quests/" .. qfile.name .. ".json") or "waiting for character")
      .. (qfile.err and (" - save failed: " .. qfile.err) or "")},
    {id = "lg3", type = "text", size = TXT.small, text = "Task database: Profiles/kt_tracker/Library/Database/" .. db_file_name() .. ".json" .. (dbf.err and (" - save failed: " .. dbf.err) or "")}}

  if log[2].text == "" then table.remove(log, 2) end

  -- 5.1.0: search the kill tasks read from your quest list (name, monster,
  -- quest giver or quest flag); a result opens its edit menu under the list.
  guard.QRES = {}
  local want = string.lower(trim(guard.qs or ""))
  local qkeys, qmap = {}, {}
  for _, id in ipairs(readids) do
    local hit = #want == 0
    if not hit then
      local t = task(id)
      hit = contains(string.lower(info[id].name .. " " .. join_mobs(t.mobs) .. " " .. (t.npc or "") .. " " .. (t.key or "") .. " " .. (t.done or "")), want)
    end
    if hit then local k = string.lower(info[id].name) .. "|" .. id; qkeys[#qkeys + 1] = k; qmap[k] = id end
  end
  table.sort(qkeys)
  local qper = 6
  local qpages = math.max(1, math.ceil(#qkeys / qper))
  guard.qpage = math.max(1, math.min(guard.qpage or 1, qpages))
  log[#log + 1] = {id = "qs_text", type = "input", size = TXT.body, text = "Search kill tasks read (" .. #qkeys .. ")", value = guard.qs or "",
    tooltip = "Name, monster, quest giver or quest flag"}
  for n = 1, qper do
    local k = qkeys[(guard.qpage - 1) * qper + n]
    if not k then break end
    local tid = qmap[k]
    local rid = uid("qr|", tid)
    guard.QRES[rid] = tid
    log[#log + 1] = {id = rid, type = "text", size = TXT.body, text = info[tid].name .. " - " .. WORD[info[tid].status],
      bold = guard.qsel == tid, clickable = true, tooltip = "Edit"}
  end
  if qpages > 1 then
    log[#log + 1] = {id = "qp", type = "row", children = {
      {id = "qp_prev", type = "button", size = TXT.body, text = "<", auto_width = true, enabled = guard.qpage > 1},
      {id = "qp_n", type = "text", size = TXT.body, text = guard.qpage .. " / " .. qpages},
      {id = "qp_next", type = "button", size = TXT.body, text = ">", auto_width = true, enabled = guard.qpage < qpages}}}
  end
  if guard.qsel and info[guard.qsel] then
    local qd = db.tasks[guard.qsel]
    local qb = {{id = "qe_save", type = "button", size = TXT.body, text = "Save"}, {id = "qe_cancel", type = "button", size = TXT.body, text = "Cancel"},
      {id = "qe_reset", type = "button", size = TXT.body, text = "Reset", tooltip = "Clear this task's kill count and timer for this character"}}
    if qd and qd.custom then qb[#qb + 1] = {id = "qe_del", type = "button", size = TXT.body, text = "Delete"}
    elseif qd then qb[#qb + 1] = {id = "qe_del", type = "button", size = TXT.body, text = "Undo", tooltip = "Back to the original task details"} end
    local body = {{id = "qe_head", type = "text", size = TXT.body, text = "Edit " .. info[guard.qsel].name, bold = true}}
    for _, c in ipairs(guard.editor_with_search("qe", guard.qdraft, picker, flags, guard.qsel)) do body[#body + 1] = c end
    body[#body + 1] = {id = "qe_btns", type = "row", children = qb}
    log[#log + 1] = {id = "qe_box", type = "column", children = body}
  elseif guard.qsel then guard.qsel = nil end
  local colsel = function(key, text) return {id = "opt|" .. key, type = "select", size = TXT.body, text = text, value = opt(key), options = COLORS} end
  local options = {
    {id = "opt|npc_marks", type = "checkbox", size = TXT.body, text = "NPC indication !", value = opt("npc_marks"), tooltip = "! over quest givers, colored by task state"},
    {id = "opt|auto_myq", type = "checkbox", size = TXT.body, text = "Automatic /myquests update", value = opt("auto_myq") ~= false,
      tooltip = "Reads your quest list after login and on the interval"},
    {id = "opt|myq_s", type = "number", size = TXT.body, text = "/myquests update interval", min = 1, max = 300, step = 1, value = tonumber(opt("myq_s")) or 65,
      tooltip = "Seconds (1-300). The server answers one /myquests per minute.", enabled = opt("auto_myq") ~= false},
    {id = "opt|myq_hide", type = "checkbox", size = TXT.body, text = "Hide /myquests in chat", value = opt("myq_hide") ~= false,
      tooltip = "Hides the tracker's own /myquests replies from the chat windows. A /myquests you type always shows."},
    {id = "opt|range", type = "slider", size = TXT.body, text = "Scan range (m)", min = 20, max = 240, step = 10, value = tonumber(opt("range")) or 150},
    {id = "opt|cooldown_hours", type = "number", size = TXT.body, text = "Default cooldown after turn-in (hours)", min = 0, max = 168, step = 1, value = tonumber(opt("cooldown_hours")) or 20},
    colsel("col_available", "! color: available"), colsel("col_progress", "! color: in progress"),
    colsel("col_turnin", "! color: ready to turn in"), colsel("col_cooldown", "! color: on cooldown")}
  ui[#ui + 1] = {id = "manage", type = "section", size = TXT.body, text = "Manage", expanded = false, hide_when_pinned = true, children = {
    {id = "mtabs", type = "tabs", children = {
      {id = "m_found", type = "column", text = "Detected" .. ((#dkeys > 0) and (" (" .. #dkeys .. ")") or ""), children = detected},
      {id = "m_tasks", type = "column", text = "Add", children = editor},
      {id = "m_log", type = "column", text = "Quest log", children = log},
      {id = "m_opt", type = "column", text = "Options", children = options}}}}}

  -- One line per control: long text is clipped instead of wrapping (which made
  -- the window very long); hovering shows the full text.
  local function one_line(list)
    for _, c in ipairs(list) do
      if c.type == "row" or c.type == "column" or c.type == "tabs" or c.type == "overlay" or c.type == "frame" then
        if c.children then one_line(c.children) end
      else
        c.wrap = false
        if (c.type == "text" or c.type == "section") and not c.tooltip and c.text and c.text ~= "" then c.tooltip = c.text end
        if c.children then one_line(c.children) end
      end
    end
  end
  one_line(ui)
  return ui
end

---------------------------------------------------------------------------
-- Saved state (the client caps it at 64 KiB and 4,096 values)
---------------------------------------------------------------------------
local function measure(v, acc)
  acc.n = acc.n + 1
  if acc.n > 4000 or acc.b > 62000 then return end
  local tv = type(v)
  if tv == "string" then acc.b = acc.b + #v
  elseif tv == "table" then
    for k, x in pairs(v) do
      if type(k) == "string" then acc.b = acc.b + #k end
      measure(x, acc)
      if acc.n > 4000 then return end
    end
  end
end
local function size_of(v) local acc = {n = 0, b = 0}; measure(v, acc); return acc end
local function compose_state()
  -- Sizes: flat maps are counted directly; only small or rare parts are walked.
  local q, qa = {}, {n = 1, b = 0}
  for k, v in pairs(st.q) do q[k] = {s = v.s, t = v.t, m = v.m, d = v.d}; qa.n = qa.n + 5; qa.b = qa.b + #k + 6 end
  local function flat(t) local a = {n = 1, b = 0}; for k in pairs(t) do a.n = a.n + 1; a.b = a.b + #k end; return a end
  local parts = {prog = st.prog, cd = st.cd, npc_cd = st.npc_cd, opt = st.opt, q = q, done_at = st.done_at}
  local sz = {prog = size_of(st.prog), cd = flat(st.cd), npc_cd = flat(st.npc_cd), opt = size_of(st.opt), q = qa, done_at = flat(st.done_at)}
  -- The task database lives in its own file; keep a copy here only if that file can't be saved.
  if dbf.err then parts.db = db; sz.db = size_of(db) end
  local n, b = 2, 1
  for k, a in pairs(sz) do n = n + a.n + 1; b = b + a.b + #k end
  for _, k in ipairs({"db", "npc_cd", "q"}) do
    if n <= 3600 and b <= 56000 then break end
    if parts[k] then
      n = n - sz[k].n; b = b - sz[k].b
      if k == "db" then parts.db = nil else parts[k] = {} end   -- the quest file is the basis for q
    end
  end
  parts.v = 4
  return parts
end

---------------------------------------------------------------------------
-- Callback
---------------------------------------------------------------------------
local state_at = -1e9
return function(s, p)
  local now = tonumber(s.time) or 0
  tick_now = now
  unix_now = tonumber(s.unix_time)
  ids_cache = nil
  local out = {}
  if not st then
    local saved = type(s.state) == "table" and s.state or {}
    st = {prog = saved.prog or {}, cd = saved.cd or {}, npc_cd = saved.npc_cd or {}, q = {}, opt = saved.opt or {},
      done_at = type(saved.done_at) == "table" and saved.done_at or {}}
    for k, v in pairs(saved.q or {}) do
      if type(v) == "table" then st.q[k] = {s = tonumber(v.s) or 0, t = tonumber(v.t) or 0, m = tonumber(v.m), d = tonumber(v.d), desc = v.desc} end
    end
    if st.opt.view == "Custom" then st.opt.view = "Other" elseif st.opt.view == "All" or st.opt.view == "Active" then st.opt.view = nil end
    st.opt.mini_area, st.opt.info_mode, st.opt.reread_reward = nil, nil, nil
    -- 4.7: interval choices are "Off" or 2-minute steps; older values fall back to the default (4 min).
    -- 4.14: the interval is in seconds (default 65) with its own on/off switch;
    -- the quest list is always read after login.
    if st.opt.refresh_min == "Off" then st.opt.auto_myq = false end
    -- 4.15: "Show in NAV" replaces the NAV-arrow and monster-arrow options; no Start/Stop.
    if st.opt.show_nav == nil and st.opt.nav == false and st.opt.arrows == false then st.opt.show_nav = false end
    st.opt.nav, st.opt.arrows, st.opt.paused = nil, nil, nil
    st.opt.chat_log = nil   -- 4.17: chat log removed
    st.opt.refresh_min, st.opt.login_refresh, st.opt.v47 = nil, nil, nil
    db = type(saved.db) == "table" and saved.db or {tasks = {}}
    refresh_areas()
    db.tasks = db.tasks or {}
    -- 3.x kept the task database as the plugin's profile; take it over once.
    if type(p.kt_db) == "table" then merge_db(p.kt_db); db_dirty = true; out.profile_patch = {kt_db = {}, kt_db_file = false} end
    for _, d in pairs(db.tasks) do if d.area == "Custom" then d.area = "Other" end end
    started_at = now
    rebuild_indexes()
  end
  if need_rebuild then rebuild_indexes(); need_rebuild = false; guard.reindexed = true end
  -- Once this server's task database is loaded (its givers are indexed), drop
  -- saved giver cooldowns that don't belong to a kill-task giver.
  if not guard.purged and dbf.phase == "ready" then guard.fix_fort_db(); guard.purge_cd(); guard.purged = true end

  -- Nearby scan (objects arrive nearest first)
  local range = tonumber(opt("range")) or 150
  local scan = {monsters = {}, npcs = {}}
  my_x, my_y = global_xy(s.position)
  local others = {}
  guard.players = {}
  for _, o in ipairs(s.objects or {}) do if o.player and type(o.name) == "string" then guard.players[string.lower(o.name)] = true end end
  -- 4.17.10: the client labels each object (build 137 object_type); items,
  -- doors, portals, containers, lifestones, corpses and players are skipped
  -- before any name work. Without the label (older builds) every object is
  -- looked at, as before.
  for _, o in ipairs(s.objects or {}) do
    local ot = o.object_type
    if (ot == nil or ot == "creature" or ot == "vendor") and type(o.name) == "string" and not o.player and not guard.is_pet(o.name) then
      local d = o.distance or 1e9
      if o.monster then
        if not o.dead and d <= range then scan.monsters[#scan.monsters + 1] = o end
      elseif not o.corpse and d <= range then
        others[#others + 1] = o
      end
    end
  end

  if type(s.character_name) == "string" and #s.character_name > 0 then my_name = s.character_name
  elseif type(s.char_strings) == "table" and type(s.char_strings["1"]) == "string" and #s.char_strings["1"] > 0 then my_name = s.char_strings["1"] end
  if tonumber(s.player) and tonumber(s.player) > 0 then my_player = math.floor(tonumber(s.player)) end
  if type(s.server) == "string" and #s.server > 0 then my_server = s.server end
  handle_results(s)
  handle_events(s, now)
  read_chat(s)
  if guard.pending and tick_now - guard.pending.at > 3 then guard.pending = nil end
  if pickup and tick_now - pickup.at >= 2 then resolve_pickup() end
  if next(recent_tells) then
    local old = {}
    for id, r in pairs(recent_tells) do if tick_now - r.at > 5 then old[#old + 1] = id end end
    for _, id in ipairs(old) do recent_tells[id] = nil end
  end
  -- (Indexes are updated incrementally by chat handlers; a full rebuild runs next callback.)
  if learn_pending and not mq.active then learn_done_flags()
  else finish_myquests() end
  -- Quest givers in range, from the client's nearby-object list (after chat, so a
  -- giver learned this tick shows at once).
  for _, o in ipairs(others) do
    local ids = npc_ids(o.name, o.wcid)
    if #ids > 0 then scan.npcs[#scan.npcs + 1] = o end   -- only kill-task givers get a "!"
    -- Remember a giver's weenie class the first time it is seen by name, so its
    -- "!" still shows if the name is written differently somewhere else.
    local w = math.floor(tonumber(o.wcid) or 0)
    if w > 1 and #ids > 0 and #ids <= 3 and not shared(o.name) then
      for _, id in ipairs(ids) do
        local t = task(id)
        if t and t.npc and norm(t.npc) == norm(o.name) and (not t.wcid or t.wcid <= 1) then
          db_task(id).wcid = w; mark_db()
          local l = NPC_BY_WCID[w] or {}; l[#l + 1] = id; NPC_BY_WCID[w] = l
        end
      end
    end
  end
  file_services(s, now)

  -- Automatic quest-list reads: after login, then on the chosen interval.
  if not mq.login_done and now - started_at > 8 then
    mq.login_done = true
    if opt("auto_myq") ~= false then request_myquests("login", now) end
  end
  local every = refresh_seconds()
  if mq.wait_at and now >= mq.wait_at and not mq.active then request_myquests(mq.wait_via or "timer", now)
  elseif every and not mq.active and mq.req_at and now - mq.req_at >= math.max(every, MYQ_MIN_GAP) then request_myquests("timer", now)
  elseif every and not mq.req_at and now - started_at > 8 then request_myquests("timer", now) end

  auto_link_descriptions(scan.monsters)
  -- 4.17.9: the window is rebuilt only when something it shows may have
  -- changed: saved data or the task database changed, a click or file result
  -- arrived, the quest-list read state, a note, an error, an edit, the minute
  -- (cooldown times), and at least every 5 seconds as a safety net.
  -- Markers are worked out every callback and sent only when they change.
  local sig = table.concat({tostring(opt("view")), tostring(mq.active), last_note, tostring(s.error), tostring(edit_id),
    tostring(qfile.name), tostring(qfile.saved), tostring(qfile.err), tostring(qfile.phase), tostring(dbf.err), tostring(dbf.phase),
    tostring(mq.done_unix), tostring(mq.done_ok), tostring(mq.req_at), tostring(picker_names and #picker_names),
    tostring(unix_now and math.floor(unix_now / 60))}, "|")
  if dirty or guard.reindexed or next(s.events or {}) or sig ~= guard.ui_sig or not guard.ui_at or now - guard.ui_at >= 5 then
    out.ui = build(s)
    if not guard.ui_at then out.status = "" end
    guard.ui_sig, guard.ui_at, guard.reindexed = sig, now, false
  end
  local markers, nav_target = guard.marks(scan)
  local mkey = guard.marker_key(markers)
  if mkey ~= guard.mkey then out.markers = markers; guard.mkey = mkey end

  if dirty and now - state_at >= 2 and workavailable() then
    out.state = compose_state()
    dirty, state_at = false, now
  end
  -- Long bursts (a big quest list): keep reading with whatever budget is left;
  -- the window and saved state catch up next callback.
  if queued() > 0 then drain(2000, true) end

  if pending_select then
    out.action, out.target = "select", pending_select
    pending_select = nil
  elseif opt("show_nav") and nav_target then
    -- NAV arrow follows the closest task monster. Each re-aim makes the client
    -- show "Waypoint: ..." above the window and save the Waypoint profile, so
    -- re-aim only on a new target or after it moved NAV_MOVE_M.
    local moved = nav.pos and dist(nav.pos, nav_target.position) or 1e9
    if (nav_target.id ~= nav.id and now - nav.at >= 2) or (moved > NAV_MOVE_M and now - nav.at >= NAV_MIN_S) then
      out.action, out.target = "waypoint", nav_target.id
      nav.id, nav.at, nav.pos = nav_target.id, now, nav_target.position
    end
  end

  flush_requests(now, out)
  -- "Hide /myquests in chat" switched off: drop a hiding rule still running.
  if guard.clear_filters then guard.clear_filters = nil; if not out.chat_filters then out.chat_filters = {} end end
  return out
end
