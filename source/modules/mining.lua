---@class MineRock
local mining = {}

---@param tick number
---@param rock RockGeneric?
---@param strength_mult number
function mining.Mine(tick, rock, strength_mult)
	if not rock then
		return
	end

	if tick < 1 then
		return nil
	end
	rock.health -= 1 + (1 * strength_mult)
end

return mining
