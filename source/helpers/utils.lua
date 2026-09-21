---@class Utils
local utils = {}

local currentTickChange = 0

---@param tick number
---@param pos number
---@return number
function utils.ComputeRealTick(tick, pos)
	currentTickChange += tick
	if currentTickChange < -360 then
		currentTickChange = math.floor(-pos)
		currentTickChange = 0
		return 1
	end

	if currentTickChange >= 360 then
		currentTickChange = math.floor(pos)
		return 1
	end

	return 0
end

return utils
