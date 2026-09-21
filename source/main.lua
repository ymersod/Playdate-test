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

-- //GLOBALS//
local pd <const> = playdate
local gfx <const> = playdate.graphics
local SCREEN_W <const> = 400
local SCREEN_H <const> = 240

-- //GAME VARIABLES//
---@type RockGeneric?
local activeRock = nil
local rockSpawnTime = 2 -- seconds
local rockThread

---@type GameContext
local context = {
	screenState = "rocks",
	screenH = SCREEN_H,
	screenW = SCREEN_W,
}

-- //GAME FUNCTIONS//
function Start()
	local rock = rocks.CreateRock(context, "rock1")
	if not rock then
		error("Failed creating rock")
	end

	activeRock = rock
end
Start()

local lastUpdate = playdate.getCurrentTimeMilliseconds()
function playdate.update()
	local delta = playdate.getCurrentTimeMilliseconds() - lastUpdate -- in ms

	--- //TIME//
	gfx.clear()

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
	mineRock.Mine(fullRotation, activeRock)

	-- // CHECK ROCKS //
	local rock, rockSpawnThread = rocks.CheckRocks(context, activeRock, rockSpawnTime)
	activeRock = rock

	-- // CHECK ROCK SPAWNER // -- TODO: out of order (prob also out of scope hehe)
	if not rockThread then
		rockThread = rockSpawnThread
	end
	if rockThread then
		local _, result = coroutine.resume(rockThread)
		if coroutine.status(rockThread) == "dead" then
			activeRock = result
			rockThread = nil
		end
	end

	if not activeRock then
		return
	end

	-- // RENDER //
	local sprite = activeRock.sprite

	gfx.drawRect(sprite.x, sprite.y, sprite.w, sprite.h)

	---@type _Rect
	gfx.drawText("ROK HP: " .. activeRock.health, sprite.x, sprite.y / 2)
end
