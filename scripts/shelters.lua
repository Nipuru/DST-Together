local _G = GLOBAL
local TheNet = _G.TheNet
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

--移除可砸属性
local function RemoveHammer(inst)
    if inst and not inst.gd_hammerremoved and inst.components.workable ~= nil then
        inst.gd_hammerremoved = true
        if inst:HasTag("HAMMER_workable") then
            inst:RemoveTag("HAMMER_workable")
        end
    end
end

--移除可燃烧属性
local function RemoveBurnable(inst)
    -- if _G.TheWorld.ismastersim then
    if inst and not inst.gd_lightremoved and inst.components.burnable ~= nil then
        inst.gd_lightremoved = true
        if inst:HasTag("canlight") then
            inst.canlight = true
            inst:RemoveTag("canlight")
        end
        if inst:HasTag("nolight") then
            inst.nolight = true
        else
            inst:AddTag("nolight")
        end
        if inst.components.fueled == nil or inst.components.circuitnode then
            if inst:HasTag("fireimmune") then
                inst.fireimmune = true
            else
                inst:AddTag("fireimmune")
            end
        end
    end
end

if IsServer then
    RemoveBurnableTable = {
        "blueprint", -- 蓝图
        "tallbirdnest", -- 高脚鸟巢穴
        "reeds", --芦苇
        "catcoonden", --空心树桩
        "cutlichen", --苔藓
        "cactus", --仙人掌（球形）
        "oasis_cactus", --仙人掌（叶形）
        "icepack" --保鲜背包
    }
    RemoveHammerableTable = {
        "catcoonden", --空心树桩
    }

    -- 移除可燃属性 
    for k, name in pairs(RemoveBurnableTable) do
        AddPrefabPostInit(
            name, 
            function(inst) 
                RemoveBurnable(inst)
            end            
        )
    end
    -- 移除可砸属性
    for k, name in pairs(RemoveHammerableTable) do
        AddPrefabPostInit(
            name, 
            function(inst) 
                RemoveHammer(inst)
            end            
        )
    end
end
