local cmd = IADM:AddCommand("kick", function(caller, target, reason)
    if target:IsListenServerHost() then
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_ERROR, "This target is invulnerable!")
        return
    end
    reason = reason or "No reason provided"
	
	local nick = IsValid(caller) and caller:Nick() or "Console"
    target:Kick(Format("Kicked %s.\nReason: \n%s", IsValid(caller) and Format("by %s (%s)", nick, caller:SteamID64()) or "from the Server", reason))
	IADM:LogCommandUse(caller, "#A kicked #T (#S)", false, target, reason)
    IADM:MessageWPrefix(caller, true, Color(255,0,0), target:Nick(), IADM_ECHOCOLOR_TEXT, " was ", Color(255,0,0), "kicked", IADM_ECHOCOLOR_TEXT, "! (", Color(255,128,0), reason, IADM_ECHOCOLOR_TEXT, ")")
end)
cmd.Name = "Kick"
cmd.Desc = "Kicks the player with a reason."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_PLR})
cmd:AddArgument({type=IADM_ARGTYPE_STR, hint="reason", optional=true, varargs=true})
cmd.RequireHigherPowerLevel = true

local cmd = IADM:AddCommand("ban", function(caller, target, duration, reason)
    local success, err
    if IADM.AddBan then
        success, err = IADM:AddBan(target, reason, duration, caller) -- steamid64 else it won't work
    else
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_ERROR, "Bans module is disabled! Use ", IADM_ECHOCOLOR_ERROR_ARGVAR, "kick", IADM_ECHOCOLOR_ERROR, " command instead or enable bans module instead!")
        return
    end

    if success then
        IADM:MessageWPrefix(caller, true, Color(255,0,0), target:Nick(), IADM_ECHOCOLOR_TEXT, " was ", Color(255,0,0), "banned", IADM_ECHOCOLOR_TEXT, "! (", Color(255,128,0), reason, IADM_ECHOCOLOR_TEXT, ")")
    else
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_ERROR, "Error: ", IADM_ECHOCOLOR_ERROR_REASON, err)
    end
end)
cmd.Name = "Ban"
cmd.Desc = "Bans the target for a specified amount of time."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_PLR})
cmd:AddArgument({type=IADM_ARGTYPE_TIME, default=0, hint="duration (0 = permanent)"})
cmd:AddArgument({type=IADM_ARGTYPE_STR, default="No reason provided", varargs=true})
cmd.RequireHigherPowerLevel = true

local cmd = IADM:AddCommand("unban", function(caller, id64, reason)
    local success, err
    if IADM.RemoveBan then
        success, err = IADM:RemoveBan(id64, reason, caller) -- steamid64 else it won't work
    else
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_ERROR, "Bans module is disabled, command is not usable!")
        return
    end

    if success then
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_ARG1, id64, IADM_ECHOCOLOR_TEXT, " was ", IADM_ECHOCOLOR_ARG1, "unbanned", IADM_ECHOCOLOR_TEXT, "! (", IADM_ECHOCOLOR_ARG2, reason, IADM_ECHOCOLOR_TEXT, ")")
    else
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_ERROR, "Error: ", IADM_ECHOCOLOR_ERROR_REASON, err, "!")
    end
end)
cmd.Name = "Unban"
cmd.Desc = "unbans an already banned target."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_STR, hint="steamid64"})
cmd:AddArgument({type=IADM_ARGTYPE_STR, default="No reason provided", varargs=true})
cmd.RequireHigherPowerLevel = true
--[[
local cmd = IADM:AddCommand("mute", function(caller, target, duration, reason)
end)
cmd.Name = "Mute"
cmd.Desc = "Prevents the target from communating in text and voice chat."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_PLR})
cmd:AddArgument({type=IADM_ARGTYPE_TIME, default=0, hint="duration (0 = permanent)"})
cmd:AddArgument({type=IADM_ARGTYPE_STR, default="No reason provided", varargs=true})
cmd.RequireHigherPowerLevel = true

local cmd = IADM:AddCommand("chatmute", function(caller, target, duration, reason)
end)
cmd.Name = "Chat Mute"
cmd.Desc = "Prevents the target from typing in chat."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_PLR})
cmd:AddArgument({type=IADM_ARGTYPE_TIME, default=0, hint="duration (0 = permanent)"})
cmd:AddArgument({type=IADM_ARGTYPE_STR, default="No reason provided", varargs=true})
cmd.RequireHigherPowerLevel = true

