local _G = GLOBAL
local SpawnPrefab = _G.SpawnPrefab

-- 基本的物资1
local basic_items1 = 
{
    "cutgrass", -- 草
    "twigs", -- 树枝
    "log", -- 木头
    "flint", -- 燧石
    "rocks", -- 石头
    "meat", -- 肉
    "carrot", -- 胡萝卜
}
-- 基本的物资2
local basic_items2 = 
{
    "amulet", -- 重生护符
    "footballhat", -- 猪皮头
    "armorwood", -- 木甲
    "spear", -- 长矛
    "pumpkin_lantern", -- 南瓜灯
    "redlantern2", -- 红灯笼
}
-- 冬天的物资
local winter_items = 
{
    "heatrock", -- 暖石
    "winterhat", -- 冬帽
}
-- 春天物资
local spring_items = 
{
    "umbrella", -- 雨伞
    "strawhat", -- 草帽
}
-- 夏天物资
local summer_items = 
{
    "nitre", -- 硝石
    "ice", -- 冰
    "heatrock", -- 暖石
    "strawhat", -- 草帽
    "coldfire_blueprint", -- 冷火蓝图
}

-- 给礼物(玩家，礼物列表，礼物1数量，礼物2数量，礼物3数量，礼物4数量)
function GiveStartGift(player, items, name, i1, i2, i3, i4, i5, i6, i7)
    local bundle = SpawnPrefab("gift") 

    if name ~= nil then
        if bundle.components.named == nil then
            inst:AddComponent("named")   
        end
        bundle.components.named:SetName(name)
    end

    local stacksize = 
    {
        i1,i2,i3,i4,i5,i6,i7
    } 

    local spawn_items = {} 

    for i = 1,#items do 
        spawn_items[i] = SpawnPrefab(items[i]) 
        if spawn_items[i] ~= nil and spawn_items[i].components.stackable ~= nil then 
            spawn_items[i].components.stackable.stacksize = stacksize[i] or 1 
        end
    end

    bundle.components.unwrappable:WrapItems(spawn_items)
    for i, v in ipairs(spawn_items) do
        v:Remove()
    end 
    local container = player.components.inventory or player.components.container
    container:GiveItem(bundle)
end 

--玩家初始物品（可根据自己需要自行修改，因为物资是通过包装的礼物的形式给的，所以一个礼物包的物品不能超过四种）
local function StartingInventory(inst, player)
    
    --玩家第一次进入时获取初始物品
    local CurrentOnNewSpawn = player.OnNewSpawn or function()
            return true
        end
    player.OnNewSpawn = function(...)
        player.components.inventory.ignoresound = true

        player:DoTaskInTime(
            1,
            function(inst) 
                GiveStartGift(player, basic_items1, "应急物资\n比较占格子，应急时打开", 9, 8, 8, 8, 9, 2, 5)
                GiveStartGift(player, basic_items2, "基础物资")
                --初始进入的时间是冬天或者临近冬天的时候
                if GLOBAL.TheWorld.state.iswinter or (GLOBAL.TheWorld.state.isautumn and GLOBAL.TheWorld.state.remainingdaysinseason < 5) then
                    GiveStartGift(player, winter_items,"冬季物资")
                end

                --春天
                if GLOBAL.TheWorld.state.isspring or (GLOBAL.TheWorld.state.iswinter and GLOBAL.TheWorld.state.remainingdaysinseason < 3) then
                    GiveStartGift(player, spring_items,"春季物资")
                end

                --夏天
                if GLOBAL.TheWorld.state.issummer or (GLOBAL.TheWorld.state.isspring and GLOBAL.TheWorld.state.remainingdaysinseason < 5) then
                    GiveStartGift(player, summer_items,"夏季物资", 6, 6)
                end
            end
        )

        return CurrentOnNewSpawn(...)
    end
end

--初始化
AddPrefabPostInit(
    "world",
    function(inst)
        if GLOBAL.TheWorld.ismastersim then --判断是不是主机
            inst:ListenForEvent("ms_playerspawn", StartingInventory, inst)
        end
    end
)
