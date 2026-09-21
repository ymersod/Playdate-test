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

---@param rockType RockType
---@param context GameContext
---@return RockGeneric?
function rock.CreateRock(rockType, context)
	---@type RockGeneric?
	local rockCreated

	if rockType == "rock1" then
		rockCreated = rock1
	elseif rockType == "rock2" then
		rockCreated = rock2
	elseif rockType == "rock3" then
		rockCreated = rock3
	end

	local sprite = rockCreated.sprite

	sprite.x = context.screenW / 2 - sprite.w / 2
	sprite.y = context.screenH / 2 - sprite.h / 2

	return rockCreated
end

return rock
