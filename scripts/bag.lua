
local san1 = 0
local san2 = 0.2
local ice1 = 0
local ice2 = 4
local food1 = 1
local food2 = -0.05
local function upgrade(inst)
	inst.grlevel = math.min(math.floor(inst.grnum/10),inst.maxlevel*6)
	inst.sanlevel = math.min(math.floor(inst.sannum/10),inst.maxlevel*2)
	inst.bxlevel = math.min(math.floor(inst.bxnum/10),inst.maxlevel*4)
	--隔热
	inst.components.insulator:SetInsulation(ice1 + ice2*inst.grlevel)
	--回脑
	inst.components.equippable.dapperness = (san1 + inst.sanlevel*san2)/54
    --保鲜
    inst.components.preserver:SetPerishRateMultiplier(food1 + food2 * inst.bxlevel)

end

local function OnRefuseItem(inst, giver, item)
	if item then
	local refusesay = "坎普斯背包\n"
			refusesay = refusesay.."冰数量:"..inst.grnum.."/"..inst.maxlevel*60 .."\tLV:"..inst.grlevel .."\n隔热："..(ice1 + ice2*inst.grlevel).."\n\n"
			refusesay = refusesay.."蜂蜜数量:"..inst.sannum.."/"..inst.maxlevel*20 .."\tLV:"..inst.sanlevel.."\n回脑："..(san1+san2*inst.sanlevel).."\n\n"
			refusesay = refusesay.."金子数量:"..inst.bxnum.."/"..inst.maxlevel*40 .."\tLV:"..inst.bxlevel.."\n保鲜："..(food1+food2*inst.bxlevel).."\n\n"
		giver.components.talker:Say(refusesay)
	end
end

local function AcceptTest(inst, item)
	if (item.prefab == "ice" ) then
		return 	inst.grnum < inst.maxlevel *60,"GENERIC"
	elseif (item.prefab == "honey") then
		return 	inst.sannum < inst.maxlevel *20,"GENERIC"
	elseif (item.prefab == "goldnugget") then
		return 	inst.bxnum < inst.maxlevel *40,"GENERIC"
	end
	return false,"WRONGTYPE" 
end
local function TraderCount(inst,giver,item)
	if item.prefab == "ice"  then
		return 	inst.maxlevel *60 - inst.grnum
	elseif item.prefab == "honey" then
		return  inst.maxlevel *20 - inst.sannum
	elseif item.prefab == "goldnugget" then
		return  inst.maxlevel *40 - inst.bxnum
	end
	return 1
end
local function OnGetItemFromPlayer(inst, giver, item)
	local num = 1
	if item.components.stackable then
		num = item.components.stackable.stacksize
	end
	if (item.prefab == "ice")then
		inst.grnum = inst.grnum + num
		inst.grlevel = math.min(math.floor(inst.grnum / 10),inst.maxlevel*6)
		if inst.grlevel < inst.maxlevel*6 then 
			giver.components.talker:Say("冰数量:"..inst.grnum.."/"..inst.maxlevel*60 .."\tLV:"..inst.grlevel .."\n隔热："..(ice1 + ice2*inst.grlevel))
			else
			giver.components.talker:Say("冰已满\tLV:60\n隔热："..(ice1 + ice2*inst.grlevel))
		end
		
	elseif (item.prefab == "honey") 
		then
		inst.sannum = inst.sannum + num
		inst.sanlevel = math.min(math.floor(inst.sannum/10),inst.maxlevel*2)
		if inst.sanlevel < inst.maxlevel*2 then 
			giver.components.talker:Say("蜂蜜数量:"..inst.sannum.."/"..inst.maxlevel*20 .."\tLV:"..inst.sanlevel.."\n回脑："..(san1+san2*inst.sanlevel))
			else
			giver.components.talker:Say("蜂蜜已满\tLV:20\n回脑："..(san1+san2*inst.sanlevel))
		end
	elseif (item.prefab == "goldnugget") 
		then
		inst.bxnum = inst.bxnum + num
		inst.bxlevel = math.min(math.floor(inst.bxnum /10),inst.maxlevel*4)
		if inst.bxlevel < inst.maxlevel*5 then 
			giver.components.talker:Say("金子数量:"..inst.bxnum.."/"..inst.maxlevel*40 .."\tLV:"..inst.bxlevel.."\n保鲜："..(food1+food2*inst.bxlevel))
			else
			giver.components.talker:Say("金子已满\tLV:50\n保鲜："..(food1+food2*inst.bxlevel).."")
		end
	end
	upgrade(inst)
end

local function onpreload(inst, data)
	if data then
		inst.grnum = data.grnum or 0
		inst.sannum = data.sannum or 0
		inst.bxnum = data.bxnum or 0
		upgrade(inst)
	end
end

local function onsave(inst, data)
	data.grnum = inst.grnum
	data.sannum = inst.sannum
	data.bxnum = inst.bxnum
end

AddPrefabPostInit("krampus_sack", function(inst)
	inst.maxlevel = 10
	inst.grnum = 0
	inst.sannum = 0
	inst.bxnum = 0
	inst.grlevel = 0
	inst.sanlevel = 0
	inst.bxlevel = 0
	
	inst.components.inspectable:SetDescription([[
		这是一个可以升级的背包
		可以通过冰块升级隔热
		可以通过蜂蜜升级回脑
		可以通过金块升级保鲜
		]])

	inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(food1)
	
	inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(ice1)
	inst.components.insulator:SetSummer()

	inst:AddComponent("trader")
	inst.cantrader = TraderCount
	inst.components.trader:SetAcceptTest(AcceptTest)
	inst.components.trader.onaccept = OnGetItemFromPlayer
	inst.components.trader.onrefuse = OnRefuseItem

	oldOnSave = inst.OnSave
	inst.OnSave = function(inst, data)
		if oldOnSave ~= nil then
			oldOnSave(inst, data)
		end
		onsave(inst, data)
	end

	oldPreLoad = inst.OnPreLoad
	inst.OnPreLoad = function(inst, data)
		if oldPreLoad ~= nil then
			oldPreLoad(inst, data)
		end
		onpreload(inst, data)
	end
end)
