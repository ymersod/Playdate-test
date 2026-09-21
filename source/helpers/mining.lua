---@class MineRock
local mining = {}

---@param tick number
---@param rock RockGeneric
---@return number?
function mining.Mine(tick, rock)
	if tick < 1 then
		return nil
	end

	-- Update health of rock

	return 5 -- Should return the state of the rock
end

return mining
