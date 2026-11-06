function IADM:GetUserGroup(pl)
    if IsValid(pl) then
        return pl:GetNWString("IADM_UserGroup","user")
    end
    return
end

function IADM:GetSteamID64(pl)
    if IsValid(pl) then
        return pl:IsBot() and "1" or pl:SteamID64()
    end

    return "0"
end


local meta_ply = FindMetaTable("Player")
if meta_ply then
    function meta_ply:IADMMessage(chat, ...)
        net.Start("iadm_printmsg")
        net.WriteBit(tobool(chat))
        IADM_NET_WRITETABLE({...})
        net.Send(self)
    end

    function meta_ply:GetIADMSessionTime()
        return self.IADM_playtime - self.IADM_spawntime + SysTime()
    end

    local M_SteamID64 = meta_ply.SteamID64
    function meta_ply:GetIADMSteamID64()
        return IADM:GetSteamID64(self)
    end

    function meta_ply:IADMGetUserGroup()
        return IADM:GetUserGroup(self)
    end

    meta_ply.GetUserGroup = meta_ply.IADMGetUserGroup

    function meta_ply:GetGroupPowerLevel()
        return IADM.UserGroups[self:IADMGetUserGroup()].powerlevel or 1
    end
end
