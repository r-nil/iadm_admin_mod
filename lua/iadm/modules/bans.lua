MODULE.ID = "bans"
MODULE.Name = "Bans"
MODULE.Description = "Module for managing user bans"

return MODULE, function(MODULE)
    if not MODULE.BannedPlayers then
        MODULE.BannedPlayers = {}
    end
    
    IADM:AddSQLDatabase("bans", function(id)
        sql.QueryTyped("CREATE TABLE IF NOT EXISTS "..(IADM.DatabaseDir.."_"..id).." ("..
            "id64 BIGINT PRIMARY KEY, "..
            "name CHAR(255), "..
            "banstart INT UNSIGNED, "..
            "banend INT UNSIGNED, "..
            "duration BIGINT, "..
            "reason VARCHAR(4096), "..
            "bannedby BIGINT, "..
            "bannedbyname CHAR(255)"..
        ")")
    end)
    
    IADM:AddLoadSQL("bans", function(id)
        for count,user in ipairs(sql.QueryTyped("SELECT * FROM "..(IADM.DatabaseDir.."_"..id))) do
            local id64 = user.id64
            user.id64 = nil
            MODULE.BannedPlayers[id64] = user
        end
    end)
    
    
    function IADM:CanBeBanned(id64)
        local ply = player.GetBySteamID64(id64)
        if IsValid(ply) and ply:IsListenServerHost() then return false end
    
        return true
    end
    
    function IADM:AddBan(id64, reason, duration, bannedby)
        if IsValid(id64) then id64 = id64:SteamID64()
        elseif type(id64) ~= "string" then return false, "Invalid user!" end
        if IsValid(bannedby) then bannedby = bannedby:GetIADMSteamID64()
        elseif type(bannedby) ~= "string" and bannedby ~= NULL then return false, "Invalid user banning the target!" end
    
        if id64 == bannedby then return false, "You cannot ban yourself!" end
        if !IADM:CanBeBanned(id64) then return false, "This target is immune to being banned!" end
    
    
        local ply = player.GetBySteamID64(id64)
        local isbot = IsValid(ply) and ply:IsBot()
    
        local start = os.time()
        local banend = duration == 0 and 0 or (start + duration)
    
        local dbname = IADM.DatabaseDir.."_bans"
        local bannedusername = sql.QueryTyped("SELECT * FROM iadm_users WHERE id64=? LIMIT 1", id64)
    	if bannedusername and bannedusername[1] then
    		bannedusername = bannedusername[1].name
    	end
        local banname = sql.QueryTyped("SELECT * FROM iadm_users WHERE id64=? LIMIT 1", bannedby)
    	if banname then
    		banname = banname[1].name
    	else
    		if IsValid(player.GetBySteamID64(bannedby)) then
    			banname = player.GetBySteamID64(bannedby):Name()
    		else
    			banname = "Console"
    		end 
    	end
        local bannedbyid = IsValid(bannedby) and bannedby:SteamID64() or bannedby == NULL and "0" or bannedby
        local tbl = {
            name = banname,
            banstart = start,
            banend = banend,
            duration = duration,
            reason = reason,
            bannedby = bannedbyid,
            bannedbyname = banname
        }
        MODULE.BannedPlayers[id64] = tbl
    
        if !ply:IsValid() or !isbot then
            sql.QueryTyped("INSERT INTO "..dbname.." (id64, name, banstart, banend, duration, reason, bannedby, bannedbyname) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                id64,
    			tbl.name,
                tbl.banstart,
                tbl.banend,
                tbl.duration,
                tbl.reason,
                tbl.bannedby,
                tbl.bannedbyname
            )
        
    		game.ConsoleCommand(string.format("banid %d %s \"%s\"\n", math.ceil(duration/60), util.SteamIDFrom64(id64), reason))
    		RunConsoleCommand("writeid")
        end
    
        if IsValid(ply) then
            ply:Kick(IADM:GetBanReason(id64, true))
        
            if isbot then -- don't actually ban bots since if they do it can be problematic
                MODULE.BannedPlayers[id64] = nil
            end
        end
    
        return true
    end
    
    function IADM:RemoveBan(id64, reason)
        if not MODULE.BannedPlayers[id64] then return false, "This player is not banned, or doesn't exist!" end
        local banned = sql.QueryTyped("SELECT * FROM iadm_users WHERE id64=? LIMIT 1", id64)
    	if banned then
    		banned = banned[1]
    	end
    
        local dbname = IADM.DatabaseDir.."_bans"
        local bannedbyid = IsValid(bannedby) and bannedby:SteamID64() or bannedby == NULL and "0"
    
    	sql.QueryTyped("DELETE FROM "..dbname.." WHERE id64=?", id64)
    	MODULE.BannedPlayers[id64] = nil
    
    	game.ConsoleCommand(string.format("removeid %s\n", util.SteamIDFrom64(id64)))
    	RunConsoleCommand("writeid")
    
        return true
    end
    
    function IADM:GetBanReason(id64, bypass)
        if !bypass and not IADM:IsPlayerBanned(id64) then return "null" end
        local bantbl = MODULE.BannedPlayers[id64]
        local r = [[oh no! you got reported by tj!!!!
maybe don't be mean!!!
    
    Reason: %reason%
    Banned by: %bannedbyname% (%bannedbyid%)
    Unbanned in: %time%]]
    
    	local timeleft = bantbl.banend - os.time()
    	local s = ""
    	if bantbl.banend ~= 0 then
    		if timeleft >= 31536000 then
    			if s ~= "" then
    				s = s..", "
    			end
            
    			local yrs = math.floor(timeleft/31536000)
    			s = s..yrs.." years"
    			timeleft = timeleft - yrs*31536000
    		end
        
    		if timeleft >= 86400 then
    			if s ~= "" then
    				s = s..", "
    			end
            
    			local days = math.floor(timeleft/86400)
    			s = s..days.." days"
    			timeleft = timeleft - days*86400
    		end
        
    		if timeleft >= 3600 then
    			if s ~= "" then
    				s = s..", "
    			end
            
    			local hours = math.floor(timeleft/3600)
    			s = s..hours.." hours"
    			timeleft = timeleft - hours*3600
    		end
        
    		if timeleft >= 60 then
    			if s ~= "" then
    				s = s..", "
    			end
            
    			local mins = math.floor(timeleft/60)
    			s = s..mins.." minutes"
    			timeleft = timeleft - mins*60
    		end
        
    		if timeleft > 0 then
    			if s ~= "" then
    				s = s..", "
    			end
            
    			s = s..timeleft.." seconds"
    		end
    	end
    
        r = string.Replace(r, "%reason%", bantbl.reason)
        r = string.Replace(r, "%time%", bantbl.banend == 0 and "Never" or s)
        r = string.Replace(r, "%bannedbyname%", bantbl.bannedbyname)
        r = string.Replace(r, "%bannedbyid%", bantbl.bannedby)
    
    
        return r
    end
    
    function IADM:IsPlayerBanned(id64)
        local bantbl = MODULE.BannedPlayers[id64]
        local time = os.time()
        if !bantbl then return false end
    
        return bantbl and (bantbl.banend == 0 or bantbl.banend > time)
    end
    
    
    IADM:AddHook("CheckPassword", "checkBanned", function(id64, ipAddress, svPassword, clPassword, name)
    	local tbl = MODULE.BannedPlayers[id64]
        if IADM:IsPlayerBanned(id64) then
    		MsgC(IADM_ECHOCOLOR_ARG1, name, IADM_ECHOCOLOR_TEXT, " (", IADM_ECHOCOLOR_ARG2, id64, IADM_ECHOCOLOR_TEXT, ", ", IADM_ECHOCOLOR_ARG3, ipAddress, IADM_ECHOCOLOR_TEXT, ") ", "attempted to join, they are still banned!")
    		if tbl.banend == 0 then
    			MsgC(IADM_ECHOCOLOR_ERROR, " (permanently)")
    		end
    		MsgN()
        
            return false, IADM:GetBanReason(id64, true)
    	elseif tbl then
    		IADM:MessageWPrefix(NULL, nil, IADM_ECHOCOLOR_TEXT, "Removing ban for ", IADM_ECHOCOLOR_ARG1, id64)
    		IADM:RemoveBan(id64, "Ban expired.", NULL)
    		--return false, "#GameUI_ConnectionFailed"
        end
    end)
    
    timer.Create("CheckBans", 1, 0, function()
    	for id64,tbl in pairs(MODULE.BannedPlayers) do
    		if tbl.banend ~= 0 and tbl.banend <= os.time() then
    			IADM:MessageWPrefix(NULL, nil, IADM_ECHOCOLOR_TEXT, "Removing ban for ", IADM_ECHOCOLOR_ARG1, id64)
    			IADM:RemoveBan(id64, "Ban expired", NULL)
    		end
    	end
    end)
end
