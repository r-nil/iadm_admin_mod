util.AddNetworkString("iadm_command")
util.AddNetworkString("iadm_printmsg")
util.AddNetworkString("iadm_csay")
util.AddNetworkString("iadm_playerusecmd")
util.AddNetworkString("iadm_playereditconfig")
util.AddNetworkString("iadm_groups")
util.AddNetworkString("iadm_playerinit")
util.AddNetworkString("iadm_syncdata")

net.Receive("iadm_command", function(len, pl)
    if !pl:IsValid() then return end
    local cmd = net.ReadString()
    local args = IADM_NET_READTABLE()
	
	local ctbl = IADM.Commands[cmd]
	if !ctbl then return end

    if !IADM:CanUseCommand(pl, cmd) then
        IADM:Message(pl, true, IADM_ECHOCOLOR_ERROR, "Insufficient permissions to use ", IADM_ECHOCOLOR_ERROR_ARGVAR, cmd, IADM_ECHOCOLOR_ERROR, " command!")
        pl:SendLua([[surface.PlaySound("buttons/button11.wav")]])
        return
    end

    args = IADM:ProcessCmdArgs(pl, inchat, ctbl, args)
    if not args then return end

    if ctbl.ChatArg then
	    ctbl.Func(pl, false, unpack(args))
    else
    	ctbl.Func(pl, unpack(args))
    end
end)

net.Receive("iadm_playereditconfig", function(len, pl)
    if !pl:IsValid() then return end
    local cfg = net.ReadString()
    local option = net.ReadString()
    local args = IADM_NET_READTABLE()

    local ctbl = IADM:GetConfigCategoryTable(cfg)
    if !ctbl then return end

    if !ctbl:CanViewConfig(pl) then
        IADM:Message(pl, true, IADM_ECHOCOLOR_ERROR, "Insufficient permissions to view this configuration!")
        pl:SendLua([[surface.PlaySound("buttons/button11.wav")]])
        return
    end

    local modtbl = ctbl:GetConfigTable(option)
    if !modtbl then
        IADM:Message(pl, true, IADM_ECHOCOLOR_ERROR, "Invalid option ", IADM_ECHOCOLOR_ERROR_ARGVAR, option, IADM_ECHOCOLOR_ERROR, "!")
        return
    end

    str = ""
    for i=1,#args do
        str = str..(str=="" and "" or " ")..args[i]
    end

    if str == "" then
        IADM:Message(pl, false, IADM_ECHOCOLOR_TEXT, "Configuration ", IADM_ECHOCOLOR_ARG1, option, IADM_ECHOCOLOR_TEXT, " in config category ", IADM_ECHOCOLOR_ARG2, cfg, IADM_ECHOCOLOR_TEXT, " is set to: ", IADM_ECHOCOLOR_ARG3, modtbl:GetConfigValue())
        return
    end

    if !ctbl:CanEditConfig(pl) then
        IADM:Message(pl, true, IADM_ECHOCOLOR_ERROR, "Insufficient permissions to edit this configuration!")
        pl:SendLua([[surface.PlaySound("buttons/button11.wav")]])
        return
    end

    str = IADM:ProcessCfgArgs(pl, modtbl, str)
    if str == nil then return end

    modtbl.SetValue = str
    IADM:Message(pl, true, IADM_ECHOCOLOR_TEXT, "Config set to ", IADM_ECHOCOLOR_ARG1, tostring(str), IADM_ECHOCOLOR_TEXT, "!")

    local saved = sql.QueryTyped("SELECT * FROM iadm_config WHERE id=?", option)[1]
    if saved then
        sql.QueryTyped("UPDATE iadm_config SET savedvalue=?, lastmodifiedby=?, timemodified=? WHERE id=?",
            tostring(str),
            IADM:GetSteamID64(pl),
            os.time(),
            option
        )
    else
        sql.QueryTyped("INSERT INTO iadm_config(id, savedvalue, powerlevel, viewpowerlevel, lastmodifiedby, timemodified) VALUES(?, ?, ?, ?, ?)",
            option,
            tostring(str),
            modtbl.Powerlevel,
            modtbl.ViewPowerlevel,
            IADM:GetSteamID64(pl),
            os.time()
        )
    end
end)


if not IADM.ServerStartTime then
    IADM.ServerStartTime = SysTime()
end

IADM:AddHook("Initialize", "TrackServerStartTime", function()
    IADM.ServerInitTime = SysTime()
end, HOOK_MONITOR_HIGH)

local loadingsteamid64 = {}
gameevent.Listen("player_connect")
IADM:AddHook("player_connect", "OnPlayerConnectSteamID64", function(data)
    if tobool(data.bot) then return end -- why this shit don't use true/false bool
    loadingsteamid64[util.SteamIDTo64(data.networkid)] = SysTime()
end)

gameevent.Listen("player_disconnect")
IADM:AddHook("player_disconnect", "OnPlayerDisconnectSteamID64", function(data)
    if tobool(data.bot) then return end
    loadingsteamid64[util.SteamIDTo64(data.networkid)] = nil
end)

-- Player Initialization
net.Receive("iadm_playerinit", function(len, pl)
    local phasetoload = net.ReadUInt(8)

    if pl.IADM_InitPhase == 1 then
        hook.Run("IADMPlrInit", pl, math.Round(SysTime() - (loadingsteamid64[pl:SteamID64()] or IADM.ServerInitTime), 2), math.Round(SysTime() - IADM.ServerStartTime, 2))

        loadingsteamid64[pl:SteamID64()] = nil
    end
    if pl.IADM_InitPhase and pl.IADM_InitPhase == phasetoload then
		if IADM.InitSyncData[phasetoload] and isfunction(IADM.InitSyncData[phasetoload].Func) then
			IADM.InitSyncData[phasetoload].Func(IADM, pl)
		end

        net.Start("iadm_playerinit")
        net.WriteUInt(phasetoload, 8)
        net.Send(pl)

        pl.IADM_InitPhase = phasetoload + 1
    end
end)

-- Data Syncing for players
net.Receive("iadm_syncdata", function(len, pl)
    local datatosync = net.ReadString()

    if datatosync and IADM.RegisteredSyncData[datatosync] then
        IADM.RegisteredSyncData[datatosync](ply, len)
    end
end)
