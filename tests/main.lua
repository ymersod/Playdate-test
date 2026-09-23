import("CoreLibs/object")
import("CoreLibs/graphics")
local upgrades = import("modules/playerUpgrades")
local rewards = import("modules/playerRewards")
local rocks = import("modules/rocks")
local mining = import("modules/mining")
local timeUtils = import("utils/timeUtils")
local progress = import("modules/playerProgress")
local feedback = import("modules/rockFeedback")
local title = import("modules/titleMenu")

local passed = 0
local failures = {}

local function Check(condition, message)
	if condition then
		passed += 1
	else
		table.insert(failures, message)
	end
end

local function FreshLevels()
	return { strength_level = 0, heatsinks_level = 0, ore_value_level = 0, drop_chances_level = 0 }
end

local function Settled(now)
	local x, y, screenX, screenY, flashing = feedback.GetOffsets(now)
	return x == 0 and y == 0 and screenX == 0 and screenY == 0 and not flashing
end

feedback.Hit(1000)
local x, y, screenX, screenY, flashing = feedback.GetOffsets(1000)
Check(x ~= 0 and screenX == 0 and screenY == 0 and flashing, "Hit moves only the rock")
Check(Settled(1120), "Hit fully settles within 120ms")
feedback.Break(1200)
x, y, screenX, screenY, flashing = feedback.GetOffsets(1200)
Check(x == 0 and y == 0 and screenX ~= 0 and not flashing, "Break moves the screen and clears the old rock flash")
Check(Settled(1410), "Break fully settles within 210ms")
local bounded = true
for now = 1500, 2500 do
	if now % 11 == 0 then feedback.Hit(now) end
	if now % 17 == 0 then feedback.Break(now) end
	x, y, screenX, screenY = feedback.GetOffsets(now)
	bounded = bounded and math.abs(x) <= 3 and math.abs(y) <= 1 and math.abs(screenX) <= 5 and math.abs(screenY) <= 3
end
Check(bounded and Settled(2800), "Rapid impacts stay bounded and settle after the final hit")
feedback.Hit(2900)
feedback.Break(2900)
feedback.Reset()
Check(Settled(2900), "Interrupting an impact immediately clears all feedback")

local levels = FreshLevels()
local balance, result = upgrades.TryPurchase(levels, 9, 1)
Check(balance == 9 and result == "poor" and levels.strength_level == 0, "Insufficient funds mutate nothing")
balance, result = upgrades.TryPurchase(levels, 10, 1)
Check(balance == 0 and result == "bought" and levels.strength_level == 1, "Exact funds buy one tier")
balance, result = upgrades.TryPurchase(levels, 0, 1)
Check(balance == 0 and result == "poor" and levels.strength_level == 1, "Repeated purchase cannot overspend")
balance, result = upgrades.TryPurchase(levels, 100, 99)
Check(balance == 100 and result == "invalid", "Invalid selection cannot spend")

for index, upgrade in ipairs(upgrades.catalog) do
	levels = FreshLevels()
	balance = 10000
	local spent = 0
	for tier, cost in ipairs(upgrade.prices) do
		local before = upgrades.ComputeValues(levels)
		balance, result = upgrades.TryPurchase(levels, balance, index)
		spent += cost
		Check(result == "bought" and balance == 10000 - spent, upgrade.name .. " tier " .. tier .. " price")
		Check(upgrades.GetLevel(levels, index) == tier, upgrade.name .. " increments exactly once")
		local after = upgrades.ComputeValues(levels)
		local stat = ({ "strength_mult", "heatsinks_mult", "ore_value_mult" })[index]
		if stat then
			Check(after[stat] > before[stat], upgrade.name .. " improves its stat")
		else
			Check(after.drop_chances_mult.diamond_mult > before.drop_chances_mult.diamond_mult, "Rare finds improves odds")
		end
	end
	local before = balance
	balance, result = upgrades.TryPurchase(levels, balance, index)
	Check(balance == before and result == "maxed" and upgrades.GetCost(levels, index) == nil, upgrade.name .. " cap")
end

