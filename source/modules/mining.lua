---@class MineRock
local mining = {}
local heat = 0
local overheated = false

function mining.Cool(delta, heatsinks_mult)
	heat = math.max(0, heat - delta * 14)
	if heat <= 100 * heatsinks_mult * 0.35 then
		overheated = false
	end
end

function mining.GetHeat(heatsinks_mult)
	return heat / (100 * heatsinks_mult), overheated
end

---@param tick number
---@param rock RockGeneric?
---@param strength_mult number
function mining.Mine(tick, rock, strength_mult, heatsinks_mult)
	if not rock or tick < 1 or overheated or rock.health <= 0 then
		return 0
	end
	local hits = 0
	local capacity = 100 * (heatsinks_mult or 1)
	for _ = 1, tick do
		rock.health = math.max(0, rock.health - strength_mult)
		heat = math.min(capacity, heat + 18)
		hits += 1
		if heat >= capacity then
			overheated = true
		end
		if overheated or rock.health == 0 then
			break
		end
	end
	return hits
end

return mining
