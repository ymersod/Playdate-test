--- // DATA //
---@type RewardInfo
local coal = {
	valuableType = "Coal",
	value = 5,
}

---@type RewardInfo
local gold = {
	valuableType = "Gold",
	value = 50,
}
---@type RewardInfo
local diamond = {
	valuableType = "Diamond",
	value = 200,
}

---@class PlayerRewards
local playerRewards = {}

---@param rewardTable RewardTable?
---@return RewardInfo?
function playerRewards.ComputeRewards(rewardTable)
	if not rewardTable then
		return
	end

	table.sort(rewardTable, function(a, b)
		return a.chance < b.chance
	end)

	---@type RewardTable
	local computedRewardTable = {}
	local acc = 0
	for _, value in ipairs(rewardTable) do
		---@type DropValuesKvPs
		local newReward = {}
		acc += value.chance

		newReward.chance = acc
		newReward.valuableType = value.valuableType

		table.insert(computedRewardTable, newReward)
		print("acc is cur: " .. acc)
	end

	if acc ~= 100 then
		error("Acc should be 100 here - u dumbdumb")
	end

	local rolled = math.random(0, 100)

	---@type DropValuesKvPs
	local rewardCur
	for _, reward in ipairs(computedRewardTable) do
		if rolled <= reward.chance and (not rewardCur or reward.chance <= rewardCur.chance) then
			rewardCur = reward
		end
	end

	if not rewardCur then
		error("No rewardinfo somehow")
		return
	end

	---@type RewardInfo
	local rewardInfo = {}

	if rewardCur.valuableType == coal.valuableType then
		rewardInfo.valuableType = rewardCur.valuableType
		rewardInfo.value = coal.value
	elseif rewardCur.valuableType == gold.valuableType then
		rewardInfo.valuableType = rewardCur.valuableType
		rewardInfo.value = gold.value
	elseif rewardCur.valuableType == diamond.valuableType then
		rewardInfo.valuableType = rewardCur.valuableType
		rewardInfo.value = diamond.value
	else
		error("Didnt find matching valuable")
	end

	return rewardInfo
end

return playerRewards
