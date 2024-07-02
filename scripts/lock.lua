local _G = GLOBAL
local TheNet = _G.TheNet
local TheSim = _G.TheSim
local GetTaskRemaining = _G.GetTaskRemaining

local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

-- 保存权限的物品
local permission_prefabs = {}
local AllPlayersForKeyUserID = {}
--保存所有玩家的集合
local AllPlayers = {}
--保存当前获取到的玩家列表_非player集合
local AllClientPlayers = {}
--保存离开玩家的集合
local LeavedPlayers = {}

-- 牛的控制指令
local MSG_CHOOSE = {
    ["#帮助"] = 0,
	["#help"] = 0,
    ["#switch"] = 1,
    ["#特殊"] = 2,
}

local config_item = {
    --要记录状态的物品
    save_state_table = {
        "storeroom",
        "plant_normal",
        "twiggytree",
        "deciduoustree",
        "evergreen",
        "stafflight",
        "staffcoldlight",
        "eyeturret"
    },
    --防挖/摧毁的安置物
    deploys_cant_table = {
        grass = true, --草丛
        sapling = true, --树苗
        berrybush = true, --浆果丛
        berrybush2 = true, --分叉浆果丛
        berrybush_juicy = true, --多汁浆果丛
        flower = true, --花
        fossil_stalker = true, --奇怪的骨骼
        pinecone_sapling = true, --榛果_种下
        acorn_sapling = true, --白桦果_种下
        twiggy_nut_sapling = true, --多枝树果_种下
        marblebean_sapling = true --大理石豆子_种下
    },
    --防摧毁的树
    winter_trees_table = {
        winter_tree = true, --圣诞松树
        winter_deciduoustree = true, --圣诞桦树
        winter_twiggytree = true, --圣诞多枝分叉树
        marbleshrub = true --大理石树
    }
}

