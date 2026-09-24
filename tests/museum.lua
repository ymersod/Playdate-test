import("CoreLibs/object")
import("CoreLibs/graphics")
local museum = import("modules/museum")
local rewards = import("modules/playerRewards")
local rocks = import("modules/rocks")
local upgrades = import("modules/playerUpgrades")
local progress = import("modules/playerProgress")
local scene = import("modules/miningScene")
local passed, failures = 0, {}

local function Check(condition, message)
	if condition then passed += 1 else table.insert(failures, message) end
end

local rockList = {}
for _, rockType in ipairs({ "rock1", "rock2", "rock3" }) do
	table.insert(rockList, rocks.CreateRock({ screenW = 400, screenH = 240 }, rockType, 0))
end
museum.Start(rewards.GetCollectableList(), rockList)
local owned = {}
local count, total = museum.GetCount(owned)
Check(count == 0 and total == 9, "Empty museum has nine undiscovered exhibits")
for index = 1, total do
	local name, source, value, found = museum.GetExhibit(index, owned)
	Check(name == "???" and value == nil and not found, "Undiscovered exhibit hides its identity and value")
	Check(source == rockList[math.ceil(index / 3)].rockName, "Exhibit uses its authored rock name")
end

for _, rock in ipairs(rockList) do
	for _, collectable in ipairs(rewards.GetCollectableList()[rock.rockType]) do
		Check(museum.CollectableDropped(collectable, owned), "First discovery adds an exhibit")
		Check(not museum.CollectableDropped(table.deepcopy(collectable), owned), "Repeat find cannot duplicate an exhibit")
	end
end
Check(#owned == 9 and museum.GetCount(owned) == 9, "Completed museum counts each collectible once")
for index = 1, total do
	local name, _, value, found = museum.GetExhibit(index, owned)
	Check(name ~= "???" and value ~= nil and found, "Owned exhibit reveals its name and value")
end
table.insert(owned, table.deepcopy(owned[1]))
Check(museum.GetCount(owned) == 9, "Duplicate legacy save entries do not inflate completion")
table.remove(owned)

museum.Open()
museum.Select(-1)
Check(museum.GetSelection() == 9, "Browsing wraps backward to the last exhibit")
museum.Select(1)
Check(museum.GetSelection() == 1, "Browsing wraps forward to the first exhibit")
Check(not museum.Crank(39) and museum.Crank(1) and museum.GetSelection() == 2, "Crank browsing respects its threshold")
museum.Crank(20)
museum.Open()
Check(not museum.Crank(20) and museum.GetSelection() == 1, "Reopening clears partial crank travel")

local levels = { strength_level = 2, heatsinks_level = 1, ore_value_level = 0, drop_chances_level = 3 }
Check(progress.Save(levels, 742, owned, 24), "Collection can be saved")
local loaded, money, finds, killed = progress.Load(upgrades)
Check(museum.GetCount(finds) == 9 and money == 742 and killed == 24, "Collection survives a save/load round trip")
Check(loaded.strength_level == 2, "Museum does not alter upgrades")
local read, write = playdate.datastore.read, playdate.datastore.write
playdate.datastore.read = function() return { money = 5, levels = levels } end
local _, _, legacyFinds = progress.Load(upgrades)
Check(museum.GetCount(legacyFinds) == 0, "Older saves without finds open an empty museum")
playdate.datastore.read = read
playdate.datastore.write = function() return false end
Check(progress.Reset(upgrades) == nil and museum.GetCount(finds) == 9, "Failed reset preserves the collection")
playdate.datastore.write = write
local _, _, resetFinds = progress.Reset(upgrades)
Check(museum.GetCount(resetFinds) == 0, "New game clears museum ownership")

scene.Reset(0)
scene.Find(owned[1], true)
scene.Find(owned[2], true)
scene.Find(owned[1], false)
local sounds = {}
local collectedValue = 0
for frame = 1, 300 do
	local value, _, sound = scene.Update(1 / 30, 0, false, frame * 1000 / 30)
	collectedValue += value
	if sound then table.insert(sounds, sound) end
end
Check(#sounds == 2 and sounds[1] == "discovery" and sounds[2] == "discovery",
	"Only first discoveries queue the big celebration")
Check(collectedValue == owned[1].value, "Repeat collectible uses normal pickup feedback exactly once")
scene.Find(owned[1], true)
scene.Find(owned[1], false)
scene.Reset(0)
local value, _, sound = scene.Update(1, 0, false, 11000)
Check(sound == nil and value == 0, "Leaving mining clears pending celebrations and pickups")

playdate.datastore.write({ passed = passed, failures = failures }, "museum-results", true)
print("Museum tests: " .. passed .. " passed; " .. #failures .. " failed")
function playdate.update()
	playdate.graphics.clear()
	playdate.graphics.drawText("Museum tests: " .. passed .. " passed", 12, 30)
	playdate.graphics.drawText(#failures == 0 and "ALL CHECKS PASSED" or failures[1], 12, 60)
end
