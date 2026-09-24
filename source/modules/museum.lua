---@class Museum
local museum = {}
local pd <const> = playdate
local gfx <const> = pd.graphics
local small = gfx.font.new("fonts/Roobert-10-Bold")
local body = gfx.font.new("fonts/Roobert-11-Medium")
local heading = gfx.font.new("fonts/Roobert-20-Medium")
local exhibits = {}
local selected, firstVisible = 1, 1
local crankTravel, openedAt = 0, 0

---@type CollectableList?
local collectableList

---@param collectable Collectable
---@param collectablesOwned Collectable[]
function museum.CollectableDropped(collectable, collectablesOwned)
	if not collectableList then
		warn("CollectableList not set yet")
		return
	end

	for _, value in ipairs(collectablesOwned) do
		if value.collectableType == collectable.collectableType then
			return false
		end
	end

	table.insert(collectablesOwned, collectable)
	return true
end

---@param toSetCollectableList CollectableList
function museum.Start(toSetCollectableList, rocks)
	collectableList = toSetCollectableList
	exhibits = {}
	for _, rock in ipairs(rocks) do
		for _, collectable in ipairs(collectableList[rock.rockType] or {}) do
			table.insert(exhibits, { collectable = collectable, rockName = rock.rockName })
		end
	end
end

function museum.GetExhibit(index, owned)
	local exhibit = exhibits[index]
	if not exhibit then return end
	for _, collectable in ipairs(owned) do
		if collectable.collectableType == exhibit.collectable.collectableType then
			return exhibit.collectable.collectableType, exhibit.rockName, exhibit.collectable.value, true
		end
	end
	return "???", exhibit.rockName, nil, false
end

function museum.GetCount(owned)
	local count = 0
	for index in ipairs(exhibits) do
		local _, _, _, found = museum.GetExhibit(index, owned)
		if found then count += 1 end
	end
	return count, #exhibits
end

function museum.Open()
	selected, firstVisible = 1, 1
	crankTravel = 0
	openedAt = pd.getCurrentTimeMilliseconds()
end

function museum.Select(direction)
	if #exhibits == 0 then return end
	selected = (selected - 1 + direction) % #exhibits + 1
	firstVisible = math.max(1, math.min(firstVisible, selected))
	firstVisible = math.max(firstVisible, selected - 3)
end

function museum.GetSelection()
	return selected
end

function museum.Crank(change)
	crankTravel += change
	if math.abs(crankTravel) >= 40 then
		museum.Select(crankTravel > 0 and 1 or -1)
		crankTravel = 0
		return true
	end
	return false
end

local function Text(text, x, y, font, white)
	gfx.setFont(font)
	gfx.setImageDrawMode(white and gfx.kDrawModeFillWhite or gfx.kDrawModeCopy)
	gfx.drawText(text, x, y)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function museum.Draw(owned, saveFailed)
	local count, total = museum.GetCount(owned)
	local entrance = math.max(0, 1 - (pd.getCurrentTimeMilliseconds() - openedAt) / 140)
	gfx.clear(gfx.kColorWhite)
	gfx.setColor(gfx.kColorBlack)
	Text("MUSEUM", 12, 3, heading)
	local counter = count .. " / " .. total .. " FOUND"
	local width = small:getTextWidth(counter) + 20
	gfx.fillRoundRect(388 - width, 8, width, 25, 5)
	Text(counter, 378 - small:getTextWidth(counter), 14, small, true)
	for row = 0, 3 do
		local index = firstVisible + row
		local name, rockName, _, found = museum.GetExhibit(index, owned)
		if name then
			local x = 10 + math.floor(entrance * (12 + row * 3))
			local y = 47 + row * 31
			local chosen = index == selected
			gfx.setColor(gfx.kColorBlack)
			if chosen then
				gfx.fillRoundRect(x, y, 372, 29, 4)
			else
				gfx.drawLine(x + 33, y + 29, 380, y + 29)
			end
			gfx.setColor(chosen and gfx.kColorWhite or gfx.kColorBlack)
			gfx.drawRoundRect(x + 7, y + 7, 17, 17, 3)
			if found then
				gfx.setLineWidth(2)
				gfx.drawLine(x + 11, y + 15, x + 15, y + 19)
				gfx.drawLine(x + 15, y + 19, x + 21, y + 11)
				gfx.setLineWidth(1)
			else
				Text("?", x + 12, y + 8, small, chosen)
			end
			Text(name, x + 36, y + 4, body, chosen)
			Text(rockName, x + 360 - small:getTextWidth(rockName), y + 8, small, chosen)
		end
	end
	gfx.setColor(gfx.kColorBlack)
	if total > 4 then
		gfx.drawLine(390, 49, 390, 167)
		gfx.fillRoundRect(387, 49 + math.floor((firstVisible - 1) / (total - 4) * 80), 6, 38, 2)
	end
	local name, rockName, value, found = museum.GetExhibit(selected, owned)
	if name then
		Text(found and "On display: " .. name or "An undiscovered collectible", 14, 179, body)
		local detail = found and "Found in " .. rockName .. "  /  Value $" .. value or "Keep drilling " .. rockName .. " to uncover it."
		Text(saveFailed and "Save failed - retry in Menu" or detail, 14, 199, small)
	end
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(0, 220, 400, 20)
	Text("Browse", 28, 224, small, true)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillTriangle(11, 228, 15, 223, 19, 228)
	gfx.fillTriangle(11, 231, 15, 236, 19, 231)
	Text(selected .. " / " .. total, 183, 224, small, true)
	Text("B Back", 388 - small:getTextWidth("B Back"), 224, small, true)
end

return museum
