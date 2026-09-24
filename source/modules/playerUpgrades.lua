---@class PlayerUpgrades
local upgrades = {}

upgrades.catalog = {
	{
		key = "strength_level",
		name = "Power",
		prices = { 10, 40, 120, 300, 700 },
		unit = "damage / rotation",
		description = "Hit harder.",
	},
	{
		key = "heatsinks_level",
		name = "Heat banks",
		prices = { 15, 50, 150, 350, 800 },
		unit = "bigger heat bubble",
		description = "Easier heat generation.",
	},
	{
		key = "ore_value_level",
		name = "Ore value",
		prices = { 20, 65, 180, 425, 950 },
		unit = "ore payout",
		description = "A better payday.",
	},
	{
		key = "drop_chances_level",
		name = "Rare finds",
		prices = { 30, 100, 250, 600, 1200 },
		unit = "better odds",
		description = "More goodies!",
	},
}

---@param levels PlayerLevels
---@param index number
function upgrades.GetLevel(levels, index)
	local value = levels[upgrades.catalog[index].key]
	if type(value) ~= "number" or value ~= value then
		return 0
	end
	return math.max(0, math.min(#upgrades.catalog[index].prices, math.floor(value)))
end

function upgrades.GetCost(levels, index)
	return upgrades.catalog[index].prices[upgrades.GetLevel(levels, index) + 1]
end

function upgrades.GetEffect(index, level)
	if index == 1 then
		return tostring(2 ^ level)
	elseif index == 2 then
		return "+" .. tostring(level * 2) .. ""
	elseif index == 3 then
		return string.format("%.2fx", tostring(2 ^ level))
	end
	return "+" .. tostring(10 * level) .. "%"
end

---@return number, string
function upgrades.TryPurchase(levels, money, index)
	if not upgrades.catalog[index] then
		return money, "invalid"
	end
	local cost = upgrades.GetCost(levels, index)
	if not cost then
		return money, "maxed"
	elseif money < cost then
		return money, "poor"
	end
	levels[upgrades.catalog[index].key] = upgrades.GetLevel(levels, index) + 1
	return money - cost, "bought"
end

function upgrades.CountAffordable(levels, money)
	local count = 0
	for index in ipairs(upgrades.catalog) do
		local cost = upgrades.GetCost(levels, index)
		if cost and money >= cost then
			count += 1
		end
	end
	return count
end

---@param playerStats PlayerLevels
---@return UpgradeMultipliers
function upgrades.ComputeValues(playerStats)
	local dropLevel = upgrades.GetLevel(playerStats, 4)

	---@type DropChanceMult
	local dropChances_mult_computed = {
		coal_mult = 10 * dropLevel,
		topaz_mult = 5 * dropLevel,
		diamond_mult = 2 * dropLevel,
		emerald_mult = 2 * dropLevel,
		ruby_mult = 1 * dropLevel,
		collectable_mult = 2 * dropLevel,
	}

	return {
		strength_mult = 2 ^ upgrades.GetLevel(playerStats, 1),
		heatsinks_mult = upgrades.GetLevel(playerStats, 2) * 2,
		ore_value_mult = 2 ^ upgrades.GetLevel(playerStats, 3),
		drop_chances_mult = dropChances_mult_computed,
	}
end

return upgrades
