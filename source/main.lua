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

---@type Museum
local museum = import("modules/museum")

---@type PlayerUpgrades
local playerUpgrades = import("modules/playerUpgrades")

---@type PlayerRewards
local playerRewards = import("modules/playerRewards")

---@type TimeUtils
local timeUtils = import("utils/timeUtils")

---@type PlayerProgress
local playerProgress = import("modules/playerProgress")

---@type HUD
local upgradeMenu = import("modules/upgradeMenu")
local miningScene = import("modules/miningScene")
local titleMenu = import("modules/titleMenu")

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
---@type Collectable[]
local collectables

---@type GameContext
local context = {
	screenState = "title",
	rockScreenState = {
		rockAsNumberOnScreen = 1,
	},
	screenH = SCREEN_H,
	screenW = SCREEN_W,
}

local saveFailed = false
local gameStarted = false

local function SaveProgress()
	saveFailed = not playerProgress.Save(playerLevels, money, collectables)
end

local function ResetPresentation()
	miningScene.Reset(money)
	timeUtils.Reset()
	pd.getCrankChange()
end

local function HasProgress()
	if money > 0 or #collectables > 0 then
		return true
	end
	for index in ipairs(playerUpgrades.catalog) do
		if playerUpgrades.GetLevel(playerLevels, index) > 0 then
			return true
		end
	end
	return false
end

local function SpawnRocks()
	aliveRocks = {}
	context.rockScreenState.rockAsNumberOnScreen = 1
	for _, value in ipairs(rockList) do
		local rock = rocks.CreateRock(context, value)
		if not rock then
			error("Failed creating rock")
		end
		table.insert(aliveRocks, rock)
	end
end

local function ShowTitle()
	SaveProgress()
	context.screenState = "title"
	ResetPresentation()
	titleMenu.Open(gameStarted or HasProgress())
end

local function OpenUpgrades()
	context.screenState = "upgrades"
	ResetPresentation()
	upgradeMenu.Open(money)
end

pd.gameWillTerminate = SaveProgress
local function PauseGame()
	ResetPresentation()
	SaveProgress()
end
pd.deviceWillSleep = PauseGame
pd.gameWillPause = PauseGame
pd.getSystemMenu():addMenuItem("Title screen", ShowTitle)
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
	miningScene.Reset(money)
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
	elseif context.screenState == "title" and titleMenu.Select() then
		upgradeMenu.Sound("move")
	end
end

function playdate.downButtonDown()
	if context.screenState == "upgrades" then
		upgradeMenu.Select(1)
	elseif context.screenState == "title" and titleMenu.Select() then
		upgradeMenu.Sound("move")
	end
end

function playdate.AButtonDown()
	if context.screenState == "title" then
		local action = titleMenu.Accept()
		if action == "reset" then
			local levels, balance, finds = playerProgress.Reset(playerUpgrades)
			if not levels then
				titleMenu.SaveFailed()
				upgradeMenu.Sound("poor")
				return
			end
			playerLevels, money, collectables = levels, balance, finds
			saveFailed = false
			SpawnRocks()
			mineRock.Reset()
		end
		if action then
			gameStarted = true
			context.screenState = "rocks"
			ResetPresentation()
		end
		upgradeMenu.Sound("move")
	elseif context.screenState == "rocks" then
		OpenUpgrades()
	elseif context.screenState == "upgrades" and upgradeMenu.CanBuy() then
		local result
		local cost = playerUpgrades.GetCost(playerLevels, upgradeMenu.GetSelection())
		money, result = playerUpgrades.TryPurchase(playerLevels, money, upgradeMenu.GetSelection())
		upgradeMenu.Feedback(result, cost)
		if result == "bought" then
			SaveProgress()
		end
	end
end

