local TheNet = GLOBAL.TheNet

local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

local TheWorld = GLOBAL.TheWorld

local TUNING = GLOBAL.TUNING

local auto_clean = false

if IsServer then
    -- 需要清理的物品
    -- @max        地图上存在的最大数量
    -- @stack      标识为true时表示仅清理无堆叠的物品
    -- @reclean    标识为数字,表示超过第n次清理时物品还存在则强制清理(第一次找到物品并未清理的计数为1)
    local function GetLevelPrefabs()
        local levelPrefabs = {
            ------------------------  生物  ------------------------
            hound           = { max = 30 },    -- 狗
            firehound       = { max = 10 },    -- 火狗
            spider_warrior  = { max = 10 },    -- 蜘蛛战士
            spider          = { max = 10 },    -- 蜘蛛
            flies           = { max = 10 },    -- 苍蝇
            mosquito        = { max = 10 },    -- 蚊子
            bee             = { max = 10 },    -- 蜜蜂
            killerbee       = { max = 10 },    -- 杀人蜂
            frog            = { max = 20 },    -- 青蛙
            beefalo         = { max = 90 },   -- 牛
            grassgekko      = { max = 15 },   -- 草蜥蜴
            lightninggoat   = { max = 25 },    -- 羊
            deer            = { max = 10 },   -- 鹿
            bunnyman        = { max = 10 },    -- 兔人
            slurtle         = { max = 5 },     -- 鼻涕虫
            snurtle         = { max = 5 },     -- 蜗牛

            ------------------------  地面物体  ------------------------
            evergreen_sparse    = { max = 250 },                      -- 常青树
            twiggytree          = { max = 150 },                      -- 树枝树
            marsh_tree          = { max = 100 },                      -- 针刺树
            rock_petrified_tree = { max = 400 },                      -- 石化树
            skeleton_player     = { max = 50 },                       -- 玩家尸体
            spiderden           = { max = 50 },                       -- 蜘蛛巢
            burntground         = { max = 50 },                       -- 陨石痕跡

            ------------------------  可拾取物品  ------------------------
            seeds           = { max = 10, stack = true, reclean = 3 },                -- 种子
            log             = { max = 100, stack = true, reclean = 3 },       -- 木头
            pinecone        = { max = 100, stack = true, reclean = 3 },       -- 松果
            cutgrass        = { max = 100, stack = true, reclean = 3 },       -- 草
            twigs           = { max = 100, stack = true, reclean = 3 },       -- 树枝
            rocks           = { max = 100, stack = true, reclean = 3 },       -- 石头
            nitre           = { max = 100, stack = true, reclean = 3 },       -- 硝石
            flint           = { max = 100, stack = true, reclean = 3 },       -- 燧石
            poop            = { max = 70 , stack = true, reclean = 3 },       -- 屎
            guano           = { max = 5 , stack = true, reclean = 3 },       -- 鸟屎
            manrabbit_tail  = { max = 70 , stack = true, reclean = 3 },       -- 兔毛
            silk            = { max = 70 , stack = true, reclean = 3 },       -- 蜘蛛丝
            spidergland     = { max = 70 , stack = true, reclean = 3 },       -- 蜘蛛腺体
            stinger         = { max = 5 , stack = true, reclean = 3 },       -- 蜂刺
            houndstooth     = { max = 80 , stack = true, reclean = 3 },       -- 狗牙
            mosquitosack    = { max = 80 , stack = true, reclean = 3 },       -- 蚊子血袋
            glommerfuel     = { max = 80 , stack = true, reclean = 3 },       -- 格罗姆粘液
            slurtleslime    = { max = 6 , stack = true, reclean = 3 },       -- 鼻涕虫粘液
            slurtle_shellpieces = { max = 10, stack = true, reclean = 3 },   -- 鼻涕虫壳碎片

            spoiled_food    = { max = 10 },                                  -- 腐烂食物
            winter_food4    = { max = 2, stack = true, reclean = 3 },        -- 维多利亚面包

            winter_ornament_plain1 = { max = 2, stack = true, reclean = 3 }, -- 节日小饰品
            winter_ornament_plain2 = { max = 2, stack = true, reclean = 3 },
            winter_ornament_plain4 = { max = 2, stack = true, reclean = 3 },
            winter_ornament_plain5 = { max = 2, stack = true, reclean = 3 },
            winter_ornament_plain6 = { max = 2, stack = true, reclean = 3 },
            winter_ornament_plain7 = { max = 2, stack = true, reclean = 3 },
            winter_ornament_plain8 = { max = 2, stack = true, reclean = 3 },

            trinket_3   = { max = 2, stack = true, reclean = 3 },            -- 戈尔迪乌姆之结
            trinket_4   = { max = 2, stack = true, reclean = 3 },
            trinket_6   = { max = 2, stack = true, reclean = 3 },
            trinket_8   = { max = 2, stack = true, reclean = 3 },

            blueprint   = { max = 30 },    -- 蓝图
            axe         = { max = 3 },    -- 斧子
            torch       = { max = 3 },    -- 火炬
            pickaxe     = { max = 3 },    -- 镐子
            hammer      = { max = 3 },    -- 锤子
            shovel      = { max = 3 },    -- 铲子
            razor       = { max = 3 },    -- 剃刀
            pitchfork   = { max = 3 },    -- 草叉
            bugnet      = { max = 3 },    -- 捕虫网
            fishingrod  = { max = 3 },    -- 鱼竿
            spear       = { max = 3 },    -- 矛
            earmuffshat = { max = 3 },    -- 兔耳罩
            winterhat   = { max = 3 },    -- 冬帽
            trap        = { max = 30 },   -- 动物陷阱
            birdtrap    = { max = 30 },   -- 鸟陷阱
            compass     = { max = 3 },    -- 指南針

            chesspiece_deerclops_sketch     = { max = 2 },    -- 四季 boss 棋子图
            chesspiece_bearger_sketch       = { max = 2 },
            chesspiece_moosegoose_sketch    = { max = 2 },
            chesspiece_dragonfly_sketch     = { max = 2 },

            winter_ornament_boss_bearger    = { max = 2, stack = true, reclean = 3 },    -- 四季 boss 和蛤蟆、蜂后的挂饰
            winter_ornament_boss_beequeen   = { max = 2, stack = true, reclean = 3 },
            winter_ornament_boss_deerclops  = { max = 2, stack = true, reclean = 3 },
            winter_ornament_boss_dragonfly  = { max = 2, stack = true, reclean = 3 },
            winter_ornament_boss_moose      = { max = 2, stack = true, reclean = 3 },
            winter_ornament_boss_toadstool  = { max = 2, stack = true, reclean = 3 },

            armor_sanity   = { max = 20 },    -- 影甲
            shadowheart    = { max = 5 },    -- 影心
        }

        return levelPrefabs
    end

    local function RemoveItem(inst)
        if inst.components.health ~= nil and not inst:HasTag("wall") then
            if inst.components.lootdropper ~= nil then
                inst.components.lootdropper.DropLoot = function(pt) end
            end
            inst.components.health:SetPercent(0)
        else
            inst:Remove()
        end
    end

    local function Clean()
        TheNet:Announce("【自动清理】 正在清理！")
        local this_max_prefabs = GetLevelPrefabs()
        local countList = {}

        for _,v in pairs(GLOBAL.Ents) do
            if v.prefab ~= nil then
                repeat
                    local thisPrefab = v.prefab
                    if this_max_prefabs[thisPrefab] ~= nil then
                        if v.reclean == nil then
                            v.reclean = 1
                        else
                            v.reclean = v.reclean + 1
                        end

                        local bNotClean = true
                        if this_max_prefabs[thisPrefab].reclean ~= nil then
                            bNotClean = this_max_prefabs[thisPrefab].reclean > v.reclean
                        end

                        if this_max_prefabs[thisPrefab].stack and bNotClean and v.components and v.components.stackable and v.components.stackable:StackSize() > 1 then break end
                    else break end

                    -- 不可见物品(在包裹内等)
                    if v.inlimbo then break end

                    if countList[thisPrefab] == nil then
                        countList[thisPrefab] = { name = v.name, count = 1, currentcount = 1 }
                    else
                        countList[thisPrefab].count = countList[thisPrefab].count + 1
                        countList[thisPrefab].currentcount = countList[thisPrefab].currentcount + 1
                    end

                    if this_max_prefabs[thisPrefab].max >= countList[thisPrefab].count then break end

                    if (v.components.hunger ~= nil and v.components.hunger.current > 0) or (v.components.domesticatable ~= nil and v.components.domesticatable.domestication > 0) then
                        break
                    end

                    RemoveItem(v)
                    countList[thisPrefab].currentcount = countList[thisPrefab].currentcount - 1
                until true
            end
        end

        for k,v in pairs(this_max_prefabs) do
            if countList[k] ~= nil and countList[k].count > v.max then
                print(string.format("清理了   %s(%s)   %d   %d   %d", countList[k].name, k, countList[k].count, countList[k].count - countList[k].currentcount, countList[k].currentcount))
            end
        end
    end

    local function CleanDelay(delay)
        delay = delay or 30
        TheNet:Announce("【自动清理】：本房间将于 "..delay.." 秒后清理！")
            TheWorld:DoTaskInTime(delay, Clean)
        
    end

    AddPrefabPostInit("world", function(inst)
        if auto_clean then
            inst:DoPeriodicTask(10 * TUNING.TOTAL_DAY_TIME, CleanDelay)
        end
    
    end)

    GLOBAL.Clean = Clean
    GLOBAL.CleanDelay = CleanDelay
end