---@class TimeUtils
local timeUtils = {}

local currentTickChange = 0

---@param tick number
---@return number
function timeUtils.ComputeRealTick(tick)
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