local cmd = IADM:AddCommand("vcmute", function(caller, target, duration, reason)
end)
cmd.Name = "Voice Mute"
cmd.Desc = "Prevents the target from talking in voice chat."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd.Aliases = {"gag"}
cmd:AddArgument({type=IADM_ARGTYPE_PLR})
cmd:AddArgument({type=IADM_ARGTYPE_TIME, default=0, hint="duration (0 = permanent)"})
cmd:AddArgument({type=IADM_ARGTYPE_STR, default="No reason provided", varargs=true})
cmd.RequireHigherPowerLevel = true
]]

local cmd = IADM:AddCommand("csay", function(caller, text)
    -- local tbl = string.Explode("%#", text)

    net.Start("iadm_csay")
    IADM_NET_WRITETABLE({text})
    net.Broadcast()
end)
cmd.Name = "Csay"
cmd.Desc = "Send a message to everyone displayed on the center screen."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_STR, hint="text", varargs=true})

local cmd = IADM:AddCommand("tsay", function(caller, text)
    -- local tbl = string.Explode("%#", text)

    IADM:Message(player.GetAll(), true, text)
end)
cmd.Name = "Tsay"
cmd.Desc = "Send a message to everyone in chat."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_STR, hint="text", varargs=true})

local cmd = IADM:AddCommand("noclip", function(caller, target)
    local on = caller:GetMoveType() ~= MOVETYPE_NOCLIP

    target:SetMoveType(on and MOVETYPE_NOCLIP or MOVETYPE_WALK)

    IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_TEXT, "Turned "..(on and "on" or "off").." noclip for ", Color(255,0,0), target:Nick(), IADM_ECHOCOLOR_TEXT, "!")
end)
cmd.Name = "Noclip"
cmd.Desc = "Toggle noclip for players."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_PLR, default="^"})

local cmd = IADM:AddCommand("cleanup", function(caller)
	local nick = IsValid(caller) and caller:Nick() or "Console"
    game.CleanUpMap(false, nil, function()
        IADM:MessageWPrefix(player.GetAll(), true, Color(255,255,0), nick, IADM_ECHOCOLOR_TEXT, " cleaned up the map!")
    end)
end)
cmd.Name = "Cleanup"
cmd.Desc = "Cleans up the map. This will not restart the round in some gamemodes."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN

local RunConsoleCommand = RunConsoleCommand
local cmd = IADM:AddCommand("map", function(caller, map)
    if !file.Exists(string.format("maps/%s.bsp", map), "GAME") then
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_ERROR, "Error: ", IADM_ECHOCOLOR_ERROR_REASON, "Invalid map", IADM_ECHOCOLOR_ERROR, "!")
        return
    end
	local nick = IsValid(caller) and caller:Nick() or "Console"
    IADM:MessageWPrefix(player.GetAll(), true, Color(255,255,0), nick, IADM_ECHOCOLOR_TEXT, " changed the map to ", Color(255,0,0), map, "!")

    RunConsoleCommand("changelevel", map)
end)
cmd.Name = "Map"
cmd.Desc = "Forces the server to change to a specified map."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_STR, hint="mapname"})

local cmd = IADM:AddCommand("restart", function(caller)
	local nick = IsValid(caller) and caller:Nick() or "Console"
    IADM:MessageWPrefix(player.GetAll(), true, Color(255,255,0), nick, IADM_ECHOCOLOR_TEXT, " restarted the map!")

    RunConsoleCommand("changelevel", game.GetMap())
end)
cmd.Name = "Restart"
cmd.Desc = "Restarts the current map."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN

local cmd = IADM:AddCommand("steamid", function(caller, target)
    IADM:Message(caller, true, IADM_ECHOCOLOR_ARG1, caller == target and "Your" or target:Nick().."'s", IADM_ECHOCOLOR_TEXT, " steamid is: ", IADM_ECHOCOLOR_ARG2, target:SteamID())
    IADM:Message(caller, true, IADM_ECHOCOLOR_ARG1, caller == target and "Your" or target:Nick().."'s", IADM_ECHOCOLOR_TEXT, " steamid64 is: ", IADM_ECHOCOLOR_ARG2, target:GetIADMSteamID64())
end)
cmd.Name = "SteamID"
cmd.Desc = "Get your, or another target's steam ID"
cmd:AddArgument({type=IADM_ARGTYPE_PLR, default="^"})
cmd.IgnoreCanTarget = true

local cmd = IADM:AddCommand("cleardecals", function(caller)
    BroadcastLua([[game.RemoveRagdolls() RunConsoleCommand("r_cleardecals")]])

    IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_TEXT, "Cleaned up all clientside decals and ragdolls!")
end)
cmd.Name = "Clear decals"
cmd.Desc = "Cleans up all clientside decals and ragdolls for everyone"
cmd.Aliases = {"cleanupdecals", "decals"}
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
