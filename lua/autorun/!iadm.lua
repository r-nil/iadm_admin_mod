if CLIENT then larp("@addons/iadm_admin_mod/lua/autorun/!iadm.lua") end

if not (PRE_HOOK and PRE_HOOK_RETURN and HOOK_MONITOR_LOW and HOOK_LOW and HOOK_NORMAL and HOOK_HIGH and HOOK_MONITOR_HIGH and POST_HOOK_RETURN and POST_HOOK) then
    ErrorNoHaltWithStack("Srlion's hook library is not installed, IADM will not start!")
    return
end

local oinclude = include
local include = function(name,...)
    if larp then larp("@addons/iadm_admin_mod/lua/" .. name) end
    local a1,a2 = oinclude(name,...)
    if larp then larp("@addons/iadm_admin_mod/lua/" .. name) end
    return a1,a2
end

AddCSLuaFile("iadm/thirdparty/sfs.lua")

AddCSLuaFile("iadm/globals.lua")
include("iadm/globals.lua")

AddCSLuaFile("iadm/init.lua")
include("iadm/init.lua")

AddCSLuaFile("iadm/translate.lua")
include("iadm/translate.lua")

local files = file.Find("iadm/languages/*.lua", "LUA", "sortasc")
for _,name in ipairs(files) do
    AddCSLuaFile("iadm/languages/"..name)
    include("iadm/languages/"..name)
end

AddCSLuaFile("iadm/sh_net.lua")
include("iadm/sh_net.lua")

AddCSLuaFile("iadm/sh_meta.lua")
include("iadm/sh_meta.lua")

if SERVER then include("iadm/sv_meta.lua") end

if SERVER then
    include("iadm/sv_init.lua")
    include("iadm/sv_hooks.lua")
    include("iadm/sv_net.lua")
end

AddCSLuaFile("iadm/cl_init.lua")
AddCSLuaFile("iadm/cl_net.lua")
if CLIENT then
    include("iadm/cl_init.lua")
    include("iadm/cl_net.lua")
end

AddCSLuaFile("iadm/sh_cami.lua")
include("iadm/sh_cami.lua")

AddCSLuaFile("iadm/sh_cami_iadm.lua")
include("iadm/sh_cami_iadm.lua")

if SERVER then include("iadm/sv_sandbox.lua") end

local modulestoenable = {}
files = file.Find("iadm/modules/*.lua", "LUA", "sortasc")
for _,name in ipairs(files) do
    if string.StartsWith(name, "sv_") then continue end
    IADM_MODULE_SHOULDINCLUDE = true
    AddCSLuaFile("iadm/modules/"..name)
    MODULE = {}
    local MOD, MODFUNC = include("iadm/modules/"..name)
    local SVMODFUNC

    IADM.Modules[MODULE.ID:lower()] = MODULE

    if MOD then
        MOD.ID = string.sub(name, 1, -5)
        MOD.Included = tobool(IADM_MODULE_SHOULDINCLUDE)
    end
    if SERVER and file.Exists("iadm/modules/sv_"..name, "LUA") then
        MODULE = MOD
        SVMODFUNC = include("iadm/modules/sv_"..name)
        MODULE = nil
    end

    if IADM_MODULE_SHOULDINCLUDE or MODULE.Included then
        table.insert(modulestoenable, {
            Module = MOD,
            ModuleFunc = MODFUNC,
            SVModuleFunc = SVMODFUNC,
            Priority = MOD.Priority or 10
        })
    end
    IADM_MODULE_SHOULDINCLUDE = nil
end
for _,tbl in ipairs(modulestoenable) do
    if tbl.ModuleFunc then
        tbl.ModuleFunc(tbl.Module)
    end
    if tbl.SVModuleFunc then
        tbl.SVModuleFunc(tbl.Module)
    end
end

files = file.Find("iadm/commands/*.lua", "LUA", "sortasc")
for _,file in ipairs(files) do
    AddCSLuaFile("iadm/commands/"..file)
    include("iadm/commands/"..file)
end
