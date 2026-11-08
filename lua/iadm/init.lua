if not IADM then
    IADM = {}
    IADM.Commands = {}
    IADM.Config = {}
    IADM.Modules = {}
    IADM.Hooks = {}
    IADM.SQLDatabases = {}
    IADM.SQLDatabasesLoad = {}

    IADM.DatabaseDir = "iadm"

    IADM.RegisteredSyncData = {}
    IADM.InitSyncData = {}
end

IADM.Prefix = {"!", "/"}
IADM.Version = "0.4.1"
IADM.UpdateVer = 29
IADM.Author = "Uklejamini"

local IADM = IADM
local string_lower = string.lower

local m = {}
local meta = {}
meta.__index = m

function m:AddArgument(t)
    table.insert(self.Args, t)
end
meta.AddArgument = m.AddArgument


function IADM:AddCommand(cmd, func, t)
    -- if IADM.Commands[cmd] then
        -- MsgN("Command "..cmd.." already exists, overriding.")
    -- end

    cmd = string_lower(cmd)

    tbl = setmetatable({}, meta)
    IADM.Commands[cmd] = tbl
    IADM.Commands[cmd].Func = func
    IADM.Commands[cmd].Args = {}
    table.Merge(IADM.Commands[cmd], t or {})

    return IADM.Commands[cmd]
end

local m = {}
local meta = {}
meta.__index = m

local m2 = {}
local meta2 = {}
meta2.__index = m2


function m2:GetConfigValue()
    if self.SetValue ~= nil then
        return self.SetValue
    end

    return self.Default
end
meta2.GetConfigValue = m2.GetConfigValue

local numid = 1
function m:AddConfigOption(id, name, desc, default, configtype)
    id = string_lower(id)

    tbl = setmetatable({}, meta2)
    self.Options[id] = tbl
    tbl.ID = numid
    numid = numid + 1
    tbl.Name = name
    tbl.Desc = desc
    tbl.Default = default
    tbl.SetValue = default
    tbl.ConfigType = configtype
    

    return tbl
end
meta.AddConfigOption = m.AddConfigOption

function m:GetConfigValue(name)
    local tbl = self.Options[name]
    if tbl.SetValue ~= nil then
        return tbl.SetValue
    end

    return tbl.Default
end
meta.GetConfigValue = m.GetConfigValue

function m:GetConfigTable(name)
    return self.Options[name]
end
meta.GetConfigTable = m.GetConfigTable

function m:CanViewConfig(pl)
    return self.Powerlevel >= pl:GetGroupPowerLevel()
end
meta.CanViewConfig = m.CanViewConfig

function m:CanEditConfig(pl)
    return self.Powerlevel >= pl:GetGroupPowerLevel()
end
meta.CanEditConfig = m.CanEditConfig

function IADM:AddConfigCategory(id, name, powerlevel)
    id = string_lower(id)

    tbl = setmetatable({}, meta)
    IADM.Config[id] = tbl
    tbl.Name = name
    tbl.ViewPowerlevel = powerlevel or IADM_GROUP_POWER_SUPERADMIN -- use it so anyone with equal or higher power level can view these configs 
    tbl.Powerlevel = powerlevel or IADM_GROUP_POWER_SUPERADMIN -- same as above but for config editing purposes
    tbl.Options = {}

    return tbl
end

function IADM:GetConfigCategoryTable(id)
    return self.Config[id]
end

function IADM:GetConfigCategoryTableByName(name)
    for _,tbl in pairs(self.Config) do
        if tbl.Name == name then
            return tbl
        end
    end

    return {}
end

function IADM:GetModuleTable(id)
    return IADM.Modules[id]
end



function IADM:GetPrefix()
    local p = IADM.Prefix
    return istable(p) and p[1] or p
end

local function NormalizeTablePlrs(tbl)
	for i,str in ipairs(tbl) do
		if isnumber(str) or isbool(str) then continue end
		if IsValid(str) then
			tbl[i] = str:Nick()
		end
	end

	return tbl
end

local function NormalizeTableTbls(tbl)
	for i,str in ipairs(tbl) do
		if istable(str) and !IsColor(str) then
			tbl[i] = tostring(str)
		end
	end

	return tbl
end

