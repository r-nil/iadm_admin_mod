local allplys = player.GetAll

local cmd = IADM:AddCommand("teleport", function(caller, target)
    if target:Alive() then
        target:SetPos(caller:GetEyeTrace().HitPos+Vector(0,0,20))
        target:DropToFloor()
        target:SetVelocity(-target:GetVelocity())
        if caller ~= target then
            -- IADM:MessageWPrefix(allplys(), true, IADM_ECHOCOLOR_TEXT, "Teleported ", IADM_ECHOCOLOR_ARG1, target:Nick(), IADM_ECHOCOLOR_TEXT, "!")
			IADM:LogCommandUse(caller, "#A teleported #T", false, target)
        end
    else
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_ERROR, Format("%s dead!", caller == target and "You are" or target:Nick().." is"))
    end
end)
cmd.Name = "Teleport"
cmd.Desc = "Teleports the player to where you are looking."
cmd.Aliases = {"tp", "tele"}
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_PLR, default="^"})

local cmd = IADM:AddCommand("goto", function(caller, target)
    if target:Alive() then
        caller:SetPos(target:GetPos()-Angle(0,target:EyeAngles().yaw,0):Forward()*48*(caller:GetModelScale()+target:GetModelScale())/2)
        caller:SetVelocity(-caller:GetVelocity())
        caller:SetEyeAngles(target:EyeAngles())
        -- IADM:MessageWPrefix(allplys(), true, IADM_ECHOCOLOR_TEXT, "Teleported to ", IADM_ECHOCOLOR_ARG1, target:Nick(), IADM_ECHOCOLOR_TEXT, "!")
		IADM:LogCommandUse(caller, "#A teleported to #T", false, target)
    else
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_TEXT, Format("%s dead!", caller == target and "You are" or target:Nick().." is"))
    end
end)
cmd.Name = "Goto"
cmd.Desc = "Teleports to the target."
cmd.Aliases = {"tpto"}
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_PLR})
cmd.IgnoreCanTarget = true

local cmd = IADM:AddCommand("bring", function(caller, target)
    if caller == target then
        IADM:MessageWPrefix(allplys(), true, IADM_ECHOCOLOR_ERROR, "Error: ", IADM_ECHOCOLOR_ERROR_REASON, "You cannot bring ", IADM_ECHOCOLOR_ERROR_ARGVAR, "yourself", IADM_ECHOCOLOR_ERROR_REASON, "!")
        return
    end
    if target:Alive() then
        local aim = caller:GetAimVector()
        local ang = caller:EyeAngles()
        aim.z = 0
        ang.pitch = 0
        ang.yaw = ang.yaw - 180
        aim:Normalize()
        target:SetPos(caller:GetPos()+aim*50)
        target:SetVelocity(-target:GetVelocity())
        target:SetEyeAngles(ang)
        -- if caller ~= target then
            -- IADM:MessageWPrefix(allplys(), true, IADM_ECHOCOLOR_TEXT, "Teleported ", IADM_ECHOCOLOR_ARG1, target:Nick(), IADM_ECHOCOLOR_TEXT, "!")
        -- end
		IADM:LogCommandUse(caller, "#A brought #T", false, target)
    else
        IADM:MessageWPrefix(caller, true, IADM_ECHOCOLOR_TEXT, Format("%s dead!", caller == target and "You are" or target:Nick().." is"))
    end
end)
cmd.Name = "Bring"
cmd.Desc = "Brings the target to you."
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd:AddArgument({type=IADM_ARGTYPE_PLR, default="^"})