local context = { screenW = 400, screenH = 240 }
local oldRandom = math.random
for tier = 0, 5 do
	levels = FreshLevels()
	levels.drop_chances_level = tier
	levels.ore_value_level = tier
	local mults = upgrades.ComputeValues(levels)
	for _, rockType in ipairs({ "rock1", "rock2", "rock3" }) do
		local rock = rocks.CreateRock(context, rockType)
		local originalCoal = rock.dropTable[1].chance
		Check(rock.maxHealth == rock.health, "Rock keeps its starting health for damage sprites")
		rock.health = 0
		local spawned, dropTable = rocks.CheckRocks(context, rock, 2, mults)
		Check(spawned ~= rock and spawned.health > 0 and dropTable ~= nil, "Zero HP pays once and respawns " .. rockType)
		local _, duplicate = rocks.CheckRocks(context, spawned, 2, mults)
		Check(duplicate == nil, "Fresh rock cannot pay twice")
		local total = 0
		for _, entry in ipairs(dropTable) do
			Check(entry.chance >= 0, "Nonnegative drop chance")
			total += entry.chance
		end
		Check(total == 100, "Drop table totals 100")
		local counts = { Coal = 0, Topaz = 0, Diamond = 0, Emerald = 0, Ruby = 0 }
		for roll = 1, 100 do
			math.random = function(low, high)
				Check(low == 1 and high == 100, "Loot roll has exactly 100 outcomes")
				return roll
			end
			local reward = rewards.ComputeRewards(table.deepcopy(dropTable), mults.ore_value_mult)
			counts[reward.valuableType] += 1
			local base = ({ Coal = 5, Topaz = 50, Diamond = 200, Emerald = 200, Ruby = 200 })[reward.valuableType]
			Check(reward.value == math.floor(base * mults.ore_value_mult), "Ore value reaches reward payout")
		end
		for _, entry in ipairs(dropTable) do
			Check(counts[entry.valuableType] == entry.chance, "Exact probability for " .. entry.valuableType)
		end
		Check(rock.dropTable[1].chance == originalCoal, "Upgrade does not mutate authored loot table")
	end
end
math.random = oldRandom

mining.Cool(100, 1)
local rock = { health = 100 }
Check(mining.Mine(1, rock, 6, 1) == 1 and rock.health == 94, "Power reaches mining damage")
mining.Cool(100, 1)
rock.health = 100
Check(mining.Mine(20, rock, 1, 1) == 6, "Base drill overheats after six uninterrupted turns")
local heat, hot = mining.GetHeat(1)
Check(heat == 1 and hot, "Heat stops at capacity")
Check(mining.Mine(1, rock, 1, 1) == 0 and rock.health == 94, "Hot drill cannot mine")
mining.Cool(4, 1)
local _, stillHot = mining.GetHeat(1)
Check(not stillHot, "Cooling releases the drill with the current recovery tuning")
mining.Cool(0.7, 1)
Check(mining.Mine(1, rock, 1, 1) == 1, "Cooling restores mining")
mining.Cool(100, 2.25)
rock.health = 100
Check(mining.Mine(20, rock, 1, 2.25) == 13, "Max heatsinks more than double uninterrupted turns")
mining.Cool(100, 1)
rock.health = 2
Check(mining.Mine(5, rock, 6, 1) == 1 and rock.health == 0, "Overkill cannot heat or damage a dead rock")
mining.Reset()
heat, hot = mining.GetHeat(1)
Check(heat == 0 and not hot, "New game clears drill heat and lockout")

local cooldowns = {}
for tier = 0, 5 do
	levels = FreshLevels()
	levels.heatsinks_level = tier
	local mult = upgrades.ComputeValues(levels).heatsinks_mult
	mining.Reset()
	mining.Mine(20, { health = 100 }, 1, mult)
	local elapsed = 0
	repeat
		mining.Cool(1 / 30, mult)
		elapsed += 1 / 30
		heat = mining.GetHeat(mult)
	until heat == 0 or elapsed >= 20
	cooldowns[tier + 1] = elapsed
	Check(heat == 0, "Heatsinks tier " .. tier .. " cools completely")
	if tier > 0 then
		Check(elapsed < cooldowns[tier], "Each heatsink tier clears a full heat bar sooner")
	end
end
Check(cooldowns[1] > 7 and cooldowns[1] < 7.3, "Base cooling stays unchanged")
Check(cooldowns[2] < cooldowns[1] * 0.85, "First heatsink gives a noticeable recovery improvement")
Check(cooldowns[6] < 3.3, "Max heatsinks clear a full heat bar in about three seconds")

local function CrankFor(tier, turnsPerSecond, frameRate)
	levels = FreshLevels()
	levels.heatsinks_level = tier
	local mult = upgrades.ComputeValues(levels).heatsinks_mult
	local target = { health = 10000 }
	local peak, total = 0, 0
	mining.Reset()
	timeUtils.Reset()
	for frame = 1, frameRate * 30 do
		mining.Cool(1 / frameRate, mult)
		local ticks = timeUtils.ComputeRealTick(turnsPerSecond * 360 / frameRate)
		total += mining.Mine(ticks, target, 1, mult)
		local heat = mining.GetHeat(mult)
		peak = math.max(peak, heat)
	end
	return peak, total
