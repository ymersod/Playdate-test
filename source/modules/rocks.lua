-- //DATA//

-- PLEASE READ
-- NOTEs FOR CHANGING DROPTABLES
-- COAL CANNOT GO BELOW 50
-- DROPS SHOULD ADD UP TO 100

---@type RockGeneric
local rock1 = {
	health = 20,
	rockType = "rock1",
	rockName = "Marble",
	heatBuffer = 20,
	rockTypeNumber = 1,
	rockValueMultiplier = 1,
	dropTable = {
		{
			valuableType = "Coal",
			chance = 100,
		},
		{
			valuableType = "Topaz",
			chance = 0,
		},
		{
			valuableType = "Diamond",
			chance = 0,
		},
		{
			valuableType = "Emerald",
			chance = 0,
		},
		{
			valuableType = "Ruby",
			chance = 0,
		},
	},
}
---@type RockGeneric
local rock2 = {
	health = 50,
	rockType = "rock2",
	rockName = "Slate",
	heatBuffer = 10,
	rockTypeNumber = 2,
	rockValueMultiplier = 2,
	dropTable = {
		{
			valuableType = "Coal",
			chance = 70,
		},
		{
			valuableType = "Topaz",
			chance = 15,
		},
		{
			valuableType = "Diamond",
			chance = 5,
		},
		{
			valuableType = "Emerald",
			chance = 5,
		},
		{
			valuableType = "Ruby",
			chance = 5,
		},
	},
}

---@type RockGeneric
local rock3 = {
	health = 100,
	rockType = "rock3",
	rockName = "Granite",
	rockTypeNumber = 3,
	heatBuffer = 5,
	rockValueMultiplier = 4,
	dropTable = {
		{
			valuableType = "Coal",
			chance = 50,
		},
		{
			valuableType = "Topaz",
			chance = 5,
		},
		{
			valuableType = "Diamond",
			chance = 10,
		},
		{
			valuableType = "Emerald",
			chance = 15,
		},
		{
			valuableType = "Ruby",
			chance = 20,
		},
	},
}

---@class Rock
local rock = {}

---@param context GameContext
---@param rockType RockType
---@param heat_sink_mult number
---@return RockGeneric?
function rock.CreateRock(context, rockType, heat_sink_mult)
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
	rockCreated.maxHealth = rockCreated.health

	local newSprite = {}
	rockCreated.sprite = newSprite
	local sprite = rockCreated.sprite

	sprite.w = 128
	sprite.h = 128
	sprite.x = context.screenW / 2 - sprite.w / 2
	sprite.y = (context.screenH / 2 - sprite.h / 2) + 30

	local max = 100
	local min = 10
	local computedBuffer = rockCreated.heatBuffer + heat_sink_mult

	rockCreated.heatToMatch = math.random(min + computedBuffer, max - computedBuffer)

	return rockCreated
end

---@param rock RockGeneric
---@param drop_chances_mult DropChanceMult
---@return RewardTable
function rock.UpdateRewardsTable(rock, drop_chances_mult)
	---@type RewardTable
	local rewardTable = {}

	for _, dropData in ipairs(rock.dropTable) do
		---@type DropValuesKvPs
		local valCopy = table.deepcopy(dropData)

		if dropData.valuableType == "Coal" then
			valCopy.chance -= drop_chances_mult.coal_mult
		elseif dropData.valuableType == "Topaz" then
			valCopy.chance += drop_chances_mult.topaz_mult
		elseif dropData.valuableType == "Diamond" then
			valCopy.chance += drop_chances_mult.diamond_mult
		elseif dropData.valuableType == "Emerald" then
			valCopy.chance += drop_chances_mult.emerald_mult
		elseif dropData.valuableType == "Ruby" then
			valCopy.chance += drop_chances_mult.ruby_mult
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

	if activeRock and activeRock.health <= 0 then
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
		local updatedRewardsTable = rock.UpdateRewardsTable(activeRock, upgrade_mults.drop_chances_mult)

		local spawnedRock = rock.CreateRock(context, activeRock.rockType, upgrade_mults.heatsinks_mult)

		return spawnedRock, updatedRewardsTable, rockSpawnTask
	end

	return newRock
end

return rock