function playdate.BButtonDown()
	if context.screenState == "upgrades" then
		context.screenState = "rocks"
		ResetPresentation()
		upgradeMenu.Sound("move")
	elseif context.screenState == "rocks" then
		ShowTitle()
		upgradeMenu.Sound("move")
	elseif context.screenState == "title" and titleMenu.Back() then
		upgradeMenu.Sound("move")
	end
end

-- //GAME FUNCTIONS//
function Start()
	playerLevels, money, collectables = playerProgress.Load(playerUpgrades) -- LOAD
	SpawnRocks()

	museum.Start(playerRewards.GetCollectableList())
	ResetPresentation()
	titleMenu.Open(HasProgress())
end
Start()

local lastUpdate = playdate.getCurrentTimeMilliseconds()
function playdate.update()
	---@type RockGeneric?
	local activeRock = SetActiveRock()

	--- //TIME//
	local now = pd.getCurrentTimeMilliseconds()
	local delta = math.max(0, math.min((now - lastUpdate) / 1000, 0.1))
	lastUpdate = now
	pd.timer.updateTimers()

	-- //COMPUTE PLAYER UGPRADES
	local upgrade_mults = playerUpgrades.ComputeValues(playerLevels)
	local change = pd.getCrankChange()
	if context.screenState == "title" then
		titleMenu.Draw(money, saveFailed)
		return
	end
	if context.screenState == "upgrades" then
		upgradeMenu.Crank(change)
		upgradeMenu.Draw(playerUpgrades, playerLevels, money, saveFailed)
		return
	end
	gfx.clear()

	local _, overHeated = mineRock.GetHeat()

	-- //CRANK LOGIC//
	---@type number
	local fullRotation = 0
	if not pd.isCrankDocked() and context.screenState == "rocks" then
		fullRotation = timeUtils.ComputeRealTick(change, overHeated)
	end

	-- // MINE_ROCK //
	local hits =
		mineRock.Mine(fullRotation, activeRock, upgrade_mults.strength_mult, upgrade_mults.heatsinks_mult, overHeated)
	if hits > 0 then
		miningScene.Hit(now, activeRock)
		if activeRock.health > 0 then
			upgradeMenu.Sound("hit")
		end
	end

	local rpsMover = mineRock.UpdateRPSBar(change, delta)
	local isInHeatZone =
		mineRock.IsInHeatZone(activeRock.heatToMatch, upgrade_mults.heatsinks_mult, rpsMover, activeRock.heatBuffer)
	local heat, overheated = mineRock.UpdateHeat(isInHeatZone, delta)

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
	local valuableDrop =
		playerRewards.ComputeRewards(rewardTable, upgrade_mults.ore_value_mult, rock.rockValueMultiplier)
	if valuableDrop then
		money += valuableDrop.value
		local collectableDrop = playerRewards.ComputeCollectable(
			valuableDrop,
			upgrade_mults.drop_chances_mult.collectable_mult,
			activeRock.rockType
		)
		if collectableDrop then
			museum.CollectableDropped(collectableDrop, collectables)
			money += collectableDrop.value
		end
		miningScene.Break(now, activeRock, valuableDrop, collectableDrop)
		activeRock = rock
		upgradeMenu.Sound("break")
		SaveProgress()
	end

	if not activeRock then
		return
	end

	-- // RENDER //
	local collected, rare = miningScene.Update(delta, change, not pd.isCrankDocked() and not overheated, now)
	if collected > 0 then
		upgradeMenu.Sound(rare and "reward" or "collect")
	end

	miningScene.Draw(
		activeRock,
		upgrade_mults,
		rpsMover,
		overheated,
		playerUpgrades.CountAffordable(playerLevels, money),
		saveFailed,
		rock.heatToMatch,
		upgrade_mults.heatsinks_mult + activeRock.heatBuffer,
		heat,
		rocks.UpdateRewardsTable(activeRock, upgrade_mults.drop_chances_mult),
		playerRewards.GetCollectableChance(upgrade_mults.drop_chances_mult.collectable_mult)
	)
end
