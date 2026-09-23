import("CoreLibs/object")
import("CoreLibs/graphics")
import("CoreLibs/sprites")
import("CoreLibs/timer")
import("CoreLibs/ui")
import("CoreLibs/crank")

-- //IMPORTS//
---@type MineRock
local mineRock = import("modules/mining")

---@type Rock
local rocks = import("modules/rocks")

---@type PlayerUpgrades
local playerUpgrades = import("modules/playerUpgrades")

---@type PlayerRewards
local playerRewards = import("modules/playerRewards")

---@type TimeUtils
local timeUtils = import("utils/timeUtils")
local playerProgress = import("modules/playerProgress")
local upgradeMenu = import("modules/upgradeMenu")
local rockFeedback = import("modules/rockFeedback")

-- //GLOBALS//
local pd <const> = playdate
local gfx <const> = playdate.graphics
local SCREEN_W <const> = 400
local SCREEN_H <const> = 240

-- //GAME VARIABLES//
---@type RockGeneric[]
local aliveRocks = {}

---@type RockType[]
local rockList = {
	"rock1",
	"rock2",
	"rock3",
}
local rockSpawnTime = 2 -- seconds

---@type PlayerLevels
local playerLevels
---@type number
local money
---@type CollectableList
local collectables

playerLevels, money, collectables = playerProgress.Load(playerUpgrades)

---@type GameContext
local context = {
	screenState = "rocks",
	rockScreenState = {
		rockAsNumberOnScreen = 1,
	},
	screenH = SCREEN_H,
	screenW = SCREEN_W,
}

local lastReward = nil
local rewardAt = 0
local saveFailed = false

local function SaveProgress()
	saveFailed = not playerProgress.Save(playerLevels, money, collectables)
end

local function OpenUpgrades()
	context.screenState = "upgrades"
	rockFeedback.Reset()
	timeUtils.Reset()
	pd.getCrankChange()
	upgradeMenu.Open(money)
end

pd.gameWillTerminate = SaveProgress
local function PauseGame()
	rockFeedback.Reset()
	SaveProgress()
end
pd.deviceWillSleep = PauseGame
pd.gameWillPause = PauseGame
pd.getSystemMenu():addMenuItem("Upgrades", OpenUpgrades)
pd.getSystemMenu():addMenuItem("Save progress", SaveProgress)
pd.getSystemMenu():addCheckmarkMenuItem("Mute effects", false, upgradeMenu.SetMuted)

-- // LOCAL HELPERS //
function SetActiveRock()
	local newActiveRock = nil
	for _, value in ipairs(aliveRocks) do
		if context.rockScreenState.rockAsNumberOnScreen == value.rockTypeNumber then
			newActiveRock = value
			value.active = true
		else
			value.active = false
		end
	end

	return newActiveRock
end

-- // INPUT HANDLING //
---@param direction number
function OnRockChange(direction)
	rockFeedback.Reset()
	local nextRock = context.rockScreenState.rockAsNumberOnScreen
	nextRock += direction

	if nextRock < 1 then
		nextRock = table.getsize(rockList)
	elseif nextRock > table.getsize(rockList) then
		nextRock = 1
	end

	context.rockScreenState.rockAsNumberOnScreen = nextRock
	SetActiveRock()
end

function playdate.leftButtonDown()
	if context.screenState == "rocks" then
		OnRockChange(-1)
	end
end

function playdate.rightButtonDown()
	if context.screenState == "rocks" then
		OnRockChange(1)
	end
end

function playdate.upButtonDown()
	if context.screenState == "upgrades" then
		upgradeMenu.Select(-1)
	end
end

function playdate.downButtonDown()
	if context.screenState == "upgrades" then
		upgradeMenu.Select(1)
	end
end

function playdate.AButtonDown()
	if context.screenState == "rocks" then
		OpenUpgrades()
	elseif context.screenState == "upgrades" then
		context.screenState = "rocks"
		timeUtils.Reset()
		pd.getCrankChange()
		upgradeMenu.Sound("move")
	end
end

function playdate.BButtonDown()
	if context.screenState == "upgrades" and upgradeMenu.CanBuy() then
		local result
		local cost = playerUpgrades.GetCost(playerLevels, upgradeMenu.GetSelection())
		money, result = playerUpgrades.TryPurchase(playerLevels, money, upgradeMenu.GetSelection())
		upgradeMenu.Feedback(result, cost)
		if result == "bought" then
			SaveProgress()
		end
	end
end

