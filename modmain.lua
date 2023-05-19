local _G = GLOBAL
local TheNet = _G.TheNet

local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()
if IsServer then
    modimport("scripts/bag")
    modimport("scripts/clean.lua")
    modimport("scripts/stack.lua")
    modimport("scripts/respawnnear.lua")
    modimport("scripts/rules.lua")
end