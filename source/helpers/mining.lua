---@class MineRock
local mining = {}

---@param tick number
---@param rock RockGeneric?
function mining.Mine(tick, rock)
	if not rock then
		return
	end

	if tick < 1 then
		return nil
	end
	rock.health -= 1
end

return mining
