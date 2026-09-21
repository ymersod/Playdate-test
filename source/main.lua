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

-- //GLOBALS//
local pd <const> = playdate
local gfx <const> = playdate.graphics
local SCREEN_W <const> = 400
local SCREEN_H <const> = 240

-- //GAME VARIABLES//
---@type RockGeneric?
local activeRock = nil

---@type GameContext
local context = {
	screenState = "rocks",
	screenH = SCREEN_H,
	screenW = SCREEN_W,
}

-- //GAME FUNCTIONS//
function Start()
	local rock = rocks.CreateRock("rock1", context)
	if not rock then
		error("Failed creating rock")
	end

	activeRock = rock
end
Start()

function playdate.update()
	gfx.clear()

	---@type number
	local ticksChange = 0

	if pd.isCrankDocked() then
		pd.ui.crankIndicator:draw()
	else
		ticksChange = pd.getCrankTicks(1)

		-- #### Checks for ticks
		-- Skip next positive IF negative
		-- Skip next negative IF positive

		print(ticksChange)
	end

	if not activeRock then
		print("No rock is active...")
		-- Try to create a new rock i suppose ?
		return
	end

	mineRock.Mine(ticksChange, activeRock)

	-- RENDER
	local sprite = activeRock.sprite

	gfx.drawRect(sprite.x, sprite.y, sprite.w, sprite.h)
end
