---@class PlayerProgress
local progress = {}
local saveName <const> = "upgrades"

---@return PlayerLevels, number, Collectable[]
function progress.Load(upgrades)
	local ok, saved = pcall(playdate.datastore.read, saveName)
	if not ok or type(saved) ~= "table" then
		saved = {}
	end

	-- levels load
	local levels = type(saved.levels) == "table" and saved.levels or {}
	local cleanLevels = {}
	for index, upgrade in ipairs(upgrades.catalog) do
		cleanLevels[upgrade.key] = upgrades.GetLevel(levels, index)
	end

	-- money load
	local money = saved.money
	if type(money) ~= "number" or money ~= money or money == math.huge then
		money = 0
	end

	-- collectables
	---@type Collectable[]
	local collectables = type(saved.collectables) == "table" and saved.collectables or {}

	return cleanLevels, math.max(0, math.floor(money)), collectables
end

function progress.Save(levels, money, collectables)
	local ok, result = pcall(playdate.datastore.write, {
		version = 1,
		levels = levels,
		money = money,
		collectables = collectables,
	}, saveName)
	return ok and result ~= false
end

function progress.Reset(upgrades)
	local levels = {}
	for _, upgrade in ipairs(upgrades.catalog) do
		levels[upgrade.key] = 0
	end
	local collectables = {}
	if not progress.Save(levels, 0, collectables) then return nil end
	return levels, 0, collectables
end

return progress
