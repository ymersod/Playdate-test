--- // DATA //

--- // VALUABLES //
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

--- // COLLECTABLES //
local BASE_COLLECTABLE_CHANCE = 2

---@type CollectableList
local collectableList = {
	["rock1"] = {
		{
			collectableType = "Ring",
			value = 500,
			chance = 10,
		},
		{
			collectableType = "Bone",
			value = 100,
			chance = 35,
		},
		{
			collectableType = "Boot",
			value = 1,
			chance = 55,
		},
	},
	["rock2"] = {
		{
			collectableType = "Ring",
			value = 500,
			chance = 10,
		},
		{
			collectableType = "Bone",
			value = 100,
			chance = 35,
		},
		{
			collectableType = "Boot",
			value = 1,
			chance = 55,
		},
	},
	["rock3"] = {
		{
			collectableType = "Ring",
			value = 500,
			chance = 10,
		},
		{
			collectableType = "Bone",
			value = 100,
			chance = 35,
		},
		{
			collectableType = "Boot",
			value = 1,
			chance = 55,
		},
	},
}

---@class PlayerRewards
local playerRewards = {}

---@param valueableDrop RewardInfo?
---@param collectable_mult number
---@param rock RockType
---@return Collectable?
function playerRewards.ComputeCollectable(valueableDrop, collectable_mult, rock)
	if not valueableDrop then
		return
	end

	local collectableTable = collectableList[rock]

	local rolled_collectable = math.random(1, 100)

	if rolled_collectable > BASE_COLLECTABLE_CHANCE * collectable_mult then -- NO COLLECTABLE ROLLED
		return
	end

	if not collectableTable then
		warn("Didn't find collectable table for " .. rock)
		return
	end

	table.sort(collectableTable, function(a, b)
		return a.chance < b.chance
	end)

	---@type Collectable[]
	local computedRewardTable = {}
	local acc = 0
	for _, value in ipairs(collectableTable) do
		---@type Collectable
		local newReward = {}
		acc += value.chance

		newReward.chance = acc
		newReward.collectableType = value.collectableType
		newReward.value = value.value

		table.insert(computedRewardTable, newReward)
		--[[ 		print("acc is cur: " .. acc) ]]
	end

	local rolled = math.random(1, 100)

	---@type Collectable
	local collectableCur
	for _, collectable in ipairs(computedRewardTable) do
		if rolled <= collectable.chance and (not collectableCur or collectable.chance <= collectableCur.chance) then
			collectableCur = collectable
		end
	end

	if not collectableCur then
		error("We didnt roll a collectable, after confirming we should get one - somethings awry")
		return
	end

	return collectableCur
end

---@param rewardTable RewardTable?
---@param ore_value_mult number
---@return RewardInfo?
function playerRewards.ComputeRewards(rewardTable, ore_value_mult)
	if not rewardTable then
		return
	end

	-- // COMPUTE ORE REWARD
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
		--[[ 		print("acc is cur: " .. acc) ]]
	end

	if acc ~= 100 then
		error("Acc should be 100 here - u dumbdumb")
	end

	local rolled = math.random(1, 100)

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

	rewardInfo.value = math.floor(rewardInfo.value * ore_value_mult)

	return rewardInfo
end

---@return CollectableList
function playerRewards.GetCollectableList()
	return collectableList
end

return playerRewards
