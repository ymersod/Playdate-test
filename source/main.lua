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

---@type Enums
local enums = import("globals/enums")

-- //GLOBALS//
local pd <const> = playdate
local gfx <const> = playdate.graphics

-- //GAME VARIABLES//
---@type RockGeneric?
local activeRock = nil

-- //GAME FUNCTIONS//
function Start()
	local rock = rocks.CreateRock(enums.rockType.rock1)
	if not rock then
		error("Failed creating rock")
	end

	activeRock = rock
end
Start()

function playdate.update()
	gfx.clear()

	---@type number
	local ticksChange

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
		return
	end

	mineRock.Mine(ticksChange, activeRock)

	-- Render rock
end
