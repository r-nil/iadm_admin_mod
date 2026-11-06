MODULE.ID = "groups"
MODULE.Name = "Groups"
MODULE.Description = "Main module for managing groups"
MODULE.Required = true

return MODULE, function(MODULE)
    if not IADM.UserGroups then -- default table
        IADM.UserGroups = {
            ["superadmin"] = {powerlevel = IADM_GROUP_POWER_SUPERADMIN, isadmin=true, issuperadmin=true},
            ["admin"] = {powerlevel = IADM_GROUP_POWER_ADMIN, isadmin=true, issuperadmin=false},
            ["user"] = {powerlevel = IADM_GROUP_POWER_USER, isadmin=false, issuperadmin=false}
        }
    end


    if CLIENT then
        IADM:RegisterInitDataSync("groups", function(_, pl, tbl)
            IADM.UserGroups = tbl
        end)

        IADM:RegisterDataSync("groups", function(_, pl, tbl)
            IADM.UserGroups = tbl
        end)
    end




    local player = FindMetaTable("Player")
    if not player then return end

    function player:IsAdmin()
        local usergroup = IADM.UserGroups[self:IADMGetUserGroup()]
        return usergroup and (usergroup.isadmin or self:IsSuperAdmin())
    end

    function player:IsSuperAdmin()
        local usergroup = IADM.UserGroups[self:IADMGetUserGroup()]
        return usergroup and usergroup.issuperadmin
    end
end
