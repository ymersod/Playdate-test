---@class PlayerUpgrades
local upgrades = {}

---@param level number
---@return DropChanceMult
function ComputeDropChance(level)
	---@type DropChanceMult
	local dropChanceMults = {
		coal_mult = 10 * level,
		gold_mult = 5 * level,
		diamond_mult = 5 * level,
	}

	return dropChanceMults
end

---@param level number
---@return number
function ComputeOreMult(level)
	local mult = 1 + (level * 0.25)
	return mult
end

---@param level number
---@return number
function ComputeStrengthMult(level)
	local mult = 1 + math.floor(level * 1) -- Tried 1.5 as value but we'd go 1:2:4 which might indicate players think it doubles WHICH IT DOESNT...
	return mult
end

---@param playerStats PlayerLevels
---@return UpgradeMultipliers
function upgrades.ComputeValues(playerStats)
	---@type UpgradeMultipliers
	local mults = {
		strength_mult = ComputeStrengthMult(playerStats.strength_level),
		heatsinks_mult = playerStats.heatsinks_level, --TODO:
		ore_value_mult = ComputeOreMult(playerStats.ore_value_level),
		drop_chances_mult = ComputeDropChance(playerStats.drop_chances_level),
	}

	return mults
end

return upgrades
