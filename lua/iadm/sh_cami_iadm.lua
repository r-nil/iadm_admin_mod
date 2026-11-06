local def_usergroups = {
    user = true,
    admin = true,
    superadmin = true
}

if IADM.UserGroups then
    for usergroup, tbl in pairs(IADM.UserGroups) do
        if def_usergroups[usergroup] then continue end
        CAMI.RegisterUsergroup({
            Name = usergroup,
            Inherits = "user" -- No Inherits in IADM.
        })
    end
end

hook.Add("CAMI.OnUsergroupRegistered","IADMCamiGroupRegistered",function(usergroup, source)
    if def_usergroups[usergroup] then return end
end)