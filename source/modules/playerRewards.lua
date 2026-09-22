---@class PlayerRewards
local playerRewards = {}

---@return RewardInfo?
function playerRewards.ComputeRewards(rewardTable)
	if not rewardTable then
		return
	end
	---@type RewardInfo
	local rewards = {
		valuableType = "Diamond",
		value = 10,
	}

	return rewards
end

return playerRewards
