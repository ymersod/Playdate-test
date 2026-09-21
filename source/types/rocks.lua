---@type Enums
local enums = import("globals/enums")

-- data
local rock1 = {
	health = 10,
	rockType = enums.rockType.rock1,
}

local rock2 = {
	health = 50,
	rockType = enums.rockType.rock2,
}

local rock3 = {
	health = 100,
	rockType = enums.rockType.rock3,
}

---@class Rock
local rock = {}

---@param rockType string
---@return RockGeneric?
function rock.CreateRock(rockType)
	if rockType == "rock1" then
		return rock1
	elseif rockType == "rock2" then
		return rock2
	elseif rockType == "rock3" then
		return rock3
	end

	return nil
end

return rock
