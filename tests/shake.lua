local pd = playdate
local elapsed = 10000
local crank = 0
local realRead = pd.datastore.read
local realWrite = pd.datastore.write
local checks = {}
local frames = {}
local saved = nil

pd.getCurrentTimeMilliseconds = function() return elapsed end
pd.getCrankChange = function()
	local change = crank
	crank = 0
	return change
end
pd.isCrankDocked = function() return false end
pd.datastore.read = function()
	return { money = 0, levels = { strength_level = 3, heatsinks_level = 5 } }
end
pd.datastore.write = function(data)
	saved = data
	return true
end
import("game")
pd.datastore.read = realRead
local gfx = pd.graphics
local gameUpdate = pd.update
local frame = 0
local rockDraw = nil
local cleanOffsets = true

local function Check(condition, name)
	table.insert(checks, { name = name, passed = condition })
end

local function Settled()
	return rockDraw and rockDraw.x == 175 and rockDraw.y == 95 and rockDraw.offsetX == 0 and rockDraw.offsetY == 0 and not rockDraw.filled
end

local drawRect = gfx.drawRect
local fillRect = gfx.fillRect
gfx.drawRect = function(x, y, w, h)
	if w == 50 and h == 50 then
		local offsetX, offsetY = gfx.getDrawOffset()
		rockDraw = { x = x, y = y, offsetX = offsetX, offsetY = offsetY, filled = false }
	end
	return drawRect(x, y, w, h)
end
gfx.fillRect = function(x, y, w, h)
	if w == 54 and h == 54 then
		local offsetX, offsetY = gfx.getDrawOffset()
		rockDraw = { x = x + 2, y = y + 2, offsetX = offsetX, offsetY = offsetY, filled = true }
	end
	return fillRect(x, y, w, h)
end

function pd.update()
	frame += 1
	rockDraw = nil
	elapsed += 1000 / 30
	if frame == 13 or frame == 28 or frame == 43 or frame == 80 or frame == 83 or frame == 89 then crank = 360 end
	if frame == 81 then pd.rightButtonDown() end
	if frame == 84 or frame == 87 then pd.AButtonDown() end
	if frame == 85 or frame == 88 then pd.BButtonDown() end
	if frame == 86 then
		pd.leftButtonDown()
		crank = 1080
	end
	if frame == 90 then pd.gameWillPause() end
	gameUpdate()
	local offsetX, offsetY = gfx.getDrawOffset()
	cleanOffsets = cleanOffsets and offsetX == 0 and offsetY == 0
	if frame == 13 then
		Check(rockDraw.x ~= 175 and rockDraw.offsetX == 0 and rockDraw.offsetY == 0, "Hit jolts the rock without moving the HUD")
	elseif frame == 17 then
		Check(Settled() and rockDraw.x == 175 and not rockDraw.filled, "Ordinary hit settles and flash clears")
	elseif frame == 43 then
		Check(rockDraw.offsetX ~= 0 and rockDraw.x == 175 and not rockDraw.filled, "Break shakes the full frame without jolting the replacement rock")
		Check(saved and saved.money > 0, "Break still pays and saves")
	elseif frame == 50 then
		Check(Settled(), "Break rumble settles")
	elseif frame == 81 then
		Check(Settled(), "Changing rocks cancels a jolt")
	elseif frame == 85 then
		Check(Settled(), "Returning from workshop has no leftover jolt")
	elseif frame == 86 then
		Check(not Settled(), "Several turns in one frame produce one bounded break")
	elseif frame == 88 then
		Check(Settled(), "Returning from workshop has no leftover break rumble")
	elseif frame == 90 then
		Check(Settled(), "Pausing cancels feedback")
	end
	if frame <= 72 then frames[frame] = gfx.getWorkingImage():copy() end
	if frame == 91 then
		Check(cleanOffsets, "Every frame restores the drawing offset, including workshop frames")
		for index, image in ipairs(frames) do
			pd.datastore.writeImage(image, string.format("shake-%03d.gif", index))
		end
		realWrite({ checks = checks }, "shake-results", true)
		pd.datastore.write = realWrite
		print("Shake review complete")
		pd.update = function() end
	end
end
