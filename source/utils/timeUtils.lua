---@class TimeUtils
local timeUtils = {}

local currentTickChange = 0

local SPEED_UP_OVERHEATED = 4

---@param tick number
---@param overHeated boolean
---@return number
function timeUtils.ComputeRealTick(tick, overHeated)
	if overHeated then
		tick *= SPEED_UP_OVERHEATED
	end

	currentTickChange += tick
	local turns = math.floor(math.abs(currentTickChange) / 360)
	local direction = currentTickChange < 0 and -1 or 1
	currentTickChange -= turns * 360 * direction

	return turns
end

function timeUtils.Reset()
	currentTickChange = 0
end

return timeUtils
