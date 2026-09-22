import("CoreLibs/object")
import("CoreLibs/graphics")
local upgrades = import("modules/playerUpgrades")
local menu = import("modules/upgradeMenu")
local levels = { strength_level = 5, heatsinks_level = 5, ore_value_level = 5, drop_chances_level = 5 }
local money = 98765
local frame = 0
menu.Open(money)

function playdate.update()
	frame += 1
	if frame == 30 then
		local result
		money, result = upgrades.TryPurchase(levels, money, 1)
		assert(money == 98765 and result == "maxed")
		menu.Feedback(result)
	end
	menu.Draw(upgrades, levels, money)
	if frame == 40 then
		playdate.datastore.writeImage(playdate.graphics.getWorkingImage(), "11-maxed.gif")
		playdate.datastore.write({ passed = true, money = money }, "maxed-results")
	end
end