function IADM:Message(ply, tochat, ...)
    if SERVER then
        if istable(ply) or IsValid(ply) then
			local tbl = NormalizeTableTbls({...})

            net.Start("iadm_printmsg")
            net.WriteBit(0)
            net.WriteBit(tochat and 1 or 0)
            IADM_NET_WRITETABLE(tbl)
            net.Send(ply)


			local _,plys = player.Iterator() -- all players table
			if game.IsDedicated() and istable(ply) and #plys == #ply then
				MsgC(unpack(NormalizeTablePlrs({...})))
				MsgN()
			end
        else
            MsgC(unpack(NormalizeTablePlrs({...})))
            MsgN()
        end
    elseif CLIENT then
        if tochat then
			local tbl = {}
			for i,str in pairs({...}) do
				tbl[i] = !IsColor(str) and tostring(str) or str
			end

            chat.AddText(unpack(tbl))
        else
            MsgC(...)
            MsgN()
        end
    end
end

function IADM:MessageWPrefix(ply, tochat, ...)
    if SERVER then
        if istable(ply) or IsValid(ply) then
			local tbl = NormalizeTableTbls({...})

            net.Start("iadm_printmsg")
            net.WriteBit(1)
            net.WriteBit(tochat and 1 or 0)
            IADM_NET_WRITETABLE(tbl)
            net.Send(ply)

			local _,plys = player.Iterator()
			if game.IsDedicated() and istable(ply) and #plys == #ply then
				MsgC(IADM_ECHOCOLOR_PREFIX, "[IADM] ", color_white, unpack(NormalizeTablePlrs({...})))
				MsgN()
			end
        else
            MsgC(IADM_ECHOCOLOR_PREFIX, "[IADM] ", color_white, unpack(NormalizeTablePlrs({...})))
            MsgN()
        end
    elseif CLIENT then
        if tochat then
			local tbl = {...}
			for i,str in pairs(tbl) do
				tbl[i] = !IsColor(str) and tostring(str) or str
			end

            chat.AddText(IADM_ECHOCOLOR_PREFIX, "[IADM] ", color_white, unpack(tbl))
        else
            MsgC(IADM_ECHOCOLOR_PREFIX, "[IADM] ", color_white, ...)
            MsgN()
        end
    end
end

function IADM:AddHook(eventname, identifier, func, order)
    if not IADM.Hooks[eventname] then IADM.Hooks[eventname] = {} end

    identifier = "IADM."..eventname.."."..identifier
    IADM.Hooks[eventname][identifier] = func
    hook.Add(eventname, identifier, func, order)

    return func
end

function IADM:AddSQLDatabase(id, func)
    IADM.SQLDatabases[id] = func
end

function IADM:AddLoadSQL(id, func)
    IADM.SQLDatabasesLoad[id] = func
end

-- Register each for client and server separately!!
function IADM:RegisterDataSync(id, func, ...)
    local tbl = {
        id = id,
        Func = func,
        args = {...}
    }

    for i,tbl in ipairs(IADM.RegisteredSyncData) do
        if table.HasValue(tbl, id) then
            IADM.RegisteredSyncData[i] = tbl
            return
        end
    end

    table.insert(IADM.RegisteredSyncData, tbl)
end

function IADM:RegisterInitDataSync(id, func, ...)
    local tbl = {
        id = id,
        Func = func,
        args = {...}
    }

    for i,tbl in ipairs(IADM.InitSyncData) do
        if table.HasValue(tbl, id) then
            IADM.InitSyncData[i] = tbl
            return
        end
    end

    table.insert(IADM.InitSyncData, tbl)
end

function IADM:PerformDataSync(id, pl, ...)
    local tbl = {...}


end

function IADM:CmdCanTarget(caller, target, ctbl, carg)
    if ctbl.IgnoreCanTarget then return true end
    if ctbl.CanAlwaysSelfTarget and caller == target then return true end
	if caller == NULL then return true end -- console

    if ctbl.OverrideCanTarget then
        return ctbl.OverrideCanTarget(caller, target)
    end
    local cantarget = ctbl.CanTarget and ctbl.CanTarget(caller, target) or carg.CanTarget and carg.CanTarget(caller, target)
    if cantarget then return cantarget end

    if caller ~= target and ctbl.RequireHigherPowerLevel or carg.RequireHigherPowerLevel then return target:GetGroupPowerLevel() < caller:GetGroupPowerLevel() end
    if caller == target then return true end
    return target:GetGroupPowerLevel() <= caller:GetGroupPowerLevel()
end

