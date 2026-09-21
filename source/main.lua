import("CoreLibs/object")
import("CoreLibs/graphics")
import("CoreLibs/sprites")
import("CoreLibs/timer")
import("CoreLibs/ui")
import("CoreLibs/crank")

---@type MineRock
local mineRock = import("helpers/mining")

---@type Rock
local rocks = import("types/rocks")

---@type Enums
local enums = import("globals/enums")

-- Globals
local pd <const> = playdate
local gfx <const> = playdate.graphics

function Start() end
Start()

function playdate.update()
	gfx.clear()

	---@type number
	local ticksChange

	if pd.isCrankDocked() then
		pd.ui.crankIndicator:draw()
	else
		-- Calculate velocity from crank angle
		local change, acceleratedChange = pd.getCrankChange()

		ticksChange = pd.getCrankTicks(1)

		-- #### Checks for ticks
		-- Skip next positive IF negative
		-- Skip next negative IF positive

		print(ticksChange)

		-- print("Change: " .. change)
		-- print("acceleratedChange: " .. acceleratedChange)
	end

	-- rock needs a type of some sort
	mineRock.Mine(ticksChange, "rock1")

	-- Render rock
end
