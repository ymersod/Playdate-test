---@class PlayerUpgrades
local upgrades = {}

---@param playerStats PlayerLevels
---@return UpgradeMultipliers
function upgrades.ComputeValues(playerStats)
	---@type UpgradeMultipliers
	local mults = {
		strength_mult = playerStats.strength_level,
		heatsinks_mult = playerStats.heatsinks_level, --TODO:
		ore_value_mult = playerStats.ore_value_level, -- TODO:
		drop_chances_mult = playerStats.drop_chances_level, -- TODO:
	}

	return mults
end

return upgrades
