local pd <const> = playdate
local gfx <const> = pd.graphics
local menu = {}
local background = gfx.image.new("assets/textures/ui/MainMenu")
local heading = gfx.font.new("fonts/Roobert-20-Medium")
local body = gfx.font.new("fonts/Roobert-11-Medium")
local small = gfx.font.new("fonts/Roobert-10-Bold")
local selected = 1
local canContinue = false
local confirming = false
local confirmedAt = 0
local errorAt = -10000

local function Center(text, y, font, inverted)
	gfx.setFont(font)
	gfx.setImageDrawMode(inverted and gfx.kDrawModeFillWhite or gfx.kDrawModeCopy)
	gfx.drawText(text, math.floor((400 - font:getTextWidth(text)) / 2), y)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function menu.Open(hasProgress)
	selected = 1
	canContinue = hasProgress
	confirming = false
	errorAt = -10000
end

function menu.Select()
	if canContinue and not confirming then
		selected = 3 - selected
		return true
	end
	return false
end

function menu.Accept()
	local now = pd.getCurrentTimeMilliseconds()
	if confirming then
		if now - confirmedAt >= 300 then
			return "reset"
		end
	elseif selected == 1 then
		return "play"
	else
		confirming = true
		confirmedAt = now
	end
end

function menu.Back()
	if confirming then
		confirming = false
		selected = 1
		return true
	end
	return false
end

function menu.SaveFailed()
	errorAt = pd.getCurrentTimeMilliseconds()
	confirmedAt = errorAt
end

function menu.Draw(money, saveFailed)
	gfx.clear(gfx.kColorBlack)
	background:draw(0, 0)
	gfx.setColor(gfx.kColorWhite)
	if confirming then
		gfx.fillRoundRect(68, 82, 264, 136, 6)
		gfx.setColor(gfx.kColorBlack)
		gfx.drawRoundRect(68, 82, 264, 136, 6)
		Center("START OVER?", 94, heading)
		Center("Erase money, upgrades", 130, body)
		Center("and collected finds?", 149, body)
		if pd.getCurrentTimeMilliseconds() - errorAt < 2200 then
			Center("Couldn't save. Try again.", 178, small)
		else
			Center("B Cancel     A Erase", 188, small)
		end
		return
	end

	gfx.fillRoundRect(134, 83, 132, 44, 5)
	gfx.setColor(gfx.kColorBlack)
	--[[ gfx.drawRoundRect(134, 83, 132, 44, 5) ]]
	Center("CRANKY", 81, heading)
	Center("DWARF", 110, small)
	if canContinue then
		Center("$" .. money .. " saved", 135, small)
	end

	local count = canContinue and 2 or 1
	for index = 1, count do
		local y = 159 + (index - 1) * 31
		local chosen = selected == index
		gfx.setColor(chosen and gfx.kColorBlack or gfx.kColorWhite)
		gfx.fillRoundRect(115, y, 170, 27, 4)
		local label = index == 2 and "New game" or canContinue and "Continue" or "Start mining"
		Center((chosen and "A  " or "") .. label, y + 3, body, chosen)
	end
	if saveFailed then
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(0, 219, 400, 21)
		Center("Save failed - try Menu > Save progress", 223, small)
	end
end

return menu
