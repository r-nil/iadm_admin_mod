local cmd = IADM:AddCommand("lag", function(caller, chat)
    local count = 0
    for _,v in ipairs(ents.GetAll())do
        if v:GetPhysicsObjectCount() > 0 then
            for i = 0, v:GetPhysicsObjectCount() do
                local phy = v:GetPhysicsObjectNum(i)
                if IsValid(phy) then
                    phy:EnableMotion(false)
                    phy:Sleep()
                    count = count + 1
                end
            end
        end
    end
    IADM:LogCommandUse(caller, "#A froze #N PhysObjs", false, count)
end)
cmd.Name = "Lag"
cmd.Desc = "Freeze every PhysObjs"
cmd.ChatArg = true
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN

local cmd = IADM:AddCommand("llag", function(caller, chat)
    local count = 0
    for _,v in ipairs(ents.GetAll())do
        if v:GetPhysicsObjectCount() > 0 then
            for i = 0, v:GetPhysicsObjectCount() do
                local phy = v:GetPhysicsObjectNum(i)
                if IsValid(phy) then
                    phy:Sleep()
                    count = count + 1
                end
            end
        end
    end
    IADM:LogCommandUse(caller, "#A made #N PhysObjs sleep", false, count)
end)
cmd.Name = "LLag"
cmd.Desc = "Make every PhysObjs sleep"
cmd.ChatArg = true
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN

local SLAGING = false

local cmd = IADM:AddCommand("slag", function(caller, chat)
    game.CleanUpMap()
    physenv.SetPhysicsPaused(true)
    SLAGING = true
    timer.Create("slag_recover",30,1,function()
        physenv.SetPhysicsPaused(false)
        SLAGING = false
    end)
    for _,v in ipairs(player.GetAll()) do
        v:StripWeapons()
    end
    IADM:LogCommandUse(caller, "#A TRIED TO STOP THE LAG", false)
    IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_TEXT, "SLag will be disabled in 30 seconds")
end)
cmd.Name = "SLag"
cmd.Desc = "Cleans up the map and stops physics simulation / all player's sandbox functions for 30 seconds, removes everyone's weapons"
cmd.ChatArg = true
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN

IADM:AddHook("IADM_PlayerSpawnALL", "SLag", function()
    if SLAGING then
        return true
    end
end, HOOK_MONITOR_HIGH)