function IADM:ProcessCmdArgs(pl, inchat, ctbl, args)
    for count,v in pairs(args) do
        local carg = ctbl.Args[count]
        if !carg then break end
        if carg.varargs then
            for i=count+1,#args do
                args[count] = args[count].." "..args[i]
            end

            if args[count] == "" then
                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_REASON, "String cannot be empty!")
                return
            end

            break
        end
        local a = args[count]

        if not a then continue end

        if carg.type == IADM_ARGTYPE_PLR then
            if a == "^" then
                a = pl
            elseif a == "@" then
                a = pl:GetEyeTrace().Entity
            elseif isnumber(tonumber(a)) and Entity(a or 0) and IsValid(Entity(a or 0)) then
                a = Entity(a)
            else
                local tbl = {}
                for _,ply in pairs(player.GetAll()) do
                    if ply:Nick() == v then
                        tbl = {ply}
                        break
                    elseif string.find(string_lower(ply:Nick()), string_lower(v)) then
                        table.insert(tbl, ply)
                    end
                end

                if #tbl > 1 then
                    local s = ""
                    for i=1,#tbl do
                        local nick = tbl[i]:Nick()
                        s=s..(i == 1 and nick or ", "..nick)
                    end
                    IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ",
                    IADM_ECHOCOLOR_ERROR_REASON, Format("Too many players (%d) to select from! ", #tbl), IADM_ECHOCOLOR_ERROR_HINT, "Select from:\n",
                    IADM_ECHOCOLOR_ERROR_REASON, s)
                    return
                end

                a = tbl[1]
            end

            if isstring(a) or !IsValid(a) or !a:IsPlayer() then
                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_REASON, "Player not found!")
                return
            end

            if !IADM:CmdCanTarget(pl, a, ctbl, carg) then
                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_ARGVAR, a:Nick(), IADM_ECHOCOLOR_ERROR, " cannot be targetted!")
                return
            end

            args[count] = a
        elseif carg.type == IADM_ARGTYPE_PLRS then
            local tbl = {}
            local seen = {}
            local failed

            -- Multiple targets can be comma separated. This is mainly used by the menu,
            -- but also makes commands like "!kill player1,player2" work in chat.
            for _, token in ipairs(string.Explode(",", tostring(a))) do
                token = string.Trim(token)

                if token ~= "" then
                    local found = {}

                    if token == "^" then
                        found = {pl}
                    elseif token == "@" then
                        local ent = IsValid(pl) and pl:GetEyeTrace().Entity
                        if IsValid(ent) and ent:IsPlayer() then
                            found = {ent}
                        end
                    elseif isnumber(tonumber(token)) and IsValid(Entity(tonumber(token))) and Entity(tonumber(token)):IsPlayer() then
                        found = {Entity(tonumber(token))}
                    else
                        for _, ply in ipairs(player.GetAll()) do
                            if ply:Nick() == token then
                                found = {ply}
                                break
                            end
                        end

                        if #found == 0 then
                            for _, ply in ipairs(player.GetAll()) do
                                if string.find(string_lower(ply:Nick()), string_lower(token), 1, true) then
                                    table.insert(found, ply)
                                end
                            end
                        end
                    end

                    if #found == 0 then
                        failed = token
                        break
                    end

                    for _, ply in ipairs(found) do
                        if not seen[ply] then
                            seen[ply] = true
                            table.insert(tbl, ply)
                        end
                    end
                end
            end

            if failed then
                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_REASON, "Player not found: ", IADM_ECHOCOLOR_ERROR_ARGVAR, failed)
                return
            end

            if #tbl == 0 then
                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_REASON, "Player not found!")
                return
            end

            for _, ply in ipairs(tbl) do
                if not IADM:CmdCanTarget(pl, ply, ctbl, carg) then
                    IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_ARGVAR, ply:Nick(), IADM_ECHOCOLOR_ERROR, " cannot be targetted!")
                    return
                end
            end

            a = tbl
            args[count] = a
        elseif carg.type == IADM_ARGTYPE_ENTS then
            if a == "^" then
                a = {pl}
            elseif a == "@" then
                a = {pl:GetEyeTrace().Entity}
            elseif isnumber(tonumber(a)) and Entity(a or 0) and IsValid(Entity(a or 0)) then
                a = {Entity(a)}
            else
                local tbl = {}
                if string.sub(a, 1, 1) == "#" then
                    for _,ent in ipairs(ents.FindByName(string.sub(a, 2))) do
                        if ent:IsPlayer() then continue end
                        table.insert(tbl, ent)
                    end
                else
                    for _,ent in ipairs(ents.FindByClass(a)) do
                        if ent:IsPlayer() then continue end
                        table.insert(tbl, ent)
                    end
                end

                a = tbl
            end

            if isstring(a) or !istable(a) and !IsValid(a) then
                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_REASON, "Could not find an entity!")
                return
            end

            args[count] = a
        elseif carg.type == IADM_ARGTYPE_NUM then
            a = tonumber(a)
            if a then
                if carg.min then
                    a = math.max(carg.min, a)
                end

                if carg.max then
                    a = math.min(carg.max, a)
                end
            else
                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_REASON, "Invalid number!")
                return
            end
            args[count] = a
        elseif carg.type == IADM_ARGTYPE_TIME then
            local calculated = 0
            local s = ""
            local last_time_type = 1
            local b = {
                {"y", 86400*365},
                {"w", 86400*7},
                {"d", 86400},
                {"h", 3600},
                {"m", 60},
                {"s", 1}
            }

            local len = #a
            for i=1,len do
                if tonumber(a[i]) then
                    s = s..a[i]

                    if i == len then
                        calculated = calculated + tonumber(s)
                        break
                    end

                    continue
                else
                    for c=last_time_type,#b do
                        if b[c][1] == a[i] then
                            calculated = calculated + (b[c][2] * tonumber(s))
                            last_time_type = c+1
                            s = ""

                            break
                        end
                    end

                    continue
                end

                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_REASON, "Invalid format!")
                return
            end

            a = tonumber(calculated)
            if a then
                if carg.min then
                    a = math.max(carg.min, a)
                end

                if carg.max then
                    a = math.min(carg.max, a)
                end
            end
            args[count] = a
        elseif carg.type == IADM_ARGTYPE_BOOL then
            a = tobool(a)
            args[count] = a
        elseif carg.type == IADM_ARGTYPE_STR then
            if a == "" then
                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_REASON, "String cannot be empty!")
                return
            end
        end
    end

    return args
