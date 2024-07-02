local _G = GLOBAL
local TheSim = _G.TheSim
local TheNet = _G.TheNet

--通过id获取当前世界玩家
function GetPlayerById(id) 
    for _,v in pairs(_G.AllPlayers) do
        if v.userid == id then 
            return v
        end
    end
    return nil
end

--获取玩家生存天数
function GetAge(player)
    if player and player.components and player.components.age then
        return player.components.age:GetAgeInDays()
    end
    return 0
end

--找大门
function GetPortal()
    if _G.c_findnext("multiplayer_portal") then
        return _G.c_findnext("multiplayer_portal").Transform:GetWorldPosition()
    end
    if _G.c_findnext("multiplayer_portal_moonrock") then
        return _G.c_findnext("multiplayer_portal_moonrock").Transform:GetWorldPosition()
    end
    return 0,0,0
end

-- 说话
function PlayerSay(player, msg, delay, duration, noanim, force, nobroadcast, colour)
    if player ~= nil and player.components.talker then
        player:DoTaskInTime(
            delay or 0.01,
            function()
                player.components.talker:Say(msg, duration or 2.5, noanim, force, nobroadcast, colour)
            end
        )
    end
end

_G.InitFire = function() 
    local x,y,z = GetPortal()
    _G.SpawnPrefab("campfirefire").Transform:SetPosition(x,y,z)
    _G.SpawnPrefab("coldfirefire").Transform:SetPosition(x,y,z)
end



