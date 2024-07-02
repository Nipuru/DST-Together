local _G = GLOBAL
local TheNet = _G.TheNet
local TUNING = _G.TUNING

-- 怪物变大机制
local tobigtable = {
	--被动生物
	"crow","robin","robin_winter","rabbit","perd",
	--中立生物
	"beefalo", "koalefant_summer","koalefant_winter","catcoon","buzzard","penguin","lightninggoat","monkey","pigman","bunnyman",
	--普通敌对生物
	"merm","pigguard","tallbird","walrus","mosquito","krampus","crawlinghorror","terrorbeak","frog",
	"spider_hider","spider","spider_spitter","spider_warrior",

    "deerclops",        --雪巨鹿
    "bearger",          --比尔熊
    "dragonfly",        --龙蜻蜓
    "moose",            --鹿角鹅
}
for k,v in pairs(tobigtable) do
	AddPrefabPostInit(v, function(inst)
		if _G.TheWorld.ismastersim then
			inst:AddComponent("zg_mobbig")		--怪物变大
			if _G.TheWorld.state.cycles >= 99 then
				inst.components.zg_mobbig.switch = true
			end
			inst.components.zg_mobbig:DoCalc()	--入口函数
			----掉落物机制
			function inst.components.lootdropper:DropLoot(pt)
				local prefabs = self:GenerateLoot()
				if not self.inst.components.fueled and self.inst.components.burnable and self.inst.components.burnable:IsBurning() then
					for k,v in pairs(prefabs) do
						local cookedAfter = v.."_cooked"
						local cookedBefore = "cooked"..v
						if _G.PrefabExists(cookedAfter) then
							prefabs[k] = cookedAfter
						elseif _G.PrefabExists(cookedBefore) then
							prefabs[k] = cookedBefore 
						else             
							prefabs[k] = "ash"               
						end
					end
				end
				for k,v in pairs(prefabs) do
					self:SpawnLootPrefab(v, pt)
					----多余的掉落物
					if inst.components.zg_mobbig and inst.components.zg_mobbig.loot and inst.components.zg_mobbig.loot >= 1 then
						for k = 1, inst.components.zg_mobbig.loot do
							self:SpawnLootPrefab(v, pt)
						end
					end
				end
            end
		end
	end)
end
local function BigMobWarning(inst)
	inst:WatchWorldState("cycleschanged",function(inst)
		local day = 100 - (_G.TheWorld.state.cycles + 1)
		if day > 0 then
			TheNet:Announce("巨型化剩余："..day.." 天")
		elseif day == 0 then
			TheNet:Announce("巨型化已开启！！！！")
		end
	end,_G.TheWorld)
end
AddPrefabPostInit("world", BigMobWarning)
--变身疯猪
local function zg_were_fn(inst)
	----大体积因子
	local zg_big_num = inst.components.zg_mobbig and inst.components.zg_mobbig.t_size or 1
	local zg_atk_mult = 1 + (zg_big_num - 1) * 3
	local zg_health_mult = 1 + (zg_big_num - 1) * 3
	
	----攻击翻倍
    inst.components.combat:SetDefaultDamage(TUNING.WEREPIG_DAMAGE * zg_atk_mult)
	----血量翻倍
    inst.components.health:SetMaxHealth(TUNING.WEREPIG_HEALTH * zg_health_mult)
	
end

--普通猪人恢复原貌
local function zg_normal_fn(inst)
	----大体积因子
	local zg_big_num = inst.components.zg_mobbig and inst.components.zg_mobbig.t_size or 1
	local zg_atk_mult = 1 + (zg_big_num - 1) * 3
	local zg_health_mult = 1 + (zg_big_num - 1) * 3
	
	----攻击翻倍
    inst.components.combat:SetDefaultDamage(TUNING.PIG_DAMAGE * zg_atk_mult)
	----血量翻倍
    inst.components.health:SetMaxHealth(TUNING.PIG_HEALTH * zg_health_mult)
	
end

--守卫猪人恢复原貌
local function zg_guard_fn(inst)
	----大体积因子
	local zg_big_num = inst.components.zg_mobbig and inst.components.zg_mobbig.t_size or 1
	local zg_atk_mult = 1 + (zg_big_num - 1) * 3
	local zg_health_mult = 1 + (zg_big_num - 1) * 3
	
	----攻击翻倍
    inst.components.combat:SetDefaultDamage(TUNING.PIG_GUARD_DAMAGE * zg_atk_mult)
	----血量翻倍
    inst.components.health:SetMaxHealth(TUNING.PIG_GUARD_HEALTH * zg_health_mult)
	
end

--普通猪人
local function pigmanfn(inst)
	if inst and _G.TheWorld.ismastersim then
		----变身之后属性也是随体积翻倍
		inst:ListenForEvent("transformwere", zg_were_fn)
		----变身恢复后恢复正确的属性
		inst:ListenForEvent("transformnormal", zg_normal_fn)
	end
end
AddPrefabPostInit("pigman", pigmanfn)

--猪人守卫
local function pigguardfn(inst)
	if inst and _G.TheWorld.ismastersim then
		----变身之后属性也是随体积翻倍
		inst:ListenForEvent("transformwere", zg_were_fn)
		----变身恢复后恢复正确的属性
		inst:ListenForEvent("transformnormal", zg_guard_fn)
	end
end
AddPrefabPostInit("pigguard", pigguardfn)