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
	sprite = tempSpriteValues,
}
---@type RockGeneric
local rock2 = {
	health = 50,
	rockType = "rock2",
	sprite = tempSpriteValues,
}

---@type RockGeneric
local rock3 = {
	health = 100,
	rockType = "rock3",
	sprite = tempSpriteValues,
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
	--[[ ---@type RockGeneric
	local rockCreated = {
		rockType = rockFound.rockType,
		health = rockFound.health,
		sprite = rockFound.sprite,
	} ]]

	local sprite = rockCreated.sprite

	sprite.x = context.screenW / 2 - sprite.w / 2
	sprite.y = context.screenH / 2 - sprite.h / 2

	return rockCreated
end

---@param context GameContext
---@param activeRock RockGeneric?
---@param rockSpawnTime number
---@return RockGeneric?, thread?
function rock.CheckRocks(context, activeRock, rockSpawnTime)
	local newRock = activeRock
	local rockSpawnTask = nil

	if activeRock and activeRock.health < 1 then
		-- TODO: Reward player

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

		local spawnedRock = rock.CreateRock(context, activeRock.rockType)
		return spawnedRock, rockSpawnTask
	end

	return newRock, rockSpawnTask
end

return rock
