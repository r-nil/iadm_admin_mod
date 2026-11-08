# Documentation for using IADM


Welcome to IADM! An independent, versatile, yet powerful admin mod.
This documentation helps you understand how to use this admin mod.
Please keep in mind that IADM is in early development stage and may still have issues. It is currently not recommended to use for public servers yet.



## 1. Commands
The commands are one of the key elements to this admin mod. These allow users, especially admins to execute specific action on the server. 

### CORE
- iadm help [command] - Shows instructions for the specified command.
- iadm menu - Opens the in-game IADM menu, where available commands can be browsed and run. The `iadm_menu` console command can be used for key binds (e.g. `bind p iadm_menu`).
- iadm status - Displays server information (Uptime, players, current map and gamemode)
- iadm version - Displays message with admin mod version.

### Dev
- [!] iadm lua [string] - Executes a lua code on the server.
- iadm entinfo [ent] - Gets information about the targetted entity (classname, hp/maxhp, weapon + ammo)

### Fun
- iadm kill [players] - Kills targets. (Alias: slay)
- iadm explode [players] [explosionlevel default=1] - Explodes players. Higher values result in much more violent explosion.
- iadm skill [players] - Silently kills targets. (Alias: sslay)
- iadm strip [players] - Removes weapons for the target(s).
- iadm hp [players] [hp] - Sets target(s) health to the specified amount.
- iadm ignite [entities] [duration default=300] - Ignites targets.
- iadm unignite [entities] - Extinguishes targets.
- iadm infammo [players] [mode] - Gives the player infinite ammo.\nModes: 0 - disable, 1 - infinite reserve ammo, 2 - infinite reserve + clip ammo

### Groups
- iadm groupadd [name] [powerlevel] [isadmin] [issuperadmin] - Adds a new usergroup.
- [!] iadm groupdel [name] - Deletes an existing usergroup.
- iadm groupmodify [name] [key] [value] - Changes usergroup's attribute.
- iadm setgroup [player] [groupname] - Assigns a player to a new group.
- iadm groupslist - Displays a list of usergroups.

### Logs
- iadm viewlogs [logtype, default="all"] [page, default=1] - Views recent logs in the current session
- iadm viewfulllogs [logtype, default="all"] [page, default=1] - Views all the logs, even from different sessions.
- [!] iadm deletelogs [confirm] - Irreversibly deletes ALL logs. Cannot be used by anyone except the user in godmode and the server console.
- iadm monitorlogs [logtype] [toggle {on/off}] - Monitors logs. This command does not work for server host or server console.

### Teleport
- iadm teleport [player] - Teleports a player to the position under your crosshair. (Aliases: tele, tp)
- iadm goto [player] - Teleports you to a specified player.
- iadm bring [players] - Brings players to you.

### Util
- iadm kick [player] [reason] - Kicks a player.
- iadm ban [player] [time, 0=permanent] [reason] - Bans a player for specified amount of time.
- iadm unban [steamid64] [reason] - Unbans player's Steam ID64.
- iadm csay [text] - Displays a text on the center screen to everyone.
- iadm tsay [text] - Displays a chat message to everyone.
- iadm noclip [player] - Toggles noclip for the target.
- iadm cleanup - Cleans up the map.
- iadm map [map] - Switches the map to another one.
- iadm restart - Restarts the map.
- iadm steamid [player] - Prints out a player's steamid.
- iadm cleardecals - Cleans up all clientside ragdolls and decals for everyone.

## 2. Config
Configuring the can be quite complex. Currently, it's quite limited too. In future there may be more configuration options.<br><br>

The command goes like this:<br>
> iadm_config [config category] [config option] [value]


## 3. UserGroups

UserGroups are a vital part of the admin mod. It helps especially who is a part of the staff team, etc. Thanks to the usergroup powerlevel system, it is more simple to use in general.

Note: While you can use commands on targetted player with equal to or lower than your power level, you can't target players with certain commands (especially kick, ban, mute, etc.) with their power level equal to or higher than yours.
