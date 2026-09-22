import("CoreLibs/object")
import("CoreLibs/graphics")
import("CoreLibs/sprites")
import("CoreLibs/timer")
import("CoreLibs/ui")
import("CoreLibs/crank")

-- //IMPORTS//
---@type MineRock
local mineRock = import("helpers/mining")

---@type Rock
local rocks = import("types/rocks")

---@type Utils
local utils = import("helpers/utils")

---@type PlayerUpgrades
local playerUpgrades = import("helpers/playerUpgrades")

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
local playerLevels = {
	strength_level = 1,
	heatsinks_level = 1,
	ore_value_level = 1,
	drop_chances_level = 1,
}

---@type GameContext
local context = {
	screenState = "rocks",
	rockScreenState = {
		rockAsNumberOnScreen = 1,
	},
	screenH = SCREEN_H,
	screenW = SCREEN_W,
}

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
	OnRockChange(-1)
end

function playdate.rightButtonDown()
	OnRockChange(1)
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

	gfx.clear()

	--- //TIME//
	local delta = playdate.getCurrentTimeMilliseconds() - lastUpdate -- in ms

	-- //COMPUTE PLAYER UGPRADES
	local upgrade_mults = playerUpgrades.ComputeValues(playerLevels)

	-- //CRANK LOGIC//
	---@type number
	local fullRotation = 0
	if pd.isCrankDocked() then
		pd.ui.crankIndicator:draw()
	else
		local ticks = pd.getCrankTicks(360)
		local pos = pd.getCrankPosition()
		fullRotation = utils.ComputeRealTick(ticks, pos)
	end

	-- // MINE_ROCK //
	mineRock.Mine(fullRotation, activeRock, upgrade_mults.strength_mult)

	-- // CHECK ROCKS //
	local rock, _ = rocks.CheckRocks(context, activeRock, rockSpawnTime)
	for i, aliveRock in ipairs(aliveRocks) do
		if aliveRock.rockType == rock.rockType and aliveRock ~= rock then
			table.remove(aliveRocks, i)
			table.insert(aliveRocks, i, rock)
			break
		end
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

	gfx.drawRect(sprite.x, sprite.y, sprite.w, sprite.h)

	gfx.drawText(activeRock.rockType, sprite.x, 0)
	gfx.drawText("ROK HP: " .. activeRock.health, sprite.x, 20)
end