end

for _, frameRate in ipairs({ 30, 50 }) do
	for tier, speed in ipairs({ 0.6, 1.1, 1.6, 2.2, 2.8, 3.5 }) do
		local peak, hits = CrankFor(tier - 1, speed, frameRate)
		Check(peak < 0.25 and hits >= math.floor(speed * 30) - 1,
			"Heatsinks tier " .. (tier - 1) .. " sustains " .. speed .. " turns/sec at " .. frameRate .. " fps")
	end
	Check(CrankFor(0, 3.5, frameRate) == 1, "Fast cranking still overheats the base drill")
	Check(CrankFor(5, 4.5, frameRate) == 1, "Max heatsinks still have a heat limit")
end
mining.Reset()

timeUtils.Reset()
Check(timeUtils.ComputeRealTick(359) == 0, "Partial turns do not mine")
Check(timeUtils.ComputeRealTick(1) == 1, "Exact forward turn mines")
Check(timeUtils.ComputeRealTick(-360) == 1, "Exact reverse turn mines")
Check(timeUtils.ComputeRealTick(810) == 2 and timeUtils.ComputeRealTick(270) == 1, "Fast turns retain remainder")
timeUtils.ComputeRealTick(180)
timeUtils.Reset()
Check(timeUtils.ComputeRealTick(180) == 0, "Menu transition discards partial turns")

local read = playdate.datastore.read
local write = playdate.datastore.write
for _, saved in ipairs({ false, "invalid", { money = -20 }, { money = math.huge }, { money = 0 / 0 } }) do
	playdate.datastore.read = function() return saved end
	local loaded, money = progress.Load(upgrades)
	Check(money == 0 and loaded.strength_level == 0, "Malformed saves load safe defaults")
end
playdate.datastore.read = function()
	return { money = 22.9, levels = { strength_level = 99, heatsinks_level = -2, ore_value_level = "bad", drop_chances_level = 3.9 } }
end
local loaded, money = progress.Load(upgrades)
Check(money == 22 and loaded.strength_level == 5 and loaded.heatsinks_level == 0 and loaded.ore_value_level == 0 and loaded.drop_chances_level == 3, "Save values are sanitized")
playdate.datastore.write = function() return false end
Check(not progress.Save(loaded, money), "Failed write is reported")
Check(progress.Reset(upgrades) == nil, "Failed reset preserves the current run")
playdate.datastore.write = function() error("disk full") end
Check(not progress.Save(loaded, money), "Write exception is reported")
playdate.datastore.read = read
playdate.datastore.write = write
Check(progress.Save(loaded, money), "SDK datastore write succeeds")
local reloaded, savedMoney = progress.Load(upgrades)
Check(savedMoney == money and reloaded.strength_level == 5 and reloaded.drop_chances_level == 3, "SDK save/load round trip")
local resetLevels, resetMoney, resetFinds = progress.Reset(upgrades)
Check(resetLevels and resetMoney == 0 and #resetFinds == 0, "New game clears money and finds")
reloaded, savedMoney, resetFinds = progress.Load(upgrades)
Check(savedMoney == 0 and reloaded.strength_level == 0 and reloaded.drop_chances_level == 0 and #resetFinds == 0, "New game persists fresh progress")

local realClock = playdate.getCurrentTimeMilliseconds
local now = 10000
playdate.getCurrentTimeMilliseconds = function() return now end
title.Open(false)
Check(title.Accept() == "play" and not title.Select(), "Fresh title starts mining without an erase prompt")
title.Open(true)
Check(title.Accept() == "play", "Returning player defaults to Continue")
title.Select()
Check(title.Accept() == nil and title.Accept() == nil, "New game requires a separate deliberate confirmation")
now += 350
Check(title.Back() and title.Accept() == "play", "Cancelling reset returns to Continue")
title.Select()
title.Accept()
now += 350
Check(title.Accept() == "reset", "Confirmed new game requests a reset")
title.SaveFailed()
Check(title.Accept() == nil, "Failed reset cannot repeat immediately")
playdate.getCurrentTimeMilliseconds = realClock

playdate.datastore.write({ passed = passed, failures = failures }, "test-results", true)
print("Upgrade tests: " .. passed .. " passed; " .. #failures .. " failed")
for _, failure in ipairs(failures) do print(failure) end
function playdate.update()
	playdate.graphics.clear()
	playdate.graphics.drawText("Upgrade tests: " .. passed .. " passed", 12, 30)
	playdate.graphics.drawText(#failures == 0 and "ALL CHECKS PASSED" or failures[1], 12, 60)
end
