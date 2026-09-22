local pd = playdate
local elapsed = 10000
local crank = 0
local saved = nil
local writes = 0
local checks = {}
local realRead = pd.datastore.read
local realWrite = pd.datastore.write
local realClock = pd.getCurrentTimeMilliseconds

pd.getCurrentTimeMilliseconds = function() return elapsed end
pd.getCrankChange = function()
	local change = crank
	crank = 0
	return change
end
pd.isCrankDocked = function() return false end
pd.datastore.read = function()
	return { money = 10, levels = {} }
end
pd.datastore.write = function(data, name)
	saved = table.deepcopy(data)
	writes += 1
	return realWrite(data, name)
end
math.random = function() return 100 end
import("game")
pd.datastore.read = realRead
local gameUpdate = pd.update
local frame = 0
local snapshots = {
	[1] = "01-mining",
	[12] = "02-affordable",
	[16] = "03-installed",
	[48] = "04-next-tier",
	[58] = "05-reward",
	[64] = "06-insufficient",
	[78] = "07-heatsinks",
	[88] = "08-ore-value",
	[98] = "09-rare-finds",
	[111] = "10-save-failure",
}

local function Check(condition, name)
	table.insert(checks, { name = name, passed = condition })
end

function pd.update()
	frame += 1
	elapsed += 34
	if frame == 2 then pd.AButtonDown() end
	if frame == 13 then
		pd.AButtonDown()
		Check(saved.money == 0 and saved.levels.strength_level == 1, "A buys one tier and saves exact balance")
		pd.AButtonDown()
		Check(writes == 1, "Immediate repeated A is gated")
	end
	if frame >= 20 and frame <= 40 then crank = 12 end
	if frame == 41 then
		Check(writes == 1 and saved.money == 0, "Cranking in shop neither mines nor pays")
		pd.BButtonDown()
		pd.AButtonDown()
		pd.upButtonDown()
	end
	if frame == 49 then pd.BButtonDown() end
	if frame >= 51 and frame <= 55 then crank = 360 end
	if frame == 56 then
		Check(saved.money == 5 and saved.levels.strength_level == 1, "Power takes five turns to break 10 HP rock and pays once")
	end
	if frame == 60 then pd.AButtonDown() end
	if frame == 61 then pd.AButtonDown() end
	if frame == 65 then Check(saved.money == 5 and writes == 2, "Unaffordable purchase leaves save untouched") end
	if frame == 70 then pd.downButtonDown() end
	if frame == 80 then pd.downButtonDown() end
	if frame == 90 then pd.downButtonDown() end
	if frame == 104 then
		pd.datastore.write = function() return false end
		pd.gameWillPause()
	end
	gameUpdate()
	if snapshots[frame] then
		pd.datastore.writeImage(pd.graphics.getWorkingImage(), snapshots[frame] .. ".gif")
	end
	if frame == 115 then
		realWrite({ checks = checks }, "integration-results", true)
		pd.datastore.write = realWrite
		pd.getCurrentTimeMilliseconds = realClock
		print("Integration review complete")
		pd.update = function() end
	end
end
