local spawnhooks = {
    "Effect",
    "NPC",
    "Object",
    "Prop",
    "Ragdoll",
    "SENT",
    "SWEP",
    "Vehicle"
}

for _, name in ipairs(spawnhooks) do
    hook.Add("PlayerSpawn" .. name, "IADM_SPAWNHOOK",function(...)
        if hook.Run("IADM_PlayerSpawn" .. name,...) then
            return false
        end

        if hook.Run("IADM_PlayerSpawnAll",...) then
            return false
        end
    end, HOOK_MONITOR_HIGH)
end