end

function IADM:ProcessCfgArgs(pl, ctbl, str)
    if ctbl.ConfigType == IADM_ARGTYPE_NUM then
        str = tonumber(str)

        if str then
            if ctbl.min then
                str = math.max(ctbl.min, str)
            end

            if ctbl.max then
                str = math.min(ctbl.max, str)
            end
        else
            IADM:Message(pl, false, IADM_ECHOCOLOR_ERROR, "Error: ", IADM_ECHOCOLOR_ERROR_REASON, "Invalid number!")
            return
        end
    elseif ctbl.ConfigType == IADM_ARGTYPE_BOOL then
        if str=="true" or str=="1" then
            str = true
        elseif str=="false" or str=="0" then
            str = false
        else
            IADM:Message(pl, false, IADM_ECHOCOLOR_ERROR, "Error: ", IADM_ECHOCOLOR_ERROR_REASON, "Invalid value! Use true/false or 1/0!")
            return
        end
    elseif ctbl.ConfigType == IADM_ARGTYPE_STR then
        if str == "" then
            IADM:Message(pl, false, IADM_ECHOCOLOR_ERROR, "Error: ", IADM_ECHOCOLOR_ERROR_REASON, "String cannot be empty!")
            return
        end
    end

    return str
end

function IADM:ProcessStr(str, argtype)
    if argtype == IADM_ARGTYPE_NUM then
        str = tonumber(str)
    elseif argtype == IADM_ARGTYPE_BOOL then
        if str=="true" or str=="1" then
            str = true
        elseif str=="false" or str=="0" then
            str = false
        end
    end

    return str
end

function IADM:CanUseCommand(pl, cmd)
    if pl == NULL then return true end -- console
    if pl.IADM_GodMode then return true end
    -- if (pl == NULL or pl:IsListenServerHost()) then return true end
    local ctbl = IADM.Commands[cmd]
    if not ctbl then return false end

    local ugrp = IADM.UserGroups[pl:IADMGetUserGroup()]

    if ugrp.powerlevel and (ctbl.PowerLevelReq or 0) <= ugrp.powerlevel then
        return true
    end

    if !ctbl.PowerLevelReq then
        return true
    end


    return false
end

