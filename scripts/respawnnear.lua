if not GLOBAL.TheNet:GetIsServer() then 
    return
end

local Vector3 = GLOBAL.Vector3
local SpawnPrefab = GLOBAL.SpawnPrefab

local repsawn_time = 5 * 480
local leastnum = 2

local respawn_list = {
    "beefalo",
    "lightninggoat",
    "spiderden",
    "catcoonden",
    "knight",
    "rocky",
    "slurtlehole",
}

for k,v in pairs(respawn_list) do
    local function PushDeathEvent(inst)
        inst:ListenForEvent("onremove", function(inst)
            local current_num = GLOBAL.c_countprefabs(v, true)
            if current_num < leastnum then
                local pos = Vector3(inst.Transform:GetWorldPosition())
                local instName = "〖"..GetInstName(inst).."〗"
                GLOBAL.TheWorld:PushEvent(v.."_death", {name = v, pos = pos, instName = instName})
                GLOBAL.TheNet:Announce(instName.."濒临灭绝 数量为："..current_num.." 将在五天后再生")
            end
        end)
    end
    AddPrefabPostInit(v, PushDeathEvent)
end

--获取实体名称
local function GetInstName(inst)
    return inst and inst:GetDisplayName() or "*无名*"
end

local function OnRecieveDeathEvent(inst)
    inst:AddComponent("timer")

    if inst.spawnlist == nil then
        inst.spawnlist = {}
    end

    for k,v in pairs(respawn_list) do
        inst:ListenForEvent(v.."_death", function(inst,data)
            table.insert(inst.spawnlist, data)
            local i = 0
            while inst.components.timer:TimerExists(v.."_"..i)
            do
                i = i + 1
            end
            inst.components.timer:StartTimer(v.."_"..i, repsawn_time)
            print("StartTimer", v.."_"..i)
        end, GLOBAL.TheWorld)
    end

    local function ontimerdone(inst, data)
        for k,v in pairs(inst.spawnlist) do
            if v.name == string.split(data.name, "_")[1] then
                local pos = v.pos
                local result_pos = GLOBAL.FindNearbyLand(pos, 15) or pos
                local tryspawn = SpawnPrefab(v.name)
                tryspawn.Transform:SetPosition(result_pos:Get())
                print(v.name, 'spawned at', result_pos.x, result_pos.z)
                GLOBAL.TheNet:Announce(v.instName.."已再生")
                table.remove(inst.spawnlist, k)
                break
            end
        end
    end

    inst:ListenForEvent("timerdone", ontimerdone)

    local OldOnSave = inst.OnSave
    local OldOnLoad = inst.OnLoad

    inst.OnSave = function(inst, data)
        if OldOnLoad then
            OldOnSave(inst, data)
        end
        if inst.spawnlist ~= nil then
            data.spawnlist = inst.spawnlist
        end
    end

    inst.OnLoad = function(inst, data)
        if OldOnLoad then
            OldOnLoad(inst, data)
        end
        if data ~= nil and data.spawnlist ~= nil then 
            inst.spawnlist = data.spawnlist
        end
    end

end

AddPrefabPostInit("world", OnRecieveDeathEvent)