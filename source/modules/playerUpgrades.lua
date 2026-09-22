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

---@param playerStats PlayerLevels
---@return UpgradeMultipliers
function upgrades.ComputeValues(playerStats)
	---@type UpgradeMultipliers
	local mults = {
		strength_mult = playerStats.strength_level,
		heatsinks_mult = playerStats.heatsinks_level, --TODO:
		ore_value_mult = playerStats.ore_value_level, -- TODO:
		drop_chances_mult = ComputeDropChance(playerStats.drop_chances_level),
	}

	return mults
end

return upgrades
