local Zg_mobbig = Class(function(self, inst)
	self.inst = inst
	
	----------------------------------------------------------
	self.i_size = nil	--体积
	self.t_size = nil	
	
	self.i_damage = nil		--攻击力
	self.t_damage = nil
	
	self.i_attackrange = nil		--开始攻击距离
	self.t_attackrange = nil
	
	self.i_hitrange = nil		--真实攻击距离
	self.t_hitrange = nil
	
	self.i_health = nil		--生命值
	self.t_health = nil
	
	self.currenthealth = nil  	--当前生命值
	
	self.i_mass = nil		--质量
	self.t_mass = nil
	
	self.i_radius = nil		--碰撞体半径
	self.t_radius = nil
	
	self.loot = nil 		--掉落物 的 增倍数
	--------------------------------------------------------
	self.switch = false 
	self.canchange = true

end)

--------------------------------------------------计算目标状态---------------------------------------------------------------------------------
----------------------------也是入口函数
function Zg_mobbig:DoCalc()

	if self.canchange then
		
			--获取并保存原来的数据
			self.i_size = self.inst.Transform:GetScale()
			self.i_damage = self.inst.components.combat.defaultdamage
			self.i_attackrange = self.inst.components.combat.attackrange
			self.i_hitrange = self.inst.components.combat.hitrange
			self.i_health = self.inst.components.health.maxhealth
			self.i_mass =  self.inst.Physics:GetMass()
			self.i_radius =  self.inst.Physics:GetRadius()
			
			
			--定义乘数因子
			local vol_scale
			local damage_scale
			local range_scale
			local health_scale
			local mass_scale
			local radius_scale
			
			local loot_scale
			
			local bigrandom = 0
			if self.switch then
				bigrandom = math.random()
			end
			if bigrandom < .2 then
				vol_scale = 1
				loot_scale = 1
			elseif bigrandom < .4 then
				vol_scale = 1.125
				loot_scale = 1
			elseif bigrandom < .6 then
				vol_scale = 1.25
				loot_scale = 2
			elseif bigrandom < .8 then
				vol_scale = 1.375
				loot_scale = 2
			else
				vol_scale = 1.5
				loot_scale = 3
			end
			
			range_scale = 1 + (vol_scale - 1) * .5
			health_scale = 1 + (vol_scale - 1) * 3
			damage_scale = 1 + (vol_scale - 1) * 3
			mass_scale = vol_scale * vol_scale * vol_scale
			radius_scale = 1 + (vol_scale - 1) * .75
			
			--计算出目标数据
			self.t_size = self.i_size * vol_scale
			self.t_damage = self.i_damage * damage_scale
			self.t_attackrange = self.i_attackrange * range_scale
			self.t_hitrange = self.i_hitrange * range_scale
			self.t_health = self.i_health * health_scale
			
			--初始化的时候怪物满血,当前值在入口函数时设置好,以后就交给health组件处理就不用管了
			self.currenthealth = 1
			
			self.t_mass = self.i_mass * mass_scale
			self.t_radius = self.i_radius * radius_scale
			self.loot = loot_scale - 1
			
			----开关关闭
			self.canchange = false
			
			--执行数据
			self:DoKeep()
			
		--end)
	end
end

--------------------------------------------------载入状态-------------------------------------
function Zg_mobbig:DoKeep()
		self.inst.Transform:SetScale(self.t_size, self.t_size, self.t_size)
		self.inst.components.combat.defaultdamage = self.t_damage
		self.inst.components.combat.attackrange = self.t_attackrange
		self.inst.components.combat.hitrange = self.t_hitrange
		self.inst.components.health.maxhealth = self.t_health
		self.inst.components.health:SetPercent(self.currenthealth or 1)
end
--------------------------------------------------状态的保存和载入-----------------------------
function Zg_mobbig:OnSave()
    return
    {
		--开关保存
		canchange = self.canchange,
		
		--状态保存
		i_size = self.i_size,
		t_size = self.t_size,

		i_damage = self.i_damage,
		t_damage = self.t_damage,

		i_attackrange = self.i_attackrange,
		t_attackrange = self.t_attackrange,

		i_hitrange = self.i_hitrange,
		t_hitrange = self.t_hitrange,
		
		i_health = self.i_health,
		t_health = self.t_health,
		
		currenthealth = self.inst.components.health:GetPercent(),		
		
		loot = self.loot,
    }
end
function Zg_mobbig:OnLoad(data)
    if data ~= nil then
		
		----对于改变过的, 才执行 保持操作
		if not self.canchange then
		
			--开关载入
			self.canchange = data.canchange
			
			--状态载入
			if data.i_size ~= nil then
				self.i_size = data.i_size
			end
			if data.t_size ~= nil then
				self.t_size = data.t_size
			end
			
			if data.i_health ~= nil then
				self.i_health = data.i_health
			end
			if data.t_health ~= nil then
				self.t_health = data.t_health
			end
			
			if data.i_damage ~= nil then
				self.i_damage = data.i_damage
			end
			if data.t_damage ~= nil then
				self.t_damage = data.t_damage
			end
			
			if data.i_attackrange ~= nil then
				self.i_attackrange = data.i_attackrange
			end
			if data.t_attackrange ~= nil then
				self.t_attackrange = data.t_attackrange
			end
			
			if data.i_hitrange ~= nil then
				self.i_hitrange = data.i_hitrange
			end
			if data.t_hitrange ~= nil then
				self.t_hitrange = data.t_hitrange
			end
			
			if data.i_health ~= nil then
				self.i_health = data.i_health
			end
			if data.t_health ~= nil then
				self.t_health = data.t_health
			end
			
			if data.currenthealth ~= nil then
				self.currenthealth = data.currenthealth
			end
			
			if data.loot ~= nil then
				self.loot = data.loot
			end
		
			self:DoKeep()
		end
		
    end
end
-----------------------------------------------------------------------------------------------

return Zg_mobbig