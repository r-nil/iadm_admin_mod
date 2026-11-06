function IADM:SetUserGroup(pl, usergroup)
    if IsValid(pl) and usergroup then
        local changed = IADM:GetUserGroup(pl) ~= usergroup
        if changed then
            pl:SetNWString("IADM_UserGroup", usergroup)
            return true
        else
            return false
        end
    end
    return false
end


local meta_ply = FindMetaTable("Player")
if meta_ply then
    function meta_ply:IADMSetUserGroup(usergroup)
        return IADM:SetUserGroup(self, usergroup)
    end

    function meta_ply:IADMSetGodMode(enabled)
        if enabled == nil or not isbool(enabled) then return end

        self.IADM_GodMode = enabled
    end
end