-- //GAME FUNCTIONS//
function Start()
	for _, value in ipairs(rockList) do -- Spawn initial rocks
		local rock = rocks.CreateRock(context, value)
		table.insert(aliveRocks, rock)

		if not rock then
			error("Failed creating rock")
		end

		if rock.rockType == "rock1" then
			rock.active = true
		end
	end
end
Start()

local lastUpdate = playdate.getCurrentTimeMilliseconds()
function playdate.update()
	---@type RockGeneric?
	local activeRock = SetActiveRock()

	--- //TIME//
	local now = pd.getCurrentTimeMilliseconds()
	local delta = math.min((now - lastUpdate) / 1000, 0.1)
	lastUpdate = now
	pd.timer.updateTimers()

	-- //COMPUTE PLAYER UGPRADES
	local upgrade_mults = playerUpgrades.ComputeValues(playerLevels)
	mineRock.Cool(delta, upgrade_mults.heatsinks_mult)
	local change = pd.getCrankChange()
	if context.screenState == "upgrades" then
		upgradeMenu.Crank(change)
		upgradeMenu.Draw(playerUpgrades, playerLevels, money, saveFailed)
		return
	end
	gfx.clear()

	-- //CRANK LOGIC//
	---@type number
	local fullRotation = 0
	if not pd.isCrankDocked() then
		fullRotation = timeUtils.ComputeRealTick(change)
	end

	-- // MINE_ROCK //
	local hits = mineRock.Mine(fullRotation, activeRock, upgrade_mults.strength_mult, upgrade_mults.heatsinks_mult)
	if hits > 0 then
		rockFeedback.Hit(now)
		upgradeMenu.Sound("hit")
	end

	-- // CHECK ROCKS //
	local rock, rewardTable = rocks.CheckRocks(context, activeRock, rockSpawnTime, upgrade_mults)
	if rewardTable then
		for i, aliveRock in ipairs(aliveRocks) do
			if aliveRock.rockType == rock.rockType and aliveRock ~= rock then
				table.remove(aliveRocks, i)
				table.insert(aliveRocks, i, rock)
				break
			end
		end
	end

	-- // COMPUTE DROPS //
	local valuableDrop = playerRewards.ComputeRewards(rewardTable, upgrade_mults.ore_value_mult)
	if valuableDrop then
		money += valuableDrop.value
		lastReward = valuableDrop
		rewardAt = now
		activeRock = rock
		rockFeedback.Break(now)
		upgradeMenu.Sound("reward")
		SaveProgress()
	end

	local collectableDrop =
		playerRewards.ComputeCollectable(valuableDrop, upgrade_mults.drop_chances_mult.collectable_mult, rock.rockType)
	if collectableDrop then
		table.insert(collectables, collectableDrop)
		SaveProgress()
	end

	-- // CHECK ROCK SPAWNER // -- TODO: out of order (prob also out of scope hehe)
	--[[ if not rockThread then
		rockThread = rockSpawnThread
	end
	if rockThread then
		local _, result = coroutine.resume(rockThread)
		if coroutine.status(rockThread) == "dead" then
			activeRock = result
			rockThread = nil
		end
	end ]]

	if not activeRock then
		return
	end

	-- // RENDER //
	local sprite = activeRock.sprite
	local rockX, rockY, screenX, screenY, flashing = rockFeedback.GetOffsets(now)
	gfx.setDrawOffset(screenX, screenY)
	local heat, overheated = mineRock.GetHeat(upgrade_mults.heatsinks_mult)
	upgradeMenu.DrawMiningHUD(playerUpgrades, playerLevels, money, heat, overheated, lastReward, rewardAt, saveFailed)

	if flashing then
		gfx.fillRect(sprite.x + rockX - 2, sprite.y + rockY - 2, sprite.w + 4, sprite.h + 4)
	else
		gfx.drawRect(sprite.x + rockX, sprite.y + rockY, sprite.w, sprite.h)
	end

	gfx.drawText("<  " .. string.upper(activeRock.rockType) .. "  >", 163, 12)
	gfx.drawText("HP " .. activeRock.health, sprite.x, 40)
	gfx.drawText(upgrade_mults.strength_mult .. " damage / turn", 137, 194)
	if overheated then
		gfx.drawText("Too hot! Let it cool.", 126, 66)
	elseif pd.isCrankDocked() then
		gfx.drawText("Undock the crank to mine", 105, 66)
	end
	gfx.setDrawOffset(0, 0)
end
