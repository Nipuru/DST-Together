
-- 为所有背包物品加上可交易标签
AddPrefabPostInitAny(
	function(inst) 
		if inst and inst.components.inventoryitem and not inst.components.tradable then 
			inst:AddComponent("tradable") 
		end 
	end
)
--坎普斯背包升级
local function krampus_sack_level(inst)
	local san1 = 0		--基础回SAN
	local san2 = 0.3	--升级回SAN
	local ice1 = 0		--基础隔热
	local ice2 = 4		--升级隔热
	local food1 = 0		--基础反鲜
	local food2 = 0.1	--升级反鲜

	local function upgrade(inst)
		inst.grlevel = math.min(math.floor(inst.grnum / inst.need/10),inst.maxlevel*6)
		inst.sanlevel = math.min(math.floor(inst.sannum / inst.need/10),inst.maxlevel*2)
		inst.bxlevel = math.min(math.floor(inst.bxnum / inst.need/10),inst.maxlevel*5)
		--隔热
		inst.components.insulator:SetInsulation(ice1 + ice2*inst.grlevel)
		--回脑
		inst.components.equippable.dapperness = (san1 + inst.sanlevel*san2)/60
	end

	local function AcceptTest(inst, item)
		if (item.prefab == "ice" ) then
			return 	inst.grnum < inst.need * inst.maxlevel *60,"GENERIC"
		elseif (item.prefab == "honey") then
			return 	inst.sannum < inst.need * inst.maxlevel *20,"GENERIC"
		elseif (item.prefab == "goldnugget") then
			return 	inst.bxnum < inst.need * inst.maxlevel *50,"GENERIC"
		end
		return false,"WRONGTYPE" 
	end

	local function OnGetItemFromPlayer(inst, giver, item)
		local num = 1
		if item.components.stackable then
			num = item.components.stackable.stacksize
		end
		if (item.prefab == "ice")then
			inst.grnum = inst.grnum + num
			inst.grlevel = math.min(math.floor(inst.grnum / inst.need/10),inst.maxlevel*6)
			if inst.grlevel < inst.maxlevel*6 then 
				giver.components.talker:Say("冰数量:"..inst.grnum.."/"..inst.need * inst.maxlevel*60 .."\tLV:"..inst.grlevel .."\n隔热："..(ice1 + ice2*inst.grlevel))
				else
				giver.components.talker:Say("冰已满\tLV:60\n隔热："..(ice1 + ice2*inst.grlevel))
			end
		elseif (item.prefab == "honey") 
			then
			inst.sannum = inst.sannum + num
			inst.sanlevel = math.min(math.floor(inst.sannum / inst.need/10),inst.maxlevel*2)
			if inst.sanlevel < inst.maxlevel*2 then 
				giver.components.talker:Say("蜂蜜数量:"..inst.sannum.."/"..inst.need * inst.maxlevel*20 .."\tLV:"..inst.sanlevel.."\n回脑："..(san1+san2*inst.sanlevel))
				else
				giver.components.talker:Say("蜂蜜已满\tLV:20\n回脑："..(san1+san2*inst.sanlevel))
			end
		elseif (item.prefab == "goldnugget") 
			then
			inst.bxnum = inst.bxnum + num
			inst.bxlevel = math.min(math.floor(inst.bxnum / inst.need/10),inst.maxlevel*5)
			if inst.bxlevel < inst.maxlevel*5 then 
				giver.components.talker:Say("金子数量:"..inst.bxnum.."/"..inst.need * inst.maxlevel*50 .."\tLV:"..inst.bxlevel.."\n保鲜："..((food1+food2*inst.bxlevel)*100).."%")
				else
				giver.components.talker:Say("金子已满\tLV:50\n保鲜："..((food1+food2*inst.bxlevel)*100).."%")
			end
		end
		upgrade(inst)
	end

	local function OnRefuseItem(inst, giver, item)
		if item then
			local refusesay = "坎普斯背包\n物\t数\t级\t属"
				refusesay = refusesay..string.format("\n冷(冰):\t%d/"..inst.need * inst.maxlevel*60 .."\t%d\t%d",inst.grnum,inst.grlevel,ice1 + ice2*inst.grlevel)
				refusesay = refusesay..string.format("\n智(蜜):\t%d/"..inst.need * inst.maxlevel*20 .."\t%d\t%d",inst.sannum,inst.sanlevel,san1 + inst.sanlevel*san2)
				refusesay = refusesay..string.format("\n保(金):\t%d/"..inst.need * inst.maxlevel*50 .."\t%d\t%d",inst.bxnum,inst.bxlevel*5,(food1*100+food2*inst.bxlevel*100)).."%"
			giver.components.talker:Say(refusesay)
		end
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

	local function onrefresh(inst)
		--背包反鲜
		if inst.components.container then
			for i,j in pairs(inst.components.container.slots) do
				if j and j.components.perishable then
					local oldval = j.components.perishable.perishremainingtime
					j.components.perishable.perishremainingtime = math.min(oldval +food1*10+10*food2*inst.bxlevel,j.components.perishable.perishtime)
				end
			end
		end
	end

	inst:AddTag("trader")
	inst:AddTag("nocool")
	inst.need = 1
	inst.maxlevel = 10
	inst.grnum = 0
	inst.sannum = 0
	inst.bxnum = 0
	inst.grlevel = 0
	inst.sanlevel = 0
	inst.bxlevel = 0
	inst:AddComponent("trader")
	inst.components.trader:SetAcceptTest(AcceptTest)
	inst.components.trader.onaccept = OnGetItemFromPlayer
	inst.components.trader.onrefuse = OnRefuseItem
	inst.OnSave = onsave
	inst.OnPreLoad = onpreload
	--隔热
	inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(ice1)
	inst.components.insulator:SetSummer()
	--返鲜
	inst:DoPeriodicTask(10,onrefresh)
	--回脑残
	inst.components.equippable.dapperness = (san1 + inst.sanlevel*san2) /60
