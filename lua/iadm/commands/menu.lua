local cmd = IADM:AddCommand("menu", function(caller, chat)
    if CLIENT then
        IADM:OpenMenu()
        return
    end

    if not IsValid(caller) then
        IADM:MessageWPrefix(NULL, false, IADM_ECHOCOLOR_ERROR, "The menu can only be opened by a player!")
        return
    end

    caller:SendLua([[if IADM and IADM.OpenMenu then IADM:OpenMenu() end]])
end)
cmd.Name = "Menu"
cmd.Desc = "Opens the in-game IADM menu."
cmd.ChatArg = true
cmd.PowerLevelReq = IADM_GROUP_POWER_ADMIN
cmd.HideInMenu = true