local IADM_CMD = function(pl, cmd, args, str)
    local prefix = "[IADM] "
    if #args == 0 then
        local c = 0
        for cmd,ctbl in pairs(IADM.Commands) do
            if IADM:CanUseCommand(pl, cmd) then
                c = c + 1
            end
        end

        IADM:MessageWPrefix(pl, false, IADM_ECHOCOLOR_TEXT, IADM:GetTranslatedText(pl, "No command selected. Currently available commands: "), IADM_ECHOCOLOR_ARG1, c)
        return
    end

    local cmd = string_lower(args[1] or "")
    args[1] = nil

    local new_args = {}
    for _,text in pairs(args) do
        table.insert(new_args, text)
    end
    args = new_args

    local ctbl = IADM.Commands[cmd]
    if !ctbl then
        for k,_ in SortedPairs(IADM.Commands) do
            if string.sub(k, 1, #cmd) ~= cmd then continue end
            if !IADM:CanUseCommand(pl, k) then continue end
            IADM:MessageWPrefix(pl, false, IADM_ECHOCOLOR_TEXT, IADM:GetTranslatedText(pl, "Invalid command "), IADM_ECHOCOLOR_ARG1, cmd, IADM_ECHOCOLOR_TEXT, IADM:GetTranslatedText(pl, ". Maybe you meant: "), IADM_ECHOCOLOR_ARG1, k, IADM_ECHOCOLOR_TEXT, IADM:GetTranslatedText(pl, "?"))
            return
        end

        IADM:MessageWPrefix(pl, false, IADM_ECHOCOLOR_TEXT, IADM:GetTranslatedText(pl, "Invalid command "), IADM_ECHOCOLOR_ARG1, cmd, IADM_ECHOCOLOR_TEXT, IADM:GetTranslatedText(pl, "."))
        return
    end

    local inchat = false
    local needed = #ctbl.Args
    local defaultargsamt = 0
    for count,argument in ipairs(ctbl.Args) do
        needed = needed - ((argument.default or argument.optional or args[count]) and 1 or 0)
        defaultargsamt = defaultargsamt + ((argument.default or argument.optional) and 1 or 0)
    end

    if #ctbl.Args ~= 0 and #ctbl.Args-defaultargsamt == needed and needed ~= 0 then
        local s = ""

        local argtypes = {
            [IADM_ARGTYPE_PLR] = "player",
            [IADM_ARGTYPE_PLRS] = "players",
            [IADM_ARGTYPE_ENT] = "entity",
            [IADM_ARGTYPE_ENTS] = "entities",
            [IADM_ARGTYPE_TIME] = "time",
            [IADM_ARGTYPE_STR] = "text",
            [IADM_ARGTYPE_NUM] = "number",
        }

        for count,arg in ipairs(ctbl.Args) do
            s = s..(s=="" and "" or " ")..string.format(arg.optional and "[%s]" or "<%s>", IADM:GetTranslatedText(pl, arg.hint or argtypes[arg.type]))
        end

        IADM:MessageWPrefix(pl, false, IADM_ECHOCOLOR_TEXT, "# "..(ctbl.Name or cmd)..(ctbl.Name and " ("..cmd..")" or "").."\n",
        IADM_ECHOCOLOR_ARG1, ctbl.Desc or "",
        IADM_ECHOCOLOR_ARG1, "\n", string.format(IADM:GetTranslatedText(pl, "Usage: %s%s %s"), IADM:GetPrefix(), cmd, s),
        IADM_ECHOCOLOR_WARN, ctbl.Dangerous and "\n"..IADM:GetTranslatedText(pl, "Dangerous command. Only allow this command to members you trust and if it's necessary.") or "")
        return
    elseif needed ~= 0 then
        IADM:MessageWPrefix(pl, false, IADM_ECHOCOLOR_TEXT, "Not enough arguments provided!")
        return
    end

    for count,arg in ipairs(ctbl.Args) do
        if arg.default and not args[count] then
            args[count] = arg.default
        end

        if arg.choices and not table.HasValue(arg.choices, args[count]) then
            if arg.optional then
                args[count] = nil
            else
                IADM:Message(pl, inchat, IADM_ECHOCOLOR_ERROR, "Arg #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " error: ", IADM_ECHOCOLOR_ERROR_REASON, "Invalid choice! You used ", IADM_ECHOCOLOR_ERROR_REASON, args[count])
                return
            end
        end
    end

    if CLIENT then
        net.Start("iadm_command")
        net.WriteString(cmd)
        IADM_NET_WRITETABLE(args)
        net.SendToServer()

    elseif SERVER then
        if !IADM:CanUseCommand(pl, cmd) then
            IADM:Message(pl, true, IADM_ECHOCOLOR_ERROR, "Insufficient permissions to use ", IADM_ECHOCOLOR_ERROR_ARGVAR, cmd, IADM_ECHOCOLOR_ERROR, " command!")
            pl:SendLua([[surface.PlaySound("buttons/button11.wav")]])
            return ""
        end

        args = IADM:ProcessCmdArgs(pl, inchat, ctbl, args)

        if !args or (#ctbl.Args ~= 0 and defaultargsamt ~= 0 and needed ~= 0) then return end

        if ctbl.ChatArg then
            ctbl.Func(pl, false, unpack(args))
        else
            ctbl.Func(pl, unpack(args))
        end
    end
end

local IADM_AUTOCOMPLETE = function(cmd, argstr, args)
    local pl = CLIENT and LocalPlayer() or !game.IsDedicated() and player.GetAll()[1] or NULL
    local t = {}
    local arg1 = string_lower(args[1] or "")

    local ctbl = IADM.Commands[arg1]

    local next = string.sub(argstr, -1, -1) == " " and 1 or 0
    local currentarg = #args + next

    local islast = true
    local function add_to_results(...)
        if islast then
            table.insert(t, ...)
        end
    end

    if ctbl and currentarg >= 2 then
        local i = false
        local s = ""
        local str
        for count,carg in ipairs(ctbl.Args) do
            if count >= currentarg then break end

            if !str then
                str = cmd.." "..arg1..s
            end
            s = s.." "

            local arg = args[count + 1]
            islast = (count+1)==currentarg

            if (count+1) == currentarg then
                if arg then
                    -- s = s..arg

                    if carg.type == IADM_ARGTYPE_STR then
                       s = s..arg
                       add_to_results(str..s)
                    elseif carg.type == IADM_ARGTYPE_PLR or carg.type == IADM_ARGTYPE_PLRS then
                        if arg == "^" then
                            add_to_results(str..s..(string.format("\"%s\"", pl:Nick())))
                        else
                            for _,ply in ipairs(player.GetAll()) do
                                if string.find(string_lower(ply:Nick()), string_lower(arg)) and IADM:CmdCanTarget(pl, ply, ctbl, carg) then
                                    add_to_results(str..s..(string.format("\"%s\"", ply:Nick())))
                                end
                            end
                        end
                        -- break
                    end
                else
                    if carg.type == IADM_ARGTYPE_PLR or carg.type == IADM_ARGTYPE_PLRS then
                        for _,ply in ipairs(player.GetAll()) do
                            if !IADM:CmdCanTarget(pl, ply, ctbl, carg) then continue end
                            add_to_results(str..s..(string.format("\"%s\"", ply:Nick())))
                        end
                        -- break
                    else
                        local defaulthint = carg.type == IADM_ARGTYPE_NUM and "number" or carg.type == IADM_ARGTYPE_BOOL and "true/false" or "string"
                    
                        s = s ..((args[count + 1] or (carg.optional and string.format("[%s]", carg.hint or defaulthint) or string.format("<%s>", carg.hint or defaulthint))..
                        (carg.type == IADM_ARGTYPE_BOOL and " [1/0, true/false]" or "")))
                        add_to_results(str..s)
                    end
                end
            end

            if args[count+1] and not (carg.type == IADM_ARGTYPE_NUM and carg.type == IADM_ARGTYPE_BOOL) then
                args[count+1] = "\""..args[count+1].."\""
            end

            if arg then
                s=s..arg
            end
        end
    elseif currentarg < 2 then
        local times = 0
        for k,_ in pairs(IADM.Commands) do
            if string.sub(k, 1, #arg1) ~= arg1 then continue end
            if !IADM:CanUseCommand(pl, k) then continue end
            add_to_results(cmd.." "..k)
            if times >= 50 then break end
        end
    end

    return t
end

concommand.Add("iadm", IADM_CMD, IADM_AUTOCOMPLETE, "nil", 0)
concommand.Add("ulx", IADM_CMD, IADM_AUTOCOMPLETE, "nil", 0)
concommand.Add("sam", IADM_CMD, IADM_AUTOCOMPLETE, "nil", 0)

concommand.Add("iadm_config", function(pl, cmd, args, str)
    local prefix = "[IADM] "
    local iterfunc, tbl = pairs(IADM.Config)

    if #args == 0 then
        local c = 0
        for _,ctbl in iterfunc, tbl do
            c = c + 1
        end

        IADM:MessageWPrefix(pl, false, IADM_ECHOCOLOR_TEXT, "No config selected. Currently available config options: (", IADM_ECHOCOLOR_ARG1, c, IADM_ECHOCOLOR_TEXT, ")")
        
        for id,ctbl in iterfunc, tbl do
            IADM:Message(pl, false, IADM_ECHOCOLOR_ARG2, "\t-> ", IADM_ECHOCOLOR_ARG3, ctbl.Name, IADM_ECHOCOLOR_TEXT, " (", IADM_ECHOCOLOR_ARG2, id, IADM_ECHOCOLOR_TEXT, ")")
        end

        return
    end

    cfg = string_lower(args[1] or "")

    local ctbl = IADM.Config[cfg]
    if !ctbl then
        for k,_ in SortedPairs(IADM.Config) do
            if string.sub(k, 1, #cfg) ~= cfg then continue end
            -- if !IADM:CanUseCommand(pl) then continue end
            IADM:MessageWPrefix(pl, false, IADM_ECHOCOLOR_TEXT, "Invalid config setting ", IADM_ECHOCOLOR_ARG1, cfg, IADM_ECHOCOLOR_TEXT, ". Maybe you meant: ", IADM_ECHOCOLOR_ARG1, k, IADM_ECHOCOLOR_TEXT, "?")
            return
        end

        IADM:MessageWPrefix(pl, false, IADM_ECHOCOLOR_TEXT, "Invalid config option ", IADM_ECHOCOLOR_ARG1, cfg, IADM_ECHOCOLOR_TEXT, ".")
        return
    end

    local option = args[2]
    if not option then
        IADM:Message(pl, false, IADM_ECHOCOLOR_TEXT, "This configuration has a set of ", IADM_ECHOCOLOR_ARG1, table.Count(ctbl.Options), IADM_ECHOCOLOR_TEXT, " options available.")
        IADM:Message(pl, false, IADM_ECHOCOLOR_TEXT, "Available options:")
        for id,tbl in SortedPairs(ctbl.Options) do
            IADM:Message(pl, false, IADM_ECHOCOLOR_ARG1, "\t--> ", IADM_ECHOCOLOR_ARG2, tbl.Name or "No name.", " ", IADM_ECHOCOLOR_ARG2, "(", IADM_ECHOCOLOR_ARG3, id, IADM_ECHOCOLOR_ARG2, ")")
            IADM:Message(pl, false, IADM_ECHOCOLOR_ARG2, "\t\t-> ", IADM_ECHOCOLOR_ARG3, tbl.Desc or "No description available.")
            IADM:Message(pl, false, IADM_ECHOCOLOR_ARG2, "\t\t-> ", IADM_ECHOCOLOR_ARG3, "Value set to: ", IADM_ECHOCOLOR_ARG1, ctbl:GetConfigValue(id))
        end

        return
    end

    args[1] = nil
    args[2] = nil


    local new_args = {}
    for _,text in pairs(args) do
        table.insert(new_args, text)
    end
    args = new_args




    if CLIENT then
        net.Start("iadm_playereditconfig")
        net.WriteString(cfg)
        net.WriteString(option)
        IADM_NET_WRITETABLE(args)
        net.SendToServer()
    elseif SERVER then
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
            IADM:Message(pl, false, IADM_ECHOCOLOR_TEXT, "Name: ", IADM_ECHOCOLOR_ARG1, modtbl.Name)
            IADM:Message(pl, false, IADM_ECHOCOLOR_TEXT, "Desc: ", IADM_ECHOCOLOR_ARG1, modtbl.Desc)
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
    end
end, function(cmd, argstr, args)
    local pl = CLIENT and LocalPlayer() or !game.IsDedicated() and player.GetAll()[1] or NULL
    local t = {}
    local arg1 = string_lower(args[1] or "")
    local arg2 = string_lower(args[2] or "")
    local ctbl = IADM.Config[arg1]

--[[

    local next = string.sub(argstr, -1, -1) == " " and 1 or 0
    local currentarg = #args + next

    local islast = true
    local function add_to_results(...)
        if islast then
            table.insert(t, ...)
        end
    end

    if ctbl and currentarg >= 2 then
        local i = false
        local s = ""
        local str
        for count,carg in ipairs(ctbl.Options) do
            if count >= currentarg then break end

            if !str then
                str = cmd.." "..arg1..s
            end
            s = s.." "

            local arg = args[count + 1]
            islast = (count+1)==currentarg

            if (count+1) == currentarg then
                if arg then
                    -- s = s..arg

                    if carg.type == IADM_ARGTYPE_STR then
                       s = s..arg
                       add_to_results(str..s)
                    elseif carg.type == IADM_ARGTYPE_PLR or carg.type == IADM_ARGTYPE_PLRS then
                        if arg == "^" then
                            add_to_results(str..s..(string.format("\"%s\"", pl:Nick())))
                        else
                            for _,ply in ipairs(player.GetAll()) do
                                if string.find(string_lower(ply:Nick()), string_lower(arg)) and IADM:CmdCanTarget(pl, ply, ctbl, carg) then
                                    add_to_results(str..s..(string.format("\"%s\"", ply:Nick())))
                                end
                            end
                        end
                        -- break
                    end
                else
                    if carg.type == IADM_ARGTYPE_PLR or carg.type == IADM_ARGTYPE_PLRS then
                        for _,ply in ipairs(player.GetAll()) do
                            if !IADM:CmdCanTarget(pl, ply, ctbl, carg) then continue end
                            add_to_results(str..s..(string.format("\"%s\"", ply:Nick())))
                        end
                        -- break
                    else
                        local defaulthint = carg.type == IADM_ARGTYPE_NUM and "number" or carg.type == IADM_ARGTYPE_BOOL and "true/false" or "string"
                    
                        s = s ..((args[count + 1] or (carg.optional and string.format("[%s]", carg.hint or defaulthint) or string.format("<%s>", carg.hint or defaulthint))..
                        (carg.type == IADM_ARGTYPE_BOOL and " [1/0, true/false]" or "")))
                        add_to_results(str..s)
                    end
                end
            end

            if args[count+1] and not (carg.type == IADM_ARGTYPE_NUM and carg.type == IADM_ARGTYPE_BOOL) then
                args[count+1] = "\""..args[count+1].."\""
            end

            if arg then
                s=s..arg
            end
        end
    elseif currentarg < 2 then
        local times = 0
        for k,_ in pairs(IADM.Config) do
            if string.sub(k, 1, #arg1) ~= arg1 then continue end
            if !IADM:CanUseCommand(pl, k) then continue end
            add_to_results(cmd.." "..k)
            if times >= 50 then break end
        end
    end

]]
    return t
end, "nil", 0)

concommand.Add("iadm_changelogs", function(pl)
    if not (SERVER and (pl == NULL or pl:IsListenServerHost()) or CLIENT) then return end

    local col_h1 = Color(255, 224, 224)
    local col_h2 = Color(255, 240, 240)
    local col_add = Color(155, 244, 110)
    local col_del = Color(244, 54, 44)
    local col_warn = Color(255, 0, 0)
    local col_change = Color(255, 255, 120)
    local col_fix = Color(86, 209, 239)
    local change_notes = [[## v0.4.1 (#29)
+ Added 1 new global for color

/ Change how the modules load
/ Updated documentation.
/ Moved IADM.BannedPlayers to MODULE.BannedPlayers in bans module

! Note for lua devs: The only problem is that the modules will not be reloading by themselves whenever edited, as it only returns a function while loading the modules.
]]

    local tbl = {}
    for i,v in pairs(string.Explode("\n", change_notes)) do
        if string.sub(v, 1, 1) == "+" then
            tbl[i] = {col_add, v.."\n"}
        elseif string.sub(v, 1, 1) == "-" then
            tbl[i] = {col_del, v.."\n"}
        elseif string.sub(v, 1, 1) == "!" then
            tbl[i] = {col_warn, v.."\n"}
        elseif string.sub(v, 1, 1) == "/" then
            tbl[i] = {col_change, v.."\n"}
        elseif string.sub(v, 1, 1) == "*" then
            tbl[i] = {col_fix, v.."\n"}
        elseif string.sub(v, 1, 2) == "##" then
            tbl[i] = {col_h2, v.."\n"}
        elseif string.sub(v, 1, 1) == "#" then
            tbl[i] = {col_h1, v.."\n"}
        else
            tbl[i] = {color_white, v.."\n"}
        end
    end

    for i=1,#tbl do
        local t = tbl[i]
        MsgC(t[1], t[2])
    end
end)

if not IADM.LogAction then
    function IADM:LogAction() -- add an empty function just in case
    end
end