end
AddPrefabPostInit("krampus_sack", krampus_sack_level)

--步行手杖升级
local function cane_level(inst)
	local movingspeed1 = GLOBAL.TUNING.CANE_SPEED_MULT	--基础移动速度
	local movingspeed2 = 0.01							--升级移动速度
	local pickspeed1 = 0								--基础采集速度
	local pickspeed2 = 1								--升级采集速度
	local builderspeed1 = 0								--基础建造速度
	local builderspeed2 = 1								--升级建造速度

	local function addtag(inst)
		local owner = inst.components.inventoryitem.owner
		if owner and inst.components.equippable:IsEquipped() then
			if pickspeed1 + pickspeed2*inst.pslevel == 1 then
				owner:AddTag("quagmire_fasthands")
			elseif pickspeed1 + pickspeed2*inst.pslevel == 2 then 
				owner:AddTag("fastpicker")
			end
			if builderspeed1 + builderspeed2*inst.zzlevel == 1 then
				owner:AddTag("fastbuilder")
			end
		end
	end
	
	local function removetag(owner)
		if owner:HasTag("quagmire_fasthands") then
			owner:RemoveTag("quagmire_fasthands")
		end
		if owner:HasTag("fastpicker") then
			owner:RemoveTag("fastpicker")
		end
		if owner:HasTag("fastbuilder") then
			owner:RemoveTag("fastbuilder")
		end
	end
	local oldOnequip = inst.components.equippable.onequipfn
	local function onequip(inst, owner)
		oldOnequip(inst, owner)
		addtag(inst)
	end
	local oldOnunequip = inst.components.equippable.onunequipfn
	local function onunequip(inst, owner)
		oldOnunequip(inst, owner)
		removetag(owner)
	end
	local function upgrade(inst)
		inst.mslevel = math.min(math.floor(inst.msnum / inst.need/20),inst.maxlevel*1)
		inst.pslevel = math.min(math.floor(inst.psnum / inst.need/1),inst.maxlevel*0.2)
		inst.zzlevel = math.min(math.floor(inst.zznum / inst.need/5),inst.maxlevel*0.1)
		--移速
		inst.components.equippable.walkspeedmult = movingspeed1 + movingspeed2*inst.mslevel
		addtag(inst)
	end

	local function AcceptTest(inst, item)
		if (item.prefab == "goldnugget" ) then
			return 	inst.msnum < inst.need * inst.maxlevel *20,"GENERIC"
		elseif (item.prefab == "opalpreciousgem") then
			return 	inst.psnum < inst.need * inst.maxlevel *0.2,"GENERIC"
		elseif (item.prefab == "orangegem") then
			return 	inst.zznum < inst.need * inst.maxlevel *0.5,"GENERIC"
		end
		return false,"WRONGTYPE" 
	end
	local function OnGetItemFromPlayer(inst, giver, item)
		local num = 1
		if item.components.stackable then
			num = item.components.stackable.stacksize
		end
		if (item.prefab == "goldnugget") then
			inst.msnum = inst.msnum + num
			inst.mslevel = math.min(math.floor(inst.msnum / inst.need/20),inst.maxlevel*1)
			if inst.mslevel < inst.maxlevel*2 then 
				giver.components.talker:Say("金子数量:"..inst.msnum.."/"..inst.need * inst.maxlevel*20 .."\tLV:"..inst.mslevel .."\n移动速度："..(movingspeed1 + movingspeed2*inst.mslevel))
			else
				giver.components.talker:Say("金子已满\tLV:10\n移动速度："..(movingspeed1 + movingspeed2*inst.mslevel))
			end
		elseif (item.prefab == "opalpreciousgem") then
			inst.psnum = inst.psnum + num
			inst.pslevel = math.min(math.floor(inst.psnum / inst.need/1),inst.maxlevel*0.2)
			if inst.pslevel < inst.maxlevel*0.2 then 
				giver.components.talker:Say("彩虹宝石数量:"..inst.psnum.."/"..inst.need * inst.maxlevel*0.2 .."\tLV:"..inst.pslevel.."\n采集速度："..(pickspeed1 + pickspeed2*inst.pslevel))
			else
				giver.components.talker:Say("彩虹宝石已满\tLV:2\n采集速度："..(pickspeed1 + pickspeed2*inst.pslevel))
			end
		elseif (item.prefab == "orangegem") then
			inst.zznum = inst.zznum + num
			inst.zzlevel = math.min(math.floor(inst.zznum / inst.need/5),inst.maxlevel*0.1)
			if inst.zzlevel < inst.maxlevel*0.1 then 
				giver.components.talker:Say("橙宝石数量:"..inst.zznum.."/"..inst.need * inst.maxlevel*0.5 .."\tLV:"..inst.zzlevel.."\n制作速度："..(builderspeed1 + builderspeed2*inst.zzlevel))
			else
				giver.components.talker:Say("橙宝石已满\tLV:1\n制作速度："..(builderspeed1 + builderspeed2*inst.zzlevel))
			end
		end
		upgrade(inst)
	end
	local function OnRefuseItem(inst, giver, item)
		if item then
			local refusesay = "步行手杖\n物\t数\t级\t属"
				refusesay = refusesay..string.format("\n移速(金):\t%d/"..inst.need * inst.maxlevel*20 .."\t%d\t%.2f",inst.msnum,inst.mslevel,movingspeed1 + movingspeed2*inst.mslevel)
				refusesay = refusesay..string.format("\n采速(彩):\t%d/"..inst.need * inst.maxlevel*0.2 .."\t%d\t%d",inst.psnum,inst.pslevel,pickspeed1 + pickspeed2*inst.pslevel)
				refusesay = refusesay..string.format("\n制速(橙):\t%d/"..inst.need * inst.maxlevel*0.5 .."\t%d\t%d",inst.zznum,inst.zzlevel,builderspeed1 + builderspeed2*inst.zzlevel)
			giver.components.talker:Say(refusesay)
		end
	end

	local function onpreload(inst, data)
		if data then
			inst.msnum = data.msnum or 0
			inst.psnum = data.psnum or 0
			inst.zznum = data.zznum or 0
			upgrade(inst)
		end
	end

	local function onsave(inst, data)
		data.msnum = inst.msnum
		data.psnum = inst.psnum
		data.zznum = inst.zznum
	end

	inst:AddTag("trader")
	inst.need = 1
	inst.maxlevel = 10
	inst.msnum = 0
	inst.psnum = 0
	inst.zznum = 0
	inst.mslevel = 0
	inst.pslevel = 0
	inst.zzlevel = 0

	inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
	inst:AddComponent("trader")
	inst.components.trader:SetAcceptTest(AcceptTest)
	inst.components.trader.onaccept = OnGetItemFromPlayer
	inst.components.trader.onrefuse = OnRefuseItem
	inst.OnSave = onsave
	inst.OnPreLoad = onpreload
end
AddPrefabPostInit("cane", cane_level)