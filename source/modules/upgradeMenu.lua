local pd <const> = playdate
local gfx <const> = pd.graphics

---@class HUD
local menu = {}
local small = gfx.font.new("fonts/Roobert-10-Bold")
local body = gfx.font.new("fonts/Roobert-11-Medium")
local heading = gfx.font.new("fonts/Roobert-20-Medium")
local selected = 1
local crankTravel = 0
local feedback = nil
local feedbackAt = 0
local paid = 0
local openedAt = 0
local displayedMoney = 0
local muted = false
local notes = {}
local findNotes = {}
local icons = {
	gfx.image.new("assets/textures/ui/upgradeMenu/power"),
	gfx.image.new("assets/textures/ui/upgradeMenu/heatbank"),
	gfx.image.new("assets/textures/ui/upgradeMenu/oreValue1"),
	gfx.image.new("assets/textures/ui/upgradeMenu/rareFinds"),
}

for index = 1, 3 do
	notes[index] = pd.sound.synth.new(pd.sound.kWaveTriangle)
	notes[index]:setADSR(0.005, 0.06, 0.25, 0.08)
	findNotes[index] = pd.sound.synth.new(pd.sound.kWaveSine)
	findNotes[index]:setADSR(0.005, 0.15, 0.3, 0.2)
end

local function Text(text, x, y, font, inverted)
	gfx.setFont(font or body)
	gfx.setImageDrawMode(inverted and gfx.kDrawModeFillWhite or gfx.kDrawModeCopy)
	gfx.drawText(text, x, y)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function RightText(text, x, y, font, inverted)
	Text(text, x - font:getTextWidth(text), y, font, inverted)
end

local function Icon(index, x, y, inverted)
	gfx.setImageDrawMode(inverted and gfx.kDrawModeInverted or gfx.kDrawModeCopy)
	icons[index]:draw(x, y)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function menu.SetMuted(value)
	muted = value
end

function menu.Sound(kind)
	if muted then
		return
	end
	if kind == "bought" then
		for index, pitch in ipairs({ 523, 659, 988 }) do
			notes[index]:playNote(pitch, 0.22, 0.1, pd.sound.getCurrentTime() + (index - 1) * 0.065)
		end
	elseif kind == "discovery" then
		for index, pitch in ipairs({ 784, 1047, 1568 }) do
			findNotes[index]:playNote(pitch, 0.24, 0.22, pd.sound.getCurrentTime() + (index - 1) * 0.1)
		end
	elseif kind == "poor" or kind == "maxed" then
		notes[1]:playNote(147, 0.18, 0.07)
	elseif kind == "reward" then
		notes[1]:playNote(784, 0.2, 0.1)
		notes[2]:playNote(1047, 0.17, 0.12, pd.sound.getCurrentTime() + 0.09)
	elseif kind == "hit" then
		notes[1]:playNote(185, 0.12, 0.025)
	elseif kind == "break" then
		notes[1]:playNote(82, 0.24, 0.08)
		notes[2]:playNote(123, 0.15, 0.06)
	elseif kind == "collect" then
		notes[1]:playNote(880, 0.16, 0.055)
		notes[2]:playNote(1175, 0.12, 0.065, pd.sound.getCurrentTime() + 0.045)
	elseif kind == "overheat" then
		notes[1]:playNote(220, 0.12, 0.06)
		notes[2]:playNote(165, 0.12, 0.06, pd.sound.getCurrentTime() + 0.12)
	else
		notes[1]:playNote(440, 0.12, 0.025)
	end
end

function menu.Open(money)
	crankTravel = 0
	feedback = nil
	displayedMoney = money
	openedAt = pd.getCurrentTimeMilliseconds()
	menu.Sound("move")
end

function menu.Select(direction)
	selected = (selected - 1 + direction) % 4 + 1
	feedback = nil
	menu.Sound("move")
end

function menu.Crank(change)
	crankTravel += change
	if math.abs(crankTravel) >= 40 then
		local direction = crankTravel > 0 and 1 or -1
		menu.Select(direction)
		crankTravel = 0
	end
end

function menu.GetSelection()
	return selected
end

function menu.CanBuy()
	return pd.getCurrentTimeMilliseconds() - feedbackAt >= 240
end

