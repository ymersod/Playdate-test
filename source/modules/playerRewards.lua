---@class PlayerRewards
local playerRewards = {}

---@param rewardTable RewardTable?
---@return RewardInfo?
function playerRewards.ComputeRewards(rewardTable)
	if not rewardTable then
		return
	end

	local rew = rewardTable[1]
	print(rew.ValuableType)
	print(rew.chance)

	---@type RewardInfo
	local rewards = {
		valuableType = "Diamond",
		value = 10,
	}

	return rewards
end

return playerRewards
