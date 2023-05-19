local TheNet = GLOBAL.TheNet
local TheSim = GLOBAL.TheSim
local TUNING = GLOBAL.TUNING
local LaunchAt = GLOBAL.LaunchAt
local SpawnPrefab = GLOBAL.SpawnPrefab
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

local FOODTYPE = GLOBAL.FOODTYPE

-- 物品自动堆叠检测范围
local SEE_ITEM_STACK_DIST = 10
local PI = 3.14159

local INV_TAG = { "_inventoryitem" }
local NO_INV_TAG = { "INLIMBO", "NOCLICK", "catchable", "fire" }

-- 掉落物品自动堆叠
local auto_stack = true

if IsServer and auto_stack then
    local function AnimPut(item, target)
        if target and target ~= item and target.prefab == item.prefab and item.components.stackable and not item.components.stackable:IsFull() and target.components.stackable and not target.components.stackable:IsFull() then
            local start_fx = SpawnPrefab("small_puff")
            start_fx.Transform:SetPosition(target.Transform:GetWorldPosition())
            start_fx.Transform:SetScale(.5, .5, .5)

            item.components.stackable:Put(target)
        end
    end

    local function CanStackInst(inst)
        return inst:IsValid() and inst.components.stackable and not inst.components.stackable:IsFull() and
                inst.components.health == nil and inst.components.mine == nil and -- 带血量的（小动物）和陷阱（有的人会装那类 mod）不堆叠
                inst.prefab ~= "fireflies" -- 萤火虫不参与堆叠

    end

    local function DoPut(inst, pt) -- 指定任意一个实体，堆叠附近所有可以堆叠的东西，不止会堆叠新的掉落
        if not (inst and inst:IsValid()) and pt == nil then
            return
        end

        local pos = pt or inst:GetPosition()
        local x, y, z = pos:Get()
        local ents = TheSim:FindEntities(x, y, z, SEE_ITEM_STACK_DIST, { "_inventoryitem" }, { "INLIMBO", "NOCLICK", "catchable", "fire" })
        for _, objBase in pairs(ents) do
            if CanStackInst(objBase) then
                for _, obj in pairs(ents) do
                    if obj:IsValid() then
                        AnimPut(objBase, obj)
                    end
                end
            end
        end
    end

    local function ToPut(inst, time, pt)
        inst:DoTaskInTime(time, DoPut, pt)
    end

    local LootDropper = GLOBAL.require("components/lootdropper")
    local old_FlingItem = LootDropper.FlingItem
    -- 掉落物品自动堆叠
    function LootDropper:FlingItem(loot, pt, bouncedcb)
        if loot ~= nil and loot:IsValid() then
            if self.inst:IsValid() or pt ~= nil then
                old_FlingItem(self, loot, pt, bouncedcb)

                ToPut(loot, 0.5)
            end
        end
    end

    local Beard = GLOBAL.require("components/beard")
    -- 刮胡子自动堆叠
    function Beard:Shave(who, withwhat)
        if self.bits == 0 then
            return false, "NOBITS"
        elseif self.canshavetest ~= nil then
            local pass, reason = self.canshavetest(self.inst)
            if not pass then
                return false, reason
            end
        end

        if self.prize ~= nil then
            for k = 1 , self.bits do
                local bit = SpawnPrefab(self.prize)
                local x, y, z = self.inst.Transform:GetWorldPosition()
                bit.Transform:SetPosition(x, y + 2, z)
                local speed = 1 + math.random()
                local angle = math.random() * 2 * PI
                bit.Physics:SetVel(speed * math.cos(angle), 2 + math.random() * 3, speed * math.sin(angle))

                ToPut(bit, 0.5)
            end
            self:Reset()
        end

        if who == self.inst and who.components.sanity ~= nil then
            who.components.sanity:DoDelta(TUNING.SANITY_SMALL)
        end

        self.inst:PushEvent("shaved")

        return true
    end

    local Terraformer = GLOBAL.require("components/terraformer")
    local old_Terraform = Terraformer.Terraform
    -- 铲地皮自动堆叠
    function Terraformer:Terraform(pt, ...)
        ToPut(GLOBAL.TheWorld, 0.5, pt)

        return old_Terraform(self, pt, ...)
    end

    -- 猪王给予物品自动堆叠
    AddPrefabPostInit("pigking", function(inst)
        local old_onaccept = inst.components.trader.onaccept
        inst.components.trader.onaccept = function(inst, giver, item)
            if old_onaccept ~= nil then
                old_onaccept(inst, giver, item)
            end

            ToPut(inst, 2)
        end
    end)

    -- 蚁狮给予物品自动堆叠
    AddPrefabPostInit("antlion", function(inst)
        local old_onaccept = inst.components.trader.onaccept
        inst.components.trader.onaccept = function(inst, giver, item)
            if old_onaccept ~= nil then
                old_onaccept(inst, giver, item)
            end

            ToPut(inst, 3)
        end
    end)

    -- 疯猪的屎自动堆叠
    local function OnEat(inst, food)
        if food.components.edible ~= nil then
            if food.components.edible.foodtype == FOODTYPE.VEGGIE then
                local poop = SpawnPrefab("poop")
                poop.Transform:SetPosition(inst.Transform:GetWorldPosition())
                ToPut(poop, 0.1)
            elseif food.components.edible.foodtype == FOODTYPE.MEAT and inst.components.werebeast ~= nil and not inst.components.werebeast:IsInWereState() and food.components.edible:GetHealth(inst) < 0 then
                inst.components.werebeast:TriggerDelta(1)
            end
        end
    end

    AddPrefabPostInit("pigman", function(inst)
        inst.components.eater:SetOnEatFn(OnEat)
    end)

    AddPrefabPostInit("pigguard", function(inst)
        inst.components.eater:SetOnEatFn(OnEat)
    end)

    AddPrefabPostInit("rock_avocado_fruit", function(inst)
        local old_onwork = inst.components.workable.onwork
        inst.components.workable:SetOnWorkCallback(function(...)
            local ret = old_onwork and old_onwork(...)
            ToPut(inst, 0.5)
            return ret
        end)
    end)
end