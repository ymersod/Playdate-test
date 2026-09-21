---@class MineRock
local mining = {}

---@param tick number
---@param rock RockGeneric
function mining.Mine(tick, rock)
	if tick < 1 then
		return nil
	end

	-- Update health of rock
	rock.health -= 1
end

return mining
