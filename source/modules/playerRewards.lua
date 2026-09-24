--- // DATA //

--- // VALUABLES //
---@type RewardInfo
local coal = {
	valuableType = "Coal",
	value = 5,
}

---@type RewardInfo
local topaz = {
	valuableType = "Topaz",
	value = 50,
}
---@type RewardInfo
local diamond = {
	valuableType = "Diamond",
	value = 200,
}

---@type RewardInfo
local emerald = {
	valuableType = "Emerald",
	value = 200,
}

---@type RewardInfo
local ruby = {
	valuableType = "Ruby",
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
			value = 10,
			chance = 55,
		},
	},
	["rock2"] = {
		{
			collectableType = "Fossil",
			value = 1000,
			chance = 5,
		},
		{
			collectableType = "Amber",
			value = 250,
			chance = 45,
		},
		{
			collectableType = "Book",
			value = 100,
			chance = 60,
		},
	},
	["rock3"] = {
		{
			collectableType = "???",
			value = 99999,
			chance = 1,
		},
		{
			collectableType = "Element 67",
			value = 9,
			chance = 670,
		},
		{
			collectableType = "Dirt",
			value = 1,
			chance = 90,
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
---@param rockMult number
---@return RewardInfo?
function playerRewards.ComputeRewards(rewardTable, ore_value_mult, rockMult)
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
	rewardInfo.valuableType = rewardCur.valuableType
	if rewardCur.valuableType == coal.valuableType then
		rewardInfo.value = coal.value
	elseif rewardCur.valuableType == topaz.valuableType then
		rewardInfo.value = topaz.value
	elseif rewardCur.valuableType == diamond.valuableType then
		rewardInfo.value = diamond.value
	elseif rewardCur.valuableType == emerald.valuableType then
		rewardInfo.value = emerald.value
	elseif rewardCur.valuableType == ruby.valuableType then
		rewardInfo.value = ruby.value
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
