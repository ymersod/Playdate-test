---@class PlayerProgress
local progress = {}
local saveName <const> = "upgrades"

function progress.Load(upgrades)
	local ok, saved = pcall(playdate.datastore.read, saveName)
	if not ok or type(saved) ~= "table" then
		saved = {}
	end
	local levels = type(saved.levels) == "table" and saved.levels or {}
	local cleanLevels = {}
	for index, upgrade in ipairs(upgrades.catalog) do
		cleanLevels[upgrade.key] = upgrades.GetLevel(levels, index)
	end
	local money = saved.money
	if type(money) ~= "number" or money ~= money or money == math.huge then
		money = 0
	end

	return cleanLevels, math.max(0, math.floor(money))
end

function progress.Save(levels, money)
	local ok, result = pcall(playdate.datastore.write, {
		version = 1,
		levels = levels,
		money = money,
	}, saveName)
	return ok and result ~= false
end

return progress