function menu.Feedback(result, cost)
	feedback = result
	paid = cost or 0
	feedbackAt = pd.getCurrentTimeMilliseconds()
	menu.Sound(result)
end

function menu.Draw(upgrades, levels, money, saveFailed)
	local now = pd.getCurrentTimeMilliseconds()
	local age = now - feedbackAt
	local installing = feedback == "bought" and age < 1100
	local rejecting = feedback == "poor" and age < 600
	local entrance = math.max(0, 1 - (now - openedAt) / 140)
	displayedMoney += (money - displayedMoney) * 0.35
	if math.abs(money - displayedMoney) < 1 then
		displayedMoney = money
	end
	gfx.clear(gfx.kColorWhite)
	gfx.setColor(gfx.kColorBlack)
	Text("WORKSHOP", 12, 3, heading)
	local wallet = "$" .. math.ceil(displayedMoney)
	local walletWidth = math.max(76, body:getTextWidth(wallet) + 20)
	gfx.fillRoundRect(388 - walletWidth, 8, walletWidth, 25, 5)
	RightText(wallet, 378, 11, body, true)

	for index, upgrade in ipairs(upgrades.catalog) do
		local level = upgrades.GetLevel(levels, index)
		local cost = upgrades.GetCost(levels, index)
		local chosen = index == selected
		local x = 10 + math.floor(entrance * (12 + index * 3))
		if chosen and rejecting then
			x += math.floor(math.sin(age * 0.065) * 3 * (1 - age / 600))
		end
		local y = 47 + (index - 1) * 31
		gfx.setColor(gfx.kColorBlack)
		if chosen then
			gfx.fillRoundRect(x, y, 380, 29, 4)
		else
			gfx.drawLine(x + 33, y + 29, 385, y + 29)
		end
		gfx.setColor(chosen and gfx.kColorWhite or gfx.kColorBlack)
		Icon(index, x + 9, y + 6, chosen)
		Text(upgrade.name, x + 36, y + 4, body, chosen)
		for pip = 1, #upgrade.prices do
			local px = x + 183 + (pip - 1) * 17
			if pip <= level then
				gfx.fillRoundRect(px - 5, y + 9, 10, 10, 2)
			else
				gfx.drawRoundRect(px - 5, y + 9, 10, 10, 2)
			end
			if chosen and installing and pip == level and age < 450 then
				gfx.drawCircleAtPoint(px, y + 14, 5 + math.floor(age / 90))
			end
		end
		local price = cost and "$" .. cost or "MAX"
		RightText(price, x + 367, y + 5, body, chosen)
		if cost and money >= cost then
			gfx.fillCircleAtPoint(x + 286, y + 14, 2)
		end
	end

	local upgrade = upgrades.catalog[selected]
	local level = upgrades.GetLevel(levels, selected)
	local cost = upgrades.GetCost(levels, selected)
	local current = upgrades.GetEffect(selected, level)
	local nextValue = upgrades.GetEffect(selected, math.min(level + 1, #upgrade.prices))
	gfx.setColor(gfx.kColorBlack)
	if installing then
		Text(string.upper(upgrade.name) .. " INSTALLED   -$" .. paid, 14, 179, small)
		Text(
			"Level " .. level .. " / " .. #upgrade.prices .. "   -   " .. current .. " " .. upgrade.unit,
			14,
			195,
			small
		)
	else
		Text(current .. (cost and "  >  " .. nextValue or "  /  MAXED") .. "   " .. upgrade.unit, 14, 179, body)
		local detail = upgrade.description
		if feedback == "poor" and age < 1600 then
			detail = "$" .. (cost - money) .. " more. A few rocks will do it."
		elseif not cost then
			detail = "Fully fitted. Take it for a spin."
		end
		Text(detail, 14, 199, small)
	end

	if saveFailed then
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRect(10, 195, 380, 23)
		Text("SAVE FAILED - Menu > Save progress", 14, 199, small)
	end
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(0, 220, 400, 20)
	Text("Select", 28, 224, small, true)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillTriangle(11, 228, 15, 223, 19, 228)
	gfx.fillTriangle(11, 231, 15, 236, 19, 231)
	local action = not cost and "A Maxed" or money >= cost and "A Buy $" .. cost or "Need $" .. (cost - money)
	Text(action, 149, 224, small, true)
	RightText("B Back", 388, 224, small, true)
end

return menu
