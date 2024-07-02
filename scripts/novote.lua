local _G = GLOBAL
local TheNet = _G.TheNet

local UserCommands = _G.require("usercommands")
local VoteUtil = _G.require("voteutil")

local no_rollback = false
local no_regenerate = true
local no_kick = true
local kick_without = {"KU_cg2vTfZ4"}

local show_starter = true

local reflect_kick = true

local kick_without_cache = {}
for key, value in pairs(kick_without) do
	kick_without_cache[value] = true
end


function showstarter(src, data)
	local cmd = UserCommands.GetCommandFromHash(data.commandhash)
	if cmd ~= nil then
		print("[NoVote]Vote Start by:", data.starteruserid, cmd.name, data.commandhash, data.targetuserid)
		if kick_without_cache[data.targetuserid] ~= nil and cmd.name == "kick" then
			print("[NoVote]", data.starteruserid, "try to kick", data.targetuserid)
			if reflect_kick then
			    TheNet:Kick(data.starteruserid, nil)
			end
		end
	end
end

function WaitActivated(inst)

if TheNet and TheNet:GetIsServer() then -- Is server
print("[NoVote]init...")

print("[NoVote]AddUserCommand", AddUserCommand)
print("[NoVote]_G.AddUserCommand", _G.AddUserCommand)
print("[NoVote]AddModUserCommand", AddModUserCommand)
print("[NoVote]_G.AddModUserCommand", _G.AddModUserCommand)
print("[NoVote]AddVoteCommand", AddVoteCommand)

--print("[NoVote]smallhash", smallhash)
print("[NoVote]_G.smallhash", _G.smallhash)
--print("[NoVote]GetCommandFromName", GetCommandFromName)
print("[NoVote]UserCommands.GetCommandFromName", UserCommands.GetCommandFromName)

	if show_starter then
		inst:ListenForEvent("ms_startvote", showstarter, inst)
	end

	if no_rollback then
print("[NoVote]no_rollback", no_rollback)
print("[NoVote]rollback Cmd", UserCommands.GetCommandFromName("rollback"))
		local rollbackCmd = UserCommands.GetCommandFromName("rollback")
		if rollbackCmd ~= nil then
			rollbackCmd.votetimeout = 60
			rollbackCmd.serverfn = function(params, caller)
				if caller ~= nil then
					print("[NoVote][rollback]serverfn", caller, caller.name, caller.userid)
				else
					print("[NoVote][rollback]serverfn", caller)
				end
			end
		else
			print("[NoVote][rollback]Patch Cmd Faild!!")
		end
print("[NoVote]rollback2", UserCommands.GetCommandFromName("rollback"))
	end

	if no_regenerate then
print("[NoVote]no_regenerate", no_regenerate)
print("[NoVote]regenerate", UserCommands.GetCommandFromName("regenerate"))
		local regenerateCmd = UserCommands.GetCommandFromName("regenerate")
		if regenerateCmd ~= nil then
			regenerateCmd.votetimeout = 60
			regenerateCmd.serverfn = function(params, caller)
				if caller ~= nil then
					print("[NoVote][regenerate]serverfn", caller, caller.name, caller.userid)
				else
					print("[NoVote][regenerate]serverfn", caller)
				end
				TheNet:Announce("重新生成世界失败 原因：禁止投票重新生成世界")
			end
		else
			print("[NoVote][regenerate]Patch Cmd Faild!!")
		end
print("[NoVote]regenerate2", UserCommands.GetCommandFromName("regenerate"))
	end

	if no_kick or (#kick_without ~= 0) then
print("[NoVote]no_kick", no_kick)
print("[NoVote]kick_without", #kick_without, kick_without)
print("[NoVote]kick", UserCommands.GetCommandFromName("kick"))

		local kickCmd = UserCommands.GetCommandFromName("kick")
		if kickCmd ~= nil then
			kickCmd.votetimeout = 90
			kickCmd.localfn = function(params, caller)
				if caller ~= nil then
					print("[NoVote][kick]serverfn", caller, caller.name, caller.userid)
				else
					print("[NoVote][kick]serverfn", caller)
				end

				if no_kick then
					TheNet:Announce("投票踢人失败 原因：禁止投票投票踢人")
					return
				end

				local clientid = _G.UserToClientID(params.user)
				if clientid ~= nil then
					if kick_without_cache[clientid] == nil then
					    TheNet:Kick(clientid, caller == nil and _G.TUNING.VOTE_KICK_TIME or nil)
					else
						print("[NoVote][kick]can't kick", params.user, clientid)
					end
				end
			end
		else
			print("[NoVote][kick]Patch Cmd Faild!!")
		end
print("[NoVote]kick2", UserCommands.GetCommandFromName("kick"))
	end
end


end

AddPrefabPostInit("world", WaitActivated)