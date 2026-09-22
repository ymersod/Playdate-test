-- //DATA//
local tempSpriteValues = {
	w = 50,
	h = 50,
	x = 0,
	y = 0,
}

---@type RockGeneric
local rock1 = {
	health = 10,
	rockType = "rock1",
	rockTypeNumber = 1,
	sprite = tempSpriteValues,
	dropTable = {
		{
			valuableType = "Coal",
			chance = 80,
		},
		{
			valuableType = "Gold",
			chance = 15,
		},
		{
			valuableType = "Diamond",
			chance = 5,
		},
	},
}
---@type RockGeneric
local rock2 = {
	health = 50,
	rockType = "rock2",
	rockTypeNumber = 2,
	sprite = tempSpriteValues,
	dropTable = { -- TODO: Temp so far
		{
			valuableType = "Coal",
			chance = 80,
		},
		{
			valuableType = "Gold",
			chance = 15,
		},
		{
			valuableType = "Diamond",
			chance = 5,
		},
	},
}

---@type RockGeneric
local rock3 = {
	health = 100,
	rockType = "rock3",
	rockTypeNumber = 3,
	sprite = tempSpriteValues,
	dropTable = { -- TODO: Temp so far
		{
			valuableType = "Coal",
			chance = 80,
		},
		{
			valuableType = "Gold",
			chance = 15,
		},
		{
			valuableType = "Diamond",
			chance = 5,
		},
	},
}

---@class Rock
local rock = {}

---@param context GameContext
---@param rockType RockType
---@return RockGeneric?
function rock.CreateRock(context, rockType)
	---@type RockGeneric?
	local rockFound
	if rockType == "rock1" then
		rockFound = rock1
	elseif rockType == "rock2" then
		rockFound = rock2
	elseif rockType == "rock3" then
		rockFound = rock3
	end

	if not rockFound then
		return rockFound
	end

	---@type RockGeneric
	local rockCreated = table.deepcopy(rockFound)

	local sprite = rockCreated.sprite

	sprite.x = context.screenW / 2 - sprite.w / 2
	sprite.y = context.screenH / 2 - sprite.h / 2

	return rockCreated
end

---@param rock RockGeneric
---@param drop_chances_mult DropChanceMult
---@return RewardTable
function UpdateRewardsTable(rock, drop_chances_mult)
	---@type RewardTable
	local rewardTable = {}

	for _, dropData in ipairs(rock.dropTable) do
		---@type DropValuesKvPs
		local valCopy = table.deepcopy(dropData)

		if dropData.valuableType == "Coal" then
			valCopy.chance -= drop_chances_mult.coal_mult
		elseif dropData.valuableType == "Gold" then
			valCopy.chance += drop_chances_mult.gold_mult
		elseif dropData.valuableType == "Diamond" then
			valCopy.chance += drop_chances_mult.diamond_mult
		end

		table.insert(rewardTable, valCopy)
	end

	return rewardTable
end

---@param context GameContext
---@param activeRock RockGeneric?
---@param rockSpawnTime number
---@param upgrade_mults UpgradeMultipliers
---@return RockGeneric?, RewardTable?, thread?
function rock.CheckRocks(context, activeRock, rockSpawnTime, upgrade_mults)
	local newRock = activeRock
	local rockSpawnTask = nil

	if activeRock and activeRock.health < 0 then
		-- // SPAWN ROCK COROUTINE TODO: Does not work, but might be a great start
		--[[ rockSpawnTask = coroutine.create(function()
			local goal = playdate.getCurrentTimeMilliseconds() + (rockSpawnTime * 1000)
			while playdate.getCurrentTimeMilliseconds() < goal do
				if not coroutine.isyieldable() then
					return
				end
				coroutine.yield()
			end

			local spawnedRock = rock.CreateRock(context, prevRockType)
			return spawnedRock
		end) ]]
		local updatedRewardsTable = UpdateRewardsTable(activeRock, upgrade_mults.drop_chances_mult)

		local spawnedRock = rock.CreateRock(context, activeRock.rockType)

		return spawnedRock, updatedRewardsTable, rockSpawnTask
	end

	return newRock
end

return rock