if IsServer then
    local gd_strings = {
        help_tips = function(opts)
            return string.format("欢迎来到󰀒『饥友们一起玩』长期无尽档󰀒\n\n============服务器帮助============\n\n【#add】给予某个玩家权限\n【#del】收回某个玩家权限\n【#delall】收回全部权限\n【#switch】新建筑权限保护开关\n\n【#查询】查询世界部分生物信息\n【#特殊】查询服务器特殊物品信息(可升级等)\n\n！！打开聊天栏输入#help，可显示此帮助菜单！！")
        end,
        permission_give = function(opts)
            return string.format("我已经把权限给了（%s）！", opts[1])
        end,
        permission_give_me = function(opts)
            return string.format("可惜，不能给自己权限！")
        end,
        permission_give_num_err = function(opts)
            return string.format("没有玩家是这个数字，请重新给权限吧！")
        end,
        permission_remove = function(opts)
            return string.format("已经收回了给（%s）的权限！", opts[1])
        end,
        permission_remove_no = function(opts)
            return string.format("（%s）没有我的权限，不能收回哦！", opts[1])
        end,
        permission_remove_me = function(opts)
            return string.format("不能收回自己的权限哦！")
        end,
        permission_remove_num_err = function(opts)
            return string.format("没有玩家是这个数字，请重新收回权限吧！")
        end,
        permission_get = function(opts)
            return string.format("我获得了（%s）的权限！", opts[1])
        end,
        permission_lose = function(opts)
            return string.format("（%s）给的权限已被收回！", opts[1])
        end,
        permission_del_tip = function(opts)
            return string.format("按U输入#del 玩家数字，我还可以回收权限哦！")
        end,
        permission_hua_no = function(opts)
            return string.format("这是（%s）的私密小屋，我需要权限！", opts[1])
        end,
        hua_enter = function(opts)
            return string.format("（%s）要进入我的%s！\n按U输入#add %s 可以给权限", opts[1], opts[2], opts[3])
        end,
        player_leaved = function(opts)
            return string.format("东西的主人%s已经离开了这个世界！", opts[1] ~= nil and "（" .. opts[1] .. "）" or "")
        end,
        command_error = function(opts)
            return string.format("命令输入错误，请重新输入吧！")
        end,
        command_help = function(opts)
            return string.format(
                "命令格式：\n给权限命令：#add  数字\n收权限命令：#del  数字\n受所有权限命令：#delall\n按Tab键在玩家列表左边可以查看对应的玩家数字\n建议有玩家进出时不要收给权限"
            )
        end,
        item_master_to = function(opts)
            return string.format("所有者： %s", opts[1])
        end,
    }
    
    local function GetSayMsg(key, ...)
        local fn = gd_strings[key]
        if fn == nil then
            return ""
        end
    
        return fn({...})
    end
    -- 检查物品是否有进行保存和加载权限
    local function IsPermission(inst)
        if type(inst) == "string" then
            return permission_prefabs[inst]
        else
            return permission_prefabs[inst.prefab]
        end
    end

    -- 说话
    local function PlayerSay(player, msg, delay, duration, noanim, force, nobroadcast, colour)
        if player ~= nil and player.components.talker then
            player:DoTaskInTime(
                delay or 0.01,
                function()
                    player.components.talker:Say(msg, duration or 2.5, noanim, force, nobroadcast, colour)
                end
            )
        end
    end

    -- 将坐标点对象拆分成x y z返回
    local function GetSplitPosition(pos)
        return pos.x, pos.y, pos.z
    end

    -- 检查是否为朋友
    local function CheckFriend(masterId, guestId)
        if masterId == nil or guestId == nil then
            return false
        end
        return _G.TheWorld.guard_authorization ~= nil and _G.TheWorld.guard_authorization[masterId] ~= nil and
            _G.TheWorld.guard_authorization[masterId].friends and
            _G.TheWorld.guard_authorization[masterId].friends[guestId]
    end

    -- 通过ownerlist来获取玩家名字
    local function GetPlayerNameByOwnerlist(ownerlist)
        return ownerlist and ownerlist.master and _G.TheWorld.guard_authorization[ownerlist.master] and _G.TheWorld.guard_authorization[ownerlist.master].name
    end

    local function DataTimerFn(seconds)
        local total = math.abs(seconds)
        local days =  math.floor(total / 86400) --1/86400 
        local hours = math.floor(total % 86400 / 3600) --1/3600
        local mins = math.floor(total % 3600 / 60) --1/60
        return 
            (days > 0 and (days .. '天'.. hours .. '小时' .. mins .."分") or (hours > 0 and (hours .. '小时'.. mins .."分") or (mins .."分")))
    end

    -- 设置所有者名(蘑菇小屋)
    local function SetOwnerName(inst, master)
        if inst ~= nil and inst:IsValid() then 
            if inst.prefab and string.find(inst.prefab, "hua_player_house") then
                if inst.components.named == nil and not inst:HasTag("player") then
                    inst:AddComponent("named")   
                end

                local userid = inst.ownerlist ~= nil and inst.ownerlist.master or master
                if inst.components.named ~= nil then
                    if userid ~= nil then
                        local ownerName = GetPlayerNameByOwnerlist({master = userid})
                        if ownerName ~= nil then
                            if inst.oldName == nil then
                                inst.oldName = inst.name
                            end
                            inst.components.named:SetName(
                                (inst.oldName or inst.name or "") .. "\n" .. GetSayMsg("item_master_to", ownerName)
                            )
                        end
                        inst.GetShowItemInfo = function(inst)
                            local timetoleave = _G.TheWorld.guard_authorization[userid].timetoleave
                            local unlocktime = _G.TheWorld.guard_authorization[userid].unlocktime
                            if timetoleave ~= nil then
                                return "\n 【权限剩余时间："..DataTimerFn(timetoleave).."】"
                            elseif unlocktime == "never" then 
                                return "\n 【权限剩余时间：永久】"
                            else
                                return "\n 【所有者在线】"
                            end
                        end
                    else
                        inst.components.named:SetName(nil)
                        inst.GetShowItemInfo = function(inst)
                            return "\n 【权限已清除】"
                        end
                    end
                end
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
            --薇诺娜的电池有“inst.components.fueled”，为了使条件成立故加入“inst.components.circuitnode”来一起判断
            if inst.components.fueled == nil or inst.components.circuitnode then
                if inst:HasTag("fireimmune") then
                    inst.fireimmune = true
                else
                    inst:AddTag("fireimmune")
                end
            end
        end
    end

    -- 添加可燃烧属性
    local function AddBurnable(inst)
        if inst and inst.gd_lightremoved and inst.components.burnable ~= nil then
            inst.gd_lightremoved = nil
            if inst.canlight then
                inst:AddTag("canlight")
            end
            if not inst.nolight then
                inst:RemoveTag("nolight")
            end
            if not inst.fireimmune then
                inst:RemoveTag("fireimmune")
            end
        end
    end

    -- 设置有权限的物品防烧 2020.02.14
    local function SetItemPermissionDestroy(item, master)
        if item ~= nil and item:IsValid() and not item:HasTag("tree") and not item:HasTag("backpack") then
            local userid = item.ownerlist ~= nil and item.ownerlist.master or master
            if userid ~= nil then
                RemoveBurnable(item)
            else
                AddBurnable(item)
            end
        end
    end

    -----权限保存与加载----
    local function SaveAndLoadChanged(inst)
        permission_prefabs[inst.prefab] = true

        if inst.components.named == nil and not inst:HasTag("player") then
            inst:AddComponent("named")
            inst.oldName = inst.name   
        end

        local OldOnSave = inst.OnSave
        inst.OnSave = function(inst, data)
            if OldOnSave ~= nil then
                OldOnSave(inst, data)
            end
            if inst.ownerlist ~= nil then
                data.ownerlist = inst.ownerlist
            end
            if inst.saved_ownerlist ~= nil then
                data.saved_ownerlist = inst.saved_ownerlist
            end
        end

        local OldOnLoad = inst.OnLoad
        inst.OnLoad = function(inst, data)
            if OldOnLoad ~= nil then
                OldOnLoad(inst, data)
            end
            if data ~= nil then
                if data.ownerlist ~= nil then
                    inst.ownerlist = data.ownerlist
                    SetOwnerName(inst)
                    SetItemPermissionDestroy(inst)
                end

                if data.saved_ownerlist ~= nil then
                    inst.saved_ownerlist = data.saved_ownerlist
                    SetOwnerName(inst, inst.saved_ownerlist.master)
                    SetItemPermissionDestroy(inst, inst.saved_ownerlist.master)
                end
            end
        end
    end

    -- 设置物体权限
    local function SetItemPermission(item, player, forer)
        -- 处理mod物品等
        if not IsPermission(item) and _G.TheWorld.guard_authorization ~= nil and item.prefab ~= nil then
            if _G.TheWorld.guard_authorization.custom_prefabs == nil then
                _G.TheWorld.guard_authorization.custom_prefabs = {}
            end

            _G.TheWorld.guard_authorization.custom_prefabs[item.prefab] = true
            for _, v in pairs(_G.Ents) do
                if v.prefab == item.prefab then
                    SaveAndLoadChanged(v)
                end
            end
        end
        if item.ownerlist == nil then
            item.ownerlist = {}
        else
            item.saved_ownerlist = nil
        end
        if player ~= nil or forer == nil then
            item.ownerlist.master = type(player) == "string" and player or (player ~= nil and player.userid or nil)
            SetOwnerName(item)
            SetItemPermissionDestroy(item) 
        end
        if forer ~= nil then
            item.ownerlist.forer = type(forer) == "string" and forer or forer.userid
        end
    end

    -- 判断权限
    local function CheckPermission(ownerlist, guest, isForer)
        -- 目标没有权限直接返回true
        if ownerlist == nil or ownerlist.master == nil then
            return true
        end
        local guestId = type(guest) == "string" and guest or (guest and guest.userid or nil)
        -- 主人为自己时直接返回true
        if
            guestId and
                (ownerlist.master == guestId or CheckFriend(ownerlist.master, guestId) or
                    (isForer and ownerlist.forer == guestId))
        then
            return true
        end

        return false
    end

    local function tablelength(T)
        local count = 0
        for _ in pairs(T) do
            count = count + 1
        end
        return count
    end

    -- 判断物品权限
    local function CheckItemPermission(player, target, isNoMaster, isForer)
        -- 主机直接返回true
        if _G.TheWorld.ismastersim == false then
            return true
        end
        -- 玩家不存在或目标不存在直接返回true
        if player == nil or target == nil then
            return true
        end
        -- 管理员直接返回true
        if player.Network and player.Network:IsServerAdmin() then
            return true
        end
        if target.ownerlist ~= nil and tablelength(target.ownerlist) > 0 then
            -- 有权限则返回true
            if CheckPermission(target.ownerlist, player, isForer) then
                return true
            end
        else
            return isNoMaster ~= nil and isNoMaster or false
        end

        return false
    end 
    -- 判断物品保存的权限
    local function CheckItemSavedPermission(player, target, isNoMaster, isForer)
        if _G.TheWorld.ismastersim == false then
            return true
        end
        if player == nil or target == nil then
            return true
        end
        -- 管理员直接返回true
        if player.Network and player.Network:IsServerAdmin() then
            return true
        end
        if target.saved_ownerlist ~= nil and tablelength(target.saved_ownerlist) > 0 then
            if CheckPermission(target.saved_ownerlist, player, isForer) then
                return true
            end
        else
            return isNoMaster ~= nil and isNoMaster or false
        end
        return false
    end
    
    --通过id来获取到玩家(当前在线的玩家) 
    local function GetPlayerById(id) 
        if id ~= nil then 
            return AllPlayersForKeyUserID[id]
        end
        return nil
    end

    --获取玩家生存天数
    local function GetAge(player)
        if player and player.components and player.components.age and player:HasTag("player") then
            return player.components.age:GetAgeInDays()
        end
        return 0
    end

    --刷新玩家列表
    local function RefreshPlayers()
        AllPlayers = {}
        AllClientPlayers = {}
        local isStandalone = TheNet:GetServerIsClientHosted()
        local clientObjs = TheNet:GetClientTable()
        if type(clientObjs) == "table" then
            local index = 1
            for i, v in ipairs(clientObjs) do
                if isStandalone or v.performance == nil then
                    AllPlayers[index] = AllPlayersForKeyUserID[v.userid]
                    AllClientPlayers[index] = v
                    index = index + 1
                end
            end
        end
    end


    --通过id获取玩家索引
    local function GetPlayerIndex(userid)
        RefreshPlayers()
        for n,p in pairs(AllPlayers) do
            if userid == p.userid then 
                return n
            end
        end

        return ""
    end

    -- 获取物品原始名称
    local function GetItemOldName(inst)
        return inst.oldName or inst.name
    end

    -- 对物品权限进行保存和加载
    local function SavePermission(inst)
        local prefab = type(inst) == "string" and inst or inst.prefab
        AddPrefabPostInit(
            prefab,
            function(inst)
                SaveAndLoadChanged(inst)
            end
        )
    end

    -- 为所有自定义物品加上权限
    AddPrefabPostInitAny(
        function(inst) 
            if
                _G.TheWorld.guard_authorization ~= nil and _G.TheWorld.guard_authorization.custom_prefabs ~= nil and
                    _G.TheWorld.guard_authorization.custom_prefabs[inst.prefab]
            then
                SaveAndLoadChanged(inst)
            end
        end
    )


    -- 共享网络状态
    AddPrefabPostInit("shard_network", function(inst)
        inst:AddComponent("gd_shard_playerchange")
    end)

    --命令处理 9种情况
    AddPrefabPostInit("world", function(inst)
        inst.guard_authorization = {
            custom_prefabs = {},
        }
        
        local OldOnSave=inst.OnSave
        inst.OnSave = function(inst,data)
            if OldOnSave~=nil then
                OldOnSave(inst,data)
            end
            if inst.guard_authorization ~= nil then
                -- 保存权限失效时间
                for k, v in pairs(LeavedPlayers) do
                    if inst.guard_authorization[k] ~= nil then
                        inst.guard_authorization[k].timetoleave = math.ceil(GetTaskRemaining(v))
                    end
                end

                data.guard_authorization = inst.guard_authorization
            end
        end
        
        local OldOnLoad=inst.OnLoad
        inst.OnLoad = function(inst,data)
            if OldOnLoad~=nil then
                OldOnLoad(inst,data)
            end
            if data.guard_authorization ~= nil then
                inst.guard_authorization = data.guard_authorization

                -- 加载清除权限定时器
                for k, v in pairs(inst.guard_authorization) do
                    if type(v) == "table" and v.timetoleave ~= nil and LeavedPlayers[k] == nil then
                        LeavedPlayers[k] = inst:DoTaskInTime(v.timetoleave, function()
                            LeavedPlayers[k] = nil
                            v.timetoleave = nil
                            local ents = TheSim:FindEntities(0,0,0,1000)
                            for i,v in ipairs(ents) do
                                if v.persists and v.ownerlist and v.ownerlist.master == k and v:IsValid() then
                                    if string.find(inst.prefab, "hua_player_house") then
                                        SetItemPermission(v, nil)
                                    end
                                end
                            end
                        end)
                    end
                end
            end
        end

        --监听玩家进入游戏(join_game)
        inst:ListenForEvent("ms_gd_playerjoined", function (inst, data)
            if data and data.userid then
                if LeavedPlayers[data.userid] ~= nil then
                    LeavedPlayers[data.userid]:Cancel()
                    LeavedPlayers[data.userid] = nil
                    if inst.guard_authorization[data.userid] ~= nil then
                        inst.guard_authorization[data.userid].timetoleave = nil
                    end
                end
            end
        end)

        --监听玩家离开游戏(leave_game)
        inst:ListenForEvent("ms_gd_playerleft", function (inst, data)
            if data and data.userid then
                if inst.guard_authorization[data.userid] ~= nil and LeavedPlayers[data.userid] == nil then
                    local remove_owner_time = inst.guard_authorization[data.userid].unlocktime or 86400
                    if remove_owner_time ~= "never" then
                        LeavedPlayers[data.userid] = inst:DoTaskInTime(remove_owner_time, function()
                            LeavedPlayers[data.userid] = nil
                            inst.guard_authorization[data.userid].timetoleave = nil
                            local ents = TheSim:FindEntities(0,0,0,1000)
                            for i,v in ipairs(ents) do
                                if v.persists and v.ownerlist and v.ownerlist.master == data.userid and v:IsValid() then
                                    if string.find(inst.prefab, "hua_player_house") then
                                        SetItemPermission(v, nil)
                                    end
                                end
                            end
                        end)
                    end
                end
            end
        end)

        
        --根据玩家说的话来对命令进行处理
        local OldNetworking_Say = _G.Networking_Say
        _G.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote)
            local r = OldNetworking_Say(guid, userid, name, prefab, message, colour, whisper, isemote)

            local talker = GetPlayerById(userid)
            
            --获取到玩家说的话
            local words = {}
            for word in string.gmatch(message, "%S+") do
                table.insert(words, word) --分词
            end

            local recipient = nil
            
            if string.sub(message,1,1) == "#" then
                local sayAction = nil
                local sayToNum = nil
                if tablelength(words) == 2 then
                    sayAction = words[1]
                    sayToNum = _G.tonumber(words[2])
                elseif tablelength(words) == 1 then					
                    if string.lower( string.sub(message,5,string.len(message)) ) == "all" then
                        sayAction = string.sub(message,1,7)
                    else
                        sayAction = string.sub(message,1,4) 
                    end
                    sayToNum = _G.tonumber(string.sub(message,5,string.len(message))) 
                end

                if sayToNum ~= nil and (string.lower(sayAction) == "#add" or string.lower(sayAction) == "#del" or string.lower(sayAction) == "#delall") then
                    RefreshPlayers()
                    recipient = AllPlayers[sayToNum]
                    recipient_client = AllClientPlayers[sayToNum]
                    if recipient_client ~= nil then
                        if inst.guard_authorization[userid] == nil then
                            inst.guard_authorization[userid] = {}
                            inst.guard_authorization[userid].name = name
                        end

                        --给权限
                        if sayAction == "#add" then --这里应该要加一个大小写的转换，待测试,下面的其他指令也是
                            if recipient_client.userid ~= userid then
                                if  inst.guard_authorization[userid].friends == nil then 
                                    inst.guard_authorization[userid].friends = {}
                                end
                                inst.guard_authorization[userid].friends[recipient_client.userid] = true

                                PlayerSay(talker, GetSayMsg("permission_give", recipient_client.name))
                                PlayerSay(recipient, GetSayMsg("permission_get", name))
                                PlayerSay(talker, GetSayMsg("permission_del_tip"), 2.5)
                            else --把权限给了自己
                                PlayerSay(talker, GetSayMsg("permission_give_me"))
                            end
                        end

                        --收回单个权限
                        if sayAction == "#del" then
                            if recipient_client.userid ~= userid then
                                if inst.guard_authorization[userid].friends ~= nil and inst.guard_authorization[userid].friends[recipient_client.userid] then
                                    inst.guard_authorization[userid].friends[recipient_client.userid] = false

                                    PlayerSay(talker, GetSayMsg("permission_remove", recipient_client.name))
                                    PlayerSay(recipient, GetSayMsg("permission_lose", name))
                                else
                                    PlayerSay(talker, GetSayMsg("permission_remove_no", recipient_client.name))
                                end
                            else --收自己的权限
                                PlayerSay(talker, GetSayMsg("permission_remove_me"))
                            end
                        end			
                    else
                        PlayerSay(talker, GetSayMsg("permission_remove_num_err"))
                    end
                elseif sayToNum == nil and sayAction ~= nil and string.lower(sayAction) == "#delall" then 
                    --收回所有权限
                    if sayAction == "#delall" then
                        PlayerSay(talker, "全部收回!")

                        if inst.guard_authorization[userid].friends ~= nil then
                            inst.guard_authorization[userid].friends = nil 
                        end	
                    end
                elseif sayAction == "#add" or sayAction == "#del" then
                    --命令输入有误
                    PlayerSay(talker, GetSayMsg("command_error"))
                    PlayerSay(talker, GetSayMsg("command_help"), 2.5, 4) 		
                elseif talker ~= nil and _G.LookupPlayerInstByUserID(userid) then
                    --获取到玩家说的话
                    local choose = MSG_CHOOSE[string.lower(message)] 
                    if choose == 0 then -- #help
                        PlayerSay(talker, GetSayMsg("help_tips"), nil, 10)
                    end
                    if choose == 1 then -- #switch
                        talker.permission_switch = not talker.permission_switch
                        if talker.permission_switch then
                            PlayerSay(talker, "权限保护已开启！玩家新制作的放置物或建筑物将受保护（怪物不可破坏或不可燃等）",nil)
                        else
                            PlayerSay(talker, "权限保护已关闭！玩家新制作的放置物或建筑物将不受保护（怪物可破坏或可燃等）",nil)
                        end
                    end
                    if choose == 2 then -- #升级
                        PlayerSay(talker, 
                        "=========特殊物品信息=========\n\n【坎普斯背包】可添加冰块、蜂蜜、金块升级隔热、精神、保鲜\n【步行手杖】可添加金块、彩虹宝石、橙宝石升级移动速度、采集速度、制作速度(升级探索法杖或分解不会返还升级材料！！)\n \n \n\n！！更多特色玩法制作中，敬请期待！！",
                        nil, 10)
                    end
                end
            end

            return r
        end
    end)

    AddComponentPostInit("playerspawner", function(OnPlayerSpawn, inst)
        --监听玩家进入游戏
        inst:ListenForEvent("ms_playerjoined", function(inst, player)
            if player and player.components then
                AllPlayersForKeyUserID[player.userid] = player
                RefreshPlayers()
                player.permission_switch = true

                if _G.TheWorld.guard_authorization[player.userid] == nil then
                    _G.TheWorld.guard_authorization[player.userid] = {}
                    _G.TheWorld.guard_authorization[player.userid].unlocktime = 604800
                end
                _G.TheWorld.guard_authorization[player.userid].name = player.name

                player:DoTaskInTime(3, function(target)
                    PlayerSay(target, GetSayMsg("help_tips"), nil, 10)
                end)
            end
        end)

    end)

	---防止炸药炸毁建筑---
	AddComponentPostInit("explosive", function(explosive, inst)
		inst.buildingdamage = 0
		explosive.CurrentOnBurnt = explosive.OnBurnt
		function explosive:OnBurnt()
			local x, y, z = inst.Transform:GetWorldPosition()
			local ents2 = _G.TheSim:FindEntities(x, y, z, 10)
			local nearbyStructure = false
			for k, v in ipairs(ents2) do
				if v.components.burnable ~= nil and not v.components.burnable:IsBurning() then
					if v:HasTag("structure") then
						nearbyStructure = true
					end
				end
			end
			--
			if nearbyStructure then
				inst:RemoveTag("canlight")
			else
				inst:AddTag("canlight")
				explosive:CurrentOnBurnt()
			end
		end
	end)

	-- 眼球塔攻击的权限判断 2020.02.26
	AddPrefabPostInit("eyeturret", 
		function(inst) 
			local Combat = inst.components.combat
			local old_CanTarget = Combat.CanTarget 

			-- 有权限的墙和眼球塔不作为目标
			function Combat:CanTarget(target) 
				
				if (target.ownerlist ~= nil and (string.find(target.prefab, "wall_") or string.find(target.prefab, "fence")) ) 
					or target.prefab == "eyeturret"
					then 
					return false
				end

				local ret = old_CanTarget(Combat, target) 
				return ret 
			end

			-- 重构选择目标的函数
			local old_retargetfn = Combat.targetfn 
			local function retargetfn(inst) 
				local target = old_retargetfn(inst) 

				if target ~= nil then 

					-- 只帮助有权限的人攻击目标
					local player_attacked = ((target.components.combat.target ~= nil and target.components.combat.target:HasTag("player")) and target.components.combat.target) or nil 
					if player_attacked ~= nil and CheckItemPermission(player_attacked, inst, true) then 
						return target 
					end

					-- 若攻击者有权限才协助其攻击
					for i, v in ipairs(_G.AllPlayers) do
						if v.components.combat.target ~= nil then
							local attack_target = v.components.combat.target 
							if CheckItemPermission(v, inst, true) then 
								return attack_target 
							end 
							return nil 
						end
					end 

					return nil 
				end

				return target
			end

			Combat:SetRetargetFunction(1, retargetfn)
		end
	)

    -------------------------- 为安置物（不包括作物）加上权限 2020.2.10 --------------------------------------------

    AddComponentPostInit(
        "deployable",
        function(Deployable, inst) 

            local old_Deploy = Deployable.Deploy 

            function Deployable:Deploy(pt, deployer,...)                

                if _G.TheWorld.ismastersim == false then
                    return old_Deploy  
                end

                -- 加安置物的权限
                local ret = old_Deploy(Deployable, pt, deployer,...) 
                if ret then 
                    if not inst:HasTag("deployedplant") then 
                        local act_pos = pt 
                        local prefab = inst.prefab 

                        local x, y, z = GetSplitPosition(act_pos)
                        -- 处理墙的坐标
                        if string.find(prefab, "wall_") or string.find(inst.prefab, "fence_") then
                            x = math.floor(x) + .5
                            z = math.floor(z) + .5
                        end
                        -- 安置物为小木牌
                        if string.find(inst.prefab, "minisign") then                       
                            local ents = TheSim:FindEntities(x, y, z, 3, nil, {"INLIMBO"}, {"backpack", "sign"}, {"player"})
                            for _, findobj in pairs(ents) do
                                if findobj ~= nil and findobj.ownerlist == nil then
                                    SetItemPermission(findobj, deployer)
                                end
                            end
                        -- 其他的安置物(不包括作物)
                        else
                            local ents = TheSim:FindEntities(x, y, z, 1, nil, {"INLIMBO"}, nil, {"player"})
                            for _, findobj in pairs(ents) do
                                if findobj ~= nil and findobj.ownerlist == nil then
                                    SetItemPermission(findobj, deployer) 
                                    local master = findobj.ownerlist and GetPlayerById(findobj.ownerlist.master) or nil 
                                end
                            end
                        end
                    end   
                end 
                
                return ret 
            end
        end
    ) 

    -------------------------- 为树苗变的树和安置的作物加上权限 --------------------------------------------
 
    AddPrefabPostInit(
        "world", 
        function(world)             
            --作物的权限
            world:ListenForEvent("itemplanted", 
            function(inst, data)  
                local x,y,z = data.pos.x, data.pos.y, data.pos.z 
                local deployer = data.doer 

                local ents = TheSim:FindEntities(x, y, z, 1, nil, {"INLIMBO"}, nil, {"player"})
                for _, findobj in pairs(ents) do
                    if findobj ~= nil and findobj.ownerlist == nil then
                        SetItemPermission(findobj, deployer)
                    end
                end
            end
            )
		end
    )
    
    -- 重写玩家建造方法
    AddPlayerPostInit(
        function(player)
            if player.components.builder ~= nil then
                -- 建造新的物品，为每个建造的新物品都添加权限
                local old_onBuild = player.components.builder.onBuild
                player.components.builder.onBuild = function(doer, prod)
                    if old_onBuild ~= nil then
                        old_onBuild(doer, prod)
                    end

                    if player.permission_switch then
                        -- 仓库物品除了背包以外都不需要加Tag
                        if prod and (not prod.components.inventoryitem or prod.components.container) then
                            SetItemPermission(prod, doer)
                        end
                    end
                end
            end
        end
    )

    --------------------------右键开解锁-----------------------------------
    local rightLockTable = { 
        "hua_player_house",
        "hua_player_house1",
        "hua_player_house_pvz", 
        "hua_player_house_tardis",
    }

    local function addRightLock(inst)
        local function turnon(inst)
            inst.on = true
            inst.saved_ownerlist = inst.ownerlist
            inst.ownerlist = nil
            inst.components.machine.ison = true
        end

        local function turnoff(inst)
            inst.on = false
            if inst.saved_ownerlist ~= nil then
                inst.ownerlist = inst.saved_ownerlist
                inst.saved_ownerlist = nil
            end
            inst.components.machine.ison = false
        end

        if inst.prefab then
            inst:AddComponent("machine")
            inst.components.machine.cooldowntime = 1
            inst.components.machine.turnonfn = turnon
            inst.components.machine.turnofffn = turnoff
        end
    end

    for k, name in pairs(rightLockTable) do
        AddPrefabPostInit(name, addRightLock)
    end

    -----权限保存与加载----
    for k, v in pairs(_G.AllRecipes) do
        local recipename = v.name
        SavePermission(recipename)
    end

    for key, value in pairs(config_item.save_state_table) do
        SavePermission(value)
    end

    for key, value in pairs(config_item.deploys_cant_table) do
        SavePermission(key)
    end

    for key, value in pairs(config_item.winter_trees_table) do
        SavePermission(key)
    end

    -- 挖、铲、砸、砍的权限
    AddComponentPostInit(
        "workable",
        function(Workable, inst) 
            local old_WorkedBy = Workable.WorkedBy 
            function Workable:WorkedBy(worker, numworks) 
                local workaction = inst.components.workable:GetWorkAction()       
                local doer_num = worker:HasTag("player") and GetPlayerIndex(worker.userid) or nil 
                local owner = inst.ownerlist and GetPlayerById(inst.ownerlist.master) or nil 

                -- 船沉了则摧毁船上的物品
                if worker ~= nil and worker.prefab == "boat" then 
                    old_WorkedBy(Workable, worker, numworks)
                elseif workaction ~= nil and workaction == _G.ACTIONS.CHOP then 
                    if not string.find(inst.prefab, "winter_") then
                        old_WorkedBy(Workable, worker, numworks)   
                    elseif GetAge(worker) >= 20 or CheckItemPermission(worker, inst, true) then 
                        old_WorkedBy(Workable, worker, numworks)                       
                    else
                        PlayerSay(worker,"生存天数大于20天才能砍别人的树")        
                    end 
                -- 开采的权限 
                elseif workaction ~= nil and workaction == _G.ACTIONS.MINE then 
                    if GetAge(worker) >= 20 or CheckItemPermission(worker, inst, true) then 
                        old_WorkedBy(Workable, worker, numworks) 
                    else                        
                        PlayerSay(worker,"生存天数大于20天才能挖别人的矿石")       
                    end
                -- 砸的权限 
                elseif workaction ~= nil and workaction == _G.ACTIONS.HAMMER then 
                    if string.find(inst.prefab, "hua_player_house") then
                        if CheckItemPermission(worker, inst, true) and CheckItemSavedPermission(worker, inst, true) then 
                            old_WorkedBy(Workable, worker, numworks) 
                        else
                            PlayerSay(worker,"我不能砸别人的小屋") 
                        end
                    elseif GetAge(worker) >= 20 or CheckItemPermission(worker, inst, true) then 
                        old_WorkedBy(Workable, worker, numworks)               
                    else                        
                        PlayerSay(worker,"生存天数大于20天才能砸别人的建筑")       
                    end
                -- 铲挖的权限 
                elseif workaction ~= nil and workaction == _G.ACTIONS.DIG then 
                    if GetAge(worker) >= 20 or CheckItemPermission(worker, inst, true) then 
                        old_WorkedBy(Workable, worker, numworks)                  
                    else
                        PlayerSay(worker, "生存天数大于20天才能铲别人的物品")         
                    end
                else 
                    old_WorkedBy(Workable, worker, numworks) 
                end
            end
        end
    )

    --右键开锁控制
    local old_TURNON = _G.ACTIONS.TURNON.fn
    _G.ACTIONS.TURNON.fn = function(act)
        if _G.TheWorld.ismastersim == false then
            return old_TURNON(act)
        end

        if act.target then
            if 
                act.target.prefab == "hua_player_house" 
                or act.target.prefab == "hua_player_house1" 
                or act.target.prefab == "hua_player_house_pvz" 
                or act.target.prefab == "hua_player_house_tardis" 
             then
                if act.target.ownerlist ~= nil and act.target.ownerlist.master == act.doer.userid then
                    PlayerSay(act.doer, "已开锁！任何人都能进入小屋")
                    return old_TURNON(act)
                else
                    PlayerSay(act.doer, "可惜，我不能给它上锁和开锁！")
                    return false
                end
            end
        end

        return old_TURNON(act)
    end

    --右键上锁控制
    local old_TURNOFF = _G.ACTIONS.TURNOFF.fn
    _G.ACTIONS.TURNOFF.fn = function(act)
        if _G.TheWorld.ismastersim == false then
            return old_TURNOFF(act)
        end
        if act.target then
            if
                act.target.prefab == "hua_player_house" 
                or act.target.prefab == "hua_player_house1" 
                or act.target.prefab == "hua_player_house_pvz" 
                or act.target.prefab == "hua_player_house_tardis" 
             then
                if act.target.saved_ownerlist ~= nil and act.target.saved_ownerlist.master == act.doer.userid then
                    PlayerSay(act.doer, "已上锁！只有自己能进入小屋")
                    return old_TURNOFF(act)
                else
                    PlayerSay(act.doer, "可惜，我不能给它上锁和开锁！")
                    return false
                end
            end
        end

        return old_TURNOFF(act)
    end

    --防止玩家打开别人的容器
    AddComponentPostInit(
        "container",
        function(Container, target)
            local old_OpenFn = Container.Open
            function Container:Open(doer)
                -- 有权限时直接处理
                if GetAge(doer) >= 5 or CheckItemPermission(doer, target, true) or target.prefab == "cookpot" then
                    return old_OpenFn(self, doer)
                elseif doer:HasTag("player") then
                    -- 主人不为自己并且物品受权限控制
                    PlayerSay(doer, "生存天数大于5天才能打开别人的容器")
                end
            end
        end
    )


    --防止玩家降别人的锚
    local old_LOWER_ANCHOR = _G.ACTIONS.LOWER_ANCHOR.fn
    _G.ACTIONS.LOWER_ANCHOR.fn = function(act)
        if act.target.components.anchor ~= nil then
            --有权限直接处理
            if GetAge(act.doer) >= 20 or CheckItemPermission(act.doer, act.target, true) then
                return old_LOWER_ANCHOR(act)
            elseif act.doer:HasTag("player") then
                --主人不为自己且物品受权限控制
                PlayerSay(act.doer, "生存天数大于20天才能降别人的锚")
            end
        end
    end

    --防止玩家升别人的锚
    local old_RAISE_ANCHOR = _G.ACTIONS.RAISE_ANCHOR.fn
    _G.ACTIONS.RAISE_ANCHOR.fn = function(act)
        if act.target.components.anchor ~= nil then
            --有权限直接处理
            if GetAge(act.doer) >= 20 or CheckItemPermission(act.doer, act.target, true) then
                return old_RAISE_ANCHOR(act)
            elseif act.doer:HasTag("player") then
                --主人不为自己且物品受权限控制
                PlayerSay(act.doer, "生存天数大于20天才能升别人的锚")
            end
        end
    end

    --防止玩家升别人的船帆
    local old_RAISE_SAIL = _G.ACTIONS.RAISE_SAIL.fn
    _G.ACTIONS.RAISE_SAIL.fn = function(act)
        if act.target.components.mast ~= nil then
            --有权限直接处理
            if GetAge(act.doer) >= 20 or CheckItemPermission(act.doer, act.target, true) then
                return old_RAISE_SAIL(act)
            elseif act.doer:HasTag("player") then
                --主人不为自己且物品受权限控制
                PlayerSay(act.doer, "生存天数大于20天才能升别人的船帆")
            end
        end
    end

    --防止玩家降别人的船帆
    local old_LOWER_SAIL = _G.ACTIONS.LOWER_SAIL.fn
    _G.ACTIONS.LOWER_SAIL.fn = function(act)
        if act.target.components.mast ~= nil then
            --有权限直接处理
            if GetAge(act.doer) >= 20 or CheckItemPermission(act.doer, act.target, true) then
                return old_LOWER_SAIL(act)
            elseif act.doer:HasTag("player") then
                --主人不为自己且物品受权限控制
                PlayerSay(act.doer, "生存天数大于20天才能降别人的船帆")
            end
        end
    end

    --防止玩家使用别人的舵
    local old_STEER_BOAT = _G.ACTIONS.STEER_BOAT.fn
    _G.ACTIONS.STEER_BOAT.fn = function(act)
        if act.target.components.steeringwheel ~= nil then
            --有权限直接处理
            if GetAge(act.doer) >= 20 or CheckItemPermission(act.doer, act.target, true) then
                return old_STEER_BOAT(act)
            elseif act.doer:HasTag("player") then
                --主人不为自己且物品受权限控制
                PlayerSay(act.doer, "生存天数大于20天才能使用别人的船舵")
            end
        end
    end

    --吃齿轮
    local old_EAT = _G.ACTIONS.EAT.fn
    _G.ACTIONS.EAT.fn = function(act)
        local food = act.target or act.invobject
        if food and food.prefab == "gears" then
            if GetAge(act.doer) >= 50 then
                return old_EAT(act)
            else
                PlayerSay(act.doer, "生存天数大于50天才能吃齿轮")
                return false
            end
        end
        return old_EAT(act)
    end

    --私有小屋
    if _G.ACTIONS.HUA_ENTER_HOUSE ~= nil then
        local old_HUA_ENTER_HOUSE = _G.ACTIONS.HUA_ENTER_HOUSE.fn
        _G.ACTIONS.HUA_ENTER_HOUSE.fn = function(act)
            if act.target.components.hua_teleporter ~= nil then
                --有权限直接处理
                if CheckItemPermission(act.doer, act.target, true) then
                    return old_HUA_ENTER_HOUSE(act)
                elseif act.doer:HasTag("player") then
                    --主人不为自己且物品受权限控制
                    local doer_num = GetPlayerIndex(act.doer.userid)
                    local master = act.target.ownerlist and GetPlayerById(act.target.ownerlist.master) or nil
                    if master ~= nil then
                        PlayerSay(act.doer, GetSayMsg("permission_hua_no", master.name, GetItemOldName(act.target)))
                        PlayerSay(master, GetSayMsg("hua_enter", act.doer.name, GetItemOldName(act.target), doer_num))
                    else
                        PlayerSay(act.doer, GetSayMsg("player_leaved", GetPlayerNameByOwnerlist(act.target.ownerlist)))
                    end
                    act.doer.sg:GoToState('idle')
                end
            end
        end
    end

    --使船不着火
    AddPrefabPostInit(
        "burnable_locator_medium",
        function(inst)
            inst:RemoveComponent("burnable")
        end
    )

    -- 船锚放下船无敌 2020.02.25
    AddComponentPostInit(
        "hullhealth",
        function(Hullhealth) 
            local old_OnCollide = Hullhealth.OnCollide 
            function Hullhealth:OnCollide(data) 
                local boat = self.inst 
                local total_anchor_drag = boat.components.boatphysics:GetTotalAnchorDrag()

                if total_anchor_drag > 0 then 
                    data.hit_dot_velocity = nil 
                    data.hit_dot_velocity = 0 
                end

                old_OnCollide(Hullhealth, data) 
            end
        end
    )
end